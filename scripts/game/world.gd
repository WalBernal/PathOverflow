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
var quests: QuestLog

var _dirty := false
var _since_save := 0.0
var _boss_alive := false
## Prueba de estrés en curso: {def, wave, total, ids, next_in, rewards}.
var _challenge: Dictionary = {}
## Recompensas ya enseñadas por prueba (para no cambiarlas al volver a mirar).
var _challenge_previews: Dictionary = {}
## Subjefe de los gemelos: {ids, turn, timer, swap, flag}.
var _twins: Dictionary = {}
var _immune_warning := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0b0a0e"))
	MusicPlayer.stop_music()
	character = GameData.current_character
	if character == null:
		character = GameData.create_character("Desarrollador", DEV_CLASS, CharacterAppearance.default(), false)
	item_generator = ItemGenerator.new(GameData.items)
	character.leveled_up.connect(_on_leveled_up)
	character.board_leveled.connect(func(b: Motherboard) -> void:
		ui.hud.flash("%s sube a nivel %d." % [b.skill_def.get("name", "La placa"), b.level], Color("1ba29b")))
	character.inventory.changed.connect(_mark_dirty)
	character.passives.changed.connect(_mark_dirty)
	character.stats_changed.connect(_mark_dirty)  # incluye cambio de ascendencia

	enemies = EnemyManager.new()
	add_child(enemies)
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.setup(character, enemies)
	enemies.player = player
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.immune_hit.connect(_on_immune_hit)
	skills = SkillController.new()
	add_child(skills)
	skills.setup(player, enemies, character)
	# Después del jugador: reciben los clicks antes que él (recoger, hablar).
	loot = LootManager.new()
	loot.player = player
	loot.inventory = character.inventory
	add_child(loot)
	loot.picked_up.connect(_on_item_picked_up)
	# El botín solo cae donde se puede llegar a recogerlo.
	loot.placement_check = func(p: Vector2) -> bool: return zone == null or zone.is_walkable(p, 18.0)
	loot.spot_fixer = func(p: Vector2) -> Vector2: return p if zone == null else zone.free_spot_near(p, 24.0)

	quests = QuestLog.new(character)
	quests.quest_started.connect(_on_quest_started)
	quests.quest_completed.connect(_on_quest_completed)

	ui = GameUI.new()
	add_child(ui)
	ui.setup(player, enemies, character, loot, skills, quests)
	player.died.connect(_on_player_died)
	ui.return_to_menu_requested.connect(_return_to_menu)
	ui.quit_requested.connect(_quit_game)
	ui.dialogue_action.connect(_on_dialogue_action)
	ui.waypoint_selected.connect(func(zone_id: String) -> void: travel_to(zone_id, "waypoint"))

	# Se vuelve a la última zona; los personajes de antes del acto, al campamento.
	var start_zone: String = character.flags.get("zone", GameData.act.get("town", "campamento"))
	if not GameData.zones.has(start_zone):
		start_zone = GameData.act.get("town", "campamento")
	travel_to(start_zone, "waypoint" if GameData.zones[start_zone].get("waypoint") != null else "")
	quests.start_auto()

	if character.flags.has("ascendancy_reset"):
		character.flags.erase("ascendancy_reset")
		ui.hud.flash.call_deferred("Las ascendencias ahora se eligen al nivel 20: tu elección se ha reiniciado.", UiStyle.ACCENT)
	if character.flags.has("passives_refunded"):
		character.flags.erase("passives_refunded")
		ui.hud.flash.call_deferred("El árbol pasivo ha cambiado: te hemos devuelto todos los puntos (P).", UiStyle.ACCENT)


func _process(delta: float) -> void:
	character.play_time += delta
	_update_twins(delta)
	_update_challenge(delta)
	_immune_warning = maxf(0.0, _immune_warning - delta)
	_since_save += delta
	if (_dirty and _since_save >= AUTOSAVE_DELAY) or _since_save >= AUTOSAVE_INTERVAL:
		save_now()


## Cerrar la ventana también guarda.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func save_now() -> void:
	GameData.save_character(character)
	_dirty = false
	_since_save = 0.0


func _mark_dirty() -> void:
	_dirty = true


func _return_to_menu() -> void:
	save_now()
	get_tree().paused = false
	GameData.current_character = null
	get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE)


func _quit_game() -> void:
	save_now()
	get_tree().quit()


# --- Zonas ---

## Carga una zona y coloca al jugador en la entrada indicada ("" = la primera).
func travel_to(zone_id: String, entry := "") -> void:
	var def: Dictionary = GameData.zones.get(zone_id, {})
	if def.is_empty():
		push_error("Zona desconocida: %s" % zone_id)
		return
	if not _challenge.is_empty():
		_fail_challenge("Has salido de la zona: la prueba de estrés se cancela.")
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
	zone.npc_interacted.connect(_on_npc_interacted)
	zone.exit_reached.connect(_on_exit_reached)
	zone.quest_item_picked.connect(_on_quest_item_picked)
	zone.key_item_picked.connect(_on_key_item_picked)
	zone.challenge_touched.connect(_on_challenge_touched)
	zone.exit_blocked.connect(func(e: Dictionary) -> void: ui.hud.flash(zone.exit_blocked_reason(e), Color("e06c6c")))
	zone.waypoint_clicked.connect(func() -> void: ui.open_waypoints(zone.id))
	zone.waypoint_touched.connect(_discover_waypoint)

	player.global_position = zone.entry_point(entry)
	player.stop_auto_move()
	var cam := player.get_node("Camera2D") as Camera2D
	cam.limit_left = int(zone.rect.position.x - 200)
	cam.limit_top = int(zone.rect.position.y - 200)
	cam.limit_right = int(zone.rect.end.x + 200)
	cam.limit_bottom = int(zone.rect.end.y + 200)
	cam.reset_smoothing()

	enemies.area_level = zone.level
	enemies.bounds = zone.rect
	enemies.walk_clamp = zone.clamp_to_walkable
	enemies.obstacles.clear()
	for o in zone.obstacles:
		enemies.obstacles.append(Vector3(o["pos"].x, o["pos"].y, o["radius"]))
	_spawn_zone_enemies()

	character.flags["zone"] = zone.id
	ui.on_zone_changed(zone)
	quests.notify_zone(zone.id)
	_mark_dirty()
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
		for center in zone.pack_centers(int(cfg.get("packs", 0)), rng):
			var type := enemies.type_index_of(type_ids[rng.randi_range(0, type_ids.size() - 1)]) if not type_ids.is_empty() else -1
			var pack := rng.randi_range(int(size_range[0]), int(size_range[1]))
			for k in pack:
				var rarity := Rarity.Enemy.NORMAL
				if k == 0 and rng.randf() < float(cfg.get("elite_chance", 0.0)):
					rarity = Rarity.Enemy.ELITE
				elif rng.randf() < float(cfg.get("special_chance", 0.0)):
					rarity = Rarity.Enemy.SPECIAL
				var p := zone.free_spot_near(center + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)))
				enemies.spawn(p, rarity, type)
	_spawn_zone_specials()
	_boss_alive = false
	var boss: Dictionary = zone.def.get("boss", {}) if zone.def.get("boss") is Dictionary else {}
	if not boss.is_empty() and not character.flags.has(boss.get("complete_flag", "act1_complete")):
		enemies.spawn(Zone._v(boss["pos"]), Rarity.Enemy.UNIQUE, enemies.type_index_of(boss.get("type", "daemon")),
			boss.get("name", ""), float(boss.get("life_mult", 1.0)), boss.get("abilities", []))
		_boss_alive = true


## Subjefes, candados y enemigos raros definidos en la zona.
func _spawn_zone_specials() -> void:
	var rc: Dictionary = zone.def.get("race_condition", {}) if zone.def.get("race_condition") is Dictionary else {}
	if not rc.is_empty() and not character.flags.has(rc.get("flag", "")):
		var p := Zone._v(rc["pos"])
		var names: Array = rc.get("names", ["Hilo Alfa", "Hilo Beta"])
		var t := enemies.type_index_of("hilo_gemelo")
		var a := enemies.spawn(p + Vector2(0, -90), Rarity.Enemy.UNIQUE, t, names[0], float(rc.get("life_mult", 4.0)))
		var b := enemies.spawn(p + Vector2(0, 90), Rarity.Enemy.UNIQUE, t, names[1], float(rc.get("life_mult", 4.0)))
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
		enemies.spawn(Zone._v(r["pos"]), Rarity.Enemy.UNIQUE, enemies.type_index_of(r["type"]), r.get("name", ""), float(r.get("life_mult", 1.0)))


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
	quests.refresh()
	save_now()


func _fail_challenge(message: String) -> void:
	_challenge = {}
	if zone:
		zone.active_challenge = {}
	ui.set_wave_text("")
	ui.hud.flash(message, Color("e06c6c"))


func _discover_waypoint() -> void:
	var found: Array = character.flags.get("waypoints", [])
	if not found.has(zone.id):
		found.append(zone.id)
		character.flags["waypoints"] = found
		ui.hud.flash("Waypoint descubierto: %s. Ya puedes viajar aquí." % zone.zone_name, Color("5cd0ff"))
		_mark_dirty()


func _on_player_died() -> void:
	character.flags["stat_deaths"] = int(character.flags.get("stat_deaths", 0)) + 1
	ui.show_death()
	_mark_dirty()


## Al reaparecer se vuelve al campamento (como en PoE, al último pueblo).
func respawn() -> void:
	player.refill()
	ui.hide_death()
	travel_to(GameData.town_for_zone(zone.id if zone else ""), "waypoint")


func _unhandled_input(event: InputEvent) -> void:
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


func _on_enemy_killed(rarity: int, experience: int, pos: Vector2, type_id: String = "") -> void:
	character.add_experience(experience)
	character.flags["stat_kills"] = int(character.flags.get("stat_kills", 0)) + 1
	player.add_flask_charges(rarity)
	player.notify_kill()
	ui.tutorial.notify("kill")
	quests.notify_kill(zone.id, rarity, type_id)
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var drop_mult := float(zone.def.get("drop_multiplier", 1.0))
	for k in int(info["drop_count"]):
		if randf() < float(info["drop_chance"]) * drop_mult:
			var item := item_generator.roll_drop(enemies.area_level, info["item_rarity_bonus"])
			loot.drop_item(item, zone.free_spot_near(pos + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))))
	if type_id == "mutex_lock":
		_on_mutex_broken()
	elif type_id == "puntero_salvaje":
		character.flags["puntero_cazado"] = true
	if _boss_alive and enemies.count_type(zone.def.get("boss", {}).get("type", "daemon")) == 0:
		_on_boss_defeated(pos)


func _on_boss_defeated(pos: Vector2) -> void:
	_boss_alive = false
	var boss: Dictionary = zone.def.get("boss", {})
	character.flags[boss.get("complete_flag", "act1_complete")] = true
	# El servidor se congela: lo que quedaba vivo se detiene y desaparece.
	enemies.clear_all()
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
	if new_level == CharacterData.ASCENDANCY_LEVEL:
		ui.hud.flash("¡Nivel %d! Ya puedes elegir tu ascendencia: abre el árbol (P) y pulsa el medallón junto a tu clase." % new_level, Color("ffd84a"))
	elif new_level > CharacterData.ASCENDANCY_LEVEL and (new_level - CharacterData.ASCENDANCY_LEVEL) % 5 == 0 and new_level <= 30:
		ui.hud.flash("¡Nivel %d! Nuevo punto de pasiva y de ascendencia (P)." % new_level, Color("ffd84a"))
	else:
		ui.hud.flash("¡Nivel %d! Tienes un punto de pasiva nuevo (P)." % new_level, UiStyle.ACCENT)


## Pistas la primera vez que se recoge una placa base o un módulo RAM.
func _on_item_picked_up(item: Item) -> void:
	if item is Motherboard and not character.flags.has("hint_board"):
		character.flags["hint_board"] = true
		ui.hud.flash("¡Una placa base! Es una habilidad: instálala en la barra con K.", UiStyle.ACCENT)
	elif item is RamModule and not character.flags.has("hint_ram"):
		character.flags["hint_ram"] = true
		ui.hud.flash("¡Un módulo RAM! Mejora una habilidad: ponlo en una ranura de su color (K).", UiStyle.ACCENT)


# --- NPCs ---

func _on_npc_interacted(npc: Dictionary) -> void:
	character.flags["talked_" + String(npc["id"])] = true
	quests.refresh()
	ui.open_dialogue(npc, zone.dialogues.get(npc.get("dialogue", ""), {}))


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
		"recycle_normals":
			_recycle_normals()
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
	ui.hud.flash("Nueva misión: %s" % quests.defs[id].get("name", id), Color("ffd84a"))
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
