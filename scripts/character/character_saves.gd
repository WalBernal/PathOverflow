class_name CharacterSaves
## Archivos de guardado de personajes: un JSON por personaje en user://characters.
## En Windows, user:// es %APPDATA%\Godot\app_userdata\Exile Overflow.
##
## Escritura segura: se escribe en <id>.json.tmp y luego se sustituye el
## archivo; las versiones anteriores se conservan como <id>.json.bak, .bak2 y
## .bak3 (de la más nueva a la más vieja). Si el juego se cierra a mitad de
## guardado, nunca queda un archivo a medias, y si el principal se daña se
## carga la copia más reciente que se pueda leer.
##
## Espacios de guardado: cada uno tiene sus personajes y su alijo. El 1 usa las
## carpetas de siempre (user://characters, user://stash.json); los demás,
## user://espacio_N/. El activo se recuerda en settings.cfg.

const SAVE_DIR := "user://characters"
const NAME_MIN := 2
const NAME_MAX := 20
const BACKUPS := [".bak", ".bak2", ".bak3"]
const SLOTS := 3

static var _slot := 0   # 0 = sin leer todavía de settings.cfg


## Nombres anteriores del proyecto: Godot guarda en app_userdata/<nombre>, así
## que al renombrar el juego hay que traer los personajes de la carpeta antigua.
const OLD_PROJECT_NAMES := ["Exile Overflow"]


## Espacio de guardado activo (1..SLOTS).
static func slot() -> int:
	if _slot == 0:
		_slot = clampi(int(GameSettings.get_value("saves", "slot", 1)), 1, SLOTS)
	return _slot


static func set_slot(n: int) -> void:
	_slot = clampi(n, 1, SLOTS)
	GameSettings.set_value("saves", "slot", _slot)


## Carpeta raíz del espacio (donde van sus personajes y su alijo).
static func slot_root(n: int) -> String:
	return "user://" if n <= 1 else "user://espacio_%d/" % n


## Carpeta de personajes del espacio activo.
static func current_dir() -> String:
	return SAVE_DIR if slot() <= 1 else slot_root(slot()) + "characters"


## Alijo del espacio activo.
static func stash_path() -> String:
	return slot_root(slot()) + "stash.json"


## Copia (sin borrar nada) los guardados de una carpeta de un nombre anterior
## del proyecto si la actual no tiene ninguno. Devuelve cuántos copió.
static func migrate_from_old_project_names(dir := SAVE_DIR) -> int:
	if not list_all(dir).is_empty():
		return 0
	var copied := 0
	var parent := OS.get_user_data_dir().get_base_dir()
	for old_name in OLD_PROJECT_NAMES:
		var old_dir := parent.path_join(old_name).path_join("characters")
		if not DirAccess.dir_exists_absolute(old_dir):
			continue
		DirAccess.make_dir_recursive_absolute(dir)
		for file_name in DirAccess.get_files_at(old_dir):
			if file_name.ends_with(".json") or file_name.ends_with(".json.bak"):
				if DirAccess.copy_absolute(old_dir.path_join(file_name), ProjectSettings.globalize_path(dir).path_join(file_name)) == OK:
					copied += 1
	return copied


static func new_id() -> String:
	return "%d_%04d" % [Time.get_unix_time_from_system(), randi() % 10000]


static func path_for(id: String, dir := "") -> String:
	return "%s/%s.json" % [dir if dir != "" else current_dir(), id]


static func write(data: Dictionary, dir := "") -> Error:
	var path := path_for(data["id"], dir)
	var err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		return err
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		# Rotación: .bak2 -> .bak3, .bak -> .bak2, principal -> .bak
		DirAccess.remove_absolute(path + BACKUPS[-1])
		for k in range(BACKUPS.size() - 1, 0, -1):
			if FileAccess.file_exists(path + BACKUPS[k - 1]):
				DirAccess.rename_absolute(path + BACKUPS[k - 1], path + BACKUPS[k])
		DirAccess.rename_absolute(path, path + BACKUPS[0])
	return DirAccess.rename_absolute(tmp, path)


## Lee un guardado. Si el principal está dañado (o falta), prueba las copias de
## la más nueva a la más vieja.
static func read(id: String, dir := "") -> Dictionary:
	var path := path_for(id, dir)
	for candidate in [path] + BACKUPS.map(func(b: String) -> String: return path + b):
		if not FileAccess.file_exists(candidate):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if data is Dictionary and data.has("id") and data.has("class_id"):
			if candidate != path:
				push_warning("Guardado dañado o ausente: se cargó la copia %s" % candidate)
			return data
		push_warning("Guardado dañado: %s" % candidate)
	return {}


static func delete(id: String, dir := "") -> void:
	var path := path_for(id, dir)
	for p in [path, path + ".tmp"] + BACKUPS.map(func(b: String) -> String: return path + b):
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Todos los personajes guardados, el último jugado primero. También los que
## solo tienen copias (si el juego se cerró justo al sustituir el principal).
## Los archivos ilegibles se ignoran (y se avisa en la consola).
static func list_all(dir := "") -> Array[Dictionary]:
	if dir == "":
		dir = current_dir()
	var result: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(dir):
		return result
	var ids: Array[String] = []
	for file_name in DirAccess.get_files_at(dir):
		for suffix in [".json"] + BACKUPS.map(func(b: String) -> String: return ".json" + b):
			if file_name.ends_with(suffix):
				var id := file_name.trim_suffix(suffix)
				if not ids.has(id):
					ids.append(id)
				break
	for id in ids:
		var data := read(id, dir)
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
