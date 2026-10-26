class_name PassivePlan
extends RefCounted
## Planificador del árbol (T83). Un plan es una lista de nodos marcados sin gastar
## puntos, conectados a lo asignado (se calcula con una asignación «sombra» = lo
## asignado + lo planeado, así que los caminos y lo que se puede quitar siguen las
## mismas reglas). Aplicar el plan asigna los nodos en el orden en que se marcaron,
## hasta donde lleguen los puntos. Lleva el historial para deshacer y rehacer (lo
## asignado, las maestrías y el plan) y exporta la build como código de texto.

const HISTORY_MAX := 60
const CODE_PREFIX := "PO1:"

var real: PassiveAllocation
var shadow: PassiveAllocation
var _planned: Array[int] = []
var _undo: Array = []
var _redo: Array = []


func _init(p_real: PassiveAllocation) -> void:
	real = p_real
	_sync()


func planned_ids() -> Array[int]:
	return _planned.duplicate()


func is_planned(id: int) -> bool:
	return _planned.has(id)


## Marca el camino hasta `target` (desde lo asignado o lo ya planeado). Devuelve cuántos nodos añadió.
func plan_path(target: int) -> int:
	var path := shadow.find_path(target)
	if path.is_empty():
		return 0
	push_history()
	_planned.append_array(path)
	_sync()
	return path.size()


## Quita un nodo del plan si no deja otros planeados sin conexión.
func unplan(id: int) -> bool:
	if not _planned.has(id) or not shadow.can_refund(id):
		return false
	push_history()
	_planned.erase(id)
	_sync()
	return true


## Sustituye el plan por estos nodos (importar una build en partida: lo que no está
## asignado queda planeado; lo que no conecta, fuera). Devuelve cuántos quedan planeados.
func set_plan(ids: Array) -> int:
	push_history()
	_planned.clear()
	for raw in ids:
		var id := int(raw)
		if not real.is_allocated(id) and not _planned.has(id):
			_planned.append(id)
	_sync()
	return _planned.size()


## Vuelve a calcular la sombra (lo asignado cambió por fuera: maestrías, ascendencia, carga).
func refresh() -> void:
	_sync()


func clear_plan() -> void:
	if _planned.is_empty():
		return
	push_history()
	_planned.clear()
	_sync()


## Puntos que faltan para todo el plan.
func points_missing(available: int) -> int:
	return maxi(0, _planned.size() - available)


## Asigna lo planeado (en orden, cada nodo cuando ya toca algo asignado) mientras
## haya puntos. Devuelve los puntos gastados; lo asignado sale del plan.
func apply(points: int) -> int:
	if _planned.is_empty() or points <= 0:
		return 0
	push_history()
	var spent := 0
	var progress := true
	while progress and spent < points:
		progress = false
		for id in _planned.duplicate():
			if spent >= points:
				break
			if real.can_allocate(id) and real.allocate_path(id, 1) == 1:
				_planned.erase(id)
				spent += 1
				progress = true
	_planned = _planned.filter(func(id: int) -> bool: return not real.is_allocated(id))
	_sync()
	return spent


# --- Historial ---

func snapshot() -> Dictionary:
	return {"real": real.get_allocated_ids(), "masteries": real.mastery_choices_dict(), "plan": _planned.duplicate()}


## Guarda el estado actual antes de un cambio (lo llama quien cambia lo asignado).
func push_history() -> void:
	_undo.append(snapshot())
	if _undo.size() > HISTORY_MAX:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo() -> bool:
	if _undo.is_empty():
		return false
	_redo.append(snapshot())
	_restore(_undo.pop_back())
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	_undo.append(snapshot())
	_restore(_redo.pop_back())
	return true


func clear_history() -> void:
	_undo.clear()
	_redo.clear()


func _restore(state: Dictionary) -> void:
	real.load_mastery_choices(state["masteries"])   # antes: load_ids avisa del cambio y se recalcula con ellas
	real.load_ids(state["real"])
	_planned.assign(state["plan"])
	_planned = _planned.filter(func(id: int) -> bool: return not real.is_allocated(id))
	_sync()


func _sync() -> void:
	shadow = PassiveAllocation.new(real.tree, real.start_node_id)
	shadow.requirement_check = real.requirement_check   # las constelaciones también frenan el plan
	var ids: Array = real.get_allocated_ids()
	ids.append_array(_planned)
	shadow.load_ids(ids)
	# Lo que ya no conecta (se quitó un nodo asignado del que colgaba) sale del plan.
	_planned = _planned.filter(func(id: int) -> bool: return shadow.is_allocated(id) and not real.is_allocated(id))


# --- Código de build ---

## «PO1:» + base64 de un JSON comprimido con la clase, los nodos y las maestrías.
static func export_code(class_id: String, ids: Array, masteries: Dictionary) -> String:
	var data := JSON.stringify({"c": class_id, "n": ids, "m": masteries})
	var raw := data.to_utf8_buffer()
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	return CODE_PREFIX + str(raw.size()) + ":" + Marshalls.raw_to_base64(packed)


## {class, ids, masteries} del código, o {} si no es válido.
static func import_code(code: String) -> Dictionary:
	var c := code.strip_edges()
	if not c.begins_with(CODE_PREFIX):
		return {}
	var parts := c.substr(CODE_PREFIX.length()).split(":", false, 1)
	if parts.size() != 2 or not parts[0].is_valid_int():
		return {}
	var size := int(parts[0])
	if size <= 0 or size > 200000:
		return {}
	var packed := Marshalls.base64_to_raw(parts[1])
	if packed.is_empty():
		return {}
	var raw := packed.decompress(size, FileAccess.COMPRESSION_DEFLATE)
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not (parsed is Dictionary) or not (parsed.get("n") is Array):
		return {}
	var ids: Array[int] = []
	for v in parsed["n"]:
		ids.append(int(v))
	return {"class": String(parsed.get("c", "")), "ids": ids, "masteries": parsed.get("m", {}) if parsed.get("m") is Dictionary else {}}
