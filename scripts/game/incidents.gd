class_name Incidents
## Atlas de incidentes (parte 1): una zona de combate al azar que ya puedes jugar,
## de tu nivel, con 2-3 modificadores que la ponen difícil (más enemigos, que
## explotan, sin regeneración...) a cambio de más botín. Se abre desde el puesto de
## Aida y se vuelve por un portal al campamento del acto. La zona se arma al vuelo
## (id ZONE_ID, no se guarda: si sales del juego dentro, vuelves al campamento).

const ZONE_ID := "incidente"
## {name, text, loot (botín extra, se suma), y lo que cambia: packs (×), elite (×),
## affix (afijo que llevan todos los enemigos) o player (mods para el jugador)}.
const MODS := {
	"denso": {"name": "Pico de tráfico", "text": "50 % más de grupos de enemigos", "loot": 0.35, "packs": 1.5},
	"explosivos": {"name": "Procesos zombi", "text": "Los enemigos explotan al morir", "loot": 0.3, "affix": "explosivo"},
	"veloces": {"name": "Hilos desbocados", "text": "Los enemigos son mucho más rápidos", "loot": 0.25, "affix": "veloz"},
	"blindados": {"name": "Firewall mal configurado", "text": "Los enemigos tienen más armadura y resistencias", "loot": 0.3, "affix": "blindado"},
	"elites": {"name": "Escalada de privilegios", "text": "El doble de élites", "loot": 0.4, "elite": 2.0},
	"sin_regen": {"name": "Fuga de memoria", "text": "No regeneras vida", "loot": 0.3,
		"player": [{"stat": "life_regen", "type": "more", "value": -100}]},
	"maldito": {"name": "Configuración por defecto", "text": "−20 a todas tus resistencias", "loot": 0.3,
		"player": [{"stat": "fire_res", "type": "flat", "value": -20}, {"stat": "cold_res", "type": "flat", "value": -20},
			{"stat": "lightning_res", "type": "flat", "value": -20}, {"stat": "chaos_res", "type": "flat", "value": -20}]},
}


## Zonas que valen como incidente: de combate (no campamentos, jefes ni el tutorial)
## y de un nivel que el personaje ya alcanzó (+3).
static func candidates(zones: Dictionary, level: int) -> Array:
	var out: Array = []
	for id in zones:
		var z: Dictionary = zones[id]
		if id == ZONE_ID or id == "tutorial" or z.get("safe", false) or z.has("boss") or not z.get("enemies") is Dictionary:
			continue
		if int(z.get("level", 1)) <= level + 3:
			out.append(z)
	return out


## Arma el incidente: copia de una zona al azar, al nivel del personaje, con sus
## modificadores y la salida al campamento. {} si no hay ninguna zona posible.
static func build(zones: Dictionary, level: int, town: String, rng: RandomNumberGenerator, count := -1) -> Dictionary:
	var pool := candidates(zones, level)
	if pool.is_empty():
		return {}
	var src: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var def: Dictionary = src.duplicate(true)
	var ids: Array = MODS.keys()
	for k in range(ids.size() - 1, 0, -1):   # barajar con el rng (para que las pruebas se repitan)
		var j := rng.randi_range(0, k)
		var tmp = ids[k]
		ids[k] = ids[j]
		ids[j] = tmp
	var mods: Array = ids.slice(0, count if count > 0 else rng.randi_range(2, 3))
	var loot := 1.0
	var en: Dictionary = def["enemies"]
	for m in mods:
		var info: Dictionary = MODS[m]
		loot += float(info["loot"])
		if info.has("packs"):
			en["packs"] = int(ceil(float(en.get("packs", 8)) * float(info["packs"])))
		if info.has("elite"):
			en["elite_chance"] = minf(0.6, float(en.get("elite_chance", 0.1)) * float(info["elite"]))
	def["id"] = ZONE_ID
	def["name"] = "Incidente: %s" % src.get("name", "")
	def["level"] = maxi(int(src.get("level", 1)), level)
	def["drop_multiplier"] = float(def.get("drop_multiplier", 1.0)) * loot
	def["incident"] = {"mods": mods, "from": src["id"]}
	for key in ["cutscene_on_enter", "quest_items", "key_items", "rare_spawns", "race_condition", "challenges", "waypoint", "npcs", "props", "locks", "subboss"]:
		def.erase(key)
	var back: Vector2 = Vector2(def["exits"][0]["pos"][0], def["exits"][0]["pos"][1]) if not def.get("exits", []).is_empty() else Vector2(120, def["size"][1] / 2.0)
	def["exits"] = [{"pos": [back.x, back.y], "target": town, "entry": "waypoint", "label": "Cerrar el incidente (al campamento)", "portal": true}]
	return def


## Afijos que llevan todos los enemigos del incidente.
static func forced_affixes(def: Dictionary) -> Array:
	var out: Array = []
	for m in def.get("incident", {}).get("mods", []):
		if MODS[m].has("affix"):
			out.append(MODS[m]["affix"])
	return out


## Mods para el jugador mientras está en el incidente.
static func player_mods(def: Dictionary) -> Array[Modifier]:
	var out: Array[Modifier] = []
	for m in def.get("incident", {}).get("mods", []):
		for md in MODS[m].get("player", []):
			out.append(Modifier.from_dict(md, "incident"))
	return out


static func describe(def: Dictionary) -> String:
	var lines := PackedStringArray()
	for m in def.get("incident", {}).get("mods", []):
		lines.append("%s: %s" % [MODS[m]["name"], MODS[m]["text"]])
	return "\n".join(lines)
