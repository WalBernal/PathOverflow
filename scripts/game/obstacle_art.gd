class_name ObstacleArt
## Obstáculos en pixel art (Acto I y, desde T60, los de los actos II-IV): cada tipo se pinta una vez en una imagen
## con píxeles de PIX unidades del mundo (la rejilla del filtro), con contorno
## oscuro, luz arriba a la izquierda y sombra abajo a la derecha (la misma luz
## que el suelo), y se guarda por tipo, tamaño y variante. Zone la dibuja encima
## de su sombra; lo que se anima (LED de los racks) va aparte.

const PIX := 2.0
## Tipos que se dibujan así.
const KINDS := ["rock", "crate", "monitor", "cable_tree", "pillar", "rubble", "dead_tree", "tomb", "rack", "cable_coil",
	"piston", "heat_sink", "barrel", "capacitor", "chip_die", "ice_block"]
const VARIANTS := 3
const OUTLINE := Color("120f16")
const LIGHT := 0.18
const SHADE := 0.28

static var _cache: Dictionary = {}


## {texture, offset}: la textura y dónde va su esquina respecto al centro del obstáculo.
static func sprite(kind: String, radius: float, seed_value: int) -> Dictionary:
	var size_key := maxi(4, roundi(radius / 4.0) * 4)
	var key := "%s:%d:%d" % [kind, size_key, posmod(seed_value, VARIANTS)]
	if not _cache.has(key):
		_cache[key] = _paint(kind, float(size_key), posmod(seed_value, VARIANTS))
	return _cache[key]


static func cached_count() -> int:
	return _cache.size()


## Pinta el tipo en una imagen. El centro del obstáculo cae a 62 % de la altura:
## lo alto (árboles, lápidas, racks) sobresale hacia arriba.
static func _paint(kind: String, r: float, variant: int) -> Dictionary:
	var w := int(ceil(r * 2.8 / PIX)) + 4
	var h := int(ceil(r * 3.0 / PIX)) + 4
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w / 2.0, h * 0.62)
	var cv := _Canvas.new(img, c)
	match kind:
		"rock":
			var pts := PackedVector2Array()
			for k in 9:
				var rr := r * (0.8 + 0.2 * sin(variant * 2.3 + k * 1.7))
				pts.append(Vector2.from_angle(TAU * k / 9.0) * Vector2(rr, rr * 0.8))
			cv.poly(pts, Color("5a5660"))
			cv.circle(Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color("75707c"))
			cv.circle(Vector2(r * 0.25, r * 0.15), r * 0.12, Color("4a4650"))   # una grieta
		"crate":
			var box := Rect2(-Vector2(r, r) * 0.8, Vector2(r, r) * 1.6)
			cv.rect(box, Color("7a5a3a"))
			cv.line(box.position, box.end, maxf(2.0, r * 0.12), Color("4a3422"))
			cv.line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), maxf(2.0, r * 0.12), Color("4a3422"))
			cv.frame(box, maxf(2.0, r * 0.12), Color("4a3422"))
		"monitor":
			cv.rect(Rect2(-Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.5)), Color("b8b8b0"))
			cv.rect(Rect2(-Vector2(r * 0.8, r * 0.6), Vector2(r * 1.6, r * 1.1)), Color("1a2a4a"))
			# Cara triste en la pantalla.
			cv.rect(Rect2(Vector2(-r * 0.35, -r * 0.3), Vector2(PIX * 2, PIX * 2)), Color("7fb8e0"))
			cv.rect(Rect2(Vector2(r * 0.2, -r * 0.3), Vector2(PIX * 2, PIX * 2)), Color("7fb8e0"))
			cv.line(Vector2(-r * 0.35, r * 0.25), Vector2(r * 0.35, r * 0.25), PIX, Color("7fb8e0"))
			cv.rect(Rect2(Vector2(-r * 0.3, r * 0.7), Vector2(r * 0.6, r * 0.2)), Color("8a8a84"))   # pie
		"cable_tree":
			cv.line(Vector2(0, r * 0.4), Vector2(0, -r * 0.8), maxf(4.0, r * 0.25), Color("2a2a30"))
			var colors := [Color("c84b4b"), Color("4b8bd6"), Color("5cb85c"), Color("d9a441"), Color("8a8a8a")]
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * (0.45 + 0.05 * variant)
				var tip := Vector2(0, -r * 0.6) + Vector2.from_angle(a) * r
				cv.line(Vector2(0, -r * 0.5), tip, maxf(2.0, r * 0.1), colors[k])
				cv.circle(tip, maxf(2.0, r * 0.12), colors[k])
		"pillar":
			cv.rect(Rect2(Vector2(-r * 0.8, -r * 1.2), Vector2(r * 1.6, r * 1.7)), Color("807868"))
			cv.ellipse(Vector2(0, r * 0.5), Vector2(r * 0.8, r * 0.35), Color("6a6458"))
			cv.ellipse(Vector2(0, -r * 1.2), Vector2(r * 0.9, r * 0.35), Color("968e7c"))   # capitel
			for k in 3:
				cv.line(Vector2(-r * 0.45 + k * r * 0.45, -r * 1.0), Vector2(-r * 0.45 + k * r * 0.45, r * 0.4), PIX, Color("6a6458"))
		"rubble":
			for k in 5:
				var q := Vector2.from_angle(variant * 1.3 + k * 2.1) * r * 0.5
				cv.circle(q, r * (0.25 + 0.08 * (k % 3)), Color("6a6458").darkened(0.1 * k))
		"dead_tree":
			var bark := Color("3a2e26")
			cv.line(Vector2(0, r * 0.4), Vector2(0, -r), maxf(4.0, r * 0.22), bark)
			cv.line(Vector2(0, -r * 0.4), Vector2(r * 0.8, -r * 1.1), maxf(3.0, r * 0.14), bark)
			cv.line(Vector2(0, -r * 0.6), Vector2(-r * 0.7, -r * 1.2), maxf(3.0, r * 0.14), bark)
			cv.line(Vector2(r * 0.5, -r * 0.9), Vector2(r * 0.6, -r * 1.4), PIX, bark)
		"tomb":
			var stone := Color("6a6872")
			cv.rect(Rect2(Vector2(-r * 0.7, -r), Vector2(r * 1.4, r * 1.6)), stone)
			cv.circle(Vector2(0, -r), r * 0.7, stone)
			cv.line(Vector2(-r * 0.35, -r * 0.55), Vector2(r * 0.35, -r * 0.55), PIX, Color("4a4852"))   # inscripción
			cv.line(Vector2(-r * 0.3, -r * 0.25), Vector2(r * 0.3, -r * 0.25), PIX, Color("4a4852"))
			cv.rect(Rect2(Vector2(-r * 0.9, r * 0.5), Vector2(r * 1.8, r * 0.2)), Color("5a5862"))   # base
		"rack":
			var box := Rect2(Vector2(-r * 0.75, -r), Vector2(r * 1.5, r * 2.0))
			cv.rect(box, Color("23262e"))
			for k in 6:
				var y := box.position.y + 6.0 + k * (box.size.y - 12.0) / 6.0
				cv.line(Vector2(box.position.x + 4, y), Vector2(box.end.x - 4, y), PIX, Color("3a3f4a"))
			cv.frame(box, PIX, Color("4a4f5c"))
		"cable_coil":
			for k in 3:
				cv.ring(Vector2.ZERO, r * (1.0 - k * 0.25), maxf(2.0, r * 0.14), Color("2a2a30").lightened(k * 0.1))
		# Actos II-IV.
		"piston":   # la carcasa; el vástago y el vapor se animan en Zone
			cv.rect(Rect2(Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 0.9)), Color("5a4a3a"))
			cv.rect(Rect2(Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 0.15)), Color("6e5c48"))
			for k in 2:
				cv.rect(Rect2(Vector2(-r * 0.55 + k * r * 0.9, r * 0.1), Vector2(PIX * 2, PIX * 2)), Color("9a9ea8"))   # remaches
		"heat_sink":
			var body := Rect2(-Vector2(r, r * 0.7), Vector2(r * 2.0, r * 1.4))
			cv.rect(body, Color("8a9098"))
			for k in 7:
				var x := -r + 4.0 + k * (r * 2.0 - 8.0) / 6.0
				cv.line(Vector2(x, -r * 0.7), Vector2(x, r * 0.7), maxf(2.0, r * 0.08), Color("5a6068"))
			cv.frame(body, PIX, Color("3a4048"))
		"barrel":
			cv.rect(Rect2(-Vector2(r * 0.8, r), Vector2(r * 1.6, r * 1.8)), Color("3a5a3a"))
			cv.ellipse(Vector2(0, -r), Vector2(r * 0.8, r * 0.25), Color("4a6a4a"))   # tapa
			cv.line(Vector2(-r * 0.8, -r * 0.4), Vector2(r * 0.8, -r * 0.4), PIX, Color("2a3a2a"))
			cv.line(Vector2(-r * 0.8, r * 0.3), Vector2(r * 0.8, r * 0.3), PIX, Color("2a3a2a"))
			cv.rect(Rect2(Vector2(-r * 0.4, -r * 0.2), Vector2(r * 0.8, r * 0.3)), Color("9ad06a"))   # etiqueta 0xFF
		"capacitor":
			cv.rect(Rect2(-Vector2(r * 0.7, r), Vector2(r * 1.4, r * 1.8)), Color("2a4a8a"))
			cv.rect(Rect2(-Vector2(r * 0.7, r), Vector2(r * 0.35, r * 1.8)), Color("c8c8d0"))   # franja del negativo
			cv.ellipse(Vector2(0, -r), Vector2(r * 0.7, r * 0.25), Color("9a9aa4"))
			cv.line(Vector2(-r * 0.3, -r), Vector2(r * 0.3, -r), PIX, Color("5a5a62"))   # la cruz de la tapa
		"chip_die":
			var box := Rect2(-Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6))
			for k in 6:
				var x := box.position.x + 6.0 + k * (box.size.x - 12.0) / 5.0
				cv.line(Vector2(x, box.position.y - 6), Vector2(x, box.end.y + 6), maxf(2.0, r * 0.08), Color("c0a060"))
			cv.rect(box, Color("1c1c22"))
			cv.rect(box.grow(-4), Color("26262e"))
			cv.circle(box.position + Vector2(10, 10), maxf(2.0, r * 0.1), Color("3a3a44"))
		"ice_block":
			var pts := PackedVector2Array()
			for k in 6:
				pts.append(Vector2.from_angle(TAU * k / 6.0 + variant) * r * (0.85 + 0.15 * sin(k + variant)))
			cv.poly(pts, Color(0.7, 0.85, 1.0, 0.9))
			cv.line(Vector2(-r * 0.4, -r * 0.3), Vector2(r * 0.2, r * 0.2), PIX, Color(1, 1, 1, 0.95))   # brillo
			cv.line(Vector2(-r * 0.1, -r * 0.5), Vector2(r * 0.1, -r * 0.35), PIX, Color(1, 1, 1, 0.95))
	_shade(img)
	var tex := ImageTexture.create_from_image(img)
	return {"texture": tex, "offset": -c * PIX, "size": Vector2(w, h) * PIX}


## Contorno oscuro alrededor y luz/sombra en los bordes de cada forma.
static func _shade(img: Image) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	var solid := func(x: int, y: int) -> bool: return x >= 0 and y >= 0 and x < w and y < h and src.get_pixel(x, y).a > 0.5
	for y in h:
		for x in w:
			if solid.call(x, y):
				var col := src.get_pixel(x, y)
				if not solid.call(x - 1, y) or not solid.call(x, y - 1):
					col = col.lightened(LIGHT)
				elif not solid.call(x + 1, y) or not solid.call(x, y + 1):
					col = col.darkened(SHADE)
				img.set_pixel(x, y, col)
			elif solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1):
				img.set_pixel(x, y, OUTLINE)


## Pinta en la imagen con coordenadas del mundo relativas al centro del obstáculo.
class _Canvas:
	var img: Image
	var c: Vector2

	func _init(p_img: Image, p_center: Vector2) -> void:
		img = p_img
		c = p_center

	func _px(p: Vector2) -> Vector2:
		return c + p / ObstacleArt.PIX

	func _plot(x: int, y: int, col: Color) -> void:
		if x >= 1 and y >= 1 and x < img.get_width() - 1 and y < img.get_height() - 1:   # deja sitio al contorno
			img.set_pixel(x, y, col)

	func rect(r: Rect2, col: Color) -> void:
		var a := _px(r.position)
		var b := _px(r.end)
		for y in range(floori(a.y), ceili(b.y)):
			for x in range(floori(a.x), ceili(b.x)):
				_plot(x, y, col)

	func frame(r: Rect2, width: float, col: Color) -> void:
		rect(Rect2(r.position, Vector2(r.size.x, width)), col)
		rect(Rect2(Vector2(r.position.x, r.end.y - width), Vector2(r.size.x, width)), col)
		rect(Rect2(r.position, Vector2(width, r.size.y)), col)
		rect(Rect2(Vector2(r.end.x - width, r.position.y), Vector2(width, r.size.y)), col)

	func ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
		var cc := _px(center)
		var rr := radii / ObstacleArt.PIX
		for y in range(floori(cc.y - rr.y), ceili(cc.y + rr.y) + 1):
			for x in range(floori(cc.x - rr.x), ceili(cc.x + rr.x) + 1):
				var d := Vector2((x + 0.5 - cc.x) / maxf(rr.x, 0.5), (y + 0.5 - cc.y) / maxf(rr.y, 0.5))
				if d.length_squared() <= 1.0:
					_plot(x, y, col)

	func circle(center: Vector2, radius: float, col: Color) -> void:
		ellipse(center, Vector2(radius, radius), col)

	func ring(center: Vector2, radius: float, width: float, col: Color) -> void:
		var cc := _px(center)
		var r_out := radius / ObstacleArt.PIX
		var r_in := maxf(0.0, (radius - width) / ObstacleArt.PIX)
		for y in range(floori(cc.y - r_out), ceili(cc.y + r_out) + 1):
			for x in range(floori(cc.x - r_out), ceili(cc.x + r_out) + 1):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(cc)
				if d <= r_out and d >= r_in:
					_plot(x, y, col)

	func line(a: Vector2, b: Vector2, width: float, col: Color) -> void:
		var steps := maxi(1, ceili(a.distance_to(b) / ObstacleArt.PIX))
		for k in steps + 1:
			circle(a.lerp(b, float(k) / steps), width / 2.0, col)

	func poly(pts: PackedVector2Array, col: Color) -> void:
		var local := PackedVector2Array()
		for p in pts:
			local.append(_px(p))
		var bounds := Rect2(local[0], Vector2.ZERO)
		for p in local:
			bounds = bounds.expand(p)
		for y in range(floori(bounds.position.y), ceili(bounds.end.y) + 1):
			for x in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), local):
					_plot(x, y, col)
