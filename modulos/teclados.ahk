; =====================================================================
;  DeckLibre  ·  teclados.ahk
;  Deteccion del teclado botonera y del teclado principal (con el que escribes)
; =====================================================================

; =====================================================================
;  DISPOSITIVOS
; =====================================================================
ResolverBotonera() {
    global gBotoneraId
    h := IniRead(CFG, "General", "BotoneraHandle", "")
    gBotoneraId := 0
    if (h != "")
        try gBotoneraId := AHI.Instance.GetDeviceIdFromHandle(false, h, 1)
}

ListaTeclados() {
    lista := []
    for id, d in AHI.GetDeviceList()
        if !d.IsMouse
            lista.Push({id: id, h: d.Handle})
    return lista
}

PrincipalPresente() {
    if (gPrincipalHandle = "")
        return 0
    for t in ListaTeclados()
        if (t.h = gPrincipalHandle)
            return 1
    return 0
}

RevisarPrincipal() {
    global gPrincipalPresente
    if (gPrincipalHandle = "" || gCapturando)
        return
    p := PrincipalPresente()
    if (p = gPrincipalPresente)
        return
    primera := (gPrincipalPresente = -1)
    gPrincipalPresente := p
    if !primera {
        ResolverBotonera()        ; por si los IDs se movieron al conectar/desconectar
        AplicarSuscripciones()
    }
    if gAuto
        SetModo(p ? "botonera" : "normal", !primera)
    ActualizarEstadoGui()
}

; Pide presionar una tecla y detecta de que teclado vino
DetectarTeclado(cual, alTerminar := 0) {
    global gCapturando, gDetect
    gCapturando := true
    AplicarSuscripciones()   ; con gCapturando = true solo quita todo
    ids := []
    for t in ListaTeclados() {
        try {
            AHI.SubscribeKeyboard(t.id, false, DetectCb.Bind(t.id, t.h, cual))
            ids.Push(t.id)
        }
    }
    gDetect := {ids: ids, hecho: false, fin: alTerminar}
    ToolTip("Presiona cualquier tecla del teclado " (cual = "botonera" ? "BOTONERA (el que usarás para las acciones)" : "PRINCIPAL (con el que escribes)") "...`n(tienes 10 segundos)")
    SetTimer(DetectTimeout, -10000)
}

DetectCb(id, handle, cual, code, state) {
    if (!gDetect || gDetect.hecho)
        return
    gDetect.hecho := true
    SetTimer(DetectFin.Bind(id, handle, cual), -1)
}

DetectSoltar() {
    global gCapturando
    for i in gDetect.ids
        try AHI.UnsubscribeKeyboard(i)
    SetTimer(DetectTimeout, 0)
    ToolTip()
    gCapturando := false
}

DetectFin(id, handle, cual) {
    global gBotoneraId, gPrincipalHandle, gPrincipalPresente
    DetectSoltar()
    if (cual = "botonera") {
        gBotoneraId := id
        IniWrite(handle, CFG, "General", "BotoneraHandle")
        if (handle = gPrincipalHandle)
            gPrincipalHandle := ""
    } else {
        if (id = gBotoneraId) {
            MsgBox("Esa tecla vino del teclado botonera, no del principal. Intenta de nuevo.", APP, "Icon!")
        } else {
            gPrincipalHandle := handle
            gPrincipalPresente := -1
        }
    }
    GuardarConfig()
    AplicarSuscripciones()
    LlenarDispositivos()
    ActualizarEstadoGui()
    if gDetect.fin
        gDetect.fin.Call()
}

DetectTimeout() {
    DetectSoltar()
    AplicarSuscripciones()
    OSD("No se detectó ninguna tecla", , "FBBF24", Chr(0xE765))
}

; Windows avisa cuando se conecta o desconecta un dispositivo (DBT_DEVNODES_CHANGED = 7).
; Asi no hay que revisar a cada rato (antes era cada 3 segundos).
AlCambiarDispositivos(wParam, *) {
    if (wParam = 7)
        SetTimer(RevisarPrincipalUnaVez, -1500)
}

RevisarPrincipalUnaVez() => RevisarPrincipal()
