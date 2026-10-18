class_name SkillCalc
## Calcula las cifras finales de una habilidad: placa base (habilidad + nivel)
## + RAM instalada + stats del personaje. Lógica pura: la usan el combate, el
## HUD y los tooltips, así que lo que lees es exactamente lo que pasa.

## Daño por nivel de los hechizos: base × (1 + growth × (nivel - 1)).
## Los ataques usan el arma × damage_effectiveness.


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
	var repeats := 0
	var area_mult := 1.0
	for ram: RamModule in board.active_supports():
		extra.append_array(ram.skill_modifiers())
		cost_mult *= ram.cost_multiplier()
		extra_projectiles += int(ram.special("extra_projectiles"))
		pierce += int(ram.special("pierce"))
		repeats += int(ram.special("repeats"))
		area_mult *= ram.special("area_multiplier", 1.0)
	var stats := character.stats.duplicate_with(extra)

	var is_attack := tags.has(Stat.TAG_ATTACK)
	var min_base := 0.0
	var max_base := 0.0
	var flat_added := 0.0
	var uses_per_second := 1.0
	var crit_base := 0.0
	var damage_type: String = skill.get("damage_type", "none")
	var damage_stat: StringName = Stat.DAMAGE_STAT_BY_TYPE.get(damage_type, &"")
	if is_attack:
		var weapon := character.weapon_values()
		var eff: float = skill["attack"].get("damage_effectiveness", 1.0)
		min_base = weapon["min"] * eff
		max_base = weapon["max"] * eff
		uses_per_second = weapon["aps"] * stats.total_multiplier(Stat.ATTACK_SPEED, tags)
		crit_base = weapon["crit"]
		if damage_stat != &"":
			flat_added = stats.get_breakdown(damage_stat, tags)["flat"] * eff
	else:
		var spell: Dictionary = skill.get("spell", {})
		var growth := 1.0 + float(spell.get("damage_growth", 0.0)) * (board.level - 1)
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
	var projectiles := int(skill.get("projectiles", 0)) + (extra_projectiles if skill.has("projectiles") else 0)
	var mana_cost := roundf((float(skill.get("mana_cost", 0)) + float(skill.get("mana_per_level", 0)) * (board.level - 1)) * cost_mult)
	var cooldown := float(skill.get("cooldown", 0.0)) / maxf(0.1, stats.total_multiplier(Stat.COOLDOWN_RECOVERY, tags))
	var duration_mult := stats.total_multiplier(Stat.SKILL_DURATION, tags)
	var duration := float(skill.get("duration", 0.0)) * duration_mult
	var tick := float(skill.get("tick", 0.0))
	var hits_per_use := float(repeats + 1)
	match String(skill["kind"]):
		"spin":
			hits_per_use *= maxf(1.0, floorf(duration / maxf(0.05, tick)))
		"boomerang":
			hits_per_use *= 2.0   # ida y vuelta contra el mismo objetivo
	var dps := average * minf(uses_per_second, 1.0 / maxf(cooldown, 0.0001)) * hits_per_use

	return {
		"id": skill["id"],
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
		"radius": float(skill.get("radius", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult,
		"projectiles": projectiles,
		"spread_degrees": float(skill.get("spread_degrees", 12.0 * maxi(0, projectiles - 1))) + 8.0 * extra_projectiles,
		"projectile_speed": float(skill.get("projectile_speed", 0.0)) * stats.total_multiplier(Stat.PROJECTILE_SPEED, tags),
		"pierce": pierce,
		"range": float(skill.get("range", 0.0)),
		"delay": float(skill.get("delay", 0.0)),
		"repeats": repeats,
		"width": float(skill.get("width", 0.0)) * sqrt(stats.total_multiplier(Stat.AREA_OF_EFFECT, tags)) * area_mult,
		"angle": float(skill.get("angle", 0.0)),
		"duration": duration,
		"tick": tick,
		"stun": float(skill.get("stun", 0.0)) * duration_mult,
		"trigger_radius": float(skill.get("trigger_radius", 0.0)),
		"max_active": int(skill.get("max_active", 0)),
		"chains": int(skill.get("chains", 0)),
		"chain_range": float(skill.get("chain_range", 0.0)),
		"life_leech": stats.get_value(Stat.LIFE_LEECH, tags),
		"dps": dps,
	}
