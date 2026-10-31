extends Node
## Captura las pantallas principales en user://capturas/ (para revisar la
## interfaz sin jugar). No guarda personajes ni toca el alijo.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . res://tools/capture_screens.tscn
## Solo las de combate (estados, HUD, iconos, tutorial): añade  -- combate

const OUT := "user://capturas/"
const MENU_SCENES := {
	"01_titulo": "res://scenes/menu/title_screen.tscn",
	"02_personajes": "res://scenes/menu/main_menu.tscn",
	"03_creador": "res://scenes/menu/character_creation.tscn",
}

var _current: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	LoadingCard.enabled = false   # la pantalla de carga taparía las capturas
	BossIntro.enabled = OS.get_cmdline_user_args().has("jefes")   # la entrada de jefe, solo donde se quiere ver
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Como en el celular (T106): con  --rendering-method mobile  delante, además el renderizador.
	if OS.get_cmdline_user_args().has("movil"):
		GameSettings.force_mobile = true
		GraphicsQuality.level = int(GameSettings.MOBILE_DEFAULTS["graphics/quality"])
	print("renderizador: ", RenderingServer.get_current_rendering_method(), " · móvil: ", GameSettings.is_mobile())
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().has("auto") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch_auto()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("alumno"):
		var sheet := Control.new()
		sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
		sheet.draw.connect(func() -> void: sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("3a3f48")))
		_swap(sheet)
		await _capture_students(sheet)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("npcs"):
		await _capture_npc_identity()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("equipos"):
		await _capture_class_gear()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("tamano"):
		await _capture_world_size()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("joystick"):
		await _capture_stick_modes()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("solapes"):
		var bad := await _audit_hud_overlaps()
		print("solapes: %d en total" % bad)
		get_tree().quit(1 if bad > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("misiones") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_quest_tracker()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("arbol") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_tree_close()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("muesca"):
		await _capture_safe_area()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("atras"):
		await _capture_back_button()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("actualizacion"):
		# Aviso de actualización (T140) en el título, con un latest.json de mentira.
		Touch.force = true
		get_window().size = Vector2i(2400, 1080)
		var title: Node = load("res://scenes/menu/title_screen.tscn").instantiate()
		_swap(title)
		await _wait(1.0)
		title.call("show_update", UpdateCheck.newer('{"version": "3.2.0", "url": "https://example.invalid/PathOverflow.apk"}', GameVersion.full()))
		await _wait(0.5)
		_save("140_titulo_actualizacion")
		Touch.force = false
		get_window().size = Vector2i(1600, 900)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("continuar"):
		# «Continuar» de un toque en el título (T154), con los personajes de este equipo.
		for touch in [true, false]:
			Touch.force = touch
			get_window().size = Vector2i(2400, 1080) if touch else Vector2i(1600, 900)
			var title: Node = load("res://scenes/menu/title_screen.tscn").instantiate()
			_swap(title)
			await _wait(1.0)
			_save("154_titulo_continuar" + ("_tactil" if touch else ""))
		Touch.force = false
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("tutorial") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch_tutorial()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("editor") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch_editor()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("botones") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch_layouts()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("ventanas") and OS.get_cmdline_user_args().has("tactil"):
		var missed := await _audit_windows_touch()
		print("ventanas táctil: %d botones sin respuesta" % missed)
		get_tree().quit(1 if missed > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("usar") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch_use()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("filtro") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_loot_filter_touch()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("prologo") and OS.get_cmdline_user_args().has("tactil"):
		await _capture_prologue_touch()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("telefono"):
		await _capture_phone()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("tactil"):
		await _capture_touch()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("llegadas"):
		await _capture_arrivals()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("escenas"):
		await _capture_cutscene_direction()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("registro"):
		await _capture_event_log()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("comparar"):
		await _capture_board_compare()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("waypoints"):
		await _capture_waypoint_map()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("profundidad"):
		await _capture_depth()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("salas"):
		await _capture_set_pieces()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("mecanicas"):
		await _capture_mechanics()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("semillas"):
		_capture_zone_seeds()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("prologo"):
		await _capture_prologue_walk()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("combate2"):
		await _capture_combat2()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("rendimiento"):
		await _benchmark()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("habilidades"):
		await _capture_unit_art()
		await _capture_skills_with_rams()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("minimapa"):
		await _capture_minimap()
		await _capture_hire_no()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("editor"):
		var ed: Control = load("res://tools/story_editor.tscn").instantiate()
		_swap(ed)
		await _wait(0.8)
		_save("110_editor_dialogos")
		ed.get("_tabs").current_tab = 1
		await _wait(0.4)
		_save("111_editor_escenas")
		ed.get("_tabs").current_tab = 2
		await _wait(0.4)
		_save("112_editor_misiones")
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("golems"):
		await _capture_unit_art()
		await _capture_icons()
		await _capture_golems_in_world()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("activacion"):
		await _capture_triggers()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("maestria"):
		await _capture_mastery()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("arena"):
		await _capture_arena()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("terrenos"):
		await _capture_terrains()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("ventanas160"):
		await _capture_windows_160()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("ventanas80"):
		await _capture_windows_160(0.8)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("arbol2"):
		await _capture_tree_v2()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("jefes"):
		await _capture_npcs_and_boss()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("capas"):
		await _capture_player_layers()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("pantallas"):
		await _capture_screens_t96()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("arbol3"):
		await _capture_tree_art()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("poses"):
		await _capture_poses()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("ventanas"):
		await _capture_windows()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("sensacion"):
		await _capture_feel()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("roadmap2b"):
		await _capture_roadmap2b()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("roadmap2"):
		await _capture_roadmap2()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("ascendencia"):
		await _capture_ascendancy()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("actos23"):
		await _capture_act1(["brecha_503", "fabrica", "alcantarillas", "modulo_frio", "fosa", "grieta", "bus", "oblea", "puerto_jtag", "memoria_rom", "camara_flash"])
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("acto1"):
		await _capture_act1()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("objetos"):
		await _capture_quest_items()
		await _capture_icons()
		await _capture_interface()
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("combate"):
		await _capture_tree_sectors()
		await _capture_tunnel_dino()
		await _capture_player_states()
		await _capture_paez()
		await _capture_boss_and_affixes()
		await _capture_icons()
		await _capture_combat_hud()
		await _capture_tutorial_start()
		get_tree().quit()
		return
	for shot in MENU_SCENES:
		_swap(load(MENU_SCENES[shot]).instantiate())
		await _wait(1.2)
		_save(shot)
	await _capture_appearances()
	await _capture_prologue()
	await _capture_game()
	await _capture_robotics()
	await _capture_act3()
	get_tree().quit()


## Muestrario: cada peinado (de frente y de espaldas) con barbas y accesorios, y retratos.
func _capture_appearances() -> void:
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	var looks: Array[Dictionary] = []
	for i in CharacterAppearance.HAIR_NAMES.size():
		var a := CharacterAppearance.default()
		a["hair"] = i
		a["beard"] = i % CharacterAppearance.BEARD_NAMES.size()
		a["accessory"] = i % CharacterAppearance.ACCESSORY_NAMES.size()
		a["hair_color"] = CharacterAppearance.HAIR_COLORS[i % CharacterAppearance.HAIR_COLORS.size()]
		a["skin_tone"] = CharacterAppearance.SKIN_TONES[i % CharacterAppearance.SKIN_TONES.size()]
		a["outfit_color"] = CharacterAppearance.OUTFIT_COLORS[(i * 3) % CharacterAppearance.OUTFIT_COLORS.size()]
		a["accent_color"] = CharacterAppearance.ACCENT_COLORS[(i + 1) % CharacterAppearance.ACCENT_COLORS.size()]
		looks.append(CharacterAppearance.sanitize(a))
	sheet.draw.connect(func() -> void:
		UiStyle.draw_background(sheet, sheet.size)
		var font := sheet.get_theme_default_font()
		for i in looks.size():
			var x := 80.0 + i * 150.0
			CharacterAppearance.draw(sheet, Vector2(x, 260), 4.0, looks[i])
			CharacterAppearance.draw(sheet, Vector2(x, 470), 4.0, looks[i], Vector2.UP)
			CharacterAppearance.draw(sheet, Vector2(x, 560), 1.0, looks[i], Vector2.RIGHT)
			sheet.draw_string(font, Vector2(x - 70, 600), CharacterAppearance.HAIR_NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, 140, 12)
			sheet.draw_string(font, Vector2(x - 70, 616), CharacterAppearance.BEARD_NAMES[looks[i]["beard"]], HORIZONTAL_ALIGNMENT_CENTER, 140, 11, UiStyle.MUTED)
			sheet.draw_string(font, Vector2(x - 70, 632), CharacterAppearance.ACCESSORY_NAMES[looks[i]["accessory"]], HORIZONTAL_ALIGNMENT_CENTER, 140, 11, UiStyle.MUTED))
	for i in looks.size():
		var p := CharacterPortrait.new()
		p.appearance = looks[i]
		p.position = Vector2(20.0 + i * 150.0, 660)
		p.size = Vector2(120, 120)
		p.ring_color = Color(CharacterAppearance.OUTFIT_COLORS[(i * 3) % CharacterAppearance.OUTFIT_COLORS.size()]).lightened(0.3)
		sheet.add_child(p)
	_swap(sheet)
	await _wait(0.6)
	_save("00_apariencias")


## El prólogo, paso a paso (sin crear el personaje al final).
func _capture_prologue() -> void:
	var gd: Node = get_node("/root/GameData")
	var look := CharacterAppearance.default()
	look["hair"] = 7
	look["accessory"] = 1
	gd.pending_creation = {"name": "Capturas", "appearance": look}
	var p: Node = load("res://scenes/prologue/prologue.tscn").instantiate()
	_swap(p)
	await _wait(2.0)
	_save("p1_intro")
	p.set("_intro_chars", 9999.0)
	p.set("_phase", "walk")
	p.get("_stage").set("player_x", 292.0)
	await _wait(1.0)
	_save("p2_calle")
	p.call("_go_room", "pasillo", 0.0)
	p.get("_stage").set("player_depth", 0.55)
	p.get("_stage").set("player_lat", -0.2)
	await _wait(0.8)
	_save("p3_pasillo")
	p.get("_stage").set("time", 5.0)
	p.get("_stage").set("player_depth", 0.93)
	p.get("_stage").set("player_lat", -0.7)
	await _wait(0.4)
	_save("p3b_lincecode")
	p.call("_go_room", "oficina", 170.0)
	await _wait(0.6)
	_save("p4_oficina")
	p.call("_play", "prologo_rafa", Callable())
	await _wait(3.0)
	_save("p5_rafa")
	p.get("_cutscene").call("_finish")
	p.call("_open_hire")
	await _wait(0.6)
	_save("p6_contratacion")
	var hire: Node = p.get("_hire")
	for k in 6:
		hire.call("_dodge", Vector2.ZERO)
	await _wait(0.3)
	_save("p6b_boton_no_esquiva")
	hire.call("_on_no_pressed")
	await _wait(0.3)
	_save("p7_boton_no")
	hire.queue_free()
	p.set("_hire", null)
	p.call("_start_console")
	await _wait(1.6)
	_save("p8_consola")
	p.call("_start_arrival")
	await _wait(3.4)
	_save("p8b_llegada_mario")
	p.set("_flags", {"console_done": true})
	p.call("_start_fall")
	await _wait(2.4)
	_save("p9_caida")
	p.call("_start_title")
	await _wait(2.0)
	_save("p10_titulo")
	p.set("_title_time", -999.0)
	gd.pending_creation = {}


func _capture_game() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Capturas", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	c.tokens = 250
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	_save("04_campamento")
	var ui: Node = world.get("ui")
	ui.call("_on_menu_requested", "character")
	await _wait(0.5)
	_save("05_hoja_personaje")
	ui.call("_on_menu_requested", "character")
	ui.call("_on_menu_requested", "inventory")
	ui.call("_on_menu_requested", "skills")
	await _wait(0.5)
	_save("06_inventario_habilidades")
	ui.call("_on_menu_requested", "inventory")
	ui.call("_on_menu_requested", "skills")
	var zone: Node = world.get("zone")
	var npcs: Array = zone.get("npcs")
	for npc in npcs:
		if npc["id"] == "ada":
			world.get("player").global_position = Vector2(npc["position"][0], npc["position"][1] + 60.0)
			world.call("_on_npc_interacted", npc)
	await _wait(2.5)
	_save("07_dialogo")
	ui.get("dialogue_box").call("close")
	ui.call("_on_menu_requested", "passives")
	await _wait(0.8)
	_save("08_arbol")
	ui.call("_on_menu_requested", "passives")
	world.call("travel_to", "fabrica", "")
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	_save("09_acto2_zona")
	world.set("_since_save", -9999.0)


## Ascendencias: el muestrario de las 14 ilustraciones, la elección (dos discos)
## y el árbol de 20 nodos con varios asignados y la ayuda de un nodo.
func _capture_ascendancy() -> void:
	var grid := Control.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ids := []
	for cdef in get_node("/root/GameData").get("classes"):
		for a in cdef["ascendancies"]:
			ids.append([String(a["id"]), String(a["name"])])
	grid.draw.connect(func() -> void:
		grid.draw_rect(Rect2(0, 0, 1600, 900), Color("0c0a10"))
		for k in ids.size():
			var pos := Vector2(20 + (k % 7) * 225, 30 + (k / 7) * 430)
			grid.draw_texture_rect(AscendancyArt.texture(ids[k][0]), Rect2(pos, Vector2(210, 210) * 1.0), false)
			grid.draw_string(grid.get_theme_default_font(), pos + Vector2(0, 236), ids[k][1], HORIZONTAL_ALIGNMENT_CENTER, 210, 14, Color.WHITE))
	_swap(grid)
	await _wait(0.5)
	_save("50_ascendencias_arte")
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Ascendencia", &"full_stack", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 40
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(4.0)   # que se vaya el título de la zona
	var ui: Node = world.get("ui")
	var choice: Variant = ui.get("_choice_panel")
	if choice is Node and is_instance_valid(choice):
		(choice as Node).queue_free()   # la elección de habilidad del nivel 16
	get_tree().paused = false
	ui.call("_on_menu_requested", "passives")
	await _wait(0.4)
	var panel: AscendancyPanel = ui.get("tree_screen").get("_ascendancy_panel")
	panel.open(c)
	panel.set("_hover", 1)
	panel.set("_selected", 0)
	await _wait(0.5)
	_save("51_ascendencia_eleccion")
	c.set_ascendancy(&"devops_integral")
	for n in [15, 16, 17, 18, 19, 13]:
		c.allocate_ascendancy_node(n)
	panel.set("_hover", 14)
	await _wait(0.5)
	_save("52_ascendencia_arbol")
	panel.set("_hover", 9)
	await _wait(0.3)
	_save("53_ascendencia_arbol_bloqueado")
	world.set("_since_save", -9999.0)


## Roadmap 2.0: eventos de zona, cargas en el HUD, variante en K, Mainframe Titán
## y ranuras de chip en el árbol.
func _capture_roadmap2() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Roadmap2", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 30
	var items: ItemDatabase = gd.get("items")
	var titan := Motherboard.new(items.skills.skills["mainframe_titan"], 12, ["DDR4", "DDR5"])
	titan.variant = ""
	c.inventory.boards[2] = titan
	var golem := Motherboard.new(items.skills.skills["golem_hardware"], 12, ["DDR4"])
	golem.variant = "trio"
	c.inventory.boards[3] = golem
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 3:
		c.inventory.add_item(ExpansionChip.roll(30, rng))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(4.0)
	var ui: Node = world.get("ui")
	var choice: Variant = ui.get("_choice_panel")
	if choice is Node and is_instance_valid(choice):
		(choice as Node).queue_free()
	get_tree().paused = false
	var zone: Zone = world.get("zone")
	var player: Node2D = world.get("player")
	var enemies: EnemyManager = world.get("enemies")
	for i in range(enemies.positions.size() - 1, -1, -1):
		if enemies.positions[i].distance_to(player.global_position) < 900.0:
			enemies.lives[i] = 0.0
	for t in Charges.TYPES:
		for k in 3:
			c.gain_charge(t)
	var skills: Node = world.get("skills")
	skills.call("_execute", skills.call("profile", 2), player.global_position)
	skills.call("_execute", skills.call("profile", 3), player.global_position)
	print("eventos: ", zone.events.events.map(func(e: Dictionary) -> String: return "%s@%s" % [e["kind"], str(Vector2i(e["pos"]))]))
	# Junto a un evento visible (santuario, datos huérfanos o deploy).
	for e in zone.events.events:
		if e["kind"] != "ambush":
			player.global_position = zone.free_spot_near(e["pos"] + Vector2(-140, 60))
			break
	await _wait(1.2)
	_save("70_roadmap2_evento_y_cargas")
	ui.call("_on_menu_requested", "skills")
	await _wait(0.5)
	_save("71_roadmap2_variantes_k")
	ui.call("_on_menu_requested", "skills")
	ui.call("_on_menu_requested", "passives")
	await _wait(0.4)
	var view: Node = ui.get("tree_screen").get("_view")
	var sock := c.passives.tree.socket_ids()[0]
	view.set("zoom", 0.9)
	view.call("center_on", c.passives.tree.get_node_data(sock).position)
	await _wait(0.5)
	_save("72_roadmap2_ranura_chip")
	ui.call("_on_menu_requested", "passives")
	world.set("_since_save", -9999.0)


## Los cinco golems nuevos en el mundo, peleando, con sus bonos en el HUD.
func _capture_golems_in_world() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Golems", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona4"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 30
	var ids := ["golem_silicio", "golem_overclock", "golem_utp", "golem_gpu", "golem_kernel"]
	for k in ids.size():
		c.inventory.set_board(k, Motherboard.new(items.skills.skills[ids[k]], 15, []))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	player.mana_reserved = 0.0
	em.clear_all()
	var p := player.global_position
	for k in ids.size():
		skills.call("_summon_unit", skills.profile(k), p + Vector2(-120 + k * 60, 40), Color(items.skills.skills[ids[k]]["icon"]["color"]))
	await _wait(0.5)
	_save("101_golems_quietos")
	for k in 8:
		var id := em.spawn(p + Vector2(260, -150 + k * 40), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
		em.lives[em.index_of(id)] *= 40.0
		em.max_lives[em.index_of(id)] *= 40.0
	for k in 12:
		var id := em.spawn(p + Vector2(-300, -200 + k * 35), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
		em.lives[em.index_of(id)] *= 40.0
	await _wait(2.0)
	_save("102_golems_peleando")
	print("música: ", MusicPlayer.current_track(), " · capa de combate: ", MusicPlayer.combat_layer())
	# Modo daltónico: avisos rayados en el suelo.
	var saved_cb := Ailments.colorblind
	Ailments.colorblind = true
	var elite := em.spawn(player.global_position + Vector2(0, -160), Rarity.Enemy.ELITE, em.type_index_of("bug"))
	var ei := em.index_of(elite)
	em.traits[ei]["heavy_on"] = true
	em.windups[ei] = EnemyManager.HEAVY_WINDUP * 0.5
	em.speeds[ei] = 0.0
	await _wait(0.1)
	_save("103_daltonico_aviso_rayado")
	Ailments.colorblind = saved_cb
	print("bonos de golem: ", c.timed_effects.filter(func(e: Dictionary) -> bool: return String(e["id"]).begins_with("golem:")).map(func(e: Dictionary) -> String: return e["id"]))
	world.set("_since_save", -9999.0)


## Mapa grande (Tab), catálogo de hardware (B), ventana del filtro de botín,
## Shift mostrando lo filtrado y la barra con Q W E R T Y.
func _capture_windows() -> void:
	var saved_scale: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.0)
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Ventanas", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona2"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 20
	c.inventory.add_item(Motherboard.new(items.skills.skills["ping_letal"], 3, []))
	c.inventory.add_item(RamModule.new(items.skills.rams["multicanal"]))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	var player: Player = world.get("player")
	var zone: Zone = world.get("zone")
	player.invulnerable = true
	# Un paseo para que el mapa tenga algo explorado.
	for k in 6:
		player.global_position = zone.free_spot_near(zone.rect.position + zone.rect.size * Vector2(0.15 + k * 0.1, 0.5 + 0.08 * sin(k)))
		ui.world_map.reveal()
	ui.world_map.toggle()
	await _wait(0.4)
	_save("93_mapa_grande")
	ui.world_map.toggle()
	ui.toggle_catalog()
	await _wait(0.4)
	_save("94_catalogo_placas")
	ui.catalog._set_tab("rams")
	await _wait(0.3)
	_save("95_catalogo_ram")
	ui.toggle_catalog()
	# Botín en el suelo con un filtro estricto; luego «con Shift».
	var loot: LootManager = world.get("loot")
	var gen := ItemGenerator.new(items)
	var p := player.global_position
	for k in 10:
		loot.drop_item(gen.generate(20, [Rarity.Item.NORMAL, Rarity.Item.MAGIC, Rarity.Item.RARE][k % 3]), p + Vector2(120 + (k % 5) * 60, -60 + (k / 5) * 80))
	var saved_rules: Dictionary = LootFilter.rules().duplicate()
	LootFilter.apply_preset("estricto")
	ui.toggle_loot_filter()
	await _wait(0.4)
	_save("96_filtro_botin")
	ui.toggle_loot_filter()
	await _wait(0.3)
	_save("97_suelo_filtrado")
	Input.action_press(&"show_all_loot")
	loot.queue_redraw()
	await _wait(0.3)
	_save("98_suelo_con_shift")
	Input.action_release(&"show_all_loot")
	loot.clear_all()
	# Roles: guardián con su aura, sanador curando, francotirador apuntando y un enjambre.
	var em: EnemyManager = world.get("enemies")
	em.clear_all()
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	var base := player.global_position + Vector2(300, 0)
	var role_ids := {}
	for role in EnemyManager.ROLES:
		var off: Vector2 = {"tank": Vector2(0, -60), "healer": Vector2(160, -20), "sniper": Vector2(330, 120), "swarm": Vector2(80, 150)}[role]
		var id := em.spawn(base + off, Rarity.Enemy.NORMAL, bug)
		em.set_role(id, role)
		role_ids[role] = id
	for k in 3:
		var id := em.spawn(base + Vector2(-40 + k * 50, 30), Rarity.Enemy.NORMAL, bug)
		em.lives[em.index_of(id)] *= 0.5
	for k in 3:
		em.set_role(em.spawn(base + Vector2(60 + k * 40, 190), Rarity.Enemy.NORMAL, bug), "swarm")
	var si := em.index_of(role_ids["sniper"])
	em.traits[si]["snipe_on"] = true
	em.windups[si] = EnemyManager.ROLE_SNIPE_WINDUP * 0.4
	em.attack_dirs[si] = (player.global_position - em.positions[si]).normalized()
	em._heal_around(em.index_of(role_ids["healer"]))
	ui.hud.set("_target_id", role_ids["healer"])
	ui.hud.set("_target_linger", 999.0)
	await _wait(0.1)
	_save("99_roles_de_enemigo")
	for k in saved_rules:
		LootFilter.set_rule(k, saved_rules[k])
	GameSettings.set_value("interface", "scale", saved_scale)
	world.set("_since_save", -9999.0)


## RAM de activación: Fork Bomb con Cron Job en la barra («AUTO» y su enfriamiento)
## lanzándose sola entre enemigos, y el menú K con la línea de qué la activa.
func _capture_triggers() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Cron", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona2"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var board := Motherboard.new(items.skills.skills["fork_bomb"], 8, ["DDR4", "DDR5"])
	board.install(RamModule.new(items.skills.rams["cron_job"]), 0)
	c.inventory.set_board(2, board)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)   # que pase el título de la zona
	var player: Player = world.get("player")
	player.invulnerable = true
	var em: EnemyManager = world.get("enemies")
	em.clear_all()
	for k in 5:
		em.spawn(player.global_position + Vector2(260 + k * 30, -80 + k * 40), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	await _wait(2.3)
	_save("131_activacion_barra")
	world.get("ui").call("_on_menu_requested", "skills")
	await _wait(0.5)
	_save("132_activacion_menu_k")
	world.set("_since_save", -9999.0)


## Maestría del árbol: la del Ingeniero DevOps asignada, con la segunda opción
## elegida y su tooltip (las tres opciones, la elegida encendida).
func _capture_mastery() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Maestria", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 30
	gd.current_character = c
	var mastery := -1
	var best := 999
	for n: PassiveNode in c.passives.tree.nodes.values():
		if n.is_mastery() and c.passives.find_path(n.id).size() > 0 and c.passives.find_path(n.id).size() < best:
			best = c.passives.find_path(n.id).size()   # la maestría más cercana a su inicio (árbol 2.0)
			mastery = n.id
	c.passives.allocate_path(mastery, 99)
	c.passives.set_mastery_choice(mastery, 1)
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: Node = world.get("ui")
	if ui.call("is_choosing"):
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	await _wait(2.5)   # que pase el título de la zona
	ui.call("_on_menu_requested", "passives")
	await _wait(0.6)
	var screen: Node = ui.get("tree_screen")
	var view: Node = screen.get("_view")
	view.set("zoom", 0.9)
	view.call("center_on", c.passives.tree.get_node_data(mastery).position + Vector2(260, 0))   # que no lo tape el panel lateral
	screen.call("_on_node_hovered", mastery)
	await _wait(0.5)
	_save("130_arbol_maestria")
	# T83: modo plan con un camino de 6-8 nodos marcado (anillos cian).
	screen.call("_on_node_hovered", -1)
	var plan: PassivePlan = screen.get("_plan")
	for id in c.passives.tree.nodes:
		var steps := plan.shadow.find_path(id).size()
		if steps >= 6 and steps <= 8:
			plan.plan_path(id)
			view.call("center_on", c.passives.tree.get_node_data(id).position + Vector2(200, 0))
			break
	screen.get("_plan_button").button_pressed = true
	await _wait(0.5)
	_save("131_arbol_plan")
	# T85: aplicar el plan: las líneas recién asignadas se iluminan.
	screen.call("apply_plan")
	await _wait(0.12)
	_save("132_arbol_lineas_iluminadas")
	ui.call("_on_menu_requested", "passives")
	world.set("_since_save", -9999.0)


## Mecánicas de arena: losas agrietándose y un agujero, zonas seguras que giran
## y dos adds canalizando hacia el jefe (también en modo daltónico).
func _capture_arena() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Arena", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona2"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	await _wait(2.5)   # que pase el título de la zona
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	em.clear_all()
	var p := player.global_position
	var boss := em.spawn(p + Vector2(320, -60), Rarity.Enemy.UNIQUE, em.type_index_of("bug"))
	var bi := em.index_of(boss)
	em.speeds[bi] = 0.0
	em._resolve_ability(bi, {"kind": "floor_break", "count": 4, "radius": 80.0, "delay": 3.0, "spread": 260.0}, p + Vector2(-260, 120))
	em._resolve_ability(bi, {"kind": "floor_break", "count": 1, "radius": 80.0, "delay": 0.05, "hole_time": 30.0}, p + Vector2(-420, -150))
	em._resolve_ability(bi, {"kind": "safe_zones", "center": [p.x, p.y], "radius": 700.0, "delay": 6.0, "safe_count": 2,
		"safe_distance": 280.0, "safe_radius": 110.0, "spin": 0.4}, p)
	em._resolve_ability(bi, {"kind": "channel_adds", "count": 2, "channel_time": 6.0, "distance": 260.0}, p)
	for id in em._channels:
		em.speeds[em.index_of(id)] = 0.0
	await _wait(1.8)
	_save("127_mecanicas_arena")
	var was_cb := Ailments.colorblind
	Ailments.colorblind = true
	await _wait(0.2)
	_save("128_mecanicas_arena_daltonico")
	Ailments.colorblind = was_cb
	# En la arena de verdad: el Arquitecto, con poca vida, lanza su Hotfix en Producción.
	world.call("travel_to", "jefe", "")
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var cut: Node = ui.get("cutscene")
	if cut.visible:
		cut.call("_finish")
	await _wait(2.5)
	var zone: Zone = world.get("zone")
	var boss_i := -1
	for k in em.count():
		if em.rarities[k] == Rarity.Enemy.UNIQUE:
			boss_i = k
	if boss_i != -1:
		em.lives[boss_i] = em.max_lives[boss_i] * 0.2
		for a in zone.def["boss"]["abilities"]:
			if a["kind"] == "safe_zones":
				em._resolve_ability(boss_i, a, player.global_position)
	await _wait(1.2)
	_save("129_jefe_hotfix_en_produccion")
	world.set("_since_save", -9999.0)


## Terrenos: aceite, estática, refrigerante, aceite ardiendo y superconductor,
## con y sin el modo daltónico (patrón propio por tipo).
func _capture_terrains() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Terrenos", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona2"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	var player: Player = world.get("player")
	var skills: SkillController = world.get("skills")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	em.clear_all()
	var p := player.global_position
	var spots := {"derrame_aceite": Vector2(-420, -120), "campo_estatica": Vector2(-130, -160), "charco_refrigerante": Vector2(160, -160)}
	for sid in spots:
		skills.call("_execute", SkillCalc.compute(Motherboard.new(items.skills.skills[sid], 5, []), c), p + spots[sid])
	# Un segundo aceite, prendido; y estática + refrigerante encimados (superconductor).
	skills.call("_execute", SkillCalc.compute(Motherboard.new(items.skills.skills["derrame_aceite"], 5, []), c), p + Vector2(420, -100))
	skills.call("_ignite_oil_near", p + Vector2(420, -100), 10.0)
	skills.call("_execute", SkillCalc.compute(Motherboard.new(items.skills.skills["campo_estatica"], 5, []), c), p + Vector2(0, 170))
	skills.call("_execute", SkillCalc.compute(Motherboard.new(items.skills.skills["charco_refrigerante"], 5, []), c), p + Vector2(40, 180))
	for k in 6:
		var id := em.spawn(p + Vector2(-480 + k * 190, -40), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
		em.lives[em.index_of(id)] *= 50.0
		em.max_lives[em.index_of(id)] *= 50.0
	await _wait(0.6)
	_save("125_terrenos")
	var was_cb := Ailments.colorblind
	Ailments.colorblind = true
	await _wait(0.2)
	_save("126_terrenos_daltonico")
	Ailments.colorblind = was_cb
	world.set("_since_save", -9999.0)


## Interfaz al 160 % en 900 px de alto: hoja de personaje, habilidades, alijo,
## tienda y waypoints, para ver que ninguna queda bajo el minimapa o las misiones.
func _capture_windows_160(scale := 1.6) -> void:
	var saved_scale: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", scale)
	var tag := "%d" % roundi(scale * 100.0)   # 160, 80...
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Ventanas", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["waypoints"] = ["campamento", "zona1", "zona3", "zona5"]
	c.level = 12
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(2.0)
	var ui: GameUI = world.get("ui")
	ui.call("_on_menu_requested", "character")
	await _wait(0.5)
	_save("120_%s_hoja" % tag)
	ui.call("_on_menu_requested", "character")
	ui.call("_on_menu_requested", "skills")
	await _wait(0.5)
	_save("121_%s_habilidades" % tag)
	ui.call("_on_menu_requested", "skills")
	ui.open_stash(world.get("stash"))
	await _wait(0.5)
	_save("122_%s_alijo" % tag)
	ui.open_shop(Economy.generate_stock(ItemGenerator.new(gd.get("items")), c.level))
	await _wait(0.5)
	_save("123_%s_tienda" % tag)
	ui.shop_panel.open_contraband()
	await _wait(0.5)
	_save("123b_%s_contrabando" % tag)
	ui.open_shop(Economy.generate_gear_stock(ItemGenerator.new(gd.get("items")), c.level), "aida")
	await _wait(0.5)
	_save("123c_%s_aida" % tag)
	ui.close_trade_panels()
	ui.inventory_panel.visible = false
	ui.open_waypoints("campamento")
	await _wait(0.5)
	_save("124_%s_waypoints" % tag)
	GameSettings.set_value("interface", "scale", saved_scale)
	world.set("_since_save", -9999.0)


## Fase "Sensación": catacumbas oscuras con antorchas, proyectiles de fuego y
## rayo que alumbran y enemigos muriendo de cada tipo de daño.
func _capture_feel() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Sensacion", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona4"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 20
	c.inventory.set_board(0, Motherboard.new(items.skills.skills["ping_letal"], 10, []))
	c.inventory.set_board(1, Motherboard.new(items.skills.skills["fork_bomb"], 10, []))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	var zone: Zone = world.get("zone")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	var skills: SkillController = world.get("skills")
	var post: WorldPost = world.get("post")
	player.invulnerable = true
	em.clear_all()
	em.roll_affixes = false
	print("antorchas: %d" % zone.torches.size())
	if not zone.torches.is_empty():
		player.global_position = zone.free_spot_near(zone.torches[0]["pos"] + Vector2(-260, 40))
	await _wait(0.6)
	_save("90_catacumbas_antorchas")
	var p := player.global_position
	for k in 8:
		var id := em.spawn(p + Vector2(280, -180 + k * 50), Rarity.Enemy.NORMAL, em.type_index_of("daemon" if k % 2 == 0 else "bug"))
		em.lives[em.index_of(id)] *= 30.0
	for k in 3:
		skills.call("_execute", skills.profile(0), p + Vector2(400, -100 + k * 100))
	await _wait(0.12)
	print("luces en pantalla: %d" % post.last_lights.size())
	_save("91_proyectiles_que_alumbran")
	for k in em.count():
		em.lives[k] = 1.0
	var kinds := ["fire", "cold", "lightning", "chaos", "physical"]
	for k in range(em.count() - 1, -1, -1):
		em.hit_ailments = {"type": kinds[k % kinds.size()]}
		em.hit_index(k, 10.0, 10.0, 0.0, 150.0)
	em.hit_ailments = {}
	await _wait(0.15)
	_save("92_muertes_con_estilo")
	# T73: muertes físicas por material (chatarra, añicos, carne, bits) y los cuerpos que quedan.
	var by_material := {}
	for k in EnemyManager.enemy_types().size():
		by_material[String(EnemyManager.enemy_types()[k].get("material", "digital"))] = k
	var mats: Array = by_material.keys()
	for k in mats.size():
		em.spawn(p + Vector2(160 + k * 70, 160), Rarity.Enemy.NORMAL, int(by_material[mats[k]]))
	em.hit_ailments = {"type": "physical"}
	for k in range(em.count() - 1, -1, -1):
		em.hit_index(k, 1e9, 1e9, 0.0, 150.0)
	em.hit_ailments = {}
	await _wait(0.12)
	_save("93_muertes_por_material")
	await _wait(1.2)
	print("cadáveres: %d" % em.corpses.size())
	_save("94_cadaveres")
	world.set("_since_save", -9999.0)


## Roadmap 2.0, segunda tanda: golpe pesado de un raro con su frase, esquiva con
## siluetas, casilla de esquiva y cargas en la barra, comparación de objetos y pausa.
func _capture_roadmap2b() -> void:
	var saved_scale: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.0)
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Roadmap2b", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 20
	var conv := Motherboard.new(items.skills.skills["barrido"], 12, ["DDR3", "DDR3"])
	conv.install(RamModule.new(items.skills.rams["transformador_de_tension"]), 0)
	conv.install(RamModule.new(items.skills.rams["volcado_de_buffer"]), 1)
	c.inventory.set_board(0, conv)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.5)
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	get_tree().paused = false
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	em.clear_all()
	em.roll_affixes = false
	for k in 2:
		c.gain_charge("buffer")
	var p := player.global_position
	var melee := em.type_index_of("bug")
	var rare := em.spawn(p + Vector2(150, -40), Rarity.Enemy.ELITE, melee)
	var ri := em.index_of(rare)
	em.lives[ri] *= 20.0
	em.max_lives[ri] *= 20.0
	em.traits[ri]["quote_t"] = EnemyManager.QUOTE_TIME
	em.traits[ri]["heavy_on"] = true
	em.windups[ri] = EnemyManager.HEAVY_WINDUP * 0.45
	em.speeds[ri] = 0.0
	for k in 3:
		em.spawn(p + Vector2(-260, -120 + k * 110), Rarity.Enemy.NORMAL)
	player.dodge()
	await _wait(0.12)
	_save("80_golpe_pesado_esquiva")
	await _wait(0.5)
	var hud: Node = ui.get("hud")
	var plate := Rect2(380, 760, 900, 140)
	var img := get_viewport().get_texture().get_image().get_region(Rect2i(plate))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(ProjectSettings.globalize_path(OUT + "81_barra_esquiva_cargas.png"))
	print("captura: 81_barra_esquiva_cargas (", hud.get("_hotspots")["dodge"].get_global_rect(), ")")
	# Comparación lado a lado: un arma nueva frente a la equipada.
	var gen := ItemGenerator.new(items)
	var weapon: Item = null
	for k in 40:
		var it := gen.generate(20, Rarity.Item.RARE)
		if it.is_equipment() and c.inventory.target_slot_for(it) == "weapon" and c.inventory.equipped("weapon") != null:
			weapon = it
			break
	if weapon:
		ui.item_tooltip.show_item(weapon, c, true)
		Input.warp_mouse(Vector2(800, 120))
		await _wait(0.4)
		_save("82_comparacion_lado_a_lado")
		ui.item_tooltip.hide()
	ui.toggle_pause_menu()
	await _wait(0.4)
	_save("83_pausa_combate")
	ui.toggle_pause_menu()
	GameSettings.set_value("interface", "scale", saved_scale)
	world.set("_since_save", -9999.0)


## Acto I: cada zona con el jugador en el centro y junto a un portal.
func _capture_act1(zone_ids: Array = ["tutorial", "campamento", "zona1", "zona2", "zona3", "zona4", "zona5", "jefe"]) -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("ActoI", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Node2D = world.get("player")
	for zid in zone_ids:
		world.call("travel_to", zid, "")
		world.set("_since_save", -9999.0)
		var zone: Zone = world.get("zone")
		var enemies: EnemyManager = world.get("enemies")
		print("%s: %dx%d, %d enemigos" % [zid, zone.rect.size.x, zone.rect.size.y, enemies.positions.size()])
		await _wait(3.2)   # que pase el título de la zona
		player.global_position = zone.free_spot_near(zone.rect.get_center())
		await _wait(0.6)
		_save("60_zona_%s" % zid)
		if not zone.exits.is_empty():
			var e: Dictionary = zone.exits[0]
			player.global_position = zone.free_spot_near(e["pos"] + Vector2(150.0 if e["pos"].x < zone.rect.get_center().x else -150.0, 60.0))
			await _wait(0.5)
			_save("61_zona_%s_salida" % zid)
	world.set("_since_save", -9999.0)


## Ingeniero DevOps con la ascendencia de robótica: torreta, drones y robot de compañía.
func _capture_robotics() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Robótica", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 25
	c.set_ascendancy(&"hierofante_docs")
	c.allocate_ascendancy_node(1)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.5)
	var skills: Node = world.get("skills")
	var player: Node = world.get("player")
	skills.call("_deploy", skills.call("profile", 0), player.global_position + Vector2(120, 0))
	skills.call("_execute", skills.call("profile", 1), player.global_position)
	await _wait(2.5)
	_save("10_robotica")
	world.set("_since_save", -9999.0)


## Acto III: el Puerto JTAG con M. Páez y Eugenio, combate en la Oblea y el jefe.
func _capture_act3() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Silicio", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "puerto_jtag"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["act2_complete"] = true
	c.flags["llegada_silicio_vista"] = true
	c.level = 30
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(2.5)
	_save("11_puerto_jtag")
	for npc in world.get("zone").get("npcs"):
		if npc["id"] == "m_paez":
			world.get("player").global_position = Vector2(npc["position"][0], npc["position"][1] + 60.0)
			world.call("_on_npc_interacted", npc)
	await _wait(2.2)
	_save("12_dialogo_paez")
	world.get("ui").get("dialogue_box").call("close")
	world.call("travel_to", "oblea", "from_jtag")
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var em: Node = world.get("enemies")
	em.call("clear_all")
	var p: Vector2 = world.get("player").global_position
	for t in [["rootkit", Vector2(420, -120)], ["centinela_bios", Vector2(520, 160)], ["gusano_firmware", Vector2(380, 40)],
			["electromigracion", Vector2(330, -220)], ["condensador", Vector2(240, 120)]]:
		em.call("spawn", p + t[1], Rarity.Enemy.NORMAL, em.call("type_index_of", t[0]))
	world.get("player").set("invulnerable", true)
	await _wait(4.0)
	_save("13_combate_silicio")
	world.call("travel_to", "camara_flash", "from_sector")
	world.set("_since_save", -9999.0)
	await _wait(2.0)
	_save("14_camara_entrada")
	world.get("ui").get("cutscene").call("_finish")
	world.get("player").global_position += Vector2(700, 0)
	await _wait(5.0)
	_save("15_jefe_fw_update")
	world.set("_since_save", -9999.0)


## Árbol pasivo: el sector del templario (automatización y legión), el del hechicero (rayo) y el conjunto.
func _capture_tree_sectors() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Arbol", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 30
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: Node = world.get("ui")
	ui.call("_on_menu_requested", "passives")
	await _wait(0.6)
	var view: Node = ui.get("tree_screen").get("_view")
	var shots := {"25_arbol_templario": [210.0, 1150.0, 0.62], "26_arbol_hechicero": [150.0, 1150.0, 0.62],
		"27_arbol_exploradora": [30.0, 1150.0, 0.62], "28_arbol_guerrero": [-90.0, 1150.0, 0.62]}
	for name in shots:
		var cfg: Array = shots[name]
		view.set("zoom", cfg[2])
		view.call("center_on", Vector2.from_angle(deg_to_rad(cfg[0])) * cfg[1])
		await _wait(0.4)
		_save(name)
	view.set("zoom", 0.2)
	view.call("center_on", Vector2.ZERO)
	await _wait(0.4)
	_save("29_arbol_completo")
	ui.call("_on_menu_requested", "passives")
	world.set("_since_save", -9999.0)


## Escena del túnel del acto I (red_lince): debe verse el dinosaurio aunque la pantalla esté en negro.
func _capture_tunnel_dino() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Tunel", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["act1_reunion"] = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	world.call("play_cutscene", "red_lince")
	var cut: Node = world.get("ui").get("cutscene")
	cut.set("_black", 1.0)
	cut.set("_black_target", 1.0)
	cut.set("_index", 3)
	cut.call("_next")
	await _wait(0.8)
	_save("22_tunel_dino")
	cut.call("_finish")
	world.set("_since_save", -9999.0)


## Estados y buffs sobre el jugador (barra encima del orbe de vida).
func _capture_player_states() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Estados2", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 14
	var items: ItemDatabase = gd.get("items")
	c.inventory.set_board(3, Motherboard.new(items.skills.skills["hiperthreading"], 3, ["DDR4"]))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Player = world.get("player")
	var skills: SkillController = world.get("skills")
	skills.call("_execute", skills.profile(3), player.global_position)
	player.apply_status("shock", 6.0)
	player.apply_status("chill", 6.0)
	player.apply_dot("fuego", 0.1, 8.0, "fire")
	player.apply_dot("veneno", 0.1, 8.0, "chaos")
	player.invulnerable = true
	await _wait(0.8)
	_save("23_estados_jugador")
	player.statuses["freeze"] = 3.0
	await _wait(0.4)
	_save("24_congelado")
	world.set("_since_save", -9999.0)


## Árbol 2.0 (T88): la disposición de data/passive_tree_v2_layout.json en la vista del
## árbol: entero, una región de cerca y el centro.
func _capture_tree_v2() -> void:
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var alloc := PassiveAllocation.new(tree, tree.get_start_node_for_class(&"guerrero"))
	var view := PassiveTreeView.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_swap(view)
	await _wait(0.2)
	view.setup(alloc)
	var colors := {"guerrero": "c84b4b", "duelista": "d9a441", "exploradora": "5cb85c", "hacker": "b04ad9", "hechicero": "4fa3e0", "templario": "e8e0d0"}
	var regions := {}
	for cid in colors:
		regions[tree.get_start_node_for_class(StringName(cid))] = Color(colors[cid])
	view.region_colors = regions
	for shot in [["88_arbol2_entero", Vector2.ZERO, 0.135], ["88_arbol2_region_guerrero", Vector2(0, -1900), 0.42], ["88_arbol2_centro", Vector2(0, 0), 0.5]]:
		view.zoom = shot[2]
		view.center_on(shot[1])
		await _wait(0.4)
		print("dibujo del árbol (%s, zoom %.2f): %.2f ms" % [shot[0], shot[2], view.last_draw_ms])
		_save(shot[0])


## NPC por capas en el campamento y la entrada de un jefe (T103).
func _capture_npcs_and_boss() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Cámara", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.5)
	_save("103_npc_campamento")
	var zone: Zone = world.get("zone")
	if zone and not zone.npcs.is_empty():
		zone.talking_npc = String(zone.npcs[0]["id"])
		world.set("_talking_npc", "")   # que World no lo apague
		world.set_process(false)
		await _wait(0.5)
		_save("103_npc_hablando")
		world.set_process(true)
	var intro := BossIntro.new()
	intro.boss_name = "La Reunión Que Pudo Ser Un Email"
	var em: EnemyManager = world.get("enemies")
	var row := 0
	var types := EnemyManager.enemy_types()
	for k in types.size():
		if String(types[k].get("id", "")).contains("admin") or k == types.size() - 1:
			row = int(types[k].get("sprite_row", k))
			break
	intro.region = EnemySheet.region(row, EnemySheet.Dir.DOWN, 0)
	intro.color = Rarity.enemy_color(Rarity.Enemy.UNIQUE)
	world.add_child(intro)
	await _wait(0.8)
	_save("103_entrada_jefe")
	world.set("_since_save", -9999.0)


## Personaje por capas (T102a): arriba, el dibujo de siempre; debajo, el mismo con las
## hojas horneadas (PlayerSprite), para varias apariencias y poses, a escala 3.
func _capture_player_layers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var looks := [CharacterAppearance.default()]
	for k in 4:
		looks.append(CharacterAppearance.random(rng))
	var poses := [[Vector2.DOWN, {"state": "idle", "time": 0.3}, -1.0], [Vector2.RIGHT, {"state": "walk"}, 1.3],
		[Vector2.UP, {"state": "walk"}, 4.0], [Vector2.RIGHT, {"state": "attack", "t": 0.3, "weapon": "sword"}, -1.0],
		[Vector2.DOWN, {"state": "attack", "t": 0.25, "weapon": "dagger"}, -1.0], [Vector2.LEFT, {"state": "cast", "t": 0.8}, -1.0]]
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cell := Vector2(1600.0 / poses.size(), 900.0 / looks.size())
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("2a2e36"))
		for li in looks.size():
			for pi in poses.size():
				var p: Array = poses[pi]
				var feet := Vector2(cell.x * (pi + 0.3), cell.y * (li + 0.92))
				var pose: Dictionary = p[1].duplicate()
				CharacterAppearance.draw(sheet, feet, 2.6, looks[li], p[0], Color(0, 0, 0, 0), p[2], pose))
	_swap(sheet)
	for li in looks.size():
		for pi in poses.size():
			var p: Array = poses[pi]
			var sp := PlayerSprite.new()
			sheet.add_child(sp)
			sp.appearance = looks[li]
			sp.sprite_scale = 2.6 / PlayerSheet.BAKE_SCALE
			sp.position = Vector2(cell.x * (pi + 0.72), cell.y * (li + 0.92))
			sp.set_pose(p[0], p[1], p[2])
	await _wait(0.5)
	_save("102_capas_comparacion")


## Equipo de oficio de las siete clases (T161), con la hoja: de frente, de lado, de
## espaldas y atacando.
func _capture_class_gear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void: sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("2a2e36")))
	_swap(sheet)
	var poses := [[Vector2.DOWN, {"state": "idle", "time": 0.3}, -1.0], [Vector2.RIGHT, {"state": "walk"}, 1.3],
		[Vector2.UP, {"state": "idle", "time": 0.3}, -1.0], [Vector2.RIGHT, {"state": "attack", "t": 0.3, "weapon": "sword"}, -1.0]]
	var gears := CharacterAppearance.GEARS
	var cell := Vector2(1600.0 / gears.size(), 900.0 / poses.size())
	for gi in gears.size():
		var look := CharacterAppearance.with_gear(CharacterAppearance.random(rng), gears[gi])
		for pi in poses.size():
			var p: Array = poses[pi]
			var sp := PlayerSprite.new()
			sheet.add_child(sp)
			sp.appearance = look
			sp.sprite_scale = 2.4 / PlayerSheet.BAKE_SCALE
			sp.position = Vector2(cell.x * (gi + 0.5), cell.y * (pi + 0.9))
			sp.set_pose(p[0], p[1], p[2])
	await _wait(0.5)
	_save("161_equipos")


## El alumno del estilo del usuario (T176, StudentHero): arriba, apariencias del
## creador (peinados, colores, barba, lentes, audífonos); abajo, el mismo alumno con
## cada conjunto de equipo; de izquierda a derecha, reposo, pasos y el tajo.
func _capture_students(sheet: Control) -> void:
	var rows := [
		[{"hair": 1, "hair_color": "7e4c2e", "skin_tone": "f6c8a0", "outfit_color": "2b4a8a", "eye_color": "5a4632"}, {}, "sword"],
		[{"hair": 2, "hair_color": "0f0d0c", "skin_tone": "8d5a3b", "outfit_color": "8a2b2b", "eye_color": "3a2414", "accessory": 1}, {}, "dagger"],
		[{"hair": 4, "hair_color": "d9b26a", "skin_tone": "f1d2b6", "outfit_color": "2b6b45", "eye_color": "2e6b8a", "accessory": 3, "accent_color": "2fd0a0"}, {}, "mace"],
		[{"hair": 0, "hair_color": "2b2118", "skin_tone": "c99a7a", "outfit_color": "5a3b6b", "eye_color": "3d7a3d", "beard": 2}, {}, "axe"],
		[{"hair": 1, "hair_color": "7e4c2e", "skin_tone": "f6c8a0", "outfit_color": "2b4a8a"}, {"helmet": "casco_de_hierro", "body": "cota_de_placas", "boots": "botas_de_hierro"}, "sword"],
		[{"hair": 1, "hair_color": "7e4c2e", "skin_tone": "f6c8a0", "outfit_color": "2b4a8a"}, {"helmet": "diadema_de_seda", "body": "tunica_de_seda"}, "mace"],
		[{"hair": 6, "hair_color": "6b3d80", "skin_tone": "a8714f", "outfit_color": "2b4a8a"}, {"helmet": "capucha_de_cuero", "body": "chaleco_de_cuero", "boots": "botas_de_cuero"}, "dagger"],
		[{"hair": 3, "hair_color": "d96a9a", "skin_tone": "e0ac8a", "outfit_color": "1d5a66"}, {"body": "chaqueta_de_conferencias"}, "sword"],
	]
	var frames := [["idle", 0], ["walk", 0], ["walk", 2], ["attack", 0], ["attack", 1], ["attack", 2], ["hurt", 0], ["dead", 1]]
	var zoom := 2.0
	for ri in rows.size():
		var r: Array = rows[ri]
		var look := StudentHero.look_of(CharacterAppearance.sanitize(r[0]), r[1])
		var tex := StudentHero.texture(look, r[2])
		for fi in frames.size():
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((StudentHero.first_column(frames[fi][0]) + int(frames[fi][1])) * StudentHero.CELL.x, 0, StudentHero.CELL.x, StudentHero.CELL.y)
			var tr := TextureRect.new()
			tr.texture = at
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.size = Vector2(StudentHero.CELL) * zoom
			tr.position = Vector2((ri % 4) * 400.0 + (fi % 4) * 95.0 - 10.0, floorf(ri / 4.0) * 450.0 + floorf(fi / 4.0) * 110.0 - 10.0)
			sheet.add_child(tr)
	await _wait(0.4)
	_save("176_alumnos")


## NPC con su objeto y su reposo (T162): cada uno de frente y, debajo, de lado, en dos
## momentos (para ver el gesto de reposo: teclear, beber café...).
func _capture_npc_identity() -> void:
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void: sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("2a2e36")))
	_swap(sheet)
	var db: Dictionary = Zone.npc_database().get("npcs", {})
	var ids := []
	var seen := {}
	for id in db:
		var person := String(db[id]["name"]).split(" ")[0].trim_suffix(",")
		if not seen.has(person) and not db[id].get("terminal", false):
			seen[person] = true
			ids.append(id)
	var cols := 8
	var cell := Vector2(1600.0 / cols, 900.0 / ceili(ids.size() / float(cols)) / 2.0)
	for k in ids.size():
		var npc: Dictionary = db[ids[k]]
		for row in 2:
			var sp := PlayerSprite.new()
			sheet.add_child(sp)
			sp.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
			sp.sprite_scale = 2.2 / PlayerSheet.BAKE_SCALE
			if npc.get("ghost", false):
				sp.modulate.a = 0.62
			sp.position = Vector2(cell.x * (k % cols + 0.5), cell.y * ((k / cols) * 2 + row + 0.92))
			var facing := Vector2.DOWN if row == 0 else Vector2.RIGHT
			# De lado, en mitad del gesto de reposo (el sorbo de café llega a los 0,7 s de su ciclo).
			var time := 2.0 if row == 0 else fposmod(Zone.SIP_TIME * 0.5 - k * 0.37, Zone.SIP_EVERY)
			sp.set_pose(facing, Zone.npc_pose(k, time, false, String(npc.get("idle", ""))))
	await _wait(0.5)
	_save("162_npcs")


## Pantallas de T96: título con la ciudad de servidores, selección de personaje con
## pedestal y pose, pantallas de carga de varias zonas y el barrido a medias.
func _capture_screens_t96() -> void:
	_swap(load("res://scenes/menu/title_screen.tscn").instantiate())
	await _wait(1.5)
	_save("96_titulo")
	_swap(load("res://scenes/menu/main_menu.tscn").instantiate())
	await _wait(1.0)
	_save("96_personajes_quieto")
	await _wait(1.9)   # la pose de lucimiento, a mitad
	_save("96_personajes_pose")
	for shot in [["96_carga_servidores", "servers", "Granja de Servidores"], ["96_carga_bosque", "forest", "Bosque de Dependencias"], ["96_carga_lava", "anillo", "Anillo de Fuego"]]:
		var holder := Control.new()
		holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		_swap(holder)
		var card := LoadingCard.new()
		card.zone_name = shot[2]
		card.subtitle = "Nivel de zona 12"
		card.style = shot[1]
		holder.add_child(card)
		await _wait(0.4)
		_save(shot[0])
	var tr := ScreenTransition.new()
	tr._target = ""
	var holder2: Control = load("res://scenes/menu/title_screen.tscn").instantiate()
	_swap(holder2)
	await _wait(0.5)
	holder2.add_child(tr)
	tr.set_process(false)   # quieto a mitad del barrido (sin cambiar de escena)
	tr._t = ScreenTransition.COVER_TIME * 0.55
	await _wait(0.1)
	tr._rect.queue_redraw()
	await _wait(0.1)
	_save("96_barrido")


## Arte del árbol 2.0 (T94): fondo con parallax, marcos, medallones, minimapa y el pulso.
func _capture_tree_art() -> void:
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var alloc := PassiveAllocation.new(tree, tree.get_start_node_for_class(&"guerrero"))
	var view := PassiveTreeView.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_swap(view)
	await _wait(0.2)
	view.setup(alloc)
	var colors := {"guerrero": "c84b4b", "duelista": "d9a441", "exploradora": "5cb85c", "hacker": "b04ad9", "hechicero": "4fa3e0", "templario": "e8e0d0"}
	var regions := {}
	for cid in colors:
		regions[tree.get_start_node_for_class(StringName(cid))] = Color(colors[cid])
	view.region_colors = regions
	# Una build pequeña: hasta la maestría más cercana y un notable más allá.
	var targets: Array = tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.is_mastery())
	targets.sort_custom(func(a: PassiveNode, b: PassiveNode) -> bool: return alloc.find_path(a.id).size() < alloc.find_path(b.id).size() if alloc.find_path(a.id).size() > 0 and alloc.find_path(b.id).size() > 0 else alloc.find_path(a.id).size() > 0)
	var mastery: PassiveNode = targets[0]
	alloc.allocate_path(mastery.id, 99)
	await _wait(1.6)
	for shot in [["94_arbol_lejos", Vector2.ZERO, 0.135], ["94_arbol_region", mastery.position, 0.4], ["94_arbol_cerca", mastery.position, 0.95]]:
		view.zoom = shot[2]
		view.center_on(shot[1])
		await _wait(0.4)
		print("dibujo del árbol (%s, zoom %.2f): %.2f ms" % [shot[0], shot[2], view.last_draw_ms])
		_save(shot[0])
	# El pulso a mitad de camino: asignar un notable a varios pasos y capturar enseguida.
	var far_notable: PassiveNode = null
	for n: PassiveNode in tree.nodes.values():
		var steps := alloc.find_path(n.id).size()
		if n.kind == PassiveNode.Kind.NOTABLE and steps >= 5 and steps <= 8:
			far_notable = n
			break
	if far_notable:
		view.zoom = 0.6
		view.center_on(far_notable.position)
		alloc.allocate_path(far_notable.id, 99)
		await _wait(0.25)
		_save("94_arbol_pulso")


## Poses del jugador (T72): cada estado en cuatro direcciones, con cada arma, a escala 3.
func _capture_poses() -> void:
	var look := CharacterAppearance.default()
	var states := [["idle", 0.0], ["walk", 0.0], ["run", 0.0], ["attack", 0.3], ["attack", 0.5], ["shoot", 0.4],
		["cast", 0.8], ["channel", 0.0], ["hurt", 0.2], ["dodge", 0.5], ["dead", 1.0]]
	var dirs := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]
	var weapons := ["sword", "axe", "mace", "dagger"]
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void:
		UiStyle.draw_background(sheet, sheet.size)
		var font := ThemeDB.fallback_font
		for i in states.size():
			var st: String = states[i][0]
			sheet.draw_string(font, Vector2(30 + i * 140, 40), "%s %.1f" % [st, states[i][1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
			for d in dirs.size():
				var walk := 1.2 if st in ["walk", "run"] else -1.0
				var pose := {"state": st, "t": states[i][1], "time": 0.6, "weapon": weapons[d % weapons.size()] if st != "cast" else "", "glow": Color("e0652f")}
				CharacterAppearance.draw(sheet, Vector2(80 + i * 140, 200 + d * 180), 2.6, look, dirs[d], Color(0, 0, 0, 0), walk, pose))
	_swap(sheet)
	await _wait(0.5)
	_save("72_poses")
	# T74: cada forma de proyectil (normal, ligera y con Menos destellos), a escala 3.
	var shapes := ["orb", "packet", "tracker", "fireball", "shard", "bolt", "glob", "glitch"]
	var colors := [Color("e8e0d0"), Color("e8e0d0"), Color("e8e0d0"), Color("e0652f"), Color("7fb8e0"), Color("e8d070"), Color("6fd36b"), Color("6fd36b")]
	var fx_sheet := Control.new()
	fx_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_sheet.draw.connect(func() -> void:
		UiStyle.draw_background(fx_sheet, fx_sheet.size)
		var font := ThemeDB.fallback_font
		for i in shapes.size():
			fx_sheet.draw_string(font, Vector2(40 + i * 190, 60), shapes[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
			for row in 3:
				fx_sheet.draw_set_transform(Vector2(110 + i * 190, 180 + row * 220), 0.0, Vector2(3, 3))
				SkillFx.draw_projectile(fx_sheet, Vector2.ZERO, Vector2.RIGHT, colors[i], shapes[i], 0.37, row == 1, row == 2)
				fx_sheet.draw_set_transform(Vector2.ZERO))
	_swap(fx_sheet)
	await _wait(0.5)
	_save("74_proyectiles")


## M. Páez: retrato grande, sprite del juego y su aspecto lado a lado con otros NPC.
func _capture_paez() -> void:
	var look: Dictionary = CharacterAppearance.sanitize(Zone.npc_database()["npcs"]["m_paez"]["appearance"])
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void:
		UiStyle.draw_background(sheet, sheet.size)
		CharacterAppearance.draw_head(sheet, Vector2(300, 330), 150.0, look, {"mouth": 0.0})
		CharacterAppearance.draw(sheet, Vector2(700, 520), 6.0, look)
		for k in 4:
			CharacterAppearance.draw(sheet, Vector2(900 + k * 120, 300), 1.06 + k * 1.0, look)
		CharacterAppearance.draw(sheet, Vector2(1000, 520), 1.06, look, Vector2.RIGHT)
		CharacterAppearance.draw(sheet, Vector2(1100, 520), 1.06, look, Vector2.UP))
	_swap(sheet)
	await _wait(0.5)
	_save("19_paez")


## Jefe del acto I con fases, afijos en un élite con resistencias, y auras activas.
func _capture_boss_and_affixes() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Jefe", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "jefe"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 14
	var items: ItemDatabase = gd.get("items")
	c.inventory.set_board(3, Motherboard.new(items.skills.skills["aura_overclock"], 3, ["DDR5"]))
	c.inventory.set_board(4, Motherboard.new(items.skills.skills["dron_medico"], 3, ["DDR5"]))
	c.inventory.set_board(5, Motherboard.new(items.skills.skills["mina_rodante"], 3, ["DDR4"]))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.2)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	skills.call("_execute", skills.profile(3), player.global_position)
	skills.call("_execute", skills.profile(4), player.global_position)
	skills.call("_execute", skills.profile(5), player.global_position)
	var boss_pos := Vector2.ZERO
	for k in em.count():
		if em.rarities[k] == Rarity.Enemy.UNIQUE:
			boss_pos = em.positions[k]
			player.global_position = boss_pos + Vector2(-380, 0)
			em.lives[k] = em.max_lives[k] * 0.5
			em._update_phases(0.1)
	var elite := em.spawn(player.global_position + Vector2(220, -60), Rarity.Enemy.ELITE, em.type_index_of("daemon"), "", 1.0, [], ["ignifugo", "blindado"])
	em.spawn(player.global_position + Vector2(180, 90), Rarity.Enemy.SPECIAL, em.type_index_of("proceso_zombi"), "", 1.0, [], ["toxico"])
	var hud: Node = world.get("ui").get("hud")
	hud.set("_target_id", elite)
	hud.set("_target_linger", 999.0)
	em.apply_ailment(em.index_of(elite), Ailments.BLEED, 10.0)
	await _wait(1.0)
	_save("20_jefe_fases")
	# Con el escudo de fase: invulnerable.
	for k in em.count():
		if em.rarities[k] == Rarity.Enemy.UNIQUE:
			em.lives[k] = em.max_lives[k] * 0.3
	await _wait(0.3)
	_save("21_jefe_fase3")
	world.set("_since_save", -9999.0)


## Muestrario de iconos: todas las habilidades y todos los estados.
func _capture_icons() -> void:
	var gd: Node = get_node("/root/GameData")
	var defs: Array = gd.get("items").skills.skills.values()
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void:
		UiStyle.draw_background(sheet, sheet.size)
		var font := sheet.get_theme_default_font()
		for i in defs.size():
			var r := Rect2(60.0 + (i % 8) * 180.0, 50.0 + (i / 8) * 120.0, 64, 64)
			SkillIcon.draw(sheet, r, defs[i])
			SkillIcon.draw_ailment_pips(sheet, r, defs[i].get("ailments", {}))
			sheet.draw_string(font, r.position + Vector2(-50, 82), defs[i]["name"], HORIZONTAL_ALIGNMENT_CENTER, 164, 12)
		var ids: Array = Ailments.ALL + ["stun", "corrupt", "taunt", "reserve"]
		for k in ids.size():
			var r := Rect2(60.0 + k * 140.0, 560.0, 40, 40)
			StatusIcon.draw(sheet, r, ids[k])
			StatusIcon.draw(sheet, Rect2(r.position + Vector2(48, 14), Vector2(12, 12)), ids[k], true)
			sheet.draw_string(font, r.position + Vector2(-40, 58), Ailments.display_name(ids[k]), HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Ailments.color(ids[k])))
	_swap(sheet)
	await _wait(0.5)
	_save("16_iconos")


## Objetos de misión del suelo: a tamaño real (abajo) y ampliados (arriba).
func _capture_quest_items() -> void:
	var kinds := ["tape", "log", "descriptor", "ice_cache", "kindle_case", "kindle", "concha", "bolillo", "cuernito"]
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("1d2a26"))
		var font := sheet.get_theme_default_font()
		for i in kinds.size():
			var x := 90.0 + i * 170.0
			sheet.draw_set_transform(Vector2(x, 300), 0.0, Vector2(3.5, 3.5))
			QuestItemArt.draw(sheet, Vector2.ZERO, kinds[i], 0.3)
			sheet.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			QuestItemArt.draw(sheet, Vector2(x, 620), kinds[i], 0.3)
			sheet.draw_string(font, Vector2(x - 80, 720), kinds[i], HORIZONTAL_ALIGNMENT_CENTER, 160, 14))
	_swap(sheet)
	await _wait(0.5)
	_save("20_objetos_mision")


## Habilidades con 4-5 RAM, disparando de verdad: abanicos de proyectiles,
## drones e invocaciones con Multicanal, teledirigidos y Pipeline. Imprime por
## cada una las RAM activas y cuántos proyectiles salen.
const RAM_BUILDS := [
	["rafaga_de_paquetes", ["multicanal_mayor", "puntero_salvaje", "propagacion_excepciones", "ecc", "pipeline"]],
	["drones_vigilancia", ["multicanal", "pipeline", "firmware_autonomo", "ecc", "sobretension"]],
	["robot_centinela", ["multicanal_mayor", "puntero_salvaje", "redundancia_invocacion", "sensor_precision", "guiado_laser"]],
	["dron_escolta", ["multicanal", "pipeline", "firmware_resiliente", "pasta_termica"]],
	["paquete_rastreador", ["multicanal_menor", "puntero_salvaje_menor", "ecc_menor", "pipeline"]],
	["cascada_css", ["multicanal", "disipador", "ecc", "refrigeracion_liquida"]],
]


## Prólogo: la calle con el personaje caminando hasta el final (¿se sale de la
## pantalla?), el pasillo y la oficina.
func _capture_prologue_walk() -> void:
	var gd: Node = get_node("/root/GameData")
	gd.set("pending_creation", {"name": "Prueba", "appearance": CharacterAppearance.default()})
	var p: Node = load("res://scenes/prologue/prologue.tscn").instantiate()
	_swap(p)
	await _wait(0.5)
	p.set("_intro_chars", 99999.0)
	p.set("_phase", "walk")
	p.set("_fade", 0.0)
	var stage: PrologueStage = p.get("_stage")
	for x in [120.0, 448.0, 9999.0]:
		Input.action_press(&"move_right")
		var t := 0.0
		while stage.player_x < minf(x, 9000.0) and t < 14.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		Input.action_release(&"move_right")
		await _wait(0.6)
		var screen_x := stage.player_x - stage.cam_x
		print("prólogo calle: player_x %.0f cam_x %.0f → en pantalla x %.0f de 400 %s" % [stage.player_x, stage.cam_x, screen_x, "OK" if screen_x > 12.0 and screen_x < 388.0 else "FUERA"])
		_save("36_prologo_calle_%d" % int(minf(x, 999.0)))
	# Click en la entrada desde lejos: camina y entra solo.
	p.call("_go_room", "calle", 120.0)
	p.set("_target", Vector2(PrologueStage.ENTRANCE_X, PrologueStage.FLOOR_Y))
	p.set("_pending_action", "to_hallway")
	var waited := 0.0
	while stage.room != "pasillo" and waited < 12.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("prólogo: click en la entrada → %s en %.1f s" % [stage.room, waited])
	await _wait(0.9)
	# Pasillo: velocidad lateral en pantalla (debe parecerse a la de la calle, 56 px/s).
	var x0 := PrologueStage.hall_to_screen(stage.player_lat, stage.player_depth).x
	Input.action_press(&"move_right")
	await _wait(1.0)
	Input.action_release(&"move_right")
	var x1 := PrologueStage.hall_to_screen(stage.player_lat, stage.player_depth).x
	print("prólogo pasillo: %.0f px/s de lado" % (x1 - x0))
	_save("37_prologo_pasillo")
	# Click en la puerta de Informática (donde se dibuja): camina y entra.
	var door: Dictionary = p.call("_hotspot_under", Vector2(85, 120))
	p.set("_target", p.call("_hotspot_pos", door) if not door.is_empty() else Vector2.INF)
	p.set("_pending_action", String(door.get("action", "")))
	waited = 0.0
	while stage.room != "oficina" and waited < 12.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("prólogo: click en la puerta de Informática → %s en %.1f s" % [stage.room, waited])
	await _wait(0.9)
	_save("38_prologo_oficina")
	# Click sobre Rafa: camina hasta el escritorio y empieza la conversación.
	var rafa: Dictionary = p.call("_hotspot_under", Vector2(314, 170))
	p.set("_target", p.call("_hotspot_pos", rafa) if not rafa.is_empty() else Vector2.INF)
	p.set("_pending_action", String(rafa.get("action", "")))
	var cut: CutscenePlayer = p.get("_cutscene")
	waited = 0.0
	while not cut.is_playing() and waited < 12.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("prólogo: click en Rafa → conversación %s en %.1f s (x %.0f)" % ["sí" if cut.is_playing() else "NO", waited, stage.player_x])
	await _wait(1.0)
	_save("39_prologo_rafa")
	# La absorción: Mario y Aida llegan y el servidor se los traga (y luego al jugador).
	cut.call("_finish")
	stage.rafa_standing = true
	stage.visitors_x = 112.0
	stage.player_x = 300.0
	p.call("_start_absorb")
	for shot in [[1.0, "40_absorcion_mario"], [1.0, "41_absorcion_aida_rafa"], [2.3, "42_caida_jugador"]]:
		await _wait(shot[0])
		_save(shot[1])
	print("prólogo: absorción %.2f, jugador %.2f, fase %s" % [stage.absorb, stage.player_pull, p.get("_phase")])


## Lo nuevo de combate: elección de habilidad al nivel 16, aura anclada (Torre de
## Señal), torreta atacada por un cazador, una élite con combinación y el HUD al 140 %.
func _capture_combat2() -> void:
	var saved_scale: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.0)
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Combate2", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 16
	var mando := Motherboard.new(items.skills.skills["aura_mando"], 12, ["DDR5", "DDR4"])
	mando.install(RamModule.new(items.skills.rams["torre_senal"]), 0)
	mando.install(RamModule.new(items.skills.rams["enlace_aura"]), 1)
	c.inventory.set_board(0, mando)
	var turret := Motherboard.new(items.skills.skills["ping_letal"], 12, ["DDR3"])
	turret.install(RamModule.new(items.skills.rams["servidor_torreta"]), 0)
	c.inventory.set_board(1, turret)
	c.inventory.set_board(2, Motherboard.new(items.skills.skills["golem_hardware"], 20, []))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.5)
	_save("33_eleccion_nivel_16")
	var ui: GameUI = world.get("ui")
	if ui.is_choosing():
		ui.call("_on_choice_picked", "golem_hardware", func(_s: String) -> void: pass)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	player.mana = 9999.0
	em.clear_all()
	var p := player.global_position
	skills.call("_execute", skills.profile(0), p)
	skills.call("_summon_unit", skills.profile(2), p, Color.WHITE)
	skills.call("_deploy", skills.profile(1), p + Vector2(200, 0))
	player.global_position = p + Vector2(-150, 60)
	em.roll_affixes = false
	for k in 3:
		var hid := em.spawn(p + Vector2(420, -80 + k * 80), Rarity.Enemy.NORMAL, em.type_index_of("gusano"))
		em.lives[em.index_of(hid)] *= 30.0
	var elite := em.spawn(p + Vector2(330, 160), Rarity.Enemy.ELITE, em.type_index_of("bug"), "", 1.0, [], ["ignifugo", "explosivo"])
	em.lives[em.index_of(elite)] *= 30.0
	ui.hud.set("_target_id", elite)
	ui.hud.set("_target_linger", 999.0)
	await _wait(2.5)
	_save("34_aura_anclada_y_cazadores")
	GameSettings.set_value("interface", "scale", 1.4)
	ui.apply_ui_scale()
	await _wait(0.6)
	_save("35_interfaz_140")
	GameSettings.set_value("interface", "scale", 1.6)
	ui.apply_ui_scale()
	await _wait(0.4)
	_save("35_interfaz_160")
	ui.call("_on_menu_requested", "inventory")
	await _wait(0.4)
	_save("35_interfaz_160_inventario")
	ui.call("_on_menu_requested", "inventory")
	ui.call("_on_menu_requested", "character")
	await _wait(0.4)
	_save("35_interfaz_160_personaje")
	ui.call("_on_menu_requested", "character")
	ui.call("_on_menu_requested", "skills")
	await _wait(0.4)
	_save("35_interfaz_160_habilidades")
	ui.call("_on_menu_requested", "skills")
	GameSettings.set_value("interface", "scale", saved_scale)
	world.set("_since_save", -9999.0)


## Rendimiento: 150 y 300 enemigos (con afijos y estados) contra 6 invocaciones,
## drones y auras. Imprime la media y el peor fotograma, y la simulación de enemigos.
func _benchmark() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Bench", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 40
	var kit := ["robot_centinela", "golem_hardware", "dron_escolta", "drones_vigilancia", "aura_mando", "aura_throttling"]
	for i in kit.size():
		c.inventory.set_board(i, Motherboard.new(items.skills.skills[kit[i]], 20, []))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	# A nivel 40 sale la elección de habilidad (que pausa el juego): la primera.
	var bench_ui: GameUI = world.get("ui")
	if bench_ui.is_choosing():
		for b in (bench_ui.get("_choice_panel") as Node).find_children("*", "Button", true, false):
			(b as Button).pressed.emit()
			break
	get_tree().paused = false
	player.invulnerable = true
	player.mana_reserved = 0.0
	player.mana = 9999.0
	for i in kit.size():
		var prof := skills.profile(i)
		if prof["kind"] == "unit":
			for k in 2:
				skills.call("_summon_unit", prof, player.global_position, Color.WHITE)
		else:
			skills.call("_execute", prof, player.global_position)
	var states := [Ailments.BURN, Ailments.SHOCK, Ailments.CHILL, Ailments.POISON, Ailments.BLEED]
	for n in [150, 300]:
		em.clear_all()
		em.roll_affixes = true
		for k in n:
			var id := em.spawn(player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(150.0, 700.0),
				Rarity.Enemy.ELITE if k % 15 == 0 else (Rarity.Enemy.SPECIAL if k % 5 == 0 else Rarity.Enemy.NORMAL))
			var i := em.index_of(id)
			em.lives[i] *= 40.0
			em.max_lives[i] *= 40.0
			em.apply_ailment(i, states[k % states.size()], 10.0, 1.0, 20.0)
		await _wait(1.0)
		var frames := 0
		var total := 0.0
		var worst := 0.0
		var sim := 0.0
		var draw_ms := 0.0
		var mm_ms := 0.0
		var calls := 0.0
		var mm: Control = world.get("ui").get("minimap")
		var start := Time.get_ticks_usec()
		var last := start
		while Time.get_ticks_usec() - start < 4000000:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var dt := (now - last) / 1000.0
			last = now
			frames += 1
			total += dt
			worst = maxf(worst, dt)
			sim += em.last_simulation_ms
			draw_ms += em.last_draw_ms
			mm_ms += float(mm.get("last_draw_ms"))
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		print("  _draw de enemigos %.2f ms, _draw del minimapa %.2f ms, llamadas de dibujo %.0f" % [draw_ms / frames, mm_ms / frames, calls / frames])
		print("rendimiento %d enemigos (%d vivos, %d en cámara): fotograma medio %.2f ms (%.0f FPS), peor %.2f ms, simulación de enemigos %.2f ms, invocaciones %d, proyectiles %d" % [
			n, em.count(), em.last_drawn_count, total / frames, 1000.0 / (total / frames), worst, sim / frames, skills.get("_units").size(), skills.get("_projectiles").size()])
		if n == 300:
			_save("32_rendimiento_300")
	# Calidad gráfica (T98): cada nivel con los 300 enemigos, explosiones incluidas.
	var saved_quality := GraphicsQuality.level
	var fx: BigFx = world.get("big_fx")
	for q in [0, 1, 2]:
		GraphicsQuality.level = q
		await _wait(0.5)
		var frames_q := 0
		var start_q := Time.get_ticks_usec()
		var peak := 0
		while Time.get_ticks_usec() - start_q < 3000000:
			if frames_q % 20 == 0:
				fx.spawn_burst(player.global_position + Vector2(randf_range(-300, 300), randf_range(-200, 200)), 120.0, Color("ff8a3a"))
				(world.get("post") as WorldPost).add_shock(player.global_position)
			await get_tree().process_frame
			frames_q += 1
			peak = maxi(peak, fx.live_particles())
		print("calidad %s: %.2f ms por fotograma, partículas vivas como mucho %d, luces %d" % [GraphicsQuality.name_of(q), 3000.0 / frames_q, peak, (world.get("post") as WorldPost).last_lights.size()])
		_save("98_calidad_%s" % GraphicsQuality.name_of(q))
	GraphicsQuality.level = saved_quality
	# Qué cuesta: se oculta una capa cada vez (con 300 enemigos).
	var ui: GameUI = world.get("ui")
	var zone_node: Node = world.get("zone")
	for layer in ["enemigos", "habilidades", "interfaz", "zona", "nada"]:
		em.visible = layer != "enemigos"
		skills.visible = layer != "habilidades"
		ui.visible = layer != "interfaz"
		if zone_node:
			zone_node.visible = layer != "zona"
		await _wait(0.5)
		var frames := 0
		var start := Time.get_ticks_usec()
		while Time.get_ticks_usec() - start < 2000000:
			await get_tree().process_frame
			frames += 1
		print("  sin %s: %.2f ms por fotograma" % [layer, 2000.0 / frames])
	em.visible = true
	skills.visible = true
	ui.visible = true
	world.set("_since_save", -9999.0)


## Todas las invocaciones persistentes, ampliadas (arriba) y a tamaño real (abajo).
func _capture_unit_art() -> void:
	var gd: Node = get_node("/root/GameData")
	var skills: Dictionary = gd.get("items").skills.skills
	var units: Array = []
	for id in skills:
		if skills[id]["kind"] == "unit":
			units.append(skills[id])
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.draw.connect(func() -> void:
		sheet.draw_rect(Rect2(Vector2.ZERO, sheet.size), Color("1d2a26"))
		var font := sheet.get_theme_default_font()
		# Dos filas: ampliadas ×2.5 y, al lado de cada una, a tamaño real.
		var per_row := ceili(units.size() / 2.0)
		for i in units.size():
			var x := 70.0 + (i % per_row) * (1480.0 / per_row)
			var y := 330.0 + (i / per_row) * 400.0
			var col := Color(units[i].get("icon", {}).get("color", "c8c8c8"))
			sheet.draw_set_transform(Vector2(x, y), 0.0, Vector2(2.5, 2.5))
			UnitArt.draw(sheet, units[i]["id"], units[i]["unit"]["behavior"], Vector2.ZERO, 1.3, col)
			sheet.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			UnitArt.draw(sheet, units[i]["id"], units[i]["unit"]["behavior"], Vector2(x + 38, y + 60), 1.3, col)
			sheet.draw_string(font, Vector2(x - 66, y + 90), units[i]["name"], HORIZONTAL_ALIGNMENT_CENTER, 132, 12))
	_swap(sheet)
	await _wait(0.5)
	_save("31_invocaciones")


func _capture_skills_with_rams() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("RAM", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 30
	for i in RAM_BUILDS.size():
		var ids: Array = RAM_BUILDS[i][1]
		var slots: Array = []
		for rid in ids:
			slots.append(items.skills.rams[rid]["generation"])
		var board := Motherboard.new(items.skills.skills[RAM_BUILDS[i][0]], 20, slots)
		for k in ids.size():
			var problem := board.install(RamModule.new(items.skills.rams[ids[k]]), k)
			if problem != "":
				print("  no se instala %s: %s" % [ids[k], problem])
		c.inventory.set_board(i, board)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.2)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	player.mana_reserved = 0.0
	em.clear_all()
	var p := player.global_position
	for k in 10:
		var id := em.spawn(p + Vector2(330, -200 + k * 45), Rarity.Enemy.NORMAL)
		em.lives[em.index_of(id)] *= 50.0
		em.max_lives[em.index_of(id)] *= 50.0
	for i in RAM_BUILDS.size():
		var prof := skills.profile(i)
		var board: Motherboard = c.inventory.boards[i]
		var before: int = skills.get("_projectiles").size()
		if prof["kind"] == "unit":
			skills.call("_summon_unit", prof, p, Color.WHITE)
		else:
			skills.call("_execute", prof, p + Vector2(300, 0))
		var fired: int = skills.get("_projectiles").size() - before
		print("%s: activas %s · proyectiles %d (salieron %d) · abanico %.0f° · teledirigido %s · daño %.0f-%.0f" % [
			RAM_BUILDS[i][0], str(board.active_supports().size()) if board else "?", prof["projectiles"], fired,
			prof["spread_degrees"], prof["homing"], prof["min_damage"], prof["max_damage"]])
		if i == 0:
			await _wait(0.12)
			_save("28_abanico_rafaga")
	await _wait(2.5)
	_save("29_drones_e_invocaciones")
	var shots := 0
	for pr in skills.get("_projectiles"):
		shots += 1
	print("proyectiles en vuelo tras 2.5 s: %d" % shots)
	# Menú K: RAM y placas sueltas en la bolsa, una RAM seleccionada.
	for rid in ["pipeline", "multicanal_menor", "ecc_mayor", "pasta_termica", "guiado_laser", "carcasa_reforzada", "fuerza_bruta", "sobretension_menor"]:
		c.inventory.add_item(RamModule.new(items.skills.rams[rid]))
	c.inventory.add_item(Motherboard.new(items.skills.skills["ping_letal"], 7, ["DDR5", "DDR4"]))
	c.inventory.add_item(Motherboard.new(items.skills.skills["golem_hardware"], 3, ["DDR3"]))
	c.inventory.boards[3].rams[3] = null   # una ranura libre en el dron escolta
	var ui: GameUI = world.get("ui")
	ui.skills_panel.visible = true
	await _wait(0.2)
	var panel: SkillsPanel = ui.skills_panel
	for i in Inventory.BAG_SIZE:
		var it: Variant = c.inventory.bag[i]
		if it is RamModule and (it as RamModule).family() == "pasta_termica":
			panel.call("_on_bag_clicked", i)
	await _wait(0.4)
	_save("30_menu_habilidades")
	world.set("_since_save", -9999.0)


## Minimapa ampliado en tres sitios: el jefe del acto I con enemigos de cada
## rareza, la Oblea (objetos de misión) y el puerto JTAG (NPCs).
func _capture_minimap() -> void:
	var gd: Node = get_node("/root/GameData")
	for cfg in [["jefe", "boss"], ["oblea", "quest"], ["puerto_jtag", "npcs"]]:
		var c: CharacterData = gd.create_character("Minimapa", &"guerrero", CharacterAppearance.default(), false)
		c.flags["zone"] = cfg[0]
		c.flags["tutorial_step"] = 99
		c.flags["tutorial_seen_done"] = true
		c.flags["quest_paez_kindle_started"] = true
		c.flags["quest_eugenio_panes_started"] = true
		c.level = 20
		gd.current_character = c
		var world: Node = load("res://scenes/game/world.tscn").instantiate()
		_swap(world)
		world.set("_since_save", -9999.0)
		await _wait(1.2)
		var player: Player = world.get("player")
		var em: EnemyManager = world.get("enemies")
		player.invulnerable = true
		if cfg[1] == "boss":
			for k in em.count():
				if em.rarities[k] == Rarity.Enemy.UNIQUE:
					player.global_position = em.positions[k] + Vector2(-700, 200)
			var p := player.global_position
			for r in 4:
				for k in 3:
					em.spawn(p + Vector2(-300 + r * 180, -350 + k * 60), r)
		elif cfg[1] == "quest":
			em.clear_all()
			player.global_position = Vector2(2000, 900)
			var quests: QuestLog = world.get("quests")
			quests.start("eugenio_panes")
			c.flags["item_pan_bolillo"] = true
			quests.refresh()
			await _wait(0.5)
			var tracker: Control = world.get("ui").get("quest_tracker")
			var timg := get_viewport().get_texture().get_image().get_region(Rect2i(tracker.get_global_rect().grow(6.0)))
			timg.resize(timg.get_width() * 2, timg.get_height() * 2, Image.INTERPOLATE_NEAREST)
			timg.save_png(ProjectSettings.globalize_path(OUT + "25_registro_objetos.png"))
		await _wait(1.3)
		var img := get_viewport().get_texture().get_image()
		var mm: Control = world.get("ui").get("minimap")
		var r := Rect2i(mm.get_global_rect().grow(16.0))
		var crop := img.get_region(r)
		crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
		crop.save_png(ProjectSettings.globalize_path(OUT + "25_minimapa_%s.png" % cfg[1]))
		print("captura: minimapa_", cfg[1])
		world.set("_since_save", -9999.0)


## El botón «No» de la contratación tras muchos esquives: pequeño pero legible.
func _capture_hire_no() -> void:
	var p: Node = load("res://scenes/prologue/prologue.tscn").instantiate()
	_swap(p)
	await _wait(0.8)
	p.call("_skip_to_hire")
	await _wait(0.6)
	var hire: Node = p.get("_hire")
	for k in 12:
		hire.call("_dodge", Vector2(-500, -500))
	await _wait(0.3)
	_save("26_contratacion_no")
	hire.call("_on_no_pressed")
	await _wait(0.3)
	_save("27_contratacion_pues_ya_que")


## Objetos de misión en la Oblea, el menú de pausa y la interfaz al 120 % con el
## modo daltónico. Deja los ajustes del jugador como estaban.
func _capture_interface() -> void:
	var saved_scale: Variant = GameSettings.get_value("interface", "scale", 1.0)
	var saved_cb: bool = Ailments.colorblind
	GameSettings.set_value("interface", "scale", 1.0)
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Interfaz", &"hechicero", CharacterAppearance.default(), false)
	c.flags["zone"] = "oblea"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["quest_paez_kindle_started"] = true
	c.flags["quest_eugenio_panes_started"] = true
	c.level = 20
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	em.clear_all()
	player.global_position = Vector2(2450, 620)
	await _wait(1.0)
	_save("21_funda_en_la_oblea")
	var ui: GameUI = world.get("ui")
	ui.toggle_pause_menu()
	await _wait(0.4)
	_save("22_pausa")
	ui.toggle_pause_menu()
	GameSettings.set_value("interface", "scale", 1.2)
	Ailments.colorblind = true
	ui.apply_ui_scale()
	var p := player.global_position
	var states := [Ailments.BURN, Ailments.SHOCK, Ailments.CHILL, Ailments.POISON, Ailments.BLEED, Ailments.FREEZE]
	for k in 6:
		var id := em.spawn(p + Vector2.from_angle(TAU * k / 6.0) * 260.0, Rarity.Enemy.NORMAL)
		em.apply_ailment(em.index_of(id), states[k], 30.0)
	ui.hud.set("_target_id", em.ids[0])
	ui.hud.set("_target_linger", 999.0)
	await _wait(1.0)
	_save("23_interfaz_120_daltonico")
	ui.toggle_pause_menu()
	await _wait(0.4)
	_save("24_pausa_120")
	ui.toggle_pause_menu()
	GameSettings.set_value("interface", "scale", saved_scale)
	Ailments.colorblind = saved_cb
	world.set("_since_save", -9999.0)


## Combate con estados alterados, invocaciones persistentes y el HUD nuevo.
func _capture_combat_hud() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Estados", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 14
	var items: ItemDatabase = gd.get("items")
	c.inventory.set_board(3, Motherboard.new(items.skills.skills["golem_hardware"], 5, ["DDR3", "DDR3"]))
	c.inventory.set_board(4, Motherboard.new(items.skills.skills["dron_escolta"], 5, ["DDR4"]))
	c.inventory.set_board(5, Motherboard.new(items.skills.skills["cascada_css"], 5, ["DDR4"]))
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	em.clear_all()
	var p := player.global_position
	for slot in [1, 3, 4]:
		skills.call("_execute", skills.profile(slot), p)
	skills.call("_deploy", skills.profile(0), p + Vector2(140, 60))
	var states := [Ailments.BURN, Ailments.SHOCK, Ailments.CHILL, Ailments.POISON, Ailments.BLEED, Ailments.FREEZE]
	for k in 12:
		var id := em.spawn(p + Vector2.from_angle(TAU * k / 12.0) * randf_range(260, 380), Rarity.Enemy.ELITE if k == 0 else Rarity.Enemy.NORMAL)
		var i := em.index_of(id)
		em.lives[i] *= 0.7
		em.apply_ailment(i, states[k % states.size()], 30.0)
		if k % 3 == 0:
			em.apply_ailment(i, states[(k + 2) % states.size()], 30.0)
	var target := em.index_of(em.ids[0])
	for id in [Ailments.BURN, Ailments.SHOCK, Ailments.POISON, Ailments.POISON, Ailments.POISON]:
		em.apply_ailment(target, id, 40.0)
	var hud: Node = world.get("ui").get("hud")
	hud.set("_target_id", em.ids[target])
	hud.set("_target_linger", 999.0)
	player.invulnerable = false
	player.apply_dot("prueba_fuego", 0.1, 30.0, "fire")
	player.apply_dot("prueba_veneno", 0.1, 30.0, "chaos")
	player.invulnerable = true
	await _wait(1.2)
	_save("17_estados_y_persistentes")
	# Unos segundos de combate de verdad: las invocaciones pelean y aplican estados.
	hud.set("_target_linger", 0.0)
	for k in 4:
		skills.call("_execute", skills.profile(5), p + Vector2(300, 0).rotated(k * 1.5))
		await _wait(1.0)
	_save("17b_combate")
	var applied := 0
	for i in em.count():
		applied += em.ailments_of(i).size()
	print("combate: %d enemigos vivos, %d estados activos, %d invocaciones, reserva %.0f %%" % [
		em.count(), applied, skills.get("_units").size(), player.mana_reserved * 100.0])
	world.set("_since_save", -9999.0)


## Tutorial recién llegado: los bugs están lejos, B.O.B. al lado.
func _capture_tutorial_start() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Tutorial", &"guerrero", CharacterAppearance.default(), false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.0)
	_save("18_tutorial_inicio")
	var em: EnemyManager = world.get("enemies")
	var player: Player = world.get("player")
	var nearest := INF
	for k in em.count():
		nearest = minf(nearest, em.positions[k].distance_to(player.global_position))
	print("tutorial: %d enemigos, el más cercano a %.0f px; vida %d/%d" % [em.count(), nearest, player.life, player.max_life()])
	world.set("_since_save", -9999.0)


func _swap(node: Node) -> void:
	if _current:
		_current.queue_free()
	_current = node
	add_child(node)


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout


## Controles táctiles (T107): un dedo en el joystick (toques simulados, con su clic
## emulado) y la mira del apuntado automático; luego un toque en el mundo para ir ahí.
func _capture_touch() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"exploradora", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	world.call("travel_to", "zona2", "waypoint")
	await _wait(1.5)
	var player: Player = world.get("player")
	player.set("invulnerable", true)
	var before := player.global_position
	var origin := Vector2(300, 450)
	_touch(0, origin, true)
	for k in 8:
		await get_tree().process_frame
		_drag(0, origin + Vector2(12.0 * (k + 1), -4.0 * (k + 1)))
	await _wait(0.8)
	print("tactil: joystick %s, el jugador se movió %s (por el toque, no hacia el dedo)" % [Touch.stick, player.global_position - before])
	_save("107_joystick")
	_touch(0, origin + Vector2(96, -32), false)
	await _wait(0.3)
	print("tactil: al soltar, joystick %s" % Touch.stick)
	var at := player.global_position
	var tap := player.get_canvas_transform() * (player.global_position + Vector2(-60, 220))   # hacia el pasillo de abajo
	_touch(0, tap, true)
	await get_tree().process_frame
	_touch(0, tap, false)
	await _wait(1.0)
	print("tactil: tras tocar el mundo (-60, 220) más allá, el jugador se movió %s" % (player.global_position - at))
	_save("107_tocar_mundo")
	# Botones (T108): mantener la habilidad 1 arrastrando para apuntar, la esquiva y una poción.
	var hud: Hud = ui.hud
	var to_screen := func(p: Vector2) -> Vector2: return hud.get_global_transform_with_canvas() * p
	var used := [0]
	(world.get("skills") as SkillController).skill_used.connect(func(_i: int) -> void: used[0] += 1)
	var skill_at: Vector2 = to_screen.call(hud.call("_slot_rect", 0).get_center())
	_touch(1, skill_at, true)
	for k in 10:
		await get_tree().process_frame
		_drag(1, skill_at + Vector2(-9.0 * (k + 1), -6.0 * (k + 1)))
	await _wait(1.2)
	print("tactil: manteniendo la habilidad 1 (apuntado a mano %s) se lanzó %d veces" % [Touch.aim_dir, used[0]])
	_save("108_botones")
	_touch(1, skill_at, false)
	await _wait(0.2)
	print("tactil: al soltar, apuntado %s" % Touch.aim_dir)
	var charges := player.dodge_charges
	var dodge_at: Vector2 = to_screen.call(hud.call("_dodge_rect").get_center())
	_touch(2, dodge_at, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_touch(2, dodge_at, false)
	await _wait(0.2)
	print("tactil: esquiva tocada, cargas %.1f -> %.1f" % [charges, player.dodge_charges])
	player.life = player.max_life() * 0.5
	var flask_before := player.flask_at(0).charges if player.flask_at(0) else -1.0
	var flask_at: Vector2 = to_screen.call(hud.call("_flask_rect", 0).get_center())
	_touch(3, flask_at, true)
	await get_tree().process_frame
	_touch(3, flask_at, false)
	await _wait(0.2)
	print("tactil: poción 1 tocada, cargas %s -> %s" % [flask_before, player.flask_at(0).charges if player.flask_at(0) else -1.0])
	# Con la interfaz al 140 % (lo que trae el celular por defecto), que nada se pise.
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	ui.apply_ui_scale()
	await _wait(0.5)
	var tracker_end := ui.quest_tracker.get_global_rect().end.y
	var top_slot := INF
	for i in SkillController.ACTIONS.size():
		top_slot = minf(top_slot, (hud.get_global_transform_with_canvas() * hud.call("_slot_rect", i).position).y)
	print("tactil 140 %%: misiones hasta y=%.0f, la habilidad más alta empieza en y=%.0f" % [tracker_end, top_slot])
	_save("108_botones_140")
	GameSettings.set_value("interface", "scale", scale_was)
	ui.apply_ui_scale()
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Interfaz táctil (T109) a resolución de teléfono (2400×1080 y 1600×720, 20:9) con la
## interfaz al 140 %: partida, inventario con un objeto tocado (tooltip y botón de
## acción), habilidades, hoja de personaje, árbol pasivo (con zoom de dos dedos), mapa
## y pausa. De paso comprueba tocar, mantener, arrastrar y el segundo toque.
func _capture_phone() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	c.level = 14
	var gen := ItemGenerator.new(gd.get("items"))
	for k in 4:
		c.inventory.add_item(gen.generate(14, Rarity.Item.RARE))
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	for res in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		get_window().size = res
		await _wait(0.6)
		var tag := "%dx%d" % [res.x, res.y]
		print("telefono %s: ventana %s, lienzo %s" % [tag, get_window().size, get_viewport().get_visible_rect().size])
		ui.apply_ui_scale()
		await _wait(0.3)
		_save("109_%s_partida" % tag)
		# Inventario: tocar un objeto de la bolsa enseña el tooltip y el botón; el segundo toque equipa.
		ui.call("_on_menu_requested", "inventory")
		await _wait(0.4)
		var cell: ItemCell = null
		for cc in ui.inventory_panel.find_children("*", "ItemCell", true, false):
			if (cc as ItemCell).item != null and (cc as ItemCell).location.get("kind", "") == "bag":
				cell = cc
				break
		if cell:
			var at := cell.get_global_rect().get_center()
			_touch(0, at, true)
			await _wait(0.1)
			_touch(0, at, false)
			await _wait(0.4)
			var action: Button = ui.touch_pointer.get("_action")
			print("telefono %s: tocar un objeto → tooltip %s, botón «%s» %s" % [tag, ui.item_tooltip.visible, action.text, action.visible])
			_save("109_%s_inventario" % tag)
			# Mantener = clic derecho (marca de basura) y lo vuelve a quitar.
			var item := cell.item
			_touch(0, at, true)
			await _wait(0.7)
			_touch(0, at, false)
			await _wait(0.2)
			print("telefono %s: mantener → marca %s" % [tag, "basura" if item.junk else ("bloqueado" if item.locked else "ninguna")])
			while item.junk or item.locked:
				Item.cycle_mark(item)
			# Arrastrar el objeto a otra casilla vacía de la bolsa.
			var empty: ItemCell = null
			var shown_rect: Rect2 = (ui.inventory_panel.get("_scroll") as Control).get_global_rect()
			for cc in ui.inventory_panel.find_children("*", "ItemCell", true, false):
				if (cc as ItemCell).item == null and (cc as ItemCell).location.get("kind", "") == "bag" \
						and shown_rect.encloses((cc as ItemCell).get_global_rect()) and int((cc as ItemCell).location["index"]) > int(cell.location["index"]) + 3:
					empty = cc
					break
			if empty:
				var to := empty.get_global_rect().get_center()
				_touch(0, at, true)
				for k in 12:
					await get_tree().process_frame
					_drag(0, at.lerp(to, (k + 1) / 12.0))
				await get_tree().process_frame
				_touch(0, to, false)
				await _wait(0.3)
				print("telefono %s: arrastrar → el objeto está ahora en la casilla de destino: %s (bolsa %d → %d, destino %s)" % [tag, empty.item == item,
					int(cell.location["index"]), c.inventory.bag.find(item), empty.location])
				# Dos toques en el mismo objeto: el segundo hace la acción (equipar).
				for k in 2:
					_touch(0, to, true)
					await _wait(0.1)
					_touch(0, to, false)
					await _wait(0.3)
				print("telefono %s: dos toques → equipado: %s (%s, se puede equipar: %s)" % [tag, c.inventory.bag.find(item) == -1, item.display_name(), c.can_equip(item)])
		ui.call("_on_menu_requested", "inventory")
		ui.call("_on_menu_requested", "skills")
		await _wait(0.4)
		_save("109_%s_habilidades" % tag)
		ui.call("_on_menu_requested", "skills")
		ui.call("_on_menu_requested", "character")
		await _wait(0.4)
		_save("109_%s_personaje" % tag)
		ui.call("_on_menu_requested", "character")
		ui.call("_on_menu_requested", "passives")
		await _wait(0.6)
		var view: PassiveTreeView = ui.tree_screen.get("_view")
		var zoom_before := view.zoom
		var mid := view.get_global_rect().get_center()
		_touch(0, mid - Vector2(60, 0), true)
		await get_tree().process_frame
		_touch(1, mid + Vector2(60, 0), true)
		for k in 10:
			await get_tree().process_frame
			_drag(1, mid + Vector2(60 + 12 * (k + 1), 0))
			_drag(0, mid - Vector2(60 + 12 * (k + 1), 0))
		_touch(1, mid + Vector2(180, 0), false)
		_touch(0, mid - Vector2(180, 0), false)
		await _wait(0.3)
		print("telefono %s: dos dedos en el árbol → zoom %.2f → %.2f" % [tag, zoom_before, view.zoom])
		_save("109_%s_arbol" % tag)
		ui.call("_on_menu_requested", "passives")
		await _wait(0.3)
		ui.world_map.toggle()
		await _wait(0.3)
		_save("109_%s_mapa" % tag)
		ui.world_map.toggle()
		var pause: Button = ui.touch_buttons.get_child(1)
		pause.pressed.emit()
		await _wait(0.4)
		_save("109_%s_pausa" % tag)
		pause.pressed.emit()
		await _wait(0.3)
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## `p` en coordenadas del lienzo; el toque llega en las de la ventana (otra cosa a
## resolución de teléfono, donde el lienzo se estira).
## Ataque automático (T151): con enemigos cerca, 2 s caminando con el joystick sin
## tocar nada más, con el interruptor apagado y encendido (se enciende tocándolo).
## Tamaño del mundo (T156): el campamento y la zona 1 con unos enemigos, a 2400×1080
## en táctil, con la cámara al 100, 130 y 140 %. Deja la opción como estaba.
func _capture_world_size() -> void:
	var before := GraphicsQuality.world_zoom_choice()
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Zoom", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	Touch.force = true
	get_window().size = Vector2i(2400, 1080)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	var player: Player = world.get("player")
	player.set("invulnerable", true)
	for zone_id in ["campamento", "zona1"]:
		world.call("travel_to", zone_id, "waypoint")
		await _wait(1.0)
		if zone_id == "zona1":
			var enemies: EnemyManager = world.get("enemies")
			enemies.clear_all()
			for k in 5:
				enemies.spawn(player.global_position + Vector2.from_angle(k * TAU / 5.0) * 220.0, Rarity.Enemy.NORMAL)
		for z in [1.0, 1.3, 1.4]:
			GraphicsQuality.set_world_zoom_choice(z)
			player.apply_world_zoom()
			await _wait(0.6)
			_save("156_%s_%d" % [zone_id, roundi(z * 100.0)])
	GraphicsQuality.set_world_zoom_choice(before)
	Touch.force = false
	get_window().size = Vector2i(1600, 900)


func _capture_touch_auto() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Auto", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	Touch.force = true
	SkillController.touch_auto = false
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	world.call("travel_to", "zona1", "waypoint")
	await _wait(1.5)
	var player: Player = world.get("player")
	player.set("invulnerable", true)
	var enemies: EnemyManager = world.get("enemies")
	var skills: SkillController = world.get("skills")
	var casts := [0]
	skills.skill_used.connect(func(i: int) -> void:
		if i == 0:
			casts[0] += 1)
	var tc := ui.touch_controls
	for on in [false, true]:
		if on:   # tocar el interruptor
			var at := ui.hud.get_global_transform_with_canvas() * ui.hud.auto_rect().get_center()
			_touch(1, at, true)
			await get_tree().process_frame
			_touch(1, at, false)
			await _wait(0.2)
		enemies.clear_all()
		for k in 6:
			enemies.spawn(player.global_position + Vector2.from_angle(k * TAU / 6.0) * 140.0, Rarity.Enemy.NORMAL)
		casts[0] = 0
		var start := tc.get_global_transform_with_canvas() * (tc.fixed_base() + Vector2(0, -20))
		_touch(0, start, true)
		for k in 6:
			await get_tree().process_frame
			_drag(0, start + Vector2(8.0 * (k + 1), 0))
		await _wait(2.0)
		_save("151_auto_%s" % ("encendido" if on else "apagado"))
		_touch(0, start + Vector2(48, 0), false)
		print("auto %s (interruptor %s): caminando 2 s, la habilidad 1 salió %d veces" % ["encendido" if on else "apagado", SkillController.touch_auto, casts[0]])
	SkillController.touch_auto = false
	Touch.force = false
	world.queue_free()


## Joystick a gusto (T149): en cada modo, apoyar el pulgar y arrastrarlo 300 px a la
## derecha (más que el radio): cuánto se inclina, dónde queda la base y cuánto camina.
func _capture_stick_modes() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	Touch.load_layout()
	var mode_was := Touch.stick_mode
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	var player: Player = world.get("player")
	var tc := ui.touch_controls
	for mode in Touch.STICK_MODES:
		Touch.stick_mode = mode
		await _wait(0.3)
		if mode == "fijo":
			_save("149_joystick_fijo_en_reposo")
		var start := tc.get_global_transform_with_canvas() * (tc.fixed_base() + Vector2(-20, -30))
		var before := player.global_position
		_touch(0, start, true)
		for k in 15:
			await get_tree().process_frame
			_drag(0, start + Vector2(20.0 * (k + 1), 0))
		await _wait(0.6)
		var origin: Vector2 = tc.get("_origin")
		print("joystick %s: inclinado %s, base en %s (el dedo empezó en %s), caminó %.0f px" % [mode, Touch.stick.round(),
			(tc.get_global_transform_with_canvas() * origin).round(), start.round(), player.global_position.distance_to(before)])
		_save("149_joystick_%s" % mode)
		_touch(0, start + Vector2(300, 0), false)
		await _wait(0.3)
	Touch.stick_mode = mode_was
	Touch.force = false
	world.queue_free()


## Comprobador de solapes del HUD (T147): en partida, con 5 misiones, el tutorial a la
## vista, un aviso en pantalla y algo que recoger cerca, recoge el rectángulo de cada
## cosa (botones táctiles uno a uno, orbes, pociones, ☰, minimapa, Mapa/II, registro
## de misiones, registro de sucesos, tutorial y aviso) y cuenta las parejas que se pisan,
## en táctil (esquina y arcos, diestro y zurdo, botones al 100 % y al 130 %) a 2400×1080 y
## 1600×720 con la interfaz al 140 %, y en el PC a 1600×900 al 100 %.
func _audit_hud_overlaps() -> int:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Solapes", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_version"] = 3
	c.flags["tutorial_step"] = 7   # «habla con Aida»: con texto largo y aro
	c.flags["llegada_campamento_vista"] = true
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	Touch.load_layout()
	var touch_was := [Touch.layout, Touch.button_scale, Touch.left_handed, Touch.custom.duplicate(true)]
	Touch.custom = {}
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	var quests: QuestLog = world.get("quests")
	var n := 0
	for id in quests.defs:
		if n >= 5:
			break
		if quests.start(String(id)):
			n += 1
	ui.quest_tracker.call("_refresh")
	var player: Player = world.get("player")
	(world.get("loot") as LootManager).drop_item(ItemGenerator.new(gd.get("items")).generate(5, Rarity.Item.RARE), player.global_position + Vector2(50, 0))
	var total := 0
	var configs := []
	for res in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		for lay in ["esquina", "arcos"]:
			for left in [false, true]:
				for bs in [1.0, 1.3]:
					configs.append([res, true, lay, left, bs, 1.4])
	configs.append([Vector2i(1600, 900), false, "esquina", false, 1.0, 1.0])
	for cfg in configs:
		get_window().size = cfg[0]
		Touch.force = cfg[1]
		Touch.layout = cfg[2]
		Touch.left_handed = cfg[3]
		Touch.button_scale = cfg[4]
		GameSettings.set_value("interface", "scale", cfg[5])
		await _wait(0.3)
		ui.apply_ui_scale()
		ui.hud.flash("Un aviso cualquiera, con su texto entero para medirlo.", UiStyle.ACCENT)
		await _wait(0.5)
		var rects := _hud_rects(ui)
		var hits: Array[String] = []
		var keys := rects.keys()
		var view := get_viewport().get_visible_rect()
		for a in keys.size():
			var ra: Rect2 = rects[keys[a]]
			if not view.encloses(ra.grow(-1.0)):
				hits.append("%s se sale" % keys[a])
			for b in range(a + 1, keys.size()):
				if ra.grow(-1.0).intersects((rects[keys[b]] as Rect2).grow(-1.0)):
					hits.append("%s / %s" % [keys[a], keys[b]])
		var tag := "%dx%d %s%s%s %d%%" % [cfg[0].x, cfg[0].y, cfg[2] if cfg[1] else "PC", " zurdo" if cfg[3] else "", "", roundi(cfg[4] * 100.0)]
		print("solapes %s: %s" % [tag, "ninguno" if hits.is_empty() else ", ".join(hits)])
		if not hits.is_empty():
			_save("147_" + tag.replace(" ", "_").replace("%", ""))
		total += hits.size()
	Touch.layout = touch_was[0]
	Touch.button_scale = touch_was[1]
	Touch.left_handed = touch_was[2]
	Touch.custom = touch_was[3]
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()
	return total


## Rectángulos (en el lienzo) de lo que se ve del HUD y la interfaz de partida.
func _hud_rects(ui: GameUI) -> Dictionary:
	var out := {}
	var hud := ui.hud
	var to := hud.get_global_transform_with_canvas()
	var conv := func(r: Rect2) -> Rect2: return Rect2(to * r.position, r.size * to.get_scale())
	var life: Vector2 = hud.call("_life_center")
	var mana: Vector2 = hud.call("_mana_center")
	var orb := Vector2.ONE * Hud.ORB_RADIUS
	out["orbe de vida"] = conv.call(Rect2(life - orb, orb * 2.0))
	out["orbe de maná"] = conv.call(Rect2(mana - orb, orb * 2.0))
	if hud.touch_layout:
		for k: String in hud.touch_rects():
			out[k] = conv.call(hud.touch_rects()[k])
		if not hud.use_now.is_empty():
			var u := hud.use_rect()
			out["use"] = conv.call(u.grow_individual(0.0, Hud.USE_LABEL_GAP + Hud.USE_LABEL_H, 0.0, 0.0))   # con su texto encima
	for pair in [["minimapa", ui.minimap], ["misiones", ui.quest_tracker], ["sucesos", ui.event_log], ["Mapa/II", ui.touch_buttons],
			["tutorial", ui.tutorial], ["aviso", hud.get("_message")]]:
		var ctl: Control = pair[1]
		if ctl and ctl.is_visible_in_tree():
			var r := ctl.get_global_rect()
			if pair[0] == "aviso":   # el aviso ocupa todo el ancho: lo que mide es su texto
				var lab := ctl as Label
				var w := lab.get_theme_font("font").get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lab.get_theme_font_size("font_size")).x * to.get_scale().x
				r = Rect2(r.get_center().x - w / 2.0, r.position.y, w, r.size.y)
			if r.size.x > 0.0 and r.size.y > 0.0:
				out[pair[0]] = r
	return out


## Registro de misiones en el celular (T146): con 6 misiones a 2400×1080 y 1600×720 y la
## interfaz al 140 %, en las dos distribuciones: no pisa ningún botón; tocar la cabecera
## pasa de resumen a todas y a plegado; en una pelea se pliega.
func _capture_quest_tracker() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Misiones", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.load_layout()
	var layout_was := Touch.layout
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	var quests: QuestLog = world.get("quests")
	var started := 0
	for id in quests.defs:
		if started >= 6:
			break
		if quests.start(String(id)):
			started += 1
	ui.quest_tracker.setup(quests) if ui.quest_tracker.quests == null else ui.quest_tracker.call("_refresh")
	var tracker := ui.quest_tracker
	for res in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		get_window().size = res
		await _wait(0.5)
		ui.apply_ui_scale()
		for lay in ["esquina", "arcos"]:
			Touch.layout = lay
			tracker.chosen_view = QuestTracker.View.ALL
			tracker.call("_refresh")
			await _wait(0.5)
			var r := tracker.get_global_rect()
			var hits: Array[String] = []
			var to_canvas := ui.hud.get_global_transform_with_canvas()
			for o: Rect2 in ui.hud.touch_obstacles():
				var oc := Rect2(to_canvas * o.position, o.size * to_canvas.get_scale())
				if tracker.visible and r.intersects(oc):
					hits.append(str(oc.position.round()))
			var tag := "%dx%d_%s" % [res.x, res.y, lay]
			print("misiones %s: %d activas, se ve «%s» (pidió «todas»), de y=%.0f a y=%.0f, %s" % [tag, quests.active_ids().size(),
				["resumen", "todas", "plegado"][tracker.shown_view], r.position.y, r.end.y, "no pisa nada" if hits.is_empty() else "PISA " + ", ".join(hits)])
			_save("146_%s" % tag)
	tracker.in_combat = true
	await _wait(0.2)
	print("misiones: en pelea se ve «%s»" % ["resumen", "todas", "plegado"][tracker.shown_view])
	tracker.in_combat = false
	Touch.layout = layout_was
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Árbol de pasivas con el dedo (fallo visto en el celular): abrirlo desde el ☰ y
## cerrarlo tocando «Cerrar», a 2400×1080 con la interfaz al 140 %.
func _capture_tree_close() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Árbol", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.force = true
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.4)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.apply_ui_scale()
	ui.call("_on_menu_requested", "passives")
	await _wait(0.6)
	var close: Button = ui.tree_screen.get("_close_button")
	var at := _canvas_point(close, close.size / 2.0)
	print("árbol: abierto %s, «Cerrar» visible %s en %s (pantalla %s)" % [ui.tree_screen.visible, close.is_visible_in_tree(), at.round(), get_viewport().get_visible_rect().size])
	_save("fix_arbol_abierto")
	_touch(0, at, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_touch(0, at, false)
	await _wait(0.5)
	print("árbol: tras tocar «Cerrar», abierto %s" % ui.tree_screen.visible)
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	world.queue_free()


## Muesca y tooltips en el celular (T142): a 2400×1080 con la interfaz al 140 % y una
## muesca simulada de 120 px a la izquierda (y 40 px de esquinas a la derecha): la
## interfaz se aparta; un tooltip comparando con lo equipado va apilado y cabe en alto.
func _capture_safe_area() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Muesca", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var gen := ItemGenerator.new(gd.get("items"))
	var equipped := gen.generate(30, Rarity.Item.RARE)
	while not equipped.is_equipment() or String(equipped.base.get("slot", "")) != "body":
		equipped = gen.generate(30, Rarity.Item.RARE)
	c.inventory.add_item(equipped)
	c.inventory.equip_from_bag(c.inventory.bag.find(equipped))
	var rival := gen.generate(30, Rarity.Item.ULTRA_RARE)
	while String(rival.base.get("slot", "")) != "body":
		rival = gen.generate(30, Rarity.Item.ULTRA_RARE)
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.force = true
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.4)
	UiStyle.test_safe_area = Rect2i(120, 0, 2400 - 120 - 40, 1080)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.apply_ui_scale()
	await _wait(0.4)
	var root: Control = ui.get("_root")
	var life: Vector2 = ui.hud.call("_life_center")
	print("muesca: la interfaz empieza en x=%.0f (lienzo; 120 px de ventana = %.0f), el orbe de vida en x=%.0f" % [root.position.x, 120.0 * 2000.0 / 2400.0, (root.get_global_transform_with_canvas() * life).x])
	_save("142_muesca")
	ui.call("_on_menu_requested", "inventory")
	await _wait(0.3)
	var mouse := Vector2(1100, 300)
	Input.warp_mouse(get_viewport().get_final_transform() * mouse)
	ui.item_tooltip.show_item(rival, c, true)
	await _wait(0.5)
	var tip: ItemTooltip = ui.item_tooltip
	var sides: Array = tip.get("_sides")
	var view := get_viewport().get_visible_rect().size
	var bottom := tip.get_global_rect().end.y
	for s in sides:
		if (s as Control).visible:
			bottom = maxf(bottom, (s as Control).get_global_rect().end.y)
	print("muesca: tooltip a escala %.2f, con %d equipado(s), de y=%.0f a y=%.0f (pantalla %.0f): %s" % [tip.scale.x, sides.filter(func(s: Control) -> bool: return s.visible).size(),
		tip.get_global_rect().position.y, bottom, view.y, "cabe" if bottom <= view.y else "SE SALE"])
	_save("142_tooltip_comparando")
	UiStyle.test_safe_area = Rect2i()
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Botón Atrás y app en segundo plano (T141): en el menú pregunta antes de salir; en
## partida, Atrás cierra el inventario y luego abre la pausa; salir de la app guarda y pausa.
func _capture_back_button() -> void:
	var gd: Node = get_node("/root/GameData")
	Touch.force = true
	var menu: Node = load("res://scenes/menu/main_menu.tscn").instantiate()
	_swap(menu)
	await _wait(0.8)
	menu.call("ask_quit")
	await _wait(0.4)
	var dialog: ConfirmationDialog = menu.get("_quit_dialog")
	print("atrás en el menú: «%s» %s" % [dialog.dialog_text, "a la vista" if dialog.visible else "NO SE VE"])
	_save("141_menu_salir")
	dialog.hide()
	var c: CharacterData = gd.create_character("Atrás", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.call("_on_menu_requested", "inventory")
	await _wait(0.3)
	gd.call("go_back")
	await _wait(0.3)
	var inv_closed := not ui.inventory_panel.visible
	gd.call("go_back")
	await _wait(0.3)
	var pause_open: bool = (ui.get("_pause_panel") as Control).visible
	print("atrás en partida: cierra el inventario %s, luego abre la pausa %s" % [inv_closed, pause_open])
	gd.call("go_back")
	await _wait(0.3)
	await _wait(1.1)
	var since_before: float = world.get("_since_save")
	world.call("app_left")
	var since_after: float = world.get("_since_save")
	await _wait(0.3)
	print("salir de la app: guardado %s (%.1f s → %.1f s desde el último), pausa abierta %s" % [since_after < since_before, since_before, since_after,
		(ui.get("_pause_panel") as Control).visible])
	_save("141_app_en_segundo_plano")
	Touch.force = false
	world.queue_free()


## Tutorial con el dedo (T138): el texto táctil de varios pasos y el aro «¡Aquí!»
## sobre su botón (la habilidad grande, el ☰, la poción 1).
func _capture_touch_tutorial() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["llegada_campamento_vista"] = true
	c.flags["tutorial_version"] = 2
	c.flags["tutorial_step"] = 1
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.5)
	ui.apply_ui_scale()
	var text: RichTextLabel = ui.tutorial.get("_text")
	for step in [["use_skill", 1], ["equip", 4], ["flask", 5]]:
		c.flags["tutorial_step"] = step[1]
		ui.tutorial.call("_refresh")
		await _wait(0.5)
		var r: Rect2 = ui.hud.tutorial_rect(ui.hud.tutorial_point)
		print("tutorial %s: «%s…», aro en %s sobre %s" % [step[0], text.get_parsed_text().substr(0, 60), ui.hud.tutorial_point, r])
		_save("138_tutorial_%s" % step[0])
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Editor de disposición táctil (T137) con toques simulados: arrastrar la habilidad 1,
## agrandar la esquiva, bajar la opacidad, «Listo» (se guarda) y «Restaurar».
func _capture_touch_editor() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.load_layout()
	var custom_was := Touch.custom.duplicate(true)
	var opacity_was := Touch.button_opacity
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.5)
	ui.apply_ui_scale()
	ui.toggle_pause_menu()
	await _wait(0.3)
	ui.open_touch_editor()
	await _wait(0.4)
	var ed := ui.touch_editor
	var hud := ui.hud
	var before: Dictionary = hud.touch_rects()
	var to_canvas := func(p: Vector2) -> Vector2: return ed.get_global_transform_with_canvas() * p
	# Arrastrar la habilidad 1 hacia arriba a la izquierda.
	var from: Vector2 = to_canvas.call((before["skill_0"] as Rect2).get_center())
	_touch(0, from, true)
	for k in 10:
		await get_tree().process_frame
		_drag(0, from + Vector2(-16.0, -10.0) * (k + 1))
	_touch(0, from + Vector2(-160, -100), false)
	await _wait(0.2)
	# Tocar la esquiva y agrandarla dos veces; bajar la opacidad.
	var dodge_at: Vector2 = to_canvas.call((before["dodge"] as Rect2).get_center())
	_touch(0, dodge_at, true)
	await get_tree().process_frame
	_touch(0, dodge_at, false)
	await _wait(0.2)
	for b: Button in ed.find_children("*", "Button", true, false):
		if b.text == "Más grande":
			for k in 2:
				b.pressed.emit()
		elif b.text.begins_with("Opacidad"):
			b.pressed.emit()
	await _wait(0.3)
	var after: Dictionary = hud.touch_rects()
	print("editor: habilidad 1 %s → %s" % [(before["skill_0"] as Rect2).get_center().round(), (after["skill_0"] as Rect2).get_center().round()])
	print("editor: esquiva %d → %d px, opacidad %d %%" % [(before["dodge"] as Rect2).size.x, (after["dodge"] as Rect2).size.x, roundi(Touch.button_opacity * 100.0)])
	_save("137_editor")
	ed.close()
	await _wait(0.3)
	ui.toggle_pause_menu()
	await _wait(0.4)
	_save("137_partida_editada")
	Touch.custom = {}
	Touch.load_layout()
	print("editor: guardado en settings.cfg: %s, la pausa vuelve al cerrar: %s" % [Touch.custom.has("skill_0") and Touch.custom.has("dodge"), not ed.visible])
	Touch.reset_custom()
	Touch.custom = custom_was
	Touch.button_opacity = opacity_was
	Touch.save_layout()
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Distribuciones de los botones táctiles (T136) a 2400×1080 y 1600×720 con la
## interfaz al 140 %: esquina, arcos, esquina al 120 % y esquina zurda (con el ☰
## abierto). Mira que ningún botón pise a otro, ni a las misiones, ni se salga.
func _capture_touch_layouts() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	c.level = 14
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.load_layout()
	var saved := [Touch.layout, Touch.button_scale, Touch.left_handed]
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	world.call("travel_to", "zona1", "waypoint")
	await _wait(1.5)
	var player: Player = world.get("player")
	player.set("invulnerable", true)
	(world.get("loot") as LootManager).drop_item(ItemGenerator.new(gd.get("items")).generate(5, Rarity.Item.RARE), player.global_position + Vector2(60, 20))
	var hud: Hud = ui.hud
	for res in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		get_window().size = res
		await _wait(0.5)
		ui.apply_ui_scale()
		for cfg in [["esquina", 1.0, false, false], ["arcos", 1.0, false, false], ["esquina", 1.2, false, false], ["esquina", 1.0, true, true]]:
			Touch.layout = cfg[0]
			Touch.button_scale = cfg[1]
			Touch.left_handed = cfg[2]
			await _wait(0.3)
			hud.set("_menu_open", cfg[3])
			hud.call("_layout")
			await _wait(0.4)
			var rects := {}
			for i in SkillController.ACTIONS.size():
				rects["habilidad %d" % (i + 1)] = hud.call("_slot_rect", i)
			rects["esquiva"] = hud.call("_dodge_rect")
			rects["usar"] = hud.use_rect()
			for i in Inventory.FLASK_SLOTS:
				rects["poción %d" % (i + 1)] = hud.call("_flask_rect", i)
			rects["☰"] = Rect2((hud.get("_menu_toggle") as Control).position, (hud.get("_menu_toggle") as Control).size)
			rects["orbe de vida"] = Rect2(hud.call("_life_center") - Vector2.ONE * Hud.ORB_RADIUS, Vector2.ONE * Hud.ORB_RADIUS * 2.0)
			rects["orbe de maná"] = Rect2(hud.call("_mana_center") - Vector2.ONE * Hud.ORB_RADIUS, Vector2.ONE * Hud.ORB_RADIUS * 2.0)
			var problems: Array[String] = []
			var keys := rects.keys()
			var view := Rect2(Vector2.ZERO, hud.size)
			var tracker := Rect2(hud.get_global_transform_with_canvas().affine_inverse() * ui.quest_tracker.get_global_rect().position,
				ui.quest_tracker.get_global_rect().size / hud.get_global_transform_with_canvas().get_scale())
			for a in keys.size():
				var ra: Rect2 = rects[keys[a]]
				if not view.encloses(ra):
					problems.append("%s se sale" % keys[a])
				if ra.intersects(tracker) and not String(keys[a]).begins_with("orbe"):
					problems.append("%s pisa las misiones" % keys[a])
				for b in range(a + 1, keys.size()):
					if ra.intersects(rects[keys[b]]):
						problems.append("%s pisa %s" % [keys[a], keys[b]])
			var tag := "%dx%d_%s_%d%s" % [res.x, res.y, cfg[0], roundi(cfg[1] * 100.0), "_zurda" if cfg[2] else ""]
			print("botones %s: %s" % [tag, "sin choques" if problems.is_empty() else ", ".join(problems)])
			_save("136_" + tag)
	get_window().size = Vector2i(1600, 900)
	Touch.layout = saved[0]
	Touch.button_scale = saved[1]
	Touch.left_handed = saved[2]
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Revisión de las ventanas con el dedo (T135): en cada menú y ventana que no maneja
## TouchPointer (título, menú, creación, pausa y sus ventanas, catálogo, filtro, mapa,
## muerte), un toque simulado sobre cada botón visible tiene que llegarle (button_down).
## Antes de levantar el dedo el botón se desactiva, así no hace nada. Devuelve cuántos fallaron.
func _audit_windows_touch() -> int:
	var gd: Node = get_node("/root/GameData")
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	Touch.force = true
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.4)
	var missed := 0
	# Pantallas de menú (con su escala de interfaz).
	for path in ["res://scenes/menu/title_screen.tscn", "res://scenes/menu/main_menu.tscn", "res://scenes/menu/character_creation.tscn"]:
		var menu: Node = load(path).instantiate()
		_swap(menu)
		await _wait(1.2)
		missed += await _tap_audit(menu, path.get_file().get_basename())
		if OS.get_cmdline_user_args().has("titulo"):
			return missed
	# En partida.
	var c: CharacterData = gd.create_character("Dedos", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.apply_ui_scale()
	await _wait(0.3)
	missed += await _tap_audit(ui.touch_buttons, "botones Mapa y II")
	# La bolsa llena: arrastrar en vertical sobre las casillas la desplaza (y no mueve el objeto).
	var gen := ItemGenerator.new(gd.get("items"))
	for k in 60:
		c.inventory.add_item(gen.generate(10, Rarity.Item.MAGIC))
	ui.call("_on_menu_requested", "inventory")
	await _wait(0.5)
	var bag_scroll: ScrollContainer = ui.inventory_panel.get("_scroll")
	var first: ItemCell = null
	for cc in ui.inventory_panel.find_children("*", "ItemCell", true, false):
		if (cc as ItemCell).item != null and (cc as ItemCell).location.get("kind", "") == "bag" and bag_scroll.get_global_rect().encloses((cc as ItemCell).get_global_rect()):
			first = cc
			break
	if first:
		var item := first.item
		var start := _canvas_point(first, first.size / 2.0)
		var before_scroll := bag_scroll.scroll_vertical
		_touch(0, start, true)
		for k in 10:
			await get_tree().process_frame
			_drag(0, start + Vector2(2, -14.0 * (k + 1)))
		_touch(0, start + Vector2(2, -140), false)
		await _wait(0.3)
		var moved_ok := bag_scroll.scroll_vertical > before_scroll and c.inventory.bag.has(item) and first.item == item
		print("ventanas táctil · bolsa: arrastrar hacia arriba desplaza %d → %d, el objeto sigue en su casilla: %s" % [before_scroll, bag_scroll.scroll_vertical, first.item == item])
		if not moved_ok:
			missed += 1
		_save("135_bolsa_desplazada")
	ui.call("_on_menu_requested", "inventory")
	await _wait(0.2)
	ui.toggle_pause_menu()
	await _wait(0.4)
	missed += await _tap_audit(ui.get("_pause_panel"), "pausa")
	for opener in ["open_controls", "open_achievements", "open_ladder", "open_tech_debt", "open_lore_log"]:
		var ui_root: Control = ui.get("_root")
		var before := ui_root.get_child_count()
		ui.call(opener)
		await _wait(0.5)
		var popup: Node = ui_root.get_child(before) if ui_root.get_child_count() > before else null
		if popup:
			missed += await _tap_audit(popup, opener)
			popup.queue_free()
			await _wait(0.2)
	ui.toggle_pause_menu()
	await _wait(0.2)
	ui.toggle_loot_filter()
	await _wait(0.5)
	missed += await _tap_audit(ui.loot_filter_panel, "filtro de botín")
	ui.toggle_loot_filter()
	ui.toggle_catalog()
	await _wait(0.5)
	missed += await _tap_audit(ui.catalog, "catálogo")
	ui.toggle_catalog()
	ui.world_map.toggle()
	await _wait(0.4)
	missed += await _tap_audit(ui.world_map, "mapa grande")
	ui.world_map.toggle()
	await _wait(0.2)
	ui.show_death()
	await _wait(0.5)
	missed += await _tap_audit(ui.get("_death_panel"), "muerte")
	(ui.get("_death_panel") as Control).visible = false
	get_window().size = Vector2i(1600, 900)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()
	return missed


## Toca cada botón visible de `root` y mira si se entera. Imprime los que no.
func _tap_audit(root: Node, tag: String) -> int:
	_save("135_" + tag.replace(" ", "_"))
	var screen := get_viewport().get_visible_rect()
	var ok := 0
	var bad: Array[String] = []
	var skipped := 0
	for b: BaseButton in root.find_children("*", "BaseButton", true, false):
		if not b.is_visible_in_tree() or b.disabled:
			continue
		var center := _canvas_point(b, b.size / 2.0)
		if not screen.has_point(center) or _clipped(b, center):
			skipped += 1
			continue
		var heard := [false]
		var hear := func() -> void: heard[0] = true
		b.button_down.connect(hear)
		_touch(0, center, true)
		await get_tree().process_frame
		await get_tree().process_frame
		b.disabled = true   # que al soltar no haga nada
		_touch(0, center, false)
		await get_tree().process_frame
		if not is_instance_valid(b):
			ok += 1 if heard[0] else 0   # la ventana se rehízo al tocarlo
			continue
		b.disabled = false
		if b is OptionButton:
			(b as OptionButton).get_popup().hide()   # se abre al apoyar el dedo
		elif b is MenuButton:
			(b as MenuButton).get_popup().hide()
		b.button_down.disconnect(hear)
		if heard[0]:
			ok += 1
		else:
			var under := get_viewport().gui_get_hovered_control()
			bad.append("«%s» (%s) en %s, encima: %s" % [b.text if "text" in b else b.name, b.get_class(), center.round(), under.get_path() if under else "nada"])
	print("ventanas táctil · %s: %d responden, %d fuera de la vista%s" % [tag, ok, skipped, "" if bad.is_empty() else ", NO responden:"])
	for line in bad:
		print("    " + line)
	return bad.size()


## ¿Queda `p` fuera de algún ScrollContainer que contiene a `c`?
func _clipped(c: Control, p: Vector2) -> bool:
	var n := c.get_parent()
	while n:
		if n is ScrollContainer:
			var sc := n as ScrollContainer
			if not Rect2(_canvas_point(sc, Vector2.ZERO), _canvas_point(sc, sc.size) - _canvas_point(sc, Vector2.ZERO)).has_point(p):
				return true
		n = n.get_parent()
	return false


## `local` de `c` en coordenadas del lienzo de la ventana del juego (lo que espera
## _touch), también dentro de una ventana emergente incrustada.
func _canvas_point(c: Control, local: Vector2) -> Vector2:
	var p := c.get_global_transform_with_canvas() * local
	var vp := c.get_viewport()
	if vp is Window and vp != get_tree().root:
		p = Vector2((vp as Window).position) + p * (vp as Window).content_scale_factor
	return p

## Botón de usar (T134) a resolución de teléfono con la interfaz al 140 %: con botín
## cerca, tocar recoge el más raro y mantener el resto; junto a un NPC, «Hablar»;
## tocar la etiqueta de un objeto lejano va hasta él (antes iba al toque anterior).
func _capture_touch_use() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Pulgar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	var rules_were: Dictionary = LootFilter.rules().duplicate(true)
	LootFilter.apply_preset("todo")
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	get_window().size = Vector2i(2400, 1080)
	await _wait(0.5)
	ui.apply_ui_scale()
	world.call("travel_to", "zona1", "waypoint")
	await _wait(1.5)
	var player: Player = world.get("player")
	player.set("invulnerable", true)
	var enemies: EnemyManager = world.get("enemies")
	enemies.clear_all()
	var loot: LootManager = world.get("loot")
	var gen := ItemGenerator.new(gd.get("items"))
	var p := player.global_position
	var picks: Array[Item] = []
	for r in [Rarity.Item.NORMAL, Rarity.Item.RARE, Rarity.Item.MAGIC, Rarity.Item.NORMAL]:
		var it := gen.generate(5, r)
		picks.append(it)
		loot.drop_item(it, p + Vector2(70 + picks.size() * 20, -30 + picks.size() * 18))
	await _wait(1.0)
	var hud: Hud = ui.hud
	var to_screen := func(q: Vector2) -> Vector2: return hud.get_global_transform_with_canvas() * q
	print("usar: botón %s «%s» (%s)" % ["visible" if not hud.use_now.is_empty() else "OCULTO", hud.use_now.get("text", ""),
		(hud.use_now.get("item") as Item).display_name() if hud.use_now.has("item") else "-"])
	_save("134_usar_boton")
	var use_at: Vector2 = to_screen.call(hud.use_rect().get_center())
	_touch(1, use_at, true)
	await get_tree().process_frame
	_touch(1, use_at, false)
	await _wait(1.2)
	print("usar: un toque → raro en la bolsa: %s, en el suelo quedan %d" % [c.inventory.bag.has(picks[1]), loot.drops.size()])
	_touch(1, use_at, true)
	await _wait(0.7)
	_touch(1, use_at, false)
	await _wait(2.5)
	print("usar: mantener → en el suelo quedan %d" % loot.drops.size())
	# Tocar la etiqueta de un objeto lejano (y antes, otro punto): va al objeto, no al toque anterior.
	var far := gen.generate(5, Rarity.Item.MAGIC)
	loot.drop_item(far, player.global_position + Vector2(330, -90))   # (a la izquierda empieza el joystick)
	await _wait(1.0)
	var elsewhere := player.get_canvas_transform() * (player.global_position + Vector2(120, 140))
	_touch(0, elsewhere, true)
	await get_tree().process_frame
	_touch(0, elsewhere, false)
	await _wait(0.2)
	player.stop_auto_move()
	var label_at := player.get_canvas_transform() * (loot.drops[-1]["rect"] as Rect2).get_center()
	_touch(0, label_at, true)
	await get_tree().process_frame
	_touch(0, label_at, false)
	await _wait(2.5)
	print("usar: tocar la etiqueta lejana → en la bolsa: %s" % c.inventory.bag.has(far))
	# En el campamento, junto a un NPC: «Hablar» y tocar abre la conversación.
	world.call("travel_to", "campamento", "waypoint")
	await _wait(1.5)
	var zone: Zone = world.get("zone")
	player.global_position = zone.npc_position(zone.npcs[0]) + Vector2(0, 90)
	await _wait(0.4)
	print("usar: junto a %s → botón «%s»" % [zone.npcs[0]["name"], hud.use_now.get("text", "")])
	_save("134_usar_npc")
	use_at = to_screen.call(hud.use_rect().get_center())
	_touch(1, use_at, true)
	await get_tree().process_frame
	_touch(1, use_at, false)
	await _wait(1.5)
	print("usar: tocar → conversación abierta: %s" % ui.dialogue_box.visible)
	get_window().size = Vector2i(1600, 900)
	LootFilter.rules().merge(rules_were, true)
	LootFilter.set_rule("weapon", String(rules_were["weapon"]))
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Filtro de botín con el dedo (T133), a resolución de teléfono con la interfaz al
## 140 % y el inventario abierto debajo: tocar gemas cambia la regla, la ventana
## cabe en la pantalla y no es más grande que las demás.
func _capture_loot_filter_touch() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Filtro", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["llegada_campamento_vista"] = true
	var gen := ItemGenerator.new(gd.get("items"))
	for k in 30:
		c.inventory.add_item(gen.generate(14, Rarity.Item.RARE))   # casillas llenas debajo del filtro
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	var scale_was: Variant = GameSettings.get_value("interface", "scale", 1.0)
	GameSettings.set_value("interface", "scale", 1.4)
	var saved_rules: Dictionary = LootFilter.rules().duplicate(true)
	Touch.force = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	for res in [Vector2i(2400, 1080), Vector2i(1600, 720)]:
		get_window().size = res
		await _wait(0.6)
		ui.apply_ui_scale()
		var tag := "%dx%d" % [res.x, res.y]
		ui.call("_on_menu_requested", "inventory")
		await _wait(0.3)
		var inv_rect := ui.inventory_panel.get_global_rect()
		LootFilter.apply_preset("todo")
		ui.toggle_loot_filter()
		await _wait(0.5)
		var panel: PanelContainer = ui.loot_filter_panel.get("_panel")
		var screen := get_viewport().get_visible_rect()
		var rect := panel.get_global_rect()
		print("filtro %s: ventana %s (pantalla %s, cabe: %s; inventario %s)" % [tag, rect, screen.size, screen.encloses(rect), inv_rect])
		# Tocar la gema «Raro» de las armas y luego «Mostrar»/«Ocultar» de las pociones.
		var rows: Array = ui.loot_filter_panel.get("_rows")
		var gem_at := func(row: Control, k: int) -> Vector2:
			return row.get_global_transform_with_canvas() * Vector2(190.0 + k * (LootFilterPanel.GEM.x + 4.0) + LootFilterPanel.GEM.x / 2.0, 3.0 + LootFilterPanel.GEM.y / 2.0)
		for step in [["weapon", 0, LootFilter.STEPS.find("rare")], ["weapon", 0, 0], ["flask", LootFilter.GEAR.size() + 2, 1]]:
			var at: Vector2 = gem_at.call(rows[step[1]], step[2])
			_touch(0, at, true)
			await get_tree().process_frame
			_touch(0, at, false)
			await _wait(0.3)
			print("filtro %s: tocar %s gema %d → regla %s" % [tag, step[0], step[2], LootFilter.rules().get(step[0])])
			if step[2] == LootFilter.STEPS.find("rare"):
				_save("133_%s_filtro" % tag)
		var gem_h: float = (rows[0] as Control).get_global_transform_with_canvas().get_scale().y * LootFilterPanel.GEM.y
		print("filtro %s: gemas de %.0f px de alto en pantalla del lienzo" % [tag, gem_h])
		ui.toggle_loot_filter()
		ui.call("_on_menu_requested", "inventory")
		await _wait(0.2)
	get_window().size = Vector2i(1600, 900)
	LootFilter.rules().merge(saved_rules, true)
	LootFilter.set_rule("weapon", String(saved_rules["weapon"]))   # (guarda todo)
	GameSettings.set_value("interface", "scale", scale_was)
	Touch.force = false
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Prólogo con el dedo (T132): joystick en la calle y el pasillo, tocar la entrada
## para ir, el botón de usar junto a Rafa y tocar para pasar la conversación.
func _capture_prologue_touch() -> void:
	var gd: Node = get_node("/root/GameData")
	gd.set("pending_creation", {"name": "Prueba", "appearance": CharacterAppearance.default()})
	Touch.force = true
	var p: Node = load("res://scenes/prologue/prologue.tscn").instantiate()
	_swap(p)
	await _wait(0.5)
	# Tocar pasa la introducción (dos toques: completa el texto y sigue).
	for k in 2:
		_touch(0, Vector2(1200, 300), true)
		await get_tree().process_frame
		_touch(0, Vector2(1200, 300), false)
		await _wait(0.8)
	print("prólogo táctil: tras tocar dos veces, fase %s" % p.get("_phase"))
	p.set("_fade", 0.0)
	var stage: PrologueStage = p.get("_stage")
	var x0 := stage.player_x
	var origin := Vector2(300, 450)
	_touch(0, origin, true)
	for k in 6:
		await get_tree().process_frame
		_drag(0, origin + Vector2(16.0 * (k + 1), 0))
	await _wait(1.0)
	print("prólogo táctil: joystick %s, de x %.0f a %.0f" % [Touch.stick, x0, stage.player_x])
	_save("132_prologo_joystick")
	_touch(0, origin + Vector2(96, 0), false)
	await _wait(0.2)
	# Tocar la entrada de la UAdeO (a la derecha del escenario): camina y entra.
	# (primero hacia el borde derecho, porque desde el principio la entrada aún no se ve)
	var rect: Rect2 = p.call("_screen_rect")
	var to_screen := func(stage_p: Vector2) -> Vector2:
		return (p as Control).get_global_transform_with_canvas() * (rect.position + stage_p / Vector2(400, 225) * rect.size)
	var tap: Vector2 = to_screen.call(Vector2(385, PrologueStage.FLOOR_Y - 20.0))
	_touch(0, tap, true)
	await get_tree().process_frame
	_touch(0, tap, false)
	await _wait(3.5)
	print("prólogo táctil: tocar a la derecha → x %.0f" % stage.player_x)
	tap = to_screen.call(Vector2(PrologueStage.ENTRANCE_X - stage.cam_x, PrologueStage.FLOOR_Y - 20.0))
	_touch(0, tap, true)
	await get_tree().process_frame
	_touch(0, tap, false)
	var waited := 0.0
	while stage.room != "pasillo" and waited < 14.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	print("prólogo táctil: tocar la entrada → %s en %.1f s" % [stage.room, waited])
	await _wait(1.0)
	# Pasillo: joystick hacia arriba = al fondo.
	var depth0 := stage.player_depth
	_touch(0, origin, true)
	for k in 6:
		await get_tree().process_frame
		_drag(0, origin + Vector2(0, -16.0 * (k + 1)))
	await _wait(0.8)
	_touch(0, origin + Vector2(0, -96), false)
	print("prólogo táctil: pasillo, profundidad %.2f → %.2f" % [depth0, stage.player_depth])
	_save("132_prologo_pasillo")
	# Oficina, junto a Rafa: el botón de usar.
	p.call("_go_room", "oficina", float(PrologueStage.HOTSPOTS["oficina"][0]["x"]))
	await _wait(0.3)
	var use: Button = p.get("_touch_use")
	print("prólogo táctil: junto a Rafa, botón %s «%s» de %s" % ["visible" if use.visible else "OCULTO", use.text, use.size])
	_save("132_prologo_usar")
	var at := use.get_global_rect().get_center()
	_touch(0, at, true)
	await get_tree().process_frame
	_touch(0, at, false)
	await _wait(0.6)
	var cut: CutscenePlayer = p.get("_cutscene")
	print("prólogo táctil: tocar el botón → conversación %s" % ("sí" if cut.is_playing() else "NO"))
	_save("132_prologo_rafa")
	var line0: int = cut.get("_index") if cut.get("_index") != null else -1
	for k in 3:
		_touch(0, Vector2(800, 300), true)
		await get_tree().process_frame
		_touch(0, Vector2(800, 300), false)
		await _wait(0.5)
	print("prólogo táctil: tres toques en la conversación, línea %s → %s" % [line0, cut.get("_index")])
	Touch.force = false
	p.queue_free()


func _touch(index: int, p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = get_viewport().get_final_transform() * p
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag(index: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = get_viewport().get_final_transform() * p
	Input.parse_input_event(e)


## Escenas que faltaban (T130): la llegada al campamento del Acto I y al Socket Seguro.
func _capture_arrivals() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Llegadas", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	for zid in ["campamento", "socket_seguro"]:
		world.call("travel_to", zid, "waypoint")
		await _wait(2.2)
		_save("130_llegada_%s" % zid)
		if ui.cutscene.visible:
			ui.cutscene.call("_finish")
		await _wait(0.3)
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Escenas con dirección (T129): la reunión del campamento con la cámara sobre Ada (zoom
## y bandas de cine) y luego sobre Rafa.
func _capture_cutscene_direction() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Escenas", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.6)
	world.call("play_cutscene", "reunion_campamento")
	await _wait(1.6)
	_save("129_escena_ada")
	var ui: GameUI = world.get("ui")
	for k in 3:   # hasta Rafa
		ui.cutscene.call("_advance")
		await _wait(0.35)
		ui.cutscene.call("_advance")
		await _wait(0.4)
	await _wait(1.0)
	_save("129_escena_rafa")
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## HUD de la zona y registro de sucesos (T128): el rótulo con la mecánica al entrar y el
## registro con unos cuantos sucesos.
func _capture_event_log() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Registro", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var ui: GameUI = world.get("ui")
	ui.log_event("Waypoint descubierto: Las Ruinas del Monolito", Color("5cd0ff"))
	ui.log_event("Ha caído: Bucle Infinito, anillo de Commit", Rarity.item_color(Rarity.Item.RARE))
	ui.log_event("Mecánica completada en El Bosque de Cables: Caché caliente", Color("ffd24a"))
	ui.log_event("Ha caído: El Último Merge", Rarity.item_color(Rarity.Item.UNIQUE))
	ui.log_event("El Bosque de Cables caduca en 1:00 (con botín en el suelo)", Color("ff9a4a"))
	world.call("travel_to", "zona2", "")
	(world.get("enemies") as EnemyManager).clear_all()
	await _wait(1.2)
	_save("128_rotulo_y_registro")
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Comparar placas y RAM (T127): el tooltip de una placa mejor de la que llevas (con la tuya
## al lado) y el de una RAM con lo que haría en tus placas.
func _capture_board_compare() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Comparar", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.6)
	var ui: GameUI = world.get("ui")
	var skills: Dictionary = gd.get("items").skills.skills
	var mine := Motherboard.new(skills["barrido"], 3, ["DDR3", "DDR3"])
	c.inventory.boards[0] = mine
	var better := Motherboard.new(skills["barrido"], 9, ["DDR3", "DDR3", "DDR4"])
	ui.item_tooltip.show_item(better, c, true)
	ui.item_tooltip.position = Vector2(420, 80)
	await _wait(0.6)
	_save("127_comparar_placa")
	var rams: Dictionary = gd.get("items").skills.rams
	for id in rams:
		var r := RamModule.new(rams[id])
		if r.supports(mine.skill_def) and r.generation() == "DDR3":
			ui.item_tooltip.show_item(r, c, true)
			ui.item_tooltip.position = Vector2(560, 120)
			break
	await _wait(0.6)
	_save("127_comparar_ram")
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Ventana de waypoints como mapa del acto (T126), con un personaje del Acto II: actos I y
## II descubiertos, zonas visitadas y una instancia viva.
func _capture_waypoint_map() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Waypoints", &"guerrero", CharacterAppearance.default(), false)
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.flags["act1_complete"] = true
	c.flags["zone"] = "socket_seguro"
	c.flags["waypoints"] = ["campamento", "zona2", "zona4", "zona5", "socket_seguro", "fabrica"]
	c.flags["visited"] = ["tutorial", "campamento", "zona1", "zona2", "zona3", "zona4", "zona5", "jefe", "socket_seguro", "brecha_503", "fabrica"]
	c.level = 15   # sin la elección de habilidad del nivel 16 delante
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(3.6)   # que pase el rótulo de la zona
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.open_waypoints("socket_seguro", {"fabrica": 452.0, "zona4": 121.0}, {"fabrica": "Merge conflict", "zona4": "Apagón del CPD"})
	await _wait(0.6)
	_save("126_waypoints_acto2")
	var panel: WaypointPanel = ui.get("_waypoint_panel")
	panel._show_act(0)
	await _wait(0.4)
	_save("126_waypoints_acto1")
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Profundidad (T124): el jugador detrás de algo alto (translúcido), manchas en el suelo
## y el fondo con parallax más allá del borde (agua, abismo, vacío).
func _capture_depth() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Profundidad", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Node2D = world.get("player")
	player.set("invulnerable", true)
	for zid in ["zona4", "zona3", "zona2", "bus"]:
		world.call("travel_to", zid, "")
		world.set("_since_save", -9999.0)
		var zone: Zone = world.get("zone")
		(world.get("enemies") as EnemyManager).clear_all()
		await _wait(0.3)
		var ui: GameUI = world.get("ui")
		if ui.cutscene.visible:
			ui.cutscene.call("_finish")
		var tall: Dictionary = {}
		for o in zone.obstacles:
			if Zone.TALL_OBSTACLES.has(o["kind"]):
				tall = o
				break
		if not tall.is_empty():   # justo detrás de lo alto
			player.global_position = (tall["pos"] as Vector2) + Vector2(0, -float(tall["radius"]) * 1.1)
		else:   # junto al borde, para ver el fondo
			player.global_position = zone.free_spot_near(zone.rect.position + Vector2(260, zone.rect.size.y * 0.5))
		for k in 14:
			zone.add_stain(player.global_position + Vector2.from_angle(k * 0.9) * (90.0 + k * 22.0), ["metal", "flesh", "digital", "crystal"][k % 4])
		await _wait(2.4)
		_save("124_profundidad_%s" % zid)
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Salas temáticas (T123): una foto de cada sala que salga en unas cuantas zonas.
func _capture_set_pieces() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Salas", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12   # sin elecciones de habilidad pendientes que tapen la foto
	var tips_were := TipPanel.enabled()
	TipPanel.set_enabled(false)
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Node2D = world.get("player")
	player.set("invulnerable", true)
	var seen := {}
	for zid in ["zona5", "zona4", "fosa", "oblea", "zona3", "zona2", "post", "alcantarillas", "zona5", "post", "zona5", "post"]:
		(world.get("instances") as ZoneInstances).forget(zid)   # repetir zona = otra instancia (por si falta el rack caído)
		world.call("travel_to", zid, "")
		world.set("_since_save", -9999.0)
		var zone: Zone = world.get("zone")
		(world.get("enemies") as EnemyManager).clear_all()   # que se vea la sala, no la pelea
		await _wait(0.3)
		var ui: GameUI = world.get("ui")
		if ui.cutscene.visible:
			ui.cutscene.call("_finish")   # la escena al entrar (el POST) taparía la foto
		for sp in zone.layout.set_pieces:
			if seen.has(sp["kind"]):
				continue
			seen[sp["kind"]] = true
			player.global_position = zone.free_spot_near((sp["pos"] as Vector2) + Vector2(0, 170))
			await _wait(2.6)
			_save("123_sala_%s" % sp["kind"])
		if seen.size() == ZoneLayout.SET_PIECES.size():
			break
	TipPanel.set_enabled(tips_were)
	world.queue_free()


## Mecánicas de zona (T121): el barrido del Garbage Collector (aviso y pasada), el
## apagón con una luz encendida y el ticket urgente con sus marcados.
func _capture_mechanics() -> void:
	var gd: Node = get_node("/root/GameData")
	var c: CharacterData = gd.create_character("Mecánicas", &"guerrero", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_swap(world)
	world.set("_since_save", -9999.0)
	await _wait(1.0)
	var player: Node2D = world.get("player")
	player.set("invulnerable", true)   # que no muera mientras se espera a la foto
	for kind in ["gc_warn", "gc", "blackout", "ticket", "merge", "friday", "hot_cache"]:
		world.call("travel_to", "zona3", "")
		world.set("_since_save", -9999.0)
		var zone: Zone = world.get("zone")
		var ev := zone.events
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var base: String = String(kind).trim_suffix("_warn")
		var e: Dictionary
		if base == "ticket":
			e = {"kind": "ticket", "pos": zone.free_spot_near(zone.rect.get_center()), "state": "ready", "main": true}
		else:
			e = ev._zone_wide(base, rng, zone.key_points())
		ev.events = [e]
		player.global_position = zone.free_spot_near(zone.rect.get_center() + Vector2(0, 160))
		await _wait(3.2)
		if base == "gc":
			e["phase"] = "warn" if kind == "gc_warn" else "sweep"
			e["timer"] = 1.5 if kind == "gc_warn" else 0.0
			e["line"] = ZoneEvents.gc_coord(e, player.global_position) - (0.0 if kind == "gc_warn" else 220.0)
			e["hit"] = {"player": true}
		elif base == "blackout":
			world.call("_apply_blackout", 0.0)
			e["lights"][0]["pos"] = player.global_position + Vector2(260, -40)
			e["lights"][1]["pos"] = player.global_position + Vector2(-300, 60)
			e["lights"][0]["lit"] = true
		elif base == "ticket":
			ev._fire(0)
		elif base == "friday":
			e["pos"] = player.global_position + Vector2(220, -40)
			e["progress"] = ZoneEvents.FRIDAY_HOLD * 0.4
		elif base == "hot_cache":
			for k in 3:
				e["tiles"][k]["pos"] = player.global_position + Vector2(-320 + k * 320, -170)
		await _wait(0.7)
		_save("%s_mecanica_%s" % ["121" if kind in ["gc_warn", "gc", "blackout", "ticket"] else "122", kind])
	world.queue_free()


## Generador de zonas (T114): cinco semillas de cada zona que se genera, en fila, con
## los colores de su estilo (verde entradas, amarillo salidas, azul waypoint, magenta
## NPC y objetos). Una imagen por zona y una hoja con todas; resumen por consola.
func _capture_zone_seeds() -> void:
	const PX := 3
	const GAP := 10
	var rows: Array[Image] = []
	var fails := 0
	var templates := {}
	var usec := 0
	var slowest := 0
	for zone_id in GameData.zones:
		var def: Dictionary = GameData.zones[zone_id]
		if not ZoneLayout.applies_to(def):
			continue
		var style: Dictionary = Zone.STYLES.get(String(def.get("style", "")), Zone.STYLES["sandbox"])
		var imgs: Array[Image] = []
		var notes := []
		for k in 5:
			var t0 := Time.get_ticks_usec()
			var l := ZoneLayout.generate(def, hash(zone_id) + k * 7919)
			var took := Time.get_ticks_usec() - t0
			usec += took
			slowest = maxi(slowest, took)
			var problem := l.check()
			if problem != "":
				fails += 1
			templates[l.template] = int(templates.get(l.template, 0)) + 1
			notes.append("%s%s%s %dx%d %.0f%%%s" % [l.template, "" if l.shape == "normal" else " " + l.shape, " rodeo" if not l.detour.is_empty() else "",
				l.width, l.height, l.floor_fraction() * 100.0, (" ¡" + problem + "!") if problem != "" else ""])
			imgs.append(l.draw_image(PX, Color(style["ground"]), Color(style["outside"])))
		var w := GAP
		var h := 0
		for img in imgs:
			w += img.get_width() + GAP
			h = maxi(h, img.get_height())
		var row := Image.create(w, h + GAP * 2, false, Image.FORMAT_RGBA8)
		row.fill(Color("0b0b10"))
		var x := GAP
		for img in imgs:
			row.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, GAP))
			x += img.get_width() + GAP
		row.save_png(ProjectSettings.globalize_path(OUT + "114_semillas_%s.png" % zone_id))
		rows.append(row)
		print("%-18s %s" % [zone_id, " | ".join(notes)])
	var sheet_w := 0
	var sheet_h := 0
	for r in rows:
		sheet_w = maxi(sheet_w, r.get_width())
		sheet_h += r.get_height()
	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("0b0b10"))
	var y := 0
	for r in rows:
		sheet.blit_rect(r, Rect2i(Vector2i.ZERO, r.get_size()), Vector2i(0, y))
		y += r.get_height()
	sheet.save_png(ProjectSettings.globalize_path(OUT + "114_semillas_todas.png"))
	print("Zonas: %d · disposiciones: %d · fallos de garantía: %d · plantillas: %s · %.0f ms de media, %.0f ms la más lenta" % [rows.size(), rows.size() * 5, fails, templates,
		usec / 1000.0 / maxf(1.0, rows.size() * 5.0), slowest / 1000.0])


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captura: ", name)
