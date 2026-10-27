class_name GameSettings
## Opciones del jugador en user://settings.cfg (el mismo archivo que usa
## MusicPlayer para el silencio). Se lee y se escribe al momento: son pocas.

const PATH := "user://settings.cfg"

## Valores por defecto en el celular (T106) mientras el jugador no elija otro:
## calidad media (las luces, además, con el tope de GraphicsQuality.MOBILE_LIGHTS)
## e interfaz al 140 % para que se lea y se toque bien en una pantalla chica.
const MOBILE_DEFAULTS := {
	"graphics/quality": 1,
	"interface/scale": 1.4,
}

## Para las pruebas y las capturas: hacer como si fuera un celular.
static var force_mobile := false


## Celular o tableta (export de Android o iOS). Una laptop con pantalla táctil no cuenta:
## tiene su tarjeta gráfica y su teclado, y no debe bajar la calidad por defecto.
static func is_mobile() -> bool:
	return force_mobile or OS.has_feature("mobile")


static func get_value(section: String, key: String, default: Variant) -> Variant:
	if is_mobile():
		default = MOBILE_DEFAULTS.get(section + "/" + key, default)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return default
	return cfg.get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # si no existe, se crea
	cfg.set_value(section, key, value)
	cfg.save(PATH)
