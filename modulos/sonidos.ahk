; =====================================================================
;  DeckLibre  ·  sonidos.ahk
;  Sonidos por el microfono (VB-CABLE)
; =====================================================================

; =====================================================================
;  SONIDOS POR EL MICROFONO (con VB-CABLE)
;  El sonido se reproduce en "CABLE Input" (lo oyen tus amigos) y, si
;  quieres, tambien en tu salida normal (lo oyes tu). Los archivos se
;  decodifican con Media Foundation de Windows (mp3, wav, m4a, wma, flac).
; =====================================================================
RutaSonido(p) {
    p := Trim(p, ' "')
    if (p = "")
        return ""
    if (!InStr(p, ":") && FileExist(CARPETA_SONIDOS "\" p))
        return CARPETA_SONIDOS "\" p
    return FileExist(p) ? p : ""
}

ListaSonidos() {
    arr := ["(Detener todos los sonidos)"]
    if DirExist(CARPETA_SONIDOS) {
        loop files CARPETA_SONIDOS "\*.*" {
            if RegExMatch(A_LoopFileExt, "i)^(mp3|wav|m4a|wma|aac|flac)$")
                arr.Push(A_LoopFileName)
        }
    }
    return arr
}

; Convierte el archivo a PCM (en memoria). Devuelve {pcm, fmt}
DecodificarAudio(ruta) {
    static listo := false
    if !listo {
        DllCall("LoadLibrary", "Str", "mfplat", "Ptr")
        DllCall("LoadLibrary", "Str", "mfreadwrite", "Ptr")
        DllCall("mfplat\MFStartup", "UInt", 0x00020070, "UInt", 0)
        listo := true
    }
    AUDIO1 := 0xFFFFFFFD                                   ; primer stream de audio
    rd := 0
    hr := DllCall("mfreadwrite\MFCreateSourceReaderFromURL", "WStr", ruta, "Ptr", 0, "Ptr*", &rd, "UInt")
    if (hr != 0 || !rd)
        throw Error("No pude abrir el audio (" Format("0x{:08X}", hr) ")")
    rd := ComValue(13, rd)
    ComCall(4, rd, "UInt", 0xFFFFFFFE, "Int", 0)           ; SetStreamSelection(todos, no)
    ComCall(4, rd, "UInt", AUDIO1, "Int", 1)               ; SetStreamSelection(audio, si)

    mt := 0
    DllCall("mfplat\MFCreateMediaType", "Ptr*", &mt)
    mt := ComValue(13, mt)
    ComCall(24, mt, "Ptr", GuidBuf("{48EBA18E-F8C9-4687-BF11-0A74C9F96A8F}"), "Ptr", GuidBuf("{73647561-0000-0010-8000-00AA00389B71}"))   ; tipo = audio
    ComCall(24, mt, "Ptr", GuidBuf("{F7E34C9A-42E8-4714-B74B-CB29D72C35E5}"), "Ptr", GuidBuf("{00000001-0000-0010-8000-00AA00389B71}"))   ; subtipo = PCM
    ComCall(21, mt, "Ptr", GuidBuf("{F2DEB57F-40FA-4764-AA33-ED4F2D1FF669}"), "UInt", 16)                                                  ; 16 bits
    ComCall(7, rd, "UInt", AUDIO1, "Ptr", 0, "Ptr", mt)    ; SetCurrentMediaType

    cur := 0
    ComCall(6, rd, "UInt", AUDIO1, "Ptr*", &cur)           ; GetCurrentMediaType
    cur := ComValue(13, cur)
    pwf := 0, cb := 0
    DllCall("mfplat\MFCreateWaveFormatExFromMFMediaType", "Ptr", cur, "Ptr*", &pwf, "UInt*", &cb, "UInt", 0, "HRESULT")
    fmt := Buffer(Max(cb, 18), 0)
    DllCall("RtlMoveMemory", "Ptr", fmt, "Ptr", pwf, "UPtr", cb)
    DllCall("ole32\CoTaskMemFree", "Ptr", pwf)

    pcm := Buffer(1 << 20), usado := 0
    loop {
        idx := 0, banderas := 0, ts := 0, smp := 0
        ComCall(9, rd, "UInt", AUDIO1, "UInt", 0, "UInt*", &idx, "UInt*", &banderas, "Int64*", &ts, "Ptr*", &smp)   ; ReadSample
        if smp {
            smp := ComValue(13, smp)
            mb := 0
            ComCall(41, smp, "Ptr*", &mb)                  ; ConvertToContiguousBuffer
            mb := ComValue(13, mb)
            pDatos := 0, maxL := 0, largo := 0
            ComCall(3, mb, "Ptr*", &pDatos, "UInt*", &maxL, "UInt*", &largo)   ; Lock
            if (usado + largo > pcm.Size)
                pcm.Size := Max(pcm.Size * 2, usado + largo)
            DllCall("RtlMoveMemory", "Ptr", pcm.Ptr + usado, "Ptr", pDatos, "UPtr", largo)
            usado += largo
            ComCall(4, mb)                                 ; Unlock
        }
        if ((banderas & 3) || A_Index > 200000)            ; fin del archivo o error
            break
    }
    pcm.Size := Max(usado, 4)
    return {pcm: pcm, fmt: fmt}
}

; Busca el dispositivo "CABLE Input" de VB-CABLE. -1 si no esta instalado
DispositivoCable() {
    caps := Buffer(84, 0)
    loop DllCall("winmm\waveOutGetNumDevs", "UInt") {
        id := A_Index - 1
        if (DllCall("winmm\waveOutGetDevCapsW", "UPtr", id, "Ptr", caps, "UInt", 84, "UInt") = 0)
            if InStr(StrGet(caps.Ptr + 8, 32, "UTF-16"), "CABLE Input")
                return id
    }
    return -1
}

; Reproduce el PCM en un dispositivo (-1 = salida predeterminada)
ReproducirEn(datos, dispositivo, vol) {
    h := 0
    if (DllCall("winmm\waveOutOpen", "Ptr*", &h, "UInt", dispositivo, "Ptr", datos.fmt, "UPtr", 0, "UPtr", 0, "UInt", 0, "UInt") != 0)
        return 0
    v := Round(0xFFFF * vol / 100)
    DllCall("winmm\waveOutSetVolume", "Ptr", h, "UInt", (v << 16) | v)
    tam := (A_PtrSize = 8) ? 48 : 32
    hdr := Buffer(tam, 0)
    NumPut("Ptr", datos.pcm.Ptr, hdr, 0)
    NumPut("UInt", datos.pcm.Size, hdr, A_PtrSize)
    DllCall("winmm\waveOutPrepareHeader", "Ptr", h, "Ptr", hdr, "UInt", tam)
    DllCall("winmm\waveOutWrite", "Ptr", h, "Ptr", hdr, "UInt", tam)
    return {h: h, hdr: hdr, datos: datos}
}

CerrarSonido(s) {
    DllCall("winmm\waveOutReset", "Ptr", s.h)
    DllCall("winmm\waveOutUnprepareHeader", "Ptr", s.h, "Ptr", s.hdr, "UInt", s.hdr.Size)
    DllCall("winmm\waveOutClose", "Ptr", s.h)
}

; Cierra los sonidos que ya terminaron (solo corre mientras algo suena)
RevisarSonidos() {
    global gReproduciendo
    pos := (A_PtrSize = 8) ? 24 : 16                      ; WAVEHDR.dwFlags
    quedan := []
    for s in gReproduciendo {
        if (NumGet(s.hdr, pos, "UInt") & 1)                ; WHDR_DONE
            CerrarSonido(s)
        else
            quedan.Push(s)
    }
    gReproduciendo := quedan
    if !quedan.Length
        SetTimer(RevisarSonidos, 0)
}

DetenerSonidos() {
    global gReproduciendo
    for s in gReproduciendo
        CerrarSonido(s)
    gReproduciendo := []
    SetTimer(RevisarSonidos, 0)
}

ReproducirSonido(a) {
    global gReproduciendo
    if InStr(a.p1, "Detener todos") {
        DetenerSonidos()
        OSD("Sonidos detenidos", , , Chr(0xE71A))
        return
    }
    ruta := RutaSonido(a.p1)
    if (ruta = "") {
        OSD("No encontré el sonido: " a.p1, , "FBBF24", Chr(0xE783))
        return
    }
    SplitPath(ruta, , , , &nombre)

    ; Si ese sonido ya esta sonando, la misma tecla lo corta
    cortado := false, quedan := []
    for s in gReproduciendo {
        if (s.clave = ruta) {
            CerrarSonido(s)
            cortado := true
        } else
            quedan.Push(s)
    }
    gReproduciendo := quedan
    if cortado {
        OSD(nombre "  ·  detenido", , "F472B6", Chr(0xE71A))
        return
    }

    if !gSonidos.Has(ruta)
        gSonidos[ruta] := DecodificarAudio(ruta)
    datos := gSonidos[ruta]
    vol := IsNumber(a.p2) ? Max(0, Min(100, Number(a.p2))) : 80

    cable := DispositivoCable()
    if (cable >= 0) {
        if (s := ReproducirEn(datos, cable, vol)) {
            s.clave := ruta
            gReproduciendo.Push(s)
        }
    }
    if (a.p3 != "No" || cable < 0) {                       ; sin cable, al menos lo oyes tu
        if (s := ReproducirEn(datos, -1, vol)) {
            s.clave := ruta
            gReproduciendo.Push(s)
        }
    }
    SetTimer(RevisarSonidos, 100)
    if (cable < 0)
        OSD("Falta VB-CABLE  ·  solo lo oyes tú", , "FBBF24", Chr(0xE783))
    else
        OSD(nombre, , "F472B6", Chr(0xE8D6))
}

AbrirCarpetaSonidos(*) {
    DirCreate(CARPETA_SONIDOS)
    Run(CARPETA_SONIDOS)
}
