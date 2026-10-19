class_name ShopPanel
extends PanelContainer
## Tienda del comerciante (Nacho): placas base y módulos RAM del nivel del
## jugador, a cambio de tokens. Click en un artículo: comprarlo (va a la bolsa).
## Arrastrar un objeto de la bolsa a la casilla "Vender": te lo paga.
## Se abre junto al inventario.

signal message(text: String)
signal close_requested
signal refresh_requested

const CELL := 58.0
const COLUMNS := 5

var character: CharacterData
var stock: Array[Item] = []
var _tooltip: ItemTooltip
var _grid: GridContainer
var _tokens_label: Label
var _hint: Label
var _sell_cell: ItemCell
var _refresh_button: Button


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.tokens_changed.connect(func(_t: int) -> void: _refresh_header())


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.window_header("Nacho · Hardware de segunda mano", "Todo del nivel de tu personaje  ·  Esc para cerrar",
		func() -> void: close_requested.emit()))
	_tokens_label = UiStyle.label("", 18, Economy.COLOR)
	box.add_child(_tokens_label)
	box.add_child(UiStyle.section_header("A la venta"))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(_grid)

	box.add_child(UiStyle.section_header("Vender"))
	var sell_row := HBoxContainer.new()
	sell_row.add_theme_constant_override("separation", 10)
	box.add_child(sell_row)
	_sell_cell = ItemCell.new()
	_sell_cell.location = {"kind": "sell"}
	_sell_cell.placeholder = "Vender"
	_sell_cell.custom_minimum_size = Vector2(CELL, CELL)
	_sell_cell.dropped.connect(_on_sell_dropped)
	sell_row.add_child(_sell_cell)
	var sell_text := UiStyle.label("Arrastra aquí un objeto de la bolsa.\nNacho paga el %d%% de lo que lo vendería." % int(Economy.SELL_FRACTION * 100), 13, UiStyle.MUTED)
	sell_row.add_child(sell_text)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	box.add_child(bottom)
	_refresh_button = UiStyle.button("", func() -> void: refresh_requested.emit(), 260)
	_refresh_button.tooltip_text = "Nacho saca otra caja de la bodega. La mercancía también cambia al subir de nivel."
	bottom.add_child(_refresh_button)
	_hint = UiStyle.label("Click en un artículo para comprarlo.", 12, UiStyle.MUTED)
	box.add_child(_hint)


static func refresh_cost(level: int) -> int:
	return 10 + level * 2


func open(p_stock: Array[Item]) -> void:
	stock = p_stock
	visible = true
	_rebuild()


func _rebuild() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for i in stock.size():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var cell := ItemCell.new()
		cell.location = {"kind": "shop", "index": i}
		cell.custom_minimum_size = Vector2(CELL, CELL)
		cell.show_skill_icon = true
		cell.set_item(stock[i])
		cell.clicked.connect(_on_item_clicked)
		cell.hovered.connect(_on_item_hovered)
		col.add_child(cell)
		var price := UiStyle.label("", 12, Economy.COLOR)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.text = "—" if stock[i] == null else "%d" % Economy.price(stock[i])
		col.add_child(price)
		_grid.add_child(col)
	_refresh_header()


func _refresh_header() -> void:
	if character == null or _tokens_label == null:
		return
	_tokens_label.text = "%s: %d" % [Economy.CURRENCY, character.tokens]
	_refresh_button.text = "Renovar mercancía (%d %s)" % [refresh_cost(character.level), Economy.CURRENCY.to_lower()]


func _on_item_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	var i: int = cell.location["index"]
	var item := stock[i]
	var price := Economy.price(item)
	if character.inventory.free_bag_index() == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	if not character.spend_tokens(price):
		message.emit("Te faltan %d tokens. Nacho no fía (lo dice un cartel)." % (price - character.tokens))
		return
	character.inventory.add_item(item)
	stock[i] = null
	Sfx.play("pickup")
	message.emit("Compraste %s por %d tokens." % [item.display_name(), price])
	_tooltip.hide()
	_rebuild()


func _on_item_hovered(cell: ItemCell, inside: bool) -> void:
	if not inside or cell.item == null:
		_tooltip.hide()
		_hint.text = "Click en un artículo para comprarlo."
		return
	_tooltip.show_item(cell.item, character, cell.item.is_equipment())
	var price := Economy.price(cell.item)
	_hint.text = "Click: comprar por %d tokens%s" % [price, "" if price <= character.tokens else "  (no te alcanza)"]


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
	Sfx.play("coin")
	message.emit("Vendiste %s por %d tokens." % [item.display_name(), value])
	_tooltip.hide()
