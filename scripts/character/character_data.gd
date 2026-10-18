class_name CharacterData
extends RefCounted
## Estado de un personaje: clase, ascendencia, nivel, apariencia, pasivas y equipo.
## Lógica pura (sin nodos): fácil de guardar y, en el futuro, de mover a un servidor.

signal stats_changed
signal leveled_up(new_level: int)

const MAX_LEVEL := 100
## Puntos extra que dan las misiones (en PoE son 24).
const QUEST_PASSIVE_POINTS := 22
const ATTACK_TAGS := [Stat.TAG_ATTACK, Stat.TAG_MELEE]
const BASE_ATTACK_RADIUS := 95.0
## Sin arma: puños.
const UNARMED := {"physical": [2.0, 5.0], "aps": 1.2, "crit": 5.0}

var character_name := "Exiliado sin nombre"
var class_def: Dictionary
var ascendancy_def: Dictionary = {}
var level := 1
var experience := 0
## Datos para el creador de personaje: índices de capas de sprite y colores.
## Se rellenarán cuando existan los sprites por capas.
var appearance := {
	"body": 0,
	"head": 0,
	"hair": 0,
	"skin_tone": "c99a7a",
	"hair_color": "2b2118",
}
var passives: PassiveAllocation
var inventory := Inventory.new()
var stats := StatBlock.new()


func _init(p_class_def: Dictionary, tree: PassiveTree) -> void:
	class_def = p_class_def
	passives = PassiveAllocation.new(tree, tree.get_start_node_for_class(StringName(class_def["id"])))
	passives.changed.connect(recalculate)
	inventory.changed.connect(recalculate)
	recalculate()


func set_level(value: int) -> void:
	level = clampi(value, 1, MAX_LEVEL)
	experience = 0
	recalculate()


## Experiencia necesaria para pasar del nivel actual al siguiente (curva provisional).
func experience_to_next() -> int:
	return int(80.0 * pow(level, 1.6))


func add_experience(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	experience += amount
	var leveled := false
	while level < MAX_LEVEL and experience >= experience_to_next():
		experience -= experience_to_next()
		level += 1
		leveled = true
	if leveled:
		recalculate()
		leveled_up.emit(level)


func set_ascendancy(asc_id: StringName) -> void:
	ascendancy_def = {}
	for a in class_def.get("ascendancies", []):
		if StringName(a["id"]) == asc_id:
			ascendancy_def = a
	recalculate()


func passive_points_total() -> int:
	return level - 1 + QUEST_PASSIVE_POINTS


func passive_points_available() -> int:
	return passive_points_total() - passives.spent_points()


func can_equip(item: Item) -> bool:
	return level >= item.required_level()


## Piezas equipadas de cada conjunto: set_id -> cantidad.
func equipped_set_counts() -> Dictionary:
	var counts := {}
	for item: Item in inventory.equipment.values():
		if not item.set_def.is_empty():
			var id: String = item.set_def["id"]
			counts[id] = counts.get(id, 0) + 1
	return counts


func recalculate(emit := true) -> void:
	stats.clear()
	var attrs: Dictionary = class_def.get("base_attributes", {})
	stats.set_base(Stat.STRENGTH, float(attrs.get("strength", 0)))
	stats.set_base(Stat.DEXTERITY, float(attrs.get("dexterity", 0)))
	stats.set_base(Stat.INTELLIGENCE, float(attrs.get("intelligence", 0)))
	stats.set_base(Stat.LIFE, 38.0 + 12.0 * level)
	stats.set_base(Stat.MANA, 34.0 + 6.0 * level)
	stats.set_base(Stat.EVASION, 15.0 + 3.0 * level)
	stats.set_base(Stat.ACCURACY, 2.0 * level)
	stats.set_base(Stat.CRIT_MULTIPLIER, 150.0)
	stats.set_base(Stat.MOVEMENT_SPEED, 100.0)
	stats.add_modifiers(passives.collect_modifiers())
	for p in ascendancy_def.get("passives", []):
		for md in p.get("mods", []):
			stats.add_modifier(Modifier.from_dict(md, "ascendancy"))
	_apply_equipment()
	_apply_attribute_bonuses()
	if emit:
		stats_changed.emit()


func _apply_equipment() -> void:
	var set_defs := {}
	for slot in inventory.equipment:
		var item: Item = inventory.equipment[slot]
		stats.add_modifiers(item.get_modifiers("item:" + slot))
		if not item.set_def.is_empty():
			set_defs[item.set_def["id"]] = item.set_def
	var counts := equipped_set_counts()
	for id in set_defs:
		var bonuses: Dictionary = set_defs[id]["bonuses"]
		for threshold in bonuses:
			if counts[id] >= int(threshold):
				for md in bonuses[threshold]:
					stats.add_modifier(Modifier.from_dict(md, "set:" + id))


## Como en PoE, los atributos dan bonus implícitos.
func _apply_attribute_bonuses() -> void:
	var str_value := stats.get_value(Stat.STRENGTH)
	var dex_value := stats.get_value(Stat.DEXTERITY)
	var int_value := stats.get_value(Stat.INTELLIGENCE)
	var src := "attributes"
	stats.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.FLAT, floorf(str_value / 10.0) * 5.0, [], src))
	stats.add_modifier(Modifier.new(Stat.PHYSICAL_DAMAGE, Modifier.Type.INCREASED, floorf(str_value / 5.0), [Stat.TAG_MELEE], src))
	stats.add_modifier(Modifier.new(Stat.ACCURACY, Modifier.Type.FLAT, dex_value * 2.0, [], src))
	stats.add_modifier(Modifier.new(Stat.EVASION, Modifier.Type.INCREASED, floorf(dex_value / 5.0), [], src))
	stats.add_modifier(Modifier.new(Stat.MANA, Modifier.Type.FLAT, floorf(int_value / 10.0) * 5.0, [], src))
	stats.add_modifier(Modifier.new(Stat.ENERGY_SHIELD, Modifier.Type.INCREASED, floorf(int_value / 5.0), [], src))


## Cifras del ataque básico con el arma equipada (o los puños).
func attack_profile() -> Dictionary:
	var weapon := inventory.equipped("weapon")
	var w_min: float = UNARMED["physical"][0]
	var w_max: float = UNARMED["physical"][1]
	var w_aps: float = UNARMED["aps"]
	var w_crit: float = UNARMED["crit"]
	if weapon:
		w_min = weapon.physical_min
		w_max = weapon.physical_max
		w_aps = weapon.attacks_per_second
		w_crit = weapon.crit_chance
	var phys := stats.get_breakdown(Stat.PHYSICAL_DAMAGE, ATTACK_TAGS)
	var mult: float = maxf(0.0, 1.0 + phys.increased / 100.0) * phys.more
	var min_damage: float = (w_min + phys.flat) * mult
	var max_damage: float = (w_max + phys.flat) * mult
	var aps := w_aps * _total_multiplier(Stat.ATTACK_SPEED)
	var crit := minf(100.0, w_crit * _total_multiplier(Stat.CRIT_CHANCE))
	var crit_mult := stats.get_value(Stat.CRIT_MULTIPLIER, ATTACK_TAGS)
	var average := (min_damage + max_damage) / 2.0 * (1.0 + crit / 100.0 * (crit_mult / 100.0 - 1.0))
	return {
		"min_damage": min_damage,
		"max_damage": max_damage,
		"attacks_per_second": aps,
		"crit_chance": crit,
		"crit_multiplier": crit_mult,
		"radius": BASE_ATTACK_RADIUS * sqrt(_total_multiplier(Stat.AREA_OF_EFFECT)),
		"dps": average * aps,
	}


func _total_multiplier(stat: StringName) -> float:
	var b := stats.get_breakdown(stat, ATTACK_TAGS)
	return maxf(0.0, 1.0 + b.increased / 100.0) * b.more


## Cifras clave para comparar equipo (el orden es el de la UI).
func summary() -> Dictionary:
	var cap := Stat.RESISTANCE_CAP
	return {
		"DPS del ataque": attack_profile()["dps"],
		"Vida": stats.get_value(Stat.LIFE),
		"Escudo de energía": stats.get_value(Stat.ENERGY_SHIELD),
		"Maná": stats.get_value(Stat.MANA),
		"Armadura": stats.get_value(Stat.ARMOUR),
		"Evasión": stats.get_value(Stat.EVASION),
		"Res. al fuego": minf(cap, stats.get_value(Stat.FIRE_RES)),
		"Res. al frío": minf(cap, stats.get_value(Stat.COLD_RES)),
		"Res. al rayo": minf(cap, stats.get_value(Stat.LIGHTNING_RES)),
		"Res. al caos": minf(cap, stats.get_value(Stat.CHAOS_RES)),
		"Velocidad de movimiento": stats.get_value(Stat.MOVEMENT_SPEED),
	}


## summary() como si el objeto estuviera equipado. No cambia nada ni emite señales.
func preview_equip(item: Item) -> Dictionary:
	var slot := inventory.target_slot_for(item)
	var previous: Item = inventory.equipment.get(slot)
	inventory.equipment[slot] = item
	recalculate(false)
	var result := summary()
	if previous == null:
		inventory.equipment.erase(slot)
	else:
		inventory.equipment[slot] = previous
	recalculate(false)
	return result
