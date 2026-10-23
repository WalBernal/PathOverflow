class_name Zone
extends Node2D
## Una zona del acto (data/act1.json): suelo, bordes irregulares (acantilados,
## agua, maleza, muros...), accidentes del terreno (lagos, colinas, simas),
## obstáculos con colisión, salidas, waypoint, NPCs y objetos de misión. Todo se
## coloca con una semilla fija por zona (siempre igual) y sin tapar el camino
## entre entradas, salidas y puntos de interés. Se dibuja con formas mientras no
## haya arte: lo estático en una capa que se dibuja una vez y lo animado aquí.
##
## Click en un NPC o en el waypoint: el jugador camina hasta él.
## Pisar una salida: se viaja a la zona de destino.

signal npc_interacted(npc: Dictionary)
signal exit_reached(exit: Dictionary)
signal waypoint_clicked
signal stash_clicked
signal waypoint_touched
signal quest_item_picked(item: Dictionary)
signal key_item_picked(item: Dictionary)
signal challenge_touched(challenge: Dictionary)
signal exit_blocked(exit: Dictionary)

const NPC_DATA_PATH := "res://data/npcs.json"
const TALK_RANGE := 70.0
const CLICK_RADIUS := 28.0
const EXIT_RADIUS := 55.0
const WAYPOINT_RADIUS := 46.0
const STASH_RADIUS := 40.0
const QUEST_ITEM_RADIUS := 40.0
## Tamaño de los objetos de misión (QuestItemArt) en el mundo.
const QUEST_ITEM_SCALE := 1.3
const BORDER := 260.0
## Distancia mínima de un obstáculo a entradas, salidas, NPCs y waypoint.
const CLEAR_RADIUS := 200.0
## Medio ancho del pasillo libre entre puntos de interés.
const CORRIDOR := 110.0
## Bordes irregulares: profundidad (hacia dentro) muestreada cada EDGE_STEP píxeles.
const EDGE_STEP := 40.0
const EDGE_MAX := 230.0
const OBSTACLE_RADIUS := {
	"rock": 34.0, "crate": 26.0, "monitor": 24.0, "cable_tree": 32.0, "pillar": 34.0, "rubble": 30.0,
	"puddle": 46.0, "dead_tree": 28.0, "tomb": 24.0, "rack": 32.0, "cable_coil": 26.0,
	"piston": 30.0, "heat_sink": 40.0, "barrel": 22.0, "ice_block": 30.0, "capacitor": 24.0, "chip_die": 34.0,
}
const CHALLENGE_RADIUS := 60.0
## Radio de la "arena" de una prueba de estrés activa.
const CHALLENGE_ARENA := 520.0
## Accidentes del terreno: radio mínimo y máximo.
const FEATURE_RADIUS := {
	"lake": [110.0, 160.0], "hill": [100.0, 150.0], "cliff": [100.0, 160.0], "chasm": [90.0, 140.0],
	"bog": [110.0, 160.0], "data_lake": [100.0, 150.0], "void": [80.0, 130.0], "lava": [80.0, 120.0],
}
const STYLES := {
	"sandbox": {"ground": "1c2630", "decal": "26323e", "edge": "void", "outside": "05070a"},
	"camp": {"ground": "231d17", "decal": "2b241c", "edge": "", "outside": "120f0c"},
	"forest": {"ground": "151d15", "decal": "1d281c", "edge": "thicket", "outside": "0a120a"},
	"ruins": {"ground": "24201b", "decal": "2e2922", "edge": "cliff", "outside": "2a241e"},
	"swamp": {"ground": "161c1a", "decal": "2a1f33", "edge": "water", "outside": "0e1820"},
	"catacombs": {"ground": "1a181e", "decal": "232029", "edge": "wall", "outside": "0b0a0e"},
	"servers": {"ground": "13161c", "decal": "1b2029", "edge": "racks", "outside": "08090c"},
	"boss": {"ground": "1a0f12", "decal": "2a1418", "edge": "lava", "outside": "2a0808"},
	"kernel": {"ground": "11161a", "decal": "1c262c", "edge": "void", "outside": "030405"},
	"terminal": {"ground": "0c1810", "decal": "15301f", "edge": "racks", "outside": "040906"},
	"fabrica": {"ground": "1e1a16", "decal": "2a241c", "edge": "wall", "outside": "0c0a08"},
	"alcantarillas": {"ground": "141c1c", "decal": "1c2a2a", "edge": "water", "outside": "081014"},
	"fosa": {"ground": "1c1814", "decal": "28221a", "edge": "cliff", "outside": "0e0c0a"},
	"grieta": {"ground": "16161a", "decal": "222228", "edge": "cliff", "outside": "060608"},
	"bus": {"ground": "10141c", "decal": "1a2230", "edge": "void", "outside": "04060a"},
	"anillo": {"ground": "1e1210", "decal": "2e1a14", "edge": "lava", "outside": "200806"},
	"frio": {"ground": "141c24", "decal": "1e2c38", "edge": "water", "outside": "08101a"},
	# Acto III: el Silicio Profundo.
	"silicio": {"ground": "141a22", "decal": "203040", "edge": "void", "outside": "04060a"},
	"bios": {"ground": "0e1a3c", "decal": "1a2c60", "edge": "racks", "outside": "040818"},
	"rom": {"ground": "1a1428", "decal": "2c2244", "edge": "cliff", "outside": "0a0612"},
	"flash": {"ground": "1e1418", "decal": "321c26", "edge": "lava", "outside": "1c0606"},
}
const PHOSPHOR := Color("3cff6a")
const TERMINAL_LINES := [
	"$ ssh rafa@socket-seguro -p 2222", "Permission denied (publickey).", "$ sudo !!", "rafa no está en el archivo sudoers.",
	"$ ping la-red-lince.net", "Request timeout for icmp_seq 0", "$ crontab -l -u pepe", "0 18 * * 5 /opt/pepe/limpieza_final.sh  # 🐟",
	"$ ps aux | wc -l", "8193", "$ kill -9 1", "bash: kill: (1) - Operation not permitted",
]
const WOOD := Color("5b3f27")

static var _npc_db: Dictionary = {}

var def: Dictionary
var id := ""
var zone_name := ""
var level := 1
var style := "sandbox"
var rect := Rect2()
var safe := false
var obstacles: Array[Dictionary] = []   # {pos, radius, kind, seed, feature?, blob?}
var exits: Array[Dictionary] = []       # {pos, target, entry, label, requires_flag?, portal?}
var has_waypoint := false
var waypoint := Vector2.ZERO
## Alijo de la cuenta (cofre en los campamentos).
var has_stash := false
var stash_pos := Vector2.ZERO
var npcs: Array = []                    # como en npcs.json + "position"
var quest_items: Array = []             # {id, name, pos, quest}
var key_items: Array = []               # {id, pos} (objetos clave que van a la bolsa)
var challenges: Array = []              # pruebas de estrés: {id, pos, name, waves, ...}
var props: Array = []                   # decorado especial (gigantes de hierro...)
## Prueba de estrés en curso (World la pone): se dibuja la arena.
var active_challenge: Dictionary = {}
var dialogues: Dictionary = {}
var player: Player
var character: CharacterData
var quests: QuestLog
## Contorno de la zona transitable (para el minimapa y la colisión).
var walk_polygon := PackedVector2Array()

var _edges := {}                        # "top"/"bottom"/"left"/"right" -> PackedFloat32Array
var _edge_props: Array[Dictionary] = [] # adornos del borde: {pos, out, seed}
var _decals: Array[Dictionary] = []
var _ground_layer: Node2D
var _pending: Dictionary = {}           # {"kind": "npc"|"waypoint", "npc": {...}}
var _hovered_npc := -1
var _time := 0.0
var _exits_armed := false
var _challenge_armed := true


static func npc_database() -> Dictionary:
	if _npc_db.is_empty():
		var data = DataLoader.load_json(NPC_DATA_PATH)
		if data is Dictionary:
			_npc_db = data
	return _npc_db


func setup(p_def: Dictionary, p_player: Player, p_character: CharacterData, p_quests: QuestLog = null) -> void:
	def = p_def
	player = p_player
	character = p_character
	quests = p_quests
	id = def["id"]
	zone_name = def.get("name", id)
	level = int(def.get("level", 1))
	style = def.get("style", "sandbox")
	safe = bool(def.get("safe", false))
	rect = Rect2(Vector2.ZERO, Vector2(def["size"][0], def["size"][1]))
	for e in def.get("exits", []):
		var exit := {"pos": _v(e["pos"]), "target": e["target"], "entry": e.get("entry", ""), "label": e.get("label", "")}
		for key in ["requires_flag", "requires_item", "show_locked", "locked_message", "portal", "message", "cutscene"]:
			if e.has(key):
				exit[key] = e[key]
		exits.append(exit)
	if def.has("waypoint"):
		has_waypoint = true
		waypoint = _v(def["waypoint"])
	if def.has("stash"):
		has_stash = true
		stash_pos = _v(def["stash"])
	for q in def.get("quest_items", []):
		var entry: Dictionary = q.duplicate()
		entry["pos"] = _v(q["pos"])
		entry["name"] = q.get("name", q["id"])
		entry["quest"] = q.get("quest", "")
		quest_items.append(entry)
	for k in def.get("key_items", []):
		key_items.append({"id": k["id"], "pos": _v(k["pos"])})
	for c in def.get("challenges", []):
		var entry: Dictionary = c.duplicate()
		entry["pos"] = _v(c["pos"])
		challenges.append(entry)
	for p in def.get("props", []):
		var entry: Dictionary = p.duplicate()
		entry["pos"] = _v(p["pos"])
		props.append(entry)
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
	_build_edges(rng)
	_place_features(rng)
	_place_obstacles(rng)
	_make_decals(rng)
	_build_collision()
	_ground_layer = Node2D.new()
	_ground_layer.show_behind_parent = true
	_ground_layer.draw.connect(_draw_static)
	add_child(_ground_layer)


func entry_point(key: String) -> Vector2:
	var entries: Dictionary = def.get("entries", {})
	if entries.has(key):
		return _v(entries[key])
	return _v(entries.values()[0]) if not entries.is_empty() else rect.get_center()


func npc_position(npc: Dictionary) -> Vector2:
	return _v(npc["position"])


## Puntos de interés: entradas, salidas, waypoint, NPCs, objetos de misión y jefe.
func key_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for e in def.get("entries", {}).values():
		points.append(_v(e))
	for e in def.get("exits", []):
		points.append(_v(e["pos"]))
	if def.has("waypoint"):
		points.append(_v(def["waypoint"]))
	for placement in def.get("npcs", []):
		points.append(_v(placement["pos"]))
	for q in def.get("quest_items", []):
		points.append(_v(q["pos"]))
	for k in def.get("key_items", []):
		points.append(_v(k["pos"]))
	for c in def.get("challenges", []):
		points.append(_v(c["pos"]))
	for p in def.get("props", []):
		points.append(_v(p["pos"]))
	for p in def.get("extra_points", []):
		points.append(_v(p))
	if def.has("boss"):
		points.append(_v(def["boss"]["pos"]))
	return points


## Centros de los grupos de enemigos: repartidos por la zona, lejos de los
## puntos de interés, de los obstáculos y entre sí.
## `keep_away`: distancia mínima a la entrada inicial ("start") y a los NPCs de
## la zona (el tutorial la usa para que B.O.B. pueda explicar antes de pelear).
func pack_centers(count: int, rng: RandomNumberGenerator, keep_away := 0.0) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var keys := key_points()
	var safe_points: Array[Vector2] = []
	if keep_away > 0.0:
		safe_points.append(entry_point("start"))
		for npc in def.get("npcs", []):
			safe_points.append(_v(npc["pos"]))
	var inner := rect.grow(-220.0)
	for attempt in 1500:
		if result.size() >= count:
			break
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		var ok := is_walkable(p, 90.0)
		for s in safe_points:
			if ok and p.distance_to(s) < keep_away:
				ok = false
		for k in keys:
			if ok and p.distance_to(k) < 450.0:
				ok = false
		for other in result:
			if ok and p.distance_to(other) < 380.0:
				ok = false
		if ok:
			result.append(p)
	return result


# --- Terreno transitable ---

## Profundidad del borde `edge` en la coordenada `t` (x para arriba/abajo, y para los lados).
func edge_depth(edge: String, t: float) -> float:
	var arr: PackedFloat32Array = _edges.get(edge, PackedFloat32Array())
	if arr.is_empty():
		return 0.0
	var f := clampf(t / EDGE_STEP, 0.0, arr.size() - 1.0)
	var i := mini(int(f), arr.size() - 2)
	if i < 0:
		return arr[0]
	return lerpf(arr[i], arr[i + 1], f - i)


## Lleva un punto dentro de los bordes (sin mirar obstáculos). Barato: lo usan
## todos los enemigos en cada tick.
func clamp_to_walkable(p: Vector2, margin := 0.0) -> Vector2:
	var lx := p.x - rect.position.x
	var ly := p.y - rect.position.y
	var top := rect.position.y + edge_depth("top", lx) + margin
	var bottom := rect.end.y - edge_depth("bottom", lx) - margin
	var left := rect.position.x + edge_depth("left", ly) + margin
	var right := rect.end.x - edge_depth("right", ly) - margin
	return Vector2(clampf(p.x, left, maxf(left, right)), clampf(p.y, top, maxf(top, bottom)))


func is_walkable(p: Vector2, margin := 0.0) -> bool:
	if clamp_to_walkable(p, margin) != p:
		return false
	for o in obstacles:
		if p.distance_to(o["pos"]) < o["radius"] + margin:
			return false
	return true


## El punto transitable más cercano a `p` (búsqueda en espiral).
func free_spot_near(p: Vector2, margin := 20.0) -> Vector2:
	if is_walkable(p, margin):
		return p
	for ring in range(1, 20):
		var r := ring * 24.0
		for k in 12:
			var q := p + Vector2.from_angle(TAU * k / 12.0 + ring * 0.4) * r
			if is_walkable(q, margin):
				return q
	return clamp_to_walkable(p, margin)


# --- Construcción ---

## Bordes irregulares: suma de senos con fase aleatoria, que se abre cerca de
## salidas y puntos de interés para no taparlos. El campamento mantiene su
## empalizada recta.
func _build_edges(rng: RandomNumberGenerator) -> void:
	var keys := key_points()
	var irregular: bool = STYLES.get(style, {}).get("edge", "") != ""
	for edge in ["top", "bottom", "left", "right"]:
		var horizontal: bool = edge == "top" or edge == "bottom"
		var length := rect.size.x if horizontal else rect.size.y
		var n := int(ceil(length / EDGE_STEP)) + 1
		var arr := PackedFloat32Array()
		arr.resize(n)
		var base := rng.randf_range(70.0, 110.0)
		var waves: Array[Vector3] = []   # amplitud, frecuencia, fase
		waves.append(Vector3(rng.randf_range(45.0, 75.0), rng.randf_range(1.0 / 330.0, 1.0 / 200.0), rng.randf() * TAU))
		waves.append(Vector3(rng.randf_range(20.0, 35.0), rng.randf_range(1.0 / 110.0, 1.0 / 70.0), rng.randf() * TAU))
		waves.append(Vector3(rng.randf_range(6.0, 12.0), rng.randf_range(1.0 / 30.0, 1.0 / 22.0), rng.randf() * TAU))
		for i in n:
			var t := i * EDGE_STEP
			var d := 0.0
			if irregular:
				d = base
				for w in waves:
					d += w.x * sin(t * w.y + w.z)
				d = clampf(d, 20.0, EDGE_MAX)
				# Abrir paso a los puntos de interés cercanos a este borde.
				for k in keys:
					var along := k.x if horizontal else k.y
					var dist_to_edge: float = {"top": k.y - rect.position.y, "bottom": rect.end.y - k.y,
						"left": k.x - rect.position.x, "right": rect.end.x - k.x}[edge]
					var allowed := maxf(6.0, dist_to_edge - 70.0)
					var w := smoothstep(90.0, 240.0, absf(t - along))
					d = minf(d, lerpf(allowed, EDGE_MAX, w))
			arr[i] = d
		_edges[edge] = arr
	_build_walk_polygon()
	if irregular:
		_build_edge_props(rng)


## Contorno transitable: recorre los cuatro bordes recortando las esquinas para
## que coincida con clamp_to_walkable().
func _build_walk_polygon() -> void:
	var pts := PackedVector2Array()
	var o := rect.position
	var w := rect.size.x
	var h := rect.size.y
	var x := 0.0
	while x <= w:
		var y := edge_depth("top", x)
		if x >= edge_depth("left", y) and x <= w - edge_depth("right", y):
			pts.append(o + Vector2(x, y))
		x += EDGE_STEP
	var y2 := 0.0
	while y2 <= h:
		var xr := w - edge_depth("right", y2)
		if y2 >= edge_depth("top", xr) and y2 <= h - edge_depth("bottom", xr):
			pts.append(o + Vector2(xr, y2))
		y2 += EDGE_STEP
	x = w
	while x >= 0.0:
		var yb := h - edge_depth("bottom", x)
		if x >= edge_depth("left", yb) and x <= w - edge_depth("right", yb):
			pts.append(o + Vector2(x, yb))
		x -= EDGE_STEP
	y2 = h
	while y2 >= 0.0:
		var xl := edge_depth("left", y2)
		if y2 >= edge_depth("top", xl) and y2 <= h - edge_depth("bottom", xl):
			pts.append(o + Vector2(xl, y2))
		y2 -= EDGE_STEP
	walk_polygon = pts


func _build_edge_props(rng: RandomNumberGenerator) -> void:
	var n := walk_polygon.size()
	var centroid := rect.get_center()
	for i in range(0, n, 2):
		var p := walk_polygon[i]
		var out := (p - centroid).normalized()
		# Hacia fuera según el borde más cercano (más natural que desde el centro).
		var d_left := p.x - rect.position.x
		var d_right := rect.end.x - p.x
		var d_top := p.y - rect.position.y
		var d_bottom := rect.end.y - p.y
		var m := minf(minf(d_left, d_right), minf(d_top, d_bottom))
		if m == d_left:
			out = Vector2.LEFT
		elif m == d_right:
			out = Vector2.RIGHT
		elif m == d_top:
			out = Vector2.UP
		else:
			out = Vector2.DOWN
		_edge_props.append({"pos": p, "out": out, "seed": rng.randi(), "size": rng.randf_range(0.7, 1.3)})


## Accidentes grandes del terreno (lagos, colinas, simas...). Son obstáculos con
## forma irregular; su colisión es un círculo algo menor que el dibujo.
func _place_features(rng: RandomNumberGenerator) -> void:
	var cfg: Dictionary = def.get("features", {})
	var kinds: Array = cfg.get("kinds", [])
	var wanted := int(cfg.get("count", 0))
	if kinds.is_empty() or wanted <= 0:
		return
	var keys := key_points()
	var path := _key_path(keys)
	for attempt in wanted * 60:
		if obstacles.size() >= wanted:
			break
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var range_r: Array = FEATURE_RADIUS.get(kind, [100.0, 140.0])
		var visual := rng.randf_range(range_r[0], range_r[1])
		var radius := visual * 0.82
		var inner := rect.grow(-visual - 60.0)
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if not _spot_is_free(p, radius, keys, path, 160.0):
			continue
		var blob := PackedVector2Array()
		var phase := rng.randf() * TAU
		for k in 20:
			var a := TAU * k / 20.0
			var rr := visual * (0.88 + 0.08 * sin(a * 3.0 + phase) + 0.05 * sin(a * 5.0 + phase * 2.0))
			blob.append(Vector2.from_angle(a) * rr)
		obstacles.append({"pos": p, "radius": radius, "kind": kind, "seed": rng.randi(), "feature": true,
			"blob": blob, "visual": visual})


func _place_obstacles(rng: RandomNumberGenerator) -> void:
	var cfg: Dictionary = def.get("obstacles", {})
	var kinds: Array = cfg.get("kinds", [])
	var wanted := int(cfg.get("count", 0)) + obstacles.size()
	if kinds.is_empty() or wanted <= obstacles.size():
		return
	var keys := key_points()
	var path := _key_path(keys)
	var inner := rect.grow(-90.0)
	for attempt in wanted * 40:
		if obstacles.size() >= wanted:
			break
		var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var radius: float = OBSTACLE_RADIUS.get(kind, 30.0)
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if _spot_is_free(p, radius, keys, path, 70.0):
			obstacles.append({"pos": p, "radius": radius, "kind": kind, "seed": rng.randi()})


## Pasillo: une los puntos de interés de oeste a este.
func _key_path(keys: Array[Vector2]) -> Array[Vector2]:
	var path := keys.duplicate()
	path.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return path


func _spot_is_free(p: Vector2, radius: float, keys: Array[Vector2], path: Array[Vector2], spacing: float) -> bool:
	if not is_walkable(p, radius + 20.0):
		return false
	for k in keys:
		if p.distance_to(k) < CLEAR_RADIUS + radius:
			return false
	for i in path.size() - 1:
		if Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1]).distance_to(p) < CORRIDOR + radius:
			return false
	for o in obstacles:
		if p.distance_to(o["pos"]) < radius + o["radius"] + spacing:
			return false
	return true


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
	# Bordes del mapa (por si acaso) y el contorno irregular.
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
	if STYLES.get(style, {}).get("edge", "") != "" and walk_polygon.size() >= 3:
		var outline := CollisionPolygon2D.new()
		outline.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		outline.polygon = walk_polygon
		body.add_child(outline)
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

func exit_open(e: Dictionary) -> bool:
	return exit_visible(e) and not exit_blocked_reason(e) != ""


## Las salidas con requires_flag no se ven hasta tener la bandera, salvo las
## marcadas show_locked (se ven con candado). Las de requires_item, siempre.
func exit_visible(e: Dictionary) -> bool:
	if e.has("requires_flag") and not (character != null and character.flags.has(e["requires_flag"])):
		return e.get("show_locked", false)
	return true


## "" si se puede pasar; si no, el motivo (para el aviso).
func exit_blocked_reason(e: Dictionary) -> String:
	if e.has("requires_flag") and not (character != null and character.flags.has(e["requires_flag"])):
		return e.get("locked_message", "Bloqueado.")
	if e.has("requires_item") and not (character != null and KeyItem.has_key(character.inventory, e["requires_item"])):
		return e.get("locked_message", "Necesitas %s en la bolsa." % KeyItem.DEFS.get(e["requires_item"], {}).get("name", e["requires_item"]))
	return ""


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if player == null or not player.is_alive():
		return
	var near_exit := false
	for e in exits:
		if exit_visible(e) and player.global_position.distance_to(e["pos"]) < EXIT_RADIUS:
			near_exit = true
			if _exits_armed:
				_exits_armed = false
				if exit_blocked_reason(e) != "":
					exit_blocked.emit(e)
				else:
					exit_reached.emit(e)
				return
	if not near_exit:
		_exits_armed = true
	if has_waypoint and player.global_position.distance_to(waypoint) < WAYPOINT_RADIUS + 60.0:
		waypoint_touched.emit()
	for q in quest_items:
		if quest_item_visible(q) and player.global_position.distance_to(q["pos"]) < QUEST_ITEM_RADIUS:
			quest_item_picked.emit(q)
	for k in key_items:
		if key_item_visible(k) and player.global_position.distance_to(k["pos"]) < QUEST_ITEM_RADIUS:
			key_item_picked.emit(k)
	var near_challenge := false
	for c in challenges:
		if challenge_available(c) and player.global_position.distance_to(c["pos"]) < CHALLENGE_RADIUS:
			near_challenge = true
			if _challenge_armed:
				_challenge_armed = false
				challenge_touched.emit(c)
	if not near_challenge:
		_challenge_armed = true


func key_item_visible(k: Dictionary) -> bool:
	return character != null and not character.flags.has("got_key_" + String(k["id"]))


## Disponible si no se ha superado ya y no hay otra en marcha.
func challenge_available(c: Dictionary) -> bool:
	return character != null and not character.flags.has("challenge_done_" + String(c["id"])) and active_challenge.is_empty()


func quest_item_visible(q: Dictionary) -> bool:
	if character == null or character.flags.has("item_" + String(q["id"])):
		return false
	return q["quest"] == "" or character.flags.has("quest_%s_started" % q["quest"])


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
		elif has_stash and mouse.distance_to(stash_pos) < STASH_RADIUS:
			_pending = {"kind": "stash"}
			player.move_to(stash_pos + Vector2(0, 34))
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var target: Vector2
	match String(_pending["kind"]):
		"waypoint":
			target = waypoint
		"stash":
			target = stash_pos
		_:
			target = npc_position(_pending["npc"])
	if player.global_position.distance_to(target) <= TALK_RANGE:
		player.stop_auto_move()
		player.face(target - player.global_position)
		if _pending["kind"] == "waypoint":
			waypoint_clicked.emit()
		elif _pending["kind"] == "stash":
			stash_clicked.emit()
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


# --- Dibujo estático (una sola vez) ---

func _draw_static() -> void:
	var s: Dictionary = STYLES.get(style, STYLES["sandbox"])
	var ground := Color(s["ground"])
	var layer := _ground_layer
	layer.draw_rect(rect.grow(BORDER), Color(s["outside"]))
	if walk_polygon.size() >= 3:
		layer.draw_colored_polygon(walk_polygon, ground)
	else:
		layer.draw_rect(rect, ground)
	_draw_decals(layer, Color(s["decal"]))
	if style == "camp":
		_draw_camp(layer)
	elif style == "terminal":
		_draw_hub_static(layer)
	_draw_edge_band(layer, s)
	for o in obstacles:
		if o.get("feature", false):
			_draw_feature(layer, o)


func _draw_decals(ci: CanvasItem, c: Color) -> void:
	for d in _decals:
		var p: Vector2 = d["pos"]
		if not is_walkable(p, 10.0):
			continue
		var sz: float = d["size"]
		match style:
			"sandbox", "servers", "catacombs":
				var tile := 80.0
				var cell := (p / tile).floor() * tile
				ci.draw_rect(Rect2(cell, Vector2(tile, tile)), Color(c, 0.8), false, 1.0)
			"forest":
				var pts := PackedVector2Array()
				for k in 6:
					pts.append(p + Vector2(k * sz / 5.0, sin(k + d["angle"]) * 10.0).rotated(d["angle"]))
				ci.draw_polyline(pts, [Color("2b5a3a"), Color("3a3a6a"), Color("6a3a3a")][int(d["seed"]) % 3], 2.0, true)
			"swamp":
				ci.draw_set_transform(p, d["angle"], Vector2(1.0, 0.5))
				ci.draw_circle(Vector2.ZERO, sz * 0.5, Color(c, 0.9))
				ci.draw_set_transform(Vector2.ZERO)
			"kernel":
				# Bus de datos: líneas rectas con un bit encendido.
				var q := p + Vector2(sz, 0).rotated(snappedf(d["angle"], PI / 2.0))
				ci.draw_line(p, q, Color(c, 0.9), 2.0)
				ci.draw_string(ThemeDB.fallback_font, p, "1" if int(d["seed"]) % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.6, 1.0, 0.25))
			"terminal":
				var tile := 64.0
				var cell := (p / tile).floor() * tile
				ci.draw_rect(Rect2(cell, Vector2(tile, tile)), Color(c, 0.9), false, 1.0)
			"boss":
				var q := p + Vector2(sz, 0).rotated(d["angle"])
				ci.draw_line(p, q, Color(c, 0.9), 2.0)
				ci.draw_circle(q, 3.0, Color(0.8, 0.2, 0.2, 0.35))
			"fabrica":
				# Planchas de metal remachadas y, a veces, franjas de peligro.
				var tile := 96.0
				var cell := (p / tile).floor() * tile
				ci.draw_rect(Rect2(cell + Vector2(2, 2), Vector2(tile - 4, tile - 4)), Color(c, 0.55))
				ci.draw_rect(Rect2(cell + Vector2(2, 2), Vector2(tile - 4, tile - 4)), Color(c.lightened(0.12), 0.6), false, 1.0)
				for corner in [Vector2(8, 8), Vector2(tile - 8, 8), Vector2(8, tile - 8), Vector2(tile - 8, tile - 8)]:
					ci.draw_circle(cell + corner, 2.0, Color(c.lightened(0.25), 0.7))
				if int(d["seed"]) % 4 == 0:
					for k in 5:
						var a := cell + Vector2(10 + k * 16, tile - 18)
						ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(8, 0), a + Vector2(16, 10), a + Vector2(8, 10)]), Color(0.85, 0.65, 0.1, 0.18))
			"alcantarillas":
				if int(d["seed"]) % 3 == 0:   # rejilla
					var g := Rect2(p - Vector2(22, 14), Vector2(44, 28))
					ci.draw_rect(g, Color(0, 0, 0, 0.35))
					for k in 6:
						ci.draw_line(g.position + Vector2(4 + k * 7, 2), g.position + Vector2(4 + k * 7, 26), Color(c.lightened(0.2), 0.8), 2.0)
				else:   # charco de datos
					ci.draw_set_transform(p, d["angle"], Vector2(1.0, 0.45))
					ci.draw_circle(Vector2.ZERO, sz * 0.5, Color(0.2, 0.55, 0.6, 0.18))
					ci.draw_arc(Vector2.ZERO, sz * 0.5, 0.0, TAU, 24, Color(0.4, 0.8, 0.85, 0.15), 2.0)
					ci.draw_set_transform(Vector2.ZERO)
			"fosa":
				# Restos de procesos: etiquetas <defunct> tiradas por el suelo.
				ci.draw_set_transform(p, d["angle"] * 0.3, Vector2.ONE)
				ci.draw_rect(Rect2(-30, -9, 60, 16), Color(c, 0.9))
				ci.draw_string(ThemeDB.fallback_font, Vector2(-27, 4), "<defunct>" if int(d["seed"]) % 2 == 0 else "PID %d" % (int(d["seed"]) % 9000 + 100),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.65, 0.5, 0.35))
				ci.draw_set_transform(Vector2.ZERO)
			"grieta":
				# Grietas en zigzag.
				var pts := PackedVector2Array([p])
				var dir := Vector2.from_angle(d["angle"])
				for k in 5:
					pts.append(pts[-1] + dir.rotated((0.6 if k % 2 == 0 else -0.6)) * sz * 0.25)
				ci.draw_polyline(pts, Color(0, 0, 0, 0.55), 3.0, true)
				ci.draw_polyline(pts, Color(0.55, 0.35, 0.9, 0.12), 1.0, true)
			"bus":
				# Carriles de datos con flechas.
				var dir := Vector2.from_angle(snappedf(d["angle"], PI / 2.0))
				ci.draw_line(p, p + dir * sz * 1.5, Color(0.3, 0.55, 1.0, 0.18), 3.0)
				for k in 3:
					var a := p + dir * (sz * 0.3 + k * sz * 0.4)
					ci.draw_colored_polygon(PackedVector2Array([a + dir * 8.0, a + dir.orthogonal() * 5.0, a - dir.orthogonal() * 5.0]), Color(0.4, 0.7, 1.0, 0.22))
			"anillo":
				# Pistas de circuito con soldaduras doradas.
				var a := p
				var b := a + Vector2(sz, 0).rotated(snappedf(d["angle"], PI / 4.0))
				var m := b + Vector2(sz * 0.5, 0).rotated(snappedf(d["angle"], PI / 2.0))
				ci.draw_polyline(PackedVector2Array([a, b, m]), Color(0.85, 0.55, 0.2, 0.22), 3.0, true)
				ci.draw_circle(a, 4.0, Color(0.95, 0.75, 0.3, 0.3))
				ci.draw_circle(m, 4.0, Color(0.95, 0.75, 0.3, 0.3))
			"frio":
				# Escarcha: cristales de seis puntas.
				for k in 3:
					var dir := Vector2.from_angle(d["angle"] + k * PI / 3.0)
					ci.draw_line(p - dir * sz * 0.35, p + dir * sz * 0.35, Color(0.75, 0.9, 1.0, 0.16), 2.0)
			"silicio":
				# Oblea: dados de silicio en cuadrícula con pistas doradas.
				var tile := 72.0
				var cell := (p / tile).floor() * tile
				ci.draw_rect(Rect2(cell + Vector2(3, 3), Vector2(tile - 6, tile - 6)), Color(c, 0.6), false, 1.0)
				if int(d["seed"]) % 3 == 0:
					ci.draw_line(cell + Vector2(8, tile * 0.5), cell + Vector2(tile - 8, tile * 0.5), Color(0.85, 0.65, 0.25, 0.22), 2.0)
					ci.draw_circle(cell + Vector2(tile - 8, tile * 0.5), 3.0, Color(0.95, 0.75, 0.3, 0.3))
			"bios":
				# Pantalla de configuración del BIOS: renglones de texto y cuadrícula.
				var tile := 64.0
				var cell := (p / tile).floor() * tile
				ci.draw_rect(Rect2(cell, Vector2(tile, tile)), Color(c, 0.5), false, 1.0)
				var words := ["Boot Order", "Secure Boot [ON]", "SATA Mode", "CPU Ratio", "F10: Save", "Fan: Auto"]
				ci.draw_string(ThemeDB.fallback_font, cell + Vector2(6, 20), words[int(d["seed"]) % words.size()],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.9, 1.0, 0.16))
			"rom":
				# Cristales de la ROM: rombos de solo lectura.
				var s := sz * 0.35
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.6, 0), p + Vector2(0, s), p + Vector2(-s * 0.6, 0)]), Color(c, 0.75))
				ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), Color(0.7, 0.55, 1.0, 0.18), 1.0)
			"flash":
				# Celdas de memoria flash: barras de progreso a medio escribir.
				var w := sz * 0.9
				ci.draw_rect(Rect2(p - Vector2(w / 2.0, 4), Vector2(w, 8)), Color(c, 0.9))
				ci.draw_rect(Rect2(p - Vector2(w / 2.0, 4), Vector2(w * (0.3 + 0.69 * fmod(d["seed"] * 0.37, 1.0)), 8)), Color(0.9, 0.3, 0.25, 0.25))
			"ruins":
				# Baldosas rotas.
				ci.draw_set_transform(p, d["angle"] * 0.2, Vector2.ONE)
				ci.draw_rect(Rect2(-sz * 0.4, -sz * 0.3, sz * 0.8, sz * 0.6), Color(c, 0.85))
				ci.draw_line(Vector2(-sz * 0.3, -sz * 0.3), Vector2(sz * 0.1, sz * 0.3), Color(0, 0, 0, 0.35), 2.0)
				ci.draw_set_transform(Vector2.ZERO)
			_:
				ci.draw_set_transform(p, d["angle"], Vector2(1.0, 0.6))
				ci.draw_circle(Vector2.ZERO, sz * 0.4, Color(c, 0.7))
				ci.draw_set_transform(Vector2.ZERO)


## Banda del borde: lo que hay fuera del camino según el estilo de la zona.
func _draw_edge_band(ci: CanvasItem, s: Dictionary) -> void:
	var kind: String = s["edge"]
	if kind == "" or walk_polygon.size() < 3:
		return
	var ground := Color(s["ground"])
	var font := ThemeDB.fallback_font
	for e in _edge_props:
		var p: Vector2 = e["pos"]
		var out: Vector2 = e["out"]
		var sd: int = e["seed"]
		var k: float = e["size"]
		var side := out.orthogonal()
		match kind:
			"thicket":   # maleza y árboles de cables
				for j in 3:
					var q := p + out * (14.0 + j * 26.0) * k + side * ((sd >> j) % 30 - 15)
					ci.draw_circle(q, (22.0 - j * 3.0) * k, Color("18301a").lerp(Color("0f1f10"), j / 3.0))
					ci.draw_circle(q + Vector2(-5, -6), (10.0 - j * 2.0) * k, Color("24452a"))
				if sd % 4 == 0:
					var q := p + out * 50.0 * k
					ci.draw_line(q + Vector2(0, 10), q - Vector2(0, 34), Color("2a2a30"), 5.0)
					for j in 4:
						var tip := q - Vector2(0, 30) + Vector2.from_angle(-PI / 2.0 + (j - 1.5) * 0.6) * 22.0
						ci.draw_line(q - Vector2(0, 26), tip, [Color("c84b4b"), Color("4b8bd6"), Color("5cb85c"), Color("d9a441")][j], 2.0, true)
			"cliff":     # acantilado: rocas cada vez más altas hacia fuera
				for j in 3:
					var q := p + out * (18.0 + j * 30.0) * k + side * ((sd >> (j * 2)) % 24 - 12)
					var r := (26.0 + j * 8.0) * k
					var pts := PackedVector2Array()
					for a in 7:
						var rr := r * (0.75 + 0.25 * sin(sd + a * 1.9 + j))
						pts.append(q + Vector2.from_angle(TAU * a / 7.0) * Vector2(rr, rr * 0.8))
					ci.draw_colored_polygon(pts, Color("4a4238").darkened(j * 0.12))
					ci.draw_circle(q + Vector2(-r * 0.3, -r * 0.35), r * 0.25, Color("6a6052").darkened(j * 0.1))
			"water":     # agua turbia con juncos
				ci.draw_circle(p + out * 40.0 * k, 46.0 * k, Color("13222c"))
				if sd % 3 == 0:
					for j in 3:
						var q := p + out * 6.0 + side * (j * 7.0 - 7.0)
						ci.draw_line(q, q + Vector2(j - 1, -22.0 - j * 4.0), Color("3a5a2a"), 2.0)
				ci.draw_arc(p + out * 50.0 * k, 16.0 * k, PI * 1.1, PI * 1.9, 8, Color(0.5, 0.7, 0.8, 0.18), 1.5)
			"wall":      # muro de bloques de piedra
				for j in 3:
					var q := p + out * (10.0 + j * 24.0)
					var box := Rect2(q - Vector2(22, 12), Vector2(44, 24))
					ci.draw_rect(box, Color("2a2730").darkened(j * 0.15))
					ci.draw_rect(box, Color("17151b"), false, 2.0)
				if sd % 5 == 0:
					ci.draw_string(font, p + out * 24.0 + Vector2(-14, 4), "// RIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("4a4652"))
			"racks":     # pared de racks
				var q := p + out * 30.0
				var box := Rect2(q - Vector2(18, 26), Vector2(36, 52))
				ci.draw_rect(box, Color("1c1f26"))
				ci.draw_rect(box, Color("343944"), false, 2.0)
				for j in 4:
					ci.draw_line(box.position + Vector2(3, 8 + j * 11), box.position + Vector2(33, 8 + j * 11), Color("2a2e36"), 1.0)
				ci.draw_rect(Rect2(q + out * 30.0 - Vector2(24, 24), Vector2(48, 48)), Color("0c0e12"))
			"void":      # el vacío del sandbox: binario y rejilla
				ci.draw_line(p, p + out * 120.0, Color(0.2, 0.5, 0.8, 0.12), 1.0)
				for j in 3:
					var q := p + out * (22.0 + j * 30.0) + side * ((sd >> j) % 20 - 10)
					ci.draw_string(font, q, "1" if (sd >> (j + 3)) % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
						Color(0.3, 0.6, 1.0, 0.35 - j * 0.09))
			"lava":      # datos corruptos al rojo
				ci.draw_circle(p + out * 34.0 * k, 40.0 * k, Color("5a1010"))
				ci.draw_circle(p + out * 40.0 * k, 24.0 * k, Color("8a2010"))
				if sd % 3 == 0:
					ci.draw_string(font, p + out * 40.0 + Vector2(-10, 4), "0x%X" % (sd % 256), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffb070"))
	# Línea de orilla: separa el suelo del borde.
	var closed := walk_polygon.duplicate()
	closed.append(walk_polygon[0])
	ci.draw_polyline(closed, ground.lightened(0.18), 3.0, true)


## Parte estática de un accidente del terreno.
func _draw_feature(ci: CanvasItem, o: Dictionary) -> void:
	var p: Vector2 = o["pos"]
	var vis: float = o["visual"]
	var at := func(scale: float, offset: Vector2) -> PackedVector2Array:
		return _blob_points(o, scale, offset)
	match o["kind"]:
		"lake":
			ci.draw_colored_polygon(at.call(1.08, Vector2.ZERO), Color("2a3a22"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("142a40"))
			ci.draw_colored_polygon(at.call(0.7, Vector2(0, -6)), Color("1c3a55"))
		"bog":
			ci.draw_colored_polygon(at.call(1.08, Vector2.ZERO), Color("1d2a1d"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("2a1f33"))
			ci.draw_colored_polygon(at.call(0.65, Vector2.ZERO), Color("3a2a4a"))
		"data_lake":
			ci.draw_colored_polygon(at.call(1.08, Vector2.ZERO), Color("1b2029"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("08262c"))
			ci.draw_colored_polygon(at.call(0.7, Vector2.ZERO), Color("0c3238"))
			var outline: PackedVector2Array = at.call(1.0, Vector2.ZERO)
			outline.append(outline[0])
			ci.draw_polyline(outline, Color(0.2, 0.9, 0.8, 0.5), 2.0, true)
		"hill", "cliff":
			var base := Color("2c3a24") if o["kind"] == "hill" else Color("4a4036")
			ci.draw_colored_polygon(at.call(1.05, Vector2(0, 10)), Color(0, 0, 0, 0.35))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), base)
			ci.draw_colored_polygon(at.call(0.72, Vector2(-6, -16)), base.lightened(0.12))
			ci.draw_colored_polygon(at.call(0.42, Vector2(-10, -30)), base.lightened(0.25))
			if o["kind"] == "cliff":
				for k in 4:
					var q := p + Vector2.from_angle(int(o["seed"]) + k * 1.6) * vis * 0.5
					ci.draw_line(q, q + Vector2(10, 18), base.darkened(0.4), 2.0)
		"chasm":
			ci.draw_colored_polygon(at.call(1.08, Vector2.ZERO), Color("2a2630"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("0d0b10"))
			ci.draw_colored_polygon(at.call(0.75, Vector2(0, 6)), Color("050407"))
			ci.draw_colored_polygon(at.call(0.45, Vector2(0, 10)), Color("000000"))
		"void":
			ci.draw_colored_polygon(at.call(1.06, Vector2.ZERO), Color("1f3a55"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("020306"))
			for k in 5:
				var y := -vis * 0.6 + k * vis * 0.3
				ci.draw_line(p + Vector2(-vis * 0.6, y), p + Vector2(vis * 0.6, y), Color(0.2, 0.5, 0.9, 0.18), 1.0)
				ci.draw_line(p + Vector2(y, -vis * 0.6), p + Vector2(y, vis * 0.6), Color(0.2, 0.5, 0.9, 0.18), 1.0)
			ci.draw_string(ThemeDB.fallback_font, p + Vector2(-40, 8), "404", HORIZONTAL_ALIGNMENT_CENTER, 80, 26, Color(0.3, 0.6, 1.0, 0.35))
		"lava":
			ci.draw_colored_polygon(at.call(1.08, Vector2.ZERO), Color("3a1010"))
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("8a1a12"))
			ci.draw_colored_polygon(at.call(0.6, Vector2.ZERO), Color("d04020"))
		_:
			ci.draw_colored_polygon(at.call(1.0, Vector2.ZERO), Color("4a4352"))


## Contorno de un accidente del terreno, escalado y desplazado (en coordenadas de la zona).
static func _blob_points(o: Dictionary, scale: float, offset := Vector2.ZERO) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var p: Vector2 = o["pos"]
	for b: Vector2 in o["blob"]:
		pts.append(p + offset + b * scale)
	return pts


# --- Dibujo animado (cada frame) ---

func _draw() -> void:
	for o in obstacles:
		if o.get("feature", false):
			_draw_feature_anim(o)
		else:
			_draw_obstacle(o)
	if style == "camp":
		_draw_campfire(rect.get_center() + Vector2(0, -20))
	elif style == "terminal":
		_draw_hub_terminal()
	elif style == "kernel":
		_draw_kernel_flicker()
	for p in props:
		_draw_prop(p)
	for e in exits:
		if exit_visible(e):
			_draw_exit(e)
	for k in key_items:
		if key_item_visible(k):
			_draw_key_item(k)
	for c in challenges:
		if character and not character.flags.has("challenge_done_" + String(c["id"])):
			_draw_challenge(c)
	if has_waypoint:
		_draw_waypoint()
	if has_stash:
		_draw_stash()
	for q in quest_items:
		if quest_item_visible(q):
			_draw_quest_item(q)
	_draw_npcs()


func _draw_feature_anim(o: Dictionary) -> void:
	var p: Vector2 = o["pos"]
	var r: float = o["visual"]
	var sd: int = o["seed"]
	var font := ThemeDB.fallback_font
	match o["kind"]:
		"lake":
			for k in 2:
				var phase := fmod(_time * 0.3 + k * 0.5 + sd % 7 * 0.1, 1.0)
				draw_set_transform(p + Vector2(r * 0.2 * (k - 0.5), r * 0.1), 0.0, Vector2(1.0, 0.5))
				draw_arc(Vector2.ZERO, r * 0.15 + phase * r * 0.35, 0.0, TAU, 24, Color(0.6, 0.8, 1.0, 0.25 * (1.0 - phase)), 1.5, true)
				draw_set_transform(Vector2.ZERO)
		"bog":
			for k in 3:
				var phase := fmod(_time * 0.6 + k * 0.33 + sd % 5 * 0.2, 1.0)
				draw_circle(p + Vector2((k - 1) * r * 0.3, r * 0.1 - phase * 14.0), 3.0 + k, Color(0.8, 0.6, 1.0, 0.6 * (1.0 - phase)))
		"data_lake", "void":
			for k in 6:
				var phase := fmod(_time * 0.25 + k / 6.0, 1.0)
				var q := p + Vector2((k - 2.5) * r * 0.22, r * 0.45 - phase * r * 0.9)
				var bit := "1" if (sd + k + int(_time * 4.0)) % 2 == 0 else "0"
				draw_string(font, q, bit, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.3, 1.0, 0.85, 0.6 * sin(phase * PI)))
		"lava":
			var pulse := 0.5 + 0.5 * sin(_time * 2.0 + sd)
			draw_circle(p, r * 0.35, Color(1.0, 0.7, 0.3, 0.15 + 0.15 * pulse))
		"chasm":
			for k in 3:
				var phase := fmod(_time * 0.4 + k / 3.0, 1.0)
				draw_string(font, p + Vector2((k - 1) * r * 0.3, -r * 0.3 + phase * r * 0.5), "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 12,
					Color(0.6, 0.5, 0.9, 0.4 * (1.0 - phase)))


func _draw_obstacle(o: Dictionary) -> void:
	var p: Vector2 = o["pos"]
	var r: float = o["radius"]
	# Semilla pequeña: sumada a ángulos en float32, una de ~4e9 los colapsa a
	# todos en el mismo valor (polígono degenerado, error en cada frame).
	var seed_value: int = int(o["seed"]) % 10007
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
		"piston":
			# Pistón rítmico con vapor.
			var stroke := (0.5 + 0.5 * sin(_time * 3.0 + seed_value)) * r * 0.9
			draw_rect(Rect2(p + Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 0.9)), Color("5a4a3a"))
			draw_rect(Rect2(p + Vector2(-r * 0.25, -r * 1.2 - stroke), Vector2(r * 0.5, r + stroke)), Color("9a9ea8"))
			draw_rect(Rect2(p + Vector2(-r * 0.55, -r * 1.35 - stroke), Vector2(r * 1.1, r * 0.3)), Color("6a6e78"))
			var steam := fmod(_time * 0.8 + seed_value % 5 * 0.2, 1.0)
			draw_circle(p + Vector2(r * 0.6, -r * 0.4 - steam * 40.0), 6.0 + steam * 10.0, Color(0.9, 0.9, 0.95, 0.25 * (1.0 - steam)))
		"heat_sink":
			# Disipador: bloque de aletas (sirve de cobertura).
			draw_rect(Rect2(p - Vector2(r, r * 0.7), Vector2(r * 2.0, r * 1.4)), Color("8a9098"))
			for k in 7:
				var x := p.x - r + 4.0 + k * (r * 2.0 - 8.0) / 6.0
				draw_line(Vector2(x, p.y - r * 0.7), Vector2(x, p.y + r * 0.7), Color("5a6068"), 3.0)
			draw_rect(Rect2(p - Vector2(r, r * 0.7), Vector2(r * 2.0, r * 1.4)), Color("3a4048"), false, 2.0)
		"barrel":
			draw_rect(Rect2(p - Vector2(r * 0.8, r), Vector2(r * 1.6, r * 1.8)), Color("3a5a3a"))
			draw_line(p + Vector2(-r * 0.8, -r * 0.4), p + Vector2(r * 0.8, -r * 0.4), Color("2a3a2a"), 2.0)
			draw_line(p + Vector2(-r * 0.8, r * 0.3), p + Vector2(r * 0.8, r * 0.3), Color("2a3a2a"), 2.0)
			draw_string(ThemeDB.fallback_font, p + Vector2(-r * 0.7, 4), "0xFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9ad06a"))
		"capacitor":
			# Condensador electrolítico (cobertura contra los orbes).
			draw_rect(Rect2(p - Vector2(r * 0.7, r), Vector2(r * 1.4, r * 1.8)), Color("2a4a8a"))
			draw_rect(Rect2(p - Vector2(r * 0.7, r), Vector2(r * 0.35, r * 1.8)), Color("c8c8d0"))
			draw_set_transform(p + Vector2(0, -r), 0.0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, r * 0.7, Color("9a9aa4"))
			draw_set_transform(Vector2.ZERO)
			draw_line(p + Vector2(-r * 0.3, -r), p + Vector2(r * 0.3, -r), Color("5a5a62"), 2.0)
		"chip_die":
			# Encapsulado de un chip con sus patas.
			var box := Rect2(p - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6))
			for k in 6:
				var x := box.position.x + 6.0 + k * (box.size.x - 12.0) / 5.0
				draw_line(Vector2(x, box.position.y - 6), Vector2(x, box.end.y + 6), Color("c0a060"), 3.0)
			draw_rect(box, Color("1c1c22"))
			draw_rect(box.grow(-4), Color("26262e"))
			draw_circle(box.position + Vector2(10, 10), 3.0, Color("3a3a44"))
		"ice_block":
			var pts := PackedVector2Array()
			for k in 6:
				pts.append(p + Vector2.from_angle(TAU * k / 6.0 + seed_value) * r * (0.85 + 0.15 * sin(k + seed_value)))
			draw_colored_polygon(pts, Color(0.7, 0.85, 1.0, 0.85))
			draw_line(p + Vector2(-r * 0.4, -r * 0.3), p + Vector2(r * 0.2, r * 0.2), Color(1, 1, 1, 0.8), 2.0)
		_:
			draw_circle(p, r, Color("4a4352"))


func _draw_camp(ci: CanvasItem) -> void:
	var c := rect.get_center()
	_draw_tent(ci, c + Vector2(-380, -330), Color("6b2b2b"))
	_draw_tent(ci, c + Vector2(390, -360), Color("2b4a6b"))
	_draw_tent(ci, c + Vector2(-320, 330), Color("3a5a3a"))
	_draw_crates(ci, c + Vector2(330, 250))
	_draw_crates(ci, c + Vector2(-480, 120))
	# Empalizada en el borde (con huecos en las salidas).
	var step := 44.0
	var x := rect.position.x + 20.0
	while x < rect.end.x - 20.0:
		for y in [rect.position.y + 20.0, rect.end.y - 20.0]:
			_draw_post(ci, Vector2(x, y))
		x += step
	var y2 := rect.position.y + 64.0
	while y2 < rect.end.y - 40.0:
		for xx in [rect.position.x + 20.0, rect.end.x - 20.0]:
			var gap := false
			for e in exits:
				if absf(e["pos"].y - y2) < 120.0 and absf(e["pos"].x - xx) < 200.0:
					gap = true
			if not gap:
				_draw_post(ci, Vector2(xx, y2))
		y2 += step
	var board := Rect2(c + Vector2(-150, -470), Vector2(300, 36))
	ci.draw_rect(board, WOOD.lightened(0.1))
	ci.draw_rect(board, WOOD.darkened(0.4), false, 2.0)
	ci.draw_string(ThemeDB.fallback_font, board.position + Vector2(0, 24), zone_name, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 15, Color("f0e0c0"))
	for k in 8:
		ci.draw_circle(c + Vector2(0, -20) + Vector2.from_angle(TAU * k / 8.0) * Vector2(26, 12), 5.0, Color("4a4550"))


## Socket Seguro: cables por el suelo y armarios a los lados.
func _draw_hub_static(ci: CanvasItem) -> void:
	var c := rect.get_center()
	for k in 6:
		var a := c + Vector2(-700 + k * 260, -420)
		ci.draw_polyline(PackedVector2Array([a, a + Vector2(40, 260), a + Vector2(-30, 520), a + Vector2(20, 760)]),
			[Color("2a5a3a"), Color("3a3a6a"), Color("5a3a2a")][k % 3], 3.0, true)
	for side in [-1.0, 1.0]:
		for k in 3:
			var p := c + Vector2(side * 620.0, -260.0 + k * 200.0)
			ci.draw_rect(Rect2(p - Vector2(28, 50), Vector2(56, 100)), Color("16241b"))
			ci.draw_rect(Rect2(p - Vector2(28, 50), Vector2(56, 100)), Color("2a4a35"), false, 2.0)


## La gran terminal del Socket Seguro, con el historial de Rafa desplazándose.
func _draw_hub_terminal() -> void:
	var c := rect.get_center() + Vector2(0, -470)
	var screen := Rect2(c - Vector2(260, 90), Vector2(520, 180))
	draw_rect(screen.grow(10), Color("1a1f1a"))
	draw_rect(screen, Color("031007"))
	var font := ThemeDB.fallback_font
	var first := int(_time * 0.8) % TERMINAL_LINES.size()
	for k in 7:
		var line: String = TERMINAL_LINES[(first + k) % TERMINAL_LINES.size()]
		draw_string(font, screen.position + Vector2(10, 22 + k * 23), line, HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 20, 14,
			Color(PHOSPHOR, 0.45 + 0.5 * float(k) / 7.0))
	if fmod(_time, 1.0) < 0.5:
		draw_rect(Rect2(screen.position + Vector2(10, 22 + 6 * 23 + 4), Vector2(9, 3)), PHOSPHOR)
	# Líneas de barrido del CRT.
	for y in range(int(screen.position.y), int(screen.end.y), 4):
		draw_line(Vector2(screen.position.x, y), Vector2(screen.end.x, y), Color(0, 0, 0, 0.25), 1.0)
	draw_string(font, screen.position + Vector2(0, -16), "SOCKET SEGURO · sesión ssh activa desde hace 2.913 días · NO ESCRIBIR «exit»",
		HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, 12, Color(PHOSPHOR, 0.7))


## La Brecha del 503: el suelo parpadea a ratos entre binario y vacío.
func _draw_kernel_flicker() -> void:
	var font := ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_time * 3.0)
	for k in 14:
		var p := Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		if not is_walkable(p, 20.0):
			continue
		var w := rng.randf_range(60, 180)
		draw_rect(Rect2(p, Vector2(w, 18)), Color(0, 0, 0, 0.55))
		draw_string(font, p + Vector2(4, 14), "10110100 0503 ERR"[rng.randi() % 8] + "0".repeat(int(w / 12)),
			HORIZONTAL_ALIGNMENT_LEFT, w, 13, Color(0.3, 0.6, 1.0, 0.35))


func _draw_post(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_rect(Rect2(p + Vector2(-5, -26), Vector2(10, 26)), WOOD)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -26), p + Vector2(0, -34), p + Vector2(5, -26)]), WOOD.lightened(0.1))


func _draw_tent(ci: CanvasItem, pos: Vector2, color: Color) -> void:
	ci.draw_set_transform(pos + Vector2(0, 6), 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.35))
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-60, 0), pos + Vector2(0, -70), pos + Vector2(60, 0)]), color)
	ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, 0), pos + Vector2(0, -42), pos + Vector2(14, 0)]), Color(0.05, 0.04, 0.05))
	ci.draw_line(pos + Vector2(0, -70), pos + Vector2(0, -80), WOOD, 3.0)


func _draw_crates(ci: CanvasItem, pos: Vector2) -> void:
	for offset in [Vector2(0, 0), Vector2(26, 6), Vector2(10, -22)]:
		var r := Rect2(pos + offset, Vector2(24, 22))
		ci.draw_rect(r, WOOD.lightened(0.15))
		ci.draw_rect(r, WOOD.darkened(0.4), false, 2.0)


func _draw_campfire(pos: Vector2) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 9.0) * sin(_time * 5.3)
	draw_circle(pos, 170.0 * flicker, Color(1.0, 0.55, 0.2, 0.05))
	draw_circle(pos, 95.0 * flicker, Color(1.0, 0.6, 0.25, 0.06))
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
	var portal: bool = e.get("portal", false)
	var locked := exit_blocked_reason(e) != ""
	var color := Color(0.75, 0.45, 1.0) if portal else Color(0.5, 0.8, 1.0)
	if locked:
		color = Color(0.85, 0.3, 0.3)
		# Candado delante de la salida.
		draw_rect(Rect2(p + Vector2(-12, -8), Vector2(24, 20)), Color("8a8e98"))
		draw_arc(p + Vector2(0, -8), 8.0, PI, TAU, 12, Color("8a8e98"), 4.0)
		draw_circle(p + Vector2(0, 1), 3.0, Color("1a1a1e"))
	draw_set_transform(p, 0.0, Vector2(0.55, 1.0))
	draw_circle(Vector2.ZERO, EXIT_RADIUS + 10.0, Color(color, 0.08 + 0.06 * glow))
	draw_circle(Vector2.ZERO, EXIT_RADIUS, Color(color.darkened(0.6), 0.45))
	draw_arc(Vector2.ZERO, EXIT_RADIUS, 0.0, TAU, 40, Color(color, 0.6 + 0.4 * glow), 3.0, true)
	if portal:
		# Remolino girando.
		for k in 3:
			var a := _time * 2.5 + k * TAU / 3.0
			draw_arc(Vector2.ZERO, EXIT_RADIUS * (0.35 + 0.18 * k), a, a + 2.2, 16, Color(color.lightened(0.3), 0.7), 2.5, true)
	draw_set_transform(Vector2.ZERO)
	var font := ThemeDB.fallback_font
	var label: String = e["label"]
	if not portal:
		label = ("← %s" if p.x < rect.get_center().x else "%s →") % label
	if locked:
		label = "[bloqueado] " + label
	draw_string_outline(font, p + Vector2(-130, -EXIT_RADIUS - 18), label, HORIZONTAL_ALIGNMENT_CENTER, 260, 15, 5, Color.BLACK)
	draw_string(font, p + Vector2(-130, -EXIT_RADIUS - 18), label, HORIZONTAL_ALIGNMENT_CENTER, 260, 15, color.lightened(0.3))


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


## Alijo: un NAS (servidor de archivos) con lucecitas, compartido por la cuenta.
func _draw_stash() -> void:
	var p := stash_pos
	draw_set_transform(p + Vector2(0, 22), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 36.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var box := Rect2(p + Vector2(-30, -40), Vector2(60, 62))
	draw_rect(box, Color("2b2733"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 8)), Color("3d3747"))
	for k in 4:
		var bay := Rect2(box.position + Vector2(6, 13 + k * 12), Vector2(48, 9))
		draw_rect(bay, Color("1a1720"))
		var on := sin(_time * (3.0 + k * 1.3) + k) > -0.2
		draw_circle(bay.position + Vector2(42, 4.5), 2.0, Color("3cff6a") if on else Color("1a4a2a"))
		draw_line(bay.position + Vector2(4, 4.5), bay.position + Vector2(28, 4.5), Color("4a4352"), 2.0)
	draw_rect(box, Color("f2c14e").darkened(0.35), false, 2.0)
	var font := ThemeDB.fallback_font
	var label := "Alijo (NAS compartido)"
	draw_string_outline(font, p + Vector2(-100, -50), label, HORIZONTAL_ALIGNMENT_CENTER, 200, 14, 5, Color.BLACK)
	draw_string(font, p + Vector2(-100, -50), label, HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color("f2c14e"))


func _draw_key_item(k: Dictionary) -> void:
	var p: Vector2 = k["pos"]
	var bob := sin(_time * 3.0) * 4.0
	draw_circle(p, 30.0, Color(1.0, 0.85, 0.3, 0.10 + 0.08 * sin(_time * 4.0)))
	ItemIcons.draw(self, Rect2(p + Vector2(-18, -22 + bob), Vector2(36, 36)), KeyItem.DEFS.get(k["id"], {}).get("icon", "key_card"))
	var name: String = KeyItem.DEFS.get(k["id"], {}).get("name", k["id"])
	var font := ThemeDB.fallback_font
	draw_string_outline(font, p + Vector2(-120, -30 + bob), name, HORIZONTAL_ALIGNMENT_CENTER, 240, 13, 5, Color.BLACK)
	draw_string(font, p + Vector2(-120, -30 + bob), name, HORIZONTAL_ALIGNMENT_CENTER, 240, 13, KeyItem.COLOR)


## Banco de Pruebas de Estrés: tócalo para ver la recompensa y aceptar las oleadas.
func _draw_challenge(c: Dictionary) -> void:
	var p: Vector2 = c["pos"]
	var active: bool = active_challenge.get("id", "") == c["id"]
	if active:
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		draw_arc(p, CHALLENGE_ARENA, 0.0, TAU, 96, Color(1.0, 0.3, 0.2, 0.35 + 0.3 * pulse), 4.0, true)
		draw_circle(p, CHALLENGE_ARENA, Color(1.0, 0.2, 0.1, 0.04))
	draw_set_transform(p + Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 36.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	var box := Rect2(p - Vector2(22, 50), Vector2(44, 64))
	draw_rect(box, Color("2a1e1e"))
	draw_rect(box, Color("e06c3a") if active else Color("d9a441"), false, 2.0)
	# Medidor de carga.
	var load := 0.5 + 0.5 * sin(_time * (6.0 if active else 1.5))
	draw_rect(Rect2(box.position + Vector2(8, 10), Vector2(28, 8)), Color("101010"))
	draw_rect(Rect2(box.position + Vector2(8, 10), Vector2(28 * load, 8)), Color("e0503a") if load > 0.7 else Color("6fd36b"))
	for k in 4:
		draw_circle(box.position + Vector2(12 + k * 7, 34), 2.0, Color("e0503a") if fmod(_time * 3.0 + k, 2.0) < 1.0 else Color("401010"))
	var font := ThemeDB.fallback_font
	var label: String = c.get("name", "Banco de Pruebas de Estrés")
	var bob := sin(_time * 3.0) * 3.0
	draw_string_outline(font, p + Vector2(-140, -62 + bob), label, HORIZONTAL_ALIGNMENT_CENTER, 280, 14, 5, Color.BLACK)
	draw_string(font, p + Vector2(-140, -62 + bob), label, HORIZONTAL_ALIGNMENT_CENTER, 280, 14, Color("ff9a4a"))
	if not active:
		draw_string_outline(font, p + Vector2(-10, -80 + bob), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 24, 5, Color.BLACK)
		draw_string(font, p + Vector2(-10, -80 + bob), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 24, Color("ff9a4a"))


## Gigantes de hierro de la Grieta del Deadlock: encadenados mientras no se abra.
func _draw_prop(p: Dictionary) -> void:
	match String(p.get("kind", "")):
		"iron_giant":
			var pos: Vector2 = p["pos"]
			var s := -1.0 if p.get("flip", false) else 1.0
			var free: bool = character != null and character.flags.has(p.get("free_flag", ""))
			var lean := 0.0 if free else sin(_time * 1.5) * 2.0
			var metal := Color("4a4e58")
			draw_set_transform(pos + Vector2(0, 40), 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2.ZERO, 80.0, Color(0, 0, 0, 0.4))
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(pos + Vector2(-50, -120 + lean), Vector2(100, 130)), metal)
			draw_rect(Rect2(pos + Vector2(-34, -170 + lean), Vector2(68, 50)), metal.lightened(0.1))
			draw_circle(pos + Vector2(-12, -148 + lean), 6.0, Color("e0503a") if not free else Color("6fd36b"))
			draw_circle(pos + Vector2(12, -148 + lean), 6.0, Color("e0503a") if not free else Color("6fd36b"))
			# Brazo extendido hacia el otro gigante, agarrando su recurso.
			draw_line(pos + Vector2(s * 50, -90 + lean), pos + Vector2(s * (70.0 if free else 150.0), -80), metal.darkened(0.2), 18.0)
			if not free:
				for k in 5:
					var q := pos + Vector2(s * (60 + k * 18), -60 + k * 4)
					draw_arc(q, 7.0, 0.0, TAU, 10, Color("8a8e98"), 3.0)
				draw_string(ThemeDB.fallback_font, pos + Vector2(-60, -190), "esperando recurso...", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("e06c6c"))
		"cpu_core":
			# Núcleo de la CPU: se sobrecalienta por turnos (y de él salen los rayos del OOM Killer).
			var pos: Vector2 = p["pos"]
			var heat := 0.5 + 0.5 * sin(_time * 1.3 + pos.x * 0.01 + pos.y * 0.02)
			draw_circle(pos, 90.0, Color(1.0, 0.4, 0.1, 0.05 + 0.10 * heat))
			draw_rect(Rect2(pos - Vector2(46, 46), Vector2(92, 92)), Color("2a2a30"))
			draw_rect(Rect2(pos - Vector2(36, 36), Vector2(72, 72)), Color(0.35 + 0.5 * heat, 0.18, 0.1))
			for k in 6:
				var o := -40.0 + k * 16.0
				for side in [Vector2(o, -52), Vector2(o, 52), Vector2(-52, o), Vector2(52, o)]:
					draw_rect(Rect2(pos + side - Vector2(3, 3), Vector2(6, 6)), Color("c0a060"))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-40, 6), "CORE", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color(1, 0.9, 0.7, 0.6 + 0.4 * heat))


func _draw_quest_item(q: Dictionary) -> void:
	var p: Vector2 = q["pos"]
	var bob := sin(_time * 3.0) * 4.0
	var glow := 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(p, 34.0, Color(1.0, 0.8, 0.3, 0.08 + 0.08 * glow))
	# Sombra en el suelo (no flota) y el objeto con su propio dibujo encima.
	draw_colored_polygon(QuestItemArt.ellipse(p + Vector2(0, 30), 22.0 - bob * 0.5, 6.0), Color(0, 0, 0, 0.35))
	draw_set_transform(p + Vector2(0, bob), 0.0, Vector2(QUEST_ITEM_SCALE, QUEST_ITEM_SCALE))
	QuestItemArt.draw(self, Vector2.ZERO, QuestItemArt.kind_for(q), _time)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	draw_string_outline(font, p + Vector2(-110, -42 + bob), q["name"], HORIZONTAL_ALIGNMENT_CENTER, 220, 13, 5, Color.BLACK)
	draw_string(font, p + Vector2(-110, -42 + bob), q["name"], HORIZONTAL_ALIGNMENT_CENTER, 220, 13, UiStyle.ACCENT)


## Un NPC que solo está "conectado": su cara en un monitor de fósforo verde.
func _draw_terminal_npc(pos: Vector2, appearance: Dictionary) -> void:
	draw_rect(Rect2(pos + Vector2(-34, -6), Vector2(68, 10)), Color("3a2e26"))          # mesa
	var screen := Rect2(pos + Vector2(-28, -52), Vector2(56, 44))
	draw_rect(screen.grow(4), Color("2a2a2e"))
	draw_rect(screen, Color("031007"))
	var flicker := 0.7 + 0.3 * sin(_time * 23.0) * sin(_time * 7.0)
	CharacterAppearance.draw(self, screen.position + Vector2(28, 52), 0.75, appearance, Vector2.DOWN, Color(PHOSPHOR, flicker))
	draw_rect(screen.grow(4), Color(0.03, 0.06, 0.04), false, 2.0)
	for y in range(int(screen.position.y), int(screen.end.y), 3):
		draw_line(Vector2(screen.position.x, y), Vector2(screen.end.x, y), Color(0, 0, 0, 0.3), 1.0)


func _draw_npcs() -> void:
	var font := ThemeDB.fallback_font
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		var pos := npc_position(npc)
		var appearance := CharacterAppearance.sanitize(npc.get("appearance", {}))
		var to_player := player.global_position - pos if player else Vector2.DOWN
		if npc.get("terminal", false):
			_draw_terminal_npc(pos, appearance)
		else:
			CharacterAppearance.draw(self, pos, 1.12, appearance, Vector2(signf(to_player.x) * 0.5, 1.0))
		var label_color := UiStyle.ACCENT if i == _hovered_npc else UiStyle.TEXT
		var label_pos := pos + Vector2(-110.0, -52.0)
		draw_string_outline(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, 5, Color(0, 0, 0, 0.8))
		draw_string(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, label_color)
		# "?" si tiene una misión lista para entregar; "!" si hay algo nuevo que hablar.
		var mark := ""
		var mark_color := UiStyle.ACCENT
		if quests and quests.npc_has_turn_in(npc["id"]):
			mark = "?"
			mark_color = Color("6fd36b")
		elif quests and quests.npc_offers_quest(npc["id"]):
			mark = "!"
			mark_color = Color("ffd84a")
		elif character and not character.flags.has("talked_" + npc["id"]):
			mark = "!"
		if mark != "":
			var bounce := sin(_time * 4.0) * 3.0
			draw_string_outline(font, pos + Vector2(-10.0, -70.0 + bounce), mark, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, 5, Color.BLACK)
			draw_string(font, pos + Vector2(-10.0, -70.0 + bounce), mark, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, mark_color)
