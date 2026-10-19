# Path Overflow — El Último Commit

ARPG estilo Path of Exile en **Godot 4.7**, de ambientación oscura y con sarcasmo de programador.
Por ahora es solo para un jugador en local, pero la lógica está escrita para poder pasar a un modelo cliente-servidor en el futuro.

## Cómo abrirlo

1. Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`.
2. Pulsa **F5**. Aparece la pantalla de título (logo, música); cualquier tecla lleva a la lista de personajes.
3. Un personaje nuevo empieza en **El Sandbox**, la zona tutorial. Desde ahí se llega al campamento y al resto del acto. El tutorial (arriba a la izquierda) te guía; se puede saltar.

| Tecla | Acción |
|---|---|
| WASD / mantener click izq. | Mover |
| Click der. · Espacio · Q · E · R · F | Las 6 habilidades de la barra |
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

**Objetos**: arrastrar y soltar entre bolsa, equipo, barra de habilidades y ranuras DIMM (intercambia si hace falta; las reglas están en `ItemTransfer`). Soltar un objeto fuera de los paneles lo tira al suelo; ya no se pueden destruir con un click.

**Al lanzar habilidades** el personaje solo se detiene un instante (25 % del tiempo de uso, máximo 0,15 s); el ritmo de ataque no cambia.

**Animación al caminar**: piernas alternas que se levantan, brazos en oposición y el cuerpo sube y baja con cada paso. El ciclo avanza con la distancia recorrida de verdad, así que los pies no "patinan" y, si choca contra algo, deja de andar en el sitio. De perfil, las piernas avanzan y retroceden y el cuerpo se inclina.

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

Se definen en `data/skills/skills.json` y `data/skills/ram_modules.json`. Cada clase empieza con dos placas (`starter_skills` en `classes.json`).

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

Trampa, mina y torreta añaden su etiqueta a la habilidad y no funcionan con movimiento, esbirros ni con otra trampa/mina/torreta (solo cuenta un módulo de despliegue).

Stats nuevas para ellas: **Recuperación de enfriamientos** (acorta los enfriamientos) y **Duración de habilidades** (giros, trampas y aturdimientos).

## Prólogo / Acto 0: La Beca de Schrödinger

Al crear un personaje (apariencia y nombre; ya no se elige clase en el creador, que muestra el **expediente** del recién egresado) empieza el prólogo (`scenes/prologue/prologue.tscn`), en pixel art de verdad: un escenario de 400×225 escalado sin suavizado, con un shader que lo pinta descolorido por el calor (`prologue_screen.gdshader`).

1. **El Desembarco de la Realidad**: texto mecanografiado (147 vacantes, 5 años de experiencia requerida, café soluble y agua de garrafón) y el malecón de Mazatlán al mediodía, con camisa formal, marcas de sudor y un portafolio de plástico.
2. **Retorno a la UAdeO**: el pasillo largo hasta el Departamento de Informática, junto a la ventanilla de cobro («Regreso en 15 minutos»).
3. **El Error 404 del Archivo Muerto**: el departamento destrozado (archivadores volcados, CRT beige, el minisplit goteando sobre una torre quemada) y Rafa, que busca tu servicio social con `grep`: el Inge Pepe anotaba a los prestadores en una libreta Scribe de gatitos y se la llevó.
4. **El Incidente del Viernes a las 6:00 PM**: se cae el SICE; el backend corre en «El Monolito» (2004). Rafa propone un trato.
5. **La Elección Forzada**: ventana al estilo Windows 98, «Confirmar Contratación de Emergencia», con un desplegable para el **primer puesto (la clase)**. El botón **No** esquiva el ratón (salta 150 px; acorralado, encoge hasta 1×1 px) y si se le atina sale `Error 0x80004005` y queda deshabilitado.
6. **Clímax**: la carpeta lila «NO TOCAR - CONFIG_PROD» detrás del rack, la descarga, la consola roja (`POST /api/v1/deploy/force --user admin`), la oficina pixelándose (papeles en logs, cables en cobre, la ropa en binario) y el título **EL ÚLTIMO COMMIT**. Despiertas en el Sandbox (escena `llegada_sandbox`).

Se camina con A/D, flechas o manteniendo el click; E, Espacio o click para interactuar. Esc (dos veces) salta a la elección de puesto; en el creador, «Saltar prólogo» va directo a ella.

## Acto I: El Último Commit

El acto está definido en `data/act1.json` y lo construye `Zone` (`scripts/game/zone.gd`).

| Zona | Nivel | Waypoint | Notas |
|---|---|---|---|
| El Sandbox | 1 | | Tutorial: pocos bugs, más botín y B.O.B., el bot de onboarding |
| Campamento | 1 | ✔ | Zona segura, punto de reaparición; Aida, Mario y Rafa |
| El Bosque de Cables | 2 | | Iris, la practicante perdida |
| Las Ruinas del Monolito | 4 | ✔ | |
| El Pantano de Memory Leaks | 6 | | Tomás, el último QA |
| Las Catacumbas del Legacy | 8 | ✔ | |
| La Granja de Servidores | 10 | ✔ | El Fantasma del DBA (regala una RAM) |
| Sala del Servidor Principal | 12 | | Jefe: **El Arquitecto del Monolito** |

- **Terreno**: los bordes de cada zona son irregulares y temáticos (maleza y árboles de cables en el bosque, acantilados en las ruinas, agua en el pantano, muros en las catacumbas, paredes de racks en la granja, el vacío binario del Sandbox y datos corruptos al rojo en la sala del jefe). Dentro hay accidentes grandes (`features`): lagos, colinas, simas, lagos de datos, agujeros 404 y charcos de lava. Todo tiene colisión y se ve en el minimapa.
- **Obstáculos** con colisión (árboles, rocas, racks, lápidas…), colocados con semilla fija para que cada zona sea siempre igual y dejando pasillos libres entre entradas, salidas, waypoint y NPCs.
- **Enemigos controlados**: cada zona tiene un número fijo de grupos (`packs`, `pack_size`), repartidos por el mapa con distancia mínima entre ellos y a los puntos clave. No reaparecen hasta volver a entrar. Los enemigos chocan con los obstáculos y no salen del mapa.
- **Salidas** en los bordes ("← Campamento", "Las Ruinas →"): basta con caminar hasta ellas.
- **Waypoints**: se descubren al tocarlos y se guardan por personaje (`flags.waypoints`). Al hacer click se abre la lista del acto.
- **Jefe**: al derrotarlo se completa el acto (bandera `act1_complete`), cae botín especial (siempre en suelo alcanzable) y se abre un portal al campamento.
- **Después del jefe**: el Arquitecto muere en una **escena** (glitch, temblor, sus últimas palabras y la consola del sistema congelándose) y se abre un portal al campamento. Al volver, el campamento culpa al **Inge Pepe**, jefe de informática de toda la vida, recién jubilado (el antecesor de Rafa), y Rafa abre el **puerto 2222** hacia el Kernel. Al cruzarlo se cae **La Red Lince** (pantalla del dinosaurio) y el jugador cae al **Acto II**.
- **Escenas**: `data/cutscenes.json` (líneas con retrato, consola, efectos de glitch, temblor, fundidos y la página sin conexión). Click o Espacio avanzan; Esc salta. Los enemigos se congelan mientras duran.
- **NPCs y lore** en `data/npcs.json` (en el campamento: Aida la Senior, Mario el Becario y Rafa el SysAdmin, que escribe con muchos puntos suspensivos...; sus ids internos siguen siendo `ada`, `kevin` y `root` para no romper los guardados): diálogos con opciones, condiciones (`requires_flag`) y acciones (regalos que se dan una sola vez). Cuentan la historia del administrador que hizo `push --force` "por el Monolito".
- **Tutorial** (`data/tutorial.json`, versión 2): 12 pasos. Empieza en el Sandbox (moverse, atacar, matar, recoger, equipar, pociones, pasivas) y sigue en el campamento (Aida, RAM, Mario, salir al Bosque). Los personajes con el tutorial antiguo continúan donde corresponde.

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

## Misiones

Definidas en `data/quests.json` y gestionadas por `QuestLog` (lógica pura, guardada en el personaje).
El **registro de misiones** está debajo del minimapa (L para plegarlo): la principal arriba, en dorado, y las secundarias debajo, con su paso actual y el progreso.

| Misión | Quién | Qué |
|---|---|---|
| El Último Commit (principal) | — | Recorrer el acto, derrotar al Arquitecto, hablar con Aida y con Rafa |
| Kernel Panic (principal) | — | Empieza al acabar la anterior; preparada para el Acto II |
| Bichos en el cableado | Iris (Bosque) | Eliminar 25 enemigos en el Bosque de Cables |
| Reporte de incidencias | Tomás (Pantano) | Eliminar 3 enemigos especiales o élite en el Pantano |
| La cinta de backup | Fantasma del DBA (Granja) | Recoger la cinta en las Catacumbas del Legacy |
| Granos de café | Mario (Campamento) | Eliminar 40 enemigos en cualquier zona |

- Tipos de paso: hablar, llegar a una zona, bandera, eliminar (con zona y rareza mínima), recoger un objeto de misión y entregar.
- Las misiones se aceptan y se entregan en los diálogos (acciones `start_quest` y `quest_advance`). Sobre los NPCs aparece un **!** amarillo si ofrecen misión y un **?** verde si tienes algo que entregarles.
- Recompensas: experiencia y objetos (`give_random` con rareza, RAM que encaja, placas…).
- Los personajes de antes se ponen al día solos: si ya mataron al jefe, la principal salta a "cuéntaselo a Aida".

## Diálogos con voz

- **Narrador**: si el sistema tiene una voz en español (en Windows: *Configuración → Hora e idioma → Voz*), los NPCs leen su texto en voz alta, cada uno con su tono y velocidad (`voice` en `npcs.json`), y el texto avanza al ritmo de la voz.
- **Pitidos retro**: sin voz (o con el narrador desactivado), sale un pitido de 8 bits cada pocas letras, con el tono de cada NPC. El sonido se genera en código (`RetroSfx`), sin archivos.
- Ambos se activan o desactivan en el menú de pausa (Esc) y se recuerdan en `user://settings.cfg`.
- **Escenas** (muerte de jefes, transiciones): el texto avanza solo, con una barrita que marca el tiempo de lectura; si hay narrador, lo lee en voz alta y espera a que termine. Click o Espacio adelanta y Esc salta.
- **Conversaciones que fluyen**: volver al inicio muestra una frase corta del NPC (`menu`) en vez de repetir el saludo; en visitas siguientes saluda distinto (`greeting_again`) y los temas ya leídos pueden resumirse (`again`). Las opciones ya leídas salen marcadas con ✓ y al final; las de misiones, con ★ y primero. Los temas largos se encadenan con *Continuar*. Las opciones aparecen cuando termina el texto (click lo completa); teclas 1-9 eligen y Espacio sigue. Lo leído se guarda en el personaje.
- El narrador no usa los avisos por palabra de la voz (en Windows pueden trabar el juego): el texto avanza a su ritmo y se consulta si la voz sigue hablando. Solo se corta la voz si de verdad está hablando.
- **Detector de cuelgues** (FreezeWatch): un hilo aparte vigila que el juego avance. Si se para más de 4 s, escribe en user://logs/congelado.log las últimas acciones (diálogos, voz, escenas, viajes). Si el juego se congela, ese archivo dice dónde.

## Efectos y ambiente

- `tools/generate_sfx.gd` sintetiza todos los sonidos (sin archivos externos): efectos en `assets/audio/sfx/` y un ambiente en bucle por estilo de zona en `assets/audio/ambient/` (fogata en el campamento, ventiladores en los servidores, goteo en las alcantarillas, pistones en la fábrica, latido en las salas de jefe...).
- El autoload `AudioManager` reproduce los efectos (limitados para no saturar cuando mueren muchos enemigos a la vez) y cambia el ambiente con un fundido al viajar. El juego lo usa a través de `Sfx` (`scripts/core/sfx.gd`), que no hace nada si el autoload no está (pruebas).
- Cada habilidad suena según su tipo y su daño (`Sfx.skill_sound`): golpe, proyectil, fuego, frío, rayo, caos, explosión, teletransporte, buff, barrera, invocación o trampa. También suenan las muertes de enemigos, el daño recibido, el botín, las pociones, subir de nivel, los portales y las oleadas.
- "Efectos de sonido" y "Sonido ambiente" se activan o desactivan en el menú de pausa. Para usar sonidos propios basta con sustituir el WAV del mismo nombre.

## Pantalla de título, menú y creador

- **Pantalla de título** (`scenes/menu/title_screen.tscn`, escena principal): logo animado de *Path Overflow* (`GameLogo`) con efecto glitch y una pila desbordándose, lluvia de binario, `console.log`s flotando, un grafo de git que termina en `push --force`, bugs cruzando, un rack de servidores echando vapor y un café.
- **Música**: `assets/audio/title_theme.wav`, generada con `tools/generate_music.gd` (bucle de ~37 s). El autoload `MusicPlayer` la mantiene sonando entre título, menú y creador; el botón "Música" la silencia y se recuerda en `user://settings.cfg`. Para usar otra música basta con sustituir el WAV.
- **Creador de personaje**: barras de atributos, estilo de juego, dificultad, arma, ascendencias y las placas base iniciales con su icono y descripción. Vista previa animada sobre un pedestal del color de la clase y un retrato de cerca. Esos datos están en `classes.json` (`playstyle`, `difficulty`, `color`).
- **Apariencia**: complexión, estatura (baja, media, alta), 10 peinados (rapado, corto, largo, cresta, moño, hacia atrás, afro, coleta, rapado lateral, melena con flequillo), barba (tres días, completa, bigote, candado), accesorio (lentes, lentes de sol, audífonos, gorra, gorro de lana) y colores de piel, pelo, ojos, atuendo y detalles (cinturón, zapatos y accesorio). Todo sale de `CharacterAppearance`: la misma cabeza (`draw_head`) se usa en el mundo, en los retratos y en el creador, así que lo que eliges es lo que ves. Los personajes de antes reciben valores por defecto.
- **Lista de personajes**: cada tarjeta con un medallón animado y la franja del color de su clase.

## Interfaz

- **Recuadros de lo activo** (sobre la barra de habilidades): esbirros, torretas, trampas, minas, giros y pociones de utilidad, con cuántos hay y el tiempo que les queda.
- **Inventario y Habilidades** con marco de ventana (esquinas doradas, cabecera, botón de cerrar), siluetas en las ranuras vacías, zócalos DIMM y tarjetas de habilidad con nivel, experiencia y etiquetas.
- **HUD**: orbes de vida/ES y maná, café y bebida energética con cargas (vapor y burbujas cuando están listas), barra de 6 habilidades con enfriamiento y coste, experiencia y botones de menú (C, I, K, P).
- **Minimapa** (arriba a la derecha): el suelo de la zona, obstáculos, salidas, waypoint, NPCs, enemigos por rareza y botín valioso, con flechas hacia las salidas que quedan fuera de vista. Debajo, el nombre y nivel de la zona. Se oculta mientras el inventario está abierto.
- **Hoja de personaje** (C): medallón redondo animado (`CharacterPortrait`) que respira, parpadea, te sigue con la mirada, toma café, piensa (con spinner de carga), bosteza, se pone lentes de sol si su DPS es alto y suda con poca vida; el aro es del color de la clase. Barra de experiencia y tarjetas con barras que se llenan: atributos, resistencias (con el tope de 75 %), defensa (vida, escudo, maná, armadura y evasión con su efecto real, bloqueo) y ofensiva (icono de la habilidad principal, DPS grande, daño, crítico, usos por segundo). Si hay pasivas sin gastar, un botón abre el árbol.
- **Retratos**: los diálogos y las escenas usan el mismo medallón, con la boca moviéndose mientras el NPC habla; Rafa y Clara por radio salen con interferencia verde.
- **Iconos de objetos**: atlas `assets/sprites/items/items.png` generado con `tools/generate_item_icons.gd` (un icono por base, placas base, RAM por generación y pociones). Para usar arte propio, sustituye el PNG respetando la cuadrícula (mapa en `data/item_icons.json`).

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
| Técnico de Soporte | FUE | Ingeniero de Guardia, Especialista en Ciberseguridad, Administrador de Sistemas |
| Tester QA | FUE/DES | Revisor de Código, Scrum Master, Project Manager |
| Desarrolladora Frontend | DES | Ingeniera de Rendimiento, Ingeniera de Depuración, Diseñadora UX/UI |
| Ingeniera de Prompts | DES/INT | Especialista Red Team, Ingeniera de IA, Analista de Malware |
| Científico de Datos | INT | Ingeniero de Machine Learning, Analista de Big Data, Orquestador de Agentes IA |
| Ingeniero DevOps | INT/FUE | Ingeniero de Confiabilidad (SRE), Arquitecto Cloud, Release Manager |
| Desarrollador Full Stack | las tres | Arquitecto de Soluciones, Líder Técnico (Tech Lead), CTO de Startup |

(Los ids internos siguen siendo los de antes —`guerrero`, `duelista`...— para no romper los guardados.)

**Ascendencia al nivel 20**: junto al inicio de tu clase en el árbol hay un **medallón**. Al pulsarlo se abre un panel circular: hasta el nivel 20 solo se pueden ver las tres opciones; a partir de ahí se elige una (permanente). Después, el panel muestra el inicio de la ascendencia y sus pasivas alrededor: cada una cuesta un **punto de ascendencia** (1 al nivel 20, +1 a los 25 y 30). En la pantalla de pruebas del árbol se puede cambiar libremente.

## Enemigos

Nueve tipos con sprites animados (`data/enemies.json`, `assets/sprites/enemies/enemies.png`). Los nuevos tienen ataques **telegrafiados en rojo** (se ve la forma del golpe antes de que llegue) y cuerpos de distinto tamaño:

| Enemigo | Ataque | Forma del golpe |
|---|---|---|
| Bug, Proceso zombi, Memory leak, Gusano | Cuerpo a cuerpo | Contacto |
| Bot de spam | A distancia: dispara correos y mantiene la distancia | Proyectil esquivable |
| Hilo desbocado | Embestida | Rectángulo en línea recta (se para al chocar) |
| node_modules | Golpe pesado, cuerpo enorme y lento | Círculo alrededor |
| Troll de foro | Teclado en llamas | Cono delante |
| Daemon | Solo jefes | — |

**Jefe del acto (El Arquitecto del Monolito)**: menos vida que antes (×2,6 en vez de ×4) y dos habilidades, con el nombre en grande y una barra de lanzamiento:
- *git push --force*: onda de 14 proyectiles en todas direcciones (hay huecos entre ellos).
- *Merge Conflict*: cinco círculos en el suelo, uno donde estás, que explotan al segundo.
- Por debajo de la mitad de vida se recargan un 40 % más rápido.
- El atlas se genera con `tools/generate_enemy_sprites.gd` (pixel art procedural, "arte de programador"). Para usar sprites dibujados a mano, sustituye el PNG respetando la cuadrícula: columnas = 4 fotogramas, filas = tipos.
- Un shader (`assets/shaders/enemy_sprite.gdshader`) se encarga de la animación, el volteo, el contorno del color de rareza y el destello al recibir daño, todo por instancia del `MultiMesh`.

## Tokens, comerciante y alijo

- **Tokens** (Economy): la moneda. Los enemigos normales los sueltan 2 de cada 5 veces (los especiales, élites y únicos más y en más cantidad, según el nivel de la zona). Se recogen solos al pasar cerca. Se ven en el inventario (I).
- **Nacho, revendedor de hardware**, en el Campamento del Último Commit y en el Socket Seguro: vende 4 placas base y 6 módulos RAM del nivel del personaje. La mercancía cambia al subir de nivel o pagando "Renovar mercancía". También compra lo que le arrastres desde la bolsa (paga el 20 % de su precio).
- **Alijo (NAS compartido)**, junto al waypoint de los campamentos: 4 pestañas de 60 casillas, **compartido entre todos los personajes** de la cuenta (user://stash.json, se guarda en cada cambio). Arrastra entre el alijo y la bolsa, o haz click: en el alijo lo pasa a la bolsa y en la bolsa lo guarda. Los objetos clave no entran.
- El inventario ya no muestra vida, daño ni resistencias: están en la hoja de personaje (C).

## Guardado de personajes

- Un archivo JSON por personaje en `user://characters/<id>.json`. En Windows es `%APPDATA%\Godot\app_userdata\Path Overflow\characters`. Al renombrar el proyecto, los guardados de la carpeta antigua (`Exile Overflow`) se **copian** a la nueva la primera vez; la carpeta vieja no se toca.
- Se guarda **todo el personaje**: nombre, clase, ascendencia, nivel, experiencia, apariencia, pasivas, equipo, bolsa, placas y RAM, banderas (diálogos, tutorial) y tiempo jugado.
- **Autoguardado**: unos segundos después de cada cambio, cada minuto, al volver al menú y al cerrar la ventana.
- **Seguro ante cortes**: se escribe en un `.tmp` y luego se sustituye el archivo; la versión anterior queda como `.bak` y se usa si el principal está dañado.
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

## Rendimiento

Benchmark del 18-10-2026 (antes de los sprites), RTX 4050 Laptop, vsync desactivado, todos los enemigos amontonados alrededor del jugador:

| Enemigos | FPS medio | Simulación (GDScript) |
|---|---|---|
| 300 | ~1350 | 2.5 ms/tick |
| 600 | ~790 | 6.3 ms/tick |
| 1000 | ~190 | 12.3 ms/tick |

GDScript va sobrado para densidades tipo PoE (300-600). Por encima de unos 800, el siguiente paso sería portar **solo** `EnemyManager` a C# o GDExtension.

## Árbol pasivo

- **734 pasivas en 67 clusters con forma** (como en PoE 2: cada temática dibuja su símbolo: corazón para vida, llama para fuego, rayo en zigzag, copo de nieve para frío, escudo para armadura, gota para maná, mira para crítico, flecha para proyectiles, estrella para área, hexágono para escudo de energía, espiral para caos, colmillos para robo de vida, pluma para evasión, chevrons para velocidad y movilidad, reloj de arena para enfriamientos, libro para hechizos, prisma para resistencias y martillo para daño físico; los de atributos siguen siendo anillos) (7 clases: 6 alrededor y el Full Stack en el centro): cada anillo o rueda es de un solo tipo (vida, armadura, fuego, crítico, maná, robo de vida…). Sus pasivas menores son variaciones de ese tema (p. ej. vida plana, vida + regeneración, vida + armadura, % de vida) y su notable tiene nombre, texto sarcástico e icono propio. Entre clusters hay caminos de atributos, puentes temáticos entre clases vecinas y un anillo central de atributos.
- **Inicios limpios**: el inicio de cada clase solo se conecta hacia delante, a sus 4 ramas; nada llega a él por detrás ni pasa junto a él. Cada región se une al centro por sus lados, a través de los clusters *puerta* entre clases vecinas, y hay un cluster interior por clase entre el anillo central y la clase.
- **Centro**: el inicio del Full Stack, el anillo de *Versatilidad* (3 notables y su piedra angular) y el anillo central de atributos.
- **Temáticas** en `data/passive_themes.json` (21, nuevas: Versatilidad, Enfriamientos y duración, Movilidad). Para añadir pasivas o cambiar valores, edita ese archivo y regenera el árbol con `python tools/generate_passive_tree.py`.
- **Condiciones**: algunas pasivas solo cuentan con **vida baja** (≤ 50 %), **vida al máximo** o **si has matado recientemente** (4 s). Se reflejan en el tooltip ("con la vida baja") y en el combate en tiempo real.
- **Interfaz**: halo de color y nombre por cluster (con zoom intermedio), pasivas menores del color de su tema, notables y piedras angulares con icono (apagado hasta asignarlo), nombres de notables al acercar, **buscador** (resalta coincidencias; Enter salta a la siguiente; no distingue tildes) y **resumen de bonificaciones** totales en el panel lateral.
- **Iconos**: `assets/sprites/passives/passives.png`, generado con `tools/generate_passive_icons.gd` (mapa en `data/passive_icons.json`).
- **Versión del árbol**: si cambia la estructura (`TREE_VERSION` en el generador), los personajes guardados con otra versión recuperan todos sus puntos de pasiva y ven un aviso al entrar, en lugar de quedarse con nodos que ahora significan otra cosa.

## Exportar

Añade `*.json` en *Exportar → Recursos → Filtros para exportar archivos no-recurso*. Si no, los datos no se incluyen en el ejecutable.

## Próximos pasos sugeridos

1. Sprites del jugador y de los NPCs (el formato de apariencia ya está preparado).
2. Resistencias y tipos de daño en los enemigos, y enemigos (y jefe) con habilidades propias.
3. Ascendencias mediante pruebas (ahora se eligen libremente en el árbol pasivo).
4. **Acto II: Kernel Panic.** Ya está preparado el gancho (portal en el campamento, misión principal, bandera `act2_started`). Idea de zonas: Espacio de Usuario → Tabla de Procesos → Cementerio de Huérfanos (procesos zombi sindicados) → Scheduler (enemigos que se turnan) → Memoria Virtual (páginas que aparecen y desaparecen) → jefe **init (PID 1)**. Hace falta un `act2.json`, que `GameData` cargue varios actos y que el waypoint muestre los dos.
5. Editor del árbol pasivo dentro de Godot.
