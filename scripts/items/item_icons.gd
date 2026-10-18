class_name ItemIcons
## Iconos de objetos desde el atlas assets/sprites/items/items.png
## (generado por tools/generate_item_icons.gd; mapa id → índice en data/item_icons.json).

const ATLAS_PATH := "res://assets/sprites/items/items.png"
const MAP_PATH := "res://data/item_icons.json"

static var _atlas: Texture2D
static var _map: Dictionary = {}
static var _columns := 8
static var _size := 32


static func _ensure_loaded() -> void:
	if _atlas != null:
		return
	_atlas = load(ATLAS_PATH)
	var data = DataLoader.load_json(MAP_PATH)
	if data is Dictionary:
		_map = data.get("icons", {})
		_columns = int(data.get("columns", 8))
		_size = int(data.get("size", 32))


static func icon_id(item: Item) -> String:
	if item is Motherboard:
		return "motherboard"
	if item is RamModule:
		return "ram_" + (item as RamModule).generation()
	if item is Flask:
		return (item as Flask).icon()
	return item.base.get("id", "unknown")


static func has_icon(id: String) -> bool:
	_ensure_loaded()
	return _map.has(id)


static func region(id: String) -> Rect2:
	_ensure_loaded()
	var index := int(_map.get(id, _map.get("unknown", 0)))
	return Rect2((index % _columns) * _size, (index / _columns) * _size, _size, _size)


static func texture() -> Texture2D:
	_ensure_loaded()
	return _atlas


## Dibuja el icono ajustado (sin deformar) y centrado dentro de `rect`.
## Con pixel_perfect se escala a múltiplos enteros (píxeles nítidos).
static func draw(ci: CanvasItem, rect: Rect2, id: String, modulate := Color.WHITE, pixel_perfect := true) -> void:
	_ensure_loaded()
	var side := minf(rect.size.x, rect.size.y)
	if pixel_perfect and side >= _size:
		side = floorf(side / _size + 0.15) * _size  # tolera unos píxeles de margen
	if side <= 0.0:
		side = minf(rect.size.x, rect.size.y)
	var dest := Rect2(rect.get_center() - Vector2(side, side) / 2.0, Vector2(side, side))
	ci.draw_texture_rect_region(_atlas, dest, region(id), modulate)


static func draw_item(ci: CanvasItem, rect: Rect2, item: Item, modulate := Color.WHITE) -> void:
	draw(ci, rect, icon_id(item), modulate)
