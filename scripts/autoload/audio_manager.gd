extends Node
## Autoload "AudioManager": efectos cortos (habilidades, golpes, botín...) y el
## ambiente en bucle de cada zona (según su estilo), con fundido al cambiar.
## Los sonidos salen de tools/generate_sfx.gd; si falta alguno no pasa nada.
## Desde el juego se usa a través de Sfx (scripts/core/sfx.gd).
## Se puede silenciar cada parte desde el menú de pausa (user://settings.cfg).

const SFX_VOICES := 10
const SFX_DB := -10.0
const AMBIENT_DB := -16.0
const SILENT_DB := -60.0
## Tiempo mínimo entre dos reproducciones del mismo efecto (evita saturar
## cuando mueren 30 enemigos en el mismo fotograma).
const MIN_GAP := 0.06

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_played := {}
var _cache := {}
var _ambient: AudioStreamPlayer
var _ambient_name := ""
var _tween: Tween
## Volúmenes del menú (0..1), leídos una vez: los efectos suenan cientos de veces
## por minuto y no deben leer settings.cfg cada vez.
var _sfx_volume := 1.0
var _ambient_volume := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for k in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_voices.append(p)
	_ambient = AudioStreamPlayer.new()
	_ambient.volume_db = SILENT_DB
	add_child(_ambient)
	_ambient.finished.connect(func() -> void:
		if _ambient_name != "":
			_ambient.play())
	_read_volumes()


func _read_volumes() -> void:
	_sfx_volume = Sfx.sfx_volume()
	_ambient_volume = Sfx.ambient_volume()


## Reproduce un efecto. `volume` en dB relativos; `pitch` con una pequeña variación.
func play_sfx(sfx_name: String, volume := 0.0, pitch := 1.0) -> void:
	if _voices.is_empty() or _sfx_volume <= 0.001:   # aún sin iniciar (pruebas) o apagados
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sfx_name, -1.0)) < MIN_GAP:
		return
	var stream := _load(Sfx.SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	_last_played[sfx_name] = now
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.volume_db = SFX_DB + volume + linear_to_db(_sfx_volume)
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.play()


## Pone el ambiente de un estilo de zona ("" lo apaga).
func play_ambient(style: String) -> void:
	var amb := Sfx.ambient_for(style)
	if amb == _ambient_name and _ambient.playing:
		return
	_ambient_name = amb
	# Bucle real del propio stream (OGG o WAV): volver a lanzarlo al terminar deja un hueco.
	var stream: AudioStream = null if amb == "" else Sfx.load_looped(Sfx.AMB_DIR + amb)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _ambient.playing:
		_tween.tween_property(_ambient, "volume_db", SILENT_DB, 0.8)
	_tween.tween_callback(func() -> void:
		_ambient.stop()
		if stream:
			_ambient.stream = stream
			_ambient.volume_db = SILENT_DB
			_ambient.play())
	if stream:
		_tween.tween_property(_ambient, "volume_db", _ambient_db(), 1.5)


## Aplica los ajustes del menú (volumen de efectos y ambiente).
func refresh_settings() -> void:
	_read_volumes()
	if _ambient.playing:
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_ambient, "volume_db", _ambient_db(), 0.3)


func _ambient_db() -> float:
	return AMBIENT_DB + linear_to_db(_ambient_volume) if _ambient_volume > 0.001 else SILENT_DB


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
