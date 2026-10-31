extends SceneTree
## Genera el ícono de la app (T174) en pixel art, en assets/icons/:
## - icon.png (1024): fondo oscuro redondeado con borde y el motivo.
## - icon_foreground.png / icon_background.png (432): el ícono adaptable de Android;
##   el motivo ocupa el 66 % del centro (la zona que ningún recorte de Android tapa).
## Motivo: la pila del logo del título que se desborda (barras verdes y bloques rojos
## cayendo) entre «<» y «/>». Se dibuja en una rejilla de MOTIF×MOTIF y se agranda
## sin suavizar, así se ve nítido a cualquier tamaño.
## Uso:  Godot_v4.7.2-stable_win64.exe --headless --path . -s res://tools/generate_app_icon.gd

const DIR := "res://assets/icons/"
const MOTIF := 48
const BG := Color("0f141c")
const BG_EDGE := Color("1c2633")
const BORDER := Color("2fd0a0")
const OUTLINE := Color("070a0f")
const GREEN := Color("3ccf5a")
const GREEN_LIGHT := Color("8ef0a0")
const GREEN_DARK := Color("1f8a3a")
const RED := Color("e05252")
const RED_LIGHT := Color("ff9a8a")
const RED_DARK := Color("9a2a2a")
const BRACKET := Color("2fd0a0")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var motif := motif_image()
	# Ícono completo: 64×64 celdas (motivo con 8 de margen) × 16 = 1024.
	var full := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	full.fill(Color(0, 0, 0, 0))
	_rounded_rect(full, Rect2i(0, 0, 64, 64), 11, BG_EDGE)
	_rounded_rect(full, Rect2i(2, 2, 60, 60), 9, BG)
	_rounded_border(full, Rect2i(2, 2, 60, 60), 9, BORDER.darkened(0.35))
	full.blend_rect(motif, Rect2i(0, 0, MOTIF, MOTIF), Vector2i(8, 8))
	_save(full, 16, "icon.png")
	# Adaptable de Android: 72×72 celdas × 6 = 432; el motivo (48) en el centro = 66 %.
	var fg := Image.create_empty(72, 72, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	fg.blend_rect(motif, Rect2i(0, 0, MOTIF, MOTIF), Vector2i(12, 12))
	_save(fg, 6, "icon_foreground.png")
	# Monocromo (íconos temáticos de Android 13+): la silueta del motivo en blanco.
	var mono := Image.create_empty(72, 72, false, Image.FORMAT_RGBA8)
	mono.fill(Color(0, 0, 0, 0))
	for y in MOTIF:
		for x in MOTIF:
			var c := motif.get_pixel(x, y)
			if c.a > 0.0 and c != OUTLINE:
				mono.set_pixel(x + 12, y + 12, Color.WHITE)
	_save(mono, 6, "icon_monochrome.png")
	var bg := Image.create_empty(72, 72, false, Image.FORMAT_RGBA8)
	bg.fill(BG)
	for y in range(0, 72, 6):   # rejilla tenue de puntos, como una placa
		for x in range(0, 72, 6):
			bg.set_pixel(x + 3, y + 3, BG_EDGE)
	_save(bg, 6, "icon_background.png")
	print("ícono generado en %s" % DIR)
	quit()


## El motivo en MOTIF×MOTIF celdas con fondo transparente.
static func motif_image() -> Image:
	var img := Image.create_empty(MOTIF, MOTIF, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# La pila: cuatro barras verdes, de abajo arriba.
	for k in 4:
		_block(img, Rect2i(14, 37 - k * 5, 20, 4), GREEN, GREEN_LIGHT, GREEN_DARK)
	# El desbordamiento: dos bloques rojos que se salen hacia la derecha y un trozo cayendo.
	_block(img, Rect2i(17, 15, 18, 4), RED, RED_LIGHT, RED_DARK)
	_block(img, Rect2i(21, 9, 15, 4), RED, RED_LIGHT, RED_DARK)
	_block(img, Rect2i(31, 3, 6, 3), RED, RED_LIGHT, RED_DARK)
	# «<» a la izquierda y «/>» a la derecha.
	for i in 6:
		_dot(img, Vector2i(9 - i, 21 + i), BRACKET)
		_dot(img, Vector2i(9 - i, 31 - i), BRACKET)
	for i in 12:
		_dot(img, Vector2i(35 + i / 4, 33 - i), BRACKET.darkened(0.15))
	for i in 5:
		_dot(img, Vector2i(40 + i, 19 + i), BRACKET)
		_dot(img, Vector2i(40 + i, 29 - i), BRACKET)
	_outline(img)
	return img


## Barra con su luz arriba y su sombra abajo.
static func _block(img: Image, r: Rect2i, base: Color, light: Color, dark: Color) -> void:
	img.fill_rect(r, base)
	img.fill_rect(Rect2i(r.position, Vector2i(r.size.x, 1)), light)
	img.fill_rect(Rect2i(r.position + Vector2i(0, r.size.y - 1), Vector2i(r.size.x, 1)), dark)
	img.set_pixel(r.position.x + 1, r.position.y + 1, light.lightened(0.4))   # brillo


## Trazo de 2×2 (para los corchetes).
static func _dot(img: Image, p: Vector2i, color: Color) -> void:
	img.fill_rect(Rect2i(p, Vector2i(2, 2)), color)


## Contorno oscuro de 1 celda alrededor de todo lo dibujado.
static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


static func _rounded_rect(img: Image, r: Rect2i, radius: int, color: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _inside_rounded(Vector2i(x, y), r, radius):
				img.set_pixel(x, y, color)


static func _rounded_border(img: Image, r: Rect2i, radius: int, color: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var p := Vector2i(x, y)
			if _inside_rounded(p, r, radius) and not _inside_rounded(p, r.grow(-1), radius - 1):
				img.set_pixel(x, y, color)


static func _inside_rounded(p: Vector2i, r: Rect2i, radius: int) -> bool:
	if not r.has_point(p):
		return false
	var cx := clampi(p.x, r.position.x + radius, r.end.x - 1 - radius)
	var cy := clampi(p.y, r.position.y + radius, r.end.y - 1 - radius)
	return Vector2(p - Vector2i(cx, cy)).length() <= radius + 0.25


static func _save(img: Image, factor: int, name: String) -> void:
	var big := img.duplicate() as Image
	big.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(DIR + name))
