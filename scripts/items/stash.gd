class_name Stash
extends RefCounted
## Alijo compartido por la cuenta: todos los personajes ven los mismos objetos.
## Se guarda aparte de los personajes (user://stash.json) cada vez que cambia.
## Los objetos clave no entran (son de la historia de cada personaje).

signal changed

const TABS := 5
const TAB_SIZE := 60
## Nombres de fábrica (cada pestaña se puede renombrar, T80).
const TAB_NAMES := ["Repositorio", "Rama dev", "Rama hotfix", "Papelera (no se vacía)", "Materiales"]
## Pestaña de materiales (T80): solo chips de expansión (lo de crafteo que es objeto;
## los parches son contadores y se ven en su cabecera).
const MATERIALS_TAB := 4
const NAME_MAX := 20
## Colores que se pueden dar a una pestaña.
const TAB_COLORS := [Color("8a8293"), Color("d9a441"), Color("6fd36b"), Color("4fa3e0"), Color("e06c6c"), Color("b05ad9"), Color("e8e0d0")]
const DEFAULT_COLORS := [0, 3, 4, 0, 1]
const DEFAULT_PATH := "user://stash.json"

var path := DEFAULT_PATH
## tabs[t][i] -> Item o null
var tabs: Array = []
## Nombre e índice de color (TAB_COLORS) de cada pestaña.
var names: Array = []
var colors: Array = []


func _init(p_path := DEFAULT_PATH) -> void:
	path = p_path
	for t in TABS:
		var tab: Array = []
		tab.resize(TAB_SIZE)
		tabs.append(tab)
	names = TAB_NAMES.duplicate()
	colors = DEFAULT_COLORS.duplicate()


func tab_name(t: int) -> String:
	return String(names[t])


func tab_color(t: int) -> Color:
	return TAB_COLORS[clampi(int(colors[t]), 0, TAB_COLORS.size() - 1)]


## Renombra una pestaña (sin espacios de más y con tope de largo; vacío = el nombre de fábrica).
func rename(t: int, new_name: String) -> void:
	var clean := new_name.strip_edges().substr(0, NAME_MAX)
	names[t] = clean if clean != "" else TAB_NAMES[t]
	changed.emit()


func set_color(t: int, index: int) -> void:
	colors[t] = clampi(index, 0, TAB_COLORS.size() - 1)
	changed.emit()


static func is_material(item: Item) -> bool:
	return item is ExpansionChip


## "" si la pestaña admite el objeto; si no, por qué.
static func refusal(t: int, item: Item) -> String:
	if item is KeyItem:
		return "Los objetos clave se quedan contigo: son de tu historia, no de la cuenta."
	if t == MATERIALS_TAB and item and not is_material(item):
		return "La pestaña de materiales es para chips de expansión. El equipo, en las otras."
	return ""


## ¿El objeto coincide con la búsqueda? (nombre, base o texto de sus afijos; sin
## distinguir mayúsculas ni tildes). Una búsqueda vacía no marca nada.
static func matches(item: Item, query: String) -> bool:
	var q := _fold(query.strip_edges())
	if item == null or q == "":
		return false
	var hay := item.display_name() + " " + String(item.base.get("name", ""))
	if item is Motherboard:
		hay += " " + String((item as Motherboard).skill_def.get("name", ""))
	for m in item.implicit_mods() + item.rolled_mods():
		if m is Dictionary and m.has("stat"):
			hay += " " + Item.describe_mod(m)
	for a in item.affixes:
		hay += " " + String(a.get("name", ""))
	return _fold(hay).contains(q)


## Cuántos objetos de la pestaña coinciden.
func match_count(t: int, query: String) -> int:
	var n := 0
	for item in tabs[t]:
		if matches(item, query):
			n += 1
	return n


static func _fold(s: String) -> String:
	var out := s.to_lower()
	for pair in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"]]:
		out = out.replace(pair[0], pair[1])
	return out


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
	if is_material(item):
		tab = MATERIALS_TAB   # los materiales, a su pestaña primero
	for k in TABS:
		var t := (tab + k) % TABS
		if refusal(t, item) != "":
			continue
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
	return {"version": 2, "tabs": data, "names": names, "colors": colors}


func load_dict(d: Dictionary, db: ItemDatabase) -> void:
	var saved_names: Array = d.get("names", [])
	var saved_colors: Array = d.get("colors", [])
	for t in TABS:
		if t < saved_names.size() and String(saved_names[t]) != "":
			names[t] = String(saved_names[t]).substr(0, NAME_MAX)
		if t < saved_colors.size():
			colors[t] = clampi(int(saved_colors[t]), 0, TAB_COLORS.size() - 1)
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
