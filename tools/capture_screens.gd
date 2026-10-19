extends Node
## Captura las pantallas principales en user://capturas/ (para revisar la
## interfaz sin jugar). No guarda personajes ni toca el alijo.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . res://tools/capture_screens.tscn

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
	for shot in MENU_SCENES:
		_swap(load(MENU_SCENES[shot]).instantiate())
		await _wait(1.2)
		_save(shot)
	await _capture_appearances()
	await _capture_prologue()
	await _capture_game()
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
