# Prueba en el celular · versión 3.8 (T199)

APK: `build/PathOverflow.apk` (v3.8.0, código 24, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.8.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.8**.

Fase 40 del Roadmap 2 (cada habilidad con su firma, T191-T198 y T216-T218). Como las fases 41 y 43 se hicieron en
paralelo, esta versión trae también lo ya hecho de ellas: invocaciones (T200-T202) e interfaz (T211-T213).
Capturas: `docs/capturas/habilidades/199_muestrario_*.png` (las 62), `docs/capturas/mecanicas/193-197_*`,
`docs/capturas/personajes/198_poses.png`, `docs/capturas/invocaciones/`, `docs/capturas/interfaz/213_*`.

## Efectos propios (T193-T195)
- [ ] Cuerpo a cuerpo y movimiento: llaves del Barrido, pipeline del Despliegue, pantalla azul de Reinicio Forzado,
      «-f» de Force Push, basura de Fuzzing, SYN/ACK del Teletransporte, candados del Túnel SSH, diff de Git Revert.
- [ ] Hechizos: sonar de Ping Letal, copias de Fork Bomb, bloques de Stack Overflow, lenguas de Flamewar, «500» del
      Rayo, candados de Deadlock, stack trace de la Excepción, charco de la Fuga de Memoria, volcado de Core Dump.
- [ ] Buffs y auras: muro «DENY», hexágono de Modo Seguro, doble de Hiperthreading, sirena, reloj y rollback;
      cada aura con su color y motivo. ¿Se distinguen las seis de un vistazo? ¿Y con el modo daltónico?
- [ ] Con 150+ enemigos en pantalla, ¿sigue fluido? (los detalles se quitan solos en la versión ligera)

## Sonido (T192, T196, T216)
- [ ] Cada habilidad suena distinta (su tipo + su firma). Las invocaciones y las auras ya no suenan a disparo.
- [ ] Core Dump: un golpe por carga; Bucle Infinito sube de tono por vuelta; Pipe y Tormenta suenan mientras se
      canalizan; Bot de Pruebas: PASS o FAIL al caer. ¿Algo cansa o tapa los demás sonidos?

## Variantes, RAM y ascendencias (T197, T218)
- [ ] Una variante se ve con otro matiz (cálido si pega más, frío si reparte) y suena más grave o más aguda.
- [ ] Multicanal abre un abanico, Pipeline marca «×2»/«×3», los proyectiles que perforan, encadenan o van guiados
      llevan su señal. Unicast dispara un solo proyectil a cualquier nivel.
- [ ] Los efectos de ascendencia tienen su etiqueta: SIGKILL, stash pop, PAGE, blue→green, ESD, 403…

## Personaje e invocaciones (T198, T200-T202)
- [ ] El personaje grita, salta, invoca, enciende auras y canaliza con su propia animación.
- [ ] Las invocaciones miran hacia donde van, solo mueven las piernas al moverse, se compilan de bits al aparecer,
      embisten o retroceden al atacar, saltan en arco y se desarman al caer.

## Interfaz (T211-T213)
- [ ] El tooltip de una placa muestra la habilidad en bucle (bolsa, barra, alijo, tienda). ¿Va fluido en el celular?
- [ ] Muñeco de prácticas en cada campamento: DPS, golpes y reparto por tipo de los últimos 10 s.
- [ ] Basura y bloqueados se ven en el tooltip y en el título de la bolsa; la ayuda dice el gesto del dedo.

## Pendiente de antes
- [ ] Lo que quedara de `docs/prueba_celular_3.7.md` (pantallas iniciales y prólogo).
