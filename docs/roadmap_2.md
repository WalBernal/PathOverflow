# Roadmap 2.0 — Path Overflow: El Último Commit

El roadmap 1 (`docs/roadmap.md`) cierra lo que falta del juego tal como está planeado. Este roadmap 2.0 propone **mejoras de fondo**: lo que haría que el juego se sienta más profundo, más claro y más satisfactorio de jugar. Va por áreas y cada idea trae tamaño (**S** ≈ 1 sesión, **M** mediano, **L** grande) y prioridad (★★★ alta, ★★ media, ★ baja).

**Pilares** (lo que cada mejora debe reforzar):
1. **Cada build se siente distinta en las manos**, no solo en los números.
2. **Leer el combate de un vistazo**: qué te pega, qué está por estallar, qué hace tu build.
3. **El humor de programador** en todo: nombres, efectos, sonidos y textos.
4. **Pixel art coherente**: lo nuevo se dibuja en la rejilla de píxeles del filtro del mundo.

---

## 1. Jugabilidad (el bucle de combate)

| Mejora | Tamaño | Prioridad | Por qué |
|---|---|---|---|
| **Más eventos de zona**: hoy hay 4 (datos huérfanos, santuario, emboscada, deploy fallido); faltan eventos con mecánica propia (escoltar un proceso, desactivar bombas lógicas a tiempo, un comerciante ambulante) | M | ★★ | Variedad entre visitas. |
| **Filtro de botín, siguiente paso**: reglas por base, nivel y afijos (como los filtros de PoE), y resaltar bases buenas | M | ★★ | Ya hay 3 niveles, haz de luz y sonido por rareza. |
| **Esquiva, siguiente paso**: nodos y afijos con +cargas de esquiva o recarga más rápida, y RAM/ascendencias que hagan algo al esquivar (dejar una trampa, ganar una carga de Multihilos) | S | ★★ | La esquiva ya existe (Shift / RT, 2 cargas, stat `dodge_charges`). |
| **Escalado de dificultad por zona**: nivel de zona que sigue al del personaje en las zonas ya completadas (opcional) | M | ★ | Repetir zonas sin que se vuelvan triviales. |

## 2. Estilos de juego (builds)

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Cargas, siguiente paso**: nodos del árbol y de ascendencia que den cargas o las usen (p. ej. "+1 de Buffer máximo", "al gastar Overclock, recupera maná"), y habilidades propias que las consuman | M | ★★ | El sistema ya está (Buffer, Multihilos, Overclock; RAM que las gastan; afijos de objetos). |
| **Conversión de daño en el árbol**: nodos (o un nodo clave) que conviertan como las RAM nuevas, para toda la build y no solo una habilidad | S | ★★ | Las RAM de conversión ya existen (`convert_to` / `convert_from` en SkillCalc). |
| **Builds de "sacrificio", siguiente paso**: nodos que premien pagar con vida (más daño con vida baja, robo de vida extra) | S | ★★ | Ya hay RAM que pagan con vida (Alimentación por Vida, Hotfix en Caliente). |
| **Nodos clave de invocador**: "Monolito" (una sola invocación con ×3 vida y daño) frente a "Microservicios" (+2 invocaciones, −30 % cada una) en el árbol | M | ★★ | Ya existen el Mainframe Titán (una invocación con 3 habilidades) y la variante de tres golems. |
| **Builds de trampas y minas con detonación encadenada** | S | ★★ | Detonar una mina detona las vecinas: satisfactorio y legible. |
| **Totems/torretas que copian tu habilidad** (soporte "Contenedor Docker") | M | ★★ | Un estilo "pongo y me alejo" para cualquier habilidad. |
| **Hechizos canalizados** (mantener pulsado: rayo continuo, tormenta que crece) | M | ★★ | Hoy casi todo es de un toque; da variedad de ritmo. |

## 3. Habilidades y RAM (soportes)

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Habilidades de movimiento**: teletransporte corto (*ssh*), carga hacia el enemigo (*force push*), salto hacia atrás (*rollback*) | M | ★★★ | Complementan la esquiva y dan identidad a cada clase. |
| **Habilidades que dejan terreno**: charco de aceite que se enciende, campo de estática, zona helada; y **combos** entre ellas (fuego + aceite = explosión) | M | ★★★ | Aprovecha las interacciones de estados que ya existen. |
| **Gritos / buffs temporales** ("¡Está en producción!": +daño a aliados 6 s) | S | ★★ | Juego de equipo con invocaciones. |
| **RAM de activación** (*triggers*): "al recibir un golpe, lanza la habilidad", "al hacer crítico, lanza", "cada 2 s, lanza" | L | ★★★ | El tipo de soporte más divertido de PoE; da builds automáticas. |
| **Más variantes**: hoy hay variantes en 10 habilidades (`data/skills/variants.json`); faltan las de auras, drones y trampas | M | ★★ | Se eligen en K desde el nivel 10-15 de la placa. |
| **Comparador de placas**: ver dos placas lado a lado con DPS, coste y área | S | ★★ | Ya existe la comparación de DPS para RAM; ampliarla. |

## 4. Pasivas de tipos nuevos

| Tipo | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Nodos clave (keystones)**: cambian una regla del juego. Ejemplos: *Tipado estático* (no puedes ser crítico, pero tu daño nunca varía), *Recolector de basura* (al matar recuperas 2 % de maná, el maná no se regenera solo), *Modo seguro* (no puedes bajar del 1 de vida durante 2 s cada 30 s), *Código espagueti* (tus proyectiles rebotan al azar) | M | ★★★ | Lo que más define builds en un ARPG. |
| **Maestrías**: en cada sector del árbol, un nodo donde eliges 1 de 3 bonos (como las Masteries de PoE) | M | ★★★ | Más elección sin agrandar el árbol. |
| **Chips únicos que transforman nodos cercanos** ("los nodos de fuego de alrededor dan frío") y más ranuras en el árbol | M | ★★ | Los chips ya existen (12 ranuras, mágicos/raros/4 únicos). |
| **Nodos condicionales**: "si tienes 3 invocaciones", "si no te moviste en 1 s", "contra enemigos aturdidos", "si tu vida está llena" | S | ★★ | Recompensa jugar de cierta manera. |
| **Árbol de "deuda técnica"**: un pequeño árbol aparte, de fin de juego, donde cada nodo da un bono fuerte y una penalización | L | ★ | Endgame con riesgo y humor. |

## 5. Interfaz y experiencia

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Construcciones guardadas**: guardar y cargar combinaciones de árbol + barra de habilidades | M | ★★ | Probar builds sin rehacer todo. |
| **Navegación total con mando** en inventario, árbol, K, tienda y diálogos | L | ★★ | Ya está en el roadmap 1; aquí con cursor libre y atajos. |
| **Mapa grande (Tab)** superpuesto, con niebla de guerra y marcas | M | ★★ | Las zonas ahora son 1.4-1.5 veces más grandes. |
| **Tutorial contextual** de mecánicas nuevas (cargas, esquiva, golpes pesados, RAM de activación) la primera vez que aparecen | S | ★★ | |
| **Comparación con mando**: con dos anillos, comparar contra los dos; y un atajo para fijar la comparación | S | ★ | La comparación lado a lado ya existe con el ratón. |

## 6. Enemigos, jefes e IA

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Roles de enemigo claros**: tanque que protege, sanador que hay que matar primero, francotirador que se aleja, enjambre que rodea | M | ★★★ | Decisiones tácticas dentro de cada manada. |
| **Jefes con mecánicas de arena**: suelo que se rompe, adds que hay que interrumpir, zonas seguras que rotan | L | ★★★ | Con la esquiva y los avisos en el suelo. |
| **Enemigos que reaccionan a los estados**: huyen si se queman, se agrupan si hay un aura enemiga | M | ★★ | Más vida en las manadas. |
| **Némesis**: un raro que te mató reaparece más fuerte con tu nombre y suelta mejor botín | M | ★ | Historias emergentes. |

## 7. Sonido y música

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Materiales en los datos**: mover el material de cada enemigo a `enemies.json` y darle uno propio a cada tipo nuevo (hoy hay una tabla en `EnemyManager.MATERIALS`; lo que falta suena "digital") | S | ★ | Ya suenan carne, metal, cristal y digital al golpear. |
| **Capas de música por intensidad**: la pista de la zona sube una capa (batería) cuando hay más de 15 enemigos cerca, y baja al limpiar | M | ★★★ | Ya hay intensidad para jefes; extenderla. |
| **Ambiente posicional**: zumbido de racks que suena más cerca de ellos, goteo en las alcantarillas, viento en la grieta | S | ★★ | Las zonas grandes se sienten vivas. |
| **Voces cortas de los NPC** (gruñidos o frases de 1 palabra al hablar) y del personaje al subir de nivel o con poca vida | M | ★★ | |
| **Música compuesta** (sustituir las pistas generadas), con leitmotiv por acto y por jefe | L | ★★ | Ya en el roadmap 1. |

## 8. Efectos visuales y sensación

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Luces, siguiente paso**: que alumbren también las auras, las invocaciones con luz propia (láser del Titán, drones) y el botín único; y opción para bajar las luces si el equipo es lento | S | ★★ | Las luces dinámicas ya existen (hasta 32 en pantalla, `WorldPost.last_lights`). |
| **Sombras de proyectiles y de enemigos voladores** | S | ★ | Lectura de altura en vista cenital. |
| **Clima por zona**: lluvia de datos en la brecha, niebla que se mueve con el jugador en el pantano | S | ★ | |

## 9. Progresión y fin de juego

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Atlas de "incidentes"** (mapas de fin de juego): cada mapa es una zona aleatoria con modificadores (más enemigos, enemigos que explotan, sin regeneración) a cambio de más botín | L | ★★★ | El motor de juego de largo plazo. |
| **Crafteo con "parches"**: monedas que rehacen afijos, añaden uno, mejoran la rareza, fijan un afijo | M | ★★★ | Da uso a los tokens y al botín normal. |
| **Desafíos de temporada / logros** con cosméticos (sombreros, colores de aura, efectos de pasos) | M | ★★ | |
| **Ladder local**: récord de tiempo en las pruebas de estrés y en los jefes | S | ★ | |

## 10. Mundo, historia y personajes

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Diálogos con decisiones** que cambian recompensas o qué NPC te acompaña | M | ★★ | |
| **Lore coleccionable**: commits perdidos, logs y correos de la UAdeO repartidos por las zonas | S | ★★ | Las zonas grandes necesitan cosas que encontrar. |
| **Campamentos que evolucionan**: Aida, Mario y Rafa mejoran el campamento según avanzas (tienda nueva, mesa de crafteo) | M | ★★ | |

## 11. Accesibilidad y opciones

- **Daltonismo en todo** (ya hay modo para estados): rarezas del botín, auras, telegrafiados. (S, ★★★)
- **Texto más grande en el mundo** independiente de la interfaz. (S, ★★)
- **Reducir parpadeos y destellos** (fases de jefe, absorción del prólogo). (S, ★★)
- **Auto-ataque / mantener pulsado para mover** y modos de un solo botón. (S, ★)

## 12. Técnica

- **Pruebas de integración automáticas** de cada zona con cada clase durante 30 s (ya en el roadmap 1). (M, ★★★)
- **Rendimiento con 300+ enemigos**: lotes de barras de vida, `EnemyManager` en C# o GDExtension si hace falta. (M-L, ★★★)
- **Audio comprimido (OGG)** y **sprites en atlas**: menos peso y carga más rápida. (S, ★★)
- **Telemetría local de equilibrio**: registrar DPS, muertes y tiempo por zona en cada partida para ajustar con datos. (M, ★★)

---

## Plan sugerido por fases

1. **Fase "Sensación", lo que queda**: capas de música por intensidad, ambiente posicional.
2. **Fase "Habilidad del jugador"**: habilidades de movimiento, roles de enemigo, jefes con mecánicas de arena.
3. **Fase "Profundidad de builds"**: nodos clave, maestrías, RAM de activación, nodos que usen las cargas.
4. **Fase "Largo plazo"**: crafteo con parches, atlas de incidentes, chips únicos que transforman nodos, temporadas.

## Hecho del roadmap 2.0 (no repetir)

**Primera tanda (23 octubre 2026, noche 5)**: **texto y personajes nítidos** con el filtro: el pixelado solo va al suelo y el decorado; la luz (gradación, viñeta, oscuridad) va aparte y los nombres, placas, botín y números quedan encima · **eventos de zona**: datos huérfanos (dos oleadas y botín), santuarios (Turbo, Firewall, Debug, Overclock), emboscadas y deploys fallidos (dos raros), distintos en cada visita · **filtro de botín** (Todo / Ocultar normales / Solo raros y mejores; Alt para ver todo), **haz de luz** y sonido para raros y únicos · **cargas de Buffer, Multihilos y Overclock**: se ganan al recibir golpes, al matar y con críticos (más con afijos nuevos), duran 10 s, se ven sobre el orbe de vida y se gastan con RAM nuevas (Volcado de Buffer, Ráfaga Multihilo, Pico de Overclock) · **costo de vida**: RAM Alimentación por Vida (50 %) y Hotfix en Caliente (100 %, +35 % de daño) · **Mainframe Titán**: una sola invocación enorme con terremoto, láser y barrera; el golem gana terremoto · **variantes de habilidades** en K (golem de tres, golem blindado, titán de asedio o guardián, Broadcast/Unicast, Ping flood, Barrido amplio o certero, etc.) · **chips de expansión**: caen de los enemigos, se engastan en 12 ranuras hexagonales del árbol y cuentan con la ranura asignada; 4 únicos · **atributos**: +1 carga máxima de su tipo cada 50 y **requisitos de Fuerza/Destreza/Inteligencia** para armas y armaduras (la ropa de seda pide Inteligencia, el hacha Fuerza); sin ellos no se equipa y, si ya lo llevabas, se desactiva.

**Segunda tanda (24 octubre 2026)**: **esquiva "git stash"** (Shift o gatillo derecho; la hoja de personaje pasa a Share/Captura en el mando): salto corto con 0,3 s de invulnerabilidad contra golpes, charcos y estados, 2 cargas que se recargan cada 1,6 s, siluetas y casilla propia junto a la barra · **golpes pesados telegrafiados**: los raros y únicos cuerpo a cuerpo se paran, marcan un círculo rojo con "!" y pegan ×2,4; las novas de proyectiles de los jefes avisan con las líneas por donde saldrán · **hitstop** (crítico y muerte de raro o único, con opción en Pausa) y **retroceso** según el daño (las élites un tercio, los únicos nada) · **sacudida de cámara graduada** (golpes fuertes recibidos, críticos, muertes, jefes) con opción no / suave / normal · **raros con nombre generado y frase** al verte ("Off-by-one el Sin Tests": «Me arreglaron con un try vacío.») · **conversión de daño** con RAM (Transformador de Tensión físico → rayo, Nitrógeno Líquido físico → frío, Sobrecalentamiento frío/rayo → fuego, Corrupción de Datos elemental → caos; escalan con los dos tipos) · **RAM con desventaja fuerte** (Turbo sin Disipador, Compilación -O3, Memoria sin ECC) · **pociones con estilo**: Manzanilla con breakpoint (quita estados), Klub-Mate de emergencia (recarga esquivas y da una más), Termo de café para el equipo (cura invocaciones) · **comparación de objetos lado a lado** (el equipado junto al tooltip) · **barra de habilidades**: cuántas cargas gastaría cada habilidad y la conversión en su ayuda.

**Tercera tanda, fase "Sensación" (24 octubre 2026)**: **sonido por material** al golpear (carne, metal, cristal y digital, según el tipo de enemigo) y **crítico con clic de teclado mecánico** · **objeto único con fanfarria propia** al caer · **luces dinámicas en el filtro**: proyectiles de fuego, rayo, frío y caos (tuyos y enemigos), explosiones, destellos de golpes y muertes, salidas, waypoint y hoguera alumbran en escalones de pixel art; tiñen un poco en todas las zonas y mucho en las oscuras · **antorchas** (o LED de estado en servidores, BIOS y ROM, y fuegos fatuos en el pantano, la grieta y las alcantarillas) repartidas por las zonas oscuras · **partículas de impacto en pixel art** por tipo de daño (astillas y bits, chispas, esquirlas de hielo, chispazos, gotas verdes) · **muertes con estilo** según lo que mató al enemigo: se descompila en píxeles y bits, se quema a ceniza, se rompe en hielo, salta en chispas o se disuelve (también al morir por quemadura o veneno), cada una con su sonido. Sonidos nuevos con `generate_sfx.gd -- golpes`.
