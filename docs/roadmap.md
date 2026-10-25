# Roadmap unificado — Path Overflow: El Último Commit

Une el roadmap 1 (lo que faltaba del juego planeado) y el roadmap 2.0 (mejoras de fondo), sin lo ya hecho. Lo hecho antes de esta unificación está en `docs/roadmap_historial.md`.

Las tareas van **en orden de prioridad**: se hacen de arriba abajo, una por vez. Cada una cabe en una sesión de trabajo (las grandes están partidas en partes).

**Tamaño:** S ≈ 1 sesión · M mediana · L grande (partida en varias tareas). **Origen:** R1 = roadmap 1, R2 = roadmap 2.0 (★★★ alta, ★★ media, ★ baja).

**Pilares** (toda tarea debe reforzar al menos uno):
1. Cada build se siente distinta en las manos, no solo en los números.
2. Leer el combate de un vistazo.
3. El humor de programador en nombres, efectos, sonidos y textos.
4. Pixel art coherente: lo nuevo se dibuja en la rejilla de píxeles del filtro del mundo.

---

## Cómo se ejecuta (protocolo para Claude)

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` hecha · `[!]` bloqueada (con el motivo en la línea siguiente) · 🛑 = punto de revisión: al terminarla, **parar y esperar el visto bueno del usuario** antes de seguir.

1. **Elegir**: la primera tarea `[ ]` de la cola, de arriba abajo. Si hay una `[~]`, retomarla primero (quedó a medias).
2. **Marcar** `[~]` antes de empezar.
3. **Entender**: leer los archivos que cita la tarea, `README.md` y los docs relacionados (`docs/estilo.md`, `docs/lore.md`, `docs/habilidades_y_ram.md`). Seguir el estilo del código existente.
4. **Hacer** lo que dice la tarea, sin ampliar el alcance. Si aparece trabajo extra, añadirlo como tarea nueva en la fase que toque, no hacerlo ahora.
5. **Comprobar**: `powershell -File tools/run_checks.ps1` debe terminar con las tres en `[OK]` (scripts, lógica e integración). Mientras se itera, `-Rapida` acorta la integración; antes del commit, la completa (en segundo plano: tarda ~30 min). Añadir pruebas en `tests/test_core.gd` para la lógica nueva.
6. **Cerrar**: cambiar `[~]` por `[x]`, añadir una línea al **Registro** del final (fecha, ID, qué se hizo en una frase) y actualizar `README.md` si cambia algo visible para el jugador.
7. **Commit** con mensaje en español al estilo del repositorio (qué se añadió, en una línea). Sin push.
8. **Bloqueo**: si algo impide terminarla (falta una decisión, arte o una prueba que no se puede arreglar en la tarea), marcarla `[!]`, escribir el motivo debajo, revertir lo que quede roto y pasar a la siguiente.
9. **Seguir** con la siguiente tarea, salvo que la recién hecha sea 🛑 o el usuario haya pedido solo una.

Para encadenarlas sin intervención: `/siguiente-tarea` hace una; `/loop /siguiente-tarea` las va haciendo una tras otra hasta acabar la cola o llegar a un 🛑.

---

## Fase 0 — Base para trabajar en automático

### [x] T01 · Pruebas de integración por zona y clase · M
Origen: R1 §7, R2 §12 ★★★
- Script de prueba que cargue cada zona y simule 30 s de combate con cada una de las 7 clases (auto-movimiento y habilidades de la barra), sin ventana.
- Falla si aparece un `SCRIPT ERROR`, un error del motor o el jugador queda fuera de los límites de la zona.
- Documentar cómo correrla en `README.md` (sección *Pruebas y comprobaciones*) y en el paso 5 del protocolo.
- Hecho cuando: corre todas las zonas × clases en una sola orden y devuelve código de salida ≠ 0 si algo falla.

### [x] T02 · Guardado con copias de seguridad y varios espacios · M
Origen: R1 §7
- Copia automática del guardado antes de sobrescribir (rotación de 3) y recuperación si el archivo principal está corrupto.
- Varios espacios por perfil, elegibles en el menú de personajes.
- Hecho cuando: una prueba corrompe el guardado y el juego carga la copia.

### [x] T03 · Rendimiento con 300 enemigos en pantalla · M
Origen: R1 §1, R2 §12 ★★★
- Barras de vida e iconos de estado de enemigos en un MultiMesh o en un único `_draw` por lotes.
- Medir antes y después con `tools/capture_screens.tscn -- rendimiento` y anotar las cifras en `README.md` (*Rendimiento*).
- Objetivo: 300 enemigos ≥ 50 FPS (hoy ~32).
- Resultado: lo que cuestan los enemigos bajó ~30 % (48.7 → 38-42 ms con 300); el objetivo de 50 FPS depende de la zona y la interfaz y pasa a T03b.

### [x] T03b · Rendimiento: aligerar la zona y la interfaz · M
Origen: medición de T03
- Sin ningún enemigo el fotograma ya cuesta ~20 ms en 1600×900: ocultar la zona ahorra ~16 ms y la interfaz ~9 ms. Perfilar qué parte (suelo, decorado, filtro de pixel art, luces, minimapa, HUD) y cachear o simplificar lo que se redibuja cada fotograma.
- Medir con `capture_screens.tscn -- rendimiento` y actualizar la tabla del `README.md`.
- Objetivo: 300 enemigos ≥ 50 FPS en el benchmark (con T03 quedó en 24-26 FPS).

### [x] T04 · Ventanas grandes sin chocar con el minimapa · S
Origen: R1 §5
- A 160 % la hoja de personaje queda bajo el minimapa y las misiones: ocultarlos o desplazar la ventana mientras esté abierta.
- Revisar alijo, tienda y waypoints a 160 % en 900 px de alto (capturas con `capture_screens`).

---

## Fase 1 — Habilidad del jugador

### [x] T05 · Habilidades de movimiento · M
Origen: R2 §3 ★★★
- *ssh* (teletransporte corto), *force push* (carga hacia el enemigo), *rollback* (salto atrás).
- Repartidas por clase según su identidad; compatibles con las RAM que tengan sentido (área, velocidad, estados).
- Iconos propios y entrada en el catálogo (B).

### [x] T06 · Esquiva, siguiente paso · S
Origen: R2 §1 ★★
- Nodos y afijos de +cargas de esquiva y recarga más rápida.
- RAM o ascendencias que actúen al esquivar (dejar una trampa, ganar una carga de Multihilos).

### [x] T07 · Habilidades que dejan terreno y combos · M
Origen: R2 §3 ★★★
- Charco de aceite, campo de estática, zona helada.
- Combos entre terrenos y estados (fuego + aceite = explosión; rayo + charco helado, etc.) usando las interacciones de estados existentes.
- Legibles: cada terreno con su color/patrón (y patrón alternativo en modo daltónico).

### [x] T08 · Mecánicas de arena para jefes (parte 1: motor) · M
Origen: R2 §6 ★★★
- Sistema reutilizable de: suelo que se rompe (aviso → caída/daño), zonas seguras que rotan, adds que hay que interrumpir (canalizan un efecto si no se matan a tiempo).
- Avisos en el suelo consistentes con los golpes pesados telegrafiados.

### [x] T09 · Mecánicas de arena para jefes (parte 2: los tres jefes) · M
Origen: R2 §6 ★★★
- Aplicar al menos una mecánica de arena distinta por fase a los jefes de los actos I, II y III.
- Pruebas: cada fase activa su mecánica.

### [x] T10 · Tutorial contextual de mecánicas · S
Origen: R2 §5 ★★
- Aviso breve la primera vez que aparecen: cargas, esquiva, golpes pesados, terrenos, mecánicas de arena (y RAM de activación cuando existan).
- Se guarda qué se ha visto; opción en Pausa para desactivarlo.

---

## Fase 2 — Profundidad de builds

### [x] T11 · Nodos clave que cambian reglas · M
Origen: R2 §4 ★★★
- Los 7 keystones actuales del árbol solo dan stats. Añadir nodos clave que cambien una regla: *Tipado estático*, *Recolector de basura*, *Modo seguro*, *Código espagueti* (y los que encajen).
- Visibles en el árbol con su marco y buscables.

### [x] T12 · Maestrías · M
Origen: R2 §4 ★★★
- Un nodo por sector del árbol donde se elige 1 de 3 bonos; cambiable con reembolso.
- El generador y las pruebas del árbol siguen sin nodos encimados.

### [x] T13 · RAM de activación (parte 1: sistema) · M
Origen: R2 §3 ★★★
- Soporte que lanza la habilidad enlazada: "al recibir un golpe", "al hacer crítico".
- Con enfriamiento interno y coste de maná claro; sin bucles infinitos.

### [x] T14 · RAM de activación (parte 2: más disparadores e interfaz) · M
Origen: R2 §3 ★★★
- "Cada 2 s", "al esquivar", "al matar".
- Menú K y barra muestran qué dispara qué; `tools/audit_rams.gd` cubre las nuevas.
- Consejo de primera vez en `data/tips.json` (T10) al equipar la primera RAM de activación.

### [x] T15 · Cargas en el árbol, ascendencias y habilidades · M
Origen: R2 §2 ★★
- Nodos de "+1 de Buffer máximo", "al gastar Overclock, recupera maná", etc.
- Al menos una habilidad propia que consuma cargas.

### [x] T16 · Conversión de daño en el árbol · S
Origen: R2 §2 ★★
- Nodos (o un nodo clave) que conviertan daño para toda la build, reutilizando `convert_to` / `convert_from` de SkillCalc.

### [x] T17 · Nodos de sacrificio y condicionales · S
Origen: R2 §2, §4 ★★
- Sacrificio: más daño con vida baja, robo de vida extra.
- Condicionales: "si tienes 3 invocaciones", "si no te moviste en 1 s", "contra aturdidos", "con la vida llena".

### [ ] T18 · Nodos clave de invocador: Monolito y Microservicios · M
Origen: R2 §2 ★★
- *Monolito*: una sola invocación con ×3 vida y daño. *Microservicios*: +2 invocaciones, −30 % cada una.

### [ ] T19 · Minas con detonación encadenada · S
Origen: R2 §2 ★★
- Detonar una mina detona las vecinas, con retardo corto y efecto en cadena legible.

### [ ] T20 · Gritos y buffs temporales · S
Origen: R2 §3 ★★
- "¡Está en producción!" (+daño a aliados 6 s) y uno o dos más; afectan a invocaciones.

### [ ] T21 · Soporte "Contenedor Docker" (torreta que copia tu habilidad) · M
Origen: R2 §2 ★★
- RAM que convierte la habilidad en una torreta que la lanza sola; regla de compatibilidad y auditoría.

### [ ] T22 · Hechizos canalizados · M
Origen: R2 §2 ★★
- Mantener pulsado: rayo continuo, tormenta que crece. Coste por segundo; funciona con teclado y mando.

### [ ] T23 · Más variantes de habilidades · M
Origen: R2 §3 ★★
- Variantes para auras, drones y trampas en `data/skills/variants.json`.

### [ ] T24 · Más habilidades únicas de ascendencia · M
Origen: R1 §2
- Una propia por clase que aún no la tenga (p. ej. muro de fuego del Firewall, sprint del Scrum Master), escalando con el daño del personaje y no solo con el nivel.

### [ ] T25 · Chips únicos que transforman nodos cercanos · M
Origen: R2 §4 ★★
- "Los nodos de fuego alrededor dan frío" y similares; más ranuras si hace falta.

### [ ] T26 · Comparador de placas y construcciones guardadas · M
Origen: R2 §3, §5 ★★
- Dos placas lado a lado con DPS, coste y área.
- Guardar y cargar combinaciones de árbol + barra de habilidades.

---

## Fase 3 — Acto IV

### [ ] T27 · Diseño del acto IV · S 🛑
Origen: R1 §4, §8
- Documento en `docs/acto4.md` siguiendo `docs/lore.md` y `docs/estilo.md`: zonas, NPC, misiones, enemigos nuevos, jefe con fases y escenas.
- **Revisión del usuario antes de construirlo.**

### [ ] T28 · Acto IV: zonas, campamento y enemigos · M
- Zonas jugables con suelo en pixel art, ambiente, densidad y salidas; enemigos con afijos propios.

### [ ] T29 · Acto IV: NPC, misiones y diálogos · M
- Misiones principales del acto; diálogos validados por las pruebas de JSON.

### [ ] T30 · Acto IV: jefe con fases y escenas · M
- Jefe con fases, resistencias cambiantes, mecánica de arena (T08) y música de fase; escenas de entrada y cierre.

---

## Fase 4 — Enemigos y mundo

### [ ] T31 · Más eventos de zona · M
Origen: R2 §1 ★★
- Escoltar un proceso, desactivar bombas lógicas a tiempo, comerciante ambulante.

### [ ] T32 · Roles de enemigo, siguiente paso · S
Origen: R2 §6 ★★
- Sprites distintos para sanador y francotirador, roles en élites y afijo «Comandante».

### [ ] T33 · Enemigos que reaccionan a los estados · M
Origen: R2 §6 ★★
- Huyen si se queman, se agrupan con un aura enemiga, etc.

### [ ] T34 · Lore coleccionable · S
Origen: R2 §10 ★★
- Commits perdidos, logs y correos de la UAdeO por las zonas; registro para leerlos.

### [ ] T35 · Diálogos con decisiones · M
Origen: R2 §10 ★★
- Decisiones que cambian recompensas o qué NPC te acompaña.

### [ ] T36 · Campamentos que evolucionan · M
Origen: R2 §10 ★★
- Aida, Mario y Rafa mejoran el campamento al avanzar (tienda nueva, mesa de crafteo).

### [ ] T37 · Némesis · M
Origen: R2 §6 ★
- El raro que te mató reaparece más fuerte con tu nombre y mejor botín.

---

## Fase 5 — Fin de juego y progresión

### [ ] T38 · Crafteo con parches · M
Origen: R2 §9 ★★★
- Monedas que rehacen afijos, añaden uno, mejoran rareza y fijan un afijo. Encaja con la mesa de crafteo (T36).

### [ ] T39 · Atlas de incidentes (parte 1: mapas con modificadores) · M
Origen: R2 §9 ★★★
- Zona aleatoria con modificadores (más enemigos, explotan, sin regeneración) a cambio de más botín.

### [ ] T40 · Atlas de incidentes (parte 2: atlas y progresión) · M
Origen: R2 §9 ★★★
- Pantalla de atlas, desbloqueo de mapas, niveles y botín de mapas.

### [ ] T41 · Dificultades: normal, pesadilla, infierno · M
Origen: R1 §4
- Más afijos y resistencias por dificultad.

### [ ] T42 · Escalado opcional del nivel de zona · M
Origen: R2 §1 ★
- Zonas completadas que siguen el nivel del personaje (opción).

### [ ] T43 · Misiones secundarias con recompensas · M
Origen: R1 §4
- Recompensas de RAM de grado alto, placas de invocación y auras.

### [ ] T44 · Más únicos y conjuntos · M
Origen: R1 §4, §8
- Con efectos de estados, auras, espinas, autómatas, cargas y terrenos.

### [ ] T45 · Desafíos y logros con cosméticos · M
Origen: R2 §9 ★★
- Sombreros, colores de aura, efectos de pasos.

### [ ] T46 · Modo oleadas infinito y ladder local · M
Origen: R1 §4, R2 §9 ★
- Oleadas reutilizando las pruebas de estrés; récords de tiempo en oleadas y jefes.

### [ ] T47 · Árbol de deuda técnica · L
Origen: R2 §4 ★
- Árbol aparte de fin de juego: cada nodo, bono fuerte y penalización.

---

## Fase 6 — Interfaz, mando y accesibilidad

### [ ] T48 · Mando en menús (parte 1: inventario, K y tienda) · M
Origen: R1 §5, R2 §5 ★★
- Navegar sin ratón con cursor libre y atajos.

### [ ] T49 · Mando en menús (parte 2: árbol, diálogos y comparación) · M
Origen: R1 §5, R2 §5 ★★
- Incluye comparación contra los dos anillos y atajo para fijarla.

### [ ] T50 · Rebindear teclas y botones desde la pausa · M
Origen: R1 §5

### [ ] T51 · Accesibilidad: destellos, texto del mundo y daltonismo · S
Origen: R2 §11 ★★
- Reducir parpadeos y destellos (fases de jefe, absorción del prólogo).
- Texto del mundo con tamaño propio, independiente de la interfaz.
- Paletas alternativas para auras y cargas.

### [ ] T52 · Auto-ataque y mantener para mover · S
Origen: R2 §11 ★

### [ ] T53 · Mapa grande: marcas propias y zoom · S
Origen: R2 §5 ★

### [ ] T54 · Filtro de botín, siguiente paso · M
Origen: R2 §1 ★★
- Reglas por base, nivel de objeto y afijos; resaltar bases buenas; varios filtros con nombre.

---

## Fase 7 — Sensación y presentación

### [ ] T55 · Ambiente posicional · S
Origen: R2 §7 ★★
- Zumbido de racks cerca de ellos, goteo en alcantarillas, viento en la grieta.

### [ ] T56 · Voces cortas · M
Origen: R2 §7 ★★
- Gruñidos o palabras sueltas de los NPC al hablar; voz del personaje al subir de nivel o con poca vida.

### [ ] T57 · Materiales de enemigos en los datos · S
Origen: R2 §7 ★
- Mover `EnemyManager.MATERIALS` a `enemies.json` y dar material propio a cada tipo.

### [ ] T58 · Luces, sombras y clima · S
Origen: R2 §8 ★★/★
- Luz en auras, invocaciones con luz propia y botín único; opción para bajar luces.
- Sombras de proyectiles y voladores; lluvia de datos y niebla del pantano.

### [ ] T59 · Obstáculos en pixel art: acto I · M
Origen: R1 §4
- Árboles de cables, rocas, lápidas... con sombra y luz como el suelo.

### [ ] T60 · Obstáculos en pixel art: actos II y III · M
Origen: R1 §4

### [ ] T61 · Prólogo en pixel art: pasillo y oficina · M
Origen: R1 §5
- Mismo nivel de detalle que la calle (luz, tramado, sombras).

### [ ] T62 · Música para las pruebas de estrés · S
Origen: R1 §6
- Con `tools/generate_zone_music.gd`.

---

## Fase 8 — Técnica

### [ ] T63 · Audio en OGG y sprites en atlas · S
Origen: R1 §6, R2 §12 ★★
- Los .wav suman ~60 MB; los bucles de `data/music_loops.json` deben seguir cuadrando.

### [ ] T64 · Telemetría local de equilibrio · M
Origen: R2 §12 ★★
- Registrar DPS, muertes y tiempo por zona en cada partida (archivo local) y una herramienta que lo resuma.

### [ ] T65 · Exportación a Linux y macOS e instalador de Windows · S
Origen: R1 §7

### [ ] T66 · `EnemyManager` en C# o GDExtension · L — solo si hace falta
Origen: R1 §7, R2 §12
- Hacerla solo si tras T03 la simulación pasa de 4 ms con estados y aliados; si no, marcar `[x]` con la medición como motivo.
- Tras T03 y T03b: 150 enemigos a 60 FPS y 300 a 32-34 FPS en el benchmark; con 300 la simulación ya da ~4.5 ms y el `_draw` de enemigos ~7 ms (los dos en GDScript), y la interfaz ~8 ms. Si se quiere 300 ≥ 50 FPS, empezar por aquí y por cachear en texturas los iconos del HUD.

---

### [ ] T67 · Investigar un cierre sin traza en la integración · S
Origen: comprobaciones de T16
- El 25-10-2026, entre las 00:56 y las 00:58, Godot se cerró 4 veces sin ningún mensaje (código de salida -1, sin evento de Windows) jugando el Tester QA en el acto III (Oblea / Memoria ROM). Después, 0 de 19 pasadas fallaron, y 0 de 6 en el commit 1a91bf1.
- Probar varias decenas de pasadas de esa clase y zonas (con y sin `--verbose`), revisar hilos (FreezeWatch, el `Logger` de la prueba) y, si vuelve a pasar, sacar la traza con el ejecutable de consola o un volcado.

---

## Fuera de la cola (necesitan una persona)

No las ejecuta Claude solo; quedan aquí para no perderlas.

- **Equilibrar con partidas reales**: cada clase hasta nivel 30 con sus dos ascendencias; Multicanal, Pipeline Superescalar (la mayor sigue siendo la mejor RAM de daño), Sobrealimentación, Enlace de Aura, auras con alcance, afijos y fases de subjefes; árboles de ascendencia hasta nivel 60; densidad de enemigos por zona. Con T64 se puede ajustar con datos.
- **Arte final**: personajes, NPC, invocaciones, iconos de habilidad y estado, sprites del acto III, retratos más expresivos. Necesita artista.
- **Música compuesta** con leitmotiv por acto y jefe (se puede escribir en `music.json` → `melody` o en `melody_file`).
- **Campamento III**: si `data/music/camp3_eptns.json` transcribe una canción con derechos, cambiarla antes de publicar.
- **Cliente/servidor para cooperativo** (largo plazo): aislar `SkillController` y `EnemyManager` de `Node2D`.

---

## Registro

<!-- Una línea por tarea terminada: AAAA-MM-DD · TXX · qué se hizo -->
- 2026-10-24 · T01 · Prueba de integración (`tests/test_integration.tscn`): 7 clases × 24 zonas, 30 s de combate con piloto automático, falla con cualquier error del motor, pausa atascada, jugador fuera de la zona o sin combate; `tools/run_checks.ps1` corre todo. Encontró y arregló un Tween vacío de la música en las arenas de jefe.
- 2026-10-24 · T02 · Guardado con tres copias rotativas (`.bak`..`.bak3`), recuperación desde la copia legible más reciente (también si falta el principal), copia y recuperación del alijo, y tres espacios de guardado con sus personajes y alijo, elegibles en el menú de personajes.
- 2026-10-24 · T03 · Barras, estados, halos, aturdidos, insignias de rol y avisos de los enemigos en un solo arreglo de triángulos y sin avisos fuera de cámara: 300 enemigos de 48.7 a 38-42 ms; el benchmark ya no mide en pausa. Lo que falta para 50 FPS (zona e interfaz) pasa a T03b.
- 2026-10-24 · T03b · La zona solo dibuja obstáculos, antorchas, props, salidas y objetos en cámara: sin enemigos de ~20 a ~13 ms, 150 enemigos a 60 FPS y 300 a 32-34 FPS. El objetivo de 300 ≥ 50 FPS no se alcanzó: lo que queda (simulación y `_draw` de enemigos en GDScript, interfaz) se anota en T66.
- 2026-10-24 · T04 · El minimapa y el registro de misiones se ocultan si cualquier ventana abierta se les encima (comprobado por rectángulos cada fotograma); el alijo y la tienda se encogen junto al inventario cuando no caben a 160 %; captura `ventanas160`.
- 2026-10-24 · T05 · Habilidades de movimiento Túnel SSH (teletransporte con descarga), Force Push (carga con empuje y aturdimiento) y Git Revert (salto atrás con zona helada), desbloqueadas al nivel 8 según la clase, con icono, sonido y entrada en el catálogo; los teletransportes ya no caen en paredes ni obstáculos.
- 2026-10-24 · T06 · Esquiva: stats de recarga más rápida, Multihilos al esquivar y explosión *git stash pop* (% de la vida como fuego); afijos de objetos (recarga, +1 carga, Multihilos, explosión), chip de recarga, dos notables de Movilidad (+1 carga, +20 % de recarga) y tres de ascendencia (Campeón del Sprint, Saboteadora, Francotiradora).
- 2026-10-24 · T07 · Terrenos Derrame de Aceite, Campo de Estática y Charco de Refrigerante con combos (aceite + fuego = explosión y suelo en llamas; estática + refrigerante = superconductor), color y textura propios y patrón daltónico; captura `terrenos`. De paso, los ticks con escala ya respetan el tipo de daño (resistencias).
- 2026-10-24 · T08 · Motor de mecánicas de arena para jefes: `floor_break` (losas que se rompen y dejan agujero), `safe_zones` (zonas seguras que giran) y `channel_adds` (adds que curan, escudan o hacen nova si no se interrumpen), con avisos legibles y modo daltónico; captura `arena`. Además, `test_core` falla si hay un SCRIPT ERROR (antes podía pasar en silencio).
- 2026-10-24 · T09 · Una mecánica de arena distinta por fase en los tres jefes (Arquitecto, init, fw_update.exe), con pruebas de que cada fase la tiene y de que se activa; las zonas seguras cubren toda la arena y su centro se escala con la zona.
- 2026-10-24 · T10 · Consejos de primera vez (`TipPanel`, `data/tips.json`) para esquiva, cargas, golpes pesados, terrenos y las tres mecánicas de arena; vistos por personaje y opción en Pausa. Las RAM de activación (T13-T14) tendrán que añadir el suyo.
- 2026-10-24 · T11 · Cuatro nodos clave que cambian reglas (Tipado Estático, Recolector de Basura, Modo Seguro, Código Espagueti) en el lugar de cuatro de los que solo daban stats, sin cambiar la estructura del árbol (no hay reembolso); el generador también los usa y los tooltips los describen como frase.
- 2026-10-24 · T12 · Siete maestrías (una por sector) donde se elige 1 de 3 bonos, gratis y cambiable; guardadas con el personaje, con rombos en el árbol, tooltip y búsqueda; sin cambiar la estructura del árbol. De paso, una prueba de T08 que dependía de la evasión al azar ya no falla de vez en cuando, y la integración encontró un fallo antiguo: si el jefe moría por un degenerativo, World vaciaba las listas de enemigos en mitad del bucle (ahora se vacían al final del fotograma).
- 2026-10-24 · T13 · RAM de activación Manejador de Excepciones (al recibir un golpe) y Breakpoint Condicional (al hacer crítico): la habilidad se lanza sola, paga su maná, tiene enfriamiento interno, se resuelve al fotograma siguiente y sus propios críticos no activan nada.
- 2026-10-24 · T14 · RAM Cron Job (cada 2 s), Hook pre-stash (al esquivar) y Callback onKill() (al matar); «AUTO» y enfriamiento en la barra, la activación en la ayuda, en K y en la descripción de la RAM, y su consejo de primera vez. `tools/audit_rams.gd` ya mira las mismas claves que la prueba (antes daba 96 falsos «sin efecto»).
- 2026-10-25 · T15 · Cargas en el árbol (cuatro notables: +1 de cada carga máxima y maná al gastarlas), en tres ascendencias y en la habilidad Core Dump, que gasta las tres; stat nuevo `charge_spend_mana`.
- 2026-10-25 · T16 · Conversión de daño desde el árbol para toda la build (físico → rayo, físico → fuego, elemental → caos) en tres notables, con la misma lógica que las RAM de conversión; si una RAM ya convierte, manda la RAM.
- 2026-10-25 · T17 · Condiciones nuevas «con 3 o más aliados» y «si no te has movido en 1 s», daño contra aturdidos o congelados, y seis notables de sacrificio y condicionales (vida baja, vida llena, 3 aliados, quieto, aturdidos).
