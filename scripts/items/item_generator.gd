class_name ItemGenerator
extends RefCounted
## Genera objetos aleatorios a partir de ItemDatabase.
## Lógica pura con su propio RandomNumberGenerator: con una semilla fija, los
## resultados son reproducibles (pruebas, y en el futuro, un servidor).

const RARE_NAME_FIRST := [
	"Pesadilla", "Tormento", "Fragmento", "Eco", "Ruina", "Susurro", "Grito", "Pánico",
	"Abismo", "Presagio", "Lamento", "Error", "Delirio", "Ceniza", "Vigilia",
]
const RARE_NAME_SECOND := [
	"del Kernel", "de la Pila", "del Vacío", "del Heap", "sin Retorno", "del Deploy",
	"del Daemon", "de Medianoche", "sin Documentar", "de la Caché", "del Viernes",
	"en Producción", "del Legacy", "del Bucle", "de la Excepción",
]

var db: ItemDatabase
var rng := RandomNumberGenerator.new()


func _init(p_db: ItemDatabase, seed_value := -1) -> void:
	db = p_db
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## Objeto aleatorio para botín: elige rareza (con bonus de rareza) y base.
func roll_drop(item_level: int, rarity_bonus := 0.0) -> Item:
	return generate(item_level, roll_rarity(rarity_bonus))


func roll_rarity(rarity_bonus := 0.0) -> int:
	var rarities: Array = Rarity.ITEM_INFO.keys()
	var weights: Array = []
	for r in rarities:
		var w: float = Rarity.ITEM_INFO[r]["drop_weight"]
		if r != Rarity.Item.NORMAL:
			w *= 1.0 + rarity_bonus / 100.0
		weights.append(w)
	return rarities[_weighted_index(weights)]


## Genera un objeto de la rareza indicada. Si no hay únicos o conjuntos
## disponibles para ese nivel, se convierte en raro.
func generate(item_level: int, rarity: int, base_id := "") -> Item:
	if rarity == Rarity.Item.UNIQUE:
		var u := _pick_by_base_level(db.uniques, item_level, func(e: Dictionary) -> String: return e["base"])
		if not u.is_empty():
			return make_unique(u, item_level)
		rarity = Rarity.Item.RARE
	elif rarity == Rarity.Item.SET:
		var entry := _pick_by_base_level(db.set_pieces, item_level, func(e: Dictionary) -> String: return e["piece"]["base"])
		if not entry.is_empty():
			return make_set_piece(entry["piece"], entry["set"], item_level)
		rarity = Rarity.Item.RARE

	var base: Dictionary = db.bases[base_id] if base_id != "" else _pick_base(item_level)
	var item := Item.new(base, rarity, item_level)
	_roll_affixes(item)
	if rarity == Rarity.Item.RARE or rarity == Rarity.Item.ULTRA_RARE:
		item.rare_name = "%s %s" % [_pick(RARE_NAME_FIRST), _pick(RARE_NAME_SECOND)]
	item.compute_properties()
	return item


func make_unique(def: Dictionary, item_level: int) -> Item:
	var item := Item.new(db.bases[def["base"]], Rarity.Item.UNIQUE, item_level)
	item.unique_def = def
	item.fixed_mods = _roll_fixed(def.get("mods", []))
	item.compute_properties()
	return item


func make_set_piece(piece: Dictionary, set_def: Dictionary, item_level: int) -> Item:
	var item := Item.new(db.bases[piece["base"]], Rarity.Item.SET, item_level)
	item.unique_def = piece
	item.set_def = set_def
	item.fixed_mods = _roll_fixed(piece.get("mods", []))
	item.compute_properties()
	return item


func _roll_fixed(mods: Array) -> Array[Dictionary]:
	var rolled: Array[Dictionary] = []
	for m in mods:
		rolled.append({
			"stat": m["stat"],
			"type": m.get("type", "flat"),
			"tags": m.get("tags", []),
			"value": float(rng.randi_range(int(m["min"]), int(m["max"]))),
		})
	return rolled


func _roll_affixes(item: Item) -> void:
	var info: Dictionary = Rarity.ITEM_INFO[item.rarity]
	var target := rng.randi_range(info["min_affixes"], info["max_affixes"])
	var counts := {"prefix": 0, "suffix": 0}
	var limits := {"prefix": int(info["max_prefixes"]), "suffix": int(info["max_suffixes"])}
	var used_groups := {}
	while item.affixes.size() < target:
		var candidates: Array = []
		var weights: Array = []
		for a in db.affixes:
			if used_groups.has(a["group"]) or counts[a["kind"]] >= limits[a["kind"]]:
				continue
			if not _allowed(a, item.base):
				continue
			var tiers := _available_tiers(a, item.item_level)
			if tiers.is_empty():
				continue
			candidates.append(a)
			weights.append(float(tiers[0]["weight"]))
		if candidates.is_empty():
			break
		var affix: Dictionary = candidates[_weighted_index(weights)]
		var tiers := _available_tiers(affix, item.item_level)
		var tier_index := tiers.size() - 1
		if item.rarity != Rarity.Item.ULTRA_RARE:
			var tier_weights: Array = []
			for t in tiers:
				tier_weights.append(float(t["weight"]))
			tier_index = _weighted_index(tier_weights)
		var tier: Dictionary = tiers[tier_index]
		var rolled := {
			"affix_id": affix["id"],
			"kind": affix["kind"],
			"name": tier["name"],
			# T1 = el mejor tier del afijo, como en PoE.
			"tier_rank": affix["tiers"].size() - tier_index,
			"tier_level": int(tier["level"]),
			"stat": affix["stat"],
			"type": affix.get("type", "flat"),
			"tags": affix.get("tags", []),
			"value": float(rng.randi_range(int(tier["min"]), int(tier["max"]))),
		}
		if tier.has("min2"):
			rolled["value2"] = float(rng.randi_range(int(tier["min2"]), int(tier["max2"])))
		item.affixes.append(rolled)
		used_groups[affix["group"]] = true
		counts[affix["kind"]] += 1


static func _allowed(affix: Dictionary, base: Dictionary) -> bool:
	for tag in affix["allowed"]:
		if base["tags"].has(tag):
			return true
	return false


## Tiers con nivel <= nivel de objeto (los datos van del peor al mejor).
static func _available_tiers(affix: Dictionary, item_level: int) -> Array:
	var result: Array = []
	for t in affix["tiers"]:
		if int(t["level"]) <= item_level:
			result.append(t)
	return result


func _pick_base(item_level: int) -> Dictionary:
	var options: Array = []
	for b in db.bases.values():
		if int(b["level"]) <= item_level:
			options.append(b)
	return _pick(options)


func _pick_by_base_level(entries: Array, item_level: int, base_of: Callable) -> Dictionary:
	var options: Array = []
	for e in entries:
		if int(db.bases[base_of.call(e)]["level"]) <= item_level:
			options.append(e)
	return _pick(options) if not options.is_empty() else {}


func _pick(options: Array) -> Variant:
	return options[rng.randi_range(0, options.size() - 1)]


func _weighted_index(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r < 0.0:
			return i
	return weights.size() - 1
