# Roadmap — Path Overflow: El Último Commit

Estado a octubre de 2026: Actos I a III jugables, 7 clases con kit y rasgo propios, 14 ascendencias (2 por clase, cada una con juego distinto), un árbol con las temáticas de estados y aliados repartidas por sectores (3-5 clusters cada una, sin nodos encimados), estados alterados sobre enemigos **y sobre el jugador**, interacciones entre estados, 11 invocaciones persistentes y 6 auras (con alcance; 2 debilitan a los enemigos), desbloqueo de habilidades por nivel, RAM por grados (menor / normal / mayor), enemigos con resistencias, inmunidades y 16 afijos, jefes con fases (que además cambian de resistencias) y barra de jefe. Lo que **falta**, por prioridad. **S** = pequeño (≈ 1 sesión), **M** = mediano, **L** = grande.

> Descartado por ahora: escala de las invocaciones y escala de los obstáculos.

## 1. Pulido inmediato

| Qué | Tamaño | Notas |
|---|---|---|
| Equilibrar con partidas reales | M | La tabla de `tools/balance_report.gd` ya está dentro de rango (DPS medio ~210 a nivel 30, placa 20; las invocaciones por encima porque reservan maná). Falta jugarlo: probabilidades de estado, reservas, daño de espinas y afijos, duración de congelación/electrocución sobre el jugador, fases de jefe, el Multicanal nuevo y las auras con alcance. Jugar cada clase hasta el nivel 30 con las dos ascendencias. |
| Rendimiento con 300 enemigos en pantalla | M | Con 150 en cámara ya va a 60 FPS; con 300 a ~32 FPS (dibujo de enemigos ~8 ms, simulación ~3.4 ms). Siguiente paso: barras de vida e iconos en un MultiMesh o en un único `_draw` por lotes. Medir con `capture_screens.tscn -- rendimiento`. |
| Arte final de las invocaciones | L | Ya tienen figura propia cada una (`UnitArt`), pero dibujada con formas: necesita un artista. |

## 2. Combate y habilidades

- **Más invocaciones y auras** (M): ya hay invocación y aura en la progresión de todas las clases; faltan mejoras por hito propias de cada invocación y el modo «reservar más maná = más potencia».
- **Equilibrar el Multicanal y la Pipeline Superescalar** (S): la Pipeline mayor sigue siendo la mejor RAM de daño para casi todo (×1.5); probar en partida.
- **Auras con alcance, siguiente paso** (S): hoy todas las auras se centran en el jugador; auras que se puedan dejar en el suelo o sobre una invocación.
- **Desbloqueos por nivel** (S): hoy son 4 por clase (niveles 5, 10, 16 y 24) y entregan la placa en la bolsa; falta un aviso visual mayor y elegir entre dos opciones en algún nivel.
## 3. Enemigos y jefes

- **Fases en subjefes y élites únicos** (M): los gemelos de la Carrera Crítica y los raros (Puntero Salvaje, Centinela del Cargador) también con barra y fases.
- **Afijos de combinación** (S): afijos que se prohíben entre sí y mezclas con nombre propio (p. ej. Ignífugo + Explosivo).
- **Sprites de enemigos nuevos para el acto III y animaciones de ataque** (L).
- **Comportamiento anti-invocaciones** (S): enemigos que priorizan al golem, explosivos contra torretas.
- **Música por fase** (S): cada fase solo sube el tempo un 4 %; falta una capa nueva de batería o una pista propia por fase.

## 4. Contenido

| Qué | Tamaño |
|---|---|
| **Acto IV** (zonas, NPCs, misiones, jefe con fases, escenas) | L |
| Misiones secundarias con recompensas de RAM de grado alto, placas de invocación y auras | M |
| Más objetos únicos y conjuntos con efectos de estados, auras, espinas y autómatas | M |
| Afijos de objetos de estados (`+x % a quemar`) y de autómatas | M |
| Mapas post-historia / modo de oleadas infinito reutilizando las pruebas de estrés | L |
| Dificultades (normal, pesadilla, infierno) con más afijos y resistencias | M |

## 5. Interfaz

- Pantalla K: filtros por tipo de habilidad y comparar el DPS con y sin una RAM antes de instalarla (S; el resumen por placa y las ranuras compatibles ya están).
- El DPS estimado de las habilidades con varios proyectiles cuenta uno solo y el de esbirros temporales (Proceso Hijo) sale inflado con Pipeline y Enjambre: revisar la fórmula (S).
- Tamaño de interfaz también en los menús fuera de partida (título, personajes, creador) y tamaños mayores que 120 %: hoy la barra inferior del HUD no cabe más allá (S).
- Mando / gamepad (L).

## 6. Arte y audio

- Sustituir los sprites provisionales dibujados con formas por arte final: personajes, NPC, invocaciones, iconos de habilidad y de estado (L). Necesita un artista: el código solo puede mejorar las figuras dibujadas.
- Retratos de NPC más expresivos y personajes del acto III (M).
- Sustituir la música generada por composiciones propias (S por pista): las 12 pistas actuales son de programador. Ya se puede escribir la melodía a mano en `music.json` (`melody`), como en `camp3`.
- Peso del audio: los .wav suman unos 58 MB en el repositorio (música 34, ambientes 24); valorar OGG o Git LFS (S).
- Música propia para los subjefes y las pruebas de estrés (S).

## 7. Sistemas y calidad

- **Guardado**: copia de seguridad automática y varios espacios por perfil; guardar qué auras estaban activas (M).
- **Tests**: pruebas de integración que carguen cada zona y simulen 30 s de combate con cada clase y que fallen si aparece un `SCRIPT ERROR` (M).
- **Rendimiento**: portar `EnemyManager` a C# o GDExtension si el presupuesto de 4 ms se rompe con estados y aliados (L).
- **Cliente/servidor** (L, largo plazo): aislar `SkillController` y `EnemyManager` de `Node2D` para un modo cooperativo.
- **Exportación**: plantillas para Linux y macOS, e instalador de Windows (S).

## 8. Próximos pasos sugeridos

1. Jugar el build nuevo con las siete clases (las dos ascendencias de cada una) y equilibrar (sección 1).
2. Pasivas de aliados en el árbol y auras con alcance.
3. Sprites y sonidos propios de invocaciones y estados.
4. Acto IV con jefe de fases y afijos propios.
5. Arte final de personajes y enemigos.

## Hecho (no repetir)

**Pulido y combate (octubre 2026)**: sonidos propios de veneno, sangrado, congelación, rotura, superconductor, aura on/off, curación del dron y explosión de la mina · **Superconductor** (rayo a un helado: arcos a 2 enemigos con el 40 % del golpe) y «efecto de las interacciones» en tres ascendencias (Analista de Big Data, Ingeniera de Depuración, Analista de Malware) · afijo de resistencia a estados en armaduras y joyas · RAM por grados de área, velocidad, Pipeline y Guiado · **auras con alcance** (las invocaciones fuera del radio pelean sin los bonos) y dos auras que debilitan (Throttling: enemigos más lentos; Exposición: reciben más daño) · invocaciones nuevas Watchdog y Bot Rastreador de Bugs · **desbloqueo de habilidades por nivel** (4 por clase, con invocación y aura) · figura propia para las 11 invocaciones (UnitArt) · rendimiento: recorte a cámara, efectos simplificados con más de 60 enemigos en pantalla y minimapa a 30 Hz (150 enemigos: de 27 a 60 FPS) · equilibrio: DPS sostenido real de esbirros, drones y degenerativos, Pipeline Superescalar −50 %, ataques +25 % de crecimiento por nivel, Bucle Infinito, Reinicio Forzado, Deadlock y Drones ajustados · listado completo en docs/habilidades_y_ram.md.

**RAM y habilidades (octubre 2026)**: proyectiles en abanico («|», «V», «\|/»...) y solo teledirigidos con la etiqueta `homing` (Paquete Rastreador, Torreta CI, Dron Escolta, Agente IA) o la RAM nueva **Guiado por Láser** · el Multicanal añade proyectiles a drones e invocaciones que disparan y quita un 40/45/50 % de daño en nivel 1 (1 punto menos por nivel, hasta la mitad) · las RAM de daño ya afectan a las invocaciones · Pipeline en invocaciones = atacan el doble de rápido (antes apagaba las auras o reinvocaba) · las RAM de área escalan las habilidades de las invocaciones · reglas de compatibilidad (`requires_all_tags`, `excludes_kinds`, sin RAM de daño en habilidades sin daño) y auditoría (`tools/audit_rams.gd` y una prueba): ninguna RAM compatible queda sin efecto · insignias de cada familia de RAM en el icono de la habilidad (barra, placas y módulos de la bolsa) · menú K con resumen por placa (DPS, maná, proyectiles, RAM activas), ranuras compatibles en verde y en rojo las que no harían nada, bolsa agrupada por generación y botón «Ordenar».

**Minimapa y prólogo (octubre 2026)**: objetos de misión como insignia verde con «!» que pulsa · NPCs con silueta propia y «!»/«?» si ofrecen o entregan misión · enemigos por rareza (gris normal, azul claro mágico, amarillo raro, naranja único) con borde oscuro · jefe con su propio sprite en una insignia con ondas rojas (pegada al borde si queda fuera) · iconos de los objetos pendientes y recogidos en el registro de misiones · el «No» de la contratación encoge su tamaño y su letra hasta un mínimo legible (antes se escalaba hasta 8×2 px sin texto) y, ya pequeño, lo señala un recuadro punteado que parpadea.

**Interfaz y audio (octubre 2026)**: objetos de misión con dibujo propio (`QuestItemArt`: cinta LTO, papel continuo con sello, descriptor en blanco, bloques de caché en hielo, funda de Kindle con nota y etiqueta, Kindle con raya y batería al 1 %, concha, bolillo tibio con vapor y cuernito escarchado) · **bucles de música arreglados**: el final del bucle se calculaba con `data.size() / 2`, que con los .wav importados en QOA cortaba cada pista a una quinta parte; ahora cada pista tiene intro que suena una vez, cuerpo de 32 compases con partes A/B y redoble antes de volver, y el bucle empieza tras la intro (`data/music_loops.json`) · ambientes de 24 s con bucle real (antes 6 s con hueco al relanzarse) · campamento del acto III con balada original de melodía escrita · menú de pausa en dos columnas con volumen por canal (música, efectos, ambiente, voces), **tamaño de interfaz** (85-120 %, solo la capa de UI; el mundo no cambia), **modo daltónico** de los estados (paleta Okabe-Ito) · el buscador del árbol encuentra las temáticas por estado («veneno», «sangrado», «congelar», «torreta», «aura»...) · los efectos ya no leen settings.cfg en cada sonido.

**Música de 12 pistas por zona y jefe** (campamento del acto III en estilo balada melancólica) con fundido cruzado y tempo por fase · Eugenio distraído, con datos de artistas · **partículas de estados**: escarcha que cubre el sprite, copos y cristales, arcos y chispas persistentes (enemigos y jugador) · voces con género y volumen por NPC y ajustes de velocidad y volumen en pausa · **Árbol reorganizado (versión 7)**: 7 temáticas nuevas con 3-5 clusters cada una y colocadas del lado de las clases que las usan (automatización y Legión de aliados/auras junto al DevOps y la puerta hacia el centro del Full Stack; hemorragia con guerrero y duelista; criogenia y toxinas con exploradora y hacker; ignición y sobrecarga con hechicero y DevOps), nodos de resistencia a estados, sin nodos encimados ni aristas sobre nodos (lo comprueban el generador y las pruebas) · choque térmico · RAM de grados de crítico, elemental y robo de vida · minimapa con aliados y marca del jefe · 
Kits de 3 habilidades y rasgo por clase · estados alterados con iconos · RAM de asistencia y por grados (encadenamiento, perforación, multicanal, estados) con escala por nivel · invocaciones persistentes (9) y auras (4) con reserva de maná visible · resistencias, inmunidades y 16 afijos de enemigos · fases en los tres jefes con resistencias que cambian, barra de jefe segmentada y sacudida de cámara · marco del objetivo con resistencias, afijos, estados y ayuda al pasar el mouse · tutorial con enemigos lejos · escena final del acto I con el dinosaurio visible en el túnel · sprites +18 % · M. Páez con sonrisa fija · **estados sobre el jugador** (electrocutado, helado, congelado) y barra de buffs y debuffs con ayuda · **interacciones entre estados** (rotura, sobrecarga, infección) · sonidos de estados · hoja de personaje con estados, auras y aliados · **14 ascendencias** (2 por clase) con efectos nuevos (espinas, vida al matar, perforación, estados, auras) y aviso a los personajes que tenían una eliminada.
