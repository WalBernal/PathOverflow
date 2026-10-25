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
	_test_events_music_colorblind()
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
	_check(atlas.get_height() / 32 >= EnemyManager.enemy_types().size(), "una fila del atlas por tipo")
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
		if z.get("cutscene_on_enter") is Dictionary:
			referenced.append(z["cutscene_on_enter"]["id"])
		for e in z.get("exits", []):
			if e.has("cutscene"):
				referenced.append(e["cutscene"])
	for id in referenced:
		_check(cutscenes.has(id), "escena inexistente: %s" % id)
	for id in cutscenes:
		for step in cutscenes[id]["steps"]:
			if step.has("speaker"):
				_check(step["speaker"] == "player" or npc_data["npcs"].has(step["speaker"]), "%s: hablante desconocido %s" % [id, step["speaker"]])
			if step.has("effect"):
				var prologue_fx: bool = id.begins_with("prologo_") and step["effect"] in ["lights_flicker", "fans", "rafa_stands", "shock"]
				_check(prologue_fx or step["effect"] in ["glitch", "shake", "blackout", "fade_in", "dino"], "%s: efecto desconocido" % id)
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
		_check(ResourceLoader.exists("res://assets/audio/music/%s_combate.wav" % t) and int(loops.get(t + "_combate", -1)) == int(loops.get(t, -2)),
			"capa de combate de %s sincronizada con la pista" % t)
	# Modo daltónico: la rareza también en letra.
	_check(LootManager.rarity_tag(Item.new(_db.bases["espada_oxidada"], Rarity.Item.RARE, 5)) == "R"
		and LootManager.rarity_tag(Item.new(_db.bases["espada_oxidada"], Rarity.Item.NORMAL, 5)) == "", "chapita de rareza para daltónicos")


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
	for k in saved_rules:
		LootFilter.set_rule(k, saved_rules[k])


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
	_check(camara["entries"].has("from_post"), "y se puede volver del POST a la Cámara")
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
	_check(music["zones"].get("modo_smm", "") == "boss4" and music["tracks"].has("boss4_fase") and ResourceLoader.exists("res://assets/audio/music/boss4_fase.wav"), "música del jefe con versión de fase")
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
	_check(ZoneEvents.KINDS.size() == ZoneEvents.WEIGHTS.size() and ZoneEvents.KINDS.has("bombs") and ZoneEvents.KINDS.has("escort") and ZoneEvents.KINDS.has("merchant"),
		"tres eventos de zona nuevos, cada uno con su peso")
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
	_check(_tree.mastery_mismatches.is_empty(), "las maestrías apuntan a sus notables: %s" % ", ".join(_tree.mastery_mismatches))
	var masteries: Array = _tree.nodes.values().filter(func(n: PassiveNode) -> bool: return n.is_mastery())
	_check(masteries.size() == 7, "una maestría por sector (%d)" % masteries.size())
	for n: PassiveNode in masteries:
		_check(n.choices.size() == 3 and n.kind == PassiveNode.Kind.NOTABLE, "%s: 3 opciones" % n.title)
	# Guerrero: su maestría (Soporte Técnico) está junto a su inicio.
	var c := CharacterData.new(_classes[0], _tree)
	c.level = 30
	var mid := -1
	for n: PassiveNode in masteries:
		if n.title == "Maestría de Soporte Técnico":
			mid = n.id
	_check(mid != -1 and c.passives.allocate_path(mid, 99) > 0, "la maestría del guerrero se puede asignar")
	var res_first := c.stats.get_value(Stat.FIRE_RES)
	var block_first := c.stats.get_value(Stat.BLOCK_CHANCE)
	_check(c.passives.mastery_choice(mid) == 0, "por defecto, la primera opción (el efecto de antes)")
	_check(c.passives.set_mastery_choice(mid, 1), "se elige otra opción")
	_check(c.stats.get_value(Stat.FIRE_RES) < res_first and c.stats.get_value(Stat.BLOCK_CHANCE) > block_first, "cambiar de opción cambia las stats")
	var saved := c.to_dict()
	var back := CharacterData.from_dict(saved, _classes[0], _tree, _db)
	_check(back.passives.mastery_choice(mid) == 1 and is_equal_approx(back.stats.get_value(Stat.BLOCK_CHANCE), c.stats.get_value(Stat.BLOCK_CHANCE)), "la elección se guarda y se carga")
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


func _test_shaped_clusters() -> void:
	var shaped := 0
	var themes := {}
	for c in _tree.clusters.values():
		if c.has("segments"):
			shaped += 1
			themes[c["theme"]] = true
	_check(shaped >= 50, "la mayoría de los clusters tienen forma (%d)" % shaped)
	for t in ["vida", "fuego", "rayo", "frio"]:
		_check(themes.has(t), "cluster con forma de %s" % t)


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
	_check(low["max_damage"] > full["max_damage"] * 1.3, "con vida baja, +40%% de daño (%.1f → %.1f)" % [full["max_damage"], low["max_damage"]])
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
	_check(stock.size() == Economy.STOCK_BOARDS + Economy.STOCK_RAMS, "la tienda tiene placas y RAM")
	for item in stock:
		_check(item.item_level == 12, "mercancía del nivel del jugador")
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
		_check(FileAccess.file_exists("res://assets/audio/music/%s.wav" % id), "música: existe %s.wav (tools/generate_zone_music.gd)" % id)
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
		var wav := load("res://assets/audio/music/%s.wav" % id) as AudioStreamWAV
		var start := int(loops.get(id, -1))
		_check(wav != null and start >= 0 and start < Sfx.frame_count(wav), "música: %s tiene inicio de bucle válido" % id)
		if wav:
			_check(wav.get_length() - start / float(wav.mix_rate) >= 30.0, "música: el bucle de %s dura al menos 30 s" % id)
			# El bucle tiene que llegar hasta el final real de la pista (no a data.size() / 2).
			Sfx.set_loop(wav, start)
			_check(absf(wav.loop_end / float(wav.mix_rate) - wav.get_length()) < 0.05, "música: el bucle de %s acaba al final de la pista" % id)
	for amb in ["camp", "rom", "flash"]:
		var a := load("res://assets/audio/ambient/%s.wav" % amb) as AudioStreamWAV
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
