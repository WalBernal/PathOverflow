class_name ItemDatabase
extends RefCounted
## Bases, afijos, únicos y conjuntos cargados desde data/items/*.json.

## Stats "locales": modifican la propia base del objeto (daño del arma,
## defensas de la armadura) en vez de sumarse al personaje.
const LOCAL_STATS := [
	"local_physical_increased", "local_added_physical", "local_attack_speed", "local_crit_increased",
	"local_defence_increased", "local_armour", "local_evasion", "local_energy_shield",
]

var bases: Dictionary = {}        # id -> Dictionary
var affixes: Array = []           # Dictionary
var uniques: Array = []           # Dictionary
var sets: Dictionary = {}         # id -> Dictionary
var set_pieces: Array = []        # {piece: Dictionary, set: Dictionary}
## Placas base y módulos RAM también son objetos (caen como botín).
var skills: SkillDatabase


static func load_from_dir(dir := "res://data/items", skills_dir := "res://data/skills") -> ItemDatabase:
	var db := ItemDatabase.new()
	db.skills = SkillDatabase.load_from_dir(skills_dir)
	for base in _section(dir + "/bases.json", "bases"):
		db.bases[base["id"]] = base
	db.affixes = _section(dir + "/affixes.json", "affixes")
	db.uniques = _section(dir + "/uniques.json", "uniques")
	for s in _section(dir + "/sets.json", "sets"):
		db.sets[s["id"]] = s
		for piece in s["pieces"]:
			db.set_pieces.append({"piece": piece, "set": s})
	return db


static func is_local(stat: String) -> bool:
	return LOCAL_STATS.has(stat)


func get_unique(id: String) -> Dictionary:
	for u in uniques:
		if u["id"] == id:
			return u
	return {}


func get_set_piece(id: String) -> Dictionary:
	for entry in set_pieces:
		if entry["piece"]["id"] == id:
			return entry
	return {}


static func _section(path: String, key: String) -> Array:
	var data = DataLoader.load_json(path)
	return data.get(key, []) if data is Dictionary else []
