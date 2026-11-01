# Prueba en el celular · versión 3.5 (T170)

APK: `build/PathOverflow.apk` (v3.5.0, código 19, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v3.5.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v3.5**.

Es la interfaz que elegiste: **B · Panel de monitoreo/datos** (`docs/estilo_visual.md`).
Capturas para comparar: `docs/capturas/interfaz/` (166_*, 167_hud_*, 168_*, 169_*).

## Ventanas (T166)
- [ ] Inventario, habilidades, hoja de personaje, tienda, alijo, mapa, pausa: ¿se entiende cada una con las
      tarjetas turquesa (sin latón ni remaches)?
- [ ] Descripción de un objeto: la franja de arriba con el color de su rareza. ¿Se distingue bien la rareza?
- [ ] ¿Algo quedó con el estilo viejo (dorado, marrón, remaches)? Anota dónde.

## HUD en pelea (T167)
- [ ] Vida («integridad») y maná («memoria") como **medidores circulares**: ¿se leen de un vistazo peleando?
- [ ] Habilidades, pociones y esquiva como teclas: siguen hundiéndose al tocarlas, con el barrido de
      enfriamiento y el azul de «sin maná».
- [ ] Minimapa como radar (anillos y barrido): ¿distrae o ayuda?
- [ ] Misiones como lista TODO («[ ] ★ ...», «[x]» al entregar) y el registro como consola
      («00:01 [WARN] ...»).

## Pantallas (T168, T169)
- [ ] La carga como registro de arranque («[ OK ] compilando zona… OK», de 0 a 100 %).
- [ ] La muerte como volcado de error («FATAL ProcesoTerminado» y la pila); el botón para reaparecer.
- [ ] Título, lista de personajes y creador con la paleta nueva.
- [ ] La fuente de consola (Fira Code) en el registro, las cifras y la carga: ¿se lee bien al tamaño de
      interfaz que usas (p. ej. 140 %)? Los sucesos largos ahora ocupan dos líneas.

## Pendiente de la 3.4
- [ ] ¿Qué tal los personajes, las armas y los NPC de la 3.4 (lista `docs/prueba_celular_3.4.md`)?
- [ ] ¿Las manadas de enemigos un 30 % más juntas en el celular (T153)?

## Siguiente etapa: que todo hable el mismo idioma (Fase 38, versión 3.6)
- T171 enemigos a la resolución de los personajes, T172 efectos con temática de datos, T173 versión 3.6.0.
