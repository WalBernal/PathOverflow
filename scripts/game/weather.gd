class_name Weather
extends Node2D
## Clima y ambiente de cada zona, dibujado sobre lo que se ve (no se guarda). Capas:
## - "data_rain": lluvia de datos, trazos verdes que caen con un bit en la punta y
##   salpican al llegar al suelo (la terminal, el kernel, los servidores).
## - "fog": niebla que deriva despacio (el pantano, las alcantarillas, la fosa).
## - "dust" (T100): polvo en suspensión que flota y brilla un poco (ruinas, catacumbas...).
## - "sparks" (T100): cables sueltos que chisporrotean de vez en cuando.
## - "leds" (T100): LEDs que parpadean en los racks del borde de la zona.
## Con «Luces y clima reducidos» (WorldPost.reduced) no hay clima.

const BY_STYLE := {"terminal": "data_rain", "kernel": "data_rain", "servers": "data_rain",
	"swamp": "fog", "alcantarillas": "fog", "fosa": "fog"}
## Capas extra de ambiente por estilo (además de la lluvia o la niebla).
const EXTRA_BY_STYLE := {
	"ruins": ["dust"], "catacombs": ["dust"], "fabrica": ["dust", "sparks"], "fosa": ["dust"], "rom": ["dust"],
	"servers": ["sparks"], "terminal": ["sparks"], "bus": ["sparks"], "bios": ["sparks"], "setup": ["sparks"],
	"grieta": ["dust"], "boss": ["dust"], "anillo": ["dust"],
}
const RAIN_DROPS := 80
const RAIN_SPEED := 420.0
const FOG_BANKS := 9
const FOG_SPEED := 18.0
const DUST_MOTES := 46
const SPARK_SPOTS := 5
const SPLASH_TIME := 0.3
const RAIN_COLOR := Color("3cff6a")
const FOG_COLOR := Color("c8d4c8")
const DUST_COLOR := Color("e8dcc0")
const SPARK_COLOR := Color("ffe070")

var kind := ""
## Capas extra activas ("dust", "sparks", "leds").
var extras: Array[String] = []
## Partículas en coordenadas del mundo: lluvia {pos, len, speed, land}; niebla {pos, radius, phase}.
var _parts: Array[Dictionary] = []
var _splashes: Array[Dictionary] = []   # {pos, t}
var _dust: Array[Dictionary] = []       # {pos, phase, size}
var _sparks: Array[Dictionary] = []     # {pos, next, burst: [{pos, vel, t}]}
var _leds: Array[Dictionary] = []       # {pos, color, phase, rate}
var _rng := RandomNumberGenerator.new()
var _time := 0.0


static func kind_for(style: String) -> String:
	return "" if WorldPost.reduced else String(BY_STYLE.get(style, ""))


## Capas extra de un estilo (sin clima reducido). Los LEDs van aparte: dependen de los racks.
static func extras_for(style: String) -> Array[String]:
	var out: Array[String] = []
	if not WorldPost.reduced:
		out.assign(EXTRA_BY_STYLE.get(style, []))
	return out


## `variant` (T117, zonas generadas): {weather: sustituye al del estilo ("", "fog",
## "data_rain"), dust: polvo de más}.
func setup(style: String, zone: Zone = null, variant := {}) -> void:
	kind = kind_for(style)
	extras = extras_for(style)
	if not WorldPost.reduced:
		if variant.has("weather"):
			kind = String(variant["weather"])
		if bool(variant.get("dust", false)) and not extras.has("dust"):
			extras.append("dust")
	_parts.clear()
	_splashes.clear()
	_dust.clear()
	_sparks.clear()
	_leds.clear()
	_rng.seed = hash(style)
	z_index = 1   # encima de la luz del mundo, debajo del botín y los nombres
	if zone != null and not WorldPost.reduced:
		for p in zone.rack_led_points():
			_leds.append({"pos": p, "color": [Color("3cff6a"), Color("3cff6a"), Color("ffb030"), Color("6ab8ff")][_rng.randi() % 4],
				"phase": _rng.randf() * TAU, "rate": _rng.randf_range(1.5, 6.0)})
		if not _leds.is_empty():
			extras.append("leds")
	set_process(kind != "" or not extras.is_empty())
	queue_redraw()


## Lo que se ve ahora, en coordenadas del mundo (con margen).
func _view() -> Rect2:
	var inv := get_canvas_transform().affine_inverse()
	var r := get_viewport_rect()
	return Rect2(inv * r.position, r.size / get_canvas_transform().get_scale()).grow(60.0)


func _process(delta: float) -> void:
	_time += delta
	var view := _view()
	if _parts.is_empty() and kind != "":
		for k in (RAIN_DROPS if kind == "data_rain" else FOG_BANKS):
			_parts.append(_spawn(view, true))
	if "dust" in extras and _dust.is_empty():
		for k in DUST_MOTES:
			_dust.append(_spawn_dust(view))
	if "sparks" in extras and _sparks.is_empty():
		for k in SPARK_SPOTS:
			_sparks.append({"pos": _random_in(view), "next": _rng.randf_range(0.5, 3.0), "burst": []})
	step(delta, view)
	_step_ambient(delta, view)
	queue_redraw()


## Avanza las partículas; las que salen de la vista vuelven a entrar por el otro lado.
## Las gotas que llegan a su suelo salpican.
func step(delta: float, view: Rect2) -> void:
	for p in _parts:
		if kind == "data_rain":
			p["pos"] += Vector2(0, float(p["speed"]) * delta)
			if p.has("land") and p["pos"].y >= float(p["land"]):
				_splashes.append({"pos": p["pos"], "t": 0.0})
				p.merge(_spawn(view, false), true)
			elif p["pos"].y > view.end.y or not view.grow(200.0).has_point(p["pos"]):
				p.merge(_spawn(view, false), true)
		else:
			p["pos"] += Vector2(FOG_SPEED * delta, sin(float(p["phase"]) + Time.get_ticks_msec() / 4000.0) * 4.0 * delta)
			if p["pos"].x - float(p["radius"]) > view.end.x or not view.grow(600.0).has_point(p["pos"]):
				p.merge(_spawn(view, false), true)
	for s in _splashes:
		s["t"] = float(s["t"]) + delta
	_splashes = _splashes.filter(func(s: Dictionary) -> bool: return float(s["t"]) < SPLASH_TIME)


func _step_ambient(delta: float, view: Rect2) -> void:
	for d in _dust:
		d["pos"] += Vector2(sin(_time * 0.4 + float(d["phase"])) * 6.0, -4.0 + cos(_time * 0.3 + float(d["phase"])) * 3.0) * delta
		if not view.grow(100.0).has_point(d["pos"]):
			d.merge(_spawn_dust(view), true)
	for s in _sparks:
		s["next"] = float(s["next"]) - delta
		if not view.grow(300.0).has_point(s["pos"]):
			s["pos"] = _random_in(view)
		if float(s["next"]) <= 0.0:
			# Un chisporroteo: 6-10 chispas que saltan y caen.
			s["next"] = _rng.randf_range(1.5, 4.5)
			for k in _rng.randi_range(6, 10):
				(s["burst"] as Array).append({"pos": s["pos"], "vel": Vector2(_rng.randf_range(-90, 90), _rng.randf_range(-160, -40)), "t": 0.0})
		for b in s["burst"]:
			b["t"] = float(b["t"]) + delta
			b["vel"] += Vector2(0, 420.0 * delta)
			b["pos"] += b["vel"] * delta
		s["burst"] = (s["burst"] as Array).filter(func(b: Dictionary) -> bool: return float(b["t"]) < 0.5)


func _random_in(view: Rect2) -> Vector2:
	return Vector2(_rng.randf_range(view.position.x, view.end.x), _rng.randf_range(view.position.y, view.end.y))


func _spawn_dust(view: Rect2) -> Dictionary:
	return {"pos": _random_in(view), "phase": _rng.randf() * TAU, "size": _rng.randf_range(1.0, 2.5)}


func _spawn(view: Rect2, anywhere: bool) -> Dictionary:
	if kind == "data_rain":
		var y := _rng.randf_range(view.position.y, view.end.y) if anywhere else view.position.y - _rng.randf_range(0.0, 80.0)
		# Cada gota cae hasta un punto del suelo de la vista y ahí salpica.
		return {"pos": Vector2(_rng.randf_range(view.position.x, view.end.x), y), "len": _rng.randf_range(14.0, 34.0),
			"speed": RAIN_SPEED * _rng.randf_range(0.7, 1.3), "land": _rng.randf_range(maxf(y + 40.0, view.position.y + 80.0), view.end.y + 40.0)}
	var radius := _rng.randf_range(140.0, 260.0)
	var x := _rng.randf_range(view.position.x, view.end.x) if anywhere else view.position.x - radius
	return {"pos": Vector2(x, _rng.randf_range(view.position.y, view.end.y)), "radius": radius, "phase": _rng.randf() * TAU}


func particle_count() -> int:
	return _parts.size()


func _draw() -> void:
	if kind == "data_rain":
		var font := ThemeDB.fallback_font
		for p in _parts:
			var pos: Vector2 = p["pos"]
			draw_line(pos - Vector2(0, float(p["len"])), pos, Color(RAIN_COLOR, 0.18), 2.0)
			draw_string(font, pos + Vector2(-3, 4), "1" if int(pos.x) % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(RAIN_COLOR, 0.45))
		for s in _splashes:   # salpicaduras: un anillo aplastado y dos gotitas
			var t := float(s["t"]) / SPLASH_TIME
			var pos: Vector2 = s["pos"]
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.4))
			draw_arc(Vector2.ZERO, 3.0 + 9.0 * t, 0.0, TAU, 10, Color(RAIN_COLOR, 0.45 * (1.0 - t)), 1.5)
			draw_set_transform(Vector2.ZERO)
			for side in [-1.0, 1.0]:
				draw_circle(pos + Vector2(side * 6.0 * t, -10.0 * t + 14.0 * t * t), 1.2, Color(RAIN_COLOR, 0.6 * (1.0 - t)))
	elif kind == "fog":
		for p in _parts:
			var r := float(p["radius"])
			for k in 3:   # bordes suaves: tres capas cada vez más chicas
				draw_circle(p["pos"], r * (1.0 - k * 0.28), Color(FOG_COLOR, 0.035))
	for d in _dust:   # motas que brillan al girar
		var tw := 0.5 + 0.5 * sin(_time * 1.7 + float(d["phase"]) * 3.0)
		draw_circle(d["pos"], float(d["size"]), Color(DUST_COLOR, 0.12 + 0.22 * tw))
	for s in _sparks:
		for b in s["burst"]:
			var t := float(b["t"]) / 0.5
			var pos: Vector2 = b["pos"]
			draw_line(pos, pos - (b["vel"] as Vector2) * 0.02, Color(SPARK_COLOR, 1.0 - t), 1.5)
		if not (s["burst"] as Array).is_empty():
			draw_circle(s["pos"], 10.0, Color(SPARK_COLOR, 0.18))
	for l in _leds:
		var on := sin(_time * float(l["rate"]) + float(l["phase"])) > -0.2
		var c: Color = l["color"]
		draw_rect(Rect2((l["pos"] as Vector2) - Vector2(2, 1), Vector2(4, 3)), Color(c, 0.95 if on else 0.15))
		if on:
			draw_circle(l["pos"], 5.0, Color(c, 0.12))
