# Prueba en el celular · versión 3.9 (T206)

APK: `build/PathOverflow.apk` (v3.9.0, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.9.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.9**.

Fase 41 del Roadmap 2 (invocaciones vivas, T200-T205). La 3.8 no se llegó a subir: esta versión la incluye entera,
así que vale también la lista `docs/prueba_celular_3.8.md` (efectos y sonidos de las 62 habilidades).
Capturas: `docs/capturas/invocaciones/` (estados, aparecer y morir, ataques y 204_*).

## Movimiento y estados (T200)
- [ ] Las invocaciones miran hacia donde caminan o atacan; los cañones y cabezas apuntan al objetivo.
- [ ] Solo mueven las piernas o ruedas cuando se desplazan; quietas respiran o flotan.
- [ ] Con Monolito se ven más grandes; con Microservicios o el Clúster de tres, más pequeñas.

## Aparecer, golpes y morir (T201)
- [ ] Al invocar se compilan de bits; al relanzar, la que se mueve se desvanece y reaparece.
- [ ] Al recibir un golpe retroceden un poco y parpadean (sin que una horda las arrastre).
- [ ] Al caer se desarman en piezas; también el Proceso Hijo, los drones, la torreta y el contenedor al caducar.

## Ataques (T202)
- [ ] Las de cuerpo a cuerpo embisten con su golpe propio (tridente, mordida, puñetazo, brazo de los golems).
- [ ] Las de distancia retroceden con un fogonazo; la Torreta CI gira el cañón y retrocede al disparar.
- [ ] Los saltos van en arco con el cuerpo; el Golem UTP azota con su cable.

## Que cumplan su texto (T203)
- [ ] El Golem blindado provoca el doble; el Bot Rastreador dispara dardos; Centinela y R-2PL, láseres.
- [ ] El EMP del R-2PL sale del robot y aturde a lo que tiene cerca él.

## Arte propio (T204) y acompañantes (T205)
- [ ] Proceso Hijo con patas y cabeza de terminal; Drones de Vigilancia con cámara; Torreta CI con trípode y
      placa «CI»; el contenedor Docker sube del suelo y se le abre la tapa.
- [ ] Mario, M. Páez y Eugenio caminan moviendo las piernas y miran hacia donde van (de espaldas, de perfil).
- [ ] El R-2PL va detrás del hombro contrario a donde miras, se inclina al moverse y mueve el visor.
- [ ] Con muchas invocaciones y enemigos a la vez, ¿va fluido en el celular?
