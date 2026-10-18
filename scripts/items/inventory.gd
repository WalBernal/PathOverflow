class_name Inventory
extends RefCounted
## Equipo por ranura + bolsa de tamaño fijo. Solo datos: la UI está en
## InventoryPanel y las reglas de nivel en CharacterData.

signal changed

const BAG_SIZE := 60
const EQUIP_SLOTS := ["weapon", "helmet", "body", "gloves", "boots", "amulet", "ring_left", "ring_right", "belt"]
const SLOT_NAMES := {
	"weapon": "Arma",
	"helmet": "Casco",
	"body": "Armadura",
	"gloves": "Guantes",
	"boots": "Botas",
	"amulet": "Amuleto",
	"ring_left": "Anillo",
	"ring_right": "Anillo",
	"belt": "Cinturón",
}

var equipment: Dictionary = {}  # ranura -> Item
var bag: Array = []             # Item o null


func _init() -> void:
	bag.resize(BAG_SIZE)


func equipped(slot: String) -> Item:
	return equipment.get(slot)


func free_bag_index() -> int:
	return bag.find(null)


func add_item(item: Item) -> bool:
	var i := free_bag_index()
	if i == -1:
		return false
	bag[i] = item
	changed.emit()
	return true


func remove_bag_item(index: int) -> Item:
	var item: Item = bag[index]
	bag[index] = null
	changed.emit()
	return item


## Ranura donde iría el objeto: los anillos buscan primero un hueco libre.
func target_slot_for(item: Item) -> String:
	var s := item.slot()
	if s != "ring":
		return s
	if not equipment.has("ring_left"):
		return "ring_left"
	if not equipment.has("ring_right"):
		return "ring_right"
	return "ring_left"


func set_equipped(slot: String, item: Item) -> void:
	equipment[slot] = item
	changed.emit()


## Equipa el objeto de la bolsa; lo que hubiera en esa ranura pasa a su hueco.
func equip_from_bag(index: int) -> bool:
	var item: Item = bag[index]
	if item == null:
		return false
	var slot := target_slot_for(item)
	bag[index] = equipment.get(slot)
	equipment[slot] = item
	changed.emit()
	return true


func to_dict() -> Dictionary:
	var equip := {}
	for slot in equipment:
		equip[slot] = equipment[slot].to_dict()
	var bag_data: Array = []
	for item in bag:
		bag_data.append(item.to_dict() if item else null)
	return {"equipment": equip, "bag": bag_data}


## Restaura equipo y bolsa. Los objetos que ya no se pueden cargar se descartan.
func load_dict(d: Dictionary, db: ItemDatabase) -> void:
	equipment.clear()
	bag.clear()
	bag.resize(BAG_SIZE)
	var equip: Dictionary = d.get("equipment", {})
	for slot in equip:
		if EQUIP_SLOTS.has(slot):
			var item := Item.from_dict(equip[slot], db)
			if item:
				equipment[slot] = item
	var bag_data: Array = d.get("bag", [])
	for i in mini(bag_data.size(), BAG_SIZE):
		if bag_data[i] is Dictionary:
			bag[i] = Item.from_dict(bag_data[i], db)
	changed.emit()


func unequip(slot: String) -> bool:
	var i := free_bag_index()
	if i == -1 or not equipment.has(slot):
		return false
	bag[i] = equipment[slot]
	equipment.erase(slot)
	changed.emit()
	return true
