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


## Probabilidad de que un objeto de botín sea una placa base o un módulo RAM.
const MOTHERBOARD_DROP_CHANCE := 0.08
const RAM_DROP_CHANCE := 0.10
const FLASK_DROP_CHANCE := 0.07
## Probabilidad relativa de cada número de ranuras DIMM (3..7).
const SLOT_COUNT_WEIGHTS := {3: 50.0, 4: 30.0, 5: 13.0, 6: 5.0, 7: 2.0}
## Probabilidad de que una ranura sea de la generación del atributo de la habilidad.
const MAIN_GENERATION_CHANCE := 0.6


## Objeto aleatorio para botín: placa base, RAM o equipo (con su rareza).
func roll_drop(item_level: int, rarity_bonus := 0.0) -> Item:
	var r := rng.randf()
	if r < MOTHERBOARD_DROP_CHANCE:
		return generate_motherboard(item_level)
	if r < MOTHERBOARD_DROP_CHANCE + RAM_DROP_CHANCE:
		return generate_ram(item_level)
	if r < MOTHERBOARD_DROP_CHANCE + RAM_DROP_CHANCE + FLASK_DROP_CHANCE:
		var flask := generate_flask(item_level)
		if flask:
			return flask
	return generate(item_level, roll_rarity(rarity_bonus))


## Placa base de una habilidad (aleatoria si skill_id es ""). Su nivel sigue al
## nivel del objeto; el número de ranuras y su generación son aleatorios.
func generate_motherboard(item_level: int, skill_id := "", slot_count := 0) -> Motherboard:
	var defs: Dictionary = db.skills.skills
	var def: Dictionary = defs[skill_id] if skill_id != "" else defs[_pick(defs.keys())]
	if slot_count <= 0:
		var counts: Array = SLOT_COUNT_WEIGHTS.keys()
		slot_count = counts[_weighted_index(SLOT_COUNT_WEIGHTS.values())]
	var main_gen: String = RamModule.GENERATION_BY_ATTRIBUTE.get(def.get("attribute", "str"), "DDR3")
	var slots: Array = []
	for i in slot_count:
		slots.append(main_gen if rng.randf() < MAIN_GENERATION_CHANCE else _pick(RamModule.GENERATIONS))
	var board := Motherboard.new(def, clampi(item_level - 3, 1, Motherboard.MAX_LEVEL), slots)
	board.item_level = item_level
	return board


func generate_ram(item_level: int, ram_id := "") -> RamModule:
	var defs: Dictionary = db.skills.rams
	var def: Dictionary
	if ram_id != "":
		def = defs[ram_id]
	else:
		# Solo caen los módulos cuyo nivel mínimo se alcanza (menor → normal → mayor según el acto).
		var options: Array = []
		for id in defs:
			if int(defs[id].get("min_level", 1)) <= item_level:
				options.append(id)
		def = defs[_pick(options if not options.is_empty() else defs.keys())]
	return RamModule.new(def, item_level)


## Poción aleatoria de nivel <= item_level. Las de nivel más cercano al de la
## zona son más probables (las antiguas dejan de caer poco a poco).
func generate_flask(item_level: int, flask_id := "") -> Flask:
	if flask_id != "":
		return Flask.new(db.flasks[flask_id], item_level) if db.flasks.has(flask_id) else null
	var options: Array = []
	var weights: Array = []
	for def in db.flasks.values():
		var lvl := int(def.get("level", 1))
		if lvl <= item_level:
			options.append(def)
			weights.append(1.0 / (1.0 + (item_level - lvl) / 4.0))
	if options.is_empty():
		return null
	return Flask.new(options[_weighted_index(weights)], item_level)


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


## Completa los afijos del objeto hasta `target` (por defecto, un número al azar
## de su rareza). Respeta los que ya tenga: cuentan para los límites de prefijos
## y sufijos y no se repite su grupo (así sirve para los parches de crafteo).
func _roll_affixes(item: Item, target := -1) -> void:
	var info: Dictionary = Rarity.ITEM_INFO[item.rarity]
	if target < 0:
		target = rng.randi_range(info["min_affixes"], info["max_affixes"])
	target = mini(target, int(info["max_affixes"]))
	var counts := {"prefix": 0, "suffix": 0}
	var limits := {"prefix": int(info["max_prefixes"]), "suffix": int(info["max_suffixes"])}
	var used_groups := {}
	for existing in item.affixes:
		counts[existing["kind"]] = int(counts.get(existing["kind"], 0)) + 1
		for a in db.affixes:
			if a["id"] == existing["affix_id"]:
				used_groups[a["group"]] = true
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
