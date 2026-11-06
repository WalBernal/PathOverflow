class_name ZoneReport
## Resumen al salir de una zona de combate (T214), con el formato de un informe de build:
## cuánto se tardó, los enemigos («procesos terminados»), la experiencia, el botín bueno
## («artefactos») y, si hubo muertes, la más tonta (la del enemigo de menor rareza).
## La visita (World._visit, de Telemetry.begin) guarda lo que hace falta mientras dura.

const MIN_SECONDS := 20.0   # visitas más cortas (entrar y salir) no merecen informe
const MAX_LOOT := 3
const LOOT_FROM := Rarity.Item.RARE


## Lo que el informe necesita además de la telemetría, al empezar la visita.
static func begin(visit: Dictionary, character: CharacterData) -> void:
	visit["xp_start"] = character.experience
	visit["level_start"] = character.level
	visit["loot"] = []


## Un objeto recogido: entra en «artefactos» si es raro o mejor (los mejores primero, hasta MAX_LOOT).
static func note_loot(visit: Dictionary, item: Item) -> void:
	if visit.is_empty() or item == null or item.rarity < LOOT_FROM:
		return
	var loot: Array = visit.get("loot", [])
	loot.append({"name": item.display_name(), "rarity": item.rarity})
	loot.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rarity"]) > int(b["rarity"]))
	visit["loot"] = loot.slice(0, MAX_LOOT)


## Una muerte: se queda la más tonta, la del enemigo de menor rareza (`hitter`, de EnemyManager.last_hitter).
static func note_death(visit: Dictionary, hitter: Dictionary) -> void:
	if visit.is_empty():
		return
	var old: Dictionary = visit.get("death", {})
	var rarity := int(hitter.get("rarity", Rarity.Enemy.UNIQUE))
	if old.is_empty() or rarity < int(old["rarity"]):
		visit["death"] = {"name": String(hitter.get("name", "algo")), "rarity": rarity}


static func worth_showing(record: Dictionary, safe_zone: bool) -> bool:
	return not safe_zone and float(record.get("seconds", 0.0)) >= MIN_SECONDS


static func _duration(seconds: float) -> String:
	var s := roundi(seconds)
	return "%d s" % s if s < 60 else "%d min %02d s" % [s / 60, s % 60]


## Las líneas del informe: [texto, tipo] con tipo "ok", "fail", "info" o "loot".
static func lines(record: Dictionary, visit: Dictionary, zone_name: String, xp_now: int, level_now: int) -> Array:
	var deaths := int(record.get("deaths", 0))
	var out := []
	var status := "OK" if deaths == 0 else "FAILED (%d %s)" % [deaths, "muerte" if deaths == 1 else "muertes"]
	out.append(["$ build %s — %s en %s" % [zone_name, status, _duration(float(record.get("seconds", 0.0)))], "ok" if deaths == 0 else "fail"])
	out.append(["procesos terminados: %d" % int(record.get("kills", 0)), "info"])
	var level_from := int(visit.get("level_start", level_now))
	var xp_line := "experiencia: +%d" % maxi(0, xp_now - int(visit.get("xp_start", xp_now))) if level_now == level_from \
		else "experiencia: subes de nivel %d → %d" % [level_from, level_now]
	out.append([xp_line, "info"])
	if int(record.get("dps", 0)) > 0:
		out.append(["DPS medio en combate: %d" % int(record["dps"]), "info"])
	var loot: Array = visit.get("loot", [])
	if loot.is_empty():
		out.append(["artefactos: nada digno de un commit", "info"])
	for l in loot:
		out.append(["artefacto: %s (%s)" % [l["name"], Rarity.item_name(int(l["rarity"])).to_lower()], "loot:%d" % int(l["rarity"])])
	var death: Dictionary = visit.get("death", {})
	if not death.is_empty():
		var who := String(death["name"])
		var how := "un «%s» normal. Sin afijos. Nada." % who if int(death["rarity"]) == Rarity.Enemy.NORMAL \
			else "«%s» (%s)" % [who, Rarity.ENEMY_INFO[int(death["rarity"])]["name"].to_lower()]
		out.append(["la muerte más tonta: %s" % how, "fail"])
	return out
