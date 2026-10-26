class_name StatBlock
extends RefCounted
## Conjunto de stats con la fórmula de Path of Exile:
##   valor = (base + Σplanos) × (1 + Σaumentos / 100) × Π(1 + más / 100)
## Los "aumentos" se suman entre sí; los "más" se multiplican entre sí.
## Los aumentos/más de los stats padre también aplican (ver Stat.PARENTS).
##
## Lógica pura (RefCounted, sin nodos): se puede mover a un servidor en el futuro.

var _base: Dictionary = {}           # StringName -> float
var _modifiers: Array[Modifier] = []
var _cache: Dictionary = {}          # "stat|tags" -> float


func clear() -> void:
	_base.clear()
	_modifiers.clear()
	_cache.clear()


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_cache.clear()


func add_modifier(mod: Modifier) -> void:
	_modifiers.append(mod)
	_cache.clear()


func add_modifiers(mods: Array[Modifier]) -> void:
	_modifiers.append_array(mods)
	_cache.clear()


## Copia con modificadores extra (p. ej. los de la RAM de una habilidad), sin
## tocar el original.
func duplicate_with(extra: Array[Modifier]) -> StatBlock:
	var copy := StatBlock.new()
	copy._base = _base.duplicate()
	copy._modifiers = _modifiers.duplicate()
	copy._modifiers.append_array(extra)
	return copy


## Multiplicador total de aumentos y "más" (útil para velocidades, área...).
func total_multiplier(stat: StringName, tags: Array = []) -> float:
	var b := get_breakdown(stat, tags)
	return maxf(0.0, 1.0 + b.increased / 100.0) * b.more


func remove_source(source: String) -> void:
	var kept: Array[Modifier] = []
	for m in _modifiers:
		if m.source != source:
			kept.append(m)
	_modifiers = kept
	_cache.clear()


func get_value(stat: StringName, tags: Array = []) -> float:
	var key := _cache_key(stat, tags)
	if _cache.has(key):
		return _cache[key]
	var b := get_breakdown(stat, tags)
	var value: float = (b.base + b.flat) * maxf(0.0, 1.0 + b.increased / 100.0) * b.more
	_cache[key] = value
	return value


## Desglose para tooltips/UI: {base, flat, increased (en %), more (multiplicador)}.
func get_breakdown(stat: StringName, tags: Array = []) -> Dictionary:
	var related: Array = [stat]
	related.append_array(Stat.PARENTS.get(stat, []))
	var flat := 0.0
	var increased := 0.0
	var more := 1.0
	for mod in _modifiers:
		if not mod.applies_to(tags):
			continue
		if mod.type == Modifier.Type.FLAT:
			if mod.stat == stat:
				flat += mod.value
		elif related.has(mod.stat):
			if mod.type == Modifier.Type.INCREASED:
				increased += mod.value
			else:
				more *= 1.0 + mod.value / 100.0
	return {
		"base": float(_base.get(stat, 0.0)),
		"flat": flat,
		"increased": increased,
		"more": more,
	}


## Nombre de cada origen de modificadores (lo que va antes de «:» en su source).
const SOURCE_GROUPS := {
	"class_trait": "Clase", "ascendancy": "Ascendencia", "asc": "Ascendencia", "attributes": "Atributos",
	"tree": "Árbol de pasivas", "chip": "Chips del árbol", "tech_debt": "Deuda técnica",
	"item": "Objetos", "set": "Conjuntos", "flask": "Pociones", "charge": "Cargas", "aura": "Auras",
	"skill": "Habilidades", "golem": "Gólem", "companion": "Compañero", "shrine": "Santuarios",
	"camp": "Campamento", "incident": "Incidentes", "ram": "RAM", "board_level": "Nivel de placa",
}


static func source_label(source: String) -> String:
	var key := source.get_slice(":", 0)
	return String(SOURCE_GROUPS.get(key, "Otros" if key == "" else key.capitalize()))


## De dónde sale un stat (T81): [{group, flat, increased, more}] por origen, en el
## orden en que aparecen. Mismas reglas que get_breakdown (plano solo del stat;
## aumentos y multiplicadores también de sus padres).
func source_breakdown(stat: StringName, tags: Array = []) -> Array:
	var related: Array = [stat]
	related.append_array(Stat.PARENTS.get(stat, []))
	var rows := {}
	var order: Array = []
	for mod in _modifiers:
		if not mod.applies_to(tags):
			continue
		var counts := (mod.type == Modifier.Type.FLAT and mod.stat == stat) or (mod.type != Modifier.Type.FLAT and related.has(mod.stat))
		if not counts or mod.value == 0.0:
			continue
		var group := source_label(mod.source)
		if not rows.has(group):
			rows[group] = {"group": group, "flat": 0.0, "increased": 0.0, "more": 1.0}
			order.append(group)
		var r: Dictionary = rows[group]
		match mod.type:
			Modifier.Type.FLAT:
				r["flat"] += mod.value
			Modifier.Type.INCREASED:
				r["increased"] += mod.value
			_:
				r["more"] *= 1.0 + mod.value / 100.0
	return order.map(func(g: String) -> Dictionary: return rows[g])


## Desglose de varios stats a la vez (daño convertido, como en PoE: le afectan los
## aumentos de su tipo original y los del nuevo; los padres compartidos, como
## «Daño», cuentan una sola vez). El plano suma el de todos los stats de la lista.
func get_breakdown_union(stat_list: Array, tags: Array = []) -> Dictionary:
	var related: Array = []
	for s in stat_list:
		for r in [s] + Stat.PARENTS.get(s, []):
			if not related.has(r):
				related.append(r)
	var flat := 0.0
	var increased := 0.0
	var more := 1.0
	for mod in _modifiers:
		if not mod.applies_to(tags):
			continue
		if mod.type == Modifier.Type.FLAT:
			if stat_list.has(mod.stat):
				flat += mod.value
		elif related.has(mod.stat):
			if mod.type == Modifier.Type.INCREASED:
				increased += mod.value
			else:
				more *= 1.0 + mod.value / 100.0
	return {"base": 0.0, "flat": flat, "increased": increased, "more": more}


static func _cache_key(stat: StringName, tags: Array) -> String:
	if tags.is_empty():
		return String(stat)
	var parts := PackedStringArray()
	for t in tags:
		parts.append(String(t))
	parts.sort()
	return String(stat) + "|" + ",".join(parts)
