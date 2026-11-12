# Repetidor de Path Overflow (prototipo, T262)

Un programa pequeño por el que pasan las partidas por internet: el anfitrión y cada invitado se conectan a él por
WebSocket y él reenvía lo que dice cada uno a los demás de su sala. No entiende ni guarda nada de la partida.
Por qué hace falta y qué alternativas hay: `docs/internet_propuesta.md`.

Sin dependencias: solo Node 18 o más.

```
node tools/repetidor/servidor.js        # escucha en el puerto 47240 (o en PORT)
```

Probarlo en este equipo con dos juegos de verdad:

```
powershell -ExecutionPolicy Bypass -File tools/prueba_dos_juegos.ps1 -Segundos 34 -Repetidor
```

Para jugar a mano por él (dos ventanas en el mismo PC): arranca el repetidor y abre cada juego con
`-- red=anfitrion repetidor=ws://127.0.0.1:47240 sala=PRUEBA` y `-- red=invitado repetidor=ws://127.0.0.1:47240 sala=PRUEBA`.

El protocolo está explicado al principio de `servidor.js`. Límites: 4 jugadores por sala, 200 salas, 512 KB por
mensaje, 256 KB/s por conexión, y fuera quien lleve un minuto sin decir nada.

## Dónde está

Desde el 11-11-2026: `https://path-overflow-repetidor.onrender.com` (Render, plan gratis, región Ohio). En el juego:
`wss://path-overflow-repetidor.onrender.com`. Se duerme tras 15 minutos sin tráfico y tarda cerca de un minuto en
despertar. Probarlo: `tools/prueba_dos_juegos.ps1 -Segundos 34 -RepetidorUrl wss://path-overflow-repetidor.onrender.com`.

## Desplegarlo en Render

La rama `repetidor` del repositorio contiene **solo esta carpeta** (se saca con
`git subtree split --prefix=tools/repetidor -b repetidor`), para que Render no vuelva a desplegar —y cortar las
partidas en curso— cada vez que cambia el juego.

En render.com: **New → Web Service** → el repositorio → rama `repetidor` → Runtime **Node** → Build Command
`npm install` → Start Command `npm start` → Instance Type **Free**. No hace falta ninguna variable: Render pone `PORT`.
La dirección que da (`https://….onrender.com`) se usa en el juego como `wss://….onrender.com`. Abrirla en el
navegador enseña «Repetidor de Path Overflow: 0 sala(s).» (y lo despierta si dormía).

## Solo con cuenta (T263)

Con dos variables de entorno puestas en el servicio, el repetidor solo deja entrar a quien tenga la sesión de su
cuenta iniciada (lo comprueba con el servicio de cuentas; no guarda ni registra nada):

| Variable | Valor |
|---|---|
| `NUBE_URL` | La dirección del proyecto de cuentas (la misma de `nube.cfg`) |
| `NUBE_CLAVE_PUBLICA` | Su clave **pública** (`sb_publishable_…`, la misma de `nube.cfg`). Nunca la secreta: con una secreta no arranca |

En Render: el servicio → **Environment** → añadir las dos → guardar (vuelve a desplegar solo). La página del repetidor
pasa a decir «Solo con cuenta.». Sin ellas entra cualquiera que conozca un código: sirve para probar en un equipo.

## Que no se duerma

El plan gratis de Render se duerme tras 15 minutos sin tráfico. Desde el 11-11-2026 un monitor de UptimeRobot (en la
cuenta del usuario) pide `https://path-overflow-repetidor.onrender.com/` cada 5 minutos. Ojo: así el servicio gasta
unas 730 de las 750 horas gratis al mes del espacio de trabajo de Render, que se comparten entre todos sus servicios
gratis: si hay otro despierto a la vez, se acaban antes de fin de mes.

## Probarlo

`node tools/repetidor/prueba.js` (Node 22 o más) lo arranca con un servicio de cuentas de mentira y comprueba quién
entra, quién no y a quién llega cada mensaje. Va dentro de `tools/run_checks.ps1` como «repetidor».
