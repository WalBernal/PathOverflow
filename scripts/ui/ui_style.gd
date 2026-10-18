class_name UiStyle
## Estilo visual común de los menús: un Theme generado en código (fondo oscuro,
## bordes sobrios, acento dorado). Cuando haya arte de UI, se sustituye por un
## recurso .tres editable en el editor sin tocar las pantallas.

const BG := Color("0d0b10")
const PANEL := Color("16131b")
const PANEL_LIGHT := Color("221e29")
const BORDER := Color("3a3442")
const ACCENT := Color("d9a441")
const TEXT := Color("e8d9b0")
const MUTED := Color("8a8293")
const DANGER := Color("e06c6c")


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style())

	theme.set_stylebox("normal", "Button", _box(PANEL_LIGHT, BORDER))
	theme.set_stylebox("hover", "Button", _box(Color("2c2735"), ACCENT.darkened(0.3)))
	theme.set_stylebox("pressed", "Button", _box(Color("332b22"), ACCENT))
	theme.set_stylebox("disabled", "Button", _box(PANEL, Color("2a2530")))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT.darkened(0.2), 1))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("4a4352"))

	theme.set_stylebox("normal", "LineEdit", _box(Color("0d0b10"), BORDER))
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), ACCENT, 1))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color("5a5363"))
	theme.set_color("caret_color", "LineEdit", ACCENT)

	var tip := _box(Color("0d0b10f5"), ACCENT.darkened(0.4))
	tip.set_content_margin_all(10)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	return theme


static func panel_style() -> StyleBoxFlat:
	var s := _box(Color(PANEL, 0.94), BORDER)
	s.set_content_margin_all(16)
	return s


static func _box(bg: Color, border: Color, border_width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(3)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func label(text: String, font_size := 16, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, callback: Callable, min_width := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 40)
	b.pressed.connect(callback)
	return b


## Fondo de los menús: color liso + rejilla isométrica tenue + viñeta.
static func draw_background(ci: CanvasItem, size: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), BG)
	var line := Color("1a1720")
	var step := 64.0
	var c := -size.x
	while c < size.y + size.x:
		ci.draw_line(Vector2(0, c), Vector2(size.x, c + size.x * 0.5), line, 1.0)
		ci.draw_line(Vector2(0, c), Vector2(size.x, c - size.x * 0.5), line, 1.0)
		c += step
	var vignette := 220.0
	for k in 6:
		var a := 0.08 * (6 - k) / 6.0
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, vignette * (1.0 - k / 6.0))), Color(0, 0, 0, a))


## "hace 5 min", "hace 3 h"... para la lista de personajes.
static func relative_time(unix: int) -> String:
	if unix <= 0:
		return "nunca"
	var s := int(Time.get_unix_time_from_system()) - unix
	if s < 60:
		return "hace un momento"
	if s < 3600:
		return "hace %d min" % (s / 60)
	if s < 86400:
		return "hace %d h" % (s / 3600)
	return "hace %d días" % (s / 86400)


static func play_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [minutes / 60, minutes % 60]
