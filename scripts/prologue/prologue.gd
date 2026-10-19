class_name Prologue
extends Control
## Prólogo / Acto 0: La Beca de Schrödinger.
##   1. El Desembarco de la Realidad: texto mecanografiado y la calle del malecón.
##   2. Retorno a la UAdeO: el pasillo hasta el Departamento de Informática.
##   3. El Error 404 del Archivo Muerto: Rafa y la libreta de gatitos.
##   4. El Incidente del Viernes a las 6:00 PM: se cae el SICE.
##   5. La Elección Forzada: la ventana de contratación (aquí se elige la clase).
##   Clímax: la carpeta lila, la descarga, la consola roja y la caída a producción.
## Al terminar se crea el personaje (nombre y apariencia del creador + la clase
## elegida) y se entra al Sandbox. Esc: saltar a la elección de puesto.
## Se mueve con A/D o flechas (en el pasillo, también W/S) o con click (destino
## fijo en el mundo); E, Espacio o click para interactuar.

const STAGE_SIZE := Vector2i(400, 225)
const WALK_SPEED := 56.0
const INTERACT_RANGE := 26.0
const INTRO_LINES := [
	"Licenciatura concluida. Promedio: 9.2. Vacantes aplicadas: 147.",
	"",
	"Requisitos del mercado: 5 años de experiencia en tecnologías lanzadas hace 3, dominio de tres frameworks incompatibles, disponibilidad para guardias los fines de semana y auto propio.",
	"",
	"Sueldo ofrecido: salario mínimo con prestaciones «superiores a la ley» (café soluble y agua de garrafón libre).",
	"",
	"Estado: RECHAZADO por falta de experiencia previa.",
	"",
	"El último salvavidas burocrático para no ahogarse en el desempleo: tramitar el título físico y concursar por una plaza de practicante con remuneración. Para eso hace falta un papel sagrado: la constancia de liberación de Servicio Social.",
]
const CONSOLE_LINES := [
	"CRITICAL: Unhandled hardware interrupt at IRQ 07",
	"FATAL: Database connection pool exhausted",
	"POST /api/v1/deploy/force --user admin --origin 127.0.0.1",
	"Commit message: \"Por el Monolito. Que nunca se reinicie\"",
	"Status: 500 Internal Server Error",
	"Dropping user session into Ring 3 sandbox...",
]
## Puntos de interés por sitio: x en el mundo, texto del aviso y acción.
const HOTSPOTS := {
	"calle": [{"x": 300.0, "text": "E · Cruzar la avenida y entrar a la UAdeO", "action": "to_hallway"}],
	"pasillo": [{"lat": -0.72, "depth": 0.86, "text": "E · Departamento de Informática", "action": "to_office"},
		{"lat": -0.12, "depth": 0.96, "text": "E · Caja de trámites", "action": "window"},
		{"lat": 0.5, "depth": 0.96, "text": "E · Ver la TV", "action": "tv"}],
	"oficina": [{"x": 170.0, "text": "E · Hablar con el encargado", "action": "talk_rafa"}],
}

var _name := "Egresado"
var _appearance: Dictionary = CharacterAppearance.default()
var _class_id := StringName("")
var _phase := "intro"
var _flags := {}
var _time := 0.0
var _fade := 1.0
var _fade_target := 0.0

var _viewport: SubViewport
var _stage: PrologueStage
var _screen: TextureRect
var _material: ShaderMaterial
var _overlay: Control
var _cutscene: CutscenePlayer
var _hire: HireDialog
var _mono: SystemFont

var _intro_chars := 0.0
var _intro_total := 0
var _intro_text := ""
var _console_chars := 0.0
var _console_text := ""
var _fall_time := 0.0
var _title_time := 0.0
var _skip_hint := 0.0
var _glitch := 0.0
var _flash := 0.0
## Destino del click en coordenadas del escenario (INF = ninguno).
var _target := Vector2.INF


func _ready() -> void:
	MusicPlayer.stop_music()
	var pending: Dictionary = GameData.pending_creation
	_name = String(pending.get("name", _name))
	_appearance = CharacterAppearance.sanitize(pending.get("appearance", CharacterAppearance.default()))
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Courier New", "DejaVu Sans Mono", "monospace"])
	_build()
	_intro_text = "\n".join(INTRO_LINES)
	_intro_total = _intro_text.length()
	if bool(pending.get("skip_prologue", false)):
		_go_room("oficina", 200.0)
		_stage.rafa_standing = true
		_phase = "hire"
		_fade = 0.0
		_open_hire()
	else:
		_go_room("calle", 40.0)
		Sfx.ambient("calle")


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_viewport = SubViewport.new()
	_viewport.size = STAGE_SIZE
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	_stage = PrologueStage.new()
	_stage.player_look = _appearance
	_stage.rafa_look = CharacterAppearance.sanitize(Zone.npc_database().get("npcs", {}).get("root", {}).get("appearance", {}))
	_viewport.add_child(_stage)
	_screen = TextureRect.new()
	_screen.texture = _viewport.get_texture()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_material = ShaderMaterial.new()
	_material.shader = load("res://scripts/prologue/prologue_screen.gdshader")
	_screen.material = _material
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_cutscene = CutscenePlayer.new()
	_cutscene.speakers = {"player": {"name": _name, "appearance": _stage_look(), "color": "e9e5d8"}}
	add_child(_cutscene)
	_cutscene.effect.connect(_on_cutscene_effect)


## El jugador en el mundo real: con su camisa formal.
func _stage_look() -> Dictionary:
	var look := _appearance.duplicate()
	look["outfit_color"] = PrologueStage.SHIRT
	return look


# --- Bucle ---

func _process(delta: float) -> void:
	_time += delta
	_fade = move_toward(_fade, _fade_target, delta * 1.6)
	_glitch = maxf(0.0, _glitch - delta * 0.6)
	_flash = maxf(0.0, _flash - delta * 1.5)
	_skip_hint = maxf(0.0, _skip_hint - delta)
	match _phase:
		"intro":
			_intro_chars = minf(_intro_total, _intro_chars + delta * 42.0)
			if int(_intro_chars) % 3 == 0 and _intro_chars < _intro_total:
				Sfx.play("trap", -18.0, 2.2)
		"walk":
			_update_walk(delta)
		"console":
			_console_chars = minf(_console_text.length(), _console_chars + delta * 90.0)
			_stage.rack_shake = 1.0
			if _console_chars >= _console_text.length() and not _flags.has("console_done"):
				_flags["console_done"] = true
				get_tree().create_timer(1.4).timeout.connect(_start_fall)
		"fall":
			_update_fall(delta)
		"title":
			_title_time += delta
			if _title_time > 4.2 and not _flags.has("finishing"):
				_flags["finishing"] = true
				_finish()
	_update_screen()
	_overlay.queue_redraw()


func _update_screen() -> void:
	var digital := 0.0
	var pixel := 1.0
	var desat: float = {"calle": 0.22, "pasillo": 0.4}.get(_stage.room, 0.42)
	if _phase == "fall":
		var t := clampf(_fall_time / 5.0, 0.0, 1.0)
		digital = t
		pixel = 1.0 + 7.0 * sin(t * PI)
		desat = lerpf(0.42, 0.0, t)
	_material.set_shader_parameter("time", _time)
	_material.set_shader_parameter("desat", desat)
	_material.set_shader_parameter("tint", Vector3(1.08, 1.0, 0.86) if _stage.room == "calle" else Vector3(1.0, 1.0, 0.95))
	_material.set_shader_parameter("heat", 1.0 if _stage.room == "calle" else 0.0)
	_material.set_shader_parameter("glitch", _glitch)
	_material.set_shader_parameter("digital", digital)
	_material.set_shader_parameter("pixelate", pixel)
	_material.set_shader_parameter("flash", _flash)


func _update_walk(delta: float) -> void:
	if _cutscene.is_playing():
		_stage.prompt = {}
		_stage.walk_phase = -1.0
		return
	if _stage.room == "pasillo":
		_walk_hallway(delta)
	else:
		_walk_side(delta)
	var spot := _nearest_hotspot()
	if spot.is_empty():
		_stage.prompt = {}
	else:
		var lift := 46.0 if _stage.room != "pasillo" else 44.0 * PrologueStage.hall_scale(float(spot["depth"]))
		_stage.prompt = {"pos": _hotspot_pos(spot) - Vector2(0, lift), "text": spot["text"]}


## Vista lateral: A/D o flechas; el click fija un destino en el mundo (no en la
## pantalla), así la cámara no lo arrastra y el personaje no se pasa de largo.
func _walk_side(delta: float) -> void:
	var dir := Input.get_axis(&"move_left", &"move_right")
	if dir != 0.0:
		_target = Vector2.INF
	elif _target != Vector2.INF:
		if absf(_target.x - _stage.player_x) > 2.0:
			dir = signf(_target.x - _stage.player_x)
		else:
			_target = Vector2.INF
	if dir != 0.0:
		_stage.player_x = clampf(_stage.player_x + dir * WALK_SPEED * delta, 12.0, _stage.width() - 12.0)
		if _target != Vector2.INF and signf(_target.x - _stage.player_x) != dir:
			_stage.player_x = _target.x   # llegó: no se pasa del punto
			_target = Vector2.INF
		_stage.player_facing = Vector2(dir, 0.0)
		_stage.walk_phase = fmod(maxf(_stage.walk_phase, 0.0) + WALK_SPEED * delta / 14.0 * PI, TAU)
	else:
		_stage.walk_phase = -1.0
	# Cámara que sigue con suavidad.
	var cam_target := clampf(_stage.player_x - STAGE_SIZE.x / 2.0, 0.0, _stage.width() - STAGE_SIZE.x)
	_stage.cam_x = lerpf(_stage.cam_x, cam_target, 1.0 - exp(-5.0 * delta))


## Pasillo de frente: W/S (o arriba/abajo) avanzan y retroceden; A/D, de lado.
func _walk_hallway(delta: float) -> void:
	var move := Vector2(Input.get_axis(&"move_left", &"move_right"), Input.get_axis(&"move_down", &"move_up"))
	if move != Vector2.ZERO:
		_target = Vector2.INF
	elif _target != Vector2.INF:
		var goal := PrologueStage.hall_from_screen(_target)
		var diff := Vector2(goal.x - _stage.player_lat, goal.y - _stage.player_depth)
		if diff.length() > 0.015:
			move = diff.normalized()
		else:
			_target = Vector2.INF
	if move != Vector2.ZERO:
		var step := move.normalized() * delta
		_stage.player_lat = clampf(_stage.player_lat + step.x * 0.9, -0.85, 0.85)
		_stage.player_depth = clampf(_stage.player_depth + step.y * 0.34, 0.0, 1.0)
		_stage.player_facing = Vector2(move.x, -move.y).normalized()
		_stage.walk_phase = fmod(maxf(_stage.walk_phase, 0.0) + delta * 2.6 * PI, TAU)
	else:
		_stage.walk_phase = -1.0
	_stage.cam_x = 0.0


func _nearest_hotspot() -> Dictionary:
	for h in _hotspots():
		if _stage.room == "pasillo":
			if absf(float(h["depth"]) - _stage.player_depth) <= 0.09 and absf(float(h["lat"]) - _stage.player_lat) <= 0.28:
				return h
		elif absf(float(h["x"]) - _stage.player_x) <= INTERACT_RANGE:
			return h
	return {}


## Dónde está un punto de interés en el escenario.
func _hotspot_pos(h: Dictionary) -> Vector2:
	if _stage.room == "pasillo":
		return PrologueStage.hall_to_screen(float(h["lat"]), float(h["depth"]))
	return Vector2(float(h["x"]), PrologueStage.FLOOR_Y)


func _hotspots() -> Array:
	var list: Array = HOTSPOTS.get(_stage.room, []).duplicate()
	if _stage.room == "oficina" and _flags.has("hired"):
		list = [{"x": 340.0, "text": "E · Buscar detrás del rack negro", "action": "rack"}]
	elif _stage.room == "oficina" and _flags.has("talked"):
		list = []
	return list


## El ratón en coordenadas del escenario (con la cámara).
func _mouse_stage() -> Vector2:
	var rect := _screen_rect()
	var local := (get_local_mouse_position() - rect.position) / rect.size * Vector2(STAGE_SIZE)
	return local + Vector2(_stage.cam_x, 0.0)


## Dónde queda el escenario en la pantalla (escalado con su proporción).
func _screen_rect() -> Rect2:
	var s := minf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	var area := Vector2(STAGE_SIZE) * s
	return Rect2((size - area) / 2.0, area)


func _input(event: InputEvent) -> void:
	if _cutscene.is_playing() or _hire != null:
		return
	var key := event as InputEventKey
	var mb := event as InputEventMouseButton
	if event.is_action_pressed(&"ui_cancel"):
		if _phase in ["intro", "walk"] and not _flags.has("hired"):
			if _skip_hint > 0.0:
				_skip_to_hire()
			else:
				_skip_hint = 2.5
		get_viewport().set_input_as_handled()
		return
	# Arrastrar con el botón pulsado mueve el destino (sigue al ratón).
	if event is InputEventMouseMotion and _phase == "walk" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_target = _mouse_stage()
		return
	var pressed := (key and key.pressed and not key.echo and key.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]) \
		or (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	match _phase:
		"intro":
			if _intro_chars < _intro_total:
				_intro_chars = _intro_total
			else:
				_phase = "walk"
		"walk":
			var spot := _nearest_hotspot()
			if not spot.is_empty() and (key != null or _mouse_stage().distance_to(_hotspot_pos(spot)) < 40.0):
				_target = Vector2.INF
				_interact(String(spot["action"]))
				get_viewport().set_input_as_handled()
			elif mb != null:
				_target = _mouse_stage()


# --- Acciones ---

func _interact(action: String) -> void:
	match action:
		"to_hallway":
			_transition(func() -> void:
				_go_room("pasillo", 24.0)
				Sfx.ambient("pasillo"))
		"window":
			_play("prologo_ventanilla", Callable())
		"tv":
			_play("prologo_tv", Callable())
		"to_office":
			_transition(func() -> void:
				_go_room("oficina", 26.0)
				Sfx.ambient("oficina"))
		"talk_rafa":
			_flags["talked"] = true
			_stage.player_facing = Vector2.RIGHT
			_play("prologo_rafa", func() -> void:
				_play("prologo_incidente", _open_hire))
		"rack":
			_stage.prompt = {}
			_stage.player_facing = Vector2.RIGHT
			_phase = "busy"
			_stage.kneeling = true
			_play("prologo_descarga", _start_console)


func _go_room(room: String, x: float) -> void:
	_stage.room = room
	_stage.player_x = x
	_stage.player_depth = 0.0
	_stage.player_lat = 0.0
	_stage.player_facing = Vector2.UP if room == "pasillo" else Vector2.RIGHT
	_target = Vector2.INF
	_stage.cam_x = clampf(x - STAGE_SIZE.x / 2.0, 0.0, _stage.width() - STAGE_SIZE.x)
	if _phase != "intro":
		_phase = "walk"


func _transition(change: Callable) -> void:
	_phase = "busy"
	_fade_target = 1.0
	Sfx.play("swing", -10.0, 0.6)
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		change.call()
		_phase = "walk"
		_fade_target = 0.0)


func _play(id: String, on_done: Callable) -> void:
	var data: Dictionary = GameData.cutscenes.get(id, {})
	if data.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	_stage.prompt = {}
	_stage.walk_phase = -1.0
	_cutscene.play(data, on_done)


func _on_cutscene_effect(effect_name: String, strength: float) -> void:
	match effect_name:
		"lights_flicker":
			_stage.flicker = 1.6
			Sfx.play("lightning", -14.0, 0.5)
		"fans":
			_stage.rack_shake = 1.2
			Sfx.play("portal", -6.0, 0.6)
		"rafa_stands":
			_stage.rafa_standing = true
			Sfx.play("swing", -10.0)
		"shock":
			_flash = 1.0
			_glitch = 1.2
			_stage.rack_shake = 1.5
			Sfx.play("lightning")
			Sfx.play("explosion", -8.0, 1.4)
		"glitch":
			_glitch = maxf(_glitch, strength)


func _skip_to_hire() -> void:
	_fade = 1.0
	_fade_target = 0.0
	_go_room("oficina", 200.0)
	_stage.rafa_standing = true
	_flags["talked"] = true
	_phase = "hire"
	Sfx.ambient("oficina")
	_open_hire()


func _open_hire() -> void:
	_phase = "hire"
	_stage.prompt = {}
	_glitch = 0.4
	_hire = HireDialog.new()
	add_child(_hire)
	_hire.hired.connect(func(class_id: StringName) -> void:
		_class_id = class_id
		_hire.queue_free()
		_hire = null
		_flags["hired"] = true
		if bool(GameData.pending_creation.get("skip_prologue", false)):
			_start_title()
			return
		_phase = "walk"
		_play("prologo_trato", Callable()))


func _start_console() -> void:
	_phase = "console"
	_console_text = "\n".join(CONSOLE_LINES)
	_console_chars = 0.0
	Sfx.play("wave", -6.0, 0.7)


## La oficina se pixela: papeles en logs, cables en cobre y la ropa en binario.
func _start_fall() -> void:
	_phase = "fall"
	_fall_time = 0.0
	Sfx.ambient("kernel")
	Sfx.play("portal")


func _update_fall(delta: float) -> void:
	_fall_time += delta
	var t := clampf(_fall_time / 5.0, 0.0, 1.0)
	_stage.dissolve = t
	_stage.outfit_shift = clampf((_fall_time - 1.0) / 2.5, 0.0, 1.0)
	_stage.kneeling = _fall_time < 1.0
	_glitch = maxf(_glitch, 0.3 + 0.6 * t)
	if _fall_time > 4.5:
		_fade_target = 1.0
	if _fall_time > 5.6:
		_start_title()


func _start_title() -> void:
	_phase = "title"
	_title_time = 0.0
	_fade = 1.0
	_fade_target = 1.0
	Sfx.ambient("")
	Sfx.play("explosion", -4.0, 0.7)


func _finish() -> void:
	var class_id := _class_id if _class_id != &"" else StringName(GameData.classes[0]["id"])
	var c := GameData.create_character(_name, class_id, _appearance)
	c.flags["prologue_done"] = true
	GameData.save_character(c)
	GameData.current_character = c
	GameData.pending_creation = {}
	get_tree().change_scene_to_file(GameData.WORLD_SCENE)


# --- Capa de arriba: texto mecanografiado, consola, fundidos y título ---

func _draw_overlay() -> void:
	var view := size
	var font := get_theme_default_font()
	if _fade > 0.0:
		_overlay.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, _fade))
	match _phase:
		"intro":
			_draw_intro(view)
		"console":
			_draw_console(view)
		"fall":
			_draw_binary_rain(view, clampf(_fall_time / 3.0, 0.0, 1.0))
		"title":
			_draw_title(view)
	if _phase == "walk" and not _cutscene.is_playing():
		var hint := ("WASD o click: caminar" if _stage.room == "pasillo" else "A / D o click: caminar") + "   ·   E / click: interactuar   ·   Esc: saltar prólogo"
		_overlay.draw_string(font, Vector2(0, view.y - 14), hint, HORIZONTAL_ALIGNMENT_CENTER, view.x, 13, Color(1, 1, 1, 0.45))
		var place: String = String({"calle": "Av. del Mar, frente al malecón · Mazatlán · 13:47 · 38 °C", "pasillo": "UAdeO · Pasillo del Departamento de Informática",
			"oficina": "Departamento de Informática"}.get(_stage.room, ""))
		_overlay.draw_string(font, Vector2(24, 34), place, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
	if _skip_hint > 0.0:
		_overlay.draw_string(font, Vector2(0, 60), "Esc otra vez: saltar a la elección de puesto", HORIZONTAL_ALIGNMENT_CENTER, view.x, 16, Color(1, 0.85, 0.4, minf(1.0, _skip_hint)))


func _draw_intro(view: Vector2) -> void:
	_overlay.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.72))
	var shown := _intro_text.substr(0, int(_intro_chars))
	var box := Rect2(view.x * 0.16, view.y * 0.16, view.x * 0.68, view.y * 0.68)
	var y := box.position.y
	for paragraph in shown.split("\n"):
		var lines := _wrap(paragraph, box.size.x, 19)
		if lines.is_empty():
			y += 14.0
		for line in lines:
			var color := Color("e06c6c") if line.begins_with("Estado") or line.contains("RECHAZADO") else Color("e8e0c8")
			_overlay.draw_string(_mono, Vector2(box.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, color)
			y += 26.0
	if int(_time * 2.0) % 2 == 0:
		_overlay.draw_string(_mono, Vector2(box.position.x, y), "█", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e8e0c8"))
	if _intro_chars >= _intro_total:
		_overlay.draw_string(get_theme_default_font(), Vector2(0, view.y - 40), "Click o Espacio para continuar", HORIZONTAL_ALIGNMENT_CENTER, view.x, 15, Color(1, 1, 1, 0.5 + 0.3 * sin(_time * 4.0)))


func _draw_console(view: Vector2) -> void:
	_overlay.draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.0, 0.0, 0.78))
	var shown := _console_text.substr(0, int(_console_chars))
	var y := view.y * 0.25
	for line in shown.split("\n"):
		var jitter := Vector2(randf_range(-2, 2), 0) if _glitch > 0.2 else Vector2.ZERO
		_overlay.draw_string(_mono, Vector2(view.x * 0.12, y) + jitter, line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ff4a3a"))
		y += 34.0


## Lluvia de binario sobre la oficina que se deshace.
func _draw_binary_rain(view: Vector2, amount: float) -> void:
	var cols := 48
	for k in cols:
		var x := (k + 0.5) * view.x / cols
		var speed := 120.0 + float((k * 37) % 90)
		var head := fmod(_time * speed + k * 53.0, view.y + 200.0) - 100.0
		for j in 10:
			var y := head - j * 22.0
			var a := amount * (1.0 - j / 10.0) * 0.8
			_overlay.draw_string(_mono, Vector2(x, y), "1" if (k + j + int(_time * 8.0)) % 3 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
				Color(0.3, 1.0, 0.5, a) if j > 0 else Color(0.85, 1.0, 0.9, amount))


func _draw_title(view: Vector2) -> void:
	var font := get_theme_default_font()
	var t := _title_time
	var alpha := clampf((t - 0.6) / 0.8, 0.0, 1.0) * clampf((4.2 - t) / 0.6, 0.0, 1.0)
	var text := "EL ÚLTIMO COMMIT"
	var center := Vector2(0, view.y / 2.0 + 20)
	for k in 3:   # separación de canales que se va asentando
		var off := Vector2((k - 1) * maxf(0.0, 10.0 - t * 4.0), 0)
		var col: Color = [Color(1, 0.2, 0.3, alpha * 0.6), Color(0.2, 1, 0.8, alpha * 0.6), Color(0.95, 0.9, 0.8, alpha)][k]
		_overlay.draw_string(font, center + off, text, HORIZONTAL_ALIGNMENT_CENTER, view.x, 72, col)
	_overlay.draw_string(font, Vector2(0, view.y / 2.0 + 70), "Path Overflow", HORIZONTAL_ALIGNMENT_CENTER, view.x, 22, Color(UiStyle.ACCENT, alpha * 0.8))


func _wrap(text: String, width: float, font_size: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if text == "":
		return lines
	var current := ""
	for word in text.split(" "):
		var attempt := word if current == "" else current + " " + word
		if _mono.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width and current != "":
			lines.append(current)
			current = word
		else:
			current = attempt
	lines.append(current)
	return lines
