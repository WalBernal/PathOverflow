class_name TouchControls
extends Control
## Controles táctiles en partida (T107): el joystick aparece donde apoyas el dedo en
## la zona izquierda de la pantalla y mueve al personaje (Touch.stick); un anillo
## marca a quién apuntarían las habilidades (Touch.aim_index). Fuera de la zona del
## joystick, el toque llega al juego como un clic (ir, recoger, hablar).
## Se ve solo con pantalla táctil y si no se apagó en Pausa → Controles.

## Zona donde puede empezar el joystick, en fracción de la pantalla (deja libres el
## registro de arriba a la izquierda y el orbe de vida de abajo).
const ZONE := Rect2(0.0, 0.22, 0.42, 0.56)
const BASE_COLOR := Color(1.0, 1.0, 1.0, 0.10)
const RING_COLOR := Color(1.0, 0.85, 0.45, 0.55)
const KNOB_COLOR := Color(1.0, 0.85, 0.45, 0.75)
const AIM_COLOR := Color(1.0, 0.45, 0.35, 0.85)

var player: Player
var enemies: EnemyManager
## Devuelve true si hay algo encima (ventana, diálogo, pausa, escena): el joystick no empieza.
var blocked: Callable = func() -> bool: return false

var _finger := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _aim := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## ¿Empieza aquí el joystick? `p` en coordenadas de este control.
func in_zone(p: Vector2) -> bool:
	var r := Rect2(ZONE.position * size, ZONE.size * size)
	return r.has_point(p)


func _input(event: InputEvent) -> void:
	if not Touch.shown():
		return
	# El toque llega dos veces: como clic del ratón emulado (antes) y como toque.
	# El clic emulado del joystick no debe mover al personaje hacia el dedo.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if _finger != -1 or (mb and mb.pressed and in_zone(_local(mb.position)) and not blocked.call()):
			get_viewport().set_input_as_handled()
		return
	var st := event as InputEventScreenTouch
	if st:
		var p := _local(st.position)
		if st.pressed and _finger == -1 and in_zone(p) and not blocked.call():
			_finger = st.index
			_origin = p
			_knob = p
			get_viewport().set_input_as_handled()
		elif not st.pressed and st.index == _finger:
			release()
			get_viewport().set_input_as_handled()
		return
	var sd := event as InputEventScreenDrag
	if sd and sd.index == _finger:
		_knob = _local(sd.position)
		Touch.stick = Touch.stick_vector(_origin, _knob)
		get_viewport().set_input_as_handled()


## Suelta el joystick (al levantar el dedo o si una ventana se abre encima).
func release() -> void:
	_finger = -1
	Touch.stick = Vector2.ZERO
	queue_redraw()


func _process(_delta: float) -> void:
	visible = Touch.shown()
	if not visible:
		if _finger != -1:
			release()
		return
	if _finger != -1 and blocked.call():
		release()
	var aim := -1
	if Touch.active and player and enemies:
		aim = Touch.aim_index(enemies.positions, player.global_position, Touch.stick)
	if aim != -1 or _aim != -1 or _finger != -1:
		queue_redraw()
	_aim = aim


func _draw() -> void:
	if _finger != -1:
		draw_circle(_origin, Touch.STICK_RADIUS, BASE_COLOR)
		draw_arc(_origin, Touch.STICK_RADIUS, 0.0, TAU, 48, RING_COLOR, 2.0, true)
		var knob := _origin + (_knob - _origin).limit_length(Touch.STICK_RADIUS)
		draw_circle(knob, 26.0, KNOB_COLOR)
	if _aim != -1 and _aim < enemies.positions.size():
		var p := _local(get_viewport().get_canvas_transform() * enemies.positions[_aim])
		var r := 20.0 + 3.0 * sin(Time.get_ticks_msec() / 160.0)
		for k in 4:   # cuatro esquinas de mira
			var a := k * TAU / 4.0 + PI / 4.0
			draw_arc(p, r, a - 0.45, a + 0.45, 8, AIM_COLOR, 2.5, true)


## De la pantalla a este control (la interfaz puede ir escalada).
func _local(screen: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen
