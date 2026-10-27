class_name ZoneInstances
extends RefCounted
## Instancias de zona que se conservan un rato (T118): al salir de una zona generada
## (por una salida, un waypoint o al morir), World guarda aquí su estado —semilla,
## botín y tokens del suelo, cajas abiertas, lo explorado del mapa— y, si vuelves
## antes de que pasen TTL segundos, la zona es la misma. Solo en memoria: al salir al
## menú o cerrar el juego se pierden. Los tiempos los pone quien llama (`now`, en
## segundos), así se prueba sin esperar.

const TTL := 600.0
## Cuántas instancias se guardan a la vez; al pasar, se olvida la que se dejó antes.
const MAX := 8

var _by_zone: Dictionary = {}   # id de zona -> {"left_at": float, ...estado}


## Guarda el estado de la zona `zone_id` (sustituye al que hubiera).
func store(zone_id: String, state: Dictionary, now: float) -> void:
	var entry := state.duplicate()
	entry["left_at"] = now
	_by_zone[zone_id] = entry
	while _by_zone.size() > MAX:
		var oldest := ""
		for k in _by_zone:
			if oldest == "" or float(_by_zone[k]["left_at"]) < float(_by_zone[oldest]["left_at"]):
				oldest = k
		_by_zone.erase(oldest)


## El estado guardado de `zone_id` si sigue vivo ({} si no hay o ya caducó; las
## caducadas se olvidan). No lo quita: al salir otra vez se vuelve a guardar.
func peek(zone_id: String, now: float) -> Dictionary:
	prune(now)
	return _by_zone.get(zone_id, {})


## Segundos que le quedan a la instancia de `zone_id` (0 si no hay).
func time_left(zone_id: String, now: float) -> float:
	var e: Dictionary = _by_zone.get(zone_id, {})
	return maxf(0.0, TTL - (now - float(e["left_at"]))) if not e.is_empty() else 0.0


## «7:32» (minutos y segundos, redondeando hacia arriba).
static func clock(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%d:%02d" % [floori(s / 60.0), s % 60]


## {id de zona: segundos que le quedan} de todas las instancias vivas.
func times(now: float) -> Dictionary:
	prune(now)
	var out := {}
	for k in _by_zone:
		out[k] = time_left(k, now)
	return out


## {id de zona: estado[key]} de las instancias vivas que lo tengan (p. ej. "mechanic").
func values(key: String, now: float) -> Dictionary:
	prune(now)
	var out := {}
	for k in _by_zone:
		if _by_zone[k].has(key):
			out[k] = _by_zone[k][key]
	return out


func prune(now: float) -> void:
	for k in _by_zone.keys():
		if now - float(_by_zone[k]["left_at"]) >= TTL:
			_by_zone.erase(k)


func forget(zone_id: String) -> void:
	_by_zone.erase(zone_id)


func size() -> int:
	return _by_zone.size()
