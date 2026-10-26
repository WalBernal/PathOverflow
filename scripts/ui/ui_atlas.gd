class_name UiAtlas
## Piezas de interfaz en pixel art (T95): un atlas con cuadrícula fija generado por
## tools/generate_ui_atlas.gd. Cada pieza es un marco de 9 partes (las esquinas y
## los bordes de MARGIN px no se estiran) que UiStyle usa como StyleBoxTexture.
## Para arte a mano, sustituye el PNG respetando la cuadrícula y los márgenes.

const PATH := "res://assets/sprites/ui/ui_atlas.png"
## Lado de cada celda en el PNG (24 píxeles de arte a escala 2).
const CELL := 48
## Borde que no se estira (esquinas y lados del marco de 9 partes).
const MARGIN := 12
const COLUMNS := 4
## Pieza -> celda (columna, fila) en el atlas.
const PIECES := {
	"window": Vector2i(0, 0), "panel": Vector2i(1, 0), "inset": Vector2i(2, 0), "tooltip": Vector2i(3, 0),
	"button_normal": Vector2i(0, 1), "button_hover": Vector2i(1, 1), "button_pressed": Vector2i(2, 1), "button_disabled": Vector2i(3, 1),
	"slot_normal": Vector2i(0, 2), "slot_magic": Vector2i(1, 2), "slot_rare": Vector2i(2, 2), "slot_unique": Vector2i(3, 2),
	"bar_frame": Vector2i(0, 3), "tab_active": Vector2i(1, 3), "tab_inactive": Vector2i(2, 3), "separator": Vector2i(3, 3),
	"hotbar_plate": Vector2i(0, 4), "flask_frame": Vector2i(2, 4), "line_edit": Vector2i(3, 4),
}
const ROWS := 5
## Piezas grandes debajo de la cuadrícula, dibujadas a resolución final (no a ×2):
## el aro de los orbes se ve grande y con píxeles de arte gordos quedaba tosco.
const BIG_PIECES := {"orb_frame": Rect2(0, ROWS * CELL, 2 * CELL, 2 * CELL)}
const BIG_ROWS := 2
## Del aro del orbe, el radio interior respecto a la mitad de la pieza.
const ORB_INNER := 0.84
## Casilla de objeto según la rareza (Rarity.Item: normal, mágico, raro, único).
const SLOT_BY_RARITY := ["slot_normal", "slot_magic", "slot_rare", "slot_unique"]

static var _texture: Texture2D
static var _loaded := false


static func texture() -> Texture2D:
	if not _loaded:
		_loaded = true
		if ResourceLoader.exists(PATH):
			_texture = load(PATH)
	return _texture


static func region(piece: String) -> Rect2:
	if BIG_PIECES.has(piece):
		return BIG_PIECES[piece]
	var cell: Vector2i = PIECES.get(piece, Vector2i.ZERO)
	return Rect2(cell.x * CELL, cell.y * CELL, CELL, CELL)


## Marco de 9 partes de una pieza, con márgenes de contenido (o null sin atlas).
static func box(piece: String, content_h := 12.0, content_v := 8.0) -> StyleBoxTexture:
	var tex := texture()
	if tex == null or not PIECES.has(piece):
		return null
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.region_rect = region(piece)
	s.set_texture_margin_all(MARGIN)
	s.content_margin_left = content_h
	s.content_margin_right = content_h
	s.content_margin_top = content_v
	s.content_margin_bottom = content_v
	return s


static func slot_piece(rarity: int) -> String:
	return SLOT_BY_RARITY[clampi(rarity, 0, SLOT_BY_RARITY.size() - 1)]


## Dibuja una pieza estirada (9 partes) en `rect` de `ci`. Sin atlas no hace nada.
static func draw(ci: CanvasItem, piece: String, rect: Rect2, tint := Color.WHITE) -> void:
	var s := box(piece)
	if s == null:
		return
	s.modulate_color = tint
	s.draw(ci.get_canvas_item(), rect)


## Dibuja una pieza entera escalada (sin 9 partes): el aro de los orbes.
static func draw_whole(ci: CanvasItem, piece: String, rect: Rect2, tint := Color.WHITE) -> void:
	var tex := texture()
	if tex != null:
		ci.draw_texture_rect_region(tex, rect, region(piece), tint)


## Aro de orbe alrededor de un círculo de radio `radius`: su borde interior queda justo fuera.
static func draw_orb_frame(ci: CanvasItem, center: Vector2, radius: float) -> void:
	var half := (radius + 1.0) / ORB_INNER
	draw_whole(ci, "orb_frame", Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0))
