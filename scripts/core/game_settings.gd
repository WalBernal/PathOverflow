class_name GameSettings
## Opciones del jugador en user://settings.cfg (el mismo archivo que usa
## MusicPlayer para el silencio). Se lee y se escribe al momento: son pocas.

const PATH := "user://settings.cfg"


static func get_value(section: String, key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return default
	return cfg.get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # si no existe, se crea
	cfg.set_value(section, key, value)
	cfg.save(PATH)
