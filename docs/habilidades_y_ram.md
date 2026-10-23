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
- **Cifras:** maná 9, enfriamiento 0.8 s, daño 23-37, radio 110, dura 20.0 s
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

### Cascada de Estilos

*lluvia de impactos* · Destreza (DDR4) · daño: frío · ataque (usa el arma)

Haces llover hojas de estilo heladas sobre una zona: !important tras !important, cada impacto congela un poco más el diseño (y a los enemigos).

- **Etiquetas:** ataque, proyectil, área, frío, elemental
- **Cifras:** maná 10, enfriamiento 3.0 s, daño 1-3, radio 150, dura 1.2 s
- **Estados extra:** helado 15 %
- **Hito (niveles 10, 20, 30):** +2 impactos
- **Inicial de:** Desarrolladora Frontend

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
- **Cifras:** maná 8, daño 11-20, radio 210
- **Estados extra:** quemado 20 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Desarrollador Full Stack

### Fork Bomb

*explosión en el suelo* · Inteligencia (DDR5) · daño: fuego · hechizo

Marca un punto y deja que se replique hasta explotar. :(){ :|:& };:

- **Etiquetas:** hechizo, área, fuego, elemental
- **Cifras:** maná 9, daño 13-23, radio 85
- **Estados extra:** quemado 15 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Científico de Datos

### Fuga de Memoria

*charco degenerativo* · Inteligencia (DDR5) · daño: caos · hechizo

Deja un charco de memoria sin liberar que corroe a quien lo pisa. Daño por segundo mientras estén dentro.

- **Etiquetas:** hechizo, área, caos, degenerativo, duración
- **Cifras:** maná 10, daño 9-13 por segundo, radio 115, dura 4.5 s
- **Hito (niveles 10, 20, 30):** +10 % de área

### Fuzzing

*cono* · Destreza (DDR4) · daño: físico · ataque (usa el arma)

Bombardeas al enemigo con entradas aleatorias: tres tajos rapidísimos en cono. Alguno encuentra el bug, y el bug sangra.

- **Etiquetas:** ataque, cuerpo a cuerpo, área, físico
- **Cifras:** maná 6, daño 1-3, radio 135
- **Estados extra:** sangrando 20 %
- **Hito (niveles 10, 20, 30):** +10 % de área
- **Inicial de:** Tester QA

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
- **Cifras:** maná 6, daño 2-5, 3 proyectiles
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

### Torreta de Integración Continua

*proyectiles teledirigidos* · Inteligencia (DDR5) · daño: rayo · hechizo

Despliegas una torreta armada con piezas de servidor que dispara sola proyectiles teledirigidos al enemigo más cercano. Tú programas; ella pelea.

- **Etiquetas:** hechizo, proyectil, rayo, elemental, tótem, duración, autómata, teledirigido
- **Cifras:** maná 14, enfriamiento 1.0 s, daño 7-14, 2 proyectiles teledirigidos
- **Estados extra:** electrocutado 10 %
- **Hito (niveles 10, 20, 30):** +1 proyectil
- **Inicial de:** Ingeniero DevOps

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
- **Cifras:** maná 16, enfriamiento 6.0 s, daño 4-8, 1 proyectil, dura 10.0 s
- **Estados extra:** electrocutado 5 %
- **Hito (niveles 10, 20, 30):** +1 dron
- **Invoca:** 3 drones que te orbitan 10 s y disparan cada 1.0 s al enemigo más cercano
- **Inicial de:** Ingeniero DevOps

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

### Mina Rodante

*invocación persistente* · Destreza (DDR4) · daño: fuego · hechizo

Una bomba con ruedas que persigue al enemigo más cercano y explota al morir (y a veces antes). Cuando estalla, la vuelves a lanzar. Persistente.

- **Etiquetas:** hechizo, esbirro, autómata, persistente, área, fuego, elemental
- **Cifras:** reserva 10 % del maná, enfriamiento 1.0 s, daño 18-30, radio 95
- **Estados extra:** quemado 30 %
- **Hito (niveles 10, 20, 30):** +25 % de daño y área de la explosión
- **Comportamiento:** cuerpo a cuerpo: persigue al enemigo más cercano; hasta 2 a la vez; vida 55; ataca cada 1.4 s; alcance 480
- **Habilidad propia:** kamikaze: al tocar a un enemigo (o al caer) explota en un radio de 95
- **Se desbloquea con:** Tester QA (nv. 16, a elegir), Desarrolladora Frontend (nv. 16, a elegir)

### Proceso Hijo

*esbirros temporales* · Inteligencia (DDR5) · daño: físico · hechizo

fork() y dos procesos hijos salen a pelear por ti durante un rato. No los has documentado, pero obedecen.

- **Etiquetas:** hechizo, esbirro, duración, físico, autómata
- **Cifras:** maná 14, enfriamiento 1.0 s, daño 6-11, dura 14.0 s
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
- **Cifras:** reserva 13 % del maná, enfriamiento 1.0 s, daño 7-12
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

### RAM de Alto Voltaje Menor

*DDR5* · grado menor · cae desde el nivel 1

Un voltio más. La garantía todavía aplica.

- **Efectos:** 15% más de Daño elemental; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (12):** Deadlock, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Mina Rodante, Ping Letal, Rayo de Producción, Robot Centinela, Stack Overflow, Torreta de Integración Continua

### RAM de Alto Voltaje

*DDR5* · grado normal · cae desde el nivel 8

Más voltios para tus hechizos elementales. La garantía no cubre esto.

- **Efectos:** 30% más de Daño elemental; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (12):** Deadlock, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Mina Rodante, Ping Letal, Rayo de Producción, Robot Centinela, Stack Overflow, Torreta de Integración Continua

### RAM de Alto Voltaje Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Voltaje de planta industrial: mucho más daño elemental de hechizos.

- **Efectos:** 45% más de Daño elemental; Consumo de maná ×1.60
- **Etiquetas:** con alguna de: hechizo; que además sea: elemental; nunca con: movimiento, potenciador
- **Funciona con (12):** Deadlock, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Mina Rodante, Ping Letal, Rayo de Producción, Robot Centinela, Stack Overflow, Torreta de Integración Continua

### Amplificador de Aura

*DDR5* · grado normal · cae desde el nivel 8

Sube el volumen de tu aura: sus bonificaciones son mucho más potentes. Reserva algo más de maná.

- **Efectos:** 40% de aumento de Efecto de auras; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: aura
- **Funciona con (6):** Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling

### Bypass de Firewall

*DDR4* · grado normal · cae desde el nivel 10

Los proyectiles atraviesan a 3 enemigos más y van más rápido. Nadie configuró las reglas de salida.

- **Efectos:** 25% de aumento de Velocidad de proyectiles; Los proyectiles atraviesan 3 enemigos más; Consumo de maná ×1.25
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Caché L3 Menor

*DDR5* · grado menor · cae desde el nivel 1

Un poco más de caché: +20 % de área.

- **Efectos:** 20% de aumento de Área de efecto; Consumo de maná ×1.15
- **Etiquetas:** con alguna de: área
- **Funciona con (16):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Cascada de Estilos, Deadlock, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow

### Caché L3 Ampliada

*DDR5* · grado normal · cae desde el nivel 1

Más espacio para todo. Sobre todo para explosiones.

- **Efectos:** 40% de aumento de Área de efecto; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: área
- **Funciona con (16):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Cascada de Estilos, Deadlock, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow

### Caché L3 Masiva

*DDR5* · grado mayor · cae desde el nivel 26

Caché de servidor: +65 % de área.

- **Efectos:** 65% de aumento de Área de efecto; Consumo de maná ×1.45
- **Etiquetas:** con alguna de: área
- **Funciona con (16):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Cascada de Estilos, Deadlock, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow

### Carcasa Reforzada

*DDR3* · grado normal · cae desde el nivel 1

Chapa de servidor atornillada a tus esbirros: mucha más vida y algo más de daño.

- **Efectos:** 50% de aumento de Vida de esbirros; 10% más de Daño de esbirros; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: esbirro
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Proceso Hijo, Robot Centinela, Watchdog

### Detonador de Mina

*DDR5* · grado normal · cae desde el nivel 1

Entierras una mina casi invisible que tarda en armarse, pero ejecuta la habilidad con más fuerza al pasar un enemigo. Hasta 5 a la vez.

- **Efectos:** 20% más de Daño; Se entierra como mina: tarda en armarse, se activa al pasar un enemigo (máx. 5); Consumo de maná ×1.35
- **Etiquetas:** nunca con: movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (19):** Barrido, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Deadlock, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### Disipador de Calor

*DDR3* · grado normal · cae desde el nivel 1

Concentra la potencia en menos espacio. Como meter todo el backend en un solo archivo.

- **Efectos:** 30% más de Daño; 25% menos de área; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: área
- **Funciona con (16):** Agente IA, Barrido, Bomba Lógica, Bucle Infinito, Cascada de Estilos, Deadlock, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Ransomware, Rayo de Producción, Reinicio Forzado, Stack Overflow

### Disparador de Trampa

*DDR4* · grado normal · cae desde el nivel 1

La habilidad ya no se lanza: tiras una trampa que la ejecuta cuando un enemigo pasa cerca. Hasta 3 a la vez.

- **Efectos:** 10% más de Daño; Se lanza como trampa: se activa al acercarse un enemigo (máx. 3); Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (19):** Barrido, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Deadlock, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### RAM ECC Menor

*DDR5* · grado menor · cae desde el nivel 1

Corrige errores de memoria... algunos. Un poco más de crítico.

- **Efectos:** 30% de aumento de Probabilidad de crítico; +10% de Multiplicador de crítico; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (29):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### RAM ECC

*DDR5* · grado normal · cae desde el nivel 8

Corrige errores de memoria. Y provoca errores críticos en tus enemigos.

- **Efectos:** 60% de aumento de Probabilidad de crítico; +20% de Multiplicador de crítico; Consumo de maná ×1.20
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (29):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### RAM ECC Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Corrección de errores de grado servidor: muchísimo más crítico.

- **Efectos:** 96% de aumento de Probabilidad de crítico; +32% de Multiplicador de crítico; Consumo de maná ×1.35
- **Etiquetas:** nunca con: movimiento, potenciador, degenerativo
- **Funciona con (29):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Explotador de Vulnerabilidades

*DDR3* · grado normal · cae desde el nivel 8

Si el enemigo ya tiene un estado (quemado, helado, envenenado...), le haces mucho más daño.

- **Efectos:** 30% más de Daño contra enemigos con estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Firmware Autónomo

*DDR5* · grado normal · cae desde el nivel 1

Tus torretas, drones, esbirros y robots dejan de esperar órdenes: atacan mucho más a menudo.

- **Efectos:** 25% más de Velocidad de autómatas; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: autómata, tótem, esbirro
- **Funciona con (14):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Golem de Hardware Reciclado, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Firmware Resiliente

*DDR3* · grado normal · cae desde el nivel 5

Más vida y reducción de daño para tus invocaciones persistentes.

- **Efectos:** 60% de aumento de Vida de esbirros; Tus invocaciones reciben un 15 % menos de daño; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: persistente; nunca con: aura
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Robot Centinela, Watchdog

### Fragmentación de Disco Menor

*DDR3* · grado menor · cae desde el nivel 1

Rompe en sectores: hace sangrar. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de hacer sangrar; 2% más de Daño físico; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Fragmentación de Disco

*DDR3* · grado normal · cae desde el nivel 8

Rompes a los enemigos en sectores dispersos. Sangran, y el doble si intentan huir.

- **Efectos:** +30% de Probabilidad de hacer sangrar; 5% más de Daño físico; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Fragmentación de Disco Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Rompe en sectores: hace sangrar. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de hacer sangrar; 7% más de Daño físico; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Algoritmo de Fuerza Bruta

*DDR3* · grado normal · cae desde el nivel 1

O(n!) de complejidad, O(1) de sutileza. Mucho más daño físico.

- **Efectos:** 35% más de Daño físico; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: físico; nunca con: movimiento, potenciador
- **Funciona con (13):** Barrido, Bot de Pruebas, Bucle Infinito, Daemon en Segundo Plano, Despliegue Continuo, Fuzzing, Golem de Hardware Reciclado, Paquete Rastreador, Proceso Hijo, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Watchdog

### Gestor de Estados Global

*DDR5* · grado normal · cae desde el nivel 13

Un store centralizado para tus estados alterados: duran más y hacen más daño. No los aplica: los mejora.

- **Efectos:** 30% más de Daño y efecto de estados alterados; 30% de aumento de Duración de estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Gestor de Memoria Eficiente

*DDR5* · grado normal · cae desde el nivel 8

Libera lo que nadie usa: tus invocaciones y auras persistentes reservan bastante menos maná.

- **Efectos:** 30% de aumento de Eficiencia de reserva de maná; Consumo de maná ×1.10
- **Etiquetas:** con alguna de: persistente
- **Funciona con (17):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Robot Centinela, Watchdog

### Guiado por Láser

*DDR5* · grado normal · cae desde el nivel 6

Los proyectiles se vuelven teledirigidos: giran hacia el enemigo más cercano. Un poco más lentos, eso sí.

- **Efectos:** 10% de reducción de Velocidad de proyectiles; Los proyectiles son teledirigidos: persiguen al enemigo más cercano; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: proyectil; nunca con: teledirigido; no en: lluvia de impactos
- **Funciona con (7):** Bot Rastreador de Bugs, Corrupción de Datos, Drones de Vigilancia, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes

### Guiado por Láser de Precisión

*DDR5* · grado mayor · cae desde el nivel 24

Teledirigido y además más rápido: +15 % de velocidad de proyectiles.

- **Efectos:** 15% de aumento de Velocidad de proyectiles; Los proyectiles son teledirigidos: persiguen al enemigo más cercano; Consumo de maná ×1.30
- **Etiquetas:** con alguna de: proyectil; nunca con: teledirigido; no en: lluvia de impactos
- **Funciona con (7):** Bot Rastreador de Bugs, Corrupción de Datos, Drones de Vigilancia, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes

### Inyección de Malware Menor

*DDR4* · grado menor · cae desde el nivel 1

Instala un regalito: envenena. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de envenenar; 7% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Inyección de Malware

*DDR4* · grado normal · cae desde el nivel 8

Cada golpe instala un pequeño regalo. El veneno se acumula hasta 10 veces.

- **Efectos:** +30% de Probabilidad de envenenar; 15% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Inyección de Malware Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Instala un regalito: envenena. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de envenenar; 22% de aumento de Daño y efecto de estados alterados; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### RAM Multicanal Menor

*DDR4* · grado menor · cae desde el nivel 1

Un canal extra: +1 proyectil en abanico. Cada uno pega un 40 % menos en una placa de nivel 1 (1 punto menos por nivel).

- **Efectos:** +1 proyectiles adicionales, en abanico (también los de drones e invocaciones); 40 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 20 %); Consumo de maná ×1.15
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### RAM Multicanal

*DDR4* · grado normal · cae desde el nivel 8

Más canales: +2 proyectiles en abanico. El ancho de banda no es infinito: cada uno pega un 45 % menos (1 punto menos por nivel de la placa).

- **Efectos:** +2 proyectiles adicionales, en abanico (también los de drones e invocaciones); 45 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 22 %); Consumo de maná ×1.30
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### RAM Multicanal Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Cuatro canales: +3 proyectiles en abanico; cada uno pega un 50 % menos (1 punto menos por nivel de la placa).

- **Efectos:** +3 proyectiles adicionales, en abanico (también los de drones e invocaciones); 50 % menos de daño en una placa de nivel 1 (1 punto menos por nivel, hasta 25 %); Consumo de maná ×1.50
- **Etiquetas:** con alguna de: proyectil
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Cascada de Estilos, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### RAM con Overclock Suave

*DDR4* · grado menor · cae desde el nivel 1

Un pequeño empujón: 10 % más de velocidad de ataque y de lanzamiento.

- **Efectos:** 10% más de Velocidad de ataque; 10% más de Velocidad de lanzamiento; Consumo de maná ×1.15
- **Etiquetas:** nunca con: aura
- **Funciona con (38):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Hiperthreading, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Torreta de Integración Continua, Watchdog

### RAM con Overclock

*DDR4* · grado normal · cae desde el nivel 1

Más rápido. Más caliente. Más caro. Lo de siempre.

- **Efectos:** 20% más de Velocidad de ataque; 20% más de Velocidad de lanzamiento; Consumo de maná ×1.30
- **Etiquetas:** nunca con: aura
- **Funciona con (38):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Hiperthreading, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Torreta de Integración Continua, Watchdog

### RAM con Overclock Extremo

*DDR4* · grado mayor · cae desde el nivel 26

Voltaje al límite: 32 % más de velocidad de ataque y de lanzamiento.

- **Efectos:** 32% más de Velocidad de ataque; 32% más de Velocidad de lanzamiento; Consumo de maná ×1.50
- **Etiquetas:** nunca con: aura
- **Funciona con (38):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Firewall Personal, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Hiperthreading, Mina Rodante, Modo Seguro, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Teletransporte TCP, Torreta de Integración Continua, Watchdog

### Pasta Térmica Menor

*DDR3* · grado menor · cae desde el nivel 1

Cada golpe tiene probabilidad de prender fuego. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de quemar; 5% más de Daño de fuego; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Pasta Térmica Caducada

*DDR3* · grado normal · cae desde el nivel 8

Ya no disipa nada: todo lo que tocas sale ardiendo. Probabilidad de quemar y algo más de daño de fuego.

- **Efectos:** +30% de Probabilidad de quemar; 10% más de Daño de fuego; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Pasta Térmica Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Cada golpe tiene probabilidad de prender fuego. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de quemar; 15% más de Daño de fuego; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Pipeline Menor

*DDR3* · grado menor · cae desde el nivel 4

Repite la habilidad una vez con más penalización (en invocaciones, atacan el doble de rápido).

- **Efectos:** 40% menos de Daño; La habilidad se repite 1 vez más; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (34):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Ejecución en Pipeline

*DDR3* · grado normal · cae desde el nivel 1

Lanza la habilidad dos veces seguidas. En invocaciones, drones y esbirros, atacan el doble de rápido. La segunda la ejecuta el practicante.

- **Efectos:** 30% menos de Daño; La habilidad se repite 1 vez más; Consumo de maná ×1.50
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (34):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Pipeline Superescalar

*DDR3* · grado mayor · cae desde el nivel 30

Repite la habilidad dos veces más con la mitad de daño (en invocaciones, atacan el triple de rápido).

- **Efectos:** 50% menos de Daño; La habilidad se repite 2 vez más; Consumo de maná ×1.80
- **Etiquetas:** nunca con: movimiento, potenciador, aura
- **Funciona con (34):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Propagación de Excepciones Menor

*DDR5* · grado menor · cae desde el nivel 1

Una excepción a medio capturar: salta una sola vez a otro enemigo, con bastante menos fuerza.

- **Efectos:** +1 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 30 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.15
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Propagación de Excepciones

*DDR5* · grado normal · cae desde el nivel 13

Nadie captura la excepción: las cadenas saltan 2 veces más y los proyectiles rebotan hacia otro enemigo. Cada salto pega menos, pero mejora con el nivel de la placa.

- **Efectos:** +2 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 25 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.30
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Propagación de Excepciones Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Un stack trace sin fin: 3 saltos y casi toda la fuerza en cada uno. Mejora con el nivel de la placa.

- **Efectos:** +3 encadenamientos (los proyectiles rebotan a otro enemigo); Cada encadenamiento pega un 20 % menos (mejora 1 % por nivel de la placa); Consumo de maná ×1.45
- **Etiquetas:** con alguna de: cadena, proyectil; no en: lluvia de impactos
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Protocolo Enjambre

*DDR4* · grado normal · cae desde el nivel 1

Escalado horizontal: +1 esbirro, dron, torreta o invocación a la vez. Cada uno pega algo menos.

- **Efectos:** +1 de Esbirros adicionales; +1 de Trampas, minas y torretas adicionales a la vez; 15% menos de Daño; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: autómata, tótem, esbirro
- **Funciona con (14):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Drones de Vigilancia, Golem de Hardware Reciclado, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Puntero Salvaje Menor

*DDR4* · grado menor · cae desde el nivel 1

Los proyectiles atraviesan a 1 enemigo más. Un solo array mal indexado.

- **Efectos:** 5% más de Daño; Los proyectiles atraviesan 1 enemigos más; Consumo de maná ×1.10
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Puntero Salvaje

*DDR4* · grado normal · cae desde el nivel 8

Los proyectiles atraviesan enemigos. Nadie comprobó los límites del array.

- **Efectos:** 10% más de Daño; Los proyectiles atraviesan 2 enemigos más; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Puntero Salvaje Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Los proyectiles atraviesan a 4 enemigos más. Segfault garantizado en producción.

- **Efectos:** 15% más de Daño; Los proyectiles atraviesan 4 enemigos más; Consumo de maná ×1.35
- **Etiquetas:** con alguna de: proyectil; no en: lluvia de impactos
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Corrupción de Datos, Dron Escolta, Drones de Vigilancia, Paquete Rastreador, Ping Letal, Robot Centinela, Rollback, Ráfaga de Paquetes, Torreta de Integración Continua

### Redundancia de Invocaciones

*DDR4* · grado normal · cae desde el nivel 13

Una instancia más de cada invocación persistente. Todas pegan un poco menos.

- **Efectos:** +1 de Esbirros adicionales; 10% menos de Daño de esbirros; Consumo de maná ×1.40
- **Etiquetas:** con alguna de: persistente; nunca con: aura
- **Funciona con (11):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Robot Centinela, Watchdog

### Refrigeración Líquida Menor

*DDR4* · grado menor · cae desde el nivel 1

Gotea refrigerante: hiela. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de helar; +4% de Probabilidad de congelar; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Refrigeración Líquida con Fugas

*DDR4* · grado normal · cae desde el nivel 8

Gotea refrigerante sobre los enemigos: los hiela y, a veces, los congela del todo.

- **Efectos:** +30% de Probabilidad de helar; +10% de Probabilidad de congelar; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Refrigeración Líquida Mayor

*DDR4* · grado mayor · cae desde el nivel 26

Gotea refrigerante: hiela. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de helar; +16% de Probabilidad de congelar; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Sensor de Precisión

*DDR4* · grado normal · cae desde el nivel 5

Calibra a tus autómatas: más probabilidad de crítico y de multiplicador.

- **Efectos:** 60% de aumento de Probabilidad de crítico; +25% de Multiplicador de crítico; Consumo de maná ×1.20
- **Etiquetas:** con alguna de: autómata, tótem, esbirro; nunca con: degenerativo
- **Funciona con (12):** Agente IA, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Escolta, Drones de Vigilancia, Golem de Hardware Reciclado, Mina Rodante, Proceso Hijo, Robot Centinela, Torreta de Integración Continua, Watchdog

### Servidor Torreta

*DDR3* · grado normal · cae desde el nivel 1

Despliega una torreta que usa la habilidad sola contra el enemigo más cercano durante 8 segundos.

- **Efectos:** 25% menos de Daño; La usa una torreta durante 8 s contra el enemigo más cercano; Consumo de maná ×1.50
- **Etiquetas:** nunca con: movimiento, trampa, mina, tótem, esbirro, potenciador, aura, persistente, autómata
- **Funciona con (19):** Barrido, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Deadlock, Despliegue Continuo, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Paquete Rastreador, Ping Letal, Ransomware, Rayo de Producción, Reinicio Forzado, Rollback, Ráfaga de Paquetes, Stack Overflow

### Fuente Sobrealimentada

*DDR3* · grado normal · cae desde el nivel 10

Reservar más maná = más potencia: la invocación o el aura reserva un 50 % más, pero pega, aguanta y potencia mucho más.

- **Efectos:** 30% más de Daño de esbirros; 30% de aumento de Vida de esbirros; 35% de aumento de Efecto de auras; Reserva un 50 % más de maná; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: persistente
- **Funciona con (17):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Robot Centinela, Watchdog

### Fuente Sobrealimentada de Servidor

*DDR3* · grado mayor · cae desde el nivel 28

Reserva el doble de maná a cambio de un salto de potencia enorme.

- **Efectos:** 55% más de Daño de esbirros; 55% de aumento de Vida de esbirros; 60% de aumento de Efecto de auras; Reserva un 100 % más de maná; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: persistente
- **Funciona con (17):** Agente IA, Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling, Bot Rastreador de Bugs, Bot de Pruebas, Daemon en Segundo Plano, Dron Cortafuegos, Dron Escolta, Dron de Mantenimiento, Golem de Hardware Reciclado, Mina Rodante, Robot Centinela, Watchdog

### Sobretensión Menor

*DDR5* · grado menor · cae desde el nivel 1

Picos de voltaje: electrocuta. Versión de primer despliegue: poca probabilidad.

- **Efectos:** +15% de Probabilidad de electrocutar; 7% de aumento de Daño de rayo; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Módulo de Sobretensión

*DDR5* · grado normal · cae desde el nivel 8

Picos de voltaje en cada golpe. Los enemigos electrocutados reciben más daño de todo.

- **Efectos:** +30% de Probabilidad de electrocutar; 15% de aumento de Daño de rayo; Consumo de maná ×1.25
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Sobretensión Mayor

*DDR5* · grado mayor · cae desde el nivel 26

Picos de voltaje: electrocuta. Versión de servidor de producción: mucha probabilidad.

- **Efectos:** +45% de Probabilidad de electrocutar; 22% de aumento de Daño de rayo; Consumo de maná ×1.40
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica Menor

*DDR3* · grado menor · cae desde el nivel 1

Un mordisco de vida del disco ajeno.

- **Efectos:** +2% de Robo de vida; Consumo de maná ×1.10
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica

*DDR3* · grado normal · cae desde el nivel 8

Toma prestada vida del disco duro ajeno. Sin devolverla, claro.

- **Efectos:** +3% de Robo de vida; Consumo de maná ×1.20
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Memoria Swap Vampírica Mayor

*DDR3* · grado mayor · cae desde el nivel 26

Se alimenta del disco entero: mucho robo de vida.

- **Efectos:** +6% de Robo de vida; Consumo de maná ×1.30
- **Etiquetas:** nunca con: movimiento, potenciador
- **Funciona con (32):** Agente IA, Barrido, Bomba Lógica, Bot Rastreador de Bugs, Bot de Pruebas, Bucle Infinito, Cascada de Estilos, Corrupción de Datos, Daemon en Segundo Plano, Deadlock, Despliegue Continuo, Dron Escolta, Drones de Vigilancia, Excepción en Cadena, Flamewar, Fork Bomb, Fuga de Memoria, Fuzzing, Golem de Hardware Reciclado, Mina Rodante, Paquete Rastreador, Ping Letal, Proceso Hijo, Ransomware, Rayo de Producción, Reinicio Forzado, Robot Centinela, Rollback, Ráfaga de Paquetes, Stack Overflow, Torreta de Integración Continua, Watchdog

### Torre de Señal

*DDR5* · grado normal · cae desde el nivel 12

El aura ya no te sigue: se queda clavada donde la activas, con un 30 % más de efecto y un 25 % más de alcance. Ideal para defender una posición.

- **Efectos:** 30% de aumento de Efecto de auras; El aura se queda en el suelo donde la activas (no te sigue); +25 % de alcance del aura; Consumo de maná ×1.00
- **Etiquetas:** con alguna de: aura
- **Funciona con (6):** Aura de Blindaje Redundante, Aura de Exposición de Vulnerabilidades, Aura de Mando, Aura de Mantenimiento Continuo, Aura de Overclock, Aura de Throttling

