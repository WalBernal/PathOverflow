class_name SoundMap
## Qué suena para cada cosa (T77). Cada habilidad lanza dos capas: la de su tipo
## (Sfx.skill_sound), con un tono propio sacado de su id, y su firma: desde T196 un
## sonido propio por habilidad (SIGNATURES); las que no lo tengan, una capa
## compartida (clic digital, aire, zumbido, campana o golpe grave) con ese mismo
## tono. Además, una pequeña variación al azar en cada uso. Los
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
	if kind in ["ground_aoe", "nova", "leap_slam", "melee_area", "charge"] and not ("spell" in tags and String(p.get("damage_type", "")) == "cold"):
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
	return "lay_chime" if kind in ["buff", "aura", "barrier"] else ""


## Volumen de la capa de tipo cuando no va a 0 dB (el encendido de un aura, como antes de T192).
const BASE_VOLUME := {"aura_on": -4.0}

## Capa de firma propia de cada habilidad (T196): assets/audio/sfx/<valor>.wav,
## sintetizada por tools/generate_sfx.gd (-- t196) según la columna de sonido de
## la ficha de T191 (docs/habilidades_y_ram.md). Va a SIGNATURE_DB con tono fijo
## (solo el ±JITTER de siempre) en lugar de la capa compartida de signature_layer.
const SIGNATURES := {
	# Cuerpo a cuerpo y movimiento
	"barrido": "sig_barrido", "deploy_continuo": "sig_deploy_continuo", "reinicio_forzado": "sig_reinicio_forzado",
	"force_push": "sig_force_push", "fuzzing": "sig_fuzzing", "teleport_tcp": "sig_teleport_tcp",
	"tunel_ssh": "sig_tunel_ssh", "git_revert": "sig_git_revert",
	# Hechizos y proyectiles
	"ping_letal": "sig_ping_letal", "fork_bomb": "sig_fork_bomb", "stack_overflow": "sig_stack_overflow",
	"flamewar": "sig_flamewar", "rayo_produccion": "sig_rayo_produccion", "deadlock": "sig_deadlock",
	"excepcion_en_cadena": "sig_excepcion_en_cadena", "fuga_de_memoria": "sig_fuga_de_memoria", "core_dump": "sig_core_dump",
	# Buffs, gritos, barrera y auras
	"firewall_personal": "sig_firewall_personal", "modo_seguro": "sig_modo_seguro", "hiperthreading": "sig_hiperthreading",
	"esta_en_produccion": "sig_esta_en_produccion", "daily_standup": "sig_daily_standup", "rollback_grito": "sig_rollback_grito",
	"aura_overclock": "sig_aura_overclock", "aura_blindaje": "sig_aura_blindaje", "aura_mantenimiento": "sig_aura_mantenimiento",
	"aura_mando": "sig_aura_mando", "aura_throttling": "sig_aura_throttling", "aura_exposicion": "sig_aura_exposicion",
	# Con efecto visual propio
	"rafaga_de_paquetes": "sig_rafaga_de_paquetes", "pipe_de_datos": "sig_pipe_de_datos", "tormenta_tickets": "sig_tormenta_tickets",
	"rollback": "sig_rollback", "bucle_infinito": "sig_bucle_infinito", "bomba_logica": "sig_bomba_logica",
	"ransomware": "sig_ransomware", "corrupcion_datos": "sig_corrupcion_datos", "paquete_rastreador": "sig_paquete_rastreador",
	"torreta_ci": "sig_torreta_ci", "derrame_aceite": "sig_derrame_aceite", "campo_estatica": "sig_campo_estatica",
	"charco_refrigerante": "sig_charco_refrigerante", "cascada_css": "sig_cascada_css",
	# Invocaciones
	"proceso_hijo": "sig_proceso_hijo", "drones_vigilancia": "sig_drones_vigilancia", "robot_centinela": "sig_robot_centinela",
	"daemon_segundo_plano": "sig_daemon_segundo_plano", "dron_escolta": "sig_dron_escolta", "golem_hardware": "sig_golem_hardware",
	"mainframe_titan": "sig_mainframe_titan", "dron_medico": "sig_dron_medico", "dron_escudo": "sig_dron_escudo",
	"bot_pruebas": "sig_bot_pruebas", "mina_rodante": "sig_mina_rodante", "agente_ia": "sig_agente_ia",
	"watchdog": "sig_watchdog", "bot_rastreador": "sig_bot_rastreador", "golem_silicio": "sig_golem_silicio",
	"golem_overclock": "sig_golem_overclock", "golem_utp": "sig_golem_utp", "golem_gpu": "sig_golem_gpu",
	"golem_kernel": "sig_golem_kernel",
	# Habilidades nuevas (T208)
	"ticket_escalado": "sig_ticket_escalado", "lazy_loading": "sig_lazy_loading", "descenso_gradiente": "sig_descenso_gradiente",
}
## Volumen de la capa de firma (propia o compartida) respecto a la de tipo.
const SIGNATURE_DB := -6.0


## Capa de firma propia de la habilidad `id` ("" si no tiene).
static func signature(id: String) -> String:
	return String(SIGNATURES.get(id, ""))


## Capas al lanzar: [[sonido, volumen dB, tono]].
static func cast_layers(p: Dictionary) -> Array:
	# Una variante suena más grave o más aguda que la base (T197).
	var shift := float(p.get("variant_pitch", 1.0))
	var pitch := skill_pitch(String(p.get("id", ""))) * shift
	var base := Sfx.skill_sound("trap" if String(p.get("deploy", "")) != "" else String(p.get("kind", "")), String(p.get("damage_type", "")))
	var layers: Array = [[base, float(BASE_VOLUME.get(base, 0.0)), pitch]]
	var own := signature(String(p.get("id", "")))
	if own != "":
		layers.append([own, SIGNATURE_DB, shift])
	else:
		var sig := signature_layer(p)
		if sig != "":
			layers.append([sig, SIGNATURE_DB, pitch * 1.05])
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
