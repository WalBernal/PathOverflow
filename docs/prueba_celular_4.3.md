# Prueba en el celular · versión 4.3 (T226)

APK: `build/PathOverflow.apk` (v4.3.0, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v4.3.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir -Notas "..."`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v4.3**. El APK pasa de 46 a 74 MB por las voces.

Fase 44 del Roadmap 2 (voz y narrativa) y los arreglos pedidos tras la 4.2. Reparto y reglas de las
voces en `docs/voces.md`.

## Voces de los actos (T220-T222)
- [ ] En Pausa → Diálogos, «Voces de los diálogos: sí»; su tooltip dice que son generadas con IA. Con «no», callan todas.
- [ ] Al hablar con B.O.B. en el Sandbox suena su voz de robotito (sin acento inglés) y el retrato mueve la boca.
- [ ] Rafa, Aída, M. Páez, Mario, Clara, Eugenio, Tomás, el DBA, Berta, Iris, el Recolector, el Sindicato y Nacho suenan con su voz en todos sus diálogos, igual de una línea a otra.
- [ ] Al volver a hablar con alguien, el saludo y el menú también tienen voz.
- [ ] Las escenas de los actos (llegadas, jefes, «Sistema») tienen voz; el texto avanza a su ritmo y espera a que termine.
- [ ] Saltar o cerrar una escena o un diálogo corta la voz al instante.
- [ ] Ninguna línea suena cortada, repetida o con murmullo al final. Si alguna sí, apuntar cuál.

## Frases de combate (T223)
- [ ] Al subir de nivel, morir, beber un refresco, quedarse con poca vida o sin maná, el personaje dice una frase con la voz elegida en el creador (masculina o femenina).
- [ ] Nunca la misma frase dos veces seguidas y no se amontonan (beber varios refrescos seguidos no repite frase en cada uno).

## Jefes que hablan (T224)
- [ ] El Arquitecto, init, fw_update.exe y admin dicen una frase al despertar, al entrar en cada fase y con poca vida, con su voz y un subtítulo bajo su barra que se apaga solo.
- [ ] El subtítulo no tapa el combate ni el juego se detiene.

## Diario del egresado (T225)
- [ ] En la hoja de personaje (C) hay pestañas «Ficha» y «Diario».
- [ ] El diario dice dónde estás y tu objetivo, y resume lo que pasó en cada acto (con partidas viejas, los actos ya completados se ven enteros).

## Arreglos pedidos
- [ ] B.O.B. en el Sandbox: cabeza gris, pelo azul rapado y traje azul, como en su miniatura.
- [ ] Creador de personaje en tableta: se ven las flechas «>», el retrato y «Comenzar».
- [ ] Prólogo: al abrirse el vórtice el jugador se agacha, gatea hacia la salida y lo absorbe igual.
