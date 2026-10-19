# Path Overflow — Biblia de lore

Documento vivo con la historia del juego, acto a acto. Lo que está marcado como **(implementado)** ya está en el juego; el resto es diseño pendiente.

## Género y tono

- **ARPG isométrico** al estilo *Path of Exile*: botín aleatorio, árbol pasivo enorme, habilidades con soportes (placas base + RAM) y ascendencias.
- **Fantasía oscura con sarcasmo de programador**: el mundo es un sistema informático corrupto, los monstruos son fallos que cobraron vida y la magia es código. Lo trágico se cuenta como una incidencia en producción.
- **Clasificación orientativa: PEGI 12 / ESRB T.** Violencia de fantasía contra criaturas digitales (sin sangre), humor irónico sobre el mundo laboral, sin lenguaje fuerte ni contenido sexual. Las "pociones" son café y refrescos.

---

## Acto I: El Último Commit (implementado)

**Premisa.** El Servidor Principal sostenía el mundo sobre un sistema antiguo, el **Monolito**, diseñado hace veinte años por **el Arquitecto**. Un viernes a las seis de la tarde, alguien hizo un `git push --force` sin tests, firmado por «admin», con el mensaje *«Por el Monolito. Que nunca se reinicie»*: **la Gran Migración**. El Servidor se corrompió y todo lo que corría dentro cobró vida (bugs con patas, procesos zombi, fugas de memoria). El jugador es un **exiliado** desplegado en producción sin pasar por staging.

| Zona | Lore |
|---|---|
| El Sandbox | Entorno de pruebas intacto desde 2014. **B.O.B.**, el Bot de Onboarding. |
| Campamento del Último Commit | Refugio con "firewall". **Aida** (la Senior, desde los tiempos del COBOL), **Mario** (el Practicante, tres meses sin accesos, gran café) y **Rafa** (el SysAdmin, reiniciando el servidor desde 2019; escribe con muchos puntos suspensivos...). |
| El Bosque de Cables | **Iris**, la Practicante Perdida: revela el mensaje del commit y la existencia del Arquitecto. |
| Las Ruinas del Monolito | Restos del sistema antiguo. |
| El Pantano de Memory Leaks | **Tomás**, el Último QA (tests desactivados «temporalmente» en 2017). «Todo proceso se puede matar. Hasta el PID 1». |
| Las Catacumbas del Legacy | Lápidas «RIP v1.0». La cinta de backup del DBA. |
| La Granja de Servidores | **El Fantasma del DBA**: hizo backups veinte años y nadie los restauró. |
| Sala del Servidor Principal | Jefe: **El Arquitecto del Monolito** (*git push --force*, *Merge Conflict*). |

### Final del Acto I y transición (implementado)

1. **Muerte del Arquitecto** (escena `arquitecto_muere`): el sistema hace glitch y tiembla. El Arquitecto, moribundo: *«kill -9... ¿sin un SIGTERM de cortesía?»*, *«El Monolito no era el problema. Era la **tapa**»*, *«el Servidor no arrancará. Se congelará. Y el **Padre** despertará. Él no deja que nada muera»*. Después, en la consola (`dmesg`): el servidor intenta arrancar, se **congela** e `init[1]` empieza a *adoptar 8192 procesos huérfanos*. Se abre un portal al campamento.
2. **Reunión en el campamento** (escena `reunion_campamento`): Aida confirma que el Servidor está congelado. Rafa se defiende: él **heredó** el servidor de **El Pepe, prestador de servicios retirado**, su antecesor en el cargo, que se jubiló dejando una nota («todo documentado») y un pósit con la contraseña de root (*«el pósit era la documentación»*). Aida sospecha que El Pepe dejó «algún cron programado y se fue a pescar». Rafa abre el **puerto 2222**: un túnel al Espacio de Kernel. *«Adelántate tú; nosotros te seguimos»*.
3. **Cae La Red Lince** (escena `red_lince`): al cruzar el portal se cae **La Red Lince**, el proveedor de internet del Acto I. Aparece la pantalla de "sin conexión" con el dinosaurio. Rafa, por los **datos de su celular** («me quedan 200 megas, no hagas streaming»), mantiene el túnel a medias. El túnel se rompe y el jugador **cae a través de la tabla de procesos** hasta la Brecha del 503.

### Misiones secundarias del Acto I (implementado)
Bichos en el cableado (Iris), Reporte de incidencias (Tomás), La cinta de backup (DBA), Granos de café (Mario).

---

## Acto II: Kernel Panic, el Abismo del Sistema Operativo

### Tono y ambientación
El Acto I transcurría en la capa de aplicación (superficial, desordenada, llena de parches). El Acto II desciende al **Espacio de Kernel**: industrial, mecánico y asfixiante. No hay interfaces gráficas ni sintaxis legible, solo registros binarios, hilos en bucle infinito, tuberías oxidadas de E/S y sectores defectuosos. Las criaturas son corrupciones de microcódigo, interrupciones no controladas y daemons que llevan décadas en segundo plano sin supervisión.

### Premisa: la Rebelión de los Huérfanos
Al caer el Arquitecto, el servidor no arrancó: **se congeló**. Al forzar la entrada al Kernel por una brecha de privilegios, el jugador descubre que `init` (PID 1) no es un proceso rebelde: es **el ancestro de todo lo que corre en la máquina**. Con el push masivo, miles de subprocesos quedaron **huérfanos** tras la caída del Monolito. Sin un padre que recogiera sus códigos de salida, `init` enloqueció intentando adoptarlos a todos. Para que el **Recolector de basura** o un reinicio no destruyeran a sus "hijos", bloqueó los canales de hardware, tomó la CPU y declaró un estado de excepción permanente: **Kernel Panic**.

### Hub: El Socket Seguro (túnel SSH) (implementado)
Enclave blindado en una terminal remota que aún mantiene una sesión activa con permisos temporales de lectura (*«NO ESCRIBIR exit»*).
- **Rafa, el Cronista**: conectado por los **datos de su celular** en un monitor de fósforo verde. Aterrado: sus comandos devuelven `Permission denied` y, con La Red Lince caída, en el campamento solo ven al dinosaurio del Chrome. Ha encontrado en el crontab una tarea de El Pepe: `limpieza_final.sh`, sin comentarios, con un emoji de pez.
- **Clara, Líder de Infraestructura (DevOps)**: veterana cínica que sobrevivió viviendo en la terminal. Trata los contenedores caídos como trincheras de guerra.
- **El Recolector**: un Garbage Collector defectuoso que busca punteros nulos y memoria sin referenciar. Habla entrecortado, **tachando partes de sus propias frases**. Por ahora recicla equipo normal (3 piezas blancas = 1 objeto mejor).

### Zonas

| Zona | Entorno | Encuentros y revelaciones | Estado |
|---|---|---|---|
| **La Brecha del 503** | Pasillo inestable donde el suelo parpadea entre binario y vacío. | Caída a través de la tabla de procesos. **Zombies**: procesos muertos que siguen ocupando la tabla de descriptores. | Implementada |
| **El Socket Seguro** | Hub (ver arriba). | Rafa, Clara, El Recolector. | Implementado |
| **La Fábrica de Hilos (Thread Pool)** | Factoría colosal: pistones rítmicos ejecutan tareas concurrentes; el vapor quema como sobrecalentamiento térmico. | Subjefe: **La Carrera Crítica (Race Condition)**, dos gemelos mecánicos (Hilo Alfa y Hilo Beta) que se turnan la vulnerabilidad: solo uno recibe daño cada vez. | Implementada |
| **Las Alcantarillas del Buffer Overflow** | Túneles anegados de datos en bruto que se desbordan de sus límites. | Se rescata el **registro de auditoría de Clara**: el Último Commit no vino de fuera, sino de una **llamada interna programada hace siete años**, justo cuando se jubiló El Pepe. Escotilla cerrada al **Módulo de Refrigeración** (necesita la Tarjeta de Acceso al Rack). | Implementada |
| **La Fosa de los Procesos Huérfanos** | Vertedero donde los procesos abandonados forman una comuna para no ser recolectados. | NPC: **Sindicato de Huérfanos (PID 404)**. Piden no restaurar el sistema a ciegas: un formateo los borraría para siempre. | Pendiente |
| **La Grieta del Deadlock** | Cruce donde dos gigantes de hierro están trabados, cada uno esperando el recurso del otro. | Puzle de combate: romper los **Mutex Locks** para abrir la compuerta central. Aquí está la **Tarjeta de Acceso al Rack**, que obliga a volver a las Alcantarillas. | Implementada |
| **El Módulo de Refrigeración** (opcional) | Cámara helada bajo las Alcantarillas. | Los tres bloques de *Caché en Frío* y una Prueba de Estrés Térmico (5 oleadas). | Implementada |
| **El Bus del Sistema** | Autopista de datos hacia el núcleo; waypoint. | Interrupciones, hilos desbocados y trolls. | Implementada |
| **El Anillo 0 (Ring 0)** | Cámara circular con cuatro núcleos de CPU que se sobrecalientan. | Jefe del acto: **init (PID 1, El Padre de Todos)**. | Implementada |

### Jefe: `init`, el Proceso Primordial (implementado)
No lucha por maldad, sino por un imperativo algorítmico: **nada entra, nada sale, nada muere**. Arena: el zócalo de la CPU, dividido en **cuatro núcleos** que se sobrecalientan por turnos.
- **Fase 1: Fork Bomb.** Se divide en copias exactas pero frágiles. Si no se limpian con daño de área, saturan la arena y congelan el movimiento del jugador (caída deliberada de frames en el ataque).
- **Fase 2: Asignación de prioridad (`nice -20`).** Canaliza la energía del bus del sistema: ráfagas de interrupciones no enmascarables (**NMI Traps**) que obligan a cubrirse tras los disipadores.
- **Fase 3: Out of Memory (OOM Killer).** Con poca vida invoca al demonio de la memoria baja: rayos de escaneo salen de los núcleos de la CPU a través del jugador; si al dispararse atraviesan a `init`, le quitan un 7 % de su vida. Hay que colocarse alineado con un núcleo y con `init` y apartarse a tiempo.

### Final del Acto II: el giro hacia el Acto III (implementado como escena `init_muere`)
1. **Muerte de PID 1**: con un `SIGKILL` definitivo, `init` colapsa: `System halted. Halting CPU.`
2. **El apagón que no apaga**: la música cesa y todo queda en negro... pero el juego no termina. La placa base sigue recibiendo energía desde un estrato más profundo e inaccesible.
3. **El destape**: en los registros póstumos de `init`, Clara y Rafa descubren que el Arquitecto no intentaba salvar el Monolito, sino que actuaba como **cortafuegos humano**: el push del Último Commit se ejecutó para **sellar el acceso a la Capa Física / Firmware (BIOS/UEFI)**. (Por eso el Arquitecto dice al morir que el Monolito era «la tapa».)
4. **Gancho del Acto III**: algo ajeno al sistema operativo está grabado a fuego en las memorias de solo lectura (**ROM**). Rafa detecta una señal que habla directamente con el hardware: alguien intenta forzar un **reflashing total** que pulverizaría el universo digital. La única ruta es atravesar la controladora de bus hacia **El Silicio Profundo**.

### Misiones secundarias del Acto II (implementadas)
- **El Puntero Salvaje**: rastrear una aberración errática que se teletransporta corrompiendo las tablas de botín de las zonas, si no se la acorrala con trampas de contención.
- **La Petición del Sindicato**: conseguir un descriptor de archivo falso para que un grupo de huérfanos se camufle como servicio legítimo y sobreviva a la purga.
- **Prueba de Carga** (El Recolector): superar un Banco de Pruebas de Estrés (oleadas con recompensa visible).
- **Caché en Frío**: recuperar bloques de datos congelados de un viejo módulo de refrigeración líquida para que Clara reconstruya el mapa de memoria del Acto III.

---

## Hilos abiertos

- **El Pepe, prestador de servicios retirado**: antecesor de Rafa. ¿Su cron `limpieza_final.sh` (con un pez) es la «llamada interna programada hace años» del registro de Clara? ¿Era «admin»?
- **Los huérfanos**: ¿salvarlos o purgarlos? El Sindicato (PID 404) podría dar elecciones al jugador.
- **La Red Lince**: el proveedor de internet que siempre cae en el peor momento; buen chiste recurrente para los siguientes actos.
- **Aida y Mario** siguen en el campamento, sin conexión. Rafa prometió alcanzar al jugador «en cuanto baje la VPN».
- **Acto III: El Silicio Profundo** (firmware, ROM, BIOS/UEFI, reflashing).

- **Las clases como primer trabajo**: el exiliado es un recién egresado; cada clase es un puesto de entrada y cada ascendencia (nivel 20), un camino de carrera.
