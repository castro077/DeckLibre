; =====================================================================
;  DeckLibre  ·  temporizador.ahk
;  Pomodoro, temporizador y cronometro con una tarjeta pequena en pantalla
; =====================================================================

TemporizadorAccion(a) {
    global gTimer
    modo := InStr(a.p1, "Pomodoro") ? "pomodoro" : InStr(a.p1, "Cronómetro") ? "cronometro" : InStr(a.p1, "Detener") ? "detener" : InStr(a.p1, "Pausar") ? "pausa" : "temporizador"
    if (modo = "detener") {
        DetenerTimer(true)
        return
    }
    if (modo = "pausa" || (gTimer && gTimer.modo = modo)) {   ; la misma tecla pausa y sigue
        PausarTimer()
        return
    }
    minutos := IsNumber(a.p2) ? Number(a.p2) : (modo = "pomodoro" ? 25 : 10)
    IniciarTimer(modo, minutos, a.p3 = "" ? "Arriba centro" : a.p3)
}

IniciarTimer(modo, minutos, esquina) {
    global gTimer
    DetenerTimer()
    gTimer := {modo: modo, fase: (modo = "pomodoro") ? "enfoque" : "", total: minutos * 60000, enfoque: minutos * 60000
        , transcurrido: 0, ultimo: A_TickCount, pausado: false, ciclos: 0, capa: 0, aviso: 0}
    GdipIniciar()
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        k := DpiMonitor(l, t) / 96
        ancho := Round(236 * k), alto := Round(64 * k), m := Round(16 * k)
        pos := PosicionWidget(MonitorGetPrimary(), esquina, ancho, alto, k), x := pos.x, y := pos.y
        st := CrearCapa(x, y, ancho, alto)
        st.k := k
        gTimer.capa := st
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
    SetTimer(TimerTick, 1000)
    DibujarTimer()
    texto := (modo = "pomodoro") ? "Pomodoro  ·  enfoque " minutos " min" : (modo = "cronometro") ? "Cronómetro iniciado" : "Temporizador  ·  " minutos " min"
    OSD(texto, , "60A5FA", Chr(0xE823))
}

PausarTimer() {
    if !gTimer
        return
    if gTimer.pausado {
        gTimer.pausado := false
        gTimer.ultimo := A_TickCount
        OSD("Sigue", , "60A5FA", Chr(0xE768))
    } else {
        TimerAvanzar()
        gTimer.pausado := true
        OSD("En pausa", , "8B8B93", Chr(0xE769))
    }
    DibujarTimer()
}

DetenerTimer(avisar := false) {
    global gTimer
    SetTimer(TimerTick, 0)
    if !gTimer
        return
    if gTimer.capa
        CerrarCapa(gTimer.capa)
    gTimer := 0
    if avisar
        OSD("Temporizador detenido", , "8B8B93", Chr(0xE71A))
}

TimerAvanzar() {
    if gTimer.pausado
        return
    ahora := A_TickCount
    gTimer.transcurrido += ahora - gTimer.ultimo
    gTimer.ultimo := ahora
}

TimerTick() {
    if !gTimer
        return
    TimerAvanzar()
    if (gTimer.modo != "cronometro" && gTimer.transcurrido >= gTimer.total) {
        TimerTermino()
        if !gTimer
            return
    }
    DibujarTimer()
}

TimerTermino() {
    if (gTimer.modo = "temporizador") {
        loop 3
            SoundBeep(880, 140), Sleep(80)
        OSD("¡Se acabó el tiempo!", , "FBBF24", Chr(0xE823), 5000, true)
        DetenerTimer()
        return
    }
    ; Pomodoro: enfoque -> descanso (cada 4, descanso largo) -> enfoque...
    if (gTimer.fase = "enfoque") {
        gTimer.ciclos += 1
        largo := (Mod(gTimer.ciclos, 4) = 0)
        gTimer.fase := "descanso"
        gTimer.total := (largo ? 15 : 5) * 60000
        SoundBeep(660, 150), SoundBeep(880, 200)
        OSD("Descanso de " (largo ? 15 : 5) " min  ·  ciclo " gTimer.ciclos, , "34D399", Chr(0xE823), 5000, true)
    } else {
        gTimer.fase := "enfoque"
        gTimer.total := gTimer.enfoque
        SoundBeep(880, 150), SoundBeep(660, 200)
        OSD("A enfocarse  ·  " Round(gTimer.enfoque / 60000) " min", , "60A5FA", Chr(0xE823), 5000, true)
    }
    gTimer.transcurrido := 0
    gTimer.ultimo := A_TickCount
}

FmtTiempo(ms) {
    s := Max(0, ms) // 1000
    h := s // 3600, mi := Mod(s // 60, 60), se := Mod(s, 60)
    return h ? Format("{}:{:02}:{:02}", h, mi, se) : Format("{:02}:{:02}", mi, se)
}

DibujarTimer() {
    if (!gTimer || !gTimer.capa)
        return
    st := gTimer.capa, k := st.k, gfx := st.gfx, fo := Fuentes(k)
    if gTimer.pausado
        color := 0xFF8B8B93
    else if (gTimer.fase = "descanso")
        color := 0xFF34D399
    else if (gTimer.modo = "cronometro")
        color := 0xFFA78BFA
    else
        color := 0xFF60A5FA
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", gfx, "UInt", 0)
    ruta := RutaRedondeada(0.5, 0.5, st.ancho - 1, st.alto - 1, (st.alto - 1) / 2)
    br := Pincel(0xF2131316)
    DllCall("gdiplus\GdipFillPath", "Ptr", gfx, "Ptr", br, "Ptr", ruta)
    BorrarPincel(br)
    pe := Lapiz(0x24FFFFFF, 1)
    DllCall("gdiplus\GdipDrawPath", "Ptr", gfx, "Ptr", pe, "Ptr", ruta)
    BorrarLapiz(pe)
    DllCall("gdiplus\GdipDeletePath", "Ptr", ruta)

    ; anillo de progreso
    cx := 14 * k, cy := 12 * k, dd := 40 * k
    pe := Lapiz(0x26FFFFFF, 4 * k)
    DllCall("gdiplus\GdipDrawEllipse", "Ptr", gfx, "Ptr", pe, "Float", cx, "Float", cy, "Float", dd, "Float", dd)
    BorrarLapiz(pe)
    if (gTimer.modo = "cronometro")
        frac := Mod(gTimer.transcurrido // 1000, 60) / 60
    else
        frac := Max(0, Min(1, 1 - gTimer.transcurrido / gTimer.total))
    if (frac > 0) {
        pe := Lapiz(color, 4 * k)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pe, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pe, "Int", 2)
        DllCall("gdiplus\GdipDrawArc", "Ptr", gfx, "Ptr", pe, "Float", cx, "Float", cy, "Float", dd, "Float", dd, "Float", -90, "Float", 360 * frac)
        BorrarLapiz(pe)
    }

    if (gTimer.modo = "pomodoro")
        etiqueta := (gTimer.fase = "descanso" ? "DESCANSO" : "ENFOQUE") "  ·  ciclo " (gTimer.ciclos + (gTimer.fase = "enfoque" ? 1 : 0))
    else
        etiqueta := (gTimer.modo = "cronometro") ? "CRONÓMETRO" : "TEMPORIZADOR"
    if gTimer.pausado
        etiqueta .= "  ·  PAUSA"
    tiempo := (gTimer.modo = "cronometro") ? FmtTiempo(gTimer.transcurrido) : FmtTiempo(gTimer.total - gTimer.transcurrido + 999)
    DibujarTexto(gfx, etiqueta, 66 * k, 9 * k, 160 * k, 16 * k, fo.tit, 0xFF8B8B93, fo.izq)
    DibujarTexto(gfx, tiempo, 66 * k, 24 * k, 160 * k, 30 * k, fo.val, 0xFFF4F4F5, fo.izq)
    MostrarCapa(st)
}
