class_name KeyItem
extends Item
## Objeto clave (tarjetas, llaves...): va en la bolsa y abre caminos bloqueados
## (salidas con requires_item en actN.json). No se equipa, no se vende y no se
## puede tirar al suelo: perderlo dejaría el camino cerrado para siempre.

const COLOR := Color("ffd84a")
## Definiciones conocidas (id -> nombre, descripción, icono).
const DEFS := {
	"tarjeta_rack": {"name": "Tarjeta de Acceso al Rack", "icon": "key_card",
		"description": "Tarjeta magnética de un técnico de El Pepe. Abre la escotilla del Módulo de Refrigeración, en las Alcantarillas del Buffer Overflow."},
}

var key_id := ""


func _init(p_key_id := "") -> void:
	key_id = p_key_id
	var d: Dictionary = DEFS.get(p_key_id, {})
	super({"id": d.get("icon", "key_card"), "name": d.get("name", p_key_id), "slot": "key", "level": 1, "tags": []},
		Rarity.Item.NORMAL, 1)


func display_color() -> Color:
	return COLOR


func description() -> String:
	return DEFS.get(key_id, {}).get("description", "")


func get_modifiers(_source: String) -> Array[Modifier]:
	return []


func to_dict() -> Dictionary:
	return {"kind": "key", "key_id": key_id}


static func from_save(d: Dictionary) -> KeyItem:
	return KeyItem.new(String(d.get("key_id", "")))


## ¿Lleva el personaje esa llave en la bolsa?
static func has_key(inventory: Inventory, id: String) -> bool:
	for item in inventory.bag:
		if item is KeyItem and (item as KeyItem).key_id == id:
			return true
	return false
