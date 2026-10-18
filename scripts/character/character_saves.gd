class_name CharacterSaves
## Archivos de guardado de personajes: un JSON por personaje en user://characters.
## En Windows, user:// es %APPDATA%\Godot\app_userdata\Exile Overflow.
##
## Escritura segura: se escribe en <id>.json.tmp y luego se sustituye el
## archivo; la versión anterior se conserva como <id>.json.bak. Si el juego se
## cierra a mitad de guardado, nunca queda un archivo a medias.

const SAVE_DIR := "user://characters"
const NAME_MIN := 2
const NAME_MAX := 20


static func new_id() -> String:
	return "%d_%04d" % [Time.get_unix_time_from_system(), randi() % 10000]


static func path_for(id: String, dir := SAVE_DIR) -> String:
	return "%s/%s.json" % [dir, id]


static func write(data: Dictionary, dir := SAVE_DIR) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	var path := path_for(data["id"], dir)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path)


## Lee un guardado. Si el principal está dañado, intenta con la copia .bak.
static func read(id: String, dir := SAVE_DIR) -> Dictionary:
	var path := path_for(id, dir)
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if data is Dictionary and data.has("id") and data.has("class_id"):
			return data
		push_warning("Guardado dañado: %s" % candidate)
	return {}


static func delete(id: String, dir := SAVE_DIR) -> void:
	var path := path_for(id, dir)
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Todos los personajes guardados, el último jugado primero.
## Los archivos ilegibles se ignoran (y se avisa en la consola).
static func list_all(dir := SAVE_DIR) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(dir):
		return result
	for file_name in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".json"):
			continue
		var data := read(file_name.get_basename(), dir)
		if not data.is_empty():
			result.append(data)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("last_played", 0)) > int(b.get("last_played", 0)))
	return result


## "" si el nombre es válido; si no, el motivo (para mostrarlo en la UI).
static func validate_name(name: String, existing_names: Array) -> String:
	var clean := name.strip_edges()
	if clean.length() < NAME_MIN:
		return "El nombre necesita al menos %d caracteres." % NAME_MIN
	if clean.length() > NAME_MAX:
		return "Máximo %d caracteres. Esto no es un nombre de variable en Java." % NAME_MAX
	var regex := RegEx.create_from_string("^[\\p{L}\\p{N} _-]+$")
	if regex.search(clean) == null:
		return "Solo letras, números, espacios, '_' y '-'."
	for other in existing_names:
		if String(other).to_lower() == clean.to_lower():
			return "Ya existe un personaje con ese nombre. Los duplicados, en otra base de datos."
	return ""
