class_name SoundMap
## Qué suena para cada cosa (T77). Cada habilidad lanza dos capas: la de su tipo
## (Sfx.skill_sound) y una de firma (clic digital, aire, zumbido, campana o golpe
## grave), con un tono propio sacado de su id, así que dos habilidades del mismo
## tipo no suenan igual; además una pequeña variación al azar en cada uso. Los
## impactos suenan según el daño; recoger y equipar, según el material del objeto;
## los únicos y los conjuntos tienen su caída; los pasos dependen del suelo.

## Tono de cada habilidad: entre BASE y BASE + SPREAD según su id.
const PITCH_BASE := 0.86
const PITCH_SPREAD := 0.28
## Variación al azar en cada uso (±).
const JITTER := 0.04
const IMPACTS := {"fire": "imp_fire", "cold": "imp_ice", "lightning": "imp_zap", "chaos": "imp_splat"}
## Suelo de cada estilo de zona (lo que no está, piedra).
const FLOORS := {
	"forest": "step_dirt", "swamp": "step_dirt", "sandbox": "step_dirt", "camp": "step_dirt", "fosa": "step_dirt", "grieta": "step_dirt",
	"servers": "step_metal", "fabrica": "step_metal", "kernel": "step_metal", "bus": "step_metal", "silicio": "step_metal",
	"anillo": "step_metal", "setup": "step_metal", "system": "step_metal", "console": "step_metal", "phone": "step_metal",
}
## Suelo de la zona actual (lo pone World al cargarla).
static var floor_style := ""


## Tono propio de la habilidad (estable: siempre el mismo para el mismo id).
static func skill_pitch(id: String) -> float:
	return PITCH_BASE + float(absi(hash(id)) % 1000) / 1000.0 * PITCH_SPREAD


## Capa de firma según cómo es la habilidad.
static func signature_layer(p: Dictionary) -> String:
	var tags: Array = p.get("tags", [])
	var kind := String(p.get("kind", ""))
	if kind in ["ground_aoe", "nova", "quake", "leap_slam", "melee_area", "charge"] and not ("spell" in tags and String(p.get("damage_type", "")) == "cold"):
		return "lay_thump"
	if "melee" in tags:
		return "lay_whoosh"
	match String(p.get("damage_type", "")):
		"lightning":
			return "lay_hum"
		"cold":
			return "lay_chime"
		"physical":
			return "lay_click"
	return "lay_chime" if kind in ["buff", "aura", "barrier", "heal"] else ""


## Capas al lanzar: [[sonido, volumen dB, tono]].
static func cast_layers(p: Dictionary) -> Array:
	var pitch := skill_pitch(String(p.get("id", "")))
	var base := Sfx.skill_sound("trap" if String(p.get("deploy", "")) != "" else String(p.get("kind", "")), String(p.get("damage_type", "")))
	var layers: Array = [[base, 0.0, pitch]]
	var sig := signature_layer(p)
	if sig != "":
		layers.append([sig, -6.0, pitch * 1.05])
	return layers


static func play_cast(p: Dictionary) -> void:
	for l in cast_layers(p):
		Sfx.play(l[0], l[1], float(l[2]) * randf_range(1.0 - JITTER, 1.0 + JITTER))


## Impacto de un proyectil según su daño.
static func impact(damage_type: String) -> String:
	return String(IMPACTS.get(damage_type, "imp_thud"))


## Material de un objeto para su sonido: "metal", "cloth", "glass" o "board".
static func material(item: Item) -> String:
	if item is Flask:
		return "glass"
	if item is Motherboard or item is RamModule:
		return "board"
	if item == null:
		return "cloth"
	var tags: Array = item.base.get("tags", [])
	if "weapon" in tags or "str_armour" in tags or "jewellery" in tags or item is KeyItem:
		return "metal"
	return "cloth"


static func pickup(item: Item) -> String:
	return "pick_" + material(item)


static func equip(item: Item) -> String:
	match material(item):
		"metal":
			return "equip_metal"
		"glass":
			return "pick_glass"
		"board":
			return "pick_board"
	return "equip_cloth"


static func play_pickup(item: Item) -> void:
	Sfx.play(pickup(item), -4.0, randf_range(0.95, 1.05) * (1.25 if item and "jewellery" in item.base.get("tags", []) else 1.0))


static func play_equip(item: Item) -> void:
	Sfx.play(equip(item), -4.0, randf_range(0.96, 1.04))


## Sonido de la caída de un objeto ("" si no tiene uno especial).
static func drop(item: Item) -> String:
	if item == null or not item.is_equipment():
		return ""
	if item.rarity == Rarity.Item.UNIQUE:
		return "unique_drop"
	if item.rarity == Rarity.Item.SET:
		return "set_drop"
	return ""


## Segundos hasta el próximo tiempo de una pista a `bpm` que va por `position` s (T78:
## los cambios de pista caen a compás).
static func beat_wait(position: float, bpm: float) -> float:
	var beat := 60.0 / maxf(bpm, 1.0)
	return beat - fmod(position, beat)


## Aviso corto de música (T78): "elite", "loot", "level" o "boss". Sin el reproductor
## de música (pruebas, herramientas) no hace nada y devuelve false.
static func stinger(kind: String) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var mp: Node = tree.root.get_node_or_null("MusicPlayer") if tree and tree.root else null
	return bool(mp.call("stinger", kind)) if mp and mp.has_method("stinger") else false


## ¿Este enemigo merece aviso al verlo por primera vez? Élites ("elite") y únicos ("boss").
static func sighting_stinger(rarity: int) -> String:
	if rarity == Rarity.Enemy.UNIQUE:
		return "boss"
	if rarity == Rarity.Enemy.ELITE:
		return "elite"
	return ""


static func step(style: String) -> String:
	return String(FLOORS.get(style, "step_stone"))


static func play_step() -> void:
	Sfx.play(step(floor_style), -18.0, randf_range(0.88, 1.12))
