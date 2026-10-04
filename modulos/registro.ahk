; =====================================================================
;  DeckLibre  ·  registro.ahk
;  Registro de errores (registro.txt)
; =====================================================================

; =====================================================================
;  REGISTRO DE ERRORES (registro.txt)
; =====================================================================
Registrar(msg, nivel := "ERROR") {
    static archivo := A_ScriptDir "\registro.txt"
    try {
        if (FileExist(archivo) && FileGetSize(archivo) > 300000)
            FileMove(archivo, A_ScriptDir "\registro_anterior.txt", 1)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "   " nivel "   " msg "`n", archivo, "UTF-8")
    }
}

DescribirError(e) {
    if !IsObject(e)
        return String(e)
    t := e.HasProp("Message") ? e.Message : "Error"
    if (e.HasProp("Extra") && e.Extra != "")
        t .= "  (" e.Extra ")"
    if e.HasProp("What")
        t .= "   [" e.What (e.HasProp("Line") ? ", línea " e.Line : "") "]"
    return t
}

; Errores que no atrapo ningun try: se anotan y AutoHotkey muestra su ventana normal
AlErrorGeneral(e, modo) {
    Registrar("Error no controlado: " DescribirError(e))
    return 0
}

AbrirRegistro(*) {
    archivo := A_ScriptDir "\registro.txt"
    if !FileExist(archivo)
        FileAppend("Registro de DeckLibre`n`n", archivo, "UTF-8")
    Run(archivo)
}
