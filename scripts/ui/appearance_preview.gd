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
var glow_color := Color("d9a441")
## Pose de lucimiento (T96): cada POSE_CYCLE s la figura hace su acción ("attack",
## "cast", "shoot"; "" = solo respira), con el arma que toque.
var action := ""
var weapon := ""
const POSE_CYCLE := 3.2
const POSE_ACTION_TIME := 0.9

var _time := 0.0


## Pose en el instante `time`: quieta la mayor parte del ciclo y, al final, la acción
## de principio a fin (t de 0 a 1). Sin acción, siempre quieta.
static func pose_at(time: float, act: String, weapon_kind := "") -> Dictionary:
	var cyc := fposmod(time, POSE_CYCLE)
	var start := POSE_CYCLE - POSE_ACTION_TIME
	if act == "" or cyc < start:
		return {"state": "idle", "t": 0.0, "time": time, "weapon": weapon_kind}
	return {"state": act, "t": (cyc - start) / POSE_ACTION_TIME, "time": time, "weapon": weapon_kind if act != "cast" else ""}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# La figura mide ~46 unidades (con cresta); se escala para llenar el control.
	var scale := minf(size.x / 30.0, size.y / 50.0)
	var feet := Vector2(size.x / 2.0, size.y - 4.0 * scale)
	if animated:
		_draw_pedestal(feet, scale)
		feet.y -= scale * 2.2   # de pie sobre el pedestal
		var pose := pose_at(_time, action, weapon)
		pose["glow"] = glow_color
		CharacterAppearance.draw(self, feet, scale, appearance, facing, Color(0, 0, 0, 0), -1.0, pose)
		return
	CharacterAppearance.draw(self, feet, scale, appearance, facing)


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
