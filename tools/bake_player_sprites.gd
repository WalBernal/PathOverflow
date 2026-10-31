extends SceneTree
## Hornea las hojas del personaje por capas (T102a, ver PlayerSheet) a partir del
## dibujo de CharacterAppearance, en assets/sprites/player/:
## - body / hair / beard / accessory (máscaras): R = luz, G = capa de color, A = alfa.
## - body_fixed / accessory_fixed / weapon (fijas): el color real de lo que no se tiñe.
## Cada capa se saca comparando dos dibujos idénticos salvo por ella (con y sin pelo,
## barba, accesorio o arma). Tres pases por hoja: identificación (colores puros),
## luz (todo blanco) y color real (para los detalles fijos).
##
## Necesita dibujar: sin --headless.
## Uso:  Godot_v4.7.2-stable_win64.exe --path . -s res://tools/bake_player_sprites.gd

const CLEAR := "00000000"

var _vp: SubViewport
var _canvas: Node2D
var _rows: Array = []      # [{a: appearance, weapon}] por variante; se dibujan las 3 direcciones
var _mode := ""


func _initialize() -> void:
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(_vp)
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_sheet)
	_vp.add_child(_canvas)
	_bake.call_deferred()


func _bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PlayerSheet.DIR_PATH))
	var base := _base_look()
	# Cuerpo: una variante (el ancho se hace al dibujar), sin pelo, barba, accesorio ni arma.
	var body_rows := [{"a": base, "weapon": ""}]
	var body_id := await _render(body_rows, "id")
	var body_lum := await _render(body_rows, "lum")
	var body_real := await _render(body_rows, "real")
	_save_mask("body", body_id, body_lum, null, body_id)
	_save_fixed("body_fixed", body_id, body_real, null)
	# Pelo: una variante por peinado, comparada con el cuerpo sin pelo.
	var hair_rows := []
	for h in CharacterAppearance.HAIR_NAMES.size():
		var a := base.duplicate()
		a["hair"] = h
		a.erase("hair_clear")
		hair_rows.append({"a": a, "weapon": ""})
	var ref_hair := _repeat(body_rows, hair_rows.size())
	_save_mask("hair", await _render(hair_rows, "id"), await _render(hair_rows, "lum"), await _render(ref_hair, "id"), null)
	# Barba (sin la variante 0) y accesorio (sin la 0): con el pelo invisible, como la referencia.
	for layer in ["beard", "accessory"]:
		var count := CharacterAppearance.BEARD_NAMES.size() if layer == "beard" else CharacterAppearance.ACCESSORY_NAMES.size()
		var rows := []
		for v in range(1, count):
			var a := base.duplicate()
			a[layer] = v
			rows.append({"a": a, "weapon": ""})
		var ref := _repeat(body_rows, rows.size())
		var ids := await _render(rows, "id")
		var ref_ids := await _render(ref, "id")
		_save_mask(layer, ids, await _render(rows, "lum"), ref_ids, null)
		if layer == "accessory":
			_save_fixed("accessory_fixed", ids, await _render(rows, "real"), ref_ids)
	# Armas: lo que añade cada una (en la mano, en reposo y al atacar).
	var weapon_rows := []
	for w in PlayerSheet.WEAPONS:
		weapon_rows.append({"a": base, "weapon": w})
	var ref_w := _repeat(body_rows, weapon_rows.size())
	var w_ids := await _render(weapon_rows, "id")
	_save_fixed("weapon", w_ids, await _render(weapon_rows, "real"), await _render(ref_w, "id"))
	print("hojas del personaje horneadas en %s (%d columnas, celdas de %dx%d)" % [PlayerSheet.DIR_PATH, PlayerSheet.columns(), PlayerSheet.CW, PlayerSheet.CH])
	quit()


## La apariencia base: pelo invisible, sin barba ni accesorio, cuerpo medio, estatura 1.
func _base_look() -> Dictionary:
	var a := CharacterAppearance.default()
	a["hair_clear"] = true
	a["beard"] = 0
	a["accessory"] = 0
	a["body"] = 1
	a["height"] = 1.0
	return a


func _repeat(rows: Array, n: int) -> Array:
	var out := []
	for k in n:
		out.append(rows[0])
	return out


## Apariencia para un pase: colores puros (id), todo blanco (lum) o los de siempre (real).
func _look_for(a: Dictionary, mode: String) -> Dictionary:
	var look := a.duplicate()
	match mode:
		"id":
			for key in PlayerSheet.ID_COLORS:
				look[key] = PlayerSheet.ID_COLORS[key]
		"lum":   # gris y no blanco: así los brillos (colores aclarados) se notan (T160)
			for key in PlayerSheet.ID_COLORS:
				look[key] = Color(PlayerSheet.LUM_GRAY, PlayerSheet.LUM_GRAY, PlayerSheet.LUM_GRAY).to_html(false)
	if look.get("hair_clear", false):
		look["beard_color"] = look["hair_color"]   # la barba se ve aunque el pelo no
		look["hair_color"] = CLEAR
	look.erase("hair_clear")
	look["shirt_color"] = look["accent_color"]
	return look


## Dibuja todas las filas (×3 direcciones) en el viewport y devuelve la imagen.
func _render(rows: Array, mode: String) -> Image:
	_rows = rows
	_mode = mode
	_vp.size = Vector2i(PlayerSheet.CW * PlayerSheet.columns(), PlayerSheet.CH * rows.size() * PlayerSheet.DIRS)
	_canvas.queue_redraw()
	await process_frame
	await process_frame
	await process_frame
	return _vp.get_texture().get_image()


func _draw_sheet() -> void:
	for v in _rows.size():
		var look := _look_for(_rows[v]["a"], _mode)
		var weapon: String = _rows[v]["weapon"]
		for dir in PlayerSheet.DIRS:
			for col in PlayerSheet.columns():
				var pose := PlayerSheet.pose_for(col)
				var draw_pose := {"state": pose["state"], "t": pose["t"], "time": pose["time"], "weapon": weapon}
				var feet := Vector2(col * PlayerSheet.CW, (v * PlayerSheet.DIRS + dir) * PlayerSheet.CH) + PlayerSheet.FEET
				var group := PlayerSheet.STATES[_group_index(col)][0] as String
				# El gesto del brazo lo marca la columna (tajo o estocada), lleve el arma que lleve.
				if group == "attack_swing":
					draw_pose["weapon_class"] = "swing"
				elif group == "attack_thrust":
					draw_pose["weapon_class"] = "thrust"
				CharacterAppearance.draw(_canvas, feet, PlayerSheet.BAKE_SCALE, look, PlayerSheet.facing_of(dir), Color(0, 0, 0, 0),
					float(pose["walk_phase"]), draw_pose)


func _group_index(col: int) -> int:
	var c := 0
	for k in PlayerSheet.STATES.size():
		c += int(PlayerSheet.STATES[k][1])
		if col < c:
			return k
	return 0


## Máscara: luz en R, capa en G (solo los píxeles que no están en la referencia, si la hay).
func _save_mask(name: String, ids: Image, lum: Image, ref: Image, _unused: Image) -> void:
	var out := Image.create_empty(ids.get_width(), ids.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in ids.get_height():
		for x in ids.get_width():
			var c := ids.get_pixel(x, y)
			if c.a < 0.05 or (ref != null and _same(c, ref.get_pixel(x, y))):
				continue
			var layer := PlayerSheet.classify(c)
			if layer == 0:
				continue
			var l := lum.get_pixel(x, y)
			out.set_pixel(x, y, Color(maxf(l.r, maxf(l.g, l.b)), layer / 8.0, 0.0, c.a))
	_save(name, out)


## Fija: el color real de los píxeles que no se tiñen (y que no están en la referencia).
func _save_fixed(name: String, ids: Image, real: Image, ref: Image) -> void:
	var out := Image.create_empty(ids.get_width(), ids.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in ids.get_height():
		for x in ids.get_width():
			var c := ids.get_pixel(x, y)
			if c.a < 0.05 or (ref != null and _same(c, ref.get_pixel(x, y))):
				continue
			if PlayerSheet.classify(c) != 0:
				continue
			out.set_pixel(x, y, real.get_pixel(x, y))
	_save(name, out)


## Guarda la hoja; las capas con variantes, un archivo por variante (T160: cada
## variante son DIRS filas de la imagen).
func _save(name: String, out: Image) -> void:
	if not name in PlayerSheet.VARIANT_LAYERS:
		out.save_png(ProjectSettings.globalize_path(PlayerSheet.file_of(name)))
		return
	var h := PlayerSheet.CH * PlayerSheet.DIRS
	for v in out.get_height() / h:
		out.get_region(Rect2i(0, v * h, out.get_width(), h)).save_png(ProjectSettings.globalize_path(PlayerSheet.file_of(name, v)))


static func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a) < 0.04
