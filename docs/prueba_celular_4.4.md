# Prueba en el celular · versión 4.4 (T231)

APK: `build/PathOverflow.apk` (v4.4.0, misma clave de siempre: se instala encima sin perder partidas).
Llega por el aviso de actualización una vez subida la release `v4.4.0` a WalBernal/PathOverflow
(`tools/publicar_version.ps1 -Repo WalBernal/PathOverflow -SoloSubir -Notas "..."`). Windows: `build/PathOverflow-Setup.exe`.
Abajo a la derecha del título debe decir **v4.4**.

Fases 45 y 46 del Roadmap 2: autoequipar y la pantalla nueva de habilidades y RAM (propuesta A con el
veredicto de B, `docs/habilidades_ui_propuesta.md`). Lo que más importa probar aquí es **el toque real
con el dedo**: en el PC se comprobó llamando a las mismas funciones, pero no con una pantalla táctil.

## Autoequipar (T227)
- [ ] Con una ranura vacía, al recoger equipo que puedes usar te lo pones solo: suena y sale «Equipado: …» en el registro.
- [ ] Nunca cambia lo que ya llevas. Si no cumples los requisitos, se queda en la bolsa.
- [ ] Dos anillos van a las dos ranuras; un tercero, a la bolsa.
- [ ] En Pausa → Combate, «Autoequipar en ranuras vacías: no» lo apaga.

## Pantalla de habilidades (T229, tecla K o su botón)
- [ ] Se ve entera: nada se sale por los bordes, ni con la interfaz grande.
- [ ] Tocar una placa de la izquierda la elige y el centro muestra sus ranuras en grande.
- [ ] Cada ranura dice qué RAM tiene y qué hace.
- [ ] Tocar una ranura con RAM la marca y activa «Quitar RAM».
- [ ] «◀ Tecla» y «Tecla ▶» cambian la placa de botón; «Quitar placa» la devuelve a la bolsa.
- [ ] «Variante», «Comparar» y «Construcciones» funcionan con toques.
- [ ] Pestaña «Encajan aquí»: cada RAM dice «ranura N libre · +X % DPS» o «cambiar la ranura N»; «Instalar» o «Cambiar» la coloca.
- [ ] Pestaña «Todas las RAM»: al tocar una, se ve en qué placas funciona, con «Instalar» en las que valen. Las placas de la izquierda muestran ✓ o ✕.
- [ ] Pestaña «Placas»: «Poner en tecla N» instala la placa en la elegida.
- [ ] Todos los botones se aciertan bien con el dedo.

## En PC (T230)
- [ ] Al pasar el ratón por una RAM, la ranura donde iría se marca y aparece el cambio de DPS; al quitar el ratón, vuelve a la normal.
- [ ] Arrastrar y soltar sigue funcionando, y soltar en la columna derecha devuelve a la bolsa.
- [ ] Clic derecho sobre una RAM o placa instalada la quita.
- [ ] Con el menú abierto: 1-6 eligen placa (y no beben refrescos), Supr quita la RAM de la ranura elegida y Tab cambia de pestaña.
