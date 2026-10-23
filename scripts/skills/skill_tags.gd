class_name SkillTags
## Etiquetas de las habilidades (placas base): nombre en español y color de la
## "chapa" en tooltips. Una habilidad puede tener varias. Las RAM las usan para
## decidir con qué funcionan (requires_tags / excludes_tags) y los modificadores
## pueden depender de ellas (p. ej. "+20 % de daño de trampas").

const INFO := {
	"attack": ["ataque", "e8d9b0"],
	"spell": ["hechizo", "9a8ae0"],
	"melee": ["cuerpo a cuerpo", "c89060"],
	"projectile": ["proyectil", "c8c8c8"],
	"homing": ["teledirigido", "e8a0ff"],
	"area": ["área", "d9a441"],
	"chain": ["cadena", "8888ff"],
	"duration": ["duración", "6fd3c8"],
	"movement": ["movimiento", "5cb85c"],
	"trap": ["trampa", "b07a3a"],
	"mine": ["mina", "a0a040"],
	"totem": ["tótem", "a07850"],
	"minion": ["esbirro", "7fd07f"],
	"automaton": ["autómata", "7fd0e8"],
	"persistent": ["persistente", "9ad0ff"],
	"aura": ["aura", "d9b0ff"],
	"curse": ["maldición", "e06c6c"],
	"physical": ["físico", "c8b8a0"],
	"fire": ["fuego", "e0652f"],
	"cold": ["frío", "7fb8e0"],
	"lightning": ["rayo", "e8d070"],
	"chaos": ["caos", "b04ad9"],
	"elemental": ["elemental", "e0a060"],
	"degen": ["degenerativo", "9a5ad0"],
	"defense": ["defensa", "8ab0e0"],
	"buff": ["potenciador", "e8d070"],
}
## Tipo de daño → etiquetas que implica (se comprueban en las pruebas).
const DAMAGE_TYPE_TAGS := {
	"physical": ["physical"],
	"fire": ["fire", "elemental"],
	"cold": ["cold", "elemental"],
	"lightning": ["lightning", "elemental"],
	"chaos": ["chaos"],
}


static func display_name(tag: String) -> String:
	return INFO[tag][0] if INFO.has(tag) else tag


static func color(tag: String) -> Color:
	return Color(INFO[tag][1]) if INFO.has(tag) else Color("c8c8c8")


static func is_known(tag: String) -> bool:
	return INFO.has(tag)


## "[ataque] [proyectil] [físico]" con colores, para RichTextLabel.
static func bbcode(tags: Array) -> String:
	var parts := PackedStringArray()
	for t in tags:
		parts.append("[color=#%s]%s[/color]" % [color(String(t)).to_html(false), display_name(String(t))])
	return ", ".join(parts)


## Texto plano: "ataque, proyectil, físico".
static func plain(tags: Array) -> String:
	var parts := PackedStringArray()
	for t in tags:
		parts.append(display_name(String(t)))
	return ", ".join(parts)
