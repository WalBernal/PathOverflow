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
	_check(_classes.size() == 5, "deben existir 5 clases")
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
	em.spawn(Vector2(0, 0), Rarity.Enemy.NORMAL)
	em.spawn(Vector2(10, 0), Rarity.Enemy.UNIQUE)
	em.spawn(Vector2(1000, 0), Rarity.Enemy.NORMAL)
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
	var kinds := ["melee_area", "nova", "projectile", "ground_aoe", "blink"]
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
	var camp: Dictionary = DataLoader.load_json("res://data/camp.json")
	var dialogues: Dictionary = camp["dialogues"]
	for npc in camp["npcs"]:
		_check(dialogues.has(npc["dialogue"]), "diálogo de %s" % npc["id"])
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
	var known := ["move", "talk_ada", "install_ram", "kevin", "leave_camp", "use_skill", "kill", "flask", "loot", "equip", "passives"]
	for step in tutorial["steps"]:
		_check(known.has(step["id"]), "paso de tutorial sin condición: %s" % step["id"])

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
	for f in Player.FLASKS:
		_check(ItemIcons.has_icon(f["icon"]), "icono de la poción %s" % f["name"])
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