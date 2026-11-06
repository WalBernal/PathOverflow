class_name Ladder
## Banco de oleadas sin fin y ladder local. Aída te manda a una zona que ya
## conoces, vacía, y desde ahí llegan oleadas cada vez más grandes (cada 5, un
## jefe de oleada) hasta que caes o sales por el portal. La zona se arma al vuelo
## como los incidentes (id ZONE_ID, no se guarda).
##
## Récords: los de cada personaje van en flags.ladder ({best_wave, best_time,
## bosses: {tipo: segundos}}); la tabla de todos los personajes de este equipo
## (top TOP_SIZE de oleadas y de cada jefe) en BOARD_PATH.

const ZONE_ID := "oleadas"
const BOARD_PATH := "user://ladder.json"
const TOP_SIZE := 10
## Cada cuántas oleadas sale un jefe de oleada (y sube un nivel el área).
const BOSS_EVERY := 5
const MAX_COUNT := 60


## Arma la arena: copia de una zona de combate de tu nivel (o `zone_id`), sin
## enemigos propios y con la salida al campamento. {} si no hay ninguna.
static func build_arena(zones: Dictionary, level: int, town: String, rng: RandomNumberGenerator, zone_id := "") -> Dictionary:
	var src: Dictionary = zones.get(zone_id, {}) if zone_id != "" else {}
	if src.is_empty():
		var pool := Incidents.candidates(zones, level)
		if pool.is_empty():
			return {}
		src = pool[rng.randi_range(0, pool.size() - 1)]
	var def: Dictionary = src.duplicate(true)
	def["id"] = ZONE_ID
	def["name"] = "Banco de oleadas: %s" % src.get("name", "")
	def["level"] = maxi(int(src.get("level", 1)), level)
	def["enemies"]["packs"] = 0
	def["waves_mode"] = {"from": src["id"]}
	for key in ["cutscene_on_enter", "quest_items", "key_items", "rare_spawns", "race_condition", "challenges", "waypoint", "npcs", "props", "locks", "subboss", "mutex"]:
		def.erase(key)
	var back: Vector2 = Vector2(def["exits"][0]["pos"][0], def["exits"][0]["pos"][1]) if not def.get("exits", []).is_empty() else Vector2(120, def["size"][1] / 2.0)
	def["exits"] = [{"pos": [back.x, back.y], "target": town, "entry": "waypoint", "label": "Salir del banco (al campamento)", "portal": true}]
	return def


## Cómo es la oleada `wave` (desde 1): {count, special_chance, elites, boss, level_bonus}.
static func wave_plan(wave: int) -> Dictionary:
	return {
		"count": mini(6 + wave * 2, MAX_COUNT),
		"special_chance": minf(0.5, 0.08 + 0.03 * wave),
		"elites": wave / 3,
		"boss": wave % BOSS_EVERY == 0,
		"level_bonus": wave / BOSS_EVERY,
	}


## Vida del jefe de oleada (crece con cada uno).
static func boss_life_mult(wave: int) -> float:
	return 2.0 + 0.5 * float(wave / BOSS_EVERY)


# --- Récords del personaje ---

static func personal(character: CharacterData) -> Dictionary:
	var l: Dictionary = character.flags.get("ladder", {})
	if not l.has("bosses"):
		l["bosses"] = {}
	character.flags["ladder"] = l
	return l


## Una partida de oleadas terminada (`waves` superadas en `seconds`). True si es
## récord: más oleadas, o las mismas en menos tiempo.
static func record_waves(character: CharacterData, waves: int, seconds: float) -> bool:
	if waves <= 0:
		return false
	var l := personal(character)
	var best := int(l.get("best_wave", 0))
	if waves > best or (waves == best and seconds < float(l.get("best_time", INF))):
		l["best_wave"] = waves
		l["best_time"] = seconds
		return true
	return false


## Jefe derrotado en `seconds` (desde que entraste a su zona). True si es récord.
static func record_boss(character: CharacterData, boss_id: String, seconds: float) -> bool:
	var bosses: Dictionary = personal(character)["bosses"]
	if seconds < float(bosses.get(boss_id, INF)):
		bosses[boss_id] = seconds
		return true
	return false


# --- Tabla local (todos los personajes) ---

static func load_board(path := BOARD_PATH) -> Dictionary:
	var board: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			board = parsed
	if not board.get("waves") is Array:
		board["waves"] = []
	if not board.get("bosses") is Dictionary:
		board["bosses"] = {}
	return board


static func save_board(board: Dictionary, path := BOARD_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(board, "\t"))


static func entry(character: CharacterData, waves: int, seconds: float) -> Dictionary:
	return {"name": character.character_name, "class": String(character.class_def.get("name", "")), "level": character.level,
		"waves": waves, "time": snappedf(seconds, 0.1), "date": Time.get_date_string_from_system()}


## Mete la partida en la tabla de oleadas (más oleadas, luego menos tiempo).
## Devuelve el puesto (1 = primero) o 0 si no entra en el top.
static func submit_waves(board: Dictionary, e: Dictionary) -> int:
	var list: Array = board["waves"]
	list.append(e)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["waves"]) > int(b["waves"]) or (int(a["waves"]) == int(b["waves"]) and float(a["time"]) < float(b["time"])))
	board["waves"] = list.slice(0, TOP_SIZE)
	return board["waves"].find(e) + 1


## Igual para el tiempo contra un jefe (menos es mejor).
static func submit_boss(board: Dictionary, boss_id: String, e: Dictionary) -> int:
	var list: Array = board["bosses"].get(boss_id, [])
	list.append(e)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))
	board["bosses"][boss_id] = list.slice(0, TOP_SIZE)
	return board["bosses"][boss_id].find(e) + 1


static func format_time(seconds: float) -> String:
	var s := int(round(seconds))
	return "%d:%02d" % [s / 60, s % 60]
