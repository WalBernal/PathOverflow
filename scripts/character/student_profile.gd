class_name StudentProfile
## El alumno de perfil (T182), mirando a la derecha (a la izquierda se voltea al
## dibujar). La lámina del usuario solo trae vistas de frente; esto lo dibuja a la
## misma escala y con su estilo: los colores del alumno de la lámina recoloreados con
## los del creador (StudentHero._tone), contorno de color, cabeza grande, y brazos y
## piernas trazados en cada cuadro para que dé zancadas de verdad.
## Celda, pies y orden de cuadros: los de StudentHero.

const C := Vector2(27.5, 20.5)   # centro del cráneo
const R := 9.5
const HIP_Y := 43
const SHOULDER := Vector2i(29, 32)
const BACK_SHOULDER := Vector2i(25, 32)
const ARM_LEN := 8.0


## Paleta del alumno de la lámina, recoloreada: letra → color.
static func palette(look: Dictionary) -> Dictionary:
	var target := {
		"hair": Color(look.get("hair_color", "2b2118")), "skin": Color(look.get("skin_tone", "c99a7a")),
		"eyes": Color(look.get("eye_color", "3a2414")), "outfit": Color(look.get("outfit_color", "2b4a6b")),
	}
	var t := func(hex: String, role: String) -> Color: return StudentHero._tone(Color(hex), role, target)
	return {
		"skin": t.call("f6c8a0", "skin"), "skin_shade": t.call("c57d71", "skin"), "skin_line": t.call("4a2d3c", "skin"),
		"mouth": t.call("aa605c", "skin"), "iris": t.call("5a4632", "eyes"), "iris_dark": t.call("482822", "eyes"),
		"brow": t.call("502e1e", "brow"), "eye_dark": Color("22162c"), "pupil": Color("32181c"),
		"hood_light": t.call("3c5296", "outfit"), "hood": t.call("243278", "outfit"), "hood_dark": t.call("1a1e52", "outfit"),
		"hood_line": t.call("100f2d", "outfit"),
		"shirt": Color("ececf0"), "shirt_shade": Color("aeadc0"),
		"pants": Color("343850"), "pants_dark": Color("252637"), "pants_line": Color("14141e"),
		"shoe": Color("e6e4de"), "shoe_shade": Color("a7a6b8"), "shoe_line": Color("323045"), "glitch": Color("28f0e6"),
	}


## Cabeza y torso de perfil, sin brazos ni piernas (van en cada cuadro), con el
## peinado, la barba, los accesorios y el equipo.
static func body(look: Dictionary) -> Image:
	var img := Image.create_empty(StudentHero.CELL.x, StudentHero.CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := palette(look)
	var helmet_eq := String(look.get("eq_helmet", ""))
	var body_eq := String(look.get("eq_body", ""))
	_torso(img, pal)
	_head(img, pal)
	if helmet_eq == "":
		_hair(img, look)
	if int(look.get("beard", 0)) > 0:
		var beard := Color(look.get("beard_color", look.get("hair_color", "2b2118")))
		for p in [Vector2i(30, 27), Vector2i(31, 28), Vector2i(32, 28), Vector2i(33, 28), Vector2i(34, 28), Vector2i(31, 27), Vector2i(32, 29), Vector2i(33, 29)]:
			img.set_pixelv(p, beard if (p.x + p.y) % 3 else beard.darkened(0.25))
	_outline(img, pal["skin_line"], 0, 30)
	if body_eq != "":
		_over_squashed(img, StudentHero._layer("torso_" + body_eq), StudentHero.TORSO_ROWS, 0.62, 28.0)
	if helmet_eq != "":
		var layer := StudentHero._layer("head_" + helmet_eq)
		if helmet_eq in ["b", "d"]:   # yelmo y capucha: lo de la cara (visor, gafas) va delante
			_over_profile_head(img, layer)
		else:
			_over_squashed(img, layer, Vector2i(0, 29), 0.9, 28.5)
	elif int(look.get("accessory", 0)) > 0:
		_accessory(img, look)
	return img


static func _torso(img: Image, pal: Dictionary) -> void:
	# Sudadera de lado: espalda redondeada a la izquierda, pecho a la derecha.
	for y in range(30, 43):
		var back := 23 if y < 33 else 22
		var front := 33 if y < 40 else 32
		for x in range(back, front + 1):
			var c: Color = pal["hood"]
			if x <= back + 1 or y >= 41:
				c = pal["hood_dark"]
			elif x >= front - 3 and y < 36:
				c = pal["hood_light"]
			img.set_pixel(x, y, c)
	# Camisa asomando por delante y la capucha caída en la nuca.
	for y in range(31, 37):
		img.set_pixel(33, y, pal["shirt"] if y < 35 else pal["shirt_shade"])
	for p in [Vector2i(21, 29), Vector2i(22, 29), Vector2i(21, 30), Vector2i(22, 30), Vector2i(23, 29), Vector2i(21, 31), Vector2i(22, 31)]:
		img.set_pixelv(p, pal["hood_dark"])
	img.set_pixel(24, 39, pal["glitch"])
	# Cuello.
	for x in range(27, 31):
		img.set_pixel(x, 30, pal["skin_shade"])
	_outline(img, pal["hood_line"], 29, 43)


static func _head(img: Image, pal: Dictionary) -> void:
	for y in range(10, 31):
		for x in range(15, 42):
			var d := Vector2(x + 0.5, y + 0.5) - C
			if d.length() <= R:
				var shade := d.x < -4.5 or y >= 28
				img.set_pixel(x, y, pal["skin_shade"] if shade else pal["skin"])
	# Cara: mandíbula, barbilla y nariz hacia delante.
	for y in range(21, 29):
		for x in range(34, 37 if y < 27 else 36):
			img.set_pixel(x, y, pal["skin"])
	for x in range(30, 35):
		img.set_pixel(x, 29, pal["skin_shade"])
	img.set_pixel(37, 24, pal["skin"])
	img.set_pixel(37, 25, pal["skin"])
	img.set_pixel(38, 25, pal["skin_shade"])
	img.set_pixel(35, 28, pal["mouth"])
	img.set_pixel(36, 28, pal["mouth"])
	# Ojo mirando hacia delante, con su ceja.
	img.set_pixel(33, 22, pal["brow"])
	img.set_pixel(34, 22, pal["brow"])
	img.set_pixel(33, 23, pal["eye_dark"])
	img.set_pixel(34, 23, pal["eye_dark"])
	img.set_pixel(33, 24, Color.WHITE)
	img.set_pixel(34, 24, pal["pupil"])
	img.set_pixel(33, 25, pal["iris"])
	img.set_pixel(34, 25, pal["iris_dark"])
	# Oreja.
	for p in [Vector2i(25, 23), Vector2i(26, 23), Vector2i(25, 24), Vector2i(26, 24), Vector2i(25, 25), Vector2i(26, 25)]:
		img.set_pixelv(p, pal["skin_shade"])
	img.set_pixel(25, 24, pal["mouth"])
	img.set_pixel(27, 22, pal["skin_line"])


## Peinados de perfil: la misma forma de cada uno vista de lado (con el motor de pelo
## de StudentHero sobre la cabeza de perfil).
static func _hair(img: Image, look: Dictionary) -> void:
	var style := int(look.get("hair", 1))
	var hair := Color(look.get("hair_color", "2b2118"))
	var skin := Color(look.get("skin_tone", "c99a7a"))
	var tie := Color(look.get("accent_color", "2fd0a0"))
	var h := StudentHero.Hair.new()
	h.center = C
	h.radius = R
	h.crown = Vector2(25.0, 6.0)
	match style:
		0:   # rapado
			h.cap(0.6, 10, 19)
			_trim(h, 19, 22, false)
			_nape(h, 19, 25)
			h.flat = true
		1:   # corto en punta (el de la lámina, de lado)
			h.cap(1.1, 10, 21)
			_trim(h, 20, 23)
			h.spikes([[22.0, 8, 2.4], [25.5, 6, 2.6], [29.0, 7, 2.4], [32.0, 10, 2.0]])
			h.locks([[33.5, 3, 2.0], [31.0, 2, 1.6]], 19)
			_nape(h, 24, 26)
		2:   # largo: cae por la espalda hasta los hombros
			h.cap(2.0, 10, 21)
			_trim(h, 20, 23)
			h.locks([[33.5, 3, 2.0]], 19)
			_back_hair(h, 18, 25, 35)
		3:   # cresta
			h.stubble(0.6, 11, 22)
			h.spikes([[22.5, 9, 2.2], [26.0, 5, 2.6], [29.5, 7, 2.4], [32.5, 11, 2.0]])
			_trim(h, 19, 22, false)
		4:   # moño arriba y atrás
			h.cap(1.2, 11, 21)
			_trim(h, 19, 23)
			_nape(h, 23, 25)
			h.disc(Vector2(22.5, 10.5), 3.4)
			h.ties.append(Rect2i(23, 13, 3, 1))
		5:   # hacia atrás
			h.cap(2.4, 9, 20)
			_trim(h, 18, 21)
			_nape(h, 22, 26)
		6:   # afro
			h.disc(Vector2(25.5, 16.5), 12.0)
			for p: Vector2i in h.cells.keys():
				if (p.y >= 20 and p.x >= 29) or p.y > 27 or (p.x >= 24 and p.x <= 28 and p.y >= 22):
					h.cells.erase(p)
			h.curly = true
		7:   # coleta que cae por detrás
			h.cap(1.6, 10, 21)
			_trim(h, 20, 23)
			h.locks([[33.5, 3, 2.0]], 19)
			h.tail(Vector2i(17, 16), 16, 3)
			h.ties.append(Rect2i(16, 17, 3, 1))
		8:   # rapado lateral: el pelo de arriba cae hacia delante
			h.stubble(0.6, 13, 22)
			h.cap(2.2, 9, 16)
			h.locks([[33.0, 6, 2.6], [30.0, 4, 2.2]], 16)
		9:   # melena con flequillo
			h.cap(2.0, 10, 21)
			_trim(h, 21, 22)
			h.locks([[34.0, 3, 2.2], [31.5, 3, 2.0]], 19)
			_back_hair(h, 18, 25, 30)
		10:   # entradas
			h.cap(1.4, 11, 20)
			_trim(h, 17, 23)
			_nape(h, 22, 25)
		11:   # ondulado
			h.cap(2.2, 10, 21)
			_trim(h, 20, 23)
			h.locks([[33.5, 4, 2.2]], 19)
			_back_hair(h, 18, 25, 32, true)
		12:   # dos coletas: se ve la de este lado
			h.cap(1.6, 10, 21)
			_trim(h, 20, 23)
			h.locks([[33.5, 3, 2.0]], 19)
			h.tail(Vector2i(21, 17), 14, 3)
			h.ties.append(Rect2i(20, 18, 3, 1))
		13:   # trenzas: la de este lado
			h.cap(1.8, 10, 21)
			_trim(h, 20, 23)
			h.braid(Vector2i(23, 22), 14)
			h.ties.append(Rect2i(22, 36, 3, 1))
		14:   # flequillo lateral: el mechón cae por delante de la cara
			h.cap(2.0, 10, 21)
			_trim(h, 21, 23)
			h.locks([[34.0, 6, 2.6], [31.5, 4, 2.0]], 19)
			_nape(h, 23, 27)
		15:   # rizos cortos
			h.cap(2.4, 9, 21)
			_trim(h, 20, 23)
			h.curly = true
	h.paint(img, hair if not style in [0, 3] else hair.lerp(skin, 0.15), tie)


## Quita el pelo de la cara: delante de la frente bajo la fila `forehead` y la oreja.
static func _trim(h, forehead: int, ear_top: int, back := true) -> void:
	for p: Vector2i in h.cells.keys():
		if (p.x >= 30 and p.y >= forehead) or (p.x >= 24 and p.x <= 28 and p.y >= ear_top) or p.y >= 29:
			h.cells.erase(p)
	if back:   # detrás de la oreja, la nuca es pelo (sin la franja de piel)
		for y in range(12, 27):
			for x in range(16, 24):
				if (Vector2(x + 0.5, y + 0.5) - C).length() <= R + 0.6:
					h.cells[Vector2i(x, y)] = true


## La nuca: el pelo baja por detrás hasta la fila `to`.
static func _nape(h, from: int, to: int) -> void:
	for y in range(from, to + 1):
		for x in range(18, 24):
			if (Vector2(x + 0.5, y + 0.5) - C).length() <= R + 0.6:
				h.cells[Vector2i(x, y)] = true


## Pelo largo que cae por la espalda, de `from` a `to` (columnas x0..x1).
static func _back_hair(h, x0: int, x1: int, to: int, wavy := false) -> void:
	for y in range(18, to + 1):
		var right := x1 - maxi(0, (y - 26) / 2)
		var wave := (1 if (y / 3) % 2 == 0 else 0) if wavy else 0
		for x in range(x0 - wave, right + 1):
			if y < 22 or x < 24:
				h.cells[Vector2i(x, y)] = true


## Lentes y audífonos de lado.
static func _accessory(img: Image, look: Dictionary) -> void:
	var accent := Color(look.get("accent_color", "2a2a30"))
	match int(look.get("accessory", 0)):
		1, 2:
			var sun := int(look.get("accessory", 0)) == 2
			var frame: Color = accent.lightened(0.1) if sun else Color("241c2c")
			for x in range(32, 37):
				img.set_pixel(x, 22, frame)
				img.set_pixel(x, 26, frame)
			for y in range(23, 26):
				img.set_pixel(32, y, frame)
				img.set_pixel(36, y, frame)
				if sun:
					for x in range(33, 36):
						img.set_pixel(x, y, Color("2c3550").darkened(0.2 * (y - 23)))
			img.set_pixel(35, 23, Color(1, 1, 1, 0.9) if not sun else Color("9fb0d8"))
			for x in range(27, 32):   # la patilla hasta la oreja
				img.set_pixel(x, 23, frame)
		3:
			var dark := Color("1a1624")
			for y in range(11, 23):
				img.set_pixel(26 + (1 if y < 14 else 0), y, dark)
			for y in range(21, 27):
				for x in range(24, 29):
					var edge := x == 24 or x == 28 or y == 21 or y == 26
					img.set_pixel(x, y, dark if edge else accent)


## Contorno de color alrededor de lo dibujado en las filas `from`..`to`.
static func _outline(img: Image, color: Color, from: int, to: int) -> void:
	var src := img.duplicate() as Image
	for y in range(maxi(0, from - 1), mini(StudentHero.CELL.y, to + 2)):
		for x in StudentHero.CELL.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= from and q.x < StudentHero.CELL.x and q.y <= to and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, color)
					break


## Una capa de la lámina (de frente) estrechada para el perfil: de las filas `rows`,
## con `s` de ancho, centrada en `cx`.
static func _over_squashed(img: Image, layer: Image, rows: Vector2i, s: float, cx: float) -> void:
	if layer == null:
		return
	for y in range(rows.x, mini(rows.y + 1, StudentHero.CELL.y)):
		for x in StudentHero.CELL.x:
			var sx := roundi(28.5 + (x + 0.5 - cx) / s - 0.5)
			if sx < 0 or sx >= StudentHero.CELL.x:
				continue
			var c := layer.get_pixel(sx, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c)


## Casco o capucha de la lámina vistos de lado: la mitad izquierda de la de frente se
## estira hacia atrás y su centro (visor, gafas) queda delante, sobre la cara.
static func _over_profile_head(img: Image, layer: Image) -> void:
	if layer == null:
		return
	for y in range(0, 30):
		for x in StudentHero.CELL.x:
			# La cabeza de perfil (columnas 17..38) toma de la izquierda al centro de la de
			# frente (19..31): el centro (visor, gafas) cae delante, sobre la cara.
			var sx := roundi(19.0 + (x - 17) * 0.571)
			if sx < 0 or sx > 31:
				continue
			var c := layer.get_pixel(sx, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c)


## Un cuadro de perfil: el cuerpo con su balanceo, el brazo y la pierna de atrás (más
## oscuros), las de delante, el arma en la mano de delante y, al morir, tumbado.
static func frame(body_img: Image, look: Dictionary, weapon: Image, anim: String, k: int, prop := false) -> Image:
	var img := Image.create_empty(StudentHero.CELL.x, StudentHero.CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := palette(look)
	var robe := String(look.get("eq_body", "")) in StudentHero.ROBES
	var boots_eq := String(look.get("eq_boots", ""))
	var bob := 0
	var lean := 0
	var front_foot := 1
	var back_foot := -2
	var front_lift := 0
	var back_lift := 0
	var front_arm := 15.0   # grados: 0 abajo, 90 adelante, 180 arriba
	var back_arm := -10.0
	# En reposo, el arma hacia abajo junto a la pierna (no tapa la cara); los objetos de
	# los NPC (T178), derechos.
	var swing := 0 if prop else 3
	match anim:
		"idle":
			bob = [0, 0, 1, 1][k]
		"walk":
			front_foot = [4, 1, -3, 1][k]
			back_foot = [-3, 0, 4, 0][k]
			front_lift = [0, 1, 0, 0][k]
			back_lift = [0, 0, 0, 1][k]
			bob = [0, 1, 0, 1][k]
			front_arm = [-30.0, 0.0, 35.0, 0.0][k]
			back_arm = [35.0, 0.0, -30.0, 0.0][k]
		"attack":
			front_arm = [150.0, 175.0, 60.0, 30.0][k]
			swing = [1, 1, 2, 3][k]
			lean = [-1, -1, 1, 1][k]
			front_foot = 3
		"cast":
			front_arm = [80.0, 100.0][k]
			back_arm = [70.0, 90.0][k]
			bob = -1
		"hurt":
			lean = -1
			front_arm = 40.0
			back_arm = -40.0
		"dead", "dodge":
			bob = [1, 3][k]
			lean = 1
		# T198, por tipo de habilidad: el primer cuadro anticipa y el segundo es el impacto.
		"channel":   # brazos delante, el arma apuntando
			front_arm = [85.0, 95.0][k]
			back_arm = [80.0, 90.0][k]
			bob = -1
			swing = 2
		"shout":   # encogido tomando aire; echado atrás con los brazos en alto al gritar
			front_arm = [20.0, 150.0][k]
			back_arm = [10.0, 140.0][k]
			bob = [1, -1][k]
			lean = [1, -1][k]
			swing = [3, 1][k]
		"leap":   # agachado con el arma sobre la cabeza; al caer, el arma al suelo
			front_arm = [170.0, 60.0][k]
			back_arm = [160.0, 50.0][k]
			bob = [2, 3][k]
			lean = [-1, 1][k]
			swing = [1, 3][k]
			front_foot = 3
			back_foot = -4
		"summon":   # alza el arma y señala el suelo delante; la otra mano, en alto
			front_arm = [120.0, 45.0][k]
			back_arm = [150.0, 160.0][k]
			bob = [-1, 1][k]
			lean = [0, 1][k]
			swing = [1, 3][k]
		"aura":   # brazos delante y arriba, erguido
			front_arm = [70.0, 105.0][k]
			back_arm = [70.0, 115.0][k]
			bob = [0, -1][k]
			swing = [0, 1][k]
	# Pierna y brazo de atrás.
	if not robe:
		_leg(img, Vector2i(26, HIP_Y), back_foot, back_lift, pal, true, boots_eq)
	var back_hand := _arm(img, BACK_SHOULDER + Vector2i(lean, bob), back_arm, pal, true, look)
	# El cuerpo.
	for y in StudentHero.CELL.y:
		for x in StudentHero.CELL.x:
			var c := body_img.get_pixel(x, y)
			if c.a > 0.0:
				var q := Vector2i(x + lean, y + bob)
				if q.x >= 0 and q.y >= 0 and q.x < StudentHero.CELL.x and q.y < StudentHero.CELL.y:
					img.set_pixelv(q, c)
	if robe:
		_over_squashed(img, StudentHero._layer("legs_" + String(look.get("eq_body", ""))), StudentHero.LEGS_ROWS, 0.62, 28.0)
	else:
		_leg(img, Vector2i(29, HIP_Y), front_foot, front_lift, pal, false, boots_eq)
	var hand := _arm(img, SHOULDER + Vector2i(lean, bob), front_arm, pal, false, look)
	if weapon != null and not anim in ["cast", "dead"]:
		_weapon(img, weapon, hand, swing)
	if anim == "dead" and k == 1:
		img = StudentHero._lay_down(img)
	return img


## Pierna de lado: muslo y espinilla de 3 píxeles de la cadera al tobillo y zapatilla
## hacia delante. La de atrás, más oscura.
static func _leg(img: Image, hip: Vector2i, foot_dx: int, lift: int, pal: Dictionary, back: bool, boots_eq: String) -> void:
	var dark := 0.25 if back else 0.0
	var pants: Color = (pal["pants"] as Color).darkened(dark)
	var shoe: Color = (pal["shoe"] as Color).darkened(dark)
	var shoe_shade: Color = (pal["shoe_shade"] as Color).darkened(dark)
	if boots_eq != "":   # las botas toman el color de las de la lámina
		var layer := StudentHero._layer("legs_" + boots_eq)
		if layer != null:
			for p in [Vector2i(25, 47), Vector2i(24, 46), Vector2i(31, 47), Vector2i(26, 45)]:
				if layer.get_pixelv(p).a > 0.0:
					shoe = layer.get_pixelv(p).darkened(dark)
					shoe_shade = shoe.darkened(0.25)
					break
	var ankle := Vector2i(hip.x + foot_dx, StudentHero.FEET.y - 2 - lift)
	var steps := maxi(absi(ankle.x - hip.x), absi(ankle.y - hip.y))
	var line: Color = pal["pants_line"]
	for i in steps + 1:
		var t := float(i) / maxf(1.0, steps)
		var q := Vector2i(roundi(lerpf(hip.x, ankle.x, t)), roundi(lerpf(hip.y, ankle.y, t)))
		for dx in 3:
			img.set_pixel(q.x - 1 + dx, q.y, line if dx == 0 else (pants if dx == 1 else pants.darkened(0.15)))
		img.set_pixel(q.x + 2, q.y, line)
	for dy in 3:
		for dx in range(-1, 4):
			var c := shoe if dy < 2 else shoe_shade
			if dx == -1 or dx == 3 or dy == 2:
				c = pal["shoe_line"]
			img.set_pixel(ankle.x + dx, ankle.y + dy, c)


## Brazo de lado (manga de la sudadera o de la armadura) y la mano; devuelve la mano.
static func _arm(img: Image, shoulder: Vector2i, angle: float, pal: Dictionary, back: bool, look: Dictionary) -> Vector2i:
	var sleeve: Color = pal["hood_dark"] if back else pal["hood"]
	var body_eq := String(look.get("eq_body", ""))
	if body_eq != "":   # la manga, del color de la armadura
		var layer := StudentHero._layer("torso_" + body_eq)
		if layer != null and layer.get_pixel(21, 36).a > 0.0:
			sleeve = layer.get_pixel(21, 36).darkened(0.25 if back else 0.0)
	var r := deg_to_rad(angle)
	var d := Vector2(sin(r), cos(r))
	var hand := shoulder + Vector2i(roundi(d.x * ARM_LEN), roundi(d.y * ARM_LEN))
	var steps := maxi(absi(hand.x - shoulder.x), absi(hand.y - shoulder.y))
	for i in steps + 1:
		var t := float(i) / maxf(1.0, steps)
		var q := Vector2i(roundi(lerpf(shoulder.x, hand.x, t)), roundi(lerpf(shoulder.y, hand.y, t)))
		img.set_pixel(q.x, q.y, sleeve)
		img.set_pixel(q.x + 1, q.y, sleeve.darkened(0.15))
		img.set_pixel(q.x - 1, q.y, pal["hood_line"])
		img.set_pixel(q.x + 2, q.y, pal["hood_line"])
	var skin: Color = (pal["skin"] as Color).darkened(0.2 if back else 0.0)
	img.set_pixel(hand.x, hand.y, skin)
	img.set_pixel(hand.x + 1, hand.y, skin)
	img.set_pixel(hand.x, hand.y + 1, pal["skin_shade"])
	img.set_pixel(hand.x + 1, hand.y + 1, pal["skin_shade"])
	return hand


## El arma de la lámina movida a la mano de delante (y girada en el tajo).
static func _weapon(img: Image, weapon: Image, hand: Vector2i, swing: int) -> void:
	for y in StudentHero.CELL.y:
		for x in StudentHero.CELL.x:
			var c := weapon.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var p := Vector2i(x, y) - StudentHero.GRIP
			match swing:
				2:
					p = Vector2i(-p.y, p.x)
				3:
					p = Vector2i(-p.x, -p.y)
			var q := hand + p
			if q.x >= 0 and q.y >= 0 and q.x < StudentHero.CELL.x and q.y < StudentHero.CELL.y:
				img.set_pixelv(q, c)
