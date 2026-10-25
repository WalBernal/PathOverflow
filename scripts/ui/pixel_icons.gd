class_name PixelIcons
## Iconos en pixel art de habilidades, estados y familias de RAM (T75), en dos
## atlas: 32×32 (barra, ventanas) y 16×16 (insignias, sobre los enemigos). Los
## genera tools/generate_pixel_icons.gd a partir de los glifos de SkillIcon,
## StatusIcon y RamIcon, rasterizados sin suavizado, con contorno y paleta
## reducida, como los objetos (ItemIcons). Para usar iconos dibujados a mano,
## sustituye los PNG manteniendo la cuadrícula. Claves: "skill:<id>",
## "status:<id>" y "ram:<familia>". Si una clave no está, quien llama dibuja con formas.

const ATLAS_32 := "res://assets/sprites/icons/icons32.png"
const ATLAS_16 := "res://assets/sprites/icons/icons16.png"
const MAP_PATH := "res://data/pixel_icons.json"
## Por debajo de este lado (px en pantalla) se usa el atlas de 16.
const SMALL_BELOW := 26.0

## Desactivable (pruebas y comparación con los glifos de formas).
static var enabled := true
static var _loaded := false
static var _atlas32: Texture2D
static var _atlas16: Texture2D
static var _map: Dictionary = {}
static var _columns := 16


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var data = DataLoader.load_json(MAP_PATH) if FileAccess.file_exists(MAP_PATH) else null
	if not (data is Dictionary) or not ResourceLoader.exists(ATLAS_32) or not ResourceLoader.exists(ATLAS_16):
		return
	_map = data.get("icons", {})
	_columns = int(data.get("columns", 16))
	_atlas32 = load(ATLAS_32)
	_atlas16 = load(ATLAS_16)


static func has_icon(key: String) -> bool:
	_ensure_loaded()
	return enabled and _atlas32 != null and _map.has(key)


static func region(key: String, size: int) -> Rect2:
	_ensure_loaded()
	var index := int(_map.get(key, 0))
	return Rect2((index % _columns) * size, (index / _columns) * size, size, size)


## Dibuja el icono `key` centrado en `rect` (escala entera, píxeles nítidos).
## Devuelve false si no hay icono (y no dibuja nada).
static func draw(ci: CanvasItem, rect: Rect2, key: String, modulate := Color.WHITE) -> bool:
	if not has_icon(key):
		return false
	var side := minf(rect.size.x, rect.size.y)
	var size := 16 if side < SMALL_BELOW else 32
	var atlas: Texture2D = _atlas16 if size == 16 else _atlas32
	# Escala entera redondeada (píxeles nítidos); puede salirse un 10 % del hueco, que
	# el icono lleva margen transparente. Si ni así cabe, escala libre.
	var drawn := maxf(1.0, roundf(side / size)) * size
	if drawn > side * 1.1:
		drawn = side
	var dest := Rect2(rect.get_center() - Vector2(drawn, drawn) * 0.5, Vector2(drawn, drawn))
	ci.draw_texture_rect_region(atlas, dest, region(key, size), modulate)
	return true
