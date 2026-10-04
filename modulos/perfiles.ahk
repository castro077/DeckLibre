; =====================================================================
;  DeckLibre  ·  perfiles.ahk
;  Perfiles por programa: las teclas cambian segun la app que tengas al
;  frente. Lo que no configures en un perfil sigue haciendo lo de General.
; =====================================================================

NombrePerfil(p) => (p = "") ? "General" : NombreBonito(p)

MapaPerfil(p) => (p = "" || !gPerfiles.Has(p)) ? gKeys : gPerfiles[p]

; Mapa que se esta editando en el configurador
MapaEdit() => MapaPerfil(gEditPerfil)

TeclaEfectiva(sc) => gEfectivo.Has(sc) ? gEfectivo[sc] : 0

; General + lo que tenga el perfil activo encima
CalcularEfectivo() {
    global gEfectivo
    if (gPerfilActivo = "" || !gPerfiles.Has(gPerfilActivo)) {
        gEfectivo := gKeys
        return
    }
    m := Map()
    for sc, k in gKeys
        m[sc] := k
    for sc, k in gPerfiles[gPerfilActivo]
        if TieneAcciones(k)
            m[sc] := k
    gEfectivo := m
}

; Avisa cuando cambia la ventana activa (sin revisar a cada rato)
IniciarPerfiles() {
    static cb := 0, hook := 0
    if hook
        return
    cb := CallbackCreate(AlCambiarVentana, , 7)
    hook := DllCall("SetWinEventHook", "UInt", 0x0003, "UInt", 0x0003, "Ptr", 0, "Ptr", cb, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    if !hook
        SetTimer(RevisarPerfil, 500)                   ; plan B: revisar cada medio segundo
    RevisarPerfil()
}

AlCambiarVentana(hHook, evento, hwnd, idObj, idHijo, hilo, tiempo) {
    SetTimer(RevisarPerfil, -60)
}

RevisarPerfil() {
    global gPerfilActivo
    exe := ""
    try {
        if (WinGetPID("A") = DllCall("GetCurrentProcessId"))   ; el configurador no cambia el perfil
            return
        exe := StrLower(WinGetProcessName("A"))
    }
    nuevo := (exe != "" && gPerfiles.Has(exe)) ? exe : ""
    if (nuevo = gPerfilActivo)
        return
    gPerfilActivo := nuevo
    AplicarSuscripciones()
    if gCfgGui
        ActualizarEstadoGui()
    if (gModo = "botonera" && gPerfiles.Count)
        OSD("Perfil: " NombrePerfil(nuevo), , "A78BFA", Chr(0xE7F4), 900)
}

; ---------------- En el configurador ----------------
LlenarPerfiles() {
    global gEditPerfil
    if (!gCfgGui || !ui.HasOwnProp("chips"))
        return
    if (gEditPerfil != "" && !gPerfiles.Has(gEditPerfil))
        gEditPerfil := ""
    perfiles := []
    for p in gPerfiles
        perfiles.Push(p)
    items := [["", "General"]]
    conMenu := (perfiles.Length > 4)
    for i, p in perfiles
        if (!conMenu || i <= 3)
            items.Push([p, NombrePerfil(p)])
    visibleSel := false
    for it in items
        if (it[1] = gEditPerfil)
            visibleSel := true
    if conMenu
        items.Push(["*menu", visibleSel ? "Más perfiles  ▾" : NombrePerfil(gEditPerfil) "  ▾"])
    items.Push(["+nuevo", "+   Nuevo perfil"])
    ui.chipAccion := []
    for i, c in ui.chips {
        if (i > items.Length) {
            c.Visible := false
            continue
        }
        it := items[i]
        ui.chipAccion.Push(it[1])
        esSel := (it[1] = gEditPerfil && it[1] != "*menu") || (it[1] = "*menu" && !visibleSel)
        c.Visible := true
        c.Text := it[2]
        if (it[1] = "+nuevo") {
            c.Opt("Background" C_BG)
            c.SetFont("c93C5FD")
        } else if esSel {
            c.Opt("Background" C_ACC)
            c.SetFont("cFFFFFF")
        } else {
            c.Opt("Background" C_KEY)
            c.SetFont("c" C_KEYTXT)
        }
        c.Redraw()
    }
    SetActivo(ui.bQuitarPerfil, gEditPerfil != "")
}

ClicChip(i, *) {
    if (i > ui.chipAccion.Length)
        return
    accion := ui.chipAccion[i]
    if (accion = "+nuevo")
        NuevoPerfil()
    else if (accion = "*menu")
        MenuPerfiles()
    else
        ElegirPerfilEdit(accion)
}

MenuPerfiles() {
    m := Menu()
    m.Add("General", (*) => ElegirPerfilEdit(""))
    for p in gPerfiles
        m.Add(NombrePerfil(p) "   (" p ")", ElegirPerfilEdit.Bind(p))
    m.Show()
}

ElegirPerfilEdit(p, *) {
    global gEditPerfil
    gEditPerfil := p
    LlenarPerfiles()
    RefrescarEdicion()
}



RefrescarEdicion() {
    global gCargandoNombre
    mapa := MapaEdit()
    gCargandoNombre := true
    ui.edNombre.Value := (gSel && mapa.Has(gSel)) ? mapa[gSel].nombre : ""
    gCargandoNombre := false
    RefrescarLV()
    PintarTeclas()
    HabilitarPanel()
}

NuevoPerfil(*) {
    d := Gui("+Owner" gCfgGui.Hwnd " -MinimizeBox -MaximizeBox", "Nuevo perfil")
    gCfgGui.Opt("+Disabled")
    d.BackColor := C_BG
    d.MarginX := 22, d.MarginY := 18
    BarraOscura(d)
    d.SetFont("s8 w700 c" C_MUTED, "Segoe UI")
    d.Add("Text", "xm w340 Background" C_BG, "PROGRAMA (.exe)")
    d.SetFont("s10 w400 c" C_TXT)
    cb := d.Add("ComboBox", "xm w340 Background" C_KEY, ListaProcesos())
    Tema(cb, "DarkMode_CFD")
    d.SetFont("s9 c93C5FD")
    d.Add("Text", "xm y+12 w340 Background" C_BG, "Elige el programa. Las teclas que no configures en este perfil siguen haciendo lo de General.")
    d.SetFont("s10 w600")
    b1 := Boton(d, "xm y+14 w120 h32", "Crear", (*) => Crear(), true)
    d.SetFont("w400")
    b2 := Boton(d, "x+8 w100 h32", "Cancelar", (*) => Cerrar())
    d.Add("Button", "x0 y0 w0 h0 Default", "").OnEvent("Click", (*) => Crear())

    Crear() {
        global gEditPerfil
        exe := StrLower(Trim(cb.Text))
        if (exe = "")
            return
        if !RegExMatch(exe, "\.exe$")
            exe .= ".exe"
        if !gPerfiles.Has(exe)
            gPerfiles[exe] := Map()
        gEditPerfil := exe
        Cerrar()
        GuardarConfig()
        LlenarPerfiles()
        RefrescarEdicion()
        RevisarPerfil()
    }

    Cerrar(*) {
        for b in [b1, b2]
            try gHoverMap.Delete(b.Hwnd)
        gCfgGui.Opt("-Disabled")
        d.Destroy()
        WinActivate(gCfgGui.Hwnd)
    }

    d.OnEvent("Close", Cerrar)
    d.OnEvent("Escape", Cerrar)
    d.Show()
}

QuitarPerfil(*) {
    global gEditPerfil, gPerfilActivo
    if (gEditPerfil = "")
        return
    if (MsgBox("¿Quitar el perfil de " NombrePerfil(gEditPerfil) " con todas sus teclas?`nAntes se guarda un respaldo.", APP, "YesNo Icon? Owner" gCfgGui.Hwnd) != "Yes")
        return
    HacerRespaldo(true)
    gPerfiles.Delete(gEditPerfil)
    if (gPerfilActivo = gEditPerfil)
        gPerfilActivo := ""
    gEditPerfil := ""
    GuardarConfig()
    AplicarSuscripciones()
    LlenarPerfiles()
    RefrescarEdicion()
}
