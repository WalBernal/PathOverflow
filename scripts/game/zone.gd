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
signal lore_picked(note: Dictionary)
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
	# Acto IV: el Setup de la BIOS.
	"setup": {"ground": "0a1a6a", "decal": "1a2c8a", "edge": "racks", "outside": "000844"},
	"vga16": {"ground": "141414", "decal": "2a2a2a", "edge": "void", "outside": "000000"},
}
const PHOSPHOR := Color("3cff6a")
const TERMINAL_LINES := [
	"$ ssh rafa@socket-seguro -p 2222", "Permission denied (publickey).", "$ sudo !!", "rafa no está en el archivo sudoers.",
	"$ ping la-red-lince.net", "Request timeout for icmp_seq 0", "$ crontab -l -u pepe", "0 18 * * 5 /opt/pepe/limpieza_final.sh  # 🐟",
	"$ ps aux | wc -l", "8193", "$ kill -9 1", "bash: kill: (1) - Operation not permitted",
]
const WOOD := Color("5b3f27")
## Margen alrededor de la cámara para dibujar obstáculos y objetos (que no
## aparezcan de golpe en el borde: el mayor obstáculo mide ~2 × 46 px más su sombra).
const DRAW_MARGIN := 160.0

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
var lore_notes: Array = []              # LoreNotes de esta zona, con "pos" ya colocada
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
var events: ZoneEvents
var _npc_layer: Node2D
var _label_layer: Node2D
var _labels: Array = []   # [pos, texto, ancho, tamaño, color, contorno] (ver _label)
var _pending: Dictionary = {}           # {"kind": "npc"|"waypoint", "npc": {...}}
var _hovered_npc := -1
var _time := 0.0
var _exits_armed := false
var _challenge_armed := true


## Agranda una zona según su "scale" (act*.json): tamaño y todas las posiciones
## (entradas, salidas, NPC, waypoint, alijo, objetos, jefe...). Las manadas, los
## obstáculos y los accidentes crecen con el área, y "enemy_density" añade más
## enemigos por pantalla. Lo llama GameData al cargar los actos.
static func scale_def(z: Dictionary) -> void:
	var s := float(z.get("scale", 1.0))
	if is_equal_approx(s, 1.0) or z.get("_scaled", false):
		return
	z["_scaled"] = true
	var mul := func(v: Variant) -> Array: return [float(v[0]) * s, float(v[1]) * s]
	z["size"] = mul.call(z["size"])
	for k in z.get("entries", {}):
		z["entries"][k] = mul.call(z["entries"][k])
	for key in ["waypoint", "stash"]:
		if z.has(key):
			z[key] = mul.call(z[key])
	for list in ["exits", "npcs", "quest_items", "key_items", "challenges", "props", "rare_spawns"]:
		for e in z.get(list, []):
			if e is Dictionary and e.has("pos"):
				e["pos"] = mul.call(e["pos"])
	if z.has("boss") and z["boss"].has("pos"):
		z["boss"]["pos"] = mul.call(z["boss"]["pos"])
	# Puntos fijos de las habilidades del jefe (centro de las zonas seguras, núcleos del OOM Killer).
	for a in z.get("boss", {}).get("abilities", []):
		if a.has("center"):
			a["center"] = mul.call(a["center"])
		if a.has("cores"):
			a["cores"] = a["cores"].map(mul)
	if z.has("extra_points"):
		z["extra_points"] = z["extra_points"].map(mul)
	if z.get("mutex") is Dictionary and z["mutex"].has("positions"):
		z["mutex"]["positions"] = z["mutex"]["positions"].map(mul)
	if z.get("race_condition") is Dictionary and z["race_condition"].has("pos"):
		z["race_condition"]["pos"] = mul.call(z["race_condition"]["pos"])
	var area := s * s
	if z.has("enemies"):
		z["enemies"]["packs"] = roundi(float(z["enemies"].get("packs", 0)) * area * float(z.get("enemy_density", 1.0)))
	if z.has("obstacles"):
		z["obstacles"]["count"] = roundi(float(z["obstacles"].get("count", 0)) * area)
	if z.has("features"):
		z["features"]["count"] = roundi(float(z["features"].get("count", 0)) * s)


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
	for n in LoreNotes.for_zone(String(def.get("id", ""))):
		var note: Dictionary = n.duplicate()
		note["pos"] = rect.position + rect.size * _v(n["at"])   # fracción del tamaño: no le afecta la escala
		lore_notes.append(note)
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
	_place_torches()
	_build_collision()
	_ground_layer = Node2D.new()
	_ground_layer.show_behind_parent = true
	_ground_layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ground_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # los obstáculos en pixel art (ObstacleArt)
	# Por encima del filtro de pixel art: NPC (z 1, con la luz de la zona) y textos (z 3).
	_npc_layer = Node2D.new()
	_npc_layer.z_index = 1
	_npc_layer.draw.connect(func() -> void: _draw_npcs(_npc_layer))
	add_child(_npc_layer)
	_label_layer = Node2D.new()
	_label_layer.z_index = 3
	_label_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # los textos, suaves
	_label_layer.draw.connect(_draw_labels)
	add_child(_label_layer)
	# Eventos (datos huérfanos, santuarios, emboscadas, deploys fallidos): cambian en cada visita.
	events = ZoneEvents.new()
	add_child(events)
	var event_rng := RandomNumberGenerator.new()
	event_rng.randomize()
	events.setup(self, event_rng)
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


## Antorchas (o su versión de la zona: LED de estado, fuego fatuo...) solo en las
## zonas oscuras: decorado sin colisión que da luz (WorldPost). Usa su propio
## generador para no cambiar el resto de la zona.
const TORCH_STYLES := {
	"servers": ["led", "6ab8ff"], "kernel": ["led", "8ab4ff"], "bios": ["led", "8aa8ff"], "rom": ["led", "d0a8ff"],
	"setup": ["led", "ffe050"], "vga16": ["led", "55ffff"],
	"swamp": ["wisp", "a0ff80"], "grieta": ["wisp", "c08aff"], "alcantarillas": ["wisp", "70e0c0"],
}
## {pos, kind ("torch", "led", "wisp"), color}
var torches: Array[Dictionary] = []


func _place_torches() -> void:
	var dark := float(WorldPost.GRADES.get(style, {}).get("dark", 0.0))
	if dark < 0.25 or safe:
		return
	var trng := RandomNumberGenerator.new()
	trng.seed = hash(id) + 7
	var look: Array = TORCH_STYLES.get(style, ["torch", "ffa040"])
	var wanted := clampi(int(rect.get_area() / 650000.0), 4, 28)
	var keys := key_points()
	var path := _key_path(keys)
	var inner := rect.grow(-120.0)
	for attempt in wanted * 30:
		if torches.size() >= wanted:
			break
		var p := Vector2(trng.randf_range(inner.position.x, inner.end.x), trng.randf_range(inner.position.y, inner.end.y))
		if not _spot_is_free(p, 12.0, keys, path, 30.0):
			continue
		if torches.any(func(t: Dictionary) -> bool: return (t["pos"] as Vector2).distance_to(p) < 380.0):
			continue
		torches.append({"pos": p, "kind": look[0], "color": Color(look[1])})


## Puntos de luz fijos de la zona (para WorldPost): antorchas, hoguera del
## campamento, salidas y waypoint. {pos, radius, color, power}
func light_points() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in torches:
		out.append({"pos": t["pos"] + Vector2(0, -30), "radius": 230.0, "color": t["color"], "power": 0.85})
	if style == "camp":
		out.append({"pos": rect.get_center() + Vector2(0, -20), "radius": 320.0, "color": Color("ff9a40"), "power": 0.9})
	for e in exits:
		if exit_visible(e) and exit_open(e):
			out.append({"pos": e["pos"], "radius": 170.0, "color": Color("60d0ff") if not e.has("portal") else Color("c08aff"), "power": 0.6})
	if has_waypoint:
		out.append({"pos": waypoint, "radius": 160.0, "color": Color("7fb8ff"), "power": 0.6})
	return out


func _draw_torch(t: Dictionary) -> void:
	var p: Vector2 = t["pos"]
	var c: Color = t["color"]
	var flick := 0.8 + 0.2 * sin(_time * 10.0 + p.x) * sin(_time * 6.1 + p.y)
	match t["kind"]:
		"led":
			# Poste con un LED de estado que parpadea.
			draw_rect(Rect2(p + Vector2(-3, -34), Vector2(6, 34)), Color("2a2e38"))
			draw_rect(Rect2(p + Vector2(-6, -40), Vector2(12, 8)), Color("3a4050"))
			draw_rect(Rect2(p + Vector2(-3, -38), Vector2(6, 4)), Color(c, 0.6 + 0.4 * flick))
			draw_circle(p + Vector2(0, -36), 10.0 * flick, Color(c, 0.12))
		"wisp":
			# Fuego fatuo: una llama suelta que flota.
			var f := p + Vector2(sin(_time * 1.3 + p.y) * 6.0, -30.0 + sin(_time * 2.1 + p.x) * 4.0)
			draw_circle(f, 12.0 * flick, Color(c, 0.18))
			draw_circle(f, 5.0 * flick, Color(c, 0.8))
			draw_circle(f, 2.0, Color(1, 1, 1, 0.9))
		_:
			# Antorcha: palo, cuenco y llama de tres capas.
			draw_rect(Rect2(p + Vector2(-2, -30), Vector2(4, 30)), WOOD)
			draw_rect(Rect2(p + Vector2(-6, -34), Vector2(12, 5)), Color("3a3430"))
			for layer in [[Color("e0652f"), 7.0, 18.0], [Color("f0a030"), 5.0, 13.0], [Color("ffe070"), 3.0, 7.0]]:
				var w: float = layer[1]
				var h: float = layer[2] * flick
				var sway := sin(_time * 7.0 + w + p.x) * 2.0
				var base := p + Vector2(0, -34)
				draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(sway, -h), base + Vector2(w, 0)]), layer[0])


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
	for n in lore_notes:
		if not n.has("placed"):
			n["pos"] = free_spot_near(n["pos"], 30.0)   # que no quede debajo de un obstáculo
			n["placed"] = true
		if lore_visible(n) and player.global_position.distance_to(n["pos"]) < QUEST_ITEM_RADIUS:
			lore_picked.emit(n)
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


func lore_visible(n: Dictionary) -> bool:
	return character != null and not LoreNotes.is_found(character, String(n["id"]))


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


## Mando: habla con el NPC más cercano, o usa el waypoint o el alijo, si están a
## menos de `radius` de `pos`. true si había algo.
func interact_near(pos: Vector2, radius: float) -> bool:
	var best := -1
	var best_d := radius
	for i in npcs.size():
		var d := npc_position(npcs[i]).distance_to(pos)
		if d < best_d:
			best_d = d
			best = i
	if best != -1:
		_pending = {"kind": "npc", "npc": npcs[best]}
		player.move_to(npc_position(npcs[best]) + Vector2(0, 40))
		return true
	if has_waypoint and waypoint.distance_to(pos) < radius:
		_pending = {"kind": "waypoint"}
		player.move_to(waypoint + Vector2(0, 30))
		return true
	if has_stash and stash_pos.distance_to(pos) < radius:
		_pending = {"kind": "stash"}
		player.move_to(stash_pos + Vector2(0, 34))
		return true
	return events != null and events.interact_near(pos, radius)


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
	if ZoneArt.has_ground(style):
		# Suelo en pixel art: baldosa sin costuras repetida (UV en el mundo).
		var tex := ZoneArt.ground(style)
		var area := walk_polygon if walk_polygon.size() >= 3 else PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		var uvs := PackedVector2Array()
		for q in area:
			uvs.append(q / ZoneArt.tile_world())
		layer.draw_colored_polygon(area, Color.WHITE, uvs, tex)
		# Las marcas temáticas (cables, losas rotas, <defunct>, texto del BIOS...) siguen
		# encima; en el resto del acto I el suelo ya lo dice todo.
		if not style in ["camp", "swamp", "catacombs", "servers", "boss", "sandbox"]:
			_draw_decals(layer, Color(s["decal"]))
	else:
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
			"setup":
				# Setup de la BIOS: opciones con su valor; la seleccionada, en amarillo.
				var tile := 64.0
				var cell := (p / tile).floor() * tile
				var opts := ["Quick Boot  [Enabled]", "Halt On  [All Errors]", "Boot Seq  [A,C,SCSI]", "Virus Warning [Disabled]",
					"CPU Cache  [Enabled]", "Password  [admin]"]
				var picked := int(d["seed"]) % 5 == 0
				if picked:
					ci.draw_rect(Rect2(cell + Vector2(2, 8), Vector2(tile * 2.2, 16)), Color(0.9, 0.85, 0.2, 0.12))
				ci.draw_string(ThemeDB.fallback_font, cell + Vector2(6, 20), opts[int(d["seed"]) % opts.size()],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.95, 0.4, 0.22) if picked else Color(0.85, 0.9, 1.0, 0.16))
			"vga16":
				# Modo VGA de 16 colores: bloques de píxeles gordos de la paleta EGA.
				var ega := [Color("0000aa"), Color("00aa00"), Color("00aaaa"), Color("aa0000"), Color("aa00aa"), Color("aa5500"), Color("5555ff"), Color("55ffff")]
				var b := sz * 0.25
				for k in 3:
					ci.draw_rect(Rect2(p + Vector2((k - 1) * b, (k % 2) * b), Vector2(b, b)), Color(ega[(int(d["seed"]) + k) % ega.size()], 0.18))
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
	# Solo lo que cae en cámara (las zonas grandes tienen cientos de obstáculos).
	var view := _camera_rect().grow(DRAW_MARGIN)
	for o in obstacles:
		if not view.grow(float(o.get("visual", 0.0))).has_point(o["pos"]):   # accidentes: hasta 160 px de radio
			continue
		if o.get("feature", false):
			_draw_feature_anim(o)
		else:
			_draw_obstacle(o)
	for t in torches:
		if view.has_point(t["pos"]):
			_draw_torch(t)
	if style == "camp":
		_draw_campfire(rect.get_center() + Vector2(0, -20))
	elif style == "terminal":
		_draw_hub_terminal()
	elif style == "kernel":
		_draw_kernel_flicker()
	for p in props:
		if view.grow(400.0).has_point(p["pos"]) and (not p.has("requires_flag") or (character != null and character.flags.has(p["requires_flag"]))):
			_draw_prop(p)
	for e in exits:
		if exit_visible(e) and view.has_point(e["pos"]):
			_draw_exit(e)
	for k in key_items:
		if key_item_visible(k) and view.has_point(k["pos"]):
			_draw_key_item(k)
	for c in challenges:
		if character and not character.flags.has("challenge_done_" + String(c["id"])) and (view.grow(CHALLENGE_ARENA).has_point(c["pos"])):
			_draw_challenge(c)
	if has_waypoint:
		_draw_waypoint()
	if has_stash:
		_draw_stash()
	for q in quest_items:
		if quest_item_visible(q):
			_draw_quest_item(q)
	for n in lore_notes:
		if lore_visible(n):
			_draw_lore_note(n)
	_draw_ambient()
	_npc_layer.queue_redraw()
	_label_layer.queue_redraw()


## Lo que ve la cámara, en coordenadas del mundo.
func _camera_rect() -> Rect2:
	var view := get_viewport_rect()
	var inv := get_canvas_transform().affine_inverse()
	return Rect2(inv * view.position, view.size / get_canvas_transform().get_scale())


## Texto del mundo que no debe pixelarse (nombres, placas, avisos): se guarda y
## lo dibuja la capa de etiquetas (z 3), encima de los filtros.
func _label(pos: Vector2, text: String, width: float, font_size: int, color: Color, outline := true) -> void:
	_labels.append([pos, text, width, font_size, color, outline])


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	for l in _labels:
		var font_size := Accessibility.world_size(l[3])
		if l[5]:
			_label_layer.draw_string_outline(font, l[0], l[1], HORIZONTAL_ALIGNMENT_CENTER, l[2], font_size, 5, Color(0, 0, 0, 0.85))
		_label_layer.draw_string(font, l[0], l[1], HORIZONTAL_ALIGNMENT_CENTER, l[2], font_size, l[4])
	_labels.clear()


## Partículas de ambiente alrededor de la cámara, según el estilo: luciérnagas y
## hojas en el bosque, niebla y burbujas en el pantano, polvo en ruinas y
## catacumbas, motas de datos en los servidores, brasas en la sala del jefe.
func _draw_ambient() -> void:
	var cam := _camera_rect().grow(60.0)
	var t := _time
	var spot := func(k: int, vx: float, vy: float) -> Vector2:
		var hx := fmod(k * 0.6180339 + 0.13, 1.0)
		var hy := fmod(k * 0.7548776 + 0.41, 1.0)
		return cam.position + Vector2(fposmod(hx * cam.size.x + t * vx, cam.size.x), fposmod(hy * cam.size.y + t * vy, cam.size.y))
	# Los estilos de los actos II y III reutilizan uno de estos ambientes.
	var kind: String = {"kernel": "servers", "bus": "servers", "silicio": "servers", "bios": "servers", "terminal": "camp",
		"fabrica": "ruins", "alcantarillas": "swamp", "fosa": "catacombs", "grieta": "catacombs", "anillo": "boss",
		"flash": "boss", "frio": "snow", "rom": "sparkle", "setup": "servers", "vga16": "sparkle"}.get(style, style)
	match kind:
		"snow":
			for k in 40:   # nieve de refrigerante
				var q: Vector2 = spot.call(k, 8.0 * sin(k), 30.0) + Vector2(sin(t + k) * 10.0, 0)
				draw_rect(Rect2(q, Vector2(2, 2)), Color(0.85, 0.95, 1.0, 0.55))
		"sparkle":
			for k in 22:   # destellos de cristal
				var q: Vector2 = spot.call(k, 0.0, 0.0)
				var on := maxf(0.0, sin(t * 2.5 + k * 1.3))
				draw_rect(Rect2(q - Vector2(1, 3), Vector2(2, 6)), Color(0.85, 0.7, 1.0, 0.6 * on))
				draw_rect(Rect2(q - Vector2(3, 1), Vector2(6, 2)), Color(0.85, 0.7, 1.0, 0.6 * on))
		"forest":
			for k in 26:   # luciérnagas
				var q: Vector2 = spot.call(k, 6.0 * sin(k), -4.0) + Vector2(sin(t * 1.3 + k) * 10.0, cos(t + k * 2.0) * 6.0)
				var blink := maxf(0.0, sin(t * 2.0 + k * 1.7))
				draw_rect(Rect2(q, Vector2(3, 3)), Color(0.85, 1.0, 0.4, 0.75 * blink))
				draw_rect(Rect2(q - Vector2(2, 2), Vector2(7, 7)), Color(0.85, 1.0, 0.4, 0.12 * blink))
			for k in 10:   # hojas que caen
				var q: Vector2 = spot.call(k + 50, 14.0, 22.0) + Vector2(sin(t * 2.0 + k) * 12.0, 0)
				draw_rect(Rect2(q, Vector2(4, 2)), [Color("6a8a3a"), Color("8a6a2a")][k % 2])
		"swamp":
			for k in 9:   # bancos de niebla
				var q: Vector2 = spot.call(k, 10.0, 2.0)
				draw_set_transform(q, 0.0, Vector2(1.0, 0.4))
				draw_circle(Vector2.ZERO, 90.0 + 30.0 * sin(k), Color(0.6, 0.55, 0.75, 0.06))
				draw_set_transform(Vector2.ZERO)
			for k in 14:   # burbujas
				var q: Vector2 = spot.call(k + 30, 0.0, -18.0)
				draw_rect(Rect2(q, Vector2(3, 3)), Color(0.75, 0.55, 1.0, 0.45))
		"ruins", "catacombs":
			for k in 30:   # polvo flotando
				var q: Vector2 = spot.call(k, 5.0, 3.0) + Vector2(sin(t * 0.7 + k) * 8.0, 0)
				draw_rect(Rect2(q, Vector2(2, 2)), Color(1.0, 0.9, 0.7, 0.3 if kind == "ruins" else 0.18))
		"servers":
			for k in 28:   # motas de datos que suben
				var q: Vector2 = spot.call(k, 0.0, -26.0)
				var on := sin(t * 5.0 + k) > 0.0
				draw_rect(Rect2(q, Vector2(2, 4)), Color(0.35, 0.9, 1.0, 0.6 if on else 0.2))
		"boss":
			for k in 30:   # brasas
				var q: Vector2 = spot.call(k, 4.0 * sin(k), -34.0) + Vector2(sin(t * 3.0 + k) * 6.0, 0)
				draw_rect(Rect2(q, Vector2(3, 3)), Color(1.0, 0.45 + 0.3 * sin(k), 0.15, 0.7))
		"camp":
			for k in 12:
				var q: Vector2 = spot.call(k, 3.0, -6.0)
				draw_rect(Rect2(q, Vector2(2, 2)), Color(1.0, 0.8, 0.4, 0.35 * maxf(0.0, sin(t * 1.5 + k))))
		"sandbox":
			var font := ThemeDB.fallback_font
			for k in 14:
				var q: Vector2 = spot.call(k, 0.0, 16.0)
				draw_string(font, q, "1" if (k + int(t * 2.0)) % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.6, 1.0, 0.3))


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
	if ObstacleArt.KINDS.has(o["kind"]):
		# Pixel art (Acto I): el sprite en la rejilla del filtro y lo que se anima encima.
		var s := ObstacleArt.sprite(o["kind"], r, seed_value)
		draw_texture_rect(s["texture"], Rect2((p + s["offset"]).snapped(Vector2(ObstacleArt.PIX, ObstacleArt.PIX)), s["size"]), false)
		if o["kind"] == "rack":
			var box := Rect2(p - Vector2(r * 0.75, r), Vector2(r * 1.5, r * 2.0))
			for k in 6:
				var y := box.position.y + 6.0 + k * (box.size.y - 12.0) / 6.0
				var on := sin(_time * (2.0 + k) + seed_value) > 0.0
				draw_rect(Rect2(Vector2(box.end.x - 9, y + 3).snapped(Vector2(2, 2)), Vector2(4, 4)), Color("3cff6a") if on else Color("1a4a2a"))
		return
	match o["kind"]:
		"puddle":
			draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r, Color("4a2a6a"))
			draw_circle(Vector2.ZERO, r * 0.7, Color("6a3a9a"))
			draw_set_transform(Vector2.ZERO)
			var bubble := fmod(_time * 0.7 + seed_value % 10, 1.0)
			draw_circle(p + Vector2(r * 0.3, -bubble * 10.0), 3.0, Color(0.8, 0.6, 1.0, 1.0 - bubble))
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


## Puerta de salida en pixel art: arco de piedra con runas, energía girando
## dentro, círculo de glifos en el suelo y una placa con el destino. El color
## dice adónde lleva: campamento (dorado), jefe (rojo), portal (violeta), zona
## (cian); bloqueada, apagada y con cadenas.
func _draw_exit(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var portal: bool = e.get("portal", false)
	var locked := exit_blocked_reason(e) != ""
	if not e.has("target_def"):
		# Sin depender del autoload (las pruebas cargan la zona sin él).
		var gd := get_node_or_null("/root/GameData")
		e["target_def"] = gd.get("zones").get(e["target"], {}) if gd else {}
	var target: Dictionary = e["target_def"]
	var color := Color("5ad8ff")
	var icon := "arrow"
	if bool(target.get("safe", false)):
		color = Color("ffc860")
		icon = "camp"
	elif target.has("boss"):
		color = Color("ff5a4a")
		icon = "skull"
	elif portal:
		color = Color("c08aff")
		icon = "swirl"
	if locked:
		color = Color("8a4a4a")
	var stone := Color("4a4652")
	var stone_dark := Color("2e2b34")
	var stone_light := Color("68636e")
	var base := p + Vector2(0, 24)
	# Círculo de glifos en el suelo (girando).
	draw_set_transform(base, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 62.0, Color(color, 0.08 if locked else 0.14))
	draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 48, Color(color, 0.35 if locked else 0.7), 3.0)
	draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 48, Color(color, 0.2 if locked else 0.4), 2.0)
	if not locked:
		for k in 12:
			var a := TAU * k / 12.0 + _time * 0.6
			var q := Vector2.from_angle(a) * 56.0
			draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(color.lightened(0.3), 0.8))
	draw_set_transform(Vector2.ZERO)
	# Energía dentro del arco (o vacío si está cerrada).
	var inner := Rect2(p + Vector2(-26, -56), Vector2(52, 80))
	if locked:
		draw_rect(inner, Color(0.05, 0.03, 0.04, 0.85))
	else:
		for k in 6:   # bandas de luz que suben
			var t := fmod(_time * 0.5 + k / 6.0, 1.0)
			var y := inner.end.y - t * inner.size.y
			draw_rect(Rect2(inner.position.x, y, inner.size.x, 6), Color(color.lightened(0.2), 0.10 + 0.2 * sin(t * PI)))
		draw_rect(inner, Color(color.darkened(0.55), 0.55))
		draw_circle(inner.get_center() + Vector2(0, -inner.size.y * 0.25), 26.0, Color(color.darkened(0.55), 0.55))
		for k in 3:   # remolino
			var a := _time * 2.2 + k * TAU / 3.0
			draw_arc(inner.get_center() + Vector2(0, -6), 10.0 + 7.0 * k, a, a + 2.0, 10, Color(color.lightened(0.35), 0.8), 3.0)
		for k in 8:   # chispas que suben
			var t := fmod(_time * 0.7 + k * 0.137, 1.0)
			var x := inner.position.x + fmod(k * 13.7, inner.size.x)
			draw_rect(Rect2(x, inner.end.y - t * (inner.size.y + 30.0), 3, 3), Color(color.lightened(0.5), 1.0 - t))
	# Pilares de bloques de piedra con runas que brillan.
	for side in [-1.0, 1.0]:
		var px: float = p.x + side * 36.0
		for b in 7:
			var block := Rect2(px - 9, base.y - 10 - b * 12, 18, 11)
			draw_rect(block, stone if b % 2 == 0 else stone.darkened(0.08))
			draw_rect(Rect2(block.position, Vector2(block.size.x, 2)), stone_light)
			draw_rect(Rect2(block.position.x + (block.size.x - 3 if side > 0 else 0), block.position.y, 3, block.size.y), stone_dark)
			if b in [2, 4] and not locked:
				var rune := 0.5 + 0.5 * sin(_time * 3.0 + b + side)
				draw_rect(Rect2(block.get_center() - Vector2(2, 3), Vector2(4, 6)), Color(color.lightened(0.3), 0.4 + 0.6 * rune))
		draw_rect(Rect2(px - 12, base.y - 6, 24, 8), stone_dark)   # zócalo
	# Arco: bloques en semicírculo y piedra clave con el icono del destino.
	var arch := p + Vector2(0, -60)
	for k in 9:
		var a := PI + PI * k / 8.0
		var q := arch + Vector2.from_angle(a) * 36.0
		draw_rect(Rect2(q - Vector2(8, 7), Vector2(16, 14)), stone if k % 2 == 0 else stone.darkened(0.08))
		draw_rect(Rect2(q - Vector2(8, 7), Vector2(16, 2)), stone_light)
	var key := arch + Vector2(0, -38)
	draw_rect(Rect2(key - Vector2(12, 11), Vector2(24, 22)), stone_light)
	draw_rect(Rect2(key - Vector2(10, 9), Vector2(20, 18)), stone_dark)
	var ic := color.lightened(0.3)
	match icon:
		"camp":
			draw_colored_polygon(PackedVector2Array([key + Vector2(0, -6), key + Vector2(7, 6), key + Vector2(-7, 6)]), ic)
		"skull":
			draw_rect(Rect2(key - Vector2(5, 6), Vector2(10, 8)), ic)
			draw_rect(Rect2(key + Vector2(-3, 2), Vector2(6, 4)), ic)
			draw_rect(Rect2(key + Vector2(-3, -4), Vector2(2, 2)), stone_dark)
			draw_rect(Rect2(key + Vector2(1, -4), Vector2(2, 2)), stone_dark)
		"swirl":
			draw_arc(key, 6.0, _time * 3.0, _time * 3.0 + 4.5, 10, ic, 2.0)
		_:
			var dir := -1.0 if p.x < rect.get_center().x else 1.0
			draw_colored_polygon(PackedVector2Array([key + Vector2(dir * 7, 0), key + Vector2(-dir * 4, -6), key + Vector2(-dir * 4, 6)]), ic)
	if locked:
		# Cadenas cruzadas y candado.
		for d in [1.0, -1.0]:
			for k in 8:
				var q := p + Vector2(-30 * d + k * 7.5 * d, -50 + k * 9.0)
				draw_rect(Rect2(q - Vector2(3, 2), Vector2(6, 4)), Color("8a8e98") if k % 2 == 0 else Color("6a6e78"))
		draw_rect(Rect2(p + Vector2(-10, -14), Vector2(20, 16)), Color("b8a060"))
		draw_arc(p + Vector2(0, -14), 7.0, PI, TAU, 10, Color("b8a060"), 3.0)
		draw_rect(Rect2(p + Vector2(-1, -9), Vector2(2, 5)), Color("2a2010"))
	# Placa con el destino.
	var font := ThemeDB.fallback_font
	var label: String = e["label"]
	if locked:
		label = "Bloqueado · " + label
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
	var plate := Rect2(Vector2(p.x - w / 2.0, key.y - 44), Vector2(w, 22))
	draw_rect(plate.grow(2), Color("120f16"))
	draw_rect(plate, Color("221d28"))
	draw_rect(plate, Color(color, 0.9), false, 2.0)
	_label(plate.position + Vector2(0, 16), label, w, 14, color.lightened(0.4), false)


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
	_label(p + Vector2(-80, -80), "Waypoint", 160, 14, color)


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
	_label(p + Vector2(-100, -50), label, 200, 14, Color("f2c14e"))


func _draw_key_item(k: Dictionary) -> void:
	var p: Vector2 = k["pos"]
	var bob := sin(_time * 3.0) * 4.0
	draw_circle(p, 30.0, Color(1.0, 0.85, 0.3, 0.10 + 0.08 * sin(_time * 4.0)))
	ItemIcons.draw(self, Rect2(p + Vector2(-18, -22 + bob), Vector2(36, 36)), KeyItem.DEFS.get(k["id"], {}).get("icon", "key_card"))
	var name: String = KeyItem.DEFS.get(k["id"], {}).get("name", k["id"])
	var font := ThemeDB.fallback_font
	_label(p + Vector2(-120, -30 + bob), name, 240, 13, KeyItem.COLOR)


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
	_label(p + Vector2(-140, -62 + bob), label, 280, 14, Color("ff9a4a"))
	if not active:
		_label(p + Vector2(-10, -80 + bob), "!", 20, 24, Color("ff9a4a"))


## Gigantes de hierro de la Grieta del Deadlock: encadenados mientras no se abra.
func _draw_prop(p: Dictionary) -> void:
	match String(p.get("kind", "")):
		"camp_stall":
			# Puesto de Aida: mesa con toldo morado, cajas y un letrero.
			var pos: Vector2 = p["pos"]
			draw_rect(Rect2(pos + Vector2(-50, -6), Vector2(100, 22)), Color("5a3b2a"))
			for k in 5:
				draw_rect(Rect2(pos + Vector2(-54 + k * 22, -58), Vector2(22, 12)), Color("5a3b6b") if k % 2 == 0 else Color("e8e0d0"))
			for s in [-1.0, 1.0]:
				draw_line(pos + Vector2(s * 50, -46), pos + Vector2(s * 50, -6), Color("3a2a1e"), 3.0)
			draw_rect(Rect2(pos + Vector2(-40, -22), Vector2(22, 16)), Color("8a6a40"))
			draw_rect(Rect2(pos + Vector2(14, -20), Vector2(24, 14)), Color("6a8a9a"))
			_label(pos + Vector2(-90, -76), "Puesto de Aida", 180, 13, Color("c8a8e8"))
		"camp_workbench":
			# Mesa de crafteo de Mario: banco con un soldador humeante y un yunque improvisado (una fuente de poder).
			var pos: Vector2 = p["pos"]
			draw_rect(Rect2(pos + Vector2(-46, -10), Vector2(92, 14)), Color("6a4a30"))
			for s in [-1.0, 1.0]:
				draw_line(pos + Vector2(s * 40, 4), pos + Vector2(s * 40, 22), Color("4a3220"), 4.0)
			draw_rect(Rect2(pos + Vector2(-34, -28), Vector2(30, 18)), Color("3a3f4a"))   # fuente de poder
			draw_line(pos + Vector2(12, -10), pos + Vector2(26, -30), Color("c8c8d0"), 3.0)  # soldador
			var smoke := sin(_time * 2.0) * 3.0
			draw_circle(pos + Vector2(28 + smoke, -40), 4.0, Color(0.8, 0.8, 0.8, 0.35))
			draw_circle(pos + Vector2(30 - smoke, -50), 3.0, Color(0.8, 0.8, 0.8, 0.25))
			_label(pos + Vector2(-90, -64), "Mesa de crafteo", 180, 13, Color("8fe08a"))
		"camp_antenna":
			# Antena de Rafa: un poste con una antena WiFi hecha con latas, que parpadea.
			var pos: Vector2 = p["pos"]
			draw_line(pos, pos + Vector2(0, -110), Color("8a8a96"), 4.0)
			for k in 3:
				draw_line(pos + Vector2(-16 + k * 4, -90 + k * 18), pos + Vector2(16 - k * 4, -90 + k * 18), Color("8a8a96"), 2.0)
			draw_rect(Rect2(pos + Vector2(-8, -122), Vector2(16, 12)), Color("c8c8d0"))
			var on := fmod(_time * 1.5, 1.0) < 0.5
			draw_circle(pos + Vector2(0, -126), 4.0, Color("3cff6a") if on else Color("1a4a2a"))
			for k in 2:
				draw_arc(pos + Vector2(0, -126), 14.0 + k * 10.0, -PI * 0.8, -PI * 0.2, 10, Color(0.24, 1.0, 0.42, 0.4 if on else 0.15), 2.0)
			_label(pos + Vector2(-90, -150), "Antena de Rafa", 180, 13, Color("3cff6a"))
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
	_label(p + Vector2(-110, -42 + bob), q["name"], 220, 13, UiStyle.ACCENT)


## Archivo de lore en el suelo: un commit (nodo de git), un log (hoja de terminal) o un correo (sobre).
func _draw_lore_note(n: Dictionary) -> void:
	var p: Vector2 = n["pos"]
	var kind := String(n.get("kind", "log"))
	var c: Color = LoreNotes.KIND_COLORS.get(kind, UiStyle.ACCENT)
	var bob := sin(_time * 2.5 + p.x) * 3.0
	draw_circle(p, 26.0, Color(c, 0.08 + 0.06 * sin(_time * 3.0)))
	draw_colored_polygon(QuestItemArt.ellipse(p + Vector2(0, 20), 14.0, 4.0), Color(0, 0, 0, 0.35))
	var q := p + Vector2(0, bob)
	match kind:
		"commit":
			draw_line(q + Vector2(-14, 0), q + Vector2(14, 0), c.darkened(0.3), 3.0)
			for x in [-10.0, 0.0, 10.0]:
				draw_circle(q + Vector2(x, 0), 4.5, c)
			draw_line(q, q + Vector2(8, -10), c.darkened(0.3), 3.0)
			draw_circle(q + Vector2(8, -10), 4.0, c.lightened(0.3))
		"email":
			draw_rect(Rect2(q - Vector2(13, 9), Vector2(26, 18)), Color("f2ead8"))
			draw_polyline(PackedVector2Array([q + Vector2(-13, -9), q + Vector2(0, 2), q + Vector2(13, -9)]), c.darkened(0.3), 2.0)
		_:
			draw_rect(Rect2(q - Vector2(10, 13), Vector2(20, 26)), Color("101418"))
			for k in 4:
				draw_line(q + Vector2(-7, -8 + k * 5), q + Vector2(-7 + 6 + (k * 5) % 9, -8 + k * 5), c, 1.5)
	_label(p + Vector2(-110, -34 + bob), LoreNotes.KIND_NAMES.get(kind, "Archivo"), 220, 12, c)


## Un NPC que solo está "conectado": su cara en un monitor de fósforo verde.
func _draw_terminal_npc(ci: CanvasItem, pos: Vector2, appearance: Dictionary) -> void:
	ci.draw_rect(Rect2(pos + Vector2(-34, -6), Vector2(68, 10)), Color("3a2e26"))          # mesa
	var screen := Rect2(pos + Vector2(-28, -52), Vector2(56, 44))
	ci.draw_rect(screen.grow(4), Color("2a2a2e"))
	ci.draw_rect(screen, Color("031007"))
	var flicker := 0.7 + 0.3 * sin(_time * 23.0) * sin(_time * 7.0)
	CharacterAppearance.draw(ci, screen.position + Vector2(28, 52), 0.75, appearance, Vector2.DOWN, Color(PHOSPHOR, flicker))
	ci.draw_rect(screen.grow(4), Color(0.03, 0.06, 0.04), false, 2.0)
	for y in range(int(screen.position.y), int(screen.end.y), 3):
		ci.draw_line(Vector2(screen.position.x, y), Vector2(screen.end.x, y), Color(0, 0, 0, 0.3), 1.0)


## Los NPC van en su propia capa (z 1): sin pixelar, con la luz de la zona.
func _draw_npcs(ci: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		var pos := npc_position(npc)
		var appearance := CharacterAppearance.sanitize(npc.get("appearance", {}))
		var to_player := player.global_position - pos if player else Vector2.DOWN
		if npc.get("terminal", false):
			_draw_terminal_npc(ci, pos, appearance)
		else:
			CharacterAppearance.draw(ci, pos, 1.12, appearance, Vector2(signf(to_player.x) * 0.5, 1.0))
		var label_color := UiStyle.ACCENT if i == _hovered_npc else UiStyle.TEXT
		var label_pos := pos + Vector2(-110.0, -52.0)
		ci.draw_string_outline(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, 5, Color(0, 0, 0, 0.8))
		ci.draw_string(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, label_color)
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
			ci.draw_string_outline(font, pos + Vector2(-10.0, -70.0 + bounce), mark, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, 5, Color.BLACK)
			ci.draw_string(font, pos + Vector2(-10.0, -70.0 + bounce), mark, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, mark_color)
