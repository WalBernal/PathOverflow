class_name ZoneMechanics
extends RefCounted
## Mecánicas de zona (T120): qué le toca a cada instancia de una zona de combate,
## según data/zone_mechanics.json. Siempre una principal (para que ninguna zona sea
## solo pegar) y, como mucho, un evento menor (para no saturarla). Las que trae la zona
## en sus datos (mutex, carrera crítica) son su principal mientras no se superen.

const DATA_PATH := "res://data/zone_mechanics.json"
## Zonas sin mecánicas: el tutorial enseña lo básico sin sorpresas.
const NONE := ["tutorial"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = DataLoader.load_json(DATA_PATH)
		if d is Dictionary:
			_data = d
	return _data


static func info(id: String) -> Dictionary:
	return data().get("main", {}).get(id, {})


## ¿Puede tocarle la mecánica `id` a esta zona? (las fijas, solo si la zona la trae).
static func eligible(id: String, def: Dictionary, act_id: String) -> bool:
	var m := info(id)
	if m.is_empty():
		return false
	if String(m.get("kind", "event")) == "fixed":
		return def.get(String(m.get("data_key", id))) is Dictionary
	var styles: Array = m.get("styles", [])
	var acts: Array = m.get("acts", [])
	return (styles.is_empty() or styles.has(String(def.get("style", "")))) and (acts.is_empty() or acts.has(act_id)) \
		and int(def.get("level", 1)) >= int(m.get("min_level", 1)) and float(m.get("weight", 0.0)) > 0.0


## Las principales que le pueden tocar al azar (sin las fijas).
static func candidates(def: Dictionary, act_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in data().get("main", {}):
		if String(info(id).get("kind", "event")) != "fixed" and eligible(id, def, act_id):
			out.append(id)
	return out


## El reparto de una instancia: {"main": id ("" si no hay), "minor": tipo de evento ("" si
## no hay), "fixed": true si la principal la trae la zona}. `flags`: las del personaje
## (una fija ya superada deja sitio a una al azar).
static func plan(def: Dictionary, rng: RandomNumberGenerator, flags := {}, act_id := "") -> Dictionary:
	var out := {"main": "", "minor": "", "fixed": false}
	if bool(def.get("safe", false)) or def.has("boss") or not def.get("enemies") is Dictionary or NONE.has(String(def.get("id", ""))):
		return out
	for id in data().get("main", {}):
		var m := info(id)
		if String(m.get("kind", "")) == "fixed" and eligible(id, def, act_id):
			var flag := String((def[String(m.get("data_key", id))] as Dictionary).get("flag", ""))
			if flag == "" or not flags.has(flag):
				out["main"] = id
				out["fixed"] = true
	if out["main"] == "":
		var options := candidates(def, act_id)
		var weights: Array[float] = []
		for id in options:
			weights.append(float(info(id).get("weight", 1.0)))
		if not options.is_empty():
			out["main"] = options[ZoneLayout.pick_weighted(weights, options.size(), rng)]
	var minors: Dictionary = data().get("minor", {})
	if not minors.is_empty() and rng.randf() < float(data().get("minor_chance", 0.0)):
		var kinds: Array = minors.keys()
		var mw: Array[float] = []
		for k in kinds:
			mw.append(float(minors[k]))
		out["minor"] = String(kinds[ZoneLayout.pick_weighted(mw, kinds.size(), rng)])
	return out
