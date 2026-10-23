class_name MainMenu
extends Control
## Pantalla de inicio: lista de personajes guardados, jugar, crear y borrar.

const CARD_HEIGHT := 84.0

var _saves: Array[Dictionary] = []
var _selected := -1
var _scroll: ScrollContainer
var _list: VBoxContainer
var _empty_label: Label
var _preview: AppearancePreview
var _detail: RichTextLabel
var _play_button: Button
var _delete_button: Button
var _status: Label
var _confirm: ConfirmationDialog
var _card_group := ButtonGroup.new()


func _ready() -> void:
	theme = UiStyle.make_theme()
	MusicPlayer.play_title()
	_build()
	_reload()
	UiStyle.apply_ui_scale(self)


func _draw() -> void:
	UiStyle.draw_background(self, size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and _selected != -1:
		_play()


func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	# Márgenes fijos: el contenido se adapta a la ventana (antes la lista se salía por abajo).
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40.0
	root.offset_right = -40.0
	root.offset_top = 24.0
	root.offset_bottom = -24.0

	var logo := GameLogo.new()
	logo.logo_scale = 0.5
	logo.custom_minimum_size = Vector2(0, 130)
	root.add_child(logo)
	var subtitle := UiStyle.label("Un ARPG oscuro. Como tu código en producción.", 18, UiStyle.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	# Lista de personajes.
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(560, 0)
	body.add_child(list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	list_panel.add_child(list_box)
	list_box.add_child(UiStyle.label("Personajes", 22, UiStyle.ACCENT))
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list)
	_empty_label = UiStyle.label("No hay personajes. Ni commits.\nCrea uno para empezar.", 16, UiStyle.MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_box.add_child(_empty_label)
	var list_buttons := HBoxContainer.new()
	list_buttons.add_theme_constant_override("separation", 10)
	list_box.add_child(list_buttons)
	list_buttons.add_child(UiStyle.button("Nuevo personaje", _new_character, 200))
	_delete_button = UiStyle.button("Borrar", _ask_delete, 120)
	list_buttons.add_child(_delete_button)

	# Detalle del personaje seleccionado.
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(380, 0)
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 12)
	detail_panel.add_child(detail_box)
	_preview = AppearancePreview.new()
	_preview.animated = true
	_preview.custom_minimum_size = Vector2(0, 240)
	detail_box.add_child(_preview)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail)
	_play_button = UiStyle.button("Jugar", _play)
	_play_button.custom_minimum_size.y = 52
	_play_button.add_theme_font_size_override("font_size", 22)
	detail_box.add_child(_play_button)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 20)
	root.add_child(footer)
	_status = UiStyle.label("", 16, UiStyle.DANGER)
	footer.add_child(_status)
	var mute := UiStyle.button("Música: no" if MusicPlayer.muted else "Música: sí", func() -> void: pass, 140)
	mute.pressed.connect(func() -> void: mute.text = "Música: no" if MusicPlayer.toggle_mute() else "Música: sí")
	footer.add_child(mute)
	footer.add_child(UiStyle.button("Salir", func() -> void: get_tree().quit(), 140))

	_confirm = ConfirmationDialog.new()
	_confirm.title = "Borrar personaje"
	_confirm.ok_button_text = "Borrar para siempre"
	_confirm.cancel_button_text = "Mejor no"
	_confirm.confirmed.connect(_delete_selected)
	add_child(_confirm)


func _reload() -> void:
	_saves = CharacterSaves.list_all()
	for child in _list.get_children():
		_list.remove_child(child)  # ya, no al final del frame: _select() usa los índices
		child.queue_free()
	for i in _saves.size():
		_list.add_child(_make_card(i))
	_empty_label.visible = _saves.is_empty()
	_scroll.visible = not _saves.is_empty()
	_select(0 if not _saves.is_empty() else -1)


func _make_card(index: int) -> Button:
	var data := _saves[index]
	var card := Button.new()
	card.toggle_mode = true
	card.button_group = _card_group
	card.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	card.pressed.connect(_select.bind(index))
	card.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.double_click and mb.button_index == MOUSE_BUTTON_LEFT:
			_select(index)
			_play())

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	var class_def := GameData.get_class_def(StringName(data.get("class_id", "")))
	var stripe := ColorRect.new()
	stripe.color = Color(class_def.get("color", "d9a441"))
	stripe.custom_minimum_size = Vector2(5, 0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stripe)
	var portrait := CharacterPortrait.new()
	portrait.custom_minimum_size = Vector2(66, 66)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.ring_color = stripe.color
	portrait.appearance = CharacterAppearance.sanitize(data.get("appearance", {}))
	row.add_child(portrait)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(texts)
	texts.add_child(UiStyle.label(data.get("name", "?"), 20, UiStyle.ACCENT))
	texts.add_child(UiStyle.label(_class_line(data), 14))
	texts.add_child(UiStyle.label("Jugado " + UiStyle.relative_time(int(data.get("last_played", 0))), 12, UiStyle.MUTED))
	return card


func _class_line(data: Dictionary) -> String:
	var class_def := GameData.get_class_def(StringName(data.get("class_id", "")))
	var line := "Nivel %d · %s" % [int(data.get("level", 1)), class_def.get("name", data.get("class_id", "?"))]
	for a in class_def.get("ascendancies", []):
		if a["id"] == data.get("ascendancy_id", ""):
			line += " · " + a["name"]
	return line


func _select(index: int) -> void:
	_selected = index
	_play_button.disabled = index == -1
	_delete_button.disabled = index == -1
	_preview.visible = index != -1
	if index == -1:
		_detail.text = "[center][color=#8a8293]Selecciona o crea un personaje.[/color][/center]"
		return
	var card := _list.get_child(index) as Button
	if card:
		card.button_pressed = true  # así el ButtonGroup suelta los demás
	var data := _saves[index]
	_preview.appearance = CharacterAppearance.sanitize(data.get("appearance", {}))
	var class_def := GameData.get_class_def(StringName(data.get("class_id", "")))
	_preview.glow_color = Color(class_def.get("color", "d9a441"))
	_detail.text = "[center][font_size=26][color=#d9a441]%s[/color][/font_size]\n%s\n\n[color=#8a8293]%s[/color]\n\n[color=#8a8293]Tiempo jugado:[/color] %s\n[color=#8a8293]Última partida:[/color] %s[/center]" % [
		data.get("name", "?"), _class_line(data), class_def.get("description", ""),
		UiStyle.play_time(float(data.get("play_time", 0.0))), UiStyle.relative_time(int(data.get("last_played", 0)))]


func _play() -> void:
	if _selected == -1:
		return
	var c := GameData.load_character(_saves[_selected]["id"])
	if c == null:
		_status.text = "No se pudo cargar el personaje. Revisa la consola."
		return
	GameData.current_character = c
	get_tree().change_scene_to_file(GameData.WORLD_SCENE)


func _new_character() -> void:
	get_tree().change_scene_to_file(GameData.CREATION_SCENE)


func _ask_delete() -> void:
	if _selected == -1:
		return
	_confirm.dialog_text = "¿Borrar a %s para siempre?\nEsto no tiene git revert." % _saves[_selected]["name"]
	_confirm.popup_centered()


func _delete_selected() -> void:
	CharacterSaves.delete(_saves[_selected]["id"])
	_reload()
