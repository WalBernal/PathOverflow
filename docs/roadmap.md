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
- Hecho: `docs/zonas_3.md` con el reparto de lo que cambia y lo fijo, la representación (rejilla de 80 px en vez de los cuatro bordes ondulados, y qué hay que adaptar en T115), las cuatro plantillas por estilo, el algoritmo paso a paso, las garantías y **seis preguntas para la revisión**. Prototipo `ZoneLayout` (aún sin usar en el juego): plantillas `salas`, `cueva`, `plaza` y `racks`, mordiscos en el contorno, salidas en su lado y separadas, entradas junto a su salida, waypoint entre entrada y salida, NPC y objetos en rincones propios, pasillos entre todos los puntos clave y fuera lo inalcanzable. Campamentos, jefes, incidentes y el tutorial quedan fijos. `capture_screens -- semillas`: 22 zonas × 5 semillas, 0 fallos de garantía, 12 ms de media por zona (66 la más lenta); imágenes en `docs/capturas/zonas_3/`. Prueba `_test_zone_layout`. **Pendiente de revisión del usuario.**

### [ ] T115 · Generador, parte 1: semilla por instancia y disposición · M
Origen: V3
- `Zone.setup` recibe una semilla de instancia (no `hash(id)`); bordes, accidentes, obstáculos, decorado y cajas salen de ella. Salidas, waypoint, objetos de misión y lore se recolocan en puntos válidos de la plantilla, respetando el lado de cada salida.
- Comprobación de conectividad (relleno por inundación sobre la colisión) y regenerar si falla.
- Pruebas: 50 semillas por zona, todas conectadas, sin nada encima de un obstáculo; la integración rápida juega con semillas al azar.

### [ ] T116 · Generador, parte 2: plantillas de forma por estilo · M
Origen: V3
- Las plantillas de T114 en el juego, una o dos por estilo; la zona puede salir más larga, más ancha o con un rodeo.
- Minimapa, mapa grande y marcas propias (T53) con la forma nueva; las marcas se borran al cambiar de instancia.

### [ ] T117 · Generador, parte 3: contenido que varía · M
Origen: V3
- Manadas por «tema» de instancia (la mezcla de tipos de la zona varía: más de uno, menos de otro), élites y raros en sitios distintos, cajas, decorado y algún rincón opcional con botín.
- Variante de ambiente por instancia (niebla, lluvia de datos, apagón parcial, polvo) dentro de lo que permite el estilo.
- Que el nivel de zona, la densidad media y la experiencia por zona no cambien (medir con la telemetría de T64).

## Fase 22 — Instancias que duran 10 minutos

### [ ] T118 · Instancias, parte 1: la zona y el botín se conservan · M
Origen: V3
- Registro de instancias en `World` (en memoria, no en el guardado): semilla, botín y tokens en el suelo, cajas abiertas, lore recogido, marcas del mapa y la hora a la que se salió. Al volver (por salida, waypoint o tras morir) antes de 10 min, la misma instancia; después, una nueva. Varias instancias a la vez (tope de ~8, se descarta la más vieja).
- El reloj corre en tiempo de juego mientras la partida está abierta (pausa incluida); al salir al menú o cerrar el juego, se pierden.
- No aplica a campamentos (no se generan), ni a oleadas ni pruebas de estrés (se reinician siempre).

### [ ] T119 · Instancias, parte 2: enemigos, eventos y mecánicas · M
Origen: V3
- `EnemyManager` guarda y restaura los enemigos vivos (tipo, rareza, afijos, rol, vida, posición) y no vuelve a sacar los muertos; el némesis, si estaba, sigue ahí. Los eventos y la mecánica de zona (Fase 23) vuelven en el estado en que se dejaron.
- **Excepción, la arena del jefe**: al morir o salir, el jefe vuelve a la fase 1 con la vida completa, sin adds, con las mecánicas de arena y la música reiniciadas; lo que haya caído al suelo en la arena sí se conserva.
- Tiempo que le queda a la instancia en la ventana de waypoints y en el minimapa («caduca en 7:32»).
- Prueba: morir con botín en el suelo y 20 enemigos vivos, volver y encontrar los mismos; pasados 10 min, zona nueva; morir en la fase 3 del jefe y volver a la fase 1 con la vida llena.

## Fase 23 — Mecánicas de zona al azar

### [ ] T120 · Motor de mecánicas de zona · M
Origen: V3
- Catálogo `data/zone_mechanics.json` (peso, estilos y actos donde puede salir, nivel mínimo, recompensa) y presupuesto por instancia: **una mecánica principal siempre** y como mucho un evento menor de los de `ZoneEvents`; nunca dos principales. El `mutex` y la `race_condition` del Acto II cuentan como la principal de su zona.
- Al entrar, aviso con el nombre y una frase; icono en el minimapa y consejo de primera vez (`TipPanel`). Recompensa al completarla (botín extra o tokens), sin castigo si se ignora.
- Integración: cada zona prueba cada mecánica que le puede tocar.

### [ ] T121 · Mecánicas nuevas, parte 1 · M
Origen: V3
- Tres principales con su arte y sonido, por ejemplo: **Garbage Collector** (un barrido recorre la zona cada cierto tiempo y daña a todo lo que pilla, enemigos incluidos; se esquiva o se usa), **Apagón del CPD** (la zona a oscuras salvo tu radio y luces de emergencia que se encienden al pasar) y **Ticket urgente** (élites marcados que hay que tumbar antes de que acabe la cuenta atrás).

### [ ] T122 · Mecánicas nuevas, parte 2 · M
Origen: V3
- Otras tres: **Merge conflict** (dos bandos de enemigos que se pelean entre sí si se cruzan), **Deploy de viernes** (oleadas que entran por la salida hasta cerrar el pipeline en un terminal) y **Caché caliente** (baldosas que dan un bono corto al pisarlas y se mueven).
- Ajustar pesos y recompensas con la telemetría para que ninguna domine ni se haga pesada.

## Fase 24 — Gráficos

### [ ] T123 · Salas temáticas en las zonas generadas · M
Origen: V3
- «Set pieces» por estilo que el generador puede insertar (rack caído con cables, cementerio de commits, sala de backups inundada, altar del becario…), con decorado propio, luz y a veces una caja o un lore.

### [ ] T124 · Profundidad y lectura del escenario · M
Origen: V3
- Obstáculos altos que se vuelven translúcidos cuando el jugador o un enemigo élite queda detrás; sombras que siguen a las luces de la zona; capa de fondo con parallax más allá del borde (vacío, abismo, agua).
- Manchas que se quedan en el suelo (aceite, chispas quemadas, restos) y se conservan con la instancia; medir el coste con `capture_screens -- rendimiento`.

## Fase 25 — Interfaz

### [ ] T125 · Minimapa con niebla que se descubre · M
Origen: V3
- Con zonas que cambian, el minimapa y el mapa grande empiezan en niebla y se descubren al pasar; lo descubierto se guarda en la instancia. Salidas y waypoint aparecen al verlos.

### [ ] T126 · Ventana de waypoints como mapa del acto · M
Origen: V3
- En vez de la lista: el mapa de cada acto con sus zonas unidas, el waypoint descubierto o no, la mecánica y el tiempo de la instancia viva y pestañas por acto (ahora es la única forma de volver atrás); con ratón, mando y toque.

### [ ] T127 · Comparar placas y RAM con lo equipado · S
Origen: pendiente de T70/T71
- Al pasar el ratón por una placa o RAM (tienda, suelo, alijo, inventario), su tooltip al lado del de lo equipado en esa ranura con las diferencias en verde y rojo (DPS de la habilidad, coste, área…).

### [ ] T128 · HUD de la zona y registro de sucesos · S
Origen: V3
- Rótulo de la zona al entrar con la mecánica activa; panel lateral plegable con lo que pasa (botín único y raro, waypoint descubierto, mecánica completada, instancia que caduca), y aviso 1 min antes de que caduque la instancia en la que tienes botín.

## Fase 26 — Escenas

### [ ] T129 · Escenas con dirección · M
Origen: V3
- `CutscenePlayer` con pasos nuevos: paneo y zoom de cámara, temblor, personajes que caminan y se giran en la escena, bandas de cine y retrato con expresión por línea; repasar las escenas existentes para usarlos.
- Saltar la escena entera o línea a línea, con ratón, mando y toque.

### [ ] T130 · Escenas que faltan · M 🛑
Origen: V3
- Llegada a cada campamento por primera vez y derrota de cada jefe (epílogo corto antes del portal), en `cutscenes.json` y con el humor del juego (`docs/lore.md`).

## Fase 27 — Cierre de la versión 3.0

### [ ] T131 · Revisión de la versión 3.0 · S 🛑
Origen: V3
- Integración completa (30 s por zona, una sola vez al final), capturas de cada fase nueva, `README.md` al día y etiqueta `v3.0` en git.

---

# Roadmap 5.0 — versión para celular (26-10-2026)

Pedido del usuario: generar el APK para celular. Hoy el juego no se puede jugar en un teléfono: las habilidades, la esquiva y las pociones van con teclado (Q W E R T Y, Espacio, 1-5), muchas ventanas dependen de pasar el ratón por encima y el proyecto usa el renderizador de escritorio (Forward+). Antes de exportar hay que prepararlo para pantalla táctil. **Origen: R5.** Mismo protocolo; 🛑 = parar y esperar el visto bueno.

Punto de partida: ventana de 1600×900 con stretch `canvas_items`; mando ya soportado (`GamepadCursor`, acciones de Input), clic para moverse hasta el botín (`Player.move_to`) y tamaño de interfaz configurable (80-160 %). En este equipo faltan el JDK, el SDK de Android y las plantillas de exportación de Android de Godot 4.7.2 (instalarlos necesita el permiso del usuario: descargas y licencias de Android).

## Fase 19 — Móvil

### [ ] T106 · Renderizador y rendimiento en móvil · M
Origen: R5
- Renderizador `mobile` para Android (`rendering/renderer/rendering_method.mobile`) y comprobar que el filtro del mundo, la luz, el bloom, las distorsiones, los sprites por capas y las partículas funcionan con él (si alguno no, alternativa o apagarlo en móvil).
- En dispositivos táctiles (`OS.has_feature("mobile")` o pantalla táctil), por defecto: calidad gráfica baja o media (T98), luces reducidas y tamaño de interfaz 140 %; orientación horizontal fija.
- Medir con `capture_screens -- rendimiento` forzando el renderizador móvil y la calidad baja.

### [ ] T107 · Controles táctiles: movimiento y objetivo · M
Origen: R5
- Detectar pantalla táctil (`DisplayServer.is_touchscreen_available()`) y mostrar un **joystick virtual** a la izquierda para moverse (aparece donde apoyas el dedo, con zona muerta); tocar el mundo fuera de los controles: ir ahí, recoger botín o hablar con un NPC (lo que ya hace el clic).
- **Apuntado automático** para jugar con el pulgar: las habilidades apuntan al enemigo más cercano en la dirección del joystick (o al más cercano, si no se mueve), con un indicador.
- Opción en Pausa → Controles para ocultar los controles táctiles.

### [ ] T108 · Controles táctiles: habilidades, esquiva y pociones · M
Origen: R5
- Botones grandes a la derecha en arco para las 6 habilidades (con su icono, enfriamiento y coste, como la barra del HUD), un botón de **esquiva** y la fila de **pociones** tocables; mantener pulsado = canalizar o repetir; arrastrar desde un botón = apuntar a mano.
- La barra del HUD de escritorio se recoloca o se oculta en táctil para no duplicar; los botones de menú (C I K P B) más grandes.

### [ ] T109 · Interfaz táctil · M 🛑
Origen: R5
- Todo lo que hoy depende de pasar el ratón por encima, con toque: tooltip al tocar un objeto o nodo (y botón para equiparlo, venderlo o asignarlo), mantener pulsado = clic derecho, arrastrar y soltar con el dedo en inventario, alijo y habilidades, zoom con dos dedos en el árbol pasivo y el mapa; botón de pausa en pantalla; textos y objetivos táctiles de 44 px como mínimo.
- Capturas a resolución de teléfono (2400×1080 y 1600×720) de las ventanas principales para la revisión.

### [ ] T110 · Exportación a Android · S 🛑
Origen: R5
- Necesita el permiso del usuario al empezar: instalar JDK 17, el SDK de Android (aceptar sus licencias) y las plantillas de exportación de Android de Godot 4.7.2.
- Preset de exportación «Android» (arm64-v8a, paquete `com.pathoverflow.game`, nombre e icono, horizontal, sin permisos extra), clave de depuración, y `build/PathOverflow.apk`; instrucciones en el README para instalarlo en el teléfono y para firmarlo con una clave propia si se quiere publicar.

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
