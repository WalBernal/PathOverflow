extends Node
## Captura las firmas de cuerpo a cuerpo y movimiento (T193) en partida: cada una de
## las ocho habilidades lanzada contra unos bichos, en dos momentos, y una hoja con
## todas juntas (user://capturas/193_firmas.png).
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . res://tools/capture_skill_fx.tscn
## Con  -- destellos  sale con «Menos destellos». Con  -- hechizos  saca las nueve firmas de
## hechizos y proyectiles (T194) en user://capturas/194_firmas.png. Con  -- buffs  saca los
## buffs, gritos y la barrera (195_buffs.png) y las seis auras (195_auras.png) de T195.

const OUT := "user://capturas/"
const IDS := ["barrido", "deploy_continuo", "reinicio_forzado", "force_push", "fuzzing", "teleport_tcp", "tunel_ssh", "git_revert"]
## Recorte alrededor del jugador y en qué momento (s) se saca cada una.
const CROP := Vector2i(560, 380)
const MOMENTS := [0.06, 0.16]
const SPELL_IDS := ["ping_letal", "fork_bomb", "stack_overflow", "flamewar", "rayo_produccion", "deadlock",
	"excepcion_en_cadena", "fuga_de_memoria", "core_dump"]
## Momentos propios de las que tienen retardo o duran más (T194).
const SPELL_MOMENTS := {"ping_letal": [0.05, 0.14], "fork_bomb": [0.3, 0.52], "stack_overflow": [0.08, 0.3], "rayo_produccion": [0.3, 0.52],
	"deadlock": [0.1, 0.6], "excepcion_en_cadena": [0.06, 0.2], "fuga_de_memoria": [0.1, 2.5], "core_dump": [0.1, 0.22]}

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
	if OS.get_cmdline_user_args().has("buffs"):
		await _run_buffs(world, c, items, skills, player, em, home)
		return
	if OS.get_cmdline_user_args().has("procs"):
		await _run_procs(c, items, skills, player, em, home)
		return
	var spells := OS.get_cmdline_user_args().has("hechizos")
	var ids: Array = SPELL_IDS if spells else IDS
	var sheet := Image.create(CROP.x * 4, CROP.y * 2 * ceili(ids.size() / 4.0), false, Image.FORMAT_RGBA8)
	for n in ids.size():
		var id: String = ids[n]
		var p := SkillCalc.compute(Motherboard.new(items.skills.skills[id], 10, []), c)
		var moments: Array = SPELL_MOMENTS.get(id, MOMENTS)
		for m in moments.size():
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
			var q := p
			if id == "core_dump":   # con cargas, para ver sus anillos
				c.charges["multihilo"] = 2
				c.charges["overclock"] = 1
				q = skills.call("_spend_charges", p)
			skills.call("_execute", q, aim)
			await _wait(moments[m] if id != "git_revert" else moments[m] + 0.6)
			var shot := get_viewport().get_texture().get_image()
			var center := Vector2i(from) + Vector2i(60, -20)
			var rect := Rect2i(center - CROP / 2, CROP).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
			shot.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(shot, rect, Vector2i((n % 4) * CROP.x, (n / 4 * 2 + m) * CROP.y))
			print("firma: %s a %.2f s (jugador en %s, recorte %s de %s)" % [id, moments[m], from, rect, shot.get_size()])
	var file := ("194_firmas" if spells else "193_firmas") + ("_destellos" if Accessibility.reduce_flashes else "")
	sheet.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
	print("captura: ", file)
	world.set("_since_save", -9999.0)
	get_tree().quit()


## Buffs, gritos, barrera y auras (T195): cada una al lanzarla y un rato después, con una
## invocación al lado (lo que lleva cada aliado) y bichos dentro (lo de las auras hostiles).
## Dos hojas: user://capturas/195_buffs.png y 195_auras.png (las auras, con más recorte).
func _run_buffs(world: Node, c: CharacterData, items: ItemDatabase, skills: SkillController, player: Player, em: EnemyManager, home: Vector2) -> void:
	# Las invocaciones también se van si su placa no está en la barra: el daemon, en la primera.
	c.inventory.boards[0] = Motherboard.new(items.skills.skills["daemon_segundo_plano"], 10, [])
	skills.refresh_profiles()
	var golem := skills.profile(0)
	for sheet_id in ["buffs", "auras"]:
		var ids: Array = SkillFx.BUFF_IDS if sheet_id == "buffs" else SkillFx.AURA_STYLE.keys()
		var crop := CROP if sheet_id == "buffs" else Vector2i(1100, 700)
		var moments := [0.15, 1.0] if sheet_id == "buffs" else [0.12, 1.2]
		var cols := 3 if sheet_id == "buffs" else 2
		var sheet := Image.create(crop.x * cols, crop.y * 2 * ceili(ids.size() / float(cols)), false, Image.FORMAT_RGBA8)
		for n in ids.size():
			var id: String = ids[n]
			var p := SkillCalc.compute(Motherboard.new(items.skills.skills[id], 10, []), c)
			if sheet_id == "auras":
				# Las auras se van si su placa no está en la barra: se pone en la última.
				var slot: int = c.inventory.boards.size() - 1
				c.inventory.boards[slot] = Motherboard.new(items.skills.skills[id], 10, [])
				skills.refresh_profiles()
				p = skills.profile(slot)
			for m in moments.size():
				em.clear_all()
				skills.clear_auras()
				skills.clear_units()
				skills.get("_effects").clear()
				player.global_position = home
				await _wait(0.25)
				for k in 5:
					var i := em.index_of(em.spawn(home + Vector2(110 + 24 * k, -40 + 22 * k), Rarity.Enemy.NORMAL))
					em.lives[i] *= 50.0
					em.max_lives[i] *= 50.0
					em.stun_index(i, 5.0)
				skills.call("_summon_unit", golem, home + Vector2(-60, 10), Color("5cb85c"))
				await _wait(0.05)
				# Recorte centrado en el jugador (la cámara puede ir con retraso tras moverlo).
				var from := player.get_global_transform_with_canvas().origin
				skills.call("_execute", p, home + Vector2(220, 0))
				if m == 1 and id == "hiperthreading":
					player.velocity = Vector2(120, 0)
				await _wait(moments[m] - 0.05)
				if m == 1 and id in ["firewall_personal", "modo_seguro"]:
					skills.call("_buff_fx_hit")
				await _wait(0.05)
				var shot := get_viewport().get_texture().get_image()
				var rect := Rect2i(Vector2i(from) + Vector2i(0, -20) - crop / 2, crop).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
				shot.convert(Image.FORMAT_RGBA8)
				sheet.blit_rect(shot, rect, Vector2i((n % cols) * crop.x, (n / cols * 2 + m) * crop.y))
				print("firma: %s a %.2f s%s" % [id, moments[m], " (aura activa)" if skills.is_aura_active(id) else ""])
		var file: String = "195_" + sheet_id + ("_destellos" if Accessibility.reduce_flashes else "")
		sheet.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
		print("captura: ", file)
	world.set("_since_save", -9999.0)
	get_tree().quit()


## Procs de ascendencia, señales de las RAM y una variante (T197): una hoja en
## user://capturas/197_senales.png. Los procs se piden directos a SkillController._proc.
func _run_procs(c: CharacterData, items: ItemDatabase, skills: SkillController, player: Player, em: EnemyManager, home: Vector2) -> void:
	var kinds: Array = SkillFx.PROC_LABELS.keys()
	var shots: Array = kinds + ["ram", "variante"]
	var cols := 4
	var sheet := Image.create(CROP.x * cols, CROP.y * ceili(shots.size() / float(cols)), false, Image.FORMAT_RGBA8)
	for n in shots.size():
		var kind: String = shots[n]
		em.clear_all()
		skills.get("_effects").clear()
		skills.get("_projectiles").clear()
		player.global_position = home
		await _wait(0.25)
		var from := player.get_global_transform_with_canvas().origin
		var at := home + Vector2(60, -20)
		if kind == "ram":   # Multicanal + perforación + encadenamiento + guiado
			var p := SkillCalc.compute(Motherboard.new(items.skills.skills["rafaga_de_paquetes"], 10, []), c)
			p["projectiles"] = 3
			p["pierce"] = 2
			p["projectile_chains"] = 1
			p["homing"] = true
			p["projectile_speed"] = 260.0
			skills.call("_execute", p, home + Vector2(220, 0))
		elif kind == "variante":   # Unicast: el matiz frío o cálido de la variante
			var board := Motherboard.new(items.skills.skills["rafaga_de_paquetes"], 20, [])
			board.variant = "unicast"
			skills.call("_execute", SkillCalc.compute(board, c), home + Vector2(220, 0))
		elif kind in ["profiled", "botnet"]:
			skills.call("_proc", kind, home, 8.0, Color("e8d070"), {"end": home + Vector2(200, -30), "duration": 0.6})
		else:
			skills.call("_proc", kind, at, 70.0, Color("8ad8ff") if kind in ["static", "nova", "bluescreen"] else Color("ffd060"), {"duration": 0.6})
		await _wait(0.2)
		var shot := get_viewport().get_texture().get_image()
		var rect := Rect2i(Vector2i(from) + Vector2i(60, -20) - CROP / 2, CROP).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
		shot.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(shot, rect, Vector2i((n % cols) * CROP.x, (n / cols) * CROP.y))
		print("señal: %s" % kind)
	sheet.save_png(ProjectSettings.globalize_path(OUT + "197_senales.png"))
	print("captura: 197_senales")
	get_tree().quit()


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout
