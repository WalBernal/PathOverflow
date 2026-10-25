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
## Tamaños de interfaz del menú de pausa.
const UI_SCALES := [0.85, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]
## Separación entre el alijo o la tienda y el inventario cuando se encogen para caber.
const TRADE_GAP := 8.0
## Tope de la escala (por si el archivo de ajustes trae un valor a mano).
const UI_SCALE_MAX := 1.6
## Alto mínimo (en px de interfaz) para que quepan el inventario y los menús: en
## pantallas bajas la escala elegida se reduce hasta caber (160 % necesita 1080p).
const UI_MIN_HEIGHT := 560.0

var hud: Hud
var inventory_panel: InventoryPanel
var skills_panel: SkillsPanel
var tree_screen: PassiveTreeScreen
var dialogue_box: DialogueBox
var tutorial: TutorialPanel
## Consejos de primera vez (esquiva, cargas, golpes pesados, terrenos, arena).
var tips: TipPanel
var item_tooltip: ItemTooltip
var minimap: Minimap
var world_map: WorldMap
var catalog: CatalogPanel
var loot_filter_panel: LootFilterPanel
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
var _root: Control
var gamepad_cursor: GamepadCursor


func setup(player: Player, enemies: EnemyManager, character: CharacterData, loot: LootManager,
		skills: SkillController, quests: QuestLog = null) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_character = character
	_player = player
	_loot = loot
	# Toda la interfaz cuelga de _root, que se escala con el tamaño de interfaz
	# del menú de pausa (el mundo no cambia).
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	get_viewport().size_changed.connect(apply_ui_scale)
	apply_ui_scale()

	hud = Hud.new()
	hud.player = player
	hud.enemies = enemies
	hud.character = character
	hud.skills = skills
	_root.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.menu_requested.connect(_on_menu_requested)

	# El tooltip se crea antes (lo usan los paneles) pero se añade al final,
	# para que quede por encima de todo.
	item_tooltip = ItemTooltip.new()

	tutorial = TutorialPanel.new()
	_root.add_child(tutorial)
	tutorial.position = Vector2(10, 34)
	tutorial.setup(character, player)
	tutorial.step_completed.connect(func(text: String) -> void: hud.flash(text, Color("6fb36b")))

	tips = TipPanel.new()
	_root.add_child(tips)
	tips.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tips.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tips.offset_top = 96.0   # debajo de la barra del jefe
	tips.setup(character, player, enemies, skills)

	inventory_panel = InventoryPanel.new()
	inventory_panel.visible = false
	_root.add_child(inventory_panel)
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
	_root.add_child(skills_panel)
	skills_panel.position = Vector2(10, 10)
	skills_panel.setup(character, item_tooltip)
	skills_panel.message.connect(hud.flash)
	skills_panel.close_requested.connect(func() -> void: _on_menu_requested("skills"))
	skills_panel.drop_to_ground.connect(_on_drop_to_ground)
	inventory_panel.drop_to_ground.connect(_on_drop_to_ground)

	character_sheet = CharacterSheet.new()
	character_sheet.visible = false
	_root.add_child(character_sheet)
	character_sheet.position = Vector2(10, 34)
	character_sheet.setup(character, player, skills)
	character_sheet.close_requested.connect(func() -> void: _on_menu_requested("character"))
	character_sheet.passives_requested.connect(func() -> void: _on_menu_requested("passives"))

	# Comerciante y alijo: a la izquierda, con el inventario abierto a la derecha.
	shop_panel = ShopPanel.new()
	_root.add_child(shop_panel)
	shop_panel.position = Vector2(10, 34)
	shop_panel.setup(character, item_tooltip)
	shop_panel.message.connect(hud.flash)
	shop_panel.close_requested.connect(close_trade_panels)
	shop_panel.refresh_requested.connect(func() -> void: shop_refresh_requested.emit())
	stash_panel = StashPanel.new()
	_root.add_child(stash_panel)
	stash_panel.position = Vector2(10, 34)
	stash_panel.message.connect(hud.flash)
	stash_panel.close_requested.connect(close_trade_panels)
	stash_panel.drop_to_ground.connect(_on_drop_to_ground)

	minimap = Minimap.new()
	minimap.player = player
	minimap.enemies = enemies
	minimap.loot = loot
	_root.add_child(minimap)
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -Minimap.RADIUS * 2.0 - 18.0
	minimap.offset_right = -18.0
	minimap.offset_top = 14.0
	minimap.offset_bottom = 14.0 + minimap.custom_minimum_size.y

	# Mapa grande (Tab), por encima del HUD y debajo de las ventanas.
	world_map = WorldMap.new()
	world_map.player = player
	world_map.enemies = enemies
	world_map.loot = loot
	world_map.character = character
	_root.add_child(world_map)
	world_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Registro de misiones, debajo del minimapa.
	quest_tracker = QuestTracker.new()
	_root.add_child(quest_tracker)
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
	_root.add_child(dialogue_box)
	dialogue_box.action_requested.connect(func(action: Dictionary) -> void: dialogue_action.emit(action))

	tree_screen = TREE_SCREEN.instantiate() as PassiveTreeScreen
	tree_screen.standalone = false
	tree_screen.visible = false
	_root.add_child(tree_screen)
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
	_root.add_child(_death_panel)
	_death_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	_waypoint_panel = WaypointPanel.new()
	_waypoint_panel.visible = false
	_root.add_child(_waypoint_panel)
	_waypoint_panel.selected.connect(func(zone_id: String) -> void:
		_waypoint_panel.visible = false
		waypoint_selected.emit(zone_id))

	_zone_banner = UiStyle.label("", 34, UiStyle.ACCENT)
	_zone_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_banner.add_theme_constant_override("outline_size", 8)
	_zone_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_zone_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_zone_banner)
	_zone_banner.anchor_right = 1.0
	_zone_banner.offset_top = 165.0
	_zone_banner.modulate.a = 0.0

	_act_banner = _build_act_banner()
	_root.add_child(_act_banner)

	challenge_panel = ChallengePanel.new()
	_root.add_child(challenge_panel)
	challenge_panel.setup(item_tooltip, character)

	_wave_label = UiStyle.label("", 20, Color("ff9a4a"))
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_constant_override("outline_size", 6)
	_wave_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_label.visible = false
	_root.add_child(_wave_label)
	_wave_label.anchor_right = 1.0
	_wave_label.offset_top = 60.0

	cutscene = CutscenePlayer.new()
	cutscene.player = player
	cutscene.speakers = {"player": {"name": character.character_name, "appearance": character.appearance,
		"color": character.class_def.get("color", "d9a441")}}
	_root.add_child(cutscene)

	catalog = CatalogPanel.new()
	_root.add_child(catalog)
	catalog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catalog.setup(character, (get_node("/root/GameData").get("items") as ItemDatabase).skills)
	catalog.close_requested.connect(toggle_catalog)
	loot_filter_panel = LootFilterPanel.new()
	_root.add_child(loot_filter_panel)
	loot_filter_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loot_filter_panel.setup(loot)
	loot_filter_panel.close_requested.connect(toggle_loot_filter)

	_pause_panel = _build_pause_menu()
	_root.add_child(_pause_panel)
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_root.add_child(item_tooltip)
	# Cursor de mando para las ventanas: encima de todo y sin la escala de _root.
	gamepad_cursor = GamepadCursor.new()
	gamepad_cursor.windows = cursor_windows
	gamepad_cursor.pin = func() -> void: item_tooltip.toggle_pin()
	gamepad_cursor.cancel = func() -> void:
		var esc := InputEventAction.new()
		esc.action = &"ui_cancel"
		esc.pressed = true
		_unhandled_input(esc)
	add_child(gamepad_cursor)
	loot.hovered_item_changed.connect(_on_ground_item_hovered)
	loot.pickup_failed.connect(hud.flash)
	loot.picked_up.connect(func(item: Item) -> void:
		tutorial.notify("picked_up")
		CatalogPanel.note_item(character, item))
	skills.skill_used.connect(func(_i: int) -> void: tutorial.notify("skill_used"))
	skills.skill_used.connect(hud.notify_skill_used)
	skills.not_enough_mana.connect(func() -> void: hud.flash("Sin maná. Bebe un refresco (teclas 1-5) o espera, como con el compilador."))
	skills.trigger_only.connect(func(skill_name: String) -> void:
		hud.flash("%s lleva una RAM de activación: se lanza sola (no a mano)." % skill_name, Color("ffd84a")))
	skills.not_enough_life.connect(func() -> void: hud.flash("Esa habilidad se paga con vida y no te sobra. Cúrate antes de hacer otro hotfix."))
	skills.reservation_full.connect(func(skill_name: String) -> void:
		hud.flash("No queda maná sin reservar para otra invocación de %s. Tus procesos en segundo plano ya se lo comen todo." % skill_name))
	skills.unit_lost.connect(func(skill_name: String) -> void:
		hud.flash("Ha caído tu %s. Vuelve a lanzar la habilidad para montarlo otra vez." % skill_name, Color("ff9a4a")))
	player.flask_used.connect(func(_i: int) -> void: tutorial.notify("flask_used"))


## Al entrar en una zona: minimapa, tutorial y el nombre de la zona en grande.
func on_zone_changed(zone: Zone) -> void:
	minimap.zone = zone
	world_map.set_zone(zone)
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
	_update_minimap()
	_fit_trade_panels()
	# Alejarse del NPC cierra la conversación.
	if dialogue_box.visible and not dialogue_box.npc.is_empty():
		var p: Array = dialogue_box.npc["position"]
		if _player.global_position.distance_to(Vector2(p[0], p[1])) > 220.0:
			dialogue_box.close()


func _build_pause_menu() -> Control:
	# Capa oscura a pantalla completa con un panel centrado: arriba el título,
	# en medio dos columnas (sonido | diálogos e interfaz) y abajo las salidas.
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.visible = false
	overlay.theme = UiStyle.make_theme()
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	UiStyle.decorate_window(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := UiStyle.label("Pausa", 32, UiStyle.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := UiStyle.label("La partida se guarda sola. Pero por si acaso.", 14, UiStyle.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	box.add_child(UiStyle.ornament())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	box.add_child(columns)

	# --- Sonido: un deslizador por canal ---
	var sound := VBoxContainer.new()
	sound.add_theme_constant_override("separation", 8)
	columns.add_child(sound)
	sound.add_child(UiStyle.section_header("Sonido"))
	sound.add_child(UiStyle.slider_row("Música", 0.0 if MusicPlayer.muted else MusicPlayer.music_volume,
		func(v: float) -> void:
			if MusicPlayer.muted and v > 0.0:
				MusicPlayer.toggle_mute()
			MusicPlayer.set_volume(v)))
	sound.add_child(UiStyle.slider_row("Efectos", Sfx.sfx_volume(), func(v: float) -> void: Sfx.set_volume("sfx", v)))
	sound.add_child(UiStyle.slider_row("Ambiente", Sfx.ambient_volume(), func(v: float) -> void: Sfx.set_volume("ambient", v)))
	sound.add_child(UiStyle.slider_row("Voces", DialogueBox.voice_volume(),
		func(v: float) -> void: GameSettings.set_value("dialogue", "voice_volume", v)))
	var sound_hint := UiStyle.label("Al 0 % el canal se apaga del todo.", 12, UiStyle.MUTED)
	sound.add_child(sound_hint)

	# --- Diálogos e interfaz ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)
	right.add_child(UiStyle.section_header("Diálogos"))
	var narrator := UiStyle.button("", func() -> void: pass, 300)
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
	right.add_child(narrator)
	var blips := UiStyle.button("", func() -> void: pass, 300)
	blips.text = "Pitidos del texto: " + ("sí" if DialogueBox.blips_enabled() else "no")
	blips.tooltip_text = "Sonido retro mientras se escribe el texto (cuando no habla el narrador)."
	blips.pressed.connect(func() -> void:
		GameSettings.set_value("dialogue", "blips", not DialogueBox.blips_enabled())
		blips.text = "Pitidos del texto: " + ("sí" if DialogueBox.blips_enabled() else "no"))
	right.add_child(blips)
	# Voz: velocidad (cada NPC además tiene su tono, velocidad, género y volumen en npcs.json).
	right.add_child(_cycle_button("Velocidad de la voz", [0.8, 1.0, 1.25], ["lenta", "normal", "rápida"],
		func() -> float: return DialogueBox.voice_speed(),
		func(v: float) -> void: GameSettings.set_value("dialogue", "voice_speed", v)))
	right.add_child(UiStyle.section_header("Interfaz"))
	var scale_button := _cycle_button("Tamaño de la interfaz", UI_SCALES, UI_SCALES.map(func(v: float) -> String: return "%d %%" % roundi(v * 100.0)),
		func() -> float: return ui_scale(),
		func(v: float) -> void:
			GameSettings.set_value("interface", "scale", v)
			apply_ui_scale())
	scale_button.tooltip_text = "Agranda o achica los menús, el HUD y los textos. El mundo se ve igual."
	right.add_child(scale_button)
	var colorblind := UiStyle.button("", func() -> void: pass, 300)
	colorblind.text = "Modo daltónico: " + ("sí" if Ailments.colorblind else "no")
	colorblind.tooltip_text = "Colores que se distinguen con cualquier tipo de daltonismo: estados alterados\n(quemado, sangrando, envenenado, helado, corrompido...), auras y cargas."
	colorblind.pressed.connect(func() -> void:
		Ailments.set_colorblind(not Ailments.colorblind)
		colorblind.text = "Modo daltónico: " + ("sí" if Ailments.colorblind else "no"))
	right.add_child(colorblind)
	var flashes := UiStyle.button("", func() -> void: pass, 300)
	flashes.text = "Menos destellos: " + ("sí" if Accessibility.reduce_flashes else "no")
	flashes.tooltip_text = "Atenúa los fogonazos (golpes a jefes, cambios de fase, luz de impactos) y los glitches\nde las escenas y del prólogo, y deja fijo lo que parpadea."
	flashes.pressed.connect(func() -> void:
		Accessibility.set_reduce_flashes(not Accessibility.reduce_flashes)
		flashes.text = "Menos destellos: " + ("sí" if Accessibility.reduce_flashes else "no"))
	right.add_child(flashes)
	var world_text := _cycle_button("Texto del mundo", Accessibility.WORLD_TEXT_SIZES, Accessibility.WORLD_TEXT_SIZES.map(func(v: float) -> String: return "%d %%" % roundi(v * 100.0)),
		func() -> float: return Accessibility.world_text,
		func(v: float) -> void: Accessibility.set_world_text(v))
	world_text.tooltip_text = "Tamaño de los nombres de enemigos y PNJ, las etiquetas del botín y los avisos del mundo,\naparte del tamaño de la interfaz."
	right.add_child(world_text)
	var pixel := UiStyle.button("", func() -> void: pass, 300)
	pixel.text = "Filtro pixel art: " + ("sí" if WorldPost.enabled() else "no")
	pixel.tooltip_text = "Rejilla de píxeles, paleta con tramado, luz y sombra de cada zona.\nApágalo si prefieres el mundo nítido."
	pixel.pressed.connect(func() -> void:
		GameSettings.set_value("interface", "pixel_filter", not WorldPost.enabled())
		pixel.text = "Filtro pixel art: " + ("sí" if WorldPost.enabled() else "no")
		for p in get_tree().get_nodes_in_group(&"world_post"):
			p.call("refresh"))
	right.add_child(pixel)
	var tips_button := UiStyle.button("", func() -> void: pass, 300)
	tips_button.text = "Consejos de mecánicas: " + ("sí" if TipPanel.enabled() else "no")
	tips_button.tooltip_text = "Un aviso corto la primera vez que aparece la esquiva, las cargas, los golpes pesados,\nlos terrenos o una mecánica de arena de jefe."
	tips_button.pressed.connect(func() -> void:
		TipPanel.set_enabled(not TipPanel.enabled())
		tips_button.text = "Consejos de mecánicas: " + ("sí" if TipPanel.enabled() else "no"))
	right.add_child(tips_button)
	var controls := UiStyle.button("Controles...", open_controls, 300)
	controls.tooltip_text = "Cambia la tecla o el botón del mando de cada acción."
	right.add_child(controls)
	var loot_filter := UiStyle.button("Filtro de botín...", toggle_loot_filter, 300)
	loot_filter.tooltip_text = "Qué se ve en el suelo, por tipo y rareza, y desde qué rareza sale el haz de luz.\nMantén Shift para ver lo oculto."
	right.add_child(loot_filter)
	var scaling := UiStyle.button("", func() -> void: pass, 300)
	var scaling_text := func() -> String:
		return "Zonas completadas a tu nivel: " + ("sí" if Difficulty.scaling_enabled(GameData.current_character) else "no")
	scaling.text = scaling_text.call()
	scaling.tooltip_text = "Las zonas de combate de los actos ya terminados suben a tu nivel (si estás por encima) para que sigan dando pelea y botín de tu nivel.\nSe nota al volver a entrar en la zona."
	scaling.pressed.connect(func() -> void:
		var c: CharacterData = GameData.current_character
		if c:
			c.flags[Difficulty.SCALING_FLAG] = not Difficulty.scaling_enabled(c)
		scaling.text = scaling_text.call())
	right.add_child(scaling)
	var achievements := UiStyle.button("Logros y cosméticos...", open_achievements, 300)
	achievements.tooltip_text = "Tus logros y los sombreros, auras y pisadas que te dan."
	right.add_child(achievements)
	var ladder := UiStyle.button("Récords...", open_ladder, 300)
	ladder.tooltip_text = "Tus récords y la tabla local: oleadas sin fin y tiempo contra cada jefe."
	right.add_child(ladder)
	var debt := UiStyle.button("Deuda técnica...", open_tech_debt, 300)
	debt.tooltip_text = "Árbol de fin de juego (tras el Acto IV): cada nodo, un bono fuerte y una penalización."
	right.add_child(debt)
	var lore := UiStyle.button("Archivos encontrados...", open_lore_log, 300)
	lore.tooltip_text = "Commits perdidos, logs y correos de la UAdeO que has encontrado por las zonas."
	right.add_child(lore)
	# --- Combate (en la columna del sonido, que es más corta) ---
	sound.add_child(UiStyle.section_header("Combate"))
	var shake := _cycle_button("Sacudida de cámara", [0.0, 0.5, 1.0], ["no", "suave", "normal"],
		func() -> float: return Player.shake_scale,
		func(v: float) -> void: Player.set_shake_scale(v))
	shake.tooltip_text = "Cuánto tiembla la pantalla con golpes fuertes, críticos, jefes y explosiones."
	sound.add_child(shake)
	var hitstop := UiStyle.button("", func() -> void: pass, 300)
	hitstop.text = "Pausa al golpear (hitstop): " + ("sí" if World.hitstop_enabled() else "no")
	hitstop.tooltip_text = "Una pausa de milésimas al hacer un crítico o matar a un raro: da peso al golpe."
	hitstop.pressed.connect(func() -> void:
		World.set_hitstop(not World.hitstop_enabled())
		hitstop.text = "Pausa al golpear (hitstop): " + ("sí" if World.hitstop_enabled() else "no"))
	sound.add_child(hitstop)
	var auto := UiStyle.button("", func() -> void: pass, 300)
	auto.text = "Auto-ataque: " + ("sí" if SkillController.auto_attack else "no")
	auto.tooltip_text = "Sin pulsar nada ni moverte, la habilidad 1 se lanza sola contra el enemigo más cercano.\nNo vale para auras, invocaciones ni canalizadas."
	auto.pressed.connect(func() -> void:
		SkillController.auto_attack = not SkillController.auto_attack
		GameSettings.set_value("combat", "auto_attack", SkillController.auto_attack)
		auto.text = "Auto-ataque: " + ("sí" if SkillController.auto_attack else "no"))
	sound.add_child(auto)
	var move_names := {"hold": "mantener", "toggle": "alternar", "click": "clic para ir"}
	var move := UiStyle.button("", func() -> void: pass, 300)
	move.text = "Moverse con el ratón: " + move_names.get(Player.mouse_move, "mantener")
	move.tooltip_text = "Mantener: sigues al cursor mientras mantienes el clic.\nAlternar: un clic empieza a seguirlo y otro para (sin mantener el botón).\nClic para ir: como mantener, y al soltar caminas hasta ese punto."
	move.pressed.connect(func() -> void:
		var modes := Player.MOUSE_MOVE_MODES
		Player.mouse_move = modes[(modes.find(Player.mouse_move) + 1) % modes.size()]
		GameSettings.set_value("combat", "mouse_move", Player.mouse_move)
		move.text = "Moverse con el ratón: " + move_names.get(Player.mouse_move, "mantener"))
	sound.add_child(move)

	box.add_child(UiStyle.ornament())
	var exits := HBoxContainer.new()
	exits.add_theme_constant_override("separation", 10)
	exits.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(exits)
	exits.add_child(UiStyle.button("Continuar", toggle_pause_menu, 200))
	exits.add_child(UiStyle.button("Guardar y volver al menú", func() -> void: return_to_menu_requested.emit(), 240))
	exits.add_child(UiStyle.button("Guardar y salir del juego", func() -> void: quit_requested.emit(), 240))
	return overlay


## Botón que recorre una lista de valores ("Velocidad de la voz: normal").
## `current` devuelve el valor guardado; `on_pick` guarda el nuevo.
func _cycle_button(text: String, values: Array, names: Array, current: Callable, on_pick: Callable) -> Button:
	var b := UiStyle.button("", func() -> void: pass, 300)
	var index := func() -> int:
		var best := 0
		for k in values.size():
			if absf(float(values[k]) - float(current.call())) < absf(float(values[best]) - float(current.call())):
				best = k
		return best
	var refresh := func() -> void:
		b.text = "%s: %s" % [text, names[index.call()]]
	b.pressed.connect(func() -> void:
		on_pick.call(values[(index.call() + 1) % values.size()])
		refresh.call())
	refresh.call()
	return b


static func ui_scale() -> float:
	return clampf(float(GameSettings.get_value("interface", "scale", 1.0)), 0.75, UI_SCALE_MAX)


## Escala la interfaz (menús, HUD, textos): _root ocupa la pantalla dividida por
## la escala y se agranda por ella, así los anclajes siguen cuadrando.
func apply_ui_scale() -> void:
	var s := minf(ui_scale(), maxf(1.0, get_viewport().get_visible_rect().size.y / UI_MIN_HEIGHT))
	_root.scale = Vector2(s, s)
	_root.size = get_viewport().get_visible_rect().size / s
	if inventory_panel:
		inventory_panel.fit_height.call_deferred()
	get_tree().call_group.call_deferred(&"fit_scroll", &"fit")


# --- Elección de habilidad (desbloqueos por nivel con dos opciones) ---

var _choice_panel: Control


func is_choosing() -> bool:
	return _choice_panel != null and is_instance_valid(_choice_panel)


## Ventana con dos (o más) placas a elegir: icono, nombre, tipo y descripción.
## Pausa el juego hasta que se elige; `on_pick` recibe el id de la habilidad.
func show_skill_choice(title: String, defs: Array, on_pick: Callable) -> void:
	if is_choosing() or defs.is_empty():
		return
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.theme = UiStyle.make_theme()
	_root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_panel = overlay
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	UiStyle.decorate_window(panel)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UiStyle.window_header(title, "Solo una: la otra no volverá a ofrecerse (aunque puede caer como botín).", Callable()))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for def in defs:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyle.inset_style(Color(def.get("icon", {}).get("color", "8a6d3b"))))
		card.custom_minimum_size = Vector2(300, 0)
		row.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.draw.connect(func() -> void: SkillIcon.draw(icon, Rect2(Vector2.ZERO, icon.size), def))
		col.add_child(icon)
		var name_label := UiStyle.label(def["name"], 18, UiStyle.ACCENT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_label)
		var tags := UiStyle.label(SkillTags.plain(def.get("tags", [])), 11, UiStyle.MUTED)
		tags.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(tags)
		var desc := UiStyle.label(String(def.get("description", "")), 13)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 280
		col.add_child(desc)
		var pick := UiStyle.button("Elegir", func() -> void: pass, 280)
		pick.pressed.connect(_on_choice_picked.bind(String(def["id"]), on_pick))
		col.add_child(pick)
	get_tree().paused = true


func _on_choice_picked(skill_id: String, on_pick: Callable) -> void:
	if is_choosing():
		_choice_panel.queue_free()
	_choice_panel = null
	get_tree().paused = false
	on_pick.call(skill_id)


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
		if loot_filter_panel.visible:
			toggle_loot_filter()
		elif catalog.visible:
			toggle_catalog()
		elif world_map.visible:
			world_map.toggle()
		elif challenge_panel.visible:
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
		if cursor_windows().is_empty():
			item_tooltip.unpin()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pin_tooltip"):
		item_tooltip.toggle_pin()
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
	elif event.is_action_pressed(&"toggle_map"):
		world_map.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_catalog"):
		toggle_catalog()
		get_viewport().set_input_as_handled()


## Ventanas que se manejan con el cursor de mando: el árbol pasivo, los
## diálogos y la elección de habilidad van solos; si no, las de objetos.
func cursor_windows() -> Array:
	if _pause_panel.visible or cutscene.is_playing():
		return []
	if tree_screen.visible:
		return [tree_screen]
	if is_choosing():
		return [_choice_panel]
	if dialogue_box.visible:
		return [dialogue_box]
	return [shop_panel, stash_panel, skills_panel, character_sheet, inventory_panel].filter(func(w: Control) -> bool: return w.visible)


func _on_menu_requested(menu: String) -> void:
	if tree_screen.visible and menu != "passives":
		return
	hud.attention.erase(menu)   # ya se vio la novedad
	item_tooltip.hide()
	item_tooltip.unpin()
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
		"catalog":
			toggle_catalog()
	_update_minimap()


## Logros y cosméticos (desde la pausa).
func open_achievements() -> void:
	var panel := AchievementsPanel.new(GameData.current_character)
	_root.add_child(panel)
	panel.popup_centered()


## Récords del banco de oleadas y de los jefes (pausa o Aida).
func open_ladder() -> void:
	var panel := LadderPanel.new(GameData.current_character)
	_root.add_child(panel)
	panel.popup_centered()


## Reasignar teclas y botones (desde la pausa).
func open_controls() -> void:
	var panel := ControlsPanel.new()
	_root.add_child(panel)
	panel.popup_centered()


## Árbol de deuda técnica (desde la pausa).
func open_tech_debt() -> void:
	var panel := TechDebtPanel.new(GameData.current_character)
	_root.add_child(panel)
	panel.popup_centered()


## Registro del lore coleccionable (desde la pausa).
func open_lore_log() -> void:
	var lore_log := LoreLog.new(GameData.current_character)
	_root.add_child(lore_log)
	lore_log.popup_centered()


## Catálogo de hardware (B): pausa el juego mientras está abierto, como el árbol.
func toggle_catalog() -> void:
	if catalog.visible:
		catalog.visible = false
	else:
		item_tooltip.hide()
		catalog.open()
	get_tree().paused = catalog.visible or tree_screen.visible or _pause_panel.visible


## Filtro de botín: ventana propia (también desde Pausa e inventario).
func toggle_loot_filter() -> void:
	if loot_filter_panel.visible:
		loot_filter_panel.visible = false
	else:
		item_tooltip.hide()
		_pause_panel.visible = false   # desde Pausa: la ventana del filtro la sustituye
		loot_filter_panel.open()
	get_tree().paused = loot_filter_panel.visible or catalog.visible or tree_screen.visible or _pause_panel.visible


## El minimapa comparte esquina con el inventario: se oculta mientras está abierto.
## Con la interfaz grande, otras ventanas (hoja de personaje, habilidades, alijo,
## tienda, waypoints) también llegan bajo el minimapa o el registro de misiones:
## si se enciman, se ocultan mientras la ventana siga abierta (se comprueba en
## cada fotograma, porque el tamaño de las ventanas cambia con su contenido).
## (Y el tutorial comparte esquina con la hoja de personaje.)
func _update_minimap() -> void:
	tutorial.suppressed = character_sheet.visible or tree_screen.visible
	var windows: Array[Rect2] = []
	for w: Control in [character_sheet, skills_panel, stash_panel, shop_panel, _waypoint_panel]:
		if w.visible:
			windows.append(_rect_in_root(w))
	minimap.visible = _minimap_enabled and not inventory_panel.visible and not tree_screen.visible \
		and not _overlaps_any(_rect_in_root(minimap), windows)
	# Sin minimapa, el registro sube a su sitio.
	var tracker_top := (minimap.offset_bottom + 6.0) if minimap.visible else 14.0
	var tracker_rect := _rect_in_root(quest_tracker)
	tracker_rect.position.y += tracker_top - quest_tracker.offset_top   # donde va a quedar
	quest_tracker.offset_top = tracker_top
	quest_tracker.visible = quest_tracker.quests != null and not inventory_panel.visible and not tree_screen.visible \
		and not _overlaps_any(tracker_rect, windows)


## Alijo o tienda (a la izquierda) junto al inventario (a la derecha): con la
## interfaz grande no caben los dos; se encogen lo justo para quedar lado a lado.
func _fit_trade_panels() -> void:
	var trade: Control = stash_panel if stash_panel.visible else (shop_panel if shop_panel.visible else null)
	var f := 1.0
	if trade and inventory_panel.visible:
		var inv_right_margin := _root.size.x - (inventory_panel.position.x + inventory_panel.size.x)
		var room := _root.size.x - trade.position.x - inv_right_margin - TRADE_GAP
		f = clampf(room / (trade.size.x + inventory_panel.size.x), 0.5, 1.0)
	for c: Control in [stash_panel, shop_panel]:
		c.scale = Vector2(f, f) if c == trade else Vector2.ONE
	inventory_panel.pivot_offset = Vector2(inventory_panel.size.x, 0.0)   # encoge hacia su esquina derecha
	inventory_panel.scale = Vector2(f, f)


## Rectángulo de un control en las coordenadas de _root (todas las ventanas
## comparten su escala; get_global_rect() mezcla posición escalada y tamaño sin escalar).
func _rect_in_root(c: Control) -> Rect2:
	return (_root.get_global_transform().affine_inverse() * c.get_global_transform()) * Rect2(Vector2.ZERO, c.size)


static func _overlaps_any(r: Rect2, windows: Array[Rect2]) -> bool:
	for w in windows:
		if w.intersects(r):
			return true
	return false


## Soltar un objeto fuera de los paneles: al suelo, junto al jugador.
func _on_drop_to_ground(location: Dictionary) -> void:
	var mouse := get_viewport().get_mouse_position()
	for panel: Control in [inventory_panel, skills_panel, character_sheet, shop_panel, stash_panel, hud]:
		if panel != hud and panel.visible and (panel.get_global_transform() * Rect2(Vector2.ZERO, panel.size)).has_point(mouse):   # con su escala
			return  # soltado sobre un panel, en un sitio que no admite objetos
	if hud.is_over_hud(hud.get_global_transform().affine_inverse() * mouse):
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
