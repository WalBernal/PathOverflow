class_name Weather
extends Node2D
## Clima de algunas zonas, dibujado sobre lo que se ve de la zona (no se guarda):
## - "data_rain": lluvia de datos, trazos verdes que caen con un bit en la punta
##   (la terminal, el kernel, los servidores).
## - "fog": niebla que deriva despacio (el pantano, las alcantarillas, la fosa).
## Con «Luces y clima reducidos» (WorldPost.reduced) no hay clima.

const BY_STYLE := {"terminal": "data_rain", "kernel": "data_rain", "servers": "data_rain",
	"swamp": "fog", "alcantarillas": "fog", "fosa": "fog"}
const RAIN_DROPS := 80
const RAIN_SPEED := 420.0
const FOG_BANKS := 9
const FOG_SPEED := 18.0
const RAIN_COLOR := Color("3cff6a")
const FOG_COLOR := Color("c8d4c8")

var kind := ""
## Partículas en coordenadas del mundo: lluvia {pos, len, speed}; niebla {pos, radius, phase}.
var _parts: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


static func kind_for(style: String) -> String:
	return "" if WorldPost.reduced else String(BY_STYLE.get(style, ""))


func setup(style: String) -> void:
	kind = kind_for(style)
	_parts.clear()
	_rng.seed = hash(style)
	z_index = 1   # encima de la luz del mundo, debajo del botín y los nombres
	set_process(kind != "")
	queue_redraw()


## Lo que se ve ahora, en coordenadas del mundo (con margen).
func _view() -> Rect2:
	var inv := get_canvas_transform().affine_inverse()
	var r := get_viewport_rect()
	return Rect2(inv * r.position, r.size / get_canvas_transform().get_scale()).grow(60.0)


func _process(delta: float) -> void:
	var view := _view()
	if _parts.is_empty():
		for k in (RAIN_DROPS if kind == "data_rain" else FOG_BANKS):
			_parts.append(_spawn(view, true))
	step(delta, view)
	queue_redraw()


## Avanza las partículas; las que salen de la vista vuelven a entrar por el otro lado.
func step(delta: float, view: Rect2) -> void:
	for p in _parts:
		if kind == "data_rain":
			p["pos"] += Vector2(0, float(p["speed"]) * delta)
			if p["pos"].y > view.end.y or not view.grow(200.0).has_point(p["pos"]):
				p.merge(_spawn(view, false), true)
		else:
			p["pos"] += Vector2(FOG_SPEED * delta, sin(float(p["phase"]) + Time.get_ticks_msec() / 4000.0) * 4.0 * delta)
			if p["pos"].x - float(p["radius"]) > view.end.x or not view.grow(600.0).has_point(p["pos"]):
				p.merge(_spawn(view, false), true)


func _spawn(view: Rect2, anywhere: bool) -> Dictionary:
	if kind == "data_rain":
		var y := _rng.randf_range(view.position.y, view.end.y) if anywhere else view.position.y - _rng.randf_range(0.0, 80.0)
		return {"pos": Vector2(_rng.randf_range(view.position.x, view.end.x), y), "len": _rng.randf_range(14.0, 34.0),
			"speed": RAIN_SPEED * _rng.randf_range(0.7, 1.3)}
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
	elif kind == "fog":
		for p in _parts:
			var r := float(p["radius"])
			for k in 3:   # bordes suaves: tres capas cada vez más chicas
				draw_circle(p["pos"], r * (1.0 - k * 0.28), Color(FOG_COLOR, 0.035))
