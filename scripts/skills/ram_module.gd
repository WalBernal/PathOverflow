class_name RamModule
extends Item
## Módulo RAM = soporte. Se instala en una ranura de su misma generación de una
## placa base y modifica esa habilidad (si es compatible con sus tags).

const GENERATIONS := ["DDR3", "DDR4", "DDR5"]
const GENERATION_COLORS := {
	"DDR3": Color("c84b4b"),
	"DDR4": Color("5cb85c"),
	"DDR5": Color("4b8bd6"),
}
## Atributo asociado a cada generación (como los colores de engarce de PoE).
const GENERATION_BY_ATTRIBUTE := {"str": "DDR3", "dex": "DDR4", "int": "DDR5"}

var def: Dictionary


func _init(p_def: Dictionary = {}, p_item_level := 1) -> void:
	super({"id": p_def.get("id", ""), "name": "Módulo RAM", "slot": "ram", "level": 1, "tags": []},
		Rarity.Item.NORMAL, p_item_level)
	def = p_def


func generation() -> String:
	return def.get("generation", "DDR4")


func display_name() -> String:
	return "%s (%s)" % [def.get("name", "?"), generation()]


## Familia: el id sin el grado ("multicanal_mayor" → "multicanal").
func family() -> String:
	return family_of(String(def.get("id", "")))


static func family_of(ram_id: String) -> String:
	for suffix in ["_menor", "_mayor"]:
		if ram_id.ends_with(suffix):
			return ram_id.substr(0, ram_id.length() - suffix.length())
	return ram_id


## 1 menor, 2 normal, 3 mayor.
func tier() -> int:
	return int(def.get("tier", 2))


func display_color() -> Color:
	return GENERATION_COLORS.get(generation(), Color.WHITE)


func get_modifiers(_source: String) -> Array[Modifier]:
	return []


## Stats que solo sirven si la habilidad hace daño (golpes, estados, crítico, robo).
const DAMAGE_STATS := ["damage", "physical_damage", "elemental_damage", "fire_damage", "cold_damage", "lightning_damage",
	"chaos_damage", "minion_damage", "crit_chance", "crit_multiplier", "life_leech", "burn_chance", "shock_chance",
	"chill_chance", "freeze_chance", "poison_chance", "bleed_chance", "ailment_damage", "ailment_duration", "ailing_damage"]


## ¿Funciona con esa habilidad? requires_tags: alguna; requires_all_tags: todas;
## excludes_tags: ninguna; excludes_kinds: no con ese tipo (p. ej. la lluvia de
## la Cascada no tiene proyectiles que atraviesen o reboten). Y una RAM que solo mejora el daño no entra en una
## habilidad que no hace daño (auras, drones de curación o de escudo).
func supports(skill_def: Dictionary) -> bool:
	var tags: Array = skill_def.get("tags", [])
	for t in def.get("excludes_tags", []):
		if tags.has(t):
			return false
	for t in def.get("requires_all_tags", []):
		if not tags.has(t):
			return false
	if String(skill_def.get("kind", "")) in def.get("excludes_kinds", []):
		return false
	if only_damage() and String(skill_def.get("damage_type", "none")) == "none":
		return false
	var required: Array = def.get("requires_tags", [])
	if required.is_empty():
		return true
	for t in required:
		if tags.has(t):
			return true
	return false


## ¿Todos sus efectos son de daño? (sin efectos especiales como proyectiles o despliegue).
func only_damage() -> bool:
	var mods: Array = def.get("mods", [])
	if mods.is_empty() or not def.get("special", {}).is_empty():
		return false
	for md in mods:
		if not (String(md.get("stat", "")) in DAMAGE_STATS):
			return false
	return true


func cost_multiplier() -> float:
	return float(def.get("cost_multiplier", 1.0))


func special(key: String, default_value: float = 0.0) -> float:
	var value = def.get("special", {}).get(key, default_value)
	return float(value) if (value is float or value is int) else default_value


## Para valores de texto (deploy: "trap", "mine", "totem").
func special_string(key: String) -> String:
	return String(def.get("special", {}).get(key, ""))


func skill_modifiers() -> Array[Modifier]:
	var mods: Array[Modifier] = []
	for md in def.get("mods", []):
		mods.append(Modifier.from_dict(md, "ram:" + def.get("id", "")))
	return mods


## Textos de sus efectos, para tooltips.
func effect_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for m in skill_modifiers():
		lines.append(m.describe())
	var sp: Dictionary = def.get("special", {})
	if sp.has("extra_projectiles"):
		lines.append("+%d proyectiles adicionales, en abanico (también los de drones e invocaciones)" % sp["extra_projectiles"])
	if sp.has("projectile_penalty"):
		lines.append("%d %% menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta %d %%)" % [
			int(sp["projectile_penalty"]), int(sp["projectile_penalty"]) / 2])
	if sp.has("reserve_mult"):
		lines.append("Reserva un %d %% más de maná" % roundi((float(sp["reserve_mult"]) - 1.0) * 100.0))
	if sp.has("aura_on_unit"):
		lines.append("El aura sigue a tu invocación más resistente (el tanque primero), no a ti")
	if sp.has("aura_anchor"):
		lines.append("El aura se queda en el suelo donde la activas (no te sigue)")
	if sp.has("aura_radius_mult"):
		lines.append("+%d %% de alcance del aura" % roundi((float(sp["aura_radius_mult"]) - 1.0) * 100.0))
	if sp.has("homing"):
		lines.append("Los proyectiles son teledirigidos: persiguen al enemigo más cercano")
	if sp.has("pierce"):
		lines.append("Los proyectiles atraviesan %d enemigos más" % sp["pierce"])
	if sp.has("repeats"):
		lines.append("La habilidad se repite %d vez más" % sp["repeats"])
	if sp.has("extra_chains"):
		lines.append("+%d encadenamientos (los proyectiles rebotan a otro enemigo)" % sp["extra_chains"])
	if sp.has("chain_penalty"):
		lines.append("Cada encadenamiento pega un %d %% menos (mejora 1 %% por nivel de la placa)" % int(sp["chain_penalty"]))
	if sp.has("unit_reduction"):
		lines.append("Tus invocaciones reciben un %d %% menos de daño" % roundi(float(sp["unit_reduction"]) * 100.0))
	match String(sp.get("deploy", "")):
		"trap":
			lines.append("Se lanza como trampa: se activa al acercarse un enemigo (máx. 3)")
		"mine":
			lines.append("Se entierra como mina: tarda en armarse, se activa al pasar un enemigo (máx. 5)")
		"totem":
			lines.append("La usa una torreta durante %d s contra el enemigo más cercano" % int(sp.get("totem_duration", 8)))
	if sp.has("area_multiplier"):
		lines.append("%d%% menos de área" % roundi((1.0 - float(sp["area_multiplier"])) * 100.0))
	lines.append("Consumo de maná ×%.2f" % cost_multiplier())
	return lines


func to_dict() -> Dictionary:
	return {"kind": "ram", "ram_id": def.get("id", ""), "item_level": item_level}


static func from_save(d: Dictionary, db: ItemDatabase) -> RamModule:
	var ram_def: Dictionary = db.skills.rams.get(d.get("ram_id", ""), {})
	if ram_def.is_empty():
		push_warning("Módulo RAM desconocido '%s': se descarta" % d.get("ram_id", ""))
		return null
	return RamModule.new(ram_def, int(d.get("item_level", 1)))
