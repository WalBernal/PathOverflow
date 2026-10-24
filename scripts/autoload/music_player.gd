extends Node
## Autoload "MusicPlayer": música de los menús, que sigue sonando al cambiar de
## pantalla (título → personajes → creador) y se apaga con un fundido al entrar
## en el juego. El silencio se recuerda en user://settings.cfg.

const TITLE_THEME := "res://assets/audio/title_theme.wav"
const SETTINGS_PATH := "user://settings.cfg"
const VOLUME_DB := -8.0
const SILENT_DB := -60.0

const TRACK_DIR := "res://assets/audio/music/"
const LOOPS_FILE := "res://data/music_loops.json"
## Sufijo de las pistas de fase de jefe (boss1 → boss1_fase).
const PHASE_SUFFIX := "_fase"
## Pista de las fases de subjefe en zonas sin pista de fase propia.
const SUBBOSS_TRACK := "subjefe"

var muted := false
## 0..1; se guarda en user://settings.cfg.
var music_volume := 1.0
var _player: AudioStreamPlayer
var _other: AudioStreamPlayer
var _tween: Tween
var _pitch_tween: Tween
var _wanted := false
var _track := ""
var _loops := {}   # pista -> muestra donde empieza su bucle
var _base_track := ""   # pista de la zona (a la que se vuelve al acabar las fases)
## Capa de combate: batería y bajo (<pista>_combate) sonando encima de la pista,
## sincronizada con ella, que entra con muchos enemigos cerca (ver set_combat).
const COMBAT_SUFFIX := "_combate"
var _layer: AudioStreamPlayer
var _layer_tween: Tween
var combat := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_other = AudioStreamPlayer.new()
	add_child(_player)
	add_child(_other)
	_layer = AudioStreamPlayer.new()
	add_child(_layer)
	# Bucle del tema del título: al terminar vuelve a empezar (las pistas de zona enlazan solas).
	for p in [_player, _other]:
		(p as AudioStreamPlayer).finished.connect(func() -> void:
			if _wanted and _track == "" and not (p as AudioStreamPlayer).playing:
				(p as AudioStreamPlayer).play())
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))
		music_volume = float(cfg.get_value("audio", "music_volume", 1.0))


func play_title() -> void:
	_wanted = true
	_track = ""
	if _player.playing and _player.stream and _player.stream.resource_path == TITLE_THEME:
		_fade_to(_target_db(), 0.5)
		return
	if not ResourceLoader.exists(TITLE_THEME):
		push_warning("Falta %s: genera la música con tools/generate_music.gd" % TITLE_THEME)
		return
	var stream := load(TITLE_THEME) as AudioStreamWAV
	if stream:
		Sfx.set_loop(stream)
	_crossfade_to(stream, 1.5)


## Pista de una zona (data/music.json). Si ya suena, no se toca; si no, fundido cruzado.
func play_zone(zone_id: String) -> void:
	var track := String(GameData.music.get("zones", {}).get(zone_id, ""))
	if track == "":
		stop_music(1.5)
		return
	play_track(track)


func play_track(id: String, fade := 2.0) -> void:
	var path := "%s%s.wav" % [TRACK_DIR, id]
	if id == _track and _wanted:
		return
	set_combat(false)   # la capa es de la pista anterior
	_wanted = true
	if not ResourceLoader.exists(path):
		push_warning("Falta %s: genera la música con tools/generate_zone_music.gd" % path)
		return
	var stream := load(path) as AudioStreamWAV
	if stream:
		# La intro suena una vez; el bucle empieza donde acaba (music_loops.json, lo
		# escribe tools/generate_zone_music.gd) y enlaza sin costura.
		Sfx.set_loop(stream, int(_loop_starts().get(id, 0)))
	_track = id
	_crossfade_to(stream, fade)


func _loop_starts() -> Dictionary:
	if _loops.is_empty() and FileAccess.file_exists(LOOPS_FILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOPS_FILE))
		if parsed is Dictionary:
			_loops = parsed
	return _loops


## Intensidad del combate: 0 normal; en las fases de jefe suena la versión de
## fase de la pista (<pista>_fase: más rápida y con otra batería) si existe; si
## no (subjefes en zonas normales), la pista común de subjefe. Cada fase más sube
## un poco el tempo. Al volver a 0, vuelve la pista de la zona.
func set_intensity(level: int) -> void:
	if _base_track == "" or not (_track in [_base_track, _base_track + PHASE_SUFFIX, SUBBOSS_TRACK]):
		_base_track = _track   # la pista de la zona (cambió de zona desde la última vez)
	var base := _base_track
	if base != "":
		var want := base
		if level >= 1:
			if ResourceLoader.exists("%s%s%s.wav" % [TRACK_DIR, base, PHASE_SUFFIX]):
				want = base + PHASE_SUFFIX
			elif ResourceLoader.exists("%s%s.wav" % [TRACK_DIR, SUBBOSS_TRACK]):
				want = SUBBOSS_TRACK
		if want != _track:
			play_track(want, 1.2)
	var pitch := 1.0 + 0.03 * clampi(level - 1, 0, 3)
	if _pitch_tween:
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_property(_player, "pitch_scale", pitch, 1.5)


func current_track() -> String:
	return _track


## Capa de combate encima de la pista de la zona: entra con un fundido, en el
## mismo punto de la canción (misma intro y mismo bucle, ver generate_zone_music),
## y sale igual. Si la pista no tiene capa (campamentos, jefes), no hace nada.
func set_combat(on: bool) -> void:
	if on == combat:
		return
	combat = on
	if _layer_tween:
		_layer_tween.kill()
		_layer_tween = null
	if not on:
		_layer_tween = create_tween()
		_layer_tween.tween_property(_layer, "volume_db", SILENT_DB, 2.5)
		_layer_tween.tween_callback(_layer.stop)
		return
	var id := _track + COMBAT_SUFFIX
	var path := "%s%s.wav" % [TRACK_DIR, id]
	if _track == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		return
	Sfx.set_loop(stream, int(_loop_starts().get(id, 0)))
	_layer.stream = stream
	_layer.pitch_scale = _player.pitch_scale
	_layer.volume_db = SILENT_DB
	_layer.play(_player.get_playback_position())
	_layer_tween = create_tween()
	_layer_tween.tween_property(_layer, "volume_db", _target_db() - 2.0, 1.2)


## Nombre de la capa que suena ahora ("" si ninguna), para pruebas y depuración.
func combat_layer() -> String:
	return _layer.stream.resource_path.get_file().get_basename() if combat and _layer.playing and _layer.stream else ""


func set_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _player.playing:
		_fade_to(_target_db(), 0.2)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.save(SETTINGS_PATH)


func _crossfade_to(stream: AudioStream, fade: float) -> void:
	if _tween:
		_tween.kill()
	var old := _player
	_player = _other
	_other = old
	_player.stream = stream
	_player.pitch_scale = 1.0
	_player.volume_db = SILENT_DB
	_player.play()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_player, "volume_db", _target_db(), fade)
	if old.playing:
		_tween.tween_property(old, "volume_db", SILENT_DB, fade)
		_tween.chain().tween_callback(old.stop)


func stop_music(fade := 1.0) -> void:
	set_combat(false)
	_wanted = false
	_track = ""
	for p in [_player, _other]:
		if (p as AudioStreamPlayer).playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", SILENT_DB, fade)
			tw.tween_callback((p as AudioStreamPlayer).stop)


func toggle_mute() -> bool:
	muted = not muted
	if _player.playing:
		_fade_to(_target_db(), 0.3)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)
	return muted


func _target_db() -> float:
	if muted or music_volume <= 0.001:
		return SILENT_DB
	return VOLUME_DB + linear_to_db(music_volume)


func _fade_to(db: float, seconds: float) -> void:
	if combat and _layer.playing:
		_layer.volume_db = db - 2.0 if db > SILENT_DB else SILENT_DB   # la capa sigue al volumen y al silencio
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_player, "volume_db", db, seconds)
	if _other.playing:  # un fundido cruzado a medias: la pista anterior se apaga
		_tween.tween_property(_other, "volume_db", SILENT_DB, seconds)
		_tween.chain().tween_callback(_other.stop)
