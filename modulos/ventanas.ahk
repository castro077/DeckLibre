; =====================================================================
;  DeckLibre  ·  ventanas.ahk
;  Abrir programas, mover ventanas entre pantallas
; =====================================================================

Abrir(a) {
    destino := Trim(a.p1)
    if (destino = "")
        return
    mon := IsNumber(a.p2) ? Integer(a.p2) : 0
    traer := (a.p3 != "Abrir otro")

    ; Nombre del .exe (sirve tambien con accesos directos .lnk)
    ruta := Trim(destino, '"')
    if (SubStr(ruta, -4) = ".lnk" && FileExist(ruta)) {
        FileGetShortcut(ruta, &objetivo)
        ruta := objetivo
    }
    exe := ""
    if (SubStr(ruta, -4) = ".exe")
        SplitPath(ruta, &exe)

    hwnd := 0
    if (exe != "" && traer)
        hwnd := BuscarVentana(exe, Map())
    if hwnd {
        if (WinGetMinMax(hwnd) = -1)
            WinRestore(hwnd)
        WinActivate(hwnd)
    } else {
        ; Ventanas que ya existian, para reconocer la NUEVA
        antes := Map()
        if (exe != "")
            for h in WinGetList("ahk_exe " exe)
                antes[h] := true
        SplitPath(Trim(destino, '"'), , &dir)
        Run(destino, (dir != "" && DirExist(dir)) ? dir : "")   ; carpeta de trabajo (OBS la necesita)
        if (exe = "" || mon = 0)
            return
        hwnd := EsperarVentana(exe, antes, 15)
        if !hwnd
            hwnd := BuscarVentana(exe, Map())   ; algunas apps reutilizan su ventana
        if !hwnd
            return
        EsperarQuieta(hwnd)   ; deja que el programa termine de acomodarse solo
    }
    if (mon > 0)
        MoverAMonitor(hwnd, mon)
}

; Ventana "de verdad" (no tooltips, splash ni ventanas invisibles)
EsVentanaPrincipal(h) {
    try {
        if (WinGetTitle(h) = "")
            return false
        if (WinGetClass(h) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")   ; escritorio y barra de tareas
            return false
        if (WinGetExStyle(h) & 0x80)          ; WS_EX_TOOLWINDOW
            return false
        WinGetPos(, , &w, &hh, h)
        return (w >= 300 && hh >= 200) || WinGetMinMax(h) != 0
    }
    return false
}

BuscarVentana(exe, ignorar) {
    for h in WinGetList("ahk_exe " exe)
        if (!ignorar.Has(h) && EsVentanaPrincipal(h))
            return h
    return 0
}

EsperarVentana(exe, ignorar, segundos) {
    fin := A_TickCount + segundos * 1000
    while (A_TickCount < fin) {
        if (h := BuscarVentana(exe, ignorar))
            return h
        Sleep(150)
    }
    return 0
}

; Espera a que la ventana deje de moverse (max ~3 s)
EsperarQuieta(hwnd) {
    ultimo := "", quieta := 0
    loop 30 {
        try {
            WinGetPos(&x, &y, &w, &h, hwnd)
            s := x "," y "," w "," h "," WinGetMinMax(hwnd)
        } catch
            return
        if (s = ultimo) {
            if (++quieta >= 4)
                return
        } else {
            quieta := 0, ultimo := s
        }
        Sleep(100)
    }
}

MonitorDeVentana(hwnd) {
    try WinGetPos(&x, &y, &w, &h, hwnd)
    catch
        return 0
    cx := x + w // 2, cy := y + h // 2
    loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (cx >= l && cx < r && cy >= t && cy < b)
            return A_Index
    }
    return 0
}

; Mueve y revisa; si el programa se devolvio solo, lo intenta otra vez.
; Se hace en modo "DPI por monitor" porque la pantalla de la laptop suele
; tener otra escala (125% / 150%) y eso descuadra las coordenadas.
MoverAMonitor(hwnd, n) {
    if (n > MonitorGetCount())
        return
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        MonitorGetWorkArea(n, &l, &t, &r, &b)
        loop 3 {
            if (WinGetMinMax(hwnd) != 0)
                WinRestore(hwnd)
            WinMove(l + 40, t + 40, (r - l) - 80, (b - t) - 80, hwnd)
            Sleep(150)
            WinMaximize(hwnd)
            Sleep(400)
            if (MonitorDeVentana(hwnd) = n)
                break
        }
        ; Plan B: el atajo de Windows Win+Shift+Flecha, que siempre respeta la escala
        if (MonitorDeVentana(hwnd) != n) {
            WinActivate(hwnd)
            WinWaitActive(hwnd, , 2)
            loop MonitorGetCount() {
                actual := MonitorDeVentana(hwnd)
                if (actual = n || actual = 0)
                    break
                MonitorGet(actual, &al)
                MonitorGet(n, &nl)
                Send(nl < al ? "#+{Left}" : "#+{Right}")
                Sleep(400)
            }
        }
        WinActivate(hwnd)
    }
    if viejo
        DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
}

; Muestra un numero grande en cada pantalla (la numeracion que usa DeckLibre)
IdentificarPantallas(*) {
    guis := []
    loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := "1F2937"
        g.SetFont("s72 bold cFFFFFF", "Segoe UI")
        g.Add("Text", "w200 Center", A_Index)
        g.Show("NA x" (l + ((r - l) - 240) // 2) " y" (t + ((b - t) - 160) // 2))
        guis.Push(g)
    }
    Sleep(2500)
    for g in guis
        g.Destroy()
}

ListaProcesos() {
    vistos := Map()
    vistos.CaseSense := false
    for n in ["chrome.exe", "msedge.exe", "firefox.exe", "Spotify.exe", "Discord.exe", "obs64.exe", "vlc.exe"]
        vistos[n] := n
    for hwnd in WinGetList() {
        try {
            n := WinGetProcessName(hwnd)
            if (n != "" && n != "explorer.exe" && n != "AutoHotkey64.exe")
                vistos[n] := n
        }
    }
    txt := ""
    for k, n in vistos
        txt .= n "`n"
    txt := Sort(RTrim(txt, "`n"))
    return StrSplit(txt, "`n")
}

; =====================================================================
;  MOVER LA VENTANA ACTIVA A OTRA PANTALLA
; =====================================================================
MoverVentanaActiva(destino) {
    hwnd := WinExist("A")
    if !hwnd
        return
    cls := WinGetClass(hwnd)
    if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd")
        return
    total := MonitorGetCount()
    if (total < 2) {
        OSD("Solo hay una pantalla", , "FBBF24", Chr(0xE7F4))
        return
    }
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    n := 0
    try {
        actual := MonitorDeVentana(hwnd)
        n := IsNumber(destino) ? Integer(destino) : Mod(Max(actual, 1), total) + 1
        if (n >= 1 && n <= total && n != actual) {
            ; Win+Shift+Flecha: Windows mueve la ventana respetando escala y si esta maximizada
            loop total {
                act := MonitorDeVentana(hwnd)
                if (act = n || act = 0)
                    break
                MonitorGet(act, &al)
                MonitorGet(n, &nl)
                WinActivate(hwnd)
                Send(nl < al ? "#+{Left}" : "#+{Right}")
                Sleep(250)
            }
        }
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
    if n
        try OSD(NombreBonito(WinGetProcessName(hwnd)) "  →  Pantalla " n, , , Chr(0xE7F4))
}

; =====================================================================
;  ACOMODAR LA VENTANA ACTIVA (mitades, tercios, cuartos, centrar)
; =====================================================================
AcomodarVentana(modo) {
    static zonas := Map("Mitad izquierda", [0, 0, 1/2, 1], "Mitad derecha", [1/2, 0, 1/2, 1]
        , "Mitad arriba", [0, 0, 1, 1/2], "Mitad abajo", [0, 1/2, 1, 1/2]
        , "Tercio izquierdo", [0, 0, 1/3, 1], "Tercio central", [1/3, 0, 1/3, 1], "Tercio derecho", [2/3, 0, 1/3, 1]
        , "Dos tercios izquierda", [0, 0, 2/3, 1], "Dos tercios derecha", [1/3, 0, 2/3, 1]
        , "Cuarto arriba izquierda", [0, 0, 1/2, 1/2], "Cuarto arriba derecha", [1/2, 0, 1/2, 1/2]
        , "Cuarto abajo izquierda", [0, 1/2, 1/2, 1/2], "Cuarto abajo derecha", [1/2, 1/2, 1/2, 1/2])
    hwnd := WinExist("A")
    if !hwnd
        return
    if (WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")
        return
    if InStr(modo, "Minimizar") {
        WinMinimize(hwnd)
        return
    }
    if InStr(modo, "Maximizar") {
        if (WinGetMinMax(hwnd) = 1)
            WinRestore(hwnd)
        else
            WinMaximize(hwnd)
        return
    }
    viejo := DllCall("SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    try {
        n := MonitorDeVentana(hwnd)
        if !n
            n := MonitorGetPrimary()
        MonitorGetWorkArea(n, &l, &t, &r, &b)
        ancho := r - l, alto := b - t
        if (WinGetMinMax(hwnd) != 0)
            WinRestore(hwnd)
        if (modo = "Centrar") {
            WinGetPos(, , &cw, &ch, hwnd)
            cw := Min(cw, ancho), ch := Min(ch, alto)
            WinMove(l + (ancho - cw) // 2, t + (alto - ch) // 2, cw, ch, hwnd)
        } else if zonas.Has(modo) {
            z := zonas[modo]
            MoverConBordes(hwnd, l + Round(z[1] * ancho), t + Round(z[2] * alto), Round(z[3] * ancho), Round(z[4] * alto))
        }
    } finally {
        if viejo
            DllCall("SetThreadDpiAwarenessContext", "Ptr", viejo, "Ptr")
    }
}

; Windows 10/11 dejan un borde invisible alrededor de las ventanas.
; Se compensa para que queden pegadas al borde de la pantalla y entre si.
MoverConBordes(hwnd, x, y, w, h) {
    rc := Buffer(16, 0), fr := Buffer(16, 0)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", rc)
    bi := 0, ba := 0, bd := 0, bb := 0
    if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", fr, "UInt", 16) = 0) {
        bi := NumGet(fr, 0, "Int") - NumGet(rc, 0, "Int")
        ba := NumGet(fr, 4, "Int") - NumGet(rc, 4, "Int")
        bd := NumGet(rc, 8, "Int") - NumGet(fr, 8, "Int")
        bb := NumGet(rc, 12, "Int") - NumGet(fr, 12, "Int")
    }
    WinMove(x - bi, y - ba, w + bi + bd, h + ba + bb, hwnd)
}
