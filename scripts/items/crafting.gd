class_name Crafting
## Crafteo con parches (mesa de Mario, en el campamento tras el Acto II). Los
## parches se guardan como contadores en flags["patches"]; caen de élites y únicos
## y Mario los vende por fichas. Funcionan sobre objetos normales, mágicos y raros
## (no únicos, de conjunto, placas, RAM ni pociones):
##   refactor: rehace los afijos que no estén fijados.
##   feature: añade un afijo (si cabe en su rareza).
##   major: sube la rareza (normal → mágico → raro).
##   hotfix: fija un afijo: sobrevive al siguiente refactor (y luego se suelta).

const FLAG := "patches"
const KINDS := ["refactor", "feature", "major", "hotfix"]
const NAMES := {"refactor": "Parche de refactor", "feature": "Parche de feature", "major": "Parche de versión mayor", "hotfix": "Parche de hotfix"}
const DESCRIPTIONS := {
	"refactor": "Rehace los afijos que no estén fijados.",
	"feature": "Añade un afijo, si cabe en su rareza.",
	"major": "Sube la rareza: normal → mágico → raro (conserva lo que tenga).",
	"hotfix": "Fija un afijo: sobrevive al siguiente refactor.",
}
const COLORS := {"refactor": Color("8ad8ff"), "feature": Color("6fd36b"), "major": Color("f2c14e"), "hotfix": Color("ff8a5a")}
## Precio en fichas en la mesa de Mario (más caro cuanto más nivel tiene el personaje).
const BASE_PRICE := {"refactor": 30, "feature": 45, "major": 80, "hotfix": 60}


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
	return ""


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
	add(c, kind, -1)
	item.compute_properties()
	c.recalculate()
	return ""


## Botín: los élites y únicos sueltan parches de vez en cuando (directo a tu contador).
## Devuelve el tipo que cayó o "".
static func roll_drop(enemy_rarity: int, rng: RandomNumberGenerator) -> String:
	var chance: float = {Rarity.Enemy.ELITE: 0.12, Rarity.Enemy.UNIQUE: 0.6}.get(enemy_rarity, 0.0)
	if rng.randf() >= chance:
		return ""
	var weights := [40, 30, 12, 18]   # refactor, feature, major, hotfix
	var r := rng.randi_range(0, 99)
	for k in KINDS.size():
		r -= weights[k]
		if r < 0:
			return KINDS[k]
	return "refactor"
