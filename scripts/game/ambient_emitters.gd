class_name AmbientEmitters
extends Node2D
## Ambiente posicional: además del ambiente general de la zona, fuentes que solo
## se oyen cerca. Racks que zumban, charcos y lagos que gotean, grietas y
## acantilados con viento. Salen de los obstáculos de la zona y, en los estilos
## que lo piden (servidores, alcantarillas, la Grieta), de puntos sueltos si no
## hay obstáculos de ese tipo. Los sonidos son assets/audio/ambient/emit_*.wav
## (tools/generate_sfx.gd -- posicional); el volumen sigue al del ambiente.

## Tipo de obstáculo → sonido.
const SOUNDS := {"rack": "emit_rack", "puddle": "emit_drip", "lake": "emit_drip", "bog": "emit_drip",
	"chasm": "emit_wind", "cliff": "emit_wind"}
## Estilos de zona que tienen su fuente aunque no haya obstáculos de ese tipo.
const STYLE_SOUNDS := {"servers": "emit_rack", "terminal": "emit_rack", "bios": "emit_rack", "setup": "emit_rack",
	"alcantarillas": "emit_drip", "grieta": "emit_wind"}
const MAX_PER_SOUND := 6
## Distancia mínima entre dos fuentes del mismo sonido (que no se amontonen).
const MIN_GAP := 420.0
## A partir de aquí ya no se oye.
const MAX_DISTANCE := 560.0
const VOLUME_DB := {"emit_rack": -11.0, "emit_drip": -7.0, "emit_wind": -9.0}


## Dónde suena cada cosa: [{sound, pos}]. `points`: sitios libres para el sonido
## del estilo de la zona.
static func plan(obstacles: Array, style: String, points: Array) -> Array:
	var out: Array = []
	var candidates: Array = []
	for o in obstacles:
		var s := String(SOUNDS.get(String(o.get("kind", "")), ""))
		if s != "":
			candidates.append({"sound": s, "pos": o["pos"]})
	if STYLE_SOUNDS.has(style):
		for p in points:
			candidates.append({"sound": STYLE_SOUNDS[style], "pos": p})
	for c in candidates:
		var same := out.filter(func(e: Dictionary) -> bool: return e["sound"] == c["sound"])
		if same.size() >= MAX_PER_SOUND:
			continue
		if same.any(func(e: Dictionary) -> bool: return (e["pos"] as Vector2).distance_to(c["pos"]) < MIN_GAP):
			continue
		out.append(c)
	return out


func setup(zone: Zone) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(zone.id)
	var points: Array = zone.pack_centers(MAX_PER_SOUND, rng) if STYLE_SOUNDS.has(zone.style) else []
	var volume := Sfx.ambient_volume()
	for e in plan(zone.obstacles, zone.style, points):
		_add_source(e, volume, rng)


func _add_source(e: Dictionary, volume: float, rng: RandomNumberGenerator) -> void:
	var path := Sfx.AMB_DIR + String(e["sound"]) + ".wav"
	if not ResourceLoader.exists(path):
		return
	var wav := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
	Sfx.set_loop(wav)
	var p := AudioStreamPlayer2D.new()
	p.stream = wav
	p.position = e["pos"]
	p.max_distance = MAX_DISTANCE
	p.attenuation = 1.6
	p.volume_db = float(VOLUME_DB.get(e["sound"], -9.0)) + linear_to_db(maxf(volume, 0.001))
	add_child(p)
	if volume > 0.001:
		p.play(rng.randf() * wav.get_length())   # cada fuente en su punto del bucle
