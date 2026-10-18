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
| 1 / 2 | Café (vida) / Bebida energética (maná) |
| Click en un objeto o NPC | Ir a recogerlo / hablar |
| I | Inventario: arrastra para mover y equipar; click equipa o quita |
| K | Habilidades: arrastra placas a la barra y RAM a sus ranuras |
| C | Hoja de personaje (con retrato animado y opiniones no solicitadas) |
| M | Mostrar u ocultar el minimapa |
| L | Plegar o desplegar el registro de misiones |
| P | Árbol pasivo (pausa el juego) |
| Esc | Cierra lo abierto; si no hay nada, menú de pausa |
| F1 / F2 / F3 / F4 | Depuración: +30 enemigos / limpiar / jefe único / botín de prueba |
| R | Reaparecer en el waypoint del campamento tras morir |
| Click en un waypoint | Viajar a otro waypoint descubierto |

Todas las teclas están en *Proyecto → Configuración del proyecto → Mapa de entrada*. Pasa el ratón por cualquier elemento del HUD para ver una ayuda.

**Objetos**: arrastrar y soltar entre bolsa, equipo, barra de habilidades y ranuras DIMM (intercambia si hace falta; las reglas están en `ItemTransfer`). Soltar un objeto fuera de los paneles lo tira al suelo; ya no se pueden destruir con un click.

**Al lanzar habilidades** el personaje solo se detiene un instante (25 % del tiempo de uso, máximo 0,15 s); el ritmo de ataque no cambia.

**Animación al caminar**: piernas alternas que se levantan, brazos en oposición y el cuerpo sube y baja con cada paso. El ciclo avanza con la distancia recorrida de verdad, así que los pies no "patinan" y, si choca contra algo, deja de andar en el sitio. De perfil, las piernas avanzan y retroceden y el cuerpo se inclina.

`scenes/ui/passive_tree_screen.tscn` funciona sola (F6) para probar builds, y `scenes/game/world.tscn` (F6) arranca con un personaje temporal que no se guarda.

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

## Acto I: El Último Commit

El acto está definido en `data/act1.json` y lo construye `Zone` (`scripts/game/zone.gd`).

| Zona | Nivel | Waypoint | Notas |
|---|---|---|---|
| El Sandbox | 1 | | Tutorial: pocos bugs, más botín y B.O.B., el bot de onboarding |
| Campamento | 1 | ✔ | Zona segura, punto de reaparición; Ada, Kevin y Root |
| El Bosque de Cables | 2 | | Iris, la becaria perdida |
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
- **Después del jefe**: Ada te manda a hablar con Root, que cuenta que el reinicio falló con un *kernel panic* (algo llamado «init», el PID 1, vive en el Kernel) y abre el **Portal al Kernel** en el campamento. Al terminar la misión principal empieza la del Acto II (*Kernel Panic*); el portal responde con un 503 hasta que exista el Acto II.
- **NPCs y lore** en `data/npcs.json`: diálogos con opciones, condiciones (`requires_flag`) y acciones (regalos que se dan una sola vez). Cuentan la historia del administrador que hizo `push --force` "por el Monolito".
- **Tutorial** (`data/tutorial.json`, versión 2): 12 pasos. Empieza en el Sandbox (moverse, atacar, matar, recoger, equipar, pociones, pasivas) y sigue en el campamento (Ada, RAM, Kevin, salir al Bosque). Los personajes con el tutorial antiguo continúan donde corresponde.

## Misiones

Definidas en `data/quests.json` y gestionadas por `QuestLog` (lógica pura, guardada en el personaje).
El **registro de misiones** está debajo del minimapa (L para plegarlo): la principal arriba, en dorado, y las secundarias debajo, con su paso actual y el progreso.

| Misión | Quién | Qué |
|---|---|---|
| El Último Commit (principal) | — | Recorrer el acto, derrotar al Arquitecto, hablar con Ada y con Root |
| Kernel Panic (principal) | — | Empieza al acabar la anterior; preparada para el Acto II |
| Bichos en el cableado | Iris (Bosque) | Eliminar 25 enemigos en el Bosque de Cables |
| Reporte de incidencias | Tomás (Pantano) | Eliminar 3 enemigos especiales o élite en el Pantano |
| La cinta de backup | Fantasma del DBA (Granja) | Recoger la cinta en las Catacumbas del Legacy |
| Granos de café | Kevin (Campamento) | Eliminar 40 enemigos en cualquier zona |

- Tipos de paso: hablar, llegar a una zona, bandera, eliminar (con zona y rareza mínima), recoger un objeto de misión y entregar.
- Las misiones se aceptan y se entregan en los diálogos (acciones `start_quest` y `quest_advance`). Sobre los NPCs aparece un **!** amarillo si ofrecen misión y un **?** verde si tienes algo que entregarles.
- Recompensas: experiencia y objetos (`give_random` con rareza, RAM que encaja, placas…).
- Los personajes de antes se ponen al día solos: si ya mataron al jefe, la principal salta a "cuéntaselo a Ada".

## Diálogos con voz

- **Narrador**: si el sistema tiene una voz en español (en Windows: *Configuración → Hora e idioma → Voz*), los NPCs leen su texto en voz alta, cada uno con su tono y velocidad (`voice` en `npcs.json`), y el texto avanza al ritmo de la voz.
- **Pitidos retro**: sin voz (o con el narrador desactivado), sale un pitido de 8 bits cada pocas letras, con el tono de cada NPC. El sonido se genera en código (`RetroSfx`), sin archivos.
- Ambos se activan o desactivan en el menú de pausa (Esc) y se recuerdan en `user://settings.cfg`.

## Pantalla de título, menú y creador

- **Pantalla de título** (`scenes/menu/title_screen.tscn`, escena principal): logo animado de *Path Overflow* (`GameLogo`) con efecto glitch y una pila desbordándose, lluvia de binario, `console.log`s flotando, un grafo de git que termina en `push --force`, bugs cruzando, un rack de servidores echando vapor y un café.
- **Música**: `assets/audio/title_theme.wav`, generada con `tools/generate_music.gd` (bucle de ~37 s). El autoload `MusicPlayer` la mantiene sonando entre título, menú y creador; el botón "Música" la silencia y se recuerda en `user://settings.cfg`. Para usar otra música basta con sustituir el WAV.
- **Creador de personaje**: barras de atributos, estilo de juego, dificultad, arma, ascendencias y las placas base iniciales con su icono y descripción. Vista previa animada sobre un pedestal del color de la clase. Esos datos están en `classes.json` (`playstyle`, `difficulty`, `color`).

## Interfaz

- **HUD**: orbes de vida/ES y maná, café y bebida energética con cargas (vapor y burbujas cuando están listas), barra de 6 habilidades con enfriamiento y coste, experiencia y botones de menú (C, I, K, P).
- **Minimapa** (arriba a la derecha): el suelo de la zona, obstáculos, salidas, waypoint, NPCs, enemigos por rareza y botín valioso, con flechas hacia las salidas que quedan fuera de vista. Debajo, el nombre y nivel de la zona. Se oculta mientras el inventario está abierto.
- **Hoja de personaje** (C): retrato animado de pecho hacia arriba que respira, parpadea, te sigue con la mirada, toma café, piensa (con spinner de carga), bosteza, se pone gafas de sol si su DPS es alto y suda con poca vida. Incluye atributos, defensas con su efecto real (reducción de la armadura, probabilidad de esquivar), resistencias con comentarios, ofensiva de la habilidad principal, muertes, enemigos eliminados y un estado de ánimo calculado.
- **Iconos de objetos**: atlas `assets/sprites/items/items.png` generado con `tools/generate_item_icons.gd` (un icono por base, placas base, RAM por generación y pociones). Para usar arte propio, sustituye el PNG respetando la cuadrícula (mapa en `data/item_icons.json`).

## Enemigos

Cinco tipos con sprites animados: Bug, Proceso zombi, Memory leak, Gusano de red y Daemon (para jefes). Están en `data/enemies.json` y `assets/sprites/enemies/enemies.png`.
- El atlas se genera con `tools/generate_enemy_sprites.gd` (pixel art procedural, "arte de programador"). Para usar sprites dibujados a mano, sustituye el PNG respetando la cuadrícula: columnas = 4 fotogramas, filas = tipos.
- Un shader (`assets/shaders/enemy_sprite.gdshader`) se encarga de la animación, el volteo, el contorno del color de rareza y el destello al recibir daño, todo por instancia del `MultiMesh`.

## Guardado de personajes

- Un archivo JSON por personaje en `user://characters/<id>.json`. En Windows es `%APPDATA%\Godot\app_userdata\Path Overflow\characters`. Al renombrar el proyecto, los guardados de la carpeta antigua (`Exile Overflow`) se **copian** a la nueva la primera vez; la carpeta vieja no se toca.
- Se guarda **todo el personaje**: nombre, clase, ascendencia, nivel, experiencia, apariencia, pasivas, equipo, bolsa, placas y RAM, banderas (diálogos, tutorial) y tiempo jugado.
- **Autoguardado**: unos segundos después de cada cambio, cada minuto, al volver al menú y al cerrar la ventana.
- **Seguro ante cortes**: se escribe en un `.tmp` y luego se sustituye el archivo; la versión anterior queda como `.bak` y se usa si el principal está dañado.
- **Tolerante a cambios de datos**: lo que deja de existir (nodos, objetos, habilidades) se descarta al cargar en vez de romper la partida.
- **Versiones**: `save_version` 2 añadió las placas base; los guardados v1 reciben las placas iniciales de su clase al cargarse.

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
tools/                Generadores (árbol, sprites, iconos, música) y comprobador de scripts
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

- **505 pasivas en 45 clusters temáticos**: cada anillo o rueda es de un solo tipo (vida, armadura, fuego, crítico, maná, robo de vida…). Sus pasivas menores son variaciones de ese tema (p. ej. vida plana, vida + regeneración, vida + armadura, % de vida) y su notable tiene nombre, texto sarcástico e icono propio. Entre clusters hay caminos de atributos, puentes temáticos entre clases vecinas y un anillo central de atributos.
- **Temáticas** en `data/passive_themes.json` (19). Para añadir pasivas o cambiar valores, edita ese archivo y regenera el árbol con `python tools/generate_passive_tree.py`.
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
