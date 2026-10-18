class_name PassiveTree
extends RefCounted
## Datos estáticos del árbol: nodos y aristas. Se carga una vez y lo comparten
## todos los personajes; lo que cada uno asigna vive en PassiveAllocation.

var nodes: Dictionary = {}       # int -> PassiveNode
var adjacency: Dictionary = {}   # int -> Array (ids vecinos)
var edges: Array[Vector2i] = []
var bounds := Rect2()


static func load_from_json(path: String) -> PassiveTree:
	var data = DataLoader.load_json(path)
	if not data is Dictionary:
		return null
	var tree := PassiveTree.new()
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
	return tree


func get_node_data(id: int) -> PassiveNode:
	return nodes.get(id)


func neighbors(id: int) -> Array:
	return adjacency.get(id, [])


func get_start_node_for_class(class_id: StringName) -> int:
	for id in nodes:
		var n: PassiveNode = nodes[id]
		if n.kind == PassiveNode.Kind.CLASS_START and n.class_id == class_id:
			return n.id
	push_error("No hay nodo de inicio para la clase '%s'" % class_id)
	return -1
