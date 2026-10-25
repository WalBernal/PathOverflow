class_name SkillCalc
## Calcula las cifras finales de una habilidad: placa base (habilidad + nivel)
## + RAM instalada + stats del personaje. Lógica pura: la usan el combate, el
## HUD y los tooltips, así que lo que lees es exactamente lo que pasa.

## Segundos entre golpes de cada esbirro.
const MINION_ATTACK_INTERVAL := 0.9
const TAG_AUTOMATON := &"automaton"

## Daño por nivel de la placa base (sube con la experiencia, como las gemas de PoE):
## - Hechizos: base × (1 + growth × (nivel - 1)) × SPELL_LEVEL_MULT^(nivel - 1).
## - Ataques: arma × damage_effectiveness × (1 + ATTACK_GROWTH × (nivel - 1)).
##   (0.15 desde octubre de 2026: con 0.12 los ataques quedaban muy por debajo de
##   los hechizos a nivel 20 de placa; ver tools/balance_report.gd).
## Así el daño acompaña a la vida de los enemigos, que crece un 15 % por nivel de zona.
const SPELL_LEVEL_MULT := 1.03
const ATTACK_GROWTH := 0.15
## Además del daño, cada nivel de la placa da +1 % de área, ancho y duración y
## -1 % de enfriamiento; y en los niveles hito, un efecto extra según la habilidad.
const LEVEL_UTILITY := 0.01
const MILESTONES := [10, 20, 30]


## Hitos alcanzados por una placa de ese nivel (0 a 3).
static func milestones_reached(level: int) -> int:
	var n := 0
	for m in MILESTONES:
		if level >= m:
			n += 1
	return n


## Qué da cada hito a esta habilidad ("" si nada especial). Las invocaciones
## pueden definir el suyo en skills.json → milestone {kind, text}: units (+1 a la
## vez), projectiles (+1 proyectil), ability (+25 % de potencia de su habilidad
## propia) o toughness (+25 % de vida y +5 % de daño evitado).
static func milestone_text(skill: Dictionary) -> String:
	if skill.has("milestone"):
		return String(skill["milestone"].get("text", ""))
	match String(skill.get("kind", "")):
		"chain":
			return "+1 salto de cadena"
		"minion":
			return "+1 esbirro"
		"trap":
			return "+1 bomba a la vez"
		"drones":
			return "+1 dron"
		"aura":
			return "+15 % de efecto"
		"unit":
			return "+1 invocación a la vez"
		"rain":
			return "+2 impactos"
		"barrier":
			return "+20 % de barrera"
		"buff":
			return "+1 s de duración"
	if skill.has("projectiles"):
		return "+1 proyectil"
	if float(skill.get("radius", 0.0)) > 0.0:
		return "+10 % de área"
	return "+10 % de daño"


## Proyectiles que cuentan para el DPS de las invocaciones que disparan: todos los
## del abanico pueden acertar a enemigos distintos, pero se cuenta la mitad de los
## extra (no todos aciertan).
static func projectiles_or_one(n: int) -> float:
	return 1.0 + maxf(0.0, n - 1) * 0.5


## % de daño que quita un módulo Multicanal en una placa de ese nivel.
static func projectile_penalty(base_pct: float, board_level: int) -> float:
	return maxf(base_pct / 2.0, base_pct - (board_level - 1))


## ¿Dispara proyectiles? Las habilidades con "projectiles" y también los drones y
## las invocaciones con la etiqueta proyectil (disparan uno; las RAM añaden más).
static func shoots_projectiles(skill: Dictionary) -> bool:
	if skill.has("projectiles"):
		return true
	return String(skill.get("kind", "")) in ["unit", "drones"] and "projectile" in skill.get("tags", []) \
		and bool(skill.get("unit", {}).get("shoots", true))


static func kind_of(skill: Dictionary) -> String:
	return String(skill.get("kind", ""))


## Habilidades que invocan algo que ataca solo: la "repetición" (Pipeline) no las
## vuelve a lanzar, sino que hace que ataquen más a menudo.
const AUTOMATON_KINDS := ["unit", "drones", "minion"]


static func compute(board: Motherboard, character: CharacterData) -> Dictionary:
	return apply_variant(_compute_base(board, character), board)


## Variantes de habilidad (skills.json → "variants"): se eligen en el menú K
## desde cierto nivel de la placa y cambian cifras del perfil ("mult", "add") o
## las habilidades de la invocación ("abilities").
static func apply_variant(p: Dictionary, board: Motherboard) -> Dictionary:
	var v := board.active_variant()
	if v.is_empty():
		return p
	for key in v.get("mult", {}):
		var f := float(v["mult"][key])
		if key == "damage":
			for k in ["min_damage", "max_damage", "dps"]:
				p[k] = float(p[k]) * f
		elif p.has(key):
			p[key] = maxi(1, roundi(float(p[key]) * f)) if p[key] is int else float(p[key]) * f
	for key in v.get("add", {}):
		if p.has(key):
			p[key] = maxi(0, int(p[key]) + int(v["add"][key])) if p[key] is int else float(p[key]) + float(v["add"][key])
			if key == "max_units":
				p["dps"] = float(p["dps"]) * float(p["max_units"]) / maxf(1.0, float(p["max_units"]) - float(v["add"][key]))
	if v.has("abilities"):
		p["unit_abilities"] = v["abilities"]
	p["variant"] = v["id"]
	return p


static func _compute_base(board: Motherboard, character: CharacterData) -> Dictionary:
	var skill := board.skill_def
	var tags: Array = []
	for t in skill.get("tags", []):
		tags.append(StringName(t))
	# Condiciones activas (vida baja, muerte reciente...): activan sus modificadores.
	tags.append_array(character.condition_tags())

	var extra: Array[Modifier] = []
	var cost_mult := 1.0
	var extra_projectiles := 0
	var pierce := int(skill.get("pierce", 0))
	# Algunas habilidades se repiten solas (Fuzzing: varios tajos seguidos).
	var repeats := int(skill.get("repeats", 0))
	var area_mult := 1.0
	var extra_chains := 0
	# Encadenamiento: % de daño que se pierde en cada salto (-1 = sin penalización).
	var chain_penalty := -1.0
	var unit_reduction := 0.0
	# Multicanal: cada módulo quita daño por los proyectiles que añade (−40 % el de +1
	# en una placa de nivel 1); la penalización baja 1 punto por nivel, hasta la mitad.
	var projectile_penalties: Array[float] = []
	# Algunas habilidades se despliegan solas (p. ej. la Torreta de Integración Continua).
	var deploy: String = skill.get("deploy", "")
	var totem_duration: float = float(skill.get("totem_duration", 8.0)) if deploy != "" else 0.0
	for ram: RamModule in board.active_supports():
		extra_chains += int(ram.special("extra_chains"))
		if ram.special("chain_penalty") > 0.0:
			chain_penalty = ram.special("chain_penalty") if chain_penalty < 0.0 else minf(chain_penalty, ram.special("chain_penalty"))
		unit_reduction += ram.special("unit_reduction")
		# Solo cuenta el primer módulo de despliegue (una trampa no puede ser también una torreta).
		if deploy == "" and ram.special_string("deploy") != "":
			deploy = ram.special_string("deploy")
			totem_duration = ram.special("totem_duration", 8.0)
		extra.append_array(ram.skill_modifiers())
		cost_mult *= ram.cost_multiplier()
		extra_projectiles += int(ram.special("extra_projectiles"))
		if ram.special("projectile_penalty") > 0.0:
			projectile_penalties.append(ram.special("projectile_penalty"))
		if ram.special("homing") > 0.0 and not tags.has(&"homing"):
			tags.append(&"homing")
		pierce += int(ram.special("pierce"))
		repeats += int(ram.special("repeats"))
		area_mult *= ram.special("area_multiplier", 1.0)
	for pen in projectile_penalties:
		extra.append(Modifier.new(Stat.DAMAGE, Modifier.Type.MORE, -projectile_penalty(pen, board.level), [], "ram:multicanal"))
	# Conversión de daño (RAM "convert_to"): la habilidad pasa a hacer daño de otro
	# tipo (colores, resistencias, estados innatos y etiqueta del nuevo), y la
	# escalan los aumentos de los dos tipos. Solo cuenta el primer módulo que aplique.
	var damage_type: String = skill.get("damage_type", "none")
	var converted_from := ""
	for ram: RamModule in board.active_supports():
		var to := ram.special_string("convert_to")
		var from: Array = ram.def.get("special", {}).get("convert_from", [])
		if to != "" and damage_type != "none" and damage_type != to and (from.is_empty() or from.has(damage_type)):
			converted_from = damage_type
			damage_type = to
			if not tags.has(StringName(to)):
				tags.append(StringName(to))
			if to in ["fire", "cold", "lightning"] and not tags.has(&"elemental"):
				tags.append(&"elemental")
			break
	# Al convertirse en trampa, mina o torreta, la habilidad gana esa etiqueta
	# (los modificadores "de trampas" le afectan).
	if deploy != "" and not tags.has(StringName(deploy)):
		tags.append(StringName(deploy))
	# Autómatas: todo lo que ataca solo (torretas, drones, esbirros, robots).
	var kind := String(skill.get("kind", ""))
	if not tags.has(TAG_AUTOMATON) and (tags.has(&"totem") or tags.has(&"minion") or kind in ["drones", "unit"]):
		tags.append(TAG_AUTOMATON)
	# Mejoras por nivel de la placa.
	var lvl_mult := 1.0 + LEVEL_UTILITY * (board.level - 1)
	var milestones := milestones_reached(board.level)
	var bonus_text := milestone_text(skill)
	# Hito propio de la invocación (por defecto, +1 a la vez).
	var unit_ms := String(skill.get("milestone", {}).get("kind", "units")) if kind_of(skill) == "unit" else ""
	if bonus_text == "+10 % de área":
		area_mult *= 1.0 + 0.10 * milestones
	elif bonus_text == "+10 % de daño" and milestones > 0:
		extra.append(Modifier.new(Stat.DAMAGE, Modifier.Type.MORE, 10.0 * milestones, [], "board_level"))
	var stats := character.stats.duplicate_with(extra)

	var is_attack := tags.has(Stat.TAG_ATTACK)
	var min_base := 0.0
	var max_base := 0.0
	var flat_added := 0.0
	var uses_per_second := 1.0
	var crit_base := 0.0
	var damage_stat: StringName = Stat.DAMAGE_STAT_BY_TYPE.get(damage_type, &"")
	# Stats de daño que escalan la habilidad (con conversión, el original y el nuevo).
	var damage_stats: Array = [damage_stat]
	if converted_from != "" and Stat.DAMAGE_STAT_BY_TYPE.has(converted_from):
		damage_stats.append(Stat.DAMAGE_STAT_BY_TYPE[converted_from])
	# Los esbirros escalan con "daño de esbirros", no con el daño del personaje.
	if tags.has(&"minion"):
		damage_stat = Stat.MINION_DAMAGE
		damage_stats = [damage_stat]
	if is_attack:
		var weapon := character.weapon_values()
		var eff: float = skill["attack"].get("damage_effectiveness", 1.0) * (1.0 + ATTACK_GROWTH * (board.level - 1))
		min_base = weapon["min"] * eff
		max_base = weapon["max"] * eff
		uses_per_second = weapon["aps"] * stats.total_multiplier(Stat.ATTACK_SPEED, tags)
		crit_base = weapon["crit"]
		if damage_stat != &"":
			flat_added = stats.get_breakdown_union(damage_stats, tags)["flat"] * eff
	else:
		var spell: Dictionary = skill.get("spell", {})
		var growth := (1.0 + float(spell.get("damage_growth", 0.0)) * (board.level - 1)) * pow(SPELL_LEVEL_MULT, board.level - 1)
		min_base = float(spell.get("base_damage", [0, 0])[0]) * growth
		max_base = float(spell.get("base_damage", [0, 0])[1]) * growth
		uses_per_second = stats.total_multiplier(Stat.CAST_SPEED, tags) / maxf(0.05, float(spell.get("cast_time", 1.0)))
		crit_base = float(spell.get("crit", 5.0))

	var mult := 0.0
	if damage_stat != &"":
		var b := stats.get_breakdown(damage_stat, tags) if damage_stats.size() == 1 else stats.get_breakdown_union(damage_stats, tags)
		mult = maxf(0.0, 1.0 + b.increased / 100.0) * b.more
	if tags.has(&"minion"):
		# Las invocaciones escalan con "daño de esbirros", pero las RAM de su placa
		# (más daño, daño físico, elemental...) también les afectan, como en PoE.
		var ram_block := StatBlock.new()
		ram_block.add_modifiers(extra)
		var rb := ram_block.get_breakdown(Stat.DAMAGE_STAT_BY_TYPE.get(damage_type, Stat.DAMAGE), tags)
		mult *= maxf(0.0, 1.0 + rb.increased / 100.0) * rb.more
	var min_damage := (min_base + flat_added) * mult
	var max_damage := (max_base + flat_added) * mult
	var crit_chance := minf(100.0, crit_base * stats.total_multiplier(Stat.CRIT_CHANCE, tags))
	var crit_multiplier := stats.get_value(Stat.CRIT_MULTIPLIER, tags)
	var average := (min_damage + max_damage) / 2.0 * (1.0 + crit_chance / 100.0 * (crit_multiplier / 100.0 - 1.0))
	# Stats especiales (ascendencias): más proyectiles, cadenas, esbirros o dispositivos.
	var shoots := shoots_projectiles(skill)
	if shoots:
		extra_projectiles += int(stats.get_value(Stat.EXTRA_PROJECTILES, tags))
		if bonus_text == "+1 proyectil" or unit_ms == "projectiles":
			extra_projectiles += milestones
	extra_chains += int(stats.get_value(Stat.EXTRA_CHAINS, tags))
	if skill.has("projectiles") or kind in ["unit", "drones"]:
		pierce += int(stats.get_value(Stat.EXTRA_PIERCE, tags))
	if bonus_text == "+1 salto de cadena":
		extra_chains += milestones
	var base_projectiles := int(skill.get("projectiles", 1 if shoots else 0))
	var projectiles := base_projectiles + (extra_projectiles if shoots else 0)
	var mana_cost := roundf((float(skill.get("mana_cost", 0)) + float(skill.get("mana_per_level", 0)) * (board.level - 1)) * cost_mult
		* (1.0 - clampf(stats.get_value(Stat.MANA_COST_REDUCTION, tags), 0.0, 50.0) / 100.0))
	var cooldown := float(skill.get("cooldown", 0.0)) / maxf(0.1, stats.total_multiplier(Stat.COOLDOWN_RECOVERY, tags) * lvl_mult)
	var duration_mult := stats.total_multiplier(Stat.SKILL_DURATION, tags) * lvl_mult
	var duration := float(skill.get("duration", 0.0)) * duration_mult
	if bonus_text == "+1 s de duración":
		duration += milestones
	# Autómatas: más velocidad = disparan y golpean más a menudo.
	var automaton_speed := stats.total_multiplier(Stat.AUTOMATON_SPEED, tags) if tags.has(TAG_AUTOMATON) else 1.0
	var tick := float(skill.get("tick", 0.0))
	# Pipeline en invocaciones: no se vuelven a invocar, atacan más a menudo.
	var attack_rate := float(1 + repeats) if kind in AUTOMATON_KINDS else 1.0
	if kind == "drones":
		tick /= maxf(0.1, automaton_speed) * attack_rate
	var minion_interval := MINION_ATTACK_INTERVAL / (maxf(0.1, automaton_speed) * attack_rate)
	# Invocaciones persistentes (kind "unit"): no caducan, reservan maná.
	var unit: Dictionary = skill.get("unit", {})
	var aura: Dictionary = skill.get("aura", {})
	var extra_minions := int(stats.get_value(Stat.EXTRA_MINIONS, tags))
	var max_units := int(skill.get("max_active", 1)) + extra_minions + (milestones if unit_ms == "units" else 0)
	# Sobrealimentación (RAM): reserva más maná a cambio de más potencia.
	var reserve_mult := 1.0
	var aura_anchor := false
	var aura_on_unit := false
	var aura_radius_mult := 1.0
	# Costo en vida (RAM de "alimentación por vida"): parte del maná se paga con vida.
	var life_cost_frac := 0.0
	# Gasto de cargas al usar la habilidad (Buffer, Multihilos, Overclock).
	var spend := {}
	for ram: RamModule in board.active_supports():
		life_cost_frac += ram.special("life_cost")
		for t in Charges.TYPES:
			if ram.special("spend_" + t) > 0.0:
				spend[t] = true
		reserve_mult *= ram.special("reserve_mult", 1.0)
		aura_anchor = aura_anchor or ram.special("aura_anchor") > 0.0
		aura_on_unit = aura_on_unit or ram.special("aura_on_unit") > 0.0
		aura_radius_mult *= ram.special("aura_radius_mult", 1.0)
	var ability_power := 1.0 + (0.25 * milestones if unit_ms == "ability" else 0.0)
	var unit_interval := float(unit.get("interval", 1.0)) / (maxf(0.1, automaton_speed) * attack_rate)
	var unit_life := float(unit.get("life", 0.0)) * (1.0 + 0.12 * (board.level - 1)) * stats.total_multiplier(Stat.MINION_LIFE, tags) \
		* (1.0 + 0.25 * milestones if unit_ms == "toughness" else 1.0)
	var reserve := float(unit.get("reserve", aura.get("reserve", 0.0))) * reserve_mult / maxf(0.1, stats.total_multiplier(Stat.RESERVATION_EFFICIENCY, tags))
	# Auras: bonificaciones para tus aliados, escaladas por el nivel, los hitos y "efecto de aura".
	var aura_scale := stats.total_multiplier(Stat.AURA_EFFECT, tags) * (1.0 + 0.02 * (board.level - 1)) \
		* (1.0 + 0.15 * milestones if kind == "aura" else 1.0)
	# Golems: bono para su creador mientras vivan (unit.owner_buff), que crece con el
	# nivel de la placa (unit.buff_growth por nivel) y con el efecto de auras.
	var owner_buff: Array = []
	var buff_scale := (1.0 + float(unit.get("buff_growth", 0.0)) * (board.level - 1)) * stats.total_multiplier(Stat.AURA_EFFECT, tags)
	for md in unit.get("owner_buff", []):
		var scaled_buff: Dictionary = md.duplicate()
		scaled_buff["value"] = snappedf(float(md["value"]) * buff_scale, 0.1)
		owner_buff.append(scaled_buff)
	var aura_mods: Array = []
	for md in aura.get("mods", []):
		var scaled: Dictionary = md.duplicate()
		scaled["value"] = float(md["value"]) * aura_scale
		aura_mods.append(scaled)
	# Encadenamiento: la penalización mejora 1 punto por nivel de la placa (−30 % → −29 % → ...).
	var chain_damage := 1.0 if chain_penalty < 0.0 else clampf(1.0 - chain_penalty / 100.0 + 0.01 * (board.level - 1), 0.0, 1.0)
	# Lluvia: cada proyectil extra son dos impactos más.
	var rain_hits := int(skill.get("count", 0)) + (2 * milestones + 2 * extra_projectiles if kind == "rain" else 0)
	var hits_per_use := 1.0 if kind in AUTOMATON_KINDS else float(repeats + 1)
	match kind:
		"spin":
			hits_per_use *= maxf(1.0, floorf(duration / maxf(0.05, tick)))
		"boomerang":
			hits_per_use *= 2.0   # ida y vuelta contra el mismo objetivo
		"minion":
			# Cada esbirro golpea ~1 vez por segundo mientras dura.
			hits_per_use *= float(int(skill.get("count", 1)) + extra_minions + milestones) * maxf(1.0, duration / minion_interval)
		"degen_area", "curse_area", "dot_projectile", "backflip":
			hits_per_use *= maxf(1.0, duration)   # base_damage es por segundo (Git Revert: su zona helada)
		"ssh":
			hits_per_use *= 2.0   # descarga al salir y al llegar
		"drones":
			hits_per_use *= float(int(skill.get("count", 1)) + milestones + extra_minions) * maxf(1.0, duration / maxf(0.1, tick))
		"rain":
			hits_per_use *= maxf(1.0, rain_hits * 0.5)   # no todos los impactos caen sobre el mismo
	var casts := minf(uses_per_second, 1.0 / maxf(cooldown, 0.0001))
	var dps := average * casts * hits_per_use
	# Daño sostenido de lo que se queda en el campo: cuenta los que pueden estar
	# vivos a la vez (los lanzamientos de más solo los renuevan).
	match kind:
		"unit":
			dps = average * max_units * projectiles_or_one(projectiles) / maxf(0.1, unit_interval)
		"minion":
			var per_cast := float(int(skill.get("count", 1)) + extra_minions + milestones)
			var alive := minf(per_cast + int(skill.get("max_active", 0)), per_cast * casts * maxf(1.0, duration))
			dps = average * alive / maxf(0.1, minion_interval)
		"drones":
			var per_cast := float(int(skill.get("count", 1)) + milestones + extra_minions)
			var alive := minf(per_cast * 2.0, per_cast * casts * maxf(1.0, duration))
			dps = average * alive * projectiles_or_one(projectiles) / maxf(0.1, tick)
		"curse_area", "dot_projectile":
			dps = average   # el degenerativo no se acumula sobre el mismo enemigo: solo cuenta uno
		"degen_area":
			dps = average * clampf(casts * duration, 1.0, 3.0)   # charcos que se solapan (hasta 3)
	# Estados alterados: probabilidad por tipo, potencia y duración.
	var ailment_chances := Ailments.chances(stats, tags, skill if converted_from == "" else skill.merged({"damage_type": damage_type}, true))
	var ailment_effect := stats.total_multiplier(Stat.AILMENT_DAMAGE, tags)
	var ailment_duration := stats.total_multiplier(Stat.AILMENT_DURATION, tags)
	var ailing_bonus := stats.total_multiplier(Stat.AILING_DAMAGE, tags)
	# Contexto de cada golpe: tipo de daño (resistencias del enemigo), estados y bonus contra enemigos con estados.
	var ailment_ctx := {"type": damage_type, "chances": ailment_chances, "effect": ailment_effect, "duration": ailment_duration, "ailing": ailing_bonus}

	return {
		"id": skill["id"],
		"def": skill,
		"name": skill["name"],
		"kind": skill["kind"],
		"damage_type": damage_type,
		# Tipo original si una RAM lo convirtió ("" si no).
		"converted_from": converted_from,
		"tags": tags,
		"min_damage": min_damage,
		"max_damage": max_damage,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
		"uses_per_second": uses_per_second,
		"use_time": 1.0 / maxf(0.1, uses_per_second),
		"cooldown": cooldown,
		"mana_cost": roundf(mana_cost * (1.0 - clampf(life_cost_frac + float(skill.get("life_cost", 0.0)), 0.0, 1.0))),
		"life_cost": roundf(mana_cost * clampf(life_cost_frac + float(skill.get("life_cost", 0.0)), 0.0, 1.0)),
		"spend_charges": spend,
		"radius": float(skill.get("radius", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult * lvl_mult,
		# Escala de área sin radio base: la usan las habilidades de las invocaciones
		# (explosión de la mina, salto del bot, nube del agente IA).
		"area_scale": sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult * lvl_mult,
		"projectiles": projectiles,
		# Abanico: "|" con uno, "V" con dos, "\|/" con tres... (12° más por proyectil extra).
		"spread_degrees": float(skill.get("spread_degrees", 12.0 * maxi(0, base_projectiles - 1))) + 12.0 * (projectiles - base_projectiles),
		# Solo persiguen a los enemigos si la habilidad es teledirigida.
		"homing": kind == "homing" or tags.has(&"homing"),
		"projectile_speed": float(skill.get("projectile_speed", 0.0)) * stats.total_multiplier(Stat.PROJECTILE_SPEED, tags),
		"pierce": pierce,
		"range": float(skill.get("range", 0.0)),
		"delay": float(skill.get("delay", 0.0)),
		"repeats": repeats,
		"width": float(skill.get("width", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult * lvl_mult,
		"angle": float(skill.get("angle", 0.0)),
		"duration": duration,
		"tick": tick,
		"stun": float(skill.get("stun", 0.0)) * duration_mult,
		"trigger_radius": float(skill.get("trigger_radius", 0.0)),
		"max_active": int(skill.get("max_active", 0)) + (milestones if bonus_text == "+1 bomba a la vez" else 0),
		"chains": int(skill.get("chains", 0)) + (extra_chains if skill.get("kind", "") == "chain" else 0),
		"projectile_chains": extra_chains if (skill.has("projectiles") or kind in ["unit", "drones"]) else 0,
		"deploy": deploy,
		"totem_duration": totem_duration * duration_mult,
		"count": int(skill.get("count", 0)) + (int(stats.get_value(Stat.EXTRA_MINIONS, tags)) + milestones if skill.get("kind", "") == "minion" else 0),
		"extra_devices": int(stats.get_value(Stat.EXTRA_DEVICES, tags)),
		"drone_count": int(skill.get("count", 0)) + milestones + extra_minions if kind == "drones" else 0,
		# Alcance con el que buscan enemigo los teledirigidos (y los drones al disparar).
		"seek_range": maxf(float(skill.get("seek_range", 0.0)), 450.0 if tags.has(&"homing") else 0.0),
		"turn_rate": float(skill.get("turn_rate", 6.0)),
		"buff_mods": skill.get("buff_mods", []),
		"barrier": (float(skill.get("barrier", 0.0)) * (1.0 + 0.1 * (board.level - 1)) + float(skill.get("barrier_life", 0.0)) * stats.get_value(Stat.LIFE)) \
			* (1.0 + 0.2 * milestones if bonus_text == "+20 % de barrera" else 1.0),
		"chain_range": float(skill.get("chain_range", 0.0)),
		"life_leech": stats.get_value(Stat.LIFE_LEECH, tags),
		"dps": dps,
		"ailments": ailment_chances,
		"ailment_effect": ailment_effect,
		"ailment_duration": ailment_duration,
		"ailment_ctx": ailment_ctx,
		"automaton_speed": automaton_speed,
		"minion_interval": minion_interval,
		"rain_hits": rain_hits,
		"impact_radius": float(skill.get("impact_radius", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult * lvl_mult,
		"unit": unit,
		"max_units": max_units,
		"unit_life": unit_life,
		"unit_interval": unit_interval,
		"reserve": reserve,
		"chain_damage": chain_damage,
		"ailing_bonus": ailing_bonus,
		"aura_mods": aura_mods,
		"owner_buff": owner_buff,
		"aura_regen": float(aura.get("regen", 0.0)) * aura_scale,
		"aura_reduction": minf(0.6, float(aura.get("reduction", 0.0)) * aura_scale),
		# Alcance del aura alrededor del jugador (crece con el área y el nivel de la placa).
		"aura_radius": float(aura.get("radius", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * lvl_mult * aura_radius_mult,
		# Torre de Señal: el aura se queda donde se activa en vez de seguirte.
		"aura_anchor": aura_anchor,
		# Enlace de Aura: el aura va sobre la invocación más resistente.
		"aura_on_unit": aura_on_unit,
		# Auras que debilitan: efectos sobre los enemigos dentro del radio.
		"aura_enemy": {} if not aura.has("enemy") else {
			"slow": minf(0.5, float(aura["enemy"].get("slow", 0.0)) * aura_scale),
			"damage_taken": minf(0.6, float(aura["enemy"].get("damage_taken", 0.0)) * aura_scale)},
		"unit_reduction": minf(0.7, float(unit.get("reduction", 0.0)) + unit_reduction + (0.05 * milestones if unit_ms == "toughness" else 0.0)),
		# Potencia de la habilidad propia de la invocación (curación, barrera, salto, veneno, explosión).
		"ability_power": ability_power,
		"unit_shoots": bool(unit.get("shoots", true)),
		"unit_ability": unit.get("ability", {}),
		# Invocaciones fuertes con varias habilidades (cada una con su enfriamiento).
		"unit_abilities": unit.get("abilities", [unit["ability"]] if unit.has("ability") else []),
	}
