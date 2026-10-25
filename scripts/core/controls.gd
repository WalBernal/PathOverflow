class_name Controls
## Teclas y botones reasignables desde la pausa (Pausa → Controles). Cada acción
## tiene una tecla y, si no es de movimiento, un botón del mando. Al asignar algo
## que ya usa otra acción, se intercambian. Se guarda en user://settings.cfg
## (sección «controls», solo lo cambiado) y se aplica al arrancar, después de
## Gamepad.setup(). El ratón y los sticks no se tocan.

const SECTION := "controls"
## [acción, nombre, ¿admite botón del mando?]
const ACTIONS := [
	[&"move_up", "Moverse arriba", false], [&"move_down", "Moverse abajo", false],
	[&"move_left", "Moverse a la izquierda", false], [&"move_right", "Moverse a la derecha", false],
	[&"skill_1", "Habilidad 1", true], [&"skill_2", "Habilidad 2", true], [&"skill_3", "Habilidad 3", true],
	[&"skill_4", "Habilidad 4", true], [&"skill_5", "Habilidad 5", true], [&"skill_6", "Habilidad 6", true],
	[&"flask_1", "Poción 1", true], [&"flask_2", "Poción 2", true], [&"flask_3", "Poción 3", true],
	[&"flask_4", "Poción 4", true], [&"flask_5", "Poción 5", true],
	[&"dodge", "Esquivar (git stash)", true],
	[&"toggle_inventory", "Inventario", true], [&"toggle_skills", "Habilidades (K)", true],
	[&"toggle_character", "Hoja de personaje", true], [&"toggle_passives", "Árbol pasivo", true],
	[&"toggle_map", "Mapa", true], [&"toggle_minimap", "Minimapa", true], [&"toggle_quests", "Misiones", true],
	[&"toggle_catalog", "Catálogo de hardware", true], [&"show_all_loot", "Ver todo el botín", true],
	[&"pin_tooltip", "Fijar la comparación", true],
]
const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_STICK: "Stick izq.", JOY_BUTTON_RIGHT_STICK: "Stick der.",
	JOY_BUTTON_DPAD_UP: "Cruceta ↑", JOY_BUTTON_DPAD_DOWN: "Cruceta ↓", JOY_BUTTON_DPAD_LEFT: "Cruceta ←",
	JOY_BUTTON_DPAD_RIGHT: "Cruceta →", JOY_BUTTON_MISC1: "Compartir",
}

## Eventos de fábrica de cada acción (para «Restaurar»).
static var _defaults: Dictionary = {}
## false en las pruebas: no lee ni toca el settings.cfg del jugador.
static var persist := true


## Guarda los de fábrica y aplica lo que el jugador cambió.
static func setup() -> void:
	_defaults.clear()
	for a in ACTIONS:
		if InputMap.has_action(a[0]):
			_defaults[a[0]] = InputMap.action_get_events(a[0]).map(func(e: InputEvent) -> InputEvent: return e.duplicate())
	for a in ACTIONS:
		var saved = GameSettings.get_value(SECTION, String(a[0]), null) if persist else null
		if not saved is Dictionary or not InputMap.has_action(a[0]):
			continue
		if saved.has("key"):
			_set_key(a[0], int(saved["key"]))
		if saved.has("pad") and a[2]:
			_set_pad(a[0], int(saved["pad"]))


static func allows_pad(action: StringName) -> bool:
	for a in ACTIONS:
		if a[0] == action:
			return a[2]
	return false


## Tecla de la acción (physical_keycode), o -1.
static func key_of(action: StringName) -> int:
	for e in InputMap.action_get_events(action):
		var k := e as InputEventKey
		if k:
			return int(k.physical_keycode) if k.physical_keycode != KEY_NONE else int(k.keycode)
	return -1


## Botón del mando de la acción, o -1 (también si va con un gatillo o un stick).
static func pad_of(action: StringName) -> int:
	for e in InputMap.action_get_events(action):
		var b := e as InputEventJoypadButton
		if b:
			return int(b.button_index)
	return -1


static func key_name(code: int) -> String:
	return "—" if code < 0 else OS.get_keycode_string(code)


static func pad_name(button: int, action := &"") -> String:
	if button < 0:
		return {&"dodge": "Gatillo der.", &"flask_5": "Gatillo izq."}.get(action, "—")
	return PAD_NAMES.get(button, "Botón %d" % button)


## Lo que se ve en la barra de habilidades y en el menú K.
static func key_label(action: StringName) -> String:
	return key_name(key_of(action))


## Asigna la tecla; si otra acción la usaba, se queda con la vieja de esta.
## Devuelve el nombre de la acción con la que se intercambió ("" si ninguna).
static func rebind_key(action: StringName, code: int) -> String:
	var old := key_of(action)
	var swapped := ""
	for a in ACTIONS:
		if a[0] != action and key_of(a[0]) == code:
			_set_key(a[0], old)
			_save(a[0], "key", old)
			swapped = a[1]
	_set_key(action, code)
	_save(action, "key", code)
	return swapped


static func rebind_pad(action: StringName, button: int) -> String:
	if not allows_pad(action):
		return ""
	var old := pad_of(action)
	var swapped := ""
	for a in ACTIONS:
		if a[0] != action and a[2] and pad_of(a[0]) == button:
			_set_pad(a[0], old)
			_save(a[0], "pad", old)
			swapped = a[1]
	_set_pad(action, button)
	_save(action, "pad", button)
	return swapped


## Todo como de fábrica.
static func reset_all() -> void:
	for action in _defaults:
		InputMap.action_erase_events(action)
		for e in _defaults[action]:
			InputMap.action_add_event(action, e.duplicate())
	var cfg := ConfigFile.new()
	if persist and cfg.load(GameSettings.PATH) == OK and cfg.has_section(SECTION):
		cfg.erase_section(SECTION)
		cfg.save(GameSettings.PATH)


static func _set_key(action: StringName, code: int) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	if code >= 0:
		var k := InputEventKey.new()
		k.physical_keycode = code as Key
		InputMap.action_add_event(action, k)


## Cambia los eventos de mando (botón o gatillo) por el botón `button` (-1 = ninguno).
static func _set_pad(action: StringName, button: int) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			InputMap.action_erase_event(action, e)
	if button >= 0:
		var b := InputEventJoypadButton.new()
		b.button_index = button as JoyButton
		InputMap.action_add_event(action, b)


static func _save(action: StringName, kind: String, value: int) -> void:
	if not persist:
		return
	var saved = GameSettings.get_value(SECTION, String(action), {})
	if not saved is Dictionary:
		saved = {}
	saved[kind] = value
	GameSettings.set_value(SECTION, String(action), saved)
