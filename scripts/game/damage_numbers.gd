class_name DamageNumbers
extends Node2D
## Números de daño (T97): cada golpe a un enemigo saca su cifra, que salta y se encoge
## (los críticos, más grandes y amarillos). Los golpes seguidos al mismo enemigo se
## apilan en una sola cifra que crece. Con «reducir movimiento», suben despacio sin saltar.
## Lee los golpes de EnemyManager.number_events cada fotograma.

const LIFETIME := 0.9
const STACK_WINDOW := 0.35
## En el celular (T152) los golpes seguidos se suman durante más tiempo: menos cifras y
## más grandes, que se leen en una pantalla chica.
const STACK_WINDOW_TOUCH := 0.7
const TOUCH_SIZE := 1.35
const MAX_NUMBERS := 60
## Pausa → Interfaz (T152): «todos», «criticos» (solo los críticos) o «no». Lo guardado
## antes como sí/no vale igual.
const MODES := ["todos", "criticos", "no"]
static var mode := _load_mode()
static var enabled := mode != "no"

var enemies: EnemyManager
var _numbers: Array[Dictionary] = []
var _time := 0.0


static func _load_mode() -> String:
	var v: Variant = GameSettings.get_value("interface", "damage_numbers", "todos")
	if v is bool:
		return "todos" if v else "no"
	return String(v) if MODES.has(String(v)) else "todos"


static func set_mode(value: String) -> void:
	mode = value if MODES.has(value) else "todos"
	enabled = mode != "no"
	GameSettings.set_value("interface", "damage_numbers", mode)


static func set_enabled(on: bool) -> void:
	set_mode("todos" if on else "no")


## Añade un golpe: si el mismo enemigo recibió otro hace menos de `window`, se suma
## a esa cifra (y vuelve a saltar); si no, cifra nueva.
static func merge(numbers: Array, id: int, pos: Vector2, amount: float, crit: bool, now: float, window := STACK_WINDOW) -> void:
	for n in numbers:
		if n["id"] == id and now - float(n["last"]) <= window:
			n["amount"] = float(n["amount"]) + amount
			n["crit"] = n["crit"] or crit
			n["stack"] = int(n["stack"]) + 1
			n["last"] = now
			n["t0"] = now   # vuelve a saltar
			n["pos"] = pos
			return
	numbers.append({"id": id, "pos": pos, "amount": amount, "crit": crit, "stack": 1, "t0": now, "last": now, "born": now})
	if numbers.size() > MAX_NUMBERS:
		numbers.remove_at(0)


## Escala de la cifra con `age` segundos: salta grande y se asienta en 0,15 s. Los
## críticos y los montones de golpes, más grandes. Sin movimiento: tamaño fijo.
static func scale_at(age: float, crit: bool, stack: int, still := false) -> float:
	var settle := (1.35 if crit else 1.0) * (1.0 + minf(0.4, (stack - 1) * 0.06))
	if still:
		return settle
	var pop := clampf(1.0 - age / 0.15, 0.0, 1.0)
	return settle * (1.0 + (1.0 if crit else 0.6) * pop * pop)   # el crítico salta más (T152)


## Desplazamiento: un saltito hacia arriba y a un lado que cae un poco; sin
## movimiento, solo sube despacio.
static func offset_at(age: float, side: float, still := false) -> Vector2:
	if still:
		return Vector2(0, -18.0 * age)
	return Vector2(side * 22.0 * age, -70.0 * age + 60.0 * age * age)


static func alpha_at(age: float) -> float:
	return clampf((LIFETIME - age) / 0.3, 0.0, 1.0)


static func label(amount: float) -> String:
	return "%.1fk" % (amount / 1000.0) if amount >= 10000.0 else str(maxi(1, roundi(amount)))


func _process(delta: float) -> void:
	_time += delta
	if enemies != null and not enemies.number_events.is_empty():
		if enabled:
			var window := STACK_WINDOW_TOUCH if Touch.shown() else STACK_WINDOW
			for e in enemies.number_events:
				if mode == "criticos" and not e[2]:
					continue
				merge(_numbers, e[3], e[0], e[1], e[2], _time, window)
		enemies.number_events.clear()
	_numbers = _numbers.filter(func(n: Dictionary) -> bool: return _time - float(n["t0"]) <= LIFETIME)
	if not _numbers.is_empty() or visible:
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var still := Accessibility.reduce_motion
	for n in _numbers:
		var age := _time - float(n["t0"])
		var side := 1.0 if int(n["id"]) % 2 == 0 else -1.0
		var s := scale_at(age, n["crit"], n["stack"], still)
		var size := Accessibility.world_size(roundi(15.0 * s * (TOUCH_SIZE if Touch.shown() else 1.0)))
		var p: Vector2 = n["pos"] + Vector2(0, -34) + offset_at(_time - float(n["born"]), side, still)
		var text := label(n["amount"]) + ("!" if n["crit"] else "")
		var color := Color("ffd84a") if n["crit"] else Color("f2ece0")
		color.a = alpha_at(age)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(font, p - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, color.a * 0.9))
		draw_string(font, p - Vector2(w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
