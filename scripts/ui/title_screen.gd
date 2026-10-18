class_name TitleScreen
extends Control
## Pantalla de título: logo de «Path Overflow», lluvia de binario, snippets de
## código flotando, un grafo de git roto, bugs cruzando la pantalla, un rack de
## servidores echando vapor y un café humeante. Con música. Cualquier tecla o
## click continúa a la lista de personajes.

const SNIPPETS := [
	"console.log('hola, exiliado');", "git push --force origin main", "sudo rm -rf /bugs",
	"while (true) { farmear(); }", "// TODO: sobrevivir", "Segmentation fault (core dumped)",
	"npm install esperanza", "404: Héroe no encontrado", "System.out.println(\"ayuda\");",
	"git blame --everyone", "SELECT * FROM esperanza; -- 0 rows", "throw new Error('motivación');",
	"merge conflict in vida.gd", "docker run --rm exiliado", "if (lunes) { return; }",
]
const ENEMY_ATLAS := preload("res://assets/sprites/enemies/enemies.png")

var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _columns: Array[Dictionary] = []     # lluvia de binario
var _snippets: Array[Dictionary] = []    # textos flotando
var _bugs: Array[Dictionary] = []        # bichos cruzando
var _logo: GameLogo
var _leaving := false


func _ready() -> void:
	_rng.randomize()
	theme = UiStyle.make_theme()
	MusicPlayer.play_title()
	_logo = GameLogo.new()
	add_child(_logo)
	_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo.offset_bottom = -120.0
	_logo.logo_scale = 1.15
	var mute := UiStyle.button("Música: sí" if not MusicPlayer.muted else "Música: no", func() -> void: pass, 130)
	mute.pressed.connect(func() -> void: mute.text = "Música: no" if MusicPlayer.toggle_mute() else "Música: sí")
	mute.focus_mode = Control.FOCUS_NONE
	add_child(mute)
	mute.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_init_effects()


func _init_effects() -> void:
	var view := get_viewport_rect().size
	for x in range(0, int(view.x), 22):
		_columns.append({"x": float(x), "y": _rng.randf_range(-view.y, view.y), "speed": _rng.randf_range(40, 140),
			"length": _rng.randi_range(6, 18), "seed": _rng.randi()})
	for k in 9:
		_snippets.append(_new_snippet(view, true))
	for k in 3:
		_bugs.append(_new_bug(view))


func _new_snippet(view: Vector2, anywhere := false) -> Dictionary:
	return {"text": SNIPPETS[_rng.randi_range(0, SNIPPETS.size() - 1)], "x": _rng.randf_range(20, view.x - 320),
		"y": _rng.randf_range(0, view.y) if anywhere else view.y + 20.0, "speed": _rng.randf_range(12, 30),
		"alpha": _rng.randf_range(0.12, 0.3)}


func _new_bug(view: Vector2) -> Dictionary:
	var from_left := _rng.randf() < 0.5
	return {"x": -60.0 if from_left else view.x + 60.0, "y": _rng.randf_range(view.y * 0.62, view.y * 0.92),
		"dir": 1.0 if from_left else -1.0, "speed": _rng.randf_range(50, 110), "row": [0, 2, 3][_rng.randi_range(0, 2)]}


func _process(delta: float) -> void:
	_time += delta
	var view := size
	for c in _columns:
		c["y"] += c["speed"] * delta
		if c["y"] - c["length"] * 16.0 > view.y:
			c["y"] = _rng.randf_range(-200.0, 0.0)
	for i in _snippets.size():
		_snippets[i]["y"] -= _snippets[i]["speed"] * delta
		if _snippets[i]["y"] < -30.0:
			_snippets[i] = _new_snippet(view)
	for i in _bugs.size():
		_bugs[i]["x"] += _bugs[i]["dir"] * _bugs[i]["speed"] * delta
		if _bugs[i]["x"] < -80.0 or _bugs[i]["x"] > view.x + 80.0:
			_bugs[i] = _new_bug(view)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if pressed and not _leaving:
		_leaving = true
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color(0, 0, 0, 1), 0.4)
		tween.tween_callback(func() -> void: get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE))


func _draw() -> void:
	var view := size
	draw_rect(Rect2(Vector2.ZERO, view), Color("07060a"))
	var font := get_theme_default_font()
	# Lluvia de binario.
	for c in _columns:
		for k in int(c["length"]):
			var y: float = c["y"] - k * 16.0
			if y < -16.0 or y > view.y:
				continue
			var bit := "1" if (int(c["seed"]) + k + int(_time * 6.0)) % 3 == 0 else "0"
			var alpha: float = (1.0 - float(k) / c["length"]) * (0.5 if k == 0 else 0.22)
			draw_string(font, Vector2(c["x"], y), bit, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.25, 0.95, 0.45, alpha))
	# Snippets flotando.
	for snip in _snippets:
		draw_string(font, Vector2(snip["x"], snip["y"]), snip["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.85, 0.8, 0.6, snip["alpha"]))
	_draw_git_graph(Vector2(70, view.y * 0.18), font)
	_draw_server_rack(Vector2(view.x - 170, view.y - 300))
	_draw_coffee(Vector2(150, view.y - 120))
	for b in _bugs:
		_draw_bug(b)
	# Viñeta.
	for k in 8:
		var a := 0.06 * (8 - k) / 8.0
		draw_rect(Rect2(Vector2.ZERO, Vector2(view.x, 26.0 * (8 - k))), Color(0, 0, 0, a))
		draw_rect(Rect2(Vector2(0, view.y - 26.0 * (8 - k)), Vector2(view.x, 26.0 * (8 - k))), Color(0, 0, 0, a))
	# Indicación parpadeante y versión.
	var cursor := "_" if fmod(_time, 1.0) < 0.5 else " "
	var prompt := "> pulsa cualquier tecla para continuar" + cursor
	var pw := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2((view.x - pw) / 2.0, view.y - 120.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3cff6a"))
	draw_string(font, Vector2(16, view.y - 16), "v0.1.0-alpha · compilado con café · inestable, como el código", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.MUTED)


## Grafo de git: main, una rama de feature y el commit que lo rompió todo.
func _draw_git_graph(origin: Vector2, font: Font) -> void:
	var main_x := origin.x
	var branch_x := origin.x + 34.0
	var step := 46.0
	var color_main := Color("5cb85c")
	var color_branch := Color("4b8bd6")
	draw_line(origin, origin + Vector2(0, step * 8), Color(color_main, 0.6), 3.0)
	draw_line(origin + Vector2(0, step * 2), Vector2(branch_x, origin.y + step * 3), Color(color_branch, 0.6), 3.0)
	draw_line(Vector2(branch_x, origin.y + step * 3), Vector2(branch_x, origin.y + step * 5), Color(color_branch, 0.6), 3.0)
	draw_line(Vector2(branch_x, origin.y + step * 5), origin + Vector2(0, step * 6), Color(color_branch, 0.6), 3.0)
	var labels := ["init", "añade login", "fix login", "feature/monolito", "más monolito", "MERGE", "hotfix viernes 18:00", "push --force"]
	for k in 8:
		var on_branch := k >= 3 and k <= 4
		var p := Vector2(branch_x if on_branch else main_x, origin.y + step * k + (step * 0.5 if on_branch else 0.0))
		var last := k == 7
		var c := Color("e06c6c") if last else (color_branch if on_branch else color_main)
		var pulse := (0.5 + 0.5 * sin(_time * 5.0)) if last else 1.0
		draw_circle(p, 7.0, Color(c, 0.4 + 0.6 * pulse))
		draw_string(font, p + Vector2(16, 5), labels[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(c, 0.55))
	draw_string(font, origin + Vector2(-8, step * 7 + 30), "HEAD -> main (roto)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e06c6c"))


func _draw_server_rack(p: Vector2) -> void:
	var box := Rect2(p, Vector2(110, 210))
	draw_rect(box, Color("191c23"))
	draw_rect(box, Color("3a3f4a"), false, 2.0)
	for k in 9:
		var y := p.y + 12.0 + k * 22.0
		draw_rect(Rect2(Vector2(p.x + 8, y), Vector2(94, 16)), Color("23262e"))
		for led in 3:
			var on := sin(_time * (3.0 + k * 0.7 + led) + k) > 0.2
			draw_circle(Vector2(p.x + 80 + led * 7, y + 8), 2.0, (Color("3cff6a") if led != 2 else Color("e06c6c")) if on else Color("1a2a1a"))
	# Vapor: el servidor se está cociendo.
	for k in 4:
		var phase := fmod(_time * 0.35 + k * 0.25, 1.0)
		draw_circle(p + Vector2(30 + k * 18 + sin(_time + k) * 6.0, -10.0 - phase * 70.0), 8.0 + phase * 10.0, Color(0.8, 0.8, 0.85, 0.12 * (1.0 - phase)))


func _draw_coffee(p: Vector2) -> void:
	ItemIcons.draw(self, Rect2(p - Vector2(40, 40), Vector2(80, 80)), "flask_coffee", Color.WHITE, false)
	for k in 3:
		var phase := fmod(_time * 0.5 + k * 0.33, 1.0)
		var q := p + Vector2(-8 + k * 9 + sin(_time * 2.0 + k) * 4.0, -36.0 - phase * 50.0)
		draw_line(q, q + Vector2(sin(_time * 3.0 + k) * 4.0, -10.0), Color(1, 1, 1, 0.35 * (1.0 - phase)), 2.0, true)


func _draw_bug(b: Dictionary) -> void:
	var frame := int(_time * 8.0) % 4
	var region := Rect2(frame * 32, int(b["row"]) * 32, 32, 32)
	var dest := Rect2(Vector2(b["x"], b["y"]) - Vector2(32, 32), Vector2(64, 64))
	if b["dir"] < 0.0:
		dest = Rect2(dest.position + Vector2(64, 0), Vector2(-64, 64))  # mirando a la izquierda
	draw_texture_rect_region(ENEMY_ATLAS, dest, region, Color(1, 1, 1, 0.85))
