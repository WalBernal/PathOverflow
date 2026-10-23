class_name UnitArt
## Dibujo de las invocaciones persistentes, cada una con su figura (hasta que
## haya arte final). `p` son los pies (o el centro si orbita); `ph` la fase de
## animación; `c` el color de la habilidad. Lo usan SkillController y la
## herramienta de capturas.


static func draw(ci: CanvasItem, skill_id: String, behavior: String, p: Vector2, ph: float, c: Color) -> void:
	match skill_id:
		"robot_centinela":
			_sentinel(ci, p, ph, c)
		"daemon_segundo_plano":
			_daemon(ci, p, ph)
		"golem_hardware":
			_golem(ci, p, ph, c)
		"dron_escolta", "dron_medico", "dron_escudo":
			_drone(ci, skill_id, p, ph, c)
		"bot_pruebas":
			_dummy(ci, p, ph, c)
		"mina_rodante":
			_wheel_mine(ci, p, ph, c)
		"agente_ia":
			_agent(ci, p, ph, c)
		"watchdog":
			_watchdog(ci, p, ph, c)
		"bot_rastreador":
			_bug_hunter(ci, p, ph, c)
		_:
			match behavior:
				"orbit":
					_drone(ci, skill_id, p, ph, c)
				"ranged":
					_sentinel(ci, p, ph, c)
				"tank":
					_golem(ci, p, ph, c)
				_:
					_daemon(ci, p, ph)


## Robot centinela: patas, torso con visor que barre y un cañón.
static func _sentinel(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var bob := sin(ph) * 1.5
	for s in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(s * 4, 2), p + Vector2(s * 6 + sin(ph + s) * 2.0, 10), Color("4a4f5c"), 3.0, true)
	ci.draw_rect(Rect2(p + Vector2(-9, -16 + bob), Vector2(18, 16)), Color("6e7480"))
	ci.draw_rect(Rect2(p + Vector2(-9, -16 + bob), Vector2(18, 16)), Color("2f333c"), false, 1.5)
	ci.draw_rect(Rect2(p + Vector2(-6, -13 + bob), Vector2(12, 5)), Color("10161c"))
	ci.draw_rect(Rect2(p + Vector2(-5, -12 + bob), Vector2(10 * (0.5 + 0.5 * sin(ph * 0.7)), 3)), c)
	ci.draw_rect(Rect2(p + Vector2(8, -8 + bob), Vector2(9, 4)), Color("3a3f4a"))
	ci.draw_line(p + Vector2(0, -16 + bob), p + Vector2(0, -22 + bob), Color("8a8a96"), 1.5)
	ci.draw_circle(p + Vector2(0, -23 + bob), 2.0, c)


## Daemon (el de BSD): cuerpecillo rojo con cuernos y un tridente.
static func _daemon(ci: CanvasItem, p: Vector2, ph: float) -> void:
	var hop := absf(sin(ph)) * 3.0
	ci.draw_circle(p + Vector2(0, -8 - hop), 9.0, Color("b8322a"))
	ci.draw_circle(p + Vector2(0, -19 - hop), 6.5, Color("c83a30"))
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(s * 3, -24 - hop), p + Vector2(s * 8, -31 - hop), p + Vector2(s * 6, -22 - hop)]), Color("f0e0c0"))
	ci.draw_circle(p + Vector2(-2.5, -19 - hop), 1.3, Color("ffe070"))
	ci.draw_circle(p + Vector2(2.5, -19 - hop), 1.3, Color("ffe070"))
	ci.draw_line(p + Vector2(11, -2 - hop), p + Vector2(11, -26 - hop), Color("c8c8c8"), 1.5, true)
	for k in 3:
		ci.draw_line(p + Vector2(8 + k * 3, -26 - hop), p + Vector2(8 + k * 3, -31 - hop), Color("c8c8c8"), 1.5, true)


## Golem de hardware: torres de PC apiladas con LEDs y un monitor por cabeza.
static func _golem(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var sway := sin(ph * 0.5) * 1.5
	ci.draw_rect(Rect2(p + Vector2(-16, -28 + sway), Vector2(32, 30)), Color("5a5650"))
	ci.draw_rect(Rect2(p + Vector2(-16, -28 + sway), Vector2(32, 30)), Color("2a2724"), false, 2.0)
	for k in 4:
		ci.draw_circle(p + Vector2(-10 + k * 6, -6 + sway), 1.6, c if fmod(ph + k, 3.0) < 1.5 else Color("2a2a20"))
	for s in [-1.0, 1.0]:
		ci.draw_rect(Rect2(p + Vector2(s * 16 - (8 if s < 0 else 0), -24 + sway + sin(ph + s) * 2.0), Vector2(8, 22)), Color("47443f"))
	ci.draw_rect(Rect2(p + Vector2(-11, -44 + sway), Vector2(22, 16)), Color("b8b8b0"))
	ci.draw_rect(Rect2(p + Vector2(-9, -42 + sway), Vector2(18, 11)), Color("10200f"))
	ci.draw_string(ThemeDB.fallback_font, p + Vector2(-8, -33 + sway), "ò_ó", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("3cff6a"))


## Drones que orbitan: cuatro rotores y un núcleo (cruz el médico, escudo el cortafuegos, llama el escolta).
static func _drone(ci: CanvasItem, skill_id: String, p: Vector2, ph: float, c: Color) -> void:
	ci.draw_circle(p + Vector2(0, 30), 5.0, Color(0, 0, 0, 0.22))
	for k in 4:
		var arm := Vector2.from_angle(PI / 4.0 + PI / 2.0 * k) * 10.0
		ci.draw_line(p, p + arm, Color("5a5f6c"), 2.0, true)
		ci.draw_circle(p + arm, 4.0 + sin(ph * 6.0 + k) * 0.6, Color(0.85, 0.85, 0.9, 0.3))
		ci.draw_line(p + arm - Vector2.from_angle(ph * 9.0 + k) * 4.0, p + arm + Vector2.from_angle(ph * 9.0 + k) * 4.0, Color(0.9, 0.9, 1.0, 0.5), 1.0)
	ci.draw_circle(p, 5.5, Color("3a3f4a"))
	match skill_id:
		"dron_medico":
			ci.draw_rect(Rect2(p + Vector2(-1.5, -4), Vector2(3, 8)), c)
			ci.draw_rect(Rect2(p + Vector2(-4, -1.5), Vector2(8, 3)), c)
		"dron_escudo":
			ci.draw_arc(p + Vector2(0, 1), 4.5, PI, TAU, 8, c, 2.0, true)
			ci.draw_arc(p + Vector2(0, 1), 9.0 + sin(ph) * 0.8, PI * 1.1, PI * 1.9, 10, Color(c, 0.5), 1.5, true)
		_:
			ci.draw_circle(p, 2.6 + 0.6 * sin(ph * 2.0), c)
			ci.draw_circle(p + Vector2(0, 7), 1.5 + absf(sin(ph * 5.0)), Color("ffb040"))   # tobera


## Bot de Pruebas: muñeco de choque (crash test) amarillo y negro, con su diana.
static func _dummy(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var run := sin(ph * 1.6)
	for s in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(s * 3, -8), p + Vector2(s * 4 + run * s * 3.0, 0), Color("2a2a2a"), 3.0, true)
	ci.draw_rect(Rect2(p + Vector2(-6, -20), Vector2(12, 13)), Color("e8c040"))
	ci.draw_rect(Rect2(p + Vector2(-6, -20), Vector2(6, 6.5)), Color("2a2a2a"))
	ci.draw_rect(Rect2(p + Vector2(0, -13.5), Vector2(6, 6.5)), Color("2a2a2a"))
	for s in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(s * 6, -18), p + Vector2(s * 10, -11 - run * s * 2.0), Color("e8c040"), 2.5, true)
	ci.draw_circle(p + Vector2(0, -26), 5.5, Color("e8c040"))
	ci.draw_arc(p + Vector2(0, -26), 3.2, 0.0, TAU, 10, Color("2a2a2a"), 1.0)
	ci.draw_circle(p + Vector2(0, -26), 1.0, c)


## Mina Rodante: bomba sobre dos ruedas con una mecha que chisporrotea.
static func _wheel_mine(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	for s in [-1.0, 1.0]:
		var w := p + Vector2(s * 7, -4)
		ci.draw_circle(w, 4.5, Color("3a3a40"))
		ci.draw_line(w, w + Vector2.from_angle(ph * 4.0 * s) * 3.5, Color("8a8a96"), 1.0)
	ci.draw_circle(p + Vector2(0, -12), 9.0, Color("26262c"))
	ci.draw_circle(p + Vector2(-3, -15), 2.5, Color("5a5a66"))
	ci.draw_rect(Rect2(p + Vector2(-3, -22), Vector2(6, 3)), Color("8a8a96"))
	ci.draw_line(p + Vector2(0, -22), p + Vector2(5, -28), Color("8a6d3b"), 1.5, true)
	var spark := 0.5 + 0.5 * sin(ph * 12.0)
	ci.draw_circle(p + Vector2(5, -29), 1.8 + spark * 1.5, Color(1.0, 0.8, 0.3, 0.9))
	ci.draw_circle(p + Vector2(0, -12), 3.0, Color(c, 0.4 + 0.4 * spark))


## Agente IA: un orbe flotante con dos ojos verdes, una sonrisa y burbujas de datos.
static func _agent(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var float_y := sin(ph * 0.8) * 3.0
	var o := p + Vector2(0, -20 + float_y)
	ci.draw_circle(o, 10.0, Color("2a1f3a"))
	ci.draw_arc(o, 10.0, 0.0, TAU, 20, c, 2.0, true)
	ci.draw_arc(o, 13.0, ph, ph + 1.6, 8, Color(c, 0.5), 1.5, true)
	var blink := fmod(ph, 4.0) > 3.8
	for s in [-1.0, 1.0]:
		if blink:
			ci.draw_line(o + Vector2(s * 3.5 - 1.5, -2), o + Vector2(s * 3.5 + 1.5, -2), Color("3cff9a"), 1.5)
		else:
			ci.draw_circle(o + Vector2(s * 3.5, -2), 1.8, Color("3cff9a"))
	ci.draw_arc(o + Vector2(0, 2), 3.5, 0.3, PI - 0.3, 6, Color("3cff9a"), 1.2, true)
	for k in 3:
		var t := fmod(ph * 0.5 + k * 0.33, 1.0)
		ci.draw_circle(o + Vector2(8 + k * 2, -10 - t * 12.0), 1.2 + k * 0.4, Color(c, 0.8 * (1.0 - t)))


## Watchdog: perro guardián de chapa con collar parpadeante (reinicia lo que se cuelga).
static func _watchdog(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var trot := sin(ph * 1.8)
	var body := Color("8a6a4a")
	for k in 4:
		var x := -9.0 + k * 6.0
		ci.draw_line(p + Vector2(x, -6), p + Vector2(x + trot * (1.0 if k % 2 == 0 else -1.0) * 2.0, 0), Color("5a4430"), 2.5, true)
	ci.draw_colored_polygon(QuestItemArt.ellipse(p + Vector2(-1, -10), 12.0, 6.0), body)
	ci.draw_line(p + Vector2(-12, -12), p + Vector2(-17, -18 - absf(trot) * 3.0), body, 2.5, true)   # cola
	var head := p + Vector2(11, -17)
	ci.draw_circle(head, 5.5, body)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(3, -1), head + Vector2(9, 1), head + Vector2(3, 3)]), body.darkened(0.15))   # hocico
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-3, -4), head + Vector2(-1, -10), head + Vector2(1, -4)]), body.darkened(0.3))   # oreja
	ci.draw_circle(head + Vector2(1.5, -1.5), 1.1, Color("ffe070"))
	ci.draw_line(p + Vector2(6, -14), p + Vector2(7, -9), c if fmod(ph, 1.0) < 0.5 else c.darkened(0.6), 2.0)   # collar con LED


## Bot Rastreador: robot de QA sobre una rueda, con lupa y cerbatana de dardos.
static func _bug_hunter(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var bob := sin(ph) * 1.0
	ci.draw_circle(p + Vector2(0, -4), 4.5, Color("3a3a40"))
	ci.draw_line(p + Vector2(0, -4), p + Vector2(0, -4) + Vector2.from_angle(ph * 3.0) * 3.5, Color("8a8a96"), 1.0)
	ci.draw_rect(Rect2(p + Vector2(-7, -20 + bob), Vector2(14, 13)), Color("4a7a4a"))
	ci.draw_rect(Rect2(p + Vector2(-7, -20 + bob), Vector2(14, 13)), Color("1f331f"), false, 1.5)
	ci.draw_string(ThemeDB.fallback_font, p + Vector2(-6, -10 + bob), "QA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("dff0d0"))
	ci.draw_circle(p + Vector2(0, -25 + bob), 5.0, Color("5a8a5a"))
	ci.draw_circle(p + Vector2(1.5, -25 + bob), 2.0, c)
	# Lupa a un lado y cerbatana al otro.
	ci.draw_arc(p + Vector2(-11, -16 + bob), 3.5, 0.0, TAU, 10, Color("c8c8c8"), 1.5, true)
	ci.draw_line(p + Vector2(-9, -13 + bob), p + Vector2(-6, -10 + bob), Color("8a6d3b"), 1.5)
	ci.draw_line(p + Vector2(7, -14 + bob), p + Vector2(16, -16 + bob), Color("6a5a4a"), 2.0)
	ci.draw_circle(p + Vector2(16, -16 + bob), 1.2, c)
