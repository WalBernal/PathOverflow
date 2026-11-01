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
## Bandas de las capas de la lámina (las mismas que corta tools/import_hero_art.gd).
const TORSO_ROWS := Vector2i(28, 42)
const LEGS_ROWS := Vector2i(43, 55)
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
## (T177: el arma en la mano es la de su base, WeaponArt; el bastón de C queda para un arma mágica.)

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
	look["eq_weapon"] = String(equipped.get("weapon", ""))   # la base del arma (T177)
	return look


## Lo que lleva puesto un guardado (ranura → id de base), para la lista de personajes.
static func equipped_of_save(data: Dictionary) -> Dictionary:
	var out := {}
	var equip: Dictionary = data.get("inventory", {}).get("equipment", {})
	for slot in LOOKS.keys() + ["weapon"]:
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


## Direcciones de la hoja (una fila cada una): de frente, de espaldas y de lado
## (tres cuartos, mirando a la derecha; a la izquierda se voltea al dibujar).
enum Dir { FRONT, BACK, SIDE }
const DIRS := 3


## Fila de la hoja (y si hay que voltear) para hacia dónde mira.
static func dir_for(facing: Vector2) -> Array:
	if facing.y < -0.5 and absf(facing.x) < 0.75:
		return [Dir.BACK, false]
	if absf(facing.x) > 0.6 and absf(facing.y) < 0.75:
		return [Dir.SIDE, facing.x < 0.0]
	return [Dir.FRONT, false]


## Hoja completa: una fila por dirección.
static func build(look: Dictionary, weapon: String) -> Image:
	# El arma de su base (T177) o, si no se sabe, la de su tipo.
	var weapon_img: Image = WeaponArt.layer(WeaponArt.art_for(String(look.get("eq_weapon", "")), weapon), CELL, GRIP) if weapon != "" else null
	var sheet := Image.create_empty(CELL.x * columns(), CELL.y * DIRS, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for dir in DIRS:
		# De lado, el perfil de verdad (T182, StudentProfile); de frente y de espaldas, la plantilla.
		var body := StudentProfile.body(look) if dir == Dir.SIDE else figure(look, dir)
		var col := 0
		for anim in ORDER:
			var n := int(FRAMES[anim])
			for k in n:
				var f := StudentProfile.frame(body, look, weapon_img, anim, k) if dir == Dir.SIDE else frame(body, weapon_img, anim, k)
				sheet.blit_rect(f, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, dir * CELL.y))
				col += 1
	return sheet


## El personaje quieto, con su apariencia y su equipo (sin el arma), en una dirección.
static func figure(look: Dictionary, dir := Dir.FRONT) -> Image:
	var img := (_layer("base") as Image).duplicate() as Image
	_recolor(img, look)
	var helmet_eq := String(look.get("eq_helmet", ""))
	var body_eq := String(look.get("eq_body", ""))
	var boots_eq := String(look.get("eq_boots", ""))
	if helmet_eq == "":   # con casco o capucha, el peinado no asoma
		_hair_style(img, look)
	if int(look.get("beard", 0)) > 0 and dir != Dir.BACK:
		_beard(img, look)
	if helmet_eq == "" and dir == Dir.BACK:
		_back_of_head(img, look)
	if body_eq != "":
		_over(img, _layer("torso_" + body_eq))
		if body_eq in ROBES:
			_over(img, _layer("legs_" + body_eq))
	elif dir == Dir.BACK:
		_back_of_hoodie(img, look)
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
		if dir == Dir.BACK:
			_back_of_helmet(img, helmet)
	elif int(look.get("accessory", 0)) > 0:
		if dir != Dir.BACK or int(look.get("accessory", 0)) == 3:   # de espaldas, solo los audífonos
			_accessory(img, look, 1 if dir == Dir.SIDE else 0)
	return img


## La cara de la lámina: piel, ojos, cejas y nariz (filas de la cabeza).
const FACE_FIXED := ["22162c", "ffffff", "32181c", "aa605c"]


static func _face_mask() -> Array[Vector2i]:
	var base := _layer("base") as Image
	var out: Array[Vector2i] = []
	for y in range(14, 30):
		for x in range(18, 40):
			var hex := base.get_pixel(x, y).to_html(false)
			if hex in FACE_FIXED or (ROLES.has(hex) and String(ROLES[hex][0]) in ["skin", "eyes", "brow", "hair_skin"]):
				out.append(Vector2i(x, y))
	return out


## De espaldas: la cabeza es pelo (o pelo al ras en los rapados) y abajo asoma la nuca.
const SHORT_BACK := [0, 3, 8, 10]
const LONG_BACK := {2: 33, 9: 29, 11: 31, 14: 27, 13: 29, 7: 26, 12: 26}


static func _back_of_head(img: Image, look: Dictionary) -> void:
	var style := int(look.get("hair", 1))
	var hair := Color(look.get("hair_color", "2b2118"))
	var skin := Color(look.get("skin_tone", "c99a7a"))
	if style in SHORT_BACK:
		hair = hair.lerp(skin, 0.4)
	var outline := hair.darkened(0.75).lerp(Color("1a1024"), 0.35)
	var base := _layer("base") as Image
	var neck := _tone(Color("c57d71"), "skin", {"skin": skin})
	for p: Vector2i in _face_mask():
		var hex := base.get_pixel(p.x, p.y).to_html(false)
		var c := hair
		if hex == "4a2d3c":
			c = outline
		elif p.y >= 28:
			c = neck
		elif p.y >= 26 or p.x > 33:
			c = hair.darkened(0.25)
		elif p.y < 19 and p.x < 26 and (p.x + p.y) % 3 == 0:
			c = hair.lightened(0.25)
		img.set_pixelv(p, c)
	if LONG_BACK.has(style):   # el pelo largo cae por la espalda
		for y in range(26, int(LONG_BACK[style]) + 1):
			for x in range(22, 36):
				var edge := x == 22 or x == 35 or y == int(LONG_BACK[style])
				img.set_pixel(x, y, outline if edge else (hair.darkened(0.2) if (x + y) % 4 == 0 else hair))


## De espaldas con casco: donde iba la cara (visor, gafas, la cara del mago) va su color.
static func _back_of_helmet(img: Image, helmet: Image) -> void:
	var fill := Color(0, 0, 0, 0)
	# (de un lado del casco: en el centro de arriba están el penacho o la gema)
	for p in [Vector2i(21, 18), Vector2i(36, 18), Vector2i(24, 16), Vector2i(28, 12)]:
		if helmet.get_pixelv(p).a > 0.0:
			fill = helmet.get_pixelv(p)
			break
	if fill.a <= 0.0:
		return
	for p: Vector2i in _face_mask():
		if p.y < 28 and img.get_pixelv(p).a > 0.0:
			img.set_pixelv(p, fill.darkened(0.12) if p.y > 24 else fill)


## La sudadera por detrás: sin la camisa ni el gafete, con la capucha caída en la nuca.
static func _back_of_hoodie(img: Image, look: Dictionary) -> void:
	var outfit := Color(look.get("outfit_color", "2b4a6b"))
	var mid := _tone(Color("243278"), "outfit", {"outfit": outfit})
	var dark := _tone(Color("1a1e52"), "outfit", {"outfit": outfit})
	var base := _layer("base") as Image
	for y in range(29, 43):
		for x in range(18, 40):
			var hex := base.get_pixel(x, y).to_html(false)
			if hex in ["ececf0", "aeadc0", "b6b4c8", "6c6a84", "28f0e6"]:
				img.set_pixel(x, y, mid)
	for y in range(29, 33):   # la capucha
		for x in range(24 - (y - 29), 34 + (y - 29)):
			img.set_pixel(x, y, dark if y == 32 or x == 24 - (y - 29) or x == 33 + (y - 29) else mid.lightened(0.08))


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
## sobre la cabeza calva de la plantilla (la cúpula de DOME) con las mismas reglas que
## ese pelo: casquete con volumen, flequillo de mechones en punta (la frente asoma entre
## ellos), mechones laterales, un brillo en arco arriba a la izquierda, líneas de mechón
## que salen de la coronilla y contorno contra el fondo.
const DOME_C := Vector2(28.5, 24.0)
const DOME_R := 9.8
const BROW_Y := 24
const CROWN := Vector2(28.5, 7.0)


static func _hair_style(img: Image, look: Dictionary) -> void:
	var style := int(look.get("hair", 1))
	if style == 1:
		return
	var hair := Color(look.get("hair_color", "2b2118"))
	var skin := Color(look.get("skin_tone", "c99a7a"))
	var tie := Color(look.get("accent_color", "2fd0a0"))
	_bald(img, skin)
	var h := Hair.new()
	match style:
		0:   # rapado: al ras de la cúpula, sin brillo
			h.cap(0.7, 13, 19)
			h.flat = true
		2:   # largo: raya al medio, flequillo abierto y mechones hasta los hombros
			h.cap(2.0, 11, 20)
			h.locks([[20.5, 4, 2.5], [23.0, 3, 2.0], [34.0, 3, 2.0], [36.5, 4, 2.5]], 19)
			h.side(18, 20, 34, 3)
			h.side(39, 20, 34, 3)
			h.part(28)
		3:   # cresta: lados rapados y una cresta de puntas
			h.stubble(0.7, 13, 20)
			h.spikes([[26.0, 13, 2.5], [28.5, 6, 3.0], [31.0, 12, 2.5], [28.5, 15, 3.5]])
		4:   # moño: recogido, con mechones sueltos en las sienes
			h.cap(1.2, 13, 19)
			h.disc(Vector2(28.5, 10.5), 3.7)
			h.locks([[20.5, 5, 1.6], [36.5, 5, 1.6]], 19)
			h.ties.append(Rect2i(26, 13, 6, 1))
		5:   # hacia atrás: volumen alto, frente despejada y patillas
			h.cap(2.6, 10, 18)
			h.side(19, 18, 23, 2)
			h.side(38, 18, 23, 2)
		6:   # afro: grande y rizado
			h.disc(Vector2(28.5, 16.5), 12.5)
			h.carve_face(21)
			h.curly = true
		7:   # coleta: flequillo de lado y la coleta por la derecha
			h.cap(1.6, 12, 20)
			h.locks([[21.0, 4, 2.5], [24.5, 3, 2.5], [28.0, 2, 2.0]], 19)
			h.tail(Vector2i(40, 16), 17, 3)
			h.ties.append(Rect2i(39, 17, 3, 1))
		8:   # rapado lateral: lados rapados y el pelo de arriba caído a la izquierda
			h.stubble(0.7, 15, 21)
			h.cap(2.4, 10, 17)
			h.locks([[20.0, 6, 2.5], [23.0, 5, 2.5], [26.0, 3, 2.0]], 17)
		9:   # melena con flequillo recto, hasta la barbilla
			h.cap(2.0, 11, 20)
			h.locks([[20.5, 3, 1.6], [23.5, 3, 1.6], [26.5, 3, 1.6], [29.5, 3, 1.6], [32.5, 3, 1.6], [35.5, 3, 1.6]], 20)
			h.side(18, 20, 30, 3)
			h.side(39, 20, 30, 3)
		10:   # entradas: nacimiento en «M» y las sienes despejadas
			h.cap(1.4, 12, 18)
			h.locks([[28.5, 3, 2.0]], 18)
			h.recede(18)
		11:   # ondulado: de lado y con ondas hasta los hombros
			h.cap(2.2, 11, 20)
			h.locks([[21.0, 4, 2.6], [24.5, 3, 2.4]], 19)
			h.side(18, 20, 32, 3, true)
			h.side(39, 20, 32, 3, true)
			h.part(31)
		12:   # dos coletas con lazos
			h.cap(1.6, 12, 20)
			h.locks([[22.0, 3, 2.2], [25.5, 3, 2.2], [31.5, 3, 2.2], [35.0, 3, 2.2]], 19)
			h.tail(Vector2i(16, 16), 15, 3)
			h.tail(Vector2i(41, 16), 15, 3)
			h.ties.append(Rect2i(15, 17, 3, 1))
			h.ties.append(Rect2i(40, 17, 3, 1))
		13:   # trenzas: raya al medio y dos trenzas a los hombros
			h.cap(1.8, 12, 20)
			h.part(28)
			h.braid(Vector2i(19, 20), 15)
			h.braid(Vector2i(37, 20), 15)
			h.ties.append(Rect2i(18, 35, 3, 1))
			h.ties.append(Rect2i(36, 35, 3, 1))
		14:   # flequillo lateral: un mechón largo que cae sobre un ojo
			h.cap(2.0, 11, 20)
			h.locks([[33.0, 8, 3.2], [36.0, 7, 2.4], [24.0, 3, 2.0]], 19)
			h.side(18, 20, 26, 2)
			h.side(39, 20, 28, 2)
		15:   # rizos cortos
			h.cap(2.4, 10, 19)
			h.disc(Vector2(21.0, 19.0), 3.0)
			h.disc(Vector2(36.0, 19.0), 3.0)
			h.curly = true
	h.paint(img, hair, tie)


## Una forma de pelo y cómo sombrearla (las piezas se suman en `cells`).
class Hair:
	## Cabeza sobre la que se peina (T182: la de perfil tiene la suya).
	var center := DOME_C
	var radius := DOME_R
	var crown := CROWN
	var cells := {}   # Vector2i → true
	var stub := {}    # pelo al ras (lados rapados)
	var locks_px := {}   # Vector2i → 0 (lado claro del mechón) / 1 (lado oscuro)
	var gaps := {}    # raya del peinado (piel)
	var ties: Array[Rect2i] = []
	var flat := false
	var curly := false

	func _add(p: Vector2i) -> void:
		if p.x >= 0 and p.y >= 0 and p.x < CELL.x and p.y < CELL.y:
			cells[p] = true

	## Casquete: la cúpula con `extra` píxeles de volumen, de la fila `top` a `bottom`.
	func cap(extra: float, top: int, bottom: int) -> void:
		for y in range(top, bottom + 1):
			for x in CELL.x:
				var d := Vector2(x + 0.5, y + 0.5) - center
				# Más volumen arriba que a los lados (como el pelo de la lámina).
				if d.length() <= radius + extra * clampf(-d.y / radius + 0.35, 0.35, 1.0):
					_add(Vector2i(x, y))

	func stubble(extra: float, top: int, bottom: int) -> void:
		for y in range(top, bottom + 1):
			for x in CELL.x:
				if (Vector2(x + 0.5, y + 0.5) - center).length() <= radius + extra:
					stub[Vector2i(x, y)] = true

	## Mechones en punta: [x del centro, largo, medio ancho], desde la fila `from`.
	func locks(list: Array, from: int) -> void:
		for l in list:
			var cx: float = l[0]
			var length: int = l[1]
			var w: float = l[2]
			for k in length + 1:
				var half := w * (1.0 - float(k) / (length + 1))
				for x in range(int(floor(cx - half)), int(ceil(cx + half))):
					var p := Vector2i(x, from + k)
					_add(p)
					locks_px[p] = 0 if x + 0.5 < cx else 1

	## Mechón lateral de `width` del borde de la cara de la fila `from` a `to` (en punta).
	func side(x: int, from: int, to: int, width: int, wavy := false) -> void:
		var dir := 1 if x < center.x else -1
		for y in range(from, to + 1):
			var w := width if y < to - 1 else maxi(1, width - (y - to + 2))
			var wave := (1 if (y / 3) % 2 == 0 else 0) * (-dir) if wavy else 0
			for i in w:
				_add(Vector2i(x + i * dir + wave, y))

	## Raya del peinado en la columna `x` (la piel asoma en la frente).
	func part(x: int) -> void:
		for y in range(17, 21):
			gaps[Vector2i(x, y)] = true

	func spikes(list: Array) -> void:
		for s in list:
			var cx: float = s[0]
			var tip: int = s[1]
			var w: float = s[2]
			for y in range(tip, 21):
				var half := w * clampf(float(y - tip + 1) / 5.0, 0.2, 1.0)
				for x in range(int(floor(cx - half)), int(ceil(cx + half))):
					_add(Vector2i(x, y))

	func disc(c: Vector2, r: float) -> void:
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				if (Vector2(x + 0.5, y + 0.5) - c).length() <= r:
					_add(Vector2i(x, y))

	## Quita el pelo de delante de la cara (afro) de la fila `from` para abajo.
	func carve_face(from: int) -> void:
		for p: Vector2i in cells.keys():
			if p.y >= from and p.x >= 20 and p.x <= 37:
				cells.erase(p)
		for p: Vector2i in cells.keys():
			if p.y > 26:
				cells.erase(p)

	## Nacimiento en «M»: fuera el pelo de las sienes.
	func recede(y0: int) -> void:
		for p: Vector2i in cells.keys():
			if p.y >= y0 - 1 and ((p.x >= 21 and p.x <= 25) or (p.x >= 32 and p.x <= 36)):
				cells.erase(p)

	## Coleta: cae desde `top` `length` filas, más fina al final.
	func tail(top: Vector2i, length: int, width: int) -> void:
		for k in length:
			var w := width if k < length - 4 else maxi(1, width - (k - length + 5))
			var sway := 1 if k > length / 2 else 0
			for i in w:
				_add(Vector2i(top.x - w / 2 + i + (sway if top.x > center.x else -sway), top.y + k))

	## Trenza: eslabones de 3 píxeles que alternan.
	func braid(top: Vector2i, length: int) -> void:
		for k in length:
			var off := 1 if (k / 2) % 2 == 0 else 0
			for i in 3:
				var p := Vector2i(top.x + i - 1 + off - 1 + 1, top.y + k)
				_add(p)
				locks_px[p] = 1 if (k % 2 == 1 and i == 2) else 0

	func paint(img: Image, hair: Color, tie: Color) -> void:
		var light := hair.lightened(0.28)
		var shine := hair.lightened(0.5)
		var dark := hair.darkened(0.28)
		var deep := hair.darkened(0.45)
		var outline := hair.darkened(0.75).lerp(Color("1a1024"), 0.35)
		var stubble := hair.lerp(img.get_pixel(int(center.x), BROW_Y - 2), 0.4)
		for p: Vector2i in stub:
			if not cells.has(p):
				img.set_pixelv(p, stubble.darkened(0.12) if (p.x + p.y) % 2 == 0 else stubble)
		for p: Vector2i in gaps:
			cells.erase(p)
		for p: Vector2i in cells:
			var up := cells.has(p + Vector2i(0, -1))
			var down := cells.has(p + Vector2i(0, 1))
			var right := cells.has(p + Vector2i(1, 0))
			var r := (Vector2(p) + Vector2(0.5, 0.5) - center).length()
			var c := hair
			if flat:
				c = hair.darkened(0.15) if (p.x + p.y) % 2 == 0 else hair
			elif curly:
				# Rizos en racimos de 3×3: brillo arriba a la izquierda, sombra abajo a la derecha.
				var cell := Vector2i(p.x / 3, (p.y + (p.x / 3) % 2) / 3)
				var local := Vector2i(p.x % 3, (p.y + (p.x / 3) % 2) % 3)
				c = hair
				if local == Vector2i(0, 0):
					c = light
				elif local == Vector2i(1, 0) and (cell.x + cell.y) % 2 == 0:
					c = light
				elif local == Vector2i(2, 2) or (local == Vector2i(1, 2) and (cell.x + cell.y) % 2 == 1):
					c = dark
				if p.y < 12 and local == Vector2i(0, 0):
					c = shine
				if not down or not right:
					c = deep
			elif locks_px.has(p):
				c = light if int(locks_px[p]) == 0 else dark
				if not down:
					c = deep
			elif not down or not right:
				c = dark
			elif r > radius - 1.5 and r < radius + 0.6 and p.x < int(center.x) + 3 and p.y < 19:
				# Brillo en arco, con un punto más claro cada tres píxeles.
				c = shine if (p.x + p.y) % 3 == 0 else light
			elif not up and p.x < int(center.x):
				c = light
			else:
				# Líneas de mechón que salen de la coronilla.
				var a := atan2(p.y + 0.5 - crown.y, p.x + 0.5 - crown.x)
				if p.y > 11 and fmod(a * 7.0 / PI + 10.0, 1.0) < 0.14:
					c = dark
			img.set_pixelv(p, c)
		for p: Vector2i in cells:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var q := p + d
				if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y and not cells.has(q) and img.get_pixelv(q).a <= 0.0:
					img.set_pixelv(q, outline)
		for t in ties:
			for y in range(t.position.y, t.end.y):
				for x in range(t.position.x, t.end.x):
					img.set_pixel(x, y, tie)


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
				# Sombra solo a la derecha y abajo, como la cara de la lámina.
				img.set_pixel(x, y, shade if d.x > DOME_R - 3.0 and y >= 19 else skin)
			elif y > BROW_Y and absf(d.x) < DOME_R - 0.5:   # las sienes (la sombra del pelo en la lámina)
				img.set_pixel(x, y, shade if d.x > 0.0 else skin)
	for y in range(12, BROW_Y + 1):
		for x in CELL.x:
			var d := Vector2(x + 0.5, y + 0.5) - DOME_C
			if img.get_pixel(x, y).a <= 0.0 and d.length() <= DOME_R + 1.0:
				img.set_pixel(x, y, outline)


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
## off: los lentes se corren con la cara cuando mira de lado (T181).
static func _accessory(img: Image, look: Dictionary, off := 0) -> void:
	var dark := Color("1a1624")
	var accent := Color(look.get("accent_color", "2a2a30"))
	match int(look.get("accessory", 0)):
		1, 2:   # lentes: montura alrededor de cada ojo (que se ve entero en los claros)
			var sun := int(look.get("accessory", 0)) == 2
			# Los de sol, con la montura del color de los detalles (se distingue del cristal).
			var frame: Color = accent.lightened(0.1) if sun else Color("241c2c")
			var lens_top := Color("2c3550")
			for lens_x in [23 + off, 31 + off]:   # cada cristal: columnas lens_x..lens_x+4, filas 25..29
				for x in range(lens_x, lens_x + 5):
					img.set_pixel(x, 25, frame)
					img.set_pixel(x, 29, frame)
				for y in range(26, 29):
					img.set_pixel(lens_x, y, frame)
					img.set_pixel(lens_x + 4, y, frame)
					for x in range(lens_x + 1, lens_x + 4):
						if sun:   # cristal oscuro con degradado
							img.set_pixel(x, y, lens_top.darkened(0.2 * (y - 26)))
						elif img.get_pixel(x, y).is_equal_approx(img.get_pixel(28, 27)):
							img.set_pixel(x, y, img.get_pixel(x, y).lightened(0.12))   # el cristal claro, sobre la piel
				# Destello en el borde de fuera de cada cristal.
				var glint_x: int = lens_x + 1 if lens_x < 28 + off else lens_x + 3
				img.set_pixel(glint_x, 26, Color(1, 1, 1, 0.9) if not sun else Color("9fb0d8"))
				if sun:
					img.set_pixel(glint_x + (1 if lens_x < 28 + off else -1), 27, Color("5a6a94"))
			# Puente y patillas hasta las orejas.
			for x in range(28 + off, 31 + off):
				img.set_pixel(x, 26, frame)
			for x in range(20 + off, 23 + off):
				img.set_pixel(x, 26, frame)
			for x in range(36 + off, 38 + off):
				img.set_pixel(x, 26, frame)
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
