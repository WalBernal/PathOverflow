class_name ExpansionChip
extends Item
## Chip de expansión (como las joyas de PoE): cae de los enemigos y se engasta en
## las ranuras del árbol pasivo (PassiveTree.socket_ids). Sus mods cuentan solo
## mientras la ranura esté asignada. Mágico: 1-2 mods; raro: 3-4; único: mods
## fijos con algo especial (cargas máximas, habilidades únicas de ascendencia...).

const BASE := {"id": "chip_expansion", "name": "Chip de expansión", "slot": "chip", "level": 1, "tags": ["chip"]}
## Mods posibles: [stat, tipo, mínimo, máximo, tags].
const POOL := [
	["damage", "increased", 8, 16, []], ["life", "increased", 4, 8, []], ["mana", "increased", 6, 12, []],
	["attack_speed", "increased", 3, 6, []], ["cast_speed", "increased", 3, 6, []], ["crit_chance", "increased", 10, 20, []],
	["crit_multiplier", "flat", 6, 12, []], ["armour", "increased", 10, 20, []], ["evasion", "increased", 10, 20, []],
	["energy_shield", "increased", 8, 15, []], ["fire_res", "flat", 6, 12, []], ["cold_res", "flat", 6, 12, []],
	["lightning_res", "flat", 6, 12, []], ["chaos_res", "flat", 4, 9, []], ["minion_damage", "increased", 10, 18, []],
	["minion_life", "increased", 8, 15, []], ["area_of_effect", "increased", 5, 10, []], ["ailment_damage", "increased", 10, 18, []],
	["movement_speed", "increased", 3, 5, []], ["strength", "flat", 8, 16, []], ["dexterity", "flat", 8, 16, []],
	["intelligence", "flat", 8, 16, []], ["buffer_charge_chance", "flat", 5, 10, []], ["multihilo_charge_chance", "flat", 5, 10, []],
	["overclock_charge_chance", "flat", 5, 10, []], ["life_regen", "flat", 3, 8, []], ["aura_effect", "increased", 4, 8, []],
]
const PREFIXES := ["Silicio", "Microcódigo", "Firmware", "Núcleo", "Bus", "Registro", "Caché", "Puerto", "Transistor", "Litografía"]
const SUFFIXES := ["de 7 nm", "sin disipador", "de laboratorio", "reciclado", "con overclock", "de servidor", "de contrabando", "ECC", "dorado"]
const UNIQUES := [
	{"id": "chip_overclock_ilegal", "name": "Chip de Overclock Ilegal", "flavor": "Garantía anulada desde el primer arranque.",
		"mods": [{"stat": "max_overclock_charges", "type": "flat", "value": 1}, {"stat": "crit_chance", "type": "increased", "value": 25},
			{"stat": "overclock_charge_chance", "type": "flat", "value": 10}]},
	{"id": "chip_ram_ecc", "name": "Chip de RAM ECC", "flavor": "Corrige un error por palabra. Los tuyos no.",
		"mods": [{"stat": "max_buffer_charges", "type": "flat", "value": 1}, {"stat": "life", "type": "increased", "value": 10},
			{"stat": "buffer_charge_chance", "type": "flat", "value": 10}]},
	{"id": "chip_hyperthread", "name": "Chip Hyperthread", "flavor": "Dos hilos por núcleo; cero hilos de paciencia.",
		"mods": [{"stat": "max_multihilo_charges", "type": "flat", "value": 1}, {"stat": "attack_speed", "type": "increased", "value": 8},
			{"stat": "cast_speed", "type": "increased", "value": 8}]},
	{"id": "chip_detonador", "name": "Chip Detonador", "flavor": "Diseñado por alguien que odiaba los procesos zombi.",
		"mods": [{"stat": "kill_explosion", "type": "flat", "value": 12}, {"stat": "damage", "type": "increased", "value": 10}]},
]

## Para únicos: su id (y así se guarda).
var unique_id := ""


func _init(p_rarity: int = Rarity.Item.MAGIC, p_item_level := 1) -> void:
	super(BASE, p_rarity, p_item_level)


static func roll(item_level: int, rng: RandomNumberGenerator) -> ExpansionChip:
	var r := rng.randf()
	var rarity := Rarity.Item.UNIQUE if r < 0.06 else (Rarity.Item.RARE if r < 0.36 else Rarity.Item.MAGIC)
	var chip := ExpansionChip.new(rarity, item_level)
	if rarity == Rarity.Item.UNIQUE:
		var u: Dictionary = UNIQUES[rng.randi_range(0, UNIQUES.size() - 1)]
		chip.unique_id = u["id"]
		chip.unique_def = u
		for m in u["mods"]:
			chip.fixed_mods.append(m.duplicate())
		return chip
	var count := rng.randi_range(1, 2) if rarity == Rarity.Item.MAGIC else rng.randi_range(3, 4)
	var picks := range(POOL.size())
	picks.shuffle()
	var scale := 1.0 + minf(1.0, item_level / 40.0)   # los chips de zonas altas tiran más alto
	for k in count:
		var e: Array = POOL[picks[k]]
		var v := roundf(rng.randf_range(float(e[2]), float(e[3])) * scale)
		chip.fixed_mods.append({"stat": e[0], "type": e[1], "value": v, "tags": e[4]})
	chip.rare_name = "%s %s" % [PREFIXES[rng.randi_range(0, PREFIXES.size() - 1)], SUFFIXES[rng.randi_range(0, SUFFIXES.size() - 1)]]
	return chip


func display_name() -> String:
	if rarity >= Rarity.Item.UNIQUE:
		return unique_def.get("name", "Chip único")
	return "Chip " + rare_name if rare_name != "" else "Chip de expansión"


func is_equipment() -> bool:
	return false


func required_level() -> int:
	return 1


func chip_modifiers(source: String) -> Array[Modifier]:
	var out: Array[Modifier] = []
	for m in fixed_mods:
		out.append(Modifier.from_dict(m, source))
	return out


func to_dict() -> Dictionary:
	return {"kind": "chip", "rarity": rarity, "item_level": item_level, "rare_name": rare_name, "unique_id": unique_id, "mods": fixed_mods}


static func from_save(d: Dictionary) -> ExpansionChip:
	var chip := ExpansionChip.new(int(d.get("rarity", Rarity.Item.MAGIC)), int(d.get("item_level", 1)))
	chip.rare_name = String(d.get("rare_name", ""))
	chip.unique_id = String(d.get("unique_id", ""))
	for u in UNIQUES:
		if u["id"] == chip.unique_id:
			chip.unique_def = u
	for m in d.get("mods", []):
		chip.fixed_mods.append(m)
	return chip


## Icono dibujado: el dado de silicio con sus patas, del color de la rareza.
static func draw_icon(ci: CanvasItem, rect: Rect2, chip: ExpansionChip, modulate := Color.WHITE) -> void:
	var side := minf(rect.size.x, rect.size.y) * 0.8
	var c := rect.get_center()
	var body := Rect2(c - Vector2(side, side) * 0.32, Vector2(side, side) * 0.64)
	var pin := Color("c8a050") * modulate
	for k in 4:
		var t := 0.15 + k * 0.23
		for side_sign in [-1.0, 1.0]:
			ci.draw_rect(Rect2(Vector2(body.position.x + body.size.x * t - 1.5, c.y + side_sign * side * 0.32 + (0.0 if side_sign > 0 else -side * 0.1)), Vector2(3, side * 0.1)), pin)
			ci.draw_rect(Rect2(Vector2(c.x + side_sign * side * 0.32 + (0.0 if side_sign > 0 else -side * 0.1), body.position.y + body.size.y * t - 1.5), Vector2(side * 0.1, 3)), pin)
	ci.draw_rect(body, Color("1e2228") * modulate)
	ci.draw_rect(body.grow(-side * 0.08), Rarity.item_color(chip.rarity).darkened(0.35) * modulate)
	ci.draw_rect(Rect2(body.get_center() - Vector2(side, side) * 0.08, Vector2(side, side) * 0.16), Rarity.item_color(chip.rarity).lightened(0.3) * modulate)
	ci.draw_rect(body, Color("8a8e98") * modulate, false, 1.0)
