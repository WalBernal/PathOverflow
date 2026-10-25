class_name Atlas
## Atlas de incidentes (parte 2): progresión y mapas. Completar un incidente
## (limpiar la zona) la marca en el atlas; cada COMPLETIONS_PER_TIER zonas distintas
## sube el nivel del atlas (incidentes más difíciles y con más botín). Los mapas son
## incidentes guardados (zona + modificadores) que caen al completarlos y de los
## élites dentro; se abren desde la pantalla de atlas.
## flags["atlas"] = {done: [ids de zona], maps: [{zone, mods, name}]}.

const FLAG := "atlas"
const COMPLETIONS_PER_TIER := 3
const MAX_TIER := 10
const MAX_MAPS := 12
## Por nivel del atlas por encima del 1: +2 niveles de zona y +10 % de botín.
const LEVEL_PER_TIER := 2
const LOOT_PER_TIER := 0.1
const ELITE_MAP_CHANCE := 0.15


static func data(c: CharacterData) -> Dictionary:
	var d = c.flags.get(FLAG, {})
	if not d is Dictionary:
		d = {}
	if not d.has("done"):
		d["done"] = []
	if not d.has("maps"):
		d["maps"] = []
	c.flags[FLAG] = d
	return d


static func done(c: CharacterData) -> Array:
	return data(c)["done"]


static func tier(c: CharacterData) -> int:
	return clampi(1 + done(c).size() / COMPLETIONS_PER_TIER, 1, MAX_TIER)


static func level_bonus(c: CharacterData) -> int:
	return LEVEL_PER_TIER * (tier(c) - 1)


static func loot_bonus(c: CharacterData) -> float:
	return LOOT_PER_TIER * (tier(c) - 1)


## Marca la zona como completada. Devuelve true si sube el nivel del atlas.
static func mark_done(c: CharacterData, zone_id: String) -> bool:
	var before := tier(c)
	var list: Array = done(c)
	if not list.has(zone_id):
		list.append(zone_id)
	return tier(c) > before


static func maps(c: CharacterData) -> Array:
	return data(c)["maps"]


## Guarda un mapa (si cabe). false si ya tienes MAX_MAPS.
static func add_map(c: CharacterData, m: Dictionary) -> bool:
	var list: Array = maps(c)
	if list.size() >= MAX_MAPS:
		return false
	list.append(m)
	return true


static func take_map(c: CharacterData, index: int) -> Dictionary:
	var list: Array = maps(c)
	if index < 0 or index >= list.size():
		return {}
	var m: Dictionary = list[index]
	list.remove_at(index)
	return m


## Un mapa al azar: una zona que vale como incidente y 2-3 modificadores (3 desde el nivel 3 del atlas).
static func roll_map(zones: Dictionary, level: int, atlas_tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var pool := Incidents.candidates(zones, level)
	if pool.is_empty():
		return {}
	var z: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var ids: Array = Incidents.MODS.keys()
	var mods: Array = []
	var n := 3 if atlas_tier >= 3 else rng.randi_range(2, 3)
	while mods.size() < n:
		var m: String = ids[rng.randi_range(0, ids.size() - 1)]
		if not mods.has(m):
			mods.append(m)
	return {"zone": z["id"], "mods": mods, "name": "Mapa: %s" % z.get("name", z["id"])}
