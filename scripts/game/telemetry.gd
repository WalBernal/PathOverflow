class_name Telemetry
## Telemetría local de equilibrio: cada visita a una zona de un personaje guardado
## deja una línea JSON en user://telemetria.jsonl (nada sale del equipo): zona,
## nivel, clase, dificultad, segundos, segundos en combate, daño hecho, DPS,
## enemigos eliminados y muertes. tools/telemetry_summary.gd lo resume por zona y
## por clase. Se apaga en Pausa → Interfaz (interface/telemetry). Los personajes
## de prueba (sin id) no dejan registro.

const PATH := "user://telemetria.jsonl"
## Visitas más cortas que esto no se apuntan (pasar por un campamento).
const MIN_SECONDS := 5.0


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "telemetry", true))


## Empieza una visita: lo que hay que restar al cerrarla.
static func begin(character: CharacterData, enemies: EnemyManager, zone_id: String, zone_level: int) -> Dictionary:
	return {"zone": zone_id, "zone_level": zone_level, "start": character.play_time,
		"kills": int(character.flags.get("stat_kills", 0)), "deaths": int(character.flags.get("stat_deaths", 0)),
		"damage": enemies.damage_total, "combat": enemies.combat_time}


## La visita ya cerrada, como registro (o {} si no merece la pena apuntarla).
static func finish(visit: Dictionary, character: CharacterData, enemies: EnemyManager) -> Dictionary:
	if visit.is_empty() or character == null:
		return {}
	var seconds := character.play_time - float(visit["start"])
	if seconds < MIN_SECONDS:
		return {}
	var damage := enemies.damage_total - float(visit["damage"])
	var combat := enemies.combat_time - float(visit["combat"])
	return {
		"date": Time.get_datetime_string_from_system(), "character": character.character_name,
		"class": String(character.class_def.get("id", "")), "level": character.level,
		"zone": visit["zone"], "zone_level": visit["zone_level"], "difficulty": Difficulty.current(character),
		"seconds": snappedf(seconds, 0.1), "combat_seconds": snappedf(combat, 0.1), "damage": roundi(damage),
		"dps": roundi(damage / combat) if combat > 1.0 else 0,
		"kills": int(character.flags.get("stat_kills", 0)) - int(visit["kills"]),
		"deaths": int(character.flags.get("stat_deaths", 0)) - int(visit["deaths"]),
	}


## Añade el registro al archivo (si está activada y el personaje es de verdad).
static func write(record: Dictionary, character: CharacterData, path := PATH) -> bool:
	if record.is_empty() or character == null or character.id == "" or not enabled():
		return false
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.seek_end()
	f.store_line(JSON.stringify(record))
	return true


static func read(path := PATH) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return out
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		var d = JSON.parse_string(line)
		if d is Dictionary:
			out.append(d)
	return out


## Resumen por `key` ("zone" o "class"): {valor: {visits, seconds, deaths, kills, dps (media
## de las visitas con combate), deaths_per_hour, kills_per_min}}.
static func summarize(records: Array, key := "zone") -> Dictionary:
	var out := {}
	for r in records:
		var k := String(r.get(key, "?"))
		if not out.has(k):
			out[k] = {"visits": 0, "seconds": 0.0, "deaths": 0, "kills": 0, "dps_sum": 0.0, "dps_n": 0}
		var s: Dictionary = out[k]
		s["visits"] += 1
		s["seconds"] += float(r.get("seconds", 0.0))
		s["deaths"] += int(r.get("deaths", 0))
		s["kills"] += int(r.get("kills", 0))
		if int(r.get("dps", 0)) > 0:
			s["dps_sum"] += float(r["dps"])
			s["dps_n"] += 1
	for k in out:
		var s: Dictionary = out[k]
		var hours := float(s["seconds"]) / 3600.0
		s["dps"] = roundi(float(s["dps_sum"]) / s["dps_n"]) if int(s["dps_n"]) > 0 else 0
		s["deaths_per_hour"] = snappedf(s["deaths"] / hours, 0.1) if hours > 0.0 else 0.0
		s["kills_per_min"] = snappedf(s["kills"] / (hours * 60.0), 0.1) if hours > 0.0 else 0.0
		s.erase("dps_sum")
		s.erase("dps_n")
	return out
