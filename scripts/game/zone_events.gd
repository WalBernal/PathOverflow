class_name ZoneEvents
extends Node2D
## Eventos dentro de las zonas de combate (para que las zonas grandes tengan
## sorpresas, no solo más manadas). Se colocan al azar en cada visita:
## - "cache": Datos huérfanos. Al abrirlo salen dos oleadas; al limpiarlas, botín.
## - "shrine": Santuario. Al tocarlo da un bono temporal (turbo, firewall, debug)
##   o llena tus cargas (overclock).
## - "ambush": Emboscada. Invisible: al pasar cerca, te rodean dos manadas.
## - "deploy": Deploy fallido. Una consola; al tocarla salen dos raros con escolta
##   y, al vencerlos, botín.
## - "bombs": Bombas lógicas. Al tocar la consola aparecen tres bombas con cuenta
##   atrás: quédate junto a cada una para desactivarla antes de que estallen.
## - "escort": Escoltar un proceso. Un proceso perdido camina hasta su salida, pero
##   solo si estás cerca y no hay enemigos junto a él; a mitad de camino, emboscadas.
## - "merchant": Comerciante ambulante. Un objeto misterioso (con buena rareza) por fichas.
## La zona dibuja y detecta; World hace aparecer enemigos y da recompensas.

signal triggered(event: Dictionary)
## Un evento con objetivo (bombas, escolta) terminó: bien o mal.
signal resolved(event: Dictionary, success: bool)
## Una bomba lógica no se desactivó a tiempo.
signal exploded(pos: Vector2)
## El proceso escoltado llegó a un tramo (1/3, 2/3): toca emboscada.
signal escort_wave(event: Dictionary)

const KINDS := ["cache", "shrine", "ambush", "deploy", "bombs", "escort", "merchant"]
const WEIGHTS := [26, 30, 17, 12, 6, 6, 4]
const BOMB_COUNT := 3
const BOMB_TIME := 25.0
const BOMB_SPREAD := 300.0
const DEFUSE_RADIUS := 70.0
const DEFUSE_TIME := 1.5
const BOMB_BLAST := 200.0
const ESCORT_SPEED := 70.0
const ESCORT_LEASH := 260.0       # el proceso solo avanza si estás así de cerca
const ESCORT_BLOCK := 220.0       # y si no hay enemigos a esta distancia de él
const ESCORT_MIN_TRIP := 900.0
## Enemigos de la zona (los pone World): la escolta se para si hay alguno cerca.
var enemies: EnemyManager
const RADIUS := 46.0
const AMBUSH_RADIUS := 170.0
## Los datos huérfanos se abren solos al pasar a esta distancia (sin tener que tocarlos).
const CACHE_TRIGGER_RADIUS := 230.0
const SHRINES := {
	"turbo": {"name": "Santuario Turbo", "color": "6ad07a", "text": "Turbo: +30 % de velocidad de ataque, lanzamiento y movimiento (20 s)",
		"mods": [{"stat": "attack_speed", "type": "increased", "value": 30}, {"stat": "cast_speed", "type": "increased", "value": 30},
			{"stat": "movement_speed", "type": "increased", "value": 25}]},
	"firewall": {"name": "Santuario Firewall", "color": "e0a050", "text": "Firewall: 50 % más de armadura y +20 % a las resistencias (20 s)",
		"mods": [{"stat": "armour", "type": "more", "value": 50}, {"stat": "fire_res", "type": "flat", "value": 20},
			{"stat": "cold_res", "type": "flat", "value": 20}, {"stat": "lightning_res", "type": "flat", "value": 20}]},
	"debug": {"name": "Santuario Debug", "color": "ff6a5a", "text": "Modo debug: 40 % más de daño (20 s)",
		"mods": [{"stat": "damage", "type": "more", "value": 40}]},
	"overclock": {"name": "Santuario Overclock", "color": "6aa8ff", "text": "Overclock: todas tus cargas al máximo", "mods": []},
}
const SHRINE_SECONDS := 20.0
const NAMES := {"cache": "Datos huérfanos", "deploy": "Deploy fallido", "bombs": "Bombas lógicas", "escort": "Proceso perdido",
	"merchant": "Comerciante ambulante"}

var zone: Zone
## {kind, pos, state: "ready"|"active"|"done", shrine?, wave?, ids?}
var events: Array[Dictionary] = []
var _pending := -1
var _time := 0.0


func setup(p_zone: Zone, rng: RandomNumberGenerator) -> void:
	zone = p_zone
	z_index = 0
	if zone.safe or not zone.def.get("enemies") is Dictionary or zone.def.has("boss"):
		return
	var area := zone.rect.size.x * zone.rect.size.y
	var count := clampi(int(area / 3200000.0), 2, 7)
	var keys := zone.key_points()
	var tries := 0
	while events.size() < count and tries < 200:
		tries += 1
		var p := Vector2(rng.randf_range(zone.rect.position.x + 300, zone.rect.end.x - 300), rng.randf_range(zone.rect.position.y + 260, zone.rect.end.y - 260))
		p = zone.free_spot_near(p, 50.0)
		if not zone.is_walkable(p, 50.0) or keys.any(func(k: Vector2) -> bool: return k.distance_to(p) < 520.0) \
				or events.any(func(e: Dictionary) -> bool: return Vector2(e["pos"]).distance_to(p) < 700.0):
			continue
		var kind := _pick(rng)
		var e := {"kind": kind, "pos": p, "state": "ready"}
		if kind == "shrine":
			e["shrine"] = SHRINES.keys()[rng.randi_range(0, SHRINES.size() - 1)]
		elif kind == "escort":
			var goal := _escort_goal(p, rng)
			if goal == Vector2.INF:
				e["kind"] = "cache"   # no cabe un viaje largo: se queda en datos huérfanos
			else:
				e["goal"] = goal
				e["start"] = p
				e["walker"] = p
				e["waves_done"] = 0
		events.append(e)


## Un destino caminable a buena distancia para el proceso escoltado (INF si no hay).
func _escort_goal(from: Vector2, rng: RandomNumberGenerator) -> Vector2:
	for k in 30:
		var q := Vector2(rng.randf_range(zone.rect.position.x + 200, zone.rect.end.x - 200), rng.randf_range(zone.rect.position.y + 200, zone.rect.end.y - 200))
		q = zone.free_spot_near(q, 40.0)
		if q.distance_to(from) >= ESCORT_MIN_TRIP and zone.is_walkable(q, 40.0):
			return q
	return Vector2.INF


func _pick(rng: RandomNumberGenerator) -> String:
	var total := 0
	for w in WEIGHTS:
		total += w
	var r := rng.randi_range(0, total - 1)
	for k in KINDS.size():
		r -= WEIGHTS[k]
		if r < 0:
			return KINDS[k]
	return KINDS[0]


func _process(delta: float) -> void:
	_time += delta
	if events.is_empty() or zone.player == null:
		return
	var pp := zone.player.global_position
	for i in events.size():
		var e := events[i]
		if e["kind"] == "ambush" and e["state"] == "ready" and pp.distance_to(e["pos"]) < AMBUSH_RADIUS:
			_fire(i)
		elif e["kind"] == "cache" and e["state"] == "ready" and pp.distance_to(e["pos"]) < CACHE_TRIGGER_RADIUS:
			if _pending == i:
				_pending = -1
			_fire(i)
		elif e["state"] == "active" and e["kind"] == "bombs":
			_update_bombs(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "escort":
			_update_escort(e, pp, delta)
	if _pending != -1:
		var e := events[_pending]
		if pp.distance_to(e["pos"]) <= RADIUS + 40.0:
			zone.player.stop_auto_move()
			_fire(_pending)
			_pending = -1
		elif not zone.player.has_auto_target():
			_pending = -1
	queue_redraw()


func _fire(i: int) -> void:
	var e := events[i]
	if e["state"] != "ready":
		return
	e["state"] = "done" if e["kind"] in ["shrine", "ambush"] else "active"
	if e["kind"] == "bombs":
		e["time_left"] = BOMB_TIME
		var bombs: Array = []
		for k in BOMB_COUNT:
			var q := zone.free_spot_near(Vector2(e["pos"]) + Vector2.from_angle(TAU * k / BOMB_COUNT + 0.4) * BOMB_SPREAD, 40.0)
			bombs.append({"pos": q, "progress": 0.0, "done": false})
		e["bombs"] = bombs
	triggered.emit(e)


## Bombas lógicas: junto a una, se desactiva poco a poco; al acabar el tiempo, las que queden estallan.
func _update_bombs(e: Dictionary, pp: Vector2, delta: float) -> void:
	e["time_left"] = float(e["time_left"]) - delta
	var left := 0
	for b in e["bombs"]:
		if b["done"]:
			continue
		if pp.distance_to(b["pos"]) <= DEFUSE_RADIUS:
			b["progress"] = float(b["progress"]) + delta
			if b["progress"] >= DEFUSE_TIME:
				b["done"] = true
				continue
		left += 1
	if left == 0:
		e["state"] = "done"
		resolved.emit(e, true)
	elif e["time_left"] <= 0.0:
		for b in e["bombs"]:
			if not b["done"]:
				b["done"] = true
				exploded.emit(b["pos"])
		e["state"] = "done"
		resolved.emit(e, false)


## Escolta: avanza hacia su salida si estás cerca y no hay enemigos a su lado.
func _update_escort(e: Dictionary, pp: Vector2, delta: float) -> void:
	var w: Vector2 = e["walker"]
	var blocked := enemies != null and enemies.nearest_index(w, ESCORT_BLOCK) != -1
	e["blocked"] = blocked
	if blocked or pp.distance_to(w) > ESCORT_LEASH:
		return
	w = w.move_toward(e["goal"], ESCORT_SPEED * delta)
	e["walker"] = w
	var trip: float = Vector2(e["start"]).distance_to(e["goal"])
	var done_frac := 1.0 - w.distance_to(e["goal"]) / maxf(1.0, trip)
	if int(e["waves_done"]) < 2 and done_frac >= (int(e["waves_done"]) + 1) / 3.0:
		e["waves_done"] = int(e["waves_done"]) + 1
		escort_wave.emit(e)
	if w.distance_to(e["goal"]) < 4.0:
		e["state"] = "done"
		resolved.emit(e, true)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var i := _at(get_global_mouse_position())
	if i != -1:
		_pending = i
		zone.player.move_to(events[i]["pos"] + Vector2(0, 30))
		get_viewport().set_input_as_handled()


## Mando (A): el evento más cercano a `pos`, si lo hay.
func interact_near(pos: Vector2, radius: float) -> bool:
	for i in events.size():
		if events[i]["kind"] != "ambush" and events[i]["state"] == "ready" and pos.distance_to(events[i]["pos"]) < radius:
			_pending = i
			zone.player.move_to(events[i]["pos"] + Vector2(0, 30))
			return true
	return false


func _at(pos: Vector2) -> int:
	for i in events.size():
		if events[i]["kind"] != "ambush" and events[i]["state"] == "ready" and pos.distance_to(events[i]["pos"]) < RADIUS:
			return i
	return -1


# --- Dibujo (con el decorado: en pixel art) ---

func _draw() -> void:
	for e in events:
		match e["kind"]:
			"cache":
				_draw_cache(e)
			"shrine":
				_draw_shrine(e)
			"deploy":
				_draw_deploy(e)
			"bombs":
				_draw_bombs(e)
			"escort":
				_draw_escort(e)
			"merchant":
				_draw_merchant(e)


func _shadow(p: Vector2, w: float) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)


## Cofre de datos huérfanos: un disco duro viejo con candado y LEDs.
func _draw_cache(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 18), 34.0)
	if ready:
		draw_circle(p, 44.0, Color(1.0, 0.8, 0.3, 0.06 + 0.04 * sin(_time * 3.0)))
		# Aro de activación: al cruzarlo se abre (trazos que giran despacio).
		for k in 24:
			var a := TAU * k / 24.0 + _time * 0.3
			draw_arc(p, CACHE_TRIGGER_RADIUS, a, a + TAU / 48.0, 3, Color(1.0, 0.8, 0.3, 0.28), 2.0)
	var box := Rect2(p - Vector2(30, 18), Vector2(60, 34))
	draw_rect(box, Color("4a4350"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 4)), Color("6a6372"))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 4), Vector2(box.size.x, 4)), Color("2e2a34"))
	for k in 4:
		draw_rect(Rect2(box.position + Vector2(6 + k * 7, 10), Vector2(4, 3)), Color("40ff70") if ready and int(_time * 4.0 + k) % 3 else Color("1a3020"))
	if e["state"] == "done":
		draw_rect(Rect2(box.position + Vector2(4, -10), Vector2(52, 10)), Color("3a3440"))   # tapa abierta
	else:
		draw_rect(Rect2(p + Vector2(10, -6), Vector2(12, 10)), Color("d9a441"))
		draw_arc(p + Vector2(16, -6), 5.0, PI, TAU, 8, Color("d9a441"), 2.0)
	if ready:
		zone._label(p + Vector2(-90, -34), NAMES["cache"], 180, 13, Color("f2c14e"))


## Santuario: obelisco con runa que gira, del color de su bono.
func _draw_shrine(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var info: Dictionary = SHRINES[e["shrine"]]
	var col := Color(info["color"])
	var ready: bool = e["state"] == "ready"
	if not ready:
		col = col.darkened(0.7)
	_shadow(p + Vector2(0, 16), 28.0)
	if ready:
		draw_circle(p + Vector2(0, -20), 50.0, Color(col, 0.08 + 0.05 * sin(_time * 2.5)))
	draw_rect(Rect2(p + Vector2(-20, 6), Vector2(40, 10)), Color("3a3640"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 6), p + Vector2(12, 6), p + Vector2(7, -52), p + Vector2(-7, -52)]), Color("4a4652"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -52), p + Vector2(7, -52), p + Vector2(0, -62)]), Color("5a5662"))
	var rune := p + Vector2(0, -26)
	draw_rect(Rect2(rune - Vector2(5, 5), Vector2(10, 10)), col)
	if ready:
		for k in 4:
			var a := _time * 1.5 + k * TAU / 4.0
			var q := rune + Vector2.from_angle(a) * 20.0
			draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(col, 0.8))
		zone._label(p + Vector2(-100, -76), info["name"], 200, 13, col.lightened(0.3))


## Deploy fallido: consola con la pantalla en rojo.
func _draw_deploy(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 16), 30.0)
	draw_rect(Rect2(p + Vector2(-26, -6), Vector2(52, 20)), Color("2e2a34"))
	var screen := Rect2(p + Vector2(-22, -46), Vector2(44, 34))
	draw_rect(screen.grow(3), Color("3a3640"))
	var blink := 0.6 + 0.4 * sin(_time * 6.0) if ready else 0.2
	draw_rect(screen, Color(0.5 * blink, 0.05, 0.05))
	for k in 4:
		draw_rect(Rect2(screen.position + Vector2(4, 5 + k * 7), Vector2(14 + (k * 9) % 22, 3)), Color(1, 0.5, 0.45, blink))
	if ready:
		zone._label(p + Vector2(-90, -58), NAMES["deploy"], 180, 13, Color("ff6a5a"))


## Bombas lógicas: la consola y, activa, las tres bombas con su aro de desactivación y la cuenta atrás.
func _draw_bombs(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 16), 28.0)
	draw_rect(Rect2(p + Vector2(-20, -30), Vector2(40, 44)), Color("2e2a34"))
	draw_rect(Rect2(p + Vector2(-15, -25), Vector2(30, 18)), Color("401010") if ready else Color("1a1a1e"))
	if ready:
		zone._label(p + Vector2(-90, -48), NAMES["bombs"], 180, 13, Color("ff9a3a"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-13, -11), "BOOM?", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.6, 0.3, 0.6 + 0.4 * sin(_time * 6.0)))
		return
	if e["state"] != "active":
		return
	var t: float = e["time_left"]
	zone._label(p + Vector2(-90, -48), "%d s" % ceili(maxf(0.0, t)), 180, 16, Color("ff5a3a") if t < 8.0 else Color("ffd060"))
	for b in e["bombs"]:
		if b["done"]:
			continue
		var q: Vector2 = b["pos"]
		_shadow(q + Vector2(0, 10), 16.0)
		draw_circle(q, 12.0, Color("1a1a1e"))
		draw_line(q + Vector2(6, -10), q + Vector2(12, -18), Color("c8a050"), 2.0)
		var spark := fmod(_time * 8.0, 1.0) < 0.5
		draw_circle(q + Vector2(12, -18), 3.0, Color("ffd060") if spark else Color("ff6a2a"))
		draw_arc(q, DEFUSE_RADIUS, 0.0, TAU, 32, Color(1, 0.6, 0.2, 0.35), 2.0, true)
		var prog := float(b["progress"]) / DEFUSE_TIME
		if prog > 0.0:
			draw_arc(q, DEFUSE_RADIUS - 6.0, -PI / 2.0, -PI / 2.0 + TAU * prog, 32, Color("6fd36b"), 4.0, true)


## Proceso perdido: un fantasmita con su PID que camina hacia su salida (bandera).
func _draw_escort(e: Dictionary) -> void:
	var w: Vector2 = e["walker"]
	var ready: bool = e["state"] == "ready"
	if e["state"] == "active":
		var goal: Vector2 = e["goal"]
		for k in 12:   # camino de puntos hasta la salida
			draw_circle(w.lerp(goal, k / 12.0), 2.0, Color(0.6, 0.9, 1.0, 0.25))
		draw_line(goal, goal + Vector2(0, -40), Color("8a8a96"), 2.0)
		draw_colored_polygon(PackedVector2Array([goal + Vector2(0, -40), goal + Vector2(22, -33), goal + Vector2(0, -26)]), Color("6fd36b"))
		zone._label(goal + Vector2(-60, -60), "Salida", 120, 12, Color("6fd36b"))
	if e["state"] == "done":
		return
	var bob := sin(_time * 4.0) * 2.0
	_shadow(w + Vector2(0, 14), 14.0)
	draw_circle(w + Vector2(0, -6 + bob), 12.0, Color(0.75, 0.9, 1.0, 0.85))
	draw_rect(Rect2(w + Vector2(-12, -6 + bob), Vector2(24, 12)), Color(0.75, 0.9, 1.0, 0.85))
	draw_circle(w + Vector2(-4, -8 + bob), 2.0, Color("1a2030"))
	draw_circle(w + Vector2(4, -8 + bob), 2.0, Color("1a2030"))
	var tag := "PID %d" % (int(Vector2(e["start"]).x) % 9000 + 1000)
	if ready:
		zone._label(w + Vector2(-90, -40), NAMES["escort"], 180, 13, Color("8ad8ff"))
	elif e.get("blocked", false):
		zone._label(w + Vector2(-90, -40), "¡Enemigos cerca!", 180, 12, Color("ff6a5a"))
	else:
		zone._label(w + Vector2(-90, -40), tag, 180, 11, Color("8ad8ff"))


## Comerciante ambulante: un carrito con toldo y un cofre misterioso.
func _draw_merchant(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 18), 36.0)
	draw_rect(Rect2(p + Vector2(-30, -10), Vector2(60, 24)), Color("6a4a30"))
	for s in [-1.0, 1.0]:
		draw_circle(p + Vector2(s * 20, 16), 7.0, Color("3a2a1e"))
	for k in 5:   # toldo de rayas
		draw_rect(Rect2(p + Vector2(-32 + k * 13, -34), Vector2(13, 10)), Color("c84b4b") if k % 2 == 0 else Color("e8e0d0"))
	draw_line(p + Vector2(-30, -24), p + Vector2(-30, -10), Color("4a3a2a"), 2.0)
	draw_line(p + Vector2(30, -24), p + Vector2(30, -10), Color("4a3a2a"), 2.0)
	if ready:
		draw_rect(Rect2(p + Vector2(-8, -20), Vector2(16, 10)), Color("d9a441"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-3, -11), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("2a1a0a"))
		zone._label(p + Vector2(-100, -52), "%s: %d fichas" % [NAMES["merchant"], merchant_price(e)], 200, 13, Color("f2c14e"))


## Precio del objeto misterioso del comerciante ambulante (sube con el nivel de la zona).
func merchant_price(_e: Dictionary) -> int:
	return 25 + int(zone.def.get("level", 1)) * 3
