class_name TutorialPanel
extends PanelContainer
## Tutorial guiado con sarcasmo. Cada paso tiene una condición (por id) que se
## comprueba sola; el progreso se guarda en las banderas del personaje.
## Los eventos (matar, hablar, usar una poción...) llegan por notify().

signal step_completed(text: String)

const DATA_PATH := "res://data/tutorial.json"
const KILLS_NEEDED := 10
const CHECK_INTERVAL := 0.25

var character: CharacterData
var player: Player
var camp: Camp
## Oculto temporalmente (otro panel ocupa su sitio); el progreso sigue.
var suppressed := false:
	set(value):
		if value == suppressed:
			return
		suppressed = value
		if character and not is_finished():
			_refresh()
		elif value:
			visible = false

var _title := ""
var _steps: Array = []
var _done_text := ""
var _events := {}
var _check_timer := 0.0
var _header: Label
var _text: RichTextLabel


func _ready() -> void:
	var style := UiStyle.panel_style()
	style.border_color = UiStyle.ACCENT.darkened(0.3)
	add_theme_stylebox_override("panel", style)
	theme = UiStyle.make_theme()
	custom_minimum_size.x = 400
	var data = DataLoader.load_json(DATA_PATH)
	if data is Dictionary:
		_title = data.get("title", "Tutorial")
		_steps = data.get("steps", [])
		_done_text = data.get("done", "")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	_header = UiStyle.label("", 14, UiStyle.ACCENT)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)
	var skip := Button.new()
	skip.text = "Saltar"
	skip.tooltip_text = "Saltar el tutorial. Valiente. O temerario."
	skip.focus_mode = Control.FOCUS_NONE
	skip.pressed.connect(skip_all)
	top.add_child(skip)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size.x = 380
	box.add_child(_text)


func setup(p_character: CharacterData, p_player: Player, p_camp: Camp) -> void:
	character = p_character
	player = p_player
	camp = p_camp
	_refresh()


func current_step() -> int:
	return int(character.flags.get("tutorial_step", 0))


func is_finished() -> bool:
	return current_step() >= _steps.size()


func notify(event: String) -> void:
	_events[event] = int(_events.get(event, 0)) + 1


func skip_all() -> void:
	character.flags["tutorial_step"] = _steps.size()
	character.flags["tutorial_seen_done"] = true
	visible = false


func _process(delta: float) -> void:
	if character == null or is_finished():
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if _condition(_steps[current_step()]["id"]):
		character.flags["tutorial_step"] = current_step() + 1
		_events.clear()
		step_completed.emit("Paso completado." if not is_finished() else _done_text)
		_refresh()
	elif _steps[current_step()]["id"] == "kill":
		_refresh()  # muestra el contador


func _refresh() -> void:
	if is_finished():
		visible = not character.flags.has("tutorial_seen_done") and not suppressed
		_header.text = _title
		_text.text = "[color=#6fb36b]%s[/color]" % _done_text
		if visible:
			character.flags["tutorial_seen_done"] = true
			get_tree().create_timer(10.0).timeout.connect(func() -> void: visible = false)
		return
	visible = not suppressed
	var step: Dictionary = _steps[current_step()]
	_header.text = "%s  ·  %d / %d" % [_title, current_step() + 1, _steps.size()]
	var text: String = step["text"]
	if step["id"] == "kill":
		text += "  [color=#d9a441](%d / %d)[/color]" % [mini(int(_events.get("kill", 0)), KILLS_NEEDED), KILLS_NEEDED]
	_text.text = text


func _condition(step_id: String) -> bool:
	match step_id:
		"move":
			return player.global_position.distance_to(camp.spawn_point) > 120.0
		"talk_ada":
			return character.flags.has("talked_ada")
		"install_ram":
			for board in character.inventory.boards:
				if board and board.rams.any(func(r) -> bool: return r != null):
					return true
			return false
		"kevin":
			return character.flags.has("talked_kevin")
		"leave_camp":
			return not camp.contains(player.global_position)
		"use_skill":
			return _events.has("skill_used")
		"kill":
			return int(_events.get("kill", 0)) >= KILLS_NEEDED
		"flask":
			return _events.has("flask_used")
		"loot":
			return _events.has("picked_up")
		"equip":
			return _events.has("equipped")
		"passives":
			return character.passives.spent_points() > 0
	return true  # paso desconocido: no bloquear
