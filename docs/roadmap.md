# Roadmap — Path Overflow: El Último Commit

Estado a octubre de 2026: Actos I a III jugables (Sandbox → Silicio Profundo), 7 clases con kit propio, estados alterados, invocaciones persistentes, árbol de ~740 nodos, HUD renovado. Lo que sigue, ordenado por prioridad. **S** = pequeño (≈ 1 sesión), **M** = mediano, **L** = grande.

## 1. Pulido inmediato (antes de añadir contenido)

| Qué | Tamaño | Notas |
|---|---|---|
| Equilibrar estados y reservas | M | Probabilidades innatas, % de reserva de maná, vida de invocaciones y daño de veneno/sangrado: jugar cada clase hasta el nivel 30 y ajustar con números reales. |
| Esbirros, torretas, drones y robot de compañía a la misma escala que el jugador (+18 %) | S | Los sprites de jugador, enemigos y NPC ya subieron; los dibujos de aliados siguen en tamaño antiguo. |
| Escala de obstáculos por zona | S | Revisar cajas, monitores y árboles frente al nuevo tamaño; reducir los más grandes. |
| Tooltips de estados al pasar el mouse por los iconos sobre los enemigos | S | Hoy solo se leen en el marco del objetivo. |
| Sonidos propios de cada estado (chisporroteo, hielo, burbujeo, goteo) | S | Hay SFX de fuego, frío y rayo; faltan veneno, sangrado y congelación. |
| Pantalla de hoja de personaje con resumen de estados (probabilidad, potencia, duración) | S | `Ailments.chances` ya lo calcula. |
| Pruebas de rendimiento con 150+ enemigos con estados | M | `EnemyManager` ahora dibuja iconos y efectos por enemigo; medir y, si hace falta, dibujar solo los cercanos a cámara. |

## 2. Combate y habilidades

- **Más invocaciones persistentes** (M): una por clase de las que aún no tienen (Tester QA: *Bot de Pruebas*; Frontend: *Dron de Diseño*; Ingeniera de Prompts: *Agente IA*). Mejoras por nivel de placa y por hito.
- **Auras y reservas** (M): aprovechar la reserva de maná para auras persistentes (velocidad, regeneración, daño), igual que en PoE.
- **Más RAM de asistencia** (M): *Condensador* (los estados se propagan al morir), *Detonador de Estados* (consume el estado para un golpe extra), *Dispersión* (el veneno salta al morir el enemigo), *Overclock Térmico* (daño extra contra quemados/helados).
- **Interacciones entre estados** (M): congelado + golpe físico fuerte = rotura; electrocutado + fuego = sobrecarga; envenenado + sangrando = infección.
- **Resistencia a estados en enemigos** (S): jefes y élites inmunes a uno o dos estados; afijos de élite («Ignífugo», «Aislado»).
- **Estados sobre el jugador** (M): los enemigos aplican quemado, electrocutado, helado y congelado de verdad (hoy solo hay daño degenerativo con icono). Pociones y pasivas que los limpian o reducen.
- **Ascendencias** (M): revisar las 21 ascendencias para que cada una tenga al menos un efecto con estados o autómatas, y la de Robótica con la nueva piedra angular.
- **Habilidades de apoyo del jefe** (S): que los jefes de acto I y II apliquen estados al jugador como pista de la mecánica.
- **Rotación de habilidades por clase** (M): habilidades desbloqueables por nivel (no solo botín) para que cada clase tenga progresión de kit propia.

## 3. Enemigos y jefes

- Sprites de enemigos nuevos para el acto III (hoy comparten atlas con los anteriores) y animaciones de ataque (L).
- Afijos de élite y únicos (M): auras, escudos, reflejo, explosión al morir.
- Jefes con fases visibles y barra de jefe propia en el marco del objetivo (M).
- Enemigos que atacan a las invocaciones con comportamiento propio (foco en el golem, explosivos contra torretas) (S).

## 4. Contenido

| Qué | Tamaño |
|---|---|
| **Acto IV** (zonas, NPCs, misiones, jefe, escenas) | L |
| Misiones secundarias con recompensas de RAM de asistencia y placas de invocación | M |
| Más objetos únicos y conjuntos, con efectos de estados y autómatas | M |
| Nuevas bases de objetos y afijos de estados (`+x % a quemar`) | M |
| Mapas post-historia / modo de oleadas infinito reutilizando las *pruebas de estrés* | L |
| Dificultades (normal, pesadilla, infierno) con escalado de estados | M |

## 5. Interfaz

- Barra de buffs y debuffs del jugador con iconos, tiempos y tooltips (hoy solo hay estados sobre el orbe y las cajas de activos) (M).
- Pantalla K con filtros por tipo de habilidad y vista previa de DPS con y sin RAM (M).
- Árbol pasivo: buscador por estado (escribir «quemar» resalta los nodos), resaltar temáticas nuevas y mostrar su icono en los clusters (M).
- Minimapa con aliados e iconos de jefes (S).
- Configuración: tamaño de interfaz, daltonismo (los estados se distinguen solo por color en parte), volumen por canal (M).
- Accesibilidad de texto: tamaños de letra y diálogos más lentos o rápidos (S).
- Mando / control con gamepad (L).

## 6. Arte y audio

- Sustituir los sprites provisionales dibujados con formas por arte final (personajes, NPC, iconos de habilidad y de estado) (L).
- Retratos de NPC más expresivos y personajes del acto III (M).
- Música por zona y por jefe (hoy hay un tema por ambiente) (M).
- Efectos de partículas por estado más ricos (chispas persistentes, escarcha que cubre el sprite) (M).
- Voz del narrador y de los NPC: terminar de estabilizar el proceso aparte y añadir ajustes por personaje (S).

## 7. Sistemas y calidad

- **Guardado**: versionado de más datos (flags nuevas ya migradas con `starter_kit_v2`), copia de seguridad automática y varios espacios de guardado por perfil (M).
- **Tests**: añadir pruebas de integración que carguen cada zona y simulen 30 s de combate con cada clase (M).
- **Rendimiento**: portar `EnemyManager` a C# o GDExtension si el presupuesto de 4 ms se rompe con estados y aliados (L).
- **Herramientas**: generador de capturas por modo (`-- combate` ya existe) para más pantallas y comparar antes/después (S).
- **Cliente/servidor** (L, a largo plazo): la lógica está separada de los nodos; falta aislar `SkillController` y `EnemyManager` de `Node2D` para un modo cooperativo.
- **Exportación**: plantillas para Linux y macOS, e instalador de Windows (S).

## 8. Próximos pasos sugeridos (orden)

1. Jugar el build nuevo con las siete clases y ajustar equilibrio (sección 1).
2. Estados sobre el jugador y buffs/debuffs en el HUD.
3. Tres invocaciones persistentes más y auras con reserva de maná.
4. Pasar a arte final de personajes y enemigos del acto III.
5. Acto IV.
