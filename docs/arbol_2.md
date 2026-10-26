# Árbol pasivo 2.0 — diseño (T88)

Propuesta para revisar antes de construirlo (T89-T94). El prototipo de la disposición
está en `tools/generate_passive_tree_v2.py` → `data/passive_tree_v2_layout.json` (el
juego no lo usa todavía) y se ve con `capture_screens.tscn -- arbol2`
(capturas `88_arbol2_entero`, `88_arbol2_region_guerrero` y `88_arbol2_centro`).

## Cifras

| | Árbol anterior (v7) | Prototipo (T88) | Árbol 2.0 (T89, v8) |
|---|---|---|---|
| Nodos | 716 | 1540 | 1373 |
| Nodos en clusters | ~450 | 853 | ~1020 |
| Nodos de viaje | ~180 | 687 | 354 |
| Notables | 72 | 126 | 149 |
| Maestrías | 8 | 18 (huecos) | 18 |
| Piedras angulares | 7 (+4 de cluster) | 6 (huecos) | 11 (20-24 con T92) |
| Clusters | 67 | 114 | 138 (131 sin contar los de piedra angular) |
| Constelaciones | 3 | 6 | 6-8 |

Los nodos de viaje del prototipo son demasiados (45 %): en T89 los anillos se acercan
y se añaden ~20 clusters pequeños en los huecos, para que viajar sea una parte menor
y los caminos lleven a algo cada pocos pasos.

## Estructura

- **Centro**: el inicio del Full Stack, un anillo de viaje de 18 nodos y un **anillo
  interior de 12 clusters** (6 hacia las clases y 6 hacia las fronteras) con familias
  de cualquier build: maná, vida, atributos, resistencias, escudo, versatilidad,
  tiempos, área, robo de vida y movilidad.
- **6 regiones de clase** de 60° cada una, en el mismo orden de ahora (vecinas que
  comparten atributo: Guerrero FUE · Duelista FUE/DES · Exploradora DES · Hacker DES/INT ·
  Hechicero INT · Templario INT/FUE). Cada región tiene cuatro anillos:
  - **A** (junto al inicio): el **corazón** de la clase (cluster XL de su estilo, con
    maestría y dos notables; aquí va su notable de estilo de T84) y dos medianos.
  - **B**: dos pequeños y dos medianos.
  - **C**: dos grandes (maestría y dos notables) y dos medianos.
  - **D** (borde): la piedra angular de la clase entre dos pequeños.
  - El inicio de la clase **solo conecta hacia fuera** (como ahora): a la región se
    llega desde el centro por las puertas y el anillo interior, no por detrás del inicio.
- **12 puertas**: dos clusters medianos en cada frontera entre regiones vecinas, con
  familias de las dos (hemorragia, toxinas, criogenia, sobrecarga, legión…), para que
  las clases híbridas tengan por dónde mezclar.
- **Anillo exterior de 6 constelaciones** (estrella de 5 puntas, 11 nodos), una en cada
  frontera, que piden dos atributos (o los tres): Pentester (FUE+DES), Hacker Ético
  (DES+INT), Arquitecto (INT+FUE), Full Stack (los tres), Rubber Duck (DES+INT) y
  Pager de Guardia (INT+FUE). Bonos que crecen al completarlas.
- **Conexiones**: los clusters se unen por el grafo de Gabriel de sus centros (cada uno
  con sus vecinos más cercanos y sin que los caminos se crucen), con nodos de viaje
  cada ~85 px. Todo el árbol queda conectado y sin nodos encimados (lo comprueba el
  generador).

## Formas de cluster

| Tamaño | Nodos | Formas | Contenido |
|---|---|---|---|
| S | 4 | rombo, cadena curva | 3 menores y un notable pequeño en la punta |
| M | 7 | rueda (6 alrededor del notable), estrella (notable y 3 radios de 2) | 6 menores y un notable |
| L | 14 | panal: maestría en el centro, anillo de 6 y anillo exterior de 7 abierto por un lado | 11 menores, 2 notables y una maestría |
| XL | 17 | panal con anillo exterior de 10 (corazón de la clase) | 14 menores, 2 notables (uno de estilo) y una maestría |
| C | 11 | estrella de 5 puntas | 10 menores y el notable de la constelación |
| K | 2 | piedra angular con un nodo de entrada | |

Los menores suben de valor del pequeño al grande (un +6 % en S, +8 % en L) y los
notables de un mismo tamaño no se repiten en todo el árbol.

## Familias

Las 28 de ahora se mantienen y cada una tendrá **al menos 4 clusters** de tamaños
distintos (T90). Reparto previsto por región (en orden: corazón primero):

| Región | Familias |
|---|---|
| Guerrero (FUE) | vida, armadura, físico, hemorragia, resistencias, robo de vida, legión |
| Duelista (FUE/DES) | velocidad de ataque, físico, crítico, hemorragia, evasión, robo de vida, movilidad |
| Exploradora (DES) | proyectiles, evasión, crítico, toxinas, movilidad, velocidad de ataque, frío, tiempos |
| Hacker (DES/INT) | caos, toxinas, crítico, lanzamiento, evasión, escudo, rayo, tiempos, maná |
| Hechicero (INT) | lanzamiento, fuego, frío, rayo, maná, escudo, ignición, criogenia, sobrecarga, área |
| Templario (INT/FUE) | automatización, legión, escudo, área, maná, armadura, fuego, resistencias, tiempos |
| Centro | maná, vida, atributos, resistencias, escudo, versatilidad, tiempos, área, robo de vida, movilidad |
| Puertas | hemorragia, resistencias, toxinas, movilidad, criogenia, sobrecarga, maná, ignición, legión, automatización, armadura, atributos |

En el prototipo, ignición, criogenia, sobrecarga y caos tienen 2 clusters y
versatilidad 1: T90 los completa con los clusters pequeños nuevos.

### Familia de maná (T91)

Seis clusters en el prototipo (Hechicero, Templario, Hacker, centro y puertas), con:

- **Regeneración plana** de maná por segundo (stat nuevo `mana_regen_flat`, que se suma
  a la base del 1,75 % del maná sin reservar).
- **% de aumento de la regeneración base** (el `mana_regen` de ahora, con su nombre claro).
- **Maná máximo** plano y en %.
- **Daño que se lleva el maná antes que la vida** (stat nuevo `damage_taken_from_mana`,
  en %, como Mente sobre Materia): el golpe se reparte; si no queda maná, lo que falta va
  a la vida.
- Maná al golpear y al matar, coste reducido y eficiencia de reserva.
- Notables: «Caché caliente» (más regeneración si no lanzaste nada en 2 s), «Sobrecarga
  de buffer» (el maná por encima del 90 % da daño), «Swap a maná» (un % del daño al maná
  solo con el maná por encima de la mitad).

## Piedras angulares (T92)

Las 7 de siempre, las 4 de cluster de T84 como piedras de verdad y 10-13 nuevas (cada
una con ventaja, contra, texto de humor y su regla en el código). Sitios: la del borde
de cada región (anillo D), dos en las puntas de los clusters grandes del anillo C de
cada región, dos en el centro y alguna en las puertas.

Ideas: Mente sobre Materia (40 % del daño al maná; sin regeneración de vida) · Pago por
Uso (las habilidades cuestan vida en vez de maná) · Batería Externa (el escudo protege el
maná, no la vida) · Zero Trust (sin críticos; el daño normal ×1,4) · Monorepo (todas las
habilidades comparten un enfriamiento corto) · Caché Fría (primer golpe a cada enemigo
×2, los siguientes -20 %) · Contenedor Efímero (invocaciones de dos en dos, duran la
mitad) · Rubber Duck (un aliado cerca te cura; sin aliados, -15 % de vida) · Legacy Code
(los objetos de nivel bajo cuentan como de tu nivel) · Pair Programming (+1 compañero; tu
daño -20 %).

## Ids estables y migración (T89)

- Cada nodo tiene una **clave** que no depende del orden de generación:
  `<region>.<anillo><hueco>:<n>` en los clusters (`guerrero.C1:5`), `via:<a>-<b>:<k>` en
  los caminos, `start.<clase>` en los inicios, `centro.I<k>:<n>`, `puerta.<clase><k>:<n>`
  y `constelacion.<k>:<n>`. Las maestrías, la identidad (estilo, piedras, constelaciones),
  el planificador y los guardados usarán la clave, así que cambiar el generador no rompe
  nada que no se haya movido.
- `TREE_VERSION` 8. Un personaje guardado con el árbol 7 recupera todos sus puntos con un
  aviso («El árbol cambió: tienes N puntos para repartir») y la primera reasignación es
  gratis. El código de build pasa a `PO2:` (un `PO1:` avisa de que es del árbol viejo).
- La vista del árbol tiene que aguantar ~1500 nodos: rejilla espacial (ya existe), recorte
  por pantalla y nivel de detalle por zoom (T94), con una prueba de tiempo de dibujo.

## Para decidir

1. Tamaño: ¿~1500 nodos está bien o se prefiere algo intermedio (~1100)?
2. Estructura: ¿regiones por anillos (A-D) con corazón, puertas y constelaciones fuera?
3. Constelaciones: ¿seis en el anillo exterior, o alguna dentro de las regiones?
4. Migración: ¿devolver todos los puntos (lo propuesto) o intentar conservar lo que se
   pueda trasladar?
5. Piedras angulares: ¿las ideas de arriba van bien, o hay alguna que no encaje?
