class_name Touch
## Controles táctiles (T107): joystick virtual a la izquierda (TouchControls) y
## apuntado automático. Tocar el mundo fuera de los controles hace lo mismo que el
## clic (Godot convierte el toque en un clic del ratón), así que ir, recoger botín
## y hablar con un NPC no necesitan nada nuevo.

## Radio del joystick (px de interfaz) y zona muerta (fracción del radio).
const STICK_RADIUS := 70.0
const STICK_DEADZONE := 0.18
## El apuntado automático busca enemigos a esta distancia y, con el joystick
## inclinado, prefiere los que caen en este cono alrededor de esa dirección.
const AIM_RANGE := 520.0
const AIM_CONE := deg_to_rad(40.0)

## Dispositivo de los clics que simula TouchPointer en las ventanas (T109): no
## cuentan como «se usó el ratón».
const POINTER_DEVICE := 7358

## true desde el último toque; false al usar el ratón de verdad o el mando.
static var active := false
## Dirección del joystick (largo 0-1); cero con el dedo fuera.
static var stick := Vector2.ZERO
## Apuntado a mano (T108): arrastrando el dedo desde un botón de habilidad, hacia
## dónde (largo 0-1); cero = apuntado automático.
static var aim_dir := Vector2.ZERO
## Cuánto hay que arrastrar desde el botón para apuntar a mano, y hasta dónde llega.
const MANUAL_AIM_MIN := 26.0
const MANUAL_AIM_FULL := 150.0
## Para las pruebas y las capturas: como si hubiera pantalla táctil.
static var force := false


## ¿Se muestran los controles táctiles? Con pantalla táctil y sin apagarlos en Pausa → Controles.
static func shown() -> bool:
	return (force or DisplayServer.is_touchscreen_available()) and enabled()


static func enabled() -> bool:
	return bool(GameSettings.get_value("controls", "touch", true))


static func set_enabled(on: bool) -> void:
	GameSettings.set_value("controls", "touch", on)
	if not on:
		stick = Vector2.ZERO
		aim_dir = Vector2.ZERO


## Último toque, en coordenadas de la ventana del juego (INF sin toques).
static var last_screen := Vector2.INF


## Dónde está el dedo en el mundo de `item`, o el ratón sin toques. El ratón que
## Godot emula desde el toque no siempre mueve el cursor del sistema, que es lo que
## lee get_global_mouse_position, así que tocar el mundo usa el último toque.
static func pointer(item: CanvasItem) -> Vector2:
	if active and last_screen != Vector2.INF:
		return item.get_canvas_transform().affine_inverse() * last_screen
	return item.get_global_mouse_position()


static func note_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		active = true
		last_screen = event.position
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		# El clic que Godot emula de un toque llega antes que el toque (T134): sin
		# esto, tocar el mundo iba al punto del toque anterior.
		last_screen = event.position
	elif (event is InputEventMouseMotion or event is InputEventMouseButton) and not event.device in [InputEvent.DEVICE_ID_EMULATION, POINTER_DEVICE, Gamepad.CURSOR_DEVICE]:
		active = false
	elif event is InputEventJoypadButton:
		active = false


## Dirección del joystick con el dedo en `finger` y el centro en `origin`: la zona
## muerta da cero, y de ahí al borde crece hasta 1 (más allá del radio, 1).
static func stick_vector(origin: Vector2, finger: Vector2, radius := STICK_RADIUS, deadzone := STICK_DEADZONE) -> Vector2:
	var d := finger - origin
	var t := d.length() / radius
	if t <= deadzone:
		return Vector2.ZERO
	return d.normalized() * minf(1.0, (t - deadzone) / (1.0 - deadzone))


## Apuntado a mano al arrastrar `drag` px desde el botón: cero si apenas se movió.
static func manual_aim(drag: Vector2) -> Vector2:
	if drag.length() < MANUAL_AIM_MIN:
		return Vector2.ZERO
	return drag.normalized() * minf(1.0, drag.length() / MANUAL_AIM_FULL)


## Punto del mundo al que apunta el arrastre: de 120 px (poco) al alcance entero (a tope).
static func manual_target(from: Vector2, dir: Vector2) -> Vector2:
	return from + dir.normalized() * lerpf(120.0, AIM_RANGE, clampf(dir.length(), 0.0, 1.0))


## Enemigo al que apuntan las habilidades: el más cercano dentro del cono de `dir`
## (el joystick); si no hay ninguno ahí o el joystick está suelto, el más cercano. -1 si nadie a tiro.
static func aim_index(positions: PackedVector2Array, from: Vector2, dir: Vector2, max_range := AIM_RANGE) -> int:
	var best := -1
	var best_d := INF
	var best_cone := -1
	var best_cone_d := INF
	var use_cone := dir.length() > 0.01
	for i in positions.size():
		var to := positions[i] - from
		var d := to.length()
		if d > max_range:
			continue
		if d < best_d:
			best_d = d
			best = i
		if use_cone and d < best_cone_d and (d < 1.0 or absf(dir.angle_to(to)) <= AIM_CONE):
			best_cone_d = d
			best_cone = i
	return best_cone if best_cone != -1 else best
