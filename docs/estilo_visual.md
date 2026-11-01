# Guía visual · interfaz de ingeniería (T165)

La interfaz deja el latón y los remaches de antes y adopta la temática del juego: ingeniería de
software, datos e inteligencia artificial. Hay dos propuestas para elegir (o mezclar); la
elegida pasa a `UiStyle` en T166 y al HUD en T167.

Maquetas (inventario, descripción de un objeto, diálogo y HUD), dibujadas por
`scripts/ui/ui_proposals.gd` (`capture_screens -- propuestas`):

- `docs/capturas/interfaz/165_propuesta_a.png`
- `docs/capturas/interfaz/165_propuesta_b.png`

## Lo que no cambia

Los colores de rareza (normal `c8c8c8`, mágico `8888ff`, raro `ffff77`, único `af6025`, de
conjunto `1ba01b`, ultra-raro `ff5ac8`), los de cada tipo de daño y los del modo daltónico: son
lenguaje del juego y se leen igual en las dos propuestas.

## A · Terminal/IDE

| Papel | Color | Uso |
|---|---|---|
| Fondo | `0b1020` | pantalla, barra de pestañas |
| Panel | `111a2e` | ventanas |
| Panel 2 | `17223b` | casillas, teclas |
| Borde | `26345a` | marcos y rejillas |
| Acento | `3ad1e6` | pestaña activa, barra de estado, cursor, memoria |
| Éxito | `7ee787` | opciones, experiencia, comentarios `//` |
| IA | `c678dd` | claves, habilidades de IA |
| Aviso / peligro | `e3b341` / `ff7b72` | `[WARN]`, vida (integridad) |
| Texto / apagado | `dfe7f5` / `8592b0` | |

- **Tipografía**: monoespaciada en todo (títulos, números, consola); la de licencia libre se
  elige en T169.
- **Motivos**: ventanas con pestaña («inventario.json ×») y los tres puntos; números de línea
  en las listas; el equipo como un JSON; la descripción como un `.md` con los afijos en líneas
  numeradas; barra de estado de editor (rama, oro, peso); diálogo como terminal (`aida>`,
  opciones `[1]`, cursor que parpadea); vida y memoria como barras segmentadas `[████░░] 72 %`;
  habilidades como teclas (keycaps) con el barrido de enfriamiento; misiones como `TODO.md` con
  casillas; sucesos como consola `12:01 [INFO]`.
- **Sensación**: densa, técnica, «estoy dentro del servidor».

## B · Panel de monitoreo/datos

| Papel | Color | Uso |
|---|---|---|
| Fondo | `0e1116` | con rejilla de puntos |
| Panel | `161b22` | tarjetas |
| Panel 2 | `1d2430` | filas, casillas |
| Borde | `2d3646` | |
| Acento | `2dd4bf` | radar, memoria, gráficas |
| Éxito | `3fb950` | experiencia, misiones hechas |
| IA | `a371f7` | separadores de red neuronal, etiquetas |
| Aviso / peligro | `f59e0b` / `f85149` | DPS, vida |
| Texto / apagado | `e6edf3` / `8b949e` | |

- **Tipografía**: la sans de siempre para títulos y textos; monoespaciada solo para números.
- **Motivos**: tarjetas planas con esquinas redondeadas y un grafo de tres nodos en la esquina;
  separadores con una red neuronal; gráficas mini (sparklines) en el equipo y el DPS; vida y
  memoria como medidores circulares con marcas; radar con anillos y barrido; retrato del NPC
  en un círculo; opciones como botones-píldora; sucesos como tarjetas con punto de color.
- **Sensación**: limpia, de un vistazo, «panel de control del servidor».

## Reglas para las dos

- Contraste de texto y de texto apagado contra el panel ≥ 4,5:1 (WCAG); lo comprueba
  `tests/test_core.gd`.
- Tamaño mínimo de letra: `UiStyle.MIN_FONT_SIZE` (revisión en T169, celular al 140 %).
- En el celular, los botones táctiles conservan el hundido, el barrido de enfriamiento y el azul
  de «sin maná» (T148).
- Mezclas posibles: p. ej. ventanas y diálogo de A con los medidores y el radar de B.
