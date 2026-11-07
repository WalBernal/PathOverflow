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

## Reparto de T220 (aprobado: tomas elegidas por el usuario en tools/voces/referencias/)

Dos tomas de prueba de cada una (A y B) en `tools/voces/salida_reparto/`.

- **B.O.B. (bot_onboarding)**: «Friendly upbeat onboarding robot assistant: androgynous synthetic voice with a light metallic, slightly digital timbre, cheerful and helpful like a tutorial guide, clear and quick. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Clara (clara)**: «Woman around 38, infrastructure team lead: firm, dry and practical, weary after years in the trenches, clear confident mid-range voice, a little sarcastic. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Eugenio (eugenio, eugenio_bios)**: «Man around 35, a self-proclaimed eligible bachelor: flirty, theatrical and dramatic, warm smooth voice, playful and a bit cheesy, upbeat. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Tomás (tomas)**: «Man around 32, the last QA tester: exhausted, paranoid and melancholic, low quiet voice, flat delivery with dry humor. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **El Fantasma del DBA (dba)**: «Ghost of an old database administrator, a man around 60: deep, slow, solemn and hollow voice, eerie and sepulchral, as if speaking from far away. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Berta, la pila CR2032 (berta)**: «Elderly grandmotherly woman around 75: sweet, warm and maternal, slightly frail and trembling voice, slow and nostalgic, gentle humor. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Iris (iris)**: «Young woman about 20, a lost intern: nervous, shy and confused, soft quick voice, rambling and a bit anxious. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **El Recolector (recolector)**: «The Garbage Collector: deep, cold, mechanical and menacing male voice, very slow with long pauses, emotionless, like an executioner. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Sindicato de Huérfanos (sindicato)**: «Man around 45, a combative union leader speaking for thousands of orphaned processes: rough raspy loud voice, passionate rally-speech delivery. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **Nacho (nacho)**: «Man around 30, a street-market hardware reseller: fast-talking, cheeky, friendly and pushy salesman, bright energetic voice. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **init (PID 1), jefe**: «Ancient patriarch process, an old man: deep, authoritative, calm and menacing voice, slow and imposing, like a stern father. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **admin, jefe**: «Lonely default admin account, a tired middle-aged man: flat monotone voice that slowly reveals sadness, quiet and resigned. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **El Arquitecto del Monolito, jefe**: «Old dying architect, a man around 70: deep, weary, breathless and grave voice, slow with long pauses, tragic. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **fw_update.exe, jefe**: «Robotic automated warning announcement: cold, synthetic and urgent, loud monotone like a system alarm message. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»
- **«Sistema» (avisos de las escenas)**: «Clean synthetic operating system announcer: calm neutral voice, crisp and clear like a computer notification. Neutral Latin American Spanish accent: clear and standard, not Castilian or Spain Spanish, not strongly regional.»

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

Hecho: el prólogo (26 audios, 3 min 17 s, 1,4 MB).- 2026-11-06 · B.O.B.: la primera propuesta sonaba con acento inglés; se rehízo como robotito divertido y algo chillón, y el usuario aprobó la toma D (acento neutro). Referencia: tools/voces/referencias/bob.wav.
- 2026-11-06 · T220 aprobado: Clara A, Eugenio A, Tomás B, DBA B, Berta B, Iris B, Recolector A, Sindicato B, Nacho A, init A, admin B, Arquitecto B, fw_update B, Sistema B.
