class_name CharacterData
extends RefCounted
## Estado de un personaje: clase, ascendencia, nivel, apariencia, pasivas y equipo.
## Lógica pura (sin nodos): fácil de guardar y, en el futuro, de mover a un servidor.

signal stats_changed
signal leveled_up(new_level: int)
signal tokens_changed(total: int)
## Cambió alguna condición (vida baja, muerte reciente...): las cifras de las
## habilidades pueden cambiar aunque las stats base no.
signal conditions_changed
## Una placa base instalada ha subido de nivel.
signal board_leveled(board: Motherboard)

const MAX_LEVEL := 100
## Puntos extra que dan las misiones (en PoE son 24).
## Puntos de pasiva: 1 por nivel (desde el 2) más los que dan las misiones de la
## historia (flags["quest_passive_points"]).
const ATTACK_TAGS := [Stat.TAG_ATTACK, Stat.TAG_MELEE]
const BASE_ATTACK_RADIUS := 95.0
## Sin arma: puños.
const UNARMED := {"physical": [2.0, 5.0], "aps": 1.2, "crit": 5.0}

## Versión del formato de guardado. Súbela si cambia la estructura de to_dict()
## y añade la migración correspondiente en from_dict().
const SAVE_VERSION := 2

## Identificador del archivo de guardado ("" = personaje temporal, no se guarda).
var id := ""
var character_name := "Egresado sin nombre"
var class_def: Dictionary
var ascendancy_def: Dictionary = {}
## Pasivas de la ascendencia asignadas (índices en ascendancy_def.passives).
var ascendancy_nodes: Array[int] = []
var level := 1
var experience := 0
## Apariencia elegida en el creador (ver CharacterAppearance).
var appearance := CharacterAppearance.default()
var created_at := 0
var last_played := 0
## Segundos jugados.
var play_time := 0.0
## Banderas de progreso: diálogos vistos, regalos recibidos, paso del tutorial...
var flags: Dictionary = {}
## Moneda (Economy): la sueltan los enemigos y se gasta con el comerciante.
var tokens := 0
var passives: PassiveAllocation
var inventory := Inventory.new()
var stats := StatBlock.new()
## Efectos temporales (pociones de utilidad): {id, mods: Array[Modifier], time_left}.
var timed_effects: Array[Dictionary] = []
## Condiciones activas en este momento (las pone Player): StringName -> true.
var conditions: Dictionary = {}


## Activa o desactiva una condición (Stat.COND_*). Emite conditions_changed si cambia.
func set_condition(condition: StringName, active: bool) -> void:
	if conditions.has(condition) == active:
		return
	if active:
		conditions[condition] = true
	else:
		conditions.erase(condition)
	conditions_changed.emit()


## Tags de las condiciones activas, para añadirlas a las consultas de stats.
func condition_tags() -> Array:
	return conditions.keys()


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
	# Las placas instaladas aprenden a la vez que el personaje.
	var boards_up := false
	for board in inventory.boards:
		if board and (board as Motherboard).add_experience(amount):
			boards_up = true
			board_leveled.emit(board)
	if boards_up:
		inventory.changed.emit()   # recalcula los perfiles de las habilidades
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
	ascendancy_nodes.clear()
	for a in class_def.get("ascendancies", []):
		if StringName(a["id"]) == asc_id:
			ascendancy_def = a
	recalculate()


## La ascendencia se elige al llegar al nivel ASCENDANCY_LEVEL.
const ASCENDANCY_LEVEL := 20


## Puntos de ascendencia: 1 al nivel 20, 2 al 25 y 3 al 30.
func ascendancy_points_total() -> int:
	if level < ASCENDANCY_LEVEL:
		return 0
	return clampi(1 + (level - ASCENDANCY_LEVEL) / 5, 1, 3)


func ascendancy_points_available() -> int:
	return ascendancy_points_total() - ascendancy_nodes.size()


func can_choose_ascendancy() -> bool:
	return level >= ASCENDANCY_LEVEL and ascendancy_def.is_empty()


func allocate_ascendancy_node(index: int) -> bool:
	if ascendancy_def.is_empty() or ascendancy_nodes.has(index) or ascendancy_points_available() <= 0:
		return false
	if index < 0 or index >= ascendancy_def.get("passives", []).size():
		return false
	ascendancy_nodes.append(index)
	recalculate()
	return true


func refund_ascendancy_node(index: int) -> bool:
	if not ascendancy_nodes.has(index):
		return false
	ascendancy_nodes.erase(index)
	recalculate()
	return true


func passive_points_total() -> int:
	return level - 1 + int(flags.get("quest_passive_points", 0))


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
	var asc_passives: Array = ascendancy_def.get("passives", [])
	for i in ascendancy_nodes:
		if i < asc_passives.size():
			for md in asc_passives[i].get("mods", []):
				stats.add_modifier(Modifier.from_dict(md, "ascendancy"))
	_apply_equipment()
	for effect in timed_effects:
		stats.add_modifiers(effect["mods"])
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


## Activa (o renueva) un efecto temporal con sus modificadores.
func add_timed_effect(id: String, mods: Array[Modifier], seconds: float) -> void:
	for effect in timed_effects:
		if effect["id"] == id:
			effect["time_left"] = seconds
			return
	timed_effects.append({"id": id, "mods": mods, "time_left": seconds, "total": seconds})
	recalculate()


## Lo llama Player cada frame: quita los efectos caducados.
func tick_timed_effects(delta: float) -> void:
	if timed_effects.is_empty():
		return
	var expired := false
	for effect in timed_effects:
		effect["time_left"] -= delta
		expired = expired or effect["time_left"] <= 0.0
	if expired:
		timed_effects.assign(timed_effects.filter(func(e: Dictionary) -> bool: return e["time_left"] > 0.0))
		recalculate()


func has_timed_effect(id: String) -> bool:
	return timed_effects.any(func(e: Dictionary) -> bool: return e["id"] == id)


## Como en PoE, los atributos dan bonus implícitos.
func _apply_attribute_bonuses() -> void:
	var str_value := stats.get_value(Stat.STRENGTH)
	var dex_value := stats.get_value(Stat.DEXTERITY)
	var int_value := stats.get_value(Stat.INTELLIGENCE)
	var src := "attributes"
	stats.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.FLAT, floorf(str_value / 10.0) * 5.0, [], src))
	# Cada atributo también da daño a su estilo, para que los caminos de atributos
	# del árbol valgan para todas las clases.
	stats.add_modifier(Modifier.new(Stat.PHYSICAL_DAMAGE, Modifier.Type.INCREASED, floorf(str_value / 4.0), [Stat.TAG_MELEE], src))
	stats.add_modifier(Modifier.new(Stat.ACCURACY, Modifier.Type.FLAT, dex_value * 2.0, [], src))
	stats.add_modifier(Modifier.new(Stat.EVASION, Modifier.Type.INCREASED, floorf(dex_value / 5.0), [], src))
	stats.add_modifier(Modifier.new(Stat.DAMAGE, Modifier.Type.INCREASED, floorf(dex_value / 4.0), [Stat.TAG_PROJECTILE], src))
	stats.add_modifier(Modifier.new(Stat.ATTACK_SPEED, Modifier.Type.INCREASED, floorf(dex_value / 10.0), [], src))
	stats.add_modifier(Modifier.new(Stat.MANA, Modifier.Type.FLAT, floorf(int_value / 10.0) * 5.0, [], src))
	stats.add_modifier(Modifier.new(Stat.ENERGY_SHIELD, Modifier.Type.INCREASED, floorf(int_value / 5.0), [], src))
	stats.add_modifier(Modifier.new(Stat.DAMAGE, Modifier.Type.INCREASED, floorf(int_value / 4.0), [Stat.TAG_SPELL], src))


## Valores base del arma equipada (o de los puños), para las habilidades de ataque.
func weapon_values() -> Dictionary:
	var weapon := inventory.equipped("weapon")
	if weapon:
		return {"min": weapon.physical_min, "max": weapon.physical_max, "aps": weapon.attacks_per_second, "crit": weapon.crit_chance}
	return {"min": UNARMED["physical"][0], "max": UNARMED["physical"][1], "aps": UNARMED["aps"], "crit": UNARMED["crit"]}


## Cifras finales de la habilidad instalada en esa ranura de la barra (o {}).
func skill_profile(hotbar_index: int) -> Dictionary:
	var board: Motherboard = inventory.boards[hotbar_index]
	return SkillCalc.compute(board, self) if board else {}


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


func add_tokens(amount: int) -> void:
	tokens = maxi(0, tokens + amount)
	tokens_changed.emit(tokens)


## Paga si le alcanza. false (y no gasta nada) si no.
func spend_tokens(amount: int) -> bool:
	if amount > tokens:
		return false
	tokens -= amount
	tokens_changed.emit(tokens)
	return true


func to_dict() -> Dictionary:
	var passive_ids: Array = []
	for pid in passives.get_allocated_ids():
		if pid != passives.start_node_id:
			passive_ids.append(pid)
	passive_ids.sort()
	return {
		"save_version": SAVE_VERSION,
		"id": id,
		"name": character_name,
		"class_id": class_def["id"],
		"ascendancy_id": ascendancy_def.get("id", ""),
		"ascendancy_nodes": ascendancy_nodes,
		"level": level,
		"experience": experience,
		"appearance": appearance,
		"passives": passive_ids,
		"passive_tree_version": passives.tree.version,
		"inventory": inventory.to_dict(),
		"created_at": created_at,
		"last_played": last_played,
		"play_time": play_time,
		"flags": flags,
		"tokens": tokens,
	}


## Reconstruye un personaje guardado. `class_def` es la definición de su clase
## (GameData.get_class_def(d.class_id)).
static func from_dict(d: Dictionary, p_class_def: Dictionary, tree: PassiveTree, db: ItemDatabase) -> CharacterData:
	var c := CharacterData.new(p_class_def, tree)
	c.id = d.get("id", "")
	c.character_name = d.get("name", c.character_name)
	c.level = clampi(int(d.get("level", 1)), 1, MAX_LEVEL)
	c.experience = maxi(0, int(d.get("experience", 0)))
	c.appearance = CharacterAppearance.sanitize(d.get("appearance", {}))
	c.created_at = int(d.get("created_at", 0))
	c.last_played = int(d.get("last_played", 0))
	c.play_time = float(d.get("play_time", 0.0))
	c.tokens = maxi(0, int(d.get("tokens", 0)))
	var saved_flags = d.get("flags", {})
	c.flags = saved_flags if saved_flags is Dictionary else {}
	for a in p_class_def.get("ascendancies", []):
		if a["id"] == d.get("ascendancy_id", ""):
			c.ascendancy_def = a
	if not c.ascendancy_def.is_empty():
		if c.level < ASCENDANCY_LEVEL:
			# Antes se elegía en cualquier momento; ahora hace falta el nivel 20.
			c.ascendancy_def = {}
			c.flags["ascendancy_reset"] = true
		elif d.has("ascendancy_nodes"):
			for i in d["ascendancy_nodes"]:
				if int(i) < c.ascendancy_def.get("passives", []).size() and not c.ascendancy_nodes.has(int(i)):
					c.ascendancy_nodes.append(int(i))
		else:
			# Guardados de antes: se asignan las que permitan sus puntos.
			for i in mini(c.ascendancy_points_total(), c.ascendancy_def.get("passives", []).size()):
				c.ascendancy_nodes.append(i)
		while c.ascendancy_nodes.size() > c.ascendancy_points_total():
			c.ascendancy_nodes.pop_back()
	c.inventory.load_dict(d.get("inventory", {}), db)
	if int(d.get("passive_tree_version", 1)) == tree.version:
		c.passives.load_ids(d.get("passives", []))  # también recalcula las stats
		if c.passives.spent_points() > c.passive_points_total():
			# Cambió el reparto de puntos (antes había 22 de regalo): se devuelven todos.
			c.passives.load_ids([])
			c.flags["passives_refunded"] = true
	elif not d.get("passives", []).is_empty():
		# El árbol cambió: los ids antiguos apuntarían a otros nodos. Se devuelven los puntos.
		c.flags["passives_refunded"] = true
		c.recalculate()
	return c


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
