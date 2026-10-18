class_name DialogueBox
extends PanelContainer
## Caja de diálogo con NPCs: retrato, nombre, texto que se escribe solo y
## opciones. Las opciones pueden depender de banderas del personaje y lanzar
## acciones (dar objetos, rellenar pociones...), que ejecuta World.

signal action_requested(action: Dictionary)
signal closed(npc_id: String)

const CHARS_PER_SECOND := 70.0
## Distancia al borde inferior de la pantalla (deja ver el HUD).
const BOTTOM_MARGIN := 125.0

var character: CharacterData
var npc: Dictionary = {}
var _dialogue: Dictionary = {}
var _portrait: AppearancePreview
var _name: Label
var _text: RichTextLabel
var _options: VBoxContainer
var _typing_tween: Tween


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	theme = UiStyle.make_theme()
	visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	_portrait = AppearancePreview.new()
	_portrait.custom_minimum_size = Vector2(110, 150)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # que no se estire con el texto
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size.x = 620
	row.add_child(col)
	_name = UiStyle.label("", 20, UiStyle.ACCENT)
	col.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(620, 60)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("normal_font_size", 16)
	col.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 4)
	col.add_child(_options)


func open(p_npc: Dictionary, dialogue: Dictionary) -> void:
	npc = p_npc
	_dialogue = dialogue
	_portrait.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
	_name.text = npc.get("name", "?")
	visible = true
	_portrait.queue_redraw.call_deferred()  # estaba oculto: forzar el dibujo
	_show_node(dialogue.get("start", ""))


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit(npc.get("id", ""))
	npc = {}


func _show_node(node_id: String) -> void:
	var nodes: Dictionary = _dialogue.get("nodes", {})
	if node_id == "" or not nodes.has(node_id):
		close()
		return
	var node: Dictionary = nodes[node_id]
	_text.text = node.get("text", "")
	_text.visible_ratio = 0.0
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / CHARS_PER_SECOND)

	for c in _options.get_children():
		_options.remove_child(c)
		c.queue_free()
	var n := 0
	for option in node.get("options", []):
		if option.has("requires_flag") and not character.flags.has(option["requires_flag"]):
			continue
		if option.has("hides_if_flag") and character.flags.has(option["hides_if_flag"]):
			continue
		n += 1
		var b := Button.new()
		b.text = "%d. %s" % [n, option["text"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(option))
		_options.add_child(b)
	_reposition.call_deferred()


## Centrada abajo, por encima del HUD (se recalcula porque la altura cambia con el texto).
func _reposition() -> void:
	reset_size()
	var view := get_viewport_rect().size
	position = Vector2((view.x - size.x) / 2.0, view.y - BOTTOM_MARGIN - size.y)


func _choose(option: Dictionary) -> void:
	# Un click mientras se escribe el texto lo completa primero.
	if _text.visible_ratio < 1.0:
		_typing_tween.kill()
		_text.visible_ratio = 1.0
		return
	if option.has("action"):
		action_requested.emit(option["action"])
	_show_node(option.get("next", ""))
