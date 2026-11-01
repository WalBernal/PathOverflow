class_name WeaponArt
## El arma que lleva el alumno (T177): un sprite propio por base de arma, en pixel
## art con el estilo de la lámina (tres tonos y contorno oscuro), mirando hacia arriba
## con el agarre abajo. StudentHero lo pone en la mano (de frente, de espaldas y de
## lado) y lo gira en el tajo. Sin base conocida, el de su tipo (DEFAULT).
## Rejillas: una letra por píxel (PALETTE), «.» vacío; GRIPS dice dónde va la mano.

const PALETTE := {
	"w": "eef2f6", "m": "b8c0cc", "M": "6e7888",          # metal: brillo, medio, sombra
	"l": "8a5c34", "L": "4f3420",                          # madera
	"g": "e2b84a", "G": "9a7424",                          # latón
	"c": "4fe0ff", "C": "2a8aa8",                          # luz de datos
	"u": "a0522d",                                         # óxido
	"r": "e04848", "R": "8a2020",                          # rojo
	"k": "d8dce6", "K": "8a90a0", "B": "2a2833",           # teclas, plástico oscuro
	"y": "f2c230", "Y": "b08a20", "p": "ff6ad5", "b": "4b8bd6", "W": "f4f4f4",
	"P": "e8d8a8", "Q": "b09a68",                          # papel
	"v": "5cbf5a", "V": "2e7d32",                          # hojas
}
const OUTLINE := Color("1a1624")

const ART := {
	# --- Espadas ---
	"espada_oxidada": ["..w..", ".wmM.", ".wmM.", ".umM.", ".wuM.", ".wmM.", ".wmu.", ".wmM.", "GgggG", "..L..", "..l..", "..G.."],
	"espada_bastarda": ["..w..", ".wmM.", ".wmM.", ".wmM.", ".wmM.", ".wmM.", ".wmM.", ".wmM.", ".wmM.", "gGgGg", "..L..", "..l..", "..L..", "..g.."],
	"estoque_del_compilador": [".w.", ".m.", ".c.", ".m.", ".c.", ".m.", ".m.", ".M.", "gGg", "GlG", ".l.", ".g."],
	"sable_de_fibra_optica": [".c.", "cwc", "cwc", "cwc", "cwc", "cwc", "cwc", "CwC", "MmM", ".B.", ".M.", ".B."],
	# --- Hachas ---
	"hacha_de_lenador": [".wm..", "wmmL.", "wmMl.", "wmMl.", ".MMl.", "...l.", "...l.", "...l.", "...L.", "...l.", "...l.", "...L."],
	"hacha_de_guerra": ["ww.l.ww", "wmMlMmw", "wmMlMmw", "wmMlMmw", ".wMlMw.", "...l...", "...l...", "...L...", "...l...", "...l...", "...L..."],
	"hacha_de_despido_masivo": [".wr...", "wrrRl.", "wrrRl.", "wrrRl.", "wrrRl.", ".wRRl.", "....l.", "....l.", "....L.", "....l.", "....l.", "....L."],
	# --- Mazas (las de oficio: martillo de compilación y teclados) ---
	"maza_de_depuracion": [".m.m.", "mwMmM", "mMmMm", ".MmM.", "..l..", "..l..", "..l..", "..L..", "..l..", "..l.."],
	"martillo_de_compilacion": ["wwmmM", "wcmMM", "wmmMM", "..l..", "..l..", "..l..", "..L..", "..l..", "..l..", "..L.."],
	"teclado_mecanico": ["BBBBBBB", "BkKkKkB", "BKkKkKB", "BkkkkkB", "BBBBBBB", "...B...", "...B...", "...B...", "...B...", "...B...", "...B..."],
	"teclado_rgb": ["BBBBBBB", "BrycpbB", "BpbrycB", "BcccccB", "BBBBBBB", "...B...", "...B...", "...B...", "...B...", "...B...", "...B..."],
	# --- Dagas ---
	"daga_de_root": [".w.", "wmM", "wmM", "wmM", "GgG", ".l.", ".L."],
	"punal_de_dia_cero": [".r.", "BrB", "BrB", "BRB", "GgG", ".L.", ".l."],
	"cuchilla_de_carton": [".w.", ".m.", ".w.", ".m.", "yYy", "yYy", "yYy"],
	"navaja_multiherramienta": [".w.", ".m.", ".m.", "rRr", "rWr", "rRr"],
	# --- Lo que llevan los NPC (T178; el `gear` de su apariencia, como en T162) ---
	"prop_cafe": ["WllW.", "WWWWW", "WWW.W", "WWWWW", "KWWK."],
	"prop_monitor": ["BBBBBBB", "BcccccB", "BcCccCB", "BcccccB", "BBBBBBB", "...B...", ".BBBBB."],
	"prop_laptop": ["BBBBBB", "BccccB", "BcCccB", "BBBBBB", "KkkkkK"],
	"prop_maleta": ["..gg..", ".g..g.", "LllllL", "lllgll", "llllll", "LLLLLL"],
	"prop_pantalla": ["BBBBB", "BcccB", "BCcCB", "BcccB", "BCCCB", "BBBBB"],
	"prop_mapa": ["LPPPPL", ".PQPP.", ".PPQP.", ".QPPP.", "LPPPPL"],
	"prop_tablas": ["bbbbb", "WbWbW", "bbbbb", "WbWbW", "bbbbb", "WbWbW"],
	"prop_tablero": [".KK.", "lWWl", "lWbl", "lWWl", "lWbl", "llll"],
	"prop_bolsa": ["..K..", ".KKK.", "KKKKK", "KKBKK", "KKKKK", ".KKK."],
	"prop_cartel": ["WWWWWWW", "WrrWrrW", "WWWWWWW", "WrrrrWW", "WWWWWWW", "...l...", "...l...", "...l...", "...L...", "...l..."],
	"prop_planos": [".b.", "bWb", "bbb", "bWb", "bbb", "bWb", "bbb"],
	"prop_rosa": [".r.", "rRr", ".r.", ".v.", "vV.", ".V.", ".V."],
	"prop_pila": [".mmm.", "mwmmM", "mmmMM", ".MMM."],
}
## Fila de la mano en cada rejilla (columna: la del mango, la del centro salvo las hachas).
const GRIPS := {
	"espada_oxidada": Vector2i(2, 10), "espada_bastarda": Vector2i(2, 11), "estoque_del_compilador": Vector2i(1, 10),
	"sable_de_fibra_optica": Vector2i(1, 10), "hacha_de_lenador": Vector2i(3, 9), "hacha_de_guerra": Vector2i(3, 8),
	"hacha_de_despido_masivo": Vector2i(4, 9), "maza_de_depuracion": Vector2i(2, 8), "martillo_de_compilacion": Vector2i(2, 8),
	"teclado_mecanico": Vector2i(3, 8), "teclado_rgb": Vector2i(3, 8), "daga_de_root": Vector2i(1, 5),
	"punal_de_dia_cero": Vector2i(1, 5), "cuchilla_de_carton": Vector2i(1, 5), "navaja_multiherramienta": Vector2i(1, 4),
	# Los objetos: en la palma (abajo) o colgando del asa (arriba: maleta y bolsa).
	"prop_cafe": Vector2i(1, 4), "prop_monitor": Vector2i(3, 6), "prop_laptop": Vector2i(2, 4),
	"prop_maleta": Vector2i(2, 0), "prop_pantalla": Vector2i(2, 5), "prop_mapa": Vector2i(2, 4),
	"prop_tablas": Vector2i(2, 5), "prop_tablero": Vector2i(1, 5), "prop_bolsa": Vector2i(2, 0),
	"prop_cartel": Vector2i(3, 8), "prop_planos": Vector2i(1, 5), "prop_rosa": Vector2i(1, 6), "prop_pila": Vector2i(2, 3),
}
## Tipo de «arma» de los objetos de los NPC: de lado se llevan derechos, no hacia abajo.
const PROP := "prop"
## Por tipo de arma, si no se sabe la base.
const DEFAULT := {"sword": "espada_oxidada", "axe": "hacha_de_lenador", "mace": "maza_de_depuracion", "dagger": "daga_de_root"}

static var _cache := {}


## La base que se dibuja para un arma: la suya si tiene sprite, si no la de su tipo.
static func art_for(base_id: String, kind: String) -> String:
	if ART.has(base_id):
		return base_id
	return String(DEFAULT.get(kind, ""))


## La capa del arma para StudentHero: del tamaño de su celda, con el agarre en `grip`.
static func layer(art_id: String, cell: Vector2i, grip: Vector2i) -> Image:
	if not ART.has(art_id):
		return null
	var key := "%s|%s" % [art_id, grip]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(cell.x, cell.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows: Array = ART[art_id]
	var origin: Vector2i = grip - (GRIPS[art_id] as Vector2i)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and PALETTE.has(ch):
				var p := origin + Vector2i(x, y)
				if p.x >= 0 and p.y >= 0 and p.x < cell.x and p.y < cell.y:
					img.set_pixelv(p, Color(PALETTE[ch]))
	# Contorno oscuro alrededor, como el del alumno.
	var src := img.duplicate() as Image
	for y in cell.y:
		for x in cell.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < cell.x and q.y < cell.y and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break
	_cache[key] = img
	return img
