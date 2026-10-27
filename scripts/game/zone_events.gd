class_name ZoneEvents
extends Node2D
## Eventos dentro de las zonas de combate (para que las zonas grandes tengan
## sorpresas, no solo más manadas). Se colocan al azar en cada visita:
## - "cache": Datos huérfanos. Al abrirlo salen dos oleadas; al limpiarlas, botín.
## - "shrine": Santuario. Al tocarlo da un bono temporal (turbo, firewall, debug)
##   o llena tus cargas (overclock).
## - "ambush": Emboscada. Invisible: al pasar cerca, te rodean dos manadas.
## - "deploy": Deploy fallido. Una consola; al tocarla salen dos raros con escolta
##   y, al vencerlos, botín.
## - "bombs": Bombas lógicas. Al tocar la consola aparecen tres bombas con cuenta
##   atrás: quédate junto a cada una para desactivarla antes de que estallen.
## - "escort": Escoltar un proceso. Un proceso perdido camina hasta su salida, pero
##   solo si estás cerca y no hay enemigos junto a él; a mitad de camino, emboscadas.
## - "merchant": Comerciante ambulante. Un objeto misterioso (con buena rareza) por fichas.
## Mecánicas principales nuevas (T121), de toda la zona o con cuenta atrás:
## - "gc": Garbage Collector. Cada cierto tiempo, tras un aviso, una línea barre la zona de
##   lado a lado y daña a todo lo que pilla (enemigos incluidos: se puede usar). Tras
##   GC_SWEEPS barridos, termina y da su botín.
## - "blackout": Apagón del CPD. La zona está casi a oscuras; las luces de emergencia
##   se encienden al pasar a su lado y cada una devuelve algo de luz. Todas: completada.
## - "ticket": Ticket urgente. Al tocar la consola, unos élites quedan marcados por toda
##   la zona: tumbarlos antes de que acabe la cuenta atrás.
## Y (T122), también de toda la zona:
## - "merge": Merge conflict. Los enemigos se reparten en dos ramas (HEAD y main) y, si
##   se cruzan lejos de ti, se pelean entre ellos. MERGE_KILLS bajas entre ellos: resuelto.
## - "friday": Deploy de viernes. Cada cierto tiempo entra una oleada por una salida;
##   quédate en el terminal del pipeline FRIDAY_HOLD s para cerrarlo.
## - "hot_cache": Caché caliente. Baldosas que dan un bono corto al pisarlas, se enfrían
##   y cambian de sitio. Usar HOT_CACHE_USES: completada.
## La zona dibuja y detecta; World hace aparecer enemigos y da recompensas.

signal triggered(event: Dictionary)
## Un evento con objetivo (bombas, escolta) terminó: bien o mal.
signal resolved(event: Dictionary, success: bool)
## Una bomba lógica no se desactivó a tiempo.
signal exploded(pos: Vector2)
## El proceso escoltado llegó a un tramo (1/3, 2/3): toca emboscada.
signal escort_wave(event: Dictionary)
## Garbage Collector: empieza el aviso de un barrido (World hace sonar la alarma).
signal gc_warning(event: Dictionary)
## Apagón: se encendió una luz de emergencia; `lit_frac` de 0 a 1.
signal blackout_changed(event: Dictionary, lit_frac: float)
## Deploy de viernes: toca oleada en `at` (junto a una salida).
signal friday_wave(event: Dictionary, at: Vector2)
## Caché caliente: el jugador pisó una baldosa con este bono (clave de HOT_CACHE_BUFFS).
signal hot_cache_hit(event: Dictionary, buff: String)

## Los pesos y cuáles son principales o menores están en data/zone_mechanics.json (T120).
const KINDS := ["cache", "shrine", "ambush", "deploy", "bombs", "escort", "merchant", "gc", "blackout", "ticket",
	"merge", "friday", "hot_cache"]
## Las que ocupan toda la zona y empiezan activas (sin consola que tocar).
const ZONE_WIDE := ["gc", "blackout", "merge", "friday", "hot_cache"]
## Las que, si se sale de la zona a medias, se dan por cerradas al volver (su pelea
## apuntaba a enemigos que ya no existen con esos ids). Las de toda la zona siguen.
const INTERRUPTIBLE := ["cache", "ambush", "deploy", "bombs", "escort", "ticket"]
const GC_INTERVAL := 16.0
const GC_WARNING := 2.2
const GC_SPEED := 620.0
const GC_BAND := 46.0
const GC_SWEEPS := 5
## Daño del barrido: parte de la vida máxima del jugador y de la de cada enemigo.
const GC_PLAYER_DAMAGE := 0.16
const GC_ENEMY_DAMAGE := 0.45
const BLACKOUT_LIGHTS := 6
const LIGHT_RADIUS := 120.0
const BLACKOUT_DARK := 0.42
const TICKET_TIME := 120.0
const TICKET_MARKS := 3
const GC_COLOR := Color("4ae0c8")
## Merge conflict: cada cuánto se miran las ramas, a qué distancia pelean, cuánto se
## quitan (de su propia vida máxima por golpe) y cuántas bajas lo resuelven.
const MERGE_TICK := 0.3
const MERGE_REACH := 110.0
const MERGE_PULL := 380.0
const MERGE_DAMAGE := 0.07
const MERGE_KILLS := 12
## A esta distancia de ti, los enemigos te prefieren a ti antes que a la otra rama.
const MERGE_IGNORE_PLAYER := 450.0
const MERGE_COLORS := [Color("ff6a5a"), Color("6ad07a")]
const MERGE_NAMES := ["HEAD", "main"]
const FRIDAY_INTERVAL := 24.0
const FRIDAY_MAX_WAVES := 6
const FRIDAY_HOLD := 3.0
const FRIDAY_RADIUS := 80.0
const HOT_CACHE_TILES := 5
const HOT_CACHE_RADIUS := 64.0
const HOT_CACHE_USES := 8
const HOT_CACHE_COOLDOWN := 4.0
const HOT_CACHE_MOVE := 12.0
const HOT_CACHE_SECONDS := 6.0
const HOT_CACHE_BUFFS := {
	"hit": {"name": "Cache hit", "text": "+35 % de daño", "color": "ff9a3a", "mods": [{"stat": "damage", "type": "more", "value": 35}]},
	"warm": {"name": "Caché precalentada", "text": "+30 % de velocidad", "color": "6aa8ff",
		"mods": [{"stat": "attack_speed", "type": "increased", "value": 30}, {"stat": "cast_speed", "type": "increased", "value": 30}, {"stat": "movement_speed", "type": "increased", "value": 20}]},
	"l1": {"name": "L1", "text": "60 % más de armadura", "color": "e0c050", "mods": [{"stat": "armour", "type": "more", "value": 60}]},
}
const BOMB_COUNT := 3
const BOMB_TIME := 25.0
const BOMB_SPREAD := 300.0
const DEFUSE_RADIUS := 70.0
const DEFUSE_TIME := 1.5
const BOMB_BLAST := 200.0
const ESCORT_SPEED := 70.0
const ESCORT_LEASH := 260.0       # el proceso solo avanza si estás así de cerca
const ESCORT_BLOCK := 220.0       # y si no hay enemigos a esta distancia de él
const ESCORT_MIN_TRIP := 900.0
## Enemigos de la zona (los pone World): la escolta se para si hay alguno cerca.
var enemies: EnemyManager
const RADIUS := 46.0
const AMBUSH_RADIUS := 170.0
## Los datos huérfanos se abren solos al pasar a esta distancia (sin tener que tocarlos).
const CACHE_TRIGGER_RADIUS := 230.0
const SHRINES := {
	"turbo": {"name": "Santuario Turbo", "color": "6ad07a", "text": "Turbo: +30 % de velocidad de ataque, lanzamiento y movimiento (20 s)",
		"mods": [{"stat": "attack_speed", "type": "increased", "value": 30}, {"stat": "cast_speed", "type": "increased", "value": 30},
			{"stat": "movement_speed", "type": "increased", "value": 25}]},
	"firewall": {"name": "Santuario Firewall", "color": "e0a050", "text": "Firewall: 50 % más de armadura y +20 % a las resistencias (20 s)",
		"mods": [{"stat": "armour", "type": "more", "value": 50}, {"stat": "fire_res", "type": "flat", "value": 20},
			{"stat": "cold_res", "type": "flat", "value": 20}, {"stat": "lightning_res", "type": "flat", "value": 20}]},
	"debug": {"name": "Santuario Debug", "color": "ff6a5a", "text": "Modo debug: 40 % más de daño (20 s)",
		"mods": [{"stat": "damage", "type": "more", "value": 40}]},
	"overclock": {"name": "Santuario Overclock", "color": "6aa8ff", "text": "Overclock: todas tus cargas al máximo", "mods": []},
}
const SHRINE_SECONDS := 20.0
const NAMES := {"cache": "Datos huérfanos", "deploy": "Deploy fallido", "bombs": "Bombas lógicas", "escort": "Proceso perdido",
	"merchant": "Comerciante ambulante", "gc": "Garbage Collector", "blackout": "Apagón del CPD", "ticket": "Ticket urgente"}

var zone: Zone
## {kind, pos, state: "ready"|"active"|"done", shrine?, wave?, ids?}
var events: Array[Dictionary] = []
var _pending := -1
var _time := 0.0


## `plan` (T120, ZoneMechanics.plan): {"main": la mecánica principal, "minor": un evento
## menor}. Se pone la principal si es de las de ZoneEvents (marcada con "main": true) y
## el menor si lo hay; nada más, para no saturar la zona.
func setup(p_zone: Zone, rng: RandomNumberGenerator, plan := {}) -> void:
	zone = p_zone
	z_index = 0
	if zone.safe or not zone.def.get("enemies") is Dictionary or zone.def.has("boss"):
		return
	var wanted: Array[Dictionary] = []
	var main := String(plan.get("main", ""))
	if main != "" and String(ZoneMechanics.info(main).get("kind", "")) == "event" and KINDS.has(main):
		wanted.append({"kind": main, "main": true})
	if String(plan.get("minor", "")) != "" and KINDS.has(String(plan["minor"])):
		wanted.append({"kind": String(plan["minor"])})
	var keys := zone.key_points()
	for w in wanted.duplicate():   # las de toda la zona no necesitan sitio propio
		if ZONE_WIDE.has(String(w["kind"])):
			wanted.erase(w)
			events.append(_zone_wide(String(w["kind"]), rng, keys))
	var tries := 0
	while not wanted.is_empty() and tries < 300:
		tries += 1
		var p := Vector2(rng.randf_range(zone.rect.position.x + 300, zone.rect.end.x - 300), rng.randf_range(zone.rect.position.y + 260, zone.rect.end.y - 260))
		p = zone.free_spot_near(p, 50.0)
		if not zone.is_walkable(p, 50.0) or keys.any(func(k: Vector2) -> bool: return k.distance_to(p) < 520.0) \
				or events.any(func(e: Dictionary) -> bool: return Vector2(e["pos"]).distance_to(p) < 700.0):
			continue
		var w: Dictionary = wanted.pop_front()
		var kind := String(w["kind"])
		var e := {"kind": kind, "pos": p, "state": "ready"}
		if w.get("main", false):
			e["main"] = true
		if kind == "shrine":
			e["shrine"] = SHRINES.keys()[rng.randi_range(0, SHRINES.size() - 1)]
		elif kind == "escort":
			var goal := _escort_goal(p, rng)
			if goal == Vector2.INF:
				e["kind"] = "deploy" if e.get("main", false) else "cache"   # no cabe un viaje largo: otra cosa del mismo peso
			else:
				e["goal"] = goal
				e["start"] = p
				e["walker"] = p
				e["waves_done"] = 0
		events.append(e)


## Garbage Collector o apagón: activos desde que entras. El barrido va en el sentido
## largo de la zona; las luces de emergencia, repartidas y lejos de las entradas.
func _zone_wide(kind: String, rng: RandomNumberGenerator, keys: Array[Vector2]) -> Dictionary:
	var e := {"kind": kind, "pos": zone.free_spot_near(zone.rect.get_center(), 30.0), "state": "active", "main": true}
	if kind == "gc":
		e["across_x"] = zone.rect.size.x >= zone.rect.size.y   # la línea es vertical y avanza en x
		e["phase"] = "wait"
		e["timer"] = GC_INTERVAL * 0.6
		e["line"] = 0.0
		e["dir"] = 1.0
		e["sweeps"] = 0
		e["hit"] = {}
	elif kind == "merge":
		e["kills"] = 0
		e["tick"] = 0.0
		e["split"] = false   # las ramas se reparten al ver a los enemigos (World los saca después)
		e["sparks"] = []
	elif kind == "friday":
		var start := zone.entry_point("")
		var best := e["pos"] as Vector2
		for k in 40:   # el terminal del pipeline, lejos de la entrada
			var p := zone.free_spot_near(Vector2(rng.randf_range(zone.rect.position.x + 250, zone.rect.end.x - 250),
				rng.randf_range(zone.rect.position.y + 250, zone.rect.end.y - 250)), 40.0)
			if zone.is_walkable(p, 40.0) and p.distance_to(start) > best.distance_to(start):
				best = p
		e["pos"] = best
		e["timer"] = FRIDAY_INTERVAL * 0.5
		e["waves"] = 0
		e["progress"] = 0.0
	elif kind == "hot_cache":
		var tiles: Array = []
		for k in HOT_CACHE_TILES:
			tiles.append({"pos": _hot_spot(rng, keys, tiles), "cold": 0.0, "move": rng.randf_range(HOT_CACHE_MOVE * 0.6, HOT_CACHE_MOVE),
				"buff": HOT_CACHE_BUFFS.keys()[rng.randi_range(0, HOT_CACHE_BUFFS.size() - 1)]})
		e["tiles"] = tiles
		e["used"] = 0
	else:
		var lights: Array = []
		var tries := 0
		while lights.size() < BLACKOUT_LIGHTS and tries < 400:
			tries += 1
			var p := zone.free_spot_near(Vector2(rng.randf_range(zone.rect.position.x + 200, zone.rect.end.x - 200),
				rng.randf_range(zone.rect.position.y + 200, zone.rect.end.y - 200)), 30.0)
			if not zone.is_walkable(p, 30.0) or keys.any(func(k: Vector2) -> bool: return k.distance_to(p) < 260.0) \
					or lights.any(func(l: Dictionary) -> bool: return Vector2(l["pos"]).distance_to(p) < 650.0):
				continue
			lights.append({"pos": p, "lit": false})
		e["lights"] = lights
	return e


## Un destino caminable a buena distancia para el proceso escoltado (INF si no hay).
func _escort_goal(from: Vector2, rng: RandomNumberGenerator) -> Vector2:
	for k in 30:
		var q := Vector2(rng.randf_range(zone.rect.position.x + 200, zone.rect.end.x - 200), rng.randf_range(zone.rect.position.y + 200, zone.rect.end.y - 200))
		q = zone.free_spot_near(q, 40.0)
		if q.distance_to(from) >= ESCORT_MIN_TRIP and zone.is_walkable(q, 40.0):
			return q
	return Vector2.INF


func _process(delta: float) -> void:
	_time += delta
	if events.is_empty() or zone.player == null:
		return
	var pp := zone.player.global_position
	for i in events.size():
		var e := events[i]
		if e["kind"] == "ambush" and e["state"] == "ready" and pp.distance_to(e["pos"]) < AMBUSH_RADIUS:
			_fire(i)
		elif e["kind"] == "cache" and e["state"] == "ready" and pp.distance_to(e["pos"]) < CACHE_TRIGGER_RADIUS:
			if _pending == i:
				_pending = -1
			_fire(i)
		elif e["state"] == "active" and e["kind"] == "bombs":
			_update_bombs(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "escort":
			_update_escort(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "gc":
			_update_gc(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "blackout":
			_update_blackout(e, pp)
		elif e["state"] == "active" and e["kind"] == "ticket":
			_update_ticket(e, delta)
		elif e["state"] == "active" and e["kind"] == "merge":
			_update_merge(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "friday":
			_update_friday(e, pp, delta)
		elif e["state"] == "active" and e["kind"] == "hot_cache":
			_update_hot_cache(e, pp, delta)
	if _pending != -1:
		var e := events[_pending]
		if pp.distance_to(e["pos"]) <= RADIUS + 40.0:
			zone.player.stop_auto_move()
			_fire(_pending)
			_pending = -1
		elif not zone.player.has_auto_target():
			_pending = -1
	queue_redraw()


func _fire(i: int) -> void:
	var e := events[i]
	if e["state"] != "ready":
		return
	e["state"] = "done" if e["kind"] in ["shrine", "ambush"] else "active"
	if e["kind"] == "bombs":
		e["time_left"] = BOMB_TIME
		var bombs: Array = []
		for k in BOMB_COUNT:
			var q := zone.free_spot_near(Vector2(e["pos"]) + Vector2.from_angle(TAU * k / BOMB_COUNT + 0.4) * BOMB_SPREAD, 40.0)
			bombs.append({"pos": q, "progress": 0.0, "done": false})
		e["bombs"] = bombs
	elif e["kind"] == "ticket":
		e["time_left"] = TICKET_TIME   # World marca a los élites y deja sus ids en e["ids"]
	triggered.emit(e)


## Bombas lógicas: junto a una, se desactiva poco a poco; al acabar el tiempo, las que queden estallan.
func _update_bombs(e: Dictionary, pp: Vector2, delta: float) -> void:
	e["time_left"] = float(e["time_left"]) - delta
	var left := 0
	for b in e["bombs"]:
		if b["done"]:
			continue
		if pp.distance_to(b["pos"]) <= DEFUSE_RADIUS:
			b["progress"] = float(b["progress"]) + delta
			if b["progress"] >= DEFUSE_TIME:
				b["done"] = true
				continue
		left += 1
	if left == 0:
		e["state"] = "done"
		resolved.emit(e, true)
	elif e["time_left"] <= 0.0:
		for b in e["bombs"]:
			if not b["done"]:
				b["done"] = true
				exploded.emit(b["pos"])
		e["state"] = "done"
		resolved.emit(e, false)


## Coordenada de `p` a lo largo del barrido del GC.
static func gc_coord(e: Dictionary, p: Vector2) -> float:
	return p.x if e["across_x"] else p.y


## Garbage Collector: espera, aviso (la línea parpadea en el borde de salida) y barrido
## de lado a lado, que golpea una vez a cada uno (jugador y enemigos) que pille.
func _update_gc(e: Dictionary, pp: Vector2, delta: float) -> void:
	var lo := zone.rect.position.x if e["across_x"] else zone.rect.position.y
	var hi := zone.rect.end.x if e["across_x"] else zone.rect.end.y
	match String(e["phase"]):
		"wait":
			e["timer"] = float(e["timer"]) - delta
			if e["timer"] <= 0.0:
				e["phase"] = "warn"
				e["timer"] = GC_WARNING
				e["line"] = lo if e["dir"] > 0.0 else hi
				gc_warning.emit(e)
		"warn":
			e["timer"] = float(e["timer"]) - delta
			if e["timer"] <= 0.0:
				e["phase"] = "sweep"
				e["hit"] = {}
		"sweep":
			e["line"] = float(e["line"]) + float(e["dir"]) * GC_SPEED * delta
			var line := float(e["line"])
			var hit: Dictionary = e["hit"]
			if zone.player and not hit.has("player") and absf(gc_coord(e, pp) - line) < GC_BAND:
				hit["player"] = true
				zone.player.take_damage(zone.player.max_life() * GC_PLAYER_DAMAGE)   # la esquiva lo evita
			if enemies:
				for i in range(enemies.positions.size() - 1, -1, -1):
					if enemies.rarities[i] == Rarity.Enemy.UNIQUE or hit.has(enemies.ids[i]):
						continue
					if absf(gc_coord(e, enemies.positions[i]) - line) < GC_BAND + enemies.radii[i]:
						hit[enemies.ids[i]] = true
						var dmg := enemies.max_lives[i] * GC_ENEMY_DAMAGE
						enemies._damage(i, dmg, dmg, 0.0, 100.0)
			if (e["dir"] > 0.0 and line > hi) or (e["dir"] < 0.0 and line < lo):
				e["sweeps"] = int(e["sweeps"]) + 1
				e["dir"] = -float(e["dir"])   # el siguiente vuelve por donde vino
				if int(e["sweeps"]) >= GC_SWEEPS:
					e["state"] = "done"
					resolved.emit(e, true)
				else:
					e["phase"] = "wait"
					e["timer"] = GC_INTERVAL


## Apagón: cada luz de emergencia se enciende al pasar a su lado.
func _update_blackout(e: Dictionary, pp: Vector2) -> void:
	var lights: Array = e["lights"]
	var changed := false
	var lit := 0
	for l in lights:
		if not l["lit"] and pp.distance_to(l["pos"]) < LIGHT_RADIUS:
			l["lit"] = true
			changed = true
		if l["lit"]:
			lit += 1
	if not changed:
		return
	var frac := float(lit) / maxf(1.0, lights.size())
	blackout_changed.emit(e, frac)
	if lit == lights.size():
		e["state"] = "done"
		resolved.emit(e, true)


## Ticket urgente: los élites marcados (e["ids"], los pone World) antes de que acabe el tiempo.
func _update_ticket(e: Dictionary, delta: float) -> void:
	e["time_left"] = float(e["time_left"]) - delta
	if not e.has("ids"):
		return
	var alive: Array = (e["ids"] as Array).filter(func(id: int) -> bool: return enemies != null and enemies.index_of(id) != -1)
	if alive.is_empty():
		e["state"] = "done"
		resolved.emit(e, true)
	elif e["time_left"] <= 0.0:
		e["state"] = "done"
		resolved.emit(e, false)


## Rama de un enemigo en el merge conflict (-1 = ninguna: únicos y jefes no se meten).
static func branch_of(em: EnemyManager, i: int) -> int:
	return int((em.traits[i] as Dictionary).get("branch", -1))


## Merge conflict: reparte las ramas la primera vez (por tipo, y si la zona tiene uno
## solo, alternando) y, cada MERGE_TICK, los de ramas distintas que estén cerca y no
## anden detrás de ti se acercan y se pegan.
func _update_merge(e: Dictionary, pp: Vector2, delta: float) -> void:
	if enemies == null:
		return
	for s in e["sparks"]:
		s["t"] = float(s["t"]) + delta
	var sparks: Array = (e["sparks"] as Array).filter(func(s: Dictionary) -> bool: return float(s["t"]) < 0.5)
	e["sparks"] = sparks   # el mismo arreglo: lo que se añada abajo se dibuja
	if not e["split"]:
		if enemies.positions.is_empty():
			return
		e["split"] = true
		var by_type := {}
		for i in enemies.positions.size():
			by_type[enemies.types[i]] = true
		var two_types := by_type.size() >= 2
		var type_list := by_type.keys()
		for i in enemies.positions.size():
			if enemies.rarities[i] != Rarity.Enemy.UNIQUE:
				enemies.traits[i]["branch"] = (type_list.find(enemies.types[i]) % 2) if two_types else (i % 2)
	e["tick"] = float(e["tick"]) - delta
	if e["tick"] > 0.0:
		return
	e["tick"] = MERGE_TICK
	var kills := 0
	var hit_ids: Array = []
	for i in enemies.positions.size():
		var bi := branch_of(enemies, i)
		if bi < 0 or enemies.positions[i].distance_to(pp) < MERGE_IGNORE_PLAYER:
			continue
		var best := -1
		var best_d := MERGE_PULL
		for j in enemies.positions.size():
			var bj := branch_of(enemies, j)
			if bj < 0 or bj == bi:
				continue
			var d := enemies.positions[i].distance_to(enemies.positions[j])
			if d < best_d:
				best_d = d
				best = j
		if best == -1:
			continue
		if best_d > MERGE_REACH + enemies.radii[i] + enemies.radii[best]:
			enemies.positions[i] = enemies.positions[i].move_toward(enemies.positions[best], 40.0)   # se buscan
		else:
			hit_ids.append(enemies.ids[i])
			if sparks.size() < 14:
				sparks.append({"pos": enemies.positions[i].lerp(enemies.positions[best], 0.5), "t": 0.0})
	for id in hit_ids:
		var i := enemies.index_of(id)
		if i == -1:
			continue
		var dmg := enemies.max_lives[i] * MERGE_DAMAGE
		enemies._damage(i, dmg, dmg, 0.0, 100.0)
		if enemies.index_of(id) == -1:
			kills += 1
	if kills > 0:
		e["kills"] = int(e["kills"]) + kills
		if int(e["kills"]) >= MERGE_KILLS:
			e["state"] = "done"
			resolved.emit(e, true)


## Deploy de viernes: una oleada por una salida cada FRIDAY_INTERVAL (como mucho
## FRIDAY_MAX_WAVES); quedarse FRIDAY_HOLD s en el terminal cierra el pipeline.
func _update_friday(e: Dictionary, pp: Vector2, delta: float) -> void:
	if pp.distance_to(e["pos"]) <= FRIDAY_RADIUS:
		e["progress"] = float(e["progress"]) + delta
		if e["progress"] >= FRIDAY_HOLD:
			e["state"] = "done"
			resolved.emit(e, true)
			return
	else:
		e["progress"] = maxf(0.0, float(e["progress"]) - delta * 0.5)
	if int(e["waves"]) >= FRIDAY_MAX_WAVES:
		return
	e["timer"] = float(e["timer"]) - delta
	if e["timer"] <= 0.0:
		e["timer"] = FRIDAY_INTERVAL
		e["waves"] = int(e["waves"]) + 1
		var exits := zone.exits.filter(func(x: Dictionary) -> bool: return zone.exit_visible(x))
		var at: Vector2 = exits[randi() % exits.size()]["pos"] if not exits.is_empty() else zone.entry_point("")
		friday_wave.emit(e, zone.free_spot_near(at.lerp(zone.rect.get_center(), 0.08), 40.0))


## Caché caliente: pisar una baldosa da su bono, la enfría HOT_CACHE_COOLDOWN s y la cambia
## de sitio; las que nadie pisa también se mueven de vez en cuando.
func _update_hot_cache(e: Dictionary, pp: Vector2, delta: float) -> void:
	for t in e["tiles"]:
		if float(t["cold"]) > 0.0:
			t["cold"] = float(t["cold"]) - delta
			if t["cold"] <= 0.0:
				t["pos"] = _hot_spot(null, zone.key_points(), e["tiles"])
			continue
		t["move"] = float(t["move"]) - delta
		if t["move"] <= 0.0:
			t["move"] = HOT_CACHE_MOVE
			t["pos"] = _hot_spot(null, zone.key_points(), e["tiles"])
		elif pp.distance_to(t["pos"]) < HOT_CACHE_RADIUS:
			t["cold"] = HOT_CACHE_COOLDOWN
			e["used"] = int(e["used"]) + 1
			hot_cache_hit.emit(e, String(t["buff"]))
			t["buff"] = HOT_CACHE_BUFFS.keys().pick_random()
			if int(e["used"]) >= HOT_CACHE_USES:
				e["state"] = "done"
				resolved.emit(e, true)
				return


## Un sitio para una baldosa de caché: suelo, lejos de los puntos clave y de las otras.
func _hot_spot(rng: RandomNumberGenerator, keys: Array[Vector2], tiles: Array) -> Vector2:
	var best := zone.free_spot_near(zone.rect.get_center(), 40.0)
	for k in 60:
		var x := rng.randf_range(zone.rect.position.x + 200, zone.rect.end.x - 200) if rng else randf_range(zone.rect.position.x + 200, zone.rect.end.x - 200)
		var y := rng.randf_range(zone.rect.position.y + 200, zone.rect.end.y - 200) if rng else randf_range(zone.rect.position.y + 200, zone.rect.end.y - 200)
		var p := zone.free_spot_near(Vector2(x, y), 40.0)
		if not zone.is_walkable(p, 40.0) or keys.any(func(q: Vector2) -> bool: return q.distance_to(p) < 260.0) \
				or tiles.any(func(t: Dictionary) -> bool: return Vector2(t["pos"]).distance_to(p) < 500.0):
			continue
		return p
	return best


## Puntos de luz de las mecánicas (para Zone.light_points): las luces de emergencia del
## apagón, encendidas o con su pilotito rojo.
func light_points() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if e["kind"] == "blackout":
			for l in e["lights"]:
				if l["lit"]:
					out.append({"pos": l["pos"] + Vector2(0, -40), "radius": 340.0, "color": Color("e8f0ff"), "power": 0.95})
				elif e["state"] == "active":
					out.append({"pos": l["pos"] + Vector2(0, -40), "radius": 70.0, "color": Color("ff3030"), "power": 0.5})
	return out


## Escolta: avanza hacia su salida si estás cerca y no hay enemigos a su lado.
func _update_escort(e: Dictionary, pp: Vector2, delta: float) -> void:
	var w: Vector2 = e["walker"]
	var blocked := enemies != null and enemies.nearest_index(w, ESCORT_BLOCK) != -1
	e["blocked"] = blocked
	if blocked or pp.distance_to(w) > ESCORT_LEASH:
		return
	w = w.move_toward(e["goal"], ESCORT_SPEED * delta)
	e["walker"] = w
	var trip: float = Vector2(e["start"]).distance_to(e["goal"])
	var done_frac := 1.0 - w.distance_to(e["goal"]) / maxf(1.0, trip)
	if int(e["waves_done"]) < 2 and done_frac >= (int(e["waves_done"]) + 1) / 3.0:
		e["waves_done"] = int(e["waves_done"]) + 1
		escort_wave.emit(e)
	if w.distance_to(e["goal"]) < 4.0:
		e["state"] = "done"
		resolved.emit(e, true)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var i := _at(get_global_mouse_position())
	if i != -1:
		_pending = i
		zone.player.move_to(events[i]["pos"] + Vector2(0, 30))
		get_viewport().set_input_as_handled()


## Mando (A): el evento más cercano a `pos`, si lo hay.
func interact_near(pos: Vector2, radius: float) -> bool:
	for i in events.size():
		if events[i]["kind"] != "ambush" and events[i]["state"] == "ready" and pos.distance_to(events[i]["pos"]) < radius:
			_pending = i
			zone.player.move_to(events[i]["pos"] + Vector2(0, 30))
			return true
	return false


func _at(pos: Vector2) -> int:
	for i in events.size():
		if events[i]["kind"] != "ambush" and events[i]["state"] == "ready" and pos.distance_to(events[i]["pos"]) < RADIUS:
			return i
	return -1


# --- Dibujo (con el decorado: en pixel art) ---

func _draw() -> void:
	for e in events:
		match e["kind"]:
			"cache":
				_draw_cache(e)
			"shrine":
				_draw_shrine(e)
			"deploy":
				_draw_deploy(e)
			"bombs":
				_draw_bombs(e)
			"escort":
				_draw_escort(e)
			"merchant":
				_draw_merchant(e)
			"gc":
				_draw_gc(e)
			"blackout":
				_draw_blackout(e)
			"ticket":
				_draw_ticket(e)
			"merge":
				_draw_merge(e)
			"friday":
				_draw_friday(e)
			"hot_cache":
				_draw_hot_cache(e)


func _shadow(p: Vector2, w: float) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)


## Cofre de datos huérfanos: un disco duro viejo con candado y LEDs.
func _draw_cache(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 18), 34.0)
	if ready:
		draw_circle(p, 44.0, Color(1.0, 0.8, 0.3, 0.06 + 0.04 * sin(_time * 3.0)))
		# Aro de activación: al cruzarlo se abre (trazos que giran despacio).
		for k in 24:
			var a := TAU * k / 24.0 + _time * 0.3
			draw_arc(p, CACHE_TRIGGER_RADIUS, a, a + TAU / 48.0, 3, Color(1.0, 0.8, 0.3, 0.28), 2.0)
	var box := Rect2(p - Vector2(30, 18), Vector2(60, 34))
	draw_rect(box, Color("4a4350"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 4)), Color("6a6372"))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 4), Vector2(box.size.x, 4)), Color("2e2a34"))
	for k in 4:
		draw_rect(Rect2(box.position + Vector2(6 + k * 7, 10), Vector2(4, 3)), Color("40ff70") if ready and int(_time * 4.0 + k) % 3 else Color("1a3020"))
	if e["state"] == "done":
		draw_rect(Rect2(box.position + Vector2(4, -10), Vector2(52, 10)), Color("3a3440"))   # tapa abierta
	else:
		draw_rect(Rect2(p + Vector2(10, -6), Vector2(12, 10)), Color("d9a441"))
		draw_arc(p + Vector2(16, -6), 5.0, PI, TAU, 8, Color("d9a441"), 2.0)
	if ready:
		zone._label(p + Vector2(-90, -34), NAMES["cache"], 180, 13, Color("f2c14e"))


## Santuario: obelisco con runa que gira, del color de su bono.
func _draw_shrine(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var info: Dictionary = SHRINES[e["shrine"]]
	var col := Color(info["color"])
	var ready: bool = e["state"] == "ready"
	if not ready:
		col = col.darkened(0.7)
	_shadow(p + Vector2(0, 16), 28.0)
	if ready:
		draw_circle(p + Vector2(0, -20), 50.0, Color(col, 0.08 + 0.05 * sin(_time * 2.5)))
	draw_rect(Rect2(p + Vector2(-20, 6), Vector2(40, 10)), Color("3a3640"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 6), p + Vector2(12, 6), p + Vector2(7, -52), p + Vector2(-7, -52)]), Color("4a4652"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -52), p + Vector2(7, -52), p + Vector2(0, -62)]), Color("5a5662"))
	var rune := p + Vector2(0, -26)
	draw_rect(Rect2(rune - Vector2(5, 5), Vector2(10, 10)), col)
	if ready:
		for k in 4:
			var a := _time * 1.5 + k * TAU / 4.0
			var q := rune + Vector2.from_angle(a) * 20.0
			draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(col, 0.8))
		zone._label(p + Vector2(-100, -76), info["name"], 200, 13, col.lightened(0.3))


## Deploy fallido: consola con la pantalla en rojo.
func _draw_deploy(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 16), 30.0)
	draw_rect(Rect2(p + Vector2(-26, -6), Vector2(52, 20)), Color("2e2a34"))
	var screen := Rect2(p + Vector2(-22, -46), Vector2(44, 34))
	draw_rect(screen.grow(3), Color("3a3640"))
	var blink := 0.6 + 0.4 * sin(_time * 6.0) if ready else 0.2
	draw_rect(screen, Color(0.5 * blink, 0.05, 0.05))
	for k in 4:
		draw_rect(Rect2(screen.position + Vector2(4, 5 + k * 7), Vector2(14 + (k * 9) % 22, 3)), Color(1, 0.5, 0.45, blink))
	if ready:
		zone._label(p + Vector2(-90, -58), NAMES["deploy"], 180, 13, Color("ff6a5a"))


## Garbage Collector: en el aviso, una línea discontinua que parpadea en el borde de
## salida con «GC»; en el barrido, una franja turquesa con su núcleo brillante y
## `free()` que se desprenden.
func _draw_gc(e: Dictionary) -> void:
	if e["state"] != "active" or e["phase"] == "wait":
		return
	var r := zone.rect
	var line := float(e["line"])
	var a := Vector2(line, r.position.y) if e["across_x"] else Vector2(r.position.x, line)
	var b := Vector2(line, r.end.y) if e["across_x"] else Vector2(r.end.x, line)
	var along := (b - a).normalized()
	var side := along.orthogonal()
	if e["phase"] == "warn":
		var blink := 0.35 + 0.35 * absf(sin(_time * 10.0))
		var d := 0.0
		var length := a.distance_to(b)
		while d < length:
			draw_line(a + along * d, a + along * minf(d + 40.0, length), Color(GC_COLOR, blink), 4.0)
			d += 70.0
		var at := a.lerp(b, 0.5) + side * float(e["dir"]) * 60.0
		for k in 3:   # flechas hacia donde va a barrer
			var tip := at + side * float(e["dir"]) * (k * 26.0)
			draw_polyline(PackedVector2Array([tip - along * 18.0 - side * float(e["dir"]) * 14.0, tip, tip + along * 18.0 - side * float(e["dir"]) * 14.0]), Color(GC_COLOR, blink), 3.0)
		zone._label(at + Vector2(-60, -30), "GC en %.1f s" % float(e["timer"]), 120, 14, GC_COLOR)
		return
	var band := PackedVector2Array([a - side * GC_BAND, b - side * GC_BAND, b + side * GC_BAND, a + side * GC_BAND])
	draw_colored_polygon(band, Color(GC_COLOR, 0.22))
	draw_line(a, b, Color(GC_COLOR, 0.9), 6.0)
	draw_line(a, b, Color(1, 1, 1, 0.8), 2.0)
	var font := ThemeDB.fallback_font
	for k in 8:
		var q := a.lerp(b, fposmod(k / 8.0 + _time * 0.07, 1.0)) - side * float(e["dir"]) * (20.0 + 30.0 * fposmod(_time * 1.7 + k * 0.37, 1.0))
		draw_string(font, q, "free()", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(GC_COLOR, 0.7))


## Apagón: las farolas de emergencia, apagadas con su piloto rojo que parpadea o encendidas.
func _draw_blackout(e: Dictionary) -> void:
	for l in e["lights"]:
		var p: Vector2 = l["pos"]
		_shadow(p + Vector2(0, 6), 14.0)
		draw_rect(Rect2(p + Vector2(-3, -44), Vector2(6, 46)), Color("3a3e48"))
		var head := Rect2(p + Vector2(-12, -58), Vector2(24, 14))
		draw_rect(head, Color("2a2e36"))
		if l["lit"]:
			draw_rect(head.grow(-3), Color("eaf2ff"))
			draw_circle(p + Vector2(0, -40), 26.0, Color(0.9, 0.95, 1.0, 0.12))
		else:
			var on := sin(_time * 4.0 + p.x) > 0.0
			draw_rect(head.grow(-3), Color("ff3030") if on else Color("401010"))
			if e["state"] == "active" and zone.player and zone.player.global_position.distance_to(p) < 600.0:
				zone._label(p + Vector2(-60, -76), "Luz de emergencia", 120, 12, Color("ff8080"))


## Ticket urgente: la consola con el ticket y, activo, la etiqueta sobre cada élite marcado.
func _draw_ticket(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 16), 30.0)
	draw_rect(Rect2(p + Vector2(-26, -6), Vector2(52, 20)), Color("2e2a34"))
	var screen := Rect2(p + Vector2(-22, -46), Vector2(44, 34))
	draw_rect(screen.grow(3), Color("3a3640"))
	draw_rect(screen, Color("1a2a4a"))
	draw_rect(Rect2(screen.position + Vector2(4, 4), Vector2(36, 8)), Color("e05050") if ready else Color("406080"))
	for k in 2:
		draw_rect(Rect2(screen.position + Vector2(4, 16 + k * 7), Vector2(30 - k * 10, 3)), Color("9ab8e0"))
	if ready:
		zone._label(p + Vector2(-90, -58), "Ticket urgente (P1)", 180, 13, Color("ff9a5a"))
	elif e["state"] == "active" and enemies and e.has("ids"):
		var left := ZoneInstances.clock(float(e["time_left"]))
		for id in e["ids"]:
			var i := enemies.index_of(int(id))
			if i == -1:
				continue
			var q := enemies.positions[i] + Vector2(0, -enemies.radii[i] - 46.0)
			draw_rect(Rect2(q + Vector2(-34, -10), Vector2(68, 18)), Color(0.1, 0.1, 0.15, 0.85))
			draw_rect(Rect2(q + Vector2(-34, -10), Vector2(68, 18)), Color("ff9a5a"), false, 1.5)
			zone._label(q + Vector2(-34, -8), "P1 · " + left, 68, 11, Color("ffd0a0"))


## Merge conflict: un aro del color de su rama bajo cada enemigo a la vista y, donde
## chocan, marcas de conflicto («<<<<<<<», «=======», «>>>>>>>») que saltan.
func _draw_merge(e: Dictionary) -> void:
	if e["state"] != "active" or enemies == null:
		return
	var view := zone._camera_rect().grow(80.0)
	for i in enemies.positions.size():
		var b := branch_of(enemies, i)
		if b < 0 or not view.has_point(enemies.positions[i]):
			continue
		var p := enemies.positions[i] + Vector2(0, enemies.radii[i] * 0.7)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, enemies.radii[i] + 6.0, 0.0, TAU, 20, Color(MERGE_COLORS[b], 0.8), 3.0)
		draw_set_transform(Vector2.ZERO)
	var font := ThemeDB.fallback_font
	var marks := ["<<<<<<<", "=======", ">>>>>>>"]
	for k in (e["sparks"] as Array).size():
		var s: Dictionary = e["sparks"][k]
		var t := float(s["t"]) / 0.5
		draw_string(font, Vector2(s["pos"]) + Vector2(-26, -20 - 30.0 * t), marks[k % 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.7, 0.3, 1.0 - t))
	if zone.player:
		zone._label(zone.player.global_position + Vector2(-110, -110), "Merge conflict: %d / %d bajas entre ramas" % [int(e["kills"]), MERGE_KILLS], 220, 12, Color("ffb070"))


## Deploy de viernes: el terminal del pipeline con su aro de cierre, y cuánto falta para
## el siguiente deploy.
func _draw_friday(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var active: bool = e["state"] == "active"
	_shadow(p + Vector2(0, 16), 32.0)
	draw_rect(Rect2(p + Vector2(-28, -6), Vector2(56, 20)), Color("2e2a34"))
	var screen := Rect2(p + Vector2(-24, -50), Vector2(48, 38))
	draw_rect(screen.grow(3), Color("3a3640"))
	draw_rect(screen, Color("2a1010") if active else Color("102a14"))
	for k in 3:   # el pipeline: tres etapas, la última en rojo mientras siga abierto
		var c := Color("6ad07a") if k < 2 or not active else (Color("ff4a3a") if sin(_time * 6.0) > 0.0 else Color("601818"))
		draw_rect(Rect2(screen.position + Vector2(5 + k * 14, 14), Vector2(10, 10)), c)
	if not active:
		return
	draw_arc(p, FRIDAY_RADIUS, 0.0, TAU, 32, Color(1.0, 0.6, 0.3, 0.35), 2.0)
	var frac := float(e["progress"]) / FRIDAY_HOLD
	if frac > 0.0:
		draw_arc(p, FRIDAY_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, Color("ffd24a"), 5.0)
	var next := "" if int(e["waves"]) >= FRIDAY_MAX_WAVES else "  ·  próximo deploy en %d s" % ceili(float(e["timer"]))
	zone._label(p + Vector2(-130, -70), "Cerrar el pipeline" + next, 260, 13, Color("ff9a5a"))


## Caché caliente: baldosas que brillan con el color de su bono; frías, apagadas.
func _draw_hot_cache(e: Dictionary) -> void:
	if e["state"] != "active":
		return
	var view := zone._camera_rect().grow(120.0)
	for t in e["tiles"]:
		var p: Vector2 = t["pos"]
		if not view.has_point(p):
			continue
		var info: Dictionary = HOT_CACHE_BUFFS[t["buff"]]
		var cold := float(t["cold"]) > 0.0
		var col := Color(info["color"])
		var r := Rect2(p - Vector2(HOT_CACHE_RADIUS, HOT_CACHE_RADIUS * 0.55), Vector2(HOT_CACHE_RADIUS * 2.0, HOT_CACHE_RADIUS * 1.1))
		if cold:
			draw_rect(r, Color(0.2, 0.25, 0.35, 0.35))
			draw_rect(r, Color(0.5, 0.6, 0.8, 0.4), false, 2.0)
			continue
		var pulse := 0.55 + 0.25 * sin(_time * 4.0 + p.x)
		draw_rect(r, Color(col, 0.25 * pulse))
		draw_rect(r, Color(col, 0.9), false, 3.0)
		for k in 4:   # rejilla de «líneas de caché»
			var x := r.position.x + r.size.x * (k + 1) / 5.0
			draw_line(Vector2(x, r.position.y + 4), Vector2(x, r.end.y - 4), Color(col, 0.35 * pulse), 1.0)
		zone._label(p + Vector2(-70, -HOT_CACHE_RADIUS * 0.55 - 20), info["name"], 140, 12, col)
	if zone.player:
		zone._label(zone.player.global_position + Vector2(-90, -110), "Caché caliente: %d / %d" % [int(e["used"]), HOT_CACHE_USES], 180, 12, Color("ffd080"))


## Bombas lógicas: la consola y, activa, las tres bombas con su aro de desactivación y la cuenta atrás.
func _draw_bombs(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 16), 28.0)
	draw_rect(Rect2(p + Vector2(-20, -30), Vector2(40, 44)), Color("2e2a34"))
	draw_rect(Rect2(p + Vector2(-15, -25), Vector2(30, 18)), Color("401010") if ready else Color("1a1a1e"))
	if ready:
		zone._label(p + Vector2(-90, -48), NAMES["bombs"], 180, 13, Color("ff9a3a"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-13, -11), "BOOM?", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.6, 0.3, 0.6 + 0.4 * sin(_time * 6.0)))
		return
	if e["state"] != "active":
		return
	var t: float = e["time_left"]
	zone._label(p + Vector2(-90, -48), "%d s" % ceili(maxf(0.0, t)), 180, 16, Color("ff5a3a") if t < 8.0 else Color("ffd060"))
	for b in e["bombs"]:
		if b["done"]:
			continue
		var q: Vector2 = b["pos"]
		_shadow(q + Vector2(0, 10), 16.0)
		draw_circle(q, 12.0, Color("1a1a1e"))
		draw_line(q + Vector2(6, -10), q + Vector2(12, -18), Color("c8a050"), 2.0)
		var spark := fmod(_time * 8.0, 1.0) < 0.5
		draw_circle(q + Vector2(12, -18), 3.0, Color("ffd060") if spark else Color("ff6a2a"))
		draw_arc(q, DEFUSE_RADIUS, 0.0, TAU, 32, Color(1, 0.6, 0.2, 0.35), 2.0, true)
		var prog := float(b["progress"]) / DEFUSE_TIME
		if prog > 0.0:
			draw_arc(q, DEFUSE_RADIUS - 6.0, -PI / 2.0, -PI / 2.0 + TAU * prog, 32, Color("6fd36b"), 4.0, true)


## Proceso perdido: un fantasmita con su PID que camina hacia su salida (bandera).
func _draw_escort(e: Dictionary) -> void:
	var w: Vector2 = e["walker"]
	var ready: bool = e["state"] == "ready"
	if e["state"] == "active":
		var goal: Vector2 = e["goal"]
		for k in 12:   # camino de puntos hasta la salida
			draw_circle(w.lerp(goal, k / 12.0), 2.0, Color(0.6, 0.9, 1.0, 0.25))
		draw_line(goal, goal + Vector2(0, -40), Color("8a8a96"), 2.0)
		draw_colored_polygon(PackedVector2Array([goal + Vector2(0, -40), goal + Vector2(22, -33), goal + Vector2(0, -26)]), Color("6fd36b"))
		zone._label(goal + Vector2(-60, -60), "Salida", 120, 12, Color("6fd36b"))
	if e["state"] == "done":
		return
	var bob := sin(_time * 4.0) * 2.0
	_shadow(w + Vector2(0, 14), 14.0)
	draw_circle(w + Vector2(0, -6 + bob), 12.0, Color(0.75, 0.9, 1.0, 0.85))
	draw_rect(Rect2(w + Vector2(-12, -6 + bob), Vector2(24, 12)), Color(0.75, 0.9, 1.0, 0.85))
	draw_circle(w + Vector2(-4, -8 + bob), 2.0, Color("1a2030"))
	draw_circle(w + Vector2(4, -8 + bob), 2.0, Color("1a2030"))
	var tag := "PID %d" % (int(Vector2(e["start"]).x) % 9000 + 1000)
	if ready:
		zone._label(w + Vector2(-90, -40), NAMES["escort"], 180, 13, Color("8ad8ff"))
	elif e.get("blocked", false):
		zone._label(w + Vector2(-90, -40), "¡Enemigos cerca!", 180, 12, Color("ff6a5a"))
	else:
		zone._label(w + Vector2(-90, -40), tag, 180, 11, Color("8ad8ff"))


## Comerciante ambulante: un carrito con toldo y un cofre misterioso.
func _draw_merchant(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	var ready: bool = e["state"] == "ready"
	_shadow(p + Vector2(0, 18), 36.0)
	draw_rect(Rect2(p + Vector2(-30, -10), Vector2(60, 24)), Color("6a4a30"))
	for s in [-1.0, 1.0]:
		draw_circle(p + Vector2(s * 20, 16), 7.0, Color("3a2a1e"))
	for k in 5:   # toldo de rayas
		draw_rect(Rect2(p + Vector2(-32 + k * 13, -34), Vector2(13, 10)), Color("c84b4b") if k % 2 == 0 else Color("e8e0d0"))
	draw_line(p + Vector2(-30, -24), p + Vector2(-30, -10), Color("4a3a2a"), 2.0)
	draw_line(p + Vector2(30, -24), p + Vector2(30, -10), Color("4a3a2a"), 2.0)
	if ready:
		draw_rect(Rect2(p + Vector2(-8, -20), Vector2(16, 10)), Color("d9a441"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-3, -11), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("2a1a0a"))
		zone._label(p + Vector2(-100, -52), "%s: %d fichas" % [NAMES["merchant"], merchant_price(e)], 200, 13, Color("f2c14e"))


## Precio del objeto misterioso del comerciante ambulante (sube con el nivel de la zona).
func merchant_price(_e: Dictionary) -> int:
	return 25 + int(zone.def.get("level", 1)) * 3
