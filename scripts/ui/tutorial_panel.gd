class_name TutorialPanel
extends PanelContainer
## Tutorial guiado con sarcasmo. Cada paso tiene una condición (por id) que se
## comprueba sola; el progreso se guarda en las banderas del personaje.
## Los eventos (matar, hablar, usar una poción...) llegan por notify().

signal step_completed(text: String)

const DATA_PATH := "res://data/tutorial.json"
const CHECK_INTERVAL := 0.25

var character: CharacterData
var player: Player
## Zona actual (la pone GameUI al cambiar de zona).
var zone: Zone
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
## Dónde estaba el jugador al empezar el paso actual (para «muévete»).
var _step_origin := Vector2.INF
var _touch_was := false
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


func setup(p_character: CharacterData, p_player: Player) -> void:
	character = p_character
	player = p_player
	_migrate()
	_refresh()


## Personajes del tutorial antiguo (sin zona tutorial): siguen desde la parte
## del campamento, o lo dan por terminado si ya lo habían acabado. Versión 3: las
## pasivas pasaron al final (TutorialOrder).
func _migrate() -> void:
	if character.flags.has("tutorial_step") and not character.flags.has("tutorial_version"):
		var old := int(character.flags["tutorial_step"])
		character.flags["tutorial_step"] = _steps.size() if old >= 11 else _index_of("talk_ada")
	elif int(character.flags.get("tutorial_version", 0)) == 2 and character.flags.has("tutorial_step"):
		character.flags["tutorial_step"] = TutorialOrder.migrated_step(int(character.flags["tutorial_step"]), TutorialOrder.V2, _steps)
	character.flags["tutorial_version"] = 3


func _index_of(step_id: String) -> int:
	for i in _steps.size():
		if _steps[i]["id"] == step_id:
			return i
	return 0


func _needed() -> int:
	return int(_steps[current_step()].get("count", 1)) if not is_finished() else 1


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


## Botón táctil que señala el paso actual (Hud lo resalta), o "".
func touch_point() -> String:
	if character == null or is_finished() or not visible:
		return ""
	return String(_steps[current_step()].get("touch_point", ""))


func _process(delta: float) -> void:
	if character == null or is_finished():
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	if Touch.shown() != _touch_was:
		_touch_was = Touch.shown()
		_refresh()   # se pasó del ratón al dedo (o al revés): el otro texto
	if _condition(_steps[current_step()]["id"]):
		character.flags["tutorial_step"] = current_step() + 1
		_events.clear()
		_step_origin = Vector2.INF
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
	var text := Touch.text(step)   # con el dedo, su versión táctil (T138)
	if step["id"] == "kill":
		text += "  [color=#2dd4bf](%d / %d)[/color]" % [mini(int(_events.get("kill", 0)), _needed()), _needed()]
	_text.text = text


func _condition(step_id: String) -> bool:
	match step_id:
		"move":
			if _step_origin == Vector2.INF:
				_step_origin = player.global_position
			return player.global_position.distance_to(_step_origin) > 150.0
		"talk_ada":
			return character.flags.has("talked_ada")
		"install_ram":
			for board in character.inventory.boards:
				if board and board.rams.any(func(r) -> bool: return r != null):
					return true
			return false
		"kevin":
			return character.flags.has("talked_kevin")
		"reach_camp":   # del Sandbox solo se sale por el campamento: más allá, ya pasó por él
			return zone != null and zone.style != "sandbox"
		"leave_camp":   # cualquier zona de después del campamento (no solo el Bosque)
			return zone != null and zone.style != "sandbox" and zone.id != GameData.act.get("town", "campamento")
		"use_skill":
			return _events.has("skill_used")
		"kill":
			return int(_events.get("kill", 0)) >= _needed()
		"flask":
			return _events.has("flask_used")
		"loot":
			return _events.has("picked_up")
		"equip":
			return _events.has("equipped")
		"passives":
			return character.passives.spent_points() > 0
	return true  # paso desconocido: no bloquear
