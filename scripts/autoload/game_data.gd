extends Node
## Autoload "GameData": datos estáticos del juego (cargados una sola vez) y el
## personaje con el que se está jugando.

const CLASSES_PATH := "res://data/classes.json"
const PASSIVE_TREE_PATH := "res://data/passive_tree.json"
const ACT_PATHS := ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]
const CUTSCENES_PATH := "res://data/cutscenes.json"
const TITLE_SCENE := "res://scenes/menu/title_screen.tscn"
const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CREATION_SCENE := "res://scenes/menu/character_creation.tscn"
const WORLD_SCENE := "res://scenes/game/world.tscn"
const PROLOGUE_SCENE := "res://scenes/prologue/prologue.tscn"

var classes: Array = []
var passive_tree: PassiveTree
var items: ItemDatabase
## Actos en orden (data/actN.json). `act` es el primero (donde empieza todo).
var acts: Array = []
var act: Dictionary = {}
## Zonas de todos los actos por id; cada una sabe su acto en "act".
var zones: Dictionary = {}
## Escenas (data/cutscenes.json) por id.
var cutscenes: Dictionary = {}
## Música (data/music.json): pistas y pista de cada zona.
var music: Dictionary = {}
## Personaje elegido en la pantalla de inicio (null = ninguno todavía).
var current_character: CharacterData
## Personaje a medio crear (nombre y apariencia del creador) mientras dura el
## prólogo: la clase se elige allí. {name, appearance, skip_prologue}
var pending_creation: Dictionary = {}


func _ready() -> void:
	GraphicsQuality.apply_fps()   # límite de FPS (T144)
	Gamepad.setup()
	Controls.setup()   # lo que el jugador reasignó en Pausa → Controles
	var data = DataLoader.load_json(CLASSES_PATH)
	if data is Dictionary:
		classes = data.get("classes", [])
		AscendancyTree.expand_classes(classes)   # árboles de 20 nodos (ascendancy_trees.json)
	passive_tree = PassiveTree.load_from_json(PASSIVE_TREE_PATH)
	items = ItemDatabase.load_from_dir()
	var migrated := CharacterSaves.migrate_from_old_project_names()
	if migrated > 0:
		print("Guardados copiados desde el nombre antiguo del proyecto: %d archivos" % migrated)
	for path in ACT_PATHS:
		var act_data = DataLoader.load_json(path)
		if not act_data is Dictionary:
			continue
		acts.append(act_data)
		for z in act_data.get("zones", []):
			z["act"] = act_data["id"]
			Zone.scale_def(z)   # zonas agrandadas ("scale" en el act*.json)
			zones[z["id"]] = z
	act = acts[0] if not acts.is_empty() else {}
	var cutscene_data = DataLoader.load_json(CUTSCENES_PATH)
	if cutscene_data is Dictionary:
		cutscenes = cutscene_data.get("cutscenes", {})
	var music_data = DataLoader.load_json("res://data/music.json")
	if music_data is Dictionary:
		music = music_data


## Acto al que pertenece una zona ({} si no existe).
func act_of_zone(zone_id: String) -> Dictionary:
	var act_id: String = zones.get(zone_id, {}).get("act", "")
	for a in acts:
		if a["id"] == act_id:
			return a
	return {}


## Pueblo (punto de reaparición) del acto de esa zona.
func town_for_zone(zone_id: String) -> String:
	return act_of_zone(zone_id).get("town", act.get("town", "campamento"))


func get_class_def(class_id: StringName) -> Dictionary:
	for c in classes:
		if StringName(c["id"]) == class_id:
			return c
	return {}


## Personaje nuevo con su arma inicial. Si `persistent`, recibe id y se guarda.
func create_character(char_name: String, class_id: StringName, appearance: Dictionary, persistent := true) -> CharacterData:
	var class_def := get_class_def(class_id)
	var c := CharacterData.new(class_def, passive_tree)
	c.character_name = char_name.strip_edges()
	c.appearance = CharacterAppearance.sanitize(appearance)
	var weapon_id: String = class_def.get("starter_weapon", "")
	if items.bases.has(weapon_id):
		c.inventory.set_equipped("weapon", ItemGenerator.new(items).generate(1, Rarity.Item.NORMAL, weapon_id))
	give_starter_skills(c)
	c.flags[CharacterData.STARTER_KIT_FLAG] = true
	var starters := Flask.starter_set(items)
	for i in mini(starters.size(), Inventory.FLASK_SLOTS):
		c.inventory.flasks[i] = starters[i]
	# Los personajes nuevos empiezan en la zona tutorial.
	c.flags["zone"] = act.get("start_zone", "tutorial")
	if persistent:
		c.id = CharacterSaves.new_id()
		c.created_at = int(Time.get_unix_time_from_system())
		save_character(c)
	return c


func load_character(id: String) -> CharacterData:
	var data := CharacterSaves.read(id)
	if data.is_empty():
		return null
	var class_def := get_class_def(StringName(data["class_id"]))
	if class_def.is_empty():
		push_error("Clase desconocida en el guardado: %s" % data["class_id"])
		return null
	var c := CharacterData.from_dict(data, class_def, passive_tree, items)
	# Migración v1 -> v2: los guardados de antes de las habilidades no tienen placas.
	if int(data.get("save_version", 1)) < 2:
		give_starter_skills(c)
	# Kits de 3 habilidades: a los personajes de antes se les regala la que les falte.
	if not c.flags.has(CharacterData.STARTER_KIT_FLAG):
		c.give_missing_starter_skills(items)
	return c


## Placas base iniciales de la clase (3 ranuras de la generación de su atributo).
func give_starter_skills(c: CharacterData) -> void:
	var generator := ItemGenerator.new(items)
	var skill_ids: Array = c.class_def.get("starter_skills", [])
	for i in mini(skill_ids.size(), Inventory.HOTBAR_SIZE):
		if items.skills.skills.has(skill_ids[i]) and c.inventory.boards[i] == null:
			var def: Dictionary = items.skills.skills[skill_ids[i]]
			var gen: String = RamModule.GENERATION_BY_ATTRIBUTE.get(def.get("attribute", "str"), "DDR3")
			c.inventory.set_board(i, Motherboard.new(def, 1, [gen, gen, gen]))


## Guarda el personaje (no hace nada con personajes temporales sin id).
func save_character(c: CharacterData) -> Error:
	if c == null or c.id == "":
		return OK
	c.last_played = int(Time.get_unix_time_from_system())
	var err := CharacterSaves.write(c.to_dict())
	if err != OK:
		push_error("No se pudo guardar a %s: %s" % [c.character_name, error_string(err)])
	return err

## F11 o Alt+Enter: pantalla completa / ventana (en cualquier pantalla).
func _input(event: InputEvent) -> void:
	Gamepad.note_event(event)
	Touch.note_event(event)
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F11 or (key.keycode == KEY_ENTER and key.alt_pressed):
		var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


## Al cerrar, se apaga el ayudante de la voz del narrador.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		NarratorVoice.shutdown()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Botón o gesto Atrás de Android (T141; en project.godot, quit_on_go_back=false):
## en el título y el menú pregunta antes de salir (`ask_quit` de la pantalla); en lo
## demás es Esc (cierra la ventana de arriba o abre la pausa).
func go_back() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("ask_quit"):
		scene.call("ask_quit")
		return
	for pressed in [true, false]:
		var esc := InputEventAction.new()
		esc.action = &"ui_cancel"
		esc.pressed = pressed
		Input.parse_input_event(esc)


## Ventana «¿Salir del juego?» para el botón Atrás en el título y el menú principal.
static func quit_dialog(parent: Node) -> ConfirmationDialog:
	var d := ConfirmationDialog.new()
	d.title = "Salir"
	d.dialog_text = "¿Salir del juego? Lo guardado se queda guardado."
	d.ok_button_text = "Salir"
	d.cancel_button_text = "Seguir"
	d.theme = UiStyle.make_theme()
	d.confirmed.connect(func() -> void: parent.get_tree().quit())
	parent.add_child(d)
	return d
