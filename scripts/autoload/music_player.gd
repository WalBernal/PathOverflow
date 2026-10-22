extends Node
## Autoload "MusicPlayer": música de los menús, que sigue sonando al cambiar de
## pantalla (título → personajes → creador) y se apaga con un fundido al entrar
## en el juego. El silencio se recuerda en user://settings.cfg.

const TITLE_THEME := "res://assets/audio/title_theme.wav"
const SETTINGS_PATH := "user://settings.cfg"
const VOLUME_DB := -8.0
const SILENT_DB := -60.0

const TRACK_DIR := "res://assets/audio/music/"

var muted := false
## 0..1; se guarda en user://settings.cfg.
var music_volume := 1.0
var _player: AudioStreamPlayer
var _other: AudioStreamPlayer
var _tween: Tween
var _pitch_tween: Tween
var _wanted := false
var _track := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_other = AudioStreamPlayer.new()
	add_child(_player)
	add_child(_other)
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
	_crossfade_to(load(TITLE_THEME), 1.5)


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
	_wanted = true
	if not ResourceLoader.exists(path):
		push_warning("Falta %s: genera la música con tools/generate_zone_music.gd" % path)
		return
	var stream := load(path) as AudioStreamWAV
	if stream:
		# Bucle sin costura (las pistas están compuestas para enlazar).
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
	_track = id
	_crossfade_to(stream, fade)


## Intensidad del combate: 0 normal; cada fase de jefe sube un poco el tempo.
func set_intensity(level: int) -> void:
	var pitch := 1.0 + 0.04 * clampi(level, 0, 3)
	if _pitch_tween:
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_property(_player, "pitch_scale", pitch, 1.5)


func current_track() -> String:
	return _track


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
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_player, "volume_db", db, seconds)
	if _other.playing:  # un fundido cruzado a medias: la pista anterior se apaga
		_tween.tween_property(_other, "volume_db", SILENT_DB, seconds)
		_tween.chain().tween_callback(_other.stop)
