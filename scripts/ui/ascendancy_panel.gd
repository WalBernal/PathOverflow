class_name AscendancyPanel
extends Control
## Panel de la ascendencia (como en PoE 2): se abre desde el medallón que hay
## junto al inicio de la clase en el árbol pasivo.
## - Sin ascendencia: un disco ilustrado por opción (arte, nombre, vista previa
##   del árbol y descripción); al elegir una (desde el nivel 20) es permanente.
## - Con ascendencia: su disco con el árbol de 20 nodos encima. Cada nodo cuesta
##   un punto (2 al nivel 20 y 2 más cada 10 niveles, hasta 10) y tiene que
##   estar pegado al inicio o a otro asignado. Click derecho: quitar.

signal changed
signal closed

const COLORS := [Color("c84b4b"), Color("4b8bd6"), Color("5cb85c")]
const NODE_RADIUS := {"minor": 10.0, "notable": 18.0, "unique": 23.0}
const KIND_NAMES := {"minor": "Pasiva menor", "notable": "Notable", "unique": "Habilidad única"}

var character: CharacterData
## En la pantalla de pruebas se puede cambiar de ascendencia libremente.
var allow_change := false

var _hover := -1          # opción o nodo bajo el cursor
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
	return size / 2.0 + Vector2(0, 16)


## Radio del disco del árbol (se achica si la pantalla es baja).
func _radius() -> float:
	return clampf(size.y * 0.37, 180.0, 310.0)


func _ascendancies() -> Array:
	return character.class_def.get("ascendancies", []) if character else []


# --- Elección: un disco por opción ---

func _option_radius() -> float:
	var n := maxi(1, _ascendancies().size())
	return minf(_radius() * 0.78, (size.x - 80.0) / (2.0 * n) - 12.0)


func _option_pos(i: int) -> Vector2:
	var n := _ascendancies().size()
	var r := _option_radius()
	return _center() + Vector2((i - (n - 1) / 2.0) * (2.0 * r + 30.0), -10.0)


func _close_rect() -> Rect2:
	return Rect2(Vector2(size.x - 64, 18), Vector2(40, 40))


func _confirm_rect() -> Rect2:
	var y := _option_pos(0).y + _option_radius() + 22.0 if character.ascendancy_def.is_empty() else _center().y + _radius() + 20.0
	return Rect2(Vector2(size.x / 2.0 - 160, y), Vector2(320, 42))


func _change_rect() -> Rect2:
	return Rect2(Vector2(size.x / 2.0 - 150, _center().y + _radius() + 22.0), Vector2(300, 32))


func _node_pos(i: int) -> Vector2:
	var nodes: Array = character.ascendancy_def.get("passives", [])
	var p: Vector2 = nodes[i].get("pos", Vector2.from_angle(-PI / 2.0 + TAU * i / maxf(1.0, nodes.size())) * 0.6)
	return _center() + p * _radius() * 0.92


func _start_pos() -> Vector2:
	return _center() + AscendancyTree.START_POS * _radius() * 0.92


# --- Dibujo ---

func _draw() -> void:
	if character == null:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.03, 0.94))
	var cr := _close_rect()
	draw_circle(cr.get_center(), 19.0, Color("2c2735") if _close_hover else Color("1a1620"))
	draw_arc(cr.get_center(), 19.0, 0.0, TAU, 24, UiStyle.GOLD, 2.0, true)
	draw_string(font, cr.position + Vector2(0, 27), "✕", HORIZONTAL_ALIGNMENT_CENTER, cr.size.x, 17, UiStyle.TEXT)
	if character.ascendancy_def.is_empty():
		_draw_choice(font)
	else:
		_draw_tree(font)


## Disco ilustrado: arte recortado en círculo, aros dorados y adornos.
func _disc(c: Vector2, r: float, asc_id: String, brightness: float, accent: Color) -> void:
	draw_circle(c, r + 14.0, Color("0b090e"))
	var tex := AscendancyArt.texture(asc_id)
	draw_texture_rect(tex, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(brightness, brightness, brightness))
	draw_arc(c, r + 7.0, 0.0, TAU, 96, UiStyle.GOLD_DARK, 7.0, true)
	draw_arc(c, r, 0.0, TAU, 96, accent, 2.5, true)
	draw_arc(c, r + 12.0, 0.0, TAU, 96, Color(UiStyle.GOLD, 0.6), 1.5, true)
	for k in 8:
		var p := c + Vector2.from_angle(TAU * k / 8.0 + PI / 8.0) * (r + 7.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), UiStyle.GOLD)


## Placa con el nombre sobre el disco (como en PoE 2).
func _banner(font: Font, c: Vector2, text: String, font_size: int, lit: bool) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 48.0
	var r := Rect2(c - Vector2(w / 2.0, font_size + 6), Vector2(w, font_size * 1.6 + 8))
	draw_rect(r, Color("1c1712"))
	draw_rect(r.grow(-3), Color("2a2118") if lit else Color("221b14"))
	draw_rect(r, UiStyle.GOLD if lit else UiStyle.GOLD_DARK, false, 2.0)
	for s in [-1.0, 1.0]:
		var tip := Vector2(c.x + s * (w / 2.0 + 10.0), r.get_center().y)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-s * 12, -8), tip + Vector2(-s * 12, 8)]), UiStyle.GOLD_DARK)
	draw_string(font, Vector2(r.position.x, r.position.y + font_size + 5), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, UiStyle.ACCENT if lit else UiStyle.TEXT)


func _draw_choice(font: Font) -> void:
	_title(font, Vector2(size.x / 2.0, 46), "Elige tu ascendencia de %s" % character.class_def["name"], 26, UiStyle.ACCENT)
	var lock := character.level < CharacterData.ASCENDANCY_LEVEL
	var sub := "El camino de tu carrera. La elección es permanente." if not lock else \
		"Disponible al nivel %d (te faltan %d). Puedes ver las opciones." % [CharacterData.ASCENDANCY_LEVEL, CharacterData.ASCENDANCY_LEVEL - character.level]
	_title(font, Vector2(size.x / 2.0, 72), sub, 14, UiStyle.MUTED if not lock else Color("e06c6c"))
	var options := _ascendancies()
	var r := _option_radius()
	for i in options.size():
		var a: Dictionary = options[i]
		var c := _option_pos(i)
		var active := i == _hover or i == _selected
		var col: Color = COLORS[i % COLORS.size()]
		if active:
			draw_circle(c, r + 26.0, Color(col, 0.12 + 0.05 * sin(_time * 3.0)))
		_disc(c, r, String(a["id"]), 0.95 if active else 0.6, UiStyle.ACCENT if i == _selected else col)
		# Vista previa del árbol (líneas y puntos tenues).
		var nodes: Array = a.get("passives", [])
		var to_screen := func(p: Vector2) -> Vector2: return c + p * r * 0.92
		for j in nodes.size():
			for l in nodes[j].get("links", []):
				var from: Vector2 = to_screen.call(AscendancyTree.START_POS if l == AscendancyTree.START else nodes[l]["pos"])
				draw_line(from, to_screen.call(nodes[j]["pos"]), Color(0.9, 0.85, 0.7, 0.25), 1.5, true)
		for j in nodes.size():
			if nodes[j].has("pos"):
				var big: bool = nodes[j].get("kind", "") != "minor"
				draw_circle(to_screen.call(nodes[j]["pos"]), 5.0 if big else 3.0, Color(0.95, 0.85, 0.6, 0.55 if big else 0.35))
		_banner(font, c - Vector2(0, r + 4.0), a["name"], 17, active)
		# Descripción en la parte de abajo del disco, sobre una franja oscura.
		var box := Rect2(c + Vector2(-r * 0.78, r * 0.3), Vector2(r * 1.56, r * 0.5))
		draw_rect(box, Color(0, 0, 0, 0.55))
		var uniques := PackedStringArray()
		for n in nodes:
			if n.get("kind", "") == "unique":
				uniques.append(n["name"])
		var text: String = a.get("description", "")
		if not uniques.is_empty():
			text += "\nÚnicas: " + ", ".join(uniques)
		draw_multiline_string(font, box.position + Vector2(8, 18), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 16, 12, 6,
			Color("f4e6c8") if active else UiStyle.MUTED)
	if _selected != -1:
		var rr := _confirm_rect()
		var enabled := not lock
		draw_rect(rr, Color("332b22") if (_confirm_hover and enabled) else Color("221e29"))
		draw_rect(rr, UiStyle.ACCENT if enabled else Color("4a4352"), false, 2.0)
		draw_string(font, rr.position + Vector2(0, 28), ("Elegir: %s" % options[_selected]["name"]) if enabled else "Bloqueado hasta el nivel %d" % CharacterData.ASCENDANCY_LEVEL,
			HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 16, UiStyle.TEXT if enabled else UiStyle.MUTED)
	else:
		_title(font, Vector2(size.x / 2.0, _confirm_rect().position.y + 26), "Click en un disco para elegirlo", 13, UiStyle.MUTED)


func _draw_tree(font: Font) -> void:
	var c := _center()
	var R := _radius()
	var a := character.ascendancy_def
	var idx: int = _ascendancies().find(a)
	var col: Color = COLORS[maxi(0, idx) % COLORS.size()]
	_title(font, Vector2(size.x / 2.0, 40), "Puntos de ascendencia: %d / %d" % [character.ascendancy_points_available(), character.ascendancy_points_total()],
		17, Color("ffd84a") if character.ascendancy_points_available() > 0 else UiStyle.TEXT)
	_title(font, Vector2(size.x / 2.0, 62), "2 al nivel %d y 2 más cada 10 niveles (máximo %d) · click: asignar · click derecho: quitar" % [
		CharacterData.ASCENDANCY_LEVEL, CharacterData.ASCENDANCY_MAX_POINTS], 12, UiStyle.MUTED)
	_disc(c, R, String(a["id"]), 0.5, col)
	_banner(font, c - Vector2(0, R + 6.0), a["name"], 20, true)
	var nodes: Array = a.get("passives", [])
	var taken := character.ascendancy_nodes
	# Enlaces: dorados si los dos extremos están asignados.
	for i in nodes.size():
		for l in nodes[i].get("links", [AscendancyTree.START]):
			var from := _start_pos() if l == AscendancyTree.START else _node_pos(l)
			var lit: bool = taken.has(i) and (l == AscendancyTree.START or taken.has(l))
			var reachable: bool = not lit and (taken.has(i) or l == AscendancyTree.START or taken.has(l))
			draw_line(from, _node_pos(i), Color("0a080c"), 7.0, true)
			draw_line(from, _node_pos(i), UiStyle.GOLD if lit else (Color(0.85, 0.78, 0.6, 0.6) if reachable else Color(0.5, 0.45, 0.4, 0.4)), 4.0 if lit else 2.5, true)
	# Inicio de la ascendencia.
	var s := _start_pos()
	draw_circle(s, 24.0, Color("120f16"))
	draw_circle(s, 18.0, col.darkened(0.3))
	_emblem(s, 11.0, col.lightened(0.4), maxi(0, idx))
	draw_arc(s, 24.0, 0.0, TAU, 40, UiStyle.GOLD, 3.0, true)
	for i in nodes.size():
		_draw_node(i, nodes[i], col)
	# Ayuda del nodo bajo el cursor (o la descripción).
	if _hover != -1 and _hover < nodes.size():
		_tooltip(font, _hover, nodes[_hover])
	if allow_change:
		var r := _change_rect()
		draw_rect(r, Color("2c2735") if _change_hover else Color("1a1620"))
		draw_rect(r, Color("4a4352"), false, 1.0)
		draw_string(font, r.position + Vector2(0, 22), "Cambiar ascendencia (solo en modo prueba)", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, UiStyle.MUTED)


func _draw_node(i: int, n: Dictionary, col: Color) -> void:
	var p := _node_pos(i)
	var kind: String = n.get("kind", "notable")
	var r: float = NODE_RADIUS.get(kind, 16.0)
	var on := character.ascendancy_nodes.has(i)
	var can := not on and character.can_allocate_ascendancy_node(i)
	var hover := i == _hover
	if on or hover or can:
		draw_circle(p, r + 6.0 + (2.0 * sin(_time * 4.0) if can else 0.0), Color(col if on else UiStyle.GOLD, 0.28 if on else 0.14))
	if kind == "unique":
		# Marco en rombo para las habilidades únicas.
		var d := r + 5.0
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -d), p + Vector2(d, 0), p + Vector2(0, d), p + Vector2(-d, 0)]), UiStyle.GOLD if on else UiStyle.GOLD_DARK)
	draw_circle(p, r, Color("0e0c12"))
	draw_circle(p, r - 3.0, col.darkened(0.25) if on else Color("221d28"))
	if kind != "minor":
		_emblem(p, r * 0.5, Color("fff0c8") if on else (col.lightened(0.2) if can or hover else col.darkened(0.45)), i)
	else:
		draw_circle(p, 3.0, Color("fff0c8") if on else Color(0.6, 0.55, 0.5))
	draw_arc(p, r, 0.0, TAU, 32, UiStyle.ACCENT if on else (UiStyle.GOLD if can or hover else Color("4a4352")), 2.5 if kind == "minor" else 3.5, true)


func _tooltip(font: Font, i: int, n: Dictionary) -> void:
	var lines := PackedStringArray()
	for md in n.get("mods", []):
		lines.append("• " + Modifier.from_dict(md).describe())
	var on := character.ascendancy_nodes.has(i)
	var state := ""
	if on:
		state = "Asignado · click derecho para quitar" if AscendancyTree.can_refund(character.ascendancy_def.get("passives", []), character.ascendancy_nodes, i) \
			else "Asignado (otros dependen de este)"
	elif character.ascendancy_points_available() <= 0:
		state = "Sin puntos de ascendencia"
	elif character.can_allocate_ascendancy_node(i):
		state = "Click para asignar (1 punto)"
	else:
		state = "Tiene que estar conectado a uno asignado"
	var w := 360.0
	var h := 74.0 + lines.size() * 17.0
	var p := _node_pos(i)
	var pos := p + Vector2(28, -h / 2.0)
	if pos.x + w > size.x - 10.0:
		pos.x = p.x - 28.0 - w
	pos.y = clampf(pos.y, 10.0, size.y - h - 10.0)
	var box := Rect2(pos, Vector2(w, h))
	draw_rect(box, Color("120f16"))
	draw_rect(box, UiStyle.GOLD_DARK, false, 2.0)
	var kind: String = n.get("kind", "notable")
	draw_string(font, pos + Vector2(10, 22), n["name"], HORIZONTAL_ALIGNMENT_LEFT, w - 20, 16, UiStyle.ACCENT if kind != "minor" else UiStyle.TEXT)
	draw_string(font, pos + Vector2(10, 39), KIND_NAMES.get(kind, ""), HORIZONTAL_ALIGNMENT_LEFT, w - 20, 11,
		Color("ffb84a") if kind == "unique" else UiStyle.MUTED)
	for k in lines.size():
		draw_string(font, pos + Vector2(10, 58 + k * 17), lines[k], HORIZONTAL_ALIGNMENT_LEFT, w - 20, 12, Color("a8c8ff"))
	draw_string(font, pos + Vector2(10, h - 10), state, HORIZONTAL_ALIGNMENT_LEFT, w - 20, 11,
		Color("ffd84a") if state.begins_with("Click") else UiStyle.MUTED)


## Emblema simple dentro de cada nodo (cada uno con un dibujo distinto).
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


func _title(font: Font, pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string_outline(font, pos + Vector2(-400, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 800, font_size, 5, Color.BLACK)
	draw_string(font, pos + Vector2(-400, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 800, font_size, color)


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
		if _close_rect().has_point(mb.position):
			_close()
			return
		if character.ascendancy_def.is_empty():
			if _hover != -1:
				_selected = _hover
			elif _selected != -1 and _confirm_rect().has_point(mb.position) and character.level >= CharacterData.ASCENDANCY_LEVEL:
				character.set_ascendancy(StringName(_ascendancies()[_selected]["id"]))
				_selected = -1
				changed.emit()
			elif mb.position.distance_to(_center()) > size.y:
				_close()
		else:
			if allow_change and _change_rect().has_point(mb.position):
				character.set_ascendancy(&"")
				changed.emit()
			elif _hover != -1 and character.allocate_ascendancy_node(_hover):
				Sfx.play("level_up", -10.0, 1.4)
				changed.emit()
			elif _hover == -1 and mb.position.distance_to(_center()) > _radius() + 60.0:
				_close()
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
			if p.distance_to(_option_pos(i)) <= _option_radius():
				_hover = i
	else:
		var nodes: Array = character.ascendancy_def.get("passives", [])
		for i in nodes.size():
			if p.distance_to(_node_pos(i)) <= float(NODE_RADIUS.get(nodes[i].get("kind", "notable"), 16.0)) + 5.0:
				_hover = i


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	visible = false
	closed.emit()
