class_name Achievements
## Logros y cosméticos. Cada logro (DEFS) se cumple con banderas o contadores del
## personaje y desbloquea un cosmético: un sombrero, un color de aura bajo los pies
## o un efecto en las pisadas. Se eligen en Pausa → Logros y cosméticos.
## flags["achievements"] = [ids], flags["cosmetics"] = {hat, aura, steps}.

const FLAG := "achievements"
const EQUIP_FLAG := "cosmetics"
const SLOTS := ["hat", "aura", "steps"]
const SLOT_NAMES := {"hat": "Sombrero", "aura": "Aura", "steps": "Pisadas"}
const COSMETICS := {
	"hat": {"gorra_hackaton": "Gorra del Hackatón LinceCode", "casco_obra": "Casco de obra del Monolito", "sombrero_pescador": "Sombrero de pescador del Pepe", "corona_admin": "Corona de admin"},
	"aura": {"dorada": "Aura dorada", "silicio": "Aura de silicio", "morada": "Aura del atlas"},
	"steps": {"bits": "Pisadas de bits", "llamas": "Pisadas de llamas", "glitch": "Pisadas con glitch"},
}
## {id, name, text, check: [tipo, clave, valor], reward: [slot, cosmético]}.
## Tipos: flag (bandera), stat (contador en flags >= valor), lore (archivos >= valor),
## atlas (nivel del atlas >= valor).
const DEFS := [
	{"id": "primer_bug", "name": "Hola, mundo", "text": "Elimina a tu primer enemigo.", "check": ["stat", "stat_kills", 1], "reward": ["hat", "gorra_hackaton"]},
	{"id": "arquitecto", "name": "La tapa", "text": "Derrota al Arquitecto del Monolito.", "check": ["flag", "act1_complete", true], "reward": ["hat", "casco_obra"]},
	{"id": "kernel", "name": "Kernel Panic resuelto", "text": "Derrota a init.", "check": ["flag", "act2_complete", true], "reward": ["steps", "bits"]},
	{"id": "silicio", "name": "99 %", "text": "Detén a fw_update.exe.", "check": ["flag", "act3_complete", true], "reward": ["aura", "silicio"]},
	{"id": "bios", "name": "Contraseña cambiada", "text": "Cámbiale la contraseña a admin.", "check": ["flag", "act4_complete", true], "reward": ["hat", "corona_admin"]},
	{"id": "cazador", "name": "Mil bugs", "text": "Elimina a 1000 enemigos.", "check": ["stat", "stat_kills", 1000], "reward": ["aura", "dorada"]},
	{"id": "venganza", "name": "Venganza", "text": "Derrota a tu némesis.", "check": ["stat", "stat_nemesis", 1], "reward": ["steps", "llamas"]},
	{"id": "archivista", "name": "Arqueología de logs", "text": "Encuentra 9 archivos de lore.", "check": ["lore", "", 9], "reward": ["hat", "sombrero_pescador"]},
	{"id": "atlas", "name": "Cartógrafo de incidentes", "text": "Sube el atlas a nivel 3.", "check": ["atlas", "", 3], "reward": ["aura", "morada"]},
	{"id": "pesadilla", "name": "Prueba de carga", "text": "Termina el Acto IV en Pesadilla.", "check": ["flag", "act4_complete_d1", true], "reward": ["steps", "glitch"]},
]


static func unlocked_ids(c: CharacterData) -> Array:
	var raw = c.flags.get(FLAG, [])
	return raw if raw is Array else []


static func is_met(c: CharacterData, def: Dictionary) -> bool:
	var chk: Array = def["check"]
	match String(chk[0]):
		"flag":
			return c.flags.has(chk[1])
		"stat":
			return int(c.flags.get(chk[1], 0)) >= int(chk[2])
		"lore":
			return LoreNotes.found_ids(c).size() >= int(chk[2])
		"atlas":
			return Atlas.tier(c) >= int(chk[2])
	return false


## Comprueba los logros: devuelve los que se acaban de conseguir (y los apunta).
static func check(c: CharacterData) -> Array:
	var got := unlocked_ids(c).duplicate()
	var fresh: Array = []
	for def in DEFS:
		if not got.has(def["id"]) and is_met(c, def):
			got.append(def["id"])
			fresh.append(def)
	if not fresh.is_empty():
		c.flags[FLAG] = got
	return fresh


## Cosméticos que puedes ponerte en esa ranura (los de tus logros).
static func available(c: CharacterData, slot: String) -> Array:
	var out: Array = []
	var got := unlocked_ids(c)
	for def in DEFS:
		if got.has(def["id"]) and def["reward"][0] == slot:
			out.append(def["reward"][1])
	return out


static func equipped(c: CharacterData, slot: String) -> String:
	return String(c.flags.get(EQUIP_FLAG, {}).get(slot, "")) if c else ""


## Se pone (o se quita, con "") un cosmético que tengas.
static func equip(c: CharacterData, slot: String, id: String) -> bool:
	if id != "" and not available(c, slot).has(id):
		return false
	var e: Dictionary = c.flags.get(EQUIP_FLAG, {}).duplicate()
	e[slot] = id
	c.flags[EQUIP_FLAG] = e
	return true


## Aura bajo los pies (antes de dibujar el cuerpo).
static func draw_aura(ci: CanvasItem, feet: Vector2, c: CharacterData, t: float) -> void:
	var colors := {"dorada": Color("ffd24a"), "silicio": Color("5cd0ff"), "morada": Color("c08aff")}
	var id := equipped(c, "aura")
	if not colors.has(id):
		return
	var col: Color = colors[id]
	ci.draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 26.0, Color(col, 0.12 + 0.06 * sin(t * 3.0)))
	ci.draw_arc(Vector2.ZERO, 24.0 + 2.0 * sin(t * 3.0), 0.0, TAU, 32, Color(col, 0.6), 2.0, true)
	ci.draw_set_transform(Vector2.ZERO)


## Sombrero sobre la cabeza (después del cuerpo). `head`: centro de la cabeza; `r`: su radio.
static func draw_hat(ci: CanvasItem, head: Vector2, r: float, c: CharacterData) -> void:
	var top := head + Vector2(0, -r * 0.9)
	match equipped(c, "hat"):
		"gorra_hackaton":
			ci.draw_circle(top + Vector2(0, r * 0.15), r * 0.95, Color("2b4a6b"))
			ci.draw_rect(Rect2(top + Vector2(0, r * 0.05), Vector2(r * 1.4, r * 0.3)), Color("2b4a6b").darkened(0.2))
			ci.draw_circle(top + Vector2(-r * 0.2, -r * 0.2), r * 0.25, Color("d9a441"))
		"casco_obra":
			ci.draw_colored_polygon(QuestItemArt.ellipse(top + Vector2(0, r * 0.2), r * 1.05, r * 0.7), Color("f2c14e"))
			ci.draw_rect(Rect2(top + Vector2(-r * 1.3, r * 0.35), Vector2(r * 2.6, r * 0.22)), Color("e0a030"))
		"sombrero_pescador":
			ci.draw_colored_polygon(QuestItemArt.ellipse(top + Vector2(0, r * 0.45), r * 1.5, r * 0.35), Color("8a7a50"))
			ci.draw_colored_polygon(QuestItemArt.ellipse(top + Vector2(0, r * 0.05), r * 0.85, r * 0.55), Color("a08a5a"))
			ci.draw_line(top + Vector2(r * 0.4, -r * 0.1), top + Vector2(r * 0.8, -r * 0.4), Color("5cd0ff"), 1.5)   # un anzuelo
		"corona_admin":
			var pts := PackedVector2Array([top + Vector2(-r, r * 0.4), top + Vector2(-r, -r * 0.3), top + Vector2(-r * 0.5, r * 0.05),
				top + Vector2(0, -r * 0.5), top + Vector2(r * 0.5, r * 0.05), top + Vector2(r, -r * 0.3), top + Vector2(r, r * 0.4)])
			ci.draw_colored_polygon(pts, Color("ffd24a"))
			ci.draw_circle(top + Vector2(0, -r * 0.15), r * 0.15, Color("5cd0ff"))


## Huella de las pisadas en `p` (local), que se apaga en `life` (1 → 0).
static func draw_step(ci: CanvasItem, p: Vector2, c: CharacterData, life: float) -> void:
	match equipped(c, "steps"):
		"bits":
			ci.draw_string(ThemeDB.fallback_font, p + Vector2(-4, 4), "1" if int(p.x + p.y) % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.25, 0.95, 0.45, life))
		"llamas":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(0, -10 * life), p + Vector2(4, 0)]), Color(1.0, 0.5, 0.15, life))
		"glitch":
			ci.draw_rect(Rect2(p + Vector2(-6, -2), Vector2(12 * life, 3)), Color(0.75, 0.3, 1.0, life))
			ci.draw_rect(Rect2(p + Vector2(-2, 2), Vector2(8 * life, 2)), Color(0.3, 0.9, 1.0, life))
