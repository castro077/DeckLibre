; =====================================================================
;  DeckLibre  ·  widgets.ahk
;  Tarjetas pequenas en pantalla: reloj, calendario, notas rapidas,
;  aviso de microfono silenciado y clima.
;  Los widgets abiertos se recuerdan y vuelven a aparecer al reiniciar.
; =====================================================================

WidgetsLista() => ["reloj", "calendario", "notas", "clima", "micwidget"]

NombreWidget(id) {
    static nombres := Map("reloj", "Reloj", "calendario", "Calendario", "notas", "Notas rápidas"
        , "clima", "Clima", "micwidget", "Aviso de micrófono silenciado")
    return nombres.Has(id) ? nombres[id] : id
}

EsWidget(id) => InStr(",reloj,calendario,notas,micwidget,clima,", "," id ",")

; Que guarda cada widget en los campos de la accion
ParamsWidget(id, a) {
    if (id = "clima")
        return {pantalla: a.p2, esquina: a.p3, extra: a.p1}
    return {pantalla: a.p1, esquina: a.p2, extra: a.p3}
}

; La tecla muestra el widget; si ya esta en pantalla, lo quita
WidgetAccion(a) {
    id := a.t
    if gWidgets.Has(id) {
        CerrarWidget(id)
        if (id = "micwidget")
            OSD("Aviso de micrófono desactivado", , "8B8B93", Chr(0xE720))
        return
    }
    p := ParamsWidget(id, a)
    if (id = "clima" && Trim(p.extra) = "") {
        OSD("Escribe la ciudad en la acción del clima", , "FBBF24", Chr(0xE753))
        return
    }
    AbrirWidget(id, p.pantalla, p.esquina, p.extra, true)
    if (id = "micwidget")
        OSD(MicMuteado() = "" ? "No encontré un micrófono" : "Aviso de micrófono activado", , "F87171", Chr(0xE720))
}

; ---------------- Abrir / cerrar / recordar ----------------
AbrirWidget(id, pantalla := "", esquina := "", extra := "", activar := false) {
    CerrarWidget(id, false)
    if (esquina = "")
        esquina := (id = "micwidget") ? "Arriba centro" : "Arriba derecha"
    n := IsNumber(pantalla) ? Integer(pantalla) : MonitorGetPrimary()
    if (n < 1 || n > MonitorGetCount())
        n := MonitorGetPrimary()
    GdipIniciar()
    w := {id: id, mon: n, esquina: esquina, extra: extra, st: 0, gui: 0, tick: 0, rect: 0, activar: activar}
    gWidgets[id] := w
    cada := 0
    try {
        switch id {
            case "reloj":
                AbrirCapaWidget(w, 236, 108)
                w.tick := TickReloj, cada := 1000
            case "calendario":
                w.filas := FilasMes(), w.dia := ""
                AbrirCapaWidget(w, 252, AltoCalendario(w.filas))
                w.tick := TickCalendario, cada := 60000
            case "micwidget":
                AbrirCapaWidget(w, 250, 44)
                w.estado := -1, w.parpadeo := false
                w.tick := TickMic, cada := 700
            case "clima":
                AbrirCapaWidget(w, 272, 184)
                w.datos := 0, w.req := 0, w.paso := "", w.lugar := "", w.hora := ""
                w.estadoTxt := "Buscando el clima…"
            case "notas":
                AbrirNotas(w)
            default:
                throw Error("Widget desconocido: " id)
        }
    } catch as e {
        CerrarWidget(id, false)
        throw e
    }
    if w.tick {
        w.tick.Call()
        SetTimer(w.tick, cada)
    }
    if (id = "clima") {
        ClimaDibujar(w)
        ClimaActualizar()
        SetTimer(ClimaActualizar, 1800000)      ; cada 30 minutos
    }
    try IniWrite(n "|" esquina "|" StrReplace(extra, "|", "/"), CFG, "Widgets", id)
    GuardarWidgetsAbiertos()
    ActualizarMenuWidgets()
}

CerrarWidget(id, recordar := true) {
    if !gWidgets.Has(id)
        return
    w := gWidgets[id]
    if w.tick
        SetTimer(w.tick, 0)
    if (id = "clima") {
        SetTimer(ClimaActualizar, 0), SetTimer(ClimaSondeo, 0), SetTimer(ClimaReintento, 0)
        if w.req
            try w.req.Abort()
        w.req := 0
    }
    if (id = "notas") {
        SetTimer(GuardarNotas, 0)
        GuardarNotas()
    }
    if w.st
        CerrarCapa(w.st)
    if w.gui
        try w.gui.Destroy()
    gWidgets.Delete(id)
    if recordar {
        GuardarWidgetsAbiertos()
        ActualizarMenuWidgets()
    }
}

GuardarWidgetsAbiertos() {
    lista := ""
    for id in gWidgets
        lista .= (lista = "" ? "" : ",") id
    try IniWrite(lista, CFG, "Widgets", "Abiertos")
}

; Al arrancar vuelven los widgets que estaban abiertos
RestaurarWidgets() {
    abiertos := IniRead(CFG, "Widgets", "Abiertos", "")
    for id in StrSplit(abiertos, ",", " ") {
        if (id = "" || !EsWidget(id) || gWidgets.Has(id))
            continue
        v := StrSplit(IniRead(CFG, "Widgets", id, "||"), "|")
        while (v.Length < 3)
            v.Push("")
        try AbrirWidget(id, v[1], v[2], v[3])
        catch as e
            Registrar("No se pudo abrir el widget " id ": " e.Message, "ERROR")
    }
}

; ---------------- Menu de la bandeja ----------------
MenuWidgets() {
    static m := 0
    if !m {
        m := Menu()
        for id in WidgetsLista()
            m.Add(NombreWidget(id), WidgetDesdeMenu.Bind(id))
    }
    return m
}

ActualizarMenuWidgets() {
    m := MenuWidgets()
    for id in WidgetsLista() {
        try {
            if gWidgets.Has(id)
                m.Check(NombreWidget(id))
            else
                m.Uncheck(NombreWidget(id))
        }
    }
}

WidgetDesdeMenu(id, *) {
    if gWidgets.Has(id) {
        CerrarWidget(id)
        return
    }
    v := StrSplit(IniRead(CFG, "Widgets", id, "||"), "|")
    while (v.Length < 3)
        v.Push("")
    if (id = "clima" && Trim(v[3]) = "") {
        ib := InputBox("¿De qué ciudad quieres ver el clima?`n(Ej: Villavicencio, Bogotá, Madrid…)", APP " · Clima", "w340 h150")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        v[3] := Trim(ib.Value)
    }
    AbrirWidget(id, v[1], v[2], v[3], true)
}

; ---------------- Posicion y dibujo comun ----------------
AbrirCapaWidget(w, ancho, alto) {
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        MonitorGetWorkArea(w.mon, &l, &t)
        k := DpiMonitor(l, t) / 96
        ancho := Round(ancho * k), alto := Round(alto * k)
        pos := PosicionWidget(w.mon, w.esquina, ancho, alto, k, w.id)
        w.st := CrearCapa(pos.x, pos.y, ancho, alto)
        w.st.k := k
        w.rect := {x: pos.x, y: pos.y, w: ancho, h: alto}
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

; Busca un lugar libre en la esquina: si ya hay otra tarjeta ahi
; (otro widget, el monitor de recursos o el temporizador), se pone al lado.
; Se llama con el contexto de DPI por monitor activo.
PosicionWidget(n, esquina, ancho, alto, k, ignorar := "") {
    if (esquina = "")
        esquina := "Arriba derecha"
    MonitorGetWorkArea(n, &l, &t, &r, &b)
    m := Round(16 * k), sep := Round(10 * k)
    x := InStr(esquina, "izquierda") ? l + m : InStr(esquina, "derecha") ? r - ancho - m : l + (r - l - ancho) // 2
    abajo := InStr(esquina, "Abajo")
    y := abajo ? b - alto - m : t + m
    ocupados := RectsOcupados(ignorar)
    loop 12 {
        choca := false
        for o in ocupados {
            if (x < o.x + o.w && o.x < x + ancho && y < o.y + o.h && o.y < y + alto) {
                y := abajo ? o.y - alto - sep : o.y + o.h + sep
                choca := true
                break
            }
        }
        if !choca
            break
    }
    return {x: x, y: y}
}

RectsOcupados(ignorar) {
    lista := []
    for id, w in gWidgets
        if (id != ignorar && w.rect)
            lista.Push(w.rect)
    if gRec
        lista.Push({x: gRec.x, y: gRec.y, w: gRec.ancho, h: gRec.alto})
    if (gTimer && gTimer.capa)
        lista.Push({x: gTimer.capa.x, y: gTimer.capa.y, w: gTimer.capa.ancho, h: gTimer.capa.alto})
    return lista
}

FondoWidget(st, radio := 18) {
    gfx := st.gfx
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0)
    ruta := RutaRedondeada(0.5, 0.5, st.ancho - 1, st.alto - 1, radio * st.k)
    br := Pincel(0xF2131316)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    pe := Lapiz(0x24FFFFFF, 1)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)
}

LineaW(gfx, x1, y1, x2, y2, argb, grosor) {
    pe := Lapiz(argb, grosor)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pe, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pe, "Int", 2)
    DllCall("gdiplus\GdipDrawLine", "Ptr", gfx, "Ptr", pe, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
    BorrarLapiz(pe)
}

CirculoW(gfx, x, y, d, argb) {
    br := Pincel(argb)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", gfx, "Ptr", br, "Float", x, "Float", y, "Float", d, "Float", d)
    BorrarPincel(br)
}

RedondeadoW(gfx, x, y, ancho, alto, radio, argb) {
    ruta := RutaRedondeada(x, y, ancho, alto, radio)
    br := Pincel(argb)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)
}

Mayuscula(s) => StrUpper(SubStr(s, 1, 1)) SubStr(s, 2)

; =====================================================================
;  RELOJ
; =====================================================================
TickReloj() {
    if !gWidgets.Has("reloj") {
        SetTimer(TickReloj, 0)
        return
    }
    w := gWidgets["reloj"], st := w.st, k := st.k, gfx := st.gfx, fo := Fuentes(k)
    pad := 18 * k
    FondoWidget(st)
    doce := InStr(w.extra, "12")
    DibujarTexto(gfx, FormatTime(, doce ? "h:mm" : "HH:mm"), pad - 3 * k, 8 * k, st.ancho - 2 * pad, 54 * k, fo.reloj, 0xFFF4F4F5, fo.izq)
    if doce
        DibujarTexto(gfx, FormatTime(, "tt"), st.ancho - pad - 70 * k, 14 * k, 70 * k, 22 * k, fo.chip, 0xFF8B8B93, fo.der)
    else
        DibujarTexto(gfx, A_Sec, st.ancho - pad - 40 * k, 14 * k, 40 * k, 22 * k, fo.chip, 0xFF5B5B63, fo.der)
    DibujarTexto(gfx, Mayuscula(FormatTime(, "dddd d 'de' MMMM")), pad, 62 * k, st.ancho - 2 * pad, 20 * k, fo.lbl, 0xFFA1A1AA, fo.izq)
    ; barrita de los segundos
    y := st.alto - 18 * k, largo := st.ancho - 2 * pad
    RedondeadoW(gfx, pad, y, largo, 4 * k, 2 * k, 0x1FFFFFFF)
    RedondeadoW(gfx, pad, y, Max(4 * k, largo * (A_Sec + 1) / 60), 4 * k, 2 * k, 0xFF60A5FA)
    MostrarCapa(st)
}

; =====================================================================
;  CALENDARIO
; =====================================================================
DiasDelMes(anio, mes) {
    anio := Integer(anio), mes := Integer(mes)
    sig := (mes = 12) ? (anio + 1) "0101" : anio Format("{:02d}", mes + 1) "01"
    return DateDiff(sig, anio Format("{:02d}", mes) "01", "Days")
}

; Columna (0 = lunes) donde cae el dia 1 del mes
InicioMes() => Mod(Integer(FormatTime(A_YYYY A_MM "01", "WDay")) + 5, 7)

FilasMes() => Ceil((InicioMes() + DiasDelMes(A_YYYY, A_MM)) / 7)

AltoCalendario(filas) => 70 + filas * 28 + 12

TickCalendario() {
    if !gWidgets.Has("calendario") {
        SetTimer(TickCalendario, 0)
        return
    }
    w := gWidgets["calendario"]
    hoy := A_YYYY A_MM A_DD
    if (w.dia = hoy)
        return
    if (FilasMes() != w.filas) {          ; mes nuevo con otra cantidad de semanas
        AbrirWidget("calendario", w.mon, w.esquina, w.extra)
        return
    }
    w.dia := hoy
    st := w.st, k := st.k, gfx := st.gfx, fo := Fuentes(k)
    pad := 16 * k
    FondoWidget(st)
    DibujarTexto(gfx, Chr(0xE787), pad, 12 * k, 20 * k, 22 * k, fo.ico, 0xFF60A5FA, fo.izq)
    DibujarTexto(gfx, Mayuscula(FormatTime(A_YYYY A_MM "01", "MMMM yyyy")), pad + 26 * k, 12 * k, 150 * k, 22 * k, fo.item, 0xFFF4F4F5, fo.izq)
    DibujarTexto(gfx, "SEM " Integer(SubStr(FormatTime(, "YWeek"), 5)), st.ancho - pad - 60 * k, 12 * k, 60 * k, 22 * k, fo.tit, 0xFF5B5B63, fo.der)
    celda := (st.ancho - 2 * pad) / 7
    for i, letra in ["L", "M", "M", "J", "V", "S", "D"]
        DibujarTexto(gfx, letra, pad + (i - 1) * celda, 42 * k, celda, 18 * k, fo.tit, i >= 6 ? 0xFF5B5B63 : 0xFF8B8B93, fo.cen)
    inicio := InicioMes(), alto := 28 * k
    loop DiasDelMes(A_YYYY, A_MM) {
        p := inicio + A_Index - 1
        columna := Mod(p, 7), cx := pad + columna * celda, cy := 66 * k + (p // 7) * alto
        if (A_Index = Integer(A_DD)) {
            dd := 24 * k
            CirculoW(gfx, cx + (celda - dd) / 2, cy + (alto - dd) / 2, dd, 0xFF3B82F6)
            DibujarTexto(gfx, A_Index, cx, cy, celda, alto, fo.chip, 0xFFFFFFFF, fo.cen)
        } else
            DibujarTexto(gfx, A_Index, cx, cy, celda, alto, fo.lbl, columna >= 5 ? 0xFF71717A : (A_Index < Integer(A_DD) ? 0xFF8B8B93 : 0xFFE4E4E7), fo.cen)
    }
    MostrarCapa(st)
}

; =====================================================================
;  AVISO DE MICROFONO SILENCIADO
;  Solo se ve cuando el micro esta silenciado (para no hablar sin que te oigan)
; =====================================================================
MicMuteado() {
    static ep := 0, cuando := 0
    try {
        if (!ep || A_TickCount - cuando > 10000) {     ; por si cambias de microfono
            eps := MicDispositivos()
            ep := eps.Length ? eps[1] : 0
            cuando := A_TickCount
        }
        if !ep
            return ""
        m := 0
        ComCall(15, ep, "Int*", &m)                     ; GetMute
        return m ? 1 : 0
    } catch {
        ep := 0
        return ""
    }
}

TickMic() {
    if !gWidgets.Has("micwidget") {
        SetTimer(TickMic, 0)
        return
    }
    w := gWidgets["micwidget"], st := w.st
    if (MicMuteado() != 1) {
        if (w.estado != 0) {
            DllCall("gdiplus\GdipGraphicsClear", "Ptr", st.gfx, "UInt", 0)
            MostrarCapa(st)
            w.estado := 0
        }
        return
    }
    w.estado := 1
    w.parpadeo := !w.parpadeo
    k := st.k, gfx := st.gfx, fo := Fuentes(k)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0)
    alto := st.alto - 1
    ruta := RutaRedondeada(0.5, 0.5, st.ancho - 1, alto, alto / 2)
    br := Pincel(0xF21C1113)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    pe := Lapiz(0xB0F87171, 1.5 * k)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)
    ix := 16 * k, iy := (st.alto - 20 * k) / 2
    DibujarTexto(gfx, Chr(0xE720), ix, iy, 20 * k, 20 * k, fo.ico, 0xFFF87171, fo.cen)
    LineaW(gfx, ix + 2 * k, iy + 2 * k, ix + 18 * k, iy + 18 * k, 0xFF1C1113, 4.5 * k)
    LineaW(gfx, ix + 2 * k, iy + 2 * k, ix + 18 * k, iy + 18 * k, 0xFFF87171, 1.8 * k)
    DibujarTexto(gfx, "MICRÓFONO SILENCIADO", ix + 30 * k, 0, st.ancho - ix - 60 * k, st.alto, fo.tit, 0xFFFECACA, fo.izq)
    CirculoW(gfx, st.ancho - 26 * k, (st.alto - 8 * k) / 2, 8 * k, w.parpadeo ? 0xFFEF4444 : 0x40EF4444)
    MostrarCapa(st)
}

; =====================================================================
;  CLIMA  (Open-Meteo: gratis y sin cuenta)
;  La consulta va en segundo plano para no trabar las teclas.
; =====================================================================
ClimaActualizar() {
    if !gWidgets.Has("clima") {
        SetTimer(ClimaActualizar, 0)
        return
    }
    w := gWidgets["clima"]
    if w.req                                  ; ya hay una consulta en camino
        return
    ciudad := Trim(w.extra)
    guardado := StrSplit(IniRead(CFG, "ClimaCiudades", StrLower(ciudad), ""), "|")
    if (guardado.Length >= 3 && IsNumber(guardado[1]) && IsNumber(guardado[2])) {
        w.lugar := guardado[3]
        ClimaPronostico(w, guardado[1], guardado[2])
        return
    }
    nombre := Trim(StrSplit(ciudad, ",")[1])
    try ClimaPedir(w, "https://geocoding-api.open-meteo.com/v1/search?name=" UrlCodificar(nombre) "&count=10&language=es&format=json", "geo")
    catch
        ClimaFallo(w, "Sin conexión")
}

ClimaReintento() => ClimaActualizar()

ClimaPronostico(w, lat, lon) {
    url := "https://api.open-meteo.com/v1/forecast?latitude=" lat "&longitude=" lon
        . "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day"
        . "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
        . "&timezone=auto&forecast_days=4"
    try ClimaPedir(w, url, "pronostico")
    catch
        ClimaFallo(w, "Sin conexión")
}

ClimaPedir(w, url, paso) {
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.SetTimeouts(5000, 5000, 10000, 10000)
    req.Open("GET", url, true)                ; true = no espera aqui
    req.SetRequestHeader("User-Agent", "DeckLibre")
    req.Send()
    w.req := req, w.paso := paso, w.inicio := A_TickCount
    SetTimer(ClimaSondeo, 250)
}

ClimaSondeo() {
    if !gWidgets.Has("clima") || !gWidgets["clima"].req {
        SetTimer(ClimaSondeo, 0)
        return
    }
    w := gWidgets["clima"]
    err := false, listo := false
    try listo := w.req.WaitForResponse(0)
    catch
        err := true
    if (!err && !listo && A_TickCount - w.inicio < 20000)
        return                                ; todavia no llega
    SetTimer(ClimaSondeo, 0)
    req := w.req, w.req := 0
    texto := ""
    if (!err && listo) {
        try {
            if (req.Status = 200)
                texto := TextoUtf8(req)
        }
    }
    if (texto = "") {
        try req.Abort()
        ClimaFallo(w, (!err && !listo) ? "El servicio del clima no respondió" : "Sin conexión")
        return
    }
    if (w.paso = "geo")
        ClimaGeoListo(w, texto)
    else
        ClimaPronosticoListo(w, texto)
}

ClimaGeoListo(w, texto) {
    partes := StrSplit(Trim(w.extra), ",", " ")
    filtro := partes.Length > 1 ? partes[2] : ""
    elegido := 0, pos := 1
    while (pos := RegExMatch(texto, '\{"id":[^{}]*\}', &m, pos)) {
        r := m[0], pos += StrLen(r)
        if !(RegExMatch(r, '"latitude":(-?[\d.]+)', &la) && RegExMatch(r, '"longitude":(-?[\d.]+)', &lo))
            continue
        nom := RegExMatch(r, '"name":"([^"]*)"', &mn) ? JsonTexto(mn[1]) : partes[1]
        donde := (RegExMatch(r, '"country":"([^"]*)"', &mc) ? JsonTexto(mc[1]) : "") " " (RegExMatch(r, '"admin1":"([^"]*)"', &ma) ? JsonTexto(ma[1]) : "")
        cand := {lat: la[1], lon: lo[1], nombre: nom}
        if !elegido
            elegido := cand
        if (filtro != "" && InStr(donde, filtro)) {
            elegido := cand
            break
        }
        if (filtro = "")
            break
    }
    if !elegido {
        w.datos := 0
        w.estadoTxt := "No encontré «" w.extra "»"
        ClimaDibujar(w)
        return
    }
    try IniWrite(elegido.lat "|" elegido.lon "|" elegido.nombre, CFG, "ClimaCiudades", StrLower(Trim(w.extra)))
    w.lugar := elegido.nombre
    ClimaPronostico(w, elegido.lat, elegido.lon)
}

ClimaPronosticoListo(w, texto) {
    d := ClimaLeer(texto)
    if !d {
        ClimaFallo(w, "No entendí la respuesta del clima")
        return
    }
    w.datos := d, w.hora := FormatTime(, "HH:mm"), w.estadoTxt := ""
    ClimaDibujar(w)
}

; Si falla, se reintenta en 5 minutos (y si habia datos, se siguen mostrando)
ClimaFallo(w, mensaje) {
    w.estadoTxt := mensaje
    ClimaDibujar(w)
    SetTimer(ClimaReintento, -300000)
}

ClimaLeer(texto) {
    if !RegExMatch(texto, '"current":\{([^}]*)\}', &c)
        return 0
    if !RegExMatch(texto, '"daily":\{([^}]*)\}', &dy)
        return 0
    cur := c[1], diario := dy[1]
    temp := JsonNum(cur, "temperature_2m")
    if (temp = "")
        return 0
    sens := JsonNum(cur, "apparent_temperature")
    esDia := JsonNum(cur, "is_day")
    d := {temp: temp, sens: sens = "" ? temp : sens, hum: JsonNum(cur, "relative_humidity_2m"), codigo: JsonNum(cur, "weather_code"), esDia: esDia != 0, dias: []}
    fechas := JsonLista(diario, "time"), cods := JsonLista(diario, "weather_code")
    maxs := JsonLista(diario, "temperature_2m_max"), mins := JsonLista(diario, "temperature_2m_min")
    lluvia := JsonLista(diario, "precipitation_probability_max")
    loop fechas.Length {
        i := A_Index
        d.dias.Push({fecha: StrReplace(Trim(fechas[i], '" '), "-"), codigo: ValorEn(cods, i)
            , max: Redondo(ValorEn(maxs, i)), min: Redondo(ValorEn(mins, i)), lluvia: ValorEn(lluvia, i)})
    }
    return d
}

JsonNum(src, campo) => RegExMatch(src, '"' campo '":(-?[\d.]+)', &m) ? m[1] + 0 : ""
JsonLista(src, campo) => RegExMatch(src, '"' campo '":\[([^\]]*)\]', &m) ? StrSplit(m[1], ",") : []
ValorEn(lista, i) => (i <= lista.Length && IsNumber(Trim(lista[i]))) ? Trim(lista[i]) + 0 : ""
Redondo(v) => (v = "") ? "—" : Round(v)

JsonTexto(s) {
    while RegExMatch(s, "\\u([0-9a-fA-F]{4})", &cod)
        s := StrReplace(s, cod[0], Chr(Integer("0x" cod[1])))
    return StrReplace(s, '\"', '"')
}

TextoUtf8(req) {
    try {
        cuerpo := req.ResponseBody
        psa := ComObjValue(cuerpo)
        datos := NumGet(psa, 8 + A_PtrSize, "Ptr")
        largo := NumGet(psa, 8 + 2 * A_PtrSize, "UInt")
        return StrGet(datos, largo, "UTF-8")
    }
    return req.ResponseText
}

UrlCodificar(s) {
    buf := Buffer(StrPut(s, "UTF-8"))
    StrPut(s, buf, "UTF-8")
    out := ""
    loop buf.Size - 1 {
        c := NumGet(buf, A_Index - 1, "UChar")
        if ((c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c = 45 || c = 46 || c = 95 || c = 126)
            out .= Chr(c)
        else
            out .= Format("%{:02X}", c)
    }
    return out
}

TipoClima(c) {
    c := IsNumber(c) ? Integer(c) : 3
    if (c <= 1)
        return "despejado"
    if (c = 2)
        return "parcial"
    if (c = 3)
        return "nublado"
    if (c = 45 || c = 48)
        return "niebla"
    if (c >= 95)
        return "tormenta"
    if ((c >= 71 && c <= 77) || c = 85 || c = 86)
        return "nieve"
    return "lluvia"
}

DescripcionClima(c) {
    static t := Map(0, "Despejado", 1, "Mayormente despejado", 2, "Parcialmente nublado", 3, "Nublado"
        , 45, "Niebla", 48, "Niebla con escarcha", 51, "Llovizna ligera", 53, "Llovizna", 55, "Llovizna fuerte"
        , 56, "Llovizna helada", 57, "Llovizna helada", 61, "Lluvia ligera", 63, "Lluvia", 65, "Lluvia fuerte"
        , 66, "Lluvia helada", 67, "Lluvia helada", 71, "Nevada ligera", 73, "Nevada", 75, "Nevada fuerte"
        , 77, "Granizo fino", 80, "Chubascos", 81, "Chubascos", 82, "Chubascos fuertes", 85, "Nevadas"
        , 86, "Nevadas fuertes", 95, "Tormenta", 96, "Tormenta con granizo", 99, "Tormenta con granizo")
    c := IsNumber(c) ? Integer(c) : -1
    return t.Has(c) ? t[c] : "—"
}

ClimaDibujar(w) {
    st := w.st, k := st.k, gfx := st.gfx, fo := Fuentes(k)
    pad := 16 * k, GRIS := 0xFF8B8B93, BLANCO := 0xFFF4F4F5, SUAVE := 0xFFA1A1AA
    FondoWidget(st)
    lugar := (w.lugar != "") ? w.lugar : w.extra
    DibujarTexto(gfx, Chr(0xE707), pad - 1 * k, 11 * k, 18 * k, 18 * k, fo.ico, 0xFF60A5FA, fo.izq)
    DibujarTexto(gfx, StrUpper(lugar), pad + 20 * k, 11 * k, st.ancho - 2 * pad - 100 * k, 18 * k, fo.tit, GRIS, fo.izq)
    d := w.datos
    if (d && w.estadoTxt != "")
        DibujarTexto(gfx, "sin conexión", st.ancho - pad - 90 * k, 11 * k, 90 * k, 18 * k, fo.tit, 0xFFFBBF24, fo.der)
    else if (w.hora != "")
        DibujarTexto(gfx, w.hora, st.ancho - pad - 60 * k, 11 * k, 60 * k, 18 * k, fo.tit, 0xFF5B5B63, fo.der)
    if !d {
        DibujarTexto(gfx, w.estadoTxt, pad, 40 * k, st.ancho - 2 * pad, st.alto - 56 * k, fo.lbl, GRIS, fo.cen)
        MostrarCapa(st)
        return
    }
    IconoClima(gfx, d.codigo, pad, 38 * k, 46 * k, d.esDia)
    DibujarTexto(gfx, Round(d.temp) "°", pad + 54 * k, 30 * k, 92 * k, 52 * k, fo.reloj, BLANCO, fo.izq)
    hoy := d.dias.Length ? d.dias[1] : 0
    x2 := pad + 148 * k, w2 := st.ancho - pad - x2
    DibujarTexto(gfx, "Sensación  " Round(d.sens) "°", x2, 36 * k, w2, 16 * k, fo.sub, SUAVE, fo.izq)
    DibujarTexto(gfx, "Humedad  " (d.hum = "" ? "—" : d.hum "%"), x2, 52 * k, w2, 16 * k, fo.sub, SUAVE, fo.izq)
    if (hoy && hoy.lluvia != "")
        DibujarTexto(gfx, "Lluvia  " hoy.lluvia "%", x2, 68 * k, w2, 16 * k, fo.sub, 0xFF60A5FA, fo.izq)
    desc := DescripcionClima(d.codigo) (hoy ? "   ·   " hoy.max "° / " hoy.min "°" : "")
    DibujarTexto(gfx, desc, pad, 88 * k, st.ancho - 2 * pad, 18 * k, fo.lbl, 0xFFD4D4D8, fo.izq)
    LineaW(gfx, pad, 114 * k, st.ancho - pad, 114 * k, 0x14FFFFFF, 1)
    col := (st.ancho - 2 * pad) / 3
    loop Min(3, d.dias.Length - 1) {
        dd := d.dias[A_Index + 1], cx := pad + (A_Index - 1) * col
        nom := "—"
        try nom := Mayuscula(RTrim(FormatTime(dd.fecha, "ddd"), "."))
        DibujarTexto(gfx, nom, cx, 120 * k, col, 16 * k, fo.sub, GRIS, fo.cen)
        IconoClima(gfx, dd.codigo, cx + (col - 22 * k) / 2, 138 * k, 22 * k, true)
        DibujarTexto(gfx, dd.max "°  " dd.min "°", cx, 162 * k, col, 16 * k, fo.sub, BLANCO, fo.cen)
    }
    MostrarCapa(st)
}

; ---------------- Iconos del clima dibujados a mano ----------------
IconoClima(gfx, codigo, x, y, s, esDia := true) {
    tipo := TipoClima(codigo)
    NUBE := 0xFFE4E4E7, GRIS := 0xFFA1A1AA, AGUA := 0xFF60A5FA
    switch tipo {
        case "despejado":
            if esDia
                DibujarSol(gfx, x, y, s)
            else
                DibujarLuna(gfx, x, y, s)
        case "parcial":
            if esDia
                DibujarSol(gfx, x + s * 0.32, y - s * 0.02, s * 0.62)
            else
                DibujarLuna(gfx, x + s * 0.34, y, s * 0.6)
            DibujarNube(gfx, x, y + s * 0.30, s * 0.86, NUBE)
        case "nublado":
            DibujarNube(gfx, x + s * 0.24, y + s * 0.08, s * 0.72, GRIS)
            DibujarNube(gfx, x, y + s * 0.26, s * 0.86, NUBE)
        case "niebla":
            DibujarNube(gfx, x + s * 0.08, y + s * 0.02, s * 0.84, GRIS)
            loop 3
                LineaW(gfx, x + s * (A_Index = 2 ? 0.16 : 0.06), y + s * (0.54 + 0.14 * A_Index), x + s * (A_Index = 2 ? 0.94 : 0.84), y + s * (0.54 + 0.14 * A_Index), NUBE, Max(1.5, s * 0.06))
        default:      ; lluvia, nieve, tormenta
            DibujarNube(gfx, x, y + s * 0.02, s, tipo = "tormenta" ? GRIS : NUBE)
            if (tipo = "lluvia") {
                loop 3
                    LineaW(gfx, x + s * (0.30 + 0.22 * (A_Index - 1)), y + s * 0.72, x + s * (0.24 + 0.22 * (A_Index - 1)), y + s * 0.92, AGUA, Max(1.5, s * 0.07))
            } else if (tipo = "nieve") {
                loop 3
                    CirculoW(gfx, x + s * (0.22 + 0.22 * (A_Index - 1)), y + s * (A_Index = 2 ? 0.82 : 0.72), s * 0.11, 0xFFFFFFFF)
            } else {
                rayo := [[0.52, 0.56], [0.36, 0.80], [0.50, 0.80], [0.42, 1.0], [0.66, 0.70], [0.52, 0.70], [0.60, 0.56]]
                pts := Buffer(8 * rayo.Length)
                for i, p in rayo
                    NumPut("Float", x + s * p[1], pts, (i - 1) * 8), NumPut("Float", y + s * p[2], pts, (i - 1) * 8 + 4)
                br := Pincel(0xFFFBBF24)
                DllCall("gdiplus\GdipFillPolygon", "Ptr", gfx, "Ptr", br, "Ptr", pts, "Int", rayo.Length, "Int", 0)
                BorrarPincel(br)
            }
    }
}

DibujarSol(gfx, x, y, s) {
    c := 0xFFFBBF24, cx := x + s / 2, cy := y + s / 2
    loop 8 {
        ang := (A_Index - 1) * 0.785398
        LineaW(gfx, cx + Cos(ang) * s * 0.34, cy + Sin(ang) * s * 0.34, cx + Cos(ang) * s * 0.47, cy + Sin(ang) * s * 0.47, c, Max(1.5, s * 0.07))
    }
    CirculoW(gfx, cx - s * 0.24, cy - s * 0.24, s * 0.48, c)
}

DibujarLuna(gfx, x, y, s) {
    d := s * 0.62, x0 := x + (s - d) / 2, y0 := y + (s - d) / 2
    CirculoW(gfx, x0, y0, d, 0xFFE5E7EB)
    CirculoW(gfx, x0 + d * 0.34, y0 - d * 0.14, d * 0.84, 0xFF131316)
}

DibujarNube(gfx, x, y, s, color) {
    CirculoW(gfx, x + s * 0.10, y + s * 0.20, s * 0.40, color)
    CirculoW(gfx, x + s * 0.34, y + s * 0.02, s * 0.50, color)
    RedondeadoW(gfx, x, y + s * 0.30, s, s * 0.30, s * 0.15, color)
}

; =====================================================================
;  NOTAS RAPIDAS  (se guardan solas en notas.txt)
; =====================================================================
AbrirNotas(w) {
    static listo := false
    if !listo {
        OnMessage(0x201, NotasClic)          ; arrastrar desde la barra de arriba
        OnMessage(0x232, NotasMovida)        ; recordar donde la dejaste
        OnExit((*) => GuardarNotas())
        listo := true
    }
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        MonitorGetWorkArea(w.mon, &l, &t)
        k := DpiMonitor(l, t) / 96
        ancho := Round(300 * k), alto := Round(260 * k), cab := Round(34 * k), ic := Round(36 * k)
        pos := 0
        g0 := StrSplit(IniRead(CFG, "Widgets", "notas_xy", ""), ",")
        if (g0.Length = 4 && g0[3] = w.mon && g0[4] = w.esquina && IsInteger(g0[1]) && IsInteger(g0[2]))
            if DllCall("MonitorFromPoint", "Int64", (Integer(g0[2]) << 32) | (Integer(g0[1]) & 0xFFFFFFFF), "UInt", 0, "Ptr")
                pos := {x: Integer(g0[1]), y: Integer(g0[2])}
        if !pos
            pos := PosicionWidget(w.mon, w.esquina, ancho, alto, k, "notas")
        fs := Max(8, Round(10 * k * 96 / A_ScreenDPI))
        g := Gui((w.extra = "No" ? "" : "+AlwaysOnTop ") "-Caption +ToolWindow -DPIScale", "Notas · DeckLibre")
        g.BackColor := C_PANEL
        g.MarginX := 0, g.MarginY := 0
        g.SetFont("s" fs " w400 c3B82F6", "Segoe MDL2 Assets")
        icono := g.Add("Text", Format("x0 y0 w{} h{} +0x200 Center Background1C1C20", ic, cab), Chr(0xE70B))
        g.SetFont("s" Max(7, fs - 2) " w700 c" C_MUTED, "Segoe UI")
        titulo := g.Add("Text", Format("x{} y0 w{} h{} +0x200 Background1C1C20", ic, ancho - ic - cab, cab), "NOTAS")
        g.SetFont("s" Max(7, fs - 1) " w400 c" C_MUTED, "Segoe MDL2 Assets")
        cerrar := g.Add("Text", Format("x{} y0 w{} h{} +0x200 Center Background1C1C20", ancho - cab, cab, cab), Chr(0xE711))
        cerrar.OnEvent("Click", (*) => CerrarWidget("notas"))
        g.SetFont("s" fs " w400 c" C_TXT, "Segoe UI")
        m := Round(12 * k)
        ed := g.Add("Edit", Format("x{} y{} w{} h{} -E0x200 +Multi +WantTab Background{}", m, cab + Round(8 * k), ancho - 2 * m, alto - cab - Round(16 * k), C_PANEL))
        try ed.Value := FileExist(ARCHIVO_NOTAS) ? FileRead(ARCHIVO_NOTAS, "UTF-8") : ""
        ed.OnEvent("Change", (*) => SetTimer(GuardarNotas, -800))
        Tema(ed)
        g.OnEvent("Escape", (*) => CerrarWidget("notas"))
        w.gui := g, w.edit := ed, w.arrastre := Map(g.Hwnd, 1, icono.Hwnd, 1, titulo.Hwnd, 1)
        g.Show(Format("{}x{} y{} w{} h{}", w.activar ? "" : "NA ", pos.x, pos.y, ancho, alto))
        try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 33, "Int*", 2, "Int", 4)          ; esquinas redondeadas (Win 11)
        try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 34, "Int*", 0x403A3A, "Int", 4)   ; borde gris oscuro
        w.rect := {x: pos.x, y: pos.y, w: ancho, h: alto}
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

NotasClic(wParam, lParam, msg, hwnd) {
    if !gWidgets.Has("notas")
        return
    w := gWidgets["notas"]
    if (w.gui && w.HasOwnProp("arrastre") && w.arrastre.Has(hwnd)) {
        PostMessage(0xA1, 2, 0, , "ahk_id " w.gui.Hwnd)      ; mover como si fuera la barra de titulo
        return 0
    }
}

NotasMovida(wParam, lParam, msg, hwnd) {
    if !gWidgets.Has("notas")
        return
    w := gWidgets["notas"]
    if !(w.gui && hwnd = w.gui.Hwnd)
        return
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        WinGetPos(&x, &y, &an, &al, "ahk_id " hwnd)
        w.rect := {x: x, y: y, w: an, h: al}
        IniWrite(x "," y "," w.mon "," w.esquina, CFG, "Widgets", "notas_xy")
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

GuardarNotas() {
    if !(gWidgets.Has("notas") && gWidgets["notas"].HasOwnProp("edit"))
        return
    try {
        f := FileOpen(ARCHIVO_NOTAS, "w", "UTF-8")
        f.Write(gWidgets["notas"].edit.Value)
        f.Close()
    }
}
