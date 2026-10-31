class_name StudentPreview
extends Control
## El alumno en pixel art (T180, StudentHero) en los menús: el creador («así te verás
## en el servidor») y la lista de personajes. Respira y, de vez en cuando, da unos pasos
## en el sitio; ampliado sin suavizar y centrado.

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = value
		_texture = null
		queue_redraw()
## Lo que lleva puesto (ranura → id de base), para la lista de personajes.
var equipped: Dictionary = {}:
	set(value):
		equipped = value
		_texture = null
		queue_redraw()
var weapon := ""

var _texture: Texture2D
var _time := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(150, 150)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


## Cuadro de ahora: respira 4 s y camina 2 s en el sitio.
func current_column() -> int:
	var t := fmod(_time, 6.0)
	if t < 4.0:
		return StudentHero.column_for("idle", 0.0, t)
	return StudentHero.column_for("walk", 0.0, 0.0, fmod(t * 6.0, TAU))


func _draw() -> void:
	if not StudentHero.available():
		return
	if _texture == null:
		_texture = StudentHero.texture(StudentHero.look_of(CharacterAppearance.sanitize(appearance), equipped), weapon)
	var cell := Vector2(StudentHero.CELL)
	# El alumno mide ~41 píxeles de la hoja: que llene el alto disponible.
	var s := floorf(maxf(1.0, size.y / 48.0))
	var feet := Vector2(StudentHero.FEET)
	var origin := Vector2(size.x / 2.0, size.y - 4.0) - feet * s
	draw_texture_rect_region(_texture, Rect2(origin, cell * s), Rect2(current_column() * cell.x, 0, cell.x, cell.y))
