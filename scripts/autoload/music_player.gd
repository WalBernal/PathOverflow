extends Node
## Autoload "MusicPlayer": música de los menús, que sigue sonando al cambiar de
## pantalla (título → personajes → creador) y se apaga con un fundido al entrar
## en el juego. El silencio se recuerda en user://settings.cfg.

const TITLE_THEME := "res://assets/audio/title_theme.wav"
const SETTINGS_PATH := "user://settings.cfg"
const VOLUME_DB := -8.0
const SILENT_DB := -60.0

var muted := false
var _player: AudioStreamPlayer
var _tween: Tween
var _wanted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	# Bucle: al terminar vuelve a empezar (el tema está pensado para enlazar).
	_player.finished.connect(func() -> void:
		if _wanted:
			_player.play())
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))


func play_title() -> void:
	_wanted = true
	if _player.playing and _player.stream and _player.stream.resource_path == TITLE_THEME:
		_fade_to(_target_db(), 0.5)
		return
	if not ResourceLoader.exists(TITLE_THEME):
		push_warning("Falta %s: genera la música con tools/generate_music.gd" % TITLE_THEME)
		return
	_player.stream = load(TITLE_THEME)
	_player.volume_db = SILENT_DB
	_player.play()
	_fade_to(_target_db(), 1.5)


func stop_music(fade := 1.0) -> void:
	_wanted = false
	if not _player.playing:
		return
	_fade_to(SILENT_DB, fade)
	_tween.tween_callback(_player.stop)


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
	return SILENT_DB if muted else VOLUME_DB


func _fade_to(db: float, seconds: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", db, seconds)
