class_name ManaMath
## Cuentas de la familia de maná, sin nodos (las usa Player y las prueban los tests).

## % de regeneración base: del maná máximo sin reserva, por segundo.
const BASE_REGEN_PERCENT := 1.75
## Tope del daño que se lleva el maná antes que la vida.
const MAX_TAKEN_FROM_MANA := 50.0


## Maná por segundo: la base (del máximo sin reserva, con sus aumentos) más la plana,
## que se suma aunque haya maná reservado. Con Recolector de Basura no hay regeneración.
static func regen_per_second(unreserved_max: float, regen_multiplier: float, flat: float, garbage_collector := false) -> float:
	if garbage_collector:
		return 0.0
	return unreserved_max * BASE_REGEN_PERCENT / 100.0 * regen_multiplier + maxf(0.0, flat)


## Reparte un golpe entre maná y vida: [al maná, a la vida]. Si el maná no alcanza,
## lo que falta va a la vida.
static func split_damage(amount: float, mana: float, percent: float) -> Vector2:
	var to_mana := minf(maxf(0.0, mana), amount * clampf(percent, 0.0, MAX_TAKEN_FROM_MANA) / 100.0)
	return Vector2(to_mana, amount - to_mana)
