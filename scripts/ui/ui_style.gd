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
	theme.set_stylebox("panel", "PanelContainer", _piece("panel", 16, 16, panel_style()))

	# Botones (T95): piezas del atlas de interfaz; sin atlas, las cajas planas de antes.
	theme.set_stylebox("normal", "Button", _piece("button_normal", 12, 6, _button_box(PANEL_LIGHT, BORDER, Color("100d14"))))
	theme.set_stylebox("hover", "Button", _piece("button_hover", 12, 6, _button_box(Color("2e2836"), ACCENT.darkened(0.25), Color("100d14"), Color(ACCENT, 0.22))))
	theme.set_stylebox("pressed", "Button", _pressed(_piece("button_pressed", 12, 6, _button_box(Color("3a2f22"), ACCENT, Color("1a140c"), Color(0, 0, 0, 0), true))))
	theme.set_stylebox("disabled", "Button", _piece("button_disabled", 12, 6, _button_box(PANEL, Color("2a2530"), Color("100d14"))))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT.darkened(0.2), 1))
	theme.set_stylebox("hover_pressed", "Button", _pressed(_piece("button_pressed", 12, 6, _button_box(Color("3a2f22"), ACCENT.lightened(0.1), Color("1a140c"), Color(ACCENT, 0.25), true))))
	for state in ["tab_selected", "tab_hovered"]:
		theme.set_stylebox(state, "TabBar", _piece("tab_active", 14, 6, _box(PANEL_LIGHT, ACCENT)))
		theme.set_stylebox(state, "TabContainer", _piece("tab_active", 14, 6, _box(PANEL_LIGHT, ACCENT)))
	theme.set_stylebox("tab_unselected", "TabBar", _piece("tab_inactive", 14, 6, _box(PANEL, BORDER)))
	theme.set_stylebox("tab_unselected", "TabContainer", _piece("tab_inactive", 14, 6, _box(PANEL, BORDER)))
	theme.set_stylebox("panel", "TabContainer", _piece("panel", 12, 10, panel_style()))
	theme.set_stylebox("background", "ProgressBar", _piece("bar_frame", 3, 3, _box(Color("0a080c"), GOLD_DARK)))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("4a4352"))

	var edit := _box(Color("0d0b10"), BORDER)
	edit.set_corner_radius_all(6)
	theme.set_stylebox("normal", "LineEdit", _piece("line_edit", 10, 6, edit))
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
	theme.set_stylebox("panel", "TooltipPanel", _piece("tooltip", 10, 10, tip))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	return theme


## Pieza del atlas de interfaz (T95) con sus márgenes de contenido; si no hay atlas,
## `fallback` (la caja plana de siempre).
static func _piece(piece: String, content_h: float, content_v: float, fallback: StyleBox) -> StyleBox:
	var s := UiAtlas.box(piece, content_h, content_v)
	return s if s != null else fallback


## Botón pulsado: el texto 2 px más abajo (la tecla hundida).
static func _pressed(s: StyleBox) -> StyleBox:
	if s is StyleBoxTexture:
		s.content_margin_top += 2.0
		s.content_margin_bottom -= 2.0
	return s


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
## opcionalmente, un brillo alrededor (hover). `pressed` (T76): la tecla hundida,
## con el borde grueso arriba y el texto 2 px más abajo.
static func _button_box(bg: Color, border: Color, bottom: Color, glow := Color(0, 0, 0, 0), pressed := false) -> StyleBoxFlat:
	var s := _box(bg, border)
	s.set_corner_radius_all(6)
	s.border_width_bottom = 3
	s.border_color = border
	s.content_margin_bottom = 5
	if pressed:
		s.border_width_bottom = 1
		s.border_width_top = 3
		s.content_margin_top += 2
		s.content_margin_bottom = 3
	if glow.a > 0.0:
		s.shadow_color = glow
		s.shadow_size = 6
	s.anti_aliasing = true
	return s


# --- Ventanas de juego (inventario, habilidades...) ---

const GOLD := Color("b08a4a")
const GOLD_DARK := Color("5a4426")
const WINDOW_BG := Color("120f17")


## Fondo de las ventanas: el marco de ventana del atlas (T95) o, sin atlas, oscuro
## con borde dorado doble y sombra.
static func window_style() -> StyleBox:
	var piece := UiAtlas.box("window", 20, 16)
	if piece != null:
		return piece
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
	# Sonido al abrir y al cerrar (T77). Se mira al final del fotograma: pasar de una
	# ventana a otra (ocultar y volver a mostrar a la vez) no suena dos veces.
	panel.visibility_changed.connect(func() -> void:
		var check := func() -> void:
			if not is_instance_valid(panel) or not panel.is_inside_tree():
				return
			var was: bool = panel.get_meta("ui_shown", false)
			if panel.visible != was:
				panel.set_meta("ui_shown", panel.visible)
				Sfx.play("ui_open" if panel.visible else "ui_close", -10.0)
		check.call_deferred())
	panel.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, panel.size)
		# Degradado cálido en la cabecera.
		for k in 12:
			panel.draw_rect(Rect2(4, 4 + k * 5, r.size.x - 8, 5), Color(0.55, 0.38, 0.15, 0.10 * (1.0 - k / 12.0)))
		if UiAtlas.texture() == null:
			panel.draw_rect(r.grow(-6.0), Color(GOLD, 0.25), false, 1.0)   # el marco del atlas ya trae su filete
		# Remaches a lo largo de los bordes (T76): cabeza oscura con un brillo arriba a la izquierda.
		for edge in [[Vector2(0, 7), Vector2(r.size.x, 7)], [Vector2(0, r.size.y - 7), Vector2(r.size.x, r.size.y - 7)],
				[Vector2(7, 0), Vector2(7, r.size.y)], [Vector2(r.size.x - 7, 0), Vector2(r.size.x - 7, r.size.y)]]:
			var a: Vector2 = edge[0]
			var b: Vector2 = edge[1]
			var n := maxi(0, int(a.distance_to(b) / RIVET_SPACING) - 1)
			for k in range(1, n + 1):
				draw_rivet(panel, a.lerp(b, float(k) / (n + 1)))
		if UiAtlas.texture() != null:
			return   # el marco del atlas ya trae sus esquinas redondeadas
		var c := 22.0
		for corner: Vector2 in [Vector2(0, 0), Vector2(r.size.x, 0), Vector2(0, r.size.y), Vector2(r.size.x, r.size.y)]:
			var sx := 1.0 if corner.x == 0.0 else -1.0
			var sy := 1.0 if corner.y == 0.0 else -1.0
			var o := corner + Vector2(sx * 3.0, sy * 3.0)
			# Cantonera de metal debajo del ángulo dorado.
			panel.draw_rect(Rect2(o + Vector2(minf(0.0, sx * 16.0), minf(0.0, sy * 16.0)), Vector2(16, 16)), GOLD_DARK)
			panel.draw_rect(Rect2(o + Vector2(minf(0.0, sx * 16.0), minf(0.0, sy * 16.0)), Vector2(16, 16)), Color(0, 0, 0, 0.5), false, 1.0)
			panel.draw_line(o, o + Vector2(sx * c, 0), GOLD, 3.0)
			panel.draw_line(o, o + Vector2(0, sy * c), GOLD, 3.0)
			panel.draw_colored_polygon(PackedVector2Array([o + Vector2(sx * 7, sy * 2), o + Vector2(sx * 11, sy * 7),
				o + Vector2(sx * 7, sy * 12), o + Vector2(sx * 3, sy * 7)]), GOLD.lightened(0.2))
			draw_rivet(panel, o + Vector2(sx * 12, sy * 12)))


## Burbujas del líquido de un orbe en el instante `t`: [posición, radio], solo las que
## están por debajo de la superficie. Suben a su ritmo y se mecen a los lados (T76).
const ORB_BUBBLES := 7


static func orb_bubbles(t: float, center_x: float, bottom_y: float, surface_y: float, radius: float) -> Array:
	var out: Array = []
	for k in ORB_BUBBLES:
		var phase := fposmod(t * (0.18 + 0.05 * (k % 3)) + k * 0.37, 1.0)
		var y := lerpf(bottom_y - 6.0, surface_y, phase)
		if y <= surface_y + 3.0 or y >= bottom_y - 4.0:
			continue
		var spread := sqrt(maxf(0.0, radius * radius - pow(y - (bottom_y - radius), 2.0))) * 0.7
		var x := center_x + sin(k * 7.31) * spread + sin(t * 2.0 + k) * 2.0
		out.append([Vector2(x, y), 1.5 + (k % 3) * 0.8])
	return out


## Separación entre remaches del marco de las ventanas.
const RIVET_SPACING := 90.0


## Un remache: cabeza redonda, sombra abajo a la derecha y brillo arriba a la izquierda.
static func draw_rivet(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_circle(p + Vector2(1, 1), 3.0, Color(0, 0, 0, 0.6))
	ci.draw_circle(p, 3.0, GOLD.darkened(0.15))
	ci.draw_circle(p - Vector2(1, 1), 1.2, GOLD.lightened(0.45))


## Cabecera de ventana: título dorado, subtítulo y un botón de cerrar.
static func window_header(title: String, subtitle: String, on_close: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	box.add_child(row)
	var t := title_label(title, 26, ACCENT.lightened(0.1))
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
	# La fuente de píxeles es ancha: los encabezados largos van con la normal para no ensanchar la ventana.
	row.add_child(title_label(text, 17, ACCENT))
	return row


## Título con la fuente normal, contorno oscuro y sombra (cabeceras de ventana y de
## sección); sustituye a la fuente de píxeles para un acabado más pulido.
static func title_label(text: String, font_size := 22, color := ACCENT) -> Label:
	var l := label(text, font_size, color)
	l.add_theme_constant_override("outline_size", maxi(3, font_size / 6))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	return l


## Encabezados de sección con más letras que esto, con la fuente normal (T82).
const PIXEL_HEADER_MAX := 24


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
	var chosen := clampf(float(GameSettings.get_value("interface", "scale", 1.0)), 0.75, 1.6)   # igual que GameUI.UI_SCALE_MAX
	if is_equal_approx(chosen, 1.0) or not root.is_inside_tree():
		return
	var fit := func() -> void:
		if not is_instance_valid(root) or not root.is_inside_tree():
			return   # el menú ya se cerró
		# Igual que GameUI.apply_ui_scale: en pantallas bajas se reduce hasta caber (560 px de alto).
		var s := minf(chosen, maxf(1.0, root.get_viewport().get_visible_rect().size.y / 560.0))
		root.set_anchors_preset(Control.PRESET_TOP_LEFT)
		root.scale = Vector2(s, s)
		root.size = root.get_viewport().get_visible_rect().size / s
	root.get_viewport().size_changed.connect(fit)
	fit.call()


## Última pestaña o filtro de cada ventana (T82), en settings.cfg → [ui_memory].
## Se escribe solo cuando el jugador la cambia.
static func remembered(key: String, default: Variant) -> Variant:
	return GameSettings.get_value("ui_memory", key, default)


static func remember(key: String, value: Variant) -> void:
	if remembered(key, null) != value:
		GameSettings.set_value("ui_memory", key, value)


## ¿Se está escribiendo en un campo de texto (búsqueda del alijo, nombres)? Mientras
## tanto, las teclas de habilidades, esquiva y movimiento no actúan (T80).
static func typing() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var focus := tree.root.gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


## Por debajo de esto no se lee con la interfaz al 80 % (T76).
const MIN_FONT_SIZE := 12


static func label(text: String, font_size := 16, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(font_size, MIN_FONT_SIZE))
	l.add_theme_color_override("font_color", color)
	return l


## Rótulo con la fuente de píxeles (T76), en mayúsculas y con sombra dura.
## `scale`: 2 o 3 (múltiplos de la celda de 10 px, para píxeles enteros).
static func pixel_label(text: String, scale := 2, color := TEXT) -> Label:
	var l := label(text.to_upper(), PixelFont.CELL_H * scale, color)
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", scale)
	l.add_theme_constant_override("shadow_offset_y", scale)
	l.add_theme_constant_override("shadow_outline_size", 0)
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
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			Sfx.play("ui_hover", -18.0))   # T77
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
