class_name AscendancyPanel
extends Control
## Panel circular de la ascendencia (como en PoE): se abre desde el medallón que
## hay junto al inicio de la clase en el árbol pasivo.
## - Sin ascendencia: las tres opciones de la clase; al elegir una (desde el
##   nivel 20) la elección es permanente.
## - Con ascendencia: su inicio en el centro y sus pasivas alrededor; cada una
##   cuesta un punto de ascendencia (1 al nivel 20, 2 al 25, 3 al 30).

signal changed
signal closed

const RADIUS := 300.0
const OPTION_RADIUS := 64.0
const NODE_RADIUS := 34.0
const COLORS := [Color("c84b4b"), Color("4b8bd6"), Color("5cb85c")]

var character: CharacterData
## En la pantalla de pruebas se puede cambiar de ascendencia libremente.
var allow_change := false

var _hover := -1          # opción o pasiva bajo el cursor
var _selected := -1       # opción elegida (antes de confirmar)
var _close_hover := false
var _confirm_hover := false
var _change_hover := false
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(p_character: CharacterData) -> void:
	character = p_character
	_selected = -1
	_hover = -1
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _center() -> Vector2:
	return size / 2.0


func _ascendancies() -> Array:
	return character.class_def.get("ascendancies", []) if character else []


func _option_pos(i: int) -> Vector2:
	return _center() + Vector2.from_angle(deg_to_rad(-150.0 + 120.0 * i)) * 200.0 + Vector2(0, 10)


func _node_pos(i: int, count: int) -> Vector2:
	var spread := 140.0
	var a := -90.0 - spread / 2.0 + spread * i / maxf(1.0, count - 1)
	return _center() + Vector2(0, 60) + Vector2.from_angle(deg_to_rad(a)) * 190.0


func _close_rect() -> Rect2:
	return Rect2(_center() + Vector2(RADIUS * 0.66, -RADIUS * 0.82), Vector2(34, 34))


func _confirm_rect() -> Rect2:
	return Rect2(_center() + Vector2(-140, RADIUS + 18), Vector2(280, 40))


func _change_rect() -> Rect2:
	return Rect2(_center() + Vector2(-140, RADIUS + 64), Vector2(280, 32))


# --- Dibujo ---

func _draw() -> void:
	if character == null:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	var c := _center()
	var class_color := Color(character.class_def.get("color", "d9a441"))
	# Disco con anillos dorados y un emblema tenue de la clase.
	draw_circle(c, RADIUS + 18.0, Color("0d0b10"))
	draw_circle(c, RADIUS, Color("17131c"))
	for k in 5:
		draw_circle(c, RADIUS * (0.95 - k * 0.12), Color(class_color, 0.025))
	draw_arc(c, RADIUS + 10.0, 0.0, TAU, 96, UiStyle.GOLD_DARK, 6.0, true)
	draw_arc(c, RADIUS, 0.0, TAU, 96, UiStyle.GOLD, 3.0, true)
	for k in 12:
		var p := c + Vector2.from_angle(TAU * k / 12.0 + _time * 0.05) * (RADIUS + 10.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), UiStyle.GOLD)
	# Cerrar.
	var cr := _close_rect()
	draw_circle(cr.get_center(), 17.0, Color("2c2735") if _close_hover else Color("1a1620"))
	draw_arc(cr.get_center(), 17.0, 0.0, TAU, 24, UiStyle.GOLD, 2.0, true)
	draw_string(font, cr.position + Vector2(0, 23), "✕", HORIZONTAL_ALIGNMENT_CENTER, cr.size.x, 16, UiStyle.TEXT)
	if character.ascendancy_def.is_empty():
		_draw_choice(font, class_color)
	else:
		_draw_tree(font)


func _draw_choice(font: Font, class_color: Color) -> void:
	var c := _center()
	_title(font, c + Vector2(0, -RADIUS + 46), "Ascendencia de %s" % character.class_def["name"], 22, UiStyle.ACCENT)
	var lock := character.level < CharacterData.ASCENDANCY_LEVEL
	var sub := "Elige el camino de tu carrera. La elección es permanente." if not lock else \
		"Disponible al nivel %d (te faltan %d). Puedes ver las opciones." % [CharacterData.ASCENDANCY_LEVEL, CharacterData.ASCENDANCY_LEVEL - character.level]
	_title(font, c + Vector2(0, -RADIUS + 70), sub, 13, UiStyle.MUTED if not lock else Color("e06c6c"))
	var options := _ascendancies()
	for i in options.size():
		var p := _option_pos(i)
		var col: Color = COLORS[i % COLORS.size()]
		var active := i == _hover or i == _selected
		draw_circle(p, OPTION_RADIUS + 6.0, Color(col, 0.25 if active else 0.1))
		draw_circle(p, OPTION_RADIUS, Color("120f16"))
		draw_arc(p, OPTION_RADIUS, 0.0, TAU, 48, UiStyle.ACCENT if i == _selected else (col if active else col.darkened(0.3)), 4.0, true)
		_emblem(p, OPTION_RADIUS * 0.55, col, i)
		# Las de arriba llevan el nombre encima; la de abajo, debajo (el centro es para el detalle).
		var label_y := -OPTION_RADIUS - 10.0 if p.y < _center().y else OPTION_RADIUS + 20.0
		_title(font, p + Vector2(0, label_y), options[i]["name"], 14, UiStyle.TEXT if active else UiStyle.MUTED)
	# Detalle de la opción señalada (o elegida) en el centro.
	var show := _hover if _hover != -1 else _selected
	if show != -1:
		var a: Dictionary = options[show]
		var lines := PackedStringArray([a.get("description", "")])
		for p in a.get("passives", []):
			lines.append("• %s: %s" % [p["name"], _mods_text(p)])
		_paragraph(font, c + Vector2(-115, -45), 230, "\n".join(lines), 11)
	else:
		_title(font, c + Vector2(0, 0), "Pasa el mouse por una opción", 12, UiStyle.MUTED)
	# Confirmar.
	if _selected != -1:
		var r := _confirm_rect()
		var enabled := not lock
		draw_rect(r, Color("332b22") if (_confirm_hover and enabled) else Color("221e29"))
		draw_rect(r, UiStyle.ACCENT if enabled else Color("4a4352"), false, 2.0)
		draw_string(font, r.position + Vector2(0, 26), ("Elegir: %s" % options[_selected]["name"]) if enabled else "Bloqueado hasta el nivel 20",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, UiStyle.TEXT if enabled else UiStyle.MUTED)


func _draw_tree(font: Font) -> void:
	var c := _center()
	var a := character.ascendancy_def
	var idx: int = _ascendancies().find(a)
	var col: Color = COLORS[maxi(0, idx) % COLORS.size()]
	_title(font, c + Vector2(0, -RADIUS + 46), a["name"], 24, UiStyle.ACCENT)
	_title(font, c + Vector2(0, -RADIUS + 70), "Puntos de ascendencia: %d / %d   (1 al nivel 20, +1 a los 25 y 30)" % [
		character.ascendancy_points_available(), character.ascendancy_points_total()], 12, UiStyle.MUTED)
	var start := c + Vector2(0, 150)
	var passives: Array = a.get("passives", [])
	for i in passives.size():
		var p := _node_pos(i, passives.size())
		var on := character.ascendancy_nodes.has(i)
		draw_line(start, p, UiStyle.GOLD if on else Color("3a3442"), 6.0 if on else 3.0, true)
	# Inicio de la ascendencia.
	draw_circle(start, 40.0, Color("120f16"))
	_emblem(start, 24.0, col, maxi(0, idx))
	draw_arc(start, 40.0, 0.0, TAU, 48, UiStyle.GOLD, 4.0, true)
	for i in passives.size():
		var p := _node_pos(i, passives.size())
		var on := character.ascendancy_nodes.has(i)
		var can := not on and character.ascendancy_points_available() > 0
		draw_circle(p, NODE_RADIUS + 5.0, Color(col, 0.25 if (on or i == _hover) else 0.08))
		draw_circle(p, NODE_RADIUS, Color("1a1620") if not on else col.darkened(0.45))
		_emblem(p, NODE_RADIUS * 0.5, col if on else col.darkened(0.5), i + 3)
		draw_arc(p, NODE_RADIUS, 0.0, TAU, 40, UiStyle.ACCENT if on else (col if can else Color("4a4352")), 4.0, true)
		_title(font, p + Vector2(0, NODE_RADIUS + 18), passives[i]["name"], 12, UiStyle.TEXT if on else UiStyle.MUTED)
	if _hover != -1 and _hover < passives.size():
		var hp: Dictionary = passives[_hover]
		var state := "Asignada (click derecho para quitar)" if character.ascendancy_nodes.has(_hover) else \
			("Click para asignar (1 punto)" if character.ascendancy_points_available() > 0 else "Sin puntos de ascendencia")
		_paragraph(font, c + Vector2(-130, -10), 260, "%s\n%s\n%s" % [hp["name"], _mods_text(hp).replace(", ", "\n"), state], 12)
	else:
		_paragraph(font, c + Vector2(-130, -10), 260, a.get("description", ""), 12)
	if allow_change:
		var r := _change_rect()
		draw_rect(r, Color("2c2735") if _change_hover else Color("1a1620"))
		draw_rect(r, Color("4a4352"), false, 1.0)
		draw_string(font, r.position + Vector2(0, 22), "Cambiar ascendencia (solo en modo prueba)", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, UiStyle.MUTED)


## Emblema simple (cada opción con un dibujo distinto, hasta tener arte).
func _emblem(p: Vector2, r: float, col: Color, variant: int) -> void:
	match variant % 6:
		0:   # escudo
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r, -r * 0.8), p + Vector2(r, -r * 0.8), p + Vector2(r * 0.8, r * 0.2), p + Vector2(0, r), p + Vector2(-r * 0.8, r * 0.2)]), col)
		1:   # rombo con aro
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), col)
			draw_arc(p, r * 1.15, 0.0, TAU, 24, col.lightened(0.3), 2.0, true)
		2:   # estrella
			var pts := PackedVector2Array()
			for k in 10:
				pts.append(p + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (r if k % 2 == 0 else r * 0.45))
			draw_colored_polygon(pts, col)
		3:
			draw_circle(p, r * 0.8, col)
		4:
			draw_rect(Rect2(p - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), col)
		_:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.9, r * 0.7), p + Vector2(-r * 0.9, r * 0.7)]), col)


func _mods_text(p: Dictionary) -> String:
	var parts := PackedStringArray()
	for md in p.get("mods", []):
		parts.append(Modifier.from_dict(md).describe())
	return ", ".join(parts)


func _title(font: Font, pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string_outline(font, pos + Vector2(-300, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 600, font_size, 5, Color.BLACK)
	draw_string(font, pos + Vector2(-300, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 600, font_size, color)


func _paragraph(font: Font, pos: Vector2, width: float, text: String, font_size: int) -> void:
	draw_multiline_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, -1, UiStyle.TEXT)


# --- Entrada ---

func _gui_input(event: InputEvent) -> void:
	if character == null:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		_update_hover(mm.position)
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	accept_event()
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if _close_rect().has_point(mb.position) or mb.position.distance_to(_center()) > RADIUS + 120.0:
			_close()
			return
		if character.ascendancy_def.is_empty():
			if _hover != -1:
				_selected = _hover
			elif _selected != -1 and _confirm_rect().has_point(mb.position) and character.level >= CharacterData.ASCENDANCY_LEVEL:
				character.set_ascendancy(StringName(_ascendancies()[_selected]["id"]))
				_selected = -1
				changed.emit()
		else:
			if allow_change and _change_rect().has_point(mb.position):
				character.set_ascendancy(&"")
				changed.emit()
			elif _hover != -1 and character.allocate_ascendancy_node(_hover):
				changed.emit()
	elif mb.button_index == MOUSE_BUTTON_RIGHT and not character.ascendancy_def.is_empty() and _hover != -1:
		if character.refund_ascendancy_node(_hover):
			changed.emit()


func _update_hover(p: Vector2) -> void:
	_hover = -1
	_close_hover = _close_rect().has_point(p)
	_confirm_hover = _confirm_rect().has_point(p)
	_change_hover = allow_change and _change_rect().has_point(p)
	if character.ascendancy_def.is_empty():
		for i in _ascendancies().size():
			if p.distance_to(_option_pos(i)) <= OPTION_RADIUS:
				_hover = i
	else:
		var count: int = character.ascendancy_def.get("passives", []).size()
		for i in count:
			if p.distance_to(_node_pos(i, count)) <= NODE_RADIUS + 4.0:
				_hover = i


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	visible = false
	closed.emit()
