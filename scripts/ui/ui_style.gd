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

	theme.set_stylebox("normal", "Button", _button_box(PANEL_LIGHT, BORDER, Color("100d14")))
	theme.set_stylebox("hover", "Button", _button_box(Color("2e2836"), ACCENT.darkened(0.25), Color("100d14"), Color(ACCENT, 0.22)))
	theme.set_stylebox("pressed", "Button", _button_box(Color("3a2f22"), ACCENT, Color("1a140c")))
	theme.set_stylebox("disabled", "Button", _button_box(PANEL, Color("2a2530"), Color("100d14")))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT.darkened(0.2), 1))
	theme.set_stylebox("hover_pressed", "Button", _button_box(Color("3a2f22"), ACCENT.lightened(0.1), Color("1a140c"), Color(ACCENT, 0.25)))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("4a4352"))

	var edit := _box(Color("0d0b10"), BORDER)
	edit.set_corner_radius_all(6)
	theme.set_stylebox("normal", "LineEdit", edit)
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), ACCENT, 1))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color("5a5363"))
	theme.set_color("caret_color", "LineEdit", ACCENT)

	# Deslizadores (volúmenes): pista hundida, relleno dorado y un tirador redondo.
	var track := _box(Color("0d0b10"), BORDER)
	track.set_corner_radius_all(4)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	for state in ["grabber_area", "grabber_area_highlight"]:
		var fill := _box(ACCENT.darkened(0.45 if state == "grabber_area" else 0.3), ACCENT.darkened(0.2))
		fill.set_corner_radius_all(4)
		fill.content_margin_top = 3
		fill.content_margin_bottom = 3
		theme.set_stylebox(state, "HSlider", fill)
	theme.set_icon("grabber", "HSlider", _dot_texture(16, ACCENT))
	theme.set_icon("grabber_highlight", "HSlider", _dot_texture(16, ACCENT.lightened(0.35)))

	var tip := _box(Color("0d0b10f5"), ACCENT.darkened(0.4))
	tip.set_content_margin_all(10)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	return theme


static func panel_style() -> StyleBoxFlat:
	var s := _box(Color(PANEL, 0.95), BORDER)
	s.set_corner_radius_all(8)
	s.border_color = Color("3d3547")
	s.border_width_top = 2
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin_all(16)
	return s


## Botón con relieve: borde inferior más grueso y oscuro (como una tecla) y,
## opcionalmente, un brillo alrededor (hover).
static func _button_box(bg: Color, border: Color, bottom: Color, glow := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := _box(bg, border)
	s.set_corner_radius_all(6)
	s.border_width_bottom = 3
	s.border_color = border
	s.content_margin_bottom = 5
	if glow.a > 0.0:
		s.shadow_color = glow
		s.shadow_size = 6
	s.anti_aliasing = true
	return s


# --- Ventanas de juego (inventario, habilidades...) ---

const GOLD := Color("b08a4a")
const GOLD_DARK := Color("5a4426")
const WINDOW_BG := Color("120f17")


## Fondo de las ventanas: oscuro, con borde dorado doble y sombra.
static func window_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(WINDOW_BG, 0.97)
	s.border_color = GOLD_DARK
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 14
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


## Viste una ventana: estilo, degradado en la cabecera, filete interior y
## esquinas doradas. Se dibuja detrás del contenido.
static func decorate_window(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", window_style())
	panel.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, panel.size)
		# Degradado cálido en la cabecera.
		for k in 12:
			panel.draw_rect(Rect2(4, 4 + k * 5, r.size.x - 8, 5), Color(0.55, 0.38, 0.15, 0.10 * (1.0 - k / 12.0)))
		panel.draw_rect(r.grow(-6.0), Color(GOLD, 0.25), false, 1.0)
		var c := 22.0
		for corner: Vector2 in [Vector2(0, 0), Vector2(r.size.x, 0), Vector2(0, r.size.y), Vector2(r.size.x, r.size.y)]:
			var sx := 1.0 if corner.x == 0.0 else -1.0
			var sy := 1.0 if corner.y == 0.0 else -1.0
			var o := corner + Vector2(sx * 3.0, sy * 3.0)
			panel.draw_line(o, o + Vector2(sx * c, 0), GOLD, 3.0)
			panel.draw_line(o, o + Vector2(0, sy * c), GOLD, 3.0)
			panel.draw_colored_polygon(PackedVector2Array([o + Vector2(sx * 7, sy * 2), o + Vector2(sx * 11, sy * 7),
				o + Vector2(sx * 7, sy * 12), o + Vector2(sx * 3, sy * 7)]), GOLD.lightened(0.2)))


## Cabecera de ventana: título dorado, subtítulo y un botón de cerrar.
static func window_header(title: String, subtitle: String, on_close: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	box.add_child(row)
	var t := label(title, 24, ACCENT.lightened(0.1))
	t.add_theme_constant_override("outline_size", 4)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if on_close.is_valid():
		var close := Button.new()
		close.text = "✕"
		close.tooltip_text = "Cerrar"
		close.focus_mode = Control.FOCUS_NONE
		close.custom_minimum_size = Vector2(32, 32)
		close.pressed.connect(on_close)
		row.add_child(close)
	if subtitle != "":
		box.add_child(label(subtitle, 12, MUTED))
	box.add_child(ornament())
	return box


## Separador ornamental: línea dorada con un rombo en el centro.
static func ornament() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 14)
	c.draw.connect(func() -> void:
		var y := c.size.y / 2.0
		var mid := c.size.x / 2.0
		c.draw_line(Vector2(0, y), Vector2(mid - 12, y), Color(GOLD, 0.6), 1.0)
		c.draw_line(Vector2(mid + 12, y), Vector2(c.size.x, y), Color(GOLD, 0.6), 1.0)
		c.draw_colored_polygon(PackedVector2Array([Vector2(mid, y - 5), Vector2(mid + 7, y), Vector2(mid, y + 5), Vector2(mid - 7, y)]), GOLD))
	return c


## Título de sección con un rombo pequeño delante.
static func section_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(10, 18)
	gem.draw.connect(func() -> void:
		gem.draw_colored_polygon(PackedVector2Array([Vector2(5, 4), Vector2(10, 9), Vector2(5, 14), Vector2(0, 9)]), GOLD))
	row.add_child(gem)
	row.add_child(label(text, 15, ACCENT))
	return row


## Caja interior (para resúmenes, filas...): más clara que la ventana.
static func inset_style(border := Color("2e2836")) -> StyleBoxFlat:
	var s := _box(Color("1a1620"), border)
	s.set_corner_radius_all(4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
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


## Tamaño de interfaz (menú de pausa → Interfaz) para los menús fuera de partida:
## el control raíz se escala y ocupa la pantalla dividida por la escala.
static func apply_ui_scale(root: Control) -> void:
	var s := clampf(float(GameSettings.get_value("interface", "scale", 1.0)), 0.75, 1.45)
	if is_equal_approx(s, 1.0) or not root.is_inside_tree():
		return
	var fit := func() -> void:
		if not is_instance_valid(root) or not root.is_inside_tree():
			return   # el menú ya se cerró
		root.set_anchors_preset(Control.PRESET_TOP_LEFT)
		root.scale = Vector2(s, s)
		root.size = root.get_viewport().get_visible_rect().size / s
	root.get_viewport().size_changed.connect(fit)
	fit.call()


static func label(text: String, font_size := 16, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


## Círculo relleno con borde oscuro (tirador de los deslizadores).
static func _dot_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var c := (diameter - 1) / 2.0
	for y in diameter:
		for x in diameter:
			var d := Vector2(x - c, y - c).length()
			if d <= c - 1.5:
				img.set_pixel(x, y, color if d < c - 4.0 else color.darkened(0.25))
			elif d <= c + 0.5:
				img.set_pixel(x, y, Color("100d14"))
	return ImageTexture.create_from_image(img)


## Fila de ajuste: nombre, deslizador de 0 a 100 % y el valor. `on_change`
## recibe el valor entre 0 y 1.
static func slider_row(text: String, value: float, on_change: Callable, width := 360.0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(width, 32)
	var name_label := label(text, 15)
	name_label.custom_minimum_size.x = 110
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = roundf(value * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value_label := label("%d %%" % int(slider.value), 14, MUTED)
	value_label.custom_minimum_size.x = 48
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d %%" % int(v) if v > 0.0 else "no"
		on_change.call(v / 100.0))
	if slider.value <= 0.0:
		value_label.text = "no"
	return row


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
	# Resplandor cálido en el centro y viñeta en los bordes.
	var center := size / 2.0
	for k in 10:
		var r := maxf(size.x, size.y) * (0.55 - k * 0.045)
		ci.draw_circle(center + Vector2(0, size.y * 0.1), r, Color(0.55, 0.38, 0.15, 0.012))
	var vignette := 220.0
	for k in 6:
		var a := 0.08 * (6 - k) / 6.0
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, vignette * (1.0 - k / 6.0))), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(Vector2(0, size.y - vignette * (1.0 - k / 6.0)), Vector2(size.x, vignette * (1.0 - k / 6.0))), Color(0, 0, 0, a))


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
