class_name NarratorVoice
## Voz del narrador en un proceso aparte (Windows): un PowerShell con
## System.Speech que recibe órdenes por una tubería. Así la voz se puede cortar
## al adelantar o cerrar un diálogo SIN arriesgar el juego: llamar a tts_stop()
## de Godot con SAPI hablando colgaba el juego entero (y el editor). Si alguna
## vez el que se cuelga es el ayudante, se mata y se vuelve a lanzar.
##
## Protocolo (una línea por orden):
##   juego → ayudante:  S <id> <velocidad%> <tono%> <género> <volumen 0-100> <texto en base64>   hablar (corta lo anterior)
##                      (género: male | female | neutral; si no hay una voz así, se usa la que haya)
##                      X                                                callar
##                      Q                                                salir
##   ayudante → juego:  D <id>   terminó (o se cortó) la frase <id>
##                      K        confirmó un «callar»

const SCRIPT_PATH := "user://narrador.ps1"
## Si un «callar» no se confirma en este tiempo, el ayudante está colgado: se mata.
const STOP_TIMEOUT_MS := 2500

const PS_SOURCE := """$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.SetOutputToDefaultAudioDevice()
foreach ($v in $s.GetInstalledVoices()) {
  if ($v.Enabled -and $v.VoiceInfo.Culture.TwoLetterISOLanguageName -eq 'es') { $s.SelectVoice($v.VoiceInfo.Name); break }
}
$lang = $s.Voice.Culture.Name
$out = [Console]::Out
$reader = New-Object IO.StreamReader([Console]::OpenStandardInput(), [Text.Encoding]::ASCII)
$task = $reader.ReadLineAsync()
$cur = 0
$since = [DateTime]::Now
$ready = 0
while ($true) {
  if ($task.Wait(50)) {
    $line = $task.Result
    if ($line -eq $null -or $line -eq 'Q') { break }
    if ($line -eq 'X') {
      $s.SpeakAsyncCancelAll()
      if ($cur -gt 0) { $out.WriteLine("D $cur"); $cur = 0 }
      $out.WriteLine('K')
      $out.Flush()
    } elseif ($line.StartsWith('S ')) {
      $p = $line.Split(' ')
      $s.SpeakAsyncCancelAll()
      if ($cur -gt 0) { $out.WriteLine("D $cur") }
      $text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p[6]))
      $esc = [Security.SecurityElement]::Escape($text)
      $s.Volume = [Math]::Max(0, [Math]::Min(100, [int]$p[5]))
      $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='$lang'><voice gender='$($p[4])'><prosody rate='$($p[2])%' pitch='$($p[3])%'>$esc</prosody></voice></speak>"
      $cur = [int]$p[1]
      $since = [DateTime]::Now
      $ready = 0
      try { $null = $s.SpeakSsmlAsync($ssml) } catch { $null = $s.SpeakAsync($text) }
      $out.Flush()
    }
    $task = $reader.ReadLineAsync()
  }
  if ($cur -gt 0) {
    if ($s.State -eq 'Ready' -and ([DateTime]::Now - $since).TotalMilliseconds -gt 400) { $ready++ } else { $ready = 0 }
    if ($ready -ge 2) { $out.WriteLine("D $cur"); $out.Flush(); $cur = 0 }
  }
}
$s.SpeakAsyncCancelAll()
"""

static var _pid := -1
static var _io: FileAccess
static var _thread: Thread
static var _mutex := Mutex.new()
static var _sent_id := 0
static var _done_id := 0
static var _stop_sent_ms := 0
static var _failed := false


## Solo en Windows con pantalla (en las pruebas sin pantalla, no).
static func supported() -> bool:
	return OS.get_name() == "Windows" and DisplayServer.get_name() != "headless" and not _failed


## Habla (cortando lo que estuviera diciendo). `pitch` y `rate`: 1 = normal.
static func speak(text: String, pitch: float, rate: float, gender := "neutral", volume := 1.0) -> bool:
	if not _ensure():
		return false
	if not gender in ["male", "female", "neutral"]:
		gender = "neutral"
	_mutex.lock()
	_sent_id += 1
	var id := _sent_id
	_mutex.unlock()
	var rate_pct := int(round((clampf(rate * 1.1, 0.5, 2.0) - 1.0) * 100.0))
	var pitch_pct := int(round((clampf(pitch, 0.5, 1.6) - 1.0) * 60.0))
	var line := "S %d %s%d %s%d %s %d %s" % [id, "+" if rate_pct >= 0 else "", rate_pct, "+" if pitch_pct >= 0 else "", pitch_pct,
		gender, int(round(clampf(volume, 0.0, 1.0) * 100.0)), Marshalls.utf8_to_base64(text)]
	return _send(line)


## Calla. El juego lo da por callado al instante; si el ayudante no confirma a
## tiempo, se mata en la siguiente consulta.
static func stop() -> void:
	if _pid <= 0 or not is_speaking():
		return
	_mutex.lock()
	_done_id = _sent_id
	_mutex.unlock()
	_stop_sent_ms = Time.get_ticks_msec()
	_send("X")


static func is_speaking() -> bool:
	_check_hung()
	_mutex.lock()
	var speaking := _done_id < _sent_id
	_mutex.unlock()
	return speaking


static func shutdown() -> void:
	if _pid > 0:
		_send("Q")
		OS.kill(_pid)
	_pid = -1
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null


# --- Interno ---

static func _ensure() -> bool:
	if not supported():
		return false
	if _pid > 0 and OS.is_process_running(_pid):
		return true
	var f := FileAccess.open(SCRIPT_PATH, FileAccess.WRITE)
	if f == null:
		_failed = true
		return false
	f.store_string(PS_SOURCE)
	f.close()
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	var info := OS.execute_with_pipe("powershell.exe", ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden",
		"-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(SCRIPT_PATH)])
	if info.is_empty():
		push_warning("Narrador: no se pudo lanzar PowerShell; se usa la voz de Godot sin poder cortarla.")
		_failed = true
		return false
	_pid = int(info["pid"])
	_io = info["stdio"]
	_mutex.lock()
	_done_id = _sent_id
	_mutex.unlock()
	_thread = Thread.new()
	_thread.start(_read_loop.bind(_io))
	FreezeWatch.mark("voz: ayudante lanzado (pid %d)" % _pid)
	return true


static func _send(line: String) -> bool:
	if _io == null:
		return false
	_io.store_line(line)
	_io.flush()
	return true


static func _read_loop(io: FileAccess) -> void:
	while true:
		var line := io.get_line()
		if line == "" and io.get_error() != OK:
			break
		if line.begins_with("D "):
			var id := int(line.substr(2))
			_mutex.lock()
			_done_id = maxi(_done_id, id)
			_mutex.unlock()
		elif line == "K":
			_stop_sent_ms = 0


## Un «callar» sin confirmar durante demasiado tiempo: el ayudante se colgó.
static func _check_hung() -> void:
	if _stop_sent_ms > 0 and Time.get_ticks_msec() - _stop_sent_ms > STOP_TIMEOUT_MS:
		FreezeWatch.mark("voz: ayudante colgado, se reinicia")
		_stop_sent_ms = 0
		if _pid > 0:
			OS.kill(_pid)
		_pid = -1
		_io = null
