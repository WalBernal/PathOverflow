extends Node
## Autoload "GameData": datos estáticos del juego (cargados una sola vez) y el
## personaje con el que se está jugando.

const CLASSES_PATH := "res://data/classes.json"
const PASSIVE_TREE_PATH := "res://data/passive_tree.json"
const ACT_PATH := "res://data/act1.json"
const TITLE_SCENE := "res://scenes/menu/title_screen.tscn"
const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CREATION_SCENE := "res://scenes/menu/character_creation.tscn"
const WORLD_SCENE := "res://scenes/game/world.tscn"

var classes: Array = []
var passive_tree: PassiveTree
var items: ItemDatabase
## Acto actual (data/act1.json) y sus zonas por id.
var act: Dictionary = {}
var zones: Dictionary = {}
## Personaje elegido en la pantalla de inicio (null = ninguno todavía).
var current_character: CharacterData


func _ready() -> void:
	var data = DataLoader.load_json(CLASSES_PATH)
	if data is Dictionary:
		classes = data.get("classes", [])
	passive_tree = PassiveTree.load_from_json(PASSIVE_TREE_PATH)
	items = ItemDatabase.load_from_dir()
	var migrated := CharacterSaves.migrate_from_old_project_names()
	if migrated > 0:
		print("Guardados copiados desde el nombre antiguo del proyecto: %d archivos" % migrated)
	var act_data = DataLoader.load_json(ACT_PATH)
	if act_data is Dictionary:
		act = act_data
		for z in act.get("zones", []):
			zones[z["id"]] = z


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
