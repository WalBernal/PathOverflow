extends Node
## Prueba de integración: carga cada zona con cada clase y juega N segundos
## (moverse, lanzar las habilidades de la barra, pociones y esquiva). Falla si
## aparece cualquier error del motor o de script (SCRIPT ERROR) o si el jugador
## sale de los límites de la zona. No guarda personajes ni toca el alijo.
##
## Uso (sin ventana y con fotogramas fijos, va más rápido que el tiempo real):
##   Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tests/test_integration.tscn
## Opciones después de "--":  segundos=10  clases=guerrero,hechicero  zonas=zona1,oblea
## Devuelve código de salida 1 si algo falla.

const WORLD_SCENE := "res://scenes/game/world.tscn"
const FPS := 60
const OUT_OF_BOUNDS_MARGIN := 40.0
## Distancia a la que el piloto automático empieza a lanzar habilidades.
const CAST_RANGE := 420.0


## Cuenta los errores que pasan por el registro del motor (también los de otros hilos).
class ErrorCounter extends Logger:
	var mutex := Mutex.new()
	var errors: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var kind: String = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"][clampi(error_type, 0, 3)]
		mutex.lock()
		errors.append("%s: %s (%s:%d, %s)" % [kind, rationale if rationale != "" else code, file, line, function])
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func take() -> PackedStringArray:
		mutex.lock()
		var out := errors.duplicate()
		errors.clear()
		mutex.unlock()
		return out


var _counter := ErrorCounter.new()
var _failures: PackedStringArray = []
var _seconds := 30.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	OS.add_logger(_counter)
	_rng.seed = 2026
	_run.call_deferred()


func _run() -> void:
	var class_filter: PackedStringArray = []
	var zone_filter: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("segundos="):
			_seconds = maxf(1.0, arg.get_slice("=", 1).to_float())
		elif arg.begins_with("clases="):
			class_filter = arg.get_slice("=", 1).split(",", false)
		elif arg.begins_with("zonas="):
			zone_filter = arg.get_slice("=", 1).split(",", false)
	var gd: Node = get_node("/root/GameData")
	var started := Time.get_ticks_msec()
	var runs := 0
	for class_def in gd.get("classes"):
		var class_id: String = class_def["id"]
		if not class_filter.is_empty() and not class_filter.has(class_id):
			continue
		for act_index in gd.get("acts").size():
			var act: Dictionary = gd.get("acts")[act_index]
			var zone_ids: Array = []
			for z in act.get("zones", []):
				if zone_filter.is_empty() or zone_filter.has(z["id"]):
					zone_ids.append(z["id"])
			if zone_ids.is_empty():
				continue
			runs += await _play_act(class_def, act, act_index, zone_ids)
		# Una vez (con la primera clase): un incidente del atlas y su pantalla.
		if runs > 0 and not _incident_played and (zone_filter.is_empty() or zone_filter.has("incidente")):
			_incident_played = true
			runs += await _play_incident(class_def)
	_counter.take()   # lo que salga al cerrar no cuenta
	print("")
	print("Integración: %d zonas × clase de %.0f s en %.1f s reales" % [runs, _seconds, (Time.get_ticks_msec() - started) / 1000.0])
	if _leftovers.size() > 1:
		print("Lo que queda vivo tras cerrar cada mundo:")
		for line in _leftovers:
			print("  " + line)
	if _failures.is_empty():
		print("OK: sin errores.")
	else:
		print("FALLOS (%d):" % _failures.size())
		for f in _failures:
			print("  " + f)
	OS.remove_logger(_counter)
	get_tree().quit(1 if not _failures.is_empty() else 0)


## Un personaje por clase y acto, con el nivel de la última zona del acto (y una
## ascendencia distinta en cada acto desde el nivel 20), que recorre sus zonas.
func _play_act(class_def: Dictionary, act: Dictionary, act_index: int, zone_ids: Array) -> int:
	var gd: Node = get_node("/root/GameData")
	var level := 1
	for z in act.get("zones", []):
		level = maxi(level, int(z.get("level", 1)))
	var c: CharacterData = gd.create_character("Integración", StringName(class_def["id"]), CharacterAppearance.default(), false)
	c.flags["zone"] = act.get("town", "campamento")
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	for k in act_index:
		c.flags["act%d_complete" % (k + 1)] = true
	c.level = level
	var ascendancies: Array = class_def.get("ascendancies", [])
	if level >= 20 and not ascendancies.is_empty():
		c.set_ascendancy(StringName(ascendancies[act_index % ascendancies.size()]["id"]))
		for node_id in range(1, 6):
			c.allocate_ascendancy_node(node_id)
	gd.set("current_character", c)
	var world: Node = load(WORLD_SCENE).instantiate()
	add_child(world)
	world.set("_since_save", -9999.0)
	await _frames(2)
	_collect("%s · acto %d · al cargar" % [class_def["id"], act_index + 1])
	var count := 0
	for zid in zone_ids:
		await _play_zone(world, class_def["id"], zid)
		count += 1
	world.set("_since_save", -9999.0)
	remove_child(world)
	world.queue_free()
	get_tree().paused = false   # que una pausa de este personaje no frene al siguiente
	await _frames(2)
	gd.set("current_character", null)
	_collect("%s · acto %d · al cerrar" % [class_def["id"], act_index + 1])
	_note_leftovers("%s · acto %d" % [class_def["id"], act_index + 1])
	return count


## T67: lo que queda vivo tras cerrar cada mundo (objetos, nodos, memoria). Si
## crece de mundo en mundo, algo se acumula entre partidas (la sospecha de los
## cierres sin traza). Se imprime al final.
var _leftovers: Array[String] = []
var _first_objects := -1


func _note_leftovers(label: String) -> void:
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	if _first_objects < 0:
		_first_objects = objects
	_leftovers.append("%-28s objetos %6d (%+d)  nodos %4d  huérfanos %3d  memoria %6.1f MB" % [label, objects, objects - _first_objects, nodes, orphans, mem])


var _incident_played := false


## Un incidente (Incidents) desde el campamento del acto I, con el atlas abierto y cerrado antes.
func _play_incident(class_def: Dictionary) -> int:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Integración", StringName(class_def["id"]), CharacterAppearance.default(), false)
	c.flags["zone"] = gd.get("act").get("town", "campamento")
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 20
	gd.set("current_character", c)
	var world: Node = load(WORLD_SCENE).instantiate()
	add_child(world)
	world.set("_since_save", -9999.0)
	await _frames(2)
	await _check_gamepad_cursor(world, class_def["id"])
	await _check_world_map(world, class_def["id"])
	await _check_instances(world, class_def["id"])
	world.call("_on_dialogue_action", {"type": "open_atlas"})
	await _frames(2)
	for child in world.get("ui").get_children():
		if child is AtlasPanel:
			child.queue_free()
	world.call("open_incident")
	await _frames(2)
	_collect("%s · incidente · al abrir" % class_def["id"])
	await _play_zone(world, class_def["id"], "incidente")
	# Banco de oleadas (Ladder) desde el diálogo de Aida, con la tabla abierta y cerrada antes.
	world.call("_on_dialogue_action", {"type": "open_ladder"})
	await _frames(2)
	for child in (world.get("ui").get("_root") as Control).get_children():
		if child is LadderPanel:
			child.queue_free()
	world.call("_on_dialogue_action", {"type": "open_waves"})
	await _frames(2)
	_collect("%s · oleadas · al abrir" % class_def["id"])
	await _play_zone(world, class_def["id"], "oleadas", false)
	var waves: Dictionary = world.get("_waves")
	if not waves.is_empty() and int(waves["wave"]) == 0 and _seconds >= 4.0:   # vacío: caíste o saliste; la primera sale a los 3 s
		_failures.append("%s · oleadas: no salió ninguna oleada" % class_def["id"])
	world.set("_since_save", -9999.0)
	remove_child(world)
	world.queue_free()
	get_tree().paused = false
	await _frames(2)
	gd.set("current_character", null)
	_collect("%s · incidente · al cerrar" % class_def["id"])
	return 1


## Instancias de 10 minutos (T118): soltar algo en una zona generada, ir al campamento y
## volver: misma zona y el objeto sigue ahí; si la instancia caduca, zona nueva y sin él.
func _check_instances(world: Node, class_id: String) -> void:
	var town: String = (get_node("/root/GameData").get("act") as Dictionary).get("town", "campamento")
	world.call("travel_to", "zona1", "")
	await _frames(2)
	var zone: Zone = world.get("zone")
	var loot: LootManager = world.get("loot")
	var seed1 := int(zone.def.get("_layout_seed", -1))
	var item: Item = (world.get("item_generator") as ItemGenerator).roll_drop(20, 1.0)
	loot.drop_item(item, zone.entry_point("") + Vector2(150, 0))
	loot.drop_tokens(7, zone.entry_point("") + Vector2(150, 60))
	if zone.containers.size() > 0:
		zone.containers[0]["opened"] = true
	world.call("travel_to", town, "waypoint")
	await _frames(2)
	world.call("travel_to", "zona1", "")
	await _frames(2)
	zone = world.get("zone")
	if int(zone.def.get("_layout_seed", -2)) != seed1:
		_failures.append("%s · instancias: al volver antes de 10 min la zona es otra" % class_id)
	if not loot.drops.any(func(d: Dictionary) -> bool: return d["item"] == item) or loot.coins.is_empty():
		_failures.append("%s · instancias: el botín del suelo no se conservó" % class_id)
	if zone.containers.size() > 0 and not zone.containers[0]["opened"]:
		_failures.append("%s · instancias: la caja abierta se volvió a cerrar" % class_id)
	world.call("travel_to", town, "waypoint")
	await _frames(2)
	(world.get("instances") as ZoneInstances).prune(float(world.call("_now")) + ZoneInstances.TTL + 1.0)
	world.call("travel_to", "zona1", "")
	await _frames(2)
	if loot.drops.any(func(d: Dictionary) -> bool: return d["item"] == item):
		_failures.append("%s · instancias: tras caducar sigue el botín de antes" % class_id)
	world.call("travel_to", town, "waypoint")
	await _frames(2)
	_collect("%s · instancias" % class_id)


## Cursor de mando (GamepadCursor): con el inventario abierto se activa, la
## cruceta lo lleva a una casilla, A la toma y B cierra la ventana.
func _check_gamepad_cursor(world: Node, class_id: String) -> void:
	var ui: GameUI = world.get("ui")
	var was := Gamepad.active
	Gamepad.active = true
	for k in 30:   # la escena de entrada al campamento, si la hay
		if ui.cutscene.visible:
			ui.cutscene.call("_finish")
		await get_tree().process_frame
	if ui.is_choosing():   # la elección de la primera habilidad: con A sobre «Elegir»
		await _frames(2)
		for pressed in [true, false]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = JOY_BUTTON_A
			ev.pressed = pressed
			Input.parse_input_event(ev)
			await _frames(2)
		if ui.is_choosing():
			_failures.append("%s · mando: A no eligió la habilidad (cursor en %s)" % [class_id, ui.gamepad_cursor.cursor_pos])
	ui._on_menu_requested("inventory")
	await _frames(2)
	var cursor := ui.gamepad_cursor
	if not cursor.engaged or not Gamepad.menu_cursor:
		_failures.append("%s · mando: el cursor no se activó con el inventario abierto (ventanas: %d, mando: %s, inventario: %s, pausa %s, árbol %s, escena %s, elección %s)" % [class_id,
			ui.cursor_windows().size(), Gamepad.active, ui.inventory_panel.visible, ui._pause_panel.visible, ui.tree_screen.visible, ui.cutscene.is_playing(), ui.is_choosing()])
	var start := cursor.cursor_pos
	for button in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_A]:
		for pressed in [true, false]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			ev.pressed = pressed
			Input.parse_input_event(ev)
			await _frames(2)
	if cursor.cursor_pos == start:
		var rects: Array[Rect2] = []
		cursor._collect_targets(ui.inventory_panel, rects)
		_failures.append("%s · mando: la cruceta no movió el cursor (en %s, %d destinos, primero %s, pantalla %s)" % [class_id, start, rects.size(),
			rects[0] if not rects.is_empty() else Rect2(), cursor.get_viewport_rect()])
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	b.pressed = true
	Input.parse_input_event(b)
	await _frames(2)
	b = b.duplicate()
	b.pressed = false
	Input.parse_input_event(b)
	await _frames(2)
	if ui.inventory_panel.visible or Gamepad.menu_cursor:
		_failures.append("%s · mando: B no cerró el inventario" % class_id)
	# Parte 2: fijar la comparación con Y, y el árbol pasivo con la cruceta.
	ui._on_menu_requested("inventory")
	await _frames(2)
	var item := ItemGenerator.new(get_node("/root/GameData").get("items")).generate(1, Rarity.Item.RARE)
	ui.item_tooltip.show_item(item, world.get("character"), true)
	await _press(JOY_BUTTON_Y)
	if not ui.item_tooltip.is_pinned():
		_failures.append("%s · mando: Y no fijó la comparación" % class_id)
	await _press(JOY_BUTTON_Y)
	if ui.item_tooltip.is_pinned():
		_failures.append("%s · mando: Y otra vez no la soltó" % class_id)
	ui._on_menu_requested("inventory")
	ui._on_menu_requested("passives")
	await _frames(3)
	if ui.cursor_windows() != [ui.tree_screen] or not cursor.engaged:
		_failures.append("%s · mando: el cursor no maneja el árbol pasivo" % class_id)
	# Cada pulsación debe saltar a otro nodo (derecha, abajo e izquierda pueden volver al
	# de partida: lo que se mira es que cada paso se mueva, no dónde acaba).
	var at_tree := cursor.cursor_pos
	var trail: Array[Vector2] = [at_tree]
	for button in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT]:
		await _press(button)
		trail.append(cursor.cursor_pos)
	var stuck := false
	for k in range(1, trail.size()):
		stuck = stuck or trail[k] == trail[k - 1]
	if stuck:
		_failures.append("%s · mando: la cruceta no salta entre nodos del árbol (pasos %s)" % [class_id, trail])
	await _press(JOY_BUTTON_B)
	if ui.tree_screen.visible:
		_failures.append("%s · mando: B no cerró el árbol" % class_id)
	get_tree().paused = false
	_collect("%s · mando en menús" % class_id)
	Gamepad.active = was


## Mapa grande (Tab): zoom y marcas propias, dibujado unos fotogramas.
func _check_world_map(world: Node, class_id: String) -> void:
	var map: WorldMap = (world.get("ui") as GameUI).world_map
	var player: Player = world.get("player")
	map.toggle()
	map.zoom_by(2)
	await _frames(3)
	if map.zoom_index != 2:
		_failures.append("%s · mapa: no hace zoom" % class_id)
	var near_player := map.map_to_world(map.size / 2.0)
	if not map.toggle_mark(player.global_position) or map.marks().size() != 1 or not map.zone.rect.has_point(near_player):
		_failures.append("%s · mapa: no pone la marca (o el zoom no se centra en la zona)" % class_id)
	await _frames(3)
	if map.toggle_mark(player.global_position + Vector2(30, 0)) or not map.marks().is_empty():
		_failures.append("%s · mapa: clic derecho sobre la marca no la quita" % class_id)
	map.zoom_by(-9)
	map.toggle()
	_collect("%s · mapa grande" % class_id)


func _press(button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func _play_zone(world: Node, class_id: String, zone_id: String, travel := true) -> void:
	var label := "%s · %s" % [class_id, zone_id]
	if travel:
		world.call("travel_to", zone_id, "")
		var z: Zone = world.get("zone")
		var c: CharacterData = world.get("character")
		if z.safe and z.has_waypoint and not (c.flags.get("waypoints", []) as Array).has(zone_id):
			_failures.append("%s: el waypoint del campamento no se descubre al entrar" % label)
	world.set("_since_save", -9999.0)
	var player: Player = world.get("player")
	var skills: SkillController = world.get("skills")
	var ui: GameUI = world.get("ui")
	Gamepad.active = true   # apunta al enemigo más cercano en vez de al ratón
	var deaths := 0
	var kills := [0]
	var on_kill := func(_rarity: int, _xp: int, _pos: Vector2, _type: String) -> void: kills[0] += 1
	(world.get("enemies") as EnemyManager).enemy_killed.connect(on_kill)
	var uses := [0]
	var on_use := func(_i: int) -> void: uses[0] += 1
	skills.skill_used.connect(on_use)
	var start_pos := player.global_position
	var travelled := 0.0
	var out_reported := false
	var pause_reported := false
	var frames := int(_seconds * FPS)
	for f in frames:
		await get_tree().process_frame
		world.set("_since_save", -9999.0)
		var zone: Zone = world.get("zone")
		var enemies: EnemyManager = world.get("enemies")
		if ui.cutscene.visible:
			ui.cutscene.call("_finish")
		if ui.dialogue_box.visible:
			ui.dialogue_box.close()
		if ui.is_choosing():   # elección entre dos habilidades: la primera
			_press_first_button(ui.get("_choice_panel"))
		elif get_tree().paused and not pause_reported:
			pause_reported = true
			_failures.append("%s: el juego quedó en pausa sin ninguna ventana que la explique" % label)
			get_tree().paused = false
		# Que el combate siga: sin muertes definitivas ni falta de maná.
		if not player.is_alive():
			deaths += 1
			player.refill()
			ui.hide_death()
		elif player.life < player.max_life() * 0.5:
			player.life = player.max_life()
		if player.mana < player.unreserved_mana_max() * 0.2:
			player.mana = player.unreserved_mana_max()
		# Lanzar solo con un enemigo a tiro (lanzar frena al personaje); si no, caminar hacia ellos.
		var in_range := enemies.nearest_index(player.global_position, CAST_RANGE) != -1
		if f % FPS == 0 or (not in_range and not player.has_auto_target()):
			player.move_to(_move_target(zone, enemies, player.global_position))
		if in_range and f % 12 == 6:
			skills.try_use((f / 12) % Inventory.HOTBAR_SIZE)
		if f % (FPS * 5) == FPS * 2:
			player.use_flask((f / (FPS * 5)) % Inventory.FLASK_SLOTS)
		if f % (FPS * 4) == FPS * 3:
			player.dodge()
		var pos := player.global_position
		travelled += pos.distance_to(start_pos)
		start_pos = pos
		if not out_reported and (not pos.is_finite() or not zone.rect.grow(OUT_OF_BOUNDS_MARGIN).has_point(pos)):
			out_reported = true
			_failures.append("%s: el jugador salió de la zona en %s (zona %s)" % [label, pos, zone.rect])
	Gamepad.active = false
	(world.get("enemies") as EnemyManager).enemy_killed.disconnect(on_kill)
	skills.skill_used.disconnect(on_use)
	var zone_now: Zone = world.get("zone")
	if _seconds >= 20.0 and not zone_now.safe and kills[0] + (world.get("enemies") as EnemyManager).count() > 0 and uses[0] == 0:
		_failures.append("%s: no hubo combate (ninguna habilidad lanzada en %.0f s)" % [label, _seconds])
	_collect(label)
	print("%-34s %3d enemigos vivos, %3d derrotados, %3d habilidades, %5.0f px recorridos, %d muertes del jugador" % [
		label, (world.get("enemies") as EnemyManager).count(), kills[0], uses[0], travelled, deaths])


## Hacia el enemigo más cercano (sin pegarse) o, de vez en cuando o si no hay, a un punto libre al azar.
func _move_target(zone: Zone, enemies: EnemyManager, from: Vector2) -> Vector2:
	var i := enemies.nearest_index(from, 4000.0)
	if i != -1 and _rng.randf() < 0.85:
		var to := enemies.positions[i]
		return zone.free_spot_near(to + (from - to).normalized() * 90.0)
	var r := zone.rect
	return zone.free_spot_near(Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y)))


func _press_first_button(root: Node) -> void:
	for b in root.find_children("*", "Button", true, false):
		(b as Button).pressed.emit()
		return


func _collect(label: String) -> void:
	for e in _counter.take():
		_failures.append("%s: %s" % [label, e])


func _frames(n: int) -> void:
	for k in n:
		await get_tree().process_frame
