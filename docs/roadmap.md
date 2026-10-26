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

### [x] T60 · Obstáculos en pixel art: actos II y III · M
Origen: R1 §4

### [x] T61 · Prólogo en pixel art: pasillo y oficina · M
Origen: R1 §5
- Mismo nivel de detalle que la calle (luz, tramado, sombras).

### [x] T62 · Música para las pruebas de estrés · S
Origen: R1 §6
- Con `tools/generate_zone_music.gd`.

---

## Fase 8 — Técnica

### [x] T63 · Audio en OGG y sprites en atlas · S
Origen: R1 §6, R2 §12 ★★
- Los .wav suman ~60 MB; los bucles de `data/music_loops.json` deben seguir cuadrando.

### [x] T64 · Telemetría local de equilibrio · M
Origen: R2 §12 ★★
- Registrar DPS, muertes y tiempo por zona en cada partida (archivo local) y una herramienta que lo resuma.

### [x] T65 · Exportación a Linux y macOS e instalador de Windows · S
Origen: R1 §7

### [!] T66 · `EnemyManager` en C# o GDExtension · L — solo si hace falta
Origen: R1 §7, R2 §12
- Hacerla solo si tras T03 la simulación pasa de 4 ms con estados y aliados; si no, marcar `[x]` con la medición como motivo.
- Tras T03 y T03b: 150 enemigos a 60 FPS y 300 a 32-34 FPS en el benchmark; con 300 la simulación ya da ~4.5 ms y el `_draw` de enemigos ~7 ms (los dos en GDScript), y la interfaz ~8 ms. Si se quiere 300 ≥ 50 FPS, empezar por aquí y por cachear en texturas los iconos del HUD.
- **Bloqueada (25-10-2026, medida en T66):** con 300 enemigos la simulación da 4,7-4,8 ms (pasa de 4 ms) en un fotograma de ~34 ms (29-30 FPS; 150 enemigos: 2,4 ms, 52-57 FPS; sin enemigos 12-16 ms). Portarla necesita decidir y descargar: C# pide la edición .NET de Godot y un SDK de .NET (aquí solo está el runtime); GDExtension, un compilador de C++ y scons (no hay). Y la ganancia máxima son esos ~4 ms: de 30 a ~34 FPS, lejos de 50; pesan más el `_draw` de enemigos (~7 ms), la interfaz (~8 ms) y la zona. Recomendación: antes, cachear en texturas los iconos del HUD y pasar el `_draw` de enemigos a MultiMesh; volver a esta tarea solo si después la simulación es lo que más pesa.

---

### [x] T67 · Investigar un cierre sin traza en la integración · S
Origen: comprobaciones de T16
- El 25-10-2026, entre las 00:56 y las 00:58, Godot se cerró 4 veces sin ningún mensaje (código de salida -1, sin evento de Windows) jugando el Tester QA en el acto III (Oblea / Memoria ROM). Después, 0 de 19 pasadas fallaron, y 0 de 6 en el commit 1a91bf1.
- Probar varias decenas de pasadas de esa clase y zonas (con y sin `--verbose`), revisar hilos (FreezeWatch, el `Logger` de la prueba) y, si vuelve a pasar, sacar la traza con el ejecutable de consola o un volcado.
- El 25-10-2026 entre las 08:00 y las 08:40 (durante T28) volvió: 6 de 8 pasadas de la integración rápida completa se cerraron igual (código -1, sin salida ni evento), en zonas distintas de los actos I a III y también **sin cargar el Acto IV**. Nunca en tandas cortas (una clase o pocas zonas: 0 de 8). Memoria, handles e hilos del proceso estables durante la pasada; el sistema tenía 1,6 GB de RAM libre y otra instancia de Godot grabando vídeo. Sospecha: depende de la carga de la máquina o de algo que se acumula entre mundos (la prueba crea y libera un `World` por clase y acto).
- **Investigado el 25-10-2026 (T67), sin reproducirlo:** 10 pasadas cortas del Tester QA en Oblea y Memoria ROM y 5 de 28 mundos (las 7 clases × 4 actos, 1 s por zona): unos 150 mundos creados y cerrados, 0 cierres. Descartado que algo se acumule entre mundos: la integración ahora imprime lo que queda vivo tras cerrar cada uno, y se mantienen 19 nodos, 0 huérfanos y ~84 MB (los objetos se estabilizan en ~+120: cachés de sprites y voces). Hilos revisados: el de FreezeWatch se arranca y se espera bien en cada mundo, y el del narrador no corre sin pantalla. Lo más probable es la carga de la máquina de aquel momento (1,6 GB libres y otra instancia de Godot grabando vídeo). Si vuelve: mirar en la tabla de lo que queda vivo si algo crece, lanzar con `--verbose` y sacar un volcado con el ejecutable de consola. De paso: PowerShell no espera a Godot si no se lee su salida (`*> $null`), lo que explicaba importaciones a medias.

### [x] T68 · Rendimiento: iconos del HUD en texturas y enemigos en MultiMesh · M
Origen: T66 (alternativa elegida por el usuario el 25-10-2026: T66 sigue bloqueada)
- Cachear en texturas los iconos que el HUD dibuja con formas cada fotograma (habilidades, pociones, estados) y dibujarlos como textura.
- Pasar a MultiMesh lo que quede del `_draw` de enemigos que se repite por enemigo.
- Medir antes y después con `capture_screens.tscn -- rendimiento` y anotarlo en `README.md` (*Rendimiento*).
- Resultado: 300 enemigos de 33,4 a ~29,9 ms (30 → 33-34 FPS), 150 de 18,2 a 14-16,6 ms (55 → 60-71 FPS); el `_draw` de enemigos de 7,2 a 6,2 ms. Siguen pesando la simulación (~4,9 ms), la interfaz (~6,5 ms sin contar los iconos) y unas 2.900 llamadas de dibujo por fotograma que vienen sobre todo de la interfaz y la zona (no de los enemigos): el siguiente paso, si hace falta, es por ahí.

---

# Roadmap 3.0 — pulido de género (25-10-2026)

Pedido del usuario tras probar el Acto IV: equilibrar las habilidades iniciales, una tienda de Nacho más rica y con humor, y un repaso de diseño, sprites, animación, sonido, ventanas de gestión y árbol pasivo pensando en Diablo, Path of Exile y Grim Dawn. **Origen: R3.** Mismo protocolo que arriba; 🛑 = parar y esperar el visto bueno.

Medición de partida (`tools/skill_balance.gd`, personaje de nivel 1 sin pasivas ni objetos, placa de nivel 1): mediana 10,9 DPS; muy por encima y sin pedir nivel: Proceso Hijo 58, Bomba Lógica 38, Derrame de Aceite 37, Mina Rodante 35, Fuga de Memoria 34, Drones de Vigilancia 33, Pipe de Datos 30. Los ataques básicos están entre 2 y 19 (escalan con el arma).

## Fase 9 — Balance y tienda

### [x] T69 · Balance de las habilidades iniciales · M
Origen: R3 (pedido del usuario)
- Banda objetivo a placa de nivel 1 y personaje de nivel 1 sin nada: ninguna habilidad por encima de ~2× la mediana; las invocaciones, trampas, terrenos y degenerativos bajan (daño base, intervalo, tope de unidades o duración) y las más fuertes piden nivel (`min_level`: p. ej. Proceso Hijo 6, Drones de Vigilancia 8, Bomba Lógica 4).
- Que la curva por nivel de placa siga premiando subirla (p10 ≈ 3× p1) y que los ataques con arma no queden atrás con el arma inicial de su clase (medir con el arma inicial, no a puño).
- Comprobar contra el primer jefe: con la habilidad inicial de cada clase y sin pasivas, ni en segundos ni en una eternidad (rango a fijar con la herramienta: tiempo para vaciar su vida).
- `tools/skill_balance.gd` gana columnas: arma inicial de la clase y tiempo contra el jefe del Acto I. Prueba en `test_core` que exija la banda, para que una habilidad nueva no se cuele por arriba.
- Hecho: daño base bajado en proporción a ~21 DPS (placa 1) en Proceso Hijo, Bomba Lógica, Derrame de Aceite, Mina Rodante, Fuga de Memoria, Drones de Vigilancia, Pipe de Datos, Campo de Estática, Flamewar, Watchdog, Tormenta de Tickets y Fork Bomb; Drones con crecimiento 0,11 (ganan un dron por hito); Ráfaga de Paquetes 0,9 → 1,2 de efectividad; `min_level` 4-6 en las que solo caen como botín. Mejor inicial contra el Arquitecto: Guerrero 92 s, Duelista 68, Exploradora 90, Hacker 55, Hechicero 59, Templario 43, Full Stack 53.

### [x] T70 · Tienda de Nacho, parte 1: más surtido · M
Origen: R3
- Más placas (8-10) y RAM (10-12), repartidas por atributo y familia (que siempre haya algo para la clase que juegas), con una **oferta del día** (una placa o RAM poco común con descuento) y un artículo «de contrabando» caro de rareza alta.
- Renovar el surtido pagando tokens (precio que sube con cada renovación hasta que vuelves a entrar en la zona), filtros por tipo (placas, RAM, pociones) y por atributo, y comparar con lo equipado al pasar el ratón.
- Precios revisados con la economía de tokens (cuánto se gana por zona de cada acto), vender por lote (todo lo normal / mágico de la bolsa) y recomprar lo último vendido.
- Hecho: 9 placas (3 por atributo, sin repetir), hasta 10 RAM distintas, 2 pociones, oferta del día (4 ranuras, 60 %) y contrabando (+2 niveles, 5 ranuras, ×2,5); renovar cada vez más caro (se reinicia al cambiar de zona); filtros; aviso de «ya la tienes»; venta por lote y recompra; la tienda se desplaza si no cabe. Arreglo de T69: `ItemGenerator.generate_motherboard` ignoraba `min_level` de las habilidades (solo lo miraban las RAM). Pendiente para T71: la comparación al pasar el ratón sigue siendo la del tooltip (solo equipo).

### [x] T71 · Tienda de Nacho, parte 2: la gabardina · M 🛑
Origen: R3 (idea del usuario)
- La tienda como escena: Nacho abre la gabardina (animación de dos o tres cuadros en pixel art) y los artículos cuelgan del forro en ganchos y bolsillos; la oferta del día en el bolsillo de dentro, el contrabando en un bolsillo que se abre aparte.
- Frases sarcásticas al entrar, al pasar el ratón por un artículo, al comprar, al vender, al regatear sin tokens o al renovar («Original, original. Bueno, original de algún lado», «Esta RAM se cayó de un camión. De un camión de Amazon.»), con su voz corta (Barks) y un sonido de tela al abrir y cerrar.
- Mismo funcionamiento que la tienda actual (arrastrar para vender, clic para comprar, mando), y la de Aida (equipo) con el mismo marco pero su propio estilo (puesto ordenado, sin gabardina).
- Hecho: `ShopVendorArt` dibuja a Nacho en pixel art (sombrero, gafas de sol, gabardina cerrada → entreabierta → abierta con RAM, placas y relojes colgando) y a Aida tras su puesto con toldo (tres cuadros: se ajusta las gafas); la mercancía cuelga de ganchos en un forro morado, la oferta va en el «bolsillo de dentro» y el contrabando en un «bolsillo secreto» que se abre con un botón. `ShopLines`: frases de Nacho y de Aida para entrar, mirar (con pausa de 4 s; frases propias para la oferta y el contrabando), comprar, recomprar, vender, vender por lote, sin tokens, bolsa llena, renovar y abrir el bolsillo; bocadillo, boca que se mueve y voz con Barks. Tela sintetizada al abrir y cerrar. El puesto de Aida usa el mismo panel sin filtros, bolsillos ni bodega. Sigue pendiente comparar placas y RAM con lo equipado al pasar el ratón.

## Fase 10 — Diseño visual, sprites y animación

### [x] T72 · Personaje animado por estados, parte 1: poses y arma en la mano · M
Origen: R3 (Diablo II/PoE: lectura del personaje)
- Ciclos en pixel art en 4 direcciones: reposo con respiración, caminar, correr, ataque cuerpo a cuerpo por tipo de arma, lanzar hechizo, canalizar, recibir golpe, esquivar y morir; el arma y el escudo equipados se ven en la mano.
- Hecho: `CharacterAppearance.draw` acepta una pose (estado, avance, arma, brillo): reposo con respiración, caminar, correr (por encima de 1,15× la velocidad base), golpe por tipo de arma (espada, hacha y maza en arco; daga en estocada), disparo, hechizo con brillo del elemento, canalizar, retroceso al recibir un golpe, esquiva agachada y caída al morir, en las cuatro direcciones. `Player` lleva el estado (`play_action`, `keep_channeling`, `anim_state`, `anim_pose`) y `SkillController` lo activa al lanzar. Diferencias con lo pedido: sigue siendo el dibujo con formas (los ciclos en pixel art por cuadros necesitarían hojas de sprites dibujadas a mano, que el proyecto no tiene) y no hay escudos en el juego, así que solo se ve el arma.

### [x] T72b · Personaje animado por estados, parte 2: el golpe en el cuadro de impacto · M
Origen: R3 (partida de T72, que era L)
- Que la animación de ataque marque el momento del golpe (el daño sale en el cuadro de impacto, no al pulsar).
- Hecho: `SkillController.impact_delay`: los ataques cuerpo a cuerpo golpean cuando el arma pasa por delante (47 % de la acción con espada, hacha o maza; 30 % con daga o puño, al final de la estocada) y los de distancia al soltar (38 %), con un tope de 0,3 s; las repeticiones cuentan desde el golpe. Siguen saliendo al instante los hechizos, las habilidades de movimiento, las invocaciones, las trampas y las RAM de activación. Una prueba comprueba que el cuadro de impacto coincide con la pose (el brazo por delante).

### [x] T73 · Enemigos: anticipación, impacto y muertes · M
Origen: R3 (Grim Dawn: peso de los golpes)
- Pose de anticipación antes de cada ataque (además del aviso rojo), retroceso al recibir un crítico y muertes por material y por tipo de daño (se congela y estalla, se desintegra en bits, se quema).
- Cadáveres que se quedan unos segundos y se desvanecen.
- Hecho: al cargar el golpe se echa hacia atrás (además de aplastarse y temblar) y en los últimos 0,12 s destella en blanco; un crítico da un respingo (atrás, aplastado y ladeado, también los jefes) y empuja más. Las muertes por tipo de daño ya existían (hielo, ceniza, chispas, disolverse, descompilarse); ahora las físicas dependen del material: chatarra con chispas (metal), añicos (cristal), gotas (carne) o bits (digital), con su sonido. Cadáveres: tumbados, oscuros y quietos 4 s, desvaneciéndose en el último segundo y medio (máx. 60), en una MultiMesh aparte por debajo de los vivos; los quemados, los congelados y los de cristal no dejan cuerpo.

### [x] T74 · Efectos de habilidades con más cuerpo · M
Origen: R3 (PoE: cada habilidad se reconoce de lejos)
- Cada habilidad con lanzamiento, trayecto e impacto propios en la rejilla de píxeles (no solo color por tipo de daño), partículas que respetan «Menos destellos», y una versión más ligera con muchos enemigos en pantalla.
- Hecho: `SkillFx` da a cada habilidad su firma (proyectil, estela, lanzamiento e impacto), con forma propia para la ráfaga de paquetes (paquete con cabecera), el paquete rastreador (con antena que parpadea), la corrupción de datos (glitch), el ping y la torreta (rayo en zigzag) y la cascada CSS (esquirla); el resto, la de su tipo de daño (bola de fuego con llamitas, esquirla de hielo, rayo, gota de caos, orbe). `ImpactFx` suma destello al lanzar, estela y estallido de firma en la rejilla de 2 px; con Menos destellos, menos partículas y sin núcleos blancos; con más enemigos en pantalla que `FX_DETAIL_LIMIT`, sin estelas ni estallidos y con proyectiles simples. Las novas, conos y demás formas de área siguen con su dibujo por tipo (ya eran distintas entre sí).

### [x] T75 · Iconos en pixel art dibujado · M
Origen: R3
- Atlas de iconos de habilidades, RAM, pociones y estados dibujados a mano en píxeles (16×16 y 32×32), en vez de formas vectoriales; mismo marco por rareza que los objetos.
- Hecho: `tools/generate_pixel_icons.gd` rasteriza los glifos de las 62 habilidades, 10 estados y 52 familias de RAM a 32×32 y 16×16 sin suavizado (alfa todo o nada, paleta de 16 niveles por canal, contorno de 1 px) en `assets/sprites/icons/icons32.png` e `icons16.png` con su mapa `data/pixel_icons.json`; `PixelIcons` los dibuja con escala entera (el de 16 por debajo de 26 px) y SkillIcon, StatusIcon y RamIcon los usan sobre su mismo fondo y marco, con los glifos de formas de respaldo. Como los objetos, es «arte de programador»: los iconos dibujados a mano de verdad se ponen sustituyendo los PNG con la misma cuadrícula. Las familias de RAM sin símbolo propio siguen siendo un círculo.

### [x] T76 · Interfaz con identidad · M 🛑
Origen: R3 (Grim Dawn/PoE: ventanas como objetos del mundo)
- Fuente de píxeles para títulos y números, marcos de ventana con remaches y esquinas, botones con estado pulsado, orbes de vida y maná con líquido animado, y un tema común para todas las ventanas.
- Revisar contraste y tamaños con la interfaz al 80-160 %.
- Hecho: `PixelFont`, fuente de píxeles de 5×7 hecha en código (mayúsculas con tildes, Ñ y Ü, cifras y signos; lo que no tiene, con la fuente normal) para los títulos de ventana (×3), los encabezados de sección (×2) y las cifras de los orbes; `UiStyle.pixel_label` la pone en mayúsculas con sombra dura. Marcos con remaches cada 90 px y cantoneras de metal bajo los ángulos dorados; botones que se hunden al pulsar (borde grueso arriba y texto 2 px más abajo); orbes con el fondo más oscuro, burbujas que suben y la cresta de la ola rellena. Todas las ventanas ya compartían `UiStyle.make_theme` y `decorate_window`. Revisado al 80 % y al 160 % (`capture_screens -- ventanas80` / `ventanas160`): ningún texto por debajo de 12 px (`MIN_FONT_SIZE`). Fuera de los múltiplos enteros (80 %, 160 %) los píxeles de la fuente salen algo desiguales.

## Fase 11 — Sonido

### [x] T77 · Sonido por habilidad y por objeto · M
Origen: R3 (Diablo: el sonido del botín)
- Cada habilidad con su sonido de lanzamiento e impacto (capas y variaciones de tono, no uno por tipo de daño); sonidos de recoger y equipar por tipo de objeto (metal, tela, cristal, placa), de la caída de un único o de un conjunto, y pasos según el suelo.
- Sonidos de interfaz: abrir y cerrar ventanas, pasar el ratón, comprar, error.
- Hecho: 25 sonidos nuevos sintetizados (`generate_sfx.gd -- t77`). `SoundMap`: cada habilidad lanza su sonido de tipo más una capa de firma (clic digital, aire, zumbido, campana o golpe grave) con un tono propio sacado de su id (0,86-1,14) y ±4 % al azar; los proyectiles suenan al golpear según su daño. Recoger y equipar según el material (metal, tela, cristal, placa; los anillos y amuletos más agudos), caída propia de los conjuntos (los únicos ya la tenían), pasos en tierra, piedra o metal según el estilo de la zona, y en la interfaz: abrir y cerrar ventanas (sin repetir al pasar de una a otra), pasar el ratón por los botones, comprar y los avisos de error (en rojo). Sin escucharlo en partida: las pruebas comprueban que existen todos los sonidos y que los tonos se reparten.

### [x] T78 · Música y avisos sonoros por intensidad · S
Origen: R3
- Avisos cortos (stingers) al aparecer un élite, al caer botín bueno, al subir de nivel y al entrar a un jefe; transición de la capa de combate a la del jefe sin cortes.
- Hecho: cuatro avisos sintetizados (`generate_sfx.gd -- t78`): élite (metales graves y timbal), botín bueno (destello de campanas), subida de nivel (fanfarria) y jefe (oleada, acorde grave y dos timbales). `MusicPlayer.stinger` los toca con el volumen de la música y la baja 7 dB mientras suenan; el mismo aviso no se repite antes de 6 s (salvo el de jefe). Suenan al ver por primera vez un élite o un único (a distancia de combate), al caer un único, un conjunto o algo con haz del filtro, y al subir de nivel. El paso a la pista de fase del jefe espera al siguiente tiempo de la pista que suena y entra ya en su bucle (sin intro), con fundido cruzado; la capa de combate se apaga con su propio fundido. Sin escucharlo en partida.

## Fase 12 — Ventanas de gestión

### [ ] T79 · Inventario a la altura del género · M
Origen: R3 (PoE/Grim Dawn)
- Ordenar y compactar, bloquear objetos (no se venden ni se tiran), marcar como basura, vender lo marcado a Nacho de una vez, y comparación rápida con Alt.
- Objetos que ocupan su tamaño en la rejilla (1×1, 1×2, 2×2, 2×3) si se decide que suma; si no, dejarlo anotado.

### [ ] T80 · Alijo con pestañas y búsqueda · M
Origen: R3 (PoE: búsqueda del alijo)
- Pestañas con nombre y color, una de materiales (parches de crafteo, mapas, chips) y búsqueda por texto que resalta lo que coincide (nombre, base o afijo).

### [ ] T81 · Hoja de personaje con desglose · M
Origen: R3 (PoE: de dónde sale cada número)
- Cada estadística con un tooltip de dónde viene (clase, árbol, objetos, auras, cargas), DPS por habilidad de la barra y resistencias con su tope.

### [ ] T82 · Ventanas coherentes entre sí · S
Origen: R3
- Mismas teclas para abrir y cerrar, apilar ventanas sin taparse (izquierda/derecha), recordar la última pestaña, y que todas funcionen con el cursor de mando.

## Fase 13 — Árbol pasivo

### [ ] T83 · Planificador del árbol · M
Origen: R3 (PoE: planear la build)
- Modo plan: marcar nodos sin gastar puntos y ver el camino; deshacer y rehacer; reasignar con coste (tokens) en vez de solo gratis o nada; exportar e importar la build como código de texto.

### [ ] T84 · Más identidad en el árbol · M
Origen: R3 (Grim Dawn: constelaciones)
- Grupos temáticos por clase con un notable que cambia cómo se juega (no solo números), más keystones con su contra, y «constelaciones» opcionales que piden puntos de dos atributos.

### [ ] T85 · Arte del árbol · S 🛑
Origen: R3
- Fondo por región de clase, iconos de nodo en pixel art, línea que se ilumina al asignar y un pequeño destello al completar un grupo.

## Fase 14 — Botín y fin de juego

### [ ] T86 · Bases con identidad y únicos con mecánica · M
Origen: R3 (Diablo/PoE: el botín que cambia la build)
- Más bases con implícito propio por tipo de arma y armadura, y únicos cuya gracia sea una mecánica (no solo más números), con su texto de humor.

### [ ] T87 · Crafteo con más decisiones · M
Origen: R3 (PoE/Grim Dawn)
- Parches que fijan o quitan un afijo concreto, mejorar el tier de uno a cambio de riesgo, y la mesa de Mario con historial de lo que hizo.

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
- 2026-10-25 · T60 · Pistones (vástago animado en la rejilla), disipadores, barriles, condensadores, chips y bloques de hielo en pixel art: ya todos los obstáculos de los actos salvo los charcos; la prueba lo exige para cada zona. Revisado en capturas de los actos II y III.
- 2026-10-25 · T61 · Pasillo y oficina del prólogo con el detalle de la calle: tramado en paredes, baldosas alternas en perspectiva (recortadas al suelo), charcos y conos de luz, aristas con luz y sombra, humedad, zócalo, juntas y sombras al pie de los muebles. Solo dibujo (sin lógica nueva que probar): revisado en las capturas del prólogo.
- 2026-10-25 · T62 · Pista «Prueba de carga» (estres, 138 BPM, con capa de combate) compuesta con generate_zone_music.gd -- estres; suena en las pruebas de estrés y el banco de oleadas y al acabar vuelve la de la zona.
- 2026-10-25 · T63 · Música, ambientes y tema del título en OGG (91,8 → 13,4 MB) con tools/convert_audio.ps1; Sfx.load_looped carga OGG o WAV y pasa el inicio de bucle de music_loops.json a segundos (16 000 Hz en la música). Los sprites ya estaban en atlas (enemigos, objetos, pasivas): nada que hacer ahí.
- 2026-10-25 · T64 · Telemetría local: una línea por visita a zona en user://telemetria.jsonl (tiempo, combate, daño, DPS, enemigos, muertes; solo personajes guardados, opción en la pausa) y tools/telemetry_summary.gd que lo resume por zona y clase.
- 2026-10-25 · T65 · Presets de Linux y macOS (export_presets.example.cfg, porque export_presets.cfg está en .gitignore), tools/build_release.ps1 que exporta lo que tenga plantilla y arma el instalador de Windows (installer/Setup.cs con csc: instala por usuario, accesos directos y desinstalador). Probado: Windows exporta (121 MB) y arranca, el instalador extrae el juego idéntico. Linux y macOS sin probar: sus plantillas no están instaladas (bajarlas necesita tu permiso). IExpress se descartó: fallaba al azar.
- 2026-10-25 · T66 · Bloqueada [!]: simulación de 300 enemigos 4,7-4,8 ms (sobre el umbral), pero portar a C# o GDExtension necesita descargas y herramientas que no hay y ganaría ~4 ms de 34; motivo y recomendación bajo la tarea.
- 2026-10-25 · T67 · Cierre sin traza investigado: ~150 mundos en tandas cortas sin un cierre; descartada la acumulación entre mundos (tabla nueva de lo que queda vivo al final de la integración) y revisados los hilos; queda como sospecha la carga de la máquina. Pasos para la próxima vez bajo la tarea.
- 2026-10-25 · T68 · Barras, cuadritos de estado y halos de enemigos en MultiMesh, avisos de cono y carga en el lote, círculos con direcciones precalculadas e iconos del HUD cacheados en texturas (IconCache): 300 enemigos 33,4 → ~29,9 ms y 150 enemigos 18,2 → 14-16,6 ms. T66 sigue bloqueada.
- 2026-10-25 · Pausa en tres columnas con desplazamiento (no se veían todas las opciones) y Roadmap 3.0 (T69-T87): balance de habilidades iniciales, tienda de Nacho con gabardina, sprites, animación, sonido, ventanas de gestión, árbol pasivo y botín; herramienta tools/skill_balance.gd.
- 2026-10-25 · T69 · Balance de habilidades iniciales con tools/skill_balance.gd: nada por encima de ~2× la mediana a placa 1 y la mejor inicial de cada clase tumba al primer jefe en 43-92 s (antes 24-120 s); prueba que exige la banda.
- 2026-10-25 · T70 · Tienda de Nacho con más surtido: placas de los tres atributos, RAM distintas, pociones, oferta del día y contrabando; renovar con precio creciente, filtros, venta por lote y recompra. De paso, las placas respetan ya el min_level de su habilidad.
- 2026-10-25 · T71 · La gabardina de Nacho: tienda como escena (pixel art en tres cuadros, forro con ganchos, bolsillo de la oferta y bolsillo secreto del contrabando), frases sarcásticas con voz y sonido de tela; el puesto de Aida con su propio estilo. Parada para revisión.
- 2026-10-25 · T72 · Partida en dos (T72b: daño en el cuadro de impacto). Parte 1: poses del jugador por estado (respira, camina, corre, golpe por arma, disparo, hechizo, canalizar, golpe recibido, esquiva y muerte) con el arma equipada en la mano.
- 2026-10-25 · T72b · Los ataques golpean en el cuadro de impacto de la animación (cuando el arma pasa por delante o al soltar lo lanzado), con tope de 0,3 s.
- 2026-10-25 · T73 · Enemigos con más peso: se echan atrás y destellan antes de golpear, respingo con los críticos, muertes físicas por material y cadáveres que se desvanecen.
- 2026-10-25 · T74 · Firma visual por habilidad: forma de proyectil, estela, destello al lanzar y estallido al golpear, con versión ligera y respetando Menos destellos.
- 2026-10-25 · T75 · Atlas de iconos en pixel art (32 y 16 px) de habilidades, estados y RAM, generados desde los glifos y listos para sustituir por arte a mano.
- 2026-10-25 · T76 · Interfaz con identidad: fuente de píxeles para títulos y cifras, marcos con remaches, botones que se hunden, orbes con burbujas y texto mínimo de 12 px. Parada para revisión.
- 2026-10-25 · T77 · Sonido por habilidad (capa de firma y tono propio), impactos por daño, recoger y equipar por material, caída de conjuntos, pasos por suelo y sonidos de interfaz.
- 2026-10-25 · T78 · Avisos de música (élite, botín, nivel y jefe) que bajan la música un momento, y paso a la fase del jefe a compás y sin intro.
