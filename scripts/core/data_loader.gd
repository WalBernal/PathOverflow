class_name DataLoader
## Utilidades para cargar datos de diseño (JSON en res://data).
## Nota de exportación: añade "*.json" en Exportar → Recursos →
## "Filtros para exportar archivos no-recurso", o no se incluirán.


static func load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return null
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("JSON inválido en %s" % path)
	return data
