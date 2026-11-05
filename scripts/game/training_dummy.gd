class_name TrainingDummy
extends Node2D
## Muñeco de prácticas del campamento (T212): un servidor de pruebas que recibe
## golpes y no se rompe. Por debajo es un enemigo estático de EnemyManager (el tipo
## del candado, sin ataque ni resistencias y con vida que nunca baja), así que le
## afectan las resistencias, los estados y las interacciones de verdad; por encima se
## dibuja como un rack con su pantalla. Mide el daño de los últimos WINDOW segundos
## (golpes con su tipo, de EnemyManager.number_events, y daños degenerativos, de sus
## estados) para el panel TrainingPanel: DPS, daño por golpe y reparto por tipo.

## Segundos que cuenta la medida.
const WINDOW := 10.0
## Vida enorme: se rellena cada fotograma, nunca muere.
const LIFE := 1.0e9
const NAME := "Servidor de pruebas"
const TYPE_ID := "mutex_lock"
## Los degenerativos se apuntan juntos cada tanto (no una entrada por fotograma).
const DOT_BUCKET := 0.25
## Distancia a la que se ve el panel con sus cifras.
const PANEL_RANGE := 560.0
const TYPES := ["physical", "fire", "cold", "lightning", "chaos"]
const TYPE_NAMES := {"physical": "Físico", "fire": "Fuego", "cold": "Frío", "lightning": "Rayo", "chaos": "Caos"}
const TYPE_COLORS := {"physical": Color("c8b8a0"), "fire": Color("e0652f"), "cold": Color("7fb8e0"),
	"lightning": Color("e8d070"), "chaos": Color("b04ad9")}

var enemies: EnemyManager
## Id del enemigo que hace de muñeco (-1 si aún no hay).
var dummy_id := -1
var spot := Vector2.ZERO
## Lo medido: [{t, amount, type, hit, crit}], lo más viejo primero.
var events: Array[Dictionary] = []
## Reloj propio (para las pruebas, que lo avanzan a mano).
var now := 0.0
## Cuándo empezó la tanda (el primer golpe tras WINDOW segundos sin nada).
var session_start := -1.0
var _dot_pending := {}
var _dot_t := 0.0
## Destello y temblor del dibujo al recibir.
var _flash := 0.0
var _shake := 0.0


func _init() -> void:
	process_priority = -10   # antes que DamageNumbers, que vacía number_events
	process_physics_priority = 10   # después de EnemyManager (los estados ya avanzaron)


## Pone el muñeco en `pos` (como enemigo de `em`).
func setup(em: EnemyManager, pos: Vector2) -> void:
	enemies = em
	spot = pos
	position = pos
	_spawn()


func _spawn() -> void:
	var t := enemies.type_index_of(TYPE_ID)
	dummy_id = enemies.spawn(spot, Rarity.Enemy.NORMAL, maxi(t, 0), NAME)
	var i := enemies.index_of(dummy_id)
	enemies.traits[i] = {}   # sin resistencias ni inmunidades: mide el daño tal cual
	enemies.speeds[i] = 0.0
	enemies.damages[i] = 0.0
	enemies.lives[i] = LIFE
	enemies.max_lives[i] = LIFE


func index() -> int:
	return enemies.index_of(dummy_id) if enemies else -1


## Apunta un golpe o un daño degenerativo.
func record(amount: float, type: String, hit: bool, crit := false) -> void:
	if amount <= 0.0:
		return
	if not TYPES.has(type):
		type = "physical"
	if session_start < 0.0 or events.is_empty() or now - float(events.back()["t"]) > WINDOW:
		session_start = now
	events.append({"t": now, "amount": amount, "type": type, "hit": hit, "crit": crit})
	if hit:
		_flash = 0.12
		_shake = 0.18 if crit else maxf(_shake, 0.08)


## Avanza el reloj y olvida lo que ya no está en la ventana.
func advance(delta: float) -> void:
	now += delta
	while not events.is_empty() and now - float(events[0]["t"]) > WINDOW:
		events.pop_front()


## Las cifras de la ventana: dps, total, segundos medidos, golpes (cuántos, media,
## máximo, % de críticos), daño por segundo de los degenerativos y el reparto por
## tipo ([[tipo, daño, fracción]], de más a menos).
static func summarize(list: Array[Dictionary], at: float, started: float) -> Dictionary:
	var total := 0.0
	var hits := 0
	var hit_sum := 0.0
	var top := 0.0
	var crits := 0
	var dot := 0.0
	var by := {}
	for e in list:
		var a := float(e["amount"])
		total += a
		by[e["type"]] = float(by.get(e["type"], 0.0)) + a
		if e["hit"]:
			hits += 1
			hit_sum += a
			top = maxf(top, a)
			crits += 1 if e["crit"] else 0
		else:
			dot += a
	# De 1 s (el primer golpe no da un DPS absurdo) a WINDOW: lo que lleva la tanda.
	var span := clampf(at - started, 1.0, WINDOW) if started >= 0.0 else WINDOW
	var types: Array = []
	for k in by:
		types.append([k, by[k], by[k] / total if total > 0.0 else 0.0])
	types.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return {"dps": total / span, "total": total, "span": span, "hits": hits,
		"per_hit": hit_sum / hits if hits > 0 else 0.0, "max_hit": top,
		"crit_rate": float(crits) / hits if hits > 0 else 0.0, "dot_dps": dot / span, "types": types}


func stats() -> Dictionary:
	return summarize(events, now, session_start)


## Los golpes de este fotograma (antes de que DamageNumbers los vacíe).
func _process(delta: float) -> void:
	if enemies == null:
		return
	for e in enemies.number_events:
		if int(e[3]) == dummy_id:
			record(float(e[1]), String(e[4]) if (e as Array).size() > 4 else "physical", true, bool(e[2]))
	var i := index()
	if i == -1:
		_spawn()   # por si algo lo quitó (F2 de depuración, un golpe de más de mil millones)
		i = index()
	enemies.lives[i] = LIFE
	enemies.positions[i] = spot   # quieto aunque un empujón lo mueva
	advance(delta)
	_flash = maxf(0.0, _flash - delta)
	_shake = maxf(0.0, _shake - delta)
	queue_redraw()


## Los degenerativos: lo mismo que suma EnemyManager._update_dots en este paso.
func _physics_process(delta: float) -> void:
	if enemies == null:
		return
	var i := index()
	if i == -1 or enemies.frozen:
		return
	var by := dot_split(enemies, i)
	for k in by:
		_dot_pending[k] = float(_dot_pending.get(k, 0.0)) + float(by[k]) * delta
	_dot_t += delta
	if _dot_t >= DOT_BUCKET - 0.001:
		_dot_t = 0.0
		for k in _dot_pending:
			record(float(_dot_pending[k]), k, false)
		_dot_pending.clear()


## Daño por segundo de los degenerativos activos del enemigo `i`, por tipo:
## corrupción y veneno (con la infección) caos, quemadura fuego, sangrado físico;
## electrocutado los amplifica (como en EnemyManager._update_dots).
static func dot_split(em: EnemyManager, i: int) -> Dictionary:
	var out := {}
	if em.dot_time[i] > 0.0:
		out["chaos"] = em.dot_dps[i]
	if em.burn_time[i] > 0.0:
		out["fire"] = em.burn_dps[i]
	if em.poison_time[i] > 0.0:
		var p := em.poison_dps[i]
		if em.bleed_time[i] > 0.0:
			p += em.poison_dps[i] * 0.5 * em.interaction_power
		out["chaos"] = float(out.get("chaos", 0.0)) + p
	if em.bleed_time[i] > 0.0:
		out["physical"] = em.bleed_dps[i]
	if em.shock_time[i] > 0.0:
		for k in out:
			out[k] = float(out[k]) * (1.0 + em.shock_amp[i])
	return out


# --- Dibujo: un rack de servidores con su pantalla, encima del candado ---

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var o := Vector2(sin(t * 60.0) * 3.0, 0.0) * (_shake / 0.18) if _shake > 0.0 else Vector2.ZERO
	# Sombra, patas y cuerpo.
	draw_set_transform(Vector2(0, 18), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 38.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var body := Rect2(Vector2(-28, -62) + o, Vector2(56, 80))
	draw_rect(Rect2(body.position + Vector2(4, 76), Vector2(8, 6)), Color("1a1e26"))
	draw_rect(Rect2(body.position + Vector2(44, 76), Vector2(8, 6)), Color("1a1e26"))
	draw_rect(body, Color("2a3140"))
	draw_rect(body, Color("4a5568"), false, 2.0)
	# Pantalla con un gráfico que late con lo que recibe.
	var screen := Rect2(body.position + Vector2(6, 6), Vector2(44, 22))
	draw_rect(screen, Color("0b1a14"))
	var level := clampf(float(stats()["dps"]) / 1000.0, 0.0, 1.0) if not events.is_empty() else 0.0
	var pts := PackedVector2Array()
	for k in 12:
		var y := 0.5 + 0.35 * sin(t * 5.0 + k * 0.9) * (0.2 + 0.8 * level)
		pts.append(screen.position + Vector2(2.0 + k * 3.6, screen.size.y * clampf(1.0 - y, 0.1, 0.9)))
	draw_polyline(pts, Color("3cff6a"), 1.5)
	# Bahías con sus luces (parpadean más cuanto más daño).
	for row in 4:
		var bay := Rect2(body.position + Vector2(6, 33 + row * 11), Vector2(44, 8))
		draw_rect(bay, Color("1d2330"))
		for led in 3:
			var on := fposmod(t * (2.0 + 9.0 * level) + row * 1.7 + led * 2.3, 3.0) < 1.6
			draw_rect(Rect2(bay.position + Vector2(30 + led * 4.5, 2.5), Vector2(3, 3)),
				Color("3cff6a") if on else Color("1f4d2a"))
		draw_line(bay.position + Vector2(3, 4), bay.position + Vector2(22, 4), Color("3a4252"), 1.0)
	if _flash > 0.0:
		draw_rect(body, Color(1, 1, 1, _flash / 0.12 * 0.45))
	# Letrero.
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, 36), "PRUEBAS", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("8b949e"))
