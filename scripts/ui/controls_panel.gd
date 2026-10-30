class_name ControlsPanel
extends AcceptDialog
## Pausa → Controles: una fila por acción con su tecla y su botón del mando. Un
## clic en cualquiera espera la tecla (o el botón) nueva; Esc cancela. Si ya la
## usaba otra acción, se intercambian (Controls).

var _grid: GridContainer
## Lo que se está reasignando: {action, kind: "key"|"pad"} o vacío.
var _waiting: Dictionary = {}
var _note: Label
## Lo pone GameUI: abre el editor de disposición táctil (T137).
var edit_layout: Callable


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
	# Joystick y mira en pantalla (T107): solo se ven con pantalla táctil.
	var touch := UiStyle.button("", func() -> void: pass, 300)
	var touch_text := func() -> String:
		return "Controles táctiles: " + ("sí" if Touch.enabled() else "no")
	touch.text = touch_text.call()
	touch.tooltip_text = "Joystick a la izquierda (aparece donde apoyas el dedo) y apuntado automático al enemigo más cercano\nen la dirección del joystick. Solo con pantalla táctil."
	touch.pressed.connect(func() -> void:
		Touch.set_enabled(not Touch.enabled())
		touch.text = touch_text.call())
	box.add_child(touch)
	# Recoger solo al pasar por encima (T134): apagado o desde una rareza.
	var auto := UiStyle.button("", func() -> void: pass, 300)
	var steps := [-1, 0, 1, 2, 3, 4]   # escalones de LootFilter.step_of
	var names := {-1: "no", 0: "todo lo visible", 1: "mágico o más", 2: "raro o más", 3: "ultra-raro o más", 4: "solo únicos"}
	var auto_text := func() -> String:
		return "Recoger solo al pasar: " + String(names.get(LootManager.auto_pickup_min, "no"))
	LootManager.load_auto_pickup()
	auto.text = auto_text.call()
	auto.tooltip_text = "Recoge sin tocar los objetos que pisas, si el filtro de botín los deja ver\ny son de esa rareza o más. Pensado para el celular."
	auto.pressed.connect(func() -> void:
		var k := steps.find(LootManager.auto_pickup_min)
		LootManager.set_auto_pickup(steps[(k + 1) % steps.size()])
		auto.text = auto_text.call())
	box.add_child(auto)
	# Botones táctiles (T136): distribución, tamaño y mano.
	Touch.load_layout()
	var touch_row := HBoxContainer.new()
	touch_row.add_theme_constant_override("separation", 6)
	box.add_child(touch_row)
	var layout_names := {"esquina": "ataque en la esquina", "arcos": "dos arcos"}
	var layout_b := UiStyle.button("", func() -> void: pass, 300)
	var size_b := UiStyle.button("", func() -> void: pass, 190)
	var hand_b := UiStyle.button("", func() -> void: pass, 150)
	var refresh_touch := func() -> void:
		layout_b.text = "Botones: " + String(layout_names[Touch.layout])
		size_b.text = "Tamaño: %d %%" % roundi(Touch.button_scale * 100.0)
		hand_b.text = "Mano: " + ("zurda" if Touch.left_handed else "diestra")
	layout_b.tooltip_text = "Ataque en la esquina: la habilidad 1 grande junto al orbe de maná y las demás alrededor.\nDos arcos: las 6 habilidades en dos arcos a la izquierda del orbe."
	hand_b.tooltip_text = "Zurda: el joystick a la derecha y los botones a la izquierda."
	layout_b.pressed.connect(func() -> void:
		Touch.layout = Touch.LAYOUTS[(Touch.LAYOUTS.find(Touch.layout) + 1) % Touch.LAYOUTS.size()]
		Touch.save_layout()
		refresh_touch.call())
	size_b.pressed.connect(func() -> void:
		var k := Touch.BUTTON_SCALES.find(snappedf(Touch.button_scale, 0.1))
		Touch.button_scale = Touch.BUTTON_SCALES[(k + 1) % Touch.BUTTON_SCALES.size()]
		Touch.save_layout()
		refresh_touch.call())
	hand_b.pressed.connect(func() -> void:
		Touch.left_handed = not Touch.left_handed
		Touch.save_layout()
		refresh_touch.call())
	refresh_touch.call()
	touch_row.add_child(layout_b)
	touch_row.add_child(size_b)
	touch_row.add_child(hand_b)
	# Joystick (T149): flotante, fijo o que sigue al dedo, y su zona muerta.
	var stick_row := HBoxContainer.new()
	stick_row.add_theme_constant_override("separation", 6)
	box.add_child(stick_row)
	var stick_names := {"flotante": "donde pongas el dedo", "fijo": "fijo", "sigue": "sigue al dedo"}
	var stick_b := UiStyle.button("", func() -> void: pass, 330)
	var dead_b := UiStyle.button("", func() -> void: pass, 250)
	var refresh_stick := func() -> void:
		stick_b.text = "Joystick: " + String(stick_names[Touch.stick_mode])
		dead_b.text = "Zona muerta: " + Touch.deadzone_name
	stick_b.tooltip_text = "Donde pongas el dedo: aparece ahí. Fijo: siempre en el mismo sitio y a la vista.\nSigue al dedo: aparece donde lo pones y, si te alejas, la base va detrás."
	dead_b.tooltip_text = "Cuánto hay que inclinar el joystick para que el personaje empiece a moverse."
	stick_b.pressed.connect(func() -> void:
		Touch.stick_mode = Touch.STICK_MODES[(Touch.STICK_MODES.find(Touch.stick_mode) + 1) % Touch.STICK_MODES.size()]
		Touch.save_layout()
		refresh_stick.call())
	dead_b.pressed.connect(func() -> void:
		var zones: Array = Touch.DEADZONES.keys()
		Touch.deadzone_name = zones[(zones.find(Touch.deadzone_name) + 1) % zones.size()]
		Touch.save_layout()
		refresh_stick.call())
	refresh_stick.call()
	stick_row.add_child(stick_b)
	stick_row.add_child(dead_b)
	# Mover y agrandar cada botón y su opacidad (T137): solo con pantalla táctil y en partida.
	if Touch.shown():
		var editor := UiStyle.button("Mover y ajustar los botones...", func() -> void:
			if edit_layout.is_valid():
				edit_layout.call(), 300)
		editor.tooltip_text = "Arrastra cada botón táctil a donde quieras, cambia su tamaño y la opacidad de todos."
		box.add_child(editor)
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
