# Roadmap — Path Overflow: El Último Commit

Estado a octubre de 2026: Actos I a III jugables, 7 clases con kit y rasgo propios, 14 ascendencias (2 por clase, cada una con juego distinto), un árbol con las temáticas de estados y aliados repartidas por sectores (3-5 clusters cada una, sin nodos encimados), estados alterados sobre enemigos **y sobre el jugador**, interacciones entre estados, 11 invocaciones persistentes y 6 auras (con alcance; 2 debilitan a los enemigos), desbloqueo de habilidades por nivel (con una elección entre dos), hitos propios por invocación, auras ancladas, mando básico, RAM por grados (menor / normal / mayor), enemigos con resistencias, inmunidades, 16 afijos y 9 combinaciones con nombre, cazadores de invocaciones, jefes y subjefes con fases (que además cambian de resistencias), barra de jefe y música de fase. Lo que **falta**, por prioridad. **S** = pequeño (≈ 1 sesión), **M** = mediano, **L** = grande.

> Descartado por ahora: escala de las invocaciones y de los obstáculos; cazadores contra minas y trampas (las minas están enterradas y no se ven).

## 1. Pulido inmediato

| Qué | Tamaño | Notas |
|---|---|---|
| Equilibrar con partidas reales | M | La tabla de `tools/balance_report.gd` ya está dentro de rango (DPS medio ~210 a nivel 30, placa 20; las invocaciones por encima porque reservan maná). Falta jugarlo: probabilidades de estado, reservas, daño de espinas y afijos, duración de congelación/electrocución sobre el jugador, fases de jefe, el Multicanal nuevo y las auras con alcance. Jugar cada clase hasta el nivel 30 con las dos ascendencias. |
| Rendimiento con 300 enemigos en pantalla | M | Con 150 en cámara ya va a 60 FPS; con 300 a ~32 FPS (dibujo de enemigos ~8 ms, simulación ~3.4 ms). Siguiente paso: barras de vida e iconos en un MultiMesh o en un único `_draw` por lotes. Medir con `capture_screens.tscn -- rendimiento`. |
| Arte final de las invocaciones | L | Ya tienen figura propia cada una (`UnitArt`), pero dibujada con formas: necesita un artista. |

## 2. Combate y habilidades

- **Equilibrar el Multicanal y la Pipeline Superescalar** (S): la Pipeline mayor sigue siendo la mejor RAM de daño para casi todo (×1.5); probar en partida. Igual con la Sobrealimentación (+50 % de reserva) y el Enlace de Aura.

## 3. Enemigos y jefes

- **Sprites de enemigos nuevos para el acto III** (L): necesita arte; las animaciones de ataque (carga, embestida estirada y retroceso al disparar) ya están para todos.

## 4. Contenido

| Qué | Tamaño |
|---|---|
| **Acto IV** (zonas, NPCs, misiones, jefe con fases, escenas) | L |
| Misiones secundarias con recompensas de RAM de grado alto, placas de invocación y auras | M |
| Más objetos únicos y conjuntos con efectos de estados, auras, espinas y autómatas | M |
| Mapas post-historia / modo de oleadas infinito reutilizando las pruebas de estrés | L |
| Dificultades (normal, pesadilla, infierno) con más afijos y resistencias | M |

## 5. Interfaz

- **Mando, siguiente paso** (M): moverse, apuntar, habilidades, pociones, abrir menús, recoger objetos y hablar con NPC (A contextual) ya funcionan; falta navegar dentro de los menús (inventario, árbol, K, diálogos) sin ratón.
- Rebindear teclas y botones desde la pausa (M).
- **Prólogo en pixel art 2.0, siguiente paso** (M): la calle ya sigue el modelo 3D y la foto real (UAdeO, calle lateral que baja, torre a la derecha); faltan el pasillo y la oficina con el mismo nivel de detalle (luz, tramado, sombras).
- **Menús con desplazamiento** (S): el inventario ya se desplaza si no cabe con la interfaz grande; falta lo mismo en la hoja de personaje (C) y el menú K, que por ahora limitan la escala a lo que quepa (160 % solo en 1080p o más).

## 6. Arte y audio

- Sustituir los sprites provisionales dibujados con formas por arte final: personajes, NPC, invocaciones, iconos de habilidad y de estado (L). Necesita un artista: el código solo puede mejorar las figuras dibujadas.
- Retratos de NPC más expresivos y personajes del acto III (M).
- Sustituir la música generada por composiciones propias (S por pista): las 15 pistas actuales son de programador. Ya se puede escribir la melodía a mano en `music.json` (`melody`) o en un archivo aparte nota por nota (`melody_file`, como `camp3`).
- **Campamento III**: suena tu melodía de prueba (`data/music/camp3_eptns.json`). Si es la transcripción de una canción con derechos, cambiarla por una propia antes de publicar.
- Peso del audio: los .wav suman unos 60 MB en el repositorio; valorar OGG o Git LFS (S).
- Música propia para las pruebas de estrés (S).

## 7. Sistemas y calidad

- **Guardado**: copia de seguridad automática y varios espacios por perfil (M).
- **Tests**: pruebas de integración que carguen cada zona y simulen 30 s de combate con cada clase y que fallen si aparece un `SCRIPT ERROR` (M). Hoy hay pruebas de datos y lógica (`tests/test_core.gd`), la auditoría de RAM, la tabla de equilibrio y las capturas (`tools/capture_screens.tscn -- objetos | minimapa | habilidades | rendimiento`).
- **Rendimiento**: portar `EnemyManager` a C# o GDExtension si el presupuesto de 4 ms se rompe con estados y aliados (L).
- **Cliente/servidor** (L, largo plazo): aislar `SkillController` y `EnemyManager` de `Node2D` para un modo cooperativo.
- **Exportación**: plantillas para Linux y macOS, e instalador de Windows (S). El ejecutable de Windows se genera con `--export-release Windows build/PathOverflow.exe`.

## 8. Próximos pasos sugeridos

1. Jugar el build nuevo (`build/PathOverflow.exe`) con las siete clases y equilibrar (secciones 1 y 2): Multicanal, Pipeline, auras con alcance, combinaciones de afijos y fases de subjefes.
2. Rendimiento con 300 enemigos en pantalla (sección 1).
3. Acto IV con jefe de fases y afijos propios.
4. Más únicos y conjuntos que usen los afijos nuevos (estados, autómatas, interacciones).
5. Arte final de personajes, enemigos e invocaciones.

## Hecho (no repetir)

**Calle real, canción de prueba y más roadmap (23 octubre 2026, noche 2)**: la **torre de departamentos pasa a la derecha** de la UAdeO, separada por una **calle lateral que baja** en perspectiva (muro de block de la escuela con ventanitas, autos estacionados, casas y poste al fondo); la torre con balcones corridos, seto y palmeras · **música del campamento III desde tu JSON** (`melody_file`, notas con velocidad; acordes de Sol mayor, 24 compases, bucle sin intro) · **Enlace de Aura con varias auras**: cada una va a una invocación distinta (tanques primero) · **las auras activas se guardan** con el personaje y se encienden solas al cargar · interfaz hasta **160 %** (se limita a lo que quepa en pantallas bajas), también en los textos del prólogo y la contratación · **el inventario se desplaza** si no cabe (antes la bolsa se salía por abajo desde 110 % en 900 px).

**Prólogo 2.0 y más roadmap (23 octubre 2026, noche)**: **fachada de la UAdeO según el modelo 3D** (anexo blanco, atrio de vidrio con parasoles, plantas y escalinata de madera, pilastras de piedra, segundo piso, bloque terracota con letrero de doble línea, ventanas, escudo dorado, rampa y entrada blanca), nubes y sombras; la entrada pasa a la puerta blanca · **arreglado de raíz el personaje que se salía de la pantalla**: CharacterAppearance.draw dejaba la transformación del lienzo en cero y el jugador se dibujaba sin la cámara · **absorción por el servidor**: tras «Profe Rafa, ¿va a querer churr...?», vórtice en el rack, el carrito, Mario, Aida y Rafa vuelan al servidor por turnos con gritos («¡MIS CHURROS!», «¡AAAAH!», «¡MI MONOLITOOO!»), succión y ráfagas digitales; luego el jugador · sonidos nuevos: gritos (voz grave y aguda), succión, ráfaga digital · **«!» en los botones K y P** al desbloquear una habilidad o subir de nivel, con sonido · **Enlace de Aura** (el aura sigue a tu invocación más resistente) · animaciones por tipo: los que disparan retroceden y los que embisten se estiran · **mando: A contextual** (recoge objetos, habla con NPC, usa waypoint y alijo; si no hay nada cerca, habilidad 1).

**Prólogo pulido (23 octubre 2026)**: el personaje ya no sale de la pantalla en la calle (se camina hasta poco más allá de la entrada de la UAdeO) · en el pasillo ya no va el triple de rápido de lado · **flecha dorada** sobre el siguiente objetivo (escaleras, puerta de Informática, Rafa, rack negro) · **click en un objetivo lejano: camina y entra solo** · el punto para entrar al departamento está en la puerta de Informática y el de hablar con Rafa, junto a su escritorio · la introducción se escribe más rápido y no se salta sin leerla · en todas las escenas, un doble click ya no se salta líneas · el «No» de la contratación ya no tiene el borde azul (solo el punteado de Windows 98).

**Combate, enemigos e interfaz (23 octubre 2026, tarde)**: **hitos propios de cada invocación** (proyectiles para el robot, el dron escolta y el bot rastreador; potencia de su habilidad para los drones de curación y barrera, el bot de pruebas, la mina y el agente; vida y defensa para el golem) · **Fuente Sobrealimentada** (normal y de servidor): reservar más maná = más potencia · **Torre de Señal**: auras ancladas en el suelo con más efecto y alcance · **elección entre dos habilidades** al nivel 16 de cada clase · 3 combinaciones más de afijos (Hotfix en Llamas, Legacy Indestructible, Rayo Fantasma) y combinaciones destacadas con ★ y borde dorado en el marco del objetivo · **las torretas tienen vida** y los cazadores van a por ellas · pista de **fase de subjefe** (Condición de carrera) · **animaciones de ataque** de los enemigos (se encogen al cargar y embisten al golpear) · interfaz hasta **140 %** (los botones C/I/K/P suben sobre la barra si no caben) y tamaño elegible desde el menú de personajes · **mando básico** (moverse, apuntar, 6 habilidades, pociones, inventario, árbol, K, pausa) · nuevo ejecutable.

**Enemigos, contenido e interfaz (23 octubre 2026)**: **afijos de combinación** (Ignífugo + Explosivo = Termonuclear, Criogenizado + Gélido = Cero Absoluto, Veloz + Teletransportador = Fantasma en la Red, Curandero + Regenerador = Inmortal en Producción, Escudado + Reflejo = Firewall Espejo, Tóxico + Invocador = Plaga) y afijos que se excluyen (Ignífugo/Ardiente, Aislado/Electrizante, Curandero/Invocador, Veloz/Blindado) · **enemigos que cazan invocaciones** (gusanos, IRQ, gusano de firmware y los que llevan carga explosiva) · **música propia de fase** para los tres jefes (más rápida, batería nueva y platillos; entra con fundido al empezar la primera fase) · **fases en subjefes**: los gemelos de la Carrera Crítica, el Puntero Salvaje y el Centinela del Cargador, con barra de jefe · **afijos de objetos** de probabilidad de estados (quemar, electrocutar, helar, envenenar, sangrar), daño de estados, velocidad de autómatas, daño y vida de esbirros · **menú K**: filtro de la bolsa por tipo y comparación de DPS al seleccionar una RAM · tamaño de interfaz también en el menú de personajes y el creador · nuevo ejecutable de Windows.

**Pulido y combate (octubre 2026)**: sonidos propios de veneno, sangrado, congelación, rotura, superconductor, aura on/off, curación del dron y explosión de la mina · **Superconductor** (rayo a un helado: arcos a 2 enemigos con el 40 % del golpe) y «efecto de las interacciones» en tres ascendencias (Analista de Big Data, Ingeniera de Depuración, Analista de Malware) · afijo de resistencia a estados en armaduras y joyas · RAM por grados de área, velocidad, Pipeline y Guiado · **auras con alcance** (las invocaciones fuera del radio pelean sin los bonos) y dos auras que debilitan (Throttling: enemigos más lentos; Exposición: reciben más daño) · invocaciones nuevas Watchdog y Bot Rastreador de Bugs · **desbloqueo de habilidades por nivel** (4 por clase, con invocación y aura) · figura propia para las 11 invocaciones (UnitArt) · rendimiento: recorte a cámara, efectos simplificados con más de 60 enemigos en pantalla y minimapa a 30 Hz (150 enemigos: de 27 a 60 FPS) · equilibrio: DPS sostenido real de esbirros, drones y degenerativos, Pipeline Superescalar −50 %, ataques +25 % de crecimiento por nivel, Bucle Infinito, Reinicio Forzado, Deadlock y Drones ajustados · listado completo en docs/habilidades_y_ram.md.

**RAM y habilidades (octubre 2026)**: proyectiles en abanico («|», «V», «\|/»...) y solo teledirigidos con la etiqueta `homing` (Paquete Rastreador, Torreta CI, Dron Escolta, Agente IA) o la RAM nueva **Guiado por Láser** · el Multicanal añade proyectiles a drones e invocaciones que disparan y quita un 40/45/50 % de daño en nivel 1 (1 punto menos por nivel, hasta la mitad) · las RAM de daño ya afectan a las invocaciones · Pipeline en invocaciones = atacan el doble de rápido (antes apagaba las auras o reinvocaba) · las RAM de área escalan las habilidades de las invocaciones · reglas de compatibilidad (`requires_all_tags`, `excludes_kinds`, sin RAM de daño en habilidades sin daño) y auditoría (`tools/audit_rams.gd` y una prueba): ninguna RAM compatible queda sin efecto · insignias de cada familia de RAM en el icono de la habilidad (barra, placas y módulos de la bolsa) · menú K con resumen por placa (DPS, maná, proyectiles, RAM activas), ranuras compatibles en verde y en rojo las que no harían nada, bolsa agrupada por generación y botón «Ordenar».

**Minimapa y prólogo (octubre 2026)**: objetos de misión como insignia verde con «!» que pulsa · NPCs con silueta propia y «!»/«?» si ofrecen o entregan misión · enemigos por rareza (gris normal, azul claro mágico, amarillo raro, naranja único) con borde oscuro · jefe con su propio sprite en una insignia con ondas rojas (pegada al borde si queda fuera) · iconos de los objetos pendientes y recogidos en el registro de misiones · el «No» de la contratación encoge su tamaño y su letra hasta un mínimo legible (antes se escalaba hasta 8×2 px sin texto) y, ya pequeño, lo señala un recuadro punteado que parpadea.

**Interfaz y audio (octubre 2026)**: objetos de misión con dibujo propio (`QuestItemArt`: cinta LTO, papel continuo con sello, descriptor en blanco, bloques de caché en hielo, funda de Kindle con nota y etiqueta, Kindle con raya y batería al 1 %, concha, bolillo tibio con vapor y cuernito escarchado) · **bucles de música arreglados**: el final del bucle se calculaba con `data.size() / 2`, que con los .wav importados en QOA cortaba cada pista a una quinta parte; ahora cada pista tiene intro que suena una vez, cuerpo de 32 compases con partes A/B y redoble antes de volver, y el bucle empieza tras la intro (`data/music_loops.json`) · ambientes de 24 s con bucle real (antes 6 s con hueco al relanzarse) · campamento del acto III con balada original de melodía escrita · menú de pausa en dos columnas con volumen por canal (música, efectos, ambiente, voces), **tamaño de interfaz** (85-120 %, solo la capa de UI; el mundo no cambia), **modo daltónico** de los estados (paleta Okabe-Ito) · el buscador del árbol encuentra las temáticas por estado («veneno», «sangrado», «congelar», «torreta», «aura»...) · los efectos ya no leen settings.cfg en cada sonido.

**Música de 12 pistas por zona y jefe** (campamento del acto III en estilo balada melancólica) con fundido cruzado y tempo por fase · Eugenio distraído, con datos de artistas · **partículas de estados**: escarcha que cubre el sprite, copos y cristales, arcos y chispas persistentes (enemigos y jugador) · voces con género y volumen por NPC y ajustes de velocidad y volumen en pausa · **Árbol reorganizado (versión 7)**: 7 temáticas nuevas con 3-5 clusters cada una y colocadas del lado de las clases que las usan (automatización y Legión de aliados/auras junto al DevOps y la puerta hacia el centro del Full Stack; hemorragia con guerrero y duelista; criogenia y toxinas con exploradora y hacker; ignición y sobrecarga con hechicero y DevOps), nodos de resistencia a estados, sin nodos encimados ni aristas sobre nodos (lo comprueban el generador y las pruebas) · choque térmico · RAM de grados de crítico, elemental y robo de vida · minimapa con aliados y marca del jefe · 
Kits de 3 habilidades y rasgo por clase · estados alterados con iconos · RAM de asistencia y por grados (encadenamiento, perforación, multicanal, estados) con escala por nivel · invocaciones persistentes (9) y auras (4) con reserva de maná visible · resistencias, inmunidades y 16 afijos de enemigos · fases en los tres jefes con resistencias que cambian, barra de jefe segmentada y sacudida de cámara · marco del objetivo con resistencias, afijos, estados y ayuda al pasar el mouse · tutorial con enemigos lejos · escena final del acto I con el dinosaurio visible en el túnel · sprites +18 % · M. Páez con sonrisa fija · **estados sobre el jugador** (electrocutado, helado, congelado) y barra de buffs y debuffs con ayuda · **interacciones entre estados** (rotura, sobrecarga, infección) · sonidos de estados · hoja de personaje con estados, auras y aliados · **14 ascendencias** (2 por clase) con efectos nuevos (espinas, vida al matar, perforación, estados, auras) y aviso a los personajes que tenían una eliminada.
