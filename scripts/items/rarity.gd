class_name Rarity
## Rarezas de objetos y categorías de enemigos. Valores de diseño: ajústalos.

enum Item { NORMAL, MAGIC, RARE, UNIQUE, SET, ULTRA_RARE }
enum Enemy { NORMAL, SPECIAL, ELITE, UNIQUE }

## min/max_affixes y max_prefixes/max_suffixes: afijos aleatorios que puede tirar.
## Únicos y de conjunto tienen modificadores fijos definidos en data/items.
## drop_weight: probabilidad relativa al generar botín.
const ITEM_INFO := {
	Item.NORMAL: {"name": "Normal", "color": Color("c8c8c8"), "min_affixes": 0, "max_affixes": 0, "max_prefixes": 0, "max_suffixes": 0, "drop_weight": 60.0},
	Item.MAGIC: {"name": "Mágico", "color": Color("8888ff"), "min_affixes": 1, "max_affixes": 2, "max_prefixes": 1, "max_suffixes": 1, "drop_weight": 28.0},
	Item.RARE: {"name": "Raro", "color": Color("ffff77"), "min_affixes": 3, "max_affixes": 6, "max_prefixes": 3, "max_suffixes": 3, "drop_weight": 10.0},
	Item.UNIQUE: {"name": "Único", "color": Color("af6025"), "min_affixes": 0, "max_affixes": 0, "max_prefixes": 0, "max_suffixes": 0, "drop_weight": 0.8},
	Item.SET: {"name": "De conjunto", "color": Color("1ba01b"), "min_affixes": 0, "max_affixes": 0, "max_prefixes": 0, "max_suffixes": 0, "drop_weight": 0.8},
	# Ultra-raro: como un raro con más afijos, siempre del mejor tier disponible.
	Item.ULTRA_RARE: {"name": "Ultra-raro", "color": Color("ff5ac8"), "min_affixes": 7, "max_affixes": 8, "max_prefixes": 4, "max_suffixes": 4, "drop_weight": 0.15},
}

## Multiplicadores sobre las stats base del monstruo y su botín.
## drop_chance: probabilidad de soltar cada uno de sus drop_count objetos.
const ENEMY_INFO := {
	Enemy.NORMAL: {"name": "Normal", "color": Color("c8c8c8"), "life_mult": 1.0, "damage_mult": 1.0, "extra_mods": 0, "xp_mult": 1.0, "item_rarity_bonus": 0.0, "drop_chance": 0.12, "drop_count": 1},
	Enemy.SPECIAL: {"name": "Especial", "color": Color("8888ff"), "life_mult": 2.0, "damage_mult": 1.2, "extra_mods": 1, "xp_mult": 3.0, "item_rarity_bonus": 50.0, "drop_chance": 0.4, "drop_count": 1},
	Enemy.ELITE: {"name": "Élite", "color": Color("ffff77"), "life_mult": 5.0, "damage_mult": 1.5, "extra_mods": 3, "xp_mult": 7.5, "item_rarity_bonus": 200.0, "drop_chance": 1.0, "drop_count": 2},
	# Los únicos tienen habilidades y botín propios; esto es solo la base.
	Enemy.UNIQUE: {"name": "Único", "color": Color("af6025"), "life_mult": 10.0, "damage_mult": 2.0, "extra_mods": 0, "xp_mult": 15.0, "item_rarity_bonus": 500.0, "drop_chance": 1.0, "drop_count": 5},
}


static func item_name(rarity: int) -> String:
	return ITEM_INFO[rarity]["name"]


static func item_color(rarity: int) -> Color:
	return ITEM_INFO[rarity]["color"]


static func enemy_name(rarity: int) -> String:
	return ENEMY_INFO[rarity]["name"]


static func enemy_color(rarity: int) -> Color:
	return ENEMY_INFO[rarity]["color"]
