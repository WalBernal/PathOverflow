class_name TouchPointer
extends Control
## El dedo en las ventanas (T109): inventario, alijo, tienda, habilidades, hoja de
## personaje, waypoints, desafíos y árbol pasivo. Como el cursor de mando
## (GamepadCursor), convierte los gestos en eventos de ratón, así que los paneles no
## necesitan saber nada del toque:
##   tocar una casilla o un nodo: pasa el «ratón» por encima (tooltip) y aparece un
##   botón con lo que hace el clic (Equipar, Comprar, Asignar…); tocarla otra vez, o
##   el botón, lo hace · tocar un botón: clic al momento · mantener: clic derecho ·
##   arrastrar: arrastrar (objetos) o mover la vista (árbol) · dos dedos: zoom en el
##   árbol y en el mapa grande.
## El ratón que Godot emula desde el toque se descarta dentro de las ventanas: los
## eventos los pone este nodo, con el dispositivo Touch.POINTER_DEVICE.

const LONG_PRESS := 0.5
const DRAG_START := 12.0
## Tocar otra vez lo mismo antes de este tiempo (s) es hacer su acción.
const SECOND_TAP := 4.0
const ACTION_SIZE := Vector2(150, 46)

## -> Array de las ventanas donde manda el dedo (Control).
var windows: Callable = func() -> Array: return []
## -> {text, button}: qué hace tocar esta casilla y con qué clic ({} = no hay nada que hacer).
var action_for: Callable = func(_cell: ItemCell) -> Dictionary: return {"text": "Usar", "button": MOUSE_BUTTON_LEFT}
var tree_view: PassiveTreeView
var world_map: WorldMap

## Dedo principal: {index, start, at, time, moved, long_done, target, inspect}.
var _press := {}
## Segundo dedo para el zoom: {index, at}; y la distancia de partida.
var _pinch := {}
var _pinch_base := 0.0
var _map_steps := 0.0
## Lo último que se tocó para ver (casilla o punto del árbol) y cuándo.
var _inspected: Variant = null
var _inspected_at := 0.0
var _inspected_point := Vector2.ZERO
var _inspected_button := MOUSE_BUTTON_LEFT
var _action: Button
var _last_window_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_action = UiStyle.button("Usar", func() -> void:
		_click(_inspected_point, _inspected_button)
		_forget(), int(ACTION_SIZE.x))
	_action.custom_minimum_size = ACTION_SIZE
	_action.add_theme_font_size_override("font_size", 18)
	gold(_action)
	_action.visible = false
	add_child(_action)


## Dorado y con sombra: tiene que verse encima de cualquier ventana (y del
## escenario, en el botón de usar del prólogo).
static func gold(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = UiStyle.ACCENT.darkened(0.15 if state == "pressed" else 0.0)
		box.border_color = Color("1a1208")
		box.set_border_width_all(2)
		box.set_corner_radius_all(6)
		box.shadow_color = Color(0, 0, 0, 0.6)
		box.shadow_size = 6
		b.add_theme_stylebox_override(state, box)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color("1a1208"))


func _process(_delta: float) -> void:
	if not Touch.shown():
		_action.visible = false
		return
	# Mantener: clic derecho, una vez.
	if not _press.is_empty() and not _press["moved"] and not _press["long_done"] and _pinch.is_empty() \
			and Time.get_ticks_msec() / 1000.0 - float(_press["time"]) >= LONG_PRESS:
		_press["long_done"] = true
		_click(_press["start"], MOUSE_BUTTON_RIGHT)
		_forget()
	if _action.visible and (windows.call().is_empty() or Time.get_ticks_msec() / 1000.0 - _inspected_at > SECOND_TAP * 3.0):
		_forget()


## ¿Manda aquí el dedo? `screen`, en coordenadas de la ventana del juego (lienzo).
func in_scope(screen: Vector2) -> bool:
	if _action.visible and _action.get_global_rect().has_point(screen):
		return false   # el botón de acción es un botón normal
	for w: Control in windows.call():
		if w.is_visible_in_tree() and w.get_global_rect().has_point(screen):
			return true
	return false


func _input(event: InputEvent) -> void:
	if not Touch.shown():
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if not _press.is_empty() or not _pinch.is_empty() or (mb and mb.pressed and in_scope(mb.position)):
			get_viewport().set_input_as_handled()
		return
	var st := event as InputEventScreenTouch
	if st:
		if st.pressed:
			_on_down(st.index, st.position)
		else:
			_on_up(st.index, st.position)
		return
	var sd := event as InputEventScreenDrag
	if sd:
		_on_drag(sd.index, sd.position)


func _on_down(index: int, p: Vector2) -> void:
	if not _press.is_empty() and _pinch.is_empty() and index != _press["index"] and _pinch_target() != "":
		# Segundo dedo: zoom. Lo que hacía el primero se suelta.
		if _press["moved"]:
			_send_button(_press["at"], MOUSE_BUTTON_LEFT, false)
		_pinch = {"index": index, "at": p}
		_pinch_base = maxf(1.0, p.distance_to(_press["at"]))
		_map_steps = 0.0
		get_viewport().set_input_as_handled()
		return
	if not _press.is_empty() or not in_scope(p):
		if _press.is_empty() and _pinch_target() == "map":
			_press = {"index": index, "start": p, "at": p, "time": 0.0, "moved": true, "long_done": true, "passive": true}
		return
	var cell := _cell_at(p)
	_press = {"index": index, "start": p, "at": p, "time": Time.get_ticks_msec() / 1000.0, "moved": false, "long_done": false,
		"cell": cell, "inspect": (cell != null and cell.item != null) or _in_tree(p), "passive": false}
	_motion(p, false)   # el «ratón» va al dedo: resalta lo que hay debajo
	get_viewport().set_input_as_handled()


func _on_drag(index: int, p: Vector2) -> void:
	if not _pinch.is_empty() and (index == _pinch["index"] or index == _press.get("index", -1)):
		if index == _pinch["index"]:
			_pinch["at"] = p
		else:
			_press["at"] = p
		_apply_pinch()
		get_viewport().set_input_as_handled()
		return
	if _press.is_empty() or index != _press["index"]:
		return
	if _press["passive"]:
		_press["at"] = p
		return
	if not _press["moved"] and p.distance_to(_press["start"]) >= DRAG_START and not _press["long_done"]:
		_press["moved"] = true
		_forget()
		_send_button(_press["start"], MOUSE_BUTTON_LEFT, true)   # empieza el arrastre (o mover la vista)
	_press["at"] = p
	if _press["moved"]:
		_motion(p, true)
	get_viewport().set_input_as_handled()


func _on_up(index: int, p: Vector2) -> void:
	if not _pinch.is_empty() and (index == _pinch["index"] or index == _press.get("index", -1)):
		var other: Variant = _press if index == _pinch["index"] else null
		_pinch = {}
		_press = {}
		if other != null:
			pass   # el primer dedo sigue apoyado, pero ya no hace nada hasta que se levante
		get_viewport().set_input_as_handled()
		return
	if _press.is_empty() or index != _press["index"]:
		return
	var press := _press
	_press = {}
	if press["passive"]:
		return
	get_viewport().set_input_as_handled()
	if press["moved"]:
		_motion(p, true)
		_send_button(p, MOUSE_BUTTON_LEFT, false)
		return
	if press["long_done"]:
		return
	var target: Variant = press["cell"] if press["cell"] != null else _tree_target(p)
	if not press["inspect"] or target == null:
		_click(p, MOUSE_BUTTON_LEFT)   # botones, pestañas, casillas vacías, el fondo del árbol: al momento
		_forget()
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _same_target(target) and now - _inspected_at <= SECOND_TAP:
		_click(_inspected_point, _inspected_button)   # segundo toque: hacer
		_forget()
		return
	_inspected = target
	_inspected_at = now
	_inspected_point = p
	_show_action(press["cell"], p)


func _same_target(target: Variant) -> bool:
	if _inspected == null or target == null:
		return false
	if target is ItemCell:
		return is_instance_valid(_inspected) and _inspected == target
	return _inspected is int and _inspected == target


## Botón de acción encima de lo tocado (el tooltip sale debajo a la derecha).
func _show_action(cell: ItemCell, p: Vector2) -> void:
	var act: Dictionary = {"text": "Asignar", "button": MOUSE_BUTTON_LEFT} if cell == null else action_for.call(cell)
	_action.visible = not act.is_empty()
	if act.is_empty():
		return
	_action.text = String(act["text"])
	_inspected_button = act["button"]
	var local := get_global_transform_with_canvas().affine_inverse() * p
	var anchor := local
	if cell != null:
		var r := cell.get_global_rect()
		anchor = get_global_transform_with_canvas().affine_inverse() * Vector2(r.get_center().x, r.position.y)
	_action.size = ACTION_SIZE
	var pos := anchor - Vector2(ACTION_SIZE.x * 0.5, ACTION_SIZE.y + 10.0)
	if pos.y < 4.0:
		pos.y = anchor.y + 70.0
	_action.position = pos.clamp(Vector2(4, 4), size - ACTION_SIZE - Vector2(4, 4))


func _forget() -> void:
	_inspected = null
	_action.visible = false


func _apply_pinch() -> void:
	var d := maxf(1.0, (_pinch["at"] as Vector2).distance_to(_press["at"]))
	var factor := d / _pinch_base
	var center: Vector2 = ((_pinch["at"] as Vector2) + (_press["at"] as Vector2)) * 0.5
	match _pinch_target():
		"tree":
			tree_view._zoom_at(tree_view.get_global_transform_with_canvas().affine_inverse() * center, factor)
			_pinch_base = d
		"map":
			_map_steps = log(factor) / log(1.25)
			if absf(_map_steps) >= 1.0:
				world_map.zoom_by(1 if _map_steps > 0.0 else -1)
				_pinch_base = d


## ¿Qué se amplía con dos dedos? "tree", "map" o "".
func _pinch_target() -> String:
	if tree_view and tree_view.is_visible_in_tree():
		return "tree"
	if world_map and world_map.visible:
		return "map"
	return ""


func _in_tree(p: Vector2) -> bool:
	return tree_view != null and tree_view.is_visible_in_tree() and tree_view.get_global_rect().has_point(p)


## Nodo del árbol bajo el dedo (lo que resalta al pasar el «ratón»), o null.
func _tree_target(p: Vector2) -> Variant:
	if not _in_tree(p):
		return null
	var id := int(tree_view.get("_hovered_id"))
	return id if id != -1 else null


func _cell_at(p: Vector2) -> ItemCell:
	for w: Control in windows.call():
		var found := _find_cell(w, p)
		if found:
			return found
	return null


func _find_cell(node: Node, p: Vector2) -> ItemCell:
	for child in node.get_children():
		var c := child as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c is ItemCell and c.get_global_rect().has_point(p):
			return c
		var inner := _find_cell(c, p)
		if inner:
			return inner
	return null


# --- Eventos de ratón simulados ---

func _click(p: Vector2, button: MouseButton) -> void:
	_motion(p, false)
	_send_button(p, button, true)
	_send_button(p, button, false)


func _motion(p: Vector2, held: bool) -> void:
	var ev := InputEventMouseMotion.new()
	_fill(ev, p)
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(ev)


func _send_button(p: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	_fill(ev, p)
	ev.button_mask = (MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
	Input.parse_input_event(ev)


func _fill(ev: InputEventMouse, p: Vector2) -> void:
	ev.device = Touch.POINTER_DEVICE
	var window_pos := get_viewport().get_final_transform() * p   # del lienzo a la ventana
	ev.position = window_pos
	ev.global_position = window_pos
	if ev is InputEventMouseMotion:
		(ev as InputEventMouseMotion).relative = window_pos - _last_window_pos   # para mover la vista del árbol
	_last_window_pos = window_pos
