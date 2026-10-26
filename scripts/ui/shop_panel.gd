class_name ShopPanel
extends PanelContainer
## Tienda de un comerciante, como escena (T71). Nacho abre la gabardina: las placas,
## la RAM y las pociones cuelgan de ganchos en el forro, la oferta del día va en el
## bolsillo de dentro y el contrabando en un bolsillo secreto que se abre aparte;
## suelta frases sarcásticas al entrar, al mirar, al comprar o vender. Aida
## (vendor "aida") usa el mismo marco con su puesto ordenado, sin gabardina.
## Click en un artículo: comprarlo (va a la bolsa). Filtros por tipo y por
## atributo. Arrastrar un objeto de la bolsa a "Vender" lo vende; los botones de
## lote venden de golpe el equipo normal o mágico; lo último vendido se puede
## recomprar por lo mismo que pagó el comerciante. Se abre junto al inventario.

signal message(text: String)
signal close_requested
signal refresh_requested

const CELL := 54.0
const COLUMNS := 6
const BUYBACK_SIZE := 5
const FILTERS := ["todo", "str", "dex", "int", "ram", "flask"]
const FILTER_NAMES := {"todo": "Todo", "str": "Placas FUE", "dex": "Placas DES", "int": "Placas INT", "ram": "RAM", "flask": "Pociones"}
## Tono de la voz de cada comerciante (el de npcs.json).
const VOICE_PITCH := {"nacho": 0.95, "aida": 0.9}
const VENDOR_TITLES := {
	"nacho": ["Nacho · La gabardina", "Hardware «original» del nivel de tu personaje  ·  I o Esc para cerrar"],
	"aida": ["Aida · Puesto de equipo", "Equipo revisado del nivel de tu personaje  ·  I o Esc para cerrar"],
}
## Entre dos frases al pasar el ratón, al menos esto (ms): que no hable sin parar.
const HOVER_LINE_GAP_MS := 4000

var character: CharacterData
var stock: Array[Item] = []
## "nacho" (gabardina) o "aida" (puesto de equipo).
var vendor := "nacho"
## Renovaciones hechas desde que entraste a la zona (las pone World: suben el precio).
var refreshes := 0
var filter := "todo"
## El bolsillo del contrabando: cerrado hasta que lo abres (se cierra al volver).
var contraband_open := false
## Lo último vendido, para recomprarlo: [{item, price}] (lo más reciente primero).
var buyback: Array[Dictionary] = []
## Lo último que dijo el comerciante.
var last_line := ""
var _tooltip: ItemTooltip
var _header_holder: VBoxContainer
var _art: ShopVendorArt
var _speech: Label
var _lining: PanelContainer
var _lining_caption: Label
var _grid: GridContainer
var _pockets_box: VBoxContainer
var _special: HBoxContainer
var _buyback_row: HBoxContainer
var _filter_row: HBoxContainer
var _tokens_label: Label
var _hint: Label
var _sell_cell: ItemCell
var _refresh_button: Button
var _bulk_normal: Button
var _bulk_magic: Button
var _bulk_junk: Button
var _scroll: ScrollContainer
var _seen_refreshes := 0
var _shown := false
var _last_hover_ms := -100000


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.tokens_changed.connect(func(_t: int) -> void: _refresh_header())
	character.inventory.changed.connect(_refresh_header)


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	visible = false
	var last: String = String(UiStyle.remembered("shop_filter", "todo"))
	filter = last if last in FILTERS else "todo"   # el último filtro (T82)
	visibility_changed.connect(func() -> void:
		if not visible:
			_check_closed.call_deferred())
	var outer := VBoxContainer.new()
	add_child(outer)
	_header_holder = VBoxContainer.new()
	outer.add_child(_header_holder)
	# El resto, en un desplazamiento que cabe en la pantalla (interfaz al 160 %).
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_scroll.add_child(box)

	# Arriba: el comerciante con su bocadillo a la izquierda, la mercancía a la derecha.
	var scene := HBoxContainer.new()
	scene.add_theme_constant_override("separation", 10)
	box.add_child(scene)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	scene.add_child(left)
	_art = ShopVendorArt.new()
	left.add_child(_art)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _bubble_style())
	left.add_child(bubble)
	_speech = UiStyle.label("", 12, Color("2a2420"))
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.custom_minimum_size = Vector2(ShopVendorArt.GRID.x * ShopVendorArt.PX - 16.0, 0)
	bubble.add_child(_speech)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	scene.add_child(right)
	_tokens_label = UiStyle.label("", 18, Economy.COLOR)
	right.add_child(_tokens_label)
	_filter_row = HBoxContainer.new()
	_filter_row.add_theme_constant_override("separation", 4)
	right.add_child(_filter_row)
	for f in FILTERS:
		var b := UiStyle.button(FILTER_NAMES[f], _set_filter.bind(f), 0)
		b.toggle_mode = true
		_filter_row.add_child(b)
	_lining = PanelContainer.new()
	right.add_child(_lining)
	var lining_box := VBoxContainer.new()
	lining_box.add_theme_constant_override("separation", 4)
	_lining.add_child(lining_box)
	_lining_caption = UiStyle.label("", 12, UiStyle.MUTED)
	lining_box.add_child(_lining_caption)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 2)
	lining_box.add_child(_grid)
	_pockets_box = VBoxContainer.new()
	lining_box.add_child(_pockets_box)
	_special = HBoxContainer.new()
	_special.add_theme_constant_override("separation", 14)
	_pockets_box.add_child(_special)

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
	_bulk_junk = UiStyle.button("", sell_junk, 240)
	_bulk_junk.tooltip_text = "Click derecho en la bolsa: basura → bloqueado → sin marca.\nLo bloqueado no se vende ni se tira."
	bulk.add_child(_bulk_normal)
	bulk.add_child(_bulk_magic)
	bulk.add_child(_bulk_junk)
	box.add_child(UiStyle.label("Arrastra aquí un objeto de la bolsa. Se paga el %d%% de lo que vale a la venta." % int(Economy.SELL_FRACTION * 100), 12, UiStyle.MUTED))
	box.add_child(UiStyle.section_header("Recomprar"))
	_buyback_row = HBoxContainer.new()
	_buyback_row.add_theme_constant_override("separation", 6)
	box.add_child(_buyback_row)

	_refresh_button = UiStyle.button("", func() -> void: refresh_requested.emit(), 300)
	_refresh_button.tooltip_text = "Nacho saca otra caja de la bodega. Cada caja cuesta más (hasta que cambies de zona).\nLa mercancía también cambia al subir de nivel."
	box.add_child(_refresh_button)
	_hint = UiStyle.label("Click en un artículo para comprarlo.", 12, UiStyle.MUTED)
	box.add_child(_hint)
	_apply_vendor()


static func refresh_cost(level: int, refreshes_done := 0) -> int:
	return Economy.refresh_cost(level, refreshes_done)


## Abre la tienda de `p_vendor`. Si es la misma de Nacho con una renovación más,
## no vuelve a saludar: comenta la caja nueva.
func open(p_stock: Array[Item], p_vendor := "nacho") -> void:
	var refreshed := p_vendor == vendor and refreshes > _seen_refreshes
	_seen_refreshes = refreshes
	stock = p_stock
	if p_vendor != vendor:
		vendor = p_vendor
		_apply_vendor()
	contraband_open = false
	visible = true
	_shown = true
	_rebuild()
	_art.play_open()
	say("refresh" if refreshed else "enter")


## El comerciante dice una frase del momento `event` (ShopLines): bocadillo, boca y voz.
func say(event: String) -> String:
	var text := ShopLines.pick(vendor, event)
	if text == "":
		return ""
	last_line = text
	if _speech:
		_speech.text = "«%s»" % text
	if _art:
		_art.talk(clampf(text.length() * 0.035, 0.5, 1.6))
	Barks.play(Barks.kind_for(text, event == "enter"), float(VOICE_PITCH.get(vendor, 1.0)))
	return text


## Título, colores del forro (o de la mesa) y lo que solo tiene Nacho.
func _apply_vendor() -> void:
	if _header_holder == null:
		return
	for c in _header_holder.get_children():
		_header_holder.remove_child(c)
		c.queue_free()
	var titles: Array = VENDOR_TITLES.get(vendor, VENDOR_TITLES["nacho"])
	_header_holder.add_child(UiStyle.window_header(titles[0], titles[1], func() -> void: close_requested.emit()))
	var nacho := vendor == "nacho"
	_art.vendor = vendor
	_art.queue_redraw()
	_filter_row.visible = nacho
	_pockets_box.visible = nacho
	_refresh_button.visible = nacho
	_lining.add_theme_stylebox_override("panel", lining_style(vendor))
	_lining_caption.text = "El forro: todo cuelga de un gancho" if nacho else "Sobre la mesa, por orden"
	_lining_caption.add_theme_color_override("font_color", Color("c9a7d0") if nacho else Color("a8c9a0"))


## Forro de la gabardina (morado con el borde del abrigo) o tapete del puesto de Aida.
static func lining_style(p_vendor: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var nacho := p_vendor != "aida"
	sb.bg_color = ShopVendorArt.LINING if nacho else ShopVendorArt.FELT
	sb.border_color = ShopVendorArt.COAT if nacho else ShopVendorArt.WOOD
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(8 if nacho else 2)
	sb.set_content_margin_all(10)
	return sb


static func _pocket_style(open_pocket: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ShopVendorArt.LINING_DARK
	sb.border_color = ShopVendorArt.COAT_LIGHT if open_pocket else ShopVendorArt.COAT_DARK
	sb.set_border_width_all(2)
	sb.border_width_top = 4   # el dobladillo del bolsillo
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.set_content_margin_all(6)
	return sb


static func _bubble_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe6d2")
	sb.border_color = Color("2a2420")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	return sb


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
	UiStyle.remember("shop_filter", f)   # se abre con el último filtro (T82)
	_rebuild()


## Abre el bolsillo secreto del contrabando.
func open_contraband() -> void:
	if contraband_open:
		return
	contraband_open = true
	ShopVendorArt.play_cloth(true)
	say("pocket")
	_rebuild()


func _rebuild() -> void:
	for row in [_grid, _special, _buyback_row]:
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
	var f := filter if vendor == "nacho" else "todo"
	for k in _filter_row.get_child_count():
		(_filter_row.get_child(k) as Button).button_pressed = FILTERS[k] == f
	for i in stock.size():
		var tag := Economy.shop_tag(stock[i])
		if tag == Economy.TAG_DEAL:
			_special.add_child(_pocket(_stock_cell(i, "Oferta del día", Color("6fd36b")), "Bolsillo de dentro", true))
		elif tag == Economy.TAG_CONTRABAND:
			if contraband_open:
				_special.add_child(_pocket(_stock_cell(i, "Contrabando", Color("e06c6c")), "Bolsillo secreto", true))
			else:
				var b := UiStyle.button("Abrir el bolsillo secreto", open_contraband, 0)
				b.tooltip_text = "Nacho mira a los lados antes de enseñarlo."
				_special.add_child(_pocket(b, "Bolsillo secreto (cerrado)", false))
		elif passes_filter(stock[i], f) and stock[i] != null:
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


func _pocket(content: Control, caption: String, open_pocket: bool) -> Control:
	var pocket := PanelContainer.new()
	pocket.add_theme_stylebox_override("panel", _pocket_style(open_pocket))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	pocket.add_child(col)
	col.add_child(UiStyle.label(caption, 11, Color("c9a7d0")))
	col.add_child(content)
	return pocket


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
	elif vendor == "nacho":
		col.add_child(_hook())
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


## Un gancho de metal del forro, encima de cada artículo.
static func _hook() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(CELL, 10)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		var x := CELL * 0.5
		c.draw_line(Vector2(x, 0), Vector2(x, 5), Color("9a9aa8"), 2.0)
		c.draw_arc(Vector2(x - 3, 5), 3.0, 0.0, PI, 6, Color("9a9aa8"), 2.0))
	return c


func _refresh_header() -> void:
	if character == null or _tokens_label == null:
		return
	_tokens_label.text = "%s: %d" % [Economy.CURRENCY, character.tokens]
	_refresh_button.text = "Otra caja de la bodega (%d %s)" % [refresh_cost(character.level, refreshes), Economy.CURRENCY.to_lower()]
	var normal := Economy.bulk_sell(character.inventory, Rarity.Item.NORMAL)
	var magic := Economy.bulk_sell(character.inventory, Rarity.Item.MAGIC)
	_bulk_normal.text = "Vender el equipo normal (%d · %d)" % [normal[0].size(), normal[1]]
	_bulk_magic.text = "Vender normal y mágico (%d · %d)" % [magic[0].size(), magic[1]]
	_bulk_normal.disabled = normal[0].is_empty()
	_bulk_magic.disabled = magic[0].is_empty()
	var junk := Economy.junk_sell(character.inventory)
	_bulk_junk.text = "Vender lo marcado como basura (%d · %d)" % [junk[0].size(), junk[1]]
	_bulk_junk.disabled = junk[0].is_empty()


## Compra el artículo `i` del puesto. Devuelve si se compró.
func buy(i: int) -> bool:
	var item := stock[i]
	if item == null:
		return false
	var price := Economy.shop_price(item)
	if character.inventory.free_bag_index() == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		say("full")
		return false
	if not character.spend_tokens(price):
		message.emit("Te faltan %d tokens." % (price - character.tokens))
		say("broke")
		return false
	item.remove_meta("shop_tag")
	character.inventory.add_item(item)
	stock[i] = null
	Sfx.play("ui_buy")
	message.emit("Compraste %s por %d tokens." % [item.display_name(), price])
	say("buy")
	if _tooltip:
		_tooltip.hide()
	_rebuild()
	return true


func _on_item_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	buy(int(cell.location["index"]))


func _on_buyback_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	var k: int = cell.location["index"]
	var entry: Dictionary = buyback[k]
	if character.inventory.free_bag_index() == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		say("full")
		return
	if not character.spend_tokens(int(entry["price"])):
		message.emit("Para recomprarlo te faltan %d tokens." % (int(entry["price"]) - character.tokens))
		say("broke")
		return
	character.inventory.add_item(entry["item"])
	buyback.remove_at(k)
	Sfx.play("ui_buy")
	message.emit("Recompraste %s." % (entry["item"] as Item).display_name())
	say("buyback")
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
	var now := Time.get_ticks_msec()
	if now - _last_hover_ms >= HOVER_LINE_GAP_MS:
		_last_hover_ms = now
		match Economy.shop_tag(cell.item):
			Economy.TAG_DEAL:
				say("hover_deal")
			Economy.TAG_CONTRABAND:
				say("hover_contraband")
			_:
				if randf() < 0.5:
					say("hover")


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
	if item.locked:
		message.emit("Está bloqueado. Quítale el candado (click derecho en la bolsa) si de verdad lo quieres vender.")
		return
	var value := Economy.sell_price(item)
	ItemTransfer.take(character, from)
	character.add_tokens(value)
	_remember_sold(item, value)
	Sfx.play("coin")
	message.emit("Vendiste %s por %d tokens." % [item.display_name(), value])
	say("sell")
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
	message.emit("Vendiste %d objetos por %d tokens." % [indices.size(), int(plan[1])])
	say("bulk")
	_rebuild()
	return int(plan[1])


## Vende de golpe lo marcado como basura (T79). Devuelve los tokens.
func sell_junk() -> int:
	var plan := Economy.junk_sell(character.inventory)
	var indices: Array = plan[0]
	if indices.is_empty():
		return 0
	indices.sort()
	indices.reverse()
	for i in indices:
		var item: Item = character.inventory.bag[i]
		ItemTransfer.take(character, {"kind": "bag", "index": i})
		item.junk = false   # si lo recompras, vuelve sin la marca
		_remember_sold(item, Economy.sell_price(item))
	character.add_tokens(int(plan[1]))
	Sfx.play("coin")
	message.emit("Vendiste %d objetos marcados por %d tokens." % [indices.size(), int(plan[1])])
	say("bulk")
	_rebuild()
	return int(plan[1])


func _remember_sold(item: Item, value: int) -> void:
	buyback.push_front({"item": item, "price": value})
	if buyback.size() > BUYBACK_SIZE:
		buyback.resize(BUYBACK_SIZE)


## Al cerrar de verdad (no al pasar de una tienda a otra en el mismo cuadro), Nacho se cierra la gabardina.
func _check_closed() -> void:
	if visible or not _shown:
		return
	_shown = false
	if vendor == "nacho":
		ShopVendorArt.play_cloth(false)
