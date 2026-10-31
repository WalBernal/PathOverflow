extends SceneTree
## Importa el arte de los héroes (T176) desde la lámina de propuestas del usuario
## (docs/capturas/personajes/propuestas_frente.png: cinco personajes de frente, A-E,
## dibujados a 5 píxeles de pantalla por píxel sobre una loseta de césped) y lo corta
## en capas en assets/sprites/hero/:
## - base.png: A, el alumno («Dev Glitcheado»), sin la loseta. Es la base que se
##   recolorea con la apariencia del creador (StudentHero).
## - head_X / torso_X / legs_X.png: lo que cada propuesta (B-E) cambia respecto a A en
##   cada zona del cuerpo (cabeza, torso con brazos, piernas): casco, armadura, botas.
## - weapon_sword / weapon_dagger / weapon_staff.png: las armas de B, D y C.
## Todo comparte la misma plantilla (la loseta y la cara coinciden píxel a píxel), así
## que las capas encajan sobre el alumno sin mover nada.
## Uso:  Godot_v4.7.2-stable_win64.exe --headless --path . -s res://tools/import_hero_art.gd

const SOURCE := "res://docs/capturas/personajes/propuestas_frente.png"
const OUT := "res://assets/sprites/hero/"
const BLOCK := 5
const CARD_X := [20, 350, 680, 1010, 1340]
const GRID := Vector2i(0, 2)   # desfase de la rejilla de 5×5 en la lámina
const TOP := 30
const SIZE := Vector2i(60, 56)
## Bandas (filas de la plantilla, incluidas): cabeza, torso con brazos y manos, piernas.
const HEAD_ROWS := Vector2i(0, 29)
const TORSO_ROWS := Vector2i(28, 42)
const LEGS_ROWS := Vector2i(43, 55)
## Armas: [propuesta, colores que son del arma, rectángulo donde buscarlos].
const WEAPONS := {
	"sword": [1, ["202f4c", "9effe1", "471024", "ecba46", "bd5824"], Rect2i(15, 23, 8, 20)],
	"dagger": [3, ["20404c", "78ffb4"], Rect2i(17, 37, 6, 10)],
	"staff": [2, ["8c6038", "2a0e1c", "702e22", "0d2848", "3cf0dc"], Rect2i(14, 6, 12, 46)],
}
## Colores que no son del equipo sino del personaje de la propuesta: el pelo lila de E
## (cae sobre los hombros, en la banda del torso).
const NOT_GEAR := {4: ["c4b0f0", "937fc0", "f3ceff", "685c84", "aa50dc", "512079", "7b2eb0"]}
## Lo que no es de ninguna pieza de equipo: el orbe de E y el escudo de B (sin ranura).
const SKIP := {
	1: [Rect2i(36, 32, 6, 14)],
	4: [Rect2i(10, 24, 12, 10)],
}


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	var cards: Array[Image] = []
	for k in CARD_X.size():
		cards.append(_native(sheet, CARD_X[k]))
	var platform := _platform_mask(cards)
	var bg := cards[0].get_pixel(0, 0)
	# Colores de la loseta: los de sus bordes, lejos de los personajes (y la sombra).
	for j in range(39, SIZE.y):
		for i in range(0, 12) + range(48, SIZE.x):
			var c := cards[0].get_pixel(i, j)
			if not c.is_equal_approx(bg) and not _grass.any(func(g: Color) -> bool: return g.is_equal_approx(c)):
				_grass.append(c)
	var base := _clean(cards[0], platform, bg)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	base.save_png(ProjectSettings.globalize_path(OUT + "base.png"))
	var names := ["", "b", "c", "d", "e"]
	for k in range(1, 5):
		var other := _clean(cards[k], platform, bg)
		var weapon_px := _weapon_mask(other, k)
		for band in [["head", HEAD_ROWS], ["torso", TORSO_ROWS], ["legs", LEGS_ROWS]]:
			var layer := _diff_layer(base, other, band[1], weapon_px, k)
			layer.save_png(ProjectSettings.globalize_path(OUT + "%s_%s.png" % [band[0], names[k]]))
	for w in WEAPONS:
		var spec: Array = WEAPONS[w]
		var src := _clean(cards[int(spec[0])], platform, bg)
		var img := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var colors: Array = spec[1].map(func(h: String) -> Color: return Color(h))
		var r: Rect2i = spec[2]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := src.get_pixel(x, y)
				if c.a > 0.0 and _in(colors, c):
					img.set_pixel(x, y, c)
		img.save_png(ProjectSettings.globalize_path(OUT + "weapon_%s.png" % w))
	print("arte del héroe importado en %s" % OUT)
	quit()


## Una tarjeta a resolución real (un píxel por bloque de 5×5).
func _native(sheet: Image, x0: int) -> Image:
	var img := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for j in SIZE.y:
		for i in SIZE.x:
			var p := Vector2i(x0 + GRID.x + i * BLOCK + 2, TOP + GRID.y + j * BLOCK + 2)
			if p.x < sheet.get_width() and p.y < sheet.get_height():
				img.set_pixel(i, j, sheet.get_pixelv(p))
	return img


## La loseta y la sombra: lo que es igual en las cinco tarjetas de la fila 39 para abajo.
func _platform_mask(cards: Array[Image]) -> Dictionary:
	var mask := {}
	for j in range(39, SIZE.y):
		for i in SIZE.x:
			var c := cards[0].get_pixel(i, j)
			var same := true
			for k in range(1, cards.size()):
				if not cards[k].get_pixel(i, j).is_equal_approx(c):
					same = false
					break
			if same:
				mask[Vector2i(i, j)] = true
	return mask


func _clean(card: Image, platform: Dictionary, bg: Color) -> Image:
	var img := card.duplicate() as Image
	for j in SIZE.y:
		for i in SIZE.x:
			var c := img.get_pixel(i, j)
			if platform.has(Vector2i(i, j)) or c.is_equal_approx(bg) or _is_grass(c):
				img.set_pixel(i, j, Color(0, 0, 0, 0))
	return img


var _grass: Array[Color] = [Color("3f6c32")]   # (más los de los bordes de la loseta)


## Verdes y tierras de la loseta que asoman entre las piernas.
func _is_grass(c: Color) -> bool:
	return _grass.any(func(g: Color) -> bool: return g.is_equal_approx(c))


func _weapon_mask(img: Image, k: int) -> Dictionary:
	var mask := {}
	for w in WEAPONS:
		var spec: Array = WEAPONS[w]
		if int(spec[0]) != k:
			continue
		var colors: Array = spec[1].map(func(h: String) -> Color: return Color(h))
		var r: Rect2i = spec[2]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if img.get_pixel(x, y).a > 0.0 and _in(colors, img.get_pixel(x, y)):
					mask[Vector2i(x, y)] = true
	for r: Rect2i in SKIP.get(k, []):
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				mask[Vector2i(x, y)] = true
	return mask


## Lo que la propuesta cambia respecto al alumno en una banda de filas (sin sus armas).
func _diff_layer(base: Image, other: Image, rows: Vector2i, skip: Dictionary, k: int) -> Image:
	var img := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var not_gear: Array = NOT_GEAR.get(k, []).map(func(h: String) -> Color: return Color(h))
	for y in range(rows.x, mini(rows.y + 1, SIZE.y)):
		for x in SIZE.x:
			if skip.has(Vector2i(x, y)):
				continue
			var c := other.get_pixel(x, y)
			if rows.x > HEAD_ROWS.y - 2 and _in(not_gear, c):
				continue
			if c.a > 0.0 and not c.is_equal_approx(base.get_pixel(x, y)):
				img.set_pixel(x, y, c)
	return img


func _in(colors: Array, c: Color) -> bool:
	for k in colors:
		if c.is_equal_approx(k):
			return true
	return false
