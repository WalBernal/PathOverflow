extends SceneTree
## Pruebas rápidas de la lógica pura (stats, árbol, objetos, datos). Ejecutar con:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_core.gd

var _failures := 0
var _tree: PassiveTree
var _db: ItemDatabase
var _classes: Array
var _script_errors := ScriptErrorCounter.new()


## Un SCRIPT ERROR dentro de una prueba la corta sin que falle ningún _check:
## se cuentan aparte y hacen fallar la tanda (los errores normales que provocan
## a propósito las pruebas de guardados dañados no cuentan).
class ScriptErrorCounter extends Logger:
	var mutex := Mutex.new()
	var errors: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_SCRIPT:
			return
		mutex.lock()
		errors.append("%s (%s:%d, %s)" % [rationale if rationale != "" else code, file, line, function])
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _initialize() -> void:
	OS.add_logger(_script_errors)
	_tree = PassiveTree.load_from_json("res://data/passive_tree.json")
	_db = ItemDatabase.load_from_dir()
	_classes = DataLoader.load_json("res://data/classes.json")["classes"]
	AscendancyTree.expand_classes(_classes)
	_test_stat_formula()
	_test_passive_tree()
	_test_data_integrity()
	_test_experience()
	_test_enemies()
	_test_input_map()
	_test_item_data()
	_test_item_generation()
	_test_local_mods()
	_test_inventory_and_equipment()
	_test_sets()
	_test_character_round_trip()
	_test_passive_load_validation()
	_test_save_files()
	_test_name_validation()
	_test_appearance()
	_test_skill_data()
	_test_motherboards_and_ram()
	_test_skill_calc()
	_test_boards_save()
	_test_enemy_hit_one()
	_test_camp_and_tutorial_data()
	_test_item_transfer()
	_test_item_icons()
	_test_tree_clusters()
	_test_conditions()
	_test_tree_version_refund()
	_test_save_dir_migration()
	_test_quests()
	_test_loot_placement()
	_test_tree_layout()
	_test_new_skills()
	_test_enemy_attacks()
	_test_skill_tags()
	_test_new_supports()
	_test_flasks()
	_test_act2_layout()
	_test_act2_mechanics()
	_test_progression_rules()
	_test_latam_spanish()
	_test_ascendancy_rules()
	_test_zone_scale()
	_test_roadmap2()
	_test_roadmap2_second_batch()
	_test_roadmap2_feel()
	_test_controls_map_catalog()
	_test_enemy_roles()
	_test_golems()
	_test_movement_skills()
	_test_dodge_upgrades()
	_test_terrains()
	_test_arena_mechanics()
	_test_boss_arena_phases()
	_test_mechanic_tips()
	_test_rule_keystones()
	_test_masteries()
	_test_trigger_rams()
	_test_charges_build()
	_test_tree_conversion()
	_test_sacrifice_and_conditions()
	_test_summoner_keystones()
	_test_chain_detonation()
	_test_warcries()
	_test_docker_container()
	_test_channelled_spells()
	_test_more_variants()
	_test_class_signatures()
	_test_transforming_chips()
	_test_builds_and_compare()
	_test_act4_world()
	_test_act4_story()
	_test_act4_boss()
	_test_new_zone_events()
	_test_roles_and_commander()
	_test_state_reactions()
	_test_lore_notes()
	_test_dialogue_decisions()
	_test_camp_upgrades()
	_test_nemesis()
	_test_crafting_patches()
	_test_incidents()
	_test_atlas()
	_test_difficulties()
	_test_zone_scaling()
	_test_side_quest_rewards()
	_test_more_uniques_and_sets()
	_test_achievements()
	_test_ladder()
	_test_tech_debt()
	_test_gamepad_cursor()
	_test_ring_comparison()
	_test_controls()
	_test_accessibility()
	_test_auto_attack()
	_test_map_marks()
	_test_loot_filter_rules()
	_test_ambient_emitters()
	_test_barks()
	_test_enemy_materials()
	_test_lights_weather()
	_test_obstacle_art()
	_test_stress_music()
	_test_audio_ogg()
	_test_telemetry()
	_test_render_batching()
	_test_skill_balance()
	_test_shop_stock()
	_test_shop_coat()
	_test_player_poses()
	_test_impact_frame()
	_test_enemy_weight()
	_test_skill_fx()
	_test_pixel_icons()
	_test_ui_identity()
	_test_sound_map()
	_test_stingers()
	_test_inventory_marks()
	_test_stash_tabs()
	_test_stat_breakdown()
	_test_window_memory()
	_test_passive_plan()
	_test_tree_identity()
	_test_tree_art()
	_test_bases_and_unique_mechanics()
	_test_crafting_decisions()
	_test_tree_v2_layout()
	_test_tree_migration()
	_test_tree_families()
	_test_mana_family()
	_test_new_keystones()
	_test_tree_extras()
	_test_tree_art_v2()
	_test_ui_atlas()
	_test_screens_t96()
	_test_ui_motion()
	_test_graphics_quality()
	_test_fx_art()
	_test_ambience()
	_test_enemy_sheet()
	_test_player_sheet()
	_test_npcs_and_boss_intro()
	_test_ground_loot()
	_test_token_pickup()
	_test_waypoint_reach()
	_test_no_back_portals()
	_test_zone_layout()
	_test_generated_zones()
	_test_zone_shapes()
	_test_zone_content()
	_test_zone_instances()
	_test_zone_mechanics()
	_test_new_mechanics_t121()
	_test_new_mechanics_t122()
	_test_set_pieces()
	_test_scene_depth()
	_test_minimap_fog()
	_test_waypoint_map()
	_test_board_compare()
	_test_event_log()
	_test_cutscene_direction()
	_test_missing_scenes()
	_test_mobile_defaults()
	_test_ui_proposals()
	_test_touch_controls()
	_test_tilesets()
	_test_events_music_colorblind()
	_test_story_editor()
	_test_board_milestones()
	_test_shaped_clusters()
	_test_defense_and_dot_skills()
	_test_walk_animation()
	_test_audio_assets()
	_test_economy_and_stash()
	_test_appearance_and_dialogue_flow()
	_test_prologue_data()
	_test_class_kits_and_robotics()
	_test_act3_mechanics()
	_test_ailments()
	_test_ailment_supports_and_tree()
	_test_persistent_units()
	_test_unique_class_kits()
	_test_tutorial_safe_start()
	_test_chain_tiers()
	_test_auras_and_unit_abilities()
	_test_resists_and_affixes()
	_test_boss_phases()
	_test_ascendancy_identity()
	_test_player_statuses()
	_test_state_interactions()
	_test_new_affixes_and_phase_resists()
	_test_ram_grades()
	_test_tree_themes_and_spacing()
	_test_thermal_shock_and_status_resist()
	_test_music_and_voices()
	_test_quest_item_art()
	_test_rams_everywhere()
	_test_prologue_reachable()
	OS.remove_logger(_script_errors)
	for e in _script_errors.errors:
		_check(false, "SCRIPT ERROR durante las pruebas: " + e)
	if _failures == 0:
		print("OK: todas las pruebas pasaron")
	else:
		printerr("%d prueba(s) fallaron" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FALLO: " + message)


func _new_character() -> CharacterData:
	return CharacterData.new(_classes[0], _tree)


func _test_stat_formula() -> void:
	var s := StatBlock.new()
	s.set_base(Stat.LIFE, 100.0)
	s.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.FLAT, 50.0))
	s.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.INCREASED, 20.0))
	s.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.INCREASED, 30.0))
	s.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.MORE, 10.0))
	s.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.MORE, 10.0))
	# (100 + 50) × 1.5 × 1.1 × 1.1
	_check(is_equal_approx(s.get_value(Stat.LIFE), 272.25), "fórmula base: %s" % s.get_value(Stat.LIFE))

	s.set_base(Stat.FIRE_DAMAGE, 100.0)
	s.add_modifier(Modifier.new(Stat.DAMAGE, Modifier.Type.INCREASED, 10.0))
	s.add_modifier(Modifier.new(Stat.ELEMENTAL_DAMAGE, Modifier.Type.INCREASED, 20.0, [Stat.TAG_SPELL]))
	_check(is_equal_approx(s.get_value(Stat.FIRE_DAMAGE), 110.0), "herencia de 'daño' al fuego")
	_check(is_equal_approx(s.get_value(Stat.FIRE_DAMAGE, [Stat.TAG_SPELL]), 130.0), "tag 'spell' condicional")

	s.remove_source("")
	_check(is_equal_approx(s.get_value(Stat.LIFE), 100.0), "remove_source")
	_check(Modifier.new(Stat.LIFE, Modifier.Type.INCREASED, 8.0).describe() == "8% de aumento de Vida máxima", "describe()")


func _test_passive_tree() -> void:
	_check(_tree != null and _tree.nodes.size() >= 150, "carga del árbol")
	var start := _tree.get_start_node_for_class(&"guerrero")
	var alloc := PassiveAllocation.new(_tree, start)
	for id in _tree.nodes:
		var n: PassiveNode = _tree.nodes[id]
		if n.kind != PassiveNode.Kind.CLASS_START:
			_check(not alloc.find_path(id).is_empty(), "nodo %d inalcanzable" % id)
	var keystone := -1
	for id in _tree.nodes:
		if _tree.nodes[id].kind == PassiveNode.Kind.KEYSTONE:
			keystone = id
			break
	var path := alloc.find_path(keystone)
	_check(alloc.allocate_path(keystone, 0) == 0, "no debe asignar sin puntos")
	var spent := alloc.allocate_path(keystone, 999)
	_check(spent == path.size() and alloc.spent_points() == spent, "coste del camino")
	if path.size() > 1:
		_check(not alloc.can_refund(path[0]), "no se puede quitar un nodo intermedio")
	_check(alloc.refund(keystone), "se puede quitar una hoja")
	_check(not alloc.refund(start), "no se puede quitar el inicio")
	_check(alloc.find_path(_tree.get_start_node_for_class(&"hechicero")).is_empty(), "inicio ajeno bloqueado")


func _test_data_integrity() -> void:
	for id in _tree.nodes:
		for m in _tree.get_node_data(id).mods:
			_check(Stat.exists(m.stat), "stat desconocido '%s' en nodo %d" % [m.stat, id])
	_check(_classes.size() == 7, "deben existir 7 clases")
	for c in _classes:
		_check(_tree.get_start_node_for_class(StringName(c["id"])) != -1, "inicio de %s" % c["id"])
		_check(c["ascendancies"].size() == 2, "%s debe tener 2 ascendencias" % c["id"])
		for a in c["ascendancies"]:
			for p in a["passives"]:
				for md in p["mods"]:
					_check(Stat.exists(StringName(md["stat"])), "stat desconocido '%s' en %s" % [md["stat"], a["id"]])


func _test_experience() -> void:
	var c := _new_character()
	var points_before := c.passive_points_total()
	c.add_experience(c.experience_to_next() + 5)
	_check(c.level == 2 and c.experience == 5, "subir de nivel con experiencia")
	_check(c.passive_points_total() == points_before + 1, "un punto de pasiva por nivel")


func _test_enemies() -> void:
	var em := EnemyManager.new()
	var kills := [0]
	em.enemy_killed.connect(func(_r: int, _xp: int, _pos: Vector2, _type: String) -> void: kills[0] += 1)
	# Tipo fijo: con tipos aleatorios, un node_modules (mucha vida) podría sobrevivir.
	var bug := em.type_index_of("bug")
	em.spawn(Vector2(0, 0), Rarity.Enemy.NORMAL, bug)
	em.spawn(Vector2(10, 0), Rarity.Enemy.UNIQUE)
	em.spawn(Vector2(1000, 0), Rarity.Enemy.NORMAL, bug)
	_check(em.max_lives[1] > em.max_lives[0], "el único tiene más vida que el normal")
	var hits := em.hit_in_radius(Vector2.ZERO, 50.0, 100.0, 100.0, 0.0, 150.0)
	_check(hits == 2, "golpea solo a los que están en el radio (%d)" % hits)
	_check(kills[0] == 1 and em.count() == 2, "muere el normal, sobrevive el único")
	_check(em.positions.has(Vector2(1000, 0)) and em.positions.has(Vector2(10, 0)), "swap-remove conserva los datos")
	em.clear_all()
	_check(em.count() == 0 and em.names.size() == 0, "clear_all vacía todos los arrays")
	em.free()


func _test_input_map() -> void:
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6", &"flask_1", &"flask_2", &"toggle_skills", &"toggle_character", &"toggle_minimap", &"toggle_passives",
			&"toggle_inventory", &"respawn", &"debug_spawn_wave", &"debug_clear_enemies", &"debug_spawn_boss",
			&"debug_drop_items"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "acción '%s'" % action)
	if InputMap.has_action(&"debug_drop_items"):
		var ev := InputMap.action_get_events(&"debug_drop_items")[0] as InputEventKey
		_check(ev != null and ev.physical_keycode == KEY_F4, "F4 = botín de prueba")


func _test_item_data() -> void:
	_check(_db.bases.size() >= 20 and _db.affixes.size() >= 15, "carga de bases y afijos")
	for b in _db.bases.values():
		_check(Inventory.EQUIP_SLOTS.has(b["slot"]) or b["slot"] == "ring", "ranura desconocida en %s" % b["id"])
		for m in b.get("implicits", []):
			_check(Stat.exists(StringName(m["stat"])), "implícito desconocido en %s" % b["id"])
	for a in _db.affixes:
		var stat: String = a["stat"]
		_check(Stat.exists(StringName(stat)) or ItemDatabase.is_local(stat), "stat desconocido en afijo %s" % a["id"])
		_check(a["kind"] == "prefix" or a["kind"] == "suffix", "tipo de afijo en %s" % a["id"])
		var any_base := false
		for b in _db.bases.values():
			any_base = any_base or ItemGenerator._allowed(a, b)
		_check(any_base, "el afijo %s no puede salir en ninguna base" % a["id"])
	var fixed: Array = []
	for u in _db.uniques:
		_check(_db.bases.has(u["base"]), "base del único %s" % u["id"])
		fixed.append_array(u["mods"])
	for entry in _db.set_pieces:
		_check(_db.bases.has(entry["piece"]["base"]), "base de la pieza %s" % entry["piece"]["id"])
		fixed.append_array(entry["piece"]["mods"])
	for m in fixed:
		_check(Stat.exists(StringName(m["stat"])) or ItemDatabase.is_local(m["stat"]), "stat desconocido '%s' en único/conjunto" % m["stat"])


func _test_item_generation() -> void:
	var gen := ItemGenerator.new(_db, 1234)
	for rarity in Rarity.ITEM_INFO:
		var info: Dictionary = Rarity.ITEM_INFO[rarity]
		for n in 200:
			var item := gen.generate(40, rarity)
			if rarity == Rarity.Item.UNIQUE or rarity == Rarity.Item.SET:
				_check(item.rarity == rarity and not item.unique_def.is_empty() and item.affixes.is_empty(), "único/conjunto bien formado")
				continue
			var prefixes := 0
			var groups := {}
			for a in item.affixes:
				prefixes += 1 if a["kind"] == "prefix" else 0
				_check(not groups.has(a["affix_id"]), "afijo repetido en %s" % item.display_name())
				groups[a["affix_id"]] = true
			_check(item.affixes.size() <= info["max_affixes"], "demasiados afijos (%s)" % Rarity.item_name(rarity))
			_check(prefixes <= info["max_prefixes"] and item.affixes.size() - prefixes <= info["max_suffixes"], "límite de prefijos/sufijos")
			if rarity == Rarity.Item.ULTRA_RARE:
				for a in item.affixes:
					_check(a["tier_rank"] == 1 or a["tier_level"] <= 40, "ultra-raro con el mejor tier disponible")
	# Reproducibilidad con semilla.
	var a := ItemGenerator.new(_db, 99).generate(30, Rarity.Item.RARE)
	var b := ItemGenerator.new(_db, 99).generate(30, Rarity.Item.RARE)
	_check(a.display_name() == b.display_name() and a.affixes == b.affixes, "misma semilla, mismo objeto")
	# Nivel de objeto bajo: solo bases y tiers de nivel 1.
	for n in 100:
		var low := gen.generate(1, Rarity.Item.RARE)
		_check(int(low.base["level"]) <= 1, "base de nivel demasiado alto para ilvl 1")
		for af in low.affixes:
			_check(af["tier_level"] <= 1, "tier de nivel demasiado alto para ilvl 1")


func _test_local_mods() -> void:
	var gen := ItemGenerator.new(_db, 7)
	var sword := gen.generate(1, Rarity.Item.NORMAL, "espada_oxidada")
	_check(sword.physical_min == 6.0 and sword.physical_max == 12.0, "daño base del arma")
	sword.affixes.append({"affix_id": "t", "kind": "prefix", "name": "", "tier_rank": 1, "tier_level": 1,
		"stat": "local_physical_increased", "type": "increased", "tags": [], "value": 100.0})
	sword.affixes.append({"affix_id": "t2", "kind": "prefix", "name": "", "tier_rank": 1, "tier_level": 1,
		"stat": "local_added_physical", "type": "flat", "tags": [], "value": 2.0, "value2": 4.0})
	sword.compute_properties()
	_check(sword.physical_min == 16.0 and sword.physical_max == 32.0, "(6+2)×2 a (12+4)×2: %s-%s" % [sword.physical_min, sword.physical_max])
	_check(sword.get_modifiers("x").is_empty(), "los mods locales no llegan al personaje")

	var helmet := gen.generate(1, Rarity.Item.NORMAL, "casco_de_hierro")
	helmet.affixes.append({"affix_id": "t", "kind": "prefix", "name": "", "tier_rank": 1, "tier_level": 1,
		"stat": "local_defence_increased", "type": "increased", "tags": [], "value": 50.0})
	helmet.compute_properties()
	_check(helmet.armour == 27.0, "18 de armadura × 1.5 = 27 (%s)" % helmet.armour)


func _test_inventory_and_equipment() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 5)
	var unarmed_dps: float = c.attack_profile()["dps"]
	var sword := gen.generate(1, Rarity.Item.NORMAL, "hacha_de_lenador")
	_check(c.inventory.add_item(sword), "añadir a la bolsa")
	var preview := c.preview_equip(sword)
	_check(preview["DPS del ataque"] > unarmed_dps, "la vista previa con hacha mejora el DPS")
	_check(is_equal_approx(c.attack_profile()["dps"], unarmed_dps), "preview_equip no cambia el estado real")
	_check(c.inventory.equip_from_bag(0) and c.inventory.equipped("weapon") == sword, "equipar desde la bolsa")
	_check(is_equal_approx(c.attack_profile()["dps"], preview["DPS del ataque"]), "el DPS real coincide con la vista previa")

	var ring_a := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_rubi")
	var ring_b := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_zafiro")
	c.inventory.add_item(ring_a)
	c.inventory.add_item(ring_b)
	c.inventory.equip_from_bag(c.inventory.bag.find(ring_a))
	c.inventory.equip_from_bag(c.inventory.bag.find(ring_b))
	_check(c.inventory.equipped("ring_left") == ring_a and c.inventory.equipped("ring_right") == ring_b, "dos anillos en dos ranuras")
	_check(c.stats.get_value(Stat.FIRE_RES) == 15.0 and c.stats.get_value(Stat.COLD_RES) == 15.0, "implícitos de los anillos aplicados")
	_check(c.inventory.unequip("ring_left") and c.stats.get_value(Stat.FIRE_RES) == 0.0, "quitar un anillo quita su resistencia")

	var high := gen.generate(40, Rarity.Item.NORMAL, "hacha_de_guerra")
	_check(not c.can_equip(high), "no se puede equipar por encima del nivel")
	for i in Inventory.BAG_SIZE:
		c.inventory.add_item(gen.generate(1, Rarity.Item.NORMAL))
	_check(not c.inventory.add_item(high), "bolsa llena")
	_check(not c.inventory.unequip("weapon"), "no se puede desequipar con la bolsa llena")


func _test_sets() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 11)
	var set_def: Dictionary = _db.sets["atuendo_del_senior"]
	var damage_before: float = c.stats.get_breakdown(Stat.DAMAGE)["increased"]
	for piece in set_def["pieces"]:
		var item := gen.make_set_piece(piece, set_def, 10)
		c.inventory.set_equipped(c.inventory.target_slot_for(item), item)
	_check(c.equipped_set_counts().get("atuendo_del_senior", 0) == 3, "3 piezas contadas")
	_check(c.stats.get_breakdown(Stat.DAMAGE)["increased"] == damage_before + 15.0, "bonus de 2 piezas activo")
	_check(c.stats.get_breakdown(Stat.ATTACK_SPEED)["increased"] >= 15.0, "bonus de 3 piezas activo")
	var saved := Item.from_dict(c.inventory.equipped("body").to_dict(), _db)
	_check(saved.display_name() == c.inventory.equipped("body").display_name() and saved.evasion == c.inventory.equipped("body").evasion, "to_dict/from_dict de una pieza de conjunto")


func _test_character_round_trip() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 21)
	c.id = "test_1"
	c.character_name = "Bobby Tables"
	c.set_level(22)
	c.add_experience(37)
	c.appearance = CharacterAppearance.random(gen.rng)
	c.set_ascendancy(StringName(_classes[0]["ascendancies"][1]["id"]))
	c.passives.allocate_path(_find_notable_near(c), 20)
	c.inventory.set_equipped("weapon", gen.generate(12, Rarity.Item.RARE, "espada_oxidada"))
	c.inventory.set_equipped("body", gen.generate(12, Rarity.Item.UNIQUE))
	c.inventory.add_item(gen.generate(12, Rarity.Item.ULTRA_RARE))
	c.inventory.bag[7] = gen.generate(12, Rarity.Item.SET)
	c.play_time = 3725.5

	# Pasa por texto JSON, como en disco (los números vuelven como float).
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(loaded.id == "test_1" and loaded.character_name == "Bobby Tables", "id y nombre")
	_check(loaded.level == 22 and loaded.experience == c.experience, "nivel y experiencia")
	_check(loaded.ascendancy_def.get("id") == c.ascendancy_def.get("id"), "ascendencia")
	_check(loaded.appearance == c.appearance, "apariencia")
	_check(loaded.passives.get_allocated_ids().size() == c.passives.get_allocated_ids().size() and loaded.passives.spent_points() > 0, "pasivas")
	_check(loaded.inventory.bag[7] != null and loaded.inventory.bag[7].display_name() == c.inventory.bag[7].display_name(), "bolsa, hueco 7")
	for key in c.summary():
		_check(is_equal_approx(loaded.summary()[key], c.summary()[key]), "stat '%s' tras cargar: %s vs %s" % [key, loaded.summary()[key], c.summary()[key]])
	_check(is_equal_approx(loaded.play_time, 3725.5), "tiempo jugado")


func _find_notable_near(c: CharacterData) -> int:
	var best := -1
	for id in _tree.nodes:
		if _tree.nodes[id].kind == PassiveNode.Kind.NOTABLE:
			var cost := c.passives.find_path(id).size()
			if cost > 0 and (best == -1 or cost < c.passives.find_path(best).size()):
				best = id
	return best


func _test_passive_load_validation() -> void:
	var start := _tree.get_start_node_for_class(&"guerrero")
	var alloc := PassiveAllocation.new(_tree, start)
	var neighbor: int = _tree.neighbors(start)[0]
	var far_start := _tree.get_start_node_for_class(&"hechicero")
	var isolated := -1
	for id in _tree.nodes:
		if not alloc.find_path(id).is_empty() and alloc.find_path(id).size() > 5:
			isolated = id
			break
	# Válido + inexistente + inicio ajeno + desconectado.
	var dropped := alloc.load_ids([float(neighbor), 99999.0, float(far_start), float(isolated)])
	_check(alloc.is_allocated(neighbor), "conserva el nodo conectado")
	_check(not alloc.is_allocated(99999) and not alloc.is_allocated(far_start) and not alloc.is_allocated(isolated), "descarta los inválidos")
	_check(dropped == 3 and alloc.spent_points() == 1, "devuelve los puntos descartados (%d)" % dropped)


func _test_save_files() -> void:
	var dir := "user://test_saves"
	for f in DirAccess.get_files_at(dir) if DirAccess.dir_exists_absolute(dir) else PackedStringArray():
		DirAccess.remove_absolute(dir + "/" + f)
	var older := {"id": "a", "class_id": "guerrero", "name": "Viejo", "last_played": 100}
	var newer := {"id": "b", "class_id": "duelista", "name": "Nuevo", "last_played": 200}
	_check(CharacterSaves.write(older, dir) == OK and CharacterSaves.write(newer, dir) == OK, "escribir guardados")
	var listed := CharacterSaves.list_all(dir)
	_check(listed.size() == 2 and listed[0]["id"] == "b", "lista ordenada por última partida")
	_check(not FileAccess.file_exists(CharacterSaves.path_for("a", dir) + ".tmp"), "no quedan temporales")

	# Segundo guardado: el anterior pasa a .bak; si el principal se corrompe, se usa el .bak.
	older["name"] = "Viejo 2"
	CharacterSaves.write(older, dir)
	_check(FileAccess.file_exists(CharacterSaves.path_for("a", dir) + ".bak"), "copia .bak creada")
	var f := FileAccess.open(CharacterSaves.path_for("a", dir), FileAccess.WRITE)
	f.store_string("{ esto no es json")
	f.close()
	_check(CharacterSaves.read("a", dir).get("name") == "Viejo", "recupera la copia .bak si el principal está dañado")

	# Rotación de tres copias: la más vieja se descarta; si fallan principal y .bak, se usa .bak2.
	for n in ["Viejo 3", "Viejo 4", "Viejo 5"]:
		older["name"] = n
		CharacterSaves.write(older, dir)
	var base := CharacterSaves.path_for("a", dir)
	_check(FileAccess.file_exists(base + ".bak3") and not FileAccess.file_exists(base + ".bak4"), "tres copias rotativas")
	_check(CharacterSaves.read("a", dir).get("name") == "Viejo 5", "lee la versión más reciente")
	for p in [base, base + ".bak"]:
		var bad := FileAccess.open(p, FileAccess.WRITE)
		bad.store_string("{ roto")
		bad.close()
	_check(CharacterSaves.read("a", dir).get("name") == "Viejo 3", "con principal y .bak dañados, carga .bak2")
	# Cierre a mitad de guardado (sin principal): el personaje sigue en la lista desde su copia.
	DirAccess.remove_absolute(base)
	_check(CharacterSaves.list_all(dir).any(func(d: Dictionary) -> bool: return d["id"] == "a"), "sin principal, aparece desde las copias")

	# Espacios de guardado: el 1 usa las rutas de siempre; los demás, su carpeta con su alijo.
	_check(CharacterSaves.slot_root(1) == "user://" and CharacterSaves.slot_root(2) == "user://espacio_2/", "carpetas de los espacios")

	# Alijo: copia .bak al guardar y recuperación si el principal está dañado.
	var stash_path := dir + "/alijo.json"
	var st := Stash.new(stash_path)
	st.save()
	st.save()
	_check(FileAccess.file_exists(stash_path + ".bak"), "el alijo guarda copia .bak")
	var bad_stash := FileAccess.open(stash_path, FileAccess.WRITE)
	bad_stash.store_string("{ roto")
	bad_stash.close()
	_check(Stash.load_from(stash_path, _db) != null and FileAccess.file_exists(stash_path + ".danado"), "alijo dañado: se aparta y se carga la copia")
	for p in [stash_path, stash_path + ".bak", stash_path + ".danado"]:
		DirAccess.remove_absolute(p)

	var junk := FileAccess.open(dir + "/basura.json", FileAccess.WRITE)
	junk.store_string("[]")
	junk.close()
	_check(CharacterSaves.list_all(dir).size() == 2, "ignora archivos que no son personajes")

	CharacterSaves.delete("a", dir)
	CharacterSaves.delete("b", dir)
	DirAccess.remove_absolute(dir + "/basura.json")
	_check(CharacterSaves.list_all(dir).is_empty(), "borrar elimina principal y copias")
	DirAccess.remove_absolute(dir)


func _test_name_validation() -> void:
	var existing := ["Segfault"]
	_check(CharacterSaves.validate_name("Ñandú_del-Kernel 2", existing) == "", "acepta letras con tilde, ñ, números, _ y -")
	_check(CharacterSaves.validate_name(" a ", existing) != "", "demasiado corto")
	_check(CharacterSaves.validate_name("x".repeat(21), existing) != "", "demasiado largo")
	_check(CharacterSaves.validate_name("Drop; Table", existing) != "", "caracteres no permitidos")
	_check(CharacterSaves.validate_name("SEGFAULT", existing) != "", "nombre repetido sin distinguir mayúsculas")


func _test_appearance() -> void:
	var fixed := CharacterAppearance.sanitize({"body": 99, "hair": -3, "skin_tone": "no-es-color", "hair_color": "ff0000"})
	_check(fixed["body"] == CharacterAppearance.BODY_NAMES.size() - 1 and fixed["hair"] == 0, "índices fuera de rango corregidos")
	_check(fixed["skin_tone"] == CharacterAppearance.default()["skin_tone"] and fixed["hair_color"] == "ff0000", "colores validados")
	_check(fixed.has("outfit_color"), "rellena claves que faltan")

func _test_skill_data() -> void:
	var skills := _db.skills
	_check(skills.skills.size() >= 6 and skills.rams.size() >= 8, "carga de habilidades y RAM")
	var kinds := ["melee_area", "nova", "projectile", "ground_aoe", "blink", "dash", "cone", "beam", "boomerang", "spin", "trap", "chain", "minion", "degen_area", "barrier", "buff", "curse_area", "dot_projectile", "homing", "drones", "leap_slam", "rain", "unit", "aura", "ssh", "charge", "backflip", "terrain", "channel_beam", "channel_storm"]
	for def in skills.skills.values():
		_check(kinds.has(def["kind"]), "tipo de habilidad desconocido en %s" % def["id"])
		_check(def.has("attack") or def.has("spell"), "%s necesita 'attack' o 'spell'" % def["id"])
		_check(RamModule.GENERATION_BY_ATTRIBUTE.has(def.get("attribute", "")), "atributo de %s" % def["id"])
	for def in skills.rams.values():
		_check(RamModule.GENERATIONS.has(def["generation"]), "generación de %s" % def["id"])
		for md in def.get("mods", []):
			_check(Stat.exists(StringName(md["stat"])), "stat desconocido en RAM %s" % def["id"])
	for c in _classes:
		for s in c.get("starter_skills", []):
			_check(skills.skills.has(s), "habilidad inicial desconocida '%s' en %s" % [s, c["id"]])


func _test_motherboards_and_ram() -> void:
	var gen := ItemGenerator.new(_db, 3)
	for n in 300:
		var board := gen.generate_motherboard(30)
		_check(board.slots.size() >= Motherboard.MIN_SLOTS and board.slots.size() <= Motherboard.MAX_SLOTS, "3 a 7 ranuras")
		_check(board.level == 27, "nivel de la placa según el nivel de objeto (%d)" % board.level)
	var proj := gen.generate_motherboard(1, "ping_letal")
	proj.slots.assign(["DDR4", "DDR5", "DDR3"])
	proj.rams.resize(3)
	var multi := gen.generate_ram(1, "multicanal")      # DDR4, requiere projectile
	var cache := gen.generate_ram(1, "cache_l3")        # DDR5, requiere area
	_check(proj.can_install(multi, 1) != "", "DDR4 no entra en ranura DDR5")
	_check(proj.install(multi, 0) == "" and proj.rams[0] == multi, "DDR4 en ranura DDR4")
	_check(proj.install(gen.generate_ram(1, "overclock"), 0) != "", "ranura ocupada")
	_check(proj.install(cache, 1) == "", "caché en ranura DDR5")
	_check(proj.active_supports().size() == 1, "la caché L3 no afecta a un proyectil sin área")
	var blink := gen.generate_motherboard(1, "teleport_tcp")
	_check(not gen.generate_ram(1, "pipeline").supports(blink.skill_def), "pipeline excluye movimiento")

	var c := _new_character()
	c.inventory.boards.fill(null)
	c.inventory.add_item(proj)
	_check(c.inventory.install_board(c.inventory.bag.find(proj)) and c.inventory.boards[0] == proj, "instalar placa desde la bolsa")
	c.inventory.add_item(gen.generate_ram(1, "puntero_salvaje"))  # DDR4: no hay ranura DDR4 libre
	var ram_index := c.inventory.bag.find(c.inventory.bag.filter(func(i) -> bool: return i is RamModule)[0])
	_check(c.inventory.install_ram(ram_index, 0) != "", "sin ranuras libres de esa generación")
	_check(c.inventory.remove_ram(0, 0) and proj.rams[0] == null, "quitar RAM a la bolsa")
	_check(c.inventory.install_ram(ram_index, 0) == "", "ahora sí cabe")
	_check(not c.inventory.equip_from_bag(c.inventory.bag.find(multi)), "la RAM no se 'equipa' como un casco")


func _test_skill_calc() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 4)
	var ping := gen.generate_motherboard(1, "ping_letal")
	ping.slots.assign(["DDR4", "DDR4"])
	ping.rams.resize(2)
	var base := SkillCalc.compute(ping, c)
	_check(base["projectiles"] == 1 and base["pierce"] == 2, "ping: 1 proyectil que atraviesa 2")
	ping.install(gen.generate_ram(1, "multicanal"), 0)
	var multi := SkillCalc.compute(ping, c)
	_check(multi["projectiles"] == 3, "multicanal: +2 proyectiles")
	_check(is_equal_approx(multi["max_damage"], base["max_damage"] * 0.55), "multicanal: 45% menos de daño en una placa de nivel 1")
	_check(is_equal_approx(multi["spread_degrees"], 24.0), "multicanal: los 3 proyectiles salen en abanico (\\|/)")
	_check(not multi["homing"], "ping: sin la etiqueta teledirigido, los proyectiles van rectos")
	_check(multi["mana_cost"] == roundf(base["mana_cost"] * 1.3), "multicanal: coste ×1.3")
	ping.install(gen.generate_ram(1, "overclock"), 1)
	var fast := SkillCalc.compute(ping, c)
	_check(is_equal_approx(fast["uses_per_second"], multi["uses_per_second"] * 1.2), "overclock: 20% más velocidad")

	var swing := gen.generate_motherboard(1, "barrido")
	swing.slots.assign(["DDR3"])
	swing.rams.resize(1)
	var unarmed := SkillCalc.compute(swing, c)
	c.inventory.set_equipped("weapon", gen.generate(1, Rarity.Item.NORMAL, "hacha_de_lenador"))
	var armed := SkillCalc.compute(swing, c)
	_check(armed["max_damage"] > unarmed["max_damage"], "los ataques usan el arma equipada")
	swing.install(gen.generate_ram(1, "disipador"), 0)
	var focused := SkillCalc.compute(swing, c)
	_check(focused["radius"] < armed["radius"] and focused["max_damage"] > armed["max_damage"], "disipador: menos área, más daño")
	var lvl1 := SkillCalc.compute(gen.generate_motherboard(1, "fork_bomb"), c)
	var lvl10 := SkillCalc.compute(gen.generate_motherboard(28, "fork_bomb"), c)
	_check(lvl10["max_damage"] > lvl1["max_damage"] * 2.0, "los hechizos escalan con el nivel de la placa")


func _test_boards_save() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 8)
	var board := gen.generate_motherboard(20, "fork_bomb", 6)
	var ram := gen.generate_ram(20, "cache_l3")
	board.slots[2] = ram.generation()
	board.install(ram, 2)
	c.inventory.set_board(4, board)
	c.inventory.add_item(gen.generate_ram(5, "ecc"))
	c.inventory.add_item(gen.generate_motherboard(5, "ping_letal", 3))
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	var lb: Motherboard = loaded.inventory.boards[4]
	_check(lb != null and lb.skill_def["id"] == "fork_bomb" and lb.slots == board.slots, "placa guardada con sus ranuras")
	_check(lb.rams[2] != null and lb.rams[2].def["id"] == "cache_l3", "RAM instalada guardada")
	_check(loaded.inventory.bag.any(func(i) -> bool: return i is RamModule) and loaded.inventory.bag.any(func(i) -> bool: return i is Motherboard), "placas y RAM en la bolsa guardadas")
	_check(is_equal_approx(SkillCalc.compute(lb, loaded)["dps"], SkillCalc.compute(board, c)["dps"]), "mismo DPS tras cargar")


func _test_enemy_hit_one() -> void:
	var em := EnemyManager.new()
	em.spawn(Vector2(0, 0), Rarity.Enemy.UNIQUE)
	em.spawn(Vector2(5, 0), Rarity.Enemy.UNIQUE)
	var first := em.hit_one(Vector2.ZERO, 10.0, {}, 1.0, 1.0, 0.0, 150.0)
	var second := em.hit_one(Vector2.ZERO, 10.0, {first: true}, 1.0, 1.0, 0.0, 150.0)
	_check(first != -1 and second != -1 and first != second, "hit_one ignora a los ya golpeados (atravesar)")
	_check(em.hit_one(Vector2.ZERO, 10.0, {first: true, second: true}, 1.0, 1.0, 0.0, 150.0) == -1, "sin más objetivos")
	_check(em.last_damage_dealt == 0.0, "daño registrado para el robo de vida")
	em.safe_radius = 100.0
	_check(em.is_in_safe_zone(Vector2(50, 0)) and not em.is_in_safe_zone(Vector2(150, 0)), "zona segura")
	_check(EnemyManager.enemy_types().size() >= 5, "tipos de enemigo cargados")
	var atlas := load("res://assets/sprites/enemies/enemies.png") as Texture2D
	_check(atlas.get_height() / EnemySheet.S >= EnemyManager.enemy_types().size() * EnemySheet.DIRS and atlas.get_width() == EnemySheet.S * EnemySheet.COLUMNS,
		"tres filas del atlas por tipo (abajo, arriba, de lado) y 18 cuadros")
	em.free()


func _test_camp_and_tutorial_data() -> void:
	var npc_data: Dictionary = DataLoader.load_json("res://data/npcs.json")
	var dialogues: Dictionary = npc_data["dialogues"]
	for npc_id in npc_data["npcs"]:
		_check(dialogues.has(npc_data["npcs"][npc_id]["dialogue"]), "diálogo de %s" % npc_id)
	_test_act(npc_data)
	for id in dialogues:
		var d: Dictionary = dialogues[id]
		_check(d["nodes"].has(d["start"]), "nodo inicial de %s" % id)
		_check(d.has("menu"), "%s: falta 'menu' (frase corta al volver al inicio, para no repetir el saludo)" % id)
		for node_id in d["nodes"]:
			var node_next: String = d["nodes"][node_id].get("next", "")
			_check(node_next == "" or d["nodes"].has(node_next), "%s/%s encadena con '%s', que no existe" % [id, node_id, node_next])
			_check(d["nodes"][node_id].has("options") or d["nodes"][node_id].has("next"), "%s/%s no tiene salida" % [id, node_id])
			for option in d["nodes"][node_id].get("options", []):
				var next: String = option.get("next", "")
				_check(next == "" or d["nodes"].has(next), "%s/%s apunta a '%s', que no existe" % [id, node_id, next])
				var action: Dictionary = option.get("action", {})
				if action.get("type", "") == "give_item":
					var pool: Dictionary = _db.skills.skills if action["kind"] == "motherboard" else _db.skills.rams
					_check(pool.has(action["id"]), "regalo desconocido '%s'" % action["id"])
	var tutorial: Dictionary = DataLoader.load_json("res://data/tutorial.json")
	var known := ["move", "talk_ada", "install_ram", "kevin", "reach_camp", "leave_camp", "use_skill", "kill", "flask", "loot", "equip", "passives"]
	for step in tutorial["steps"]:
		_check(known.has(step["id"]), "paso de tutorial sin condición: %s" % step["id"])


func _test_act(npc_data: Dictionary) -> void:
	var all_zones: Array = []
	var zones := {}
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var a: Dictionary = DataLoader.load_json(path)
		for z in a["zones"]:
			zones[z["id"]] = z
			all_zones.append(z)
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var a: Dictionary = DataLoader.load_json(path)
		_check(zones.has(a["start_zone"]) and zones.has(a["town"]), "%s: zona inicial y pueblo existen" % a["id"])
		_check(zones[a["town"]].has("waypoint"), "%s: el pueblo tiene waypoint (reaparición)" % a["id"])
		_check(zones[a["town"]].get("safe", false), "%s: el pueblo es zona segura" % a["id"])
	var act := {"zones": all_zones}
	var type_ids := []
	for t in EnemyManager.enemy_types():
		type_ids.append(t["id"])
	var bosses := 0
	for z in act["zones"]:
		for e in z.get("exits", []):
			if e["target"] == "":
				_check(e.has("message"), "%s: salida sin destino ni mensaje" % z["id"])
				continue
			_check(zones.has(e["target"]), "%s: salida a zona inexistente %s" % [z["id"], e["target"]])
			if zones.has(e["target"]):
				_check(zones[e["target"]]["entries"].has(e["entry"]), "%s: la entrada %s no existe en %s" % [z["id"], e["entry"], e["target"]])
		if z.has("waypoint"):
			_check(z["entries"].has("waypoint"), "%s tiene waypoint pero no entrada 'waypoint'" % z["id"])
		for n in z.get("npcs", []):
			_check(npc_data["npcs"].has(n["id"]), "%s: NPC desconocido %s" % [z["id"], n["id"]])
		var cfg = z.get("enemies")
		if cfg is Dictionary:
			for t in cfg.get("types", []):
				_check(type_ids.has(t), "%s: tipo de enemigo desconocido %s" % [z["id"], t])
		if z.has("boss"):
			bosses += 1
			_check(type_ids.has(z["boss"]["type"]), "tipo del jefe")

		# Construye la zona y comprueba que el diseño es jugable.
		var zone := Zone.new()
		zone.setup(z, null, null)
		for k in zone.key_points():
			for o in zone.obstacles:
				_check(k.distance_to(o["pos"]) > o["radius"] + 60.0, "%s: obstáculo encima de un punto de interés" % z["id"])
			_check(zone.rect.grow(-10.0).has_point(k), "%s: punto de interés fuera del mapa" % z["id"])
		if cfg is Dictionary:
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			var packs := zone.pack_centers(int(cfg["packs"]), rng, float(cfg.get("keep_away", 0.0)))
			_check(packs.size() >= int(cfg["packs"]) * 0.8, "%s: solo caben %d de %d grupos" % [z["id"], packs.size(), cfg["packs"]])
			for p in packs:
				for k in zone.key_points():
					_check(p.distance_to(k) >= 450.0, "%s: grupo demasiado cerca de una entrada/NPC" % z["id"])
		zone.free()
	_check(bosses == 4, "un jefe por acto (el Arquitecto, init, fw_update.exe y admin)")
	_test_quest_data(zones, npc_data)
	_test_cutscenes(zones, npc_data)
	_check(act["zones"].size() >= 10, "acto I completo + inicio del acto II")


func _test_cutscenes(zones: Dictionary, npc_data: Dictionary) -> void:
	var cutscenes: Dictionary = DataLoader.load_json("res://data/cutscenes.json")["cutscenes"]
	var referenced := []
	for z in zones.values():
		if z.has("boss") and z["boss"].has("death_cutscene"):
			referenced.append(z["boss"]["death_cutscene"])
		var enters: Array = z["cutscene_on_enter"] if z.get("cutscene_on_enter") is Array else ([z["cutscene_on_enter"]] if z.get("cutscene_on_enter") is Dictionary else [])
		for enter in enters:
			referenced.append(enter["id"])
		for e in z.get("exits", []):
			if e.has("cutscene"):
				referenced.append(e["cutscene"])
	for id in cutscenes:   # las que siguen a otra (epílogos, T130)
		if cutscenes[id].get("on_finish", {}).has("cutscene"):
			referenced.append(cutscenes[id]["on_finish"]["cutscene"])
	for id in referenced:
		_check(cutscenes.has(id), "escena inexistente: %s" % id)
	for id in cutscenes:
		for step in cutscenes[id]["steps"]:
			if step.has("speaker"):
				_check(step["speaker"] == "player" or npc_data["npcs"].has(step["speaker"]), "%s: hablante desconocido %s" % [id, step["speaker"]])
			if step.has("effect"):
				var prologue_fx: bool = id.begins_with("prologo_") and step["effect"] in ["lights_flicker", "fans", "rafa_stands", "shock"]
				_check(prologue_fx or step["effect"] in ["glitch", "shake", "blackout", "fade_in", "dino", "camera", "walk", "turn", "bars"], "%s: efecto desconocido" % id)
			else:
				_check(step.has("text") and (step.has("speaker") or step.has("name")), "%s: línea sin texto o sin hablante" % id)
		var travel: Dictionary = cutscenes[id].get("on_finish", {}).get("travel", {})
		if not travel.is_empty():
			_check(zones.has(travel["zone"]) and zones[travel["zone"]]["entries"].has(travel["entry"]), "%s: viaje a una entrada inexistente" % id)
	# La transición del acto I al II.
	_check(referenced.has("arquitecto_muere") and referenced.has("reunion_campamento") and referenced.has("red_lince"), "transición al acto II")
	var red_lince: Dictionary = cutscenes["red_lince"]
	_check(red_lince["steps"].any(func(s: Dictionary) -> bool: return s.get("effect", "") == "dino"), "La Red Lince muestra al dinosaurio")
	var reunion_text := ""
	for s in cutscenes["reunion_campamento"]["steps"]:
		reunion_text += s.get("text", "")
	_check(reunion_text.contains("Inge Pepe") and reunion_text.contains("culpa suya"), "culpan al Inge Pepe")


func _test_quest_data(zones: Dictionary, npc_data: Dictionary) -> void:
	var quests := QuestLog.database()
	_check(quests.has("main_act1"), "misión principal del acto I")
	var quest_items := []
	for z in zones.values():
		for q in z.get("quest_items", []):
			quest_items.append(q["id"])
			_check(quests.has(q["quest"]), "objeto de misión de una misión inexistente: %s" % q["id"])
	# Acciones de diálogo que nombran misiones.
	var advanced := {}
	for d in npc_data["dialogues"].values():
		for node in d["nodes"].values():
			for option in node.get("options", []):
				var action: Dictionary = option.get("action", {})
				if action.get("type", "") in ["start_quest", "quest_advance"]:
					_check(quests.has(action.get("quest", "")), "diálogo con misión inexistente %s" % action.get("quest", ""))
				if action.get("type", "") == "quest_advance":
					advanced[action["quest"]] = true
	for id in quests:
		var q: Dictionary = quests[id]
		if q.has("giver"):
			_check(npc_data["npcs"].has(q["giver"]), "%s: quien la da no existe" % id)
		if q.has("starts_after"):
			_check(quests.has(q["starts_after"]), "%s: starts_after inexistente" % id)
		for step in q["steps"]:
			match step["type"]:
				"talk", "turn_in":
					_check(npc_data["npcs"].has(step["npc"]), "%s: NPC desconocido %s" % [id, step["npc"]])
					if step["type"] == "turn_in":
						_check(advanced.has(id), "%s: nadie acepta la entrega (falta quest_advance)" % id)
				"reach_zone":
					_check(zones.has(step["zone"]), "%s: zona desconocida %s" % [id, step["zone"]])
				"kill":
					_check(step.get("zone", "") == "" or zones.has(step["zone"]), "%s: zona desconocida" % id)
					_check(QuestLog.RARITY_BY_NAME.has(step.get("min_rarity", "normal")), "%s: rareza desconocida" % id)
				"collect":
					for item_id in step.get("items", [step.get("item", "")]):
						_check(quest_items.has(item_id), "%s: objeto %s no está en ninguna zona" % [id, item_id])
				"flag":
					pass
				_:
					_check(false, "%s: tipo de paso desconocido %s" % [id, step["type"]])


func _test_quests() -> void:
	var c := _new_character()
	var log := QuestLog.new(c)
	var started: Array[String] = []
	var completed: Array[String] = []
	log.quest_started.connect(func(id: String) -> void: started.append(id))
	log.quest_completed.connect(func(id: String) -> void: completed.append(id))
	log.start_auto()
	_check(log.is_active("main_act1") and started.has("main_act1"), "la principal empieza sola")
	_check(log.active_ids()[0] == "main_act1", "la principal va primero")
	# Partidas cortas (T154): objetivo a la vista al entrar.
	_check(log.short_goal().begins_with(String(log.defs["main_act1"]["name"]) + ": ") and log.short_goal() != "",
		"objetivo corto: la principal con su paso")
	_check(QuestLog.entry_goal(log.short_goal(), true, 0).begins_with("Objetivo · "), "con misión: «Objetivo · …»")
	_check(QuestLog.entry_goal("", false, 12) == "Objetivo · limpia esta zona (0/12)", "sin misiones: limpiar la zona")
	_check(QuestLog.entry_goal("", true, 0) == "", "zona segura sin misiones: nada")
	var zones := {"campamento": {"name": "Campamento"}}
	_check(CharacterSaves.continue_label({"name": "Ada", "level": 12, "flags": {"zone": "campamento"}}, zones) \
		== "▶ Continuar · Ada · Nv 12 · Campamento", "«Continuar» con nombre, nivel y zona")
	_check(CharacterSaves.continue_label({"name": "Ada", "level": 3, "flags": {"zone": "no_existe"}}, zones) == "▶ Continuar · Ada · Nv 3",
		"«Continuar» sin una zona conocida: sin zona")
	c.flags["talked_bot_onboarding"] = true
	log.refresh()
	_check(int(log.state("main_act1")["step"]) == 1, "hablar con B.O.B. avanza")
	log.notify_zone("campamento")
	_check(int(log.state("main_act1")["step"]) == 2, "llegar al campamento avanza")
	# Saltar hasta un paso de bandera ya cumplido (personaje que ya mató al jefe).
	c.flags["act1_complete"] = true
	log.refresh()
	_check(log.step_text("main_act1").contains("Vuelve al campamento"), "salta a 'vuelve al campamento' si ya mató al jefe")
	c.flags["act1_reunion"] = true
	log.refresh()
	_check(log.step_text("main_act1").contains("Portal al Kernel"), "tras la reunión: cruzar el portal")
	log.notify_zone("brecha_503")
	_check(log.is_done("main_act1") and completed.has("main_act1"), "principal completada")
	_check(log.is_active("main_act2"), "la del acto II empieza al terminar la del I")

	# Secundaria: eliminar en una zona concreta y entregar.
	_check(log.npc_offers_quest("iris"), "Iris ofrece misión")
	log.start("iris_cables")
	_check(c.flags.has("quest_iris_cables_started") and not log.npc_offers_quest("iris"), "aceptada")
	for k in 10:
		log.notify_kill("zona3", Rarity.Enemy.NORMAL)   # zona equivocada: no cuenta
	_check(int(log.state("iris_cables")["count"]) == 0, "solo cuentan las muertes en su zona")
	for k in 25:
		log.notify_kill("zona1", Rarity.Enemy.NORMAL)
	_check(c.flags.has("quest_iris_cables_ready") and log.npc_has_turn_in("iris"), "lista para entregar")
	_check(not log.advance("tomas_reporte"), "no se entrega una misión no aceptada")
	_check(log.advance("iris_cables") and log.is_done("iris_cables"), "entregada")
	_check(not c.flags.has("quest_iris_cables_ready") and c.flags.has("quest_iris_cables_done"), "banderas al terminar")

	# Rareza mínima.
	log.start("tomas_reporte")
	log.notify_kill("zona3", Rarity.Enemy.NORMAL)
	log.notify_kill("zona3", Rarity.Enemy.ELITE)
	_check(int(log.state("tomas_reporte")["count"]) == 1, "solo cuentan los especiales o mejores")
	_check(log.step_text("tomas_reporte").ends_with("(1/3)"), "progreso en el texto")

	# Recoger un objeto.
	log.start("dba_backup")
	c.flags["item_cinta_backup"] = true
	log.refresh()
	_check(log.npc_has_turn_in("dba"), "objeto recogido: a entregar")

	# Se guarda con el personaje.
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	var log2 := QuestLog.new(loaded)
	_check(log2.is_done("iris_cables") and log2.is_active("tomas_reporte") and int(log2.state("tomas_reporte")["count"]) == 1, "misiones guardadas")


func _test_loot_placement() -> void:
	var def := {"id": "prueba", "size": [1000, 800], "style": "ruins", "entries": {"a": [200, 400]},
		"exits": [], "obstacles": {"count": 0, "kinds": []}}
	var zone := Zone.new()
	zone.setup(def, null, null)
	var loot := LootManager.new()
	loot.placement_check = func(p: Vector2) -> bool: return zone.is_walkable(p, 18.0)
	loot.spot_fixer = func(p: Vector2) -> Vector2: return zone.free_spot_near(p, 24.0)
	var gen := ItemGenerator.new(_db, 3)
	# Muchos objetos junto al borde de abajo (como el botín del jefe).
	for k in 12:
		loot.drop_item(gen.generate(10, Rarity.Item.RARE), Vector2(500, 790))
	var all_ok := true
	for d in loot.drops:
		if not zone.is_walkable(d["rect"].get_center(), 10.0):
			all_ok = false
	_check(all_ok, "el botín cae siempre en suelo alcanzable")
	var overlaps := false
	for i in loot.drops.size():
		for j in range(i + 1, loot.drops.size()):
			if loot.drops[i]["rect"].intersects(loot.drops[j]["rect"]):
				overlaps = true
	_check(not overlaps, "las etiquetas del botín no se tapan")
	loot.free()
	zone.free()


func _test_tree_layout() -> void:
	var starts := {}
	for id in _tree.nodes:
		if _tree.nodes[id].kind == PassiveNode.Kind.CLASS_START:
			starts[id] = _tree.nodes[id]
	_check(starts.size() == 7, "7 inicios de clase")
	var center := _tree.get_start_node_for_class(&"full_stack")
	_check(_tree.nodes[center].position.length() < 1.0, "el Full Stack empieza en el centro")
	for sid in starts:
		var s: PassiveNode = starts[sid]
		# El inicio solo se conecta hacia delante (hacia fuera del centro).
		if sid != center:
			for nb in _tree.neighbors(sid):
				var out: Vector2 = _tree.nodes[nb].position - s.position
				_check(out.dot(s.position) > 0.0, "%s: conexión por detrás del inicio" % s.title)
		# Ninguna arista ajena pasa junto al inicio.
		for a in _tree.nodes:
			for b in _tree.neighbors(a):
				if a < b and a != sid and b != sid:
					var p := Geometry2D.get_closest_point_to_segment(s.position, _tree.nodes[a].position, _tree.nodes[b].position)
					_check(p.distance_to(s.position) > 50.0, "%s: arista %d-%d pasa por detrás" % [s.title, a, b])
	# Desde las clases nuevas se llega a todo.
	for class_id in [&"hacker", &"full_stack"]:
		var alloc := PassiveAllocation.new(_tree, _tree.get_start_node_for_class(class_id))
		var unreachable := 0
		for id in _tree.nodes:
			if not starts.has(id) and alloc.find_path(id).is_empty():
				unreachable += 1
		_check(unreachable == 0, "%s: %d nodos inalcanzables" % [class_id, unreachable])
	_check(_tree.nodes.size() >= 700, "más pasivas (%d)" % _tree.nodes.size())


func _test_new_skills() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 5)
	var spin := SkillCalc.compute(gen.generate_motherboard(1, "bucle_infinito"), c)
	_check(spin["duration"] > 0.0 and spin["tick"] > 0.0, "el giro tiene duración y ticks")
	_check(spin["dps"] > (spin["min_damage"] + spin["max_damage"]) / 2.0, "el giro cuenta varios golpes")
	var deadlock_board := gen.generate_motherboard(1, "deadlock")
	var before := SkillCalc.compute(deadlock_board, c)
	_check(before["stun"] > 1.0 and before["cooldown"] > 0.0, "Deadlock aturde y tiene enfriamiento")
	c.stats.add_modifier(Modifier.new(Stat.SKILL_DURATION, Modifier.Type.INCREASED, 50.0))
	c.stats.add_modifier(Modifier.new(Stat.COOLDOWN_RECOVERY, Modifier.Type.INCREASED, 100.0))
	var after := SkillCalc.compute(deadlock_board, c)
	_check(is_equal_approx(after["stun"], before["stun"] * 1.5), "la duración alarga el aturdimiento")
	_check(is_equal_approx(after["cooldown"], before["cooldown"] / 2.0), "la recuperación acorta el enfriamiento")
	for id in ["deploy_continuo", "flamewar", "rayo_produccion", "rollback", "bomba_logica", "excepcion_en_cadena"]:
		var p := SkillCalc.compute(gen.generate_motherboard(1, id), c)
		_check(p["max_damage"] > 0.0, "%s hace daño" % id)
	_check(SkillCalc.compute(gen.generate_motherboard(1, "rayo_produccion"), c)["width"] > 0.0, "el rayo tiene ancho")
	for cdef in _classes:
		for s in cdef["starter_skills"]:
			_check(_db.skills.skills.has(s), "%s: habilidad inicial %s" % [cdef["id"], s])
		_check(_db.bases.has(cdef["starter_weapon"]), "%s: arma inicial" % cdef["id"])


func _test_enemy_attacks() -> void:
	var em := EnemyManager.new()
	var kinds := ["melee", "ranged", "charge", "slam", "cone", "blink", "none", "summon", "seeker", "lob_pool"]
	var rows := {}
	for t in EnemyManager.enemy_types():
		_check(kinds.has(t.get("attack", {}).get("kind", "melee")), "ataque desconocido en %s" % t["id"])
		_check(not rows.has(t["sprite_row"]), "fila de sprite repetida en %s" % t["id"])
		rows[t["sprite_row"]] = true
	_check(EnemyManager.enemy_types().size() >= 9, "nueve tipos de enemigo")
	# Formas de golpe del jugador.
	em.spawn(Vector2(100, 0), Rarity.Enemy.NORMAL)     # delante
	em.spawn(Vector2(-100, 0), Rarity.Enemy.NORMAL)    # detrás
	em.spawn(Vector2(0, 300), Rarity.Enemy.NORMAL)     # lejos
	_check(em.hit_in_cone(Vector2.ZERO, Vector2.RIGHT, 150.0, 0.5, 1.0, 1.0, 0.0, 150.0) == 1, "el cono solo golpea delante")
	_check(em.hit_in_segment(Vector2(-200, 0), Vector2(200, 0), 20.0, 1.0, 1.0, 0.0, 150.0).size() == 2, "el segmento golpea a los de la línea")
	em.stun_in_radius(Vector2.ZERO, 150.0, 2.0)
	_check(em.stuns[0] > 0.0 and em.stuns[1] > 0.0 and em.stuns[2] == 0.0, "aturdimiento en área")
	var far := em.nearest_index(Vector2(0, 280), 100.0)
	_check(far == 2, "el más cercano para las cadenas")
	em.spawn(Vector2(500, 500), Rarity.Enemy.UNIQUE, -1, "Jefe", 1.0, [{"kind": "projectile_nova", "count": 10}])
	var boss := em.count() - 1
	em.stun_index(boss, 2.0)
	_check(is_equal_approx(em.stuns[boss], 1.0), "los únicos se aturden la mitad")
	em._resolve_ability(boss, {"kind": "projectile_nova", "count": 10}, Vector2.ZERO)
	_check(em.projectiles.size() == 10, "onda de proyectiles del jefe")
	em._resolve_ability(boss, {"kind": "ground_marks", "count": 4}, Vector2.ZERO)
	_check(em.hazards.size() == 4, "marcas en el suelo del jefe")
	em.clear_all()
	_check(em.projectiles.is_empty() and em.hazards.is_empty() and em.abilities.is_empty(), "limpieza completa")
	em.free()
	# El jefe del acto: menos vida y dos habilidades.
	var act: Dictionary = DataLoader.load_json("res://data/act1.json")
	for z in act["zones"]:
		if z.has("boss"):
			_check(float(z["boss"]["life_mult"]) < 4.0, "el jefe tiene menos vida")
			_check(z["boss"].get("abilities", []).size() >= 2, "el jefe tiene habilidades especiales")
			for a in z["boss"]["abilities"]:
				_check(a["kind"] in ["projectile_nova", "ground_marks", "summon", "oom_beam", "floor_break", "safe_zones", "channel_adds"],
					"habilidad de jefe desconocida: %s" % a["kind"])


func _test_skill_tags() -> void:
	for def in _db.skills.skills.values():
		var tags: Array = def.get("tags", [])
		_check(tags.size() >= 2, "%s debe tener varias etiquetas" % def["id"])
		_check(tags.has("attack") or tags.has("spell"), "%s: ataque o hechizo" % def["id"])
		for t in tags:
			_check(SkillTags.is_known(t), "%s: etiqueta desconocida %s" % [def["id"], t])
		for implied in SkillTags.DAMAGE_TYPE_TAGS.get(def.get("damage_type", ""), []):
			if def["kind"] != "blink":
				_check(tags.has(implied), "%s: le falta la etiqueta %s por su tipo de daño" % [def["id"], implied])
	_check(SkillTags.display_name("minion") == "esbirro" and SkillTags.display_name("degen") == "degenerativo", "nombres en español")
	for ram in _db.skills.rams.values():
		for t in ram.get("requires_tags", []) + ram.get("excludes_tags", []):
			_check(SkillTags.is_known(t), "RAM %s: etiqueta desconocida %s" % [ram["id"], t])


func _test_new_supports() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 9)
	# Perforación.
	var ping := gen.generate_motherboard(1, "ping_letal", 3)
	var base_pierce: int = SkillCalc.compute(ping, c)["pierce"]
	ping.slots[0] = "DDR4"
	ping.install(gen.generate_ram(1, "bypass_firewall"), 0)
	_check(SkillCalc.compute(ping, c)["pierce"] == base_pierce + 3, "Bypass de Firewall: +3 perforación")
	# Cadenas: más saltos en las cadenas y rebotes en proyectiles.
	var chain := gen.generate_motherboard(1, "excepcion_en_cadena", 3)
	var base_chains: int = SkillCalc.compute(chain, c)["chains"]
	chain.slots[0] = "DDR5"
	chain.install(gen.generate_ram(1, "propagacion_excepciones"), 0)
	_check(SkillCalc.compute(chain, c)["chains"] == base_chains + 2, "Propagación: +2 cadenas")
	ping.slots[1] = "DDR5"
	ping.install(gen.generate_ram(1, "propagacion_excepciones"), 1)
	_check(SkillCalc.compute(ping, c)["projectile_chains"] == 2, "Propagación: los proyectiles rebotan")
	# Trampa / mina / torreta: cambian el despliegue y añaden la etiqueta.
	for entry in [["disparador_trampa", "DDR4", "trap"], ["detonador_mina", "DDR5", "mine"], ["servidor_torreta", "DDR3", "totem"]]:
		var board := gen.generate_motherboard(1, "flamewar", 3)
		board.slots[0] = entry[1]
		var ram := gen.generate_ram(1, entry[0])
		_check(ram.supports(board.skill_def), "%s funciona con Flamewar" % entry[0])
		board.install(ram, 0)
		var p := SkillCalc.compute(board, c)
		_check(p["deploy"] == entry[2] and p["tags"].has(StringName(entry[2])), "%s: se despliega como %s" % [entry[0], entry[2]])
		if entry[2] == "totem":
			_check(p["totem_duration"] > 0.0, "la torreta dura un tiempo")
	_check(not gen.generate_ram(1, "disparador_trampa").supports(_db.skills.skills["bomba_logica"]), "una trampa no se convierte en trampa")
	_check(not gen.generate_ram(1, "servidor_torreta").supports(_db.skills.skills["teleport_tcp"]), "el movimiento no va en torreta")
	# Esbirros y degenerativo.
	var minion := SkillCalc.compute(gen.generate_motherboard(1, "proceso_hijo"), c)
	_check(minion["count"] >= 2 and minion["duration"] > 0.0 and minion["max_damage"] > 0.0, "Proceso Hijo invoca esbirros")
	c.stats.add_modifier(Modifier.new(Stat.MINION_DAMAGE, Modifier.Type.INCREASED, 100.0))
	var stronger := SkillCalc.compute(gen.generate_motherboard(1, "proceso_hijo"), c)
	_check(is_equal_approx(stronger["max_damage"], minion["max_damage"] * 2.0), "los esbirros escalan con daño de esbirros")
	var degen := SkillCalc.compute(gen.generate_motherboard(1, "fuga_de_memoria"), c)
	_check(degen["dps"] > 0.0 and degen["duration"] > 0.0, "Fuga de Memoria hace daño en el tiempo")


func _test_flasks() -> void:
	_check(_db.flasks.size() >= 20, "hay muchas pociones (%d)" % _db.flasks.size())
	var kinds := {}
	for def in _db.flasks.values():
		kinds[def["kind"]] = true
		_check(int(def["charges_per_use"]) <= int(def["max_charges"]), "%s: usos posibles" % def["id"])
		if def["kind"] == "utility":
			_check(not def.get("mods", []).is_empty(), "%s: efecto de utilidad" % def["id"])
			for m in def["mods"]:
				_check(Stat.exists(StringName(m["stat"])), "%s: stat desconocido" % def["id"])
		else:
			_check(float(def.get("recover", 0)) > 0.0, "%s: recupera algo" % def["id"])
	_check(kinds.has("life") and kinds.has("mana") and kinds.has("utility"), "vida, maná y utilidad")
	# Las de nivel alto recuperan más.
	_check(_db.flasks["cafe_especialidad"]["recover"] > _db.flasks["cafe_maquina"]["recover"], "mejores cafés a más nivel")
	_check(_db.flasks["yerba_turbo"]["recover"] > _db.flasks["pepsy"]["recover"], "mejores bebidas a más nivel")
	# Cargas.
	var f := Flask.new(_db.flasks["cafe_maquina"])
	_check(f.charges == f.max_charges() and f.uses_left() == 5, "empieza llena: 30 cargas, 6 por uso")
	f.charges -= f.cost()
	f.add_charges(100.0)
	_check(f.charges == f.max_charges(), "no pasa del máximo")
	# Guardado y cinturón.
	var c := _new_character()
	c.inventory.flasks[0] = Flask.new(_db.flasks["latte"])
	c.inventory.flasks[0].charges = 12.0
	c.inventory.add_item(Flask.new(_db.flasks["kombucha"]))
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(loaded.inventory.flasks[0] is Flask and loaded.inventory.flasks[0].def["id"] == "latte", "cinturón guardado")
	_check(is_equal_approx(loaded.inventory.flasks[0].charges, 12.0), "cargas guardadas")
	_check(loaded.inventory.bag.any(func(i) -> bool: return i is Flask), "poción en la bolsa guardada")
	# Guardados antiguos (sin cinturón) reciben las iniciales.
	data["inventory"].erase("flasks")
	var old := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(old.inventory.flasks[0] is Flask and old.inventory.flasks[1] is Flask, "pociones iniciales al migrar")
	# Reglas del cinturón.
	var bag_index := c.inventory.bag.find(c.inventory.bag.filter(func(i) -> bool: return i is Flask)[0])
	_check(ItemTransfer.fits(c, {"kind": "flask", "index": 2}, c.inventory.bag[bag_index]) != "", "nivel insuficiente para la kombucha")
	c.set_level(40)
	_check(ItemTransfer.move(c, {"kind": "bag", "index": bag_index}, {"kind": "flask", "index": 2}) == "", "poción al cinturón")
	_check(ItemTransfer.fits(c, {"kind": "flask", "index": 3}, ItemGenerator.new(_db).generate(1, Rarity.Item.NORMAL)) != "", "en el cinturón solo pociones")
	# Efecto de utilidad: modifica las stats mientras dura.
	var before := c.stats.get_value(Stat.CHAOS_RES)
	var kombucha: Flask = c.inventory.flasks[2]
	c.add_timed_effect("flask:kombucha", kombucha.timed_modifiers(), 5.0)
	_check(c.stats.get_value(Stat.CHAOS_RES) == before + 25.0, "la kombucha da resistencia al caos")
	c.tick_timed_effects(6.0)
	_check(c.stats.get_value(Stat.CHAOS_RES) == before, "y se pasa")
	# Botín: pociones de nivel adecuado.
	var gen := ItemGenerator.new(_db, 4)
	for k in 30:
		var drop := gen.generate_flask(5)
		_check(drop != null and drop.required_level() <= 5, "pociones de botín de nivel <= zona")


func _test_act2_layout() -> void:
	var act: Dictionary = DataLoader.load_json("res://data/act2.json")
	var zones := {}
	for z in act["zones"]:
		zones[z["id"]] = z
	_check(zones.size() >= 8, "Acto II con al menos 6-7 escenarios además de la Brecha y el pueblo (%d)" % zones.size())
	# Camino principal desde el pueblo hasta el jefe (sin pasar por salidas con objeto clave).
	var seen := {"socket_seguro": true}
	var todo := ["socket_seguro"]
	while not todo.is_empty():
		var z: Dictionary = zones[todo.pop_back()]
		for e in z.get("exits", []):
			if e.get("requires_item", "") != "" or not zones.has(e["target"]):
				continue
			if not seen.has(e["target"]):
				seen[e["target"]] = true
				todo.append(e["target"])
	_check(seen.has("anillo0"), "se llega del Socket Seguro al Anillo 0")
	_check(not seen.has("modulo_frio"), "el Módulo de Refrigeración solo se abre con la tarjeta")
	_check(zones["socket_seguro"].get("safe", false) and zones["socket_seguro"].has("waypoint"), "el Socket Seguro es el pueblo (reaparición)")
	# El camino bloqueado: la llave está en una zona más adelante que la puerta.
	var lock_zone := ""
	var key_zone := ""
	for z in act["zones"]:
		for e in z.get("exits", []):
			if e.get("requires_item", "") == "tarjeta_rack":
				lock_zone = z["id"]
		for k in z.get("key_items", []):
			if k["id"] == "tarjeta_rack":
				key_zone = z["id"]
	var order := ["socket_seguro", "fabrica", "alcantarillas", "fosa", "grieta", "bus", "anillo0"]
	_check(lock_zone != "" and key_zone != "" and order.find(key_zone) > order.find(lock_zone), "la tarjeta está más adelante que la escotilla (hay que volver)")
	_check(KeyItem.DEFS.has("tarjeta_rack") and ItemIcons.has_icon("key_card"), "objeto clave definido con icono")
	# Pruebas de estrés y misiones secundarias.
	var challenges := 0
	for z in act["zones"]:
		challenges += z.get("challenges", []).size()
		for c in z.get("challenges", []):
			_check(int(c.get("waves", 0)) >= 3 and not c.get("rewards", []).is_empty(), "%s: oleadas y recompensa" % c["id"])
			for ty in c.get("types", []):
				_check(EnemyManager.enemy_types().any(func(e: Dictionary) -> bool: return e["id"] == ty), "%s: tipo desconocido %s" % [c["id"], ty])
	_check(challenges >= 3, "varias pruebas de estrés en el acto")
	var quests := QuestLog.database()
	for id in ["puntero_salvaje", "sindicato_descriptor", "cache_en_frio", "prueba_estres"]:
		_check(quests.has(id), "misión secundaria %s" % id)
	_check(zones["anillo0"]["boss"]["type"] == "init" and zones["anillo0"]["boss"]["abilities"].size() >= 4, "init con habilidades por fases")


func _test_act2_mechanics() -> void:
	# Objeto clave: se guarda, se detecta y no se puede tirar.
	var c := _new_character()
	_check(not KeyItem.has_key(c.inventory, "tarjeta_rack"), "sin tarjeta al principio")
	c.inventory.add_item(KeyItem.new("tarjeta_rack"))
	_check(KeyItem.has_key(c.inventory, "tarjeta_rack"), "tarjeta en la bolsa")
	var idx := c.inventory.bag.find(c.inventory.bag.filter(func(i) -> bool: return i is KeyItem)[0])
	_check(ItemTransfer.take(c, {"kind": "bag", "index": idx}) == null and KeyItem.has_key(c.inventory, "tarjeta_rack"), "no se puede tirar")
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(KeyItem.has_key(loaded.inventory, "tarjeta_rack"), "la tarjeta se guarda")
	# Inmunidad por turnos (Carrera Crítica).
	var em := EnemyManager.new()
	var a := em.spawn(Vector2.ZERO, Rarity.Enemy.UNIQUE, em.type_index_of("hilo_gemelo"))
	em.set_immune(a, true)
	var before := em.lives[0]
	em.hit_in_radius(Vector2.ZERO, 50.0, 100.0, 100.0, 0.0, 150.0)
	_check(em.lives[0] == before, "el gemelo inmune no recibe daño")
	em.set_immune(a, false)
	em.hit_in_radius(Vector2.ZERO, 50.0, 10.0, 10.0, 0.0, 150.0)
	_check(em.lives[0] < before, "el gemelo de turno sí")
	_check(em.count_type("hilo_gemelo") == 1 and em.is_alive_id(a), "conteo por tipo")
	em.clear_all()
	# Fases del jefe: cada habilidad solo en su tramo de vida.
	var boss_id := em.spawn(Vector2(500, 0), Rarity.Enemy.UNIQUE, em.type_index_of("init"), "init", 1.0, [
		{"kind": "summon", "type": "init_fork", "count": 2, "cooldown": 1.0, "first": 0.0, "min_life": 0.66},
		{"kind": "oom_beam", "count": 1, "cooldown": 1.0, "first": 0.0, "max_life": 0.33, "cores": [[0, 0]], "self_damage": 0.1}])
	var bi := em.index_of(boss_id)
	_check(em._try_ability(bi, 0.1, 100.0, Vector2.ZERO) and em.casting[boss_id]["def"]["kind"] == "summon", "fase 1: Fork Bomb")
	em.casting.clear()
	em.lives[bi] = em.max_lives[bi] * 0.2
	for a2 in em.abilities[boss_id]:
		a2["timer"] = 0.0
	_check(em._try_ability(bi, 0.1, 100.0, Vector2.ZERO) and em.casting[boss_id]["def"]["kind"] == "oom_beam", "fase 3: OOM Killer")
	# El rayo del OOM Killer daña al propio jefe si lo atraviesa.
	var life_before := em.lives[bi]
	em._resolve_ability(bi, em.casting[boss_id]["def"], em.positions[bi])   # rayo del núcleo (0,0) hacia el jefe
	em.hazards[0]["time"] = 99.0
	em._update_hazards(0.0)
	_check(em.lives[bi] < life_before, "el OOM Killer se come a init si le apuntas bien")
	em.free()
	# Misiones: eliminar un tipo concreto y recoger varios objetos.
	var c2 := _new_character()
	var log := QuestLog.new(c2)
	log.start("puntero_salvaje")
	log.notify_kill("fosa", Rarity.Enemy.UNIQUE, "proceso_zombi")
	_check(log.current_step("puntero_salvaje")["type"] == "kill", "otro tipo no cuenta")
	log.notify_kill("fosa", Rarity.Enemy.UNIQUE, "puntero_salvaje")
	_check(log.npc_has_turn_in("rafa_terminal"), "el Puntero cuenta")
	log.start("cache_en_frio")
	c2.flags["item_cache_1"] = true
	c2.flags["item_cache_2"] = true
	log.refresh()
	_check(log.step_text("cache_en_frio").ends_with("(2/3)"), "progreso de varios objetos")
	c2.flags["item_cache_3"] = true
	log.refresh()
	_check(log.npc_has_turn_in("clara"), "los tres bloques recogidos")


func _test_progression_rules() -> void:
	# Puntos de pasiva: ninguno al empezar, 1 por nivel y extra por misiones.
	var c := _new_character()
	_check(c.passive_points_total() == 0 and c.passive_points_available() == 0, "sin puntos al crear el personaje")
	c.set_level(5)
	_check(c.passive_points_total() == 4, "1 punto por cada nivel subido")
	c.flags["quest_passive_points"] = 2
	_check(c.passive_points_total() == 6, "puntos extra por misiones")
	var main_rewards: Array = QuestLog.database()["main_act1"]["rewards"]
	_check(main_rewards.any(func(r: Dictionary) -> bool: return r["type"] == "passive_point"), "la misión principal da puntos de pasiva")
	# Guardados con más puntos gastados de los que ahora tocan: se devuelven.
	var old := _new_character()
	old.set_level(3)
	var start := old.passives.start_node_id
	var data = JSON.parse_string(JSON.stringify(old.to_dict()))
	var far: Array = []
	var alloc := PassiveAllocation.new(_tree, start)
	for id in _tree.nodes:
		if alloc.find_path(id).size() == 6:
			alloc.allocate_path(id, 999)
			break
	for id in alloc.get_allocated_ids():
		if id != start:
			far.append(id)
	data["passives"] = far
	data["passive_tree_version"] = _tree.version
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(loaded.passives.spent_points() == 0 and loaded.flags.has("passives_refunded"), "se devuelven los puntos sobrantes")
	# Las placas suben de nivel con la experiencia (como las gemas de PoE).
	var c2 := _new_character()
	var board: Motherboard = c2.inventory.boards[0] if c2.inventory.boards[0] else Motherboard.new(_db.skills.skills["barrido"], 1, ["DDR3"])
	c2.inventory.set_board(0, board)
	var before: float = SkillCalc.compute(board, c2)["max_damage"]
	c2.add_experience(board.experience_to_next() * 3)
	_check(board.level >= 2, "la placa instalada sube de nivel")
	_check(SkillCalc.compute(board, c2)["max_damage"] > before, "y pega más fuerte")
	var saved = JSON.parse_string(JSON.stringify(c2.to_dict()))
	_check(int(saved["inventory"]["boards"][0]["level"]) == board.level, "el nivel de la placa se guarda")
	# Ascendencias: fuertes y con efectos especiales.
	var specials := 0
	for cdef in _classes:
		for a in cdef["ascendancies"]:
			var big := false
			for p in a["passives"]:
				for md in p["mods"]:
					if md["type"] == "more" and float(md["value"]) >= 25.0:
						big = true
					if String(md["stat"]).begins_with("extra_"):
						specials += 1
			_check(big or a["passives"].any(func(p: Dictionary) -> bool: return p["mods"].any(func(md: Dictionary) -> bool:
				return String(md["stat"]).begins_with("extra_") or md["stat"] in ["kill_explosion", "static_pulse", "retaliation_nova", "companion_robot"] + SIGNATURE_STATS)), "%s debe tener un efecto fuerte" % a["id"])
	_check(specials >= 8, "varias ascendencias cambian cómo funcionan las habilidades (%d)" % specials)
	var hacker: Dictionary = _classes.filter(func(x: Dictionary) -> bool: return x["id"] == "hacker")[0]
	var ch := CharacterData.new(hacker, _tree)
	var chain_board := Motherboard.new(_db.skills.skills["excepcion_en_cadena"], 1, ["DDR5"])
	var chains_before: int = SkillCalc.compute(chain_board, ch)["chains"]
	ch.set_level(40)
	ch.set_ascendancy(&"asesina_sesiones")
	for n in [15, 16, 5, 6, 7]:   # Sesión persistente (16) y Movimiento lateral (7)
		ch.allocate_ascendancy_node(n)
	_check(SkillCalc.compute(chain_board, ch)["chains"] == chains_before + 2, "la Asesina de Sesiones encadena 2 veces más")
	# Los atributos dan daño a su estilo.
	var warrior := CharacterData.new(_classes.filter(func(x: Dictionary) -> bool: return x["id"] == "guerrero")[0], _tree)
	var wizard := CharacterData.new(_classes.filter(func(x: Dictionary) -> bool: return x["id"] == "hechicero")[0], _tree)
	_check(wizard.stats.total_multiplier(Stat.DAMAGE, [Stat.TAG_SPELL]) > warrior.stats.total_multiplier(Stat.DAMAGE, [Stat.TAG_SPELL]), "la inteligencia da daño de hechizos")
	_check(warrior.stats.total_multiplier(Stat.PHYSICAL_DAMAGE, [Stat.TAG_MELEE]) > wizard.stats.total_multiplier(Stat.PHYSICAL_DAMAGE, [Stat.TAG_MELEE]), "la fuerza da daño cuerpo a cuerpo")


## Los textos del juego, en español latinoamericano (ver docs/estilo.md).
func _test_latam_spanish() -> void:
	var banned := RegEx.create_from_string("(*UCP)(?i)\\b(vosotr\\w*|vuestr\\w*|os|\\w+áis|\\w+éis|portátil\\w*|ordenador\\w*|móvil\\w*|vale|coger|ratón|gafas|zumo|guay|becari\\w*|marchando|cuidaos|proteged)\\b")
	var files := ["res://data/npcs.json", "res://data/cutscenes.json", "res://data/quests.json", "res://data/tutorial.json",
		"res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json", "res://data/classes.json", "res://data/passive_themes.json",
		"res://data/items/flasks.json", "res://data/items/uniques.json", "res://data/items/bases.json",
		"res://data/skills/skills.json", "res://data/skills/ram_modules.json", "res://data/enemies.json"]
	var found := PackedStringArray()
	for path in files:
		_collect_banned(DataLoader.load_json(path), banned, path, found)
	_check(found.is_empty(), "formas de España en los textos: %s" % ", ".join(found.slice(0, 8)))


func _collect_banned(value: Variant, banned: RegEx, path: String, found: PackedStringArray) -> void:
	if value is Dictionary:
		for k in value:
			if k != "id" and not String(k).ends_with("_id"):
				_collect_banned(value[k], banned, path, found)
	elif value is Array:
		for v in value:
			_collect_banned(v, banned, path, found)
	elif value is String:
		var m := banned.search(value)
		if m:
			found.append("%s: «%s»" % [path.get_file(), m.get_string()])


## Roadmap 2.0: cargas, costo de vida, requisitos de atributos, variantes, chips,
## invocación con varias habilidades, filtro de botín y eventos de zona.
## Roadmap 2.0, segunda tanda: esquiva, golpes pesados, retroceso, nombres de
## raros, conversión de daño, RAM con desventaja y pociones con estilo.
func _test_roadmap2_second_batch() -> void:
	var rams: Dictionary = _db.skills.rams
	var skills: Dictionary = _db.skills.skills
	var c := _new_character()
	c.set_level(20)
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	em.player = player
	player.global_position = Vector2(9000, 9000)
	# Esquiva: gasta una carga, da invulnerabilidad breve y se recarga sola.
	_check(player.dodge_charges == Player.DODGE_CHARGES, "empieza con %d esquivas" % Player.DODGE_CHARGES)
	_check(player.dodge() and player.is_dodging() and player.dodge_charges < Player.DODGE_CHARGES, "esquivar gasta una carga y vuelve invulnerable")
	player.life = player.max_life()
	player.take_damage(player.max_life() * 0.5)
	player.apply_dot("prueba", 50.0, 2.0, "fire")
	_check(player.life == player.max_life() and player.dots.is_empty(), "durante la esquiva no entran golpes ni charcos")
	player._iframes = 0.0
	player._dodge_time = 0.0
	player.dodge_charges = 0.0
	_check(not player.dodge(), "sin cargas no se esquiva")
	# Pociones con estilo.
	var mate := Flask.new(_db.flasks["klub_mate"], 10)
	c.inventory.flasks[0] = mate
	player.use_flask(0)
	_check(player.max_dodge_charges() == Player.DODGE_CHARGES + 1 and player.dodge_charges >= Player.DODGE_CHARGES + 1,
		"Klub-Mate: recarga las esquivas y da una más (%.1f / %d)" % [player.dodge_charges, player.max_dodge_charges()])
	var tea := Flask.new(_db.flasks["manzanilla_debug"], 10)
	c.inventory.flasks[1] = tea
	player.statuses["chill"] = 3.0
	player.dots["x"] = {"dps": 5.0, "time": 3.0, "kind": "chaos"}
	player.use_flask(1)
	_check(player.statuses.is_empty() and player.dots.is_empty(), "Manzanilla con breakpoint: quita estados y degenerativos")
	_check(_db.flasks["cafe_para_el_equipo"].has("heal_minions") and Flask.new(_db.flasks["cafe_para_el_equipo"], 20).effect_lines()[0].contains("invocaciones"),
		"Termo de café: cura invocaciones y lo dice")
	# Golpe pesado de raros: telegrafiado, y golpea fuerte en su radio.
	em.area_level = 10
	var melee := -1
	for k in EnemyManager.enemy_types().size():
		var t: Dictionary = EnemyManager.enemy_types()[k]
		if String(t.get("attack", {}).get("kind", "melee")) == "melee" and not t.get("boss_only", false) and float(t.get("speed_mult", 1.0)) > 0.0 and not t.get("summon_only", false):
			melee = k
			break
	var rare_id := em.spawn(player.global_position + Vector2(40, 0), Rarity.Enemy.ELITE, melee)
	var ri := em.index_of(rare_id)
	_check(em.traits[ri].has("heavy") and em.traits[ri].has("quote"), "los raros cuerpo a cuerpo tienen golpe pesado y frase")
	_check(em.names[ri].length() > 8, "nombre generado de raro: «%s»" % em.names[ri])
	player.life = player.max_life()
	player.invulnerable = false
	var hit := false
	for k in 30:   # la evasión del personaje puede esquivarlo
		player.life = player.max_life()
		em._resolve_heavy(ri)
		if player.life < player.max_life():
			hit = true
			break
	_check(hit, "el golpe pesado daña al jugador dentro del círculo")
	# Retroceso: un golpe empuja a los enemigos normales, no a los únicos.
	var n_id := em.spawn(player.global_position + Vector2(60, 0), Rarity.Enemy.NORMAL, melee)
	var ni := em.index_of(n_id)
	em.max_lives[ni] = 1000.0
	em.lives[ni] = 1000.0
	em.hit_index(ni, 100.0, 100.0, 0.0, 150.0)
	ni = em.index_of(n_id)
	_check(em.knocks[ni].x > 0.0, "el golpe empuja al enemigo lejos del jugador")
	var u_id := em.spawn(player.global_position + Vector2(-60, 0), Rarity.Enemy.UNIQUE, melee)
	em.hit_index(em.index_of(u_id), 10.0, 10.0, 0.0, 150.0)
	_check(em.knocks[em.index_of(u_id)] == Vector2.ZERO, "los únicos no retroceden")
	em.clear_all()
	_check(em.knocks.is_empty(), "limpiar enemigos vacía el retroceso")
	player.queue_free()
	em.queue_free()
	# Conversión de daño: físico → rayo, con los aumentos de ambos.
	var b := Motherboard.new(skills["barrido"], 5, ["DDR3"])
	var plain := SkillCalc.compute(b, c)
	b.install(RamModule.new(rams["transformador_de_tension"]), 0)
	var conv := SkillCalc.compute(b, c)
	_check(conv["damage_type"] == "lightning" and conv["converted_from"] == "physical" and conv["tags"].has(&"lightning"),
		"Transformador de Tensión: el Barrido hace daño de rayo")
	c.add_timed_effect("prueba_rayo", [Modifier.new(Stat.LIGHTNING_DAMAGE, Modifier.Type.INCREASED, 100.0, [], "prueba")], 5.0)
	var boosted := SkillCalc.compute(b, c)
	_check(boosted["max_damage"] > conv["max_damage"] * 1.3 and is_equal_approx(SkillCalc.compute(Motherboard.new(skills["barrido"], 5, []), c)["max_damage"], plain["max_damage"]),
		"el daño convertido escala con los aumentos del tipo nuevo; sin la RAM, no")
	_check(not RamModule.new(rams["transformador_de_tension"]).supports(skills["ping_letal"]), "convertir físico no encaja en un hechizo de rayo")
	_check(RamModule.new(rams["sobrecalentamiento"]).supports(skills["stack_overflow"]), "Sobrecalentamiento sí encaja en frío")
	var s := StatBlock.new()
	s.add_modifier(Modifier.new(Stat.DAMAGE, Modifier.Type.INCREASED, 10.0))
	_check(is_equal_approx(s.get_breakdown_union([Stat.PHYSICAL_DAMAGE, Stat.LIGHTNING_DAMAGE])["increased"], 10.0), "el «Daño» compartido no cuenta dos veces")
	# RAM con desventaja fuerte.
	var nocrit := Motherboard.new(skills["ping_letal"], 5, ["DDR5"])
	nocrit.install(RamModule.new(rams["memoria_sin_ecc"]), 0)
	var pn := SkillCalc.compute(nocrit, c)
	_check(pn["crit_chance"] == 0.0 and pn["max_damage"] > SkillCalc.compute(Motherboard.new(skills["ping_letal"], 5, []), c)["max_damage"] * 1.5,
		"Memoria sin ECC: mucho más daño, ningún crítico")
	_check(not RamModule.new(rams["turbo_sin_disipador"]).supports(skills["teleport_tcp"]), "las RAM con desventaja no encajan en habilidades sin daño")
	var o3 := Motherboard.new(skills["ping_letal"], 5, ["DDR4"])
	var cost_before: float = SkillCalc.compute(o3, c)["mana_cost"]
	o3.install(RamModule.new(rams["compilacion_o3"]), 0)
	var cost_after: float = SkillCalc.compute(o3, c)["mana_cost"]
	_check(cost_after >= cost_before * 1.8, "Compilación -O3: el doble de maná (%d → %d)" % [cost_before, cost_after])
	_check(InputMap.has_action(&"dodge"), "existe la acción de esquivar (Shift)")
	var seen := {}
	for m in DataLoader.load_json("res://data/skills/ram_modules.json")["modules"]:
		_check(not seen.has(m["id"]), "id de RAM repetido: %s" % m["id"])
		seen[m["id"]] = true


## Roadmap 2.0, fase "Sensación": partículas de impacto, muertes con estilo,
## materiales, antorchas y luces de la zona, y los sonidos nuevos.
func _test_roadmap2_feel() -> void:
	var em := EnemyManager.new()
	root.add_child(em)
	_check(em.impact != null, "el gestor de enemigos crea sus partículas de impacto")
	em.area_level = 5
	var id := em.spawn(Vector2(100, 100), Rarity.Enemy.NORMAL, em.type_index_of("daemon"))
	var i := em.index_of(id)
	_check(em.material_of(i) == "metal" and em.material_of(em.index_of(em.spawn(Vector2(300, 100), Rarity.Enemy.NORMAL, em.type_index_of("proceso_fantasma")))) == "digital",
		"materiales: el daemon es metal, el proceso fantasma digital")
	em.max_lives[i] = 1000.0
	em.lives[i] = 1000.0
	em.hit_ailments = {"type": "fire"}
	em.hit_index(i, 50.0, 50.0, 0.0, 150.0)
	_check(em.impact.count() > 0, "un golpe suelta partículas")
	var before := em.impact.count()
	em.hit_index(em.index_of(id), 5000.0, 5000.0, 0.0, 150.0)
	_check(em.impact.count() > before + 10 and not em.impact.flashes.is_empty(), "morir por fuego: ceniza y un destello que alumbra")
	em.hit_ailments = {}
	# Muerte por degenerativo: el tipo lo decide la quemadura.
	var b := em.spawn(Vector2(500, 100), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var bi := em.index_of(b)
	em.lives[bi] = 1.0
	em.burn_dps[bi] = 100.0
	em.burn_time[bi] = 2.0
	em.impact.clear()
	em._update_dots(0.1)
	_check(not em.is_alive_id(b) and em.impact.count() > 0, "morir quemado también deja su muerte con estilo")
	em.clear_all()
	_check(em.impact.count() == 0, "limpiar la zona borra las partículas")
	em.queue_free()
	# Antorchas solo en las zonas oscuras, y dan luz.
	var dark := Zone.new()
	dark.setup(_zone_def("zona4"), null, null)
	_check(not dark.torches.is_empty() and dark.light_points().size() >= dark.torches.size(), "las catacumbas tienen antorchas que alumbran (%d)" % dark.torches.size())
	for t in dark.torches:
		_check(dark.is_walkable(t["pos"]), "antorcha en suelo transitable")
	var lit := Zone.new()
	lit.setup(_zone_def("zona2"), null, null)
	_check(lit.torches.is_empty(), "las ruinas (sin oscuridad) no tienen antorchas")
	dark.free()
	lit.free()
	for s in ["hit_flesh", "hit_metal", "hit_crystal", "hit_digital", "crit_click", "unique_drop", "death_ash", "death_decompile"]:
		_check(ResourceLoader.exists(Sfx.SFX_DIR + s + ".wav"), "existe el sonido %s" % s)


## Controles nuevos (QWERTY, flechas, Espacio, Tab, Shift, B), iconos únicos,
## catálogo, mapa grande con niebla y menos botín.
func _test_controls_map_catalog() -> void:
	var key_of := func(action: StringName) -> int:
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				return (e as InputEventKey).physical_keycode
		return -1
	var expected := {&"skill_1": KEY_Q, &"skill_2": KEY_W, &"skill_3": KEY_E, &"skill_4": KEY_R, &"skill_5": KEY_T, &"skill_6": KEY_Y,
		&"move_up": KEY_UP, &"move_down": KEY_DOWN, &"move_left": KEY_LEFT, &"move_right": KEY_RIGHT,
		&"dodge": KEY_SPACE, &"toggle_map": KEY_TAB, &"show_all_loot": KEY_SHIFT, &"toggle_catalog": KEY_B}
	for a in expected:
		_check(key_of.call(a) == expected[a], "tecla de %s: %s" % [a, OS.get_keycode_string(expected[a])])
	_check(SkillController.KEY_LABELS == ["Q", "W", "E", "R", "T", "Y"], "la barra muestra Q W E R T Y")
	# Cada habilidad con su propio icono.
	var shapes := {}
	for id in _db.skills.skills:
		var shape := String(_db.skills.skills[id].get("icon", {}).get("shape", ""))
		_check(shape != "" and not shapes.has(shape), "icono propio para %s (forma «%s» ya usada por %s)" % [id, shape, shapes.get(shape, "-")])
		shapes[shape] = id
	# Catálogo: ficha completa y lo encontrado.
	var c := _new_character()
	var cat := CatalogPanel.new()
	cat.setup(c, _db.skills)
	var ping := String(_db.skills.skills["ping_letal"]["name"])
	_check(cat.entries().size() == _db.skills.skills.size(), "el catálogo lista todas las placas")
	var text := cat.detail_text("ping_letal")
	_check(text.contains(ping) and text.contains("Aún no encontrada") and text.contains("RAM compatibles"), "ficha de placa con nombre, estado y compatibilidad")
	CatalogPanel.note_item(c, Motherboard.new(_db.skills.skills["ping_letal"], 1, []))
	_check(cat.is_seen("ping_letal") and cat.detail_text("ping_letal").contains("Encontrada"), "lo recogido queda marcado como encontrado")
	cat._set_tab("rams")
	_check(cat.entries().size() == _db.skills.rams.size() and cat.detail_text("multicanal").contains("Funciona con"), "pestaña de RAM con sus placas compatibles")
	cat.free()
	# Mapa grande: niebla, lo explorado se guarda y se recupera.
	var zone := Zone.new()
	zone.setup(_zone_def("zona1"), null, null)
	var p: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(p)
	p.setup(c, EnemyManager.new())
	p.global_position = zone.rect.position + Vector2(200, 200)
	var wm := WorldMap.new()
	wm.player = p
	wm.character = c
	wm.set_zone(zone)
	var first := wm.explored_fraction()
	_check(first > 0.0 and first < 0.3 and wm.is_explored(p.global_position), "al entrar solo se ve lo de alrededor (%.0f %%)" % (first * 100.0))
	_check(not wm.is_explored(zone.rect.end - Vector2(100, 100)), "la otra punta sigue en la niebla")
	p.global_position = zone.rect.get_center()
	wm.reveal()
	wm.save_explored()
	var wm2 := WorldMap.new()
	wm2.player = p
	wm2.character = c
	p.global_position = zone.rect.position + Vector2(200, 200)
	wm2.set_zone(zone)
	_check(wm2.is_explored(zone.rect.get_center()) and wm2.explored_fraction() > first, "lo explorado se guarda en el personaje")
	wm.free()
	wm2.free()
	p.queue_free()
	zone.free()
	# Menos botín: una zona media suelta una docena de objetos, no treinta.
	var expected_items := 80.0 * 0.8 * float(Rarity.ENEMY_INFO[Rarity.Enemy.NORMAL]["drop_chance"]) \
		+ 80.0 * 0.2 * float(Rarity.ENEMY_INFO[Rarity.Enemy.SPECIAL]["drop_chance"]) + 2.0 * 2.0 * float(Rarity.ENEMY_INFO[Rarity.Enemy.ELITE]["drop_chance"])
	_check(expected_items < 14.0, "una zona de 80 enemigos suelta ~%.0f objetos" % expected_items)


## Roles en las manadas: guardián, sanador, francotirador y enjambre.
func _test_enemy_roles() -> void:
	var c := _new_character()
	c.set_level(10)
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	player.global_position = Vector2(20000, 20000)
	player.invulnerable = true
	em.player = player
	em.area_level = 10
	var bug := em.type_index_of("bug")
	var base := Vector2(20000, 20600)
	# Guardián: más vida y protege a los de al lado (no a los lejanos).
	var tank := em.spawn(base, Rarity.Enemy.NORMAL, bug)
	var plain_life := em.max_lives[em.index_of(tank)]
	em.set_role(tank, "tank")
	_check(em.max_lives[em.index_of(tank)] > plain_life * 2.0 and em.role_of(em.index_of(tank)) == "tank", "el guardián tiene más del doble de vida")
	var near := em.spawn(base + Vector2(80, 0), Rarity.Enemy.NORMAL, bug)
	var far := em.spawn(base + Vector2(900, 0), Rarity.Enemy.NORMAL, bug)
	for id in [near, far]:
		em.max_lives[em.index_of(id)] = 10000.0
		em.lives[em.index_of(id)] = 10000.0
	em._physics_process(0.016)
	em.hit_index(em.index_of(near), 100.0, 100.0, 0.0, 150.0)
	var near_taken := 10000.0 - em.lives[em.index_of(near)]
	em.hit_index(em.index_of(far), 100.0, 100.0, 0.0, 150.0)
	var far_taken := 10000.0 - em.lives[em.index_of(far)]
	_check(near_taken < far_taken * 0.7, "junto al guardián se recibe menos daño (%.0f frente a %.0f)" % [near_taken, far_taken])
	# Sanador: cura a los heridos de alrededor.
	var healer := em.spawn(base + Vector2(40, 60), Rarity.Enemy.NORMAL, bug)
	em.set_role(healer, "healer")
	var hurt_before := em.lives[em.index_of(near)]
	em._heal_around(em.index_of(healer))
	_check(em.lives[em.index_of(near)] > hurt_before, "el sanador cura a los heridos cercanos")
	# Francotirador: se para, avisa con la línea y dispara un tiro rápido y fuerte.
	em.clear_all()
	var sniper := em.spawn(player.global_position + Vector2(500, 0), Rarity.Enemy.NORMAL, bug)
	em.set_role(sniper, "sniper")
	var si := em.index_of(sniper)
	em.cooldowns[si] = 0.0
	em._physics_process(0.016)
	si = em.index_of(sniper)
	_check(em.traits[si].get("snipe_on", false) and em.windups[si] > 0.0, "el francotirador apunta (aviso con línea)")
	for k in 90:
		em._physics_process(0.016)
	_check(not em.projectiles.is_empty() or em.cooldowns[em.index_of(sniper)] > 0.0, "y dispara")
	# Enjambre: rápido y frágil, entra por el costado.
	var sw := em.spawn(player.global_position + Vector2(600, 0), Rarity.Enemy.NORMAL, bug)
	var speed0 := em.speeds[em.index_of(sw)]
	em.set_role(sw, "swarm")
	_check(em.speeds[em.index_of(sw)] > speed0 * 1.4, "el enjambre es más rápido")
	var step: Variant = em._role_step(em.index_of(sw), em.traits[em.index_of(sw)], "swarm", 0.016, Vector2(-600, 0), 600.0, 30.0, true)
	_check(step is Vector2 and absf((step as Vector2).y) > 1.0, "el enjambre rodea en vez de ir en línea recta")
	player.queue_free()
	em.queue_free()


## Golems nuevos: cada uno da su bono al creador mientras vive (y crece con el
## nivel de la placa); habilidades de enredo y corrupción.
func _test_golems() -> void:
	var skills: Dictionary = _db.skills.skills
	var c := _new_character()
	c.set_level(20)
	var expected := {"golem_silicio": [Stat.ARMOUR, Stat.ENERGY_SHIELD_REGEN], "golem_overclock": [Stat.ATTACK_SPEED, Stat.CAST_SPEED, Stat.MOVEMENT_SPEED],
		"golem_utp": [Stat.AUTOMATON_SPEED], "golem_gpu": [Stat.MANA_COST_REDUCTION, Stat.COOLDOWN_RECOVERY], "golem_kernel": [Stat.CHAOS_RES]}
	for gid in expected:
		_check(skills.has(gid) and "golem" in skills[gid]["tags"], "existe la placa %s" % gid)
		var p1 := SkillCalc.compute(Motherboard.new(skills[gid], 1, []), c)
		var p20 := SkillCalc.compute(Motherboard.new(skills[gid], 20, []), c)
		var stats_in := (p1["owner_buff"] as Array).map(func(md: Dictionary) -> StringName: return StringName(md["stat"]))
		for st in expected[gid]:
			_check(stats_in.has(st), "%s da %s" % [gid, st])
		_check(float(p20["owner_buff"][0]["value"]) > float(p1["owner_buff"][0]["value"]), "el bono de %s crece con el nivel de la placa" % gid)
	# El bono está solo mientras el golem vive.
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	player.global_position = Vector2(30000, 30000)
	var sc := SkillController.new()
	root.add_child(sc)
	c.inventory.set_board(0, Motherboard.new(skills["golem_silicio"], 10, []))
	sc.setup(player, em, c)
	var armour0 := c.stats.get_value(Stat.ARMOUR)
	sc._summon_unit(sc.profile(0), player.global_position, Color.WHITE)
	sc._sync_golem_buffs()
	_check(c.stats.get_value(Stat.ARMOUR) > armour0 + 50.0 and c.stats.get_value(Stat.ENERGY_SHIELD_REGEN) > 0.0, "con el Golem del Silicio vivo: más armadura y regeneración de escudo")
	sc.clear_units()
	_check(is_equal_approx(c.stats.get_value(Stat.ARMOUR), armour0) and not c.has_timed_effect("golem:golem_silicio"), "al caer el golem, el bono se va")
	# El escudo se regenera solo con el stat.
	c.add_timed_effect("prueba_es", [Modifier.new(Stat.ENERGY_SHIELD, Modifier.Type.FLAT, 100.0, [], "p"), Modifier.new(Stat.ENERGY_SHIELD_REGEN, Modifier.Type.FLAT, 10.0, [], "p")], 60.0)
	player.energy_shield = 0.0
	player._since_damage = 0.0
	player._regenerate(1.0)
	_check(player.energy_shield >= 9.9, "regeneración de escudo de energía: %.1f por segundo" % player.energy_shield)
	# Golem GPU: las habilidades cuestan menos.
	var ping := Motherboard.new(skills["ping_letal"], 10, [])
	var cost0: float = SkillCalc.compute(ping, c)["mana_cost"]
	c.add_timed_effect("prueba_gpu", [Modifier.new(Stat.MANA_COST_REDUCTION, Modifier.Type.FLAT, 30.0, [], "p")], 60.0)
	_check(SkillCalc.compute(ping, c)["mana_cost"] < cost0 * 0.8, "la reducción de coste abarata las habilidades")
	# Enredo (UTP) y corrupción (Kernel).
	var utp := SkillCalc.compute(Motherboard.new(skills["golem_utp"], 10, []), c)
	var u := {"pos": Vector2(30000, 30400), "color": Color.WHITE, "ab_cd": 0.0}
	var bug := em.spawn(Vector2(30140, 30400), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.max_lives[em.index_of(bug)] = 99999.0
	em.lives[em.index_of(bug)] = 99999.0
	sc._one_unit_ability(u, utp, utp["unit_abilities"][0], 0.1)
	var bi := em.index_of(bug)
	_check(em.positions[bi].x < 30140.0 and em.stuns[bi] > 0.0, "el enredo atrae y aturde")
	var kernel := SkillCalc.compute(Motherboard.new(skills["golem_kernel"], 10, []), c)
	u["ab_cd"] = 0.0
	sc._one_unit_ability(u, kernel, kernel["unit_abilities"][0], 0.1)
	_check(em.dot_time[em.index_of(bug)] > 0.0, "la corrupción del Golem de Kernel daña con el tiempo")
	sc.queue_free()
	player.queue_free()
	em.queue_free()


## Datos huérfanos al acercarse, capas de combate de la música y letras de rareza
## del modo daltónico.
func _test_events_music_colorblind() -> void:
	var zone := Zone.new()
	var c := _new_character()
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, EnemyManager.new())
	zone.setup(_zone_def("zona1"), player, c)
	var ev := zone.events
	var at := zone.rect.get_center()
	ev.events = [{"kind": "cache", "pos": at, "state": "ready"}]
	var fired: Array = []
	ev.triggered.connect(func(e: Dictionary) -> void: fired.append(e))
	player.global_position = at + Vector2(ZoneEvents.CACHE_TRIGGER_RADIUS + 60.0, 0)
	ev._process(0.1)
	_check(fired.is_empty(), "los datos huérfanos no saltan desde lejos")
	player.global_position = at + Vector2(ZoneEvents.CACHE_TRIGGER_RADIUS - 30.0, 0)
	ev._process(0.1)
	_check(fired.size() == 1 and ev.events[0]["state"] == "active", "al pasar cerca, los datos huérfanos se abren solos")
	player.queue_free()
	zone.free()
	# Capas de combate: existen y empiezan el bucle en la misma muestra que su pista.
	var loops: Dictionary = DataLoader.load_json("res://data/music_loops.json")
	for t in ["field1", "field2", "field3", "dark1", "cold2", "deep3"]:
		_check(Sfx.audio_path("res://assets/audio/music/%s_combate" % t) != "" and int(loops.get(t + "_combate", -1)) == int(loops.get(t, -2)),
			"capa de combate de %s sincronizada con la pista" % t)
	# Modo daltónico: la rareza también en letra.
	_check(LootManager.rarity_tag(Item.new(_db.bases["espada_oxidada"], Rarity.Item.RARE, 5)) == "R"
		and LootManager.rarity_tag(Item.new(_db.bases["espada_oxidada"], Rarity.Item.NORMAL, 5)) == "", "chapita de rareza para daltónicos")


## Editor de historia: guardar no cambia ningún dato (ida y vuelta exacta) y los
## datos actuales no tienen referencias rotas.
func _test_story_editor() -> void:
	var editor: Control = load("res://tools/story_editor.gd").new()
	editor.load_all()
	for key in editor.FILES:
		var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(editor.FILES[key]))
		var again: Variant = JSON.parse_string(editor.to_json(editor.data[key]))
		_check(again is Dictionary and JSON.stringify(again, "", false) == JSON.stringify(original, "", false),
			"editor de historia: %s se guarda sin cambiar nada" % key)
	_check(editor.npcs().size() >= 10 and editor.dialogues().size() >= 10 and editor.cutscenes().size() > 5, "el editor carga NPC, diálogos y escenas")
	var problems: PackedStringArray = editor.validate()
	_check(problems.is_empty(), "la historia no tiene referencias rotas: %s" % " | ".join(problems))
	# Un nodo que apunta a uno inexistente se detecta.
	var dl: Dictionary = editor.dialogues().values()[0]
	var first: Dictionary = dl["nodes"].values()[0]
	first["options"].append({"text": "Prueba", "next": "no_existe"})
	_check(not editor.validate().is_empty(), "la validación avisa de una opción que va a un nodo que no existe")
	_check(editor.to_json({"a": 1.0, "b": 0.5, "c": [1.0, 2.0]}) == "{\n  \"a\": 1,\n  \"b\": 0.5,\n  \"c\": [1, 2]\n}", "enteros sin «.0» al guardar")
	_check(editor.compact_json({"type": "give_random", "rarity": 2.0, "x": 0.5}) == "{\"type\":\"give_random\",\"rarity\":2,\"x\":0.5}", "campos JSON compactos y en su orden")
	# Orden de las tarjetas: el saludo primero; títulos en lenguaje llano.
	var ada: Dictionary = editor.dialogues()["ada"]
	var order: Array = editor.flow_order(ada)
	_check(order[0] == ada["start"] and order.size() == ada["nodes"].size(), "las tarjetas empiezan por el saludo y están todas")
	_check(editor._node_title(ada, ada["start"]) == "Saludo inicial" and editor._node_title(ada, "lugar").begins_with("«"), "títulos de tarjeta legibles")
	_check(editor.as_text(["a", "b"]) == "a\nb" and editor.as_text("x") == "x", "las frases en lista se editan una por línea")
	_check(not editor.search("constancia").is_empty(), "la búsqueda encuentra frases en toda la historia")
	_check(editor.data["prologue"].get("intro", []).size() > 3, "el editor carga los textos del prólogo")
	# El prólogo lee sus textos del archivo (con respaldo si faltan).
	PrologueText.reload()
	_check(PrologueText.text("prompts", "talk_rafa", "") != "" and PrologueText.text("hire", "no_existe", "respaldo") == "respaldo", "textos del prólogo desde data/prologue.json")
	editor.free()


func _zone_def(zone_id: String) -> Dictionary:
	for f in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(f).get("zones", []):
			if z["id"] == zone_id:
				return z
	return {}


func _test_roadmap2() -> void:
	var c := _new_character()
	c.set_level(30)
	# Cargas: se ganan hasta el máximo (3 + 1 cada 50 del atributo), dan sus bonos y se gastan.
	var crit_before := c.stats.get_value(Stat.CRIT_CHANCE)
	var max_oc := c.max_charges("overclock")
	_check(max_oc >= 3, "al menos 3 cargas de cada tipo (%d)" % max_oc)
	for k in max_oc + 2:
		c.gain_charge("overclock")
	_check(int(c.charges["overclock"]) == max_oc, "las cargas no pasan del máximo")
	_check(c.stats.total_multiplier(Stat.CRIT_CHANCE, []) > 1.0 + 0.3 * max_oc, "las cargas de Overclock dan probabilidad de crítico")
	_check(c.spend_charges("overclock") == max_oc and int(c.charges["overclock"]) == 0, "gastar devuelve cuántas había y las vacía")
	c.gain_charge("multihilo")
	c.tick_timed_effects(Charges.DURATION + 0.1)
	_check(int(c.charges["multihilo"]) == 0, "las cargas caducan a los %d s" % int(Charges.DURATION))
	var strong := _new_character()
	strong.set_level(30)
	strong.stats.set_base(Stat.STRENGTH, 0.0)
	strong.inventory.equipment.clear()
	var base_max := strong.max_charges("buffer")
	strong.add_timed_effect("prueba_fuerza", [Modifier.new(Stat.STRENGTH, Modifier.Type.FLAT, 100.0, [], "prueba")], 5.0)
	_check(strong.max_charges("buffer") >= base_max + 2, "cada 50 de Fuerza da una carga de Buffer más")
	# Costo de vida: la RAM pasa parte del maná a la vida.
	var rams: Dictionary = _db.skills.rams
	var skills: Dictionary = _db.skills.skills
	var b := Motherboard.new(skills["barrido"], 5, ["DDR4"])
	var cost0: float = SkillCalc.compute(b, c)["mana_cost"]
	b.install(RamModule.new(rams["alimentacion_por_vida"]), 0)
	var p := SkillCalc.compute(b, c)
	_check(p["life_cost"] > 0.0 and p["mana_cost"] < cost0, "Alimentación por Vida: parte del costo es vida (%d maná, %d vida)" % [p["mana_cost"], p["life_cost"]])
	var b2 := Motherboard.new(skills["barrido"], 5, ["DDR3"])
	b2.install(RamModule.new(rams["volcado_de_buffer"]), 0)
	_check(SkillCalc.compute(b2, c)["spend_charges"].has("buffer"), "Volcado de Buffer marca la habilidad para gastar cargas")
	_check(not RamModule.new(rams["hotfix_en_caliente"]).supports(skills["teleport_tcp"]), "pagar con vida no encaja en habilidades sin daño")
	# Requisitos de atributos: armas y armaduras de nivel alto piden su atributo.
	var axe := Item.new(_db.bases["hacha_de_guerra"], Rarity.Item.NORMAL, 20)
	var req := axe.attribute_requirements()
	_check(req.has("strength") and int(req["strength"]) >= 30, "el hacha de guerra pide Fuerza (%s)" % str(req))
	_check(Item.new(_db.bases["tunica_de_seda"], Rarity.Item.NORMAL, 1).attribute_requirements().is_empty(), "lo de nivel 1 no pide atributos")
	_check(Item.new(_db.bases["anillo_de_rubi"], Rarity.Item.NORMAL, 30).attribute_requirements().is_empty(), "la joyería no pide atributos")
	var weak := _new_character()
	weak.set_level(25)
	weak.stats.set_base(Stat.STRENGTH, 0.0)
	weak.recalculate()
	if weak.stats.get_value(Stat.STRENGTH) < float(req["strength"]):
		_check(not weak.can_equip(axe) and weak.missing_attributes(axe).has("strength"), "sin Fuerza suficiente no se equipa")
		weak.inventory.equipment["weapon"] = axe
		weak.recalculate()
		_check("weapon" in weak.disabled_equipment, "un arma equipada sin atributos queda desactivada")
	# Variantes: cambian el perfil desde su nivel de placa.
	var golem := Motherboard.new(skills["golem_hardware"], 12, [])
	var g0 := SkillCalc.compute(golem, c)
	_check(golem.cycle_variant() == "Clúster de tres", "el golem tiene la variante de tres a nivel 12")
	var g1 := SkillCalc.compute(golem, c)
	_check(g1["max_units"] == g0["max_units"] + 2 and g1["unit_life"] < g0["unit_life"], "Clúster de tres: más golems y menos vida cada uno")
	var saved := Item.from_dict(JSON.parse_string(JSON.stringify(golem.to_dict())), _db) as Motherboard
	_check(saved.variant == "trio", "la variante se guarda con la placa")
	var low := Motherboard.new(skills["golem_hardware"], 1, [])
	low.variant = "trio"
	_check(SkillCalc.compute(low, c)["max_units"] == g0["max_units"], "sin el nivel de placa la variante no aplica")
	var rafaga := Motherboard.new(skills["rafaga_de_paquetes"], 10, [])
	var r0: int = SkillCalc.compute(rafaga, c)["projectiles"]
	rafaga.cycle_variant()
	_check(SkillCalc.compute(rafaga, c)["projectiles"] == r0 + 3, "Broadcast: +3 proyectiles (variantes de variants.json)")
	# Invocación fuerte con varias habilidades.
	var titan := SkillCalc.compute(Motherboard.new(skills["mainframe_titan"], 1, []), c)
	_check(titan["unit_abilities"].size() == 3 and titan["max_units"] == 1, "Mainframe Titán: una invocación con 3 habilidades")
	_check(g0["unit_abilities"].size() == 1 and g0["unit_abilities"][0]["kind"] == "quake", "el golem ahora tiene terremoto")
	# Chips de expansión: solo cuentan con la ranura asignada; se guardan.
	var sockets := _tree.socket_ids()
	_check(sockets.size() >= 10, "ranuras de chip repartidas por el árbol (%d)" % sockets.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var chip := ExpansionChip.roll(30, rng)
	_check(not chip.fixed_mods.is_empty() and chip.display_name() != "", "un chip tiene mods y nombre")
	var cc := _new_character()
	var life0 := cc.stats.get_value(Stat.LIFE)
	var big := ExpansionChip.new(Rarity.Item.MAGIC, 10)
	big.fixed_mods.append({"stat": "life", "type": "flat", "value": 100})
	cc.inventory.bag[0] = big
	_check(cc.inventory.socket_chip(0, sockets[0]) and cc.inventory.bag[0] == null, "el chip pasa de la bolsa a la ranura")
	cc.recalculate()
	_check(is_equal_approx(cc.stats.get_value(Stat.LIFE), life0), "con la ranura sin asignar el chip no da nada")
	cc.passives._allocated[sockets[0]] = true
	cc.recalculate()
	_check(cc.stats.get_value(Stat.LIFE) > life0 + 50.0, "con la ranura asignada el chip suma sus mods")
	var inv2 := Inventory.new()
	inv2.load_dict(JSON.parse_string(JSON.stringify(cc.inventory.to_dict())), _db)
	_check(inv2.chips.has(sockets[0]) and inv2.chips[sockets[0]] is ExpansionChip, "los chips engastados se guardan")
	# Filtro de botín.
	var normal := Item.new(_db.bases["espada_oxidada"], Rarity.Item.NORMAL, 5)
	var magic := Item.new(_db.bases["espada_oxidada"], Rarity.Item.MAGIC, 5)
	var saved_rules: Dictionary = LootFilter.rules().duplicate()
	LootFilter.apply_preset("todo")
	_check(LootFilter.passes(normal), "con «Ver todo» se ve el equipo normal")
	LootFilter.apply_preset("equilibrado")
	_check(not LootFilter.passes(normal) and LootFilter.passes(magic), "«Equilibrado» oculta las armas normales")
	LootFilter.apply_preset("estricto")
	_check(not LootFilter.passes(magic) and LootFilter.passes(chip), "«Estricto» oculta también las mágicas; los chips se ven")
	LootFilter.set_rule("chip", "hidden")
	_check(not LootFilter.passes(chip), "una categoría se puede ocultar del todo")
	var uniq := Item.new(_db.bases["espada_oxidada"], Rarity.Item.UNIQUE, 5)
	_check(LootFilter.passes(uniq), "los únicos se ven siempre")
	LootFilter._rules = saved_rules.duplicate(true)   # tal como estaba (rarezas y reglas finas)
	LootFilter._save()


## Acto I más grande: "scale" agranda tamaño y posiciones, y las manadas crecen con el área.
func _test_zone_scale() -> void:
	var scaled := 0
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(path)["zones"]:
			if not z.has("scale"):
				_check(bool(z.get("safe", false)) or z.has("boss") or not z.has("enemies") or String(z["id"]) == "tutorial",
					"%s: las zonas de combate se agrandan (solo quedan igual campamentos, arenas de jefe y el tutorial)" % z["id"])
				continue
			scaled += 1
			_check_scaled_zone(z)
	_check(scaled >= 17, "zonas agrandadas en los tres actos (%d)" % scaled)
	# Suelos en pixel art de todos los estilos de los actos I a III.
	for style in ZoneArt.STYLES:
		_check(ZoneArt.has_ground(style) and ZoneArt.ground(style).get_width() == ZoneArt.SIZE, "suelo en pixel art: %s" % style)


func _check_scaled_zone(z: Dictionary) -> void:
	if true:
		var raw: Dictionary = z.duplicate(true)
		Zone.scale_def(z)
		var s := float(raw.get("scale", 1.0))
		_check(s >= 1.25, "%s: zona agrandada (×%.2f)" % [z["id"], s])
		_check(is_equal_approx(float(z["size"][0]), float(raw["size"][0]) * s), "%s: el tamaño crece" % z["id"])
		_check(is_equal_approx(float(z["exits"][0]["pos"][0]), float(raw["exits"][0]["pos"][0]) * s), "%s: las salidas se mueven con la zona" % z["id"])
		_check(int(z["enemies"]["packs"]) >= floori(int(raw["enemies"]["packs"]) * s * s),"%s: más manadas con el área (%d → %d)" % [z["id"], raw["enemies"]["packs"], z["enemies"]["packs"]])
		var area := Rect2(Vector2.ZERO, Vector2(z["size"][0], z["size"][1]))
		for e in z["exits"]:
			_check(area.has_point(Vector2(e["pos"][0], e["pos"][1])), "%s: salida dentro de la zona" % z["id"])
		for p in z.get("extra_points", []) + (z["mutex"]["positions"] if z.get("mutex") is Dictionary else []):
			_check(area.has_point(Vector2(p[0], p[1])), "%s: puntos especiales dentro de la zona" % z["id"])
		Zone.scale_def(z)
		_check(is_equal_approx(float(z["size"][0]), float(raw["size"][0]) * s), "%s: no se agranda dos veces" % z["id"])


func _test_ascendancy_rules() -> void:
	var c := _new_character()
	c.set_level(19)
	_check(not c.can_choose_ascendancy() and c.ascendancy_points_total() == 0, "sin ascendencia antes del nivel 20")
	c.set_level(20)
	_check(c.can_choose_ascendancy() and c.ascendancy_points_total() == 2, "al nivel 20 se elige y hay 2 puntos")
	var asc_id := StringName(c.class_def["ascendancies"][0]["id"])
	c.set_ascendancy(asc_id)
	var nodes: Array = c.ascendancy_def["passives"]
	_check(nodes.size() == 20, "la ascendencia tiene 20 nodos")
	_check(c.ascendancy_nodes.is_empty(), "al elegirla no hay pasivas asignadas")
	_check(not c.allocate_ascendancy_node(1), "un nodo suelto no se puede asignar (tiene que tocar el inicio o uno asignado)")
	_check(c.allocate_ascendancy_node(0) and c.allocate_ascendancy_node(1) and not c.allocate_ascendancy_node(2), "dos puntos al nivel 20, en camino")
	_check(not c.can_choose_ascendancy(), "la elección queda hecha")
	c.set_level(30)
	_check(c.ascendancy_points_total() == 4 and c.allocate_ascendancy_node(2) and c.allocate_ascendancy_node(5), "4 puntos al nivel 30")
	_check(not c.refund_ascendancy_node(1), "no se quita un nodo del que dependen otros")
	_check(c.refund_ascendancy_node(2) and c.ascendancy_points_available() == 1, "se quita el del final del camino")
	c.set_level(100)
	_check(c.ascendancy_points_total() == CharacterData.ASCENDANCY_MAX_POINTS and c.ascendancy_points_total() == 10, "como mucho 10 puntos")
	c.set_level(60)
	_check(c.ascendancy_points_total() == 10, "los 10 puntos al nivel 60")
	c.set_level(30)
	# Solo cuentan las pasivas asignadas.
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var loaded := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(loaded.ascendancy_nodes.size() == 3 and loaded.ascendancy_def.get("id", "") == String(asc_id), "ascendancia y pasivas guardadas")
	# Guardado con el árbol antiguo (3 pasivas): se devuelven los puntos.
	var old_save: Dictionary = data.duplicate(true)
	old_save.erase("ascendancy_tree_version")
	var old_char := CharacterData.from_dict(old_save, _classes[0], _tree, _db)
	_check(old_char.ascendancy_nodes.is_empty() and old_char.flags.has("ascendancy_refunded"), "guardado con el árbol antiguo: puntos devueltos")
	# Cada árbol: 20 nodos alcanzables, 8 notables (2 únicas con habilidad propia) y 10 puntos llegan a 2+ notables.
	for cdef in _classes:
		for a in cdef["ascendancies"]:
			var ns: Array = a["passives"]
			var all := range(ns.size())
			_check(ns.size() == 20 and AscendancyTree.connected(ns, all).size() == 20, "%s: 20 nodos, todos conectados al inicio" % a["id"])
			_check(ns.filter(func(n: Dictionary) -> bool: return n["kind"] == "unique").size() == 2 and ns.filter(func(n: Dictionary) -> bool: return n["kind"] == "notable").size() == 6,
				"%s: 6 notables y 2 únicas" % a["id"])
			var special := ns.filter(func(n: Dictionary) -> bool: return n["kind"] == "unique").any(func(n: Dictionary) -> bool:
				return n["mods"].any(func(md: Dictionary) -> bool: return md["stat"] in ["kill_explosion", "static_pulse", "retaliation_nova", "companion_robot"] + SIGNATURE_STATS))
			_check(special, "%s: una de sus únicas da una habilidad propia" % a["id"])
			# Forma propia: dentro del disco y sin nodos encimados.
			var closest := 9.0
			for i in ns.size():
				_check(Vector2(ns[i]["pos"]).length() <= 0.85, "%s: nodo %d dentro del disco" % [a["id"], i])
				closest = minf(closest, Vector2(ns[i]["pos"]).distance_to(AscendancyTree.START_POS))
				for j in range(i + 1, ns.size()):
					closest = minf(closest, Vector2(ns[i]["pos"]).distance_to(ns[j]["pos"]))
			_check(closest >= 0.13, "%s: nodos separados (mínimo %.2f)" % [a["id"], closest])
		var p0: Array = cdef["ascendancies"][0]["passives"].map(func(n: Dictionary) -> Vector2: return n["pos"])
		var p1: Array = cdef["ascendancies"][1]["passives"].map(func(n: Dictionary) -> Vector2: return n["pos"])
		_check(p0 != p1, "%s: sus dos ascendencias tienen árboles con forma distinta" % cdef["id"])
	# Habilidades únicas: el pulso de estática daña a los enemigos cercanos cada 3 s.
	_check(Stat.exists(Stat.STATIC_PULSE) and Stat.exists(Stat.KILL_EXPLOSION) and Stat.exists(Stat.RETALIATION_NOVA), "stats de habilidades únicas de ascendencia")
	# Guardado antiguo con ascendencia por debajo del nivel 20: se reinicia.
	data["level"] = 12
	var young := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(young.ascendancy_def.is_empty() and young.flags.has("ascendancy_reset"), "ascendencia anterior al nivel 20 reiniciada")
	# Nombres de puestos de trabajo coherentes (sin los descartados).
	var names := PackedStringArray()
	for cdef in _classes:
		names.append(cdef["name"])
		for a in cdef["ascendancies"]:
			names.append(a["name"])
	for banned in ["Hacker", "Desarrollador 10x", "Danzarina de Hilos", "Señor del Monolito", "Project Manager", "Administrador de Sistemas", "Release Manager"]:
		_check(not names.has(banned), "nombre descartado: %s" % banned)
	for wanted in ["Scrum Master", "Revisor de Código", "Tester QA", "Ingeniera de Prompts"]:
		_check(names.has(wanted), "falta el rol %s" % wanted)


func _test_board_milestones() -> void:
	var c := _new_character()
	var rafaga: Dictionary = _db.skills.skills["rafaga_de_paquetes"]
	var low := SkillCalc.compute(Motherboard.new(rafaga, 1, ["DDR4"]), c)
	var mid := SkillCalc.compute(Motherboard.new(rafaga, 10, ["DDR4"]), c)
	var high := SkillCalc.compute(Motherboard.new(rafaga, 30, ["DDR4"]), c)
	_check(mid["projectiles"] == low["projectiles"] + 1 and high["projectiles"] == low["projectiles"] + 3, "hitos: +1 proyectil a los niveles 10, 20 y 30")
	var deadlock: Dictionary = _db.skills.skills["deadlock"]
	var d1 := SkillCalc.compute(Motherboard.new(deadlock, 1, ["DDR3"]), c)
	var d20 := SkillCalc.compute(Motherboard.new(deadlock, 20, ["DDR3"]), c)
	_check(d20["radius"] > d1["radius"] and d20["cooldown"] < d1["cooldown"] and d20["stun"] > d1["stun"], "cada nivel mejora área, enfriamiento y duración")
	_check(SkillCalc.milestone_text(_db.skills.skills["proceso_hijo"]) == "+1 esbirro", "hito de esbirros")
	_check(SkillCalc.compute(Motherboard.new(_db.skills.skills["proceso_hijo"], 20, ["DDR5"]), c)["count"] == 4, "esbirros extra por nivel")


## Minas y trampas con detonación en cadena: al estallar una, las vecinas armadas
## estallan poco después (y así sigue), aunque ningún enemigo las pise.
func _test_chain_detonation() -> void:
	var c := CharacterData.new(_classes[4], _tree)
	var board := Motherboard.new(_db.skills.skills["fork_bomb"], 5, ["DDR5"])
	board.install(RamModule.new(_db.skills.rams["detonador_mina"]), 0)
	var p := SkillCalc.compute(board, c)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	var sc := SkillController.new()
	sc.player = pl
	sc.enemies = em
	sc.character = c
	for x in [100.0, 250.0, 400.0]:   # tres minas en fila, a 150 px una de otra
		sc._deploy(p, Vector2(x, 0))
	for d in sc._devices:
		d["armed_in"] = 0.0
	em.spawn(Vector2(105, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))   # solo pisa la primera
	sc._update_devices(0.0)
	_check(sc._devices.size() == 2 and sc._devices[0].has("chain_in"), "al estallar la primera, la vecina queda en cuenta atrás")
	_check(not sc._devices[1].has("chain_in"), "la que está lejos aún no")
	sc._update_devices(CHAIN_STEP)   # la cuenta atrás empieza al fotograma siguiente de marcarla
	_check(sc._devices.size() == 2, "no estalla en el mismo instante: la cadena se ve")
	sc._update_devices(CHAIN_STEP)
	_check(sc._devices.size() == 1 and sc._devices[0].has("chain_in"), "la cadena sigue: estalla la segunda y prende la tercera")
	sc._update_devices(CHAIN_STEP)
	sc._update_devices(CHAIN_STEP)
	_check(sc._devices.is_empty(), "y estalla la tercera, sin que ningún enemigo la pise")
	sc.free()
	pl.free()
	em.free()


## Gritos: potenciadores con etiqueta warcry que también mejoran a las invocaciones.
func _test_warcries() -> void:
	var shouts := ["esta_en_produccion", "daily_standup", "rollback_grito"]
	for id in shouts:
		var s: Dictionary = _db.skills.skills.get(id, {})
		_check(s.get("kind", "") == "buff" and "warcry" in s["tags"] and float(s["duration"]) > 0.0, "el grito %s es un potenciador con etiqueta grito" % id)
	var c := CharacterData.new(_classes[5], _tree)
	var daemon := Motherboard.new(_db.skills.skills["daemon_segundo_plano"], 5, [])
	var before := SkillCalc.compute(daemon, c)
	var pl := Player.new()
	pl.character = c
	var em := EnemyManager.new()
	var sc := SkillController.new()
	sc.player = pl
	sc.enemies = em
	sc.character = c
	var prod := SkillCalc.compute(Motherboard.new(_db.skills.skills["esta_en_produccion"], 1, []), c)
	sc._execute(prod, Vector2(50, 0))
	var after := SkillCalc.compute(daemon, c)
	_check(float(after["max_damage"]) > float(before["max_damage"]) * 1.25, "¡Está en producción! sube el daño de las invocaciones")
	_check(float(after["automaton_speed"]) > float(before["automaton_speed"]), "y su velocidad")
	_check(c.timed_effects.any(func(e: Dictionary) -> bool: return e["id"] == "skill:esta_en_produccion" and is_equal_approx(float(e["time_left"]), 6.0)), "dura 6 s")
	# ¡Rollback! cura a las invocaciones.
	sc._summon_unit(before, Vector2.ZERO, Color.WHITE)
	_check(sc._units.size() == 1, "hay una invocación para curar")
	if sc._units.size() == 1:
		sc._units[0]["life"] = float(sc._units[0]["max_life"]) * 0.5
		sc._execute(SkillCalc.compute(Motherboard.new(_db.skills.skills["rollback_grito"], 1, []), c), Vector2(50, 0))
		_check(is_equal_approx(float(sc._units[0]["life"]), float(sc._units[0]["max_life"]) * 0.8), "¡Rollback! cura un 30 %% a las invocaciones")
	_check(sc._effects.any(func(e: Dictionary) -> bool: return e["type"] == "ring" and float(e["radius"]) >= 170.0), "el grito se ve como una onda grande")
	sc.free()
	pl.free()
	em.free()


## Contenedor Docker: torreta que no caduca, reserva maná y lanza la habilidad sola.
func _test_docker_container() -> void:
	var c := CharacterData.new(_classes[4], _tree)
	var ram := RamModule.new(_db.skills.rams["contenedor_docker"])
	var board := Motherboard.new(_db.skills.skills["flamewar"], 5, ["DDR4"])
	var plain := SkillCalc.compute(board, c)
	_check(ram.supports(board.skill_def), "el contenedor funciona con Flamewar")
	_check(not ram.supports(_db.skills.skills["teleport_tcp"]) and not ram.supports(_db.skills.skills["bomba_logica"]) and not ram.supports(_db.skills.skills["daemon_segundo_plano"]),
		"ni con movimiento, ni con trampas, ni con invocaciones")
	board.install(ram, 0)
	var p := SkillCalc.compute(board, c)
	_check(p["deploy"] == "container" and p["tags"].has(&"totem") and p["tags"].has(&"persistent") and p["tags"].has(&"automaton"), "se despliega como contenedor: torreta persistente y autómata")
	_check(float(p["reserve"]) > 0.0 and float(p["max_damage"]) < float(plain["max_damage"]), "reserva maná y pega menos que la habilidad a mano")
	_check(" ".join(ram.effect_lines()).contains("contenedor"), "la RAM explica el contenedor")
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	var sc := SkillController.new()
	sc.player = pl
	sc.enemies = em
	sc.character = c
	sc._deploy(p, Vector2(100, 0))
	_check(sc._devices.size() == 1 and sc._devices[0]["kind"] == "container" and sc._devices[0]["life"] > 1.0e6, "el contenedor no caduca")
	_check(is_equal_approx(pl.mana_reserved, float(p["reserve"]) / 100.0), "reserva su maná mientras está en pie")
	sc._deploy(p, Vector2(200, 0))
	_check(sc._devices.size() == 1 and (sc._devices[0]["pos"] as Vector2).x > 150.0 and is_equal_approx(pl.mana_reserved, float(p["reserve"]) / 100.0),
		"relanzarla lo mueve (uno por habilidad, sin reservar dos veces)")
	sc._devices[0]["armed_in"] = 0.0
	em.spawn(Vector2(260, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	sc._update_devices(0.05)
	_check(float(sc._devices[0]["next_use"]) > 0.0, "dispara solo al enemigo cercano")
	sc._devices[0]["ally"]["life"] = 0.0
	sc._update_devices(0.05)
	_check(sc._devices.is_empty() and is_zero_approx(pl.mana_reserved), "si lo destruyen, libera el maná")
	sc.free()
	pl.free()
	em.free()


## Hechizos canalizados: mientras se mantiene la tecla, maná por segundo y golpes por tick.
func _test_channelled_spells() -> void:
	var c := CharacterData.new(_classes[5], _tree)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	var sc := SkillController.new()
	sc.player = pl
	sc.enemies = em
	sc.character = c
	for id in ["pipe_de_datos", "tormenta_tickets"]:
		_check(_db.skills.skills.has(id) and "channel" in _db.skills.skills[id]["tags"], "%s es canalizado" % id)
		_check(not RamModule.new(_db.skills.rams["servidor_torreta"]).supports(_db.skills.skills[id]) and not RamModule.new(_db.skills.rams["cron_job"]).supports(_db.skills.skills[id]),
			"%s no va en torreta ni con activación" % id)
	# Rayo: golpea en línea y cobra maná por segundo.
	var beam := SkillCalc.compute(Motherboard.new(_db.skills.skills["pipe_de_datos"], 5, []), c)
	em.spawn(Vector2(200, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var life0: float = em.lives[0]
	pl.mana = 100.0
	sc._start_channel(0, beam, Vector2(400, 0))
	sc._update_channel(0.05, true, Vector2(400, 0))
	_check(em.lives.size() == 0 or em.lives[0] < life0, "el rayo canalizado golpea lo que cruza")
	_check(is_equal_approx(pl.mana, 100.0 - float(beam["mana_cost"]) * 0.05), "cobra maná por segundo")
	_check(sc.is_channeling() and pl.action_lock > 0.0, "mientras canaliza no se mueve")
	sc._update_channel(0.05, false, Vector2(400, 0))
	_check(not sc.is_channeling(), "al soltar la tecla se corta")
	pl.mana = 0.0
	sc._start_channel(0, beam, Vector2(400, 0))
	sc._update_channel(0.05, true, Vector2(400, 0))
	_check(not sc.is_channeling(), "sin maná se corta")
	# Tormenta: crece con el tiempo y sigue al cursor.
	var storm := SkillCalc.compute(Motherboard.new(_db.skills.skills["tormenta_tickets"], 5, []), c)
	_check(is_equal_approx(SkillController.storm_radius(storm, SkillController.CHANNEL_RAMP), SkillController.storm_radius(storm, 0.0) * 3.0), "la tormenta llega al triple de tamaño")
	pl.mana = 1000.0
	sc._start_channel(1, storm, Vector2(100, 0))
	var start: Vector2 = sc._channel["center"]
	sc._update_channel(1.0, true, Vector2(100, 300))
	_check((sc._channel["center"] as Vector2).y > start.y and is_equal_approx(float(sc._channel["time"]), 1.0), "la tormenta sigue al cursor mientras crece")
	sc.free()
	pl.free()
	em.free()


## Variantes de auras, drones y trampas (variants.json).
func _test_more_variants() -> void:
	var c := CharacterData.new(_classes[5], _tree)
	var with_variant := func(id: String, variant: String) -> Array:
		var board := Motherboard.new(_db.skills.skills[id], 20, [])
		var base := SkillCalc.compute(board, c)
		board.variant = variant
		return [base, SkillCalc.compute(board, c)]
	# Todas las auras, los drones y la trampa tienen al menos una variante.
	for id in _db.skills.skills:
		var def: Dictionary = _db.skills.skills[id]
		if def["kind"] in ["aura", "drones", "trap"]:
			_check(not def.get("variants", []).is_empty(), "%s tiene variante" % id)
	var r: Array = with_variant.call("aura_blindaje", "blindaje_concentrado")
	_check(float(r[1]["aura_radius"]) < float(r[0]["aura_radius"]) and float(r[1]["aura_mods"][0]["value"]) > float(r[0]["aura_mods"][0]["value"]),
		"Blindaje concentrado: menos radio y más efecto")
	r = with_variant.call("aura_mando", "mando_ligero")
	_check(float(r[1]["reserve"]) < float(r[0]["reserve"]), "Mando ligero reserva menos maná")
	r = with_variant.call("aura_throttling", "rate_limit_agresivo")
	_check(float(r[1]["aura_enemy"]["slow"]) > float(r[0]["aura_enemy"]["slow"]), "Rate limit agresivo ralentiza más")
	r = with_variant.call("drones_vigilancia", "enjambre")
	_check(int(r[1]["drone_count"]) == int(r[0]["drone_count"]) + 2 and float(r[1]["max_damage"]) < float(r[0]["max_damage"]), "Enjambre: +2 drones que pegan menos")
	r = with_variant.call("bomba_logica", "bomba_racimo")
	_check(int(r[1]["max_active"]) == int(r[0]["max_active"]) + 3, "Bomba de racimo: +3 bombas a la vez")
	r = with_variant.call("bomba_logica", "detonacion_remota")
	_check(float(r[1]["trigger_radius"]) > float(r[0]["trigger_radius"]) * 1.9, "Detonación remota: se activa más lejos")


const SIGNATURE_STATS := ["fire_wall", "sprint_demo", "profiled_shot", "botnet", "blue_screen", "pager_strike", "blue_green"]


## Habilidades propias de clase: una por clase, en una única de una de sus
## ascendencias, y su daño escala con el del personaje (no solo con el nivel).
func _test_class_signatures() -> void:
	var seen := {}
	for cdef in _classes:
		var mine := []
		for a in cdef["ascendancies"]:
			for n in a["passives"]:
				for md in n["mods"]:
					if md["stat"] in SIGNATURE_STATS:
						_check(n["kind"] == "unique", "%s: %s va en una única" % [a["id"], md["stat"]])
						mine.append(md["stat"])
		_check(mine.size() == 1, "%s tiene una habilidad propia de clase (%s)" % [cdef["id"], str(mine)])
		for s in mine:
			_check(not seen.has(s), "%s y %s comparten %s" % [cdef["id"], seen.get(s, ""), s])
			seen[s] = cdef["id"]
	_check(seen.size() == SIGNATURE_STATS.size() and SkillController.SIGNATURES.size() == SIGNATURE_STATS.size(), "las siete habilidades propias se usan")
	for s in SIGNATURE_STATS:
		_check(Stat.exists(StringName(s)) and Stat.RULE_TEXT.has(StringName(s)), "%s tiene nombre y descripción" % s)
	var c := CharacterData.new(_classes[0], _tree)
	c.set_level(20)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	var sc := SkillController.new()
	sc.player = pl
	sc.enemies = em
	sc.character = c
	var d0 := sc.signature_damage(Stat.FIRE_WALL)
	c.stats.add_modifier(Modifier.new(Stat.FIRE_DAMAGE, Modifier.Type.INCREASED, 100.0))
	_check(d0 > 0.0 and is_equal_approx(sc.signature_damage(Stat.FIRE_WALL), d0 * 2.0), "escalan con el daño del personaje de su tipo")
	c.stats.add_modifier(Modifier.new(Stat.FIRE_WALL, Modifier.Type.FLAT, 1.0))
	sc._update_signatures(0.1)
	_check(sc._fire_walls.is_empty(), "sin enemigos cerca no se usa")
	em.spawn(Vector2(150, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	sc._update_signatures(0.1)
	_check(sc._fire_walls.size() == 1 and float(sc._sig_timers[Stat.FIRE_WALL]) > 6.0, "Muro de fuego: se levanta y espera su enfriamiento")
	em.spawn(Vector2(260, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.spawn(Vector2(370, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	sc._effects.clear()
	sc._fire_signature(Stat.BOTNET)
	_check(sc._effects.filter(func(e: Dictionary) -> bool: return e["type"] == "zap").size() >= 3, "Botnet salta entre varios enemigos")
	sc._fire_signature(Stat.SPRINT_DEMO)
	_check(c.timed_effects.any(func(e: Dictionary) -> bool: return e["id"] == "asc:sprint") and sc._sig_pending.size() == 1, "Sprint: acelera y deja la demo para el final")
	sc.free()
	pl.free()
	em.free()


## Chips únicos que transforman los nodos asignados de su radio (fuego → frío...).
func _test_transforming_chips() -> void:
	var own := func(c: CharacterData, stat: String) -> float:
		var b: Dictionary = c.stats.get_breakdown(StringName(stat))
		return float(b["flat"]) + float(b["increased"])
	var transforming := ExpansionChip.UNIQUES.filter(func(u: Dictionary) -> bool: return u.has("transform"))
	_check(transforming.size() >= 4, "hay chips únicos que transforman nodos (%d)" % transforming.size())
	for u in transforming:
		for from in u["transform"]:
			_check(Stat.exists(StringName(from)) and Stat.exists(StringName(u["transform"][from])), "%s: %s → %s son stats" % [u["id"], from, u["transform"][from]])
		# En alguna ranura hay un nodo que transformar (si no, el chip no sirve).
		var found := []
		for socket in _tree.socket_ids():
			var center: Vector2 = _tree.get_node_data(socket).position
			for id in _tree.nodes:
				var n: PassiveNode = _tree.nodes[id]
				if id != socket and n.position.distance_to(center) <= ExpansionChip.TRANSFORM_RADIUS and not n.is_mastery() \
						and n.mods.any(func(m: Modifier) -> bool: return u["transform"].has(String(m.stat))):
					found = [socket, id, n]
					break
			if not found.is_empty():
				break
		_check(not found.is_empty(), "%s: alguna ranura tiene nodos que transformar en su radio" % u["id"])
		if found.is_empty():
			continue
		var c := CharacterData.new(_classes[0], _tree)
		c.passives._allocated[found[0]] = true
		c.passives._allocated[found[1]] = true
		var m: Modifier = (found[2] as PassiveNode).mods.filter(func(x: Modifier) -> bool: return u["transform"].has(String(x.stat)))[0]
		var from_stat := String(m.stat)
		var to_stat: String = u["transform"][from_stat]
		c.recalculate(false)
		var from0: float = own.call(c, from_stat)
		var to0: float = own.call(c, to_stat)
		var chip := ExpansionChip.new(Rarity.Item.UNIQUE, 30)
		chip.unique_id = u["id"]
		chip.unique_def = u
		c.inventory.chips[found[0]] = chip
		c.recalculate(false)
		_check(is_equal_approx(own.call(c, from_stat), from0 - m.value) and is_equal_approx(own.call(c, to_stat), to0 + m.value),
			"%s: el nodo %d da %s en vez de %s" % [u["id"], found[1], to_stat, from_stat])
		_check(chip.transform_text().contains(u["transform_text"]), "%s explica lo que transforma" % u["id"])
		c.passives._allocated.erase(found[0])
		c.recalculate(false)
		var with_chip: float = own.call(c, from_stat)
		c.inventory.chips.erase(found[0])
		c.recalculate(false)
		_check(is_equal_approx(with_chip, own.call(c, from_stat)), "%s: sin la ranura asignada no transforma" % u["id"])


## Construcciones guardadas (árbol + barra) y comparador de placas.
func _test_builds_and_compare() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	c.set_level(20)
	var inv := c.inventory
	for i in Inventory.HOTBAR_SIZE:
		inv.boards[i] = null
	inv.boards[0] = Motherboard.new(_db.skills.skills["barrido"], 3, [])
	inv.boards[1] = Motherboard.new(_db.skills.skills["stack_overflow"], 2, [])
	var spare := Motherboard.new(_db.skills.skills["ping_letal"], 4, [])
	inv.bag[inv.free_bag_index()] = spare
	# Árbol A: dos nodos desde el inicio.
	var first: int = _tree.neighbors(c.passives.start_node_id)[0]
	c.passives.allocate_path(first, 5)
	_check(Builds.save(c, "A") == "", "se guarda una construcción")
	_check(Builds.save(c, "  ") != "", "sin nombre no se guarda")
	var saved_ids: Array = c.passives.get_allocated_ids()
	# Árbol y barra B.
	c.passives.reset()
	inv.boards[0] = spare
	inv.bag[inv.bag.find(spare)] = null
	inv.bag[inv.free_bag_index()] = Motherboard.new(_db.skills.skills["barrido"], 3, [])   # placeholder para que la A siga existiendo
	_check(Builds.save(c, "B") == "" and Builds.list(c).size() == 2, "dos construcciones guardadas")
	# Volver a la A: árbol y barra como estaban.
	var r := Builds.apply(c, Builds.list(c)[0])
	_check(r["error"] == "" and r["missing_skills"].is_empty(), "la A se carga sin problemas: %s" % str(r))
	_check(c.passives.get_allocated_ids().size() == saved_ids.size(), "el árbol vuelve a ser el de la A")
	_check(inv.boards[0].skill_def["id"] == "barrido" and inv.boards[1].skill_def["id"] == "stack_overflow", "la barra vuelve a ser la de la A")
	_check(inv.bag.any(func(b) -> bool: return b is Motherboard and b.skill_def["id"] == "ping_letal"), "la placa que sobra vuelve a la bolsa")
	# Placa que ya no tienes: se avisa y el resto se carga igual.
	var ghost := Builds.capture(c, "fantasma")
	ghost["hotbar"][2] = "fork_bomb"
	r = Builds.apply(c, ghost)
	_check(r["error"] == "" and r["missing_skills"] == ["fork_bomb"], "avisa de las placas que faltan")
	# Más puntos de los que tienes: no cambia nada.
	var big := Builds.capture(c, "grande")
	big["passives"] = range(100)
	_check(Builds.apply(c, big)["error"] != "" and c.passives.get_allocated_ids().size() == saved_ids.size(), "sin puntos suficientes no se carga")
	Builds.delete(c, "B")
	_check(Builds.list(c).size() == 1, "se borra")
	var loaded := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Builds.list(loaded).size() == 1 and Builds.list(loaded)[0]["name"] == "A", "las construcciones se guardan con el personaje")
	# Comparador: filas con el mejor marcado.
	var a := SkillCalc.compute(Motherboard.new(_db.skills.skills["barrido"], 10, []), c)
	var b := SkillCalc.compute(Motherboard.new(_db.skills.skills["barrido"], 1, []), c)
	var rows := Builds.compare_boards(a, b)
	var dps_row: Array = rows.filter(func(x: Dictionary) -> bool: return x["label"] == "DPS aproximado")
	_check(not dps_row.is_empty() and dps_row[0]["better"] == 0, "el comparador marca la placa de más nivel como mejor en DPS")
	_check(rows.any(func(x: Dictionary) -> bool: return x["label"] == "Área (radio)"), "y enseña el área")


## Acto IV (T28): zonas con camino bifurcado, estilos nuevos y enemigos con afijos innatos.
func _test_act4_world() -> void:
	var act4: Dictionary = DataLoader.load_json("res://data/act4.json")
	var zones := {}
	for z in act4.get("zones", []):
		zones[z["id"]] = z
	_check(act4.get("town", "") == "pila_cmos" and zones.has(act4.get("start_zone", "")) and zones["pila_cmos"].get("safe", false), "Acto IV: empieza en el POST y su hub es la Pila del CMOS")
	for style in ["setup", "vga16"]:
		_check(Zone.STYLES.has(style) and ZoneArt.has_ground(style), "estilo %s con suelo en pixel art" % style)
	# Bifurcación: el Menú Advanced lleva a dos caminos que vuelven a unirse en el Sector Oculto.
	var targets := func(id: String) -> Array:
		return zones[id]["exits"].map(func(e: Dictionary) -> String: return e["target"])
	_check(targets.call("menu_advanced").has("secuencia_arranque") and targets.call("menu_advanced").has("rom_video"), "el Menú Advanced se bifurca")
	_check(targets.call("secuencia_arranque").has("sector_oculto") and targets.call("rom_video").has("sector_oculto"), "los dos caminos llegan al Sector Oculto")
	_check(targets.call("sector_oculto").has("modo_smm"), "del Sector Oculto se llega a la arena del jefe")
	# El Acto III ya lleva al IV.
	var act3: Dictionary = DataLoader.load_json("res://data/act3.json")
	var camara: Dictionary = act3["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == "camara_flash")[0]
	_check(camara.get("exits", []).any(func(e: Dictionary) -> bool: return e["target"] == "post" and e.get("requires_flag", "") == "act3_complete"),
		"tras el reflasheo, la Cámara lleva al POST")
	var act_paths: Array = (load("res://scripts/autoload/game_data.gd") as GDScript).get_script_constant_map()["ACT_PATHS"]
	_check(act_paths.has("res://data/act4.json"), "el juego carga el Acto IV")
	# Enemigos nuevos: cada uno con su afijo innato, que no sale al azar en otros.
	var types := {}
	for t in _db_enemies():
		types[t["id"]] = t
	var defs := EnemyManager.affix_defs()
	for id in ["beep_code", "jumper_suelto", "pila_hinchada", "sector_defectuoso", "option_rom", "watchdog_timer"]:
		_check(types.has(id), "enemigo %s definido" % id)
		for aid in types.get(id, {}).get("innate_affixes", []):
			_check(defs.has(aid) and defs[aid].get("innate_only", false), "%s: su afijo innato %s existe y solo es suyo" % [id, aid])
		_check(not types.get(id, {}).get("innate_affixes", []).is_empty(), "%s tiene afijo propio" % id)
	var em := EnemyManager.new()
	em.roll_affixes = false
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("pila_hinchada"))
	_check(em.affixes_of(0).has("fuga_acido"), "una Pila Hinchada normal ya trae su Fuga de ácido")
	em.roll_affixes = true
	em.area_level = 60
	var leaked := false
	for k in 300:
		for aid in em._roll_affixes(Rarity.Enemy.ELITE):
			leaked = leaked or defs.get(aid, {}).get("innate_only", false)
	_check(not leaked, "los afijos innatos no salen al azar en las élites")
	em.free()


## Acto IV (T29): NPC del hub, misiones y la decisión sobre los huérfanos.
func _test_act4_story() -> void:
	var npcs: Dictionary = DataLoader.load_json("res://data/npcs.json")
	var quests: Dictionary = DataLoader.load_json("res://data/quests.json")["quests"]
	var act4: Dictionary = DataLoader.load_json("res://data/act4.json")
	var hub: Dictionary = act4["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == "pila_cmos")[0]
	var placed: Array = hub["npcs"].map(func(n: Dictionary) -> String: return n["id"])
	for id in ["berta", "rafa_bios", "mario_bios"]:
		_check(placed.has(id) and npcs["npcs"].has(id) and npcs["dialogues"].has(npcs["npcs"][id]["dialogue"]), "%s está en la Pila del CMOS con su diálogo" % id)
	_check(quests.has("main_act4") and quests["main_act4"].get("starts_after", "") == "main_act3" and quests["main_act4"].get("main", false),
		"la misión principal del Acto IV empieza al acabar la del III")
	var main_flags: Array = quests["main_act4"]["steps"].filter(func(s: Dictionary) -> bool: return s["type"] == "flag").map(func(s: Dictionary) -> String: return s["flag"])
	_check(main_flags.has("act4_huerfanos_decidido") and main_flags.has("act4_complete"), "la principal pide decidir sobre los huérfanos y cambiar la contraseña")
	# La decisión: dos caminos, cada uno con su bandera para el Acto V, y los dos la cierran.
	var rafa: Dictionary = npcs["dialogues"]["rafa_bios"]["nodes"]
	var choices: Array = rafa["huerfanos"]["options"].filter(func(o: Dictionary) -> bool: return o.has("action"))
	var flags: Array = choices.map(func(o: Dictionary) -> String: return o["action"]["flag"])
	_check(flags.has("act4_huerfanos_salvados") and flags.has("act4_huerfanos_purgados"), "Rafa ofrece salvar o purgar a los huérfanos")
	for o in choices:
		var closes: Array = rafa[o["next"]]["options"].filter(func(x: Dictionary) -> bool: return x.get("action", {}).get("flag", "") == "act4_huerfanos_decidido")
		_check(not closes.is_empty(), "elegir «%s» marca la decisión como tomada" % o["text"])
	var opener: Array = rafa["hola"]["options"].filter(func(o: Dictionary) -> bool: return o["next"] == "huerfanos")
	_check(not opener.is_empty() and opener[0].get("requires_flag", "") == "quest_rafa_libreta_done" and opener[0].get("hides_if_flag", "") == "act4_huerfanos_decidido",
		"la decisión se abre al entregar la libreta y no se repite")
	# Cada objeto de las misiones del acto está en alguna zona del Acto IV.
	var items := {}
	for z in act4["zones"]:
		for it in z.get("quest_items", []):
			items[it["id"]] = it["quest"]
	for qid in ["rafa_libreta", "paez_arranque", "berta_ajustes", "eugenio_cafe"]:
		for s in quests[qid]["steps"]:
			if s["type"] == "collect":
				for it in s.get("items", [s.get("item", "")]):
					_check(items.get(it, "") == qid, "%s: el objeto %s está en el Acto IV" % [qid, it])


## Acto IV (T30): admin/admin con tres fases, mecánica de arena por fase, música
## de fase, escenas y la contraseña que escribe el jugador (se guarda).
func _test_act4_boss() -> void:
	var act4: Dictionary = DataLoader.load_json("res://data/act4.json")
	var arena: Dictionary = act4["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == "modo_smm")[0]
	var boss: Dictionary = arena.get("boss", {})
	_check(boss.get("type", "") == "admin" and boss.get("complete_flag", "") == "act4_complete", "el Modo de Gestión del Sistema tiene a admin/admin")
	_check(arena.get("cutscene_on_enter", {}).get("id", "") == "admin_entrada", "escena de entrada del jefe")
	var phases: Array = boss.get("phases", [])
	_check(phases.size() == 2 and phases[0]["resist"].keys() != phases[1]["resist"].keys(), "tres fases con resistencias distintas")
	# Una mecánica de arena distinta en cada tramo de vida.
	var mech := func(life: float) -> Array:
		return boss["abilities"].filter(func(a: Dictionary) -> bool:
			return a["kind"] in ["safe_zones", "floor_break", "channel_adds"] and life >= float(a.get("min_life", 0.0)) and life <= float(a.get("max_life", 1.0))
		).map(func(a: Dictionary) -> String: return a["kind"])
	var m1: Array = mech.call(0.9)
	var m2: Array = mech.call(0.5)
	var m3: Array = mech.call(0.2)
	_check(m1 == ["safe_zones"] and m2 == ["floor_break"] and m3 == ["channel_adds"], "una mecánica de arena por fase: %s / %s / %s" % [m1, m2, m3])
	var music: Dictionary = DataLoader.load_json("res://data/music.json")
	_check(music["zones"].get("modo_smm", "") == "boss4" and music["tracks"].has("boss4_fase") and Sfx.audio_path("res://assets/audio/music/boss4_fase") != "", "música del jefe con versión de fase")
	# Escena final: el jugador escribe la contraseña y se guarda.
	var cs: Dictionary = DataLoader.load_json("res://data/cutscenes.json")["cutscenes"]
	_check(boss.get("death_cutscene", "") == "admin_cambia_password" and cs.has("admin_cambia_password") and cs.has("admin_entrada") and cs.has("bios_post"), "escenas del jefe y de llegada")
	var input_steps: Array = cs.get("admin_cambia_password", {}).get("steps", []).filter(func(s: Dictionary) -> bool: return s.has("input"))
	_check(input_steps.size() == 1 and input_steps[0].get("flag", "") == "admin_password", "la escena final pide la contraseña")
	_check(CutscenePlayer.password_problem("admin") != "" and CutscenePlayer.password_problem("abc") != "" and CutscenePlayer.password_problem("12345678") != "", "rechaza admin, las cortas y las fechas")
	_check(CutscenePlayer.password_problem("Lince-LinceCode") == "" and CutscenePlayer.password_problem("Ana2026xyz", "Ana") != "", "acepta una buena y no deja usar tu nombre")
	var c := CharacterData.new(_classes[0], _tree)
	var pl := Player.new()
	pl.character = c
	var cp := CutscenePlayer.new()
	cp.player = pl
	cp._steps = cs["admin_cambia_password"]["steps"]
	cp._save_input(input_steps[0], "Lince-LinceCode")
	_check(c.flags.get("admin_password", "") == "Lince-LinceCode", "la contraseña se guarda en el personaje")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(saved.flags.get("admin_password", "") == "Lince-LinceCode", "y sobrevive al guardado")
	c.flags.erase("admin_password")
	cp._default_inputs(0)
	_check(c.flags.get("admin_password", "") == CutscenePlayer.DEFAULT_PASSWORD and c.flags.has("admin_password_saltada"), "si se salta la escena, queda la contraseña por defecto")
	cp.free()
	pl.free()


## Eventos de zona nuevos (T31): bombas lógicas, escolta y comerciante ambulante.
func _test_new_zone_events() -> void:
	var catalog := ZoneMechanics.data()
	_check(ZoneEvents.KINDS.has("bombs") and ZoneEvents.KINDS.has("escort") and ZoneEvents.KINDS.has("merchant")
		and ZoneEvents.KINDS.all(func(k: String) -> bool: return catalog["main"].has(k) or catalog["minor"].has(k)),
		"tres eventos de zona nuevos, cada uno con su peso (principal o menor en zone_mechanics.json)")
	var ev := ZoneEvents.new()
	var results: Array = []
	var booms: Array = []
	var waves := [0]
	ev.resolved.connect(func(_e: Dictionary, ok: bool) -> void: results.append(ok))
	ev.exploded.connect(func(pos: Vector2) -> void: booms.append(pos))
	ev.escort_wave.connect(func(_e: Dictionary) -> void: waves[0] += 1)
	# Bombas: junto a una se desactiva; las que queden estallan al acabar el tiempo.
	var e := {"kind": "bombs", "pos": Vector2.ZERO, "state": "active", "time_left": 3.0,
		"bombs": [{"pos": Vector2.ZERO, "progress": 0.0, "done": false}, {"pos": Vector2(600, 0), "progress": 0.0, "done": false}]}
	for k in 16:
		ev._update_bombs(e, Vector2(10, 0), 0.1)
	_check(e["bombs"][0]["done"] and not e["bombs"][1]["done"] and results.is_empty(), "una bomba se desactiva quedándose a su lado")
	for k in 20:
		if e["state"] == "active":
			ev._update_bombs(e, Vector2(10, 0), 0.1)
	_check(booms == [Vector2(600, 0)] and results == [false], "la que no se desactivó estalla y el evento sale mal")
	results.clear()
	var e2 := {"kind": "bombs", "pos": Vector2.ZERO, "state": "active", "time_left": 10.0, "bombs": [{"pos": Vector2.ZERO, "progress": 0.0, "done": false}]}
	for k in 20:
		if e2["state"] == "active":
			ev._update_bombs(e2, Vector2.ZERO, 0.1)
	_check(results == [true], "desactivarlas todas a tiempo es un éxito")
	# Escolta: avanza solo contigo cerca y sin enemigos a su lado; dos emboscadas por el camino.
	var em := EnemyManager.new()
	em.roll_affixes = false
	ev.enemies = em
	results.clear()
	var es := {"kind": "escort", "pos": Vector2.ZERO, "state": "active", "start": Vector2.ZERO, "walker": Vector2.ZERO, "goal": Vector2(1000, 0), "waves_done": 0}
	ev._update_escort(es, Vector2(2000, 0), 1.0)
	_check(es["walker"] == Vector2.ZERO, "lejos de ti, el proceso no avanza")
	em.spawn(Vector2(50, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	ev._update_escort(es, Vector2.ZERO, 1.0)
	_check(es["walker"] == Vector2.ZERO and es.get("blocked", false), "con un enemigo al lado, se para")
	em.clear_all()
	for k in 40:
		if es["state"] == "active":
			ev._update_escort(es, es["walker"], 0.5)
	_check(results == [true] and waves[0] == 2, "llega a su salida tras dos emboscadas (%s, %d)" % [results, waves[0]])
	# Comerciante: el precio sube con el nivel de la zona.
	var z := Zone.new()
	z.def = {"level": 40}
	ev.zone = z
	_check(ev.merchant_price({}) > 100, "el comerciante cobra según el nivel de la zona")
	z.free()
	em.free()
	ev.free()


## Roles (T32): élites con rol en el nombre y el afijo Comandante.
func _test_roles_and_commander() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var elite := em.spawn(Vector2.ZERO, Rarity.Enemy.ELITE, em.type_index_of("bug"))
	em.set_role(elite, "healer")
	var ei := em.index_of(elite)
	_check(em.role_of(ei) == "healer" and em.names[ei].ends_with("(Sanador)"), "una élite puede tener rol y lo dice su nombre (%s)" % em.names[ei])
	var normal := em.spawn(Vector2(500, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.set_role(normal, "sniper")
	_check(not em.names[em.index_of(normal)].contains("("), "los normales con rol no cambian de nombre")
	# Comandante: los de alrededor pegan y corren más; él no se da el bono a sí mismo.
	var defs := EnemyManager.affix_defs()
	_check(defs.has("comandante") and defs["comandante"].has("commander") and not defs["comandante"].get("innate_only", false), "existe el afijo Comandante y sale en élites")
	var boss := em.spawn(Vector2(1000, 0), Rarity.Enemy.ELITE, em.type_index_of("bug"), "", 1.0, [], ["comandante"])
	var near := em.spawn(Vector2(1100, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var far := em.spawn(Vector2(2000, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em._update_commanders()
	_check(float(em.command_bonus(em.index_of(near))["damage"]) > 0.2 and float(em.command_bonus(em.index_of(near))["speed"]) > 0.1, "el de al lado recibe sus órdenes")
	_check(is_zero_approx(float(em.command_bonus(em.index_of(far))["damage"])) and is_zero_approx(float(em.command_bonus(em.index_of(boss))["damage"])), "ni el lejano ni él mismo")
	em.free()


## Enemigos que reaccionan a su estado (T33): pánico al quemarse, buscar al
## sanador con poca vida y agruparse con el comandante.
func _test_state_reactions() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	var a := em.index_of(em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, bug))
	var to_player := Vector2(200, 0)
	_check(em._react(a, em.traits[a], 0.1, to_player, 200.0) == null, "sin nada raro, sigue a lo suyo")
	# Pánico: quemado y con el pánico activo, huye del jugador.
	em.burn_time[a] = 3.0
	em.traits[a]["burn_seen"] = true
	em.traits[a]["panic"] = 1.0
	var flee: Variant = em._react(a, em.traits[a], 0.1, to_player, 200.0)
	_check(flee is Vector2 and (flee as Vector2).x < 0.0 and em.traits[a].get("react", "") == "panic", "quemado y en pánico, huye")
	em.burn_time[a] = 0.0
	em.traits[a].erase("panic")
	# Con poca vida busca al sanador.
	var h := em.spawn(Vector2(0, 400), Rarity.Enemy.NORMAL, bug)
	em.set_role(h, "healer")
	em.lives[a] = em.max_lives[a] * 0.2
	em._update_commanders()
	var go: Variant = em._react(a, em.traits[a], 0.1, to_player, 200.0)
	_check(go is Vector2 and (go as Vector2).y > 0.0 and em.traits[a].get("react", "") == "healer", "con poca vida va hacia el sanador")
	em.lives[a] = em.max_lives[a]
	# Sin estar peleando, se arrima al comandante.
	em.spawn(Vector2(-500, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["comandante"])
	em._update_commanders()
	var rally: Variant = em._react(a, em.traits[a], 0.1, Vector2(900, 0), 900.0)
	_check(rally is Vector2 and (rally as Vector2).x < 0.0 and em.traits[a].get("react", "") == "rally", "lejos del combate, se reagrupa con el comandante")
	_check(em._react(a, em.traits[a], 0.1, Vector2(150, 0), 150.0) == null, "si ya está peleando, no se va")
	# Los jefes no reaccionan.
	var boss := em.index_of(em.spawn(Vector2(3000, 0), Rarity.Enemy.UNIQUE, bug))
	em.burn_time[boss] = 3.0
	em.traits[boss]["panic"] = 1.0
	_check(em._react(boss, em.traits[boss], 0.1, to_player, 200.0) == null, "los jefes no entran en pánico")
	em.free()


## Lore coleccionable (T34): archivos por zonas de los cuatro actos y su registro.
func _test_lore_notes() -> void:
	var notes := LoreNotes.all()
	_check(notes.size() >= 16, "hay lore coleccionable (%d archivos)" % notes.size())
	var zone_ids := {}
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(path)["zones"]:
			zone_ids[z["id"]] = path
	var acts := {}
	var ids := {}
	for n in notes:
		_check(zone_ids.has(n["zone"]), "%s: su zona %s existe" % [n["id"], n["zone"]])
		_check(LoreNotes.KIND_NAMES.has(n["kind"]) and String(n["title"]) != "" and String(n["text"]) != "", "%s: tipo, título y texto" % n["id"])
		_check(float(n["at"][0]) > 0.05 and float(n["at"][0]) < 0.95 and float(n["at"][1]) > 0.05 and float(n["at"][1]) < 0.95, "%s: dentro de la zona" % n["id"])
		_check(not ids.has(n["id"]), "%s: id repetido" % n["id"])
		ids[n["id"]] = true
		acts[zone_ids.get(n["zone"], "")] = true
	_check(acts.size() == 4, "hay archivos en los cuatro actos")
	var c := CharacterData.new(_classes[0], _tree)
	c.character_name = "Ana"
	_check(LoreNotes.found(c).is_empty(), "al principio no has encontrado nada")
	_check(LoreNotes.mark_found(c, "log_constancia") and not LoreNotes.mark_found(c, "log_constancia"), "se apunta una sola vez")
	_check(LoreNotes.text_of(LoreNotes.found(c)[0], c).contains("Ana"), "{jugador} se cambia por tu nombre")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(LoreNotes.is_found(saved, "log_constancia"), "lo encontrado se guarda con el personaje")
	var log := LoreLog.new(c)
	_check(log._list.item_count == 1 and log.title.contains("1/"), "el registro lista lo encontrado")
	log.free()


## Diálogos con decisiones (T35): quién te acompaña y qué recompensa eliges.
func _test_dialogue_decisions() -> void:
	var dlg: Dictionary = DataLoader.load_json("res://data/npcs.json")["dialogues"]
	for id in Companions.DEFS:
		var nodes: Dictionary = dlg[id]["nodes"]
		var acts := []
		for node in nodes.values():
			for o in node.get("options", []):
				if o.get("action", {}).get("type", "") == "companion":
					acts.append(String(o["action"].get("npc", "")))
		_check(acts.has(id) and acts.has(""), "%s puede venir contigo y quedarse" % id)
	# Recompensas a elegir: dos opciones que comparten bandera (solo se da una).
	for pair in [["paez_bios", "arranque_entrega"], ["berta", "ajustes_entrega"]]:
		var opts: Array = dlg[pair[0]]["nodes"][pair[1]]["options"]
		var flags := opts.map(func(o: Dictionary) -> String: return String(o.get("action", {}).get("flag", "")))
		_check(opts.size() == 2 and flags[0] != "" and flags[0] == flags[1] and opts[0]["action"] != opts[1]["action"], "%s: se elige una de dos recompensas" % pair[0])
	# Acompañante: bono mientras está, uno a la vez, y se va al despedirlo.
	var c := CharacterData.new(_classes[0], _tree)
	var speed0 := c.stats.get_value(Stat.MOVEMENT_SPEED)
	Companions.choose(c, "mario_bios")
	_check(Companions.current(c) == "mario_bios" and c.flags.has("companion_mario_bios") and c.stats.get_value(Stat.MOVEMENT_SPEED) > speed0, "Mario te acompaña y corres más")
	Companions.choose(c, "paez_bios")
	_check(not c.flags.has("companion_mario_bios") and is_equal_approx(c.stats.get_value(Stat.MOVEMENT_SPEED), speed0), "uno a la vez: Mario se queda al venir Páez")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Companions.current(saved) == "paez_bios", "el acompañante se guarda")
	Companions.choose(c, "")
	_check(Companions.current(c) == "" and not c.timed_effects.any(func(e: Dictionary) -> bool: return String(e["id"]).begins_with("companion:")), "al despedirlo se va su bono")


## Campamento que evoluciona (T36): puesto de Aida, mesa de Mario y antena de Rafa,
## cada uno al terminar un acto.
func _test_camp_upgrades() -> void:
	var camp: Dictionary = DataLoader.load_json("res://data/act1.json")["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == "campamento")[0]
	var props := {}
	for p in camp.get("props", []):
		props[p["kind"]] = p.get("requires_flag", "")
	_check(props.get("camp_stall", "") == "act1_complete" and props.get("camp_workbench", "") == "act2_complete" and props.get("camp_antenna", "") == "act3_complete",
		"el campamento crece al acabar cada acto: %s" % str(props))
	var dlg: Dictionary = DataLoader.load_json("res://data/npcs.json")["dialogues"]
	for entry in [["ada", "puesto", "act1_complete", "open_gear_shop"], ["kevin", "mesa", "act2_complete", "reforge_weapon"], ["root", "antena", "act3_complete", "antenna"]]:
		var opener: Array = dlg[entry[0]]["nodes"]["hola"]["options"].filter(func(o: Dictionary) -> bool: return o["next"] == entry[1])
		_check(not opener.is_empty() and opener[0].get("requires_flag", "") == entry[2], "%s: la mejora se abre con %s" % [entry[0], entry[2]])
		var acts: Array = dlg[entry[0]]["nodes"][entry[1]]["options"].map(func(o: Dictionary) -> String: return String(o.get("action", {}).get("type", "")))
		_check(acts.has(entry[3]), "%s: su mejora hace %s" % [entry[0], entry[3]])
	var gen := ItemGenerator.new(_db)
	var stock := Economy.generate_gear_stock(gen, 20)
	_check(stock.size() >= Economy.GEAR_STOCK_RARE + Economy.GEAR_STOCK_MAGIC and stock.any(func(it: Item) -> bool: return it.rarity == Rarity.Item.RARE),
		"el puesto de Aida vende equipo raro y mágico")
	var weapon := gen.generate(20, Rarity.Item.RARE, "espada_oxidada")
	_check(Economy.can_reforge(weapon) and Economy.reforge_price(weapon) > 0, "un arma rara se puede reforjar y tiene precio")
	_check(not Economy.can_reforge(gen.generate(20, Rarity.Item.UNIQUE)), "los únicos no se reforjan")


## Némesis (T37): el élite que te mató vuelve con tu nombre, más fuerte, y al
## vencerlo se olvida.
func _test_nemesis() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var elite := em.index_of(em.spawn(Vector2.ZERO, Rarity.Enemy.ELITE, em.type_index_of("bug"), "Bug corrupto", 1.0, [], ["veloz"]))
	em._note_hitter(elite)
	var hit := em.last_hitter
	_check(hit["rarity"] == Rarity.Enemy.ELITE and hit["type"] == "bug" and hit["affixes"].has("veloz"), "se recuerda quién te golpeó")
	var c := CharacterData.new(_classes[0], _tree)
	c.character_name = "Ana"
	var now := int(hit["time"])
	_check(not Nemesis.record(c, hit, "zona2", "act1", now + 10000), "un golpe viejo no cuenta")
	var normal := em.index_of(em.spawn(Vector2(300, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	em._note_hitter(normal)
	_check(not Nemesis.record(c, em.last_hitter, "zona2", "act1", now), "un normal no se vuelve némesis")
	_check(Nemesis.record(c, hit, "zona2", "act1", now), "el élite que te mató se vuelve tu némesis")
	_check(Nemesis.title(c).contains("Ana") and Nemesis.title(c).contains("Bug corrupto"), "lleva tu nombre: %s" % Nemesis.title(c))
	var life1 := Nemesis.life_mult(c)
	_check(Nemesis.should_spawn(c, "zona2", "act1", 0.99) and not Nemesis.should_spawn(c, "zona3", "act1", 0.99) and Nemesis.should_spawn(c, "zona3", "act1", 0.1),
		"vuelve seguro donde te mató y a veces en el resto del acto")
	_check(not Nemesis.should_spawn(c, "fabrica", "act2", 0.0), "no sale en otros actos")
	var again := hit.duplicate()
	again["nemesis"] = true
	Nemesis.record(c, again, "zona2", "act1", now)
	_check(int(Nemesis.current(c)["kills"]) == 2 and Nemesis.life_mult(c) > life1 and Nemesis.title(c).contains("×2"), "si te vuelve a matar, es más fuerte")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(not Nemesis.current(saved).is_empty(), "el némesis se guarda")
	# Al matarlo se avisa (para el botín) y se olvida.
	var fired := [false]
	em.nemesis_killed.connect(func(_p: Vector2) -> void: fired[0] = true)
	em.traits[elite]["nemesis"] = true
	em._kill(elite)
	_check(fired[0], "al caer el némesis se avisa para soltar su botín")
	Nemesis.defeated(c)
	_check(Nemesis.current(c).is_empty() and int(c.flags.get("stat_nemesis", 0)) == 1, "vencido, se olvida")
	em.free()


## Crafteo con parches (T38): rehacer, añadir, subir rareza y fijar un afijo.
func _test_crafting_patches() -> void:
	var gen := ItemGenerator.new(_db, 7)
	var c := CharacterData.new(_classes[0], _tree)
	c.set_level(30)
	var item := gen.generate(30, Rarity.Item.NORMAL, "espada_oxidada")
	_check(Crafting.apply(c, item, "major", gen) != "", "sin parches no se puede")
	for k in Crafting.KINDS:
		Crafting.add(c, k, 5)
	_check(Crafting.apply(c, item, "refactor", gen) != "", "un objeto normal no tiene afijos que rehacer")
	_check(Crafting.apply(c, item, "major", gen) == "" and item.rarity == Rarity.Item.MAGIC and item.affixes.size() >= 1 and Crafting.count(c, "major") == 4,
		"versión mayor: de normal a mágico (y gasta el parche)")
	_check(Crafting.apply(c, item, "major", gen) == "" and item.rarity == Rarity.Item.RARE and item.affixes.size() >= 3 and item.rare_name != "",
		"y de mágico a raro, conservando lo que tenía")
	var before := item.affixes.size()
	if before < 6:
		_check(Crafting.apply(c, item, "feature", gen) == "" and item.affixes.size() == before + 1, "feature: un afijo más")
	Crafting.add(c, "feature", 10)
	while item.affixes.size() < 6 and Crafting.apply(c, item, "feature", gen) == "":
		pass
	var left := Crafting.count(c, "feature")
	_check(Crafting.apply(c, item, "feature", gen) != "" and Crafting.count(c, "feature") == left, "lleno, no se añaden más afijos y el parche no se gasta")
	# Hotfix: el afijo fijado sobrevive al refactor y luego se suelta.
	var fixed: Dictionary = item.affixes[1].duplicate()
	_check(Crafting.apply(c, item, "hotfix", gen, 1) == "" and item.affixes[1].get("locked", false), "hotfix: fija el afijo elegido")
	_check(Crafting.apply(c, item, "refactor", gen) == "", "refactor con un afijo fijado")
	var survived := item.affixes.filter(func(a: Dictionary) -> bool: return a["affix_id"] == fixed["affix_id"] and is_equal_approx(float(a["value"]), float(fixed["value"])))
	_check(survived.size() == 1 and not survived[0].get("locked", false), "el fijado sobrevive al refactor y deja de estar fijado")
	var groups := {}
	var dup := false
	for a in item.affixes:
		dup = dup or groups.has(a["affix_id"])
		groups[a["affix_id"]] = true
	_check(not dup and item.affixes.size() >= 3 and item.affixes.size() <= 6, "el refactor no repite afijos y respeta la rareza")
	_check(not Crafting.craftable(gen.generate(30, Rarity.Item.UNIQUE)), "los únicos no se craftean")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var drops := 0
	for k in 200:
		if Crafting.roll_drop(Rarity.Enemy.UNIQUE, rng) != "":
			drops += 1
	_check(drops > 80 and Crafting.roll_drop(Rarity.Enemy.NORMAL, rng) == "", "los únicos sueltan parches a menudo; los normales, nunca")
	c.tokens = 0
	_check(not Crafting.buy(c, "refactor"), "sin fichas no se compran")
	c.add_tokens(1000)
	var had := Crafting.count(c, "refactor")
	_check(Crafting.buy(c, "refactor") and Crafting.count(c, "refactor") == had + 1, "Mario los vende por fichas")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Crafting.count(saved, "refactor") == had + 1, "los parches se guardan")
	var panel := CraftingPanel.new(c, gen)
	_check(panel._rows.get_child_count() == Crafting.KINDS.size(), "la mesa muestra los cuatro parches")
	panel.free()


## Atlas de incidentes, parte 1 (T39): zona al azar con modificadores y más botín.
func _test_incidents() -> void:
	var zones := {}
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act["zones"]:
			z["act"] = act["id"]
			Zone.scale_def(z)
			zones[z["id"]] = z
	var low := Incidents.candidates(zones, 5)
	_check(not low.is_empty() and low.all(func(z: Dictionary) -> bool: return int(z["level"]) <= 8 and not z.get("safe", false) and not z.has("boss")),
		"a nivel 5 solo salen zonas de combate que ya puedes jugar")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var def := Incidents.build(zones, 30, "campamento", rng, 3)
	_check(def["id"] == Incidents.ZONE_ID and int(def["level"]) >= 30 and def["incident"]["mods"].size() == 3, "incidente de tu nivel con tres modificadores")
	_check(float(def["drop_multiplier"]) > 1.5, "a cambio de más botín (×%.2f)" % float(def["drop_multiplier"]))
	_check(def["exits"].size() == 1 and def["exits"][0]["target"] == "campamento" and not def.has("boss") and not def.has("quest_items"), "solo tiene la salida al campamento y nada de misiones")
	var src: Dictionary = zones[def["incident"]["from"]]
	_check(src["id"] != Incidents.ZONE_ID and zones[src["id"]].get("name", "") == src.get("name", ""), "no cambia la zona original")
	# Cada modificador hace algo.
	var dense := Incidents.build(zones, 30, "campamento", rng, 7)   # todos
	_check(int(dense["enemies"]["packs"]) > int(zones[dense["incident"]["from"]]["enemies"]["packs"]), "Pico de tráfico: más grupos")
	_check(Incidents.forced_affixes(dense).has("explosivo") and Incidents.forced_affixes(dense).has("veloz"), "afijos que llevan todos los enemigos")
	_check(Incidents.player_mods(dense).size() >= 5, "mods para el jugador (sin regeneración, resistencias)")
	var em := EnemyManager.new()
	em.roll_affixes = false
	em.forced_affixes = ["explosivo"]
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	_check(em.affixes_of(0).has("explosivo"), "en un incidente con zombis, hasta los normales explotan")
	em.free()
	var zone := Zone.new()
	zone.setup(def, null, null)
	_check(zone.rect.size.x > 0 and zone.entry_point("") != Vector2.ZERO, "la zona del incidente se arma")
	zone.free()
	_check(Incidents.describe(def).count("\n") == 2, "se explican sus modificadores")


## Atlas de incidentes, parte 2 (T40): progresión por zonas completadas y mapas.
func _test_atlas() -> void:
	var zones := {}
	for path in ["res://data/act1.json", "res://data/act2.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act["zones"]:
			z["act"] = act["id"]
			zones[z["id"]] = z
	var c := CharacterData.new(_classes[0], _tree)
	c.set_level(20)
	_check(Atlas.tier(c) == 1 and Atlas.level_bonus(c) == 0 and is_zero_approx(Atlas.loot_bonus(c)), "el atlas empieza en nivel 1")
	_check(not Atlas.mark_done(c, "zona1") and not Atlas.mark_done(c, "zona1") and Atlas.done(c).size() == 1, "completar la misma zona dos veces cuenta una")
	Atlas.mark_done(c, "zona2")
	_check(Atlas.mark_done(c, "zona3") and Atlas.tier(c) == 2 and Atlas.level_bonus(c) == Atlas.LEVEL_PER_TIER, "tres zonas distintas suben el nivel del atlas")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var m := Atlas.roll_map(zones, 20, 3, rng)
	_check(zones.has(m["zone"]) and m["mods"].size() == 3 and String(m["name"]).begins_with("Mapa"), "un mapa: zona válida y tres modificadores desde el nivel 3")
	for k in Atlas.MAX_MAPS:
		Atlas.add_map(c, m)
	_check(not Atlas.add_map(c, m) and Atlas.maps(c).size() == Atlas.MAX_MAPS, "caben %d mapas" % Atlas.MAX_MAPS)
	var taken := Atlas.take_map(c, 0)
	_check(taken["zone"] == m["zone"] and Atlas.maps(c).size() == Atlas.MAX_MAPS - 1, "abrir un mapa lo gasta")
	# El incidente de un mapa usa su zona y sus modificadores, y el nivel del atlas.
	var def := Incidents.build(zones, 20, "campamento", rng, -1, taken["zone"], taken["mods"], Atlas.level_bonus(c), Atlas.loot_bonus(c))
	_check(def["incident"]["from"] == taken["zone"] and def["incident"]["mods"] == taken["mods"], "el incidente del mapa es el del mapa")
	_check(int(def["level"]) >= 20 + Atlas.LEVEL_PER_TIER, "con el nivel del atlas sube la dificultad")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Atlas.tier(saved) == 2 and Atlas.maps(saved).size() == Atlas.MAX_MAPS - 1, "el atlas se guarda con el personaje")


## Dificultades (T41): Normal, Pesadilla e Infierno, con desbloqueo y efectos.
func _test_difficulties() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	_check(Difficulty.current(c) == 0 and Difficulty.unlocked(c) == 0 and not Difficulty.choose(c, 1), "al principio solo hay Normal")
	c.flags["act4_complete"] = true
	_check(Difficulty.unlocked(c) == 1 and Difficulty.choose(c, 1) and Difficulty.current(c) == 1 and not Difficulty.choose(c, 2), "tras el Acto IV se abre Pesadilla, no Infierno")
	_check(Difficulty.boss_flag("act4_complete", 1) == "act4_complete_d1" and Difficulty.boss_flag("act1_complete", 0) == "act1_complete", "cada dificultad tiene su bandera de jefe")
	c.flags[Difficulty.boss_flag("act4_complete", 1)] = true
	_check(Difficulty.unlocked(c) == 2 and Difficulty.choose(c, 2), "terminar el Acto IV en Pesadilla abre Infierno")
	_check(Difficulty.LEVEL_BONUS[2] > Difficulty.LEVEL_BONUS[1] and Difficulty.LOOT[2] > Difficulty.LOOT[1] and Difficulty.describe(2).contains("Infierno"), "cada dificultad sube nivel y botín")
	# Enemigos: más resistencias y más afijos.
	var em := EnemyManager.new()
	em.roll_affixes = false
	var base := em.index_of(em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	var r0 := em.resist_of(base, "fire")
	em.difficulty = 2
	var hard := em.index_of(em.spawn(Vector2(300, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	_check(em.resist_of(hard, "fire") >= r0 + 39.0, "en Infierno los enemigos resisten más (%d → %d)" % [r0, em.resist_of(hard, "fire")])
	em.roll_affixes = true
	em.area_level = 60
	var counts := {}
	for k in 30:
		counts[em._roll_affixes(Rarity.Enemy.ELITE).size()] = true
	_check(counts.keys().max() >= 4, "los élites de Infierno salen con más afijos (%s)" % str(counts.keys()))
	em.free()
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Difficulty.current(saved) == 2, "la dificultad se guarda")


## Escalado opcional del nivel de zona (T42): las zonas de actos terminados suben a tu nivel.
func _test_zone_scaling() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	c.set_level(40)
	_check(Difficulty.zone_level(c, 5, "act1", false) == 5, "sin la opción, la zona tiene su nivel")
	c.flags[Difficulty.SCALING_FLAG] = true
	_check(Difficulty.zone_level(c, 5, "act1", false) == 5, "con la opción, pero sin terminar el acto, tampoco cambia")
	c.flags["act1_complete"] = true
	_check(Difficulty.zone_level(c, 5, "act1", false) == 40, "acto terminado y opción activa: la zona sube a tu nivel")
	_check(Difficulty.zone_level(c, 50, "act1", false) == 50, "nunca baja una zona de más nivel que tú")
	_check(Difficulty.zone_level(c, 1, "act1", true) == 1, "los campamentos no cambian")
	c.flags["act4_complete"] = true
	Difficulty.choose(c, 1)
	_check(Difficulty.zone_level(c, 5, "act1", false) == 40 + Difficulty.LEVEL_BONUS[1], "se suma con la dificultad")


## Misiones secundarias con recompensas (T43): placas de invocación y auras, RAM de grado mayor.
func _test_side_quest_rewards() -> void:
	var quests: Dictionary = DataLoader.load_json("res://data/quests.json")["quests"]
	var boards := 0
	var majors := 0
	for id in quests:
		var q: Dictionary = quests[id]
		for r in q.get("rewards", []):
			if r.get("type", "") != "give_item":
				continue
			if r.get("kind", "") == "motherboard":
				_check(_db.skills.skills.has(r["id"]), "%s: la placa %s existe" % [id, r["id"]])
				var def: Dictionary = _db.skills.skills.get(r["id"], {})
				if def.get("kind", "") in ["unit", "minion", "aura", "drones"]:
					boards += 1
			else:
				_check(_db.skills.rams.has(r["id"]), "%s: la RAM %s existe" % [id, r["id"]])
				if String(r["id"]).ends_with("_mayor"):
					majors += 1
	_check(boards >= 6 and majors >= 4, "recompensas de invocación/aura (%d) y RAM de grado mayor (%d)" % [boards, majors])
	var text := QuestLog.reward_text(quests["paez_kindle"], _db.skills)
	_check(text.contains("RAM «") and text.contains("punto de pasiva") and text.contains("experiencia"), "las recompensas se explican: %s" % text)
	_check(QuestLog.reward_text(quests["iris_cables"], _db.skills).contains("placa «Proceso Hijo»"), "con el nombre de la placa")


## Más únicos y conjuntos (T44): con estados, auras, espinas, autómatas, cargas y terrenos.
func _test_more_uniques_and_sets() -> void:
	_check(_db.uniques.size() >= 14 and _db.sets.size() >= 4, "hay más únicos (%d) y conjuntos (%d)" % [_db.uniques.size(), _db.sets.size()])
	var valid_stat := func(s: String) -> bool: return Stat.exists(StringName(s)) or ItemDatabase.is_local(s)
	var themes := {"estados": ["burn_chance", "shock_chance", "poison_chance"], "auras": ["aura_effect"], "espinas": ["thorns"],
		"autómatas": ["automaton_speed", "extra_devices"], "cargas": ["max_buffer_charges", "max_multihilo_charges"], "terrenos": ["skill_duration"]}
	var seen := {}
	for u in _db.uniques:
		_check(_db.bases.has(u["base"]), "%s: su base %s existe" % [u["id"], u["base"]])
		for m in u["mods"]:
			_check(valid_stat.call(String(m["stat"])), "%s: stat %s" % [u["id"], m["stat"]])
			for t in themes:
				if themes[t].has(String(m["stat"])):
					seen[t] = true
	for s in _db.sets.values():
		for p in s["pieces"]:
			_check(_db.bases.has(p["base"]), "%s: base %s" % [p["id"], p["base"]])
			for m in p["mods"]:
				_check(valid_stat.call(String(m["stat"])), "%s: stat %s" % [p["id"], m["stat"]])
		for n in s["bonuses"]:
			for m in s["bonuses"][n]:
				_check(valid_stat.call(String(m["stat"])), "%s (%s piezas): stat %s" % [s["id"], n, m["stat"]])
	_check(seen.size() == themes.size(), "hay únicos de estados, auras, espinas, autómatas, cargas y terrenos: %s" % str(seen.keys()))
	# Equipar uno se nota en las stats.
	var gen := ItemGenerator.new(_db)
	var c := CharacterData.new(_classes[0], _tree)
	var thorns0 := c.stats.get_value(Stat.THORNS)
	c.inventory.set_equipped("body", gen.make_unique(_db.get_unique("chaleco_cactus_ssl"), 20))
	c.recalculate()
	_check(c.stats.get_value(Stat.THORNS) >= thorns0 + 35.0, "el Chaleco Certificado SSL da espinas")


## Logros con cosméticos (T45): se cumplen con banderas y contadores, y dan sombreros, auras y pisadas.
func _test_achievements() -> void:
	var slots_seen := {}
	var ids := {}
	for def in Achievements.DEFS:
		_check(not ids.has(def["id"]), "logro repetido: %s" % def["id"])
		ids[def["id"]] = true
		_check(Achievements.COSMETICS.get(def["reward"][0], {}).has(def["reward"][1]), "%s: su premio existe" % def["id"])
		slots_seen[def["reward"][0]] = true
	_check(slots_seen.size() == 3 and Achievements.DEFS.size() >= 10, "logros con sombreros, auras y pisadas")
	var c := CharacterData.new(_classes[0], _tree)
	_check(Achievements.check(c).is_empty(), "un personaje nuevo no tiene logros")
	c.flags["stat_kills"] = 1
	c.flags["act1_complete"] = true
	var fresh := Achievements.check(c)
	_check(fresh.size() == 2 and Achievements.check(c).is_empty(), "se consiguen una sola vez (%d)" % fresh.size())
	_check(Achievements.available(c, "hat").size() == 2 and Achievements.available(c, "aura").is_empty(), "dan sus cosméticos")
	_check(not Achievements.equip(c, "aura", "dorada") and Achievements.equip(c, "hat", "casco_obra") and Achievements.equipped(c, "hat") == "casco_obra",
		"solo te pones lo que tienes")
	for k in 9:
		LoreNotes.mark_found(c, LoreNotes.all()[k]["id"])
	_check(Achievements.check(c).any(func(d: Dictionary) -> bool: return d["id"] == "archivista"), "el de lore se cumple con 9 archivos")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Achievements.equipped(saved, "hat") == "casco_obra" and Achievements.unlocked_ids(saved).size() == 3, "logros y cosméticos se guardan")
	var panel := AchievementsPanel.new(c)
	panel.free()


## Banco de oleadas sin fin y ladder local (T46).
func _test_ladder() -> void:
	var zones := {}
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act["zones"]:
			z["act"] = act["id"]
			Zone.scale_def(z)
			zones[z["id"]] = z
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var def := Ladder.build_arena(zones, 20, "campamento", rng)
	_check(def["id"] == Ladder.ZONE_ID and int(def["enemies"]["packs"]) == 0 and not def["enemies"].get("types", []).is_empty(),
		"la arena es una zona vacía que sabe qué enemigos soltar")
	_check(def["exits"].size() == 1 and def["exits"][0]["target"] == "campamento" and not def.has("npcs") and not def.has("challenges"), "solo la salida al campamento")
	_check(int(zones[def["waves_mode"]["from"]]["enemies"].get("packs", 0)) > 0, "no vacía la zona original")
	var w1 := Ladder.wave_plan(1)
	var w10 := Ladder.wave_plan(10)
	_check(int(w10["count"]) > int(w1["count"]) and float(w10["special_chance"]) > float(w1["special_chance"]) and int(w10["elites"]) > int(w1["elites"]),
		"las oleadas crecen")
	_check(not w1["boss"] and Ladder.wave_plan(5)["boss"] and int(w10["level_bonus"]) == 2 and int(Ladder.wave_plan(500)["count"]) == Ladder.MAX_COUNT,
		"jefe cada 5, nivel que sube y un tope de enemigos")
	_check(Ladder.boss_life_mult(10) > Ladder.boss_life_mult(5), "cada jefe de oleada aguanta más")
	# Récords del personaje.
	var c := CharacterData.new(_classes[0], _tree)
	_check(not Ladder.record_waves(c, 0, 10.0) and Ladder.record_waves(c, 6, 300.0), "una partida con oleadas es récord")
	_check(not Ladder.record_waves(c, 5, 100.0) and Ladder.record_waves(c, 6, 250.0) and not Ladder.record_waves(c, 6, 260.0),
		"récord: más oleadas, o las mismas en menos tiempo")
	_check(Ladder.record_boss(c, "daemon", 90.0) and not Ladder.record_boss(c, "daemon", 95.0) and Ladder.record_boss(c, "daemon", 80.0), "récord de jefe: menos tiempo")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(int(Ladder.personal(saved)["best_wave"]) == 6 and float(Ladder.personal(saved)["bosses"]["daemon"]) == 80.0, "los récords se guardan")
	# Tabla local: top ordenado, guardado y cargado.
	var path := "user://test_ladder.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var board := Ladder.load_board(path)
	_check(board["waves"].is_empty() and board["bosses"].is_empty(), "tabla vacía sin archivo")
	for k in Ladder.TOP_SIZE:
		Ladder.submit_waves(board, Ladder.entry(c, 3 + k, 100.0))
	_check(Ladder.submit_waves(board, Ladder.entry(c, 1, 5.0)) == 0 and board["waves"].size() == Ladder.TOP_SIZE, "lo que no entra en el top se descarta")
	_check(Ladder.submit_waves(board, Ladder.entry(c, 12, 90.0)) == 1 and Ladder.submit_waves(board, Ladder.entry(c, 12, 95.0)) == 2, "más oleadas primero, empate por tiempo")
	_check(Ladder.submit_boss(board, "daemon", Ladder.entry(c, 0, 60.0)) == 1 and Ladder.submit_boss(board, "daemon", Ladder.entry(c, 0, 50.0)) == 1, "jefes: menos tiempo primero")
	Ladder.save_board(board, path)
	var loaded := Ladder.load_board(path)
	_check(loaded["waves"].size() == Ladder.TOP_SIZE and int(loaded["waves"][0]["waves"]) == 12 and loaded["bosses"]["daemon"].size() == 2, "la tabla se guarda en disco")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(Ladder.format_time(125.4) == "2:05", "tiempo en m:ss")
	# Aida abre el banco y la tabla.
	var npcs: Dictionary = DataLoader.load_json("res://data/npcs.json")
	var text := JSON.stringify(npcs)
	_check(text.contains("\"open_waves\"") and text.contains("\"open_ladder\""), "Aida abre el banco de oleadas y los récords")


## Árbol de deuda técnica (T47): cada nodo, bono y penalización.
func _test_tech_debt() -> void:
	var ids := {}
	for n in TechDebt.NODES:
		_check(not ids.has(n["id"]) and not n["bonus"].is_empty() and not n["penalty"].is_empty(), "%s: único, con bono y penalización" % n["id"])
		_check(n["requires"] == "" or ids.has(n["requires"]), "%s: pide un nodo anterior" % n["id"])
		_check(n["branch"] == "" or TechDebt.BRANCHES.has(n["branch"]), "%s: rama conocida" % n["id"])
		for md in n["bonus"] + n["penalty"]:
			_check(Stat.display_name(StringName(md["stat"])) != "", "%s: stat %s" % [n["id"], md["stat"]])
		ids[n["id"]] = true
		_check(TechDebt.describe(n["id"]).contains("Precio:"), "%s: se describe" % n["id"])
	var c := CharacterData.new(_classes[0], _tree)
	_check(TechDebt.total_points(c) == 0 and not TechDebt.can_allocate(c, "commit_directo"), "cerrado antes del Acto IV")
	c.flags["act4_complete"] = true
	_check(TechDebt.total_points(c) == 2, "al abrirse: 1 + nivel 1 del atlas (%d)" % TechDebt.total_points(c))
	c.flags["ladder"] = {"best_wave": 12, "bosses": {}}
	_check(TechDebt.total_points(c) == 4, "+1 por cada 5 oleadas")
	c.flags["ladder"]["best_wave"] = 500
	_check(TechDebt.total_points(c) == 2 + TechDebt.MAX_WAVE_POINTS, "las oleadas dan como mucho %d" % TechDebt.MAX_WAVE_POINTS)
	_check(not TechDebt.allocate(c, "hotfix"), "una rama pide la raíz")
	var dmg_before := c.stats.get_value(Stat.DAMAGE)
	var life_before := c.stats.get_value(Stat.LIFE)
	_check(TechDebt.allocate(c, "commit_directo") and TechDebt.allocate(c, "hotfix"), "raíz y primer nodo")
	c.recalculate()
	_check(c.stats.get_value(Stat.LIFE) < life_before, "la penalización se nota (vida %.0f → %.0f)" % [life_before, c.stats.get_value(Stat.LIFE)])
	_check(TechDebt.modifiers(c).size() == 4 and TechDebt.modifiers(c).any(func(m: Modifier) -> bool: return m.stat == Stat.DAMAGE and m.value > 0.0),
		"y el bono también (daño %.0f)" % dmg_before)
	_check(not TechDebt.refund(c, "commit_directo") and TechDebt.refund(c, "hotfix") and TechDebt.refund(c, "commit_directo"), "se paga de las hojas a la raíz")
	_check(is_equal_approx(c.stats.get_value(Stat.LIFE), life_before), "pagar la deuda devuelve la vida")
	for id in ["commit_directo", "viernes", "stack_overflow", "parche_sobre_parche", "crunch", "legacy", "no_lo_toques"]:
		TechDebt.allocate(c, id)
	_check(TechDebt.free_points(c) == 0 and not TechDebt.allocate(c, "try_catch_vacio"), "no pasa de los puntos que tienes")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(TechDebt.allocated(saved).size() == 7 and is_equal_approx(saved.stats.get_value(Stat.LIFE), c.stats.get_value(Stat.LIFE)), "el árbol se guarda y se aplica al cargar")
	var panel := TechDebtPanel.new(c)
	panel.free()


## Mando en menús, parte 1 (T48): cursor libre y salto con la cruceta.
func _test_gamepad_cursor() -> void:
	# Rejilla de casillas de 40 px; el cursor en la del centro (100, 100).
	var rects: Array[Rect2] = []
	for y in 3:
		for x in 3:
			rects.append(Rect2(Vector2(60 + x * 40, 60 + y * 40) - Vector2(16, 16), Vector2(32, 32)))
	var at := Vector2(100, 100)
	_check(GamepadCursor.pick_target(at, Vector2.RIGHT, rects) == 5 and GamepadCursor.pick_target(at, Vector2.UP, rects) == 1, "la cruceta va a la vecina")
	_check(GamepadCursor.pick_target(at, Vector2.LEFT, rects) == 3 and GamepadCursor.pick_target(at, Vector2.DOWN, rects) == 7, "en las cuatro direcciones")
	_check(GamepadCursor.pick_target(Vector2(140, 100), Vector2.RIGHT, rects) == -1, "en el borde no salta")
	_check(GamepadCursor.pick_target(Vector2(140, 60), Vector2.LEFT, rects) == 1, "prefiere la de su fila a la diagonal")
	# Los clics simulados no cuentan como «se usó el ratón».
	var was := Gamepad.active
	Gamepad.active = true
	var fake := InputEventMouseMotion.new()
	fake.device = Gamepad.CURSOR_DEVICE
	Gamepad.note_event(fake)
	_check(Gamepad.active, "el cursor de mando no apaga el modo mando")
	Gamepad.note_event(InputEventMouseMotion.new())
	_check(not Gamepad.active, "el ratón de verdad sí")
	Gamepad.active = was
	var cursor := GamepadCursor.new()
	_check(not cursor.engaged and cursor.windows.call().is_empty(), "sin ventanas, el cursor no se activa")
	cursor.free()
	_check(not Gamepad.menu_cursor, "y el personaje se maneja como siempre")


## Mando en menús, parte 2 (T49): comparar contra los dos anillos.
func _test_ring_comparison() -> void:
	var gen := ItemGenerator.new(_db, 49)
	var c := CharacterData.new(_classes[0], _tree)
	var ring_a := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_rubi")
	var ring_b := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_zafiro")
	var ring_c := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_zafiro")
	c.inventory.add_item(ring_a)
	c.inventory.equip_from_bag(c.inventory.bag.find(ring_a))
	_check(ItemTooltip.compare_slots(ring_c, c) == ["ring_right"] and ItemTooltip.build_text(ring_c, c, true).contains("Al equiparlo"),
		"con un anillo, se compara contra la mano libre")
	c.inventory.add_item(ring_b)
	c.inventory.equip_from_bag(c.inventory.bag.find(ring_b))
	var text := ItemTooltip.build_text(ring_c, c, true)
	_check(ItemTooltip.compare_slots(ring_c, c) == ["ring_left", "ring_right"] and text.contains("En lugar del anillo izquierdo") and text.contains("En lugar del anillo derecho"),
		"con dos anillos, contra cada uno")
	_check(ItemTooltip.compare_slots(ring_a, c) == ["ring_right"], "un anillo puesto solo se compara con el otro")
	c.preview_equip(ring_c, "ring_right")
	c.preview_equip(ring_c, "ring_left")
	_check(c.inventory.equipped("ring_left") == ring_a and c.inventory.equipped("ring_right") == ring_b and c.stats.get_value(Stat.FIRE_RES) == 15.0,
		"la vista previa por ranura no cambia lo equipado")
	_check(not ItemTooltip.build_text(ring_c, c, false).contains("En lugar del"), "sin comparar, no hay comparación")


## Rebindear teclas y botones (T50). Sin tocar el settings.cfg del jugador.
func _test_controls() -> void:
	var settings_before := FileAccess.get_file_as_string(GameSettings.PATH)
	Controls.allows_pad(&"skill_1")   # que corra antes su inicialización estática (ver _test_loot_filter_rules)
	Controls.persist = false
	Controls.setup()
	var pad_default := Controls.pad_of(&"skill_1")
	_check(Controls.key_of(&"skill_1") == KEY_Q and Controls.key_label(&"skill_1") == "Q", "de fábrica: Q para la habilidad 1")
	var msg := ControlsPanel.apply_key(&"skill_1", KEY_W)
	_check(Controls.key_of(&"skill_1") == KEY_W and Controls.key_of(&"skill_2") == KEY_Q and msg.contains("Habilidad 2"), "una tecla ocupada se intercambia (%s)" % msg)
	var w := InputEventKey.new()
	w.physical_keycode = KEY_W
	_check(InputMap.event_is_action(w, &"skill_1") and not InputMap.event_is_action(w, &"skill_2"), "el juego obedece a la tecla nueva")
	_check(Controls.rebind_pad(&"skill_1", JOY_BUTTON_Y) == "" and Controls.pad_of(&"skill_1") == JOY_BUTTON_Y, "botón del mando")
	_check(Controls.rebind_pad(&"skill_3", JOY_BUTTON_Y) != "" and Controls.pad_of(&"skill_3") == JOY_BUTTON_Y, "y también se intercambia")
	var before := Controls.pad_of(&"move_up")
	_check(Controls.rebind_pad(&"move_up", JOY_BUTTON_X) == "" and Controls.pad_of(&"move_up") == before, "el movimiento va con el stick")
	_check(Controls.pad_name(-1, &"dodge") == "Gatillo der." and Controls.pad_name(JOY_BUTTON_LEFT_SHOULDER) == "LB", "nombres de botones")
	var actions := {}
	for a in Controls.ACTIONS:
		_check(InputMap.has_action(a[0]) or a[0] == &"pin_tooltip", "%s existe" % a[0])
		actions[a[0]] = true
	_check(actions.size() == Controls.ACTIONS.size(), "sin acciones repetidas")
	var panel := ControlsPanel.new()
	panel.free()
	Controls.reset_all()
	_check(Controls.key_of(&"skill_1") == KEY_Q and Controls.key_of(&"skill_2") == KEY_W and Controls.pad_of(&"skill_1") == pad_default,
		"restaurar deja todo como de fábrica")
	Controls.persist = true
	_check(FileAccess.get_file_as_string(GameSettings.PATH) == settings_before, "las pruebas de controles no tocan el settings.cfg del jugador")


## Accesibilidad (T51): menos destellos, texto del mundo y paletas daltónicas.
## Cambia las variables a mano (sin set_*: no se toca el settings.cfg del jugador).
func _test_accessibility() -> void:
	var was := [Accessibility.reduce_flashes, Accessibility.world_text, Ailments.colorblind]
	Accessibility.reduce_flashes = false
	_check(Accessibility.flash(1.0) == 1.0 and Accessibility.can_blink(), "por defecto, los destellos como siempre")
	Accessibility.reduce_flashes = true
	_check(Accessibility.flash(1.0) < 0.5 and Accessibility.flash(4.0) < 2.0 and not Accessibility.can_blink(), "con la opción, más suaves y sin parpadeo")
	Accessibility.world_text = 1.5
	_check(Accessibility.world_size(14) == 21, "texto del mundo al 150 %%")
	Accessibility.world_text = 0.8
	_check(Accessibility.world_size(14) == 11 and Accessibility.world_size(4) >= 6, "más chico, con un mínimo")
	Ailments.colorblind = false
	var fire := SkillController.DAMAGE_COLORS["fire"]
	_check(Accessibility.aura_color("fire", fire) == fire and Charges.color("buffer") == Charges.COLORS["buffer"], "sin modo daltónico, los colores de siempre")
	Ailments.colorblind = true
	var auras := {}
	for t in Accessibility.AURA_COLORBLIND:
		auras[Accessibility.aura_color(t, Color.BLACK).to_html()] = true
	_check(auras.size() == Accessibility.AURA_COLORBLIND.size() and Accessibility.aura_color("fire", fire) != fire, "auras: un color distinto por tipo")
	var charges := {}
	for t in Charges.TYPES:
		charges[Charges.color(t).to_html()] = true
		_check(Charges.color(t) != Charges.COLORS[t], "carga %s con su color daltónico" % t)
	_check(charges.size() == Charges.TYPES.size(), "cargas: tres colores distintos")
	var lum := Charges.TYPES.map(func(t: String) -> float: return Charges.color(t).get_luminance())
	lum.sort()
	_check(lum[1] - lum[0] > 0.08 and lum[2] - lum[1] > 0.08, "y distintos también en brillo")
	Accessibility.reduce_flashes = was[0]
	Accessibility.world_text = was[1]
	Ailments.colorblind = was[2]


## Auto-ataque y mantener para mover (T52).
func _test_auto_attack() -> void:
	# Movimiento con el clic izquierdo: los tres modos.
	var hold := Player.mouse_press("hold", true, false, false)
	_check(hold["held"] and not hold["toggled"] and not Player.mouse_press("hold", false, true, false)["held"], "mantener: sigue mientras está pulsado")
	var on := Player.mouse_press("toggle", true, false, false)
	var off := Player.mouse_press("toggle", true, false, true)
	_check(on["toggled"] and not off["toggled"] and Player.mouse_press("toggle", false, false, true)["toggled"], "alternar: un clic empieza, otro para, soltar no cambia nada")
	_check(not Player.mouse_press("click", true, false, false)["go_to"] and Player.mouse_press("click", false, true, false)["go_to"], "clic para ir: al soltar camina hasta ahí")
	# Qué puede lanzar el auto-ataque.
	_check(SkillController.auto_attack_ok({"kind": "projectile"}) and not SkillController.auto_attack_ok({"kind": "aura"}) and not SkillController.auto_attack_ok({"kind": "unit"}),
		"golpes sí; auras e invocaciones no")
	_check(not SkillController.auto_attack_ok({"kind": "channel_beam"}) and not SkillController.auto_attack_ok({"kind": "projectile", "trigger": "on_kill"}) and not SkillController.auto_attack_ok({}),
		"ni canalizadas ni de activación")
	# En marcha: con un enemigo cerca y sin moverte, la habilidad 1 sale sola.
	var skills: Dictionary = _db.skills.skills
	var c := CharacterData.new(_classes[0], _tree)
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	player.global_position = Vector2(-40000, 40000)
	var sc := SkillController.new()
	root.add_child(sc)
	c.inventory.set_board(0, Motherboard.new(skills["ping_letal"], 5, []))
	sc.setup(player, em, c)
	var uses := [0]
	sc.skill_used.connect(func(_i: int) -> void: uses[0] += 1)
	var was: bool = SkillController.auto_attack
	SkillController.auto_attack = true
	em.spawn(player.global_position + Vector2(SkillController.AUTO_ATTACK_RANGE + 200.0, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	sc._physics_process(0.016)
	_check(uses[0] == 0, "sin enemigos a su alcance no ataca")
	em.spawn(player.global_position + Vector2(150, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	player._move_toggled = true
	sc._physics_process(0.016)
	_check(uses[0] == 0, "mientras te mueves no ataca")
	player._move_toggled = false
	sc._physics_process(0.016)
	_check(uses[0] == 1, "quieto y con un enemigo cerca, la habilidad 1 sale sola")
	SkillController.auto_attack = false
	sc.cooldowns[0] = 0.0
	sc._busy = 0.0
	sc._physics_process(0.016)
	_check(uses[0] == 1, "con la opción apagada, no")
	SkillController.auto_attack = was
	for n in [sc, player, em]:
		n.queue_free()


## Mapa grande: marcas propias (T53).
func _test_map_marks() -> void:
	var list: Array = []
	list = WorldMap.toggle_in(list, Vector2(500, 300), WorldMap.MARK_PICK, 3)
	_check(list.size() == 1 and list[0] == [500.0, 300.0], "clic derecho: una marca")
	list = WorldMap.toggle_in(list, Vector2(900, 300), WorldMap.MARK_PICK, 3)
	list = WorldMap.toggle_in(list, Vector2(1400, 300), WorldMap.MARK_PICK, 3)
	_check(WorldMap.toggle_in(list, Vector2(2000, 300), WorldMap.MARK_PICK, 3).size() == 3, "con el tope lleno no se añaden más")
	var after := WorldMap.toggle_in(list, Vector2(930, 320), WorldMap.MARK_PICK, 3)
	_check(after.size() == 2 and not after.has([900.0, 300.0]) and list.size() == 3, "clic cerca de una marca la quita (sin tocar la lista original)")
	var c := CharacterData.new(_classes[0], _tree)
	c.flags["marks_zona1"] = after
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	var back: Array = saved.flags.get("marks_zona1", [])
	_check(back.size() == 2 and Vector2(back[1][0], back[1][1]) == Vector2(1400, 300), "las marcas se guardan con el personaje")
	_check(WorldMap.ZOOMS[0] == 1.0 and WorldMap.ZOOMS.size() >= 4, "niveles de zoom, empezando por la zona entera")


## Filtro de botín, siguiente paso (T54): nivel de objeto, bases, afijos y filtros con nombre.
## Sin tocar el settings.cfg del jugador.
func _test_loot_filter_rules() -> void:
	var settings_before := FileAccess.get_file_as_string(GameSettings.PATH)
	# Primero una llamada a la clase: su inicialización estática (persist = true)
	# corre en la primera llamada y pisaría lo que se ponga antes.
	LootFilter.reload()
	LootFilter.persist = false
	LootFilter._test_profiles = {}
	LootFilter.apply_preset("estricto")
	var gen := ItemGenerator.new(_db, 54)
	var low := Item.new(_db.bases["espada_oxidada"], Rarity.Item.RARE, 3)
	var high := Item.new(_db.bases["espada_oxidada"], Rarity.Item.RARE, 30)
	var normal := Item.new(_db.bases["hacha_de_lenador"], Rarity.Item.NORMAL, 30)
	_check(LootFilter.passes(low) and LootFilter.passes(high) and not LootFilter.passes(normal), "de partida: raros sí, normales no")
	LootFilter.set_min_ilvl(10)
	_check(not LootFilter.passes(low) and LootFilter.passes(high), "nivel de objeto mínimo: esconde lo de nivel bajo")
	LootFilter.toggle_listed("bases", "hacha_de_lenador")
	_check(LootFilter.passes(normal) and LootFilter.highlighted(normal) and LootFilter.beams(normal), "una base buena se ve siempre, con estrella y haz")
	LootFilter.toggle_listed("bases", "hacha_de_lenador")
	_check(not LootFilter.passes(normal) and not LootFilter.highlighted(normal), "y se puede quitar")
	var magic := gen.generate(30, Rarity.Item.MAGIC, "espada_oxidada")
	var stat := String(magic.affixes[0]["stat"])
	_check(not LootFilter.passes(magic), "un mágico no pasa el filtro estricto")
	LootFilter.toggle_listed("stats", stat)
	_check(LootFilter.passes(magic) and LootFilter.highlighted(magic), "con un afijo buscado (%s), sí" % stat)
	var flask := gen.generate_flask(10)
	_check(flask == null or not LootFilter.highlighted(flask), "las pociones no llevan estrella")
	# Los atajos no borran las reglas finas.
	LootFilter.apply_preset("todo")
	_check(int(LootFilter.rules()["min_ilvl"]) == 10 and (LootFilter.rules()["stats"] as Array).has(stat), "un atajo cambia rarezas y respeta las reglas finas")
	# Filtros con nombre.
	LootFilter.save_profile("Mapas")
	LootFilter.apply_preset("endgame")
	LootFilter.set_min_ilvl(0)
	_check(LootFilter.profiles().has("Mapas") and LootFilter.load_profile("Mapas"), "se guarda y se carga un filtro con nombre")
	_check(String(LootFilter.rules()["weapon"]) == "normal" and int(LootFilter.rules()["min_ilvl"]) == 10, "cargarlo devuelve todas sus reglas")
	_check(not LootFilter.load_profile("No existe"), "uno que no existe no se carga")
	LootFilter.save_profile("   ")
	LootFilter.delete_profile("Mapas")
	_check(LootFilter.profiles().is_empty(), "sin nombre no se guarda; y se pueden borrar")
	LootFilter.persist = true
	LootFilter.reload()
	_check(FileAccess.get_file_as_string(GameSettings.PATH) == settings_before, "las pruebas no tocan el settings.cfg del jugador")


## Ambiente posicional (T55): racks, goteo y viento cerca de su fuente.
func _test_ambient_emitters() -> void:
	for s in ["emit_rack", "emit_drip", "emit_wind"]:
		_check(Sfx.audio_path(Sfx.AMB_DIR + s) != "", "existe el sonido %s" % s)
	var obstacles := [
		{"kind": "rack", "pos": Vector2(100, 100)}, {"kind": "rack", "pos": Vector2(200, 100)},   # demasiado juntos: uno
		{"kind": "rack", "pos": Vector2(900, 100)}, {"kind": "chasm", "pos": Vector2(150, 120)},
		{"kind": "tomb", "pos": Vector2(500, 500)},
	]
	var plan := AmbientEmitters.plan(obstacles, "ruins", [])
	var sounds := plan.map(func(e: Dictionary) -> String: return e["sound"])
	_check(sounds.count("emit_rack") == 2 and sounds.count("emit_wind") == 1 and plan.size() == 3, "cada fuente suena junto a su obstáculo, sin amontonarse (%s)" % str(sounds))
	var many: Array = []
	for k in 20:
		many.append(Vector2(k * 1000.0, 0))
	var sewer := AmbientEmitters.plan([], "alcantarillas", many)
	_check(sewer.size() == AmbientEmitters.MAX_PER_SOUND and sewer.all(func(e: Dictionary) -> bool: return e["sound"] == "emit_drip"),
		"en las alcantarillas gotea aunque no haya charcos, con un tope")
	_check(AmbientEmitters.plan([], "forest", many).is_empty(), "un bosque sin fuentes queda en silencio posicional")


## Voces cortas (T56): murmullos de PNJ y la voz del personaje.
func _test_barks() -> void:
	_check(Barks.kind_for("Hola", true) == "greet" and Barks.kind_for("¿Y tú quién eres?", false) == "question", "saludo al empezar; pregunta si acaba en ?")
	_check(Barks.kind_for("¡Cuidado!", false) == "exclaim" and Barks.kind_for("No sé...", false) == "hmm" and Barks.kind_for("Bien.", false) == "talk", "exclamación, duda y charla")
	for kind in Barks.KINDS:
		var wav := Barks.stream(kind)
		var seconds := wav.get_length()
		var loud := false
		for i in range(0, wav.data.size() - 1, 64):
			if absi(wav.data.decode_s16(i)) > 4000:
				loud = true
				break
		_check(seconds > 0.1 and seconds < 0.8 and loud, "%s: un murmullo corto que suena (%.2f s)" % [kind, seconds])
	_check(Barks.stream("talk") == Barks.stream("talk"), "se sintetiza una vez y se guarda")
	var her := DialogueBox.bark_pitch({"id": "aida", "voice": {"pitch": 1.0, "gender": "female"}})
	var him := DialogueBox.bark_pitch({"id": "mario", "voice": {"pitch": 1.0, "gender": "male"}})
	_check(her > him and DialogueBox.bark_pitch({"id": "x"}) > 0.5, "cada PNJ con su tono (y su género)")


## Materiales de enemigos en los datos (T57): cada tipo dice de qué está hecho.
func _test_enemy_materials() -> void:
	var counts := {}
	for t in _db_enemies():
		var m := String(t.get("material", ""))
		_check(EnemyManager.MATERIAL_SFX.has(m), "%s tiene material válido en enemies.json (%s)" % [t["id"], m])
		counts[m] = int(counts.get(m, 0)) + 1
	_check(counts.size() == EnemyManager.MATERIAL_SFX.size(), "se usan los cuatro materiales: %s" % str(counts))
	_check(not (load("res://scripts/game/enemy_manager.gd") as GDScript).get_script_constant_map().has("MATERIALS"), "la tabla fija ya no está en el código")


## Luces, sombras y clima (T58).
func _test_lights_weather() -> void:
	WorldPost.enabled()   # que corra su inicialización estática antes de tocar `reduced`
	var was := WorldPost.reduced
	WorldPost.reduced = false
	_check(Weather.kind_for("terminal") == "data_rain" and Weather.kind_for("swamp") == "fog" and Weather.kind_for("forest") == "", "lluvia de datos en la terminal, niebla en el pantano")
	var rain := Weather.new()
	rain.kind = "data_rain"
	var view := Rect2(0, 0, 1600, 900)
	for k in Weather.RAIN_DROPS:
		rain._parts.append(rain._spawn(view, true))
	for k in 120:   # 6 s de lluvia
		rain.step(0.05, view)
	_check(rain.particle_count() == Weather.RAIN_DROPS and rain._parts.all(func(p: Dictionary) -> bool: return view.grow(200.0).has_point(p["pos"])),
		"la lluvia cae y vuelve a entrar por arriba (sigue en pantalla)")
	rain.free()
	var fog := Weather.new()
	fog.kind = "fog"
	for k in Weather.FOG_BANKS:
		fog._parts.append(fog._spawn(view, true))
	var x0: float = fog._parts[0]["pos"].x
	fog.step(1.0, view)
	_check(fog._parts[0]["pos"].x > x0, "la niebla deriva")
	fog.free()
	WorldPost.reduced = true
	_check(Weather.kind_for("terminal") == "", "con luces y clima reducidos, no hay clima")
	WorldPost.reduced = was
	# Luz propia de las invocaciones.
	var sc := SkillController.new()
	sc._minions.append({"pos": Vector2(50, 60), "color": Color.RED})
	var allies := sc.light_allies()
	_check(allies.size() == 1 and allies[0]["pos"] == Vector2(50, 60) and allies[0]["color"] == Color.RED and float(allies[0]["power"]) > 0.0, "las invocaciones dan luz de su color")
	sc.free()
	_check(SkillController.PROJECTILE_SHADOW_DROP > 0.0, "los proyectiles proyectan sombra un poco más abajo")


## Obstáculos del Acto I en pixel art (T59).
func _test_obstacle_art() -> void:
	for kind in ObstacleArt.KINDS:
		var s := ObstacleArt.sprite(kind, 32.0, 7)
		var img: Image = (s["texture"] as ImageTexture).get_image()
		var counts := {"solid": 0, "outline": 0}
		var tones := {}
		for y in img.get_height():
			for x in img.get_width():
				var px := img.get_pixel(x, y)
				if px.a > 0.5:
					counts["solid"] += 1
					tones[px.to_html(false)] = true
					if px.is_equal_approx(ObstacleArt.OUTLINE):
						counts["outline"] += 1
		_check(counts["solid"] > 40 and counts["outline"] > 10 and tones.size() >= 3, "%s: pintado, con contorno y al menos tres tonos (%d px, %d tonos)" % [kind, counts["solid"], tones.size()])
		_check(Vector2(s["size"]) == Vector2(img.get_width(), img.get_height()) * ObstacleArt.PIX, "%s: cada píxel ocupa %d del mundo" % [kind, ObstacleArt.PIX])
	var before := ObstacleArt.cached_count()
	ObstacleArt.sprite("rock", 33.0, 7)   # mismo tamaño redondeado y variante: de la caché
	_check(ObstacleArt.cached_count() == before, "se pinta una vez por tipo, tamaño y variante")
	_check(ObstacleArt.sprite("rock", 32.0, 0)["texture"] != ObstacleArt.sprite("rock", 32.0, 1)["texture"], "con variantes")
	# T60: todos los obstáculos de los actos (salvo los charcos, animados) van en pixel art.
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act["zones"]:
			var obs = z.get("obstacles")
			if not obs is Dictionary:
				continue
			for kind in obs.get("kinds", []):
				_check(ObstacleArt.KINDS.has(kind) or kind == "puddle", "%s (%s): obstáculo en pixel art" % [kind, z["id"]])


## Música de las pruebas de estrés (T62).
func _test_stress_music() -> void:
	var music: Dictionary = DataLoader.load_json("res://data/music.json")
	var id := String((load("res://scripts/game/world.gd") as GDScript).get_script_constant_map().get("STRESS_TRACK", ""))
	_check(id != "" and music["tracks"].has(id), "la pista de las pruebas de estrés está en music.json (%s)" % id)
	_check(Sfx.audio_path("res://assets/audio/music/%s" % id) != "" and Sfx.audio_path("res://assets/audio/music/%s_combate" % id) != "", "y está compuesta, con su capa de combate")
	var loops: Dictionary = DataLoader.load_json("res://data/music_loops.json")
	_check(loops.has(id) and float(loops[id]) > 0.0, "con su bucle tras la intro")
	_check(int(music["tracks"][id]["bpm"]) > int(music["tracks"]["field1"]["bpm"]), "más rápida que la música de las zonas")


## Audio en OGG (T63): música, ambientes y título comprimidos; los efectos, en WAV.
func _test_audio_ogg() -> void:
	var total := 0
	for dir in ["res://assets/audio/music/", "res://assets/audio/ambient/"]:
		for f in DirAccess.get_files_at(dir):
			_check(not f.ends_with(".wav"), "%s%s: ya en OGG" % [dir, f])
			if f.ends_with(".ogg"):
				total += FileAccess.open(dir + f, FileAccess.READ).get_length()
	_check(total > 0 and total < 30 * 1024 * 1024, "la música y los ambientes ocupan menos de 30 MB (%.1f MB)" % (total / 1048576.0))
	_check(Sfx.audio_path("res://assets/audio/title_theme").ends_with(".ogg"), "el tema del título también")
	_check(Sfx.audio_path(Sfx.SFX_DIR + "coin").ends_with(".wav"), "los efectos cortos siguen en WAV")
	_check(Sfx.audio_path("res://assets/audio/no_existe") == "" and Sfx.load_looped("res://assets/audio/no_existe") == null, "lo que no existe no se carga")
	var camp := Sfx.load_looped("res://assets/audio/music/camp1", 16000, Sfx.MUSIC_RATE) as AudioStreamOggVorbis
	_check(camp != null and camp.loop and is_equal_approx(camp.loop_offset, 1.0), "el bucle pasa de muestras a segundos (16000 muestras = 1 s)")


## Telemetría local de equilibrio (T64).
func _test_telemetry() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	var em := EnemyManager.new()
	c.play_time = 100.0
	var visit := Telemetry.begin(c, em, "zona3", 7)
	c.play_time = 160.0
	c.flags["stat_kills"] = 25
	c.flags["stat_deaths"] = 1
	em._count_damage(3000.0)
	em.tick_combat_time(1.0)
	em.tick_combat_time(1.0)   # 2 s en combate
	var rec := Telemetry.finish(visit, c, em)
	_check(rec["zone"] == "zona3" and is_equal_approx(float(rec["seconds"]), 60.0) and int(rec["kills"]) == 25 and int(rec["deaths"]) == 1,
		"una visita: zona, tiempo, enemigos y muertes")
	_check(int(rec["damage"]) == 3000 and int(rec["dps"]) == 1500, "DPS = daño entre segundos en combate (%s)" % rec["dps"])
	c.play_time = 162.0
	_check(Telemetry.finish(Telemetry.begin(c, em, "campamento", 1), c, em).is_empty(), "pasar un momento por una zona no cuenta")
	var path := "user://test_telemetria.jsonl"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(not Telemetry.write(rec, c, path), "un personaje de prueba (sin id) no deja registro")
	c.id = "prueba"
	if Telemetry.enabled():
		var other := rec.duplicate()
		other["zone"] = "zona4"
		other["deaths"] = 0
		other["dps"] = 500
		_check(Telemetry.write(rec, c, path) and Telemetry.write(other, c, path) and Telemetry.write(rec, c, path), "se apunta en el archivo")
		var all := Telemetry.read(path)
		var by_zone := Telemetry.summarize(all)
		_check(all.size() == 3 and by_zone["zona3"]["visits"] == 2 and int(by_zone["zona3"]["dps"]) == 1500 and float(by_zone["zona3"]["deaths_per_hour"]) == 60.0,
			"el resumen por zona: visitas, DPS medio y muertes por hora")
		_check(Telemetry.summarize(all, "class").size() == 1 and by_zone["zona4"]["deaths"] == 0, "y por clase")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	em.free()


## Rendimiento (T68): formas de enemigos en MultiMesh y caché de iconos del HUD.
func _test_render_batching() -> void:
	var em := EnemyManager.new()
	root.add_child(em)
	if em._quad_mm == null:
		em._ready()   # en las pruebas el árbol aún no corre: crea las MultiMesh a mano
	em._shape_rect(Rect2(10, 20, 30, 4), Color.RED)
	em._shape_rect(Rect2(0, 0, 5, 5), Color.BLACK)
	em._shape_disc(Vector2(100, 50), 12.0, Color(0, 1, 0, 0.5))
	var buf := em._quad_buf
	_check(is_equal_approx(buf[0], 30.0) and is_equal_approx(buf[3], 10.0) and is_equal_approx(buf[5], 4.0) and is_equal_approx(buf[7], 20.0) and is_equal_approx(buf[8], 1.0),
		"una barra: escala = tamaño, origen = esquina y su color")
	em._flush_shapes()
	_check(em._quad_mm.visible_instance_count == 2 and em._disc_mm.visible_instance_count == 1 and em._quad_n == 0, "las barras y halos del fotograma, en sus MultiMesh")
	em._flush_shapes()
	_check(em._quad_mm.visible_instance_count == 0, "un fotograma sin nada no deja barras viejas")
	for k in 200:
		em._shape_rect(Rect2(k, 0, 1, 1), Color.WHITE)
	em._flush_shapes()
	_check(em._quad_mm.visible_instance_count == 200 and em._quad_mm.instance_count >= 200, "el búfer crece con muchos enemigos")
	var dirs := EnemyManager._unit_circle(12)
	_check(dirs.size() == 13 and dirs[0].is_equal_approx(Vector2.RIGHT) and dirs[12].is_equal_approx(Vector2.RIGHT) and EnemyManager._unit_circle(12) == dirs, "círculos con direcciones precalculadas")
	var before := em._batch_indices.size()
	em._batch_convex(EnemyManager._cone_points(Vector2.ZERO, Vector2.RIGHT, 100.0, 0.5), Color.RED)
	_check(em._batch_indices.size() - before == 12 * 3, "el aviso de cono va al lote como abanico (12 triángulos)")
	em.free()
	# Sin pantalla la caché no crea texturas: se dibuja con formas como siempre.
	var calls := [0]
	_check(IconCache.texture("prueba", func(_ci, _r, _m) -> void: calls[0] += 1) == null and IconCache.cached_count() == 0, "sin pantalla, IconCache no crea nada")


## Balance de habilidades iniciales (T69): banda de DPS a placa 1 y tiempo contra el primer jefe.
func _test_skill_balance() -> void:
	var ch := CharacterData.new(_classes[0], _tree)
	var values: Array = []
	var dps_of := {}
	for id in _db.skills.skills:
		var dps := float(SkillCalc.compute(Motherboard.new(_db.skills.skills[id], 1, []), ch).get("dps", 0.0))
		dps_of[id] = dps
		if dps > 0.0:
			values.append(dps)
	values.sort()
	var median: float = values[values.size() / 2]
	for id in dps_of:
		_check(dps_of[id] <= median * 2.2, "%s: a placa 1 no pasa de ~2× la mediana (%.1f, mediana %.1f)" % [id, dps_of[id], median])
	_check(int(_db.skills.skills["proceso_hijo"].get("min_level", 1)) >= 6, "Proceso Hijo ya no cae al principio")
	# Con su arma y sus iniciales, cada clase tumba al Arquitecto en un tiempo razonable.
	var bal: GDScript = load("res://tools/skill_balance.gd")
	var boss_life: float = bal.act1_boss_life()
	_check(boss_life > 1000.0, "vida del primer jefe (%.0f)" % boss_life)
	for c in _classes:
		var best := INF
		for row in bal.starter_rows(c, _db, _tree, boss_life):
			best = minf(best, float(row[2]))
		_check(best >= 35.0 and best <= 130.0, "%s: su mejor habilidad inicial tumba al primer jefe en %.0f s (entre 35 y 130)" % [c["id"], best])


## Tienda de Nacho, parte 1 (T70): más surtido, oferta, contrabando, renovar, lote y recompra.
func _test_shop_stock() -> void:
	var gen := ItemGenerator.new(_db, 70)
	var stock := Economy.generate_stock(gen, 15)
	var boards := stock.filter(func(it: Item) -> bool: return it is Motherboard and Economy.shop_tag(it) == "")
	for attr in ["str", "dex", "int"]:
		_check(boards.filter(func(b: Motherboard) -> bool: return String(b.skill_def.get("attribute", "")) == attr).size() == Economy.STOCK_BOARDS_PER_ATTRIBUTE,
			"%d placas de %s: siempre hay algo para tu clase" % [Economy.STOCK_BOARDS_PER_ATTRIBUTE, attr])
	var skill_ids := boards.map(func(b: Motherboard) -> String: return String(b.skill_def["id"]))
	var unique_ids := {}
	for id in skill_ids:
		unique_ids[id] = true
	_check(unique_ids.size() == skill_ids.size(), "sin placas repetidas")
	var rams := stock.filter(func(it: Item) -> bool: return it is RamModule)
	var ram_ids := {}
	for r in rams:
		ram_ids[String((r as RamModule).def.get("id", ""))] = true
	_check(rams.size() >= 8 and ram_ids.size() == rams.size(), "RAM de módulos distintos (%d)" % rams.size())
	var deal: Item = stock.filter(func(it: Item) -> bool: return Economy.shop_tag(it) == Economy.TAG_DEAL)[0]
	var contra: Item = stock.filter(func(it: Item) -> bool: return Economy.shop_tag(it) == Economy.TAG_CONTRABAND)[0]
	_check(Economy.shop_price(deal) < Economy.price(deal) and (deal as Motherboard).slots.size() == 4, "la oferta del día: placa de 4 ranuras, rebajada")
	_check(Economy.shop_price(contra) > Economy.price(contra) * 2 and (contra as Motherboard).slots.size() == 5 and (contra as Motherboard).level > 14,
		"el contrabando: más nivel, 5 ranuras y caro")
	# Las placas con min_level no salen antes (arreglo de T69 en el generador).
	var low := ItemGenerator.new(_db, 7)
	for k in 200:
		_check(int(low.generate_motherboard(2).skill_def.get("min_level", 1)) <= 2, "una placa de nivel 2 no es de una habilidad de nivel mayor")
	_check(Economy.refresh_cost(10, 0) < Economy.refresh_cost(10, 1) and Economy.refresh_cost(10, 1) < Economy.refresh_cost(10, 2), "cada renovación cuesta más")
	# Venta por lote y recompra.
	var c := CharacterData.new(_classes[0], _tree)
	c.inventory.add_item(gen.generate(10, Rarity.Item.NORMAL))
	c.inventory.add_item(gen.generate(10, Rarity.Item.MAGIC))
	c.inventory.add_item(gen.generate(10, Rarity.Item.RARE))
	c.inventory.add_item(gen.generate_motherboard(10))
	_check(Economy.bulk_sell(c.inventory, Rarity.Item.NORMAL)[0].size() == 1 and Economy.bulk_sell(c.inventory, Rarity.Item.MAGIC)[0].size() == 2,
		"el lote vende solo equipo normal (o normal y mágico), nunca raros ni placas")
	var panel := ShopPanel.new()
	panel.character = c
	panel._ready()
	var before := c.tokens
	var got := panel.sell_bulk(Rarity.Item.MAGIC)
	_check(got > 0 and c.tokens == before + got and panel.buyback.size() == 2, "vender el lote paga y lo deja para recomprar")
	_check(ShopPanel.passes_filter(boards[0], String(boards[0].skill_def["attribute"])) and not ShopPanel.passes_filter(rams[0], "str") and ShopPanel.passes_filter(rams[0], "ram"),
		"filtros por tipo y atributo")
	c.inventory.add_item(boards[0].duplicate_item() if boards[0].has_method("duplicate_item") else boards[0])
	_check(ShopPanel.owned_board_level(c, boards[0]) > 0, "avisa si ya tienes esa habilidad")
	panel.free()


## Tienda de Nacho, parte 2 (T71): la gabardina, sus frases y el puesto de Aida.
func _test_shop_coat() -> void:
	for vendor in ["nacho", "aida"]:
		for event in ["enter", "hover", "buy", "sell", "broke", "full", "refresh"]:
			_check(ShopLines.pick(vendor, event) != "", "%s tiene frase para «%s»" % [vendor, event])
	var wav := ShopVendorArt.cloth_stream(true)
	_check(wav.data.size() > 4000 and wav.data != ShopVendorArt.cloth_stream(false).data, "sonido de tela al abrir y al cerrar (distintos)")
	var gen := ItemGenerator.new(_db, 71)
	var c := CharacterData.new(_classes[0], _tree)
	var panel := ShopPanel.new()
	panel.character = c
	panel._ready()
	panel.open(Economy.generate_stock(gen, 12))
	_check(panel.last_line in ShopLines.LINES["nacho"]["enter"], "Nacho saluda al abrir la gabardina")
	_check(panel._art.frame == ShopVendorArt.FRAMES - 1, "la gabardina acaba abierta")
	var hooks := panel._grid.get_children().filter(func(col: Node) -> bool: return col.get_child(0) is Control and not (col.get_child(0) is Label))
	_check(hooks.size() == panel._grid.get_child_count() and hooks.size() > 0, "cada artículo cuelga de un gancho del forro")
	_check(not panel.contraband_open and panel._special.get_child_count() == 2, "dos bolsillos: la oferta y el contrabando (cerrado)")
	var contra_i := panel.stock.find(panel.stock.filter(func(it: Item) -> bool: return Economy.shop_tag(it) == Economy.TAG_CONTRABAND)[0])
	c.tokens = 0
	_check(not panel.buy(contra_i) and panel.last_line in ShopLines.LINES["nacho"]["broke"], "sin tokens: no compra y Nacho se burla")
	panel.open_contraband()
	_check(panel.contraband_open and panel.last_line in ShopLines.LINES["nacho"]["pocket"], "el bolsillo secreto se abre aparte")
	c.tokens = 100000
	_check(panel.buy(contra_i) and panel.stock[contra_i] == null and panel.last_line in ShopLines.LINES["nacho"]["buy"], "comprar sigue funcionando (y comenta)")
	panel.refreshes = 1
	panel.open(Economy.generate_stock(gen, 12))
	_check(panel.last_line in ShopLines.LINES["nacho"]["refresh"] and not panel.contraband_open, "al renovar comenta la caja nueva, no vuelve a saludar")
	panel.filter = "ram"
	panel.open(Economy.generate_gear_stock(gen, 12), "aida")
	_check(panel.vendor == "aida" and panel.last_line in ShopLines.LINES["aida"]["enter"], "Aida tiene su propio saludo")
	_check(not panel._filter_row.visible and not panel._pockets_box.visible and not panel._refresh_button.visible, "el puesto de Aida: sin filtros, bolsillos ni bodega")
	_check(panel._grid.get_child_count() == panel.stock.size() and panel._grid.get_child(0).get_child(0) is ItemCell, "Aida enseña todo en la mesa, sin ganchos")
	panel.free()


## Personaje animado por estados, parte 1 (T72): poses, arma en la mano y estado del jugador.
func _test_player_poses() -> void:
	_check(Player.action_for({"tags": ["attack", "melee"]}) == "attack" and Player.action_for({"tags": ["attack", "projectile"]}) == "shoot"
		and Player.action_for({"tags": ["spell", "fire"]}) == "cast", "golpe, disparo o hechizo según las etiquetas de la habilidad")
	_check(CharacterAppearance.pose_transform("idle", 0.0, Vector2.DOWN, 1.0).is_empty(), "de pie no se gira la figura")
	_check(is_equal_approx(absf(float(CharacterAppearance.pose_transform("dead", 1.0, Vector2.RIGHT, 1.0)[1])), PI * 0.5), "muerto: cae de lado")
	_check(CharacterAppearance.arm_angle("attack", "sword", 0.35) > 2.5 and CharacterAppearance.arm_angle("attack", "sword", 0.55) < 0.5,
		"la espada sube y luego baja de golpe")
	_check(CharacterAppearance.arm_reach("attack", "dagger", 0.4) > 1.1 and CharacterAppearance.arm_reach("attack", "sword", 0.4) == 1.0, "la daga es una estocada")
	var gen := ItemGenerator.new(_db, 72)
	for base_id in _db.bases:
		var tags: Array = _db.bases[base_id].get("tags", [])
		if "weapon" in tags:
			_check(CharacterAppearance.weapon_kind(gen.generate(5, Rarity.Item.NORMAL, base_id)) != "", "se dibuja el arma %s" % base_id)
	_check(CharacterAppearance.weapon_kind(null) == "", "sin arma, nada en la mano")
	var c := CharacterData.new(_classes[0], _tree)
	var p := Player.new()
	p.character = c
	p.life = 10.0
	_check(p.anim_state() == "idle", "quieto: respira")
	p.play_action("attack", 0.5)
	p._tick_anim(0.25)
	var pose := p.anim_pose()
	_check(pose["state"] == "attack" and is_equal_approx(float(pose["t"]), 0.5), "a media acción, el golpe va por la mitad")
	p._tick_anim(0.3)
	_check(p.anim_state() == "idle", "acabada la acción, vuelve a reposo")
	p.keep_channeling()
	_check(p.anim_state() == "channel", "canalizando")
	p._tick_anim(0.2)
	p.life = 0.0
	p._tick_anim(1.0)
	_check(p.anim_state() == "dead" and float(p.anim_pose()["t"]) == 1.0, "muerto: la caída termina")
	p.free()


## Enemigos (T73): respingo al recibir un crítico, muertes por material y cadáveres.
func _test_enemy_weight() -> void:
	_check(EnemyManager.leaves_corpse("physical", "flesh") and EnemyManager.leaves_corpse("chaos", "metal"), "los muertos a golpes o disueltos dejan cuerpo")
	_check(not EnemyManager.leaves_corpse("fire", "flesh") and not EnemyManager.leaves_corpse("cold", "metal") and not EnemyManager.leaves_corpse("physical", "crystal"),
		"ni la ceniza, ni el hielo roto, ni los añicos de cristal")
	_check(EnemyManager.corpse_alpha(EnemyManager.CORPSE_TIME) > 0.85 and EnemyManager.corpse_alpha(0.1) < 0.1, "el cuerpo se ve entero y al final se desvanece")
	var em := EnemyManager.new()
	var by_material := {}
	for k in EnemyManager.enemy_types().size():
		by_material[String(EnemyManager.enemy_types()[k].get("material", "digital"))] = k
	em.spawn(Vector2(0, 0), Rarity.Enemy.NORMAL, int(by_material.get("flesh", 0)))
	em.hit_ailments = {"type": "physical"}
	em.hit_index(0, 1e9, 1e9, 0.0, 150.0)
	_check(em.count() == 0 and em.corpses.size() == 1, "muerto a golpes: queda su cuerpo")
	em.spawn(Vector2(50, 0), Rarity.Enemy.NORMAL, int(by_material.get("flesh", 0)))
	em.hit_ailments = {"type": "fire"}
	em.hit_index(0, 1e9, 1e9, 0.0, 150.0)
	_check(em.corpses.size() == 1, "quemado: no deja cuerpo, solo ceniza")
	em._update_corpses(EnemyManager.CORPSE_TIME + 0.1)
	_check(em.corpses.is_empty(), "a los pocos segundos el cuerpo desaparece")
	# Un crítico da un respingo y empuja más que un golpe normal.
	var pl := Player.new()
	em.player = pl
	em.spawn(Vector2(80, 0), Rarity.Enemy.NORMAL, int(by_material.get("flesh", 0)))
	em.spawn(Vector2(80, 40), Rarity.Enemy.NORMAL, int(by_material.get("flesh", 0)))
	em.hit_ailments = {"type": "physical"}
	em.hit_index(0, 0.01, 0.01, 100.0, 150.0)
	em.hit_index(1, 0.01, 0.01, 0.0, 150.0)
	_check(em._recoils.has(em.ids[0]) and not em._recoils.has(em.ids[1]), "solo el crítico da un respingo")
	_check(em.knocks[0].length() > em.knocks[1].length(), "y empuja más")
	em.free()
	pl.free()


## Efectos de habilidades con más cuerpo (T74): firma por habilidad y partículas con tope.
func _test_skill_fx() -> void:
	var skills: Dictionary = _db.skills.skills
	_check(SkillFx.signature(skills["ping_letal"])["projectile"] == "bolt" and SkillFx.signature(skills["rafaga_de_paquetes"])["projectile"] == "packet",
		"el ping es un rayo en zigzag y la ráfaga, paquetes")
	_check(SkillFx.signature({"id": "nueva", "damage_type": "fire"})["projectile"] == "fireball", "sin firma propia: la de su tipo de daño")
	var shapes := {}
	for id in skills:
		if String(skills[id].get("kind", "")) in ["projectile", "homing", "dot_projectile"]:
			var sig := SkillFx.signature(skills[id])
			for part in ["projectile", "trail", "cast", "impact"]:
				_check(String(sig.get(part, "")) != "", "%s tiene %s" % [id, part])
			shapes[sig["projectile"]] = true
	_check(shapes.size() >= 4, "los proyectiles se distinguen de lejos (%d formas)" % shapes.size())
	var fx := ImpactFx.new()
	var was: bool = Accessibility.reduce_flashes
	Accessibility.reduce_flashes = false
	fx.skill_impact(Vector2.ZERO, "splash", Color.ORANGE)
	var full := fx.count()
	fx.clear()
	Accessibility.reduce_flashes = true
	fx.skill_impact(Vector2.ZERO, "splash", Color.ORANGE)
	_check(fx.count() < full and fx.flashes.size() <= 1, "con Menos destellos, menos partículas")
	Accessibility.reduce_flashes = was
	fx.clear()
	for k in 2000:
		fx.trail(Vector2.ZERO, "embers", Color.ORANGE)
	_check(fx.count() <= int(ImpactFx.MAX_PARTICLES * 0.5) + 1, "las estelas no pasan del tope de partículas")
	fx.free()


## Iconos en pixel art (T75): atlas de 32 y 16 con todas las habilidades, estados y familias de RAM.
func _test_pixel_icons() -> void:
	var data: Dictionary = DataLoader.load_json(PixelIcons.MAP_PATH)
	var icons: Dictionary = data.get("icons", {})
	for id in _db.skills.skills:
		_check(PixelIcons.has_icon("skill:" + id), "icono en pixel art de %s" % id)
	for id in Ailments.ALL + ["stun", "corrupt", "taunt", "reserve"]:
		_check(PixelIcons.has_icon("status:" + id), "icono del estado %s" % id)
	for id in _db.skills.rams:
		_check(PixelIcons.has_icon("ram:" + RamModule.family_of(id)), "icono de la familia de %s" % id)
	var a32: Texture2D = load(PixelIcons.ATLAS_32)
	var a16: Texture2D = load(PixelIcons.ATLAS_16)
	var cols := int(data.get("columns", 16))
	var rows := int(ceil(icons.size() / float(cols)))
	_check(a32.get_width() == cols * 32 and a32.get_height() == rows * 32 and a16.get_width() == cols * 16 and a16.get_height() == rows * 16,
		"los dos atlas tienen la cuadrícula del mapa")
	var last: int = icons.values().max()
	_check(PixelIcons.region(icons.keys()[icons.values().find(last)], 16).end.y <= a16.get_height(), "la última celda cabe en el atlas")
	# Pixel art de verdad: alfa todo o nada (sin degradados de suavizado).
	var img := a32.get_image()
	var soft := 0
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var al := img.get_pixel(x, y).a
			if al > 0.01 and al < 0.99:
				soft += 1
	_check(soft == 0, "sin bordes suavizados (%d píxeles a medias)" % soft)
	PixelIcons.enabled = false
	_check(not PixelIcons.has_icon("skill:ping_letal"), "se puede volver a los glifos de formas")
	PixelIcons.enabled = true


## Interfaz con identidad (T76): fuente de píxeles, botón hundido, remaches y orbes con líquido.
func _test_ui_identity() -> void:
	for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚÜÑ0123456789.,:;!¡?¿-+/%()·«»":
		var r := PixelFont.rows(ch)
		_check(r.size() == PixelFont.CELL_H, "la fuente de píxeles tiene «%s»" % ch)
		for row in r:
			_check(String(row).length() == String(r[0]).length(), "«%s»: todas las filas del mismo ancho" % ch)
	_check(PixelFont.rows("Á")[0] != PixelFont.rows("A")[0] and PixelFont.rows("Ñ")[1] != PixelFont.rows("N")[1], "con tilde y con virgulilla")
	_check(PixelFont.supports("Nacho · La gabardina") and PixelFont.supports("Bolsa (3 / 60)") and not PixelFont.supports("✕"), "cubre los títulos (en mayúsculas)")
	var f := PixelFont.font()
	_check(f.has_char("A".unicode_at(0)) and f.has_char("Ñ".unicode_at(0)) and f.has_char("7".unicode_at(0)), "la fuente montada tiene los glifos")
	_check(f.get_string_size("AB", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.CELL_H * 2).x > f.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.CELL_H * 2).x,
		"avanza al escribir")
	var l := UiStyle.pixel_label("Inventario", 3)
	_check(l.text == "INVENTARIO" and l.get_theme_font_size("font_size") == 30, "rótulo en mayúsculas y a tamaño entero")
	l.free()
	var tiny := UiStyle.label("x", 9)
	_check(tiny.get_theme_font_size("font_size") >= UiStyle.MIN_FONT_SIZE, "ningún texto por debajo del mínimo legible")
	tiny.free()
	var theme := UiStyle.make_theme()
	var normal := theme.get_stylebox("normal", "Button")
	var pressed := theme.get_stylebox("pressed", "Button")
	_check(pressed.content_margin_top > normal.content_margin_top, "el botón pulsado se hunde")   # con el atlas (T95), StyleBoxTexture
	# Orbes: las burbujas están siempre dentro del líquido.
	for t in [0.0, 1.3, 7.7]:
		for b in UiStyle.orb_bubbles(t, 100.0, 178.0, 120.0, 78.0):
			_check((b[0] as Vector2).y > 120.0 and (b[0] as Vector2).y < 178.0 and (b[0] as Vector2).distance_to(Vector2(100, 100)) < 78.0, "burbuja dentro del orbe")
	_check(UiStyle.orb_bubbles(0.5, 100.0, 178.0, 177.0, 78.0).is_empty(), "orbe vacío: sin burbujas")


## Sonido por habilidad y por objeto (T77): capas con tono propio, materiales, suelos e interfaz.
func _test_sound_map() -> void:
	var exists := func(name: String) -> bool: return ResourceLoader.exists(Sfx.SFX_DIR + name + ".wav")
	var skills: Dictionary = _db.skills.skills
	var pitches := {}
	for id in skills:
		var layers := SoundMap.cast_layers(skills[id])
		for l in layers:
			_check(exists.call(l[0]), "%s: existe el sonido %s" % [id, l[0]])
		pitches[snappedf(float(layers[0][2]), 0.001)] = true
		_check(float(layers[0][2]) >= SoundMap.PITCH_BASE and float(layers[0][2]) <= SoundMap.PITCH_BASE + SoundMap.PITCH_SPREAD, "%s: tono dentro del rango" % id)
	_check(pitches.size() > skills.size() * 0.8, "casi todas las habilidades con su propio tono (%d de %d)" % [pitches.size(), skills.size()])
	_check(SoundMap.skill_pitch("ping_letal") == SoundMap.skill_pitch("ping_letal"), "el tono de una habilidad es estable")
	_check(SoundMap.cast_layers(skills["barrido"]).size() == 2 and SoundMap.signature_layer(skills["ping_letal"]) == "lay_hum", "capa de firma: cuerpo a cuerpo y rayo")
	for dt in ["fire", "cold", "lightning", "chaos", "physical"]:
		_check(exists.call(SoundMap.impact(dt)), "impacto de %s" % dt)
	var gen := ItemGenerator.new(_db, 77)
	var sword := gen.generate(5, Rarity.Item.NORMAL, "espada_oxidada")
	var robe := gen.generate(5, Rarity.Item.NORMAL, "tunica_de_seda")
	_check(SoundMap.material(sword) == "metal" and SoundMap.material(robe) == "cloth" and SoundMap.material(gen.generate_flask(5)) == "glass"
		and SoundMap.material(gen.generate_motherboard(5)) == "board", "material del objeto: metal, tela, cristal y placa")
	for it in [sword, robe, gen.generate_flask(5), gen.generate_motherboard(5), gen.generate_ram(5)]:
		_check(exists.call(SoundMap.pickup(it)) and exists.call(SoundMap.equip(it)), "recoger y equipar %s suenan" % it.display_name())
	_check(SoundMap.drop(gen.generate(20, Rarity.Item.UNIQUE)) in ["unique_drop", "set_drop"] and SoundMap.drop(sword) == "", "caída especial solo de únicos y conjuntos")
	_check(SoundMap.step("forest") == "step_dirt" and SoundMap.step("servers") == "step_metal" and SoundMap.step("catacombs") == "step_stone", "pasos según el suelo")
	for name in ["ui_open", "ui_close", "ui_hover", "ui_buy", "ui_error", "set_drop", "step_stone", "step_dirt", "step_metal"]:
		_check(exists.call(name), "existe %s" % name)


## Música y avisos por intensidad (T78): avisos cortos y cambio de pista a compás.
func _test_stingers() -> void:
	for kind in ["elite", "loot", "level", "boss"]:
		var path: String = Sfx.SFX_DIR + "sting_" + kind + ".wav"
		_check(ResourceLoader.exists(path), "existe el aviso %s" % kind)
		if ResourceLoader.exists(path):
			var len_s := (load(path) as AudioStream).get_length()
			_check(len_s > 0.3 and len_s < 2.5, "el aviso %s es corto (%.1f s)" % [kind, len_s])
	_check(SoundMap.sighting_stinger(Rarity.Enemy.ELITE) == "elite" and SoundMap.sighting_stinger(Rarity.Enemy.UNIQUE) == "boss"
		and SoundMap.sighting_stinger(Rarity.Enemy.NORMAL) == "" and SoundMap.sighting_stinger(Rarity.Enemy.SPECIAL) == "", "aviso al ver élites y jefes, no normales")
	_check(not SoundMap.stinger("elite"), "sin reproductor de música (pruebas), el aviso no hace nada")
	# A compás: a 120 bpm (medio segundo por tiempo).
	_check(is_equal_approx(SoundMap.beat_wait(0.0, 120.0), 0.5) and is_equal_approx(SoundMap.beat_wait(1.2, 120.0), 0.3)
		and SoundMap.beat_wait(7.49, 120.0) < 0.02, "el cambio de pista espera al siguiente tiempo")
	for bpm in [84.0, 142.0]:
		for pos in [0.1, 3.3, 10.0]:
			var beat: float = 60.0 / bpm
			var w := SoundMap.beat_wait(pos, bpm)
			var off := fposmod(pos + w, beat)
			_check(w > 0.0 and w <= beat + 0.0001 and minf(off, beat - off) < 0.001, "cae justo en un tiempo (%d bpm, %.1f s)" % [bpm, pos])


## Inventario a la altura del género (T79): ordenar y compactar, bloquear, basura y venderla.
func _test_inventory_marks() -> void:
	var gen := ItemGenerator.new(_db, 79)
	var sword := gen.generate(10, Rarity.Item.RARE, "espada_oxidada")
	_check(Item.cycle_mark(sword) == "basura" and sword.junk and not sword.locked, "click derecho: basura")
	_check(Item.cycle_mark(sword) == "bloqueado" and sword.locked and not sword.junk, "otra vez: bloqueado")
	_check(Item.cycle_mark(sword) == "sin marca" and not sword.locked and not sword.junk, "y otra: sin marca")
	var board := gen.generate_motherboard(10)
	board.locked = true
	var again := Item.from_dict(Item.serialize(board), _db)
	_check(again.locked and again is Motherboard, "las marcas se guardan (también en placas)")
	var c := CharacterData.new(_classes[0], _tree)
	var inv := c.inventory
	for k in inv.bag.size():
		inv.bag[k] = null
	var robe := gen.generate(10, Rarity.Item.NORMAL, "tunica_de_seda")
	var junk_ring := gen.generate(10, Rarity.Item.MAGIC)
	junk_ring.junk = true
	var flask := gen.generate_flask(10)
	inv.bag[7] = board
	inv.bag[3] = flask
	inv.bag[12] = robe
	inv.bag[20] = junk_ring
	inv.bag[30] = sword
	_check(inv.sort_bag() == 5, "ordenar no pierde nada")
	_check(inv.bag[5] == null and inv.bag[4] != null, "compacta: sin huecos")
	_check(inv.bag[0].is_equipment() and inv.bag[1].is_equipment() and inv.bag[2] == flask and inv.bag[3] == board and inv.bag[4] == junk_ring,
		"equipo, luego pociones y placas; la basura al final")
	var loaded := Inventory.new()
	loaded.load_dict(inv.to_dict(), _db)
	_check(loaded.bag[4].junk and loaded.bag[3].locked, "la bolsa guardada conserva las marcas")
	# Venta: lo bloqueado nunca, la basura de golpe.
	sword.locked = true
	_check(not (inv.bag.find(sword) in Economy.bulk_sell(inv, Rarity.Item.RARE)[0]), "vender por lote se salta lo bloqueado")
	board.locked = false
	board.junk = true
	var plan := Economy.junk_sell(inv)
	_check(plan[0].size() == 2 and plan[1] > 0, "basura: el anillo y la placa marcados")
	var panel := ShopPanel.new()
	panel.character = c
	panel._ready()
	var before := c.tokens
	var got := panel.sell_junk()
	_check(got == plan[1] and c.tokens == before + got and panel.buyback.size() == 2 and not (panel.buyback[0]["item"] as Item).junk,
		"vender lo marcado paga, se puede recomprar y vuelve sin la marca")
	_check(inv.bag.find(sword) != -1 and inv.bag.find(robe) != -1, "lo demás sigue en la bolsa")
	panel.free()


## Alijo con pestañas y búsqueda (T80).
func _test_stash_tabs() -> void:
	var s := Stash.new("user://prueba_alijo_t80.json")
	_check(Stash.TABS == 5 and s.tab_name(Stash.MATERIALS_TAB) == "Materiales", "cinco pestañas, una de materiales")
	s.rename(0, "   Lo bueno de verdad para el jefe final   ")
	_check(s.tab_name(0) == "Lo bueno de verdad p" and s.tab_name(0).length() == Stash.NAME_MAX, "renombrar recorta espacios y largo")
	s.rename(1, "  ")
	_check(s.tab_name(1) == Stash.TAB_NAMES[1], "un nombre vacío vuelve al de fábrica")
	s.set_color(2, 5)
	var gen := ItemGenerator.new(_db, 80)
	var ring := gen.generate(20, Rarity.Item.RARE, "anillo_de_rubi")
	s.set_item(0, 3, ring)
	var copy := Stash.new("user://prueba_alijo_t80.json")
	copy.load_dict(s.to_dict(), _db)
	_check(copy.tab_name(0) == s.tab_name(0) and copy.tab_color(2) == Stash.TAB_COLORS[5] and copy.get_item(0, 3) != null, "nombres, colores y objetos se guardan")
	var old := Stash.new("user://prueba_alijo_t80.json")
	old.load_dict({"version": 1, "tabs": [[null], [null], [null], [null]]}, _db)
	_check(old.tab_name(3) == Stash.TAB_NAMES[3] and old.tabs.size() == 5, "un alijo de antes carga con los nombres de fábrica y la pestaña nueva")
	# Materiales: solo chips.
	_check(Stash.refusal(Stash.MATERIALS_TAB, ring) != "" and Stash.refusal(0, ring) == "", "el equipo no va a la pestaña de materiales")
	# Búsqueda: nombre, base y afijos, sin tildes ni mayúsculas.
	_check(Stash.matches(ring, "ANILLO") and Stash.matches(ring, ring.display_name().substr(0, 4)), "busca por nombre y base")
	if not ring.affixes.is_empty():
		var affix_text := Item.describe_mod(ring.affixes[0]).split(" ")
		var word := ""
		for w in affix_text:
			if w.length() > 4 and not w.is_valid_float():
				word = w
				break
		if word != "":
			_check(Stash.matches(ring, word.to_upper()), "busca por el texto de un afijo («%s»)" % word)
	_check(Stash.matches(ring, "rubí") == Stash.matches(ring, "rubi"), "sin distinguir tildes")
	_check(not Stash.matches(ring, "") and not Stash.matches(null, "anillo") and not Stash.matches(ring, "zzzz"), "vacío o sin coincidencia: no marca")
	_check(s.match_count(0, "anillo") == 1 and s.match_count(1, "anillo") == 0, "cuenta las coincidencias por pestaña")
	_check(not UiStyle.typing(), "sin escribir en un campo, las teclas del juego funcionan")


## Hoja de personaje con desglose (T81): de dónde sale cada número.
func _test_stat_breakdown() -> void:
	var sb := StatBlock.new()
	sb.set_base(Stat.LIFE, 100.0)
	sb.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.FLAT, 20.0, [], "item:helmet"))
	sb.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.FLAT, 10.0, [], "item:body"))
	sb.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.INCREASED, 15.0, [], "tree"))
	sb.add_modifier(Modifier.new(Stat.LIFE, Modifier.Type.MORE, 10.0, [], "aura:blindaje"))
	sb.add_modifier(Modifier.new(Stat.MANA, Modifier.Type.FLAT, 50.0, [], "item:ring"))
	var rows := sb.source_breakdown(Stat.LIFE)
	var by := {}
	for r in rows:
		by[r["group"]] = r
	_check(by.size() == 3 and by.has("Objetos") and by.has("Árbol de pasivas") and by.has("Auras"), "se agrupa por origen (objetos, árbol, auras)")
	_check(float(by["Objetos"]["flat"]) == 30.0 and float(by["Árbol de pasivas"]["increased"]) == 15.0 and is_equal_approx(float(by["Auras"]["more"]), 1.1),
		"suma lo de cada origen: planos, aumentos y multiplicadores")
	var b := sb.get_breakdown(Stat.LIFE)
	var total := 0.0
	for r in rows:
		total += float(r["flat"])
	_check(is_equal_approx(total, float(b["flat"])), "el desglose suma lo mismo que el total")
	_check(StatBlock.source_label("item:weapon") == "Objetos" and StatBlock.source_label("charge") == "Cargas" and StatBlock.source_label("class_trait") == "Clase"
		and StatBlock.source_label("") == "Otros", "nombres de los orígenes")
	var text := StatExplain.explain(sb, Stat.LIFE, "Vida máxima")
	_check(text.contains("Base (clase y nivel): 100") and text.contains("Objetos: +30") and text.contains("Árbol de pasivas: +15 %") and text.contains("Auras: ×1.10"),
		"el tooltip cuenta de dónde sale: %s" % text.replace("\n", " | "))
	_check(StatExplain.explain(sb, Stat.ARMOUR, "Armadura").contains("nada lo modifica"), "sin modificadores, lo dice")
	# Con un personaje de verdad: la clase y los atributos aparecen.
	var c := CharacterData.new(_classes[0], _tree)
	var groups := c.stats.source_breakdown(Stat.LIFE).map(func(r: Dictionary) -> String: return r["group"])
	_check("Atributos" in groups, "la vida de un personaje cuenta lo que da su fuerza (%s)" % ", ".join(groups))
	_check(StatExplain.hotbar_dps_lines(null).is_empty(), "sin barra, sin líneas")


## Ventanas coherentes (T82): la memoria de pestañas solo lee si no se toca.
func _test_window_memory() -> void:
	_check(UiStyle.remembered("clave_que_no_existe_t82", 7) == 7, "sin recuerdo, el valor por defecto")
	var panel := ShopPanel.new()
	panel._ready()
	_check(panel.filter in ShopPanel.FILTERS, "la tienda abre con un filtro válido (el último usado o «todo»)")
	panel.free()


## Planificador del árbol (T83): plan sin gastar, aplicar, deshacer, rehacer y código de build.
func _test_passive_plan() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	var alloc := c.passives
	var plan := PassivePlan.new(alloc)
	# Un nodo a 3+ pasos del inicio.
	var target := -1
	for id in _tree.nodes:
		if alloc.find_path(id).size() >= 3 and alloc.find_path(id).size() <= 6:
			target = id
			break
	_check(target != -1, "hay un nodo a unos pasos del inicio")
	var path_len := alloc.find_path(target).size()
	_check(plan.plan_path(target) == path_len and alloc.spent_points() == 0, "planear marca el camino sin gastar puntos")
	_check(plan.is_planned(target) and plan.points_missing(1) == path_len - 1, "dice cuántos puntos faltan")
	var first: int = plan.planned_ids()[0]
	_check(path_len < 2 or not plan.unplan(first), "no se quita del plan un nodo del que cuelgan otros")
	_check(plan.unplan(target) and not plan.is_planned(target), "el último del camino sí se quita")
	plan.plan_path(target)
	_check(plan.apply(2) == 2 and alloc.spent_points() == 2 and plan.planned_ids().size() == path_len - 2, "aplicar asigna hasta donde llegan los puntos")
	_check(plan.undo() and alloc.spent_points() == 0 and plan.planned_ids().size() == path_len, "deshacer vuelve a como estaba (asignado y plan)")
	_check(plan.redo() and alloc.spent_points() == 2, "rehacer")
	plan.clear_history()
	_check(not plan.can_undo() and not plan.can_redo(), "al cerrar el árbol se olvida el historial")
	# Código de build.
	var ids: Array = alloc.get_allocated_ids()
	ids.append_array(plan.planned_ids())
	var code := PassivePlan.export_code(_tree, String(c.class_def["id"]), ids, {"12": 1})
	_check(code.begins_with(PassivePlan.CODE_PREFIX), "el código empieza por %s" % PassivePlan.CODE_PREFIX)
	var back := PassivePlan.import_code(_tree, code)
	_check(back.get("class", "") == String(c.class_def["id"]) and (back["ids"] as Array).size() == ids.size() and int(back["masteries"].get("12", 0)) == 1,
		"exportar e importar la build da lo mismo")
	_check(PassivePlan.import_code(_tree, "hola").is_empty() and PassivePlan.import_code(_tree, "PO2:12:@@@").is_empty(), "un texto que no es código no rompe nada")
	_check(PassivePlan.import_code(_tree, "PO1:30:abc").get("error", "") == "old" and int(back.get("dropped", -1)) == 0, "un código del árbol viejo avisa; uno nuevo no pierde nodos")
	# Importar en partida: queda como plan, sin regalar puntos.
	var fresh := CharacterData.new(_classes[0], _tree)
	var fplan := PassivePlan.new(fresh.passives)
	_check(fplan.set_plan(back["ids"]) == ids.size() - 1 and fresh.passives.spent_points() == 0, "una build importada en partida es un plan")
	_check(Economy.passive_refund_cost(30) > Economy.passive_refund_cost(5), "quitar nodos cuesta más con el nivel")


## Más identidad en el árbol (T84): notables de estilo, piedras angulares con contra y constelaciones.
func _test_tree_identity() -> void:
	var styles := _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.style)
	_check(styles.size() == 7, "un notable de estilo por clase (%d)" % styles.size())
	var mechanic_stats := [Stat.CONVERT_PHYSICAL_TO_LIGHTNING, Stat.RETALIATION_NOVA, Stat.DODGE_BLAST, Stat.EXTRA_PIERCE, Stat.CONVERT_ELEMENTAL_TO_CHAOS, Stat.STATIC_PULSE, Stat.KILL_EXPLOSION]
	for n: PassiveNode in styles:
		_check(n.mods.any(func(m: Modifier) -> bool: return m.stat in mechanic_stats), "%s cambia cómo se juega (no solo números)" % n.title)
	for cdef in _classes:
		var alloc := PassiveAllocation.new(_tree, _tree.get_start_node_for_class(StringName(cdef["id"])))
		var near := styles.filter(func(n: PassiveNode) -> bool: return alloc.find_path(n.id).size() > 0 and alloc.find_path(n.id).size() <= 6)
		_check(not near.is_empty(), "%s tiene su notable de estilo cerca del inicio" % cdef["name"])
	var keystones := _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.is_keystone())
	_check(keystones.size() >= 11, "más piedras angulares (%d)" % keystones.size())
	for title in ["Hotfix en Producción", "Root Access", "Arquitectura Hexagonal", "Kanban"]:
		var k: Array = keystones.filter(func(n: PassiveNode) -> bool: return n.title == title)
		_check(k.size() == 1 and k[0].mods.any(func(m: Modifier) -> bool: return m.value < 0.0), "«%s» tiene su contra" % title)
	# Constelaciones: piden dos atributos; sin ellos no se asignan ni se cruzan.
	var stars := _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return not n.requires.is_empty())
	var names := {}
	for n: PassiveNode in stars:
		names[n.constellation] = true
		_check(n.requires.size() >= 2, "%s pide dos atributos o más" % n.title)
	_check(names.size() == 6, "seis constelaciones en el anillo exterior (%d)" % names.size())
	var star: PassiveNode = stars[0]
	var test_alloc := PassiveAllocation.new(_tree, _tree.get_start_node_for_class(StringName(_classes[0]["id"])))
	var ok := [false]
	test_alloc.requirement_check = func(_r: Dictionary) -> bool: return ok[0]
	_check(test_alloc.find_path(star.id).is_empty(), "sin los atributos, la constelación no se alcanza")
	ok[0] = true
	_check(not test_alloc.find_path(star.id).is_empty(), "con ellos, sí")
	var c := CharacterData.new(_classes[0], _tree)
	_check(not c.meets_attributes({"strength": 999}) and c.meets_attributes({"strength": 1}), "el personaje compara sus atributos")


## Arte del árbol (T85): destello al completar un grupo e iconos de temática.
func _test_tree_art() -> void:
	var cluster := ""
	for n: PassiveNode in _tree.nodes.values():
		if n.cluster != "":
			cluster = n.cluster
			break
	var members: Array = _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.cluster == cluster).map(func(n: PassiveNode) -> int: return n.id)
	var before := {}
	for id in members.slice(1):
		before[id] = true
	var after := before.duplicate()
	after[members[0]] = true
	_check(PassiveTreeView.completed_clusters(_tree, before, after) == [cluster], "el último nodo de un grupo lo completa (destello)")
	_check(PassiveTreeView.completed_clusters(_tree, after, after).is_empty(), "sin nodos nuevos, sin destello")
	var partial := {}
	partial[members[0]] = true
	_check(PassiveTreeView.completed_clusters(_tree, {}, partial).is_empty() or members.size() == 1, "un grupo a medias no destella")
	var themes := {}
	for n: PassiveNode in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.MINOR and n.theme != "":
			themes[n.theme] = true
	var with_icon := themes.keys().filter(func(t: String) -> bool: return PassiveIcons.has_icon(t))
	_check(with_icon.size() >= themes.size() * 0.8, "los nodos menores tienen icono de su temática (%d de %d)" % [with_icon.size(), themes.size()])


## Bases con identidad y únicos con mecánica (T86).
func _test_bases_and_unique_mechanics() -> void:
	var new_bases := ["sable_de_fibra_optica", "hacha_de_despido_masivo", "martillo_de_compilacion", "cuchilla_de_carton", "casco_de_obra",
		"auriculares_con_cancelacion", "armadura_de_rack", "chaqueta_de_conferencias", "guantes_antiestaticos", "botas_de_seguridad"]
	var gen := ItemGenerator.new(_db, 86)
	for id in new_bases:
		_check(_db.bases.has(id), "existe la base %s" % id)
		if not _db.bases.has(id):
			continue
		_check(not (_db.bases[id].get("implicits", []) as Array).is_empty(), "%s tiene implícito propio" % id)
		_check(ItemIcons.has_icon(id), "%s tiene icono" % id)
		var it := gen.generate(40, Rarity.Item.RARE, id)
		_check(it.implicit_mods().size() > 0 and it.display_name() != "", "%s se genera con su implícito" % id)
	# Cada tipo de arma con su implícito propio en la base de nivel alto.
	var weapon_implicit := {"sword": "life_leech", "axe": "bleed_chance", "mace": "area_of_effect", "dagger": "poison_chance"}
	for kind in weapon_implicit:
		var found := false
		for id in new_bases:
			var b: Dictionary = _db.bases.get(id, {})
			if kind in b.get("tags", []) and String(b["implicits"][0]["stat"]) == weapon_implicit[kind]:
				found = true
		_check(found, "las %s nuevas tienen su implícito (%s)" % [kind, weapon_implicit[kind]])
	var mechanic := [Stat.PAGER_STRIKE, Stat.FIRE_WALL, Stat.RETALIATION_NOVA, Stat.CONVERT_PHYSICAL_TO_FIRE, Stat.SPAGHETTI_CODE, Stat.SAFE_MODE,
		Stat.EXTRA_PROJECTILES, Stat.DODGE_BLAST]
	var with_mechanic := 0
	for u in _db.uniques:
		var item := gen.make_unique(u, 40)
		_check(item != null and String(u.get("flavor", "")) != "", "%s se puede generar y tiene su texto" % u["name"])
		for m in u.get("mods", []):
			_check(StringName(m["stat"]) in Stat.NAMES or StringName(m["stat"]) in Stat.RULE_TEXT or String(m["stat"]).begins_with("local_"), "%s: stat conocido %s" % [u["name"], m["stat"]])
		if u.get("mods", []).any(func(m: Dictionary) -> bool: return StringName(m["stat"]) in mechanic):
			with_mechanic += 1
	_check(with_mechanic >= 8, "únicos cuya gracia es una mecánica (%d)" % with_mechanic)
	# Llevar el Pager de Guardia activa su golpe propio.
	var c := CharacterData.new(_classes[0], _tree)
	var pager: Dictionary = _db.uniques.filter(func(u: Dictionary) -> bool: return u["id"] == "pager_de_guardia")[0]
	c.inventory.set_equipped("belt", gen.make_unique(pager, 40))
	_check(c.stats.get_value(Stat.PAGER_STRIKE) > 0.0, "equipar el Pager activa los rayos de guardia")


## Crafteo con más decisiones (T87): quitar un afijo, optimizar con riesgo e historial de la mesa.
func _test_crafting_decisions() -> void:
	var gen := ItemGenerator.new(_db, 87)
	var c := CharacterData.new(_classes[0], _tree)
	for k in Crafting.KINDS:
		Crafting.add(c, k, 50)
	var item := gen.generate(60, Rarity.Item.RARE, "espada_bastarda")
	var gone: Dictionary = item.affixes[0]
	var n := item.affixes.size()
	_check(Crafting.apply(c, item, "rollback", gen, 0) == "" and item.affixes.size() == n - 1 and not item.affixes.has(gone), "rollback: quita el afijo elegido")
	_check(Crafting.apply(c, item, "rollback", gen, 99) != "", "sin elegir afijo, no hace nada")
	# Optimizar: o sube un tier (mejor rango) o se rompe y se pierde; nunca empeora.
	var upgraded := 0
	var broke := 0
	for k in 40:
		var it := gen.generate(60, Rarity.Item.RARE, "espada_bastarda")
		var idx := -1
		for i in it.affixes.size():
			if not Crafting.next_tier(it, it.affixes[i], _db).is_empty():
				idx = i
				break
		if idx == -1:
			continue
		var before: Dictionary = it.affixes[idx].duplicate()
		var count_before := it.affixes.size()
		_check(Crafting.apply(c, it, "optimize", gen, idx) == "", "optimizar se puede")
		if it.affixes.size() == count_before:
			upgraded += 1
			_check(int(it.affixes[idx]["tier_rank"]) == int(before["tier_rank"]) - 1, "sube justo un tier")
		else:
			broke += 1
	_check(upgraded > 0 and broke > 0, "a veces sube y a veces se rompe (%d / %d)" % [upgraded, broke])
	# El nivel del objeto pone el techo.
	var low := gen.generate(1, Rarity.Item.MAGIC, "espada_oxidada")
	var capped := true
	for a in low.affixes:
		var t := Crafting.next_tier(low, a, _db)
		capped = capped and (t.is_empty() or int(t["level"]) <= low.item_level)
	_check(capped, "no se pasa del tier que permite el nivel del objeto")
	# Historial.
	var log_entries := Crafting.history(c)
	_check(log_entries.size() > 0 and log_entries.size() <= Crafting.LOG_MAX and String(log_entries[0]).contains("optimización"), "la mesa apunta lo que hizo (lo último primero)")
	var saved := CharacterData.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())), _classes[0], _tree, _db)
	_check(Crafting.history(saved).size() == log_entries.size(), "el historial se guarda con el personaje")


## Árbol 2.0, diseño (T88): la disposición del prototipo se carga, está conectada y tiene claves únicas.
func _test_tree_v2_layout() -> void:
	var path := "res://data/passive_tree.json"
	var data: Dictionary = DataLoader.load_json(path)
	var keys := {}
	for n in data.get("nodes", []):
		keys[String(n.get("key", ""))] = true
	_check(keys.size() == (data["nodes"] as Array).size() and not keys.has(""), "cada nodo del árbol 2.0 tiene su clave estable y única")
	var tree := PassiveTree.load_from_json(path)
	_check(tree.nodes.size() >= 1300 and tree.nodes.size() <= 1700, "el árbol 2.0 tiene casi el doble de nodos (%d)" % tree.nodes.size())
	var starts := tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.kind == PassiveNode.Kind.CLASS_START)
	_check(starts.size() == 7, "siete inicios de clase")
	var start := tree.get_start_node_for_class(&"full_stack")
	var seen := {start: true}
	var stack: Array = [start]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		for nb in tree.neighbors(cur):
			if not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	_check(seen.size() == tree.nodes.size(), "todo el árbol 2.0 se alcanza desde el centro (%d de %d)" % [seen.size(), tree.nodes.size()])
	_check((data["clusters"] as Array).size() >= 100, "más del doble de clusters (%d)" % (data["clusters"] as Array).size())


## Árbol 2.0, migración (T89b): un personaje del árbol viejo recupera los puntos con la primera reasignación gratis.
func _test_tree_migration() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	c.level = 20
	var d := c.to_dict()
	d["passive_tree_version"] = 7
	d["passives"] = [1, 2, 3, 4, 5]
	var back := CharacterData.from_dict(d, _classes[0], _tree, _db)
	_check(back.passives.spent_points() == 0 and back.passive_points_available() == back.passive_points_total(), "con el árbol viejo, todos los puntos de vuelta")
	_check(back.flags.has("passives_refunded") and back.flags.has("free_respec"), "y la primera reasignación es gratis")
	_check(_tree.version >= 8, "el árbol del juego es la versión 8 o posterior (árbol 2.0)")
	var keyed := _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.key != "")
	_check(keyed.size() == _tree.nodes.size() and _tree.id_for_key(keyed[0].key) == keyed[0].id, "todos los nodos con clave, y la clave lleva a su id")
	_check(PassiveTreeView.LOD_FAR_ZOOM > PassiveTreeView.LOD_ICON_ZOOM, "de lejos, el árbol se dibuja simplificado")


## Más clusters de las familias (T90): todas con 4 o más, sin notables repetidos y con condiciones.
func _test_tree_families() -> void:
	var per := {}
	for c in _tree.clusters.values():
		if String(c["theme"]) != "":
			per[c["theme"]] = int(per.get(c["theme"], 0)) + 1
	for t in _tree.themes:
		_check(int(per.get(t, 0)) >= 4, "la familia %s tiene 4 clusters o más (%d)" % [t, per.get(t, 0)])
	var names := {}
	var repeated := []
	var unknown := []
	var conditional := 0
	var conditions := [Stat.COND_LOW_LIFE, Stat.COND_FULL_LIFE, &"recent_kill", &"stationary", &"three_allies"]
	for n: PassiveNode in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.NOTABLE or n.kind == PassiveNode.Kind.KEYSTONE:
			if names.has(n.title):
				repeated.append(n.title)
			names[n.title] = true
			if n.mods.any(func(m: Modifier) -> bool: return m.tags.any(func(tag: StringName) -> bool: return tag in conditions)):
				conditional += 1
		for m in n.mods:
			if not (m.stat in Stat.NAMES or m.stat in Stat.RULE_TEXT):
				unknown.append(String(m.stat))
	_check(repeated.is_empty(), "ningún notable repetido: %s" % ", ".join(repeated))
	_check(unknown.is_empty(), "todos los stats del árbol son conocidos: %s" % ", ".join(unknown))
	_check(conditional >= 15, "notables con condición (vida baja o llena, tras matar, quieto, con aliados): %d" % conditional)


## Familia de maná (T91): maná antes que vida, regeneración plana y los nodos del árbol.
func _test_mana_family() -> void:
	var split := ManaMath.split_damage(100.0, 500.0, 30.0)
	_check(is_equal_approx(split.x, 30.0) and is_equal_approx(split.y, 70.0), "con 30 %% al maná, un golpe de 100 quita 30 de maná y 70 de vida (%s)" % split)
	split = ManaMath.split_damage(100.0, 0.0, 30.0)
	_check(split.x == 0.0 and is_equal_approx(split.y, 100.0), "sin maná, todo el golpe va a la vida")
	split = ManaMath.split_damage(100.0, 12.0, 30.0)
	_check(is_equal_approx(split.x, 12.0) and is_equal_approx(split.y, 88.0), "si el maná no alcanza, lo que falta va a la vida")
	split = ManaMath.split_damage(100.0, 500.0, 90.0)
	_check(is_equal_approx(split.x, ManaMath.MAX_TAKEN_FROM_MANA), "el maná se lleva como mucho un 50 %% del golpe")
	var base := ManaMath.regen_per_second(200.0, 1.0, 0.0)
	_check(is_equal_approx(base, 3.5), "regeneración base: 1,75 %% del maná máximo por segundo (%.2f)" % base)
	_check(is_equal_approx(ManaMath.regen_per_second(200.0, 1.0, 5.0), base + 5.0), "la regeneración plana se suma a la base")
	_check(is_equal_approx(ManaMath.regen_per_second(0.0, 1.0, 5.0), 5.0), "la regeneración plana se suma aunque todo el maná esté reservado")
	_check(ManaMath.regen_per_second(200.0, 2.0, 5.0, true) == 0.0, "con Recolector de Basura no hay regeneración")
	var stats := StatBlock.new()
	stats.add_modifier(Modifier.new(Stat.DAMAGE_TAKEN_FROM_MANA, Modifier.Type.FLAT, 15.0))
	_check(stats.get_value(Stat.DAMAGE_TAKEN_FROM_MANA) == 15.0 and Stat.is_percent(Stat.DAMAGE_TAKEN_FROM_MANA), "maná antes que vida es un stat en %")
	var found := {}
	for n: PassiveNode in _tree.nodes.values():
		for m in n.mods:
			if m.stat in [Stat.MANA_REGEN_FLAT, Stat.DAMAGE_TAKEN_FROM_MANA, Stat.MANA_ON_HIT, Stat.MANA_ON_KILL]:
				found[m.stat] = int(found.get(m.stat, 0)) + 1
	for s in [Stat.MANA_REGEN_FLAT, Stat.DAMAGE_TAKEN_FROM_MANA, Stat.MANA_ON_HIT, Stat.MANA_ON_KILL]:
		_check(int(found.get(s, 0)) >= 1, "el árbol tiene nodos de %s" % Stat.display_name(s))
	var mana_clusters := _tree.clusters.values().filter(func(c: Dictionary) -> bool: return c["theme"] == "mana").size()
	_check(mana_clusters >= 10, "la familia de maná tiene 10 clusters o más (%d)" % mana_clusters)


## Escenarios con tilesets (T105): variantes sin costuras, banda del borde y PNG por estilo.
func _test_tilesets() -> void:
	for style in ZoneArt.STYLES:
		_check(ResourceLoader.exists(ZoneArt.TILE_DIR + style + ".png") and ResourceLoader.exists(ZoneArt.TILE_DIR + style + "_edge.png"),
			"tileset y borde de %s generados" % style)
	var base := ZoneArt.variant_image("forest", 0, false)
	var v2 := ZoneArt.variant_image("forest", 2, false)
	var same_edges := true
	var different := false
	for k in ZoneArt.SIZE:
		for e in [Vector2i(k, 0), Vector2i(k, ZoneArt.SIZE - 1), Vector2i(0, k), Vector2i(ZoneArt.SIZE - 1, k)]:
			same_edges = same_edges and base.get_pixelv(e) == v2.get_pixelv(e)
	for y in range(10, ZoneArt.SIZE - 10, 3):
		for x in range(10, ZoneArt.SIZE - 10, 3):
			different = different or base.get_pixel(x, y) != v2.get_pixel(x, y)
	_check(same_edges, "las variantes tienen los mismos bordes que la base (encajan sin costuras)")
	_check(different, "y por dentro tienen sus propios detalles")
	var sheet := ZoneArt.tileset_image("forest", false)
	_check(sheet.get_width() == ZoneArt.SIZE * ZoneArt.VARIANTS and sheet.get_height() == ZoneArt.SIZE, "tileset de %d baldosas en fila" % ZoneArt.VARIANTS)
	var strip := ZoneArt.edge_image("forest", Color("0a120a"), "thicket", false)
	_check(strip.get_width() == ZoneArt.SIZE and strip.get_height() == ZoneArt.EDGE_H, "banda del borde de 128×16")
	var seamless := true
	for y in ZoneArt.EDGE_H:
		seamless = seamless and strip.get_pixel(0, y).is_equal_approx(strip.get_pixel(ZoneArt.SIZE - 1, y)) or absf(strip.get_pixel(0, y).a - strip.get_pixel(ZoneArt.SIZE - 1, y).a) < 0.5
	_check(seamless, "la banda se repite a lo largo sin saltos bruscos")
	_check(strip.get_pixel(5, 0).a == 1.0 and strip.get_pixel(5, ZoneArt.EDGE_H - 1).a < 0.05, "arriba lo de fuera, abajo transparente (vale sobre cualquier suelo)")
	var counts := [0, 0, 0, 0]
	for y in 40:
		for x in 40:
			counts[ZoneArt.cell_variant(Vector2i(x, y))] += 1
	_check(counts[0] > 600 and counts[1] > 100 and counts[2] > 100 and counts[3] > 100, "la baldosa base es la más común y las variantes salpican (%s)" % [counts])


## Objetos en el suelo y cofres (T104): vuelo en arco, rebote, etiqueta y tapa de la caja.
func _test_ground_loot() -> void:
	var from := Vector2(0, 0)
	var to := Vector2(120, 40)
	_check(LootManager.arc_pos(from, to, 0.0).is_equal_approx(from), "el objeto sale de donde cae")
	var mid := LootManager.arc_pos(from, to, LootManager.FLY_TIME * 0.5)
	_check(mid.y < from.lerp(to, 0.5).y - 30.0, "vuela en arco por encima de la línea recta")
	_check(LootManager.arc_pos(from, to, LootManager.FLY_TIME).distance_to(to) < 0.5, "y aterriza en su sitio")
	_check(LootManager.arc_pos(from, to, LootManager.FLY_TIME + 0.1).y < to.y, "rebota un poco al caer")
	_check(LootManager.arc_pos(from, to, LootManager.FLY_TIME + 1.0).is_equal_approx(to), "y se queda quieto")
	_check(LootManager.label_alpha(0.0) == 0.0 and LootManager.label_alpha(1.0) == 1.0, "la etiqueta aparece cuando ya ha caído")
	var r := Rect2(100, 100, 80, 20)
	_check(LootManager.icon_spot(r).y > r.end.y and is_equal_approx(LootManager.icon_spot(r).x, r.get_center().x), "el icono va debajo de la etiqueta")
	_check(Zone.lid_open(0.0) == 0.0 and is_equal_approx(Zone.lid_open(Zone.CONTAINER_OPEN_TIME), 1.0), "la tapa de la caja se abre del todo")
	var peak := 0.0
	for k in 20:
		peak = maxf(peak, Zone.lid_open(Zone.CONTAINER_OPEN_TIME * k / 20.0))
	_check(peak >= 1.0, "y rebota un poco al abrirse")


## Tokens desde más lejos (T111): imán, radio con el stat y sin atravesar obstáculos.
func _test_token_pickup() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	var pl := Player.new()
	pl.character = c
	var lm := LootManager.new()
	lm.player = pl
	var got := [0]
	lm.tokens_picked.connect(func(n: int) -> void: got[0] += n)
	lm.drop_tokens(7, Vector2(300, 0))
	for k in 120:
		lm._update_coins(1.0 / 60.0)
	_check(got[0] == 7 and lm.coins.is_empty(), "un token a 300 px acaba en la cuenta sin moverse (%d)" % got[0])
	lm.drop_tokens(5, Vector2(500, 0))
	for k in 120:
		lm._update_coins(1.0 / 60.0)
	_check(got[0] == 7, "a 500 px no lo atrae sin el stat")
	c.add_timed_effect("prueba_imán", [Modifier.from_dict({"stat": "token_pickup_radius", "type": "flat", "value": 500}, "prueba")] as Array[Modifier], 99.0)
	_check(is_equal_approx(pl.token_radius_mult(), 1.0 + LootManager.TOKEN_RADIUS_CAP / 100.0), "el radio de recogida tiene tope")
	for k in 120:
		lm._update_coins(1.0 / 60.0)
	_check(got[0] == 12, "con el stat sí lo atrae (%d)" % got[0])
	c.remove_timed_effect("prueba_imán")
	# Una pared entre el token y el jugador: no la atraviesa.
	lm.placement_check = func(p: Vector2) -> bool: return not (p.x > 140.0 and p.x < 180.0)
	lm.drop_tokens(3, Vector2(250, 0))
	for k in 120:
		lm._update_coins(1.0 / 60.0)
	_check(got[0] == 12 and lm.coins.size() == 1 and (lm.coins[0]["pos"] as Vector2).x >= 180.0, "el imán no saca los tokens de detrás de una pared")
	var stats := {}
	for a in DataLoader.load_json("res://data/items/affixes.json")["affixes"]:
		if a["stat"] == "token_pickup_radius":
			stats[a["id"]] = a["allowed"]
	_check(not stats.is_empty() and stats.values()[0].has("ring") and stats.values()[0].has("amulet"), "hay afijo de radio de recogida en anillos y amuletos")
	var tree_has := false
	for n in _tree.nodes.values():
		for m in n.mods:
			if m.stat == Stat.TOKEN_PICKUP_RADIUS:
				tree_has = true
	_check(tree_has, "y nodos del árbol que lo dan")
	lm.free()
	pl.free()


## Waypoints que se descubren de lejos (T112).
func _test_waypoint_reach() -> void:
	var wp := Vector2(1000, 1000)
	var screen := Rect2(wp - Vector2(800, 450), Vector2(1600, 900))
	_check(Zone.waypoint_in_reach(wp + Vector2(400, 0), wp, screen), "a 400 px y en pantalla, el waypoint se descubre")
	_check(Zone.waypoint_in_reach(wp + Vector2(0, 300), wp), "sin saber la pantalla, basta la distancia")
	_check(not Zone.waypoint_in_reach(wp + Vector2(500, 0), wp, screen), "a 500 px todavía no")
	_check(not Zone.waypoint_in_reach(wp + Vector2(400, 0), wp, Rect2(wp + Vector2(100, -450), Vector2(1600, 900))), "ni si queda fuera de la pantalla")


## Solo waypoints entre actos (T113): ninguna salida lleva a un acto anterior, y los
## guardados viejos reciben el waypoint de los campamentos ya alcanzados.
func _test_no_back_portals() -> void:
	var acts := []
	var act_index := {}   # zona -> índice del acto
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var a: Dictionary = DataLoader.load_json(path)
		for z in a.get("zones", []):
			act_index[z["id"]] = acts.size()
		acts.append(a)
	var back := []
	for i in acts.size():
		for z in acts[i].get("zones", []):
			for e in z.get("exits", []):
				if int(act_index.get(e["target"], i)) < i:
					back.append("%s → %s" % [z["id"], e["target"]])
	_check(back.is_empty(), "ninguna salida vuelve a un acto anterior %s" % [back])
	_check(Zone.reached_towns(acts, {}, "act1") == ["campamento"], "al empezar, solo el primer campamento")
	_check(Zone.reached_towns(acts, {"act1_complete": true, "act2_complete": true}, "act1") == ["campamento", "socket_seguro", "puerto_jtag"],
		"tras terminar dos actos, sus campamentos y el siguiente, aunque estés en el primero")
	_check(Zone.reached_towns(acts, {}, "act3").size() == 3, "estar en el Acto III da los campamentos hasta él")


## Prototipo del generador de zonas (T114): garantías en todas las zonas, misma semilla =
## misma zona, semillas distintas = zonas distintas; campamentos y jefes, fijos.
func _test_zone_layout() -> void:
	var generated := 0
	var problems := []
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(path).get("zones", []):
			var def: Dictionary = z.duplicate(true)
			Zone.scale_def(def)
			if not ZoneLayout.applies_to(def):
				_check(bool(def.get("safe", false)) or def.has("boss") or ZoneLayout.FIXED.has(def["id"]), "%s se queda fija por ser campamento, jefe o guiada" % def["id"])
				continue
			for k in 3:
				var l := ZoneLayout.generate(def, 1000 + k)
				var problem := l.check()
				if problem != "":
					problems.append("%s/%d: %s" % [def["id"], k, problem])
				generated += 1
			var a := ZoneLayout.generate(def, 42)
			var b := ZoneLayout.generate(def, 42)
			var c := ZoneLayout.generate(def, 43)
			if a.cells != b.cells or a.exits[0]["pos"] != b.exits[0]["pos"]:
				problems.append("%s: la misma semilla da otra zona" % def["id"])
			if a.cells == c.cells:
				problems.append("%s: dos semillas dan la misma zona" % def["id"])
			for e in a.exits:
				if ZoneLayout.side_of(e["pos"], a.size_px()) != e["side"]:
					problems.append("%s: la salida a %s cambia de lado" % [def["id"], e["target"]])
	_check(generated > 50 and problems.is_empty(), "el generador cumple sus garantías en %d disposiciones %s" % [generated, problems])


## Zonas generadas en el juego (T115): 50 semillas por zona conectadas (la rejilla) y,
## con la zona entera (obstáculos, colisión), 3 por zona: todo punto clave sobre suelo,
## fuera de los obstáculos y alcanzable, y sin tocar la definición original.
func _test_generated_zones() -> void:
	var problems := []
	var zones_done := 0
	var t0 := Time.get_ticks_msec()
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(path).get("zones", []):
			var def: Dictionary = z.duplicate(true)
			Zone.scale_def(def)
			if not ZoneLayout.applies_to(def):
				continue
			zones_done += 1
			for k in 50:
				var problem := ZoneLayout.generate(def, 5000 + k).check()
				if problem != "":
					problems.append("%s/%d: %s" % [def["id"], k, problem])
			var before := JSON.stringify(def)
			for k in 3:
				var zone := Zone.new()
				zone.setup(def, null, null, null, 9000 + k)
				if zone.layout == null:
					problems.append("%s: no se generó" % def["id"])
				else:
					if not zone._all_keys_reachable():
						problems.append("%s/%d: algún punto clave no se alcanza" % [def["id"], k])
					for p in zone.key_points():
						if not zone.rect.has_point(p) or not zone.layout.point_ok(p):
							problems.append("%s/%d: punto clave fuera del suelo en %s" % [def["id"], k, p])
						for o in zone.obstacles:
							if p.distance_to(o["pos"]) < float(o["radius"]):
								problems.append("%s/%d: obstáculo encima de %s" % [def["id"], k, p])
					if not zone.is_walkable(zone.entry_point(""), 18.0):
						problems.append("%s/%d: la entrada no es transitable" % [def["id"], k])
				zone.free()
			if JSON.stringify(def) != before:
				problems.append("%s: la zona generada cambió la definición original" % def["id"])
	_check(zones_done > 15 and problems.is_empty(), "zonas generadas conectadas y con todo en su sitio en %d zonas (%d ms) %s" % [zones_done, Time.get_ticks_msec() - t0, problems.slice(0, 6)])
	var camp := Zone.new()
	camp.setup(_zone_def("campamento"), null, null, null, 1234)
	_check(camp.layout == null and not camp.walk_polygon.is_empty(), "el campamento no se genera aunque haya semilla")
	camp.free()


## Variantes de forma (T116): zonas largas, anchas y con rodeo que de verdad obliga a
## dar la vuelta; las marcas del mapa solo duran lo que su instancia.
func _test_zone_shapes() -> void:
	var def: Dictionary = _zone_def("zona4").duplicate(true)
	Zone.scale_def(def)
	var shapes := {}
	var detours := 0
	var detour_kept := 0
	var detour_cells := 0
	for k in 60:
		var l := ZoneLayout.generate(def, 300 + k)
		shapes[l.shape] = true
		if l.detour.is_empty():
			continue
		detours += 1
		for c in l.detour:
			detour_cells += 1
			if not l.is_floor(c):
				detour_kept += 1
	_check(shapes.has("larga") and shapes.has("ancha") and shapes.has("normal"), "salen zonas normales, largas y anchas %s" % [shapes.keys()])
	_check(detours >= 8 and detour_kept >= detour_cells * 0.9, "zonas con rodeo cuya cresta casi no se cava (%d rodeos, %d de %d celdas en pie)" % [detours, detour_kept, detour_cells])
	# Marcas del mapa: se quedan en la misma instancia y se borran en otra.
	var c := _new_character()
	var z1 := Zone.new()
	z1.setup(def, null, null, null, 77)
	var wm := WorldMap.new()
	wm.character = c
	wm.set_zone(z1)
	wm.toggle_mark(z1.entry_point(""))
	_check(wm.marks().size() == 1, "se puede marcar una zona generada")
	var z1b := Zone.new()
	z1b.setup(def, null, null, null, 77)
	wm.set_zone(z1b)
	_check(wm.marks().size() == 1, "la marca sigue en la misma instancia")
	var z2 := Zone.new()
	z2.setup(def, null, null, null, 78)
	wm.set_zone(z2)
	_check(wm.marks().is_empty(), "y se borra en otra instancia")
	for n in [z1, z1b, z2, wm]:
		n.free()


## Contenido que varía (T117): tema de enemigos, élites, tiempo del estilo, rincón con
## botín, raros en otro sitio; sin cambiar cuántas manadas hay.
func _test_zone_content() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var counts := [0, 0, 0]
	for k in 3000:
		counts[ZoneLayout.pick_weighted([3.0, 1.0, 0.35] as Array[float], 3, rng)] += 1
	_check(counts[0] > counts[1] * 2 and counts[1] > counts[2] * 2, "el sorteo con peso respeta los pesos %s" % [counts])
	_check(ZoneLayout.pick_weighted([] as Array[float], 4, rng) in [0, 1, 2, 3], "sin pesos, todos igual")
	var problems := []
	var treasures := 0
	var themes := {}
	var seeds := 40
	for zid in ["zona2", "zona5", "fosa", "oblea"]:
		var def: Dictionary = _zone_def(zid).duplicate(true)
		Zone.scale_def(def)
		var style := String(def["style"])
		for k in seeds:
			var l := ZoneLayout.generate(def, 700 + k)
			if l.type_weights.size() != def["enemies"]["types"].size() or not l.type_weights.has(3.0) or not l.type_weights.has(0.35):
				problems.append("%s/%d: tema sin tipo que abunde y otro que escasee" % [zid, k])
			themes[l.type_weights.find(3.0)] = true
			if l.elite_mult < 0.7 or l.elite_mult > 1.3:
				problems.append("%s/%d: élites fuera de rango" % [zid, k])
			var w := String(l.ambience.get("weather", "-"))
			if (w == "fog" and not ZoneLayout.FOG_STYLES.has(style)) or (w == "data_rain" and not ZoneLayout.RAIN_STYLES.has(style)):
				problems.append("%s/%d: tiempo %s que no pega con %s" % [zid, k, w, style])
			if l.treasure != Vector2.INF:
				treasures += 1
				if not l.point_ok(l.treasure) or not l._flood(l.cell_of(l.entries.values()[0])).has(l.cell_of(l.treasure)):
					problems.append("%s/%d: el rincón con botín no se alcanza" % [zid, k])
				for p in l.key_points():
					if p.distance_to(l.treasure) < ZoneLayout.CELL * 8.0:
						problems.append("%s/%d: el rincón está junto a un punto clave" % [zid, k])
			var remapped := l.remap_def(def)
			if int(remapped["enemies"]["packs"]) != int(def["enemies"]["packs"]):
				problems.append("%s: cambia el número de manadas" % zid)
	_check(problems.is_empty(), "tema, élites, tiempo y rincón de cada instancia en su sitio %s" % [problems.slice(0, 5)])
	_check(themes.size() >= 3, "el tipo que abunda cambia de una instancia a otra")
	_check(treasures > seeds * 4 * 0.3 and treasures < seeds * 4 * 0.7, "rincón con botín en cerca de la mitad de las instancias (%d de %d)" % [treasures, seeds * 4])
	# Raros con posición (Acto II): en suelo y en otro sitio según la instancia.
	for zid in ["fosa", "memoria_rom"]:   # las zonas con raros de posición fija
		var def: Dictionary = _zone_def(zid).duplicate(true)
		Zone.scale_def(def)
		var a := ZoneLayout.generate(def, 11)
		var b := ZoneLayout.generate(def, 12)
		var ra: Dictionary = a.remap_def(def)["rare_spawns"][0]
		var rb: Dictionary = b.remap_def(def)["rare_spawns"][0]
		_check(a.point_ok(Zone._v(ra["pos"])) and Zone._v(ra["pos"]) != Zone._v(rb["pos"]), "el raro de %s sale sobre suelo y en otro sitio en cada instancia" % zid)


## Instancias de 10 minutos (T118): se guardan, caducan y como mucho 8; la misma semilla
## da las mismas cajas (para restaurar cuáles se abrieron).
func _test_zone_instances() -> void:
	var inst := ZoneInstances.new()
	inst.store("zona1", {"seed": 5}, 100.0)
	_check(int(inst.peek("zona1", 100.0 + ZoneInstances.TTL - 1.0).get("seed", -1)) == 5, "antes de 10 min, la misma instancia")
	_check(is_equal_approx(inst.time_left("zona1", 160.0), ZoneInstances.TTL - 60.0), "y se sabe cuánto le queda")
	_check(inst.peek("zona1", 100.0 + ZoneInstances.TTL + 1.0).is_empty() and inst.size() == 0, "después, caduca y se olvida")
	for k in ZoneInstances.MAX + 2:
		inst.store("z%d" % k, {"seed": k}, float(k))
	_check(inst.size() == ZoneInstances.MAX and inst.peek("z0", 20.0).is_empty() and not inst.peek("z9", 20.0).is_empty(),
		"como mucho %d a la vez: se olvida la que se dejó antes" % ZoneInstances.MAX)
	inst.store("z9", {"seed": 99}, 30.0)
	_check(int(inst.peek("z9", 31.0)["seed"]) == 99, "volver a salir la sustituye y reinicia el reloj")
	var def: Dictionary = _zone_def("zona3").duplicate(true)
	Zone.scale_def(def)
	var a := Zone.new()
	a.setup(def, null, null, null, 4242)
	var b := Zone.new()
	b.setup(def, null, null, null, 4242)
	var same := a.containers.size() == b.containers.size()
	for i in mini(a.containers.size(), b.containers.size()):
		same = same and (a.containers[i]["pos"] as Vector2).is_equal_approx(b.containers[i]["pos"])
	_check(same and a.containers.size() > 0, "la misma semilla da las mismas cajas en el mismo orden")
	# T119: enemigos guardados y restaurados tal cual, sin los que se excluyen.
	var em := EnemyManager.new()
	em.roll_affixes = false
	var e1 := em.spawn(Vector2(100, 100), Rarity.Enemy.ELITE, 0, "Uno")
	em.set_role(e1, "tank")
	var e2 := em.spawn(Vector2(300, 100), Rarity.Enemy.NORMAL, 0)
	var e3 := em.spawn(Vector2(500, 100), Rarity.Enemy.UNIQUE, 0, "Gemelo")
	em.lives[em.index_of(e2)] = 5.0
	var snap := em.snapshot([e3])
	var life1 := em.lives[em.index_of(e1)]
	em.clear_all()
	em.restore(snap)
	_check(em.positions.size() == 2 and not em.rarities.has(Rarity.Enemy.UNIQUE), "se restauran los vivos guardados, sin los excluidos (%d)" % em.positions.size())
	var i1 := em.rarities.find(Rarity.Enemy.ELITE)
	_check(i1 != -1 and is_equal_approx(em.lives[i1], life1) and em.role_of(i1) == "tank" and em.names[i1].begins_with("Uno"),
		"con su vida, su rol, su rareza y su nombre")
	_check(em.lives.has(5.0) and em.positions.has(Vector2(300, 100)), "y el herido sigue herido donde estaba")
	em.free()
	_check(ZoneInstances.clock(452.0) == "7:32" and ZoneInstances.clock(0.2) == "0:01", "el tiempo de la instancia en minutos y segundos")
	var inst2 := ZoneInstances.new()
	inst2.store("zona2", {"seed": 1}, 0.0)
	_check(is_equal_approx(float(inst2.times(60.0).get("zona2", 0.0)), ZoneInstances.TTL - 60.0), "la ventana de waypoints sabe cuánto le queda a cada una")
	var ladder_def := {"id": "banco", "size": [2000, 1400], "waves_mode": {"from": "zona1"}, "enemies": {}}
	_check(not ZoneLayout.applies_to(ladder_def), "el banco de oleadas no se genera")
	a.free()
	b.free()


## Mecánicas de zona (T120): una principal siempre, como mucho un evento menor, las
## fijas mientras no se superan y cada principal posible se coloca en cada zona.
func _test_zone_mechanics() -> void:
	var catalog := ZoneMechanics.data()
	for id in catalog["main"]:
		var m: Dictionary = catalog["main"][id]
		_check(String(m.get("kind", "")) == "fixed" or ZoneEvents.KINDS.has(id), "la mecánica %s la sabe poner ZoneEvents" % id)
		_check(String(m.get("name", "")) != "" and String(m.get("text", "")) != "", "la mecánica %s tiene nombre y frase" % id)
	var problems := []
	var tried := 0
	var rng := RandomNumberGenerator.new()
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act.get("zones", []):
			var def: Dictionary = z.duplicate(true)
			Zone.scale_def(def)
			var combat: bool = not def.get("safe", false) and not def.has("boss") and def.get("enemies") is Dictionary and def["id"] != "tutorial"
			for k in 20:
				rng.seed = 800 + k
				var plan := ZoneMechanics.plan(def, rng, {}, act["id"])
				if combat and String(plan["main"]) == "":
					problems.append("%s: sin mecánica principal" % def["id"])
				if not combat and (String(plan["main"]) != "" or String(plan["minor"]) != ""):
					problems.append("%s: mecánicas donde no tocan" % def["id"])
				if plan["minor"] != "" and catalog["main"].has(plan["minor"]):
					problems.append("%s: dos principales" % def["id"])
			if not combat:
				continue
			for key in ["mutex", "race_condition"]:
				if def.get(key) is Dictionary:
					rng.seed = 1
					_check(ZoneMechanics.plan(def, rng, {}, act["id"])["main"] == key, "%s: su %s es la principal" % [def["id"], key])
					rng.seed = 1
					var after := ZoneMechanics.plan(def, rng, {String(def[key].get("flag", "")): true}, act["id"])
					_check(after["main"] != key and after["main"] != "", "%s: superado el %s, le toca otra" % [def["id"], key])
			# Cada principal que le puede tocar se coloca de verdad en la zona.
			var zone := Zone.new()
			zone.setup(def, null, null, null, 31337)
			for m in ZoneMechanics.candidates(def, act["id"]):
				tried += 1
				var ev := ZoneEvents.new()
				rng.seed = 5
				ev.setup(zone, rng, {"main": m, "minor": "shrine"})
				var mains := ev.events.filter(func(e: Dictionary) -> bool: return e.get("main", false))
				if mains.size() != 1 or ev.events.size() > 2 or (mains[0]["kind"] != m and not (m == "escort" and mains[0]["kind"] == "deploy")):
					problems.append("%s: %s no se colocó (%d eventos)" % [def["id"], m, ev.events.size()])
				ev.free()
			zone.free()
	_check(problems.is_empty() and tried > 40, "reparto de mecánicas en todas las zonas y %d colocadas %s" % [tried, problems.slice(0, 5)])


## Mecánicas nuevas (T121): el Garbage Collector barre y golpea una vez a cada uno (no a
## los únicos) y termina tras sus pasadas; el apagón se completa encendiendo las luces;
## el ticket sale bien si caen los marcados a tiempo y mal si no.
func _test_new_mechanics_t121() -> void:
	var def: Dictionary = _zone_def("zona3").duplicate(true)
	Zone.scale_def(def)
	var c := _new_character()
	var em := EnemyManager.new()
	em.roll_affixes = false
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	var zone := Zone.new()
	zone.setup(def, player, c, null, 2024)
	var ev := ZoneEvents.new()
	ev.zone = zone
	ev.enemies = em
	var results: Array = []
	ev.resolved.connect(func(e: Dictionary, ok: bool) -> void: results.append([e["kind"], ok]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# Garbage Collector.
	var gc := ev._zone_wide("gc", rng, zone.key_points())
	var mid := zone.rect.get_center()
	var normal := em.spawn(mid, Rarity.Enemy.NORMAL, 0)
	var boss := em.spawn(mid + Vector2(0, 60), Rarity.Enemy.UNIQUE, 0)
	em.max_lives[em.index_of(normal)] = 1000.0
	em.lives[em.index_of(normal)] = 1000.0
	player.global_position = mid + Vector2(0, -120)
	var life_before := player.life
	gc["timer"] = 0.0
	for k in 400:
		if int(gc["sweeps"]) >= 1:
			break
		ev._update_gc(gc, player.global_position, 0.05)
	var ni := em.index_of(normal)
	_check(int(gc["sweeps"]) == 1 and ni != -1 and is_equal_approx(em.lives[ni], 1000.0 * (1.0 - ZoneEvents.GC_ENEMY_DAMAGE)),
		"el barrido del GC golpea una sola vez a cada enemigo (%.0f)" % (em.lives[ni] if ni != -1 else -1.0))
	_check(is_equal_approx(em.lives[em.index_of(boss)], em.max_lives[em.index_of(boss)]), "a los únicos y jefes no los toca")
	# Al jugador lo golpea (si no esquiva o bloquea al azar, pierde vida): se mira el golpe, no la vida.
	_check((gc["hit"] as Dictionary).has("player") or player.life < life_before, "y al jugador que pilla, también")
	for k in 4000:
		if gc["state"] == "done":
			break
		ev._update_gc(gc, player.global_position, 0.05)
	_check(gc["state"] == "done" and results.has(["gc", true]) and int(gc["sweeps"]) == ZoneEvents.GC_SWEEPS, "tras sus pasadas el GC termina y sale bien")
	# Apagón del CPD.
	var bo := ev._zone_wide("blackout", rng, zone.key_points())
	var fracs: Array = []
	ev.blackout_changed.connect(func(_e: Dictionary, f: float) -> void: fracs.append(f))
	_check((bo["lights"] as Array).size() >= 4, "el apagón reparte sus luces de emergencia (%d)" % (bo["lights"] as Array).size())
	var lit_points := ev.light_points()
	for l in bo["lights"]:
		ev._update_blackout(bo, l["pos"])
	_check(bo["state"] == "done" and results.has(["blackout", true]) and not fracs.is_empty() and is_equal_approx(fracs[fracs.size() - 1], 1.0),
		"encender todas las luces completa el apagón, poco a poco")
	_check(lit_points.is_empty(), "las luces del apagón solo alumbran si el apagón está en la zona (no lo está en este ZoneEvents)")
	ev.events = [bo]
	_check(ev.light_points().size() == (bo["lights"] as Array).size(), "encendidas, cada luz alumbra")
	# Ticket urgente.
	var a := em.spawn(mid + Vector2(300, 0), Rarity.Enemy.ELITE, 0)
	var b := em.spawn(mid + Vector2(-300, 0), Rarity.Enemy.ELITE, 0)
	var t1 := {"kind": "ticket", "state": "active", "time_left": 10.0, "ids": [a, b], "pos": mid}
	em._remove(em.index_of(a))
	ev._update_ticket(t1, 0.1)
	_check(t1["state"] == "active", "con un marcado vivo, el ticket sigue abierto")
	em._remove(em.index_of(b))
	ev._update_ticket(t1, 0.1)
	_check(t1["state"] == "done" and results.has(["ticket", true]), "sin marcados vivos, el ticket sale bien")
	var c2 := em.spawn(mid, Rarity.Enemy.ELITE, 0)
	var t2 := {"kind": "ticket", "state": "active", "time_left": 0.05, "ids": [c2], "pos": mid}
	ev._update_ticket(t2, 0.1)
	_check(t2["state"] == "done" and results.has(["ticket", false]), "si se acaba el tiempo, sale mal")
	_check(ZoneMechanics.candidates(def, "act1").has("gc") and ZoneMechanics.candidates(def, "act1").has("blackout") and ZoneMechanics.candidates(def, "act1").has("ticket"),
		"las tres pueden tocar en una zona del acto I")
	ev.free()
	zone.free()
	player.queue_free()
	em.free()


## Mecánicas nuevas (T122): las ramas del merge se pelean lejos de ti y cuentan sus bajas;
## el deploy de viernes manda oleadas hasta cerrar el pipeline; la caché caliente da su
## bono, se enfría y se completa; y ninguna principal domina el reparto.
func _test_new_mechanics_t122() -> void:
	var def: Dictionary = _zone_def("zona3").duplicate(true)
	Zone.scale_def(def)
	var c := _new_character()
	var em := EnemyManager.new()
	em.roll_affixes = false
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	var zone := Zone.new()
	zone.setup(def, player, c, null, 4048)
	var ev := ZoneEvents.new()
	ev.zone = zone
	ev.enemies = em
	var results: Array = []
	ev.resolved.connect(func(e: Dictionary, ok: bool) -> void: results.append([e["kind"], ok]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var mid := zone.rect.get_center()
	# Merge conflict.
	var mg := ev._zone_wide("merge", rng, zone.key_points())
	var a := em.spawn(mid, Rarity.Enemy.NORMAL, 0)
	var b := em.spawn(mid + Vector2(60, 0), Rarity.Enemy.NORMAL, 1)
	var boss := em.spawn(mid + Vector2(0, 80), Rarity.Enemy.UNIQUE, 0)
	player.global_position = mid + Vector2(2000, 0)
	ev._update_merge(mg, player.global_position, 0.0)
	_check(ZoneEvents.branch_of(em, em.index_of(a)) != ZoneEvents.branch_of(em, em.index_of(b)) and ZoneEvents.branch_of(em, em.index_of(boss)) == -1,
		"el merge reparte dos ramas por tipo (los únicos, fuera)")
	var life_a := em.lives[em.index_of(a)]
	ev._update_merge(mg, player.global_position, ZoneEvents.MERGE_TICK)
	_check(em.lives[em.index_of(a)] < life_a and not (mg["sparks"] as Array).is_empty(), "las ramas que se cruzan se pegan entre ellas")
	player.global_position = mid + Vector2(10, 0)
	var life_a2 := em.lives[em.index_of(a)]
	ev._update_merge(mg, player.global_position, ZoneEvents.MERGE_TICK)
	_check(is_equal_approx(em.lives[em.index_of(a)], life_a2), "pero si estás cerca, van a por ti")
	player.global_position = mid + Vector2(2000, 0)
	mg["kills"] = ZoneEvents.MERGE_KILLS - 1
	for k in 200:
		if mg["state"] == "done":
			break
		ev._update_merge(mg, player.global_position, ZoneEvents.MERGE_TICK)
	_check(mg["state"] == "done" and results.has(["merge", true]), "con sus bajas, el conflicto se resuelve")
	em.clear_all()
	# Deploy de viernes.
	var fr := ev._zone_wide("friday", rng, zone.key_points())
	var waves: Array = []
	ev.friday_wave.connect(func(_e: Dictionary, at: Vector2) -> void: waves.append(at))
	_check(Vector2(fr["pos"]).distance_to(zone.entry_point("")) > 600.0, "el terminal del pipeline queda lejos de la entrada")
	for k in int(ZoneEvents.FRIDAY_INTERVAL * ZoneEvents.FRIDAY_MAX_WAVES * 2.0):
		ev._update_friday(fr, mid + Vector2(5000, 5000), 1.0)
	_check(waves.size() == ZoneEvents.FRIDAY_MAX_WAVES, "entran oleadas por las salidas, con tope (%d)" % waves.size())
	for k in 40:
		if fr["state"] == "done":
			break
		ev._update_friday(fr, fr["pos"], 0.1)
	_check(fr["state"] == "done" and results.has(["friday", true]), "quedarse en el terminal cierra el pipeline")
	# Caché caliente.
	var hc := ev._zone_wide("hot_cache", rng, zone.key_points())
	var buffs: Array = []
	ev.hot_cache_hit.connect(func(_e: Dictionary, buff: String) -> void: buffs.append(buff))
	_check((hc["tiles"] as Array).size() == ZoneEvents.HOT_CACHE_TILES, "la caché pone sus baldosas")
	var tile: Dictionary = hc["tiles"][0]
	ev._update_hot_cache(hc, tile["pos"], 0.05)
	_check(buffs.size() == 1 and float(tile["cold"]) > 0.0 and ZoneEvents.HOT_CACHE_BUFFS.has(buffs[0]), "pisar una baldosa da su bono y la enfría")
	ev._update_hot_cache(hc, tile["pos"], 0.05)
	_check(buffs.size() == 1, "fría, no da nada")
	for k in 200:
		if hc["state"] == "done":
			break
		for t in hc["tiles"]:
			if float(t["cold"]) <= 0.0:
				ev._update_hot_cache(hc, t["pos"], 0.05)
				break
		ev._update_hot_cache(hc, mid + Vector2(9000, 9000), 1.0)
	_check(hc["state"] == "done" and results.has(["hot_cache", true]) and int(hc["used"]) == ZoneEvents.HOT_CACHE_USES, "usar la caché las veces que pide la completa")
	# Ninguna principal domina.
	var total := 0.0
	var top := 0.0
	for id in ZoneMechanics.candidates(def, "act1"):
		var w := float(ZoneMechanics.info(id).get("weight", 0.0))
		total += w
		top = maxf(top, w)
	_check(ZoneMechanics.candidates(def, "act1").size() >= 8 and top / total < 0.2, "ninguna principal pasa del 20 %% del reparto (%.0f %%)" % (top / total * 100.0))
	ev.free()
	zone.free()
	player.queue_free()
	em.free()


## Salas temáticas (T123): 1-2 por instancia, de su estilo, en un claro y lejos de los
## puntos clave; el rack caído estorba, algunas traen caja y la zona las alumbra.
func _test_set_pieces() -> void:
	var problems := []
	var kinds := {}
	var boxes := 0
	var total := 0
	for zid in ["zona2", "zona4", "zona5", "fosa", "oblea", "post", "alcantarillas"]:
		var def: Dictionary = _zone_def(zid).duplicate(true)
		Zone.scale_def(def)
		var style := String(def["style"])
		for k in 25:
			var l := ZoneLayout.generate(def, 6100 + k)
			if l.set_pieces.size() < 1 or l.set_pieces.size() > 2:
				problems.append("%s/%d: %d salas" % [zid, k, l.set_pieces.size()])
			for sp in l.set_pieces:
				total += 1
				kinds[sp["kind"]] = true
				boxes += 1 if sp["box"] else 0
				var allowed: Array = ZoneLayout.SET_PIECES[sp["kind"]]
				if not allowed.is_empty() and not allowed.has(style):
					problems.append("%s: %s no pega con %s" % [zid, sp["kind"], style])
				if not l._clearing(sp["pos"], ZoneLayout.SET_PIECE_RADIUS * ZoneLayout.CELL):
					problems.append("%s/%d: %s sin sitio" % [zid, k, sp["kind"]])
				for p in l.key_points():
					if p.distance_to(sp["pos"]) < ZoneLayout.CELL * 6.0:
						problems.append("%s/%d: %s pegada a un punto clave" % [zid, k, sp["kind"]])
	_check(problems.is_empty(), "salas temáticas en su sitio y de su estilo %s" % [problems.slice(0, 5)])
	_check(kinds.size() == ZoneLayout.SET_PIECES.size(), "salen todas las salas temáticas %s" % [kinds.keys()])
	_check(boxes > total * 0.2 and boxes < total * 0.6, "algunas traen caja (%d de %d)" % [boxes, total])
	# En la zona: el rack caído pone su obstáculo, la caja aparece y la sala da luz.
	var def5: Dictionary = _zone_def("zona5").duplicate(true)
	Zone.scale_def(def5)
	var checked := {}
	for k in 60:
		var zone := Zone.new()
		zone.setup(def5, null, null, null, 7300 + k)
		for sp in zone.layout.set_pieces:
			var sp_pos: Vector2 = sp["pos"]
			if sp["kind"] == "rack_caido" and not checked.has("rack"):
				checked["rack"] = zone.obstacles.any(func(o: Dictionary) -> bool: return o["kind"] == "rack" and (o["pos"] as Vector2).distance_to(sp_pos) < 150.0)
			if sp["box"] and not checked.has("box"):
				checked["box"] = zone.containers.any(func(c: Dictionary) -> bool: return (c["pos"] as Vector2).distance_to(sp_pos) < 150.0)
			if not checked.has("light"):
				checked["light"] = zone.light_points().any(func(l: Dictionary) -> bool: return (l["pos"] as Vector2).distance_to(sp_pos) < 60.0)
		zone.free()
		if checked.size() == 3:
			break
	_check(checked.get("rack", false) and checked.get("box", false) and checked.get("light", false), "el rack caído estorba, la caja está y la sala da luz %s" % [checked])


## Profundidad (T124): lo alto se transparenta si tapa a alguien, las sombras se alejan
## de la luz, las manchas se quedan con tope y el parallax solo donde fuera es vacío.
func _test_scene_depth() -> void:
	var sprite := Rect2(Vector2(-30, -90), Vector2(60, 100))
	var base := Vector2(0, 10)
	_check(Zone.hides_someone(sprite, base, [Vector2(0, -40)] as Array[Vector2]), "alguien detrás de un rack se ve a través")
	_check(not Zone.hides_someone(sprite, base, [Vector2(0, 30)] as Array[Vector2]) and not Zone.hides_someone(sprite, base, [Vector2(200, -40)] as Array[Vector2]),
		"delante o al lado, no")
	var def: Dictionary = _zone_def("zona4").duplicate(true)
	Zone.scale_def(def)
	var zone := Zone.new()
	zone.setup(def, null, null, null, 515)
	zone._shadow_lights = [Vector2(1000, 1000)] as Array[Vector2]
	var d := zone.shadow_dir(Vector2(1100, 1000))
	_check(d.x > 0.0 and absf(d.y) < 0.01, "la sombra cae lejos de la luz")
	_check(zone.shadow_dir(Vector2(1050, 1000)).length() > d.length(), "y más larga cuanto más cerca está")
	_check(zone.shadow_dir(Vector2(3000, 3000)) == Vector2.ZERO, "sin luz cerca, la de siempre")
	for k in Zone.STAIN_MAX + 20:
		zone.add_stain(Vector2(k, 0), "metal")
	_check(zone.stains.size() == Zone.STAIN_MAX and zone.stains[0]["pos"] == Vector2(20, 0) and zone.stains[0]["kind"] == "oil",
		"las manchas se quedan, con tope (se van las más viejas), y el metal deja aceite")
	zone.add_stain(Vector2.ZERO, "crystal")
	_check(zone.stains[zone.stains.size() - 1]["kind"] == "shards", "el cristal deja esquirlas")
	zone.free()
	var camp := Zone.new()
	camp.setup(_zone_def("campamento"), null, null, null)
	camp.add_stain(Vector2.ZERO, "flesh")
	_check(camp.stains.is_empty() and camp._parallax_kind == "", "en el campamento ni manchas ni parallax")
	camp.free()
	var kinds := {}
	for zid in ["zona3", "zona2", "bus", "anillo0", "zona1"]:
		var z := Zone.new()
		var zd: Dictionary = _zone_def(zid).duplicate(true)
		Zone.scale_def(zd)
		z.setup(zd, null, null, null, 9)
		kinds[zid] = z._parallax_kind
		z.free()
	_check(kinds["zona3"] == "water" and kinds["zona2"] == "abyss" and kinds["bus"] == "void" and kinds["zona1"] == "",
		"parallax de agua, abismo o vacío según el borde; la maleza, no %s" % [kinds])


## Minimapa con niebla (T125): lo que no has visto no se ve, tampoco las salidas ni el
## waypoint; al pasar cerca, aparecen.
func _test_minimap_fog() -> void:
	var def: Dictionary = _zone_def("zona2").duplicate(true)
	Zone.scale_def(def)
	var zone := Zone.new()
	zone.setup(def, null, null, null, 8181)
	var c := _new_character()
	var p: Player = load("res://scenes/game/player.tscn").instantiate()
	p.global_position = zone.entry_point("")
	var wm := WorldMap.new()
	wm.player = p
	wm.character = c
	wm.set_zone(zone)
	var mm := Minimap.new()
	mm.player = p
	mm.zone = zone
	mm.world_map = wm
	var far_exit: Dictionary = {}
	for e in zone.exits:
		if (e["pos"] as Vector2).distance_to(p.global_position) > WorldMap.REVEAL_RADIUS * 2.0:
			far_exit = e
	_check(not far_exit.is_empty() and not mm.seen(far_exit["pos"]), "la salida lejana no sale en el minimapa hasta verla")
	_check(mm.seen(p.global_position), "lo que tienes alrededor, sí")
	p.global_position = far_exit["pos"]
	wm.reveal()
	_check(mm.seen(far_exit["pos"]), "al llegar cerca, la salida aparece")
	_check(not zone.has_waypoint or mm.seen(zone.waypoint) == wm.is_explored(zone.waypoint), "el waypoint, igual que en el mapa grande")
	var mm2 := Minimap.new()
	_check(mm2.seen(Vector2(99999, 99999)), "sin mapa grande (pruebas, herramientas), se ve todo")
	for n in [mm, mm2, wm, zone]:
		n.free()
	p.free()


## Mapa del acto en la ventana de waypoints (T126): cada zona en su sitio (del campamento
## al jefe), las salidas como líneas, y el texto de cada nodo sin spoilers.
func _test_waypoint_map() -> void:
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		var lay := Zone.act_map_layout(act)
		var cells: Dictionary = lay["cells"]
		_check(cells.size() == act["zones"].size(), "%s: todas las zonas en el mapa" % act["id"])
		_check(cells[act["town"]].x <= 1, "%s: el campamento al principio" % act["id"])
		var used := {}
		for id in cells:
			if used.has(cells[id]):
				_check(false, "%s: dos zonas en la misma casilla" % act["id"])
			used[cells[id]] = true
		for z in act["zones"]:
			if z.get("boss") != null:
				_check(cells[z["id"]].x >= int(lay["cols"]) - 2, "%s: la arena del jefe al final" % act["id"])
		_check(not (lay["edges"] as Array).is_empty() and int(lay["cols"]) >= 4, "%s: zonas unidas por sus salidas (%d columnas)" % [act["id"], lay["cols"]])
	var z := {"id": "zona4", "name": "Las Catacumbas", "level": 8}
	var hidden := WaypointPanel.node_text(z, false, true, false, false, 0.0, "")
	_check(hidden.begins_with("???") and hidden.contains("waypoint sin descubrir") and not hidden.contains("nivel"), "zona sin pisar: sin nombre ni nivel")
	var live := WaypointPanel.node_text(z, true, true, true, false, 452.0, "Merge conflict")
	_check(live.contains("Las Catacumbas") and live.contains("nivel 8") and live.contains("7:32") and live.contains("Merge conflict"), "con instancia viva: tiempo y mecánica")
	_check(WaypointPanel.node_text(z, true, true, true, true, 452.0, "x").contains("(aquí)") and not WaypointPanel.node_text(z, true, true, true, true, 452.0, "x").contains("7:32"),
		"donde estás no dice el tiempo (aún no caduca)")
	var inst := ZoneInstances.new()
	inst.store("zona4", {"seed": 1, "mechanic": "Apagón del CPD"}, 0.0)
	inst.store("zona5", {"seed": 2}, 0.0)
	_check(inst.values("mechanic", 1.0) == {"zona4": "Apagón del CPD"}, "la instancia recuerda su mecánica para la ventana")


## Comparar placas y RAM con lo equipado (T127): la placa contra la de la misma habilidad en
## tu barra, con lo que mejora en verde y lo que empeora en rojo; la RAM, en cada placa.
func _test_board_compare() -> void:
	var c := _new_character()
	var equipped := Motherboard.new(_db.skills.skills["barrido"], 3, ["DDR3", "DDR3"] as Array[String])
	c.inventory.boards[0] = equipped
	var better := Motherboard.new(equipped.skill_def, equipped.level + 5, equipped.slots + ["DDR3"] as Array[String])
	_check(ItemTooltip.board_rival(better, c) == equipped and ItemTooltip.board_rival(equipped, c) == null,
		"una placa se compara con la de su habilidad en la barra (la de la barra, con nada)")
	var text := ItemTooltip.build_text(better, c, true)
	_check(text.contains("Frente a la de tu barra") and text.contains("Nivel: %d → %d" % [equipped.level, better.level]) and text.contains(ItemTooltip.UP),
		"y dice en verde lo que mejora (nivel, ranuras, DPS)")
	var worse := Motherboard.new(equipped.skill_def, 1, ["DDR3"] as Array[String])
	if equipped.level > 1:
		_check(ItemTooltip.build_text(worse, c, true).contains(ItemTooltip.DOWN), "y en rojo lo que empeora")
	var other_def: Dictionary = {}
	for id in _db.skills.skills:
		if id != String(equipped.skill_def.get("id", "")) and not c.inventory.boards.any(func(b) -> bool: return b is Motherboard and b.skill_def.get("id", "") == id):
			other_def = _db.skills.skills[id]
			break
	var stranger := Motherboard.new(other_def, 1, ["DDR3"] as Array[String])
	_check(ItemTooltip.build_text(stranger, c, true).contains("No llevas esta habilidad"), "una habilidad que no llevas lo dice")
	_check(not ItemTooltip.build_text(better, c, false).contains("Frente a la de tu barra"), "sin comparar, el tooltip de siempre")
	var any_ram: RamModule = null
	for id in _db.skills.rams:
		var r := RamModule.new(_db.skills.rams[id])
		if r.supports(equipped.skill_def):
			any_ram = r
			break
	if any_ram:
		var rt := ItemTooltip.build_text(any_ram, c, true)
		_check(rt.contains("En tus placas") and rt.contains(String(equipped.skill_def.get("name", ""))), "una RAM dice qué haría en cada placa de tu barra")
	_check(ItemTooltip.wants_compare(better) and ItemTooltip.wants_compare(any_ram) if any_ram else ItemTooltip.wants_compare(better), "placas y RAM se comparan como el equipo")


## HUD de la zona y registro de sucesos (T128): el rótulo dice la mecánica, el registro
## guarda lo último (con tope), plegado cuenta lo nuevo, y se avisa de las instancias con
## botín que van a caducar.
func _test_event_log() -> void:
	var def: Dictionary = _zone_def("zona2").duplicate(true)
	Zone.scale_def(def)
	var zone := Zone.new()
	zone.setup(def, null, null, null, 4321)
	var banner := Zone.banner_text(zone)
	var main := String(zone.mechanic.get("main", ""))
	_check(banner.contains(zone.zone_name) and banner.contains("Nivel de zona") and (main == "" or banner.contains(String(ZoneMechanics.info(main)["name"]))),
		"el rótulo al entrar dice la mecánica de la instancia (%s)" % banner.replace("\n", " / "))
	zone.free()
	var camp := Zone.new()
	camp.setup(_zone_def("campamento"), null, null, null)
	_check(Zone.banner_text(camp) == camp.zone_name, "en el campamento, solo el nombre")
	camp.free()
	var log := EventLog.new()
	root.add_child(log)
	for k in EventLog.MAX_ENTRIES + 5:
		log.add("suceso %d" % k)
	_check(log.entries.size() == EventLog.MAX_ENTRIES and log.entries[0]["text"] == "suceso 5", "el registro guarda los últimos, con tope")
	log.toggle()
	log.add("nuevo 1")
	log.add("nuevo 2")
	_check(log.collapsed and log.unseen == 2 and log.header_text().contains("2 nuevos"), "plegado, cuenta los sucesos nuevos")
	# T167: el registro como consola, el medidor con la fracción de antes, misiones como TODO.
	_check(EventLog.console_line("Botín [raro]", UiStyle.TEXT, 125.0).contains("02:05") and EventLog.console_line("x", UiStyle.TEXT, 0.0).contains("[lb]INFO[rb]")
		and EventLog.console_line("Botín [raro]", UiStyle.TEXT, 0.0).contains("[lb]raro[rb]"), "suceso como línea de consola, con hora y nivel")
	_check(EventLog.level_of(Color("e06c6c")) == "WARN" and EventLog.level_of(Color("6fd36b")) == "OK" and EventLog.level_of(Color("ffff77")) == "INFO",
		"el nivel del suceso sale de su color")
	for f in [0.0, 0.25, 0.5, 0.72, 1.0]:
		var arc := UiStyle.gauge_arc(f)
		_check(absf((arc.y - arc.x) / deg_to_rad(UiStyle.GAUGE_SPAN) - f) < 0.0001, "el medidor llena la misma fracción que el orbe (%.2f)" % f)
	_check(UiStyle.gauge_arc(1.7) == UiStyle.gauge_arc(1.0) and UiStyle.gauge_arc(-1.0).y == UiStyle.gauge_arc(0.0).y, "el medidor no se pasa de lleno ni de vacío")
	_check(QuestTracker.todo_line("Misión", true, false, "#ffffff").begins_with("[color=#8b949e][lb] [rb]") and QuestTracker.todo_line("M", false, true, "#ffffff").contains("[lb]x[rb]"),
		"misiones como lista de TODO (casilla marcada si ya solo falta entregarla)")
	log.toggle()
	_check(not log.collapsed and log.unseen == 0 and log.header_text() == "[–] Registro", "al desplegarlo, se dan por vistos")
	log.queue_free()
	var inst := ZoneInstances.new()
	inst.store("zona2", {"seed": 1, "drops": [{"x": 1}], "coins": []}, 0.0)
	inst.store("zona3", {"seed": 2, "drops": [], "coins": []}, 0.0)
	var soon := inst.expiring(ZoneInstances.TTL - 30.0, 60.0)
	_check(soon.size() == 1 and soon[0][0] == "zona2" and is_equal_approx(float(soon[0][1]), 30.0), "avisa de la instancia con botín que caduca en menos de un minuto (no de la vacía)")
	_check(inst.expiring(10.0, 60.0).is_empty(), "y no antes de tiempo")


## Escenas con dirección (T129): la cámara va al NPC o al jefe y vuelve, alguien camina,
## las bandas entran, el retrato pone cara y saltar la escena lo deja todo en su sitio.
func _test_cutscene_direction() -> void:
	var c := _new_character()
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, EnemyManager.new())
	var zone := Zone.new()
	zone.setup(_zone_def("campamento"), player, c)
	player.global_position = zone.entry_point("")
	var cs := CutscenePlayer.new()
	cs.player = player
	cs.zone = zone
	root.add_child(cs)
	if cs._box == null:
		cs._ready()   # en las pruebas el árbol aún no ha arrancado: _ready no llega solo
	var ada_pos: Vector2 = cs.resolve_point("npc:ada")
	_check(ada_pos != Vector2.INF and cs.resolve_point("npc:nadie") == Vector2.INF and cs.resolve_point([10, 20]) == Vector2(10, 20),
		"la escena encuentra a sus NPC (y no se inventa los que no hay)")
	var root_start: Vector2 = cs.resolve_point("npc:root")
	var done := [false]
	cs.play({"steps": [
		{"effect": "camera", "to": "npc:ada", "zoom": 1.5, "time": 0.5},
		{"effect": "walk", "who": "npc:root", "to": {"by": [100, 0]}, "time": 0.5},
		{"speaker": "ada", "expression": "angry", "text": "Hola."},
	]}, func() -> void: done[0] = true)
	for k in 70:
		cs._process(1.0 / 60.0)
	var cam := player.get_node("Camera2D") as Camera2D
	_check(cam.offset.distance_to(ada_pos - player.global_position) < 20.0 and cam.zoom.x > 1.3, "la cámara se acerca al NPC con zoom (%s)" % cam.offset)
	_check(cs._bars > 0.9, "las bandas de cine entran solas")
	_check(cs.resolve_point("npc:root").distance_to(root_start + Vector2(100, 0)) < 5.0, "el NPC camina hasta su sitio")
	_check(cs._portrait.expression == "angry", "el retrato pone la cara de la línea")
	cs.skip()
	_check(done[0] and not cs.visible and cam.offset == Vector2.ZERO and is_equal_approx(cam.zoom.x, 1.0), "saltar la escena devuelve la cámara y su zoom")
	cs.queue_free()
	zone.free()
	player.queue_free()


## Escenas que faltaban (T130): la llegada a cada campamento (una vez, y no si ese acto ya
## está terminado) y el epílogo de cada jefe tras su escena de derrota.
func _test_missing_scenes() -> void:
	var cutscenes: Dictionary = DataLoader.load_json("res://data/cutscenes.json")["cutscenes"]
	var expected := {"act1": "llegada_campamento", "act2": "llegada_socket", "act3": "llegada_jtag", "act4": "llegada_cmos"}
	for act_id in expected:
		var act: Dictionary = DataLoader.load_json("res://data/%s.json" % act_id)
		var town: Dictionary = act["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == act["town"])[0]
		var first := Zone.pick_entry_cutscene(town.get("cutscene_on_enter"), {})
		_check(first.get("id", "") == expected[act_id], "%s: al llegar al campamento, su escena de llegada" % act_id)
		var seen := Zone.pick_entry_cutscene(town.get("cutscene_on_enter"), {String(first.get("set_flag", "x")): true})
		_check(seen.get("id", "") != expected[act_id], "%s: y solo la primera vez" % act_id)
		_check(Zone.pick_entry_cutscene(town.get("cutscene_on_enter"), {act_id + "_complete": true}).get("id", "") != expected[act_id],
			"%s: con el acto ya terminado (guardados viejos), no" % act_id)
		var boss_zone: Dictionary = act["zones"].filter(func(z: Dictionary) -> bool: return z.has("boss"))[0]
		var death := String(boss_zone["boss"].get("death_cutscene", ""))
		var epilogue := String(cutscenes.get(death, {}).get("on_finish", {}).get("cutscene", ""))
		_check(epilogue != "" and cutscenes.has(epilogue), "%s: tras la derrota del jefe, su epílogo (%s)" % [act_id, epilogue])
	var camp1 := Zone.pick_entry_cutscene(DataLoader.load_json("res://data/act1.json")["zones"].filter(func(z: Dictionary) -> bool: return z["id"] == "campamento")[0]["cutscene_on_enter"],
		{"llegada_campamento_vista": true, "act1_complete": true})
	_check(camp1.get("id", "") == "reunion_campamento", "en el campamento del acto I sigue la reunión tras el jefe")


## Celular (T106): renderizador, horizontal y valores por defecto.
## T165: las dos propuestas de interfaz se leen (contraste WCAG ≥ 4,5 contra el panel) y la
## guía existe.
func _test_ui_proposals() -> void:
	var low := []
	for v in UiProposals.PALETTES:
		for key in ["text", "muted", "accent", "ok"]:
			var ratio := UiProposals.contrast(UiProposals.color(v, key), UiProposals.color(v, "panel"))
			if ratio < 4.5:
				low.append("%s.%s %.1f" % [v, key, ratio])
	_check(low.is_empty(), "las dos propuestas de interfaz tienen contraste suficiente: %s" % [low])
	_check(absf(UiProposals.contrast(Color.WHITE, Color.BLACK) - 21.0) < 0.01, "contraste blanco/negro = 21")
	_check(FileAccess.file_exists("res://docs/estilo_visual.md"), "la guía visual existe")


func _test_mobile_defaults() -> void:
	# T159: Compatibility (OpenGL) en vez de Mobile (Vulkan): con Mobile la interfaz parpadeaba en el teléfono.
	_check(String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "gl_compatibility", "en el celular, el renderizador Compatibility")
	# Ícono de la app (T174): sus tamaños y el motivo dentro de la zona segura del adaptable.
	_check(String(ProjectSettings.get_setting("application/config/icon")) == "res://assets/icons/icon.png", "el proyecto usa el ícono nuevo")
	var sizes := {"icon.png": 1024, "icon_foreground.png": 432, "icon_background.png": 432}
	for file in sizes:
		var img := Image.new()
		var ok := img.load(ProjectSettings.globalize_path("res://assets/icons/" + file)) == OK
		_check(ok and img.get_width() == int(sizes[file]) and img.get_height() == int(sizes[file]), "ícono %s de %d px" % [file, sizes[file]])
		if ok and file == "icon_foreground.png":
			var used := img.get_used_rect()
			var safe := Rect2i(Vector2i(72, 72), Vector2i(288, 288))   # el 66 % del centro de 432
			_check(used.size.x > 150 and safe.encloses(used), "el motivo del ícono adaptable cabe en la zona segura (%s)" % used)
	_check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_SENSOR_LANDSCAPE, "y siempre en horizontal")
	_check(not GameSettings.is_mobile(), "este equipo no cuenta como celular")
	_check(int(GraphicsQuality.preset(2)["lights"]) == 32, "en escritorio, la calidad alta con todas sus luces")
	var cfg := ConfigFile.new()
	cfg.load(GameSettings.PATH)
	GameSettings.force_mobile = true
	_check(int(GraphicsQuality.preset(2)["lights"]) == GraphicsQuality.MOBILE_LIGHTS and int(GraphicsQuality.preset(0)["lights"]) == 10,
		"en el celular, menos luces (la calidad baja ya tiene menos)")
	_check(int(GraphicsQuality.PRESETS[2]["lights"]) == 32, "sin tocar los ajustes de escritorio")
	if not cfg.has_section_key("graphics", "quality"):
		_check(int(GameSettings.get_value("graphics", "quality", 2)) == 1, "calidad media por defecto en el celular")
	if not cfg.has_section_key("interface", "scale"):
		_check(is_equal_approx(float(GameSettings.get_value("interface", "scale", 1.0)), 1.4), "interfaz al 140 % por defecto en el celular")
	_check(int(GameSettings.get_value("prueba_t106", "nada", 7)) == 7, "lo que no tiene valor de celular, igual")
	GameSettings.force_mobile = false
	_check(int(GameSettings.get_value("prueba_t106", "nada", 7)) == 7 and int(GraphicsQuality.preset(2)["lights"]) == 32, "y al dejar de forzarlo, todo como antes")


## Controles táctiles (T107): joystick, apuntado automático y opción para ocultarlos.
func _test_touch_controls() -> void:
	var o := Vector2(100, 100)
	_check(Touch.stick_vector(o, o + Vector2(5, 0)) == Vector2.ZERO, "joystick: zona muerta")
	_check(Touch.stick_vector(o, o + Vector2(Touch.STICK_RADIUS * 3.0, 0)).is_equal_approx(Vector2.RIGHT), "joystick: más allá del borde, a tope")
	var half := Touch.stick_vector(o, o + Vector2(0, -Touch.STICK_RADIUS * 0.6))
	_check(half.y < 0.0 and half.length() > 0.3 and half.length() < 0.8, "joystick: a medias, a medias y hacia arriba (%s)" % half)
	var from := Vector2.ZERO
	var enemies := PackedVector2Array([Vector2(150, 0), Vector2(0, -300), Vector2(-90, 10), Vector2(2000, 0)])
	_check(Touch.aim_index(enemies, from, Vector2.ZERO) == 2, "sin joystick, apunta al más cercano")
	_check(Touch.aim_index(enemies, from, Vector2.UP) == 1, "con el joystick arriba, al de arriba aunque esté más lejos")
	_check(Touch.aim_index(enemies, from, Vector2.RIGHT) == 0, "con el joystick a la derecha, al de la derecha")
	_check(Touch.aim_index(enemies, from, Vector2.DOWN) == 2, "si no hay nadie en esa dirección, al más cercano")
	_check(Touch.aim_index(PackedVector2Array([Vector2(2000, 0)]), from, Vector2.RIGHT) == -1, "fuera de alcance, a nadie")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	Touch.note_event(touch)
	_check(Touch.active, "un toque activa el modo táctil")
	var emulated := InputEventMouseMotion.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.position = Vector2(321, 123)
	Touch.note_event(emulated)
	_check(Touch.active, "el ratón que emula el toque no lo apaga")
	_check(Touch.last_screen == Vector2(321, 123), "y ya lleva al punto tocado (llega antes que el toque)")
	Touch.note_event(InputEventMouseMotion.new())
	_check(not Touch.active, "el ratón de verdad, sí")
	var was := Touch.enabled()
	Touch.force = true
	Touch.set_enabled(true)
	_check(Touch.shown(), "con pantalla táctil, los controles se ven")
	Touch.stick = Vector2.RIGHT
	Touch.set_enabled(false)
	_check(not Touch.shown() and Touch.stick == Vector2.ZERO, "y en Pausa → Controles se ocultan (y sueltan el joystick)")
	Touch.set_enabled(was)
	Touch.force = false
	# Botones (T108): arrastrar desde una habilidad apunta a mano.
	_check(Touch.manual_aim(Vector2(10, 5)) == Vector2.ZERO, "pulsar sin arrastrar: apuntado automático")
	var aim := Touch.manual_aim(Vector2(0, -Touch.MANUAL_AIM_FULL * 2.0))
	_check(aim.is_equal_approx(Vector2.UP), "arrastrar mucho hacia arriba: apunta arriba a tope")
	_check(Touch.manual_target(Vector2(50, 50), aim).is_equal_approx(Vector2(50, 50 - Touch.AIM_RANGE)), "a tope llega al alcance del apuntado")
	var little := Touch.manual_aim(Vector2(Touch.MANUAL_AIM_MIN + 2.0, 0))
	_check(little.x > 0.0 and Touch.manual_target(Vector2.ZERO, little).x < 200.0, "arrastrar poco: cerca y en esa dirección")
	# Ventanas (T109): los clics que simula el dedo no apagan el modo táctil ni el del mando.
	Touch.note_event(touch)
	var simulated := InputEventMouseButton.new()
	simulated.device = Touch.POINTER_DEVICE
	Touch.note_event(simulated)
	Gamepad.active = true
	Gamepad.note_event(simulated)
	_check(Touch.active and Gamepad.active, "los clics del dedo en las ventanas no cuentan como ratón")
	Gamepad.active = false
	Touch.active = false
	# Objetivos táctiles de 44 px como mínimo con la interfaz del celular (140 %).
	var ui := float(GameSettings.MOBILE_DEFAULTS["interface/scale"])
	for s in [Hud.TOUCH_SLOT, Hud.TOUCH_DODGE, Hud.TOUCH_FLASK.x, Hud.TOUCH_MENU.y, TouchPointer.ACTION_SIZE.y, 40.0]:
		_check(s * ui >= 44.0, "objetivo táctil de %d px a 140 %% (≥ 44)" % roundi(s * ui))
	_check(TouchPointer.LONG_PRESS >= 0.4 and TouchPointer.LONG_PRESS <= 0.8, "mantener: medio segundo, ni más ni menos")
	_check(TouchPointer.scroll_for(null, Vector2(0, 40)) == null, "arrastrar sin casilla: no desplaza por su cuenta")
	# Tamaño del mundo (T156): 130 % en el celular, 100 % en el PC, y siempre se ve el alcance
	# del auto-ataque alrededor del jugador (lienzo de 1600×720 y 2400×1080 = 2000×900 y 1600×900 con «expand»).
	var phone := Vector2(2000, 900)
	_check(is_equal_approx(GraphicsQuality.world_zoom(phone, true, -1.0), 1.3), "tamaño del mundo auto en el celular: 130 %")
	_check(is_equal_approx(GraphicsQuality.world_zoom(Vector2(1600, 900), false, -1.0), 1.0), "tamaño del mundo auto en el PC: 100 %")
	_check(GraphicsQuality.WORLD_ZOOM_REACH == SkillController.AUTO_ATTACK_RANGE, "el tope del zoom usa el alcance del auto-ataque")
	for view in [phone, Vector2(1600, 900), Vector2(1600, 1333)]:
		for choice in GraphicsQuality.WORLD_ZOOMS:
			var z := GraphicsQuality.world_zoom(view, true, choice)
			_check(z >= 1.0 and minf(view.x, view.y) / z >= 2.0 * SkillController.AUTO_ATTACK_RANGE,
				"con %s en %s se ve el alcance del auto-ataque (zoom %.2f)" % [choice, view, z])
	# Personajes más grandes (T157): jugador y NPC a la misma escala (PlayerSheet.WORLD_SCALE),
	# un 15 % más; con el tamaño del mundo del celular, ×1,5 respecto a antes (lo pedido: 30-50 %).
	_check(PlayerSheet.WORLD_SCALE >= 1.06 * 1.14, "personajes un 15 % más grandes que antes (1,06)")
	_check(PlayerSheet.WORLD_SCALE / 1.06 * GraphicsQuality.WORLD_ZOOM_TOUCH >= 1.45, "en el celular, al menos ×1,45 que antes")
	var body := Image.new()
	if body.load(ProjectSettings.globalize_path(PlayerSheet.file_of("body"))) == OK:
		var cell := PlayerSheet.region(PlayerSheet.Dir.DOWN, 0)
		var top := int(cell.size.y)
		for y in int(cell.size.y):
			for x in int(cell.size.x):
				if body.get_pixel(int(cell.position.x) + x, int(cell.position.y) + y).a > 0.6:
					top = y
					break
			if top < int(cell.size.y):
				break
		var on_screen := (PlayerSheet.FEET.y - top) * PlayerSheet.WORLD_SCALE / PlayerSheet.BAKE_SCALE * GraphicsQuality.WORLD_ZOOM_TOUCH
		_check(on_screen / 900.0 >= 0.065, "el personaje mide %.1f %% del alto en el celular (≥ 6,5 %%; antes 4,6)" % (on_screen / 9.0))
	else:
		_check(false, "se puede leer la hoja del cuerpo")
	_check(is_equal_approx(EnemyManager.draw_size(11.0), 11.0 * 2.0 * EnemyManager.SPRITE_SCALE), "un enemigo normal se dibuja igual que antes")
	_check(EnemyManager.draw_size(11.0 * 0.75 * 0.8, 1.0) == EnemyManager.MIN_DRAW_SIZE and EnemyManager.draw_size(5.0, 0.8) >= EnemyManager.MIN_DRAW_SIZE,
		"un enjambre pequeño no baja del tamaño mínimo")
	_check(EnemyManager.visual_radius(5.0) * 2.0 >= EnemyManager.MIN_DRAW_SIZE, "la barra y la zona para tocarlo siguen al dibujo")
	# Textos del mundo con el zoom (T158): crecen menos que el dibujo, pero crecen; los números
	# de daño se leen en un celular de 1600×720 (lienzo de 2000×900: 0,8 píxeles reales por píxel).
	var keep_zoom := Accessibility.world_zoom
	var keep_text := Accessibility.world_text
	Accessibility.world_text = 1.0
	Accessibility.world_zoom = 1.0
	_check(Accessibility.world_size(14) == 14, "sin zoom, la letra del mundo como siempre")
	Accessibility.world_zoom = GraphicsQuality.WORLD_ZOOM_TOUCH
	var on := Accessibility.world_size_on_screen(14)
	_check(on > 14.0 and on < 14.0 * GraphicsQuality.WORLD_ZOOM_TOUCH, "con zoom, la letra crece menos que el dibujo (%.1f px)" % on)
	var dmg := Accessibility.world_size_on_screen(roundi(15.0 * DamageNumbers.TOUCH_SIZE)) * 0.8
	_check(dmg >= 18.0, "números de daño de %.1f px reales en 1600×720 (≥ 18)" % dmg)
	Accessibility.world_zoom = keep_zoom
	Accessibility.world_text = keep_text
	# Racha de bajas (T153): se encadena, da velocidad por escalones y tokens al cortarse.
	var ks := KillStreak.new()
	for k in 6:
		ks.add_kill(10.0 + k * 1.0)
	_check(ks.count == 6 and KillStreak.speed_bonus(ks.count) == 10.0, "6 bajas seguidas: racha x6, +10 %% de velocidad")
	_check(not ks.expired(16.0) and ks.expired(18.0), "se corta tras %.1f s sin bajas" % KillStreak.WINDOW)
	_check(ks.end() == 6 and ks.count == 0, "al cortarse se cuenta y vuelve a cero")
	_check(KillStreak.reward_tokens(7) == 0 and KillStreak.reward_tokens(12) == 3, "tokens desde 8 bajas (uno cada cuatro)")
	_check(KillStreak.speed_bonus(16) == 20.0 and KillStreak.speed_bonus(40) == 30.0, "más racha, más velocidad (con tope)")
	ks.add_kill(100.0)
	_check(ks.add_kill(104.0) == 1, "dos bajas lejos: no se encadenan")
	# Números de daño (T152): ventana para sumar y lo guardado como sí/no.
	var nums: Array = []
	DamageNumbers.merge(nums, 7, Vector2.ZERO, 10.0, false, 0.0, DamageNumbers.STACK_WINDOW_TOUCH)
	DamageNumbers.merge(nums, 7, Vector2.ZERO, 15.0, true, 0.6, DamageNumbers.STACK_WINDOW_TOUCH)
	_check(nums.size() == 1 and is_equal_approx(float(nums[0]["amount"]), 25.0) and nums[0]["crit"], "en el celular, dos golpes a 0,6 s se suman en una cifra")
	DamageNumbers.merge(nums, 7, Vector2.ZERO, 5.0, false, 1.0)
	_check(nums.size() == 2, "con la ventana del PC, a 0,4 s ya es otra cifra")
	_check(DamageNumbers.scale_at(0.0, true, 1) > DamageNumbers.scale_at(0.0, false, 1) * 1.35, "el crítico salta más que el normal")
	_check(LootManager.arc_pos(Vector2.ZERO, Vector2(100, 0), LootManager.FLY_TIME + 0.14).y < -6.0, "el botín rebota al caer")
	# Objetivo pegajoso (T150): sigue el mismo mientras esté a tiro; tocar fija.
	var eids := PackedInt32Array([10, 11, 12])
	var epos := PackedVector2Array([Vector2(100, 0), Vector2(130, 10), Vector2(-200, 0)])
	Touch.target_id = -1
	Touch.target_fixed = false
	var first := Touch.pick_target(eids, epos, Vector2.ZERO, Vector2.ZERO)
	_check(first == 0 and Touch.target_id == 10, "sin objetivo: el más cercano")
	_check(Touch.pick_target(eids, epos, Vector2.ZERO, Vector2(0.4, 0.2)) == 0, "un paso del joystick no lo cambia")
	epos[0] = Vector2(105, 0)   # se movió, sigue a tiro
	_check(Touch.pick_target(eids, epos, Vector2.ZERO, Vector2.ZERO) == 0, "si se mueve, sigue siendo el mismo")
	_check(Touch.pick_target(eids, epos, Vector2.ZERO, Vector2.LEFT) == 2, "joystick claramente al otro lado: cambia")
	_check(Touch.lock_at(eids, epos, Vector2(128, 12)) and Touch.target_id == 11 and Touch.target_fixed, "tocar un enemigo lo fija")
	_check(Touch.pick_target(eids, epos, Vector2.ZERO, Vector2.LEFT) == 1, "fijado: aunque el joystick apunte a otro lado")
	var gone := PackedInt32Array([10, 12])
	_check(Touch.pick_target(gone, PackedVector2Array([Vector2(105, 0), Vector2(-200, 0)]), Vector2.ZERO, Vector2.ZERO) == 0 and not Touch.target_fixed,
		"si el fijado muere, otro y ya sin fijar")
	Touch.target_id = -1
	Touch.target_fixed = false
	# Joystick a gusto (T149): sigue al dedo y zona muerta.
	var o2 := Vector2(100, 100)
	_check(Touch.follow_origin(o2, o2 + Vector2(40, 0)) == o2, "sigue al dedo: dentro del radio, la base quieta")
	_check(Touch.follow_origin(o2, o2 + Vector2(Touch.STICK_RADIUS + 50.0, 0)).is_equal_approx(o2 + Vector2(50, 0)), "si te alejas, la base va detrás")
	var tilt := o2 + Vector2(Touch.STICK_RADIUS * 0.2, 0)
	_check(Touch.stick_vector(o2, tilt, Touch.STICK_RADIUS, Touch.DEADZONES["chica"]) != Vector2.ZERO
		and Touch.stick_vector(o2, tilt, Touch.STICK_RADIUS, Touch.DEADZONES["grande"]) == Vector2.ZERO, "zona muerta chica mueve con poco; grande, no")
	# Zona de toque generosa (T148): un poco fuera del dibujo vale; entre dos, el más cercano.
	var big := Rect2(0, 0, 100, 100)
	var small := Rect2(106, 20, 60, 60)
	_check(Touch.nearest_button(Vector2(50, 50), [big, small]) == 0, "en el centro: ese botón")
	_check(Touch.nearest_button(Vector2(-20, 50), [big, small]) == 0, "20 px fuera del borde: todavía cuenta")
	_check(Touch.nearest_button(Vector2(-60, 50), [big, small]) == -1, "lejos: ningún botón")
	_check(Touch.nearest_button(Vector2(104, 50), [big, small]) == 1, "en el hueco entre dos: el más cercano a su tamaño")
	# Registro de misiones en el celular (T146): resumen, recorte por alto y plegado en peleas.
	var V := QuestTracker.View
	_check(QuestTracker.view_for(V.ALL, false, true, 6, 10.0) == V.ALL, "escritorio: lo elegido, siempre")
	_check(QuestTracker.view_for(V.SUMMARY, true, true, 6, INF) == V.FOLDED, "celular en pelea: plegado")
	_check(QuestTracker.view_for(V.ALL, true, false, 6, QuestTracker.height_for(V.SUMMARY, 6) + 1.0) == V.SUMMARY,
		"6 misiones que no caben: solo el resumen")
	_check(QuestTracker.view_for(V.SUMMARY, true, false, 6, 20.0) == V.FOLDED, "ni el resumen cabe: plegado")
	_check(QuestTracker.room(Rect2(1000, 100, 250, 400), [Rect2(1100, 450, 70, 70), Rect2(200, 300, 70, 70)]) == 340.0,
		"alto libre: hasta el botón de su columna (no el de otra)")
	# Tutorial v3: las pasivas al final; quien iba a medias sigue por el mismo paso.
	var tut: Array = DataLoader.load_json("res://data/tutorial.json")["steps"]
	_check(tut[-1]["id"] == "passives", "tutorial: las pasivas, el último paso (en el Sandbox no da para subir de nivel)")
	var v2: Array = TutorialOrder.V2
	_check(tut[TutorialOrder.migrated_step(v2.find("passives"), v2, tut)]["id"] == "passives"
		and tut[TutorialOrder.migrated_step(v2.find("talk_ada"), v2, tut)]["id"] == "talk_ada"
		and TutorialOrder.migrated_step(v2.size(), v2, tut) == tut.size(), "tutorial v2 → v3: mismo paso o terminado")
	# Zona segura (T142b): una muesca normal se respeta; una zona mal informada no mueve nada.
	var canvas := Vector2(2000, 900)
	var win := Vector2(2400, 1080)
	_check(UiStyle.margins_for(Rect2(120, 0, 2240, 1080), win, canvas) == Vector4(100, 0, 33, 0), "muesca de 120 px a la izquierda: 100 de lienzo")
	_check(UiStyle.margins_for(Rect2(0, 0, 1080, 2400), win, canvas) == Vector4.ZERO, "zona segura en la otra orientación: se ignora")
	_check(UiStyle.margins_for(Rect2(600, 0, 1800, 1080), win, canvas).x <= 2000.0 * UiStyle.SAFE_MAX, "margen exagerado: con tope")
	_check(UiStyle.margins_for(Rect2(), win, canvas) == Vector4.ZERO, "sin zona segura: nada")
	# Límite de FPS (T144): automático = sin límite en el PC; en el celular 60, y 30 si va lento.
	var fps_choice_was := GraphicsQuality.fps_choice()
	var auto_fps_was := int(GameSettings.get_value("graphics", "auto_fps", 60))
	GameSettings.set_value("graphics", "max_fps", -1)
	GameSettings.set_value("graphics", "auto_fps", 60)
	GameSettings.force_mobile = false
	_check(GraphicsQuality.effective_fps() == 0 and not GraphicsQuality.auto_measured(20.0), "en el PC, auto: sin límite y no se toca")
	GameSettings.force_mobile = true
	_check(GraphicsQuality.effective_fps() == 60, "en el celular, auto: 60 de entrada")
	_check(not GraphicsQuality.auto_measured(58.0) and GraphicsQuality.effective_fps() == 60, "si va bien, se queda en 60")
	_check(GraphicsQuality.auto_measured(41.0) and GraphicsQuality.effective_fps() == 30, "si va lento, baja a 30")
	GameSettings.set_value("graphics", "max_fps", 60)
	_check(not GraphicsQuality.auto_measured(20.0) and GraphicsQuality.effective_fps() == 60, "con un límite elegido, no se toca")
	GameSettings.force_mobile = false
	GameSettings.set_value("graphics", "max_fps", fps_choice_was)
	GameSettings.set_value("graphics", "auto_fps", auto_fps_was)
	GraphicsQuality.apply_fps()
	# Vibración (T143): con respiro entre pulsos, salvo los importantes; apagable.
	var touch_force_was := Touch.force
	var vib_was := Haptics.enabled()
	Touch.force = true
	Haptics.set_enabled(true)
	Haptics._last = 100.0
	_check(not Haptics.would_pulse("crit", 100.05) and Haptics.would_pulse("crit", 100.2), "críticos seguidos: con respiro")
	_check(Haptics.would_pulse("level", 100.01) and Haptics.would_pulse("unique", 100.01), "subir de nivel y un único: siempre")
	Haptics.set_enabled(false)
	_check(not Haptics.would_pulse("level", 200.0), "apagada: nada")
	Haptics.set_enabled(vib_was)
	Touch.force = touch_force_was
	_check(not Haptics.would_pulse("nada", 300.0), "causa desconocida: nada")
	# Versión del juego (T139): una sola fuente y «v3.1» sin el «.0».
	_check(GameVersion.full().split(".").size() == 3, "project.godot lleva la versión (%s)" % GameVersion.full())
	_check(GameVersion.short("3.1.0") == "v3.1" and GameVersion.short("3.1.2") == "v3.1.2" and GameVersion.short("4.0.0") == "v4.0",
		"versión corta: v3.1, v3.1.2, v4.0")
	# Aviso de actualización (T140): solo con una versión más nueva y descarga https.
	_check(UpdateCheck.compare("3.10.0", "3.9.2") == 1 and UpdateCheck.compare("3.1", "3.1.0") == 0 and UpdateCheck.compare("3.0.9", "3.1.0") == -1,
		"comparar versiones número a número")
	var newer := UpdateCheck.newer('{"version": "3.2.0", "url": "https://github.com/a/b/releases/download/v3.2.0/PathOverflow.apk", "notes": "Más botones"}', "3.1.0")
	_check(newer.get("version") == "3.2.0" and String(newer.get("url")).ends_with(".apk"), "latest.json más nuevo: se avisa")
	_check(UpdateCheck.newer('{"version": "3.1.0", "url": "https://x/y.apk"}', "3.1.0").is_empty(), "la misma versión: nada")
	_check(UpdateCheck.newer('{"version": "9.0.0", "url": "http://x/y.apk"}', "3.1.0").is_empty(), "sin https: nada")
	_check(UpdateCheck.newer("<html>no es json</html>", "3.1.0").is_empty(), "respuesta rara: nada")
	# Ayudas para el dedo (T138): con controles táctiles, el texto «_touch» si lo hay.
	var force_was := Touch.force
	var tip := {"text": "Pulsa Espacio", "text_touch": "Toca la esquiva"}
	Touch.force = true
	_check(Touch.text(tip) == "Toca la esquiva" and Touch.text({"text": "solo"}) == "solo", "con el dedo: el texto táctil (o el de siempre)")
	Touch.force = false
	_check(Touch.text(tip) == "Pulsa Espacio" or DisplayServer.is_touchscreen_available(), "con teclado: el de teclas")
	Touch.force = force_was
	var key_words := RegEx.create_from_string("(?i)\\b(click|clic|tecla|teclas|espacio|tab|ratón|mouse)\\b")
	# Mayúsculas sueltas (la «y» y la «e» son palabras; «Pídele» o «B.O.B.» no son teclas).
	var key_letters := RegEx.create_from_string("(?<![\\p{L}.])[QWERTCIKPB](?![\\p{L}.])")
	var has_keys := func(s: String) -> bool:
		s = s.replace("(☰ y luego I)", "").replace("(☰ y luego K)", "").replace("(☰ y luego P)", "")
		return key_words.search(s) != null or key_letters.search(s) != null
	for st in DataLoader.load_json("res://data/tutorial.json")["steps"]:
		if has_keys.call(String(st["text"])):
			_check(st.has("text_touch") and not has_keys.call(String(st["text_touch"])), "tutorial «%s»: versión para el dedo sin teclas" % st["id"])
	# Editor de disposición (T137): mover y escalar un botón, con tope, y restaurar.
	var custom_was := Touch.custom.duplicate(true)
	var opacity_was := Touch.button_opacity
	Touch.custom = {}
	var base := Rect2(100, 100, 60, 60)
	_check(Touch.customized("dodge", base) == base, "sin editar: en su sitio")
	Touch.adjust("dodge", Vector2(30, -20))
	Touch.adjust("dodge", Vector2.ZERO, 1.5)
	var moved := Touch.customized("dodge", base)
	_check(moved.get_center().is_equal_approx(base.get_center() + Vector2(30, -20)) and is_equal_approx(moved.size.x, 90.0),
		"editor: movido 30,-20 y al 150 %% (%s)" % moved)
	for k in 10:
		Touch.adjust("dodge", Vector2.ZERO, 2.0)
	_check(is_equal_approx(Touch.customized("dodge", base).size.x, 60.0 * Touch.CUSTOM_SCALE.y), "el tamaño tiene tope")
	Touch.button_opacity = 0.4
	Touch.reset_custom()
	_check(Touch.customized("dodge", base) == base and Touch.button_opacity == 1.0, "Restaurar: todo en su sitio y opaco")
	Touch.custom = custom_was
	Touch.button_opacity = opacity_was
	_test_prologue_touch()


## Prólogo en el celular (T132): joystick, botón de usar y su texto sin tecla.
func _test_prologue_touch() -> void:
	# (por ruta: Prologue usa autoloads y no compila mientras se compila este archivo)
	var script: GDScript = load("res://scripts/prologue/prologue.gd")
	_check(script.touch_use_text("E · Hablar con Rafa") == "Hablar con Rafa", "botón de usar: sin la tecla")
	_check(script.touch_use_text("Mirar la TV") == "Mirar la TV", "botón de usar: sin tecla, igual")
	# El joystick, el botón y los toques en el escenario: capture_screens -- prologo tactil.
	_test_touch_pickup()


## Botón de usar y recogida cómoda (T134): el más raro primero, mantener = todo en
## orden, recoger solo al pasar y etiquetas más fáciles de tocar.
func _test_touch_pickup() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	var pl := Player.new()
	pl.character = c
	pl.life = 100.0
	var lm := LootManager.new()
	lm.player = pl
	lm.inventory = c.inventory
	var gen := ItemGenerator.new(_db, 7)
	var normal := gen.generate(5, Rarity.Item.NORMAL)
	var rare := gen.generate(5, Rarity.Item.RARE)
	var ultra := gen.generate(5, Rarity.Item.ULTRA_RARE)
	var rules_were: Dictionary = LootFilter.rules().duplicate(true)
	LootFilter.apply_preset("todo")
	lm.drop_item(normal, Vector2(20, 0))
	lm.drop_item(rare, Vector2(120, 0))
	lm.drop_item(ultra, Vector2(400, 0))
	var at := func(item: Item) -> int:
		for i in lm.drops.size():
			if lm.drops[i]["item"] == item:
				return i
		return -1
	_check(lm.best_near(Vector2.ZERO, 160.0) == at.call(rare), "botón de usar: el raro antes que el normal, aunque esté más lejos")
	_check(lm.best_near(Vector2.ZERO, 600.0) == at.call(ultra), "y el ultra-raro antes que el raro (el enum no va en orden)")
	_check(lm.best_near(Vector2(2000, 0), 160.0) == -1, "nada cerca: sin botón")
	lm.pick_all_near(Vector2.ZERO, 600.0)
	var order: Array = [lm._pending.get("item")]
	for d in lm._queue:
		order.append(d["item"])
	_check(order == [ultra, rare, normal], "mantener: recoge todo, de más raro a menos")
	# Llegar a cada uno en orden: los va metiendo en la bolsa.
	for k in 3:
		pl.global_position = (lm._pending["rect"] as Rect2).get_center()
		lm._physics_process(1.0 / 60.0)
	_check(lm.drops.is_empty() and c.inventory.bag.has(ultra) and c.inventory.bag.has(normal), "y llega a recogerlos todos (%d en el suelo)" % lm.drops.size())
	# Recoger solo al pasar: solo lo de la rareza elegida o más.
	var magic := gen.generate(5, Rarity.Item.MAGIC)
	var rare2 := gen.generate(5, Rarity.Item.RARE)
	lm.drop_item(magic, Vector2(0, 0))
	lm.drop_item(rare2, Vector2(0, 0))
	for d in lm.drops:
		d["age"] = 9.0   # ya cayeron
	var auto_was := LootManager.auto_pickup_min
	LootManager.auto_pickup_min = -1
	pl.global_position = Vector2.ZERO
	lm._physics_process(1.0 / 60.0)
	_check(lm.drops.size() == 2, "recoger solo apagado: nada se recoge sin tocar")
	LootManager.auto_pickup_min = LootFilter.step_of(Rarity.Item.RARE)
	for k in 3:
		pl.global_position = (lm.drops[0]["rect"] as Rect2).get_center() if lm.drops.size() > 0 else Vector2.ZERO
		lm._physics_process(1.0 / 60.0)
		pl.global_position = (lm.drops[-1]["rect"] as Rect2).get_center() if lm.drops.size() > 0 else Vector2.ZERO
		lm._physics_process(1.0 / 60.0)
	_check(c.inventory.bag.has(rare2) and not c.inventory.bag.has(magic), "recoger solo «raro o más»: el raro sí, el mágico no")
	LootManager.auto_pickup_min = auto_was
	# Etiquetas más fáciles de tocar con el dedo.
	var label := Rect2(100, 100, 80, 20)
	var was_active := Touch.active
	Touch.active = false
	_check(LootManager.hit_rect(label) == label, "con ratón: solo la etiqueta")
	Touch.active = true
	var hit := LootManager.hit_rect(label)
	_check(hit.size.y >= LootManager.TOUCH_TARGET_HEIGHT and hit.encloses(label) and hit.has_point(LootManager.icon_spot(label)),
		"con el dedo: la etiqueta, su icono y 44 px de alto como mínimo (%s)" % hit)
	Touch.active = was_active
	LootFilter.rules().merge(rules_were, true)
	lm.free()
	pl.free()


## NPC, jefes y retratos (T103): poses de los NPC y la entrada de jefe.
func _test_npcs_and_boss_intro() -> void:
	var idle := Zone.npc_pose(0, 1.0, false)
	_check(idle["state"] == "idle", "un NPC en reposo respira")
	_check(Zone.npc_pose(1, 1.0, false)["time"] != idle["time"], "cada NPC respira a su ritmo")
	var talk := Zone.npc_pose(0, 1.0, true)
	_check(talk["state"] == "cast" and float(talk["t"]) >= 0.25 and float(talk["t"]) <= 0.75, "al hablar gesticula con los brazos")
	_check(PlayerSheet.group_for(String(talk["state"]), "") == "cast", "el gesto usa los cuadros de lanzar de la hoja")
	# NPC con identidad (T162): su objeto, su reposo y ninguno igual a otro.
	_check(Zone.npc_pose(0, 1.0, false, "type")["state"] == "type" and PlayerSheet.group_for("type", "") == "type", "teclear tiene sus cuadros")
	_check(Zone.npc_pose(0, 0.7, false, "sip")["state"] == "cast" and Zone.npc_pose(0, 3.0, false, "sip")["state"] == "idle",
		"el sorbo de café llega cada %.0f s y luego vuelve a respirar" % Zone.SIP_EVERY)
	var npc_db: Dictionary = Zone.npc_database().get("npcs", {})
	var looks_by_person := {}
	var bad_props := []
	for id in npc_db:
		var npc: Dictionary = npc_db[id]
		var look := CharacterAppearance.sanitize(npc.get("appearance", {}))
		var gear := String(npc.get("appearance", {}).get("gear", ""))
		if gear != "" and not CharacterAppearance.GEARS.has(gear):
			bad_props.append(id)
		if not String(npc.get("idle", "")) in ["", "type", "sip"]:
			bad_props.append(id + " (idle)")
		var person := String(npc["name"]).split(" ")[0].trim_suffix(",")   # Rafa y «Rafa (en persona)» son el mismo
		var key := JSON.stringify(look, "", true)
		if looks_by_person.has(key) and looks_by_person[key] != person:
			_check(false, "%s se ve igual que %s" % [person, looks_by_person[key]])
		looks_by_person[key] = person
	_check(bad_props.is_empty(), "cada objeto e «idle» de npcs.json existe: %s" % [bad_props])
	_check(CharacterAppearance.NPC_PROPS.all(func(p: String) -> bool: return PlayerSprite.texture_of("gear", CharacterAppearance.GEARS.find(p)) != null),
		"cada objeto de NPC está horneado")
	_check(BossIntro.slide_at(0.0) == 0.0 and BossIntro.slide_at(BossIntro.ENTER + 0.5) == 1.0 and is_zero_approx(BossIntro.slide_at(BossIntro.total_time() + 0.01)),
		"la entrada de jefe entra, se queda y se va")
	_check(BossIntro.total_time() < 3.0, "y dura poco (no para el juego)")


## Personaje por capas (T102a): cuadrícula, poses, clasificación de capas y hojas horneadas.
func _test_player_sheet() -> void:
	_check(PlayerSheet.columns() == 36 and PlayerSheet.frames_of("walk") == 8 and PlayerSheet.frames_of("type") == 2, "36 columnas de estados, 8 al andar y 2 al teclear (%d)" % PlayerSheet.columns())
	_check(PlayerSheet.group_for("attack", "sword") == "attack_swing" and PlayerSheet.group_for("attack", "dagger") == "attack_thrust"
		and PlayerSheet.group_for("attack", "") == "attack_thrust" and PlayerSheet.group_for("run", "") == "walk", "cada arma con su gesto; correr usa andar")
	var walk := {}
	for k in 24:
		walk[PlayerSheet.column_for("walk", "", 0.0, 0.0, k / 24.0 * TAU)] = true
	_check(walk.size() == PlayerSheet.frames_of("walk"), "al andar pasa por sus %d cuadros" % PlayerSheet.frames_of("walk"))
	_check(PlayerSheet.column_for("dead", "", 1.0) == PlayerSheet.first_column("dead") + PlayerSheet.frames_of("dead") - 1, "al morir, el último cuadro")
	for col in PlayerSheet.columns():
		var p := PlayerSheet.pose_for(col)
		var back := PlayerSheet.column_for(String(p["state"]), "sword" if col >= PlayerSheet.first_column("attack_swing") and col < PlayerSheet.first_column("attack_thrust") else "",
			float(p["t"]), float(p["time"]), float(p["walk_phase"]))
		if back != col:
			_check(false, "la columna %d se hornea con una pose que vuelve a ella (sale %d)" % [col, back])
			break
	_check(PlayerSheet.dir_for(Vector2.LEFT) == [PlayerSheet.Dir.SIDE, true] and PlayerSheet.dir_for(Vector2.UP) == [PlayerSheet.Dir.UP, false]
		and PlayerSheet.dir_for(Vector2.DOWN) == [PlayerSheet.Dir.DOWN, false], "dirección y volteo")
	_check(PlayerSheet.classify(Color(1, 0, 0)) == PlayerSheet.LAYER_SKIN and PlayerSheet.classify(Color(0, 0.6, 0)) == PlayerSheet.LAYER_OUTFIT
		and PlayerSheet.classify(Color(0.7, 0.7, 0)) == PlayerSheet.LAYER_HAIR and PlayerSheet.classify(Color(0, 0.8, 0.8)) == PlayerSheet.LAYER_EYES
		and PlayerSheet.classify(Color(0.3, 0.3, 0.32)) == 0, "cada color puro es su capa; los grises, fijos")
	# Hojas horneadas (T160: un archivo por variante, 96×120 por cuadro): tamaño y algo
	# dibujado en cada variante.
	_check(PlayerSheet.CW * PlayerSheet.columns() <= 4096, "las hojas caben en una textura de 4096 px de ancho")
	var rows := {"body": 1, "hair": CharacterAppearance.OFFICE_HAIR_COUNT, "beard": CharacterAppearance.BEARD_NAMES.size() - 1,
		"accessory": CharacterAppearance.ACCESSORY_NAMES.size() - 1, "weapon": PlayerSheet.WEAPONS.size()}
	for layer in rows:
		var empty := []
		for v in int(rows[layer]):
			var tex := PlayerSprite.texture_of(layer, v)
			if tex == null or tex.get_width() != PlayerSheet.CW * PlayerSheet.columns() or tex.get_height() != PlayerSheet.CH * PlayerSheet.DIRS:
				_check(false, "hoja %s %d horneada con su cuadrícula" % [layer, v])
				continue
			var img := tex.get_image()
			# Los lentes son solo colores fijos (montura y cristal): van en accessory_fixed.
			var extra: Image = PlayerSprite.texture_of("accessory_fixed", v).get_image() if layer == "accessory" else null
			var r := PlayerSheet.region(PlayerSheet.Dir.DOWN, PlayerSheet.first_column("attack_swing") + 1)
			var solid := false
			for y in range(int(r.position.y), int(r.end.y)):
				for x in range(int(r.position.x), int(r.end.x)):
					if img.get_pixel(x, y).a > 0.08 or (extra != null and extra.get_pixel(x, y).a > 0.5):
						solid = true
						break
				if solid:
					break
			if not solid and not (layer == "hair" and v == 0):   # rapado: casi nada que dibujar
				empty.append(v)
		_check(empty.is_empty(), "todas las variantes de %s tienen algo dibujado: %s" % [layer, empty])
	# Las máscaras guardan la capa en G (×8) y la luz en R.
	var body := PlayerSprite.texture_of("body").get_image()
	var layers := {}
	for y in range(0, PlayerSheet.CH):
		for x in range(0, PlayerSheet.CW):
			var c := body.get_pixel(x, y)
			if c.a > 0.5:
				layers[roundi(c.g * 8.0)] = true
	_check(layers.has(PlayerSheet.LAYER_SKIN) and layers.has(PlayerSheet.LAYER_OUTFIT) and layers.has(PlayerSheet.LAYER_ACCENT), "el cuerpo tiene piel, atuendo y detalles")
	# T163: vida encima de los cuadros: respira poco, rebota al andar y se estira al golpear.
	var breath_max := 0.0
	for k in 40:
		var s: Vector2 = PlayerSprite.life({"state": "idle", "time": k * 0.1}, -1.0)[0]
		breath_max = maxf(breath_max, maxf(absf(s.x - 1.0), absf(s.y - 1.0)))
	_check(breath_max > 0.005 and breath_max <= 0.04, "respira, pero nunca más de ±4 %% (%.3f)" % breath_max)
	var landing: Array = PlayerSprite.life({"state": "walk"}, 0.0)
	var mid_step: Array = PlayerSprite.life({"state": "walk"}, PI * 0.5)
	_check((landing[0] as Vector2).y < 1.0 and is_zero_approx(float(landing[1])) and float(mid_step[1]) < 0.0, "al pisar se aplasta en el suelo y entre pisadas se eleva")
	var imp := CharacterAppearance.impact_fraction("attack", "sword")
	var hit: Vector2 = PlayerSprite.life({"state": "attack", "t": imp, "weapon": "sword"}, -1.0)[0]
	var early: Vector2 = PlayerSprite.life({"state": "attack", "t": 0.0, "weapon": "sword"}, -1.0)[0]
	_check(hit.x > early.x and hit.x <= 1.0 + PlayerSprite.HIT_STRETCH + 0.001, "se estira justo al llegar el golpe")
	for state in ["idle", "walk", "attack", "shoot", "cast", "channel", "hurt", "dodge", "dead", "type"]:
		var group := PlayerSheet.group_for(state, "sword")
		var first := PlayerSheet.first_column(group)
		for t in [0.0, 0.5, 0.99]:
			var col := PlayerSheet.column_for(state, "sword", t, t * 3.0, t * TAU if state == "walk" else -1.0)
			if col < first or col >= first + PlayerSheet.frames_of(group):
				_check(false, "%s con t=%.2f sale de sus cuadros (%d)" % [state, t, col])
	# T176: el alumno del estilo del usuario (StudentHero): capas importadas de la lámina,
	# recoloreado con el creador, el equipo cambia su look y cada cuadro tiene dibujo sin flotar.
	_check(StudentHero.available(), "el arte del alumno está importado (assets/sprites/hero)")
	for name in ["head_b", "torso_b", "legs_b", "head_c", "torso_c", "legs_c", "head_d", "torso_d", "legs_d", "torso_e", "weapon_sword", "weapon_dagger", "weapon_staff"]:
		var layer := StudentHero._layer(name)
		_check(layer != null and layer.get_size() == StudentHero.CELL and layer.get_used_rect().size != Vector2i.ZERO, "capa %s importada y con dibujo" % name)
	for slot in StudentHero.LOOKS:
		for base_id in StudentHero.LOOKS[slot]:
			_check(StudentHero._layer(("head_" if slot == "helmet" else ("legs_" if slot == "boots" else "torso_")) + String(StudentHero.LOOKS[slot][base_id])) != null,
				"la base %s tiene su capa" % base_id)
	var red := CharacterAppearance.sanitize({"hair_color": "c03030", "outfit_color": "30a040"})
	var plain := StudentHero.figure(StudentHero.look_of(red, {}))
	var hair_px := plain.get_pixel(30, 18)
	_check(hair_px.r > hair_px.g and hair_px.r > hair_px.b, "el pelo toma el color del creador (%s)" % hair_px.to_html(false))
	var armored := StudentHero.figure(StudentHero.look_of(red, {"body": "cota_de_placas", "helmet": "casco_de_hierro"}))
	var changed := 0
	for y in StudentHero.CELL.y:
		for x in StudentHero.CELL.x:
			if not plain.get_pixel(x, y).is_equal_approx(armored.get_pixel(x, y)):
				changed += 1
	_check(changed > 300, "ponerse casco y armadura cambia el look (%d píxeles)" % changed)
	var hero := StudentHero.build(StudentHero.look_of(red, {}), "sword")
	_check(hero.get_width() == StudentHero.CELL.x * StudentHero.columns() and hero.get_height() == StudentHero.CELL.y * StudentHero.DIRS,
		"la hoja del alumno tiene un cuadro por pose y una fila por dirección")
	var bad_hero := []
	for dir in StudentHero.DIRS:
		for c in StudentHero.columns():
			var used := hero.get_region(Rect2i(c * StudentHero.CELL.x, dir * StudentHero.CELL.y, StudentHero.CELL.x, StudentHero.CELL.y)).get_used_rect()
			if used.size == Vector2i.ZERO or used.end.y - 1 < StudentHero.FEET.y - 2:
				bad_hero.append("%d/%d (%s)" % [dir, c, used])
	_check(bad_hero.is_empty(), "cada cuadro del alumno, en cada dirección, tiene dibujo y no flota: %s" % [bad_hero])
	# T181: de espaldas no hay ojos ni camisa blanca; de lado los ojos miran hacia donde va.
	var front := StudentHero.figure(StudentHero.look_of(red, {}), StudentHero.Dir.FRONT)
	var back := StudentHero.figure(StudentHero.look_of(red, {}), StudentHero.Dir.BACK)
	var side := StudentHero.figure(StudentHero.look_of(red, {}), StudentHero.Dir.SIDE)
	var count_color := func(img: Image, hex: String) -> int:
		var n := 0
		for y in StudentHero.CELL.y:
			for x in StudentHero.CELL.x:
				if img.get_pixel(x, y).to_html(false) == hex:
					n += 1
		return n
	_check(count_color.call(front, "ffffff") > 0 and count_color.call(back, "ffffff") == 0 and count_color.call(back, "ececf0") == 0,
		"de espaldas no se ven los ojos ni la camisa")
	# T177: cada arma del juego tiene su sprite y es el que lleva el alumno en la mano.
	var bases_json = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/bases.json"))
	var no_art := []
	for b in bases_json["bases"]:
		if String(b.get("slot", "")) == "weapon":
			var layer := WeaponArt.layer(String(b["id"]), StudentHero.CELL, StudentHero.GRIP)
			if not WeaponArt.ART.has(String(b["id"])) or layer == null or layer.get_used_rect().size == Vector2i.ZERO:
				no_art.append(b["id"])
			elif layer.get_pixelv(StudentHero.GRIP).a <= 0.0:
				no_art.append(String(b["id"]) + " (sin agarre en la mano)")
	_check(no_art.is_empty(), "cada arma tiene su sprite con el agarre en la mano: %s" % [no_art])
	_check(WeaponArt.art_for("nada", "mace") == "maza_de_depuracion" and WeaponArt.art_for("teclado_rgb", "mace") == "teclado_rgb", "sin base conocida, el arma de su tipo")
	var with_keyboard := StudentHero.build(StudentHero.look_of(red, {"weapon": "teclado_mecanico"}), "mace")
	var with_mace := StudentHero.build(StudentHero.look_of(red, {"weapon": "maza_de_depuracion"}), "mace")
	_check(with_keyboard.get_data() != with_mace.get_data(), "dos mazas distintas (teclado y maza) se ven distintas en la mano")
	_check(StudentHero.equipped_of_save({"inventory": {"equipment": {"weapon": {"base": "teclado_rgb"}}}})["weapon"] == "teclado_rgb", "la lista de personajes sabe qué arma lleva")
	# T178: los NPC del servidor, con el estilo del alumno: equipo de su arquetipo y su
	# objeto en la mano; ninguno se ve igual a otro (los «_bios» son los mismos personajes).
	var npc_db: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))["npcs"]
	var npc_sheets := {}
	var npc_bad := []
	for npc_id in npc_db:
		var npc: Dictionary = npc_db[npc_id]
		if npc.get("terminal", false) or String(npc_id).ends_with("_bios"):
			continue
		var nl: Array = StudentHero.npc_look(npc)
		var gear := String(npc.get("appearance", {}).get("gear", ""))
		if gear in CharacterAppearance.NPC_PROPS and String(nl[0].get("eq_weapon", "")) != "prop_" + gear:
			npc_bad.append("%s sin su %s" % [npc_id, gear])
		if not npc.has("server") or String(nl[1]) == "":
			npc_bad.append("%s sin equipo o sin nada en la mano" % npc_id)
		var data := StudentHero.build(nl[0], nl[1]).get_data()
		if npc_sheets.has(data):
			npc_bad.append("%s igual que %s" % [npc_id, npc_sheets[data]])
		npc_sheets[data] = npc_id
	_check(npc_bad.is_empty(), "cada NPC del servidor con su equipo, su objeto y su propio look: %s" % [npc_bad])
	var prop_layer := WeaponArt.layer("prop_cafe", StudentHero.CELL, StudentHero.GRIP)
	_check(prop_layer != null and prop_layer.get_pixelv(StudentHero.GRIP).a > 0.0, "la taza de Aida, en la mano")
	# T182: de lado es un perfil de verdad: un solo ojo y las piernas cambian en cada paso.
	var profile := StudentProfile.body(StudentHero.look_of(red, {}))
	_check(count_color.call(profile, "ffffff") == 1 and count_color.call(front, "ffffff") == 2, "de perfil se ve un solo ojo")
	var steps := {}
	for k in StudentHero.FRAMES["walk"]:
		var f := StudentProfile.frame(profile, StudentHero.look_of(red, {}), null, "walk", k)
		steps[f.get_region(Rect2i(0, StudentProfile.HIP_Y, StudentHero.CELL.x, StudentHero.CELL.y - StudentProfile.HIP_Y)).get_data()] = true
	_check(steps.size() >= 3, "de perfil las piernas cambian de posición al andar (%d posturas)" % steps.size())
	var bad_side := []
	for h in CharacterAppearance.HAIR_NAMES.size():
		var pf := StudentProfile.body(StudentHero.look_of(CharacterAppearance.sanitize({"hair": h}), {}))
		if pf.get_region(Rect2i(0, 0, StudentHero.CELL.x, 24)).get_used_rect().size == Vector2i.ZERO:
			bad_side.append(CharacterAppearance.HAIR_NAMES[h])
	_check(bad_side.is_empty(), "cada peinado tiene su vista de lado: %s" % [bad_side])
	_check(StudentHero.dir_for(Vector2.UP)[0] == StudentHero.Dir.BACK and StudentHero.dir_for(Vector2.LEFT) == [StudentHero.Dir.SIDE, true]
		and StudentHero.dir_for(Vector2.DOWN)[0] == StudentHero.Dir.FRONT, "cada dirección del movimiento elige su fila")
	_check(StudentHero.column_for("attack", 0.99) == StudentHero.first_column("attack") + 3 and StudentHero.column_for("limp", 1.0) == StudentHero.first_column("dead") + 1
		and StudentHero.column_for("idle", 0.0, 0.0, PI) >= StudentHero.first_column("walk"), "cada estado elige sus cuadros")
	_check(StudentHero.texture(StudentHero.look_of(red, {}), "sword") == StudentHero.texture(StudentHero.look_of(red, {}), "sword"), "la hoja se arma una vez y se guarda")
	# T180: los accesorios del creador no son sombreros (lo de la cabeza lo pone el equipo),
	# los guardados con gorra o gorro cargan sin accesorio, y cada peinado y accesorio se ve distinto.
	for name in CharacterAppearance.ACCESSORY_NAMES:
		_check(not (String(name).to_lower().contains("gorr") or String(name).to_lower().contains("casco") or String(name).to_lower().contains("sombrero")),
			"el accesorio «%s» no es un sombrero" % name)
	_check(CharacterAppearance.sanitize({"accessory": 4})["accessory"] == 0 and CharacterAppearance.sanitize({"accessory": 5})["accessory"] == 0
		and CharacterAppearance.sanitize({"accessory": 2})["accessory"] == 2, "un guardado con gorra o gorro carga sin accesorio")
	var figs := {}
	var repeated := []
	for h in CharacterAppearance.HAIR_NAMES.size():
		var fig := StudentHero.figure(StudentHero.look_of(CharacterAppearance.sanitize({"hair": h}), {}))
		var key := fig.get_data()
		if figs.has(key) or fig.get_used_rect().size == Vector2i.ZERO:
			repeated.append(CharacterAppearance.HAIR_NAMES[h])
		figs[key] = true
	for acc in range(1, CharacterAppearance.ACCESSORY_NAMES.size()):
		var fig := StudentHero.figure(StudentHero.look_of(CharacterAppearance.sanitize({"accessory": acc}), {}))
		var key := fig.get_data()
		if figs.has(key):
			repeated.append(CharacterAppearance.ACCESSORY_NAMES[acc])
		figs[key] = true
	_check(repeated.is_empty(), "cada peinado y accesorio del alumno se ve distinto: %s" % [repeated])
	_check(StudentHero.equipped_of_save({"inventory": {"equipment": {"helmet": {"base": "casco_de_hierro"}}}})["helmet"] == "casco_de_hierro",
		"la lista de personajes sabe qué lleva puesto cada guardado")
	# T161: cada clase con su equipo de oficio, horneado, y dos clases nunca con el mismo.
	var classes_json = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
	var class_ids: Array = classes_json["classes"].map(func(c: Dictionary) -> String: return String(c["id"]))
	_check(class_ids.all(func(id: String) -> bool: return CharacterAppearance.GEARS.has(id)), "cada clase tiene su equipo de oficio")
	_check(CharacterAppearance.with_gear(CharacterAppearance.default(), "hacker")["gear"] == "hacker"
		and not CharacterAppearance.with_gear(CharacterAppearance.default(), "nadie").has("gear")
		and CharacterAppearance.sanitize({"gear": "templario"})["gear"] == "templario", "el equipo va con la clase y sobrevive a sanitize")
	var gear_shapes := {}
	for gi in CharacterAppearance.GEARS.size():
		var tex := PlayerSprite.texture_of("gear", gi)
		if tex == null:
			_check(false, "equipo %s horneado" % CharacterAppearance.GEARS[gi])
			continue
		var img := tex.get_image()
		var shape := PackedByteArray()
		var count := 0
		var cell := PlayerSheet.region(PlayerSheet.Dir.DOWN, 0)
		for y in range(int(cell.position.y), int(cell.end.y)):
			for x in range(int(cell.position.x), int(cell.end.x)):
				var on := img.get_pixel(x, y).a > 0.3
				shape.append(1 if on else 0)
				count += 1 if on else 0
		_check(count > 20, "el equipo de %s se ve de frente (%d píxeles)" % [CharacterAppearance.GEARS[gi], count])
		gear_shapes[shape] = true
	_check(gear_shapes.size() == CharacterAppearance.GEARS.size(), "dos clases no comparten silueta de equipo")
	# T160: ningún cuadro del cuerpo vacío, los pies en FEET (de pie) y solo capas válidas en G.
	var bad_frames := []
	var bad_layers := {}
	for dir in PlayerSheet.DIRS:
		for col in PlayerSheet.columns():
			var cell := PlayerSheet.region(dir, col)
			var lowest := -1
			for y in range(int(cell.position.y), int(cell.end.y)):
				for x in range(int(cell.position.x), int(cell.end.x)):
					var c := body.get_pixel(x, y)
					if c.a > 0.6:
						lowest = y - int(cell.position.y)
						var g := roundi(c.g * 8.0)
						if g < PlayerSheet.LAYER_SKIN or g > PlayerSheet.LAYER_EYES:
							bad_layers[g] = true
			var group := String(PlayerSheet.STATES[0][0])
			var acc := 0
			for s in PlayerSheet.STATES:
				acc += int(s[1])
				if col < acc:
					group = s[0]
					break
			var standing := group in ["idle", "walk", "attack_swing", "attack_thrust", "shoot", "cast", "channel"]
			if lowest < 0 or (standing and absi(lowest - int(PlayerSheet.FEET.y)) > 3):
				bad_frames.append("%d/%d (%d)" % [dir, col, lowest])
	_check(bad_frames.is_empty(), "cada cuadro del cuerpo tiene dibujo y, de pie, los pies en FEET: %s" % [bad_frames])
	_check(bad_layers.is_empty(), "el canal G del cuerpo solo trae capas válidas: %s" % [bad_layers.keys()])


## Enemigos con más cuadros y direcciones (T101): la hoja y qué cuadro sale en cada estado.
func _test_enemy_sheet() -> void:
	_check(EnemySheet.WALK_FRAMES == 6 and EnemySheet.ATTACK_FRAMES == 4 and EnemySheet.HURT_FRAMES == 2 and EnemySheet.DIE_FRAMES == 6
		and EnemySheet.DIE + EnemySheet.DIE_FRAMES == EnemySheet.COLUMNS, "andar 6, atacar 4, golpe 2 y morir 6: 18 cuadros seguidos")
	_check(EnemySheet.row(3, EnemySheet.Dir.SIDE) == 11 and EnemySheet.region(3, EnemySheet.Dir.UP, 7) == Rect2(7 * 32, 10 * 32, 32, 32), "fila por tipo y dirección")
	_check(EnemySheet.dir_for(Vector2(10, 2)) == EnemySheet.Dir.SIDE and EnemySheet.dir_for(Vector2(1, -10)) == EnemySheet.Dir.UP
		and EnemySheet.dir_for(Vector2(1, 10)) == EnemySheet.Dir.DOWN and EnemySheet.dir_for(Vector2.ZERO) == EnemySheet.Dir.DOWN, "dirección según hacia dónde va")
	var walk := {}
	for k in 60:
		walk[EnemySheet.column_for("walk", k / 60.0)] = true
	_check(walk.size() == EnemySheet.WALK_FRAMES and walk.keys().all(func(c: int) -> bool: return c >= EnemySheet.WALK and c < EnemySheet.ATTACK),
		"al andar pasa por sus 6 cuadros")
	_check(EnemySheet.column_for("attack", 0.0) == EnemySheet.ATTACK and EnemySheet.column_for("attack", 0.99) == EnemySheet.ATTACK + 3, "el ataque va de la preparación al golpe")
	_check(EnemySheet.column_for("hurt", 1.0) == EnemySheet.HURT and EnemySheet.column_for("hurt", 0.2) == EnemySheet.HURT + 1, "golpe recibido: dos cuadros")
	_check(EnemySheet.column_for("die", 0.0) == EnemySheet.DIE and EnemySheet.column_for("die", 10.0) == EnemySheet.COLUMNS - 1, "al morir se queda en el último cuadro")
	var idle := {}
	for k in 40:
		idle[EnemySheet.column_for("idle", k / 10.0)] = true
	_check(idle.size() == 2, "quieto, respira con dos cuadros")
	# El atlas tiene algo dibujado en cada celda de cada tipo.
	var img := (load("res://assets/sprites/enemies/enemies.png") as Texture2D).get_image()
	var empty := []
	for type_row in EnemyManager.enemy_types().size():
		for dir in EnemySheet.DIRS:
			for col in [EnemySheet.WALK, EnemySheet.ATTACK + 2, EnemySheet.HURT, EnemySheet.COLUMNS - 1]:
				var r := EnemySheet.region(type_row, dir, col)
				var solid := false
				for y in range(int(r.position.y), int(r.end.y), 2):
					for x in range(int(r.position.x), int(r.end.x), 2):
						if img.get_pixel(x, y).a > 0.9:
							solid = true
							break
					if solid:
						break
				if not solid:
					empty.append("%d/%d/%d" % [type_row, dir, col])
	_check(empty.is_empty(), "todas las celdas tienen al enemigo dibujado: %s" % ", ".join(empty))
	# EnemyManager elige el cuadro: quieto, andando y preparando un golpe.
	var em := EnemyManager.new()
	em.roll_affixes = false
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var still := em.sprite_frame(0, 0, 1.0)
	_check(int(still.y) < 2, "quieto: cuadros de respirar")
	em.positions[0] = Vector2(30, 0)
	var walking := em.sprite_frame(0, 0, 1.0)
	_check(int(walking.x) == EnemySheet.row(0, EnemySheet.Dir.SIDE), "andando hacia un lado: la fila de lado")
	em.windups[0] = 0.4
	_check(int(em.sprite_frame(0, 0, 1.0).y) in [EnemySheet.ATTACK, EnemySheet.ATTACK + 1], "preparando el golpe: cuadros de ataque")
	em.free()


## Ambiente y clima por zona (T100): salpicaduras, polvo, chispas, LEDs y luces que reaccionan.
func _test_ambience() -> void:
	var was := WorldPost.reduced
	WorldPost.reduced = false
	_check("dust" in Weather.extras_for("catacombs") and "sparks" in Weather.extras_for("fabrica") and Weather.extras_for("forest").is_empty(),
		"polvo en las catacumbas, chispas en la fábrica, nada extra en el bosque")
	var rain := Weather.new()
	rain.kind = "data_rain"
	var view := Rect2(0, 0, 1600, 900)
	for k in Weather.RAIN_DROPS:
		rain._parts.append(rain._spawn(view, true))
	_check(rain._parts.all(func(p: Dictionary) -> bool: return p.has("land")), "cada gota sabe dónde va a caer")
	var splashed := false
	for k in 40:
		rain.step(0.05, view)
		splashed = splashed or not rain._splashes.is_empty()
	_check(splashed, "las gotas salpican al llegar al suelo")
	for k in 20:
		rain.step(0.05, view)
	_check(rain._splashes.all(func(s: Dictionary) -> bool: return float(s["t"]) < Weather.SPLASH_TIME), "las salpicaduras duran poco")
	rain.free()
	var dust := Weather.new()
	dust.extras = ["dust", "sparks"] as Array[String]
	for k in Weather.DUST_MOTES:
		dust._dust.append(dust._spawn_dust(view))
	dust._sparks.append({"pos": Vector2(800, 450), "next": 0.0, "burst": []})
	dust._step_ambient(0.05, view)
	_check(not (dust._sparks[0]["burst"] as Array).is_empty(), "un cable suelto chisporrotea")
	for k in 20:
		dust._step_ambient(0.05, view)
	_check(dust._dust.all(func(d: Dictionary) -> bool: return view.grow(100.0).has_point(d["pos"])), "el polvo sigue flotando en pantalla")
	dust.free()
	WorldPost.reduced = true
	_check(Weather.extras_for("catacombs").is_empty(), "con luces y clima reducidos, sin ambiente extra")
	WorldPost.reduced = was
	# Luces que reaccionan a los golpes.
	var post := WorldPost.new()
	post.note_hit(Vector2(100, 100), 10.0)
	_check(post.hit_kick(Vector2(100, 100), 10.0) == 1.0, "un golpe aviva la luz que tiene al lado")
	_check(post.hit_kick(Vector2(1000, 100), 10.0) == 0.0, "las luces lejanas no se enteran")
	_check(is_zero_approx(post.hit_kick(Vector2(100, 100), 10.0 + WorldPost.HIT_KICK_TIME + 0.01)), "y se calma enseguida")
	post.free()


## Estados y avisos con textura (T99): borde de trazos, flechas y escarcha que crece.
func _test_fx_art() -> void:
	var spans := FxArt.dash_spans(0.0)
	_check(spans.size() == FxArt.DASHES and is_equal_approx(spans[0][1] - spans[0][0], TAU / FxArt.DASHES * FxArt.DASH_FILL), "borde de trazos con huecos")
	var moved := FxArt.dash_spans(0.25)
	_check(is_equal_approx(moved[0][0] - spans[0][0], TAU * 0.25), "el borde gira con la fase")
	_check(is_equal_approx(FxArt.dash_spans(1.25)[0][0], moved[0][0]), "una vuelta entera vuelve al principio")
	var marks := FxArt.chevron_offsets(200.0, 46.0, 0.0)
	_check(marks.size() >= 3 and marks[0] == 0.0 and marks.all(func(d: float) -> bool: return d < 200.0), "flechas repartidas a lo largo del aviso")
	_check(FxArt.chevron_offsets(200.0, 46.0, 0.5)[0] == 23.0, "las flechas avanzan con la fase")
	_check(FxArt.frost_growth(0.0) == 0.35 and FxArt.frost_growth(0.5) == 1.0 and FxArt.frost_growth(0.25) > 0.35, "la escarcha crece en medio segundo")
	# El jugador apunta cuándo empezó cada estado.
	var c := CharacterData.new(_classes[0], _tree)
	var pl := Player.new()
	pl.character = c
	_check(pl.apply_status("chill", 3.0) and pl._status_since.has("chill"), "el jugador recuerda cuándo se heló")
	var first: float = pl._status_since["chill"]
	pl.apply_status("chill", 3.0)
	_check(pl._status_since["chill"] == first, "renovar el estado no reinicia la escarcha")
	pl.free()


## Partículas, luz y posproceso (T98): calidad gráfica, presupuesto y efectos.
func _test_graphics_quality() -> void:
	var low := GraphicsQuality.preset(GraphicsQuality.Level.LOW)
	var mid := GraphicsQuality.preset(GraphicsQuality.Level.MEDIUM)
	var high := GraphicsQuality.preset(GraphicsQuality.Level.HIGH)
	_check(int(low["lights"]) < int(mid["lights"]) and int(mid["lights"]) < int(high["lights"]) and int(high["lights"]) <= WorldPost.MAX_LIGHTS,
		"más luces cuanto más calidad, sin pasar del shader")
	_check(int(low["particles"]) == 0 and int(mid["particles"]) < int(high["particles"]), "partículas: ninguna en baja, más en alta")
	_check(not bool(low["heat"]) and bool(high["heat"]) and float(low["bloom"]) == 0.0 and float(high["bloom"]) > 0.0, "calor y bloom solo con más calidad")
	_check(not GraphicsQuality.fits_particles(0, 20, GraphicsQuality.Level.LOW), "en baja no sale ninguna ráfaga")
	_check(GraphicsQuality.fits_particles(0, 100, GraphicsQuality.Level.HIGH) and not GraphicsQuality.fits_particles(850, 100, GraphicsQuality.Level.HIGH),
		"una ráfaga sale si cabe en el presupuesto")
	_check(BigFx.burst_amount(10.0) == 16 and BigFx.burst_amount(1000.0) == 110 and BigFx.burst_amount(120.0) == 60, "partículas por ráfaga según su radio")
	var saved := GraphicsQuality.level
	var saved_reduced := WorldPost.reduced
	GraphicsQuality.level = GraphicsQuality.Level.HIGH
	WorldPost.reduced = false
	_check(WorldPost.light_limit() == int(high["lights"]), "luces según la calidad")
	WorldPost.reduced = true
	_check(WorldPost.light_limit() == WorldPost.LOW_LIGHTS, "con luces reducidas, como siempre")
	WorldPost.reduced = saved_reduced
	GraphicsQuality.level = saved
	_check(WorldPost.shock_radius(0.0) == 0.0 and is_equal_approx(WorldPost.shock_radius(WorldPost.SHOCK_TIME), WorldPost.SHOCK_MAX_RADIUS)
		and WorldPost.shock_radius(WorldPost.SHOCK_TIME * 0.5) > WorldPost.SHOCK_MAX_RADIUS * 0.5, "la onda crece rápido y frena")
	_check(WorldPost.shock_strength(WorldPost.SHOCK_TIME) == 0.0, "la onda se apaga al final")
	_check(WorldPost.is_fire_color(Color("ff8a3a")) and not WorldPost.is_fire_color(Color("9fd8ff")), "el calor sale de las luces de fuego")


## Animación de la interfaz (T97): números de daño, rebotes y brillo de la experiencia.
func _test_ui_motion() -> void:
	var numbers: Array = []
	DamageNumbers.merge(numbers, 7, Vector2.ZERO, 40.0, false, 0.0)
	DamageNumbers.merge(numbers, 7, Vector2.ZERO, 25.0, true, 0.2)
	_check(numbers.size() == 1 and is_equal_approx(numbers[0]["amount"], 65.0) and numbers[0]["stack"] == 2 and numbers[0]["crit"],
		"dos golpes seguidos al mismo enemigo se apilan en una cifra (y cuenta como crítico)")
	DamageNumbers.merge(numbers, 7, Vector2.ZERO, 10.0, false, 0.2 + DamageNumbers.STACK_WINDOW + 0.05)
	DamageNumbers.merge(numbers, 8, Vector2.ZERO, 10.0, false, 0.7)
	_check(numbers.size() == 3, "pasado el margen, o a otro enemigo, cifra nueva")
	for k in DamageNumbers.MAX_NUMBERS + 5:
		DamageNumbers.merge(numbers, 1000 + k, Vector2.ZERO, 1.0, false, 1.0)
	_check(numbers.size() == DamageNumbers.MAX_NUMBERS, "como mucho %d cifras a la vez" % DamageNumbers.MAX_NUMBERS)
	_check(DamageNumbers.scale_at(0.0, false, 1) > DamageNumbers.scale_at(0.3, false, 1), "la cifra salta grande y se asienta")
	_check(DamageNumbers.scale_at(0.3, true, 1) > DamageNumbers.scale_at(0.3, false, 1), "los críticos, más grandes")
	_check(DamageNumbers.scale_at(0.3, false, 5) > DamageNumbers.scale_at(0.3, false, 1), "un montón de golpes, más grande")
	_check(DamageNumbers.scale_at(0.0, false, 1, true) == DamageNumbers.scale_at(0.3, false, 1, true), "sin movimiento, tamaño fijo")
	_check(DamageNumbers.offset_at(0.3, 1.0, true).x == 0.0 and DamageNumbers.offset_at(0.3, 1.0, true).y < 0.0, "sin movimiento, solo sube")
	_check(DamageNumbers.alpha_at(0.1) == 1.0 and DamageNumbers.alpha_at(DamageNumbers.LIFETIME) == 0.0, "la cifra se desvanece al final")
	_check(DamageNumbers.label(12345.0) == "12.3k" and DamageNumbers.label(0.3) == "1", "cifras cortas")
	# EnemyManager deja los golpes para los números.
	var em := EnemyManager.new()
	em.roll_affixes = false
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.lives[0] = 1.0e6
	em.hit_index(0, 50.0, 50.0, 0.0, 100.0)
	_check(em.number_events.size() == 1 and is_equal_approx(em.number_events[0][1], 50.0), "cada golpe deja su número")
	em.free()
	# Rebotes y brillo.
	_check(is_equal_approx(UiMotion.overshoot(0.0), 0.92) and is_equal_approx(UiMotion.overshoot(1.0), 1.0), "el rebote va del 92 % al 100 %")
	var peak := 0.0
	for k in 20:
		peak = maxf(peak, UiMotion.overshoot(k / 20.0))
	_check(peak > 1.0, "el rebote se pasa un poco antes de asentarse")
	_check(UiMotion.level_glow(0.1) > 0.5 and UiMotion.level_glow(UiMotion.LEVEL_GLOW_TIME + 0.1) == 0.0 and UiMotion.level_glow(-1.0) == 0.0, "la barra de experiencia brilla al subir de nivel y se apaga")


## Pantallas de título, personajes y carga (T96): barrido, poses y pantalla de carga.
func _test_screens_t96() -> void:
	# Barrido: cada celda tiene su momento entre 0 y 1, en diagonal desde arriba a la izquierda.
	var cols := 40
	var rows := 23
	var first := ScreenTransition.cell_threshold(0, 0, cols, rows)
	var last := ScreenTransition.cell_threshold(cols - 1, rows - 1, cols, rows)
	_check(first < 0.25 and last > 0.75, "el barrido empieza arriba a la izquierda y acaba abajo a la derecha (%.2f → %.2f)" % [first, last])
	var all_in_range := true
	for r in rows:
		for c in cols:
			var th := ScreenTransition.cell_threshold(c, r, cols, rows)
			all_in_range = all_in_range and th >= 0.0 and th <= 1.0
	_check(all_in_range, "todas las celdas se encienden dentro del barrido")
	# Pose de lucimiento: quieta casi todo el ciclo y la acción al final, de principio a fin.
	_check(AppearancePreview.pose_at(0.5, "attack", "sword")["state"] == "idle", "al principio del ciclo, quieta")
	var act := AppearancePreview.pose_at(AppearancePreview.POSE_CYCLE - AppearancePreview.POSE_ACTION_TIME * 0.5, "attack", "sword")
	_check(act["state"] == "attack" and is_equal_approx(act["t"], 0.5) and act["weapon"] == "sword", "a mitad de la acción, atacando con su arma")
	_check(AppearancePreview.pose_at(AppearancePreview.POSE_CYCLE - 0.1, "cast", "sword")["weapon"] == "", "al lanzar no lleva arma")
	_check(AppearancePreview.pose_at(3.0, "", "")["state"] == "idle", "sin acción, siempre quieta")
	# Pantalla de carga: consejos, silueta según el borde de la zona y el desvanecido.
	_check(LoadingCard.tips().size() >= 15, "15 consejos de carga o más (%d)" % LoadingCard.tips().size())
	_check(LoadingCard.tip_for(3) == LoadingCard.tip_for(3) and LoadingCard.tip_for(3) != "", "el consejo depende de la semilla")
	_check(LoadingCard.silhouette_for("servers") == "racks" and LoadingCard.silhouette_for("forest") == "trees" and LoadingCard.silhouette_for("anillo") == "lava",
		"cada estilo de zona tiene su silueta")
	_check(LoadingCard.silhouette_for("no_existe") == "tents", "un estilo desconocido no rompe nada")
	_check(LoadingCard.alpha_at(0.2) == 1.0 and is_zero_approx(LoadingCard.alpha_at(LoadingCard.HOLD + LoadingCard.FADE + 0.01)), "la pantalla de carga se queda y luego se desvanece")
	# T168: la carga como registro de arranque, con su progreso de 0 a 100 %.
	var last_pct := -1
	var steady := true
	for k in 21:
		var p := LoadingCard.progress_at(LoadingCard.HOLD * k / 20.0)
		steady = steady and p >= last_pct
		last_pct = p
	_check(LoadingCard.progress_at(0.0) == 0 and LoadingCard.progress_at(LoadingCard.HOLD) == 100 and LoadingCard.progress_at(9.0) == 100 and steady,
		"la carga va de 0 a 100 % sin retroceder")
	var boot_end := LoadingCard.boot_lines("Bosque", 100)
	_check(LoadingCard.boot_lines("Bosque", 0).size() == 1 and String(LoadingCard.boot_lines("Bosque", 0)[0][0]) == ".."
		and boot_end.size() == LoadingCard.BOOT_STEPS.size() + 1 and boot_end.all(func(l: Array) -> bool: return l[0] == "OK")
		and String(boot_end[1][1]).contains("compilando zona: Bosque… OK"), "registro de arranque: «compilando zona… OK» y al final todo OK")
	var dump := DeathDump.text("Bosque", 7, false)
	_check(dump.contains("ProcesoTerminado") and dump.contains("Bosque") and dump.contains("nivel 7") and dump.contains("pulsa R")
		and not DeathDump.text("Bosque", 7, true).contains("pulsa R"), "la muerte como volcado de error (sin «pulsa R» en táctil)")


## Tema de interfaz dibujado (T95): atlas de piezas de 9 partes cargado en UiStyle.
func _test_ui_atlas() -> void:
	var tex := UiAtlas.texture()
	_check(tex != null, "el atlas de interfaz está generado (%s)" % UiAtlas.PATH)
	if tex == null:
		return
	_check(tex.get_width() == UiAtlas.CELL * UiAtlas.COLUMNS and tex.get_height() == UiAtlas.CELL * (UiAtlas.ROWS + UiAtlas.BIG_ROWS), "el atlas tiene la cuadrícula de UiAtlas")
	_check(UiAtlas.region("orb_frame").size == Vector2(192, 192) and Rect2(Vector2.ZERO, tex.get_size()).encloses(UiAtlas.region("orb_frame")),
		"el aro de los orbes es una pieza grande dentro del atlas")
	var cells := {}
	for piece in UiAtlas.PIECES:
		var cell: Vector2i = UiAtlas.PIECES[piece]
		_check(not cells.has(cell) and cell.x < UiAtlas.COLUMNS and cell.y < UiAtlas.ROWS, "%s tiene su celda propia" % piece)
		cells[cell] = true
	for piece in ["window", "panel", "button_normal", "button_hover", "button_pressed", "button_disabled", "slot_normal", "slot_magic",
			"slot_rare", "slot_unique", "bar_frame", "tab_active", "tab_inactive", "separator", "hotbar_plate", "flask_frame"]:
		_check(UiAtlas.PIECES.has(piece), "pieza de interfaz: %s" % piece)
	var box := UiAtlas.box("window", 20, 16)
	_check(box is StyleBoxTexture and box.texture_margin_left == UiAtlas.MARGIN and box.content_margin_left == 20.0, "marco de ventana de 9 partes con sus márgenes")
	# T166: botones, tooltips y ventanas, tarjetas planas redondeadas (sin el latón del atlas).
	var theme := UiStyle.make_theme()
	var flat_button := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	_check(flat_button != null and flat_button.corner_radius_top_left >= 6 and theme.get_stylebox("panel", "TooltipPanel") is StyleBoxFlat,
		"botones y tooltips son tarjetas redondeadas del panel de datos")
	var pressed := theme.get_stylebox("pressed", "Button")
	_check(pressed.content_margin_top > theme.get_stylebox("normal", "Button").content_margin_top, "el botón pulsado baja el texto")
	var win := UiStyle.window_style() as StyleBoxFlat
	_check(win != null and win.corner_radius_top_left == UiStyle.RADIUS and win.border_color == UiStyle.BORDER, "las ventanas son tarjetas del panel de datos")
	_check(theme.has_stylebox("grabber", "VScrollBar") and theme.has_stylebox("tab_selected", "TabBar"), "barras de desplazamiento y pestañas con el tema")
	# Contraste WCAG ≥ 4,5:1 del texto, el texto apagado y el acento contra los paneles.
	for bg in [UiStyle.PANEL, UiStyle.WINDOW_BG, UiStyle.PANEL_LIGHT]:
		for fg in [UiStyle.TEXT, UiStyle.MUTED, UiStyle.ACCENT]:
			_check(UiProposals.contrast(fg, bg) >= 4.5, "contraste %s sobre %s ≥ 4,5 (%.1f)" % [fg.to_html(false), bg.to_html(false), UiProposals.contrast(fg, bg)])
	_check(Color(UiStyle.TEXT_HEX) == UiStyle.TEXT and Color(UiStyle.MUTED_HEX) == UiStyle.MUTED and Color(UiStyle.ACCENT_HEX) == UiStyle.ACCENT,
		"los colores en hexadecimal del BBCode son los mismos")
	# Ninguna ventana usa los colores del estilo de latón fuera de UiStyle.
	var old_colors := ["d9a441", "b08a4a", "5a4426", "e8d9b0", "8a8293", "3a3442", "16131b", "221e29", "120f17", "0d0b10"]
	var stale := []
	for f in DirAccess.get_files_at("res://scripts/ui"):
		if not f.ends_with(".gd") or f == "ui_style.gd":
			continue
		var src := FileAccess.get_file_as_string("res://scripts/ui/" + f)
		for c in old_colors:
			if src.contains(c):
				stale.append("%s (%s)" % [f, c])
	_check(stale.is_empty(), "sin colores del estilo viejo en scripts/ui: %s" % [stale])
	_check(UiAtlas.slot_piece(Rarity.Item.MAGIC) == "slot_magic" and UiAtlas.slot_piece(Rarity.Item.ULTRA_RARE) == "slot_unique", "casilla según la rareza")
	_check(UiAtlas.box("no_existe") == null, "una pieza desconocida no rompe nada")


## Arte del árbol 2.0 (T94): parallax, marcos, minimapa y el pulso por el camino.
func _test_tree_art_v2() -> void:
	var view := Vector2(1600, 900)
	var off := Vector2(300, -200)
	_check(TreeArt.parallax(Vector2(100, 50), 0.5, off, view, 1.0).is_equal_approx(Vector2(100, 50) * 0.5 + off), "con profundidad 1 el fondo va con el árbol")
	var still := TreeArt.parallax(Vector2(100, 50), 0.5, Vector2.ZERO, view, 0.3)
	var moved := TreeArt.parallax(Vector2(100, 50), 0.5, Vector2(100, 0), view, 0.3)
	_check(is_equal_approx(moved.x - still.x, 30.0), "una capa de profundidad 0,3 se mueve un 30 %% de lo que se arrastra")
	_check(TreeArt.stars(0).size() == TreeArt.STAR_COUNT and TreeArt.stars(0)[0] == TreeArt.stars(0)[0], "estrellas fijas por capa")
	_check(TreeArt.nebula_blobs(Vector2(0, -900), 5) == TreeArt.nebula_blobs(Vector2(0, -900), 5), "la nebulosa de una región es siempre la misma")
	var kinds := {}
	for n: PassiveNode in _tree.nodes.values():
		kinds[TreeArt.frame_kind(n)] = true
	for k in ["minor", "notable", "keystone", "mastery", "constellation"]:
		_check(kinds.has(k), "hay nodos con marco de %s" % k)
		var poly := TreeArt.frame(k, Vector2(10, 10), 20.0)
		_check(poly.size() >= 5 and poly[0].is_equal_approx(poly[poly.size() - 1]), "el marco de %s es un polígono cerrado" % k)
	var b := TreeArt.bounds(_tree)
	var map := TreeArt.minimap_rect(view)
	_check(map.end.x <= view.x and map.end.y <= view.y and map.size.x == TreeArt.MINIMAP_SIZE, "el minimapa cabe en la esquina")
	for n: PassiveNode in _tree.nodes.values():
		if not map.grow(0.5).has_point(TreeArt.to_minimap(n.position, b, map)):
			_check(false, "%s cae fuera del minimapa" % n.title)
			break
	var p := Vector2(420, -1300)
	_check(TreeArt.from_minimap(TreeArt.to_minimap(p, b, map), b, map).is_equal_approx(p), "del minimapa al árbol y vuelta")
	# Pulso: un camino de 3 nodos nuevos sale de lo asignado y va paso a paso.
	var alloc := PassiveAllocation.new(_tree, _tree.get_start_node_for_class(&"guerrero"))
	var before := {}
	for id in alloc.get_allocated_ids():
		before[id] = true
	var target := -1
	for n: PassiveNode in _tree.nodes.values():
		if alloc.find_path(n.id).size() == 3:
			target = n.id
			break
	var path := alloc.find_path(target)
	var after := before.duplicate()
	for id in path:
		after[id] = true
	var depths := TreeArt.path_depths(_tree, before, after)
	var ordered := path.map(func(id: int) -> int: return int(depths[id]))
	ordered.sort()
	_check(ordered == [1, 2, 3], "el pulso recorre el camino nodo a nodo (%s)" % [ordered])


## Maestrías, constelaciones y ranuras del árbol nuevo (T93).
func _test_tree_extras() -> void:
	# Cada maestría de una misma familia ofrece otras opciones.
	var by_theme := {}
	for n: PassiveNode in _tree.nodes.values():
		if n.is_mastery():
			var names := PackedStringArray(n.choices.map(func(ch: Dictionary) -> String: return ch["name"]))
			var key := "%s|%s" % [n.theme if n.theme != "" else n.icon, ",".join(names)]
			_check(not by_theme.has(key), "%s no repite las opciones de otra maestría de su familia" % n.title)
			by_theme[key] = true
	# Constelaciones: 6 o más, cada una con su bono por completarla.
	_check(_tree.constellations.size() >= 6, "6 constelaciones o más (%d)" % _tree.constellations.size())
	var star: PassiveNode = null
	for n: PassiveNode in _tree.nodes.values():
		if n.constellation != "" and n.kind == PassiveNode.Kind.NOTABLE:
			_check(not n.complete_mods.is_empty(), "%s tiene bono por completar la constelación" % n.title)
			if star == null:
				star = n
	var c := CharacterData.new(_classes[0], _tree)
	c.level = 100
	c.passives.requirement_check = Callable()
	for id in _tree.constellations[star.constellation]:
		c.passives._allocated[id] = true
	_check(c.passives.constellation_complete(star.constellation), "con todos sus nodos, la constelación está completa")
	var whole := c.passives.collect_modifiers().size()
	var removed: int = _tree.constellations[star.constellation].filter(func(i: int) -> bool: return i != star.id)[0]
	c.passives._allocated.erase(removed)
	_check(not c.passives.constellation_complete(star.constellation), "le falta un nodo: no está completa")
	_check(c.passives.collect_modifiers().size() == whole - _tree.get_node_data(removed).mods.size() - star.complete_mods.size(),
		"sin completarla, la estrella no da el bono extra")
	# Ranuras de chip: 18 marcadas por el generador, en las puertas y en una por región.
	var sockets := _tree.socket_ids()
	_check(sockets.size() == 18, "18 ranuras de chip (%d)" % sockets.size())
	_check(sockets.all(func(i: int) -> bool:
			var n := _tree.get_node_data(i)
			return n.socket and (n.cluster.begins_with("puerta.") or n.cluster.ends_with(".B1"))),
		"las ranuras están en las puertas y en el anillo B")
	# Al cambiar el árbol, los chips engastados vuelven a la bolsa.
	var saved := CharacterData.new(_classes[0], _tree)
	saved.inventory.chips[999999] = ExpansionChip.new(Rarity.Item.MAGIC, 10)
	var d := saved.to_dict()
	d["passive_tree_version"] = _tree.version - 1
	d["passives"] = [1]
	var back := CharacterData.from_dict(d, _classes[0], _tree, _db)
	_check(back.inventory.chips.is_empty() and back.inventory.bag.any(func(it) -> bool: return it is ExpansionChip), "con el árbol nuevo, los chips engastados vuelven a la bolsa")


## Piedras angulares nuevas (T92): cada regla con su ventaja y su contra, y los choques.
func _test_new_keystones() -> void:
	var by_name := {}
	for n: PassiveNode in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.KEYSTONE:
			by_name[n.title] = n
	var new_ones := ["Rate Limiting", "Consistencia Eventual", "Fail Fast", "Kill -9", "Caché Fría", "Pair Programming",
		"Zero Trust", "Pago por Uso", "Mente sobre Materia", "Buffer Overflow", "Pato de Goma", "Contenedor Efímero"]
	for k in new_ones + ["Hotfix en Producción", "Root Access", "Arquitectura Hexagonal", "Kanban", "Monolito", "Tipado Estático"]:
		_check(by_name.has(k), "piedra angular en el árbol: %s" % k)
	_check(by_name.size() >= 22, "el árbol tiene 22 piedras angulares o más (%d)" % by_name.size())
	for k in by_name:
		var n: PassiveNode = by_name[k]
		_check(n.flavor != "", "%s tiene su texto" % k)
		for other in n.conflicts:
			_check(by_name.has(other) and k in by_name[other].conflicts, "el choque %s ↔ %s va en los dos sentidos" % [k, other])
	# Aviso de choque: con Pago por Uso asignada, Mente sobre Materia lo dice.
	var alloc := PassiveAllocation.new(_tree, _tree.get_start_node_for_class(&"guerrero"))
	alloc._allocated[by_name["Pago por Uso"].id] = true
	_check(alloc.conflicts_with(by_name["Mente sobre Materia"].id) == PackedStringArray(["Pago por Uso"]), "Mente sobre Materia avisa de que choca con Pago por Uso")
	_check(alloc.conflicts_with(by_name["Zero Trust"].id).is_empty(), "sin la otra asignada no hay aviso")
	var rule := func(c: CharacterData, stat: StringName, value: float) -> void:
		c.add_timed_effect("prueba_" + String(stat), [Modifier.from_dict({"stat": String(stat), "type": "flat", "value": value}, "prueba")] as Array[Modifier], 99.0)
	var board := Motherboard.new(_db.skills.skills["ping_letal"], 5, [])
	# Zero Trust: sin críticos, 40 % más de daño.
	var c := CharacterData.new(_classes[3], _tree)
	var before := SkillCalc.compute(board, c)
	rule.call(c, Stat.ZERO_TRUST, 40.0)
	var after := SkillCalc.compute(board, c)
	_check(after["crit_chance"] == 0.0 and is_equal_approx(after["max_damage"], before["max_damage"] * 1.4), "Zero Trust: sin críticos y un 40 %% más de daño")
	# Pago por Uso: el coste pasa del maná a la vida.
	var c2 := CharacterData.new(_classes[3], _tree)
	rule.call(c2, Stat.BLOOD_MAGIC, 1.0)
	var blood := SkillCalc.compute(board, c2)
	_check(blood["mana_cost"] == 0.0 and blood["life_cost"] == before["mana_cost"] and before["mana_cost"] > 0.0, "Pago por Uso: las habilidades cuestan vida en vez de maná")
	# Mente sobre Materia: el 40 % del daño al maná y sin regeneración de vida.
	var c3 := CharacterData.new(_classes[4], _tree)
	rule.call(c3, Stat.DAMAGE_TAKEN_FROM_MANA, 40.0)
	rule.call(c3, Stat.NO_LIFE_REGEN, 1.0)
	rule.call(c3, Stat.LIFE_REGEN, 10.0)
	var pl := Player.new()
	pl.character = c3
	var life0 := pl.max_life() * 0.9
	pl.life = life0
	pl.mana = 100.0
	pl.apply_dot("prueba", 20.0, 5.0)
	pl._tick_dots(1.0)
	var taken := (100.0 - pl.mana) + (life0 - pl.life)
	_check(taken > 0.0 and is_equal_approx(100.0 - pl.mana, taken * 0.4), "Mente sobre Materia: el maná se lleva el 40 %% (maná %.0f, vida %.0f)" % [pl.mana, pl.life])
	var life_now := pl.life
	pl._regenerate(1.0)
	_check(is_equal_approx(pl.life, life_now), "Mente sobre Materia: la vida no se regenera sola")
	pl.free()
	# Consistencia Eventual: la mitad llega ahora y el resto después.
	var c4 := CharacterData.new(_classes[0], _tree)
	rule.call(c4, Stat.EVENTUAL_CONSISTENCY, 1.0)
	var ev := Player.new()
	ev.character = c4
	ev.life = 100.0
	ev.apply_dot("prueba", 40.0, 5.0)
	ev._tick_dots(1.0)
	_check(is_equal_approx(ev.deferred_damage, 20.0), "Consistencia Eventual: la mitad del daño se aplaza (%.1f)" % ev.deferred_damage)
	ev.dots.clear()
	for i in 40:
		ev._regenerate(0.1)
	_check(ev.deferred_damage < 0.01 and ev.life < 80.0 + 0.5, "Consistencia Eventual: lo aplazado se acaba cobrando")
	ev.free()
	_check(KeystoneRules.deferred_drain(30.0, 1.0) >= 20.0 and KeystoneRules.deferred_drain(1.0, 1.0) == 1.0, "lo aplazado se cobra en unos 3 s")
	# Rate Limiting, Caché Fría y Pato de Goma.
	_check(KeystoneRules.rate_limited(0.2) and not KeystoneRules.rate_limited(0.5), "Rate Limiting: solo un golpe cada 0,4 s")
	var em := EnemyManager.new()
	em.roll_affixes = false
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.lives[0] = 1.0e6
	em.cold_cache = true
	em.hit_index(0, 100.0, 100.0, 0.0, 100.0)
	var first := em.last_damage_dealt
	em.hit_index(0, 100.0, 100.0, 0.0, 100.0)
	_check(is_equal_approx(first / em.last_damage_dealt, 2.0 / 0.8), "Caché Fría: el primer golpe hace el doble y los siguientes un 20 %% menos (%.0f / %.0f)" % [first, em.last_damage_dealt])
	em.free()
	var c5 := CharacterData.new(_classes[5], _tree)
	rule.call(c5, Stat.RUBBER_DUCK, 2.0)
	var duck := Player.new()
	duck.character = c5
	duck.life = 1.0
	duck._regenerate(1.0)
	var alone := duck.life
	c5.set_condition(Stat.COND_ALLIES, true)
	duck._regenerate(1.0)
	_check(duck.life - alone > duck.max_life() * 0.019, "Pato de Goma: con 3 aliados regeneras un 2 %% de la vida por segundo")
	duck.free()
	_check(Stat.tag_name(Stat.COND_HIGH_MANA) != String(Stat.COND_HIGH_MANA), "Buffer Overflow: la condición de maná alto tiene texto")


## Parte 2 (T72b): el ataque golpea en el cuadro de impacto de la animación.
func _test_impact_frame() -> void:
	var melee := {"tags": ["attack", "melee", "area"], "use_time": 0.6}
	var sword := SkillController.impact_delay(melee, "sword")
	_check(sword > 0.2 and sword <= SkillController.IMPACT_MAX, "con espada, el golpe llega a mitad del arco (%.2f s)" % sword)
	_check(SkillController.impact_delay(melee, "dagger") < sword, "la estocada de la daga llega antes")
	_check(SkillController.impact_delay({"tags": ["attack", "projectile"], "use_time": 0.5}, "") > 0.0, "un ataque a distancia sale al soltar")
	_check(SkillController.impact_delay({"tags": ["attack", "melee"], "use_time": 5.0}, "mace") == SkillController.IMPACT_MAX, "con tope: nunca parece que no responde")
	for instant in [{"tags": ["spell", "fire"], "use_time": 0.6}, {"tags": ["attack", "melee", "movement"], "use_time": 0.6},
			{"tags": ["attack", "minion", "automaton", "melee"], "use_time": 0.6}, {"tags": ["attack", "melee"], "use_time": 0.6, "trigger": "on_hit"}]:
		_check(SkillController.impact_delay(instant, "sword") == 0.0, "sale al instante: %s" % ", ".join(instant["tags"]))
	# El cuadro de impacto coincide con la pose: el arma pasa por delante (brazo hacia fuera).
	for w in ["sword", "axe", "mace", "dagger", ""]:
		var ang := CharacterAppearance.arm_angle("attack", w, CharacterAppearance.impact_fraction("attack", w))
		_check(absf(ang - PI * 0.5) < 0.6, "con %s, el golpe sale con el brazo por delante (%.2f rad)" % [w if w != "" else "el puño", ang])


func _db_enemies() -> Array:
	var data: Dictionary = DataLoader.load_json("res://data/enemies.json")
	return data.get("types", [])


const CHAIN_STEP := 0.1   # menor que SkillController.CHAIN_DELAY: hacen falta dos pasos por eslabón


## Nodos clave de invocador: Monolito (una sola, ×3 de vida y daño) frente a
## Microservicios (+2 a la vez, −30 % cada una).
func _test_summoner_keystones() -> void:
	var titles := {}
	for n in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.KEYSTONE:
			titles[n.title] = true
	_check(titles.has("Monolito") and titles.has("Microservicios"), "nodos clave Monolito y Microservicios en el árbol")
	var golem: Dictionary = _db.skills.skills["golem_hardware"]
	var c := CharacterData.new(_classes[5], _tree)
	var base := SkillCalc.compute(Motherboard.new(golem, 10, []), c)
	var mono_c := CharacterData.new(_classes[5], _tree)
	mono_c.add_timed_effect("prueba_mono", [Modifier.from_dict({"stat": "monolith", "type": "flat", "value": 1}, "prueba")] as Array[Modifier], 99.0)
	var mono := SkillCalc.compute(Motherboard.new(golem, 10, []), mono_c)
	_check(mono["max_units"] == 1 and is_equal_approx(mono["unit_life"], base["unit_life"] * 3.0) and mono["max_damage"] > base["max_damage"] * 2.9,
		"Monolito: una sola invocación con el triple de vida y daño")
	var micro_c := CharacterData.new(_classes[5], _tree)
	micro_c.add_timed_effect("prueba_micro", [Modifier.from_dict({"stat": "microservices", "type": "flat", "value": 1}, "prueba")] as Array[Modifier], 99.0)
	var micro := SkillCalc.compute(Motherboard.new(golem, 10, []), micro_c)
	_check(micro["max_units"] == base["max_units"] + 2 and is_equal_approx(micro["unit_life"], base["unit_life"] * 0.7) and micro["reserve"] < base["reserve"],
		"Microservicios: +2 a la vez, cada una con menos vida, daño y reserva")
	_check(is_equal_approx(SkillCalc.compute(Motherboard.new(_db.skills.skills["barrido"], 1, []), mono_c)["max_damage"],
		SkillCalc.compute(Motherboard.new(_db.skills.skills["barrido"], 1, []), c)["max_damage"]), "solo afecta a las invocaciones persistentes")


## Nodos de sacrificio (vida baja) y condicionales: 3 aliados, quieto 1 s, contra
## aturdidos y con la vida llena.
func _test_sacrifice_and_conditions() -> void:
	var cond_tags := {}
	var tree_stats := {}
	for n in _tree.nodes.values():
		for m in n.mods:
			tree_stats[String(m.stat)] = true
			for tg in m.tags:
				cond_tags[String(tg)] = true
	for tg in ["low_life", "full_life", "three_allies", "stationary"]:
		_check(cond_tags.has(tg), "nodos del árbol con la condición %s" % tg)
	_check(tree_stats.has("stunned_damage"), "nodo del árbol con daño contra aturdidos")
	# Quieto: tras 1 s sin moverse se activa y los modificadores «quieto» cuentan.
	var c := CharacterData.new(_classes[0], _tree)
	c.add_timed_effect("prueba_quieto", [Modifier.from_dict({"stat": "damage", "type": "increased", "value": 50, "tags": ["stationary"]}, "prueba")] as Array[Modifier], 99.0)
	var pl := Player.new()
	pl.character = c
	var base := c.stats.total_multiplier(Stat.DAMAGE, c.condition_tags())
	for k in 6:
		pl._update_conditions(0.25)
	_check(c.condition_tags().has(Stat.COND_STILL) and c.stats.total_multiplier(Stat.DAMAGE, c.condition_tags()) > base, "quieto 1 s: activa los modificadores «si no te has movido»")
	pl.position = Vector2(50, 0)
	pl._update_conditions(0.25)
	_check(not c.condition_tags().has(Stat.COND_STILL), "al moverte se apaga")
	pl.free()
	# Contra aturdidos: más daño solo si el enemigo está aturdido o congelado.
	var em := EnemyManager.new()
	em.roll_affixes = false
	var a := em.index_of(em.spawn(Vector2(0, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	var b := em.index_of(em.spawn(Vector2(500, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	for i in [a, b]:
		em.lives[i] = 1.0e6
		em.max_lives[i] = 1.0e6
	em.stuns[a] = 2.0
	em.hit_ailments = {"type": "physical", "chances": {}, "stunned": 1.5}
	em.hit_index(a, 100.0, 100.0, 0.0, 150.0)
	em.hit_index(b, 100.0, 100.0, 0.0, 150.0)
	_check(1.0e6 - em.lives[a] > (1.0e6 - em.lives[b]) * 1.4, "contra aturdidos: más daño al aturdido")
	em.free()
	var c2 := CharacterData.new(_classes[0], _tree)
	c2.add_timed_effect("prueba_aturdidos", [Modifier.from_dict({"stat": "stunned_damage", "type": "increased", "value": 30}, "prueba")] as Array[Modifier], 99.0)
	_check(is_equal_approx(float(SkillCalc.compute(Motherboard.new(_db.skills.skills["barrido"], 1, []), c2)["ailment_ctx"]["stunned"]), 1.3), "el perfil lleva el bono contra aturdidos")


## Conversión de daño desde el árbol: para toda la build, sin ocupar ranura; si una
## RAM ya convierte, manda la RAM.
func _test_tree_conversion() -> void:
	var tree_stats := {}
	for n in _tree.nodes.values():
		for m in n.mods:
			tree_stats[String(m.stat)] = n.title
	for conv in Stat.TREE_CONVERSIONS:
		_check(tree_stats.has(String(conv[0])), "nodo del árbol con %s" % conv[0])
	var skills := _db.skills.skills
	var c := CharacterData.new(_classes[0], _tree)
	var before := SkillCalc.compute(Motherboard.new(skills["barrido"], 5, []), c)
	c.add_timed_effect("prueba_conv", [Modifier.from_dict({"stat": "convert_physical_to_lightning", "type": "flat", "value": 1}, "prueba")] as Array[Modifier], 99.0)
	var after := SkillCalc.compute(Motherboard.new(skills["barrido"], 5, []), c)
	_check(before["damage_type"] == "physical" and after["damage_type"] == "lightning" and after["converted_from"] == "physical", "el árbol convierte el Barrido de físico a rayo")
	_check(after["tags"].has(&"lightning") and after["tags"].has(&"elemental"), "y gana las etiquetas de rayo y elemental")
	# Con una RAM de conversión, manda la RAM.
	var board := Motherboard.new(skills["barrido"], 5, [RamModule.new(_db.skills.rams["nitrogeno_liquido"]).generation()])
	board.install(RamModule.new(_db.skills.rams["nitrogeno_liquido"]), 0)
	_check(SkillCalc.compute(board, c)["damage_type"] == "cold", "si una RAM ya convierte, manda la RAM")
	# Elemental a caos.
	var c2 := CharacterData.new(_classes[4], _tree)
	c2.add_timed_effect("prueba_caos", [Modifier.from_dict({"stat": "convert_elemental_to_chaos", "type": "flat", "value": 1}, "prueba")] as Array[Modifier], 99.0)
	_check(SkillCalc.compute(Motherboard.new(skills["ping_letal"], 5, []), c2)["damage_type"] == "chaos", "el árbol convierte el Ping Letal de rayo a caos")


## Cargas en las builds: nodos del árbol y de ascendencia que las dan o las usan,
## maná al gastarlas y Core Dump, una habilidad que gasta todas.
func _test_charges_build() -> void:
	var tree_stats := {}
	for n in _tree.nodes.values():
		for m in n.mods:
			tree_stats[String(m.stat)] = true
	for s in ["max_buffer_charges", "max_multihilo_charges", "max_overclock_charges", "charge_spend_mana"]:
		_check(tree_stats.has(s), "el árbol tiene %s" % s)
	var asc_stats := {}
	for cls in _classes:
		for a in cls.get("ascendancies", []):
			for n in a.get("passives", []):
				for md in n.get("mods", []):
					asc_stats[String(md.get("stat", ""))] = true
	_check(asc_stats.has("max_buffer_charges") and asc_stats.has("charge_spend_mana"), "ascendencias que dan cargas o las usan")
	# Core Dump: gasta los tres tipos; las RAM de gasto ya no encajan en ella.
	var skills := _db.skills.skills
	var c := CharacterData.new(_classes[4], _tree)
	var p := SkillCalc.compute(Motherboard.new(skills["core_dump"], 5, []), c)
	_check(p["spend_charges"].size() == 3, "Core Dump gasta las tres cargas")
	_check(not RamModule.new(_db.skills.rams["volcado_de_buffer"]).supports(skills["core_dump"]), "Volcado de Buffer no encaja en Core Dump (ya gasta Buffer)")
	# Maná al gastar cargas.
	c.add_timed_effect("prueba_cargas", [Modifier.from_dict({"stat": "charge_spend_mana", "type": "flat", "value": 10}, "prueba")] as Array[Modifier], 99.0)
	var pl := Player.new()
	pl.character = c
	var sc := SkillController.new()
	sc.player = pl
	sc.character = c
	pl.mana = 0.0
	c.charges["multihilo"] = 2
	var q: Dictionary = sc._spend_charges(p)
	_check(c.charges["multihilo"] == 0 and q["max_damage"] > p["max_damage"], "gastar Multihilos: más daño")
	_check(is_equal_approx(pl.mana, minf(pl.max_mana(), pl.unreserved_mana_max() * 0.2)), "Compilación JIT y compañía: maná por carga gastada (%.1f)" % pl.mana)
	sc.free()
	pl.free()


## RAM de activación: la habilidad se lanza sola al recibir un golpe o al hacer un
## crítico, con enfriamiento interno, pagando su maná y sin bucles.
func _test_trigger_rams() -> void:
	var skills := _db.skills.skills
	var rams := _db.skills.rams
	_check(not RamModule.new(rams["manejador_excepciones"]).supports(skills["aura_mando"]), "no se activan auras")
	_check(not RamModule.new(rams["manejador_excepciones"]).supports(skills["teleport_tcp"]), "ni habilidades de movimiento")
	var c := CharacterData.new(_classes[4], _tree)
	var board := Motherboard.new(skills["fork_bomb"], 5, ["DDR3", "DDR5"])
	var plain := SkillCalc.compute(board, c)
	board.install(RamModule.new(rams["manejador_excepciones"]), 0)
	var p := SkillCalc.compute(board, c)
	_check(p["trigger"] == "on_hit" and p["trigger_cooldown"] > 0.0 and p["mana_cost"] > plain["mana_cost"], "Manejador de Excepciones: al recibir un golpe, con enfriamiento y más coste")
	var crit_board := Motherboard.new(skills["fork_bomb"], 5, ["DDR5"])
	crit_board.install(RamModule.new(rams["breakpoint_condicional"]), 0)
	_check(SkillCalc.compute(crit_board, c)["trigger"] == "on_crit", "Breakpoint Condicional: al hacer un crítico")
	c.inventory.set_board(0, board)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	em.player = pl
	var sc := SkillController.new()
	sc.setup(pl, em, c)
	pl.mana = pl.max_mana()
	var full := pl.mana
	em.spawn(Vector2(200, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	_check(not sc.try_use(0), "no se puede lanzar a mano")
	sc.on_player_hit()
	_check(sc._pending.is_empty(), "no se lanza en mitad del golpe: espera al siguiente fotograma")
	sc._update_triggers(0.016)
	_check(sc._pending.size() == 1 and sc._pending[0].get("triggered", false) and pl.mana < full, "al recibir un golpe se lanza sola y paga su maná")
	var mana_after := pl.mana
	sc.on_player_hit()
	sc._update_triggers(0.016)
	_check(sc._pending.size() == 1 and pl.mana <= mana_after + 0.01 and sc._trigger_cd[0] > 0.0, "enfriamiento interno: no se repite enseguida")
	sc._triggering = true
	sc.on_crit()
	sc._triggering = false
	_check(sc._pending_triggers.is_empty(), "los críticos de una habilidad activada no activan nada")
	# Cron Job, al esquivar y al matar (parte 2), y su texto en la barra y en K.
	for rid in ["cron_job", "hook_esquiva", "callback_matar"]:
		var b := Motherboard.new(skills["fork_bomb"], 5, [RamModule.new(rams[rid]).generation()])
		b.install(RamModule.new(rams[rid]), 0)
		var tp := SkillCalc.compute(b, c)
		_check(SkillController.trigger_text(tp) != "", "%s: dice qué la activa (%s)" % [rid, tp["trigger"]])
	var cron := Motherboard.new(skills["fork_bomb"], 5, ["DDR4"])
	cron.install(RamModule.new(rams["cron_job"]), 0)
	c.inventory.set_board(1, cron)
	sc.refresh_profiles()
	sc._pending.clear()
	pl.mana = pl.max_mana()
	sc._update_triggers(0.016)
	_check(sc._pending.size() == 1 and sc._trigger_cd[1] > 1.5, "Cron Job: con un enemigo cerca se lanza sola sin ningún evento")
	sc.on_player_dodged()
	_check(sc._pending_triggers.has("on_dodge"), "esquivar apunta su activación")
	sc._pending_triggers.clear()
	sc._triggering = true
	sc.on_enemy_killed(Vector2.ZERO)
	sc._triggering = false
	_check(not sc._pending_triggers.has("on_kill"), "lo que mata una habilidad activada no activa nada")
	sc.on_enemy_killed(Vector2.ZERO)
	_check(sc._pending_triggers.has("on_kill"), "matar con otra habilidad apunta su activación")
	sc.free()
	pl.free()
	em.free()


## Maestrías: un notable por sector donde se elige 1 de 3 bonos; la elección se
## guarda, cambia las stats y se puede cambiar gratis.
func _test_masteries() -> void:
	var masteries: Array = _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.is_mastery())
	_check(masteries.size() >= 18, "maestrías en los clusters grandes (%d)" % masteries.size())
	for n: PassiveNode in masteries:
		_check(n.choices.size() == 3 and n.kind == PassiveNode.Kind.NOTABLE, "%s: 3 opciones" % n.title)
	# La maestría más cercana al inicio del guerrero.
	var c := CharacterData.new(_classes[0], _tree)
	c.level = 30
	var mid := -1
	var best := 999
	for n: PassiveNode in masteries:
		var steps := c.passives.find_path(n.id).size()
		if steps > 0 and steps < best:
			best = steps
			mid = n.id
	_check(mid != -1 and c.passives.allocate_path(mid, 99) > 0, "la maestría del guerrero se puede asignar")
	var node: PassiveNode = _tree.get_node_data(mid)
	var stat_of := func(k: int) -> StringName: return (node.choices[k]["mods"][0] as Modifier).stat
	var first_value := c.stats.get_value(stat_of.call(1))
	_check(c.passives.mastery_choice(mid) == 0, "por defecto, la primera opción")
	_check(c.passives.set_mastery_choice(mid, 1), "se elige otra opción")
	_check(c.stats.get_value(stat_of.call(1)) != first_value or stat_of.call(1) == stat_of.call(0), "cambiar de opción cambia las stats")
	var back := CharacterData.from_dict(c.to_dict(), _classes[0], _tree, _db)
	_check(back.passives.mastery_choice(mid) == 1, "la elección se guarda y se carga")
	_check(not CharacterData.new(_classes[0], _tree).passives.set_mastery_choice(mid, 2), "sin asignar no se elige")

## Nodos clave que cambian una regla: Tipado Estático, Recolector de Basura,
## Modo Seguro y Código Espagueti.
func _test_rule_keystones() -> void:
	var rule_stats := {}
	for n in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.KEYSTONE:
			for m in n.mods:
				rule_stats[String(m.stat)] = n.title
	for s in [Stat.STATIC_TYPING, Stat.GARBAGE_COLLECTOR, Stat.SAFE_MODE, Stat.SPAGHETTI_CODE]:
		_check(rule_stats.has(String(s)), "nodo clave en el árbol con la regla %s" % s)
	var gc_text := Modifier.from_dict({"stat": "garbage_collector", "type": "flat", "value": 3}, "x").describe()
	_check(gc_text.begins_with("Al matar recuperas un 3 %"), "la regla se describe como frase, no como «+3 de»: %s" % gc_text)
	var rule := func(c: CharacterData, stat: StringName, value: float) -> void:
		c.add_timed_effect("prueba_" + String(stat), [Modifier.from_dict({"stat": String(stat), "type": "flat", "value": value}, "prueba")] as Array[Modifier], 99.0)
	# Tipado Estático: sin críticos y daño fijo.
	var c := CharacterData.new(_classes[3], _tree)
	rule.call(c, Stat.STATIC_TYPING, 1.0)
	var p := SkillCalc.compute(Motherboard.new(_db.skills.skills["ping_letal"], 5, []), c)
	_check(p["crit_chance"] == 0.0 and is_equal_approx(p["min_damage"], p["max_damage"]) and p["max_damage"] > 0.0, "Tipado Estático: sin críticos y el daño nunca varía")
	# Recolector de Basura: el maná no se regenera solo.
	var c2 := CharacterData.new(_classes[4], _tree)
	rule.call(c2, Stat.GARBAGE_COLLECTOR, 3.0)
	var pl := Player.new()
	pl.character = c2
	pl.mana = 1.0
	pl._regenerate(1.0)
	_check(is_equal_approx(pl.mana, 1.0), "Recolector de Basura: el maná no se regenera solo")
	pl.free()
	# Modo Seguro: un degenerativo mortal te deja a 1 de vida; tras la ventana y sin recarga, mueres.
	var c3 := CharacterData.new(_classes[0], _tree)
	rule.call(c3, Stat.SAFE_MODE, 1.0)
	var safe := Player.new()
	safe.character = c3
	safe.life = 10.0
	safe.apply_dot("prueba", 1.0e6, 5.0)
	safe._tick_dots(0.1)
	_check(is_equal_approx(safe.life, 1.0) and safe.is_alive() and safe.safe_mode_window > 0.0, "Modo Seguro: el golpe mortal te deja a 1 de vida")
	safe._tick_dots(0.1)
	_check(safe.is_alive(), "Modo Seguro: durante 2 s no bajas de 1")
	safe.safe_mode_window = 0.0
	safe._tick_dots(0.1)
	_check(not safe.is_alive(), "Modo Seguro: sin ventana y en recarga, mueres")
	safe.free()
	# Código Espagueti: los proyectiles salen con rebotes.
	var c4 := CharacterData.new(_classes[2], _tree)
	rule.call(c4, Stat.SPAGHETTI_CODE, 2.0)
	var sc := SkillController.new()
	sc.character = c4
	sc._fire_volley(SkillCalc.compute(Motherboard.new(_db.skills.skills["rafaga_de_paquetes"], 1, []), c4), Vector2.ZERO, Vector2.RIGHT, Color.WHITE)
	_check(not sc._projectiles.is_empty() and int(sc._projectiles[0]["ricochets_left"]) == 2, "Código Espagueti: proyectiles con 2 rebotes al azar")
	sc.free()


## Consejos de primera vez: uno por mecánica, una sola vez, guardado en el personaje.
func _test_mechanic_tips() -> void:
	var data: Dictionary = DataLoader.load_json(TipPanel.DATA_PATH)
	for id in ["dodge", "charges", "heavy", "terrain", "arena_break", "arena_safe", "arena_channel", "trigger"]:
		_check(data.get("tips", {}).has(id), "consejo de primera vez para %s" % id)
	if not TipPanel.enabled():
		return   # el jugador los apagó en Pausa: no se toca su ajuste
	var c := CharacterData.new(_classes[0], _tree)
	var pl := Player.new()
	pl.character = c
	var em := EnemyManager.new()
	var tp := TipPanel.new()
	root.add_child(tp)
	tp.setup(c, pl, em, null)
	pl.hit_taken.emit()
	_check(tp.has_seen("dodge") and tp._queue.size() == 1, "al recibir el primer golpe, consejo de esquiva")
	pl.hit_taken.emit()
	_check(tp._queue.size() == 1, "cada consejo sale una sola vez")
	em.hazards.append({"kind": "break", "pos": Vector2.ZERO, "radius": 50.0, "time": 0.0, "delay": 1.0})
	tp._watch()
	_check(tp.has_seen("arena_break"), "una losa a punto de romperse dispara su consejo")
	tp._process(0.5)
	_check(tp.visible and tp._showing == "dodge", "se muestran por orden")
	tp.queue_free()
	pl.free()
	em.free()


## Los jefes de los actos I, II y III usan una mecánica de arena distinta en cada
## fase (por encima del 66 %, entre 33 y 66 % y por debajo del 33 % de vida).
func _test_boss_arena_phases() -> void:
	const ARENA := ["floor_break", "safe_zones", "channel_adds"]
	var bosses := 0
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		for z in DataLoader.load_json(path).get("zones", []):
			var boss: Dictionary = z.get("boss", {})
			if boss.is_empty() or not boss.has("phases"):
				continue
			bosses += 1
			var kinds_used := {}
			for life in [0.9, 0.5, 0.2]:
				var found := ""
				for a in boss.get("abilities", []):
					var usable: bool = life <= float(a.get("max_life", 1.01)) and life > float(a.get("min_life", -1.0))
					if usable and ARENA.has(String(a.get("kind", ""))):
						found = String(a["kind"])
				_check(found != "", "%s: mecánica de arena con el %d %% de vida" % [boss.get("name", z["id"]), int(life * 100)])
				kinds_used[found] = true
			_check(kinds_used.size() == 3, "%s: una mecánica distinta en cada fase" % boss.get("name", z["id"]))
			# Las zonas seguras cubren toda la arena: pegarse a una esquina no las esquiva.
			Zone.scale_def(z)
			var half := Vector2(z["size"][0], z["size"][1]) / 2.0
			for a in boss.get("abilities", []):
				if a.get("kind", "") == "safe_zones":
					var c := Vector2(a["center"][0], a["center"][1])
					var far := 0.0
					for corner in [Vector2.ZERO, Vector2(half.x * 2.0, 0), Vector2(0, half.y * 2.0), half * 2.0]:
						far = maxf(far, c.distance_to(corner))
					_check(float(a["radius"]) >= far, "%s: %s cubre la arena entera (%.0f < %.0f)" % [boss.get("name", ""), a.get("name", ""), float(a["radius"]), far])
			# Y funcionan: cada una crea su aviso (o sus adds) sin errores.
			var em := EnemyManager.new()
			em.roll_affixes = false
			var bi := em.index_of(em.spawn(Vector2.ZERO, Rarity.Enemy.UNIQUE, em.type_index_of(String(boss["type"]))))
			for a in boss.get("abilities", []):
				if ARENA.has(String(a.get("kind", ""))):
					var before: int = em.hazards.size() + em._channels.size()
					em._resolve_ability(bi, a, Vector2(100, 0))
					_check(em.hazards.size() + em._channels.size() > before, "%s: %s se activa" % [boss.get("name", ""), a.get("name", "")])
			em.free()
	_check(bosses == 4, "los cuatro jefes con fases (%d)" % bosses)
	# En zonas agrandadas, el centro de las zonas seguras se escala con la zona (como el jefe).
	var scaled := {"scale": 1.25, "size": [2200, 1500], "boss": {"pos": [1650, 750], "abilities": [{"kind": "safe_zones", "center": [1100, 750]}]}}
	Zone.scale_def(scaled)
	_check(is_equal_approx(float(scaled["boss"]["abilities"][0]["center"][0]), 1375.0), "el centro de las zonas seguras se escala con la zona")


## Mecánicas de arena de los jefes: suelo que se rompe, zonas seguras que rotan
## y adds que hay que interrumpir.
func _test_arena_mechanics() -> void:
	var c := CharacterData.new(_classes[0], _tree)
	# Sin evasión ni bloqueo: que los golpes de la prueba no se esquiven al azar.
	c.add_timed_effect("prueba_sin_evasion", [Modifier.from_dict({"stat": "evasion", "type": "more", "value": -100}, "prueba"),
		Modifier.from_dict({"stat": "block_chance", "type": "more", "value": -100}, "prueba")] as Array[Modifier], 99.0)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var pl := Player.new()
	pl.character = c
	em.player = pl
	var boss_id := em.spawn(Vector2(600, 0), Rarity.Enemy.UNIQUE, em.type_index_of("bug"))
	var bi := em.index_of(boss_id)
	em.damages[bi] = 50.0
	# Suelo que se rompe: aviso, golpe a quien está encima y agujero que hace daño.
	pl.life = pl.max_life()
	em._resolve_ability(bi, {"kind": "floor_break", "count": 1, "radius": 80.0, "delay": 0.5, "hole_time": 3.0}, Vector2.ZERO)
	_check(em.hazards.size() == 1 and em.hazards[0]["kind"] == "break", "suelo que se rompe: una losa avisada")
	em._update_hazards(0.2)
	_check(is_equal_approx(pl.life, pl.max_life()), "durante el aviso no hace daño")
	em._update_hazards(0.4)
	_check(pl.life < pl.max_life() and em.pools.any(func(p: Dictionary) -> bool: return p.get("pit", false)), "al romperse golpea y deja un agujero")
	# Zonas seguras: fuera de ellas te toca; dentro, no.
	em.pools.clear()
	pl.life = pl.max_life()
	em._resolve_ability(bi, {"kind": "safe_zones", "center": [0, 0], "radius": 900.0, "delay": 1.0, "safe_count": 2,
		"safe_distance": 300.0, "safe_radius": 100.0, "spin": 0.5}, Vector2.ZERO)
	var zones: Dictionary = em.hazards[0]
	var first_angle: float = zones["safe"][0]["angle"]
	em._update_hazards(0.5)
	_check(not is_equal_approx(float(zones["safe"][0]["angle"]), first_angle), "las zonas seguras giran")
	var safe_spot: Vector2 = Vector2.from_angle(zones["safe"][0]["angle"]) * 300.0
	_check(EnemyManager.in_safe_zone(zones, safe_spot) and not EnemyManager.in_safe_zone(zones, Vector2.ZERO), "dentro y fuera de una zona segura")
	em._update_hazards(0.6)
	_check(pl.life < pl.max_life() and em.hazards.is_empty(), "fuera de las zonas seguras, al acabar el aviso, te toca")
	# Adds que canalizan: si no se matan, el jefe se cura; al morir, se interrumpe.
	em.lives[bi] = em.max_lives[bi] * 0.5
	var before := em.index_of(boss_id)
	em._resolve_ability(before, {"kind": "channel_adds", "count": 1, "channel_time": 1.0, "effect": "heal", "amount": 0.1, "distance": 200.0}, Vector2.ZERO)
	var add_id: int = em._channels.keys()[0]
	_check(em.channel_fraction(add_id) > 0.99, "el add empieza a canalizar")
	em._update_channels(1.05)
	bi = em.index_of(boss_id)
	_check(em.lives[bi] > em.max_lives[bi] * 0.55, "canalización completa: el jefe se cura")
	var ai := em.index_of(add_id)
	em.lives[ai] = 0.0
	em._kill(ai)
	em._update_channels(0.1)
	_check(em.channel_fraction(add_id) < 0.0, "matar al add interrumpe la canalización")
	pl.free()
	em.free()


## Terrenos (aceite, estática, refrigerante) y sus combos: aceite + fuego =
## explosión y suelo en llamas; estática + refrigerante = superconductor.
func _test_terrains() -> void:
	var skills := _db.skills.skills
	var c := CharacterData.new(_classes[4], _tree)
	var em := EnemyManager.new()
	em.roll_affixes = false
	var sc := SkillController.new()
	sc.enemies = em
	sc.character = c
	var bug := em.type_index_of("bug")
	var prof := {}
	for sid in ["derrame_aceite", "campo_estatica", "charco_refrigerante"]:
		_check(skills.has(sid) and skills[sid]["kind"] == "terrain", "%s es un terreno" % sid)
		prof[sid] = SkillCalc.compute(Motherboard.new(skills[sid], 1, []), c)
		_check(prof[sid]["dps"] > 0.0 and prof[sid]["duration"] > 0.0, "%s: daño por segundo y duración" % sid)
	var add := func(sid: String, pos: Vector2) -> Dictionary:
		var t := {"pos": pos, "radius": float(prof[sid]["radius"]), "terrain": String(skills[sid]["terrain"]), "life": 5.0, "next": 0.0,
			"profile": prof[sid], "color": Color.WHITE, "seed": 1}
		sc._terrains.append(t)
		return t
	# Aceite: ralentiza y, con un enemigo quemándose dentro, estalla y arde.
	var oil: Dictionary = add.call("derrame_aceite", Vector2.ZERO)
	var burning := em.index_of(em.spawn(Vector2(20, 0), Rarity.Enemy.NORMAL, bug))
	em.lives[burning] = 1.0e6
	em.max_lives[burning] = 1.0e6
	sc._update_aura_fields()
	_check(em.aura_fields.any(func(f: Dictionary) -> bool: return f["slow"] > 0.0), "el aceite ralentiza")
	sc._update_terrains(0.05)
	_check(oil["terrain"] == "oil", "el aceite no arde solo")
	em.apply_ailment(burning, Ailments.BURN, 10.0)
	sc._update_terrains(0.05)
	_check(oil["terrain"] == "fire" and em.lives[burning] < 1.0e6, "aceite + enemigo quemándose: explosión y suelo en llamas")
	# Estática + refrigerante encimados: superconductor.
	sc._terrains.clear()
	var st: Dictionary = add.call("campo_estatica", Vector2(1000, 0))
	var fr: Dictionary = add.call("charco_refrigerante", Vector2(1040, 0))
	sc._update_terrains(0.05)
	_check(st["terrain"] == "superconductor" and sc._terrains.size() == 1, "estática + refrigerante = superconductor")
	_check(not fr in sc._terrains, "el refrigerante se funde en el superconductor")
	sc.free()
	em.free()


## Esquiva, siguiente paso: recarga más rápida, Multihilos y explosión al esquivar,
## en afijos, chips, el árbol y las ascendencias.
func _test_dodge_upgrades() -> void:
	for s in [Stat.DODGE_RECOVERY, Stat.DODGE_MULTIHILO, Stat.DODGE_BLAST]:
		_check(Stat.exists(s), "stat de esquiva %s" % s)
	var c := CharacterData.new(_classes[1], _tree)
	var p := Player.new()
	p.character = c
	var base_time := p.dodge_recharge_time()
	c.add_timed_effect("prueba_esquiva", [Modifier.from_dict({"stat": "dodge_recovery", "type": "flat", "value": 25}, "prueba")] as Array[Modifier], 99.0)
	_check(is_equal_approx(base_time, Player.DODGE_RECHARGE) and is_equal_approx(p.dodge_recharge_time(), Player.DODGE_RECHARGE / 1.25),
		"+25 %% de recarga de esquiva: %.2f s → %.2f s" % [base_time, p.dodge_recharge_time()])
	p.free()
	var affix_stats := {}
	for a in _db.affixes:
		affix_stats[String(a.get("stat", ""))] = true
	for s in ["dodge_recovery", "dodge_charges", "dodge_multihilo", "dodge_blast"]:
		_check(affix_stats.has(s), "afijo de objeto con %s" % s)
	var tree_stats := {}
	for n in _tree.nodes.values():
		for m in n.mods:
			tree_stats[String(m.stat)] = true
	_check(tree_stats.has("dodge_recovery") and tree_stats.has("dodge_charges"), "el árbol tiene recarga y cargas de esquiva")
	var asc_stats := {}
	for cls in _classes:
		for a in cls.get("ascendancies", []):
			for n in a.get("passives", []):
				for md in n.get("mods", []):
					asc_stats[String(md.get("stat", ""))] = true
	_check(asc_stats.has("dodge_multihilo") and asc_stats.has("dodge_blast"), "ascendencias que actúan al esquivar")


## Habilidades de movimiento: Túnel SSH, Force Push y Git Revert.
func _test_movement_skills() -> void:
	var skills := _db.skills.skills
	var c := CharacterData.new(_classes[0], _tree)
	for sid in ["tunel_ssh", "force_push", "git_revert"]:
		_check(skills.has(sid) and skills[sid]["tags"].has("movement"), "%s existe con la etiqueta de movimiento" % sid)
		var p := SkillCalc.compute(Motherboard.new(skills[sid], 1, []), c)
		_check(p["max_damage"] > 0.0 and p["range"] > 0.0 and p["radius"] > 0.0, "%s: daño, alcance y radio" % sid)
		_check(Sfx.skill_sound(String(p["kind"])) != "", "%s: sonido al lanzarla" % sid)
	var revert := SkillCalc.compute(Motherboard.new(skills["git_revert"], 1, []), c)
	_check(revert["duration"] > 0.0 and revert["tick"] > 0.0 and revert["ailments"].get("chill", 0.0) >= 100.0, "Git Revert: zona helada con duración que ralentiza")
	var push := SkillCalc.compute(Motherboard.new(skills["force_push"], 1, []), c)
	_check(push["stun"] > 0.0 and float(push["def"].get("push", 0.0)) > 1.0, "Force Push: aturde y empuja")
	# Empuje en área: aleja del centro a los normales, menos a las élites y nada a los únicos.
	var em := EnemyManager.new()
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	var normal := em.index_of(em.spawn(Vector2(40, 0), Rarity.Enemy.NORMAL, bug))
	var elite := em.index_of(em.spawn(Vector2(0, 40), Rarity.Enemy.ELITE, bug))
	var boss := em.index_of(em.spawn(Vector2(-40, 0), Rarity.Enemy.UNIQUE, bug))
	var far_e := em.index_of(em.spawn(Vector2(600, 0), Rarity.Enemy.NORMAL, bug))
	em.push_in_radius(Vector2.ZERO, 100.0, 2.5)
	_check(em.knocks[normal].x > 0.0 and em.knocks[normal].length() > em.knocks[elite].length(), "Force Push: empuja hacia fuera, menos a las élites")
	_check(em.knocks[elite].y > 0.0 and em.knocks[boss] == Vector2.ZERO and em.knocks[far_e] == Vector2.ZERO, "los únicos y los lejanos no se mueven")
	em.free()


## Clusters de tamaños y formas distintos (árbol 2.0, T89).
func _test_shaped_clusters() -> void:
	var sizes := {}
	var themes := {}
	for c in _tree.clusters.values():
		sizes[String(c.get("size", ""))] = int(sizes.get(String(c.get("size", "")), 0)) + 1
		themes[c["theme"]] = true
	for s in ["S", "M", "L", "XL", "C"]:
		_check(int(sizes.get(s, 0)) > 0, "hay clusters de tamaño %s" % s)
	for t in ["vida", "fuego", "rayo", "frio", "mana"]:
		_check(themes.has(t), "hay clusters de %s" % t)


func _test_defense_and_dot_skills() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 21)
	var barrier := SkillCalc.compute(gen.generate_motherboard(1, "firewall_personal"), c)
	_check(barrier["barrier"] > 0.0 and barrier["duration"] > 0.0, "Firewall Personal da barrera")
	var buff := SkillCalc.compute(gen.generate_motherboard(1, "hiperthreading"), c)
	_check(not buff["buff_mods"].is_empty(), "Hiperthreading tiene mods")
	# El potenciador se aplica como efecto temporal.
	var mods: Array[Modifier] = []
	for md in buff["buff_mods"]:
		mods.append(Modifier.from_dict(md))
	var speed_before := c.stats.total_multiplier(Stat.ATTACK_SPEED)
	c.add_timed_effect("skill:hiperthreading", mods, buff["duration"])
	_check(c.stats.total_multiplier(Stat.ATTACK_SPEED) > speed_before, "más velocidad de ataque durante el efecto")
	# Degenerativo: mata con el tiempo.
	var em := EnemyManager.new()
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var kills := [0]
	em.enemy_killed.connect(func(_r: int, _xp: int, _p: Vector2, _t: String) -> void: kills[0] += 1)
	_check(em.dot_in_radius(Vector2.ZERO, 50.0, 1000.0, 3.0) == 1, "Ransomware afecta a los de la zona")
	em._update_dots(0.5)
	_check(kills[0] == 1, "el daño degenerativo mata")
	em.free()
	var dot := SkillCalc.compute(gen.generate_motherboard(1, "corrupcion_datos"), c)
	_check(dot["dps"] >= dot["min_damage"] and dot["dps"] <= dot["max_damage"] * 1.5,
		"el DPS del degenerativo es su daño por segundo (no se acumula sobre el mismo enemigo)")
	var homing := SkillCalc.compute(gen.generate_motherboard(1, "paquete_rastreador"), c)
	_check(homing["seek_range"] > 0.0 and homing["projectiles"] >= 3, "Paquete Rastreador busca enemigos")
	var drones := SkillCalc.compute(gen.generate_motherboard(1, "drones_vigilancia"), c)
	_check(drones["drone_count"] == 3 and drones["dps"] > 0.0, "tres drones")
	_check(not gen.generate_ram(1, "servidor_torreta").supports(_db.skills.skills["modo_seguro"]), "los potenciadores no van en torreta")


func _test_walk_animation() -> void:
	_check(RetroSfx.blip().data.size() > 0, "pitido generado")


func _test_save_dir_migration() -> void:
	# Simula la carpeta del nombre antiguo junto a la actual y comprueba la copia.
	var parent := OS.get_user_data_dir().get_base_dir()
	var old_dir := parent.path_join("Exile Overflow").path_join("characters")
	var existed := DirAccess.dir_exists_absolute(old_dir)
	_check(not existed or CharacterSaves.list_all("user://__vacio__").is_empty(), "directorio vacío de prueba")
	var dir := "user://test_migracion"
	for f in DirAccess.get_files_at(dir) if DirAccess.dir_exists_absolute(dir) else PackedStringArray():
		DirAccess.remove_absolute(dir + "/" + f)
	if existed:
		var copied := CharacterSaves.migrate_from_old_project_names(dir)
		_check(copied > 0 and not CharacterSaves.list_all(dir).is_empty(), "copia los guardados del nombre antiguo")
		_check(CharacterSaves.migrate_from_old_project_names(dir) == 0, "no vuelve a copiar si ya hay personajes")
		for f in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir + "/" + f)
		DirAccess.remove_absolute(dir)

func _test_item_transfer() -> void:
	var c := _new_character()
	c.set_level(30)
	var inv := c.inventory
	var gen := ItemGenerator.new(_db, 12)
	inv.boards.fill(null)
	var helmet := gen.generate(1, Rarity.Item.NORMAL, "casco_de_hierro")
	var ring := gen.generate(1, Rarity.Item.NORMAL, "anillo_de_rubi")
	var board := gen.generate_motherboard(1, "ping_letal")
	board.slots.assign(["DDR4", "DDR5"])
	board.rams.resize(2)
	var ram4 := gen.generate_ram(1, "multicanal")
	var ram5 := gen.generate_ram(1, "ecc")
	inv.bag[0] = helmet
	inv.bag[1] = ring
	inv.bag[2] = board
	inv.bag[3] = ram4
	inv.bag[4] = ram5
	var bag := func(i: int) -> Dictionary: return {"kind": "bag", "index": i}

	_check(ItemTransfer.move(c, bag.call(0), {"kind": "equip", "slot": "helmet"}) == "" and inv.equipped("helmet") == helmet and inv.bag[0] == null, "bolsa → casco")
	_check(ItemTransfer.move(c, bag.call(1), {"kind": "equip", "slot": "helmet"}) != "", "un anillo no va en la cabeza")
	_check(ItemTransfer.move(c, bag.call(1), {"kind": "equip", "slot": "ring_right"}) == "", "anillo en la ranura derecha")
	_check(ItemTransfer.move(c, {"kind": "equip", "slot": "ring_right"}, {"kind": "equip", "slot": "ring_left"}) == "" and inv.equipped("ring_left") == ring, "anillo de una mano a otra")
	_check(ItemTransfer.move(c, bag.call(2), {"kind": "equip", "slot": "body"}) != "", "una placa no se viste")
	_check(ItemTransfer.move(c, bag.call(2), {"kind": "board", "index": 3}) == "" and inv.boards[3] == board, "placa a la barra")
	_check(ItemTransfer.move(c, bag.call(3), {"kind": "dimm", "board": 3, "dimm": 1}) != "", "DDR4 en ranura DDR5: no")
	_check(ItemTransfer.move(c, bag.call(3), {"kind": "dimm", "board": 3, "dimm": 0}) == "" and board.rams[0] == ram4, "DDR4 en ranura DDR4")
	_check(ItemTransfer.move(c, bag.call(4), {"kind": "dimm", "board": 0, "dimm": 0}) != "", "sin placa en esa fila")
	_check(ItemTransfer.move(c, {"kind": "board", "index": 3}, {"kind": "board", "index": 0}) == "" and inv.boards[0] == board and inv.boards[3] == null, "mover la placa de tecla")
	_check(ItemTransfer.move(c, {"kind": "dimm", "board": 0, "dimm": 0}, bag.call(9)) == "" and inv.bag[9] == ram4 and board.rams[0] == null, "RAM instalada → bolsa")
	_check(ItemTransfer.move(c, {"kind": "equip", "slot": "helmet"}, bag.call(4)) != "", "intercambio inválido: la RAM no puede ir a la cabeza")
	_check(inv.equipped("helmet") == helmet and inv.bag[4] == ram5, "un intercambio inválido no cambia nada")
	var low := _new_character()
	low.inventory.bag[0] = gen.generate(40, Rarity.Item.NORMAL, "hacha_de_guerra")
	_check(ItemTransfer.move(low, {"kind": "bag", "index": 0}, {"kind": "equip", "slot": "weapon"}) != "", "nivel insuficiente")
	var taken := ItemTransfer.take(c, {"kind": "equip", "slot": "helmet"})
	_check(taken == helmet and inv.equipped("helmet") == null, "sacar un objeto para tirarlo al suelo")


func _test_item_icons() -> void:
	for b in _db.bases.values():
		_check(ItemIcons.has_icon(b["id"]), "sin icono para la base %s" % b["id"])
	for id in ["motherboard", "ram_DDR3", "ram_DDR4", "ram_DDR5", "flask_coffee", "flask_energy", "unknown"]:
		_check(ItemIcons.has_icon(id), "sin icono '%s'" % id)
	for def in _db.flasks.values():
		_check(ItemIcons.has_icon(Flask.new(def).icon()), "icono de la poción %s" % def["name"])
	var gen := ItemGenerator.new(_db, 2)
	_check(ItemIcons.icon_id(gen.generate_ram(1, "ecc")) == "ram_DDR5", "icono de RAM según su generación")
	_check(ItemIcons.texture() != null, "atlas de iconos cargado")

func _test_tree_clusters() -> void:
	_check(_tree.nodes.size() >= 450 and _tree.clusters.size() >= 40, "árbol grande con clusters (%d nodos, %d clusters)" % [_tree.nodes.size(), _tree.clusters.size()])
	var themes_in_cluster := {}
	for id in _tree.nodes:
		var n: PassiveNode = _tree.nodes[id]
		if n.kind == PassiveNode.Kind.NOTABLE or n.kind == PassiveNode.Kind.KEYSTONE:
			_check(PassiveIcons.has_icon(n.icon), "sin icono para %s (%s)" % [n.title, n.icon])
		if n.cluster != "":
			_check(_tree.clusters.has(n.cluster), "cluster inexistente %s" % n.cluster)
			if not themes_in_cluster.has(n.cluster):
				themes_in_cluster[n.cluster] = {}
			themes_in_cluster[n.cluster][n.theme] = true
		if n.theme != "":
			_check(_tree.themes.has(n.theme), "temática desconocida '%s'" % n.theme)
	for cid in themes_in_cluster:
		_check(themes_in_cluster[cid].size() == 1, "el cluster %s mezcla temáticas" % cid)
		var has_notable := false
		for id in _tree.nodes:
			if _tree.nodes[id].cluster == cid and _tree.nodes[id].kind == PassiveNode.Kind.NOTABLE:
				has_notable = true
		_check(has_notable, "el cluster %s no tiene notable" % cid)


func _test_conditions() -> void:
	var c := _new_character()
	var gen := ItemGenerator.new(_db, 30)
	var board := gen.generate_motherboard(1, "barrido")
	var low_life_node := -1
	for id in _tree.nodes:
		if _tree.nodes[id].title == "Hasta el Último Byte":
			low_life_node = id
	_check(low_life_node != -1, "existe el notable de vida baja")
	var before := SkillCalc.compute(board, c)
	c.passives.allocate_path(low_life_node, 999)
	var full := SkillCalc.compute(board, c)
	c.set_condition(Stat.COND_LOW_LIFE, true)
	var low := SkillCalc.compute(board, c)
	c.set_condition(Stat.COND_LOW_LIFE, false)
	_check(is_equal_approx(SkillCalc.compute(board, c)["max_damage"], full["max_damage"]), "sin vida baja, el notable no da daño")
	_check(full["max_damage"] >= before["max_damage"], "el camino no resta daño")
	c.set_condition(Stat.COND_LOW_LIFE, true)
	_check(low["max_damage"] > full["max_damage"] * 1.15, "con vida baja, más daño (+40 %% aumentado; %.1f → %.1f)" % [full["max_damage"], low["max_damage"]])
	var signals := [0]
	c.conditions_changed.connect(func() -> void: signals[0] += 1)
	c.set_condition(Stat.COND_LOW_LIFE, true)
	c.set_condition(Stat.COND_LOW_LIFE, false)
	_check(signals[0] == 1, "conditions_changed solo cuando cambia algo")


func _test_tree_version_refund() -> void:
	var c := _new_character()
	c.set_level(3)
	var start := c.passives.start_node_id
	c.passives.allocate_path(_tree.neighbors(start)[0], 5)
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var same := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(same.passives.spent_points() == 1 and not same.flags.has("passives_refunded"), "misma versión del árbol: se conservan")
	data["passive_tree_version"] = _tree.version - 1
	var old := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(old.passives.spent_points() == 0 and old.flags.has("passives_refunded"), "versión antigua: puntos devueltos y aviso")

## Cada estilo de zona tiene su ambiente y cada habilidad su efecto.
func _test_audio_assets() -> void:
	for act_path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(act_path))
		for z in act.get("zones", []):
			var style := String(z.get("style", ""))
			_check(Sfx.ambient_for(style) == style, "falta el ambiente del estilo %s" % style)
	for id in _db.skills.skills:
		var s: Dictionary = _db.skills.skills[id]
		var sound := Sfx.skill_sound(String(s.get("kind", "")), String(s.get("damage_type", "")))
		_check(ResourceLoader.exists(Sfx.SFX_DIR + sound + ".wav"), "falta el efecto %s (%s)" % [sound, id])
	for extra in ["enemy_death", "player_hurt", "pickup", "level_up", "flask", "portal", "wave"]:
		_check(ResourceLoader.exists(Sfx.SFX_DIR + extra + ".wav"), "falta el efecto " + extra)

## Tokens (2 de cada 5 normales en promedio), tienda del nivel del jugador y alijo compartido.
func _test_economy_and_stash() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var drops := 0
	for k in 5000:
		if Economy.drop_amount(5, Rarity.Enemy.NORMAL, rng) > 0:
			drops += 1
	_check(absf(drops / 5000.0 - 0.4) < 0.03, "los normales sueltan tokens ~2 de cada 5 (%.2f)" % (drops / 5000.0))
	_check(Economy.drop_amount(5, Rarity.Enemy.UNIQUE, rng) > Economy.drop_amount(5, Rarity.Enemy.NORMAL, rng), "un único suelta más que un normal")
	var gen := ItemGenerator.new(_db, 3)
	var stock := Economy.generate_stock(gen, 12)
	_check(stock.filter(func(it: Item) -> bool: return it is Motherboard).size() >= 9 and stock.any(func(it: Item) -> bool: return it is RamModule), "la tienda tiene placas y RAM")
	for item in stock:
		_check(item.item_level == 12 or Economy.shop_tag(item) == Economy.TAG_CONTRABAND, "mercancía del nivel del jugador (salvo el contrabando)")
		_check(Economy.price(item) > Economy.sell_price(item), "se vende más barato de lo que se compra")
	var c := _new_character()
	c.add_tokens(50)
	_check(not c.spend_tokens(80) and c.tokens == 50, "no se gasta lo que no hay")
	_check(c.spend_tokens(20) and c.tokens == 30, "gastar tokens")
	var saved := CharacterData.from_dict(c.to_dict(), c.class_def, _tree, _db)
	_check(saved.tokens == 30, "los tokens se guardan")
	# Alijo: mover desde la bolsa, guardar en disco y cargarlo en otro personaje.
	var path := "user://test_saves/stash.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_saves"))
	var stash := Stash.new(path)
	ItemTransfer.stash = stash
	var board := gen.generate_motherboard(5, "", 2)
	c.inventory.add_item(board)
	var bag_i := c.inventory.bag.find(board)
	_check(ItemTransfer.move(c, {"kind": "bag", "index": bag_i}, {"kind": "stash", "tab": 1, "index": 3}) == "", "guardar en el alijo")
	_check(stash.get_item(1, 3) == board and c.inventory.bag[bag_i] == null, "el objeto pasó al alijo")
	var key := KeyItem.new("tarjeta_rack")
	c.inventory.add_item(key)
	_check(ItemTransfer.move(c, {"kind": "bag", "index": c.inventory.bag.find(key)}, {"kind": "stash", "tab": 0, "index": 0}) != "", "los objetos clave no van al alijo")
	var other := _new_character()
	var loaded := Stash.load_from(path, _db)
	ItemTransfer.stash = loaded
	_check(loaded.get_item(1, 3) is Motherboard and loaded.count() == 1, "el alijo se comparte entre personajes (archivo)")
	var free := other.inventory.free_bag_index()
	_check(ItemTransfer.move(other, {"kind": "stash", "tab": 1, "index": 3}, {"kind": "bag", "index": free}) == "" and other.inventory.bag[free] is Motherboard, "otro personaje lo saca")
	ItemTransfer.stash = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Apariencia nueva (barba, accesorio, ojos, detalles, estatura) y diálogos que no se repiten.
func _test_appearance_and_dialogue_flow() -> void:
	var old := CharacterAppearance.sanitize({"body": 1, "hair": 2, "outfit_color": "2b4a6b"})
	_check(old["beard"] == 0 and old["accessory"] == 0, "guardados viejos: sin barba ni accesorio")
	_check(old["accent_color"] == Color("2b4a6b").darkened(0.55).to_html(false), "guardados viejos: detalles = atuendo oscurecido")
	var bad := CharacterAppearance.sanitize({"beard": 99, "accessory": -4, "eye_color": "nope", "height": 9.0})
	_check(bad["beard"] == CharacterAppearance.BEARD_NAMES.size() - 1 and bad["accessory"] == 0, "barba y accesorio dentro de rango")
	_check(bad["height"] == CharacterAppearance.MAX_HEIGHT and Color.html_is_valid(bad["eye_color"]), "estatura y ojos corregidos")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 20:
		var a := CharacterAppearance.random(rng)
		_check(CharacterAppearance.sanitize(a) == CharacterAppearance.sanitize(CharacterAppearance.sanitize(a)), "apariencia aleatoria estable")
	# Diálogo: el saludo no se repite al volver al inicio; lo leído queda marcado.
	var c := _new_character()
	var box := DialogueBox.new()
	box.character = c
	box._dialogue = {"start": "hola", "menu": ["¿Algo más?"], "greeting_again": ["De nuevo tú."],
		"nodes": {"hola": {"text": "Saludo largo.", "options": [{"text": "A", "next": "a"}]},
			"a": {"text": "Tema A.", "again": "Ya te lo conté.", "next": "hola"}}}
	box._dialogue_id = "prueba"
	_check(box._text_for("hola", box._dialogue["nodes"]["hola"]) == "Saludo largo.", "primera vez: saludo completo")
	box._visited_now["hola"] = true
	box._seen_nodes()["hola"] = true
	box._seen_nodes()["a"] = true
	_check(box._text_for("hola", box._dialogue["nodes"]["hola"]) == "¿Algo más?", "volver al inicio en la misma charla: frase corta")
	box._visited_now = {}
	_check(box._text_for("hola", box._dialogue["nodes"]["hola"]) == "De nuevo tú.", "otra visita: saludo distinto")
	_check(box._text_for("a", box._dialogue["nodes"]["a"]) == "Ya te lo conté.", "tema ya leído: texto 'again'")
	_check(c.flags["dialogue_seen"]["prueba"].has("a"), "lo leído se guarda en el personaje")
	box.free()

## Prólogo: las escenas que usa existen y la llegada al Sandbox solo sale tras él.
func _test_prologue_data() -> void:
	var cut: Dictionary = DataLoader.load_json("res://data/cutscenes.json")["cutscenes"]
	var source := FileAccess.get_file_as_string("res://scripts/prologue/prologue.gd")
	var regex := RegEx.new()
	regex.compile("_play\\(\"([a-z_]+)\"")
	var used := 0
	for m in regex.search_all(source):
		used += 1
		_check(cut.has(m.get_string(1)), "el prólogo usa la escena '%s', que no existe" % m.get_string(1))
	_check(used >= 5, "el prólogo usa sus escenas (%d)" % used)
	_check(cut.has("prologo_descarga") and cut.has("llegada_sandbox"), "escenas del clímax y de la llegada")
	var player_lines := 0
	for id in ["prologo_rafa", "llegada_sandbox"]:
		for step in cut[id]["steps"]:
			if step.get("speaker", "") == "player":
				player_lines += 1
	_check(player_lines >= 2, "el jugador habla en el prólogo")
	var act1: Dictionary = DataLoader.load_json("res://data/act1.json")
	for z in act1["zones"]:
		if z["id"] == act1["start_zone"]:
			var enter: Dictionary = z.get("cutscene_on_enter", {})
			_check(enter.get("id", "") == "llegada_sandbox" and enter.get("requires_flag", "") == "prologue_done", "llegada al Sandbox tras el prólogo")
	# El narrador nunca corta la voz: tts_stop() con SAPI colgaba el juego entero.
	for path in ["res://scripts/ui/dialogue_box.gd", "res://scripts/ui/cutscene_player.gd", "res://scripts/prologue/prologue.gd"]:
		_check(not FileAccess.get_file_as_string(path).contains("tts_stop()" + "
") and not FileAccess.get_file_as_string(path).contains("DisplayServer.tts_stop"), "%s no debe llamar a tts_stop" % path)
	# El jugador es un recién egresado, no un exiliado.
	for path in ["res://data/npcs.json", "res://data/cutscenes.json", "res://data/tutorial.json", "res://data/quests.json"]:
		_check(not FileAccess.get_file_as_string(path).to_lower().contains("exiliad"), "%s: ya no hay exiliados" % path)
	# El Inge Pepe ya no es «prestador de servicios».
	for path in ["res://data/npcs.json", "res://data/cutscenes.json"]:
		_check(not FileAccess.get_file_as_string(path).contains("restador de servicios retirado"), "%s: Pepe ya no es prestador de servicios" % path)

## Cada clase empieza con su kit de habilidades (no puede repetir el de otra)
## y el Ingeniero DevOps es de robótica: torreta autónoma, drones y robot de compañía.
func _test_class_kits_and_robotics() -> void:
	var seen := {}
	for c in _classes:
		var pair: Array = c["starter_skills"].duplicate()
		pair.sort()
		var key := ",".join(pair)
		_check(not seen.has(key), "%s empieza con las mismas habilidades que %s" % [c["id"], seen.get(key, "")])
		seen[key] = c["id"]
		for id in pair:
			_check(_db.skills.skills.has(id), "%s: habilidad inicial desconocida %s" % [c["id"], id])
	var devops: Dictionary = {}
	for c in _classes:
		if c["id"] == "templario":
			devops = c
	_check(devops["starter_skills"][0] == "torreta_ci", "el DevOps empieza con la torreta")
	var c := CharacterData.new(devops, _tree)
	var turret := SkillCalc.compute(Motherboard.new(_db.skills.skills["torreta_ci"], 1, []), c)
	_check(turret["deploy"] == "totem" and turret["totem_duration"] > 0.0 and turret["kind"] == "homing", "la torreta se despliega sola y rastrea")
	var robotics: Dictionary = {}
	for a in devops["ascendancies"]:
		if a["name"] == "Ingeniero en Robótica":
			robotics = a
	_check(not robotics.is_empty(), "ascendencia de robótica")
	var grants := false
	for passive in robotics.get("passives", []):
		for m in passive["mods"]:
			grants = grants or m["stat"] == "companion_robot"
	_check(grants, "la robótica da un robot de compañía")
	var laser := SkillCalc.compute(Motherboard.new(CompanionRobot.LASER, 5, []), c)
	var emp := SkillCalc.compute(Motherboard.new(CompanionRobot.EMP, 5, []), c)
	_check(laser["max_damage"] > 0.0 and laser["kind"] == "homing", "láser de rastreo del robot")
	_check(emp["stun"] > 0.0 and emp["radius"] > 0.0, "pulso EMP del robot")

## Simulación de combate del acto III: un jugador quieto frente a cada enemigo
## nuevo; se avanza el tiempo y se comprueba que la mecánica ocurre de verdad.
func _test_act3_mechanics() -> void:
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(_new_character(), em)
	var home := Vector2(1000, 1000)
	player.global_position = home
	em.player = player
	em.area_level = 30
	var sim := func(seconds: float) -> void:
		for k in int(seconds / 0.05):
			em._physics_process(0.05)
			player._tick_dots(0.05)
			player.life = player.max_life()   # inmortal durante la prueba
	var spawn := func(type_id: String, offset: Vector2, rarity := Rarity.Enemy.NORMAL) -> int:
		return em.spawn(home + offset, rarity, em.type_index_of(type_id))

	# Rootkit: invoca procesos fantasma, sin pasarse de su tope.
	em.clear_all()
	spawn.call("rootkit", Vector2(420, 0))
	sim.call(9.0)
	var ghosts := em.count_type("proceso_fantasma")
	_check(ghosts >= 2 and ghosts <= 10, "el Rootkit invoca procesos fantasma (%d)" % ghosts)

	# Centinela del BIOS: orbes lentos que giran hacia el jugador y se rompen contra obstáculos.
	em.clear_all()
	spawn.call("centinela_bios", Vector2(520, 0))
	sim.call(2.5)
	var orbs := em.projectiles.filter(func(pr: Dictionary) -> bool: return pr.has("homing"))
	_check(not orbs.is_empty(), "el Centinela dispara orbes perseguidores")
	if not orbs.is_empty():
		var orb: Dictionary = orbs[0]
		player.global_position = home + Vector2(0, 380)   # el jugador se aparta
		sim.call(1.2)
		var heading: float = (orb["vel"] as Vector2).normalized().dot((player.global_position - orb["pos"]).normalized())
		_check(heading > 0.6, "el orbe gira para seguir al jugador (%.2f)" % heading)
		_check(absf((orb["vel"] as Vector2).length() - 120.0) < 1.0, "el orbe es lento y mantiene su velocidad")
	player.global_position = home
	em.clear_all()
	em.obstacles = [Vector3(home.x + 200, home.y, 40)]
	em.projectiles.append(em._seeker_orb(home + Vector2(400, 0), Vector2.LEFT, 10.0, {"speed": 200.0}))
	sim.call(1.5)
	_check(em.projectiles.is_empty(), "un obstáculo detiene al orbe (cobertura)")
	em.obstacles = []

	# Gusano de firmware: lanza un charco donde estaba el jugador; pisarlo aplica daño degenerativo.
	em.clear_all()
	player.dots.clear()
	spawn.call("gusano_firmware", Vector2(380, 0))
	for k in 40:
		sim.call(0.25)
		if not em.pools.is_empty():
			break
	_check(not em.pools.is_empty(), "el Gusano deja un charco")
	if not em.pools.is_empty():
		_check((em.pools[0]["pos"] as Vector2).distance_to(home) < 40.0, "el charco cae donde estaba el jugador")
		sim.call(0.2)
		_check(player.dots.has("charco"), "pisar el charco aplica daño degenerativo")

	# Arco de electromigración: sus proyectiles dejan una quemadura.
	em.clear_all()
	player.dots.clear()
	spawn.call("electromigracion", Vector2(330, 0))
	var burned := false
	for k in 30:
		sim.call(0.25)
		for key in player.dots:
			burned = burned or String(player.dots[key]["kind"]) == "fire"
		if burned:
			break
	_check(burned, "la electromigración quema (daño degenerativo de fuego)")

	# Condensador: su golpe en área deja un charco eléctrico.
	em.clear_all()
	spawn.call("condensador", Vector2(70, 0))
	sim.call(3.0)
	_check(em.pools.any(func(pl: Dictionary) -> bool: return pl["kind"] == "lightning"), "el Condensador revienta y deja un charco eléctrico")

	# El daño degenerativo ignora la armadura pero respeta la resistencia.
	player.dots.clear()
	player.life = player.max_life()
	var before := player.life
	player.apply_dot("prueba", 40.0, 2.0, "chaos")
	player._tick_dots(1.0)
	var lost := before - player.life
	_check(lost > 0.0 and lost <= 40.0 + 0.01, "el daño degenerativo resta vida por segundo (%.1f)" % lost)
	player.apply_dot("prueba", 10.0, 0.5, "chaos")
	_check(float(player.dots["prueba"]["dps"]) == 40.0, "la misma fuente no se acumula: se renueva con el mayor")

	# Jefe fw_update.exe: orbes al principio; charcos a media vida; más orbes y rootkits al final.
	em.clear_all()
	var act3: Dictionary = DataLoader.load_json("res://data/act3.json")
	var boss: Dictionary = {}
	for z in act3["zones"]:
		if z.has("boss"):
			boss = z["boss"]
	var bid: int = em.spawn(home + Vector2(300, 0), Rarity.Enemy.UNIQUE, em.type_index_of("fw_update"), boss["name"], 1.0, boss["abilities"])
	sim.call(4.0)
	_check(em.projectiles.any(func(pr: Dictionary) -> bool: return pr.has("homing")), "fase 1: el jefe lanza orbes perseguidores")
	var bi := em.index_of(bid)
	em.lives[bi] = em.max_lives[bi] * 0.5
	em.projectiles.clear()
	sim.call(4.0)
	_check(not em.pools.is_empty(), "fase 2: el jefe deja charcos (Borrado de sectores)")
	bi = em.index_of(bid)
	em.lives[bi] = em.max_lives[bi] * 0.2
	sim.call(5.0)
	_check(em.count_type("rootkit") > 0, "fase 3: el jefe invoca rootkits de respaldo")
	em.queue_free()
	player.queue_free()


func _class_def(id: String) -> Dictionary:
	return _classes.filter(func(x: Dictionary) -> bool: return x["id"] == id)[0]


## Estados alterados: se aplican con la probabilidad del golpe, hacen su efecto
## (degenerativos, +daño, lentitud, congelación) y caducan.
func _test_ailments() -> void:
	var em := EnemyManager.new()
	em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.lives[0] = 1.0e6
	em.max_lives[0] = 1.0e6
	var all := {}
	for id in Ailments.ALL:
		if id != Ailments.FREEZE:
			all[id] = 100.0
	em.hit_ailments = {"chances": all, "effect": 1.0, "duration": 1.0}
	em.hit_index(0, 100.0, 100.0, 0.0, 150.0)
	_check(em.burn_time[0] > 0.0 and em.shock_time[0] > 0.0 and em.chill_time[0] > 0.0 and em.poison_time[0] > 0.0 and em.bleed_time[0] > 0.0,
		"un golpe con 100 % aplica todos los estados")
	_check(em.ailments_of(0).size() == 5, "ailments_of lista los estados activos (%d)" % em.ailments_of(0).size())
	_check(is_equal_approx(em.burn_dps[0], 100.0 * Ailments.DOT_FRACTION[Ailments.BURN]), "la quemadura es una fracción del golpe")
	em.hit_ailments = {}
	var before := em.lives[0]
	em.hit_index(0, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[0], 100.0 * (1.0 + Ailments.SHOCK_AMP)), "electrocutado recibe más daño (%.1f)" % (before - em.lives[0]))
	before = em.lives[0]
	em._update_dots(0.5)
	_check(em.lives[0] < before, "los degenerativos restan vida")
	em.hit_ailments = {"chances": {Ailments.POISON: 100.0}, "effect": 1.0, "duration": 1.0}
	for k in 20:
		em.hit_index(0, 10.0, 10.0, 0.0, 150.0)
	_check(em.poison_stacks[0] == Ailments.POISON_MAX_STACKS, "el veneno se acumula hasta el tope (%d)" % em.poison_stacks[0])
	em.hit_ailments = {"chances": {Ailments.FREEZE: 100.0}, "effect": 1.0, "duration": 1.0}
	em.hit_index(0, 10.0, 10.0, 0.0, 150.0)
	_check(em.freeze_time[0] > 0.0 and em.stuns[0] > 0.0, "congelado: no puede actuar")
	_check(em.ailments_of(0)[0]["id"] == Ailments.FREEZE, "congelado se muestra en vez de aturdido")
	em._update_dots(10.0)
	_check(em.ailments_of(0).size() == 1 and em.ailments_of(0)[0]["id"] == "stun" or em.ailments_of(0).is_empty(), "los estados caducan")
	# Inmunes: nada. Y al quitar un enemigo, los arrays siguen alineados.
	var b := em.spawn(Vector2(50, 0), Rarity.Enemy.NORMAL)
	em.set_immune(b, true)
	em.hit_ailments = {"chances": {Ailments.BURN: 100.0}, "effect": 1.0, "duration": 1.0}
	em.hit_index(em.index_of(b), 1.0, 1.0, 0.0, 150.0)
	_check(em.burn_time[em.index_of(b)] == 0.0, "un inmune no se quema")
	em.lives[0] = 0.5
	em.hit_ailments = {}
	em.hit_index(0, 10.0, 10.0, 0.0, 150.0)
	_check(em.count() == 1 and em.burn_time.size() == 1 and em.poison_stacks.size() == 1 and em.ids[0] == b, "los arrays de estados se compactan al morir")
	# Helado: más lento.
	_check(Ailments.CHILL_SLOW > 0.0 and Ailments.chances(StatBlock.new(), [], {"damage_type": "cold"}).has(Ailments.CHILL), "el frío hiela de forma innata")
	em.free()
	# Las habilidades llevan sus probabilidades en el perfil (innata + propia + rasgo).
	var wizard := CharacterData.new(_class_def("hechicero"), _tree)
	var flame := SkillCalc.compute(Motherboard.new(_db.skills.skills["flamewar"], 1, []), wizard)
	_check(is_equal_approx(flame["ailments"][Ailments.BURN], 10.0 + 20.0 + 10.0), "Flamewar quema: innata + propia + rasgo (%.0f)" % flame["ailments"][Ailments.BURN])
	_check(not flame["ailment_ctx"].is_empty(), "el contexto de estados va en el perfil")
	var buff := SkillCalc.compute(Motherboard.new(_db.skills.skills["hiperthreading"], 1, []), wizard)
	_check(buff["ailments"].is_empty(), "un potenciador no aplica estados")


## RAM de asistencia y pasivas que dan probabilidad de estados o mejoran autómatas.
func _test_ailment_supports_and_tree() -> void:
	var gen := ItemGenerator.new(_db, 31)
	var c := _new_character()
	for entry in [["pasta_termica", Ailments.BURN], ["sobretension", Ailments.SHOCK], ["refrigeracion_liquida", Ailments.CHILL],
			["inyeccion_malware", Ailments.POISON], ["fragmentacion_disco", Ailments.BLEED]]:
		var ram := gen.generate_ram(1, entry[0])
		var board := Motherboard.new(_db.skills.skills["barrido"], 1, [ram.generation()])
		var base := SkillCalc.compute(board, c)
		_check(board.install(ram, 0) == "" and ram.supports(board.skill_def), "%s encaja y funciona con Barrido" % entry[0])
		var with := SkillCalc.compute(board, c)
		_check(float(with["ailments"].get(entry[1], 0.0)) >= float(base["ailments"].get(entry[1], 0.0)) + 25.0, "%s sube la probabilidad de %s" % [entry[0], entry[1]])
	var turret: Dictionary = _db.skills.skills["torreta_ci"]
	var firmware := gen.generate_ram(1, "firmware_autonomo")
	_check(firmware.supports(turret) and firmware.supports(_db.skills.skills["drones_vigilancia"]), "el firmware funciona con torretas y drones")
	_check(not firmware.supports(_db.skills.skills["barrido"]), "el firmware no hace nada en un ataque normal")
	var drones := Motherboard.new(_db.skills.skills["drones_vigilancia"], 1, ["DDR4", "DDR5"])
	var before := SkillCalc.compute(drones, c)
	drones.install(gen.generate_ram(1, "protocolo_enjambre"), 0)
	drones.install(firmware, 1)
	var after := SkillCalc.compute(drones, c)
	_check(after["drone_count"] == before["drone_count"] + 1, "el enjambre añade un dron")
	_check(after["tick"] < before["tick"] and after["automaton_speed"] > 1.0, "el firmware hace disparar más rápido a los drones")
	# Árbol: temáticas nuevas, pasivas con estados y piedra angular de autómatas.
	var themes := {}
	var ailment_nodes := 0
	for n in _tree.nodes.values():
		themes[n.theme] = true
		for m in n.mods:
			if String(m.stat).ends_with("_chance") and String(m.stat) != "crit_chance" and String(m.stat) != "block_chance":
				ailment_nodes += 1
	for t in ["ignicion", "sobrecarga", "criogenia", "toxinas", "hemorragia", "automatizacion"]:
		_check(themes.has(t), "el árbol tiene la temática %s" % t)
		_check(PassiveIcons.has_icon(t), "icono de la temática %s" % t)
	_check(ailment_nodes >= 60, "muchas pasivas dan probabilidad de estados (%d)" % ailment_nodes)
	var devops := CharacterData.new(_class_def("templario"), _tree)
	var ks_found := false
	for n in _tree.nodes.values():
		if n.kind == PassiveNode.Kind.KEYSTONE and n.icon == "ks_templario":
			for m in n.mods:
				ks_found = ks_found or m.tags.has(&"automaton")
	_check(ks_found, "la piedra angular del DevOps potencia a los autómatas")
	_check(devops.stats.total_multiplier(Stat.AUTOMATON_SPEED) > 1.0, "rasgo del DevOps: autómatas más rápidos")


## Invocaciones persistentes: no caducan, reservan maná, los enemigos pueden
## atacarlas, se re-montan al relanzar y desaparecen al quitar la placa.
func _test_persistent_units() -> void:
	var c := CharacterData.new(_class_def("templario"), _tree)
	c.inventory.boards.fill(null)
	c.inventory.set_board(0, Motherboard.new(_db.skills.skills["robot_centinela"], 1, []))
	c.inventory.set_board(1, Motherboard.new(_db.skills.skills["dron_escolta"], 1, []))
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	em.player = player
	var sk := SkillController.new()
	root.add_child(sk)
	sk.setup(player, em, c)
	var p := sk.profile(0)
	_check(p["kind"] == "unit" and p["max_units"] >= 1 and p["unit_life"] > 0.0 and p["reserve"] > 0.0, "perfil de invocación persistente")
	_check(p["tags"].has(&"automaton"), "las invocaciones son autómatas")
	var full := player.max_mana()
	sk._execute(p, Vector2(100, 0))
	_check(sk._units.size() == 1 and em.allies.size() == 1, "invoca el robot y los enemigos pueden atacarlo")
	_check(is_equal_approx(player.mana_reserved, p["reserve"] / 100.0) and player.max_mana() < full, "reserva maná mientras viva")
	sk._update_units(30.0)
	_check(sk._units.size() == 1, "no caduca con el tiempo")
	sk._execute(p, Vector2(100, 0))
	_check(sk._units.size() == p["max_units"], "al máximo, relanzar lo repara en vez de añadir otro")
	var drone := sk.profile(1)
	sk._execute(drone, Vector2.ZERO)
	_check(sk._units.size() == 2 and em.allies.size() == 1, "el dron escolta orbita y no se le puede atacar")
	# Un enemigo cerca del robot va a por él (está más cerca que el jugador) y lo destruye.
	player.global_position = Vector2(-600, 0)
	sk._units[0]["pos"] = Vector2(0, 0)
	em.spawn(Vector2(30, 0), Rarity.Enemy.NORMAL)
	em._physics_process(0.05)
	_check(em._pick_ally(Vector2(30, 0), 630.0) == 0, "el enemigo prefiere al aliado que tiene al lado")
	em._damage_ally(0, 1.0e6)
	sk._update_units(0.05)
	_check(sk._units.size() == 1 and is_equal_approx(player.mana_reserved, drone["reserve"] / 100.0), "al caer libera su reserva")
	# Sin placa en la barra, la invocación desaparece.
	c.inventory.set_board(1, null)
	_check(sk._units.is_empty() and player.mana_reserved == 0.0, "quitar la placa retira la invocación")
	# El golem provoca: los enemigos en su radio van a por él aunque el jugador esté cerca.
	c.inventory.set_board(2, Motherboard.new(_db.skills.skills["golem_hardware"], 1, []))
	var golem := sk.profile(2)
	player.global_position = Vector2(0, 0)
	sk._execute(golem, Vector2.ZERO)
	sk._units[0]["pos"] = Vector2(150, 0)
	_check(em._pick_ally(Vector2(40, 0), 40.0) == 0, "el golem provoca a los enemigos de su radio")
	# RAM de proyectiles (rebote/perforación) afecta a los disparos de autómatas.
	var chain_board := Motherboard.new(_db.skills.skills["robot_centinela"], 1, ["DDR5", "DDR4"])
	chain_board.install(ItemGenerator.new(_db, 3).generate_ram(1, "propagacion_excepciones"), 0)
	chain_board.install(ItemGenerator.new(_db, 3).generate_ram(1, "bypass_firewall"), 1)
	var chain_p := SkillCalc.compute(chain_board, c)
	_check(chain_p["projectile_chains"] == 2 and chain_p["pierce"] == 3, "la RAM de rebote y perforación llega al robot (%d/%d)" % [chain_p["projectile_chains"], chain_p["pierce"]])
	var shots_before := sk._projectiles.size()
	sk._units[0]["cd"] = 0.0
	sk._units[0]["profile"] = chain_p
	em.spawn(sk._units[0]["pos"] + Vector2(200, 0), Rarity.Enemy.NORMAL)
	sk._unit_shoot(sk._units[0], chain_p, 520.0)
	_check(sk._projectiles.size() == shots_before + 1 and sk._projectiles[-1]["chains_left"] == 2, "el disparo del robot sale con rebotes")
	# En escenas (jugador bloqueado) los aliados no atacan.
	sk._units[0]["cd"] = 0.0
	var count_before := sk._projectiles.size()
	player.controls_locked = true
	sk._physics_process(0.1)
	player.controls_locked = false
	_check(sk._projectiles.size() == count_before, "con el jugador bloqueado nadie dispara")
	# Reserva llena: no deja invocar más.
	player.set_mana_reserved(0.9)
	_check(not sk._can_summon(p), "sin maná sin reservar no se puede invocar otra")
	sk.queue_free()
	em.queue_free()
	player.queue_free()


## Cada clase tiene un kit de 3 habilidades exclusivas y un rasgo propio.
func _test_unique_class_kits() -> void:
	var owner := {}
	for cdef in _classes:
		var kit: Array = cdef["starter_skills"]
		_check(kit.size() >= 3, "%s empieza con 3 habilidades" % cdef["id"])
		for s in kit:
			_check(not owner.has(s), "%s y %s empiezan con %s: los kits deben ser únicos" % [cdef["id"], owner.get(s, ""), s])
			owner[s] = cdef["id"]
		var trait_def: Dictionary = cdef.get("trait", {})
		_check(trait_def.has("name") and not trait_def.get("mods", []).is_empty(), "%s tiene rasgo de clase" % cdef["id"])
		for md in trait_def.get("mods", []):
			_check(Stat.exists(StringName(md["stat"])), "%s: stat del rasgo %s" % [cdef["id"], md["stat"]])
	# El kit de cada clase cubre mecánicas distintas (no todo es "proyectil").
	var kinds := {}
	for cdef in _classes:
		var key := PackedStringArray()
		for s in cdef["starter_skills"]:
			key.append(_db.skills.skills[s]["kind"])
		key.sort()
		_check(not kinds.has(",".join(key)), "%s juega igual que %s" % [cdef["id"], kinds.get(",".join(key), "")])
		kinds[",".join(key)] = cdef["id"]
	# Los personajes de antes reciben la habilidad que les falte del kit nuevo.
	var old := CharacterData.new(_class_def("guerrero"), _tree)
	old.inventory.set_board(0, Motherboard.new(_db.skills.skills["barrido"], 1, []))
	old.give_missing_starter_skills(_db)
	var ids := []
	for b in old.inventory.boards:
		if b:
			ids.append(b.skill_def["id"])
	_check(ids.has("reinicio_forzado") and ids.has("firewall_personal") and ids.count("barrido") == 1, "migración del kit: %s" % str(ids))
	_check(old.flags.has(CharacterData.STARTER_KIT_FLAG), "la migración se hace una vez")


## En el tutorial los enemigos empiezan lejos del jugador y de B.O.B. y no se
## despiertan hasta que el jugador se acerca: primero se habla, luego se pelea.
func _test_tutorial_safe_start() -> void:
	var act: Dictionary = DataLoader.load_json("res://data/act1.json")
	var z: Dictionary = act["zones"].filter(func(x: Dictionary) -> bool: return x["id"] == "tutorial")[0]
	var aggro := float(z.get("aggro_range", EnemyManager.AGGRO_RANGE))
	var keep := float(z["enemies"].get("keep_away", 0.0))
	_check(keep - aggro >= 300.0, "los bugs no oyen al jugador desde el inicio (%.0f / %.0f)" % [keep, aggro])
	var zone := Zone.new()
	zone.setup(z, null, null)
	var rng := RandomNumberGenerator.new()
	for seed_value in [1, 2, 3, 4, 5]:
		rng.seed = seed_value
		var packs := zone.pack_centers(int(z["enemies"]["packs"]), rng, keep)
		_check(packs.size() == int(z["enemies"]["packs"]), "caben todos los grupos lejos del inicio (%d)" % packs.size())
		for p in packs:
			_check(p.distance_to(zone.entry_point("start")) >= keep, "grupo lejos de la entrada")
			for npc in z["npcs"]:
				# Los bugs de un grupo se reparten hasta ±70 px: aun así, fuera del alcance desde B.O.B.
				_check(p.distance_to(Zone._v(npc["pos"])) - 100.0 > aggro, "grupo fuera del alcance de B.O.B.")
	zone.free()


## RAM de encadenamiento por grados: menor (1 salto), normal (2) y mayor (3); cada salto pega
## menos y la penalización mejora 1 punto por nivel de la placa.
func _test_chain_tiers() -> void:
	var gen := ItemGenerator.new(_db, 41)
	var c := _new_character()
	var tiers := {}
	for id in ["propagacion_excepciones_menor", "propagacion_excepciones", "propagacion_excepciones_mayor"]:
		var ram := gen.generate_ram(1, id)
		tiers[ram.tier()] = ram
	_check(tiers.size() == 3 and tiers[1].special("extra_chains") == 1 and tiers[2].special("extra_chains") == 2 and tiers[3].special("extra_chains") == 3, "tres grados de encadenamiento: 1, 2 y 3 saltos")
	_check(tiers[1].special("chain_penalty") > tiers[2].special("chain_penalty") and tiers[2].special("chain_penalty") > tiers[3].special("chain_penalty"), "los grados altos pierden menos daño")
	var board := Motherboard.new(_db.skills.skills["robot_centinela"], 1, ["DDR5"])
	board.install(tiers[1], 0)
	var lvl1 := SkillCalc.compute(board, c)
	_check(lvl1["projectile_chains"] == 1 and is_equal_approx(lvl1["chain_damage"], 0.70), "nivel 1 con la menor: 1 salto al -30 %% (%.2f)" % lvl1["chain_damage"])
	board.level = 2
	_check(is_equal_approx(SkillCalc.compute(board, c)["chain_damage"], 0.71), "al subir de nivel la penalización mejora un punto (-29 %)")
	board.level = 40
	_check(SkillCalc.compute(board, c)["chain_damage"] <= 1.0, "nunca supera el 100 %")
	_check(SkillCalc.compute(board, c)["projectile_chains"] == 1, "subir de nivel no añade saltos")
	# Solo caen los grados que corresponden al nivel de la zona.
	var seen_act1 := {}
	var seen_act3 := {}
	for k in 600:
		seen_act1[gen.generate_ram(8).def["id"]] = true
		seen_act3[gen.generate_ram(30).def["id"]] = true
	_check(seen_act1.has("propagacion_excepciones_menor") and not seen_act1.has("propagacion_excepciones") and not seen_act1.has("propagacion_excepciones_mayor"), "en el acto I solo cae la menor")
	_check(seen_act3.has("propagacion_excepciones_mayor") and seen_act3.has("pasta_termica_mayor"), "en el acto III caen los grados mayores")
	# El daño baja en cada rebote de un proyectil.
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	var chara := CharacterData.new(_class_def("templario"), _tree)
	chara.inventory.boards.fill(null)
	chara.inventory.set_board(0, board)
	board.level = 1
	player.setup(chara, em)
	em.player = player
	var sk := SkillController.new()
	root.add_child(sk)
	sk.setup(player, em, chara)
	var p := sk.profile(0)
	var pr := {"pos": Vector2.ZERO, "vel": Vector2.RIGHT * 100.0, "distance_left": 500.0, "pierce_left": 0, "hit_ids": {}, "profile": p,
		"color": Color.WHITE, "chains_left": 1, "homing": false}
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	em.spawn(Vector2(3, 0), Rarity.Enemy.NORMAL, bug)
	em.spawn(Vector2(120, 0), Rarity.Enemy.NORMAL, bug)
	em.lives[0] = 1.0e6
	em.max_lives[0] = 1.0e6
	em.lives[1] = 1.0e6
	em.max_lives[1] = 1.0e6
	sk._projectiles.append(pr)
	sk._update_projectiles(0.01)
	_check(sk._projectiles.size() == 1 and is_equal_approx(float(sk._projectiles[0].get("dmg_mult", 1.0)), p["chain_damage"]), "tras rebotar, el proyectil lleva la penalización")
	sk.queue_free()
	em.queue_free()
	player.queue_free()


## Auras (se activan y apagan, reservan maná, mejoran a los autómatas) y habilidades de invocaciones.
func _test_auras_and_unit_abilities() -> void:
	var c := CharacterData.new(_class_def("templario"), _tree)
	c.level = 20
	c.inventory.boards.fill(null)
	c.inventory.set_board(0, Motherboard.new(_db.skills.skills["robot_centinela"], 1, []))
	c.inventory.set_board(1, Motherboard.new(_db.skills.skills["aura_overclock"], 1, []))
	c.inventory.set_board(2, Motherboard.new(_db.skills.skills["dron_medico"], 1, []))
	c.inventory.set_board(3, Motherboard.new(_db.skills.skills["dron_escudo"], 1, []))
	c.inventory.set_board(4, Motherboard.new(_db.skills.skills["mina_rodante"], 1, []))
	c.inventory.set_board(5, Motherboard.new(_db.skills.skills["aura_blindaje"], 1, []))
	var em := EnemyManager.new()
	em.roll_affixes = false
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(c, em)
	em.player = player
	var sk := SkillController.new()
	root.add_child(sk)
	sk.setup(player, em, c)
	var before := sk.profile(0)
	sk._execute(sk.profile(1), Vector2.ZERO)
	_check(sk.is_aura_active("aura_overclock") and sk._auras.size() == 1, "la aura se activa")
	var after := sk.profile(0)
	_check(after["automaton_speed"] > before["automaton_speed"] and after["unit_interval"] < before["unit_interval"], "la aura acelera a los autómatas (%.2f → %.2f)" % [before["automaton_speed"], after["automaton_speed"]])
	_check(after["ailments"].get(Ailments.SHOCK, 0.0) > before["ailments"].get(Ailments.SHOCK, 0.0), "y les da probabilidad de electrocutar")
	_check(player.mana_reserved > 0.0, "la aura reserva maná")
	sk._execute(sk.profile(1), Vector2.ZERO)
	_check(not sk.is_aura_active("aura_overclock") and is_equal_approx(sk.profile(0)["automaton_speed"], before["automaton_speed"]) and player.mana_reserved == 0.0, "relanzarla la apaga y libera la reserva")
	# Las auras activas se guardan con el personaje y se vuelven a encender al cargar.
	sk._execute(sk.profile(1), Vector2.ZERO)
	_check(c.flags.get("active_auras", []) == ["aura_overclock"], "el aura activa queda en el guardado")
	var reloaded := SkillController.new()
	root.add_child(reloaded)
	c.timed_effects.clear()
	reloaded.setup(player, em, c)
	_check(reloaded.is_aura_active("aura_overclock") and player.mana_reserved > 0.0, "al cargar, el aura vuelve a estar activa y reserva maná")
	reloaded.clear_auras()
	reloaded.queue_free()
	_check(c.flags.get("active_auras", ["x"]).is_empty(), "al morir se apagan y ya no se guardan")
	sk._auras.clear()
	sk._execute(sk.profile(5), Vector2.ZERO)
	sk._execute(sk.profile(0), Vector2.ZERO)
	sk._update_units(0.05)
	_check(sk._units[0]["reduction"] >= sk.profile(5)["aura_reduction"] - 0.001 and sk.profile(5)["aura_reduction"] > 0.0, "el blindaje reduce el daño de las invocaciones")
	sk.clear_auras()
	_check(sk._auras.is_empty() and c.timed_effects.is_empty(), "clear_auras quita los efectos")
	# Dron médico: cura al jugador cuando está herido.
	sk.clear_units()
	sk._execute(sk.profile(2), Vector2.ZERO)
	player.life = player.max_life() * 0.5
	sk._units[0]["ab_cd"] = 0.0
	var hp := player.life
	sk._update_units(0.05)
	_check(player.life > hp, "el dron de mantenimiento cura al jugador")
	# Cortafuegos: da barrera.
	sk.clear_units()
	sk._execute(sk.profile(3), Vector2.ZERO)
	sk._units[0]["ab_cd"] = 0.0
	sk._update_units(0.05)
	_check(player.barrier > 0.0, "el dron cortafuegos levanta una barrera")
	# Mina rodante: explota al caer y daña a los cercanos.
	sk.clear_units()
	sk._execute(sk.profile(4), Vector2.ZERO)
	var bug_i := em.spawn(sk._units[0]["pos"] + Vector2(20, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	em.lives[em.index_of(bug_i)] = 1.0e6
	em.max_lives[em.index_of(bug_i)] = 1.0e6
	var life_before := em.lives[em.index_of(bug_i)]
	sk._units[0]["life"] = 0.0
	sk._update_units(0.05)
	_check(sk._units.is_empty() and em.lives[em.index_of(bug_i)] < life_before, "la mina rodante explota al caer")
	sk.queue_free()
	em.queue_free()
	player.queue_free()
	# Cada habilidad de invocación tiene una habilidad propia distinta.
	var kinds := {}
	for id in ["robot_centinela", "daemon_segundo_plano", "dron_escolta", "golem_hardware", "dron_medico", "dron_escudo", "bot_pruebas", "mina_rodante", "agente_ia"]:
		var d: Dictionary = _db.skills.skills[id]
		_check(d["kind"] == "unit" and d["tags"].has("persistent"), "%s es una invocación persistente" % id)
		kinds[str(d["unit"].get("ability", {}).get("kind", "")) + "/" + str(d["unit"]["behavior"]) + "/" + str(d["damage_type"])] = true
	_check(kinds.size() >= 8, "las invocaciones juegan distinto (%d combinaciones)" % kinds.size())


## Resistencias, inmunidades y afijos de los enemigos.
func _test_resists_and_affixes() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var zombi := em.type_index_of("proceso_zombi")
	var id := em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, zombi)
	var i := em.index_of(id)
	em.lives[i] = 1.0e6
	em.max_lives[i] = 1.0e6
	_check(em.is_immune_to(i, "poison") and em.resist_of(i, "chaos") == 50.0 and em.resist_of(i, "fire") == -25.0, "el proceso zombi es inmune al veneno y resiste caos")
	em.hit_ailments = {"type": "chaos", "chances": {"poison": 100.0}, "effect": 1.0, "duration": 1.0}
	var before := em.lives[i]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[i], 50.0) and em.poison_time[i] == 0.0, "50 % de resistencia: la mitad del daño y sin veneno")
	em.hit_ailments = {"type": "fire", "chances": {}, "effect": 1.0, "duration": 1.0}
	before = em.lives[i]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[i], 125.0), "resistencia negativa: más daño (%.0f)" % (before - em.lives[i]))
	# Daño extra contra enemigos con estados.
	em.apply_ailment(i, Ailments.BLEED, 10.0)
	em.hit_ailments = {"type": "", "chances": {}, "effect": 1.0, "duration": 1.0, "ailing": 1.5}
	before = em.lives[i]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[i], 150.0), "daño contra enemigos con estados")
	# Afijos explícitos: resistencias, inmunidades y velocidad.
	em.clear_all()
	var bug := em.type_index_of("bug")
	var base_speed_id := em.spawn(Vector2(500, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], [])
	var aff_id := em.spawn(Vector2(0, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["ignifugo", "veloz"])
	var ai := em.index_of(aff_id)
	_check(em.resist_of(ai, "fire") == 75.0 and em.is_immune_to(ai, "burn") and em.affixes_of(ai).size() == 2, "afijos Ignífugo y Veloz")
	_check(em.names[ai].begins_with("Ignífugo"), "el afijo da nombre al élite (%s)" % em.names[ai])
	_check(em.speeds[ai] > em.speeds[em.index_of(base_speed_id)] * 1.1, "Veloz corre más")
	# Los élite tiran afijos según el nivel de la zona.
	var em2 := EnemyManager.new()
	em2.area_level = 10
	var with := 0
	for k in 30:
		var e := em2.spawn(Vector2.ZERO, Rarity.Enemy.ELITE, bug)
		var base_affixes: Array = em2.affixes_of(em2.index_of(e)).filter(func(a: String) -> bool: return not EnemyManager.affix_defs()[a].has("combo"))
		with += 1 if base_affixes.size() == 2 and not EnemyManager._excluded(base_affixes[0], [base_affixes[1]]) else 0
	_check(with == 30, "los élite del nivel 10 llevan dos afijos (y nunca dos que se excluyan)")
	# Combinaciones: Ignífugo + Explosivo = Termonuclear (nombre propio, una sola explosión, la grande).
	var combo_id := em2.spawn(Vector2.ZERO, Rarity.Enemy.ELITE, bug, "", 1.0, [], ["ignifugo", "explosivo"])
	var ci := em2.index_of(combo_id)
	_check(em2.affixes_of(ci).has("combo_termonuclear") and em2.names[ci].begins_with("Termonuclear"), "combinación: Termonuclear con nombre propio")
	_check(em2.call("_hunts_allies", ci), "los que llevan carga explosiva van a por las invocaciones")
	_check(EnemyManager._excluded("ignifugo", ["ardiente"]), "Ignífugo y Ardiente no salen juntos")
	# Torretas: solo los cazadores van a por ellas, aunque el jugador esté más cerca.
	em2.allies = [{"pos": Vector2(300, 0), "life": 50.0, "max_life": 50.0, "radius": 14.0, "device": true}]
	_check(em2.call("_pick_ally", Vector2.ZERO, 100.0, true) == 0, "un cazador va a por la torreta")
	_check(em2.call("_pick_ally", Vector2.ZERO, 1000.0, false) == -1, "un enemigo normal ignora la torreta (aunque esté más cerca que tú)")
	em2.area_level = 1
	var e1 := em2.spawn(Vector2.ZERO, Rarity.Enemy.ELITE, bug)
	_check(em2.affixes_of(em2.index_of(e1)).is_empty(), "sin afijos en el nivel 1")
	# Explosivo: al morir deja una carga; regenerador: recupera vida.
	var boom_id := em.spawn(Vector2(0, 300), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["explosivo"])
	em.hit_index(em.index_of(boom_id), 1.0e9, 1.0e9, 0.0, 150.0)
	_check(em.hazards.size() == 1, "el explosivo deja una carga al morir")
	var regen_id := em.spawn(Vector2(0, 600), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["regenerador"])
	var ri := em.index_of(regen_id)
	em.lives[ri] = em.max_lives[ri] * 0.5
	em._update_affixes(1.0)
	_check(em.lives[ri] > em.max_lives[ri] * 0.5, "el regenerador recupera vida")
	for aid in EnemyManager.affix_defs():
		var d: Dictionary = EnemyManager.affix_defs()[aid]
		_check(d.has("name") and d.has("description") and d.has("color"), "afijo %s completo" % aid)
	for t in EnemyManager.enemy_types():
		for k in t.get("resist", {}):
			_check(EnemyManager.RESIST_TYPES.has(k), "%s: tipo de resistencia %s" % [t["id"], k])
		for k in t.get("immune", []):
			_check(Ailments.ALL.has(k), "%s: estado inmune %s" % [t["id"], k])
	em.free()
	em2.free()


## Fases de jefe: aviso, más velocidad, invulnerabilidad breve y barra de jefe con umbrales.
func _test_boss_phases() -> void:
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = DataLoader.load_json(path)
		for z in act["zones"]:
			if z.has("boss"):
				var phases: Array = z["boss"].get("phases", [])
				_check(phases.size() >= 2, "%s: el jefe tiene fases" % z["id"])
				var last := 1.0
				for ph in phases:
					_check(float(ph["at"]) < last and ph.has("name") and ph.has("text"), "%s: fases ordenadas y con texto" % z["id"])
					last = float(ph["at"])
	var act1: Dictionary = DataLoader.load_json("res://data/act1.json")
	var boss: Dictionary = act1["zones"].filter(func(z: Dictionary) -> bool: return z.has("boss"))[0]["boss"]
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(_new_character(), em)
	player.global_position = Vector2(3000, 3000)
	em.player = player
	var id := em.spawn(Vector2(0, 0), Rarity.Enemy.UNIQUE, em.type_index_of(boss["type"]), boss["name"], float(boss["life_mult"]), boss["abilities"])
	em.set_phases(id, boss["phases"])
	var announced := []
	em.phase_started.connect(func(_i: int, n: String, _t: String, _c: Color) -> void: announced.append(n))
	var info := em.boss_info()
	_check(info["thresholds"].size() == 2 and info["index"] == 0 and info["frac"] > 0.99, "barra de jefe: dos umbrales y fase 1")
	var i := em.index_of(id)
	var speed := em.speeds[i]
	em.lives[i] = em.max_lives[i] * 0.6
	em._update_phases(0.1)
	_check(announced.size() == 1 and em.boss_info()["index"] == 1, "al bajar del 66 % empieza la fase 2")
	_check(em.speeds[i] > speed and em.boss_info()["shield"] > 0.0, "la fase sube la velocidad y da invulnerabilidad breve")
	var life := em.lives[i]
	em.hit_index(i, 1000.0, 1000.0, 0.0, 150.0)
	_check(em.lives[i] == life, "el jefe es invulnerable entre fases")
	em._update_phases(2.0)
	em.hit_index(i, 10.0, 10.0, 0.0, 150.0)
	_check(em.lives[i] < life, "y vuelve a recibir daño después")
	em.lives[i] = em.max_lives[i] * 0.2
	em._update_phases(0.1)
	_check(announced.size() == 2 and em.boss_info()["index"] == 2, "fase 3 al bajar del 33 %")
	em.lives[i] = 1.0
	em._update_phases(5.0)
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(em.boss_info().is_empty() and em.boss_phases.is_empty(), "al morir el jefe desaparece la barra")
	em.queue_free()
	player.queue_free()


## Dos ascendencias por clase, y cada una con efectos o juego distintos a los de su pareja.
func _test_ascendancy_identity() -> void:
	for cdef in _classes:
		var pair: Array = cdef["ascendancies"]
		_check(pair.size() == 2, "%s tiene 2 ascendencias" % cdef["id"])
		var stat_sets: Array = []
		for a in pair:
			var set := {}
			for p in a["passives"]:
				for md in p["mods"]:
					set[md["stat"]] = true
			stat_sets.append(set)
			_check(a["passives"].size() == 20 and not str(a["description"]).is_empty(), "%s: 20 nodos y descripción" % a["id"])
		var shared := 0
		for k in stat_sets[0]:
			if stat_sets[1].has(k):
				shared += 1
		var union: int = stat_sets[0].size() + stat_sets[1].size() - shared
		_check(float(shared) / float(union) <= 0.35, "%s: sus dos ascendencias juegan distinto (%d de %d stats comunes)" % [cdef["id"], shared, union])
		# Cada una tiene al menos un stat que la otra no toca.
		for k in 2:
			var unique := 0
			for stat in stat_sets[k]:
				if not stat_sets[1 - k].has(stat):
					unique += 1
			_check(unique >= 2, "%s: ascendencia %d con identidad propia (%d stats únicos)" % [cdef["id"], k, unique])
	# Efectos nuevos: vida al matar, espinas y perforación extra.
	var c := CharacterData.new(_class_def("guerrero"), _tree)
	c.set_level(30)
	c.set_ascendancy(&"guardian_firewall")
	c.allocate_ascendancy_node(15)
	c.allocate_ascendancy_node(16)
	_check(c.stats.get_value(Stat.THORNS) >= 30.0, "Honeypot da espinas")
	c.set_ascendancy(&"berserker_hotfix")
	c.allocate_ascendancy_node(15)
	c.allocate_ascendancy_node(16)
	_check(c.stats.get_value(Stat.LIFE_ON_KILL) >= 8.0, "Sin fin de semana da vida al matar")
	var ex := CharacterData.new(_class_def("exploradora"), _tree)
	ex.set_level(30)
	var base: int = SkillCalc.compute(Motherboard.new(_db.skills.skills["rafaga_de_paquetes"], 1, []), ex)["pierce"]
	ex.set_level(60)
	ex.set_ascendancy(&"francotiradora_bugs")
	for n in [15, 16, 5, 6, 7, 8, 9]:   # Stack trace (16) y Perfilado total (9): +1 y +1
		ex.allocate_ascendancy_node(n)
	_check(SkillCalc.compute(Motherboard.new(_db.skills.skills["rafaga_de_paquetes"], 1, []), ex)["pierce"] == base + 2, "Stack trace y Perfilado total: los proyectiles atraviesan 2 enemigos más")
	# Un guardado con una ascendencia que ya no existe queda sin ascendencia y avisa.
	var old := CharacterData.new(_class_def("guerrero"), _tree)
	old.set_level(25)
	var data = JSON.parse_string(JSON.stringify(old.to_dict()))
	data["ascendancy_id"] = "senor_monolito"
	var loaded := CharacterData.from_dict(data, _class_def("guerrero"), _tree, _db)
	_check(loaded.ascendancy_def.is_empty() and loaded.flags.has("ascendancy_removed") and loaded.can_choose_ascendancy(), "ascendencia eliminada: vuelve a poder elegirse")


## Estados sobre el jugador: shock, chill y freeze con resistencias, y thorns / vida al matar.
func _test_player_statuses() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	var c := _new_character()
	c.set_level(10)
	player.setup(c, em)
	em.player = player
	player.global_position = Vector2(5000, 5000)
	_check(not player.apply_status("burn", 3.0), "solo shock, chill y freeze son estados de estado")
	_check(player.apply_status("shock", 3.0) and player.statuses.has("shock"), "el jugador se electrocuta")
	player.life = player.max_life()
	player.invulnerable = false
	var before := player.life
	# Con armadura/evasión del personaje de pruebas el golpe puede esquivarse: se repite hasta que entre.
	var taken := 0.0
	for k in 40:
		player.life = player.max_life()
		player.statuses.erase("shock")
		player.take_damage(10.0)
		var normal := player.max_life() - player.life
		player.life = player.max_life()
		player.statuses["shock"] = 3.0
		player.take_damage(10.0)
		var shocked := player.max_life() - player.life
		if normal > 0.0 and shocked > 0.0:
			taken = shocked / normal
			break
	_check(taken > 1.15, "electrocutado recibe más daño (×%.2f)" % taken)
	player.statuses.clear()
	player.apply_status("chill", 2.0)
	_check(player.statuses.has("chill"), "helado")
	# La resistencia reduce la duración.
	var resist_char := _new_character()
	resist_char.stats.add_modifier(Modifier.new(Stat.COLD_RES, Modifier.Type.FLAT, 75.0, [], "prueba"))
	var p2: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(p2)
	p2.setup(resist_char, em)
	p2.apply_status("freeze", 2.0)
	_check(p2.statuses.get("freeze", 0.0) < 0.6 and p2.statuses.get("freeze", 0.0) > 0.0, "75 %% de resistencia al frío: congelación mucho más corta (%.2f)" % p2.statuses.get("freeze", 0.0))
	_check(p2.is_frozen(), "congelado: no puede actuar")
	p2.statuses["freeze"] = 0.01
	p2._physics_process(0.1)
	_check(not p2.is_frozen() and not p2.apply_status("freeze", 2.0), "tras descongelarse no se vuelve a congelar enseguida")
	p2.queue_free()
	# Los enemigos con on_hit_status aplican el estado.
	var cond := em.spawn(Vector2(5000, 5010), Rarity.Enemy.NORMAL, em.type_index_of("condensador"))
	player.statuses.clear()
	var applied := false
	for k in 60:
		em.apply_status_to_player({"id": "shock", "chance": 100.0, "duration": 2.0})
		applied = applied or player.statuses.has("shock")
	_check(applied, "los golpes de enemigos aplican estados al jugador")
	_check(not em._status_of(em.index_of(cond)).is_empty(), "el Condensador electrocuta")
	# Espinas: golpe recibido, daño devuelto.
	var thorn_char := _new_character()
	thorn_char.stats.add_modifier(Modifier.new(Stat.THORNS, Modifier.Type.FLAT, 50.0, [], "prueba"))
	var p3: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(p3)
	p3.setup(thorn_char, em)
	p3.global_position = Vector2(8000, 8000)
	var bug := em.spawn(Vector2(8010, 8000), Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var bi := em.index_of(bug)
	em.lives[bi] = 1.0e6
	em.max_lives[bi] = 1.0e6
	var hit := false
	for k in 40:
		p3.life = p3.max_life()
		var l0 := em.lives[bi]
		p3.take_damage(5.0)
		if em.lives[bi] < l0:
			hit = true
			break
	_check(hit, "las espinas dañan al enemigo cercano")
	var kill_char := _new_character()
	kill_char.stats.add_modifier(Modifier.new(Stat.LIFE_ON_KILL, Modifier.Type.FLAT, 20.0, [], "prueba"))
	p3.character = kill_char
	p3.life = 10.0
	p3.notify_kill()
	_check(p3.life >= 29.9, "vida al matar")
	p3.queue_free()
	player.queue_free()
	em.queue_free()


## Rotura, sobrecarga e infección.
func _test_state_interactions() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	var id := em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, bug)
	var i := em.index_of(id)
	em.lives[i] = 1.0e6
	em.max_lives[i] = 1.0e6
	# Rotura: golpe físico a un congelado.
	em.freeze_time[i] = 2.0
	em.hit_ailments = {"type": "physical", "chances": {}, "effect": 1.0, "duration": 1.0}
	var before := em.lives[i]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[i], 150.0) and em.freeze_time[i] == 0.0, "rotura: +50 % y se acaba el hielo")
	# Sobrecarga: fuego sobre electrocutado explota.
	var other := em.spawn(Vector2(40, 0), Rarity.Enemy.NORMAL, bug)
	var oi := em.index_of(other)
	em.lives[oi] = 1.0e6
	em.max_lives[oi] = 1.0e6
	em.shock_time[i] = 3.0
	em.shock_amp[i] = 0.25
	em.hit_ailments = {"type": "fire", "chances": {}, "effect": 1.0, "duration": 1.0}
	var other_before := em.lives[oi]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(em._booms.size() == 1 and em.shock_time[i] == 0.0, "sobrecarga: el fuego gasta la descarga y encola una explosión")
	em.hit_ailments = {}
	em._update_booms()
	_check(em.lives[em.index_of(other)] < other_before, "la explosión daña a los cercanos")
	# Infección: envenenado + sangrando hace más daño por segundo.
	var solo := em.spawn(Vector2(4000, 0), Rarity.Enemy.NORMAL, bug)
	var si := em.index_of(solo)
	em.lives[si] = 1.0e6
	em.max_lives[si] = 1.0e6
	em.apply_ailment(si, Ailments.POISON, 100.0)
	var l1 := em.lives[si]
	em._update_dots(1.0)
	var poison_only := l1 - em.lives[si]
	em.apply_ailment(si, Ailments.BLEED, 100.0)
	var l2 := em.lives[si]
	em._update_dots(1.0)
	var both := l2 - em.lives[si]
	_check(both > poison_only * 1.5, "infección: veneno + sangrado (%.1f vs %.1f)" % [both, poison_only])
	em.free()


## Afijos nuevos (escudo, reflejo, curandero, teletransportador, estados) y resistencias que cambian por fase.
func _test_new_affixes_and_phase_resists() -> void:
	var em := EnemyManager.new()
	root.add_child(em)
	var player: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(player)
	player.setup(_new_character(), em)
	em.player = player
	player.global_position = Vector2(600, 0)
	em.roll_affixes = false
	var bug := em.type_index_of("bug")
	var sh := em.spawn(Vector2(0, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["escudado"])
	var si := em.index_of(sh)
	var shield: float = em.traits[si]["shield"]
	_check(shield > 0.0 and is_equal_approx(shield, em.max_lives[si] * 0.5), "el escudado lleva un escudo del 50 % de su vida")
	var life0 := em.lives[si]
	em.hit_ailments = {"type": "physical", "chances": {}, "effect": 1.0, "duration": 1.0}
	em.hit_index(si, shield * 0.4, shield * 0.4, 0.0, 150.0)
	_check(em.lives[si] == life0 and float(em.traits[si]["shield"]) < shield, "el escudo absorbe el daño primero")
	em.hit_index(si, shield, shield, 0.0, 150.0)
	_check(em.lives[em.index_of(sh)] < life0, "roto el escudo, el daño pasa")
	# Reflejo.
	var rf := em.spawn(Vector2(40, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["reflejo"])
	var ri := em.index_of(rf)
	em.lives[ri] = 1.0e7
	em.max_lives[ri] = 1.0e7
	player.invulnerable = false
	var reflected := false
	for k in 40:
		player.life = player.max_life()
		em.hit_ailments = {"type": "physical", "chances": {}, "effect": 1.0, "duration": 1.0}
		em.hit_index(ri, 10.0, 10.0, 0.0, 150.0)
		reflected = reflected or player.life < player.max_life()
	_check(reflected, "el reflejo te devuelve daño")
	em.hit_ailments = {}
	# Curandero.
	em.clear_all()
	var heal_id := em.spawn(Vector2(0, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["curandero"])
	var hurt_id := em.spawn(Vector2(60, 0), Rarity.Enemy.NORMAL, bug)
	var hi := em.index_of(hurt_id)
	em.lives[hi] = em.max_lives[hi] * 0.4
	em._update_affixes(1.0)
	_check(em.lives[em.index_of(hurt_id)] > em.max_lives[em.index_of(hurt_id)] * 0.4, "el curandero cura a sus vecinos")
	# Teletransportador: se acerca al jugador.
	em.clear_all()
	var tp := em.spawn(Vector2(0, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["teletransportador"])
	em._affix_timers["%d:teletransportador" % tp] = 0.0
	em._update_affixes(0.1)
	_check(em.positions[em.index_of(tp)].distance_to(player.global_position) < 400.0, "el teletransportador salta junto al jugador")
	# Estados: electrizante y gélido aplican estado al jugador.
	em.clear_all()
	var el := em.spawn(Vector2(0, 0), Rarity.Enemy.ELITE, bug, "", 1.0, [], ["electrizante", "gelido"])
	_check(em._status_of(em.index_of(el))["id"] == "shock" and em.is_immune_to(em.index_of(el), "chill"), "afijos con estado sobre el jugador")
	# Resistencias por fase de jefe.
	em.clear_all()
	player.global_position = Vector2(3000, 3000)
	var act1: Dictionary = DataLoader.load_json("res://data/act1.json")
	var boss: Dictionary = act1["zones"].filter(func(z: Dictionary) -> bool: return z.has("boss"))[0]["boss"]
	var bid := em.spawn(Vector2(0, 0), Rarity.Enemy.UNIQUE, em.type_index_of(boss["type"]), boss["name"], float(boss["life_mult"]), boss["abilities"])
	em.set_phases(bid, boss["phases"])
	var bi := em.index_of(bid)
	_check(em.resist_of(bi, "cold") == -25.0, "fase 1: débil al frío")
	em.lives[bi] = em.max_lives[bi] * 0.6
	em._update_phases(0.1)
	_check(em.resist_of(bi, "cold") == 40.0 and em.is_immune_to(bi, "chill"), "fase 2: resiste el frío y no se hiela")
	em.lives[bi] = em.max_lives[bi] * 0.2
	em._update_phases(5.0)
	_check(em.resist_of(bi, "physical") == 40.0 and em.is_immune_to(bi, "bleed"), "fase 3: resiste lo físico y no sangra")
	for aid in ["electrizante", "gelido", "reflejo", "escudado", "curandero", "teletransportador"]:
		_check(EnemyManager.affix_defs().has(aid), "afijo %s" % aid)
	em.queue_free()
	player.queue_free()


## RAM de grados nuevos: perforación y multicanal.
func _test_ram_grades() -> void:
	var gen := ItemGenerator.new(_db, 5)
	var c := _new_character()
	for family in [["puntero_salvaje_menor", "puntero_salvaje", "puntero_salvaje_mayor", "pierce"],
			["multicanal_menor", "multicanal", "multicanal_mayor", "extra_projectiles"]]:
		var values: Array = []
		for k in 3:
			var ram := gen.generate_ram(1, family[k])
			values.append(ram.special(family[3]))
			_check(ram.tier() == k + 1 or k == 1, "%s: grado %d" % [family[k], k + 1])
		_check(values[0] < values[1] and values[1] < values[2], "%s: crece con el grado (%s)" % [family[3], str(values)])
	var board := Motherboard.new(_db.skills.skills["rafaga_de_paquetes"], 1, ["DDR4"])
	board.install(gen.generate_ram(1, "multicanal_mayor"), 0)
	_check(SkillCalc.compute(board, c)["projectiles"] == 6, "multicanal mayor: +3 proyectiles")


## RAM en drones e invocaciones, penalización del Multicanal por nivel, Pipeline en
## invocaciones y que ninguna RAM compatible se quede sin efecto.
func _test_rams_everywhere() -> void:
	var c := _new_character()
	c.set_level(30)
	var rams: Dictionary = _db.skills.rams
	var skills: Dictionary = _db.skills.skills
	for id in ["drones_vigilancia", "robot_centinela", "dron_escolta", "agente_ia"]:
		var board := Motherboard.new(skills[id], 1, ["DDR4"])
		var before: Dictionary = SkillCalc.compute(board, c)
		board.install(RamModule.new(rams["multicanal_menor"]), 0)
		var after: Dictionary = SkillCalc.compute(board, c)
		_check(before["projectiles"] == 1 and after["projectiles"] == 2, "%s: +1 proyectil con el Multicanal Menor (%d → %d)" % [id, before["projectiles"], after["projectiles"]])
		_check(is_equal_approx(after["min_damage"], before["min_damage"] * 0.6), "%s: el Multicanal Menor quita un 40 %% en nivel 1" % id)
	_check(SkillCalc.projectile_penalty(40.0, 11) == 30.0 and SkillCalc.projectile_penalty(40.0, 40) == 20.0, "multicanal: la penalización baja 1 punto por nivel, hasta la mitad")
	_check(SkillCalc.compute(Motherboard.new(skills["paquete_rastreador"], 1, []), c)["homing"], "el Paquete Rastreador es teledirigido")
	var laser := Motherboard.new(skills["rafaga_de_paquetes"], 1, ["DDR5"])
	laser.install(RamModule.new(rams["guiado_laser"]), 0)
	var guided: Dictionary = SkillCalc.compute(laser, c)
	_check(guided["homing"] and guided["seek_range"] > 0.0, "Guiado por Láser: los proyectiles pasan a ser teledirigidos")
	# Las RAM de daño también suben el daño de las invocaciones.
	var golem := Motherboard.new(skills["golem_hardware"], 1, ["DDR3"])
	var g0: float = SkillCalc.compute(golem, c)["min_damage"]
	golem.install(RamModule.new(rams["fuerza_bruta"]), 0)
	_check(SkillCalc.compute(golem, c)["min_damage"] > g0 * 1.3, "invocaciones: la Fuerza Bruta sube el daño del golem")
	# Pipeline: la invocación ataca el doble de rápido en vez de invocarse dos veces.
	var bot := Motherboard.new(skills["robot_centinela"], 1, ["DDR3"])
	var i0: float = SkillCalc.compute(bot, c)["unit_interval"]
	bot.install(RamModule.new(rams["pipeline"]), 0)
	_check(is_equal_approx(SkillCalc.compute(bot, c)["unit_interval"], i0 / 2.0), "Pipeline: el robot centinela dispara el doble de rápido")
	_check(not RamModule.new(rams["pipeline"]).supports(skills["aura_overclock"]), "Pipeline no encaja en auras (las apagaría)")
	_check(not RamModule.new(rams["disparador_trampa"]).supports(skills["aura_mando"]), "una aura no se puede convertir en trampa")
	_check(not RamModule.new(rams["pasta_termica"]).supports(skills["dron_medico"]), "las RAM de daño no encajan en habilidades sin daño")
	# Auditoría: toda RAM que encaja en una habilidad cambia algo de su perfil.
	var keys := ["dps", "min_damage", "projectiles", "pierce", "projectile_chains", "chains", "projectile_speed", "homing", "radius",
		"width", "impact_radius", "rain_hits", "crit_chance", "life_leech", "ailments", "ailment_effect", "ailment_duration",
		"ailing_bonus", "deploy", "max_units", "unit_interval", "unit_life", "unit_reduction", "reserve", "aura_mods",
		"aura_regen", "aura_reduction", "aura_enemy", "aura_radius", "aura_anchor", "ability_power", "tick", "minion_interval", "drone_count", "count", "extra_devices",
		"uses_per_second", "repeats", "spend_charges", "life_cost", "trigger"]
	var dead := PackedStringArray()
	for sid in skills:
		var base := SkillCalc.compute(Motherboard.new(skills[sid], 10, []), c)
		for rid in rams:
			var ram := RamModule.new(rams[rid])
			if not ram.supports(skills[sid]):
				continue
			var board := Motherboard.new(skills[sid], 10, [ram.generation()])
			board.install(ram, 0)
			var p := SkillCalc.compute(board, c)
			var changed := false
			var has_area_ability: bool = base["kind"] == "unit" and (base["unit_ability"].has("radius")
				or (base["unit_abilities"] as Array).any(func(a: Dictionary) -> bool: return a.has("radius")))
			for k in keys + (["area_scale"] if has_area_ability else []):
				if str(base[k]) != str(p[k]):
					changed = true
					break
			if not changed:
				dead.append("%s+%s" % [sid, rid])
	_check(dead.is_empty(), "RAM compatibles sin efecto: %s" % ", ".join(dead))
	# Grados nuevos: área, velocidad, pipeline y guiado.
	for fam in ["cache_l3", "overclock", "pipeline"]:
		_check(rams.has(fam + "_menor") and rams.has(fam + "_mayor"), "RAM de grados: %s tiene menor y mayor" % fam)
	_check(rams.has("guiado_laser_mayor"), "RAM de grados: Guiado por Láser de Precisión")
	# Auras con alcance y auras que debilitan.
	var thr := SkillCalc.compute(Motherboard.new(skills["aura_throttling"], 1, []), c)
	_check(thr["aura_radius"] > 300.0 and thr["aura_enemy"]["slow"] > 0.1, "Aura de Throttling: radio y ralentiza a los enemigos")
	var exp_aura := SkillCalc.compute(Motherboard.new(skills["aura_exposicion"], 1, []), c)
	_check(exp_aura["aura_enemy"]["damage_taken"] > 0.1, "Aura de Exposición: los enemigos reciben más daño")
	var em := EnemyManager.new()
	em.roll_affixes = false
	var near := em.index_of(em.spawn(Vector2(100, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	var far_e := em.index_of(em.spawn(Vector2(900, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	for k in [near, far_e]:
		em.lives[k] = 1.0e6
		em.max_lives[k] = 1.0e6
	em.aura_fields = [{"pos": Vector2.ZERO, "radius": 360.0, "slow": 0.15, "damage_taken": 0.12}]
	em.hit_index(near, 100.0, 100.0, 0.0, 150.0)
	em.hit_index(far_e, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(1.0e6 - em.lives[near], 112.0) and is_equal_approx(1.0e6 - em.lives[far_e], 100.0), "aura que debilita: solo dentro de su radio")
	em.free()
	# Desbloqueos por nivel: cada clase tiene 5, con habilidades que existen, al menos una invocación,
	# una aura y una habilidad de movimiento (nivel 8).
	for cls in _classes:
		var unlocks: Array = cls.get("unlocks", [])
		var kinds := {}
		var choices := 0
		var movement := false
		for u in unlocks:
			var ids: Array = u.get("choice", [u.get("skill", "")])
			choices += 1 if u.has("choice") else 0
			for sid in ids:
				_check(skills.has(sid), "%s desbloquea %s, que existe" % [cls["id"], sid])
				kinds[skills.get(sid, {}).get("kind", "")] = true
				movement = movement or skills.get(sid, {}).get("tags", []).has("movement")
		_check(unlocks.size() == 5 and choices == 1 and kinds.has("aura") and (kinds.has("unit") or kinds.has("minion")) and movement,
			"%s: 5 desbloqueos (uno a elegir entre dos) con invocación, aura y movimiento" % cls["id"])
	var lvl := CharacterData.new(_classes[0], _tree)
	lvl.set_level(12)
	_check(lvl.due_unlocks().size() == 3, "al nivel 12 el guerrero tiene 3 habilidades por recibir")
	lvl.flags["unlock_aura_blindaje"] = true
	_check(lvl.due_unlocks().size() == 2, "las ya recibidas no se repiten")
	lvl.set_level(16)
	_check(lvl.due_unlocks().any(func(u: Dictionary) -> bool: return u.has("choice")), "al nivel 16 toca elegir entre dos")
	lvl.flags["unlock_golem_hardware"] = true   # personaje de antes de la elección
	_check(not lvl.due_unlocks().any(func(u: Dictionary) -> bool: return u.has("choice")), "quien ya recibió una de las dos no vuelve a elegir")
	# Hitos propios de las invocaciones y Sobrealimentación.
	var bot10 := SkillCalc.compute(Motherboard.new(skills["robot_centinela"], 10, []), c)
	_check(bot10["projectiles"] == 2 and bot10["max_units"] == 1, "Robot Centinela: su hito da +1 proyectil, no +1 invocación")
	var med1 := SkillCalc.compute(Motherboard.new(skills["dron_medico"], 1, []), c)
	var med20 := SkillCalc.compute(Motherboard.new(skills["dron_medico"], 20, []), c)
	_check(is_equal_approx(med20["ability_power"], 1.5) and med1["ability_power"] == 1.0, "Dron de Mantenimiento: +25 % de curación por hito")
	var over := Motherboard.new(skills["golem_hardware"], 1, ["DDR3"])
	var g_before := SkillCalc.compute(over, c)
	over.install(RamModule.new(rams["sobrealimentacion"]), 0)
	var g_after := SkillCalc.compute(over, c)
	_check(is_equal_approx(g_after["reserve"], g_before["reserve"] * 1.5) and g_after["min_damage"] > g_before["min_damage"], "Sobrealimentación: más reserva, más potencia")
	# Mando: los botones y ejes se añaden a las acciones existentes.
	Gamepad.setup()
	var pad_ok := InputMap.action_get_events(&"skill_1").any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton) \
		and InputMap.action_get_events(&"move_left").any(func(e: InputEvent) -> bool: return e is InputEventJoypadMotion)
	_check(pad_ok, "mando: habilidades en botones y movimiento en el stick izquierdo")
	Gamepad.block_skill_1()
	_check(Gamepad.skill_1_blocked(), "mando: tras interactuar con A, la habilidad 1 no se lanza a la vez")
	var link := Motherboard.new(skills["aura_mando"], 1, ["DDR4"])
	link.install(RamModule.new(rams["enlace_aura"]), 0)
	_check(SkillCalc.compute(link, c)["aura_on_unit"], "Enlace de Aura: el aura sigue a una invocación")
	var tower := Motherboard.new(skills["aura_mando"], 1, ["DDR5"])
	tower.install(RamModule.new(rams["torre_senal"]), 0)
	_check(SkillCalc.compute(tower, c)["aura_anchor"], "Torre de Señal: el aura queda anclada")
	# Ordenar la bolsa: placas primero y RAM por generación; lo demás no se mueve.
	var inv := Inventory.new()
	inv.bag[0] = RamModule.new(rams["pasta_termica"])
	inv.bag[1] = Item.new({"id": "x", "name": "Espada", "slot": "weapon", "level": 1, "tags": []}, Rarity.Item.NORMAL, 1)
	inv.bag[2] = Motherboard.new(skills["ping_letal"], 1, [])
	inv.bag[5] = RamModule.new(rams["ecc"])
	inv.sort_skill_items()
	_check(inv.bag[0] is Motherboard and inv.bag[1].display_name() == "Espada" and (inv.bag[2] as RamModule).generation() == "DDR3"
		and (inv.bag[5] as RamModule).generation() == "DDR5", "ordenar la bolsa: placas, luego RAM por generación, sin mover el resto")


## Prólogo: todo punto de interés se alcanza caminando (dentro de los límites que
## impiden salir de la pantalla) y tiene flecha de objetivo si es parte de la historia.
func _test_prologue_reachable() -> void:
	for room in PrologueStage.HOTSPOTS:
		for h in PrologueStage.HOTSPOTS[room]:
			if room == "pasillo":
				_check(absf(float(h["lat"])) <= 0.85 and float(h["depth"]) <= 1.0, "prólogo: %s se alcanza en el pasillo" % h["action"])
			else:
				var lim: Vector2 = PrologueStage.WALK_LIMITS.get(room, Vector2(12, 9999))
				_check(float(h["x"]) >= lim.x and float(h["x"]) <= lim.y, "prólogo: %s queda dentro de los límites de %s" % [h["action"], room])
	for action in ["to_hallway", "to_office", "talk_rafa", "rack"]:
		_check(PrologueStage.GOAL_MARKERS.has(action), "prólogo: el objetivo %s tiene flecha" % action)
	var calle: Vector2 = PrologueStage.WALK_LIMITS["calle"]
	_check(calle.y <= float(PrologueStage.ROOM_WIDTH["calle"]) - PrologueStage.VIEW.x / 2.0, "prólogo: en el límite de la calle la cámara aún centra al personaje (no sale de la pantalla)")


## Objetos de misión: cada uno tiene su propio dibujo (solo la cinta del DBA es una cinta).
func _test_quest_item_art() -> void:
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for z in act["zones"]:
			for q in z.get("quest_items", []):
				var kind := QuestItemArt.kind_for(q)
				_check(kind != "tape" or q["id"] == "cinta_backup", "objeto de misión %s sin dibujo propio" % q["id"])
	_check(QuestItemArt.kind_for({"id": "kindle_paez"}) == "kindle", "objeto de misión: el Kindle se dibuja como Kindle")
	_check(QuestItemArt.kind_for({"id": "cache_2"}) == "ice_cache", "objeto de misión: los bloques de caché son de hielo")


## Música: cada zona de los tres actos tiene una pista que existe; Eugenio y las voces de los NPC.
func _test_music_and_voices() -> void:
	var music: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/music.json"))
	var zones: Dictionary = music["zones"]
	for path in ["res://data/act1.json", "res://data/act2.json", "res://data/act3.json", "res://data/act4.json"]:
		var act: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for z in act["zones"]:
			_check(zones.has(z["id"]), "música: la zona %s tiene pista" % z["id"])
			if z.has("boss"):
				_check(String(zones.get(z["id"], "")).begins_with("boss"), "música: la zona del jefe %s suena a jefe" % z["id"])
	for id in music["tracks"]:
		_check(Sfx.audio_path("res://assets/audio/music/%s" % id) != "", "música: existe %s (tools/generate_zone_music.gd y convert_audio.ps1)" % id)
	for z in zones:
		_check(music["tracks"].has(zones[z]), "música: la pista %s de %s está definida" % [zones[z], z])
	var camp3_bars: Array = load("res://tools/generate_zone_music.gd").load_melody_file(String(music["tracks"]["camp3"]["melody_file"]))
	_check(camp3_bars.size() == 12 and int(music["tracks"]["camp3"]["bars"]) % camp3_bars.size() == 0, "música: el campamento del acto III usa la melodía del archivo (12 compases)")
	var camp3_ok := true
	for bar: Array in camp3_bars:
		var beats := 0.0
		for ev: Array in bar:
			beats += float(ev[1])
		camp3_ok = camp3_ok and absf(beats - 4.0) < 0.01
	_check(camp3_ok, "música: cada compás de la melodía del campamento III suma 4 tiempos")
	# Bucles: cada pista dice dónde empieza su bucle, después de la intro y antes del final.
	var loops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/music_loops.json"))
	for id in music["tracks"]:
		# OGG (T63): el inicio del bucle, de muestras a segundos con la frecuencia de la música.
		var stream := Sfx.load_looped("res://assets/audio/music/%s" % id, int(loops.get(id, -1)), Sfx.MUSIC_RATE)
		var start := float(loops.get(id, -1)) / Sfx.MUSIC_RATE
		_check(stream != null and start >= 0.0 and start < stream.get_length(), "música: %s tiene inicio de bucle válido" % id)
		if stream:
			_check(stream.get_length() - start >= 30.0, "música: el bucle de %s dura al menos 30 s" % id)
			var ogg := stream as AudioStreamOggVorbis
			_check(ogg == null or (ogg.loop and is_equal_approx(ogg.loop_offset, start)), "música: el bucle de %s empieza tras la intro" % id)
	for amb in ["camp", "rom", "flash"]:
		var a := Sfx.load_looped("res://assets/audio/ambient/%s" % amb)
		_check(a != null and a.get_length() >= 20.0, "ambiente: %s dura al menos 20 s" % amb)
	var npcs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	for id in npcs["npcs"]:
		var voice: Dictionary = npcs["npcs"][id].get("voice", {})
		_check(voice.get("gender", "") in ["male", "female", "neutral"], "voz: %s tiene género" % id)
	var eugenio: Dictionary = npcs["dialogues"]["eugenio"]
	_check(String(eugenio["nodes"]["hola"]["text"]).begins_with("¿Oyes eso del fondo? ¡Que rolón!"), "Eugenio: abre con la música del fondo")
	var tangents := 0
	for k in eugenio["nodes"]:
		var n: Dictionary = eugenio["nodes"][k]
		for t in [n.get("text", "")] + n.get("again", []):
			if "neurodivergencia" in String(t):
				tangents += 1
	for t in eugenio["greeting_again"] + eugenio["menu"]:
		if "neurodivergencia" in String(t) or "Chappell" in String(t) or "NewJeans" in String(t):
			tangents += 1
	_check(tangents >= 6, "Eugenio: se distrae y culpa a su neurodivergencia (%d)" % tangents)


## Árbol: las temáticas de estados y aliados tienen 3-5 clusters, del lado de las clases que las usan,
## y no hay nodos encimados (ni aristas sobre nodos ajenos).
func _test_tree_themes_and_spacing() -> void:
	var radius_by_kind := {PassiveNode.Kind.MINOR: 10.0, PassiveNode.Kind.NOTABLE: 22.0, PassiveNode.Kind.KEYSTONE: 30.0, PassiveNode.Kind.CLASS_START: 30.0}
	var all_nodes: Array = _tree.nodes.values()
	var overlaps := 0
	for i in all_nodes.size():
		var a: PassiveNode = all_nodes[i]
		for j in range(i + 1, all_nodes.size()):
			var b: PassiveNode = all_nodes[j]
			if a.position.distance_to(b.position) < radius_by_kind[a.kind] + radius_by_kind[b.kind] + 4.0:
				overlaps += 1
	_check(overlaps == 0, "no hay nodos encimados en el árbol (%d pares)" % overlaps)
	var through := 0
	for e in _tree.edges:
		var pa: Vector2 = _tree.get_node_data(e.x).position
		var pb: Vector2 = _tree.get_node_data(e.y).position
		for n: PassiveNode in all_nodes:
			if n.id == e.x or n.id == e.y:
				continue
			if Geometry2D.get_closest_point_to_segment(n.position, pa, pb).distance_to(n.position) < radius_by_kind[n.kind] + 1.0:
				through += 1
	_check(through == 0, "ninguna arista pasa por encima de un nodo (%d)" % through)
	# Clusters por temática y su sector (ángulo alrededor del centro, 0 = derecha, sentido horario).
	var sectors := {"hemorragia": 300.0, "criogenia": 90.0, "toxinas": 60.0, "sobrecarga": 150.0, "ignicion": 180.0, "automatizacion": 210.0, "legion": 200.0}
	var tolerance := {"hemorragia": 80.0, "criogenia": 140.0, "toxinas": 80.0, "sobrecarga": 90.0, "ignicion": 70.0, "automatizacion": 55.0, "legion": 65.0}
	var counts := {}
	var near := {}
	for cl in _tree.clusters.values():
		var t: String = cl["theme"]
		counts[t] = int(counts.get(t, 0)) + 1
		if sectors.has(t):
			var ang := fposmod(rad_to_deg(atan2(cl["y"], cl["x"])), 360.0)
			var diff := absf(wrapf(ang - sectors[t], -180.0, 180.0))
			if diff <= tolerance[t]:
				near[t] = int(near.get(t, 0)) + 1
	for t in sectors:
		_check(int(counts.get(t, 0)) >= 3 and int(counts.get(t, 0)) <= 5, "%s: entre 3 y 5 clusters (%d)" % [t, counts.get(t, 0)])
		_check(int(near.get(t, 0)) >= int(counts.get(t, 0)) - 1, "%s: sus clusters están del lado de sus clases (%d de %d)" % [t, near.get(t, 0), counts.get(t, 0)])
	_check(_tree.themes.has("legion") and PassiveIcons.has_icon("legion"), "temática y icono de Legión")
	# Los nodos de aliados dan stats de aliados; hay notables distintos para variar entre clusters.
	var allied_stats := {}
	var legion_notables := {}
	for n: PassiveNode in all_nodes:
		if n.theme == "legion":
			for m in n.mods:
				allied_stats[m.stat] = true
			if n.kind == PassiveNode.Kind.NOTABLE:
				legion_notables[n.title] = true
	for k in [Stat.MINION_LIFE, Stat.MINION_DAMAGE, Stat.RESERVATION_EFFICIENCY, Stat.AURA_EFFECT]:
		_check(allied_stats.has(k), "Legión da %s" % k)
	_check(legion_notables.size() >= 4, "Legión tiene notables distintos (%d)" % legion_notables.size())
	var status_nodes := 0
	for n: PassiveNode in all_nodes:
		for m in n.mods:
			if m.stat == Stat.STATUS_RESIST:
				status_nodes += 1
	_check(status_nodes >= 5, "hay nodos de resistencia a estados (%d)" % status_nodes)


## Choque térmico (frío sobre un enemigo en llamas) y resistencia a estados sobre el jugador.
func _test_thermal_shock_and_status_resist() -> void:
	var em := EnemyManager.new()
	em.roll_affixes = false
	var id := em.spawn(Vector2.ZERO, Rarity.Enemy.NORMAL, em.type_index_of("bug"))
	var i := em.index_of(id)
	em.lives[i] = 1.0e6
	em.max_lives[i] = 1.0e6
	em.burn_time[i] = 3.0
	em.burn_dps[i] = 10.0
	em.hit_ailments = {"type": "cold", "chances": {}, "effect": 1.0, "duration": 1.0}
	var before := em.lives[i]
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	_check(is_equal_approx(before - em.lives[i], 140.0) and em.burn_time[i] == 0.0, "choque térmico: +40 % y se apaga la quemadura")
	# Superconductor: rayo a un helado → arcos a 2 vecinos con el 40 % (más con efecto de interacciones).
	var n1 := em.index_of(em.spawn(Vector2(60, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	var n2 := em.index_of(em.spawn(Vector2(0, 70), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	var far := em.index_of(em.spawn(Vector2(900, 0), Rarity.Enemy.NORMAL, em.type_index_of("bug")))
	for k in [n1, n2, far]:
		em.lives[k] = 1.0e6
		em.max_lives[k] = 1.0e6
	em.interaction_power = 1.5
	em.chill_time[i] = 2.0
	em.hit_ailments = {"type": "lightning", "chances": {}, "effect": 1.0, "duration": 1.0}
	em.hit_index(i, 100.0, 100.0, 0.0, 150.0)
	em.call("_update_arcs")
	_check(is_equal_approx(1.0e6 - em.lives[n1], 60.0) and is_equal_approx(1.0e6 - em.lives[n2], 60.0) and em.lives[far] == 1.0e6 \
		and em.chill_time[i] == 0.0, "superconductor: arcos del 40 % ×1.5 a los 2 vecinos y se gasta el frío")
	em.free()
	var base := _new_character()
	var tough := _new_character()
	tough.stats.add_modifier(Modifier.new(Stat.STATUS_RESIST, Modifier.Type.FLAT, 50.0, [], "prueba"))
	var e2 := EnemyManager.new()
	root.add_child(e2)
	var pa: Player = load("res://scenes/game/player.tscn").instantiate()
	var pb: Player = load("res://scenes/game/player.tscn").instantiate()
	root.add_child(pa)
	root.add_child(pb)
	pa.setup(base, e2)
	pb.setup(tough, e2)
	pa.apply_status("shock", 4.0)
	pb.apply_status("shock", 4.0)
	_check(is_equal_approx(pb.statuses["shock"], pa.statuses["shock"] * 0.5), "50 %% de resistencia a estados: la mitad de duración (%.1f vs %.1f)" % [pb.statuses["shock"], pa.statuses["shock"]])
	pa.queue_free()
	pb.queue_free()
	e2.queue_free()
