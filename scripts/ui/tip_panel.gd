class_name TipPanel
extends PanelContainer
## Consejos de primera vez (data/tips.json): un aviso corto la primera vez que
## aparece una mecánica (esquiva, cargas, golpes pesados, terrenos y mecánicas de
## arena). Se guardan como vistos en las banderas del personaje (tip_seen_<id>) y
## se pueden desactivar en Pausa (settings.cfg: interface/tips).

const DATA_PATH := "res://data/tips.json"
const SHOW_TIME := 9.0
const CHECK_INTERVAL := 0.4

var character: CharacterData
var player: Player
var enemies: EnemyManager
var skills: SkillController

var _tips: Dictionary = {}
var _queue: Array[String] = []
var _showing := ""
var _time_left := 0.0
var _check := 0.0
var _title: Label
var _text: RichTextLabel


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "tips", true))


static func set_enabled(on: bool) -> void:
	GameSettings.set_value("interface", "tips", on)


func _init() -> void:
	var style := UiStyle.panel_style()
	style.border_color = Color("6fb3e0")
	add_theme_stylebox_override("panel", style)
	theme = UiStyle.make_theme()
	custom_minimum_size.x = 440
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	_title = UiStyle.label("", 15, Color("8ad0ff"))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var close := Button.new()
	close.text = "Entendido"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_hide_current)
	top.add_child(close)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size.x = 420
	box.add_child(_text)


func setup(p_character: CharacterData, p_player: Player, p_enemies: EnemyManager, p_skills: SkillController) -> void:
	character = p_character
	player = p_player
	enemies = p_enemies
	skills = p_skills
	var data = DataLoader.load_json(DATA_PATH)
	if data is Dictionary:
		_tips = data.get("tips", {})
	player.hit_taken.connect(func() -> void: show_tip("dodge"))
	character.charges_changed.connect(func() -> void:
		for t in Charges.TYPES:
			if int(character.charges[t]) > 0:
				show_tip("charges")
				return)


func has_seen(id: String) -> bool:
	return character != null and character.flags.has("tip_seen_" + id)


## Pone en cola un consejo si existe, no se ha visto y están activados.
func show_tip(id: String) -> void:
	if character == null or not _tips.has(id) or has_seen(id) or _queue.has(id) or _showing == id or not enabled():
		return
	character.flags["tip_seen_" + id] = true
	_queue.append(id)


func _process(delta: float) -> void:
	if character == null:
		return
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_INTERVAL
		_watch()
	if _showing != "":
		_time_left -= delta
		if _time_left <= 0.0:
			_hide_current()
	elif not _queue.is_empty():
		_show(_queue.pop_front())


## Lo que no llega por señal: golpes pesados a la vista, terrenos y mecánicas de arena.
func _watch() -> void:
	if enemies == null:
		return
	if not has_seen("heavy") and player:
		for i in enemies.count():
			if enemies.windups[i] > 0.0 and (enemies.traits[i] as Dictionary).get("heavy_on", false) \
					and enemies.positions[i].distance_to(player.global_position) < 700.0:
				show_tip("heavy")
				break
	for h in enemies.hazards:
		match String(h.get("kind", "")):
			"break": show_tip("arena_break")
			"safe_zones": show_tip("arena_safe")
	if not enemies._channels.is_empty():
		show_tip("arena_channel")
	if skills and not skills._terrains.is_empty():
		show_tip("terrain")
	if skills and not has_seen("trigger"):
		for i in SkillController.ACTIONS.size():
			if String(skills.profile(i).get("trigger", "")) != "":
				show_tip("trigger")
				break


func _show(id: String) -> void:
	_showing = id
	_time_left = SHOW_TIME
	_title.text = "Consejo · " + String(_tips[id].get("title", id))
	_text.text = Touch.text(_tips[id])   # con su versión para el dedo, si la tiene (T138)
	visible = true


func _hide_current() -> void:
	_showing = ""
	visible = false
