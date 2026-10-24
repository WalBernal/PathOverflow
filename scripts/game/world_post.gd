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
}

var player: Node2D
var _pixel: _Pass
var _light: _Pass
var _radius := 500.0


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
