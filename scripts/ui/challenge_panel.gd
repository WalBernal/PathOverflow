class_name ChallengePanel
extends PanelContainer
## Panel de un Banco de Pruebas de Estrés: muestra las oleadas y la recompensa
## (los objetos concretos, con su tooltip) y deja aceptar o rechazar.

signal accepted
signal declined

var _title: Label
var _info: RichTextLabel
var _rewards: HBoxContainer
var _tooltip: ItemTooltip
var _character: CharacterData


func setup(tooltip: ItemTooltip, character: CharacterData) -> void:
	_tooltip = tooltip
	_character = character


func _ready() -> void:
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = UiStyle.label("", 22, Color("ff9a4a"))
	box.add_child(_title)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.custom_minimum_size.x = 460
	box.add_child(_info)
	box.add_child(UiStyle.label("Recompensa garantizada (más botín adicional):", 14, UiStyle.MUTED))
	_rewards = HBoxContainer.new()
	_rewards.add_theme_constant_override("separation", 6)
	box.add_child(_rewards)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var accept := UiStyle.button("Aceptar el desafío", func() -> void:
		_close()
		accepted.emit(), 220)
	buttons.add_child(accept)
	buttons.add_child(UiStyle.button("Ahora no", func() -> void:
		_close()
		declined.emit(), 140))


func open(challenge: Dictionary, rewards: Array) -> void:
	_title.text = challenge.get("name", "Banco de Pruebas de Estrés")
	_info.text = "Resiste [color=#ff9a4a][b]%d oleadas[/b][/color] de enemigos sin morir y sin salir de la zona.\nCada oleada es más dura que la anterior; la última trae élites.\n[color=#8a8293]Si caes, la prueba se reinicia y podrás intentarlo de nuevo.[/color]" % int(challenge.get("waves", 4))
	for c in _rewards.get_children():
		_rewards.remove_child(c)
		c.queue_free()
	for item: Item in rewards:
		var cell := ItemCell.new()
		cell.item = item
		cell.custom_minimum_size = Vector2(56, 56)
		cell.hovered.connect(func(c: ItemCell, inside: bool) -> void:
			if inside and c.item:
				_tooltip.show_item(c.item, _character, false)
			else:
				_tooltip.hide())
		_rewards.add_child(cell)
	visible = true
	reset_size()
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)


func _close() -> void:
	visible = false
	if _tooltip:
		_tooltip.hide()
