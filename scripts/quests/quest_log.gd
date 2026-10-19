class_name QuestLog
extends RefCounted
## Misiones del personaje (data/quests.json). Lógica pura: el estado vive en
## character.flags["quests"] = {id: {step, count, done}} y se guarda con él.
## World le avisa de lo que pasa (zonas, muertes, diálogos, objetos) y ella
## avanza los pasos y emite señales para la UI y las recompensas.

signal quest_started(id: String)
signal quest_progressed(id: String)
signal quest_completed(id: String)

const DATA_PATH := "res://data/quests.json"
const RARITY_BY_NAME := {"normal": 0, "special": 1, "elite": 2, "unique": 3}

static var _db: Dictionary = {}

var character: CharacterData
var defs: Dictionary


static func database() -> Dictionary:
	if _db.is_empty():
		var data = DataLoader.load_json(DATA_PATH)
		if data is Dictionary:
			_db = data.get("quests", {})
	return _db


func _init(p_character: CharacterData, p_defs: Dictionary = {}) -> void:
	character = p_character
	defs = p_defs if not p_defs.is_empty() else database()
	if not character.flags.get("quests") is Dictionary:
		character.flags["quests"] = {}


## Arranca las misiones automáticas y pone al día los pasos que ya se cumplen
## (personajes de antes de las misiones, banderas que ya tenían...).
func start_auto() -> void:
	# Personajes de antes de las misiones: las zonas con waypoint descubierto cuentan como visitadas.
	if not character.flags.has("visited_zones"):
		character.flags["visited_zones"] = character.flags.get("waypoints", []).duplicate()
	for id in defs:
		if defs[id].get("auto_start", false) and not _states().has(id):
			start(id)
	refresh()


func _states() -> Dictionary:
	return character.flags["quests"]


func state(id: String) -> Dictionary:
	return _states().get(id, {})


func is_active(id: String) -> bool:
	return _states().has(id) and not _states()[id].get("done", false)


func is_done(id: String) -> bool:
	return _states().has(id) and _states()[id].get("done", false)


func start(id: String) -> bool:
	if not defs.has(id) or _states().has(id):
		return false
	_states()[id] = {"step": 0, "count": 0, "done": false}
	character.flags["quest_%s_started" % id] = true
	quest_started.emit(id)
	refresh()
	return true


func current_step(id: String) -> Dictionary:
	var steps: Array = defs.get(id, {}).get("steps", [])
	var i := int(state(id).get("step", 0))
	return steps[i] if i < steps.size() else {}


## Texto del paso actual, con progreso si es de eliminar enemigos.
func step_text(id: String) -> String:
	var step := current_step(id)
	if step.is_empty():
		return ""
	var text: String = step.get("text", "")
	if step.get("type", "") == "kill":
		text += " (%d/%d)" % [mini(int(state(id).get("count", 0)), int(step.get("count", 1))), int(step.get("count", 1))]
	elif step.get("type", "") == "collect" and step.has("items"):
		text += " (%d/%d)" % [_collected(step), step["items"].size()]
	return text


func _collected(step: Dictionary) -> int:
	var n := 0
	for item_id in step.get("items", []):
		if character.flags.has("item_" + String(item_id)):
			n += 1
	return n


## Activas, la principal primero.
func active_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _states():
		if is_active(id) and defs.has(id):
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return defs[a].get("main", false) and not defs[b].get("main", false))
	return result


func notify_zone(zone_id: String) -> void:
	var visited: Array = character.flags.get("visited_zones", [])
	if not visited.has(zone_id):
		visited.append(zone_id)
		character.flags["visited_zones"] = visited
	refresh()


func notify_kill(zone_id: String, rarity: int, type_id := "") -> void:
	for id in active_ids():
		var step := current_step(id)
		if step.get("type", "") != "kill":
			continue
		if step.get("zone", "") != "" and step["zone"] != zone_id:
			continue
		if rarity < int(RARITY_BY_NAME.get(step.get("min_rarity", "normal"), 0)):
			continue
		if step.get("enemy_type", "") != "" and step["enemy_type"] != type_id:
			continue
		_states()[id]["count"] = int(_states()[id].get("count", 0)) + 1
		quest_progressed.emit(id)
	refresh()


## Entrega (paso turn_in): la llama la acción de diálogo quest_advance.
func advance(id: String) -> bool:
	if not is_active(id) or current_step(id).get("type", "") != "turn_in":
		return false
	_next_step(id)
	refresh()
	return true


## ¿Algún paso actual es entregar a este NPC?
func npc_has_turn_in(npc_id: String) -> bool:
	for id in active_ids():
		var step := current_step(id)
		if step.get("type", "") == "turn_in" and step.get("npc", "") == npc_id:
			return true
	return false


## ¿Este NPC tiene una misión que aún no se ha aceptado?
func npc_offers_quest(npc_id: String) -> bool:
	for id in defs:
		if defs[id].get("giver", "") == npc_id and not _states().has(id):
			return true
	return false


## Avanza todos los pasos que ya se cumplen.
func refresh() -> void:
	for id in _states().keys():
		if not is_active(id) or not defs.has(id):
			continue
		_skip_to_satisfied_flag(id)
		var guard := 0
		while is_active(id) and _satisfied(id, current_step(id)) and guard < 64:
			_next_step(id)
			guard += 1
		_update_ready_flag(id)


## Si un paso posterior ya se cumple (p. ej. personajes que ya mataron al jefe,
## o que fueron al campamento sin hablar con B.O.B.), se salta hasta él.
## No aplica a pasos de eliminar ni de entregar.
func _skip_to_satisfied_flag(id: String) -> void:
	var steps: Array = defs[id].get("steps", [])
	var i := int(state(id).get("step", 0))
	for j in range(steps.size() - 1, i, -1):
		if steps[j].get("type", "") in ["flag", "talk", "reach_zone", "collect"] and _satisfied(id, steps[j]):
			_states()[id]["step"] = j
			_states()[id]["count"] = 0
			quest_progressed.emit(id)
			return


func _satisfied(id: String, step: Dictionary) -> bool:
	match step.get("type", ""):
		"talk":
			return character.flags.has("talked_" + String(step.get("npc", "")))
		"reach_zone":
			return character.flags.get("visited_zones", []).has(step.get("zone", ""))
		"flag":
			return character.flags.has(step.get("flag", ""))
		"kill":
			return int(state(id).get("count", 0)) >= int(step.get("count", 1))
		"collect":
			if step.has("items"):
				return _collected(step) >= step["items"].size()
			return character.flags.has("item_" + String(step.get("item", "")))
	return false   # turn_in y desconocidos: no se cumplen solos


func _next_step(id: String) -> void:
	var s: Dictionary = _states()[id]
	s["step"] = int(s.get("step", 0)) + 1
	s["count"] = 0
	if s["step"] >= defs[id].get("steps", []).size():
		s["done"] = true
		character.flags["quest_%s_done" % id] = true
		character.flags.erase("quest_%s_ready" % id)
		quest_completed.emit(id)
		for other in defs:
			if defs[other].get("starts_after", "") == id:
				start(other)
	else:
		quest_progressed.emit(id)


func _update_ready_flag(id: String) -> void:
	var key := "quest_%s_ready" % id
	if is_active(id) and current_step(id).get("type", "") == "turn_in":
		character.flags[key] = true
	else:
		character.flags.erase(key)
