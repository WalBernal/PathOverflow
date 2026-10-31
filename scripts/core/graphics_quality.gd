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

## Límite de FPS (T144, Pausa → Gráficos): -1 automático, 0 sin límite, 30 o 60.
## Automático: sin límite en el PC; en el celular 60 hasta medir la partida y, si va
## por debajo de AUTO_SLOW de media, 30 (ahorra batería y calor; el jugador puede elegir).
const FPS_CHOICES := [-1, 30, 60, 0]
const FPS_NAMES := {-1: "auto", 30: "30", 60: "60", 0: "sin límite"}
const AUTO_SLOW := 50.0


static func fps_choice() -> int:
	var v := int(GameSettings.get_value("graphics", "max_fps", -1))
	return v if FPS_CHOICES.has(v) else -1


static func set_fps_choice(v: int) -> void:
	GameSettings.set_value("graphics", "max_fps", v)
	apply_fps()


## El límite que se usa ahora (0 = sin límite).
static func effective_fps() -> int:
	var v := fps_choice()
	if v >= 0:
		return v
	return int(GameSettings.get_value("graphics", "auto_fps", 60)) if GameSettings.is_mobile() else 0


static func apply_fps() -> void:
	Engine.max_fps = effective_fps()


## Tras medir la partida (media de FPS): en automático y en el celular, si va lento,
## baja a 30 y lo recuerda. true si cambió (para avisar).
static func auto_measured(average_fps: float) -> bool:
	if fps_choice() != -1 or not GameSettings.is_mobile() or average_fps >= AUTO_SLOW \
			or int(GameSettings.get_value("graphics", "auto_fps", 60)) == 30:
		return false
	GameSettings.set_value("graphics", "auto_fps", 30)
	apply_fps()
	return true


static func fps_name() -> String:
	var v := fps_choice()
	return FPS_NAMES[v] + (" (%d)" % effective_fps() if v == -1 and effective_fps() > 0 else "")


## Tamaño del mundo (T156, Pausa → Gráficos): zoom de la cámara del jugador. Agranda
## personajes, enemigos, botín y efectos sin tocar la lógica ni las colisiones.
## -1 = automático: WORLD_ZOOM_TOUCH en el celular y 1 en el PC.
const WORLD_ZOOMS := [-1.0, 1.0, 1.15, 1.3, 1.4]
const WORLD_ZOOM_TOUCH := 1.3
## Lo que tiene que verse alrededor del jugador como mínimo (el alcance del
## auto-ataque y de la mira, SkillController.AUTO_ATTACK_RANGE): pone tope al zoom.
const WORLD_ZOOM_REACH := 320.0


static func world_zoom_choice() -> float:
	var v := float(GameSettings.get_value("graphics", "world_zoom", -1.0))
	for z in WORLD_ZOOMS:
		if is_equal_approx(v, z):
			return z
	return -1.0


static func set_world_zoom_choice(v: float) -> void:
	GameSettings.set_value("graphics", "world_zoom", v)


## El zoom que se usa con una vista (lienzo) de `view` píxeles: el elegido o el
## automático, sin pasar del que deja ver WORLD_ZOOM_REACH alrededor del jugador.
static func world_zoom(view: Vector2, mobile := GameSettings.is_mobile(), choice := world_zoom_choice()) -> float:
	var z := choice if choice > 0.0 else (WORLD_ZOOM_TOUCH if mobile else 1.0)
	return minf(z, max_world_zoom(view))


static func max_world_zoom(view: Vector2) -> float:
	return maxf(1.0, minf(view.x, view.y) / (2.0 * WORLD_ZOOM_REACH))


static func world_zoom_name(view: Vector2) -> String:
	var pct := "%d %%" % roundi(world_zoom(view) * 100.0)
	return ("auto (%s)" % pct) if world_zoom_choice() < 0.0 else pct


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
