class_name Stash
extends RefCounted
## Alijo compartido por la cuenta: todos los personajes ven los mismos objetos.
## Se guarda aparte de los personajes (user://stash.json) cada vez que cambia.
## Los objetos clave no entran (son de la historia de cada personaje).

signal changed

const TABS := 4
const TAB_SIZE := 60
const TAB_NAMES := ["Repositorio", "Rama dev", "Rama hotfix", "Papelera (no se vacía)"]
const DEFAULT_PATH := "user://stash.json"

var path := DEFAULT_PATH
## tabs[t][i] -> Item o null
var tabs: Array = []


func _init(p_path := DEFAULT_PATH) -> void:
	path = p_path
	for t in TABS:
		var tab: Array = []
		tab.resize(TAB_SIZE)
		tabs.append(tab)


func get_item(tab: int, index: int) -> Item:
	return tabs[tab][index]


func set_item(tab: int, index: int, item: Item) -> void:
	tabs[tab][index] = item


## Primer hueco libre de una pestaña (-1 si está llena).
func free_index(tab: int) -> int:
	return tabs[tab].find(null)


## Guarda el objeto en la pestaña (o en la primera con hueco). false si no cabe.
func add_item(item: Item, tab := 0) -> bool:
	if item is KeyItem:
		return false
	for k in TABS:
		var t := (tab + k) % TABS
		var i := free_index(t)
		if i != -1:
			tabs[t][i] = item
			changed.emit()
			return true
	return false


func count() -> int:
	var n := 0
	for tab in tabs:
		for item in tab:
			if item:
				n += 1
	return n


func to_dict() -> Dictionary:
	var data: Array = []
	for tab in tabs:
		var row: Array = []
		for item in tab:
			row.append(Item.serialize(item))
		data.append(row)
	return {"version": 1, "tabs": data}


func load_dict(d: Dictionary, db: ItemDatabase) -> void:
	var data: Array = d.get("tabs", [])
	for t in mini(data.size(), TABS):
		var row: Array = data[t] if data[t] is Array else []
		for i in mini(row.size(), TAB_SIZE):
			if row[i] is Dictionary:
				tabs[t][i] = Item.from_dict(row[i], db)
	changed.emit()


func save() -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar el alijo en %s" % path)
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	if FileAccess.file_exists(path):   # copia de la versión anterior
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


## Si el alijo está dañado se conserva aparte (.danado) y se carga la copia .bak.
static func load_from(p_path: String, db: ItemDatabase) -> Stash:
	var s := Stash.new(p_path)
	for candidate in [p_path, p_path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if parsed is Dictionary:
			s.load_dict(parsed, db)
			return s
		push_warning("Alijo dañado: %s (se conserva aparte como .danado)" % candidate)
		DirAccess.copy_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(candidate + ".danado"))
	return s
