extends SceneTree
## Compone la música de las zonas y los jefes a partir de data/music.json y la
## guarda en assets/audio/music/<id>.wav (mono). Es música de programador, con
## sonido retro: si tienes un compositor, sustituye los .wav.
##
## Cada pista tiene una intro (las capas van entrando según "from") que suena una
## sola vez, y un cuerpo de "bars" compases (A y B, con redoble al final de cada
## parte) que se repite: el bucle empieza donde acaba la intro. El inicio del
## bucle de cada pista (en muestras) se guarda en data/music_loops.json,
## y las colas de las notas del último compás se escriben al inicio del bucle,
## para que la vuelta no tenga costura.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_zone_music.gd [-- id1 id2]
## Después: tools/convert_audio.ps1 pasa los .wav a OGG (el juego carga el OGG).

const RATE := 16000
const OUT_DIR := "res://assets/audio/music/"
const LOOPS_FILE := "res://data/music_loops.json"
## Capa de combate de las pistas de zona: solo batería y bajo, con la misma
## duración de intro y bucle, para sonar sincronizada encima (MusicPlayer.set_combat).
const COMBAT_SUFFIX := "_combate"
const COMBAT_DRUMS := ["soft", "drive", "ballad", "none"]
const SCALES := {
	"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10], "lydian": [0, 2, 4, 6, 7, 9, 11],
}
const QUALITIES := {
	"M": [0, 4, 7], "m": [0, 3, 7], "M7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "sus": [0, 5, 7], "dim": [0, 3, 6],
}
## Ritmos de la melodía (duraciones en tiempos; un valor negativo es silencio).
const RHYTHMS := [
	[2.0, 2.0], [1.0, 1.0, 2.0], [1.5, 0.5, 2.0], [1.0, 1.0, 1.0, 1.0], [3.0, 1.0], [0.5, 0.5, 1.0, 2.0],
	[-1.0, 1.0, 2.0], [2.0, 1.0, 1.0], [1.0, 0.5, 0.5, 2.0], [4.0],
]

var buf := PackedFloat32Array()
var rng := RandomNumberGenerator.new()
## Primera muestra del bucle: las colas que pasan del final vuelven aquí.
var loop_start := 0
## Grado de la primera nota del último compás compuesto por _melody.
var _first_idx := 7


func _initialize() -> void:
	var f := FileAccess.open("res://data/music.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var only: PackedStringArray = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var loops := {}
	if FileAccess.file_exists(LOOPS_FILE):
		loops = JSON.parse_string(FileAccess.get_file_as_string(LOOPS_FILE))
	for id in data["tracks"]:
		if not only.is_empty() and not (id in only) and not ((id + COMBAT_SUFFIX) in only):
			continue
		if only.is_empty() or id in only:
			loops[id] = _compose(id, data["tracks"][id])
		# Versión de combate: misma pista (tempo, compases y acordes) con batería
		# frenética y bajo pulsante; MusicPlayer cambia a ella en el mismo punto.
		if String(data["tracks"][id].get("drums", "none")) in COMBAT_DRUMS and not id.ends_with("_fase") \
				and not id.begins_with("camp") and not id.begins_with("boss"):
			var t: Dictionary = data["tracks"][id].duplicate(true)
			t["drums"] = "frenzy"
			t["bass"] = "pulse"   # "from" igual: la intro dura lo mismo y el bucle empieza en el mismo sitio
			# Solo batería y bajo: es una capa que suena ENCIMA de la pista de la zona.
			t["lead"] = "none"
			t["arp"] = "none"
			t["pad"] = 0.0
			loops[id + COMBAT_SUFFIX] = _compose(id + COMBAT_SUFFIX, t)
	FileAccess.open(LOOPS_FILE, FileAccess.WRITE).store_string(JSON.stringify(loops, "  ", true))
	quit()


## Compases de intro: los necesarios para que entren todas las capas, redondeados
## a vueltas enteras de la progresión (así el bucle empieza en el primer acorde).
static func intro_bars(t: Dictionary) -> int:
	if t.has("intro"):
		return int(t["intro"])
	var cycle: int = t["prog"].size() * int(t.get("chord_bars", 1))
	var latest := 0
	for v in t.get("from", {}).values():
		latest = maxi(latest, int(v))
	return int(ceil(latest / float(cycle))) * cycle


## Devuelve la muestra donde empieza el bucle.
func _compose(id: String, t: Dictionary) -> int:
	rng.seed = int(t.get("seed", 1))
	var bpm := float(t["bpm"])
	var beat := 60.0 / bpm
	var intro := intro_bars(t)
	var body := int(t["bars"])
	var half := body / 2
	var chord_bars := int(t.get("chord_bars", 1))
	var root := int(t["root"])
	var scale: Array = SCALES[t.get("scale", "minor")]
	var from: Dictionary = t.get("from", {})
	var written: Array = t.get("melody", [])
	var from_file: Array = load_melody_file(String(t["melody_file"])) if t.has("melody_file") else []
	var lead := String(t.get("lead", "none"))
	buf.clear()
	buf.resize(int((intro + body) * 4 * beat * RATE))
	loop_start = int(intro * 4 * beat * RATE)
	var mel_idx := 7  # grado actual de la melodía (índice sobre la escala extendida)
	var body_first_idx := -1
	for bar in intro + body:
		var b := bar - intro   # compás dentro del cuerpo (negativo en la intro)
		var part_b := b >= half and t.has("prog_b")
		var prog: Array = t["prog_b"] if part_b else t["prog"]
		var chord_bar := bar if b < 0 else (b - half if part_b else b)
		var spec: Array = prog[(chord_bar / chord_bars) % prog.size()]
		var croot: int = root + int(spec[0])
		var tones: Array = QUALITIES[spec[1]]
		var t0 := bar * 4 * beat
		var pad_gain := float(t.get("pad", 0.04))
		if pad_gain > 0.0:
			for tone in tones:
				_note(t0, 4.0 * beat, croot + int(tone), "pad", pad_gain * 0.9)
		_bass(t0, beat, croot + int(t.get("bass_shift", 0)), String(t.get("bass", "root")))
		if b >= 0 or bar >= int(from.get("arp", 0)):
			# En la parte B el arpegio sube una octava: la misma canción, otro color.
			_arp(t0, beat, croot + (12 if b >= half and t.get("arp_lift", false) else 0), tones,
				String(t.get("arp", "none")), String(t.get("arp_wave", "square")))
		if b >= 0 or bar >= int(from.get("drums", 0)):
			var fill := b == half - 1 or b == body - 1
			_drums(t0, beat, String(t.get("drums", "none")), bar, fill)
		if lead == "none" or (b < 0 and bar < int(from.get("lead", 0))):
			continue
		if b >= 0 and not from_file.is_empty():
			_file_bar(t0, beat, from_file[b % from_file.size()], lead, float(t.get("lead_gain", 0.09)))
		elif b >= 0 and not written.is_empty():
			_written_bar(t0, beat, String(written[b % written.size()]), root, scale, lead, float(t.get("lead_gain", 0.09)))
		elif b == body - 1 and body_first_idx >= 0:
			mel_idx = _melody_to(t0, beat, root, scale, mel_idx, body_first_idx, lead)
		else:
			mel_idx = _melody(t0, beat, croot, tones, root, scale, mel_idx, lead)
			if b == 0:
				body_first_idx = _first_idx
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.save_to_wav(ProjectSettings.globalize_path(OUT_DIR + id + ".wav"))
	print("Escrito %s%s.wav (%.1f s, bucle desde %.1f s)" % [OUT_DIR, id, buf.size() / float(RATE), loop_start / float(RATE)])
	return loop_start


func _bass(t0: float, beat: float, croot: int, kind: String) -> void:
	var low := croot - 12
	match kind:
		"root":
			_note(t0, 2.0 * beat, low, "tri", 0.2)
			_note(t0 + 2.0 * beat, 2.0 * beat * 0.9, low, "tri", 0.16)
		"walk":
			for q in 4:
				_note(t0 + q * beat, beat * 0.9, low + [0, 7, 12, 7][q], "saw", 0.12)
		"eighth":
			for e in 8:
				_note(t0 + e * beat / 2.0, beat / 2.0 * 0.85, low + (7 if e == 6 else 0), "saw", 0.15 if e % 2 == 0 else 0.1)
		"pulse":
			for e in 8:
				var n := low + (12 if e % 4 == 3 else 0)
				_note(t0 + e * beat / 2.0, beat / 2.0 * 0.7, n, "saw", 0.17 if e % 2 == 0 else 0.12)


func _arp(t0: float, beat: float, croot: int, tones: Array, kind: String, wave: String) -> void:
	var n := tones.size()
	match kind:
		"up":
			for s in 16:
				var octave := 12 if (s / 3) % 2 == 0 else 24
				var m: int = croot + int(tones[s % n]) + octave
				var tt := t0 + s * beat / 4.0
				_note(tt, beat / 4.0, m, wave, 0.045)
				_note(tt + beat * 0.75, beat / 4.0, m, wave, 0.016)
		"broken":
			for e in 8:
				var m: int = croot + int(tones[[0, 2, 1, 2][e % 4] % n]) + 12 + (12 if e >= 4 else 0)
				_note(t0 + e * beat / 2.0, beat * 1.2, m, wave, 0.07)
		"ballad":
			var shape := [0, 2, 3, 4, 3, 2, 4, 2]
			var steps := [0, int(tones[1]), int(tones[2]), 12, 12 + int(tones[1])]
			for e in 8:
				var m: int = croot + int(steps[shape[e]])
				_note(t0 + e * beat / 2.0, beat * 1.6, m, wave, 0.075 if e % 2 == 0 else 0.055)


## `fill`: último compás de una parte; la segunda mitad es un redoble que
## anuncia la vuelta (o el paso a la parte B).
func _drums(t0: float, beat: float, kind: String, bar: int, fill := false) -> void:
	if kind == "none":
		return
	if fill:
		_kick(t0, 0.3)
		_snare(t0 + beat, 0.35 if kind in ["soft", "ballad"] else 0.8)
		var steps := 4 if kind in ["soft", "ballad"] else 8
		for s in steps:
			var level := (0.15 + 0.5 * s / steps) * (0.6 if kind in ["soft", "ballad"] else 1.2)
			_snare(t0 + 2.0 * beat + s * 2.0 * beat / steps, level)
		return
	match kind:
		"soft":
			_kick(t0, 0.3)
			_kick(t0 + 2.0 * beat, 0.22)
			for h in 4:
				_hat(t0 + (h * 2 + 1) * beat / 2.0, 0.018)
		"ballad":
			_kick(t0, 0.32)
			_kick(t0 + 2.5 * beat, 0.2)
			_snare(t0 + 2.0 * beat, 0.45)
			if bar % 2 == 1:
				_snare(t0 + 3.5 * beat, 0.2)
			for h in 8:
				_hat(t0 + h * beat / 2.0, 0.012 if h % 2 == 0 else 0.008)
		"drive":
			for b in 4:
				if b % 2 == 0:
					_kick(t0 + b * beat, 0.5)
				else:
					_snare(t0 + b * beat, 1.0)
			for h in 8:
				_hat(t0 + h * beat / 2.0, 0.035 if h % 2 == 0 else 0.02)
		"frenzy":
			# Fase de jefe: bombo a corcheas, caja doble en 2 y 4, platillo al empezar el compás.
			for e in 8:
				_kick(t0 + e * beat / 2.0, 0.5 if e % 2 == 0 else 0.32)
			for b in [1, 3]:
				_snare(t0 + b * beat, 1.1)
				_snare(t0 + (b + 0.25) * beat, 0.45)
			for h in 16:
				_hat(t0 + h * beat / 4.0, 0.034 if h % 2 == 0 else 0.02)
			if bar % 2 == 0:
				_crash(t0, 0.5)
		"boss":
			for b in 4:
				_kick(t0 + b * beat, 0.55)
				if b % 2 == 1:
					_snare(t0 + b * beat, 1.1)
				else:
					_kick(t0 + (b + 0.5) * beat, 0.3)
			for h in 16:
				_hat(t0 + h * beat / 4.0, 0.03 if h % 4 == 0 else 0.016)


## Compone un compás de melodía; devuelve el último grado usado.
func _melody(t0: float, beat: float, croot: int, tones: Array, root: int, scale: Array, idx: int, lead: String) -> int:
	var rhythm: Array = RHYTHMS[rng.randi() % RHYTHMS.size()]
	var pos := 0.0
	var first := true
	for d in rhythm:
		var dur := absf(float(d))
		if d > 0.0:
			if first:
				idx = _nearest_chord_degree(idx, croot, tones, root, scale)
				_first_idx = idx
			else:
				var step: int = [-2, -1, -1, 1, 1, 2][rng.randi() % 6]
				idx = clampi(idx + step, 3, 13)
			_note(t0 + pos * beat, dur * beat * 0.95, _degree_midi(idx, root, scale) + 12, lead, 0.075)
			first = false
		pos += dur
	return idx


## Último compás antes de la vuelta: la melodía camina por grados hacia la
## primera nota del bucle y se queda a un paso de ella (la vuelta la resuelve).
func _melody_to(t0: float, beat: float, root: int, scale: Array, idx: int, target: int, lead: String) -> int:
	var pos := 0.0
	for d in [1.0, 1.0, 2.0]:
		var gap := target - idx
		if absi(gap) > 1:
			idx += clampi(gap - signi(gap), -2, 2)
		_note(t0 + pos * beat, d * beat * 0.95, _degree_midi(idx, root, scale) + 12, lead, 0.075)
		pos += d
	return idx


## Un compás de melodía escrita: "grado:tiempos grado:tiempos ...", con "r" para
## los silencios. El grado 7 es la tónica central (Re4 si la tónica es Re).
func _written_bar(t0: float, beat: float, bar: String, root: int, scale: Array, lead: String, gain: float) -> void:
	var pos := 0.0
	for token in bar.split(" ", false):
		var parts := token.split(":")
		var dur := float(parts[1]) if parts.size() > 1 else 1.0
		if parts[0] != "r":
			_note(t0 + pos * beat, dur * beat * 0.95, _degree_midi(int(parts[0]), root, scale), lead, gain)
		pos += dur
	if absf(pos - 4.0) > 0.01:
		push_warning("Compás de melodía que no suma 4 tiempos (%.2f): %s" % [pos, bar])


## Melodía en un archivo aparte (formato de nota por nota: {"bar", "note" como
## "F#4" o "REST", "duration" como "1/8", "velocity"}). Devuelve un arreglo por
## compás con [midi (-1 = silencio), tiempos, velocidad].
static func load_melody_file(path: String) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var bars := []
	bars.resize(int(data.get("total_bars", 1)))
	for i in bars.size():
		bars[i] = []
	for ev: Dictionary in data["tracks"]["melody"]:
		var frac := String(ev["duration"]).split("/")
		var beats := 4.0 * float(frac[0]) / float(frac[1]) if frac.size() == 2 else float(frac[0])
		(bars[int(ev["bar"]) - 1] as Array).append([note_midi(String(ev["note"])), beats, float(ev.get("velocity", 0.8))])
	return bars


## "C4" = 60; admite "#" y "b". "REST" (o cualquier otra cosa) = -1.
static func note_midi(note: String) -> int:
	var pcs := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	if note.length() < 2 or not pcs.has(note[0]):
		return -1
	var pc: int = pcs[note[0]]
	var rest := note.substr(1)
	if rest.begins_with("#"):
		pc += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		pc -= 1
		rest = rest.substr(1)
	return 12 * (int(rest) + 1) + pc


func _file_bar(t0: float, beat: float, events: Array, lead: String, gain: float) -> void:
	var pos := 0.0
	for ev: Array in events:
		if int(ev[0]) >= 0:
			_note(t0 + pos * beat, float(ev[1]) * beat * 0.95, int(ev[0]), lead, gain * float(ev[2]))
		pos += float(ev[1])
	if absf(pos - 4.0) > 0.01:
		push_warning("Compás de melodía que no suma 4 tiempos (%.2f)" % pos)


func _degree_midi(idx: int, root: int, scale: Array) -> int:
	return root + 12 * (idx / scale.size()) + int(scale[idx % scale.size()])


func _nearest_chord_degree(idx: int, croot: int, tones: Array, root: int, scale: Array) -> int:
	var best := idx
	var best_d := 999
	for cand in range(maxi(3, idx - 4), mini(13, idx + 4) + 1):
		var pc := posmod(_degree_midi(cand, root, scale) - croot, 12)
		for tone in tones:
			if pc == int(tone) and absi(cand - idx) < best_d:
				best_d = absi(cand - idx)
				best = cand
	return best


func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Escribe con vuelta al inicio del bucle, para que no tenga costura.
func _put(i: int, v: float) -> void:
	if i >= buf.size():
		i = loop_start + (i - buf.size()) % (buf.size() - loop_start)
	buf[i] += v


func _note(start: float, duration: float, midi: int, wave: String, gain: float) -> void:
	var f := _freq(midi)
	var i0 := int(start * RATE)
	var tail := 1.0 if wave in ["bell", "piano", "pluck"] else 0.0
	var n := int((duration + tail) * RATE)
	for k in n:
		var t := float(k) / RATE
		var phase := fmod(t * f, 1.0)
		var v := 0.0
		var env := 1.0
		match wave:
			"saw":
				v = 2.0 * phase - 1.0
				env = exp(-t * 6.0) * minf(1.0, t * 400.0)
			"square":
				v = 1.0 if phase < 0.5 else -1.0
				env = exp(-t * 14.0) * minf(1.0, t * 600.0)
			"pluck":
				v = 1.0 if phase < 0.25 else -1.0
				env = exp(-t * 9.0) * minf(1.0, t * 800.0)
			"tri":
				v = 4.0 * absf(phase - 0.5) - 1.0
				env = exp(-t * 2.2) * minf(1.0, t * 300.0)
			"bell":
				v = sin(t * f * TAU) * 0.7 + sin(t * f * 2.76 * TAU) * 0.2 + sin(t * f * 5.4 * TAU) * 0.1
				env = exp(-t * 3.2) * minf(1.0, t * 800.0)
			"piano":
				v = sin(t * f * TAU) * 0.6 + sin(t * f * 2.0 * TAU) * 0.28 * exp(-t * 3.0) + sin(t * f * 3.0 * TAU) * 0.12 * exp(-t * 5.0)
				env = exp(-t * 2.4) * minf(1.0, t * 900.0)
			"pad":
				var p2 := fmod(t * f * 1.006, 1.0)
				v = (2.0 * phase - 1.0) * 0.5 + (2.0 * p2 - 1.0) * 0.5
				env = minf(1.0, t / 0.6) * minf(1.0, (duration - t) / 0.4)
		if env <= 0.0001 and k > 100:
			break
		_put(i0 + k, v * env * gain)


func _kick(start: float, level: float) -> void:
	var i0 := int(start * RATE)
	var phase := 0.0
	for k in int(0.25 * RATE):
		var t := float(k) / RATE
		phase += (45.0 + 90.0 * exp(-t * 30.0)) / RATE
		_put(i0 + k, sin(phase * TAU) * exp(-t * 12.0) * level)


func _snare(start: float, level: float) -> void:
	var i0 := int(start * RATE)
	for k in int(0.18 * RATE):
		var t := float(k) / RATE
		_put(i0 + k, (rng.randf_range(-1.0, 1.0) * 0.7 + sin(t * 190.0 * TAU) * 0.3) * exp(-t * 22.0) * 0.22 * level)


## Platillo: ruido brillante que se apaga despacio.
func _crash(start: float, level: float) -> void:
	var i0 := int(start * RATE)
	var last := 0.0
	for k in int(0.9 * RATE):
		var t := float(k) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		_put(i0 + k, (noise - last * 0.6) * exp(-t * 4.5) * 0.09 * level)
		last = noise


func _hat(start: float, gain: float) -> void:
	var i0 := int(start * RATE)
	var last := 0.0
	for k in int(0.04 * RATE):
		var t := float(k) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		_put(i0 + k, (noise - last) * exp(-t * 90.0) * gain * 4.0)
		last = noise
