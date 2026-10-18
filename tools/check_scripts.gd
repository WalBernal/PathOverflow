extends SceneTree
## Carga (y por tanto compila) todos los scripts, escenas y shaders del proyecto
## para detectar errores sin abrir el editor.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/check_scripts.gd

const ROOTS := ["res://scripts", "res://scenes", "res://assets/shaders", "res://tests", "res://tools"]
const EXTENSIONS := ["gd", "tscn", "gdshader"]


func _initialize() -> void:
	var files: Array[String] = []
	for root_dir in ROOTS:
		_collect(root_dir, files)
	var failed := 0
	for path in files:
		if path.ends_with("check_scripts.gd"):
			continue
		var res := load(path)
		if res == null or (res is GDScript and not res.can_instantiate()):
			failed += 1
			printerr("ERROR al cargar: " + path)
	print("%d archivos comprobados, %d con errores" % [files.size(), failed])
	quit(1 if failed > 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	for file in DirAccess.get_files_at(dir_path):
		if EXTENSIONS.has(file.get_extension()):
			out.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), out)
