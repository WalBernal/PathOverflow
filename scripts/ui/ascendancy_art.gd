class_name AscendancyArt
extends RefCounted
## Ilustración en pixel art de cada ascendencia (para el disco del panel de
## ascendencia): se pinta a 128×128 en una Image, con fondo degradado y tramado,
## y se escala sin filtro. Una escena por ascendencia, alusiva a su nombre.

const SIZE := 128
const C := 64.0   # centro

static var _cache := {}


## Textura de la ascendencia (en caché).
static func texture(asc_id: String) -> ImageTexture:
	if not _cache.has(asc_id):
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		var p := _Painter.new(img, hash(asc_id))
		_paint(p, asc_id)
		p.finish()
		_cache[asc_id] = ImageTexture.create_from_image(img)
	return _cache[asc_id]


static func _paint(p: _Painter, id: String) -> void:
	match id:
		"berserker_hotfix":   # Ingeniero de Guardia: rack en llamas de madrugada, luna y alarma
			p.gradient(Color("1a0a1e"), Color("5a1420"))
			p.stars(30, Color("f0d8e0"))
			p.circle(30, 28, 13, Color("f4e6c8"))
			p.circle(35, 25, 11, Color("2a0e26"))   # luna menguante
			p.rect(46, 52, 36, 62, Color("26222c"))
			for k in 6:
				p.rect(49, 56 + k * 9, 30, 6, Color("3a3442"))
				p.rect(51, 58 + k * 9, 3, 2, Color("ff4040") if k % 2 == 0 else Color("40ff70"))
			p.flames(64, 54, 26, 22)
			p.circle(96, 92, 7, Color("ff2a2a"))
			p.ring(96, 92, 10, 1, Color(1, 0.3, 0.3, 0.6))
			p.rect(84, 100, 24, 14, Color("1c1c20"))
			p.text_bars(87, 104, Color("ff6060"))   # pager con 3:00
		"guardian_firewall":   # Ciberseguridad: muro de ladrillos en llamas y escudo con candado
			p.gradient(Color("0a1426"), Color("1e3a64"))
			p.stars(20, Color("9ac8ff"))
			for row in 4:
				for col in 9:
					var x := col * 16 - (8 if row % 2 else 0)
					p.rect(x, 96 + row * 9, 15, 8, Color("8a3a2c").lerp(Color("b4543c"), ((col + row) % 3) / 3.0))
			p.flames(64, 96, 60, 18)
			p.shield(64, 62, 26, Color("3e7cd6"), Color("c8e0ff"))
			p.rect(56, 60, 16, 12, Color("e8c040"))
			p.ring(64, 58, 5, 2, Color("e8c040"))
			p.rect(63, 64, 2, 4, Color("3a2a10"))
		"gladiador_review":   # Revisor de Código: editor con líneas, una subrayada en rojo y una lupa
			p.gradient(Color("0c1410"), Color("16261c"))
			for k in 11:
				var w := 20 + (k * 37) % 50
				p.rect(18, 22 + k * 8, 6, 3, Color("4a6a56"))
				p.rect(28, 22 + k * 8, w, 3, [Color("6ad08a"), Color("d8b860"), Color("7ab0e8"), Color("c88ad8")][k % 4])
			p.rect(28, 76, 52, 1, Color("ff3a3a"))
			p.ring(76, 62, 18, 4, Color("d8d0b8"))
			p.circle(76, 62, 14, Color(0.8, 0.95, 1.0, 0.18))
			p.line(88, 75, 104, 92, Color("8a5a34"), 5)
			p.bug(74, 64, Color("ff5050"))
		"campeon_sprint":   # Scrum Master: tablero kanban y cronómetro
			p.gradient(Color("201608"), Color("4a3416"))
			p.rect(14, 22, 100, 70, Color("e8e0d0"))
			for col in 3:
				p.rect(16 + col * 33, 24, 31, 66, Color("d4ccbc"))
				for k in 3 - col % 2:
					p.rect(19 + col * 33, 30 + k * 18, 24, 14, [Color("f4d860"), Color("8ad0f0"), Color("f09ab0")][(col + k) % 3])
			p.chevrons(30, 104, Color("6ae07a"))
			p.circle(98, 98, 14, Color("e8e8e0"))
			p.ring(98, 98, 14, 2, Color("6a6a70"))
			p.line(98, 98, 98, 88, Color("2a2a30"), 2)
			p.line(98, 98, 106, 101, Color("d03a3a"), 2)
			p.rect(95, 80, 6, 4, Color("6a6a70"))
		"francotiradora_bugs":   # Ingeniera de Rendimiento: mira sobre un bug y velocímetro
			p.gradient(Color("081a1a"), Color("10343a"))
			p.stars(14, Color("7ae0d0"))
			for r in [42, 30, 18]:
				p.ring(64, 60, r, 1, Color(0.5, 1.0, 0.9, 0.45))
			p.line(64, 12, 64, 108, Color(0.5, 1.0, 0.9, 0.6), 1)
			p.line(16, 60, 112, 60, Color(0.5, 1.0, 0.9, 0.6), 1)
			p.bug(64, 60, Color("ff6040"))
			p.ring(64, 60, 6, 1, Color("ff3030"))
			p.arc_gauge(64, 112, 20, Color("e8d060"))
		"rastreadora_leaks":   # Ingeniera de Depuración: telaraña con un bug y una tubería que gotea
			p.gradient(Color("0e1208"), Color("26301a"))
			for k in 8:
				var a := TAU * k / 8.0
				p.line(60, 58, 60 + cos(a) * 52, 58 + sin(a) * 52, Color(0.85, 0.9, 0.8, 0.5), 1)
			for r in [12, 24, 36, 48]:
				p.ring(60, 58, r, 1, Color(0.85, 0.9, 0.8, 0.35))
			p.bug(60, 58, Color("b0e050"))
			p.rect(84, 14, 40, 8, Color("6a7a80"))
			p.rect(84, 14, 8, 18, Color("6a7a80"))
			for k in 4:
				p.circle(88, 40 + k * 16, 3 - k * 0.4, Color("7af07a"))
		"asesina_sesiones":   # Red Team: figura encapuchada, ojos que brillan, llave robada y binario rojo
			p.gradient(Color("100608"), Color("2a0c12"))
			p.binary_rain(Color(1, 0.25, 0.25, 0.5))
			p.poly([Vector2(64, 22), Vector2(94, 56), Vector2(100, 116), Vector2(28, 116), Vector2(34, 56)], Color("6a2a34"))   # borde iluminado
			p.poly([Vector2(64, 25), Vector2(91, 57), Vector2(96, 116), Vector2(32, 116), Vector2(37, 57)], Color("3a2a3e"))
			p.poly([Vector2(64, 30), Vector2(80, 50), Vector2(48, 50)], Color("4a3850"))   # pliegue de la capucha
			p.circle(64, 50, 15, Color("0a080c"))
			p.rect(56, 48, 5, 2, Color("ff3a3a"))
			p.rect(67, 48, 5, 2, Color("ff3a3a"))
			p.ring(92, 90, 6, 2, Color("e8c040"))
			p.rect(97, 89, 14, 3, Color("e8c040"))
			p.rect(106, 92, 2, 4, Color("e8c040"))
		"saboteadora":   # Analista de Malware: virus verde con calavera
			p.gradient(Color("040e08"), Color("0e2a14"))
			p.binary_rain(Color(0.3, 1, 0.4, 0.35))
			for k in 10:
				var a := TAU * k / 10.0
				p.line(64, 62, 64 + cos(a) * 40, 62 + sin(a) * 40, Color("3ac060"), 3)
				p.circle(64 + cos(a) * 42, 62 + sin(a) * 42, 4, Color("7af090"))
			p.circle(64, 62, 26, Color("2a9a4a"))
			p.circle(64, 58, 13, Color("e8f0e0"))
			p.rect(56, 66, 16, 8, Color("e8f0e0"))
			p.circle(59, 57, 3, Color("10301a"))
			p.circle(69, 57, 3, Color("10301a"))
			for k in 3:
				p.rect(58 + k * 5, 70, 2, 4, Color("10301a"))
		"archimago_recursivo":   # Ingeniero de ML: red neuronal brillante
			p.gradient(Color("0c0a22"), Color("241a52"))
			p.stars(24, Color("c8b8ff"))
			var layers := [[40, 64, 88], [30, 52, 76, 98], [40, 64, 88], [64]]
			for l in layers.size() - 1:
				for a in layers[l]:
					for b in layers[l + 1]:
						p.line(24 + l * 28, a, 24 + (l + 1) * 28, b, Color(0.6, 0.5, 1.0, 0.35), 1)
			for l in layers.size():
				for y in layers[l]:
					p.circle(24 + l * 28, y, 6, Color("8a6af0"))
					p.circle(24 + l * 28, y, 3, Color("e0d8ff"))
			p.spiral(104, 64, Color("f0c860"))
		"elementalista_so":   # Analista de Big Data: bases de datos apiladas y tres orbes elementales
			p.gradient(Color("0a1218"), Color("1c2c3a"))
			for k in 3:
				var y := 90 - k * 20
				p.rect(44, y - 8, 40, 16, Color("5a6a80"))
				p.ellipse(64, y + 8, 20, 6, Color("4a5a70"))
				p.ellipse(64, y - 8, 20, 6, Color("8a9ab0"))
			p.circle(28, 44, 9, Color("ff7a2a"))
			p.circle(28, 44, 5, Color("ffd060"))
			p.circle(100, 44, 9, Color("6ad0ff"))
			p.circle(100, 44, 5, Color("e0f8ff"))
			p.circle(64, 22, 9, Color("c8a0ff"))
			p.line(60, 16, 66, 22, Color("fff0a0"), 2)
			p.line(66, 22, 61, 28, Color("fff0a0"), 2)
		"hierofante_docs":   # Ingeniero en Robótica: cabeza de robot con engranajes
			p.gradient(Color("14100a"), Color("3a2c16"))
			p.gear(32, 34, 16, Color("8a7a5a"))
			p.gear(100, 96, 20, Color("6a5c40"))
			p.rect(38, 46, 52, 44, Color("a8b0b8"))
			p.rect(38, 46, 52, 4, Color("d8e0e8"))
			p.rect(44, 58, 40, 12, Color("1a2a34"))
			p.rect(48, 62, 10, 4, Color("40e0ff"))
			p.rect(70, 62, 10, 4, Color("40e0ff"))
			p.rect(52, 78, 24, 4, Color("5a6068"))
			p.line(64, 46, 64, 32, Color("a8b0b8"), 2)
			p.circle(64, 30, 4, Color("ff4040"))
			p.rect(30, 60, 8, 16, Color("7a8088"))
			p.rect(90, 60, 8, 16, Color("7a8088"))
		"inquisidor_linter":   # SRE: panel de monitoreo con latido y campana de alerta
			p.gradient(Color("0a0e14"), Color("18222e"))
			for k in 8:
				p.line(16, 28 + k * 10, 112, 28 + k * 10, Color(0.4, 0.6, 0.8, 0.15), 1)
				p.line(16 + k * 13, 28, 16 + k * 13, 98, Color(0.4, 0.6, 0.8, 0.15), 1)
			var pts := [Vector2(16, 66), Vector2(40, 66), Vector2(46, 56), Vector2(52, 78), Vector2(58, 36), Vector2(64, 86), Vector2(70, 66), Vector2(112, 66)]
			for k in pts.size() - 1:
				p.line(pts[k].x, pts[k].y, pts[k + 1].x, pts[k + 1].y, Color("ff6a3a"), 2)
			for k in 6:
				p.rect(22 + k * 15, 112 - k * 2, 10, 4 + k * 2, Color("4ad07a") if k < 5 else Color("e8c040"))
			p.poly([Vector2(98, 14), Vector2(106, 26), Vector2(108, 34), Vector2(88, 34), Vector2(90, 26)], Color("e8c040"))
			p.circle(98, 37, 3, Color("e8c040"))
		"arquitecto_soluciones":   # Arquitecto: plano azul con cajas, flechas y una nube
			p.gradient(Color("0c2a5a"), Color("1a4a8a"))
			for k in 16:
				p.line(0, k * 8, 128, k * 8, Color(1, 1, 1, 0.08), 1)
				p.line(k * 8, 0, k * 8, 128, Color(1, 1, 1, 0.08), 1)
			for b: Rect2 in [Rect2(20, 30, 26, 18), Rect2(82, 30, 26, 18), Rect2(51, 70, 26, 18), Rect2(20, 96, 26, 14), Rect2(82, 96, 26, 14)]:
				p.rect_outline(int(b.position.x), int(b.position.y), int(b.size.x), int(b.size.y), Color("e8f0ff"))
			p.line(46, 39, 82, 39, Color("e8f0ff"), 1)
			p.line(33, 48, 58, 70, Color("e8f0ff"), 1)
			p.line(95, 48, 70, 70, Color("e8f0ff"), 1)
			p.line(58, 88, 33, 96, Color("e8f0ff"), 1)
			p.line(70, 88, 95, 96, Color("e8f0ff"), 1)
			p.circle(56, 16, 7, Color("e8f0ff"))
			p.circle(66, 13, 9, Color("e8f0ff"))
			p.circle(76, 17, 6, Color("e8f0ff"))
		"devops_integral":   # Tech Lead: organigrama con corona y bucle infinito de CI/CD
			p.gradient(Color("0a1420"), Color("1a3040"))
			p.infinity(64, 100, Color("4ad0c0"))
			p.line(64, 40, 30, 66, Color("c8d8e0"), 2)
			p.line(64, 40, 64, 66, Color("c8d8e0"), 2)
			p.line(64, 40, 98, 66, Color("c8d8e0"), 2)
			p.person(64, 32, Color("e8c040"))
			p.poly([Vector2(56, 18), Vector2(60, 22), Vector2(64, 16), Vector2(68, 22), Vector2(72, 18), Vector2(71, 26), Vector2(57, 26)], Color("ffd84a"))
			for x in [30, 64, 98]:
				p.person(x, 72, Color("6aa8e0"))
		_:
			p.gradient(Color("141018"), Color("2a2230"))


## Pintor de pixel art sobre una Image (formas simples y tramado).
class _Painter:
	var img: Image
	var rng := RandomNumberGenerator.new()

	func _init(p_img: Image, seed: int) -> void:
		img = p_img
		rng.seed = seed

	func px(x: int, y: int, col: Color) -> void:
		if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
			return
		if col.a >= 0.999:
			img.set_pixel(x, y, col)
		else:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(col, 1.0), col.a))

	func gradient(top: Color, bottom: Color) -> void:
		# Degradado en bandas con tramado ordenado entre banda y banda (pixel art).
		for y in SIZE:
			var t := y / float(SIZE - 1)
			var band := floorf(t * 8.0) / 8.0
			var frac := t * 8.0 - floorf(t * 8.0)
			for x in SIZE:
				var bayer: float = [0.0, 0.5, 0.75, 0.25][(x % 2) + 2 * (y % 2)]
				var b := band + (0.125 if frac > bayer else 0.0)
				img.set_pixel(x, y, top.lerp(bottom, clampf(b, 0.0, 1.0)))

	func rect(x: float, y: float, w: float, h: float, col: Color) -> void:
		for yy in range(int(y), int(y + h)):
			for xx in range(int(x), int(x + w)):
				px(xx, yy, col)

	func rect_outline(x: int, y: int, w: int, h: int, col: Color) -> void:
		rect(x, y, w, 1, col)
		rect(x, y + h - 1, w, 1, col)
		rect(x, y, 1, h, col)
		rect(x + w - 1, y, 1, h, col)

	func circle(cx: float, cy: float, r: float, col: Color) -> void:
		for yy in range(int(cy - r - 1), int(cy + r + 2)):
			for xx in range(int(cx - r - 1), int(cx + r + 2)):
				if Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length() <= r:
					px(xx, yy, col)

	func ellipse(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
		for yy in range(int(cy - ry - 1), int(cy + ry + 2)):
			for xx in range(int(cx - rx - 1), int(cx + rx + 2)):
				if pow((xx + 0.5 - cx) / rx, 2) + pow((yy + 0.5 - cy) / ry, 2) <= 1.0:
					px(xx, yy, col)

	func ring(cx: float, cy: float, r: float, th: float, col: Color) -> void:
		for yy in range(int(cy - r - th - 1), int(cy + r + th + 2)):
			for xx in range(int(cx - r - th - 1), int(cx + r + th + 2)):
				var d := Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length()
				if d <= r + th * 0.5 and d >= r - th * 0.5:
					px(xx, yy, col)

	func line(x0: float, y0: float, x1: float, y1: float, col: Color, th := 1) -> void:
		var steps := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
		for k in steps + 1:
			var t := k / float(steps)
			var x := lerpf(x0, x1, t)
			var y := lerpf(y0, y1, t)
			if th <= 1:
				px(int(x), int(y), col)
			else:
				rect(x - th / 2.0, y - th / 2.0, th, th, col)

	func poly(points: Array, col: Color) -> void:
		var pts := PackedVector2Array(points)
		for yy in SIZE:
			for xx in SIZE:
				if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), pts):
					px(xx, yy, col)

	func stars(n: int, col: Color) -> void:
		for k in n:
			px(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE / 2), Color(col, rng.randf_range(0.4, 1.0)))

	func binary_rain(col: Color) -> void:
		for k in 14:
			var x := rng.randi_range(2, SIZE - 4)
			var y0 := rng.randi_range(0, SIZE)
			for j in rng.randi_range(4, 10):
				var y := (y0 + j * 6) % SIZE
				if rng.randf() < 0.5:
					rect(x, y, 1, 4, col)   # «1»
				else:
					rect_outline(x - 1, y, 3, 4, col)   # «0»

	func flames(cx: float, base_y: float, half_w: float, h: float) -> void:
		for k in int(half_w):
			var x := cx - half_w + k * 2.0
			var fh := h * (0.5 + 0.5 * absf(sin(k * 1.7))) * (1.0 - absf(x - cx) / (half_w * 1.4))
			rect(x, base_y - fh, 2, fh, Color("ff6a1a"))
			rect(x, base_y - fh * 0.6, 2, fh * 0.6, Color("ffb030"))
			rect(x, base_y - fh * 0.25, 2, fh * 0.25, Color("fff0a0"))

	func shield(cx: float, cy: float, r: float, col: Color, edge: Color) -> void:
		var pts := [Vector2(cx - r, cy - r), Vector2(cx + r, cy - r), Vector2(cx + r, cy + r * 0.2), Vector2(cx, cy + r * 1.2), Vector2(cx - r, cy + r * 0.2)]
		poly(pts, edge)
		var inner := []
		for q: Vector2 in pts:
			inner.append(Vector2(cx, cy) + (q - Vector2(cx, cy)) * 0.85)
		poly(inner, col)

	func bug(cx: float, cy: float, col: Color) -> void:
		ellipse(cx, cy, 6, 8, col)
		circle(cx, cy - 9, 4, col.darkened(0.2))
		line(cx, cy - 8, cx, cy + 8, col.darkened(0.4), 1)
		for k in 3:
			var y := cy - 4 + k * 4
			line(cx - 6, y, cx - 11, y - 2 + k * 2, col.darkened(0.3), 1)
			line(cx + 6, y, cx + 11, y - 2 + k * 2, col.darkened(0.3), 1)
		line(cx - 2, cy - 12, cx - 5, cy - 16, col, 1)
		line(cx + 2, cy - 12, cx + 5, cy - 16, col, 1)

	func text_bars(x: int, y: int, col: Color) -> void:
		# «3:00» en dígitos de 3×5.
		for seg in [[0, 0, 3, 1], [2, 0, 1, 5], [0, 2, 3, 1], [0, 4, 3, 1], [4, 1, 1, 1], [4, 3, 1, 1],
				[6, 0, 3, 1], [6, 4, 3, 1], [6, 0, 1, 5], [8, 0, 1, 5], [10, 0, 3, 1], [10, 4, 3, 1], [10, 0, 1, 5], [12, 0, 1, 5]]:
			rect(x + seg[0] * 1.4, y + seg[1], seg[2] * 1.4, seg[3], col)

	func chevrons(x: int, y: int, col: Color) -> void:
		for k in 4:
			var ox := x + k * 12
			line(ox, y - 6, ox + 6, y, col, 2)
			line(ox + 6, y, ox, y + 6, col, 2)

	func arc_gauge(cx: float, cy: float, r: float, col: Color) -> void:
		for k in 20:
			var a := PI + PI * k / 19.0
			px(int(cx + cos(a) * r), int(cy + sin(a) * r), col)
		line(cx, cy, cx + cos(PI * 1.8) * r * 0.9, cy + sin(PI * 1.8) * r * 0.9, Color("ff4040"), 2)

	func spiral(cx: float, cy: float, col: Color) -> void:
		for k in 120:
			var a := k * 0.18
			var r := k * 0.16
			px(int(cx + cos(a) * r), int(cy + sin(a) * r), col)

	func gear(cx: float, cy: float, r: float, col: Color) -> void:
		for k in 8:
			var a := TAU * k / 8.0
			rect(cx + cos(a) * r - 3, cy + sin(a) * r - 3, 6, 6, col)
		circle(cx, cy, r, col)
		circle(cx, cy, r * 0.4, col.darkened(0.5))

	func person(cx: float, cy: float, col: Color) -> void:
		circle(cx, cy - 6, 5, col.lightened(0.2))
		ellipse(cx, cy + 6, 9, 7, col)

	func infinity(cx: float, cy: float, col: Color) -> void:
		for k in 160:
			var t := TAU * k / 160.0
			var d := 1.0 + sin(t) * sin(t)
			px(int(cx + 30 * cos(t) / d), int(cy + 30 * sin(t) * cos(t) / d), col)
			px(int(cx + 30 * cos(t) / d), int(cy + 1 + 30 * sin(t) * cos(t) / d), col)

	## Recorta en círculo y oscurece el borde (viñeta).
	func finish() -> void:
		for y in SIZE:
			for x in SIZE:
				var d := Vector2(x + 0.5 - C, y + 0.5 - C).length() / C
				if d > 1.0:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
				elif d > 0.7:
					var col := img.get_pixel(x, y)
					var dark := (d - 0.7) / 0.3
					# Viñeta en tres pasos (sin degradado suave: pixel art).
					img.set_pixel(x, y, col.darkened(floorf(dark * 3.0) / 3.0 * 0.6))
