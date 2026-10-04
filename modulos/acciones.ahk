; =====================================================================
;  DeckLibre  ·  acciones.ahk
;  Suscripcion de teclas, modos, gestos (mantener / doble toque) y ejecucion de acciones
; =====================================================================

; =====================================================================
;  SUSCRIPCIONES / MODOS
; =====================================================================
AplicarSuscripciones() {
    global gSubs, gSubsId, gPressed
    CalcularEfectivo()
    nuevas := []
    if (gBotoneraId && !gCapturando) {
        for sc, k in gEfectivo {
            if !TieneAcciones(k)
                continue
            if (gModo = "normal" && !TieneModo(k))
                continue
            nuevas.Push(sc)
        }
    }
    ; Si son las mismas teclas (por ejemplo al cambiar de perfil), no se vuelven a suscribir
    if (gSubsId = gBotoneraId && ListaIgual(nuevas, gSubs))
        return
    ; Mismo teclado: solo se quitan las que sobran y se agregan las nuevas
    if (gSubsId && gSubsId = gBotoneraId) {
        nuevoSet := Map(), viejoSet := Map()
        for sc in nuevas
            nuevoSet[sc] := true
        for sc in gSubs {
            viejoSet[sc] := true
            if !nuevoSet.Has(sc)
                try AHI.UnsubscribeKey(gSubsId, sc)
        }
        quedan := []
        for sc in nuevas {
            if viejoSet.Has(sc) {
                quedan.Push(sc)
                continue
            }
            try {
                AHI.SubscribeKey(gBotoneraId, sc, true, AlTeclear.Bind(sc))
                quedan.Push(sc)
            }
        }
        gSubs := quedan
        return
    }
    for sc in gSubs
        try AHI.UnsubscribeKey(gSubsId, sc)
    gSubs := []
    gPressed := Map()
    gSubsId := gBotoneraId
    for sc in nuevas {
        try {
            AHI.SubscribeKey(gBotoneraId, sc, true, AlTeclear.Bind(sc))
            gSubs.Push(sc)
        }
    }
}

ListaIgual(a, b) {
    if (a.Length != b.Length)
        return false
    loop a.Length
        if (a[A_Index] != b[A_Index])
            return false
    return true
}

TieneModo(k) {
    for lista in [k.acciones, k.mantener, k.doble]
        for a in lista
            if (a.t = "modo")
                return true
    return false
}

EsRepetible(k) {
    for a in k.acciones
        if !(a.t = "volgen" || a.t = "volapp" || a.t = "brillo")
            return false
    return true
}

SetModo(m, avisar := true) {
    global gModo
    gModo := m
    AplicarSuscripciones()
    ActualizarTray()
    ActualizarEstadoGui()
    if !avisar
        return
    if (m = "botonera") {
        SoundBeep(850, 100)
        OSD("Modo botonera", , "60A5FA", Chr(0xE765))
    } else {
        SoundBeep(450, 100)
        OSD("Modo normal  ·  la botonera escribe normal", , "FBBF24", Chr(0xE765))
    }
}

AlternarModo(*) => SetModo(gModo = "botonera" ? "normal" : "botonera")

; =====================================================================
;  EJECUCION DE ACCIONES
; =====================================================================
AlTeclear(sc, state) {
    global gPressed
    k := TeclaEfectiva(sc)
    if !k
        return
    if (k.mantener.Length || k.doble.Length) {
        GestoTecla(sc, state)              ; tecla con pulsacion larga o doble toque
        return
    }
    if (state = 1) {
        if !(gPressed.Has(sc) && gPressed[sc])
            gPresion[sc] := A_TickCount
        repetida := gPressed.Has(sc) && gPressed[sc]
        gPressed[sc] := true
        if (repetida && (!EsRepetible(k) || gEnCurso.Has(sc)))
            return
        SetTimer(EjecutarLista.Bind(sc, "acciones"), -1)   ; se ejecuta aparte para no trabar el teclado
    } else {
        gPressed[sc] := false
        if gHoja
            SetTimer(HojaSoltar.Bind(sc), -1)
    }
}

EjecutarTecla(sc) => EjecutarLista(sc, "acciones")

EjecutarAcciones(k, cual := "acciones") {
    lista := ListaDe(k, cual)
    if (cual = "acciones" && k.nombre != "" && lista.Length && !InStr("volgen,volapp,mutegen,muteapp,mic,modo,ventana,recursos,salida,hoja,sonido,acomodar,espacio,portapapeles,temporizador,brillo,sistema,edicion,reloj,calendario,notas,micwidget,clima", lista[1].t))
        OSD(k.nombre, , , Chr(0xE945))
    for a in lista {
        try {
            EjecutarAccion(a)
        } catch as e {
            Registrar("Tecla " KeyLabel(gTeclaActual) " (" NombreLista(cual) ")  ·  " TipoNombre(a.t) (a.p1 != "" ? " [" a.p1 "]" : "") "  ·  " DescribirError(e))
            OSD("Error: " e.Message, , "F87171", Chr(0xE783))
            break
        }
    }
}

Delta(p) {
    p := Trim(p)
    if (p = "")
        p := "+5"
    c := SubStr(p, 1, 1)
    return (c = "+" || c = "-") ? p : "+" p
}

EjecutarAccion(a) {
    switch a.t {
        case "volgen":
            SoundSetMute(false)
            SoundSetVolume(Delta(a.p1))
            OSD("Volumen general", Round(SoundGetVolume()))
        case "mutegen":
            SoundSetMute(-1)
            if SoundGetMute()
                OSD("Sonido silenciado", , "F87171", Chr(0xE74F))
            else
                OSD("Volumen general", Round(SoundGetVolume()))
        case "volapp":
            try {
                pct := VolumenApp(a.p1, Delta(a.p2))
                if (pct = "")
                    AvisoNoSuena(a.p1)
                else
                    OSD(NombreBonito(a.p1), pct)
            } catch as e {
                try DiagnosticoAudio(a.p1, "(error: " e.Message ")")
                Registrar("Volumen de " a.p1 "  ·  " DescribirError(e))
                OSD("Error de audio: " e.Message, , "F87171", Chr(0xE783))
            }
        case "muteapp":
            try
                r := SilencioApp(a.p1)
            catch as e {
                Registrar("Silenciar " a.p1 "  ·  " DescribirError(e))
                OSD("Error de audio: " e.Message, , "F87171", Chr(0xE783))
                return
            }
            if !IsObject(r)
                AvisoNoSuena(a.p1)
            else if r.mute
                OSD(NombreBonito(a.p1) "  ·  silenciado", , "F87171", Chr(0xE74F))
            else
                OSD(NombreBonito(a.p1), r.pct)
        case "mic":
            m := MicAlternar()
            if (m = "")
                OSD("No encontré un micrófono", , "FBBF24", Chr(0xE720))
            else
                OSD(m ? "Micrófono silenciado" : "Micrófono activo", , m ? "F87171" : "4ADE80", Chr(0xE720))
            if gWidgets.Has("micwidget")
                TickMic()
        case "abrir":
            Abrir(a)
        case "recursos":
            AlternarRecursos(a.p1, a.p2)
        case "salida":
            CambiarSalida(a.p1)
        case "hoja":
            HojaPresionar(a.p1)
        case "sonido":
            ReproducirSonido(a)
        case "ventana":
            MoverVentanaActiva(a.p1)
        case "media":
            switch a.p1 {
                case "Siguiente": Send("{Media_Next}"), OSD("Siguiente", , , Chr(0xE893))
                case "Anterior":  Send("{Media_Prev}"), OSD("Anterior", , , Chr(0xE892))
                case "Detener":   Send("{Media_Stop}"), OSD("Detener", , , Chr(0xE71A))
                default:          Send("{Media_Play_Pause}"), OSD("Play / Pausa", , , Chr(0xE768))
            }
        case "atajo":
            if (Trim(a.p2) != "")
                ControlSend(a.p1, , "ahk_exe " Trim(a.p2))
            else
                Send(a.p1)
        case "texto":
            EscribirPlantilla(a)
        case "acomodar":
            AcomodarVentana(a.p1)
        case "espacio":
            EspacioAccion(a)
        case "portapapeles":
            MostrarHistorial()
        case "temporizador":
            TemporizadorAccion(a)
        case "reloj", "calendario", "notas", "micwidget", "clima":
            WidgetAccion(a)
        case "brillo":
            Brillo(a.p1)
        case "sistema":
            AccionSistema(a.p1)
        case "edicion":
            EdicionTexto(a.p1)
        case "esperar":
            Sleep(IsNumber(a.p1) ? Integer(a.p1) : 250)
        case "modo":
            AlternarModo()
    }
}

; =====================================================================
;  TECLAS: listas de acciones (toque, mantener, doble toque)
; =====================================================================
NuevaTecla() => {acciones: [], mantener: [], doble: [], nombre: ""}

TieneAcciones(k) => (k.acciones.Length || k.mantener.Length || k.doble.Length)

ListaDe(k, cual) => (cual = "mantener") ? k.mantener : (cual = "doble") ? k.doble : k.acciones

PrimeraAccion(k) => k.acciones.Length ? k.acciones[1] : k.mantener.Length ? k.mantener[1] : k.doble[1]

NombreLista(cual) => (cual = "mantener") ? "Mantener" : (cual = "doble") ? "Doble toque" : "Toque"

; Ejecuta una de las listas de la tecla
EjecutarLista(sc, cual := "acciones", k := 0) {
    global gTeclaActual
    if !IsObject(k)
        k := TeclaEfectiva(sc)
    if !k
        return
    gTeclaActual := sc
    gEnCurso[sc] := true
    inicio := A_TickCount
    espera := (gPresion.Has(sc) && !k.mantener.Length && !k.doble.Length) ? inicio - gPresion[sc] : 0
    try EjecutarAcciones(k, cual)
    if gEnCurso.Has(sc)
        gEnCurso.Delete(sc)
    ; si algo fue lento, queda anotado en registro.txt para saber que fue
    dura := A_TickCount - inicio
    if (espera > 250 || dura > 1500) {
        lista := ListaDe(k, cual), resumen := ""
        for a in lista
            resumen .= (resumen = "" ? "" : ", ") CortoTipo(a.t)
        Registrar("Tecla " KeyLabel(sc) ": esperó " espera " ms para empezar y tardó " dura " ms  (" resumen ")", "LENTO")
    }
    if gPresion.Has(sc)
        gPresion.Delete(sc)
}

; ---------------------------------------------------------------------
; Pulsacion larga y doble toque. Solo se usa en teclas que tienen
; acciones de "mantener" o "doble"; las demas siguen siendo instantaneas.
; ---------------------------------------------------------------------
GestoTecla(sc, state) {
    k := TeclaEfectiva(sc)
    if !k
        return
    if !gGestos.Has(sc)
        gGestos[sc] := {abajo: false, holdHecho: false, pendiente: false, fnHold: 0, fnTap: 0}
    est := gGestos[sc]
    if (state = 1) {
        if est.abajo                       ; repeticion de la tecla sostenida
            return
        est.abajo := true
        est.holdHecho := false
        if k.mantener.Length {
            est.fnHold := GestoMantener.Bind(sc)
            SetTimer(est.fnHold, -UMBRAL_MANTENER)
        }
        return
    }
    ; --- se solto la tecla ---
    if !est.abajo
        return
    est.abajo := false
    if est.fnHold {
        SetTimer(est.fnHold, 0)
        est.fnHold := 0
    }
    if gHoja
        SetTimer(HojaSoltar.Bind(sc), -1)
    if est.holdHecho                       ; ya se ejecuto "mantener"
        return
    if k.doble.Length {
        if est.pendiente {                 ; segundo toque a tiempo = doble
            SetTimer(est.fnTap, 0)
            est.pendiente := false
            SetTimer(EjecutarLista.Bind(sc, "doble"), -1)
        } else {
            est.pendiente := true
            est.fnTap := GestoToqueSimple.Bind(sc)
            SetTimer(est.fnTap, -UMBRAL_DOBLE)
        }
    } else
        SetTimer(EjecutarLista.Bind(sc, "acciones"), -1)
}

GestoMantener(sc) {
    if !gGestos.Has(sc)
        return
    est := gGestos[sc]
    est.fnHold := 0
    if !est.abajo
        return
    est.holdHecho := true
    EjecutarLista(sc, "mantener")
}

GestoToqueSimple(sc) {
    if !gGestos.Has(sc)
        return
    gGestos[sc].pendiente := false
    EjecutarLista(sc, "acciones")
}
