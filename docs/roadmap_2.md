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
| **Esquiva / "git stash"**: un salto corto con invulnerabilidad breve (Espacio o B en el mando), con su propio enfriamiento y un pequeño gasto de energía | M | ★★★ | Hoy defenderse es solo vida y pociones; la esquiva da habilidad al jugador y permite jefes con ataques telegrafiados de verdad. |
| **Ataques enemigos telegrafiados**: zonas rojas en el suelo antes de los golpes fuertes de raros, únicos y jefes (ya hay carga y embestida; falta el aviso en el suelo) | M | ★★★ | Junto con la esquiva, convierte las peleas de jefe en peleas de reflejos, no de vida. |
| **Hitstop y retroceso**: 2-4 fotogramas de pausa al dar un crítico o matar a un raro, y empujón a los enemigos golpeados | S | ★★★ | El "peso" del golpe es lo que más mejora la sensación sin cambiar números. |
| **Eventos en las zonas**: emboscadas, cofres de "datos huérfanos" con oleada, santuarios temporales (más daño, más velocidad), "deploy fallido" que hace aparecer élites | M | ★★ | Las zonas más grandes necesitan sorpresas, no solo más manadas. |
| **Botín más legible**: rayo de luz del color de la rareza al caer un raro/único, sonido propio por rareza, filtro de botín configurable (ocultar normales, resaltar bases) | M | ★★★ | Con 200 enemigos por zona, el botín se vuelve ruido sin filtro. |
| **Pociones con estilo**: pociones que quitan estados, que dan carga de esquiva, que curan a las invocaciones | S | ★★ | Más decisiones en el cinturón (1-5). |
| **Escalado de dificultad por zona**: nivel de zona que sigue al del personaje en las zonas ya completadas (opcional) | M | ★ | Repetir zonas sin que se vuelvan triviales. |

## 2. Estilos de juego (builds)

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Cargas** (como las de PoE): *Cafeína* (velocidad), *Contexto* (daño crítico), *Uptime* (defensa). Se ganan con habilidades, nodos o al matar, y se gastan con habilidades que las consumen | L | ★★★ | Un sistema transversal que crea builds nuevas: "gasto todas mis cargas en un golpe". |
| **Conversión de daño**: nodos/RAM que convierten físico → rayo, fuego → caos, etc. | M | ★★★ | Permite builds temáticas (un Guerrero eléctrico) sin habilidades nuevas. |
| **Builds de "sacrificio"**: habilidades que gastan vida en vez de maná (Hotfix en caliente), con nodos que lo premian | M | ★★ | Encaja con el Ingeniero de Guardia y su "logs en rojo". |
| **Builds de invocación masiva vs. invocación única**: un nodo clave "Monolito" (una sola invocación con ×3 vida y daño) frente a "Microservicios" (+2 invocaciones, −30 % cada una) | M | ★★★ | Dos formas claras de jugar invocador. |
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
| **RAM con desventaja fuerte** (más 60 % de daño pero las habilidades cuestan vida, etc.) | S | ★★ | Decisiones con riesgo. |
| **Evolución de habilidades al nivel 20 de la placa**: una variante alternativa (p. ej. el Golem se divide en tres pequeños) | L | ★★ | Recompensa subir placas y da metas a largo plazo. |
| **Comparador de placas**: ver dos placas lado a lado con DPS, coste y área | S | ★★ | Ya existe la comparación de DPS para RAM; ampliarla. |

## 4. Pasivas de tipos nuevos

| Tipo | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Nodos clave (keystones)**: cambian una regla del juego. Ejemplos: *Tipado estático* (no puedes ser crítico, pero tu daño nunca varía), *Recolector de basura* (al matar recuperas 2 % de maná, el maná no se regenera solo), *Modo seguro* (no puedes bajar del 1 de vida durante 2 s cada 30 s), *Código espagueti* (tus proyectiles rebotan al azar) | M | ★★★ | Lo que más define builds en un ARPG. |
| **Maestrías**: en cada sector del árbol, un nodo donde eliges 1 de 3 bonos (como las Masteries de PoE) | M | ★★★ | Más elección sin agrandar el árbol. |
| **Chips de expansión** (equivalente a las joyas): objetos que se engastan en ranuras del árbol, con afijos propios y únicos que transforman los nodos cercanos ("los nodos de fuego de alrededor dan frío") | L | ★★ | Botín nuevo que interactúa con el árbol. |
| **Nodos condicionales**: "si tienes 3 invocaciones", "si no te moviste en 1 s", "contra enemigos aturdidos", "si tu vida está llena" | S | ★★ | Recompensa jugar de cierta manera. |
| **Pasivas de atributo con umbral**: cada 50 de Fuerza = +1 carga máxima, cada 50 de Inteligencia = +1 RAM activa | S | ★★ | Hace interesante invertir en atributos. |
| **Árbol de "deuda técnica"**: un pequeño árbol aparte, de fin de juego, donde cada nodo da un bono fuerte y una penalización | L | ★ | Endgame con riesgo y humor. |

## 5. Interfaz y experiencia

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Números de daño legibles con el filtro de pixel art**: dibujarlos en la capa de interfaz (no en el mundo) con fuente de píxel y colores por tipo, y apilarlos | S | ★★★ | Hoy el filtro los pixela y pierden nitidez. Igual con los nombres de NPC y puertas. |
| **Barra de habilidades con información**: enfriamiento en reloj, cargas, coste de maná en rojo si no alcanza | S | ★★★ | Leer el estado de la build sin abrir menús. |
| **Panel de estado del personaje en combate**: iconos de bonos activos (auras, cargas, pociones, santuarios) con duración | S | ★★★ | Ya hay estados sobre el jugador; faltan los buenos. |
| **Ventana de comparación de objetos** al pasar sobre uno de la bolsa (mostrar el equipado al lado, con diferencias en verde y rojo) | M | ★★★ | Lo más usado en un ARPG. |
| **Construcciones guardadas**: guardar y cargar combinaciones de árbol + barra de habilidades | M | ★★ | Probar builds sin rehacer todo. |
| **Navegación total con mando** en inventario, árbol, K, tienda y diálogos | L | ★★ | Ya está en el roadmap 1; aquí con cursor libre y atajos. |
| **Mapa grande (Tab)** superpuesto, con niebla de guerra y marcas | M | ★★ | Las zonas ahora son 1.4-1.5 veces más grandes. |
| **Tutorial contextual** de mecánicas nuevas (cargas, esquiva, RAM de activación) la primera vez que aparecen | S | ★★ | |

## 6. Enemigos, jefes e IA

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Roles de enemigo claros**: tanque que protege, sanador que hay que matar primero, francotirador que se aleja, enjambre que rodea | M | ★★★ | Decisiones tácticas dentro de cada manada. |
| **Jefes con mecánicas de arena**: suelo que se rompe, adds que hay que interrumpir, zonas seguras que rotan | L | ★★★ | Con la esquiva y los avisos en el suelo. |
| **Enemigos que reaccionan a los estados**: huyen si se queman, se agrupan si hay un aura enemiga | M | ★★ | Más vida en las manadas. |
| **Raros con nombre generado y frase** ("Excepción no controlada de Juan", "Null Pointer el Breve") | S | ★★ | Humor y reconocimiento. |
| **Némesis**: un raro que te mató reaparece más fuerte con tu nombre y suelta mejor botín | M | ★ | Historias emergentes. |

## 7. Sonido y música

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Sonido por tipo de daño y por material**: golpe en metal (racks), en carne, en cristal (ROM); crítico con un "clic" de teclado mecánico | M | ★★★ | El audio es la mitad de la sensación de golpe. |
| **Capas de música por intensidad**: la pista de la zona sube una capa (batería) cuando hay más de 15 enemigos cerca, y baja al limpiar | M | ★★★ | Ya hay intensidad para jefes; extenderla. |
| **Ambiente posicional**: zumbido de racks que suena más cerca de ellos, goteo en las alcantarillas, viento en la grieta | S | ★★ | Las zonas grandes se sienten vivas. |
| **Voces cortas de los NPC** (gruñidos o frases de 1 palabra al hablar) y del personaje al subir de nivel o con poca vida | M | ★★ | |
| **Sonido de botín por rareza** y de "objeto único" inconfundible | S | ★★★ | Ver sección 1. |
| **Música compuesta** (sustituir las pistas generadas), con leitmotiv por acto y por jefe | L | ★★ | Ya en el roadmap 1. |

## 8. Efectos visuales y sensación

| Mejora | Tamaño | Prioridad | Idea |
|---|---|---|---|
| **Luces dinámicas en el filtro**: proyectiles de fuego y rayos que iluminan en zonas oscuras (catacumbas, alcantarillas), antorchas en las paredes | M | ★★★ | Aprovecha la oscuridad del filtro de pixel art: el combate ilumina la zona. |
| **Partículas de impacto en pixel art** por tipo de daño (chispas, astillas de hielo, gotas de veneno, bits) | M | ★★★ | |
| **Muertes con estilo**: los enemigos se "descompilan" en píxeles, se congelan y se rompen, se queman a ceniza según el daño que los mató | M | ★★ | Ya existe la explosión de afijos; esto da variedad. |
| **Sacudida de cámara graduada** y una opción para reducirla | S | ★★ | Accesibilidad y sensación. |
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

1. **Fase "Sensación"** (★★★ rápidas): hitstop, números de daño en la interfaz, sonido por material y rareza, luces dinámicas, filtro de botín.
2. **Fase "Habilidad del jugador"**: esquiva, telegrafiados en el suelo, habilidades de movimiento, roles de enemigo.
3. **Fase "Profundidad de builds"**: cargas, conversión de daño, nodos clave, maestrías, RAM de activación.
4. **Fase "Largo plazo"**: crafteo con parches, atlas de incidentes, chips de expansión, temporadas.
