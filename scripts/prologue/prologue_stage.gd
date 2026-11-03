class_name PrologueStage
extends Node2D
## Escenario del prólogo, dibujado en pequeño (400×225) y escalado sin
## suavizado: pixel art de verdad. Tres sitios en vista lateral:
##   calle    — el malecón de Mazatlán al mediodía, camino a la UAdeO.
##   pasillo  — vista de sur a norte (en perspectiva): se camina de frente hacia la
##              caja de trámites; la puerta de Informática, a la izquierda.
##   oficina  — el departamento destrozado, con Rafa atrincherado.
## `dissolve` (0..1) convierte la oficina en el mundo digital (papeles en logs,
## cables en enredaderas de cobre).

const VIEW := Vector2(400, 225)
const FLOOR_Y := 198.0
const ROOM_WIDTH := {"calle": 760.0, "pasillo": 400.0, "oficina": 400.0}
## Hasta dónde se puede caminar en cada sitio (vista lateral). En la calle, poco
## más allá de la entrada de la UAdeO: el resto de la avenida no lleva a nada y
## el personaje acababa fuera de la pantalla.
const WALK_LIMITS := {"calle": Vector2(14.0, 540.0), "oficina": Vector2(16.0, 384.0)}
## Centro de la entrada blanca del bloque principal de la UAdeO (calle).
const ENTRANCE_X := 448.0
## Dónde se dibuja la flecha del siguiente objetivo (sobre lo que se ve: las
## escaleras de la UAdeO, la puerta de Informática, Rafa y el rack negro).
const GOAL_MARKERS := {"to_hallway": Vector2(448, 126), "to_office": Vector2(85, 64), "talk_rafa": Vector2(314, 148), "rack": Vector2(371, 62)}
## Puntos de interés por sitio: x en el mundo (o lat/depth en el pasillo), texto del aviso y acción.
const HOTSPOTS := {
	"calle": [{"x": 448.0, "text": "E · Cruzar la avenida y entrar a la UAdeO", "action": "to_hallway"}],
	"pasillo": [{"lat": -0.85, "depth": 0.8, "text": "E · Departamento de Informática", "action": "to_office"},
		{"lat": -0.12, "depth": 0.96, "text": "E · Caja de trámites", "action": "window"},
		{"lat": 0.5, "depth": 0.96, "text": "E · Ver la TV", "action": "tv"}],
	"oficina": [{"x": 272.0, "text": "E · Hablar con el encargado", "action": "talk_rafa"}],
}
## Pasillo en perspectiva: profundidad 0 (cerca) .. 1 (al fondo) y lateral -1..1.
const HALL_NEAR_Y := 214.0
const HALL_FAR_Y := 150.0
const HALL_BACK_LEFT := 110.0
const HALL_BACK_RIGHT := 290.0
## Logo del Hackatón LinceCode en pixel art (M = guinda, G = dorado).
const LYNX := [
	"......M...........",
	".....MM...M.......",
	"....MGM..MM.......",
	"....MGMMMMM.......",
	"...MMGMMMMMM......",
	"...MMMMMMGGMM.....",
	"..MMMMMMMMMMMM....",
	"..MMGGGGMMMMMMMMM.",
	".MMGMMMMGMMMMMMMMM",
	".MMGMMMMMGMMMMM...",
	"MMMGMMGMMMGMMMM...",
	"MMGMMGMMMMMGMM....",
	"MGMMGMMMMMMMGM....",
	"GMMGMMMMMMMMMG....",
	"MMGMMMMMMMMMMMG...",
	"MGMMMMMMMMMMMMMG..",
]
const SHIRT := "e9e5d8"
const PORTFOLIO := Color("3d6fb0")

var room := "calle"
var cam_x := 0.0
var player_x := 40.0
## Solo en el pasillo: profundidad (0..1) y desplazamiento lateral (-1..1).
var player_depth := 0.0
var player_lat := 0.0
var player_facing := Vector2.RIGHT
var walk_phase := -1.0
var player_look: Dictionary = CharacterAppearance.default()
var rafa_look: Dictionary = CharacterAppearance.default()
var mario_look: Dictionary = CharacterAppearance.default()
var aida_look: Dictionary = CharacterAppearance.default()
## Mario (con el carrito de frituras) y Aida entrando a la oficina: x de Mario (< -100 = no están).
var visitors_x := -999.0
var visitors_walk := -1.0
## Ropa formal (0) → ropa del mundo digital (1).
var outfit_shift := 0.0
var kneeling := false
var rafa_standing := false
var time := 0.0
var flicker := 0.0
var rack_shake := 0.0
var dissolve := 0.0
## Absorción por el servidor: 0 → 1 (Mario, Aida, el carrito y Rafa, por turnos)
## y, aparte, la del jugador (en la caída).
var absorb := 0.0
var player_pull := 0.0
## Centro del vórtice: la cara del rack negro («El Monolito»).
const VORTEX := Vector2(371, 112)
## Turno de cada uno en la absorción (fracción de `absorb` en que empieza a volar).
const PULL_DELAY := {"cart": 0.0, "mario": 0.12, "aida": 0.3, "rafa": 0.5}
const PULL_SPAN := 0.42
## Hotspot resaltado: {pos: Vector2 (en el mundo), text}
var prompt: Dictionary = {}
## Siguiente objetivo (en el mundo): una flecha que rebota encima. INF = ninguno.
var goal := Vector2.INF
var _font: Font
var _papers: Array[Dictionary] = []
var _walker_looks: Array[Dictionary] = []   # peatones de la calle y la figura del pasillo (T188)
var _hall_look: Dictionary = {}


func _ready() -> void:
	_font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 2008
	for k in 12:
		_papers.append({"x": rng.randf_range(20, 380), "y": rng.randf_range(150, 205), "r": rng.randf_range(-0.6, 0.6),
			"speed": rng.randf_range(0.5, 1.5), "phase": rng.randf() * TAU})
	for p in WALKERS:
		rng.seed = int(p[2])
		_walker_looks.append(CharacterAppearance.random(rng))
	rng.seed = 404
	_hall_look = CharacterAppearance.random(rng)


## Pasillo: de (lateral, profundidad) a un punto del escenario, y al revés.
static func hall_to_screen(lat: float, depth: float) -> Vector2:
	return Vector2(200.0 + lat * lerpf(185.0, 88.0, depth), lerpf(HALL_NEAR_Y, HALL_FAR_Y, depth))


static func hall_from_screen(p: Vector2) -> Vector2:
	var depth := clampf((HALL_NEAR_Y - p.y) / (HALL_NEAR_Y - HALL_FAR_Y), 0.0, 1.0)
	return Vector2(clampf((p.x - 200.0) / lerpf(185.0, 88.0, depth), -0.85, 0.85), depth)


static func hall_scale(depth: float) -> float:
	return lerpf(1.3, 0.62, depth)


func width() -> float:
	return ROOM_WIDTH.get(room, VIEW.x)


## Rafa se levanta con una animación corta en vez de un corte (T187): 0 sentado, 1 de pie.
const RAFA_STAND_TIME := 0.45
var rafa_stand_k := 0.0


func _process(delta: float) -> void:
	time += delta
	flicker = maxf(0.0, flicker - delta)
	rack_shake = maxf(0.0, rack_shake - delta * 0.2)
	rafa_stand_k = move_toward(rafa_stand_k, 1.0 if rafa_standing else 0.0, delta / RAFA_STAND_TIME)
	queue_redraw()


## Cuánto se ha levantado Rafa (0..1) con un pequeño impulso al final: se pasa un poco
## hacia arriba y se asienta.
static func rafa_rise(k: float) -> float:
	return UiMotion.overshoot(k, 0.0) if k < 1.0 else 1.0


## Hacia dónde mira Rafa sentado: al monitor tecleando, o al jugador cuando entra en la
## oficina y se acerca (T187).
static func rafa_facing(standing: bool, player_x_now: float, in_office: bool) -> Vector2:
	if standing:
		return Vector2.LEFT
	if in_office and player_x_now > 120.0:
		return Vector2(-1.0, 0.5)
	return Vector2(-0.3, 1.0)


func _draw() -> void:
	draw_set_transform(Vector2(-roundf(cam_x), 0))
	match room:
		"calle":
			_draw_street()
		"pasillo":
			_draw_hallway()
		"oficina":
			_draw_office()
	if room == "oficina":
		# El jugador, delante del escritorio (y de la barricada).
		_draw_office_front()
		_draw_visitors()
		_draw_player()
	else:
		_draw_player()
		if room == "calle":
			_draw_street_front()
	if not prompt.is_empty():
		var p: Vector2 = prompt["pos"]
		var bob := sin(time * 4.0) * 1.5
		var text: String = prompt["text"]
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0
		draw_rect(Rect2(p + Vector2(-w / 2.0, -14 + bob), Vector2(w, 12)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(p + Vector2(-w / 2.0, -14 + bob), Vector2(w, 12)), Color("d9a441"), false, 1.0)
		draw_string(_font, p + Vector2(-w / 2.0 + 5, -5 + bob), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2e6c0"))
	elif goal != Vector2.INF:
		# Flecha dorada que rebota sobre el siguiente objetivo.
		var g := goal + Vector2(0, sin(time * 4.0) * 2.5)
		var arrow := PackedVector2Array([g + Vector2(-5, -7), g + Vector2(5, -7), g])
		draw_colored_polygon(PackedVector2Array([g + Vector2(-6, -8), g + Vector2(6, -8), g + Vector2(0, 1)]), Color(0, 0, 0, 0.6))
		draw_colored_polygon(arrow, Color("d9a441"))
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
	var sc := 1.0
	if room == "pasillo":
		feet = hall_to_screen(player_lat, player_depth)
		sc = hall_scale(player_depth)
	if kneeling:
		look["height"] = 0.72
	if player_pull > 0.0:
		# El último en caer: el vórtice también lo arrastra a él.
		if player_pull >= 1.0:
			return
		var home := feet
		feet = home.lerp(VORTEX + Vector2(0, 16), player_pull * player_pull) + Vector2.from_angle(time * 9.0) * 10.0 * player_pull * (1.0 - player_pull)
		sc *= 1.0 - 0.85 * player_pull * player_pull
		_draw_pull_trail(home, feet, player_pull, Color("3cff6a"))
		_draw_scream(feet, player_pull, "¡¿QUÉ PASA?!")
	# Quieto, respira (T187); antes se quedaba congelado a media zancada.
	var pose := {} if walk_phase >= 0.0 or player_pull > 0.0 else {"state": "idle", "time": time}
	CharacterAppearance.draw(self, feet, sc, look, player_facing, Color(0, 0, 0, 0), walk_phase, pose)
	if outfit_shift < 0.5:
		# Marcas de sudor y el portafolio de plástico bajo el brazo (de espaldas no se ven).
		var hs := float(look.get("height", 1.0))
		var side := 1.0 if player_facing.x >= 0.0 else -1.0
		if player_facing.y > -0.5:
			for s in [-1.0, 1.0]:
				draw_circle(feet + Vector2(s * 5.5, -20.5 * hs) * sc, 1.6 * sc, Color(0.55, 0.52, 0.42, 0.55))
		var folder := Rect2(feet + Vector2(side * 6.0 - 3.0, -21.0 * hs) * sc, Vector2(6, 9) * sc)
		draw_rect(folder, PORTFOLIO)
		draw_rect(folder, PORTFOLIO.darkened(0.4), false, 1.0)
	if outfit_shift > 0.0 and outfit_shift < 1.0:
		# La ropa se descompone en binario.
		for k in 6:
			var y := feet.y - 8.0 - k * 3.0 - fmod(time * 30.0 + k * 7.0, 20.0)
			draw_string(_font, Vector2(feet.x - 6 + (k % 3) * 4, y), "1" if k % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color(0.3, 1.0, 0.5, 0.8 * (1.0 - absf(outfit_shift - 0.5) * 2.0)))


# --- Calle: la UAdeO, frente al malecón de Mazatlán ---

func _draw_street() -> void:
	var w := width()
	# Cielo despejado de Mazatlán al mediodía.
	for k in 10:
		draw_rect(Rect2(0, k * 13.0, w, 13.0), Color("8cc4e8").lerp(Color("d8ecf4"), k / 9.0))
	var sun := Vector2(cam_x + 60.0, 26.0)
	draw_circle(sun, 20.0, Color(1.0, 0.97, 0.8, 0.3))
	draw_circle(sun, 12.0, Color("fff6d0"))
	for k in 12:
		var a := TAU * k / 12.0 + time * 0.2
		draw_line(sun + Vector2.from_angle(a) * 16.0, sun + Vector2.from_angle(a) * (21.0 + 3.0 * sin(time * 3.0 + k)), Color("fff6d0"), 1.0)
	_draw_clouds(w)
	# A la derecha de la escuela: la calle que baja y la torre de departamentos.
	_draw_side_street()
	_draw_tower()
	_draw_palm(Vector2(36, 160))
	# Reja beige a la izquierda, hasta el anexo.
	draw_rect(Rect2(0, 126, 66, 3), Color("d8c8a0"))
	draw_rect(Rect2(0, 164, 66, 3), Color("d8c8a0"))
	for k in 7:
		draw_rect(Rect2(k * 10.0, 126, 3, 41), Color("e2d4b0"))
		draw_rect(Rect2(k * 10.0 + 2, 126, 1, 41), Color("c4b48e"))
	_draw_uadeo()
	# Poste de luz blanco (a la izquierda, sin tapar la fachada).
	draw_rect(Rect2(20, 34, 3, 136), Color("f0f0ec"))
	draw_rect(Rect2(22, 34, 1, 136), Color("c8c8c2"))
	draw_rect(Rect2(12, 32, 12, 3), Color("f0f0ec"))
	draw_rect(Rect2(12, 35, 5, 2), Color("fff6c8"))
	# Banqueta de la escuela, la avenida y el camellón.
	draw_rect(Rect2(0, 168, w, 8), Color("cfcac0"))
	draw_rect(Rect2(0, 176, w, 16), Color("6c6c6e"))
	for k in int(w / 30.0) + 1:
		draw_rect(Rect2(k * 30.0 + 6, 183, 14, 2), Color("e8e4d8"))
	draw_rect(Rect2(0, 191, w, 3), Color("e8c040"))   # guarnición amarilla
	# Malecón (donde camina el jugador), barandal y el mar en primer plano.
	draw_rect(Rect2(0, 194, w, 18), Color("d6cdb8"))
	for k in int(w / 24.0) + 1:
		draw_line(Vector2(k * 24.0, 194), Vector2(k * 24.0, 212), Color("c6bca6"), 1.0)
	draw_rect(Rect2(0, 212, w, 13), Color("3f8db0"))
	for k in int(w / 20.0) + 1:
		var x := k * 20.0 + fmod(time * 5.0, 20.0)
		draw_line(Vector2(x, 216 + (k % 2) * 4), Vector2(x + 8, 216 + (k % 2) * 4), Color("9fd0e4"), 1.0)
	draw_line(Vector2(0, 211), Vector2(w, 211), Color("f0ece0"), 1.0)
	_draw_street_life(w)


## Posición x de algo que cruza en bucle (autos, peatones, gaviotas): entra por un lado
## y, al salir por el otro, vuelve a empezar; `span` es el ancho del sitio.
static func loop_x(base: float, speed: float, t: float, span: float) -> float:
	return fposmod(base + speed * t, span + 80.0) - 40.0


## Autos de la avenida en bucle: [x de salida, velocidad (signo = sentido), y de las
## ruedas, color]. El carril de atrás va hacia la izquierda.
const TRAFFIC := [[40.0, -26.0, 183.0, "5a7a9a"], [420.0, -31.0, 183.0, "e8e4d8"],
	[200.0, 38.0, 189.0, "c03a3a"], [600.0, 34.0, 189.0, "2a2a2e"]]
## Peatones en la banqueta de la escuela: [x de salida, velocidad, semilla del aspecto].
const WALKERS := [[120.0, 11.0, 7], [520.0, -9.0, 31]]


## La calle con vida (T188): autos que pasan por la avenida, gente en la banqueta,
## gaviotas y el sol brillando en el mar.
func _draw_street_life(w: float) -> void:
	for g in 3:   # gaviotas: una V que aletea
		var gx := loop_x(100.0 + g * 260.0, 9.0 + g * 3.0, time, w)
		var gy := 38.0 + g * 9.0 + sin(time * 0.8 + g) * 4.0
		var flap := sin(time * 7.0 + g * 2.0) * 2.0
		draw_line(Vector2(gx - 4, gy - flap), Vector2(gx, gy), Color("f4f4f0"), 1.0)
		draw_line(Vector2(gx, gy), Vector2(gx + 4, gy - flap), Color("f4f4f0"), 1.0)
	for i in WALKERS.size():
		var p: Array = WALKERS[i]
		var px := loop_x(p[0], p[1], time, w)
		var look: Dictionary = _walker_looks[i]
		var phase := fmod(absf(px) / 6.0 * PI, TAU)
		CharacterAppearance.draw(self, Vector2(px, 175.0), 0.55, look, Vector2.RIGHT if p[1] > 0.0 else Vector2.LEFT, Color(0, 0, 0, 0), phase)
	for car in TRAFFIC:
		_draw_car(loop_x(car[0], car[1], time, w), car[2], Color(car[3]), car[1] < 0.0)
	for k in 16:   # destellos del sol sobre el agua
		var gx := fposmod(k * 53.7 + sin(time * 0.7 + k) * 6.0, w)
		if sin(time * 3.0 + k * 1.7) > 0.55:
			draw_rect(Rect2(gx, 214 + (k % 4) * 2.5, 2, 1), Color(1, 1, 0.92, 0.9))


## Auto de perfil, en pixel art: carrocería, cabina con cristal y ruedas que giran.
func _draw_car(x: float, wheel_y: float, col: Color, left: bool) -> void:
	var dir := -1.0 if left else 1.0
	var body := Rect2(x - 13, wheel_y - 7, 26, 5)
	draw_rect(body, col)
	draw_rect(Rect2(body.position, Vector2(body.size.x, 1)), col.lightened(0.25))
	var cab := Rect2(x - 7 - dir * 1.0, wheel_y - 11, 13, 4)
	draw_rect(cab, col)
	draw_rect(cab.grow(-1), Color("6a8a9a"))
	draw_rect(Rect2(x + dir * 12.0 - 1.0, wheel_y - 6, 2, 1), Color("fff2a0"))   # faro
	for wx in [x - 8.0, x + 8.0]:
		draw_circle(Vector2(wx, wheel_y - 1), 2.2, Color("1e1e22"))
		var spin := time * 9.0 * dir
		draw_line(Vector2(wx, wheel_y - 1), Vector2(wx, wheel_y - 1) + Vector2.from_angle(spin) * 1.6, Color("8a8a8a"), 1.0)


## Calle lateral que baja hacia el fondo (separa la escuela de la torre): el muro
## de block de la escuela en perspectiva, autos estacionados y casas a lo lejos.
func _draw_side_street() -> void:
	var vp := Vector2(611, 140)   # punto de fuga
	# Fondo: casas blancas, un edificio rojo y copas de árboles junto al horizonte.
	draw_rect(Rect2(596, 124, 34, 22), Color("cfe0dc"))
	draw_rect(Rect2(598, 128, 8, 18), Color("f2f0ea"))
	draw_rect(Rect2(606, 132, 6, 14), Color("e6e2da"))
	draw_rect(Rect2(614, 130, 7, 16), Color("f4f2ec"))
	for k in 3:
		draw_rect(Rect2(599 + k * 2.5, 131, 1, 2), Color("8aa4b0"))
	draw_circle(Vector2(624, 136), 6, Color("5f8a4a"))
	draw_circle(Vector2(630, 138), 5, Color("4f7a40"))
	draw_rect(Rect2(608, 112, 1, 34), Color("8a7a66"))   # poste de luz al fondo
	draw_line(Vector2(566, 96), Vector2(608, 114), Color(0.3, 0.3, 0.3, 0.5), 1.0)   # cables
	draw_line(Vector2(608, 114), Vector2(660, 104), Color(0.3, 0.3, 0.3, 0.5), 1.0)
	# La calle: asfalto que se angosta, banquetas a los lados.
	draw_colored_polygon(PackedVector2Array([Vector2(570, 168), Vector2(662, 168), Vector2(vp.x + 6, 146), Vector2(vp.x - 6, 146)]), Color("76767a"))
	draw_colored_polygon(PackedVector2Array([Vector2(566, 168), Vector2(574, 168), Vector2(vp.x - 6, 146), Vector2(vp.x - 8, 146)]), Color("c8c2b6"))
	draw_colored_polygon(PackedVector2Array([Vector2(658, 168), Vector2(668, 168), Vector2(vp.x + 9, 146), Vector2(vp.x + 6, 146)]), Color("c8c2b6"))
	for k in 4:   # línea central discontinua, cada vez más corta
		var t0 := 0.15 + k * 0.22
		var a := Vector2(616, 168).lerp(Vector2(vp.x, 146), t0)
		var b := Vector2(616, 168).lerp(Vector2(vp.x, 146), t0 + 0.1)
		draw_line(a, b, Color("e8e4d8"), 1.0)
	# Muro lateral de la escuela (block gris) en perspectiva, con sus ventanitas.
	draw_colored_polygon(PackedVector2Array([Vector2(565, 58), Vector2(596, 100), Vector2(596, 147), Vector2(565, 168)]), Color("a8a49c"))
	for k in 9:
		var t := k / 9.0
		var x := lerpf(566, 596, t)
		draw_line(Vector2(x, lerpf(58, 100, t)), Vector2(x, lerpf(168, 147, t)), Color("928e86"), 1.0)
	for k in 6:
		var y0 := lerpf(70.0, 160.0, k / 5.0)
		draw_line(Vector2(565, y0), Vector2(596, lerpf(104.0, 145.0, k / 5.0)), Color("bab6ae"), 1.0)
	for k in 4:
		var t := 0.2 + k * 0.19
		var x := lerpf(566, 596, t)
		var top := lerpf(58, 100, t) + lerpf(30, 14, t)
		draw_rect(Rect2(x, top, lerpf(5, 2, t), lerpf(12, 6, t)), Color("f0ede6"))
		draw_rect(Rect2(x + 1, top + 1, maxf(1.0, lerpf(3, 1, t)), lerpf(10, 4, t)), Color("4e6470"))
	# Autos estacionados junto al muro, cada vez más chicos.
	for car: Array in [[586.0, 166.0, 22.0, Color("eeeeec")], [599.0, 157.0, 13.0, Color("7a6a62")], [605.0, 151.0, 8.0, Color("c03a3a")]]:
		var cx: float = car[0]
		var cy: float = car[1]
		var cw: float = car[2]
		var col: Color = car[3]
		var ch := cw * 0.42
		draw_rect(Rect2(cx - cw / 2.0, cy - ch, cw, ch * 0.6), col)
		draw_rect(Rect2(cx - cw * 0.3, cy - ch * 1.35, cw * 0.6, ch * 0.4), col)
		draw_rect(Rect2(cx - cw * 0.26, cy - ch * 1.25, cw * 0.52, ch * 0.28), Color("5a7684"))
		draw_rect(Rect2(cx - cw / 2.0, cy - ch * 0.45, cw, ch * 0.08), col.darkened(0.25))
		draw_circle(Vector2(cx - cw * 0.3, cy - ch * 0.35), maxf(1.0, cw * 0.1), Color("26262a"))
		draw_circle(Vector2(cx + cw * 0.3, cy - ch * 0.35), maxf(1.0, cw * 0.1), Color("26262a"))


## Torre de departamentos color salmón, a la derecha de la calle lateral, con
## balcones corridos, palmeras y un seto delante.
func _draw_tower() -> void:
	var tower := Rect2(626, 22, 140, 130)
	# Cara lateral que da a la calle (en perspectiva, más clara: le pega el sol).
	draw_colored_polygon(PackedVector2Array([Vector2(616, 40), Vector2(tower.position.x, tower.position.y),
		Vector2(tower.position.x, tower.end.y), Vector2(616, 148)]), Color("e6ae8c"))
	for row in 7:
		var y := tower.position.y + 12 + row * 17
		draw_line(Vector2(617, y * 0.86 + 6), Vector2(tower.position.x, y + 9), Color("c98a6c"), 2.0)
	draw_rect(tower, Color("d99a7c"))
	draw_rect(Rect2(tower.position.x - 2, tower.position.y - 4, tower.size.x + 2, 5), Color("c4846a"))   # azotea
	draw_rect(Rect2(tower.position.x, tower.position.y + 1, tower.size.x, 2), Color("eab89c"))
	for row in 7:
		var y := tower.position.y + 10 + row * 17
		for col in 6:
			var win := Rect2(tower.position.x + 8 + col * 22, y, 13, 9)
			draw_rect(win, Color("f0e6d8") if (row * 2 + col) % 5 else Color("7aa0b8"))
			draw_rect(Rect2(win.position.x + 1, win.position.y + 1, win.size.x - 2, 3), Color("5e7a88"))
		draw_rect(Rect2(tower.position.x - 2, y + 10, tower.size.x + 2, 3), Color("eec6aa"))   # balcón corrido
		draw_rect(Rect2(tower.position.x - 2, y + 13, tower.size.x + 2, 1), Color("b07258"))   # su sombra
	# Seto, barda y palmeras al frente.
	draw_rect(Rect2(618, 146, 150, 6), Color("c9a088"))
	for k in 34:
		var hx := 620.0 + k * 4.5
		draw_circle(Vector2(hx, 158 + (k % 2)), 5.0, Color("3f7a3a") if k % 3 else Color("4f8a46"))
		draw_rect(Rect2(hx - 1, 154 + (k % 3), 2, 1), Color("7ab86a"))
	draw_rect(Rect2(618, 164, 150, 4), Color("2f5a2c"))
	for px in [640.0, 676.0, 724.0]:
		_draw_palm(Vector2(px, 156))


## Nubes de pixel art que cruzan despacio (con sombra abajo y brillo arriba).
func _draw_clouds(w: float) -> void:
	for k in 4:
		var x := fposmod(80.0 + k * 190.0 + time * (3.0 + k), w + 120.0) - 60.0
		var y := 14.0 + (k % 2) * 12.0
		for blob: Vector3 in [Vector3(0, 4, 9), Vector3(10, 0, 11), Vector3(22, 4, 8), Vector3(-9, 6, 6)]:
			draw_circle(Vector2(x + blob.x, y + blob.y + 2), blob.z, Color("c9dfe8"))
			draw_circle(Vector2(x + blob.x, y + blob.y), blob.z, Color("f4f8f8"))


## Pilastra de piedra (como las del edificio): sillares con juntas y luz a la izquierda.
func _stone_pillar(r: Rect2) -> void:
	draw_rect(r, Color("b8946a"))
	var row := 0
	var y := r.position.y
	while y < r.end.y:
		var h := minf(5.0, r.end.y - y)
		var off := 0.0 if row % 2 == 0 else r.size.x * 0.5
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("8e7050"), 1.0)
		draw_line(Vector2(r.position.x + off + r.size.x * 0.25, y), Vector2(r.position.x + off + r.size.x * 0.25, y + h), Color("9a7c58"), 1.0)
		if (row + int(r.position.x)) % 3 == 0:
			draw_rect(Rect2(r.position.x + 1, y + 1, r.size.x - 2, h - 1), Color("c4a276"))   # sillar más claro
		y += 5.0
		row += 1
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color("dcc29a"))   # luz
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Color("6e5640"))   # sombra


## La UAdeO, según la fachada del modelo 3D: anexo blanco, atrio de vidrio con
## parasoles y plantas sobre una escalinata de madera, segundo piso detrás y el
## bloque principal terracota con el letrero, el escudo y la entrada blanca.
func _draw_uadeo() -> void:
	var terra := Color("b4544a")
	var terra_dark := Color("923e38")
	var terra_light := Color("c86c5e")
	# Segundo piso, al fondo: franja de ventanas.
	var back := Rect2(176, 50, 268, 26)
	draw_rect(back, Color("bb6658"))
	draw_rect(Rect2(back.position, Vector2(back.size.x, 2)), terra_light)
	for k in 17:
		var win := Rect2(back.position.x + 6 + k * 15.5, back.position.y + 8, 10, 7)
		draw_rect(win, Color("f0ece4"))
		draw_rect(win.grow(-1), Color("4e6e7c") if k % 4 else Color("8ab0c0"))
	draw_rect(Rect2(back.position.x, back.end.y - 3, back.size.x, 3), terra_dark)
	# Anexo blanco a la izquierda.
	var annex := Rect2(68, 84, 96, 84)
	draw_rect(annex, Color("e2e2de"))
	draw_rect(Rect2(annex.position, Vector2(annex.size.x, 3)), Color("8e3a34"))   # cornisa
	draw_rect(Rect2(annex.position.x, annex.position.y + 3, annex.size.x, 2), Color("c8c8c2"))
	draw_rect(Rect2(annex.end.x - 10, annex.position.y + 3, 10, annex.size.y - 3), Color("c8c8c4"))   # cara en sombra
	for k in 4:
		draw_line(Vector2(annex.position.x + 20 + k * 20, annex.position.y + 8), Vector2(annex.position.x + 20 + k * 20, annex.end.y), Color("d0d0cc"), 1.0)
	# Atrio: pilastras, banda terracota, vidrio con parasoles y plantas, escalinata.
	var atrium := Rect2(170, 76, 160, 92)
	draw_rect(Rect2(atrium.position, Vector2(atrium.size.x, 12)), terra)
	draw_rect(Rect2(atrium.position, Vector2(atrium.size.x, 2)), terra_light)
	draw_rect(Rect2(atrium.position.x, atrium.position.y + 10, atrium.size.x, 2), terra_dark)
	var glass := Rect2(atrium.position.x, atrium.position.y + 12, atrium.size.x, 62)
	for k in 8:   # vidrio: del cielo reflejado (arriba) al interior en sombra
		draw_rect(Rect2(glass.position.x, glass.position.y + k * 7.75, glass.size.x, 8), Color("7ea4b2").lerp(Color("3e5a66"), k / 7.0))
	# Plantas dentro del atrio (helechos y palmitas).
	for px in [190.0, 222.0, 258.0, 296.0]:
		var base := Vector2(px, glass.end.y - 6)
		draw_rect(Rect2(base.x - 1, base.y - 14, 2, 14), Color("6a5034"))
		for a in 5:
			var dir := Vector2.from_angle(PI + PI * (a + 0.5) / 5.0)
			draw_line(base + Vector2(0, -14), base + Vector2(0, -14) + dir * 10.0, Color("4f8a46"), 2.0)
			draw_line(base + Vector2(0, -15), base + Vector2(0, -15) + dir * 7.0, Color("7ab86a"), 1.0)
	# Parasoles verticales blancos (con su sombra) y un travesaño.
	var x := glass.position.x + 4.0
	while x < glass.end.x - 2.0:
		draw_rect(Rect2(x, glass.position.y, 2, glass.size.y), Color("eeeae2"))
		draw_rect(Rect2(x + 2, glass.position.y, 1, glass.size.y), Color("9aa8ae"))
		x += 8.0
	draw_rect(Rect2(glass.position.x, glass.position.y + 30, glass.size.x, 2), Color("dcd8d0"))
	# Reflejos diagonales en el vidrio.
	for k in 3:
		var rx := glass.position.x + 20 + k * 52
		draw_colored_polygon(PackedVector2Array([Vector2(rx, glass.position.y), Vector2(rx + 8, glass.position.y),
			Vector2(rx - 12, glass.end.y), Vector2(rx - 20, glass.end.y)]), Color(1, 1, 1, 0.08))
	# Escalinata de madera.
	for k in 4:
		var step := Rect2(atrium.position.x - 2, glass.end.y + k * 4.5, atrium.size.x + 4, 4.5)
		draw_rect(step, Color("c8a070") if k % 2 == 0 else Color("b48c5c"))
		draw_line(step.position, Vector2(step.end.x, step.position.y), Color("e0c08e"), 1.0)
	_stone_pillar(Rect2(162, 72, 9, 96))
	_stone_pillar(Rect2(329, 70, 9, 98))
	# Bloque principal: terracota con textura (tramado), letrero, ventanas, escudo y entrada.
	var b := Rect2(338, 62, 222, 106)
	draw_rect(b, terra)
	for yy in range(int(b.position.y) + 4, int(b.end.y), 4):   # tramado sutil del aplanado
		for xx in range(int(b.position.x) + (yy / 4) % 2 * 2, int(b.end.x), 4):
			draw_rect(Rect2(xx, yy, 1, 1), Color(terra_dark, 0.35))
	draw_rect(Rect2(b.position, Vector2(b.size.x, 3)), terra_light)
	draw_rect(Rect2(b.position.x, b.end.y - 5, b.size.x, 5), terra_dark)   # zócalo en sombra
	draw_string(_font, Vector2(b.position.x + 22, b.position.y + 14), "UNIVERSIDAD AUTÓNOMA DE OCCIDENTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("f6eee0"))
	for ly in [18.0, 21.0]:
		draw_rect(Rect2(b.position.x + 8, b.position.y + ly, 176, 1), Color("f6eee0"))
	# Escudo dorado con centro blanco y las letras «UAdeO».
	var logo := Vector2(b.end.x - 26, b.position.y + 22)
	draw_circle(logo + Vector2(1, 1), 14, terra_dark)
	draw_circle(logo, 14, Color("d4a848"))
	draw_circle(logo, 11, Color("b88a30"))
	draw_circle(logo, 8, Color("f6eee0"))
	draw_circle(logo, 4, Color("d4a848"))
	draw_arc(logo, 14, PI * 1.1, PI * 1.5, 6, Color("f0d080"), 1.0)   # brillo
	draw_string(_font, Vector2(logo.x - 18, b.position.y + 50), "UAdeO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f6eee0"))
	# Fila de ventanas con marco blanco y reflejo.
	for k in 7:
		var win := Rect2(b.position.x + 30 + k * 20 + (8 if k >= 4 else 0), b.position.y + 32, 16, 13)
		draw_rect(win, Color("f2efe8"))
		draw_rect(win.grow(-1), Color("2e4450"))
		draw_rect(Rect2(win.position.x + 1, win.position.y + 1, win.size.x - 2, 4), Color("587884"))
		draw_line(win.position + Vector2(win.size.x / 2.0, 1), win.position + Vector2(win.size.x / 2.0, win.size.y - 1), Color("f2efe8"), 1.0)
		draw_line(win.position + Vector2(3, win.size.y - 3), win.position + Vector2(6, 3), Color(1, 1, 1, 0.35), 1.0)
	# Rampa roja a la izquierda y la entrada blanca (por donde se entra).
	draw_colored_polygon(PackedVector2Array([Vector2(b.position.x + 2, b.end.y - 34), Vector2(b.position.x + 12, b.end.y - 34),
		Vector2(b.position.x + 30, b.end.y), Vector2(b.position.x + 2, b.end.y)]), Color("8a3630"))
	draw_line(Vector2(b.position.x + 12, b.end.y - 34), Vector2(b.position.x + 30, b.end.y), Color("a84a40"), 1.0)
	var door := Rect2(ENTRANCE_X - 28, b.end.y - 32, 56, 32)
	draw_rect(door, Color("efede6"))
	draw_rect(Rect2(door.position.x + 4, door.position.y + 5, door.size.x - 8, door.size.y - 5), Color("c6c4be"))
	draw_rect(Rect2(door.position.x + 8, door.position.y + 9, door.size.x - 16, door.size.y - 9), Color("9eb4bc"))   # puertas de vidrio
	draw_line(Vector2(ENTRANCE_X, door.position.y + 9), Vector2(ENTRANCE_X, door.end.y), Color("e8e6e0"), 1.0)
	draw_rect(Rect2(door.position.x + 8, door.position.y + 9, door.size.x - 16, 3), Color(1, 1, 1, 0.3))
	_stone_pillar(Rect2(556, 58, 9, 110))
	# Base de concreto y la sombra del edificio sobre la banqueta.
	draw_rect(Rect2(64, 166, 504, 3), Color("9a9a9e"))
	draw_rect(Rect2(64, 168, 504, 3), Color(0.25, 0.2, 0.3, 0.25))


## El barandal del malecón va delante del jugador.
func _draw_street_front() -> void:
	var w := width()
	for k in int(w / 12.0) + 1:
		draw_rect(Rect2(k * 12.0, 204, 2, 8), Color("f0ece0"))
	draw_line(Vector2(0, 204), Vector2(w, 204), Color("f0ece0"), 1.0)
	# Hojas de palmera que vuelan con la brisa del mar (T188).
	for k in 5:
		var lx := loop_x(k * 170.0, -16.0 - k * 3.0, time, w)
		var ly := 150.0 + k * 11.0 + sin(time * 1.6 + k * 2.0) * 6.0
		var turn := sin(time * 3.0 + k)
		draw_rect(Rect2(lx, ly, 3.0 if turn > 0.0 else 2.0, 1.0 if turn > 0.0 else 2.0), Color("6f9a4a") if k % 2 else Color("b89a5a"))


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
	# Vista de sur a norte: se camina de frente hacia el fondo del pasillo.
	var back := Rect2(HALL_BACK_LEFT, 40, HALL_BACK_RIGHT - HALL_BACK_LEFT, HALL_FAR_Y - 40)
	# Techo, paredes y suelo.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(back.end.x, 40), Vector2(back.position.x, 40)]), Color("bdb39a"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(back.position.x, 40), Vector2(back.position.x, HALL_FAR_Y), Vector2(-10, 225), Vector2(-10, 0)]), Color("cfc6ae"))
	draw_colored_polygon(PackedVector2Array([Vector2(400, 0), Vector2(back.end.x, 40), Vector2(back.end.x, HALL_FAR_Y), Vector2(410, 225), Vector2(410, 0)]), Color("c3baa1"))
	draw_rect(back, Color("dad2bb"))
	draw_colored_polygon(PackedVector2Array([Vector2(back.position.x, HALL_FAR_Y), Vector2(back.end.x, HALL_FAR_Y), Vector2(410, 225), Vector2(-10, 225)]), Color("b4ac9c"))
	_hall_texture(back)
	# Baldosas en perspectiva: líneas hacia el punto de fuga y filas cada vez más juntas.
	var vp := Vector2(200, 93.75)
	for k in range(-6, 7):
		var bottom := Vector2(200 + k * 34.0, 225)
		var t := (HALL_FAR_Y - vp.y) / (bottom.y - vp.y)
		draw_line(vp.lerp(bottom, t), bottom, Color("a39b8a"), 1.0)
	for i in range(1, 9):
		var y := HALL_FAR_Y + 75.0 * pow(i / 8.0, 1.6)
		var edge := 120.0 * (y - HALL_FAR_Y) / 75.0   # el suelo se ensancha hacia abajo
		draw_line(Vector2(HALL_BACK_LEFT - edge, y), Vector2(HALL_BACK_RIGHT + edge, y), Color("a39b8a"), 1.0)
	# Zócalo oscuro a lo largo de las paredes.
	draw_colored_polygon(PackedVector2Array([Vector2(back.position.x, HALL_FAR_Y - 7), Vector2(back.position.x, HALL_FAR_Y), Vector2(-10, 225), Vector2(-10, 212)]), Color("968b70"))
	draw_colored_polygon(PackedVector2Array([Vector2(back.end.x, HALL_FAR_Y - 7), Vector2(back.end.x, HALL_FAR_Y), Vector2(410, 225), Vector2(410, 212)]), Color("8e8368"))
	draw_rect(Rect2(back.position.x, HALL_FAR_Y - 7, back.size.x, 7), Color("9e9378"))
	# Lámparas del techo, más pequeñas cuanto más lejos.
	for k in 4:
		var d := k / 4.0
		var y := lerpf(6.0, 36.0, d)
		var half := lerpf(30.0, 14.0, d)
		var on := flicker <= 0.0 or k % 2 == 0
		draw_rect(Rect2(200 - half, y, half * 2.0, lerpf(4.0, 2.0, d)), Color("f4f0dc") if on else Color("807a6a"))
		if on:   # charco de luz en el suelo, debajo de cada lámpara
			var floor_y := lerpf(222.0, HALL_FAR_Y + 4.0, d)
			for ring in 3:
				var rw := lerpf(70.0, 30.0, d) * (1.0 - ring * 0.28)
				draw_set_transform(Vector2(200 - roundf(cam_x), floor_y), 0.0, Vector2(1.0, 0.22))
				draw_circle(Vector2.ZERO, rw, Color(1.0, 0.97, 0.85, 0.05))
				draw_set_transform(Vector2(-roundf(cam_x), 0))
	# Pared derecha: un ventilador industrial al límite y carteles.
	var fan := Vector2(352, 70)
	draw_set_transform(fan, 0.0, Vector2(0.55, 1.0))
	draw_circle(Vector2.ZERO, 16, Color("8a8a8a"))
	for k in 3:
		draw_line(Vector2.ZERO, Vector2.from_angle(time * 30.0 + TAU * k / 3.0) * 14.0, Color("5a5a5a"), 4.0)
	draw_circle(Vector2.ZERO, 3, Color("3a3a3a"))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(322, 110), Vector2(372, 104), Vector2(372, 150), Vector2(322, 148)]), Color("8a6a4a"))
	draw_colored_polygon(PackedVector2Array([Vector2(326, 113), Vector2(368, 108), Vector2(368, 146), Vector2(326, 144)]), Color("c8a878"))
	draw_string(_font, Vector2(330, 124), "SE BUSCA", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("3a3a3a"))
	draw_string(_font, Vector2(330, 132), "PRACTICANTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("3a3a3a"))
	draw_string(_font, Vector2(330, 140), "5 años exp.", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("a03030"))
	# Pared izquierda, al fondo: la puerta gris lisa de Informática, entreabierta.
	var door := PackedVector2Array([Vector2(70, 85), Vector2(100, 84), Vector2(100, 156), Vector2(70, 175)])
	draw_colored_polygon(door, Color("141414"))
	draw_colored_polygon(PackedVector2Array([Vector2(70, 85), Vector2(84, 80), Vector2(84, 166), Vector2(70, 175)]), Color("8e9196"))
	draw_circle(Vector2(81, 128), 1.2, Color("d9c070"))
	draw_colored_polygon(PackedVector2Array([Vector2(84, 84.5), Vector2(100, 84), Vector2(112, 172), Vector2(90, 190)]), Color(0.4, 1.0, 0.6, 0.07 + 0.03 * sin(time * 7.0)))
	draw_colored_polygon(PackedVector2Array([Vector2(64, 70), Vector2(106, 67), Vector2(106, 78), Vector2(64, 80)]), Color("3a3a3a"))
	draw_string(_font, Vector2(66, 77), "INFORMÁTICA", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("e0e0e0"))
	# Al fondo: la caja de trámites (cerrada, como siempre).
	var caja := Rect2(back.position.x + 10, 72, 64, 70)
	draw_rect(caja, Color("8a7a5a"))
	draw_rect(Rect2(caja.position + Vector2(6, 16), Vector2(52, 32)), Color("5a5a5a"))
	for k in 6:
		draw_line(caja.position + Vector2(6, 18 + k * 5), caja.position + Vector2(58, 18 + k * 5), Color("7a7a7a"), 1.0)
	draw_rect(Rect2(caja.position + Vector2(0, -10), Vector2(64, 10)), Color("2d5a8a"))
	draw_string(_font, caja.position + Vector2(3, -2), "CAJA · TRÁMITES", HORIZONTAL_ALIGNMENT_LEFT, 60, 7, Color.WHITE)
	draw_rect(Rect2(caja.position + Vector2(10, 52), Vector2(44, 10)), Color("f4f0e0"))
	draw_string(_font, caja.position + Vector2(11, 59), "Regreso en 15 min", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("3a3a3a"))
	# A la derecha de la caja: la TV plana con la promoción.
	_draw_tv(Rect2(back.position.x + 84, 64, 92, 56))
	_draw_hall_life(back)


## Cada cuánto cruza alguien por el fondo del pasillo y cuánto tarda en llegar a la puerta.
const HALL_CYCLE := 15.0
const HALL_WALK := 6.5


## Cuánto está abierta la puerta del fondo (0..1) en el instante `t` del ciclo: se abre
## cuando llega quien cruza, y se cierra sola detrás de él.
static func hall_door_open(t: float) -> float:
	if t < HALL_WALK - 0.8:
		return 0.0
	if t < HALL_WALK:
		return (t - (HALL_WALK - 0.8)) / 0.8
	return clampf(1.0 - (t - HALL_WALK - 0.4) / 0.9, 0.0, 1.0)


## El pasillo con vida (T188): polvo que flota en la luz de las lámparas y alguien que
## cruza al fondo y sale por una puerta que se cierra tras él.
func _draw_hall_life(back: Rect2) -> void:
	for j in 18:   # motas de polvo en los conos de luz
		var lamp := j % 2
		var half := lerpf(30.0, 14.0, lamp / 4.0) * 1.3
		var x := 200.0 + sin(time * 0.25 + j * 2.1) * half
		var y := lerpf(14.0, 40.0, lamp / 4.0) + fposmod(j * 17.0 + time * (2.0 + j % 3), 150.0)
		draw_rect(Rect2(x, y, 1, 1), Color(1, 0.98, 0.85, 0.35 + 0.25 * sin(time * 2.0 + j)))
	var door := Rect2(back.end.x - 28, HALL_FAR_Y - 30, 20, 30)
	var t := fmod(time, HALL_CYCLE)
	var open := hall_door_open(t)
	draw_rect(door, Color("2a241c"))   # el hueco oscuro
	var panel_w := door.size.x * (1.0 - 0.8 * open)   # la hoja gira hacia dentro
	draw_rect(Rect2(door.position, Vector2(panel_w, door.size.y)), Color("8a6a4a"))
	draw_rect(Rect2(door.position, Vector2(panel_w, door.size.y)), Color("5a442e"), false, 1.0)
	if panel_w > 6.0:
		draw_rect(Rect2(door.position.x + panel_w - 4, door.position.y + 15, 2, 2), Color("d9c070"))
	if t < HALL_WALK:   # alguien cruza el fondo, de la caja hacia la puerta
		var k := t / HALL_WALK
		var fx := lerpf(back.position.x - 6.0, door.get_center().x, k)
		CharacterAppearance.draw(self, Vector2(fx, HALL_FAR_Y), 0.42, _hall_look, Vector2.RIGHT, Color(0, 0, 0, 0), fmod(t * 2.6 * PI, TAU))


## Pasillo con el detalle de la calle: aplanado con tramado en las paredes (más
## oscuro hacia el fondo), baldosas alternas en perspectiva, luz en las aristas
## del fondo y sombra al pie de las paredes.
func _hall_texture(back: Rect2) -> void:
	# Paredes laterales: tramado columna a columna entre el techo y el suelo en perspectiva.
	for side in [-1, 1]:
		var x0 := 0.0 if side < 0 else back.end.x
		var x1 := back.position.x if side < 0 else 400.0
		var base := Color("cfc6ae") if side < 0 else Color("c3baa1")
		for xx in range(int(x0), int(x1), 2):
			var t := (xx - x0) / (x1 - x0)   # 0 en el borde izquierdo de la franja
			var near := (1.0 - t) if side < 0 else t   # 1 = junto a la cámara
			var top := lerpf(40.0, 0.0, near)
			var bottom := lerpf(HALL_FAR_Y, 225.0, near)
			var shade := Color(base.darkened(0.12 + 0.18 * (1.0 - near)), 0.5)
			for yy in range(int(top) + ((xx / 2) % 2) * 2, int(bottom) - 8, 4):
				draw_rect(Rect2(xx, yy, 1, 1), shade)
	# Pared del fondo: tramado y una franja de luz arriba.
	for yy in range(int(back.position.y) + 2, int(back.end.y) - 8, 4):
		for xx in range(int(back.position.x) + (yy / 4) % 2 * 2, int(back.end.x), 4):
			draw_rect(Rect2(xx, yy, 1, 1), Color("c4bca4", 0.6))
	draw_rect(Rect2(back.position, Vector2(back.size.x, 2)), Color("ece6d2"))
	# Aristas del fondo: luz en la izquierda (de donde vienen las lámparas), sombra en la derecha.
	draw_line(Vector2(back.position.x, back.position.y), Vector2(back.position.x, back.end.y), Color("eae2ca"), 1.0)
	draw_line(Vector2(back.end.x, back.position.y), Vector2(back.end.x, back.end.y), Color("9a9078"), 1.0)
	# Baldosas: una de cada dos un poco más oscura (en perspectiva, hacia el punto de fuga).
	var vp := Vector2(200, 93.75)
	var rows: Array[float] = [HALL_FAR_Y]
	for i in range(1, 9):
		rows.append(HALL_FAR_Y + 75.0 * pow(i / 8.0, 1.6))
	var x_at := func(k: int, y: float) -> float:   # x de la línea k del suelo a la altura y
		var bottom := Vector2(200 + k * 34.0, 225)
		return vp.x + (bottom.x - vp.x) * (y - vp.y) / (bottom.y - vp.y)
	var floor_poly := PackedVector2Array([Vector2(back.position.x, HALL_FAR_Y), Vector2(back.end.x, HALL_FAR_Y), Vector2(410, 225), Vector2(-10, 225)])
	for i in rows.size() - 1:
		for k in range(-7, 7):
			if (i + k) % 2 == 0:
				continue
			var y0: float = rows[i]
			var y1: float = rows[i + 1]
			var tile := PackedVector2Array([Vector2(x_at.call(k, y0), y0), Vector2(x_at.call(k + 1, y0), y0),
				Vector2(x_at.call(k + 1, y1), y1), Vector2(x_at.call(k, y1), y1)])
			for piece in Geometry2D.intersect_polygons(tile, floor_poly):   # que no se salga a las paredes
				if piece.size() >= 3:
					draw_colored_polygon(piece, Color(0.38, 0.34, 0.28, 0.12))
	# Sombra al pie de las paredes del fondo.
	draw_rect(Rect2(back.position.x, HALL_FAR_Y, back.size.x, 3), Color(0.2, 0.17, 0.12, 0.25))


## Oficina con el detalle de la calle: aplanado con tramado y manchas de humedad,
## luz de los fluorescentes en conos, zócalo, baldosas con junta y brillo, y
## sombras al pie de los muebles.
func _office_texture(w: float) -> void:
	for yy in range(14, int(FLOOR_Y) - 10, 4):
		for xx in range(((yy / 4) % 2) * 2, int(w), 4):
			draw_rect(Rect2(xx, yy, 1, 1), Color("b4ac94", 0.55))
	draw_rect(Rect2(0, 0, w, 12), Color("b8b09a"))   # techo en sombra
	draw_rect(Rect2(0, 12, w, 1), Color("9e9682"))
	# Mancha de humedad bajo el minisplit (escurre por la pared).
	for k in 5:
		draw_rect(Rect2(62 + k * 2, 50, 18 - k * 4, 60 + k * 14), Color(0.45, 0.42, 0.32, 0.06))
	# Zócalo y su sombra.
	draw_rect(Rect2(0, FLOOR_Y - 6, w, 6), Color("8e8672"))
	draw_rect(Rect2(0, FLOOR_Y - 6, w, 1), Color("a8a08a"))
	# Junta y brillo de cada baldosa.
	for k in int(w / 20.0) + 1:
		draw_rect(Rect2(k * 20.0, FLOOR_Y, 1, 30), Color("6e685e"))
		draw_rect(Rect2(k * 20.0 + 1, FLOOR_Y + 1, 18, 1), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(0, FLOOR_Y + 13, w, 1), Color("6e685e"))


## Cono de luz de un fluorescente hasta el suelo.
func _office_light(x: float, on: bool) -> void:
	if not on:
		return
	for k in 3:
		var spread := 18.0 + k * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(x + 4, 10), Vector2(x + 46, 10), Vector2(x + 25 + spread, FLOOR_Y + 10),
			Vector2(x + 25 - spread, FLOOR_Y + 10)]), Color(1.0, 1.0, 0.9, 0.025))


## Sombra en el suelo al pie de algo (elipse aplastada).
func _floor_shadow(center_x: float, half_width: float) -> void:
	draw_set_transform(Vector2(center_x - roundf(cam_x), FLOOR_Y + 2.0), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, half_width, Color(0.1, 0.08, 0.06, 0.3))
	draw_set_transform(Vector2(-roundf(cam_x), 0))


## TV plana: alterna «Ingeniería de Software» y el Hackatón LinceCode 2026.
func _draw_tv(tv: Rect2) -> void:
	draw_rect(Rect2(tv.position + Vector2(tv.size.x / 2.0 - 6, tv.size.y), Vector2(12, 4)), Color("2a2a2a"))   # soporte
	draw_rect(tv, Color("0c0c0e"))
	var screen := tv.grow(-3)
	var slide := int(time / 4.5) % 2
	var t := fmod(time, 4.5)
	if slide == 0:
		for k in 8:
			draw_rect(Rect2(screen.position.x, screen.position.y + k * screen.size.y / 8.0, screen.size.x, screen.size.y / 8.0 + 1),
				Color("12305a").lerp(Color("1d5aa0"), k / 7.0))
		# Laptop en pixel art.
		var lp := screen.position + Vector2(6, 12)
		draw_rect(Rect2(lp, Vector2(22, 14)), Color("d8d8d8"))
		draw_rect(Rect2(lp + Vector2(2, 2), Vector2(18, 10)), Color("0c1a2a"))
		for j in 3:
			draw_rect(Rect2(lp + Vector2(4, 4 + j * 3), Vector2(6 + (j * 5) % 10, 1)), Color("3cff6a"))
		draw_rect(Rect2(lp + Vector2(-3, 14), Vector2(28, 3)), Color("b8b8b8"))
		draw_string(_font, screen.position + Vector2(33, 14), "INGENIERÍA", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
		draw_string(_font, screen.position + Vector2(33, 23), "DE SOFTWARE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("ffd84a"))
		draw_string(_font, screen.position + Vector2(34, 33), "¡Inscríbete!", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("cfe4ff"))
		draw_string(_font, screen.position + Vector2(4, 46), "UAdeO · Unidad Mazatlán", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("cfe4ff"))
	else:
		draw_rect(screen, Color("f4f0e8"))
		var px := 2.0
		var origin := screen.position + Vector2(3, 6)
		for y in LYNX.size():
			var row: String = LYNX[y]
			for x in row.length():
				if row[x] == "M":
					draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), Color("7a1420"))
				elif row[x] == "G":
					draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), Color("e0a820"))
		draw_string(_font, screen.position + Vector2(42, 12), "HACKATÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("7a1420"))
		draw_string(_font, screen.position + Vector2(41, 23), "LINCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("7a1420"))
		draw_string(_font, screen.position + Vector2(41, 32), "CODE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("d09018"))
		draw_line(screen.position + Vector2(41, 36), screen.position + Vector2(84, 36), Color("d09018"), 1.0)
		draw_string(_font, screen.position + Vector2(52, 45), "2026", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("d09018"))
	# Barrido de cambio de diapositiva y reflejo de la pantalla.
	if t < 0.25:
		draw_rect(Rect2(screen.position, Vector2(screen.size.x, screen.size.y * (1.0 - t / 0.25))), Color(0, 0, 0, 0.85))
	draw_line(screen.position + Vector2(screen.size.x - 18, 2), screen.position + Vector2(screen.size.x - 6, 2), Color(1, 1, 1, 0.15), 1.0)


# --- Oficina destrozada ---

func _draw_office() -> void:
	var w := width()
	var shake := Vector2(sin(time * 60.0), cos(time * 47.0)) * rack_shake * 1.5
	draw_rect(Rect2(0, 0, w, FLOOR_Y), Color("c9c2ac"))
	for k in int(w / 20.0) + 1:
		draw_rect(Rect2(k * 20.0, FLOOR_Y, 20, 30), Color("9c968a") if k % 2 == 0 else Color("8e887c"))
	_office_texture(w)
	# Lámparas fluorescentes que parpadean (con su cono de luz).
	for x in [60.0, 200.0, 330.0]:
		var on := flicker <= 0.0 or fmod(time * 17.0 + x, 1.0) < 0.4
		_office_light(x, on)
		draw_rect(Rect2(x, 6, 50, 4), Color("f4f8e8") if on else Color("6a6a60"))
		draw_rect(Rect2(x, 10, 50, 1), Color("8a8a80"))   # carcasa
	# Sombras al pie de lo que hay en el suelo.
	for s: Vector2 in [Vector2(71, 18), Vector2(124, 16), Vector2(160, 22), Vector2(20, 18), Vector2(371 + rack_shake, 26)]:
		_floor_shadow(s.x, s.y)
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
		draw_rect(Rect2(m.position, Vector2(m.size.x, 1)), Color("eee4c0"))   # luz arriba
		draw_rect(Rect2(m.end.x - 1, m.position.y, 1, m.size.y), Color("a89c74"))   # sombra a la derecha
		draw_rect(m.grow(-4), Color("3a4a3a"))
		# T188: código que se desplaza en las pantallas viejas (verde tenue, sube línea a línea).
		var screen := m.grow(-4)
		for j in 4:
			var ly := screen.position.y + 2.0 + fposmod(j * 3.5 - time * (3.0 + k), screen.size.y - 3.0)
			var lw := 3.0 + fposmod(j * 7.0 + k * 5.0 + floorf(time * 0.8), screen.size.x - 6.0)
			draw_rect(Rect2(screen.position.x + 2.0 + (j % 2) * 2.0, ly, lw, 1), Color(0.4, 1.0, 0.5, 0.45))
		draw_rect(Rect2(m.position + Vector2(5, 5), Vector2(6, 2)), Color(1, 1, 1, 0.18))   # reflejo del cristal
	# El rack negro del rincón (y su temblor).
	var rack := Rect2(Vector2(350, 70) + shake, Vector2(42, 128))
	draw_rect(rack, Color("151518"))
	draw_rect(Rect2(rack.position, Vector2(1, rack.size.y)), Color("3a3a42"))   # arista con luz
	draw_rect(Rect2(rack.position, Vector2(rack.size.x, 1)), Color("2e2e36"))
	for k in 9:
		var y := rack.position.y + 8 + k * 13
		draw_rect(Rect2(rack.position.x + 4, y, 34, 9), Color("23232a"))
		var on := sin(time * (6.0 + k * 2.0) + k) > 0.0 or rack_shake > 0.3
		draw_circle(Vector2(rack.end.x - 8, y + 4.5), 1.2, Color("ff4a3a") if rack_shake > 0.3 else (Color("3cff6a") if on else Color("1a4a2a")))
	draw_string(_font, rack.position + Vector2(2, -3), "EL MONOLITO (2004)", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("4a4a4a"))
	if absorb > 0.0 or player_pull > 0.0:
		_draw_vortex()
	# Rafa, de pie o sentado tras la barricada.
	# Sentado solo asoma la cabeza sobre el escritorio; al levantarse de golpe, medio cuerpo.
	# T187: se levanta con un impulso; sentado teclea (respira rápido, como quien escribe)
	# y gira la cabeza hacia el jugador cuando este se acerca.
	var rise := rafa_rise(rafa_stand_k)
	var rafa_feet := Vector2(314, FLOOR_Y - 12.0 * rise)
	var rp := pull_of("rafa")
	if rp < 1.0:
		var at := pulled_pos(rafa_feet, rp)
		_draw_pull_trail(rafa_feet, at, rp, Color("e06c6c"))
		var standing := rafa_stand_k >= 0.5
		var rafa_pose := {"state": "idle", "time": time * (1.0 if standing else 4.0)}
		CharacterAppearance.draw(self, at, 1.0 - 0.85 * rp * rp, rafa_look, rafa_facing(standing, player_x, room == "oficina"),
			Color(0, 0, 0, 0), -1.0, rafa_pose)
		_draw_scream(at, rp, "¡MI MONOLITOOO!")


## 0 → 1: cuánto ha volado ya `who` hacia el servidor (1 = absorbido, no se dibuja).
func pull_of(who: String) -> float:
	return clampf((absorb - float(PULL_DELAY.get(who, 0.0))) / PULL_SPAN, 0.0, 1.0)


## Posición de algo que vuela al vórtice: arranca despacio, acelera y gira en espiral.
func pulled_pos(from: Vector2, k: float) -> Vector2:
	if k <= 0.0:
		return from + Vector2(sin(time * 40.0) * 0.6 * absorb, 0)   # tiembla mientras espera su turno
	var e := k * k
	var spiral := Vector2.from_angle(time * 9.0 + from.x) * 14.0 * (1.0 - e) * e
	return from.lerp(VORTEX + Vector2(0, 16), e) + spiral


## Estela de píxeles entre la posición original y el personaje que vuela.
func _draw_pull_trail(from: Vector2, at: Vector2, k: float, color: Color) -> void:
	if k <= 0.02:
		return
	for j in 8:
		var t := float(j) / 8.0
		var p := from.lerp(at, t) + Vector2(sin(time * 20.0 + j) * 3.0, -12.0 * (1.0 - k))
		draw_rect(Rect2(p, Vector2(2, 2)), Color(color, 0.5 * t))


## Grito en letras de cómic sobre quien está siendo absorbido.
func _draw_scream(at: Vector2, k: float, text: String) -> void:
	if k <= 0.03 or k >= 0.85:
		return
	var a := clampf(k / 0.1, 0.0, 1.0) * clampf((0.85 - k) / 0.15, 0.0, 1.0)
	var shake := Vector2(sin(time * 50.0) * 1.0, cos(time * 43.0) * 1.0)
	var pos := at + Vector2(-40, -50) + shake
	draw_string_outline(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 80, 9, 3, Color(0.1, 0.0, 0.0, a))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(1.0, 0.85, 0.2, a))


## El rack se abre en un vórtice: núcleo negro que crece, anillos rojos y verdes
## que giran y píxeles que entran en espiral.
func _draw_vortex() -> void:
	var power := maxf(absorb, player_pull)
	var r := 8.0 + 18.0 * power
	for k in 4:
		var rr := r + 6.0 + k * 6.0
		var a0 := time * (5.0 + k * 1.7) * (1.0 if k % 2 == 0 else -1.0)
		var col := Color("ff3a2a") if k % 2 == 0 else Color("3cff6a")
		for s in 3:
			draw_arc(VORTEX, rr, a0 + TAU * s / 3.0, a0 + TAU * s / 3.0 + 1.3, 10, Color(col, 0.55 - k * 0.1), 2.0)
	draw_circle(VORTEX, r + 3.0, Color(0.9, 0.2, 0.2, 0.35))
	draw_circle(VORTEX, r, Color("050307"))
	for k in 24:   # píxeles que entran en espiral
		var t := fmod(time * 0.9 + k / 24.0, 1.0)
		var ang := k * 2.4 + t * 6.0
		var p := VORTEX + Vector2.from_angle(ang) * (r + 70.0 * (1.0 - t))
		draw_rect(Rect2(p, Vector2(2, 2)), Color("3cff6a") if k % 3 else Color("ffd84a"))


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
	for s in 3:   # el café todavía humea (T188)
		var rise := fposmod(time * 0.6 + s / 3.0, 1.0)
		var sx := 329.5 + sin(time * 2.0 + s * 2.0 + rise * 5.0) * 1.5
		draw_rect(Rect2(sx, 166.0 - rise * 12.0, 1, 2), Color(1, 1, 1, 0.45 * (1.0 - rise)))
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

# --- Mario y Aida llegan con el carrito ---

## Mario jala un carrito plegable negro con una bolsa de basura llena de
## frituras; Aida camina a su lado.
func _draw_visitors() -> void:
	if visitors_x < -100.0:
		return
	var mx := visitors_x
	var feet_y := FLOOR_Y + 4.0
	# El carrito es lo primero que se traga el servidor (luego Mario y Aida).
	var cp := pull_of("cart")
	if cp >= 1.0:
		_draw_visitor_people(mx, feet_y)
		return
	var cart_home := Vector2(mx - 31, feet_y - 12)
	var cart_at := pulled_pos(cart_home, cp)
	_draw_pull_trail(cart_home, cart_at, cp, Color("e8a020"))
	# Gira y encoge alrededor de su propio centro mientras vuela.
	var spin := Transform2D(cp * 6.0, Vector2.ONE * (1.0 - 0.8 * cp), 0.0, cart_at) * Transform2D(0.0, -cart_home)
	draw_set_transform_matrix(Transform2D(0.0, Vector2(-roundf(cam_x), 0)) * spin)
	# Carrito: lona negra con el armazón en X, cuatro ruedas y el asa hacia Mario.
	var cart := Rect2(mx - 46, feet_y - 19, 30, 13)
	for wx in [cart.position.x + 3, cart.end.x - 3]:
		draw_circle(Vector2(wx, feet_y - 3), 3.2, Color("101010"))
		draw_circle(Vector2(wx, feet_y - 3), 1.2, Color("3a3a3a"))
	draw_rect(cart, Color("1a1a1c"))
	draw_line(cart.position, cart.end, Color("3a3a40"), 1.0)
	draw_line(Vector2(cart.position.x, cart.end.y), Vector2(cart.end.x, cart.position.y), Color("3a3a40"), 1.0)
	draw_rect(cart, Color("2c2c30"), false, 1.0)
	draw_line(Vector2(cart.end.x, cart.position.y + 3), Vector2(mx - 6, feet_y - 13), Color("202024"), 1.5)   # asa
	# Bolsa negra repleta de frituras (con bolsitas de colores asomando).
	draw_circle(cart.get_center() + Vector2(0, -9), 9.0, Color("0c0c0e"))
	draw_circle(cart.get_center() + Vector2(-6, -6), 6.0, Color("0c0c0e"))
	draw_circle(cart.get_center() + Vector2(6, -6), 6.0, Color("121214"))
	for chip in [[Vector2(-5, -17), Color("e8a020")], [Vector2(1, -19), Color("d83a2a")], [Vector2(6, -16), Color("f0d040")], [Vector2(-1, -14), Color("3a8ad0")]]:
		draw_rect(Rect2(cart.get_center() + chip[0], Vector2(4, 5)), chip[1])
	draw_line(cart.get_center() + Vector2(-2, -18), cart.get_center() + Vector2(2, -20), Color("0c0c0e"), 1.0)   # nudo
	draw_set_transform(Vector2(-roundf(cam_x), 0))
	_draw_visitor_people(mx, feet_y)


## Mario y Aida (y, si el servidor ya tira de ellos, volando hacia él).
func _draw_visitor_people(mx: float, feet_y: float) -> void:
	for who in ["mario", "aida"]:
		var home := Vector2(mx, feet_y) if who == "mario" else Vector2(mx + 20, feet_y + 2)
		var k := pull_of(who)
		if k >= 1.0:
			continue
		var at := pulled_pos(home, k)
		_draw_pull_trail(home, at, k, Color("ffd84a") if who == "mario" else Color("d9b0ff"))
		var look: Dictionary = mario_look if who == "mario" else aida_look
		var phase := visitors_walk if who == "mario" else (visitors_walk + 1.4 if visitors_walk >= 0.0 else -1.0)
		CharacterAppearance.draw(self, at, 1.0 - 0.85 * k * k, look, Vector2.RIGHT, Color(0, 0, 0, 0), phase if k <= 0.0 else -1.0)
		_draw_scream(at, k, "¡MIS CHURROS!" if who == "mario" else "¡AAAAH!")
	if dissolve > 0.0:
		for k in 8:
			var y := feet_y - 8.0 - fmod(time * 26.0 + k * 9.0, 34.0)
			draw_string(_font, Vector2(mx - 40 + k * 9, y), "1" if k % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.3, 1.0, 0.5, 0.8 * dissolve))
