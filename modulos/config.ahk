; =====================================================================
;  DeckLibre  ·  config.ahk
;  Archivo de configuracion (DeckLibre.ini), respaldos, exportar e importar
; =====================================================================

; =====================================================================
;  CONFIGURACION (archivo .ini)
; =====================================================================
CrearConfigInicial() {
    txt := "
    (
[General]
BotoneraHandle=
PrincipalHandle=
ModoAutomatico=1
Indicador=1
[Teclas]
sc002_1=volgen|-5||
sc003_1=volgen|+5||
sc004_1=mic|||
sc005_1=volapp|chrome.exe|-5|
sc006_1=volapp|chrome.exe|+5|
sc011_1=abrir|chrome.exe|1|Traer al frente
sc011_2=abrir|code.exe|2|Traer al frente
sc039_1=media|Play/Pausa||
sc152_1=modo|||
[Nombres]
sc011=Chrome + VS Code
    )"
    FileAppend(txt "`n", CFG, "UTF-16")
}

CargarConfig() {
    global gPrincipalHandle, gAuto, gOSD, gBateria, gKeys, gPerfiles
    if !FileExist(CFG)
        CrearConfigInicial()
    gPrincipalHandle := IniRead(CFG, "General", "PrincipalHandle", "")
    gAuto := IniRead(CFG, "General", "ModoAutomatico", "1") = "1"
    gOSD := IniRead(CFG, "General", "Indicador", "1") = "1"
    gBateria := IniRead(CFG, "General", "AvisoBateria", "1") = "1"

    gKeys := LeerMapa("Teclas", "Nombres")
    gPerfiles := Map()
    for p in StrSplit(IniRead(CFG, "Perfiles", "Lista", ""), "|") {
        p := StrLower(Trim(p))
        if (p != "")
            gPerfiles[p] := LeerMapa("Teclas@" p, "Nombres@" p)
    }
}

; Lee una seccion de teclas. Llaves: sc011_1 = toque, sc011_h1 = mantener, sc011_d1 = doble toque
LeerMapa(secTeclas, secNombres) {
    try
        sec := IniRead(CFG, secTeclas)
    catch
        sec := ""
    temp := Map()   ; sc -> {acciones: Map(indice -> accion), mantener: ..., doble: ...}
    loop parse sec, "`n", "`r" {
        p := InStr(A_LoopField, "=")
        if !p
            continue
        k := Trim(SubStr(A_LoopField, 1, p - 1))
        v := SubStr(A_LoopField, p + 1)
        if !RegExMatch(k, "i)^sc([0-9a-f]{2,3})_([hd]?)(\d+)$", &m)
            continue
        sc := Integer("0x" m[1])
        f := StrSplit(v, "|")
        if (f.Length = 0 || Trim(f[1]) = "")
            continue
        a := {t: Trim(f[1]), p1: f.Length >= 2 ? f[2] : "", p2: f.Length >= 3 ? f[3] : "", p3: f.Length >= 4 ? f[4] : ""}
        if !temp.Has(sc)
            temp[sc] := {acciones: Map(), mantener: Map(), doble: Map()}
        lista := (StrLower(m[2]) = "h") ? temp[sc].mantener : (StrLower(m[2]) = "d") ? temp[sc].doble : temp[sc].acciones
        lista[Integer(m[3])] := a
    }
    mapa := Map()
    for sc, t in temp {
        kn := NuevaTecla()
        for cual in ["acciones", "mantener", "doble"]
            for i, a in t.%cual%      ; Map recorre las llaves numericas en orden
                ListaDe(kn, cual).Push(a)
        kn.nombre := IniRead(CFG, secNombres, ScAKey(sc), "")
        mapa[sc] := kn
    }
    return mapa
}

GuardarConfig() {
    HacerRespaldo()
    ; borrar las secciones de teclas viejas (General y perfiles)
    try {
        for sec in StrSplit(IniRead(CFG), "`n")
            if RegExMatch(sec, "i)^(Teclas|Nombres)(@.*)?$")
                IniDelete(CFG, sec)
    }
    EscribirMapa(gKeys, "Teclas", "Nombres")
    lista := ""
    for p, mapa in gPerfiles {
        lista .= (lista = "" ? "" : "|") p
        EscribirMapa(mapa, "Teclas@" p, "Nombres@" p)
    }
    IniWrite(lista, CFG, "Perfiles", "Lista")
    IniWrite(gPrincipalHandle, CFG, "General", "PrincipalHandle")
    IniWrite(gAuto ? 1 : 0, CFG, "General", "ModoAutomatico")
    IniWrite(gOSD ? 1 : 0, CFG, "General", "Indicador")
    IniWrite(gBateria ? 1 : 0, CFG, "General", "AvisoBateria")
}

; Se escribe toda la seccion de una vez: con una escritura por accion,
; guardar se volvia lento a medida que habia mas teclas
EscribirMapa(mapa, secTeclas, secNombres) {
    teclas := "", nombres := ""
    for sc, k in mapa {
        key := ScAKey(sc)
        for par in [["", k.acciones], ["h", k.mantener], ["d", k.doble]]
            for i, a in par[2]
                teclas .= key "_" par[1] i "=" a.t "|" Limpia(a.p1) "|" Limpia(a.p2) "|" Limpia(a.p3) "`n"
        if (k.nombre != "")
            nombres .= key "=" Limpia(k.nombre) "`n"
    }
    if (teclas != "")
        IniWrite(RTrim(teclas, "`n"), CFG, secTeclas)
    if (nombres != "")
        IniWrite(RTrim(nombres, "`n"), CFG, secNombres)
}

Limpia(s) => StrReplace(StrReplace(StrReplace(s, "|", "/"), "`n", " "), "`r", "")

ScAKey(sc) => Format("sc{:03X}", sc)

Q(s) => '"' s '"'

; =====================================================================
;  RESPALDOS DE LA CONFIGURACION
; =====================================================================
; Copia DeckLibre.ini a la carpeta Respaldos (maximo una vez cada 10 min,
; y solo si cambio algo). Se guardan los ultimos 10.
HacerRespaldo(forzar := false) {
    global gUltimoRespaldo
    if !FileExist(CFG)
        return
    if (!forzar && gUltimoRespaldo && A_TickCount - gUltimoRespaldo < 600000)
        return
    try {
        DirCreate(CARPETA_RESPALDOS)
        ultimo := UltimoRespaldo()
        if (ultimo != "" && FileRead(ultimo) == FileRead(CFG)) {
            gUltimoRespaldo := A_TickCount
            return
        }
        FileCopy(CFG, CARPETA_RESPALDOS "\DeckLibre_" FormatTime(, "yyyy-MM-dd_HH-mm-ss") ".ini", 1)
        gUltimoRespaldo := A_TickCount
        LimpiarRespaldos(10)
    } catch as e
        Registrar("No se pudo hacer el respaldo: " DescribirError(e))
}

; Respaldos del mas nuevo al mas viejo
ListaRespaldos() {
    arr := []
    if !DirExist(CARPETA_RESPALDOS)
        return arr
    txt := ""
    loop files CARPETA_RESPALDOS "\DeckLibre_*.ini"
        txt .= A_LoopFileName "`n"
    if (txt = "")
        return arr
    for nom in StrSplit(Sort(RTrim(txt, "`n"), "R"), "`n")
        arr.Push(CARPETA_RESPALDOS "\" nom)
    return arr
}

UltimoRespaldo() {
    lista := ListaRespaldos()
    return lista.Length ? lista[1] : ""
}

LimpiarRespaldos(cuantos) {
    lista := ListaRespaldos()
    while (lista.Length > cuantos)
        try FileDelete(lista.Pop())
}

ContarTeclas(ruta) {
    try
        sec := IniRead(ruta, "Teclas")
    catch
        return 0
    vistas := Map()
    loop parse sec, "`n", "`r"
        if RegExMatch(A_LoopField, "i)^sc([0-9a-f]+)_", &m)
            vistas[m[1]] := 1
    return vistas.Count
}

; Reemplaza la configuracion con otro archivo, conservando los teclados de este PC
RestaurarRespaldo(ruta) {
    HacerRespaldo(true)
    lap := IniRead(CFG, "General", "BotoneraHandle", "")
    ext := IniRead(CFG, "General", "PrincipalHandle", "")
    FileCopy(ruta, CFG, 1)
    IniWrite(lap, CFG, "General", "BotoneraHandle")
    IniWrite(ext, CFG, "General", "PrincipalHandle")
    RecargarConfigEnVivo()
}

RecargarConfigEnVivo() {
    global gCargandoNombre
    CargarConfig()
    AplicarSuscripciones()
    if gCfgGui {
        gCargandoNombre := true
        ui.edNombre.Value := (gSel && MapaEdit().Has(gSel)) ? MapaEdit()[gSel].nombre : ""
        gCargandoNombre := false
        RefrescarLV()
        PintarTeclas()
        HabilitarPanel()
        PintarInterruptores()
        LlenarPerfiles()
        ActualizarEstadoGui()
    }
}

ExportarConfig(*) {
    f := FileSelect("S16", A_Desktop "\DeckLibre_config.ini", "Exportar configuración", "Configuración (*.ini)")
    if (f = "")
        return
    if !RegExMatch(f, "i)\.ini$")
        f .= ".ini"
    FileCopy(CFG, f, 1)
    OSD("Configuración exportada", , "4ADE80", Chr(0xE73E))
}

ImportarConfig(*) {
    f := FileSelect(3, , "Importar configuración", "Configuración (*.ini)")
    if (f = "")
        return
    try
        IniRead(f, "Teclas")
    catch {
        MsgBox("Ese archivo no parece una configuración de DeckLibre.", APP, "Icon!")
        return
    }
    if (MsgBox("Esto reemplaza tus teclas actuales.`nAntes se guarda un respaldo.`n`n¿Continuar?", APP, "YesNo Icon?") != "Yes")
        return
    RestaurarRespaldo(f)
    OSD("Configuración importada", , "4ADE80", Chr(0xE73E))
}

AbrirRespaldos(*) {
    global gRespGui
    if gRespGui
        try gRespGui.Destroy()
    HacerRespaldo(true)
    lista := ListaRespaldos()
    d := Gui("-MinimizeBox -MaximizeBox", "Respaldos de DeckLibre")
    gRespGui := d
    d.BackColor := C_BG
    d.MarginX := 22, d.MarginY := 18
    BarraOscura(d)
    d.SetFont("s8 w700 c" C_MUTED, "Segoe UI")
    d.Add("Text", "xm w460 Background" C_BG, "RESPALDOS AUTOMÁTICOS")
    d.SetFont("s9 w400 c" C_MUTED)
    d.Add("Text", "xm y+4 w460 Background" C_BG, "Se guarda una copia cuando cambias algo (máximo una cada 10 minutos). Se conservan las últimas 10.")
    d.SetFont("s10 cE4E4E7")
    lv := d.Add("ListView", "xm y+12 w460 h220 -Multi NoSort NoSortHdr -E0x200 +LV0x10000 Background" C_PANEL, ["Fecha", "Teclas"])
    Tema(lv)
    for ruta in lista {
        SplitPath(ruta, &nom)
        fecha := RegExReplace(nom, "i)^\w+?_(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)\.ini$", "$3/$2/$1   $4:$5")
        lv.Add(, fecha, ContarTeclas(ruta) " teclas")
    }
    if !lista.Length
        lv.Add(, "Todavía no hay respaldos", "")
    lv.ModifyCol(1, 300)
    lv.ModifyCol(2, 130)
    d.SetFont("s10 w600")
    b1 := Boton(d, "xm y+14 w130 h32", "Restaurar", (*) => Restaurar(), true)
    d.SetFont("w400")
    b2 := Boton(d, "x+8 w130 h32", "Abrir carpeta", (*) => AbrirCarpetaRespaldos())
    b3 := Boton(d, "x+8 w100 h32", "Cerrar", (*) => Cerrar())

    Restaurar() {
        f := lv.GetNext(0)
        if (!f || !lista.Length) {
            MsgBox("Elige un respaldo de la lista.", APP, "Icon! Owner" d.Hwnd)
            return
        }
        if (MsgBox("¿Restaurar el respaldo del " lv.GetText(f, 1) "?`nTus teclas actuales se guardan antes en otro respaldo.", APP, "YesNo Icon? Owner" d.Hwnd) != "Yes")
            return
        RestaurarRespaldo(lista[f])
        Cerrar()
        OSD("Respaldo restaurado", , "4ADE80", Chr(0xE73E))
    }

    Cerrar(*) {
        global gRespGui
        for b in [b1, b2, b3]
            try gHoverMap.Delete(b.Hwnd)
        try d.Destroy()
        gRespGui := 0
    }

    d.OnEvent("Close", Cerrar)
    d.OnEvent("Escape", Cerrar)
    d.Show()
}

AbrirCarpetaRespaldos() {
    DirCreate(CARPETA_RESPALDOS)
    Run(CARPETA_RESPALDOS)
}

; =====================================================================
;  PASO DEL NOMBRE VIEJO (LaptopDeck) A DeckLibre
;  Se hace solo la primera vez que abres DeckLibre.ahk
; =====================================================================
MigrarNombreViejo() {
    ; 1) Cerrar la version vieja si sigue abierta (si no, las dos usarian el teclado)
    antes := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        for h in WinGetList("LaptopDeck.ahk ahk_class AutoHotkey")
            if (h != A_ScriptHwnd)
                WinClose(h)
    }
    DetectHiddenWindows(antes)

    ; 2) Configuracion y respaldos
    viejoIni := A_ScriptDir "\LaptopDeck.ini"
    if (!FileExist(CFG) && FileExist(viejoIni)) {
        Sleep(800)
        try FileMove(viejoIni, CFG)
        if DirExist(CARPETA_RESPALDOS) {
            loop files CARPETA_RESPALDOS "\LaptopDeck_*.ini"
                try FileMove(A_LoopFileFullPath, CARPETA_RESPALDOS "\DeckLibre_" SubStr(A_LoopFileName, 12), 1)
        }
        Registrar("Configuración pasada de LaptopDeck a DeckLibre", "INFO")
    }

    ; 3) Nombres nuevos de los teclados en el .ini
    if FileExist(CFG) {
        for par in [["BotoneraHandle", "LaptopHandle"], ["PrincipalHandle", "ExternoHandle"]] {
            v := IniRead(CFG, "General", par[2], "§")
            if (v != "§") {
                if (IniRead(CFG, "General", par[1], "§") = "§")
                    IniWrite(v, CFG, "General", par[1])
                try IniDelete(CFG, "General", par[2])
            }
        }
    }

    ; 4) Inicio con Windows: lo viejo apunta al archivo anterior
    if FileExist(A_Startup "\LaptopDeck.lnk")
        try FileDelete(A_Startup "\LaptopDeck.lnk")
    if (RunWait(A_ComSpec ' /c schtasks /Query /TN "LaptopDeck" >nul 2>&1', , "Hide") = 0)
        SetTimer(() => MigrarTareaVieja(), -4000)
}

MigrarTareaVieja() {
    if (MsgBox("El proyecto ahora se llama DeckLibre.`n`nEl inicio automático con Windows todavía apunta al nombre viejo. ¿Lo actualizo?`n(Windows te pedirá permiso una vez)", APP, "YesNo Iconi") != "Yes")
        return
    archivo := A_Temp "\DeckLibre_tarea.xml"
    try FileDelete(archivo)
    FileAppend(ArmarXmlTarea(), archivo, "UTF-16")
    try RunWait('*RunAs ' A_ComSpec ' /c schtasks /Delete /TN "LaptopDeck" /F & schtasks /Create /TN "DeckLibre" /XML "' archivo '" /F', , "Hide")
    try FileDelete(archivo)
    ActualizarCheckInicio()
}
