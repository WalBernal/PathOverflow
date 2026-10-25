extends SceneTree
## Auditoría de RAM: para cada habilidad, instala una a una las RAM compatibles
## y lista qué cambia de verdad en el perfil (SkillCalc). Una RAM compatible que
## no cambia nada útil sale marcada con «!!». Después prueba cada habilidad con
## 5 RAM a la vez (las que más cambian) y comprueba que el perfil es coherente.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/audit_rams.gd

## Claves del perfil que dicen algo del efecto (el maná no cuenta: todas lo suben).
const KEYS := ["dps", "min_damage", "projectiles", "spread_degrees", "pierce", "projectile_chains", "chains", "chain_damage",
	"projectile_speed", "homing", "radius", "width", "impact_radius", "rain_hits", "crit_chance", "crit_multiplier",
	"life_leech", "ailments", "ailment_effect", "ailment_duration", "ailing_bonus", "deploy", "totem_duration",
	"max_units", "unit_interval", "unit_life", "unit_reduction", "reserve", "aura_mods", "aura_regen", "aura_reduction",
	"tick", "minion_interval", "drone_count", "count", "extra_devices", "uses_per_second", "repeats", "automaton_speed",
	"trigger", "trigger_cooldown",
	# Las mismas que mira la auditoría de tests/test_core.gd (cargas, costo de vida, auras que debilitan y ancladas).
	"spend_charges", "life_cost", "aura_enemy", "aura_radius", "aura_anchor", "ability_power"]


func _initialize() -> void:
	var db := ItemDatabase.load_from_dir()
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var classes: Array = DataLoader.load_json("res://data/classes.json")["classes"]
	var ch := CharacterData.new(classes[0], tree)
	ch.set_level(30)
	var dead := 0
	for skill_id in db.skills.skills:
		var skill: Dictionary = db.skills.skills[skill_id]
		var base := SkillCalc.compute(Motherboard.new(skill, 10, ["DDR3"]), ch)
		var useful: Array = []
		var lines := PackedStringArray()
		for ram_id in db.skills.rams:
			var ram := RamModule.new(db.skills.rams[ram_id])
			if not ram.supports(skill):
				continue
			var board := Motherboard.new(skill, 10, [ram.generation()])
			board.install(ram, 0)
			var changed := _diff(base, SkillCalc.compute(board, ch))
			if changed.is_empty():
				dead += 1
				lines.append("   !! %s: no cambia nada" % ram_id)
			else:
				useful.append([ram_id, changed.size()])
				lines.append("   %s: %s" % [ram_id, ", ".join(changed)])
		print("%s (%s)" % [skill_id, skill["kind"]])
		for l in lines:
			print(l)
		# Cinco RAM a la vez: las que más cambian, cada una en su ranura.
		useful.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
		var board5 := Motherboard.new(skill, 20, [])
		var picked := PackedStringArray()
		for u in useful:
			if picked.size() >= 5:
				break
			var ram := RamModule.new(db.skills.rams[u[0]])
			if ram.special_string("deploy") != "" and picked.size() > 0:
				continue
			# Activación: como el despliegue, solo cuenta la primera.
			if ram.special_string("trigger") != "" and Array(picked).any(func(id: String) -> bool:
					return RamModule.new(db.skills.rams[id]).special_string("trigger") != ""):
				continue
			board5.slots.append(ram.generation())
			board5.rams.append(null)
			board5.install(ram, board5.slots.size() - 1)
			picked.append(u[0])
		var p5 := SkillCalc.compute(board5, ch)
		var ok: bool = p5["dps"] >= 0.0 and p5["mana_cost"] >= 0.0 and (p5["projectiles"] == 0 or p5["spread_degrees"] >= 0.0)
		print("   5 RAM [%s] -> dps %.0f, proyectiles %d, maná %.0f %s" % [", ".join(picked), p5["dps"], p5["projectiles"], p5["mana_cost"], "" if ok else "!! INCOHERENTE"])
	print("RAM compatibles sin efecto: %d" % dead)
	quit()


func _diff(a: Dictionary, b: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var keys: Array = KEYS.duplicate()
	if a["kind"] == "unit" and (a["unit_ability"].has("radius")
			or (a.get("unit_abilities", []) as Array).any(func(ab: Dictionary) -> bool: return ab.has("radius"))):
		keys.append("area_scale")   # radio de la habilidad (o habilidades, el Titán) de la invocación
	for k in keys:
		if not a.has(k):
			continue
		var x: Variant = a[k]
		var y: Variant = b[k]
		if (x is float or x is int) and (y is float or y is int):
			if absf(float(x) - float(y)) > 0.0001:
				out.append(k)
		elif str(x) != str(y):
			out.append(k)
	return out
