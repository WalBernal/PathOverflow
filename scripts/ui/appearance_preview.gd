class_name AppearancePreview
extends Control
## Muestra la figura de un personaje a cualquier tamaño (creador, lista de personajes).

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = value
		queue_redraw()
var facing := Vector2.DOWN:
	set(value):
		facing = value
		queue_redraw()
## Si está activo, la figura respira (sube y baja) y se dibuja un pedestal brillante.
var animated := false:
	set(value):
		animated = value
		set_process(value)
var glow_color := UiStyle.ACCENT
## Pose de lucimiento (T96): cada POSE_CYCLE s la figura hace su acción ("attack",
## "cast", "shoot"; "" = solo respira), con el arma que toque.
var action := ""
var weapon := ""
## Con las hojas por capas (T102b) en vez del dibujo con formas (lista de personajes y creador).
var use_sprites := false
var _sprite: PlayerSprite
var _holder: Node2D   # el sprite va dentro: así se encoge al girar sin pisar su propia escala
## Giro con paso intermedio (T185): la figura se estrecha, cambia de dirección a mitad
## y vuelve a su ancho. `_turn_p` va de 0 a 1 (1 = quieta).
const TURN_TIME := 0.18
var _turn_from := Vector2.DOWN
var _turn_p := 1.0
## Gira sola (lista de personajes): abajo → lado → arriba → lado, y de frente para posar.
var auto_turn := false
const AUTO_TURN := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]
const POSE_CYCLE := 3.2
const POSE_ACTION_TIME := 0.9

var _time := 0.0
## Destello al cambiar de personaje (T184): una columna de luz y bits que salen del
## pedestal; baja de 1 a 0 en FLASH_TIME.
var _flash := 0.0
const FLASH_TIME := 0.45


## La figura cambia: destello y la figura reaparece desde el pedestal.
func flash() -> void:
	_flash = 1.0
	if not Accessibility.reduce_motion and is_inside_tree():
		pivot_offset = Vector2(size.x / 2.0, size.y)   # se estira desde el pedestal
		scale = Vector2(0.92, 1.08)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pose en el instante `time`: quieta la mayor parte del ciclo y, al final, la acción
## de principio a fin (t de 0 a 1). Sin acción, siempre quieta.
static func pose_at(time: float, act: String, weapon_kind := "") -> Dictionary:
	var cyc := fposmod(time, POSE_CYCLE)
	var start := POSE_CYCLE - POSE_ACTION_TIME
	if act == "" or cyc < start:
		return {"state": "idle", "t": 0.0, "time": time, "weapon": weapon_kind}
	return {"state": act, "t": (cyc - start) / POSE_ACTION_TIME, "time": time, "weapon": weapon_kind if act != "cast" else ""}


## Ancho de la figura a mitad de un giro (p de 0 a 1): se estrecha y vuelve.
static func turn_squash(p: float) -> float:
	return 1.0 - 0.6 * sin(PI * clampf(p, 0.0, 1.0))


## Hacia dónde mira la figura que gira sola en el instante `time`: una dirección por
## ciclo de pose y de frente un poco antes de la acción, para posar mirando a cámara.
static func facing_at(time: float) -> Vector2:
	var cyc := fposmod(time, POSE_CYCLE)
	if cyc >= POSE_CYCLE - POSE_ACTION_TIME - TURN_TIME:
		return Vector2.DOWN
	return AUTO_TURN[int(time / POSE_CYCLE) % AUTO_TURN.size()]


## Gira hacia `dir` con el paso intermedio (con «reducir movimiento», al instante).
func turn_to(dir: Vector2) -> void:
	if dir == facing:
		return
	_turn_from = shown_facing()
	facing = dir
	_turn_p = 1.0 if Accessibility.reduce_motion else 0.0


## La dirección que se ve ahora: la de antes hasta la mitad del giro.
func shown_facing() -> Vector2:
	return _turn_from if _turn_p < 0.5 else facing


## Avanza el tiempo de la figura (lo que hace cada fotograma, sin dibujar).
func step(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta / FLASH_TIME)
	_turn_p = minf(1.0, _turn_p + delta / TURN_TIME)
	if auto_turn:
		turn_to(facing_at(_time))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)


func _process(delta: float) -> void:
	step(delta)
	queue_redraw()


func _draw() -> void:
	# La figura mide ~46 unidades (con cresta); se escala para llenar el control.
	var scale := minf(size.x / 30.0, size.y / 50.0)
	var feet := Vector2(size.x / 2.0, size.y - 4.0 * scale)
	var pose := {}
	if animated:
		_draw_pedestal(feet, scale)
		feet.y -= scale * 2.2   # de pie sobre el pedestal
		pose = pose_at(_time, action, weapon)
		pose["glow"] = glow_color
		if _flash > 0.0:
			_draw_flash(feet, scale)
	var squash := turn_squash(_turn_p) if _turn_p < 1.0 else 1.0
	var looking := shown_facing()
	if use_sprites and PlayerSprite.available():
		if _sprite == null:
			_holder = Node2D.new()
			add_child(_holder)
			_sprite = PlayerSprite.new()
			_holder.add_child(_sprite)
		_sprite.appearance = appearance
		_holder.position = feet
		_holder.scale = Vector2(squash, 1.0)
		_sprite.sprite_scale = scale / PlayerSheet.BAKE_SCALE
		_sprite.set_pose(looking, pose if not pose.is_empty() else {"state": "idle", "time": _time})
		return
	# (el dibujo con formas usa su propio draw_set_transform: gira sin estrecharse)
	if animated:
		CharacterAppearance.draw(self, feet, scale, appearance, looking, Color(0, 0, 0, 0), -1.0, pose)
		return
	CharacterAppearance.draw(self, feet, scale, appearance, looking)


## Destello al cambiar de personaje (T184): columna de luz del color de la clase y
## bits que salen hacia arriba y a los lados.
func _draw_flash(feet: Vector2, scale: float) -> void:
	var k := _flash
	var w := scale * 10.0 * (0.4 + 0.6 * k)
	var h := scale * 46.0
	draw_rect(Rect2(feet.x - w / 2.0, feet.y - h, w, h), Color(glow_color, 0.22 * k))
	draw_rect(Rect2(feet.x - w / 6.0, feet.y - h, w / 3.0, h), Color(Color.WHITE, 0.25 * k))
	var spread := 1.0 - k
	for n in 10:
		var ang := -PI / 2.0 + (n - 4.5) * 0.28
		var p := feet + Vector2(0, -scale * 8.0) + Vector2.from_angle(ang) * scale * (6.0 + 26.0 * spread)
		var s := maxf(2.0, scale * 0.9)
		draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), Color(glow_color, k))


## Pedestal de la clase (T96): losa hexagonal de piedra con runas del color de la
## clase que laten, el resplandor de siempre y bits subiendo.
func _draw_pedestal(feet: Vector2, scale: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 1.6)
	var top := PackedVector2Array()
	var side := PackedVector2Array()
	for k in 6:
		top.append(feet + Vector2.from_angle(TAU * k / 6.0) * scale * Vector2(12.0, 4.2))
	for k in [0, 1, 2, 3]:
		side.append(top[k])
	for k in [3, 2, 1, 0]:
		side.append(top[k] + Vector2(0, scale * 3.2))
	draw_colored_polygon(side, Color("1a1720"))
	draw_colored_polygon(top, Color("2a2531"))
	var rim := top.duplicate()
	rim.append(top[0])
	draw_polyline(rim, Color(glow_color, 0.55 + 0.35 * pulse), 2.0, true)
	for k in 6:
		var p := feet + Vector2.from_angle(TAU * (k + 0.5) / 6.0) * scale * Vector2(8.5, 3.0)
		var lit := 0.5 + 0.5 * sin(_time * 2.0 + k * 1.1)
		draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 2)), Color(glow_color, 0.3 + 0.6 * lit))
	for k in 5:
		var r := scale * (9.0 + k * 2.2)
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, r, Color(glow_color, (0.10 + 0.06 * pulse) * (1.0 - k / 5.0)))
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.32))
	draw_arc(Vector2.ZERO, scale * 11.0, 0.0, TAU, 48, Color(glow_color, 0.45 + 0.3 * pulse), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	# Bits subiendo desde el pedestal.
	var font := get_theme_default_font()
	for k in 6:
		var phase := fmod(_time * 0.4 + k / 6.0, 1.0)
		var x := feet.x + sin(k * 2.3) * scale * 9.0
		var y := feet.y - phase * scale * 40.0
		draw_string(font, Vector2(x, y), "1" if k % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
			Color(glow_color, 0.5 * (1.0 - phase)))
