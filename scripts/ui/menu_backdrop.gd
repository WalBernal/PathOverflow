class_name MenuBackdrop
extends Control
## Fondo vivo de los menús (T184): paquetes de datos que viajan por la rejilla de puntos
## de `UiStyle.draw_background` (giran en los cruces, con una estela corta) y algún nodo
## que se enciende y se apaga. La rejilla la sigue pintando el menú, que solo la redibuja
## al cambiar de tamaño; aquí se dibujan cada fotograma unos pocos rectángulos.
## Con «reducir movimiento» no se mueve nada.

const GRID := 24.0
const TRAIL := 5
const TURN_CHANCE := 0.22
const PULSE_TIME := 1.6

var _rng := RandomNumberGenerator.new()
var _packets: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _pulse_wait := 0.6


## Cuántos paquetes caben: más en pantallas grandes, sin pasarse en el celular.
static func packet_count(view: Vector2) -> int:
	return clampi(int(view.x * view.y / 60000.0), 8, 28)


## El cruce de la rejilla más cercano a `p`.
static func snap(p: Vector2) -> Vector2:
	return (p / GRID).round() * GRID


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	set_process(not Accessibility.reduce_motion)


func _new_packet(view: Vector2) -> Dictionary:
	var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	return {"pos": snap(Vector2(_rng.randf() * view.x, _rng.randf() * view.y)), "dir": dirs[_rng.randi_range(0, 3)],
		"speed": _rng.randf_range(40.0, 95.0), "run": 0.0, "life": _rng.randf_range(3.0, 7.0), "age": 0.0,
		"trail": [], "warm": _rng.randf() < 0.18}


func _process(delta: float) -> void:
	var view := size
	if view.x < GRID or view.y < GRID:
		return
	while _packets.size() < packet_count(view):
		_packets.append(_new_packet(view))
	if _packets.size() > packet_count(view):
		_packets.resize(packet_count(view))
	for i in _packets.size():
		var p: Dictionary = _packets[i]
		p["age"] += delta
		var step: float = p["speed"] * delta
		p["pos"] += p["dir"] * step
		p["run"] += step
		if p["run"] >= GRID:   # en un cruce: se asienta en él y a veces gira
			p["run"] = 0.0
			p["pos"] = snap(p["pos"])
			var trail: Array = p["trail"]
			trail.push_front(p["pos"])
			if trail.size() > TRAIL:
				trail.pop_back()
			if _rng.randf() < TURN_CHANCE:
				p["dir"] = Vector2(p["dir"].y, p["dir"].x) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var out: bool = p["pos"].x < -GRID or p["pos"].y < -GRID or p["pos"].x > view.x + GRID or p["pos"].y > view.y + GRID
		if out or p["age"] > p["life"]:
			if p["age"] > p["life"] and not out:
				_pulses.append({"pos": snap(p["pos"]), "t": 0.0})   # llega a su nodo y lo enciende
			_packets[i] = _new_packet(view)
	_pulse_wait -= delta
	if _pulse_wait <= 0.0:
		_pulse_wait = _rng.randf_range(0.5, 1.4)
		_pulses.append({"pos": snap(Vector2(_rng.randf() * view.x, _rng.randf() * view.y)), "t": 0.0})
	for q in _pulses:
		q["t"] += delta
	_pulses = _pulses.filter(func(q: Dictionary) -> bool: return q["t"] < PULSE_TIME)
	queue_redraw()


## Intensidad de un paquete según su edad: entra y sale con un fundido corto.
static func fade(age: float, life: float) -> float:
	return clampf(minf(age / 0.4, (life - age) / 0.4), 0.0, 1.0)


func _draw() -> void:
	for q in _pulses:
		var k: float = q["t"] / PULSE_TIME
		var r := 2.0 + 7.0 * k
		draw_rect(Rect2(q["pos"] - Vector2(r, r), Vector2(r, r) * 2.0), Color(UiStyle.ACCENT, 0.22 * (1.0 - k)), false, 1.0)
		draw_rect(Rect2(q["pos"] - Vector2(1.5, 1.5), Vector2(3, 3)), Color(UiStyle.ACCENT, 0.5 * (1.0 - k)))
	for p in _packets:
		var a := fade(p["age"], p["life"])
		if a <= 0.0:
			continue
		var tint: Color = UiStyle.WARN if p["warm"] else UiStyle.ACCENT
		var trail: Array = p["trail"]
		var prev: Vector2 = p["pos"]
		for k in trail.size():
			var at: Vector2 = trail[k]
			if prev.distance_to(at) <= GRID * 1.5:   # sin rayas que crucen la pantalla al reaparecer
				draw_line(prev, at, Color(tint, 0.16 * a * (1.0 - float(k) / TRAIL)), 1.0)
			prev = at
		draw_rect(Rect2(p["pos"] - Vector2(1.5, 1.5), Vector2(3, 3)), Color(tint, 0.6 * a))
