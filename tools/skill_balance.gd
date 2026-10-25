extends SceneTree
## Balance de habilidades: DPS de cada placa a nivel 1 (y a nivel 10) con un
## personaje de nivel 1 sin pasivas ni objetos, ordenado de más a menos, con el
## nivel que pide (min_level) y su tipo. Sirve para ver qué habilidades iniciales
## pegan demasiado para lo poco que cuestan.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/skill_balance.gd [-- clase=guerrero]


func _initialize() -> void:
	var class_id := "guerrero"
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("clase="):
			class_id = String(arg).get_slice("=", 1)
	var classes: Array = DataLoader.load_json("res://data/classes.json").get("classes", [])
	var class_def: Dictionary = {}
	for c in classes:
		if c["id"] == class_id:
			class_def = c
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var db := ItemDatabase.load_from_dir()
	var ch := CharacterData.new(class_def, tree)
	var rows: Array = []
	for id in db.skills.skills:
		var def: Dictionary = db.skills.skills[id]
		var p1 := SkillCalc.compute(Motherboard.new(def, 1, []), ch)
		var p10 := SkillCalc.compute(Motherboard.new(def, 10, []), ch)
		rows.append([id, String(def.get("kind", "")), int(def.get("min_level", 1)), float(p1.get("dps", 0.0)), float(p10.get("dps", 0.0)), float(p1.get("mana_cost", 0.0))])
	rows.sort_custom(func(a, b) -> bool: return a[3] > b[3])
	print("DPS a nivel de placa 1 y 10 (personaje %s de nivel 1, sin pasivas ni objetos):" % class_id)
	print("  %-26s %-14s %6s %9s %9s %6s" % ["habilidad", "tipo", "nivel", "DPS p1", "DPS p10", "maná"])
	var dps_values: Array = []
	for r in rows:
		print("  %-26s %-14s %6d %9.1f %9.1f %6.1f" % r)
		if r[3] > 0.0:
			dps_values.append(r[3])
	dps_values.sort()
	if not dps_values.is_empty():
		print("Mediana del DPS a nivel 1: %.1f" % dps_values[dps_values.size() / 2])
	quit()
