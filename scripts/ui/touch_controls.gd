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
## Joystick fijo: distancia de su base al borde de la pantalla.
const FIXED_INSET := 150.0

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


## Joystick fijo (T149): su base, justo encima del orbe de vida (que el HUD pone en
## espejo en zurdo); sin HUD (el prólogo), abajo en la zona del joystick.
func fixed_base() -> Vector2:
	if hud:
		var life: Vector2 = hud.call("_life_center")
		var p := hud.get_global_transform_with_canvas() * (life - Vector2(0.0, Hud.ORB_RADIUS + 16.0 + Touch.STICK_RADIUS))
		return get_global_transform_with_canvas().affine_inverse() * p
	var r := Rect2(ZONE.position * size, ZONE.size * size)
	var x := r.position.x + FIXED_INSET
	return Vector2(size.x - x if Touch.left_handed else x, r.end.y - Touch.STICK_RADIUS - 10.0)


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
				# Fijo (T149): la base no se mueve; el dedo ya inclina desde donde cae.
				_origin = fixed_base() if Touch.stick_mode == "fijo" else p
				_knob = p
				Touch.stick = Touch.stick_vector(_origin, _knob, Touch.STICK_RADIUS, Touch.deadzone())
				get_viewport().set_input_as_handled()
			elif enemies and player:
				# Tocar un enemigo lo fija como objetivo (T150); el toque sigue siendo un clic.
				Touch.lock_at(enemies.ids, enemies.positions, player.get_canvas_transform().affine_inverse() * st.position)
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
		if Touch.stick_mode == "sigue":   # la base va detrás del dedo (T149)
			_origin = Touch.follow_origin(_origin, _knob)
		Touch.stick = Touch.stick_vector(_origin, _knob, Touch.STICK_RADIUS, Touch.deadzone())
		get_viewport().set_input_as_handled()
	elif sd and _buttons.has(sd.index):
		var b: Dictionary = _buttons[sd.index]
		b["at"] = _local(sd.position)
		if b["kind"] == "skill" and not b.get("cancelled", false):
			Touch.aim_dir = Touch.manual_aim(b["at"] - b["origin"])
			Touch.aim_skill = int(b["index"])
			if Touch.aim_dir != Vector2.ZERO:
				b["aimed"] = true
			elif b.get("aimed", false):
				# Volvió al botón tras apuntar (T150): se cancela; deja de lanzar hasta soltar.
				b["cancelled"] = true
				Input.action_release(SkillController.ACTIONS[int(b["index"])])
				Touch.aim_skill = -1
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
				Touch.aim_skill = -1
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
		aim = Touch.pick_target(enemies.ids, enemies.positions, player.global_position, Touch.stick)   # pegajoso (T150)
	if aim != -1 or _aim != -1 or _finger != -1 or not _buttons.is_empty() or Touch.stick_mode == "fijo":
		queue_redraw()
	_aim = aim


func _draw() -> void:
	if _finger == -1 and Touch.stick_mode == "fijo" and not blocked.call():
		# Fijo (T149): la base siempre a la vista, tenue, para saber dónde poner el pulgar.
		var base := fixed_base()
		draw_circle(base, Touch.STICK_RADIUS, Color(BASE_COLOR, BASE_COLOR.a * 0.7))
		draw_arc(base, Touch.STICK_RADIUS, 0.0, TAU, 48, Color(RING_COLOR, 0.3), 2.0, true)
		draw_circle(base, 26.0, Color(KNOB_COLOR, 0.25))
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
		_draw_target(_aim)
	if Touch.aim_dir != Vector2.ZERO and player:
		_draw_aim_preview()


## Mira del objetivo (T150): esquinas del color de su rareza, más grandes en los fuertes,
## su barra de vida encima y un candado si se fijó tocándolo.
func _draw_target(i: int) -> void:
	var p := _world_to_local(enemies.positions[i])
	var k := _world_scale()
	var color := Rarity.enemy_color(enemies.rarities[i]).lerp(AIM_COLOR, 0.35)
	var r := (maxf(20.0, float(enemies.radii[i]) * k + 10.0)) + 3.0 * sin(Time.get_ticks_msec() / 160.0)
	for q in 4:   # cuatro esquinas de mira
		var a := q * TAU / 4.0 + PI / 4.0
		draw_arc(p, r, a - 0.45, a + 0.45, 8, Color.BLACK, 5.0, true)
		draw_arc(p, r, a - 0.45, a + 0.45, 8, color, 2.5, true)
	var frac := clampf(enemies.lives[i] / maxf(1.0, enemies.max_lives[i]), 0.0, 1.0)
	var bar := Rect2(p + Vector2(-26.0, -r - 14.0), Vector2(52.0, 6.0))
	draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color("e04040"))
	if Touch.target_fixed:
		var lock := bar.position + Vector2(-12.0, 3.0)
		draw_rect(Rect2(lock + Vector2(-4, -1), Vector2(8, 6)), color)
		draw_arc(lock + Vector2(0, -2), 3.0, PI, TAU, 8, color, 1.5)


## Apuntando a mano desde un botón (T150): hasta dónde llega y lo que abarcaría la
## habilidad (círculo, cono, franja o abanico de proyectiles); arrastrar de vuelta al
## botón lo cancela.
func _draw_aim_preview() -> void:
	var origin_w := player.global_position
	var target_w := Touch.manual_target(origin_w, Touch.aim_dir)
	var from := _world_to_local(origin_w)
	var to := _world_to_local(target_w)
	var k := _world_scale()
	draw_arc(from, Touch.AIM_RANGE * k, 0.0, TAU, 64, Color(AIM_COLOR, 0.18), 1.5, true)   # alcance
	draw_dashed_line(from, to, AIM_COLOR, 2.5, 10.0)
	var p: Dictionary = hud.skills.profile(Touch.aim_skill) if hud and hud.skills and Touch.aim_skill >= 0 else {}
	var dir := (to - from).normalized()
	var fill := Color(AIM_COLOR, 0.16)
	var line := Color(AIM_COLOR, 0.8)
	if float(p.get("angle", 0.0)) > 0.0:   # cono
		var reach := maxf(float(p.get("range", 0.0)), maxf(float(p.get("radius", 0.0)), 160.0)) * k
		var half := deg_to_rad(float(p["angle"])) / 2.0
		var pts := PackedVector2Array([from])
		for s in 13:
			pts.append(from + dir.rotated(-half + 2.0 * half * s / 12.0) * reach)
		draw_colored_polygon(pts, fill)
		pts.append(from)
		draw_polyline(pts, line, 2.0, true)
	elif float(p.get("width", 0.0)) > 0.0:   # franja (rayo, embestida)
		var side := dir.orthogonal() * float(p["width"]) * k / 2.0
		var pts := PackedVector2Array([from + side, to + side, to - side, from - side])
		draw_colored_polygon(pts, fill)
		pts.append(from + side)
		draw_polyline(pts, line, 2.0, true)
	elif int(p.get("projectiles", 0)) > 1:   # abanico de proyectiles
		var n := int(p["projectiles"])
		var spread := deg_to_rad(float(p.get("spread_degrees", 12.0)))
		for s in n:
			var a := -spread / 2.0 + spread * s / maxf(1.0, n - 1)
			draw_dashed_line(from, from + dir.rotated(a) * from.distance_to(to), line, 2.0, 8.0)
	if float(p.get("radius", 0.0)) > 0.0 and float(p.get("angle", 0.0)) <= 0.0:   # área en el punto
		var rad := float(p["radius"]) * k
		draw_circle(to, rad, fill)
		draw_arc(to, rad, 0.0, TAU, 40, line, 2.0, true)
	else:
		draw_arc(to, 16.0, 0.0, TAU, 24, AIM_COLOR, 2.5, true)


## Píxeles de este control por unidad del mundo (cámara e interfaz).
func _world_scale() -> float:
	return (_world_to_local(Vector2(100, 0)) - _world_to_local(Vector2.ZERO)).length() / 100.0


func _world_to_local(p: Vector2) -> Vector2:
	return _local(get_viewport().get_canvas_transform() * p)


## De la pantalla a este control (la interfaz puede ir escalada).
func _local(screen: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen
