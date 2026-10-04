; =====================================================================
;  DeckLibre  ·  espacios.ahk
;  Espacios de trabajo: guarda como estan acomodadas las ventanas
;  (programa, pantalla, posicion y tamano) y las vuelve a dejar igual.
; =====================================================================

ListaEspacios() {
    arr := []
    try {
        for sec in StrSplit(IniRead(CFG), "`n")
            if (SubStr(sec, 1, 8) = "Espacio@")
                arr.Push(SubStr(sec, 9))
    }
    return arr
}

VentanasParaEspacio() {
    lista := []
    yo := DllCall("GetCurrentProcessId")
    for h in WinGetList() {
        try {
            if !EsVentanaPrincipal(h)
                continue
            if (WinGetPID(h) = yo)
                continue
            if (WinGetClass(h) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")
                continue
            lista.Push(h)
        }
    }
    return lista
}

GuardarEspacio(nombre) {
    nombre := Trim(StrReplace(nombre, "|", "/"))
    if (nombre = "")
        return
    sec := "Espacio@" nombre
    try IniDelete(CFG, sec)
    n := 0
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        lista := VentanasParaEspacio()
        i := lista.Length
        while (i >= 1) {                               ; de la de atras a la de adelante
            h := lista[i]
            i -= 1
            try {
                exe := WinGetProcessName(h)
                ruta := WinGetProcessPath(h)
                mm := WinGetMinMax(h)
                WinGetPos(&x, &y, &w, &alto, h)
                n += 1
                IniWrite(exe "|" ruta "|" x "|" y "|" w "|" alto "|" mm "|" MonitorDeVentana(h), CFG, sec, n)
            }
            if (n >= 30)
                break
        }
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
    OSD("Espacio «" nombre "» guardado  ·  " n " ventanas", , "34D399", Chr(0xE74E), 1800)
}

RestaurarEspacio(nombre) {
    nombre := Trim(nombre)
    try
        txt := IniRead(CFG, "Espacio@" nombre)
    catch {
        OSD("No existe el espacio «" nombre "»", , "FBBF24", Chr(0xE783))
        return
    }
    OSD("Acomodando «" nombre "»", , "34D399", Chr(0xE74E), 1500)
    usados := Map()
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        loop parse txt, "`n", "`r" {
            p := InStr(A_LoopField, "=")
            if !p
                continue
            f := StrSplit(SubStr(A_LoopField, p + 1), "|")
            if (f.Length < 8)
                continue
            exe := f[1], ruta := f[2]
            h := BuscarVentana(exe, usados)
            if !h {                                    ; no estaba abierto: abrirlo
                if (ruta = "" || !FileExist(ruta) || exe = "ApplicationFrameHost.exe")
                    continue
                antes := Map()
                for v in WinGetList("ahk_exe " exe)
                    antes[v] := true
                for v in usados
                    antes[v] := true
                SplitPath(ruta, , &dir)
                try
                    Run('"' ruta '"', dir)
                catch
                    continue
                h := EsperarVentana(exe, antes, 12)
                if !h
                    continue
                EsperarQuieta(h)
            }
            usados[h] := true
            ColocarVentana(h, Integer(f[3]), Integer(f[4]), Integer(f[5]), Integer(f[6]), Integer(f[7]), Integer(f[8]))
        }
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

ColocarVentana(h, x, y, w, alto, mm, mon) {
    try {
        if (WinGetMinMax(h) != 0)
            WinRestore(h)
        if (mm = 1) {
            if (mon >= 1 && mon <= MonitorGetCount()) {
                MonitorGetWorkArea(mon, &l, &t, &r, &b)
                WinMove(l + 40, t + 40, (r - l) - 80, (b - t) - 80, h)
            }
            WinMaximize(h)
        } else if (mm = -1) {
            WinMinimize(h)
        } else {
            WinMove(x, y, w, alto, h)
        }
    }
}

EspacioAccion(a) {
    if InStr(a.p2, "Guardar")
        GuardarEspacio(a.p1)
    else
        RestaurarEspacio(a.p1)
}

GuardarEspacioMenu(*) {
    r := InputBox("Nombre del espacio de trabajo (por ejemplo: Clase, Diseño, Programar).`nSe guardan las ventanas abiertas ahora mismo.", "Guardar espacio de trabajo", "w360 h150")
    if (r.Result = "OK" && Trim(r.Value) != "")
        GuardarEspacio(r.Value)
}
