class_name Economy
## Tokens: la moneda del juego (los sueltan los enemigos, se gastan con el
## comerciante). Aquí están las cuentas: cuánto sueltan, cuánto cuesta cada
## cosa y qué tiene a la venta la tienda.

const CURRENCY := "Tokens"
const COLOR := Color("f2c14e")
## Probabilidad de soltar tokens según la rareza del enemigo (normal ≈ 2 de cada 5).
const DROP_CHANCE := {Rarity.Enemy.NORMAL: 0.4, Rarity.Enemy.SPECIAL: 0.7, Rarity.Enemy.ELITE: 1.0, Rarity.Enemy.UNIQUE: 1.0}
const DROP_MULT := {Rarity.Enemy.NORMAL: 1.0, Rarity.Enemy.SPECIAL: 2.0, Rarity.Enemy.ELITE: 4.0, Rarity.Enemy.UNIQUE: 15.0}
## Lo que paga el comerciante al venderle algo (fracción del precio de compra).
const SELL_FRACTION := 0.2


## Tokens de un enemigo (0 = no suelta nada).
static func drop_amount(area_level: int, enemy_rarity: int, rng: RandomNumberGenerator) -> int:
	if rng.randf() >= float(DROP_CHANCE.get(enemy_rarity, 0.4)):
		return 0
	var base := rng.randi_range(1, 3) + area_level / 3
	return maxi(1, int(round(base * float(DROP_MULT.get(enemy_rarity, 1.0)))))


## Precio de compra.
static func price(item: Item) -> int:
	var lvl := maxi(1, item.item_level)
	if item is Motherboard:
		return 40 + lvl * 8 + (item as Motherboard).slots.size() * 10
	if item is RamModule:
		return 20 + lvl * 4 + item.affixes.size() * 6
	if item is Flask:
		return 15 + lvl * 2
	return 10 + lvl * 2 + item.affixes.size() * 5 + item.rarity * 10


## Lo que se recibe al venderlo (los objetos clave no se venden).
static func sell_price(item: Item) -> int:
	if item is KeyItem:
		return 0
	return maxi(1, int(price(item) * SELL_FRACTION))


## Puesto de Aída (campamento tras el Acto I): equipo raro del nivel del jugador,
## alguno mágico y dos pociones.
const GEAR_STOCK_RARE := 4
const GEAR_STOCK_MAGIC := 3


static func generate_gear_stock(gen: ItemGenerator, level: int) -> Array[Item]:
	var stock: Array[Item] = []
	for k in GEAR_STOCK_RARE:
		stock.append(gen.generate(level, Rarity.Item.RARE))
	for k in GEAR_STOCK_MAGIC:
		stock.append(gen.generate(level, Rarity.Item.MAGIC))
	for k in 2:
		var f := gen.generate_flask(level)
		if f:
			stock.append(f)
	return stock


## Reforjar en la mesa de Mario: mismos base, nivel y rareza, afijos nuevos.
## Precio: más de la mitad de lo que vale (los únicos y de conjunto no se reforjan).
static func reforge_price(item: Item) -> int:
	return maxi(10, int(price(item) * 0.6))


static func can_reforge(item: Item) -> bool:
	return item != null and item.rarity in [Rarity.Item.MAGIC, Rarity.Item.RARE] and not (item is Motherboard or item is RamModule or item is Flask)


## Mercancía de Nacho (T70): placas de los tres atributos (siempre hay algo para
## cualquier clase), RAM de módulos distintos, un par de pociones, la **oferta del
## día** (una placa con más ranuras, rebajada) y el **contrabando** (una placa de
## nivel más alto y cinco ranuras, carísima). Las placas, algo mejores que las que
## caen (nivel - 1 en vez de - 3): para eso se pagan.
const STOCK_BOARDS_PER_ATTRIBUTE := 3
const STOCK_RAMS_DISTINCT := 10
const STOCK_FLASKS := 2
const DEAL_DISCOUNT := 0.6
const CONTRABAND_MARKUP := 2.5
## Etiqueta de la tienda en el objeto (meta "shop_tag"): "deal" u "contraband".
const TAG_DEAL := "deal"
const TAG_CONTRABAND := "contraband"


static func generate_stock(gen: ItemGenerator, level: int) -> Array[Item]:
	var stock: Array[Item] = []
	var seen_skills := {}
	for attr in ["str", "dex", "int"]:
		var options := gen.skill_options(level, attr)
		for k in STOCK_BOARDS_PER_ATTRIBUTE:
			var free := options.filter(func(id) -> bool: return not seen_skills.has(id))
			var id: String = (free if not free.is_empty() else options)[gen.rng.randi_range(0, (free if not free.is_empty() else options).size() - 1)]
			seen_skills[id] = true
			var board := gen.generate_motherboard(level, id, 0)
			board.level = clampi(level - 1, 1, Motherboard.MAX_LEVEL)
			stock.append(board)
	var rams: Array = []
	for id in gen.db.skills.rams:
		if int(gen.db.skills.rams[id].get("min_level", 1)) <= level:
			rams.append(id)
	for k in range(rams.size() - 1, 0, -1):   # barajar con el rng del generador
		var j := gen.rng.randi_range(0, k)
		var tmp = rams[k]
		rams[k] = rams[j]
		rams[j] = tmp
	for k in mini(STOCK_RAMS_DISTINCT, rams.size()):
		stock.append(gen.generate_ram(level, rams[k]))
	for k in STOCK_FLASKS:
		var f := gen.generate_flask(level)
		if f:
			stock.append(f)
	var deal := gen.generate_motherboard(level, "", 4)
	deal.level = clampi(level - 1, 1, Motherboard.MAX_LEVEL)
	deal.set_meta("shop_tag", TAG_DEAL)
	stock.append(deal)
	var contraband := gen.generate_motherboard(level + 2, "", 5)
	contraband.level = clampi(level + 2, 1, Motherboard.MAX_LEVEL)
	contraband.set_meta("shop_tag", TAG_CONTRABAND)
	stock.append(contraband)
	return stock


static func shop_tag(item: Item) -> String:
	return String(item.get_meta("shop_tag", "")) if item else ""


## Precio en la tienda: el normal, rebajado si es la oferta y por las nubes si es contrabando.
static func shop_price(item: Item) -> int:
	match shop_tag(item):
		TAG_DEAL:
			return maxi(1, int(price(item) * DEAL_DISCOUNT))
		TAG_CONTRABAND:
			return int(price(item) * CONTRABAND_MARKUP)
	return price(item)


## Quitar un nodo del árbol pasivo en partida (T83): cuesta tokens según el nivel
## (los asignados desde que se abrió el árbol se quitan gratis, como deshacer).
static func passive_refund_cost(level: int) -> int:
	return 5 + level * 2


## Renovar la mercancía: sube con cada renovación (se reinicia al cambiar de zona).
static func refresh_cost(level: int, refreshes_done: int) -> int:
	return int((10 + level * 2) * (1.0 + 0.5 * refreshes_done))


## Lo que vale vender de golpe los objetos de equipo de la bolsa hasta `max_rarity`
## (normal o mágico): [índices de la bolsa, tokens].
static func bulk_sell(inv: Inventory, max_rarity: int) -> Array:
	var idx: Array[int] = []
	var total := 0
	for i in inv.bag.size():
		var it: Item = inv.bag[i]
		if it and not it.locked and it.is_equipment() and not (it is Motherboard or it is RamModule or it is KeyItem) and it.rarity <= max_rarity:
			idx.append(i)
			total += sell_price(it)
	return [idx, total]


## Lo marcado como basura en la bolsa (T79), de cualquier tipo salvo objetos clave:
## [índices de la bolsa, tokens]. Lo bloqueado nunca se vende.
static func junk_sell(inv: Inventory) -> Array:
	var idx: Array[int] = []
	var total := 0
	for i in inv.bag.size():
		var it: Item = inv.bag[i]
		if it and it.junk and not it.locked and not it is KeyItem:
			idx.append(i)
			total += sell_price(it)
	return [idx, total]
