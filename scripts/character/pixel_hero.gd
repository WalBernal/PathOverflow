class_name PixelHero
## Héroes en pixel art propios (T176): el personaje dentro del servidor, desde el acto I.
## Estilo de RPG diminuto (como los packs de personajes de ~20 píxeles o Final Fantasy
## Tactics), dibujado aquí píxel a píxel: nada copiado de ningún pack.
## - Cabeza (11×10) y torso (8×7) de cada clase son rejillas de píxeles con letras de
##   paleta (HEADS, TORSOS); piernas, brazos, capa y arma se trazan píxel a píxel según
##   la pose de cada cuadro; al final, contorno negro de 1 píxel.
## - Solo de lado, mirando a la derecha (a la izquierda se voltea al dibujar).
## - Los colores del creador tiñen: atuendo (o/O/p y x), detalles (a/A), piel (s/z),
##   pelo (h/H). Lo demás es fijo: metal, oro, cuero, tela blanca y el cian de los
##   «datos» (runas, LEDs, visores).
## La hoja (una fila de cuadros CELL, en el orden de ORDER) se arma al cargar y se
## guarda en caché por apariencia, clase y arma.

const CELL := Vector2i(48, 48)
const FEET := Vector2i(24, 44)
const ORDER := ["idle", "walk", "attack", "cast", "hurt", "dead", "dodge", "channel", "shoot", "type"]
const FRAMES := {"idle": 4, "walk": 8, "attack": 6, "cast": 4, "hurt": 3, "dead": 4, "dodge": 3, "channel": 2, "shoot": 4, "type": 2}
const OUTLINE := Color("0b0a10")
const CLASSES := ["guerrero", "duelista", "exploradora", "hacker", "hechicero", "templario", "full_stack"]

## Colores fijos por letra (los del creador van en `palette`).
const FIXED := {
	"m": "b8c0cc", "M": "6e7888", "w": "eef2f6",
	"g": "e2b84a", "G": "9a7424", "y": "fff0a0",
	"l": "8a5c34", "L": "4f3420",
	"c": "4fe0ff", "C": "2a8aa8",
	"W": "eeeae0", "V": "b8b2a6",
	"r": "ff5050", "k": "0b0a10", "e": "1a1414",
}

## Cabezas, mirando a la derecha (11×10; la cara a la derecha).
const HEADS := {
	# Técnico de Soporte: caballero con yelmo y visor HUD cian, micrófono de diadema.
	"guerrero": [
		"...mmmm....",
		"..mwwmmmM..",
		".mwmmmmmmM.",
		".mmmmmmmmmM",
		".mmmmMkcccc",
		".mmmmMkcccc",
		".MmmmmmmmmM",
		"..MmmmmmmMa",
		"..MMmmmmMa.",
		"...MMMMM...",
	],
	# Tester QA: espadachín con sombrero de ala, pluma y monóculo-lupa.
	"duelista": [
		".....WWV...",
		"....WaWV...",
		"...ooooooo.",
		"...oaaaaao.",
		".ooooooooooo",
		"..hhssssss.",
		"..hhsssCWs.",
		"..hhsssssss",
		"...hzssszs.",
		"....zzzz...",
	],
	# Frontend: capucha y bufanda con la paleta de colores.
	"exploradora": [
		"...ooooo...",
		"..oppoooO..",
		".oppoooooO.",
		".ooOhhhssO.",
		".oOhhsssesO",
		".oOhssssssO",
		".oOOzssssO.",
		"..OOarcgyc.",
		"...Oarcgy..",
		"....OO.....",
	],
	# Ingeniera de Prompts: pícara con capucha, máscara y ojos-LED cian.
	"hacker": [
		"...xxxxx...",
		"..xxpxxxx..",
		".xxpxxxxxx.",
		".xxxxxxssxx",
		".xxxxkkcckx",
		".xxxxxsssxx",
		".xxxxkkkkkk",
		"..xxxkkkkk.",
		"...xxxx....",
		"...........",
	],
	# Científico de Datos: mago con sombrero de punta y una gráfica en runas.
	"hechicero": [
		".......oO..",
		"......ooO..",
		".....ocoO..",
		"....oocooO.",
		"...oocoooO.",
		"ooaaaaaaaoo",
		"..hhsssss..",
		"..hhsssess.",
		"..hzssssss.",
		"...zzzzs...",
	],
	# DevOps: paladín con casco de obra dorado y su LED de estado.
	"templario": [
		"...ggggg...",
		"..gyygggG..",
		".gyggggcgG.",
		".gggggggggG",
		"GGGGGGGGGGG",
		"..hhssssss.",
		"..hhsssess.",
		"..hhssssss.",
		"...zzsssz..",
		"....zzz....",
	],
	# Full Stack: caballero-mago con diadema y gema cian.
	"full_stack": [
		"..hhhhhh...",
		".hhhhhhhh..",
		".hhmmmmcm..",
		".hhhssssss.",
		".hhhsssess.",
		".hhhsssssss",
		"..hhzssss..",
		"...zzzzz...",
		"...........",
		"...........",
	],
}

## Torsos, mirando a la derecha (8×7).
const TORSOS := {
	"guerrero": [
		"mwmmmmmM",
		"mwmooomM",
		"MmmoaomM",
		"MmmooomM",
		"MmmoooMm",
		"lclllcll",
		".OoooOO.",
	],
	"duelista": [
		"WVooWWo.",
		"WooWWWoo",
		"VoaWWWoo",
		"VooaWWoo",
		"VoooaWoo",
		"LlllLlll",
		".OO..OO.",
	],
	"exploradora": [
		"ooopoooo",
		"oOopoolo",
		"oOooolOo",
		"oOoolooo",
		"oOolOooo",
		"LlllLlll",
		".Oo..oO.",
	],
	"hacker": [
		"xxxxxxxx",
		"xLxxxcxx",
		"xLxxxxcx",
		"xLxxxcxx",
		"xLxaxxxx",
		"LLLaLLLL",
		".xx..xx.",
	],
	"hechicero": [
		"oopooooo",
		"oOpocooo",
		"oOpoocoo",
		"oOpooocc",
		"aaaaaaaa",
		"oOoooooo",
		"OOooooOO",
	],
	"templario": [
		"gyggggGG",
		"gyWWWWgG",
		"GgWaWaWG",
		"GgWWaWWG",
		"GgWWWWgG",
		"lllclll.",
		".VWWWWV.",
	],
	"full_stack": [
		"oommmwmo",
		"oOmmmmoo",
		"oOoooooo",
		"oOooocoo",
		"oOoaoooo",
		"lllllcll",
		".OOooOO.",
	],
}

## Por clase: manga, mano, pantalón, botas, capa (largo en filas; 0 = sin capa) y túnica larga.
const BODY := {
	"guerrero": {"sleeve": "M", "hand": "l", "pants": "M", "boots": "L", "cape": 9, "robe": false},
	"duelista": {"sleeve": "W", "hand": "s", "pants": "O", "boots": "L", "cape": 5, "robe": false},
	"exploradora": {"sleeve": "o", "hand": "l", "pants": "O", "boots": "L", "cape": 9, "robe": false},
	"hacker": {"sleeve": "x", "hand": "k", "pants": "x", "boots": "k", "cape": 0, "robe": false},
	"hechicero": {"sleeve": "o", "hand": "s", "pants": "O", "boots": "L", "cape": 0, "robe": true},
	"templario": {"sleeve": "g", "hand": "l", "pants": "G", "boots": "G", "cape": 9, "robe": false},
	"full_stack": {"sleeve": "o", "hand": "l", "pants": "O", "boots": "M", "cape": 8, "robe": false},
}

static var _cache := {}


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
			k = posmod(int(floor(time * 4.0)), n)
		"channel", "type":
			k = posmod(int(floor(time * 6.0)), n)
		_:
			k = clampi(int(t * n), 0, n - 1)
	return first_column(anim) + k


## Hoja (en caché) de una apariencia, su clase y el tipo de arma ("" sin arma).
static func texture(a: Dictionary, cls: String, weapon: String) -> ImageTexture:
	var key := "%s|%s|%s" % [cls, weapon, JSON.stringify(a, "", true)]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(build(a, cls, weapon))
	return _cache[key]


static func build(a: Dictionary, cls: String, weapon: String) -> Image:
	if not HEADS.has(cls):
		cls = "guerrero"
	var pal := palette(a)
	var sheet := Image.create_empty(CELL.x * columns(), CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var col := 0
	for anim in ORDER:
		var n := int(FRAMES[anim])
		for k in n:
			var f := frame(pal, a, cls, weapon, anim, k, n)
			sheet.blit_rect(f, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, 0))
			col += 1
	return sheet


## Paleta de una apariencia: letras del creador + las fijas.
static func palette(a: Dictionary) -> Dictionary:
	var outfit := Color(a.get("outfit_color", "6b2b2b"))
	var accent := Color(a.get("accent_color", "2a2a30"))
	var skin := Color(a.get("skin_tone", "c99a7a"))
	var hair := Color(a.get("hair_color", "2b2118"))
	var pal := {
		"o": outfit, "O": outfit.darkened(0.32), "p": outfit.lightened(0.28), "x": outfit.darkened(0.6),
		"a": accent, "A": accent.darkened(0.3),
		"s": skin, "z": skin.darkened(0.22),
		"h": hair, "H": hair.darkened(0.3),
	}
	for key in FIXED:
		pal[key] = Color(FIXED[key])
	return pal


## Pose de un cuadro: bob (abajo +), lean (adelante +), pies (x, alzado), brazos y arma
## (ángulos en grados: 0 abajo, 90 adelante, 180 arriba), agachado y tumbado.
static func pose(anim: String, k: int, n: int) -> Dictionary:
	var p := {"bob": 0, "lean": 0, "ff": 2, "fl": 0, "bf": -2, "bl": 0, "fa": 25.0, "ba": -15.0, "wa": 150.0, "lying": false}
	match anim:
		"idle":
			p["bob"] = 1 if k >= 2 else 0
		"walk":
			var ph := (k + 0.5) / n * TAU
			var s := sin(ph)
			p["ff"] = roundi(3.0 * s)
			p["bf"] = -roundi(3.0 * s)
			p["fl"] = 1 if cos(ph) > 0.35 else 0
			p["bl"] = 1 if cos(ph) < -0.35 else 0
			p["bob"] = 1 if absf(s) > 0.75 else 0
			p["fa"] = 25.0 - 28.0 * s
			p["ba"] = -15.0 + 28.0 * s
			p["wa"] = 150.0 - 10.0 * s
		"attack":
			var fa: float = [130.0, 170.0, 175.0, 70.0, 35.0, 45.0][k]
			p["fa"] = fa
			p["wa"] = fa + [10.0, 5.0, 0.0, -20.0, -25.0, -10.0][k]
			p["lean"] = [0, -1, -1, 1, 1, 0][k]
			p["ff"] = [2, 2, 2, 3, 3, 2][k]
		"cast":
			p["fa"] = [60.0, 120.0, 150.0, 150.0][k]
			p["ba"] = [40.0, 100.0, 140.0, 140.0][k]
			p["wa"] = p["fa"]
		"hurt":
			p["lean"] = -1
			p["fa"] = 35.0
			p["ba"] = -40.0
			p["bob"] = [0, 1, 0][k]
		"dead":
			p["bob"] = [0, 3, 0, 0][k]
			p["lean"] = [-1, 1, 0, 0][k]
			p["lying"] = k >= 2
			p["fa"] = [40.0, 10.0, 20.0, 20.0][k]
		"dodge":
			p["bob"] = [3, 4, 2][k]
			p["lean"] = [1, 2, 1][k]
			p["ff"] = 3
			p["bf"] = -3
		"channel":
			p["fa"] = 95.0 + k * 5.0
			p["ba"] = 85.0 + k * 5.0
			p["wa"] = 120.0
		"shoot":
			p["fa"] = [70.0, 120.0, 95.0, 80.0][k]
			p["wa"] = p["fa"]
		"type":
			p["fa"] = 70.0 + k * 8.0
			p["ba"] = 62.0 + k * 8.0
			p["wa"] = 150.0
	return p


## Un cuadro: lo de atrás primero (pierna, brazo, capa), luego torso y cabeza, y lo
## de delante (pierna, brazo, arma). Al final, el contorno.
static func frame(pal: Dictionary, a: Dictionary, cls: String, weapon: String, anim: String, k: int, n: int) -> Image:
	var img := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var p := pose(anim, k, n)
	var body: Dictionary = BODY.get(cls, BODY["guerrero"])
	var o := Vector2i(FEET.x, FEET.y)
	var bob := int(p["bob"])
	var lean := int(p["lean"])
	var hip_y := o.y - 7 + bob
	var torso := Vector2i(o.x - 4 + lean, o.y - 14 + bob)
	var head := Vector2i(o.x - 5 + lean, o.y - 23 + bob)
	var back_sh := Vector2i(o.x - 2 + lean, o.y - 12 + bob)
	var front_sh := Vector2i(o.x + 1 + lean, o.y - 12 + bob)
	var col := func(key: String) -> Color: return pal.get(key, Color.MAGENTA)
	# Pierna de atrás, brazo de atrás y capa.
	_leg(img, Vector2i(o.x - 1, hip_y), Vector2i(o.x + int(p["bf"]) - 1, o.y - int(p["bl"])), col.call(body["pants"]).darkened(0.2), col.call(body["boots"]).darkened(0.2))
	_arm(img, back_sh, float(p["ba"]), col.call(body["sleeve"]).darkened(0.25), col.call(body["hand"]).darkened(0.2))
	if int(body["cape"]) > 0:
		var sway := 1 if anim == "walk" and k % 4 < 2 else 0
		for row in int(body["cape"]):
			var y := torso.y + 1 + row
			var w := 2 + row / 4
			for dx in w:
				var x := torso.x - 1 - dx - (sway if row > 4 else 0)
				_px(img, Vector2i(x, y), col.call("O") if dx > 0 else col.call("o").darkened(0.1))
	# Pierna de delante (o la túnica larga).
	if bool(body["robe"]):
		for row in 7:
			var w := 8 + row / 2
			for dx in w:
				var x := torso.x - (w - 8) / 2 + dx
				var c: Color = col.call("o") if dx > 1 and dx < w - 2 else col.call("O")
				if row == 6:
					c = col.call("a")
				_px(img, Vector2i(x, hip_y + row), c)
		_px(img, Vector2i(o.x + int(p["ff"]) + 1, o.y - 1), col.call(body["boots"]))
		_px(img, Vector2i(o.x + int(p["ff"]) + 2, o.y - 1), col.call(body["boots"]))
	else:
		_leg(img, Vector2i(o.x + 1, hip_y), Vector2i(o.x + int(p["ff"]) + 1, o.y - int(p["fl"])), col.call(body["pants"]), col.call(body["boots"]))
	# Torso y cabeza.
	_stamp(img, TORSOS.get(cls, TORSOS["guerrero"]), torso, pal)
	var head_rows: Array = HEADS.get(cls, HEADS["guerrero"]).duplicate()
	if int(a.get("beard", 0)) > 0 and cls in ["duelista", "hechicero", "templario", "full_stack"]:
		head_rows = _with_beard(head_rows)
	_stamp(img, head_rows, head, pal)
	# Brazo de delante con el arma.
	var hand := _arm(img, front_sh, float(p["fa"]), col.call(body["sleeve"]), col.call(body["hand"]))
	if weapon != "" and not anim in ["cast", "channel", "type"]:
		_weapon(img, hand, float(p["wa"]), weapon, pal)
	if bool(p["lying"]):
		img = _lay_down(img, o)
	_outline(img)
	return img


static func _px(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, c)


## Rejilla de letras: cada letra, su color; «.» transparente.
static func _stamp(img: Image, rows: Array, at: Vector2i, pal: Dictionary) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and pal.has(ch):
				_px(img, at + Vector2i(x, y), pal[ch])


## Línea de píxeles (Bresenham) de grosor 1.
static func _line(img: Image, from: Vector2i, to: Vector2i, c: Color) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	var d := to - from
	var steps := maxi(absi(d.x), absi(d.y))
	for i in steps + 1:
		var t := 0.0 if steps == 0 else float(i) / steps
		var q := Vector2i(roundi(from.x + d.x * t), roundi(from.y + d.y * t))
		_px(img, q, c)
		pts.append(q)
	return pts


static func _dir(angle_deg: float) -> Vector2:
	var r := deg_to_rad(angle_deg)
	return Vector2(sin(r), cos(r))


## Pierna de 2 píxeles de la cadera al pie y bota de 3 hacia delante.
static func _leg(img: Image, hip: Vector2i, foot: Vector2i, pants: Color, boot: Color) -> void:
	var ankle := foot + Vector2i(0, -2)
	_line(img, hip, ankle, pants)
	_line(img, hip + Vector2i(1, 0), ankle + Vector2i(1, 0), pants.darkened(0.15))
	for dx in 3:
		_px(img, foot + Vector2i(dx, -1), boot)
		_px(img, foot + Vector2i(dx, 0), boot.darkened(0.2))


## Brazo de 2 píxeles (manga) del hombro a la mano; devuelve la mano.
static func _arm(img: Image, shoulder: Vector2i, angle: float, sleeve: Color, hand_color: Color) -> Vector2i:
	var d := _dir(angle)
	var hand := shoulder + Vector2i(roundi(d.x * 5.0), roundi(d.y * 5.0))
	_line(img, shoulder, hand, sleeve)
	_line(img, shoulder + Vector2i(1, 0), hand + Vector2i(1, 0), sleeve.darkened(0.15))
	_px(img, hand, hand_color)
	_px(img, hand + Vector2i(1, 0), hand_color)
	return hand


## Arma desde la mano hacia `angle`, según su tipo (las de oficio llegan en T177).
static func _weapon(img: Image, hand: Vector2i, angle: float, kind: String, pal: Dictionary) -> void:
	var d := _dir(angle)
	var perp := Vector2(-d.y, d.x)
	var at := func(dist: float, side := 0.0) -> Vector2i: return hand + Vector2i(roundi(d.x * dist + perp.x * side), roundi(d.y * dist + perp.y * side))
	match kind:
		"sword":
			_line(img, at.call(-1.0), at.call(1.0), pal["l"])
			_line(img, at.call(1.0, -1.5), at.call(1.0, 1.5), pal["G"])
			_line(img, at.call(2.0), at.call(10.0), pal["m"])
			_line(img, at.call(2.0, 0.6), at.call(9.0, 0.6), pal["w"])
		"axe":
			_line(img, at.call(-1.0), at.call(9.0), pal["l"])
			for i in 4:
				_line(img, at.call(6.0 + i * 0.7, 0.0), at.call(6.0 + i * 0.7, 3.0), pal["m"] if i < 3 else pal["w"])
		"mace":
			_line(img, at.call(-1.0), at.call(7.0), pal["l"])
			for i in 3:
				_line(img, at.call(7.0 + i * 0.8, -1.5), at.call(7.0 + i * 0.8, 1.5), pal["M"] if i != 1 else pal["m"])
		"dagger":
			_line(img, at.call(-1.0), at.call(1.0), pal["L"])
			_line(img, at.call(2.0), at.call(6.0), pal["m"])
		_:
			_line(img, at.call(-1.0), at.call(8.0), pal["l"])


## Barba: la barbilla (z) en el color del pelo.
static func _with_beard(rows: Array) -> Array:
	var out := []
	for i in rows.size():
		var r: String = rows[i]
		out.append(r.replace("z", "H") if i >= rows.size() - 3 else r)
	return out


## Tumbado (los últimos cuadros de morir): la figura girada sobre los pies, en el suelo.
static func _lay_down(img: Image, feet: Vector2i) -> Image:
	var src := img.duplicate() as Image
	var out := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in CELL.y:
		for x in CELL.x:
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			# (x, y) → girado 90° hacia atrás: la cabeza a la izquierda, la espalda en el suelo.
			var q := Vector2i(feet.x + 10 - (feet.y - y), feet.y - 1 - (x - (feet.x - 7)))
			_px(out, q, c)
	return out


## Contorno negro de 1 píxel alrededor de todo lo dibujado.
static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	for y in CELL.y:
		for x in CELL.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < CELL.x and q.y < CELL.y and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break
