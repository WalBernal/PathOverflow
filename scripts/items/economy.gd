class_name Economy
## Tokens: la moneda del juego (los sueltan los enemigos, se gastan con el
## comerciante). Aquí están las cuentas: cuánto sueltan, cuánto cuesta cada
## cosa y qué tiene a la venta la tienda.

const CURRENCY := "Tokens"
const COLOR := Color("f2c14e")
## Probabilidad de soltar tokens según la rareza del enemigo (normal ≈ 2 de cada 5).
const DROP_CHANCE := {Rarity.Enemy.NORMAL: 0.4, Rarity.Enemy.SPECIAL: 0.7, Rarity.Enemy.ELITE: 1.0, Rarity.Enemy.UNIQUE: 1.0}
const DROP_MULT := {Rarity.Enemy.NORMAL: 1.0, Rarity.Enemy.SPECIAL: 2.0, Rarity.Enemy.ELITE: 4.0, Rarity.Enemy.UNIQUE: 15.0}
const STOCK_BOARDS := 4
const STOCK_RAMS := 6
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


## Mercancía del comerciante para un nivel: placas base (habilidades al azar
## que no sean exclusivas) y módulos RAM, todo del nivel del jugador.
static func generate_stock(gen: ItemGenerator, level: int) -> Array[Item]:
	var stock: Array[Item] = []
	for k in STOCK_BOARDS:
		var board := gen.generate_motherboard(level, "", 0)
		# Algo mejor que las que caen (nivel - 3): para eso se pagan.
		board.level = clampi(level - 1, 1, Motherboard.MAX_LEVEL)
		stock.append(board)
	for k in STOCK_RAMS:
		stock.append(gen.generate_ram(level, ""))
	return stock
