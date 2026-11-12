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

**Todavía no** (T263): pedir sesión iniciada para entrar, la guía de despliegue paso a paso y la pantalla del juego
con el código de sala.
