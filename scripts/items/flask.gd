class_name Flask
extends Item
## Poción (frasco de PoE): café para la vida, bebidas para el maná o de
## utilidad (efecto temporal). Tiene cargas: cada uso gasta charges_per_use y
## matar enemigos las recarga. Se lleva en el cinturón de pociones (teclas 1-5).

const KIND_NAMES := {"life": "Poción de vida", "mana": "Poción de maná", "utility": "Poción de utilidad"}
const KIND_COLORS := {"life": Color("c8894a"), "mana": Color("4b8bd6"), "utility": Color("6fd36b")}
## Cargas por enemigo muerto, según su rareza.
const CHARGES_BY_RARITY := {
	Rarity.Enemy.NORMAL: 1.0,
	Rarity.Enemy.SPECIAL: 3.0,
	Rarity.Enemy.ELITE: 6.0,
	Rarity.Enemy.UNIQUE: 15.0,
}

var def: Dictionary
var charges := 0.0


func _init(p_def: Dictionary = {}, p_item_level := 1) -> void:
	super({"id": p_def.get("id", ""), "name": p_def.get("name", "Poción"), "slot": "flask",
		"level": int(p_def.get("level", 1)), "tags": []}, Rarity.Item.NORMAL, p_item_level)
	def = p_def
	charges = max_charges()


func kind() -> String:
	return def.get("kind", "life")


func max_charges() -> float:
	return float(def.get("max_charges", 30))


func cost() -> float:
	return float(def.get("charges_per_use", 10))


func duration() -> float:
	return float(def.get("duration", 3.0))


## Cantidad total de vida o maná que devuelve (0 en las de utilidad).
func recover() -> float:
	return float(def.get("recover", 0.0))


func uses_left() -> int:
	return floori(charges / cost())


func has_charges() -> bool:
	return charges >= cost()


func add_charges(amount: float) -> void:
	charges = minf(max_charges(), charges + amount)


func refill() -> void:
	charges = max_charges()


func display_color() -> Color:
	return KIND_COLORS.get(kind(), Color.WHITE)


func required_level() -> int:
	return int(def.get("level", 1))


func get_modifiers(_source: String) -> Array[Modifier]:
	return []   # solo dan efecto al beberlas (ver timed_modifiers)


## Mods de una poción de utilidad mientras dura su efecto.
func timed_modifiers() -> Array[Modifier]:
	var mods: Array[Modifier] = []
	for md in def.get("mods", []):
		mods.append(Modifier.from_dict(md, "flask:" + def.get("id", "")))
	return mods


func icon() -> String:
	return def.get("icon", def.get("id", "flask_coffee"))


## Textos del efecto, para tooltips.
func effect_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	match kind():
		"life":
			lines.append("Recupera %d de vida en %.1f s" % [recover(), duration()])
		"mana":
			lines.append("Recupera %d de maná en %.1f s" % [recover(), duration()])
		_:
			if def.get("cleanse", false):
				lines.append("Quita al momento los estados y daños degenerativos que sufres")
			if def.has("dodge_refill"):
				lines.append("Recarga todas tus esquivas (git stash)")
			if def.has("heal_minions"):
				lines.append("Cura a tus invocaciones un %d %% de su vida" % roundi(float(def["heal_minions"]) * 100.0))
			lines.append("Durante %.1f s:" % duration())
			for m in timed_modifiers():
				lines.append("  " + m.describe())
	lines.append("Gasta %d de %d cargas por uso" % [cost(), max_charges()])
	return lines


func to_dict() -> Dictionary:
	return {"kind": "flask", "flask_id": def.get("id", ""), "item_level": item_level, "charges": charges}


static func from_save(d: Dictionary, db: ItemDatabase) -> Flask:
	var flask_def: Dictionary = db.flasks.get(d.get("flask_id", ""), {})
	if flask_def.is_empty():
		push_warning("Poción desconocida '%s': se descarta" % d.get("flask_id", ""))
		return null
	var f := Flask.new(flask_def, int(d.get("item_level", 1)))
	f.charges = clampf(float(d.get("charges", f.max_charges())), 0.0, f.max_charges())
	return f


## Las pociones con las que empieza un personaje nuevo.
static func starter_set(db: ItemDatabase) -> Array[Flask]:
	var result: Array[Flask] = []
	for id in db.flask_starters:
		if db.flasks.has(id):
			result.append(Flask.new(db.flasks[id], 1))
	return result
