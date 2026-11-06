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
var _dir := 0
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
	# De frente, de espaldas o de lado (T181); de lado a la izquierda, volteado.
	var d: Array = StudentHero.dir_for(facing)
	_dir = int(d[0])
	_flip = bool(d[1])
	var weapon := String(pose.get("weapon", ""))
	if weapon != _weapon or _texture == null:
		_weapon = weapon
		_texture = StudentHero.texture(appearance, weapon)
	_col = StudentHero.column_for(String(pose.get("state", "idle")), float(pose.get("t", 0.0)), float(pose.get("time", 0.0)), walk_phase)
	var lf := PlayerSprite.life(pose, walk_phase)
	scale = lf[0]
	_lift = float(lf[1])
	queue_redraw()


## Dónde brillan las manos (píxeles de la hoja desde los pies, sin HERO_SCALE) en las
## poses con brillo (CharacterAppearance.GLOW_POSES; las hojas no lo traen): la mano del
## arma (la del lado izquierdo de la lámina), al invocar abajo y delante, y con el aura
## las dos (T198). De lado, las manos del perfil (StudentProfile), delante.
static func glow_points(state: String, facing: Vector2) -> Array[Vector2]:
	var d: Array = StudentHero.dir_for(facing)
	if int(d[0]) == StudentHero.Dir.SIDE:
		var ahead := -1.0 if bool(d[1]) else 1.0
		match state:
			"summon":
				return [Vector2(ahead * 10.0, -2.0)]
			"aura":
				return [Vector2(ahead * 8.0, -19.0), Vector2(ahead * 3.0, -21.0)]
		return [Vector2(ahead * 8.0, -18.0)]
	var side := -1.0 if facing.x < -0.3 else 1.0
	match state:
		"summon":
			return [Vector2(side * -9.0, -3.0)]
		"aura":
			return [Vector2(-11.0, -11.0), Vector2(11.0, -11.0)]
	return [Vector2(side * -10.0, -9.0)]


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
	draw_texture_rect_region(_texture, Rect2(-feet * s, cell * s), Rect2(_col * cell.x, _dir * cell.y, cell.x, cell.y))
	draw_set_transform(Vector2.ZERO)
