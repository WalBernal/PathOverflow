class_name PlayerSheet
## Cuadrícula de las hojas del personaje por capas (T102a), horneadas con
## tools/bake_player_sprites.gd a partir del dibujo de CharacterAppearance:
## - Columnas: los estados de T72 con sus cuadros (ver STATES).
## - Filas: mirando abajo, arriba y de lado (a la derecha; a la izquierda se voltea).
##   Las capas con variantes (pelo, barba, accesorio, arma) van en un archivo por
##   variante (file_of).
## - Celdas de CW×CH con los pies en FEET, a la escala del juego (BAKE_SCALE).
## Capas de máscara (cuerpo, pelo, barba, accesorio): R = luz (0..1), G = capa
## (LAYER_* / 8) y alfa; se tiñen con los colores del creador (PlayerSprite).
## Capas fijas (detalles del cuerpo y del accesorio, armas): su color real.

## T160: a 1,5 veces la resolución de antes (64×80 a 1,06): más definido. No a 2×: las
## hojas pasarían de 4096 px de ancho y ~230 MB de textura en el celular.
const CW := 96
const CH := 120
const FEET := Vector2(48, 105)
const BAKE_SCALE := 1.59
## Escala en el mundo del jugador y de los NPC, la misma para todos (T157: un 15 %
## más que la de las hojas; antes el jugador iba a 1,06 y los NPC a 1,12).
const WORLD_SCALE := 1.22
enum Dir { DOWN, UP, SIDE }
const DIRS := 3
## Capas de color (canal G de las máscaras): qué color del creador las tiñe.
const LAYER_SKIN := 1
const LAYER_OUTFIT := 2
const LAYER_ACCENT := 3
const LAYER_HAIR := 4
const LAYER_EYES := 5
## [estado, cuadros]. Atacar va en dos grupos: tajo (espada, hacha, maza) y estocada (daga, puño).
const STATES := [["idle", 2], ["walk", 8],["attack_swing", 4], ["attack_thrust", 4], ["shoot", 3], ["cast", 3],
	["channel", 2], ["hurt", 2], ["dodge", 3], ["dead", 3]]
const WEAPONS := ["sword", "axe", "mace", "dagger"]
const SWING_WEAPONS := ["sword", "axe", "mace"]
## Archivos de cada capa (assets/sprites/player/).
const DIR_PATH := "res://assets/sprites/player/"
const MASK_LAYERS := ["body", "hair", "beard", "accessory"]
const FIXED_LAYERS := ["body_fixed", "accessory_fixed", "weapon"]
## Capas con variantes: un archivo por variante (T160; `hair_3.png`...), así solo se
## carga lo que alguien lleva puesto. Cada archivo: 3 filas (direcciones) × columnas.
const VARIANT_LAYERS := ["hair", "beard", "accessory", "accessory_fixed", "weapon"]
## Pase de luz (T160): se hornea en gris LUM_GRAY y el shader multiplica por
## 1 / LUM_GRAY, así los brillos (colores aclarados) pasan del color base.
const LUM_GRAY := 0.65


static func file_of(layer: String, variant := 0) -> String:
	return DIR_PATH + layer + ("_%d" % variant if layer in VARIANT_LAYERS else "") + ".png"


static func columns() -> int:
	var n := 0
	for s in STATES:
		n += int(s[1])
	return n


## Primera columna de un grupo de STATES (-1 si no existe).
static func first_column(group: String) -> int:
	var c := 0
	for s in STATES:
		if s[0] == group:
			return c
		c += int(s[1])
	return -1


static func frames_of(group: String) -> int:
	for s in STATES:
		if s[0] == group:
			return int(s[1])
	return 0


## Grupo de columnas para un estado del jugador (y su arma, para atacar).
static func group_for(state: String, weapon: String) -> String:
	match state:
		"attack":
			return "attack_swing" if weapon in SWING_WEAPONS else "attack_thrust"
		"run":
			return "walk"
		"limp":
			return "dead"
	return state if first_column(state) != -1 else "idle"


## Columna del cuadro: andar por la fase del paso, quieto y canalizar por el tiempo,
## el resto por el avance de la acción (0..1).
static func column_for(state: String, weapon: String, t: float, time := 0.0, walk_phase := -1.0) -> int:
	var group := group_for(state, weapon)
	var first := first_column(group)
	var n := frames_of(group)
	var k := 0
	match group:
		"walk":
			k = posmod(int(floor(maxf(0.0, walk_phase) / TAU * n)), n)
		"idle":
			k = posmod(int(floor(time / 0.65)), n)
		"channel":
			k = posmod(int(floor(time * 5.0)), n)
		_:
			k = clampi(int(t * n), 0, n - 1)
	return first + k


## Pose para hornear la columna `col` (lo que se le pasa a CharacterAppearance.draw).
## {state, t, time, weapon_class, walk_phase}
static func pose_for(col: int) -> Dictionary:
	var c := 0
	for s in STATES:
		var n := int(s[1])
		if col < c + n:
			var k := col - c
			var group: String = s[0]
			var pose := {"state": group, "t": (k + 0.5) / n, "time": 0.0, "walk_phase": -1.0}
			match group:
				"idle":
					pose["time"] = k * 0.65 + 0.3
				"walk":
					pose["walk_phase"] = (k + 0.5) / n * TAU
				"attack_swing", "attack_thrust":
					pose["state"] = "attack"
				"channel":
					pose["time"] = k * 0.2
				"dead":
					pose["t"] = (k + 0.99) / n   # el último cuadro, ya en el suelo
			return pose
		c += n
	return {"state": "idle", "t": 0.0, "time": 0.0, "walk_phase": -1.0}


static func facing_of(dir: int) -> Vector2:
	return [Vector2.DOWN, Vector2.UP, Vector2.RIGHT][dir]


## Dirección de la hoja (y si hay que voltear) para hacia dónde mira el personaje.
static func dir_for(facing: Vector2) -> Array:
	if facing.y < -0.5 and absf(facing.x) < 0.75:
		return [Dir.UP, false]
	if absf(facing.x) > 0.6 and absf(facing.y) < 0.75:
		return [Dir.SIDE, facing.x < 0.0]
	return [Dir.DOWN, false]


## Celda de una dirección y columna (en el archivo de la variante, si la capa las tiene).
static func region(dir: int, col: int) -> Rect2:
	return Rect2(col * CW, dir * CH, CW, CH)


## Capa de color de un píxel del pase de identificación: el canal dominante de cada
## color puro (piel rojo, atuendo verde, detalles azul, pelo amarillo, ojos cian);
## 0 = no es de ninguno (detalle fijo: boca, contornos, armas).
static func classify(c: Color) -> int:
	var m := maxf(c.r, maxf(c.g, c.b))
	if c.a < 0.5 or m < 0.08:
		return 0
	var r := c.r / m > 0.6
	var g := c.g / m > 0.6
	var b := c.b / m > 0.6
	if r and g and not b:
		return LAYER_HAIR
	if g and b and not r:
		return LAYER_EYES
	if r and not g and not b:
		return LAYER_SKIN
	if g and not r and not b:
		return LAYER_OUTFIT
	if b and not r and not g:
		return LAYER_ACCENT
	return 0


## Colores puros del pase de identificación (en la apariencia que se hornea).
const ID_COLORS := {"skin_tone": "ff0000", "outfit_color": "00ff00", "accent_color": "0000ff", "hair_color": "ffff00", "eye_color": "00ffff"}
