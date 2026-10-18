# Exile Overflow (nombre provisional)

ARPG estilo Path of Exile en **Godot 4.7**, de ambientación oscura y con sarcasmo de programador.
Por ahora es solo para un jugador en local, pero la lógica está escrita para poder pasar a un modelo cliente-servidor en el futuro.

## Cómo abrirlo

1. Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`.
2. Pulsa **F5**. Se abre la pantalla de inicio: crea un personaje (clase, apariencia y nombre) o elige uno guardado.
3. Empiezas en el **Campamento del Último Commit**, una zona segura con NPCs. El tutorial (arriba a la izquierda) te guía; se puede saltar.

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
| P | Árbol pasivo (pausa el juego) |
| Esc | Cierra lo abierto; si no hay nada, menú de pausa |
| F1 / F2 / F3 / F4 | Depuración: +100 enemigos / limpiar / jefe único / botín de prueba |
| R | Reaparecer en el campamento tras morir |

Todas las teclas están en *Proyecto → Configuración del proyecto → Mapa de entrada*. Pasa el ratón por cualquier elemento del HUD para ver una ayuda.

**Objetos**: arrastrar y soltar entre bolsa, equipo, barra de habilidades y ranuras DIMM (intercambia si hace falta; las reglas están en `ItemTransfer`). Soltar un objeto fuera de los paneles lo tira al suelo; ya no se pueden destruir con un click.

**Al lanzar habilidades** el personaje solo se detiene un instante (25 % del tiempo de uso, máximo 0,15 s); el ritmo de ataque no cambia.

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

## Campamento, NPCs y tutorial

- **Zona segura**: los enemigos no entran ni persiguen dentro. Fuera aparecen grupos continuamente; los que quedan muy lejos desaparecen.
- **NPCs** (`data/camp.json`): Ada la Senior (te explica las habilidades y te da una RAM que encaja en tu primera placa), Kevin el Becario (rellena las pociones) y Root el SysAdmin (lore y una placa de regalo). Los diálogos tienen opciones con condiciones y acciones; los regalos se dan una sola vez (banderas guardadas en el personaje).
- **Tutorial** (`data/tutorial.json`): 11 pasos con condiciones que se comprueban solas. El progreso se guarda por personaje y se puede saltar.

## Interfaz

- **HUD**: orbes de vida/ES y maná, café y bebida energética con cargas (vapor y burbujas cuando están listas), barra de 6 habilidades con enfriamiento y coste, experiencia y botones de menú (C, I, K, P).
- **Minimapa** (arriba a la derecha): campamento, NPCs, enemigos por rareza, botín valioso y una flecha hacia el campamento cuando queda fuera de vista. Se oculta mientras el inventario está abierto.
- **Hoja de personaje** (C): retrato animado de pecho hacia arriba que respira, parpadea, te sigue con la mirada, toma café, piensa (con spinner de carga), bosteza, se pone gafas de sol si su DPS es alto y suda con poca vida. Incluye atributos, defensas con su efecto real (reducción de la armadura, probabilidad de esquivar), resistencias con comentarios, ofensiva de la habilidad principal, muertes, enemigos eliminados y un estado de ánimo calculado.
- **Iconos de objetos**: atlas `assets/sprites/items/items.png` generado con `tools/generate_item_icons.gd` (un icono por base, placas base, RAM por generación y pociones). Para usar arte propio, sustituye el PNG respetando la cuadrícula (mapa en `data/item_icons.json`).

## Enemigos

Cinco tipos con sprites animados: Bug, Proceso zombi, Memory leak, Gusano de red y Daemon (para jefes). Están en `data/enemies.json` y `assets/sprites/enemies/enemies.png`.
- El atlas se genera con `tools/generate_enemy_sprites.gd` (pixel art procedural, "arte de programador"). Para usar sprites dibujados a mano, sustituye el PNG respetando la cuadrícula: columnas = 4 fotogramas, filas = tipos.
- Un shader (`assets/shaders/enemy_sprite.gdshader`) se encarga de la animación, el volteo, el contorno del color de rareza y el destello al recibir daño, todo por instancia del `MultiMesh`.

## Guardado de personajes

- Un archivo JSON por personaje en `user://characters/<id>.json`. En Windows es `%APPDATA%\Godot\app_userdata\Exile Overflow\characters`.
- Se guarda **todo el personaje**: nombre, clase, ascendencia, nivel, experiencia, apariencia, pasivas, equipo, bolsa, placas y RAM, banderas (diálogos, tutorial) y tiempo jugado.
- **Autoguardado**: unos segundos después de cada cambio, cada minuto, al volver al menú y al cerrar la ventana.
- **Seguro ante cortes**: se escribe en un `.tmp` y luego se sustituye el archivo; la versión anterior queda como `.bak` y se usa si el principal está dañado.
- **Tolerante a cambios de datos**: lo que deja de existir (nodos, objetos, habilidades) se descarta al cargar en vez de romper la partida.
- **Versiones**: `save_version` 2 añadió las placas base; los guardados v1 reciben las placas iniciales de su clase al cargarse.

## Estructura

```
data/                 Datos de diseño (JSON): clases, árbol, enemigos, campamento, tutorial
data/items/           Bases, afijos (con tiers), únicos y conjuntos
data/skills/          Habilidades (placas base) y módulos RAM
scripts/core/         Stat, Modifier, StatBlock (fórmula de PoE), DataLoader
scripts/passives/     PassiveTree, PassiveAllocation, PassiveTreeView
scripts/character/    CharacterData, CharacterSaves, CharacterAppearance
scripts/items/        Rarity, ItemDatabase, Item, ItemGenerator, Inventory, ItemTransfer, ItemIcons
scripts/skills/       SkillDatabase, Motherboard, RamModule, SkillCalc
scripts/game/         World, Player, SkillController, EnemyManager, LootManager, Camp, IsoGround
scripts/ui/           Menús, HUD, inventario, habilidades, diálogos, tutorial, tooltips, UiStyle
scripts/autoload/     GameData: datos estáticos y personaje actual
scenes/               Escenas (.tscn)
assets/               Sprites, shaders, UI, audio, fuentes
tools/                Generadores (árbol, sprites de enemigos, iconos) y comprobador de scripts
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

## Exportar

Añade `*.json` en *Exportar → Recursos → Filtros para exportar archivos no-recurso*. Si no, los datos no se incluyen en el ejecutable.

## Próximos pasos sugeridos

1. Sprites del jugador y de los NPCs (el formato de apariencia ya está preparado).
2. Resistencias y tipos de daño en los enemigos, y enemigos con habilidades propias.
3. Ascendencias mediante pruebas (ahora se eligen libremente en el árbol pasivo).
4. Más zonas fuera del campamento (mapas con TileMapLayer isométrico).
5. Editor del árbol pasivo dentro de Godot.
