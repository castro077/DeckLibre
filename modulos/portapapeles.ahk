; =====================================================================
;  DeckLibre  ·  portapapeles.ahk
;  Historial del portapapeles (solo en memoria, no se guarda en disco)
;  y plantillas de texto con variables.
; =====================================================================

IniciarPortapapeles() {
    OnClipboardChange(AlCambiarPortapapeles)
    ; Teclas 1-9 para elegir rapido mientras el historial esta abierto
    HotIf(HistorialActivo)
    loop 9
        Hotkey(String(A_Index), PegarClipNumero.Bind(A_Index))
    HotIf()
}

HistorialActivo(*) => gClipGui && WinActive("ahk_id " gClipGui.Hwnd)

PegarClipNumero(n, *) => PegarClip(n)

AlCambiarPortapapeles(tipo) {
    global gClips
    if (tipo != 1 || A_TickCount < gIgnorarClip)
        return
    try
        t := A_Clipboard
    catch
        return
    if (Trim(t) = "" || StrLen(t) > 100000)
        return
    for i, c in gClips {
        if (c == t) {
            gClips.RemoveAt(i)
            break
        }
    }
    gClips.InsertAt(1, t)
    while (gClips.Length > 25)
        gClips.Pop()
}

; Pega un texto usando el portapapeles y luego deja el portapapeles como estaba
PegarTexto(t) {
    global gIgnorarClip
    respaldo := ClipboardAll()
    gIgnorarClip := A_TickCount + 1500
    A_Clipboard := t
    if !ClipWait(1) {
        A_Clipboard := respaldo
        return
    }
    Send("^v")
    Sleep(300)
    gIgnorarClip := A_TickCount + 800
    A_Clipboard := respaldo
}

ResumenClip(c) {
    t := Trim(RegExReplace(c, "\s+", " "))
    return StrLen(t) > 90 ? SubStr(t, 1, 90) "…" : t
}

MostrarHistorial(*) {
    global gClipGui, gClipDestino
    if gClipGui {
        CerrarHistorial()
        return
    }
    if !gClips.Length {
        OSD("El historial está vacío  ·  copia algo primero", , "FBBF24", Chr(0xE77F))
        return
    }
    gClipDestino := WinExist("A")
    d := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Portapapeles")
    gClipGui := d
    d.BackColor := C_BG
    d.MarginX := 16, d.MarginY := 14
    BarraOscura(d)
    d.SetFont("s8 w700 c" C_MUTED, "Segoe UI")
    d.Add("Text", "xm w540 Background" C_BG, "HISTORIAL DEL PORTAPAPELES    ·    Enter o el número para pegar    ·    Esc cierra")
    d.SetFont("s10 w400 cE4E4E7")
    lv := d.Add("ListView", "xm y+8 w540 h320 -Multi -Hdr NoSort NoSortHdr -E0x200 +LV0x10000 Background" C_PANEL, ["#", "Texto"])
    Tema(lv)
    for i, c in gClips
        lv.Add(, i <= 9 ? i : "", ResumenClip(c))
    lv.ModifyCol(1, 34)
    lv.ModifyCol(2, 486)
    lv.Modify(1, "Select Focus")
    d.Add("Button", "x0 y0 w0 h0 Default", "").OnEvent("Click", (*) => PegarClip(lv.GetNext(0)))
    lv.OnEvent("DoubleClick", (*) => PegarClip(lv.GetNext(0)))
    d.OnEvent("Escape", (*) => CerrarHistorial())
    d.OnEvent("Close", (*) => CerrarHistorial())

    ; en el centro de la pantalla donde estabas trabajando
    d.Show("Hide AutoSize")
    WinGetPos(, , &ww, &hh, d.Hwnd)
    n := gClipDestino ? MonitorDeVentana(gClipDestino) : 0
    if !n
        n := MonitorGetPrimary()
    MonitorGetWorkArea(n, &l, &t, &r, &b)
    d.Show("x" (l + (r - l - ww) // 2) " y" (t + (b - t - hh) // 2))
}

CerrarHistorial() {
    global gClipGui
    if gClipGui
        try gClipGui.Destroy()
    gClipGui := 0
}

PegarClip(idx) {
    if (!idx || idx > gClips.Length)
        return
    t := gClips[idx]
    CerrarHistorial()
    if gClipDestino
        try WinActivate(gClipDestino)
    Sleep(150)
    PegarTexto(t)
}

; Plantillas: {fecha} {hora} {dia} {mes} {año} {portapapeles} y {n} = salto de linea
ExpandirPlantilla(t) {
    clip := ""
    try clip := A_Clipboard
    t := StrReplace(t, "{fecha}", FormatTime(, "dd/MM/yyyy"))
    t := StrReplace(t, "{hora}", FormatTime(, "HH:mm"))
    t := StrReplace(t, "{dia}", FormatTime(, "dddd"))
    t := StrReplace(t, "{mes}", FormatTime(, "MMMM"))
    t := StrReplace(t, "{año}", FormatTime(, "yyyy"))
    t := StrReplace(t, "{portapapeles}", clip)
    t := StrReplace(t, "{n}", "`r`n")
    return t
}

EscribirPlantilla(a) {
    t := ExpandirPlantilla(a.p1)
    if InStr(a.p2, "Pegar")
        PegarTexto(t)
    else
        SendText(t)
}
