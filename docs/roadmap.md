# Roadmap — Path Overflow: El Último Commit

Estado a octubre de 2026: Actos I a III jugables, 7 clases con kit y rasgo propios, 14 ascendencias (2 por clase, cada una con juego distinto), un árbol con las temáticas de estados y aliados repartidas por sectores (3-5 clusters cada una, sin nodos encimados), estados alterados sobre enemigos **y sobre el jugador**, interacciones entre estados, 9 invocaciones persistentes y 4 auras, RAM por grados (menor / normal / mayor), enemigos con resistencias, inmunidades y 16 afijos, jefes con fases (que además cambian de resistencias) y barra de jefe. Lo que **falta**, por prioridad. **S** = pequeño (≈ 1 sesión), **M** = mediano, **L** = grande.

> Descartado por ahora: escala de las invocaciones y escala de los obstáculos.

## 1. Pulido inmediato

| Qué | Tamaño | Notas |
|---|---|---|
| Equilibrar con partidas reales | M | Probabilidades de estado, reservas de maná, vida y daño de las 9 invocaciones, penalización del encadenamiento por grado, daño de espinas y de afijos (explosivo, reflejo, tóxico), duración de congelación/electrocución sobre el jugador y de las fases de jefe. Jugar cada clase hasta el nivel 30 con las dos ascendencias. |
| Sprites propios para las invocaciones nuevas | M | Hoy son figuras dibujadas con formas. |
| Sonidos propios por estado y habilidad | S | Hoy los estados reutilizan sonidos existentes (fuego, rayo, frío, poción, golpe) con otro tono; faltan los de veneno, sangrado, congelación, aura on/off, curación del dron y explosión de la mina. |
| Rendimiento con 150+ enemigos con estados, afijos y aliados | M | Medir; si hace falta, limitar los efectos a lo que se ve en cámara. |

## 2. Combate y habilidades

- **Auras con alcance** (S): hoy afectan a todos tus aliados; que dependan de la distancia al jugador y que haya auras que debiliten a los enemigos.
- **Más invocaciones y auras** (M): una de cada por clase que aún no la tiene, mejoras por hito y modo «reservar más maná = más potencia».
- **RAM de grados para más familias** (S): ya tienen grados el encadenamiento, la perforación, el multicanal, los estados, el crítico, el daño elemental y el robo de vida; faltan área, velocidad y pipeline. Módulos de efecto sobre aliados (estados en drones).
- **Desbloqueo de habilidades por nivel** (M): que cada clase tenga progresión de kit propia, no solo botín.
- **Más interacciones entre estados** (S): hoy hay rotura, sobrecarga, infección y choque térmico; falta una para helado + rayo y que las ascendencias las potencien.
- **Resistencia a estados en objetos** (S): el árbol ya tiene nodos de «resistencia a estados»; faltan afijos en el equipo.

## 3. Enemigos y jefes

- **Fases en subjefes y élites únicos** (M): los gemelos de la Carrera Crítica y los raros (Puntero Salvaje, Centinela del Cargador) también con barra y fases.
- **Afijos de combinación** (S): afijos que se prohíben entre sí y mezclas con nombre propio (p. ej. Ignífugo + Explosivo).
- **Sprites de enemigos nuevos para el acto III y animaciones de ataque** (L).
- **Comportamiento anti-invocaciones** (S): enemigos que priorizan al golem, explosivos contra torretas.
- **Música y cámara por fase** (S): hoy hay sacudida de cámara y aviso; falta cambiar la música al entrar en una fase.

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

- Pantalla K con filtros por tipo de habilidad, y vista previa de DPS con y sin RAM (M).
- Árbol pasivo: que el buscador reconozca también las temáticas nuevas por su nombre de estado (S).
- Configuración: tamaño de interfaz, modo daltónico (los estados se distinguen en parte por color), volumen por canal (M).
- Mando / gamepad (L).

## 6. Arte y audio

- Sustituir los sprites provisionales dibujados con formas por arte final: personajes, NPC, invocaciones, iconos de habilidad y de estado (L).
- Retratos de NPC más expresivos y personajes del acto III (M).
- Música por zona y por jefe (M).
- Partículas de estados más ricas (escarcha que cubre el sprite, chispas persistentes) (M).
- Voz del narrador y de los NPC: estabilizar el proceso aparte y añadir ajustes por personaje (S).

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

**Árbol reorganizado (versión 7)**: 7 temáticas nuevas con 3-5 clusters cada una y colocadas del lado de las clases que las usan (automatización y Legión de aliados/auras junto al DevOps y la puerta hacia el centro del Full Stack; hemorragia con guerrero y duelista; criogenia y toxinas con exploradora y hacker; ignición y sobrecarga con hechicero y DevOps), nodos de resistencia a estados, sin nodos encimados ni aristas sobre nodos (lo comprueban el generador y las pruebas) · choque térmico · RAM de grados de crítico, elemental y robo de vida · minimapa con aliados y marca del jefe · 
Kits de 3 habilidades y rasgo por clase · estados alterados con iconos · RAM de asistencia y por grados (encadenamiento, perforación, multicanal, estados) con escala por nivel · invocaciones persistentes (9) y auras (4) con reserva de maná visible · resistencias, inmunidades y 16 afijos de enemigos · fases en los tres jefes con resistencias que cambian, barra de jefe segmentada y sacudida de cámara · marco del objetivo con resistencias, afijos, estados y ayuda al pasar el mouse · tutorial con enemigos lejos · escena final del acto I con el dinosaurio visible en el túnel · sprites +18 % · M. Páez con sonrisa fija · **estados sobre el jugador** (electrocutado, helado, congelado) y barra de buffs y debuffs con ayuda · **interacciones entre estados** (rotura, sobrecarga, infección) · sonidos de estados · hoja de personaje con estados, auras y aliados · **14 ascendencias** (2 por clase) con efectos nuevos (espinas, vida al matar, perforación, estados, auras) y aviso a los personajes que tenían una eliminada.
