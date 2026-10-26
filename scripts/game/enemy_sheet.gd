class_name EnemySheet
## Cuadrícula de la hoja de sprites de los enemigos (T101), generada por
## tools/generate_enemy_sprites.gd (o dibujada a mano con la misma cuadrícula):
## - Columnas: andar (6), atacar (4), recibir golpe (2) y morir (6) = 18 cuadros.
## - Filas: tres por tipo (sprite_row en data/enemies.json): mirando abajo, arriba
##   y de lado (de lado mira a la derecha; el shader lo voltea para la izquierda).
## Cada celda mide S×S píxeles.

const S := 32
const WALK := 0
const WALK_FRAMES := 6
const ATTACK := 6
const ATTACK_FRAMES := 4
const HURT := 10
const HURT_FRAMES := 2
const DIE := 12
const DIE_FRAMES := 6
const COLUMNS := 18
enum Dir { DOWN, UP, SIDE }
const DIRS := 3
const WALK_FPS := 9.0
## Segundos que dura la animación de morir (el cadáver se queda en el último cuadro).
const DIE_TIME := 0.5


static func row(type_row: int, dir: int) -> int:
	return type_row * DIRS + dir


static func region(type_row: int, dir: int, column: int) -> Rect2:
	return Rect2(column * S, row(type_row, dir) * S, S, S)


## Hacia dónde mira según hacia dónde va (o hacia quién mira): de lado si lo
## horizontal pesa más, si no arriba o abajo.
static func dir_for(v: Vector2) -> int:
	if v.length_squared() < 0.01:
		return Dir.DOWN
	if absf(v.x) >= absf(v.y) * 0.8:
		return Dir.SIDE
	return Dir.UP if v.y < 0.0 else Dir.DOWN


## Columna del cuadro según el estado:
## - "walk": anda en bucle (`time` + `phase`).
## - "idle": respira con los dos primeros cuadros de andar, despacio.
## - "attack": `t` 0..1 de la preparación al golpe.
## - "hurt": `t` 0..1 del destello del golpe recibido.
## - "die": `t` segundos desde que murió.
static func column_for(state: String, t: float, phase := 0.0) -> int:
	match state:
		"walk":
			return WALK + posmod(int(floor(t * WALK_FPS + phase)), WALK_FRAMES)
		"attack":
			return ATTACK + clampi(int(t * ATTACK_FRAMES), 0, ATTACK_FRAMES - 1)
		"hurt":
			return HURT + (0 if t > 0.5 else 1)
		"die":
			return DIE + clampi(int(t / DIE_TIME * DIE_FRAMES), 0, DIE_FRAMES - 1)
	return WALK + posmod(int(floor(t * 2.0 + phase)), 2)
