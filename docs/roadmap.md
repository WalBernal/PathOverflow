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
5. **Comprobar**: `powershell -File tools/run_checks.ps1 -Rapida` debe terminar con las tres en `[OK]` (scripts, lógica e integración de 5 s por zona, ~5 min). Si la tarea cambia zonas, enemigos o jefes concretos, además la integración a fondo solo en ellos: `-Zonas id1,id2` (30 s por zona). La completa de 30 s en todo (~30 min) ya no se corre en cada tarea: el usuario prefiere pruebas cortas. Añadir pruebas en `tests/test_core.gd` para la lógica nueva.
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

### [x] T18 · Nodos clave de invocador: Monolito y Microservicios · M
Origen: R2 §2 ★★
- *Monolito*: una sola invocación con ×3 vida y daño. *Microservicios*: +2 invocaciones, −30 % cada una.

### [x] T19 · Minas con detonación encadenada · S
Origen: R2 §2 ★★
- Detonar una mina detona las vecinas, con retardo corto y efecto en cadena legible.

### [x] T20 · Gritos y buffs temporales · S
Origen: R2 §3 ★★
- "¡Está en producción!" (+daño a aliados 6 s) y uno o dos más; afectan a invocaciones.

### [x] T21 · Soporte "Contenedor Docker" (torreta que copia tu habilidad) · M
Origen: R2 §2 ★★
- RAM que convierte la habilidad en una torreta que la lanza sola; regla de compatibilidad y auditoría.

### [x] T22 · Hechizos canalizados · M
Origen: R2 §2 ★★
- Mantener pulsado: rayo continuo, tormenta que crece. Coste por segundo; funciona con teclado y mando.

### [x] T23 · Más variantes de habilidades · M
Origen: R2 §3 ★★
- Variantes para auras, drones y trampas en `data/skills/variants.json`.

### [x] T24 · Más habilidades únicas de ascendencia · M
Origen: R1 §2
- Una propia por clase que aún no la tenga (p. ej. muro de fuego del Firewall, sprint del Scrum Master), escalando con el daño del personaje y no solo con el nivel.

### [x] T25 · Chips únicos que transforman nodos cercanos · M
Origen: R2 §4 ★★
- "Los nodos de fuego alrededor dan frío" y similares; más ranuras si hace falta.

### [x] T26 · Comparador de placas y construcciones guardadas · M
Origen: R2 §3, §5 ★★
- Dos placas lado a lado con DPS, coste y área.
- Guardar y cargar combinaciones de árbol + barra de habilidades.

---

## Fase 3 — Acto IV

### [x] T27 · Diseño del acto IV · S 🛑
Origen: R1 §4, §8
- Documento en `docs/acto4.md` siguiendo `docs/lore.md` y `docs/estilo.md`: zonas, NPC, misiones, enemigos nuevos, jefe con fases y escenas.
- **Revisión del usuario antes de construirlo.** Aprobado el 2026-10-25, con las respuestas a las preguntas abiertas al final de `docs/acto4.md`: El Pepe no aparece hasta el Acto V (solo se le menciona), la contraseña se guarda, la decisión sobre los huérfanos va en este acto, Mario acompaña a Rafa al hub, las zonas se bifurcan y la historia sigue en el Acto V; el nombre se queda.

### [x] T28 · Acto IV: zonas, campamento y enemigos · M
- Zonas jugables con suelo en pixel art, ambiente, densidad y salidas; enemigos con afijos propios.
- Según `docs/acto4.md`: estilos `setup` y `vga16`, hub La Pila del CMOS, **zonas bifurcadas** (dos caminos que se separan y se vuelven a unir antes del jefe).

### [x] T29 · Acto IV: NPC, misiones y diálogos · M
- Misiones principales del acto; diálogos validados por las pruebas de JSON.
- Berta, Rafa en persona y **Mario** (obligado por ser prestador de servicio) en el hub; El Pepe solo mencionado. **Decisión sobre los huérfanos del Sindicato** (reiniciar con ellos o sin ellos) guardada en un flag para el Acto V.

### [x] T30 · Acto IV: jefe con fases y escenas · M
- Jefe con fases, resistencias cambiantes, mecánica de arena (T08) y música de fase; escenas de entrada y cierre.
- La contraseña que escribe el jugador al final **se guarda** con el personaje (para el Acto V).

---

## Fase 4 — Enemigos y mundo

### [x] T31 · Más eventos de zona · M
Origen: R2 §1 ★★
- Escoltar un proceso, desactivar bombas lógicas a tiempo, comerciante ambulante.

### [x] T32 · Roles de enemigo, siguiente paso · S
Origen: R2 §6 ★★
- Sprites distintos para sanador y francotirador, roles en élites y afijo «Comandante».

### [x] T33 · Enemigos que reaccionan a los estados · M
Origen: R2 §6 ★★
- Huyen si se queman, se agrupan con un aura enemiga, etc.

### [x] T34 · Lore coleccionable · S
Origen: R2 §10 ★★
- Commits perdidos, logs y correos de la UAdeO por las zonas; registro para leerlos.

### [x] T35 · Diálogos con decisiones · M
Origen: R2 §10 ★★
- Decisiones que cambian recompensas o qué NPC te acompaña.

### [x] T36 · Campamentos que evolucionan · M
Origen: R2 §10 ★★
- Aida, Mario y Rafa mejoran el campamento al avanzar (tienda nueva, mesa de crafteo).

### [x] T37 · Némesis · M
Origen: R2 §6 ★
- El raro que te mató reaparece más fuerte con tu nombre y mejor botín.

---

## Fase 5 — Fin de juego y progresión

### [x] T38 · Crafteo con parches · M
Origen: R2 §9 ★★★
- Monedas que rehacen afijos, añaden uno, mejoran rareza y fijan un afijo. Encaja con la mesa de crafteo (T36).

### [x] T39 · Atlas de incidentes (parte 1: mapas con modificadores) · M
Origen: R2 §9 ★★★
- Zona aleatoria con modificadores (más enemigos, explotan, sin regeneración) a cambio de más botín.

### [x] T40 · Atlas de incidentes (parte 2: atlas y progresión) · M
Origen: R2 §9 ★★★
- Pantalla de atlas, desbloqueo de mapas, niveles y botín de mapas.

### [x] T41 · Dificultades: normal, pesadilla, infierno · M
Origen: R1 §4
- Más afijos y resistencias por dificultad.

### [x] T42 · Escalado opcional del nivel de zona · M
Origen: R2 §1 ★
- Zonas completadas que siguen el nivel del personaje (opción).

### [x] T43 · Misiones secundarias con recompensas · M
Origen: R1 §4
- Recompensas de RAM de grado alto, placas de invocación y auras.

### [x] T44 · Más únicos y conjuntos · M
Origen: R1 §4, §8
- Con efectos de estados, auras, espinas, autómatas, cargas y terrenos.

### [x] T45 · Desafíos y logros con cosméticos · M
Origen: R2 §9 ★★
- Sombreros, colores de aura, efectos de pasos.

### [x] T46 · Modo oleadas infinito y ladder local · M
Origen: R1 §4, R2 §9 ★
- Oleadas reutilizando las pruebas de estrés; récords de tiempo en oleadas y jefes.

### [x] T47 · Árbol de deuda técnica · L
Origen: R2 §4 ★
- Árbol aparte de fin de juego: cada nodo, bono fuerte y penalización.

---

## Fase 6 — Interfaz, mando y accesibilidad

### [x] T48 · Mando en menús (parte 1: inventario, K y tienda) · M
Origen: R1 §5, R2 §5 ★★
- Navegar sin ratón con cursor libre y atajos.

### [x] T49 · Mando en menús (parte 2: árbol, diálogos y comparación) · M
Origen: R1 §5, R2 §5 ★★
- Incluye comparación contra los dos anillos y atajo para fijarla.

### [x] T50 · Rebindear teclas y botones desde la pausa · M
Origen: R1 §5

### [x] T51 · Accesibilidad: destellos, texto del mundo y daltonismo · S
Origen: R2 §11 ★★
- Reducir parpadeos y destellos (fases de jefe, absorción del prólogo).
- Texto del mundo con tamaño propio, independiente de la interfaz.
- Paletas alternativas para auras y cargas.

### [x] T52 · Auto-ataque y mantener para mover · S
Origen: R2 §11 ★

### [x] T53 · Mapa grande: marcas propias y zoom · S
Origen: R2 §5 ★

### [x] T54 · Filtro de botín, siguiente paso · M
Origen: R2 §1 ★★
- Reglas por base, nivel de objeto y afijos; resaltar bases buenas; varios filtros con nombre.

---

## Fase 7 — Sensación y presentación

### [x] T55 · Ambiente posicional · S
Origen: R2 §7 ★★
- Zumbido de racks cerca de ellos, goteo en alcantarillas, viento en la grieta.

### [x] T56 · Voces cortas · M
Origen: R2 §7 ★★
- Gruñidos o palabras sueltas de los NPC al hablar; voz del personaje al subir de nivel o con poca vida.

### [x] T57 · Materiales de enemigos en los datos · S
Origen: R2 §7 ★
- Mover `EnemyManager.MATERIALS` a `enemies.json` y dar material propio a cada tipo.

### [x] T58 · Luces, sombras y clima · S
Origen: R2 §8 ★★/★
- Luz en auras, invocaciones con luz propia y botín único; opción para bajar luces.
- Sombras de proyectiles y voladores; lluvia de datos y niebla del pantano.

### [x] T59 · Obstáculos en pixel art: acto I · M
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
- El 25-10-2026 entre las 08:00 y las 08:40 (durante T28) volvió: 6 de 8 pasadas de la integración rápida completa se cerraron igual (código -1, sin salida ni evento), en zonas distintas de los actos I a III y también **sin cargar el Acto IV**. Nunca en tandas cortas (una clase o pocas zonas: 0 de 8). Memoria, handles e hilos del proceso estables durante la pasada; el sistema tenía 1,6 GB de RAM libre y otra instancia de Godot grabando vídeo. Sospecha: depende de la carga de la máquina o de algo que se acumula entre mundos (la prueba crea y libera un `World` por clase y acto).

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
- 2026-10-25 · T18 · Nodos clave Monolito (una sola invocación persistente, ×3 de vida y daño) y Microservicios (+2 a la vez, −30 % cada una), en el lugar de Hola Mundo en 40 Lenguajes y Orquestación con Kubernetes (sin reembolso del árbol); el generador también los usa.
- 2026-10-25 · T19 · Detonación en cadena de trampas y minas: al estallar una, las armadas a 170 px o menos estallan 0,12 s después (rayo naranja entre ellas, apuntan al enemigo más cercano) y siguen la cadena; la cuenta atrás no avanza en el mismo fotograma en que se marcó.
- 2026-10-25 · T20 · Tres gritos (etiqueta `warcry`): ¡Está en producción! (daño propio y de esbirros, velocidad de autómatas), ¡Daily en cinco minutos! (velocidades) y ¡Rollback! (cura a las invocaciones, armadura y vida de esbirros), 6 s; onda grande y destello en cada aliado, iconos de megáfono propios.
- 2026-10-25 · T21 · RAM Contenedor Docker (DDR4): la habilidad pasa a un contenedor que no caduca y la lanza solo (−35 % de daño), reserva un 20 % del maná, uno por habilidad (relanzarla lo mueve), cuenta como torreta persistente, sigue a su placa y libera el maná si lo destruyen o al cambiar de zona; mismas exclusiones que la torreta, auditoría sin RAM sin efecto.
- 2026-10-25 · T22 · Hechizos canalizados (tipos `channel_beam` y `channel_storm`, etiqueta `channel`): Pipe de Datos (rayo continuo) y Tormenta de Tickets (crece ×3 de tamaño y ×2 de daño en 3 s y sigue al cursor); maná por segundo mientras se mantiene la tecla o el botón, sin moverse, se cortan al soltar o sin maná; tooltips con maná/s; excluidos de despliegues y activaciones.
- 2026-10-25 · T23 · Diez variantes nuevas en `variants.json`: una por aura (efecto frente a radio o reserva), dos para los Drones de Vigilancia (Enjambre, Patrulla larga) y dos para la Bomba Lógica (racimo, detonación remota); clave nueva `mult.aura_effect` que escala los bonos del aura con sus topes, y el DPS sigue a `add.drone_count`.
- 2026-10-25 · T24 · Siete habilidades propias de clase, una por clase en una única de ascendencia (en el lugar de un pulso de estática, nova o explosión genéricos; sin reembolso): Muro de fuego, Sprint con demo, Disparo perfilado, Botnet, Pantallazo azul, Alerta del pager y Despliegue azul-verde. Se usan solas con un enemigo cerca y escalan con el nivel y con el daño del personaje de su tipo.
- 2026-10-25 · T25 · Cuatro chips únicos que transforman los nodos asignados en su radio (Criogénico: fuego → frío; Sobretensión: frío → rayo; Monohilo: esbirros → tú; Blindado: evasión → armadura y destreza → fuerza), con aro de radio en el árbol y línea en el tooltip; las pruebas comprueban que cada uno tiene nodos que transformar junto a alguna ranura. No hicieron falta más ranuras.
- 2026-10-25 · T26 · En el menú K: comparador de dos placas (DPS, daño, usos/s, crítico, maná, área, proyectiles, enfriamiento y duración, la mejor en verde) y construcciones guardadas (`Builds`, en flags del personaje: árbol, maestrías y barra; hasta 8; cargar reasigna gratis y coloca las placas que tengas, avisa de las que faltan y no cambia nada si faltan puntos o sitio en la bolsa).
- 2026-10-25 · T27 · Borrador de diseño del Acto IV en `docs/acto4.md` («El Setup de la BIOS», niveles 38–48): premisa (la cuenta de fábrica admin/admin firmó el Último Commit), hub con Berta la Pila CR2032, seis zonas, seis enemigos con afijos, misiones, jefe admin/admin con tres fases (resistencias, mecánica de arena y música por fase), escenas y gancho del Acto V. **Pendiente de revisión del usuario** (preguntas abiertas al final del documento) antes de T28.
- 2026-10-25 · T28 · Acto IV jugable sin historia todavía (`data/act4.json`): POST, hub La Pila del CMOS, Menú Advanced que se bifurca en la Secuencia de Arranque y la ROM de Video Legada, que se juntan en el Sector Oculto, y la arena del Modo de Gestión del Sistema (sin jefe hasta T30). Estilos `setup` y `vga16` (suelo, decorado, luces, posproceso y ambientes generados con `generate_sfx.gd -- acto4`), seis enemigos con sprite y afijo innato (`innate_affixes`; `innate_only` no sale al azar). La Cámara de Reflasheo lleva al POST. Comprobación: lógica + integración rápida de las zonas del Acto IV; la integración completa se cae al azar también sin el Acto IV (ver T67).
- 2026-10-25 · T29 · NPC del hub del Acto IV (Berta, Rafa en persona, Mario, M. Páez y Eugenio) con diálogos; el Pepe solo mencionado. Misión principal *El Setup de la BIOS* y cuatro secundarias (libreta de gatitos, orden de arranque, ajustes de fábrica, café de máquina) con sus objetos y dibujos propios. Decisión sobre los huérfanos con Rafa tras entregar la libreta (`act4_huerfanos_salvados`/`_purgados` + `act4_huerfanos_decidido`). Queda para más adelante: la escolta de la laptop de Rafa y la mejora del Recolector que proponía el diseño. T67: el cierre sin traza también sale en el commit anterior a T28 (1 de 2 pasadas), así que no lo causa el Acto IV; desapareció al terminar otra instancia de Godot que corría en paralelo.
- 2026-10-25 · T30 · Jefe admin/admin en el Modo de Gestión del Sistema: tres fases con resistencias distintas y una mecánica de arena por fase (zonas seguras, suelo que se rompe, adds que canalizan su reinstalación), sprite propio y música `boss4`/`boss4_fase`. Escenas `bios_post`, `admin_entrada` y `admin_cambia_password`, con un paso nuevo de escena `input` donde el jugador escribe la contraseña (validación sarcástica; se guarda en `flags.admin_password`, «admin2» si se salta). Lore actualizado.
- 2026-10-25 · T31 · Tres eventos de zona nuevos: Bombas lógicas (tres bombas con cuenta atrás de 25 s; se desactivan quedándose al lado; las que quedan estallan), Proceso perdido (escolta que solo avanza contigo cerca y sin enemigos a su lado, con dos emboscadas) y Comerciante ambulante (objeto misterioso por fichas). World da el botín según salga bien o mal.
- 2026-10-25 · T32 · Sanador y francotirador con aspecto propio dibujado sobre el sprite (halo y brazalete con cruz; visor y rifle que apunta, con láser al cargar), roles en las élites (35 % de las manadas con rol; el rol sale en el nombre) y afijo de élite Comandante (aro dorado: +25 % de daño y +15 % de velocidad a los de alrededor).
- 2026-10-25 · T33 · Enemigos que reaccionan a su estado (`EnemyManager._react`, salvo jefes y únicos): pánico al quemarse (50 %, huyen 1,6 s), buscan al sanador con poca vida y se reagrupan con el comandante si no están peleando; marca sobre la cabeza («!», «+», «»»).
- 2026-10-25 · T34 · Lore coleccionable: 18 commits, logs y correos en los cuatro actos (`data/lore_notes.json`, `LoreNotes`), con dibujo propio en el suelo, aviso al recogerlos y registro en Pausa → Archivos encontrados (`LoreLog`); se guardan en `flags.lore_found`. T67: la integración larga volvió a cortarse con la otra instancia de Godot en marcha; las tandas cortas pasaron 3 de 3.
- 2026-10-25 · T35 · Diálogos con decisiones: elegir acompañante en el hub del Acto IV (Mario, Páez o Eugenio; te sigue por las zonas de combate con un bono pequeño; `Companions`, `CompanionFollower`, acción `companion`) y elegir recompensa al entregar *Orden de Arranque* y *Ajustes de Fábrica* (dos opciones que comparten bandera). Nota: el editor de historia del usuario (`tools/story_editor.gd`) no conoce aún la acción `companion`.
- 2026-10-25 · T36 · El campamento del Acto I evoluciona: puesto de Aida tras el Acto I (equipo raro y mágico y pociones, `Economy.generate_gear_stock`), mesa de crafteo de Mario tras el Acto II (reforjar el arma equipada por fichas) y antena de Rafa tras el Acto III (rellena pociones y da un bono de 3 minutos); decorado propio que aparece con cada mejora (`props` con `requires_flag`) y acciones de diálogo `open_gear_shop`, `reforge_weapon` y `antenna`.
- 2026-10-25 · T37 · Némesis (`Nemesis`): el élite que te mató (golpe propio o proyectil en los últimos 4 s; `EnemyManager.last_hitter`) vuelve con tu nombre, sus afijos, ×2,5 de vida y más daño; seguro en la zona donde te mató y a veces en el resto del acto; más fuerte si te vuelve a matar; al vencerlo, cuatro objetos buenos y fichas. T67: otra pasada larga cortada sin traza, ahora sin otra instancia de Godot pero con solo 1,2 GB de RAM libre en el sistema; las cortas pasaron 3 de 3.
- 2026-10-25 · T38 · Crafteo con parches (`Crafting`, `CraftingPanel` en la mesa de Mario): refactor (rehace los afijos no fijados), feature (añade uno), versión mayor (normal → mágico → raro) y hotfix (fija un afijo para el siguiente refactor); caen de élites y únicos y se compran por fichas; el tooltip marca el afijo fijado. `ItemGenerator._roll_affixes` ahora respeta los afijos que ya tenga el objeto.
- 2026-10-25 · T39 · Atlas de incidentes, parte 1 (`Incidents`): desde el puesto de Aida, una zona de combate al azar ya jugable, a tu nivel, con 2-3 de siete modificadores (más grupos, explotan, veloces, blindados, más élites, sin regeneración, −20 a resistencias) que suman botín (`drop_multiplier`); afijos forzados en `EnemyManager.forced_affixes` y mods del jugador mientras dura; salida por portal al campamento.
- 2026-10-25 · T40 · Atlas de incidentes, parte 2 (`Atlas`, `AtlasPanel`): completar un incidente lo marca y suelta un mapa; cada tres zonas distintas sube el nivel del atlas (+2 niveles y +10 % de botín por nivel, hasta 10); mapas (zona + modificadores) que caen al completar y de los élites de dentro, y pantalla del atlas desde el puesto de Aida. La integración juega ahora un incidente (con el atlas abierto antes) una vez por pasada.
- 2026-10-25 · T41 · Dificultades Normal, Pesadilla e Infierno (`Difficulty`): se abren al terminar el Acto IV (y al terminarlo en Pesadilla) y se eligen con Rafa en el campamento; +12/+24 niveles de zona, +20/+40 % de resistencias enemigas, más afijos en élites y especiales, +30/+60 % de botín; los jefes se repiten en cada dificultad (`boss_flag`). T67: un cierre sin traza tumbó también la prueba de lógica una vez; al repetir, todo en verde.
- 2026-10-25 · T42 · Escalado opcional del nivel de zona: opción en Pausa (por personaje, `flags.zone_scaling`) para que las zonas de combate de los actos terminados suban a tu nivel; `Difficulty.zone_level` reúne escalado y dificultad.
- 2026-10-25 · T43 · Recompensas propias en 12 misiones secundarias: placas de invocación y auras en los actos I y II, RAM de grado mayor y el Mainframe Titán en los III y IV; el aviso al aceptar una misión dice qué da (`QuestLog.reward_text`).
- 2026-10-25 · T44 · Ocho únicos nuevos (estados, auras, espinas, autómatas, cargas y terrenos) y dos conjuntos (Kit del SRE de Guardia, Equipo de Redes); las pruebas validan bases y stats de todos los únicos y conjuntos.
- 2026-10-25 · T45 · Diez logros (primer enemigo, jefes de cada acto, 1000 enemigos, némesis, lore, atlas y Pesadilla) que dan cosméticos sin stats: sombreros, auras y pisadas; se equipan en Pausa → Logros y cosméticos. Pruebas cubren defs, desbloqueo y equipar.
- 2026-10-25 · T46 · Banco de oleadas sin fin desde el puesto de Aida (arena vacía, oleadas que crecen, jefe cada 5 con botín) y récords: personales (oleadas y tiempo contra cada jefe) y tabla local top 10 en user://ladder.json, en Pausa → Récords. La integración juega una partida de oleadas tras el incidente.
- 2026-10-25 · T47 · Árbol de deuda técnica tras el Acto IV (Pausa → Deuda técnica): raíz y tres ramas (Hotfix, Legacy, Deadline) de nodos con bono fuerte y penalización; puntos por atlas y récord de oleadas, se paga de las hojas a la raíz. Hecho en una sola tarea en vez de partirla: cabía.
- 2026-10-25 · T48 · Cursor libre de mando en inventario, K, hoja, tienda, alijo y elección de habilidad: stick para moverlo, A/X como clics (eventos de ratón simulados), cruceta para saltar entre casillas, LB/RB entre ventanas y B para cerrar; el personaje queda quieto mientras tanto. La integración lo prueba (elige con A, mueve con la cruceta y cierra con B).
- 2026-10-25 · T49 · Cursor de mando en el árbol pasivo (cruceta entre nodos, stick derecho como rueda) y en los diálogos; comparación de anillos contra los dos puestos (dos secciones y dos tooltips al lado) y comparación fijable con F o Y. La integración fija y suelta con Y y recorre el árbol con la cruceta.
- 2026-10-25 · T50 · Pausa → Controles: tecla y botón de mando por acción (26), con intercambio si ya estaba en uso, guardado en settings.cfg y botón de restaurar; la barra de habilidades y el menú K muestran la tecla asignada.
- 2026-10-25 · T51 · Accesibilidad en Pausa → Interfaz: «menos destellos» (fogonazos de enemigos y de impactos, glitches de escenas y del prólogo, sin parpadeos), tamaño propio del texto del mundo y paletas daltónicas para auras y cargas con el modo daltónico.
- 2026-10-25 · T52 · Auto-ataque opcional (habilidad 1 contra el enemigo más cercano si no pulsas nada ni te mueves) y tres modos de moverse con el ratón (mantener, alternar, clic para ir) en Pausa → Combate. De paso: Controls ya no llena el log de errores al leer controles sin guardar.
- 2026-10-25 · T53 · Mapa grande con zoom (rueda o +/−, cinco niveles centrados en el jugador) y marcas propias con clic derecho (hasta 12 por zona, guardadas en el personaje y visibles en el minimapa). La integración prueba zoom y marcas.
- 2026-10-25 · T54 · Filtro de botín con nivel de objeto mínimo, bases buenas y afijos buscados (se ven siempre, con estrella y haz) y filtros con nombre. Arreglo: las pruebas de Controls y del filtro escribían en el settings.cfg del jugador (la inicialización estática de la clase volvía a poner persist = true); ahora no, y lo comprueban.
- 2026-10-25 · T55 · Ambiente posicional: zumbido de racks, goteo y viento como fuentes 2D que se oyen de cerca, sacadas de los obstáculos (y del estilo en servidores, alcantarillas y la Grieta); tres sonidos nuevos con generate_sfx.gd -- posicional.
- 2026-10-25 · T56 · Voces cortas sintetizadas: murmullo de cada NPC al hablar (saludo, pregunta, exclamación, duda) con su tono y género, y la voz del personaje al subir de nivel y con poca vida; opción en Pausa → Diálogos.
- 2026-10-25 · T57 · Material de cada tipo de enemigo en enemies.json (los 29 con el suyo, documentado en _doc); fuera la tabla EnemyManager.MATERIALS. Las pruebas exigen un material válido por tipo.
- 2026-10-25 · T58 · Luz de auras, invocaciones, drones y botín único; sombras de proyectiles; lluvia de datos (terminal, kernel, servidores) y niebla (pantano, alcantarillas, fosa); opción «Luces y clima: reducidos». No hay enemigos voladores en los datos: las sombras de vuelo quedan en proyectiles y drones (ya la tenían).
- 2026-10-25 · T59 · Los diez obstáculos del Acto I en pixel art (ObstacleArt): pintados una vez en la rejilla de 2 px, con contorno, luz arriba a la izquierda y sombra abajo, tres variantes; revisado en capturas de las zonas del acto I.
