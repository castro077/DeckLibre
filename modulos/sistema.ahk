; =====================================================================
;  DeckLibre  ·  sistema.ahk
;  Bandeja, inicio con Windows como administrador y aviso de bateria
; =====================================================================

; =====================================================================
;  BANDEJA
; =====================================================================
ConfigurarTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Configurar...", AbrirConfig)
    A_TrayMenu.Add("Modo botonera  (Ctrl+Alt+F12)", AlternarModo)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Hoja de teclas", HojaMenu)
    A_TrayMenu.Add("Monitor de recursos", AlternarRecursosMenu)
    A_TrayMenu.Add("Widgets", MenuWidgets())
    A_TrayMenu.Add("Identificar pantallas", IdentificarPantallas)
    A_TrayMenu.Add("Historial del portapapeles", MostrarHistorial)
    A_TrayMenu.Add("Guardar espacio de trabajo...", GuardarEspacioMenu)
    A_TrayMenu.Add("Carpeta de sonidos", AbrirCarpetaSonidos)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Respaldos...", AbrirRespaldos)
    A_TrayMenu.Add("Registro de errores", AbrirRegistro)
    A_TrayMenu.Add("Diagnóstico de audio", AbrirDiagnostico)
    A_TrayMenu.Add("Diagnóstico de recursos", (*) => Run(DiagnosticoRecursos()))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Iniciar con Windows (admin)", AlternarInicio)
    if A_IsAdmin {
        A_TrayMenu.Add("Ejecutando como administrador", (*) => 0)
        A_TrayMenu.Disable("Ejecutando como administrador")
    } else
        A_TrayMenu.Add("Reiniciar como administrador", ReiniciarAdmin)
    A_TrayMenu.Add("Recargar", (*) => Reload())
    A_TrayMenu.Add("Salir", (*) => ExitApp())
    A_TrayMenu.Default := "Configurar..."
    ActualizarCheckInicio()
    ActualizarTray()
}

ActualizarTray() {
    A_IconTip := "DeckLibre - " (gModo = "botonera" ? "Modo botonera" : "Modo normal")
    if (gModo = "botonera")
        A_TrayMenu.Check("Modo botonera  (Ctrl+Alt+F12)")
    else
        A_TrayMenu.Uncheck("Modo botonera  (Ctrl+Alt+F12)")
    ico := A_ScriptDir "\iconos\" (gModo = "botonera" ? "botonera.ico" : "normal.ico")
    if FileExist(ico)
        try TraySetIcon(ico)
}

; =====================================================================
;  INICIO CON WINDOWS COMO ADMINISTRADOR (tarea programada)
;  Asi funciona tambien con programas abiertos como admin, sin que
;  Windows pregunte cada vez que prendes el PC.
; =====================================================================
TareaExiste() => RunWait(A_ComSpec ' /c schtasks /Query /TN "DeckLibre" >nul 2>&1', , "Hide") = 0

XmlEsc(s) => StrReplace(StrReplace(StrReplace(StrReplace(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), '"', "&quot;")

ArmarXmlTarea() {
    usuario := XmlEsc(EnvGet("USERDOMAIN") "\" A_UserName)
    xml := '<?xml version="1.0" encoding="UTF-16"?>`n'
        . '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">`n'
        . '  <RegistrationInfo><Description>Inicia DeckLibre con permisos de administrador</Description></RegistrationInfo>`n'
        . '  <Triggers><LogonTrigger><Enabled>true</Enabled><UserId>' usuario '</UserId><Delay>PT5S</Delay></LogonTrigger></Triggers>`n'
        . '  <Principals><Principal id="Author"><UserId>' usuario '</UserId><LogonType>InteractiveToken</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals>`n'
        . '  <Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority></Settings>`n'
        . '  <Actions Context="Author"><Exec><Command>' XmlEsc(A_AhkPath) '</Command><Arguments>' XmlEsc('"' A_ScriptFullPath '"') '</Arguments><WorkingDirectory>' XmlEsc(A_ScriptDir) '</WorkingDirectory></Exec></Actions>`n'
        . '</Task>'
    return xml
}

AlternarInicio(*) {
    lnk := A_Startup "\DeckLibre.lnk"
    try {
        if TareaExiste() {
            RunWait('*RunAs schtasks.exe /Delete /TN "DeckLibre" /F', , "Hide")
            if FileExist(lnk)
                FileDelete(lnk)
            OSD("Ya no inicia con Windows", , "FBBF24", Chr(0xE7E8))
        } else {                           ; (si habia el acceso directo viejo, se cambia por la tarea)
            archivo := A_Temp "\DeckLibre_tarea.xml"
            try FileDelete(archivo)
            FileAppend(ArmarXmlTarea(), archivo, "UTF-16")
            RunWait('*RunAs schtasks.exe /Create /TN "DeckLibre" /XML "' archivo '" /F', , "Hide")
            try FileDelete(archivo)
            if TareaExiste()
                OSD("Inicia con Windows como administrador", , "4ADE80", Chr(0xE7E8))
            else
                OSD("No se pudo crear el inicio automático", , "F87171", Chr(0xE783))
        }
    } catch as e {
        Registrar("Inicio con Windows: " DescribirError(e), "AVISO")
        OSD("Cancelado", , "FBBF24", Chr(0xE7E8))
    }
    ActualizarCheckInicio()
}

ActualizarCheckInicio() {
    if (TareaExiste() || FileExist(A_Startup "\DeckLibre.lnk"))
        A_TrayMenu.Check("Iniciar con Windows (admin)")
    else
        A_TrayMenu.Uncheck("Iniciar con Windows (admin)")
}

ReiniciarAdmin(*) {
    try
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
    catch
        return
    ExitApp()
}

; =====================================================================
;  AVISO DE BATERIA BAJA (revisa cada minuto)
; =====================================================================
RevisarBateria() {
    global gBatAviso
    if !gBateria
        return
    sps := Buffer(12, 0)
    if !DllCall("GetSystemPowerStatus", "Ptr", sps)
        return
    ac := NumGet(sps, 0, "UChar"), p := NumGet(sps, 2, "UChar")
    if (p = 255 || ac = 1) {               ; sin bateria o cargando
        gBatAviso := 0
        return
    }
    if (p <= 10 && gBatAviso < 2) {
        gBatAviso := 2
        SoundBeep(500, 150)
        OSD("Batería muy baja  ·  conecta el cargador", p, "F87171", Chr(0xE7BA), 6000, true)
    } else if (p <= 20 && gBatAviso < 1) {
        gBatAviso := 1
        OSD("Batería baja", p, "FBBF24", Chr(0xE7BA), 4500, true)
    } else if (p > 25) {
        gBatAviso := 0
    }
}

; =====================================================================
;  BRILLO DE LA PANTALLA DE LA LAPTOP (WMI)
;  Solo funciona con la pantalla integrada; los monitores externos no
;  dejan cambiar el brillo desde Windows de esta forma.
; =====================================================================
Brillo(cambio) {
    static wmi := 0
    if !wmi
        wmi := ComObjGet("winmgmts:\\.\root\WMI")
    actual := ""
    try {
        for mon in wmi.ExecQuery("SELECT CurrentBrightness FROM WmiMonitorBrightness WHERE Active=TRUE")
            actual := mon.CurrentBrightness
    }
    if (actual = "") {
        OSD("Esta pantalla no deja cambiar el brillo", , "FBBF24", Chr(0xE706))
        return
    }
    c := Trim(cambio)
    if (c = "")
        c := "+10"
    primero := SubStr(c, 1, 1)
    nuevo := (primero = "+" || primero = "-") ? actual + Number(c) : Number(c)
    nuevo := Max(0, Min(100, Round(nuevo)))
    for mon in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=TRUE")
        mon.WmiSetBrightness(0, nuevo)
    OSD("Brillo", nuevo, "FBBF24", Chr(0xE706))
}
