class_name PassiveAllocation
extends RefCounted
## Los nodos que ha asignado UN personaje sobre el árbol compartido.
## Reglas: solo se asigna un nodo adyacente a otro asignado; no se puede
## pasar por el inicio de otra clase; quitar un nodo no puede desconectar otros.

signal changed

var tree: PassiveTree
var start_node_id := -1
var _allocated: Dictionary = {}  # int -> true


func _init(p_tree: PassiveTree, p_start_node_id: int) -> void:
	tree = p_tree
	start_node_id = p_start_node_id
	_allocated[start_node_id] = true


func is_allocated(id: int) -> bool:
	return _allocated.has(id)


func spent_points() -> int:
	return _allocated.size() - 1


func get_allocated_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_allocated.keys())
	return ids


## Nodos de inicio de otras clases: no se pueden asignar ni atravesar.
func is_blocked(id: int) -> bool:
	var n := tree.get_node_data(id)
	return n == null or (n.kind == PassiveNode.Kind.CLASS_START and id != start_node_id)


## Constelaciones (T84): `requirement_check.call(requires)` dice si el personaje tiene
## los atributos que pide un nodo. Solo frena asignar y planear caminos; lo ya
## asignado se carga igual aunque los atributos hayan bajado.
var requirement_check: Callable


## Piedras angulares asignadas que chocan con la del nodo `id` (T92), por nombre.
func conflicts_with(id: int) -> PackedStringArray:
	var out := PackedStringArray()
	var n := tree.get_node_data(id)
	if n == null or n.conflicts.is_empty():
		return out
	for other_id in _allocated:
		var o := tree.get_node_data(other_id)
		if o != null and other_id != id and o.title in n.conflicts:
			out.append(o.title)
	return out


func meets_requirements(id: int) -> bool:
	var n := tree.get_node_data(id)
	if n == null or n.requires.is_empty() or not requirement_check.is_valid():
		return true
	return bool(requirement_check.call(n.requires))


func can_allocate(id: int) -> bool:
	if _allocated.has(id) or is_blocked(id) or not meets_requirements(id):
		return false
	for nb in tree.neighbors(id):
		if _allocated.has(nb):
			return true
	return false


## Camino más corto (BFS) desde cualquier nodo asignado hasta `target`.
## Devuelve los nodos que habría que asignar, en orden. Vacío si no hay camino.
func find_path(target: int) -> Array[int]:
	var result: Array[int] = []
	if _allocated.has(target) or is_blocked(target) or not meets_requirements(target):
		return result
	var came_from := {}
	var queue: Array[int] = []
	for id in _allocated:
		came_from[id] = -1
		queue.append(id)
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		if cur == target:
			break
		for nb in tree.neighbors(cur):
			if came_from.has(nb) or is_blocked(nb) or (not _allocated.has(nb) and not meets_requirements(nb)):
				continue
			came_from[nb] = cur
			queue.append(nb)
	if not came_from.has(target):
		return result
	var step := target
	while not _allocated.has(step):
		result.push_front(step)
		step = came_from[step]
	return result


## Asigna el camino hasta `target` si cuesta como mucho `max_points`.
## Devuelve los puntos gastados (0 si no se pudo).
func allocate_path(target: int, max_points: int) -> int:
	var path := find_path(target)
	if path.is_empty() or path.size() > max_points:
		return 0
	for id in path:
		_allocated[id] = true
	changed.emit()
	return path.size()


func can_refund(id: int) -> bool:
	if id == start_node_id or not _allocated.has(id):
		return false
	# ¿Siguen todos los demás nodos conectados al inicio sin este?
	var seen := {start_node_id: true}
	var stack: Array[int] = [start_node_id]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		for nb in tree.neighbors(cur):
			if nb == id or seen.has(nb) or not _allocated.has(nb):
				continue
			seen[nb] = true
			stack.append(nb)
	return seen.size() == _allocated.size() - 1


func refund(id: int) -> bool:
	if not can_refund(id):
		return false
	_allocated.erase(id)
	changed.emit()
	return true


func reset() -> void:
	_allocated = {start_node_id: true}
	changed.emit()


## Restaura una partida guardada. Descarta los ids que ya no existen (el árbol
## cambió entre versiones) y los que quedan desconectados del inicio.
## Devuelve cuántos nodos se descartaron (= puntos devueltos al jugador).
func load_ids(ids: Array) -> int:
	_allocated = {start_node_id: true}
	var wanted := {}
	var requested := 0
	for raw in ids:
		var id := int(raw)  # JSON devuelve floats
		if id == start_node_id:
			continue
		requested += 1
		if tree.nodes.has(id) and not is_blocked(id):
			wanted[id] = true
	var stack: Array[int] = [start_node_id]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		for nb in tree.neighbors(cur):
			if wanted.has(nb) and not _allocated.has(nb):
				_allocated[nb] = true
				stack.append(nb)
	changed.emit()
	return requested - spent_points()


## `remap`: {id de nodo: {stat: stat}} de los chips que transforman (ExpansionChip.node_remap).
func collect_modifiers(remap: Dictionary = {}) -> Array[Modifier]:
	var mods: Array[Modifier] = []
	for id in _allocated:
		var n := tree.get_node_data(id)
		var own: Array = n.choices[mastery_choice(id)]["mods"] if n.is_mastery() else n.mods
		var map: Dictionary = remap.get(int(id), {})
		if map.is_empty():
			mods.append_array(own)
			continue
		for m: Modifier in own:
			mods.append(Modifier.new(StringName(map[String(m.stat)]), m.type, m.value, m.tags, m.source) if map.has(String(m.stat)) else m)
	for id in _allocated:
		var n := tree.get_node_data(id)
		if not n.complete_mods.is_empty() and constellation_complete(n.constellation):
			mods.append_array(n.complete_mods)
	return mods


## Constelación entera asignada (T93): su estrella da el bono extra.
func constellation_complete(constellation: String) -> bool:
	var ids: Array = tree.constellations.get(constellation, [])
	return not ids.is_empty() and ids.all(func(i: int) -> bool: return _allocated.has(i))


# --- Maestrías: qué opción tiene elegida cada una (por defecto la primera) ---

var _mastery_choices: Dictionary = {}  # id -> índice


func mastery_choice(id: int) -> int:
	var n := tree.get_node_data(id)
	if n == null or not n.is_mastery():
		return 0
	return clampi(int(_mastery_choices.get(id, 0)), 0, n.choices.size() - 1)


## Cambia la opción de una maestría (gratis, como respec); solo con el nodo asignado.
func set_mastery_choice(id: int, index: int) -> bool:
	var n := tree.get_node_data(id)
	if n == null or not n.is_mastery() or not _allocated.has(id) or index < 0 or index >= n.choices.size():
		return false
	if mastery_choice(id) == index:
		return true
	_mastery_choices[id] = index
	changed.emit()
	return true


## Para el guardado: {"id": índice} solo de las que no están en la primera opción.
func mastery_choices_dict() -> Dictionary:
	var out := {}
	for id in _mastery_choices:
		if int(_mastery_choices[id]) != 0:
			out[str(id)] = int(_mastery_choices[id])
	return out


func load_mastery_choices(d: Dictionary) -> void:
	_mastery_choices.clear()
	for key in d:
		_mastery_choices[int(key)] = int(d[key])
