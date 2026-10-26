class_name Crafting
## Crafteo con parches (mesa de Mario, en el campamento tras el Acto II). Los
## parches se guardan como contadores en flags["patches"]; caen de élites y únicos
## y Mario los vende por fichas. Funcionan sobre objetos normales, mágicos y raros
## (no únicos, de conjunto, placas, RAM ni pociones):
##   refactor: rehace los afijos que no estén fijados.
##   feature: añade un afijo (si cabe en su rareza).
##   major: sube la rareza (normal → mágico → raro).
##   hotfix: fija un afijo: sobrevive al siguiente refactor (y luego se suelta).
##   rollback: quita el afijo que elijas (T87).
##   optimize: sube un tier el afijo que elijas, si el nivel del objeto lo permite;
##     con riesgo: a veces se rompe y el afijo se pierde (T87).
## Lo que se hace en la mesa queda en un historial (flags["craft_log"]).

const FLAG := "patches"
const KINDS := ["refactor", "feature", "major", "hotfix", "rollback", "optimize"]
const NAMES := {"refactor": "Parche de refactor", "feature": "Parche de feature", "major": "Parche de versión mayor", "hotfix": "Parche de hotfix",
	"rollback": "Parche de rollback", "optimize": "Parche de optimización"}
const DESCRIPTIONS := {
	"refactor": "Rehace los afijos que no estén fijados.",
	"feature": "Añade un afijo, si cabe en su rareza.",
	"major": "Sube la rareza: normal → mágico → raro (conserva lo que tenga).",
	"hotfix": "Fija un afijo: sobrevive al siguiente refactor.",
	"rollback": "Quita el afijo elegido.",
	"optimize": "Sube un tier el afijo elegido (si el nivel del objeto da para más). 30 % de que se rompa y lo pierdas.",
}
const COLORS := {"refactor": Color("8ad8ff"), "feature": Color("6fd36b"), "major": Color("f2c14e"), "hotfix": Color("ff8a5a"),
	"rollback": Color("c8a0e0"), "optimize": Color("ff6ab0")}
## Precio en fichas en la mesa de Mario (más caro cuanto más nivel tiene el personaje).
const BASE_PRICE := {"refactor": 30, "feature": 45, "major": 80, "hotfix": 60, "rollback": 50, "optimize": 70}
## Probabilidad de que la optimización se rompa (el afijo se pierde).
const OPTIMIZE_RISK := 0.3
const LOG_FLAG := "craft_log"
const LOG_MAX := 12
## Lo que pasó con el último parche usado (para el mensaje de Mario).
static var last_result := ""


static func count(c: CharacterData, kind: String) -> int:
	return int(c.flags.get(FLAG, {}).get(kind, 0))


static func add(c: CharacterData, kind: String, amount := 1) -> void:
	var p: Dictionary = c.flags.get(FLAG, {}).duplicate()
	p[kind] = maxi(0, int(p.get(kind, 0)) + amount)
	c.flags[FLAG] = p


static func price(kind: String, level: int) -> int:
	return int(BASE_PRICE[kind] * (1.0 + level / 25.0))


static func buy(c: CharacterData, kind: String) -> bool:
	if not c.spend_tokens(price(kind, c.level)):
		return false
	add(c, kind)
	return true


static func craftable(item: Item) -> bool:
	return item != null and item.rarity in [Rarity.Item.NORMAL, Rarity.Item.MAGIC, Rarity.Item.RARE] \
		and not (item is Motherboard or item is RamModule or item is Flask or item is ExpansionChip or item is KeyItem)


## Por qué no se puede usar ese parche en ese objeto ("" = se puede).
static func problem(item: Item, kind: String, affix_index := -1) -> String:
	if not craftable(item):
		return "Ese objeto no se puede craftear."
	var info: Dictionary = Rarity.ITEM_INFO[item.rarity]
	match kind:
		"refactor":
			if item.rarity == Rarity.Item.NORMAL:
				return "Un objeto normal no tiene afijos que rehacer: súbele la rareza primero."
		"feature":
			if item.affixes.size() >= int(info["max_affixes"]):
				return "Ya tiene todos los afijos que caben en su rareza."
		"major":
			if item.rarity == Rarity.Item.RARE:
				return "Ya es raro: más arriba solo hay únicos, y esos no se hacen con parches."
		"hotfix":
			if affix_index < 0 or affix_index >= item.affixes.size():
				return "Elige el afijo que quieres fijar."
			if item.affixes[affix_index].get("locked", false):
				return "Ese afijo ya está fijado."
		"rollback":
			if affix_index < 0 or affix_index >= item.affixes.size():
				return "Elige el afijo que quieres quitar."
		"optimize":
			if affix_index < 0 or affix_index >= item.affixes.size():
				return "Elige el afijo que quieres optimizar."
	return ""


## El siguiente tier (mejor) de un afijo tirado, si el nivel del objeto lo permite: {} si ya está arriba.
static func next_tier(item: Item, rolled: Dictionary, db: ItemDatabase) -> Dictionary:
	for def in db.affixes:
		if def["id"] != rolled.get("affix_id", ""):
			continue
		var tiers: Array = def["tiers"]   # del peor al mejor
		var current := tiers.size() - int(rolled.get("tier_rank", tiers.size()))
		var next := current + 1
		if next < tiers.size() and int(tiers[next]["level"]) <= item.item_level:
			return tiers[next]
	return {}


## Usa un parche (si lo tienes y se puede). Devuelve "" o el motivo.
static func apply(c: CharacterData, item: Item, kind: String, gen: ItemGenerator, affix_index := -1) -> String:
	var why := problem(item, kind, affix_index)
	if why != "":
		return why
	if count(c, kind) <= 0:
		return "No te quedan %s." % NAMES[kind].to_lower().replace("parche", "parches")
	match kind:
		"refactor":
			var kept: Array[Dictionary] = []
			for a in item.affixes:
				if a.get("locked", false):
					var unlocked: Dictionary = a.duplicate()
					unlocked.erase("locked")   # el hotfix vale para un refactor
					kept.append(unlocked)
			item.affixes = kept
			var info: Dictionary = Rarity.ITEM_INFO[item.rarity]
			gen._roll_affixes(item, maxi(kept.size(), gen.rng.randi_range(info["min_affixes"], info["max_affixes"])))
		"feature":
			var before := item.affixes.size()
			gen._roll_affixes(item, before + 1)
			if item.affixes.size() == before:
				return "No queda ningún afijo posible para este objeto (el parche no se gasta)."
		"major":
			item.rarity = Rarity.Item.MAGIC if item.rarity == Rarity.Item.NORMAL else Rarity.Item.RARE
			var info: Dictionary = Rarity.ITEM_INFO[item.rarity]
			gen._roll_affixes(item, maxi(item.affixes.size(), int(info["min_affixes"])))
			if item.rarity == Rarity.Item.RARE and item.rare_name == "":
				item.rare_name = "%s %s" % [gen._pick(ItemGenerator.RARE_NAME_FIRST), gen._pick(ItemGenerator.RARE_NAME_SECOND)]
		"hotfix":
			for a in item.affixes:
				a.erase("locked")   # uno fijado a la vez
			item.affixes[affix_index]["locked"] = true
		"rollback":
			var gone: Dictionary = item.affixes[affix_index]
			item.affixes.remove_at(affix_index)
			last_result = "Fuera «%s». Como si nunca hubiera existido." % Item.describe_mod(gone)
		"optimize":
			var rolled: Dictionary = item.affixes[affix_index]
			var tier := next_tier(item, rolled, gen.db)
			if tier.is_empty():
				return "Ese afijo ya está en el mejor tier que permite el nivel del objeto (el parche no se gasta)."
			var before := Item.describe_mod(rolled)
			if gen.rng.randf() < OPTIMIZE_RISK:
				item.affixes.remove_at(affix_index)
				last_result = "Se rompió al optimizarlo: adiós a «%s». Pasa en las mejores familias." % before
			else:
				rolled["name"] = tier["name"]
				rolled["tier_rank"] = int(rolled.get("tier_rank", 1)) - 1
				rolled["tier_level"] = int(tier["level"])
				rolled["value"] = float(gen.rng.randi_range(int(tier["min"]), int(tier["max"])))
				if tier.has("min2"):
					rolled["value2"] = float(gen.rng.randi_range(int(tier["min2"]), int(tier["max2"])))
				last_result = "Optimizado: «%s» → «%s» (T%d)." % [before, Item.describe_mod(rolled), rolled["tier_rank"]]
	if kind not in ["rollback", "optimize"]:
		last_result = "Listo. %s" % DESCRIPTIONS[kind]
	add(c, kind, -1)
	item.compute_properties()
	log_action(c, "%s · %s: %s" % [item.display_name(), NAMES[kind], last_result])
	c.recalculate()
	return ""


## Historial de la mesa de Mario (lo más reciente primero, hasta LOG_MAX).
static func log_action(c: CharacterData, text: String) -> void:
	var entries: Array = c.flags.get(LOG_FLAG, []).duplicate()
	entries.push_front(text)
	if entries.size() > LOG_MAX:
		entries.resize(LOG_MAX)
	c.flags[LOG_FLAG] = entries


static func history(c: CharacterData) -> Array:
	return c.flags.get(LOG_FLAG, [])


## Botín: los élites y únicos sueltan parches de vez en cuando (directo a tu contador).
## Devuelve el tipo que cayó o "".
static func roll_drop(enemy_rarity: int, rng: RandomNumberGenerator) -> String:
	var chance: float = {Rarity.Enemy.ELITE: 0.12, Rarity.Enemy.UNIQUE: 0.6}.get(enemy_rarity, 0.0)
	if rng.randf() >= chance:
		return ""
	var weights := [34, 26, 10, 14, 9, 7]   # refactor, feature, major, hotfix, rollback, optimize
	var r := rng.randi_range(0, 99)
	for k in KINDS.size():
		r -= weights[k]
		if r < 0:
			return KINDS[k]
	return "refactor"
