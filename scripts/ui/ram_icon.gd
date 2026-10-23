class_name RamIcon
## Insignias pequeñas de los módulos RAM (como las gemas de soporte de PoE junto
## al icono de la habilidad): un cuadrito del color de su generación (DDR3 rojo,
## DDR4 verde, DDR5 azul) con un símbolo propio de cada familia de RAM (las
## variantes menor y mayor comparten símbolo; la mayor lleva borde dorado).
## Se usan en la barra de habilidades, en las placas del inventario y en los
## propios módulos RAM de la bolsa.

const GOLD := Color("e0b050")


## Columna de insignias en el borde derecho del icono de una placa (debajo de la
## chapita del maná). Devuelve el ancho que ocupa (0 si no hay RAM).
static func draw_board_column(ci: CanvasItem, rect: Rect2, board: Motherboard, top_margin := 15.0) -> float:
	var rams: Array = []
	for ram in board.rams:
		if ram != null:
			rams.append(ram)
	if rams.is_empty():
		return 0.0
	var room := rect.size.y - top_margin - 2.0
	var s := clampf(minf(rect.size.x * 0.2, room / rams.size() - 1.0), 6.0, 12.0)
	for k in rams.size():
		var r := Rect2(rect.end.x - s - 1.0, rect.position.y + top_margin + k * (s + 1.0), s, s)
		draw_badge(ci, r, rams[k], (rams[k] as RamModule).supports(board.skill_def))
	return s + 2.0


## Una insignia; `active` = false si la RAM no funciona con esa habilidad (tenue y tachada).
static func draw_badge(ci: CanvasItem, r: Rect2, ram: RamModule, active := true) -> void:
	var bg := ram.display_color().darkened(0.35)
	if not active:
		bg = bg.darkened(0.5)
	ci.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.85))
	ci.draw_rect(r, bg)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), Color(1, 1, 1, 0.12))
	draw_glyph(ci, r.grow(-maxf(1.0, r.size.x * 0.12)), ram.family(),
		Color(1, 1, 1, 0.95 if active else 0.4))
	ci.draw_rect(r, GOLD if ram.tier() >= 3 else Color(0, 0, 0, 0.6), false, 1.0)
	if not active:
		ci.draw_line(r.position, r.end, Color("e06c6c"), 1.5)


## Símbolo de cada familia, dibujado dentro de `r` (cuadrado pequeño).
static func draw_glyph(ci: CanvasItem, r: Rect2, fam: String, col: Color) -> void:
	var c := r.get_center()
	var h := r.size.x * 0.5
	var w := maxf(1.0, r.size.x * 0.14)
	match fam:
		"multicanal":   # abanico: tres trazos que se abren
			for a in [-0.55, 0.0, 0.55]:
				ci.draw_line(c + Vector2(0, h), c + Vector2(0, -h).rotated(a), col, w)
		"overclock":   # rayo de velocidad
			ci.draw_polyline(PackedVector2Array([c + Vector2(h * 0.3, -h), c + Vector2(-h * 0.4, 0), c + Vector2(h * 0.4, 0), c + Vector2(-h * 0.3, h)]), col, w)
		"ecc", "sensor_precision":   # mira de crítico
			ci.draw_arc(c, h * 0.65, 0.0, TAU, 10, col, w)
			ci.draw_line(c + Vector2(-h, 0), c + Vector2(h, 0), col, w * 0.7)
			ci.draw_line(c + Vector2(0, -h), c + Vector2(0, h), col, w * 0.7)
		"cache_l3", "amplificador_aura":   # ondas de área
			ci.draw_arc(c, h * 0.9, 0.0, TAU, 12, col, w * 0.8)
			ci.draw_arc(c, h * 0.45, 0.0, TAU, 8, col, w * 0.8)
		"disipador":   # aletas
			for k in 3:
				var x := c.x - h * 0.6 + k * h * 0.6
				ci.draw_line(Vector2(x, c.y - h), Vector2(x, c.y + h * 0.6), col, w)
			ci.draw_line(c + Vector2(-h, h * 0.7), c + Vector2(h, h * 0.7), col, w)
		"pipeline":   # doble flecha: se repite
			for dx in [-h * 0.45, h * 0.35]:
				ci.draw_polyline(PackedVector2Array([c + Vector2(dx - h * 0.3, -h * 0.7), c + Vector2(dx + h * 0.3, 0), c + Vector2(dx - h * 0.3, h * 0.7)]), col, w)
		"puntero_salvaje", "bypass_firewall":   # flecha que atraviesa una barra
			ci.draw_line(c + Vector2(0, -h), c + Vector2(0, h), col.darkened(0.3), w * 1.4)
			ci.draw_line(c + Vector2(-h, 0), c + Vector2(h, 0), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h, 0), c + Vector2(h * 0.4, -h * 0.45), c + Vector2(h * 0.4, h * 0.45)]), col)
		"fuerza_bruta":   # martillo
			ci.draw_rect(Rect2(c + Vector2(-h, -h * 0.9), Vector2(h * 2.0, h * 0.8)), col)
			ci.draw_line(c + Vector2(0, -h * 0.2), c + Vector2(0, h), col, w * 1.3)
		"alto_voltaje", "sobretension":   # rayo grueso
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.25, -h), c + Vector2(-h * 0.55, h * 0.15), c + Vector2(-h * 0.05, h * 0.15),
				c + Vector2(-h * 0.3, h), c + Vector2(h * 0.6, -h * 0.2), c + Vector2(h * 0.08, -h * 0.2)]), col)
		"swap_vampirica":   # gota de sangre
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.6, h * 0.1), c + Vector2(-h * 0.6, h * 0.1)]), Color("ff6060", col.a))
			ci.draw_circle(c + Vector2(0, h * 0.3), h * 0.6, Color("ff6060", col.a))
		"propagacion_excepciones":   # zigzag que rebota
			ci.draw_polyline(PackedVector2Array([c + Vector2(-h, h * 0.6), c + Vector2(-h * 0.3, -h * 0.6), c + Vector2(h * 0.3, h * 0.6), c + Vector2(h, -h * 0.6)]), col, w)
		"disparador_trampa":   # trampa: triángulo
			var tri := PackedVector2Array([c + Vector2(0, -h), c + Vector2(h, h * 0.8), c + Vector2(-h, h * 0.8), c + Vector2(0, -h)])
			ci.draw_polyline(tri, col, w)
		"detonador_mina":   # mina con púas
			ci.draw_circle(c, h * 0.5, col)
			for k in 4:
				ci.draw_line(c, c + Vector2.from_angle(PI / 4.0 + k * PI / 2.0) * h, col, w * 0.8)
		"servidor_torreta":   # torreta
			ci.draw_rect(Rect2(c + Vector2(-h * 0.6, 0), Vector2(h * 1.2, h)), col)
			ci.draw_line(c + Vector2(0, h * 0.1), c + Vector2(h, -h * 0.7), col, w * 1.2)
		"pasta_termica":   # llama
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.7, h * 0.2), c + Vector2(h * 0.4, h),
				c + Vector2(-h * 0.4, h), c + Vector2(-h * 0.7, h * 0.2)]), Color("ffa040", col.a))
		"refrigeracion_liquida":   # copo
			for k in 3:
				var d := Vector2.from_angle(PI / 3.0 * k + PI / 2.0) * h
				ci.draw_line(c - d, c + d, Color("bfe8ff", col.a), w)
		"inyeccion_malware":   # gota verde
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h * 0.6, h * 0.1), c + Vector2(-h * 0.6, h * 0.1)]), Color("7fe07a", col.a))
			ci.draw_circle(c + Vector2(0, h * 0.3), h * 0.6, Color("7fe07a", col.a))
		"fragmentacion_disco":   # disco partido
			ci.draw_rect(Rect2(c - Vector2(h, h) * 0.8, Vector2(h, h) * 0.75), col)
			ci.draw_rect(Rect2(c + Vector2(h * 0.1, h * 0.1), Vector2(h, h) * 0.7), col)
		"gestor_estados":   # reloj de arena
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.7, -h), c + Vector2(h * 0.7, -h), c, ]), col)
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(h * 0.7, h), c + Vector2(-h * 0.7, h)]), col)
		"firmware_autonomo", "firmware_resiliente":   # engranaje
			ci.draw_arc(c, h * 0.5, 0.0, TAU, 10, col, w * 1.3)
			for k in 6:
				var d := Vector2.from_angle(TAU * k / 6.0)
				ci.draw_line(c + d * h * 0.55, c + d * h, col, w * 1.2)
			if fam == "firmware_resiliente":
				ci.draw_circle(c, h * 0.2, col)
		"protocolo_enjambre":   # enjambre: tres puntos
			for v: Vector2 in [Vector2(0, -0.55), Vector2(-0.6, 0.45), Vector2(0.6, 0.45)]:
				ci.draw_circle(c + v * h, h * 0.32, col)
		"carcasa_reforzada":   # escudo
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.8, -h * 0.8), c + Vector2(h * 0.8, -h * 0.8), c + Vector2(h * 0.7, h * 0.1),
				c + Vector2(0, h), c + Vector2(-h * 0.7, h * 0.1)]), col)
		"explotador_vulnerabilidades":   # diana rota
			ci.draw_arc(c, h * 0.8, 0.3, TAU - 0.3, 10, col, w)
			ci.draw_line(c + Vector2(-h * 0.2, -h), c + Vector2(h * 0.2, h), col, w)
		"gestor_memoria":   # infinito: reserva menos
			ci.draw_arc(c + Vector2(-h * 0.45, 0), h * 0.42, 0.0, TAU, 10, col, w)
			ci.draw_arc(c + Vector2(h * 0.45, 0), h * 0.42, 0.0, TAU, 10, col, w)
		"redundancia_invocacion":   # dos copias
			ci.draw_rect(Rect2(c + Vector2(-h, -h), Vector2(h * 1.2, h * 1.2)), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.2, -h * 0.2), Vector2(h * 1.2, h * 1.2)), col)
		"guiado_laser":   # flecha curva que persigue
			ci.draw_arc(c + Vector2(0, h * 0.4), h * 0.8, PI * 1.05, PI * 1.9, 8, col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.75, -h * 0.35), c + Vector2(h * 0.95, h * 0.35), c + Vector2(h * 0.25, h * 0.1)]), col)
		_:
			ci.draw_circle(c, h * 0.5, col)
