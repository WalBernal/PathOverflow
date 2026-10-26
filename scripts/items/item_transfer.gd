class_name ItemTransfer
## Mover objetos entre ubicaciones (arrastrar y soltar). Una ubicación es un
## diccionario:
##   {"kind": "bag", "index": i}
##   {"kind": "equip", "slot": "helmet"}
##   {"kind": "board", "index": h}              (ranura de la barra de habilidades)
##   {"kind": "dimm", "board": h, "dimm": d}    (ranura DIMM de una placa instalada)
##   {"kind": "flask", "index": f}              (ranura del cinturón de pociones)
##   {"kind": "stash", "tab": t, "index": i}    (alijo compartido, ver ItemTransfer.stash)
## Siempre es un intercambio: lo que hay en el destino vuelve al origen, así que
## ambos objetos tienen que encajar donde acaban.

## El alijo de la cuenta (lo pone World). Sin él, las ubicaciones "stash" no existen.
static var stash: Stash


static func get_at(inv: Inventory, loc: Dictionary) -> Item:
	match loc.get("kind", ""):
		"bag":
			return inv.bag[loc["index"]]
		"equip":
			return inv.equipment.get(loc["slot"])
		"board":
			return inv.boards[loc["index"]]
		"dimm":
			var board: Motherboard = inv.boards[loc["board"]]
			return board.rams[loc["dimm"]] if board else null
		"flask":
			return inv.flasks[loc["index"]]
		"stash":
			return stash.get_item(loc["tab"], loc["index"]) if stash else null
	return null


static func _set_at(inv: Inventory, loc: Dictionary, item: Item) -> void:
	match loc["kind"]:
		"bag":
			inv.bag[loc["index"]] = item
		"equip":
			if item == null:
				inv.equipment.erase(loc["slot"])
			else:
				inv.equipment[loc["slot"]] = item
		"board":
			inv.boards[loc["index"]] = item
		"dimm":
			inv.boards[loc["board"]].rams[loc["dimm"]] = item
		"flask":
			inv.flasks[loc["index"]] = item
		"stash":
			stash.set_item(loc["tab"], loc["index"], item)


## "" si `item` puede quedarse en `loc`; si no, el motivo.
static func fits(character: CharacterData, loc: Dictionary, item: Item) -> String:
	if item == null:
		return ""
	match loc.get("kind", ""):
		"bag":
			return ""
		"stash":
			if stash == null:
				return "El alijo no está disponible aquí."
			if item is KeyItem:
				return "Los objetos clave se quedan contigo: son de tu historia, no de la cuenta."
			return ""
		"equip":
			var slot: String = loc["slot"]
			if item is Flask:
				return "Las pociones van en el cinturón de pociones (abajo del inventario)."
			if item is KeyItem:
				return "Es un objeto clave: se queda en la bolsa y abre caminos bloqueados."
			if not item.is_equipment():
				return "Eso no se lleva puesto. Las placas y la RAM van en el menú de habilidades (K)."
			var ok := item.slot() == slot or (item.slot() == "ring" and slot.begins_with("ring"))
			if not ok:
				return "Eso no va en esa ranura. Ni con cinta americana."
			if not character.can_equip(item):
				return equip_refusal(character, item)
			return ""
		"board":
			return "" if item is Motherboard else "Ahí solo caben placas base."
		"dimm":
			var board: Motherboard = character.inventory.boards[loc["board"]]
			if board == null:
				return "No hay placa base en esa fila."
			if not item is RamModule:
				return "En una ranura DIMM solo cabe RAM. Por mucho que lo intentes."
			var gen: String = board.slots[loc["dimm"]]
			if (item as RamModule).generation() != gen:
				return "Ranura %s, módulo %s. No encaja ni a martillazos." % [gen, (item as RamModule).generation()]
			return ""
		"flask":
			if not item is Flask:
				return "En el cinturón solo caben pociones. Café o bebidas, nada de placas."
			if character.level < item.required_level():
				return "Requiere nivel %d. Este café es demasiado fuerte para ti." % item.required_level()
			return ""
	return "Destino desconocido."


## Por qué no puedes equipar un objeto (nivel o atributos).
static func equip_refusal(character: CharacterData, item: Item) -> String:
	if character.level < item.required_level():
		return "Requiere nivel %d. Vuelve cuando seas senior." % item.required_level()
	var lack := PackedStringArray()
	var missing := character.missing_attributes(item)
	for a in missing:
		lack.append("%d de %s" % [missing[a], Item.ATTR_NAMES[a]])
	return "Te faltan %s para usar esto. Al árbol (P) o a buscar un anillo." % " y ".join(lack)


## Mueve (intercambia) lo que hay en `from` con lo que hay en `to`.
## Devuelve "" si se hizo; si no, el motivo para mostrarlo.
static func move(character: CharacterData, from: Dictionary, to: Dictionary) -> String:
	if from == to:
		return ""
	var inv := character.inventory
	var a := get_at(inv, from)
	if a == null:
		return ""
	var b := get_at(inv, to)
	var problem := fits(character, to, a)
	if problem == "":
		problem = fits(character, from, b)
	if problem != "":
		return problem
	_set_at(inv, to, a)
	_set_at(inv, from, b)
	if String(to.get("kind", "")) in ["equip", "board", "dimm", "flask"]:
		SoundMap.play_equip(a)   # ponérselo suena según el material (T77)
	inv.changed.emit()
	_stash_touched(from, to)
	return ""


## Saca el objeto de `from` (para tirarlo al suelo). Devuelve el objeto.
## Los objetos clave no se pueden tirar (devuelve null).
static func take(character: CharacterData, from: Dictionary) -> Item:
	var item := get_at(character.inventory, from)
	if item is KeyItem:
		return null
	if item:
		_set_at(character.inventory, from, null)
		character.inventory.changed.emit()
		_stash_touched(from, {})
	return item


## Si se tocó el alijo: avisa a su panel y lo guarda (es de toda la cuenta).
static func _stash_touched(a: Dictionary, b: Dictionary) -> void:
	if stash and (a.get("kind", "") == "stash" or b.get("kind", "") == "stash"):
		stash.changed.emit()
		stash.save()
