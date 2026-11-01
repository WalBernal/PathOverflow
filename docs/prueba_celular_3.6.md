# Prueba en el celular · versión 3.6 (T173)

APK: `build/PathOverflow.apk` (v3.6.0, código 21, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.6.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.6**.

Cierra la etapa de tamaño y estética (Roadmap 8.0). Capturas para comparar: `docs/capturas/estetica/`
(`171_antes_despues.png`, `171_partida_*`, `172_efectos.png`, `173_antes_despues.png`).

## Enemigos (T171)
- [ ] Los enemigos se ven al nivel del héroe: curvas finas, luz arriba y sombra abajo, contorno grueso. ¿Alguno se ve raro?
- [ ] El contorno de rareza (azul mágico, amarillo élite, naranja único) se sigue viendo igual de grueso.
- [ ] Los jefes en su presentación y los enemigos del título se ven bien (sin cuadros cortados ni de otro enemigo).
- [ ] Con muchos enemigos (acto III, 150+), ¿va igual de fluido que la 3.5?

## Efectos (T172)
- [ ] Al morir, un anillo de nodos que se apagan y el glifo de su familia (digital «{ }», metal «#», cristal «<>», carne «;»). ¿Se entiende o estorba?
- [ ] Golpes fuertes y críticos: un corchete que salta. El botín raro o mejor: bits que suben entre corchetes.
- [ ] Los colores por tipo de daño se distinguen igual; con el modo daltónico puesto, también.
- [ ] Con «Efectos de pantalla» apagado no aparece nada de lo anterior.

## Pendiente de antes
- [ ] Lo que quedara de `docs/prueba_celular_3.5.md` (interfaz) y de la 3.4 (personajes, armas, NPC).
- [ ] ¿Las manadas de enemigos un 30 % más juntas en el celular (T153)?
