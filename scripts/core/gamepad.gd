class_name Gamepad
## Soporte básico de mando (Xbox / PlayStation, con la disposición de Godot):
##   stick izquierdo: moverse · stick derecho: apuntar (sin él, se apunta hacia
##   donde mira el personaje) · A/B/X/Y y LB/RB: las 6 habilidades · cruceta y
##   gatillo izquierdo: pociones 1-5 · gatillo derecho: esquiva (git stash) ·
##   Back/Select: inventario · Start: pausa · Share/Captura: hoja de personaje ·
##   clic del stick derecho: árbol pasivo.
## Los eventos se añaden al InputMap al arrancar (no tocan project.godot), así
## que el teclado y el ratón siguen igual.

const AIM_DISTANCE := 320.0
const DEADZONE := 0.3
## A interactúa con lo que haya a esta distancia (objetos, NPC, waypoint, alijo).
const INTERACT_RANGE := 110.0

## true desde que se toca el mando; false al mover el ratón (lo pone GameData).
static var active := false
## true con el cursor de menús en marcha (GamepadCursor): el stick y los botones
## manejan la ventana, no al personaje.
static var menu_cursor := false
## Los clics y movimientos que simula GamepadCursor llevan este dispositivo, para
## que no cuenten como «se usó el ratón».
const CURSOR_DEVICE := 7357
## Si A acaba de usarse para interactuar, la habilidad 1 no sale hasta este instante (ms).
static var _skill_1_blocked_until := 0


static func block_skill_1() -> void:
	_skill_1_blocked_until = Time.get_ticks_msec() + 400


static func skill_1_blocked() -> bool:
	return Time.get_ticks_msec() < _skill_1_blocked_until


static func setup() -> void:
	_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0)
	var skills := [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]
	for k in skills.size():
		_button(StringName("skill_%d" % (k + 1)), skills[k])
	var flasks := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT]
	for k in flasks.size():
		_button(StringName("flask_%d" % (k + 1)), flasks[k])
	_axis(&"flask_5", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_axis(&"dodge", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button(&"toggle_character", JOY_BUTTON_MISC1)
	_button(&"toggle_inventory", JOY_BUTTON_BACK)
	_button(&"toggle_passives", JOY_BUTTON_RIGHT_STICK)
	_button(&"toggle_skills", JOY_BUTTON_LEFT_STICK)
	_button(&"ui_cancel", JOY_BUTTON_START)
	_button(&"respawn", JOY_BUTTON_A)
	# Fijar la comparación de un objeto: F en el teclado (Y con el cursor de mando, GamepadCursor).
	if not InputMap.has_action(&"pin_tooltip"):
		InputMap.add_action(&"pin_tooltip")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_F
		InputMap.action_add_event(&"pin_tooltip", key)


## Hacia dónde se apunta con el mando (en el mundo), desde `from`; `facing` si
## el stick derecho está suelto.
static func aim_point(from: Vector2, facing: Vector2) -> Vector2:
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down") if InputMap.has_action(&"aim_left") \
		else Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	var dir := stick if stick.length() > DEADZONE else facing
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	return from + dir.normalized() * AIM_DISTANCE


## Marca si el último dispositivo usado fue el mando o el ratón.
static func note_event(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == CURSOR_DEVICE:
		return
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > DEADZONE):
		active = true
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		active = false


static func _button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


static func _axis(action: StringName, axis: JoyAxis, direction: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = direction
	InputMap.action_add_event(action, ev)
