class_name UiMotion
## Animación de la interfaz (T97): ventanas que entran con un zoom corto, botones que
## rebotan al pulsar y tooltips de objeto que aparecen con un fundido. Con «reducir
## movimiento» (Accessibility.reduce_motion) no se mueve nada: solo el fundido.

const WINDOW_IN := 0.14
const BUTTON_BOUNCE := 0.18
const TOOLTIP_FADE := 0.12


## Rebote con un poco de sobrepaso: de `from` a 1 en t ∈ [0, 1] (sube de más y vuelve).
static func overshoot(t: float, from := 0.92) -> float:
	t = clampf(t, 0.0, 1.0)
	var s := 1.70158
	var u := t - 1.0
	return from + (1.0 - from) * (1.0 + (s + 1.0) * u * u * u + s * u * u)


## Entrada de una ventana: aparece y crece desde el 96 % (o solo aparece, sin movimiento).
static func window_in(panel: Control) -> void:
	if not panel.is_inside_tree():
		return
	panel.pivot_offset = panel.size / 2.0
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, WINDOW_IN)
	if not Accessibility.reduce_motion:
		panel.scale = Vector2(0.96, 0.96)
		tw.tween_property(panel, "scale", Vector2.ONE, WINDOW_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Rebote de un botón al pulsarlo: se encoge un poco y vuelve con sobrepaso.
static func bounce(button: Control) -> void:
	if Accessibility.reduce_motion or not button.is_inside_tree():
		return
	button.pivot_offset = button.size / 2.0
	button.scale = Vector2(0.92, 0.92)
	button.create_tween().tween_property(button, "scale", Vector2.ONE, BUTTON_BOUNCE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Brillo de la barra de experiencia al subir de nivel (lo dibuja Hud).
const LEVEL_GLOW_TIME := 2.2


## Intensidad del brillo `since` segundos después de subir de nivel: late y se apaga.
static func level_glow(since: float) -> float:
	if since < 0.0 or since > LEVEL_GLOW_TIME:
		return 0.0
	return (1.0 - since / LEVEL_GLOW_TIME) * (0.75 + 0.25 * cos(since * 9.0))


## Entrada escalonada (T184): cada pieza aparece un poco después de la anterior.
const STAGGER_START := 0.12
const STAGGER_STEP := 0.07
const STAGGER_TIME := 0.24


## Cuándo empieza a entrar la pieza número `k`.
static func stagger_delay(k: int) -> float:
	return STAGGER_START + STAGGER_STEP * maxi(k, 0)


## Hace entrar `nodes` en orden: fundido y, si se puede mover, crecen desde el 96 %.
static func stagger_in(nodes: Array) -> void:
	for k in nodes.size():
		var c := nodes[k] as Control
		if c == null or not c.is_inside_tree():
			continue
		c.modulate.a = 0.0
		var tw := c.create_tween().set_parallel(true)
		tw.tween_property(c, "modulate:a", 1.0, STAGGER_TIME).set_delay(stagger_delay(k))
		if not Accessibility.reduce_motion:
			c.pivot_offset = c.size / 2.0
			c.scale = Vector2(0.96, 0.96)
			tw.tween_property(c, "scale", Vector2.ONE, STAGGER_TIME).set_delay(stagger_delay(k)) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cuánto tarda un texto en escribirse a máquina (T184): rápido, sin pasar de medio segundo.
static func typewriter_time(chars: int) -> float:
	return clampf(chars / 400.0, 0.12, 0.5)


## Fundido de entrada (tooltips de objeto).
static func fade_in(c: CanvasItem) -> void:
	if not c.is_inside_tree():
		return
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, TOOLTIP_FADE)
