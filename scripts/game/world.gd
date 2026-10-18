class_name World
extends Node2D
## Escena de juego: campamento seguro en el centro, enemigos alrededor, botín,
## habilidades y UI. Juega con GameData.current_character (elegido en la
## pantalla de inicio) y lo guarda automáticamente. Ejecutada sola (F6) usa un
## personaje temporal.
## Teclas de depuración: F1 +100 enemigos, F2 limpiar, F3 jefe único,
## F4 soltar botín de prueba, R reaparecer.

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
## Clase del personaje temporal al ejecutar esta escena sola.
const DEV_CLASS := &"guerrero"
const INITIAL_ENEMIES := 60
## Población que se intenta mantener alrededor del jugador fuera del campamento.
const TARGET_POPULATION := 70
const SPAWN_INTERVAL := 2.5
## Los enemigos más lejos que esto del jugador desaparecen (no cuentan como muertos).
const DESPAWN_DISTANCE := 2600.0
## Distancia mínima entre el borde del campamento y un grupo nuevo.
const CAMP_SPAWN_MARGIN := 250.0
## Tras un cambio (nivel, objetos, pasivas), se guarda como mucho cada X segundos.
const AUTOSAVE_DELAY := 5.0
## Y, aunque no cambie nada, cada X segundos (para el tiempo jugado).
const AUTOSAVE_INTERVAL := 60.0

var character: CharacterData
var player: Player
var enemies: EnemyManager
var loot: LootManager
var skills: SkillController
var camp: Camp
var item_generator: ItemGenerator
var ui: GameUI

var _dirty := false
var _since_save := 0.0
var _spawn_timer := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("121016"))
	character = GameData.current_character
	if character == null:
		character = GameData.create_character("Desarrollador", DEV_CLASS, CharacterAppearance.default(), false)
	item_generator = ItemGenerator.new(GameData.items)
	character.leveled_up.connect(_on_leveled_up)
	character.inventory.changed.connect(_mark_dirty)
	character.passives.changed.connect(_mark_dirty)
	character.stats_changed.connect(_mark_dirty)  # incluye cambio de ascendencia

	add_child(IsoGround.new())
	camp = Camp.new()
	add_child(camp)
	enemies = EnemyManager.new()
	add_child(enemies)
	enemies.safe_center = Vector2.ZERO
	enemies.safe_radius = camp.radius
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.global_position = camp.spawn_point
	player.setup(character, enemies)
	enemies.player = player
	enemies.enemy_killed.connect(_on_enemy_killed)
	camp.player = player
	camp.character = character
	skills = SkillController.new()
	add_child(skills)
	skills.setup(player, enemies, character)
	# Después del jugador: reciben los clicks antes que él (recoger, hablar).
	loot = LootManager.new()
	loot.player = player
	loot.inventory = character.inventory
	add_child(loot)
	loot.picked_up.connect(_on_item_picked_up)

	ui = GameUI.new()
	add_child(ui)
	ui.setup(player, enemies, character, loot, skills, camp)
	player.died.connect(ui.show_death)
	player.died.connect(func() -> void:
		character.flags["stat_deaths"] = int(character.flags.get("stat_deaths", 0)) + 1
		_mark_dirty())
	ui.return_to_menu_requested.connect(_return_to_menu)
	ui.quit_requested.connect(_quit_game)
	ui.dialogue_action.connect(_on_dialogue_action)
	camp.npc_interacted.connect(_on_npc_interacted)

	enemies.area_level = character.level
	spawn_wave(INITIAL_ENEMIES)
	if character.flags.has("passives_refunded"):
		character.flags.erase("passives_refunded")
		ui.hud.flash.call_deferred("El árbol pasivo ha cambiado: te hemos devuelto todos los puntos (P).", UiStyle.ACCENT)


func _process(delta: float) -> void:
	character.play_time += delta
	_since_save += delta
	if (_dirty and _since_save >= AUTOSAVE_DELAY) or _since_save >= AUTOSAVE_INTERVAL:
		save_now()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		enemies.despawn_beyond(player.global_position, DESPAWN_DISTANCE)
		if player.is_alive() and not camp.contains(player.global_position) and enemies.count() < TARGET_POPULATION:
			spawn_wave(randi_range(6, 12), 750.0, 1200.0)


## Cerrar la ventana también guarda.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func save_now() -> void:
	GameData.save_character(character)
	_dirty = false
	_since_save = 0.0


func _mark_dirty() -> void:
	_dirty = true


func _return_to_menu() -> void:
	save_now()
	get_tree().paused = false
	GameData.current_character = null
	get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE)


func _quit_game() -> void:
	save_now()
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_spawn_wave"):
		spawn_wave(100)
	elif event.is_action_pressed(&"debug_clear_enemies"):
		enemies.clear_all()
	elif event.is_action_pressed(&"debug_spawn_boss"):
		enemies.spawn(_spawn_center(500.0, 700.0), Rarity.Enemy.UNIQUE)
	elif event.is_action_pressed(&"debug_drop_items"):
		drop_test_loot()
	elif event.is_action_pressed(&"respawn") and not player.is_alive():
		respawn()


## Grupos de 5-12 enemigos del mismo tipo alrededor del jugador (nunca dentro
## del campamento), a veces con un élite al frente.
func spawn_wave(count: int, min_distance := 450.0, max_distance := 1100.0) -> void:
	var spawned := 0
	while spawned < count:
		var center := _spawn_center(min_distance, max_distance)
		var pack := mini(randi_range(5, 12), count - spawned)
		var type := enemies.random_type()
		for k in pack:
			var rarity := Rarity.Enemy.NORMAL
			if k == 0 and randf() < 0.2:
				rarity = Rarity.Enemy.ELITE
			elif randf() < 0.12:
				rarity = Rarity.Enemy.SPECIAL
			enemies.spawn(center + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0)), rarity, type)
		spawned += pack


## Un punto a esa distancia del jugador y lejos del campamento.
func _spawn_center(min_distance: float, max_distance: float) -> Vector2:
	var min_from_camp := camp.radius + CAMP_SPAWN_MARGIN
	for attempt in 30:
		var c := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(min_distance, max_distance)
		if c.length() > min_from_camp:
			return c
	# El jugador está en el campamento: hacia fuera, en cualquier dirección.
	return Vector2.from_angle(randf() * TAU) * (min_from_camp + randf_range(0.0, max_distance - min_distance))


## Una muestra de cada rareza alrededor del jugador, para probar la UI.
## Usa el nivel del personaje, así que los objetos se pueden equipar.
func drop_test_loot() -> void:
	var item_level := enemies.area_level
	var rarities := [Rarity.Item.NORMAL, Rarity.Item.MAGIC, Rarity.Item.RARE, Rarity.Item.RARE,
		Rarity.Item.UNIQUE, Rarity.Item.SET, Rarity.Item.ULTRA_RARE]
	var items: Array[Item] = []
	for r in rarities:
		items.append(item_generator.generate(item_level, r))
	items.append(item_generator.generate_motherboard(item_level, "", 6))
	items.append(item_generator.generate_ram(item_level))
	items.append(item_generator.generate_ram(item_level))
	for i in items.size():
		var offset := Vector2.from_angle(TAU * i / items.size()) * 140.0
		loot.drop_item(items[i], player.global_position + offset)


func respawn() -> void:
	enemies.clear_all()
	loot.clear_all()
	player.global_position = camp.spawn_point
	player.refill()
	ui.hide_death()
	spawn_wave(INITIAL_ENEMIES)


func _on_enemy_killed(rarity: int, experience: int, pos: Vector2) -> void:
	character.add_experience(experience)
	character.flags["stat_kills"] = int(character.flags.get("stat_kills", 0)) + 1
	player.add_flask_charges(rarity)
	player.notify_kill()
	ui.tutorial.notify("kill")
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	for k in int(info["drop_count"]):
		if randf() < float(info["drop_chance"]):
			var item := item_generator.roll_drop(enemies.area_level, info["item_rarity_bonus"])
			loot.drop_item(item, pos + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0)))


## Los monstruos escalan con el personaje (y con ellos, el nivel de los objetos).
func _on_leveled_up(new_level: int) -> void:
	enemies.area_level = new_level
	ui.hud.flash("¡Nivel %d! Tienes un punto de pasiva nuevo (P)." % new_level, UiStyle.ACCENT)


## Pistas la primera vez que se recoge una placa base o un módulo RAM.
func _on_item_picked_up(item: Item) -> void:
	if item is Motherboard and not character.flags.has("hint_board"):
		character.flags["hint_board"] = true
		ui.hud.flash("¡Una placa base! Es una habilidad: instálala en la barra con K.", UiStyle.ACCENT)
	elif item is RamModule and not character.flags.has("hint_ram"):
		character.flags["hint_ram"] = true
		ui.hud.flash("¡Un módulo RAM! Mejora una habilidad: ponlo en una ranura de su color (K).", UiStyle.ACCENT)


# --- NPCs ---

func _on_npc_interacted(npc: Dictionary) -> void:
	character.flags["talked_" + String(npc["id"])] = true
	ui.open_dialogue(npc, camp.dialogues.get(npc.get("dialogue", ""), {}))


func _on_dialogue_action(action: Dictionary) -> void:
	var flag: String = action.get("flag", "")
	if flag != "" and character.flags.has(flag):
		return  # ya se dio
	match action.get("type", ""):
		"give_item":
			var item: Item
			if action.get("kind", "") == "motherboard":
				item = item_generator.generate_motherboard(maxi(1, character.level), action.get("id", ""), 3)
			else:
				item = item_generator.generate_ram(character.level, action.get("id", ""))
			_give(item)
		"give_matching_ram":
			_give(_matching_ram())
		"refill":
			player.refill()
		"set_flag":
			pass
	if flag != "":
		character.flags[flag] = true
	_mark_dirty()


## Un módulo RAM que encaje y funcione en la primera placa de la barra.
func _matching_ram() -> RamModule:
	var board: Motherboard = null
	for b in character.inventory.boards:
		if b:
			board = b
			break
	if board == null:
		return item_generator.generate_ram(character.level)
	var options: Array = []
	for id in GameData.items.skills.rams:
		var ram := item_generator.generate_ram(character.level, id)
		if board.slots.has(ram.generation()) and ram.supports(board.skill_def):
			options.append(ram)
	return options.pick_random() if not options.is_empty() else item_generator.generate_ram(character.level)


func _give(item: Item) -> void:
	if character.inventory.add_item(item):
		ui.hud.flash("Recibido: %s" % item.display_name(), UiStyle.ACCENT)
	else:
		loot.drop_item(item, player.global_position + Vector2(0, 40))
		ui.hud.flash("Inventario lleno: %s está en el suelo." % item.display_name())
