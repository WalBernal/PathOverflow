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
	tree.apply_masteries(DataLoader.load_json(MASTERIES_PATH))
	tree.apply_identity(DataLoader.load_json(IDENTITY_PATH))
	return tree


const IDENTITY_PATH := "res://data/passive_identity.json"
## Entradas de identidad que no se pudieron aplicar (el nodo cambió): para las pruebas.
var identity_mismatches: PackedStringArray = []


## Identidad del árbol (T84): notables de estilo por clase, piedras angulares nuevas
## y constelaciones que piden dos atributos (ver data/passive_identity.json).
func apply_identity(data: Variant) -> void:
	if not data is Dictionary:
		return
	for section in ["style", "keystones"]:
		var defs: Dictionary = data.get(section, {})
		for key in defs:
			var def: Dictionary = defs[key]
			var n: PassiveNode = nodes.get(int(key))
			if n == null or n.title != String(def.get("node", "")) or n.is_mastery():
				identity_mismatches.append("%s %s (%s)" % [section, key, def.get("node", "")])
				continue
			n.title = String(def.get("name", n.title))
			n.flavor = String(def.get("flavor", n.flavor))
			n.mods.clear()
			for md in def.get("mods", []):
				n.mods.append(Modifier.from_dict(md, "tree"))
			if section == "style":
				n.style = true
			else:
				n.capstone = true   # sigue siendo el notable de su cluster
	var constellations: Dictionary = data.get("constellations", {})
	for cluster_id in constellations:
		var def: Dictionary = constellations[cluster_id]
		var mult := float(def.get("mult", 1.0))
		var found := false
		for n: PassiveNode in nodes.values():
			if n.cluster != String(cluster_id) or n.kind == PassiveNode.Kind.CLASS_START:
				continue
			found = true
			n.constellation = String(def.get("name", ""))
			n.requires = def.get("requires", {})
			for m in n.mods:
				m.value *= mult   # piden más, dan más
		if not found:
			identity_mismatches.append("constelación %s" % cluster_id)


const MASTERIES_PATH := "res://data/passive_masteries.json"
## Maestrías que no se pudieron aplicar (el id ya no es ese notable): para las pruebas.
var mastery_mismatches: PackedStringArray = []


## Convierte en maestría los notables de data/passive_masteries.json (por id,
## comprobando el nombre: si el árbol cambió, se ignora y se apunta en mastery_mismatches).
func apply_masteries(data: Variant) -> void:
	if not data is Dictionary:
		return
	var defs: Dictionary = data.get("masteries", {})
	for key in defs:
		var def: Dictionary = defs[key]
		var n: PassiveNode = nodes.get(int(key))
		if n == null or n.title != String(def.get("node", "")):
			mastery_mismatches.append("%s (%s)" % [key, def.get("node", "")])
			continue
		n.title = String(def.get("name", n.title))
		n.mods.clear()
		for c in def.get("choices", []):
			var mods: Array[Modifier] = []
			for md in c.get("mods", []):
				mods.append(Modifier.from_dict(md, "tree"))
			n.choices.append({"name": String(c.get("name", "")), "mods": mods})


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


## Ranuras de chip de expansión: 12 notables repartidas alrededor del árbol (una
## de cada seis, por ángulo). Con el nodo asignado, admiten un ExpansionChip.
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
