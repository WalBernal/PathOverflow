class_name Stat
## Identificadores de stats y tags (StringName para comparaciones baratas).
## Para añadir un stat nuevo: constante + nombre en NAMES (+ PARENTS si hereda
## los aumentos de otro stat, + PERCENT_STATS si su valor plano es un %).

# --- Atributos ---
const STRENGTH := &"strength"
const DEXTERITY := &"dexterity"
const INTELLIGENCE := &"intelligence"

# --- Defensa ---
const LIFE := &"life"
const MANA := &"mana"
const ENERGY_SHIELD := &"energy_shield"
const LIFE_REGEN := &"life_regen"
const ARMOUR := &"armour"
const EVASION := &"evasion"
const BLOCK_CHANCE := &"block_chance"
const FIRE_RES := &"fire_res"
const COLD_RES := &"cold_res"
const LIGHTNING_RES := &"lightning_res"
const CHAOS_RES := &"chaos_res"

# --- Ofensiva ---
const DAMAGE := &"damage"
const PHYSICAL_DAMAGE := &"physical_damage"
const ELEMENTAL_DAMAGE := &"elemental_damage"
const FIRE_DAMAGE := &"fire_damage"
const COLD_DAMAGE := &"cold_damage"
const LIGHTNING_DAMAGE := &"lightning_damage"
const CHAOS_DAMAGE := &"chaos_damage"
const MINION_DAMAGE := &"minion_damage"
const MINION_LIFE := &"minion_life"
const ATTACK_SPEED := &"attack_speed"
const CAST_SPEED := &"cast_speed"
const CRIT_CHANCE := &"crit_chance"
const CRIT_MULTIPLIER := &"crit_multiplier"
const ACCURACY := &"accuracy"
const AREA_OF_EFFECT := &"area_of_effect"
const PROJECTILE_SPEED := &"projectile_speed"
const MOVEMENT_SPEED := &"movement_speed"
const LIFE_LEECH := &"life_leech"

# --- Tags (condiciones de los modificadores) ---
const TAG_ATTACK := &"attack"
const TAG_SPELL := &"spell"
const TAG_MELEE := &"melee"
const TAG_PROJECTILE := &"projectile"
const TAG_AREA := &"area"
const TAG_MOVEMENT := &"movement"

const RESISTANCE_CAP := 75.0

const NAMES := {
	STRENGTH: "Fuerza",
	DEXTERITY: "Destreza",
	INTELLIGENCE: "Inteligencia",
	LIFE: "Vida máxima",
	MANA: "Maná máximo",
	ENERGY_SHIELD: "Escudo de energía",
	LIFE_REGEN: "Regeneración de vida por segundo",
	ARMOUR: "Armadura",
	EVASION: "Evasión",
	BLOCK_CHANCE: "Probabilidad de bloqueo",
	FIRE_RES: "Resistencia al fuego",
	COLD_RES: "Resistencia al frío",
	LIGHTNING_RES: "Resistencia al rayo",
	CHAOS_RES: "Resistencia al caos",
	DAMAGE: "Daño",
	PHYSICAL_DAMAGE: "Daño físico",
	ELEMENTAL_DAMAGE: "Daño elemental",
	FIRE_DAMAGE: "Daño de fuego",
	COLD_DAMAGE: "Daño de frío",
	LIGHTNING_DAMAGE: "Daño de rayo",
	CHAOS_DAMAGE: "Daño de caos",
	MINION_DAMAGE: "Daño de esbirros",
	MINION_LIFE: "Vida de esbirros",
	ATTACK_SPEED: "Velocidad de ataque",
	CAST_SPEED: "Velocidad de lanzamiento",
	CRIT_CHANCE: "Probabilidad de crítico",
	CRIT_MULTIPLIER: "Multiplicador de crítico",
	ACCURACY: "Precisión",
	AREA_OF_EFFECT: "Área de efecto",
	PROJECTILE_SPEED: "Velocidad de proyectiles",
	MOVEMENT_SPEED: "Velocidad de movimiento",
	LIFE_LEECH: "Robo de vida",
}

## Los aumentos/más de los padres también aplican al hijo:
## "10% de aumento de Daño" afecta al Daño de fuego, como en PoE.
const PARENTS := {
	PHYSICAL_DAMAGE: [DAMAGE],
	ELEMENTAL_DAMAGE: [DAMAGE],
	FIRE_DAMAGE: [ELEMENTAL_DAMAGE, DAMAGE],
	COLD_DAMAGE: [ELEMENTAL_DAMAGE, DAMAGE],
	LIGHTNING_DAMAGE: [ELEMENTAL_DAMAGE, DAMAGE],
	CHAOS_DAMAGE: [DAMAGE],
}

const PERCENT_STATS := [
	BLOCK_CHANCE, FIRE_RES, COLD_RES, LIGHTNING_RES, CHAOS_RES, CRIT_MULTIPLIER, LIFE_LEECH,
]

const TAG_NAMES := {
	TAG_ATTACK: "con ataques",
	TAG_SPELL: "con hechizos",
	TAG_MELEE: "cuerpo a cuerpo",
	TAG_PROJECTILE: "de proyectiles",
	TAG_AREA: "de área",
	TAG_MOVEMENT: "de movimiento",
}

## Stat de daño de cada tipo de daño de las habilidades.
const DAMAGE_STAT_BY_TYPE := {
	"physical": PHYSICAL_DAMAGE,
	"fire": FIRE_DAMAGE,
	"cold": COLD_DAMAGE,
	"lightning": LIGHTNING_DAMAGE,
	"chaos": CHAOS_DAMAGE,
}


static func exists(id: StringName) -> bool:
	return NAMES.has(id)


static func display_name(id: StringName) -> String:
	return NAMES.get(id, String(id))


static func tag_name(tag: StringName) -> String:
	return TAG_NAMES.get(tag, String(tag))


static func is_percent(id: StringName) -> bool:
	return PERCENT_STATS.has(id)
