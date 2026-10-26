class_name PassiveTree
extends RefCounted
## Datos estáticos del árbol: nodos y aristas. Se carga una vez y lo comparten
## todos los personajes; lo que cada uno asigna vive en PassiveAllocation.

var nodes: Dictionary = {}       # int -> PassiveNode
var adjacency: Dictionary = {}   # int -> Array (ids vecinos)
var edges: Array[Vector2i] = []
var bounds := Rect2()
## Versión del árbol: si cambia, los ids de los nodos ya no significan lo mismo.
var version := 1
## Temáticas: id -> {name, color}. Clusters: id -> {id, theme, name, x, y, radius}.
var themes: Dictionary = {}
var clusters: Dictionary = {}


static func load_from_json(path: String) -> PassiveTree:
	var data = DataLoader.load_json(path)
	if not data is Dictionary:
		return null
	var tree := PassiveTree.new()
	tree.version = int(data.get("version", 1))
	tree.themes = data.get("themes", {})
	for c in data.get("clusters", []):
		tree.clusters[c["id"]] = c
	var first := true
	for nd in data.get("nodes", []):
		var n := PassiveNode.from_dict(nd)
		tree.nodes[n.id] = n
		tree.adjacency[n.id] = []
		if first:
			tree.bounds = Rect2(n.position, Vector2.ZERO)
			first = false
		else:
			tree.bounds = tree.bounds.expand(n.position)
	for e in data.get("edges", []):
		var a := int(e[0])
		var b := int(e[1])
		if not tree.nodes.has(a) or not tree.nodes.has(b):
			push_error("Arista %d-%d apunta a un nodo inexistente" % [a, b])
			continue
		tree.adjacency[a].append(b)
		tree.adjacency[b].append(a)
		tree.edges.append(Vector2i(a, b))
	for n: PassiveNode in tree.nodes.values():
		if n.key != "":
			tree.keys[n.key] = n.id
		if n.constellation != "":
			if not tree.constellations.has(n.constellation):
				tree.constellations[n.constellation] = [] as Array[int]
			tree.constellations[n.constellation].append(n.id)
		if n.socket:
			tree._sockets.append(n.id)
	return tree


## Constelación (nombre) -> ids de sus nodos (T93: completarla da su bono extra).
var constellations: Dictionary = {}


## Clave estable (árbol 2.0, T89) -> id del nodo. Las maestrías, el estilo y las
## constelaciones vienen dentro del árbol (los parches por id ya no existen).
var keys: Dictionary = {}


func id_for_key(node_key: String) -> int:
	return int(keys.get(node_key, -1))


func get_node_data(id: int) -> PassiveNode:
	return nodes.get(id)


func theme_color(theme: String) -> Color:
	return Color(themes[theme]["color"]) if themes.has(theme) else Color("8a8293")


func theme_name(theme: String) -> String:
	return themes[theme]["name"] if themes.has(theme) else ""


func cluster_name(cluster_id: String) -> String:
	return clusters[cluster_id]["name"] if clusters.has(cluster_id) else ""


func neighbors(id: int) -> Array:
	return adjacency.get(id, [])


## Ranuras de chip de expansión: las marca el generador (`socket`, T93: las puertas
## entre clases y un cluster de cada región). Si un árbol no trae ninguna, una de cada
## seis notables por ángulo. Con el nodo asignado, admiten un ExpansionChip.
const SOCKET_EVERY := 6
var _sockets: Array[int] = []


func socket_ids() -> Array[int]:
	if _sockets.is_empty():
		var notables: Array = nodes.values().filter(func(n: PassiveNode) -> bool: return n.kind == PassiveNode.Kind.NOTABLE)
		notables.sort_custom(func(a: PassiveNode, b: PassiveNode) -> bool: return a.position.angle() < b.position.angle())
		for k in range(0, notables.size(), SOCKET_EVERY):
			_sockets.append((notables[k] as PassiveNode).id)
	return _sockets


func is_socket(id: int) -> bool:
	return id in socket_ids()


func get_start_node_for_class(class_id: StringName) -> int:
	for id in nodes:
		var n: PassiveNode = nodes[id]
		if n.kind == PassiveNode.Kind.CLASS_START and n.class_id == class_id:
			return n.id
	push_error("No hay nodo de inicio para la clase '%s'" % class_id)
	return -1
