class_name Difficulty
## Dificultades: Normal, Pesadilla e Infierno (flags["difficulty"]). Pesadilla se
## abre al terminar el Acto IV; Infierno, al terminarlo en Pesadilla. Se elige con
## Rafa en el campamento. Sube el nivel de las zonas de combate, las resistencias
## de los enemigos y sus afijos, y el botín; los jefes se pueden volver a pelear en
## cada dificultad (su bandera de completado lleva el sufijo _d1 / _d2).

const FLAG := "difficulty"
const NAMES := ["Normal", "Pesadilla", "Infierno"]
const COLORS := [Color("c8c8c8"), Color("c08aff"), Color("ff5a3a")]
const LEVEL_BONUS := [0, 12, 24]
## Resistencia extra de los enemigos a todos los tipos de daño (%).
const RESIST := [0, 20, 40]
## Afijos extra de los élites; los especiales tienen más probabilidad de tener uno.
const EXTRA_AFFIXES := [0, 1, 2]
const LOOT := [0.0, 0.3, 0.6]
const FINAL_FLAG := "act4_complete"


static func current(c: CharacterData) -> int:
	return clampi(int(c.flags.get(FLAG, 0)), 0, NAMES.size() - 1) if c else 0


## La más alta que puedes elegir.
static func unlocked(c: CharacterData) -> int:
	if c.flags.has(boss_flag(FINAL_FLAG, 1)):
		return 2
	if c.flags.has(FINAL_FLAG):
		return 1
	return 0


static func choose(c: CharacterData, d: int) -> bool:
	if d < 0 or d > unlocked(c):
		return false
	c.flags[FLAG] = d
	return true


## Bandera de completado de un jefe en esa dificultad (la de Normal, sin sufijo).
static func boss_flag(flag: String, d: int) -> String:
	return flag if d <= 0 else "%s_d%d" % [flag, d]


## Opción del personaje (Pausa): las zonas de combate de los actos ya terminados
## suben a tu nivel si estás por encima (para volver a ellas sin que se queden cortas).
const SCALING_FLAG := "zone_scaling"


static func scaling_enabled(c: CharacterData) -> bool:
	return c != null and c.flags.get(SCALING_FLAG, false)


## Nivel con el que se juega una zona: el suyo (o el tuyo, si está escalada y su
## acto ya está terminado) más el de la dificultad. Los campamentos no cambian.
static func zone_level(c: CharacterData, base_level: int, act_id: String, safe: bool) -> int:
	if safe:
		return base_level
	var level := base_level
	if scaling_enabled(c) and act_id != "" and c.flags.has("%s_complete" % act_id):
		level = maxi(level, c.level)
	return level + LEVEL_BONUS[current(c)]


static func describe(d: int) -> String:
	if d <= 0:
		return "Normal: el juego tal como es."
	return "%s: zonas +%d niveles, enemigos con +%d %% de resistencias y más afijos, +%d %% de botín." % [NAMES[d], LEVEL_BONUS[d], RESIST[d], roundi(LOOT[d] * 100.0)]
