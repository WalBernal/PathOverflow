class_name Nemesis
## Némesis: el élite que te mató (golpe en los últimos segundos) vuelve a aparecer
## en las zonas de combate de ese acto, más fuerte cada vez que te vuelve a matar,
## con tu nombre en el suyo. Al vencerlo suelta botín mucho mejor y se olvida.
## flags["nemesis"] = {type, name, affixes, zone, act, kills}.

const FLAG := "nemesis"
## Solo cuenta si el golpe fue hace poco (no un élite que te rozó hace un minuto).
const RECENT_MS := 4000
## Vuelve seguro a la zona donde te mató; en las demás del acto, a veces.
const ELSEWHERE_CHANCE := 0.35


static func current(c: CharacterData) -> Dictionary:
	var n = c.flags.get(FLAG, {})
	return n if n is Dictionary else {}


## Al morir: si te mató un élite (o tu némesis otra vez), lo recuerda. Devuelve
## true si hay némesis nuevo o más fuerte.
static func record(c: CharacterData, hitter: Dictionary, zone_id: String, act_id: String, now_ms: int) -> bool:
	if hitter.is_empty() or now_ms - int(hitter.get("time", -100000)) > RECENT_MS:
		return false
	var n := current(c)
	if hitter.get("nemesis", false) and not n.is_empty():
		n["kills"] = int(n.get("kills", 1)) + 1
		c.flags[FLAG] = n
		return true
	if int(hitter.get("rarity", 0)) != Rarity.Enemy.ELITE:
		return false
	c.flags[FLAG] = {"type": hitter.get("type", ""), "name": hitter.get("name", "Élite"), "affixes": hitter.get("affixes", []),
		"zone": zone_id, "act": act_id, "kills": 1}
	return true


static func title(c: CharacterData) -> String:
	var n := current(c)
	var t := "%s, Azote de %s" % [n.get("name", "Élite"), c.character_name if c.character_name != "" else "ti"]
	return t + (" (×%d)" % int(n["kills"]) if int(n.get("kills", 1)) > 1 else "")


## Vida: el doble y medio de un élite, y un 30 % más por cada vez que te volvió a matar.
static func life_mult(c: CharacterData) -> float:
	return 2.5 * (1.0 + 0.3 * (int(current(c).get("kills", 1)) - 1))


static func should_spawn(c: CharacterData, zone_id: String, act_id: String, roll: float) -> bool:
	var n := current(c)
	if n.is_empty() or String(n.get("act", "")) != act_id:
		return false
	return zone_id == String(n.get("zone", "")) or roll < ELSEWHERE_CHANCE


static func defeated(c: CharacterData) -> void:
	c.flags.erase(FLAG)
	c.flags["stat_nemesis"] = int(c.flags.get("stat_nemesis", 0)) + 1
