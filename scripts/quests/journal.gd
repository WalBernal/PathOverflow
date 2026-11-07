class_name Journal
## Diario del egresado (T225): lo que pasó en cada acto (data/diario.json) según las
## escenas vistas, y un «¿dónde me quedé?» para volver tras semanas sin jugar.

const PATH := "res://data/diario.json"
const SEEN_FLAG := "cutscenes_seen"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = DataLoader.load_json(PATH)
		_data = d if d is Dictionary else {"acts": []}
	return _data


## Apunta que se vio la escena `id` (en las banderas del personaje).
static func mark_seen(flags: Dictionary, id: String) -> void:
	if not flags.has(SEEN_FLAG):
		flags[SEEN_FLAG] = {}
	flags[SEEN_FLAG][id] = true


## Los actos con sus entradas visibles: [{title, lines: [texto...]}]. Una entrada se
## ve si se vio su escena o si su acto ya está completo (partidas de antes del diario).
static func visible_acts(flags: Dictionary) -> Array:
	var seen: Dictionary = flags.get(SEEN_FLAG, {})
	var out: Array = []
	for act in data().get("acts", []):
		var done := bool(act.get("always", false)) or flags.has(String(act.get("id", "")) + "_complete")
		var lines: Array = []
		for e in act.get("entries", []):
			if done or not e.has("cutscene") or seen.has(String(e["cutscene"])):
				lines.append(String(e["text"]))
		if not lines.is_empty():
			out.append({"title": String(act.get("title", "")), "lines": lines})
	return out


## «¿Dónde me quedé?»: la zona y el objetivo actual (o una pista si no hay misión).
static func where(zone_name: String, goal: String) -> String:
	var text := "Estás en %s." % (zone_name if zone_name != "" else "algún lugar del servidor")
	if goal != "":
		text += " Objetivo: %s." % goal.trim_suffix(".")
	else:
		text += " Sin misión a la vista: habla con la gente del campamento (★ en el mapa) o explora."
	return text


## Todo el diario como BBCode, para la pestaña de la hoja de personaje.
static func bbcode(flags: Dictionary, zone_name: String, goal: String) -> String:
	var t := "[b][color=#2dd4bf]¿Dónde me quedé?[/color][/b]\n%s\n" % where(zone_name, goal)
	for act in visible_acts(flags):
		t += "\n[b][color=#d9a441]%s[/color][/b]\n" % act["title"]
		for line in act["lines"]:
			t += "• %s\n" % line
	return t
