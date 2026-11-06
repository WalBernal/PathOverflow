class_name SkillPreview
extends SubViewportContainer
## Vista previa animada de una habilidad (T211): en el tooltip de una placa base
## (bolsa, barra de habilidades, alijo y tienda) un escenario pequeño donde tu
## personaje la lanza en bucle contra tres servidores de prueba.
## Lo que se ve es el dibujo de SkillController (anillos, conos, rayos, proyectiles
## con su firma, giros, charcos, terrenos, trampas, torretas, esbirros, drones,
## invocaciones y auras) y las partículas de ImpactFx, en un SubViewport propio.
## La simulación es de juguete: sin EnemyManager ni daño, solo mueve lo que
## SkillController dibuja (sus listas de efectos) y hace parpadear al servidor que
## recibe el golpe. Corre aunque el juego esté en pausa y solo mientras se ve.

## Tamaño en la interfaz (el ancho del texto del tooltip) y zoom de la cámara:
## caben ~580 × 225 px del mundo, lo justo para una habilidad de alcance medio.
const SIZE := Vector2(360, 140)
const ZOOM := 0.62
## Servidores de prueba (el centro del cuerpo) y de dónde sale el personaje.
const DUMMIES: Array[Vector2] = [Vector2(170, 4), Vector2(236, -52), Vector2(240, 54)]
const DUMMY_RADIUS := 16.0
const START := Vector2(-250, 6)
## Una vuelta: muy corta para los golpes al instante, corta para proyectiles y rayos,
## larga para lo que se queda en el suelo o te acompaña.
const QUICK_CYCLE := 1.1
const SHORT_CYCLE := 1.7
const LONG_CYCLE := 3.4
const QUICK_KINDS := ["melee_area", "nova", "cone", "chain", "dash", "blink", "ssh", "charge", "leap_slam",
	"barrier", "buff", "curse_area", "backflip"]
const LONG_KINDS := ["unit", "aura", "drones", "minion", "degen_area", "terrain", "trap", "spin",
	"channel_beam", "channel_storm", "rain", "curse_area", "canary", "breakpoint"]
## Las que golpean alrededor del personaje: empieza cerca de los servidores.
const CLOSE_KINDS := ["melee_area", "nova", "cone", "spin", "barrier", "buff", "aura", "backflip"]
## Las que lo mueven: empieza a su alcance para que llegue.
const MOVE_KINDS := ["leap_slam", "dash", "charge", "blink", "ssh"]
## Lo más lejos que vuela un proyectil (que no se pierda fuera de la vista).
const MAX_REACH := 620.0
## Un mismo servidor no parpadea más de una vez cada tanto (que no sature de partículas).
const HIT_GAP := 0.12
const FLOOR := Color("1b2029")
const FLOOR_LINE := Color("232a35")

var _view: SubViewport
var _stage: Node2D
var _sc: SkillController
var _fx: ImpactFx
## SkillController dibuja giros, drones, auras y canalizadas alrededor de su jugador:
## uno sin dibujo ni proceso que solo marca dónde está el personaje.
var _player: Player
var _hero: HeroSprite
var _p := {}
var _key := ""
var _t := 0.0
var _cycle := SHORT_CYCLE
var _anim := 0.0
var _action := "cast"
var _action_t := 99.0
var _action_len := 0.35
var _weapon := ""
## Lo programado para más tarde: [{time, call}] (explosiones retardadas, rayos, lluvia).
var _later: Array[Dictionary] = []
var _flash: Array[float] = [0.0, 0.0, 0.0]
var _hit_cd: Array[float] = [0.0, 0.0, 0.0]
## Golpes a los servidores en esta vuelta (lo miran las pruebas).
var hits := 0


func _init() -> void:
	custom_minimum_size = SIZE
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_mode = Node.PROCESS_MODE_ALWAYS   # los menús pausan el juego; la vista previa sigue
	_view = SubViewport.new()
	_view.size = Vector2i(SIZE)
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_view)
	_stage = Node2D.new()
	_stage.draw.connect(_draw_stage)
	_view.add_child(_stage)
	_player = Player.new()
	_player.visible = false
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_player.position = START
	_view.add_child(_player)
	_sc = SkillController.new()
	_sc.process_mode = Node.PROCESS_MODE_DISABLED   # sin EnemyManager: lo mueve este
	_sc.player = _player
	_view.add_child(_sc)
	_fx = ImpactFx.new()
	_view.add_child(_fx)
	var cam := Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	_view.add_child(cam)


## Empieza (o sigue, si es la misma) la vista previa del perfil `p` de SkillCalc.
## Con `character`, el personaje es tu alumno con su equipo.
func play(p: Dictionary, character: CharacterData = null) -> void:
	var key := "%s|%d" % [String(p.get("id", "")), p.hash()]
	if key == _key and not _p.is_empty():
		return
	_key = key
	_p = p
	_weapon = CharacterAppearance.weapon_kind(character.inventory.equipped("weapon")) if character else ""
	_setup_hero(character)
	_restart()


func stop() -> void:
	_p = {}
	_key = ""
	_clear()


func playing() -> bool:
	return not _p.is_empty()


## Segundos de una vuelta del bucle.
static func cycle_seconds(p: Dictionary) -> float:
	if String(p.get("kind", "")) in LONG_KINDS or String(p.get("deploy", "")) != "":
		return LONG_CYCLE
	return QUICK_CYCLE if String(p.get("kind", "")) in QUICK_KINDS else SHORT_CYCLE


## Dónde empieza el personaje: lejos para proyectiles y hechizos, a su radio de los
## servidores para lo que golpea alrededor y a su alcance para lo que lo mueve.
static func start_position(p: Dictionary) -> Vector2:
	var kind := String(p.get("kind", ""))
	if String(p.get("deploy", "")) != "":
		return START
	if kind in CLOSE_KINDS:
		return Vector2(DUMMIES[0].x - clampf(float(p.get("radius", 80.0)) * 0.7, 60.0, 220.0), START.y)
	if kind in MOVE_KINDS:
		return Vector2(DUMMIES[0].x - clampf(float(p.get("range", 300.0)) * 0.85, 120.0, 420.0), START.y)
	if kind == "unit" and String((p.get("unit", {}) as Dictionary).get("behavior", "melee")) in ["melee", "tank"]:
		return Vector2(DUMMIES[0].x - 300.0, START.y)   # que lleguen a pegar antes de que acabe la vuelta
	return START


## Hacia dónde apunta: al primer servidor; los saltos caen a su lado y la embestida lo atraviesa.
static func aim_point(p: Dictionary) -> Vector2:
	match String(p.get("kind", "")):
		"leap_slam", "blink", "ssh", "charge":
			return DUMMIES[0] - Vector2(DUMMY_RADIUS + 34.0, 0.0)
		"dash":
			return DUMMIES[0] + Vector2(90.0, 0.0)
	return DUMMIES[0]


func _setup_hero(character: CharacterData) -> void:
	if character == null or not HeroSprite.available():
		if _hero:
			_hero.hide()
		return
	if _hero == null:
		_hero = HeroSprite.new()
		_view.add_child(_hero)
		_view.move_child(_hero, _stage.get_index() + 1)   # encima del suelo, debajo de los efectos
	_hero.show()
	var equipped := {}
	for slot in StudentHero.LOOKS.keys() + ["weapon"]:
		var it: Item = character.inventory.equipment.get(slot, null)
		equipped[slot] = String(it.base.get("id", "")) if it != null else ""
	_hero.appearance = StudentHero.look_of(character.appearance, equipped)


func _clear() -> void:
	for list: Array in [_sc._effects, _sc._projectiles, _sc._spins, _sc._traps, _sc._devices, _sc._minions,
			_sc._clouds, _sc._drones, _sc._units, _sc._auras, _sc._terrains, _sc._breakpoints, _sc._canaries, _sc._lazies]:
		list.clear()
	_sc._channel = {}
	_later.clear()
	_fx.clear()
	_flash.fill(0.0)
	_hit_cd.fill(0.0)
	hits = 0
	_sc.queue_redraw()


## Vuelve a empezar la vuelta: el personaje a su sitio y la habilidad, otra vez.
func _restart() -> void:
	_clear()
	_t = 0.0
	if _p.is_empty():
		return
	_cycle = cycle_seconds(_p)
	_player.position = start_position(_p)
	_action = Player.action_for(_p)
	_action_len = clampf(float(_p.get("use_time", 0.35)), 0.25, 0.6)
	_action_t = 0.0
	var target := aim_point(_p)
	var color: Color = SkillController.DAMAGE_COLORS.get(String(_p.get("damage_type", "physical")), Color.WHITE)
	if not (String(_p.get("kind", "")) in SkillCalc.AUTOMATON_KINDS or String(_p.get("kind", "")) == "aura") \
			and String(_p.get("damage_type", "none")) != "none":
		var dir := (target - _player.position).normalized()
		_fx.cast(_player.position + dir * 16.0 + Vector2(0, -24.0), SkillFx.signature(_p)["cast"], color, dir)
	if String(_p.get("deploy", "")) != "":
		_deploy(_p, target, color)
	else:
		_cast(_p, _player.position, target, false)


func _process(delta: float) -> void:
	if _p.is_empty() or not is_visible_in_tree():
		return
	step(minf(delta, 0.05))


## Avanza la vista previa `delta` segundos (público para las pruebas).
func step(delta: float) -> void:
	if _p.is_empty():
		return
	_t += delta
	_anim += delta
	_action_t += delta
	if _t >= _cycle:
		_restart()
		return
	for i in DUMMIES.size():
		_flash[i] = maxf(0.0, _flash[i] - delta)
		_hit_cd[i] -= delta
	_run_later(delta)
	_move_projectiles(delta)
	_tick_spins(delta)
	_tick_traps(delta)
	_tick_devices(delta)
	_tick_minions(delta)
	_tick_drones(delta)
	_tick_units(delta)
	_tick_grounds(delta)
	_tick_channel(delta)
	_sc._update_effects(delta)
	_update_hero()
	_stage.queue_redraw()
	_sc.queue_redraw()


## Cuántas cosas de SkillController hay ahora en pantalla (lo miran las pruebas).
func visible_things() -> int:
	var n := _sc._effects.size() + _sc._projectiles.size() + _sc._spins.size() + _sc._traps.size() \
		+ _sc._devices.size() + _sc._minions.size() + _sc._clouds.size() + _sc._drones.size() \
		+ _sc._units.size() + _sc._auras.size() + _sc._terrains.size() \
		+ _sc._breakpoints.size() + _sc._canaries.size() + _sc._lazies.size()   # (habilidades nuevas, T208-T209)
	return n + (0 if _sc._channel.is_empty() else 1)


# --- Lanzar (lo mismo que SkillController._execute, sin daño) ---

func _cast(p: Dictionary, origin: Vector2, target: Vector2, device: bool) -> void:
	var color: Color = SkillController.DAMAGE_COLORS.get(String(p.get("damage_type", "physical")), Color.WHITE)
	var dir := (target - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var radius := maxf(20.0, float(p.get("radius", 60.0)))
	var reach := float(p.get("range", 400.0))
	var fx := _sc._effects
	var fx_before := fx.size()
	var start := _player.position
	_cast_kind(p, origin, target, device, color, dir, radius, reach, fx)
	# Con firma (T193-T195), la misma que en el juego en vez del anillo, la estela o el cono genéricos.
	var id := String(p.get("id", ""))
	if not device and SkillFx.has_fx(id):
		var mine := fx.slice(fx_before)
		fx.resize(fx_before)
		var hops := PackedVector2Array()   # los saltos de la cadena, de sus zigzags
		for e in mine:
			if String(e["type"]) == "zap":
				if hops.is_empty():
					hops.append(e["pos"])
				hops.append(e["end"])
			if not (String(e["type"]) in GENERIC_FX):
				fx.append(e)
		if SkillFx.BUFF_IDS.has(id):
			# (sin seguir al jugador: en la vista previa no hay personaje que lleve el buff)
			var cast := float(SkillFx.BUFF_FX.get(id, 0.4))
			fx.append(SkillFx.move_fx(id, origin, origin, dir, radius, color, PackedVector2Array(), {"cast": cast, "live": false, "end": -1.0}))
		else:
			var end := _player.position if _player.position != start else origin + (target - origin).limit_length(reach)
			if hops.size() < 2:
				hops = PackedVector2Array([origin, end])
			_sc._move_fx(p, origin, end, dir, color, PackedVector2Array(DUMMIES), {"hops": hops})


## Efectos genéricos que la firma sustituye en la vista previa (T199).
const GENERIC_FX := ["ring", "trail", "cone", "leap", "quake", "zap", "lock", "beam", "beam_marker", "marker", "curse"]


func _cast_kind(p: Dictionary, origin: Vector2, target: Vector2, device: bool, color: Color, dir: Vector2, radius: float, reach: float, fx: Array) -> void:
	match String(p.get("kind", "")):
		"leap_slam":
			var land := origin + (target - origin).limit_length(reach)
			if not device:
				_player.position = land
			fx.append({"type": "leap", "pos": origin, "end": land, "time": 0.0, "duration": 0.3, "color": color})
			fx.append({"type": "quake", "pos": land, "radius": radius, "time": 0.0, "duration": 0.45, "color": color})
			_hit_area(land, radius, p)
		"rain":
			var center := origin + (target - origin).limit_length(reach)
			var n := clampi(int(p.get("rain_hits", 6)), 1, 12)
			var span := minf(float(p.get("duration", 1.5)), _cycle - 0.7)
			var impact := maxf(20.0, float(p.get("impact_radius", radius * 0.4)))
			fx.append({"type": "marker", "pos": center, "radius": radius, "time": 0.0, "duration": span + 0.2, "color": color})
			for k in n:
				_after(span * k / n, func() -> void:
					var spot := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
					_sc._effects.append({"type": "streak", "pos": spot, "radius": impact, "time": 0.0, "duration": 0.16, "color": color})
					_after(0.16, func() -> void: _blast(spot, impact, p, color)))
		"unit":
			if not device:
				_summon(p, origin, color)
		"aura":
			if not device:
				_sc._auras.append({"skill_id": String(p.get("id", "")), "profile": p, "color": color})
				fx.append({"type": "ring", "pos": origin, "radius": 60.0, "time": 0.0, "duration": 0.5, "color": color})
		"melee_area", "nova":
			if float(p.get("stun", 0.0)) > 0.0:
				fx.append({"type": "lock", "pos": origin, "radius": radius, "time": 0.0, "duration": 0.6, "color": color})
			fx.append({"type": "ring", "pos": origin, "radius": radius, "time": 0.0, "duration": 0.25, "color": color})
			_hit_area(origin, radius, p)
		"dash":
			var end := origin + (target - origin).limit_length(reach)
			if not device:
				_player.position = end
			fx.append({"type": "trail", "pos": origin, "end": end, "radius": float(p.get("width", 40.0)), "time": 0.0, "duration": 0.3, "color": color})
			_hit_segment(origin, end, float(p.get("width", 40.0)) * 0.5, p)
		"cone":
			var half := deg_to_rad(float(p.get("angle", 60.0))) / 2.0
			fx.append({"type": "cone", "pos": origin, "dir": dir, "radius": radius, "half": half, "time": 0.0, "duration": 0.35, "color": color})
			_hit_cone(origin, dir, radius, half, p)
		"beam":
			var delay := clampf(float(p.get("delay", 0.4)), 0.1, 0.9)
			var length := float(p.get("range", 500.0))
			var width := float(p.get("width", 30.0))
			fx.append({"type": "beam_marker", "pos": origin, "dir": dir, "radius": width, "length": length, "time": 0.0, "duration": delay, "color": color})
			_after(delay, func() -> void:
				_sc._effects.append({"type": "beam", "pos": origin, "dir": dir, "radius": width, "length": length, "time": 0.0, "duration": 0.35, "color": color})
				_hit_segment(origin, origin + dir * length, width * 0.5, p))
		"boomerang":
			_volley(p, origin, dir, color, {"pierce_left": 999, "boomerang": true, "returning": false, "spin": 0.0, "homing": false})
		"spin":
			_sc._spins.append({"time_left": minf(float(p.get("duration", 2.0)), _cycle - 0.4), "next_tick": 0.0, "profile": _with_radius(p, radius),
				"color": color, "angle": 0.0, "center": origin if device else Vector2.INF})
		"minion":
			var n := clampi(int(p.get("count", 1)), 1, 3)
			for k in n:
				_sc._minions.append({"pos": origin + Vector2.from_angle(TAU * k / n) * 30.0, "life": _cycle, "total": _cycle,
					"cd": 0.3, "profile": p, "color": color, "phase": randf() * TAU})
			fx.append({"type": "ring", "pos": origin, "radius": 50.0, "time": 0.0, "duration": 0.3, "color": color})
		"barrier":
			fx.append({"type": "ring", "pos": origin, "radius": 60.0, "time": 0.0, "duration": 0.5, "color": Color("cfe8ff")})
		"buff":
			if "warcry" in (p.get("tags", []) as Array):
				fx.append({"type": "ring", "pos": origin, "radius": 170.0, "time": 0.0, "duration": 0.5, "color": SkillController.SHOUT_COLOR})
				fx.append({"type": "ring", "pos": origin, "radius": 90.0, "time": 0.0, "duration": 0.35, "color": SkillController.SHOUT_COLOR})
			else:
				fx.append({"type": "ring", "pos": origin, "radius": 45.0, "time": 0.0, "duration": 0.6, "color": Color("e8d070")})
		"curse_area":
			var center := origin + (target - origin).limit_length(reach)
			fx.append({"type": "curse", "pos": center, "radius": radius, "time": 0.0, "duration": 0.8, "color": color})
			_hit_area(center, radius, p)
		"dot_projectile", "homing":
			_volley(p, origin, dir, color, {"dot": String(p.get("kind", "")) == "dot_projectile"})
		"drones":
			var n := clampi(int(p.get("drone_count", 2)), 1, 4)
			for k in n:
				_sc._drones.append({"angle": TAU * k / n, "life": _cycle, "total": _cycle, "next": 0.3 + 0.25 * k, "profile": p, "color": color})
		"degen_area":
			_sc._clouds.append({"pos": origin + (target - origin).limit_length(reach), "life": minf(float(p.get("duration", 3.0)), _cycle - 0.2),
				"next": 0.0, "profile": _with_radius(p, radius), "color": color, "seed": randi()})
		"trap":
			var pp := _with_radius(p, radius)
			pp["trigger_radius"] = float(p.get("trigger_radius", 50.0))
			_sc._traps.append({"pos": origin + (target - origin).limit_length(reach), "armed_in": 0.5, "life": _cycle, "profile": pp, "color": color})
		"chain":
			_chain(p, origin, target, color)
		"projectile":
			_volley(p, origin, dir, color)
		"ticket":   # habilidades nuevas (T208), en pequeño: el golpe con su prioridad
			fx.append({"type": "tag", "pos": DUMMIES[0] + Vector2(-8, -46), "text": "P3", "time": 0.0, "duration": 0.8, "color": color})
			_hit_area(DUMMIES[0], 30.0, p)
		"lazy":   # las flechas salen hacia el servidor más cercano
			_volley(p, origin, dir, color)
		"gradient":
			_volley(p, origin, dir, color, {"grow": 1.0, "steer": 0.0, "pierce_left": 999})
		"breakpoint":   # tanda 2 (T209), en pequeño: el círculo sobre los servidores
			_sc._breakpoints.append({"pos": DUMMIES[0], "life": _cycle - 0.3, "total": _cycle - 0.3, "profile": _with_radius(p, 70.0), "color": SkillController.BREAKPOINT_COLOR})
		"charm":
			fx.append({"type": "tag", "pos": DUMMIES[0] + Vector2(-40, -50), "text": "{prompt}", "time": 0.0, "duration": 1.0, "color": color})
			_hit_area(DUMMIES[0], 40.0, p)
		"canary":
			# El canario al 1 % y, en la vista previa (más corta que su rollout), sus bots al poco.
			if not device:
				var bird := {"pos": origin + Vector2(30, 10), "life": 40.0, "max_life": 40.0, "radius": 10.0, "taunt": 0.0,
					"time": 0.0, "profile": p, "color": Color("e8d070")}
				_sc._canaries.append(bird)
				_after(0.8, func() -> void:
					_sc._canaries.erase(bird)
					var n := int(SkillController.skill_value(p, "count", 3.0))
					for k in n:
						_sc._minions.append({"pos": bird["pos"] + Vector2.from_angle(TAU * k / n) * 24.0, "life": _cycle, "total": _cycle,
							"cd": 0.3, "profile": p, "color": bird["color"], "phase": randf() * TAU}))
		"ground_aoe":
			var at := origin + (target - origin).limit_length(reach)
			var delay := clampf(float(p.get("delay", 0.4)), 0.1, 0.9)
			fx.append({"type": "marker", "pos": at, "radius": radius, "time": 0.0, "duration": delay, "color": color})
			_after(delay, func() -> void: _blast(at, radius, p, color))
		"blink":
			if device:
				return
			var dest := origin + (target - origin).limit_length(reach)
			fx.append({"type": "ring", "pos": origin, "radius": 30.0, "time": 0.0, "duration": 0.3, "color": color})
			_player.position = dest
			fx.append({"type": "ring", "pos": dest, "radius": 40.0, "time": 0.0, "duration": 0.3, "color": color})
		"terrain":
			var at := origin + (target - origin).limit_length(reach)
			var kind := String((p.get("def", {}) as Dictionary).get("terrain", "oil"))
			if not SkillController.TERRAIN_COLORS.has(kind):
				kind = "oil"
			_sc._terrains.append({"pos": at, "radius": radius, "terrain": kind, "life": _cycle - 0.2, "next": 0.0,
				"profile": p, "color": color, "seed": randi()})
			fx.append({"type": "ring", "pos": at, "radius": radius, "time": 0.0, "duration": 0.3, "color": color})
		"ssh":
			if device:
				return
			var dest := origin + (target - origin).limit_length(reach)
			for at: Vector2 in [origin, dest]:
				fx.append({"type": "ring", "pos": at, "radius": radius, "time": 0.0, "duration": 0.3, "color": color})
				_hit_area(at, radius, p)
			_player.position = dest
			fx.append({"type": "zap", "pos": origin, "end": dest, "time": 0.0, "duration": 0.25, "color": color})
		"charge":
			if device:
				return
			var to := DUMMIES[0] - origin
			var end := origin + to - to.normalized() * minf(to.length(), DUMMY_RADIUS + 18.0)
			if to.length() > reach:
				end = origin + dir * reach
			_player.position = end
			fx.append({"type": "trail", "pos": origin, "end": end, "radius": 40.0, "time": 0.0, "duration": 0.3, "color": color})
			fx.append({"type": "quake", "pos": end, "radius": radius, "time": 0.0, "duration": 0.35, "color": color})
			_hit_area(end, radius, p)
		"backflip":
			if device:
				return
			_sc._clouds.append({"pos": origin, "life": minf(float(p.get("duration", 2.0)), _cycle - 0.2), "next": 0.0,
				"profile": _with_radius(p, radius), "color": color, "seed": randi()})
			var back := origin - dir * minf(reach, 260.0)
			_player.position = back
			fx.append({"type": "leap", "pos": origin, "end": back, "time": 0.0, "duration": 0.25, "color": color})
		"channel_beam", "channel_storm":
			if device:
				return
			_sc._channel = {"index": 0, "profile": _with_radius(p, radius), "time": 0.0, "next_tick": 0.0, "aim": target,
				"center": origin + (target - origin).limit_length(reach), "color": color}
		_:
			fx.append({"type": "ring", "pos": origin, "radius": 45.0, "time": 0.0, "duration": 0.5, "color": color})


## RAM de despliegue: trampa, mina, torreta o contenedor que lanza la habilidad sola.
func _deploy(p: Dictionary, target: Vector2, color: Color) -> void:
	var kind := String(p["deploy"])
	var rules: Dictionary = SkillController.DEVICE_RULES.get(kind, SkillController.DEVICE_RULES["totem"])
	var inner := p.duplicate()
	inner["deploy"] = ""
	var origin := _player.position
	var interval := maxf(0.5, maxf(0.35, float(p.get("use_time", 0.5)) * 1.25) / maxf(0.1, float(p.get("automaton_speed", 1.0))))
	_sc._devices.append({"kind": kind, "pos": origin + (target - origin).limit_length(rules["range"]), "armed_in": minf(float(rules["armed"]), 0.8),
		"life": _cycle, "total": _cycle, "profile": inner, "next_use": 0.0, "interval": interval, "color": color})


func _summon(p: Dictionary, origin: Vector2, color: Color) -> void:
	var unit: Dictionary = p.get("unit", {})
	var behavior := String(unit.get("behavior", "melee"))
	var n := clampi(int(p.get("max_units", 1)), 1, 2)
	for k in n:
		var u := {"skill_id": String(p.get("id", "")), "behavior": behavior, "pos": origin + Vector2(36.0, -34.0 + 68.0 * k),
			"life": 1.0, "max_life": 1.0, "radius": float(unit.get("radius", 12.0)), "taunt": 0.0, "hurt": 0.0,
			"phase": randf() * TAU, "angle": TAU * k / n, "color": color, "cd": 0.5 + 0.3 * k,
			"speed": float(unit.get("speed", 220.0)), "interval": float(unit.get("interval", 1.0)),
			"shoots": bool(unit.get("shoots", true)), "lane": -26.0 + 52.0 * k, "profile": p}
		if behavior == "orbit":
			u["pos"] = _orbit_pos(u)
		for ab: Dictionary in p.get("unit_abilities", unit.get("abilities", [])):
			if String(ab.get("kind", "")) == "corrode":   # Golem de Kernel: su campo de corrupción
				u["corrode_radius"] = float(ab.get("radius", 150.0))
		_sc._units.append(u)
		_sc._effects.append({"type": "ring", "pos": u["pos"], "radius": 40.0 + u["radius"], "time": 0.0, "duration": 0.5, "color": color})


func _volley(p: Dictionary, origin: Vector2, dir: Vector2, color: Color, extra := {}, reach := -1.0, count := -1) -> void:
	var n := count if count > 0 else maxi(1, int(p.get("projectiles", 1)))
	var spread := deg_to_rad(float(p.get("spread_degrees", 0.0)))
	for k in n:
		var angle := 0.0 if n == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (n - 1))
		var pr := {"pos": origin, "vel": dir.rotated(angle) * maxf(250.0, float(p.get("projectile_speed", 700.0))),
			"distance_left": minf(reach if reach > 0.0 else float(p.get("range", 600.0)), MAX_REACH),
			"pierce_left": int(p.get("pierce", 0)), "hit_ids": {}, "profile": p, "color": color,
			"chains_left": int(p.get("projectile_chains", 0)), "homing": bool(p.get("homing", false)),
			"fx": SkillFx.signature(p), "trail_t": 0.0, "phase": randf() * 10.0}
		pr.merge(extra, true)
		_sc._projectiles.append(pr)


## Cadena: salta del personaje al servidor apuntado y de ahí a los demás.
func _chain(p: Dictionary, origin: Vector2, target: Vector2, color: Color) -> void:
	var reach := float(p.get("range", 500.0))
	var first := _nearest(target)
	if first == -1 or DUMMIES[first].distance_to(origin) > reach:
		_sc._effects.append({"type": "zap", "pos": origin, "end": origin + (target - origin).limit_length(reach), "time": 0.0, "duration": 0.2, "color": color})
		return
	var hit := {}
	var from := origin
	var i := first
	for k in int(p.get("chains", 2)) + 1:
		_sc._effects.append({"type": "zap", "pos": from, "end": DUMMIES[i], "time": -0.06 * k, "duration": 0.3, "color": color})
		var idx := i
		_after(0.06 * k, func() -> void: _hit(idx, p))
		hit[i] = true
		from = DUMMIES[i]
		i = _nearest(from, hit)
		if i == -1 or DUMMIES[i].distance_to(from) > float(p.get("chain_range", 260.0)):
			break


func _blast(at: Vector2, radius: float, p: Dictionary, color: Color) -> void:
	_sc._effects.append({"type": "burst", "pos": at, "radius": radius, "time": 0.0, "duration": 0.3, "color": color})
	_hit_area(at, radius, p)


static func _with_radius(p: Dictionary, radius: float) -> Dictionary:
	if float(p.get("radius", 0.0)) > 0.0:
		return p
	var out := p.duplicate()
	out["radius"] = radius
	return out


func _after(seconds: float, call: Callable) -> void:
	_later.append({"time": seconds, "call": call})


func _run_later(delta: float) -> void:
	var due: Array[Callable] = []
	var still: Array[Dictionary] = []
	for e in _later:
		e["time"] -= delta
		if e["time"] <= 0.0:
			due.append(e["call"])
		else:
			still.append(e)
	_later = still
	for call in due:
		call.call()


# --- Golpes a los servidores de prueba ---

func _hit(i: int, p: Dictionary) -> void:
	if _hit_cd[i] > 0.0:
		return
	_hit_cd[i] = HIT_GAP
	_flash[i] = 0.18
	hits += 1
	var dtype := String(p.get("damage_type", "physical"))
	_fx.hit(DUMMIES[i] + Vector2(0, -10), dtype if dtype != "none" else "physical", false, 0.25)


func _hit_area(center: Vector2, radius: float, p: Dictionary) -> void:
	for i in DUMMIES.size():
		if DUMMIES[i].distance_to(center) <= radius + DUMMY_RADIUS:
			_hit(i, p)


func _hit_segment(a: Vector2, b: Vector2, half_width: float, p: Dictionary) -> void:
	for i in DUMMIES.size():
		if Geometry2D.get_closest_point_to_segment(DUMMIES[i], a, b).distance_to(DUMMIES[i]) <= half_width + DUMMY_RADIUS:
			_hit(i, p)


func _hit_cone(origin: Vector2, dir: Vector2, radius: float, half: float, p: Dictionary) -> void:
	for i in DUMMIES.size():
		var to := DUMMIES[i] - origin
		if to.length() <= radius + DUMMY_RADIUS and absf(dir.angle_to(to)) <= half + 0.15:
			_hit(i, p)


func _nearest(pos: Vector2, skip := {}) -> int:
	var best := -1
	for i in DUMMIES.size():
		if not skip.has(i) and (best == -1 or DUMMIES[i].distance_to(pos) < DUMMIES[best].distance_to(pos)):
			best = i
	return best


# --- Lo que se mueve (una versión mínima de los _update_* de SkillController) ---

func _move_projectiles(delta: float) -> void:
	var still: Array[Dictionary] = []
	for pr in _sc._projectiles:
		var p: Dictionary = pr["profile"]
		if pr.get("boomerang", false):
			pr["spin"] += delta * 18.0
			if not pr["returning"] and pr["distance_left"] <= 0.0:
				pr["returning"] = true
				pr["hit_ids"] = {}
			if pr["returning"]:
				var back: Vector2 = _player.position - pr["pos"]
				if back.length() < 24.0:
					continue   # de vuelta en la mano
				pr["vel"] = back.normalized() * (pr["vel"] as Vector2).length()
				pr["distance_left"] = 1.0
		if pr.get("homing", false):
			var t := _nearest(pr["pos"], pr["hit_ids"])
			if t != -1:
				var want: Vector2 = (DUMMIES[t] - pr["pos"]).normalized()
				var cur: Vector2 = (pr["vel"] as Vector2).normalized()
				pr["vel"] = cur.slerp(want, clampf(float(p.get("turn_rate", 4.0)) * delta, 0.0, 1.0)) * (pr["vel"] as Vector2).length()
		var step: Vector2 = pr["vel"] * delta
		pr["pos"] += step
		if not pr.get("returning", false):
			pr["distance_left"] -= step.length()
		var dir: Vector2 = (pr["vel"] as Vector2).normalized()
		pr["trail_t"] = float(pr["trail_t"]) + delta
		if pr["trail_t"] >= SkillFx.TRAIL_EVERY:
			pr["trail_t"] = 0.0
			_fx.trail(pr["pos"], pr["fx"]["trail"], pr["color"], dir)
		var hit := -1
		for i in DUMMIES.size():
			if not pr["hit_ids"].has(i) and DUMMIES[i].distance_to(pr["pos"]) <= DUMMY_RADIUS + SkillController.PROJECTILE_RADIUS:
				hit = i
				break
		if hit != -1:
			pr["hit_ids"][hit] = true
			_hit(hit, p)
			var next := _nearest(pr["pos"], pr["hit_ids"]) if int(pr.get("chains_left", 0)) > 0 else -1
			if next != -1:
				pr["chains_left"] -= 1
				pr["vel"] = (DUMMIES[next] - pr["pos"]).normalized() * (pr["vel"] as Vector2).length()
				pr["distance_left"] = maxf(pr["distance_left"], 300.0)
			else:
				pr["pierce_left"] -= 1
			_sc._effects.append({"type": "burst", "pos": pr["pos"], "radius": 14.0, "time": 0.0, "duration": 0.15, "color": pr["color"]})
			_fx.skill_impact(pr["pos"], pr["fx"]["impact"], pr["color"], dir)
		if pr.get("boomerang", false) or (pr["distance_left"] > 0.0 and pr["pierce_left"] >= 0):
			still.append(pr)
	_sc._projectiles = still


func _tick_spins(delta: float) -> void:
	var still: Array[Dictionary] = []
	for spin in _sc._spins:
		spin["time_left"] -= delta
		spin["next_tick"] -= delta
		spin["angle"] += delta * 14.0
		if spin["time_left"] <= 0.0:
			continue
		if spin["next_tick"] <= 0.0:
			spin["next_tick"] = maxf(0.15, float(spin["profile"].get("tick", 0.25)))
			_hit_area(_sc._spin_center(spin), float(spin["profile"]["radius"]), spin["profile"])
		still.append(spin)
	_sc._spins = still


func _tick_traps(delta: float) -> void:
	var still: Array[Dictionary] = []
	for trap in _sc._traps:
		trap["armed_in"] -= delta
		if trap["armed_in"] <= -0.3:   # armada y pisada
			_sc._effects.append({"type": "burst", "pos": trap["pos"], "radius": trap["profile"]["radius"], "time": 0.0, "duration": 0.35, "color": trap["color"]})
			_hit_area(trap["pos"], float(trap["profile"]["radius"]), trap["profile"])
			continue
		still.append(trap)
	_sc._traps = still


func _tick_devices(delta: float) -> void:
	var still: Array[Dictionary] = []
	for d in _sc._devices:
		d["life"] -= delta
		d["armed_in"] -= delta
		if d["life"] <= 0.0:
			continue
		if d["armed_in"] > 0.0:
			still.append(d)
			continue
		var target := DUMMIES[_nearest(d["pos"])]
		if d["kind"] in SkillController.TURRET_DEVICES:
			d["next_use"] -= delta
			if d["next_use"] <= 0.0:
				d["next_use"] = d["interval"]
				_cast(d["profile"], d["pos"], target, true)
			still.append(d)
		elif d["armed_in"] <= -0.3:
			# Trampa o mina: un servidor la pisa, se ejecuta la habilidad y desaparece.
			_cast(d["profile"], d["pos"], target, true)
			_sc._effects.append({"type": "burst", "pos": d["pos"], "radius": 26.0, "time": 0.0, "duration": 0.25, "color": d["color"]})
		else:
			still.append(d)
	_sc._devices = still


func _tick_minions(delta: float) -> void:
	for m in _sc._minions:
		m["life"] -= delta
		m["cd"] -= delta
		m["phase"] += delta * 8.0
		var pos: Vector2 = m["pos"]
		var i := _nearest(pos)
		var to := DUMMIES[i] - pos
		var reach := DUMMY_RADIUS + 14.0
		if to.length() > reach:
			m["pos"] = pos + to.normalized() * minf(SkillController.MINION_SPEED * delta, to.length() - reach)
		elif m["cd"] <= 0.0:
			m["cd"] = maxf(0.3, float(m["profile"].get("minion_interval", 0.6)))
			_sc._effects.append({"type": "burst", "pos": pos + to.normalized() * 14.0, "radius": 12.0, "time": 0.0, "duration": 0.15, "color": m["color"]})
			_hit(i, m["profile"])


func _tick_drones(delta: float) -> void:
	for d in _sc._drones:
		d["life"] -= delta
		d["next"] -= delta
		d["angle"] += delta * 1.6
		if d["next"] <= 0.0:
			var p: Dictionary = d["profile"]
			d["next"] = maxf(0.3, float(p.get("tick", 0.6)))
			var pos := _sc._drone_pos(d)
			_volley(p, pos, (DUMMIES[_nearest(pos)] - pos).normalized(), d["color"], {}, 600.0, 1)


func _orbit_pos(u: Dictionary) -> Vector2:
	return _player.position + Vector2.from_angle(u["angle"]) * Vector2(46, 28) + Vector2(0, -30)


func _tick_units(delta: float) -> void:
	for u in _sc._units:
		u["phase"] += delta * 6.0
		u["cd"] -= delta
		var p: Dictionary = u["profile"]
		var pos: Vector2 = u["pos"]
		if u.has("corrode_radius"):
			u["corrode_cd"] = float(u.get("corrode_cd", 0.0)) - delta
			if u["corrode_cd"] <= 0.0:
				u["corrode_cd"] = 0.5
				_hit_area(pos, u["corrode_radius"], p)
		match String(u["behavior"]):
			"orbit":
				u["angle"] += delta * 1.5
				u["pos"] = _orbit_pos(u)
				if u["shoots"] and u["cd"] <= 0.0:
					u["cd"] = u["interval"]
					_volley(p, u["pos"], (DUMMIES[_nearest(u["pos"])] - u["pos"]).normalized(), u["color"], {"pierce_left": 0}, 600.0, 1)
			"ranged":
				var goal := Vector2(DUMMIES[0].x - 250.0, DUMMIES[0].y + float(u["lane"]))
				if pos.distance_to(goal) > 6.0:
					u["pos"] = pos.move_toward(goal, float(u["speed"]) * delta)
				elif u["cd"] <= 0.0:
					u["cd"] = u["interval"]
					_volley(p, pos + Vector2(0, -12), (DUMMIES[_nearest(pos)] - pos).normalized(), u["color"], {"pierce_left": 0}, 600.0, 1)
			_:
				var i := _nearest(pos)
				var to := DUMMIES[i] - pos
				var reach := DUMMY_RADIUS + float(u["radius"]) + 4.0
				if to.length() > reach:
					u["pos"] = pos + to.normalized() * minf(float(u["speed"]) * delta, to.length() - reach)
				elif u["cd"] <= 0.0:
					u["cd"] = u["interval"]
					_sc._effects.append({"type": "burst", "pos": pos + to.normalized() * float(u["radius"]), "radius": 16.0, "time": 0.0, "duration": 0.2, "color": u["color"]})
					_hit(i, p)


## Charcos (Fuga de Memoria, Git Revert) y terrenos: se apagan y golpean a lo que hay dentro.
func _tick_grounds(delta: float) -> void:
	for list: Array[Dictionary] in [_sc._clouds, _sc._terrains]:
		var still: Array[Dictionary] = []
		for g in list:
			g["life"] -= delta
			g["next"] -= delta
			if g["life"] <= 0.0:
				continue
			if g["next"] <= 0.0:
				g["next"] = 0.45
				var r: float = g["radius"] if g.has("radius") else float(g["profile"]["radius"])
				if float(g["profile"].get("max_damage", 1.0)) > 0.0:
					_hit_area(g["pos"], r, g["profile"])
			still.append(g)
		list.assign(still)


func _tick_channel(delta: float) -> void:
	var ch := _sc._channel
	if ch.is_empty():
		return
	ch["time"] += delta
	if ch["time"] >= _cycle - 0.5:
		_sc._channel = {}
		return
	var p: Dictionary = ch["profile"]
	var origin := _player.position
	if String(p.get("kind", "")) == "channel_storm":
		var want := origin + ((ch["aim"] as Vector2) - origin).limit_length(float(p.get("range", 400.0)))
		ch["center"] = (ch["center"] as Vector2).move_toward(want, SkillController.STORM_FOLLOW * delta)
	ch["next_tick"] -= delta
	if ch["next_tick"] > 0.0:
		return
	ch["next_tick"] = maxf(0.2, float(p.get("use_time", 0.3)))
	if String(p.get("kind", "")) == "channel_beam":
		var end := origin + ((ch["aim"] as Vector2) - origin).normalized() * float(p.get("range", 500.0))
		_hit_segment(origin, end, float(p.get("width", 30.0)) * 0.5, p)
	else:
		_hit_area(ch["center"], SkillController.storm_radius(p, ch["time"]), p)


# --- Dibujo: el suelo, los servidores y el personaje ---

func _update_hero() -> void:
	if _hero == null or not _hero.visible:
		return
	var state := "idle"
	if not _sc._channel.is_empty():
		state = "channel"
	elif _action_t < _action_len:
		state = _action
	_hero.position = _player.position + Vector2(0.0, Player.RADIUS * 0.6)
	_hero.set_pose(Vector2.RIGHT, {"state": state, "t": clampf(_action_t / _action_len, 0.0, 1.0), "time": _anim, "weapon": _weapon})


func _draw_stage() -> void:
	var half := SIZE / ZOOM / 2.0 + Vector2(4, 4)
	_stage.draw_rect(Rect2(-half, half * 2.0), FLOOR)
	# Baldosas de servidor: una rejilla tenue (que se lea como suelo, no como tabla).
	var x := -half.x - fposmod(-half.x, 48.0)
	while x < half.x:
		_stage.draw_line(Vector2(x, -half.y), Vector2(x, half.y), FLOOR_LINE, 2.0)
		x += 48.0
	var y := -half.y - fposmod(-half.y, 48.0)
	while y < half.y:
		_stage.draw_line(Vector2(-half.x, y), Vector2(half.x, y), FLOOR_LINE, 2.0)
		y += 48.0
	for i in DUMMIES.size():
		_draw_dummy(DUMMIES[i], _flash[i])
	if _hero == null or not _hero.visible:
		_draw_stand_in()


## Servidor de prueba: un rack pequeño con sus luces; parpadea en blanco al recibir.
func _draw_dummy(at: Vector2, flash: float) -> void:
	_stage.draw_set_transform(at + Vector2(0, 16), 0.0, Vector2(1.0, 0.4))
	_stage.draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.35))
	_stage.draw_set_transform(Vector2.ZERO)
	var body := Rect2(at + Vector2(-12, -22), Vector2(24, 38))
	_stage.draw_rect(body, Color("23262e"))
	_stage.draw_rect(body, Color("4a4f5c"), false, 2.0)
	for k in 3:
		_stage.draw_rect(Rect2(at + Vector2(-8, -16 + k * 11), Vector2(16, 6)), Color("15181e"))
		var on := fmod(_anim * 2.0 + k * 0.7 + at.y * 0.01, 1.4) < 0.9
		_stage.draw_rect(Rect2(at + Vector2(4, -15 + k * 11), Vector2(2, 4)), Color("6fd36b") if on else Color("1a2a1a"))
	if flash > 0.0:
		_stage.draw_rect(body, Color(1, 1, 1, 0.6 * flash / 0.18 * Accessibility.flash(1.0)))


## Sin hoja del alumno (pruebas, o sin personaje): una figura sencilla en su lugar.
func _draw_stand_in() -> void:
	var at := _player.position
	var glow: Color = SkillController.DAMAGE_COLORS.get(String(_p.get("damage_type", "physical")), Color.WHITE)
	_stage.draw_set_transform(at + Vector2(0, 10), 0.0, Vector2(1.0, 0.4))
	_stage.draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	_stage.draw_set_transform(Vector2.ZERO)
	_stage.draw_rect(Rect2(at + Vector2(-7, -20), Vector2(14, 28)), Color("3a5a8a"))
	_stage.draw_circle(at + Vector2(0, -26), 7.0, Color("e0b48a"))
	if _action_t < _action_len:
		_stage.draw_circle(at + Vector2(10, -10), 4.0, Color(glow, 0.8))
