class_name LoreNotes
## Lore coleccionable (data/lore_notes.json): commits perdidos, logs y correos de
## la UAdeO por las zonas. Los encontrados se guardan en flags["lore_found"].

const PATH := "res://data/lore_notes.json"
const FLAG := "lore_found"
const KIND_NAMES := {"commit": "Commit perdido", "log": "Log", "email": "Correo"}
const KIND_COLORS := {"commit": Color("6fd36b"), "log": Color("8ad8ff"), "email": Color("f2c14e")}

static var _notes: Array = []


static func all() -> Array:
	if _notes.is_empty():
		var data = DataLoader.load_json(PATH)
		_notes = data.get("notes", []) if data is Dictionary else []
	return _notes


static func for_zone(zone_id: String) -> Array:
	return all().filter(func(n: Dictionary) -> bool: return n["zone"] == zone_id)


static func found_ids(c: CharacterData) -> Array:
	var raw = c.flags.get(FLAG, [])
	return raw if raw is Array else []


static func is_found(c: CharacterData, id: String) -> bool:
	return found_ids(c).has(id)


## Lo apunta como encontrado. false si ya lo estaba.
static func mark_found(c: CharacterData, id: String) -> bool:
	var ids := found_ids(c).duplicate()
	if ids.has(id):
		return false
	ids.append(id)
	c.flags[FLAG] = ids
	return true


## Los encontrados, en el orden del archivo (por actos).
static func found(c: CharacterData) -> Array:
	var ids := found_ids(c)
	return all().filter(func(n: Dictionary) -> bool: return ids.has(n["id"]))


## Texto del archivo con el nombre del jugador donde diga {jugador}.
static func text_of(n: Dictionary, c: CharacterData) -> String:
	return String(n.get("text", "")).replace("{jugador}", c.character_name if c else "tú")
