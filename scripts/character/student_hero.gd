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


## Peinados del creador sobre el pelo de la lámina (corto y en punta = el de la lámina).
static func _hair_style(img: Image, look: Dictionary) -> void:
	var style := int(look.get("hair", 1))
	if style == 1:
		return
	var hair := Color(look.get("hair_color", "2b2118"))
	var skin := Color(look.get("skin_tone", "c99a7a"))
	var mask := _hair_mask(img)
	var outline := hair.darkened(0.75).lerp(Color("1a1024"), 0.35)
	var stubble := hair.lerp(skin, 0.45)
	match style:
		0, 8:   # rapado / rapado lateral: sin puntas; el resto, pelo al ras
			for p: Vector2i in mask:
				var keep := style == 8 and p.x >= 24 and p.x <= 33
				if p.y < 16 and not keep:
					img.set_pixelv(p, Color(0, 0, 0, 0))
				elif not keep:
					img.set_pixelv(p, stubble if img.get_pixelv(p).v > outline.v + 0.05 else outline)
			_close_top(img, outline)
		3:   # cresta: solo el centro alto; los lados, rapados
			for p: Vector2i in mask:
				if p.x < 25 or p.x > 32:
					if p.y < 16:
						img.set_pixelv(p, Color(0, 0, 0, 0))
					else:
						img.set_pixelv(p, stubble if img.get_pixelv(p).v > outline.v + 0.05 else outline)
			_close_top(img, outline)
		4:   # moño: sin puntas y un moño arriba
			for p: Vector2i in mask:
				if p.y < 16:
					img.set_pixelv(p, Color(0, 0, 0, 0))
			_close_top(img, outline)
			_blob(img, Vector2i(CENTER_X, 13), 3, hair, outline)
		5, 10:   # hacia atrás / entradas: la frente despejada
			for p: Vector2i in mask:
				if p.y >= 20 and p.y <= 25 and p.x >= 22 and p.x <= 35:
					img.set_pixelv(p, skin)
		6:   # afro: el pelo crece hacia fuera
			_grow(img, mask, 2, hair, outline, 26)
		2, 9:   # largo / melena: mechones hasta los hombros
			for side in [-1, 1]:
				var x0 := 19 if side < 0 else 37
				for y in range(20, 34):
					for dx in 2:
						var x: int = x0 + dx * side
						if img.get_pixel(x, y).a <= 0.0 or y < 30:
							img.set_pixel(x, y, hair if dx == 0 else hair.darkened(0.25))
					img.set_pixel(x0 + 2 * side, y, outline)
		7:   # coleta: cae por un lado
			for y in range(16, 30):
				img.set_pixel(39, y, hair)
				img.set_pixel(40, y, hair.darkened(0.25))
				img.set_pixel(41, y, outline)


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


## Cierra con contorno la parte de arriba de la cabeza tras quitar las puntas.
static func _close_top(img: Image, outline: Color) -> void:
	for x in CELL.x:
		for y in range(0, 27):
			if img.get_pixel(x, y).a > 0.0:
				if y > 0:
					img.set_pixel(x, y - 1, outline)
				break


static func _blob(img: Image, center: Vector2i, r: int, color: Color, outline: Color) -> void:
	for y in range(center.y - r - 1, center.y + r + 2):
		for x in range(center.x - r - 1, center.x + r + 2):
			var d := Vector2(x - center.x, y - center.y).length()
			if d <= r:
				img.set_pixel(x, y, color.lightened(0.2) if (x < center.x and y < center.y) else color)
			elif d <= r + 1 and img.get_pixel(x, y).a <= 0.0:
				img.set_pixel(x, y, outline)


static func _grow(img: Image, mask: Array[Vector2i], steps: int, color: Color, outline: Color, max_y: int) -> void:
	var cur := {}
	for p in mask:
		cur[p] = true
	for s in steps:
		var add := {}
		for p: Vector2i in cur:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var q := p + d
				if q.y < max_y and q.x >= 0 and q.x < CELL.x and q.y >= 0 and img.get_pixelv(q).a <= 0.0 and not cur.has(q):
					add[q] = true
		for q: Vector2i in add:
			cur[q] = true
			img.set_pixelv(q, color.darkened(0.1 * s))
	for p: Vector2i in cur:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var q := p + d
			if q.x >= 0 and q.y >= 0 and q.x < CELL.x and img.get_pixelv(q).a <= 0.0:
				img.set_pixelv(q, outline)


## Barba: la barbilla y las mejillas bajas, del color del pelo.
static func _beard(img: Image, look: Dictionary) -> void:
	var hair := Color(look.get("beard_color", look.get("hair_color", "2b2118")))
	var base := _layer("base") as Image
	for y in range(27, 30):
		for x in range(21, 37):
			var hex := base.get_pixel(x, y).to_html(false)
			if hex in ["f6c8a0", "c57d71"] and not (y == 27 and x > 24 and x < 33):
				img.set_pixel(x, y, hair if (x + y) % 3 else hair.darkened(0.25))


## Accesorios del creador (si no lleva casco): lentes, lentes de sol, audífonos, gorra, gorro.
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
		4, 5:   # gorra / gorro de lana: cubre la parte de arriba del pelo
			var cap := accent if int(look.get("accessory", 0)) == 4 else accent.lightened(0.15)
			for y in range(10, 20):
				for x in range(19, 39):
					var inside := y >= 14 or (x >= 22 + (14 - y) and x <= 35 - (14 - y))
					if inside:
						img.set_pixel(x, y, cap.darkened(0.2) if y == 19 or x == 19 or x == 38 else cap)
			if int(look.get("accessory", 0)) == 4:
				for x in range(26, 42):
					img.set_pixel(x, 20, cap.darkened(0.3))


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
