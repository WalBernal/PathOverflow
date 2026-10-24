class_name AscendancyTree
extends RefCounted
## Árbol de cada ascendencia (como en PoE 2): un inicio arriba y 20 nodos en
## cuatro ramas sobre el disco, con 8 notables (2 de ellas, las más profundas,
## con una habilidad única). Se asignan con puntos de ascendencia, cada nodo
## pegado al inicio o a otro ya asignado.
##
## Los datos de cada ascendencia (nombres y modificadores) están en
## data/ascendancy_trees.json; aquí van la forma del árbol y las reglas.
## expand_classes() sustituye las "passives" de classes.json por los 20 nodos.

const DATA_PATH := "res://data/ascendancy_trees.json"
## Versión del árbol: los guardados con otra versión devuelven los puntos.
const VERSION := 2
const NODE_COUNT := 20
## Índice que representa el inicio en "links".
const START := -1
## Posición del inicio (en radios del disco, el centro es 0,0).
const START_POS := Vector2(0.0, -0.8)

## Forma: posición (en radios del disco), enlaces y tipo de cada nodo.
## "minor" usa los modificadores menores de la ascendencia (ciclo de 3);
## "notable" y "unique" toman, en orden, las 8 notables de la ascendencia.
const TEMPLATE := [
	{"pos": Vector2(-0.30, -0.66), "links": [START], "kind": "minor", "minor": 0},   # 0
	{"pos": Vector2(-0.56, -0.48), "links": [0], "kind": "notable", "notable": 0},   # 1
	{"pos": Vector2(-0.72, -0.20), "links": [1], "kind": "minor", "minor": 1},       # 2
	{"pos": Vector2(-0.74, 0.12), "links": [2], "kind": "minor", "minor": 2},        # 3
	{"pos": Vector2(-0.58, 0.44), "links": [3], "kind": "notable", "notable": 4},    # 4
	{"pos": Vector2(-0.14, -0.50), "links": [START], "kind": "minor", "minor": 0},   # 5
	{"pos": Vector2(-0.28, -0.22), "links": [5], "kind": "minor", "minor": 1},       # 6
	{"pos": Vector2(-0.32, 0.10), "links": [6], "kind": "notable", "notable": 2},    # 7
	{"pos": Vector2(-0.30, 0.40), "links": [7, 4], "kind": "minor", "minor": 2},     # 8
	{"pos": Vector2(-0.18, 0.68), "links": [8], "kind": "unique", "notable": 6},     # 9
	{"pos": Vector2(0.14, -0.50), "links": [START], "kind": "minor", "minor": 0},    # 10
	{"pos": Vector2(0.28, -0.22), "links": [10], "kind": "minor", "minor": 1},      # 11
	{"pos": Vector2(0.32, 0.10), "links": [11], "kind": "notable", "notable": 3},   # 12
	{"pos": Vector2(0.30, 0.40), "links": [12, 19], "kind": "minor", "minor": 2},   # 13
	{"pos": Vector2(0.18, 0.68), "links": [13], "kind": "unique", "notable": 7},    # 14
	{"pos": Vector2(0.30, -0.66), "links": [START], "kind": "minor", "minor": 0},   # 15
	{"pos": Vector2(0.56, -0.48), "links": [15], "kind": "notable", "notable": 1},  # 16
	{"pos": Vector2(0.72, -0.20), "links": [16], "kind": "minor", "minor": 1},      # 17
	{"pos": Vector2(0.74, 0.12), "links": [17], "kind": "minor", "minor": 2},       # 18
	{"pos": Vector2(0.58, 0.44), "links": [18], "kind": "notable", "notable": 5},   # 19
]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = DataLoader.load_json(DATA_PATH)
		_data = d if d is Dictionary else {}
	return _data


## Sustituye las pasivas de cada ascendencia por su árbol de 20 nodos (si está
## en ascendancy_trees.json). Se llama al cargar classes.json.
static func expand_classes(classes: Array) -> void:
	var k := 0
	for c in classes:
		for a in c.get("ascendancies", []):
			var def: Dictionary = data().get(String(a["id"]), {}).duplicate()
			if not def.is_empty():
				# Forma por orden (las dos de una clase nunca comparten forma ni lado).
				if not def.has("shape"):
					def["shape"] = SHAPES[(k * 3 + k / SHAPES.size()) % SHAPES.size()]
				if not def.has("mirror"):
					def["mirror"] = k % 2 == 1
				a["passives"] = build(def, String(a["id"]))
				a["tree_version"] = VERSION
			k += 1


static func build(def: Dictionary, asc_id := "") -> Array:
	var minors: Array = def.get("minors", [])
	var notables: Array = def.get("notables", [])
	var shape: String = def.get("shape", SHAPES[absi(hash(asc_id)) % SHAPES.size()] if asc_id != "" else "fan")
	var mirror: bool = def.get("mirror", false)
	var nodes := []
	for t: Dictionary in TEMPLATE:
		var src: Dictionary = minors[int(t["minor"]) % minors.size()] if t["kind"] == "minor" else notables[int(t["notable"])]
		var mods := []
		for m in src.get("mods", []):
			mods.append(parse_mod(m) if m is String else m)
		nodes.append({"name": src["name"], "mods": mods, "pos": shape_pos(t["pos"], shape, mirror), "links": t["links"].duplicate(), "kind": t["kind"]})
	return nodes


## Formas del árbol: cada ascendencia dobla la plantilla a su manera (los enlaces
## no cambian, solo dónde se dibuja cada nodo). Se puede fijar con "shape" y
## "mirror" en ascendancy_trees.json.
const SHAPES := ["fan", "heart", "crown", "spiral", "wide"]


static func shape_pos(p: Vector2, shape: String, mirror: bool) -> Vector2:
	var q := p
	match shape:
		"heart":   # las ramas se cierran abajo, hacia el centro
			q.x *= 1.0 - 0.35 * maxf(q.y, 0.0)
			q.y += 0.06 * absf(q.x)
		"crown":   # las ramas de fuera suben como las puntas de una corona
			q.y -= 0.22 * absf(q.x) - 0.05
		"spiral":   # gira más cuanto más lejos del inicio
			var d := q.distance_to(START_POS)
			# (todo hacia el mismo lado: si cada mitad girara al contrario, se juntarían abajo)
			q = START_POS + (q - START_POS).rotated(0.22 * d)
		"wide":
			q = Vector2(q.x * 1.08, q.y * 0.9 + 0.04)
	if mirror:
		q.x = -q.x
	# Que nada se salga del disco.
	if q.length() > 0.84:
		q = q.normalized() * 0.84
	return q


## "stat tipo valor [tags...]" → {"stat", "type", "value", "tags"}.
static func parse_mod(text: String) -> Dictionary:
	var parts := text.split(" ", false)
	var d := {"stat": parts[0], "type": parts[1], "value": float(parts[2])}
	if parts.size() > 3:
		d["tags"] = Array(parts.slice(3))
	return d


## Nodos vecinos de `i` (en los dos sentidos); START si toca el inicio.
static func neighbors(nodes: Array, i: int) -> Array:
	var out: Array = nodes[i].get("links", [START]).duplicate()
	for j in nodes.size():
		if i in nodes[j].get("links", []):
			out.append(j)
	return out


## ¿Se puede asignar `i` con los nodos `taken`? (pegado al inicio o a uno asignado)
static func can_allocate(nodes: Array, taken: Array, i: int) -> bool:
	if i < 0 or i >= nodes.size() or i in taken:
		return false
	if not nodes[i].has("links"):
		return true   # ascendencia sin árbol (datos antiguos): libre
	for n in neighbors(nodes, i):
		if n == START or n in taken:
			return true
	return false


## ¿Siguen todos conectados al inicio si se quita `i`?
static func can_refund(nodes: Array, taken: Array, i: int) -> bool:
	if not i in taken:
		return false
	var rest := taken.filter(func(x: int) -> bool: return x != i)
	return connected(nodes, rest).size() == rest.size()


## Los nodos de `taken` que llegan al inicio.
static func connected(nodes: Array, taken: Array) -> Array:
	var reached := []
	var frontier := [START]
	while not frontier.is_empty():
		var cur: int = frontier.pop_back()
		for j in taken:
			if j in reached:
				continue
			if cur == START:
				if START in nodes[j].get("links", [START]):
					reached.append(j)
					frontier.append(j)
			elif j in neighbors(nodes, cur):
				reached.append(j)
				frontier.append(j)
	return reached
