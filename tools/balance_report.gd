extends SceneTree
## Tabla de equilibrio: DPS estimado de cada habilidad a nivel de personaje 30 y
## placa 20, con un personaje de su atributo (fuerza → guerrero, destreza →
## exploradora, inteligencia → hechicero) y un arma básica de su nivel. Sin RAM y
## con la mejor RAM de daño que encaja. Sirve para ver qué se sale de la media.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/balance_report.gd

const CLASS_BY_ATTR := {"str": "guerrero", "dex": "exploradora", "int": "hechicero"}


func _initialize() -> void:
	var db := ItemDatabase.load_from_dir()
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var classes: Array = DataLoader.load_json("res://data/classes.json")["classes"]
	var gen := ItemGenerator.new(db)
	var rows: Array = []
	# La misma arma para todos los ataques (si no, cada ejecución da cifras distintas).
	seed(30)
	var weapon := gen.generate(30, Rarity.Item.NORMAL)
	while not weapon.is_weapon():
		weapon = gen.generate(30, Rarity.Item.NORMAL)
	print("Arma de referencia: %s" % weapon.display_name())
	for id in db.skills.skills:
		var skill: Dictionary = db.skills.skills[id]
		var cls: Dictionary = classes.filter(func(c: Dictionary) -> bool: return c["id"] == CLASS_BY_ATTR.get(skill.get("attribute", "int"), "hechicero"))[0]
		var ch := CharacterData.new(cls, tree)
		ch.set_level(30)
		ch.inventory.equipment["weapon"] = weapon
		ch.recalculate()
		var base := SkillCalc.compute(Motherboard.new(skill, 20, []), ch)
		var best := 0.0
		var best_ram := "-"
		for rid in db.skills.rams:
			var ram := RamModule.new(db.skills.rams[rid])
			if not ram.supports(skill) or ram.special_string("deploy") != "":
				continue
			var b := Motherboard.new(skill, 20, [ram.generation()])
			b.install(ram, 0)
			var d: float = SkillCalc.compute(b, ch)["dps"]
			if d > best:
				best = d
				best_ram = rid
		rows.append([id, skill["kind"], base["dps"], best, best_ram])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	var total := 0.0
	var n := 0
	for r in rows:
		if r[2] > 0.0:
			total += r[2]
			n += 1
	var mean := total / maxf(1.0, n)
	print("DPS medio (habilidades con daño): %.0f" % mean)
	for r in rows:
		var flag := ""
		if r[2] > 0.0 and (r[2] > mean * 3.0 or r[2] < mean / 4.0):
			flag = "  <-- fuera de rango"
		print("%-26s %-14s %8.0f  con RAM %8.0f (%s)%s" % [r[0], r[1], r[2], r[3], r[4], flag])
	quit()
