; =====================================================================
;  DeckLibre  ·  edicion.ahk
;  Copiar, pegar y editar texto, y teclas de sistema
; =====================================================================

; ---------------- Copiar, pegar y convertir texto ----------------
EdicionTexto(op) {
    switch op {
        case "Copiar":            Send("^c")
        case "Cortar":            Send("^x")
        case "Pegar":             Send("^v")
        case "Pegar sin formato": PegarSinFormato()
        case "Deshacer":          Send("^z")
        case "Rehacer":           Send("^y")
        case "Seleccionar todo":  Send("^a")
        case "Buscar":            Send("^f")
        case "Guardar":           Send("^s")
        case "MAYÚSCULAS":        TransformarSeleccion(StrUpper, op)
        case "minúsculas":        TransformarSeleccion(StrLower, op)
        case "Tipo Título":       TransformarSeleccion(StrTitle, op)
        case "Tipo oración":      TransformarSeleccion(TipoOracion, op)
        case "Quitar espacios de más": TransformarSeleccion(QuitarEspacios, op)
        default:                  Send("^c")
    }
}

; Copia lo seleccionado, lo convierte y lo pega encima. El portapapeles queda como estaba.
TransformarSeleccion(fn, nombre) {
    global gIgnorarClip
    respaldo := ClipboardAll()
    gIgnorarClip := A_TickCount + 2500
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.8) {
        A_Clipboard := respaldo
        OSD("Primero selecciona un texto", , "FBBF24", Chr(0xE8C8))
        return
    }
    t := fn(A_Clipboard)
    A_Clipboard := t
    ClipWait(1)
    Send("^v")
    Sleep(300)
    gIgnorarClip := A_TickCount + 800
    A_Clipboard := respaldo
    OSD(nombre, , "A78BFA", Chr(0xE8C8), 900)
}

; Pega solo el texto, sin colores, letras ni tamaños de donde se copio
PegarSinFormato() {
    global gIgnorarClip
    if !DllCall("IsClipboardFormatAvailable", "UInt", 13) {       ; CF_UNICODETEXT
        Send("^v")
        return
    }
    respaldo := ClipboardAll()
    t := A_Clipboard
    gIgnorarClip := A_TickCount + 1500
    A_Clipboard := t
    ClipWait(1)
    Send("^v")
    Sleep(300)
    gIgnorarClip := A_TickCount + 800
    A_Clipboard := respaldo
}

TipoOracion(t) => RegExReplace(StrLower(t), "(^\s*|[.!?¡¿]\s*)(\p{Ll})", "$1$U2")

QuitarEspacios(t) => Trim(RegExReplace(RegExReplace(t, "[ \t]+", " "), "m)^ | $", ""))

; ---------------- Teclas de sistema ----------------
Confirmar(texto) => MsgBox(texto, APP, "YesNo Icon? T10 262144") = "Yes"

AccionSistema(op) {
    switch op {
        case "Bloquear el PC":
            DllCall("LockWorkStation")
        case "Apagar la pantalla":
            Sleep(500)
            DllCall("PostMessage", "Ptr", 0xFFFF, "UInt", 0x112, "Ptr", 0xF170, "Ptr", 2)
        case "Suspender":
            DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
        case "Hibernar":
            DllCall("PowrProf\SetSuspendState", "Int", 1, "Int", 0, "Int", 0)
        case "Apagar el PC":
            if Confirmar("¿Apagar el PC?")
                Shutdown(1)
        case "Reiniciar":
            if Confirmar("¿Reiniciar el PC?")
                Shutdown(2)
        case "Cerrar sesión":
            if Confirmar("¿Cerrar sesión?")
                Shutdown(0)
        case "Mostrar escritorio":
            Send("#d")
        case "Vista de tareas":
            Send("#{Tab}")
        case "Captura de pantalla (recorte)":
            Send("#+s")
        case "Solo pantalla de la PC", "Solo pantalla de la laptop":
            Run("DisplaySwitch.exe /internal")
        case "Duplicar pantallas":
            Run("DisplaySwitch.exe /clone")
        case "Extender pantallas":
            Run("DisplaySwitch.exe /extend")
        case "Solo segunda pantalla":
            Run("DisplaySwitch.exe /external")
        case "Vaciar papelera":
            if Confirmar("¿Vaciar la papelera de reciclaje?")
                DllCall("Shell32\SHEmptyRecycleBinW", "Ptr", 0, "Ptr", 0, "UInt", 7)
        case "Notificaciones / no molestar":
            Send("#n")
        case "Configuración rápida (wifi, bluetooth)":
            Send("#a")
        case "Panel de emojis":
            Send("#.")
        default:
            OSD("Acción de sistema desconocida: " op, , "FBBF24", Chr(0xE7BA))
    }
}
