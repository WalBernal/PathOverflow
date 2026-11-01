# Prueba en el celular · versión 3.4 (T179)

APK: `build/PathOverflow.apk` (v3.4.0, código 18, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.4.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.4**.

Capturas para comparar: `docs/capturas/personajes/` (180_peinados_accesorios, 181_direcciones,
182_perfiles, 177_armas, 178_npcs).

## Logo (T174)
- [ ] ¿El ícono de la app (la pila que se desborda entre «<» y «/>») se ve bien en el escritorio del celular?

## Creador de personaje (T180)
- [ ] 16 peinados: ¿alguno se ve raro o quieres cambiar alguno?
- [ ] Lentes claros (se ven los ojos y el armazón), lentes de sol (armazón del color de acento) y audífonos.
- [ ] Debajo del personaje de oficina, «Así te verás dentro del servidor»: ¿coincide con lo que elegiste? «Girar» lo gira.

## Tu alumno en el servidor (T176, T181, T182)
- [ ] El prólogo sigue con el estilo de oficina; desde el acto I, el alumno en pixel art.
- [ ] Al caminar a la izquierda o a la derecha se ve **de perfil** (ya no camina como cangrejo), y de espaldas al subir.
- [ ] Al equiparte casco, armadura o botas, ¿cambia tu look? (Hierro/obra → paladín, cuero → ladrón,
      túnica de seda → mago, chaqueta de conferencias → invocador.)

## Armas (T177)
- [ ] Cada arma tiene su sprite: espadas, hachas, maza de depuración, martillo, **teclado mecánico y RGB**,
      dagas, cúter, navaja. ¿La maza ya no parece un bastón largo?
- [ ] ¿Se ven bien al atacar de frente, de espaldas y de lado?

## NPC (T178) — en el campamento y las demás zonas
- [ ] Con el estilo del alumno: Aida con túnica y su café, Rafa con armadura de rack tecleando en su laptop,
      Nacho con chaleco y su maleta, B.O.B. autómata con su pantalla, Iris con capucha y su mapa, Tomás con
      cota y estoque, Clara con su tablero...
- [ ] ¿Algún NPC que quieras distinto (equipo u objeto)?

## Pendiente de T153
- [ ] ¿Las manadas de enemigos un 30 % más juntas en el celular, para pelear más y pasear menos?

## Límites conocidos
- Los íconos de armas del inventario siguen siendo los de antes.
- De perfil, el sombrero del mago y el abrigo del invocador son el dibujo de frente comprimido.
- Las armaduras no tienen vista propia de espaldas.

## Siguiente etapa: interfaz de ingeniería (T165, versión 3.5)
- [ ] Cuando apruebes esta versión, preparo dos propuestas: **A · Terminal/IDE** o **B · Panel de monitoreo/datos**.
