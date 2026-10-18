class_name CharacterCreation
extends Control
## Creador de personaje: clase, apariencia y nombre. Al confirmar se guarda y
## se entra al juego directamente.

const RANDOM_NAMES := [
	"Segfault", "NullPointer", "Bobby Tables", "Sudo", "Deadlock", "Hotfix", "Legacy",
	"Pato de Goma", "Chmod 777", "Lorem Ipsum", "Tabulador", "Exiliado404", "Commitero",
	"Stack Smasher", "Regexorcista", "Async Await", "Kernel Sanders", "Monolito", "Cron Job",
]
const FACINGS := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]

var _class_index := 0
var _appearance := CharacterAppearance.default()
var _facing_index := 0
var _rng := RandomNumberGenerator.new()
var _existing_names: Array = []

var _class_buttons: Array[Button] = []
var _class_info: RichTextLabel
var _preview: AppearancePreview
var _option_labels := {}      # clave -> Label del valor (complexión, peinado)
var _swatch_rows := {}        # clave -> Array[Button]
var _name_edit: LineEdit
var _error: Label
var _create_button: Button


func _ready() -> void:
	theme = UiStyle.make_theme()
	_rng.randomize()
	for data in CharacterSaves.list_all():
		_existing_names.append(data.get("name", ""))
	_build()
	_select_class(0)
	_refresh_appearance()
	_name_edit.grab_focus()


func _draw() -> void:
	UiStyle.draw_background(self, size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_back()


func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	root.add_child(UiStyle.label("Nuevo personaje", 40, UiStyle.ACCENT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# --- Clase ---
	var class_panel := PanelContainer.new()
	class_panel.custom_minimum_size = Vector2(440, 0)
	columns.add_child(class_panel)
	var class_box := VBoxContainer.new()
	class_box.add_theme_constant_override("separation", 8)
	class_panel.add_child(class_box)
	class_box.add_child(UiStyle.label("Clase", 22, UiStyle.ACCENT))
	var group := ButtonGroup.new()
	for i in GameData.classes.size():
		var c: Dictionary = GameData.classes[i]
		var attrs: Dictionary = c["base_attributes"]
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s      FUE %d · DES %d · INT %d" % [c["name"], attrs["strength"], attrs["dexterity"], attrs["intelligence"]]
		b.custom_minimum_size.y = 42
		b.pressed.connect(_select_class.bind(i))
		class_box.add_child(b)
		_class_buttons.append(b)
	_class_info = RichTextLabel.new()
	_class_info.bbcode_enabled = true
	_class_info.fit_content = true
	_class_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	class_box.add_child(_class_info)

	# --- Vista previa ---
	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_panel)
	var preview_box := VBoxContainer.new()
	preview_panel.add_child(preview_box)
	_preview = AppearancePreview.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_child(_preview)
	var rotate_row := HBoxContainer.new()
	rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rotate_row.add_theme_constant_override("separation", 12)
	preview_box.add_child(rotate_row)
	rotate_row.add_child(UiStyle.button("<", _rotate.bind(-1), 48))
	rotate_row.add_child(UiStyle.label("Girar", 14, UiStyle.MUTED))
	rotate_row.add_child(UiStyle.button(">", _rotate.bind(1), 48))

	# --- Apariencia ---
	var look_panel := PanelContainer.new()
	look_panel.custom_minimum_size = Vector2(440, 0)
	columns.add_child(look_panel)
	var look_box := VBoxContainer.new()
	look_box.add_theme_constant_override("separation", 10)
	look_panel.add_child(look_box)
	look_box.add_child(UiStyle.label("Apariencia", 22, UiStyle.ACCENT))
	look_box.add_child(_option_row("Complexión", "body", CharacterAppearance.BODY_NAMES))
	look_box.add_child(_option_row("Peinado", "hair", CharacterAppearance.HAIR_NAMES))
	look_box.add_child(UiStyle.label("Tono de piel", 14, UiStyle.MUTED))
	look_box.add_child(_swatch_row("skin_tone", CharacterAppearance.SKIN_TONES))
	look_box.add_child(UiStyle.label("Color de pelo", 14, UiStyle.MUTED))
	look_box.add_child(_swatch_row("hair_color", CharacterAppearance.HAIR_COLORS))
	look_box.add_child(UiStyle.label("Color del atuendo", 14, UiStyle.MUTED))
	look_box.add_child(_swatch_row("outfit_color", CharacterAppearance.OUTFIT_COLORS))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	look_box.add_child(spacer)
	look_box.add_child(UiStyle.button("Apariencia aleatoria", _randomize_appearance))

	# --- Nombre y confirmación ---
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	footer.add_child(UiStyle.button("Volver", _back, 120))
	footer.add_child(UiStyle.label("Nombre:", 18))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Cómo te recordarán los logs"
	_name_edit.max_length = CharacterSaves.NAME_MAX
	_name_edit.custom_minimum_size = Vector2(320, 44)
	_name_edit.text_changed.connect(func(_t: String) -> void: _validate())
	_name_edit.text_submitted.connect(func(_t: String) -> void: _create())
	footer.add_child(_name_edit)
	footer.add_child(UiStyle.button("Nombre aleatorio", _random_name))
	_error = UiStyle.label("", 15, UiStyle.DANGER)
	_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_error)
	_create_button = UiStyle.button("Crear personaje", _create, 220)
	_create_button.add_theme_font_size_override("font_size", 20)
	_create_button.custom_minimum_size.y = 48
	footer.add_child(_create_button)
	_validate()


func _option_row(title: String, key: String, names: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := UiStyle.label(title, 14, UiStyle.MUTED)
	label.custom_minimum_size.x = 110
	row.add_child(label)
	row.add_child(UiStyle.button("<", _cycle.bind(key, names.size(), -1), 40))
	var value := UiStyle.label("", 16)
	value.custom_minimum_size.x = 140
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value)
	row.add_child(UiStyle.button(">", _cycle.bind(key, names.size(), 1), 40))
	_option_labels[key] = value
	return row


func _swatch_row(key: String, colors: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var buttons: Array[Button] = []
	for hex in colors:
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 32)
		b.tooltip_text = "#" + hex
		b.pressed.connect(func() -> void:
			_appearance[key] = hex
			_refresh_appearance())
		row.add_child(b)
		buttons.append(b)
	_swatch_rows[key] = buttons
	return row


func _select_class(index: int) -> void:
	_class_index = index
	_class_buttons[index].button_pressed = true  # así el ButtonGroup suelta los demás
	var c: Dictionary = GameData.classes[index]
	var asc_names := PackedStringArray()
	for a in c.get("ascendancies", []):
		asc_names.append(a["name"])
	var weapon_name := "—"
	if GameData.items.bases.has(c.get("starter_weapon", "")):
		weapon_name = GameData.items.bases[c["starter_weapon"]]["name"]
	_class_info.text = "\n[font_size=24][color=#d9a441]%s[/color][/font_size]\n[i][color=#a08f6a]%s[/color][/i]\n\n[color=#8a8293]Arma inicial:[/color] %s\n[color=#8a8293]Ascendencias:[/color] %s" % [
		c["name"], c["description"], weapon_name, ", ".join(asc_names)]


func _cycle(key: String, count: int, step: int) -> void:
	_appearance[key] = posmod(int(_appearance[key]) + step, count)
	_refresh_appearance()


func _rotate(step: int) -> void:
	_facing_index = posmod(_facing_index + step, FACINGS.size())
	_preview.facing = FACINGS[_facing_index]


func _randomize_appearance() -> void:
	_appearance = CharacterAppearance.random(_rng)
	_refresh_appearance()


func _refresh_appearance() -> void:
	_preview.appearance = _appearance.duplicate()
	_option_labels["body"].text = CharacterAppearance.BODY_NAMES[_appearance["body"]]
	_option_labels["hair"].text = CharacterAppearance.HAIR_NAMES[_appearance["hair"]]
	for key in _swatch_rows:
		for b: Button in _swatch_rows[key]:
			var hex := b.tooltip_text.substr(1)
			var selected: bool = hex == _appearance[key]
			var style := StyleBoxFlat.new()
			style.bg_color = Color(hex)
			style.border_color = UiStyle.ACCENT if selected else UiStyle.BORDER
			style.set_border_width_all(3 if selected else 1)
			style.set_corner_radius_all(3)
			for state in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(state, style)


func _random_name() -> void:
	var options: Array = RANDOM_NAMES.filter(func(n: String) -> bool:
		return CharacterSaves.validate_name(n, _existing_names) == "")
	var picked: String = options[_rng.randi_range(0, options.size() - 1)] if not options.is_empty() \
		else "Exiliado %d" % _rng.randi_range(100, 999)
	_name_edit.text = picked
	_validate()


func _validate() -> bool:
	var problem := CharacterSaves.validate_name(_name_edit.text, _existing_names)
	# Sin escribir nada todavía, no hace falta regañar.
	_error.text = problem if _name_edit.text != "" else ""
	_create_button.disabled = problem != ""
	return problem == ""


func _create() -> void:
	if not _validate():
		return
	var class_id := StringName(GameData.classes[_class_index]["id"])
	GameData.current_character = GameData.create_character(_name_edit.text, class_id, _appearance)
	get_tree().change_scene_to_file(GameData.WORLD_SCENE)


func _back() -> void:
	get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE)
