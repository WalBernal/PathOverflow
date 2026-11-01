class_name UiStyle
## Estilo visual común de los menús: un Theme generado en código. T166: la propuesta B
## de docs/estilo_visual.md, «panel de monitoreo/datos» (tarjetas planas redondeadas,
## acento turquesa, rejilla de puntos y motivos de grafo y red neuronal), en lugar del
## latón y los remaches de antes. Las ventanas toman sus colores de aquí.

const BG := Color("0e1116")
const PANEL := Color("161b22")
const PANEL_LIGHT := Color("1d2430")
const BORDER := Color("2d3646")
const ACCENT := Color("2dd4bf")
const TEXT := Color("e6edf3")
const MUTED := Color("8b949e")
const DANGER := Color("f85149")
const OK := Color("3fb950")
const AI := Color("a371f7")
const WARN := Color("f59e0b")
## Los mismos, en hexadecimal para el BBCode de los textos ricos.
const TEXT_HEX := "e6edf3"
const MUTED_HEX := "8b949e"
const ACCENT_HEX := "2dd4bf"
const BORDER_HEX := "2d3646"
## Esquinas de tarjetas, botones y ventanas.
const RADIUS := 10
## Arco de los medidores circulares del HUD (T167): 270° abiertos por abajo, de 135° a 405°.
const GAUGE_START := 135.0
const GAUGE_SPAN := 270.0


static var _mono: Font


## Monoespaciada para consolas, registros y números (T168: la del sistema; T169 elige
## una de licencia libre para el proyecto).
static func mono_font() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "DejaVu Sans Mono", "Droid Sans Mono", "monospace"])
		f.fallbacks = [ThemeDB.fallback_font]
		_mono = f
	return _mono


## Ángulos (en radianes) del arco lleno de un medidor con `fill` (0..1): empieza abajo a
## la izquierda y sube por arriba en el sentido del reloj. La fracción del arco es `fill`
## (la misma que llenaban los orbes).
static func gauge_arc(fill: float) -> Vector2:
	var a := deg_to_rad(GAUGE_START)
	return Vector2(a, a + deg_to_rad(GAUGE_SPAN) * clampf(fill, 0.0, 1.0))


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style())

	# Botones (T166): tarjetas planas redondeadas con un borde inferior un poco más
	# grueso (la tecla); al pulsar, se hunden y se tiñen del acento.
	theme.set_stylebox("normal", "Button", _button_box(PANEL_LIGHT, BORDER, BG))
	theme.set_stylebox("hover", "Button", _button_box(Color("243041"), Color(ACCENT, 0.6), BG, Color(ACCENT, 0.18)))
	theme.set_stylebox("pressed", "Button", _button_box(Color(ACCENT, 0.16), ACCENT, BG, Color(0, 0, 0, 0), true))
	theme.set_stylebox("disabled", "Button", _button_box(PANEL, Color("232a36"), BG))
	var focus := _box(Color(0, 0, 0, 0), Color(ACCENT, 0.7), 1)
	focus.set_corner_radius_all(8)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_stylebox("hover_pressed", "Button", _button_box(Color(ACCENT, 0.22), ACCENT.lightened(0.1), BG, Color(ACCENT, 0.22), true))
	# Pestañas: la elegida, con una raya del acento abajo (como un panel de datos).
	for state in ["tab_selected", "tab_hovered"]:
		var tab := _box(PANEL_LIGHT, ACCENT if state == "tab_selected" else BORDER, 0)
		tab.border_width_bottom = 2
		tab.border_color = ACCENT if state == "tab_selected" else Color(ACCENT, 0.4)
		tab.corner_radius_top_left = 8
		tab.corner_radius_top_right = 8
		tab.content_margin_left = 14
		tab.content_margin_right = 14
		theme.set_stylebox(state, "TabBar", tab)
		theme.set_stylebox(state, "TabContainer", tab)
	var idle_tab := _box(PANEL, BORDER, 0)
	idle_tab.corner_radius_top_left = 8
	idle_tab.corner_radius_top_right = 8
	idle_tab.content_margin_left = 14
	idle_tab.content_margin_right = 14
	theme.set_stylebox("tab_unselected", "TabBar", idle_tab)
	theme.set_stylebox("tab_unselected", "TabContainer", idle_tab)
	theme.set_color("font_selected_color", "TabBar", TEXT)
	theme.set_color("font_unselected_color", "TabBar", MUTED)
	theme.set_color("font_selected_color", "TabContainer", TEXT)
	theme.set_color("font_unselected_color", "TabContainer", MUTED)
	theme.set_stylebox("panel", "TabContainer", panel_style())
	var bar_bg := _box(BG, BORDER)
	bar_bg.set_corner_radius_all(5)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := _box(ACCENT, ACCENT, 0)
	bar_fill.set_corner_radius_all(5)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("4d5562"))

	var edit := _box(BG, BORDER)
	edit.set_corner_radius_all(8)
	theme.set_stylebox("normal", "LineEdit", edit)
	var edit_focus := _box(Color(0, 0, 0, 0), ACCENT, 1)
	edit_focus.set_corner_radius_all(8)
	theme.set_stylebox("focus", "LineEdit", edit_focus)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color("6e7681"))
	theme.set_color("caret_color", "LineEdit", ACCENT)

	# Barras de desplazamiento: finas, redondeadas, el tirador del acento al pasar.
	for bar in ["VScrollBar", "HScrollBar"]:
		var scroll := _box(Color(BG, 0.6), Color(0, 0, 0, 0), 0)
		scroll.set_corner_radius_all(4)
		scroll.set_content_margin_all(2)
		theme.set_stylebox("scroll", bar, scroll)
		for g in [["grabber", BORDER.lightened(0.15)], ["grabber_highlight", Color(ACCENT, 0.7)], ["grabber_pressed", ACCENT]]:
			var grab := _box(g[1], Color(0, 0, 0, 0), 0)
			grab.set_corner_radius_all(4)
			grab.set_content_margin_all(4)
			theme.set_stylebox(g[0], bar, grab)

	# Deslizadores (volúmenes): pista hundida, relleno del acento y un tirador redondo.
	var track := _box(BG, BORDER)
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

	var tip := _box(Color(BG, 0.96), BORDER)
	tip.set_corner_radius_all(8)
	tip.border_width_top = 3
	tip.border_color = Color(ACCENT, 0.7)
	tip.set_content_margin_all(10)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	return theme


## Tarjeta de los menús: plana, redondeada, con una sombra suave.
static func panel_style() -> StyleBoxFlat:
	var s := _box(Color(PANEL, 0.96), BORDER)
	s.set_corner_radius_all(RADIUS)
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
	s.set_corner_radius_all(8)
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

## Líneas y adornos de las ventanas (el nombre viene del latón de antes; desde T166,
## turquesa apagado) y su versión oscura.
const GOLD := Color("3aa99b")
const GOLD_DARK := Color("1f4d4a")
const WINDOW_BG := Color("12171e")


## Fondo de las ventanas: tarjeta plana y redondeada con borde fino y sombra (T166;
## antes, el marco de latón del atlas).
static func window_style() -> StyleBox:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(WINDOW_BG, 0.97)
	s.border_color = BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(RADIUS)
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 14
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


## Viste una ventana: la tarjeta, una raya del acento arriba a la izquierda y un grafo
## de tres nodos abajo a la derecha (T166). Se dibuja detrás del contenido.
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
				if panel.visible:
					UiMotion.window_in(panel)   # entrada corta (T97)
		check.call_deferred())
	panel.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, panel.size)
		panel.draw_rect(Rect2(RADIUS, 0, minf(64.0, r.size.x * 0.3), 3), ACCENT)
		draw_graph_motif(panel, r.end - Vector2(18, 16)))


## Tres nodos unidos (el motivo de grafo de las tarjetas), con el de la derecha en `p`.
static func draw_graph_motif(ci: CanvasItem, p: Vector2, color := ACCENT) -> void:
	var n := [p + Vector2(-50, 2), p + Vector2(-26, -10), p]
	ci.draw_line(n[0], n[1], Color(color, 0.45), 1.5)
	ci.draw_line(n[1], n[2], Color(color, 0.45), 1.5)
	for q in n:
		ci.draw_circle(q, 3.0, Color(color, 0.8))


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


## Un nodo (lo que eran los remaches, T166): un punto del acento con su anillo.
static func draw_rivet(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_circle(p, 3.0, Color(GOLD, 0.25))
	ci.draw_circle(p, 1.6, GOLD)


## Cabecera de ventana: título, subtítulo y un botón de cerrar.
static func window_header(title: String, subtitle: String, on_close: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	box.add_child(row)
	var t := title_label(title, 26, TEXT)
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


## Separador: una línea con una red neuronal pequeña (tres capas de nodos) en el centro.
static func ornament() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 26)
	c.draw.connect(func() -> void:
		draw_neural_separator(c, Vector2(0, c.size.y / 2.0), Vector2(c.size.x, c.size.y / 2.0)))
	return c


static func draw_neural_separator(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	var mid := (a + b) / 2.0
	ci.draw_line(a, mid - Vector2(38, 0), BORDER, 1.0)
	ci.draw_line(mid + Vector2(38, 0), b, BORDER, 1.0)
	var layers := [[-6.0, 6.0], [-10.0, 0.0, 10.0], [-6.0, 6.0]]
	for li in layers.size():
		for yi in layers[li]:
			var p: Vector2 = mid + Vector2(-24 + li * 24, yi)
			if li < 2:
				for yj in layers[li + 1]:
					ci.draw_line(p, mid + Vector2(-24 + (li + 1) * 24, yj), Color(AI, 0.4), 1.0)
			ci.draw_circle(p, 2.3, AI)


## Título de sección con un nodo delante.
static func section_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(10, 18)
	gem.draw.connect(func() -> void:
		gem.draw_circle(Vector2(5, 9), 4.5, Color(ACCENT, 0.25))
		gem.draw_circle(Vector2(5, 9), 2.5, ACCENT))
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
static func inset_style(border := BORDER) -> StyleBoxFlat:
	var s := _box(PANEL_LIGHT, border)
	s.set_corner_radius_all(8)
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
	if not root.is_inside_tree() or (is_equal_approx(chosen, 1.0) and safe_margins(root.get_viewport()) == Vector4.ZERO):
		return
	var fit := func() -> void:
		if not is_instance_valid(root) or not root.is_inside_tree():
			return   # el menú ya se cerró
		# Igual que GameUI.apply_ui_scale: fuera de la muesca (T142) y, en pantallas bajas,
		# reducida hasta caber (560 px de alto).
		var m := safe_margins(root.get_viewport())
		var view := root.get_viewport().get_visible_rect().size - Vector2(m.x + m.z, m.y + m.w)
		var s := minf(chosen, maxf(1.0, view.y / 560.0))
		root.set_anchors_preset(Control.PRESET_TOP_LEFT)
		root.position = Vector2(m.x, m.y)
		root.scale = Vector2(s, s)
		root.size = view / s
	root.get_viewport().size_changed.connect(fit)
	fit.call()


## Pruebas y capturas (T142): como si la pantalla tuviera esta zona segura, en
## píxeles de la ventana (Rect2i() = la de verdad).
static var test_safe_area := Rect2i()


## Lo que tapan la muesca y las esquinas redondeadas del celular (T142), en
## coordenadas del lienzo: (izquierda, arriba, derecha, abajo). Cero en el PC.
static func safe_margins(vp: Viewport) -> Vector4:
	if test_safe_area == Rect2i() and not GameSettings.is_mobile():
		return Vector4.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	var safe := test_safe_area if test_safe_area != Rect2i() else DisplayServer.get_display_safe_area()
	return margins_for(Rect2(safe), win, vp.get_visible_rect().size)


## Lo más que puede ocupar cada margen (fracción del lado): una muesca de verdad
## ocupa un 3-5 %; más es una zona segura mal informada (T142b).
const SAFE_MAX := 0.08


## Márgenes del lienzo `canvas` para la zona segura `safe` de una ventana `win`. Una
## zona segura que no cabe en la ventana (p. ej. dada en la otra orientación al girar)
## no se usa: en el celular hacía que la interfaz se saliera de la pantalla y
## parpadeara. Cada margen, como mucho SAFE_MAX y redondeado (sin temblores).
static func margins_for(safe: Rect2, win: Vector2, canvas: Vector2) -> Vector4:
	if safe.size.x <= 0.0 or safe.size.y <= 0.0 or win.x <= 0.0 or win.y <= 0.0 \
			or not Rect2(Vector2.ZERO, win).grow(1.0).encloses(safe):
		return Vector4.ZERO
	var k := canvas / win
	var m := Vector4(safe.position.x * k.x, safe.position.y * k.y, (win.x - safe.end.x) * k.x, (win.y - safe.end.y) * k.y)
	var cap := Vector4(canvas.x, canvas.y, canvas.x, canvas.y) * SAFE_MAX
	return Vector4(roundf(clampf(m.x, 0.0, cap.x)), roundf(clampf(m.y, 0.0, cap.y)),
		roundf(clampf(m.z, 0.0, cap.z)), roundf(clampf(m.w, 0.0, cap.w)))


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
				img.set_pixel(x, y, BG)
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
	b.pressed.connect(func() -> void: UiMotion.bounce(b))   # rebote al pulsar (T97)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			Sfx.play("ui_hover", -18.0))   # T77
	return b


## Fondo de los menús: color liso + rejilla de puntos (T166) + viñeta.
static func draw_background(ci: CanvasItem, size: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), BG)
	var dot := Color(BORDER, 0.8)
	var step := 24.0
	for y in range(0, int(size.y) + 1, int(step)):
		for x in range(0, int(size.x) + 1, int(step)):
			ci.draw_rect(Rect2(x, y, 2, 2), dot)
	# Resplandor frío en el centro y viñeta en los bordes.
	var center := size / 2.0
	for k in 10:
		var r := maxf(size.x, size.y) * (0.55 - k * 0.045)
		ci.draw_circle(center + Vector2(0, size.y * 0.1), r, Color(ACCENT, 0.006))
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
