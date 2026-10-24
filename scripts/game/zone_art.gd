class_name ZoneArt
extends RefCounted
## Suelos en pixel art para las zonas (por estilo): una baldosa de 128×128 que se
## repite sin costuras, hecha con ruido periódico, una paleta corta con tramado
## y detalles propios (hierba, losas, lodo, ladrillo, placas de metal...).
## Cada texel ocupa TEXEL px del mundo.

const SIZE := 128
const TEXEL := 2.0

static var _cache := {}


static func has_ground(style: String) -> bool:
	return style in ["sandbox", "camp", "forest", "ruins", "swamp", "catacombs", "servers", "boss"]


## Tamaño de la baldosa en el mundo (para las UV).
static func tile_world() -> float:
	return SIZE * TEXEL


static func ground(style: String) -> ImageTexture:
	if not _cache.has(style):
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(style) % 100000
		_paint(img, style, rng)
		_cache[style] = ImageTexture.create_from_image(img)
	return _cache[style]


static func _paint(img: Image, style: String, rng: RandomNumberGenerator) -> void:
	match style:
		"forest":
			_noise_fill(img, rng, [Color("142018"), Color("17251a"), Color("1a2a1c"), Color("1e301f")], 4)
			for k in 90:   # briznas de hierba
				var x := rng.randi_range(0, SIZE - 1)
				var y := rng.randi_range(0, SIZE - 1)
				var c: Color = [Color("26402a"), Color("2c4a2c"), Color("223a26")][k % 3]
				_px(img, x, y, c)
				_px(img, x, y - 1, c.lightened(0.1))
				if k % 4 == 0:
					_px(img, x + 1, y - 2, c.lightened(0.2))
			for k in 6:   # hojas secas y florecitas de colores de cable
				_px(img, rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), [Color("7a5a2e"), Color("c84b4b"), Color("4b8bd6"), Color("d9a441")][k % 4])
			for k in 3:   # piedritas
				var x := rng.randi_range(2, SIZE - 3)
				var y := rng.randi_range(2, SIZE - 3)
				_px(img, x, y, Color("4a4a44"))
				_px(img, x + 1, y, Color("5a5a52"))
		"ruins":
			_noise_fill(img, rng, [Color("2a241c"), Color("302a20"), Color("363024")], 6)
			# Losas irregulares: juntas oscuras y borde iluminado arriba.
			var rows := [0, 14, 30, 44, 64, 78, 94, 108]
			for r in rows.size():
				var y0: int = rows[r]
				var y1: int = rows[(r + 1) % rows.size()] if r < rows.size() - 1 else SIZE
				for x in SIZE:
					_px(img, x, y0, Color("1a1610"))
					_px(img, x, y0 + 1, Color("443c2e"))
				var off := (r * 23) % 20
				for cut in range(off, SIZE + off, 21 + r * 2):
					for y in range(y0, y1):
						_px(img, cut % SIZE, y, Color("1a1610"))
			for k in 12:   # musgo y grietas
				var x := rng.randi_range(0, SIZE - 1)
				var y := rng.randi_range(0, SIZE - 1)
				for j in 4:
					_px(img, x + j, y + (j % 2), Color("1c160e"))
				_px(img, x + 2, y - 1, Color("3e5a2a"))
		"swamp":
			_noise_fill(img, rng, [Color("141a16"), Color("1a2219"), Color("202a1c"), Color("26201e")], 10)
			for k in 8:   # charcos de agua oscura con brillo
				var cx := rng.randi_range(6, SIZE - 7)
				var cy := rng.randi_range(6, SIZE - 7)
				var rx := rng.randi_range(4, 7)
				for y in range(-3, 4):
					for x in range(-rx, rx + 1):
						if float(x * x) / (rx * rx) + float(y * y) / 9.0 <= 1.0:
							_px(img, cx + x, cy + y, Color("101a20"))
				if k == 0:
					_px(img, cx - 1, cy - 1, Color("2a4250"))
			for k in 70:   # algas y burbujas moradas (memory leaks)
				_px(img, rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), Color("3a4a22") if k % 3 else Color("5a3a6a"))
		"catacombs":
			_noise_fill(img, rng, [Color("18161c"), Color("1e1b22"), Color("24202a")], 6)
			# Losas grandes de piedra 16×16 con junta y bisel.
			for y in SIZE:
				for x in SIZE:
					var ox := x + (8 if (y / 16) % 2 else 0)
					if y % 16 == 0 or ox % 16 == 0:
						_px(img, x, y, Color("0e0c10"))
					elif y % 16 == 1 or ox % 16 == 1:
						_px(img, x, y, Color("2e2a34"))
			# Un hueso por baldosa, sin brillo (si no, el suelo parece lleno de rayitas).
			var bx := rng.randi_range(4, SIZE - 8)
			var by := rng.randi_range(4, SIZE - 4)
			for j in 4:
				_px(img, bx + j, by, Color("6e685e"))
			_px(img, bx - 1, by - 1, Color("7a746a"))
			_px(img, bx + 4, by + 1, Color("7a746a"))
		"servers":
			_noise_fill(img, rng, [Color("161a20"), Color("1a1e26"), Color("1e232c")], 4)
			# Placas de 32×32 con remaches y una rejilla de ventilación.
			for y in SIZE:
				for x in SIZE:
					if y % 32 == 0 or x % 32 == 0:
						_px(img, x, y, Color("0c0e12"))
					elif y % 32 == 1 or x % 32 == 1:
						_px(img, x, y, Color("2c323e"))
			for corner in [Vector2i(3, 3), Vector2i(28, 3), Vector2i(3, 28), Vector2i(28, 28)]:
				for q in [Vector2i(0, 0), Vector2i(32, 0), Vector2i(0, 32), Vector2i(32, 32)]:
					_px(img, corner.x + q.x, corner.y + q.y, Color("4a5260"))
			for k in 6:   # una rejilla de ventilación
				for x in range(70, 90):
					_px(img, x, 72 + k * 3, Color("0a0c10"))
			for x in range(0, SIZE, 2):   # pista de cable con LED
				_px(img, x, 18, Color("22303a"))
			_px(img, 20, 18, Color("40e0a0"))
		"boss":
			_noise_fill(img, rng, [Color("1a0e10"), Color("221214"), Color("2a1618")], 6)
			# Basalto con grietas al rojo.
			for k in 3:
				var x := rng.randi_range(0, SIZE - 1)
				var y := rng.randi_range(0, SIZE - 1)
				for j in 18:
					x += rng.randi_range(0, 1)
					y += rng.randi_range(-1, 1)
					_px(img, x, y, Color("5a1810") if j % 4 else Color("a03818"))
		"camp":
			_noise_fill(img, rng, [Color("2a2018"), Color("2e2319"), Color("32271c"), Color("362a1e")], 4)
			for k in 60:
				_px(img, rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), Color("4a3a2a") if k % 2 else Color("221a12"))
			for k in 26:   # hierba en la tierra
				var x := rng.randi_range(0, SIZE - 1)
				var y := rng.randi_range(0, SIZE - 1)
				_px(img, x, y, Color("3a4a26"))
				_px(img, x, y - 1, Color("4a5a2e"))
		"sandbox":
			_noise_fill(img, rng, [Color("18202a"), Color("1c2630"), Color("202c38")], 5)
			for i in SIZE:   # rejilla brillante cada 32 texels
				_px(img, i, 0, Color("2a4a6a"))
				_px(img, 0, i, Color("2a4a6a"))
				_px(img, i, 32, Color("223a52"))
				_px(img, 32, i, Color("223a52"))
			for k in 6:
				_px(img, rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), Color("4a8ac8"))


## Relleno con ruido de valor periódico (sin costuras) cuantizado a la paleta
## con tramado ordenado.
static func _noise_fill(img: Image, rng: RandomNumberGenerator, palette: Array, cells: int) -> void:
	var grid := []
	for i in cells * cells:
		grid.append(rng.randf())
	var at := func(gx: int, gy: int) -> float: return grid[posmod(gx, cells) + posmod(gy, cells) * cells]
	var bayer := [0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0]
	for y in SIZE:
		for x in SIZE:
			var fx := float(x) * cells / SIZE
			var fy := float(y) * cells / SIZE
			var ix := int(fx)
			var iy := int(fy)
			var tx := smoothstep(0.0, 1.0, fx - ix)
			var ty := smoothstep(0.0, 1.0, fy - iy)
			var v: float = lerpf(lerpf(at.call(ix, iy), at.call(ix + 1, iy), tx), lerpf(at.call(ix, iy + 1), at.call(ix + 1, iy + 1), tx), ty)
			v += (float(bayer[(x % 4) + (y % 4) * 4]) / 16.0 - 0.5) * 0.35
			img.set_pixel(x, y, palette[clampi(int(v * palette.size()), 0, palette.size() - 1)])


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, SIZE), posmod(y, SIZE), c)
