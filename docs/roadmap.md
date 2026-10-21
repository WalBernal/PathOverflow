# Roadmap — Path Overflow: El Último Commit

Estado a octubre de 2026: Actos I a III jugables, 7 clases con kit propio, estados alterados con iconos, 9 invocaciones persistentes y 4 auras con reserva de maná, RAM por grados (menor / normal / mayor), enemigos con resistencias, inmunidades y afijos, jefes con fases y barra de jefe. Lo que **falta**, por prioridad. **S** = pequeño (≈ 1 sesión), **M** = mediano, **L** = grande.

## 1. Pulido inmediato

| Qué | Tamaño | Notas |
|---|---|---|
| Equilibrar con partidas reales | M | Probabilidades de estado, reservas de maná (auras 16-22 %, invocaciones 10-25 %), vida y daño de las 9 invocaciones, penalización del encadenamiento por grado, daño de los afijos (explosivo, tóxico) y duración de las fases de invulnerabilidad. Jugar cada clase hasta el nivel 30. |
| Esbirros, torretas, drones, invocaciones y robot de compañía a la escala del jugador (+18 %) | S | El jugador, los enemigos y los NPC ya subieron; los aliados siguen en tamaño antiguo. |
| Escala de obstáculos por zona | S | Revisar cajas, monitores y árboles frente al nuevo tamaño de los sprites. |
| Sprites propios para las invocaciones nuevas | M | Hoy son figuras dibujadas con formas (Dron de Mantenimiento, Bot de Pruebas, Mina Rodante, Agente IA...). |
| Sonidos por estado y por habilidad nueva | S | Faltan veneno, sangrado, congelación, aura on/off, curación del dron y explosión de la mina. |
| Tooltips al pasar el mouse por los iconos de estado sobre los enemigos | S | Hoy se leen en el marco del objetivo. |
| Rendimiento con 150+ enemigos con estados, afijos y aliados | M | `EnemyManager` dibuja iconos, aros de afijo y efectos por enemigo; medir y, si hace falta, limitar a lo que se ve en cámara. |

## 2. Combate y habilidades

- **Estados sobre el jugador** (M): los enemigos aplican quemado, electrocutado, helado y congelado de verdad (hoy solo hay daño degenerativo con icono). Pociones y pasivas que los limpian o reducen; resistencia propia a cada estado.
- **Buffs y debuffs del jugador en el HUD** (M): barra con iconos, tiempos y tooltips para pociones, potenciadores, estados y auras.
- **Interacciones entre estados** (M): congelado + golpe fuerte = rotura; electrocutado + fuego = sobrecarga; envenenado + sangrando = infección.
- **Invocaciones y auras de nivel avanzado** (M): una invocación y un aura más por clase, mejoras por hito y modo "reservar más maná = más potencia".
- **Auras con alcance** (S): hoy afectan a todos tus aliados; que dependan de la distancia al jugador y haya auras que debiliten enemigos.
- **RAM de nuevos grados** (M): grados menor / mayor para perforación, multicanal y área; módulos de efecto sobre aliados (rebotes en torretas, estados en drones).
- **Pasivas de aliados** (M): temática del árbol para vida y reserva de invocaciones, y notables de auras.
- **Ascendencias** (M): revisar las 21 para que cada una tenga al menos un efecto con estados, auras o autómatas.
- **Desbloqueo de habilidades por nivel** (M): que cada clase tenga progresión de kit propia, no solo botín.

## 3. Enemigos y jefes

- **Más afijos** (M): reflejo de daño, escudo de energía, aura que cura a los demás, teletransporte, y combinaciones que se prohíben entre sí.
- **Resistencias de jefes por fase** (S): que una fase cambie de inmunidad (p. ej. fase 2 inmune al fuego, fase 3 al hielo).
- **Fases en los subjefes y élites únicos** (M): los gemelos de la Carrera Crítica y los raros (Puntero Salvaje, Centinela del Cargador) también con barra y fases.
- **Sprites de enemigos nuevos para el acto III y animaciones de ataque** (L).
- **Comportamiento anti-invocaciones** (S): enemigos que priorizan al golem, explosivos contra torretas.
- **Telegrafiado de las fases** (S): sonido y cámara (sacudida) al cambiar de fase.

## 4. Contenido

| Qué | Tamaño |
|---|---|
| **Acto IV** (zonas, NPCs, misiones, jefe con fases, escenas) | L |
| Misiones secundarias con recompensas de RAM de grado alto, placas de invocación y auras | M |
| Más objetos únicos y conjuntos con efectos de estados, auras y autómatas | M |
| Afijos de objetos de estados (`+x % a quemar`) y de autómatas | M |
| Mapas post-historia / modo de oleadas infinito reutilizando las pruebas de estrés | L |
| Dificultades (normal, pesadilla, infierno) con más afijos y resistencias | M |

## 5. Interfaz

- Pantalla K con filtros por tipo de habilidad, y vista previa de DPS con y sin RAM (M).
- Árbol pasivo: buscador por estado (escribir «quemar» resalta los nodos) y vista de las temáticas nuevas (M).
- Minimapa con aliados e iconos de jefes (S).
- Hoja de personaje con resumen de estados (probabilidad, potencia, duración) y de auras activas (S).
- Configuración: tamaño de interfaz, modo daltónico (los estados se distinguen en parte por color), volumen por canal (M).
- Mando / gamepad (L).

## 6. Arte y audio

- Sustituir los sprites provisionales dibujados con formas por arte final: personajes, NPC, invocaciones, iconos de habilidad y de estado (L).
- Retratos de NPC más expresivos y personajes del acto III (M).
- Música por zona y por jefe, con cambio al entrar en una fase nueva (M).
- Partículas de estados más ricas (escarcha que cubre el sprite, chispas persistentes) (M).
- Voz del narrador y de los NPC: estabilizar el proceso aparte y añadir ajustes por personaje (S).

## 7. Sistemas y calidad

- **Guardado**: copia de seguridad automática y varios espacios por perfil; guardar qué auras estaban activas (M).
- **Tests**: pruebas de integración que carguen cada zona y simulen 30 s de combate con cada clase (M).
- **Rendimiento**: portar `EnemyManager` a C# o GDExtension si el presupuesto de 4 ms se rompe con estados y aliados (L).
- **Herramientas**: más modos de `capture_screens` (hoy `-- combate`) para comparar antes y después (S).
- **Cliente/servidor** (L, largo plazo): aislar `SkillController` y `EnemyManager` de `Node2D` para un modo cooperativo.
- **Exportación**: plantillas para Linux y macOS, e instalador de Windows (S).

## 8. Próximos pasos sugeridos

1. Jugar el build nuevo con las siete clases y equilibrar (sección 1).
2. Estados sobre el jugador y barra de buffs y debuffs.
3. Sprites y escala de aliados; sonidos de estados.
4. Acto IV con jefe de fases y afijos propios.
5. Arte final de personajes y enemigos.

## Hecho recientemente (no repetir)

Kits de 3 habilidades y rasgo por clase · estados alterados con iconos · RAM de asistencia y por grados con escala por nivel · encadenamiento con penalización que mejora por nivel · invocaciones persistentes (9) y auras (4) con reserva de maná visible en el orbe · resistencias, inmunidades y 10 afijos de enemigos · fases en los tres jefes y barra de jefe segmentada · marco del objetivo con resistencias, afijos y estados · tutorial con enemigos lejos · escena final del acto I · sprites +18 % · M. Páez con sonrisa fija.
