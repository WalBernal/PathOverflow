class_name TouchControls
extends Control
## Controles táctiles en partida. El joystick (T107) aparece donde apoyas el dedo en
## la zona izquierda y mueve al personaje (Touch.stick); un anillo marca a quién
## apuntarían las habilidades (Touch.aim_index). Los botones (T108) son los del HUD
## en su forma táctil (Hud.touch_button_at): habilidades en arco, esquiva y pociones.
## Mantener un botón de habilidad es como mantener su tecla (canaliza o repite) y
## arrastrar desde él apunta a mano (Touch.aim_dir). Fuera de todo eso, el toque
## llega al juego como un clic (ir, recoger, hablar). Cada dedo va por su lado.
## Se ve solo con pantalla táctil y si no se apagó en Pausa → Controles.

## Zona donde puede empezar el joystick, en fracción de la pantalla (deja libres el
## registro de arriba a la izquierda y el orbe de vida de abajo).
const ZONE := Rect2(0.0, 0.22, 0.42, 0.56)
const BASE_COLOR := Color(1.0, 1.0, 1.0, 0.10)
const RING_COLOR := Color(1.0, 0.85, 0.45, 0.55)
const KNOB_COLOR := Color(1.0, 0.85, 0.45, 0.75)
const AIM_COLOR := Color(1.0, 0.45, 0.35, 0.85)
const PRESS_COLOR := Color(1.0, 0.9, 0.55, 0.35)

var player: Player
var enemies: EnemyManager
var hud: Hud
## Devuelve true si hay algo encima (ventana, diálogo, pausa, escena): nada empieza.
var blocked: Callable = func() -> bool: return false
## Botón de usar del HUD (T134): World.touch_use(all). Tocar = usar lo de cerca;
## mantener USE_HOLD s = recoger todo lo de alrededor.
var use_action: Callable
const USE_HOLD := 0.45
const USE_COLOR := Color(1.0, 0.85, 0.45, 0.9)

var _finger := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _aim := -1
## Dedos sobre botones: índice del toque -> {kind, index, origin, at}.
var _buttons := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## ¿Empieza aquí el joystick? `p` en coordenadas de este control.
func in_zone(p: Vector2) -> bool:
	var r := Rect2(ZONE.position * size, ZONE.size * size)
	if Touch.left_handed:   # modo zurdo (T136): el joystick, a la derecha
		r.position.x = size.x - r.end.x
	return r.has_point(p)


func _input(event: InputEvent) -> void:
	if not Touch.shown():
		return
	# El toque llega dos veces: como clic del ratón emulado (antes) y como toque.
	# El clic emulado del joystick no debe mover al personaje hacia el dedo (los de
	# los botones ya se los queda el HUD, que tiene ahí sus zonas de ayuda).
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		var on_use: bool = mb != null and mb.pressed and not blocked.call() and _button_at(_local(mb.position)).get("kind", "") == "use"   # (sin zona de ayuda en el HUD)
		if _finger != -1 or on_use or (mb and mb.pressed and in_zone(_local(mb.position)) and _button_at(_local(mb.position)).is_empty() and not blocked.call()):
			get_viewport().set_input_as_handled()
		return
	var st := event as InputEventScreenTouch
	if st:
		var p := _local(st.position)
		if st.pressed:
			if blocked.call():
				return
			var b := _button_at(p)
			if not b.is_empty():
				_press_button(st.index, b, p)
				get_viewport().set_input_as_handled()
			elif _finger == -1 and in_zone(p):
				_finger = st.index
				_origin = p
				_knob = p
				get_viewport().set_input_as_handled()
		elif st.index == _finger:
			release()
			get_viewport().set_input_as_handled()
		elif _buttons.has(st.index):
			_release_button(st.index)
			get_viewport().set_input_as_handled()
		return
	var sd := event as InputEventScreenDrag
	if sd and sd.index == _finger:
		_knob = _local(sd.position)
		Touch.stick = Touch.stick_vector(_origin, _knob)
		get_viewport().set_input_as_handled()
	elif sd and _buttons.has(sd.index):
		var b: Dictionary = _buttons[sd.index]
		b["at"] = _local(sd.position)
		if b["kind"] == "skill":
			Touch.aim_dir = Touch.manual_aim(b["at"] - b["origin"])
		get_viewport().set_input_as_handled()


func _button_at(p: Vector2) -> Dictionary:
	return hud.touch_button_at(hud.get_global_transform_with_canvas().affine_inverse() * (get_global_transform_with_canvas() * p)) if hud else {}


func _press_button(index: int, b: Dictionary, p: Vector2) -> void:
	Haptics.pulse("button")
	if hud:
		hud.set_held(b["kind"], int(b["index"]), true)   # se hunde mientras el dedo esté (T148)
		if b["kind"] == "skill" and player and hud.skills and player.mana < float(hud.skills.profile(int(b["index"])).get("mana_cost", 0.0)):
			hud.deny(int(b["index"]))   # sin maná: tiembla en vez de no hacer nada
	b["origin"] = p
	b["at"] = p
	_buttons[index] = b
	match b["kind"]:
		"skill":
			Input.action_press(SkillController.ACTIONS[int(b["index"])])
		"dodge":
			Input.action_press(&"dodge")
		"flask":
			if player:
				player.use_flask(int(b["index"]))
		"use":
			b["time"] = Time.get_ticks_msec() / 1000.0
			b["done"] = false


func _release_button(index: int) -> void:
	var b: Dictionary = _buttons[index]
	_buttons.erase(index)
	if hud:
		hud.set_held(b["kind"], int(b["index"]), false)
	match b["kind"]:
		"skill":
			Input.action_release(SkillController.ACTIONS[int(b["index"])])
			if not _buttons.values().any(func(o: Dictionary) -> bool: return o["kind"] == "skill"):
				Touch.aim_dir = Vector2.ZERO
		"dodge":
			Input.action_release(&"dodge")
		"use":
			if not b["done"] and use_action.is_valid():
				use_action.call(false)


## Suelta el joystick y los botones (al levantar el dedo o si una ventana se abre encima).
func release() -> void:
	_finger = -1
	Touch.stick = Vector2.ZERO
	queue_redraw()


func release_all() -> void:
	release()
	for index in _buttons.keys():
		_buttons[index]["done"] = true   # soltar por una ventana no usa nada
		_release_button(index)
	Touch.aim_dir = Vector2.ZERO


func _process(_delta: float) -> void:
	visible = Touch.shown()
	if not visible:
		if _finger != -1 or not _buttons.is_empty():
			release_all()
		return
	if (_finger != -1 or not _buttons.is_empty()) and blocked.call():
		release_all()
	for b in _buttons.values():
		if b["kind"] == "use" and not b["done"] and Time.get_ticks_msec() / 1000.0 - float(b["time"]) >= USE_HOLD:
			b["done"] = true
			if use_action.is_valid():
				use_action.call(true)
	if hud and not hud.use_now.is_empty():
		queue_redraw()   # el contorno de lo que se va a usar
	var aim := -1
	if Touch.active and player and enemies and Touch.aim_dir == Vector2.ZERO:
		aim = Touch.aim_index(enemies.positions, player.global_position, Touch.stick)
	if aim != -1 or _aim != -1 or _finger != -1 or not _buttons.is_empty():
		queue_redraw()
	_aim = aim


func _draw() -> void:
	if _finger != -1:
		draw_circle(_origin, Touch.STICK_RADIUS, BASE_COLOR)
		draw_arc(_origin, Touch.STICK_RADIUS, 0.0, TAU, 48, RING_COLOR, 2.0, true)
		var knob := _origin + (_knob - _origin).limit_length(Touch.STICK_RADIUS)
		draw_circle(knob, 26.0, KNOB_COLOR)
	for b in _buttons.values():
		draw_circle(b["origin"], 30.0, PRESS_COLOR)   # el botón pulsado se ilumina
	if hud and not hud.use_now.is_empty():
		# Lo que usaría el botón (T134): cuatro esquinas doradas a su alrededor.
		var p := _world_to_local(hud.use_now["pos"])
		var half := Vector2(34.0, 24.0) + Vector2.ONE * 2.0 * sin(Time.get_ticks_msec() / 200.0)
		for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var corner := p + half * s
			draw_line(corner, corner - Vector2(12.0 * s.x, 0), USE_COLOR, 3.0)
			draw_line(corner, corner - Vector2(0, 12.0 * s.y), USE_COLOR, 3.0)
	if _aim != -1 and _aim < enemies.positions.size():
		var p := _world_to_local(enemies.positions[_aim])
		var r := 20.0 + 3.0 * sin(Time.get_ticks_msec() / 160.0)
		for k in 4:   # cuatro esquinas de mira
			var a := k * TAU / 4.0 + PI / 4.0
			draw_arc(p, r, a - 0.45, a + 0.45, 8, AIM_COLOR, 2.5, true)
	if Touch.aim_dir != Vector2.ZERO and player:
		# Apuntado a mano: línea discontinua del jugador al punto y un círculo al final.
		var from := _world_to_local(player.global_position)
		var to := _world_to_local(Touch.manual_target(player.global_position, Touch.aim_dir))
		draw_dashed_line(from, to, AIM_COLOR, 2.5, 10.0)
		draw_arc(to, 16.0, 0.0, TAU, 24, AIM_COLOR, 2.5, true)


func _world_to_local(p: Vector2) -> Vector2:
	return _local(get_viewport().get_canvas_transform() * p)


## De la pantalla a este control (la interfaz puede ir escalada).
func _local(screen: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen
