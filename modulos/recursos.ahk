; =====================================================================
;  DeckLibre  ·  recursos.ahk
;  Monitor de recursos (CPU, RAM, GPU, disco, red, bateria)
; =====================================================================

; Se crea en modo "DPI por monitor" para que se vea nitida en la pantalla
; de la laptop aunque tenga otra escala que la principal

FmtVel(bps) {
    if (bps = "")
        return "0 KB/s"
    if (bps >= 1048576)
        return Format("{:.1f} MB/s", bps / 1048576)
    return Format("{:.0f} KB/s", bps / 1024)
}

; Contadores de rendimiento de Windows (nombres en ingles: sirven en Windows en espanol)
PdhIniciar() {
    ; Dejar pdh.dll cargada: si DllCall la carga sola, la descarga despues de
    ; cada llamada y la consulta queda invalida (error 0xC0000BBC)
    static libreria := DllCall("LoadLibrary", "Str", "pdh", "Ptr")
    consulta := 0
    est := DllCall("pdh\PdhOpenQueryW", "Ptr", 0, "UPtr", 0, "Ptr*", &consulta, "UInt")
    if (est != 0)
        return {q: 0, c: Map(), err: Map("abrir", est)}
    c := Map(), err := Map()
    rutas := Map("gpu", "\GPU Engine(*)\Utilization Percentage"
               , "disco", "\PhysicalDisk(_Total)\% Idle Time"
               , "rx", "\Network Interface(*)\Bytes Received/sec"
               , "tx", "\Network Interface(*)\Bytes Sent/sec")
    for nombre, ruta in rutas {
        h := 0
        est := DllCall("pdh\PdhAddEnglishCounterW", "Ptr", consulta, "Str", ruta, "UPtr", 0, "Ptr*", &h, "UInt")
        err[nombre] := est
        if (est = 0)
            c[nombre] := h
    }
    err["recolectar"] := DllCall("pdh\PdhCollectQueryData", "Ptr", consulta, "UInt")
    return {q: consulta, c: c, err: err}
}

; Devuelve [[instancia, valor], ...]
PdhArray(h) {
    out := []
    tam := 0, n := 0
    r := DllCall("pdh\PdhGetFormattedCounterArrayW", "Ptr", h, "UInt", 0x8200, "UInt*", &tam, "UInt*", &n, "Ptr", 0, "UInt")
    if (r != 0x800007D2 || !tam)
        return out
    buf := Buffer(tam, 0)
    if (DllCall("pdh\PdhGetFormattedCounterArrayW", "Ptr", h, "UInt", 0x8200, "UInt*", &tam, "UInt*", &n, "Ptr", buf, "UInt") != 0)
        return out
    loop n {
        off := (A_Index - 1) * 24
        st := NumGet(buf, off + 8, "UInt")
        if (st != 0 && st != 1)
            continue
        p := NumGet(buf, off, "Ptr")
        out.Push([p ? StrGet(p, "UTF-16") : "", NumGet(buf, off + 16, "Double")])
    }
    return out
}

PdhSuma(h) {
    s := 0.0
    for it in PdhArray(h)
        s += it[2]
    return s
}

; Uso de la GPU: suma los procesos de cada tarjeta y muestra la mas ocupada
; Uso de la GPU como lo muestra el Administrador de tareas: por cada tarjeta
; y tipo de motor (3D, video, copia...) se suman los procesos y se toma el mayor
PdhGpu(h) {
    sumas := Map()
    for it in PdhArray(h) {
        tarjeta := RegExMatch(it[1], "i)luid_0x[0-9a-f]+_0x[0-9a-f]+_phys_\d+", &m1) ? m1[0] : "x"
        motor := RegExMatch(it[1], "i)engtype_(\w+)", &m2) ? m2[1] : "?"
        clave := tarjeta "|" motor
        sumas[clave] := (sumas.Has(clave) ? sumas[clave] : 0) + it[2]
    }
    mayor := 0
    for clave, v in sumas
        mayor := Max(mayor, v)
    return Round(Min(100, mayor))
}

; Velocidad de red con GetIfTable (no depende de los contadores de Windows).
; Devuelve [bajada, subida] en bytes por segundo, o "" en la primera lectura.
RedVelocidad() {
    static previo := Map(), tickPrevio := 0
    tam := 0
    DllCall("iphlpapi\GetIfTable", "Ptr", 0, "UInt*", &tam, "Int", 0)
    if !tam
        return ""
    buf := Buffer(tam, 0)
    if (DllCall("iphlpapi\GetIfTable", "Ptr", buf, "UInt*", &tam, "Int", 0, "UInt") != 0)
        return ""
    ahora := A_TickCount
    actual := Map(), vistos := Map()
    totEnt := 0, totSal := 0
    loop NumGet(buf, 0, "UInt") {
        base := 4 + (A_Index - 1) * 860                    ; MIB_IFROW = 860 bytes
        tipo := NumGet(buf, base + 516, "UInt")
        oper := NumGet(buf, base + 544, "UInt")
        if (tipo = 24 || oper < 4)                         ; loopback o desconectada
            continue
        idx := NumGet(buf, base + 512, "UInt")
        ent := NumGet(buf, base + 552, "UInt")
        sal := NumGet(buf, base + 576, "UInt")
        actual[idx] := [ent, sal]
        ; Windows repite la misma tarjeta como "filtros" con los mismos contadores
        clave := NumGet(buf, base + 532, "Int64") "|" ent "|" sal
        if vistos.Has(clave)
            continue
        vistos[clave] := true
        if previo.Has(idx) {
            totEnt += (ent - previo[idx][1]) & 0xFFFFFFFF
            totSal += (sal - previo[idx][2]) & 0xFFFFFFFF
        }
    }
    seg := (ahora - tickPrevio) / 1000
    primera := (tickPrevio = 0)
    previo := actual, tickPrevio := ahora
    if (primera || seg <= 0)
        return ""
    return [totEnt / seg, totSal / seg]
}

; Escribe recursos_diagnostico.txt para saber que contador falla
DiagnosticoRecursos(*) {
    archivo := A_ScriptDir "\recursos_diagnostico.txt"
    txt := "Diagnostico del monitor de recursos  " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
    txt .= "AutoHotkey " A_AhkVersion "  " (A_PtrSize * 8) "-bit   admin: " (A_IsAdmin ? "si" : "no") "`n`n"
    if !IsObject(gPdh) {
        txt .= "Los contadores todavia no se iniciaron (abre el monitor primero)`n"
    } else {
        for clave, v in gPdh.err
            txt .= "  " clave ": " Format("0x{:08X}", v) "`n"
        if gPdh.q
            txt .= "  recolectar ahora: " Format("0x{:08X}", DllCall("pdh\PdhCollectQueryData", "Ptr", gPdh.q, "UInt")) "`n"
        for nombre, h in gPdh.c {
            tam := 0, n := 0
            r := DllCall("pdh\PdhGetFormattedCounterArrayW", "Ptr", h, "UInt", 0x8200, "UInt*", &tam, "UInt*", &n, "Ptr", 0, "UInt")
            txt .= "`n== " nombre ": primera llamada " Format("0x{:08X}", r) "  tam=" tam "  n=" n "`n"
            if (r = 0x800007D2 && tam) {
                buf := Buffer(tam, 0)
                r2 := DllCall("pdh\PdhGetFormattedCounterArrayW", "Ptr", h, "UInt", 0x8200, "UInt*", &tam, "UInt*", &n, "Ptr", buf, "UInt")
                txt .= "   segunda llamada " Format("0x{:08X}", r2) "  n=" n "`n"
                loop Min(n, 8) {
                    off := (A_Index - 1) * 24
                    p := NumGet(buf, off, "Ptr")
                    txt .= "   " (p ? StrGet(p, "UTF-16") : "?") "  estado=" Format("0x{:X}", NumGet(buf, off + 8, "UInt")) "  valor=" Round(NumGet(buf, off + 16, "Double"), 2) "`n"
                }
            }
        }
    }
    red := RedVelocidad()
    txt .= "`nRed (GetIfTable): " (IsObject(red) ? Round(red[1]) " B/s bajada, " Round(red[2]) " B/s subida" : "primera lectura") "`n"
    try FileDelete(archivo)
    FileAppend(txt, archivo, "UTF-8")
    return archivo
}

AlternarRecursosMenu(*) => AlternarRecursos("1", "Arriba derecha")

; =====================================================================
;  MONITOR DE RECURSOS v2: tarjeta dibujada con GDI+ (bordes suaves,
;  graficas pequenas). Solo trabaja mientras esta visible: 1 vez por
;  segundo, sin controles de ventana, casi 0% de CPU.
; =====================================================================
AlternarRecursos(pantalla := "1", esquina := "Arriba derecha") {
    global gHist
    if gRec {
        SetTimer(RecursosTick, 0)
        CerrarRecursos()
        return
    }
    gHist := Map("cpu", [], "ram", [], "gpu", [], "rx", [], "tx", [])
    CrearRecursos(pantalla, esquina)
    RecursosTick()
    SetTimer(RecursosTick, 1000)
}

CerrarRecursos() {
    global gRec
    if !gRec
        return
    st := gRec
    gRec := 0
    try DllCall("gdiplus\GdipDeleteGraphics", "Ptr", st.gfx)
    try DllCall("SelectObject", "Ptr", st.hdc, "Ptr", st.obm)
    try DllCall("DeleteObject", "Ptr", st.hbm)
    try DllCall("DeleteDC", "Ptr", st.hdc)
    try st.gui.Destroy()
}

CrearRecursos(pantalla, esquina) {
    global gRec
    GdipIniciar()
    n := IsNumber(pantalla) ? Integer(pantalla) : 1
    if (n < 1 || n > MonitorGetCount())
        n := MonitorGetPrimary()
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        MonitorGetWorkArea(n, &l, &t, &r, &b)
        hMon := DllCall("MonitorFromPoint", "Int64", ((t + 10) << 32) | ((l + 10) & 0xFFFFFFFF), "UInt", 2, "Ptr")
        dpi := 96, dpiY := 96
        try DllCall("Shcore\GetDpiForMonitor", "Ptr", hMon, "Int", 0, "UInt*", &dpi, "UInt*", &dpiY)
        k := dpi / 96
        ancho := Round(300 * k), alto := Round(282 * k), m := Round(16 * k)
        pos := PosicionWidget(n, esquina, ancho, alto, k), x := pos.x, y := pos.y

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
        gRec := {gui: gv, hdc: hdc, hbm: hbm, obm: obm, gfx: gfx, k: k, ancho: ancho, alto: alto, x: x, y: y, fo: Fuentes(k)}
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

RecursosTick() {
    global gCpuPrev, gPdh
    if !gRec
        return
    d := {}
    ; --- CPU ---
    idle := 0, kern := 0, user := 0
    DllCall("GetSystemTimes", "Int64*", &idle, "Int64*", &kern, "Int64*", &user)
    d.cpu := ""
    if IsObject(gCpuPrev) {
        dIdle := idle - gCpuPrev[1]
        dTotal := (kern - gCpuPrev[2]) + (user - gCpuPrev[3])
        if (dTotal > 0)
            d.cpu := Round(Max(0, Min(100, (1 - dIdle / dTotal) * 100)))
    }
    gCpuPrev := [idle, kern, user]

    ; --- RAM ---
    ms := Buffer(64, 0)
    NumPut("UInt", 64, ms, 0)
    DllCall("GlobalMemoryStatusEx", "Ptr", ms)
    d.ram := NumGet(ms, 4, "UInt")
    total := NumGet(ms, 8, "Int64"), libre := NumGet(ms, 16, "Int64")
    d.ramTxt := Format("{:.1f}", (total - libre) / 1073741824) " / " Round(total / 1073741824) " GB"

    ; --- GPU, disco y red ---
    if !IsObject(gPdh)
        gPdh := PdhIniciar()
    d.gpu := "", d.disco := "", d.rx := 0, d.tx := 0
    if (IsObject(gPdh) && gPdh.q) {
        DllCall("pdh\PdhCollectQueryData", "Ptr", gPdh.q)
        static gpuPar := false, gpuUltimo := ""
        gpuPar := !gpuPar
        if (gPdh.c.Has("gpu") && (gpuPar || gpuUltimo = ""))
            gpuUltimo := PdhGpu(gPdh.c["gpu"])
        d.gpu := gpuUltimo
        if gPdh.c.Has("disco") {
            arr := PdhArray(gPdh.c["disco"])
            if arr.Length
                d.disco := Round(Max(0, Min(100, 100 - arr[1][2])))
        }
    }
    red := RedVelocidad()
    if IsObject(red) {
        d.rx := red[1], d.tx := red[2]
    } else if (IsObject(gPdh) && gPdh.c.Has("rx")) {
        d.rx := PdhSuma(gPdh.c["rx"])
        d.tx := gPdh.c.Has("tx") ? PdhSuma(gPdh.c["tx"]) : 0
    }

    ; --- Bateria ---
    sps := Buffer(12, 0)
    DllCall("GetSystemPowerStatus", "Ptr", sps)
    d.ac := NumGet(sps, 0, "UChar"), d.bat := NumGet(sps, 2, "UChar")

    ; --- Historial (ultimos 40 segundos) ---
    Historial("cpu", d.cpu)
    Historial("ram", d.ram)
    if (d.gpu != "")
        Historial("gpu", d.gpu)
    Historial("rx", d.rx)
    Historial("tx", d.tx)

    static ticks := 0, diagHecho := false
    ticks += 1
    if (ticks = 5 && !diagHecho && (d.gpu = "" || d.disco = "")) {
        diagHecho := true
        try DiagnosticoRecursos()
    }

    DibujarRecursos(d)
}

Historial(id, v) {
    if (v = "")
        return
    a := gHist[id]
    a.Push(v)
    if (a.Length > 40)
        a.RemoveAt(1)
}

DibujarRecursos(d) {
    st := gRec, k := st.k, gfx := st.gfx, fo := st.fo
    GRIS := 0xFF8B8B93, BLANCO := 0xFFF4F4F5
    pad := 16 * k
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0)

    ; Fondo con borde suave
    ruta := RutaRedondeada(0.5, 0.5, st.ancho - 1, st.alto - 1, 18 * k)
    br := Pincel(0xF2131316)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    pe := Lapiz(0x24FFFFFF, 1)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)

    ; Encabezado
    br := Pincel(0xFF4ADE80)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", gfx, "Ptr", br, "Float", pad, "Float", 18 * k, "Float", 6 * k, "Float", 6 * k)
    BorrarPincel(br)
    DibujarTexto(gfx, "RECURSOS", pad + 12 * k, 12 * k, 150 * k, 18 * k, fo.tit, GRIS, fo.izq)
    DibujarTexto(gfx, FormatTime(, "HH:mm"), st.ancho - pad - 80 * k, 12 * k, 80 * k, 18 * k, fo.tit, GRIS, fo.der)

    ; Filas con grafica
    y := 40 * k, fila := 52 * k
    FilaGrafica(st, y, "CPU", d.cpu = "" ? "…" : d.cpu "%", d.cpu, gHist["cpu"], 100, 0xFF60A5FA)
    y += fila
    FilaGrafica(st, y, "RAM  ·  " d.ramTxt, d.ram "%", d.ram, gHist["ram"], 100, 0xFFA78BFA)
    y += fila
    FilaGrafica(st, y, "GPU", d.gpu = "" ? "—" : d.gpu "%", d.gpu, gHist["gpu"], 100, 0xFF34D399)
    y += fila
    tope := 65536
    for v in gHist["rx"]
        tope := Max(tope, v)
    for v in gHist["tx"]
        tope := Max(tope, v)
    FilaGrafica(st, y, "RED  ·  ↑ " FmtVel(d.tx), "↓ " FmtVel(d.rx), "", gHist["rx"], tope * 1.15, 0xFF22D3EE, gHist["tx"], 0xFFF472B6, true)
    y += fila

    ; Pie: disco y bateria
    pe := Lapiz(0x14FFFFFF, 1)
    DllCall("gdiplus\GdipDrawLine", "Ptr", gfx, "Ptr", pe, "Float", pad, "Float", y - 2 * k, "Float", st.ancho - pad, "Float", y - 2 * k)
    BorrarLapiz(pe)
    yy := y + 6 * k
    DibujarTexto(gfx, "Disco", pad, yy, 50 * k, 20 * k, fo.lbl, GRIS, fo.izq)
    DibujarTexto(gfx, d.disco = "" ? "—" : d.disco "%", pad + 40 * k, yy, 70 * k, 20 * k, fo.chip, ColorCarga(d.disco), fo.izq)
    mitad := st.ancho / 2
    DibujarTexto(gfx, "Batería", mitad, yy, 60 * k, 20 * k, fo.lbl, GRIS, fo.izq)
    if (d.bat = 255)
        batTxt := d.ac = 1 ? "conectado" : "—", batCol := BLANCO
    else
        batTxt := d.bat "%" (d.ac = 1 ? "  ·  cargando" : ""), batCol := d.bat < 20 ? 0xFFF87171 : d.bat < 40 ? 0xFFFBBF24 : 0xFF4ADE80
    DibujarTexto(gfx, batTxt, mitad + 50 * k, yy, mitad - 50 * k - pad, 20 * k, fo.chip, batCol, fo.izq)

    ; Mostrar en pantalla (ventana con transparencia por pixel)
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

ColorCarga(p) => (p = "") ? 0xFFF4F4F5 : p >= 85 ? 0xFFF87171 : p >= 60 ? 0xFFFBBF24 : 0xFFF4F4F5

FilaGrafica(st, y, etiqueta, valor, pct, datos, tope, color, datos2 := 0, color2 := 0, mediano := false) {
    k := st.k, gfx := st.gfx, fo := st.fo
    pad := 16 * k
    gx := 118 * k, gw := st.ancho - gx - pad, gy := y + 8 * k, gh := 34 * k
    DibujarTexto(gfx, etiqueta, pad, y, st.ancho - 2 * pad, 16 * k, fo.lbl, 0xFF8B8B93, fo.izq)
    DibujarTexto(gfx, valor, pad, y + 16 * k, 100 * k, 28 * k, mediano ? fo.med : fo.val, ColorCarga(pct), fo.izq)
    pe := Lapiz(0x14FFFFFF, 1)
    DllCall("gdiplus\GdipDrawLine", "Ptr", gfx, "Ptr", pe, "Float", gx, "Float", gy + gh, "Float", gx + gw, "Float", gy + gh)
    BorrarLapiz(pe)
    Sparkline(gfx, datos, gx, gy, gw, gh, tope, color, k, true)
    if IsObject(datos2)
        Sparkline(gfx, datos2, gx, gy, gw, gh, tope, color2, k, false)
}

Sparkline(gfx, datos, x, y, w, h, tope, argb, k, relleno) {
    n := datos.Length
    if (n < 2 || tope <= 0)
        return
    paso := w / 39
    x0 := x + w - paso * (n - 1)
    pts := Buffer(8 * (n + 2), 0)
    loop n {
        i := A_Index - 1
        v := Max(0, Min(datos[A_Index], tope)) / tope
        NumPut("Float", x0 + paso * i, pts, i * 8)
        NumPut("Float", y + h - v * h, pts, i * 8 + 4)
    }
    rgb := argb & 0xFFFFFF
    if relleno {
        NumPut("Float", x0 + paso * (n - 1), pts, n * 8)
        NumPut("Float", y + h, pts, n * 8 + 4)
        NumPut("Float", x0, pts, (n + 1) * 8)
        NumPut("Float", y + h, pts, (n + 1) * 8 + 4)
        p1 := Buffer(8), p2 := Buffer(8)
        NumPut("Float", x, p1, 0), NumPut("Float", y - 1, p1, 4)
        NumPut("Float", x, p2, 0), NumPut("Float", y + h + 1, p2, 4)
        lb := 0
        DllCall("gdiplus\GdipCreateLineBrush", "Ptr", p1, "Ptr", p2, "UInt", 0x55000000 | rgb, "UInt", 0x03000000 | rgb, "Int", 1, "Ptr*", &lb)
        DllCall("gdiplus\GdipFillPolygon", "Ptr", gfx, "Ptr", lb, "Ptr", pts, "Int", n + 2, "Int", 0)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", lb)
    }
    pe := Lapiz(argb, (relleno ? 1.7 : 1.3) * k)
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pe, "Int", 2)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pe, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pe, "Int", 2)
    DllCall("gdiplus\GdipDrawLines", "Ptr", gfx, "Ptr", pe, "Ptr", pts, "Int", n)
    BorrarLapiz(pe)
    if relleno {
        lx := NumGet(pts, (n - 1) * 8, "Float"), ly := NumGet(pts, (n - 1) * 8 + 4, "Float")
        rr := 2.6 * k
        br := Pincel(argb)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", gfx, "Ptr", br, "Float", lx - rr, "Float", ly - rr, "Float", rr * 2, "Float", rr * 2)
        BorrarPincel(br)
    }
}
