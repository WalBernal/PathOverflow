class_name CharacterPortrait
extends Control
## Retrato animado en medallón redondo (de pecho hacia arriba): hoja de
## personaje, diálogos y escenas. Usa CharacterAppearance.draw_head, así que
## peinado, barba y accesorios son los mismos que en el mundo.
## Respira, parpadea, mira al ratón y, si `talking`, mueve la boca. En modo
## jugador (`idle_actions`) cada pocos segundos hace alguna tontería: un sorbo
## de café, pensar (con spinner de carga), bostezar o ponerse lentes de sol.
## Si le queda poca vida, suda.

signal caption_changed(text: String)

const ACTIONS := ["sip", "think", "yawn", "glasses"]
const CAPTIONS := {
	"idle": ["Esperando input del usuario...", "Funcionando. Más o menos.", "Ocioso, pero con estilo."],
	"sip": ["Recargando cafeína...", "Café nº 7 del día.", "Sin café no hay commits."],
	"think": ["Compilando una idea... 3%", "Buscando en Stack Overflow...", "Pensando. No molestar. (No hay nadie.)"],
	"yawn": ["Daily de 45 minutos...", "Otra reunión que pudo ser un email.", "Bostezo en producción."],
	"glasses": ["Optimizado. Supuestamente.", "Deploy un viernes. Sin miedo.", "Todos los tests en verde. (No hay tests.)"],
	"sweat": ["Esto no estaba en el sprint.", "Vida baja. Pánico alto.", "¿Alguien vio el botón de rollback?"],
}

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = CharacterAppearance.sanitize(value)
		queue_redraw()
## 0..1 de vida (para sudar cuando es baja).
var life_fraction := 1.0
## Si es true, los lentes de sol tienen más papeletas (DPS alto).
var feeling_powerful := false
## Tonterías de vez en cuando (hoja de personaje). En los diálogos, no.
var idle_actions := false
## Mientras sea true, la boca se mueve (texto escribiéndose / voz).
var talking := false
## Color del aro (el de la clase, o el del hablante).
var ring_color := UiStyle.ACCENT
## Glitch (por ejemplo, Rafa hablando por datos del celular).
var glitch := 0.0

var _time := 0.0
var _blink := 0.0
var _next_blink := 2.0
var _action := ""
var _action_time := 0.0
var _next_action := 3.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = _rng.randf_range(2.0, 5.0)
	_blink = maxf(0.0, _blink - delta)
	if idle_actions:
		if _action != "":
			_action_time += delta
			if _action_time > 3.0:
				_set_action("")
		else:
			_next_action -= delta
			if _next_action <= 0.0:
				var options: Array = ACTIONS.duplicate()
				if feeling_powerful:
					options.append("glasses")
				_set_action(options[_rng.randi_range(0, options.size() - 1)])
		if life_fraction < 0.35 and _action == "":
			_set_action("sweat")
	queue_redraw()


func _set_action(action: String) -> void:
	_action = action
	_action_time = 0.0
	_next_action = _rng.randf_range(3.0, 6.0)
	var key := action if action != "" else "idle"
	var options: Array = CAPTIONS[key]
	caption_changed.emit(options[_rng.randi_range(0, options.size() - 1)])


func _draw() -> void:
	var c := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 4.0
	var pulse := 0.5 + 0.5 * sin(_time * 1.8)

	# Halo exterior y fondo con degradado radial.
	for k in 4:
		draw_circle(c, radius + 4.0 - k, Color(ring_color, 0.05 + 0.04 * pulse))
	var bg := Color("120f17")
	for k in 8:
		var t := k / 7.0
		draw_circle(c, radius * (1.0 - t * 0.55), bg.lerp(ring_color.darkened(0.55), t * 0.45))

	var circle := PackedVector2Array()
	for k in 48:
		circle.append(c + Vector2.from_angle(TAU * k / 48.0) * radius)

	# Busto: hombros recortados por el círculo.
	var a := appearance
	var outfit := Color(a["outfit_color"])
	var accent := Color(a.get("accent_color", "2a2a30"))
	var skin := Color(a["skin_tone"])
	var body_w: float = CharacterAppearance.BODY_WIDTH[int(a["body"])]
	var breath := sin(_time * 2.0) * radius * 0.012
	var r := radius * 0.36
	var jitter := Vector2(_rng.randf_range(-1, 1) * glitch * 4.0, 0)
	var head := c + Vector2(0, -radius * 0.08 + breath * 0.5) + jitter
	var shoulders_y := c.y + radius * 0.5 + breath
	var torso := PackedVector2Array([
		Vector2(c.x - radius * 0.95 * body_w, c.y + radius * 1.3), Vector2(c.x - radius * 0.62 * body_w, shoulders_y),
		Vector2(c.x + radius * 0.62 * body_w, shoulders_y), Vector2(c.x + radius * 0.95 * body_w, c.y + radius * 1.3)])
	for poly in Geometry2D.intersect_polygons(torso, circle):
		draw_colored_polygon(poly, outfit)
	draw_rect(Rect2(Vector2(head.x - r * 0.3, head.y + r * 0.7), Vector2(r * 0.6, shoulders_y - head.y - r * 0.6)), skin.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(head.x - r * 0.5, shoulders_y), Vector2(head.x, shoulders_y + r * 0.5),
		Vector2(head.x + r * 0.5, shoulders_y)]), accent)

	# Cabeza (mismo dibujo que en el mundo, a lo grande).
	var look := (get_local_mouse_position() - head) / maxf(1.0, radius * 2.0)
	var opts := {
		"look": look.limit_length(1.0),
		"blink": _blink > 0.0 or (_action == "yawn" and _action_time > 0.6 and _action_time < 2.0),
		"time": _time,
		"mouth": _mouth_open(),
		"smile": 0.6 if _action == "glasses" else (-0.6 if _action == "sweat" else 0.0),
		"brow": 0.15 if _action == "sweat" else (-0.12 if _action == "think" else 0.0),
	}
	CharacterAppearance.draw_head(self, head, r, a, opts)

	match _action:
		"sip":
			_draw_sip(head, r)
		"think":
			_draw_think(head, r)
		"glasses":
			_draw_glasses(head, r)
		"sweat":
			_draw_sweat(head, r)

	# Aro con brillo que gira y bits orbitando.
	draw_arc(c, radius, 0.0, TAU, 64, ring_color.darkened(0.25), 3.0, true)
	var spin := _time * 0.7
	draw_arc(c, radius, spin, spin + 1.1, 24, ring_color.lightened(0.35), 3.0, true)
	draw_arc(c, radius, spin + PI, spin + PI + 0.6, 16, Color(ring_color.lightened(0.2), 0.7), 3.0, true)
	draw_arc(c, radius + 5.0, 0.0, TAU, 64, Color(ring_color, 0.25), 1.0, true)
	var font := get_theme_default_font()
	for k in (3 if radius > 50.0 else 0):
		var ang := -_time * 0.5 + TAU * k / 3.0
		draw_string(font, c + Vector2.from_angle(ang) * (radius + 5.0) + Vector2(-3, 4), "01"[k % 2], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(ring_color.lightened(0.3), 0.8))
	if glitch > 0.0:
		# Señal mala: tinte verde de monitor de fósforo y líneas que saltan.
		draw_circle(c, radius - 2.0, Color(0.2, 1.0, 0.45, 0.08 * glitch))
		for k in 3:
			var y := c.y + _rng.randf_range(-radius, radius) * 0.8
			var half := sqrt(maxf(0.0, radius * radius - (y - c.y) * (y - c.y)))
			draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), Color(0.3, 1.0, 0.5, 0.25 * glitch), 2.0)


func _mouth_open() -> float:
	if _action == "yawn":
		return sin(clampf(_action_time / 2.0, 0.0, 1.0) * PI)
	if talking:
		return maxf(0.0, sin(_time * 14.0) * 0.5 + sin(_time * 23.0) * 0.4)
	return 0.0


func _draw_sip(head: Vector2, r: float) -> void:
	# La taza sube, se queda en la boca y baja.
	var t := _action_time
	var lift := clampf(t / 0.8, 0.0, 1.0) * (1.0 - clampf((t - 2.2) / 0.8, 0.0, 1.0))
	var mug_size := r * 1.0
	var pos := Vector2(head.x + r * 0.15, lerpf(size.y - mug_size * 0.2, head.y + r * 0.75, lift))
	ItemIcons.draw(self, Rect2(pos - Vector2(mug_size, mug_size) / 2.0, Vector2(mug_size, mug_size)), "flask_coffee", Color.WHITE, false)
	for k in 2:
		var phase := fmod(_time + k * 0.5, 1.0)
		var s := pos + Vector2(k * 8.0 - 6.0, -mug_size * 0.5 - phase * 14.0)
		draw_line(s, s + Vector2(sin(_time * 5.0 + k) * 3.0, -6.0), Color(1, 1, 1, 0.5 * (1.0 - phase)), 2.0, true)


func _draw_think(head: Vector2, r: float) -> void:
	var bubble := head + Vector2(r * 1.2, -r * 1.2)
	draw_circle(head + Vector2(r * 0.85, -r * 0.7), r * 0.08, Color(1, 1, 1, 0.85))
	draw_circle(head + Vector2(r * 1.0, -r * 0.92), r * 0.13, Color(1, 1, 1, 0.85))
	draw_circle(bubble, r * 0.42, Color(1, 1, 1, 0.9))
	# Spinner de carga, el gran clásico.
	for k in 8:
		var ang := TAU * k / 8.0 + floorf(_time * 10.0) * TAU / 8.0
		draw_circle(bubble + Vector2.from_angle(ang) * r * 0.24, r * 0.05, Color(0.1, 0.1, 0.1, 0.15 + 0.85 * k / 7.0))


func _draw_glasses(head: Vector2, r: float) -> void:
	# Bajan desde arriba (estilo "deal with it").
	var drop := clampf(_action_time / 0.9, 0.0, 1.0)
	var y := lerpf(head.y - r * 2.4, head.y + r * 0.07, drop)
	var col := Color("0d0d10")
	for side: float in [-1.0, 1.0]:
		var cx := head.x + side * r * 0.37
		draw_rect(Rect2(Vector2(cx - r * 0.25, y - r * 0.15), Vector2(r * 0.5, r * 0.3)), col)
		draw_rect(Rect2(Vector2(cx - r * 0.17, y - r * 0.09), Vector2(r * 0.08, r * 0.06)), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(Vector2(head.x - r * 0.15, y - r * 0.1), Vector2(r * 0.3, r * 0.07)), col)


func _draw_sweat(head: Vector2, r: float) -> void:
	var phase := fmod(_time * 0.8, 1.0)
	var drop := head + Vector2(r * 0.8, -r * 0.2 + phase * r * 0.9)
	var color := Color(0.6, 0.85, 1.0, 0.9 * (1.0 - phase * 0.5))
	draw_circle(drop, r * 0.09, color)
	draw_colored_polygon(PackedVector2Array([drop + Vector2(-r * 0.08, -r * 0.02), drop + Vector2(0, -r * 0.2),
		drop + Vector2(r * 0.08, -r * 0.02)]), color)
