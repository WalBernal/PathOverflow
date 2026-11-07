class_name SkillAdvice
## Consejos de la pantalla de habilidades (T229): dónde funciona una RAM, en qué
## ranura iría y cuánto cambia el DPS, para que el jugador no tenga que adivinarlo.

## Veredictos.
const NONE := ""            # no hay placa
const FREE := "free"        # encaja en una ranura libre
const SWAP := "swap"        # encaja cambiándola por otra de su generación
const NO_SLOT := "no_slot"  # le sirve, pero la placa no tiene ranuras de su generación
const USELESS := "useless"  # no le sirve a esa habilidad


## Qué pasaría con `ram` en `board`: {kind, slot, text, delta (% de DPS, NAN si no se sabe)}.
## Con ranuras ocupadas de su generación, propone la que más DPS deja al cambiarla.
static func verdict(ram: RamModule, board: Motherboard, character: CharacterData) -> Dictionary:
	if board == null or ram == null:
		return {"kind": NONE, "slot": -1, "text": "", "delta": NAN}
	if not ram.supports(board.skill_def):
		return {"kind": USELESS, "slot": -1, "text": "no le sirve a esta habilidad", "delta": NAN}
	var gen := ram.generation()
	var free := board.free_slot_for(ram)
	if free != -1:
		var d := dps_delta(board, ram, free, character)
		return {"kind": FREE, "slot": free, "text": "ranura %d libre%s" % [free + 1, _delta_text(d)], "delta": d}
	var best := -1
	var best_delta := -INF
	for k in board.slots.size():
		if String(board.slots[k]) != gen:
			continue
		var d := dps_delta(board, ram, k, character)
		if best == -1 or (not is_nan(d) and d > best_delta):
			best = k
			best_delta = d if not is_nan(d) else best_delta
	if best == -1:
		return {"kind": NO_SLOT, "slot": -1, "text": "no tiene ranuras %s" % gen, "delta": NAN}
	var dd := dps_delta(board, ram, best, character)
	return {"kind": SWAP, "slot": best, "text": "cambiar la ranura %d%s" % [best + 1, _delta_text(dd)], "delta": dd}


## ¿Vale la pena? Ranura libre, o cambio que no baja el DPS.
static func good(v: Dictionary) -> bool:
	var kind := String(v.get("kind", ""))
	var d := float(v.get("delta", NAN))
	return kind == FREE or (kind == SWAP and (is_nan(d) or d >= 0.0))


## Cambio de DPS (%) al poner `ram` en la ranura `slot` de `board` (sustituyendo lo que
## haya). NAN si la habilidad no hace daño directo (auras, por ejemplo).
static func dps_delta(board: Motherboard, ram: RamModule, slot: int, character: CharacterData) -> float:
	var before: float = SkillCalc.compute(board, character)["dps"]
	if before <= 0.0:
		return NAN
	var trial := Motherboard.new(board.skill_def, board.level, board.slots)
	trial.variant = board.variant
	trial.rams = board.rams.duplicate()
	trial.rams[slot] = null
	if trial.install(ram, slot) != "":
		return NAN
	var after: float = SkillCalc.compute(trial, character)["dps"]
	return (after / before - 1.0) * 100.0


static func _delta_text(d: float) -> String:
	return "" if is_nan(d) else " · %+.0f %% DPS" % roundf(d)


## Qué hace la RAM en una frase (la primera de su descripción).
static func short_effect(ram: RamModule) -> String:
	var d := String(ram.def.get("description", ""))
	var cut := d.find(". ")
	return d.substr(0, cut + 1) if cut > 0 else d
