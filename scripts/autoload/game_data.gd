extends Node
## Autoload "GameData": datos estáticos del juego, cargados una sola vez.

const CLASSES_PATH := "res://data/classes.json"
const PASSIVE_TREE_PATH := "res://data/passive_tree.json"

var classes: Array = []
var passive_tree: PassiveTree
var items: ItemDatabase


func _ready() -> void:
	var data = DataLoader.load_json(CLASSES_PATH)
	if data is Dictionary:
		classes = data.get("classes", [])
	passive_tree = PassiveTree.load_from_json(PASSIVE_TREE_PATH)
	items = ItemDatabase.load_from_dir()


func get_class_def(class_id: StringName) -> Dictionary:
	for c in classes:
		if StringName(c["id"]) == class_id:
			return c
	return {}
