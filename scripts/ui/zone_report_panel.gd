class_name ZoneReportPanel
extends Control
## Informe al salir de una zona (T214): una consola arriba al centro con las líneas de
## ZoneReport, que entra cuando se retira la tarjeta de carga, se queda SHOW_TIME s y se
## desvanece. Un clic o un toque la cierra antes.

const WIDTH := 430.0
const PAD := 10.0
const LINE := 18.0
const DELAY := 1.3       # lo que tarda en irse la tarjeta de carga
const SHOW_TIME := 8.0
const FADE := 0.4

var _lines: Array = []
var _t := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


## Enseña un informe nuevo (sustituye al anterior si aún se veía).
func show_report(report_lines: Array) -> void:
	_lines = wrap_lines(report_lines, UiStyle.mono_font(), WIDTH - PAD * 2.0)
	_t = -DELAY
	custom_minimum_size = Vector2(WIDTH, height_for(_lines.size()))
	size = custom_minimum_size
	visible = false
	modulate.a = 0.0
	queue_redraw()


## Parte cada línea por palabras para que quepa en `width` (las de continuación,
## con dos espacios de sangría y el mismo color).
static func wrap_lines(report_lines: Array, font: Font, width: float) -> Array:
	var out: Array = []
	for l in report_lines:
		var current := ""
		for word in String(l[0]).split(" "):
			var next := word if current.is_empty() else current + " " + word
			if not current.is_empty() and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > width:
				out.append([current, l[1]])
				current = "  " + word
			else:
				current = next
		out.append([current, l[1]])
	return out


static func height_for(n: int) -> float:
	return PAD * 2.0 + 18.0 + LINE * n


## Opacidad a los `t` s de aparecer (sube rápido, se queda y se apaga en FADE).
static func alpha_at(t: float) -> float:
	if t < 0.0:
		return 0.0
	if t < 0.2:
		return t / 0.2
	return clampf((SHOW_TIME - t) / FADE, 0.0, 1.0)


func _process(delta: float) -> void:
	if _lines.is_empty() or _t >= SHOW_TIME:
		return
	_t += delta
	modulate.a = alpha_at(_t)
	visible = _t >= 0.0 and _t < SHOW_TIME
	if _t >= SHOW_TIME:
		_lines = []


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		dismiss()
		accept_event()


func dismiss() -> void:
	if _t >= 0.0 and _t < SHOW_TIME - FADE:
		_t = SHOW_TIME - FADE   # se desvanece ya


func _draw() -> void:
	if _lines.is_empty():
		return
	var box := UiStyle.inset_style(UiStyle.ACCENT.darkened(0.45))
	box.bg_color = Color(UiStyle.PANEL, 0.97)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var font := UiStyle.mono_font()
	var y := PAD + 13.0
	draw_string(font, Vector2(PAD, y), "$ cat informe.log", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.MUTED)
	draw_string(font, Vector2(PAD, y), "toca para cerrar", HORIZONTAL_ALIGNMENT_RIGHT, WIDTH - PAD * 2.0, 11, UiStyle.MUTED)
	y += 4.0
	for l in _lines:
		y += LINE
		draw_string(font, Vector2(PAD, y), String(l[0]), HORIZONTAL_ALIGNMENT_LEFT, WIDTH - PAD * 2.0, 13, color_for(String(l[1])))


static func color_for(kind: String) -> Color:
	if kind.begins_with("loot:"):
		return Rarity.item_color(int(kind.substr(5)))
	match kind:
		"ok": return UiStyle.OK
		"fail": return UiStyle.DANGER
	return UiStyle.TEXT
