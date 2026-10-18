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
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"attack", &"toggle_passives",
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
