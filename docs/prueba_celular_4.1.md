# Prueba en el celular · versión 4.1 (T215)

APK: `build/PathOverflow.apk` (v4.1.0, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v4.1.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v4.1**.

Cierra el Roadmap 2. Lo nuevo es T214, el resumen al salir de una zona. Ni la 3.8, ni la 3.9, ni la 4.0 se
subieron: esta versión las incluye, así que siguen valiendo `docs/prueba_celular_3.8.md`, `3.9.md` y `4.0.md`.
Capturas: `docs/capturas/interfaz/214_informe_pc.png` y `214_informe_tactil.png`.

## Informe al salir de una zona
- [ ] Juega al menos 20 s en una zona de combate y viaja (waypoint o salida): al quitarse la tarjeta de carga aparece arriba al centro «$ cat informe.log».
- [ ] Primera línea «$ build <zona> — OK en X min Y s» en verde; si moriste, «FAILED (n muertes)» en rojo.
- [ ] «procesos terminados» cuenta los enemigos que mataste en esa visita.
- [ ] «experiencia: +N», o «subes de nivel a → b» si subiste.
- [ ] «DPS medio en combate» tiene sentido para tu personaje.
- [ ] Los artefactos raros o mejores que recogiste salen con el color de su rareza (como mucho tres, los mejores primero); si no hubo, «artefactos: nada digno de un commit».
- [ ] Si moriste, «la muerte más tonta» nombra al enemigo más débil que te mató.
- [ ] Las líneas largas se parten y no se salen del recuadro.
- [ ] Se va solo a los ~8 s, o antes con un toque encima, y el toque no mueve al personaje.
- [ ] No sale al salir de un campamento, ni si estuviste menos de 20 s en la zona, ni al volver al menú.
