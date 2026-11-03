class_name MainMenu
extends Control
## Pantalla de inicio: lista de personajes guardados, jugar, crear y borrar,
## y el espacio de guardado activo.

const CARD_HEIGHT := 84.0
## Por debajo de este alto (lienzo / escala de interfaz) el menú se compacta (T135).
const COMPACT_HEIGHT := 760.0
## Pose de lucimiento de cada clase sobre su pedestal (T96): [acción, arma].
const CLASS_POSES := {
	"guerrero": ["attack", "mace"], "duelista": ["attack", "sword"], "exploradora": ["shoot", "dagger"],
	"hacker": ["cast", ""], "hechicero": ["cast", ""], "templario": ["cast", ""], "full_stack": ["attack", "axe"],
}

var _saves: Array[Dictionary] = []
var _selected := -1
var _scroll: ScrollContainer
var _list: VBoxContainer
var _empty_label: Label
var _preview: AppearancePreview
var _student: StudentPreview
var _detail: RichTextLabel
var _play_button: Button
var _delete_button: Button
var _status: Label
var _confirm: ConfirmationDialog
var _quit_dialog: ConfirmationDialog
var _card_group := ButtonGroup.new()
## Piezas que entran escalonadas al abrir el menú (T184).
var _entrance: Array[Control] = []
var _glow_tween: Tween


func _ready() -> void:
	theme = UiStyle.make_theme()
	MusicPlayer.play_title()
	var backdrop := MenuBackdrop.new()   # paquetes por la rejilla (T184)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_reload()
	UiStyle.apply_ui_scale(self)
	_enter()


## Entrada escalonada (T184): logo, lista, detalle y pie, uno tras otro, cuando el
## barrido ya se está retirando. Esperan tapados un fotograma a tener su tamaño.
func _enter() -> void:
	for c in _entrance:
		c.modulate.a = 0.0
	await get_tree().process_frame
	UiMotion.stagger_in(_entrance)


func _draw() -> void:
	UiStyle.draw_background(self, size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## Botón Atrás de Android (T141): preguntar antes de salir.
func ask_quit() -> void:
	if _quit_dialog == null:
		_quit_dialog = GameData.quit_dialog(self)
	GameUI.show_popup(_quit_dialog)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and _selected != -1:
		_play()


static func _closest_scale(v: float) -> float:
	var best: float = GameUI.UI_SCALES[0]
	for s in GameUI.UI_SCALES:
		if absf(float(s) - v) < absf(best - v):
			best = s
	return best


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
	var header := HBoxContainer.new()
	list_box.add_child(header)
	var title := UiStyle.label("Personajes", 22, UiStyle.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	# Espacios de guardado: cada uno con sus personajes y su alijo.
	var slot_button := UiStyle.button("", func() -> void: pass, 170)
	slot_button.tooltip_text = "Cada espacio de guardado tiene sus propios personajes y su propio alijo."
	var refresh_slot := func() -> void:
		slot_button.text = "Espacio %d de %d" % [CharacterSaves.slot(), CharacterSaves.SLOTS]
	slot_button.pressed.connect(func() -> void:
		CharacterSaves.set_slot(CharacterSaves.slot() % CharacterSaves.SLOTS + 1)
		refresh_slot.call()
		_reload(true))
	refresh_slot.call()
	header.add_child(slot_button)
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
	# El oficinista (como en el prólogo) y, a su lado, el alumno en el servidor con lo que
	# lleva puesto (T180).
	var figures := HBoxContainer.new()
	figures.add_theme_constant_override("separation", 0)
	detail_box.add_child(figures)
	_preview = AppearancePreview.new()
	_preview.animated = true
	_preview.use_sprites = true   # el mismo personaje por capas que en el juego (T102b)
	_preview.auto_turn = true     # gira despacio y se pone de frente para posar (T185)
	_preview.custom_minimum_size = Vector2(0, 240)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	figures.add_child(_preview)
	_student = StudentPreview.new()
	_student.custom_minimum_size = Vector2(130, 0)
	figures.add_child(_student)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	# Se desplaza en su hueco (T135): con fit_content, en el celular a 140 % empujaba
	# «Jugar» y los botones de abajo fuera de la pantalla.
	_detail.scroll_active = true
	_detail.custom_minimum_size.y = 40
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
	# Tamaño de interfaz (también en la pausa): se aplica al volver a cargar el menú.
	var ui_size := UiStyle.button("", func() -> void: pass, 190)
	var refresh_size := func() -> void:
		ui_size.text = "Interfaz: %d %%" % roundi(GameUI.ui_scale() * 100.0)
	ui_size.tooltip_text = "Agranda o achica los menús, el HUD y los textos (el mundo se ve igual)."
	ui_size.pressed.connect(func() -> void:
		var k := GameUI.UI_SCALES.find(_closest_scale(GameUI.ui_scale()))
		GameSettings.set_value("interface", "scale", GameUI.UI_SCALES[(k + 1) % GameUI.UI_SCALES.size()])
		ScreenTransition.change_scene(get_tree(), scene_file_path))   # con el barrido, no un corte (T184)
	refresh_size.call()
	footer.add_child(ui_size)
	footer.add_child(UiStyle.button("Salir", func() -> void: get_tree().quit(), 140))

	# Pantalla baja (el celular con la interfaz grande): logo y figura más chicos y sin subtítulo.
	var compact := func() -> void:
		var low := size.y < COMPACT_HEIGHT
		logo.custom_minimum_size.y = 84 if low else 130
		logo.logo_scale = 0.34 if low else 0.5
		subtitle.visible = not low
		_preview.custom_minimum_size.y = 150 if low else 240
		logo.queue_redraw()
	resized.connect(compact)
	compact.call()
	_entrance.assign([logo, subtitle, list_panel, detail_panel, footer])

	_confirm = ConfirmationDialog.new()
	_confirm.title = "Borrar personaje"
	_confirm.ok_button_text = "Borrar para siempre"
	_confirm.cancel_button_text = "Mejor no"
	_confirm.confirmed.connect(_delete_selected)
	add_child(_confirm)


## `animate`: al cambiar de espacio o borrar, las tarjetas entran escalonadas (T184).
func _reload(animate := false) -> void:
	_saves = CharacterSaves.list_all()
	_selected = -1   # la lista es otra: la primera tarjeta cuenta como un cambio
	for child in _list.get_children():
		_list.remove_child(child)  # ya, no al final del frame: _select() usa los índices
		child.queue_free()
	for i in _saves.size():
		_list.add_child(_make_card(i))
	_empty_label.visible = _saves.is_empty()
	_scroll.visible = not _saves.is_empty()
	_select(0 if not _saves.is_empty() else -1)
	if animate:
		var cards: Array = _list.get_children()
		UiMotion.stagger_in(cards if not cards.is_empty() else [_empty_label])


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
	UiStyle.juicy(card)   # rebota y suena como los demás botones (T184)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	var class_def := GameData.get_class_def(StringName(data.get("class_id", "")))
	var stripe := ColorRect.new()
	stripe.color = Color(class_def.get("color", "2dd4bf"))
	stripe.custom_minimum_size = Vector2(5, 0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stripe)
	var portrait := CharacterPortrait.new()
	portrait.custom_minimum_size = Vector2(66, 66)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.ring_color = stripe.color
	portrait.appearance = CharacterAppearance.sanitize(data.get("appearance", {}))
	portrait.still = true   # solo se anima la tarjeta elegida (T186)
	portrait.name = "Portrait"
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
	var changed := index != _selected
	_selected = index
	_play_button.disabled = index == -1
	_delete_button.disabled = index == -1
	_preview.visible = index != -1
	_student.visible = index != -1
	if index == -1:
		_detail.text = "[center][color=#8b949e]Selecciona o crea un personaje.[/color][/center]"
		return
	var card := _list.get_child(index) as Button
	if card:
		card.button_pressed = true  # así el ButtonGroup suelta los demás
	for k in _list.get_child_count():   # T186: solo respira el retrato elegido
		var p := _list.get_child(k).find_child("Portrait", true, false) as CharacterPortrait
		if p:
			p.still = k != index
	var data := _saves[index]
	_preview.appearance = CharacterAppearance.with_gear(CharacterAppearance.sanitize(data.get("appearance", {})), String(data.get("class_id", "")))
	_student.equipped = StudentHero.equipped_of_save(data)
	# Con el arma que lleva (T177): el tipo solo dice que hay arma; el dibujo, su base.
	_student.weapon = "sword" if String(_student.equipped.get("weapon", "")) != "" else ""
	_student.appearance = CharacterAppearance.sanitize(data.get("appearance", {}))
	var class_def := GameData.get_class_def(StringName(data.get("class_id", "")))
	var class_color := Color(class_def.get("color", "2dd4bf"))
	var look: Array = CLASS_POSES.get(String(data.get("class_id", "")), ["attack", "sword"])
	_preview.action = look[0]
	_preview.weapon = look[1]
	_detail.text = "[center][font_size=26][color=#2dd4bf]%s[/color][/font_size]\n%s\n\n[color=#8b949e]%s[/color]\n\n[color=#8b949e]Tiempo jugado:[/color] %s\n[color=#8b949e]Última partida:[/color] %s[/center]" % [
		data.get("name", "?"), _class_line(data), class_def.get("description", ""),
		UiStyle.play_time(float(data.get("play_time", 0.0))), UiStyle.relative_time(int(data.get("last_played", 0)))]
	if not changed or not is_inside_tree():
		_preview.glow_color = class_color
		return
	# T184: el cambio se ve. Destello en el pedestal, su color pasa al de la clase con
	# un fundido y el detalle se escribe a máquina.
	_preview.flash()
	_student.modulate.a = 0.0
	_student.create_tween().tween_property(_student, "modulate:a", 1.0, 0.25).set_delay(0.08)
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(_preview, "glow_color", class_color, 0.35)
	_detail.visible_ratio = 0.0
	_detail.create_tween().tween_property(_detail, "visible_ratio", 1.0, UiMotion.typewriter_time(_detail.get_total_character_count()))


func _play() -> void:
	if _selected == -1:
		return
	var c := GameData.load_character(_saves[_selected]["id"])
	if c == null:
		_status.text = "No se pudo cargar el personaje. Revisa la consola."
		return
	GameData.current_character = c
	ScreenTransition.change_scene(get_tree(), GameData.WORLD_SCENE)


func _new_character() -> void:
	ScreenTransition.change_scene(get_tree(), GameData.CREATION_SCENE)


func _ask_delete() -> void:
	if _selected == -1:
		return
	_confirm.dialog_text = "¿Borrar a %s para siempre?\nEsto no tiene git revert." % _saves[_selected]["name"]
	_confirm.popup_centered()


func _delete_selected() -> void:
	CharacterSaves.delete(_saves[_selected]["id"])
	_reload(true)
