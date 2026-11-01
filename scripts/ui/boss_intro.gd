class_name BossIntro
extends CanvasLayer
## Entrada de jefe (T103): la primera vez que ves a un jefe, una franja cruza la
## pantalla con su figura grande en pose de amenaza (el cuadro de ataque de su hoja)
## y su nombre. Entra, se queda un momento y se va; el juego no se para.

const ENTER := 0.35
const HOLD := 1.6
const LEAVE := 0.4
const ATLAS := preload("res://assets/sprites/enemies/enemies.png")
## Las capturas la apagan (taparía lo que quieren fotografiar).
static var enabled := true

var boss_name := ""
var region := Rect2()   # celda del jefe en la hoja (mirando abajo); se usa su fila de lado
var color := Color("ff8a3a")
var _t := 0.0
var _rect: Control


## Cuánto ha entrado la franja (0..1) en el instante `t`: entra, se queda y se va.
static func slide_at(t: float) -> float:
	if t < ENTER:
		return ease(t / ENTER, 0.4)
	if t < ENTER + HOLD:
		return 1.0
	return clampf(1.0 - (t - ENTER - HOLD) / LEAVE, 0.0, 1.0)


static func total_time() -> float:
	return ENTER + HOLD + LEAVE


func _ready() -> void:
	layer = 90
	_rect = Control.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.draw.connect(_draw_band)
	add_child(_rect)


func _process(delta: float) -> void:
	_t += delta
	if _t >= total_time():
		queue_free()
		return
	_rect.queue_redraw()


func _draw_band() -> void:
	var view := _rect.size
	var k := slide_at(_t)
	var band := Rect2(Vector2((1.0 - k) * -view.x * 0.6, view.y * 0.24), Vector2(view.x, 150.0))
	_rect.draw_rect(band, Color(0, 0, 0, 0.72 * k))
	_rect.draw_rect(Rect2(band.position, Vector2(band.size.x, 3.0)), Color(color, 0.9 * k))
	_rect.draw_rect(Rect2(band.position + Vector2(0, band.size.y - 3.0), Vector2(band.size.x, 3.0)), Color(color, 0.9 * k))
	# La figura del jefe, grande, en su cuadro de embestida (pose de amenaza), de lado.
	var row := EnemySheet.type_of(region)
	var cell := EnemySheet.region(row, EnemySheet.Dir.SIDE, EnemySheet.ATTACK + 1 if fmod(_t, 0.5) < 0.25 else EnemySheet.ATTACK)
	var fig := Rect2(band.position + Vector2(view.x * 0.18, -70.0), Vector2(220, 220))
	_rect.draw_texture_rect_region(ATLAS, fig, cell, Color(1, 1, 1, k))
	var font := _rect.get_theme_default_font()
	var text_x := fig.end.x + 30.0
	_rect.draw_string(font, Vector2(text_x, band.position.y + 52.0), "JEFE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(color, k))
	_rect.draw_string_outline(font, Vector2(text_x, band.position.y + 102.0), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, 8, Color(0, 0, 0, k))
	_rect.draw_string(font, Vector2(text_x, band.position.y + 102.0), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(UiStyle.TEXT, k))
