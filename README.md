# Path Overflow — El Último Commit

ARPG estilo Path of Exile en **Godot 4.7**, de ambientación oscura y con sarcasmo de programador.
Por ahora es solo para un jugador en local, pero la lógica está escrita para poder pasar a un modelo cliente-servidor en el futuro.

**Versiones**: la 2.0 queda en la rama `version-2.0` (etiqueta `v2.0`). La **3.0** (etiqueta `v3.0`) trae zonas de combate que se generan en cada visita y se conservan 10 minutos (salvo la arena del jefe), una mecánica al azar por zona (como mucho un evento menor más), tokens y waypoints que se recogen y se descubren desde más lejos, vuelta entre actos solo por waypoints, salas temáticas, profundidad en el suelo, niebla en el minimapa, la ventana de waypoints como mapa del acto, comparación de placas y RAM, registro de sucesos y escenas con cámara, llegadas a cada campamento y epílogos de los jefes. El detalle, en `docs/roadmap.md` (T111-T131). La **3.1** (en curso) es la del celular: controles en el prólogo, filtro de botín con el dedo, botón de usar y recoger por rareza, todas las ventanas revisadas al tacto, botones en la esquina con modo zurdo y editor de disposición, tutorial para el dedo y la versión a la vista (T132-T139). La **3.2** agranda el juego en el celular: «Tamaño del mundo» (130 % por defecto), personajes y NPC un 15 % más grandes con contorno y anillo de clase, enemigos con un tamaño mínimo y texto del mundo a la medida del zoom, además de «Continuar» de un toque en el título (T154-T158); la 3.2.1 pasa el celular al renderizador Compatibility contra el parpadeo de la interfaz. La **3.3** rehace a los personajes con el estilo chibi de la referencia del usuario: hojas a 1,5× de resolución (un archivo por variante), cabeza grande, ojos con brillo, sombreado en tres tonos y contorno grueso; cada clase con su equipo de oficio (chaleco, bata, capucha y paleta, audífonos, tableta holográfica, casco de obra, mochila), cada NPC con su objeto y su gesto de reposo, y respiración, rebote al andar, estiramiento al golpear y polvo al esquivar (T160-T163). La **3.4** trae el logo de la app y, desde el acto I, el alumno en pixel art con el estilo de la lámina del usuario: de frente, de espaldas y de perfil, con 16 peinados, lentes y el look del equipo que lleva; un sprite por arma (teclados, sable de fibra óptica, cúter...) y los NPC con el equipo de su arquetipo y su objeto en la mano (T174-T182). La **3.5** cambia la interfaz al estilo «panel de monitoreo/datos»: ventanas como tarjetas turquesa, vida y maná como medidores circulares, habilidades como teclas, minimapa de radar, misiones como lista TODO, registro como consola, carga como registro de arranque, muerte como volcado de error y la fuente Fira Code (T165-T170). La **3.6** pone a los enemigos al nivel de los personajes (64 px, sombreado en tres tonos y contorno grueso) y los efectos con temática de datos: nodos de red que se apagan al morir, el glifo de cada familia, corchetes en los golpes fuertes y bits en el botín (T171-T173; antes/después en `docs/capturas/estetica/`). La **3.7** abre el Roadmap 2 (`docs/roadmap2.md`) con la primera impresión: el título sale de negro y todas las pantallas pasan con el barrido; la lista de personajes tiene un fondo de paquetes de datos, entrada escalonada, botones con clic y un personaje que gira y posa; el creador se gira arrastrando; el prólogo tiene vida (autos, peatones, gaviotas, Rafa que teclea y se levanta), una ventana de contratación animada con la figura de cada puesto y música propia (T183-T190). La **3.8** da a cada habilidad su firma: las 62 con efecto y sonido propios según una ficha de diseño (llaves del Barrido, pantalla azul de Reinicio Forzado, sonar de Ping Letal, sirena de ¡PROD!, seis auras con su color y motivo...), variantes con su matiz y su tono, la señal de las RAM en los proyectiles (abanico, «×2», perforar, encadenar, guiado), efectos propios de las ascendencias y una animación del personaje por tipo de habilidad; trae además invocaciones que miran, atacan, se compilan al aparecer y se desarman al caer, la vista previa animada en el tooltip de las placas, un muñeco de prácticas con DPS en cada campamento e inventario con basura y bloqueados a la vista (T191-T202, T211-T213, T216-T218). La **3.9** (que incluye la 3.8, no publicada por separado) da vida a las invocaciones: miran hacia donde van, caminan solo al moverse, se compilan de bits al aparecer, embisten o retroceden al atacar, saltan en arco y se desarman al caer; cumplen su texto (el Golem blindado provoca el doble, el Bot Rastreador dispara dardos, Centinela y R-2PL disparan láseres, el EMP sale del robot); Proceso Hijo, los drones, la Torreta CI y el contenedor tienen arte propio, y los acompañantes caminan y el R-2PL sigue tu mirada (T200-T206). La **4.0** trae seis habilidades nuevas elegidas del catálogo del Roadmap 2, una por clase a nivel 12, cada una con una mecánica que el juego no tenía: **Ticket Escalado** (cada golpe sube la prioridad del enemigo, P3, P2 y en P1 estalla), **Breakpoint** (detiene a los enemigos y sus proyectiles en un círculo), **Lazy Loading** (flechas que esperan en el aire hasta que algo se acerca), **Inyección de Prompt** (un enemigo pelea de tu lado y su botín sigue siendo tuyo), **Descenso de Gradiente** (un orbe que busca el grupo más denso y crece) y **Despliegue Canario** (un canario que, si aguanta, se promueve a tres bots) (T207-T210). La **4.1** cierra el Roadmap 2 con un informe al salir de cada zona de combate, con forma de log de build: OK o FAILED, el tiempo, los procesos terminados, la experiencia, el DPS medio, los mejores artefactos con su color y «la muerte más tonta» (T214-T215). La **4.2** da voz al prólogo: diálogos grabados (generados en local con Qwen3-TTS a partir de una ficha de casting, docs/voces.md) para Rafa, el narrador, Mario y el egresado o la egresada según la nueva opción «Voz» del creador; además, los autos de la avenida a la escala del jugador, el jugador a la de la caja y la TV al fondo del pasillo, y Aída con tilde. La **4.3** da voz a todo el juego: las escenas y los diálogos de todos los NPC de los actos I-IV (unas 420 líneas generadas en local con Qwen3-TTS desde las tomas que eligió el usuario), frases de combate con la voz del personaje (al subir de nivel, morir, beber un refresco, quedarse sin vida o sin maná), jefes que hablan al despertar, en cada fase y al caer, con subtítulo bajo su barra, y el **diario del egresado** en la hoja de personaje (C) con «¿dónde me quedé?»; además B.O.B. se ve como en su miniatura, el creador cabe en PC y tableta y en el prólogo el jugador gatea hacia la salida antes de ser absorbido (T220-T226).

## Cómo abrirlo

- **Jugar sin el editor**: doble click en `Jugar.bat` (pantalla completa, sin depurador). **F11** o **Alt+Enter** cambian entre pantalla completa y ventana en cualquier momento.
- **Editor de historia**: doble click en `Editor de historia.bat` (botón «?» para la guía). Cada conversación se edita como un guion de tarjetas: lo que dice el personaje y las respuestas del jugador, con adónde lleva cada una, y lo avanzado (cuándo aparece una respuesta, qué hace) tras «⚙» con formularios. Vista previa navegable, Ctrl+Z, búsqueda de frases en toda la historia. Pestaña **Prólogo** con la introducción, letreros, avisos, conversaciones, ventana de contratación y consola (`data/prologue.json` y escenas `prologo_*`); también escenas, misiones y tutorial. Guarda en `data/*.json` (con copia en `user://story_backups/`), revisa referencias rotas, abre el juego con los cambios y genera `build/PathOverflow.exe`.
- **Exportar** (`build/PathOverflow.exe`, un solo archivo con el juego dentro, pantalla completa por defecto): las plantillas de exportación de Godot 4.7.2 están instaladas en `%APPDATA%\Godot\export_templates\4.7.2.stable`. Proyecto → Exportar → Windows, o `Godot_v4.7.2-stable_win64.exe --headless --path . --export-release Windows build/PathOverflow.exe`.

1. Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`.
2. Pulsa **F5**. Aparece la pantalla de título (logo, música); cualquier tecla lleva a la lista de personajes.
3. Un personaje nuevo empieza en **El Sandbox**, la zona tutorial. Desde ahí se llega al campamento y al resto del acto. El tutorial (arriba a la izquierda) te guía; se puede saltar.

| Tecla | Acción |
|---|---|
| Flechas / mantener click izq. | Mover |
| Q · W · E · R · T · Y | Las 6 habilidades de la barra |
| Espacio | Esquiva (*git stash*): salto corto con un instante de invulnerabilidad; 2 cargas que se recargan solas (más cargas, recarga más rápida, Multihilos al esquivar y explosión *git stash pop* con afijos, chips, el árbol y algunas ascendencias) |
| Tab | Mapa grande de la zona (con niebla de guerra). Rueda o +/−: zoom centrado en ti; clic derecho: poner o quitar una marca propia (hasta 12 por zona, se guardan y salen también en el minimapa) |
| Shift (mantener) | Ver el botín que oculta el filtro (atenuado) |
| B | Catálogo de hardware: todas las placas base y RAM |
| 1 - 5 | Pociones del cinturón (cafés, bebidas y de utilidad) |
| Click en un objeto o NPC | Ir a recogerlo / hablar |
| I | Inventario: arrastra para mover y equipar; click equipa o quita |
| K | Habilidades: arrastra placas a la barra y RAM a sus ranuras |
| C | Hoja de personaje (con retrato animado y opiniones no solicitadas) |
| M | Mostrar u ocultar el minimapa |
| L | Plegar o desplegar el registro de misiones |
| P | Árbol pasivo (pausa el juego) |
| Esc | Cierra lo abierto; si no hay nada, menú de pausa |
| F1 / F2 / F3 / F4 | Depuración: +30 enemigos / limpiar / jefe único / botín de prueba |
| R | Reaparecer en el pueblo del acto tras morir |
| Click en un waypoint | Viajar a otro waypoint descubierto |

Todas las teclas están en *Proyecto → Configuración del proyecto → Mapa de entrada*. Pasa el ratón por cualquier elemento del HUD para ver una ayuda.

**Pantalla táctil**: apoya el dedo en la parte izquierda de la pantalla y aparece un **joystick** donde lo pusiste (con zona muerta); arrástralo para moverte (también en el prólogo, donde un **botón dorado abajo a la derecha** usa lo que tienes cerca: la entrada, la TV, Rafa, el rack). Tocar el mundo fuera de él hace lo mismo que el clic: ir ahí, recoger botín o hablar con un NPC. Con algo cerca aparece abajo, junto a las habilidades, un **botón dorado de usar** con su dibujo y su texto (Recoger, Hablar, Waypoint, Alijo, Abrir...), y unas esquinas doradas marcan en el suelo a qué: tocarlo lo usa (con varios objetos, el más raro primero) y **mantenerlo recoge todo lo de alrededor**. En Pausa → Controles, **Recoger solo al pasar** (desde la rareza que elijas, si el filtro lo deja ver). Al morir, un botón **Reaparecer en el campamento** (además de R). El botón **Atrás** de Android hace de Esc (cierra la ventana de arriba o abre la pausa; en el título y el menú pregunta antes de salir) y, al salir de la app, la partida se guarda y queda en pausa. La interfaz se aparta de la muesca y las esquinas redondeadas, y el celular **vibra** un instante con los golpes fuertes, los críticos, al subir de nivel, cuando cae un único y al pulsar los botones (Pausa → Combate → «Vibración»). Para la batería, **FPS: auto** (Pausa → Gráficos) deja 60 y baja solo a 30 si la partida va justa; también se puede fijar 30, 60 o sin límite, y el contador de FPS se enciende ahí mismo. **Tamaño del mundo** (Pausa → Gráficos): la cámara se acerca al 130 % en el celular (100 % en el PC) para que personajes, enemigos y botín se vean más grandes; se puede elegir 100, 115, 130 o 140 %, siempre con tope para que se vea el alcance del ataque automático alrededor. Las habilidades **apuntan solas** al enemigo más cercano en la dirección del joystick (o al más cercano si no lo mueves), marcado con una mira roja. Con pantalla táctil, la barra del HUD cambia de forma: la **habilidad 1, grande, en la esquina** junto al orbe de maná y las otras 5 en dos anillos a su alrededor, la **esquiva** encima del orbe, las **pociones** en fila a la izquierda y los menús en un botón **☰**. En Pausa → Controles se elige entre esa distribución y la de **dos arcos**, el **tamaño** de los botones (80-140 %) y la **mano** (zurda: todo en espejo, con el joystick a la derecha). Con **Mover y ajustar los botones...** se arrastra cada botón a donde quieras, se agranda o achica y se elige la **opacidad**; «Restaurar» lo deja como venía. Mantener una habilidad la canaliza o la repite; **arrastrar el dedo desde ella apunta a mano** (línea discontinua hasta el punto). **En las ventanas** (inventario, alijo, tienda, habilidades, hoja, árbol pasivo): tocar un objeto o un nodo enseña su tooltip y un botón dorado con lo que hace (Equipar, Quitar, Al alijo, Comprar, Instalar, Asignar…); tocarlo otra vez, o el botón, lo hace. **Arrastrar en vertical** sobre la bolsa la desplaza. **Mantener** el dedo es el clic derecho (marcar basura, quitar una placa, devolver un nodo), **arrastrar** mueve objetos como con el ratón (y la vista del árbol) y **dos dedos** hacen zoom en el árbol y en el mapa grande. Arriba a la derecha, junto al minimapa, botones de **Mapa** y **pausa** (II, como Esc), que se apartan con una ventana abierta. Con la interfaz al 140 % del celular, todo lo que se toca mide 44 px o más. Se ocultan en Pausa → Controles → «Controles táctiles» y solo salen con pantalla táctil.

**Objetos**: arrastrar y soltar entre bolsa, equipo, barra de habilidades y ranuras DIMM (intercambia si hace falta; las reglas están en `ItemTransfer`). Soltar un objeto fuera de los paneles lo tira al suelo; ya no se pueden destruir con un click.

**Al lanzar habilidades** el personaje solo se detiene un instante (25 % del tiempo de uso, máximo 0,15 s); el ritmo de ataque no cambia.

**Animación al caminar**: piernas alternas que se levantan, brazos en oposición y el cuerpo sube y baja con cada paso. El ciclo avanza con la distancia recorrida de verdad, así que los pies no "patinan" y, si choca contra algo, deja de andar en el sitio. De perfil, las piernas avanzan y retroceden y el cuerpo se inclina.

**Poses por estado**: en reposo respira; con más velocidad de movimiento corre (zancada y balanceo mayores); el arma equipada (espada, hacha, maza o daga) se ve en la mano. Las habilidades cuerpo a cuerpo hacen el golpe según el arma (la espada, el hacha y la maza suben y bajan de golpe; la daga es una estocada), los ataques a distancia lanzan hacia delante, los hechizos suben las manos con el brillo de su elemento y al canalizar las mantiene delante. Al recibir un golpe retrocede, al esquivar se agacha y rueda, y al morir cae de lado. Los ataques **golpean en el cuadro de impacto** (cuando el arma pasa por delante, al final de la estocada o al soltar lo lanzado; como mucho 0,3 s después de pulsar), no al pulsar; los hechizos siguen saliendo al instante. Hoja de poses: `capture_screens.tscn -- poses`.

`scenes/ui/passive_tree_screen.tscn` funciona sola (F6) para probar builds, y `scenes/game/world.tscn` (F6) arranca con un personaje temporal que no se guarda.

## Progresión

- **Puntos de pasiva**: se empieza con 0; cada nivel da 1 y las misiones de la historia dan puntos extra (2 por cada misión principal de acto y 1 por algunas secundarias).
- **Las placas base suben de nivel** (hasta el 40) con la experiencia mientras están instaladas, como las gemas de PoE. Cada nivel da más daño (hechizos: +15 % lineal ×1,03; ataques: +12 % sobre el arma), +1 % de área, ancho y duración y -1 % de enfriamiento. En los **niveles 10, 20 y 30** ganan un hito según la habilidad: +1 proyectil, +1 salto de cadena, +1 esbirro, +1 bomba a la vez, +10 % de área o +10 % de daño. El tooltip muestra el nivel, la experiencia y los hitos.
- **Atributos con daño**: la Fuerza da daño físico cuerpo a cuerpo (1 % por cada 4), la Destreza daño de proyectiles (1 % por cada 4) y velocidad de ataque, y la Inteligencia daño de hechizos (1 % por cada 4). Los caminos de atributos del árbol dan +12.
- **Ascendencias** con mucho impacto: bonificaciones grandes (+25-60 % más) y efectos que cambian las habilidades: proyectiles adicionales, cadenas adicionales, esbirros adicionales o más trampas, minas y torretas a la vez.
- Estos cambios **devuelven los puntos de pasiva** a los personajes guardados (árbol versión 4).

## Habilidades: placas base y RAM

La versión informática de las gemas de PoE:

- **Placa base** = habilidad activa. Es un objeto que cae como botín, con **3 a 7 ranuras DIMM**. Cada ranura es de una generación: **DDR3** (rojo, fuerza), **DDR4** (verde, destreza) o **DDR5** (azul, inteligencia). Su nivel sigue al nivel del objeto y escala el daño de los hechizos.
- **Módulo RAM** = soporte. Solo encaja en ranuras de su generación, y solo hace efecto si la habilidad es compatible (p. ej. *RAM Multicanal* solo con proyectiles). Cada módulo multiplica el **consumo de maná**.
- Las 6 placas instaladas forman la barra de habilidades. El orden se cambia con *Subir/Bajar* en el menú K.
- Los ataques usan el arma equipada (daño × efectividad); los hechizos tienen daño propio. Todo pasa por `SkillCalc`, así que el tooltip muestra exactamente lo que ocurre en combate.

| Habilidad | Tipo | | Módulo RAM | Efecto |
|---|---|---|---|---|
| Barrido | ataque, área | | Multicanal (DDR4) | +2 proyectiles, menos daño |
| Ráfaga de Paquetes | ataque, proyectiles | | Overclock (DDR4) | más velocidad |
| Ping Letal | hechizo, rayo que atraviesa | | ECC (DDR5) | más crítico |
| Fork Bomb | hechizo, explosión en el suelo | | Caché L3 (DDR5) | más área |
| Stack Overflow | hechizo, onda de frío | | Disipador (DDR3) | menos área, más daño |
| Teletransporte TCP | movimiento | | Pipeline (DDR3) | la habilidad se repite |
| | | | Puntero Salvaje (DDR4) | los proyectiles atraviesan |
| | | | Fuerza Bruta (DDR3) | más daño físico |
| | | | Alto Voltaje (DDR5) | más daño elemental de hechizos |
| | | | Swap Vampírica (DDR3) | robo de vida |

Se definen en `data/skills/skills.json` y `data/skills/ram_modules.json`. Cada clase empieza con **tres placas exclusivas** (`starter_skills` en `classes.json`) y un **rasgo de clase** siempre activo (`trait`); ninguna comparte habilidad inicial con otra ni juega con la misma combinación de mecánicas (lo comprueban las pruebas). Los personajes de antes reciben la placa que les falte al cargar (bandera `starter_kit_v2`).

| Clase | Kit inicial | Rasgo |
|---|---|---|
| Técnico de Soporte | Barrido · **Reinicio Forzado** (salto con aturdimiento) · Firewall Personal | Mantenimiento Preventivo: sangrado cuerpo a cuerpo, estados más largos, armadura |
| Tester QA | **Fuzzing** (3 tajos en cono) · Despliegue Continuo · Hiperthreading | Pruebas de Regresión: crítico y sangrado con ataques |
| Desarrolladora Frontend | Ráfaga de Paquetes · **Cascada de Estilos** (lluvia helada) · Teletransporte TCP | Diseño Responsive: los proyectiles hielan, más velocidad |
| Ingeniera de Prompts | Rollback · Excepción en Cadena · Bomba Lógica | Inyección de Prompts: veneno y daño de estados |
| Científico de Datos | Ping Letal · Stack Overflow · Fork Bomb (los tres elementos) | Sobreajuste: los hechizos queman, hielan y electrocutan |
| Ingeniero DevOps | Torreta CI · **Robot Centinela** (persistente) · Drones de Vigilancia | Infraestructura como Código: autómatas más rápidos y fuertes |
| Full Stack | Bucle Infinito · Flamewar · **Daemon en Segundo Plano** (persistentes) | Hilo Principal y Secundario: daño, esbirros y menos reserva |

**Habilidades de movimiento** (etiqueta `movement`; cada clase recibe la suya al **nivel 8**): **Túnel SSH** (Inteligencia; Científico de Datos e Ingeniera de Prompts): teletransporte corto que suelta una descarga eléctrica donde estabas y donde llegas · **Force Push** (Fuerza; Técnico de Soporte, Ingeniero DevOps y Full Stack): carga hasta el primer enemigo hacia el cursor, lo arrolla con los de alrededor, los empuja lejos (`EnemyManager.push_in_radius`) y los aturde · **Git Revert** (Destreza; Tester QA y Desarrolladora Frontend): salto hacia atrás, lejos del cursor, que deja una zona helada donde estabas. Se suman al Teletransporte TCP, Despliegue Continuo y Reinicio Forzado; los teletransportes ya no caen dentro de paredes ni obstáculos (buscan el punto libre más cercano).

**Terrenos** (`kind: terrain`, placas que caen como botín): **Derrame de Aceite** (ralentiza; si algo en llamas lo toca —un enemigo quemándose, un proyectil o una explosión de fuego— estalla, quema a todos y el suelo arde 3 s), **Campo de Estática** (rayo por segundo, electrocuta) y **Charco de Refrigerante** (frío por segundo, hiela). **Combos**: aceite + fuego = explosión y suelo en llamas; estática + refrigerante encimados = **superconductor** (el doble de rayo, hiela y puede congelar). Cada terreno tiene su color y su textura y, en modo daltónico, un patrón propio (rayas, zigzag, cruces, diagonales, puntos). Capturas: `capture_screens.tscn -- terrenos`.

**Cargas en las builds**: en el árbol, *Hormigón Armado* (+1 Buffer máximo), *Excepción Capturada* (+1 Multihilos máximo), *Segmentation Fault* (+1 Overclock máximo) y *Compilación JIT* (recuperas un 3 % del maná por cada carga que gastas); en las ascendencias, *Lista blanca* (Guardián del Firewall: +1 Buffer y más probabilidad de ganarlo), *Token robado* (Asesina de Sesiones: +1 Overclock y maná al gastar) y *Pager a las 3 AM* (Berserker del Hotfix: más Multihilos). **Core Dump** (hechizo, nova física) gasta todas tus cargas a la vez (`spend` en skills.json): cada Buffer cura y suma daño, cada Multihilos suma daño y el Overclock da crítico seguro; las RAM de gasto no encajan en ella porque ya lo hace sola.

**Conversión de daño en el árbol** (`Stat.TREE_CONVERSIONS`): *Pico de Tensión* convierte todo tu daño físico en rayo, *Thermal Throttling* el físico en fuego y *Rootkit Residente* el elemental en caos, para toda la build y sin ocupar ranura. Funciona como las RAM de conversión (tipo, resistencias, estados innatos y etiquetas del nuevo; la escalan los dos tipos) y, si una RAM ya convierte la habilidad, manda la RAM. Con dos del mismo origen, la primera de esa lista.

**RAM de activación** (`special.trigger`): la habilidad deja de lanzarse a mano y se lanza sola hacia el enemigo más cercano, pagando su maná y con un enfriamiento interno. **Manejador de Excepciones** (DDR3): al recibir un golpe, cada 0,8 s como mucho. **Cron Job** (DDR4): cada 2 s si hay un enemigo cerca. **Hook pre-stash** (DDR4): al esquivar, cada 0,6 s como mucho. **Callback onKill()** (DDR3): al matar con otra habilidad, cada 0,4 s como mucho (lo que mata ella no cuenta). En la barra la placa lleva el rótulo **AUTO** y una franja con su enfriamiento interno; su ayuda y el menú K dicen qué la activa; un consejo lo explica la primera vez. **Breakpoint Condicional** (DDR5): con cada crítico de tus otras habilidades, cada 0,5 s como mucho; los críticos de una habilidad activada (también sus explosiones retardadas y proyectiles) no activan nada, así que no hay bucles. Los eventos se resuelven en el fotograma siguiente, nunca en mitad de un golpe.

**Estados alterados** (`Ailments`, iconos en `StatusIcon`): cada golpe tira los dados de **quemar** (daño de fuego por segundo), **electrocutar** (+25 % de daño recibido), **helar** (35 % más lento), **congelar** (no actúa), **envenenar** (se acumula hasta 10) y **hacer sangrar** (el doble si se mueve). Cada tipo de daño tiene una probabilidad innata hacia su estado, que suben la propia habilidad (`ailments` en `skills.json`), los rasgos, las pasivas (temáticas Ignición, Sobrecarga, Criogenia, Toxinas y Hemorragia) y las **RAM de asistencia**: Pasta Térmica Caducada, Módulo de Sobretensión, Refrigeración Líquida con Fugas, Inyección de Malware, Fragmentación de Disco y Gestor de Estados Global. Los iconos salen sobre la barra de vida de los enemigos y en el **marco del objetivo** (arriba, al pasar el mouse por un enemigo); los del jugador, sobre el orbe de vida.

**Autómatas** (etiqueta `automaton`): torretas, drones, esbirros y robots. Les afectan la *velocidad de autómatas*, la temática de pasivas Automatización, la piedra angular **Microservicios** (antes Orquestación con Kubernetes: +2 invocaciones persistentes a la vez, cada una con un 30 % menos de vida, daño y reserva; +1 dispositivo y más daño de autómatas) y las RAM Firmware Autónomo, Protocolo Enjambre y Carcasa Reforzada. Su contrario es **Monolito** (antes Hola Mundo en 40 Lenguajes, junto al Full Stack): una sola invocación persistente de cada tipo con el triple de vida y daño. Si tienes los dos, manda el Monolito.

**Invocaciones persistentes** (`kind: unit`): Robot Centinela, Daemon en Segundo Plano, Dron Escolta y Golem de Hardware Reciclado. No caducan: **reservan un % del maná máximo** mientras sigan en pie (la parte rayada del orbe), te siguen entre zonas y los enemigos pueden atacarlas (el golem además los provoca). Si caen, se vuelve a lanzar la habilidad; si ya están todas, relanzarla las repara. Quitar la placa de la barra las retira.

**Gritos** (etiqueta `warcry`, potenciadores de 6 s): **¡Está en producción!** (+15 % más daño para ti, +30 % más daño de esbirros y +20 % de velocidad de autómatas), **¡Daily en cinco minutos!** (velocidad de movimiento, ataque y lanzamiento, y +40 % de velocidad de autómatas) y **¡Rollback!** (cura un 30 % a las invocaciones, +30 % más armadura y +30 % de vida de esbirros). Llegan a las invocaciones por sus stats; se ven como una onda grande y un destello en cada aliado.

**Hechizos canalizados** (etiqueta `channel`): se mantienen pulsados (teclado o mando) y cobran su maná **por segundo**; mientras tanto no te mueves ni lanzas otra cosa, y se cortan al soltar o al quedarte sin maná. Golpean una vez por cada uso que darían a su ritmo de lanzamiento. **Pipe de Datos**: rayo continuo de rayo hacia el cursor. **Tormenta de Tickets**: tormenta de frío que sigue al cursor y crece hasta el triple de tamaño y el doble de daño en 3 s. No van en trampas, minas, torretas, contenedores ni con RAM de activación.

**Comparar placas y construcciones** (menú K): **Comparar** y luego dos placas (de la barra o de la bolsa) las enseña lado a lado: DPS, daño por golpe, usos por segundo, crítico, coste o reserva de maná, área, proyectiles, enfriamiento y duración, con la mejor en verde. **Construcciones** guarda con un nombre el árbol pasivo (nodos y maestrías) y qué habilidad va en cada ranura de la barra (hasta 8, con el personaje); al cargar una, los puntos se reasignan gratis y se colocan las placas que tengas (la de más nivel de cada habilidad), avisando de las que falten. No se carga si usa más puntos de los que tienes o si las placas que salen no caben en la bolsa.

**Variantes** (`data/skills/variants.json`, botón de la placa en el menú K): desde cierto nivel de placa, una habilidad puede cambiar de forma (más área y menos daño, más proyectiles, etc.). Todas las auras tienen una (efecto contra radio o contra reserva: Overclock extremo, Blindaje concentrado, Mantenimiento remoto, Mando ligero, Rate limit agresivo, Escaneo amplio), los Drones de Vigilancia dos (Enjambre: +2 drones; Patrulla larga: el doble de duración) y la Bomba Lógica dos (Bomba de racimo: +3 a la vez; Detonación remota: se activa al doble de distancia). `mult.aura_effect` escala los bonos del aura con sus topes.

**RAM por grados**: los módulos tienen *menor / normal / mayor* y solo caen cuando el nivel de la zona alcanza su `min_level` (acto I: menores; acto II: normales; acto III: mayores). El encadenamiento es el ejemplo: *Propagación de Excepciones Menor* salta 1 vez (−30 % de daño por salto), la normal 2 (−25 %) y la mayor 3 (−20 %). Al subir de nivel la placa **no** añade saltos: la penalización mejora 1 punto por nivel (−30 % → −29 % ...). También hay grados para las RAM de estados, y módulos nuevos: Explotador de Vulnerabilidades (daño contra enemigos con estados), Sensor de Precisión, Gestor de Memoria Eficiente, Amplificador de Aura, Redundancia de Invocaciones y Firmware Resiliente.

**Invocaciones y auras persistentes** (`kind: unit` / `aura`): además del Robot Centinela, Daemon, Dron Escolta y Golem, hay *Dron de Mantenimiento* (cura), *Dron Cortafuegos* (barrera), *Bot de Pruebas* (salta sobre el grupo más lejano), *Mina Rodante* (explota al caer) y *Agente IA* (charcos tóxicos). Las **auras** (Overclock, Blindaje Redundante, Mantenimiento Continuo, Mando) se activan y apagan al relanzarlas, reservan maná y mejoran a todos tus aliados. El orbe de maná muestra la parte reservada rayada y «reservado X de Y».

**Enemigos**: cada tipo tiene resistencias (`resist`) e inmunidades a estados (`immune`) en `enemies.json`; los élite (y 1 de cada 4 especiales) tiran **afijos** de `enemy_affixes.json` (Ignífugo, Aislado, Criogenizado, Tóxico, Ardiente, Blindado, Veloz, Regenerador, Explosivo, Invocador). El marco del objetivo muestra afijos, resistencias e inmunidades.

**Jefes**: los tres jefes tienen `phases` (umbral de vida, nombre, texto, velocidad, daño, invulnerabilidad breve y onda). La **barra de jefe** (arriba) lleva marco, porcentaje y marcas de fase.

**Mecánicas de arena** (habilidades de jefe en `enemies.json` → `abilities`, con los avisos rojos de los golpes pesados y rayado en modo daltónico): `floor_break` (losas que se agrietan y se rompen: golpe a quien esté encima y un agujero que hace daño al pisarlo; `count`, `radius`, `delay`, `hole_time`, `hole_dps_mult`), `safe_zones` (toda la arena marcada salvo `safe_count` círculos seguros que giran alrededor del centro; al acabar el aviso daña a quien siga fuera; `radius`, `safe_distance`, `safe_radius`, `spin`, `center`) y `channel_adds` (adds que canalizan hacia el jefe con un hilo y un aro de progreso; si no se matan en `channel_time`, el jefe se cura, gana escudo o suelta una nova —`effect`: heal | shield | nova— y vuelven a empezar; aturdirlos o congelarlos los frena). Capturas: `capture_screens.tscn -- arena`.

Cada jefe usa una distinta en cada fase: **El Arquitecto** — Código Legado Frágil (losas), Reunión de Alineamiento (asistentes que lo curan) y Hotfix en Producción (zonas seguras) · **init** — Planificador de Procesos (tres porciones de tiempo que giran), Paginación (losas) y Procesos Zombi (lo protegen) · **fw_update.exe** — Sectores de Respaldo (lo curan), Borrado de Bloques (losas) y Verificación de Sectores (zonas seguras rápidas). Las zonas seguras cubren la arena entera, y su centro se escala con la zona como el jefe.
**Estados sobre el jugador**: los enemigos y algunos afijos (Electrizante, Gélido) te aplican **electrocutado** (recibes +25 % de daño), **helado** (30 % más lento) y **congelado** (no puedes actuar; luego 3 s sin poder volver a congelarte). Su duración baja con la resistencia al rayo (electrocutado) o al frío (helado y congelado). Una barra de **buffs y debuffs** sobre el orbe de vida muestra cada uno con su tiempo (borde rojo = debuff, verde = buff) y una ayuda al pasar el mouse.

**Interacciones entre estados**: *rotura* (golpe físico a un congelado: +50 % y se acaba el hielo), *sobrecarga* (daño de fuego a un electrocutado: explosión en área y se gasta la descarga) e *infección* (veneno + sangrado a la vez: +50 % de daño del veneno).

**Ascendencias** (14, dos por clase; se eligen al nivel 20): cada pareja juega distinto.

| Clase | Ascendencia A | Ascendencia B |
|---|---|---|
| Técnico de Soporte | Ingeniero de Guardia: riesgo, vida baja, sangrado y vida al matar | Especialista en Ciberseguridad: armadura, bloqueo y **espinas** |
| Tester QA | Revisor de Código: críticos y sangrado | Scrum Master: velocidad, enfriamientos y vida al matar |
| Desarrolladora Frontend | Ingeniera de Rendimiento: críticos, proyectiles y **perforación** | Ingeniera de Depuración: veneno, trampas y minas |
| Ingeniera de Prompts | Especialista Red Team: críticos y cadenas | Analista de Malware: caos, veneno y trampas |
| Científico de Datos | Ingeniero de Machine Learning: velocidad de lanzamiento y proyectiles | Analista de Big Data: los tres elementos y sus estados |
| Ingeniero DevOps | Ingeniero en Robótica: torretas y robot de compañía | Ingeniero de Confiabilidad (SRE): **auras** más potentes y baratas |
| Full Stack | Arquitecto de Soluciones: atributos y un poco de cada estado | Líder Técnico: invocaciones, autómatas y enfriamientos |

**Habilidades propias de clase** (una por clase, en una de las dos únicas del fondo de una ascendencia). Se usan solas cuando hay un enemigo cerca, y su daño escala con el nivel **y con tu daño de su tipo**:

| Ascendencia | Habilidad |
|---|---|
| Especialista en Ciberseguridad | **Muro de fuego**: cada 7 s, un muro ardiente entre tú y el enemigo más cercano (3 s) |
| Scrum Master | **Sprint**: cada 10 s, 3 s de +30 % de movimiento y ataque; al acabar, la demo estalla a tu alrededor |
| Ingeniera de Rendimiento | **Disparo perfilado**: cada 5 s, atraviesa todo hasta el enemigo más lejano (más crítico) |
| Especialista Red Team | **Botnet**: cada 4 s, una descarga de caos salta entre hasta 5 enemigos |
| Analista de Big Data | **Pantallazo azul**: cada 9 s, aturde 1 s a los que tienes alrededor (daño de frío) |
| Ingeniero de Confiabilidad (SRE) | **Alerta del pager**: cada 3 s cae un rayo sobre un enemigo cercano |
| Arquitecto de Soluciones | **Despliegue azul-verde**: cada 7 s, una nova de fuego y otra de frío |

**Árbol pasivo 2.0 (versión 8)**: casi el doble que el anterior, unos 1370 nodos en 138 clusters de tamaños y formas distintos (rombos, cadenas, ruedas, estrellas, panales), con 149 notables, 18 maestrías y 11 piedras angulares. Seis regiones de clase en anillos, con el **corazón** de cada clase junto a su inicio (con su notable de estilo) y su piedra angular en el borde; 12 clusters **puerta** entre clases vecinas, un anillo interior alrededor del Full Stack y seis **constelaciones** en el borde exterior. Lo genera `tools/generate_passive_tree.py` (diseño en `docs/arbol_2.md`); cada nodo tiene una clave estable. Los personajes de antes recuperan todos sus puntos de pasiva al cargar, y hasta que cierren el árbol quitar nodos es gratis. Los códigos de build son ``PO2:`` (por la clave de cada nodo); los ``PO1:`` del árbol viejo ya no se cargan.

**Árbol pasivo (versión 7)**: además de las temáticas de siempre, hay siete de estados y aliados: *Ignición*, *Sobrecarga*, *Criogenia*, *Toxinas*, *Hemorragia*, *Automatización* y *Legión* (vida, daño, reserva y auras de los aliados). Cada una tiene entre 3 y 5 clusters y están del lado de las clases que las usan: Automatización y Legión alrededor del Ingeniero DevOps y de las puertas hacia el centro (Full Stack); Hemorragia con el Técnico de Soporte y el Tester QA; Criogenia y Toxinas con la Desarrolladora Frontend y la Ingeniera de Prompts; Ignición y Sobrecarga con el Científico de Datos y el DevOps. Hay nodos de *resistencia a estados*. `tools/generate_passive_tree.py` separa los nodos (tamaño mínimo entre ellos según su radio) y falla si queda alguno encimado o una arista sobre un nodo ajeno. Los personajes guardados recuperan sus puntos de pasiva al cargar.

**Choque térmico**: daño de frío a un enemigo en llamas = +40 % y se apaga la quemadura (junto a rotura, sobrecarga e infección). **Superconductor**: daño de rayo a un enemigo helado = arcos a 2 enemigos cercanos con el 40 % del golpe. Algunas ascendencias suben el «efecto de las interacciones».

**Dónde están los diálogos y la historia**: `data/npcs.json` (personajes y todos sus diálogos), `data/cutscenes.json` (escenas: prólogo, llegadas, final de cada acto), `data/quests.json` (misiones), `data/tutorial.json` (pasos del tutorial) y `data/act1.json`, `act2.json`, `act3.json` (zonas, jefes y sus textos de fase).
- **Ingeniero DevOps (robótica)**: empieza con la **Torreta de Integración Continua** (se despliega sola, sin RAM: `deploy` en `skills.json`, y dispara proyectiles teledirigidos), el **Robot Centinela** y los **Drones de Vigilancia**. Su ascendencia **Ingeniero en Robótica** da +2 torretas/trampas a la vez, +1 esbirro y el **robot de compañía R-2PL** (`CompanionRobot`): te sigue siempre y tiene su propio kit, **Láser de rastreo** (al enemigo más cercano) y **Pulso EMP** (aturde a lo que se te acerque). Las mejoras de esbirros le afectan.

**Habilidades inspiradas en League of Legends** (sencillas de leer y de esquivar):

| Habilidad | Inspirada en | Qué hace |
|---|---|---|
| Despliegue Continuo | Irelia Q / Yasuo E | Embestida hacia el cursor que golpea todo lo que hay en la línea (no atraviesa paredes) |
| Flamewar | Annie W | Cono de fuego delante |
| Rayo de Producción | Lux R | Se carga medio segundo (línea telegrafiada) y dispara un rayo larguísimo |
| Rollback | Sivir Q | El arma va y vuelve, golpeando a la ida y a la vuelta |
| Bucle Infinito | Garen E | Giras golpeando alrededor durante 2,4 s y puedes moverte |
| Deadlock | Amumu R | Onda de frío que aturde (candados sobre los enemigos; los jefes, la mitad) |
| Bomba Lógica | Teemo R | Trampa que explota cuando se acerca un enemigo (hasta 3 a la vez) |
| Excepción en Cadena | Brand R | Rayo que salta de enemigo en enemigo |

| Proceso Hijo | Yorick / Tibbers | Invoca 2 esbirros que pelean solos un rato (escalan con daño de esbirros) |
| Fuga de Memoria | Singed Q / Cassiopeia W | Charco de caos que hace daño degenerativo por segundo |

**Etiquetas**: cada placa base tiene varias (`SkillTags`): ataque o hechizo, forma (cuerpo a cuerpo, proyectil, área, cadena), mecánica (duración, trampa, mina, tótem, esbirro, movimiento, degenerativo) y tipo de daño (físico, fuego, frío, rayo, caos, elemental). Se ven en el tooltip con su color; las RAM las usan para saber con qué funcionan y los modificadores pueden depender de ellas.

**RAM nuevas**:

| Módulo RAM | Gen. | Efecto |
|---|---|---|
| Bypass de Firewall | DDR4 | +3 perforación y proyectiles más rápidos |
| Propagación de Excepciones | DDR5 | +2 encadenamientos; en proyectiles, rebotan hacia otro enemigo al impactar |
| Disparador de Trampa | DDR4 | La habilidad se lanza como trampa y se ejecuta cuando un enemigo se acerca (máx. 3) |
| Detonador de Mina | DDR5 | Se entierra como mina casi invisible: tarda en armarse, más daño (máx. 5) |
| Servidor Torreta | DDR3 | Una torreta usa la habilidad sola contra el enemigo más cercano durante 8 s |
| Contenedor Docker | DDR4 | Un contenedor que no caduca lanza la habilidad solo (−35 % de daño); reserva un 20 % del maná mientras siga en pie, uno por habilidad, relanzarla lo mueve. Cuenta como torreta persistente; se queda en la zona al salir y, si lo destruyen, libera el maná |

Trampa, mina y torreta añaden su etiqueta a la habilidad y no funcionan con movimiento, esbirros ni con otra trampa/mina/torreta (solo cuenta un módulo de despliegue). Al estallar, una trampa o mina **detona en cadena** las armadas que tenga cerca (170 px): cada eslabón espera 0,12 s, se ve un rayo naranja de una a otra y la detonada apunta al enemigo más cercano.

Stats nuevas para ellas: **Recuperación de enfriamientos** (acorta los enfriamientos) y **Duración de habilidades** (giros, trampas y aturdimientos).

## Prólogo / Acto 0: La Beca de Schrödinger

Al crear un personaje (apariencia y nombre; ya no se elige clase en el creador, que muestra el **expediente** del recién egresado) empieza el prólogo (`scenes/prologue/prologue.tscn`), en pixel art de verdad: un escenario de 400×225 escalado sin suavizado, con un shader que lo pinta descolorido por el calor (`prologue_screen.gdshader`).

1. **El Desembarco de la Realidad**: texto mecanografiado (147 vacantes, 5 años de experiencia requerida, café soluble y agua de garrafón) y la Av. del Mar, con la UAdeO (fachada guinda, reja beige) frente al malecón, con camisa formal, marcas de sudor y un portafolio de plástico.
2. **Retorno a la UAdeO**: el pasillo en perspectiva, de sur a norte (se camina de frente con las flechas o click): al fondo la caja de trámites («Regreso en 15 minutos»), a la izquierda la puerta gris de Informática y, junto a la caja, una TV plana que alterna «Ingeniería de Software» y el **Hackatón LinceCode 2026** con su lince en pixel art.
3. **El Error 404 del Archivo Muerto**: el departamento destrozado (archivadores volcados, CRT beige, el minisplit goteando sobre una torre quemada) y Rafa, que busca tu servicio social con `grep`: el Inge Pepe anotaba a los prestadores en una libreta Scribe de gatitos y se la llevó.
4. **El Incidente del Viernes a las 6:00 PM**: se cae el SICE; el backend corre en «El Monolito» (2004). Rafa propone un trato.
5. **La Elección Forzada**: ventana al estilo Windows 98, «Confirmar Contratación de Emergencia», con un desplegable para el **primer puesto (la clase)**. El botón **No** esquiva el ratón sin salir de la ventana (el primer salto, 150 px a la derecha; luego a cualquier hueco) y encoge cada vez; ya diminuto deja de huir, y si se le atina sale `Error 0x80004005` y se convierte en «Pues ya que...», que acepta igual.
6. **Clímax**: Mario llega jalando un carrito con una bolsa de frituras, Aída con él («Profe Rafa, ¿va a querer churr...?»), y la caída se los lleva a todos. Antes: la carpeta lila «NO TOCAR - CONFIG_PROD» detrás del rack, la descarga, la consola roja (`POST /api/v1/deploy/force --user admin`), la oficina pixelándose (papeles en logs, cables en cobre, la ropa en binario) y el título **EL ÚLTIMO COMMIT**. Despiertas en el Sandbox (escena `llegada_sandbox`).

El **pasillo y la oficina** tienen el detalle de la calle (`scripts/prologue/prologue_stage.gd`): aplanado con tramado (más oscuro hacia el fondo del pasillo), baldosas alternas en perspectiva, charcos de luz bajo las lámparas y conos de los fluorescentes, aristas con luz y sombra, la mancha de humedad bajo el minisplit, zócalo y juntas, y sombras al pie de los muebles.

Se camina con las flechas o con click, que fija un destino en el mundo; E, Espacio o click para interactuar. Esc (dos veces) salta a la elección de puesto; en el creador, «Saltar prólogo» va directo a ella.

## Acto I: El Último Commit

El acto está definido en `data/act1.json` y lo construye `Zone` (`scripts/game/zone.gd`).

| Zona | Nivel | Waypoint | Notas |
|---|---|---|---|
| El Sandbox | 1 | | Tutorial: pocos bugs, más botín y B.O.B., el bot de onboarding. Los bugs empiezan al este, lejos de la entrada y de B.O.B. (`keep_away`), y despiertan más cerca (`aggro_range`): primero se habla, luego se pelea |
| Campamento | 1 | ✔ | Zona segura, punto de reaparición; Aída, Mario y Rafa |
| El Bosque de Cables | 2 | | Iris, la practicante perdida |
| Las Ruinas del Monolito | 4 | ✔ | |
| El Pantano de Memory Leaks | 6 | | Tomás, el último QA |
| Las Catacumbas del Legacy | 8 | ✔ | |
| La Granja de Servidores | 10 | ✔ | El Fantasma del DBA (regala una RAM) |
| Sala del Servidor Principal | 12 | | Jefe: **El Arquitecto del Monolito** |

- **Terreno**: los bordes de cada zona son irregulares y temáticos (maleza y árboles de cables en el bosque, acantilados en las ruinas, agua en el pantano, muros en las catacumbas, paredes de racks en la granja, el vacío binario del Sandbox y datos corruptos al rojo en la sala del jefe). Dentro hay accidentes grandes (`features`): lagos, colinas, simas, lagos de datos, agujeros 404 y charcos de lava. Todo tiene colisión y se ve en el minimapa.
- **Zonas que cambian en cada visita** (versión 3.0, diseño en `docs/zonas_3.md`): las zonas de combate se generan al entrar con una semilla nueva (`ZoneLayout`): forma según el estilo (salas y pasillos, cueva, plaza con islas o pasillos de racks), tamaño ±15 % y a veces más larga o más ancha, a veces con un **rodeo** (una cresta que solo se cruza por un extremo), cada salida en su lado pero en otro sitio, waypoint entre la entrada y la salida, y NPC y objetos de misión en rincones propios; todo queda conectado. Cada instancia trae además su **tema** (un tipo de enemigo abunda y otro escasea, más o menos élites), los raros en otro sitio, a veces un **rincón con una caja dorada** con botín mejor, una o dos **salas temáticas** según el estilo (rack caído con cables, cementerio de commits con sus epitafios, sala de backups inundada, altar del practicante, servidor legacy de 1998), con su luz y a veces una caja o una nota de lore, y su tiempo (niebla, lluvia de datos, polvo o un apagón parcial) según el estilo. Los campamentos, las arenas de jefe, los incidentes y el tutorial son siempre iguales. Las marcas propias del mapa grande duran lo que la instancia de la zona. **La instancia se conserva 10 minutos** desde que sales (por una salida, un waypoint o al morir): si vuelves antes, la zona es la misma, con el botín y los tokens que dejaste en el suelo, las cajas que abriste, lo que exploraste del mapa, **los enemigos que quedaban vivos** (con la vida que tenían; los muertos no vuelven) y los eventos como estaban. Se guardan hasta 8 a la vez y solo mientras el juego está abierto; la ventana de waypoints dice cuánto le queda a cada una («como la dejaste 7:32»). **Excepción, la arena del jefe**: si mueres o sales, el jefe vuelve a la fase 1 con toda la vida, aunque lo que cayó al suelo de la arena sigue ahí.
- **Obstáculos** con colisión (árboles, rocas, racks, lápidas…), dejando pasillos libres entre entradas, salidas, waypoint y NPCs; en las zonas generadas se quitan los que cortarían el paso. Los altos (racks, pilares, árboles, lápidas…) se vuelven **translúcidos** si tú o un élite quedáis detrás, y su sombra se estira lejos de la antorcha o la luz más cercana.
- **Niebla en el minimapa y en el mapa grande**: empiezan a oscuras y se descubren al pasar (lo descubierto va con la instancia); las salidas y el waypoint solo aparecen —y solo los señalan las flechas del borde— cuando ya los has visto. El rombo de la mecánica de la zona sí se ve desde el principio.
- **Más allá del borde** (vacío, abismo, agua o lava), un fondo con **parallax** que se mueve más despacio que la cámara: bits sueltos, rocas que se pierden en la profundidad, ondas o brasas.
- **Manchas en el suelo** donde cae cada enemigo, según su material (aceite, restos, glitch, esquirlas); se quedan con la instancia de la zona.
- **Enemigos controlados**: cada zona tiene un número fijo de grupos (`packs`, `pack_size`), repartidos por el mapa con distancia mínima entre ellos y a los puntos clave. No reaparecen hasta volver a entrar. Los enemigos chocan con los obstáculos y no salen del mapa.
- **Salidas** en los bordes ("← Campamento", "Las Ruinas →"): basta con caminar hasta ellas.
- **Rótulo y registro de sucesos** (versión 3.0): al entrar en una zona de combate, su rótulo grande dice también su mecánica principal (◆). A la izquierda, un **registro** plegable (click en su cabecera) guarda lo último que conviene no perderse: botín raro, único y de conjunto, waypoints descubiertos, mecánicas completadas y zonas con botín en el suelo que están a punto de caducar (aviso 1 min antes, también en pantalla).
- **Ventana de waypoints como mapa del acto** (versión 3.0): una pestaña por acto y sus zonas unidas por sus salidas, del campamento a la arena del jefe; cada zona dice su nivel, si tiene waypoint (descubierto o no) y, si la dejaste hace menos de 10 minutos, cuánto le queda y qué mecánica tenía. Las zonas que aún no has pisado salen como «???». Se usa con ratón, mando o toque.
- **Waypoints**: son la única forma de volver a un acto anterior (no hay túneles ni salidas de vuelta entre actos). Se descubren al pasar a menos de ~420 px con el waypoint en pantalla (los de los campamentos, al entrar al campamento) y se guardan por personaje (`flags.waypoints`). Al hacer click se abre la lista del acto.
- **Jefe**: al derrotarlo se completa el acto (bandera `act1_complete`), cae botín especial (siempre en suelo alcanzable) y se abre un portal al campamento.
- **Después del jefe**: el Arquitecto muere en una **escena** (glitch, temblor, sus últimas palabras y la consola del sistema congelándose) y se abre un portal al campamento. Al volver, el campamento culpa al **Inge Pepe**, jefe de informática de toda la vida, recién jubilado (el antecesor de Rafa), y Rafa abre el **puerto 2222** hacia el Kernel. Al cruzarlo se cae **La Red Lince** (pantalla del dinosaurio) y el jugador cae al **Acto II**.
- **Escenas**: `data/cutscenes.json` (líneas con retrato, consola, efectos de glitch, temblor, fundidos y la página sin conexión). Desde la versión 3.0, con **dirección**: bandas de cine, la cámara se acerca con zoom al NPC o al jefe que habla, los personajes caminan y se giran, y el retrato pone la cara de cada línea (contento, enfadado, triste, sorprendido, preocupado). Click, toque, Espacio o la A del mando avanzan; Esc, la B del mando o el botón «Saltar escena» la saltan entera. Los enemigos se congelan mientras duran.
- **NPCs y lore** en `data/npcs.json` (en el campamento: Aída la Senior, Mario el Practicante y Rafa el SysAdmin, que escribe con muchos puntos suspensivos...; sus ids internos siguen siendo `ada`, `kevin` y `root` para no romper los guardados): diálogos con opciones, condiciones (`requires_flag`) y acciones (regalos que se dan una sola vez). Dentro del servidor se ven con el estilo del alumno: `server` dice qué llevan puesto (ranura → base de objeto) y el `gear` de su apariencia, qué objeto llevan en la mano (sprites `prop_*` de `WeaponArt`). Cuentan la historia del administrador que hizo `push --force` "por el Monolito".
- **El campamento evoluciona** al avanzar en la historia (se ve el puesto nuevo en el campamento y se usa hablando con su dueño): tras el Acto I, **el puesto de Aída** (equipo raro y mágico de tu nivel y pociones, expuesto en una mesa con toldo y con sus propias frases, más secas que las de Nacho; Nacho sigue con las placas y la RAM); tras el Acto II, **la mesa de crafteo de Mario** (reforja el arma equipada entera por fichas, o usa **parches** sobre cualquier objeto equipado normal, mágico o raro: *refactor* rehace los afijos no fijados, *feature* añade uno, *versión mayor* sube la rareza de normal a mágico y de mágico a raro, y *hotfix* fija un afijo para que sobreviva al siguiente refactor. Los parches caen de élites (12 %) y únicos (60 %) y Mario los vende; se guardan en `flags.patches`); y tras el Acto III, **la antena de Rafa** (rellena las pociones y da 3 minutos de +15 % de daño y +5 % de velocidad).
- **Tutorial** (`data/tutorial.json`, versión 2): 12 pasos. Empieza en el Sandbox (moverse, atacar, matar, recoger, equipar, pociones, pasivas) y sigue en el campamento (Aída, RAM, Mario, salir al Bosque). Los personajes con el tutorial antiguo continúan donde corresponde.
- **Consejos de primera vez** (`data/tips.json`, `TipPanel`): un aviso corto, arriba en el centro, la primera vez que aparece cada mecánica: la esquiva (al recibir el primer golpe), las cargas, un golpe pesado a la vista, los terrenos y cada mecánica de arena de jefe (losas, zonas seguras, adds que canalizan). Se guardan por personaje (`tip_seen_<id>`) y se apagan en Pausa → Interfaz → «Consejos de mecánicas».

## Acto II: Kernel Panic

`data/act2.json`. El pueblo es **El Socket Seguro** (waypoint y reaparición): Rafa por datos del celular, Clara y El Recolector.

| Zona | Nivel | Waypoint | Lo que hay |
|---|---|---|---|
| La Brecha del 503 | 13 | | Entrada al Kernel, procesos zombi |
| El Socket Seguro | 14 | ✔ | Pueblo del acto |
| La Fábrica de Hilos | 15 | | Pistones; subjefe **Carrera Crítica** (dos gemelos que se turnan la inmunidad: ataca al que le toca); prueba de estrés |
| Las Alcantarillas del Buffer Overflow | 17 | | Registro de auditoría de Clara (revelación); escotilla **cerrada** al Módulo de Refrigeración |
| El Módulo de Refrigeración (opcional) | 18 | | Solo con la **Tarjeta de Acceso al Rack** en la bolsa; Caché en Frío; prueba de estrés de 5 oleadas |
| La Fosa de los Procesos Huérfanos | 19 | ✔ | Sindicato de Huérfanos (PID 404); el Puntero Salvaje (se teletransporta); prueba de estrés |
| La Grieta del Deadlock | 21 | | Dos gigantes de hierro trabados: rompe los 4 **Candados Mutex** para abrir la compuerta; aquí está la Tarjeta de Acceso al Rack |
| El Bus del Sistema | 23 | ✔ | Camino al núcleo |
| El Anillo 0 | 25 | | Jefe: **init (PID 1)** |

- **Camino bloqueado**: la escotilla del Módulo de Refrigeración (Alcantarillas) necesita la Tarjeta de Acceso al Rack, que está más adelante, en la Grieta del Deadlock: hay que volver con ella en la bolsa. Los objetos clave (`KeyItem`) no se pueden tirar.
- **Pruebas de estrés (oleadas)**: al tocar un Banco de Pruebas de Estrés se ve la recompensa concreta (con tooltip) y se puede aceptar. Empiezan las oleadas alrededor del banco (cada una más dura; la última con élites) y, si sobrevives, cae la recompensa mostrada más botín adicional. Si mueres o sales de la zona, se reinicia. Se definen en `challenges` de cada zona.
- **init** tiene tres fases según su vida: *Fork Bomb* (copias frágiles; usa daño de área), *nice -20* (ráfagas de interrupciones: cúbrete tras los disipadores, que bloquean proyectiles) y *OOM Killer* (rayos desde los núcleos a través de ti: si también atraviesan a init, le quitan un 7 % de vida). Al morir, la escena final revela el giro hacia el Acto III.
- **Enemigos nuevos**: Interrupción (IRQ, tres proyectiles), Candado Mutex (inmóvil), Puntero Salvaje (se teletransporta con aviso), Hilo gemelo, Copia de init e init.
- **Misiones secundarias**: El Puntero Salvaje (Rafa), La Petición del Sindicato, Caché en Frío (Clara) y Prueba de Carga (El Recolector).

El lore completo está en [`docs/lore.md`](docs/lore.md).

## Acto III: El Silicio Profundo

Se llega por la **controladora de bus** del Anillo 0 (tras derrotar a init). Datos en `data/act3.json`.

| Zona | Nivel | Qué hay |
|---|---|---|
| La Controladora de Bus | 26 | Llegada (escena `llegada_silicio`): el reflasheo está jalando a más gente de la UAdeO. |
| **El Puerto de Depuración JTAG** (campamento) | 27 | **M. Páez, el Inge** (análisis de datos, álgebra y club de lectura), **Eugenio** (catador de café y pan; nada llega al 10/10), Rafa por el celular, Nacho, alijo y waypoint. |
| La Oblea de Silicio | 28 | Funda del Kindle, una concha, Banco de Pruebas de Estrés. |
| Los Cristales de la ROM | 30 | El Kindle de M. Páez, waypoint y el Centinela del Cargador USB-C (aparece con la misión). |
| La Caché L3 Abandonada | 32 | Un bolillo y una prueba de estrés térmico de 5 oleadas. |
| El Sector de Arranque | 34 | Un cuernito y waypoint. |
| La Cámara de Reflasheo | 36 | Jefe: **fw_update.exe (El Gran Reflasheo)**. |

- **Misiones**: *El Silicio Profundo* (principal), *El Kindle Perdido* y *1 % de Batería* (M. Páez), *Cata de Pan en el Silicio* (Eugenio). Eugenio también rellena las pociones con su café (8/10).
- **Enemigos nuevos** (`enemies.json`):
  - **Rootkit** (`summon`): se queda a distancia e invoca **procesos fantasma** (con tope).
  - **Centinela del BIOS** (`seeker`): orbes **lentos y persistentes** que giran hacia ti durante 7 s; los obstáculos los rompen (cúbrete tras los condensadores).
  - **Gusano de firmware** (`lob_pool`): lanza ácido donde estabas (marcado en el suelo) y deja un **charco** de daño degenerativo de caos.
  - **Arco de electromigración** (`ranged` con `dot`): sus chispas **queman** durante 4 s.
  - **Condensador hinchado** (`slam` con `pool`): revienta y deja un charco eléctrico.
- **Daño degenerativo en el jugador** (`Player.apply_dot`): no se esquiva ni lo reduce la armadura, pero sí la resistencia de su tipo; la misma fuente se renueva, no se acumula. Se ve como burbujas de color sobre la cabeza.
- **Jefe fw_update.exe**: fase 1, orbes perseguidores y procesos fantasma; fase 2, *Borrado de sectores* (charcos) y ráfagas de bloques; fase 3 (99 %), más orbes, rootkits de respaldo y charcos. Al caer, el reflasheo se detiene en el 99 %.
- Suelos propios (silicio, BIOS, ROM, flash), obstáculos nuevos (condensadores y chips) y ambientes.
- `tests/test_core.gd` simula el combate contra cada enemigo nuevo y contra el jefe (`_test_act3_mechanics`).

## Acto IV: El Setup de la BIOS

Diseño en `docs/acto4.md`. Se llega por el **Bus de la BIOS** de la Cámara de Reflasheo (tras detener el reflasheo). Datos en `data/act4.json`.

| Zona | Nivel | Qué hay |
|---|---|---|
| El POST | 38 | Llegada: los pitidos del Power-On Self-Test. |
| **La Pila del CMOS** (campamento) | 39 | **Berta, la Pila CR2032** (recuerda cada ajuste desde 2004 y cuenta lo de admin/admin), **Rafa en persona** (bajó la VPN a mano), **Mario** (vino obligado por su servicio social), M. Páez y Eugenio; alijo, waypoint y túnel al Puerto JTAG. |
| El Menú Advanced | 39 | Aquí el camino **se bifurca**: |
| ↳ La Secuencia de Arranque | 41 | camino A |
| ↳ La ROM de Video Legada | 43 | camino B, en 16 colores |
| El Sector Oculto | 45 | Los dos caminos se juntan; waypoint. |
| El Modo de Gestión del Sistema | 48 | Jefe: **admin/admin, el Usuario por Defecto**. |

- **Jefe admin/admin** (una ventana de login con brazos de cable plano): fase 1 *Contraseña por defecto* (resiste físico y fuego; abanicos de asteriscos y **zonas seguras que giran**: solo los sectores con checksum válido pasan el escaneo), fase 2 *Escalada de privilegios* (resiste frío y rayo; **el suelo se rompe** y procesos de Ring −2 te persiguen) y fase 3 *Persistencia* (resiste caos; tres **Option ROMs canalizan su reinstalación** y hay que matarlas, más Beep Codes y una ráfaga final). Música propia con versión de fase (`boss4`, `boss4_fase`).
- **Escenas**: llegada al POST (`bios_post`), entrada de admin (`admin_entrada`) y el final (`admin_cambia_password`): no se le mata, **se le cambia la contraseña**. El jugador la escribe (paso `input` de las escenas, con validación sarcástica: ni «admin», ni cortas, ni fechas, ni tu nombre) y se guarda en el personaje (`flags.admin_password`) para el Acto V; si salta la escena, queda «admin2». El servidor arranca y en la cola de impresión aparece un archivo del Pepe de 2004.

- **Misiones**: *El Setup de la BIOS* (principal), *La Libreta de Gatitos* (Rafa: la libreta del Pepe, en la ROM de Video), *Orden de Arranque* (M. Páez: los tres andenes), *Ajustes de Fábrica* (Berta) y *Café de Máquina* (Eugenio: por fin un 10/10... de malo).
- **Acompañante**: Mario, M. Páez o Eugenio pueden venir contigo (uno a la vez; se elige y se despide hablando con ellos). Te siguen por las zonas de combate (en el hub se quedan en su sitio) con un bono: Mario +8 % de velocidad de movimiento, Páez +15 % de crítico y Eugenio +6 de regeneración de vida (`Companions`, acción de diálogo `companion`).
- **Recompensas a elegir**: al entregar *Orden de Arranque* (una RAM que encaje o un único al azar) y *Ajustes de Fábrica* (una poción o un objeto muy raro).
- **Decisión sobre los huérfanos del Sindicato**: al entregar la libreta, Rafa pregunta si reiniciar **con** ellos o **sin** ellos. Se guarda (`act4_huerfanos_salvados` o `act4_huerfanos_purgados`) para el Acto V y la misión principal no avanza sin decidir.
- **Estilos nuevos**: `setup` (azul del Setup con opciones y la seleccionada en amarillo) y `vga16` (píxeles gordos de la paleta EGA), con suelo en pixel art, luces y ambientes propios (`tools/generate_sfx.gd -- acto4`).
- **Enemigos nuevos**, cada uno con un **afijo innato** (`innate_affixes` en `enemies.json`; los afijos con `innate_only` no salen al azar en otras élites):
  - **Beep Code** (embestida): *Código de error*, sus pitidos te hielan.
  - **Jumper suelto** (golpe en área): *Puenteado*, salta de pin en pin hasta tu lado.
  - **Pila hinchada** (golpe con charco de caos): *Fuga de ácido*, revienta al morir.
  - **Sector defectuoso** (no se mueve; golpe en área): *Bad block*, devuelve parte del daño.
  - **Option ROM** (invoca Beep Codes): *Legado*, escudo del 40 % de su vida.
  - **Watchdog Timer** (va a por tus invocaciones): *Reinicio*, cura a los enemigos cercanos.

## Misiones

Definidas en `data/quests.json` y gestionadas por `QuestLog` (lógica pura, guardada en el personaje).

**Recompensas propias de las secundarias**: además de puntos de pasiva y objetos al azar, cada una da algo concreto. En los actos I y II, **placas de invocación y auras** (Proceso Hijo, Daemon en Segundo Plano, Aura de Mantenimiento, Robot Centinela, Aura de Mando, Aura de Blindaje, Golem de Hardware); en los III y IV, **RAM de grado mayor** (Guiado Láser, Sobrealimentación, ECC, Multicanal) y el Mainframe Titán. Al aceptar una misión, el aviso dice qué da (`QuestLog.reward_text`).
El **registro de misiones** está debajo del minimapa (L para plegarlo): la principal arriba, en dorado, y las secundarias debajo, con su paso actual y el progreso. Con la interfaz grande, el minimapa y el registro se ocultan mientras una ventana abierta (inventario, hoja de personaje, habilidades, alijo, tienda o waypoints) llegue debajo de ellos; y si el alijo o la tienda no caben junto al inventario, los dos se encogen lo justo para quedar lado a lado (capturas: `capture_screens.tscn -- ventanas160`).

| Misión | Quién | Qué |
|---|---|---|
| El Último Commit (principal) | — | Recorrer el acto, derrotar al Arquitecto, hablar con Aída y con Rafa |
| Kernel Panic (principal) | — | Empieza al acabar la anterior; preparada para el Acto II |
| Bichos en el cableado | Iris (Bosque) | Eliminar 25 enemigos en el Bosque de Cables |
| Reporte de incidencias | Tomás (Pantano) | Eliminar 3 enemigos especiales o élite en el Pantano |
| La cinta de backup | Fantasma del DBA (Granja) | Recoger la cinta en las Catacumbas del Legacy |
| Granos de café | Mario (Campamento) | Eliminar 40 enemigos en cualquier zona |

- Tipos de paso: hablar, llegar a una zona, bandera, eliminar (con zona y rareza mínima), recoger un objeto de misión y entregar.
- Las misiones se aceptan y se entregan en los diálogos (acciones `start_quest` y `quest_advance`). Sobre los NPCs aparece un **!** amarillo si ofrecen misión y un **?** verde si tienes algo que entregarles.
- Recompensas: experiencia y objetos (`give_random` con rareza, RAM que encaja, placas…).
- Los personajes de antes se ponen al día solos: si ya mataron al jefe, la principal salta a "cuéntaselo a Aída".

## Diálogos con voz

- **Narrador**: si el sistema tiene una voz en español (en Windows: *Configuración → Hora e idioma → Voz*), los NPCs leen su texto en voz alta, cada uno con su tono y velocidad (`voice` en `npcs.json`), y el texto avanza al ritmo de la voz.
- **Pitidos retro**: sin voz (o con el narrador desactivado), sale un pitido de 8 bits cada pocas letras, con el tono de cada NPC. El sonido se genera en código (`RetroSfx`), sin archivos.
- **Voces cortas** (`scripts/core/barks.gd`): sin narrador, cada NPC suelta un murmullo sin palabras al empezar a hablar (saludo al principio, que sube si pregunta, «¡ah!» si exclama, «mmm» si duda), con su tono y su género. Tu personaje celebra al subir de nivel y se queja al bajar del 30 % de vida (como mucho cada 25 s), más grave cuanto más ancha su complexión. Se sintetizan al vuelo (pulsos por dos formantes de vocal), sin archivos.
- Los tres se activan o desactivan en el menú de pausa (Esc) y se recuerdan en `user://settings.cfg`.
- **Escenas** (muerte de jefes, transiciones): el texto avanza solo, con una barrita que marca el tiempo de lectura; si hay narrador, lo lee en voz alta y espera a que termine. Click o Espacio adelanta y Esc salta.
- **Llegadas y epílogos**: la primera vez que llegas a cada campamento (Último Commit, Socket Seguro, Puerto JTAG, Pila CMOS) sus NPC te reciben con una escena corta; al vencer a cada jefe (el Arquitecto, init, el reflash, admin) sigue un epílogo breve por radio con la cámara en el portal. Las llegadas no salen si ya completaste ese acto.
- **Conversaciones que fluyen**: volver al inicio muestra una frase corta del NPC (`menu`) en vez de repetir el saludo; en visitas siguientes saluda distinto (`greeting_again`) y los temas ya leídos pueden resumirse (`again`). Las opciones ya leídas salen marcadas con ✓ y al final; las de misiones, con ★ y primero. Los temas largos se encadenan con *Continuar*. Las opciones aparecen cuando termina el texto (click lo completa); teclas 1-9 eligen y Espacio sigue. Lo leído se guarda en el personaje.
- **El narrador nunca corta la voz a media frase**: en Windows, `tts_stop()` con la voz hablando colgaba el juego entero (y el editor); lo detectó `FreezeWatch` (la última acción antes de cada cuelgue era «voz: callar»). Si se adelanta una línea mientras la voz habla, esa línea sale sin voz (con pitidos) y la voz termina su frase.
- El narrador no usa los avisos por palabra de la voz (en Windows pueden trabar el juego): el texto avanza a su ritmo y se consulta si la voz sigue hablando. Solo se corta la voz si de verdad está hablando.
- **Detector de cuelgues** (FreezeWatch): un hilo aparte vigila que el juego avance. Si se para más de 4 s, escribe en user://logs/congelado.log las últimas acciones (diálogos, voz, escenas, viajes). Si el juego se congela, ese archivo dice dónde.

## Efectos y ambiente

- **Formato**: la música, los ambientes y el tema del título van en **OGG Vorbis** (13 MB en vez de 92 MB en WAV); los efectos cortos siguen en WAV. Los generadores escriben `.wav` y `tools/convert_audio.ps1` los convierte (con `ffmpeg`) y borra los WAV. Los bucles siguen en `data/music_loops.json`, en muestras; `Sfx.load_looped` los pasa a segundos. Los sprites ya iban en atlas (`enemies.png`, `items.png`, `passives.png`).
- `tools/generate_sfx.gd` sintetiza todos los sonidos (sin archivos externos): efectos en `assets/audio/sfx/` y un ambiente en bucle por estilo de zona en `assets/audio/ambient/` (fogata en el campamento, ventiladores en los servidores, goteo en las alcantarillas, pistones en la fábrica, latido en las salas de jefe...).
- El autoload `AudioManager` reproduce los efectos (limitados para no saturar cuando mueren muchos enemigos a la vez) y cambia el ambiente con un fundido al viajar. El juego lo usa a través de `Sfx` (`scripts/core/sfx.gd`), que no hace nada si el autoload no está (pruebas).
- Cada habilidad suena según su tipo y su daño (`Sfx.skill_sound`): golpe, proyectil, fuego, frío, rayo, caos, explosión, teletransporte, buff, barrera, invocación o trampa. También suenan las muertes de enemigos, el daño recibido, el botín, las pociones, subir de nivel, los portales y las oleadas.
- **Sonido con más capas** (`SoundMap`): cada habilidad suma a su sonido de tipo una capa de firma y un tono propio, así que dos hechizos de fuego no suenan igual; los proyectiles suenan al impactar; recoger y equipar suenan a metal, tela, cristal o placa; las piezas de conjunto tienen su propia caída; los pasos cambian con el suelo (tierra, piedra, metal), y la interfaz suena al abrir y cerrar ventanas, al pasar por un botón, al comprar y con los errores.
- **Avisos de música**: un golpe de metales al ver un élite, una oleada al ver un jefe, un destello al caer botín bueno y una fanfarria al subir de nivel; la música baja un momento para que se oigan. Al empezar las fases de un jefe, la música cambia justo en un tiempo y sin volver a la intro.
- Cada habilidad **se ve** a su manera (`SkillFx`): destello al lanzar, proyectil con forma propia (paquetes con cabecera, rayo en zigzag, bola de fuego con llamitas, esquirla de hielo, gota de caos), estela de partículas (brasas, escarcha, chispas, gotas, bits) y estallido al golpear. Con **Menos destellos** salen menos partículas y sin núcleos blancos; con muchos enemigos en pantalla, una versión ligera sin estelas.
- **Iconos en pixel art** de habilidades, estados y RAM (atlas de 32 y 16 px en `assets/sprites/icons/`), generados con `tools/generate_pixel_icons.gd` a partir de los glifos (con ventana: `Godot --path . -s res://tools/generate_pixel_icons.gd`). Para usar arte dibujado a mano, sustituye los PNG manteniendo la cuadrícula; sin atlas se vuelve a los glifos de formas.
- **Interfaz con identidad**: títulos de ventana, encabezados y cifras de los orbes con una fuente de píxeles propia (`PixelFont`, en mayúsculas); marcos con remaches y cantoneras; botones que se hunden al pulsar; orbes de vida y maná con burbujas y oleaje. Ningún texto baja de 12 px, para que se lea con la interfaz al 80 %.
- **Obstáculos en pixel art** (`scripts/game/obstacle_art.gd`): los del Acto I (rocas, cajas, monitores, árboles de cables, columnas, escombros, árboles secos, lápidas, racks y rollos de cable) y los de los actos II-IV (pistones, disipadores, barriles, condensadores, chips y bloques de hielo) se pintan en una imagen con píxeles de 2 unidades (la rejilla del filtro), con contorno oscuro y la misma luz que el suelo (arriba a la izquierda) y sombra abajo a la derecha; tres variantes por tipo, en caché. Los LED de los racks y el vástago y el vapor de los pistones siguen animados encima. Solo los charcos (con burbujas) quedan como antes. Se ven en pixel art aunque el filtro esté apagado.
- **Luces, sombras y clima**: además de antorchas, hogueras, portales, golpes y proyectiles elementales, dan luz las **auras** (de su color), las **invocaciones, esbirros y drones** y el **botín único y de conjunto** en el suelo. Los proyectiles (tuyos y de enemigos) proyectan **sombra**. Clima (`scripts/game/weather.gd`): **lluvia de datos** en la terminal, el kernel y los servidores, y **niebla** que deriva en el pantano, las alcantarillas y la fosa. En Pausa → Interfaz, **Luces y clima: reducidos** quita las luces de golpes y proyectiles, deja como mucho 10 luces y apaga el clima.
- **Golpes por material**: cada tipo de enemigo dice en `enemies.json` de qué está hecho (`material`: `flesh`, `metal`, `crystal` o `digital`) y así suena al golpearlo (bugs y gusanos a carne, daemons y condensadores a metal, la electromigración y las Option ROM a cristal, procesos e hilos a digital).
- **Ambiente posicional** (`scripts/game/ambient_emitters.gd`): además del ambiente de la zona, fuentes que solo se oyen de cerca (hasta 560 px): **zumbido** junto a los racks, **goteo** en charcos, lagos y alcantarillas y **viento** en grietas y acantilados. En los servidores, las alcantarillas y la Grieta suenan aunque no haya obstáculos de ese tipo. Sus sonidos son `assets/audio/ambient/emit_*.wav` (`generate_sfx.gd -- posicional`) y siguen el volumen del ambiente.
- "Efectos de sonido" y "Sonido ambiente" se activan o desactivan en el menú de pausa. Para usar sonidos propios basta con sustituir el WAV del mismo nombre.

## Pantalla de título, menú y creador

- **Pantalla de título** (`scenes/menu/title_screen.tscn`, escena principal): logo animado de *Path Overflow* (`GameLogo`) con efecto glitch y una pila desbordándose, lluvia de binario, `console.log`s flotando, un grafo de git que termina en `push --force`, bugs cruzando, un rack de servidores echando vapor y un café. Se continúa con cualquier tecla, un clic o, en el celular, tocando la pantalla («toca la pantalla para continuar»). Si hay personajes, **«▶ Continuar»** (dorado, encima) entra de un toque con el último jugado, donde lo dejaste, y al entrar se ve unos segundos el **objetivo** (la misión principal y su paso o, sin misiones, «limpia esta zona (0/N)»), para partidas cortas.
- **Música**: `assets/audio/title_theme.wav`, generada con `tools/generate_music.gd` (bucle de ~37 s). El autoload `MusicPlayer` la mantiene sonando entre título, menú y creador; el botón "Música" la silencia y se recuerda en `user://settings.cfg`. Para usar otra música basta con sustituir el WAV.
- **Música de zonas y jefes**: `data/music.json` define 12 pistas (campamento, exploración, zonas oscuras/frías y jefe de cada acto) y qué pista suena en cada zona; `tools/generate_zone_music.gd` las compone en `assets/audio/music/<id>.wav` (mono 16 kHz, bucle sin costura; `-- id1 id2` para regenerar solo algunas). `MusicPlayer.play_zone()` hace fundido cruzado al cambiar de zona, y cada fase de jefe sube el tempo un 4 %. El campamento del acto III (`camp3`) es un instrumental lento de piano y pad con batería suave, de aire melancólico. Para sustituir una pista basta con reemplazar su WAV. El volumen de música, voz y su velocidad se cambian en el menú de pausa.
- **Voces**: cada NPC de `data/npcs.json` tiene en `voice` su `pitch`, `rate`, `gender` (male/female/neutral) y `volume` opcional; el proceso aparte del narrador (`NarratorVoice`) los recibe junto con los ajustes del jugador.
- **Creador de personaje**: barras de atributos, estilo de juego, dificultad, arma, ascendencias y las placas base iniciales con su icono y descripción. Vista previa animada sobre un pedestal del color de la clase y un retrato de cerca. Esos datos están en `classes.json` (`playstyle`, `difficulty`, `color`).
- **Apariencia**: complexión, estatura (baja, media, alta), 10 peinados (rapado, corto, largo, cresta, moño, hacia atrás, afro, coleta, rapado lateral, melena con flequillo), barba (tres días, completa, bigote, candado), accesorio (lentes, lentes de sol, audífonos, gorra, gorro de lana) y colores de piel, pelo, ojos, atuendo y detalles (cinturón, zapatos y accesorio). Todo sale de `CharacterAppearance`: la misma cabeza (`draw_head`) se usa en el mundo, en los retratos y en el creador, así que lo que eliges es lo que ves. Los personajes de antes reciben valores por defecto.
- **Lista de personajes**: cada tarjeta con un medallón animado y la franja del color de su clase.

## Interfaz

- **Escenarios con tilesets**: cada estilo de zona tiene su tileset en `assets/sprites/tiles/` (suelo con variantes que encajan sin costuras y una banda para el borde del camino), generado con `tools/generate_tilesets.gd`; si se sustituyen los PNG por arte a mano con la misma cuadrícula, el juego usa el arte. El agua del borde tiene ondas animadas.
- **Botín en el suelo**: cada objeto muestra su icono con sombra y el brillo de su rareza, y al caer vuela en arco y rebota antes de que salga su etiqueta. En las zonas de combate hay **cajas de servidor** que se abren al acercarte y sueltan 1-3 objetos y unos tokens.
- **Personaje por capas**: el jugador (en el mundo, el creador y la lista de personajes) se dibuja con hojas de sprites por capas —cuerpo, pelo, barba, accesorio y arma, en 4 direcciones y con los estados de reposo, andar, tajo, estocada, disparo, hechizo, canalizar, golpe, esquiva y muerte— teñidas con los colores del creador. Se hornean desde el dibujo de siempre con `tools/bake_player_sprites.gd` (sin `--headless`); la cuadrícula está en `PlayerSheet` por si se sustituyen por arte a mano. Los retratos siguen dibujados (tienen expresiones). Los NPC usan el mismo personaje por capas: respiran y gesticulan mientras hablas con ellos. La primera vez que ves a un jefe, una franja con su figura y su nombre cruza la pantalla.
- **Animación de enemigos**: cada tipo tiene cuadros de andar, atacar (se echa atrás y embiste), recibir golpe y morir (se desploma), mirando abajo, arriba o de lado; el cuadro sale de lo que está haciendo. Hoja en `assets/sprites/enemies/enemies.png` (cuadrícula en `EnemySheet`, generada con `tools/generate_enemy_sprites.gd`; se puede sustituir por arte a mano con la misma cuadrícula). Desde la 3.6 los cuadros miden 64 px, como los personajes: curvas finas, luz arriba y sombra abajo en cada parte y contorno de 2 px; la hoja va en bloques de 48 filas para no pasar de 4096 px.
- **Efectos con temática de datos** (3.6): al morir, cada enemigo deja un anillo de nodos de red que se apagan y el glifo de su familia (digital «{ }», metal «#», cristal «<>», carne «;»); los golpes fuertes sueltan corchetes y el botín raro, bits entre corchetes de su color. Los colores siguen siendo los del tipo de daño (y los del modo daltónico); con «Efectos de pantalla» apagado no aparecen.
- **Ambiente de las zonas**: la lluvia de datos salpica en el suelo, hay polvo en suspensión en ruinas, catacumbas y fábricas, cables sueltos que chisporrotean en las zonas de servidores, LEDs que parpadean en los racks del borde y luces de la zona que se avivan con los golpes cercanos («Luces y clima reducidos» lo apaga).
- **Estados y avisos**: llamas que suben, burbujas de veneno que revientan y gotas de sangrado sobre enemigos y jugador, escarcha que crece al helarte; los avisos de ataque en el suelo tienen un borde de trazos que gira, ondas que se cierran hacia donde cae el golpe y flechas que marcan la dirección de conos y cargas.
- **Calidad gráfica** (Pausa → baja, media, alta): cuántas luces hay a la vez, ráfagas de partículas de GPU en explosiones y novas, bloom alrededor de las luces, distorsión de calor sobre el fuego (alta) y ondas de choque en los golpes grandes (media y alta). **En el celular** usa el renderizador `gl_compatibility` (OpenGL ES 3; desde la 3.2.1: con `mobile`, Vulkan, la interfaz parpadeaba en algunos teléfonos), va siempre en horizontal y, mientras no elijas otra cosa, empieza en calidad media con la interfaz al 140 %; ahí las luces dinámicas no pasan de 12 en ninguna calidad.
- **Animación**: números de daño sobre los enemigos (los críticos, grandes y amarillos; los golpes seguidos se suman en una sola cifra), ventanas que entran con un zoom corto, botones que rebotan, tooltips de objeto con fundido y la barra de experiencia que brilla al subir de nivel. En Pausa → Interfaz: «Números de daño» y «Reducir movimiento» (sin rebotes ni zoom; las cifras solo suben).
- **Pantallas**: el título tiene una ciudad de servidores que se desplaza y un brillo detrás del logo; en la lista de personajes, el elegido posa sobre un pedestal del color de su clase; al viajar entre zonas sale una **pantalla de carga** con una postal de la zona, su nombre y un consejo (`data/loading_tips.json`); y del título al menú y del menú al juego hay un **barrido de píxeles**.
- **Tema dibujado** (`assets/sprites/ui/ui_atlas.png`, generado con `tools/generate_ui_atlas.gd`; cuadrícula y piezas en `UiAtlas`): marcos de ventana, botones (normal, encima, pulsado, desactivado), casillas de objeto con el marco de su rareza, pestañas, barras, separador, tooltips y campos de texto de 9 partes con acabado suave (degradados, esquinas redondeadas y bordes suavizados, filtrado en lineal aunque el mundo sea pixel art); títulos y cifras de los orbes con la fuente normal y contorno, y en el HUD la placa de bronce de la barra, los aros dorados de los orbes y los marcos de pociones, habilidades y experiencia. Para arte hecho a mano, sustituye el PNG con la misma cuadrícula (celdas de 48 px, bordes de 12 px); sin el PNG se usan las cajas planas de antes.
- **Recuadros de lo activo** (sobre la barra de habilidades): esbirros, torretas, trampas, minas, giros y pociones de utilidad, con cuántos hay y el tiempo que les queda.
- **Inventario y Habilidades** con marco de ventana (esquinas doradas, cabecera, botón de cerrar), siluetas en las ranuras vacías, zócalos DIMM y tarjetas de habilidad con nivel, experiencia y etiquetas.
- **HUD**: orbes de vida/ES y maná, café y bebida energética con cargas (vapor y burbujas cuando están listas), barra de 6 habilidades con enfriamiento y coste, experiencia y botones de menú (C, I, K, P).
- **Minimapa** (arriba a la derecha): el suelo de la zona, obstáculos, salidas, waypoint, NPCs, enemigos por rareza y botín valioso, con flechas hacia las salidas que quedan fuera de vista. Debajo, el nombre y nivel de la zona. Se oculta mientras el inventario está abierto.
- **Hoja de personaje** (C): medallón redondo animado (`CharacterPortrait`) que respira, parpadea, te sigue con la mirada, toma café, piensa (con spinner de carga), bosteza, se pone lentes de sol si su DPS es alto y suda con poca vida; el aro es del color de la clase. Barra de experiencia y tarjetas con barras que se llenan: atributos, resistencias (con el tope de 75 %), defensa (vida, escudo, maná, armadura y evasión con su efecto real, bloqueo) y ofensiva (icono de la habilidad principal, DPS grande, daño, crítico, usos por segundo). Si hay pasivas sin gastar, un botón abre el árbol.
- **Retratos**: los diálogos y las escenas usan el mismo medallón, con la boca moviéndose mientras el NPC habla; Rafa y Clara por radio salen con interferencia verde.
- **Iconos de objetos**: atlas `assets/sprites/items/items.png` generado con `tools/generate_item_icons.gd` (un icono por base, placas base, RAM por generación y pociones). Para usar arte propio, sustituye el PNG respetando la cuadrícula (mapa en `data/item_icons.json`).

## Mando

En el mundo (`scripts/core/gamepad.gd`): stick izquierdo para moverse, derecho para apuntar, A/B/X/Y y LB/RB para las 6 habilidades, cruceta y gatillo izquierdo para las pociones, gatillo derecho para esquivar, Back para el inventario, clic del stick izquierdo para K, Start para la pausa.

**Pausa → Controles** (`scripts/core/controls.gd`): cada acción (moverse, las 6 habilidades, las pociones, esquivar, abrir ventanas, fijar la comparación...) muestra su tecla y su botón del mando; un clic en cualquiera espera la nueva (Esc cancela). Si ya la usaba otra acción, se intercambian. El movimiento con mando sigue en el stick. Se guarda en `user://settings.cfg` y la barra de habilidades y el menú K muestran las teclas nuevas. Hay un botón para restaurar los de fábrica.

**En las ventanas** (inventario, habilidades K, hoja de personaje, tienda, alijo y la elección de habilidad) aparece un **cursor libre** (`scripts/ui/gamepad_cursor.gd`): el stick izquierdo lo mueve, **A** es clic izquierdo (mantener y mover = arrastrar), **X** clic derecho, la **cruceta** salta a la casilla o botón más cercano en esa dirección, **LB/RB** cambian de ventana y **B** cierra como Esc. Mientras está activo, el personaje no se mueve ni lanza nada; al abrir otra ventana el cursor salta a ella. También funciona en el **árbol pasivo** (la cruceta salta entre los nodos que se ven, el stick derecho hace zoom como la rueda y A mantenida arrastra para mover el árbol) y en los **diálogos**. **Y** (o **F** en el teclado) **fija la comparación** del objeto: deja una copia quieta en pantalla para mover el cursor y compararlo con calma; otra vez la suelta, y se quita sola al cerrar las ventanas. Un anillo con los dos anillos puestos se compara **contra cada uno** (dos secciones y los dos equipados al lado).

## Filtro de botín

**Pausa → Filtro de botín** (`scripts/items/loot_filter.gd`): rareza mínima por categoría (armas, armaduras, joyería, chips), mostrar u ocultar placas, RAM y pociones, desde qué rareza sale el haz de luz y atajos (Ver todo, Equilibrado, Estricto, Fin de juego). Reglas finas:
- **Nivel de objeto mínimo**: esconde el equipo de nivel menor.
- **Bases buenas** y **afijos buscados**: el equipo con esa base o con ese afijo se ve siempre, con **marco dorado, estrella y haz de luz**, aunque su rareza no pase.
- **Filtros con nombre**: guarda el filtro actual con un nombre y cárgalo o bórralo cuando quieras (p. ej. uno para subir de nivel y otro para el atlas). Los atajos cambian las rarezas y respetan las reglas finas.

Los únicos, los de conjunto y los objetos clave se ven siempre; Shift muestra lo oculto atenuado.

## Accesibilidad

En **Pausa → Interfaz** (`scripts/core/accessibility.gd`):
- **Menos destellos**: atenúa los fogonazos de los enemigos (golpes a jefes, cambios de fase), la luz de los impactos y los glitches de las escenas y de la absorción del prólogo, y deja fijo lo que parpadea (estados por acabarse, trampas armadas).
- **Texto del mundo** (80-150 %): nombres de enemigos, PNJ y compañero, etiquetas del botín y avisos como *git stash*, aparte del tamaño de la interfaz.
- **Auto-ataque** (Pausa → Combate): sin pulsar nada ni moverte, la habilidad 1 sale sola contra el enemigo más cercano (a 320 px). No vale para auras, invocaciones, canalizadas ni habilidades de activación.
- **Moverse con el ratón** (Pausa → Combate): *mantener* (seguir al cursor con el clic pulsado, como siempre), *alternar* (un clic empieza a seguirlo y otro para, sin mantener el botón) o *clic para ir* (como mantener, y al soltar caminas hasta ese punto). El teclado o el stick cancelan el modo alternar.
- **Modo daltónico**: además de los estados alterados y la chapita de rareza del botín, cambia las **auras** (un color Okabe-Ito por tipo de daño) y las **cargas** (bermellón, amarillo y celeste, distintos también en brillo).

## Pociones

Las pociones son **objetos**: caen como botín (las de nivel cercano al de la zona son más probables) y se llevan en el **cinturón de pociones** (5 ranuras, teclas 1-5; en el inventario, I). Cada una tiene **cargas**: cada uso gasta unas (por ejemplo, 6 de 30) y matar enemigos las recarga (más con élites y jefes). Mario las rellena todas.

| Tipo | Pociones (nivel) |
|---|---|
| Vida (cafés) | Café de máquina (1), Americano (5), Espresso (10, rapidísimo), Latte (15), Capuchino (20), Cold Brew (26, lento pero enorme), Café de moka (33), Café de especialidad (40) |
| Maná (bebidas) | Pepsy (1), Coca Cero (6), Vive 101 (11), Monstruo Energy (17), Toro Rojo (23), Refresco de 2 litros (30), Yerba Turbo (38) |
| Utilidad (efecto temporal) | Agua con gas (movimiento), Té matcha (evasión), Batido de proteínas (armadura y daño físico), Infusión de jengibre (resistencias), Bebida isotónica (velocidad de ataque y lanzamiento), Chocolate caliente (regeneración), Kombucha (resistencia al caos y crítico) |

Las bebidas son parodias de marcas reales (nombres y latas inventados). Cada poción tiene su sprite. Se definen en `data/items/flasks.json`; los personajes antiguos reciben el Café de máquina y la Pepsy al cargar.

## Clases: tu primer trabajo

El personaje es un recién egresado que se enfrenta al mundo laboral: cada clase es un puesto de entrada y sus ascendencias, los caminos de carrera que salen de él.

| Clase | Atributos | Ascendencias (carreras) |
|---|---|---|
| Técnico de Soporte | FUE | Ingeniero de Guardia, Especialista en Ciberseguridad |
| Tester QA | FUE/DES | Revisor de Código, Scrum Master |
| Desarrolladora Frontend | DES | Ingeniera de Rendimiento, Ingeniera de Depuración |
| Ingeniera de Prompts | DES/INT | Especialista Red Team, Analista de Malware |
| Científico de Datos | INT | Ingeniero de Machine Learning, Analista de Big Data |
| Ingeniero DevOps | INT/FUE | Ingeniero en Robótica, Ingeniero de Confiabilidad (SRE) |
| Desarrollador Full Stack | las tres | Arquitecto de Soluciones, Líder Técnico (Tech Lead) |

(Los ids internos siguen siendo los de antes —`guerrero`, `duelista`...— para no romper los guardados.)

**Ascendencia al nivel 20**: junto al inicio de tu clase en el árbol hay un **medallón**. Al pulsarlo se abre un panel circular: hasta el nivel 20 solo se pueden ver las dos opciones; a partir de ahí se elige una (permanente). Después, el panel muestra el inicio de la ascendencia y sus pasivas alrededor: cada una cuesta un **punto de ascendencia** (1 al nivel 20, +1 a los 25 y 30). En la pantalla de pruebas del árbol se puede cambiar libremente.

## Dificultades

**Normal**, **Pesadilla** e **Infierno** (`Difficulty`, `flags.difficulty`). Pesadilla se abre al terminar el Acto IV e Infierno al terminarlo en Pesadilla; se cambian hablando con Rafa en el campamento. En Pesadilla las zonas de combate suben 12 niveles, los enemigos tienen +20 % a todas las resistencias, los élites un afijo más y los especiales el doble de probabilidad de tener uno, y cae un 30 % más de botín; en Infierno, +24 niveles, +40 %, dos afijos más y +60 %. Los jefes se pueden volver a pelear en cada dificultad (su bandera de completado lleva `_d1` o `_d2`).

**Zonas completadas a tu nivel** (opción en Pausa, por personaje: `flags.zone_scaling`): las zonas de combate de los actos ya terminados suben a tu nivel si estás por encima, para volver a ellas sin que se queden cortas. Se suma con la dificultad (`Difficulty.zone_level`); los campamentos no cambian.

## Atlas de incidentes

En el puesto de Aída (campamento, tras el Acto I) se pide un **incidente**: una zona de combate al azar que ya puedes jugar, a tu nivel, con 2 o 3 modificadores que la ponen difícil a cambio de **más botín** (cada uno suma): *Pico de tráfico* (+50 % de grupos), *Procesos zombi* (todos explotan al morir), *Hilos desbocados* (todos veloces), *Firewall mal configurado* (todos blindados), *Escalada de privilegios* (el doble de élites), *Fuga de memoria* (no regeneras vida) y *Configuración por defecto* (−20 a tus resistencias). Se vuelve por un portal al campamento. La zona se arma al vuelo (`Incidents`) y no se guarda: si sales del juego dentro, vuelves al campamento.

- **Completar un incidente** (limpiar la zona) lo marca en el **atlas**, suelta tres objetos y un **mapa**. Cada tres zonas distintas completadas sube el **nivel del atlas** (hasta 10): los incidentes salen 2 niveles más altos y con un 10 % más de botín por nivel.
- **Mapas**: incidentes guardados (zona + modificadores; tres modificadores desde el nivel 3 del atlas). Caen al completar incidentes y, un 15 % de las veces, de los élites de dentro. Caben 12.
- **Pantalla del atlas** (puesto de Aída → «Abre el atlas»): nivel y lo que falta para el siguiente, zonas completadas por acto, tus mapas con su botón «Abrir» y el incidente al azar (`Atlas`, `AtlasPanel`; se guarda en `flags.atlas`).

## Lore coleccionable

Por las zonas de los cuatro actos hay **commits perdidos, logs y correos de la UAdeO** (`data/lore_notes.json`, 18 por ahora) que brillan en el suelo y se recogen al pasar cerca. Cuentan pedacitos de la historia: el `monolito.log` con la contraseña por defecto, el cron de las 3:33, el único commit sin descripción, el club de lectura de los jueves, el commit con hash de pez... Se leen en **Pausa → Archivos encontrados** (lista a la izquierda, texto a la derecha) y se guardan con el personaje (`flags.lore_found`). Su posición va como fracción del tamaño de la zona, así que no le afecta la escala.

## Logros y cosméticos

Hay **10 logros** (`scripts/game/achievements.gd`): tu primer enemigo, cada jefe de acto, 1000 enemigos, vengarte de tu némesis, 9 archivos de lore, el atlas a nivel 3 y terminar el Acto IV en Pesadilla. Cada uno regala un **cosmético** que no da stats: sombreros (gorra del hackatón, casco de obra, sombrero de pescador, corona de admin), auras (dorada, silicio, morada) y pisadas que se quedan un momento en el suelo (bits, llamas, glitch). Se revisan al eliminar enemigos y al cambiar de zona; se ven y se equipan en **Pausa → Logros y cosméticos** y se guardan con el personaje.

## Banco de oleadas y récords

Desde el **puesto de Aída** (tras el Acto I) se abre el **banco de oleadas sin fin** (`scripts/game/ladder.gd`): una zona que ya conoces, vacía, donde llegan oleadas cada vez más grandes y fuertes (más especiales y élites, +1 nivel de área cada 5) con un **jefe de oleada** cada 5, que deja botín. Dura hasta que caes o sales por el portal. Se anotan tus récords (más oleadas, luego menos tiempo) y tu **mejor tiempo contra cada jefe de acto** (desde que entras a su zona). Además hay una **tabla local** con el top 10 de todos los personajes de este equipo (`user://ladder.json`). Se ve en **Pausa → Récords** o con Aída.

Las **pruebas de estrés** y el banco de oleadas tienen su música, **Prueba de carga** (`estres` en `data/music.json`, 138 BPM, con capa de combate): entra al empezar y, al acabar, perder o salir, vuelve la de la zona.

## Deuda técnica (fin de juego)

Al terminar el Acto IV se abre el **árbol de deuda técnica** (`scripts/character/tech_debt.gd`, **Pausa → Deuda técnica**): una raíz (*Commit directo a main*) y tres ramas de cuatro nodos — **Hotfix** (daño), **Legacy** (aguante) y **Deadline** (velocidad). Cada nodo da un **bono fuerte y una penalización** (p. ej. *Reescribirlo desde cero*: 25 % más de daño y 20 % menos de vida). Puntos: 1 al abrirlo + el nivel del atlas + 1 por cada 5 oleadas de tu récord del banco (hasta 5). Quitar un nodo es gratis (pagar la deuda), pero de las hojas a la raíz. Se guarda con el personaje.

## Eventos de zona

**Mecánicas de zona** (versión 3.0, `data/zone_mechanics.json`, `ZoneMechanics`): cada instancia de una zona de combate trae **una mecánica principal** —se anuncia al entrar con su nombre y una frase, sale en el minimapa con un rombo dorado y, al completarla, da botín extra; ignorarla no tiene castigo— y como mucho **un evento menor**, para no saturar la zona. Principales: **Bombas lógicas**, **Proceso perdido**, **Deploy fallido**, **Garbage Collector** (tras una línea turquesa de aviso, un barrido cruza la zona de lado a lado y daña a todo lo que pilla, enemigos incluidos; cinco pasadas), **Apagón del CPD** (la zona casi a oscuras; pasa junto a las luces de emergencia de piloto rojo para encenderlas) **Ticket urgente** (en su consola se abre un P1: élites marcados por la zona que hay que tumbar en 2 minutos), **Merge conflict** (los enemigos van en dos ramas, aro rojo HEAD y verde main, y se pegan entre ellos si se cruzan lejos de ti; 12 bajas entre ramas lo resuelven), **Deploy de viernes** (oleadas que entran por las salidas cada 24 s, hasta seis, hasta que te quedas 3 s en el terminal del pipeline) y **Caché caliente** (baldosas que dan 6 s de daño, velocidad o armadura al pisarlas, se enfrían y se mueven; ocho usos la completan) —al azar según estilo, acto y nivel, con pesos parecidos para que ninguna domine— y, en sus zonas, el **Mutex** y la **Carrera Crítica** mientras no se hayan superado. Menores: Datos huérfanos, Santuarios, Emboscadas y el Comerciante ambulante. El tutorial no tiene mecánicas.

Los eventos (`scripts/game/zone_events.gd`): **Datos huérfanos** (dos oleadas y botín), **Santuarios** (bono temporal o cargas llenas), **Emboscadas** (invisibles) y **Deploy fallido** (dos raros con escolta). Nuevos:

- **Bombas lógicas**: al tocar la consola aparecen tres bombas con una cuenta atrás de 25 s y una oleada. Quédate 1,5 s junto a cada una para desactivarla; las que queden estallan y hacen mucho daño cerca. Bien: tres objetos y fichas; mal: uno.
- **Proceso perdido** (escolta): un fantasmita con su PID camina hasta su salida, pero solo si estás cerca y no hay enemigos a su lado. A un tercio y a dos tercios del camino, emboscada. Al llegar: tres objetos y fichas.
- **Comerciante ambulante**: un objeto misterioso de buena rareza por fichas (el precio sube con el nivel de la zona). «Sin devoluciones».

## Enemigos

**Roles en las manadas** (desde el nivel 2): *Guardián* (protege a los de alrededor), *Sanador* (cura a los heridos; lleva halo verde y brazalete con la cruz), *Francotirador* (tiro fuerte avisado; visor rojo y rifle que apunta hacia ti, con láser mientras carga) y *Enjambre*. Una de cada tres veces el rol va a la **élite** que encabeza la manada, y se ve en su nombre («Bug corrupto (Sanador)»). Afijo de élite **Comandante** (desde el nivel 9): los enemigos en su aro dorado pegan un 25 % más y se mueven un 15 % más rápido.

**Némesis**: si te mata un élite (un golpe suyo en los últimos 4 s, también a distancia), se vuelve tu némesis. Reaparece seguro en la zona donde te mató y, a veces, en las demás zonas de combate del acto, con tu nombre («Veloz Bug corrupto, Azote de Ana»), sus mismos afijos, el doble y medio de vida y más daño. Si te vuelve a matar, sube de nivel (×2, ×3...). Al vencerlo suelta cuatro objetos de buena rareza y un montón de fichas, y se olvida (`flags.nemesis`).

**Reaccionan a su estado** (salvo jefes y únicos), con una marca sobre la cabeza: quemados, la mitad de las veces **entran en pánico** y huyen 1,6 s («!»); con menos del 35 % de vida **van hacia el sanador** más cercano («+»); y si no están peleando **se reagrupan** dentro del aro de un comandante («»»).

Nueve tipos con sprites animados (`data/enemies.json`, `assets/sprites/enemies/enemies.png`). Los nuevos tienen ataques **telegrafiados en rojo** (se ve la forma del golpe antes de que llegue) y cuerpos de distinto tamaño:

| Enemigo | Ataque | Forma del golpe |
|---|---|---|
| Bug, Proceso zombi, Memory leak, Gusano | Cuerpo a cuerpo | Contacto |
| Bot de spam | A distancia: dispara correos y mantiene la distancia | Proyectil esquivable |
| Hilo desbocado | Embestida | Rectángulo en línea recta (se para al chocar) |
| node_modules | Golpe pesado, cuerpo enorme y lento | Círculo alrededor |
| Troll de foro | Teclado en llamas | Cono delante |
| Daemon | Solo jefes | — |

**Peso de los golpes**: antes de atacar, el enemigo se encoge, se echa hacia atrás y destella en blanco justo antes del golpe; con un crítico da un respingo y sale despedido más lejos. Al morir, según el daño: se rompe en hielo, se quema a ceniza, salta en chispas, se disuelve o, si es físico, según de qué está hecho (chatarra con chispas, añicos de cristal, gotas o bits). Los que no se quemaron, congelaron ni hicieron añicos dejan el **cuerpo** tumbado unos segundos antes de desvanecerse.

**Jefe del acto (El Arquitecto del Monolito)**: menos vida que antes (×2,6 en vez de ×4) y dos habilidades, con el nombre en grande y una barra de lanzamiento:
- *git push --force*: onda de 14 proyectiles en todas direcciones (hay huecos entre ellos).
- *Merge Conflict*: cinco círculos en el suelo, uno donde estás, que explotan al segundo.
- Por debajo de la mitad de vida se recargan un 40 % más rápido.
- El atlas se genera con `tools/generate_enemy_sprites.gd` (pixel art procedural, "arte de programador"). Para usar sprites dibujados a mano, sustituye el PNG respetando la cuadrícula: columnas = 4 fotogramas, filas = tipos.
- Un shader (`assets/shaders/enemy_sprite.gdshader`) se encarga de la animación, el volteo, el contorno del color de rareza y el destello al recibir daño, todo por instancia del `MultiMesh`.

## Tokens, comerciante y alijo

- **Tokens** (Economy): la moneda. Los enemigos normales los sueltan 2 de cada 5 veces (los especiales, élites y únicos más y en más cantidad, según el nivel de la zona). Se recogen solos al pasar cerca: a ~90 px van a la cuenta y desde ~380 px vuelan hacia ti (rodean las paredes, no las atraviesan). El stat **Radio de recogida de tokens** (afijo de anillos y amuletos, y algunos nodos menores de movilidad del árbol) agranda los dos radios, hasta +100 %. Se ven en el inventario (I).
- **Gestión del inventario**: «Ordenar» compacta la bolsa (equipo por ranura y rareza, luego pociones, placas y RAM; la basura al final). Click derecho en un objeto de la bolsa lo marca como **basura** (papelera) o lo **bloquea** (candado: no se vende ni se tira); Nacho compra toda la basura de una vez. Con **Alt** pulsada, cualquier tooltip de equipo se compara con lo que llevas puesto. Las **placas** se comparan con la de su misma habilidad en tu barra (al lado, y abajo DPS, coste, usos/s, área, enfriamiento, nivel y ranuras en verde si mejora o en rojo si empeora) y las **RAM** dicen cuánto DPS daría cada placa de tu barra que las admita.
- **Alijo con pestañas y búsqueda**: cinco pestañas a las que se les cambia el nombre y el color («Editar pestaña»), una de **materiales** para los chips de expansión (con tus parches a la vista), y una búsqueda por texto (nombre, base o afijo) que resalta lo que coincide y dice cuántos hay en cada pestaña.
- **Hoja de personaje con desglose** (C): al pasar el ratón por cada estadística se ve de dónde sale (base, clase, atributos, árbol, objetos, conjuntos, auras, cargas…) con sus planos, aumentos y multiplicadores; las resistencias dicen cuánto falta o sobra para el tope, y la tarjeta de ofensiva da el DPS de cada habilidad de la barra.
- **Ventanas ordenadas**: a la izquierda va una sola ventana (tienda, alijo, habilidades, personaje o waypoints) y a la derecha el inventario; si no caben las dos, la de la izquierda se encoge. El alijo abre por la última pestaña y la tienda y la bolsa de habilidades con el último filtro.
- **Planificador del árbol** (P): «Modo plan» marca nodos sin gastar puntos y enseña el camino en cian; «Aplicar plan» los asigna hasta donde lleguen los puntos. Deshacer y rehacer con Ctrl+Z / Ctrl+Y. En partida, quitar un nodo cuesta tokens (5 + 2 por nivel), salvo los asignados desde que abriste el árbol. «Copiar build» y «Pegar build» pasan la build como un código de texto (`PO1:…`); en partida se carga como plan.
- **Árbol con identidad**: cada clase tiene cerca de su inicio un **notable de estilo** (anillo dorado) que cambia cómo se juega (convertir el daño, una nova al recibir golpes, una bomba al esquivar, perforar, un pulso de estática, explosiones al matar); hay cuatro **piedras angulares** nuevas con su contra (Hotfix en Producción, Root Access, Arquitectura Hexagonal, Kanban), y tres **constelaciones** (puntas de estrella) que piden 50 de dos atributos y dan un 50 % más.
- **Arte del árbol**: cada región se tiñe del color de su clase, los nodos menores llevan el icono de su temática, las líneas se iluminan al asignar y completar un grupo suelta un destello.
- **Botín con identidad**: bases de nivel alto con implícito propio de su tipo (espadas con robo de vida, hachas que desangran, mazas con más área, dagas que envenenan, armaduras con bloqueo…) y únicos cuya gracia es una mecánica: El Pager de Guardia lanza rayos, el Encendedor del Practicante levanta muros de fuego, el Ctrl+Z de Bolsillo devuelve los golpes, el Casco del Rollback deja una bomba al esquivar, y más.
- **Crafteo con más decisiones** (mesa de Mario): el parche de **rollback** quita el afijo que elijas y el de **optimización** lo sube un tier (hasta lo que permita el nivel del objeto), con un 30 % de que se rompa y lo pierdas. La mesa guarda un historial de lo que hizo.
- **Nacho, revendedor de hardware**, en el Campamento del Último Commit y en el Socket Seguro. Su tienda es una escena: abre la **gabardina** (pixel art en tres cuadros, con sonido de tela) y la mercancía cuelga de ganchos en el forro; suelta frases sarcásticas al entrar, al mirar, al comprar, al vender o si no te alcanza («Esta RAM se cayó de un camión. De un camión de Amazon.»), con su voz. Vende 9 placas base (3 de Fuerza, 3 de Destreza y 3 de Inteligencia, sin repetir, así que siempre hay algo para tu clase), hasta 10 módulos RAM distintos y 2 pociones, todo del nivel del personaje. En el **bolsillo de dentro**, la **oferta del día** (una placa de 4 ranuras al 60 %), y en un **bolsillo secreto** que hay que abrir, el **contrabando** (una placa de 2 niveles más y 5 ranuras, a 2,5 veces su precio). Filtros por tipo y atributo, y al pasar por una placa avisa si ya tienes esa habilidad. «Renovar mercancía» cuesta más con cada caja hasta que cambias de zona. Compra lo que le arrastres desde la bolsa (20 % de su precio), vende de golpe el equipo normal o el normal y mágico, y lo último vendido se puede **recomprar** por lo mismo. Las placas de habilidades con `min_level` ya no salen antes de ese nivel (tampoco como botín).
- **Alijo (NAS compartido)**, junto al waypoint de los campamentos: 4 pestañas de 60 casillas, **compartido entre todos los personajes** de la cuenta (user://stash.json, se guarda en cada cambio). Arrastra entre el alijo y la bolsa, o haz click: en el alijo lo pasa a la bolsa y en la bolsa lo guarda. Los objetos clave no entran.
- El inventario ya no muestra vida, daño ni resistencias: están en la hoja de personaje (C).

## Guardado de personajes

- Un archivo JSON por personaje en `user://characters/<id>.json`. En Windows es `%APPDATA%\Godot\app_userdata\Path Overflow\characters`. Al renombrar el proyecto, los guardados de la carpeta antigua (`Exile Overflow`) se **copian** a la nueva la primera vez; la carpeta vieja no se toca.
- Se guarda **todo el personaje**: nombre, clase, ascendencia, nivel, experiencia, apariencia, pasivas, equipo, bolsa, placas y RAM, banderas (diálogos, tutorial) y tiempo jugado.
- **Autoguardado**: unos segundos después de cada cambio, cada minuto, al volver al menú y al cerrar la ventana.
- **Seguro ante cortes**: se escribe en un `.tmp` y luego se sustituye el archivo; las tres versiones anteriores quedan como `.bak`, `.bak2` y `.bak3` y, si el principal está dañado o falta, se carga la copia más reciente que se pueda leer. El alijo también guarda un `.bak` y se recupera de él (el dañado se aparta como `.danado`).
- **Espacios de guardado**: tres, elegibles en el menú de personajes («Espacio 1 de 3»); cada uno con sus personajes y su alijo. El 1 usa las carpetas de siempre (`user://characters`, `user://stash.json`); los demás, `user://espacio_N/`. El activo se recuerda en `settings.cfg`.
- **Tolerante a cambios de datos**: lo que deja de existir (nodos, objetos, habilidades) se descarta al cargar en vez de romper la partida.
- **Versiones**: `save_version` 2 añadió las placas base; los guardados v1 reciben las placas iniciales de su clase al cargarse.

## Idioma

Todos los textos están en **español latinoamericano neutro** (ustedes, laptop, celular, mouse, practicante...). Las reglas están en [`docs/estilo.md`](docs/estilo.md) y una prueba falla si aparece una forma de España.

## Estructura

```
data/                 Datos de diseño (JSON): clases, árbol, enemigos, acto y zonas, NPCs, misiones, tutorial
data/items/           Bases, afijos (con tiers), únicos y conjuntos
data/skills/          Habilidades (placas base) y módulos RAM
scripts/core/         Stat, Modifier, StatBlock (fórmula de PoE), DataLoader, GameSettings, RetroSfx
scripts/passives/     PassiveTree, PassiveAllocation, PassiveTreeView
scripts/character/    CharacterData, CharacterSaves, CharacterAppearance
scripts/items/        Rarity, ItemDatabase, Item, ItemGenerator, Inventory, ItemTransfer, ItemIcons
scripts/skills/       SkillDatabase, Motherboard, RamModule, SkillCalc
scripts/quests/       QuestLog
scripts/game/         World, Player, SkillController, EnemyManager, LootManager, Zone
scripts/ui/           Título, logo, menús, HUD, inventario, habilidades, waypoints, diálogos, tutorial, UiStyle
scripts/autoload/     GameData (datos estáticos y personaje actual), MusicPlayer
scenes/               Escenas (.tscn)
assets/               Sprites, shaders, UI, audio, fuentes
tools/                Generadores (árbol, sprites, iconos, música, efectos y ambientes) y comprobador de scripts
tests/                Pruebas de la lógica pura
```

## Decisiones de arquitectura

- **Todo es un `Modifier`.** El árbol, las ascendencias, los objetos y la RAM producen el mismo tipo de dato. Añadir contenido es añadir datos, no código.
- **Fórmula de PoE** en `StatBlock`: `(base + planos) × (1 + Σaumentos) × Π(más)`. Los tags (`spell`, `melee`, `projectile`, `area`…) permiten modificadores condicionales. Los stats padre (`damage` → `elemental_damage` → `fire_damage`) heredan aumentos. La RAM se aplica sobre una copia (`duplicate_with`) que solo afecta a su habilidad.
- **Lógica separada de los nodos.** Stats, pasivas, personaje, objetos, inventario y cálculo de habilidades son `RefCounted` puros. Se prueban sin escena y podrían moverse a un servidor.
- **El árbol se dibuja en un solo `_draw()`** y está pensado para más de 1000 nodos.
- **Enemigos orientados a datos** (`EnemyManager`): arrays empaquetados, rejilla espacial y un `MultiMesh` con shader para dibujarlos en una sola llamada.

## Objetos

| Rareza | Afijos | Notas |
|---|---|---|
| Normal | 0 | Solo implícitos de la base |
| Mágico | 1-2 (máx. 1 prefijo + 1 sufijo) | Nombre: base + prefijo + sufijo |
| Raro | 3-6 (máx. 3 + 3) | Nombre aleatorio ("Tormento del Kernel") |
| Ultra-raro | 7-8 (máx. 4 + 4) | Siempre el mejor tier disponible para su nivel |
| Único | Fijos, con rango | `uniques.json`, con texto de ambientación |
| De conjunto | Fijos + bonus por piezas | `sets.json` |

Además, el botín incluye placas base (8 %) y módulos RAM (10 %). Los tooltips de equipo muestran la comparación con lo que llevas puesto.

**Únicos** (14): además de los primeros, *Fusible Quemado* (quemar y fuego), *Guantes del Electricista Sin Certificado* (electrocutar y efecto de las interacciones), *Diadema del Cron Lento* (veneno y caos), *Credencial de Sysadmin* (efecto y eficiencia de auras), *Chaleco Certificado SSL* (espinas), *Teclado del Orquestador* (autómatas: velocidad, daño de esbirros y +1 dispositivo), *Faja de Batería de Litio* (+1 Buffer y +1 Multihilos máximos) y *Zapatillas de Suelo Recién Trapeado* (duración y área: terrenos más largos). **Conjuntos** (4): *Atuendo del Senior*, *Legado del Arquitecto*, *Kit del SRE de Guardia* (espinas, resistencia a estados, auras y vida al matar) y *Equipo de Redes* (electrocutar, rayo y +1 encadenamiento con las tres piezas).

## Pruebas y comprobaciones

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_core.gd
```

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/check_scripts.gd
# Capturas de todas las pantallas (título, personajes, creador, muestrario de apariencias,
# campamento, hoja C, inventario, diálogo, árbol y una zona del acto II) en user://capturas/:
Godot_v4.7.2-stable_win64_console.exe --path . res://tools/capture_screens.tscn
```

La primera ejecuta las pruebas de lógica: stats, árbol, objetos, guardado, placas base y RAM (compatibilidad, generaciones, cálculo de daño, coste, proyectiles, área) y la integridad de los JSON (diálogos que apuntan a nodos que existen, pasos del tutorial, regalos válidos...).
La segunda carga todos los scripts, escenas y shaders para detectar errores de compilación sin abrir el editor.

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tests/test_integration.tscn
# Opciones: -- segundos=10 clases=guerrero,hechicero zonas=zona1,oblea
```

La prueba de integración carga cada zona con cada una de las 7 clases (un personaje por acto con el nivel del acto y, desde el 20, una ascendencia) y juega 30 s simulados: se mueve hacia los enemigos, lanza las habilidades de la barra, usa pociones y esquiva. Falla (código de salida 1) si aparece cualquier error del motor o `SCRIPT ERROR`, o si el jugador sale de la zona. Con `--fixed-fps` va más rápido que el tiempo real.

```bash
powershell -File tools/run_checks.ps1
```

Corre las tres comprobaciones seguidas y sale con código 1 si alguna falla (con `-Rapida`, la integración va a 5 s por zona). Busca Godot en el Escritorio o en Descargas, o en la variable `GODOT`. El `_console.exe` necesita el ejecutable normal en la misma carpeta.

## Telemetría local

Con **Pausa → Interfaz → Registro local de partidas** (activado por defecto), cada visita a una zona de un personaje guardado deja una línea en `user://telemetria.jsonl` (`scripts/game/telemetry.gd`): zona, nivel de área, clase, dificultad, segundos, segundos en combate, daño, **DPS**, enemigos y **muertes**. Nada sale del equipo, y los personajes de las pruebas no dejan registro. Para verlo resumido por zona y por clase (visitas, minutos, DPS medio, muertes por hora, enemigos por minuto, de la zona que más mata a la que menos):

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/telemetry_summary.gd -- clase=hacker zona=zona3
```

**Balance de habilidades** (`tools/skill_balance.gd`): DPS de cada placa a nivel 1 y 10 con un personaje de nivel 1 sin pasivas ni objetos, ordenado, con el nivel que pide y su maná (`-- clase=hacker` para otra clase). También muestra, para cada clase, sus habilidades iniciales con su arma inicial (personaje nv 10, placa nv 8) y cuánto tardan en tumbar al jefe del Acto I. Tras el balance del 25-10-2026 (T69) ninguna habilidad pasa de ~2× la mediana a placa 1 (las invocaciones, trampas, terrenos y degenerativos más fuertes bajaron su daño base, y Proceso Hijo, Derrame de Aceite, Mina Rodante, Fuga de Memoria y Pipe de Datos caen más tarde), y la mejor inicial de cada clase tumba al primer jefe en 43-92 s (antes, Drones de Vigilancia 24 s y Bomba Lógica 30 s; Ráfaga de Paquetes 120 s). Una prueba lo exige.

Al terminar, la integración imprime **lo que queda vivo tras cerrar cada mundo** (objetos, nodos, huérfanos y memoria): si algo se acumulara entre partidas, se vería crecer ahí. Medido el 25-10-2026 (T67): tras 28 mundos se mantienen 19 nodos, 0 huérfanos y ~84 MB; los objetos se estabilizan en ~+120 (las cachés de sprites y voces).

Ojo al lanzar Godot desde PowerShell: es una aplicación de ventana y, si no se lee su salida (`| Out-Null` o `| Out-String`), PowerShell no espera a que termine (con `*> $null` sigue de largo).

## Rendimiento

Benchmark del 18-10-2026 (antes de los sprites), RTX 4050 Laptop, vsync desactivado, todos los enemigos amontonados alrededor del jugador:

| Enemigos | FPS medio | Simulación (GDScript) |
|---|---|---|
| 300 | ~1350 | 2.5 ms/tick |
| 600 | ~790 | 6.3 ms/tick |
| 1000 | ~190 | 12.3 ms/tick |

GDScript va sobrado para densidades tipo PoE (300-600). Por encima de unos 800, el siguiente paso sería portar **solo** `EnemyManager` a C# o GDExtension.

Benchmark del 24-10-2026 con el juego completo (sprites, filtro de pixel art, HUD, afijos, estados en todos y 6 invocaciones y auras; ventana de 1600×900, vsync desactivado): `Godot --path . --disable-vsync res://tools/capture_screens.tscn -- rendimiento`.

| | 150 enemigos | 300 enemigos | Sin enemigos (300 ocultos) |
|---|---|---|---|
| Antes de los lotes | 27.8 ms (36 FPS) | 48.7 ms (21 FPS) | 20.8 ms |
| Con barras, estados y avisos por lotes | 22-24 ms (42-45 FPS) | 38-42 ms (24-26 FPS) | 20-22 ms |
| Y la zona solo dibuja lo que cae en cámara | 16.5 ms (60 FPS) | 30-31 ms (32-34 FPS) | 13-13.5 ms |

Las barras de vida, los cuadritos de estado, los halos del modo simple, los candados de aturdido, las insignias de rol y los círculos de aviso de todos los enemigos se dibujan en **un solo arreglo de triángulos** por fotograma (`EnemyManager._batch_*`), y los avisos de enemigos fuera de cámara no se dibujan: lo que cuestan los enemigos con 300 en pantalla baja de ~28 a ~19 ms. Lo que queda está repartido: `_draw` de enemigos ~8 ms, simulación ~4.5 ms y el resto en GPU. La zona redibujaba cada fotograma **todos** sus obstáculos, antorchas, props y salidas (cientos en las zonas grandes); ahora solo los que caen en cámara (con margen), y sin enemigos el fotograma baja de ~20 a ~13 ms. Lo que queda con 300 enemigos: `_draw` de enemigos ~7 ms, simulación ~4.5 ms, interfaz ~8 ms (el `_draw` del HUD solo ~2.4 ms; el resto, textos, iconos y GPU) y la zona ~5 ms. (Antes el benchmark medía con el juego en pausa por la elección de habilidad del nivel 16: ahora la resuelve.)

Medición del 25-10-2026 (tras las tareas de presentación: luces de aliados, clima, obstáculos en pixel art): 150 enemigos 17,5-19,3 ms (52-57 FPS, simulación 2,4-2,5 ms), 300 enemigos ~34 ms (29-30 FPS, simulación 4,7-4,8 ms), sin enemigos 12,6-16,3 ms. Portar `EnemyManager` a C# o GDExtension ahorraría como mucho esos ~4,8 ms; quedó bloqueado (T66 en `docs/roadmap.md`) y se hizo T68 en su lugar.

**T68**: las barras de vida, los cuadritos de estado y los halos de estados de los enemigos van en dos **MultiMesh** (un rectángulo y un disco; una instancia por elemento, escrita en un solo búfer por fotograma); los avisos de cono y de carga entran en el lote de triángulos sin triangular cada fotograma, y los círculos y aros usan direcciones precalculadas. Los iconos del HUD (habilidades, pociones y estados) se pintan **una vez en una textura** (`scripts/ui/icon_cache.gd`: un `SubViewport` por icono que se renderiza una sola vez) y luego solo se dibuja la textura.

| | 150 enemigos | 300 enemigos | `_draw` de enemigos (300) |
|---|---|---|---|
**T124** (26-10-2026, ya con las zonas generadas, las mecánicas y las salas de la versión 3.0): obstáculos que se transparentan, sombras hacia la luz, fondo con parallax y manchas en el suelo. Sin T124: 150 enemigos 17,50 ms, 300 enemigos 35,81 ms; con T124: 17,46 ms y 34,71 ms. Dentro del ruido: no cuesta nada que se note.

| Antes de T68 | 18,2 ms (55 FPS) | 33,4 ms (30 FPS) | 7,2 ms |
| Después | 14-16,6 ms (60-71 FPS) | 29,7-30 ms (33-34 FPS) | 6,2 ms |

## Árbol pasivo

- **734 pasivas en 67 clusters con forma** (como en PoE 2: cada temática dibuja su símbolo: corazón para vida, llama para fuego, rayo en zigzag, copo de nieve para frío, escudo para armadura, gota para maná, mira para crítico, flecha para proyectiles, estrella para área, hexágono para escudo de energía, espiral para caos, colmillos para robo de vida, pluma para evasión, chevrons para velocidad y movilidad, reloj de arena para enfriamientos, libro para hechizos, prisma para resistencias y martillo para daño físico; los de atributos siguen siendo anillos) (7 clases: 6 alrededor y el Full Stack en el centro): cada anillo o rueda es de un solo tipo (vida, armadura, fuego, crítico, maná, robo de vida…). Sus pasivas menores son variaciones de ese tema (p. ej. vida plana, vida + regeneración, vida + armadura, % de vida) y su notable tiene nombre, texto sarcástico e icono propio. Entre clusters hay caminos de atributos, puentes temáticos entre clases vecinas y un anillo central de atributos.
- **Inicios limpios**: el inicio de cada clase solo se conecta hacia delante, a sus 4 ramas; nada llega a él por detrás ni pasa junto a él. Cada región se une al centro por sus lados, a través de los clusters *puerta* entre clases vecinas, y hay un cluster interior por clase entre el anillo central y la clase.
- **Centro**: el inicio del Full Stack, el anillo de *Versatilidad* (3 notables y su piedra angular) y el anillo central de atributos.
- **Maestrías** (`data/passive_masteries.json`): en cada sector, el notable más cercano al inicio de la clase es una maestría (tres rombos encima): asignada, click izquierdo para elegir **1 de 3 bonos**, gratis y cuando quieras. Full Stack (Contexto Infinito / Backend / DevOps), Soporte Técnico (resistencias / bloqueo / armadura y regeneración), QA (daño físico / velocidad de ataque / sangrado), Frontend (multiplicador de crítico / movimiento y evasión / proyectiles que atraviesan), Prompts (crítico / veneno / daño contra enemigos con estados), Datos (daño / velocidad de lanzamiento / maná) y DevOps (vida y reserva de esbirros / daño de esbirros / velocidad de autómatas). La primera opción es el efecto que tenía el notable; la elección se guarda con el personaje (`passive_masteries`) y el buscador también encuentra las opciones. Van por id del nodo con su nombre original: si se regenera el árbol y cambian los ids, las pruebas avisan.
- **Nodos clave que cambian una regla** (marco violeta): **Tipado Estático** (Ingeniera de Prompts: sin críticos, pero el daño nunca varía; +20 % más de daño), **Recolector de Basura** (Científico de Datos: al matar recuperas un 3 % del maná y el maná no se regenera solo; +15 % más de velocidad de lanzamiento), **Modo Seguro** (Técnico de Soporte: un golpe mortal te deja a 1 de vida 2 s, una vez cada 30 s) y **Código Espagueti** (Tester QA: tus proyectiles rebotan 2 veces al azar tras golpear). Sustituyen a Root Sin Contraseña, Programación Orientada a Deadlines, Monolito Legacy y git push --force en el mismo sitio del árbol: quien los tenía asignados conserva el punto, con el efecto nuevo.
- **Temáticas** en `data/passive_themes.json` (21, nuevas: Versatilidad, Enfriamientos y duración, Movilidad). Para añadir pasivas o cambiar valores, edita ese archivo y regenera el árbol con `python tools/generate_passive_tree.py`.
- **Condiciones**: algunas pasivas solo cuentan con **vida baja** (≤ 50 %), **vida al máximo**, **si has matado recientemente** (4 s), **con 3 o más aliados** (invocaciones, esbirros o drones) o **si no te has movido en 1 s**. Se reflejan en el tooltip ("con la vida baja") y en el combate en tiempo real. Sacrificio: *Swap Ajeno* (más daño con la vida baja) y *Hasta el Último Byte* (robo de vida extra con la vida baja); condicionales: *Redundancia Activa-Activa* (daño de esbirros con 3 aliados), *Defensa en Profundidad* (daño quieto), *Corazón de Silicio* (daño con la vida llena) y *Refactor a Martillazos* (daño **contra enemigos aturdidos o congelados**, stat `stunned_damage`).
- **Piedras angulares del árbol 2.0** (23): además de las 7 de clase y las 4 de los clusters (Hotfix en Producción, Root Access, Arquitectura Hexagonal, Kanban), 12 nuevas con ventaja y contra: **Mente sobre Materia** (el maná se lleva el 40 % del daño; la vida no se regenera sola), **Pago por Uso** (las habilidades cuestan vida), **Zero Trust** (sin críticos, 40 % más de daño), **Caché Fría** (el primer golpe a cada enemigo hace el doble; los siguientes, un 20 % menos), **Rate Limiting** (tras un golpe, los de los 0,4 s siguientes no te dañan; −15 % de vida), **Consistencia Eventual** (la mitad del daño llega en unos 3 s), **Pato de Goma** (con 3 aliados regeneras un 2 % de vida por segundo), **Buffer Overflow** (35 % más de daño con el maná al 90 % o más), **Kill -9**, **Fail Fast**, **Pair Programming** (robot de compañía, −20 % de daño) y **Contenedor Efímero**. El tooltip dice con qué piedras choca cada una y avisa en rojo si ya tienes la otra.
- **Arte del árbol 2.0**: fondo de estrellas y nebulosas del color de cada clase que se mueven con parallax al arrastrar, marcos de pixel art por tipo de nodo (octógono, hexágono doble para piedras angulares, rombo para maestrías, estrella para constelaciones), un destello que recorre las líneas asignadas, medallones con el icono de la familia y nombres de región al alejar, **minimapa** en la esquina (click para saltar) y, al asignar, un pulso que viaja por el camino; completar una constelación hace su propio destello.
- **Maestrías, constelaciones y ranuras del árbol 2.0**: 18 maestrías (3 por región) y cada una de la misma familia ofrece tres opciones distintas. Las 6 constelaciones del anillo exterior piden atributos y, **completas** (sus 11 nodos), su estrella da un bono extra (p. ej. Pentester: 10 % más de daño físico y +20 % de multiplicador de crítico). **18 ranuras de chip** fijas: en las 12 puertas entre clases y en un cluster del anillo B de cada región; si el árbol cambia de versión, los chips engastados vuelven a la bolsa.
- **Familia de maná** (12 clusters): **maná antes que vida** (el maná se lleva ese % del daño que pasa el escudo de energía, hasta un 50 %; si no alcanza, el resto va a la vida), **maná por segundo** (se suma a la regeneración base del 1,75 % aunque tengas maná reservado), **maná al golpear** y **al matar**. Notables: *Mente sobre Memoria* y *Swap a Disco* (maná antes que vida), *Interrupción por Hardware*, *Liberación de Recursos*, *Caché Caliente*… El orbe de maná y la hoja de personaje muestran la regeneración por segundo y el % que se lleva el maná.
- **Familias del árbol 2.0**: las 28 familias tienen 4 clusters o más (maná 12; vida, armadura, evasión, crítico y hemorragia 5) y hay 19 notables nuevos, muchos con condición: *Rack Anclado al Suelo* (quieto), *Doble Fuente de Alimentación* (vida llena), *Commit Forzado* y *Kernel Comprometido* (vida baja), *Fallo en Cascada* (tras matar), *Hombre Orquesta* (con 3 aliados), y de maná *Caché Caliente*, *Pool de Conexiones*, *Reciclaje de Memoria* y *Buffer Lleno*. Ningún notable ni piedra angular repite nombre en todo el árbol (el generador lo comprueba); las maestrías se llaman «Maestría: <cluster>» y los notables de constelación «Estrella: <nombre>».
- **Interfaz**: halo de color y nombre por cluster (con zoom intermedio), pasivas menores del color de su tema, notables y piedras angulares con icono (apagado hasta asignarlo), nombres de notables al acercar, **buscador** (resalta coincidencias; Enter salta a la siguiente; no distingue tildes) y **resumen de bonificaciones** totales en el panel lateral.
- **Chips de expansión que transforman nodos** (únicos, en `ExpansionChip.UNIQUES` con `transform`): engastados en una ranura asignada, cambian lo que dan los nodos asignados en su radio (unos 3 nodos, aro de color alrededor de la ranura): **Chip Criogénico** (fuego da frío), **Chip de Sobretensión** (frío da rayo), **Chip Monohilo** (el daño y la vida de esbirros son para ti) y **Chip Blindado** (evasión da armadura y destreza da fuerza). Solo cambia el stat; el valor es el mismo.
- **Iconos**: `assets/sprites/passives/passives.png`, generado con `tools/generate_passive_icons.gd` (mapa en `data/passive_icons.json`).
- **Versión del árbol**: si cambia la estructura (`TREE_VERSION` en el generador), los personajes guardados con otra versión recuperan todos sus puntos de pasiva y ven un aviso al entrar, en lugar de quedarse con nodos que ahora significan otra cosa.

## Exportar

Añade `*.json` en *Exportar → Recursos → Filtros para exportar archivos no-recurso*. Si no, los datos no se incluyen en el ejecutable.

**Publicar** (`tools/build_release.ps1`): exporta Windows (`build/PathOverflow.exe`), Linux (`build/linux/PathOverflow.x86_64`) y macOS (`build/mac/PathOverflow.zip`, app universal firmada ad hoc) según las plantillas de exportación que haya instaladas (las de Linux y macOS se bajan desde *Editor → Administrar plantillas de exportación*; sin ellas se saltan), y arma el **instalador de Windows** `build/PathOverflow-Setup.exe`: un ejecutable (`installer/Setup.cs`, compilado con el `csc` de .NET Framework que trae Windows) que instala el juego en `%LOCALAPPDATA%\Programs\PathOverflow` sin pedir administrador, con accesos directos en el escritorio y el menú Inicio y «Desinstalar Path Overflow». Las partidas guardadas no se tocan al instalar ni al desinstalar. `export_presets.cfg` no va en el repositorio: si falta, se crea desde `export_presets.example.cfg` (con los tres presets).

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_release.ps1
```

**Android** (`tools/instalar_android.ps1`): descarga, si faltan, el JDK 17 (a `%LOCALAPPDATA%\PathOverflowAndroid`) y las herramientas de Android (a `%LOCALAPPDATA%\Android\Sdk`), te pide aceptar las licencias del SDK, instala build-tools 36.1.0 y la plataforma 36, apunta el editor de Godot a ellos y exporta `build/PathOverflow.apk` (preset «Android»: arm64-v8a, `com.pathoverflow.game`, horizontal, sin permisos extra, firmado con la clave de depuración `%APPDATA%\Godot\keystores\debug.keystore`). Hacen falta las plantillas de exportación de Android de Godot 4.7.2.

```powershell
powershell -ExecutionPolicy Bypass -File tools/instalar_android.ps1
```

Con todo instalado, las siguientes veces basta con `tools/exportar_android.ps1` (`-Release` para la versión firmada). La **versión** sale de un solo sitio, `application/config/version` en `project.godot` (ahora 3.1.0): el script la copia al APK y sube el código de versión en cada exportación (Android solo instala encima una versión con el código más alto). Se ve abajo a la derecha en la pantalla de título y en la pausa («v3.1»).

```powershell
powershell -ExecutionPolicy Bypass -File tools/exportar_android.ps1
```

**Actualizaciones** (GitHub Releases): en la pantalla de título el juego lee `latest.json` de la última publicación del repositorio (`application/config/update_url`) y, si hay una versión más nueva, ofrece un botón «Actualización disponible · Descargar» que abre la descarga en el navegador (nunca descarga ni instala solo; se apaga en Pausa → «Buscar actualizaciones»). Para publicar: sube `application/config/version`, ejecuta `tools/publicar_version.ps1 -Repo usuario/repositorio -Notas "qué trae"` (exporta firmado con tu clave y escribe `build/latest.json`) y sube `build/PathOverflow.apk` y `build/latest.json` a una release con la etiqueta `v<versión>`. Para que cada versión se instale encima de la anterior **sin borrar las partidas**, firma siempre con la **misma clave**: por defecto el script firma con la de depuración de este equipo (`%APPDATA%\Godot\keystores\debug.keystore`, la de los APK ya instalados; hay copia en `%APPDATA%\PathOverflow\clave_firma_respaldo.keystore` y conviene guardar otra fuera del equipo). Repositorio de versiones: **WalBernal/PathOverflow** (público, solo versiones).

```powershell
powershell -ExecutionPolicy Bypass -File tools/publicar_version.ps1 -Repo usuario/repositorio -Notas "Qué trae"
```

**Subirla sola** con GitHub CLI: `-Subir` exporta y además crea (o actualiza) la release `v<versión>` con el APK y el `latest.json` y la marca como la última; `-SoloSubir` sube lo que ya está en `build\` sin exportar de nuevo. Una sola vez en el equipo: `winget install --id GitHub.cli` y `gh auth login` (con tu cuenta de GitHub).

```powershell
powershell -ExecutionPolicy Bypass -File tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -Notas "Qué trae" -Subir
powershell -ExecutionPolicy Bypass -File tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -Notas "Qué trae" -SoloSubir
```

Para instalarlo en el teléfono: copia `build/PathOverflow.apk` al celular (cable USB, Drive o correo), ábrelo desde el administrador de archivos y permite «instalar apps de origen desconocido» a esa app cuando lo pida. Con depuración USB activada también vale `adb install -r build/PathOverflow.apk` (adb está en `%LOCALAPPDATA%\Android\Sdk\platform-tools`). Para publicarlo en una tienda hay que firmarlo con una clave propia: créala con `keytool -genkeypair -v -keystore mi_clave.keystore -alias mi_alias -keyalg RSA -keysize 2048 -validity 10000`, ponla en *Proyecto → Exportar → Android → Keystore → Release* (ruta, usuario y contraseña) y exporta con `--export-release` (para Google Play, además, AAB con `gradle_build/use_gradle_build`).

## Próximos pasos sugeridos

1. Sprites del jugador y de los NPCs (el formato de apariencia ya está preparado).
2. Resistencias y tipos de daño en los enemigos, y enemigos (y jefe) con habilidades propias.
3. Ascendencias mediante pruebas (ahora se eligen libremente en el árbol pasivo).
4. **Acto II: Kernel Panic.** Ya está preparado el gancho (portal en el campamento, misión principal, bandera `act2_started`). Idea de zonas: Espacio de Usuario → Tabla de Procesos → Cementerio de Huérfanos (procesos zombi sindicados) → Scheduler (enemigos que se turnan) → Memoria Virtual (páginas que aparecen y desaparecen) → jefe **init (PID 1)**. Hace falta un `act2.json`, que `GameData` cargue varios actos y que el waypoint muestre los dos.
5. Editor del árbol pasivo dentro de Godot.

**Fuentes**: la monoespaciada de la interfaz (consola, cifras, pantalla de carga y de muerte) es Fira Code (https://github.com/tonsky/FiraCode), con licencia SIL Open Font License 1.1: `assets/fonts/FiraCode-VF.woff2` y su licencia en `assets/fonts/FiraCode-OFL.txt`.
