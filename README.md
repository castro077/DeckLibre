# DeckLibre

Convierte **cualquier teclado** en una botonera tipo **Stream Deck**, sin comprar nada.

Sirve con el teclado de la laptop que se queda sin uso cuando conectas uno externo, con un teclado USB viejo, con un numpad barato… El que quieras. DeckLibre lo vuelve una **botonera**: cada tecla puede subir el volumen de un programa, abrir apps en la pantalla que quieras, silenciar el micrófono, reproducir sonidos en Discord, mostrar el uso de la CPU y mucho más. Mientras tanto, tu **teclado principal** (con el que escribes) sigue funcionando normal.

En este README:
- **Botonera** = el teclado que usas para las acciones.
- **Principal** = el teclado con el que escribes. Es opcional: solo se usa para el cambio automático de modo.

Funciona gracias al driver **Interception**, que permite saber de qué teclado viene cada tecla.

---

## Qué puede hacer

**Audio**
- Subir, bajar o silenciar el volumen general.
- Subir, bajar o silenciar el volumen de **un programa en específico** (Spotify, Discord, Chrome…). Si mantienes la tecla, sigue subiendo.
- Silenciar y activar el micrófono.
- Cambiar la salida de audio (audífonos ↔ parlantes) con una tecla.
- Reproducir sonidos **a través de tu micrófono**, para que los escuchen en Discord, WhatsApp, Meet o juegos (necesita VB-CABLE).

**Programas y ventanas**
- Abrir programas, archivos o páginas web, y mandarlos directo a la pantalla 1, 2 o 3.
- Si el programa ya está abierto, lo trae al frente en vez de abrir otro.
- Pasar la ventana que estás usando a la otra pantalla.
- Acomodar la ventana activa en mitades, tercios o cuartos de la pantalla.
- **Espacios de trabajo**: guarda cómo tienes acomodados tus programas y con una tecla los vuelve a abrir y acomodar igual.
- Enviar atajos de teclado (por ejemplo `Ctrl+Shift+M`) y hacer macros de varios pasos.

**Productividad**
- **Perfiles por programa**: las mismas teclas hacen cosas distintas según la app que tengas al frente (OBS, VS Code, Photoshop…).
- Historial del portapapeles: lo último que copiaste, para pegarlo otra vez.
- Plantillas de texto con fecha, hora, día y más.
- Pomodoro, temporizador y cronómetro en pantalla.
- Brillo de la pantalla (en laptops).

**En pantalla**
- **Widgets**: reloj, calendario, notas rápidas, clima y un aviso cuando el micrófono está silenciado. Se quedan aunque reinicies.
- **Indicador**: una píldora que muestra el volumen, si el micrófono quedó silenciado, etc.
- **Monitor de recursos**: una tarjeta pequeña con CPU, RAM, GPU, disco, red y batería, con gráficas. Solo trabaja mientras está visible.
- **Hoja de teclas**: mantienes una tecla y te muestra qué hace cada botón.
- Aviso de batería baja.

**Comodidad**
- Cada tecla puede tener tres acciones distintas: **toque**, **mantener** y **doble toque**.
- **Modo normal / modo botonera**: si desconectas el teclado principal (por ejemplo, para llevarte la laptop), la botonera vuelve a escribir normal sola.
- Ventana de configuración con el teclado dibujado: haces clic en una tecla y le asignas acciones. No hay que tocar código.
- Respaldos automáticos de tu configuración, y opción de exportarla o importarla.
- Puede iniciar con Windows como administrador.
- Registro de errores para saber qué falló.

---

## Requisitos

- **Windows 10 u 11** de 64 bits.
- **AutoHotkey v2** (2.0 o más nuevo).
- **Driver Interception**, que es el que separa los dos teclados.
- **.NET Framework 4**, que ya viene instalado en Windows 10 y 11.
- Opcional: **VB-CABLE**, solo si quieres reproducir sonidos por el micrófono.

---

## Instalación paso a paso

### 1. Instalar AutoHotkey v2

Descárgalo de [autohotkey.com](https://www.autohotkey.com/) e instala la **versión 2**.

### 2. Instalar el driver Interception

1. Descarga la última versión desde [github.com/oblitum/Interception/releases](https://github.com/oblitum/Interception/releases) y descomprime el zip.
2. Abre la carpeta `command line installer`.
3. Abre una **terminal como administrador** (clic derecho en Inicio → *Terminal (administrador)*). Ojo: no sirve darle doble clic al instalador.
4. Entra a esa carpeta con `cd` y ejecuta:

   ```
   install-interception.exe /install
   ```

5. **Reinicia el PC.**

### 3. Descargar DeckLibre

Descarga este repositorio (botón **Code → Download ZIP**) y descomprímelo donde quieras, por ejemplo en `Documentos\DeckLibre`.

La carpeta `Lib` ya trae AutoHotInterception y los archivos `interception.dll` que se necesitan.

### 4. Desbloquear los archivos .dll

Windows bloquea los `.dll` descargados de internet. Tienes dos opciones:

- Clic derecho sobre `Lib\Unblocker.ps1` → **Ejecutar con PowerShell** (mejor como administrador).
- O, en cada `.dll` de la carpeta `Lib`: clic derecho → **Propiedades** → marcar **Desbloquear** → Aceptar.

### 5. Primer arranque

1. Dale doble clic a `DeckLibre.ahk`.
2. Te va a pedir que **presiones cualquier tecla del teclado que quieres usar como botonera**. Así sabe cuál es.
3. Se abre el configurador. Si quieres el cambio automático de modo, entra a **Ajustes**, en **Principal** dale **Detectar** y presiona una tecla del teclado con el que escribes.

DeckLibre trae unas teclas de ejemplo para que veas cómo funciona: `1` y `2` para el volumen, `3` para el micrófono, `Espacio` para play/pausa e `Insert` para cambiar de modo. Puedes borrarlas o cambiarlas.

---

## Cómo se usa

### Abrir el configurador

Clic derecho en el ícono de la bandeja (abajo a la derecha, junto al reloj) → **Configurar...**

El ícono es **azul** en modo botonera y **ámbar** en modo normal.

### Configurar una tecla

El configurador muestra tu teclado dibujado. Las teclas que ya hacen algo se ven con el **ícono de su acción** y del color de su categoría; las que tienen algo al mantener o con doble toque llevan unos puntitos abajo.

1. Haz clic en la tecla en el dibujo, o usa **Capturar tecla** y presiónala en la botonera.
2. Elige la pestaña: **Toque**, **Mantener** o **Doble toque**.
3. Dale **+ Agregar acción**. Se abre una galería con todas las acciones agrupadas por categoría (Audio, Apps y ventanas, Texto y teclado, Sistema, En pantalla): haz clic en la que quieras.
4. Llena los detalles y dale **Guardar**. Si te equivocaste de acción, **Cambiar acción** te devuelve a la galería.
5. Opcional: ponle un **nombre** a la tecla. Sale en el indicador y en la hoja de teclas.

Todo se guarda solo. Con **Probar** ejecutas la tecla sin presionarla.

Los teclados, las opciones (indicador, batería, modo automático), los respaldos y el inicio con Windows están en el botón **Ajustes**.

Una tecla puede tener **varias acciones** seguidas. Por ejemplo, abrir Chrome en la pantalla 1 y VS Code en la pantalla 2 con una sola tecla.

**Colores del dibujo:** azul = tiene acción · ámbar = cambia el modo · azul brillante = la tecla seleccionada.

### Toque, mantener y doble toque

| Pestaña | Cuándo se ejecuta |
|---|---|
| Toque | Al presionar la tecla normal |
| Mantener | Si la sostienes más de 0.4 segundos |
| Doble toque | Si la tocas dos veces rápido (menos de 0.25 s) |

Las teclas que solo tienen "Toque" responden al instante. Las que tienen mantener o doble toque esperan un momento para saber cuál fue: si quieres que una tecla responda lo más rápido posible, déjale solo "Toque".

Si alguna vez una tecla tarda, queda anotado en **Registro de errores** (bandeja) con la palabra `LENTO`, cuánto esperó y qué acciones tenía.

### Tipos de acción

| Acción | Para qué sirve |
|---|---|
| Volumen general | Sube o baja el volumen de Windows (`+5`, `-5`…) |
| Silenciar sonido general | Silencia o activa todo el sonido |
| Volumen de un programa | Sube o baja solo un programa, por ejemplo `Spotify.exe` |
| Silenciar un programa | Silencia o activa solo ese programa |
| Micrófono: silenciar / activar | Silencia el micrófono predeterminado |
| Abrir programa, archivo o web | Abre algo y opcionalmente lo manda a una pantalla. La lista trae las apps y carpetas del sistema (Explorador de archivos, Descargas, Configuración, Administrador de tareas…) y todas tus apps instaladas |
| Mover ventana activa a otra pantalla | Pasa la ventana que estás usando a otra pantalla |
| Monitor de recursos | Muestra u oculta la tarjeta de CPU, RAM, GPU… |
| Cambiar salida de audio | Rota entre audífonos, parlantes, etc. |
| Hoja de teclas | Muestra qué hace cada tecla |
| Reproducir sonido por el micrófono | Suena en Discord o en llamadas (ver más abajo) |
| Control multimedia | Play/pausa, siguiente, anterior, detener |
| Atajo de teclado | Envía teclas: `^` Ctrl, `+` Shift, `!` Alt, `#` Win |
| Escribir texto / plantilla | Escribe o pega un texto, con variables como `{fecha}` |
| Acomodar ventana activa | Mitades, tercios, cuartos, centrar, maximizar |
| Espacio de trabajo | Guarda o restaura cómo están acomodadas tus ventanas |
| Historial del portapapeles | Muestra lo último que copiaste para pegarlo |
| Temporizador / Pomodoro | Pomodoro, temporizador o cronómetro en pantalla |
| Reloj, Calendario, Notas, Clima, Aviso de micrófono | Widgets en pantalla (ver abajo) |
| Brillo de la pantalla | Sube o baja el brillo de la pantalla integrada (laptops) |
| Teclas de sistema | Bloquear, apagar la pantalla, suspender, mostrar escritorio, captura, duplicar/extender pantallas, apagar, reiniciar… |
| Copiar, pegar y editar texto | Copiar, cortar, pegar, pegar sin formato, deshacer, y convertir lo seleccionado a MAYÚSCULAS, minúsculas o Tipo Título |
| Esperar | Pausa entre pasos de una macro |
| Cambiar modo | Pasa de botonera a normal y al revés |

> **Tip para OBS:** en la acción "Atajo de teclado" usa `{F13}` a `{F24}`. Son teclas que no existen en ningún teclado físico, así que nunca chocan con nada. Asígnalas en OBS a tus escenas.

### Perfiles por programa

En el configurador, en **Perfil**, dale **+ Nuevo perfil** y elige el programa (por ejemplo `obs64.exe`). Mientras ese perfil esté seleccionado en el configurador, lo que configures solo funciona cuando ese programa está al frente.

- Las teclas que **no** configures en el perfil siguen haciendo lo de **General**. En el dibujo se ven en un azul apagado.
- El cambio de perfil es automático, al instante en que cambias de ventana. Sale un aviso pequeño con el nombre del perfil.
- La hoja de teclas muestra las teclas del perfil activo.

Ejemplo: en General, `1` y `2` son el volumen; en el perfil de OBS, `1` y `2` cambian de escena. Al salir de OBS vuelven a ser el volumen.

### Espacios de trabajo

1. Abre y acomoda tus programas como te gusta trabajar (por ejemplo VS Code en la pantalla 1 y Chrome en la 2).
2. Guarda el espacio con un nombre: en la bandeja → **Guardar espacio de trabajo...**, o con una tecla que tenga la acción "Espacio de trabajo" en modo **Guardar**.
3. Ponle a otra tecla la misma acción en modo **Restaurar**. Al presionarla, abre los programas que falten y acomoda todo igual.

Se guarda el programa, la pantalla, la posición, el tamaño y si estaba maximizado.

### Portapapeles y plantillas

- **Historial del portapapeles**: muestra los últimos 25 textos que copiaste. Elige uno con Enter o con su número (1–9) y se pega donde estabas. El historial vive solo en memoria: no se guarda en el disco.
- **Plantillas**: en la acción "Escribir texto / plantilla" puedes usar variables:

  | Variable | Se cambia por |
  |---|---|
  | `{fecha}` | 04/10/2026 |
  | `{hora}` | 15:30 |
  | `{dia}` | sábado |
  | `{mes}` / `{año}` | octubre / 2026 |
  | `{portapapeles}` | lo que tengas copiado |
  | `{n}` | un salto de línea |

  El modo **Pegar** es instantáneo y sirve para textos largos. Después de pegar, el portapapeles queda como estaba.

### Temporizador / Pomodoro

Aparece una tarjeta pequeña con un anillo de progreso y el tiempo.

- **Pomodoro:** 25 minutos de enfoque y 5 de descanso; cada 4 ciclos, 15 de descanso. Cambia de fase solo y avisa con un sonido.
- **Temporizador:** cuenta hacia atrás los minutos que elijas.
- **Cronómetro:** cuenta hacia adelante.

La misma tecla pausa y sigue. Para cerrarlo, usa una tecla con el modo **Detener**.

### Widgets

Tarjetas pequeñas que se quedan en una esquina de la pantalla que elijas. La misma tecla las muestra y las quita, y también están en la bandeja → **Widgets**. Si reinicias el PC, vuelven solas.

| Widget | Qué muestra |
|---|---|
| Reloj | La hora grande, la fecha y una barrita con los segundos. En 24 h o 12 h. |
| Calendario | El mes con el día de hoy marcado y el número de semana. |
| Notas rápidas | Una nota para apuntar cosas. Se guarda sola en `notas.txt`. Se arrastra desde la barra de arriba y recuerda dónde la dejaste. |
| Clima | Temperatura, sensación, humedad, probabilidad de lluvia y los próximos 3 días. Usa [Open-Meteo](https://open-meteo.com) (gratis, sin cuenta). Se actualiza cada 30 minutos. |
| Aviso de micrófono | Solo aparece cuando el micrófono está silenciado, para que no hables en una llamada sin que te escuchen. |

- Si pones varios en la misma esquina, se acomodan uno debajo del otro (también respetan el monitor de recursos y el temporizador).
- El reloj, el calendario, el clima y el aviso dejan pasar el mouse: puedes hacer clic "a través" de ellos.
- Clima: escribe la ciudad tal cual (`Villavicencio`, `Madrid`). Si hay varias con el mismo nombre, agrega el país: `Valencia, Venezuela`.

### Brillo

La acción "Brillo de la pantalla" sube o baja el brillo (`+10`, `-10`) o lo pone en un valor fijo (`50`). Funciona con la pantalla integrada de las laptops. Los monitores externos no dejan cambiar el brillo así desde Windows.

### Modo botonera y modo normal

- **Modo botonera:** el teclado botonera hace tus acciones.
- **Modo normal:** el teclado botonera escribe como siempre.

Se cambia de cuatro formas:

- Con la tecla que tenga la acción "Cambiar modo" (por defecto `Insert`).
- Con `Ctrl + Alt + F12` desde cualquier teclado.
- Haciendo clic en el modo, arriba en el configurador.
- **Sola:** si desconectas el teclado principal, pasa a modo normal, y cuando lo conectas vuelve a botonera. Ideal para laptops: llegas a casa, conectas tu teclado y la laptop se vuelve botonera.

### Pantallas

En el menú de la bandeja, **Identificar pantallas** muestra un número grande en cada monitor. Usa esos números en las acciones. A veces no coinciden con los de la configuración de Windows.

### Sonidos por el micrófono (Discord, llamadas)

Windows no deja meter sonido directamente en un micrófono, así que se usa un **cable de audio virtual**.

1. Instala [VB-CABLE](https://vb-audio.com/Cable/) (es gratis, funciona con donaciones). Ejecuta `VBCABLE_Setup_x64.exe` como administrador y reinicia.
   - Si después del instalador dejas de oír todo, vuelve a poner tus audífonos como salida predeterminada.
2. Pasa tu voz por el cable:
   - Presiona `Win + R` y escribe `mmsys.cpl`.
   - En la pestaña **Grabación**, haz doble clic en tu micrófono real.
   - En la pestaña **Escuchar**, marca **"Escuchar este dispositivo"** y elige **CABLE Input**.
   - Deja tu micrófono real como predeterminado. Así la tecla de silenciar sigue funcionando.
3. En Discord (**Ajustes → Voz y vídeo**):
   - Dispositivo de entrada: **CABLE Output**.
   - Supresión de ruido: **Ninguna**. Krisp borra todo lo que no sea voz.
4. Pon tus `.mp3` o `.wav` en la carpeta `Sonidos` y asígnalos con la acción "Reproducir sonido por el micrófono".

Si presionas la tecla mientras el sonido está sonando, se corta.

### Iniciar con Windows

En la bandeja: **Iniciar con Windows (admin)**. Crea una tarea de Windows que abre DeckLibre al iniciar sesión **con permisos de administrador**. Windows pide permiso una sola vez, cuando la activas.

¿Por qué como administrador? Windows no deja que un programa normal mande teclas a programas abiertos como admin (el Administrador de tareas, algunos juegos y launchers).

### Respaldos, exportar e importar

- Cada vez que cambias algo se guarda una copia en la carpeta `Respaldos` (como máximo una cada 10 minutos). Se conservan las últimas 10.
- En el configurador, abajo: **Respaldos** (ver y restaurar), **Exportar** e **Importar**.
- Al importar se conservan los teclados del PC actual, así que puedes pasar tu configuración a otro computador.

---

## Estructura del proyecto

```
DeckLibre/
├── DeckLibre.ahk         ← archivo principal: variables generales y arranque
├── modulos/
│   ├── datos.ahk         ← tipos de acción y dibujo del teclado
│   ├── config.ahk        ← leer/guardar DeckLibre.ini, respaldos, exportar/importar
│   ├── teclados.ahk      ← detectar el teclado botonera y el principal
│   ├── acciones.ahk      ← teclas, modos, toque/mantener/doble toque, ejecutar acciones
│   ├── perfiles.ahk      ← perfiles por programa
│   ├── ventanas.ahk      ← abrir programas, mover y acomodar ventanas
│   ├── espacios.ahk      ← espacios de trabajo
│   ├── apps.ahk          ← lista de apps del sistema e instaladas para "Abrir"
│   ├── audio.ahk         ← volumen por programa, micrófono, salidas de audio
│   ├── sonidos.ahk       ← sonidos por el micrófono (VB-CABLE)
│   ├── portapapeles.ahk  ← historial del portapapeles y plantillas
│   ├── edicion.ahk       ← copiar/pegar/convertir texto y teclas de sistema
│   ├── temporizador.ahk  ← pomodoro, temporizador y cronómetro
│   ├── widgets.ahk       ← reloj, calendario, notas, clima y aviso del micrófono
│   ├── indicador.ahk     ← la píldora del indicador en pantalla
│   ├── graficos.ahk      ← ayudas de GDI+ para dibujar las tarjetas
│   ├── recursos.ahk      ← monitor de recursos (CPU, RAM, GPU, disco, red)
│   ├── hoja.ahk          ← hoja de teclas
│   ├── sistema.ahk       ← bandeja, inicio con Windows, batería y brillo
│   ├── registro.ahk      ← registro de errores
│   ├── estilo.ahk        ← tema oscuro: botones, interruptores
│   └── interfaz.ahk      ← configurador: teclado dibujado, galería de acciones, ajustes
├── iconos/               ← íconos de la bandeja (azul y ámbar)
├── Lib/                  ← AutoHotInterception + interception.dll
└── Sonidos/              ← tus sonidos (.mp3, .wav)
```

Estos archivos los crea el programa solo:

- `DeckLibre.ini`: tu configuración.
- `Respaldos/`: copias de la configuración.
- `registro.txt`: los errores.

### Cómo funciona por dentro

1. **AutoHotInterception** se "suscribe" a las teclas configuradas, **solo del teclado botonera**, y las bloquea para que no escriban.
   Cuando cambias de ventana, Windows avisa (`SetWinEventHook`) y DeckLibre cambia al perfil de ese programa, sin revisar a cada rato.
2. Cuando presionas una, `acciones.ahk` decide si fue toque, mantener o doble toque, y ejecuta la lista de acciones.
3. El audio se maneja directo con las interfaces de Windows (Core Audio), sin programas externos: por eso el volumen por programa es instantáneo.
4. Los sonidos se decodifican con Media Foundation y se reproducen en `CABLE Input` y en tus audífonos al mismo tiempo.
5. Las tarjetas (monitor y hoja) se dibujan con GDI+ en ventanas con transparencia, y los clics las atraviesan.

### El archivo de configuración

Es un `.ini` normal. Cada acción es una línea:

```ini
[Teclas]
sc011_1=abrir|chrome.exe|1|Traer al frente     ; W, toque, acción 1
sc011_2=abrir|code.exe|2|Traer al frente       ; W, toque, acción 2
sc011_h1=ventana|Siguiente pantalla||          ; W, mantener
sc011_d1=recursos|1|Arriba derecha|            ; W, doble toque
[Nombres]
sc011=Chrome + VS Code
```

- `sc011` es el código de la tecla (scancode).
- `_1`, `_2`… es el orden de las acciones.
- `h` = mantener, `d` = doble toque.

Los perfiles se guardan igual, en secciones con el nombre del programa, por ejemplo `[Teclas@obs64.exe]`. Los espacios de trabajo van en secciones `[Espacio@nombre]`. Los widgets abiertos van en `[Widgets]` y las ciudades del clima ya encontradas en `[ClimaCiudades]`.

---

## Problemas comunes

**Sale un error al abrir que dice que no carga `AutoHotInterception.dll`**
Faltó desbloquear los `.dll` (paso 4) o no está instalado el driver Interception (paso 2, y reiniciar).

**Las teclas de la botonera no hacen nada**
- Revisa que esté en modo botonera (ícono azul).
- En **Ajustes**, dale **Detectar** al teclado botonera otra vez.

**El teclado botonera dejó de funcionar del todo después de conectar y desconectar muchas veces o de hibernar**
Es una limitación conocida del driver Interception: si el número interno del teclado pasa de 10, deja de funcionar hasta reiniciar. Reinicia el PC. Tu teclado principal sigue funcionando mientras tanto.

**Una tecla no funciona en un programa específico (Administrador de tareas, un juego)**
Ese programa corre como administrador. Usa **Reiniciar como administrador** en la bandeja, o activa **Iniciar con Windows (admin)**.

**"Volumen de un programa" dice "no está sonando"**
- El programa tiene que estar reproduciendo algo.
- Revisa que el nombre del `.exe` sea el correcto.
- En la bandeja, **Diagnóstico de audio** crea un archivo con todo lo que Windows tiene sonando.

**El monitor de recursos no muestra la GPU o el disco**
En la bandeja, **Diagnóstico de recursos** crea `recursos_diagnostico.txt` con lo que respondió Windows.

**Mis amigos no escuchan los sonidos en Discord**
- Revisa la casilla "Escuchar este dispositivo".
- Revisa que la supresión de ruido de Discord esté en "Ninguna".

**Una tecla a veces tarda en responder**
- Si la tecla tiene "Mantener" o "Doble toque", espera a propósito unos 0.25 s para saber cuál hiciste. Déjale solo "Toque" si quieres que sea instantánea.
- Mira el **Registro de errores**: las teclas lentas quedan anotadas con `LENTO` y qué acción las demoró (por ejemplo, abrir un programa pesado o esperar a que aparezca su ventana).

**El clima dice "Sin conexión" o "No encontré la ciudad"**
- Necesita internet. Si falla, lo intenta otra vez solo a los 5 minutos.
- Prueba con el nombre de la ciudad sin abreviaturas, o agrega el país después de una coma.

**El antivirus marca algo**
Interception trabaja a nivel de driver con el teclado, y a algunos antivirus eso les parece sospechoso. Es un falso positivo. Todo el código de DeckLibre está a la vista en este repositorio.

---

## Desinstalar

1. Si activaste el inicio con Windows, desactívalo desde la bandeja.
2. Cierra DeckLibre (bandeja → **Salir**) y borra la carpeta.
3. Para quitar el driver: en una terminal como administrador, dentro de la carpeta del instalador de Interception, ejecuta `install-interception.exe /uninstall` y reinicia.

---

## Créditos

- [AutoHotkey](https://www.autohotkey.com/): el lenguaje.
- [AutoHotInterception](https://github.com/evilC/AutoHotInterception) de evilC (licencia MIT): la librería que conecta AutoHotkey con Interception.
- [Interception](https://github.com/oblitum/Interception) de Francisco Lopes: el driver que distingue los teclados. Revisa su licencia si quieres usarlo con fines comerciales.
- [VB-CABLE](https://vb-audio.com/Cable/) de VB-Audio: el cable de audio virtual (donationware).

---

## Licencia

DeckLibre es software libre con licencia **MIT** (mira el archivo [`LICENSE`](LICENSE)): puedes usarlo, cambiarlo y compartirlo, siempre que mantengas el aviso de autoría.

Lo que viene en la carpeta `Lib` es de otros proyectos y tiene sus propias licencias: [`Lib/LICENCIAS.md`](Lib/LICENCIAS.md).

---

Hecho por **Kevin**. Si te sirvió o tienes ideas, abre un *issue* en el repositorio.
