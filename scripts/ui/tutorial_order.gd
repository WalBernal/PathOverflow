class_name TutorialOrder
## Orden de los pasos del tutorial entre versiones (sin dependencias, para las pruebas).
## Versión 3: el paso de las pasivas pasó al final (en el Sandbox no da para subir de
## nivel), así que quien iba a medias sigue por el mismo paso, que ahora está en otro sitio.

const V2 := ["move", "use_skill", "kill", "loot", "equip", "flask", "passives", "reach_camp", "talk_ada", "install_ram", "kevin", "leave_camp"]


## Paso del orden nuevo `steps` para quien iba por el paso `old` del orden `old_order`.
static func migrated_step(old: int, old_order: Array, steps: Array) -> int:
	if old >= old_order.size():
		return steps.size()   # ya lo había terminado
	for i in steps.size():
		if steps[i]["id"] == old_order[old]:
			return i
	return 0
