; =====================================================================
;  DeckLibre  ·  graficos.ahk
;  Ayudas de GDI+ para dibujar tarjetas con transparencia
; =====================================================================

; ---------------- Ayudas de GDI+ ----------------
GdipIniciar() {
    static token := 0
    if token
        return token
    DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &token, "Ptr", si, "Ptr", 0)
    return token
}

Pincel(argb) {
    b := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &b)
    return b
}

BorrarPincel(b) => DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)

Lapiz(argb, grosor) {
    p := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", grosor, "Int", 2, "Ptr*", &p)
    return p
}

BorrarLapiz(p) => DllCall("gdiplus\GdipDeletePen", "Ptr", p)

RutaRedondeada(x, y, w, h, radio) {
    ruta := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &ruta)
    dd := radio * 2
    DllCall("gdiplus\GdipAddPathArc", "Ptr", ruta, "Float", x, "Float", y, "Float", dd, "Float", dd, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", ruta, "Float", x + w - dd, "Float", y, "Float", dd, "Float", dd, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", ruta, "Float", x + w - dd, "Float", y + h - dd, "Float", dd, "Float", dd, "Float", 0, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", ruta, "Float", x, "Float", y + h - dd, "Float", dd, "Float", dd, "Float", 90, "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", ruta)
    return ruta
}

CrearFuente(familia, px, estilo := 0) {
    fu := 0
    DllCall("gdiplus\GdipCreateFont", "Ptr", familia, "Float", px, "Int", estilo, "Int", 2, "Ptr*", &fu)
    return fu
}

CrearFormato(alineacion) {
    fmt := 0
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x1000, "Int", 0, "Ptr*", &fmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", alineacion)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
    DllCall("gdiplus\GdipSetStringFormatTrimming", "Ptr", fmt, "Int", 3)
    return fmt
}

; Fuentes en pixeles segun la escala de la pantalla (se crean una sola vez)
Fuentes(k) {
    static cache := Map()
    clave := Round(k * 100)
    if cache.Has(clave)
        return cache[clave]
    famR := 0, famS := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", &famR)
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI Semibold", "Ptr", 0, "Ptr*", &famS)
    if !famS
        famS := famR
    fo := {}
    fo.tit := CrearFuente(famS, 10.5 * k)
    fo.lbl := CrearFuente(famR, 11 * k)
    fo.val := CrearFuente(famS, 20 * k)
    fo.med := CrearFuente(famS, 15 * k)
    fo.chip := CrearFuente(famS, 12 * k)
    fo.item := CrearFuente(famS, 13 * k)
    fo.big := CrearFuente(famS, 20 * k)
    fo.sub := CrearFuente(famR, 10.5 * k)
    fo.cen := CrearFormato(1)
    famI := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe MDL2 Assets", "Ptr", 0, "Ptr*", &famI)
    if !famI
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe Fluent Icons", "Ptr", 0, "Ptr*", &famI)
    if !famI
        famI := famR
    fo.ico := CrearFuente(famI, 15 * k)
    fo.tecla := CrearFuente(famS, 11 * k)
    fo.mini := CrearFuente(famS, 8 * k)
    famL := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI Light", "Ptr", 0, "Ptr*", &famL)
    fo.reloj := CrearFuente(famL ? famL : famR, 38 * k)
    fo.izq := CrearFormato(0)
    fo.der := CrearFormato(2)
    cache[clave] := fo
    return fo
}

DibujarTexto(gfx, s, x, y, w, h, fuente, argb, fmt) {
    rc := Buffer(16)
    NumPut("Float", x, rc, 0), NumPut("Float", y, rc, 4), NumPut("Float", w, rc, 8), NumPut("Float", h, rc, 12)
    br := Pincel(argb)
    DllCall("gdiplus\GdipDrawString", "Ptr", gfx, "WStr", String(s), "Int", -1, "Ptr", fuente, "Ptr", rc, "Ptr", fmt, "Ptr", br)
    BorrarPincel(br)
}

DpiMonitor(x, y) {
    hMon := DllCall("MonitorFromPoint", "Int64", ((y + 10) << 32) | ((x + 10) & 0xFFFFFFFF), "UInt", 2, "Ptr")
    dpi := 96, dpiY := 96
    try DllCall("Shcore\GetDpiForMonitor", "Ptr", hMon, "Int", 0, "UInt*", &dpi, "UInt*", &dpiY)
    return dpi
}

Chip(gfx, x, y, w, h, argb, texto, fuente, fmt) {
    rgb := argb & 0xFFFFFF
    ruta := RutaRedondeada(x, y, w, h, h / 2.2)
    br := Pincel(0x2E000000 | rgb)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    pe := Lapiz(0x55000000 | rgb, 1)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)
    DibujarTexto(gfx, texto, x, y, w, h, fuente, argb, fmt)
}

; ---------------- Capa con transparencia por pixel ----------------
CrearCapa(x, y, ancho, alto) {
    gv := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80000 +E0x20 -DPIScale")
    gv.Show(Format("NA x{} y{} w{} h{}", x, y, ancho, alto))
    bi := Buffer(40, 0)
    NumPut("UInt", 40, bi, 0)
    NumPut("Int", ancho, bi, 4)
    NumPut("Int", -alto, bi, 8)
    NumPut("UShort", 1, bi, 12)
    NumPut("UShort", 32, bi, 14)
    hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    bits := 0
    hbm := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bi, "UInt", 0, "Ptr*", &bits, "Ptr", 0, "UInt", 0, "Ptr")
    obm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
    gfx := 0
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &gfx)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", gfx, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", gfx, "Int", 2)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", gfx, "Int", 4)
    return {gui: gv, hdc: hdc, hbm: hbm, obm: obm, gfx: gfx, ancho: ancho, alto: alto, x: x, y: y}
}

MostrarCapa(st) {
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        pt := Buffer(8), sz := Buffer(8), src := Buffer(8, 0)
        NumPut("Int", st.x, pt, 0), NumPut("Int", st.y, pt, 4)
        NumPut("Int", st.ancho, sz, 0), NumPut("Int", st.alto, sz, 4)
        DllCall("UpdateLayeredWindow", "Ptr", st.gui.Hwnd, "Ptr", 0, "Ptr", pt, "Ptr", sz, "Ptr", st.hdc, "Ptr", src, "UInt", 0, "UInt*", 0x01FF0000, "UInt", 2)
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

CerrarCapa(st) {
    try DllCall("gdiplus\GdipDeleteGraphics", "Ptr", st.gfx)
    try DllCall("SelectObject", "Ptr", st.hdc, "Ptr", st.obm)
    try DllCall("DeleteObject", "Ptr", st.hbm)
    try DllCall("DeleteDC", "Ptr", st.hdc)
    try st.gui.Destroy()
}
