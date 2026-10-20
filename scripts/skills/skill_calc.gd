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
## Así el daño acompaña a la vida de los enemigos, que crece un 15 % por nivel de zona.
const SPELL_LEVEL_MULT := 1.03
const ATTACK_GROWTH := 0.12
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


## Qué da cada hito a esta habilidad ("" si nada especial).
static func milestone_text(skill: Dictionary) -> String:
	match String(skill.get("kind", "")):
		"chain":
			return "+1 salto de cadena"
		"minion":
			return "+1 esbirro"
		"trap":
			return "+1 bomba a la vez"
		"drones":
			return "+1 dron"
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


static func compute(board: Motherboard, character: CharacterData) -> Dictionary:
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
	# Algunas habilidades se despliegan solas (p. ej. la Torreta de Integración Continua).
	var deploy: String = skill.get("deploy", "")
	var totem_duration: float = float(skill.get("totem_duration", 8.0)) if deploy != "" else 0.0
	for ram: RamModule in board.active_supports():
		extra_chains += int(ram.special("extra_chains"))
		# Solo cuenta el primer módulo de despliegue (una trampa no puede ser también una torreta).
		if deploy == "" and ram.special_string("deploy") != "":
			deploy = ram.special_string("deploy")
			totem_duration = ram.special("totem_duration", 8.0)
		extra.append_array(ram.skill_modifiers())
		cost_mult *= ram.cost_multiplier()
		extra_projectiles += int(ram.special("extra_projectiles"))
		pierce += int(ram.special("pierce"))
		repeats += int(ram.special("repeats"))
		area_mult *= ram.special("area_multiplier", 1.0)
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
	var damage_type: String = skill.get("damage_type", "none")
	var damage_stat: StringName = Stat.DAMAGE_STAT_BY_TYPE.get(damage_type, &"")
	# Los esbirros escalan con "daño de esbirros", no con el daño del personaje.
	if tags.has(&"minion"):
		damage_stat = Stat.MINION_DAMAGE
	if is_attack:
		var weapon := character.weapon_values()
		var eff: float = skill["attack"].get("damage_effectiveness", 1.0) * (1.0 + ATTACK_GROWTH * (board.level - 1))
		min_base = weapon["min"] * eff
		max_base = weapon["max"] * eff
		uses_per_second = weapon["aps"] * stats.total_multiplier(Stat.ATTACK_SPEED, tags)
		crit_base = weapon["crit"]
		if damage_stat != &"":
			flat_added = stats.get_breakdown(damage_stat, tags)["flat"] * eff
	else:
		var spell: Dictionary = skill.get("spell", {})
		var growth := (1.0 + float(spell.get("damage_growth", 0.0)) * (board.level - 1)) * pow(SPELL_LEVEL_MULT, board.level - 1)
		min_base = float(spell.get("base_damage", [0, 0])[0]) * growth
		max_base = float(spell.get("base_damage", [0, 0])[1]) * growth
		uses_per_second = stats.total_multiplier(Stat.CAST_SPEED, tags) / maxf(0.05, float(spell.get("cast_time", 1.0)))
		crit_base = float(spell.get("crit", 5.0))

	var mult := 0.0
	if damage_stat != &"":
		var b := stats.get_breakdown(damage_stat, tags)
		mult = maxf(0.0, 1.0 + b.increased / 100.0) * b.more
	var min_damage := (min_base + flat_added) * mult
	var max_damage := (max_base + flat_added) * mult
	var crit_chance := minf(100.0, crit_base * stats.total_multiplier(Stat.CRIT_CHANCE, tags))
	var crit_multiplier := stats.get_value(Stat.CRIT_MULTIPLIER, tags)
	var average := (min_damage + max_damage) / 2.0 * (1.0 + crit_chance / 100.0 * (crit_multiplier / 100.0 - 1.0))
	# Stats especiales (ascendencias): más proyectiles, cadenas, esbirros o dispositivos.
	if skill.has("projectiles"):
		extra_projectiles += int(stats.get_value(Stat.EXTRA_PROJECTILES, tags))
		if bonus_text == "+1 proyectil":
			extra_projectiles += milestones
	extra_chains += int(stats.get_value(Stat.EXTRA_CHAINS, tags))
	if bonus_text == "+1 salto de cadena":
		extra_chains += milestones
	var projectiles := int(skill.get("projectiles", 0)) + (extra_projectiles if skill.has("projectiles") else 0)
	var mana_cost := roundf((float(skill.get("mana_cost", 0)) + float(skill.get("mana_per_level", 0)) * (board.level - 1)) * cost_mult)
	var cooldown := float(skill.get("cooldown", 0.0)) / maxf(0.1, stats.total_multiplier(Stat.COOLDOWN_RECOVERY, tags) * lvl_mult)
	var duration_mult := stats.total_multiplier(Stat.SKILL_DURATION, tags) * lvl_mult
	var duration := float(skill.get("duration", 0.0)) * duration_mult
	if bonus_text == "+1 s de duración":
		duration += milestones
	# Autómatas: más velocidad = disparan y golpean más a menudo.
	var automaton_speed := stats.total_multiplier(Stat.AUTOMATON_SPEED, tags) if tags.has(TAG_AUTOMATON) else 1.0
	var tick := float(skill.get("tick", 0.0))
	if kind == "drones":
		tick /= maxf(0.1, automaton_speed)
	var minion_interval := MINION_ATTACK_INTERVAL / maxf(0.1, automaton_speed)
	# Invocaciones persistentes (kind "unit"): no caducan, reservan maná.
	var unit: Dictionary = skill.get("unit", {})
	var extra_minions := int(stats.get_value(Stat.EXTRA_MINIONS, tags))
	var max_units := int(skill.get("max_active", 1)) + extra_minions + (milestones if kind == "unit" else 0)
	var unit_interval := float(unit.get("interval", 1.0)) / maxf(0.1, automaton_speed)
	var unit_life := float(unit.get("life", 0.0)) * (1.0 + 0.12 * (board.level - 1)) * stats.total_multiplier(Stat.MINION_LIFE, tags)
	var reserve := float(unit.get("reserve", 0.0)) / maxf(0.1, stats.total_multiplier(Stat.RESERVATION_EFFICIENCY, tags))
	var rain_hits := int(skill.get("count", 0)) + (2 * milestones if kind == "rain" else 0)
	var hits_per_use := float(repeats + 1)
	match kind:
		"spin":
			hits_per_use *= maxf(1.0, floorf(duration / maxf(0.05, tick)))
		"boomerang":
			hits_per_use *= 2.0   # ida y vuelta contra el mismo objetivo
		"minion":
			# Cada esbirro golpea ~1 vez por segundo mientras dura.
			hits_per_use *= float(int(skill.get("count", 1)) + extra_minions + milestones) * maxf(1.0, duration / minion_interval)
		"degen_area", "curse_area", "dot_projectile":
			hits_per_use *= maxf(1.0, duration)   # base_damage es por segundo
		"drones":
			hits_per_use *= float(int(skill.get("count", 1)) + milestones + extra_minions) * maxf(1.0, duration / maxf(0.1, tick))
		"rain":
			hits_per_use *= maxf(1.0, rain_hits * 0.5)   # no todos los impactos caen sobre el mismo
	var dps := average * minf(uses_per_second, 1.0 / maxf(cooldown, 0.0001)) * hits_per_use
	if kind == "unit":
		# Daño sostenido de todas las invocaciones a la vez.
		dps = average * max_units / maxf(0.1, unit_interval)
	# Estados alterados: probabilidad por tipo, potencia y duración.
	var ailment_chances := Ailments.chances(stats, tags, skill)
	var ailment_effect := stats.total_multiplier(Stat.AILMENT_DAMAGE, tags)
	var ailment_duration := stats.total_multiplier(Stat.AILMENT_DURATION, tags)
	var ailment_ctx := {} if ailment_chances.is_empty() else {"chances": ailment_chances, "effect": ailment_effect, "duration": ailment_duration}

	return {
		"id": skill["id"],
		"def": skill,
		"name": skill["name"],
		"kind": skill["kind"],
		"damage_type": damage_type,
		"tags": tags,
		"min_damage": min_damage,
		"max_damage": max_damage,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
		"uses_per_second": uses_per_second,
		"use_time": 1.0 / maxf(0.1, uses_per_second),
		"cooldown": cooldown,
		"mana_cost": mana_cost,
		"radius": float(skill.get("radius", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult * lvl_mult,
		"projectiles": projectiles,
		"spread_degrees": float(skill.get("spread_degrees", 12.0 * maxi(0, projectiles - 1))) + 8.0 * extra_projectiles,
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
		"projectile_chains": extra_chains if skill.has("projectiles") else 0,
		"deploy": deploy,
		"totem_duration": totem_duration * duration_mult,
		"count": int(skill.get("count", 0)) + (int(stats.get_value(Stat.EXTRA_MINIONS, tags)) + milestones if skill.get("kind", "") == "minion" else 0),
		"extra_devices": int(stats.get_value(Stat.EXTRA_DEVICES, tags)),
		"drone_count": int(skill.get("count", 0)) + milestones + extra_minions if kind == "drones" else 0,
		"seek_range": float(skill.get("seek_range", 0.0)),
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
	}
