class_name Hud
extends Control
## HUD de combate: orbe de vida (con anillo de escudo de energía), orbe de maná,
## barra de experiencia y panel de rendimiento para las pruebas de estrés.

const ORB_RADIUS := 70.0
const LIFE_COLOR := Color("b3262b")
const MANA_COLOR := Color("2a4fb3")
const ES_COLOR := Color("7fb8e0")
const XP_COLOR := Color("d9a441")
const FRAME_COLOR := Color("3a3442")
const TEXT_COLOR := Color("e8d9b0")

var player: Player
var enemies: EnemyManager
var character: CharacterData

var _info: Label
var _message: Label
var _message_tween: Tween
var _info_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info = Label.new()
	_info.position = Vector2(12, 10)
	_info.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(_info)

	var help := Label.new()
	help.text = "WASD / mantener click izq.: mover  ·  Espacio / click der.: atacar  ·  Click en objeto: recoger  ·  I: inventario  ·  P: árbol pasivo\nF1: +100 enemigos  ·  F2: limpiar  ·  F3: jefe único  ·  F4: botín de prueba"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", Color("8a8293"))
	add_child(help)
	help.anchor_left = 0.0
	help.anchor_right = 1.0
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_top = -78.0
	help.offset_bottom = -30.0

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color("e06c6c"))
	_message.add_theme_font_size_override("font_size", 18)
	add_child(_message)
	_message.anchor_right = 1.0
	_message.offset_top = 90.0


## Mensaje temporal en el centro superior de la pantalla.
func flash(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(2.0)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.6)


func _process(delta: float) -> void:
	queue_redraw()
	_info_timer -= delta
	if _info_timer > 0.0 or character == null:
		return
	_info_timer = 0.25
	_info.text = "FPS: %d\nEnemigos: %d  ·  Simulación: %.2f ms\nNivel %d  ·  Pasivas libres: %d" % [
		Engine.get_frames_per_second(),
		enemies.count(),
		enemies.last_simulation_ms,
		character.level,
		character.passive_points_available(),
	]


func _draw() -> void:
	if player == null:
		return
	var font := get_theme_default_font()
	var life_center := Vector2(ORB_RADIUS + 40.0, size.y - ORB_RADIUS - 40.0)
	var mana_center := Vector2(size.x - ORB_RADIUS - 40.0, size.y - ORB_RADIUS - 40.0)

	_draw_orb(life_center, player.life / player.max_life(), LIFE_COLOR)
	var max_es := player.max_energy_shield()
	if max_es > 0.0 and player.energy_shield > 0.0:
		draw_arc(life_center, ORB_RADIUS + 6.0, -PI / 2.0, -PI / 2.0 + TAU * player.energy_shield / max_es,
			64, ES_COLOR, 5.0, true)
	_draw_orb(mana_center, player.mana / maxf(1.0, player.max_mana()), MANA_COLOR)

	var life_text := "%d / %d" % [player.life, player.max_life()]
	if max_es > 0.0:
		life_text += "  (+%d ES)" % player.energy_shield
	draw_string(font, life_center + Vector2(-100.0, 6.0), life_text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 16, TEXT_COLOR)
	draw_string(font, mana_center + Vector2(-100.0, 6.0), "%d / %d" % [player.mana, player.max_mana()],
		HORIZONTAL_ALIGNMENT_CENTER, 200.0, 16, TEXT_COLOR)

	# Barra de experiencia.
	var bar := Rect2(Vector2(ORB_RADIUS * 2.0 + 80.0, size.y - 22.0), Vector2(size.x - ORB_RADIUS * 4.0 - 160.0, 8.0))
	draw_rect(bar, Color(0, 0, 0, 0.6))
	var progress := float(character.experience) / float(character.experience_to_next())
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), XP_COLOR)
	draw_rect(bar, FRAME_COLOR, false, 1.0)


## Orbe estilo PoE: círculo rellenado desde abajo según `fill` (0..1).
func _draw_orb(center: Vector2, fill: float, color: Color) -> void:
	fill = clampf(fill, 0.0, 1.0)
	draw_circle(center, ORB_RADIUS, Color(0.05, 0.04, 0.06, 0.85))
	if fill > 0.01:
		# Arco desde la línea de llenado, pasando por abajo (sin(t) > 0 es "abajo").
		var start := asin(clampf(1.0 - 2.0 * fill, -1.0, 1.0))
		var points := PackedVector2Array()
		var steps := 48
		for k in steps + 1:
			var t := lerpf(start, PI - start, float(k) / steps)
			points.append(center + Vector2(cos(t), sin(t)) * ORB_RADIUS)
		draw_colored_polygon(points, color)
	draw_arc(center, ORB_RADIUS, 0.0, TAU, 64, FRAME_COLOR, 3.0, true)
