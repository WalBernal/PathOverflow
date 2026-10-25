class_name ControlsPanel
extends AcceptDialog
## Pausa → Controles: una fila por acción con su tecla y su botón del mando. Un
## clic en cualquiera espera la tecla (o el botón) nueva; Esc cancela. Si ya la
## usaba otra acción, se intercambian (Controls).

var _grid: GridContainer
## Lo que se está reasignando: {action, kind: "key"|"pad"} o vacío.
var _waiting: Dictionary = {}
var _note: Label


func _init() -> void:
	title = "Controles"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_note = UiStyle.label("Haz clic en una tecla o un botón y pulsa el nuevo. Esc cancela.", 13, UiStyle.MUTED)
	box.add_child(_note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	var reset := UiStyle.button("Restaurar los de fábrica", func() -> void:
		Controls.reset_all()
		_waiting = {}
		_note.text = "Controles restaurados."
		_refresh(), 300)
	box.add_child(reset)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	window_input.connect(_on_window_input)
	_refresh()


func _refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for h in ["Acción", "Teclado", "Mando"]:
		_grid.add_child(UiStyle.label(h, 13, UiStyle.GOLD))
	for a in Controls.ACTIONS:
		var action: StringName = a[0]
		var name_label := UiStyle.label(a[1], 13)
		name_label.custom_minimum_size.x = 230
		_grid.add_child(name_label)
		var waiting_here: bool = _waiting.get("action", &"") == action
		var key := UiStyle.button("…" if waiting_here and _waiting["kind"] == "key" else Controls.key_label(action), _start.bind(action, "key"), 160)
		_grid.add_child(key)
		var pad := UiStyle.button("…" if waiting_here and _waiting["kind"] == "pad" else Controls.pad_name(Controls.pad_of(action), action), _start.bind(action, "pad"), 160)
		pad.disabled = not a[2]
		if not a[2]:
			pad.tooltip_text = "El movimiento con mando va con el stick izquierdo."
		_grid.add_child(pad)


func _start(action: StringName, kind: String) -> void:
	_waiting = {"action": action, "kind": kind}
	_note.text = "Pulsa la tecla nueva (Esc cancela)." if kind == "key" else "Pulsa el botón nuevo del mando (Esc cancela)."
	_refresh()


func _on_window_input(event: InputEvent) -> void:
	if _waiting.is_empty() or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if key == null and pad == null:
		return
	set_input_as_handled()
	if key and key.physical_keycode == KEY_ESCAPE:
		_note.text = "Cancelado."
	elif _waiting["kind"] == "key" and key:
		_note.text = apply_key(_waiting["action"], int(key.physical_keycode))
	elif _waiting["kind"] == "pad" and pad:
		_note.text = apply_pad(_waiting["action"], int(pad.button_index))
	else:
		return   # un botón del mando cuando se espera tecla (o al revés): se sigue esperando
	_waiting = {}
	_refresh()


## Asigna y devuelve el aviso para el jugador.
static func apply_key(action: StringName, code: int) -> String:
	var swapped := Controls.rebind_key(action, code)
	return "%s: %s.%s" % [_action_name(action), Controls.key_name(code), " Intercambiada con «%s»." % swapped if swapped != "" else ""]


static func apply_pad(action: StringName, button: int) -> String:
	var swapped := Controls.rebind_pad(action, button)
	return "%s: %s.%s" % [_action_name(action), Controls.pad_name(button), " Intercambiado con «%s»." % swapped if swapped != "" else ""]


static func _action_name(action: StringName) -> String:
	for a in Controls.ACTIONS:
		if a[0] == action:
			return a[1]
	return String(action)
