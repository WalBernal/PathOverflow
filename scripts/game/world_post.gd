class_name WorldPost
extends CanvasLayer
## Filtro de pixel art del mundo (assets/shaders/world_post.gdshader): va entre
## el mundo y la interfaz. Cada estilo de zona tiene su gradación, viñeta y
## oscuridad (con luz alrededor del jugador). Se apaga en Pausa → Interfaz.

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
}

var player: Node2D
var _rect: ColorRect
var _mat: ShaderMaterial
var _radius := 500.0


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "pixel_filter", true))


func _ready() -> void:
	layer = 1
	add_to_group(&"world_post")
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)
	refresh()


func refresh() -> void:
	visible = enabled()


func set_style(style: String) -> void:
	var g: Dictionary = GRADES.get(style, {"tint": "ffffff", "amount": 0.0, "sat": 1.05, "vignette": 0.35, "dark": 0.0})
	_mat.set_shader_parameter("tint", Color(g["tint"]))
	_mat.set_shader_parameter("tint_amount", float(g["amount"]))
	_mat.set_shader_parameter("saturation", float(g["sat"]))
	_mat.set_shader_parameter("vignette", float(g["vignette"]))
	_mat.set_shader_parameter("darkness", float(g["dark"]))
	_radius = float(g.get("radius", 500.0))


func _process(_delta: float) -> void:
	if not visible or player == null or not is_instance_valid(player):
		return
	# Posición del jugador en la pantalla (en píxeles reales, como FRAGCOORD).
	# Con stretch "canvas_items" la ventana puede ser más grande que la vista de 1600×900.
	var ratio := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("light_pos", player.get_global_transform_with_canvas().origin * ratio)
	_mat.set_shader_parameter("light_radius", _radius * ratio.x)
	_mat.set_shader_parameter("pixel", maxf(2.0, roundf(2.0 * ratio.x)))
