class_name GraphicsQuality
## Calidad gráfica (T98, Pausa → Gráficos): baja, media o alta. Ajusta cuántas luces
## dinámicas hay en pantalla, el presupuesto de partículas de los efectos grandes,
## el bloom de las luces, la distorsión de calor del fuego y la onda de choque de
## los golpes grandes.

enum Level { LOW, MEDIUM, HIGH }
const NAMES := ["baja", "media", "alta"]
## lights: luces dinámicas; particles: partículas vivas como mucho (efectos grandes);
## bloom: halo suave de las luces; heat: distorsión de calor; shock: ondas de choque;
## flashes: luces de golpes y proyectiles.
const PRESETS := [
	{"lights": 10, "particles": 0, "bloom": 0.0, "heat": false, "shock": false, "flashes": false},
	{"lights": 20, "particles": 320, "bloom": 0.5, "heat": false, "shock": true, "flashes": true},
	{"lights": 32, "particles": 900, "bloom": 1.0, "heat": true, "shock": true, "flashes": true},
]

## En el celular (T106), luces dinámicas como mucho, sea cual sea la calidad: cada luz
## es una pasada más del filtro del mundo y la GPU de un teléfono lo nota.
const MOBILE_LIGHTS := 12

static var level := clampi(int(GameSettings.get_value("graphics", "quality", Level.HIGH)), 0, 2)


static func set_level(value: int) -> void:
	level = clampi(value, 0, 2)
	GameSettings.set_value("graphics", "quality", level)


static func preset(at := -1) -> Dictionary:
	var p: Dictionary = PRESETS[level if at < 0 else clampi(at, 0, 2)]
	if GameSettings.is_mobile() and int(p["lights"]) > MOBILE_LIGHTS:
		p = p.duplicate()
		p["lights"] = MOBILE_LIGHTS
	return p


static func name_of(at := -1) -> String:
	return NAMES[level if at < 0 else clampi(at, 0, 2)]


## ¿Cabe un efecto de `amount` partículas con `live` ya vivas?
static func fits_particles(live: int, amount: int, at := -1) -> bool:
	return amount > 0 and live + amount <= int(preset(at)["particles"])
