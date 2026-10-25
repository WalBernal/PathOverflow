# Acto IV: El Setup de la BIOS — diseño

> **Estado: borrador para revisión.** Nada de esto está construido. Sigue `docs/lore.md` (continuidad) y `docs/estilo.md` (español latinoamericano neutro, sarcasmo de programador, términos técnicos en inglés). Al final hay **preguntas abiertas** que conviene decidir antes de empezar T28–T30.

## Resumen en una frase

Debajo del firmware que casi se reflashea está la **BIOS**, el primer programa que corre al encender la máquina; allí vive desde 2004 la cuenta que firmó el Último Commit: **admin**, con contraseña **admin**, que nadie cambió nunca.

## Tono y ambientación

- El Acto I era la capa de aplicación (desordenada), el II el kernel (industrial), el III el silicio (cristalino y frío). El IV es **retro**: los menús azules y grises del *Setup* de BIOS de los 90 y 2000, texto en 80 columnas, pitidos del altavoz interno, la fecha atascada en **01/01/2000** y la pila CR2032 agotándose.
- Paleta: azul BIOS (`0000aa`), gris claro de las ventanas, amarillo de la opción seleccionada, rojo de «Disabled». Los suelos son cuadrículas de caracteres; los bordes, marcos de doble línea (`╔═╗`).
- Música: chiptune grave con el pitido del POST como percusión; cada zona baja un poco más el tempo, como un arranque que tarda.

## Premisa

Al detener el reflasheo al 99 %, `limpieza_final.sh` completó su ejecución 2 de 2 (Acto III). Lo que despertó no es un virus nuevo: es lo más viejo de la máquina. Cuando instalaron el servidor del Monolito en 2004, alguien dejó la cuenta de fábrica del firmware **admin/admin**. Con los años, esa cuenta, que tiene permisos sobre todo y no pertenece a nadie, se volvió consciente en el **Modo de Gestión del Sistema** (SMM, «Ring −2»), un modo del procesador que el sistema operativo ni siquiera ve.

- **El Último Commit** salió de admin (por eso estaba firmado «admin» y sin descripción: admin nunca escribe descripciones).
- **El Inge Pepe** lo descubrió hace siete años. Como nadie le creyó («todos somos admin», le dijeron), lo encerró con lo que tenía: el Monolito encima como tapa, el Arquitecto como cortafuegos humano y `limpieza_final.sh` para sellar cada capa si alguien rompía la anterior. El pez `><(((º>` no era una firma cualquiera: El Pepe no se fue a pescar, **se fue a cazar phishing**. Así fue como admin consiguió sus permisos.
- Ahora admin quiere lo único que nunca tuvo: **que alguien cambie su contraseña**, para dejar de ser «nadie». Si no lo consigue, piensa quedarse con todos los equipos de la red de la UAdeO, que siguen conectados por el reflasheo del Acto III.

## Hub: La Pila del CMOS

Una ventana de Setup en «Standard CMOS Features», con un reloj que marca siempre 00:00 del 01/01/2000. Es el único lugar que conserva la configuración entre apagones.

| NPC | Papel |
|---|---|
| **Berta, la Pila CR2032** | Señora mayor de 3 voltios que recuerda cada ajuste desde 2004 y se va apagando: la configuración que guarda «se pierde si me quitan». Vende objetos raros a cambio de tokens (comerciante del acto) y es la que cuenta lo de admin/admin. |
| **Rafa** | Llega por fin en persona: bajó la VPN... a mano, desconectando el router de La Red Lince. Ahora no tiene ni datos del celular. Hace de cronista y abre los waypoints. |
| **M. Páez** | Ve la BIOS como un sistema de ecuaciones; dirige las misiones de la Secuencia de Arranque. Sigue sin cargador del Kindle. |
| **Eugenio** | Catador de café sin café: cata el «café» de la máquina expendedora de la sala de maestros, que también cayó. Misión secundaria. |
| **El Recolector** | Reaparece: aquí se puede **liberar memoria de verdad** (mejora del reciclaje: objetos mágicos → raros). |

## Zonas (niveles 38–48)

| Zona | Nivel | Entorno | Encuentros y revelaciones |
|---|---|---|---|
| **El POST (Power-On Self-Test)** | 38 | Pasillo donde se cuentan los módulos de memoria en voz alta (`Memory Test: 640K OK`). Los pitidos cambian el terreno. | Entrada: escena del pitido largo. Primer contacto con los **Beep Codes**. |
| **La Pila del CMOS** | — | Hub (ver arriba). | Berta, Rafa, Páez, Eugenio, El Recolector. |
| **El Menú Advanced** | 39 | Pasillos de opciones con el aviso «No cambie estos valores si no sabe lo que hace». Las opciones en rojo (*Disabled*) son muros; las amarillas, puertas. | Subjefe: **El Jumper de Recuperación**, dos pines que se puentean y desapuentean (solo es vulnerable mientras está puenteado). |
| **La Secuencia de Arranque (Boot Order)** | 41 | Una estación de trenes donde cada andén es un dispositivo de arranque (disquete, CD, USB, red). | Misión principal: **reordenar el arranque** (activar tres andenes en el orden correcto con combate entre medias). Un disquete de 3½ con la etiqueta «PEPE — NO FORMATEAR» (lo que Nacho compró en el Acto I era la caja vacía). |
| **La ROM de Video Legada** | 43 | Zona en 16 colores y 320×200; los enemigos parpadean como sprites de los 90. | Las **Option ROMs** invocan copias de enemigos de actos anteriores en baja resolución. Se recupera la **libreta Scribe de gatitos** del Prólogo: no era un recetario, era el registro de quién tenía acceso a admin (y sale el nombre del jugador como prestador de servicio social). |
| **El Sector Oculto** | 45 | Pasillos que solo aparecen al mirarlos de reojo (zonas que se revelan al acercarse). Waypoint. | Notas de El Pepe en la NVRAM: «Si lees esto, ya cayó init. No le cambies la contraseña a lo loco». |
| **El Modo de Gestión del Sistema (Ring −2)** | 48 | Arena: una cámara negra donde el borde es el marco de una ventana de BIOS y el suelo es un mapa de sectores. | Jefe: **admin/admin**. |

## Enemigos nuevos (con afijos propios)

| Enemigo | Comportamiento | Afijo o rasgo |
|---|---|---|
| **Beep Code** | Grupo de pitidos: 1 largo + N cortos. El largo carga y los cortos lo siguen; cuantos más cortos vivos, más daño hace el largo. | *Código de error*: al morir deja un número que da un efecto en la zona (1 = más lento, 2 = menos armadura, 3 = sin regeneración). |
| **Jumper Suelto** | Salta entre pines (teletransportes cortos) y aturde al caer. | *Puenteado*: invulnerable mientras salta. |
| **Pila Hinchada** | Lenta, explota en un área grande de rayo al morir. | *Fuga de ácido*: deja un charco degenerativo. |
| **Sector Defectuoso** | Trampa viva en el suelo que se activa al pisarla. | *Bad block*: solo se ve de cerca (como las minas). |
| **Option ROM** | Invocador estático que trae copias pixeladas de enemigos de actos anteriores. | *Legado*: sus invocaciones tienen las resistencias del acto de donde vienen. |
| **Watchdog Timer** | Persigue y, si no muere en 8 s, «reinicia» a los enemigos cercanos (vida al máximo). | Enemigo prioritario: cuenta atrás visible. |

## Misiones

**Principales**
1. **Pitido largo** (POST): llegar a la Pila del CMOS y hablar con Berta.
2. **Orden de arranque** (Páez): activar los tres andenes de la Secuencia de Arranque en el orden correcto.
3. **La libreta de gatitos** (Rafa): recuperar la libreta Scribe en la ROM de Video Legada.
4. **Credenciales de fábrica**: entrar al Modo de Gestión del Sistema y derrotar a admin.

**Secundarias**
- **Café de máquina** (Eugenio): tres vasos de café de la expendedora repartidos por el acto (por fin un 10/10... de lo malo que está).
- **Ajustes de fábrica** (Berta): encontrar tres opciones perdidas del CMOS; al entregarlas, la fecha deja de ser 01/01/2000 (cambio visual en el hub).
- **Copia de seguridad de Rafa**: escoltar la laptop de Rafa (una unidad aliada con vida) por el Sector Oculto mientras sube un respaldo.
- **Anti-spam**: protege a M. Páez mientras captura calificaciones en el sistema, de las oleadas de menensajes de spam (solicitando "Un puntito extra", "Redondéelo de 3.4 a 7", y cosas de este estilo con humor) de sus alumnos que reprobaron el primer parcial

## Jefe: admin/admin, el Usuario por Defecto

Una ventana de login con brazos de cable plano; el campo de contraseña muestra `*****` y parpadea. No odia a nadie: quiere que alguien le cambie la contraseña para dejar de ser «nadie». Cada fase cambia sus **resistencias** (como fw_update), su **mecánica de arena** (T08) y la música.

| Fase | Vida | Resistencias | Mecánica de arena | Habilidades |
|---|---|---|---|---|
| **1. Contraseña por defecto** | 100–70 % | Alta a físico y fuego | **Zonas seguras que rotan**: solo los sectores con *checksum válido* (verdes) son seguros cuando llega el «escaneo de integridad». | *Intento de login* (proyectiles en abanico que «escriben» la contraseña), *Bloqueo de cuenta* (aturde si te quedas quieto) |
| **2. Escalada de privilegios** | 70–35 % | Alta a frío y rayo | **Suelo que se rompe**: los sectores se reescriben y caen; hay que moverse por los que siguen en pie. | *sudo* (se cura un 5 % si nadie lo interrumpe), *Ring −2* (se vuelve invisible y aparece detrás del jugador) |
| **3. Persistencia** | 35–0 % | Alta a caos | **Adds que hay que interrumpir**: tres Option ROMs canalizan su reinstalación; si una termina, admin recupera un 10 % de vida. | *Rootkit* (copias de sí mismo que reflejan parte del daño), *Contraseña expirada* (ráfaga final a pantalla completa con un hueco seguro) |

## Escenas

1. **Entrada al acto** (`bios_post`): pantalla negra, un pitido largo y dos cortos, el texto del POST contando la memoria. Rafa entra corriendo con el cable del router en la mano: «Ya.... no hay internet.... pero tampoco La Red Lince....».
2. **Berta cuenta lo de admin** (al hablar con ella por primera vez): el origen de la cuenta y por qué nadie la cambió («la contraseña venía en el manual, y el manual lo tiró alguien en 2004»).
3. **La libreta de gatitos** (al recuperarla): la última página, con la letra de El Pepe: «admin no es una persona. Es lo que pasa cuando nadie es responsable».
4. **Entrada de admin** (al entrar en la arena): la ventana de login se abre sola; admin escribe su propia contraseña letra por letra: `a-d-m-i-n`.
5. **Muerte de admin** (`admin_cambia_password`): el jugador no lo mata. Le aparece `Enter new password:` y la escena deja escribir una contraseña (con su validación sarcástica: «demasiado corta», «no uses tu fecha de nacimiento»). admin, por fin con dueño, se queda tranquilo. La consola: `Settings saved. Rebooting...`.
6. **Gancho del Acto V**: el servidor arranca por primera vez desde 2019. Pasa del 99 % al 100 %. En el campamento, Aida y Mario ven el escritorio. Rafa firma la constancia del jugador... y la impresora se atasca. En la cola de impresión hay un trabajo de 2004 de un usuario llamado «pepe»: un solo archivo, `lee_esto_cuando_arranque.txt`.

## Cómo se construye (T28–T30)

- **T28 · Zonas, campamento y enemigos**: un `data/act4.json` con el estilo `bios` (ya existe en el Acto III para el Puerto JTAG y el Sector de Arranque; habría que añadir dos estilos más, `setup` y `vga16`), las seis zonas y el hub, y los seis enemigos con sus afijos en el formato de los del Acto III.
- **T29 · NPC, misiones y diálogos**: Berta, Rafa en persona, Páez, Eugenio y El Recolector en `data/npcs.json`, las misiones en `data/quests.json` y las escenas en `data/cutscenes.json`, todo validado por las pruebas de JSON y de español latinoamericano.
- **T30 · Jefe con fases y escenas**: admin/admin con tres fases, resistencias que cambian, una mecánica de arena por fase (las tres de T08), música de fase y las escenas de entrada y cierre (incluida la contraseña que escribe el jugador).

## Preguntas abiertas (para decidir antes de construir)

1. **¿El Inge Pepe aparece en persona?** Respuesta: Aún no aparece, será hasta el acto 5. Aunque se pudiera mencionar en los dialogos
2. **¿La contraseña que escribe el jugador se guarda?** Podría salir más adelante (Rafa la usa en el Acto V, o la pide un NPC). Si no se guarda, la escena es solo un chiste. Respuesta: Si se guarda.
3. **Los huérfanos del Sindicato (PID 404)**: ¿el jugador decide aquí si se reinicia con ellos o sin ellos (afectaría al Acto V), o se deja para después? Respuesta: Buena idea, hagámoslo.
4. **Aida y Mario**: en esta propuesta solo aparecen en la escena final. ¿Prefieres que alguno viaje con Rafa al hub? Respuesta: lo acompaña Mario, obligado por ser prestador de servicio
5. **Nivel**: 38–48 sigue la curva del Acto III (26–36). ¿Está bien, o el acto IV debería ser más corto (cinco zonas) y dejar más hueco para el V? Respuesta: puede ser un acto con historia y zonas bifurcadas. Pero continuará en el acto 5
6. **Nombre del acto**: «El Setup de la BIOS». Otras opciones: «Credenciales de Fábrica», «Pulsa Supr para entrar al Setup». Respuesta: Se queda ese nombre.
