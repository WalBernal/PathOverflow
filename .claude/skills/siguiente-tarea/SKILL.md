---
name: siguiente-tarea
description: Ejecuta la siguiente tarea pendiente del roadmap activo (docs/roadmap2.md), la marca como hecha y hace commit. Usar cuando el usuario pida "la siguiente tarea", "seguir con el roadmap" o con /loop para encadenarlas.
---

# Siguiente tarea del roadmap

1. Lee `docs/roadmap2.md` completo (el roadmap anterior, `docs/roadmap.md`, está terminado y solo sirve de historial), sobre todo la sección **Cómo se ejecuta (protocolo para Claude)**, y síguela al pie de la letra.
2. Elige la tarea: la que esté `[~]` (a medias) o, si no hay, la primera `[ ]` de arriba abajo. Sáltate las `[x]` y las `[!]`.
3. Si no queda ninguna `[ ]` ni `[~]`, di que el roadmap está terminado y, si estás dentro de `/loop`, detén el bucle.
4. Si la última tarea terminada lleva 🛑 y el usuario no ha dado su visto bueno en esta conversación, no empieces la siguiente: pide la revisión y, dentro de `/loop`, detén el bucle.
5. Haz **una sola tarea** completa: marcar `[~]`, implementar, comprobar (check_scripts, test_core y la prueba de integración si existe), marcar `[x]`, añadir la línea al **Registro**, actualizar `README.md` si cambia algo visible, y commit en español sin push.
6. Termina con un resumen corto: qué tarea hiciste, qué cambió, resultado de las pruebas y cuál es la siguiente.
