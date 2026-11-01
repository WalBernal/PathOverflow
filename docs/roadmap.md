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

### [x] T79 · Inventario a la altura del género · M
Origen: R3 (PoE/Grim Dawn)
- Ordenar y compactar, bloquear objetos (no se venden ni se tiran), marcar como basura, vender lo marcado a Nacho de una vez, y comparación rápida con Alt.
- Objetos que ocupan su tamaño en la rejilla (1×1, 1×2, 2×2, 2×3) si se decide que suma; si no, dejarlo anotado.
- Hecho: botón «Ordenar» (`Inventory.sort_bag`: compacta sin huecos; equipo por ranura, rareza y nivel, luego pociones, placas, RAM, chips y objetos clave, la basura al final). Click derecho en la bolsa: basura → bloqueado → sin marca (candado o papelera sobre la casilla; se guardan con el objeto en bolsa, equipo y alijo). Lo bloqueado no se vende (ni arrastrándolo ni en lote) ni se tira; en la tienda, «Vender lo marcado como basura» (`Economy.junk_sell`, cualquier tipo salvo objetos clave) y lo vendido vuelve sin marca si se recompra. Alt en cualquier tooltip de equipo lo compara con lo equipado (alijo, tienda, suelo). Tamaños en la rejilla: **no se hace** — con 60 casillas, alijo, filtro de botín y venta por lote/basura, el «tetris» añadiría gestión sin decisiones interesantes; queda anotado por si se replantea con una bolsa más pequeña.

### [x] T80 · Alijo con pestañas y búsqueda · M
Origen: R3 (PoE: búsqueda del alijo)
- Pestañas con nombre y color, una de materiales (parches de crafteo, mapas, chips) y búsqueda por texto que resalta lo que coincide (nombre, base o afijo).
- Hecho: cinco pestañas; «Editar pestaña» cambia el nombre (hasta 20 letras; vacío = el de fábrica) y el color (7 colores), que se guardan en el alijo (versión 2; los de antes cargan con los nombres de fábrica). Pestaña «Materiales»: solo chips de expansión (lo de crafteo que es objeto; los chips van ahí solos al guardarlos) y muestra los parches del personaje, que son contadores. No hay mapas en el juego. Búsqueda (`Stash.matches`: nombre, base, habilidad de la placa y texto de los afijos, sin mayúsculas ni tildes): resalta en dorado lo que coincide, apaga el resto y cuenta las coincidencias de cada pestaña en su botón. Mientras se escribe en un campo de texto, las teclas de habilidades, esquiva y movimiento no actúan (`UiStyle.typing`).

### [x] T81 · Hoja de personaje con desglose · M
Origen: R3 (PoE: de dónde sale cada número)
- Cada estadística con un tooltip de dónde viene (clase, árbol, objetos, auras, cargas), DPS por habilidad de la barra y resistencias con su tope.
- Hecho: `StatBlock.source_breakdown` agrupa los modificadores de un stat por su origen (clase, ascendencia, atributos, árbol, chips, deuda técnica, objetos, conjuntos, pociones, cargas, auras, habilidades, santuarios…) y `StatExplain.explain` lo convierte en el tooltip de cada barra de la hoja: base, cada origen con su plano, aumento y multiplicador, y la fórmula. Atributos (más lo que dan), resistencias (con su tope y lo que falta o sobra), vida, escudo, maná, armadura, evasión y bloqueo. En Ofensiva, «DPS de la barra» con la tecla y el DPS de cada habilidad (las de apoyo lo dicen). Tooltips sin ver en pantalla: comprobado el texto en pruebas.

### [x] T82 · Ventanas coherentes entre sí · S
Origen: R3
- Mismas teclas para abrir y cerrar, apilar ventanas sin taparse (izquierda/derecha), recordar la última pestaña, y que todas funcionen con el cursor de mando.
- Hecho: la columna izquierda (tienda, alijo, habilidades, hoja de personaje y waypoints) muestra una sola ventana a la vez: al abrir una se cierran las demás (los waypoints, que van al centro, cierran también el inventario); la de la izquierda, sea cual sea, se encoge para caber junto al inventario (antes solo la tienda y el alijo). La tienda y el alijo dicen «I o Esc para cerrar» (I ya los cerraba con el inventario). Se recuerdan la última pestaña del alijo, el último filtro de la tienda y el de la bolsa de habilidades (`UiStyle.remember`, en settings.cfg solo al cambiarlos). El cursor de mando incluye ahora los waypoints y el banco de oleadas. Arreglado de paso: los encabezados largos con la fuente de píxeles (T76) ensanchaban la ventana de habilidades al 160 %; ahora los de más de 24 letras van con la fuente normal.

## Fase 13 — Árbol pasivo

### [x] T83 · Planificador del árbol · M
Origen: R3 (PoE: planear la build)
- Modo plan: marcar nodos sin gastar puntos y ver el camino; deshacer y rehacer; reasignar con coste (tokens) en vez de solo gratis o nada; exportar e importar la build como código de texto.
- Hecho: `PassivePlan` (lógica pura, con una asignación «sombra» = asignado + planeado). «Modo plan»: click izq. planea el camino hasta un nodo sin gastar puntos (anillos y camino cian), click der. lo quita si no deja otros colgando; «Aplicar plan» asigna en el orden marcado hasta donde lleguen los puntos; «Borrar plan». Deshacer y rehacer (botones y Ctrl+Z / Ctrl+Y) de lo asignado, las maestrías y el plan, desde que se abrió el árbol. En partida, quitar un nodo cuesta `Economy.passive_refund_cost` (5 + 2 × nivel) en tokens, y reiniciar el árbol, lo de cada nodo; lo asignado en esta visita se quita gratis (en el planificador suelto, todo gratis). «Copiar build» / «Pegar build»: código `PO1:` (JSON comprimido en base64 con clase, nodos y maestrías) por el portapapeles; en partida se carga como plan (no regala puntos); en el planificador suelto cambia de clase si hace falta.

### [x] T84 · Más identidad en el árbol · M
Origen: R3 (Grim Dawn: constelaciones)
- Grupos temáticos por clase con un notable que cambia cómo se juega (no solo números), más keystones con su contra, y «constelaciones» opcionales que piden puntos de dos atributos.
- Hecho: `data/passive_identity.json` (encima del árbol generado, como las maestrías, comprobando el nombre de cada nodo). Un **notable de estilo** por clase, el más cercano a su inicio que no es maestría, con una mecánica que el juego ya hace: Commit Atómico (físico a rayo), Escalado a Nivel 3 (nova al recibir golpes), Caso Límite (bomba al esquivar), Lazy Loading (+2 perforaciones), Inyección de Prompt (elemental a caos), Batch Nocturno (pulso de estática) y Rollback Automático (explosión al matar); anillo dorado en el árbol. Cuatro **piedras angulares** nuevas con contra (Hotfix en Producción, Root Access, Arquitectura Hexagonal, Kanban), que siguen siendo el notable de su cluster (`capstone`). Tres **constelaciones** exteriores (Pentester: FUE+DES, Hacker Ético: DES+INT, Arquitecto: INT+FUE) que piden 50 de cada uno para asignar o cruzar sus nodos y dan un 50 % más; puntas de estrella en el árbol y el tooltip dice cuánto tienes. Lo ya asignado se carga aunque bajen los atributos.

### [x] T85 · Arte del árbol · S 🛑
Origen: R3
- Fondo por región de clase, iconos de nodo en pixel art, línea que se ilumina al asignar y un pequeño destello al completar un grupo.
- Hecho: cada región del árbol tiene detrás un resplandor del color de su clase (classes.json → color); los nodos menores muestran el icono en pixel art de su temática (apagado hasta asignarlos, y solo con zoom suficiente), como ya hacían notables y piedras angulares; al asignar, cada línea nueva brilla y la recorre una chispa (0,9 s), y al completar un grupo sale un anillo con chispas de píxel de su color y un sonido corto (como mucho tres a la vez, por si se carga una build entera).

## Fase 14 — Botín y fin de juego

### [x] T86 · Bases con identidad y únicos con mecánica · M
Origen: R3 (Diablo/PoE: el botín que cambia la build)
- Más bases con implícito propio por tipo de arma y armadura, y únicos cuya gracia sea una mecánica (no solo más números), con su texto de humor.
- Hecho: 10 bases nuevas de nivel 24-36, cada una con implícito propio de su tipo (espadas roban vida, hachas desangran, mazas abarcan más área, dagas envenenan; armadura pesada con bloqueo, chaqueta mixta con recuperación de enfriamientos, auriculares con resistencia a estados, guantes antiestáticos con resistencia al rayo, botas de seguridad con recarga de esquiva) y su icono. 8 únicos con mecánica y su texto: El Pager de Guardia (rayos de guardia), Encendedor del Practicante (muros de fuego), Ctrl+Z de Bolsillo (nova al recibir golpes), Puñal Incendiario de Producción (físico a fuego y explosiones al matar), Rebase Interactivo (rebotes), Túnica del Modo Seguro, Guantes del Doble Click (un proyectil más) y Casco del Rollback (bomba al esquivar).

### [x] T87 · Crafteo con más decisiones · M
Origen: R3 (PoE/Grim Dawn)
- Parches que fijan o quitan un afijo concreto, mejorar el tier de uno a cambio de riesgo, y la mesa de Mario con historial de lo que hizo.
- Hecho: dos parches nuevos (también caen y Mario los vende): **rollback** quita el afijo elegido, y **optimización** sube un tier el afijo elegido hasta lo que permite el nivel del objeto, con un 30 % de que se rompa y se pierda (si ya está arriba, no se gasta). Fijar un afijo ya existía (hotfix). La mesa cuenta lo que pasó («Optimizado: … → … (T2)», «Se rompió…») y guarda con el personaje un historial de las últimas 12 cosas que hizo, visible en la propia mesa.

# Roadmap 4.0 — gráficos y árbol pasivo nuevo (25-10-2026)

Pedido del usuario tras el Roadmap 3.0: un salto gráfico (interfaz, efectos, sprites y animación) y un **cambio radical del árbol pasivo**: muchos más nodos, otro diseño, más clusters de las familias que ya hay, una familia de maná (regeneración base plana y en %, maná máximo, daño que se lleva el maná antes que la vida) y piedras angulares nuevas. **Origen: R4.** Mismo protocolo; 🛑 = parar y esperar el visto bueno.

Punto de partida (árbol versión 7, `tools/generate_passive_tree.py`): 716 nodos, 630 menores, 72 notables, 7 piedras angulares + 4 de cluster (T84), 67 clusters de 28 familias, 8 maestrías y 3 constelaciones. Los añadidos de T84 y las maestrías van en archivos aparte pegados por **id de nodo**, así que regenerar el árbol los rompe: el árbol nuevo tiene que llevar ids estables (o meterlos en el generador). El maná regenera 1,75 % del maná sin reservar por segundo × «% de regeneración»; no hay regeneración plana ni «daño al maná antes que a la vida».

## Fase 15 — Árbol pasivo 2.0

### [x] T88 · Diseño del árbol 2.0 · M 🛑
Origen: R4 (pedido del usuario)
- Documento `docs/arbol_2.md` con el objetivo y un boceto: **~1500 nodos** (unos 1300 menores, 150 notables, 20-24 piedras angulares, 25 maestrías), más del doble de clusters y con formas distintas (rueda, estrella, cadena, rombo, panal; pequeños de 3-4 nodos, medianos de 6-8, grandes de 10-14 con dos notables), regiones por clase más anchas con un «corazón» de su estilo, un anillo exterior de constelaciones y un centro de nodos de viaje.
- Reparto de familias: cuántos clusters de cada una (las 28 de ahora más maná, más las nuevas que salgan), dónde caen respecto a las clases y qué notables tiene cada una (sin repetir nombre ni efecto).
- Decidir el formato de ids estables (clave por cluster y posición, p. ej. `c_fuego_2:n3`) para que maestrías, identidad, planificador y guardados no dependan del orden de generación.
- Captura del boceto (el generador nuevo en modo «solo disposición») para revisarlo antes de llenarlo.
- Hecho: `docs/arbol_2.md` (cifras, estructura, formas, familias, maná, piedras angulares, ids estables, migración y cinco preguntas para decidir) y el prototipo `tools/generate_passive_tree_v2.py` → `data/passive_tree_v2_layout.json` (sin efectos; el juego no lo usa): 1540 nodos, 114 clusters (30 S, 54 M, 12 L, 6 XL, 6 piedras, 6 constelaciones), 126 notables y 18 huecos de maestría, todo conectado y sin nodos encimados; claves estables por nodo. Capturas con `capture_screens -- arbol2`. Pendiente para T89: bajar los nodos de viaje (687, demasiados) acercando anillos y sumando clusters pequeños.

### [x] T89 · Generador del árbol 2.0, parte 1: el árbol con efectos · M
Origen: R4
- Reescribir `tools/generate_passive_tree.py` con la disposición aprobada en T88: formas de cluster, tamaños, caminos de viaje y conexiones entre regiones; ids estables y `TREE_VERSION` 8.
- Pasar las maestrías (`passive_masteries.json`) y la identidad (`passive_identity.json`) al formato de ids estables (o dentro del generador), con prueba de que nada quedó colgando.
- Hecho: `tools/generate_passive_tree.py` es el generador 2.0 (el de la versión 7 queda en git) y escribe `data/passive_tree.json` versión 8: 1373 nodos (354 de viaje, el 26 %), 138 clusters (29 S, 78 M, 12 L, 6 XL, 6 constelaciones y 7 huecos de piedra), 149 notables, 18 maestrías (los tres primeros notables de su familia) y 11 piedras angulares (las 7 de siempre más las 4 de T84 de verdad), con anillo E y dos medianos más en el D de cada región; cada familia con 3-8 clusters. Las maestrías, los notables de estilo, las piedras extra y las constelaciones van dentro del árbol (`choices`, `style`, `requires`, `constellation`, `key`): `passive_masteries.json` desaparece y `passive_identity.json` pasa a estar por clase, no por id. `PassiveTree.id_for_key` traduce claves. Los inicios solo conectan con su región. Los personajes de la versión 7 recuperan todos los puntos (lo hacía ya `passives_refunded`). Pruebas del árbol puestas al día (maestrías, identidad, formas, vida baja).

### [x] T89b · Generador del árbol 2.0, parte 2: migración y rendimiento · M
Origen: R4 (partida de T89, que era L)
- Migración de personajes: al cargar uno de la versión 7, devolver todos los puntos con un aviso claro («El árbol cambió: tienes N puntos para repartir») y la primera reasignación gratis; el código de build pasa a `PO2:` y avisa si es de un árbol viejo.
- Rendimiento con ~1500 nodos: la vista tiene que seguir dibujando y respondiendo al ratón sin tirones (rejilla espacial, recorte por pantalla y nivel de detalle por zoom); prueba con tiempo de dibujo medido.
- Hecho: un personaje del árbol 7 recupera todos los puntos con un aviso que dice cuántos tiene, y hasta que cierra el árbol con puntos gastados quitar nodos es gratis (`free_respec`). Código de build `PO2:` con las **claves** de los nodos y de las maestrías (sobrevive a regenerar el árbol; avisa si algún nodo ya no existe); un `PO1:` dice que es del árbol viejo. Nivel de detalle en la vista: por debajo de zoom 0,5 los nodos se dibujan lisos (cuadros y círculos, líneas sin suavizado), y desde 0,3 los notables y piedras conservan su icono. Dibujo medido con `capture_screens -- arbol2` (`PassiveTreeView.last_draw_ms`): árbol entero 74 → 14 ms, región 24 → 20 ms, centro 17 ms.

### [x] T90 · Más clusters de las familias que ya hay · M
Origen: R4 (pedido del usuario)
- Cada una de las 28 familias con al menos 4 clusters de tamaños distintos (vida, armadura, evasión, escudo, crítico, fuego, frío, rayo, caos, área, proyectiles, legión, automatización, ignición, sobrecarga, criogenia, toxinas, hemorragia…), con menores que suban de valor del pequeño al grande y notables propios por cluster.
- Notables nuevos con condición o efecto (no solo +%): «con un aliado cerca», «tras esquivar», «contra enemigos con estados», «mientras canalizas», «al gastar cargas»… usando las condiciones que ya existen (low_life, full_life, recent_kill, stationary, three_allies) y las que añada T92.
- Prueba: ninguna familia con menos de 4 clusters, ningún notable repetido, todos los stats conocidos.
- Hecho: `REGION_THEMES` repartidos para que las 28 familias tengan 4 clusters o más (maná 8, nueve familias con 5). 19 notables nuevos en `passive_themes.json`, la mayoría con condición (quieto, vida llena, vida baja, tras matar, con 3 aliados) y cuatro de maná. El generador asigna primero los notables de estilo y las piedras extra y luego nombra, sin repetir: comprueba que ningún notable ni piedra repita nombre (174 únicos), las maestrías se llaman «Maestría: <cluster>» y las constelaciones «Estrella: <nombre>». Prueba `_test_tree_families`.

### [x] T91 · Familia de maná · M
Origen: R4 (pedido del usuario)
- Stats nuevos: **regeneración de maná plana** (maná por segundo que se suma a la base), **% de aumento de la regeneración base** (el que ya existe, bien nombrado), **maná máximo** plano y en %, **daño recibido que se lleva el maná antes que la vida** (en %, como Mente sobre Materia de PoE), maná al golpear y al matar, coste de maná reducido y eficiencia de reserva.
- Lógica en `Player`: el daño que toca al maná se descuenta de él (si no alcanza, lo que falta va a la vida); el orbe de maná y la hoja de personaje (T81) lo muestran; regeneración plana en `_regenerate`.
- Clusters de maná en las regiones de INT y en el anillo central (pequeños de regeneración, medianos de máximo, grandes con notable de «maná antes que vida»), y notables como «Caché caliente» (más regeneración si no lanzaste nada en 2 s) o «Sobrecarga de buffer» (el maná sobrante por encima del 90 % da daño).
- Pruebas: con 30 % al maná, un golpe de 100 quita 30 de maná y 70 de vida; sin maná, todo a la vida; la regeneración plana se suma aunque el maná esté reservado.
- Hecho: stats nuevos `mana_regen_flat` (maná por segundo), `damage_taken_from_mana` (en %, tope 50 %), `mana_on_hit` y `mana_on_kill`; `mana_regen` pasa a llamarse «Regeneración base de maná». Las cuentas van en `ManaMath` (sin nodos): `regen_per_second` (base del 1,75 % del maná sin reserva con sus aumentos, más la plana; nada con Recolector de Basura) y `split_damage`. `Player` descuenta del maná su parte del daño tras el escudo de energía (golpes y degenerativos), recupera maná al matar y, desde `SkillController._leech`, al golpear (`restore_mana`). El orbe de maná muestra la regeneración por segundo y el % que se lleva el maná, y la hoja de personaje una línea de maná. La familia de maná pasa a 12 clusters (4 más en las regiones de INT, quitados a caos, toxinas, escudo y resistencias, que se quedan en 4), con 2 menores nuevos (maná por segundo, maná al golpear) y 4 notables: *Mente sobre Memoria* y *Swap a Disco* (maná antes que vida), *Interrupción por Hardware* (maná al golpear) y *Liberación de Recursos* (maná al matar). «Sobrecarga de buffer» queda para T92 (necesita una condición de maná alto). Prueba `_test_mana_family`.

### [x] T92 · Piedras angulares nuevas · M
Origen: R4 (pedido del usuario)
- 12-15 piedras angulares nuevas con ventaja, contra y su texto de humor, cada una con su lógica (no solo números). Ideas: **Mente sobre Materia** (40 % del daño al maná; sin regeneración de vida), **Pago por Uso** (las habilidades cuestan vida en vez de maná), **Batería Externa** (el escudo de energía protege el maná en vez de la vida), **Zero Trust** (no puedes hacer críticos; el daño no crítico ×1,4), **Monorepo** (todas tus habilidades comparten enfriamiento corto), **Caché Fría** (primer golpe a cada enemigo ×2; los siguientes -20 %), **Contenedor Efímero** (tus invocaciones duran poco pero salen de dos en dos), **Rubber Duck** (hablar con un aliado cercano te cura; sin aliados, -15 % de vida), **Legacy Code** (los objetos de nivel bajo cuentan como de tu nivel), **Pair Programming** (+1 compañero; tu daño -20 %).
- Las cuatro de cluster de T84 pasan a piedras angulares de verdad en el árbol nuevo; las 7 de siempre se conservan.
- Cada una con prueba de su regla (que la ventaja y la contra se apliquen) y aviso en el tooltip si choca con otra.
- Hecho: 12 piedras nuevas en `passive_identity.json` (cada una con su `slot` en el árbol), 16 extra en total con las 4 de T84, 23 con las 7 de clase. Con regla propia en código: **Mente sobre Materia** (40 % del daño al maná, la vida no se regenera sola), **Pago por Uso** (el coste pasa a vida, también al canalizar), **Zero Trust** (sin críticos, ×1,4 de daño), **Caché Fría** (primer golpe a cada enemigo ×2, los demás ×0,8; `EnemyManager.cold_cache`), **Rate Limiting** (ignoras los golpes de los 0,4 s siguientes a otro), **Consistencia Eventual** (la mitad del daño a la vida se cobra en unos 3 s, `Player.deferred_damage`) y **Pato de Goma** (con 3 aliados, 2 % de vida por segundo). Con condiciones: **Buffer Overflow** (condición nueva `high_mana`, maná ≥ 90 %), **Kill -9** (tras matar), **Fail Fast** (vida llena); y **Pair Programming** y **Contenedor Efímero**. Las cuentas puras van en `KeystoneRules`. Choques en `keystone_conflicts` (p. ej. Mente sobre Materia con Pago por Uso, Recolector de Basura y Buffer Overflow; Zero Trust con Tipado Estático y Hotfix): el nodo los lista (`conflicts`) y el tooltip avisa en rojo si ya tienes la otra (`PassiveAllocation.conflicts_with`). Cada piedra ocupa el último notable si su cluster tiene dos, o la pasiva menor más exterior si solo tiene uno. Árbol versión 9 (los personajes recuperan sus puntos). Quedan fuera Batería Externa, Monorepo y Legacy Code (necesitan cambios grandes en escudo, enfriamientos u objetos). Prueba `_test_new_keystones`.

### [x] T93 · Maestrías, estilo y constelaciones en el árbol nuevo · M
Origen: R4
- Una maestría por familia y región (elegir 1 de 3), los 7 notables de estilo de T84 en su sitio nuevo y 6-8 constelaciones en el anillo exterior (una por cada par de atributos y alguna de tres) con bonos que crecen al completarlas.
- Ranuras de chip de expansión repartidas por el árbol nuevo (las de ahora caen donde toque).
- Hecho: 18 maestrías (una por cluster grande, 3 por región), y las de una misma familia ya no repiten opciones: cada una toma otro trío de notables de la familia. Los 7 notables de estilo siguen en el corazón de cada región (T89). Las 6 constelaciones dan además un **bono por completarlas** (`complete` en `passive_identity.json` → `complete_mods` en la estrella; `PassiveAllocation.constellation_complete`, `PassiveTree.constellations`), que el tooltip enseña en gris hasta tenerlas enteras (11 nodos). **18 ranuras de chip** marcadas por el generador (`socket`): el notable de las 12 puertas entre clases y el del cluster B1 de cada región. Al cambiar el árbol, los chips engastados vuelven a la bolsa. Árbol versión 10. Prueba `_test_tree_extras`.

### [x] T94 · Arte del árbol 2.0 · M 🛑
Origen: R4
- Fondo pintado por región (nebulosa procedural con el color de la clase, capas con parallax al mover la vista), marcos de nodo en pixel art por tipo (menor, notable, piedra angular, maestría, constelación), líneas asignadas con flujo animado de luz, placas o medallones en el centro de cada cluster con su icono de familia.
- Nivel de detalle por zoom: de lejos, regiones y clusters (con su nombre); de cerca, iconos y textos. Minimapa del árbol en una esquina con el encuadre actual.
- Animaciones: asignar un nodo hace un pulso que viaja por el camino; completar un cluster o una constelación, destello propio (T85 ampliado).
- Hecho: nueva clase `TreeArt` (cuentas sin nodos). Fondo: dos capas de estrellas fijas y una nebulosa por región con el color de su clase, cada capa con su parallax (0,18, 0,35 y 0,7). Marcos de pixel art por tipo (`TreeArt.frame`): octógono para menores, octógono con remaches para notables, hexágono doble para piedras angulares, rombo para maestrías y estrella de ocho puntas para constelaciones. Las líneas asignadas llevan un destello de luz que las recorre (el árbol se redibuja cada cuadro mientras se ve; 6-16 ms). De lejos (zoom < 0,3), un medallón con el icono de la familia en el centro de cada cluster y el nombre de cada región; nombres de clusters desde zoom 0,25. **Minimapa** en la esquina inferior derecha con las regiones, los clusters, lo asignado y el encuadre; un click en él salta ahí. Al asignar, el brillo recorre el camino tramo a tramo desde lo que ya tenías (`TreeArt.path_depths`), y completar una constelación hace un destello violeta con estrella y su propio sonido. Capturas con `capture_screens -- arbol3`. Prueba `_test_tree_art_v2`.

## Fase 16 — Interfaz

### [x] T95 · Tema de interfaz dibujado · M 🛑
Origen: R4
- Atlas de piezas de interfaz en pixel art (marcos de ventana de 9 partes, botones normal/encima/pulsado/desactivado, casillas de objeto por rareza, barras, pestañas y separadores) generado por herramienta y cargado como `StyleBoxTexture` en `UiStyle`, en vez de cajas planas; listo para cambiar por arte a mano con la misma cuadrícula.
- HUD nuevo con esas piezas: placa de la barra de habilidades, marcos de los orbes, pociones y experiencia.
- Revisar todas las ventanas al 80-160 % con el tema nuevo.
- Hecho: `tools/generate_ui_atlas.gd` genera `assets/sprites/ui/ui_atlas.png` (pixel art a 24 px por celda, ×2): marcos de ventana, panel, recuadro, tooltip, botón normal/encima/pulsado/desactivado, casillas por rareza (normal, mágico, raro, único), marco de barra, pestaña activa e inactiva, separador, placa de la barra de habilidades, marco de poción, campo de texto y, a resolución final debajo de la cuadrícula, el aro de los orbes (96 px). `UiAtlas` da cada pieza como `StyleBoxTexture` de 9 partes (márgenes de 12 px) y `UiStyle` la usa en el tema (botones, paneles, pestañas, tooltips, campos de texto, barras) y en las ventanas, con las cajas planas de antes si falta el PNG. HUD: placa de bronce de la barra, aros dorados en los orbes, marcos de pociones, casillas de habilidades y marco de la experiencia; las casillas de objeto llevan el marco de su rareza. Revisadas las ventanas al 80 y al 160 % (`ventanas80`, `ventanas160`). Prueba `_test_ui_atlas`.

### [x] T96 · Pantallas de título, personajes y carga · M
Origen: R4
- Título con fondo animado (la ciudad de servidores, lluvia de código, el logo con brillo), selección de personaje con el personaje animado en su pose (T72) sobre un pedestal de su clase, pantalla de carga entre zonas con una ilustración de la zona y un consejo.
- Transiciones entre pantallas (fundido, barrido de píxeles).
- Hecho: título con una **ciudad de servidores** en dos capas que se desplazan (edificios-rack con LEDs que parpadean y antenas con luz roja), resplandor del horizonte y un brillo que late detrás del logo. Selección de personaje con el personaje **sobre un pedestal hexagonal** del color de su clase (runas que laten) haciendo su **pose de lucimiento** cada 3,2 s (`AppearancePreview.pose_at`; guerrero con maza, duelista con espada, exploradora disparando, las de INT lanzando, Full Stack con hacha). **Pantalla de carga** al viajar (`LoadingCard`): postal de la zona con el cielo y el suelo de su estilo y una silueta según su borde (racks, montañas, agua, muros, lava, árboles, estrellas o tiendas), nombre, nivel, un consejo de `data/loading_tips.json` (20) y una barra; se queda 0,75 s y se desvanece. **Barrido de píxeles** (`ScreenTransition`) del título al menú y del menú al juego o al creador: cuadros que se encienden en diagonal con algo de ruido, cambio de escena y se retiran. Capturas con `capture_screens -- pantallas` (las demás capturas apagan la pantalla de carga). Prueba `_test_screens_t96`.

### [x] T97 · Animación de la interfaz · S
Origen: R4
- Ventanas que entran y salen con una transición corta, botones que rebotan al pulsar, números de daño con salto y escala (críticos más grandes, apilado de golpes seguidos), barra de experiencia que brilla al subir de nivel y tooltips que aparecen con un fundido. Todo con la opción de reducir movimiento (accesibilidad).
- Hecho: **números de daño** nuevos (`DamageNumbers`, leen `EnemyManager.number_events`): cada golpe saca su cifra, que salta y se encoge; los críticos, más grandes, amarillos y con «!»; los golpes seguidos al mismo enemigo (en 0,35 s) se apilan en una cifra que crece y vuelve a saltar; hasta 60 a la vez; se apagan en Pausa → Interfaz → «Números de daño». Ventanas que entran con un fundido y un zoom corto desde el 96 % (`UiMotion.window_in`, desde `decorate_window`); los botones de `UiStyle.button` rebotan al pulsar; los tooltips de objeto aparecen con un fundido; la barra de experiencia brilla 2,2 s al subir de nivel. Opción nueva **«Reducir movimiento»** (`Accessibility.reduce_motion`): sin zoom ni rebotes, y los números solo suben despacio. Las ventanas no animan la salida (se cierran desde muchos sitios con `visible = false`). Prueba `_test_ui_motion`.

## Fase 17 — Efectos

### [x] T98 · Partículas, luz y posproceso · M
Origen: R4
- Efectos grandes (explosiones, novas, lluvias, auras) con `GPUParticles2D` y presupuesto por pantalla; bloom ligero en las luces, distorsión de calor en el fuego y onda de choque en los golpes grandes.
- Opción de calidad gráfica (baja, media, alta) en Pausa → Gráficos, que ajuste partículas, luces y posproceso; medir con `tools/capture_screens -- rendimiento` en cada nivel.
- Hecho: **calidad gráfica** (`GraphicsQuality`, Pausa → «Calidad gráfica: baja / media / alta»): luces dinámicas 10 / 20 / 32, partículas vivas como mucho 0 / 320 / 900, bloom 0 / 0,5 / 1, distorsión de calor solo en alta, ondas de choque desde media. **Ráfagas de partículas de GPU** (`BigFx`, `GPUParticles2D` de un solo disparo, del color del efecto y hacia fuera) en cada explosión o nova de las habilidades (`SkillController.burst_effects`), con el presupuesto de la calidad. En el shader de luz: **bloom** (halo suave alrededor de las luces, aparte de los escalones), **distorsión de calor** sobre las luces de fuego y **ondas de choque** (anillo que desplaza la imagen, 0,45 s) en los destellos grandes y las explosiones; «Reducir movimiento» apaga calor y ondas. Medido con `capture_screens -- rendimiento` (300 enemigos con explosiones): baja 25,0 ms, media 27,0, alta 27,0 por fotograma (`98_calidad_*`). Las auras y la lluvia siguen con su dibujo de siempre. Prueba `_test_graphics_quality`.

### [x] T99 · Estados y telegrafiados con textura · S
Origen: R4
- Estados animados sobre enemigos y jugador (llamas que suben, escarcha que crece, burbujas de veneno, chispas de electrocución, gotas de sangrado) y avisos de ataque en el suelo con textura y borde animado en vez de formas planas.
- Hecho: clase `FxArt` compartida. Estados: llamas con forma de lengua que suben (quemado), burbujas que suben y revientan con un anillo (veneno y corrupción), gotas con forma de lágrima que caen (sangrado), en enemigos y ahora también en el **jugador** (antes, burbujas genéricas para cualquier degenerativo); la **escarcha del jugador crece** del 35 % al 100 % en el primer medio segundo (`Player._status_since`); chispas y escarcha de los enemigos, como estaban. Avisos: **borde de trazos que gira** en golpes pesados, golpes de área y losas que se rompen, **ondas que se cierran hacia el centro** donde va a caer el golpe, y **flechas que avanzan** a lo largo de conos y cargas (las cargas, además, con sus bordes); se dibujan encima de los rellenos por lotes. Prueba `_test_fx_art`.

### [x] T100 · Ambiente y clima por zona · S
Origen: R4
- Más capas de ambiente: lluvia con salpicaduras en el suelo, polvo en suspensión, niebla que se desplaza, chispas de cables sueltos, LEDs que parpadean en los racks; luces de zona que reaccionan a los golpes.
- Hecho: `Weather` por capas. La lluvia de datos **salpica** (cada gota cae hasta un punto del suelo y deja un anillo aplastado y dos gotitas); capas nuevas por estilo (`EXTRA_BY_STYLE`): **polvo en suspensión** que flota y brilla (ruinas, catacumbas, fábrica, fosa, ROM, grieta, jefes) y **cables que chisporrotean** de vez en cuando (servidores, terminal, fábrica, bus, BIOS, setup); los **LEDs de los racks** del borde parpadean (`Zone.rack_led_points`, verde, ámbar o azul, cada uno a su ritmo). La niebla sigue derivando. Las **luces de la zona reaccionan a los golpes** cercanos (`WorldPost.note_hit`/`hit_kick`: más radio y potencia 0,35 s). Todo se apaga con «Luces y clima reducidos». Prueba `_test_ambience`.

## Fase 18 — Sprites y animación

### [x] T101 · Enemigos con más cuadros y direcciones · M
Origen: R4
- Hojas de sprites por tipo con andar (6 cuadros), atacar (4), recibir golpe (2) y morir (6), mirando a los lados y hacia arriba/abajo; generadas por `tools/generate_enemy_sprites.gd` ampliado (o listas para arte a mano con la misma cuadrícula) y movidas por estado en `EnemyManager` (la `MultiMesh` elige el cuadro por instancia).
- Hecho: nueva cuadrícula `EnemySheet`: 18 columnas (andar 6, atacar 4, golpe recibido 2, morir 6) y tres filas por tipo (abajo, arriba y de lado). `tools/generate_enemy_sprites.gd` dibuja las 4 poses base de cada tipo y de ahí saca cada estado (andar con saltito; atacar: se echa atrás, se encoge, embiste y vuelve; golpe: retrocede con un destello blanco; morir: se desploma, se ladea y se oscurece) y cada dirección (de espaldas más oscuro y sin brillos; de lado, en perfil). `EnemyManager.sprite_frame` elige fila y columna por instancia (preparando o embistiendo → atacar; recién golpeado → golpe; moviéndose → andar; quieto → respira), mirando al jugador si lo persigue o hacia donde va; el shader ya no anima por tiempo. Los cadáveres hacen la animación de morir y se quedan en el último cuadro (sin girarlos). Hoja de 576×2784. Prueba `_test_enemy_sheet`.

### [x] T102 · Personaje del jugador en pixel art por capas · L (partir en dos) 🛑
Origen: R4
- Partida en dos: **T102a** horneado por capas (herramienta, hojas, cuadrícula y composición con los colores del creador) y **T102b** usarlo en el juego, el creador, la hoja de personaje y los retratos (la revisión 🛑 va al final de T102b).
- Hecho T102a: `tools/bake_player_sprites.gd` (sin `--headless`, ~6 s) hornea el dibujo de `CharacterAppearance` en `assets/sprites/player/`: máscaras **body**, **hair** (11 peinados), **beard** (4) y **accessory** (5) —R = luz, G = capa de color (piel, atuendo, detalles, pelo, ojos), alfa— y capas fijas **body_fixed**, **accessory_fixed** y **weapon** (espada, hacha, maza, daga) con su color real. Cada capa sale de comparar dos dibujos iguales salvo por ella; tres pases (colores puros para saber la capa, todo blanco para la luz, colores reales para lo fijo). Cuadrícula en `PlayerSheet`: 32 columnas (reposo 2, andar 6, tajo 4, estocada 4, disparo 3, hechizo 3, canalizar 2, golpe 2, esquiva 3, muerte 3) × 3 direcciones (abajo, arriba, de lado; a la izquierda se voltea), celdas de 64×80 a la escala del juego. `PlayerSprite` las apila (cuerpo, fijos, arma, pelo, barba, accesorio) con el shader `player_layers` y los colores del creador; ancho del cuerpo y estatura al dibujar. `CharacterAppearance` acepta `weapon_class` en la pose (gesto de tajo o estocada sin cambiar el arma). Comparación con el dibujo de siempre: `capture_screens -- capas`. Prueba `_test_player_sheet`.
- Hecho T102b: el **jugador en el mundo** se dibuja con `PlayerSprite` (hijo detrás de su propio dibujo, así el sombrero, la escarcha y las chispas siguen encima; las pisadas y el aura de los logros, en otro hijo debajo), con la pose de cada fotograma, el tinte de golpe y de muerte, y el brillo de las manos al lanzar o canalizar dibujado aparte. El **creador** y la **lista de personajes** usan el mismo sprite (`AppearancePreview.use_sprites`) con su pose de lucimiento. Sin las hojas horneadas, todo vuelve al dibujo con formas. Los **retratos** (diálogos y hoja de personaje) siguen con la cabeza dibujada: necesitan expresiones, parpadeo y boca al hablar que las hojas no tienen, y a ese tamaño el pixel art se vería tosco; el silueta del inventario y los NPC, también como estaban.
- Sustituir el dibujo con formas por sprites por capas (cuerpo, pelo, cara, ropa, arma) en 4 direcciones con los estados de T72 (reposo, andar, correr, golpe por arma, hechizo, canalizar, golpe recibido, esquiva, muerte), coloreados con los colores del creador de personaje.
- El creador, la hoja de personaje y los retratos usan los mismos sprites; con la herramienta para generarlos y la cuadrícula documentada para arte a mano.

### [x] T103 · NPC, jefes y retratos · M
Origen: R4
- Sprites propios para los NPC del campamento y los jefes (reposo animado y gesto al hablar), retratos de diálogo en pixel art y una entrada de jefe con su pose.
- Hecho: los **NPC** del mundo se dibujan con el personaje por capas de T102 (`PlayerSprite`, uno por NPC detrás de su nombre y su «!»), cada uno **respirando** a su ritmo y **gesticulando** con los brazos mientras hablas con él (`Zone.npc_pose`, `Zone.talking_npc`, que pone World con el diálogo abierto); los de monitor siguen en su pantalla de fósforo. **Entrada de jefe** (`BossIntro`): la primera vez que ves a un jefe, una franja cruza la pantalla con su figura grande en su cuadro de embestida (la hoja de T101) y su nombre; entra, se queda 1,6 s y se va, sin pausar. Los jefes ya tienen sus cuadros propios con T101. Los **retratos de diálogo** siguen dibujados con detalle (expresiones, parpadeo y boca al hablar), como se decidió en T102, en vez de pasarlos a pixel art. Capturas con `capture_screens -- jefes`. Prueba `_test_npcs_and_boss_intro`.

### [x] T104 · Objetos en el suelo y cofres · S
Origen: R4
- Cada objeto caído con su sprite (el icono en pequeño, con sombra y un rebote al caer) y brillo por rareza; cofres y contenedores que se abren con animación y sueltan el botín en arco.
- Hecho: cada objeto en el suelo lleva su **icono** pequeño debajo de la etiqueta, con **sombra** y un **brillo** del color de su rareza (mágico en adelante, que late); al soltarse **vuela en arco** desde donde cae (`LootManager.drop_item(item, pos, from)`) o da un saltito en su sitio, **rebota** al aterrizar y su etiqueta aparece cuando ya está en el suelo (`LootManager.arc_pos`, `label_alpha`). **Cajas de servidor** nuevas en las zonas de combate (2-4 por zona, `Zone.containers`): se abren al acercarte con la tapa que se levanta y rebota (`Zone.lid_open`), un fogonazo y chispas, y sueltan 1-3 objetos en arco desde la caja y unos tokens (`World._on_container_opened`); abiertas quedan vacías. Prueba `_test_ground_loot`.

### [x] T105 · Escenarios con tilesets · M
Origen: R4
- Tilesets por estilo de zona con variaciones y bordes (suelo, paredes, transiciones), decoración animada (antorchas, servidores con LEDs, cables que chisporrotean, agua) y objetos de escenario con sombra; generados por herramienta y listos para arte a mano.
- Hecho: `tools/generate_tilesets.gd` escribe en `assets/sprites/tiles/`, para los 23 estilos con suelo en pixel art, `<estilo>.png` (4 baldosas de 128×128 en fila: el suelo de siempre y tres **variantes** con grietas y motas propias que conservan los bordes de la base, así encajan sin costuras) y `<estilo>_edge.png` (**banda del borde** de 128×16 que se repite: el color de fuera entra con un filo irregular, un filo de luz del tipo de borde —racks, roca, agua, muro, lava, maleza, vacío— y una sombra que se desvanece). `ZoneArt` carga esos PNG antes que lo procedural (listos para arte a mano con la misma cuadrícula). En el suelo, ~46 % de las celdas enteras dentro del camino usan una variante (`ZoneArt.cell_variant`) y el contorno del camino lleva la banda hacia dentro (`Zone._draw_edge_strip`). Decoración animada: el agua del borde con ondas que se abren; antorchas, LEDs, racks y cables ya se animan (T100); las cajas de servidor y los obstáculos llevan sombra. Prueba `_test_tilesets`.

# Versión 3.0 del juego — mundo vivo (26-10-2026)

Lo hecho hasta aquí es la **versión 2.0** del juego: copia en la rama `version-2.0` y la etiqueta `v2.0` (commit `b570137`). Los títulos «Roadmap 3.0 / 4.0 / 5.0» de este documento numeran tandas de tareas, no versiones del juego. Va por delante del Roadmap 5.0 (móvil, T106-T110), que se hace después. **Origen: V3** (pedido del usuario). Mismo protocolo; 🛑 = parar y esperar el visto bueno.

Pedido: mejoras de gráficos, interfaz y escenas; zonas que se generan solas para que no se sientan iguales en cada visita; la zona se conserva 10 minutos (botín en el suelo y enemigos) salvo la arena del jefe, que siempre se reinicia entera; mecánicas nuevas y al menos una al azar por zona sin saturarla; tokens que se recogen de más lejos, waypoints que se activan de más lejos (los de campamento al entrar) y fuera los portales de vuelta a actos anteriores: solo se regresa por waypoint.

Punto de partida: cada zona se construye igual siempre (`Zone.setup` siembra con `hash(id)`: bordes, accidentes, obstáculos, decorado, cajas) desde las posiciones fijas de `act*.json`; al viajar o al morir, `World.travel_to` borra la zona, los enemigos y el botín (`enemies.clear_all()`, `loot.clear_all()`) y la levanta de cero. Lo único que cambia por visita son los eventos (`ZoneEvents`, 7 tipos, `event_rng.randomize()`); el `mutex` y la `race_condition` del Acto II son fijos de su zona. Recogida de tokens: `LootManager.TOKEN_PICKUP_RANGE` 34 px e imán `TOKEN_MAGNET_RANGE` 150 px. Waypoint: se descubre a `Zone.WAYPOINT_RADIUS + 60` (106 px). Portales de vuelta: Socket Seguro → Campamento, Puerto JTAG → Socket Seguro y Pila del CMOS → Puerto JTAG (`"portal": true` en `act2/3/4.json`).

## Fase 20 — Viaje y comodidades

### [x] T111 · Tokens desde más lejos · S
Origen: V3
- Recogida directa de ~34 a ~90 px e imán de ~150 a ~380 px (`LootManager`), con el tirón algo más rápido para que no se queden persiguiéndote; que el imán no los saque de detrás de una pared (si el camino recto choca con un obstáculo, rodean o esperan).
- Stat nuevo «radio de recogida de tokens» (+%) en dos o tres afijos de anillo y amuleto y en un notable menor del árbol, con tope.
- Prueba: un token a 300 px acaba en la cuenta sin moverse.
- Hecho: `LootManager.TOKEN_PICKUP_RANGE` 90 y `TOKEN_MAGNET_RANGE` 380, velocidad mínima del imán 420 px/s (`TOKEN_MAGNET_SPEED`); cada paso del imán mira `placement_check` y, si choca, se desliza por un eje o espera (`_magnet_step`). Stat `token_pickup_radius` (Radio de recogida de tokens, %, tope `TOKEN_RADIUS_CAP` = 100, `Player.token_radius_mult`) que agranda los dos radios: sufijo de anillos y amuletos con tres tiers (del Imán de Nevera 10-18, del Electroimán 19-30, del Disco Duro Desmontado 31-45) y un cuarto menor de movilidad, «Movimiento y recogida de tokens» (+2 % movimiento, +10 %), en 5 nodos; árbol regenerado sin cambiar su estructura (misma versión). Prueba `_test_token_pickup`. De paso, dos polígonos que no se triangulaban y tumbaban la integración: las llamas de quemado casi apagadas (`FxArt.flames`) y la cresta de la onda del orbe (`Hud._draw_orb`). La integración sigue con un fallo que ya estaba antes de la tarea (comprobado con `git stash`): pasa a T111b.

### [x] T111b · La cruceta no salta entre nodos del árbol (prueba de mando) · S
Origen: integración de T111
- `test_integration` (`_check_gamepad_cursor`) falla siempre con el guerrero: tras derecha, abajo e izquierda en el árbol pasivo, el cursor vuelve al mismo sitio. Ya fallaba en `b570137`, antes de T111. Averiguar si es la prueba (derecha e izquierda se anulan si abajo no encuentra nodo) o `GamepadCursor.pick_target` / `PassiveTreeView.cursor_targets`, y arreglarlo.
- Hecho: era la prueba. La cruceta funciona (361 nodos a la vista; derecha a (996, 1430), abajo a (996, 1500) e izquierda al nodo de partida, que es el más cercano por ese lado), pero la prueba exigía acabar lejos del inicio. Ahora comprueba que **cada** pulsación salta a otro nodo y, si no, dice los pasos.

### [x] T112 · Waypoints que se activan de lejos y al entrar al campamento · S
Origen: V3
- En las zonas de combate, el waypoint se descubre al tenerlo en pantalla y a ~420 px (en vez de 106), con su aviso y sonido de siempre.
- En las zonas seguras (campamentos), el waypoint se descubre **al entrar**, sin acercarse (`World.travel_to` con `zone.safe`).
- Prueba: entrar a un campamento lo apunta en `flags.waypoints`; quedarse a 400 px del waypoint de una zona de combate, también.
- Hecho: `Zone.WAYPOINT_DISCOVER_RADIUS` = 420 y `Zone.waypoint_in_reach(jugador, waypoint, pantalla)`, que además exige que el waypoint esté dentro de lo que enseña la cámara (`Zone._screen_rect`); `World.travel_to` descubre el waypoint de las zonas seguras al entrar (mismo aviso que al tocarlo). Prueba `_test_waypoint_reach` (distancia y pantalla) y la integración comprueba en cada campamento que su waypoint queda descubierto al entrar.

### [x] T113 · Fuera los portales de vuelta: solo waypoints entre actos · S
Origen: V3
- Quitar las salidas `portal` que llevan al acto anterior (Socket Seguro → Campamento, Puerto JTAG → Socket Seguro, Pila del CMOS → Puerto JTAG). Se quedan las que llevan hacia delante (Portal al Kernel del Campamento, portales de las arenas de jefe al siguiente campamento).
- La ventana de waypoints ya enseña todos los actos con algún waypoint descubierto: comprobar que desde cualquier campamento se viaja a los de actos anteriores, y que las misiones, diálogos, escenas, el editor de historia y la integración no dependen de esos túneles.
- Guardados viejos: si un personaje está en un acto posterior sin el waypoint del campamento de un acto anterior que ya terminó, dárselo al cargar.
- Hecho: fuera los túneles Socket Seguro → Campamento, Puerto JTAG → Socket Seguro y Pila del CMOS → Puerto JTAG, y también las dos **salidas a pie** que volvían a la arena del jefe del acto anterior (Controladora de Bus → Anillo 0, POST → Cámara de Reflasheo), para que de verdad solo se vuelva por waypoint. Se quedan los portales hacia delante y los de cada arena a su propio campamento. Misiones, diálogos, escenas y la integración no dependían de ellos. `Zone.reached_towns(actos, flags, acto_de_la_zona)` dice qué campamentos ha alcanzado el personaje (hasta el acto donde está y el siguiente a cada `actN_complete`) y `World._grant_town_waypoints` se los da al cargar. Prueba `_test_no_back_portals`: ninguna salida de ninguna zona lleva a un acto anterior, más la migración.

## Fase 21 — Zonas que se generan solas

### [x] T114 · Diseño del generador de zonas · M 🛑
Origen: V3
- Documento `docs/zonas_3.md`: qué cambia en cada instancia (forma del camino, obstáculos y accidentes, manadas, cajas, decorado, lado y sitio de las salidas, sitio del waypoint) y qué se queda fijo (lado de la entrada y orden de las zonas del acto, NPC, objetos de misión en una «sala» propia, arenas de jefe y campamentos, que no se generan).
- Plantillas de forma por estilo (salas y pasillos, cueva orgánica, plaza abierta con islas, laberinto de racks…) con tamaño variable (±15 %) y garantías: todo conectado, la salida lejos de la entrada, el waypoint y los objetos de misión alcanzables.
- Prototipo en `capture_screens` que dibuja 5 semillas de cada zona para la revisión.
- Hecho: `docs/zonas_3.md` con el reparto de lo que cambia y lo fijo, la representación (rejilla de 80 px en vez de los cuatro bordes ondulados, y qué hay que adaptar en T115), las cuatro plantillas por estilo, el algoritmo paso a paso, las garantías y **seis preguntas para la revisión**. Prototipo `ZoneLayout` (aún sin usar en el juego): plantillas `salas`, `cueva`, `plaza` y `racks`, mordiscos en el contorno, salidas en su lado y separadas, entradas junto a su salida, waypoint entre entrada y salida, NPC y objetos en rincones propios, pasillos entre todos los puntos clave y fuera lo inalcanzable. Campamentos, jefes, incidentes y el tutorial quedan fijos. `capture_screens -- semillas`: 22 zonas × 5 semillas, 0 fallos de garantía, 12 ms de media por zona (66 la más lenta); imágenes en `docs/capturas/zonas_3/`. Prueba `_test_zone_layout`. **Aprobado** (26-10-2026) con las respuestas por defecto del documento: plantillas de la tabla, tutorial fijo, ±15 %, salas y racks con proporciones distintas, waypoint entre entrada y salida, muros con el estilo del borde de la zona.

### [x] T115 · Generador, parte 1: semilla por instancia y disposición · M
Origen: V3
- `Zone.setup` recibe una semilla de instancia (no `hash(id)`); bordes, accidentes, obstáculos, decorado y cajas salen de ella. Salidas, waypoint, objetos de misión y lore se recolocan en puntos válidos de la plantilla, respetando el lado de cada salida.
- Comprobación de conectividad (relleno por inundación sobre la colisión) y regenerar si falla.
- Pruebas: 50 semillas por zona, todas conectadas, sin nada encima de un obstáculo; la integración rápida juega con semillas al azar.
- Hecho: `Zone.setup(..., p_seed)`; con semilla, las zonas de `ZoneLayout.applies_to` se generan y trabajan sobre una **copia** de su definición con las posiciones de la instancia (`ZoneLayout.remap_def`: tamaño, salidas, entradas, waypoint, NPC, objetos de misión, pruebas, objetos clave; decorado, puntos extra, mutex y race condition en proporción y al suelo más cercano), así `World` y el resto leen lo correcto sin tocar los datos globales. Lo transitable (`is_walkable`, `clamp_to_walkable` → `ZoneLayout.point_ok` / `clamp_point`, barato), la colisión (rectángulos de muro), el suelo (rectángulos con la baldosa, variantes, banda del borde en cada frontera suelo/muro), los adornos del borde, el minimapa y el mapa grande usan la rejilla; obstáculos, accidentes, decorado, antorchas y cajas salen de la semilla. **Conectividad**: relleno en celdas de 40 px sobre suelo y obstáculos desde la entrada; si un punto clave no se alcanza, fuera los obstáculos que no estén en un claro amplio y, si aún falla, todos (en vez de regenerar la zona entera). `World.travel_to` pasa una semilla nueva en cada viaje (T118 la conservará). Lo explorado del mapa grande no se guarda en las zonas generadas (cambian de forma). De paso, `ZoneLayout` separa mejor dos salidas del mismo lado (se queda con el mejor intento). Pruebas `_test_generated_zones`: 50 semillas por zona de la rejilla y 3 por zona con la zona entera (puntos clave sobre suelo, fuera de obstáculos y alcanzables; la definición original intacta; el campamento no se genera); ~16 s. Capturas en `docs/capturas/zonas_3/115_*`. Pendiente para T116: las marcas propias del mapa (T53) siguen guardadas por zona y no se borran al cambiar de instancia.

### [x] T116 · Generador, parte 2: plantillas de forma por estilo · M
Origen: V3
- Las plantillas de T114 en el juego, una o dos por estilo; la zona puede salir más larga, más ancha o con un rodeo.
- Minimapa, mapa grande y marcas propias (T53) con la forma nueva; las marcas se borran al cambiar de instancia.
- Hecho: las plantillas, el minimapa y el mapa grande ya estaban en el juego desde T115. Nuevo en `ZoneLayout`: **variante de forma** (`shape`: normal ±15 %, «larga» +20-30 % de largo o «ancha» +20-30 % de alto, 20 % cada una), **rodeo** (`detour`, 30 %: cresta de muro de lado a lado, perpendicular a la marcha y lejos de los puntos clave, con un paso de 5 celdas en un extremo) y **pasillos por el camino más barato** (`AStarGrid2D`: suelo 1, cavar 8, cresta 80), así la cueva sigue siendo cueva, los racks no se cortan con zanjas rectas y el rodeo se respeta. **Marcas del mapa** ligadas a la instancia (`WorldMap._forget_old_marks`, `flags["marks_seed_<zona>"]`): se quedan con la misma semilla y se borran con otra. `capture_screens -- semillas` dice forma y rodeo; 110 disposiciones, 0 fallos, 12 ms de media; imágenes actualizadas en `docs/capturas/zonas_3/`. Prueba `_test_zone_shapes` (las tres formas salen, la cresta del rodeo queda en pie ≥ 90 %, marcas por instancia).

### [x] T117 · Generador, parte 3: contenido que varía · M
Origen: V3
- Manadas por «tema» de instancia (la mezcla de tipos de la zona varía: más de uno, menos de otro), élites y raros en sitios distintos, cajas, decorado y algún rincón opcional con botín.
- Variante de ambiente por instancia (niebla, lluvia de datos, apagón parcial, polvo) dentro de lo que permite el estilo.
- Que el nivel de zona, la densidad media y la experiencia por zona no cambien (medir con la telemetría de T64).
- Hecho: todo sale de la semilla en `ZoneLayout._make_content` (así T118 reproduce la instancia). **Tema**: `type_weights` (un tipo ×3, otro ×0,35, el resto ×1) que usa `World._spawn_zone_enemies` con `ZoneLayout.pick_weighted`, y `elite_mult` 0,7-1,3 (media 1) sobre la probabilidad de élite. Las manadas ya caían en sitios al azar; ahora también los **raros de posición fija** (`rare_spawns`: fosa, memoria ROM) van a un sitio apartado distinto en cada instancia (T115 no los recolocaba). **Rincón con botín** (50 %): callejón lejos de todo punto clave con una **caja rica** dorada que late (3-5 objetos con más rareza y el triple de tokens). **Ambiente**: la mitad de las veces otro tiempo dentro del estilo (niebla o nada en los orgánicos, lluvia de datos o nada en los técnicos), polvo de más (30 %) y **apagón parcial** (20 %, +0,18 de oscuridad y menos radio de luz: `WorldPost.set_style(estilo, extra_dark)`, `Weather.setup(..., variant)`). Las cajas y el decorado ya variaban con la semilla desde T115. **Nivel, manadas y experiencia**: el nivel no se toca y el número de manadas y su tamaño son los mismos (prueba), así que la experiencia por zona se mantiene salvo por el tipo que abunda; la densidad por pantalla varía con el tamaño de la instancia (±15-30 %), que es lo buscado. No se midió con la telemetría (solo escribe con personajes guardados y la integración no los usa). Prueba `_test_zone_content`.

## Fase 22 — Instancias que duran 10 minutos

### [x] T118 · Instancias, parte 1: la zona y el botín se conservan · M
Origen: V3
- Registro de instancias en `World` (en memoria, no en el guardado): semilla, botín y tokens en el suelo, cajas abiertas, lore recogido, marcas del mapa y la hora a la que se salió. Al volver (por salida, waypoint o tras morir) antes de 10 min, la misma instancia; después, una nueva. Varias instancias a la vez (tope de ~8, se descarta la más vieja).
- El reloj corre en tiempo de juego mientras la partida está abierta (pausa incluida); al salir al menú o cerrar el juego, se pierden.
- No aplica a campamentos (no se generan), ni a oleadas ni pruebas de estrés (se reinician siempre).
- Hecho: `ZoneInstances` (en memoria, `TTL` 600 s desde que sales, `MAX` 8 con la más vieja fuera; el reloj lo pone quien llama). `World.travel_to` guarda la zona generada al salir (`_store_instance`: semilla, objetos y tokens del suelo, índices de las cajas abiertas, lo explorado del mapa) y, si hay una viva, entra con su semilla y la restaura (`_restore_instance`; la misma semilla da las mismas cajas en el mismo orden). Reloj: `Time.get_ticks_msec` (corre en pausa; al salir al menú se pierde con el `World`). El lore ya se guardaba en el personaje y las marcas del mapa van con la semilla (T116), así que se conservan solos. Las pruebas de estrés no guardan estado y se cancelan al salir; el **banco de oleadas** no se genera (desde T115 se estaba generando por error: `ZoneLayout.applies_to` excluye `waves_mode`). Los enemigos todavía reaparecen enteros: T119. Pruebas `_test_zone_instances` (caducidad, tope, misma semilla = mismas cajas) y en la integración `_check_instances` (soltar objeto y tokens y abrir una caja en la zona 1, ir al campamento y volver: misma zona y todo sigue; tras caducar, sin el botín).

### [x] T119 · Instancias, parte 2: enemigos, eventos y mecánicas · M
Origen: V3
- `EnemyManager` guarda y restaura los enemigos vivos (tipo, rareza, afijos, rol, vida, posición) y no vuelve a sacar los muertos; el némesis, si estaba, sigue ahí. Los eventos y la mecánica de zona (Fase 23) vuelven en el estado en que se dejaron.
- **Excepción, la arena del jefe**: al morir o salir, el jefe vuelve a la fase 1 con la vida completa, sin adds, con las mecánicas de arena y la música reiniciadas; lo que haya caído al suelo en la arena sí se conserva.
- Tiempo que le queda a la instancia en la ventana de waypoints y en el minimapa («caduca en 7:32»).
- Prueba: morir con botín en el suelo y 20 enemigos vivos, volver y encontrar los mismos; pasados 10 min, zona nueva; morir en la fase 3 del jefe y volver a la fase 1 con la vida llena.
- Hecho: `EnemyManager.snapshot(skip_ids)` / `restore(lista)` guardan y devuelven a los vivos (posición, vida, rareza, tipo, nombre, inmunidad y `traits` con afijos, rol y némesis, habilidades y fases de jefe; sin estados alterados ni la acción en curso). `World._store_instance` los guarda con la instancia y, al volver, `travel_to` los restaura en vez de sacar manadas nuevas; los **gemelos de la Carrera Crítica** no se guardan (World los sigue por id) y se crean de nuevo con `_spawn_race_condition`, separado de `_spawn_zone_specials`. **Eventos**: se guarda su lista; los que estaban a medias (oleadas de datos huérfanos, bombas, escolta) quedan cerrados, porque su pelea apuntaba a ids que ya no existen. **Arena del jefe**: se guarda solo el botín del suelo y el jefe sale siempre de cero (fase 1, toda la vida, sin adds; la música y las mecánicas de arena se reinician con la zona). **Tiempo**: la ventana de waypoints pone «como la dejaste 7:32» en cada zona con instancia viva (`ZoneInstances.times`, `ZoneInstances.clock`). En el minimapa no se pone: mientras estás dentro la instancia no caduca (el reloj empieza al salir), así que solo tiene sentido al elegir destino. Las mecánicas de zona (Fase 23) aún no existen: T120 tendrá que guardar su estado con la instancia. Pruebas: en `_test_zone_instances`, guardar y restaurar enemigos (excluidos fuera, vida, rol, rareza y nombre) y el reloj; en la integración (`_check_instances`), quitar 5 enemigos y herir a otro en la zona 1, ir al campamento y volver con los mismos, y en la arena del jefe dejarlo al 20 % con un objeto en el suelo, salir y volver: jefe con toda la vida y el objeto sigue.

## Fase 23 — Mecánicas de zona al azar

### [x] T120 · Motor de mecánicas de zona · M
Origen: V3
- Catálogo `data/zone_mechanics.json` (peso, estilos y actos donde puede salir, nivel mínimo, recompensa) y presupuesto por instancia: **una mecánica principal siempre** y como mucho un evento menor de los de `ZoneEvents`; nunca dos principales. El `mutex` y la `race_condition` del Acto II cuentan como la principal de su zona.
- Al entrar, aviso con el nombre y una frase; icono en el minimapa y consejo de primera vez (`TipPanel`). Recompensa al completarla (botín extra o tokens), sin castigo si se ignora.
- Integración: cada zona prueba cada mecánica que le puede tocar.
- Hecho: `data/zone_mechanics.json` (principales con nombre, frase, peso, estilos, actos, nivel mínimo, tipo —`event` la pone ZoneEvents, `fixed` la trae la zona— y recompensa; menores con su peso y `minor_chance` 0,6) y `ZoneMechanics.plan(def, rng, flags, acto)`. Hasta que lleguen las de T121-T122, las principales al azar son los eventos con objetivo que ya había (**Bombas lógicas**, **Proceso perdido** y **Deploy fallido**) y las fijas el **Mutex** y la **Carrera Crítica** (mientras su bandera no esté puesta; superadas, le toca otra). `ZoneEvents.setup(zone, rng, plan)` pone solo la principal (marcada `main`) y el menor: antes salían **2-7 eventos por zona**, ahora 1-2 (pesos de `ZoneEvents.WEIGHTS` al catálogo; una escolta principal sin sitio para el viaje pasa a deploy). El reparto sale de la semilla de la instancia (así T119 la repite) y su estado vuelve con los eventos guardados. Al entrar, aviso dorado «Nombre — frase» (no se repite si ya se completó en la instancia) y consejo `zone_mechanic`; rombo dorado en el minimapa (`Minimap.mechanic_points`: el evento, o los puntos del mutex o de la carrera); al completarla, `World._mechanic_reward` suelta el botín extra del catálogo. Comprobación: en vez de jugar cada mecánica de cada zona en la integración (que juega una al azar por zona y clase), `test_core` coloca en cada zona cada principal que le puede tocar (`_test_zone_mechanics`, >40 colocaciones) y revisa el reparto con 20 semillas por zona.

### [x] T121 · Mecánicas nuevas, parte 1 · M
Origen: V3
- Tres principales con su arte y sonido, por ejemplo: **Garbage Collector** (un barrido recorre la zona cada cierto tiempo y daña a todo lo que pilla, enemigos incluidos; se esquiva o se usa), **Apagón del CPD** (la zona a oscuras salvo tu radio y luces de emergencia que se encienden al pasar) y **Ticket urgente** (élites marcados que hay que tumbar antes de que acabe la cuenta atrás).
- Hecho: tres tipos nuevos en `ZoneEvents` y en `data/zone_mechanics.json`. **Garbage Collector** (`gc`, de toda la zona, activo al entrar): espera 16 s, aviso de 2,2 s (línea turquesa discontinua que parpadea en el borde, flechas y «GC en 1,5 s», alarma con `Sfx`) y barrido a 620 px/s en el sentido largo de la zona, de ida y vuelta, que golpea **una vez** a cada uno que pille: el 16 % de la vida máxima al jugador (la esquiva lo evita) y el 45 % de la suya a cada enemigo menos a únicos y jefes (así se puede usar); franja turquesa con núcleo blanco y `free()` que se desprenden; tras 5 pasadas termina con botín. **Apagón del CPD** (`blackout`, de toda la zona): +0,42 de oscuridad que baja con cada una de las 6 luces de emergencia (farola con piloto rojo que parpadea y una luz roja débil; al pasar a 120 px se enciende en blanco con luz grande, vía `Zone.light_points`); todas encendidas: completada y vuelve la luz normal. **Ticket urgente** (`ticket`, consola): al tocarla, `World._mark_ticket_targets` saca 3 élites «[P1]» con escolta repartidos por la zona y cada uno lleva su etiqueta con la cuenta atrás (2:00); todos muertos a tiempo: éxito; si no, «won't fix» y pierden la marca. Las de toda la zona siguen como estaban al volver a la instancia (`ZoneEvents.INTERRUPTIBLE` deja fuera `gc` y `blackout`). Consejo de primera vez propio (`mech_gc`, `mech_blackout`, `mech_ticket`). El sonido usa los efectos que ya había con otro tono (alarma, encender, oleada). Capturas `capture_screens -- mecanicas` en `docs/capturas/mecanicas/`. Prueba `_test_new_mechanics_t121`.

### [x] T122 · Mecánicas nuevas, parte 2 · M
Origen: V3
- Otras tres: **Merge conflict** (dos bandos de enemigos que se pelean entre sí si se cruzan), **Deploy de viernes** (oleadas que entran por la salida hasta cerrar el pipeline en un terminal) y **Caché caliente** (baldosas que dan un bono corto al pisarlas y se mueven).
- Ajustar pesos y recompensas con la telemetría para que ninguna domine ni se haga pesada.
- Hecho: tres tipos más de toda la zona en `ZoneEvents` (`ZONE_WIDE`: siguen como estaban al volver a la instancia). **Merge conflict** (`merge`): al ver a los enemigos los reparte en dos ramas por tipo (o alternando si hay un tipo; únicos y jefes fuera) en `traits["branch"]` (aro rojo HEAD o verde main bajo cada uno); cada 0,3 s los que están a más de 450 px de ti buscan al más cercano de la otra rama (se acercan si está a menos de 380 px) y, al tocarse, se quitan un 7 % de su vida máxima con marcas `<<<<<<<` `=======` `>>>>>>>` que saltan; 12 bajas entre ramas lo resuelven (las muertes dan experiencia). **Deploy de viernes** (`friday`): terminal del pipeline lo más lejos posible de la entrada; cada 24 s (hasta 6) entra una oleada junto a una salida (`friday_wave` → `World._on_friday_wave`), y quedarse 3 s en el aro del terminal lo cierra (el progreso baja si te vas). **Caché caliente** (`hot_cache`): 5 baldosas con rejilla de «líneas de caché» del color de su bono (Cache hit +35 % de daño, Caché precalentada +30 % de velocidades, L1 +60 % de armadura; 6 s), se enfrían 4 s al pisarlas y cambian de sitio (también solas cada ~12 s); 8 usos la completan. Consejos `mech_merge`, `mech_friday`, `mech_hot_cache`. **Pesos**: sin telemetría de partidas reales (la local solo escribe con personajes guardados), se igualaron a mano en 15-20 para las nueve principales al azar, de modo que ninguna pasa del 20 % del reparto (prueba); las recompensas, entre 2 y 3 objetos y 1,5-2,5× de tokens según lo que piden. Capturas en `docs/capturas/mecanicas/` (el modo `capture_screens -- mecanicas` hace invulnerable al personaje). Prueba `_test_new_mechanics_t122`.

## Fase 24 — Gráficos

### [x] T123 · Salas temáticas en las zonas generadas · M
Origen: V3
- «Set pieces» por estilo que el generador puede insertar (rack caído con cables, cementerio de commits, sala de backups inundada, altar del becario…), con decorado propio, luz y a veces una caja o un lore.
- Hecho: `ZoneLayout.set_pieces` (de la semilla: se repiten en la instancia): 1-2 por instancia, de las que pegan con el estilo (`SET_PIECES`: **rack caído**, **cementerio de commits**, **sala de backups inundada**, **altar del becario** —en cualquier estilo— y **servidor legacy**), en un claro de 3,2 celdas de radio lejos de los puntos clave, del rincón con botín y entre ellas; si no hay claro (racks densos), se abre un disco de suelo alrededor de una celda alcanzable. `Zone` las cuenta como puntos clave (sin obstáculos ni manadas encima), las dibuja en la capa estática (cables y servidores sueltos; lápidas con hash y epitafio de commit; agua con cintas LTO y discos; mesa con monitor «Hola mundo», taza, velas y post-its; torre beige con CRT y el cartel «NO TOCAR · FUNCIONA (1998)») con los textos en la capa de etiquetas para que se lean, les da su luz (`SET_PIECE_LIGHTS`), el rack caído pone un rack de verdad que estorba, el 40 % trae una caja y el 50 % se queda con una nota de lore de la zona. Capturas `capture_screens -- salas` en `docs/capturas/salas/`. Prueba `_test_set_pieces`.

### [x] T124 · Profundidad y lectura del escenario · M
Origen: V3
- Obstáculos altos que se vuelven translúcidos cuando el jugador o un enemigo élite queda detrás; sombras que siguen a las luces de la zona; capa de fondo con parallax más allá del borde (vacío, abismo, agua).
- Manchas que se quedan en el suelo (aceite, chispas quemadas, restos) y se conservan con la instancia; medir el coste con `capture_screens -- rendimiento`.
- Hecho: **translúcidos**: los obstáculos altos (`Zone.TALL_OBSTACLES`) se dibujan al 40 % si el jugador o un élite a la vista está detrás (dentro del sprite y por encima de su base, `Zone.hides_someone`). **Sombras**: la de cada obstáculo se estira y gira lejos de la luz fija más cercana a menos de 460 px (antorchas, salas temáticas, hoguera; `Zone.shadow_dir`), más larga cuanto más cerca. Las luces de los aliados y los efectos no proyectan sombra (solo las fijas, por coste). **Parallax**: donde «fuera» es vacío, abismo, agua o lava (`PARALLAX_EDGES`; no muros, racks ni maleza, que son sólidos), una capa detrás del suelo sustituye al relleno liso y se mueve al 45 % de la cámara con bits y rejilla lejana, rocas en la profundidad, ondas lentas o brasas que laten (en las zonas generadas también se ve entre los muros de esos estilos). **Manchas**: cada enemigo que cae deja la suya según su material (aceite, restos, glitch o esquirlas; `Zone.add_stain`, tope 260), se dibujan bajo los obstáculos y se guardan con la instancia (T118). **Coste** (`capture_screens -- rendimiento`, A/B con `git stash`): sin T124, 150 enemigos 17,50 ms y 300 enemigos 35,81 ms; con T124, 17,46 y 34,71 ms: dentro del ruido. Capturas `capture_screens -- profundidad` en `docs/capturas/profundidad/`. Prueba `_test_scene_depth`.

## Fase 25 — Interfaz

### [x] T125 · Minimapa con niebla que se descubre · M
Origen: V3
- Con zonas que cambian, el minimapa y el mapa grande empiezan en niebla y se descubren al pasar; lo descubierto se guarda en la instancia. Salidas y waypoint aparecen al verlos.
- Hecho: el mapa grande ya tenía niebla, ya solo enseñaba salidas y waypoint explorados (T53) y desde T118 lo explorado de una zona generada va con su instancia (y no se carga de otra). Faltaba el minimapa, que enseñaba todo y señalaba con flechas salidas y waypoint sin haberlos visto: ahora usa la misma rejilla de 160 px del mapa grande (`Minimap.seen`, `_draw_fog`): las celdas sin explorar se tapan del color del fondo (recortadas al círculo en el borde) y salidas y waypoint (y sus flechas) solo salen si están en terreno visto. El rombo de la mecánica de la zona se ve siempre (es una guía, T120). Coste: el primer intento subió el `_draw` del minimapa de ~1,0 a ~1,75 ms; con los trozos de niebla en caché (se rehacen al moverse 32 px o al descubrir algo; mientras tanto se desplazan) queda en 1,07-1,19 ms. Captura `docs/capturas/zonas_3/125_minimapa_niebla.png`. Prueba `_test_minimap_fog`.

### [x] T126 · Ventana de waypoints como mapa del acto · M
Origen: V3
- En vez de la lista: el mapa de cada acto con sus zonas unidas, el waypoint descubierto o no, la mecánica y el tiempo de la instancia viva y pestañas por acto (ahora es la única forma de volver atrás); con ratón, mando y toque.
- Hecho: `WaypointPanel` reescrita: pestañas por acto (solo los que tienen algún waypoint descubierto; se abre en el tuyo; la abierta en color de acento) y un mapa de 1040×430 con un botón por zona colocado por `Zone.act_map_layout` (columna = salidas desde el campamento en anchura, sin contar los portales, que son teletransportes; filas por orden de los datos) y líneas entre zonas unidas (doradas si conoces las dos). Cada botón (`WaypointPanel.node_text`): nombre o «???» si no la has pisado (`flags["visited"]`, nuevo; los guardados viejos cuentan como visitadas las zonas de los actos terminados), nivel, «waypoint» o «waypoint sin descubrir», «(aquí)» y, con instancia viva, «como la dejaste 7:32 · Mecánica» (la mecánica se guarda ahora con la instancia, `ZoneInstances.values`); solo se pueden pulsar las de waypoint descubierto; la arena del jefe en rojo; el texto se recorta con puntos suspensivos y entero en el tooltip. Al ser botones, sirven el ratón, el toque y el cursor de mando (que salta entre botones). La ventana recibe los actos (`open(..., acts)`) para no depender del autoload. Capturas `capture_screens -- waypoints` en `docs/capturas/zonas_3/126_*`. Prueba `_test_waypoint_map`.

### [x] T127 · Comparar placas y RAM con lo equipado · S
Origen: pendiente de T70/T71
- Al pasar el ratón por una placa o RAM (tienda, suelo, alijo, inventario), su tooltip al lado del de lo equipado en esa ranura con las diferencias en verde y rojo (DPS de la habilidad, coste, área…).
- Hecho: `ItemTooltip.wants_compare` (equipo, placas y RAM) en la tienda, el suelo, el alijo y la bolsa del inventario (también con Alt). **Placa**: se compara con la de la misma habilidad en tu barra (`board_rival`; la «ranura» de una placa es su habilidad), que sale al lado como «Equipado ahora», y abajo «Frente a la de tu barra:» con DPS, coste de maná, usos/s, radio, proyectiles, enfriamiento, nivel y ranuras de antes → después y su %, en verde lo que mejora y en rojo lo que empeora (el coste y el enfriamiento, al revés); si no llevas esa habilidad, lo dice. **RAM**: como no tiene una ranura fija, «En tus placas:» con el DPS de cada placa de la barra que la admite si la instalas en una ranura libre de su generación (o «sin ranura DDRx libre»), como ya hacía el menú K al seleccionarla. Capturas `capture_screens -- comparar` en `docs/capturas/interfaz/`. Prueba `_test_board_compare`.

### [x] T128 · HUD de la zona y registro de sucesos · S
Origen: V3
- Rótulo de la zona al entrar con la mecánica activa; panel lateral plegable con lo que pasa (botín único y raro, waypoint descubierto, mecánica completada, instancia que caduca), y aviso 1 min antes de que caduque la instancia en la que tienes botín.
- Hecho: el rótulo grande de la zona (`Zone.banner_text`) añade «◆ Mecánica» bajo el nivel. **Registro** (`EventLog`, a la izquierda bajo la línea de depuración): lo más nuevo arriba, 7 a la vista y 40 guardados; se pliega con un click (o toque, o el cursor de mando) en su cabecera «[–] Registro» y plegado cuenta «[+] Registro (3 nuevos)»; se oculta, como el minimapa, si una ventana se le encima, y en las escenas y el árbol. Entra: equipo raro o mejor al caer (`LootManager.dropped`, señal nueva; restaurar una instancia no lo repite), waypoint descubierto, mecánica completada y la instancia que caduca. **Aviso de caducidad**: `World._check_expiring` mira cada segundo `ZoneInstances.expiring` y, una sola vez por instancia, cuando a una zona con botín o tokens en el suelo le queda menos de un minuto, lo dice en pantalla y en el registro (no si estás en ella). Los triángulos ▾/▸ no están en la fuente: `[–]`/`[+]`. Captura `capture_screens -- registro` en `docs/capturas/interfaz/`. Prueba `_test_event_log`.

## Fase 26 — Escenas

### [x] T129 · Escenas con dirección · M
Origen: V3
- `CutscenePlayer` con pasos nuevos: paneo y zoom de cámara, temblor, personajes que caminan y se giran en la escena, bandas de cine y retrato con expresión por línea; repasar las escenas existentes para usarlos.
- Saltar la escena entera o línea a línea, con ratón, mando y toque.
- Hecho: pasos nuevos en `CutscenePlayer` (documentados en su cabecera y en el `_doc` de `cutscenes.json`): **camera** (`to`: player, npc:<id>, boss, exit:<destino> o [x, y]; `zoom`; `time`; con entrada y salida suaves, y al acabar o saltar la escena vuelve sola, zoom incluido), **walk** (`who` un NPC o el jugador; `to` como camera o {by: [dx, dy]}; mira hacia donde va), **turn** (un NPC mira a izquierda, derecha o a ti: `facing_override`, que ahora respeta el dibujo de los NPC en `Zone`), **bars** y **bandas de cine** que entran solas en todas las escenas (salvo `"bars": false`); el temblor ya existía y se suma a la cámara. **Expresión por línea** (`expression`: happy, angry, sad, surprised, worried) en `CharacterPortrait.EXPRESSIONS` (sonrisa y cejas). **Saltar**: línea a línea con click, toque, Espacio o la A del mando; la escena entera con Esc, la B del mando o el botón «Saltar escena (Esc)» arriba a la derecha (para ratón y toque). Repasadas: la muerte del Arquitecto, la entrada de init y la de admin (la cámara se acerca al jefe con zoom y vuelve contigo para tu réplica o la radio) y la reunión del campamento (cámara a quien habla, caras por línea, Kevin se gira y Rafa camina hacia ti). La escena de la prueba de cámara no se probó con el prólogo (no tiene zona: los pasos de cámara ahí no hacen nada). Capturas `capture_screens -- escenas` en `docs/capturas/escenas/`. Prueba `_test_cutscene_direction`; de paso, una prueba de T121 que dependía de no esquivar al azar ya no falla de vez en cuando.

### [x] T130 · Escenas que faltan · M 🛑
Origen: V3
- Llegada a cada campamento por primera vez y derrota de cada jefe (epílogo corto antes del portal), en `cutscenes.json` y con el humor del juego (`docs/lore.md`).
- Hecho: cuatro **llegadas** (`llegada_campamento`, `llegada_socket`, `llegada_jtag`, `llegada_cmos`) con cámara hacia quien habla y caras por línea, y cuatro **epílogos** (`arquitecto_epilogo`, `init_epilogo`, `reflash_epilogo`, `admin_epilogo`) con la cámara en el portal y los NPC del campamento por radio. `cutscene_on_enter` acepta ahora una lista con `requires_flag`, `unless_flag` (uno o varios) y `set_flag`, y la elige `Zone.pick_entry_cutscene`: la llegada sale una vez y no si ya completaste ese acto, y en el campamento del Acto I convive con la reunión. Los epílogos se encadenan tras la muerte del jefe con `on_finish.cutscene` (después del viaje, si lo hay). Se cambiaron «becario» por «practicante» y «veintiséis» por «26» para pasar la prueba de español latino. Capturas `capture_screens -- llegadas`. Prueba `_test_missing_scenes`, y `_test_cutscenes` valida listas y escenas encadenadas.

## Fase 27 — Cierre de la versión 3.0

### [x] T131 · Revisión de la versión 3.0 · S 🛑
Origen: V3
- Integración completa (30 s por zona, una sola vez al final), capturas de cada fase nueva, `README.md` al día y etiqueta `v3.0` en git.
- Hecho: la primera integración completa dio dos «no hubo combate» al azar (exploradora en `zona2` y templario en `sector_oculto`), sin errores del motor: el piloto de la prueba caminaba en línea recta hacia el enemigo más cercano y en las zonas generadas se quedaba empujando una pared. Ahora sigue la rejilla de `ZoneLayout` con A* (`_next_step` en `tests/test_integration.gd`); repetida, la completa pasa entera (219 combinaciones de clase y zona, scripts y lógica en `[OK]`). Capturas de cada fase en `docs/capturas/` (`zonas_3`, `salas`, `mecanicas`, `profundidad`, `interfaz`, `escenas`, con las llegadas de T130). En el `README.md`, un párrafo de versiones arriba (2.0 y 3.0). Etiqueta `v3.0` en git.

---

# Roadmap 5.0 — versión para celular (26-10-2026)

Pedido del usuario: generar el APK para celular. Hoy el juego no se puede jugar en un teléfono: las habilidades, la esquiva y las pociones van con teclado (Q W E R T Y, Espacio, 1-5), muchas ventanas dependen de pasar el ratón por encima y el proyecto usa el renderizador de escritorio (Forward+). Antes de exportar hay que prepararlo para pantalla táctil. **Origen: R5.** Mismo protocolo; 🛑 = parar y esperar el visto bueno.

Punto de partida: ventana de 1600×900 con stretch `canvas_items`; mando ya soportado (`GamepadCursor`, acciones de Input), clic para moverse hasta el botín (`Player.move_to`) y tamaño de interfaz configurable (80-160 %). En este equipo faltan el JDK, el SDK de Android y las plantillas de exportación de Android de Godot 4.7.2 (instalarlos necesita el permiso del usuario: descargas y licencias de Android).

## Fase 19 — Móvil

### [x] T106 · Renderizador y rendimiento en móvil · M
Origen: R5
- Renderizador `mobile` para Android (`rendering/renderer/rendering_method.mobile`) y comprobar que el filtro del mundo, la luz, el bloom, las distorsiones, los sprites por capas y las partículas funcionan con él (si alguno no, alternativa o apagarlo en móvil).
- En dispositivos táctiles (`OS.has_feature("mobile")` o pantalla táctil), por defecto: calidad gráfica baja o media (T98), luces reducidas y tamaño de interfaz 140 %; orientación horizontal fija.
- Medir con `capture_screens -- rendimiento` forzando el renderizador móvil y la calidad baja.
- Hecho: `project.godot` con `rendering_method.mobile="mobile"` y orientación `sensor_landscape` (horizontal, en cualquiera de los dos sentidos). `GameSettings.MOBILE_DEFAULTS` (calidad media e interfaz al 140 %) se usa como valor por defecto en el celular mientras el jugador no haya elegido otro, y `GraphicsQuality.MOBILE_LIGHTS` limita a 12 las luces en cualquier calidad. **Decisión**: cuenta como celular solo `OS.has_feature("mobile")` (`GameSettings.is_mobile`, con `force_mobile` para pruebas y capturas); una laptop con pantalla táctil conserva su calidad, y los controles táctiles (T107) son los que miran la pantalla táctil. Medido con `capture_screens -- rendimiento movil` y `--rendering-method mobile` en este equipo (RTX 4050), sin un solo error: 300 enemigos a 45,6 ms por fotograma con el móvil frente a 45,5 ms con Forward+, mismas capas y efectos (filtro del mundo, luces, bloom, ondas, sprites por capas, partículas); capturas en `docs/capturas/movil/`. El rendimiento en un teléfono de verdad queda para T110, con el APK. Prueba `_test_mobile_defaults`.

### [x] T107 · Controles táctiles: movimiento y objetivo · M
Origen: R5
- Detectar pantalla táctil (`DisplayServer.is_touchscreen_available()`) y mostrar un **joystick virtual** a la izquierda para moverse (aparece donde apoyas el dedo, con zona muerta); tocar el mundo fuera de los controles: ir ahí, recoger botín o hablar con un NPC (lo que ya hace el clic).
- **Apuntado automático** para jugar con el pulgar: las habilidades apuntan al enemigo más cercano en la dirección del joystick (o al más cercano, si no se mueve), con un indicador.
- Opción en Pausa → Controles para ocultar los controles táctiles.
- Hecho: `Touch` (lógica: `stick_vector` con zona muerta, `aim_index` con un cono de 40° y alcance de 520 px, `active` desde el último toque, `shown`/`set_enabled` en `settings.cfg` → controls/touch) y `TouchControls` en `GameUI`, encima del HUD: el joystick empieza donde apoyas el dedo en la franja izquierda (sin el registro de arriba ni el orbe de vida), no empieza con una ventana, el diálogo, la pausa o una escena encima, y se suelta si se abre una. Se come el clic que Godot emula desde ese toque para que el personaje no camine hacia el dedo. `Player` suma `Touch.stick` como el stick del mando (también para la esquiva) y `SkillController._aim_target` apunta con `Touch.aim_index`; la mira roja la dibuja `TouchControls`. **Arreglo de paso**: `get_global_mouse_position` lee el cursor del sistema, que el toque no siempre mueve, y tocar el mundo iba hacia otro lado; `Touch.pointer` usa el último toque en `Player`, el botín, los NPC y los sucesos de zona. Interruptor «Controles táctiles» en Pausa → Controles. Capturas `capture_screens -- tactil` (toques simulados con su clic emulado) en `docs/capturas/movil/`: el joystick mueve en su dirección, al soltar vuelve a cero y tocar el mundo lleva hasta allí. Prueba `_test_touch_controls`. Sin probar en un teléfono de verdad (eso, con el APK de T110).

### [x] T108 · Controles táctiles: habilidades, esquiva y pociones · M
Origen: R5
- Botones grandes a la derecha en arco para las 6 habilidades (con su icono, enfriamiento y coste, como la barra del HUD), un botón de **esquiva** y la fila de **pociones** tocables; mantener pulsado = canalizar o repetir; arrastrar desde un botón = apuntar a mano.
- La barra del HUD de escritorio se recoloca o se oculta en táctil para no duplicar; los botones de menú (C I K P B) más grandes.
- Hecho: el `Hud` tiene una forma táctil (`touch_layout`, sigue a `Touch.shown()`): sin la placa, las 6 casillas de siempre (icono, enfriamiento, coste, RAM, AUTO y ON; sin la chapita de la tecla) en **dos arcos** a la izquierda del orbe de maná (`TOUCH_RING`; la 1 más grande, 76 px, y las demás de 66), la esquiva encima del orbe, pociones de 60×68 y botones de menú de 48×42 abajo a la izquierda, fuera del joystick, y la barra de experiencia debajo. **Decisión**: un solo arco de 6 no cabía sin montarse ni subir hasta el registro de misiones con la interfaz al 140 % (el valor del celular); con dos arcos, a 140 % el botón más alto empieza 38 px por debajo de las misiones. `Hud.touch_button_at` dice qué botón hay bajo un dedo y `TouchControls` lleva cada dedo por su lado (joystick y botones a la vez): una habilidad es `Input.action_press` de su acción mientras el dedo esté (así canalizar y repetir son lo de siempre), arrastrar ≥26 px desde ella pone `Touch.aim_dir` (apuntado a mano, con línea discontinua hasta el punto; `Touch.manual_target`, de 120 px al alcance entero) y soltar vuelve al automático; la esquiva es la acción `dodge` y la poción, `use_flask`. Una ventana encima suelta todo. Comprobado con toques simulados (`capture_screens -- tactil`): mantener la 1 arrastrando la lanzó 3 veces en 1,2 s, la esquiva gastó su carga y la poción sus cargas; capturas a 100 % y 140 % en `docs/capturas/movil/`. Pruebas en `_test_touch_controls`.

### [x] T109 · Interfaz táctil · M 🛑
Origen: R5
- Todo lo que hoy depende de pasar el ratón por encima, con toque: tooltip al tocar un objeto o nodo (y botón para equiparlo, venderlo o asignarlo), mantener pulsado = clic derecho, arrastrar y soltar con el dedo en inventario, alijo y habilidades, zoom con dos dedos en el árbol pasivo y el mapa; botón de pausa en pantalla; textos y objetivos táctiles de 44 px como mínimo.
- Capturas a resolución de teléfono (2400×1080 y 1600×720) de las ventanas principales para la revisión.
- Hecho: `TouchPointer` (en `GameUI`), como el cursor de mando: dentro de las ventanas de `cursor_windows` (inventario, alijo, tienda, habilidades, hoja, waypoints, desafíos, árbol, diálogo y elección) descarta el ratón que Godot emula del toque y pone sus propios eventos de ratón (dispositivo `Touch.POINTER_DEVICE`, que no apaga el modo táctil ni el del mando), así que los paneles no cambian. **Tocar** una casilla con objeto o un nodo del árbol pasa el «ratón» por encima (tooltip) y saca encima un botón dorado con la acción (`GameUI._touch_action`: Equipar, Quitar, Al cinturón, Al alijo, A la bolsa, Comprar, Recomprar, Instalar, Seleccionar; Asignar en el árbol); **tocar otra vez** lo mismo antes de 4 s, o el botón, la hace (con el clic que toque: quitar una placa de la barra es el derecho). Botones, pestañas, casillas vacías y el fondo del árbol: clic al momento. **Mantener** 0,5 s: clic derecho. **Arrastrar** ≥12 px: el arrastre de siempre (objetos) o mover la vista (árbol). **Dos dedos**: zoom en el árbol (`_zoom_at` en el centro de los dedos) y en el mapa grande (un paso de `zoom_by` cada ×1,25). Botones **Mapa** y **II** (como Esc) a la izquierda del minimapa, solo en táctil y escondidos con una ventana, el árbol o la pausa abiertos. **44 px**: con la interfaz al 140 % del celular, los botones del HUD táctil, el de acción y los de las ventanas (40 px de alto) pasan de 44; los textos más chicos (10-11 px) quedan en 14-15. Comprobado con toques simulados a 2400×1080 y 1600×720 (`capture_screens -- telefono`, lienzo 2000×900): tocar → tooltip y «Equipar», mantener → basura, arrastrar → a la casilla de destino, dos toques → equipado, dos dedos → zoom 0,55 → 1,65 en el árbol; capturas de partida, inventario, habilidades, hoja, árbol, mapa y pausa en `docs/capturas/telefono/`. **Pendiente**: el desplazamiento de la bolsa con el dedo solo va por los huecos y la barra (sobre las casillas, arrastrar mueve el objeto); con la interfaz al 140 % la bolsa no cabe entera. Pruebas en `_test_touch_controls`. Sin probar en un teléfono de verdad (T110).

### [x] T110 · Exportación a Android · S 🛑
Origen: R5
- Necesita el permiso del usuario al empezar: instalar JDK 17, el SDK de Android (aceptar sus licencias) y las plantillas de exportación de Android de Godot 4.7.2.
- Preset de exportación «Android» (arm64-v8a, paquete `com.pathoverflow.game`, nombre e icono, horizontal, sin permisos extra), clave de depuración, y `build/PathOverflow.apk`; instrucciones en el README para instalarlo en el teléfono y para firmarlo con una clave propia si se quiere publicar.
- **Hecho:** preset «Android» en `export_presets.cfg` y en `export_presets.example.cfg` (arm64-v8a, `com.pathoverflow.game`, «Path Overflow» 3.0, horizontal e inmersivo, sin gradle), compresión ETC2/ASTC en `project.godot`, y `tools/instalar_android.ps1` que baja el JDK 17 y las herramientas de Android, pide aceptar las licencias, instala build-tools 36.1.0 y Android 36, configura el editor y exporta `build/PathOverflow.apk` (~45 MB, clave de depuración). Probado por el usuario en su celular: la pantalla de título solo continuaba con teclas (el Control se quedaba el clic y no escuchaba toques); ahora escucha en `_input` toques y clics (salvo sobre «Música») y dice «toca la pantalla para continuar» en móvil. README: sección Android en «Exportar».

---

# Roadmap 6.0 — experiencia en el celular (27-10-2026)

Pedido del usuario tras jugar el APK de T110 en su celular: en el prólogo no aparecen el joystick ni los botones; en el acto I cuesta recoger objetos (hay que acercarse y tocar justo encima) y los botones de la derecha podrían repartirse mejor, con uno de **interactuar** (objetos, NPC, sucesos); el filtro de botín no responde al dedo (no marca ni desmarca) y su ventana es más grande que las demás; quiere ver la **versión** abajo a la derecha (p. ej. «v1.1») y poder **actualizar** si hay una nueva. **Origen: R6.** Mismo protocolo; 🛑 = parar y esperar el visto bueno. Aprobado por el usuario el 27-10-2026 tal como está.

Diagnóstico de partida (leído en el código, sin probar en el teléfono):
- El prólogo es su propia escena (`scenes/prologue/prologue.tscn`, `Prologue` + `PrologueStage`) y no lleva `GameUI`, así que tampoco `TouchControls` ni `TouchPointer`: allí solo hay clic emulado.
- `LootFilterPanel` no está en `GameUI.cursor_windows()` (y se abre desde la pausa, que hace que esa lista salga vacía), así que `TouchPointer` no lo maneja; sus filas leen el clic con `gui_input` sobre gemas de 92×30 px (por debajo de 44 px). Se ancla con `PRESET_FULL_RECT`, de ahí que ocupe más que las otras ventanas.
- La versión solo existe en el preset de Android (`version/name="3.0"`, `version/code=1`); no hay `application/config/version` ni etiqueta en pantalla. El APK va firmado con la clave de depuración del equipo: para instalar una versión encima de otra sin perder nada hace falta firmar siempre con la **misma** clave.
- El tutorial (`data/tutorial.json`) habla de teclas (flechas, Espacio, Tab, 1-5).

## Fase 28 — Lo que falló en el teléfono

### [x] T132 · Controles táctiles en el prólogo · S
Origen: R6
- Joystick y toque al mundo también en el prólogo: sacar de `GameUI` lo que no depende de la partida (`TouchControls` en modo «solo moverse», sin habilidades ni pociones) o montarlo en `Prologue`; botón de interactuar (T134) para Rafa, la TV, la ventanilla y las puertas; tocar para pasar los diálogos y las líneas de la consola roja.
- Capturas `capture_screens -- prologo tactil` con toques simulados de la calle a la oficina.
- Hecho: `Prologue` monta su propio `TouchControls` (sin `hud` ni enemigos: solo el joystick, que no empieza fuera de la fase de caminar, con una conversación o con la ventana de contratación) y suma `Touch.stick` a las flechas en la calle, la oficina y el pasillo (arriba = al fondo). Botón dorado **abajo a la derecha** con el nombre de lo que hay cerca («Hablar con el encargado», sin la «E ·»; `Prologue.touch_use_text`), solo con controles táctiles; el estilo dorado sale de `TouchPointer.gold`, compartido con el botón de acción de las ventanas. **Arreglo de paso**: el clic que emula un toque llega antes que el toque, así que el prólogo leía el destino del toque anterior; ahora `_mouse_stage` usa la posición del propio evento. La introducción y las conversaciones ya pasaban con el clic emulado; la consola roja avanza sola. Comprobado con `capture_screens -- prologo tactil`: dos toques pasan la introducción, el joystick camina (120 → 178 en 1 s), tocar a la derecha y luego la entrada entra al pasillo en 1,5 s, el joystick hacia arriba avanza (profundidad 0 → 0,33), junto a Rafa sale el botón (239×64) y tocarlo empieza la conversación, y tocar la pasa; capturas en `docs/capturas/movil/132_*`. **Decisión**: el botón de usar del prólogo es propio y sencillo; el de la partida es T134. Saltar el prólogo sigue siendo Esc (Atrás de Android, en T141). Prueba de `touch_use_text` en `_test_touch_controls` (la escena no se puede instanciar desde `test_core`, que compila antes que los autoloads).

### [x] T133 · Filtro de botín con el dedo y del tamaño de las demás ventanas · S
Origen: R6
- `LootFilterPanel` en `cursor_windows()` (también con la pausa abierta, que es desde donde se abre) o con su propio manejo de `InputEventScreenTouch`; gemas de 44 px de alto como mínimo; tocar una gema la marca y la desmarca, con el sonido de siempre.
- El mismo marco que el inventario o la hoja (tamaño y posición de `UiStyle`), no a pantalla completa; si no cabe a 140 %, desplazamiento con el dedo.
- Prueba en `_test_touch_controls`: toque simulado sobre cada fila cambia la regla.
- Hecho: **causa**: con el inventario abierto (el filtro se abre también desde su botón), `cursor_windows()` devolvía el inventario y `TouchPointer` tomaba el toque como si fuera sobre las casillas que quedan debajo del filtro (primer toque = tooltip, no clic), así que las gemas nunca recibían el clic. **Decisión**: el filtro tapa todo, así que con él abierto `cursor_windows()` devuelve vacío y el toque llega directo a sus gemas (y el arrastre al desplazamiento nativo de Godot); el joystick y los botones Mapa/II tampoco empiezan con él abierto. Gemas de 92×32 (45 px con la interfaz al 140 %). Ventana más chica: la vista previa y las reglas finas comparten la columna de la derecha con dos pestañas (antes eran tres columnas, ~1420 px, más ancha que la pantalla del celular a 140 %), y las filas se desplazan si no caben en alto (`_fit`: el alto que deja la pantalla, como `FitScroll`). Comprobado con `capture_screens -- filtro tactil` a 2400×1080 y 1600×720 con la interfaz al 140 % y 30 objetos en la bolsa debajo: la ventana cabe (1585×886 en el lienzo de 2000×900, del alto del inventario), tocar «Raro», «Normal» y «Ocultar» de pociones cambia cada regla; capturas `docs/capturas/movil/133_*`. La prueba va en la captura y no en `test_core` (el panel usa autoloads, como el prólogo). Sigue más ancha que el inventario (6 gemas por fila).

### [x] T134 · Botón de interactuar y recogida cómoda · M
Origen: R6
- Botón grande de **interactuar** a la derecha (junto a los arcos de habilidades) que muestra el icono de lo más cercano que se puede usar a ~160 px: objeto del suelo, NPC, waypoint, caja, suceso de zona o salida; tocarlo camina hasta allí y lo usa; el objetivo se resalta en el mundo con un contorno.
- Con varios objetos juntos: cada toque recoge el siguiente (de más raro a menos); mantener = recoger todo lo visible cerca.
- Opción en Pausa → Controles: **recoger solo** al pasar por encima los objetos que el filtro deja ver de una rareza elegida o más (por defecto apagado).
- Toque al mundo más permisivo: el nombre del objeto en el suelo cuenta como zona de toque, ampliada a 44 px de alto.
- Hecho: **arreglo de fondo**: el clic que Godot emula de un toque llega antes que el toque, y `Touch.pointer` usaba el punto del toque *anterior*: tocar una etiqueta mandaba al jugador al sitio donde se tocó la vez anterior (por eso costaba tanto recoger). `Touch.note_event` toma ya la posición del clic emulado. Botón dorado de 74 px en el HUD táctil (`Hud.use_rect`, a 318 px y 194° del orbe de maná, abajo a la izquierda de los arcos) con un dibujo de lo que hay (el icono del objeto, burbuja, rombo del waypoint, cofre del alijo) y su texto (Recoger, Hablar, Waypoint, Alijo, Abrir, Tocar, Consola, Escoltar, Comprar); `TouchControls` dibuja cuatro esquinas doradas en el objetivo. `World.touch_use_target` (a 160 px): el objeto visible de más rareza (`LootManager.best_near`, por el escalón del filtro, porque el enum de rareza no va en orden) o, si no hay, `Zone.use_near` (NPC, waypoint, alijo o suceso con `ZoneEvents.nearest`); `interact_near` del mando usa lo mismo. Tocar = usar; mantener 0,45 s = `LootManager.pick_all_near` (a 320 px, de más raro a menos, en cola). «Recoger solo al pasar» en Pausa → Controles (no, todo lo visible, mágico, raro, ultra-raro o únicos; `settings.cfg` → controls/auto_pickup). Con el dedo, la etiqueta se toca también por su icono y con 44 px de alto (`LootManager.hit_rect`). **Decisión**: las salidas no salen en el botón (se cruzan caminando, como siempre). Comprobado con `capture_screens -- usar tactil` a 2400×1080 con la interfaz al 140 %: botón «Recoger» con el raro entre cuatro objetos, un toque lo recoge, mantener recoge los otros tres, tocar la etiqueta de un objeto lejano (después de tocar otro punto) lo recoge, junto a Aida sale «Hablar» y tocarlo abre la conversación; capturas `docs/capturas/movil/134_*`. Pruebas en `_test_touch_pickup` y `_test_touch_controls`.

### [x] T135 · Revisión de todas las ventanas en táctil · M
Origen: R6
- Recorrer con toques simulados cada ventana y menú que no está en `cursor_windows` (pausa y sus submenús, opciones, catálogo, selección y creación de personaje, título, confirmaciones, escenas) y arreglar lo que no responda; objetivos de 44 px y textos de 14 px como mínimo.
- Una prueba que abra cada ventana y toque cada botón visible (falla si alguno no recibe el toque), para que no vuelva a pasar con ventanas nuevas.
- Pendientes de T109: desplazar la bolsa con el dedo sobre las casillas (mantener para coger el objeto, arrastrar en vertical para desplazar) y que la bolsa quepa a 140 %.
- Hecho: recorrido `capture_screens -- ventanas tactil` (sale con código 1 si algún botón falla) a 2400×1080 con la interfaz al 140 %: título, menú principal, creación, Mapa/II, pausa, Controles, Logros, Récords, Deuda técnica, Archivos, filtro de botín, catálogo, mapa grande y muerte; toca cada botón visible (no los que quedan fuera de su lista desplazable), mira que le llegue (`button_down`) y lo desactiva antes de soltar para que no haga nada; también desplaza la bolsa. Encontró y se arregló: **muerte** sin botón (solo «Pulsa R»: en el celular no se podía seguir) → botón «Reaparecer en el campamento» (`GameUI.respawn_requested`) y sin el «Pulsa R» en táctil; **menú principal** con «Jugar», «Nuevo personaje» y la fila de abajo fuera de la pantalla (la descripción del personaje con `fit_content` estiraba el panel) → la descripción se desplaza en su hueco y, por debajo de 760 px de alto, logo, figura y subtítulo se compactan; **catálogo**: el joystick empezaba debajo de él y se comía los toques de la mitad izquierda, y el «II» tapaba su ✕ → con el catálogo abierto, ni joystick ni Mapa/II; **ventanas emergentes** de la pausa, el atlas, la forja y las construcciones sin el tamaño de interfaz (letra de 13 px en el celular) y la de logros con «Cerrar» por debajo del borde → `GameUI.show_popup`: escala de interfaz, rebajada hasta que quepa (nunca menos de 100 %), y como mucho el 94 % de la pantalla. **Bolsa**: arrastrar en vertical sobre las casillas la desplaza (`TouchPointer.scroll_for`, si el arrastre es 1,5 veces más vertical que horizontal); en horizontal o en diagonal sigue moviendo el objeto, y mantener sigue siendo el clic derecho (**decisión**: así no choca con mantener = basura). La ventana del inventario ya cabía a 140 % (la bolsa se desplaza dentro). Resultado: 0 botones sin respuesta; arrastrar la bolsa la desplaza 100 px sin mover el objeto; capturas en `docs/capturas/movil/135_*`. Queda fuera: el campo de texto de las escenas confía en el Enter del teclado del celular.

## Fase 29 — Controles a la medida

### [x] T136 · Lado derecho reorganizado · M 🛑
Origen: R6
- Propuesta (con capturas a 2400×1080 y 1600×720 para elegir): **ataque principal** grande en la esquina inferior derecha, las otras habilidades en arco a su alrededor, la esquiva junto al pulgar y el botón de interactuar (T134) encima; los menús en una sola tecla «☰» que despliega C I K P B; las pociones en una fila corta a la izquierda del arco.
- Si las 6 habilidades no caben cómodas: 4 a la vista y un botón para cambiar de juego de habilidades.
- Opciones en Pausa → Controles: tamaño de los botones (80-140 %), opacidad y **modo zurdo** (joystick a la derecha y botones a la izquierda).
- Hecho: nueva distribución **«esquina»** (por defecto): la habilidad 1 de 100 px abajo y pegada al orbe de maná, y las otras 5 en dos anillos a su alrededor (`Hud.TOUCH_CORNER_RING`: tres a 120 px a la izquierda, en diagonal y arriba; dos a 205 px entre ellas), la esquiva encima del orbe, el botón de usar entre el anillo y la esquiva (encima pisaba el registro de misiones; con botones grandes se estrecha hasta caber), las pociones en una fila a la izquierda del anillo y los menús en un **☰** que despliega C I K P B (el «!» de novedades pasa al ☰ si está recogido). La de **«dos arcos»** (T108) sigue como opción. En Pausa → Controles: **Botones** (esquina / dos arcos), **Tamaño** (80-140 %, escala botones y distancias) y **Mano** (diestra / zurda: todo el HUD de abajo y la zona del joystick en espejo; `Hud._mr`, `TouchControls.in_zone`), guardados en `settings.cfg` → controls (`Touch.load_layout`). Comprobado con `capture_screens -- botones tactil` a 2400×1080 y 1600×720 con la interfaz al 140 %: esquina al 100 %, al 120 % y zurda sin ningún botón encima de otro, fuera de pantalla ni sobre las misiones; en «dos arcos» las esquinas de algunas casillas se tocan (como desde T108). Capturas `docs/capturas/movil/136_*`. **Decisiones**: con la esquina caben las 6 habilidades sin montarse, así que no hace falta el cambio de juego de 4; la **opacidad** pasa a T137 (los botones se dibujan con el resto del HUD y hay que separarlos primero); en zurdo las pociones quedan en espejo (la 1 a la derecha).

### [x] T137 · Editor de disposición táctil · M
Origen: R6
- Pantalla para arrastrar cada botón a donde se quiera y cambiar su tamaño, con «Restaurar»; se guarda en `settings.cfg`.
- Opacidad de los botones táctiles (viene de T136): separar su dibujo del resto del HUD para poder atenuarlos.
- Hecho: Pausa → Controles → «Mover y ajustar los botones...» (solo con pantalla táctil) abre `TouchLayoutEditor` sobre el HUD con el juego en pausa: arrastrar un botón lo mueve; tocarlo lo elige y «Más grande» / «Más chico» lo escalan (×1,12, entre 60 % y 180 %); «Opacidad» (100, 85, 70, 55, 40 %), «Restaurar» (vuelve a la distribución elegida y opaca) y «Listo» (o Esc), que vuelve a la pausa. Se pueden mover las 6 habilidades, la esquiva, usar, la fila de pociones (entera) y el ☰. Se guarda en `settings.cfg` → controls/touch_custom ([dx, dy, escala] por botón, como diestro, así vale también en zurdo) y controls/touch_opacity (`Touch.customized`, `Touch.adjust`). **Opacidad**: pociones, habilidades, esquiva y usar se pintan ahora en una capa hija del HUD (`_draw_buttons_layer`; las funciones de dibujo pintan en `_ci`), que se atenúa sin tocar los orbes. Comprobado con `capture_screens -- editor tactil` a 2400×1080 con la interfaz al 140 %: arrastrar 160×100 px de pantalla movió la habilidad 1 114×72 en el HUD (lo mismo, a 140 %), la esquiva pasó de 64 a 80 px, la opacidad al 85 %, se guardó y la pausa volvió al cerrar; capturas `docs/capturas/movil/137_*`. Pruebas en `_test_touch_controls`.

### [x] T138 · Tutorial y ayudas para el dedo · S
Origen: R6
- Textos del tutorial, de las ayudas en pantalla y de los tooltips con la versión táctil cuando `Touch.shown()` («toca el botón de esquiva», «mantén pulsado») en vez de teclas; el paso que señala un botón lo resalta en pantalla.
- Hecho: `Touch.text(d)` devuelve `d["text_touch"]` con los controles táctiles a la vista (si existe) y si no `d["text"]`; lo usan el tutorial, los consejos de mecánicas (`TipPanel`) y los diálogos (`DialogueBox`). Versión táctil en `data/tutorial.json` (9 pasos que hablaban de teclas o del clic, sin teclas: joystick, botones, «☰ y luego I»...), en la esquiva de `data/tips.json`, en las explicaciones de controles de Aida («lucha», «lucha2», «regalo») y Mario («cafe») en `data/npcs.json`, y en las ayudas del prólogo (`controls_touch`, `continue_touch` en `data/prologue.json`); el consejo de carga de la esquiva nombra también el botón. El tutorial cambia de texto al pasar del ratón al dedo. **Aro «¡Aquí!»** dorado que late sobre el botón del paso (`touch_point` en el JSON: habilidad grande, esquiva, usar, poción 1 o el menú; si el ☰ está recogido, sobre el ☰): `Hud.tutorial_point`, que pone `GameUI` desde `TutorialPanel.touch_point()`. El editor de historia muestra y edita el texto «(celular)» de cada paso. Comprobado con `capture_screens -- tutorial tactil` (aro sobre la habilidad grande, el ☰ y la poción 1); capturas `docs/capturas/movil/138_*`. Prueba: cada paso del tutorial que nombra teclas o el clic tiene versión táctil sin teclas.

## Fase 30 — Versión y actualizaciones

### [x] T139 · Versión visible · S
Origen: R6
- Una sola fuente: `application/config/version` en `project.godot` (p. ej. «3.1.0»); el preset de Android toma de ahí `version/name` y un `version/code` que sube solo en cada exportación (`tools/instalar_android.ps1` o un `tools/exportar_android.ps1`).
- Etiqueta discreta «v3.1» abajo a la derecha en la pantalla de título y en la pausa (no tapa los botones táctiles); en el registro de cambios del README.
- Hecho: `config/version="3.1.0"` en `project.godot`; `GameVersion` la lee (`short()` = «v3.1», sin el «.0») y pone la etiqueta (13 px, gris) abajo a la derecha en el título y en la pausa (con la pausa abierta no hay botones táctiles). `tools/exportar_android.ps1` (con BOM, como el instalador) copia la versión al preset «Android» como `version/name`, sube `version/code` en 1 (en `export_presets.cfg`, que no va al repositorio; en el de ejemplo solo el nombre), importa y exporta (`-Release` para firmar con la clave propia); `instalar_android.ps1` lo usa en su paso 5. Probado: exportó `build/PathOverflow.apk` (45 MB) como 3.1.0 con código 2. README: sección Android y la 3.1 en «Versiones». Prueba de `GameVersion` en `_test_touch_controls`; capturas `docs/capturas/movil/139_*`.

### [x] T140 · Aviso de actualización · M 🛑
Origen: R6
- **Necesita decisiones del usuario**: dónde se publica el APK (p. ej. GitHub Releases de un repositorio público, que hoy no existe: el proyecto no tiene remoto) y una **clave de firma propia** que se guarde fuera del repositorio (con la de depuración, una versión nueva no se instala encima).
- Al llegar a la pantalla de título, `HTTPRequest` (con tiempo límite, en segundo plano, sin bloquear si no hay red) lee un `latest.json` (`version`, `code`, `url`, `notas`); si es más nueva, junto a la versión aparece «Actualización disponible: v3.2» y un botón que abre la descarga (`OS.shell_open`); Android pide instalarla encima y las partidas (`user://`) se conservan.
- Opción para no comprobar; nunca descarga ni instala sola. Si más adelante se publica en Google Play, la tienda hace esto y se quita.
- Decisiones del usuario (28-10-2026): **GitHub Releases** y **clave propia creada por el usuario** (él escribe la contraseña).
- Hecho: `UpdateCheck` (en la pantalla de título): `HTTPRequest` con 6 s de límite y redirecciones a `application/config/update_url` de `project.godot` (vacío hasta que exista el repositorio: entonces no pregunta nada); `newer()` solo avisa con una versión mayor (`compare`, número a número) y descarga https. El aviso es un botón dorado «Actualización disponible: v3.2 · Descargar» encima de la versión, que abre la descarga en el navegador (`OS.shell_open`); tocarlo no cuenta como «continuar». «Buscar actualizaciones: sí/no» en Pausa → Gráficos y datos (`interface/check_updates`). Permiso de internet en el preset «Android» (antes «sin permisos extra»: sin él no hay red). `tools/publicar_version.ps1 -Repo usuario/repo [-Notas]`: apunta `update_url` a `https://github.com/<repo>/releases/latest/download/latest.json`, exporta firmado (`exportar_android.ps1 -Release`) y escribe `build/latest.json`; luego se suben el APK y el JSON a una release `v<versión>`. De paso: el título decía «v0.1.0-alpha» en su texto de broma (ahora sin versión) y el estilo dorado tiene margen interior. Pruebas de `compare` y `newer`; captura `docs/capturas/movil/140_titulo_actualizacion.png` (con un latest.json de mentira).
- **Falta (usuario)**: crear el repositorio de GitHub y la clave propia; ver los pasos en la conversación del 28-10-2026 y en el README («Exportar» → Android).
- 28-10-2026: repositorio de versiones **WalBernal/PathOverflow** (público, solo versiones; lo crea el usuario). `update_url` apunta a su `releases/latest/download/latest.json` y la **3.1.1** (código 6) es la primera que lo lleva dentro: hay que instalarla a mano una vez. **Decisión**: para no borrar las partidas, se sigue firmando con la clave de depuración de este equipo (la de los APK ya instalados; cambiar de clave obliga a desinstalar) — `publicar_version.ps1` firma así por defecto (`-ClavePropia` para la otra) y hay una copia en `%APPDATA%\PathOverflow\clave_firma_respaldo.keystore`. Arreglado de paso: `publicar_version.ps1` no llegaba a ejecutarse (`"$version:"` es una variable con ámbito en PowerShell).

## Fase 31 — Pulido de celular

### [x] T141 · La app en segundo plano y el botón Atrás · S
Origen: R6
- Al salir de la app, recibir una llamada o apagar la pantalla (`NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT`): pausar y guardar; al volver, la pausa abierta.
- Botón o gesto **Atrás** de Android (`NOTIFICATION_WM_GO_BACK_REQUEST`) = Esc: cierra la ventana de arriba o abre la pausa; en el título, pregunta antes de salir.
- Hecho: `World` guarda y abre la pausa (si no había nada encima y el jugador vive) con `NOTIFICATION_APPLICATION_PAUSED` y, en el celular, con `APPLICATION_FOCUS_OUT` (`World.app_left`; en el PC, cambiar de ventana no pausa). **Atrás**: `config/quit_on_go_back=false` en `project.godot` (antes Godot cerraba la app) y `GameData.go_back()`: en el título y el menú principal, «¿Salir del juego?» (`ask_quit`, con «Salir» y «Seguir»; en el título, tocar la ventana no cuenta como «continuar»); en lo demás manda un Esc (`ui_cancel`), que ya cierra la ventana de arriba, salta escenas o abre la pausa, y en el prólogo avisa y salta. Comprobado con `capture_screens -- atras`: la pregunta sale en el menú, Atrás cierra el inventario y luego abre la pausa, y salir de la app guarda (el autoguardado vuelve a 0) y deja la pausa abierta; capturas `docs/capturas/movil/141_*`.

### [x] T142 · Pantallas con muesca y legibilidad · S
Origen: R6
- Respetar la zona segura (`DisplayServer.get_display_safe_area`) para que la muesca y las esquinas redondeadas no tapen el HUD, el joystick ni los botones.
- Tooltips de objetos que caben en pantalla con la interfaz al 140 % (más estrechos o con desplazamiento) y comparar con lo equipado uno debajo de otro.
- Hecho: `UiStyle.safe_margins` pasa la zona segura del celular (`DisplayServer.get_display_safe_area`, en píxeles de pantalla) a coordenadas del lienzo; `GameUI.apply_ui_scale` y `UiStyle.apply_ui_scale` (menús y prólogo) colocan la interfaz dentro de ella, y `GameUI` la vuelve a mirar cada medio segundo (al girar el celular la muesca cambia de lado sin cambiar el tamaño). En el PC no hace nada; `UiStyle.test_safe_area` la simula. **Tooltips**: si con su comparación no caben en alto se encogen (como mucho al 60 %, `ItemTooltip.MIN_FIT`) en vez de salirse por abajo; lo equipado va al lado si cabe a lo ancho y debajo si no. **Decisión**: en el celular horizontal (2000×900 de lienzo a 140 %) al lado sí cabe y apilarlo obligaba a encoger hasta el 60 % (letra de 11 px), así que solo se apila cuando al lado no cabe. Comprobado con `capture_screens -- muesca` a 2400×1080 con una muesca simulada de 120 px: la interfaz empieza en x=100 del lienzo (los 120 px de ventana) y un tooltip de ultra-raro comparando con el equipado cabe entero al 96 %; capturas `docs/capturas/movil/142_*`.

### [x] T143 · Vibración y respuesta al toque · S
Origen: R6
- `Input.vibrate_handheld` corto al recibir un golpe fuerte, crítico, subir de nivel, caer un único y pulsar un botón táctil; opción para apagarlo.
- Hecho: `Haptics.pulse(causa)` con un pulso por causa (golpe que quita más del 8 % de la vida —el mismo que sacude la cámara— 45 ms; crítico 18 ms suave; subir de nivel 120 ms; caer un único o de conjunto 90 ms; botón táctil 10 ms muy suave) y 0,12 s de respiro entre pulsos para que una ráfaga de críticos no zumbe sin parar (subir de nivel y el único pasan siempre). Solo en el celular. «Vibración (celular): sí/no» en Pausa → Combate (`combat/vibration`). Permiso `vibrate` en el preset «Android» (sin él Android ignora la vibración). Pruebas en `_test_touch_controls` (respiro, importantes, apagada). Sin probar en un teléfono de verdad (en el PC no vibra).

### [x] T144 · Batería y rendimiento en el teléfono · M
Origen: R6
- Límite de FPS (30 / 60) en Opciones, 30 por defecto en el celular si mide por debajo de 50; contador de FPS opcional; medir en el teléfono del usuario una zona con muchos enemigos y bajar partículas o luces si hace falta.
- Hecho: «FPS: auto / 30 / 60 / sin límite» en Pausa → Gráficos y datos (`GraphicsQuality.fps_choice`, `Engine.max_fps`, aplicado al arrancar en `GameData`). **Auto** (por defecto): sin límite en el PC; en el celular 60 y, la primera vez que una partida pasa 10 s con 10 enemigos o más, si la media baja de 50 FPS se queda en 30 (`graphics/auto_fps`) con un aviso en pantalla. «Contador de FPS: sí/no» (la línea de FPS y depuración de arriba a la izquierda; en el celular, apagada por defecto, `MOBILE_DEFAULTS`). Pruebas en `_test_touch_controls`. **Falta**: medir en el teléfono del usuario (no se puede desde aquí) y, si hace falta, bajar partículas o luces: va a la lista de T145.

### [x] T145 · Revisión en el teléfono · S 🛑
Origen: R6
- APK nuevo y una lista para el usuario: prólogo entero, acto I hasta el primer jefe, filtro de botín, recoger objetos con el botón, inventario, árbol, salir y volver a la app, y actualizar de una versión a otra.
- Preparado: `build/PathOverflow.apk` v3.1.0 (código 4, clave de depuración: se instala encima del de T110) y la lista en `docs/prueba_celular_3.1.md`. De paso, `exportar_android.ps1` espera a Godot (el ejecutable sin consola volvía enseguida y el script decía «falló» con el APK a medio escribir). **Esperando la prueba del usuario**; actualizar de una versión a otra queda para cuando exista el repositorio de versiones. (31-10-2026: superada por las revisiones de las versiones 3.2 y 3.3, que ya se actualizan por el aviso; se cierra.)
- Primera prueba del usuario (28-10-2026), tres fallos arreglados: (1) **la interfaz parpadeaba y se borraba** (HUD, minimapa y misiones fuera de la pantalla): la zona segura de T142 podía venir en la otra orientación y dar márgenes enormes, y se volvía a aplicar cada medio segundo → `UiStyle.margins_for` ignora una zona segura que no cabe en la ventana, pone tope a cada margen (8 % del lado; una muesca real ocupa un 3-5 %) y redondea (sin temblores); (2) **no se podía cerrar el árbol de pasivas**: su «Cerrar (P)» era texto plano en la esquina de la muesca (y con el fallo anterior, fuera de la pantalla) → con el dedo, «✕ Cerrar» grande y dorado; comprobado con `capture_screens -- arbol tactil` (tocarlo cierra el árbol); (3) **tutorial**: pedía gastar un punto de pasiva en el Sandbox, donde no da para subir de nivel, y después «llega al campamento» con el jugador ya más allá → el paso de las pasivas va al final (tutorial versión 3, `TutorialOrder` migra a quien iba a medias al mismo paso), «llega al campamento» vale en cualquier zona que no sea el Sandbox y «sal del campamento» en cualquiera de después. Pruebas en `_test_touch_controls`.

---

# Roadmap 7.0 — diseño y experiencia en el celular (29-10-2026)

Pedido del usuario tras jugar la 3.1 en el celular: mejorar los controles; con varias misiones el registro tapa los botones; la jugabilidad todavía no se siente satisfactoria. **Origen: R7.** Mismo protocolo; 🛑 = parar y esperar el visto bueno. Aprobado por el usuario el 29-10-2026 («inicia en /loop»), tal como está.

Diagnóstico de partida (leído en el código):
- `QuestTracker` cuelga del minimapa (arriba a la derecha) y crece hacia abajo sin tope: con 3-4 misiones llega a la esquina de los botones (habilidades, esquiva, usar). Solo se esconde si pisa una ventana, no si pisa el HUD táctil.
- Los botones táctiles no dan casi respuesta propia: se iluminan con un círculo plano al pulsar; no hay aviso de «listo» al terminar el enfriamiento ni de «sin maná» en el propio botón; el joystick siempre es flotante.
- La sensación de los golpes (números, destellos, empuje, sonido) está pensada para ver de lejos en un monitor: en un teléfono los números son chicos y muchos, y el impacto se pierde.

## Fase 32 — Pantalla limpia

### [x] T146 · Registro de misiones que no tapa nada · S
Origen: R7
- En el celular, el registro muestra solo la misión activa (título y paso) y se pliega a una pestaña «Misiones (N)» que se abre con un toque; se pliega solo al empezar una pelea.
- Tope de alto: nunca baja de la línea donde empiezan los botones táctiles (con cualquier distribución, tamaño y mano, y con el editor de T137); si no cabe, se pliega.
- Captura con 6 misiones a 2400×1080 y 1600×720: ningún elemento del HUD se pisa.
- Hecho: en táctil, `QuestTracker.compact` con tres vistas que se recorren tocando la cabecera: **resumen** (la misión principal y su paso; en la cabecera «Misiones (7) · +6»), **todas** y **plegado**. `max_height` = lo que queda libre hasta el primer obstáculo de su columna (`Hud.touch_obstacles`: botones, el texto de «Usar» y el orbe de maná; `QuestTracker.room`), recalculado en cada fotograma (vale con cualquier distribución, tamaño, mano o el editor); si lo elegido no cabe, se ve lo siguiente más pequeño (`view_for`, con altos aproximados para no esperar a la maquetación). En una pelea (`in_combat`, lo pone `World` con la música de combate) se pliega solo. En el PC, como siempre (L o la cabecera pliega). Comprobado con `capture_screens -- misiones tactil` con 7 misiones a 2400×1080 y 1600×720 en las dos distribuciones: pide «todas», se ve el resumen y no pisa ningún botón; en pelea, plegado. Capturas `docs/capturas/movil/146_*`; pruebas en `_test_touch_controls`.

### [x] T147 · Comprobador de solapes del HUD · S
Origen: R7
- Una prueba (captura) que recoge los rectángulos de todo lo que hay en pantalla en partida (botones, orbes, minimapa, registro, sucesos, avisos, barra de jefe, marco del objetivo, tutorial) y falla si dos se pisan, en las dos distribuciones, zurdo, al 100 % y al 140 %; se arregla lo que salga.
- Hecho: `capture_screens -- solapes` (sale con código 1 si algo se pisa): con 5 misiones, el tutorial, un aviso y botín cerca, mide cada botón táctil, los orbes, pociones, ☰, «Usar» con su texto, minimapa, Mapa/II, misiones, sucesos, tutorial y el texto del aviso, en 16 configuraciones táctiles (2400×1080 y 1600×720 con la interfaz al 140 %; esquina y arcos; diestro y zurdo; botones al 100 y al 130 %) y en el PC. Encontró 85 solapes, ahora 0: el texto de «Usar» (Recoger, Hablar...) va **encima** del botón (debajo pisaba la esquiva, la habilidad de al lado y el orbe); en táctil los **avisos** van arriba (al 26 % de la pantalla) y no sobre las habilidades; el **registro de sucesos** baja bajo el **tutorial** cuando está a la vista (también en el PC); los anillos de **«dos arcos»** se separan un poco (las esquinas de las casillas se tocaban desde T108) y «Usar» se aparta del anillo exterior; si ni el registro de misiones plegado cabe sobre los botones (arcos al 130 %), no se ve. No mide la barra de jefe ni el marco del objetivo (se dibujan sin nodo propio, arriba en el centro, donde no hay nada más).

## Fase 33 — Controles que se sienten bien

### [x] T148 · Botones con respuesta · S
Origen: R7
- Al pulsar: el botón se hunde (escala 0,92) y suelta un pequeño destello; enfriamiento con barrido y un «clic» visual (y vibración suave) cuando vuelve a estar listo; sin maná, el botón se pone azul apagado y tiembla al tocarlo en vez de no hacer nada.
- Zona de toque generosa: cada botón responde también un poco fuera de su dibujo (sin quitarle sitio al vecino).
- Hecho: mientras un dedo pulsa una habilidad, la esquiva, «Usar» o una poción, su dibujo se hunde al 92 % (`Hud.set_held`, que llama `TouchControls`); al acabar un enfriamiento, un marco claro se abre y se apaga en la casilla y el celular da un toque mínimo (`Haptics` «ready»); sin maná la casilla se tiñe de azul apagado y, al tocarla, tiembla (`Hud.deny`). **Zona de toque**: vale hasta 0,8 veces el lado desde el centro (el borde es 0,5) y, si dos botones se disputan el dedo, gana el más cercano en proporción a su tamaño (`Touch.nearest_button`); las pociones entran en el mismo reparto. Comprobado: `capture_screens -- tactil` (mantener la 1 la lanza 3 veces y se ve hundida; esquiva y poción responden) y `-- solapes` sigue en 0; captura `docs/capturas/movil/148_boton_hundido.png`. Pruebas de la zona de toque en `_test_touch_controls`. De paso, un «\n» suelto en un comentario de T136.

### [x] T149 · Joystick a gusto · S
Origen: R7
- Opción en Pausa → Controles: joystick **flotante** (como ahora), **fijo** (siempre en el mismo sitio, a la vista) o **que sigue al dedo** (si el dedo se aleja, la base va detrás); tamaño de la zona muerta; el personaje gira al instante y acelera sin retraso.
- Hecho: «Joystick: donde pongas el dedo / fijo / sigue al dedo» y «Zona muerta: chica (0,1) / normal (0,18) / grande (0,28)» en Pausa → Controles (`Touch.stick_mode`, `Touch.deadzone`, en `settings.cfg`). **Fijo**: la base, tenue y siempre a la vista, justo encima del orbe de vida (en espejo en zurdo; en el prólogo, abajo en su zona); el pulgar puede caer en cualquier parte de la zona del joystick y ya inclina desde la base. **Sigue al dedo**: si el dedo pasa del radio, la base va detrás (`Touch.follow_origin`). El personaje ya giraba y arrancaba al instante (la velocidad no tiene aceleración), así que eso no cambia. Comprobado con `capture_screens -- joystick`: en los tres modos, arrastrar 300 px inclina a tope y el personaje camina (~200 px); en «sigue» la base acabó 202 px más allá; capturas `docs/capturas/movil/149_*`. Pruebas en `_test_touch_controls`.

### [x] T150 · Apuntado que ayuda · M
Origen: R7
- Objetivo «pegajoso»: las habilidades siguen apuntando al mismo enemigo mientras siga cerca y vivo (no saltan a otro por un paso del joystick); tocar un enemigo lo fija.
- Al arrastrar desde un botón, vista previa del alcance y del área de la habilidad (círculo, cono o línea) antes de soltar; arrastrar de vuelta al botón cancela.
- Mira más clara: el enemigo apuntado con un contorno de su color y su barra de vida encima.
- Hecho: `Touch.pick_target` recuerda el objetivo por su id: sigue con el mismo mientras viva y esté a tiro (hasta 1,15 veces el alcance) y solo cambia si el joystick apunta a más de 100° de él; `SkillController` y la mira usan lo mismo. **Tocar un enemigo lo fija** (`Touch.lock_at`, a 60 px; el toque sigue siendo un clic): no cambia hasta que muera o se aleje, con un candado junto a su barra. **Mira**: esquinas del color de su rareza (más abiertas en los grandes) con borde negro y su barra de vida encima. **Arrastrando desde un botón**: el alcance (círculo tenue) y la forma de la habilidad según su perfil (cono con `angle`, franja con `width`, abanico con varios proyectiles, círculo con `radius` en el punto); volver al botón tras apuntar **cancela** (deja de lanzar hasta soltar). Comprobado con `capture_screens -- tactil` (la habilidad 1, de tres proyectiles, enseña su abanico y sigue lanzándose); captura `docs/capturas/movil/150_vista_previa_abanico.png`. Pruebas del objetivo pegajoso en `_test_touch_controls`.

### [x] T151 · Modo automático para el ataque principal · S
Origen: R7
- Un interruptor junto al botón grande: el ataque principal se lanza solo contra lo que hay cerca mientras te mueves con el joystick (como en los ARPG de celular); el resto de habilidades, a mano. Se apaga solo al abrir una ventana.
- Hecho: interruptor redondo «AUTO» (40 px, verde con un aro que gira si está encendido; gris; tachado si la habilidad 1 no se puede lanzar sola: aura, invocación, canalizada, contenedor o de activación). `SkillController.touch_auto`: con él, el auto-ataque de siempre (`_try_auto_attack`, a 320 px) también funciona caminando y apunta al objetivo de la mira (pegajoso o fijado, T150) si está a tiro. Espera mientras hay una ventana, la pausa o una escena encima (`Touch.ui_busy`, que pone `TouchControls`). **Decisión**: en «esquina» va encima de la esquiva (junto al botón grande no queda hueco entre los dos anillos y el orbe) y en «dos arcos», debajo de la habilidad 1; el editor de disposición (T137) también lo mueve. Comprobado: `capture_screens -- auto tactil` (2 s caminando con 6 enemigos cerca: apagado 0 lanzamientos, encendido con un toque 2) y `-- solapes` sigue en 0; capturas `docs/capturas/movil/151_*`.

## Fase 34 — Que se sienta bien pegar

### [x] T152 · Golpes con peso en el celular · M
Origen: R7
- Enemigo golpeado: destello blanco de 60 ms y un empujón corto; los críticos, más grandes y con un número que salta.
- Números de daño legibles en el teléfono: más grandes, menos (se suman los golpes seguidos al mismo enemigo en un solo número que crece) y opción para dejar solo los críticos.
- Muertes con un estallido de partículas del color del enemigo y botín que sale volando hacia afuera (ya existe el arco; más fuerza y un rebote).
- Hecho: al mirar el código, buena parte ya estaba: destello al golpear (`FLASH_TIME` 0,12 s), retroceso según el daño y más fuerte con críticos, respingo de los críticos hasta en los jefes, hitstop y temblor en los críticos, números que se suman por enemigo y muertes con su efecto y su sonido según lo que mató (`ImpactFx.death`). Lo nuevo, para el celular: **números de daño** un 35 % más grandes y sumando los golpes seguidos durante 0,7 s (antes 0,35: menos cifras y más grandes); el **crítico salta más**; opción «Números de daño: todos / solo críticos / no» en Pausa → Interfaz (lo guardado como sí/no vale igual); el **botín** sube más alto al salir (arco de 95 px, antes 70) y da dos botes de 14 px al caer (antes uno de 8, apenas se veía). Pruebas en `_test_touch_controls`. **Decisión**: el estallido de muerte y el destello ya cumplían; no se tocan.

### [x] T153 · Ritmo de las peleas · M 🛑
Origen: R7
- Medir con la telemetría local (T64) una partida en el celular: tiempo entre peleas, enemigos por minuto, tiempo para matar un normal y un raro; propuesta de ajustes para el celular (manadas algo más juntas y más cerca del camino, menos paseo vacío, recompensa visible tras cada manada) y cadena de bajas (contador «x5» que da un pequeño bono de velocidad).
- Se para para que el usuario lo pruebe y diga si se siente mejor antes de seguir.
- Medido (telemetría local de este equipo, 26 visitas, 75 min, la mayoría en el PC): **solo el 34 % del tiempo es pelea**, pero en pelea caen 141 enemigos por minuto: mucho paseo y ráfagas muy cortas. En la primera zona (zona1, la que juega el usuario en el celular) la pelea es el 32 %; hubo zonas con varios minutos sin un solo enemigo. No hay telemetría del celular (se guarda en el propio teléfono).
- Hecho: **racha de bajas** (`KillStreak`): las bajas con menos de 2,5 s entre ellas se encadenan; desde 5, «x5 · RACHA» arriba en el centro con una barrita que se vacía y +10 % de velocidad de movimiento (+20 % desde 15, +30 % desde 30) mientras dure; al cortarse, una racha de 8 o más deja tokens a tus pies (uno cada cuatro bajas) con un aviso: una **recompensa visible tras cada manada**. Pruebas en `_test_touch_controls`; versión **3.1.2** (código 7) preparada para publicar en WalBernal/PathOverflow (`build/PathOverflow.apk` y `build/latest.json`).
- 29-10-2026, prueba del usuario (Samsung Galaxy Z Fold 7, pantalla exterior): **la interfaz sigue parpadeando** (desaparece y vuelve, también el menú de pausa). Sospechosos: la copia de pantalla de los efectos (`BackBufferCopy` de `WorldPost`, que con el renderizador Mobile podría pintarse a ratos encima de la interfaz) o la zona segura (T142). Versión **3.1.3**: opción «Efectos de pantalla: sí/no» en Pausa → Gráficos (quita las dos pasadas que copian la pantalla), la zona segura ya no se vuelve a mirar cada medio segundo (cada 3 s y solo si el cambio se mantiene) y la línea del contador de FPS dice en táctil la zona segura, cuántas veces se recolocó la interfaz y el renderizador. Pendiente: que el usuario pruebe con los efectos apagados. Si no basta, siguiente paso: un APK con el renderizador Compatibility (OpenGL).
- **Propuesta pendiente de la prueba del usuario** (no aplicada: cambia el equilibrio): en el celular, manadas un 30 % más juntas y más cerca del camino y menos espacio vacío entre ellas, para pasar del 34 % de pelea a ~50 %.
- 31-10-2026: el parpadeo se fue con el renderizador Compatibility (3.2.1, ver T159). Se cierra; la propuesta de las manadas pasa a la lista de T179 como pregunta.

### [x] T154 · Partidas cortas · S
Origen: R7
- «Continuar» de un toque en la pantalla de título (último personaje, donde lo dejaste) y un objetivo corto a la vista al entrar (la siguiente misión o «limpia esta zona: 0/N»), pensado para jugar 5 minutos.
- Hecho: botón dorado **«▶ Continuar · Nombre · Nv 21 · Zona»** centrado encima de la indicación del título (solo si hay personajes; `CharacterSaves.continue_label`, el primero de `list_all`, que ya ordena por última partida): carga el personaje y entra al mundo sin pasar por la lista; tocar el resto de la pantalla sigue llevando a la lista («toca la pantalla para ver tus personajes»). Al entrar, el aviso de arriba enseña 6 s el **objetivo** (`QuestLog.short_goal` y `QuestLog.entry_goal`: «Objetivo · Misión: paso (2/5)» o, sin misiones fuera de una zona segura, «limpia esta zona (0/N)»); `Hud.flash` acepta cuánto dura. Comprobado con `capture_screens -- continuar` (2400×1080 táctil y 1600×900); captura `docs/capturas/movil/154_titulo_continuar_tactil.png`. Pruebas en `_test_quests`.

### [x] T155 · Revisión en el teléfono · S 🛑
Origen: R7
- Versión nueva publicada en WalBernal/PathOverflow (llega por el aviso de actualización) y una lista corta con preguntas sobre la sensación: controles, golpes, ritmo y si algo tapa la pantalla.
- 30-10-2026: absorbida por el Roadmap 8.0: cada etapa termina con su versión publicada y su revisión en el teléfono (T159, T164, T170, T173); las preguntas de sensación (y el parpadeo pendiente de T153) van en la lista de T159.

---

# Roadmap 8.0 — tamaño y estética: personajes y una interfaz de ingeniería (30-10-2026)

Pedido del usuario tras probar la 3.1.3 en el celular: los sprites en general se ven muy chicos (crecer un 30-50 %), y una mejora estética de los sprites del jugador y los NPC y de la interfaz, más acorde con la temática de ingeniería de software, datos e inteligencia artificial. **Origen: R8.** Mismo protocolo; 🛑 = parar y esperar el visto bueno.

**Cada etapa termina con una versión para probar**: se sube `application/config/version` en `project.godot`, `tools/run_checks.ps1 -Rapida` en `[OK]`, `tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -Notas "…"` (deja `build/PathOverflow.apk` y `build/latest.json`; llega al teléfono por el aviso de actualización de T140) y `tools/build_release.ps1` (deja `build/PathOverflow.exe` y el instalador de Windows). Subir la release a GitHub lo hace el usuario (es publicar). Cada tarea añade **pruebas cortas** en `tests/test_core.gd` (la línea «Prueba:» dice cuáles) y se comprueba con `-Rapida` (+ `-Zonas` si toca zonas concretas).

Diagnóstico de partida (leído en el código y en las capturas):
- La cámara del jugador no tiene zoom: en 1600×900 de lienzo el personaje mide ~50 px (≈ 5,5 % del alto); en un teléfono de 2400×1080 el lienzo se ensancha (`stretch/aspect="expand"`) y aún se ve más mundo y más chico.
- El jugador se dibuja a 1,06 (`Player.PLAYER_SPRITE_SCALE`) y los NPC a 1,12 (`Zone._add_npc_sprite`): tamaños que no casan. Las hojas (`PlayerSheet`) son celdas de 64×80 horneadas del dibujo procedural de `CharacterAppearance` (`tools/bake_player_sprites.gd`): poco detalle para crecer sin verse borroso o plano.
- La interfaz (`UiStyle`: dorado `d9a441`, latón, remaches, orbes de vida y maná) es de fantasía oscura tipo Diablo; los textos y los nombres sí son de oficina y de software. Falta que la *forma* cuente el mismo chiste: terminal, IDE, paneles de monitoreo, grafos de datos, redes neuronales.

## Fase 35 — Todo más grande en el celular (versión 3.2.0)

### [x] T156 · Tamaño del mundo · M
Origen: R8
- Opción «Tamaño del mundo: 100 / 115 / 130 / 150 %» en Pausa → Gráficos: zoom de la `Camera2D` del jugador (agranda personajes, enemigos, botín y efectos sin tocar la lógica ni las colisiones). Por defecto **130 % en táctil** y 100 % en el PC; se guarda en `settings.cfg`.
- Que lo respeten las escenas (`CutscenePlayer` ya parte de `_base_zoom`), el filtro de píxeles de `WorldPost`, el clima, los indicadores de enemigos fuera de cámara y el minimapa (que no cambia).
- Revisar que a 150 % en 1600×720 el alcance del auto-ataque (320 px) y de la mira sigan dentro de la vista; si no, tope por alto de pantalla.
- Prueba: `GraphicsQuality` (o donde viva) devuelve 1,3 en táctil y 1,0 en el PC por defecto; con cada opción y en 1600×720 / 2400×1080, el rectángulo visible contiene un círculo de 320 px alrededor del jugador. Capturas `docs/capturas/tamano/156_*` antes y después.
- Hecho: «Tamaño del mundo: auto / 100 / 115 / 130 / 140 %» en Pausa → Gráficos y datos (`GraphicsQuality.world_zoom`, `graphics/world_zoom` en `settings.cfg`); auto = 130 % en el celular y 100 % en el PC. `Player.apply_world_zoom` pone el zoom de su `Camera2D` al entrar en cada zona, al cambiar la opción y al cambiar el tamaño de la vista. **Decisión**: sin 150 %; el tope es el zoom que deja ver el alcance del auto-ataque (`WORLD_ZOOM_REACH` = `AUTO_ATTACK_RANGE`, 320 px) en el lado corto del lienzo: con 900 px de alto, 1,406, así que como mucho 140 %. Lo demás ya usaba la escala del lienzo (cámara de la zona, clima, enemigos en pantalla, luces de `WorldPost`, escenas a partir de `_base_zoom`); solo faltaban el radio de la luz del jugador y la rejilla del filtro pixel art de `WorldPost`, que ahora crecen con el zoom. Capturas `docs/capturas/tamano/156_*` (campamento y zona 1 a 100, 130 y 140 % en 2400×1080, con `capture_screens -- tamano`). Pruebas en `_test_touch_controls`.

### [x] T157 · Personajes del mismo tamaño y más legibles · M
Origen: R8
- Una sola escala para jugador y NPC (constante compartida en `PlayerSheet`), un 15 % mayor que hoy; nombres, «!» y «?» de los NPC colocados según la altura real del sprite (hoy van a −52 / −70 px fijos).
- Lectura sobre suelos oscuros: contorno oscuro de 1 px y sombra elíptica bajo los pies (jugador, NPC y compañeros); el jugador, además, un anillo suave de su color.
- Enemigos: tamaño mínimo en pantalla para los más pequeños (que no queden en 12-16 px) sin cambiar su radio de colisión; la zona para tocarlos/seleccionarlos crece con el dibujo.
- Prueba: jugador y NPC usan la misma escala; la altura del sprite en pantalla con el tamaño por defecto del celular es ≥ 8 % del alto de la vista; ningún tipo de `enemies.json` se dibuja por debajo del mínimo.
- Hecho: `PlayerSheet.WORLD_SCALE` = 1,22 para el jugador (`Player.PLAYER_SPRITE_SCALE`) y los NPC (sprite y dibujo de respaldo); nombre, «!»/«?» y la zona para tocar un NPC, a su altura (`Zone.NPC_LABEL_Y`, `NPC_MARK_Y`). **Contorno** oscuro de 1 píxel de hoja: una silueta por capa debajo de todas (`player_outline.gdshader`, solo lo bien opaco: la sombra de los pies, que ya venía horneada, no se contornea); vale también para el creador. **Anillo** elíptico del color de la clase bajo los pies del jugador. **Enemigos**: `EnemyManager.draw_size` con un mínimo de 40 px (`MIN_DRAW_SIZE`; un normal mide 49) y `visual_radius` para barra, avisos, aturdido, muerte y `hover_index` (tocar/apuntar), sin cambiar el radio de choque. **Corrección del diagnóstico**: los más chicos no medían 12-16 px sino ~29 (los enjambres); y el cuerpo mide 41 píxeles de hoja, no ~50, así que con el 130 % de T156 el personaje ocupa un **7,4 %** del alto en el celular (antes 4,6 %: ×1,5, lo pedido) y no el 8 %; la prueba pide ≥ 6,5 % y ×1,45. Capturas `docs/capturas/tamano/157_*`. Pruebas en `_test_touch_controls`.

### [x] T158 · Lo que flota sobre el mundo, a la medida · S
Origen: R8
- Con el zoom, los textos del mundo (nombres, números de daño, rótulos de salidas, nombres de objetos en el suelo, barras de vida de enemigos) no deben crecer sin control ni pisarse: tamaño de letra compensado por el zoom con un mínimo legible, y el agrupado de botín y de números de T152 con la nueva escala.
- Prueba: `capture_screens -- solapes` sigue en 0 en las 16 configuraciones táctiles con cada tamaño de mundo; tamaño efectivo de letra de los números de daño ≥ 18 px de pantalla en 1600×720.
- Hecho: todo el texto del mundo pasa por `Accessibility.world_size` (nombres de enemigos, NPC —que antes iban fijos a 14— y compañeros, etiquetas del botín, números de daño, «git stash», rótulos de la zona), que ahora divide por √zoom (`Accessibility.world_zoom`, lo pone `Player.apply_world_zoom`): en pantalla la letra crece √zoom (al 130 %, un 14 %) y el dibujo el zoom entero, así que las etiquetas ocupan menos mundo y se pisan menos; el agrupado de botín y de números trabaja en el mundo y lo aprovecha sin cambios. Los números de daño quedan en 18,4 px reales en 1600×720. Lo decorativo con letras (bits, «404», carteles) crece con el mundo. `capture_screens -- solapes`: 0 en las 16 configuraciones y en el PC (el HUD no depende del zoom). Pruebas en `_test_touch_controls`.

### [x] T159 · Versión 3.2.0 y revisión en el teléfono · S 🛑
Origen: R8
- Versión 3.2.0: APK + `latest.json` + ejecutable de Windows (ver la cabecera del roadmap); lista corta `docs/prueba_celular_3.2.md`: ¿el tamaño por defecto se siente bien o prefieres 115/150?, ¿se ve suficiente alrededor para esquivar?, ¿se lee el texto?, ¿la interfaz sigue parpadeando con «Efectos de pantalla» apagado? (pendiente de T153), y las preguntas de sensación de T155 (controles, golpes, ritmo, algo que tape la pantalla).
- Preparado (30-10-2026): `config/version="3.2.0"`; `run_checks -Rapida` en `[OK]`; `publicar_version.ps1 -Repo WalBernal/PathOverflow` dejó `build/PathOverflow.apk` (45 MB, código 9, clave de depuración: se instala encima) y `build/latest.json`; `build_release.ps1` dejó `build/PathOverflow.exe` y `build/PathOverflow-Setup.exe` (Linux y macOS saltan: faltan sus plantillas). Lista `docs/prueba_celular_3.2.md` (las opciones de tamaño son 115/130/140: ver T156). README: la 3.2 en «Versiones». **Falta (usuario)**: subir el APK y el `latest.json` a una release `v3.2.0` de WalBernal/PathOverflow y probar en el teléfono.
- 30-10-2026, prueba del usuario: **el parpadeo de la interfaz volvió** (se había ido en la 3.1.3). Entre la 3.1.3 y la 3.2.0 ningún cambio toca la interfaz (zoom de cámara, contornos, textos del mundo, «Continuar»); que se borre toda la interfaz, pausa incluida, a ratos y no siempre, apunta al renderizador Mobile (Vulkan) del teléfono. **Versión 3.2.1**: el celular usa el renderizador **Compatibility** (OpenGL ES 3, `rendering_method.mobile="gl_compatibility"`), el paso siguiente que T153 dejó anotado; comprobado en el PC con `--rendering-method gl_compatibility`: luz, filtro pixel art, zoom y HUD iguales y sin errores de shader. La línea del contador de FPS dice el renderizador («gl_compatibility»). Pendiente: que el usuario confirme si se fue. También pidió **otra estética para los personajes** (ver T160).
- 31-10-2026: **confirmado, el parpadeo se fue** con la 3.2.1.

## Fase 36 — Personajes con presencia (versión 3.3.0)

### [x] T160 · Hojas del personaje a doble resolución · L
Origen: R8
- **Referencia del usuario (30-10-2026)**: un caballero chibi en pixel art (`docs/capturas/personajes/referencia_usuario.png`): cabeza grande con casco que ocupa ~40 % de la altura, cuerpo compacto, contorno oscuro grueso en toda la silueta, sombreado en tres tonos con un brillo duro, colores saturados con un acento fuerte (bufanda roja) y el arma bien visible. Pide «esa estética, pero con una resolución más definida, menos pixeleado». Se sigue esa forma (proporciones, contorno, sombreado, acento) con los atuendos de oficio de T161, no con armadura de fantasía.
- Hornear las capas a 128×160 por celda (hoy 64×80) con más detalle en el dibujo de `CharacterAppearance` y el aspecto de la referencia: proporciones chibi (cabeza grande, ~2,5 cabezas de alto), contorno oscuro de 2 píxeles de hoja horneado (sustituye al de T157), sombreado en tres tonos con brillo y luz de borde, ojos y manos legibles y 8 cuadros al caminar (hoy 6). Dibujadas a la mitad, en el celular cada píxel de hoja queda en ~1 píxel de pantalla (hoy ~2): más definido, menos pixelado. Se mantiene el sistema de máscaras y tintes (los colores del creador siguen valiendo) y el tamaño en pantalla de T157 (se dibuja a la mitad: más nitidez, no más grande).
- Revisar el creador de personaje, los retratos y la vista previa (`AppearancePreview`) con las hojas nuevas.
- Prueba: dimensiones de cada hoja = columnas × CW por filas × CH; ningún cuadro vacío; los pies caen en `FEET` en todos los cuadros (fila de píxeles opaca más baja); el canal G de las máscaras solo tiene capas válidas (`LAYER_*`).
- Hecho: **1,5× y no 2×** (decisión): celdas de **96×120** (`BAKE_SCALE` 1,59, pies en (48, 105)); a 2× (128×160) las hojas pasaban de 4096 px de ancho (límite de muchos celulares) y sumaban ~230 MB de textura. Además, **un archivo por variante** (`PlayerSheet.file_of`: `hair_3.png`, `weapon_0.png`...; antes una hoja con todas apiladas): solo se carga lo que alguien lleva puesto. En el celular cada píxel de hoja queda en ~1,2 píxeles de pantalla (antes ~1,9). **Estilo de la referencia**: cabeza grande (`CharacterAppearance.HEAD_R` 8,6, antes 7), ojos chibi grandes con brillo (más abajo: en las hojas el pelo va encima de la cara y los cortaba), piel en dos tonos, atuendo en tres (sombra a la derecha y abajo, brillo en el hombro), sombra en las piernas, brillo en el pelo y contorno oscuro grueso (2 píxeles de hoja en ocho direcciones, `PlayerSprite.OUTLINE_OFFSETS`). Para que los brillos pasen del color base, la luz se hornea en gris (`PlayerSheet.LUM_GRAY` 0,65) y el shader la multiplica (`light_gain`). **8 cuadros al andar** (34 columnas). El tamaño en el mundo no cambia (`WORLD_SCALE`). Los retratos y el creador usan el mismo dibujo, así que heredan la cabeza y el sombreado. Capturas `docs/capturas/personajes/160_*` (`capture_screens -- capas`: a la izquierda el dibujo con formas, a la derecha la hoja). Pruebas en `_test_player_sheet` (cuadrícula por variante, ≤ 4096 px, cuadros con dibujo, pies en `FEET` de pie, canal G válido).

### [x] T161 · Atuendos de oficio para las siete clases · M
Origen: R8
- Una silueta reconocible por clase, coherente con su nombre: **Técnico de Soporte** (chaleco con herramientas y gafete), **Tester QA** (bata con lupa y etiquetas de bug), **Desarrolladora Frontend** (sudadera con capucha y paleta de colores flotante), **Ingeniera de Prompts** (audífonos y burbujas de texto/tokens), **Científico de Datos** (tableta con gráfica holográfica), **Ingeniero DevOps** (casco con cables y LEDs de estado), **Full Stack** (mochila con laptop y stickers).
- Detalles que brillan (LEDs, pantallas, hologramas) como capa fija con un poco de emisión; las armas conservan su mecánica pero con aspecto de oficio (teclado mecánico, cable de red, servidor de bolsillo…), si el usuario lo aprueba en T164.
- Prueba: cada clase de `classes.json` tiene su atuendo por defecto; dos clases no comparten silueta (capa de accesorio distinta).
- Hecho: capa nueva **«gear»** (equipo de oficio) encima de todo, un archivo por clase (`gear_0..6`, orden de `CharacterAppearance.GEARS`): **Soporte** chaleco reflectante naranja con franjas y gafete con cordón; **QA** bata blanca larga, etiqueta roja de bug y lupa al cinto; **Frontend** capucha morada con cordones y paleta de cuatro colores flotando; **Prompts** audífonos de neón y globo de texto «...»; **Datos** tableta holográfica translúcida con una gráfica de barras; **DevOps** casco de obra amarillo con LED verde y cable al hombro; **Full Stack** mochila con laptop y stickers (tirantes de frente). Se hornea comparando el dibujo con y sin el equipo (`_save_overlay`), así que puede ser de cualquier color (las capas fijas de antes no admitían colores «de capa» como el naranja). Va con la clase, no con el guardado: `CharacterAppearance.with_gear` en el jugador y en la vista previa de la lista de personajes (el creador no lo enseña: la clase se elige en el prólogo). **Armas de oficio** (teclado, cable...): pendiente del visto bueno de T164. Captura `docs/capturas/personajes/161_equipos.png` (`capture_screens -- equipos`: las siete clases de frente, de lado, de espaldas y atacando). Pruebas en `_test_player_sheet`.

### [x] T162 · NPC con identidad · M
Origen: R8
- Cada NPC de `npcs.json` con un rasgo propio y una animación de reposo que lo cuente: Aida (la Senior) con taza de café y lentes, Mario (el Practicante) cargando cajas o un monitor, Rafa (SysAdmin) tecleando en una laptop, Nacho revendiendo RAM de una maleta, B.O.B. como robot con pantalla-cara, el Fantasma del DBA translúcido con tablas flotando, Clara con tablero de incidentes…
- Retratos del diálogo redibujados con el mismo estilo que los sprites nuevos.
- Prueba: no hay dos NPC con la misma apariencia completa; todo `idle_prop` o animación de `npcs.json` existe en la hoja o en el dibujo.
- Hecho: los objetos van en la misma capa horneada que el equipo de clase (`CharacterAppearance.NPC_PROPS`, `gear` en la apariencia de `npcs.json`; los que se llevan en la mano siguen a la mano en cada pose): **Aida** taza de café, **Mario** cargando un monitor, **Rafa** laptop con texto verde, **Nacho** maleta abierta con RAM, **B.O.B.** cabeza-pantalla con cara cian y antena, **Iris** mapa con la ruta en rojo, **Tomás** la bata del QA, **Fantasma del DBA** tablas flotando y translúcido (`ghost`), **Clara** portapapeles de incidentes, **El Recolector** bolsa de basura al hombro, **Sindicato** cartel «404», **M. Páez** planos enrollados, **Eugenio** una rosa, **Berta** la pila CR2032. **Reposo** (`idle` en `npcs.json`, `Zone.npc_pose`): Rafa **teclea** (estado nuevo `type`, 2 cuadros con las manos al frente) y Aida **da un sorbo** cada 5 s (la taza sube con la mano); los demás respiran como antes. Sus «yo» de otros actos (Rafa en la BIOS, Mario...) llevan lo mismo. **Retratos**: heredan la piel en dos tonos y el brillo del pelo de T160, pero no se redibujaron aparte (la cabeza de retrato ya tenía detalle). Captura `docs/capturas/personajes/162_npcs.png` (`capture_screens -- npcs`: de frente y de lado en mitad de su gesto). Pruebas en `_test_npcs_and_boss_intro` (teclear y sorbo, objetos e `idle` válidos y horneados, ninguna persona igual a otra).

### [x] T163 · Animación con más vida · S
Origen: R8
- Respiración en reposo, rebote al caminar y estiramiento al atacar en jugador y NPC; polvo al esquivar; silueta del jugador (contorno de su color) cuando un obstáculo lo tapa.
- Prueba: `PlayerSprite.set_pose` con cada estado devuelve un cuadro dentro del rango de su estado; la escala de respiración nunca pasa de ±4 %.
- Hecho: `PlayerSprite.life` pone encima de los cuadros horneados una escala desde los pies y una elevación (jugador y NPC): **respira** en reposo (±2 % de alto), al **andar** se aplasta un 3 % al pisar y se eleva 1,6 píxeles de hoja entre pisadas, al **atacar** o disparar se estira un 7 % justo cuando llega el golpe (`impact_fraction`) y al lanzar se alarga un poco. **Polvo al esquivar**: seis bocanadas que salen de los pies hacia atrás y se deshacen en 0,45 s (`Player._dust`, debajo del personaje). **Silueta tras obstáculos: no hace falta** (decisión): la zona entera (obstáculos y decorado) se dibuja debajo del jugador, así que nada lo tapa; lo único encima es la capa de los NPC, que no se cruza con él en pelea. Pruebas en `_test_player_sheet` (respiración ≤ ±4 %, pisada y estiramiento, cada estado en sus cuadros).

### [x] T164 · Versión 3.3.0 y revisión en el teléfono · S 🛑
Origen: R8
- Versión 3.3.0 (APK, `latest.json` y Windows) y capturas de las 7 clases y de los NPC del campamento en `docs/capturas/personajes/`; el usuario elige qué atuendos o armas cambiar antes de seguir.
- Preparado (31-10-2026): `config/version="3.3.0"`; `run_checks -Rapida` en `[OK]`; `build/PathOverflow.apk` (45 MB, código 11, renderizador Compatibility de la 3.2.1), `build/latest.json`, `build/PathOverflow.exe` y el instalador. Capturas: `161_equipos.png` (las 7 clases en 4 poses), `162_npcs.png`, `164_campamento_130.png` y `164_zona1_130.png` (en partida, 2400×1080 al 130 %). Lista `docs/prueba_celular_3.3.md` (incluye si el parpadeo se fue con la 3.2.1 y si quiere armas de oficio). README: la 3.3 en «Versiones». **Falta (usuario)**: subir la release `v3.3.0` a WalBernal/PathOverflow, probar y decidir atuendos, armas y NPC.
- 31-10-2026, respuesta del usuario: (1) **el parpadeo se fue** (renderizador Compatibility, 3.2.1); (2) quiere **armas de oficio**; (3) quiere **rehacer los personajes con estética de RPG**, no una mezcla de lo actual con chibi: desde el acto I (dentro del servidor ya son datos) pasan a ser héroes de RPG; los del prólogo se quedan como están; (4) la app necesita un **logo** (hoy el ícono es un círculo amarillo). Todo va a la **Fase 36b** (versión 3.4.0); la interfaz pasa a la 3.5.0 y lo último a la 3.6.0.

## Fase 36b — Héroes de RPG dentro del servidor y un logo (versión 3.4.0)

Pedido del usuario al revisar la 3.3 (31-10-2026). **Origen: R8b.** En el prólogo los personajes siguen siendo oficinistas (el dibujo con formas de `CharacterAppearance`, que el prólogo usa directamente); al entrar al servidor, en el acto I, se compilan como héroes de RPG. Lo de T160-T163 que no es el dibujo (hojas por capas y por variante, contorno, `PlayerSprite.life`, polvo al esquivar, objetos de NPC) se reutiliza; el dibujo chibi se sustituye en el juego, no se mezcla.

### [x] T174 · Logo de la app · S
Origen: R8b
- Ícono propio en pixel art, legible a 48 px: fondo oscuro redondeado, la pila que se desborda del logo del título (barras verdes y bloques rojos cayendo) entre `<` y `/>`, con el borde del color de acento. Generado por código (`tools/generate_app_icon.gd`, como los demás generadores) en `assets/icons/`: `icon.png` (1024), `icon_foreground.png` y `icon_background.png` para el ícono adaptable de Android (432, con la zona segura del 66 %), y el `.ico` de Windows si la plantilla lo admite.
- `project.godot` (`config/icon`) y el preset de Android (`launcher_icons/*`) apuntan a ellos; el SVG de ahora (un `{;}` que Godot no dibuja: por eso se ve solo el círculo) se retira.
- Prueba: los archivos existen con su tamaño y el centro del primer plano cae dentro de la zona segura (66 %) del ícono adaptable. Captura del ícono a 48, 96 y 512 px.
- Hecho: `tools/generate_app_icon.gd` (sin ventana, `--headless`) dibuja el motivo en una rejilla de 48×48 celdas (cuatro barras verdes con luz y sombra, dos bloques rojos que se salen y un trozo cayendo, «<» y «/>» en verde agua, contorno oscuro) y lo agranda sin suavizar: `assets/icons/icon.png` (1024, fondo `0f141c` redondeado con borde), `icon_foreground.png` y `icon_background.png` (432, motivo en el 66 % central; el fondo, con una rejilla tenue de puntos) e `icon_monochrome.png` (silueta para los íconos temáticos de Android 13+; sin él salía el de Godot). `config/icon` y los presets (Windows y Android `launcher_icons/*`, también en `export_presets.example.cfg`) apuntan a ellos; fuera `icon.svg`. Comprobado: el APK lleva sus `mipmap-*/icon*.webp`. El `.exe` de Windows solo cambia de ícono si el editor tiene configurado `rcedit` (Editor → Ajustes → Exportar → Windows); el de la ventana del juego sí cambia. Captura `docs/capturas/interfaz/174_icono.png` (48, 96 y 192 px y el adaptable). Prueba en `_test_mobile_defaults`.

### [x] T175 · Diseño de los héroes de RPG · M 🛑
Origen: R8b
- Dibujo nuevo y propio, `RpgAppearance` (no se toca `CharacterAppearance`, que se queda para el prólogo, los retratos y el creador): figura de RPG en vista 3/4 como la referencia (`docs/capturas/personajes/referencia_usuario.png`), proporciones de héroe pixel art (cabeza ~1/3, armadura con volumen), contorno oscuro, sombreado en tres tonos y brillos.
- Un arquetipo por clase, que ya está en sus ids: **guerrero** (Técnico de Soporte) caballero con armadura pesada y yelmo; **duelista** (Tester QA) espadachín con capa corta y sombrero de ala; **exploradora** (Frontend) exploradora con capucha y capa; **hacker** (Ingeniera de Prompts) pícara con capucha y máscara; **hechicero** (Científico de Datos) mago con túnica larga y sombrero; **templario** (DevOps) paladín con armadura dorada y tabardo; **full_stack** caballero-mago con media armadura y capa. Detalles «de datos» que cuentan dónde están: runas como código, gemas que parpadean como LEDs, bordes de circuito en capas y escudos.
- Los colores del creador siguen valiendo: el **atuendo** tiñe telas (capa, tabardo, túnica), los **detalles** los adornos, y la piel, el pelo y los ojos se ven donde el casco o la capucha los deja.
- Hoja de muestra (`capture_screens -- rpg`): las 7 clases de frente, de lado, de espaldas y atacando, junto al personaje actual. **Se para hasta que el usuario elija** qué clases cambiar antes de hornear todas las poses.
- Hecho: `scripts/character/rpg_appearance.gd` con el mismo contrato y lógica de poses que el oficinista (así se hornea con la misma cuadrícula) y la clase en `a["rpg"]`: **guerrero** yelmo cerrado con rendija y cresta, peto y hombreras de acero, tabardo de su color con una cruz de los detalles, runas en el peto y capa; **duelista** sombrero de ala con cinta y pluma, camisa blanca, chaleco abierto y banda cruzada, capa corta; **exploradora** capucha y capa de su color, correa y carcaj con flechas, bolsa al cinto; **hacker** capucha oscura, máscara, ojos cian como LEDs, correas cruzadas y bufanda; **hechicero** sombrero de punta doblado con runa, túnica hasta los pies con ruedo y runas; **templario** armadura y yelmo dorados con carrilleras y penacho, tabardo y capa; **full_stack** abrigo largo, una hombrera y peto de acero, diadema con gema cian. Botas, guantes y sombreado en tres tonos con brillos. Lo fijo (acero, oro, cuero, runas) se dibuja gris en el pase de identificación (`_fixed`): el dorado o el marrón se clasificarían como «pelo». Captura `docs/capturas/personajes/175_rpg.png` (a la izquierda, el oficinista; a escala de la hoja, ampliada sin suavizar y con el contorno grueso). Prueba en `_test_player_sheet`. **Esperando la elección del usuario.**
- 31-10-2026, respuesta del usuario: **no se parece a lo que espera**; quiere los personajes como los del **Tiny RPG Character Asset Pack 01** de Zerie (https://zerie.itch.io/tiny-rpg-character-asset-pack; referencia en `docs/capturas/personajes/referencia_zerie.png`). Licencia (leída en la página): uso y modificación permitidos en juegos, también comerciales; **prohibido redistribuirlos o volver a subirlos**, modificados o no, y usarlos para entrenar IA o en NFT; crédito opcional. El pack completo (22 personajes, 2 MB) cuesta 2,50 USD o más; gratis solo el Soldado y el Orco. Celdas de 100×100, **solo de lado** (izquierda/derecha), con reposo, andar, ataque, bloqueo, golpe y muerte. **Decisión**: T176 pasa a **usar el pack** (lo compra y descarga el usuario) en vez de dibujar los héroes por código; `RpgAppearance` queda como respaldo mientras tanto.

### [x] T176 · Hojas de RPG del jugador · L
Origen: R8b
- **Plan definitivo (31-10-2026, usuario)**: **sprites propios**, no los del pack: el usuario descargó la versión gratis (`assets/third_party/zerie/`, fuera de git y con `.gdignore`, así ni se sube ni entra en el juego) solo como **referencia de estilo** (y Final Fantasy Tactics), con temática de ingeniería de software e IA, para poder subirlos a git y probarlos en el celular. Medido en el pack: personajes de ~17×21 píxeles en celdas de 100×100, contorno negro puro, ~30 colores, cabeza grande; animaciones de reposo 6, andar 8, ataque 6, golpe 4 y muerte 4, solo de lado. **Cómo**: `PixelHero` dibuja cada cuadro **píxel a píxel** a esa escala diminuta (cabeza y torso de cada clase diseñados como rejillas de píxeles con su paleta; piernas, brazos y arma trazados píxel a píxel según la pose; contorno negro automático), con los colores del creador, y arma la hoja al cargar (en caché); `HeroSprite` la dibuja ampliada sin suavizar, de lado y volteada según hacia dónde mira, con la misma API que `PlayerSprite`. Nada copiado ni calcado del pack.
- Hecho (31-10-2026): `scripts/character/pixel_hero.gd` (celdas de 48×48, pies en (24, 44), héroes de ~23 píxeles; reposo 4, andar 8, ataque 6, lanzar 4, golpe 3, morir 4 —los dos últimos tumbado—, esquiva 3, canalizar 2, disparar 4 y teclear 2) con las 7 clases: **Soporte** caballero con yelmo, visor HUD cian, micrófono, tabardo y capa; **QA** espadachín con sombrero de ala y pluma, monóculo-lupa, camisa blanca y chaleco; **Frontend** capucha y capa con la bufanda de la paleta de colores; **Prompts** pícara oscura con ojos-LED cian, máscara y el «>» de un prompt en el pecho; **Datos** mago con sombrero de punta con una gráfica en runas y túnica; **DevOps** paladín con casco de obra dorado con LED y tabardo; **Full Stack** diadema con gema, hombrera y abrigo. Armas trazadas píxel a píxel (espada, hacha, maza, daga). Barba en el color del pelo si la tiene. `scripts/character/hero_sprite.gd` (×2,3 en el mundo, volteado según hacia dónde mira, tinte de golpe y muerte con `hero_tint.gdshader`, `PlayerSprite.life`); el **jugador** ya lo usa en todas las zonas (el prólogo no usa `Player`). Capturas `docs/capturas/personajes/176_heroes.png` (las 7 clases en 13 cuadros) y `176_en_partida.png`. Pruebas en `_test_player_sheet` (rejillas y paleta, cuadros con dibujo y sin flotar, cuadros por estado, caché). **Falta**: la lista de personajes y la hoja de personaje siguen con el oficinista.
- ~~Plan anterior: con el pack de Zerie.~~
- **31-10-2026, estilo del usuario (definitivo)**: el usuario diseñó en otra sesión una lámina de cinco personajes de frente (`docs/capturas/personajes/propuestas_frente.png`: **A** Dev Glitcheado —el alumno recién absorbido: sudadera, gafete y glitches—, **B** Paladín Firewall, **C** Mago Neural, **D** Ladrón Root, **E** Invocador IA) y pidió que el personaje principal **siga siendo el alumno del creador** y que **su look cambie con lo que equipa**; el prólogo, como está; los NPC, después. Los `PixelHero` por clase se retiran (y `RpgAppearance` de T175).
- Hecho: `tools/import_hero_art.gd` lee la lámina (5 píxeles de pantalla por píxel, la misma plantilla en las cinco: la loseta y la cara coinciden píxel a píxel) y la corta en `assets/sprites/hero/`: `base.png` (A sin la loseta), `head_/torso_/legs_` de B-E (lo que cada uno cambia respecto a A en cabeza, torso con brazos y piernas) y las armas (`weapon_sword` de B, `weapon_dagger` de D, `weapon_staff` de C). `scripts/character/student_hero.gd` compone al personaje: **recolorea** pelo, piel, ojos y sudadera con los colores del creador conservando el sombreado (HSV), aplica el **peinado** (corto = el de la lámina; rapado, cresta, moño, hacia atrás, afro, largo/melena y coleta, generados sobre su pelo), **barba** y **accesorio** (lentes, de sol, audífonos, gorra, gorro), y encima el **equipo** (`LOOKS`): casco de hierro/obra → B, capucha de cuero → D, diadema de seda → sombrero de C; armadura de rack/cota de placas → B, chaleco de cuero → D, túnica de seda → C (con su falda), chaqueta de conferencias → E; botas de hierro/seguridad → B, de cuero → D; con casco, el pelo que no tapa desaparece. Armas: espada → la de luz de B, daga → la de D, maza y hacha → el bastón de C (las de oficio, T177). Animaciones de frente moviendo la plantilla: reposo, pasos (cada pierna), tajo (el arma girando en la mano), lanzar, golpe, esquiva y tumbado. `HeroSprite` (×1,35, volteado a la izquierda) lo dibuja y el jugador le pasa su apariencia y su equipo (`StudentHero.look_of`), así que al equiparse cambia al momento. Capturas `docs/capturas/personajes/176_alumnos.png` y `176_alumno_en_partida.png`. Pruebas en `_test_player_sheet`. El ZIP original va a `assets/third_party/zerie/` (fuera de git: la licencia prohíbe volver a subirlo); un importador (`tools/import_zerie.gd`) corta las hojas de 100×100, elige un personaje por clase (guerrero → Caballero o Hachero acorazado, duelista → Espadachín, exploradora → Arquero, hacker → Soldado retocado, hechicero → Mago, templario → Caballero templario, full_stack → Lancero o Caballero), recolorea la tela con el color de atuendo del creador y añade los detalles «de datos» (runas y gemas cian). Al ser solo de lado, de frente y de espaldas se usa la vista de lado del lado al que mira. El crédito a Zerie va en el README y en los créditos.
- Hornear `RpgAppearance` con la cuadrícula de T160 (96×120, 36 columnas, un archivo por clase y por variante de pelo/barba visibles), con el contorno, la luz en gris y `PlayerSprite.life` de siempre.
- En el juego (todas las zonas desde el acto I), la lista de personajes y la hoja de personaje, el jugador es su héroe de RPG; el prólogo y el creador (que va antes del prólogo) siguen con el oficinista. Las animaciones de T163 y el polvo de la esquiva se conservan.
- Prueba: cada clase tiene su hoja con todos los cuadros y los pies en `FEET`; el jugador usa la hoja de RPG fuera del prólogo y la de siempre en el prólogo.

### [x] T180 · Peinados y accesorios del alumno, y el creador · M
Origen: R8b (pedido del usuario, 31-10-2026: «lo siguiente»)
- **Hoja de sprites del alumno** con todos los peinados (11) y accesorios del creador, a resolución real (`assets/sprites/hero/catalogo.png`, una celda por peinado y por accesorio) y ampliada con sus nombres (`docs/capturas/personajes/180_peinados_accesorios.png`), para revisarlos uno por uno; los que se vean mal (generados sobre el pelo de la lámina en T176) se redibujan.
- **Creador**: los accesorios ya no incluyen sombreros (**sin gorra ni gorro de lana**: lo de la cabeza lo pone el equipo); quedan nada, lentes, lentes de sol y audífonos. Los guardados que los llevaban pasan a «nada». Junto al oficinista del prólogo, una **vista previa del alumno en pixel art** («así te verás en el servidor») que cambia con cada opción. La lista de personajes (pendiente de T176) también lo enseña.
- Prueba: cada peinado y accesorio se ve distinto en la hoja (ninguno igual a otro ni vacío); ningún accesorio del creador es un sombrero; un guardado con gorra o gorro carga sin accesorio.
- Hecho: la primera hoja mostró que los peinados de T176 (recortes del pelo de la lámina) casi no se distinguían; ahora **se redibujan**: `StudentHero._bald` deja la cabeza calva de la plantilla (cúpula de piel con su sombra y contorno, respetando cejas y cara) y cada peinado es una forma propia pintada con el sombreado de la lámina (`_paint_hair`: luz arriba a la izquierda, sombra abajo y a la derecha, mechones y contorno contra el fondo): rapado al ras, **corto** (el de la lámina, sin tocar), largo con flequillo partido y mechones a los hombros, cresta con los lados rapados, moño con lazo de los detalles, hacia atrás con volumen, afro, coleta con lazo, rapado lateral con el pelo caído a un lado, melena con flequillo recto y entradas en «M». Hoja a resolución real `assets/sprites/hero/catalogo.png` (fila de peinados y fila de accesorios) y ampliada con nombres `docs/capturas/personajes/180_peinados_accesorios.png` (`capture_screens -- catalogo`). **Accesorios**: nada, lentes, lentes de sol y audífonos (fuera gorra y gorro; `sanitize` pasa los guardados con 4 o 5 a «nada»; se borran sus hojas `accessory_3/4`). **Creador**: el alumno en pixel art bajo el oficinista («Así te verás dentro del servidor», `StudentPreview`: respira y da unos pasos). **Lista de personajes**: el alumno al lado, con lo que lleva puesto el guardado (`StudentHero.equipped_of_save`). Capturas `180_02_personajes.png` y `180_03_creador.png`. Pruebas en `_test_player_sheet`.
- 31-10-2026, revisión del usuario: peinados más estéticos y agradables, lentes claros que dejen ver los ojos y la montura, lentes de sol con la montura visible y más peinados. Hecho: motor de pelo nuevo (`StudentHero.Hair`) con las reglas del pelo de la lámina: casquete con más volumen arriba que a los lados, **flequillo de mechones en punta** (la frente asoma entre ellos; cada mechón con su lado claro y su lado oscuro), mechones laterales en punta, **brillo en arco** arriba a la izquierda, líneas de mechón que salen de la coronilla, rizos en racimos (afro y rizos) y lazos del color de los detalles. Los 10 peinados redibujados y **5 nuevos**: ondulado, dos coletas, trenzas, flequillo lateral y rizos (16 en total). En el prólogo, los retratos y los NPC por capas, los nuevos usan el más parecido de los 11 de siempre (`CharacterAppearance.office_hair`). **Lentes**: montura de 5×5 alrededor de cada ojo con puente y patillas; los claros, montura oscura, el ojo entero a la vista, el cristal aclara un poco la piel y un destello; los de sol, montura del color de los detalles y cristal oscuro con degradado y destello.

### [x] T181 · El alumno en movimiento: de espaldas y de lado · M
Origen: R8b (pedido del usuario, 31-10-2026: «aplicar los cambios en el movimiento del jugador y el menú de creación»)
- Hasta ahora el alumno siempre mira de frente (la lámina es de frente). **De espaldas** al ir hacia arriba: la nuca con el pelo de su peinado (o el casco, la capucha o el sombrero por detrás) y la sudadera sin el frente. **De tres cuartos** al ir a los lados: la cara (ojos, cejas, nariz) se gira hacia donde camina; a la izquierda, volteado.
- Hoja con tres filas (frente, espaldas, lado) y `HeroSprite` elige la fila por hacia dónde mira (como `PlayerSheet.dir_for`).
- **Creador**: «Girar» también gira al alumno de la vista previa.
- Prueba: cada dirección tiene todos sus cuadros con dibujo; de espaldas no se ven ojos ni la camisa blanca; de lado los ojos se mueven hacia donde mira.
- Hecho: `StudentHero.figure(look, dir)` y la hoja con tres filas (`Dir.FRONT/BACK/SIDE`, `dir_for` como `PlayerSheet.dir_for`). **De espaldas**: la cara de la plantilla (`_face_mask`) se vuelve pelo de su color con su contorno y la nuca abajo (pelo al ras en los rapados); los peinados largos caen por la espalda (`LONG_BACK`); la sudadera pierde la camisa y el gafete y enseña la capucha caída; con casco, donde iba la cara (visor, gafas, la cara del mago) va el color del casco; de los accesorios, solo los audífonos. **De lado**: ojos, cejas y nariz un píxel hacia donde mira, y los lentes con ellos; a la izquierda, volteado. `HeroSprite` elige la fila con hacia dónde mira el jugador. **Creador**: «Girar» gira también al alumno (`StudentPreview.facing`). Captura `docs/capturas/personajes/181_direcciones.png` (ocho looks: frente, lado, espaldas, pasos de lado y de espaldas, tajo). Pruebas en `_test_player_sheet`.

### [x] T182 · El alumno de perfil · L
Origen: R8b (prueba del usuario de la 3.3.3, 31-10-2026: «al caminar a la derecha o a la izquierda mira de frente, camina como cangrejo»)
- La vista «de lado» de T181 (la cara corrida un píxel) no basta: hace falta un **perfil de verdad**. Plantilla de perfil propia a la misma escala y con el mismo estilo de la lámina (cabeza grande, contorno de color, sombreado): cabeza de perfil (nariz, un ojo, oreja, nuca), torso de lado con un brazo delante y otro detrás, piernas que se cruzan al andar (paso de verdad, no solo subir y bajar).
- Con lo mismo que el frente: recoloreado del creador, los 16 peinados y los accesorios vistos de lado, y el equipo (casco, armadura, botas) de lado.
- Animaciones de perfil: reposo, andar (4 cuadros con zancada), tajo, lanzar, golpe, esquiva y caída.
- Prueba: de lado no se ven dos ojos; las piernas cambian de posición en cada cuadro del paso; cada peinado y cada pieza de equipo tienen su vista de lado con dibujo.
- Hecho: `scripts/character/student_profile.gd` dibuja el perfil con los colores del alumno de la lámina recoloreados con el creador: cráneo redondo con la nuca y la oreja, un ojo con su ceja y su brillo, nariz, boca y barbilla, la sudadera de lado (espalda redondeada, camisa asomando delante, capucha caída en la nuca), contorno de color, y **brazos y piernas trazados en cada cuadro**: el paso tiene zancada (los pies se cruzan, la pierna y el brazo de atrás más oscuros, los brazos en oposición), el tajo levanta el brazo, lanzar los adelanta. Los **16 peinados de lado** con el mismo motor de pelo (`StudentHero.Hair`, ahora con su propia cabeza: `center`, `radius`, `crown`): flequillo delante, pelo largo y trenzas por la espalda, coleta y moño atrás, nuca cubierta; lentes y audífonos de lado; barba. **Equipo**: armaduras estrechadas al ancho del perfil y sus mangas en los brazos; el yelmo Firewall y la capucha Root toman la mitad de la vista de frente con el visor o las gafas delante; las botas, del color de las de la lámina. En reposo de lado, el arma cuelga junto a la pierna (no tapa la cara). La fila «de lado» de la hoja ya es este perfil (fuera la cara corrida de T181). Capturas `docs/capturas/personajes/182_perfiles.png` (los 16 peinados y accesorios de lado y el paso) y `181_direcciones.png`. Pruebas en `_test_player_sheet` (un solo ojo, piernas que cambian en el paso, cada peinado con vista de lado).

### [x] T177 · Armas de oficio · M
Origen: R8b
- **31-10-2026 (usuario)**: con un mazo, el personaje lleva el bastón largo de la lámina; las armas tienen que verse **como lo que son**: un sprite por tipo de arma y por base (`data/items/bases.json`: espadas, hachas, mazas, dagas, con las de oficio: teclado mecánico, teclado RGB, sable de fibra óptica, cúter de cartonero, navaja multiherramienta, martillo de compilación...), en la mano y en el tajo, de frente, de espaldas y de lado. El bastón de C queda para un arma mágica si llega.
- Mismo daño y mismo gesto (tajo o estocada); cambia el aspecto en el mundo, en los iconos y en el nombre de las bases que lo pidan: **espada** → sable de fibra óptica (hoja de luz con conector); **hacha** → teclado mecánico con teclas sueltas; **maza** → mouse con cable (se balancea como un mangual); **daga** → destornillador de precisión / memoria USB afilada. Con brillo de «datos» en el filo como los detalles de T175.
- Prueba: cada tipo de arma (`PlayerSheet.WEAPONS`) tiene su dibujo de oficio en la hoja y su icono.
- Hecho: `scripts/character/weapon_art.gd`: un sprite en pixel art por base (las 15 de `bases.json`), con el estilo del alumno (tres tonos y contorno oscuro), apuntando hacia arriba con el agarre marcado: espada oxidada (con óxido), espada bastarda, estoque del compilador (runas cian), sable de fibra óptica (hoja de luz), hacha de leñador, hacha de guerra doble, hacha de despido masivo (roja), maza de depuración, martillo de compilación (con su luz), **teclado mecánico** y **teclado RGB** (llevados por el cable), daga de root, puñal de día cero (filo rojo), cúter de cartonero (amarillo) y navaja multiherramienta (roja con la cruz). El jugador pasa la base de su arma (`look["eq_weapon"]`) y `StudentHero` pone ese sprite en la mano de frente, de espaldas y de lado, y lo gira en el tajo; sin base conocida, el de su tipo (`WeaponArt.DEFAULT`). La lista de personajes también enseña el arma del guardado. El bastón de C ya no se usa (queda para un arma mágica). **Iconos**: los del inventario no se tocan aquí. Captura `docs/capturas/personajes/177_armas.png` (cada arma de frente en reposo y de lado en el tajo). Pruebas en `_test_player_sheet`.

### [x] T178 · NPC de RPG desde el acto I · M
Origen: R8b (redefinida tras T176/T182: con el estilo del alumno, no con `RpgAppearance`)
- Los NPC de las zonas (del acto I en adelante) se dibujan como el alumno (`StudentHero`, `HeroSprite`): su apariencia de npcs.json con el equipo de su arquetipo (campo `server`: Aida y el DBA con túnica, Rafa y Clara con armadura de rack, B.O.B. autómata con casco y placas, Iris y el Recolector con capucha, Tomás con cota y estoque...) y en la mano su objeto de T162 (taza, laptop, maleta, cartel, planos, rosa, pila...: sprites propios en `WeaponArt`, «prop_*»), de frente, de espaldas y de perfil, con sus gestos (teclear, sorbo, hablar). El prólogo, como está.
- Prueba: cada NPC tiene equipo y su objeto en la mano, y ninguno se ve igual a otro; la taza de Aida va en la mano. Captura: `capture_screens npcs` → docs/capturas/personajes/178_npcs.png.

### [x] T179 · Versión 3.4.0 y revisión en el teléfono · S 🛑
Origen: R8b
- Versión 3.4.0 (APK, `latest.json` y Windows) con el logo, los héroes y las armas; capturas en `docs/capturas/personajes/`; lista `docs/prueba_celular_3.4.md`. Incluye la pregunta que quedó de T153: ¿manadas un 30 % más juntas en el celular para pelear más y pasear menos?

## Fase 37 — Interfaz de ingeniería (versión 3.5.0)

### [x] T165 · Guía visual y dos propuestas · S 🛑
Origen: R8
- `docs/estilo_visual.md`: paleta, tipografía y motivos. Dos propuestas con capturas del inventario, el HUD y un diálogo, para que el usuario elija (o mezcle):
  - **A · Terminal/IDE**: fondo pizarra `0b1020`, paneles `111a2e`, acento cian `3ad1e6`, verde éxito `7ee787`, magenta IA `c678dd`; títulos en monoespaciada, ventanas con barra de pestaña («inventario.json ×» y los tres puntos), números de línea en las listas, cursor que parpadea.
  - **B · Panel de monitoreo/datos**: tarjetas planas tipo dashboard, medidores circulares con marcas, gráficas mini (sparklines) y rejilla de puntos de fondo; motivos de grafo y red neuronal en marcos y separadores.
- Los colores de rareza, de daño y del modo daltónico no cambian (son lenguaje del juego).
- Se para hasta que el usuario elija.

### [x] T166 · Tema de ventanas, botones y tooltips · M
Origen: R8
- `UiStyle` con la propuesta elegida: `make_theme`, `window_style`, `window_header`, `decorate_window` (fuera remaches y latón), botones, deslizadores, pestañas, barras de desplazamiento y `ItemTooltip` (cabecera tipo documentación, afijos como líneas de código con su color).
- Quitar colores sueltos: las ventanas toman sus colores de `UiStyle`, no de constantes propias.
- Prueba: contraste texto/panel ≥ 4,5:1 (luminancia WCAG) para `TEXT`, `MUTED` y el acento; ninguna ventana de `scripts/ui/` usa los colores antiguos (`d9a441`, `b08a4a`…) fuera de `UiStyle`.

### [ ] T167 · HUD de partida · M
Origen: R8
- Orbes de vida y maná como **medidores** de la propuesta elegida (vida = integridad del proceso, maná = memoria), barra de experiencia como barra de progreso con porcentaje, casillas de habilidad como teclas (keycaps), minimapa como radar con rejilla, registro de misiones como lista de TODO con casillas y registro de sucesos como consola (`[INFO]`, `[WARN]` con hora).
- Botones táctiles (habilidades, esquiva, usar, AUTO, pociones) con el mismo estilo, sin perder el hundido, el barrido de enfriamiento y el azul de sin maná de T148.
- Prueba: `capture_screens -- solapes` sigue en 0; los medidores muestran la misma fracción que los orbes de hoy (prueba de la función de relleno); capturas `docs/capturas/interfaz/167_*` en PC y 2400×1080.

### [ ] T168 · Menús y pantallas · M
Origen: R8
- Título, menú principal, creación de personaje, pausa y opciones, carga (como un registro de arranque: «compilando zona… OK») y muerte (como volcado de error) con el tema nuevo; el logo de `GameLogo` adaptado.
- Prueba: cada pantalla abre sin errores en `capture_screens` (táctil y PC) y la carga muestra su progreso de 0 a 100 %.

### [ ] T169 · Fuentes y legibilidad · S
Origen: R8
- Una monoespaciada de licencia libre para títulos, números y la consola (si no hay ya una en `assets/fonts`, elegirla con licencia OFL y anotarla), la de siempre para textos largos; tamaños mínimos de `UiStyle.MIN_FONT_SIZE` revisados en el celular al 140 %.
- Prueba: todos los `Label` creados por `UiStyle.label` usan ≥ `MIN_FONT_SIZE`; la fuente nueva carga y tiene los caracteres del español (á é í ó ú ñ ¿ ¡ ü).

### [ ] T170 · Versión 3.5.0 y revisión en el teléfono · S 🛑
Origen: R8
- Versión 3.5.0 (APK, `latest.json` y Windows) y lista `docs/prueba_celular_3.5.md`: ¿se entiende cada ventana?, ¿se leen los medidores de un vistazo en pelea?, ¿algo quedó con el estilo viejo?

## Fase 38 — Que todo hable el mismo idioma (versión 3.6.0)

### [ ] T171 · Enemigos al nivel de los personajes · M
Origen: R8
- `tools/generate_enemy_sprites.gd` a doble resolución con el mismo contorno y sombreado de T160, empezando por los del acto I (los que más se ven); los demás, en la misma tarea si da el tiempo o como tarea nueva.
- Prueba: cada enemigo de `enemies.json` tiene su cuadro en la hoja nueva y no está vacío.

### [ ] T172 · Efectos con temática de datos · S
Origen: R8
- Partículas de impacto, muerte y botín con motivos de datos (bits, corchetes, nodos de red que se apagan), sin perder el color por tipo de daño ni el modo daltónico; el estallido de muerte de cada familia de enemigos con su glifo.
- Prueba: `ImpactFx` sigue devolviendo el color del tipo de daño para cada tipo; con «Efectos de pantalla» apagado no se crea ninguna partícula extra.

### [ ] T173 · Versión 3.6.0 y revisión final · S 🛑
Origen: R8
- Versión 3.6.0 (APK, `latest.json` y Windows), capturas de antes/después de toda la etapa en `docs/capturas/estetica/` y README actualizado (capturas y «Versiones»).

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
- 2026-10-25 · T79 · Inventario: ordenar y compactar, bloquear y marcar como basura (guardado), vender la basura de una vez y comparar con Alt; tamaños en la rejilla descartados con su motivo.
- 2026-10-25 · T80 · Alijo con pestañas de nombre y color editables, pestaña de materiales y búsqueda que resalta lo que coincide.
- 2026-10-25 · T81 · Hoja de personaje con desglose por origen en el tooltip de cada estadística, resistencias con su tope y DPS de cada habilidad de la barra.
- 2026-10-25 · T82 · Ventanas coherentes: una sola a la izquierda, todas encogen junto al inventario, se recuerdan pestaña y filtros, waypoints y oleadas con el cursor de mando; arreglo del ancho de habilidades al 160 %.
- 2026-10-25 · T83 · Planificador del árbol: modo plan, aplicar, deshacer y rehacer, quitar nodos con coste en tokens y build como código de texto.
- 2026-10-25 · T84 · Identidad del árbol: notable de estilo por clase con su mecánica, cuatro piedras angulares con contra y tres constelaciones que piden dos atributos.
- 2026-10-25 · T85 · Arte del árbol: fondo por región de clase, iconos de temática en los nodos menores, líneas que se iluminan al asignar y destello al completar un grupo. Parada para revisión.
- 2026-10-25 · T86 · Diez bases de nivel alto con implícito propio por tipo y ocho únicos cuya gracia es una mecánica, con su texto de humor.
- 2026-10-25 · T87 · Crafteo con más decisiones: parche de rollback (quita un afijo), de optimización (sube un tier con riesgo de romperse) e historial de la mesa de Mario. Fin de la cola del Roadmap 3.0.
- 2026-10-25 · Roadmap 4.0 (T88-T105): gráficos (interfaz, efectos, sprites y animación) y árbol pasivo 2.0 (~1500 nodos, más clusters por familia, familia de maná, piedras angulares nuevas, ids estables y migración).
- 2026-10-25 · T88 · Diseño del árbol 2.0: documento docs/arbol_2.md y prototipo de disposición (1540 nodos, 114 clusters, claves estables). Parada para revisión.
- 2026-10-25 · T89 · Árbol pasivo 2.0 en el juego: 1373 nodos, 138 clusters, 149 notables, 18 maestrías y 11 piedras angulares, con claves estables y la identidad dentro del árbol.
- 2026-10-25 · T89b · Migración al árbol 2.0 con la primera reasignación gratis, código de build PO2 por claves y nivel de detalle en la vista (árbol entero de 74 a 14 ms).
- 2026-10-25 · T90 · Todas las familias con 4 clusters o más y 19 notables nuevos con condición; nombres de notables únicos en todo el árbol.
- 2026-10-25 · T91 · Familia de maná: maná antes que vida, regeneración plana, maná al golpear y al matar, y 12 clusters de maná con 4 notables nuevos.
- 2026-10-25 · T92 · 12 piedras angulares nuevas (23 en el árbol), siete con regla propia (Mente sobre Materia, Pago por Uso, Zero Trust, Caché Fría, Rate Limiting, Consistencia Eventual, Pato de Goma), condición de maná alto y aviso de choques en el tooltip; árbol versión 9.
- 2026-10-25 · T93 · Maestrías sin opciones repetidas, bono por completar cada constelación y 18 ranuras de chip fijas (puertas y anillo B); los chips vuelven a la bolsa si cambia el árbol; árbol versión 10.
- 2026-10-25 · T94 · Arte del árbol 2.0: fondo de estrellas y nebulosas con parallax, marcos de pixel art por tipo, flujo de luz en lo asignado, medallones de familia de lejos, minimapa y pulso por el camino al asignar (aprobado).
- 2026-10-25 · T95 · Tema de interfaz dibujado: atlas de piezas en pixel art (ventanas, botones, casillas por rareza, pestañas, barras, aro de orbe) cargado como StyleBoxTexture en UiStyle y en el HUD.
- 2026-10-25 · T95 (revisión) · A petición del usuario, HUD e interfaz menos pixel art: el atlas se dibuja a resolución final con degradados, esquinas redondeadas y bordes suavizados, filtrado en lineal (CanvasTexture); aro de orbe de metal liso a 192 px; cifras de los orbes y títulos de ventana y de sección con la fuente normal y contorno; sin las cantoneras cuadradas en las ventanas.
- 2026-10-25 · T96 · Título con ciudad de servidores y brillo del logo, personaje en pedestal con pose de lucimiento, pantalla de carga entre zonas con ilustración y consejo, y barrido de píxeles entre pantallas.
- 2026-10-25 · T97 · Números de daño (con críticos y apilado), ventanas que entran con zoom, botones que rebotan, tooltips con fundido, brillo de la experiencia al subir de nivel y la opción «Reducir movimiento».
- 2026-10-25 · T98 · Calidad gráfica baja/media/alta, ráfagas de partículas de GPU en explosiones y novas, bloom, distorsión de calor y ondas de choque en el shader de luz; medido en cada nivel.
- 2026-10-25 · T99 · Estados con forma (llamas, burbujas que revientan, gotas) también en el jugador, escarcha que crece y avisos de ataque con borde de trazos que gira, ondas que se cierran y flechas.
- 2026-10-25 · T100 · Ambiente por zona: salpicaduras de la lluvia de datos, polvo en suspensión, cables que chisporrotean, LEDs que parpadean en los racks y luces de zona que se avivan con los golpes.
- 2026-10-25 · T101 · Enemigos con 18 cuadros (andar, atacar, golpe, morir) en tres direcciones, elegidos por estado en la MultiMesh; cadáveres con su animación de morir.
- 2026-10-26 · T102a · Personaje horneado por capas (cuerpo, pelo, barba, accesorio, arma) desde el dibujo de siempre, con cuadrícula documentada y composición teñida con los colores del creador (PlayerSprite).
- 2026-10-26 · T102b · El jugador, el creador y la lista de personajes usan el personaje por capas; los retratos siguen dibujados (expresiones) (aprobado).
- 2026-10-26 · T103 · NPC con el personaje por capas (respiran y gesticulan al hablar) y entrada de jefe con su figura y su nombre; retratos dibujados como se decidió en T102.
- 2026-10-26 · T104 · Objetos en el suelo con icono, sombra, brillo de rareza y vuelo en arco con rebote; cajas de servidor que se abren y sueltan botín en arco.
- 2026-10-26 · T105 · Tilesets por estilo en PNG (suelo con 3 variantes sin costuras y banda del borde), usados en el suelo y el contorno del camino; agua animada en el borde. Roadmap 4.0 terminado.
- 2026-10-26 · Roadmap 5.0 (T106-T110): versión para celular — renderizador móvil, controles táctiles (joystick, apuntado automático, botones de habilidades, esquiva y pociones), interfaz táctil y exportación a Android.
- 2026-10-26 · Copia de la versión 2.0 (rama `version-2.0`, etiqueta `v2.0`) y roadmap de la versión 3.0 (T111-T131): tokens y waypoints de más lejos, solo waypoints entre actos, zonas generadas por instancia que duran 10 minutos (salvo la arena del jefe), mecánicas de zona al azar, gráficos, interfaz y escenas.
- 2026-10-26 · La versión 3.0 (T111-T131) pasa por delante del Roadmap 5.0 (móvil, T106-T110) en la cola.
- 2026-10-26 · T111 · Tokens desde más lejos (90 px directo, imán a 380 px que no atraviesa paredes) y stat Radio de recogida de tokens en anillos, amuletos y nodos de movilidad; arreglados dos polígonos que no se triangulaban (llamas y orbe). El fallo de la cruceta en el árbol ya existía: pasa a T111b.
- 2026-10-26 · T111b · La prueba de la cruceta en el árbol fallaba por la propia prueba (derecha, abajo e izquierda volvían al nodo de partida); ahora mira que cada pulsación salte a otro nodo. Integración rápida en verde.
- 2026-10-26 · T112 · Waypoints que se descubren a ~420 px con el waypoint en pantalla (antes 106) y los de los campamentos al entrar; comprobado en la lógica y en la integración.
- 2026-10-26 · T113 · Solo waypoints entre actos: fuera los tres túneles de vuelta y las dos salidas a pie hacia la arena del acto anterior; los guardados viejos reciben el waypoint de los campamentos ya alcanzados.
- 2026-10-26 · T114 · Diseño del generador de zonas (`docs/zonas_3.md`) y prototipo `ZoneLayout` con cuatro plantillas (salas, cueva, plaza, racks) sobre una rejilla de 80 px; 110 disposiciones sin fallos de garantía, 12 ms por zona; capturas en `docs/capturas/zonas_3/`. **Pendiente de revisión del usuario.**
- 2026-10-26 · T114 · Aprobado por el usuario con las respuestas por defecto del documento.
- 2026-10-26 · T115 · Las zonas de combate se generan en cada viaje con una semilla nueva: posiciones de la instancia en una copia de la definición, lo transitable, la colisión, el suelo, el borde, el minimapa y el mapa grande sobre la rejilla, y obstáculos que no cortan el paso.
- 2026-10-26 · T116 · Zonas más largas, más anchas o con rodeo, pasillos que siguen la forma de la plantilla (A*) y marcas del mapa que duran lo que la instancia.
- 2026-10-26 · T117 · Cada instancia con su tema de enemigos (uno abunda, otro escasea, élites 0,7-1,3×), raros en otro sitio, rincón con caja rica la mitad de las veces y su tiempo (niebla, lluvia, polvo o apagón parcial) dentro del estilo.
- 2026-10-26 · T118 · Las zonas generadas se conservan 10 minutos (hasta 8): al volver, la misma zona con el botín y los tokens del suelo, las cajas abiertas y el mapa explorado; el banco de oleadas deja de generarse.
- 2026-10-26 · T119 · Al volver a una instancia viva, los mismos enemigos vivos (con su vida) y los eventos como estaban; la arena del jefe conserva su botín pero el jefe vuelve entero; la ventana de waypoints dice cuánto le queda a cada instancia.
- 2026-10-26 · T120 · Motor de mecánicas de zona: una principal siempre (bombas, escolta o deploy al azar; mutex y carrera crítica en sus zonas) y como mucho un evento menor, con aviso al entrar, rombo en el minimapa, consejo y botín extra al completarla.
- 2026-10-26 · T121 · Mecánicas principales nuevas: Garbage Collector (barridos que dañan a todos, también a los enemigos), Apagón del CPD (luces de emergencia que devuelven la luz) y Ticket urgente (élites marcados con cuenta atrás), con su dibujo, aviso y consejo.
- 2026-10-26 · T122 · Merge conflict (ramas de enemigos que se pegan entre ellas), Deploy de viernes (oleadas por las salidas hasta cerrar el pipeline) y Caché caliente (baldosas con bono que se mueven); pesos igualados para que ninguna principal pase del 20 %.
- 2026-10-26 · T123 · Salas temáticas en las zonas generadas (rack caído, cementerio de commits, backups inundada, altar del becario, servidor legacy): 1-2 por instancia según el estilo, con decorado, luz y a veces caja o lore.
- 2026-10-26 · T124 · Obstáculos altos translúcidos con alguien detrás, sombras que se alejan de la luz, fondo con parallax más allá del borde (vacío, abismo, agua, lava) y manchas en el suelo que se guardan con la instancia; sin coste medible.
- 2026-10-26 · T125 · Niebla en el minimapa (la del mapa grande): lo no explorado se tapa y salidas y waypoint solo salen al verlos; con caché, el minimapa cuesta lo mismo que antes.
- 2026-10-27 · T126 · La ventana de waypoints es el mapa de cada acto: pestañas, zonas unidas por sus salidas, waypoint descubierto o no, nombres ocultos hasta pisarlas y tiempo y mecánica de cada instancia viva.
- 2026-10-27 · T127 · Placas y RAM se comparan con lo equipado al pasar el ratón: la placa contra la de su habilidad en la barra (al lado, con las diferencias en verde y rojo) y la RAM con el DPS que daría en cada placa.
- 2026-10-27 · T128 · El rótulo de la zona dice su mecánica; registro de sucesos plegable a la izquierda (botín raro y único, waypoints, mecánicas, instancias que caducan) y aviso 1 min antes de perder el botín de una instancia.
- 2026-10-27 · T129 · Escenas con dirección: cámara con paneo y zoom hacia NPC o jefe, personajes que caminan y se giran, bandas de cine, cara por línea y saltar con ratón, toque o mando; repasadas cuatro escenas.
- 2026-10-27 · T130 · Escenas que faltaban: llegada a cada uno de los 4 campamentos (una vez, no si el acto ya está completo) y epílogo corto tras cada jefe, encadenado con `on_finish.cutscene`; `cutscene_on_enter` admite listas con condiciones.
- 2026-10-27 · T131 · Revisión de la 3.0: el piloto de la integración sigue la rejilla con A* (se atascaba en paredes de zonas generadas), integración completa en verde (219 combinaciones), capturas y README al día, etiqueta `v3.0`. **Pendiente de revisión del usuario.**
- 2026-10-27 · T131 · Versión 3.0 aprobada por el usuario; se sigue con la fase móvil.
- 2026-10-27 · T106 · Renderizador `mobile` y horizontal fijo en el celular, con calidad media, interfaz al 140 % y como mucho 12 luces por defecto; los efectos funcionan igual con el renderizador móvil y cuesta lo mismo en este equipo.
- 2026-10-27 · T107 · Joystick virtual que aparece bajo el dedo a la izquierda, tocar el mundo como el clic (con el último toque, no el cursor del sistema), apuntado automático al enemigo en la dirección del joystick con mira, e interruptor en Pausa → Controles.
- 2026-10-27 · T108 · Botones táctiles: las 6 habilidades en dos arcos junto al orbe de maná (mantener = canalizar o repetir, arrastrar = apuntar a mano), esquiva encima del orbe, pociones y menús grandes a la izquierda; la placa del HUD desaparece en táctil.
- 2026-10-27 · T109 · Interfaz táctil en las ventanas: tocar = tooltip y botón de acción (otro toque la hace), mantener = clic derecho, arrastrar objetos, zoom con dos dedos en árbol y mapa, botones de Mapa y pausa; capturas a 2400×1080 y 1600×720. **Pendiente de revisión del usuario.**
- 2026-10-27 · T109 · Aprobado por el usuario, con permiso para instalar lo de Android y generar el APK (T110).
- 2026-10-27 · T110 · Exportación a Android: preset, script de instalación y exportación, y APK de depuración; la pantalla de título ya continúa con un toque (fallo visto por el usuario en su celular)
- 2026-10-27 · Boceto del Roadmap 6.0 (T132-T145): experiencia en el celular tras probar el APK — controles en el prólogo, filtro de botín táctil, botón de interactuar, lado derecho reorganizado, versión visible y aviso de actualización; aprobado por el usuario.
- 2026-10-27 · T132 · Prólogo con el dedo: joystick en la calle, el pasillo y la oficina, botón dorado de usar abajo a la derecha y tocar el escenario va al punto tocado (antes iba al del toque anterior).
- 2026-10-27 · T133 · Filtro de botín con el dedo: el inventario de debajo ya no se queda el toque, gemas de 45 px a 140 %, vista previa y reglas finas en pestañas y filas con desplazamiento para que la ventana quepa en el celular.
- 2026-10-27 · T134 · Botón dorado de usar en el celular (recoger el más raro, hablar, waypoint, alijo, sucesos; mantener recoge todo), recoger solo al pasar por rareza, etiquetas más fáciles de tocar y arreglado que tocar el mundo fuera al punto del toque anterior.
- 2026-10-27 · T135 · Recorrido táctil de todas las ventanas (0 botones sin respuesta): botón para reaparecer al morir, menú principal que cabe en el celular, catálogo sin joystick debajo, ventanas emergentes con el tamaño de interfaz y bolsa que se desplaza arrastrando en vertical.
- 2026-10-27 · T136 · Botones táctiles «esquina» (ataque grande junto al orbe de maná y las otras 5 en dos anillos, usar junto a la esquiva, pociones a la izquierda y menús en un ☰), con «dos arcos» como opción, tamaño 80-140 % y modo zurdo. Scripts y lógica en OK; la integración rápida se cortó a mitad (181 recorridos sin un error).
- 2026-10-28 · T136 · El usuario pidió seguir con el loop: se toma como visto bueno.
- 2026-10-28 · T137 · Editor de disposición táctil (mover y escalar cada botón, opacidad de los botones, Restaurar), guardado en settings.cfg.
- 2026-10-28 · T138 · Tutorial, consejos, diálogos de controles y ayudas del prólogo con su versión para el dedo, y aro «¡Aquí!» sobre el botón de cada paso del tutorial.
- 2026-10-28 · T139 · Versión única en project.godot (3.1.0), «v3.1» en el título y la pausa, y tools/exportar_android.ps1 que la copia al APK y sube el código de versión.
- 2026-10-28 · T140 · Aviso de actualización desde GitHub Releases (latest.json, botón que abre la descarga, opción para apagarlo), permiso de internet en el APK y tools/publicar_version.ps1; falta que el usuario cree el repositorio y su clave.
- 2026-10-28 · T141 · Salir de la app guarda y pausa; el botón Atrás de Android hace de Esc y en el título y el menú pregunta antes de salir (antes cerraba la app).
- 2026-10-28 · T142 · La interfaz respeta la muesca y las esquinas del celular (también al girarlo) y los tooltips con comparación se encogen para caber en alto.
- 2026-10-28 · T143 · Vibración corta en el celular al recibir un golpe fuerte, críticos, subir de nivel, caer un único y pulsar botones táctiles, con respiro entre pulsos y opción para apagarla.
- 2026-10-28 · T144 · Límite de FPS (auto, 30, 60 o sin límite): en el celular baja solo a 30 si la partida va por debajo de 50; contador de FPS opcional, apagado en el celular.
- 2026-10-28 · T145 · APK v3.1.0 (código 4) y lista de pruebas en docs/prueba_celular_3.1.md; esperando la prueba del usuario en su teléfono.
- 2026-10-28 · T145 · Fallos de la primera prueba en el celular: interfaz que parpadeaba y se iba (zona segura mal informada), árbol de pasivas sin forma visible de cerrarlo y tutorial que pedía pasivas en el Sandbox y volver al campamento ya pasado.
- 2026-10-29 · Boceto del Roadmap 7.0 (T146-T155): diseño y experiencia en el celular — registro de misiones que no tape los botones, comprobador de solapes, botones con respuesta, joystick a gusto, apuntado que ayuda, ataque automático, golpes con peso, ritmo de las peleas y partidas cortas; aprobado por el usuario.
- 2026-10-29 · T146 · Registro de misiones en el celular: resumen, todas o plegado con un toque, nunca baja hasta los botones táctiles y se pliega en las peleas.
- 2026-10-29 · T147 · Comprobador de solapes del HUD en 17 configuraciones: de 85 solapes a 0 (texto de «Usar» encima, avisos arriba en táctil, sucesos bajo el tutorial, arcos más separados).
- 2026-10-29 · T148 · Botones táctiles con respuesta: se hunden al pulsar, destello y toque al volver a estar listos, azul apagado y temblor sin maná, y zona de toque más generosa.
- 2026-10-29 · T149 · Joystick flotante, fijo (a la vista sobre el orbe de vida) o que sigue al dedo, y zona muerta chica, normal o grande.
- 2026-10-29 · T150 · Apuntado que ayuda: objetivo pegajoso, tocar un enemigo lo fija, mira con su color y su vida, y vista previa de alcance y forma al arrastrar (volver al botón cancela).
- 2026-10-29 · T151 · Interruptor «AUTO»: el ataque principal se lanza solo contra lo que hay cerca también caminando, al objetivo de la mira; espera con una ventana encima.
- 2026-10-29 · T152 · Golpes que se notan en el celular: números de daño más grandes y agrupados (o solo críticos), críticos que saltan más y botín con arco más alto y dos botes.
- 2026-10-29 · T153 · Ritmo medido (34 % del tiempo en pelea) y racha de bajas con velocidad y tokens al cortarse; versión 3.1.2 preparada; propuesta de manadas más juntas esperando la prueba del usuario.. **Pendiente de revisión del usuario.**
- 2026-10-30 · T155 · Absorbida por el Roadmap 8.0 (tamaño y estética, T156-T173): cada etapa publica su versión (APK, latest.json y Windows) y se revisa en el teléfono.
- 2026-10-30 · T154 · «▶ Continuar» de un toque en el título (último personaje, con su nivel y zona) y el objetivo a la vista 6 s al entrar (misión principal y su paso o «limpia esta zona (0/N)»).
- 2026-10-30 · T156 · «Tamaño del mundo» (auto / 100-140 %) en Pausa → Gráficos: zoom de la cámara, 130 % por defecto en el celular, con tope para ver siempre el alcance del auto-ataque; luz del jugador y rejilla pixel art siguen el zoom.
- 2026-10-30 · T157 · Jugador y NPC a la misma escala (+15 %), contorno oscuro de 1 píxel, anillo de la clase bajo el jugador, nombres de NPC a su altura y enemigos con un mínimo de 40 px de dibujo (barra y toque incluidos).
- 2026-10-30 · T158 · El texto del mundo (nombres, botín, números de daño) crece √zoom en vez del zoom entero: más legible sin tapar la pelea; nombres de NPC con el tamaño de texto del mundo; solapes del HUD en 0.
- 2026-10-31 · T160 · Hojas del personaje a 1,5× (96×120, un archivo por variante) con el estilo de la referencia: cabeza grande, ojos chibi con brillo, sombreado en tres tonos, brillos y contorno grueso; 8 cuadros al andar.
- 2026-10-31 · T161 · Equipo de oficio por clase (chaleco, bata, capucha y paleta, audífonos y globo, tableta holográfica, casco de obra, mochila) en una capa horneada propia, en el jugador y la lista de personajes.
- 2026-10-31 · T162 · Cada NPC con su objeto (taza, monitor, laptop, maleta de RAM, cabeza-pantalla, tablas flotantes...) y reposo propio (Rafa teclea, Aida bebe café; el DBA, translúcido).
- 2026-10-31 · T163 · Respiración, rebote al andar y estiramiento al golpear encima de los cuadros (jugador y NPC) y polvo al esquivar; la silueta tras obstáculos no hace falta (nada tapa al jugador).
- 2026-10-31 · T145, T153, T159, T164 · Revisiones cerradas: el parpadeo se fue (renderizador Compatibility); el usuario pide armas de oficio, héroes de RPG desde el acto I y un logo (Fase 36b, T174-T179).
- 2026-10-31 · T174 · Ícono de la app en pixel art (la pila que se desborda entre «<» y «/>»), con versión adaptable y monocroma para Android, generado por código.
- 2026-10-31 · T175 · Diseño de los héroes de RPG (RpgAppearance): caballero, espadachín, exploradora, pícara, mago, paladín y caballero-mago, con runas y gemas cian; hoja de muestra para que el usuario elija.
- 2026-10-31 · T180 · Peinados del alumno redibujados (11, cada uno con su forma), hoja de peinados y accesorios, accesorios sin sombreros y el alumno en pixel art en el creador y la lista de personajes.
- 2026-10-31 · T181 · El alumno de espaldas (nuca, pelo largo por la espalda, capucha de la sudadera, casco por detrás) y de lado (la cara gira hacia donde camina); el creador lo gira.
- 2026-10-31 · (herramienta) · `publicar_version.ps1 -Subir` / `-SoloSubir`: crea o actualiza la release v<versión> en GitHub con el APK y el latest.json y la marca como la última (GitHub CLI; una vez: `winget install --id GitHub.cli` y `gh auth login`).
- 2026-10-31 · T182 · El alumno de perfil de verdad (StudentProfile): cara de lado, zancada con brazos y piernas por cuadro, los 16 peinados y los accesorios de lado y el equipo adaptado.
- 2026-10-31 · T177 · Un sprite en pixel art por cada arma (15 bases: espadas, hachas, mazas con los dos teclados, dagas con el cúter y la navaja) en la mano del alumno, en las tres direcciones y en el tajo.
- 2026-10-31 · T178 · Los NPC dentro del servidor, con el estilo del alumno: el equipo de su arquetipo (`server` en npcs.json) y su objeto de T162 en la mano (13 sprites «prop_*»), de frente, de espaldas y de perfil; el prólogo, igual.
- 2026-10-31 · T179 · Versión 3.4.0: APK (código 18) y latest.json, Windows e instalador; lista `docs/prueba_celular_3.4.md` (con la pregunta de las manadas de T153). Sin subir a GitHub: pendiente de la revisión del usuario 🛑.
- 2026-10-31 · (release) · v3.4.0 subida a GitHub (WalBernal/PathOverflow) con el APK y el latest.json, a petición del usuario.
- 2026-10-31 · T165 · Guía visual (`docs/estilo_visual.md`) y dos maquetas para elegir, dibujadas por `UiProposals`: A · Terminal/IDE y B · Panel de monitoreo/datos (`docs/capturas/interfaz/165_propuesta_a/b.png`), con contraste ≥ 4,5:1 comprobado.
- 2026-10-31 · T165 · El usuario elige la propuesta B (panel de monitoreo/datos).
- 2026-10-31 · T166 · `UiStyle` con la propuesta B: paleta turquesa, tarjetas planas redondeadas, botones, pestañas, barras de desplazamiento y barras de progreso; ventanas sin latón ni remaches (raya del acento y grafo de tres nodos), separador de red neuronal, fondo de puntos; tooltips con franja del color de la rareza; casillas sin el marco del atlas. Los colores sueltos de `scripts/ui` pasan a `UiStyle`. Pruebas: contraste ≥ 4,5:1 y ningún color viejo en `scripts/ui`. Capturas `docs/capturas/interfaz/166_*`.
