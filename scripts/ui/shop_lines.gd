class_name ShopLines
## Lo que dicen los comerciantes en su tienda (T71): Nacho, sarcástico y con la
## gabardina llena de cosas «originales»; Aída, seca y ordenada. Cada momento
## (entrar, pasar el ratón, comprar, vender…) tiene su lista y sale una al azar.

const LINES := {
	"nacho": {
		"enter": [
			"Psst. Tú. Sí, tú. ¿Buscas hardware?",
			"Original, original. Bueno, original de algún lado.",
			"Pasa, pasa. Hoy tengo género fresco. Casi sin usar.",
			"Todo con garantía. La garantía es que yo ya me fui.",
			"No hago facturas, pero hago amigos.",
		],
		"hover": [
			"Ese es bueno. Lo sé porque lo dice la caja.",
			"Esta RAM se cayó de un camión. De un camión de Amazon.",
			"Lleva pegatina de «Made in». En algún sitio lo hicieron.",
			"Precio de amigo. Bueno, de conocido.",
			"Huele a nuevo. Le eché colonia.",
			"Ese lo tenía reservado para mi primo. Mi primo no paga.",
			"Funciona. Lo probé encendiéndolo. Una vez.",
		],
		"hover_deal": ["La oferta del día. Del día que me la encontré.", "Eso a ese precio es un robo. Literalmente, no preguntes."],
		"hover_contraband": ["Eso no lo has visto. Y yo no te lo he enseñado.", "Número de serie limado por motivos estéticos."],
		"buy": [
			"Un placer. Sin devoluciones, sin preguntas, sin recibo.",
			"Buena elección. Todas lo son si pagas.",
			"Ya es tuyo. Si alguien pregunta, te lo encontraste.",
			"Disfrútalo. Y si hace humo, es una característica.",
		],
		"buyback": ["¿Otra vez tú? Te lo cobro igual, por el cariño.", "Lo guardé por si volvías. Mentira, nadie lo quería."],
		"sell": [
			"Esto vale poco. Pero yo soy generoso. Poco, pero generoso.",
			"Te lo compro. Lo revenderé al triple, no te ofendas.",
			"Ajá. Esto en el mercado negro… digo, de segunda mano, se mueve.",
		],
		"bulk": ["Te lo compro por kilo.", "¿Todo eso? Necesito una gabardina más grande."],
		"broke": [
			"Sin tokens no hay paraíso.",
			"Nacho no fía. Lo dice un cartel. Que también vendo.",
			"Vuelve cuando seas rico. O cuando tengas tokens, que es lo mismo.",
			"¿Regatear? Esto no es un mercadillo. Bueno, sí, pero no.",
		],
		"full": ["No te cabe. Como tu backlog.", "Haz sitio, que esto no es una mochila de Mary Poppins."],
		"refresh": [
			"Espera, que tengo otra caja en la bodega.",
			"Caja nueva. Mismo camión.",
			"Esto acaba de llegar. De dónde, no importa.",
		],
		"pocket": ["Esto no lo enseño a cualquiera. Tú pareces cualquiera, pero bueno.", "Mira a los lados… vale. Lo bueno."],
	},
	"aida": {
		"enter": [
			"Equipo revisado. Una vez. Por mí. Con eso basta.",
			"Todo ordenado por nivel. No lo desordenes.",
			"Si buscas algo bonito, ve con Nacho. Aquí hay cosas que funcionan.",
		],
		"hover": [
			"Ese aguanta. Lo usé en un deploy de viernes.",
			"Sin pegatinas ni humo. Equipo de verdad.",
			"Mira bien los afijos. Luego no vengas a quejarte.",
		],
		"hover_deal": ["No hago ofertas."],
		"hover_contraband": ["Aquí no hay de eso."],
		"buy": ["Úsalo bien.", "Apuntado. Es broma, no apunto nada.", "Que te dure más que el último."],
		"buyback": ["¿Te arrepentiste? Pasa a todos."],
		"sell": ["Lo pongo en la caja de repuestos.", "Esto ha visto cosas. Lo acepto."],
		"bulk": ["Vale. Lo clasifico luego."],
		"broke": ["No llegas. Junta tokens y vuelve.", "Sin tokens no hay trato. Ni con antigüedad."],
		"full": ["Vacía la bolsa primero."],
		"refresh": ["Esto es lo que hay."],
		"pocket": ["Aquí no hay bolsillos secretos."],
	},
}


## Una frase al azar del comerciante para ese momento ("" si no hay).
static func pick(vendor: String, event: String, rng: RandomNumberGenerator = null) -> String:
	var pool: Array = LINES.get(vendor, LINES["nacho"]).get(event, [])
	if pool.is_empty():
		return ""
	var i := rng.randi_range(0, pool.size() - 1) if rng else randi() % pool.size()
	return pool[i]
