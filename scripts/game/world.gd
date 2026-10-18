class_name World
extends Node2D
## Escena de juego de prueba: suelo, personaje, enemigos, botín y UI.
## Teclas de depuración: F1 +100 enemigos, F2 limpiar, F3 jefe único,
## F4 soltar botín de prueba, R reaparecer.

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
## Hasta que exista el creador de personaje, se juega con esta clase.
const START_CLASS := &"guerrero"
const START_WEAPON := "espada_oxidada"
const INITIAL_ENEMIES := 60

var character: CharacterData
var player: Player
var enemies: EnemyManager
var loot: LootManager
var item_generator: ItemGenerator
var ui: GameUI


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("121016"))
	character = CharacterData.new(GameData.get_class_def(START_CLASS), GameData.passive_tree)
	item_generator = ItemGenerator.new(GameData.items)
	character.inventory.set_equipped("weapon", item_generator.generate(1, Rarity.Item.NORMAL, START_WEAPON))
	character.leveled_up.connect(_on_leveled_up)

	add_child(IsoGround.new())
	enemies = EnemyManager.new()
	add_child(enemies)
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.setup(character, enemies)
	enemies.player = player
	enemies.enemy_killed.connect(_on_enemy_killed)
	# Después del jugador: recibe los clicks antes que él (para recoger objetos).
	loot = LootManager.new()
	loot.player = player
	loot.inventory = character.inventory
	add_child(loot)

	ui = GameUI.new()
	add_child(ui)
	ui.setup(player, enemies, character, loot)
	player.died.connect(ui.show_death)

	spawn_wave(INITIAL_ENEMIES)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_spawn_wave"):
		spawn_wave(100)
	elif event.is_action_pressed(&"debug_clear_enemies"):
		enemies.clear_all()
	elif event.is_action_pressed(&"debug_spawn_boss"):
		enemies.spawn(player.global_position + Vector2.from_angle(randf() * TAU) * 600.0, Rarity.Enemy.UNIQUE)
	elif event.is_action_pressed(&"debug_drop_items"):
		drop_test_loot()
	elif event.is_action_pressed(&"respawn") and not player.is_alive():
		respawn()


## Grupos de 5-12 enemigos alrededor del jugador, a veces con un élite al frente.
func spawn_wave(count: int, min_distance := 450.0, max_distance := 1100.0) -> void:
	var spawned := 0
	while spawned < count:
		var center := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(min_distance, max_distance)
		var pack := mini(randi_range(5, 12), count - spawned)
		for k in pack:
			var rarity := Rarity.Enemy.NORMAL
			if k == 0 and randf() < 0.2:
				rarity = Rarity.Enemy.ELITE
			elif randf() < 0.12:
				rarity = Rarity.Enemy.SPECIAL
			enemies.spawn(center + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0)), rarity)
		spawned += pack


## Una muestra de cada rareza alrededor del jugador, para probar la UI.
## Usa el nivel del personaje, así que los objetos se pueden equipar.
func drop_test_loot() -> void:
	var item_level := enemies.area_level
	var rarities := [Rarity.Item.NORMAL, Rarity.Item.MAGIC, Rarity.Item.MAGIC, Rarity.Item.RARE, Rarity.Item.RARE,
		Rarity.Item.RARE, Rarity.Item.UNIQUE, Rarity.Item.SET, Rarity.Item.SET, Rarity.Item.ULTRA_RARE]
	for i in rarities.size():
		var offset := Vector2.from_angle(TAU * i / rarities.size()) * 140.0
		loot.drop_item(item_generator.generate(item_level, rarities[i]), player.global_position + offset)


func respawn() -> void:
	enemies.clear_all()
	player.global_position = Vector2.ZERO
	player.refill()
	ui.hide_death()
	spawn_wave(INITIAL_ENEMIES)


func _on_enemy_killed(rarity: int, experience: int, pos: Vector2) -> void:
	character.add_experience(experience)
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	for k in int(info["drop_count"]):
		if randf() < float(info["drop_chance"]):
			var item := item_generator.roll_drop(enemies.area_level, info["item_rarity_bonus"])
			loot.drop_item(item, pos + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0)))


## Los monstruos escalan con el personaje (y con ellos, el nivel de los objetos).
func _on_leveled_up(new_level: int) -> void:
	enemies.area_level = new_level
