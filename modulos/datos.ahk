; =====================================================================
;  DeckLibre  ·  datos.ahk
;  Datos fijos: tipos de accion, dibujo del teclado y teclado numerico
; =====================================================================

; ---------------------------------------------------------------------
; Tipos de accion que se pueden asignar a una tecla
; f = campos [etiqueta, sugerencias]   ("@procesos" = programas abiertos)
; ---------------------------------------------------------------------
global PASOS := ["+5", "-5", "+2", "-2", "+10", "-10"]
global ESQUINAS := ["Arriba derecha", "Arriba izquierda", "Abajo derecha", "Abajo izquierda"]
global TIPOS := [
    {id: "volgen",  n: "Volumen general",                  f: [["Cambio  (+5 sube, -5 baja)", PASOS]], h: "Si mantienes la tecla, sigue subiendo o bajando."},
    {id: "mutegen", n: "Silenciar sonido general",         f: [], h: "Activa o quita el silencio de todo el PC."},
    {id: "volapp",  n: "Volumen de un programa",           f: [["Programa (.exe)", "@procesos"], ["Cambio  (+5 sube, -5 baja)", PASOS]], h: "El programa tiene que haber sonado al menos una vez para aparecer en el mezclador."},
    {id: "muteapp", n: "Silenciar un programa",            f: [["Programa (.exe)", "@procesos"]], h: "Ej: Discord.exe, Spotify.exe, chrome.exe"},
    {id: "mic",     n: "Micrófono: silenciar / activar",   f: [], h: "Usa el microfono predeterminado de Windows."},
    {id: "abrir",   n: "Abrir programa, archivo o web",    f: [["Programa, carpeta o página web  (elige de la lista o usa ...)", "@apps"], ["Mover a la pantalla  (0 = no mover)", ["0", "1", "2", "3"]], ["Si ya está abierto", ["Traer al frente", "Abrir otro"]]], h: "La lista trae las apps y carpetas del sistema (Explorador, Descargas, Configuración…) y todas tus apps instaladas."},
    {id: "ventana", n: "Mover ventana activa a otra pantalla", f: [["Destino", ["Siguiente pantalla", "1", "2", "3"]]], h: "Mueve el programa que estás usando ahora. 'Siguiente' va rotando entre tus pantallas."},
    {id: "recursos", n: "Monitor de recursos (mostrar / ocultar)", f: [["Pantalla donde se muestra", ["1", "2", "3"]], ["Esquina", ["Arriba derecha", "Arriba izquierda", "Abajo derecha", "Abajo izquierda"]]], h: "CPU, RAM, GPU, disco, red y batería. Presiona la tecla otra vez para ocultarlo."},
    {id: "salida",  n: "Cambiar salida de audio (audífonos / parlantes)", f: [["Salida  (varias separadas con  /  para rotar entre ellas)", "@salidas"]], h: "'Siguiente' rota entre todas. Ej: 'Audífonos / Altavoces' rota solo entre esas dos."},
    {id: "hoja",    n: "Hoja de teclas (ver qué hace cada tecla)", f: [["Pantalla", ["Donde está el mouse", "1", "2", "3"]]], h: "Mantén la tecla para verla y suéltala para cerrar. Un toque rápido la deja abierta."},
    {id: "sonido",  n: "Reproducir sonido por el micrófono", f: [["Sonido  (de la carpeta Sonidos, o búscalo con ...)", "@sonidos"], ["Volumen %", ["100", "80", "60", "40", "20"]], ["Escucharlo yo también", ["Sí", "No"]]], h: "Necesita VB-CABLE. Presiona la tecla otra vez para cortar el sonido."},
    {id: "acomodar", n: "Acomodar ventana activa (mitades, tercios…)", f: [["Posición", ["Mitad izquierda", "Mitad derecha", "Mitad arriba", "Mitad abajo", "Tercio izquierdo", "Tercio central", "Tercio derecho", "Dos tercios izquierda", "Dos tercios derecha", "Cuarto arriba izquierda", "Cuarto arriba derecha", "Cuarto abajo izquierda", "Cuarto abajo derecha", "Centrar", "Maximizar / restaurar", "Minimizar"]]], h: "Acomoda el programa que estás usando dentro de su pantalla."},
    {id: "espacio",  n: "Espacio de trabajo (guardar / restaurar ventanas)", f: [["Nombre del espacio", "@espacios"], ["Qué hacer", ["Restaurar", "Guardar como está ahora"]]], h: "Guardar: recuerda qué programas tienes abiertos y dónde. Restaurar: los abre y los acomoda igual."},
    {id: "portapapeles", n: "Historial del portapapeles", f: [], h: "Muestra lo último que copiaste (25). Enter o el número para pegar. No se guarda en disco."},
    {id: "temporizador", n: "Temporizador / Pomodoro", f: [["Modo", ["Pomodoro (25 / 5)", "Temporizador", "Cronómetro", "Pausar / seguir", "Detener"]], ["Minutos", ["25", "5", "10", "15", "30", "45", "60"]], ["Esquina (pantalla principal)", ["Arriba centro", "Arriba derecha", "Arriba izquierda", "Abajo derecha", "Abajo izquierda"]]], h: "La misma tecla pausa y sigue. Pomodoro: 25 min de enfoque, 5 de descanso y cada 4 ciclos 15."},
    {id: "reloj",      n: "Reloj en pantalla", f: [["Pantalla", ["1", "2", "3"]], ["Esquina", ESQUINAS], ["Formato", ["24 horas", "12 horas (a. m. / p. m.)"]]], h: "Hora grande con la fecha. La misma tecla lo quita. Si reinicias, vuelve solo."},
    {id: "calendario", n: "Calendario del mes", f: [["Pantalla", ["1", "2", "3"]], ["Esquina", ESQUINAS]], h: "El mes completo con el día de hoy marcado y el número de semana."},
    {id: "notas",      n: "Notas rápidas", f: [["Pantalla", ["1", "2", "3"]], ["Esquina", ESQUINAS], ["Siempre encima", ["Sí", "No"]]], h: "Una nota para apuntar lo que sea. Se guarda sola. Arrástrala desde la barra de arriba."},
    {id: "micwidget",  n: "Aviso de micrófono silenciado", f: [["Pantalla", ["1", "2", "3"]], ["Dónde", ["Arriba centro", "Abajo centro", "Arriba derecha", "Arriba izquierda", "Abajo derecha", "Abajo izquierda"]]], h: "Solo aparece cuando tu micrófono está silenciado, para que no hables sin que te escuchen."},
    {id: "clima",      n: "Clima", f: [["Ciudad", ["Villavicencio", "Bogotá", "Medellín", "Cali", "Barranquilla"]], ["Pantalla", ["1", "2", "3"]], ["Esquina", ESQUINAS]], h: "Temperatura, probabilidad de lluvia y los próximos 3 días. Gratis, sin cuenta (Open-Meteo). Se actualiza cada 30 min."},
    {id: "brillo",   n: "Brillo de la pantalla integrada", f: [["Cambio  (+10 sube, -10 baja, o un número fijo)", ["+10", "-10", "+5", "-5", "100", "50", "20"]]], h: "Solo funciona con la pantalla integrada de la laptop. Si mantienes la tecla, sigue cambiando."},
    {id: "sistema",  n: "Teclas de sistema (bloquear, apagar pantalla, proyectar…)", f: [["Acción", ["Bloquear el PC", "Apagar la pantalla", "Suspender", "Hibernar", "Mostrar escritorio", "Vista de tareas", "Captura de pantalla (recorte)", "Solo pantalla de la PC", "Duplicar pantallas", "Extender pantallas", "Solo segunda pantalla", "Notificaciones / no molestar", "Configuración rápida (wifi, bluetooth)", "Panel de emojis", "Vaciar papelera", "Apagar el PC", "Reiniciar", "Cerrar sesión"]]], h: "Apagar, reiniciar, cerrar sesión y vaciar la papelera piden confirmación."},
    {id: "edicion",  n: "Copiar, pegar y editar texto", f: [["Acción", ["Copiar", "Cortar", "Pegar", "Pegar sin formato", "Deshacer", "Rehacer", "Seleccionar todo", "Buscar", "Guardar", "MAYÚSCULAS", "minúsculas", "Tipo Título", "Tipo oración", "Quitar espacios de más"]]], h: "Las de convertir (MAYÚSCULAS, Tipo Título…) trabajan sobre el texto que tengas seleccionado."},
    {id: "media",   n: "Control multimedia",               f: [["Acción", ["Play/Pausa", "Siguiente", "Anterior", "Detener"]]], h: "Funciona con Spotify, YouTube, etc."},
    {id: "atajo",   n: "Atajo de teclado",                 f: [["Teclas  (^ Ctrl   + Shift   ! Alt   # Win)", ["^c", "^v", "^+m", "!{Tab}", "#d", "{F13}", "^+{F1}"]], ["Enviar solo a este programa (opcional)", "@procesos"]], h: "Tip para OBS: usa {F13} a {F24}, teclas que no existen en tu teclado y nunca chocan."},
    {id: "texto",   n: "Escribir texto / plantilla",        f: [["Texto   (variables: {fecha} {hora} {dia} {mes} {año} {portapapeles}   {n} = salto de línea)", []], ["Cómo", ["Pegar (rápido)", "Escribir letra por letra"]]], h: "Ej: Hola, hoy es {dia} {fecha}{n}Saludos. 'Pegar' sirve para textos largos y con tildes."},
    {id: "esperar", n: "Esperar (para macros de varios pasos)", f: [["Milisegundos", ["100", "250", "500", "1000"]]], h: "Pausa entre una acción y la siguiente."},
    {id: "modo",    n: "Cambiar modo (botonera / normal)", f: [], h: "Esta tecla sigue activa en modo normal para que puedas volver."}
]

; ---------------------------------------------------------------------
; Dibujo del teclado (scancode, ancho en teclas, etiqueta opcional)
; ---------------------------------------------------------------------
global U := 40, GAP := 4
global FILAS := [
    [[0x01, 1, "Esc"], [0x3B, 1, "F1"], [0x3C, 1, "F2"], [0x3D, 1, "F3"], [0x3E, 1, "F4"], [0x3F, 1, "F5"], [0x40, 1, "F6"], [0x41, 1, "F7"], [0x42, 1, "F8"], [0x43, 1, "F9"], [0x44, 1, "F10"], [0x57, 1, "F11"], [0x58, 1, "F12"], [0x152, 1, "Ins"], [0x153, 1, "Supr"]],
    ArmarFila([[0x29, 1]], 0x02, 0x0D, [[0x0E, 2, "Borrar"]]),
    ArmarFila([[0x0F, 1.5, "Tab"]], 0x10, 0x1B, [[0x2B, 1.5]]),
    ArmarFila([[0x3A, 1.75, "Mayús"]], 0x1E, 0x28, [[0x1C, 2.25, "Enter"]]),
    ArmarFila([[0x2A, 1.25, "Shift"], [0x56, 1]], 0x2C, 0x35, [[0x36, 2.75, "Shift"]]),
    [[0x1D, 1.25, "Ctrl"], [0x15B, 1.25, "Win"], [0x38, 1.25, "Alt"], [0x39, 5, "Espacio"], [0x138, 1.25, "AltGr"], [0x11D, 1, "Ctrl"], [0x14B, 1, "←"], [0x148, 1, "↑"], [0x150, 1, "↓"], [0x14D, 1, "→"]]
]
; Teclado numerico: [scancode, columna, fila, ancho, alto, texto en el dibujo, nombre]
global NUMPAD := [
    [0x45, 0, 1, 1, 1, "Num", "Bloq Num"], [0x135, 1, 1, 1, 1, "/", "Num /"], [0x37, 2, 1, 1, 1, "*", "Num *"], [0x4A, 3, 1, 1, 1, "-", "Num -"],
    [0x47, 0, 2, 1, 1, "7", "Num 7"], [0x48, 1, 2, 1, 1, "8", "Num 8"], [0x49, 2, 2, 1, 1, "9", "Num 9"], [0x4E, 3, 2, 1, 2, "+", "Num +"],
    [0x4B, 0, 3, 1, 1, "4", "Num 4"], [0x4C, 1, 3, 1, 1, "5", "Num 5"], [0x4D, 2, 3, 1, 1, "6", "Num 6"],
    [0x4F, 0, 4, 1, 1, "1", "Num 1"], [0x50, 1, 4, 1, 1, "2", "Num 2"], [0x51, 2, 4, 1, 1, "3", "Num 3"], [0x11C, 3, 4, 1, 2, "Ent", "Num Enter"],
    [0x52, 0, 5, 2, 1, "0", "Num 0"], [0x53, 2, 5, 1, 1, ".", "Num ."]
]
global ETIQ := Map()
for k in NUMPAD
    ETIQ[k[1]] := k[7]
for fila in FILAS
    for k in fila
        if (k.Length >= 3)
            ETIQ[k[1]] := k[3]

ArmarFila(antes, desde, hasta, despues) {
    f := []
    for k in antes
        f.Push(k)
    loop hasta - desde + 1
        f.Push([desde + A_Index - 1, 1])
    for k in despues
        f.Push(k)
    return f
}

; ---------------------------------------------------------------------
; Categorias de la galeria de acciones y como se ve cada tipo
; VISUAL: id -> [categoria, icono (Segoe MDL2 Assets), nombre corto]
; ---------------------------------------------------------------------
global CATEGORIAS := [
    {id: "audio",    n: "Audio",                 corto: "Audio",           color: 0xFF60A5FA},
    {id: "apps",     n: "Apps y ventanas",       corto: "Apps y ventanas", color: 0xFF34D399},
    {id: "texto",    n: "Texto y teclado",       corto: "Texto y teclado", color: 0xFFA78BFA},
    {id: "sistema",  n: "Sistema",               corto: "Sistema",         color: 0xFFFBBF24},
    {id: "pantalla", n: "En pantalla y tiempo",  corto: "En pantalla",     color: 0xFFF472B6}
]
global VISUAL := Map(
    "volgen",       ["audio",    0xE767, "Volumen general"],
    "mutegen",      ["audio",    0xE74F, "Silenciar todo"],
    "volapp",       ["audio",    0xE995, "Volumen de una app"],
    "muteapp",      ["audio",    0xE74F, "Silenciar una app"],
    "mic",          ["audio",    0xE720, "Micrófono"],
    "salida",       ["audio",    0xE7F5, "Salida de audio"],
    "sonido",       ["audio",    0xE8D6, "Sonido al micrófono"],
    "media",        ["audio",    0xE768, "Multimedia"],
    "abrir",        ["apps",     0xE8A7, "Abrir app o web"],
    "ventana",      ["apps",     0xE7F4, "Mover a otra pantalla"],
    "acomodar",     ["apps",     0xE7C4, "Acomodar ventana"],
    "espacio",      ["apps",     0xE80F, "Espacio de trabajo"],
    "atajo",        ["texto",    0xE765, "Atajo de teclado"],
    "texto",        ["texto",    0xE70F, "Texto / plantilla"],
    "edicion",      ["texto",    0xE8C8, "Copiar, pegar y texto"],
    "portapapeles", ["texto",    0xE77F, "Portapapeles"],
    "sistema",      ["sistema",  0xE7E8, "Teclas de sistema"],
    "brillo",       ["sistema",  0xE706, "Brillo"],
    "modo",         ["sistema",  0xE895, "Cambiar modo"],
    "recursos",     ["pantalla", 0xE9D9, "Monitor de recursos"],
    "hoja",         ["pantalla", 0xE8FD, "Hoja de teclas"],
    "temporizador", ["pantalla", 0xE823, "Temporizador"],
    "reloj",        ["pantalla", 0xE121, "Reloj"],
    "calendario",   ["pantalla", 0xE787, "Calendario"],
    "notas",        ["pantalla", 0xE70B, "Notas rápidas"],
    "clima",        ["pantalla", 0xE753, "Clima"],
    "micwidget",    ["pantalla", 0xE720, "Aviso de mic"],
    "esperar",      ["pantalla", 0xE81C, "Esperar (macro)"]
)
