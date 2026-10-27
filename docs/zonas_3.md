# Zonas que se generan solas — diseño (T114)

Borrador para la revisión 🛑 antes de T115-T117. Prototipo: `scripts/game/zone_layout.gd` (`ZoneLayout`), que todavía **no usa el juego**. Se ve con:

```
Godot --path . res://tools/capture_screens.tscn -- semillas
```

Deja en `user://capturas/` una imagen por zona con 5 semillas en fila (`114_semillas_<zona>.png`) y una hoja con todas (`114_semillas_todas.png`); copia en `docs/capturas/zonas_3/`. Colores: suelo del estilo, **verde** entradas, **amarillo** salidas, **azul** waypoint, **magenta** NPC, objetos de misión y pruebas.

## Hoy

`Zone.setup` siembra con `hash(id)`: la zona es siempre un rectángulo con los cuatro bordes ondulados (`_build_edges`), accidentes y obstáculos sueltos que dejan libre un pasillo recto entre los puntos de interés (`_key_path`), todo en las posiciones fijas de `act*.json`. Por eso cada visita se siente igual: mismo contorno, mismo camino de izquierda a derecha y mismos sitios para todo.

## Qué cambia en cada instancia y qué se queda

| Cambia | Se queda fijo |
|---|---|
| Tamaño (±15 % en cada eje) | Qué zonas hay y cómo se encadenan (salida *X* lleva a la zona *Y*) |
| Forma: plantilla del estilo y su contenido | El **lado** por el que sale cada salida (si estaba a la derecha, sigue a la derecha) |
| Dónde cae cada salida a lo largo de su lado (±25 %) | Estilo, nivel, enemigos posibles, densidad media y experiencia de la zona |
| Dónde está el waypoint (entre la entrada y la salida, con desvío) | NPC, objetos de misión, pruebas de estrés y objetos clave (existen siempre) |
| Dónde están los NPC, objetos de misión y pruebas (cada uno en un rincón propio, lejos del resto) | **Campamentos**, **arenas de jefe**, **incidentes** del atlas y el **tutorial** (no se generan) |
| Obstáculos, accidentes, decorado, cajas y manadas (T117) | |

## Representación: una rejilla de celdas

El prototipo trabaja con una **rejilla de 80 px** (una zona de acto I sale de ~60×40 celdas): cada celda es suelo o muro. Con el contorno de cuatro bordes que hay hoy no se pueden hacer salas, pasillos ni rodeos; con la rejilla sí, y se puede comprobar que todo está conectado con un relleno por inundación.

Lo que habrá que adaptar en T115 para que el resto del juego la entienda:
- **Colisión y lo transitable** (`Zone.is_walkable`, `clamp_to_walkable`, `free_spot_near`): consultar la celda en vez de las profundidades del borde. Los muros se agrupan en rectángulos (o polígonos por *marching squares*) para la colisión física.
- **Dibujo**: el suelo de `ZoneArt` ya va por celdas de baldosa; el contorno (`_draw_edge_strip`, la banda del borde de T105) pasa a dibujarse a lo largo de cada frontera suelo/muro, y el muro con el estilo del borde de la zona (racks, roca, agua, muralla, lava, maleza, vacío).
- **Minimapa y mapa grande**: dibujar la rejilla (es más barato que hoy).
- **Enemigos** (`EnemyManager.walk_clamp`) y **botín** (`placement_check`): ya preguntan a la zona; no cambian.

## Plantillas de forma

Cada estilo tiene una o dos (la primera sale el 65 % de las veces):

| Plantilla | Cómo se hace | Estilos |
|---|---|---|
| **Salas y pasillos** | 6-9 salas rectangulares que no se tocan, unidas por pasillos en L (árbol mínimo + 1-2 atajos que cierran un bucle) | ruinas, catacumbas, fábrica, alcantarillas, ROM, grieta, servidores, BIOS, kernel, vga16 |
| **Cueva orgánica** | Relleno al azar suavizado (autómata celular, 6 pasadas); las columnas sueltas de menos de 10 celdas se rellenan | bosque, pantano, fosa, grieta, ROM, frío, alcantarillas |
| **Plaza con islas** | Todo suelo con islas de muro (lagos, colinas, chatarra) según el área | bosque, pantano, ruinas, frío, anillo, kernel, silicio, setup, bus, sandbox, flash |
| **Pasillos de racks** | Filas de muro con huecos desplazados (laberinto suave) y 1-3 claros para pelear | servidores, terminal, BIOS, setup, bus, silicio, fábrica, vga16 |

Salvo las salas, todas llevan **mordiscos en el contorno** (del tamaño proporcional a la zona) para que no se lea el rectángulo.

## Cómo se genera (en orden)

1. Semilla de la instancia (T118: nueva al entrar a una zona sin instancia viva; se guarda 10 minutos). Misma semilla → misma zona.
2. Tamaño: ±15 % por eje (60 %), o **larga** (+20-30 % de largo, −5-15 % de ancho; 20 %) o **ancha** (al revés; 20 %), T116. Plantilla del estilo.
3. Rellenar la rejilla con la plantilla; mordiscos en el contorno.
4. **Salidas**: cada una en su lado, a lo largo de él con ±25 % de lo que tenía en el diseño y a 10 celdas o más de otra salida del mismo lado.
5. **Entradas**: cada una junto a la salida que tenía más cerca en el diseño (por ahí se llega); la del waypoint, junto al waypoint.
6. **Waypoint** entre la primera y la última salida (35-65 % del camino) con un desvío lateral.
7. **NPC, objetos de misión, pruebas y objetos clave**: cada uno en la celda de suelo más lejana de todo lo anterior entre 60 al azar (su «rincón»).
8. **Rodeo** (T116, 30 %): una cresta de muro de 2 celdas cruza la zona de lado a lado, perpendicular a la marcha y lejos de los puntos clave, con un solo paso de 5 celdas en un extremo.
9. **Conectar**: un claro alrededor de cada punto clave y pasillos de 3 celdas entre todos (árbol mínimo) por el camino más barato (`AStarGrid2D`, T116): el suelo de la plantilla cuesta 1, cavar muro 8 y la cresta del rodeo 80. Así el pasillo va por la cueva o entre los racks en vez de abrir una zanja recta, y solo se cava donde la plantilla había cerrado el paso.
10. Lo que no se alcanza desde la primera entrada pasa a muro (no quedan bolsas cerradas donde aparezcan enemigos).

## Garantías (comprobadas)

`ZoneLayout.check()` y la prueba `_test_zone_layout` en `test_core`:
- Todo punto clave está sobre suelo y se llega a él desde la primera entrada.
- Ninguna salida queda pegada a la entrada principal (salvo la suya).
- Cada salida conserva su lado; la misma semilla da la misma zona y dos semillas, zonas distintas.

Prototipo con las 22 zonas que se generan × 5 semillas (110 disposiciones): **0 fallos**; plantillas usadas: cueva 26, plaza 21, salas 30, racks 33; suelo entre el 28 % (salas) y el 66 % (racks); **12 ms de media** por zona, 66 ms la más lenta (cabe en la pantalla de carga).

## Lo que no hace todavía (T115-T117)

- No coloca obstáculos, accidentes, decorado, cajas ni manadas (T115 y T117: se repartirán por las celdas de suelo con las mismas reglas de hoy).
- No hay salas temáticas («set pieces», T123) ni la sala propia de un NPC con su decorado; de momento el NPC solo va a un rincón.
- Las escenas al entrar (`cutscene_on_enter`) y los eventos no dependen de la posición; los objetos de misión sí, y van a su rincón.

## Preguntas para la revisión

1. **¿Las cuatro plantillas encajan** con lo que esperas? ¿Algún estilo con otra (p. ej. alcantarillas solo con salas, servidores solo racks)?
2. **Tutorial**: lo he dejado fijo. ¿Prefieres que también cambie?
3. **Tamaño**: ±15 % por eje. ¿Más variación (zonas claramente más grandes o más pequeñas) o menos?
4. **Proporción de suelo**: las salas dejan mucho muro (~30 % de suelo), los racks casi todo suelo. ¿Igualarlas, o que se sientan distintas?
5. **Waypoint**: siempre entre la entrada y la salida. ¿O a veces en un rincón (hay que buscarlo)?
6. **Muros**: ¿se dibujan como el borde de la zona (racks, roca, agua…) o quieres paredes propias por estilo?
