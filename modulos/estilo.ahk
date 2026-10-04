; =====================================================================
;  DeckLibre  ·  estilo.ahk
;  Tema oscuro: botones planos, interruptores y efecto hover
; =====================================================================

; =====================================================================
;  ESTILO (tema oscuro)
; =====================================================================
Tema(ctrl, estilo := "DarkMode_Explorer") => DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", estilo, "Ptr", 0)

BarraOscura(g) {
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 20, "Int*", 1, "UInt", 4)
    try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "UInt", 19, "Int*", 1, "UInt", 4)
}

; Boton plano hecho con un Text (se ve igual en Windows 10 y 11)
Boton(g, opts, texto, fn, primario := false) {
    bg := primario ? "2563EB" : "34343A"
    fg := primario ? "FFFFFF" : "E4E4E7"
    c := g.Add("Text", opts " +0x200 +0x80 Center Background" bg, texto)
    c.SetFont("c" fg)
    c.OnEvent("Click", (ctl, *) => gApagados.Has(ctl.Hwnd) ? 0 : fn(ctl))
    gHoverMap[c.Hwnd] := {c: c, bg: bg, fg: fg, hov: primario ? "3B82F6" : "45454D"}
    return c
}

SetActivo(c, on) {
    info := gHoverMap[c.Hwnd]
    if on {
        if gApagados.Has(c.Hwnd)
            gApagados.Delete(c.Hwnd)
        c.Opt("Background" info.bg)
        c.SetFont("c" info.fg)
    } else {
        gApagados[c.Hwnd] := true
        c.Opt("Background27272A")
        c.SetFont("c52525B")
    }
    c.Redraw()
}

Seccion(g, y, texto) {
    g.SetFont("s8 w700 c" C_MUTED)
    g.Add("Text", "x20 y" y " w200 Background" C_BG, texto)
}

Leyenda(g, x, y, color, texto) {
    g.Add("Text", Format("x{} y{} w12 h12 Background{}", x, y + 3, color))
    g.SetFont("s9 w400 c" C_MUTED)
    g.Add("Text", Format("x{} y{} Background{}", x + 18, y, C_BG), texto)
}

Interruptor(g, x, y, texto, fn) {
    g.SetFont("s8 w700")
    p := g.Add("Text", Format("x{} y{} w44 h22 +0x200 +0x80 Center", x, y), "")
    g.SetFont("s10 w400 c" C_TXT)
    l := g.Add("Text", Format("x{} y{} h22 +0x200 Background{}", x + 54, y, C_BG), texto)
    p.OnEvent("Click", fn)
    l.OnEvent("Click", fn)
    return p
}

; Efecto al pasar el mouse por botones y teclas
AlMoverMouse(wParam, lParam, msg, hwnd) {
    global gHover, gTecHover
    ; teclado dibujado: resaltar la tecla que esta bajo el mouse
    if (gCfgGui && ui.HasOwnProp("picTec") && hwnd = ui.picTec.Hwnd)
        HoverTeclado(lParam & 0xFFFF, (lParam >> 16) & 0xFFFF)
    else if gTecHover {
        gTecHover := 0
        try DibujarTecladoGui()
    }
    if (hwnd = gHover)
        return
    ant := gHover
    gHover := hwnd
    if (ant && gHoverMap.Has(ant) && !gApagados.Has(ant)) {
        try {
            gHoverMap[ant].c.Opt("Background" gHoverMap[ant].bg)
            gHoverMap[ant].c.Redraw()
        }
    }
    if (gHoverMap.Has(hwnd) && !gApagados.Has(hwnd)) {
        try {
            gHoverMap[hwnd].c.Opt("Background" gHoverMap[hwnd].hov)
            gHoverMap[hwnd].c.Redraw()
        }
    }
}
