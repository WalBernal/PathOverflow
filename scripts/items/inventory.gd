class_name Inventory
extends RefCounted
## Equipo por ranura + bolsa de tamaño fijo + placas base instaladas en la barra
## de habilidades. Solo datos: la UI está en InventoryPanel/SkillsPanel y las
## reglas de nivel en CharacterData.

signal changed

const BAG_SIZE := 60
const HOTBAR_SIZE := 6
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
	"motherboard": "Placa base",
	"ram": "Módulo RAM",
}

var equipment: Dictionary = {}  # ranura -> Item
var bag: Array = []             # Item o null
## Placa base instalada en cada ranura de la barra de habilidades, o null.
var boards: Array = []


func _init() -> void:
	bag.resize(BAG_SIZE)
	boards.resize(HOTBAR_SIZE)


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
## Las placas base y la RAM no se equipan aquí (ver install_board / install_ram).
func equip_from_bag(index: int) -> bool:
	var item: Item = bag[index]
	if item == null or not item.is_equipment():
		return false
	var slot := target_slot_for(item)
	bag[index] = equipment.get(slot)
	equipment[slot] = item
	changed.emit()
	return true


func unequip(slot: String) -> bool:
	var i := free_bag_index()
	if i == -1 or not equipment.has(slot):
		return false
	bag[i] = equipment[slot]
	equipment.erase(slot)
	changed.emit()
	return true


# --- Placas base y RAM ---

func set_board(hotbar_index: int, board: Motherboard) -> void:
	boards[hotbar_index] = board
	changed.emit()


## Instala la placa base de la bolsa en esa ranura de la barra (intercambia si
## ya había otra). Si hotbar_index es -1, usa la primera ranura libre.
func install_board(bag_index: int, hotbar_index := -1) -> bool:
	var board := bag[bag_index] as Motherboard
	if board == null:
		return false
	if hotbar_index == -1:
		hotbar_index = boards.find(null)
		if hotbar_index == -1:
			return false
	bag[bag_index] = boards[hotbar_index]
	boards[hotbar_index] = board
	changed.emit()
	return true


## Intercambia dos ranuras de la barra (para elegir qué tecla usa cada placa).
func swap_boards(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= HOTBAR_SIZE or b >= HOTBAR_SIZE:
		return
	var tmp = boards[a]
	boards[a] = boards[b]
	boards[b] = tmp
	changed.emit()


func uninstall_board(hotbar_index: int) -> bool:
	var i := free_bag_index()
	if i == -1 or boards[hotbar_index] == null:
		return false
	bag[i] = boards[hotbar_index]
	boards[hotbar_index] = null
	changed.emit()
	return true


## Instala la RAM de la bolsa en una ranura DIMM de una placa instalada.
## dimm_index -1: la primera ranura libre compatible. Devuelve "" o el motivo.
func install_ram(bag_index: int, hotbar_index: int, dimm_index := -1) -> String:
	var ram := bag[bag_index] as RamModule
	var board: Motherboard = boards[hotbar_index]
	if ram == null or board == null:
		return "Selecciona un módulo RAM y una placa base."
	if dimm_index == -1:
		dimm_index = board.free_slot_for(ram)
		if dimm_index == -1:
			return "Esta placa no tiene ranuras %s libres." % ram.generation()
	var problem := board.install(ram, dimm_index)
	if problem == "":
		bag[bag_index] = null
		changed.emit()
	return problem


func remove_ram(hotbar_index: int, dimm_index: int) -> bool:
	var board: Motherboard = boards[hotbar_index]
	var i := free_bag_index()
	if board == null or i == -1 or board.rams[dimm_index] == null:
		return false
	bag[i] = board.remove(dimm_index)
	changed.emit()
	return true


func to_dict() -> Dictionary:
	var equip := {}
	for slot in equipment:
		equip[slot] = equipment[slot].to_dict()
	var bag_data: Array = []
	for item in bag:
		bag_data.append(item.to_dict() if item else null)
	var board_data: Array = []
	for board in boards:
		board_data.append(board.to_dict() if board else null)
	return {"equipment": equip, "bag": bag_data, "boards": board_data}


## Restaura equipo, bolsa y placas. Lo que ya no se puede cargar se descarta.
func load_dict(d: Dictionary, db: ItemDatabase) -> void:
	equipment.clear()
	bag.clear()
	bag.resize(BAG_SIZE)
	boards.clear()
	boards.resize(HOTBAR_SIZE)
	var equip: Dictionary = d.get("equipment", {})
	for slot in equip:
		if EQUIP_SLOTS.has(slot):
			var item := Item.from_dict(equip[slot], db)
			if item and item.is_equipment():
				equipment[slot] = item
	var bag_data: Array = d.get("bag", [])
	for i in mini(bag_data.size(), BAG_SIZE):
		if bag_data[i] is Dictionary:
			bag[i] = Item.from_dict(bag_data[i], db)
	var board_data: Array = d.get("boards", [])
	for i in mini(board_data.size(), HOTBAR_SIZE):
		if board_data[i] is Dictionary:
			boards[i] = Item.from_dict(board_data[i], db) as Motherboard
	changed.emit()
