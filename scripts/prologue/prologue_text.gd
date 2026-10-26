class_name PrologueText
## Textos del prólogo que no son diálogos (data/prologue.json): la introducción,
## la consola, los letreros, los avisos de los puntos de interés, la ventana de
## contratación y las ayudas. Si falta alguno, se usa el que se le pase como respaldo.

const PATH := "res://data/prologue.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = DataLoader.load_json(PATH)
		_data = parsed if parsed is Dictionary else {"_vacio": true}
	return _data


## Para pruebas y el editor: vuelve a leer el archivo.
static func reload() -> void:
	_data = {}


static func lines(key: String, fallback: Array = []) -> Array:
	var v: Variant = data().get(key)
	return v if v is Array and not (v as Array).is_empty() else fallback


static func text(section: String, key: String, fallback := "") -> String:
	var s: Variant = data().get(section)
	if s is Dictionary and String((s as Dictionary).get(key, "")) != "":
		return String(s[key])
	return fallback
