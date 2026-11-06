class_name UnitArt
## Dibujo de las invocaciones persistentes, cada una con su figura (hasta que
## haya arte final). `p` son los pies (o el centro si orbita); `ph` el reloj de
## animación (siempre corre: LEDs, ventiladores, visores); `c` el color de la
## habilidad. Lo usan SkillController y la herramienta de capturas.
##
## Motor de animación (T200): `anim` (ver `anim()`) trae hacia dónde mira, hacia
## dónde apunta, el estado (quieto, caminar, atacar, aparecer, herido, morir) con
## su progreso, la fase de caminar (solo avanza al moverse) y la escala de la
## unidad. Sin `anim` se dibuja como siempre: mirando a la derecha y quieta.

const STATES := ["idle", "walk", "attack", "spawn", "warp", "leap", "hurt", "die"]
## Duración de cada estado con tiempo propio.
const SPAWN_TIME := 0.4
const ATTACK_TIME := 0.25
const DIE_TIME := 0.35
## Al relanzar (o al quedarse atrás) se desvanece en bits y reaparece compilándose.
const WARP_TIME := 0.2
## Piezas y bits al desarmarse (T201): cuánto duran, cómo caen y cuántas a la vez como mucho.
const DEBRIS_TIME := 0.9
const DEBRIS_GRAVITY := 1100.0
const DEBRIS_MAX := 160
const BIT_COLOR := Color("3cff6a")
## Colores de las piezas de cada figura (el de la habilidad se añade al desarmarla).
const DEBRIS_COLORS := {
	"robot_centinela": [Color("6e7480"), Color("4a4f5c")],
	"daemon_segundo_plano": [Color("b8322a"), Color("f0e0c0")],
	"golem_hardware": [Color("5a5650"), Color("b8b8b0")],
	"mainframe_titan": [Color("2c3038"), Color("4a4f5c")],
	"bot_pruebas": [Color("e8c040"), Color("2a2a2a")],
	"mina_rodante": [Color("26262c"), Color("8a8a96")],
	"proceso_hijo": [Color("2f4a3a"), Color("b8b8b0")],
	"dron": [Color("3a3f4a"), Color("8a8a96")],
	"torreta": [Color("23262e"), Color("4a4f5c")],
	"contenedor": [Color("1d63a8"), Color("8ac4f0")],
}
## Tras atacar o fijar un objetivo, cuánto sigue mirándolo aunque se mueva.
const LOOK_TIME := 0.35
## Fase de caminar por píxel recorrido (a 220 px/s, ~1,2 zancadas por segundo).
const WALK_PER_PX := 0.035
## Por debajo de esta velocidad (px/s) cuenta como quieta.
const STILL_SPEED := 20.0
## Escala por nodo clave o variante: Monolito más grande; Microservicios y el
## Clúster de tres, más pequeños.
const SCALE_MONOLITH := 1.35
const SCALE_MICROSERVICES := 0.8
const SCALE_TRIO := 0.75
## Ataques que se ven (T202): embestida de las de cuerpo a cuerpo (como el
## _lunge_to de los enemigos; los tanques, más corta), retroceso de las de
## distancia y salto en arco (dura LEAP_TIME y sube según la distancia).
const LUNGE_REACH := 11.0
const TANK_LUNGE := 7.0
const RECOIL := 3.5
const LEAP_TIME := 0.38
const LEAP_ARC_MIN := 28.0
const LEAP_ARC_MAX := 80.0
## Figuras con cañón propio, que dibujan el fogonazo al disparar.
const MUZZLE_FIGURES := ["robot_centinela", "bot_rastreador", "golem_gpu"]

# Estado del dibujo en curso (lo fija draw() antes de llamar a cada figura).
static var _flip := 1.0          # 1 = mira a la derecha, -1 = a la izquierda
static var _move := 0.0          # 0 quieta … 1 caminando (mezcla las dos animaciones)
static var _walk := 0.0          # fase de caminar
static var _aim := Vector2.RIGHT # hacia el objetivo, en el espacio de la figura (ya volteado)
static var _focus := false       # tiene un objetivo fijado (mira en vez de vigilar)
static var _base := Transform2D.IDENTITY
static var _atk := 0.0           # progreso del ataque (0 = no ataca): tridente, mordida, fogonazo…


static func draw(ci: CanvasItem, skill_id: String, behavior: String, p: Vector2, ph: float, c: Color, anim := {}) -> void:
	_flip = 1.0
	_move = 0.0
	_walk = 0.0
	_aim = Vector2.RIGHT
	_focus = false
	_atk = 0.0
	_base = Transform2D.IDENTITY
	var at := p
	if not anim.is_empty():
		_flip = -1.0 if float(anim.get("facing", 1.0)) < 0.0 else 1.0
		_move = clampf(float(anim.get("move", 0.0)), 0.0, 1.0)
		_walk = float(anim.get("walk", 0.0))
		var aim: Vector2 = anim.get("aim", Vector2.RIGHT)
		var aim_world := aim.normalized() if aim.length() > 0.01 else Vector2(_flip, 0.0)
		_aim = Vector2(aim_world.x * _flip, aim_world.y)
		_focus = bool(anim.get("focus", false))
		var state := String(anim.get("state", "idle"))
		var t := float(anim.get("t", 0.0))
		var sc := float(anim.get("scale", 1.0))
		# Herida: además del retroceso, se inclina hacia atrás. Saltando: sube el
		# morro al despegar y lo baja al caer.
		var tilt := 0.0
		if state == "hurt":
			tilt = -0.14 * sin(t * PI) * _flip
		elif state == "leap":
			tilt = 0.5 * (t - 0.5) * _flip
		var shift := Vector2(_state_shift(state, t) * _flip, -float(anim.get("hop", 0.0)))
		if state == "attack":
			_atk = maxf(0.001, t)
			shift += attack_offset(behavior, t, aim_world) * sc
		_base = Transform2D(tilt, _state_scale(state, t, ph) * sc * Vector2(_flip, 1.0), 0.0, p + shift)
		ci.draw_set_transform_matrix(_base)
		at = Vector2.ZERO
	_figure(ci, skill_id, behavior, at, ph, c)
	if not anim.is_empty():
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
		_base = Transform2D.IDENTITY
		_flip = 1.0
		# Aparecer y reaparecer: bits que llegan (o se van) y la línea de compilación.
		var st := String(anim.get("state", ""))
		if st == "spawn" or st == "warp":
			var tt := float(anim.get("t", 0.0))
			_compile(ci, p + Vector2(0.0, float(anim.get("lift", 0.0))), tt if st == "spawn" else 1.0 - tt,
				float(anim.get("height", 30.0)), c)


static func _figure(ci: CanvasItem, skill_id: String, behavior: String, p: Vector2, ph: float, c: Color) -> void:
	match skill_id:
		"robot_centinela":
			_sentinel(ci, p, ph, c)
		"daemon_segundo_plano":
			_daemon(ci, p, ph)
		"golem_hardware":
			_golem(ci, p, ph, c)
		"mainframe_titan":
			_titan(ci, p, ph, c)
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
		"golem_silicio":
			_golem_silicon(ci, p, ph, c)
		"golem_overclock":
			_golem_overclock(ci, p, ph, c)
		"golem_utp":
			_golem_utp(ci, p, ph, c)
		"golem_gpu":
			_golem_gpu(ci, p, ph, c)
		"golem_kernel":
			_golem_kernel(ci, p, ph, c)
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


# --- Motor de animación ---

## Datos de animación de una invocación para draw().
static func anim(u: Dictionary) -> Dictionary:
	var state := state_of(u)
	var t := 0.0
	match state:
		"spawn":
			t = 1.0 - float(u.get("spawn", 0.0)) / SPAWN_TIME
		"attack":
			t = 1.0 - float(u.get("atk", 0.0)) / ATTACK_TIME
		"hurt":
			t = 1.0 - clampf(float(u.get("hurt", 0.0)) / 0.15, 0.0, 1.0)
		"die":
			t = float(u.get("dying", 0.0)) / DIE_TIME
		"warp":
			t = 1.0 - float(u.get("warp", 0.0)) / WARP_TIME
		"leap":
			t = float(u.get("leap_t", 0.0)) / LEAP_TIME
	var sc := float(u.get("scale", 1.0))
	var r := float(u.get("radius", 12.0))
	var orbit := String(u.get("behavior", "")) == "orbit"
	return {"facing": float(u.get("facing", 1.0)), "aim": u.get("aim", Vector2.RIGHT), "state": state, "t": clampf(t, 0.0, 1.0),
		"walk": float(u.get("walk", 0.0)), "move": float(u.get("move", 0.0)), "scale": sc,
		"focus": float(u.get("look", 0.0)) > 0.0, "hop": leap_height(u),
		# Alto de la figura (y, si orbita, cuánto bajan sus pies desde el centro) para la compilación.
		"height": figure_height(u), "lift": r * sc if orbit else 0.0}


## Alto aproximado de la figura en el mundo (para compilarla y desarmarla).
static func figure_height(u: Dictionary) -> float:
	var r := float(u.get("radius", 12.0)) * float(u.get("scale", 1.0))
	return r * 2.0 if String(u.get("behavior", "")) == "orbit" else r * 2.4


## Estado de animación, de más a menos prioritario.
static func state_of(u: Dictionary) -> String:
	if u.has("dying"):
		return "die"
	if float(u.get("warp", 0.0)) > 0.0:
		return "warp"
	if float(u.get("spawn", 0.0)) > 0.0:
		return "spawn"
	if u.has("leap_to"):
		return "leap"
	if float(u.get("atk", 0.0)) > 0.0:
		return "attack"
	if float(u.get("hurt", 0.0)) > 0.0:
		return "hurt"
	if float(u.get("move", 0.0)) > 0.5:
		return "walk"
	return "idle"


## Avanza la animación un fotograma: la fase de caminar solo con lo que se ha
## movido (`moved`, en píxeles), los temporizadores de estado y, si camina sin
## un objetivo fijado, se voltea hacia donde va.
static func tick(u: Dictionary, delta: float, moved: Vector2) -> void:
	var dist := moved.length()
	var moving := dist > STILL_SPEED * delta
	u["walk"] = float(u.get("walk", 0.0)) + dist * WALK_PER_PX
	u["move"] = move_toward(float(u.get("move", 0.0)), 1.0 if moving else 0.0, delta * 6.0)
	u["spawn"] = maxf(0.0, float(u.get("spawn", 0.0)) - delta)
	u["atk"] = maxf(0.0, float(u.get("atk", 0.0)) - delta)
	u["look"] = maxf(0.0, float(u.get("look", 0.0)) - delta)
	if moving and float(u["look"]) <= 0.0:
		u["aim"] = moved / dist
		if absf(moved.x) > dist * 0.2:
			u["facing"] = signf(moved.x)


## Mira hacia `dir` (un objetivo): voltea la figura y apunta cañón o cabeza.
static func look(u: Dictionary, dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	u["aim"] = dir.normalized()
	u["look"] = LOOK_TIME
	if absf(dir.x) > 0.01:
		u["facing"] = signf(dir.x)


## Ataca hacia `dir`: mira y entra en el estado de ataque.
static func strike(u: Dictionary, dir: Vector2) -> void:
	look(u, dir)
	u["atk"] = ATTACK_TIME


## Desplazamiento del cuerpo al atacar hacia `aim` (en el mundo), con t de 0 a 1:
## las de cuerpo a cuerpo y los tanques embisten (salen rápido y vuelven
## despacio); las de distancia (y las que orbitan) retroceden con el disparo.
static func attack_offset(behavior: String, t: float, aim: Vector2) -> Vector2:
	if behavior == "ranged" or behavior == "orbit":
		var kick := t / 0.15 if t < 0.15 else 1.0 - smoothstep(0.15, 1.0, t)
		return -aim * RECOIL * kick
	var reach := TANK_LUNGE if behavior == "tank" else LUNGE_REACH
	var k := 1.0 - pow(1.0 - t / 0.3, 2.0) if t < 0.3 else 1.0 - smoothstep(0.3, 1.0, t)
	return aim * reach * k


## Altura del cuerpo sobre el suelo durante un salto (0 si no salta).
static func leap_height(u: Dictionary) -> float:
	if not u.has("leap_to"):
		return 0.0
	return sin(clampf(float(u.get("leap_t", 0.0)) / LEAP_TIME, 0.0, 1.0) * PI) * float(u.get("leap_arc", LEAP_ARC_MIN))


## Arco de un salto según lo largo que es.
static func leap_arc(dist: float) -> float:
	return clampf(dist * 0.3, LEAP_ARC_MIN, LEAP_ARC_MAX)


## Escala de dibujo por nodo clave y variante (no cambia el tamaño de colisión).
static func scale_for(variant: String, monolith: bool, microservices: bool) -> float:
	var s := 1.0
	if monolith:
		s *= SCALE_MONOLITH
	elif microservices:
		s *= SCALE_MICROSERVICES
	if variant == "trio":
		s *= SCALE_TRIO
	return s


# --- Aparecer y morir (T201) ---

## Compilación: bits que vuelan desde alrededor hasta su sitio en el cuerpo, uno
## tras otro, y una línea que sube de los pies a la cabeza (t de 0 a 1). Al
## revés (t de 1 a 0), los bits se van: así se desvanece al reaparecer.
static func _compile(ci: CanvasItem, feet: Vector2, t: float, height: float, c: Color) -> void:
	if t >= 1.0:
		return
	var w := maxf(8.0, height * 0.45)
	var line := feet + Vector2(0.0, -height * t)
	ci.draw_line(line - Vector2(w, 0.0), line + Vector2(w, 0.0), Color(BIT_COLOR, 0.8 * (1.0 - t)), 2.0)
	for k in 10:
		var s := clampf(t * 1.6 - k * 0.06, 0.0, 1.0)   # cada bit sale un poco después
		if s >= 1.0:
			continue
		var a := k * 2.39996   # ángulo áureo: repartidos sin azar (no tiemblan entre fotogramas)
		var from := feet + Vector2(cos(a) * (w + 26.0), -height * 0.5 + sin(a) * (height * 0.5 + 18.0))
		var to := feet + Vector2(cos(a * 1.7) * w * 0.5, -height * (0.1 + 0.8 * fmod(k * 0.37, 1.0)))
		var q := from.lerp(to, s * s * (3.0 - 2.0 * s))
		ci.draw_rect(Rect2(q - Vector2(1.5, 1.5), Vector2(3, 3)), Color(BIT_COLOR if k % 2 == 0 else c, 1.0 - 0.6 * s))


## Colores de las piezas de una figura: los suyos y el de la habilidad.
static func debris_colors(key: String, c: Color) -> Array:
	var cols: Array = DEBRIS_COLORS.get(key, [Color("3a3f4a"), Color("8a8f9c")]).duplicate()
	cols.append(c)
	return cols


## Desarma una figura: añade a `out` piezas (cuadraditos que giran) y bits que
## saltan de su cuerpo (de `lift` a `lift + height` sobre los pies) y caen al
## suelo, rebotan y se apagan. Si ya hay DEBRIS_MAX, no añade más.
static func shatter(out: Array, feet: Vector2, height: float, cols: Array, pieces: int, bits: int, lift := 0.0) -> void:
	var n := mini(pieces + bits, DEBRIS_MAX - out.size())
	var big := clampf(height / 30.0, 0.7, 2.2)
	for k in n:
		var bit := k >= pieces
		out.append({"pos": feet + Vector2(randf_range(-0.3, 0.3) * height, randf_range(-5.0, 5.0)),
			"h": lift + randf_range(0.2, 0.95) * height, "vh": randf_range(60.0, 180.0),
			"vel": Vector2(randf_range(-110.0, 110.0), randf_range(-25.0, 25.0)) * (0.7 + 0.3 * big),
			"rot": randf() * TAU, "spin": randf_range(-14.0, 14.0), "t": 0.0, "bit": bit,
			"size": 2.5 if bit else randf_range(3.0, 6.0) * big,
			"col": (BIT_COLOR if k % 2 == 0 else cols[cols.size() - 1]) if bit else cols[k % cols.size()]})


## Avanza las piezas: caen, rebotan una vez, se paran y se quitan al apagarse.
static func update_debris(arr: Array, delta: float) -> void:
	for i in range(arr.size() - 1, -1, -1):
		var d: Dictionary = arr[i]
		d["t"] += delta
		if d["t"] >= DEBRIS_TIME:
			arr.remove_at(i)
			continue
		if d["h"] > 0.0 or d["vh"] > 0.0:
			d["vh"] -= DEBRIS_GRAVITY * delta
			d["h"] += d["vh"] * delta
			d["pos"] += d["vel"] * delta
			d["rot"] += d["spin"] * delta
			if d["h"] <= 0.0:
				d["h"] = 0.0
				if d["vh"] < -120.0:
					d["vh"] = -d["vh"] * 0.3   # rebote
					d["vel"] *= 0.5
					d["spin"] *= 0.5
				else:
					d["vh"] = 0.0


static func draw_debris(ci: CanvasItem, arr: Array) -> void:
	for d in arr:
		var a := 1.0 - smoothstep(0.6, 1.0, float(d["t"]) / DEBRIS_TIME)
		var col: Color = d["col"]
		var q: Vector2 = d["pos"] + Vector2(0.0, -float(d["h"]))
		var s: float = d["size"]
		if d["bit"]:
			ci.draw_rect(Rect2(q - Vector2(1.0, 1.5), Vector2(2.0, 3.0)), Color(col, a))
			continue
		var ax := Vector2.from_angle(d["rot"]) * s * 0.5
		var ay := ax.orthogonal()
		ci.draw_colored_polygon(PackedVector2Array([q - ax - ay, q + ax - ay, q + ax + ay, q - ax + ay]), Color(col, a))


## Deformación del cuerpo según el estado (pivote en los pies): respira quieta,
## crece con rebote al aparecer, se aplasta al atacar y se hunde al morir.
static func _state_scale(state: String, t: float, ph: float) -> Vector2:
	match state:
		"spawn":
			var k := t / 0.7 * 1.12 if t < 0.7 else lerpf(1.12, 1.0, (t - 0.7) / 0.3)
			return Vector2(lerpf(0.6, 1.0, minf(1.0, t * 1.4)), k)
		"attack":
			var hit := sin(t * PI)
			return Vector2(1.0 + 0.08 * hit, 1.0 - 0.06 * hit)
		"die":
			return Vector2(1.0 + 0.3 * t, maxf(0.05, 1.0 - 0.9 * t))
		"warp":
			# Se desvanece estrechándose en una línea de bits antes de reaparecer.
			return Vector2(maxf(0.05, 1.0 - 0.95 * t), 1.0 + 0.2 * t)
		"hurt":
			var k := sin(t * PI)
			return Vector2(1.0 - 0.06 * k, 1.0 + 0.04 * k)
		"leap":
			# Estirada al despegar y al caer, encogida en lo alto.
			var k := 1.0 - sin(t * PI)
			return Vector2(1.0 - 0.1 * k + 0.05 * (1.0 - k), 1.0 + 0.14 * k - 0.08 * (1.0 - k))
		"idle":
			var breath := sin(ph * 0.35)
			return Vector2(1.0 - 0.015 * breath, 1.0 + 0.025 * breath)
	return Vector2.ONE


## Desplazamiento horizontal hacia delante (positivo) según el estado (el del
## ataque va aparte, hacia el objetivo: attack_offset).
static func _state_shift(state: String, t: float) -> float:
	if state == "hurt":
		return -sin(t * PI) * 6.0
	return 0.0


## Fuerza del golpe en curso: 0 sin atacar, 1 en lo más fuerte (a 1/3 del ataque).
static func _strike_k() -> float:
	if _atk <= 0.0:
		return 0.0
	return _atk / 0.33 if _atk < 0.33 else 1.0 - smoothstep(0.33, 1.0, _atk)


## Fogonazo en la boca de un cañón (`dir`, en el espacio de la figura) justo al disparar.
static func _muzzle(ci: CanvasItem, tip: Vector2, dir: Vector2, c: Color) -> void:
	if _atk <= 0.0 or _atk > 0.45:
		return
	var k := 1.0 - _atk / 0.45
	ci.draw_circle(tip + dir * 1.5, 1.5 + 3.0 * k, Color(1.0, 0.95, 0.7, 0.85 * k))
	ci.draw_line(tip, tip + dir * (4.0 + 6.0 * k), Color(c.lightened(0.4), 0.9 * k), 2.0)
	for s in [-1.0, 1.0]:
		ci.draw_line(tip, tip + dir.rotated(s * 0.8) * (2.0 + 4.0 * k), Color(1.0, 0.9, 0.6, 0.7 * k), 1.0)


## Transformación local relativa a la de la figura (sombras, obleas).
static func _set_xf(ci: CanvasItem, pos: Vector2, sc: Vector2) -> void:
	ci.draw_set_transform_matrix(_base * Transform2D(0.0, sc, 0.0, pos))


static func _reset_xf(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(_base)


## Texto que no se ve al revés cuando la figura mira a la izquierda.
static func _text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color) -> void:
	var font := ThemeDB.fallback_font
	if _flip > 0.0:
		ci.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		return
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_set_xf(ci, pos + Vector2(w * 0.5, 0.0), Vector2(-1.0, 1.0))
	ci.draw_string(font, Vector2(-w * 0.5, 0.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	_reset_xf(ci)


## Balanceo al caminar (amplitud `amp`), que se apaga al pararse.
static func _stride(offset: float, amp: float) -> float:
	return sin(_walk + offset) * amp * _move


## Respiración/flote en espera, que se apaga al caminar.
static func _rest(ph: float, speed: float, amp: float) -> float:
	return sin(ph * speed) * amp * (1.0 - _move)


## Dirección del cañón: la de apuntado, sin pasarse de ±50° (no dispara hacia atrás).
static func _barrel() -> Vector2:
	return Vector2.from_angle(clampf(_aim.angle(), -0.9, 0.9))


# --- Figuras ---

## Robot centinela: patas, torso con visor que barre y un cañón que apunta.
static func _sentinel(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var bob := -absf(sin(_walk)) * 1.5 * _move + _rest(ph, 0.4, 0.8)
	for s in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(s * 4, 2), p + Vector2(s * 6 + _stride(s * 1.5, 3.0), 10), Color("4a4f5c"), 3.0, true)
	ci.draw_rect(Rect2(p + Vector2(-9, -16 + bob), Vector2(18, 16)), Color("6e7480"))
	ci.draw_rect(Rect2(p + Vector2(-9, -16 + bob), Vector2(18, 16)), Color("2f333c"), false, 1.5)
	ci.draw_rect(Rect2(p + Vector2(-6, -13 + bob), Vector2(12, 5)), Color("10161c"))
	ci.draw_rect(Rect2(p + Vector2(-5, -12 + bob), Vector2(10 * (0.5 + 0.5 * sin(ph * 0.7)), 3)), c)
	var pivot := p + Vector2(8, -6 + bob)
	var tip := pivot + _barrel() * (9.0 - 3.0 * _strike_k())   # el cañón se recoge al disparar
	ci.draw_line(pivot, tip, Color("3a3f4a"), 4.0)
	ci.draw_circle(tip, 1.5, Color(c, 0.8))
	_muzzle(ci, tip, _barrel(), c)
	ci.draw_line(p + Vector2(0, -16 + bob), p + Vector2(0, -22 + bob), Color("8a8a96"), 1.5)
	ci.draw_circle(p + Vector2(0, -23 + bob), 2.0, c)


## Daemon (el de BSD): cuerpecillo rojo con cuernos y un tridente.
static func _daemon(ci: CanvasItem, p: Vector2, ph: float) -> void:
	var hop := absf(sin(_walk)) * 3.0 * _move + (0.8 + _rest(ph, 0.5, 0.8))
	ci.draw_circle(p + Vector2(0, -8 - hop), 9.0, Color("b8322a"))
	ci.draw_circle(p + Vector2(0, -19 - hop), 6.5, Color("c83a30"))
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(s * 3, -24 - hop), p + Vector2(s * 8, -31 - hop), p + Vector2(s * 6, -22 - hop)]), Color("f0e0c0"))
	var eye := _aim * 0.8
	ci.draw_circle(p + Vector2(-2.5, -19 - hop) + eye, 1.3, Color("ffe070"))
	ci.draw_circle(p + Vector2(2.5, -19 - hop) + eye, 1.3, Color("ffe070"))
	# Tridente: en alto en reposo; al atacar se baja hacia el objetivo y pincha.
	var k := _strike_k()
	var dir := Vector2.UP.slerp(_aim, minf(1.0, k * 1.6)) if _atk > 0.0 else Vector2.UP
	var grip := p + Vector2(11, -14 - hop) + _aim * 6.0 * k
	var tip := grip + dir * 12.0
	var side := dir.orthogonal()
	ci.draw_line(grip - dir * 12.0, tip, Color("c8c8c8"), 1.5, true)
	ci.draw_line(tip - side * 3.0, tip + side * 3.0, Color("c8c8c8"), 1.5, true)
	for q in 3:
		var root := tip + side * (q - 1) * 3.0
		ci.draw_line(root, root + dir * 5.0, Color("c8c8c8"), 1.5, true)


## Golem de hardware: torres de PC apiladas con LEDs y un monitor por cabeza.
static func _golem(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var sway := _stride(0.0, 1.5) + _rest(ph, 0.3, 0.6)
	ci.draw_rect(Rect2(p + Vector2(-16, -28 + sway), Vector2(32, 30)), Color("5a5650"))
	ci.draw_rect(Rect2(p + Vector2(-16, -28 + sway), Vector2(32, 30)), Color("2a2724"), false, 2.0)
	for k in 4:
		ci.draw_circle(p + Vector2(-10 + k * 6, -6 + sway), 1.6, c if fmod(ph + k, 3.0) < 1.5 else Color("2a2a20"))
	var slam := _strike_k()
	for s in [-1.0, 1.0]:
		# Al golpear, los brazos suben y caen sobre el objetivo (el de delante, más).
		ci.draw_rect(Rect2(p + Vector2(s * 16 - (8 if s < 0 else 0) + (4.0 if s > 0 else 2.0) * slam, -24 + sway + _stride(s, 2.0) - 6.0 * slam), Vector2(8, 22)), Color("47443f"))
	var look := Vector2(_aim.x * 1.5, _aim.y * 1.5)
	ci.draw_rect(Rect2(p + Vector2(-11, -44 + sway) + look, Vector2(22, 16)), Color("b8b8b0"))
	ci.draw_rect(Rect2(p + Vector2(-9, -42 + sway) + look, Vector2(18, 11)), Color("10200f"))
	_text(ci, p + Vector2(-8, -33 + sway) + look, "ò_ó", 9, Color("3cff6a"))


## Mainframe Titán: un armario de servidores con piernas, hombreras de ventilador,
## un ojo-láser y LEDs que corren por el pecho. El doble de grande que el golem.
static func _titan(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var sway := _stride(0.0, 2.0) + _rest(ph, 0.25, 1.0)
	_set_xf(ci, p + Vector2(0, 4), Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.35))
	_reset_xf(ci)
	for s in [-1.0, 1.0]:   # piernas
		ci.draw_rect(Rect2(p + Vector2(s * 12 - 7, -14 + _stride(s, 2.0)), Vector2(14, 16)), Color("3a3f4a"))
		ci.draw_rect(Rect2(p + Vector2(s * 12 - 9, 0), Vector2(18, 5)), Color("2a2e36"))
	var body := Rect2(p + Vector2(-24, -62 + sway), Vector2(48, 50))
	ci.draw_rect(body, Color("2c3038"))
	ci.draw_rect(body, Color("14161a"), false, 2.0)
	for k in 5:   # bahías de discos con LEDs
		var y := body.position.y + 6 + k * 9
		ci.draw_rect(Rect2(body.position.x + 6, y, 36, 6), Color("1c1f26"))
		ci.draw_rect(Rect2(body.position.x + 8 + fmod(ph * 12.0 + k * 7.0, 30.0), y + 2, 3, 2), c)
		ci.draw_rect(Rect2(body.end.x - 10, y + 2, 2, 2), Color("40ff70") if int(ph * 3.0 + k) % 2 else Color("1a3020"))
	for s in [-1.0, 1.0]:   # hombreras con ventilador y brazos
		var sh := p + Vector2(s * 30, -54 + sway)
		ci.draw_circle(sh, 10.0, Color("4a4f5c"))
		ci.draw_circle(sh, 7.0, Color("1c1f26"))
		for k in 3:
			var a := ph * 6.0 + k * TAU / 3.0
			ci.draw_line(sh, sh + Vector2.from_angle(a) * 6.0, Color("8a8f9c"), 2.0)
		# Al golpear, el puño de delante se adelanta hacia el objetivo.
		var punch := _aim * 8.0 * _strike_k() if s > 0.0 else Vector2.ZERO
		ci.draw_rect(Rect2(sh + Vector2(-5, 8) + punch * 0.5, Vector2(10, 24 + _stride(s, 2.0))), Color("3a3f4a"))
		ci.draw_rect(Rect2(sh + Vector2(-7, 30) + punch, Vector2(14, 8)), Color("4a4f5c"))
	var head := Rect2(p + Vector2(-14, -82 + sway) + Vector2(_aim.x, _aim.y) * 2.0, Vector2(28, 18))
	ci.draw_rect(head, Color("4a4f5c"))
	ci.draw_rect(Rect2(head.position + Vector2(4, 6), Vector2(20, 6)), Color("10161c"))
	# Ojo-láser: barre en espera y se clava hacia el objetivo al apuntar.
	var eye_x := 8.0 + 6.0 * (_aim.x if _focus else sin(ph * 0.8))
	ci.draw_rect(Rect2(head.position + Vector2(eye_x, 7), Vector2(6, 4)), Color("ff3a3a"))
	ci.draw_line(head.position + Vector2(14, 0), head.position + Vector2(14, -8), Color("8a8f9c"), 2.0)
	ci.draw_circle(head.position + Vector2(14, -9), 2.5, c)


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
		"drones_vigilancia":
			# Cámara de vigilancia (T204): lente que barre y el piloto rojo de grabación.
			var look := Vector2(cos(ph * 0.8) * 1.5, 1.0)
			ci.draw_circle(p + look, 3.0, Color("101418"))
			ci.draw_circle(p + look, 1.5, c)
			if fmod(ph, 1.2) < 0.6:
				ci.draw_rect(Rect2(p + Vector2(3, -5), Vector2(2, 2)), Color("e04a3a"))
		"dron_medico":
			ci.draw_rect(Rect2(p + Vector2(-1.5, -4), Vector2(3, 8)), c)
			ci.draw_rect(Rect2(p + Vector2(-4, -1.5), Vector2(8, 3)), c)
		"dron_escudo":
			ci.draw_arc(p + Vector2(0, 1), 4.5, PI, TAU, 8, c, 2.0, true)
			ci.draw_arc(p + Vector2(0, 1), 9.0 + sin(ph) * 0.8, PI * 1.1, PI * 1.9, 10, Color(c, 0.5), 1.5, true)
		_:
			# El escolta: el núcleo-ojo mira al objetivo.
			ci.draw_circle(p + _aim * 1.5, 2.6 + 0.6 * sin(ph * 2.0), c)
			ci.draw_circle(p + Vector2(0, 7), 1.5 + absf(sin(ph * 5.0)), Color("ffb040"))   # tobera


## Bot de Pruebas: muñeco de choque (crash test) amarillo y negro, con su diana.
static func _dummy(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var run := _stride(0.0, 1.0)
	var idle := _rest(ph, 0.4, 1.0)
	for s in [-1.0, 1.0]:
		ci.draw_line(p + Vector2(s * 3, -8), p + Vector2(s * 4 + run * s * 3.0, 0), Color("2a2a2a"), 3.0, true)
	ci.draw_rect(Rect2(p + Vector2(-6, -20), Vector2(12, 13)), Color("e8c040"))
	ci.draw_rect(Rect2(p + Vector2(-6, -20), Vector2(6, 6.5)), Color("2a2a2a"))
	ci.draw_rect(Rect2(p + Vector2(0, -13.5), Vector2(6, 6.5)), Color("2a2a2a"))
	var punch := _strike_k()
	for s in [-1.0, 1.0]:
		var hand := p + Vector2(s * 10, -11 - run * s * 2.0 + idle * s)
		if s > 0.0 and punch > 0.0:
			hand = hand.lerp(p + Vector2(6, -16) + _aim * 11.0, punch)   # puñetazo de prueba
		ci.draw_line(p + Vector2(s * 6, -18), hand, Color("e8c040"), 2.5, true)
		if s > 0.0 and punch > 0.0:
			ci.draw_circle(hand, 2.0, Color("2a2a2a"))
	var head := p + Vector2(0, -26) + _aim * 1.0
	ci.draw_circle(head, 5.5, Color("e8c040"))
	ci.draw_arc(head, 3.2, 0.0, TAU, 10, Color("2a2a2a"), 1.0)
	ci.draw_circle(head, 1.0, c)


## Mina Rodante: bomba sobre dos ruedas con una mecha que chisporrotea.
static func _wheel_mine(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var rock := _rest(ph, 0.6, 0.6)
	for s in [-1.0, 1.0]:
		var w := p + Vector2(s * 7, -4)
		ci.draw_circle(w, 4.5, Color("3a3a40"))
		ci.draw_line(w, w + Vector2.from_angle(_walk * 1.5 + s) * 3.5, Color("8a8a96"), 1.0)   # ruedan al avanzar
	ci.draw_circle(p + Vector2(rock, -12), 9.0, Color("26262c"))
	ci.draw_circle(p + Vector2(-3 + rock, -15), 2.5, Color("5a5a66"))
	ci.draw_rect(Rect2(p + Vector2(-3 + rock, -22), Vector2(6, 3)), Color("8a8a96"))
	ci.draw_line(p + Vector2(rock, -22), p + Vector2(5 + rock, -28), Color("8a6d3b"), 1.5, true)
	var spark := 0.5 + 0.5 * sin(ph * 12.0)
	ci.draw_circle(p + Vector2(5 + rock, -29), 1.8 + spark * 1.5, Color(1.0, 0.8, 0.3, 0.9))
	ci.draw_circle(p + Vector2(rock, -12), 3.0, Color(c, 0.4 + 0.4 * spark))


## Agente IA: un orbe flotante con dos ojos verdes, una sonrisa y burbujas de datos.
static func _agent(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var float_y := sin(ph * 0.8) * 3.0
	var o := p + Vector2(0, -20 + float_y)
	ci.draw_circle(o, 10.0, Color("2a1f3a"))
	ci.draw_arc(o, 10.0, 0.0, TAU, 20, c, 2.0, true)
	ci.draw_arc(o, 13.0, ph, ph + 1.6, 8, Color(c, 0.5), 1.5, true)
	var blink := fmod(ph, 4.0) > 3.8
	var eye := _aim * 1.5   # los ojos miran al objetivo
	for s in [-1.0, 1.0]:
		if blink:
			ci.draw_line(o + Vector2(s * 3.5 - 1.5, -2) + eye, o + Vector2(s * 3.5 + 1.5, -2) + eye, Color("3cff9a"), 1.5)
		else:
			ci.draw_circle(o + Vector2(s * 3.5, -2) + eye, 1.8, Color("3cff9a"))
	ci.draw_arc(o + Vector2(0, 2) + eye * 0.5, 3.5, 0.3, PI - 0.3, 6, Color("3cff9a"), 1.2, true)
	for k in 3:
		var t := fmod(ph * 0.5 + k * 0.33, 1.0)
		ci.draw_circle(o + Vector2(8 + k * 2, -10 - t * 12.0), 1.2 + k * 0.4, Color(c, 0.8 * (1.0 - t)))


## Watchdog: perro guardián de chapa con collar parpadeante (reinicia lo que se cuelga).
static func _watchdog(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var trot := _stride(0.0, 1.0)
	var body := Color("8a6a4a")
	for k in 4:
		var x := -9.0 + k * 6.0
		ci.draw_line(p + Vector2(x, -6), p + Vector2(x + trot * (1.0 if k % 2 == 0 else -1.0) * 2.0, 0), Color("5a4430"), 2.5, true)
	ci.draw_colored_polygon(QuestItemArt.ellipse(p + Vector2(-1, -10 + absf(trot) * -1.0), 12.0, 6.0), body)
	ci.draw_line(p + Vector2(-12, -12), p + Vector2(-17, -18 - absf(sin(ph * 2.0)) * 3.0), body, 2.5, true)   # cola (menea siempre)
	var bite := _strike_k()
	var head := p + Vector2(11, -17) + Vector2(maxf(0.0, _aim.x) * 1.0, _aim.y * 3.0) + _aim * 4.0 * bite
	ci.draw_circle(head, 5.5, body)
	if bite > 0.05:
		# Mordida: la mandíbula se abre y enseña los dientes.
		var gape := 3.0 * bite
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(3, -1 - gape), head + Vector2(10, -gape), head + Vector2(3, 1)]), body.darkened(0.15))
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(3, 2), head + Vector2(9, 3 + gape), head + Vector2(3, 4)]), body.darkened(0.3))
		for q in 2:
			ci.draw_line(head + Vector2(5 + q * 3, 0 - gape * 0.6), head + Vector2(5 + q * 3, 1.5 - gape * 0.6), Color("f0f0e0"), 1.0)
	else:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(3, -1), head + Vector2(9, 1), head + Vector2(3, 3)]), body.darkened(0.15))   # hocico
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-3, -4), head + Vector2(-1, -10), head + Vector2(1, -4)]), body.darkened(0.3))   # oreja
	ci.draw_circle(head + Vector2(1.5, -1.5), 1.1, Color("ffe070"))
	ci.draw_line(p + Vector2(6, -14), p + Vector2(7, -9), c if fmod(ph, 1.0) < 0.5 else c.darkened(0.6), 2.0)   # collar con LED


## Bot Rastreador: robot de QA sobre una rueda, con lupa y cerbatana que apunta.
static func _bug_hunter(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var bob := _stride(0.0, 1.0) + _rest(ph, 0.4, 0.7)
	ci.draw_circle(p + Vector2(0, -4), 4.5, Color("3a3a40"))
	ci.draw_line(p + Vector2(0, -4), p + Vector2(0, -4) + Vector2.from_angle(_walk * 1.5) * 3.5, Color("8a8a96"), 1.0)
	ci.draw_rect(Rect2(p + Vector2(-7, -20 + bob), Vector2(14, 13)), Color("4a7a4a"))
	ci.draw_rect(Rect2(p + Vector2(-7, -20 + bob), Vector2(14, 13)), Color("1f331f"), false, 1.5)
	_text(ci, p + Vector2(-6, -10 + bob), "QA", 8, Color("dff0d0"))
	ci.draw_circle(p + Vector2(0, -25 + bob), 5.0, Color("5a8a5a"))
	ci.draw_circle(p + Vector2(1.5, -25 + bob) + _aim * 1.0, 2.0, c)
	# Lupa a un lado y cerbatana al otro.
	ci.draw_arc(p + Vector2(-11, -16 + bob), 3.5, 0.0, TAU, 10, Color("c8c8c8"), 1.5, true)
	ci.draw_line(p + Vector2(-9, -13 + bob), p + Vector2(-6, -10 + bob), Color("8a6d3b"), 1.5)
	var mouth := p + Vector2(7, -14 + bob)
	var tip := mouth + _barrel() * (9.5 - 2.5 * _strike_k())
	ci.draw_line(mouth, tip, Color("6a5a4a"), 2.0)
	ci.draw_circle(tip, 1.2, c)
	_muzzle(ci, tip, _barrel(), c)   # el soplido del dardo


# --- Golems (cada uno con su silueta: nada de cajas con patas) ---

## Golem del Silicio: coloso de cristal en bruto, con un die de chip brillando
## en el pecho, esquirlas en los hombros y obleas que orbitan a su alrededor.
static func _golem_silicon(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var sway := _stride(0.0, 1.5) + _rest(ph, 0.3, 0.8)
	var dark := Color("3e5866")
	var mid := Color("6f93a6")
	var light := Color("b8dcec")
	for s in [-1.0, 1.0]:   # piernas: columnas hexagonales
		var lp := p + Vector2(s * 9, -2 + _stride(s, 1.5))
		ci.draw_colored_polygon(PackedVector2Array([lp + Vector2(-6, 2), lp + Vector2(-7, -10), lp + Vector2(-3, -16), lp + Vector2(4, -16), lp + Vector2(7, -10), lp + Vector2(6, 2)]), dark)
		ci.draw_line(lp + Vector2(-3, -15), lp + Vector2(-5, 0), mid, 1.5)
	# Torso: una gema irregular con caras claras y oscuras.
	var t := p + Vector2(0, -32 + sway)
	var torso := PackedVector2Array([t + Vector2(-20, -8), t + Vector2(-9, -20), t + Vector2(10, -19), t + Vector2(21, -6), t + Vector2(15, 14), t + Vector2(-14, 15)])
	ci.draw_colored_polygon(torso, mid)
	ci.draw_colored_polygon(PackedVector2Array([t + Vector2(-9, -20), t + Vector2(10, -19), t + Vector2(2, -6)]), light)
	ci.draw_colored_polygon(PackedVector2Array([t + Vector2(21, -6), t + Vector2(15, 14), t + Vector2(4, 4)]), dark)
	ci.draw_polyline(torso + PackedVector2Array([torso[0]]), Color("22343d"), 1.5)
	# El die del chip: cuadrado con rejilla que late.
	var glow := 0.6 + 0.4 * sin(ph * 1.6)
	ci.draw_rect(Rect2(t + Vector2(-7, -5), Vector2(14, 12)), Color("101a20"))
	for k in 3:
		ci.draw_line(t + Vector2(-6 + k * 5, -4), t + Vector2(-6 + k * 5, 6), Color(c, glow), 1.0)
		ci.draw_line(t + Vector2(-6, -3 + k * 4), t + Vector2(6, -3 + k * 4), Color(c, glow * 0.7), 1.0)
	# Hombros: racimos de esquirlas.
	for s in [-1.0, 1.0]:
		for k in 3:
			var base := t + Vector2(s * (17 + k * 3), -12 + k * 3)
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 2), base + Vector2(s * 2, -10 + k * 2), base + Vector2(3, 2)]), light if k == 0 else mid)
		var arm := t + Vector2(s * 20, 2 + _stride(s + 0.5, 2.0) + _rest(ph, 0.5, 0.6))
		if s > 0.0:
			arm += (_aim * 9.0 + Vector2(0, -5)) * _strike_k()   # al golpear, el brazo de delante cae sobre el objetivo
		ci.draw_colored_polygon(PackedVector2Array([arm + Vector2(-4, -4), arm + Vector2(4, -4), arm + Vector2(6, 12), arm + Vector2(0, 18), arm + Vector2(-6, 12)]), dark)
	# Cabeza: gema pequeña con dos ojos que miran al objetivo.
	var h := t + Vector2(0, -27) + _aim * 1.5
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-7, 2), h + Vector2(-4, -7), h + Vector2(5, -7), h + Vector2(8, 2), h + Vector2(0, 7)]), mid)
	ci.draw_rect(Rect2(h + Vector2(-4, -2), Vector2(2, 2)), c)
	ci.draw_rect(Rect2(h + Vector2(2, -2), Vector2(2, 2)), c)
	# Obleas en órbita (detrás y delante).
	for k in 3:
		var a := ph * 0.6 + TAU * k / 3.0
		var wp := t + Vector2(cos(a) * 30.0, sin(a) * 9.0 - 4.0)
		_set_xf(ci, wp, Vector2(1.0, 0.45))
		ci.draw_circle(Vector2.ZERO, 5.0, Color(light, 0.85 if sin(a) > 0.0 else 0.4))
		ci.draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 10, Color(c, 0.7), 1.0)
		_reset_xf(ci)


## Golem de Overclock: un disipador de aletas al rojo vivo, que se inclina hacia
## delante al correr, con un ventilador por cabeza y llamas de calor.
static func _golem_overclock(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var run := _stride(0.0, 1.0)
	var lean := 1.0 + 3.0 * _move
	for s in [-1.0, 1.0]:   # piernas de muelle (zigzag)
		var hip := p + Vector2(s * 5 + lean * 0.3, -14 + _rest(ph, 0.8, 1.0))
		var foot := p + Vector2(s * 5 + run * s * 6.0, 0)
		var pts := PackedVector2Array([hip])
		for k in 5:
			var q := hip.lerp(foot, (k + 1) / 6.0)
			pts.append(q + Vector2(3.0 if k % 2 == 0 else -3.0, 0))
		pts.append(foot)
		ci.draw_polyline(pts, Color("9a9aa6"), 2.0)
		ci.draw_rect(Rect2(foot + Vector2(-4, -1), Vector2(8, 3)), Color("4a4a56"))
	# Cuerpo: aletas verticales que pasan de aluminio a rojo vivo abajo.
	var body := p + Vector2(lean, -38 + _rest(ph, 0.8, 1.0))
	for k in 7:
		var x := -12.0 + k * 4.0
		var heat := 0.5 + 0.5 * sin(ph * 3.0 + k)
		ci.draw_rect(Rect2(body + Vector2(x, 0), Vector2(2.5, 24)), Color("b8bcc6").lerp(Color("ff5a20"), 0.35 + 0.25 * heat))
		ci.draw_rect(Rect2(body + Vector2(x, 16), Vector2(2.5, 8)), Color("ff8a3a").lerp(Color("ffe070"), heat * 0.6))
	ci.draw_rect(Rect2(body + Vector2(-14, 22), Vector2(28, 4)), Color("6a4a3a"))
	# Núcleo al rojo con destello.
	var core := body + Vector2(0, 12)
	ci.draw_circle(core, 7.0 + run, Color(c, 0.35))
	ci.draw_circle(core, 4.0, Color("ffe070"))
	# Brazos: barras de cobre (heatpipes) que bracean al correr; al golpear, el de
	# delante sale disparado hacia el objetivo.
	for s in [-1.0, 1.0]:
		var sh := body + Vector2(s * 14, 4)
		var fist := sh + Vector2(s * 4 - run * s * 5.0, 16)
		if s > 0.0:
			fist = fist.lerp(sh + _aim * 18.0, _strike_k())
		ci.draw_line(sh, fist, Color("c87a3a"), 3.0)
		ci.draw_circle(fist, 2.5, Color("e0a060"))
	# Cabeza: carcasa de ventilador con aspas girando muy rápido.
	var head := body + Vector2(2, -9) + _aim * 1.5
	ci.draw_circle(head, 9.0, Color("2a2a30"))
	ci.draw_arc(head, 9.0, 0.0, TAU, 16, Color("8a8a96"), 1.5)
	for k in 5:
		var a := ph * 14.0 + TAU * k / 5.0
		ci.draw_line(head, head + Vector2.from_angle(a) * 7.0, Color("d8d8e0", 0.8), 2.0)
	ci.draw_circle(head, 2.5, c)
	# Calor: llamitas que suben de las aletas.
	for k in 3:
		var f := fmod(ph * 0.9 + k * 0.33, 1.0)
		var fp := body + Vector2(-8 + k * 8, -2 - f * 18.0)
		ci.draw_colored_polygon(PackedVector2Array([fp + Vector2(-2.5, 0), fp + Vector2(0, -6), fp + Vector2(2.5, 0)]), Color(c, 0.8 * (1.0 - f)))


## Golem UTP: una maraña de cables de red (azul, naranja, verde y marrón) que se
## retuercen, con dos LEDs de puerto por ojos y brazos que acaban en conectores RJ45.
static func _golem_utp(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var cols := [Color("3a6fd0"), Color("e0802a"), Color("3aa04a"), Color("8a5a30"), Color("d8d8d8")]
	var center := p + Vector2(0, -26 + _rest(ph, 0.3, 1.0) - absf(_stride(0.0, 1.5)))
	# La maraña: lazos de cable alrededor del centro, cada uno moviéndose un poco.
	for k in 14:
		var col: Color = cols[k % cols.size()]
		var a0 := k * 2.4 + ph * 0.15 * (1.0 if k % 2 == 0 else -1.0)
		var rad := 10.0 + float(k % 4) * 3.5
		var loop := PackedVector2Array()
		for q in 9:
			var a := a0 + q * 0.55
			loop.append(center + Vector2(cos(a) * rad * 1.25, sin(a) * rad) + Vector2(sin(ph + k + q) * 1.5, 0))
		ci.draw_polyline(loop, col.darkened(0.15), 2.5, true)
	# Patas: tres manojos de cable que llegan al suelo.
	for s in [-1.0, 0.0, 1.0]:
		var top := center + Vector2(s * 9, 12)
		var foot := p + Vector2(s * 12 + _stride(s * 2.0, 3.0), 0)
		ci.draw_line(top, foot, cols[int(s + 1)], 3.0)
		ci.draw_line(top + Vector2(2, 0), foot + Vector2(3, 0), Color(cols[4], 0.7), 1.5)
	# Brazos: cables largos que cuelgan y se balancean, con un RJ45 al final.
	for s in [-1.0, 1.0]:
		var sh := center + Vector2(s * 16, -4)
		var hand := sh + Vector2(s * 10 + sin(ph * 1.3 + s) * (1.5 + 2.5 * _move), 20)
		if s > 0.0 and _atk > 0.0:
			# Latigazo: el brazo de delante se echa atrás y restalla hacia el objetivo.
			var lash := sh + _aim * 26.0 + Vector2(0, -4)
			var back := sh + Vector2(-6, -14)
			if _atk < 0.15:
				hand = hand.lerp(back, _atk / 0.15)
			elif _atk < 0.3:
				hand = back.lerp(lash, (_atk - 0.15) / 0.15)
			else:
				hand = lash.lerp(hand, smoothstep(0.3, 1.0, _atk))
		var mid := sh.lerp(hand, 0.5) + Vector2(s * 6, 0)
		ci.draw_polyline(PackedVector2Array([sh, mid, hand]), cols[0 if s < 0 else 1], 3.0, true)
		ci.draw_rect(Rect2(hand + Vector2(-4, 0), Vector2(8, 7)), Color(0.85, 0.9, 0.95, 0.8))
		for k in 3:
			ci.draw_rect(Rect2(hand + Vector2(-3 + k * 2.5, 5), Vector2(1.5, 2)), Color("e0b050"))
	# Ojos: LEDs de enlace (verde fijo y naranja que parpadea con la actividad).
	var eyes := center + _aim * 1.5
	ci.draw_rect(Rect2(eyes + Vector2(-7, -6), Vector2(5, 4)), Color("1a1a1a"))
	ci.draw_rect(Rect2(eyes + Vector2(2, -6), Vector2(5, 4)), Color("1a1a1a"))
	ci.draw_rect(Rect2(eyes + Vector2(-6, -5), Vector2(3, 2)), Color("40ff70"))
	ci.draw_rect(Rect2(eyes + Vector2(3, -5), Vector2(3, 2)), Color("ffa030") if int(ph * 5.0) % 2 == 0 else Color("3a2a10"))


## Golem GPU: una tarjeta gráfica que camina: carcasa ancha con dos
## ventiladores en el pecho, tira RGB que cambia de color, dientes de contacto
## PCIe dorados por mandíbula y patas de heatpipe de cobre.
static func _golem_gpu(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var bob := _stride(0.0, 1.2) + _rest(ph, 0.4, 0.8)
	for s in [-1.0, 1.0]:   # patas de heatpipe (curvas de cobre)
		var hip := p + Vector2(s * 12, -14 + bob)
		var foot := p + Vector2(s * 14 + _stride(s, 3.0), 0)
		ci.draw_polyline(PackedVector2Array([hip, hip.lerp(foot, 0.5) + Vector2(s * 4, 0), foot]), Color("c87a3a"), 3.0, true)
		ci.draw_rect(Rect2(foot + Vector2(-4, -1), Vector2(8, 3)), Color("3a3a42"))
	var body := Rect2(p + Vector2(-24, -38 + bob), Vector2(48, 24))
	ci.draw_rect(body, Color("1e2026"))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, 3)), Color("3a3e48"))
	ci.draw_rect(body, Color("0c0d10"), false, 1.5)
	# Tira RGB por el borde de arriba, que recorre el arcoíris.
	for k in 12:
		ci.draw_rect(Rect2(body.position + Vector2(2 + k * 3.8, 1), Vector2(3, 2)), Color.from_hsv(fmod(ph * 0.15 + k / 12.0, 1.0), 0.8, 1.0))
	# Dos ventiladores girando.
	for s in [-1.0, 1.0]:
		var fan := body.get_center() + Vector2(s * 11, 1)
		ci.draw_circle(fan, 9.0, Color("2c2f38"))
		ci.draw_arc(fan, 9.0, 0.0, TAU, 16, Color("5a5e6a"), 1.0)
		for k in 7:
			var a: float = ph * 9.0 * s + TAU * k / 7.0
			ci.draw_line(fan + Vector2.from_angle(a) * 2.0, fan + Vector2.from_angle(a + 0.5) * 8.0, Color("8a8e9a"), 1.5)
		ci.draw_circle(fan, 2.5, c)
	# Mandíbula: los dientes dorados del conector PCIe.
	for k in 10:
		ci.draw_rect(Rect2(body.position + Vector2(5 + k * 4, body.size.y), Vector2(2.5, 4)), Color("e0b050"))
	# Cabeza: el bloque de puertos de vídeo, con dos LEDs por ojos; gira hacia el objetivo.
	var head := Rect2(p + Vector2(-9, -49 + bob) + Vector2(_aim.x * 2.0, _aim.y * 2.0), Vector2(18, 11))
	ci.draw_rect(head, Color("3a3e48"))
	ci.draw_rect(Rect2(head.position + Vector2(2, 3), Vector2(6, 4)), Color("0c0d10"))
	ci.draw_rect(Rect2(head.position + Vector2(10, 3), Vector2(6, 4)), Color("0c0d10"))
	ci.draw_rect(Rect2(head.position + Vector2(3, 4), Vector2(3, 2)), c)
	ci.draw_rect(Rect2(head.position + Vector2(11, 4), Vector2(3, 2)), c)
	# Dispara por los puertos de vídeo: fogonazo hacia el objetivo.
	_muzzle(ci, head.get_center() + _barrel() * 9.0, _barrel(), c)


## Golem de Kernel: un espectro que flota sobre una cola de píxeles que se
## deshace, con una pantalla «:(» por cara, volcados de memoria girando a su
## alrededor y gotas de caos cayendo.
static func _golem_kernel(ci: CanvasItem, p: Vector2, ph: float, c: Color) -> void:
	var hover := sin(ph * 0.7) * 3.0
	var top := p + Vector2(0, -50 + hover)
	# Cola que se deshace en píxeles (se arrastra hacia atrás al avanzar).
	for k in 8:
		var f := fmod(ph * 0.4 + k * 0.125, 1.0)
		ci.draw_rect(Rect2(p + Vector2(-6 + (k % 4) * 3.5 - f * 6.0 * _move, -10 + f * 10.0 + hover), Vector2(3, 3)), Color(c, 0.7 * (1.0 - f)))
	# Túnica: silueta que se estrecha hacia abajo, con borde que brilla.
	var drag := -4.0 * _move
	var robe := PackedVector2Array([top + Vector2(-15, 8), top + Vector2(-8, -2), top + Vector2(8, -2), top + Vector2(15, 8),
		top + Vector2(11 + drag * 0.5, 30), top + Vector2(5 + drag, 40), top + Vector2(drag, 36), top + Vector2(-5 + drag, 40), top + Vector2(-11 + drag * 0.5, 30)])
	ci.draw_colored_polygon(robe, Color("1c1028"))
	ci.draw_polyline(robe + PackedVector2Array([robe[0]]), Color(c, 0.6 + 0.3 * sin(ph * 1.4)), 1.5, true)
	# Cara: una pantalla con «:(» (el pánico del kernel), vuelta hacia el objetivo.
	var face := Rect2(top + Vector2(-9, -16) + _aim * 1.5, Vector2(18, 14))
	ci.draw_rect(face, Color("2a1640"))
	ci.draw_rect(face, Color(c, 0.9), false, 1.0)
	_text(ci, face.position + Vector2(3, 11), ":(", 10, Color("e0d0ff"))
	# Manos espectrales: al golpear, la de delante se alarga hacia el objetivo.
	for s in [-1.0, 1.0]:
		var hand := top + Vector2(s * 19, 14 + sin(ph + s) * 3.0)
		if s > 0.0:
			hand += _aim * 12.0 * _strike_k()
		ci.draw_circle(hand, 3.5, Color(c, 0.5))
		ci.draw_circle(hand, 2.0, Color("b0ff90"))
	# Volcados de memoria girando: «0x», «#», «$», «PID».
	var glyphs := ["0x", "#", "$", "PID"]
	for k in glyphs.size():
		var a := ph * 0.5 + TAU * k / glyphs.size()
		var gp := top + Vector2(cos(a) * 24.0, 12.0 + sin(a) * 8.0)
		_text(ci, gp, glyphs[k], 8, Color(c.lightened(0.4), 0.5 + 0.4 * sin(a)))
	# Gotas de caos.
	for k in 3:
		var f := fmod(ph * 0.6 + k * 0.33, 1.0)
		ci.draw_rect(Rect2(top + Vector2(-8 + k * 8, 30 + f * 20.0), Vector2(2, 3)), Color("8aff70", 0.8 * (1.0 - f)))
