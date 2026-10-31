class_name WorldPost
extends Node
## Filtro del mundo (assets/shaders/world_post.gdshader) en dos pasadas, dentro
## del propio mundo para elegir qué queda debajo:
## - Pixel art: justo después de la zona (suelo, decorado, puertas). Jugador,
##   enemigos, botín y textos se dibujan después y quedan nítidos.
## - Luz: con z_index 1, encima de enemigos, jugador y habilidades, pero debajo
##   del botín (z 2) y de los nombres (z 3): gradación, viñeta y oscuridad.
## El pixelado se apaga en Pausa → Interfaz; la luz de cada zona se queda.

const SHADER := preload("res://assets/shaders/world_post.gdshader")
## Por estilo: tinte, cuánto tinte, saturación, viñeta, oscuridad, radio de luz.
const GRADES := {
	"sandbox": {"tint": "8ab4ff", "amount": 0.18, "sat": 1.1, "vignette": 0.45, "dark": 0.0},
	"camp": {"tint": "ffb878", "amount": 0.22, "sat": 1.1, "vignette": 0.45, "dark": 0.15, "radius": 620.0},
	"forest": {"tint": "d8f0b0", "amount": 0.14, "sat": 1.0, "vignette": 0.45, "dark": 0.15, "radius": 640.0},
	"ruins": {"tint": "ffd8a0", "amount": 0.2, "sat": 1.0, "vignette": 0.4, "dark": 0.0},
	"swamp": {"tint": "b4a0e0", "amount": 0.25, "sat": 1.05, "vignette": 0.5, "dark": 0.38, "radius": 520.0},
	"catacombs": {"tint": "a0b8ff", "amount": 0.25, "sat": 0.85, "vignette": 0.55, "dark": 0.58, "radius": 400.0},
	"servers": {"tint": "90e8ff", "amount": 0.22, "sat": 1.1, "vignette": 0.45, "dark": 0.3, "radius": 560.0},
	"boss": {"tint": "ff8a70", "amount": 0.25, "sat": 1.15, "vignette": 0.55, "dark": 0.25, "radius": 600.0},
	# Acto II: el sistema operativo.
	"kernel": {"tint": "8ab4ff", "amount": 0.2, "sat": 1.05, "vignette": 0.5, "dark": 0.2, "radius": 600.0},
	"terminal": {"tint": "a0ffb0", "amount": 0.18, "sat": 1.05, "vignette": 0.45, "dark": 0.1, "radius": 640.0},
	"fabrica": {"tint": "ffcc90", "amount": 0.2, "sat": 1.0, "vignette": 0.45, "dark": 0.15, "radius": 620.0},
	"alcantarillas": {"tint": "90e0d0", "amount": 0.22, "sat": 0.95, "vignette": 0.55, "dark": 0.42, "radius": 480.0},
	"frio": {"tint": "b0d8ff", "amount": 0.28, "sat": 0.85, "vignette": 0.45, "dark": 0.1, "radius": 640.0},
	"fosa": {"tint": "e0c8a0", "amount": 0.2, "sat": 0.85, "vignette": 0.55, "dark": 0.35, "radius": 500.0},
	"grieta": {"tint": "c0a0ff", "amount": 0.24, "sat": 1.0, "vignette": 0.55, "dark": 0.4, "radius": 480.0},
	"bus": {"tint": "90b8ff", "amount": 0.2, "sat": 1.1, "vignette": 0.45, "dark": 0.15, "radius": 620.0},
	"anillo": {"tint": "ffa070", "amount": 0.25, "sat": 1.15, "vignette": 0.55, "dark": 0.25, "radius": 600.0},
	# Acto III: el silicio.
	"silicio": {"tint": "a8c8ff", "amount": 0.2, "sat": 1.05, "vignette": 0.45, "dark": 0.15, "radius": 620.0},
	"bios": {"tint": "8aa8ff", "amount": 0.25, "sat": 1.1, "vignette": 0.45, "dark": 0.1, "radius": 640.0},
	"rom": {"tint": "d0a8ff", "amount": 0.25, "sat": 1.1, "vignette": 0.5, "dark": 0.3, "radius": 540.0},
	"flash": {"tint": "ff9080", "amount": 0.25, "sat": 1.15, "vignette": 0.55, "dark": 0.25, "radius": 600.0},
	"setup": {"tint": "6a80ff", "amount": 0.2, "sat": 1.1, "vignette": 0.4, "dark": 0.08, "radius": 660.0},
	"vga16": {"tint": "c0c0c0", "amount": 0.1, "sat": 1.3, "vignette": 0.5, "dark": 0.2, "radius": 560.0},
}

## Luces dinámicas (máx. MAX_LIGHTS en pantalla, como el shader): las fijas de la
## zona (antorchas, hogueras, portales), los destellos de golpes y muertes, las
## explosiones y los proyectiles elementales, los tuyos y los de los enemigos.
const MAX_LIGHTS := 32
## Colores de los proyectiles de cada tipo que alumbran (los físicos no).
const PROJECTILE_LIGHT := {"fire": Color("ff8a3a"), "lightning": Color("fff0a0"), "cold": Color("9fd8ff"), "chaos": Color("8aff70")}

## Luces y clima reducidos (Pausa → Interfaz): sin destellos de golpes ni de
## proyectiles, como mucho LOW_LIGHTS luces y sin lluvia ni niebla (Weather).
const LOW_LIGHTS := 10
static var reduced := bool(GameSettings.get_value("interface", "reduced_lights", false))

var player: Node2D
var skills: SkillController
var enemies: EnemyManager
var loot: LootManager
var _zone: Zone
var _pixel: _Pass
var _light: _Pass
var _radius := 500.0
## Última lista enviada al shader (para pruebas y depuración): [{pos, radius, color, power}].
var last_lights: Array[Dictionary] = []


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "pixel_filter", true))


## Efectos de pantalla (luz y filtro): las dos pasadas copian la pantalla entera
## (BackBufferCopy). Se pueden apagar del todo (Pausa → Gráficos): en algunos celulares,
## con el renderizador Mobile, esa copia parecía tapar a ratos la interfaz.
static func screen_fx() -> bool:
	return bool(GameSettings.get_value("interface", "screen_fx", true))


func _ready() -> void:
	add_to_group(&"world_post")


## Mete las dos pasadas en el mundo, la de pixel art justo después de la zona.
func attach(world: Node, zone: Node) -> void:
	if _pixel == null:
		_pixel = _Pass.new(true)
		_light = _Pass.new(false)
	for p in [_pixel, _light]:
		if p.get_parent() != world:
			if p.get_parent():
				p.get_parent().remove_child(p)
			world.add_child(p)
	world.move_child(_pixel, zone.get_index() + 1)
	_zone = zone as Zone
	refresh()


func refresh() -> void:
	if _pixel:
		_pixel.visible = enabled() and screen_fx()
		_light.visible = screen_fx()


## `extra_dark` (T117): oscuridad de más de la instancia (apagón parcial).
func set_style(style: String, extra_dark := 0.0) -> void:
	var g: Dictionary = GRADES.get(style, {"tint": "ffffff", "amount": 0.0, "sat": 1.05, "vignette": 0.35, "dark": 0.0})
	for p in [_pixel, _light]:
		p.mat.set_shader_parameter("tint", Color(g["tint"]))
		p.mat.set_shader_parameter("tint_amount", float(g["amount"]) * 0.5)
	_pixel.mat.set_shader_parameter("saturation", float(g["sat"]))
	_light.mat.set_shader_parameter("vignette", float(g["vignette"]))
	_light.mat.set_shader_parameter("darkness", clampf(float(g["dark"]) + extra_dark, 0.0, 0.75))
	_radius = float(g.get("radius", 500.0)) * (1.0 - extra_dark * 0.6)


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player) or _light == null:
		return
	# Con stretch "canvas_items" la ventana puede ser más grande que la vista de 1600×900.
	var ratio := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	var zoom := player.get_canvas_transform().get_scale().x   # tamaño del mundo (T156)
	_light.mat.set_shader_parameter("light_pos", player.get_global_transform_with_canvas().origin * ratio)
	_light.mat.set_shader_parameter("light_radius", _radius * zoom * ratio.x)
	_pixel.mat.set_shader_parameter("pixel", maxf(2.0, roundf(2.0 * zoom * ratio.x)))
	_send_lights(ratio)


## Junta las luces visibles y las pasa al shader en coordenadas de pantalla.
func _send_lights(ratio: Vector2) -> void:
	var canvas := player.get_canvas_transform()
	var view := (canvas.affine_inverse() * get_viewport().get_visible_rect()).grow(260.0)
	var found: Array[Dictionary] = []
	var limit := light_limit()
	var add := func(pos: Vector2, radius: float, color: Color, power: float) -> void:
		if found.size() < limit and view.has_point(pos):
			found.append({"pos": pos, "radius": radius, "color": color, "power": clampf(power, 0.0, 1.0)})
	var t := Time.get_ticks_msec() / 1000.0
	# Primero las que dan forma al sitio (si hay que recortar, se van los destellos).
	if enemies and enemies.impact:   # golpes recién dados: las luces de la zona cercanas reaccionan (T100)
		for f in enemies.impact.flashes:
			if float(f["life"]) >= float(f["max"]) - 0.02:
				note_hit(f["pos"], t)
	_hits = _hits.filter(func(h: Dictionary) -> bool: return t - float(h["t"]) < HIT_KICK_TIME)
	if _zone:
		for l in _zone.light_points():
			var flick := 0.85 + 0.15 * sin(t * 9.0 + l["pos"].x) * sin(t * 5.3 + l["pos"].y)
			var kick := hit_kick(l["pos"], t)
			add.call(l["pos"], float(l["radius"]) * flick * (1.0 + 0.25 * kick), l["color"], float(l.get("power", 0.9)) * flick * (1.0 + 0.6 * kick))
	if loot:   # el botín único y de conjunto brilla en el suelo
		for d in loot.drops:
			var item: Item = d["item"]
			if item.rarity == Rarity.Item.UNIQUE or item.rarity == Rarity.Item.SET:
				add.call((d["rect"] as Rect2).get_center(), 120.0, item.display_color(), 0.55 + 0.1 * sin(t * 3.0))
	if skills:   # auras e invocaciones con luz propia
		for l in skills.light_allies():
			add.call(l["pos"], l["radius"], l["color"], l["power"])
	if not reduced and bool(GraphicsQuality.preset()["flashes"]):
		if enemies and enemies.impact:
			for f in enemies.impact.flashes:
				add.call(f["pos"], f["radius"], f["color"], f["life"] / f["max"])
				# Onda de choque (T98): los destellos grandes recién salidos.
				if float(f["radius"]) >= SHOCK_MIN_RADIUS and float(f["life"]) >= float(f["max"]) - 0.02:
					add_shock(f["pos"])
		if skills:
			for e in skills.light_effects():
				add.call(e["pos"], e["radius"], e["color"], e["power"])
				if float(e["radius"]) >= SHOCK_MIN_RADIUS and float(e["power"]) > 0.95:
					add_shock(e["pos"])   # explosiones y novas grandes recién salidas
			for pr in skills.light_projectiles():
				add.call(pr["pos"], 110.0, pr["color"], 0.85)
		if enemies:
			for pr in enemies.projectiles:
				add.call(pr["pos"], 80.0 + float(pr["radius"]) * 3.0, pr["color"], 0.7)
	last_lights = found
	var data := PackedVector4Array()
	var colors := PackedColorArray()
	data.resize(MAX_LIGHTS)
	colors.resize(MAX_LIGHTS)
	for k in found.size():
		var sp: Vector2 = canvas * (found[k]["pos"] as Vector2) * ratio
		data[k] = Vector4(sp.x, sp.y, float(found[k]["radius"]) * canvas.get_scale().x * ratio.x, found[k]["power"])
		colors[k] = found[k]["color"]
	_light.mat.set_shader_parameter("lights", data)
	_light.mat.set_shader_parameter("light_colors", colors)
	_light.mat.set_shader_parameter("light_count", found.size())
	_send_effects(found, canvas, ratio)


# --- T100: las luces de la zona reaccionan a los golpes cercanos ---

const HIT_KICK_TIME := 0.35
const HIT_KICK_RANGE := 320.0
var _hits: Array[Dictionary] = []   # {pos, t}


func note_hit(pos: Vector2, now: float) -> void:
	_hits.append({"pos": pos, "t": now})
	if _hits.size() > 24:
		_hits.remove_at(0)


## Cuánto se aviva una luz en `pos` por los golpes recientes cercanos (0..1).
func hit_kick(pos: Vector2, now: float) -> float:
	var k := 0.0
	for h in _hits:
		var near := 1.0 - clampf((h["pos"] as Vector2).distance_to(pos) / HIT_KICK_RANGE, 0.0, 1.0)
		var fresh := 1.0 - clampf((now - float(h["t"])) / HIT_KICK_TIME, 0.0, 1.0)
		k = maxf(k, near * fresh)
	return k


# --- T98: bloom, distorsión de calor y ondas de choque (según la calidad gráfica) ---

const SHOCK_MIN_RADIUS := 140.0
const SHOCK_TIME := 0.45
const SHOCK_MAX_RADIUS := 230.0
const MAX_HEAT := 8
const MAX_SHOCKS := 6
var _shocks: Array[Dictionary] = []   # {pos, t0}


## Luces dinámicas como mucho: las de la calidad gráfica, y menos con «luces reducidas».
static func light_limit() -> int:
	var by_quality := int(GraphicsQuality.preset()["lights"])
	return mini(LOW_LIGHTS, by_quality) if reduced else by_quality


## Radio de una onda de choque con `age` segundos (crece rápido y frena); su fuerza baja.
static func shock_radius(age: float) -> float:
	var t := clampf(age / SHOCK_TIME, 0.0, 1.0)
	return SHOCK_MAX_RADIUS * (1.0 - (1.0 - t) * (1.0 - t))


static func shock_strength(age: float) -> float:
	return clampf(1.0 - age / SHOCK_TIME, 0.0, 1.0)


## ¿Es una luz de fuego (para la distorsión de calor)? Anaranjada o roja.
static func is_fire_color(c: Color) -> bool:
	return c.r > 0.75 and c.g < 0.75 and c.b < 0.5


func add_shock(pos: Vector2) -> void:
	if not bool(GraphicsQuality.preset()["shock"]) or Accessibility.reduce_motion:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for s in _shocks:
		if (s["pos"] as Vector2).distance_to(pos) < 40.0 and now - float(s["t0"]) < 0.1:
			return   # el mismo golpe en varios fotogramas
	_shocks.append({"pos": pos, "t0": now})
	if _shocks.size() > MAX_SHOCKS:
		_shocks.remove_at(0)


func _send_effects(found: Array[Dictionary], canvas: Transform2D, ratio: Vector2) -> void:
	var q := GraphicsQuality.preset()
	var px := canvas.get_scale().x * ratio.x
	_light.mat.set_shader_parameter("bloom", float(q["bloom"]))
	var heat := PackedVector4Array()
	heat.resize(MAX_HEAT)
	var heat_count := 0
	if bool(q["heat"]) and not Accessibility.reduce_motion:
		for l in found:
			if heat_count < MAX_HEAT and is_fire_color(l["color"]):
				var sp: Vector2 = canvas * (l["pos"] as Vector2) * ratio
				heat[heat_count] = Vector4(sp.x, sp.y, float(l["radius"]) * 0.55 * px, 0.6 * float(l["power"]))
				heat_count += 1
	_light.mat.set_shader_parameter("heat", heat)
	_light.mat.set_shader_parameter("heat_count", heat_count)
	var now := Time.get_ticks_msec() / 1000.0
	_shocks = _shocks.filter(func(s: Dictionary) -> bool: return now - float(s["t0"]) < SHOCK_TIME)
	var shocks := PackedVector4Array()
	shocks.resize(MAX_SHOCKS)
	for k in _shocks.size():
		var age := now - float(_shocks[k]["t0"])
		var sp: Vector2 = canvas * (_shocks[k]["pos"] as Vector2) * ratio
		shocks[k] = Vector4(sp.x, sp.y, shock_radius(age) * px, shock_strength(age))
	_light.mat.set_shader_parameter("shocks", shocks)
	_light.mat.set_shader_parameter("shock_count", _shocks.size())


## Una pasada: copia lo ya dibujado (BackBufferCopy) y lo cubre con el shader.
class _Pass extends Node2D:
	var mat: ShaderMaterial
	var _copy: BackBufferCopy

	func _init(pixel_pass: bool) -> void:
		z_index = 0 if pixel_pass else 1
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("posterize", pixel_pass)
		mat.set_shader_parameter("pixel", 2.0 if pixel_pass else 1.0)
		_copy = BackBufferCopy.new()
		_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(_copy)
		var cover := Node2D.new()
		cover.material = mat
		cover.draw.connect(func() -> void:
			var inv := cover.get_canvas_transform().affine_inverse()
			var view := cover.get_viewport_rect()
			cover.draw_rect(Rect2(inv * view.position, view.size / cover.get_canvas_transform().get_scale()).grow(16.0), Color.WHITE))
		add_child(cover)
		cover.set_process(false)
		_cover = cover

	var _cover: Node2D

	func _process(_delta: float) -> void:
		_cover.queue_redraw()
