class_name ImpactFx
extends Node2D
## Partículas de impacto y de muerte en pixel art (cuadritos en la rejilla de 2 px
## del filtro), según el tipo de daño:
##   físico: astillas y bits ("0"/"1") · fuego: chispas que suben · frío: esquirlas
##   de hielo · rayo: chispazos rápidos · caos: gotas verdes que caen.
## Las muertes son más grandes: el enemigo se "descompila" en píxeles, se rompe en
## hielo, se quema a ceniza, salta en chispas o se disuelve. Los destellos de los
## golpes de fuego y rayo y de las muertes dan luz (WorldPost.lights).
## Lo crea EnemyManager; solo dibuja, no toca la simulación.
## T172, motivos de datos (solo con «Efectos de pantalla»: si no, las mismas
## partículas de antes): los golpes sueltan algún corchete o «;», las muertes un
## anillo de nodos de red que se apagan y el glifo de su familia (MATERIAL_GLYPHS),
## y el botín bueno, bits que suben entre corchetes.

const MAX_PARTICLES := 700
const GRID := 2.0
const COLORS := {
	"physical": [Color("e8e0d0"), Color("a89f90"), Color("6fd36b")],
	"fire": [Color("ffd060"), Color("ff8a2a"), Color("e0452f")],
	"cold": [Color("e8f8ff"), Color("9fd8ff"), Color("5a9ad0")],
	"lightning": [Color("fffbe0"), Color("ffe870"), Color("a8d8ff")],
	"chaos": [Color("b0ff90"), Color("6fd36b"), Color("3a8a40")],
}
## Color de la luz que dan los destellos (los físicos no alumbran).
const LIGHT_COLORS := {"fire": Color("ff9a3a"), "lightning": Color("fff0a0"), "cold": Color("9fd8ff"), "chaos": Color("8aff70")}

## Glifos sueltos de los golpes y glifo de cada familia (material) al morir.
const BRACKETS := ["{", "}", "[", "]", "<", ">", ";"]
const MATERIAL_GLYPHS := {"digital": ["{ }", "0x0", "01"], "metal": ["#", "&&", "%"], "crystal": ["<>", "*", "+"], "flesh": [";", "~", "!"]}
## Nodos del anillo de muerte y color al que se apagan.
const DEATH_NODES := 6
const NODE_OFF := Color("3a4250")

## Partículas: {pos, vel, life, max, color, size, kind ("sq", "shard", "bit", "spark", "node"), grav, text?, link?}
var _parts: Array[Dictionary] = []
## Destellos con luz: {pos, color, radius, life, max}
var flashes: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 0


## Colores de las partículas de un tipo de daño (el tono medio, el del modo
## daltónico si está puesto, como las auras).
static func colors_for(damage_type: String) -> Array:
	var t := damage_type if COLORS.has(damage_type) else "physical"
	var out: Array = (COLORS[t] as Array).duplicate()
	out[1] = Accessibility.aura_color(t, out[1])
	return out


## Los motivos de datos (T172) van con los efectos de pantalla.
static func motifs() -> bool:
	return WorldPost.screen_fx()


func _glyph(pos: Vector2, text: String, color: Color, vel: Vector2, life: float, grav := 0.0) -> void:
	_parts.append({"pos": pos, "vel": vel, "life": life, "max": life, "color": color, "size": 2.0, "kind": "bit", "grav": grav, "text": text})


## Golpe a un enemigo en `pos`. `strength` 0..1 (fracción de vida que quitó) y crítico dan más.
func hit(pos: Vector2, damage_type: String, crit := false, strength := 0.1) -> void:
	var t := damage_type if COLORS.has(damage_type) else "physical"
	var n := clampi(int(3.0 + strength * 14.0) + (5 if crit else 0), 3, 12)
	if _parts.size() + n > MAX_PARTICLES:
		return
	var palette: Array = colors_for(t)
	if motifs() and (crit or strength > 0.12):
		_glyph(pos + Vector2(randf_range(-6, 6), -4), BRACKETS[randi() % BRACKETS.size()], palette[0],
			Vector2(randf_range(-40, 40), -randf_range(50, 90)), 0.4, 120.0)
	for k in n:
		var dir := Vector2.from_angle(randf() * TAU)
		var p := {"pos": pos + dir * randf_range(2.0, 8.0), "life": randf_range(0.25, 0.5), "color": palette[randi() % palette.size()],
			"size": 2.0 if randf() < 0.7 else 4.0, "kind": "sq", "grav": 0.0}
		match t:
			"fire":
				p["vel"] = Vector2(dir.x * 40.0, -randf_range(40.0, 120.0))
				p["grav"] = -60.0
			"cold":
				p["vel"] = dir * randf_range(80.0, 180.0)
				p["kind"] = "shard"
				p["grav"] = 260.0
			"lightning":
				p["vel"] = dir * randf_range(180.0, 320.0)
				p["kind"] = "spark"
				p["life"] = randf_range(0.1, 0.22)
			"chaos":
				p["vel"] = Vector2(dir.x * 50.0, randf_range(-60.0, 10.0))
				p["grav"] = 320.0
			_:
				p["vel"] = dir * randf_range(60.0, 160.0)
				p["grav"] = 200.0
				if randf() < 0.3:
					p["kind"] = "bit"
					p["text"] = "0" if randf() < 0.5 else "1"
		p["max"] = p["life"]
		_parts.append(p)
	if LIGHT_COLORS.has(t) and (crit or strength > 0.15 or randf() < 0.25):
		_flash(pos, LIGHT_COLORS[t], 90.0 + (60.0 if crit else 0.0), 0.15)


## Restos de las muertes físicas según el material (T73): chatarra con chispas,
## añicos de cristal, gotas que caen o (digital) píxeles y bits.
const MATERIAL_DEBRIS := {
	"metal": [Color("8d9099"), Color("5e6068"), Color("ffd060")],
	"crystal": [Color("d8c8ff"), Color("9a7ae0"), Color("8af0ff")],
	"flesh": [Color("8a2a2a"), Color("5a1a1a"), Color("c8b8a0")],
}


## Muerte con estilo según el daño que lo mató. `radius`: tamaño del enemigo;
## `tint`: color del enemigo (los píxeles en que se descompila); `material`:
## de qué está hecho, para las muertes físicas.
func death(pos: Vector2, damage_type: String, radius: float, tint: Color, material := "digital") -> void:
	var t := damage_type if COLORS.has(damage_type) else "physical"
	var n := clampi(int(radius * 1.4), 14, 40)
	if _parts.size() + n > MAX_PARTICLES:
		n = maxi(0, MAX_PARTICLES - _parts.size())
	var palette: Array = colors_for(t)
	if motifs() and _parts.size() + n + DEATH_NODES + 2 <= MAX_PARTICLES:
		_death_motifs(pos, radius, palette, material)
	for k in n:
		var dir := Vector2.from_angle(randf() * TAU)
		var start := pos + Vector2(randf_range(-radius, radius), randf_range(-radius * 1.4, radius * 0.3))
		var p := {"pos": start, "life": randf_range(0.5, 1.0), "size": 2.0 if randf() < 0.5 else 4.0, "kind": "sq", "grav": 0.0,
			"color": palette[randi() % palette.size()]}
		match t:
			"fire":
				# Ceniza: gris que sube despacio, con brasas.
				p["color"] = Color("4a4448") if k % 3 != 0 else palette[randi() % 2]
				p["vel"] = Vector2(randf_range(-20.0, 20.0), -randf_range(20.0, 70.0))
				p["grav"] = -20.0
				p["life"] = randf_range(0.8, 1.4)
			"cold":
				# Se rompe en pedazos de hielo que caen.
				p["vel"] = dir * randf_range(90.0, 240.0) + Vector2(0, -60.0)
				p["kind"] = "shard"
				p["grav"] = 420.0
				p["size"] = randf_range(3.0, 6.0)
			"lightning":
				p["vel"] = dir * randf_range(200.0, 420.0)
				p["kind"] = "spark"
				p["life"] = randf_range(0.15, 0.35)
			"chaos":
				# Se disuelve: gotas que escurren hacia abajo.
				p["vel"] = Vector2(randf_range(-15.0, 15.0), randf_range(10.0, 50.0))
				p["grav"] = 160.0
			_ when MATERIAL_DEBRIS.has(material):
				var debris: Array = MATERIAL_DEBRIS[material]
				p["color"] = debris[k % 2]
				match material:
					"metal":
						# Chatarra que salta y cae pesada; alguna chispa.
						p["vel"] = dir * randf_range(80.0, 200.0) + Vector2(0, -80.0)
						p["grav"] = 520.0
						p["kind"] = "shard" if k % 2 == 0 else "sq"
						if k % 6 == 0:
							p["kind"] = "spark"
							p["color"] = debris[2]
							p["life"] = randf_range(0.15, 0.3)
					"crystal":
						p["vel"] = dir * randf_range(120.0, 260.0)
						p["kind"] = "shard"
						p["grav"] = 300.0
						p["size"] = randf_range(2.0, 5.0)
						if k % 4 == 0:
							p["color"] = debris[2]
					_:
						# Carne: gotas que salpican y caen al suelo.
						p["vel"] = Vector2(dir.x * randf_range(40.0, 120.0), -randf_range(30.0, 110.0))
						p["grav"] = 380.0
			_:
				# Se "descompila": píxeles de su color y bits que se dispersan.
				p["color"] = tint.lerp(Color.WHITE, randf() * 0.3) if k % 4 != 0 else palette[2]
				p["vel"] = dir * randf_range(40.0, 140.0) + Vector2(0, -40.0)
				p["grav"] = 180.0
				if k % 5 == 0:
					p["kind"] = "bit"
					p["text"] = "0" if randf() < 0.5 else "1"
					p["color"] = palette[2]
		p["max"] = p["life"]
		_parts.append(p)
	if LIGHT_COLORS.has(t):
		_flash(pos, LIGHT_COLORS[t], 140.0 + radius * 2.0, 0.3)


## Anillo de nodos de red unidos que se apagan (del color del daño al gris) y el
## glifo de la familia del enemigo, que sube y se desvanece.
func _death_motifs(pos: Vector2, radius: float, palette: Array, material: String) -> void:
	var r := maxf(10.0, radius * 0.9)
	var turn := randf() * TAU
	var ring: Array[Vector2] = []
	for k in DEATH_NODES:
		ring.append(pos + Vector2.from_angle(turn + TAU * k / DEATH_NODES) * Vector2(r, r * 0.6))
	for k in DEATH_NODES:
		var life := randf_range(0.55, 0.8)
		_parts.append({"pos": ring[k], "vel": (ring[k] - pos).normalized() * 18.0, "life": life, "max": life, "color": palette[k % 2],
			"size": 3.0, "kind": "node", "grav": 0.0, "link": ring[(k + 1) % DEATH_NODES] - ring[k]})
	var glyphs: Array = MATERIAL_GLYPHS.get(material, MATERIAL_GLYPHS["digital"])
	_glyph(pos + Vector2(-4, -radius * 0.4), glyphs[randi() % glyphs.size()], palette[0], Vector2(0, -45.0), 0.9)


## Botín bueno (T172): bits que suben del suelo entre corchetes del color de la rareza.
func loot(pos: Vector2, color: Color) -> void:
	if not motifs() or _parts.size() > MAX_PARTICLES * 0.7:
		return
	_glyph(pos + Vector2(-16, -4), "[", color, Vector2(0, -20), 0.7)
	_glyph(pos + Vector2(12, -4), "]", color, Vector2(0, -20), 0.7)
	for k in 5:
		_glyph(pos + Vector2(randf_range(-10, 8), randf_range(-2, 6)), "0" if randi() % 2 == 0 else "1", color.lightened(0.3),
			Vector2(randf_range(-8, 8), -randf_range(40, 80)), randf_range(0.5, 0.8))


## Destello al lanzar una habilidad (T74, ver SkillFx): `kind` "flare" (brasas en
## corona), "frost" (esquirlas lentas), "spark" (chispazos), "glitch" (cuadros
## verdes que saltan) o "flick" (unos píxeles hacia delante).
func cast(pos: Vector2, kind: String, color: Color, dir := Vector2.RIGHT) -> void:
	if _parts.size() > MAX_PARTICLES * 0.7:
		return
	var n := 4 if Accessibility.reduce_flashes else 7   # menos destellos: menos partículas
	for k in n:
		var a := TAU * k / n
		var p := {"pos": pos, "life": 0.22, "size": 2.0, "kind": "sq", "grav": 0.0, "color": color.lightened(0.3 * (k % 2))}
		match kind:
			"flare":
				p["vel"] = Vector2.from_angle(a) * 70.0 + Vector2(0, -30.0)
				p["grav"] = -80.0
				p["color"] = Color("ffd060") if k % 2 == 0 else color
			"frost":
				p["vel"] = Vector2.from_angle(a) * 45.0
				p["kind"] = "shard"
				p["size"] = 3.0
				p["life"] = 0.3
			"spark":
				p["vel"] = Vector2.from_angle(a) * 220.0
				p["kind"] = "spark"
				p["life"] = 0.12
			"glitch":
				p["pos"] = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)).snapped(Vector2(GRID, GRID))
				p["vel"] = Vector2.ZERO
				p["size"] = 4.0
				p["color"] = Color("6fd36b") if k % 2 == 0 else color
			_:
				p["vel"] = dir.rotated(randf_range(-0.4, 0.4)) * randf_range(80.0, 150.0)
				p["life"] = 0.15
		p["max"] = p["life"]
		_parts.append(p)
	if kind in ["flare", "spark"]:
		_flash(pos, color, 50.0, 0.1)


## Una partícula de estela detrás de un proyectil: brasas que suben, escarcha que
## cae, chispas cortas, gotas, bits o puntitos de rastreo.
func trail(pos: Vector2, kind: String, color: Color, dir := Vector2.RIGHT) -> void:
	if _parts.size() > MAX_PARTICLES * 0.5:
		return
	var p := {"pos": pos - dir * 6.0 + Vector2(randf_range(-2, 2), randf_range(-2, 2)), "life": 0.3, "size": 2.0, "kind": "sq", "grav": 0.0,
		"color": color, "vel": -dir * 20.0}
	match kind:
		"embers":
			p["vel"] = Vector2(randf_range(-15, 15), -randf_range(30, 60))
			p["color"] = Color("ffd060") if randf() < 0.5 else Color("e0452f")
		"frost":
			p["vel"] = Vector2(randf_range(-10, 10), randf_range(10, 30))
			p["grav"] = 60.0
			p["color"] = Color("e8f8ff")
			p["life"] = 0.4
		"sparks":
			p["vel"] = dir.orthogonal() * randf_range(-120, 120)
			p["kind"] = "spark"
			p["life"] = 0.08
		"drips":
			p["vel"] = Vector2(0, 20)
			p["grav"] = 260.0
		"dots":
			p["life"] = 0.5
			p["vel"] = Vector2.ZERO
		_:
			if randf() < 0.35:
				p["kind"] = "bit"
				p["text"] = "0" if randf() < 0.5 else "1"
	p["max"] = p["life"]
	_parts.append(p)


## Estallido de un proyectil al golpear, según su firma: "splash" (fuego), "shatter"
## (hielo), "zapburst" (rayo), "splat" (caos) o "shards" (físico, salen hacia delante).
func skill_impact(pos: Vector2, kind: String, color: Color, dir := Vector2.RIGHT) -> void:
	if _parts.size() > MAX_PARTICLES * 0.8:
		return
	var n := 5 if Accessibility.reduce_flashes else 9
	for k in n:
		var a := TAU * k / n + randf() * 0.3
		var p := {"pos": pos, "life": randf_range(0.2, 0.35), "size": 2.0 if k % 3 else 4.0, "kind": "sq", "grav": 0.0, "color": color,
			"vel": Vector2.from_angle(a) * randf_range(60.0, 140.0)}
		match kind:
			"splash":
				p["grav"] = -40.0
				p["color"] = Color("ffd060") if k % 3 == 0 else (Color("ff8a2a") if k % 3 == 1 else color)
			"shatter":
				p["kind"] = "shard"
				p["grav"] = 300.0
				p["size"] = randf_range(3.0, 5.0)
				p["color"] = Color("e8f8ff") if k % 2 == 0 else color
			"zapburst":
				p["kind"] = "spark"
				p["vel"] = Vector2.from_angle(a) * randf_range(180.0, 300.0)
				p["life"] = randf_range(0.08, 0.16)
			"splat":
				p["vel"] = Vector2.from_angle(a) * randf_range(40.0, 90.0) + Vector2(0, -40.0)
				p["grav"] = 320.0
			_:
				p["vel"] = dir.rotated(randf_range(-1.0, 1.0)) * randf_range(60.0, 160.0)
				p["grav"] = 220.0
				if k % 4 == 0:
					p["kind"] = "bit"
					p["text"] = "0" if randf() < 0.5 else "1"
		p["max"] = p["life"]
		_parts.append(p)
	if LIGHT_COLORS.has(String({"splash": "fire", "zapburst": "lightning"}.get(kind, ""))):
		_flash(pos, color, 70.0, 0.12)


func _flash(pos: Vector2, color: Color, radius: float, life: float) -> void:
	if flashes.size() < 12:
		if Accessibility.reduce_flashes:   # menos destellos: un fogonazo más chico y tenue
			radius *= 0.6
			color = Color(color, color.a * Accessibility.REDUCED)
		flashes.append({"pos": pos, "color": color, "radius": radius, "life": life, "max": life})


func count() -> int:
	return _parts.size()


func clear() -> void:
	_parts.clear()
	flashes.clear()


func _process(delta: float) -> void:
	if _parts.is_empty() and flashes.is_empty():
		return
	for p in _parts:
		p["life"] -= delta
		p["vel"] += Vector2(0, p["grav"]) * delta
		p["vel"] *= 1.0 - 1.5 * delta
		p["pos"] += p["vel"] * delta
	_parts.assign(_parts.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0))
	for f in flashes:
		f["life"] -= delta
	flashes.assign(flashes.filter(func(f: Dictionary) -> bool: return f["life"] > 0.0))
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var a: float = clampf(p["life"] / p["max"] * 1.5, 0.0, 1.0)
		var c: Color = p["color"]
		c.a = a
		# En la rejilla del filtro: posiciones y tamaños en múltiplos de 2 px.
		var at := (p["pos"] as Vector2).snapped(Vector2(GRID, GRID))
		var s: float = p["size"]
		match p["kind"]:
			"shard":
				var d: Vector2 = (p["vel"] as Vector2).normalized() * s
				draw_colored_polygon(PackedVector2Array([at - d, at + d.orthogonal() * 0.4, at + d, at - d.orthogonal() * 0.4]), c)
			"spark":
				draw_line(at, at - (p["vel"] as Vector2) * 0.03, c, 2.0)
			"bit":
				draw_string(_font, at, p["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c)
			"node":
				# Se apaga: del color del daño al gris; la arista al siguiente nodo, más tenue.
				var off := Color(NODE_OFF.lerp(c, clampf(p["life"] / p["max"] * 1.6 - 0.3, 0.0, 1.0)), a)
				draw_line(at, at + (p["link"] as Vector2), Color(off, a * 0.45), 1.0)
				draw_rect(Rect2(at - Vector2(s, s) * 0.5, Vector2(s, s)).grow(1.0), Color(0.05, 0.07, 0.1, a))
				draw_rect(Rect2(at - Vector2(s, s) * 0.5, Vector2(s, s)), off)
			_:
				draw_rect(Rect2(at, Vector2(s, s)), c)
