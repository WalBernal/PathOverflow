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

var player: Node2D
var skills: SkillController
var enemies: EnemyManager
var _zone: Zone
var _pixel: _Pass
var _light: _Pass
var _radius := 500.0
## Última lista enviada al shader (para pruebas y depuración): [{pos, radius, color, power}].
var last_lights: Array[Dictionary] = []


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "pixel_filter", true))


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
		_pixel.visible = enabled()


func set_style(style: String) -> void:
	var g: Dictionary = GRADES.get(style, {"tint": "ffffff", "amount": 0.0, "sat": 1.05, "vignette": 0.35, "dark": 0.0})
	for p in [_pixel, _light]:
		p.mat.set_shader_parameter("tint", Color(g["tint"]))
		p.mat.set_shader_parameter("tint_amount", float(g["amount"]) * 0.5)
	_pixel.mat.set_shader_parameter("saturation", float(g["sat"]))
	_light.mat.set_shader_parameter("vignette", float(g["vignette"]))
	_light.mat.set_shader_parameter("darkness", float(g["dark"]))
	_radius = float(g.get("radius", 500.0))


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player) or _light == null:
		return
	# Con stretch "canvas_items" la ventana puede ser más grande que la vista de 1600×900.
	var ratio := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	_light.mat.set_shader_parameter("light_pos", player.get_global_transform_with_canvas().origin * ratio)
	_light.mat.set_shader_parameter("light_radius", _radius * ratio.x)
	_pixel.mat.set_shader_parameter("pixel", maxf(2.0, roundf(2.0 * ratio.x)))
	_send_lights(ratio)


## Junta las luces visibles y las pasa al shader en coordenadas de pantalla.
func _send_lights(ratio: Vector2) -> void:
	var canvas := player.get_canvas_transform()
	var view := (canvas.affine_inverse() * get_viewport().get_visible_rect()).grow(260.0)
	var found: Array[Dictionary] = []
	var add := func(pos: Vector2, radius: float, color: Color, power: float) -> void:
		if found.size() < MAX_LIGHTS and view.has_point(pos):
			found.append({"pos": pos, "radius": radius, "color": color, "power": clampf(power, 0.0, 1.0)})
	var t := Time.get_ticks_msec() / 1000.0
	if enemies and enemies.impact:
		for f in enemies.impact.flashes:
			add.call(f["pos"], f["radius"], f["color"], f["life"] / f["max"])
	if skills:
		for e in skills.light_effects():
			add.call(e["pos"], e["radius"], e["color"], e["power"])
		for pr in skills.light_projectiles():
			add.call(pr["pos"], 110.0, pr["color"], 0.85)
	if enemies:
		for pr in enemies.projectiles:
			add.call(pr["pos"], 80.0 + float(pr["radius"]) * 3.0, pr["color"], 0.7)
	if _zone:
		for l in _zone.light_points():
			var flick := 0.85 + 0.15 * sin(t * 9.0 + l["pos"].x) * sin(t * 5.3 + l["pos"].y)
			add.call(l["pos"], float(l["radius"]) * flick, l["color"], float(l.get("power", 0.9)) * flick)
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
