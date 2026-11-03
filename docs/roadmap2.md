# Roadmap 2 — Path Overflow: El Último Commit (02-11-2026)

Sigue al roadmap unificado (`docs/roadmap.md`, terminado en la versión 3.6.0 con T173). Allí quedan el registro de todo lo hecho y las tareas **fuera de la cola** que necesitan a una persona (equilibrio con partidas reales, arte final, música compuesta, cooperativo).

Este roadmap sale de una revisión del código del 02-11-2026 en cuatro frentes:
1. Pantalla de inicio, selección de personajes y prólogo: que nada aparezca de golpe y que todo tenga vida.
2. Habilidades: cada una con efecto y sonido propios (iconos ya tiene las 62).
3. Invocaciones y aliados persistentes: fluidos y fieles a su descripción.
4. Habilidades nuevas sugeridas y un banco de ideas de interfaz, comodidad y juego.

Las tareas van **en orden de prioridad**: se hacen de arriba abajo, una por vez. Cada una cabe en una sesión de trabajo (las grandes están partidas en partes). Se numeran desde T183 para no chocar con el roadmap anterior.

**Tamaño:** S ≈ 1 sesión · M mediana · L grande (partida en varias tareas). **Origen:** R9 = este roadmap.

**Pilares** (los cuatro de siempre más uno nuevo):
1. Cada build se siente distinta en las manos, no solo en los números.
2. Leer el combate de un vistazo.
3. El humor de programador en nombres, efectos, sonidos y textos.
4. Pixel art coherente: lo nuevo se dibuja en la rejilla de píxeles del filtro del mundo.
5. **Fluidez:** nada entra, sale ni cambia de golpe; todo lo que se mueve tiene anticipación, movimiento y asentamiento.

---

## Cómo se ejecuta (protocolo para Claude)

Estados: `[ ]` pendiente · `[~]` en curso · `[x]` hecha · `[!]` bloqueada (con el motivo en la línea siguiente) · 🛑 = punto de revisión: al terminarla, **parar y esperar el visto bueno del usuario** antes de seguir.

1. **Elegir**: la primera tarea `[ ]` de la cola, de arriba abajo. Si hay una `[~]`, retomarla primero (quedó a medias).
2. **Marcar** `[~]` antes de empezar.
3. **Entender**: leer los archivos que cita la tarea, `README.md` y los docs relacionados (`docs/estilo.md`, `docs/estilo_visual.md`, `docs/lore.md`, `docs/habilidades_y_ram.md`). Seguir el estilo del código existente.
4. **Hacer** lo que dice la tarea, sin ampliar el alcance. Si aparece trabajo extra, añadirlo como tarea nueva en la fase que toque, no hacerlo ahora.
5. **Comprobar**: `powershell -File tools/run_checks.ps1 -Rapida` debe terminar con las tres en `[OK]`. Si la tarea cambia zonas, enemigos o jefes concretos, además `-Zonas id1,id2`. La integración completa de 30 min no se corre en cada tarea. Añadir pruebas en `tests/test_core.gd` para la lógica nueva. Para lo visual, una captura en `docs/capturas/` (antes/después cuando sirva).
6. **Cerrar**: cambiar `[~]` por `[x]`, añadir una línea al **Registro** del final (fecha, ID, qué se hizo en una frase) y actualizar `README.md` si cambia algo visible para el jugador.
7. **Commit** con mensaje en español al estilo del repositorio. Sin push.
8. **Bloqueo**: si algo impide terminarla, marcarla `[!]`, escribir el motivo debajo, revertir lo que quede roto y pasar a la siguiente.
9. **Seguir** con la siguiente tarea, salvo que la recién hecha sea 🛑 o el usuario haya pedido solo una.

Para encadenarlas: `/siguiente-tarea` hace una; `/loop /siguiente-tarea` las va haciendo hasta acabar la cola o llegar a un 🛑.

---

## Fase 39 — Primera impresión: título, personajes y prólogo (versión 3.7.0)

### [x] T183 · Transiciones sin cortes · M
Origen: R9
- Título con fundido de entrada al abrir el juego y un sonido al pulsar para continuar (`title_screen.gd:34-56`, `:188-190`).
- Creador → prólogo y creador → menú con `ScreenTransition` en vez de `change_scene_to_file` directo (`character_creation.gd:369`, `:373`).
- Prólogo → mundo con el barrido y la tarjeta de carga, no una congelación en negro (`prologue.gd:679`).
- `ScreenTransition`: tras el cambio de escena, esperar un fotograma y limitar el delta para que el destape no se salte (`screen_transition.gd:47-59`). Un sonido suave en el barrido.
- Tarjeta de carga con fundido de entrada y sin salto de progreso en el primer fotograma (`loading_card.gd:57-81`).
- Prueba: el destape de `ScreenTransition` dura lo mismo aunque el primer delta sea de 2 s.

### [ ] T184 · Menú principal vivo · M
Origen: R9
- Fondo animado y barato: rejilla de puntos cacheada en textura, lluvia de binario tenue y bits que suben, sin competir con el personaje (`main_menu.gd:39-45`, `ui_style.gd:542-558`).
- Entrada escalonada de logo, tarjetas y panel con `UiMotion` al terminar el barrido.
- Tarjetas de personaje con el estilo de `UiStyle.button` (rebote y sonido al pasar). Sonido de clic al pulsar en **todos** los botones de `UiStyle` (`ui_style.gd:529-538`).
- Al cambiar de tarjeta: la figura sale y entra con un destello de bits, el pedestal cambia de color con un fundido y el texto de detalle escribe a máquina (`main_menu.gd:272-297`).
- Cambiar de espacio de guardado, borrar personaje o cambiar el tamaño de la interfaz con transición en vez de reconstruir de golpe (`main_menu.gd:110-113`, `:187`, `:322-324`).
- Prueba: ningún botón del menú se crea sin pasar por `UiStyle`.

### [ ] T185 · El personaje en la selección y el creador · M
Origen: R9
- Selección: la figura gira despacio sola (abajo → lado → arriba → lado) con un paso intermedio en cada cambio de dirección, y vuelve a mirar al frente al hacer su pose.
- Creador: arrastrar con el ratón o el dedo para girar; los botones < > giran con la misma transición (`character_creation.gd:310-314`).
- Creador: la figura posa con el arma al cambiar de clase o de arma (hoy `action` queda vacío), y cada cambio de opción o color da un pequeño «pop» con destello (`:322-343`). El pedestal toma el color de la clase.
- Muestras de color con rebote, sonido y la seleccionada resaltada con un marco animado (`:261-277`).
- Prueba: girar ocho veces vuelve a la dirección inicial y no deja la figura a medio paso.

### [ ] T186 · Rendimiento de las pantallas iniciales · S
Origen: R9
- Título: no crear un `RandomNumberGenerator` por edificio en cada fotograma (`title_screen.gd:248-249`); precalcular la ciudad.
- Lluvia, columnas y ciudad del título recalculadas al cambiar el tamaño de la ventana o girar el celular (`:118-133`).
- Fondos estáticos de menú, creador y carga en texturas cacheadas en vez de redibujarlos con `draw_*` cada fotograma.
- Medir FPS en título, menú y creador con el perfil de celular antes y después; anotar las cifras en el registro.

### [ ] T187 · Prólogo: personajes con vida · M
Origen: R9
- El jugador respira cuando está quieto (`state:"idle"` ya existe en `character_appearance.gd:172-173`; hoy se congela, `prologue_stage.gd:193`).
- Rafa teclea sentado, mira al jugador cuando entra y se levanta con una animación corta en vez de un corte (`prologue_stage.gd:758-763`, `prologue.gd:534-536`).
- El velo de la intro se desvanece en vez de desaparecer en un fotograma (`prologue.gd:446`, `:710`).
- Ventana de contratación: entra y sale con `window_in`/`window_out`, el botón «No» se desliza en vez de teletransportarse, el globo de error aparece con un pop (`hire_dialog.gd:158`, `:258`, `:271`). Cada clase muestra su figura animada además de los iconos.
- Corregir el tecleo que depende de los FPS: sonar al cruzar cada 3 caracteres, no por fotograma (`prologue.gd:201-202`).
- Prueba: a 30, 60 y 144 FPS suena el mismo número de teclas para el mismo texto.

### [ ] T188 · Prólogo: calle y pasillo con vida · M
Origen: R9
- Calle: autos que pasan (los aparcados siguen quietos), un par de peatones, gaviotas, brillo del sol sobre el mar y hojas que vuelan (`prologue_stage.gd:214-304`).
- Pasillo: luz que entra por las ventanas con polvo flotando, una figura que cruza al fondo, una puerta que se cierra.
- Oficina: pantallas con código que se desplaza, el café de alguien humeando.
- Todo en la rejilla de 400×225 del `SubViewport` y con el shader del prólogo.

### [ ] T189 · Música del prólogo · S
Origen: R9
- Un tema tranquilo por tramos (calle, oficina) que se apaga cuando entra la consola roja, y un golpe musical en «EL ÚLTIMO COMMIT» (`prologue.gd:94`, `:752-762`).
- Escrito en `music.json` (`melody`) con los instrumentos que ya usa `MusicPlayer`; los ambientes siguen sonando debajo.

### [ ] T190 · Versión 3.7.0 y revisión en el teléfono · S 🛑
Origen: R9
- Versión 3.7.0 (APK, `latest.json` y Windows), capturas antes/después de título, menú, creador y prólogo en `docs/capturas/interfaz/`, lista `docs/prueba_celular_3.7.md` y README.

---

## Fase 40 — Cada habilidad con su firma (versión 3.8.0)

Estado de partida: las 62 habilidades tienen icono propio; **29 no tienen efecto visual propio** (solo formas genéricas coloreadas por tipo de daño) y **ninguna tiene sonido propio** (capas compartidas a las que solo cambia el tono según el id).

### [ ] T191 · Ficha de firmas de las 62 habilidades · S 🛑
Origen: R9
- Una tabla en `docs/habilidades_y_ram.md` con, por habilidad: forma del efecto al lanzar, en vuelo e impacto, y su sonido (base + capa propia), con el chiste de programador que la inspira. Sin código.
- Grupos que hoy se ven igual y hay que separar: ring (barrido, stack_overflow, core_dump), cone (flamewar, fuzzing), trail (deploy_continuo, force_push), zap (excepcion_en_cadena, tunel_ssh), cloud (fuga_de_memoria, git_revert), ring amarillo (modo_seguro, hiperthreading), `_shout` (los tres gritos) y las 6 auras.

### [ ] T192 · Sonidos que no encajan · S
Origen: R9
- `Sfx.skill_sound` no contempla los kinds leap_slam, cone, unit, aura, terrain, rain, beam, chain, curse ni channel, y los físicos o sin daño caen al sample `projectile` (`sfx.gd:99-125`). Por eso reinicio_forzado, fuzzing, core_dump, las invocaciones físicas, los drones de apoyo y las auras suenan a disparo.
- Las auras suenan dos veces (`play_cast` y `aura_on`/`aura_off`, `skill_controller.gd:401`, `:408`, `:1033`).
- Limpiar lo que no se usa: firmas de `SkillFx.SIGNATURES` iguales a la de por defecto (ping_letal, torreta_ci) o que nunca se disparan (cascada_css); kinds «quake» y «heal» de `signature_layer`; «mine» y «totem» de `skill_sound`.
- Prueba: ningún kind del catálogo cae al sample por defecto.

### [ ] T193 · Efectos propios, parte 1: cuerpo a cuerpo y movimiento · M
Origen: R9
- Barrido, Despliegue Continuo, Reinicio Forzado, Force Push, Fuzzing, Teletransporte TCP, Túnel SSH y Git Revert, según la ficha de T191.
- Ejemplos: Teletransporte con un paquete que viaja entre los dos puntos; Git Revert dejando un «fantasma» de la posición anterior; Force Push con una flecha de commit que empuja.

### [ ] T194 · Efectos propios, parte 2: hechizos y proyectiles · M
Origen: R9
- Ping Letal, Fork Bomb, Stack Overflow, Flamewar, Rayo de Producción, Deadlock, Excepción en Cadena, Fuga de Memoria y Core Dump.
- Firmas de proyectil propias donde hoy se comparte la del tipo de daño (`skill_fx.gd:11-36`). Ejemplos: Stack Overflow con bloques que se apilan y se desbordan; Fork Bomb con copias que se dividen antes de estallar.

### [ ] T195 · Efectos propios, parte 3: buffs, gritos y auras · M
Origen: R9
- Cada aura con su color y su motivo (hoy las 6 son arcos verdes iguales, `skill_controller.gd:2633`): engranajes en Overclock, placas en Blindaje, llaves inglesas en Mantenimiento, etc. Las hostiles, con su propio motivo y no solo un radio rojo.
- Los tres gritos con onda y texto distintos; Firewall, Modo Seguro e Hiperthreading con efecto propio.

### [ ] T196 · Sonidos propios por habilidad · M
Origen: R9
- Una capa de firma propia para cada habilidad (generada con la misma herramienta que los WAV actuales o sintetizada en código), encima de la base por tipo. Primero las 29 sin efecto propio y las 6 auras; luego las demás.
- Prueba: los 62 ids tienen una entrada propia en `SoundMap` y su archivo existe.

### [ ] T197 · Variantes, RAM y ascendencias con señal · M
Origen: R9
- Las 24 variantes cambian al menos el matiz o un detalle del efecto (Unicast, Ping flood, Bomba de racimo, Titán de asedio… hoy se ven y suenan como la base).
- RAM sin señal visual (multicanal, perforación, encadenamiento, guiado, pipeline): un detalle pequeño en el proyectil.
- Procs de ascendencia con efecto propio (hoy reutilizan ring, burst, zap, lock y beam; `skill_controller.gd:425-553`, `:820-908`).

### [ ] T198 · Animación del jugador por tipo de habilidad · M
Origen: R9
- Hoy hay tres (attack, shoot, cast; `player.gd:403`). Añadir canalizar, grito, salto, invocar y aura en las hojas del personaje y del alumno, con su cuadro de impacto.

### [ ] T199 · Versión 3.8.0 y revisión en el teléfono · S 🛑
Origen: R9
- Versión 3.8.0, captura de cada habilidad en `docs/capturas/habilidades/` (una hoja con todas), lista `docs/prueba_celular_3.8.md` y README.

---

## Fase 41 — Invocaciones que se sienten vivas (versión 3.9.0)

Estado de partida: no hay sprites de invocación; todo se dibuja con primitivas en `UnitArt` y `skill_controller.gd`. Todas miran a la derecha, «caminan» aunque estén quietas, atacan solo con destellos y aparecen y mueren con un anillo.

### [ ] T200 · Motor de animación de unidades · M
Origen: R9
- `UnitArt.draw` recibe dirección y estado (quieto, caminar, atacar, aparecer, herido, morir) además de la fase (`unit_art.gd:8`).
- La fase de caminar solo avanza al moverse (`skill_controller.gd:1754`); en reposo, una animación de espera propia.
- Se voltean según hacia dónde se mueven o atacan; los cañones y cabezas apuntan al objetivo.
- Escala por unidad, para Monolito, Microservicios y el Clúster de tres.
- Prueba: una unidad quieta no avanza su fase de caminar; una que ataca a la izquierda queda volteada.

### [ ] T201 · Aparecer y morir · M
Origen: R9
- Aparición: se «compila» de bits o se ensambla pieza a pieza en ~0,4 s (hoy un anillo, `:1740`). Al relanzar, la que se mueve se desvanece y reaparece en vez de teletransportarse.
- Muerte: se desarma en piezas y bits que caen (hoy un destello, `:1776-1779`). Incluye Proceso Hijo y Drones de Vigilancia al caducar, y la torreta y el contenedor Docker (hoy desaparecen sin más, `:1633`, `:1692`, `:2032`).
- Golpe recibido: retroceso y parpadeo, no solo el círculo blanco (`:2680`).

### [ ] T202 · Ataques que se ven · M
Origen: R9
- Cuerpo a cuerpo con embestida, como `_lunge_to` de los enemigos (`enemy_manager.gd:1666`): Daemon con el tridente, Watchdog con mordida, Bot de Pruebas, golems.
- A distancia con apuntado y retroceso: Centinela, Torreta CI, Golem GPU, Bot Rastreador.
- Saltos con el cuerpo en arco en vez de teletransporte con estela (`skill_controller.gd:1877-1900`).
- Golem UTP con latigazo visible de cable (hoy usa el anillo del tanque, `:1815`).

### [ ] T203 · Que cumplan su descripción · M
Origen: R9
- Golem blindado: la doble provocación no está implementada (`skills.json:1683`, `skill_controller.gd:1735`).
- Monolito se ve más grande; Microservicios y el Clúster de tres, más pequeños (`skill_calc.gd:375-387`, `skills.json:1679-1681`).
- Bot Rastreador dispara dardos propios, no la gota de caos genérica (`skill_fx.gd:15`).
- Centinela y R-2PL: láser de verdad (haz) o cambiar el texto de «láser».
- R-2PL: el EMP sale del robot, no del jugador (`skill_controller.gd:2078`); unificar el +40 % de `classes.json:1003-1015` con el +20 % de `ascendancy_trees.json:186`.
- Prueba: cada una de estas reglas con su caso en `tests/test_core.gd`.

### [ ] T204 · Arte propio para las invocaciones rígidas · M
Origen: R9
- Proceso Hijo: dos procesitos con patas, no una caja con «>_» (`skill_controller.gd:2617-2629`).
- Drones de Vigilancia con el `_drone` de `UnitArt` y su detalle, para que coincidan con los demás (`:2429-2436`).
- Torreta CI con cabezal que gira y apunta y disparo desde el cañón (`:1664`, `:2587-2597`); Contenedor Docker que se despliega como una caja que se abre (`:2598-2608`). La torreta deja de compartir dibujo con la RAM Servidor Torreta.

### [ ] T205 · Acompañantes y R-2PL · S
Origen: R9
- Mario, M. Páez y Eugenio caminan con `walk_phase` y miran de espaldas o de perfil según la marcha (hoy se deslizan siempre de frente, `companion_follower.gd:41`).
- R-2PL se coloca según hacia dónde mira el jugador, se inclina al moverse y gira el visor hacia el objetivo (`skill_controller.gd:2063-2100`).

### [ ] T206 · Versión 3.9.0 y revisión en el teléfono · S 🛑
Origen: R9
- Versión 3.9.0, captura de todas las invocaciones en sus estados, lista `docs/prueba_celular_3.9.md` y README.

---

## Fase 42 — Habilidades nuevas (versión 4.0.0)

### [ ] T207 · Elegir las habilidades nuevas · S 🛑
Origen: R9
- Revisar con el usuario el **catálogo de habilidades sugeridas** (abajo) y escoger de 6 a 9. Escribir su diseño (cifras, tags, variante, icono, efecto y sonido) en `docs/habilidades_y_ram.md` y partir la implementación en tareas T208+.

### [ ] T208 · Habilidades nuevas, tanda 1 · M
Origen: R9
- Las tres primeras elegidas en T207, con icono, efecto, sonido, animación y prueba de lógica.

### [ ] T209 · Habilidades nuevas, tanda 2 · M
Origen: R9
- Las siguientes tres.

### [ ] T210 · Versión 4.0.0 y revisión en el teléfono · S 🛑
Origen: R9

---

## Fase 43 — Interfaz y comodidad (versión 4.1.0)

Lo más útil del banco de ideas (abajo). El resto se pasa a tareas cuando el usuario lo elija.

### [ ] T211 · Vista previa animada de la habilidad · M
Origen: R9
- En el tooltip de la habilidad y en la tienda, una miniatura que reproduce el efecto en bucle (el mismo dibujo de `SkillController` en un viewport pequeño).

### [ ] T212 · Muñeco de prácticas en el campamento · S
Origen: R9
- Un servidor de pruebas que recibe golpes y muestra DPS, daño por golpe y por tipo durante los últimos 10 s. Sirve para comparar placas y RAM sin salir a una zona.

### [ ] T213 · Inventario más rápido · S
Origen: R9
- Ordenar con un botón, marcar objetos como «basura» y venderlos todos de una vez en la tienda, y bloquear objetos para que no se vendan por error.

### [ ] T214 · Resumen al salir de una zona · S
Origen: R9
- Al volver al campamento o cambiar de zona: tiempo, enemigos, botín destacado, experiencia y la muerte más tonta (si la hubo), en el estilo de un informe de build.

### [ ] T215 · Versión 4.1.0 y revisión en el teléfono · S 🛑
Origen: R9

---

## Catálogo de habilidades sugeridas

Para elegir en T207. Cada una trae algo que hoy no existe en el juego (la **novedad**), para que no sea otra versión de lo que ya hay.

### Técnico de Soporte (cuerpo a cuerpo, físico)
- **¿Probaste apagarlo y prenderlo?** · attack, melee, area. Un golpe seco que aturde y le **quita los buffs y auras** al enemigo. Novedad: disipar.
- **Cable Ethernet** · attack, melee. Latigazo de alcance medio que engancha al enemigo y lo **atrae** hacia ti; con el botón mantenido, lo hace girar y lo lanza contra otros. Novedad: tirón.
- **Ticket Escalado** · attack, melee, duration. Marca a un enemigo; cada golpe sube la prioridad (P3 → P2 → P1) y en P1 estalla con daño acumulado. Novedad: marca con etapas.

### Tester QA (cuerpo a cuerpo preciso)
- **Caso Borde** · attack, melee. Estocada con **crítico seguro** contra enemigos con más del 90 % o menos del 10 % de vida. Novedad: crítico condicional.
- **Regresión** · attack, melee, duration. El enemigo golpeado **repite el último daño recibido** 1 s después, como un eco. Novedad: eco de daño.
- **Breakpoint** · spell, area, duration. Detiene el tiempo en un círculo: enemigos y proyectiles enemigos quedan casi quietos 2 s. Novedad: ralentizar proyectiles.

### Desarrolladora Frontend (a distancia)
- **Lazy Loading** · attack, projectile. Deja flechas suspendidas en el aire que **solo salen cuando un enemigo se acerca**. Novedad: proyectiles en espera.
- **Diseño Responsive** · attack, projectile. El proyectil se divide en más fragmentos **cuanto más lejos** está el objetivo. Novedad: escala con la distancia.
- **Z-index 9999** · spell, movement. Saltas «por encima de la capa»: 1 s intocable y caes disparando una lluvia. Novedad: invulnerabilidad corta ofensiva.

### Ingeniera de Prompts (caos y cadenas)
- **Inyección de Prompt** · spell, chaos, minion, duration. **Convierte a un enemigo** normal o mágico en aliado durante 8 s. Novedad: control mental.
- **Alucinación** · spell, duration. Crea dos copias falsas de ti que **atraen a los enemigos** y estallan en caos al romperse. Novedad: señuelo.
- **Ventana de Contexto** · spell, area, duration. Mientras estás dentro del círculo, las últimas tres habilidades que lanzaste **se repiten solas** a mitad de daño. Novedad: repetición.

### Científico de Datos (elemental)
- **Descenso de Gradiente** · spell, projectile, cold. Un orbe que **rueda hacia el grupo más denso** de enemigos y crece al atravesarlos. Novedad: busca aglomeraciones.
- **Overfitting** · spell, curse, duration. El enemigo recibe cada vez más daño del tipo que más le han hecho. Novedad: maldición que aprende.
- **Clustering K-means** · spell, area. **Junta a los enemigos** en tres puntos y luego cae un rayo en cada uno. Novedad: agrupar.

### Ingeniero DevOps (invocaciones)
- **Kubernetes** · spell, minion, persistent. Un nodo orquestador que **reinicia las invocaciones caídas** a los 3 s y reparte entre ellas el daño que recibe una. Novedad: resurrección de esbirros.
- **Despliegue Canario** · spell, minion. Una invocación pequeña que, si sobrevive 5 s, **se convierte en tres** de las tuyas. Novedad: invocación que evoluciona.
- **Cron Job** · spell, duration. Cada 2 s lanza sola la habilidad enlazada, aunque no estés atacando. Novedad: disparador por tiempo.

### Full Stack y de cualquier clase
- **Hotfix** · spell, buff. Cura al instante el 40 % de la vida, pero el 30 % vuelve como **daño diferido** en 4 s (se puede anular matando enemigos). Novedad: deuda; encaja con el árbol de deuda técnica.
- **404 Not Found** · spell, movement, duration. Te vuelves invisible: los enemigos **pierden el objetivo** 2 s y el primer golpe al salir es crítico. Novedad: sigilo.
- **Merge Conflict** · spell, projectile. Lanzas dos proyectiles que se curvan y, si **chocan entre sí**, explotan con daño doble. Novedad: proyectiles que interactúan.
- **Garbage Collector** · spell, area. Aspira los restos de los enemigos muertos cerca y te da vida o una carga por cada uno. Novedad: usar cadáveres.

---

## Banco de ideas (sin cola)

Ideas que no están en la cola. Se pasan a tareas cuando el usuario las elija.

### Interfaz
- Códice de enemigos: los vistos, sus debilidades, sus ataques y una animación.
- Historial del botín recogido en la zona, con filtro por rareza.
- Logros y subidas de nivel con una notificación más vistosa y con sonido propio.
- Comparar un objeto del suelo al pasar por encima, sin recogerlo.
- Tooltips de pasivas con «qué cambia en tu build» (antes/después con tus cifras).

### Comodidad
- Recoger oro y fragmentos sin pulsar (con radio ajustable).
- Repetir el último crafteo con un botón.
- Exportar e importar una build como código de texto (árbol, habilidades y RAM).
- Ajustes de gráficos recomendados según el teléfono al primer arranque.
- Copia de seguridad de los guardados a un archivo para pasarlos entre PC y celular.

### Juego
- Nueva partida+ al acabar el acto IV, con modificadores y cosméticos.
- Incidente semanal con semilla fija y su ladder local.
- Jefes opcionales escondidos en zonas generadas (un «bug legendario» por acto).
- Mascotas cosméticas que siguen al jugador (reutilizando el motor de T200).
- Aspecto de armas y atuendos independiente de las cifras (transfiguración).

### Técnica
- Capturas automáticas de pantallas clave para detectar cambios visuales sin querer.
- Medidor de FPS por pantalla en las pruebas del perfil de celular.

---

## Registro

- 2026-11-02 · — · Roadmap 2 creado a partir de la revisión de las pantallas iniciales, las 62 habilidades y las invocaciones.
- 2026-11-02 · T183 · Transiciones sin cortes: el título sale de negro en 0,8 s (el aviso espera) y suena al continuar; creador → prólogo, creador → menú y prólogo → mundo con el barrido (el mundo abre con su tarjeta de carga); `ScreenTransition` espera 2 fotogramas tapado tras el cambio, limita el delta a 1/30 s (`step`) y suena muy bajo; la tarjeta de carga tapa desde el primer fotograma con el fondo y el contenido entra en 0,18 s, sin salto de progreso. Pruebas del destape tras un delta de 2 s y del fundido del contenido.
