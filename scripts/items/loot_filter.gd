class_name LootFilter
## Filtro de botín por categoría (la ventana es LootFilterPanel). Cada categoría
## de equipo tiene una rareza mínima para verse en el suelo; las placas, RAM,
## pociones y chips se muestran u ocultan. Los únicos, los de conjunto y los
## objetos clave se ven siempre. `beam`: rareza mínima del haz de luz y su sonido.
## Se guarda en user://settings.cfg (sección loot_filter). Shift lo ignora.

## Escalones de rareza (de menos a más) que usan las reglas.
const STEPS := ["normal", "magic", "rare", "ultra", "unique_only", "hidden"]
const STEP_NAMES := {"normal": "Normal", "magic": "Mágico", "rare": "Raro", "ultra": "Ultra-raro", "unique_only": "Solo únicos", "hidden": "Oculto"}
const STEP_COLORS := {"normal": Color("c8c8c8"), "magic": Color("8888ff"), "rare": Color("ffff77"), "ultra": Color("ff5ac8"),
	"unique_only": Color("af6025"), "hidden": Color("e06c6c")}
## Categorías de equipo (con rareza) y de "hardware" (mostrar u ocultar).
const GEAR := ["weapon", "armour", "jewelry", "chip"]
const TOGGLES := ["board", "ram", "flask"]
const NAMES := {"weapon": "Armas", "armour": "Armaduras", "jewelry": "Joyería y cinturones", "chip": "Chips de expansión",
	"board": "Placas base", "ram": "Módulos RAM", "flask": "Pociones"}
## Ajustes de fábrica (y los atajos de la ventana).
const PRESETS := {
	"todo": {"weapon": "normal", "armour": "normal", "jewelry": "normal", "chip": "normal", "board": "normal", "ram": "normal", "flask": "normal", "beam": "rare"},
	"equilibrado": {"weapon": "magic", "armour": "magic", "jewelry": "normal", "chip": "normal", "board": "normal", "ram": "normal", "flask": "normal", "beam": "rare"},
	"estricto": {"weapon": "rare", "armour": "rare", "jewelry": "magic", "chip": "normal", "board": "normal", "ram": "normal", "flask": "hidden", "beam": "rare"},
	"endgame": {"weapon": "ultra", "armour": "ultra", "jewelry": "rare", "chip": "magic", "board": "normal", "ram": "hidden", "flask": "hidden", "beam": "ultra"},
}
const PRESET_NAMES := {"todo": "Ver todo", "equilibrado": "Equilibrado", "estricto": "Estricto", "endgame": "Fin de juego"}

static var _rules: Dictionary = {}


static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = PRESETS["todo"].duplicate()
		var saved = GameSettings.get_value("loot_filter", "rules", null)
		if saved is Dictionary:
			for k in saved:
				if _rules.has(k) and STEPS.has(String(saved[k])):
					_rules[k] = String(saved[k])
		else:
			# Del filtro viejo de tres niveles (Pausa → Filtro de botín).
			match int(GameSettings.get_value("interface", "loot_filter", 0)):
				1:
					_rules = PRESETS["equilibrado"].duplicate()
				2:
					_rules = PRESETS["estricto"].duplicate()
					_rules["flask"] = "normal"
	return _rules


static func set_rule(key: String, step: String) -> void:
	rules()[key] = step
	GameSettings.set_value("loot_filter", "rules", _rules)


static func apply_preset(preset: String) -> void:
	_rules = PRESETS[preset].duplicate()
	GameSettings.set_value("loot_filter", "rules", _rules)


## Para pruebas: vuelve a leer el archivo de ajustes.
static func reload() -> void:
	_rules = {}


static func category_of(item: Item) -> String:
	if item is Motherboard:
		return "board"
	if item is RamModule:
		return "ram"
	if item is Flask:
		return "flask"
	if item is KeyItem:
		return "key"
	match item.slot():
		"chip":
			return "chip"
		"weapon":
			return "weapon"
		"ring", "amulet", "belt":
			return "jewelry"
	return "armour"


## Escalón de la rareza de un objeto (únicos y de conjunto: "unique_only").
static func step_of(rarity: int) -> int:
	match rarity:
		Rarity.Item.NORMAL:
			return 0
		Rarity.Item.MAGIC:
			return 1
		Rarity.Item.RARE:
			return 2
		Rarity.Item.ULTRA_RARE:
			return 3
	return 4


## ¿Se ve en el suelo?
static func passes(item: Item) -> bool:
	var cat := category_of(item)
	if cat == "key" or item.rarity == Rarity.Item.UNIQUE or item.rarity == Rarity.Item.SET:
		return true
	var step := STEPS.find(String(rules().get(cat, "normal")))
	if cat in TOGGLES:
		return step < STEPS.size() - 1
	return step_of(item.rarity) >= step and step < STEPS.size() - 1


## ¿Merece haz de luz y sonido al caer?
static func beams(item: Item) -> bool:
	if not item.is_equipment() or item is ExpansionChip:
		return false
	return step_of(item.rarity) >= STEPS.find(String(rules().get("beam", "rare"))) and passes(item)
