class_name StudentHero
## El personaje dentro del servidor (T176), con el estilo de la lámina del usuario
## (docs/capturas/personajes/propuestas_frente.png, cortada en capas por
## tools/import_hero_art.gd en assets/sprites/hero/):
## - Base: el alumno («Dev Glitcheado»), recoloreado con la apariencia del creador
##   (pelo, piel, ojos y sudadera), con su peinado, barba y accesorio.
## - Encima, lo que lleva puesto: el casco, la armadura y las botas cambian su look
##   (LOOKS: base del objeto → capa de la lámina) y el arma va en la mano.
## - De frente (la lámina es de frente); a la izquierda se voltea al dibujar. Las
##   animaciones mueven las piezas de la plantilla: respirar, pasos, el tajo del arma,
##   golpe, esquiva y tumbado al morir.
## La hoja (una fila de cuadros CELL, en el orden de ORDER) se arma al cargar y se
## guarda en caché por look y arma.

const DIR := "res://assets/sprites/hero/"
const CELL := Vector2i(60, 56)
const FEET := Vector2i(29, 49)
const ORDER := ["idle", "walk", "attack", "cast", "hurt", "dead", "dodge"]
const FRAMES := {"idle": 4, "walk": 4, "attack": 4, "cast": 2, "hurt": 2, "dead": 2, "dodge": 2}
## Filas de la plantilla: dónde empiezan las piernas y el centro (para los pasos).
const LEGS_Y := 43
const CENTER_X := 28
## Mano que lleva el arma (la del lado izquierdo de la lámina) y su punto de agarre.
const GRIP := Vector2i(19, 40)

## Qué capa de la lámina pone cada base de objeto (b = Paladín Firewall, c = Mago
## Neural, d = Ladrón Root, e = Invocador IA). Sin objeto (o la sudadera), el alumno.
const LOOKS := {
	"helmet": {"casco_de_hierro": "b", "casco_de_obra": "b", "capucha_de_cuero": "d", "diadema_de_seda": "c"},
	"body": {"armadura_de_rack": "b", "cota_de_placas": "b", "chaleco_de_cuero": "d", "tunica_de_seda": "c",
		"chaqueta_de_conferencias": "e"},
	"boots": {"botas_de_hierro": "b", "botas_de_seguridad": "b", "botas_de_cuero": "d"},
}
## Armaduras largas: también ponen sus piernas (la túnica tapa las botas).
const ROBES := ["c", "e"]
## Arma de la lámina por tipo (las de oficio de T177 llegarán aparte).
const WEAPON_ART := {"sword": "sword", "dagger": "dagger", "mace": "staff", "axe": "staff"}

## Colores del alumno en la lámina, por papel y tono: el papel dice qué color del
## creador lo sustituye; se conserva el brillo relativo (HSV) para no perder el sombreado.
const ROLES := {
	"260b1a": ["hair", 0.0], "7e4c2e": ["hair", 0.0], "45131f": ["hair", 0.0], "a77d5a": ["hair", 0.0],
	"87515b": ["hair_skin", 0.0],
	"f6c8a0": ["skin", 0.0], "c57d71": ["skin", 0.0], "4a2d3c": ["skin", 0.0], "aa605c": ["skin", 0.0],
	"5a4632": ["eyes", 0.0], "482822": ["eyes", 0.0], "502e1e": ["brow", 0.0],
	"3c5296": ["outfit", 0.0], "243278": ["outfit", 0.0], "1a1e52": ["outfit", 0.0], "100f2d": ["outfit", 0.0],
}
## Color principal de cada papel en la lámina (contra él se mide el brillo de cada tono).
const REF := {"hair": "7e4c2e", "skin": "f6c8a0", "eyes": "5a4632", "outfit": "243278"}

static var _cache := {}
static var _art := {}


static func columns() -> int:
	var n := 0
	for anim in ORDER:
		n += int(FRAMES[anim])
	return n


static func first_column(anim: String) -> int:
	var c := 0
	for a in ORDER:
		if a == anim:
			return c
		c += int(FRAMES[a])
	return -1


## Cuadro de la hoja para una pose (como PlayerSheet.column_for).
static func column_for(state: String, t: float, time := 0.0, walk_phase := -1.0) -> int:
	var anim := state
	match state:
		"run":
			anim = "walk"
		"limp":
			anim = "dead"
		"channel", "type":
			anim = "cast"
		"shoot":
			anim = "attack"
	if not FRAMES.has(anim):
		anim = "idle"
	if walk_phase >= 0.0 and anim == "idle":
		anim = "walk"
	var n := int(FRAMES[anim])
	var k := 0
	match anim:
		"walk":
			k = posmod(int(floor(maxf(0.0, walk_phase) / TAU * n)), n)
		"idle":
			k = posmod(int(floor(time * 3.0)), n)
		"cast":
			k = posmod(int(floor(time * 4.0)), n) if state in ["channel", "type"] else clampi(int(t * n), 0, n - 1)
		_:
			k = clampi(int(t * n), 0, n - 1)
	return first_column(anim) + k


## Look de un personaje: su apariencia y la capa que pone cada objeto equipado.
static func look_of(appearance: Dictionary, equipped: Dictionary) -> Dictionary:
	var look := appearance.duplicate()
	for slot in LOOKS:
		var base_id := String(equipped.get(slot, ""))
		look["eq_" + slot] = String(LOOKS[slot].get(base_id, ""))
	return look


## Lo que lleva puesto un guardado (ranura → id de base), para la lista de personajes.
static func equipped_of_save(data: Dictionary) -> Dictionary:
	var out := {}
	var equip: Dictionary = data.get("inventory", {}).get("equipment", {})
	for slot in LOOKS:
		var it = equip.get(slot, null)
		out[slot] = String(it.get("base", "")) if it is Dictionary else ""
	return out


static func texture(look: Dictionary, weapon: String) -> ImageTexture:
	var key := "%s|%s" % [weapon, JSON.stringify(look, "", true)]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(build(look, weapon))
	return _cache[key]


static func _layer(name: String) -> Image:
	if not _art.has(name):
		# Siempre como recurso importado (sin pérdida): igual en el editor, las pruebas y el APK.
		var path := DIR + name + ".png"
		_art[name] = (load(path) as Texture2D).get_image() if ResourceLoader.exists(path) else null
		if _art[name] != null:
			(_art[name] as Image).convert(Image.FORMAT_RGBA8)
	return _art[name]


static func available() -> bool:
	return _layer("base") != null


## Hoja completa.
static func build(look: Dictionary, weapon: String) -> Image:
	var body := figure(look)
	var weapon_img: Image = _layer("weapon_" + String(WEAPON_ART.get(weapon, ""))) if WEAPON_ART.has(weapon) else null
	var sheet := Image.create_empty(CELL.x * columns(), CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var col := 0
	for anim in ORDER:
		var n := int(FRAMES[anim])
		for k in n:
			sheet.blit_rect(frame(body, weapon_img, anim, k), Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, 0))
			col += 1
	return sheet


## El personaje quieto, con su apariencia y su equipo (sin el arma).
static func figure(look: Dictionary) -> Image:
	var img := (_layer("base") as Image).duplicate() as Image
	_recolor(img, look)
	if String(look.get("eq_helmet", "")) == "":   # con casco o capucha, el peinado no asoma
		_hair_style(img, look)
	if int(look.get("beard", 0)) > 0:
		_beard(img, look)
	var body_eq := String(look.get("eq_body", ""))
	var boots_eq := String(look.get("eq_boots", ""))
	var helmet_eq := String(look.get("eq_helmet", ""))
	if body_eq != "":
		_over(img, _layer("torso_" + body_eq))
		if body_eq in ROBES:
			_over(img, _layer("legs_" + body_eq))
	if boots_eq != "" and not body_eq in ROBES:
		_over(img, _layer("legs_" + boots_eq))
	if helmet_eq != "":
		# El pelo que el casco no tapa (las puntas) desaparece: va debajo del casco.
		var helmet := _layer("head_" + helmet_eq)
		if helmet != null:
			for p: Vector2i in _hair_mask(img):
				if helmet.get_pixelv(p).a <= 0.0:
					img.set_pixelv(p, Color(0, 0, 0, 0))
		_over(img, helmet)
	elif int(look.get("accessory", 0)) > 0:
		_accessory(img, look)
	return img


static func _over(img: Image, layer: Image) -> void:
	if layer != null:
		img.blend_rect(layer, Rect2i(Vector2i.ZERO, CELL), Vector2i.ZERO)


## Sustituye pelo, piel, ojos y sudadera por los colores del creador, con el mismo
## sombreado (el brillo de cada tono respecto al principal, en HSV).
static func _recolor(img: Image, look: Dictionary) -> void:
	var target := {
		"hair": Color(look.get("hair_color", "2b2118")), "skin": Color(look.get("skin_tone", "c99a7a")),
		"eyes": Color(look.get("eye_color", "3a2414")), "outfit": Color(look.get("outfit_color", "2b4a6b")),
	}
	var memo := {}
	for y in CELL.y:
		for x in CELL.x:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var hex := c.to_html(false)
			if not ROLES.has(hex):
				continue
			if not memo.has(hex):
				memo[hex] = _tone(c, ROLES[hex][0], target)
			img.set_pixel(x, y, memo[hex])


static func _tone(c: Color, role: String, target: Dictionary) -> Color:
	match role:
		"brow":
			return _tone(c, "hair", target).darkened(0.25)
		"hair_skin":
			return _tone(Color("7e4c2e"), "hair", target).lerp(_tone(Color("c57d71"), "skin", target), 0.5)
	var ref := Color(REF[role])
	var to: Color = target[role]
	var k := c.v / maxf(ref.v, 0.01)
	var out := Color.from_hsv(to.h, clampf(to.s * lerpf(1.0, 1.15, clampf(1.0 - k, 0.0, 1.0)), 0.0, 1.0), clampf(to.v * k, 0.0, 1.0))
	# Los tonos muy oscuros (contornos) se van hacia un morado oscuro, como en la lámina.
	if k < 0.45:
		out = out.lerp(Color("1a1024"), 0.35)
	return out


## Peinados del creador (T180). «Corto» es el pelo de la lámina; los demás se dibujan
## sobre la cabeza calva de la plantilla (la cúpula de DOME), cada uno con su forma y
## el mismo sombreado que el de la lámina: luz arriba a la izquierda, sombra abajo y a
## la derecha, contorno contra el fondo.
const DOME_C := Vector2(28.5, 24.0)
const DOME_R := 9.8
const BROW_Y := 24


static func _hair_style(img: Image, look: Dictionary) -> void:
	var style := int(look.get("hair", 1))
	if style == 1:
		return
	var hair := Color(look.get("hair_color", "2b2118"))
	var skin := Color(look.get("skin_tone", "c99a7a"))
	_bald(img, skin)
	var m := {}
	match style:
		0:   # rapado: pelo al ras de la cúpula
			_dome_cap(m, 0.6, 13, 20)
			_paint_hair(img, m, hair.lerp(skin, 0.35).darkened(0.1), true)
			return
		2:   # largo: casquete con flequillo partido y mechones hasta los hombros
			_dome_cap(m, 1.6, 13, 22)
			_fringe(m, 21, 23, [22, 23, 24, 25, 26, 31, 32, 33, 34, 35])
			_rect(m, 17, 21, 3, 13)
			_rect(m, 37, 21, 3, 13)
		3:   # cresta: lados rapados y una cresta alta en el centro
			var sides := {}
			_dome_cap(sides, 0.6, 13, 20)
			_paint_hair(img, sides, hair.lerp(skin, 0.4).darkened(0.1), true)
			for y in range(7, 21):
				var w := 3 if y > 9 else 2
				for x in range(28 - w, 29 + w - (1 if y < 9 else 0)):
					m[Vector2i(x, y)] = true
		4:   # moño: peinado hacia atrás y un moño arriba
			_dome_cap(m, 1.2, 14, 21)
			_disc(m, Vector2(28.5, 11.0), 3.6)
		5:   # hacia atrás: con volumen, la frente despejada y raya diagonal
			_dome_cap(m, 1.8, 12, 20)
			_rect(m, 18, 20, 2, 5)
			_rect(m, 38, 20, 2, 5)
		6:   # afro: un círculo grande alrededor de la cara
			_disc(m, Vector2(28.5, 18.0), 13.0)
			for p: Vector2i in m.keys():
				if p.y > 25 or (p.y >= 21 and p.x >= 20 and p.x <= 37):
					m.erase(p)
		7:   # coleta: recogido, flequillo corto y la coleta por la derecha
			_dome_cap(m, 1.2, 14, 21)
			_fringe(m, 21, 22, [21, 22, 23, 24])
			for y in range(17, 33):
				var w := 3 if y < 28 else 2
				for x in range(39, 39 + w):
					m[Vector2i(x, y)] = true
		8:   # rapado lateral: lados rapados y el pelo largo arriba, caído a un lado
			var sides := {}
			_dome_cap(sides, 0.6, 17, 21)
			_paint_hair(img, sides, hair.lerp(skin, 0.4).darkened(0.1), true)
			_dome_cap(m, 2.2, 11, 17)
			_fringe(m, 18, 21, [20, 21, 22, 23, 24, 25, 26])
		9:   # melena con flequillo: corte recto en la frente y a los lados hasta el cuello
			_dome_cap(m, 1.6, 13, 23)
			_fringe(m, 21, 23, range(20, 38))
			_rect(m, 17, 21, 4, 10)
			_rect(m, 37, 21, 4, 10)
		10:   # entradas: el nacimiento del pelo en «M», con las sienes despejadas
			_dome_cap(m, 1.2, 14, 20)
			for p: Vector2i in m.keys():
				if p.y >= 18 and ((p.x >= 21 and p.x <= 25) or (p.x >= 32 and p.x <= 36)):
					m.erase(p)
			_rect(m, 27, 20, 4, 1)
	_paint_hair(img, m, hair, false)
	if style == 4 or style == 7:   # el lazo del moño o la coleta, del color de los detalles
		var tie := Color(look.get("accent_color", "2fd0a0"))
		for x in ([27, 28, 29, 30] if style == 4 else [39, 40, 41]):
			img.set_pixel(x, 14 if style == 4 else 18, tie)


## La cabeza sin pelo: quita el de la lámina y rellena la cúpula con piel (con su
## sombra a la derecha y su contorno), respetando las cejas y la cara.
static func _bald(img: Image, skin: Color) -> void:
	var base := _layer("base") as Image
	for y in range(0, 27):
		for x in CELL.x:
			var hex := base.get_pixel(x, y).to_html(false)
			if ROLES.has(hex) and String(ROLES[hex][0]) in ["hair", "hair_skin"]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var shade := _tone(Color("c57d71"), "skin", {"skin": skin})
	var outline := _tone(Color("4a2d3c"), "skin", {"skin": skin})
	for y in range(13, BROW_Y + 3):
		for x in CELL.x:
			var d := Vector2(x + 0.5, y + 0.5) - DOME_C
			if img.get_pixel(x, y).a > 0.0:
				continue
			if y <= BROW_Y and d.length() <= DOME_R:
				img.set_pixel(x, y, shade if d.x > DOME_R - 3.5 or d.x < -DOME_R + 1.2 else skin)
			elif y > BROW_Y and absf(d.x) < DOME_R - 0.5:   # las sienes (la sombra del pelo en la lámina)
				img.set_pixel(x, y, shade)
	for y in range(12, BROW_Y + 1):
		for x in CELL.x:
			var d := Vector2(x + 0.5, y + 0.5) - DOME_C
			if img.get_pixel(x, y).a <= 0.0 and d.length() <= DOME_R + 1.0:
				img.set_pixel(x, y, outline)


## Casquete sobre la cúpula: `extra` píxeles por encima, de la fila `top` a `bottom`.
static func _dome_cap(m: Dictionary, extra: float, top: int, bottom: int) -> void:
	for y in range(top, bottom + 1):
		for x in CELL.x:
			if (Vector2(x + 0.5, y + 0.5) - DOME_C).length() <= DOME_R + extra:
				m[Vector2i(x, y)] = true


## Flequillo: mechones que bajan de `from` a `to` en las columnas dadas (más cortos en los bordes).
static func _fringe(m: Dictionary, from: int, to: int, cols) -> void:
	var list: Array = Array(cols)
	for i in list.size():
		var x: int = list[i]
		var edge := i == 0 or i == list.size() - 1
		for y in range(from, to + (0 if edge else 1)):
			m[Vector2i(x, y)] = true


static func _rect(m: Dictionary, x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			m[Vector2i(x, y)] = true


static func _disc(m: Dictionary, c: Vector2, r: float) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if (Vector2(x + 0.5, y + 0.5) - c).length() <= r:
				m[Vector2i(x, y)] = true


## Pinta una forma de pelo con el sombreado de la lámina y contorno contra el fondo.
## `flat`: pelo al ras (sin brillos, un solo tono con puntitos).
static func _paint_hair(img: Image, m: Dictionary, hair: Color, flat: bool) -> void:
	var light := hair.lightened(0.28)
	var dark := hair.darkened(0.3)
	var outline := hair.darkened(0.75).lerp(Color("1a1024"), 0.35)
	for p: Vector2i in m:
		if p.x < 0 or p.y < 0 or p.x >= CELL.x or p.y >= CELL.y:
			continue
		var up := m.has(p + Vector2i(0, -1))
		var right := m.has(p + Vector2i(1, 0))
		var down := m.has(p + Vector2i(0, 1))
		var c := hair
		if flat:
			c = hair.darkened(0.15) if (p.x + p.y) % 2 == 0 else hair
		elif not right or not down:
			c = dark
		elif not up and p.x < int(DOME_C.x) + 2:
			c = light
		elif (p.x - p.y) % 5 == 0 and up:   # mechones
			c = dark if p.x > int(DOME_C.x) else hair.lightened(0.1)
		img.set_pixelv(p, c)
	for p: Vector2i in m:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var q := p + d
			if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y and not m.has(q) and img.get_pixelv(q).a <= 0.0:
				img.set_pixelv(q, outline)


static func _hair_mask(img: Image) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(0, 27):
		for x in CELL.x:
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and _is_hair_color(c, img, x, y):
				out.append(Vector2i(x, y))
	return out


## ¿Es pelo? Lo que en la base era pelo (se mira el arte original, sin recolorear).
static func _is_hair_color(_c: Color, _img: Image, x: int, y: int) -> bool:
	var base := _layer("base") as Image
	var hex := base.get_pixel(x, y).to_html(false)
	return ROLES.has(hex) and String(ROLES[hex][0]) == "hair"


## Barba: la barbilla y las mejillas bajas, del color del pelo.
static func _beard(img: Image, look: Dictionary) -> void:
	var hair := Color(look.get("beard_color", look.get("hair_color", "2b2118")))
	var base := _layer("base") as Image
	for y in range(27, 30):
		for x in range(21, 37):
			var hex := base.get_pixel(x, y).to_html(false)
			if hex in ["f6c8a0", "c57d71"] and not (y == 27 and x > 24 and x < 33):
				img.set_pixel(x, y, hair if (x + y) % 3 else hair.darkened(0.25))


## Accesorios del creador (si no lleva casco): lentes, lentes de sol y audífonos.
static func _accessory(img: Image, look: Dictionary) -> void:
	var dark := Color("1a1624")
	var accent := Color(look.get("accent_color", "2a2a30"))
	match int(look.get("accessory", 0)):
		1, 2:   # lentes (montura) / de sol (cristal oscuro)
			for eye_x in [24, 32]:
				for x in range(eye_x - 1, eye_x + 3):
					img.set_pixel(x, 25, dark)
					img.set_pixel(x, 28, dark)
				img.set_pixel(eye_x - 1, 26, dark)
				img.set_pixel(eye_x - 1, 27, dark)
				img.set_pixel(eye_x + 2, 26, dark)
				img.set_pixel(eye_x + 2, 27, dark)
				if int(look.get("accessory", 0)) == 2:
					for x in range(eye_x, eye_x + 2):
						img.set_pixel(x, 26, Color("2a2f3e"))
						img.set_pixel(x, 27, Color("3a4258"))
			img.set_pixel(28, 26, dark)
			img.set_pixel(29, 26, dark)
		3:   # audífonos
			for x in range(19, 39):
				img.set_pixel(x, 14 if x > 21 and x < 36 else 16, dark)
			for side_x in [17, 38]:
				for y in range(21, 26):
					for dx in 3:
						img.set_pixel(side_x + dx, y, accent if dx == 1 and y > 21 and y < 25 else dark)

## Un cuadro: la figura movida según la animación, con el arma.
static func frame(body: Image, weapon: Image, anim: String, k: int) -> Image:
	var img := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bob := 0
	var lift_left := 0
	var lift_right := 0
	var shift := 0
	var swing := 0   # 0 en reposo, 1 alzada, 2 tajo, 3 abajo
	match anim:
		"idle":
			bob = [0, 0, 1, 1][k]
		"walk":
			bob = [0, 1, 0, 1][k]
			lift_left = 1 if k == 0 else 0
			lift_right = 1 if k == 2 else 0
		"attack":
			swing = [1, 2, 3, 0][k]
			shift = [0, 1, 1, 0][k]
		"cast":
			bob = [-1, -1][k]
		"hurt":
			shift = -1
			bob = [0, 1][k]
		"dead", "dodge":
			bob = [1, 2][k]
	# Cuerpo de las piernas para arriba, con su balanceo; piernas, cada una con su paso.
	for y in CELL.y:
		for x in CELL.x:
			var c := body.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var q := Vector2i(x + shift, y)
			if y < LEGS_Y:
				q.y += bob
			elif x < CENTER_X:
				q.y -= lift_left
			else:
				q.y -= lift_right
			if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y:
				img.set_pixelv(q, c)
	if weapon != null and anim != "dead":
		_weapon(img, weapon, swing, Vector2i(shift, bob))
	if anim == "dead" and k == 1:
		img = _lay_down(img)
	return img


## El arma en la mano: en reposo como en la lámina; al atacar, alzada, girada en el
## tajo y abajo (girando alrededor del agarre).
static func _weapon(img: Image, weapon: Image, swing: int, offset: Vector2i) -> void:
	for y in CELL.y:
		for x in CELL.x:
			var c := weapon.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var p := Vector2i(x, y) - GRIP
			match swing:
				1:   # alzada: un poco más arriba
					p += Vector2i(0, -3)
				2:   # tajo: girada 90° (apunta al otro lado, a la altura de la mano)
					p = Vector2i(-p.y, p.x)
				3:   # abajo: girada 180°
					p = Vector2i(-p.x, -p.y) + Vector2i(0, 2)
			var q := GRIP + p + offset
			if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y:
				img.set_pixelv(q, c)


## Tumbado: la figura girada 90° sobre los pies.
static func _lay_down(img: Image) -> Image:
	var out := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in CELL.y:
		for x in CELL.x:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var q := Vector2i(FEET.x + 12 - (FEET.y - y), FEET.y - 1 - (x - (FEET.x - 10)) / 2)
			if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y:
				out.set_pixelv(q, c)
	return out
