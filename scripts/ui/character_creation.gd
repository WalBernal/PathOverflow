class_name CharacterCreation
extends Control
## Creador de personaje: clase, apariencia y nombre. Al confirmar se guarda y
## se entra al juego directamente (empezando en la zona tutorial).

const RANDOM_NAMES := [
	"Segfault", "NullPointer", "Bobby Tables", "Sudo", "Deadlock", "Hotfix", "Legacy",
	"Pato de Goma", "Chmod 777", "Lorem Ipsum", "Tabulador", "Exiliado404", "Commitero",
	"Stack Smasher", "Regexorcista", "Async Await", "Kernel Sanders", "Monolito", "Cron Job",
]
const FACINGS := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
const ATTRIBUTES := [["strength", "FUE", Color("c84b4b")], ["dexterity", "DES", Color("5cb85c")],
	["intelligence", "INT", Color("4b8bd6")]]
const ATTRIBUTE_MAX := 40.0
const DIFFICULTY_NAMES := ["", "Amable (para estándares de producción)", "Media: lee los tooltips", "Alta: vive en el borde del stack"]
const SNIPPETS := ["git init personaje", "new Exiliado()", "chmod +x heroe.sh", "// valores por defecto, como tú",
	"npm install valor", "assert(vivo)", "CREATE TABLE heroe (...)", "docker build -t exiliado ."]

var _class_index := 0
var _appearance := CharacterAppearance.default()
var _facing_index := 0
var _rng := RandomNumberGenerator.new()
var _existing_names: Array = []
var _time := 0.0
var _floaters: Array[Dictionary] = []

var _class_buttons: Array[Button] = []
var _class_title: Label
var _class_info: RichTextLabel
var _attribute_bars: Control
var _skills_box: VBoxContainer
var _preview: AppearancePreview
var _face: CharacterPortrait
var _option_labels := {}      # clave -> Label del valor (complexión, peinado)
var _swatch_rows := {}        # clave -> Array[Button]
var _name_edit: LineEdit
var _error: Label
var _create_button: Button


func _ready() -> void:
	theme = UiStyle.make_theme()
	_rng.randomize()
	MusicPlayer.play_title()
	for data in CharacterSaves.list_all():
		_existing_names.append(data.get("name", ""))
	_build()
	_select_class(0)
	_refresh_appearance()
	_name_edit.grab_focus()
	for k in 10:
		_floaters.append(_new_floater(true))


func _process(delta: float) -> void:
	_time += delta
	for i in _floaters.size():
		_floaters[i]["y"] -= _floaters[i]["speed"] * delta
		if _floaters[i]["y"] < -20.0:
			_floaters[i] = _new_floater(false)
	queue_redraw()


func _new_floater(anywhere: bool) -> Dictionary:
	var binary := _rng.randf() < 0.6
	var text: String
	if binary:
		text = ""
		for k in _rng.randi_range(4, 8):
			text += "1" if _rng.randf() < 0.5 else "0"
	else:
		text = SNIPPETS[_rng.randi_range(0, SNIPPETS.size() - 1)]
	return {"text": text, "x": _rng.randf_range(10.0, maxf(size.x - 260.0, 20.0)),
		"y": _rng.randf_range(0.0, size.y) if anywhere else size.y + 10.0,
		"speed": _rng.randf_range(10.0, 26.0), "alpha": _rng.randf_range(0.05, 0.14), "binary": binary}


func _draw() -> void:
	UiStyle.draw_background(self, size)
	var font := get_theme_default_font()
	for f in _floaters:
		var color := Color(0.25, 0.95, 0.45, f["alpha"]) if f["binary"] else Color(0.85, 0.8, 0.6, f["alpha"])
		draw_string(font, Vector2(f["x"], f["y"]), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_back()


func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	var logo := GameLogo.new()
	logo.logo_scale = 0.3
	logo.custom_minimum_size = Vector2(300, 84)
	header.add_child(logo)
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(titles)
	titles.add_child(UiStyle.label("Nuevo exiliado", 36, UiStyle.ACCENT))
	titles.add_child(UiStyle.label("$ git init personaje  —  elige clase, cara y un nombre que no dé vergüenza en los logs", 15, UiStyle.MUTED))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# --- Clase ---
	var class_panel := PanelContainer.new()
	class_panel.custom_minimum_size = Vector2(470, 0)
	columns.add_child(class_panel)
	var class_box := VBoxContainer.new()
	class_box.add_theme_constant_override("separation", 6)
	class_panel.add_child(class_box)
	class_box.add_child(UiStyle.label("Clase", 22, UiStyle.ACCENT))
	var group := ButtonGroup.new()
	for i in GameData.classes.size():
		var c: Dictionary = GameData.classes[i]
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "   " + c["name"]
		b.custom_minimum_size.y = 34
		b.pressed.connect(_select_class.bind(i))
		var stripe := ColorRect.new()
		stripe.color = Color(c.get("color", "d9a441"))
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.position = Vector2(4, 6)
		stripe.size = Vector2(6, 22)
		b.add_child(stripe)
		class_box.add_child(b)
		_class_buttons.append(b)
	_attribute_bars = Control.new()
	_attribute_bars.custom_minimum_size = Vector2(0, 84)
	_attribute_bars.draw.connect(_draw_attribute_bars)
	class_box.add_child(_attribute_bars)
	var info_scroll := ScrollContainer.new()
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	class_box.add_child(info_scroll)
	_class_info = RichTextLabel.new()
	_class_info.bbcode_enabled = true
	_class_info.fit_content = true
	_class_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.add_child(_class_info)

	# --- Vista previa + habilidades iniciales ---
	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_panel)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 8)
	preview_panel.add_child(preview_box)
	_class_title = UiStyle.label("", 30, UiStyle.ACCENT)
	_class_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(_class_title)
	_preview = AppearancePreview.new()
	_preview.animated = true
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_child(_preview)
	var rotate_row := HBoxContainer.new()
	rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rotate_row.add_theme_constant_override("separation", 12)
	preview_box.add_child(rotate_row)
	rotate_row.add_child(UiStyle.button("<", _rotate.bind(-1), 48))
	rotate_row.add_child(UiStyle.label("Girar", 14, UiStyle.MUTED))
	rotate_row.add_child(UiStyle.button(">", _rotate.bind(1), 48))
	preview_box.add_child(UiStyle.label("Placas base iniciales", 18, UiStyle.ACCENT))
	_skills_box = VBoxContainer.new()
	_skills_box.add_theme_constant_override("separation", 6)
	preview_box.add_child(_skills_box)

	# --- Apariencia ---
	var look_panel := PanelContainer.new()
	look_panel.custom_minimum_size = Vector2(430, 0)
	columns.add_child(look_panel)
	var look_box := VBoxContainer.new()
	look_box.add_theme_constant_override("separation", 10)
	look_panel.add_child(look_box)
	# Cabecera con un retrato de cerca (para ver ojos, barba y accesorios).
	var look_top := HBoxContainer.new()
	look_top.add_theme_constant_override("separation", 12)
	look_box.add_child(look_top)
	var look_titles := VBoxContainer.new()
	look_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	look_titles.alignment = BoxContainer.ALIGNMENT_CENTER
	look_top.add_child(look_titles)
	look_titles.add_child(UiStyle.label("Apariencia", 22, UiStyle.ACCENT))
	var hint := UiStyle.label("No da stats. Es puramente cosmética,\ncomo los comentarios del código.", 12, UiStyle.MUTED)
	look_titles.add_child(hint)
	look_titles.add_child(UiStyle.button("Apariencia aleatoria", _randomize_appearance))
	_face = CharacterPortrait.new()
	_face.custom_minimum_size = Vector2(118, 118)
	look_top.add_child(_face)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	look_box.add_child(scroll)
	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 6)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options)
	options.add_child(_option_row("Complexión", "body", CharacterAppearance.BODY_NAMES))
	options.add_child(_option_row("Estatura", "height", CharacterAppearance.HEIGHT_NAMES))
	options.add_child(_option_row("Peinado", "hair", CharacterAppearance.HAIR_NAMES))
	options.add_child(_option_row("Barba", "beard", CharacterAppearance.BEARD_NAMES))
	options.add_child(_option_row("Accesorio", "accessory", CharacterAppearance.ACCESSORY_NAMES))
	for entry in [["Tono de piel", "skin_tone", CharacterAppearance.SKIN_TONES],
			["Color de pelo", "hair_color", CharacterAppearance.HAIR_COLORS],
			["Color de ojos", "eye_color", CharacterAppearance.EYE_COLORS],
			["Color del atuendo", "outfit_color", CharacterAppearance.OUTFIT_COLORS],
			["Detalles (cinturón, zapatos, accesorio)", "accent_color", CharacterAppearance.ACCENT_COLORS]]:
		options.add_child(UiStyle.label(entry[0], 13, UiStyle.MUTED))
		options.add_child(_swatch_row(entry[1], entry[2]))

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
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 5)
	row.add_theme_constant_override("v_separation", 5)
	var buttons: Array[Button] = []
	for hex in colors:
		var b := Button.new()
		b.custom_minimum_size = Vector2(30, 26)
		b.focus_mode = Control.FOCUS_NONE
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
	var class_color := Color(c.get("color", "d9a441"))
	_class_title.text = c["name"]
	_class_title.add_theme_color_override("font_color", class_color)
	_preview.glow_color = class_color
	_attribute_bars.queue_redraw()

	var asc_names := PackedStringArray()
	for a in c.get("ascendancies", []):
		asc_names.append(a["name"])
	var weapon_name := "—"
	if GameData.items.bases.has(c.get("starter_weapon", "")):
		weapon_name = GameData.items.bases[c["starter_weapon"]]["name"]
	var difficulty := clampi(int(c.get("difficulty", 2)), 1, 3)
	var stars := "★".repeat(difficulty) + "☆".repeat(3 - difficulty)
	_class_info.text = "[i][color=#a08f6a]%s[/color][/i]\n\n[color=#8a8293]Estilo de juego:[/color] %s\n[color=#8a8293]Dificultad:[/color] [color=#d9a441]%s[/color] %s\n[color=#8a8293]Arma inicial:[/color] %s\n[color=#8a8293]Ascendencias:[/color] %s" % [
		c["description"], c.get("playstyle", "—"), stars, DIFFICULTY_NAMES[difficulty], weapon_name, ", ".join(asc_names)]

	for child in _skills_box.get_children():
		child.queue_free()
	for skill_id in c.get("starter_skills", []):
		if GameData.items.skills.skills.has(skill_id):
			_skills_box.add_child(_skill_card(GameData.items.skills.skills[skill_id]))


func _skill_card(def: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiStyle.PANEL_LIGHT
	style.border_color = UiStyle.BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.draw.connect(func() -> void: SkillIcon.draw(icon, Rect2(Vector2.ZERO, icon.size), def))
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	var tags := PackedStringArray()
	for tag: String in def.get("tags", []):
		tags.append(SkillTags.display_name(tag))
	texts.add_child(UiStyle.label("%s   [%s]" % [def.get("name", "?"), ", ".join(tags)], 16, UiStyle.ACCENT))
	var desc := UiStyle.label(def.get("description", ""), 13, UiStyle.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(desc)
	return panel


func _draw_attribute_bars() -> void:
	var c: Dictionary = GameData.classes[_class_index]
	var attrs: Dictionary = c["base_attributes"]
	var font := get_theme_default_font()
	var width := _attribute_bars.size.x
	for k in ATTRIBUTES.size():
		var key: String = ATTRIBUTES[k][0]
		var color: Color = ATTRIBUTES[k][2]
		var value := float(attrs.get(key, 0))
		var y := 8.0 + k * 26.0
		_attribute_bars.draw_string(font, Vector2(0, y + 14), ATTRIBUTES[k][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		var bar := Rect2(Vector2(44, y), Vector2(width - 90, 16))
		_attribute_bars.draw_rect(bar, Color("0d0b10"))
		_attribute_bars.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(value / ATTRIBUTE_MAX, 0.0, 1.0), bar.size.y)), Color(color, 0.85))
		_attribute_bars.draw_rect(bar, UiStyle.BORDER, false, 1.0)
		_attribute_bars.draw_string(font, Vector2(width - 38, y + 14), str(int(value)), HORIZONTAL_ALIGNMENT_RIGHT, 38, 14, UiStyle.TEXT)


func _cycle(key: String, count: int, step: int) -> void:
	if key == "height":
		var i := posmod(CharacterAppearance.height_index(_appearance) + step, count)
		_appearance["height"] = CharacterAppearance.HEIGHT_VALUES[i]
	else:
		_appearance[key] = posmod(int(_appearance.get(key, 0)) + step, count)
	_refresh_appearance()


func _rotate(step: int) -> void:
	_facing_index = posmod(_facing_index + step, FACINGS.size())
	_preview.facing = FACINGS[_facing_index]


func _randomize_appearance() -> void:
	_appearance = CharacterAppearance.random(_rng)
	_refresh_appearance()


func _refresh_appearance() -> void:
	_appearance = CharacterAppearance.sanitize(_appearance)
	_preview.appearance = _appearance.duplicate()
	_face.appearance = _appearance.duplicate()
	_face.ring_color = Color(GameData.classes[_class_index].get("color", "d9a441"))
	_option_labels["body"].text = CharacterAppearance.BODY_NAMES[_appearance["body"]]
	_option_labels["height"].text = CharacterAppearance.HEIGHT_NAMES[CharacterAppearance.height_index(_appearance)]
	_option_labels["hair"].text = CharacterAppearance.HAIR_NAMES[_appearance["hair"]]
	_option_labels["beard"].text = CharacterAppearance.BEARD_NAMES[_appearance["beard"]]
	_option_labels["accessory"].text = CharacterAppearance.ACCESSORY_NAMES[_appearance["accessory"]]
	for key in _swatch_rows:
		for b: Button in _swatch_rows[key]:
			var hex := b.tooltip_text.substr(1)
			var selected: bool = hex == String(_appearance.get(key, ""))
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
