extends SceneTree
## Hoja de las poses del jugador por tipo de habilidad (T198): el alumno (HeroSprite,
## el del servidor) y el oficinista (PlayerSprite, prólogo y NPC) en sus tres
## direcciones, cuadro a cuadro, con el brillo de las manos donde lo hay. Guarda
## user://capturas/198_poses.png.
##
## Necesita dibujar: sin --headless.
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . -s res://tools/capture_player_poses.gd

## [estado, t]: la anticipación y el cuadro de impacto de cada pose (y las de antes, para comparar).
const POSES := [["idle", 0.0], ["attack", 0.6], ["cast", 0.8], ["channel", 0.3], ["shout", 0.25], ["shout", 0.75],
	["leap", 0.25], ["leap", 0.75], ["summon", 0.25], ["summon", 0.75], ["aura", 0.25], ["aura", 0.75]]
const FACINGS := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP]
const COL_W := 110.0
const ROW_H := 120.0
const ZOOM := 1.6

var _vp: SubViewport


func _initialize() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(int(COL_W * POSES.size() + 40), int(ROW_H * FACINGS.size() * 2 + 60))
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(_vp)
	var bg := ColorRect.new()
	bg.color = Color("3a3f48")
	bg.size = Vector2(_vp.size)
	_vp.add_child(bg)
	_build.call_deferred()


func _build() -> void:
	var look := CharacterAppearance.sanitize({"hair": 1, "hair_color": "7e4c2e", "skin_tone": "f6c8a0", "outfit_color": "2b4a8a", "eye_color": "5a4632"})
	var hero_look := StudentHero.look_of(look, {"weapon": ""})
	var glow := Color("e0652f")
	for i in POSES.size():
		var label := Label.new()
		label.text = "%s %.2f" % POSES[i]
		label.position = Vector2(20 + i * COL_W, 6)
		_vp.add_child(label)
		for d in FACINGS.size():
			var pose := {"state": POSES[i][0], "t": POSES[i][1], "time": 0.3, "weapon": "sword", "glow": glow}
			# Arriba, el alumno (con el brillo de las manos como lo pone Player).
			var hero := HeroSprite.new()
			hero.appearance = hero_look
			var feet := Vector2(70 + i * COL_W, 40 + (d + 1) * ROW_H - 20)
			hero.position = feet
			hero.scale = Vector2.ONE
			_vp.add_child(hero)
			hero.set_pose(FACINGS[d], pose)
			hero.scale *= ZOOM
			hero.position = feet
			if String(pose["state"]) in CharacterAppearance.GLOW_POSES:
				var lift := float(PlayerSprite.life(pose, -1.0)[1]) * HeroSprite.HERO_SCALE * ZOOM
				var dots := Node2D.new()
				var pts := HeroSprite.glow_points(String(pose["state"]), FACINGS[d])
				dots.draw.connect(func() -> void:
					for p in pts:
						var at: Vector2 = feet + Vector2(0.0, lift) + p * HeroSprite.HERO_SCALE * ZOOM
						dots.draw_circle(at, 6.0, Color(glow, 0.35))
						dots.draw_circle(at, 3.2, Color(glow.lightened(0.4), 0.8)))
				_vp.add_child(dots)
			# Abajo, el oficinista por capas.
			var office := PlayerSprite.new()
			office.sprite_scale = ZOOM * 0.75
			office.position = feet + Vector2(0, ROW_H * FACINGS.size())
			_vp.add_child(office)
			office.appearance = look
			office.set_pose(FACINGS[d], pose)
	for k in 4:
		await process_frame
	var img := _vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	img.save_png(ProjectSettings.globalize_path("user://capturas/198_poses.png"))
	print("guardada user://capturas/198_poses.png")
	quit()
