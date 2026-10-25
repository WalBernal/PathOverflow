class_name LootFilter
## Filtro de botín por categoría (la ventana es LootFilterPanel). Cada categoría
## de equipo tiene una rareza mínima para verse en el suelo; las placas, RAM,
## pociones y chips se muestran u ocultan. Los únicos, los de conjunto y los
## objetos clave se ven siempre. `beam`: rareza mínima del haz de luz y su sonido.
## Se guarda en user://settings.cfg (sección loot_filter). Shift lo ignora.
## Reglas finas: `min_ilvl` esconde el equipo de nivel de objeto menor (0 = no);
## `bases` (ids de base) y `stats` (afijos buscados) hacen que el equipo que las
## tenga se vea siempre y salga resaltado con una estrella. Filtros con nombre:
## se guardan aparte (`profiles`) y se cargan desde la ventana.

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

## Reglas finas (además de las de rareza) y sus valores por defecto.
const EXTRA := {"min_ilvl": 0, "bases": [], "stats": []}
const HIGHLIGHT := Color("ffd24a")
## false en las pruebas: no toca el settings.cfg del jugador.
static var persist := true

static var _rules: Dictionary = {}


static func _with_extra(r: Dictionary) -> Dictionary:
	for k in EXTRA:
		if not r.has(k):
			r[k] = EXTRA[k].duplicate() if EXTRA[k] is Array else EXTRA[k]
	return r


static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = _with_extra(PRESETS["todo"].duplicate())
		var saved = GameSettings.get_value("loot_filter", "rules", {}) if persist else {}
		if saved is Dictionary and not saved.is_empty():
			for k in saved:
				if _rules.has(k) and saved[k] is String and STEPS.has(saved[k]):
					_rules[k] = saved[k]
			_rules["min_ilvl"] = maxi(0, int(saved.get("min_ilvl", 0)))
			for k in ["bases", "stats"]:
				if saved.get(k) is Array:
					_rules[k] = (saved[k] as Array).map(func(v) -> String: return str(v))
		else:
			# Del filtro viejo de tres niveles (Pausa → Filtro de botín).
			match int(GameSettings.get_value("interface", "loot_filter", 0)):
				1:
					_rules = _with_extra(PRESETS["equilibrado"].duplicate())
				2:
					_rules = _with_extra(PRESETS["estricto"].duplicate())
					_rules["flask"] = "normal"
	return _rules


static func _save() -> void:
	if persist:
		GameSettings.set_value("loot_filter", "rules", _rules)


static func set_rule(key: String, step: String) -> void:
	rules()[key] = step
	_save()


## Los atajos cambian las rarezas; las reglas finas se quedan.
static func apply_preset(preset: String) -> void:
	var keep := {}
	for k in EXTRA:
		keep[k] = rules()[k]
	_rules = PRESETS[preset].duplicate()
	_rules.merge(keep, true)
	_save()


static func set_min_ilvl(level: int) -> void:
	rules()["min_ilvl"] = maxi(0, level)
	_save()


## Añade o quita una base (`kind` = "bases") o un afijo buscado ("stats").
static func toggle_listed(kind: String, id: String) -> void:
	var list: Array = rules()[kind]
	if list.has(id):
		list.erase(id)
	else:
		list.append(id)
	_save()


# --- Filtros con nombre ---

static func profiles() -> Dictionary:
	var p = GameSettings.get_value("loot_filter", "profiles", {}) if persist else _test_profiles
	return p if p is Dictionary else {}


static var _test_profiles: Dictionary = {}


static func save_profile(profile_name: String) -> void:
	var name := profile_name.strip_edges()
	if name == "":
		return
	var all := profiles()
	all[name] = rules().duplicate(true)
	if persist:
		GameSettings.set_value("loot_filter", "profiles", all)
	else:
		_test_profiles = all


static func load_profile(profile_name: String) -> bool:
	var saved = profiles().get(profile_name)
	if not saved is Dictionary:
		return false
	_rules = _with_extra((saved as Dictionary).duplicate(true))
	_save()
	return true


static func delete_profile(profile_name: String) -> void:
	var all := profiles()
	all.erase(profile_name)
	if persist:
		GameSettings.set_value("loot_filter", "profiles", all)
	else:
		_test_profiles = all


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
	if highlighted(item):
		return true   # base buena o afijo buscado: siempre
	if item.item_level < int(rules().get("min_ilvl", 0)):
		return false
	return step_of(item.rarity) >= step and step < STEPS.size() - 1


## ¿Lleva estrella? Equipo con una base buena o un afijo buscado.
static func highlighted(item: Item) -> bool:
	if not item.is_equipment() or item is ExpansionChip:
		return false
	if (rules()["bases"] as Array).has(String(item.base.get("id", ""))):
		return true
	var wanted: Array = rules()["stats"]
	if wanted.is_empty():
		return false
	for a in item.affixes:
		if wanted.has(String(a.get("stat", ""))):
			return true
	return false


## ¿Merece haz de luz y sonido al caer?
static func beams(item: Item) -> bool:
	if not item.is_equipment() or item is ExpansionChip:
		return false
	return (step_of(item.rarity) >= STEPS.find(String(rules().get("beam", "rare"))) or highlighted(item)) and passes(item)
