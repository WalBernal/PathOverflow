extends SceneTree
## Pruebas rápidas de la lógica pura (stats, árbol, objetos, datos). Ejecutar con:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_core.gd

var _failures := 0
var _tree: PassiveTree
var _db: ItemDatabase
var _classes: Array


func _initialize() -> void:
	_tree = PassiveTree.load_from_json("res://data/passive_tree.json")
	_db = ItemDatabase.load_from_dir()
	_classes = DataLoader.load_json("res://data/classes.json")["classes"]
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
	_test_walk_animation()
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
		_check(c["ascendancies"].size() == 3, "%s debe tener 3 ascendencias" % c["id"])
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
	em.enemy_killed.connect(func(_r: int, _xp: int, _pos: Vector2) -> void: kills[0] += 1)
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
	c.set_level(12)
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
	_check(loaded.level == 12 and loaded.experience == c.experience, "nivel y experiencia")
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
	var kinds := ["melee_area", "nova", "projectile", "ground_aoe", "blink", "dash", "cone", "beam", "boomerang", "spin", "trap", "chain", "minion", "degen_area"]
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
		_check(board.level == 11, "nivel de la placa según el nivel de objeto (%d)" % board.level)
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
	_check(is_equal_approx(multi["max_damage"], base["max_damage"] * 0.75), "multicanal: 25% menos de daño")
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
		for node_id in d["nodes"]:
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
	for path in ["res://data/act1.json", "res://data/act2.json"]:
		var a: Dictionary = DataLoader.load_json(path)
		for z in a["zones"]:
			zones[z["id"]] = z
			all_zones.append(z)
	for path in ["res://data/act1.json", "res://data/act2.json"]:
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
			var packs := zone.pack_centers(int(cfg["packs"]), rng)
			_check(packs.size() >= int(cfg["packs"]) * 0.8, "%s: solo caben %d de %d grupos" % [z["id"], packs.size(), cfg["packs"]])
			for p in packs:
				for k in zone.key_points():
					_check(p.distance_to(k) >= 450.0, "%s: grupo demasiado cerca de una entrada/NPC" % z["id"])
		zone.free()
	_check(bosses == 1, "el acto tiene un jefe")
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
				_check(npc_data["npcs"].has(step["speaker"]), "%s: hablante desconocido %s" % [id, step["speaker"]])
			if step.has("effect"):
				_check(step["effect"] in ["glitch", "shake", "blackout", "fade_in", "dino"], "%s: efecto desconocido" % id)
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
	_check(reunion_text.contains("El Pepe") and reunion_text.contains("prestador de servicios retirado"), "culpan a El Pepe")


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
					_check(quest_items.has(step["item"]), "%s: objeto %s no está en ninguna zona" % [id, step["item"]])
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
	var kinds := ["melee", "ranged", "charge", "slam", "cone"]
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
				_check(a["kind"] in ["projectile_nova", "ground_marks", "summon"], "habilidad de jefe desconocida")


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
	var start := c.passives.start_node_id
	c.passives.allocate_path(_tree.neighbors(start)[0], 5)
	var data = JSON.parse_string(JSON.stringify(c.to_dict()))
	var same := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(same.passives.spent_points() == 1 and not same.flags.has("passives_refunded"), "misma versión del árbol: se conservan")
	data["passive_tree_version"] = _tree.version - 1
	var old := CharacterData.from_dict(data, _classes[0], _tree, _db)
	_check(old.passives.spent_points() == 0 and old.flags.has("passives_refunded"), "versión antigua: puntos devueltos y aviso")