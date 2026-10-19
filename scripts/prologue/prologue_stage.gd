class_name PrologueStage
extends Node2D
## Escenario del prólogo, dibujado en pequeño (400×225) y escalado sin
## suavizado: pixel art de verdad. Tres sitios en vista lateral:
##   calle    — el malecón de Mazatlán al mediodía, camino a la UAdeO.
##   pasillo  — el pasillo largo hasta el Departamento de Informática.
##   oficina  — el departamento destrozado, con Rafa atrincherado.
## `dissolve` (0..1) convierte la oficina en el mundo digital (papeles en logs,
## cables en enredaderas de cobre).

const VIEW := Vector2(400, 225)
const FLOOR_Y := 198.0
const ROOM_WIDTH := {"calle": 760.0, "pasillo": 820.0, "oficina": 400.0}
const SHIRT := "e9e5d8"
const PORTFOLIO := Color("3d6fb0")

var room := "calle"
var cam_x := 0.0
var player_x := 40.0
var player_facing := Vector2.RIGHT
var walk_phase := -1.0
var player_look: Dictionary = CharacterAppearance.default()
var rafa_look: Dictionary = CharacterAppearance.default()
## Ropa formal (0) → ropa del mundo digital (1).
var outfit_shift := 0.0
var kneeling := false
var rafa_standing := false
var time := 0.0
var flicker := 0.0
var rack_shake := 0.0
var dissolve := 0.0
## Hotspot resaltado: {pos: Vector2 (en el mundo), text}
var prompt: Dictionary = {}
var _font: Font
var _papers: Array[Dictionary] = []


func _ready() -> void:
	_font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 2008
	for k in 12:
		_papers.append({"x": rng.randf_range(20, 380), "y": rng.randf_range(150, 205), "r": rng.randf_range(-0.6, 0.6),
			"speed": rng.randf_range(0.5, 1.5), "phase": rng.randf() * TAU})


func width() -> float:
	return ROOM_WIDTH.get(room, VIEW.x)


func _process(delta: float) -> void:
	time += delta
	flicker = maxf(0.0, flicker - delta)
	rack_shake = maxf(0.0, rack_shake - delta * 0.2)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(-roundf(cam_x), 0))
	match room:
		"calle":
			_draw_street()
		"pasillo":
			_draw_hallway()
		"oficina":
			_draw_office()
	_draw_player()
	if room == "oficina":
		_draw_office_front()
	if not prompt.is_empty():
		var p: Vector2 = prompt["pos"]
		var bob := sin(time * 4.0) * 1.5
		var text: String = prompt["text"]
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
		draw_rect(Rect2(p + Vector2(-w / 2.0, -14 + bob), Vector2(w, 12)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(p + Vector2(-w / 2.0, -14 + bob), Vector2(w, 12)), Color("d9a441"), false, 1.0)
		draw_string(_font, p + Vector2(-w / 2.0 + 5, -5 + bob), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2e6c0"))
	draw_set_transform(Vector2.ZERO)
	if flicker > 0.0 and fmod(time * 23.0, 1.0) < 0.5:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0, 0, 0, 0.45))


# --- Jugador ---

func _draw_player() -> void:
	var look := player_look.duplicate()
	var digital := Color(look["outfit_color"])
	look["outfit_color"] = Color(SHIRT).lerp(digital, outfit_shift).to_html(false)
	look["accessory"] = look.get("accessory", 0) if look.get("accessory", 0) in [1, 2] else 0   # sin gorra en la entrevista
	var feet := Vector2(player_x, FLOOR_Y + (6.0 if kneeling else 0.0))
	if kneeling:
		look["height"] = 0.72
	CharacterAppearance.draw(self, feet, 1.0, look, player_facing, Color(0, 0, 0, 0), walk_phase)
	if outfit_shift < 0.5:
		# Marcas de sudor y el portafolio de plástico bajo el brazo.
		var hs := float(look.get("height", 1.0))
		var side := 1.0 if player_facing.x >= 0.0 else -1.0
		for s in [-1.0, 1.0]:
			draw_circle(feet + Vector2(s * 5.5, -20.5 * hs), 1.6, Color(0.55, 0.52, 0.42, 0.55))
		draw_rect(Rect2(feet + Vector2(side * 6.0 - 3.0, -21.0 * hs), Vector2(6, 9)), PORTFOLIO)
		draw_rect(Rect2(feet + Vector2(side * 6.0 - 3.0, -21.0 * hs), Vector2(6, 9)), PORTFOLIO.darkened(0.4), false, 1.0)
	if outfit_shift > 0.0 and outfit_shift < 1.0:
		# La ropa se descompone en binario.
		for k in 6:
			var y := feet.y - 8.0 - k * 3.0 - fmod(time * 30.0 + k * 7.0, 20.0)
			draw_string(_font, Vector2(feet.x - 6 + (k % 3) * 4, y), "1" if k % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color(0.3, 1.0, 0.5, 0.8 * (1.0 - absf(outfit_shift - 0.5) * 2.0)))


# --- Calle: malecón de Mazatlán al mediodía ---

func _draw_street() -> void:
	var w := width()
	# Cielo blanco de calor y sol.
	for k in 8:
		draw_rect(Rect2(0, k * 14.0, w, 14.0), Color("bcd8e4").lerp(Color("f4ead2"), k / 7.0))
	var sun := Vector2(cam_x + 330.0, 30.0)
	draw_circle(sun, 22.0, Color(1.0, 0.95, 0.75, 0.25))
	draw_circle(sun, 14.0, Color("fff3c4"))
	for k in 12:
		var a := TAU * k / 12.0 + time * 0.2
		draw_line(sun + Vector2.from_angle(a) * 18.0, sun + Vector2.from_angle(a) * (24.0 + 3.0 * sin(time * 3.0 + k)), Color("fff3c4"), 1.0)
	# Mar y olas.
	draw_rect(Rect2(0, 112, w, 40), Color("4f8fa8"))
	for k in int(w / 24.0) + 1:
		var x := k * 24.0 + fmod(time * 6.0, 24.0)
		draw_line(Vector2(x, 120 + (k % 3) * 9), Vector2(x + 10, 120 + (k % 3) * 9), Color("8cc1d2"), 1.0)
	# Isla del Crestón al fondo (y su faro).
	draw_colored_polygon(PackedVector2Array([Vector2(40, 112), Vector2(80, 88), Vector2(110, 96), Vector2(150, 112)]), Color("6f8a76"))
	draw_rect(Rect2(84, 80, 3, 9), Color("e8e4d8"))
	# Muro del malecón y barandal.
	draw_rect(Rect2(0, 150, w, 16), Color("c9b89a"))
	for k in int(w / 16.0) + 1:
		draw_rect(Rect2(k * 16.0, 142, 2, 8), Color("d8cbb0"))
	draw_line(Vector2(0, 142), Vector2(w, 142), Color("d8cbb0"), 1.0)
	# Palmeras.
	for px in [120.0, 300.0, 470.0]:
		_draw_palm(Vector2(px, 166))
	# Banqueta y calle.
	draw_rect(Rect2(0, 166, w, 60), Color("a8a296"))
	for k in int(w / 32.0) + 1:
		draw_line(Vector2(k * 32.0, 166), Vector2(k * 32.0, 225), Color("98928a"), 1.0)
	draw_line(Vector2(0, 205), Vector2(w, 205), Color("8e887e"), 1.0)
	# La universidad, a la derecha.
	var b := Rect2(560, 40, 200, 126)
	draw_rect(b, Color("e6dcc8"))
	draw_rect(Rect2(b.position, Vector2(b.size.x, 10)), Color("8a2d3a"))
	for row in 3:
		for col in 5:
			draw_rect(Rect2(b.position + Vector2(14 + col * 36, 22 + row * 28), Vector2(20, 16)), Color("7f9eb0"))
	draw_rect(Rect2(620, 118, 44, 48), Color("5a4a3a"))   # puerta
	draw_rect(Rect2(624, 122, 17, 44), Color("7f9eb0"))
	draw_rect(Rect2(643, 122, 17, 44), Color("7f9eb0"))
	draw_rect(Rect2(586, 100, 152, 14), Color("8a2d3a"))
	draw_string(_font, Vector2(590, 110), "UNIVERSIDAD AUTÓNOMA DE OCCIDENTE", HORIZONTAL_ALIGNMENT_LEFT, 148, 7, Color("f4ead2"))
	draw_string(_font, Vector2(574, 36), "UAdeO · Unidad Mazatlán", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("5a4a3a"))
	# Puesto de raspados abandonado (el calor ganó).
	draw_rect(Rect2(200, 150, 26, 16), Color("d86a4a"))
	draw_rect(Rect2(196, 140, 34, 4), Color("f0d060"))
	draw_string(_font, Vector2(198, 162), "RASPADOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("fff3c4"))


func _draw_palm(base: Vector2) -> void:
	for k in 8:
		draw_rect(Rect2(base + Vector2(-2 + sin(k * 0.4) * 2.0, -k * 8.0 - 8.0), Vector2(5, 8)), Color("8a6a4a").darkened(0.08 * (k % 2)))
	var top := base + Vector2(sin(3.2) * 2.0, -70)
	for k in 6:
		var a := PI + PI * k / 5.0 + sin(time * 1.2 + k) * 0.05
		var mid := top + Vector2.from_angle(a) * 12.0 + Vector2(0, -2)
		var tip := top + Vector2.from_angle(a) * 22.0 + Vector2(0, 6)
		draw_polyline(PackedVector2Array([top, mid, tip]), Color("5f8a4a"), 3.0)


# --- Pasillo ---

func _draw_hallway() -> void:
	var w := width()
	draw_rect(Rect2(0, 0, w, FLOOR_Y), Color("d8cfb8"))
	draw_rect(Rect2(0, 0, w, 18), Color("bfb59c"))
	draw_rect(Rect2(0, FLOOR_Y - 34, w, 34), Color("9a8e74"))   # zócalo
	for k in int(w / 20.0) + 1:
		draw_rect(Rect2(k * 20.0, FLOOR_Y, 20, 30), Color("b8b0a0") if k % 2 == 0 else Color("a8a090"))
	# Lámparas.
	for k in int(w / 90.0) + 1:
		var x := 40.0 + k * 90.0
		draw_rect(Rect2(x, 18, 36, 4), Color("f4f0dc") if flicker <= 0.0 or k % 2 == 0 else Color("807a6a"))
	# Puertas de salones.
	for x in [90.0, 250.0, 410.0]:
		draw_rect(Rect2(x, 108, 36, 90), Color("7a6a54"))
		draw_rect(Rect2(x + 6, 116, 24, 22), Color("aac0c8"))
		draw_circle(Vector2(x + 30, 156), 1.5, Color("d9c070"))
	# Tablero de avisos.
	draw_rect(Rect2(140, 70, 80, 50), Color("8a6a4a"))
	draw_rect(Rect2(144, 74, 72, 42), Color("c8a878"))
	var flyers := ["SE BUSCA PRACTICANTE", "Req: 5 años exp.", "Titulación: trámite", "TORNEO DE FUT 7"]
	for k in flyers.size():
		draw_rect(Rect2(147 + (k % 2) * 36, 77 + (k / 2) * 20, 32, 17), Color("f4f0e0"))
		draw_string(_font, Vector2(148 + (k % 2) * 36, 86 + (k / 2) * 20), flyers[k], HORIZONTAL_ALIGNMENT_LEFT, 30, 4, Color("3a3a3a"))
	# Ventiladores industriales forzados al límite.
	for x in [320.0, 560.0]:
		var c := Vector2(x, 60)
		draw_circle(c, 14, Color("8a8a8a"))
		for k in 3:
			var a := time * 30.0 + TAU * k / 3.0
			draw_line(c, c + Vector2.from_angle(a) * 12.0, Color("5a5a5a"), 3.0)
		draw_circle(c, 3, Color("3a3a3a"))
	# Ventanilla de cobro.
	draw_rect(Rect2(600, 92, 70, 70), Color("8a7a5a"))
	draw_rect(Rect2(608, 104, 54, 34), Color("5a5a5a"))
	for k in 6:
		draw_line(Vector2(608, 106 + k * 5), Vector2(662, 106 + k * 5), Color("7a7a7a"), 1.0)   # cortina cerrada
	draw_rect(Rect2(600, 80, 70, 12), Color("2d5a8a"))
	draw_string(_font, Vector2(604, 89), "CAJA · TRÁMITES", HORIZONTAL_ALIGNMENT_LEFT, 64, 7, Color.WHITE)
	draw_string(_font, Vector2(610, 150), "Regreso en 15 min", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("f4f0e0"))
	# La puerta gris lisa, entreabierta, al fondo.
	draw_rect(Rect2(730, 100, 44, 98), Color("1a1a1a"))
	draw_colored_polygon(PackedVector2Array([Vector2(730, 100), Vector2(758, 104), Vector2(758, 194), Vector2(730, 198)]), Color("8e9196"))
	draw_rect(Rect2(722, 84, 60, 12), Color("3a3a3a"))
	draw_string(_font, Vector2(725, 93), "Depto. Informática", HORIZONTAL_ALIGNMENT_LEFT, 56, 6, Color("e0e0e0"))
	# Luz verdosa de monitores que sale por la rendija.
	draw_colored_polygon(PackedVector2Array([Vector2(758, 104), Vector2(774, 100), Vector2(800, 198), Vector2(758, 194)]), Color(0.4, 1.0, 0.6, 0.06 + 0.03 * sin(time * 7.0)))


# --- Oficina destrozada ---

func _draw_office() -> void:
	var w := width()
	var shake := Vector2(sin(time * 60.0), cos(time * 47.0)) * rack_shake * 1.5
	draw_rect(Rect2(0, 0, w, FLOOR_Y), Color("c9c2ac"))
	for k in int(w / 20.0) + 1:
		draw_rect(Rect2(k * 20.0, FLOOR_Y, 20, 30), Color("9c968a") if k % 2 == 0 else Color("8e887c"))
	# Lámparas fluorescentes que parpadean.
	for x in [60.0, 200.0, 330.0]:
		var on := flicker <= 0.0 or fmod(time * 17.0 + x, 1.0) < 0.4
		draw_rect(Rect2(x, 6, 50, 4), Color("f4f8e8") if on else Color("6a6a60"))
	# Minisplit goteando sobre una torre quemada.
	draw_rect(Rect2(40, 30, 60, 18), Color("e8e8e0"))
	draw_line(Vector2(44, 44), Vector2(96, 44), Color("a0a098"), 1.0)
	var drip := fmod(time * 0.9, 1.0)
	draw_rect(Rect2(70, 50 + drip * 110, 2, 3), Color("8ab8d8"))
	draw_rect(Rect2(56, 162, 30, 36), Color("2a2a2a"))
	draw_rect(Rect2(56, 162, 30, 36), Color("4a3a2a"), false, 1.0)
	draw_circle(Vector2(70, 176), 5, Color("1a120c"))   # quemado
	draw_string(_font, Vector2(52, 160), "sin tapa", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("6a5a4a"))
	# Archivadores volcados contra la pared.
	draw_colored_polygon(PackedVector2Array([Vector2(108, 198), Vector2(114, 150), Vector2(140, 154), Vector2(134, 198)]), Color("7a8288"))
	for k in 4:
		draw_line(Vector2(112, 160 + k * 10), Vector2(136, 162 + k * 10), Color("5a6268"), 1.0)
	draw_rect(Rect2(140, 182, 40, 16), Color("6e767c"))
	# Monitores CRT beige apilados en la esquina.
	for k in 3:
		var m := Rect2(4 + (k % 2) * 6, 160 - k * 22, 28, 22)
		draw_rect(m, Color("d8cca0"))
		draw_rect(m.grow(-4), Color("3a4a3a"))
	# El rack negro del rincón (y su temblor).
	var rack := Rect2(Vector2(350, 70) + shake, Vector2(42, 128))
	draw_rect(rack, Color("151518"))
	for k in 9:
		var y := rack.position.y + 8 + k * 13
		draw_rect(Rect2(rack.position.x + 4, y, 34, 9), Color("23232a"))
		var on := sin(time * (6.0 + k * 2.0) + k) > 0.0 or rack_shake > 0.3
		draw_circle(Vector2(rack.end.x - 8, y + 4.5), 1.2, Color("ff4a3a") if rack_shake > 0.3 else (Color("3cff6a") if on else Color("1a4a2a")))
	draw_string(_font, rack.position + Vector2(2, -3), "EL MONOLITO (2004)", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("4a4a4a"))
	# Rafa, de pie o sentado tras la barricada.
	# Sentado solo asoma la cabeza sobre el escritorio; al levantarse de golpe, medio cuerpo.
	var rafa_feet := Vector2(314, FLOOR_Y - (12.0 if rafa_standing else 0.0))
	CharacterAppearance.draw(self, rafa_feet, 1.0, rafa_look, Vector2.LEFT if rafa_standing else Vector2(-0.3, 1.0))


## Lo que va delante de Rafa y del jugador (la barricada, los cables, los papeles).
func _draw_office_front() -> void:
	# Escritorio con panel frontal (tapa las piernas de Rafa) y el monitor
	# ultrapanorámico lleno de consolas negras, a su izquierda.
	draw_rect(Rect2(232, 176, 112, 4), Color("6a5440"))
	draw_rect(Rect2(234, 180, 108, 18), Color("5a4430"))
	draw_line(Vector2(234, 189), Vector2(342, 189), Color("4a3420"), 1.0)
	var mon := Rect2(236, 150, 64, 24)
	draw_rect(mon, Color("101014"))
	for k in 3:
		var win := Rect2(mon.position + Vector2(3 + k * 20, 3), Vector2(18, 18))
		draw_rect(win, Color("050506"))
		for j in 4:
			var red := rack_shake > 0.3 and k == 1
			draw_line(win.position + Vector2(2, 3 + j * 4), win.position + Vector2(3 + fmod(time * 9.0 + j * 5.0 + k * 3.0, 13.0), 3 + j * 4),
				Color("ff5a4a") if red else Color("3cff6a"), 1.0)
	draw_rect(Rect2(264, 174, 8, 2), Color("2a2a2a"))
	# La taza de Rafa: «Don't talk to me before git pull».
	draw_rect(Rect2(326, 168, 7, 8), Color("f0f0f0"))
	draw_arc(Vector2(334, 172), 2.5, -PI / 2.0, PI / 2.0, 6, Color("f0f0f0"), 1.0)
	draw_line(Vector2(327, 171), Vector2(332, 171), Color("4a4a4a"), 1.0)
	# Barricada de cajas y manuales engargolados (a un lado, sin tapar al jugador).
	for b in [Rect2(208, 174, 24, 24), Rect2(212, 156, 18, 18)]:
		draw_rect(b, Color("b08a5a"))
		draw_line(b.position + Vector2(0, b.size.y / 2.0), b.position + Vector2(b.size.x, b.size.y / 2.0), Color("8a6a40"), 1.0)
	for k in 4:
		draw_rect(Rect2(184 + k * 2, 192 - k * 4, 22, 4), [Color("c84b4b"), Color("4b8bd6"), Color("e8e0c8"), Color("5cb85c")][k])	# Cables UTP pelados: en la caída, enredaderas de cobre que palpitan.
	var copper := Color("c87a3a")
	for k in 4:
		var pts := PackedVector2Array()
		for j in 12:
			var x := j * 34.0
			var y := FLOOR_Y + 4.0 + k * 5.0 + sin(j * 1.3 + k) * 3.0 + sin(time * 3.0 + j) * 3.0 * dissolve
			pts.append(Vector2(x, y))
		var color := Color("4a7acc").lerp(copper, dissolve) if k % 2 == 0 else Color("e8e0c8").lerp(copper.darkened(0.2), dissolve)
		draw_polyline(pts, color, 1.0 + dissolve * 2.0 + (sin(time * 6.0 + k) * dissolve))
	# Papeles por el suelo (formatos de reinscripción de 2008) que se vuelven logs.
	for p in _papers:
		var pos := Vector2(p["x"], p["y"] - dissolve * (20.0 + 30.0 * sin(time * p["speed"] + p["phase"])))
		if dissolve < 0.5:
			draw_set_transform(pos - Vector2(roundf(cam_x), 0), p["r"], Vector2.ONE)
			draw_rect(Rect2(-5, -3, 10, 7), Color("f2eee0"))
			draw_line(Vector2(-3, -1), Vector2(3, -1), Color("9a9a9a"), 1.0)
			draw_set_transform(Vector2(-roundf(cam_x), 0))
		else:
			var lines := ["ERR", "WARN", "0x0F", "null", "500", "OOM"]
			draw_string(_font, pos, lines[int(p["x"]) % lines.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
				Color(1.0, 0.85, 0.3, 0.9) if int(p["x"]) % 2 == 0 else Color(0.4, 1.0, 0.6, 0.9))
