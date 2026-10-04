; =====================================================================
;  DeckLibre  ·  hoja.ahk
;  Hoja de teclas
; =====================================================================

; =====================================================================
;  HOJA DE TECLAS: muestra que hace cada tecla configurada
;  Mantener = ver y soltar cierra. Toque rapido = queda abierta.
; =====================================================================
HojaPresionar(pantalla) {
    if gHoja {
        CerrarHoja()
        return
    }
    if !MostrarHoja(pantalla)
        return
    gHoja.tecla := gTeclaActual
    gHoja.inicio := A_TickCount
    SetTimer(CerrarHoja, -15000)
}

HojaSoltar(sc) {
    if (gHoja && gHoja.HasOwnProp("tecla") && gHoja.tecla = sc && A_TickCount - gHoja.inicio >= 400)
        CerrarHoja()
}

HojaMenu(*) {
    if gHoja {
        CerrarHoja()
        return
    }
    if MostrarHoja("") {
        gHoja.tecla := 0                   ; abierta desde el menu, no desde una tecla
        gHoja.inicio := A_TickCount
        SetTimer(CerrarHoja, -15000)
    }
}

CerrarHoja(*) {
    global gHoja
    SetTimer(CerrarHoja, 0)
    if !gHoja
        return
    st := gHoja
    gHoja := 0
    CerrarCapa(st)
}

ItemsHoja() {
    items := [], vistos := Map()
    orden := []
    for filaT in FILAS
        for kk in filaT
            orden.Push(kk[1])
    for kk in NUMPAD
        orden.Push(kk[1])
    for sc in orden {
        if (gEfectivo.Has(sc) && TieneAcciones(gEfectivo[sc]) && !vistos.Has(sc)) {
            vistos[sc] := true
            items.Push(sc)
        }
    }
    for sc, kv in gEfectivo
        if (TieneAcciones(kv) && !vistos.Has(sc))
            items.Push(sc)
    return items
}

MonitorParaHoja(p) {
    if (IsNumber(p) && p >= 1 && p <= MonitorGetCount())
        return Integer(p)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (mx >= l && mx < r && my >= t && my < b)
            return A_Index
    }
    return MonitorGetPrimary()
}

MostrarHoja(pantalla) {
    global gHoja
    items := ItemsHoja()
    if !items.Length {
        OSD("Todavía no tienes teclas configuradas", , "FBBF24", Chr(0xE765))
        return false
    }
    GdipIniciar()
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        n := MonitorParaHoja(pantalla)
        MonitorGetWorkArea(n, &l, &t, &r, &b)
        k := DpiMonitor(l, t) / 96
        fo := Fuentes(k)
        colW := 290, itemH := 48, pad := 24, cab := 78, pie := 40, sep := 14
        cols := items.Length <= 7 ? 1 : items.Length <= 16 ? 2 : 3
        loop {
            filasN := Ceil(items.Length / cols)
            alto := Round((cab + filasN * itemH + pie) * k)
            if (alto <= (b - t) * 0.9 || cols >= 5)
                break
            cols += 1
        }
        ancho := Round((pad * 2 + cols * colW + (cols - 1) * sep) * k)
        x := l + ((r - l) - ancho) // 2
        y := t + ((b - t) - alto) // 2
        st := CrearCapa(x, y, ancho, alto)
        gfx := st.gfx
        GRIS := 0xFF8B8B93, BLANCO := 0xFFF4F4F5

        DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0)
        ruta := RutaRedondeada(0.5, 0.5, ancho - 1, alto - 1, 20 * k)
        br := Pincel(0xF5131316)
        DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
        BorrarPincel(br)
        pe := Lapiz(0x24FFFFFF, 1)
        DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
        BorrarLapiz(pe)
        DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)

        ; Encabezado
        DibujarTexto(gfx, "DECKLIBRE", pad * k, 18 * k, 300 * k, 16 * k, fo.tit, GRIS, fo.izq)
        DibujarTexto(gfx, "Tus teclas" (gPerfilActivo != "" ? "  ·  " NombrePerfil(gPerfilActivo) : ""), pad * k, 34 * k, 300 * k, 30 * k, fo.big, BLANCO, fo.izq)
        enBotonera := (gModo = "botonera")
        Chip(gfx, ancho - pad * k - 136 * k, 28 * k, 136 * k, 26 * k, enBotonera ? 0xFF60A5FA : 0xFFFBBF24, enBotonera ? "MODO BOTONERA" : "MODO NORMAL", fo.tit, fo.cen)
        pe := Lapiz(0x14FFFFFF, 1)
        DllCall("gdiplus\GdipDrawLine", "Ptr", gfx, "Ptr", pe, "Float", pad * k, "Float", (cab - 8) * k, "Float", ancho - pad * k, "Float", (cab - 8) * k)
        BorrarLapiz(pe)

        ; Teclas (en columnas)
        for i, sc in items {
            c := (i - 1) // filasN
            fi := Mod(i - 1, filasN)
            ix := (pad + c * (colW + sep)) * k
            iy := (cab + fi * itemH) * k
            kv := gEfectivo[sc]
            a := PrimeraAccion(kv)
            Chip(gfx, ix, iy + 8 * k, 66 * k, 30 * k, ColorCategoria(a.t), KeyLabel(sc), fo.chip, fo.cen)
            titulo := (kv.nombre != "") ? kv.nombre : TituloAccion(a)
            sub := TipoNombre(a.t) (kv.acciones.Length > 1 ? "  ·  +" (kv.acciones.Length - 1) " más" : "")
            sub .= (kv.mantener.Length ? "  ·  mantener: " TituloAccion(kv.mantener[1]) : "") (kv.doble.Length ? "  ·  doble: " TituloAccion(kv.doble[1]) : "")
            DibujarTexto(gfx, titulo, ix + 78 * k, iy + 5 * k, (colW - 82) * k, 20 * k, fo.item, BLANCO, fo.izq)
            DibujarTexto(gfx, sub, ix + 78 * k, iy + 25 * k, (colW - 82) * k, 16 * k, fo.sub, GRIS, fo.izq)
        }

        ; Pie
        DibujarTexto(gfx, "Suelta la tecla para cerrar   ·   toque rápido = dejarla abierta", pad * k, alto - (pie - 10) * k, ancho - 2 * pad * k, 18 * k, fo.sub, GRIS, fo.izq)

        MostrarCapa(st)
        gHoja := st
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
    return true
}

ColorCategoria(t) => ColorTipo(t)

TituloAccion(a) {
    switch a.t {
        case "volgen":   return (SubStr(Delta(a.p1), 1, 1) = "-" ? "Bajar" : "Subir") " volumen"
        case "mutegen":  return "Silenciar todo"
        case "volapp":   return NombreBonito(a.p1) "   " (SubStr(Delta(a.p2), 1, 1) = "-" ? "−" : "+") SubStr(Delta(a.p2), 2) "%"
        case "muteapp":  return "Silenciar " NombreBonito(a.p1)
        case "mic":      return "Micrófono on / off"
        case "abrir":    return "Abrir " NombreDestino(a.p1)
        case "ventana":  return "Mover ventana"
        case "recursos": return "Monitor de recursos"
        case "media":    return a.p1
        case "atajo":    return "Atajo   " a.p1
        case "texto":    return "Escribir texto"
        case "esperar":  return "Esperar " a.p1 " ms"
        case "modo":     return "Cambiar modo"
        case "salida":   return (a.p1 = "" || InStr(a.p1, "Siguiente")) ? "Cambiar salida de audio" : a.p1
        case "hoja":     return "Hoja de teclas"
        case "sistema", "edicion": return a.p1
        case "acomodar": return a.p1
        case "espacio":  return (InStr(a.p2, "Guardar") ? "Guardar espacio " : "Espacio ") a.p1
        case "portapapeles": return "Historial del portapapeles"
        case "temporizador": return a.p1
        case "brillo":   return "Brillo " a.p1
        case "clima":    return "Clima " a.p1
        case "reloj", "calendario", "notas", "micwidget": return NombreWidget(a.t)
        case "texto":    return "Texto: " SubStr(RegExReplace(a.p1, "\{n\}", " "), 1, 28)
        case "sonido":   return "Sonido: " RegExReplace(a.p1, "\.\w+$")
        default:         return TipoNombre(a.t)
    }
}

NombreDestino(p) {
    n := ComandoANombre(p)
    if (n != "")
        return n
    if RegExMatch(p, "i)shell:AppsFolder\\(.+)$", &ma)
        return RegExReplace(RegExReplace(ma[1], ".*!", ""), "_.*", "")
    p := Trim(p, ' "')
    if RegExMatch(p, "i)^https?://(?:www\.)?([^/]+)", &mm)
        return mm[1]
    SplitPath(p, , , , &sinExt)
    return NombreBonito(sinExt ".exe")
}
