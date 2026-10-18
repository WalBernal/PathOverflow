# Exile Overflow (nombre provisional)

ARPG estilo Path of Exile en **Godot 4.7**, de ambientación oscura y con sarcasmo de programador.
Por ahora es solo para un jugador en local, pero la lógica está escrita para poder pasar a un modelo cliente-servidor en el futuro.

## Cómo abrirlo

1. Abre Godot 4.7.2 → **Importar** → selecciona `project.godot`.
2. Pulsa **F5**. Se abre la pantalla de inicio: crea un personaje (clase, apariencia y nombre) o elige uno guardado.
3. En el juego, **Esc** abre el menú de pausa (volver al menú o salir, guardando).

| Tecla | Acción |
|---|---|
| WASD / mantener click izq. | Mover |
| Espacio / click der. | Atacar ("Barrido", golpe en área con el arma equipada) |
| Click en un objeto del suelo | Ir a recogerlo |
| I | Inventario: click izq. equipa o quita, click der. destruye |
| P / Esc | Árbol pasivo (pausa el juego) |
| F1 / F2 / F3 | +100 enemigos / limpiar / jefe único |
| F4 | Botín de prueba: una muestra de cada rareza |
| R | Reaparecer tras morir |

Todas las teclas están en *Proyecto → Configuración del proyecto → Mapa de entrada*.

`scenes/ui/passive_tree_screen.tscn` también funciona sola (F6) para probar builds de cualquier clase y nivel, y `scenes/game/world.tscn` (F6) arranca con un personaje temporal que no se guarda.

## Guardado de personajes

- Un archivo JSON por personaje en `user://characters/<id>.json`. En Windows es `%APPDATA%\Godot\app_userdata\Exile Overflow\characters`.
- Se guarda **todo el personaje**: nombre, clase, ascendencia, nivel, experiencia, apariencia, pasivas, equipo, bolsa y tiempo jugado.
- **Autoguardado**: unos segundos después de cada cambio (subir de nivel, objetos, pasivas), cada minuto, al volver al menú y al cerrar la ventana.
- **Seguro ante cortes**: se escribe en un `.tmp` y luego se sustituye el archivo; la versión anterior queda como `.bak` y se usa si el principal está dañado.
- **Tolerante a cambios de datos**: si un nodo del árbol u objeto deja de existir, se descarta al cargar (los puntos de pasiva vuelven al jugador) en lugar de romper la partida. El campo `save_version` permite migrar formatos antiguos.
- La apariencia se guarda como índices de estilo + colores, el mismo formato que usarán los sprites por capas.

## Estructura

```
data/                 Datos de diseño (JSON): clases, ascendencias, árbol pasivo
data/items/           Bases, afijos (con tiers), únicos y conjuntos
scripts/core/         Stat, Modifier, StatBlock (fórmula de PoE), DataLoader
scripts/passives/     PassiveTree (datos), PassiveAllocation (por personaje), PassiveTreeView (dibujo)
scripts/character/    CharacterData (personaje), CharacterSaves (archivos), CharacterAppearance
scripts/items/        Rarity, ItemDatabase, Item, ItemGenerator, Inventory
scripts/game/         World, Player, EnemyManager, LootManager, IsoGround
scripts/ui/           Menú de inicio, creador, HUD, inventario, tooltips, árbol pasivo, UiStyle
scenes/menu/          Pantalla de inicio y creación de personaje
scripts/autoload/     GameData: carga los datos estáticos una vez
scenes/               Escenas (.tscn)
tools/                Scripts externos (generador del árbol de prueba)
tests/                Pruebas de la lógica pura
assets/               Sprites, UI, audio, fuentes
```

## Decisiones de arquitectura

- **Todo es un `Modifier`.** El árbol, las ascendencias, los objetos y, más adelante, las gemas y las auras de enemigos producen el mismo tipo de dato. Añadir contenido es añadir datos, no código.
- **Fórmula de PoE** en `StatBlock`: `(base + planos) × (1 + Σaumentos) × Π(más)`. Los tags (`spell`, `melee`, `projectile`…) permiten modificadores condicionales. Los stats padre (`damage` → `elemental_damage` → `fire_damage`) heredan aumentos.
- **Lógica separada de los nodos.** `StatBlock`, `PassiveAllocation`, `CharacterData`, `Item`, `ItemGenerator` e `Inventory` son `RefCounted` puros. Así se pueden probar sin escena y, si algún día hay servidor, moverlos allí.
- **El árbol se dibuja en un solo `_draw()`**, con descarte por viewport y una rejilla espacial para el hover. Está pensado para más de 1000 nodos.
- **Enemigos orientados a datos** (`EnemyManager`): un solo nodo con arrays empaquetados, una rejilla espacial para separarlos y un `MultiMesh` para dibujarlos en una sola llamada.
- **Datos estáticos compartidos** (`PassiveTree`, `ItemDatabase`) frente a **estado por personaje** (`PassiveAllocation`, `Inventory`).

## Objetos

| Rareza | Afijos | Notas |
|---|---|---|
| Normal | 0 | Solo implícitos de la base |
| Mágico | 1-2 (máx. 1 prefijo + 1 sufijo) | Nombre: base + prefijo + sufijo |
| Raro | 3-6 (máx. 3 + 3) | Nombre aleatorio ("Tormento del Kernel") |
| Ultra-raro | 7-8 (máx. 4 + 4) | Siempre el mejor tier disponible para su nivel |
| Único | Fijos, con rango | Definidos en `uniques.json`, con texto de ambientación |
| De conjunto | Fijos + bonus por piezas | Definidos en `sets.json` |

- **Tiers**: cada afijo tiene tiers con nivel mínimo y peso; el nivel del objeto decide cuáles pueden salir. En el tooltip, `(P T1)` significa prefijo del mejor tier.
- **Mods locales** (`local_*`): modifican la propia base (daño del arma, defensas de la armadura) en vez de sumarse al personaje, como en PoE.
- **Botín**: cada enemigo tiene probabilidad y número de objetos según su rareza, y los élites y únicos tienen bonus de rareza (`Rarity.ENEMY_INFO`). El nivel de los monstruos, y con él el de los objetos, sigue al nivel del personaje.
- **Comparación**: el tooltip de un objeto no equipado muestra cómo cambiarían el DPS, la vida, las defensas y las resistencias al equiparlo.
- Los objetos ya tienen `to_dict()`/`from_dict()`, preparados para el sistema de guardado.

## Pruebas

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/test_core.gd
```

Comprueban:
- la fórmula de stats;
- los caminos del árbol y los reembolsos;
- la experiencia y los enemigos;
- el mapa de entrada;
- la integridad de todos los JSON;
- la generación de 1200 objetos (límites de afijos, sin grupos repetidos, tiers según nivel, reproducibilidad con semilla);
- los mods locales, el equipo y los anillos, la vista previa al equipar y los bonus de conjunto.

## Rendimiento (benchmark, 18-10-2026)

RTX 4050 Laptop, vsync desactivado, todos los enemigos amontonados alrededor del jugador (el peor caso):

| Enemigos | FPS medio | Peor frame | Simulación (GDScript) |
|---|---|---|---|
| 300 | ~1350 | 1.4 ms | 2.5 ms/tick |
| 600 | ~790 | 2.1 ms | 6.3 ms/tick |
| 1000 | ~190 | 26.5 ms | 12.3 ms/tick |
| 1500 | ~8 | 144 ms | 20.9 ms/tick |

Conclusión: GDScript va sobrado para densidades tipo PoE (300-600 enemigos). Por encima de unos 800, la simulación pasa de 16 ms por tick y el juego colapsa. Si hace falta más, el siguiente paso es portar **solo** `EnemyManager` a C# o a GDExtension.

## Árbol de prueba

`data/passive_tree.json` se genera con `python tools/generate_passive_tree.py`. Son 195 nodos: 5 inicios, 18 notables y 5 piedras angulares.
Es un generador de prototipo. El siguiente paso natural es un **editor del árbol dentro de Godot** (plugin `@tool`) para colocar nodos a mano.

## Exportar

Añade `*.json` en *Exportar → Recursos → Filtros para exportar archivos no-recurso*. Si no, los datos no se incluyen en el ejecutable.

## Próximos pasos sugeridos

1. Habilidades activas (gemas) que consulten `StatBlock` con sus tags, y coste de maná.
2. Sprites del personaje por capas (decidir antes: 2D a mano o 3D prerenderizado); el formato de apariencia ya está preparado.
3. Ascendencia mediante pruebas (ahora se elige libremente en el árbol pasivo).
4. Iconos de objetos e inventario por cuadrícula con tamaños (2×3, 1×1…) como en PoE.
5. Editor del árbol pasivo dentro de Godot.
