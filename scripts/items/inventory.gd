class_name Inventory
extends RefCounted
## Equipo por ranura + bolsa de tamaño fijo + placas base instaladas en la barra
## de habilidades. Solo datos: la UI está en InventoryPanel/SkillsPanel y las
## reglas de nivel en CharacterData.

signal changed

const BAG_SIZE := 60
const HOTBAR_SIZE := 6
## Cinturón de pociones (teclas 1-5).
const FLASK_SLOTS := 5
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
	"flask": "Poción",
	"chip": "Chip de expansión (árbol pasivo)",
}

var equipment: Dictionary = {}  # ranura -> Item
## Chips de expansión engastados en el árbol pasivo: id de nodo -> ExpansionChip.
var chips: Dictionary = {}


## Engasta el chip de la bolsa (índice) en la ranura `node_id`; el que hubiera vuelve a la bolsa.
func socket_chip(bag_index: int, node_id: int) -> bool:
	var chip := bag[bag_index] as ExpansionChip
	if chip == null:
		return false
	bag[bag_index] = chips.get(node_id, null)
	chips[node_id] = chip
	changed.emit()
	return true


## Saca el chip de la ranura a la bolsa (si cabe).
func unsocket_chip(node_id: int) -> bool:
	if not chips.has(node_id):
		return false
	var free := bag.find(null)
	if free == -1:
		return false
	bag[free] = chips[node_id]
	chips.erase(node_id)
	changed.emit()
	return true
var bag: Array = []             # Item o null
## Placa base instalada en cada ranura de la barra de habilidades, o null.
var boards: Array = []
## Poción en cada ranura del cinturón, o null.
var flasks: Array = []


func _init() -> void:
	bag.resize(BAG_SIZE)
	boards.resize(HOTBAR_SIZE)
	flasks.resize(FLASK_SLOTS)


## Pone la poción de la bolsa en el cinturón (primera ranura libre, o
## intercambia con la ranura indicada).
func equip_flask(bag_index: int, flask_index := -1) -> bool:
	var flask := bag[bag_index] as Flask
	if flask == null:
		return false
	if flask_index == -1:
		flask_index = flasks.find(null)
		if flask_index == -1:
			return false
	bag[bag_index] = flasks[flask_index]
	flasks[flask_index] = flask
	SoundMap.play_equip(flask)
	changed.emit()
	return true


func unequip_flask(flask_index: int) -> bool:
	var i := free_bag_index()
	if i == -1 or flasks[flask_index] == null:
		return false
	bag[i] = flasks[flask_index]
	flasks[flask_index] = null
	changed.emit()
	return true


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
	SoundMap.play_equip(item)   # según el material (T77)
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
	SoundMap.play_equip(board)
	changed.emit()
	return true


## Ordena y compacta la bolsa (T79): sin huecos, primero el equipo (por ranura,
## rareza y nivel), luego pociones, placas, RAM, chips y objetos clave; lo marcado
## como basura, al final. Devuelve cuántos objetos hay.
func sort_bag() -> int:
	var items: Array = bag.filter(func(it) -> bool: return it != null)
	items.sort_custom(func(a: Item, b: Item) -> bool:
		var ka := bag_sort_key(a)
		var kb := bag_sort_key(b)
		for k in ka.size():
			if ka[k] != kb[k]:
				return ka[k] < kb[k]
		return false)
	for i in bag.size():
		bag[i] = items[i] if i < items.size() else null
	changed.emit()
	return items.size()


## Clave de orden de un objeto de la bolsa (menor = antes).
static func bag_sort_key(it: Item) -> Array:
	var group := 0
	if it is Flask:
		group = 1
	elif it is Motherboard:
		group = 2
	elif it is RamModule:
		group = 3
	elif it is ExpansionChip:
		group = 4
	elif it is KeyItem:
		group = 5
	var slot_order := EQUIP_SLOTS.find(it.slot()) if group == 0 else 0
	var name_key := 0
	if it is Motherboard:
		name_key = String((it as Motherboard).skill_def.get("name", "")).hash() % 100000
	return [1 if it.junk else 0, group, slot_order, -it.rarity, name_key, -it.item_level]


## Ordena las placas y los módulos RAM de la bolsa sin mover lo demás: ocupan
## los mismos huecos, pero primero las placas (por nombre y nivel) y luego las RAM
## (por generación, familia y grado).
func sort_skill_items() -> void:
	var spots: Array[int] = []
	var items: Array = []
	for i in BAG_SIZE:
		if bag[i] is Motherboard or bag[i] is RamModule:
			spots.append(i)
			items.append(bag[i])
	items.sort_custom(func(a: Item, b: Item) -> bool: return skill_item_key(a) < skill_item_key(b))
	for k in spots.size():
		bag[spots[k]] = items[k]
	changed.emit()


## Clave de orden de placas y RAM (también la usa el menú de habilidades).
static func skill_item_key(item: Item) -> String:
	if item is Motherboard:
		var b := item as Motherboard
		return "0|%s|%03d" % [b.skill_def.get("name", ""), 999 - b.level]
	var r := item as RamModule
	return "1|%s|%s|%d" % [r.generation(), r.family(), 9 - r.tier()]


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
		SoundMap.play_equip(ram)
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
		equip[slot] = Item.serialize(equipment[slot])
	var bag_data: Array = []
	for item in bag:
		bag_data.append(Item.serialize(item))
	var board_data: Array = []
	for board in boards:
		board_data.append(Item.serialize(board))
	var flask_data: Array = []
	for f in flasks:
		flask_data.append(f.to_dict() if f else null)
	var chip_data := {}
	for id in chips:
		chip_data[str(id)] = chips[id].to_dict()
	return {"equipment": equip, "bag": bag_data, "boards": board_data, "flasks": flask_data, "chips": chip_data}


## Restaura equipo, bolsa y placas. Lo que ya no se puede cargar se descarta.
func load_dict(d: Dictionary, db: ItemDatabase) -> void:
	equipment.clear()
	bag.clear()
	bag.resize(BAG_SIZE)
	boards.clear()
	boards.resize(HOTBAR_SIZE)
	flasks.clear()
	flasks.resize(FLASK_SLOTS)
	chips.clear()
	var chip_data: Dictionary = d.get("chips", {})
	for key in chip_data:
		if chip_data[key] is Dictionary:
			chips[int(key)] = ExpansionChip.from_save(chip_data[key])
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
	if d.has("flasks"):
		var flask_data: Array = d.get("flasks", [])
		for i in mini(flask_data.size(), FLASK_SLOTS):
			if flask_data[i] is Dictionary:
				flasks[i] = Item.from_dict(flask_data[i], db) as Flask
	else:
		# Guardados de antes de las pociones-objeto: reciben las iniciales.
		var starters := Flask.starter_set(db)
		for i in mini(starters.size(), FLASK_SLOTS):
			flasks[i] = starters[i]
	changed.emit()
