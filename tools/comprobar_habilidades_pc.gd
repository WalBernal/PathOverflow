extends Node
## Habilidades en PC (T230): lo que antes pedía arrastrar, doble clic o clic derecho
## se hace con botones o atajos, y al pasar el ratón por una RAM se ve dónde iría.
## Uso: Godot --path . res://tools/comprobar_habilidades_pc.tscn
## Imprime una línea por acción («OK» o «FALLO») y guarda dos capturas.

const BUILD := [
	["rafaga_de_paquetes", ["multicanal_mayor", "puntero_salvaje", "propagacion_excepciones", "ecc", "pipeline"]],
	["drones_vigilancia", ["multicanal", "pipeline", "firmware_autonomo", "ecc", "sobretension"]],
	["robot_centinela", ["multicanal_mayor", "puntero_salvaje", "redundancia_invocacion", "sensor_precision", "guiado_laser"]],
]

const EXPECTED_CHECKS := 11

var _fails := 0
var _checks := 0


func _ready() -> void:
	LoadingCard.enabled = false
	await get_tree().process_frame   # la raíz ya montada: se le puede añadir el mundo
	await _run()
	var complete := _checks == EXPECTED_CHECKS
	print("comprobar_habilidades_pc: %s (%d/%d)" % ["todo OK" if _fails == 0 and complete else "%d FALLO(S)" % maxi(_fails, 1), _checks, EXPECTED_CHECKS])
	get_tree().quit(1 if _fails > 0 or not complete else 0)


func _check(ok: bool, text: String) -> void:
	print("%s · %s" % ["OK   " if ok else "FALLO", text])
	_checks += 1
	if not ok:
		_fails += 1


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _run() -> void:
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("PC", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "campamento"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	c.level = 12
	for i in BUILD.size():
		var ids: Array = BUILD[i][1]
		var slots: Array = []
		for rid in ids:
			slots.append(items.skills.rams[rid]["generation"])
		var board := Motherboard.new(items.skills.skills[BUILD[i][0]], 10, slots)
		for k in ids.size() - 1:   # la última ranura, libre
			board.install(RamModule.new(items.skills.rams[ids[k]]), k)
		c.inventory.set_board(i, board)
	c.inventory.add_item(RamModule.new(items.skills.rams[BUILD[0][1][4]]))
	gd.current_character = c
	var world: Node = load(GameData.WORLD_SCENE).instantiate()
	get_tree().root.add_child(world)
	world.set("_since_save", -9999.0)
	await _wait(1.2)
	var ui: GameUI = world.get("ui")
	if ui.cutscene.visible:
		ui.cutscene.call("_finish")
	ui.call("_on_menu_requested", "skills")
	await _wait(0.4)
	var panel: SkillsPanel = ui.skills_panel
	_check(panel.visible, "el menú K se abre")
	# Ratón sobre una RAM: ranura válida en verde y el cambio de DPS en la línea de cifras.
	var ram_index := -1
	for i in Inventory.BAG_SIZE:
		if c.inventory.bag[i] is RamModule:
			ram_index = i
	panel.call("_preview", c.inventory.bag[ram_index])
	var cells: Array = panel.get("_slot_cells")
	var lit := cells.filter(func(cell: ItemCell) -> bool: return cell.selected).size()
	var stats := (panel.get("_stats") as Label).text
	_check(lit == 1 and stats.contains("Con "), "ratón sobre una RAM: %d ranura en verde y «%s»" % [lit, stats.get_slice("\n", stats.get_slice_count("\n") - 1)])
	await _wait(0.2)
	_save("230_vista_previa")
	panel.call("_preview", null)
	_check((panel.get("_stats") as Label).text.find("Con ") == -1, "al quitar el ratón, la línea de cifras vuelve a la normal")
	# Atajos.
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_2
	panel.call("_unhandled_input", key)
	_check(int(panel.get("_sel_board")) == 1, "tecla 2: elige la segunda placa")
	panel.call("_on_board_tapped", 0)
	# «Quitar RAM» con su botón (antes: clic en la ranura o arrastrar a la bolsa).
	panel.set("_sel_slot", 0)
	panel.call("_rebuild")
	var quitar: Button = _buttons_in(panel).get("Quitar RAM")
	_check(quitar != null and not quitar.disabled, "con una ranura elegida, «Quitar RAM» está activo")
	if quitar:
		quitar.pressed.emit()
	_check(c.inventory.boards[0].rams[0] == null, "botón «Quitar RAM»: la RAM vuelve a la bolsa")
	# Supr quita la de la ranura elegida.
	panel.set("_sel_slot", 1)
	panel.call("_rebuild")
	key.keycode = KEY_DELETE
	panel.call("_unhandled_input", key)
	_check(c.inventory.boards[0].rams[1] == null, "Supr: quita la RAM de la ranura elegida")
	# Mover de tecla con botón (antes: arrastrar una placa sobre otra).
	var first: Motherboard = c.inventory.boards[0]
	var right: Button = _buttons_in(panel).get("Tecla ▶")
	if right:
		right.pressed.emit()
	_check(c.inventory.boards.find(first) == 1, "botón «Tecla ▶»: la placa pasa a la tecla 2")
	# Instalar con botón (antes: doble clic o arrastrar a la ranura).
	panel.call("_on_board_tapped", 1)
	panel.set("_tab", "fits")
	panel.call("_rebuild")
	var install: Button = _buttons_in(panel).get("Instalar")
	if install == null:
		install = _buttons_in(panel).get("Cambiar")
	var bag_rams_before := c.inventory.bag.filter(func(it: Variant) -> bool: return it is RamModule).size()
	if install:
		install.pressed.emit()
	var bag_rams_after := c.inventory.bag.filter(func(it: Variant) -> bool: return it is RamModule).size()
	_check(install != null and bag_rams_after < bag_rams_before, "botón «Instalar»: una RAM de la bolsa entra en la placa")
	# Quitar la placa con botón (antes: clic derecho).
	var quit_board: Button = _buttons_in(panel).get("Quitar placa")
	if quit_board:
		quit_board.pressed.emit()
	_check(c.inventory.boards[1] == null, "botón «Quitar placa»: la placa vuelve a la bolsa")
	key.keycode = KEY_TAB
	panel.call("_unhandled_input", key)
	_check(String(panel.get("_tab")) == "all", "Tab: pasa a la pestaña siguiente")
	await _wait(0.3)
	_save("230_atajos")


## Los botones de una ventana, por su texto.
func _buttons_in(root: Node) -> Dictionary:
	var out := {}
	for n in root.find_children("*", "Button", true, false):
		out[(n as Button).text] = n
	return out


func _save(name: String) -> void:
	var dir := "user://capturas/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir + name + ".png"))
	print("captura: ", name)
