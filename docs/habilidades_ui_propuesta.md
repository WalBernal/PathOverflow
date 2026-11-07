# Pantalla de habilidades y RAM: diagnóstico y propuestas (T228)

Capturas de hoy (personaje de nivel 30 con seis placas, RAM instaladas, una ranura libre y la
bolsa con placas y RAM sueltas): `docs/capturas/interfaz/228_hoy_pc.png`,
`228_hoy_pc_ram_elegida.png`, `228_hoy_tactil.png` y `228_hoy_tactil_ram_elegida.png`.

## Dónde se atasca alguien nuevo

1. **El mismo diseño en PC y celular.** En el celular caben dos placas y media de seis; hay que
   desplazar para ver el resto, y la bolsa queda en una franja de dos filas al fondo.
2. **Gestos ocultos.** Arrastrar y soltar, doble clic («a la primera ranura») y clic derecho
   («quitar placa»). En el dedo no hay clic derecho ni «pasar por encima», y nada en pantalla
   dice que esos gestos existen.
3. **Qué hace cada RAM solo está en el tooltip.** En la bolsa y en las ranuras las RAM son
   iconos sin nombre; en el celular no hay forma cómoda de leerlas.
4. **Al elegir una RAM, el aviso no dice qué hacer.** La ayuda se sustituye por una frase larga
   («funciona con Ráfaga, Drones, Robot...») y cada placa dice «no hay ranura DDR3 libre», sin
   sugerir cambiarla por otra RAM ni cuál sería mejor.
5. **Colores que se pisan.** El verde de «aquí funciona» es el mismo verde de las ranuras DDR4.
6. **Ranuras estrechas.** Las DIMM miden 34×50 y no dicen qué módulo tienen.
7. **No se ve la mejora antes de instalar.** El cambio de DPS solo aparece con «Comparar».
8. **Las teclas Q W E R T Y** no significan nada en el celular.
9. **Ayuda en párrafo** arriba del todo, en letra pequeña.

## Propuesta A · Placa a placa (`228_propuesta_a_pc.png`, `228_propuesta_a_tactil.png`)

- Izquierda: las seis placas, compactas (icono, nombre, tecla y un punto por ranura del color de
  su generación, lleno si tiene RAM).
- Centro: la placa elegida en grande, con cada ranura como tarjeta: generación, módulo, nombre y
  qué hace en una frase. Al tocar una ranura: «Quitar». Debajo, botones visibles: cambiar tecla,
  comparar, variante y quitar placa.
- Derecha: «RAM que encajan aquí», con su efecto en esta placa (+9 % DPS, +1 proyectil…) y
  «Instalar». Pestañas «Encajan aquí / Todas / Placas».
- Ayuda en tres pasos en la cabecera. En PC sigue funcionando arrastrar y soltar y hay atajos (1-6).
- **A favor:** todo a la vista y con objetivos grandes; se entiende la placa como «un PC con
  ranuras». **En contra:** para ver dónde rinde mejor una RAM hay que ir placa por placa.

## Propuesta B · RAM primero (`228_propuesta_b_pc.png`, `228_propuesta_b_tactil.png`)

- Arriba: las seis placas en columnas, con sus ranuras.
- Al tocar una RAM de la bolsa (casillas grandes con nombre), una hoja explica qué hace y cada
  placa se ilumina o se apaga con su veredicto: «✓ ranura libre · +9 % DPS», «✓ cambiar por otra
  · +4 %», «sin ranura DDR3 libre» o «no le sirve», con «Instalar aquí» en las que valen.
- **A favor:** responde directamente a «¿dónde pongo esto que acabo de encontrar?».
  **En contra:** para retocar una placa concreta (quitar, cambiar tecla, variante) hace falta
  otra vista.

## Recomendación

**A como pantalla principal, con el veredicto de B** al tocar una RAM en la pestaña «Todas»
(o recién recogida): A sirve para montar una placa y B para decidir dónde va cada RAM nueva.
Lo que elija el usuario se implementa en T229 (flujo táctil) y T230 (claridad en PC).
