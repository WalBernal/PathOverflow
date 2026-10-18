class_name PassiveIcons
## Iconos de notables y piedras angulares desde assets/sprites/passives/passives.png
## (generado por tools/generate_passive_icons.gd; mapa en data/passive_icons.json).

const ATLAS_PATH := "res://assets/sprites/passives/passives.png"
const MAP_PATH := "res://data/passive_icons.json"

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


static func has_icon(id: String) -> bool:
	_ensure_loaded()
	return _map.has(id)


## Dibuja el icono centrado en `center` con `side` píxeles de lado.
static func draw(ci: CanvasItem, center: Vector2, side: float, id: String, modulate := Color.WHITE) -> void:
	_ensure_loaded()
	if not _map.has(id):
		return
	var index := int(_map[id])
	var region := Rect2((index % _columns) * _size, (index / _columns) * _size, _size, _size)
	ci.draw_texture_rect_region(_atlas, Rect2(center - Vector2(side, side) / 2.0, Vector2(side, side)), region, modulate)
