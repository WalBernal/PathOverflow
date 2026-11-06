# Prueba en el celular · versión 4.0 (T210)

APK: `build/PathOverflow.apk` (v4.0.0, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v4.0.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v4.0**.

Fase 42 del Roadmap 2: seis habilidades nuevas elegidas por el usuario (T207-T209), una por clase, que se
desbloquean a nivel 12 (y caen como placa base). Ni la 3.8 ni la 3.9 se subieron: esta versión las incluye, así
que siguen valiendo `docs/prueba_celular_3.8.md` y `docs/prueba_celular_3.9.md`. Diseño y cifras en
`docs/habilidades_y_ram.md`, «Habilidades nuevas (T207)». Capturas: `docs/capturas/habilidades/208_nuevas.png` y
`209_nuevas.png`.

## Ticket Escalado (Técnico de Soporte)
- [ ] Golpear al mismo enemigo sube su prioridad: «P3», «P2» y en «P1» estalla con lo acumulado (la tarjeta se parte).
- [ ] ¿Se entiende la marca encima del enemigo? ¿Pega lo que debe al estallar? Variante: Prioridad crítica.

## Breakpoint (Tester QA)
- [ ] En el círculo, los enemigos casi se paran y sus proyectiles también (pruébalo con enemigos que disparan).
- [ ] «⏸ PAUSED» y, al acabar, «▶ continue». Variante: Breakpoint condicional (+15 % de daño recibido).

## Lazy Loading (Desarrolladora Frontend)
- [ ] Las flechas se quedan en el aire con «loading…» y salen solas cuando se acerca un enemigo («200 OK»).
- [ ] ¿Se ven bien en el celular? ¿Es fácil colocarlas con el dedo? Variante: Precarga (cinco flechas).

## Inyección de Prompt (Ingeniera de Prompts)
- [ ] El enemigo normal o especial más cercano al cursor se pasa a tu lado (morado, «{prompt}» y su contador).
- [ ] Al acabar estalla y da su experiencia y su botín. Con élites o únicos, «403: no aplica» (salvo élites con Jailbreak).

## Descenso de Gradiente (Científico de Datos)
- [ ] El orbe gira hacia el grupo más denso, los atraviesa y crece. ¿Se nota que «busca» grupos?

## Despliegue Canario (Ingeniero DevOps)
- [ ] El canario sigue al personaje con su barra de rollout; si aguanta 5 s salen tres bots («✓ rollout»).
- [ ] Si lo tumban antes, «rollback». ¿Los enemigos lo atacan lo justo? Variante: Rollout progresivo.

## Equilibrio
- [ ] ¿Alguna de las seis pega demasiado o se queda corta frente a las de su clase?
