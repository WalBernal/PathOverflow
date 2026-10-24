class_name SkillDatabase
extends RefCounted
## Habilidades activas (placas base) y soportes (módulos RAM) de data/skills.

var skills: Dictionary = {}   # id -> Dictionary
var rams: Dictionary = {}     # id -> Dictionary


static func load_from_dir(dir := "res://data/skills") -> SkillDatabase:
	var db := SkillDatabase.new()
	var s = DataLoader.load_json(dir + "/skills.json")
	if s is Dictionary:
		for def in s.get("skills", []):
			db.skills[def["id"]] = def
	# Variantes de habilidad en un archivo aparte (las de las invocaciones van en skills.json).
	var v = DataLoader.load_json(dir + "/variants.json")
	if v is Dictionary:
		for id in v.get("variants", {}):
			if db.skills.has(id):
				db.skills[id]["variants"] = db.skills[id].get("variants", []) + v["variants"][id]
	var r = DataLoader.load_json(dir + "/ram_modules.json")
	if r is Dictionary:
		for def in r.get("modules", []):
			db.rams[def["id"]] = def
	return db
