# Prueba en el celular · versión 3.7 (T190)

APK: `build/PathOverflow.apk` (v3.7.0, código 22, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.7.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.7**.

Primera fase del Roadmap 2 (`docs/roadmap2.md`, T183-T189): la primera impresión. Casi todo es movimiento y sonido,
así que las capturas fijas cambian poco: `docs/capturas/interfaz/190_antes_despues.png` y `docs/capturas/prologo/`.

## Transiciones (T183)
- [ ] Al abrir el juego, el título sale de negro (no aparece de golpe) y el aviso «toca la pantalla» llega al final.
- [ ] Tocar para continuar suena, y el barrido de cuadros se ve entero también al entrar al mundo (antes se saltaba).
- [ ] Creador → prólogo, creador → lista y prólogo → mundo pasan con el barrido; el mundo abre con su tarjeta de carga.
- [ ] La tarjeta de carga ya no empieza adelantada: el registro de arranque va de 0 a 100 %.

## Lista de personajes (T184-T186)
- [ ] Fondo con paquetes de datos que recorren la rejilla. ¿Se nota sin distraer? Con «reducir movimiento», quieto.
- [ ] Logo, lista, detalle y botones entran uno tras otro.
- [ ] Todos los botones (y las tarjetas) rebotan y hacen clic al pulsar.
- [ ] Al cambiar de personaje: destello en el pedestal, el color pasa al de la clase y el texto se escribe solo.
- [ ] La figura gira sola por los cuatro lados (se estrecha a mitad del giro) y se pone de frente para posar.
- [ ] Va fluido aunque tengas muchos personajes (solo respira el retrato elegido).

## Creador (T185)
- [ ] Arrastrar con el dedo sobre la figura la gira; los botones < > giran con la misma transición.
- [ ] Cambiar peinado, colores, etc. da un pequeño «pop»; el pedestal toma el color del atuendo.
- [ ] Las muestras de color rebotan y suenan; la elegida tiene un marco que late.

## Prólogo (T187-T189)
- [ ] El texto de la intro se desvanece al empezar a caminar; el tecleo suena parejo.
- [ ] Quieto, el personaje respira. Rafa teclea, te mira cuando te acercas y se levanta con una animación.
- [ ] Calle: autos que pasan, peatones, gaviotas, brillos en el mar y hojas. Pasillo: polvo en la luz y alguien
      que cruza al fondo por una puerta que se abre y se cierra. Oficina: código en los monitores viejos y café humeando.
- [ ] Ventana de contratación: entra con zoom y sonido, el «No» se desliza, el error aparece con un pop y cada puesto
      muestra su figura con el atuendo de la clase. ¿Cabe bien en la pantalla del celular?
- [ ] Música: un tema en la calle y el pasillo, otro en la oficina; se apaga con la consola roja y suena un golpe
      musical en «EL ÚLTIMO COMMIT». ¿No tapa los diálogos?

## Pendiente de antes
- [ ] Lo que quedara de `docs/prueba_celular_3.6.md` (enemigos y efectos).
