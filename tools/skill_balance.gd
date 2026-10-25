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
	# Habilidades iniciales de cada clase, con su arma inicial, contra el primer jefe.
	var boss_life := act1_boss_life()
	print("")
	print("Iniciales de cada clase con su arma (personaje nv %d, placa nv %d) contra El Arquitecto (%.0f de vida):" % [BOSS_CHAR_LEVEL, BOSS_BOARD_LEVEL, boss_life])
	for c in classes:
		for row in starter_rows(c, db, tree, boss_life):
			print("  %-12s %-24s %8.1f DPS  %6.0f s" % [c["id"], row[0], row[1], row[2]])
	quit()


const BOSS_CHAR_LEVEL := 10
const BOSS_BOARD_LEVEL := 8


## Vida del jefe del Acto I tal como la pone EnemyManager.spawn (dificultad Normal).
static func act1_boss_life() -> float:
	var act: Dictionary = DataLoader.load_json("res://data/act1.json")
	for z in act["zones"]:
		if z.get("boss") is Dictionary:
			var em := EnemyManager.new()
			em.area_level = int(z.get("level", 1))
			em.spawn(Vector2.ZERO, Rarity.Enemy.UNIQUE, em.type_index_of(String(z["boss"].get("type", "daemon"))), "", float(z["boss"].get("life_mult", 1.0)))
			var life := em.max_lives[0]
			em.free()
			return life
	return 0.0


## [habilidad, DPS, segundos contra `boss_life`] de las iniciales de la clase, con su arma.
static func starter_rows(class_def: Dictionary, db: ItemDatabase, tree: PassiveTree, boss_life: float) -> Array:
	var ch := CharacterData.new(class_def, tree)
	ch.level = BOSS_CHAR_LEVEL
	var weapon_id := String(class_def.get("starter_weapon", ""))
	if db.bases.has(weapon_id):
		ch.inventory.set_equipped("weapon", ItemGenerator.new(db, 1).generate(1, Rarity.Item.NORMAL, weapon_id))
	ch.recalculate()
	var out: Array = []
	for id in class_def.get("starter_skills", []):
		var p := SkillCalc.compute(Motherboard.new(db.skills.skills[id], BOSS_BOARD_LEVEL, []), ch)
		var dps := float(p.get("dps", 0.0))
		out.append([id, dps, boss_life / dps if dps > 0.0 else INF])
	return out
