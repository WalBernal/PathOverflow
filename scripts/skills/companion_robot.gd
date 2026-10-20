class_name CompanionRobot
## Robot de compañía R-2PL (ascendencia Ingeniero en Robótica del DevOps):
## sigue al jugador y usa su propio kit de dos habilidades. SkillController lo
## mueve, dispara y dibuja.

## Kit del robot de compañía: dos habilidades propias, calculadas con SkillCalc
## (las mejoras de esbirros del personaje le afectan).
const LASER := {"id": "robot_laser", "name": "Láser de rastreo", "kind": "homing", "damage_type": "lightning",
	"attribute": "int", "tags": ["spell", "projectile", "lightning", "elemental", "minion", "automaton"],
	"spell": {"base_damage": [6, 11], "damage_growth": 0.16, "cast_time": 1.0, "crit": 5.0},
	"projectiles": 1, "spread_degrees": 0, "projectile_speed": 650, "range": 720, "seek_range": 540, "turn_rate": 8.0,
	"mana_cost": 0, "cooldown": 0}
const EMP := {"id": "robot_emp", "name": "Pulso EMP", "kind": "nova", "damage_type": "lightning",
	"attribute": "int", "tags": ["spell", "area", "lightning", "elemental", "minion", "automaton"],
	"spell": {"base_damage": [10, 18], "damage_growth": 0.15, "cast_time": 1.0, "crit": 5.0},
	"radius": 130, "stun": 1.2, "mana_cost": 0, "cooldown": 0}
const LASER_INTERVAL := 1.1
const EMP_INTERVAL := 7.0
