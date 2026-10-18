class_name Item
extends RefCounted
## Un objeto concreto: base + rareza + mods tirados. Los mods locales se
## aplican a la propia base (compute_properties) y el resto se entregan al
## personaje como Modifiers (get_modifiers).

const LOCAL_TEXT := {
	"local_physical_increased": "%d%% de aumento de Daño físico",
	"local_added_physical": "Añade %d a %d de Daño físico",
	"local_attack_speed": "%d%% de aumento de Velocidad de ataque",
	"local_crit_increased": "%d%% de aumento de Probabilidad de crítico",
	"local_defence_increased": "%d%% de aumento de Defensas",
	"local_armour": "+%d de Armadura",
	"local_evasion": "+%d de Evasión",
	"local_energy_shield": "+%d de Escudo de energía",
}

var base: Dictionary
var rarity: int = Rarity.Item.NORMAL
var item_level := 1
## Nombre generado de raros y ultra-raros.
var rare_name := ""
## Definición del único o de la pieza de conjunto (nombre, flavor...).
var unique_def: Dictionary = {}
## Solo piezas de conjunto: la definición del conjunto (bonificaciones).
var set_def: Dictionary = {}
## Afijos tirados: {affix_id, kind, name, tier_rank, tier_level, stat, type, tags, value, value2}
var affixes: Array[Dictionary] = []
## Mods fijos tirados de únicos y conjuntos: {stat, type, tags, value}
var fixed_mods: Array[Dictionary] = []

# Propiedades finales (base + mods locales).
var physical_min := 0.0
var physical_max := 0.0
var attacks_per_second := 0.0
var crit_chance := 0.0
var armour := 0.0
var evasion := 0.0
var energy_shield := 0.0


func _init(p_base: Dictionary = {}, p_rarity: int = Rarity.Item.NORMAL, p_item_level := 1) -> void:
	base = p_base
	rarity = p_rarity
	item_level = p_item_level


func slot() -> String:
	return base["slot"]


func is_weapon() -> bool:
	return base.has("weapon")


func display_name() -> String:
	match rarity:
		Rarity.Item.UNIQUE, Rarity.Item.SET:
			return unique_def["name"]
		Rarity.Item.RARE, Rarity.Item.ULTRA_RARE:
			return rare_name
		Rarity.Item.MAGIC:
			var prefix := ""
			var suffix := ""
			for a in affixes:
				if a["kind"] == "prefix":
					prefix = " " + a["name"]
				else:
					suffix = " " + a["name"]
			return base["name"] + prefix + suffix
	return base["name"]


func required_level() -> int:
	var level: int = base.get("level", 1)
	for a in affixes:
		level = maxi(level, int(a["tier_level"] * 0.8))
	return level


func implicit_mods() -> Array:
	return base.get("implicits", [])


## Mods tirados (afijos + fijos), sin implícitos.
func rolled_mods() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(affixes)
	all.append_array(fixed_mods)
	return all


func compute_properties() -> void:
	var inc_phys := 0.0
	var added_min := 0.0
	var added_max := 0.0
	var inc_speed := 0.0
	var inc_crit := 0.0
	var inc_def := 0.0
	var flat_armour := 0.0
	var flat_evasion := 0.0
	var flat_es := 0.0
	for m in rolled_mods():
		var v: float = m["value"]
		match m["stat"]:
			"local_physical_increased": inc_phys += v
			"local_added_physical":
				added_min += v
				added_max += float(m.get("value2", v))
			"local_attack_speed": inc_speed += v
			"local_crit_increased": inc_crit += v
			"local_defence_increased": inc_def += v
			"local_armour": flat_armour += v
			"local_evasion": flat_evasion += v
			"local_energy_shield": flat_es += v
	if is_weapon():
		var w: Dictionary = base["weapon"]
		physical_min = roundf((float(w["physical"][0]) + added_min) * (1.0 + inc_phys / 100.0))
		physical_max = roundf((float(w["physical"][1]) + added_max) * (1.0 + inc_phys / 100.0))
		attacks_per_second = float(w["aps"]) * (1.0 + inc_speed / 100.0)
		crit_chance = float(w["crit"]) * (1.0 + inc_crit / 100.0)
	var d: Dictionary = base.get("defences", {})
	var def_mult := 1.0 + inc_def / 100.0
	armour = roundf((float(d.get("armour", 0)) + flat_armour) * def_mult)
	evasion = roundf((float(d.get("evasion", 0)) + flat_evasion) * def_mult)
	energy_shield = roundf((float(d.get("energy_shield", 0)) + flat_es) * def_mult)


## Lo que el objeto aporta al personaje (implícitos, mods no locales y defensas).
func get_modifiers(source: String) -> Array[Modifier]:
	var mods: Array[Modifier] = []
	for m in implicit_mods():
		mods.append(Modifier.from_dict(m, source))
	for m in rolled_mods():
		if not ItemDatabase.is_local(m["stat"]):
			mods.append(Modifier.from_dict(m, source))
	if armour > 0.0:
		mods.append(Modifier.new(Stat.ARMOUR, Modifier.Type.FLAT, armour, [], source))
	if evasion > 0.0:
		mods.append(Modifier.new(Stat.EVASION, Modifier.Type.FLAT, evasion, [], source))
	if energy_shield > 0.0:
		mods.append(Modifier.new(Stat.ENERGY_SHIELD, Modifier.Type.FLAT, energy_shield, [], source))
	return mods


static func describe_mod(m: Dictionary) -> String:
	var stat: String = m["stat"]
	if LOCAL_TEXT.has(stat):
		if stat == "local_added_physical":
			return LOCAL_TEXT[stat] % [m["value"], m.get("value2", m["value"])]
		return LOCAL_TEXT[stat] % m["value"]
	return Modifier.from_dict(m).describe()


## Para el futuro sistema de guardado.
func to_dict() -> Dictionary:
	return {
		"base": base["id"],
		"rarity": rarity,
		"item_level": item_level,
		"rare_name": rare_name,
		"unique_id": unique_def.get("id", ""),
		"set_id": set_def.get("id", ""),
		"affixes": affixes,
		"fixed_mods": fixed_mods,
	}


static func from_dict(d: Dictionary, db: ItemDatabase) -> Item:
	var item := Item.new(db.bases[d["base"]], int(d["rarity"]), int(d["item_level"]))
	item.rare_name = d.get("rare_name", "")
	if d.get("unique_id", "") != "":
		item.unique_def = db.get_unique(d["unique_id"])
	if d.get("set_id", "") != "":
		var entry := db.get_set_piece(d["unique_id"])
		item.unique_def = entry.get("piece", {})
		item.set_def = entry.get("set", {})
	item.affixes.assign(d.get("affixes", []))
	item.fixed_mods.assign(d.get("fixed_mods", []))
	item.compute_properties()
	return item
