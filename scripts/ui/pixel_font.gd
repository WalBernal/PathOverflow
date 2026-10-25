class_name PixelFont
## Fuente de píxeles para títulos y números (T76): mayúsculas de 5×7 con tildes,
## Ñ y Ü, cifras y signos, dibujadas aquí mismo como cuadrículas y montadas en un
## FontFile de mapa de bits. Celda de 10 px de alto (2 de tilde, 7 de letra y 1
## por debajo): a 10, 20 o 30 px de tamaño se ve con píxeles enteros. Solo tiene
## mayúsculas: quien la usa pasa el texto por to_upper() (UiStyle.pixel_label).

const CELL_H := 10
const ASCENT := 9
const ACCENT_ROWS := 2
const SPACE_ADVANCE := 4

## Glifo: 7 filas (de la línea de mayúsculas a la base); "#" = píxel encendido.
const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
	".": [".", ".", ".", ".", ".", ".", "#"],
	",": [".", ".", ".", ".", ".", "#", "#"],
	":": [".", ".", "#", ".", ".", "#", "."],
	";": [".", ".", "#", ".", ".", "#", "#"],
	"!": ["#", "#", "#", "#", "#", ".", "#"],
	"¡": ["#", ".", "#", "#", "#", "#", "#"],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"¿": ["..#..", ".....", "..#..", ".#...", "#....", "#...#", ".###."],
	"-": ["...", "...", "...", "###", "...", "...", "..."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
	"·": [".", ".", ".", "#", ".", ".", "."],
	"'": ["#", "#", ".", ".", ".", ".", "."],
	"\"": ["#.#", "#.#", "...", "...", "...", "...", "..."],
	"«": [".....", "..#.#", ".#.#.", "#.#..", ".#.#.", "..#.#", "....."],
	"»": [".....", "#.#..", ".#.#.", "..#.#", ".#.#.", "#.#..", "....."],
	"×": [".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "....."],
	"=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
	"#": [".#.#.", "#####", ".#.#.", ".#.#.", ".#.#.", "#####", ".#.#."],
}
## Letras con tilde o diéresis: base + dos filas encima.
const ACCENTED := {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "Ñ": "N"}

static var _font: FontFile


## Las dos filas de encima de la letra para la tilde, la diéresis o la virgulilla.
static func _accent_rows(ch: String, width: int) -> Array:
	var pad := func(s: String) -> String: return s.rpad(width, ".").substr(0, width)
	match ch:
		"Ü":
			return [pad.call(""), pad.call(".#.#.")]
		"Ñ":
			return [pad.call(".##.#"), pad.call("#.##.")]
		"Í":
			return [pad.call("..#"), pad.call(".#.")]
	return [pad.call("...#."), pad.call("..#..")]


## Filas completas (CELL_H) de un carácter, o [] si la fuente no lo tiene.
static func rows(ch: String) -> Array:
	var base := String(ACCENTED.get(ch, ch))
	if not GLYPHS.has(base):
		return []
	var body: Array = GLYPHS[base]
	var width := String(body[0]).length()
	var top: Array = _accent_rows(ch, width) if ACCENTED.has(ch) else [".".repeat(width), ".".repeat(width)]
	return top + body + [".".repeat(width)]


## La fuente (se monta una vez).
static func font() -> FontFile:
	if _font:
		return _font
	var chars: Array = GLYPHS.keys() + ACCENTED.keys()
	var total_w := 0
	for ch in chars:
		total_w += String(rows(ch)[0]).length() + 1
	var img := Image.create(total_w, CELL_H, false, Image.FORMAT_RGBA8)
	var f := FontFile.new()
	f.fixed_size = CELL_H
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	var sz := Vector2i(CELL_H, 0)
	var x := 0
	var placed := {}
	for ch in chars:
		var r := rows(ch)
		var w := String(r[0]).length()
		for y in CELL_H:
			for i in w:
				if String(r[y])[i] == "#":
					img.set_pixel(x + i, y, Color.WHITE)
		placed[ch] = [x, w]
		x += w + 1
	f.set_texture_image(0, sz, 0, img)
	for ch in placed:
		var code := String(ch).unicode_at(0)
		var gx: int = placed[ch][0]
		var gw: int = placed[ch][1]
		f.set_glyph_advance(0, CELL_H, code, Vector2(gw + 1, 0))
		f.set_glyph_offset(0, sz, code, Vector2(0, -ASCENT))
		f.set_glyph_size(0, sz, code, Vector2(gw, CELL_H))
		f.set_glyph_uv_rect(0, sz, code, Rect2(gx, 0, gw, CELL_H))
		f.set_glyph_texture_idx(0, sz, code, 0)
	var space := " ".unicode_at(0)
	f.set_glyph_advance(0, CELL_H, space, Vector2(SPACE_ADVANCE, 0))
	f.set_glyph_size(0, sz, space, Vector2.ZERO)
	f.set_cache_ascent(0, CELL_H, ASCENT)
	f.set_cache_descent(0, CELL_H, CELL_H - ASCENT)
	f.fallbacks = [ThemeDB.fallback_font]   # lo que no tenga (símbolos raros), con la fuente normal
	_font = f
	return f


## ¿Se puede escribir todo `text` (en mayúsculas) con esta fuente?
static func supports(text: String) -> bool:
	for ch in text.to_upper():
		if ch != " " and rows(ch).is_empty():
			return false
	return true
