class_name HeroSprite
extends Node2D
## El personaje dentro del servidor (T176, StudentHero) en el mundo: el alumno con su
## apariencia y lo que lleva puesto, ampliado sin suavizar y volteado según hacia dónde
## mira. Misma API que PlayerSprite (appearance, tint, set_pose) para que el jugador
## lo use igual. Sus pies van en (0, 0). `appearance` es el look de
## StudentHero.look_of (apariencia + equipo); el arma sale de la pose. Con
## PlayerSprite.life respira, rebota al andar y se estira al golpear.

## Píxeles del mundo por píxel de la hoja: el alumno mide ~41 (~55 en el mundo, lo
## que medía el oficinista con T157).
const HERO_SCALE := 1.35
const SHADER := preload("res://assets/shaders/hero_tint.gdshader")

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		if value == appearance and _texture != null:
			return
		appearance = value
		_texture = null
		queue_redraw()
var tint := Color(0, 0, 0, 0):
	set(value):
		tint = value
		if material:
			(material as ShaderMaterial).set_shader_parameter("tint", value)
## (Lo pone quien lo usa, como en PlayerSprite; aquí manda HERO_SCALE.)
var sprite_scale := 1.0

var _texture: Texture2D
var _weapon := ""
var _col := 0
var _flip := false
var _lift := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := ShaderMaterial.new()
	m.shader = SHADER
	material = m
	tint = tint


static func available() -> bool:
	return StudentHero.available()


func set_pose(facing: Vector2, pose: Dictionary, walk_phase := -1.0) -> void:
	if absf(facing.x) > 0.1:
		_flip = facing.x < 0.0
	var weapon := String(pose.get("weapon", ""))
	if weapon != _weapon or _texture == null:
		_weapon = weapon
		_texture = StudentHero.texture(appearance, weapon)
	_col = StudentHero.column_for(String(pose.get("state", "idle")), float(pose.get("t", 0.0)), float(pose.get("time", 0.0)), walk_phase)
	var lf := PlayerSprite.life(pose, walk_phase)
	scale = lf[0]
	_lift = float(lf[1])
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	var s := HERO_SCALE
	var cell := Vector2(StudentHero.CELL)
	var feet := Vector2(StudentHero.FEET)
	if _flip:
		draw_set_transform(Vector2(0, _lift * s), 0.0, Vector2(-1, 1))
	else:
		draw_set_transform(Vector2(0, _lift * s))
	draw_texture_rect_region(_texture, Rect2(-feet * s, cell * s), Rect2(_col * cell.x, 0, cell.x, cell.y))
	draw_set_transform(Vector2.ZERO)
