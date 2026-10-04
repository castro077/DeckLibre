; =====================================================================
;  DeckLibre  ·  audio.ahk
;  Volumen por programa, microfono, salidas de audio y diagnostico
; =====================================================================

; =====================================================================
;  VOLUMEN POR PROGRAMA (directo con el audio de Windows, sin programas
;  externos: es instantaneo y funciona al mantener la tecla)
; =====================================================================
GuidBuf(s) {
    b := Buffer(16)
    DllCall("ole32\CLSIDFromString", "Str", s, "Ptr", b)
    return b
}

; Devuelve los controles de volumen (ISimpleAudioVolume) de todas las
; sesiones de audio de ese .exe, en todas las salidas de sonido activas
SesionesDeApp(exe) {
    static IID_MGR2 := GuidBuf("{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}")
    vols := []
    exe := Trim(exe)
    procs := MapaProcesos()
    enum := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    col := 0
    ComCall(3, enum, "Int", 0, "UInt", 1, "Ptr*", &col)          ; EnumAudioEndpoints(render, activos)
    col := ComValue(13, col)
    nDev := 0
    ComCall(3, col, "UInt*", &nDev)
    loop nDev {
        dev := 0, mgr := 0, se := 0, n := 0
        ComCall(4, col, "UInt", A_Index - 1, "Ptr*", &dev)
        dev := ComValue(13, dev)
        try ComCall(3, dev, "Ptr", IID_MGR2, "UInt", 23, "Ptr", 0, "Ptr*", &mgr)   ; Activate
        if !mgr
            continue
        mgr := ComValue(13, mgr)
        try {
            ComCall(5, mgr, "Ptr*", &se)                              ; GetSessionEnumerator
            se := ComValue(13, se)
            ComCall(3, se, "Int*", &n)
        } catch
            continue
        loop n {
            ctl := 0, pid := 0, c2 := 0
            try {
                ComCall(4, se, "Int", A_Index - 1, "Ptr*", &ctl)
                ctl := ComValue(13, ctl)
                c2 := ComObjQuery(ctl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
                ComCall(14, c2, "UInt*", &pid)                         ; GetProcessId
            }
            if (!pid || !c2)
                continue
            if !EsDeApp(pid, exe, procs)     ; el proceso o alguno de sus "padres"
                continue
            try vols.Push(ComObjQuery(c2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"))
        }
    }
    return vols
}

; Sube/baja el volumen del programa. Devuelve el % nuevo o "" si no esta sonando
VolumenApp(exe, cambio) {
    vols := SesionesDeApp(exe)
    if !vols.Length
        return ""
    v := 0.0
    ComCall(4, vols[1], "Float*", &v)                                 ; GetMasterVolume
    paso := Number(cambio) / 100
    nuevo := Max(0.0, Min(1.0, v + paso))
    for sv in vols {
        ComCall(3, sv, "Float", nuevo, "Ptr", 0)                      ; SetMasterVolume
        if (paso > 0)
            ComCall(5, sv, "Int", 0, "Ptr", 0)                        ; al subir, quita el silencio
    }
    return Round(nuevo * 100)
}

; Silencia / activa. Devuelve {mute, pct} o "" si no esta sonando
SilencioApp(exe) {
    vols := SesionesDeApp(exe)
    if !vols.Length
        return ""
    m := 0, v := 0.0
    ComCall(6, vols[1], "Int*", &m)                                   ; GetMute
    ComCall(4, vols[1], "Float*", &v)
    for sv in vols
        ComCall(5, sv, "Int", !m, "Ptr", 0)                           ; SetMute
    return {mute: !m, pct: Round(v * 100)}
}

AvisoNoSuena(exe) {
    OSD(NombreBonito(exe) "  ·  no está sonando", , "FBBF24", Chr(0xE7BA))
    try DiagnosticoAudio(exe, "(no encontro sesiones)")
}

; Muchas apps (Tauri, WebView2, algunas Electron) no reproducen el sonido
; desde su propio .exe sino desde un proceso hijo (ej: msedgewebview2.exe).
; Por eso se revisa el proceso y toda su cadena de padres.
EsDeApp(pid, exe, procs) {
    loop 8 {
        if !procs.Has(pid)
            return false
        info := procs[pid]
        if (info.nombre = exe)
            return true
        if (info.padre = 0 || info.padre = pid)
            return false
        pid := info.padre
    }
    return false
}

; Lista de procesos: pid -> {padre, nombre}
MapaProcesos() {
    m := Map()
    x64 := (A_PtrSize = 8)
    tam := x64 ? 568 : 556
    pe := Buffer(tam, 0)
    NumPut("UInt", tam, pe, 0)
    snap := DllCall("CreateToolhelp32Snapshot", "UInt", 2, "UInt", 0, "Ptr")
    if (snap = -1)
        return m
    if DllCall("Process32FirstW", "Ptr", snap, "Ptr", pe) {
        loop {
            id := NumGet(pe, 8, "UInt")
            padre := NumGet(pe, x64 ? 32 : 24, "UInt")
            m[id] := {padre: padre, nombre: StrGet(pe.Ptr + (x64 ? 44 : 36), "UTF-16")}
        } until !DllCall("Process32NextW", "Ptr", snap, "Ptr", pe)
    }
    DllCall("CloseHandle", "Ptr", snap)
    return m
}

; =====================================================================
;  DIAGNOSTICO DE AUDIO: escribe diagnostico_audio.txt con todas las
;  sesiones de sonido que ve Windows (para saber por que no encuentra
;  un programa)
; =====================================================================
DiagnosticoAudio(exe := "", nota := "") {
    txt := "Diagnostico de audio  " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
    txt .= "Buscando: [" exe "]   " nota "`n"
    txt .= "AutoHotkey " A_AhkVersion "  " (A_PtrSize * 8) "-bit`n"
    procs := MapaProcesos()
    txt .= "Procesos leidos: " procs.Count "`n"
    enum := 0, col := 0, nDev := 0
    try {
        enum := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        ComCall(3, enum, "Int", 0, "UInt", 1, "Ptr*", &col)
        col := ComValue(13, col)
        ComCall(3, col, "UInt*", &nDev)
        txt .= "Salidas de audio activas: " nDev "`n"
    } catch as e {
        txt .= "FALLO al leer las salidas de audio: " e.Message "`n"
    }
    iid := GuidBuf("{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}")
    loop nDev {
        d := A_Index
        dev := 0, mgr := 0, se := 0, n := 0
        try {
            ComCall(4, col, "UInt", d - 1, "Ptr*", &dev)
            dev := ComValue(13, dev)
            ComCall(3, dev, "Ptr", iid, "UInt", 23, "Ptr", 0, "Ptr*", &mgr)
            mgr := ComValue(13, mgr)
            ComCall(5, mgr, "Ptr*", &se)
            se := ComValue(13, se)
            ComCall(3, se, "Int*", &n)
            txt .= "`n== Salida " d ": " n " sesiones`n"
        } catch as e {
            txt .= "`n== Salida " d ": FALLO " e.Message "`n"
            continue
        }
        loop n {
            ctl := 0, pid := 0, c2 := 0, dn := 0
            linea := "  #" A_Index ": "
            try {
                ComCall(4, se, "Int", A_Index - 1, "Ptr*", &ctl)
                ctl := ComValue(13, ctl)
            } catch as e {
                txt .= linea "FALLO GetSession: " e.Message "`n"
                continue
            }
            try {
                c2 := ComObjQuery(ctl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
                ComCall(14, c2, "UInt*", &pid)
            } catch as e {
                linea .= "[FALLO pid: " e.Message "] "
            }
            linea .= "pid=" pid "  " CadenaProcesos(pid, procs)
            try {
                ComCall(4, ctl, "Ptr*", &dn)
                if dn {
                    linea .= "  nombre='" StrGet(dn, "UTF-16") "'"
                    DllCall("ole32\CoTaskMemFree", "Ptr", dn)
                }
            }
            try {
                sv := ComObjQuery(ctl, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
                v := 0.0
                ComCall(4, sv, "Float*", &v)
                linea .= "  vol=" Round(v * 100) "%"
            } catch as e {
                linea .= "  [FALLO volumen: " e.Message "]"
            }
            if (exe != "" && EsDeApp(pid, exe, procs))
                linea .= "   <== COINCIDE"
            txt .= linea "`n"
        }
    }
    archivo := A_ScriptDir "\diagnostico_audio.txt"
    try FileDelete(archivo)
    FileAppend(txt, archivo, "UTF-8")
    return archivo
}

CadenaProcesos(pid, procs) {
    t := ""
    loop 8 {
        if !procs.Has(pid)
            break
        t .= (t = "" ? "" : "  <-  ") procs[pid].nombre
        if (procs[pid].padre = 0 || procs[pid].padre = pid)
            break
        pid := procs[pid].padre
    }
    return t
}

AbrirDiagnostico(*) {
    Run(DiagnosticoAudio("", "(desde el menu)"))
}

; =====================================================================
;  DISPOSITIVOS DE AUDIO (directo con Windows)
; =====================================================================
EnumeradorAudio() => ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

IdDispositivo(dev) {
    p := 0
    ComCall(5, dev, "Ptr*", &p)                       ; IMMDevice::GetId
    s := StrGet(p, "UTF-16")
    DllCall("ole32\CoTaskMemFree", "Ptr", p)
    return s
}

PKeyNombre() {
    clave := Buffer(20, 0)
    DllCall("ole32\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "Ptr", clave)
    NumPut("UInt", 14, clave, 16)                     ; PKEY_Device_FriendlyName
    return clave
}

NombreDispositivo(dev) {
    static PKEY := PKeyNombre()
    ps := 0
    ComCall(4, dev, "UInt", 0, "Ptr*", &ps)           ; OpenPropertyStore(lectura)
    ps := ComValue(13, ps)
    pv := Buffer(24, 0)
    ComCall(5, ps, "Ptr", PKEY, "Ptr", pv)            ; IPropertyStore::GetValue
    nombre := ""
    if (NumGet(pv, 0, "UShort") = 31)                 ; VT_LPWSTR
        nombre := StrGet(NumGet(pv, 8, "Ptr"), "UTF-16")
    DllCall("ole32\PropVariantClear", "Ptr", pv)
    return nombre
}

; Salidas de sonido activas: [{id, nombre}, ...]
ListaSalidas() {
    out := []
    col := 0, n := 0
    ComCall(3, EnumeradorAudio(), "Int", 0, "UInt", 1, "Ptr*", &col)
    col := ComValue(13, col)
    ComCall(3, col, "UInt*", &n)
    loop n {
        dev := 0
        ComCall(4, col, "UInt", A_Index - 1, "Ptr*", &dev)
        dev := ComValue(13, dev)
        try out.Push({id: IdDispositivo(dev), nombre: NombreDispositivo(dev)})
    }
    return out
}

NombresSalidas() {
    arr := ["Siguiente (todas)"]
    try {
        for s in ListaSalidas()
            arr.Push(s.nombre)
    }
    return arr
}

SalidaActual() {
    dev := 0
    try ComCall(4, EnumeradorAudio(), "Int", 0, "Int", 0, "Ptr*", &dev)
    if !dev
        return ""
    dev := ComValue(13, dev)
    return IdDispositivo(dev)
}

; IPolicyConfig: la interfaz que usa Windows para cambiar la salida predeterminada
PonerSalida(id) {
    pc := ComObject("{870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    for rol in [0, 1, 2]                              ; consola, multimedia, comunicaciones
        ComCall(13, pc, "WStr", id, "Int", rol)       ; SetDefaultEndpoint
}

; destino: "Siguiente (todas)", un nombre, o varios separados con "/"
CambiarSalida(destino) {
    lista := ListaSalidas()
    if !lista.Length {
        OSD("No hay salidas de audio", , "FBBF24", Chr(0xE767))
        return
    }
    destino := Trim(destino)
    candidatos := []
    if (destino = "" || InStr(destino, "Siguiente")) {
        candidatos := lista
    } else {
        usados := Map()
        for parte in StrSplit(destino, "/") {
            parte := Trim(parte)
            if (parte = "")
                continue
            for s in lista {
                if (InStr(s.nombre, parte) && !usados.Has(s.id)) {
                    usados[s.id] := true
                    candidatos.Push(s)
                }
            }
        }
    }
    if !candidatos.Length {
        OSD("No encontré la salida: " destino, , "FBBF24", Chr(0xE767))
        return
    }
    actual := SalidaActual()
    idx := 0
    for i, s in candidatos
        if (s.id = actual)
            idx := i
    elegida := candidatos[Mod(idx, candidatos.Length) + 1]
    PonerSalida(elegida.id)
    OSD(elegida.nombre, , "22D3EE", Chr(0xE767))
}

; ---------------- Microfono ----------------
; Microfono predeterminado (y el de comunicaciones, si es otro)
MicDispositivos() {
    static IID_AEV := GuidBuf("{5CDF2C82-841E-4546-9722-0CF74078229A}")   ; IAudioEndpointVolume
    enum := EnumeradorAudio()
    lista := [], vistos := Map()
    for rol in [0, 2] {
        dev := 0
        try ComCall(4, enum, "Int", 1, "Int", rol, "Ptr*", &dev)          ; captura
        if !dev
            continue
        dev := ComValue(13, dev)
        id := IdDispositivo(dev)
        if vistos.Has(id)
            continue
        vistos[id] := true
        aev := 0
        ComCall(3, dev, "Ptr", IID_AEV, "UInt", 23, "Ptr", 0, "Ptr*", &aev)
        lista.Push(ComValue(13, aev))
    }
    return lista
}

; Devuelve 1 si quedo silenciado, 0 si quedo activo, "" si no hay microfono
MicAlternar() {
    eps := MicDispositivos()
    if !eps.Length
        return ""
    m := 0
    ComCall(15, eps[1], "Int*", &m)                   ; GetMute
    nuevo := m ? 0 : 1
    for e in eps
        ComCall(14, e, "Int", nuevo, "Ptr", 0)        ; SetMute
    return nuevo
}
