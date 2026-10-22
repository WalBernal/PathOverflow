class_name GameUI
extends CanvasLayer
## Capa de UI del juego: HUD, inventario (I), habilidades (K), árbol pasivo
## (P, pausa el juego), diálogos con NPCs, tutorial, tooltip de objetos,
## menú de pausa (Esc) y pantalla de muerte.
## Funciona con el juego en pausa (PROCESS_MODE_ALWAYS).

signal return_to_menu_requested
signal quit_requested
signal dialogue_action(action: Dictionary)
signal waypoint_selected(zone_id: String)
signal shop_refresh_requested

const TREE_SCREEN := preload("res://scenes/ui/passive_tree_screen.tscn")

var hud: Hud
var inventory_panel: InventoryPanel
var skills_panel: SkillsPanel
var tree_screen: PassiveTreeScreen
var dialogue_box: DialogueBox
var tutorial: TutorialPanel
var item_tooltip: ItemTooltip
var minimap: Minimap
var quest_tracker: QuestTracker
var cutscene: CutscenePlayer
var challenge_panel: ChallengePanel
var shop_panel: ShopPanel
var stash_panel: StashPanel
var _wave_label: Label
var character_sheet: CharacterSheet
var _character: CharacterData
var _player: Player
var _loot: LootManager
var _minimap_enabled := true
var _death_panel: PanelContainer
var _waypoint_panel: WaypointPanel
var _zone_banner: Label
var _act_banner: PanelContainer
var _pause_panel: Control


func setup(player: Player, enemies: EnemyManager, character: CharacterData, loot: LootManager,
		skills: SkillController, quests: QuestLog = null) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_character = character
	_player = player
	_loot = loot

	hud = Hud.new()
	hud.player = player
	hud.enemies = enemies
	hud.character = character
	hud.skills = skills
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.menu_requested.connect(_on_menu_requested)

	# El tooltip se crea antes (lo usan los paneles) pero se añade al final,
	# para que quede por encima de todo.
	item_tooltip = ItemTooltip.new()

	tutorial = TutorialPanel.new()
	add_child(tutorial)
	tutorial.position = Vector2(10, 34)
	tutorial.setup(character, player)
	tutorial.step_completed.connect(func(text: String) -> void: hud.flash(text, Color("6fb36b")))

	inventory_panel = InventoryPanel.new()
	inventory_panel.visible = false
	add_child(inventory_panel)
	inventory_panel.anchor_left = 1.0
	inventory_panel.anchor_right = 1.0
	inventory_panel.offset_left = -10.0
	inventory_panel.offset_right = -10.0
	inventory_panel.offset_top = 10.0
	inventory_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	inventory_panel.setup(character, item_tooltip)
	inventory_panel.message.connect(hud.flash)
	inventory_panel.close_requested.connect(func() -> void: _on_menu_requested("inventory"))
	inventory_panel.item_equipped.connect(func() -> void: tutorial.notify("equipped"))

	skills_panel = SkillsPanel.new()
	skills_panel.visible = false
	add_child(skills_panel)
	skills_panel.position = Vector2(10, 170)
	skills_panel.setup(character, item_tooltip)
	skills_panel.message.connect(hud.flash)
	skills_panel.close_requested.connect(func() -> void: _on_menu_requested("skills"))
	skills_panel.drop_to_ground.connect(_on_drop_to_ground)
	inventory_panel.drop_to_ground.connect(_on_drop_to_ground)

	character_sheet = CharacterSheet.new()
	character_sheet.visible = false
	add_child(character_sheet)
	character_sheet.position = Vector2(10, 34)
	character_sheet.setup(character, player, skills)
	character_sheet.close_requested.connect(func() -> void: _on_menu_requested("character"))
	character_sheet.passives_requested.connect(func() -> void: _on_menu_requested("passives"))

	# Comerciante y alijo: a la izquierda, con el inventario abierto a la derecha.
	shop_panel = ShopPanel.new()
	add_child(shop_panel)
	shop_panel.position = Vector2(10, 34)
	shop_panel.setup(character, item_tooltip)
	shop_panel.message.connect(hud.flash)
	shop_panel.close_requested.connect(close_trade_panels)
	shop_panel.refresh_requested.connect(func() -> void: shop_refresh_requested.emit())
	stash_panel = StashPanel.new()
	add_child(stash_panel)
	stash_panel.position = Vector2(10, 34)
	stash_panel.message.connect(hud.flash)
	stash_panel.close_requested.connect(close_trade_panels)
	stash_panel.drop_to_ground.connect(_on_drop_to_ground)

	minimap = Minimap.new()
	minimap.player = player
	minimap.enemies = enemies
	minimap.loot = loot
	add_child(minimap)
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -Minimap.RADIUS * 2.0 - 18.0
	minimap.offset_right = -18.0
	minimap.offset_top = 14.0
	minimap.offset_bottom = 14.0 + minimap.custom_minimum_size.y

	# Registro de misiones, debajo del minimapa.
	quest_tracker = QuestTracker.new()
	add_child(quest_tracker)
	quest_tracker.anchor_left = 1.0
	quest_tracker.anchor_right = 1.0
	quest_tracker.offset_left = -QuestTracker.WIDTH - 10.0
	quest_tracker.offset_right = -10.0
	quest_tracker.offset_top = minimap.offset_bottom + 6.0
	quest_tracker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	if quests:
		quest_tracker.setup(quests)
	else:
		quest_tracker.visible = false

	dialogue_box = DialogueBox.new()
	dialogue_box.character = character
	add_child(dialogue_box)
	dialogue_box.action_requested.connect(func(action: Dictionary) -> void: dialogue_action.emit(action))

	tree_screen = TREE_SCREEN.instantiate() as PassiveTreeScreen
	tree_screen.standalone = false
	tree_screen.visible = false
	add_child(tree_screen)
	tree_screen.show_character(character)
	tree_screen.closed.connect(toggle_passive_tree)

	_death_panel = PanelContainer.new()
	_death_panel.theme = UiStyle.make_theme()
	var label := Label.new()
	label.text = "HAS MUERTO\n\nStack trace:\n  en Player.take_damage()\n  en Enemy.attack()\n  en tu_decision_de_ir_sin_resistencias()\n\nPulsa R para reaparecer en el campamento"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("e06c6c"))
	_death_panel.add_child(label)
	_death_panel.visible = false
	add_child(_death_panel)
	_death_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	_waypoint_panel = WaypointPanel.new()
	_waypoint_panel.visible = false
	add_child(_waypoint_panel)
	_waypoint_panel.selected.connect(func(zone_id: String) -> void:
		_waypoint_panel.visible = false
		waypoint_selected.emit(zone_id))

	_zone_banner = UiStyle.label("", 34, UiStyle.ACCENT)
	_zone_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_banner.add_theme_constant_override("outline_size", 8)
	_zone_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_zone_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zone_banner)
	_zone_banner.anchor_right = 1.0
	_zone_banner.offset_top = 165.0
	_zone_banner.modulate.a = 0.0

	_act_banner = _build_act_banner()
	add_child(_act_banner)

	challenge_panel = ChallengePanel.new()
	add_child(challenge_panel)
	challenge_panel.setup(item_tooltip, character)

	_wave_label = UiStyle.label("", 20, Color("ff9a4a"))
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_constant_override("outline_size", 6)
	_wave_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_label.visible = false
	add_child(_wave_label)
	_wave_label.anchor_right = 1.0
	_wave_label.offset_top = 60.0

	cutscene = CutscenePlayer.new()
	cutscene.player = player
	cutscene.speakers = {"player": {"name": character.character_name, "appearance": character.appearance,
		"color": character.class_def.get("color", "d9a441")}}
	add_child(cutscene)

	_pause_panel = _build_pause_menu()
	add_child(_pause_panel)
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_child(item_tooltip)
	loot.hovered_item_changed.connect(_on_ground_item_hovered)
	loot.pickup_failed.connect(hud.flash)
	loot.picked_up.connect(func(_item: Item) -> void: tutorial.notify("picked_up"))
	skills.skill_used.connect(func(_i: int) -> void: tutorial.notify("skill_used"))
	skills.skill_used.connect(hud.notify_skill_used)
	skills.not_enough_mana.connect(func() -> void: hud.flash("Sin maná. Bebe un refresco (teclas 1-5) o espera, como con el compilador."))
	skills.reservation_full.connect(func(skill_name: String) -> void:
		hud.flash("No queda maná sin reservar para otra invocación de %s. Tus procesos en segundo plano ya se lo comen todo." % skill_name))
	skills.unit_lost.connect(func(skill_name: String) -> void:
		hud.flash("Ha caído tu %s. Vuelve a lanzar la habilidad para montarlo otra vez." % skill_name, Color("ff9a4a")))
	player.flask_used.connect(func(_i: int) -> void: tutorial.notify("flask_used"))


## Al entrar en una zona: minimapa, tutorial y el nombre de la zona en grande.
func on_zone_changed(zone: Zone) -> void:
	minimap.zone = zone
	tutorial.zone = zone
	dialogue_box.close()
	close_trade_panels()
	_waypoint_panel.visible = false
	_zone_banner.text = zone.zone_name if zone.safe else "%s\nNivel de zona %d" % [zone.zone_name, zone.level]
	var tween := create_tween()
	_zone_banner.modulate.a = 0.0
	tween.tween_property(_zone_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.0)
	tween.tween_property(_zone_banner, "modulate:a", 0.0, 0.8)


## Reproduce una escena; on_done se llama al terminar (o al saltarla).
func play_cutscene(data: Dictionary, on_done: Callable) -> void:
	dialogue_box.close()
	close_trade_panels()
	_waypoint_panel.visible = false
	inventory_panel.visible = false
	skills_panel.visible = false
	character_sheet.visible = false
	item_tooltip.hide()
	_update_minimap()
	cutscene.play(data, on_done)


## Texto de la prueba de estrés en curso ("" lo oculta).
func set_wave_text(text: String) -> void:
	_wave_label.text = text
	_wave_label.visible = text != ""


func open_waypoints(current_zone: String) -> void:
	_waypoint_panel.open(_character.flags.get("waypoints", []), current_zone)


func show_act_complete(act_name: String) -> void:
	_act_banner.get_node("Box/Title").text = "%s: COMPLETADO" % act_name
	_act_banner.visible = true
	_act_banner.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)
	get_tree().create_timer(9.0).timeout.connect(func() -> void: _act_banner.visible = false)


func _build_act_banner() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = UiStyle.make_theme()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := UiStyle.label("", 32, UiStyle.ACCENT)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := UiStyle.label("El Arquitecto del Monolito ha sido terminado (kill -9).\nEl Servidor Principal sigue caído, pero ahora es culpa de otro.\nSe ha abierto un portal al campamento: ve a contárselo a Aida.", 16)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	return panel


## Tienda de Nacho (con el inventario al lado para vender).
func open_shop(stock: Array[Item]) -> void:
	dialogue_box.close()
	_open_trade_panel(shop_panel)
	shop_panel.open(stock)


## Alijo de la cuenta: click en la bolsa guarda, click en el alijo saca.
func open_stash(stash: Stash) -> void:
	if stash_panel.stash == null:
		stash_panel.setup(_character, stash, item_tooltip)
	_open_trade_panel(stash_panel)
	inventory_panel.bag_click_override = stash_panel.store_from_bag


func _open_trade_panel(panel: Control) -> void:
	skills_panel.visible = false
	character_sheet.visible = false
	shop_panel.visible = false
	stash_panel.visible = false
	inventory_panel.bag_click_override = Callable()
	panel.visible = true
	inventory_panel.visible = true
	item_tooltip.hide()
	_update_minimap()


func close_trade_panels() -> void:
	shop_panel.visible = false
	stash_panel.visible = false
	inventory_panel.bag_click_override = Callable()
	item_tooltip.hide()


func open_dialogue(npc: Dictionary, dialogue: Dictionary) -> void:
	inventory_panel.visible = false
	skills_panel.visible = false
	character_sheet.visible = false
	_update_minimap()
	item_tooltip.hide()
	dialogue_box.open(npc, dialogue)
	tutorial.notify("talked:" + String(npc.get("id", "")))


func _process(_delta: float) -> void:
	# Alejarse del NPC cierra la conversación.
	if dialogue_box.visible and not dialogue_box.npc.is_empty():
		var p: Array = dialogue_box.npc["position"]
		if _player.global_position.distance_to(Vector2(p[0], p[1])) > 220.0:
			dialogue_box.close()


func _build_pause_menu() -> Control:
	# Capa oscura a pantalla completa con un panel centrado.
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.visible = false
	overlay.theme = UiStyle.make_theme()
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := UiStyle.label("Pausa", 32, UiStyle.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := UiStyle.label("La partida se guarda sola. Pero por si acaso.", 14, UiStyle.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	box.add_child(UiStyle.button("Continuar", toggle_pause_menu, 320))
	# Sonido de los diálogos.
	var narrator := UiStyle.button("", func() -> void: pass, 320)
	var refresh_narrator := func() -> void:
		if not DialogueBox.narrator_available():
			narrator.text = "Narrador: sin voz en español"
			narrator.disabled = true
			narrator.tooltip_text = "Instala una voz en español en el sistema (Windows: Configuración → Hora e idioma → Voz)."
		else:
			narrator.text = "Narrador (voz): " + ("sí" if DialogueBox.narrator_enabled() else "no")
	refresh_narrator.call()
	narrator.pressed.connect(func() -> void:
		GameSettings.set_value("dialogue", "narrator", not DialogueBox.narrator_enabled())
		refresh_narrator.call())
	box.add_child(narrator)
	var blips := UiStyle.button("", func() -> void: pass, 320)
	blips.text = "Pitidos del texto: " + ("sí" if DialogueBox.blips_enabled() else "no")
	blips.tooltip_text = "Sonido retro mientras se escribe el texto (cuando no habla el narrador)."
	blips.pressed.connect(func() -> void:
		GameSettings.set_value("dialogue", "blips", not DialogueBox.blips_enabled())
		blips.text = "Pitidos del texto: " + ("sí" if DialogueBox.blips_enabled() else "no"))
	box.add_child(blips)
	# Voz: velocidad y volumen (cada NPC además tiene su tono, velocidad, género y volumen en npcs.json).
	var speed_steps := [0.8, 1.0, 1.25]
	var speed_names := ["lenta", "normal", "rápida"]
	var speed := UiStyle.button("", func() -> void: pass, 320)
	var speed_index := func() -> int:
		var cur := 1
		for k in speed_steps.size():
			if absf(speed_steps[k] - DialogueBox.voice_speed()) < 0.05:
				cur = k
		return cur
	var refresh_speed := func() -> void:
		speed.text = "Velocidad de la voz: " + speed_names[speed_index.call()]
	speed.pressed.connect(func() -> void:
		GameSettings.set_value("dialogue", "voice_speed", speed_steps[(speed_index.call() + 1) % speed_steps.size()])
		refresh_speed.call())
	refresh_speed.call()
	box.add_child(speed)
	var vol_steps := [0.4, 0.7, 1.0]
	var vol := UiStyle.button("", func() -> void: pass, 320)
	var refresh_vol := func() -> void:
		vol.text = "Volumen de la voz: %d %%" % int(round(DialogueBox.voice_volume() * 100.0))
	vol.pressed.connect(func() -> void:
		var cur := 0
		for k in vol_steps.size():
			if absf(vol_steps[k] - DialogueBox.voice_volume()) < 0.05:
				cur = k
		GameSettings.set_value("dialogue", "voice_volume", vol_steps[(cur + 1) % vol_steps.size()])
		refresh_vol.call())
	refresh_vol.call()
	box.add_child(vol)
	var music_steps := [0.0, 0.4, 0.7, 1.0]
	var music := UiStyle.button("", func() -> void: pass, 320)
	var refresh_music := func() -> void:
		music.text = "Volumen de la música: %d %%" % int(round(MusicPlayer.music_volume * 100.0))
	music.pressed.connect(func() -> void:
		var cur := 0
		for k in music_steps.size():
			if absf(music_steps[k] - MusicPlayer.music_volume) < 0.05:
				cur = k
		MusicPlayer.set_volume(music_steps[(cur + 1) % music_steps.size()])
		refresh_music.call())
	refresh_music.call()
	box.add_child(music)
	# Efectos de habilidades y ambiente de las zonas.
	var sfx :=UiStyle.button("", func() -> void: pass, 320)
	sfx.text = "Efectos de sonido: " + ("sí" if Sfx.sfx_enabled() else "no")
	sfx.pressed.connect(func() -> void:
		GameSettings.set_value("audio", "sfx", not Sfx.sfx_enabled())
		sfx.text = "Efectos de sonido: " + ("sí" if Sfx.sfx_enabled() else "no"))
	box.add_child(sfx)
	var ambient := UiStyle.button("", func() -> void: pass, 320)
	ambient.text = "Sonido ambiente: " + ("sí" if Sfx.ambient_enabled() else "no")
	ambient.pressed.connect(func() -> void:
		GameSettings.set_value("audio", "ambient", not Sfx.ambient_enabled())
		Sfx.refresh_settings()
		ambient.text = "Sonido ambiente: " + ("sí" if Sfx.ambient_enabled() else "no"))
	box.add_child(ambient)
	box.add_child(UiStyle.button("Guardar y volver al menú", func() -> void: return_to_menu_requested.emit(), 320))
	box.add_child(UiStyle.button("Guardar y salir del juego", func() -> void: quit_requested.emit(), 320))
	return overlay


func toggle_pause_menu() -> void:
	_pause_panel.visible = not _pause_panel.visible
	item_tooltip.hide()
	get_tree().paused = _pause_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if cutscene.is_playing():
		return
	if _pause_panel.visible:
		if event.is_action_pressed(&"ui_cancel"):
			toggle_pause_menu()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel"):
		# Esc cierra lo que esté abierto; si no hay nada, pausa.
		if challenge_panel.visible:
			challenge_panel._close()
		elif shop_panel.visible or stash_panel.visible:
			close_trade_panels()
			inventory_panel.visible = false
			_update_minimap()
		elif _waypoint_panel.visible:
			_waypoint_panel.visible = false
		elif dialogue_box.visible:
			dialogue_box.close()
		elif tree_screen.visible:
			toggle_passive_tree()
		elif inventory_panel.visible or skills_panel.visible or character_sheet.visible:
			inventory_panel.visible = false
			skills_panel.visible = false
			character_sheet.visible = false
			_update_minimap()
			item_tooltip.hide()
		else:
			toggle_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_passives"):
		_on_menu_requested("passives")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_inventory"):
		_on_menu_requested("inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_skills"):
		_on_menu_requested("skills")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_character"):
		_on_menu_requested("character")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_minimap"):
		_minimap_enabled = not _minimap_enabled
		_update_minimap()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_quests"):
		quest_tracker.collapsed = not quest_tracker.collapsed
		get_viewport().set_input_as_handled()


func _on_menu_requested(menu: String) -> void:
	if tree_screen.visible and menu != "passives":
		return
	item_tooltip.hide()
	if menu != "inventory" or inventory_panel.visible:
		close_trade_panels()   # cerrar el inventario (u abrir otra ventana) cierra la tienda
	match menu:
		"passives":
			toggle_passive_tree()
		"inventory":
			inventory_panel.visible = not inventory_panel.visible
		"skills":
			# Habilidades y hoja de personaje ocupan el mismo sitio.
			skills_panel.visible = not skills_panel.visible
			character_sheet.visible = character_sheet.visible and not skills_panel.visible
		"character":
			character_sheet.visible = not character_sheet.visible
			skills_panel.visible = skills_panel.visible and not character_sheet.visible
	_update_minimap()


## El minimapa comparte esquina con el inventario: se oculta mientras está abierto.
## (Y el tutorial comparte esquina con la hoja de personaje.)
func _update_minimap() -> void:
	tutorial.suppressed = character_sheet.visible or tree_screen.visible
	minimap.visible = _minimap_enabled and not inventory_panel.visible and not tree_screen.visible
	# Sin minimapa, el registro sube a su sitio.
	quest_tracker.visible = quest_tracker.quests != null and not inventory_panel.visible and not tree_screen.visible
	quest_tracker.offset_top = (minimap.offset_bottom + 6.0) if minimap.visible else 14.0


## Soltar un objeto fuera de los paneles: al suelo, junto al jugador.
func _on_drop_to_ground(location: Dictionary) -> void:
	var mouse := get_viewport().get_mouse_position()
	for panel: Control in [inventory_panel, skills_panel, character_sheet, shop_panel, stash_panel, hud]:
		if panel != hud and panel.visible and panel.get_global_rect().has_point(mouse):
			return  # soltado sobre un panel, en un sitio que no admite objetos
	if hud.is_over_hud(mouse):
		return
	if ItemTransfer.get_at(_character.inventory, location) is KeyItem:
		hud.flash("Es un objeto clave. Mejor no tirarlo: abre caminos que necesitarás.", UiStyle.ACCENT)
		return
	var item := ItemTransfer.take(_character, location)
	if item:
		_loot.drop_item(item, _player.global_position + Vector2(randf_range(-40.0, 40.0), randf_range(20.0, 50.0)))
		hud.flash("%s, al suelo. Alguien lo recogerá. O no." % item.display_name(), UiStyle.MUTED)


func toggle_passive_tree() -> void:
	tree_screen.visible = not tree_screen.visible
	hud.visible = not tree_screen.visible
	if tree_screen.visible:
		close_trade_panels()
		inventory_panel.visible = false
		skills_panel.visible = false
		character_sheet.visible = false
		dialogue_box.close()
		item_tooltip.hide()
	_update_minimap()
	get_tree().paused = tree_screen.visible


func show_death() -> void:
	_death_panel.visible = true
	dialogue_box.close()
	# Centrar tras calcular su tamaño.
	_death_panel.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)


func hide_death() -> void:
	_death_panel.visible = false


func _on_ground_item_hovered(item: Item) -> void:
	if tree_screen.visible:
		return
	if item == null:
		item_tooltip.hide()
	else:
		item_tooltip.show_item(item, _character, item.is_equipment())
