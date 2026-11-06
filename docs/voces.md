# Voces de los diálogos: ficha de casting

Cómo debe sonar cada personaje cuando sus diálogos se generen como audio (en vez de la voz de
Windows). La descripción es del usuario; la «indicación» es la versión lista para pegar en una
herramienta que diseña voces a partir de texto (p. ej. Voice Design de ElevenLabs), donde el
inglés funciona mejor. Todas con acento latinoamericano neutro: ni castellano ni regional marcado (Aída y M. Páez se quedan como están, ya aprobadas).

Pruebas descartadas: Kokoro (local) — no convenció (2026-11-06).

| Personaje | id en `npcs.json` | Descripción |
|---|---|---|
| El recién egresado (jugador) | `player` | Voz joven. Hace falta en versión de hombre y de mujer (según el personaje creado). |
| Rafa, el SysAdmin | `root`, `rafa_terminal`, `rafa_bios` | Adulto de 45 años que todavía se expresa como joven. |
| Mario, el Practicante | `kevin`, `mario_bios` | Alumno joven que se quiere meter en todo, ruidoso, de voz aguda. |
| Aída, la Senior | `ada` | Adulta de 50 años, entusiasta, voz seria con un toque sutil de sensualidad. |
| M. Páez, el Inge | `m_paez`, `paez_bios` | Adulto de 40 años, súper entusiasta y alegre. |
| Narrador | (pasos `style: system`) | Narrador clásico de juego (estilo Pokémon): tono neutral, claro y que no aburra. |

## Indicaciones para diseñar cada voz

- **Recién egresado (hombre)**: «Very young man, about 20, just graduated: youthful boyish voice, light and bright, slightly higher pitch, a bit nervous but hopeful, natural and casual. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Recién egresada (mujer)**: «Very young woman, about 20, just graduated: youthful girlish voice, light and bright, a bit nervous but hopeful, natural and casual. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Rafa**: «Man in his mid forties who still talks like a young guy: relaxed and casual, a tired and sarcastic sysadmin, slightly raspy mid-low voice, dry humor, drawn-out pauses. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Mario**: «Teenage boy, about 17, a first-year student who wants to join everything: loud, very high-pitched bright teenage voice that still sounds like a kid, fast and super enthusiastic. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Aída**: «Mexican woman around 50, senior engineer. Serious, confident, warm low voice with a subtle, elegant sensual touch; enthusiastic underneath, never exaggerated.»
- **M. Páez**: «Mexican man around 40, super enthusiastic and cheerful engineering teacher, bright upbeat mid-range voice, always smiling when he talks.»
- **Narrador**: «Neutral Latin American Spanish narrator for a video game, like a classic RPG narrator: clear, warm, engaging and well-paced, never monotone, not theatrical.»

## Pendientes de descripción

Nacho, B.O.B. (bot), Iris, Tomás, el Fantasma del DBA, Clara, El Recolector, el Sindicato de
Huérfanos, Eugenio y Berta (la pila CR2032). Mientras tanto conservan la voz de Windows con su
tono de `npcs.json`.

## Reglas

- Solo voces con licencia de uso comercial (o grabaciones propias con permiso); nada de imitar
  a personas reales.
- En los créditos: «Voces generadas con IA» y la herramienta usada.
- Si falta el audio de una línea, el juego usa la voz de Windows o los pitidos, como hoy.

## Historial

- 2026-11-06 · Qwen3-TTS VoiceDesign (local): Aída y M. Páez aprobadas a la primera. Rafa sonaba a español de España: se pide acento del norte de México (Sinaloa) y se prueba una variante B. Egresado, egresada y Mario, más jóvenes.
- 2026-11-06 · El usuario prefiere acento neutro, no mexicano marcado ni castellano: Rafa, egresado, egresada y Mario pasan a «Neutral Latin American Spanish accent». Rafa regenerado entero; del egresado solo las líneas 02 y 04.

## Cómo se generan y llegan al juego

Todo en local (Qwen3-TTS, Apache 2.0; ~8 GB en `tools/voces/modelo/`, fuera de git):

1. `tools/voces/voces.json`: el reparto. Cada voz es una toma aprobada en `tools/voces/referencias/`
   (se clona con el modelo Base y suena igual en todas sus líneas) o una descripción.
2. `exportar_escenas.py prologo_ tools/voces/lineas_prologo.json`: saca las líneas de
   `data/cutscenes.json` con el id del juego (`<escena>_<paso>`, y `_m`/`_f` las del jugador).
3. `generar_qwen.py tools/voces/lineas_prologo.json tools/voces/salida_prologo`: genera los .wav.
4. `al_juego.py tools/voces/salida_prologo`: los deja en `audio/voces/*.ogg` al mismo volumen.
5. Godot `--import`. En el juego, `VoiceLines` los reproduce en las escenas; si una línea no
   tiene audio, se usa la voz del sistema como antes. La voz del jugador se elige en el creador
   («Voz: Masculina/Femenina»; los guardados viejos, masculina).

Hecho: el prólogo (26 audios, 3 min 17 s, 1,4 MB).