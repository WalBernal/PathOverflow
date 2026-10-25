class_name ShopPanel
extends PanelContainer
## Tienda del comerciante (Nacho): placas base de los tres atributos, módulos RAM,
## pociones, la oferta del día y el contrabando (Economy.generate_stock), a cambio
## de tokens. Click en un artículo: comprarlo (va a la bolsa). Filtros por tipo y
## por atributo. Arrastrar un objeto de la bolsa a "Vender" lo vende; los botones
## de lote venden de golpe el equipo normal o mágico; lo último vendido se puede
## recomprar por lo mismo que pagó Nacho. Se abre junto al inventario.

signal message(text: String)
signal close_requested
signal refresh_requested

const CELL := 54.0
const COLUMNS := 6
const BUYBACK_SIZE := 5
## Filtros: id -> [texto, función(item) -> bool].
const FILTERS := ["todo", "str", "dex", "int", "ram", "flask"]
const FILTER_NAMES := {"todo": "Todo", "str": "Placas FUE", "dex": "Placas DES", "int": "Placas INT", "ram": "RAM", "flask": "Pociones"}

var character: CharacterData
var stock: Array[Item] = []
## Renovaciones hechas desde que entraste a la zona (las pone World: suben el precio).
var refreshes := 0
var filter := "todo"
## Lo último vendido, para recomprarlo: [{item, price}] (lo más reciente primero).
var buyback: Array[Dictionary] = []
var _tooltip: ItemTooltip
var _grid: GridContainer
var _special: HBoxContainer
var _buyback_row: HBoxContainer
var _filter_row: HBoxContainer
var _tokens_label: Label
var _hint: Label
var _sell_cell: ItemCell
var _refresh_button: Button
var _bulk_normal: Button
var _bulk_magic: Button
var _scroll: ScrollContainer


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.tokens_changed.connect(func(_t: int) -> void: _refresh_header())
	character.inventory.changed.connect(_refresh_header)


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	visible = false
	var outer := VBoxContainer.new()
	add_child(outer)
	outer.add_child(UiStyle.window_header("Nacho · Hardware de segunda mano", "Todo del nivel de tu personaje  ·  Esc para cerrar",
		func() -> void: close_requested.emit()))
	# El resto, en un desplazamiento que cabe en la pantalla (interfaz al 160 %).
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_scroll.add_child(box)
	_tokens_label = UiStyle.label("", 18, Economy.COLOR)
	box.add_child(_tokens_label)
	_filter_row = HBoxContainer.new()
	_filter_row.add_theme_constant_override("separation", 4)
	box.add_child(_filter_row)
	for f in FILTERS:
		var b := UiStyle.button(FILTER_NAMES[f], _set_filter.bind(f), 0)
		b.toggle_mode = true
		_filter_row.add_child(b)
	box.add_child(UiStyle.section_header("A la venta"))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 2)
	box.add_child(_grid)
	box.add_child(UiStyle.section_header("Bajo el mostrador"))
	_special = HBoxContainer.new()
	_special.add_theme_constant_override("separation", 14)
	box.add_child(_special)

	box.add_child(UiStyle.section_header("Vender"))
	var sell_row := HBoxContainer.new()
	sell_row.add_theme_constant_override("separation", 8)
	box.add_child(sell_row)
	_sell_cell = ItemCell.new()
	_sell_cell.location = {"kind": "sell"}
	_sell_cell.placeholder = "Vender"
	_sell_cell.custom_minimum_size = Vector2(CELL, CELL)
	_sell_cell.dropped.connect(_on_sell_dropped)
	sell_row.add_child(_sell_cell)
	var bulk := VBoxContainer.new()
	sell_row.add_child(bulk)
	_bulk_normal = UiStyle.button("", sell_bulk.bind(Rarity.Item.NORMAL), 240)
	_bulk_magic = UiStyle.button("", sell_bulk.bind(Rarity.Item.MAGIC), 240)
	bulk.add_child(_bulk_normal)
	bulk.add_child(_bulk_magic)
	box.add_child(UiStyle.label("Arrastra aquí un objeto de la bolsa. Nacho paga el %d%% de lo que lo vendería." % int(Economy.SELL_FRACTION * 100), 12, UiStyle.MUTED))
	box.add_child(UiStyle.section_header("Recomprar"))
	_buyback_row = HBoxContainer.new()
	_buyback_row.add_theme_constant_override("separation", 6)
	box.add_child(_buyback_row)

	_refresh_button = UiStyle.button("", func() -> void: refresh_requested.emit(), 300)
	_refresh_button.tooltip_text = "Nacho saca otra caja de la bodega. Cada caja cuesta más (hasta que cambies de zona).\nLa mercancía también cambia al subir de nivel."
	box.add_child(_refresh_button)
	_hint = UiStyle.label("Click en un artículo para comprarlo.", 12, UiStyle.MUTED)
	box.add_child(_hint)


static func refresh_cost(level: int, refreshes_done := 0) -> int:
	return Economy.refresh_cost(level, refreshes_done)


func open(p_stock: Array[Item]) -> void:
	stock = p_stock
	visible = true
	_rebuild()


## ¿El artículo pasa el filtro activo?
static func passes_filter(item: Item, f: String) -> bool:
	if item == null:
		return f == "todo"
	match f:
		"str", "dex", "int":
			return item is Motherboard and String((item as Motherboard).skill_def.get("attribute", "")) == f
		"ram":
			return item is RamModule
		"flask":
			return item is Flask
	return true


func _set_filter(f: String) -> void:
	filter = f
	_rebuild()


func _rebuild() -> void:
	for row in [_grid, _special, _buyback_row]:
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
	for k in _filter_row.get_child_count():
		(_filter_row.get_child(k) as Button).button_pressed = FILTERS[k] == filter
	for i in stock.size():
		var tag := Economy.shop_tag(stock[i])
		if tag != "":
			_special.add_child(_stock_cell(i, "Oferta del día" if tag == Economy.TAG_DEAL else "Contrabando",
				Color("6fd36b") if tag == Economy.TAG_DEAL else Color("e06c6c")))
		elif passes_filter(stock[i], filter) and stock[i] != null:
			_grid.add_child(_stock_cell(i))
	for k in buyback.size():
		var cell := ItemCell.new()
		cell.location = {"kind": "buyback", "index": k}
		cell.custom_minimum_size = Vector2(CELL, CELL)
		cell.show_skill_icon = true
		cell.set_item(buyback[k]["item"])
		cell.clicked.connect(_on_buyback_clicked)
		cell.hovered.connect(_on_item_hovered)
		_buyback_row.add_child(cell)
	if buyback.is_empty():
		_buyback_row.add_child(UiStyle.label("Nada todavía.", 12, UiStyle.MUTED))
	_refresh_header()
	_fit_height.call_deferred()


## Alto del desplazamiento: todo el contenido si cabe; si no, lo que quepa en pantalla.
func _fit_height() -> void:
	if _scroll == null or not is_inside_tree():
		return
	var content := (_scroll.get_child(0) as Control).get_combined_minimum_size()
	var scale_y := get_global_transform().get_scale().y
	var room := get_viewport_rect().size.y / maxf(0.1, scale_y) - position.y - 120.0   # cabecera y márgenes
	_scroll.custom_minimum_size = Vector2(content.x + 12.0, clampf(content.y, 160.0, maxf(160.0, room)))


func _stock_cell(i: int, caption := "", caption_color := UiStyle.MUTED) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	if caption != "":
		col.add_child(UiStyle.label(caption, 11, caption_color))
	var cell := ItemCell.new()
	cell.location = {"kind": "shop", "index": i}
	cell.custom_minimum_size = Vector2(CELL, CELL)
	cell.show_skill_icon = true
	cell.set_item(stock[i])
	cell.clicked.connect(_on_item_clicked)
	cell.hovered.connect(_on_item_hovered)
	col.add_child(cell)
	var price := UiStyle.label("—" if stock[i] == null else "%d" % Economy.shop_price(stock[i]), 12, Economy.COLOR)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(price)
	return col


func _refresh_header() -> void:
	if character == null or _tokens_label == null:
		return
	_tokens_label.text = "%s: %d" % [Economy.CURRENCY, character.tokens]
	_refresh_button.text = "Renovar mercancía (%d %s)" % [refresh_cost(character.level, refreshes), Economy.CURRENCY.to_lower()]
	var normal := Economy.bulk_sell(character.inventory, Rarity.Item.NORMAL)
	var magic := Economy.bulk_sell(character.inventory, Rarity.Item.MAGIC)
	_bulk_normal.text = "Vender el equipo normal (%d · %d)" % [normal[0].size(), normal[1]]
	_bulk_magic.text = "Vender normal y mágico (%d · %d)" % [magic[0].size(), magic[1]]
	_bulk_normal.disabled = normal[0].is_empty()
	_bulk_magic.disabled = magic[0].is_empty()


func _on_item_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	var i: int = cell.location["index"]
	var item := stock[i]
	var price := Economy.shop_price(item)
	if character.inventory.free_bag_index() == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	if not character.spend_tokens(price):
		message.emit("Te faltan %d tokens. Nacho no fía (lo dice un cartel)." % (price - character.tokens))
		return
	item.remove_meta("shop_tag")
	character.inventory.add_item(item)
	stock[i] = null
	Sfx.play("pickup")
	message.emit("Compraste %s por %d tokens." % [item.display_name(), price])
	_tooltip.hide()
	_rebuild()


func _on_buyback_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	var k: int = cell.location["index"]
	var entry: Dictionary = buyback[k]
	if character.inventory.free_bag_index() == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	if not character.spend_tokens(int(entry["price"])):
		message.emit("Para recomprarlo te faltan %d tokens." % (int(entry["price"]) - character.tokens))
		return
	character.inventory.add_item(entry["item"])
	buyback.remove_at(k)
	Sfx.play("pickup")
	message.emit("Recompraste %s. Nacho finge que no se acuerda de ti." % (entry["item"] as Item).display_name())
	_tooltip.hide()
	_rebuild()


func _on_item_hovered(cell: ItemCell, inside: bool) -> void:
	if not inside or cell.item == null:
		_tooltip.hide()
		_hint.text = "Click en un artículo para comprarlo."
		return
	_tooltip.show_item(cell.item, character, cell.item.is_equipment())
	var price := Economy.shop_price(cell.item) if cell.location.get("kind", "") == "shop" else int(buyback[int(cell.location["index"])]["price"])
	var owned := owned_board_level(character, cell.item)
	_hint.text = "Click: comprar por %d tokens%s%s" % [price, "" if price <= character.tokens else "  (no te alcanza)",
		"  ·  ya la tienes (placa nv %d)" % owned if owned > 0 else ""]


## Si ya tienes una placa de la misma habilidad (equipada o en la bolsa), su nivel más alto; 0 si no.
static func owned_board_level(ch: CharacterData, item: Item) -> int:
	var board := item as Motherboard
	if board == null or ch == null:
		return 0
	var best := 0
	for group in [ch.inventory.boards, ch.inventory.bag]:
		for it in group:
			var b := it as Motherboard
			if b and String(b.skill_def.get("id", "")) == String(board.skill_def.get("id", "")):
				best = maxi(best, b.level)
	return best


func _on_sell_dropped(_target: ItemCell, payload: Dictionary) -> void:
	var from: Dictionary = payload.get("from", {})
	if from.get("kind", "") != "bag":
		message.emit("Solo se vende desde la bolsa. Quítatelo primero.")
		return
	var item := ItemTransfer.get_at(character.inventory, from)
	if item == null:
		return
	if item is KeyItem:
		message.emit("Eso no se vende: lo vas a necesitar.")
		return
	var value := Economy.sell_price(item)
	ItemTransfer.take(character, from)
	character.add_tokens(value)
	_remember_sold(item, value)
	Sfx.play("coin")
	message.emit("Vendiste %s por %d tokens." % [item.display_name(), value])
	_tooltip.hide()
	_rebuild()


## Vende de golpe el equipo de la bolsa hasta `max_rarity` (normal o mágico).
func sell_bulk(max_rarity: int) -> int:
	var plan := Economy.bulk_sell(character.inventory, max_rarity)
	var indices: Array = plan[0]
	if indices.is_empty():
		return 0
	indices.sort()
	indices.reverse()   # de atrás adelante: los índices de la bolsa no se mueven
	for i in indices:
		var item: Item = character.inventory.bag[i]
		ItemTransfer.take(character, {"kind": "bag", "index": i})
		_remember_sold(item, Economy.sell_price(item))
	character.add_tokens(int(plan[1]))
	Sfx.play("coin")
	message.emit("Vendiste %d objetos por %d tokens. «Te los compro por kilo», dice Nacho." % [indices.size(), int(plan[1])])
	_rebuild()
	return int(plan[1])


func _remember_sold(item: Item, value: int) -> void:
	buyback.push_front({"item": item, "price": value})
	if buyback.size() > BUYBACK_SIZE:
		buyback.resize(BUYBACK_SIZE)
