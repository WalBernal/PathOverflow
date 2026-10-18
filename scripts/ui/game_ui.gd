class_name GameUI
extends CanvasLayer
## Capa de UI del juego: HUD, inventario (I), árbol pasivo (P, pausa el juego),
## tooltip de objetos y pantalla de muerte.
## Funciona con el juego en pausa (PROCESS_MODE_ALWAYS).

const TREE_SCREEN := preload("res://scenes/ui/passive_tree_screen.tscn")

var hud: Hud
var inventory_panel: InventoryPanel
var tree_screen: PassiveTreeScreen
var item_tooltip: ItemTooltip
var _character: CharacterData
var _death_panel: PanelContainer


func setup(player: Player, enemies: EnemyManager, character: CharacterData, loot: LootManager) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_character = character

	hud = Hud.new()
	hud.player = player
	hud.enemies = enemies
	hud.character = character
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# El tooltip se crea antes (lo usa el inventario) pero se añade al final,
	# para que quede por encima de todo.
	item_tooltip = ItemTooltip.new()

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

	tree_screen = TREE_SCREEN.instantiate() as PassiveTreeScreen
	tree_screen.standalone = false
	tree_screen.visible = false
	add_child(tree_screen)
	tree_screen.show_character(character)
	tree_screen.closed.connect(toggle_passive_tree)

	_death_panel = PanelContainer.new()
	var label := Label.new()
	label.text = "HAS MUERTO\n\nStack trace:\n  en Player.take_damage()\n  en Enemy.attack()\n  en tu_decision_de_ir_sin_resistencias()\n\nPulsa R para reaparecer"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("e06c6c"))
	_death_panel.add_child(label)
	_death_panel.visible = false
	add_child(_death_panel)
	_death_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	add_child(item_tooltip)
	loot.hovered_item_changed.connect(_on_ground_item_hovered)
	loot.pickup_failed.connect(hud.flash)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_passives") \
			or (tree_screen.visible and event.is_action_pressed(&"ui_cancel")):
		toggle_passive_tree()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_inventory") \
			or (inventory_panel.visible and event.is_action_pressed(&"ui_cancel")):
		if not tree_screen.visible:
			inventory_panel.visible = not inventory_panel.visible
			item_tooltip.hide()
			get_viewport().set_input_as_handled()


func toggle_passive_tree() -> void:
	tree_screen.visible = not tree_screen.visible
	hud.visible = not tree_screen.visible
	if tree_screen.visible:
		inventory_panel.visible = false
		item_tooltip.hide()
	get_tree().paused = tree_screen.visible


func show_death() -> void:
	_death_panel.visible = true
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
		item_tooltip.show_item(item, _character, true)
