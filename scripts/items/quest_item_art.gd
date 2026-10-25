class_name QuestItemArt
## Dibujo de los objetos de misión que se recogen del suelo (quest_items en
## actN.json), cada uno con su forma: la cinta del DBA, el Kindle de M. Páez y su
## funda, los panes de Eugenio... Un objeto puede elegir su dibujo con "art";
## si no, se deduce del id (ART_BY_ID) y, si tampoco, es una cinta.

const ART_BY_ID := {
	"cinta_backup": "tape", "registro_auditoria": "log", "descriptor_falso": "descriptor",
	"funda_kindle": "kindle_case", "kindle_paez": "kindle",
	"pan_concha": "concha", "pan_bolillo": "bolillo", "pan_cuernito": "cuernito",
	"libreta_gatitos": "notebook",
}
const OUTLINE := Color(0.04, 0.03, 0.05, 0.9)


static func kind_for(q: Dictionary) -> String:
	if q.has("art"):
		return String(q["art"])
	var id := String(q.get("id", ""))
	if id.begins_with("cache_"):
		return "ice_cache"
	# Acto IV: vasos de la expendedora, andenes de arranque y ajustes del CMOS.
	for prefix in ["cafe_", "anden_", "ajuste_"]:
		if id.begins_with(prefix):
			return {"cafe_": "vending_cup", "anden_": "boot_device", "ajuste_": "cmos_setting"}[prefix]
	return ART_BY_ID.get(id, "tape")


## Dibuja el objeto centrado en `p` (sin la sombra ni el brillo del suelo).
## `time` anima los detalles (vapor, parpadeos).
static func draw(ci: CanvasItem, p: Vector2, kind: String, time := 0.0) -> void:
	match kind:
		"log":
			_log(ci, p)
		"descriptor":
			_descriptor(ci, p, time)
		"ice_cache":
			_ice_cache(ci, p, time)
		"kindle_case":
			_kindle_case(ci, p)
		"kindle":
			_kindle(ci, p, time)
		"concha":
			_concha(ci, p)
		"bolillo":
			_bolillo(ci, p, time)
		"cuernito":
			_cuernito(ci, p, time)
		"notebook":
			_notebook(ci, p)
		"vending_cup":
			_vending_cup(ci, p, time)
		"boot_device":
			_boot_device(ci, p, time)
		"cmos_setting":
			_cmos_setting(ci, p, time)
		_:
			_tape(ci, p)


# --- Utilidades ---

static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func _outlined(ci: CanvasItem, pts: PackedVector2Array, fill: Color, width := 2.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, OUTLINE, width, true)


static func _box(ci: CanvasItem, r: Rect2, fill: Color, width := 2.0) -> void:
	ci.draw_rect(r.grow(width * 0.5), OUTLINE)
	ci.draw_rect(r, fill)


static func _tiny_text(ci: CanvasItem, pos: Vector2, text: String, width: float, size: int, color: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


# --- Acto I y II ---

## Cartucho de cinta LTO de 2009: carcasa gris azulada, etiqueta escrita a mano,
## pestaña naranja de protección contra escritura y la puerta de la cinta.
static func _tape(ci: CanvasItem, p: Vector2) -> void:
	var body := Rect2(p + Vector2(-18, -15), Vector2(36, 30))
	_box(ci, body, Color("2d3440"))
	ci.draw_rect(Rect2(body.position, Vector2(36, 4)), Color("3d4656"))           # luz arriba
	var label := Rect2(body.position + Vector2(4, 6), Vector2(28, 11))
	ci.draw_rect(label, Color("ece6d2"))
	ci.draw_rect(Rect2(label.position, Vector2(28, 2)), Color("c8463a"))
	_tiny_text(ci, label.position + Vector2(0, 9), "FINAL", 28, 7, Color("2a2a8a"))
	ci.draw_rect(Rect2(body.position + Vector2(4, 21), Vector2(6, 5)), Color("e88a2a"))   # protección
	ci.draw_rect(Rect2(body.position + Vector2(20, 20), Vector2(13, 7)), Color("1c2129"))  # puerta
	ci.draw_line(body.position + Vector2(21, 23.5), body.position + Vector2(32, 23.5), Color("5a4a2a"), 1.0)


## Registro de auditoría: papel continuo de impresora (pijama verde), con los
## agujeros de arrastre, plegado en acordeón y con un sello rojo «AUDIT».
static func _log(ci: CanvasItem, p: Vector2) -> void:
	for k in 2:   # hojas plegadas debajo
		var o := Vector2(3 - k * 3, 4 - k * 2)
		_box(ci, Rect2(p + Vector2(-15, -17) + o, Vector2(30, 34)), Color("d9d6c8").darkened(0.12 * (1 - k)))
	var page := Rect2(p + Vector2(-15, -19), Vector2(30, 34))
	ci.draw_rect(page, Color("f2f0e4"))
	for b in 4:   # bandas verdes
		ci.draw_rect(Rect2(page.position + Vector2(4, 3 + b * 8), Vector2(22, 4)), Color("cfe8c8"))
	for y in range(3, 33, 5):   # agujeros de arrastre
		ci.draw_circle(page.position + Vector2(2, y), 0.9, Color("8a8a80"))
		ci.draw_circle(page.position + Vector2(28, y), 0.9, Color("8a8a80"))
	for l in 6:   # líneas impresas
		var w: float = [18.0, 14.0, 20.0, 11.0, 17.0, 9.0][l]
		ci.draw_line(page.position + Vector2(6, 5 + l * 4.5), page.position + Vector2(6 + w, 5 + l * 4.5), Color("4a4a52"), 1.0)
	# Sello rojo.
	var stamp := Rect2(p + Vector2(-9, 3), Vector2(22, 9))
	ci.draw_rect(stamp, Color(0.95, 0.85, 0.82, 0.6))
	ci.draw_rect(stamp, Color(0.8, 0.15, 0.12, 0.85), false, 1.5)
	_tiny_text(ci, stamp.position + Vector2(0, 7.5), "AUDIT", 22, 7, Color(0.8, 0.15, 0.12, 0.95))


## Descriptor de archivo en blanco: una ficha digital (cian) con la esquina
## doblada, cabecera «fd:» y todos los campos vacíos.
static func _descriptor(ci: CanvasItem, p: Vector2, time: float) -> void:
	var pts := PackedVector2Array([p + Vector2(-13, -18), p + Vector2(7, -18), p + Vector2(13, -12),
		p + Vector2(13, 18), p + Vector2(-13, 18)])
	_outlined(ci, pts, Color("dff4f7"))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(7, -18), p + Vector2(7, -12), p + Vector2(13, -12)]), Color("9cc9d1"))
	ci.draw_rect(Rect2(p + Vector2(-11, -16), Vector2(16, 6)), Color("2a8a9a"))
	_tiny_text(ci, p + Vector2(-11, -11), "fd: ?", 16, 6, Color.WHITE)
	for l in 4:   # campos vacíos: etiqueta + guiones
		var y := -4.0 + l * 5.5
		ci.draw_line(p + Vector2(-10, y), p + Vector2(-5, y), Color("2a8a9a"), 1.5)
		var x := -3.0
		while x < 10.0:
			ci.draw_line(p + Vector2(x, y + 1), p + Vector2(x + 2, y + 1), Color("7aa8b0"), 1.0)
			x += 4.0
	# Parpadeo del cursor en el primer campo.
	if fmod(time, 1.0) < 0.5:
		ci.draw_rect(Rect2(p + Vector2(-3, -7), Vector2(1.5, 4)), Color("2a8a9a"))


## Bloque de caché congelado: un cubo de hielo (isométrico) con un módulo de
## memoria dentro, escarcha y un par de carámbanos.
static func _ice_cache(ci: CanvasItem, p: Vector2, time: float) -> void:
	var s := 15.0
	var top := PackedVector2Array([p + Vector2(0, -s - 6), p + Vector2(s, -s * 0.5 - 6), p + Vector2(0, -6), p + Vector2(-s, -s * 0.5 - 6)])
	var left := PackedVector2Array([p + Vector2(-s, -s * 0.5 - 6), p + Vector2(0, -6), p + Vector2(0, s + 2), p + Vector2(-s, s * 0.5 + 2)])
	var right := PackedVector2Array([p + Vector2(0, -6), p + Vector2(s, -s * 0.5 - 6), p + Vector2(s, s * 0.5 + 2), p + Vector2(0, s + 2)])
	# El chip, visto a través del hielo.
	ci.draw_rect(Rect2(p + Vector2(-9, -6), Vector2(18, 10)), Color("2f6b3a"))
	for k in 3:
		ci.draw_rect(Rect2(p + Vector2(-8 + k * 6, -4), Vector2(4, 5)), Color("15181c"))
	for k in 8:
		ci.draw_rect(Rect2(p + Vector2(-8.5 + k * 2.2, 3), Vector2(1.2, 1.5)), Color("d9b44a"))
	ci.draw_colored_polygon(left, Color(0.62, 0.82, 0.95, 0.55))
	ci.draw_colored_polygon(right, Color(0.45, 0.68, 0.88, 0.6))
	ci.draw_colored_polygon(top, Color(0.85, 0.95, 1.0, 0.75))
	for face in [top, left, right]:
		var closed: PackedVector2Array = face.duplicate()
		closed.append(face[0])
		ci.draw_polyline(closed, Color(0.9, 0.97, 1.0, 0.9), 1.2, true)
	# Brillo que recorre la cara izquierda.
	var g := fmod(time * 0.6, 1.0)
	ci.draw_line(p + Vector2(-s + 2, -s * 0.5 - 2 + g * 18), p + Vector2(-4, -2 + g * 18), Color(1, 1, 1, 0.5 * (1.0 - g)), 1.5)
	# Carámbanos y escarcha.
	for x: float in [-10.0, -4.0, 6.0]:
		var base := p + Vector2(x, s * 0.5 + 2 + (s * 0.5 - absf(x) * 0.5))
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-1.5, -1), base + Vector2(1.5, -1), base + Vector2(0, 5)]), Color("d8f0ff"))
	for k in 5:
		ci.draw_circle(p + Vector2(-12 + k * 6, -s * 0.5 - 7 + (k % 2) * 4), 0.9, Color.WHITE)


# --- Acto III: M. Páez ---

## Funda de Kindle: tapa de tela azul marino con el elástico a un lado, la
## etiqueta con el nombre y una nota amarilla asomando por arriba.
static func _kindle_case(ci: CanvasItem, p: Vector2) -> void:
	# Nota adhesiva que asoma (detrás de la funda).
	var note := PackedVector2Array([p + Vector2(2, -26), p + Vector2(16, -24), p + Vector2(14, -12), p + Vector2(0, -14)])
	_outlined(ci, note, Color("f7e36a"), 1.5)
	ci.draw_line(p + Vector2(4, -21), p + Vector2(13, -20), Color("6a5a2a"), 1.0)
	ci.draw_line(p + Vector2(3, -18), p + Vector2(10, -17), Color("6a5a2a"), 1.0)
	var cover := Rect2(p + Vector2(-15, -20), Vector2(30, 40))
	_box(ci, cover, Color("26324a"))
	ci.draw_rect(Rect2(cover.position, Vector2(5, 40)), Color("1b2436"))          # lomo
	ci.draw_rect(Rect2(cover.position + Vector2(8, 4), Vector2(19, 32)), Color("2e3c58"), false, 1.0)   # costura
	ci.draw_rect(Rect2(cover.position + Vector2(22, 0), Vector2(3, 40)), Color("101218"))   # elástico
	# Etiqueta con el nombre.
	ci.draw_rect(Rect2(cover.position + Vector2(8, 24), Vector2(13, 7)), Color("ece6d2"))
	_tiny_text(ci, cover.position + Vector2(8, 30), "M.Páez", 13, 5, Color("2a2a2a"))


## El Kindle: marco negro, pantalla de tinta electrónica con texto, una raya
## en la pantalla, el logo abajo y la batería al 1 % parpadeando.
static func _kindle(ci: CanvasItem, p: Vector2, time: float) -> void:
	var body := Rect2(p + Vector2(-15, -21), Vector2(30, 42))
	_box(ci, body, Color("1d1d20"))
	ci.draw_rect(Rect2(body.position, Vector2(30, 2)), Color("34343a"))
	var screen := Rect2(body.position + Vector2(3, 4), Vector2(24, 30))
	ci.draw_rect(screen, Color("c9c8bd"))
	for l in 7:   # texto del libro
		var w := 18.0 if l % 3 != 2 else 12.0
		ci.draw_line(screen.position + Vector2(3, 6 + l * 3.5), screen.position + Vector2(3 + w, 6 + l * 3.5), Color("5a5a56"), 1.0)
	ci.draw_line(screen.position + Vector2(3, 6 + 2 * 3.5 + 1), screen.position + Vector2(13, 6 + 2 * 3.5 + 1), Color("8a7a3a"), 1.0)   # subrayado
	ci.draw_line(screen.position + Vector2(2, 25), screen.position + Vector2(21, 9), Color(1, 1, 1, 0.75), 1.0)   # raya
	# Batería al 1 %.
	var bat := Rect2(screen.position + Vector2(17, 1), Vector2(5, 2.5))
	ci.draw_rect(bat, Color("3a3a3a"), false, 0.6)
	if fmod(time, 1.2) < 0.7:
		ci.draw_rect(Rect2(bat.position, Vector2(1, 2.5)), Color("d93a2a"))
	_tiny_text(ci, body.position + Vector2(0, 40), "kindle", 30, 5, Color("8a8a90"))


# --- Acto III: los panes de Eugenio ---

## Concha: pan redondo con la cubierta de azúcar blanca rayada en forma de
## concha marina, y unas gotitas de soldadura (es pan de silicio).
static func _concha(ci: CanvasItem, p: Vector2) -> void:
	# El pan: un bollo redondo que asoma por debajo de la cubierta.
	var bun := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		bun.append(p + Vector2(cos(a) * 19, 5 + sin(a) * 7))
	for k in 17:
		var a := PI + PI * k / 16.0
		bun.append(p + Vector2(cos(a) * 19, 5 + sin(a) * 14))
	_outlined(ci, bun, Color("d39248"))
	var dome := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		dome.append(p + Vector2(cos(a) * 17, 5 + sin(a) * 18))
	_outlined(ci, dome, Color("f3e3cc"), 1.5)
	# Ranuras de la concha: abanico desde abajo y dos arcos.
	var o := p + Vector2(0, 8)
	for k in 7:
		var a := PI + PI * (k + 1) / 8.0
		ci.draw_line(o + Vector2.from_angle(a) * 5.0, o + Vector2.from_angle(a) * 18.0, Color("c9925a"), 1.5, true)
	ci.draw_arc(o, 10.0, PI * 1.08, PI * 1.92, 10, Color("d9aa78"), 1.0, true)
	ci.draw_arc(o, 15.0, PI * 1.1, PI * 1.9, 12, Color("d9aa78"), 1.0, true)
	ci.draw_arc(p + Vector2(-2, -4), 9.0, PI * 1.2, PI * 1.5, 6, Color(1, 1, 1, 0.7), 2.0, true)   # brillo
	for v: Vector2 in [Vector2(-14, 9), Vector2(13, 9)]:   # gotitas de soldadura
		ci.draw_circle(p + v, 1.2, Color("c8ccd4"))


## Bolillo: pan alargado de puntas afiladas, costra dorada y una greña a lo
## largo; todavía tibio, así que echa vapor.
static func _bolillo(ci: CanvasItem, p: Vector2, time: float) -> void:
	# Visto desde arriba y algo inclinado: una lanzadera con las puntas afiladas.
	var rot := -0.18
	var shape := PackedVector2Array()
	var n := 18
	for k in n + 1:
		var t := float(k) / n
		shape.append(p + Vector2(-22 + 44 * t, -pow(sin(PI * t), 0.7) * 10.0).rotated(rot))
	for k in range(n - 1, 0, -1):
		var t := float(k) / n
		shape.append(p + Vector2(-22 + 44 * t, pow(sin(PI * t), 0.7) * 10.0).rotated(rot))
	_outlined(ci, shape, Color("b06a2a"))
	# Volumen: el centro más claro y las puntas más tostadas.
	ci.draw_colored_polygon(ellipse(p, 15, 7.5, rot), Color("cc8640"))
	ci.draw_colored_polygon(ellipse(p + Vector2(-1, -2).rotated(rot), 10, 4.5, rot), Color("dda05a"))
	# Greña: el corte a lo largo, con la miga clara entre dos bordes de costra.
	var cut := PackedVector2Array()
	for k in 11:
		var t := float(k) / 10
		cut.append(p + Vector2(-14 + 28 * t, -sin(PI * t) * 2.6).rotated(rot))
	for k in range(9, 0, -1):
		var t := float(k) / 10
		cut.append(p + Vector2(-14 + 28 * t, sin(PI * t) * 1.4).rotated(rot))
	ci.draw_colored_polygon(cut, Color("f6e4bc"))
	var closed := cut.duplicate()
	closed.append(cut[0])
	ci.draw_polyline(closed, Color("7a4416"), 1.5, true)
	ci.draw_line(p + Vector2(-10, -4.5).rotated(rot), p + Vector2(8, -5.5).rotated(rot), Color(1, 0.92, 0.75, 0.6), 1.0, true)   # brillo de la costra
	# Vapor.
	for k in 3:
		var x := -8.0 + k * 8.0
		var ph := time * 2.0 + k * 1.7
		var a := 0.25 + 0.2 * sin(ph)
		var pts := PackedVector2Array()
		for j in 6:
			pts.append(p + Vector2(x + sin(ph + j * 0.9) * 2.0, -12 - j * 3.0))
		ci.draw_polyline(pts, Color(1, 1, 1, a), 1.5, true)


## Cuernito: media luna de capas doradas que se estrechan hacia las puntas,
## con escarcha y cristalitos (lo encontraron en el arranque en frío).
static func _cuernito(ci: CanvasItem, p: Vector2, time: float) -> void:
	var center := p + Vector2(0, 16)
	var segs := []
	for k in 7:
		var t := k / 6.0
		var a := deg_to_rad(lerpf(198.0, 342.0, t))
		var fat := 1.0 - absf(t - 0.5) * 1.5
		segs.append({"pos": center + Vector2.from_angle(a) * 19.0, "rx": 4.0 + 4.0 * fat, "ry": 5.0 + 6.0 * fat, "rot": a + PI / 2.0, "fat": fat})
	segs.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["fat"] < y["fat"])
	for sgm in segs:
		var col := Color("c88a3e").lerp(Color("e0a85a"), float(sgm["fat"]))
		_outlined(ci, ellipse(sgm["pos"], sgm["rx"], sgm["ry"], sgm["rot"], 16), col, 1.5)
		ci.draw_colored_polygon(ellipse(sgm["pos"] + Vector2(0, -sgm["ry"] * 0.35), sgm["rx"] * 0.55, sgm["ry"] * 0.35, sgm["rot"], 10), Color(1, 0.9, 0.65, 0.5))
	# Escarcha.
	for v: Vector2 in [Vector2(-14, -2), Vector2(-4, -7), Vector2(7, -6), Vector2(15, 0), Vector2(1, -2)]:
		ci.draw_circle(p + v, 1.1, Color(0.9, 0.97, 1.0, 0.9))
	var tw := 0.5 + 0.5 * sin(time * 3.0)
	for v: Vector2 in [Vector2(-9, -9), Vector2(12, -8)]:
		var c := p + v
		var r := 2.0 + tw * 1.5
		ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0.8, 0.95, 1.0, 0.9), 1.0)
		ci.draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0.8, 0.95, 1.0, 0.9), 1.0)


# --- Acto IV: el Setup de la BIOS ---

## Libreta Scribe del Inge Pepe, con pasta de gatitos.
static func _notebook(ci: CanvasItem, p: Vector2) -> void:
	var body := Rect2(p + Vector2(-14, -19), Vector2(28, 38))
	_box(ci, body, Color("f2a8c8"))
	for k in 6:   # espiral
		ci.draw_circle(body.position + Vector2(0, 4 + k * 6), 2.0, Color("8a8a90"))
	for c: Vector2 in [Vector2(-3, -8), Vector2(6, 6)]:   # dos gatitos
		ci.draw_circle(p + c, 4.5, Color("fff2f6"))
		ci.draw_colored_polygon(PackedVector2Array([p + c + Vector2(-4, -2), p + c + Vector2(-3, -7), p + c + Vector2(-1, -3)]), Color("fff2f6"))
		ci.draw_colored_polygon(PackedVector2Array([p + c + Vector2(4, -2), p + c + Vector2(3, -7), p + c + Vector2(1, -3)]), Color("fff2f6"))
		ci.draw_circle(p + c + Vector2(-1.5, 0), 0.8, Color("2a2030"))
		ci.draw_circle(p + c + Vector2(1.5, 0), 0.8, Color("2a2030"))
	_tiny_text(ci, body.position + Vector2(0, 36), "Scribe", 28, 6, Color("8a3a5a"))


## Vaso de la máquina expendedora, con vapor tibio.
static func _vending_cup(ci: CanvasItem, p: Vector2, time: float) -> void:
	_outlined(ci, PackedVector2Array([p + Vector2(-10, -14), p + Vector2(10, -14), p + Vector2(7, 16), p + Vector2(-7, 16)]), Color("f2ead8"), 1.5)
	ci.draw_rect(Rect2(p + Vector2(-9, -6), Vector2(18, 7)), Color("8a5a2e"))
	_tiny_text(ci, p + Vector2(-9, 0), "café", 18, 6, Color("f2ead8"))
	for k in 2:
		var x := -4.0 + k * 7.0
		var wave := sin(time * 2.5 + k) * 2.0
		ci.draw_line(p + Vector2(x, -18), p + Vector2(x + wave, -26), Color(1, 1, 1, 0.35), 1.5, true)


## Andén de arranque: el dispositivo (disquete, disco o red) sobre su placa, con un LED.
static func _boot_device(ci: CanvasItem, p: Vector2, time: float) -> void:
	_box(ci, Rect2(p + Vector2(-18, 6), Vector2(36, 10)), Color("4a4f5c"))
	_box(ci, Rect2(p + Vector2(-12, -18), Vector2(24, 24)), Color("1d3a8a"))
	ci.draw_rect(Rect2(p + Vector2(-7, -18), Vector2(14, 8)), Color("c8c8d0"))   # la ventanita metálica del disquete
	ci.draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 8)), Color("f2f2f0"))
	var on := fmod(time * 1.5, 1.0) < 0.5
	ci.draw_circle(p + Vector2(13, 11), 2.5, Color("3cff6a") if on else Color("1a4a2a"))


## Ajuste del CMOS: una fila del Setup en un marco gris, con su valor en amarillo.
static func _cmos_setting(ci: CanvasItem, p: Vector2, time: float) -> void:
	var r := Rect2(p + Vector2(-20, -12), Vector2(40, 24))
	_box(ci, r, Color("0a1a6a"))
	ci.draw_rect(r.grow(-3), Color("8a96c8"), false, 1.0)
	var glow := 0.6 + 0.4 * sin(time * 3.0)
	ci.draw_rect(Rect2(p + Vector2(-15, -3), Vector2(30, 7)), Color(0.9, 0.85, 0.2, 0.35 * glow))
	_tiny_text(ci, p + Vector2(-20, 3), "[Enabled]", 40, 6, Color("ffe050"))
