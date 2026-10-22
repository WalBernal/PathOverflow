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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run.call_deferred()


func _run() -> void:
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


func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captura: ", name)
