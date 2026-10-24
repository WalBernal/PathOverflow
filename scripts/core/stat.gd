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
const MANA_REGEN := &"mana_regen"
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
const COOLDOWN_RECOVERY := &"cooldown_recovery"
const SKILL_DURATION := &"skill_duration"
## Stats especiales (ascendencias): cambian cómo funcionan las habilidades.
const EXTRA_PROJECTILES := &"extra_projectiles"
const EXTRA_CHAINS := &"extra_chains"
const EXTRA_MINIONS := &"extra_minions"
const EXTRA_DEVICES := &"extra_devices"
## Robot de compañía (ascendencia Ingeniero en Robótica): 1 = lo tiene.
const COMPANION_ROBOT := &"companion_robot"
## Estados alterados (ver Ailments): probabilidad plana (%) de aplicarlos al golpear.
const BURN_CHANCE := &"burn_chance"
const SHOCK_CHANCE := &"shock_chance"
const CHILL_CHANCE := &"chill_chance"
const FREEZE_CHANCE := &"freeze_chance"
const POISON_CHANCE := &"poison_chance"
const BLEED_CHANCE := &"bleed_chance"
## Daño, duración y efecto de los estados alterados que aplicas.
const AILMENT_DAMAGE := &"ailment_damage"
const AILMENT_DURATION := &"ailment_duration"
## Velocidad de los autómatas (torretas, drones, esbirros, robots): más disparos y golpes.
const AUTOMATON_SPEED := &"automaton_speed"
## Maná reservado por las invocaciones persistentes (menos es mejor).
const RESERVATION_EFFICIENCY := &"reservation_efficiency"
## Daño contra enemigos que ya sufren algún estado alterado.
const AILING_DAMAGE := &"ailing_damage"
## Potencia de las interacciones entre estados (rotura, choque térmico, sobrecarga,
## infección, superconductor).
const INTERACTION_EFFECT := &"interaction_effect"
## Potencia de las auras.
const AURA_EFFECT := &"aura_effect"
## Vida que se recupera al matar (plano) y daño de espinas a los enemigos cercanos al recibir un golpe.
const LIFE_ON_KILL := &"life_on_kill"
## Habilidades únicas de ascendencia (las procesa SkillController):
## % de que un enemigo que matas explote (fuego, alrededor).
const KILL_EXPLOSION := &"kill_explosion"
## Pulso de estática cada 3 s: daño de rayo = valor × nivel alrededor tuyo.
const STATIC_PULSE := &"static_pulse"
## % de soltar una nova de hielo al recibir un golpe (daña y aturde).
const RETALIATION_NOVA := &"retaliation_nova"
## Cargas (ver Charges): probabilidad extra de ganarlas y máximo extra.
const BUFFER_CHARGE_CHANCE := &"buffer_charge_chance"
const MULTIHILO_CHARGE_CHANCE := &"multihilo_charge_chance"
const OVERCLOCK_CHARGE_CHANCE := &"overclock_charge_chance"
const MAX_BUFFER_CHARGES := &"max_buffer_charges"
const MAX_MULTIHILO_CHARGES := &"max_multihilo_charges"
const MAX_OVERCLOCK_CHARGES := &"max_overclock_charges"
const THORNS := &"thorns"
## Enemigos extra que atraviesan los proyectiles (suma a la RAM de perforación).
const EXTRA_PIERCE := &"extra_pierce"
## % menos de duración de electrocutado, helado y congelado sobre ti.
const STATUS_RESIST := &"status_resist"
## Cargas de esquiva (git stash) extra.
const DODGE_CHARGES := &"dodge_charges"
## Escudo de energía que se regenera por segundo siempre (aparte de la recarga tras no recibir daño).
const ENERGY_SHIELD_REGEN := &"energy_shield_regen"
## % menos de coste de maná de las habilidades (máximo 50 %).
const MANA_COST_REDUCTION := &"mana_cost_reduction"

# --- Tags (condiciones de los modificadores) ---
const TAG_ATTACK := &"attack"
const TAG_SPELL := &"spell"
const TAG_MELEE := &"melee"
const TAG_PROJECTILE := &"projectile"
const TAG_AREA := &"area"
const TAG_MOVEMENT := &"movement"
# Condiciones: modificadores que solo aplican mientras se cumplen (ver CharacterData.condition_tags).
const COND_LOW_LIFE := &"low_life"
const COND_FULL_LIFE := &"full_life"
const COND_RECENT_KILL := &"recent_kill"

const RESISTANCE_CAP := 75.0

const NAMES := {
	STRENGTH: "Fuerza",
	DEXTERITY: "Destreza",
	INTELLIGENCE: "Inteligencia",
	LIFE: "Vida máxima",
	MANA: "Maná máximo",
	ENERGY_SHIELD: "Escudo de energía",
	LIFE_REGEN: "Regeneración de vida por segundo",
	MANA_REGEN: "Regeneración de maná",
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
	COOLDOWN_RECOVERY: "Recuperación de enfriamientos",
	SKILL_DURATION: "Duración de habilidades",
	EXTRA_PROJECTILES: "Proyectiles adicionales",
	EXTRA_CHAINS: "Encadenamientos adicionales",
	EXTRA_MINIONS: "Esbirros adicionales",
	EXTRA_DEVICES: "Trampas, minas y torretas adicionales a la vez",
	COMPANION_ROBOT: "Robot de compañía (Láser de rastreo y Pulso EMP)",
	BURN_CHANCE: "Probabilidad de quemar",
	SHOCK_CHANCE: "Probabilidad de electrocutar",
	CHILL_CHANCE: "Probabilidad de helar",
	FREEZE_CHANCE: "Probabilidad de congelar",
	POISON_CHANCE: "Probabilidad de envenenar",
	BLEED_CHANCE: "Probabilidad de hacer sangrar",
	AILMENT_DAMAGE: "Daño y efecto de estados alterados",
	AILMENT_DURATION: "Duración de estados alterados",
	AUTOMATON_SPEED: "Velocidad de autómatas",
	RESERVATION_EFFICIENCY: "Eficiencia de reserva de maná",
	AILING_DAMAGE: "Daño contra enemigos con estados alterados",
	INTERACTION_EFFECT: "Efecto de las interacciones de estados",
	AURA_EFFECT: "Efecto de auras",
	LIFE_ON_KILL: "Vida al matar",
	KILL_EXPLOSION: "Probabilidad de que los enemigos que matas exploten (fuego)",
	STATIC_PULSE: "Pulso de estática cada 3 s (daño de rayo por nivel)",
	RETALIATION_NOVA: "Probabilidad de soltar una nova de hielo al recibir un golpe",
	BUFFER_CHARGE_CHANCE: "Probabilidad de ganar una carga de Buffer al recibir un golpe",
	MULTIHILO_CHARGE_CHANCE: "Probabilidad de ganar una carga de Multihilos al matar",
	OVERCLOCK_CHARGE_CHANCE: "Probabilidad de ganar una carga de Overclock al hacer un crítico",
	MAX_BUFFER_CHARGES: "Cargas de Buffer máximas",
	MAX_MULTIHILO_CHARGES: "Cargas de Multihilos máximas",
	MAX_OVERCLOCK_CHARGES: "Cargas de Overclock máximas",
	THORNS: "Daño de espinas al recibir un golpe",
	EXTRA_PIERCE: "Enemigos extra que atraviesan los proyectiles",
	STATUS_RESIST: "Resistencia a estados (electrocutado, helado, congelado)",
	DODGE_CHARGES: "Cargas de esquiva",
	ENERGY_SHIELD_REGEN: "Regeneración de escudo de energía por segundo",
	MANA_COST_REDUCTION: "Reducción del coste de maná",
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
	BURN_CHANCE, SHOCK_CHANCE, CHILL_CHANCE, FREEZE_CHANCE, POISON_CHANCE, BLEED_CHANCE, STATUS_RESIST,
	KILL_EXPLOSION, RETALIATION_NOVA, BUFFER_CHARGE_CHANCE, MULTIHILO_CHARGE_CHANCE, OVERCLOCK_CHARGE_CHANCE,
	MANA_COST_REDUCTION,
]

const TAG_NAMES := {
	TAG_ATTACK: "con ataques",
	TAG_SPELL: "con hechizos",
	TAG_MELEE: "cuerpo a cuerpo",
	TAG_PROJECTILE: "de proyectiles",
	TAG_AREA: "de área",
	TAG_MOVEMENT: "de movimiento",
	&"trap": "de trampas",
	&"mine": "de minas",
	&"totem": "de torretas",
	&"minion": "de esbirros",
	&"chain": "de cadenas",
	&"duration": "de duración",
	&"automaton": "de autómatas",
	&"aura": "de auras",
	&"persistent": "persistentes",
	&"physical": "físicas",
	&"fire": "de fuego",
	&"cold": "de frío",
	&"lightning": "de rayo",
	&"chaos": "de caos",
	&"elemental": "elementales",
	&"golem": "de golems",
	COND_LOW_LIFE: "con la vida baja",
	COND_FULL_LIFE: "con la vida al máximo",
	COND_RECENT_KILL: "si has matado recientemente",
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
