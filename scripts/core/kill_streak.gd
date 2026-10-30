class_name KillStreak
extends RefCounted
## Racha de bajas (T153): las bajas con menos de WINDOW segundos entre una y otra se
## encadenan. Desde 5 dan velocidad de movimiento mientras dure (por escalones) y, al
## cortarse, una racha de 8 o más deja tokens a tus pies: una recompensa visible tras
## cada manada, para que las peleas no acaben en nada.

const WINDOW := 2.5
## [bajas, % de velocidad de movimiento aumentada]
const TIERS := [[5, 10.0], [15, 20.0], [30, 30.0]]
const REWARD_FROM := 8

var count := 0
var _last := -INF


## Una baja en el instante `now` (segundos): la racha que queda.
func add_kill(now: float) -> int:
	if now - _last > WINDOW:
		count = 0
	count += 1
	_last = now
	return count


## ¿Se cortó la racha (pasó la ventana sin bajas)?
func expired(now: float) -> bool:
	return count > 0 and now - _last > WINDOW


## Corta la racha y devuelve cuántas bajas tuvo.
func end() -> int:
	var n := count
	count = 0
	return n


## Segundos que le quedan a la racha antes de cortarse.
func time_left(now: float) -> float:
	return maxf(0.0, WINDOW - (now - _last)) if count > 0 else 0.0


static func speed_bonus(n: int) -> float:
	var bonus := 0.0
	for t in TIERS:
		if n >= int(t[0]):
			bonus = float(t[1])
	return bonus


## Tokens al cortar una racha de `n` bajas (uno por cada cuatro, desde REWARD_FROM).
static func reward_tokens(n: int) -> int:
	return n / 4 if n >= REWARD_FROM else 0
