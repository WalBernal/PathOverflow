class_name Motherboard
extends Item
## Placa base = habilidad activa. Tiene de 3 a 7 ranuras DIMM, cada una de una
## generación (DDR3/DDR4/DDR5); en cada una cabe un RamModule de su generación,
## que modifica la habilidad (como las gemas de soporte de PoE).

const COLOR := Color("1ba29b")
const MAX_LEVEL := 40
const MIN_SLOTS := 3
const MAX_SLOTS := 7

var skill_def: Dictionary
var level := 1
## Experiencia hacia el siguiente nivel (las placas instaladas la ganan al matar).
var experience := 0
## Generación de cada ranura ("DDR3", "DDR4" o "DDR5").
var slots: Array[String] = []
## RamModule instalado en cada ranura, o null.
var rams: Array = []


func _init(p_skill_def: Dictionary = {}, p_level := 1, p_slots: Array = []) -> void:
	super({"id": p_skill_def.get("id", ""), "name": "Placa base", "slot": "motherboard", "level": 1, "tags": []},
		Rarity.Item.NORMAL, p_level)
	skill_def = p_skill_def
	level = clampi(p_level, 1, MAX_LEVEL)
	slots.assign(p_slots)
	rams.resize(slots.size())


## Un poco más rápida que la del personaje, para que la placa no se quede atrás.
func experience_to_next() -> int:
	return int(60.0 * pow(level, 1.55))


## Devuelve true si ha subido de nivel.
func add_experience(amount: int) -> bool:
	if level >= MAX_LEVEL:
		return false
	experience += amount
	var leveled := false
	while level < MAX_LEVEL and experience >= experience_to_next():
		experience -= experience_to_next()
		level += 1
		leveled = true
	return leveled


func display_name() -> String:
	return "Placa base: %s" % skill_def.get("name", "?")


func display_color() -> Color:
	return COLOR


func get_modifiers(_source: String) -> Array[Modifier]:
	return []  # las placas no dan stats al personaje, solo a su habilidad


func has_tag(tag: String) -> bool:
	return skill_def.get("tags", []).has(tag)


## "" si se pudo instalar; si no, el motivo para mostrarlo en la UI.
func can_install(ram: RamModule, index: int) -> String:
	if index < 0 or index >= slots.size():
		return "Esa ranura no existe."
	if rams[index] != null:
		return "Ranura ocupada. Quita primero el módulo que hay."
	if ram.generation() != slots[index]:
		return "Ranura %s, módulo %s. No encaja ni a martillazos." % [slots[index], ram.generation()]
	return ""


func install(ram: RamModule, index: int) -> String:
	var problem := can_install(ram, index)
	if problem == "":
		rams[index] = ram
	return problem


func remove(index: int) -> RamModule:
	var ram: RamModule = rams[index]
	rams[index] = null
	return ram


func free_slot_for(ram: RamModule) -> int:
	for i in slots.size():
		if rams[i] == null and slots[i] == ram.generation():
			return i
	return -1


## Módulos instalados que afectan a esta habilidad (los incompatibles no hacen nada).
func active_supports() -> Array:
	var result: Array = []
	for ram in rams:
		if ram != null and ram.supports(skill_def):
			result.append(ram)
	return result


func to_dict() -> Dictionary:
	var ram_data: Array = []
	for ram in rams:
		ram_data.append(ram.to_dict() if ram else null)
	return {
		"kind": "motherboard",
		"skill_id": skill_def.get("id", ""),
		"level": level,
		"experience": experience,
		"item_level": item_level,
		"slots": slots,
		"rams": ram_data,
	}


static func from_save(d: Dictionary, db: ItemDatabase) -> Motherboard:
	var def: Dictionary = db.skills.skills.get(d.get("skill_id", ""), {})
	if def.is_empty():
		push_warning("Placa base de una habilidad desconocida '%s': se descarta" % d.get("skill_id", ""))
		return null
	var board := Motherboard.new(def, int(d.get("level", 1)), d.get("slots", []))
	board.item_level = int(d.get("item_level", 1))
	board.experience = int(d.get("experience", 0))
	var ram_data: Array = d.get("rams", [])
	for i in mini(ram_data.size(), board.slots.size()):
		if ram_data[i] is Dictionary:
			var ram := RamModule.from_save(ram_data[i], db)
			if ram and ram.generation() == board.slots[i]:
				board.rams[i] = ram
	return board
