class_name World
extends Node2D
## Escena de juego: la zona actual del acto (Zone), jugador, enemigos, botín,
## habilidades y UI. Viaja entre zonas por las salidas y por waypoints; al
## morir se reaparece en el campamento. Juega con GameData.current_character y
## lo guarda automáticamente. Ejecutada sola (F6) usa un personaje temporal.
## Teclas de depuración: F1 +30 enemigos, F2 limpiar, F3 jefe único,
## F4 soltar botín de prueba, R reaparecer.

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
## Clase del personaje temporal al ejecutar esta escena sola.
const DEV_CLASS := &"guerrero"
const RARITY_BY_NAME := {"normal": Rarity.Item.NORMAL, "magic": Rarity.Item.MAGIC, "rare": Rarity.Item.RARE,
	"ultra_rare": Rarity.Item.ULTRA_RARE, "unique": Rarity.Item.UNIQUE, "set": Rarity.Item.SET}
## Tras un cambio (nivel, objetos, pasivas), se guarda como mucho cada X segundos.
const AUTOSAVE_DELAY := 5.0
## Y, aunque no cambie nada, cada X segundos (para el tiempo jugado).
const AUTOSAVE_INTERVAL := 60.0

var character: CharacterData
var player: Player
var enemies: EnemyManager
var loot: LootManager
var skills: SkillController
var zone: Zone
var item_generator: ItemGenerator
var ui: GameUI
## Filtro de pixel art del mundo (debajo de la interfaz).
var post: WorldPost
var big_fx: BigFx
var quests: QuestLog

var _dirty := false
var _since_save := 0.0
var _boss_alive := false
## Fases de jefe ya iniciadas en esta zona (la música acelera con cada una).
var _boss_phase := 0
## Visita en curso a la zona, para la telemetría local (Telemetry).
var _visit: Dictionary = {}
## Cuándo apareció el jefe de la zona (play_time), para su récord de tiempo.
var _boss_started := 0.0
## Banco de oleadas en curso (Ladder): {wave, ids, next_in, time, base_level}.
var _waves: Dictionary = {}
## Prueba de estrés en curso: {def, wave, total, ids, next_in, rewards}.
var _challenge: Dictionary = {}
## Recompensas ya enseñadas por prueba (para no cambiarlas al volver a mirar).
var _challenge_previews: Dictionary = {}
## Subjefe de los gemelos: {ids, turn, timer, swap, flag}.
var _twins: Dictionary = {}
var _immune_warning := 0.0
## Alijo de la cuenta (compartido por todos los personajes).
var stash: Stash
## Mercancía de Nacho y el nivel para el que se generó.
var _shop_stock: Array[Item] = []
## Cajas que Nacho ha sacado desde que entraste a la zona (cada una cuesta más).
var _shop_refreshes := 0
var _shop_level := 0
var _rng := RandomNumberGenerator.new()
## Hitstop: hasta cuándo no puede repetirse (ms) y la pausa mínima entre dos.
var _hitstop_ready_at := 0
const HITSTOP_GAP_MS := 250


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0b0a0e"))
	tree_exiting.connect(func() -> void: MusicPlayer.set_intensity(0))
	# Detector de cuelgues (escribe en user://logs/congelado.log si el juego se para).
	if not get_tree().process_frame.is_connected(FreezeWatch.beat):
		get_tree().process_frame.connect(FreezeWatch.beat)
	FreezeWatch.start()
	tree_exiting.connect(FreezeWatch.stop)
	character = GameData.current_character
	if character == null:
		character = GameData.create_character("Desarrollador", DEV_CLASS, CharacterAppearance.default(), false)
	item_generator = ItemGenerator.new(GameData.items)
	_rng.randomize()
	stash = Stash.load_from(CharacterSaves.stash_path(), GameData.items)   # cada espacio de guardado tiene el suyo
	ItemTransfer.stash = stash
	tree_exiting.connect(func() -> void: ItemTransfer.stash = null)
	character.leveled_up.connect(_on_leveled_up)
	character.board_leveled.connect(func(b: Motherboard) -> void:
		ui.hud.flash("%s sube a nivel %d." % [b.skill_def.get("name", "La placa"), b.level], Color("1ba29b")))
	character.inventory.changed.connect(_mark_dirty)
	character.tokens_changed.connect(func(_t: int) -> void: _mark_dirty())
	character.passives.changed.connect(_mark_dirty)
	character.stats_changed.connect(_mark_dirty)  # incluye cambio de ascendencia

	enemies = EnemyManager.new()
	add_child(enemies)
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	var numbers := DamageNumbers.new()   # números de daño (T97), encima de los enemigos
	numbers.enemies = enemies
	numbers.z_index = 50
	add_child(numbers)
	big_fx = BigFx.new()   # ráfagas de partículas de las explosiones y novas (T98)
	add_child(big_fx)
	player.setup(character, enemies)
	enemies.player = player
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.nemesis_killed.connect(_on_nemesis_killed)
	enemies.immune_hit.connect(_on_immune_hit)
	enemies.crit_dealt.connect(func() -> void:
		player.camera_shake(1.5, 0.06)
		hitstop(0.035))
	tree_exiting.connect(func() -> void:
		Engine.time_scale = 1.0
		MusicPlayer.set_combat(false))
	enemies.phase_started.connect(func(_id: int, phase_name: String, text: String, color: Color) -> void:
		ui.hud.flash("%s\n%s" % [phase_name, text], color)
		Sfx.play("wave")
		_boss_phase += 1
		MusicPlayer.set_intensity(_boss_phase))
	skills = SkillController.new()
	add_child(skills)
	skills.setup(player, enemies, character)
	skills.spot_fixer = func(p: Vector2) -> Vector2: return p if zone == null else zone.free_spot_near(p, 18.0)
	# Después del jugador: reciben los clicks antes que él (recoger, hablar).
	loot = LootManager.new()
	loot.player = player
	loot.inventory = character.inventory
	add_child(loot)
	loot.picked_up.connect(_on_item_picked_up)
	loot.tokens_picked.connect(func(amount: int) -> void:
		character.add_tokens(amount)
		Sfx.play("coin", -8.0)
		_mark_dirty())
	# El botín solo cae donde se puede llegar a recogerlo.
	loot.placement_check = func(p: Vector2) -> bool: return zone == null or zone.is_walkable(p, 18.0)
	loot.spot_fixer = func(p: Vector2) -> Vector2: return p if zone == null else zone.free_spot_near(p, 24.0)

	quests = QuestLog.new(character)
	quests.quest_started.connect(_on_quest_started)
	quests.quest_completed.connect(_on_quest_completed)

	post = WorldPost.new()
	post.player = player
	post.skills = skills
	big_fx.skills = skills
	post.enemies = enemies
	post.loot = loot
	add_child(post)
	ui = GameUI.new()
	ui.layer = 5   # encima del filtro de pixel art (capa 1)
	add_child(ui)
	ui.setup(player, enemies, character, loot, skills, quests)
	player.died.connect(_on_player_died)
	ui.return_to_menu_requested.connect(_return_to_menu)
	ui.quit_requested.connect(_quit_game)
	ui.dialogue_action.connect(_on_dialogue_action)
	ui.shop_refresh_requested.connect(_refresh_shop)
	ui.waypoint_selected.connect(func(zone_id: String) -> void: travel_to(zone_id, "waypoint"))

	# Se vuelve a la última zona; los personajes de antes del acto, al campamento.
	var start_zone: String = character.flags.get("zone", GameData.act.get("town", "campamento"))
	if not GameData.zones.has(start_zone):
		start_zone = GameData.act.get("town", "campamento")
	travel_to(start_zone, "waypoint" if GameData.zones[start_zone].get("waypoint") != null else "")
	quests.start_auto()
	_grant_unlocks.call_deferred()   # personajes que ya pasaron esos niveles antes del cambio

	if character.flags.has("ascendancy_reset"):
		character.flags.erase("ascendancy_reset")
		ui.hud.flash.call_deferred("Las ascendencias ahora se eligen al nivel 20: tu elección se ha reiniciado.", UiStyle.ACCENT)
	if character.flags.has("ascendancy_removed"):
		character.flags.erase("ascendancy_removed")
		ui.hud.flash.call_deferred("Las ascendencias ahora son dos por clase: tu elección ya no existe, elige otra en el árbol (P).", UiStyle.ACCENT)
	if character.flags.has("ascendancy_refunded"):
		character.flags.erase("ascendancy_refunded")
		ui.hud.flash.call_deferred("Tu ascendencia tiene un árbol nuevo de 20 nodos: te devolvimos los puntos (P → medallón).", UiStyle.ACCENT)
	if character.flags.has("passives_refunded"):
		character.flags.erase("passives_refunded")
		ui.hud.flash.call_deferred("El árbol pasivo es nuevo: tienes %d puntos para repartir (P). Hasta que cierres el árbol, quitar nodos es gratis." % character.passive_points_available(), UiStyle.ACCENT)


## Voz del personaje (Barks): un quejido al bajar de LOW_LIFE_BARK de vida, como
## mucho cada LOW_LIFE_BARK_COOLDOWN segundos.
const LOW_LIFE_BARK := 0.3
const LOW_LIFE_BARK_COOLDOWN := 25.0
var _low_life_wait := 0.0
var _was_low := false


func _update_low_life_bark(delta: float) -> void:
	_low_life_wait = maxf(0.0, _low_life_wait - delta)
	var low := player.is_alive() and player.life < player.max_life() * LOW_LIFE_BARK
	if low and not _was_low and _low_life_wait <= 0.0:
		_low_life_wait = LOW_LIFE_BARK_COOLDOWN
		Barks.play("hurt", player_voice_pitch())
	_was_low = low


## Tono de la voz del personaje según su complexión (más grave cuanto más ancho).
func player_voice_pitch() -> float:
	return [1.15, 1.0, 0.85][clampi(int(character.appearance.get("body", 1)), 0, 2)]


## Capa de batería de combate: entra con COMBAT_ON enemigos cerca (o un raro y
## media manada) y sale tras COMBAT_CALM segundos con menos de COMBAT_OFF.
const COMBAT_RANGE := 700.0
const COMBAT_ON := 15
const COMBAT_OFF := 6
const COMBAT_CALM := 4.0
var _combat_check := 0.0
var _combat_calm := 0.0


## Élites y jefes que ya se anunciaron con su aviso (por id; se vacía al cambiar de zona).
var _sighted := {}


func _update_combat_music(delta: float) -> void:
	_combat_check -= delta
	if _combat_check > 0.0:
		return
	_combat_check = 0.5
	if zone == null or zone.safe or _boss_phase > 0 or not player.is_alive():
		MusicPlayer.set_combat(false)
		return
	var near := 0
	var strong := false
	var pp := player.global_position
	for i in enemies.count():
		if enemies.positions[i].distance_to(pp) <= COMBAT_RANGE:
			near += 1
			strong = strong or enemies.rarities[i] >= Rarity.Enemy.ELITE
			# Aviso al ver por primera vez un élite o un jefe (T78).
			var sting := SoundMap.sighting_stinger(enemies.rarities[i])
			if sting != "" and not _sighted.has(enemies.ids[i]):
				_sighted[enemies.ids[i]] = true
				SoundMap.stinger(sting)
				if enemies.rarities[i] == Rarity.Enemy.UNIQUE and BossIntro.enabled:
					# Entrada de jefe (T103): su nombre y su pose, una vez por jefe.
					var intro := BossIntro.new()
					intro.boss_name = String(enemies.names[i])
					intro.region = enemies.sprite_region(i)
					intro.color = Rarity.enemy_color(enemies.rarities[i])
					add_child(intro)
	if near >= COMBAT_ON or (strong and near >= COMBAT_ON / 2):
		_combat_calm = COMBAT_CALM
		MusicPlayer.set_combat(true)
	elif near < COMBAT_OFF:
		_combat_calm -= 0.5
		if _combat_calm <= 0.0:
			MusicPlayer.set_combat(false)


func _process(delta: float) -> void:
	character.play_time += delta
	if zone:   # el NPC con el que hablas gesticula (T103)
		zone.talking_npc = _talking_npc if ui.dialogue_box.visible else ""
	_update_combat_music(delta)
	_update_twins(delta)
	_update_challenge(delta)
	_update_waves(delta)
	_update_low_life_bark(delta)
	if not _event_fights.is_empty():
		_update_event_fights()
	_immune_warning = maxf(0.0, _immune_warning - delta)
	_since_save += delta
	if (_dirty and _since_save >= AUTOSAVE_DELAY) or _since_save >= AUTOSAVE_INTERVAL:
		save_now()


## Cerrar la ventana también guarda.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func save_now() -> void:
	if ui and ui.world_map:
		ui.world_map.save_explored()
	GameData.save_character(character)
	if stash:
		stash.save()
	_dirty = false
	_since_save = 0.0


func _mark_dirty() -> void:
	_dirty = true


func _return_to_menu() -> void:
	_close_visit()
	save_now()
	Sfx.ambient("")
	get_tree().paused = false
	GameData.current_character = null
	get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE)


func _quit_game() -> void:
	_close_visit()
	save_now()
	get_tree().quit()


## Apunta la visita a la zona que termina (telemetría local).
func _close_visit() -> void:
	if zone and not _visit.is_empty():
		Telemetry.write(Telemetry.finish(_visit, character, enemies), character)
	_visit = {}


# --- Zonas ---

## Carga una zona y coloca al jugador en la entrada indicada ("" = la primera).
func travel_to(zone_id: String, entry := "") -> void:
	FreezeWatch.mark("viaje: " + zone_id)
	var def: Dictionary = GameData.zones.get(zone_id, {})
	if def.is_empty():
		push_error("Zona desconocida: %s" % zone_id)
		return
	if LoadingCard.enabled:
		# Pantalla de carga (T96): ilustración de la zona, su nombre y un consejo.
		var card := LoadingCard.new()
		card.zone_name = String(def.get("name", zone_id))
		card.subtitle = ("Acto %s  ·  " % def["act"] if def.has("act") else "") + ("Nivel de zona %d" % int(def.get("level", 1)))
		card.style = String(def.get("style", ""))
		add_child(card)
	if not _challenge.is_empty():
		_fail_challenge("Has salido de la zona: la prueba de estrés se cancela.")
	if not _waves.is_empty():
		_end_waves("Sales del banco de oleadas.")
	_close_visit()
	_shop_refreshes = 0
	_twins = {}
	if zone:
		remove_child(zone)
		zone.queue_free()
	enemies.clear_all()
	loot.clear_all()
	zone = Zone.new()
	zone.setup(def, player, character, quests)
	add_child(zone)
	move_child(zone, 0)  # debajo de todo lo demás
	var emitters := AmbientEmitters.new()   # racks, goteo y viento que suenan cerca
	zone.add_child(emitters)
	emitters.setup(zone)
	var weather := Weather.new()   # lluvia de datos o niebla, según el estilo
	zone.add_child(weather)
	weather.setup(zone.style, zone)
	SoundMap.floor_style = zone.style   # pasos según el suelo (T77)
	_sighted.clear()
	post.attach(self, zone)   # el pixelado justo después de la zona; la luz, encima
	post.set_style(zone.style)
	zone.npc_interacted.connect(_on_npc_interacted)
	zone.events.triggered.connect(_on_zone_event)
	zone.events.resolved.connect(_on_zone_event_resolved)
	zone.events.exploded.connect(_on_logic_bomb_exploded)
	zone.events.escort_wave.connect(func(e: Dictionary) -> void:
		ui.hud.flash("¡Emboscada en el camino! Despeja al proceso para que siga.", Color("ff6a5a"))
		_spawn_event_wave(e["walker"], 7, 0.3, 0.08, 240.0))
	zone.events.enemies = enemies
	_event_fights.clear()
	zone.exit_reached.connect(_on_exit_reached)
	zone.quest_item_picked.connect(_on_quest_item_picked)
	zone.key_item_picked.connect(_on_key_item_picked)
	zone.lore_picked.connect(_on_lore_picked)
	zone.challenge_touched.connect(_on_challenge_touched)
	zone.exit_blocked.connect(func(e: Dictionary) -> void: ui.hud.flash(zone.exit_blocked_reason(e), Color("e06c6c")))
	zone.waypoint_clicked.connect(func() -> void: ui.open_waypoints(zone.id))
	zone.stash_clicked.connect(func() -> void: ui.open_stash(stash))
	zone.waypoint_touched.connect(_discover_waypoint)

	player.global_position = zone.entry_point(entry)
	player.stop_auto_move()
	_refresh_companion()
	var cam := player.get_node("Camera2D") as Camera2D
	cam.limit_left = int(zone.rect.position.x - 200)
	cam.limit_top = int(zone.rect.position.y - 200)
	cam.limit_right = int(zone.rect.end.x + 200)
	cam.limit_bottom = int(zone.rect.end.y + 200)
	cam.reset_smoothing()

	var difficulty := Difficulty.current(character)
	enemies.difficulty = difficulty
	enemies.area_level = Difficulty.zone_level(character, zone.level, String(GameData.act_of_zone(zone.id).get("id", zone.def.get("act", ""))), zone.safe)
	enemies.forced_affixes = Incidents.forced_affixes(zone.def)
	var incident_mods := Incidents.player_mods(zone.def)
	if incident_mods.is_empty():
		character.remove_timed_effect("incident")
	else:
		character.set_timed_effect("incident", incident_mods)
	enemies.aggro_range = float(zone.def.get("aggro_range", EnemyManager.AGGRO_RANGE))
	enemies.bounds = zone.rect
	enemies.walk_clamp = zone.clamp_to_walkable
	enemies.obstacles.clear()
	for o in zone.obstacles:
		enemies.obstacles.append(Vector3(o["pos"].x, o["pos"].y, o["radius"]))
	_spawn_zone_enemies()
	_visit = Telemetry.begin(character, enemies, zone.id, enemies.area_level)
	skills.on_zone_changed()

	character.flags["zone"] = zone.id
	_check_achievements()
	ui.on_zone_changed(zone)
	quests.notify_zone(zone.id)
	_mark_dirty()
	Sfx.ambient(String(zone.def.get("style", "ruins")))
	Sfx.play("portal", -8.0)
	_boss_phase = 0
	MusicPlayer.set_intensity(0)
	MusicPlayer.play_zone(String(zone.def.get("incident", {}).get("from", zone.id)))   # el incidente suena como su zona
	_check_zone_cutscene.call_deferred()


## Escena al entrar en la zona (una sola vez, según sus banderas).
func _check_zone_cutscene() -> void:
	var c: Dictionary = zone.def.get("cutscene_on_enter", {}) if zone.def.get("cutscene_on_enter") is Dictionary else {}
	if c.is_empty():
		return
	if c.has("requires_flag") and not character.flags.has(c["requires_flag"]):
		return
	if c.has("unless_flag") and character.flags.has(c["unless_flag"]):
		return
	if c.has("set_flag"):
		character.flags[c["set_flag"]] = true
	play_cutscene(c["id"])


# --- Escenas ---

func play_cutscene(id: String) -> void:
	var data: Dictionary = GameData.cutscenes.get(id, {})
	if data.is_empty():
		push_warning("Escena desconocida: %s" % id)
		return
	player.stop_auto_move()
	enemies.frozen = true
	ui.play_cutscene(data, func() -> void: _on_cutscene_finished(data.get("on_finish", {})))


func _on_cutscene_finished(on_finish: Dictionary) -> void:
	enemies.frozen = false
	if on_finish.has("set_flag"):
		character.flags[on_finish["set_flag"]] = true
		quests.refresh()
		_mark_dirty()
	if on_finish.has("travel"):
		var t: Dictionary = on_finish["travel"]
		travel_to(t.get("zone", ""), t.get("entry", ""))


func _on_exit_reached(e: Dictionary) -> void:
	if e.has("cutscene"):
		play_cutscene(e["cutscene"])   # la escena decide a dónde se viaja
		return
	if e["target"] == "" or not GameData.zones.has(e["target"]):
		ui.hud.flash(e.get("message", "Esta salida todavía no lleva a ningún sitio."), Color("c08aff"))
		return
	travel_to.call_deferred(e["target"], e["entry"])


func _on_quest_item_picked(q: Dictionary) -> void:
	character.flags["item_" + String(q["id"])] = true
	ui.hud.flash("Objeto de misión: %s" % q["name"], UiStyle.ACCENT)
	quests.refresh()
	_mark_dirty()
	if q.has("cutscene"):
		play_cutscene(q["cutscene"])


## Logros (Achievements): al conseguir uno, aviso con su cosmético.
func _check_achievements() -> void:
	for def in Achievements.check(character):
		ui.hud.flash("¡Logro: %s! Premio: %s (Pausa → Logros y cosméticos)." % [def["name"], Achievements.COSMETICS[def["reward"][0]][def["reward"][1]]], Color("ffd24a"))
		Sfx.play("level_up", -6.0, 1.4)


## Incidente (Incidents): al azar, o el de un mapa (`map`: {zone, mods}). Usa el
## nivel del atlas (Atlas) para su dificultad y su botín.
func open_incident(map: Dictionary = {}) -> void:
	var def := Incidents.build(GameData.zones, character.level, GameData.town_for_zone(zone.id), _rng, -1,
		String(map.get("zone", "")), map.get("mods", []), Atlas.level_bonus(character), Atlas.loot_bonus(character))
	if def.is_empty():
		ui.hud.flash("No hay incidentes para tu nivel todavía.", Color("e0a060"))
		return
	GameData.zones[Incidents.ZONE_ID] = def
	travel_to(Incidents.ZONE_ID, "")
	ui.hud.flash("%s · nivel %d (+%d %% de botín)\n%s\nLimpia la zona para completarlo en el atlas." % [def["name"], int(def["level"]),
		roundi((float(def["drop_multiplier"]) - 1.0) * 100.0), Incidents.describe(def)], Color("ff8a5a"))


## Incidente limpio: se marca en el atlas, suelta un mapa y un botín extra.
func _check_incident_done() -> void:
	if zone == null or zone.id != Incidents.ZONE_ID or zone.def.get("incident_done", false) or enemies.count() > 0:
		return
	zone.def["incident_done"] = true
	var src := String(zone.def["incident"]["from"])
	var up := Atlas.mark_done(character, src)
	var m := Atlas.roll_map(GameData.zones, character.level, Atlas.tier(character), _rng)
	var got_map := not m.is_empty() and Atlas.add_map(character, m)
	for k in 3:
		loot.drop_item(item_generator.roll_drop(enemies.area_level, 2.0), zone.free_spot_near(player.global_position + Vector2.from_angle(TAU * k / 3.0) * 80.0))
	ui.hud.flash("Incidente resuelto. %s%s" % ["¡El atlas sube a nivel %d! " % Atlas.tier(character) if up else "",
		("Nuevo %s en el atlas." % m["name"]) if got_map else ""], Color("6fd36b"))
	Sfx.play("level_up", -4.0, 1.1)
	_mark_dirty()


## Mejoras del campamento (se abren al terminar cada acto): puesto de Aida,
## mesa de crafteo de Mario y antena de Rafa.
const CAMP_ANTENNA_SECONDS := 180.0
var _gear_stock: Array[Item] = []
var _gear_level := -1


## Mesa de Mario: el arma equipada sale con afijos nuevos (misma base, nivel y rareza).
func _reforge_weapon() -> void:
	var weapon: Item = character.inventory.equipped("weapon")
	if not Economy.can_reforge(weapon):
		ui.hud.flash("Mario: «Eso no se puede reforjar». Hace falta un arma mágica o rara equipada.", Color("e0a060"))
		return
	var cost := Economy.reforge_price(weapon)
	if not character.spend_tokens(cost):
		ui.hud.flash("Mario: «Son %d fichas. Yo también tengo que comer». Te faltan %d." % [cost, cost - character.tokens], Color("e0a060"))
		return
	var fresh := item_generator.generate(weapon.item_level, weapon.rarity, String(weapon.base.get("id", "")))
	character.inventory.set_equipped("weapon", fresh)
	character.recalculate()
	ui.hud.flash("Mario reforjó tu arma (%d fichas): %s." % [cost, fresh.display_name()], Color("8fe08a"))
	Sfx.play("coin")
	_mark_dirty()


## El acompañante (Companions): su bono y, en las zonas de combate, el que te sigue.
## En los campamentos se queda en su sitio como NPC.
var _companion_node: CompanionFollower


func _refresh_companion() -> void:
	Companions.apply(character)
	var id := Companions.current(character)
	var want := id != "" and zone != null and not zone.safe
	if _companion_node and (not want or _companion_node.npc_id != id):
		_companion_node.queue_free()
		_companion_node = null
	if want and _companion_node == null:
		_companion_node = CompanionFollower.new()
		add_child(_companion_node)
		_companion_node.setup(player, id)


func _on_lore_picked(n: Dictionary) -> void:
	if not LoreNotes.mark_found(character, String(n["id"])):
		return
	ui.hud.flash("%s encontrado: «%s» (%d/%d). Léelo en Pausa → Archivos encontrados." % [LoreNotes.KIND_NAMES.get(n["kind"], "Archivo"),
		n["title"], LoreNotes.found_ids(character).size(), LoreNotes.all().size()], LoreNotes.KIND_COLORS.get(n["kind"], UiStyle.ACCENT))
	Sfx.play("pickup")
	_mark_dirty()


func _on_key_item_picked(k: Dictionary) -> void:
	var key := KeyItem.new(k["id"])
	if not character.inventory.add_item(key):
		ui.hud.flash("Bolsa llena: haz sitio para %s." % key.display_name())
		return
	character.flags["got_key_" + String(k["id"])] = true
	ui.hud.flash("Objeto clave: %s. %s" % [key.display_name(), key.description()], KeyItem.COLOR)
	_mark_dirty()


func _spawn_zone_enemies() -> void:
	var cfg: Dictionary = zone.def.get("enemies", {}) if zone.def.get("enemies") is Dictionary else {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if not cfg.is_empty():
		var type_ids: Array = cfg.get("types", [])
		var size_range: Array = cfg.get("pack_size", [3, 6])
		for center in zone.pack_centers(int(cfg.get("packs", 0)), rng, float(cfg.get("keep_away", 0.0))):
			var type := enemies.type_index_of(type_ids[rng.randi_range(0, type_ids.size() - 1)]) if not type_ids.is_empty() else -1
			var pack := rng.randi_range(int(size_range[0]), int(size_range[1]))
			var pack_ids: Array[int] = []
			for k in pack:
				var rarity := Rarity.Enemy.NORMAL
				if k == 0 and rng.randf() < float(cfg.get("elite_chance", 0.0)):
					rarity = Rarity.Enemy.ELITE
				elif rng.randf() < float(cfg.get("special_chance", 0.0)):
					rarity = Rarity.Enemy.SPECIAL
				var p := zone.free_spot_near(center + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)))
				pack_ids.append(enemies.spawn(p, rarity, type))
			_assign_role(pack_ids, center, type, cfg, rng)
	_spawn_zone_specials()
	_boss_alive = false
	var boss: Dictionary = zone.def.get("boss", {}) if zone.def.get("boss") is Dictionary else {}
	if not boss.is_empty() and not character.flags.has(Difficulty.boss_flag(boss.get("complete_flag", "act1_complete"), Difficulty.current(character))):
		enemies.spawn(Zone._v(boss["pos"]), Rarity.Enemy.UNIQUE, enemies.type_index_of(boss.get("type", "daemon")),
			boss.get("name", ""), float(boss.get("life_mult", 1.0)), boss.get("abilities", []))
		enemies.set_phases(enemies.ids[enemies.ids.size() - 1], boss.get("phases", []))
		_boss_alive = true
		_boss_started = character.play_time


## Roles en las manadas (desde el nivel de zona 2): a veces un guardián, un
## sanador o un francotirador entre los normales, o un enjambre que se suma.
## La zona puede limitarlos con enemies.roles (lista) y role_chance.
const ROLE_CHANCE := 0.4
const SWARM_SIZE := 4
const ELITE_ROLE_CHANCE := 0.35


func _assign_role(pack_ids: Array[int], center: Vector2, type: int, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	if zone.level < 2 or rng.randf() >= float(cfg.get("role_chance", ROLE_CHANCE)):
		return
	var allowed: Array = cfg.get("roles", EnemyManager.ROLES)
	if allowed.is_empty():
		return
	var role := String(allowed[rng.randi_range(0, allowed.size() - 1)])
	if role == "swarm":
		for k in SWARM_SIZE:
			var p := zone.free_spot_near(center + Vector2.from_angle(TAU * k / SWARM_SIZE) * 90.0)
			enemies.set_role(enemies.spawn(p, Rarity.Enemy.NORMAL, type), "swarm")
		return
	# A veces el rol va al élite que encabeza la manada (con su rol en el nombre);
	# si no, a un normal.
	if rng.randf() < ELITE_ROLE_CHANCE:
		for id in pack_ids:
			var i := enemies.index_of(id)
			if i != -1 and enemies.rarities[i] == Rarity.Enemy.ELITE:
				enemies.set_role(id, role)
				return
	for id in pack_ids:
		var i := enemies.index_of(id)
		if i != -1 and enemies.rarities[i] != Rarity.Enemy.ELITE:
			enemies.set_role(id, role)
			return


## Némesis (Nemesis): el élite que te mató vuelve, con tu nombre y más fuerte.
func _spawn_nemesis() -> void:
	if zone.safe or zone.def.has("boss") or not zone.def.get("enemies") is Dictionary:
		return
	if not Nemesis.should_spawn(character, zone.id, String(GameData.act_of_zone(zone.id).get("id", "")), _rng.randf()):
		return
	var n := Nemesis.current(character)
	var r := zone.rect
	var p := zone.free_spot_near(Vector2(_rng.randf_range(r.position.x + r.size.x * 0.4, r.end.x - 200.0), _rng.randf_range(r.position.y + 200.0, r.end.y - 200.0)))
	var id := enemies.spawn(p, Rarity.Enemy.ELITE, enemies.type_index_of(String(n.get("type", "bug"))), Nemesis.title(character), Nemesis.life_mult(character),
		[], n.get("affixes", []))
	var i := enemies.index_of(id)
	if i != -1:
		enemies.traits[i]["nemesis"] = true
		enemies.damages[i] *= 1.0 + 0.15 * int(n.get("kills", 1))
	ui.hud.flash("Tu némesis está en esta zona: %s." % Nemesis.title(character), Color("e0503a"))


func _on_nemesis_killed(pos: Vector2) -> void:
	Nemesis.defeated(character)
	for k in 4:
		loot.drop_item(item_generator.roll_drop(enemies.area_level, 3.0 if k < 2 else 1.5), zone.free_spot_near(pos + Vector2.from_angle(TAU * k / 4.0) * 70.0))
	loot.drop_tokens(maxi(10, Economy.drop_amount(enemies.area_level, Rarity.Enemy.UNIQUE, _rng)), zone.free_spot_near(pos))
	ui.hud.flash("¡Venganza! Tu némesis cayó: botín de sobra.", Color("ffd24a"))
	Sfx.play("level_up", -4.0, 0.9)
	_mark_dirty()


## Subjefes, candados y enemigos raros definidos en la zona.
func _spawn_zone_specials() -> void:
	_spawn_nemesis()
	var rc: Dictionary = zone.def.get("race_condition", {}) if zone.def.get("race_condition") is Dictionary else {}
	if not rc.is_empty() and not character.flags.has(rc.get("flag", "")):
		var p := Zone._v(rc["pos"])
		var names: Array = rc.get("names", ["Hilo Alfa", "Hilo Beta"])
		var t := enemies.type_index_of("hilo_gemelo")
		var a := enemies.spawn(p + Vector2(0, -90), Rarity.Enemy.UNIQUE, t, names[0], float(rc.get("life_mult", 4.0)))
		var b := enemies.spawn(p + Vector2(0, 90), Rarity.Enemy.UNIQUE, t, names[1], float(rc.get("life_mult", 4.0)))
		# Cada gemelo con sus fases (y su barra de jefe mientras pelea).
		enemies.set_phases(a, rc.get("phases", []))
		enemies.set_phases(b, rc.get("phases", []))
		enemies.set_immune(b, true)
		_twins = {"ids": [a, b], "names": names, "turn": 0, "timer": float(rc.get("swap", 4.0)),
			"swap": float(rc.get("swap", 4.0)), "flag": rc.get("flag", ""), "pos": p}
	var mx: Dictionary = zone.def.get("mutex", {}) if zone.def.get("mutex") is Dictionary else {}
	if not mx.is_empty() and not character.flags.has(mx.get("flag", "")):
		for pos in mx.get("positions", []):
			enemies.spawn(Zone._v(pos), Rarity.Enemy.ELITE, enemies.type_index_of("mutex_lock"), "Candado Mutex")
	for r in zone.def.get("rare_spawns", []):
		if r.has("requires_flag") and not character.flags.has(r["requires_flag"]):
			continue
		if r.has("unless_flag") and character.flags.has(r["unless_flag"]):
			continue
		var rid := enemies.spawn(Zone._v(r["pos"]), Rarity.Enemy.UNIQUE, enemies.type_index_of(r["type"]), r.get("name", ""), float(r.get("life_mult", 1.0)))
		enemies.set_phases(rid, r.get("phases", []))   # subjefes raros con fases y barra


# --- Carrera Crítica: los gemelos se turnan la vulnerabilidad ---

func _update_twins(delta: float) -> void:
	if _twins.is_empty() or enemies.frozen:
		return
	var ids: Array = _twins["ids"]
	var alive := ids.filter(func(id: int) -> bool: return enemies.is_alive_id(id))
	if alive.is_empty():
		character.flags[_twins["flag"]] = true
		var p: Vector2 = _twins["pos"]
		for r in [Rarity.Item.UNIQUE, Rarity.Item.RARE, Rarity.Item.RARE]:
			loot.drop_item(item_generator.generate(enemies.area_level, r), zone.free_spot_near(p + Vector2(randf_range(-80, 80), randf_range(-60, 60))))
		ui.hud.flash("Carrera Crítica resuelta: ya no hay condición de carrera. La compuerta se abre.", UiStyle.ACCENT)
		_twins = {}
		quests.refresh()
		save_now()
		return
	if alive.size() == 1:
		enemies.set_immune(alive[0], false)   # sin rival, ya no hay turnos
		return
	_twins["timer"] -= delta
	if _twins["timer"] <= 0.0:
		_twins["timer"] = _twins["swap"]
		_twins["turn"] = 1 - int(_twins["turn"])
		for k in 2:
			enemies.set_immune(ids[k], k != int(_twins["turn"]))
		ui.hud.flash("¡Cambio de turno! Ahora es vulnerable: %s" % _twins["names"][_twins["turn"]], Color("8ab0e0"))


func _on_immune_hit(_pos: Vector2) -> void:
	if _immune_warning > 0.0 or _twins.is_empty():
		return
	_immune_warning = 2.5
	ui.hud.flash("¡Fuera de turno! Ese hilo es inmune: ataca a %s." % _twins["names"][_twins["turn"]], Color("8ab0e0"))


# --- Pruebas de estrés (oleadas) ---

func _on_challenge_touched(c: Dictionary) -> void:
	if not _challenge.is_empty() or ui.cutscene.is_playing():
		return
	if not _challenge_previews.has(c["id"]):
		_challenge_previews[c["id"]] = _make_challenge_rewards(c)
	var rewards: Array = _challenge_previews[c["id"]]
	player.stop_auto_move()
	for con in ui.challenge_panel.accepted.get_connections():
		ui.challenge_panel.accepted.disconnect(con["callable"])
	ui.challenge_panel.accepted.connect(func() -> void: _start_challenge(c, rewards), CONNECT_ONE_SHOT)
	ui.challenge_panel.open(c, rewards)


func _make_challenge_rewards(c: Dictionary) -> Array:
	var level := enemies.area_level + 2
	var result: Array = []
	for r in c.get("rewards", ["rare"]):
		match String(r):
			"ram":
				result.append(item_generator.generate_ram(level))
			"flask":
				var f := item_generator.generate_flask(level)
				if f:
					result.append(f)
			"board":
				result.append(item_generator.generate_motherboard(level, "", 5))
			_:
				result.append(item_generator.generate(level, RARITY_BY_NAME.get(r, Rarity.Item.RARE)))
	return result


func _start_challenge(c: Dictionary, rewards: Array) -> void:
	_challenge = {"def": c, "wave": 0, "total": int(c.get("waves", 4)), "ids": [], "next_in": 1.5, "rewards": rewards}
	zone.active_challenge = c
	ui.hud.flash("¡Prueba de estrés iniciada! Resiste %d oleadas." % _challenge["total"], Color("ff9a4a"))
	MusicPlayer.play_track(STRESS_TRACK, 1.0)


func _update_challenge(delta: float) -> void:
	if _challenge.is_empty() or enemies.frozen:
		return
	if not player.is_alive():
		_fail_challenge("Has caído: la prueba de estrés se reinicia. Puedes volver a intentarlo.")
		return
	var ids: Array = _challenge["ids"]
	_challenge["ids"] = ids.filter(func(id: int) -> bool: return enemies.is_alive_id(id))
	var left: int = _challenge["ids"].size()
	if left > 0:
		ui.set_wave_text("PRUEBA DE ESTRÉS · Oleada %d/%d · Enemigos: %d" % [_challenge["wave"], _challenge["total"], left])
		return
	if _challenge["wave"] >= _challenge["total"]:
		_complete_challenge()
		return
	_challenge["next_in"] -= delta
	ui.set_wave_text("PRUEBA DE ESTRÉS · Oleada %d/%d en %d…" % [_challenge["wave"] + 1, _challenge["total"], ceili(maxf(0.0, _challenge["next_in"]))])
	if _challenge["next_in"] <= 0.0:
		_challenge["wave"] += 1
		_challenge["next_in"] = 2.5
		_spawn_wave(_challenge["def"], _challenge["wave"], _challenge["total"])


func _spawn_wave(c: Dictionary, wave: int, total: int) -> void:
	var center: Vector2 = c["pos"]
	var types: Array = c.get("types", ["bug"])
	var count := 5 + wave * 3
	for k in count:
		var rarity := Rarity.Enemy.NORMAL
		if wave == total and k < 2:
			rarity = Rarity.Enemy.ELITE
		elif randf() < 0.1 + 0.06 * wave:
			rarity = Rarity.Enemy.SPECIAL
		var p := zone.free_spot_near(center + Vector2.from_angle(TAU * k / count + randf() * 0.3) * randf_range(280.0, 460.0))
		_challenge["ids"].append(enemies.spawn(p, rarity, enemies.type_index_of(types[randi() % types.size()])))
	ui.hud.flash("Oleada %d de %d" % [wave, total], Color("ff9a4a"))
	Sfx.play("wave")


func _complete_challenge() -> void:
	var c: Dictionary = _challenge["def"]
	var center: Vector2 = c["pos"]
	character.flags["challenge_done_" + String(c["id"])] = true
	character.flags["challenge_any_done"] = true
	for item: Item in _challenge["rewards"]:
		loot.drop_item(item, zone.free_spot_near(center + Vector2(randf_range(-60, 60), randf_range(40, 90))))
	# Botín adicional: más cuantas más oleadas.
	for k in 3 + int(_challenge["total"]):
		loot.drop_item(item_generator.roll_drop(enemies.area_level, 0.4), zone.free_spot_near(center + Vector2(randf_range(-120, 120), randf_range(-60, 120))))
	ui.hud.flash("¡Prueba de estrés superada! El servidor aguantó. Y tú también.", Color("6fd36b"))
	_challenge = {}
	_challenge_previews.erase(c["id"])
	zone.active_challenge = {}
	ui.set_wave_text("")
	_restore_zone_music()
	quests.refresh()
	save_now()


func _fail_challenge(message: String) -> void:
	_challenge = {}
	if zone:
		zone.active_challenge = {}
		_restore_zone_music()
	ui.set_wave_text("")
	ui.hud.flash(message, Color("e06c6c"))


## Música de las pruebas de estrés y del banco de oleadas (data/music.json → estres).
const STRESS_TRACK := "estres"


## Al acabar una prueba u oleadas: vuelve la música de la zona (la del incidente, la de su zona de origen).
func _restore_zone_music() -> void:
	if zone and MusicPlayer.current_track() == STRESS_TRACK:
		MusicPlayer.play_zone(String(zone.def.get("incident", zone.def.get("waves_mode", {})).get("from", zone.id)))


# --- Banco de oleadas sin fin y récords (Ladder) ---

func open_waves() -> void:
	var def := Ladder.build_arena(GameData.zones, character.level, GameData.town_for_zone(zone.id), _rng)
	if def.is_empty():
		ui.hud.flash("Todavía no hay ninguna zona para el banco de oleadas.", Color("e0a060"))
		return
	GameData.zones[Ladder.ZONE_ID] = def
	travel_to(Ladder.ZONE_ID, "")
	_waves = {"wave": 0, "ids": [], "next_in": 3.0, "time": 0.0, "base_level": enemies.area_level}
	MusicPlayer.play_track(STRESS_TRACK, 1.5)
	var best := int(Ladder.personal(character).get("best_wave", 0))
	ui.hud.flash("%s\nOleadas sin fin: aguanta todo lo que puedas.%s" % [def["name"], " Tu récord: %d." % best if best > 0 else ""], Color("ff9a4a"))


func _update_waves(delta: float) -> void:
	if _waves.is_empty() or enemies.frozen or zone == null or zone.id != Ladder.ZONE_ID:
		return
	_waves["time"] += delta
	var ids: Array = _waves["ids"]
	_waves["ids"] = ids.filter(func(id: int) -> bool: return enemies.is_alive_id(id))
	var left: int = _waves["ids"].size()
	var clock := Ladder.format_time(_waves["time"])
	if left > 0:
		ui.set_wave_text("OLEADAS · %d · Enemigos: %d · %s" % [_waves["wave"], left, clock])
		return
	if _waves["wave"] > 0 and _waves.get("cleared", 0) < _waves["wave"]:
		_waves["cleared"] = _waves["wave"]
		if Ladder.wave_plan(_waves["wave"])["boss"]:   # botín por cada jefe de oleada
			for k in 2:
				loot.drop_item(item_generator.roll_drop(enemies.area_level, 1.0), zone.free_spot_near(player.global_position + Vector2.from_angle(PI * k) * 70.0))
	_waves["next_in"] -= delta
	ui.set_wave_text("OLEADAS · %d en %d… · %s" % [_waves["wave"] + 1, ceili(maxf(0.0, _waves["next_in"])), clock])
	if _waves["next_in"] <= 0.0:
		_waves["wave"] += 1
		_waves["next_in"] = 3.0
		_spawn_endless_wave(_waves["wave"])


func _spawn_endless_wave(wave: int) -> void:
	var plan := Ladder.wave_plan(wave)
	enemies.area_level = int(_waves["base_level"]) + int(plan["level_bonus"])
	var types: Array = zone.def.get("enemies", {}).get("types", [])
	var center := player.global_position
	var count := int(plan["count"])
	for k in count:
		var rarity := Rarity.Enemy.NORMAL
		if k < int(plan["elites"]):
			rarity = Rarity.Enemy.ELITE
		elif _rng.randf() < float(plan["special_chance"]):
			rarity = Rarity.Enemy.SPECIAL
		var type := enemies.type_index_of(types[_rng.randi_range(0, types.size() - 1)]) if not types.is_empty() else -1
		var p := zone.free_spot_near(center + Vector2.from_angle(TAU * k / count + _rng.randf() * 0.3) * _rng.randf_range(300.0, 480.0))
		_waves["ids"].append(enemies.spawn(p, rarity, type))
	if plan["boss"]:
		var type := enemies.type_index_of(types[_rng.randi_range(0, types.size() - 1)]) if not types.is_empty() else -1
		_waves["ids"].append(enemies.spawn(zone.free_spot_near(center + Vector2(0, -360)), Rarity.Enemy.UNIQUE, type,
			"Jefe de oleada %d" % wave, Ladder.boss_life_mult(wave)))
	ui.hud.flash("Oleada %d%s" % [wave, " · ¡jefe de oleada!" if plan["boss"] else ""], Color("ff9a4a"))
	Sfx.play("wave")


## Fin de la partida de oleadas (caída o salida): récord personal y tabla local.
func _end_waves(reason: String) -> void:
	var done := int(_waves.get("cleared", 0))
	var seconds := float(_waves["time"])
	_waves = {}
	ui.set_wave_text("")
	_restore_zone_music()
	if done <= 0:
		return
	var best := Ladder.record_waves(character, done, seconds)
	var board := Ladder.load_board()
	var rank := Ladder.submit_waves(board, Ladder.entry(character, done, seconds))
	Ladder.save_board(board)
	ui.hud.flash("%s %d oleadas en %s.%s%s" % [reason, done, Ladder.format_time(seconds), " ¡Récord personal!" if best else "",
		" Puesto %d en la tabla local." % rank if rank > 0 else ""], Color("ffd24a") if best else Color("ff9a4a"))
	_mark_dirty()


func _record_boss_time(boss_id: String, seconds: float) -> void:
	var best := Ladder.record_boss(character, boss_id, seconds)
	var board := Ladder.load_board()
	var rank := Ladder.submit_boss(board, boss_id, Ladder.entry(character, 0, seconds))
	Ladder.save_board(board)
	if best:
		ui.hud.flash("Récord contra este jefe: %s.%s" % [Ladder.format_time(seconds), " Puesto %d en la tabla local." % rank if rank > 0 else ""], Color("ffd24a"))


func _discover_waypoint() -> void:
	var found: Array = character.flags.get("waypoints", [])
	if not found.has(zone.id):
		found.append(zone.id)
		character.flags["waypoints"] = found
		ui.hud.flash("Waypoint descubierto: %s. Ya puedes viajar aquí." % zone.zone_name, Color("5cd0ff"))
		_mark_dirty()


func _on_player_died() -> void:
	skills.clear_auras()
	if not _waves.is_empty():
		_end_waves("Caíste en el banco de oleadas.")
	character.flags["stat_deaths"] = int(character.flags.get("stat_deaths", 0)) + 1
	if zone and Nemesis.record(character, enemies.last_hitter, zone.id, String(GameData.act_of_zone(zone.id).get("id", "")), Time.get_ticks_msec()):
		ui.hud.flash("%s te recordará. Y tú a él: ahora es tu némesis." % Nemesis.current(character).get("name", "Ese élite"), Color("e0503a"))
	ui.show_death()
	_mark_dirty()


## Al reaparecer se vuelve al campamento (como en PoE, al último pueblo).
func respawn() -> void:
	player.refill()
	ui.hide_death()
	travel_to(GameData.town_for_zone(zone.id if zone else ""), "waypoint")


func _unhandled_input(event: InputEvent) -> void:
	# Mando: A es contextual. Con un objeto, un NPC, el waypoint o el alijo cerca,
	# los usa; si no, es la habilidad 1 (SkillController la lee aparte).
	var pad := event as InputEventJoypadButton
	if pad and pad.pressed and pad.button_index == JOY_BUTTON_A and player.is_alive():
		if loot.pick_near(player.global_position, Gamepad.INTERACT_RANGE) or zone.interact_near(player.global_position, Gamepad.INTERACT_RANGE):
			Gamepad.block_skill_1()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"debug_spawn_wave"):
		for k in 30:
			enemies.spawn(zone.free_spot_near(player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(300, 600)),
				Rarity.Enemy.NORMAL)
	elif event.is_action_pressed(&"debug_clear_enemies"):
		enemies.clear_all()
	elif event.is_action_pressed(&"debug_spawn_boss"):
		enemies.spawn(zone.free_spot_near(player.global_position + Vector2(450, 0)), Rarity.Enemy.UNIQUE)
	elif event.is_action_pressed(&"debug_drop_items"):
		drop_test_loot()
	elif event.is_action_pressed(&"respawn") and not player.is_alive():
		respawn()


## Una muestra de cada rareza alrededor del jugador, para probar la UI.
func drop_test_loot() -> void:
	var item_level := enemies.area_level
	var rarities := [Rarity.Item.NORMAL, Rarity.Item.MAGIC, Rarity.Item.RARE, Rarity.Item.RARE,
		Rarity.Item.UNIQUE, Rarity.Item.SET, Rarity.Item.ULTRA_RARE]
	var items: Array[Item] = []
	for r in rarities:
		items.append(item_generator.generate(item_level, r))
	items.append(item_generator.generate_motherboard(item_level, "", 6))
	items.append(item_generator.generate_ram(item_level))
	items.append(item_generator.generate_ram(item_level))
	for i in items.size():
		var offset := Vector2.from_angle(TAU * i / items.size()) * 140.0
		loot.drop_item(items[i], player.global_position + offset)


# --- Eventos de zona (ZoneEvents) ---

## Peleas de evento en curso: {event, ids: Array[int], waves_left, reward}.
var _event_fights: Array[Dictionary] = []


func _on_zone_event(e: Dictionary) -> void:
	var p: Vector2 = e["pos"]
	match String(e["kind"]):
		"shrine":
			var info: Dictionary = ZoneEvents.SHRINES[e["shrine"]]
			if e["shrine"] == "overclock":
				for t in Charges.TYPES:
					for k in character.max_charges(t):
						character.gain_charge(t)
			else:
				var mods: Array[Modifier] = []
				for md in info["mods"]:
					mods.append(Modifier.from_dict(md, "shrine"))
				character.add_timed_effect("shrine:" + String(e["shrine"]), mods, ZoneEvents.SHRINE_SECONDS)
			ui.hud.flash(info["text"], Color(info["color"]))
			Sfx.play("aura_on", -2.0, 1.2)
		"cache":
			ui.hud.flash("¡Datos huérfanos! Sus dueños vienen a reclamarlos: aguanta dos oleadas.", Color("f2c14e"))
			Sfx.play("wave")
			_event_fights.append({"event": e, "ids": _spawn_event_wave(p, 9, 0.25, 0.0), "waves_left": 1, "reward": 3})
		"ambush":
			ui.hud.flash("¡Emboscada! Era un honeypot.", Color("ff6a5a"))
			Sfx.play("wave")
			var ids := _spawn_event_wave(player.global_position, 12, 0.2, 0.12, 320.0)
			_event_fights.append({"event": e, "ids": ids, "waves_left": 0, "reward": 1})
		"deploy":
			ui.hud.flash("Deploy fallido: dos procesos raros se escaparon a producción.", Color("ff6a5a"))
			Sfx.play("wave")
			var ids := _spawn_event_wave(p, 4, 0.0, 0.0)
			var cfg: Dictionary = zone.def.get("enemies", {})
			var types: Array = cfg.get("types", [])
			for k in 2:
				var t := enemies.type_index_of(types[randi() % types.size()]) if not types.is_empty() else -1
				ids.append(enemies.spawn(zone.free_spot_near(p + Vector2.from_angle(PI * k) * 90.0), Rarity.Enemy.ELITE, t))
			_event_fights.append({"event": e, "ids": ids, "waves_left": 0, "reward": 3})
		"bombs":
			ui.hud.flash("¡Bombas lógicas! Quédate junto a cada una para desactivarla antes de %d s." % int(ZoneEvents.BOMB_TIME), Color("ff9a3a"))
			Sfx.play("wave")
			_spawn_event_wave(p, 8, 0.25, 0.05, 260.0)
		"escort":
			ui.hud.flash("Un proceso perdido quiere llegar a su salida. Solo avanza si estás cerca y no hay enemigos a su lado.", Color("8ad8ff"))
			Sfx.play("aura_on", -4.0, 1.1)
		"merchant":
			var price := zone.events.merchant_price(e)
			if character.spend_tokens(price):
				e["state"] = "done"
				loot.drop_item(item_generator.roll_drop(enemies.area_level, 2.5), zone.free_spot_near(p + Vector2(0, 60)))
				ui.hud.flash("«Sin devoluciones.» Pagaste %d fichas: el objeto misterioso está en el suelo." % price, Color("f2c14e"))
				Sfx.play("coin")
			else:
				e["state"] = "ready"
				ui.hud.flash("«Vuelve cuando tengas %d fichas.» Te faltan %d." % [price, price - character.tokens], Color("e0a060"))


## Bombas o escolta terminadas: buen botín si salió bien, un consuelo si no.
func _on_zone_event_resolved(e: Dictionary, success: bool) -> void:
	var at: Vector2 = e.get("walker", e["pos"]) if e["kind"] == "escort" else e["pos"]
	var count := 3 if success else 1
	for k in count:
		loot.drop_item(item_generator.roll_drop(enemies.area_level, 1.5 if success and k == 0 else 0.5), zone.free_spot_near(at + Vector2.from_angle(TAU * k / count) * 70.0))
	if success:
		loot.drop_tokens(Economy.drop_amount(enemies.area_level, Rarity.Enemy.ELITE, _rng) * 2, zone.free_spot_near(at))
		ui.hud.flash("¡Bombas desactivadas!" if e["kind"] == "bombs" else "El proceso llegó a su salida: exit code 0.", Color("6fd36b"))
		Sfx.play("level_up", -6.0, 1.3)
	else:
		ui.hud.flash("Las bombas lógicas estallaron. Algo se salvó entre los escombros.", Color("ff6a5a"))


## Una bomba lógica sin desactivar: explota y hace mucho daño si estás cerca.
func _on_logic_bomb_exploded(pos: Vector2) -> void:
	Sfx.play("explosion", -2.0)
	if player.is_alive() and player.global_position.distance_to(pos) <= ZoneEvents.BOMB_BLAST:
		player.take_damage(player.max_life() * 0.35)
	skills._effects.append({"type": "burst", "pos": pos, "radius": ZoneEvents.BOMB_BLAST, "time": 0.0, "duration": 0.5, "color": Color("ff9a3a")})


## Una oleada alrededor de `center`: `count` enemigos de los tipos de la zona.
func _spawn_event_wave(center: Vector2, count: int, magic_chance: float, rare_chance: float, ring := 160.0) -> Array[int]:
	var cfg: Dictionary = zone.def.get("enemies", {})
	var types: Array = cfg.get("types", [])
	var ids: Array[int] = []
	for k in count:
		var rarity := Rarity.Enemy.NORMAL
		if randf() < rare_chance:
			rarity = Rarity.Enemy.ELITE
		elif randf() < magic_chance:
			rarity = Rarity.Enemy.SPECIAL
		var t := enemies.type_index_of(types[randi() % types.size()]) if not types.is_empty() else -1
		var q := center + Vector2.from_angle(TAU * k / count + randf() * 0.4) * ring * randf_range(0.8, 1.2)
		ids.append(enemies.spawn(zone.free_spot_near(q), rarity, t))
	return ids


## Comprueba cada fotograma si se limpió una pelea de evento (siguiente oleada o botín).
func _update_event_fights() -> void:
	for f in _event_fights.duplicate():
		var alive: Array = f["ids"].filter(func(id: int) -> bool: return enemies.index_of(id) != -1)
		f["ids"] = alive
		if not alive.is_empty():
			continue
		var e: Dictionary = f["event"]
		if int(f["waves_left"]) > 0:
			f["waves_left"] = int(f["waves_left"]) - 1
			f["ids"] = _spawn_event_wave(e["pos"], 11, 0.35, 0.12, 200.0)
			ui.hud.flash("Segunda oleada: vienen con refuerzos.", Color("f2c14e"))
			continue
		_event_fights.erase(f)
		e["state"] = "done"
		var at: Vector2 = e["pos"] if e["kind"] != "ambush" else player.global_position
		for k in int(f["reward"]):
			var bonus := 1.5 if k == 0 else 0.5   # el primero, con más rareza
			loot.drop_item(item_generator.roll_drop(enemies.area_level, bonus), zone.free_spot_near(at + Vector2.from_angle(TAU * k / maxf(1.0, f["reward"])) * 70.0))
		loot.drop_tokens(Economy.drop_amount(enemies.area_level, Rarity.Enemy.ELITE, _rng) * 2, zone.free_spot_near(at))
		ui.hud.flash("Evento superado: botín en el suelo.", Color("6fd36b"))
		Sfx.play("level_up", -6.0, 1.3)


## Hitstop: el juego se congela unos milisegundos (tiempo real) para dar peso al
## golpe. Con pausa entre uno y otro para que una lluvia de críticos no tartamudee.
func hitstop(seconds: float) -> void:
	if not hitstop_enabled() or Engine.time_scale < 1.0 or get_tree().paused:
		return
	var now := Time.get_ticks_msec()
	if now < _hitstop_ready_at:
		return
	_hitstop_ready_at = now + HITSTOP_GAP_MS + int(seconds * 1000.0)
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


static var _hitstop_on := bool(GameSettings.get_value("interface", "hitstop", true))


static func hitstop_enabled() -> bool:
	return _hitstop_on


static func set_hitstop(on: bool) -> void:
	_hitstop_on = on
	GameSettings.set_value("interface", "hitstop", on)


func _on_enemy_killed(rarity: int, experience: int, pos: Vector2, type_id: String = "") -> void:
	Sfx.play("enemy_death", -6.0 + 2.0 * rarity, 1.0 - 0.08 * rarity)
	if rarity >= Rarity.Enemy.ELITE:
		hitstop(0.06 if rarity == Rarity.Enemy.ELITE else 0.1)
		player.camera_shake(3.0 if rarity == Rarity.Enemy.ELITE else 6.0, 0.15)
	if rarity == Rarity.Enemy.UNIQUE and _boss_phase > 0 and not _boss_alive and enemies.boss_info().is_empty():
		_boss_phase = 0   # cayó el subjefe con fases: vuelve la música de la zona
		MusicPlayer.set_intensity(0)
	character.add_experience(experience)
	character.flags["stat_kills"] = int(character.flags.get("stat_kills", 0)) + 1
	_check_achievements()
	var patch := Crafting.roll_drop(rarity, _rng)
	if patch != "":
		Crafting.add(character, patch)
		ui.hud.flash("+1 %s (mesa de crafteo de Mario)." % Crafting.NAMES[patch].to_lower(), Crafting.COLORS[patch])
	if zone.id == Incidents.ZONE_ID:
		if rarity == Rarity.Enemy.ELITE and _rng.randf() < Atlas.ELITE_MAP_CHANCE:
			var m := Atlas.roll_map(GameData.zones, character.level, Atlas.tier(character), _rng)
			if not m.is_empty() and Atlas.add_map(character, m):
				ui.hud.flash("El élite soltó un %s (atlas)." % m["name"], Color("ff8a5a"))
		_check_incident_done.call_deferred()
	player.add_flask_charges(rarity)
	player.notify_kill()
	skills.on_enemy_killed(pos)
	ui.tutorial.notify("kill")
	quests.notify_kill(zone.id, rarity, type_id)
	var coins := Economy.drop_amount(enemies.area_level, rarity, _rng)
	if coins > 0:
		loot.drop_tokens(coins, zone.free_spot_near(pos + Vector2(randf_range(-24.0, 24.0), randf_range(-16.0, 16.0))))
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var drop_mult := float(zone.def.get("drop_multiplier", 1.0)) * (1.0 + float(Difficulty.LOOT[Difficulty.current(character)]))
	for k in int(info["drop_count"]):
		if randf() < float(info["drop_chance"]) * drop_mult:
			var item := item_generator.roll_drop(enemies.area_level, info["item_rarity_bonus"])
			loot.drop_item(item, zone.free_spot_near(pos + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))))
	# Chips de expansión (para las ranuras del árbol pasivo): raros, más de los enemigos fuertes.
	if randf() < [0.004, 0.015, 0.06, 0.25][clampi(rarity, 0, 3)] * drop_mult:
		loot.drop_item(ExpansionChip.roll(enemies.area_level, _rng), zone.free_spot_near(pos + Vector2(randf_range(-30.0, 30.0), 20.0)))
	# Enemigos raros con kill_flag (p. ej. el Centinela del Cargador): que no reaparezcan.
	if rarity == Rarity.Enemy.UNIQUE:
		for r in zone.def.get("rare_spawns", []):
			if r.get("type", "") == type_id and r.has("kill_flag"):
				character.flags[r["kill_flag"]] = true
	if type_id == "mutex_lock":
		_on_mutex_broken()
	elif type_id == "puntero_salvaje":
		character.flags["puntero_cazado"] = true
	if _boss_alive and enemies.count_type(zone.def.get("boss", {}).get("type", "daemon")) == 0:
		_on_boss_defeated(pos)


func _on_boss_defeated(pos: Vector2) -> void:
	_boss_alive = false
	MusicPlayer.set_intensity(0)
	MusicPlayer.play_track(String(GameData.music.get("zones", {}).get(GameData.town_for_zone(zone.id), "camp1")), 3.0)
	var boss: Dictionary = zone.def.get("boss", {})
	_record_boss_time(String(boss.get("type", "daemon")), character.play_time - _boss_started)
	var done_flag: String = boss.get("complete_flag", "act1_complete")
	var newly_unlocked := Difficulty.unlocked(character)
	character.flags[done_flag] = true
	character.flags[Difficulty.boss_flag(done_flag, Difficulty.current(character))] = true   # se puede repetir en cada dificultad
	if Difficulty.unlocked(character) > newly_unlocked:
		var d := Difficulty.unlocked(character)
		ui.hud.flash("Nueva dificultad: %s. Habla con Rafa en el campamento para cambiarla." % Difficulty.NAMES[d], Difficulty.COLORS[d])
	# El servidor se congela: lo que quedaba vivo se detiene y desaparece. Diferido:
	# el jefe puede morir dentro de un bucle del EnemyManager (degenerativos, área)
	# y vaciar sus listas en mitad del recorrido lo haría leer fuera de rango.
	enemies.clear_all.call_deferred()
	# Botín de jefe: algo bueno seguro.
	for r in [Rarity.Item.UNIQUE, Rarity.Item.RARE, Rarity.Item.RARE, Rarity.Item.ULTRA_RARE]:
		loot.drop_item(item_generator.generate(enemies.area_level, r), zone.free_spot_near(pos + Vector2(randf_range(-80, 80), randf_range(-60, 60))))
	loot.drop_item(item_generator.generate_motherboard(enemies.area_level, "", 6), zone.free_spot_near(pos + Vector2(0, 70)))
	quests.refresh()
	save_now()
	if boss.has("death_cutscene"):
		play_cutscene(boss["death_cutscene"])


func _on_mutex_broken() -> void:
	var mx: Dictionary = zone.def.get("mutex", {}) if zone.def.get("mutex") is Dictionary else {}
	if mx.is_empty():
		return
	var left := enemies.count_type("mutex_lock")
	if left > 0:
		ui.hud.flash("Candado Mutex liberado. Quedan %d." % left, Color("8ab0e0"))
		return
	character.flags[mx["flag"]] = true
	quests.refresh()
	save_now()
	if mx.has("cutscene"):
		play_cutscene(mx["cutscene"])


## Los monstruos tienen el nivel de su zona; subir de nivel solo avisa.
func _on_leveled_up(new_level: int) -> void:
	if not SoundMap.stinger("level"):   # el aviso de música; sin música, el efecto de siempre
		Sfx.play("level_up")
	Barks.play("level", player_voice_pitch())
	ui.hud.attention["passives"] = true   # punto nuevo: «!» en el botón P
	if new_level == CharacterData.ASCENDANCY_LEVEL:
		ui.hud.flash("¡Nivel %d! Ya puedes elegir tu ascendencia: abre el árbol (P) y pulsa el medallón junto a tu clase." % new_level, Color("ffd84a"))
	elif new_level > CharacterData.ASCENDANCY_LEVEL and (new_level - CharacterData.ASCENDANCY_LEVEL) % 5 == 0 and new_level <= 30:
		ui.hud.flash("¡Nivel %d! Nuevo punto de pasiva y de ascendencia (P)." % new_level, Color("ffd84a"))
	else:
		ui.hud.flash("¡Nivel %d! Tienes un punto de pasiva nuevo (P)." % new_level, UiStyle.ACCENT)
	_grant_unlocks()


## Progresión de kit: al llegar al nivel, la clase recibe la placa de su siguiente
## habilidad (nivel 1, dos ranuras). También se entregan las atrasadas al cargar.
func _grant_unlocks() -> void:
	for u in character.due_unlocks():
		if u.has("choice"):
			# Elección entre dos: se pregunta (una a la vez) y se entrega la elegida.
			if ui.is_choosing():
				continue
			var level := int(u["level"])
			var defs: Array = u["choice"].filter(func(s: String) -> bool: return GameData.items.skills.skills.has(s)) \
				.map(func(s: String) -> Dictionary: return GameData.items.skills.skills[s])
			ui.show_skill_choice("Nivel %d: elige tu nueva habilidad" % level, defs, func(skill_id: String) -> void:
				character.flags["unlock_lvl_%d" % level] = true
				_grant_board(skill_id)
				_grant_unlocks.call_deferred())
			continue
		_grant_board(String(u["skill"]))
	_mark_dirty()


func _grant_board(skill_id: String) -> void:
	if not GameData.items.skills.skills.has(skill_id):
		return
	character.flags["unlock_" + skill_id] = true
	var board := item_generator.generate_motherboard(1, skill_id, 2)
	board.level = 1
	_give(board)
	ui.hud.flash("Nueva habilidad de %s: %s. Está en tu bolsa; instálala con K." % [character.class_def.get("name", "tu clase"), board.skill_def["name"]], Color("ffd84a"))
	ui.hud.attention["skills"] = true   # «!» en el botón K hasta que se abra
	Sfx.play("level_up", -2.0, 1.25)
	_mark_dirty()


## Pistas la primera vez que se recoge una placa base o un módulo RAM.
func _on_item_picked_up(item: Item) -> void:
	SoundMap.play_pickup(item)   # según el material (T77)
	if item is Motherboard and not character.flags.has("hint_board"):
		character.flags["hint_board"] = true
		ui.hud.flash("¡Una placa base! Es una habilidad: instálala en la barra con K.", UiStyle.ACCENT)
	elif item is RamModule and not character.flags.has("hint_ram"):
		character.flags["hint_ram"] = true
		ui.hud.flash("¡Un módulo RAM! Mejora una habilidad: ponlo en una ranura de su color (K).", UiStyle.ACCENT)


# --- NPCs ---

func _on_npc_interacted(npc: Dictionary) -> void:
	FreezeWatch.mark("npc: " + String(npc["id"]))
	character.flags["talked_" + String(npc["id"])] = true
	quests.refresh()
	_talking_npc = String(npc["id"])
	ui.open_dialogue(npc, zone.dialogues.get(npc.get("dialogue", ""), {}))


var _talking_npc := ""


## Nacho saca otra caja: mercancía nueva, pagando.
func _refresh_shop() -> void:
	var cost := ShopPanel.refresh_cost(character.level, _shop_refreshes)
	if not character.spend_tokens(cost):
		ui.hud.flash("Renovar cuesta %d tokens. Nacho tampoco trabaja gratis." % cost, UiStyle.DANGER)
		return
	_shop_refreshes += 1   # la siguiente caja, más cara (hasta cambiar de zona)
	_shop_stock = Economy.generate_stock(item_generator, character.level)
	_shop_level = character.level
	ui.shop_panel.refreshes = _shop_refreshes
	ui.open_shop(_shop_stock)
	_mark_dirty()


func _on_dialogue_action(action: Dictionary) -> void:
	var flag: String = action.get("flag", "")
	if flag != "" and character.flags.has(flag):
		return  # ya se dio
	match action.get("type", ""):
		"give_item":
			var item: Item
			if action.get("kind", "") == "motherboard":
				item = item_generator.generate_motherboard(maxi(1, character.level), action.get("id", ""), 3)
			else:
				item = item_generator.generate_ram(character.level, action.get("id", ""))
			_give(item)
		"give_matching_ram":
			_give(_matching_ram())
		"give_random":
			var level := maxi(1, enemies.area_level)
			match String(action.get("rarity", "rare")):
				"flask":
					var f := item_generator.generate_flask(level)
					if f:
						_give(f)
				"ram":
					_give(item_generator.generate_ram(level))
				_:
					_give(item_generator.generate(level, RARITY_BY_NAME.get(action.get("rarity", "rare"), Rarity.Item.RARE)))
		"refill":
			player.refill()
		"start_quest":
			quests.start(action.get("quest", ""))
		"quest_advance":
			quests.advance(action.get("quest", ""))
		"set_flag":
			pass
		"open_gear_shop":
			if _gear_stock.is_empty() or _gear_level != character.level:
				_gear_stock = Economy.generate_gear_stock(item_generator, character.level)
				_gear_level = character.level
			ui.open_shop(_gear_stock, "aida")
		"reforge_weapon":
			_reforge_weapon()
		"set_difficulty":
			var d := int(action.get("value", 0))
			if Difficulty.choose(character, d):
				ui.hud.flash(Difficulty.describe(d), Difficulty.COLORS[d])
		"open_incident":
			open_incident()
		"open_waves":
			open_waves()
		"open_ladder":
			ui.open_ladder()
		"open_atlas":
			var atlas := AtlasPanel.new(character, open_incident)
			ui.add_child(atlas)
			atlas.popup_centered()
		"open_crafting":
			var panel := CraftingPanel.new(character, item_generator)
			ui.add_child(panel)
			panel.popup_centered()
		"antenna":
			player.refill()
			var mods: Array[Modifier] = [Modifier.new(Stat.DAMAGE, Modifier.Type.INCREASED, 15.0, [], "camp:antena"),
				Modifier.new(Stat.MOVEMENT_SPEED, Modifier.Type.INCREASED, 5.0, [], "camp:antena")]
			character.add_timed_effect("camp:antena", mods, CAMP_ANTENNA_SECONDS)
			ui.hud.flash("Señal fuerte: pociones llenas y +15 %% de daño durante %d minutos." % int(CAMP_ANTENNA_SECONDS / 60.0), Color("3cff6a"))
		"companion":
			var who := String(action.get("npc", ""))
			Companions.choose(character, who)
			_refresh_companion()
			ui.hud.flash(Companions.DEFS[who]["text"] if Companions.DEFS.has(who) else "Ahora vas solo.", Color("8ad8ff"))
		"recycle_normals":
			_recycle_normals()
		"open_shop":
			if _shop_stock.is_empty() or _shop_level != character.level:
				_shop_stock = Economy.generate_stock(item_generator, character.level)
				_shop_level = character.level
			ui.shop_panel.refreshes = _shop_refreshes
			ui.open_shop(_shop_stock)
		"passive_point":
			var amount := int(action.get("amount", 1))
			character.flags["quest_passive_points"] = int(character.flags.get("quest_passive_points", 0)) + amount
			character.recalculate()
			ui.hud.flash("+%d punto%s de pasiva por la misión (P)." % [amount, "" if amount == 1 else "s"], UiStyle.ACCENT)
	if flag != "":
		character.flags[flag] = true
	quests.refresh()
	_mark_dirty()


# --- Misiones ---

func _on_quest_started(id: String) -> void:
	var rewards := QuestLog.reward_text(quests.defs[id], GameData.items.skills)
	ui.hud.flash("Nueva misión: %s%s" % [quests.defs[id].get("name", id), ("\nRecompensa: " + rewards) if rewards != "" else ""], Color("ffd84a"))
	_mark_dirty()


func _on_quest_completed(id: String) -> void:
	var def: Dictionary = quests.defs[id]
	ui.hud.flash("Misión completada: %s" % def.get("name", id), Color("6fd36b"))
	if def.has("experience"):
		character.add_experience(int(def["experience"]))
	for reward in def.get("rewards", []):
		_on_dialogue_action(reward)
	_mark_dirty()


## Un módulo RAM que encaje y funcione en la primera placa de la barra.
func _matching_ram() -> RamModule:
	var board: Motherboard = null
	for b in character.inventory.boards:
		if b:
			board = b
			break
	if board == null:
		return item_generator.generate_ram(character.level)
	var options: Array = []
	for id in GameData.items.skills.rams:
		var ram := item_generator.generate_ram(character.level, id)
		if board.slots.has(ram.generation()) and ram.supports(board.skill_def):
			options.append(ram)
	return options.pick_random() if not options.is_empty() else item_generator.generate_ram(character.level)


## El Recolector: cada 3 piezas de equipo normal (blancas) de la bolsa, un objeto mejor.
func _recycle_normals() -> void:
	var inv := character.inventory
	var indices: Array[int] = []
	for i in inv.bag.size():
		var item: Item = inv.bag[i]
		if item and item.is_equipment() and item.rarity == Rarity.Item.NORMAL:
			indices.append(i)
	var batches := indices.size() / 3
	if batches == 0:
		ui.hud.flash("El Recolector necesita al menos 3 piezas normales (blancas) en tu bolsa.", UiStyle.MUTED)
		return
	for k in batches * 3:
		inv.bag[indices[k]] = null
	inv.changed.emit()
	for k in batches:
		var roll := randf()
		var reward: Item
		if roll < 0.35:
			reward = item_generator.generate_ram(enemies.area_level)
		elif roll < 0.55:
			reward = item_generator.generate_flask(enemies.area_level)
		else:
			reward = item_generator.generate(enemies.area_level, Rarity.Item.MAGIC if randf() < 0.6 else Rarity.Item.RARE)
		if reward:
			_give(reward)
	ui.hud.flash("El Recolector se lleva %d piezas y te da %d objetos a cambio." % [batches * 3, batches], UiStyle.ACCENT)


func _give(item: Item) -> void:
	if character.inventory.add_item(item):
		ui.hud.flash("Recibido: %s" % item.display_name(), UiStyle.ACCENT)
	else:
		loot.drop_item(item, player.global_position + Vector2(0, 40))
		ui.hud.flash("Inventario lleno: %s está en el suelo." % item.display_name())
