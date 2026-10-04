; =====================================================================
;  DeckLibre  ·  interfaz.ahk
;  Ventana de configuracion: teclado dibujado con iconos, galeria de
;  acciones, formulario de cada accion y ventana de ajustes.
; =====================================================================

; ---------------- Etiquetas de teclas ----------------
EtiquetaChar(sc) {
    n := GetKeyName(Format("sc{:03X}", sc))
    return StrLen(n) = 1 ? StrUpper(n) : n
}

KeyLabel(sc) => ETIQ.Has(sc) ? ETIQ[sc] : EtiquetaChar(sc)

EtiquetaCorta(sc) => (ui.HasOwnProp("cortas") && ui.cortas.Has(sc)) ? ui.cortas[sc] : KeyLabel(sc)

TextoDispositivo(t) => "ID " t.id "   " t.h (InStr(t.h, "ACPI") ? "   (integrado)" : "")

; ---------------- Tipos: nombre, icono y color ----------------
TipoNombre(id) {
    for t in TIPOS
        if (t.id = id)
            return t.n
    return id
}

TipoIndice(id) {
    for i, t in TIPOS
        if (t.id = id)
            return i
    return 1
}

CortoTipo(id) => VISUAL.Has(id) ? VISUAL[id][3] : TipoNombre(id)

IconoTipo(id) => Chr(VISUAL.Has(id) ? VISUAL[id][2] : 0xE945)

CategoriaTipo(id) => VISUAL.Has(id) ? VISUAL[id][1] : "pantalla"

ColorTipo(id) {
    cat := CategoriaTipo(id)
    for c in CATEGORIAS
        if (c.id = cat)
            return c.color
    return 0xFFA78BFA
}

NombreCategoria(id) {
    cat := CategoriaTipo(id)
    for c in CATEGORIAS
        if (c.id = cat)
            return c.n
    return ""
}

HexColor(argb) => Format("{:06X}", argb & 0xFFFFFF)

Describir(a) {
    switch a.t {
        case "volgen":  return (SubStr(Delta(a.p1), 1, 1) = "-" ? "Bajar " : "Subir ") SubStr(Delta(a.p1), 2) "%"
        case "volapp":  return a.p1 "  -  " (SubStr(Delta(a.p2), 1, 1) = "-" ? "bajar " : "subir ") SubStr(Delta(a.p2), 2) "%"
        case "muteapp": return a.p1
        case "abrir":   return NombreAppDe(a.p1) (IsNumber(a.p2) && a.p2 > 0 ? "   →  pantalla " a.p2 : "")
        case "media":   return a.p1
        case "atajo":   return a.p1 (a.p2 != "" ? "   →  " a.p2 : "")
        case "texto":   return a.p1 (InStr(a.p2, "Pegar") ? "   (pegar)" : "")
        case "esperar": return a.p1 " ms"
        case "ventana": return (IsNumber(a.p1) ? "A la pantalla " a.p1 : "A la siguiente pantalla")
        case "salida":  return a.p1 = "" ? "Siguiente (todas)" : a.p1
        case "hoja":    return "Mantener para ver  ·  " (a.p1 = "" ? "Donde está el mouse" : a.p1)
        case "sonido":  return a.p1 "  ·  " (a.p2 = "" ? "80" : a.p2) "%" (a.p3 = "No" ? "  ·  solo para ellos" : "")
        case "recursos": return "Pantalla " (a.p1 = "" ? "1" : a.p1) "  ·  " (a.p2 = "" ? "Arriba derecha" : a.p2)
        case "acomodar", "sistema", "edicion": return a.p1
        case "espacio":  return (InStr(a.p2, "Guardar") ? "Guardar  ·  " : "Restaurar  ·  ") a.p1
        case "temporizador": return a.p1 (IsNumber(a.p2) && !InStr(a.p1, "Detener") && !InStr(a.p1, "Pausar") && !InStr(a.p1, "Cronómetro") ? "  ·  " a.p2 " min" : "")
        case "reloj", "calendario", "notas": return "Pantalla " (a.p1 = "" ? "1" : a.p1) "  ·  " (a.p2 = "" ? "Arriba derecha" : a.p2) (a.t = "reloj" && InStr(a.p3, "12") ? "  ·  12 h" : "")
        case "micwidget": return "Solo se ve si está silenciado  ·  " (a.p2 = "" ? "Arriba centro" : a.p2)
        case "clima":    return (a.p1 = "" ? "(sin ciudad)" : a.p1) "  ·  pantalla " (a.p2 = "" ? "1" : a.p2)
        case "brillo":   return (SubStr(a.p1, 1, 1) = "-" ? "Bajar " SubStr(a.p1, 2) : SubStr(a.p1, 1, 1) = "+" ? "Subir " SubStr(a.p1, 2) : "Poner en " a.p1) "%"
        default:        return ""
    }
}

; =====================================================================
;  VENTANA PRINCIPAL
; =====================================================================
AbrirConfig(*) {
    if !gCfgGui
        ConstruirGui()
    LlenarPerfiles()
    ActualizarEstadoGui()
    gCfgGui.Show()
    PintarTeclas()
}

ConstruirGui() {
    global gCfgGui, ui
    g := Gui("-MaximizeBox", "DeckLibre")
    gCfgGui := g
    g.BackColor := C_BG
    g.MarginX := 24, g.MarginY := 18
    g.OnEvent("Close", (*) => gCfgGui.Hide())
    BarraOscura(g)
    ui := {cortas: Map(), rects: Map(), chips: [], chipAccion: [], aj: 0}
    X0 := 24, ANCHO := Round(19.5 * U)

    ; --- Encabezado ---
    g.SetFont("s20 w400 cFFFFFF", "Segoe MDL2 Assets")
    g.Add("Text", "x24 y16 w50 h50 +0x200 Center Background" C_ACC, Chr(0xE765))
    g.SetFont("s19 w700 c" C_TXT, "Segoe UI")
    g.Add("Text", "x88 y12 w400 Background" C_BG, "DeckLibre")
    g.SetFont("s9 w400 c" C_MUTED)
    g.Add("Text", "x90 y48 w420 Background" C_BG, "Haz clic en una tecla y dale superpoderes")
    g.SetFont("s10 w700")
    ui.pillModo := g.Add("Text", "x" (X0 + ANCHO - 300) " y22 w188 h38 +0x200 +0x80 Center", "")
    ui.pillModo.OnEvent("Click", AlternarModo)
    g.SetFont("s10 w600")
    Boton(g, "x" (X0 + ANCHO - 104) " y22 w104 h38", "Ajustes", AbrirAjustes)

    ; --- Perfiles (chips) ---
    y := 86
    g.SetFont("s8 w700 c" C_MUTED)
    g.Add("Text", "x24 y" y " w60 +0x80 Background" C_BG, "PERFIL")
    g.SetFont("s9 w400 c" C_MUTED)
    g.Add("Text", "x84 y" (y - 1) " w" (ANCHO - 60) " +0x80 +0x4000 Background" C_BG, "Las teclas pueden cambiar según la app que tengas al frente")
    y += 20
    g.SetFont("s9 w600")
    loop 6 {
        c := g.Add("Text", Format("x{} y{} w110 h30 +0x200 +0x80 +0x4000 Center Background{}", X0 + (A_Index - 1) * 116, y, C_KEY), "")
        c.OnEvent("Click", ClicChip.Bind(A_Index))
        ui.chips.Push(c)
    }
    g.SetFont("s9 w400")
    ui.bQuitarPerfil := Boton(g, "x" (X0 + ANCHO - 120) " y" y " w120 h30", "Quitar perfil", QuitarPerfil)

    ; --- Ayuda y colores ---
    y += 46
    g.SetFont("s9 w400 c" C_MUTED)
    ui.lblHint := g.Add("Text", "x24 y" y " w330 +0x80 +0x4000 Background" C_BG, "Pasa el mouse sobre una tecla para ver qué hace")
    lx := X0 + ANCHO - 504
    for i, cat in CATEGORIAS {
        Leyenda(g, lx, y, HexColor(cat.color), cat.corto)
        lx += [70, 128, 126, 82, 98][i]
    }

    ; --- Teclado dibujado (una sola imagen, se redibuja al cambiar algo) ---
    y += 26
    ui.tecW := ANCHO, ui.tecH := 6 * U
    ui.picTec := g.Add("Text", Format("x{} y{} w{} h{} +0xE", X0, y, ANCHO, 6 * U))
    ui.picTec.OnEvent("Click", ClicTeclado)
    for fila in FILAS
        for k in fila
            ui.cortas[k[1]] := (k.Length >= 3) ? k[3] : EtiquetaChar(k[1])
    for k in NUMPAD
        ui.cortas[k[1]] := k[6]

    ; --- Tecla seleccionada ---
    y += 6 * U + 14
    g.Add("Text", "x24 y" y " w" ANCHO " h1 Background" C_LINE)
    y += 18
    g.SetFont("s24 w400 c" C_MUTED, "Segoe MDL2 Assets")
    ui.preview := g.Add("Text", Format("x24 y{} w66 h66 +0x200 Center Background{}", y, C_KEY), Chr(0xE710))
    g.SetFont("s15 w700 c" C_TXT, "Segoe UI")
    ui.lblTecla := g.Add("Text", "x106 y" (y - 2) " w380 h30 +0x200 +0x80 Background" C_BG, "Elige una tecla del dibujo")
    g.SetFont("s10 w400 c" C_TXT)
    ui.edNombre := g.Add("Edit", "x106 y" (y + 36) " w380 h28 -E0x200 Background" C_KEY)
    SendMessage(0x1501, 1, StrPtr("Ponle un nombre (opcional)"), ui.edNombre)   ; texto de ejemplo
    ui.edNombre.OnEvent("Change", CambioNombre)
    g.SetFont("s10 w400")
    Boton(g, "x" (X0 + ANCHO - 190) " y" (y - 1) " w190 h30", "Capturar tecla", CapturarTecla)
    g.SetFont("s10 w600")
    ui.bTest := Boton(g, "x" (X0 + ANCHO - 190) " y" (y + 35) " w190 h32", "▶   Probar", (*) => ProbarTecla(), true)

    ; --- Pestañas: toque / mantener / doble toque ---
    y += 84
    g.SetFont("s9 w600")
    ui.tabs := Map()
    for i, par in [["acciones", "Toque"], ["mantener", "Mantener"], ["doble", "Doble toque"]] {
        c := g.Add("Text", Format("x{} y{} w150 h30 +0x200 +0x80 Center Background{}", X0 + (i - 1) * 156, y, C_KEY), par[2])
        c.OnEvent("Click", CambiarLista.Bind(par[1]))
        ui.tabs[par[1]] := c
    }
    g.SetFont("s9 w400 c" C_MUTED)
    g.Add("Text", "x" (X0 + 480) " y" (y + 7) " w" (ANCHO - 480) " Right Background" C_BG, "Mantener = 0.4 s   ·   Doble = dos toques rápidos")

    y += 40
    g.SetFont("s10 cE4E4E7", "Segoe UI")
    ui.lv := g.Add("ListView", "x24 y" y " w" ANCHO " h128 -Multi -Hdr -E0x200 +LV0x10000 Background" C_PANEL, ["Acción", "Detalle"])
    Tema(ui.lv)
    ui.lv.ModifyCol(1, 230)
    ui.lv.ModifyCol(2, ANCHO - 250)
    ui.lv.OnEvent("DoubleClick", (*) => BotonEditar())

    y += 140
    g.SetFont("s10 w600")
    ui.bAdd := Boton(g, "x24 y" y " w220 h40", "+   Agregar acción", (*) => EditarAccion(0), true)
    g.SetFont("w400")
    ui.bEdit := Boton(g, "x252 y" y " w100 h40", "Editar", (*) => BotonEditar())
    ui.bDel := Boton(g, "x360 y" y " w100 h40", "Quitar", BotonQuitar)
    ui.bUp := Boton(g, "x468 y" y " w46 h40", "↑", (*) => MoverAccion(-1))
    ui.bDown := Boton(g, "x520 y" y " w46 h40", "↓", (*) => MoverAccion(1))

    y += 54
    g.SetFont("s9 c" C_MUTED)
    ui.lblInfo := g.Add("Text", "x24 y" y " w" ANCHO " +0x80 +0x4000 Background" C_BG, "")

    OnMessage(0x200, AlMoverMouse)
    RefrescarLV()
    HabilitarPanel()
}

ActualizarEstadoGui() {
    if !gCfgGui
        return
    if (gModo = "botonera") {
        ui.pillModo.Opt("Background1D3A6B")
        ui.pillModo.SetFont("c93C5FD")
        ui.pillModo.Text := "●   MODO BOTONERA"
    } else {
        ui.pillModo.Opt("Background4A3410")
        ui.pillModo.SetFont("cFCD34D")
        ui.pillModo.Text := "●   MODO NORMAL"
    }
    ui.pillModo.Redraw()
    ext := (gPrincipalHandle = "") ? "sin teclado principal configurado" : (PrincipalPresente() ? "teclado principal conectado" : "teclado principal no detectado")
    lap := gBotoneraId ? "botonera = ID " gBotoneraId : "botonera sin detectar"
    ui.lblInfo.Text := lap "   ·   " ext "   ·   perfil activo: " NombrePerfil(gPerfilActivo) "   ·   " (A_IsAdmin ? "como administrador" : "sin permisos de admin") "   ·   Ctrl+Alt+F12 cambia el modo"
}

; ---------------- Teclado dibujado ----------------
PintarTeclas() {
    DibujarTecladoGui()
    ActualizarPreview()
}

DibujarTecladoGui() {
    if (!gCfgGui || !ui.HasOwnProp("picTec"))
        return
    GdipIniciar()
    s := A_ScreenDPI / 96
    W := Round(ui.tecW * s), H := Round(ui.tecH * s)
    bmp := 0, gfx := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", W, "Int", H, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &bmp)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", &gfx)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", gfx, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", gfx, "Int", 2)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", gfx, "Int", 4)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0xFF18181B)
    fo := Fuentes(s)
    mapa := MapaEdit()
    ui.rects := Map()
    fy := 0
    for fila in FILAS {
        acc := 0
        for k in fila {
            DibujarTecla(gfx, fo, mapa, k[1], acc * U * s, fy * U * s, (k[2] * U - GAP) * s, (U - GAP) * s, s)
            acc += k[2]
        }
        fy += 1
    }
    for k in NUMPAD
        DibujarTecla(gfx, fo, mapa, k[1], (15.5 + k[2]) * U * s, k[3] * U * s, (k[4] * U - GAP) * s, (k[5] * U - GAP) * s, s)
    hbm := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", bmp, "Ptr*", &hbm, "UInt", 0xFF18181B)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", gfx)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", bmp)
    viejo := SendMessage(0x172, 0, hbm, ui.picTec)          ; STM_SETIMAGE
    if viejo
        DllCall("DeleteObject", "Ptr", viejo)
    if (SendMessage(0x173, 0, 0, ui.picTec) != hbm)         ; el control hizo su propia copia
        DllCall("DeleteObject", "Ptr", hbm)
}

DibujarTecla(gfx, fo, mapa, sc, x, y, w, h, s) {
    ui.rects[sc] := [x, y, w, h]
    k := (mapa.Has(sc) && TieneAcciones(mapa[sc])) ? mapa[sc] : 0
    heredada := false
    if (!k && gEditPerfil != "" && gKeys.Has(sc) && TieneAcciones(gKeys[sc])) {
        k := gKeys[sc]
        heredada := true
    }
    sel := (sc = gSel), hov := (sc = gTecHover)
    r := 7 * s
    alto := h - 4 * s

    ; base oscura: da la sensacion de tecla de verdad
    ruta := RutaRedondeada(x + 1, y + 3 * s, w - 2, h - 3 * s, r)
    br := Pincel(0xFF0C0C0E)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)

    ; cara de la tecla
    ruta := RutaRedondeada(x + 1, y + 1, w - 2, alto, r)
    br := Pincel(hov ? 0xFF37373F : 0xFF29292F)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    if k {
        col := ColorTipo(PrimeraAccion(k).t), rgb := col & 0xFFFFFF
        br := Pincel(((heredada ? 0x12 : (hov ? 0x4A : 0x36)) << 24) | rgb)
        DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
        BorrarPincel(br)
        pe := Lapiz(((heredada ? 0x45 : 0xC0) << 24) | rgb, 1.4 * s)
    } else
        pe := Lapiz(0x18FFFFFF, 1)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    if sel {
        pe := Lapiz(0xFFFFFFFF, 2.2 * s)
        DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
        BorrarLapiz(pe)
    }
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)

    if k {
        ; icono de la accion + letra chiquita arriba a la izquierda
        DibujarTexto(gfx, IconoTipo(PrimeraAccion(k).t), x, y + 4 * s, w, alto - 2 * s, fo.ico, heredada ? (0x90000000 | rgb) : (sel ? 0xFFFFFFFF : col), fo.cen)
        DibujarTexto(gfx, EtiquetaCorta(sc), x + 5 * s, y + 2 * s, w - 8 * s, 12 * s, fo.mini, heredada ? 0x80FFFFFF : 0xC8FFFFFF, fo.izq)
        ; puntitos abajo a la derecha: mantener / doble toque
        dx := x + w - 9 * s
        for lista in [k.doble, k.mantener] {
            if lista.Length {
                br := Pincel(0xE6FFFFFF)
                DllCall("gdiplus\GdipFillEllipse", "Ptr", gfx, "Ptr", br, "Float", dx, "Float", y + alto - 7 * s, "Float", 4 * s, "Float", 4 * s)
                BorrarPincel(br)
                dx -= 6 * s
            }
        }
    } else {
        DibujarTexto(gfx, EtiquetaCorta(sc), x, y, w, alto, fo.tecla, sel ? 0xFFFFFFFF : (hov ? 0xFFE4E4E7 : 0xFF8B8B93), fo.cen)
    }
}

TeclaEnPunto(x, y) {
    for sc, rc in ui.rects
        if (x >= rc[1] && x < rc[1] + rc[3] && y >= rc[2] && y < rc[2] + rc[4])
            return sc
    return 0
}

ClicTeclado(*) {
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "Ptr", pt)
    DllCall("ScreenToClient", "Ptr", ui.picTec.Hwnd, "Ptr", pt)
    sc := TeclaEnPunto(NumGet(pt, 0, "Int"), NumGet(pt, 4, "Int"))
    if sc
        SeleccionarTecla(sc)
}

HoverTeclado(x, y) {
    global gTecHover
    sc := TeclaEnPunto(x, y)
    if (sc = gTecHover)
        return
    gTecHover := sc
    DibujarTecladoGui()
    if sc
        MostrarHint(sc)
}

ActualizarPreview() {
    if (!gCfgGui || !ui.HasOwnProp("preview"))
        return
    mapa := MapaEdit()
    k := (gSel && mapa.Has(gSel) && TieneAcciones(mapa[gSel])) ? mapa[gSel] : 0
    if k {
        t := PrimeraAccion(k).t
        ui.preview.SetFont("c" HexColor(ColorTipo(t)))
        ui.preview.Text := IconoTipo(t)
    } else {
        ui.preview.SetFont("c" C_MUTED)
        ui.preview.Text := Chr(0xE710)
    }
}

MostrarHint(sc) {
    t := KeyLabel(sc)
    mapa := MapaEdit()
    k := 0, heredada := false
    if (mapa.Has(sc) && TieneAcciones(mapa[sc]))
        k := mapa[sc]
    else if (gEditPerfil != "" && gKeys.Has(sc) && TieneAcciones(gKeys[sc]))
        k := gKeys[sc], heredada := true
    if k {
        n := k.acciones.Length
        t .= "   ·   " (k.nombre != "" ? k.nombre : CortoTipo(PrimeraAccion(k).t)) (n > 1 ? "   ·   " n " acciones" : "")
        t .= (k.mantener.Length ? "   ·   + mantener" : "") (k.doble.Length ? "   ·   + doble" : "")
        t .= heredada ? "   ·   (de General)" : ""
    } else
        t .= "   ·   libre, dale clic para configurarla"
    ui.lblHint.Text := t
}

; ---------------- Tecla seleccionada ----------------
SeleccionarTecla(sc) {
    global gSel, gCargandoNombre
    gSel := sc
    ui.lblTecla.Text := "Tecla  " KeyLabel(sc)
    mapa := MapaEdit()
    gCargandoNombre := true
    ui.edNombre.Value := mapa.Has(sc) ? mapa[sc].nombre : ""
    gCargandoNombre := false
    RefrescarLV()
    PintarTeclas()
    HabilitarPanel()
}

RefrescarLV(seleccion := 0) {
    ui.lv.Delete()
    lista := ListaActual()
    for a in lista
        ui.lv.Add(, CortoTipo(a.t), Describir(a))
    if (!lista.Length && gSel)
        ui.lv.Add(, "Sin acciones todavía", "Dale  “+ Agregar acción”  para elegir qué hace esta tecla")
    if (seleccion && seleccion <= lista.Length)
        ui.lv.Modify(seleccion, "Select Focus")
    PintarTabs()
}

HabilitarPanel() {
    tiene := ListaActual().Length
    SetActivo(ui.bAdd, !!gSel)
    for c in [ui.bEdit, ui.bDel, ui.bUp, ui.bDown, ui.bTest]
        SetActivo(c, !!tiene)
}

CambioNombre(*) {
    mapa := MapaEdit()
    if (gCargandoNombre || !gSel || !mapa.Has(gSel))
        return
    mapa[gSel].nombre := ui.edNombre.Value
    SetTimer(GuardarConfig, -600)
}

BotonEditar() {
    f := ui.lv.GetNext(0)
    if (f && f <= ListaActual().Length)
        EditarAccion(f)
}

BotonQuitar(*) {
    f := ui.lv.GetNext(0)
    mapa := MapaEdit()
    if (!f || !mapa.Has(gSel) || f > ListaActual().Length)
        return
    ListaActual().RemoveAt(f)
    if !TieneAcciones(mapa[gSel])
        mapa.Delete(gSel)
    TrasCambio()
}

MoverAccion(dir) {
    f := ui.lv.GetNext(0)
    if (!f || !MapaEdit().Has(gSel))
        return
    acc := ListaActual()
    n := f + dir
    if (f > acc.Length || n < 1 || n > acc.Length)
        return
    tmp := acc[f], acc[f] := acc[n], acc[n] := tmp
    TrasCambio(n)
}

TrasCambio(sel := 0) {
    GuardarConfig()
    AplicarSuscripciones()
    RefrescarLV(sel)
    PintarTeclas()
    HabilitarPanel()
}

ListaActual() => (gSel && MapaEdit().Has(gSel)) ? ListaDe(MapaEdit()[gSel], gLista) : []

ProbarTecla() {
    mapa := MapaEdit()
    if (gSel && mapa.Has(gSel))
        EjecutarLista(gSel, gLista, mapa[gSel])
}

CambiarLista(cual, *) {
    global gLista
    gLista := cual
    RefrescarLV()
    HabilitarPanel()
}

PintarTabs() {
    if (!gCfgGui || !ui.HasOwnProp("tabs"))
        return
    for cual, c in ui.tabs {
        n := (gSel && MapaEdit().Has(gSel)) ? ListaDe(MapaEdit()[gSel], cual).Length : 0
        sel := (cual = gLista)
        c.Opt("Background" (sel ? C_ACC : C_KEY))
        c.SetFont("c" (sel ? "FFFFFF" : C_KEYTXT))
        c.Text := NombreLista(cual) (n ? "  (" n ")" : "")
        c.Redraw()
    }
}

; ---------------- Capturar una tecla presionandola en la botonera ----------------
CapturarTecla(*) {
    global gCapturando, gCaptura
    if !gBotoneraId {
        MsgBox("Primero detecta el teclado botonera (en Ajustes).", APP, "Icon!")
        return
    }
    gCapturando := true
    AplicarSuscripciones()
    gCaptura := {hecho: false}
    AHI.SubscribeKeyboard(gBotoneraId, true, CapturaCb)
    ui.lblTecla.Text := "Presiona una tecla en la botonera..."
    SetTimer(CapturaTimeout, -8000)
}

CapturaCb(code, state) {
    if (state != 1 || !gCaptura || gCaptura.hecho)
        return
    gCaptura.hecho := true
    SetTimer(CapturaFin.Bind(code), -1)
}

CapturaSoltar() {
    global gCapturando
    try AHI.UnsubscribeKeyboard(gBotoneraId)
    SetTimer(CapturaTimeout, 0)
    gCapturando := false
    AplicarSuscripciones()
}

CapturaFin(code) {
    CapturaSoltar()
    SeleccionarTecla(code)
}

CapturaTimeout() {
    CapturaSoltar()
    ui.lblTecla.Text := gSel ? "Tecla  " KeyLabel(gSel) : "Elige una tecla del dibujo"
}

; =====================================================================
;  GALERIA DE ACCIONES (paso 1) Y FORMULARIO (paso 2)
; =====================================================================
EditarAccion(fila) {
    if !gSel
        return
    if fila {
        a := ListaActual()[fila]
        FormularioAccion(fila, a.t, a)
    } else
        GaleriaAcciones(0)
}

GaleriaAcciones(fila, previo := 0) {
    d := Gui("+Owner" gCfgGui.Hwnd " -MinimizeBox -MaximizeBox", "Elegir acción  ·  tecla " KeyLabel(gSel))
    gCfgGui.Opt("+Disabled")
    d.BackColor := C_BG
    d.MarginX := 24, d.MarginY := 18
    BarraOscura(d)
    controles := []

    Cerrar(seguir := false) {
        for ctl in controles
            try gHoverMap.Delete(ctl.Hwnd)
        if !seguir
            gCfgGui.Opt("-Disabled")
        d.Destroy()
        if !seguir
            WinActivate(gCfgGui.Hwnd)
    }

    Elegir(id, *) {
        Cerrar(true)
        FormularioAccion(fila, id, previo)
    }

    TW := 104, TH := 60, SEP := 8, COLS := 9
    anchoTotal := COLS * TW + (COLS - 1) * SEP
    cuando := (gLista = "mantener") ? "al mantenerla presionada" : (gLista = "doble") ? "al tocarla dos veces" : "al tocarla"
    d.SetFont("s16 w700 c" C_TXT, "Segoe UI")
    d.Add("Text", "x24 y16 w" anchoTotal " Background" C_BG, "¿Qué hará la tecla " KeyLabel(gSel) "?")
    d.SetFont("s9 w400 c" C_MUTED)
    d.Add("Text", "x24 y52 w" anchoTotal " Background" C_BG, "Elige una acción para " cuando ". Después ajustas los detalles.")
    y := 88
    for cat in CATEGORIAS {
        deCat := []                                     ; ojo: "tipos" chocaria con TIPOS
        for t in TIPOS
            if (CategoriaTipo(t.id) = cat.id)
                deCat.Push(t)
        if !deCat.Length
            continue
        hex := HexColor(cat.color)
        d.Add("Text", Format("x24 y{} w10 h10 Background{}", y + 4, hex))
        d.SetFont("s9 w700 c" hex, "Segoe UI")
        d.Add("Text", Format("x42 y{} w400 Background{}", y, C_BG), StrUpper(cat.n))
        y += 24
        for i, t in deCat {
            tx := 24 + Mod(i - 1, COLS) * (TW + SEP)
            ty := y + ((i - 1) // COLS) * (TH + 40)
            d.SetFont("s20 w400 c" hex, "Segoe MDL2 Assets")
            c := d.Add("Text", Format("x{} y{} w{} h{} +0x200 Center Background2A2A30", tx, ty, TW, TH), IconoTipo(t.id))
            c.OnEvent("Click", Elegir.Bind(t.id))
            gHoverMap[c.Hwnd] := {c: c, bg: "2A2A30", fg: hex, hov: "3A3A44"}
            controles.Push(c)
            d.SetFont("s8 w600 cE4E4E7", "Segoe UI")
            lb := d.Add("Text", Format("x{} y{} w{} h34 Center Background{}", tx, ty + TH + 5, TW, C_BG), CortoTipo(t.id))
            lb.OnEvent("Click", Elegir.Bind(t.id))
        }
        y += Ceil(deCat.Length / COLS) * (TH + 40) + 6
    }
    d.SetFont("s10 w400", "Segoe UI")
    controles.Push(Boton(d, Format("x{} y{} w120 h34", 24 + anchoTotal - 120, y + 2), "Cancelar", (*) => Cerrar()))
    d.OnEvent("Close", (*) => Cerrar())
    d.OnEvent("Escape", (*) => Cerrar())
    d.Show()
}

ValoresPorDefecto(id) {
    switch id {
        case "volgen":       return ["+5", "", ""]
        case "brillo":       return ["+10", "", ""]
        case "volapp":       return ["", "+5", ""]
        case "abrir":        return ["", "0", "Traer al frente"]
        case "salida":       return ["Siguiente (todas)", "", ""]
        case "texto":        return ["", "Pegar (rápido)", ""]
        case "acomodar":     return ["Mitad izquierda", "", ""]
        case "espacio":      return ["", "Restaurar", ""]
        case "temporizador": return ["Pomodoro (25 / 5)", "25", "Arriba centro"]
        case "reloj":        return ["1", "Arriba derecha", "24 horas"]
        case "calendario":   return ["1", "Arriba derecha", ""]
        case "notas":        return ["1", "Arriba derecha", "Sí"]
        case "micwidget":    return ["1", "Arriba centro", ""]
        case "clima":        return ["", "1", "Arriba derecha"]
        case "sonido":       return ["", "80", "Sí"]
        case "hoja":         return ["Donde está el mouse", "", ""]
        case "recursos":     return ["1", "Arriba derecha", ""]
        case "ventana":      return ["Siguiente pantalla", "", ""]
        case "media":        return ["Play/Pausa", "", ""]
        case "sistema":      return ["Bloquear el PC", "", ""]
        case "edicion":      return ["Copiar", "", ""]
        case "esperar":      return ["250", "", ""]
        default:             return ["", "", ""]
    }
}

SugerenciasCampo(sug) {
    if (Type(sug) != "String")
        return sug
    switch sug {
        case "@salidas":  return NombresSalidas()
        case "@sonidos":  return ListaSonidos()
        case "@espacios": return ListaEspacios()
        case "@apps":     return ListaAppsNombres()
        default:          return ListaProcesos()
    }
}

FormularioAccion(fila, id, previo := 0) {
    tipo := TIPOS[TipoIndice(id)]
    hex := HexColor(ColorTipo(id))
    d := Gui("+Owner" gCfgGui.Hwnd " -MinimizeBox -MaximizeBox", (fila ? "Editar acción" : "Nueva acción") "  ·  tecla " KeyLabel(gSel) "  ·  " NombreLista(gLista))
    gCfgGui.Opt("+Disabled")
    d.BackColor := C_BG
    d.MarginX := 24, d.MarginY := 18
    BarraOscura(d)
    misBotones := [], cbs := []
    ANCHO_F := 440

    Cerrar(seguir := false) {
        for b in misBotones
            try gHoverMap.Delete(b.Hwnd)
        if !seguir
            gCfgGui.Opt("-Disabled")
        d.Destroy()
        if !seguir
            WinActivate(gCfgGui.Hwnd)
    }

    Valores() {
        v3 := ["", "", ""]
        for n, combo in cbs
            v3[n] := Trim(combo.Text)
        if (id = "abrir") {
            cmd := NombreAComando(v3[1])
            if (cmd != "")
                v3[1] := cmd
        }
        return {t: id, p1: v3[1], p2: v3[2], p3: v3[3]}
    }

    CambiarAccion() {
        actual := Valores()
        Cerrar(true)
        GaleriaAcciones(fila, actual)
    }

    Buscar() {
        if (id = "sonido") {
            DirCreate(CARPETA_SONIDOS)
            f := FileSelect(3, CARPETA_SONIDOS, "Elige el sonido", "Audio (*.mp3; *.wav; *.m4a; *.wma; *.flac)")
            if (f != "" && InStr(f, CARPETA_SONIDOS "\") = 1)
                f := SubStr(f, StrLen(CARPETA_SONIDOS) + 2)   ; solo el nombre si esta en la carpeta Sonidos
        } else
            f := FileSelect(3, , "Elige el programa o archivo", "Programas (*.exe; *.lnk; *.bat; *.ahk; *.*)")
        if (f != "")
            cbs[1].Text := f
    }

    Aceptar(*) {
        nueva := Valores()
        if (tipo.f.Length >= 1 && nueva.p1 = "") {
            MsgBox("Falta llenar: " tipo.f[1][1], APP, "Icon! Owner" d.Hwnd)
            return
        }
        mapa := MapaEdit()
        if !mapa.Has(gSel)
            mapa[gSel] := NuevaTecla()
        lista := ListaDe(mapa[gSel], gLista)
        if fila
            lista[fila] := nueva
        else
            lista.Push(nueva)
        Cerrar()
        TrasCambio(fila ? fila : lista.Length)
    }

    ; --- encabezado: icono, nombre y categoria ---
    d.SetFont("s22 w400 c" hex, "Segoe MDL2 Assets")
    d.Add("Text", "x24 y18 w58 h58 +0x200 Center Background2A2A30", IconoTipo(id))
    d.SetFont("s14 w700 c" C_TXT, "Segoe UI")
    d.Add("Text", "x96 y20 w220 h30 +0x80 +0x4000 Background" C_BG, CortoTipo(id))
    d.SetFont("s9 w600 c" hex)
    d.Add("Text", "x96 y52 w220 Background" C_BG, NombreCategoria(id))
    d.SetFont("s9 w400")
    misBotones.Push(Boton(d, "x" (24 + ANCHO_F - 130) " y32 w130 h30", "Cambiar acción", (*) => CambiarAccion()))

    ; --- campos (solo los que necesita esta accion) ---
    y := 96
    if !tipo.f.Length {
        d.SetFont("s10 w400 c" C_TXT, "Segoe UI")
        d.Add("Text", "x24 y" y " w" ANCHO_F " Background" C_BG, "Esta acción no necesita nada más. Dale Guardar.")
        y += 30
    }
    for i, campo in tipo.f {
        d.SetFont("s9 w400 c" C_MUTED, "Segoe UI")
        d.Add("Text", "x24 y" y " w" ANCHO_F " Background" C_BG, campo[1])
        d.SetFont("s10 c" C_TXT)
        conBuscar := (i = 1 && (id = "abrir" || id = "sonido"))
        cb := d.Add("ComboBox", "x24 y" (y + 20) " w" (conBuscar ? ANCHO_F - 52 : ANCHO_F) " Background" C_KEY, SugerenciasCampo(campo[2]))
        Tema(cb, "DarkMode_CFD")
        cbs.Push(cb)
        if conBuscar
            misBotones.Push(Boton(d, "x" (24 + ANCHO_F - 44) " y" (y + 19) " w44 h26", "...", (*) => Buscar()))
        y += 58
    }
    d.SetFont("s9 w400 c93C5FD", "Segoe UI")
    d.Add("Text", "x24 y" (y + 2) " w" ANCHO_F " Background" C_BG, tipo.h)
    y += 46
    d.SetFont("s10 w600")
    misBotones.Push(Boton(d, "x24 y" y " w130 h36", "Guardar", (*) => Aceptar(), true))
    d.SetFont("w400")
    misBotones.Push(Boton(d, "x162 y" y " w120 h36", "Cancelar", (*) => Cerrar()))
    d.Add("Button", "x0 y0 w0 h0 Default", "").OnEvent("Click", (*) => Aceptar())   ; Enter = Guardar
    d.OnEvent("Close", (*) => Cerrar())
    d.OnEvent("Escape", (*) => Cerrar())

    ; --- valores: los que ya tenia, o los de por defecto ---
    if (IsObject(previo) && previo.t = id)
        vals := [(id = "abrir") ? NombreAppDe(previo.p1) : previo.p1, previo.p2, previo.p3]
    else
        vals := ValoresPorDefecto(id)
    for i, cb in cbs
        cb.Text := vals[i]
    d.Show()
}

; =====================================================================
;  VENTANA DE AJUSTES (teclados, opciones, respaldos, sistema)
; =====================================================================
AjustesAbiertos() => gCfgGui && ui.HasOwnProp("aj") && ui.aj

AbrirAjustes(*) {
    if AjustesAbiertos() {
        try WinActivate(ui.aj.Hwnd)
        return
    }
    d := Gui("+Owner" gCfgGui.Hwnd " -MinimizeBox -MaximizeBox", "Ajustes de DeckLibre")
    ui.aj := d
    ui.ajBotones := []
    d.BackColor := C_BG
    d.MarginX := 22, d.MarginY := 18
    BarraOscura(d)
    d.SetFont("s15 w700 c" C_TXT, "Segoe UI")
    d.Add("Text", "x22 y16 w500 Background" C_BG, "Ajustes")

    y := 62
    Seccion(d, y, "TECLADOS")
    y += 22
    d.SetFont("s10 w400 c" C_MUTED)
    d.Add("Text", "x22 y" (y + 4) " w78 Background" C_BG, "Botonera")
    d.Add("Text", "x22 y" (y + 38) " w78 Background" C_BG, "Principal")
    d.SetFont("c" C_TXT)
    ui.ddlBot := d.Add("DropDownList", "x100 y" y " w400 Background" C_KEY)
    ui.ddlPri := d.Add("DropDownList", "x100 y" (y + 34) " w400 Background" C_KEY)
    Tema(ui.ddlBot, "DarkMode_CFD")
    Tema(ui.ddlPri, "DarkMode_CFD")
    ui.ddlBot.OnEvent("Change", CambioBotonera)
    ui.ddlPri.OnEvent("Change", CambioPrincipal)
    d.SetFont("s9 w400")
    ui.ajBotones.Push(Boton(d, "x510 y" (y - 1) " w110 h28", "Detectar", (*) => DetectarTeclado("botonera")))
    ui.ajBotones.Push(Boton(d, "x510 y" (y + 33) " w110 h28", "Detectar", (*) => DetectarTeclado("principal")))

    y += 82
    Seccion(d, y, "OPCIONES")
    y += 24
    ui.tgAuto := Interruptor(d, 22, y, "Volver a modo normal al desconectar el teclado principal", (*) => CambiarOpcion("auto"))
    y += 32
    ui.tgOsd := Interruptor(d, 22, y, "Indicador en pantalla (volumen, micrófono…)", (*) => CambiarOpcion("osd"))
    y += 32
    ui.tgBat := Interruptor(d, 22, y, "Aviso de batería baja", (*) => CambiarOpcion("bateria"))

    y += 48
    Seccion(d, y, "CONFIGURACIÓN")
    y += 24
    d.SetFont("s9 w400")
    x := 22
    for par in [["Respaldos", AbrirRespaldos, 120], ["Exportar", ExportarConfig, 110], ["Importar", ImportarConfig, 110], ["Registro de errores", AbrirRegistro, 150]] {
        ui.ajBotones.Push(Boton(d, Format("x{} y{} w{} h30", x, y, par[3]), par[1], par[2]))
        x += par[3] + 8
    }
    y += 46
    Seccion(d, y, "SISTEMA")
    y += 24
    x := 22
    for par in [["Iniciar con Windows (admin)", AlternarInicio, 200], ["Identificar pantallas", IdentificarPantallas, 160], ["Diagnóstico de audio", AbrirDiagnostico, 160]] {
        ui.ajBotones.Push(Boton(d, Format("x{} y{} w{} h30", x, y, par[3]), par[1], par[2]))
        x += par[3] + 8
    }
    y += 40
    d.Add("Text", "x22 y" y " w1 h1 Background" C_BG)

    d.OnEvent("Close", CerrarAjustes)
    d.OnEvent("Escape", CerrarAjustes)
    LlenarDispositivos()
    PintarInterruptores()
    d.Show()
}

CerrarAjustes(*) {
    if !AjustesAbiertos()
        return
    for b in ui.ajBotones
        try gHoverMap.Delete(b.Hwnd)
    try ui.aj.Destroy()
    ui.aj := 0
}

LlenarDispositivos() {
    if !AjustesAbiertos()
        return
    lista := ListaTeclados()
    itemsL := [], itemsE := ["(ninguno - sin modo automático)"]
    ui.devBot := [], ui.devPri := [{id: 0, h: ""}]
    selL := 0, selE := 1
    for t in lista {
        itemsL.Push(TextoDispositivo(t)), ui.devBot.Push(t)
        itemsE.Push(TextoDispositivo(t)), ui.devPri.Push(t)
        if (t.id = gBotoneraId)
            selL := itemsL.Length
        if (gPrincipalHandle != "" && t.h = gPrincipalHandle)
            selE := itemsE.Length
    }
    if (gPrincipalHandle != "" && selE = 1) {   ; configurado pero desconectado ahora
        itemsE.Push("(desconectado)  " gPrincipalHandle), ui.devPri.Push({id: 0, h: gPrincipalHandle})
        selE := itemsE.Length
    }
    ui.ddlBot.Delete(), ui.ddlBot.Add(itemsL)
    ui.ddlPri.Delete(), ui.ddlPri.Add(itemsE)
    if selL
        ui.ddlBot.Choose(selL)
    ui.ddlPri.Choose(selE)
}

CambioBotonera(*) {
    global gBotoneraId
    if !ui.ddlBot.Value
        return
    t := ui.devBot[ui.ddlBot.Value]
    gBotoneraId := t.id
    IniWrite(t.h, CFG, "General", "BotoneraHandle")
    AplicarSuscripciones()
    ActualizarEstadoGui()
}

CambioPrincipal(*) {
    global gPrincipalHandle, gPrincipalPresente
    gPrincipalHandle := ui.devPri[ui.ddlPri.Value].h
    gPrincipalPresente := -1
    GuardarConfig()
    RevisarPrincipal()
    ActualizarEstadoGui()
}

PintarInterruptores() {
    if !AjustesAbiertos()
        return
    for par in [[ui.tgAuto, gAuto], [ui.tgOsd, gOSD], [ui.tgBat, gBateria]] {
        on := par[2]
        par[1].Opt("Background" (on ? "2563EB" : "3F3F46"))
        par[1].SetFont("c" (on ? "FFFFFF" : "A1A1AA"))
        par[1].Text := on ? "ON" : "OFF"
    }
}

CambiarOpcion(cual) {
    global gAuto, gOSD, gBateria, gBatAviso, gPrincipalPresente
    if (cual = "auto") {
        gAuto := !gAuto
        gPrincipalPresente := -1
    } else if (cual = "bateria") {
        gBateria := !gBateria
        gBatAviso := 0
    } else
        gOSD := !gOSD
    GuardarConfig()
    PintarInterruptores()
    if (cual = "auto")
        RevisarPrincipal()
    else if (cual = "osd" && gOSD)
        OSD("Indicador activado", , , Chr(0xE73E))
    else if (cual = "bateria" && gBateria)
        RevisarBateria()
}
