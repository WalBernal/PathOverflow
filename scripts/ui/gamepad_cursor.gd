class_name GamepadCursor
extends Control
## Cursor libre de mando para las ventanas (inventario, habilidades K, hoja de
## personaje, tienda y alijo): con alguna abierta y el mando en uso, el stick
## izquierdo mueve una flecha y los botones hacen de ratón.
##   A: clic izquierdo (mantener y mover = arrastrar) · X: clic derecho ·
##   cruceta: salta a la casilla o botón más cercano en esa dirección ·
##   LB/RB: a la ventana anterior/siguiente · B: cerrar (como Esc) ·
##   Y: fijar la comparación del objeto (como F) · stick derecho: rueda (zoom del árbol).
## También en el árbol pasivo (la cruceta salta entre nodos), los diálogos y la
## elección de habilidad.
## Los clics se simulan como eventos de ratón con el dispositivo
## Gamepad.CURSOR_DEVICE, así que los paneles no necesitan saber nada del mando.
## Va directamente en la CanvasLayer de GameUI (sin la escala de _root): sus
## coordenadas son las del lienzo.

const SPEED := 900.0
const SIZE := 18.0

## -> Array de las ventanas abiertas que maneja (Control).
var windows: Callable = func() -> Array: return []
## Lo que hace B (cerrar, como Esc).
var cancel: Callable = func() -> void: pass
## Lo que hace Y (fijar la comparación del objeto, como F).
var pin: Callable = func() -> void: pass

var engaged := false
var cursor_pos := Vector2(-1, -1)
var _left_held := false
var _window_index := 0
var _last_windows: Array = []
var _wheel_wait := 0.0
const WHEEL_REPEAT := 0.12


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _exit_tree() -> void:
	Gamepad.menu_cursor = false


func _process(delta: float) -> void:
	var open: Array = windows.call()
	var now := Gamepad.active and not open.is_empty()
	if now != engaged:
		engaged = now
		Gamepad.menu_cursor = now
		if not now and _left_held:
			_send_button(MOUSE_BUTTON_LEFT, false)
		queue_redraw()
	if not engaged:
		_last_windows = []
		return
	for w in open:   # se abrió otra ventana: el cursor va a ella
		if not _last_windows.has(w):
			_jump_to_window(open, open.find(w))
			break
	_last_windows = open
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if stick.length() > Gamepad.DEADZONE:
		move_cursor(cursor_pos + stick * stick.length() * SPEED * delta)
	# Stick derecho arriba/abajo: la rueda (zoom del árbol, listas largas).
	_wheel_wait = maxf(0.0, _wheel_wait - delta)
	var wheel := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(wheel) > 0.5 and _wheel_wait <= 0.0:
		_wheel_wait = WHEEL_REPEAT
		_send_button(MOUSE_BUTTON_WHEEL_UP if wheel < 0.0 else MOUSE_BUTTON_WHEEL_DOWN, true)
		_send_button(MOUSE_BUTTON_WHEEL_UP if wheel < 0.0 else MOUSE_BUTTON_WHEEL_DOWN, false)


func _input(event: InputEvent) -> void:
	var jb := event as InputEventJoypadButton
	if not engaged or jb == null:
		return
	match jb.button_index:
		JOY_BUTTON_A:
			_send_button(MOUSE_BUTTON_LEFT, jb.pressed)
		JOY_BUTTON_X:
			if jb.pressed:
				_send_button(MOUSE_BUTTON_RIGHT, true)
				_send_button(MOUSE_BUTTON_RIGHT, false)
		JOY_BUTTON_B:
			if jb.pressed:
				cancel.call()
		JOY_BUTTON_Y:
			if jb.pressed:
				pin.call()
		JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
			if jb.pressed:
				snap({JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN,
					JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT}[jb.button_index])
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			if jb.pressed:
				_jump_to_window(windows.call(), _window_index + (1 if jb.button_index == JOY_BUTTON_RIGHT_SHOULDER else -1))
		_:
			return   # Back, Start y los clics de stick siguen abriendo y cerrando ventanas
	get_viewport().set_input_as_handled()


func move_cursor(p: Vector2) -> void:
	var r := get_viewport_rect()
	var to := p.clamp(r.position, r.end - Vector2.ONE)
	if to == cursor_pos:
		return
	var ev := InputEventMouseMotion.new()
	ev.relative = to - cursor_pos
	cursor_pos = to
	_fill(ev)
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if _left_held else 0
	Input.parse_input_event(ev)
	queue_redraw()


## Cruceta: a la casilla o botón más cercano en esa dirección.
func snap(dir: Vector2) -> void:
	var rects: Array[Rect2] = []
	for w: Control in windows.call():
		_collect_targets(w, rects)
	var i := pick_target(cursor_pos, dir, rects)
	if i != -1:
		move_cursor(rects[i].get_center())


## El mejor destino desde `from` hacia `dir` entre los centros de `rects`: el
## más cercano dentro de un cono de ±60°, castigando lo que se aparta del eje.
## -1 si no hay ninguno.
static func pick_target(from: Vector2, dir: Vector2, rects: Array[Rect2]) -> int:
	var best := -1
	var best_score := INF
	for i in rects.size():
		var d := rects[i].get_center() - from
		var along := d.dot(dir)
		if along <= 4.0 or along < d.length() * 0.5:
			continue
		var score := along + absf(d.cross(dir)) * 2.0
		if score < best_score:
			best_score = score
			best = i
	return best


func _collect_targets(node: Node, out: Array[Rect2]) -> void:
	for child in node.get_children():
		var c := child as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c is ItemCell or (c is BaseButton and not (c as BaseButton).disabled):
			out.append(c.get_global_rect())
		elif c.has_method(&"cursor_targets"):   # dibujos con sitios propios (nodos del árbol)
			out.append_array(c.call(&"cursor_targets"))
			_collect_targets(c, out)
		else:
			_collect_targets(c, out)


func _jump_to_window(open: Array, index: int) -> void:
	if open.is_empty():
		return
	_window_index = posmod(index, open.size())
	var rects: Array[Rect2] = []
	var w: Control = open[_window_index]
	_collect_targets(w, rects)
	move_cursor(rects[0].get_center() if not rects.is_empty() else w.get_global_rect().get_center())


func _send_button(button: MouseButton, pressed: bool) -> void:
	if button == MOUSE_BUTTON_LEFT:
		if _left_held == pressed:
			return
		_left_held = pressed
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	_fill(ev)
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if _left_held else 0
	Input.parse_input_event(ev)


func _fill(ev: InputEventMouse) -> void:
	ev.device = Gamepad.CURSOR_DEVICE
	var window_pos := get_viewport().get_final_transform() * cursor_pos   # del lienzo a la ventana
	ev.position = window_pos
	ev.global_position = window_pos


func _draw() -> void:
	if not engaged:
		return
	var p := cursor_pos
	var arrow := PackedVector2Array([p, p + Vector2(0, SIZE), p + Vector2(SIZE * 0.3, SIZE * 0.72), p + Vector2(SIZE * 0.72, SIZE * 0.72)])
	draw_colored_polygon(arrow, Color("f4f0e8") if not _left_held else UiStyle.ACCENT)
	arrow.append(p)
	draw_polyline(arrow, UiStyle.PANEL, 2.0)
