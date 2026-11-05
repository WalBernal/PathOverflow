extends Node
## Captura las firmas de cuerpo a cuerpo y movimiento (T193) en partida: cada una de
## las ocho habilidades lanzada contra unos bichos, en dos momentos, y una hoja con
## todas juntas (user://capturas/193_firmas.png).
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . res://tools/capture_skill_fx.tscn
## Con  -- destellos  sale con «Menos destellos».

const OUT := "user://capturas/"
const IDS := ["barrido", "deploy_continuo", "reinicio_forzado", "force_push", "fuzzing", "teleport_tcp", "tunel_ssh", "git_revert"]
## Recorte alrededor del jugador y en qué momento (s) se saca cada una.
const CROP := Vector2i(560, 380)
const MOMENTS := [0.06, 0.16]

var _current: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	LoadingCard.enabled = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run.call_deferred()


func _run() -> void:
	Accessibility.reduce_flashes = OS.get_cmdline_user_args().has("destellos")
	var gd: Node = get_node("/root/GameData")
	var items: ItemDatabase = gd.get("items")
	var c: CharacterData = gd.create_character("Firmas", &"templario", CharacterAppearance.default(), false)
	c.flags["zone"] = "zona1"
	c.flags["tutorial_step"] = 99
	c.flags["tutorial_seen_done"] = true
	gd.current_character = c
	var world: Node = load("res://scenes/game/world.tscn").instantiate()
	_current = world
	add_child(world)
	world.set("_since_save", -9999.0)
	await _wait(1.2)
	var skills: SkillController = world.get("skills")
	var player: Player = world.get("player")
	var em: EnemyManager = world.get("enemies")
	player.invulnerable = true
	var ui: Node = world.get("ui")
	if ui is CanvasLayer:
		(ui as CanvasLayer).visible = false   # sin HUD: solo el mundo
	var home := player.global_position
	var sheet := Image.create(CROP.x * 4, CROP.y * 4, false, Image.FORMAT_RGBA8)
	for n in IDS.size():
		var id: String = IDS[n]
		var p := SkillCalc.compute(Motherboard.new(items.skills.skills[id], 10, []), c)
		for m in MOMENTS.size():
			em.clear_all()
			skills.get("_effects").clear()
			skills.get("_clouds").clear()
			player.global_position = home
			await _wait(0.25)
			for k in 5:
				var i := em.index_of(em.spawn(home + Vector2(70 + 24 * k, -40 + 22 * k), Rarity.Enemy.NORMAL))
				em.lives[i] *= 50.0
				em.max_lives[i] *= 50.0
				em.stun_index(i, 5.0)
			await _wait(0.05)
			var from := Vector2(get_viewport().get_visible_rect().size / 2.0)   # la cámara sigue al jugador
			var aim := home + (Vector2(-200, 0) if id == "git_revert" else Vector2(220, 0))
			skills.call("_execute", p, aim)
			await _wait(MOMENTS[m] if id != "git_revert" else MOMENTS[m] + 0.6)
			var shot := get_viewport().get_texture().get_image()
			var center := Vector2i(from) + Vector2i(60, -20)
			var rect := Rect2i(center - CROP / 2, CROP).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
			shot.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(shot, rect, Vector2i((n % 4) * CROP.x, (n / 4 * 2 + m) * CROP.y))
			print("firma: %s a %.2f s (jugador en %s, recorte %s de %s)" % [id, MOMENTS[m], from, rect, shot.get_size()])
	var file := "193_firmas" + ("_destellos" if Accessibility.reduce_flashes else "")
	sheet.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
	print("captura: ", file)
	world.set("_since_save", -9999.0)
	get_tree().quit()


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout
