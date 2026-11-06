# Habilidades (placas base) y asistencias (módulos RAM)

Generado con `tools/list_skills.gd` a partir de `data/skills/`. Cifras de una placa de nivel 1: el daño, el área y la duración crecen con el nivel de la placa, y en los niveles 10, 20 y 30 cada habilidad gana su bonificación de hito.

## Ataques y hechizos

### Barrido

*golpe en área* · Fuerza (DDR3) · daño: físico · ataque (usa el arma)

Gira con el arma y golpea todo alrededor. Refactorización a la vieja escuela.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, físico
- **Cifras:** maná 4, daño 2-5, radio 95
- **Estados extra:** sangrando 10 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Técnico de Soporte

### Bomba Lógica

*trampa* · Destreza (DDR4) · daño: caos · hechizo

Escondes una bomba en el suelo. Explota cuando un enemigo cumple la condición: acercarse. Hasta 3 a la vez.

- **Etiquetas:** hechizo, área, caos, trampa, duración
- **Cifras:** maná 9, enfriamiento 0.8 s, daño 12-20, radio 110, dura 20.0 s
- **Estados extra:** envenenado 25 %
- **Hito (niveles 10, 20, 30):** +1 bomba a la vez
- **Inicial de:** Ingeniera de Prompts

### Bucle Infinito

*giro continuo* · Fuerza (DDR3) · daño: físico · ataque (usa el arma)

while (true) { girar(); } Golpeas a tu alrededor sin parar durante unos segundos y puedes moverte mientras tanto.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, físico, duración
- **Cifras:** maná 12, enfriamiento 4.0 s, daño 1-3, radio 105, dura 2.4 s
- **Estados extra:** sangrando 5 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Desarrollador Full Stack

### Campo de Estática

*terreno en el suelo (con combos)* · Inteligencia (DDR5) · daño: rayo · hechizo

Cargas el suelo de electricidad estática: daño de rayo por segundo a quien lo pise y alguna electrocución. Encima de un charco de refrigerante se vuelve superconductor.

- **Etiquetas:** hechizo, área, rayo, elemental, degenerativo, duración
- **Cifras:** maná 10, daño 5-9 por segundo, radio 120, dura 5.0 s
- **Estados extra:** electrocutado 25 %
- **Hito (niveles 10, 20, 30):** +10 % de área

### Cascada de Estilos

*lluvia de impactos* · Destreza (DDR4) · daño: frío · ataque (usa el arma)

Haces llover hojas de estilo heladas sobre una zona: !important tras !important, cada impacto congela un poco más el diseño (y a los enemigos).

- **Etiquetas:** ataque, proyectil, área, frío, elemental
- **Cifras:** maná 10, enfriamiento 3.0 s, daño 1-3, radio 150, dura 1.2 s
- **Estados extra:** helado 15 %
- **Hito (niveles 10, 20, 30):** +2 impactos
- **Inicial de:** Desarrolladora Frontend

### Charco de Refrigerante

*terreno en el suelo (con combos)* · Inteligencia (DDR5) · daño: frío · hechizo

Vacías el circuito de refrigeración líquida: el suelo se hiela, hace daño de frío y ralentiza a quien lo pisa. Con un Campo de Estática encima, superconductor: el doble de rayo y congela.

- **Etiquetas:** hechizo, área, frío, elemental, degenerativo, duración
- **Cifras:** maná 8, daño 3-5 por segundo, radio 115, dura 5.0 s
- **Estados extra:** helado 100 %
- **Hito (niveles 10, 20, 30):** +10 % de área

### Core Dump

*nova a tu alrededor* · Inteligencia (DDR5) · daño: físico · hechizo

Vuelcas toda la memoria de golpe a tu alrededor: gasta todas tus cargas. Cada Buffer te cura un 6 % y suma un 10 % de daño; cada Multihilos, un 15 %; con Overclock, crítico seguro y más multiplicador. Sin cargas, un volcado discreto.

- **Etiquetas:** hechizo, área, físico
- **Cifras:** maná 12, enfriamiento 4.0 s, daño 12-21, radio 150
- **Hito (niveles 10, 20, 30):** +10 % de área

### Corrupción de Datos

*proyectil degenerativo* · Inteligencia (DDR5) · daño: caos · hechizo

Un paquete corrupto que atraviesa enemigos y los deja pudriéndose: daño de caos por segundo.

- **Etiquetas:** hechizo, proyectil, caos, degenerativo, duración
- **Cifras:** maná 8, daño 12-18 por segundo, 1 proyectil, dura 4.0 s
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Se desbloquea con:** Ingeniera de Prompts (nv. 24)

### Deadlock

*nova a tu alrededor* · Fuerza (DDR3) · daño: frío · hechizo

Todos los procesos a tu alrededor se quedan esperando a otro proceso que les espera a ellos. Daño de frío y aturdimiento.

- **Etiquetas:** hechizo, área, frío, elemental, duración
- **Cifras:** maná 15, enfriamiento 7.0 s, daño 27-43, radio 170, aturde 1.6 s
- **Estados extra:** congelado 15 %
- **Hito (niveles 10, 20, 30):** +10 % de área

### Derrame de Aceite

*terreno en el suelo (con combos)* · Destreza (DDR4) · daño: fuego · hechizo

Tiras el aceite del ventilador en el suelo: los enemigos resbalan y van más lentos. Si algo en llamas lo toca (un enemigo quemándose, un proyectil o una explosión de fuego), estalla y el suelo queda ardiendo.

- **Etiquetas:** hechizo, área, fuego, elemental, duración
- **Cifras:** maná 9, enfriamiento 1.0 s, daño 5-8 por segundo, radio 110, dura 7.0 s
- **Hito (niveles 10, 20, 30):** +10 % de área

### Despliegue Continuo

*embestida* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Te lanzas hacia el cursor y golpeas a todo lo que hay en el camino. CI/CD: si algo se rompe, ya lo arreglará el siguiente commit.

- **Etiquetas:** ataque, cuerpo a cuerpo, físico
- **Cifras:** maná 7, enfriamiento 1.5 s, daño 3-6
- **Estados extra:** sangrando 15 %
- **Hito (niveles 10, 20, 30):** +10 % de daño
- **Inicial de:** Tester QA

### Excepción en Cadena

*cadena* · Inteligencia (DDR5) · daño: rayo · hechizo

Lanzas una excepción al enemigo más cercano al cursor; nadie la captura y va saltando de uno a otro.

- **Etiquetas:** hechizo, cadena, rayo, elemental
- **Cifras:** maná 9, daño 9-21, 4 saltos de cadena
- **Estados extra:** electrocutado 15 %
- **Hito (niveles 10, 20, 30):** +1 salto de cadena
- **Inicial de:** Ingeniera de Prompts

### Firewall Personal

*barrera* · Fuerza (DDR3) · daño: sin daño · hechizo

Levantas un firewall a tu alrededor: una barrera que absorbe daño antes que tu vida. Crece con tu vida máxima.

- **Etiquetas:** hechizo, defensa, potenciador, duración
- **Cifras:** maná 12, enfriamiento 10.0 s, dura 6.0 s
- **Hito (niveles 10, 20, 30):** +20 % de barrera
- **Inicial de:** Técnico de Soporte

### Flamewar

*cono* · Inteligencia (DDR5) · daño: fuego · hechizo

Un cono de fuego delante de ti. Como un hilo de comentarios sobre tabuladores contra espacios.

- **Etiquetas:** hechizo, área, fuego, elemental
- **Cifras:** maná 8, daño 9-17, radio 210
- **Estados extra:** quemado 20 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Desarrollador Full Stack

### Force Push

*carga con empuje* · Fuerza (DDR3) · daño: físico · ataque (usa el arma)

Cargas contra el primer enemigo hacia el cursor y lo arrollas con todo lo de alrededor: los empujas lejos y quedan aturdidos un momento. Sobrescribe la historia de quien estuviera delante.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, movimiento, físico
- **Cifras:** maná 8, enfriamiento 3.0 s, daño 3-8, radio 85, aturde 0.4 s
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Se desbloquea con:** Técnico de Soporte (nv. 8), Ingeniero DevOps (nv. 8), Desarrollador Full Stack (nv. 8)

### Fork Bomb

*explosión en el suelo* · Inteligencia (DDR5) · daño: fuego · hechizo

Marca un punto y deja que se replique hasta explotar. :(){ :|:& };:

- **Etiquetas:** hechizo, área, fuego, elemental
- **Cifras:** maná 9, daño 12-20, radio 85
- **Estados extra:** quemado 15 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Científico de Datos

### Fuga de Memoria

*charco degenerativo* · Inteligencia (DDR5) · daño: caos · hechizo

Deja un charco de memoria sin liberar que corroe a quien lo pisa. Daño por segundo mientras estén dentro.

- **Etiquetas:** hechizo, área, caos, degenerativo, duración
- **Cifras:** maná 10, daño 6-8 por segundo, radio 115, dura 4.5 s
- **Hito (niveles 10, 20, 30):** +10 % de área

### Fuzzing

*cono* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Bombardeas al enemigo con entradas aleatorias: tres tajos rapidísimos en cono. Alguno encuentra el bug, y el bug sangra.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, físico
- **Cifras:** maná 6, daño 1-3, radio 135
- **Estados extra:** sangrando 20 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Tester QA

### Git Revert

*salto atrás con zona helada* · Destreza (DDR4) · daño: frío · hechizo

Saltas hacia atrás, lejos del cursor, y dejas donde estabas una zona helada que ralentiza y daña a quien la pisa. Deshacer siempre fue la mejor jugada.

- **Etiquetas:** hechizo, movimiento, área, frío, elemental, duración
- **Cifras:** maná 7, enfriamiento 2.0 s, daño 4-6 por segundo, radio 95, dura 2.5 s
- **Estados extra:** helado 100 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Se desbloquea con:** Tester QA (nv. 8), Desarrolladora Frontend (nv. 8)

### Hiperthreading

*potenciador* · Destreza (DDR4) · daño: sin daño · hechizo

Dos hilos por núcleo: atacas y lanzas mucho más rápido durante unos segundos.

- **Etiquetas:** hechizo, potenciador, duración
- **Cifras:** maná 10, enfriamiento 14.0 s, dura 8.0 s
- **Hito (niveles 10, 20, 30):** +1 s de duración
- **Inicial de:** Tester QA

### Modo Seguro

*potenciador* · Fuerza (DDR3) · daño: sin daño · hechizo

Reinicias en modo seguro: mucha más armadura y resistencias durante unos segundos, a cambio de moverte más lento.

- **Etiquetas:** hechizo, defensa, potenciador, duración
- **Cifras:** maná 10, enfriamiento 12.0 s, dura 6.0 s
- **Hito (niveles 10, 20, 30):** +1 s de duración

### Paquete Rastreador

*proyectiles teledirigidos* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Disparas paquetes con seguimiento que buscan al enemigo más cercano. Nadie escapa del tracking.

- **Etiquetas:** ataque, proyectil, físico, teledirigido
- **Cifras:** maná 7, daño 1-4, 3 proyectiles teledirigidos
- **Estados extra:** sangrando 5 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Se desbloquea con:** Desarrolladora Frontend (nv. 24)

### Ping Letal

*proyectiles* · Inteligencia (DDR5) · daño: rayo · hechizo

Un rayo que atraviesa enemigos. 64 bytes de puro dolor, tiempo de respuesta: el tuyo.

- **Etiquetas:** hechizo, proyectil, rayo, elemental
- **Cifras:** maná 6, daño 6-16, 1 proyectil
- **Estados extra:** electrocutado 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Inicial de:** Científico de Datos

### Pipe de Datos

*channel_beam* · Inteligencia (DDR5) · daño: rayo · hechizo

Canalizado: mantén pulsada la tecla para abrir un flujo continuo de datos que electrocuta todo lo que cruza. Gasta maná por segundo y no te deja moverte; apunta con el cursor o el stick.

- **Etiquetas:** hechizo, canalizado, rayo, elemental
- **Cifras:** maná 9, daño 4-7
- **Estados extra:** electrocutado 6 %
- **Hito (niveles 10, 20, 30):** +10 % de daño

### Ransomware

*maldición en área* · Inteligencia (DDR5) · daño: caos · hechizo

Cifras a todos los enemigos de una zona: sufren daño de caos por segundo hasta que paguen. No pagarán.

- **Etiquetas:** hechizo, área, caos, degenerativo, duración
- **Cifras:** maná 11, daño 14-21 por segundo, radio 130, dura 5.0 s
- **Hito (niveles 10, 20, 30):** +10 % de área

### Rayo de Producción

*rayo en línea* · Inteligencia (DDR5) · daño: rayo · hechizo

Se carga un instante y dispara un rayo larguísimo en línea recta. Desplegado directamente en main, sin revisión.

- **Etiquetas:** hechizo, área, rayo, elemental
- **Cifras:** maná 16, enfriamiento 5.0 s, daño 31-54
- **Estados extra:** electrocutado 20 %
- **Hito (niveles 10, 20, 30):** +10 % de daño

### Reinicio Forzado

*salto y golpe* · Fuerza (DDR3) · daño: físico · ataque (usa el arma)

Saltas hacia el cursor y caes sobre los enemigos como quien reinicia un servidor a patadas: daño en área, aturdimiento corto y alguna hemorragia.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, físico
- **Cifras:** maná 9, enfriamiento 3.0 s, daño 4-10, radio 110, aturde 0.7 s
- **Estados extra:** sangrando 15 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Técnico de Soporte

### Rollback

*bumerán* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Lanzas tu arma y vuelve a tus manos, golpeando a la ida y a la vuelta. Como un git revert: deshace todo lo que toca.

- **Etiquetas:** ataque, proyectil, físico
- **Cifras:** maná 7, daño 2-5, 1 proyectil
- **Estados extra:** sangrando 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Inicial de:** Ingeniera de Prompts

### Ráfaga de Paquetes

*proyectiles* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Lanza varios paquetes afilados en abanico. Algunos llegan. Es UDP.

- **Etiquetas:** ataque, proyectil, físico
- **Cifras:** maná 6, daño 2-6, 3 proyectiles
- **Estados extra:** sangrando 5 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Inicial de:** Desarrolladora Frontend

### Stack Overflow

*nova a tu alrededor* · Inteligencia (DDR5) · daño: frío · hechizo

Una onda helada a tu alrededor. La pila no da para más y congela todo.

- **Etiquetas:** hechizo, área, frío, elemental
- **Cifras:** maná 8, daño 8-14, radio 140
- **Estados extra:** helado 15 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Científico de Datos

### Teletransporte TCP

*teletransporte* · Destreza (DDR4) · daño: sin daño · hechizo

Te reenvía hacia el cursor. Con confirmación de entrega, a diferencia de ese correo.

- **Etiquetas:** hechizo, movimiento
- **Cifras:** maná 8, enfriamiento 2.5 s
- **Hito (niveles 10, 20, 30):** +10 % de daño
- **Inicial de:** Desarrolladora Frontend

### Tormenta de Tickets

*channel_storm* · Inteligencia (DDR5) · daño: frío · hechizo

Canalizado: mientras la mantienes, una tormenta de tickets sin resolver crece donde apuntas (hasta el triple de tamaño y el doble de daño en 3 s) y sigue al cursor. Gasta maná por segundo.

- **Etiquetas:** hechizo, canalizado, área, frío, elemental
- **Cifras:** maná 10, daño 5-9, radio 90
- **Estados extra:** helado 10 %
- **Hito (niveles 10, 20, 30):** +10 % de área

### Torreta de Integración Continua

*proyectiles teledirigidos* · Inteligencia (DDR5) · daño: rayo · hechizo

Despliegas una torreta armada con piezas de servidor que dispara sola proyectiles teledirigidos al enemigo más cercano. Tú programas; ella pelea.

- **Etiquetas:** hechizo, proyectil, rayo, elemental, tótem, duración, autómata, teledirigido
- **Cifras:** maná 14, enfriamiento 1.0 s, daño 7-14, 2 proyectiles teledirigidos
- **Estados extra:** electrocutado 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Inicial de:** Ingeniero DevOps

### Túnel SSH

*teletransporte con descarga* · Inteligencia (DDR5) · daño: rayo · hechizo

Abres un túnel hasta el cursor y apareces al otro lado. El handshake suelta una descarga donde estabas y donde llegas. Sin contraseña: la clave pública ya la tenías.

- **Etiquetas:** hechizo, movimiento, área, rayo, elemental
- **Cifras:** maná 9, enfriamiento 2.5 s, daño 7-12, radio 75
- **Estados extra:** electrocutado 20 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Se desbloquea con:** Ingeniera de Prompts (nv. 8), Científico de Datos (nv. 8)

### ¡Daily en cinco minutos!

*potenciador* · Destreza (DDR4) · daño: sin daño · hechizo

Grito: la reunión diaria empieza ya y nadie quiere llegar tarde. Tú y tus invocaciones se mueven y actúan mucho más rápido.

- **Etiquetas:** hechizo, potenciador, grito, duración
- **Cifras:** maná 10, enfriamiento 16.0 s, dura 6.0 s
- **Hito (niveles 10, 20, 30):** +1 s de duración

### ¡Está en producción!

*potenciador* · Fuerza (DDR3) · daño: sin daño · hechizo

Grito: alguien rompió producción y todo el equipo se pone las pilas. Más daño para ti y mucho más para tus invocaciones, que además van más rápido.

- **Etiquetas:** hechizo, potenciador, grito, duración
- **Cifras:** maná 12, enfriamiento 15.0 s, dura 6.0 s
- **Hito (niveles 10, 20, 30):** +1 s de duración

### ¡Rollback!

*potenciador* · Inteligencia (DDR5) · daño: sin daño · hechizo

Grito: vuelta a la última versión que funcionaba. Cura a tus invocaciones y les da a todos más armadura; ellas, además, más vida.

- **Etiquetas:** hechizo, potenciador, grito, defensa, duración
- **Cifras:** maná 14, enfriamiento 18.0 s, dura 6.0 s
- **Hito (niveles 10, 20, 30):** +1 s de duración

## Invocaciones

### Agente IA

*invocación persistente* · Inteligencia (DDR5) · daño: caos · hechizo

Un agente autónomo que alucina con confianza: dispara a distancia y, cada pocos segundos, escupe un charco tóxico sobre el grupo enemigo. Persistente.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, caos, proyectil, teledirigido
- **Cifras:** reserva 15 % del maná, enfriamiento 1.0 s, daño 7-13, 1 proyectil teledirigidos
- **Estados extra:** envenenado 30 %
- **Hito (niveles 10, 20, 30):** +25 % de duración y daño del charco venenoso
- **Comportamiento:** a distancia: se queda a tu lado y dispara; hasta 1 a la vez; vida 65; ataca cada 1.4 s; alcance 540
- **Habilidad propia:** cada 7 s escupe un charco venenoso (radio 95, 4 s) sobre el enemigo más cercano
- **Se desbloquea con:** Ingeniera de Prompts (nv. 10)

### Bot Rastreador de Bugs

*invocación persistente* · Destreza (DDR4) · daño: caos · hechizo

Un bot de QA que no se cansa: dispara dardos envenenados al bug más cercano desde lejos. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, proyectil, caos
- **Cifras:** reserva 13 % del maná, enfriamiento 1.5 s, daño 8-14, 1 proyectil
- **Estados extra:** envenenado 30 %
- **Hito (niveles 10, 20, 30):** +1 dardo por disparo
- **Comportamiento:** a distancia: se queda a tu lado y dispara; hasta 1 a la vez; vida 50; ataca cada 0.9 s; alcance 560
- **Se desbloquea con:** Desarrolladora Frontend (nv. 10), Ingeniera de Prompts (nv. 16, a elegir)

### Bot de Pruebas

*invocación persistente* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Un script de QA que salta sobre el grupo enemigo más lejano y lo golpea en área; luego sigue a golpes. Rápido y frágil. Persistente.

- **Etiquetas:** ataque, esbirro, autómata, persistente, cuerpo a cuerpo, físico
- **Cifras:** reserva 12 % del maná, enfriamiento 1.0 s, daño 1-3
- **Estados extra:** sangrando 20 %
- **Hito (niveles 10, 20, 30):** +25 % de daño del salto
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 2 a la vez; vida 70; ataca cada 0.6 s; alcance 520
- **Habilidad propia:** cada 5 s salta sobre el enemigo más lejano a su alcance y golpea el suelo (radio 75, ×1.6 de daño)
- **Se desbloquea con:** Tester QA (nv. 10), Desarrollador Full Stack (nv. 16, a elegir)

### Daemon en Segundo Plano

*invocación persistente* · Inteligencia (DDR5) · daño: físico · hechizo

Lanzas dos procesos daemon que pelean cuerpo a cuerpo por ti. Corren en segundo plano para siempre (como todo lo que nadie documentó) y reservan maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, físico
- **Cifras:** reserva 12 % del maná, enfriamiento 1.0 s, daño 7-12
- **Estados extra:** sangrando 10 %
- **Hito (niveles 10, 20, 30):** +1 invocación a la vez
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 2 a la vez; vida 90; ataca cada 0.9 s; alcance 450
- **Inicial de:** Desarrollador Full Stack

### Dron Cortafuegos

*invocación persistente* · Fuerza (DDR3) · daño: sin daño · hechizo

Un dron que levanta un cortafuegos sobre ti cada pocos segundos: una barrera que crece con tu vida máxima. Orbita, no ataca. Persistente.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, defensa
- **Cifras:** reserva 14 % del maná, enfriamiento 1.0 s
- **Hito (niveles 10, 20, 30):** +25 % de barrera
- **Comportamiento:** dron que orbita a tu alrededor (no se le puede dañar); hasta 1 a la vez; vida 1; ataca cada 7.0 s; alcance 600; no dispara
- **Habilidad propia:** cada 7.0 s (si no tienes barrera) te da una barrera de 20 + 12 % de tu vida máxima durante 6 s
- **Se desbloquea con:** Técnico de Soporte (nv. 16, a elegir), Ingeniero DevOps (nv. 24), Desarrollador Full Stack (nv. 5)

### Dron Escolta

*invocación persistente* · Destreza (DDR4) · daño: fuego · hechizo

Un dron armado que orbita a tu alrededor y dispara bengalas incendiarias. Vuela demasiado alto para que lo golpeen. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, proyectil, fuego, elemental, teledirigido
- **Cifras:** reserva 10 % del maná, enfriamiento 1.0 s, daño 6-11, 1 proyectil teledirigidos
- **Estados extra:** quemado 20 %
- **Hito (niveles 10, 20, 30):** +1 proyectil por disparo
- **Comportamiento:** dron que orbita a tu alrededor (no se le puede dañar); hasta 2 a la vez; vida 1; ataca cada 1.3 s; alcance 480
- **Se desbloquea con:** Desarrolladora Frontend (nv. 16, a elegir), Científico de Datos (nv. 10), Desarrollador Full Stack (nv. 16, a elegir)

### Dron de Mantenimiento

*invocación persistente* · Inteligencia (DDR5) · daño: sin daño · hechizo

Un dron con el botiquín de IT: orbita a tu alrededor y repara cada pocos segundos a ti y a tus invocaciones. No ataca. Persistente.

- **Etiquetas:** hechizo, esbirro, autómata, persistente
- **Cifras:** reserva 12 % del maná, enfriamiento 1.0 s
- **Hito (niveles 10, 20, 30):** +25 % de curación
- **Comportamiento:** dron que orbita a tu alrededor (no se le puede dañar); hasta 1 a la vez; vida 1; ataca cada 3.5 s; alcance 600; no dispara
- **Habilidad propia:** repara: cada 3.5 s te cura un 6 % de tu vida y a tus invocaciones un 12 % de la suya
- **Se desbloquea con:** Ingeniero DevOps (nv. 10)

### Drones de Vigilancia

*drones temporales* · Inteligencia (DDR5) · daño: rayo · hechizo

Tres drones orbitan a tu alrededor y disparan rayos en línea recta al enemigo más cercano (con Guiado por Láser, teledirigidos).

- **Etiquetas:** hechizo, proyectil, rayo, elemental, duración, autómata
- **Cifras:** maná 16, enfriamiento 6.0 s, daño 3-6, 1 proyectil, dura 10.0 s
- **Estados extra:** electrocutado 5 %
- **Hito (niveles 10, 20, 30):** +1 dron
- **Invoca:** 3 drones que te orbitan 10 s y disparan cada 1.0 s al enemigo más cercano
- **Inicial de:** Ingeniero DevOps

### Golem GPU

*invocación persistente* · Inteligencia (DDR5) · daño: rayo · hechizo

Una tarjeta gráfica con patas, dos ventiladores en el pecho y luces RGB. Dispara a distancia y cada poco traza un rayo en línea (ray tracing, literalmente). Mientras viva, tus habilidades cuestan menos maná y se enfrían antes. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, proyectil, rayo, elemental, golem
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 8-13, 1 proyectil
- **Estados extra:** electrocutado 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil por disparo
- **Comportamiento:** a distancia: se queda a tu lado y dispara; hasta 1 a la vez; vida 140; ataca cada 1.2 s; alcance 520
- **Defensa:** recibe un 15 % menos de daño

### Golem UTP

*invocación persistente* · Destreza (DDR4) · daño: físico · hechizo

Un monstruo de cables UTP enredados con conectores RJ45 colgando. Barre el área a latigazos y enreda a los grupos, atrayéndolos y aturdiéndolos. Mientras viva, tus autómatas hacen más daño y actúan más rápido. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, físico, golem
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 9-15, radio 120
- **Estados extra:** sangrando 10 %
- **Hito (niveles 10, 20, 30):** +25 % de potencia del enredo y el latigazo
- **Comportamiento:** tanque: golpea en área y provoca a los enemigos; hasta 1 a la vez; vida 190; ataca cada 1.3 s; alcance 430
- **Defensa:** recibe un 20 % menos de daño
- **Provoca** a los enemigos a 120 de distancia (te los quita de encima)

### Golem de Hardware Reciclado

*invocación persistente* · Fuerza (DDR3) · daño: físico · hechizo

Ensamblas un golem con torres viejas y cables. Es lento y enorme: provoca a los enemigos cercanos para que le peguen a él y golpea el suelo. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, físico
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 12-20, radio 90, aturde 0.4 s
- **Estados extra:** sangrando 10 %
- **Hito (niveles 10, 20, 30):** +25 % de vida y +5 % de daño evitado
- **Comportamiento:** tanque: golpea en área y provoca a los enemigos; hasta 1 a la vez; vida 220; ataca cada 1.6 s; alcance 400
- **Defensa:** recibe un 30 % menos de daño
- **Provoca** a los enemigos a 230 de distancia (te los quita de encima)
- **Se desbloquea con:** Técnico de Soporte (nv. 16, a elegir), Ingeniero DevOps (nv. 16, a elegir)

### Golem de Kernel

*invocación persistente* · Inteligencia (DDR5) · daño: caos · hechizo

Un espectro del espacio de kernel que flota entre volcados de memoria. Todo enemigo cerca de él sufre daño de caos continuo (corrupción). Mientras viva, te da resistencia al caos. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, caos, golem
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 7-12
- **Estados extra:** envenenado 10 %
- **Hito (niveles 10, 20, 30):** +25 % de potencia y alcance de la corrupción
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 1 a la vez; vida 170; ataca cada 1.1 s; alcance 420
- **Defensa:** recibe un 20 % menos de daño

### Golem de Overclock

*invocación persistente* · Destreza (DDR4) · daño: fuego · hechizo

Un disipador al rojo vivo que nunca para quieto: corre a los enemigos, golpea rápido y salta sobre los lejanos. Mientras viva, tú también vas más rápido: ataque, lanzamiento y movimiento. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, cuerpo a cuerpo, fuego, elemental, golem
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 7-11
- **Estados extra:** quemado 15 %
- **Hito (niveles 10, 20, 30):** +25 % de potencia de su salto
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 1 a la vez; vida 150; ataca cada 0.7 s; alcance 480
- **Defensa:** recibe un 10 % menos de daño

### Golem del Silicio

*invocación persistente* · Fuerza (DDR3) · daño: físico · hechizo

Un coloso de obleas de silicio y cristal en bruto. Provoca a los enemigos y golpea el suelo. Mientras viva, te da armadura y regenera poco a poco tu escudo de energía. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, físico, golem
- **Cifras:** reserva 25 % del maná, enfriamiento 2.0 s, daño 10-17, radio 85, aturde 0.3 s
- **Hito (niveles 10, 20, 30):** +25 % de vida y +5 % de daño evitado
- **Comportamiento:** tanque: golpea en área y provoca a los enemigos; hasta 1 a la vez; vida 240; ataca cada 1.7 s; alcance 400
- **Defensa:** recibe un 30 % menos de daño
- **Provoca** a los enemigos a 210 de distancia (te los quita de encima)

### Mainframe Titán

*invocación persistente* · Fuerza (DDR3) · daño: físico · hechizo

Despiertas un mainframe de los 80 con piernas. Es una sola invocación, enorme y cara: golpea, cada pocos segundos lanza un terremoto que aturde, dispara un láser con el ojo que atraviesa filas de enemigos y te protege con una barrera. Persistente: reserva mucho maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, físico
- **Cifras:** reserva 45 % del maná, enfriamiento 3.0 s, daño 22-34, radio 110, aturde 0.5 s
- **Hito (niveles 10, 20, 30):** +25 % de potencia de sus habilidades
- **Comportamiento:** tanque: golpea en área y provoca a los enemigos; hasta 1 a la vez; vida 520; ataca cada 1.8 s; alcance 520
- **Defensa:** recibe un 35 % menos de daño
- **Provoca** a los enemigos a 300 de distancia (te los quita de encima)

### Mina Rodante

*invocación persistente* · Destreza (DDR4) · daño: fuego · hechizo

Una bomba con ruedas que persigue al enemigo más cercano y explota al morir (y a veces antes). Cuando estalla, la vuelves a lanzar. Persistente.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, fuego, elemental
- **Cifras:** reserva 10 % del maná, enfriamiento 1.0 s, daño 11-18, radio 95
- **Estados extra:** quemado 30 %
- **Hito (niveles 10, 20, 30):** +25 % de daño y área de la explosión
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 2 a la vez; vida 55; ataca cada 1.4 s; alcance 480
- **Habilidad propia:** kamikaze: al tocar a un enemigo (o al caer) explota en un radio de 95
- **Se desbloquea con:** Tester QA (nv. 16, a elegir), Desarrolladora Frontend (nv. 16, a elegir)

### Proceso Hijo

*esbirros temporales* · Inteligencia (DDR5) · daño: físico · hechizo

fork() y dos procesos hijos salen a pelear por ti durante un rato. No los has documentado, pero obedecen.

- **Etiquetas:** hechizo, esbirro, duración, físico, autómata
- **Cifras:** maná 14, enfriamiento 1.0 s, daño 2-4, dura 14.0 s
- **Hito (niveles 10, 20, 30):** +1 esbirro
- **Invoca:** 2 esbirros que duran 14 s y golpean cada 0.9 s
- **Se desbloquea con:** Ingeniera de Prompts (nv. 16, a elegir), Científico de Datos (nv. 24)

### Robot Centinela

*invocación persistente* · Inteligencia (DDR5) · daño: rayo · hechizo

Montas un robot centinela que te sigue y dispara láseres al enemigo más cercano. No caduca: reserva maná mientras siga en pie. Si lo destruyen, vuelve a montarlo.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, proyectil, rayo, elemental
- **Cifras:** reserva 15 % del maná, enfriamiento 1.5 s, daño 8-14, 1 proyectil
- **Estados extra:** electrocutado 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil por disparo
- **Comportamiento:** a distancia: se queda a tu lado y dispara; hasta 1 a la vez; vida 60; ataca cada 1.1 s; alcance 520
- **Inicial de:** Ingeniero DevOps

### Watchdog

*invocación persistente* · Fuerza (DDR3) · daño: físico · hechizo

Un perro guardián que reinicia todo lo que se cuelga: muerde a los enemigos cercanos (sangran) y salta sobre el más lejano cada pocos segundos. Persistente: reserva maná.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, cuerpo a cuerpo, físico
- **Cifras:** reserva 13 % del maná, enfriamiento 1.0 s, daño 6-10
- **Estados extra:** sangrando 20 %
- **Hito (niveles 10, 20, 30):** +1 invocación a la vez
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 2 a la vez; vida 110; ataca cada 0.8 s; alcance 480
- **Habilidad propia:** cada 6 s salta sobre el enemigo más lejano a su alcance y golpea el suelo (radio 70, ×1.4 de daño)
- **Se desbloquea con:** Técnico de Soporte (nv. 10), Tester QA (nv. 16, a elegir), Ingeniero DevOps (nv. 16, a elegir)

## Auras

### Aura de Blindaje Redundante

*aura persistente* · Fuerza (DDR3) · daño: sin daño · hechizo

Redundancia N+2: tus invocaciones tienen mucha más vida y reciben menos daño. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración, defensa
- **Cifras:** reserva 20 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 420 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** 40% de aumento de Vida de esbirros; tus invocaciones reciben un 20 % menos de daño
- **Se desbloquea con:** Técnico de Soporte (nv. 5)

### Aura de Exposición de Vulnerabilidades

*aura persistente* · Inteligencia (DDR5) · daño: sin daño · hechizo

Publicas los CVE de todo lo que te rodea: los enemigos dentro del aura reciben más daño. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración, maldición
- **Cifras:** reserva 22 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 360 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** los enemigos dentro reciben un 12 % más de daño
- **Se desbloquea con:** Ingeniera de Prompts (nv. 5), Científico de Datos (nv. 16, a elegir)

### Aura de Mando

*aura persistente* · Fuerza (DDR3) · daño: sin daño · hechizo

El jefe de equipo da órdenes claras: tus aliados hacen más daño y crítico. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración
- **Cifras:** reserva 22 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 420 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** 25% de aumento de Daño (de autómatas); 30% de aumento de Probabilidad de crítico (de autómatas)
- **Se desbloquea con:** Técnico de Soporte (nv. 24), Tester QA (nv. 5), Desarrollador Full Stack (nv. 10)

### Aura de Mantenimiento Continuo

*aura persistente* · Destreza (DDR4) · daño: sin daño · hechizo

Un cron que repara todo lo que está cerca: tus invocaciones recuperan vida sin parar y tú también. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración
- **Cifras:** reserva 16 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 420 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** +4 de Regeneración de vida por segundo; tus invocaciones recuperan un 3.0 % de vida por segundo
- **Se desbloquea con:** Ingeniero DevOps (nv. 5)

### Aura de Overclock

*aura persistente* · Inteligencia (DDR5) · daño: sin daño · hechizo

Un campo de reloj acelerado: tus torretas, drones, esbirros y robots atacan más rápido y con más probabilidad de electrocutar. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración
- **Cifras:** reserva 20 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 420 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** 20% de aumento de Velocidad de autómatas; +8% de Probabilidad de electrocutar (de autómatas)
- **Se desbloquea con:** Científico de Datos (nv. 5), Desarrollador Full Stack (nv. 24)

### Aura de Throttling

*aura persistente* · Destreza (DDR4) · daño: sin daño · hechizo

Limitas la tasa de peticiones a todo lo que se acerque: los enemigos dentro del aura se mueven y atacan más lento. Se activa y se apaga al relanzarla; reserva maná.

- **Etiquetas:** hechizo, aura, persistente, duración, maldición
- **Cifras:** reserva 18 % del maná, enfriamiento 0.6 s
- **Hito (niveles 10, 20, 30):** +15 % de efecto
- **Alcance:** 360 alrededor de ti (las invocaciones fuera no reciben sus bonos)
- **Efectos:** los enemigos dentro se mueven y atacan un 15 % más lento
- **Se desbloquea con:** Tester QA (nv. 24), Desarrolladora Frontend (nv. 5), Científico de Datos (nv. 16, a elegir)

## Módulos RAM (asistencias)

Cada RAM encaja en una ranura de su generación (DDR3 rojo, DDR4 verde, DDR5 azul) y solo funciona con las habilidades que cumplen sus etiquetas. Las de grado *menor* y *mayor* son la misma familia con más o menos efecto. Una RAM que solo mejora el daño no encaja en habilidades sin daño.

### Alimentación por Vida

*DDR4* · grado normal · cae desde el nivel 8

La habilidad toma la mitad de su costo de tu vida en vez del maná, y pega más fuerte por el riesgo. Ideal con robo de vida o vida al matar.

- **Efectos:** 15% más de Daño; El 50 % del costo se paga con vida; Consumo de maná ×1.00
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (32):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### RAM de Alto Voltaje Menor

*DDR5* · grado menor · cae desde el nivel 1

Un voltio más. La garantía todavía aplica.

- **Efectos:** 15% más de Daño elemental; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (19):** Campo de Estática, Charco de Refrigerante, Deadlock, Derrame de Aceite, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Golem GPU, Golem de Overclock, Mina Rodante, Ping Letal, Pipe de Datos, Rayo de Producción, Robot Centinela, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua

### RAM de Alto Voltaje

*DDR5* · grado normal · cae desde el nivel 8

Más voltios para tus hechizos elementales. La garantía no cubre esto.

- **Efectos:** 30% más de Daño elemental; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (19):** Campo de Estática, Charco de Refrigerante, Deadlock, Derrame de Aceite, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Golem GPU, Golem de Overclock, Mina Rodante, Ping Letal, Pipe de Datos, Rayo de Producción, Robot Centinela, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua

### RAM de Alto Voltaje Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Voltaje de planta industrial: mucho más daño elemental de hechizos.

- **Efectos:** 45% más de Daño elemental; Consumo de maná ×1.60
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (19):** Campo de Estática, Charco de Refrigerante, Deadlock, Derrame de Aceite, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Golem GPU, Golem de Overclock, Mina Rodante, Ping Letal, Pipe de Datos, Rayo de Producción, Robot Centinela, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua

### Amplificador de Aura

*DDR5* · grado normal · cae desde el nivel 8

Sube el volumen de tu aura: sus bonificaciones son mucho más potentes. Reserva algo más de maná.

- **Efectos:** 40% de aumento de Efecto de auras; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: aura
- **Funciona con (6):** Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling

### Breakpoint Condicional

*DDR5* · grado mayor · cae desde el nivel 14

if (critico) lanzar_habilidad(): cada crítico de tus otras habilidades lanza esta sola hacia el enemigo más cercano (como mucho cada 0,5 s y pagando su maná; sus propios críticos no cuentan). Ya no se puede lanzar a mano. 10 % menos de daño.

- **Efectos:** 10% menos de Daño; Se lanza sola con los críticos de tus otras habilidades (cada 0.5 s como mucho) (no con su tecla); Consumo de maná ×1.40
- **Etiquetas:** nunca con: canalizado, aura, persistente, movimiento
- **Funciona con (33):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Hiperthreading, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Bypass de Firewall

*DDR4* · grado normal · cae desde el nivel 10

Los proyectiles atraviesan a 3 enemigos más y van más rápido. Nadie configuró las reglas de salida.

- **Efectos:** 25% de aumento de Velocidad de proyectiles; Los proyectiles atraviesan 3 enemigos más; Consumo de maná ×1.25
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Caché L3 Menor

*DDR5* · grado menor · cae desde el nivel 1

Un poco más de caché: +20 % de área.

- **Efectos:** 20% de aumento de Área de efecto; Consumo de maná ×1.15
- **Etiquetas:** con alguna de: área
- **Funciona con (28):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Deadlock, Derrame de Aceite, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem del Silicio, Mainframe Titán, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow, Tormenta de Tickets, Túnel SSH

### Caché L3 Ampliada

*DDR5* · grado normal · cae desde el nivel 1

Más espacio para todo. Sobre todo para explosiones.

- **Efectos:** 40% de aumento de Área de efecto; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: área
- **Funciona con (28):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Deadlock, Derrame de Aceite, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem del Silicio, Mainframe Titán, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow, Tormenta de Tickets, Túnel SSH

### Caché L3 Masiva

*DDR5* · grado mayor · cae desde el nivel 26

Caché de servidor: +65 % de área.

- **Efectos:** 65% de aumento de Área de efecto; Consumo de maná ×1.45
- **Etiquetas:** con alguna de: área
- **Funciona con (28):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Deadlock, Derrame de Aceite, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem del Silicio, Mainframe Titán, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow, Tormenta de Tickets, Túnel SSH

### Callback onKill()

*DDR3* · grado mayor · cae desde el nivel 16

onKill(() => lanzar_habilidad()): cada vez que matas a un enemigo con otra habilidad, esta se lanza sola hacia el más cercano (como mucho cada 0,4 s y pagando su maná; lo que mata ella no cuenta). Ya no se puede lanzar a mano. 10 % menos de daño.

- **Efectos:** 10% menos de Daño; Se lanza sola al matar con otra habilidad (cada 0.4 s como mucho) (no con su tecla); Consumo de maná ×1.40
- **Etiquetas:** nunca con: canalizado, aura, persistente, movimiento
- **Funciona con (33):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Hiperthreading, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Carcasa Reforzada

*DDR3* · grado normal · cae desde el nivel 1

Chapa de servidor atornillada a tus esbirros: mucha más vida y algo más de daño.

- **Efectos:** 50% de aumento de Vida de esbirros; 10% más de Daño de esbirros; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: esbirro
- **Funciona con (18):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Proceso Hijo, Robot Centinela, Watchdog

### Compilación -O3

*DDR4* · grado mayor · cae desde el nivel 12

50 % más de daño y 10 % más de velocidad, a cambio de gastar el doble de maná. Optimizado para todo menos para tu presupuesto.

- **Efectos:** 50% más de Daño; 10% de aumento de Velocidad de ataque; 10% de aumento de Velocidad de lanzamiento; Desventaja fuerte: piensa bien dónde la instalas; Consumo de maná ×2.00
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (32):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Contenedor Docker

*DDR4* · grado normal · cae desde el nivel 1

Empaquetas la habilidad en un contenedor que se queda corriendo donde lo pongas y la lanza sola contra el enemigo más cercano. No caduca: reserva maná mientras siga en pie; relanzarla lo mueve.

- **Efectos:** 35% menos de Daño; La usa un contenedor que no caduca contra el enemigo más cercano (1 por habilidad); Reserva un 20 % del maná mientras siga en pie; Consumo de maná ×1.00
- **Etiquetas:** nunca con: canalizado, movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (23):** Barrido, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### Corrupción de Datos

*DDR5* · grado mayor · cae desde el nivel 18

Convierte el daño elemental (fuego, frío o rayo) de la habilidad en daño de caos. Escala con ambos tipos. Ninguna resistencia elemental te salva de un disco corrupto.

- **Efectos:** Convierte el daño de fuego o de frío o de rayo en daño de caos (le afectan los aumentos de ambos); Consumo de maná ×1.20
- **Etiquetas:** cualquier habilidad
- **Funciona con (22):** Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Deadlock, Derrame de Aceite, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Git Revert, Golem GPU, Golem de Overclock, Mina Rodante, Ping Letal, Pipe de Datos, Rayo de Producción, Robot Centinela, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Cron Job

*DDR4* · grado normal · cae desde el nivel 10

*/2 * * * * lanzar_habilidad: cada 2 s, si hay un enemigo cerca, la habilidad se lanza sola hacia el más cercano (pagando su maná). Ya no se puede lanzar a mano. 20 % menos de daño.

- **Efectos:** 20% menos de Daño; Se lanza sola cada 2.0 s si hay un enemigo cerca (no con su tecla); Consumo de maná ×1.30
- **Etiquetas:** nunca con: canalizado, aura, persistente, movimiento
- **Funciona con (33):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Hiperthreading, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Detonador de Mina

*DDR5* · grado normal · cae desde el nivel 1

Entierras una mina casi invisible que tarda en armarse, pero ejecuta la habilidad con más fuerza al pasar un enemigo. Hasta 5 a la vez.

- **Efectos:** 20% más de Daño; Se entierra como mina: tarda en armarse, se activa al pasar un enemigo (máx. 5); Consumo de maná ×1.35
- **Etiquetas:** nunca con: canalizado, movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (23):** Barrido, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### Disipador de Calor

*DDR3* · grado normal · cae desde el nivel 1

Concentra la potencia en menos espacio. Como meter todo el backend en un solo archivo.

- **Efectos:** 30% más de Daño; 25% menos de área; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: área
- **Funciona con (28):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Deadlock, Derrame de Aceite, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem del Silicio, Mainframe Titán, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow, Tormenta de Tickets, Túnel SSH

### Disparador de Trampa

*DDR4* · grado normal · cae desde el nivel 1

La habilidad ya no se lanza: tiras una trampa que la ejecuta cuando un enemigo pasa cerca. Hasta 3 a la vez.

- **Efectos:** 10% más de Daño; Se lanza como trampa: se activa al acercarse un enemigo (máx. 3); Consumo de maná ×1.30
- **Etiquetas:** nunca con: canalizado, movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (23):** Barrido, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### RAM ECC Menor

*DDR5* · grado menor · cae desde el nivel 1

Corrige errores de memoria... algunos. Un poco más de crítico.

- **Efectos:** 30% de aumento de Probabilidad de crítico; +10% de Multiplicador de crítico; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (39):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Core Dump, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### RAM ECC

*DDR5* · grado normal · cae desde el nivel 8

Corrige errores de memoria. Y provoca errores críticos en tus enemigos.

- **Efectos:** 60% de aumento de Probabilidad de crítico; +20% de Multiplicador de crítico; Consumo de maná ×1.20
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (39):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Core Dump, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### RAM ECC Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Corrección de errores de grado servidor: muchísimo más crítico.

- **Efectos:** 96% de aumento de Probabilidad de crítico; +32% de Multiplicador de crítico; Consumo de maná ×1.35
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (39):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Core Dump, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Enlace de Aura

*DDR4* · grado normal · cae desde el nivel 14

El aura se monta sobre tu invocación más resistente (el golem, si lo tienes) y la sigue a ella en vez de a ti: tus aliados pelean dentro y tú puedes quedarte atrás. Si enlazas varias auras, cada una va a una invocación distinta.

- **Efectos:** 15% de aumento de Efecto de auras; El aura sigue a tu invocación más resistente (el tanque primero), no a ti; con varias auras enlazadas, cada una va a una invocación distinta; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: aura
- **Funciona con (6):** Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling

### Explotador de Vulnerabilidades

*DDR3* · grado normal · cae desde el nivel 8

Si el enemigo ya tiene un estado (quemado, helado, envenenado...), le haces mucho más daño.

- **Efectos:** 30% más de Daño contra enemigos con estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Firmware Autónomo

*DDR5* · grado normal · cae desde el nivel 1

Tus torretas, drones, esbirros y robots dejan de esperar órdenes: atacan mucho más a menudo.

- **Efectos:** 25% más de Velocidad de autómatas; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: autómata, tótem, esbirro
- **Funciona con (20):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Firmware Resiliente

*DDR3* · grado normal · cae desde el nivel 5

Más vida y reducción de daño para tus invocaciones persistentes.

- **Efectos:** 60% de aumento de Vida de esbirros; Tus invocaciones reciben un 15 % menos de daño; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: persistente; nunca con: aura
- **Funciona con (17):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Robot Centinela, Watchdog

### Fragmentación de Disco Menor

*DDR3* · grado menor · cae desde el nivel 1

Rompe en sectores: hace sangrar. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de hacer sangrar; 2% más de Daño físico; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Fragmentación de Disco

*DDR3* · grado normal · cae desde el nivel 8

Rompes a los enemigos en sectores dispersos. Sangran, y el doble si intentan huir.

- **Efectos:** +30% de Probabilidad de hacer sangrar; 5% más de Daño físico; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Fragmentación de Disco Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Rompe en sectores: hace sangrar. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de hacer sangrar; 7% más de Daño físico; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Algoritmo de Fuerza Bruta

*DDR3* · grado normal · cae desde el nivel 1

O(n!) de complejidad, O(1) de sutileza. Mucho más daño físico.

- **Efectos:** 35% más de Daño físico; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: físico; nunca con: movimiento, potenciador
- **Funciona con (17):** Barrido, Bot de Pruebas, Bucle Infinito, Core Dump, Daemon en Segundo Plano, Despliegue Continuo, Fuzzing, Golem UTP, Golem de Hardware Reciclado, Golem del Silicio, Mainframe Titán, Paquete Rastreador, Proceso Hijo, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Watchdog

### Gestor de Estados Global

*DDR5* · grado normal · cae desde el nivel 13

Un store centralizado para tus estados alterados: duran más y hacen más daño. No los aplica: los mejora.

- **Efectos:** 30% más de Daño y efecto de estados alterados; 30% de aumento de Duración de estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Gestor de Memoria Eficiente

*DDR5* · grado normal · cae desde el nivel 8

Libera lo que nadie usa: tus invocaciones y auras persistentes reservan bastante menos maná.

- **Efectos:** 30% de aumento de Eficiencia de reserva de maná; Consumo de maná ×1.10
- **Etiquetas:** con alguna de: persistente
- **Funciona con (23):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Robot Centinela, Watchdog

### Guiado por Láser

*DDR5* · grado normal · cae desde el nivel 6

Los proyectiles se vuelven teledirigidos: giran hacia el enemigo más cercano. Un poco más lentos, eso sí.

- **Efectos:** 10% de reducción de Velocidad de proyectiles; Los proyectiles son teledirigidos: persiguen al enemigo más cercano; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: proyectil; nunca con: teledirigido; no en: lluvia de impactos
- **Funciona con (8):** Bot Rastreador de Bugs, Corrupción de Datos, Drones de Vigilancia, Golem GPU, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes

### Guiado por Láser de Precisión

*DDR5* · grado mayor · cae desde el nivel 24

Teledirigido y además más rápido: +15 % de velocidad de proyectiles.

- **Efectos:** 15% de aumento de Velocidad de proyectiles; Los proyectiles son teledirigidos: persiguen al enemigo más cercano; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: proyectil; nunca con: teledirigido; no en: lluvia de impactos
- **Funciona con (8):** Bot Rastreador de Bugs, Corrupción de Datos, Drones de Vigilancia, Golem GPU, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes

### Hook pre-stash

*DDR4* · grado normal · cae desde el nivel 12

Un hook que corre antes de cada git stash: al esquivar, la habilidad se lanza sola hacia el enemigo más cercano (como mucho cada 0,6 s y pagando su maná). Ya no se puede lanzar a mano.

- **Efectos:** Se lanza sola al esquivar (cada 0.6 s como mucho) (no con su tecla); Consumo de maná ×1.30
- **Etiquetas:** nunca con: canalizado, aura, persistente, movimiento
- **Funciona con (33):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Hiperthreading, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Hotfix en Caliente

*DDR5* · grado mayor · cae desde el nivel 18

Todo el costo se paga con vida: nada de maná. A cambio, 35 % más de daño. Para los que despliegan a producción un viernes a las 6.

- **Efectos:** 35% más de Daño; El 100 % del costo se paga con vida; Consumo de maná ×1.20
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (32):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Inyección de Malware Menor

*DDR4* · grado menor · cae desde el nivel 1

Instala un regalito: envenena. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de envenenar; 7% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Inyección de Malware

*DDR4* · grado normal · cae desde el nivel 8

Cada golpe instala un pequeño regalo. El veneno se acumula hasta 10 veces.

- **Efectos:** +30% de Probabilidad de envenenar; 15% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Inyección de Malware Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Instala un regalito: envenena. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de envenenar; 22% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Manejador de Excepciones

*DDR3* · grado normal · cae desde el nivel 8

try { recibir_golpe() } catch { lanzar_habilidad() }: al recibir un golpe, la habilidad se lanza sola hacia el enemigo más cercano (como mucho cada 0,8 s y pagando su maná). Ya no se puede lanzar a mano. 15 % menos de daño.

- **Efectos:** 15% menos de Daño; Se lanza sola al recibir un golpe (cada 0.8 s como mucho) (no con su tecla); Consumo de maná ×1.30
- **Etiquetas:** nunca con: canalizado, aura, persistente, movimiento
- **Funciona con (33):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Hiperthreading, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Memoria sin ECC

*DDR5* · grado mayor · cae desde el nivel 16

70 % más de daño, pero la habilidad nunca hace críticos. Sin corrección de errores: lo que sale, sale.

- **Efectos:** 70% más de Daño; 100% menos de Probabilidad de crítico; Desventaja fuerte: piensa bien dónde la instalas; Consumo de maná ×1.20
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (32):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### RAM Multicanal Menor

*DDR4* · grado menor · cae desde el nivel 1

Un canal extra: +1 proyectil en abanico. Cada uno pega un 40 % menos en una placa de nivel 1 (1 punto menos por nivel).

- **Efectos:** +1 proyectiles adicionales, en abanico (también los de drones e invocaciones); 40 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 20 %); Consumo de maná ×1.15
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### RAM Multicanal

*DDR4* · grado normal · cae desde el nivel 8

Más canales: +2 proyectiles en abanico. El ancho de banda no es infinito: cada uno pega un 45 % menos (1 punto menos por nivel de la placa).

- **Efectos:** +2 proyectiles adicionales, en abanico (también los de drones e invocaciones); 45 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 22 %); Consumo de maná ×1.30
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### RAM Multicanal Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Cuatro canales: +3 proyectiles en abanico; cada uno pega un 50 % menos (1 punto menos por nivel de la placa).

- **Efectos:** +3 proyectiles adicionales, en abanico (también los de drones e invocaciones); 50 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 25 %); Consumo de maná ×1.50
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Nitrógeno Líquido

*DDR4* · grado normal · cae desde el nivel 10

Convierte el daño físico de la habilidad en daño de frío. Escala con los aumentos de físico y de frío. Para overclockers sin miedo.

- **Efectos:** Convierte el daño físico en daño de frío (le afectan los aumentos de ambos); Consumo de maná ×1.15
- **Etiquetas:** cualquier habilidad
- **Funciona con (18):** Barrido, Bot de Pruebas, Bucle Infinito, Core Dump, Daemon en Segundo Plano, Despliegue Continuo, Force Push, Fuzzing, Golem UTP, Golem de Hardware Reciclado, Golem del Silicio, Mainframe Titán, Paquete Rastreador, Proceso Hijo, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Watchdog

### RAM con Overclock Suave

*DDR4* · grado menor · cae desde el nivel 1

Un pequeño empujón: 10 % más de velocidad de ataque y de lanzamiento.

- **Efectos:** 10% más de Velocidad de ataque; 10% más de Velocidad de lanzamiento; Consumo de maná ×1.15
- **Etiquetas:** nunca con: aura
- **Funciona con (56):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Hiperthreading, Mainframe Titán, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH, Watchdog, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### RAM con Overclock

*DDR4* · grado normal · cae desde el nivel 1

Más rápido. Más caliente. Más caro. Lo de siempre.

- **Efectos:** 20% más de Velocidad de ataque; 20% más de Velocidad de lanzamiento; Consumo de maná ×1.30
- **Etiquetas:** nunca con: aura
- **Funciona con (56):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Hiperthreading, Mainframe Titán, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH, Watchdog, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### RAM con Overclock Extremo

*DDR4* · grado mayor · cae desde el nivel 26

Voltaje al límite: 32 % más de velocidad de ataque y de lanzamiento.

- **Efectos:** 32% más de Velocidad de ataque; 32% más de Velocidad de lanzamiento; Consumo de maná ×1.50
- **Etiquetas:** nunca con: aura
- **Funciona con (56):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Hiperthreading, Mainframe Titán, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH, Watchdog, ¡Daily en cinco minutos!, ¡Está en producción!, ¡Rollback!

### Pasta Térmica Menor

*DDR3* · grado menor · cae desde el nivel 1

Cada golpe tiene probabilidad de prender fuego. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de quemar; 5% más de Daño de fuego; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Pasta Térmica Caducada

*DDR3* · grado normal · cae desde el nivel 8

Ya no disipa nada: todo lo que tocas sale ardiendo. Probabilidad de quemar y algo más de daño de fuego.

- **Efectos:** +30% de Probabilidad de quemar; 10% más de Daño de fuego; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Pasta Térmica Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Cada golpe tiene probabilidad de prender fuego. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de quemar; 15% más de Daño de fuego; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Pico de Overclock

*DDR5* · grado normal · cae desde el nivel 14

Al usar la habilidad gasta todas tus cargas de Overclock: si había al menos una, el golpe es crítico seguro y gana +20 % de multiplicador de crítico por carga.

- **Efectos:** Gasta tus cargas de Overclock: crítico seguro y +20 % de multiplicador de crítico por carga; Consumo de maná ×1.10
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (31):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Pipeline Menor

*DDR3* · grado menor · cae desde el nivel 4

Repite la habilidad una vez con más penalización (en invocaciones, atacan el doble de rápido).

- **Efectos:** 40% menos de Daño; La habilidad se repite 1 vez más; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (46):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Ejecución en Pipeline

*DDR3* · grado normal · cae desde el nivel 1

Lanza la habilidad dos veces seguidas. En invocaciones, drones y esbirros, atacan el doble de rápido. La segunda la ejecuta el practicante.

- **Efectos:** 30% menos de Daño; La habilidad se repite 1 vez más; Consumo de maná ×1.50
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (46):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Pipeline Superescalar

*DDR3* · grado mayor · cae desde el nivel 30

Repite la habilidad dos veces más con la mitad de daño (en invocaciones, atacan el triple de rápido).

- **Efectos:** 50% menos de Daño; La habilidad se repite 2 vez más; Consumo de maná ×1.80
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (46):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Propagación de Excepciones Menor

*DDR5* · grado menor · cae desde el nivel 1

Una excepción a medio capturar: salta una sola vez a otro enemigo, con bastante menos fuerza.

- **Efectos:** +1 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 30 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.15
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Propagación de Excepciones

*DDR5* · grado normal · cae desde el nivel 13

Nadie captura la excepción: las cadenas saltan 2 veces más y los proyectiles rebotan hacia otro enemigo. Cada salto pega menos, pero mejora con el nivel de la placa.

- **Efectos:** +2 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 25 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.30
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Propagación de Excepciones Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Un stack trace sin fin: 3 saltos y casi toda la fuerza en cada uno. Mejora con el nivel de la placa.

- **Efectos:** +3 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 20 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.45
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (13):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Protocolo Enjambre

*DDR4* · grado normal · cae desde el nivel 1

Escalado horizontal: +1 esbirro, dron, torreta o invocación a la vez. Cada uno pega algo menos.

- **Efectos:** +1 de Esbirros adicionales; +1 de Trampas, minas y torretas adicionales a la vez; 15% menos de Daño; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: autómata, tótem, esbirro
- **Funciona con (20):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Puntero Salvaje Menor

*DDR4* · grado menor · cae desde el nivel 1

Los proyectiles atraviesan a 1 enemigo más. Un solo array mal indexado.

- **Efectos:** 5% más de Daño; Los proyectiles atraviesan 1 enemigos más; Consumo de maná ×1.10
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Puntero Salvaje

*DDR4* · grado normal · cae desde el nivel 8

Los proyectiles atraviesan enemigos. Nadie comprobó los límites del array.

- **Efectos:** 10% más de Daño; Los proyectiles atraviesan 2 enemigos más; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Puntero Salvaje Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Los proyectiles atraviesan a 4 enemigos más. Segfault garantizado en producción.

- **Efectos:** 15% más de Daño; Los proyectiles atraviesan 4 enemigos más; Consumo de maná ×1.35
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Golem GPU, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Ráfaga Multihilo

*DDR4* · grado normal · cae desde el nivel 10

Al usar la habilidad gasta todas tus cargas de Multihilos: 15 % más de daño por carga.

- **Efectos:** Gasta tus cargas de Multihilos: 15 % más de daño por carga; Consumo de maná ×1.10
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (31):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Redundancia de Invocaciones

*DDR4* · grado normal · cae desde el nivel 13

Una instancia más de cada invocación persistente. Todas pegan un poco menos.

- **Efectos:** +1 de Esbirros adicionales; 10% menos de Daño de esbirros; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: persistente; nunca con: aura
- **Funciona con (17):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Robot Centinela, Watchdog

### Refrigeración Líquida Menor

*DDR4* · grado menor · cae desde el nivel 1

Gotea refrigerante: hiela. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de helar; +4% de Probabilidad de congelar; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Refrigeración Líquida con Fugas

*DDR4* · grado normal · cae desde el nivel 8

Gotea refrigerante sobre los enemigos: los hiela y, a veces, los congela del todo.

- **Efectos:** +30% de Probabilidad de helar; +10% de Probabilidad de congelar; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Refrigeración Líquida Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Gotea refrigerante: hiela. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de helar; +16% de Probabilidad de congelar; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Sensor de Precisión

*DDR4* · grado normal · cae desde el nivel 5

Calibra a tus autómatas: más probabilidad de crítico y de multiplicador.

- **Efectos:** 60% de aumento de Probabilidad de crítico; +25% de Multiplicador de crítico; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: autómata, tótem, esbirro; nunca con: degenerativo
- **Funciona con (18):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Escolta, Drones de Vigilancia, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Servidor Torreta

*DDR3* · grado normal · cae desde el nivel 1

Despliega una torreta que usa la habilidad sola contra el enemigo más cercano durante 8 segundos.

- **Efectos:** 25% menos de Daño; La usa una torreta durante 8 s contra el enemigo más cercano; Consumo de maná ×1.50
- **Etiquetas:** nunca con: canalizado, movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (23):** Barrido, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### Fuente Sobrealimentada

*DDR3* · grado normal · cae desde el nivel 10

Reservar más maná = más potencia: la invocación o el aura reserva un 50 % más, pero pega, aguanta y potencia mucho más.

- **Efectos:** 30% más de Daño de esbirros; 30% de aumento de Vida de esbirros; 35% de aumento de Efecto de auras; Reserva un 50 % más de maná; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: persistente
- **Funciona con (23):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Robot Centinela, Watchdog

### Fuente Sobrealimentada de Servidor

*DDR3* · grado mayor · cae desde el nivel 28

Reserva el doble de maná a cambio de un salto de potencia enorme.

- **Efectos:** 55% más de Daño de esbirros; 55% de aumento de Vida de esbirros; 60% de aumento de Efecto de auras; Reserva un 100 % más de maná; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: persistente
- **Funciona con (23):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Robot Centinela, Watchdog

### Sobrecalentamiento

*DDR3* · grado normal · cae desde el nivel 14

Convierte el daño de frío o de rayo de la habilidad en daño de fuego. Escala con los dos tipos. El ventilador ya no da más.

- **Efectos:** Convierte el daño de frío o de rayo en daño de fuego (le afectan los aumentos de ambos); Consumo de maná ×1.15
- **Etiquetas:** cualquier habilidad
- **Funciona con (16):** Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Deadlock, Drones de Vigilancia, Excepción en Cadena, Git Revert, Golem GPU, Ping Letal, Pipe de Datos, Rayo de Producción, Robot Centinela, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Sobretensión Menor

*DDR5* · grado menor · cae desde el nivel 1

Picos de voltaje: electrocuta. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de electrocutar; 7% de aumento de Daño de rayo; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Módulo de Sobretensión

*DDR5* · grado normal · cae desde el nivel 8

Picos de voltaje en cada golpe. Los enemigos electrocutados reciben más daño de todo.

- **Efectos:** +30% de Probabilidad de electrocutar; 15% de aumento de Daño de rayo; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Sobretensión Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Picos de voltaje: electrocuta. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de electrocutar; 22% de aumento de Daño de rayo; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica Menor

*DDR3* · grado menor · cae desde el nivel 1

Un mordisco de vida del disco ajeno.

- **Efectos:** +2% de Robo de vida; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica

*DDR3* · grado normal · cae desde el nivel 8

Toma prestada vida del disco duro ajeno. Sin devolverla, claro.

- **Efectos:** +3% de Robo de vida; Consumo de maná ×1.20
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Se alimenta del disco entero: mucho robo de vida.

- **Efectos:** +6% de Robo de vida; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (44):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Derrame de Aceite, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem GPU, Golem UTP, Golem de Hardware Reciclado, Golem de Kernel, Golem de Overclock, Golem del Silicio, Mainframe Titán, Mina Rodante, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Watchdog

### Torre de Señal

*DDR5* · grado normal · cae desde el nivel 12

El aura ya no te sigue: se queda clavada donde la activas, con un 30 % más de efecto y un 25 % más de alcance. Ideal para defender una posición.

- **Efectos:** 30% de aumento de Efecto de auras; El aura se queda en el suelo donde la activas (no te sigue); +25 % de alcance del aura; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: aura
- **Funciona con (6):** Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling

### Transformador de Tensión

*DDR3* · grado normal · cae desde el nivel 10

Convierte el daño físico de la habilidad en daño de rayo. Le siguen afectando los aumentos de daño físico, y ahora también los de rayo y elemental. Un Guerrero eléctrico, sin cambiar de oficio.

- **Efectos:** Convierte el daño físico en daño de rayo (le afectan los aumentos de ambos); Consumo de maná ×1.15
- **Etiquetas:** cualquier habilidad
- **Funciona con (18):** Barrido, Bot de Pruebas, Bucle Infinito, Core Dump, Daemon en Segundo Plano, Despliegue Continuo, Force Push, Fuzzing, Golem UTP, Golem de Hardware Reciclado, Golem del Silicio, Mainframe Titán, Paquete Rastreador, Proceso Hijo, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Watchdog

### Turbo sin Disipador

*DDR3* · grado mayor · cae desde el nivel 12

60 % más de daño, pero la habilidad se usa un 30 % más lento. Mucha potencia, cero refrigeración.

- **Efectos:** 60% más de Daño; 30% menos de Velocidad de ataque; 30% menos de Velocidad de lanzamiento; Desventaja fuerte: piensa bien dónde la instalas; Consumo de maná ×1.20
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (32):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Core Dump, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH

### Volcado de Buffer

*DDR3* · grado normal · cae desde el nivel 6

Al usar la habilidad gasta todas tus cargas de Buffer: te cura un 6 % de vida y la habilidad hace un 10 % más de daño por carga.

- **Efectos:** Gasta tus cargas de Buffer: 6 % de vida y 10 % más de daño por carga; Consumo de maná ×1.10
- **Etiquetas:** nunca con: aura, persistente
- **Funciona con (31):** Barrido, Bomba Lógica, Bucle Infinito, Campo de Estática, Cascada de Estilos, Charco de Refrigerante, Corrupción de Datos, Deadlock, Derrame de Aceite, Despliegue Continuo, Drones de Vigilancia, Excepción en Cadena, Flamewar, Force Push, Fork Bomb, Fuga de Memoria, Fuzzing, Git Revert, Paquete Rastreador, Ping Letal, Pipe de Datos, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow, Tormenta de Tickets, Torreta de Integración Continua, Túnel SSH


## Firmas de las habilidades (T191)

Ficha de diseño, escrita a mano (no la genera `tools/list_skills.gd`: si se regenera el archivo, hay que conservar esta sección). Dice cómo se ve y cómo suena cada una de las 62 habilidades para que de lejos se distingan sin leer el icono. La implementan T193 (cuerpo a cuerpo y movimiento), T194 (hechizos y proyectiles), T195 (buffs, gritos, barrera y auras), T196 (los sonidos de todas) y, en las invocaciones, T200-T205.

### Convenciones

- **Dibujo:** todo con primitivas de `CanvasItem` (`draw_rect`, `draw_line`, `draw_polyline`, `draw_arc`, `draw_circle`, `draw_colored_polygon`, `draw_string` con la fuente de píxel) en la rejilla del mundo (`SkillFx.GRID` = 2 px: posiciones con `_snap`, tamaños pares). Las medidas son en píxeles del mundo; «1×» y «2×» son el tamaño de la fuente de píxel. Nada de texturas nuevas.
- **Colores:** el del tipo de daño (`DAMAGE_COLORS`: físico `e8d9b0`, fuego `e0652f`, frío `7fb8e0`, rayo `e8d070`, caos `b04ad9`, sin tipo `5cb85c`) sigue siendo el principal, para que el jugador lea el daño; la firma añade un **acento** propio (se indica con su hex). Rojo de error `d9534f`, verde de OK `5cb85c`, cian de red `4ec9e0`.
- **Tiempos:** en segundos. «Al lanzar» es lo que sale en el cuadro del lanzamiento; «en vuelo» es lo que se mueve entre el lanzamiento y el golpe (proyectil, carga, salto, expansión o zona que dura); «impacto» es lo que aparece en cada enemigo golpeado o al final. Con «Menos destellos», sin núcleos blancos ni parpadeos (como `SkillFx.draw_projectile` con `dim`); con muchos enemigos en pantalla, la versión ligera quita las partículas y el texto.
- **Texto en el mundo:** como mucho una palabra corta por efecto, 1×, vida ≤ 0,6 s y que sube 8-12 px mientras se apaga; nunca encima del número de daño (va 10 px a un lado).
- **Sonido:** «base» es el sample de `Sfx.skill_sound(kind, tipo)` (con lo que corrige T192, indicado entre paréntesis donde hoy falla); «capa» es un WAV nuevo `assets/audio/sfx/sig_<id>.wav` de 0,1-0,5 s, sintetizado en `tools/generate_sfx.gd` con sus mismas piezas (`_env`, `_sq`, `_saw`, `_noise`, `_lp`, `_arpeggio`), que `SoundMap.cast_layers` pone a -6 dB en lugar de la capa compartida de `signature_layer`, con tono fijo (sin el `hash(id)`) y el mismo ±4 % al azar.

### Grupos que hoy se ven igual y cómo se separan

| Grupo de hoy | Habilidades | Qué las separa |
|---|---|---|
| `ring` (anillo que crece) | barrido, stack_overflow, core_dump | Barrido: tres arcos que **barren** 360° desde el cursor. Stack Overflow: **bloques que se apilan** sobre el jugador y se derrumban hacia fuera. Core Dump: **anillos de bloques**, uno por tipo de carga gastada. |
| `cone` | flamewar, fuzzing | Flamewar: **lenguas de llama continuas** con dos bocadillos «TAB»/«SPC». Fuzzing: **tres tajos rotos** de colores al azar con caracteres basura. |
| `trail` (estela de la carga) | deploy_continuo, force_push | Despliegue Continuo: **cinta de etapas de CI** que pasan a verde. Force Push: **flecha de commit** delante y nodos del historial tachados detrás. |
| `zap` (zigzag) | excepcion_en_cadena, tunel_ssh | Excepción: zigzag con **líneas de stack trace** y «!» por enemigo. Túnel SSH: **tubo de dos líneas paralelas** con asteriscos y un candado en cada punta. |
| `cloud` (charco) | fuga_de_memoria, git_revert | Fuga: **rejilla de celdas moradas que crece** y no se apaga. Git Revert: **rectángulo de diff** (rayas rojas y celestes) con el **fantasma** del jugador. |
| `ring` amarillo de buff | modo_seguro, hiperthreading | Modo Seguro: **hexágono gris** y esquinas «Modo seguro». Hiperthreading: **doble hélice** y un **segundo hilo** (doble del jugador) desfasado. |
| `_shout` | esta_en_produccion, daily_standup, rollback_grito | Producción: anillos **rojos** hacia fuera y **sirena**. Daily: anillo de **reloj** con aguja, amarillo. Rollback: anillos **verdes hacia dentro**. |
| Auras (arco verde igual) | las 6 | Cada una con su color y su motivo en el borde: engranajes, placas, llaves inglesas, banderas; las hostiles, anillo discontinuo hacia atrás (Throttling) y dientes hacia dentro con mira (Exposición). |
| Sonido: capa compartida con tono por id | las 62 | Cada una con su `sig_<id>` (T196). |

### Cuerpo a cuerpo y movimiento (T193)

| id | Nombre | Al lanzar | En vuelo | Impacto | Sonido: base + capa | Chiste |
|---|---|---|---|---|---|---|
| barrido | Barrido | Tres `draw_arc` concéntricos (0,6 / 0,8 / 1,0 × radio; 4, 3 y 2 px) que barren 360° en 0,18 s empezando en la dirección del cursor; físico con el arco exterior blanco. | Detrás del barrido saltan 8 «tokens» (rectángulos 4×2 gris `8a8f99`) en radial, 20 px en 0,3 s, apagándose. | En cada enemigo, una llave `{ }` de 6×10 px que se abre (las dos mitades se separan 4 px) en 0,15 s. | swing + `sig_barrido`: ruido con `_lp` que barre de 400 a 2400 Hz en 0,2 s y un clic cuadrado de 1800 Hz y 15 ms al cerrar. | Refactorizar a la vieja escuela: todo lo de alrededor sale volando y acaba entre llaves. |
| deploy_continuo | Despliegue Continuo | En el origen, tres casillas 6×6 en fila (gris, gris, verde) que se encienden una tras otra en 0,1 s. | La estela son casillas 6×6 cada 12 px a lo largo de la carga que pasan de amarillo `e8d070` a verde `5cb85c` de atrás hacia delante en 0,3 s (etapas del pipeline). | En cada enemigo atravesado, un ✓ verde de 8 px o, uno de cada cuatro, una ✗ roja; sube 10 px en 0,4 s. | swing + `sig_deploy_continuo`: tres pitidos cuadrados ascendentes 660 / 880 / 1320 Hz de 35 ms con 25 ms de silencio entre ellos. | CI/CD: el pipeline pasa aunque haya algo en rojo; ya lo arreglará el siguiente commit. |
| reinicio_forzado | Reinicio Forzado | Sobre el jugador, el símbolo de encendido (`draw_arc` de 300° y r 8 + línea vertical de 8 px, blanco) parpadea dos veces en 0,1 s. | Parábola de 0,3 s: la sombra (elipse oscura alfa 0,4) se encoge a la mitad en el punto alto; el jugador deja 3 copias fantasma (alfa 0,4 / 0,25 / 0,1). | Al caer, «pantalla azul» local: cuadrado de 0,8 × radio azul `2b4fd8` alfa 0,35 que se agrieta con 6 líneas radiales blancas de 2 px y se apaga en 0,4 s; «:(» 2× en el centro 0,3 s; temblor de cámara 3 px durante 0,15 s. | projectile (T192: swing) + `sig_reinicio_forzado`: chasquido de relé (ruido de 5 ms), seno que cae de 120 a 40 Hz en 0,25 s (disco que se para) y un pitido de POST de 1000 Hz y 80 ms. | Reiniciar el servidor a patadas, con su pitido de arranque. |
| force_push | Force Push | Una flecha de commit (triángulo 12×10 naranja `f0883e`) delante del jugador con «-f» 1× encima. | La flecha va delante durante la carga; detrás, una línea de historial con 3 nodos (círculos de 4 px) que se tachan con una X roja según pasa. | Frente de onda: 4 líneas paralelas de 2 px y 2 × radio de largo que avanzan 30 px en la dirección del empuje (alfa 0,8 → 0 en 0,25 s); cada enemigo empujado deja una estela de 3 cuadritos. | swing + `sig_force_push`: ruido con `_lp` a 300 Hz (ataque 5 ms, caída 0,18 s) sobre una sierra que baja de 220 a 110 Hz, y un clic seco al final. | `git push --force`: sobrescribe la historia de quien estuviera delante. |
| fuzzing | Fuzzing | Los tres tajos (repeats): cada uno un `draw_polyline` de 5 tramos con el ángulo movido al azar ±15° y un color al azar de cuatro (`e8d9b0`, `7fb8e0`, `e8d070`, `b04ad9`); 0,08 s cada uno. | Entre tajo y tajo, 6 caracteres basura (rectángulos de 2×4 a 4×4) que aparecen en puntos al azar del cono y viven 0,2 s. | En cada enemigo, «0x» 1× con dos píxeles de color al azar; si sangra, un bicho 6×4 rojo (cuerpo y cuatro patas) que cae 6 px. | projectile (T192: swing) + `sig_fuzzing`: tres golpes de ruido de 30 ms cada 80 ms, cada uno con un tono cuadrado al azar entre 300 y 2000 Hz. | Tirarle entradas aleatorias hasta que algo se rompe; y el bug sangra. |
| teleport_tcp | Teletransporte TCP | «SYN» 1× en el origen; un cuadrado 8×8 cian `4ec9e0` que se encoge a 2 px en 0,12 s (el jugador se empaqueta). | Un paquete (la forma `packet` de `SkillFx`, cian) va del origen al destino en 0,15 s con 3 puntos de estela. | En el destino, «ACK» 1× verde y el cuadrado crece de 2 a 12 px; anillo fino de 40 px. | blink + `sig_teleport_tcp`: pitido cuadrado de 1200 Hz (SYN) y otro de 1600 Hz (ACK), 30 ms cada uno y separados 120 ms; entre medias un trino de módem muy bajo (seno que salta entre 1800 y 2400 Hz cada 10 ms). | El saludo en tres pasos: con confirmación de entrega. |
| tunel_ssh | Túnel SSH | En el origen, un candado 8×10 (arco + rectángulo) amarillo que se cierra (el arco baja 2 px) en 0,1 s, y la descarga: 6 zigzags radiales hasta el radio. | Un tubo: dos líneas paralelas de 2 px separadas 10 px entre origen y destino, alfa 0,6, con 4 asteriscos (cruces de 4 px) que corren por dentro en 0,2 s. | En el destino el candado aparece abierto y una llave 10×4 gira 90°; la misma descarga radial. | blink + `sig_tunel_ssh`: clic metálico (ruido filtrado a 3 kHz, 10 ms), zumbido cuadrado de 60 Hz 0,15 s y otro clic. | Sin contraseña: la clave pública ya la tenías, el candado se abre solo. |
| git_revert | Git Revert | En la posición de partida queda el fantasma del jugador (su silueta rellena de celeste alfa 0,5), que dura lo que la zona y parpadea cada 0,5 s. | Salto hacia atrás de 0,25 s con una flecha curva (`draw_arc` de 180° + punta) sobre la cabeza. | La zona helada es un rectángulo de diff: rayas horizontales de 2 px cada 6 px alternando rojo (líneas quitadas) y celeste (las añadidas, que se congelan), con escarcha de 2×2 en el borde; dura lo que la zona. | blink + `sig_git_revert`: el arpegio de tres notas del buff al revés (sol-mi-do) en 0,2 s y un chime al final. | Deshacer el último commit: queda el fantasma de la versión anterior. |

### Hechizos y proyectiles (T194)

| id | Nombre | Al lanzar | En vuelo | Impacto | Sonido: base + capa | Chiste |
|---|---|---|---|---|---|---|
| ping_letal | Ping Letal | «64 bytes» 1× sobre el jugador 0,3 s y un destello cuadrado de 6 px. | Nueva firma `sonar` en `SkillFx.SIGNATURES`: punto 4×4 blanco con dos arcos de radar delante (`draw_arc` de 60°, r 8 y 14) que se redibujan cada 0,1 s; amarillo. | En cada enemigo atravesado, un tiempo de respuesta («12ms», al azar de 1 a 99) 1× que sube 8 px; en el último, un círculo de eco que crece de 0 a 24 px. | lightning + `sig_ping_letal`: «ping» de seno a 1760 Hz con caída de 0,25 s y su eco a -12 dB 0,12 s después. | Ping: 64 bytes de dolor, tiempo de respuesta el tuyo. |
| fork_bomb | Fork Bomb | En el punto, un cuadrado naranja de 6×6. | Durante el retardo, el cuadrado se divide: 2, 4, 8 y 16 copias (una vez cada cuarto del retardo), cada copia de 6×6 que se aparta de su madre hasta llenar el radio. | Las 16 estallan a la vez, cada una con su círculo de 4 a 10 px, y luego el anillo del radio; tres bocanadas de humo gris. | explosion + `sig_fork_bomb`: clics cuadrados de 900 Hz que se duplican en el tiempo del retardo (1, 2, 4 y 8 por cuarto), acabando justo antes de la explosión. | `:(){ :\|:& };:` — el proceso que se copia a sí mismo hasta tumbar la máquina. |
| stack_overflow | Stack Overflow | Sobre el jugador se apilan 5 bloques de 16×4 celestes, uno cada 0,03 s; el último, rojo. | La pila se derrumba: 8 bloques salen en las 8 direcciones deslizándose hasta el radio en 0,25 s, dejando escarcha (cuadritos 2×2 blancos). | Cada enemigo queda encerrado 0,3 s en un cuadro de hielo de 2 px de borde, un poco más grande que él. | cold + `sig_stack_overflow`: cinco notas cuadradas que suben de 440 a 990 Hz cada 30 ms (push, push, push…) y un glissando hacia abajo de 0,15 s. | La pila no da para más (y la web de preguntas que se llama igual). |
| flamewar | Flamewar | Dos bocadillos de comentario 10×8 (rectángulo + piquito) en los bordes del cono, uno con «TAB» y otro con «SPC», 0,35 s. | El cono son 3 lenguas de llama (polígonos de 5 puntos que tiemblan ±2 px) que avanzan hasta el radio en 0,25 s, naranja y amarillo `ffc04a`; brasas «!» rojas que saltan. | En cada enemigo, un bocadillo «>:(» de 8 px que arde y se encoge en 0,3 s. | fire + `sig_flamewar`: dos «voces» que discuten (sierras de 300 y 340 Hz moduladas a 18 Hz) pisándose 0,25 s. | El hilo de tabuladores contra espacios. |
| rayo_produccion | Rayo de Producción | Durante el retardo, una barra de progreso 20×4 que se llena sobre el jugador; el marcador del rayo es una línea discontinua con «main» 1× cada 60 px. | Rayo del ancho de la habilidad: núcleo blanco de 4 px y halo amarillo, con 3 franjas de alarma rojo/amarillo que corren a lo largo; dura 0,25 s. | Al final de la línea, «500» 2× rojo que cae 10 px; cada enemigo golpeado chispea (4 píxeles amarillos). | lightning + `sig_rayo_produccion`: seno que sube de 200 a 1200 Hz en lo que dura la carga y una sirena de dos tonos (800 / 600 Hz cada 60 ms) al disparar. | Desplegado en main un viernes, sin revisión. |
| deadlock | Deadlock | Dos candados 8×10 a los lados del jugador y dos flechas curvas que se persiguen en círculo (r 0,5 × radio), una vuelta en 0,6 s. | Un anillo de cadena (eslabones de 6×3 que alternan horizontal y vertical cada 12 px) que se expande hasta el radio en 0,2 s. | Sobre cada enemigo aturdido, un reloj de arena de 6×8 que gira mientras dura el aturdimiento; escarcha alrededor. | cold + `sig_deadlock`: dos tonos cuadrados disonantes (440 y 466 Hz) que se alternan cada 50 ms durante 0,3 s y se cortan en seco. | Dos procesos esperándose el uno al otro para siempre. |
| excepcion_en_cadena | Excepción en Cadena | «throw» 1× naranja sobre el jugador. | Cada salto es un zigzag amarillo con una tira de 3 rectángulos 4×2 (líneas del stack trace) que corre por encima; el grosor baja de 4 a 2 px en cada salto. | En cada enemigo, un triángulo de aviso de 10 px con «!» rojo; en el último, «Uncaught» 1×. | lightning + `sig_excepcion_en_cadena`: dos notas cuadradas de error (880 → 660 Hz, 60 ms cada una). | Una excepción que nadie captura. |
| fuga_de_memoria | Fuga de Memoria | Una gota morada de 6×8 cae del jugador al punto en 0,15 s. | El charco es una rejilla de celdas de memoria 6×6 moradas con borde claro que se encienden una a una y no se apagan: crece del 60 % al 100 % del radio a lo largo de su duración. | Sobre quien lo pisa suben burbujas con «MB» 1× (una cada 0,5 s). | chaos + `sig_fuga_de_memoria`: goteo (tres senos que caen de 600 a 300 Hz, 40 ms cada 0,1 s) sobre un borboteo de ruido con `_lp`. | Memoria que nunca se libera y no para de crecer. |
| core_dump | Core Dump | Un volcado hexadecimal: 12 rectángulos de texto 4×2 gris claro salen del jugador en espiral en 0,2 s. | Un anillo de 16 bloques 6×6 que llega al radio en 0,25 s; por cada tipo de carga gastado, otro anillo de bloques de su color con 0,05 s de retraso (Buffer verde, Multihilos azul `5a8fd8`, Overclock rojo). Sin cargas, un solo anillo fino gris: el volcado discreto. | «core» 1× en cada enemigo; los críticos (con Overclock) con un destello blanco de 0,1 s. | projectile (T192: thump) + `sig_core_dump`: ráfaga de bits (ruido retenido a 2 kHz) de 0,2 s y un golpe grave de 60 Hz y 50 ms por cada tipo de carga gastado. | *Segmentation fault (core dumped).* |

### Buffs, gritos, barrera y auras (T195)

En las auras, «al lanzar» es al activarla, «en vuelo» es lo que se ve mientras está activa (en el borde de su radio) e «impacto» es lo que se ve en los aliados o enemigos de dentro. Al desactivarla, el anillo se desdibuja en sentido contrario en 0,2 s.

| id | Nombre | Al lanzar | En vuelo | Impacto | Sonido: base + capa | Chiste |
|---|---|---|---|---|---|---|
| firewall_personal | Firewall Personal | 12 ladrillos 8×4 color ladrillo `a04a3a` con junta gris se colocan en anillo de r 26 px alrededor del jugador, uno cada 0,02 s. | Mientras dura la barrera, el anillo de ladrillos a alfa 0,35 con una llamita de 4 px que lo recorre (1 vuelta/s); al acabarse, los ladrillos caen 6 px y se apagan. | Al absorber un golpe, el ladrillo del lado del golpe parpadea en blanco y suelta «DENY» 1×. | barrier + `sig_firewall_personal`: seis «clacs» de ladrillo (ruido filtrado a 1500 Hz, 8 ms) en 0,12 s y un chime grave de 330 Hz. | Un muro de fuego… hecho de ladrillo. |
| modo_seguro | Modo Seguro | En un cuadrado de 120 px, velo negro alfa 0,4 con «Modo seguro» 1× en las cuatro esquinas, 0,6 s. | Hexágono de 2 px gris claro alrededor del jugador, sin brillo, mientras dura; el jugador lleva una sombra cuadrada más ancha (va pesado). | Al recibir un golpe, el hexágono destella en gris 0,1 s. | buff + `sig_modo_seguro`: acorde grave apagado (cuadradas de 220 y 262 Hz con `_lp`) 0,4 s. | Arrancar en modo seguro: feo y lento, pero no se rompe. |
| hiperthreading | Hiperthreading | Dos hélices de puntos 2×2 (amarillo y cian) que se trenzan alrededor del jugador de los pies a la cabeza en 0,4 s. | Un doble del jugador a alfa 0,25, 3 px detrás, que lo sigue con 0,05 s de retraso (el segundo hilo) mientras dura. | Cada ataque o lanzamiento suelta dos destellos de mano en vez de uno. | buff + `sig_hiperthreading`: el mismo arpegio rápido (do-mi-sol) dos veces desfasado 20 ms: suena doble. | Dos hilos por núcleo. |
| esta_en_produccion | ¡Está en producción! | Tres anillos rojos de 2 px que salen hasta 120 px en 0,4 s; «¡PROD!» 2× rojo que tiembla ±1 px sobre el jugador 0,8 s; una luz de sirena (semicírculo que gira, rojo y azul alternos) encima. | Sobre cada invocación afectada, un «!» rojo que parpadea mientras dura. | — | buff + `sig_esta_en_produccion`: sirena de dos tonos (960 / 770 Hz), dos ciclos en 0,5 s. | Alguien rompió producción y de repente todos trabajan. |
| daily_standup | ¡Daily en cinco minutos! | Anillo amarillo con 12 marcas de hora y una aguja que da una vuelta en 0,5 s mientras crece hasta 120 px; «¡DAILY!» 2× amarillo. | Sobre cada invocación, un relojito de 6 px; el jugador deja huellas de prisa (2×2 cada 0,1 s) mientras dura. | — | buff + `sig_daily_standup`: tic-tac (clics de 2 y 1,5 kHz) que se acelera cuatro veces y un «ding» de calendario (seno de 1320 Hz con su armónico). | La reunión de quince minutos que dura una hora. |
| rollback_grito | ¡Rollback! | Tres anillos verdes que se cierran desde 120 px hasta el jugador en 0,4 s (al revés que los otros gritos); «¡ROLLBACK!» 2× verde con una flecha curva. | — | Las invocaciones curadas sueltan «+» verdes de 4 px que suben. | buff + `sig_rollback_grito`: ruido con la envolvente al revés (sube 0,3 s y se corta en seco) y un arpegio descendente. | Volver a la última versión que funcionaba. |
| aura_overclock | Aura de Overclock | El anillo naranja `ff8a2a` se dibuja de 0 a 360° en 0,3 s. | 8 engranajes de 6 px (círculo + 4 dientes) sobre el borde que giran (1 vuelta cada 3 s) mientras recorren el anillo. | Las invocaciones de dentro sueltan una chispa 2×2 amarilla cada 0,5 s. | aura_on + `sig_aura_overclock`: ventilador que acelera (ruido con `_lp` a 800 Hz modulado de 10 a 30 Hz en 0,3 s). | Subirle el reloj a todo lo que tienes. |
| aura_blindaje | Aura de Blindaje Redundante | El anillo gris acero `a0a8b8` aparece con 6 placas que caen en su sitio una a una en 0,3 s. | 6 placas 10×6 con dos remaches de 2 px, quietas sobre el borde, con un brillo que las recorre cada 2 s. | Las invocaciones de dentro llevan un contorno gris de 2 px. | aura_on + `sig_aura_blindaje`: dos «clanks» (ruido filtrado a 2 kHz + seno de 420 Hz, 0,1 s cada uno): N+2. | Redundancia N+2: si una cae, quedan dos. |
| aura_mantenimiento | Aura de Mantenimiento Continuo | El anillo verde se dibuja en 0,3 s y 4 llaves inglesas (10×4, cabeza abierta) caen en sus puntos cardinales. | Las 4 llaves orbitan despacio (1 vuelta cada 5 s) girando sobre sí mismas. | Cada segundo, un «+» verde de 4 px sube de cada aliado curado (y del jugador). | aura_on + `sig_aura_mantenimiento`: carraca (seis clics de 3 kHz cada 25 ms) y un chime. | Un cron que lo repara todo cada minuto. |
| aura_mando | Aura de Mando | El anillo dorado `ffc04a` y 4 banderitas (palo 2×10 + triángulo de 6 px) que se clavan en los puntos cardinales. | Las banderas ondean (el triángulo oscila 1 px a 4 Hz) mientras está activa. | Sobre cada aliado de dentro, una estrella de 4 px que brilla al hacer un crítico. | aura_on + `sig_aura_mando`: fanfarria de dos notas cuadradas (784 y 1046 Hz). | El jefe de equipo da órdenes claras (por una vez). |
| aura_throttling | Aura de Throttling | Anillo azul `5a8fd8` discontinuo (8 trazos con hueco) que aparece de golpe. | Los 8 trazos giran hacia atrás, despacio (1 vuelta cada 6 s). | Cada enemigo que entra recibe «429» 1× una vez y un reloj de arena de 6×8 sobre la cabeza mientras está dentro. | aura_on + `sig_aura_throttling`: tres «bips» graves cuadrados de 220 Hz con `_lp`, espaciados 0,15 s. | *HTTP 429 Too Many Requests.* |
| aura_exposicion | Aura de Exposición de Vulnerabilidades | Anillo rojo `d9534f` con dientes de sierra hacia dentro (triángulos de 4 px cada 16 px). | Una mira (cruz de 8 px + círculo) salta de un enemigo de dentro a otro cada 0,5 s. | Sobre cada enemigo de dentro, la etiqueta «CVE» 1× roja fija mientras está dentro. | aura_on + `sig_aura_exposicion`: alerta de dos tonos (1200 / 900 Hz, 40 ms) y un seno de escáner que barre a 2400 Hz. | Publicar los CVE de todo lo que te rodea. |

### Con efecto visual propio (solo sonido, T196)

Ya se distinguen a la vista; la tabla dice lo que tienen y su sonido. Los detalles de variante y de RAM van en T197.

| id | Nombre | Al lanzar | En vuelo | Impacto | Sonido: base + capa | Chiste |
|---|---|---|---|---|---|---|
| rafaga_de_paquetes | Ráfaga de Paquetes | Destello `flick`. | Paquetes en abanico (`packet`: rectángulo con cabecera clara). | `shards`. | projectile + `sig_rafaga_de_paquetes`: 5 clics cuadrados de 1400 Hz en 0,1 s a los que les faltan uno o dos al azar. | Es UDP: algunos llegan. |
| pipe_de_datos | Pipe de Datos | Canalizado. | Flujo continuo de rayo. | Chispas. | lightning + `sig_pipe_de_datos`: zumbido cuadrado de 120 Hz con `_lp` que se repite mientras se canaliza. | La tubería de Unix: `\|` y todo lo de un lado sale por el otro. |
| tormenta_tickets | Tormenta de Tickets | Canalizado. | Tormenta que crece y sigue al cursor. | Escarcha. | cold + `sig_tormenta_tickets`: papeles (ráfagas de ruido filtrado a 4 kHz de 20 ms) y un «ding» de ticket nuevo cada 0,5 s. | La cola de tickets que nunca baja. |
| rollback | Rollback | Destello `flick`. | El arma gira de ida y vuelta. | `shards` a la ida y a la vuelta. | projectile + `sig_rollback`: whoosh que sube de tono a la ida y baja a la vuelta (0,4 s). | `git revert`: deshace todo lo que toca. |
| bucle_infinito | Bucle Infinito | — | Giro continuo con el arma. | `shards` en cada tick. | swing + `sig_bucle_infinito`: whoosh corto en cada tick que sube un semitono por vuelta hasta cuatro y vuelve a empezar. | `while (true) { girar(); }` |
| bomba_logica | Bomba Lógica | Se esconde en el suelo. | Trampa que parpadea al armarse. | Explosión de caos. | trap + `sig_bomba_logica`: dos clics de reloj (tic-tac) al ponerla. | `if (cerca) boom();` |
| ransomware | Ransomware | — | Zona `curse`. | Daño por segundo. | chaos + `sig_ransomware`: candado que se cierra (clic metálico) y una caja registradora (senos de 1568 y 2093 Hz). | Cifrarlo todo y pedir rescate; no pagarán. |
| corrupcion_datos | Corrupción de Datos | Destello `glitch`. | Firma `glitch` (franja que tiembla). | `splat` y caos por segundo. | chaos + `sig_corrupcion_datos`: ruido retenido a frecuencias al azar (50-4000 Hz) en trozos de 15 ms, 0,15 s. | Un paquete corrupto que lo pudre todo. |
| paquete_rastreador | Paquete Rastreador | Destello `flick`. | `tracker`: paquete con antena que parpadea y estela de puntos. | `shards`. | projectile + `sig_paquete_rastreador`: dos pips de radar de 2 kHz separados 80 ms. | Nadie escapa del tracking. |
| torreta_ci | Torreta de Integración Continua | Se despliega la torreta. | Proyectiles teledirigidos (`bolt`). | `zapburst`. | trap + `sig_torreta_ci`: servo (sierra de 300 a 500 Hz, 0,15 s) y un clic de bloqueo. | Tú programas; ella pelea (y ejecuta los tests). |
| derrame_aceite | Derrame de Aceite | Anillo. | Terreno de aceite (y fuego si prende). | Resbalan y van lentos. | fire + `sig_derrame_aceite`: «glug, glug» (dos burbujas de seno a 180 Hz con vibrato). | El aceite del ventilador que nadie cambió. |
| campo_estatica | Campo de Estática | Anillo. | Terreno con chispas. | Rayo por segundo. | lightning + `sig_campo_estatica`: crepitar (ruido con picos al azar) 0,3 s. | Tocar el chasis sin pulsera antiestática. |
| charco_refrigerante | Charco de Refrigerante | Anillo. | Terreno helado. | Frío y lentitud. | cold + `sig_charco_refrigerante`: chorro (ruido con `_lp` a 1200 Hz, 0,3 s) y un gorgoteo. | La refrigeración líquida que gotea. |
| cascada_css | Cascada de Estilos | Marcador de la zona. | Lluvia de impactos. | Hielo en cada impacto. | cold + `sig_cascada_css`: cinco clics que bajan de 1568 a 784 Hz (un `!important` tras otro). | La cascada de estilos: el último `!important` gana. |

### Invocaciones (cuerpos ya propios, T200-T205)

Los cuerpos ya los dibuja `UnitArt`; aquí «al lanzar» es cómo **aparecen** (T201), «en vuelo» cómo **atacan** (T202) e «impacto» cómo **mueren** o desaparecen (T201). T200 pone el motor (dirección y estados), T203 lo que no cumple su descripción, T204 el arte de las rígidas (Proceso Hijo, Drones) y T205 los acompañantes. El sonido de todas va en T196; hoy la base sale del tipo de daño (y las sin daño, de `projectile`), y T192 la pasa a `summon`.

| id | Nombre | Al lanzar | En vuelo | Impacto | Sonido: base + capa | Chiste |
|---|---|---|---|---|---|---|
| proceso_hijo | Proceso Hijo | «fork()» 1× y una caja de 8 px que se parte en dos procesitos que se separan en 0,3 s (T204). | Embestida corta de 6 px. | Al caducar, «exit 0» 1× y cada uno se deshace en 4 bits. | summon + `sig_proceso_hijo`: dos clics iguales de 1 kHz separados 40 ms. | `fork()`: dos hijos sin documentar que obedecen. |
| drones_vigilancia | Drones de Vigilancia | Los 3 drones bajan desde 30 px con la hélice (línea de 6 px que alterna largo y corto a 20 Hz) (T204). | Mira roja 0,1 s antes de cada rayo recto. | Al caducar, caen girando y rebotan una vez. | summon + `sig_drones_vigilancia`: hélice (sierra de 180 Hz con trémolo de 25 Hz), 0,4 s. | Vigilancia 24/7. |
| robot_centinela | Robot Centinela | Se ensambla de abajo arriba (patas, cuerpo, cabeza) en 0,4 s. | La cabeza apunta y retrocede 2 px en cada láser. | Se le cae la cabeza con una chispa. | lightning (T192: summon) + `sig_robot_centinela`: servo y un «bip-bup» (880 / 1320 Hz). | El centinela que no duerme. |
| daemon_segundo_plano | Daemon en Segundo Plano | Sale de un «&» 2× que se disuelve en 0,3 s. | Embestida con el tridente. | «SIGKILL» 1× y se apaga en franjas horizontales. | projectile (T192: summon) + `sig_daemon_segundo_plano`: batido grave (sierras de 110 y 116 Hz) 0,3 s. | `comando &`: corre en segundo plano para siempre. |
| dron_escolta | Dron Escolta | Despega del hombro y sube a su órbita con una estela de 3 puntos. | La bengala sale en arco y deja chispas. | Al cancelarlo, se aleja hacia arriba y se apaga. | fire (T192: summon) + `sig_dron_escolta`: rotor y el chasquido de la bengala. | Escolta armada que vuela demasiado alto. |
| golem_hardware | Golem de Hardware Reciclado | Cuatro torres de PC caen una a una y se apilan en 0,5 s con polvo. | Golpe al suelo con grietas radiales; «!» rojo sobre los provocados. | Se desarma en torres y cables que caen. | projectile (T192: summon) + `sig_golem_hardware`: clanks y un ventilador viejo que arranca (ruido que sube). | Hecho con lo que había en el almacén. |
| mainframe_titan | Mainframe Titán | Las bobinas de cinta giran y se levanta en 0,6 s; las filas de luces se encienden de arriba abajo. | El ojo carga el láser 0,3 s (punto que crece); terremoto. | Las luces se apagan una a una. | projectile (T192: summon) + `sig_mainframe_titan`: zumbido de 50 Hz y cinta (ruido modulado a 8 Hz). | Un COBOL de los 80 con piernas. |
| dron_medico | Dron de Mantenimiento | Una cruz verde que gira 360° en 0,3 s. | Rayo de curación verde punteado hacia el objetivo. | Al cancelarlo, la cruz se apaga. | projectile (T192: summon) + `sig_dron_medico`: chime suave de dos notas ascendentes. | El de IT con el botiquín: «¿probaste a reiniciarlo?» |
| dron_escudo | Dron Cortafuegos | Un ladrillito que gira y se convierte en el dron. | Lanza tres ladrillos que forman la barrera sobre el jugador. | Al cancelarlo, el ladrillo cae. | projectile (T192: summon) + `sig_dron_escudo`: «clac» de ladrillo y chime. | Un cortafuegos portátil. |
| bot_pruebas | Bot de Pruebas | «test» 1× y un ✓ verde. | Salta y al caer «PASS» o «FAIL» 1× al azar. | «FAIL» rojo y se rompe en dos. | physical (T192: summon) + `sig_bot_pruebas`: bip de PASS (1320 Hz) o de FAIL (330 Hz). | Los tests en verde que no prueban nada. |
| mina_rodante | Mina Rodante | Cae y rebota dos veces. | Los radios de las ruedas giran según la velocidad. | Estalla en un anillo y piezas que salen volando. | fire (T192: summon) + `sig_mina_rodante`: tic-tac rápido y un chirrido de ruedas. | `rm -rf` con ruedas. |
| agente_ia | Agente IA | «Pensando…» 1× con los puntos animados 0,6 s antes de aparecer. | Proyectiles con estrellitas de 4 puntas; el charco tóxico parpadea en colores al azar (alucinación). | Se desvanece en franjas de colores. | chaos (T192: summon) + `sig_agente_ia`: arpegio de 4 notas al azar de una escala pentatónica (seguro de sí mismo) y un glitch al final. | Alucina con mucha confianza. |
| watchdog | Watchdog | «WOOF» 1× y una sacudida. | Mordida con embestida; salto al lejano. | Se tumba y suelta un «Zz». | physical (T192: summon) + `sig_watchdog`: ladrido corto (`_scream` breve con f0 400 Hz). | El watchdog timer que reinicia lo que se cuelga. |
| bot_rastreador | Bot Rastreador de Bugs | Una lupa que barre de lado a lado. | Dardo verde con un bicho dibujado. | Se rompe la lente. | chaos (T192: summon) + `sig_bot_rastreador`: zumbido de insecto (sierra de 220 Hz con trémolo de 60 Hz), 0,2 s. | El QA que no se cansa. |
| golem_silicio | Golem del Silicio | Obleas circulares (círculos de 10 px con rejilla) que se apilan con destellos de cristal. | Golpe al suelo con esquirlas de cristal. | Se rompe en obleas que ruedan. | physical (T192: summon) + `sig_golem_silicio`: `hit_crystal` y un chime agudo. | Hecho de arena, literalmente. |
| golem_overclock | Golem de Overclock | Las aletas del disipador se ponen al rojo de abajo arriba; píxeles de calor que suben ondulando. | Golpes rápidos y salto al lejano con estela roja. | Se enfría a gris y humea. | fire (T192: summon) + `sig_golem_overclock`: ventilador que se acelera y chisporroteo. | 5 GHz y sin pasta térmica. |
| golem_utp | Golem UTP | Cables que salen del suelo y se enredan en 0,5 s. | Latigazo con un RJ45 en la punta; al atraer, una línea que tira de los enemigos. | Se desenreda en cables sueltos. | physical (T192: summon) + `sig_golem_utp`: chasquido de látigo (ruido de 3 ms + sierra de 2 kHz a 500 Hz) y el clic del RJ45. | El armario de cables que nadie se atreve a abrir. |
| golem_gpu | Golem GPU | Los ventiladores arrancan (las aspas aceleran) y el RGB recorre el arcoíris. | Rayo trazado en línea con píxeles que rebotan en los enemigos. | Los ventiladores se paran y el RGB se apaga. | lightning (T192: summon) + `sig_golem_gpu`: pitido de bobina (seno de 8 kHz muy bajo) y ventilador. | Ray tracing, literalmente. |
| golem_kernel | Golem de Kernel | Líneas de «panic» que se condensan en el espectro. | Aura de corrupción con franjas de glitch. | Se deshace en un volcado de texto que cae. | chaos (T192: summon) + `sig_golem_kernel`: zumbido grave de 55 Hz con glitch. | *Kernel panic*. |

