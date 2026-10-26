extends Node
## Autoload "MusicPlayer": música de los menús, que sigue sonando al cambiar de
## pantalla (título → personajes → creador) y se apaga con un fundido al entrar
## en el juego. El silencio se recuerda en user://settings.cfg.

## Sin extensión: OGG (o WAV si aún no se ha convertido, ver Sfx.audio_path).
const TITLE_THEME := "res://assets/audio/title_theme"
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
	if _player.playing and _player.stream and _player.stream.resource_path.get_basename() == TITLE_THEME:
		_fade_to(_target_db(), 0.5)
		return
	var stream := Sfx.load_looped(TITLE_THEME)
	if stream == null:
		push_warning("Falta %s: genera la música con tools/generate_music.gd" % TITLE_THEME)
		return
	_crossfade_to(stream, 1.5)


## Pista de una zona (data/music.json). Si ya suena, no se toca; si no, fundido cruzado.
func play_zone(zone_id: String) -> void:
	var track := String(GameData.music.get("zones", {}).get(zone_id, ""))
	if track == "":
		stop_music(1.5)
		return
	play_track(track)


## `on_beat` (T78): espera al siguiente tiempo de la pista que suena para cambiar
## (el cambio cae a compás); `skip_intro`: la nueva entra ya en su bucle, con todas
## sus capas (para las fases de jefe: sin esperar a que arranque la intro).
func play_track(id: String, fade := 2.0, on_beat := false, skip_intro := false) -> void:
	if id == _track and _wanted:
		return
	if on_beat and _player.playing and _track != "":
		var wait := beat_wait(_player.get_playback_position(), bpm_of(_track))
		if wait > 0.02:
			_track = id   # ya decidido: que otra llamada en la espera no lo repita
			_wanted = true
			var tw := create_tween()
			tw.tween_interval(wait)
			tw.tween_callback(func() -> void:
				if _track == id:
					_track = ""
					play_track(id, fade, false, skip_intro))
			return
	set_combat(false)   # la capa es de la pista anterior (se apaga con su propio fundido)
	_wanted = true
	# La intro suena una vez; el bucle empieza donde acaba (music_loops.json, lo
	# escribe tools/generate_zone_music.gd) y enlaza sin costura.
	var loop_start := int(_loop_starts().get(id, 0))
	var stream := Sfx.load_looped(TRACK_DIR + id, loop_start, Sfx.MUSIC_RATE)
	if stream == null:
		push_warning("Falta %s%s: genera la música con tools/generate_zone_music.gd" % [TRACK_DIR, id])
		return
	_track = id
	_crossfade_to(stream, fade, float(loop_start) / Sfx.MUSIC_RATE if skip_intro else 0.0)


## Tempo de una pista (las de fase, el de su pista base: se aceleran con el tono).
func bpm_of(id: String) -> float:
	var tracks: Dictionary = GameData.music.get("tracks", {})
	var base := id.trim_suffix(PHASE_SUFFIX).trim_suffix(COMBAT_SUFFIX)
	return float(tracks.get(id, tracks.get(base, {})).get("bpm", 120.0))


static func beat_wait(position: float, bpm: float) -> float:
	return SoundMap.beat_wait(position, bpm)


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
			if Sfx.audio_path(TRACK_DIR + base + PHASE_SUFFIX) != "":
				want = base + PHASE_SUFFIX
			elif Sfx.audio_path(TRACK_DIR + SUBBOSS_TRACK) != "":
				want = SUBBOSS_TRACK
		if want != _track:
			# A compás y entrando ya en el bucle: la fase empieza sin corte ni intro (T78).
			play_track(want, 1.6, true, level >= 1)
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
	if _track == "":
		return
	var stream := Sfx.load_looped(TRACK_DIR + id, int(_loop_starts().get(id, 0)), Sfx.MUSIC_RATE)
	if stream == null:
		return
	_layer.stream = stream
	_layer.pitch_scale = _player.pitch_scale
	_layer.volume_db = SILENT_DB
	_layer.play(_player.get_playback_position())
	_layer_tween = create_tween()
	_layer_tween.tween_property(_layer, "volume_db", _target_db() - 2.0, 1.2)


## Avisos cortos (T78): "elite", "loot", "level" o "boss" (assets/audio/sfx/sting_<tipo>.wav).
## Suenan con el volumen de la música y la bajan un momento para que se oigan. El
## mismo aviso no se repite antes de STINGER_GAP s (el de jefe, siempre).
const STINGER_GAP := 6.0
const STINGER_DUCK_DB := 7.0
var _sting: AudioStreamPlayer
var _sting_last := {}


func stinger(kind: String) -> bool:
	if _player == null:
		return false   # sin preparar (pruebas)
	var now := Time.get_ticks_msec() / 1000.0
	if kind != "boss" and now - float(_sting_last.get(kind, -100.0)) < STINGER_GAP:
		return false
	var stream := load(Sfx.SFX_DIR + "sting_" + kind + ".wav") as AudioStream if ResourceLoader.exists(Sfx.SFX_DIR + "sting_" + kind + ".wav") else null
	if stream == null or _target_db() <= SILENT_DB:
		return false
	_sting_last[kind] = now
	if _sting == null:
		_sting = AudioStreamPlayer.new()
		add_child(_sting)
	_sting.stream = stream
	_sting.volume_db = _target_db() + 3.0
	_sting.play()
	# Baja la música mientras suena el aviso y luego vuelve.
	if _player.playing:
		var length := stream.get_length()
		var duck := create_tween()
		duck.tween_property(_player, "volume_db", _target_db() - STINGER_DUCK_DB, 0.08)
		duck.tween_interval(maxf(0.1, length - 0.5))
		duck.tween_property(_player, "volume_db", _target_db(), 0.6)
	return true


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


func _crossfade_to(stream: AudioStream, fade: float, from_position := 0.0) -> void:
	if _tween:
		_tween.kill()
	var old := _player
	_player = _other
	_other = old
	_player.stream = stream
	_player.pitch_scale = 1.0
	_player.volume_db = SILENT_DB
	_player.play(from_position)
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
