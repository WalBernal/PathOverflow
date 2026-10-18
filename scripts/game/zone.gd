class_name Zone
extends Node2D
## Una zona del acto (data/act1.json): suelo, obstáculos con colisión, bordes,
## salidas a otras zonas, waypoint y NPCs. Los obstáculos se colocan con una
## semilla fija por zona (siempre igual) y sin tapar el camino entre entradas,
## salidas y puntos de interés. Todo se dibuja con formas mientras no haya arte.
##
## Click en un NPC o en el waypoint: el jugador camina hasta él.
## Pisar una salida: se viaja a la zona de destino.

signal npc_interacted(npc: Dictionary)
signal exit_reached(exit: Dictionary)
signal waypoint_clicked
signal waypoint_touched

const NPC_DATA_PATH := "res://data/npcs.json"
const TALK_RANGE := 70.0
const CLICK_RADIUS := 28.0
const EXIT_RADIUS := 55.0
const WAYPOINT_RADIUS := 46.0
const BORDER := 160.0
## Distancia mínima de un obstáculo a entradas, salidas, NPCs y waypoint.
const CLEAR_RADIUS := 200.0
## Medio ancho del pasillo libre entre puntos de interés.
const CORRIDOR := 110.0
const OBSTACLE_RADIUS := {
	"rock": 34.0, "crate": 26.0, "monitor": 24.0, "cable_tree": 32.0, "pillar": 34.0, "rubble": 30.0,
	"puddle": 46.0, "dead_tree": 28.0, "tomb": 24.0, "rack": 32.0, "cable_coil": 26.0,
}
const STYLES := {
	"sandbox": {"ground": "1c2630", "decal": "26323e"},
	"camp": {"ground": "231d17", "decal": "2b241c"},
	"forest": {"ground": "151d15", "decal": "1d281c"},
	"ruins": {"ground": "24201b", "decal": "2e2922"},
	"swamp": {"ground": "161c1a", "decal": "2a1f33"},
	"catacombs": {"ground": "1a181e", "decal": "232029"},
	"servers": {"ground": "13161c", "decal": "1b2029"},
	"boss": {"ground": "1a0f12", "decal": "2a1418"},
}
const WOOD := Color("5b3f27")

static var _npc_db: Dictionary = {}

var def: Dictionary
var id := ""
var zone_name := ""
var level := 1
var style := "sandbox"
var rect := Rect2()
var safe := false
var obstacles: Array[Dictionary] = []   # {pos, radius, kind, seed}
var exits: Array[Dictionary] = []       # {pos, target, entry, label}
var has_waypoint := false
var waypoint := Vector2.ZERO
var npcs: Array = []                    # como en npcs.json + "position"
var dialogues: Dictionary = {}
var player: Player
var character: CharacterData

var _decals: Array[Dictionary] = []
var _pending: Dictionary = {}           # {"kind": "npc"|"waypoint", "npc": {...}}
var _hovered_npc := -1
var _time := 0.0
var _exits_armed := false


static func npc_database() -> Dictionary:
	if _npc_db.is_empty():
		var data = DataLoader.load_json(NPC_DATA_PATH)
		if data is Dictionary:
			_npc_db = data
	return _npc_db


func setup(p_def: Dictionary, p_player: Player, p_character: CharacterData) -> void:
	def = p_def
	player = p_player
	character = p_character
	id = def["id"]
	zone_name = def.get("name", id)
	level = int(def.get("level", 1))
	style = def.get("style", "sandbox")
	safe = bool(def.get("safe", false))
	rect = Rect2(Vector2.ZERO, Vector2(def["size"][0], def["size"][1]))
	for e in def.get("exits", []):
		exits.append({"pos": _v(e["pos"]), "target": e["target"], "entry": e["entry"], "label": e.get("label", "")})
	if def.has("waypoint"):
		has_waypoint = true
		waypoint = _v(def["waypoint"])
	var db := npc_database()
	dialogues = db.get("dialogues", {})
	for placement in def.get("npcs", []):
		var base: Dictionary = db.get("npcs", {}).get(placement["id"], {})
		if base.is_empty():
			push_warning("NPC desconocido en %s: %s" % [id, placement["id"]])
			continue
		var npc := base.duplicate()
		npc["id"] = placement["id"]
		npc["position"] = placement["pos"]
		npcs.append(npc)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	_place_obstacles(rng)
	_make_decals(rng)
	_build_collision()


func entry_point(key: String) -> Vector2:
	var entries: Dictionary = def.get("entries", {})
	if entries.has(key):
		return _v(entries[key])
	return _v(entries.values()[0]) if not entries.is_empty() else rect.get_center()


func npc_position(npc: Dictionary) -> Vector2:
	return _v(npc["position"])


## Puntos de interés: entradas, salidas, waypoint, NPCs y jefe.
func key_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for e in def.get("entries", {}).values():
		points.append(_v(e))
	for e in exits:
		points.append(e["pos"])
	if has_waypoint:
		points.append(waypoint)
	for npc in npcs:
		points.append(npc_position(npc))
	if def.has("boss"):
		points.append(_v(def["boss"]["pos"]))
	return points


## Centros de los grupos de enemigos: repartidos por la zona, lejos de los
## puntos de interés, de los obstáculos y entre sí.
func pack_centers(count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var keys := key_points()
	var inner := rect.grow(-220.0)
	for attempt in 600:
		if result.size() >= count:
			break
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		var ok := true
		for k in keys:
			if p.distance_to(k) < 450.0:
				ok = false
				break
		for o in obstacles:
			if ok and p.distance_to(o["pos"]) < o["radius"] + 90.0:
				ok = false
		for other in result:
			if ok and p.distance_to(other) < 380.0:
				ok = false
		if ok:
			result.append(p)
	return result


func free_spot_near(p: Vector2) -> Vector2:
	for o in obstacles:
		if p.distance_to(o["pos"]) < o["radius"] + 16.0:
			return o["pos"] + (p - o["pos"]).normalized() * (o["radius"] + 20.0)
	return p.clamp(rect.position + Vector2(30, 30), rect.end - Vector2(30, 30))


# --- Construcción ---

func _place_obstacles(rng: RandomNumberGenerator) -> void:
	var cfg: Dictionary = def.get("obstacles", {})
	var kinds: Array = cfg.get("kinds", [])
	var wanted := int(cfg.get("count", 0))
	if kinds.is_empty() or wanted <= 0:
		return
	var keys := key_points()
	# Pasillo: une los puntos de interés de oeste a este.
	var path := keys.duplicate()
	path.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var inner := rect.grow(-90.0)
	for attempt in wanted * 40:
		if obstacles.size() >= wanted:
			break
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var radius: float = OBSTACLE_RADIUS.get(kind, 30.0)
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		var ok := true
		for k in keys:
			if p.distance_to(k) < CLEAR_RADIUS + radius:
				ok = false
				break
		for i in path.size() - 1:
			if ok and Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1]).distance_to(p) < CORRIDOR + radius:
				ok = false
		for o in obstacles:
			if ok and p.distance_to(o["pos"]) < radius + o["radius"] + 70.0:
				ok = false
		if ok:
			obstacles.append({"pos": p, "radius": radius, "kind": kind, "seed": rng.randi()})


func _make_decals(rng: RandomNumberGenerator) -> void:
	var n := int(rect.get_area() / 60000.0)
	for i in n:
		_decals.append({
			"pos": Vector2(rng.randf_range(0, rect.size.x), rng.randf_range(0, rect.size.y)),
			"size": rng.randf_range(30.0, 110.0), "angle": rng.randf() * TAU, "seed": rng.randi(),
		})


func _build_collision() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	# Bordes del mapa.
	for wall in [
		Rect2(rect.position.x - BORDER, rect.position.y - BORDER, rect.size.x + BORDER * 2.0, BORDER),
		Rect2(rect.position.x - BORDER, rect.end.y, rect.size.x + BORDER * 2.0, BORDER),
		Rect2(rect.position.x - BORDER, rect.position.y, BORDER, rect.size.y),
		Rect2(rect.end.x, rect.position.y, BORDER, rect.size.y)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = wall.size
		shape.shape = box
		shape.position = wall.get_center()
		body.add_child(shape)
	for o in obstacles:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = o["radius"]
		shape.shape = circle
		shape.position = o["pos"]
		body.add_child(shape)


static func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


# --- Interacción ---

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if player == null or not player.is_alive():
		return
	var near_exit := false
	for e in exits:
		if player.global_position.distance_to(e["pos"]) < EXIT_RADIUS:
			near_exit = true
			if _exits_armed:
				_exits_armed = false
				exit_reached.emit(e)
				return
	if not near_exit:
		_exits_armed = true
	if has_waypoint and player.global_position.distance_to(waypoint) < WAYPOINT_RADIUS + 60.0:
		waypoint_touched.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hovered_npc = _npc_at(get_global_mouse_position())
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var mouse := get_global_mouse_position()
		var i := _npc_at(mouse)
		if i != -1:
			_pending = {"kind": "npc", "npc": npcs[i]}
			player.move_to(npc_position(npcs[i]) + Vector2(0, 40))
			get_viewport().set_input_as_handled()
		elif has_waypoint and mouse.distance_to(waypoint) < WAYPOINT_RADIUS:
			_pending = {"kind": "waypoint"}
			player.move_to(waypoint + Vector2(0, 30))
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var target: Vector2 = waypoint if _pending["kind"] == "waypoint" else npc_position(_pending["npc"])
	if player.global_position.distance_to(target) <= TALK_RANGE:
		player.stop_auto_move()
		player.face(target - player.global_position)
		if _pending["kind"] == "waypoint":
			waypoint_clicked.emit()
		else:
			npc_interacted.emit(_pending["npc"])
		_pending = {}
	elif not player.has_auto_target():
		_pending = {}


func _npc_at(pos: Vector2) -> int:
	for i in npcs.size():
		if pos.distance_to(npc_position(npcs[i]) + Vector2(0, -18)) <= CLICK_RADIUS:
			return i
	return -1


# --- Dibujo ---

func _draw() -> void:
	var s: Dictionary = STYLES.get(style, STYLES["sandbox"])
	var ground := Color(s["ground"])
	var decal := Color(s["decal"])
	draw_rect(rect.grow(BORDER), ground.darkened(0.55))
	draw_rect(rect, ground)
	_draw_decals(decal)
	if style == "camp":
		_draw_camp()
	for o in obstacles:
		_draw_obstacle(o)
	draw_rect(rect, ground.lightened(0.15), false, 3.0)
	for e in exits:
		_draw_exit(e)
	if has_waypoint:
		_draw_waypoint()
	_draw_npcs()


func _draw_decals(c: Color) -> void:
	for d in _decals:
		var p: Vector2 = d["pos"]
		var sz: float = d["size"]
		match style:
			"sandbox", "servers", "catacombs":
				var tile := 80.0
				var cell := (p / tile).floor() * tile
				draw_rect(Rect2(cell, Vector2(tile, tile)), Color(c, 0.8), false, 1.0)
				if style == "servers" and int(d["seed"]) % 3 == 0:
					draw_circle(cell + Vector2(6, 6), 2.0, Color(0.2, 0.9, 0.4, 0.4 + 0.3 * sin(_time * 3.0 + d["seed"])))
			"forest":
				var pts := PackedVector2Array()
				for k in 6:
					pts.append(p + Vector2(k * sz / 5.0, sin(k + d["angle"]) * 10.0).rotated(d["angle"]))
				draw_polyline(pts, [Color("2b5a3a"), Color("3a3a6a"), Color("6a3a3a")][int(d["seed"]) % 3], 2.0, true)
			"swamp":
				draw_set_transform(p, d["angle"], Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, sz * 0.5, Color(c, 0.9))
				draw_set_transform(Vector2.ZERO)
			"boss":
				var q := p + Vector2(sz, 0).rotated(d["angle"])
				draw_line(p, q, Color(c, 0.9), 2.0)
				draw_circle(q, 3.0, Color(0.8, 0.2, 0.2, 0.35))
			_:
				draw_set_transform(p, d["angle"], Vector2(1.0, 0.6))
				draw_circle(Vector2.ZERO, sz * 0.4, Color(c, 0.7))
				draw_set_transform(Vector2.ZERO)


func _draw_obstacle(o: Dictionary) -> void:
	var p: Vector2 = o["pos"]
	var r: float = o["radius"]
	var seed_value: int = o["seed"]
	# Sombra común.
	draw_set_transform(p + Vector2(0, r * 0.55), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r * 1.05, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	match o["kind"]:
		"rock":
			var pts := PackedVector2Array()
			for k in 9:
				var rr := r * (0.8 + 0.2 * sin(seed_value + k * 1.7))
				pts.append(p + Vector2.from_angle(TAU * k / 9.0) * Vector2(rr, rr * 0.8))
			draw_colored_polygon(pts, Color("5a5660"))
			draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color("75707c"))
		"crate":
			var box := Rect2(p - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6)
			draw_rect(box, WOOD.lightened(0.15))
			draw_rect(box, WOOD.darkened(0.4), false, 3.0)
			draw_line(box.position, box.end, WOOD.darkened(0.3), 3.0)
			draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), WOOD.darkened(0.3), 3.0)
		"monitor":
			draw_rect(Rect2(p - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.5)), Color("b8b8b0"))
			draw_rect(Rect2(p - Vector2(r * 0.8, r * 0.6), Vector2(r * 1.6, r * 1.1)), Color("1a2a4a"))
			draw_string(ThemeDB.fallback_font, p + Vector2(-r * 0.7, 2), ":(", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("7fb8e0"))
		"cable_tree":
			draw_line(p + Vector2(0, r * 0.4), p - Vector2(0, r * 0.8), Color("2a2a30"), 7.0)
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.5
				var tip := p - Vector2(0, r * 0.6) + Vector2.from_angle(a) * r
				var color: Color = [Color("c84b4b"), Color("4b8bd6"), Color("5cb85c"), Color("d9a441"), Color("8a8a8a")][k]
				draw_line(p - Vector2(0, r * 0.5), tip, color, 3.0, true)
				draw_circle(tip, 3.0, color)
		"pillar":
			draw_circle(p, r, Color("6a6458"))
			draw_circle(p, r * 0.8, Color("807868"))
			draw_arc(p, r * 0.55, 0.0, TAU, 20, Color("5a5448"), 2.0)
		"rubble":
			for k in 5:
				var q := p + Vector2.from_angle(seed_value + k * 2.1) * r * 0.5
				draw_circle(q, r * (0.25 + 0.08 * (k % 3)), Color("6a6458").darkened(0.1 * k))
		"puddle":
			draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r, Color("4a2a6a"))
			draw_circle(Vector2.ZERO, r * 0.7, Color("6a3a9a"))
			draw_set_transform(Vector2.ZERO)
			var bubble := fmod(_time * 0.7 + seed_value % 10, 1.0)
			draw_circle(p + Vector2(r * 0.3, -bubble * 10.0), 3.0, Color(0.8, 0.6, 1.0, 1.0 - bubble))
		"dead_tree":
			draw_line(p + Vector2(0, r * 0.4), p - Vector2(0, r), Color("3a2e26"), 6.0)
			draw_line(p - Vector2(0, r * 0.4), p + Vector2(r * 0.8, -r * 1.1), Color("3a2e26"), 4.0)
			draw_line(p - Vector2(0, r * 0.6), p + Vector2(-r * 0.7, -r * 1.2), Color("3a2e26"), 4.0)
		"tomb":
			var stone := Rect2(p - Vector2(r * 0.7, r), Vector2(r * 1.4, r * 1.6))
			draw_rect(stone, Color("6a6872"))
			draw_circle(stone.position + Vector2(stone.size.x / 2.0, 0), r * 0.7, Color("6a6872"))
			draw_string(ThemeDB.fallback_font, stone.position + Vector2(0, r * 0.7), "RIP", HORIZONTAL_ALIGNMENT_CENTER, stone.size.x, 11, Color("2a2830"))
			draw_string(ThemeDB.fallback_font, stone.position + Vector2(0, r * 1.2), "v1.0", HORIZONTAL_ALIGNMENT_CENTER, stone.size.x, 9, Color("2a2830"))
		"rack":
			var box := Rect2(p - Vector2(r * 0.75, r), Vector2(r * 1.5, r * 2.0))
			draw_rect(box, Color("23262e"))
			draw_rect(box, Color("4a4f5c"), false, 2.0)
			for k in 6:
				var y := box.position.y + 6.0 + k * (box.size.y - 12.0) / 6.0
				draw_line(Vector2(box.position.x + 4, y), Vector2(box.end.x - 4, y), Color("3a3f4a"), 1.0)
				var on := sin(_time * (2.0 + k) + seed_value) > 0.0
				draw_circle(Vector2(box.end.x - 8, y + 4), 2.0, Color("3cff6a") if on else Color("1a4a2a"))
		"cable_coil":
			for k in 3:
				draw_arc(p, r * (1.0 - k * 0.25), 0.0, TAU, 20, Color("2a2a30").lightened(k * 0.1), 4.0, true)
		_:
			draw_circle(p, r, Color("4a4352"))


func _draw_camp() -> void:
	var c := rect.get_center()
	_draw_tent(c + Vector2(-380, -330), Color("6b2b2b"))
	_draw_tent(c + Vector2(390, -360), Color("2b4a6b"))
	_draw_tent(c + Vector2(-320, 330), Color("3a5a3a"))
	_draw_crates(c + Vector2(330, 250))
	_draw_crates(c + Vector2(-480, 120))
	_draw_campfire(c + Vector2(0, -20))
	# Empalizada en el borde (con huecos en las salidas).
	var step := 44.0
	var x := rect.position.x + 20.0
	while x < rect.end.x - 20.0:
		for y in [rect.position.y + 20.0, rect.end.y - 20.0]:
			_draw_post(Vector2(x, y))
		x += step
	var y2 := rect.position.y + 64.0
	while y2 < rect.end.y - 40.0:
		for xx in [rect.position.x + 20.0, rect.end.x - 20.0]:
			var gap := false
			for e in exits:
				if absf(e["pos"].y - y2) < 120.0 and absf(e["pos"].x - xx) < 200.0:
					gap = true
			if not gap:
				_draw_post(Vector2(xx, y2))
		y2 += step
	var board := Rect2(c + Vector2(-150, -470), Vector2(300, 36))
	draw_rect(board, WOOD.lightened(0.1))
	draw_rect(board, WOOD.darkened(0.4), false, 2.0)
	draw_string(ThemeDB.fallback_font, board.position + Vector2(0, 24), zone_name, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 15, Color("f0e0c0"))


func _draw_post(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-5, -26), Vector2(10, 26)), WOOD)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -26), p + Vector2(0, -34), p + Vector2(5, -26)]), WOOD.lightened(0.1))


func _draw_tent(pos: Vector2, color: Color) -> void:
	draw_set_transform(pos + Vector2(0, 6), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-60, 0), pos + Vector2(0, -70), pos + Vector2(60, 0)]), color)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, 0), pos + Vector2(0, -42), pos + Vector2(14, 0)]), Color(0.05, 0.04, 0.05))
	draw_line(pos + Vector2(0, -70), pos + Vector2(0, -80), WOOD, 3.0)


func _draw_crates(pos: Vector2) -> void:
	for offset in [Vector2(0, 0), Vector2(26, 6), Vector2(10, -22)]:
		var r := Rect2(pos + offset, Vector2(24, 22))
		draw_rect(r, WOOD.lightened(0.15))
		draw_rect(r, WOOD.darkened(0.4), false, 2.0)


func _draw_campfire(pos: Vector2) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 9.0) * sin(_time * 5.3)
	draw_circle(pos, 170.0 * flicker, Color(1.0, 0.55, 0.2, 0.05))
	draw_circle(pos, 95.0 * flicker, Color(1.0, 0.6, 0.25, 0.06))
	for k in 8:
		draw_circle(pos + Vector2.from_angle(TAU * k / 8.0) * Vector2(26, 12), 5.0, Color("4a4550"))
	draw_line(pos + Vector2(-18, 6), pos + Vector2(18, -4), WOOD, 6.0)
	draw_line(pos + Vector2(-18, -4), pos + Vector2(18, 6), WOOD.darkened(0.2), 6.0)
	for layer in [[Color("e0652f"), 16.0, 34.0], [Color("f0a030"), 11.0, 24.0], [Color("ffe070"), 6.0, 14.0]]:
		var w: float = layer[1]
		var h: float = layer[2] * (0.85 + 0.2 * sin(_time * 11.0 + w))
		var sway := sin(_time * 6.0 + w) * 3.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-w, 0), pos + Vector2(sway, -h), pos + Vector2(w, 0)]), layer[0])


func _draw_exit(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var glow := 0.5 + 0.5 * sin(_time * 3.0)
	draw_set_transform(p, 0.0, Vector2(0.55, 1.0))
	draw_circle(Vector2.ZERO, EXIT_RADIUS + 10.0, Color(0.3, 0.6, 1.0, 0.08 + 0.06 * glow))
	draw_circle(Vector2.ZERO, EXIT_RADIUS, Color(0.15, 0.3, 0.6, 0.35))
	draw_arc(Vector2.ZERO, EXIT_RADIUS, 0.0, TAU, 40, Color(0.5, 0.8, 1.0, 0.6 + 0.4 * glow), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	var font := ThemeDB.fallback_font
	var label: String = ("← %s" if p.x < rect.get_center().x else "%s →") % e["label"]
	draw_string_outline(font, p + Vector2(-110, -EXIT_RADIUS - 18), label, HORIZONTAL_ALIGNMENT_CENTER, 220, 15, 5, Color.BLACK)
	draw_string(font, p + Vector2(-110, -EXIT_RADIUS - 18), label, HORIZONTAL_ALIGNMENT_CENTER, 220, 15, Color("a0d0ff"))


func _draw_waypoint() -> void:
	var p := waypoint
	var discovered: bool = character != null and character.flags.get("waypoints", []).has(id)
	var color := Color("5cd0ff") if discovered else Color("8a8293")
	var pts := PackedVector2Array()
	for k in 6:
		pts.append(p + Vector2.from_angle(TAU * k / 6.0 + PI / 6.0) * Vector2(WAYPOINT_RADIUS, WAYPOINT_RADIUS * 0.6))
	draw_colored_polygon(pts, Color("2a2f3a"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), color.darkened(0.2), 3.0, true)
	var pulse := fmod(_time * 0.6, 1.0)
	draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
	draw_arc(Vector2.ZERO, WAYPOINT_RADIUS * (0.3 + 0.6 * pulse), 0.0, TAU, 32, Color(color, 1.0 - pulse), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	# Columna de luz.
	draw_rect(Rect2(p + Vector2(-5, -70), Vector2(10, 70)), Color(color, 0.25 + 0.15 * sin(_time * 4.0)))
	var font := ThemeDB.fallback_font
	draw_string_outline(font, p + Vector2(-80, -80), "Waypoint", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, 5, Color.BLACK)
	draw_string(font, p + Vector2(-80, -80), "Waypoint", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, color)


func _draw_npcs() -> void:
	var font := ThemeDB.fallback_font
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		var pos := npc_position(npc)
		var appearance := CharacterAppearance.sanitize(npc.get("appearance", {}))
		var to_player := player.global_position - pos if player else Vector2.DOWN
		CharacterAppearance.draw(self, pos, 0.95, appearance, Vector2(signf(to_player.x) * 0.5, 1.0))
		var label_color := UiStyle.ACCENT if i == _hovered_npc else UiStyle.TEXT
		var label_pos := pos + Vector2(-110.0, -52.0)
		draw_string_outline(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, 5, Color(0, 0, 0, 0.8))
		draw_string(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, label_color)
		if character and not character.flags.has("talked_" + npc["id"]):
			var bounce := sin(_time * 4.0) * 3.0
			draw_string_outline(font, pos + Vector2(-10.0, -70.0 + bounce), "!", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, 5, Color.BLACK)
			draw_string(font, pos + Vector2(-10.0, -70.0 + bounce), "!", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, UiStyle.ACCENT)
