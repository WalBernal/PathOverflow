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
	_run.call_deferred()


func _run() -> void:
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
