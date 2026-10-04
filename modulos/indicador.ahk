; =====================================================================
;  DeckLibre  ·  indicador.ahk
;  Indicador en pantalla (pildora)
; =====================================================================

; =====================================================================
;  INDICADOR EN PANTALLA (pildora con barra)
; =====================================================================
OSD(texto, pct := "", color := "", icono := "", duracion := 1500, forzar := false) {
    global gPildora
    if (!gOSD && !forzar)
        return
    W := 340, H := 78, BW := 254
    if !gPildora {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := "18181B"
        g.MarginX := 0, g.MarginY := 0
        g.SetFont("s20", "Segoe MDL2 Assets")
        ico := g.Add("Text", "x18 y0 w40 h" H " +0x200 Center Background18181B", "")
        g.SetFont("s11 w600 cF4F4F5", "Segoe UI")
        tit := g.Add("Text", "x68 y16 w180 h24 +0x80 +0x4000 Background18181B", "")
        g.SetFont("s17 w700 cF4F4F5", "Segoe UI")
        pc := g.Add("Text", "x248 y8 w74 h36 +0x200 Right Background18181B", "")
        track := g.Add("Text", "x68 y50 w" BW " h6 Background34343A")
        fill := g.Add("Text", "x68 y50 w10 h6 Background3B82F6")
        gPildora := {g: g, ico: ico, tit: tit, pct: pc, track: track, fill: fill, alpha: 0, visible: false, region: false}
    }
    acento := (color != "") ? color : "3B82F6"
    if (icono = "")
        icono := (pct != "") ? IconoVolumen(pct) : Chr(0xE946)
    gPildora.ico.SetFont("c" acento)
    gPildora.ico.Text := icono
    gPildora.tit.Text := texto
    conBarra := (pct != "")
    gPildora.pct.Visible := conBarra
    gPildora.track.Visible := conBarra
    gPildora.fill.Visible := conBarra && pct > 0
    if conBarra {
        gPildora.tit.Move(, 16, 180)
        gPildora.pct.Text := pct "%"
        gPildora.fill.Opt("Background" acento)
        gPildora.fill.Move(, , Max(4, Round(BW * pct / 100)))
        gPildora.fill.Redraw()
    } else {
        gPildora.tit.Move(, 27, BW)
    }

    esc := A_ScreenDPI / 96
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    x := l + ((r - l) - Round(W * esc)) // 2
    y := b - Round((H + 60) * esc)

    SetTimer(OsdPasoSalida, 0)
    if !gPildora.visible {
        WinSetTransparent(0, gPildora.g.Hwnd)
        gPildora.g.Show("NA x" x " y" y " w" W " h" H)
        if !gPildora.region {
            WinSetRegion("0-0 w" Round(W * esc) " h" Round(H * esc) " R" Round(30 * esc) "-" Round(30 * esc), gPildora.g.Hwnd)
            gPildora.region := true
        }
        for a in [70, 140, 200]
            WinSetTransparent(a, gPildora.g.Hwnd), Sleep(12)
        gPildora.visible := true
    }
    gPildora.alpha := 242
    WinSetTransparent(gPildora.alpha, gPildora.g.Hwnd)
    SetTimer(OsdIniciarSalida, -duracion)
}

IconoVolumen(p) => Chr(p = 0 ? 0xE992 : p < 34 ? 0xE993 : p < 67 ? 0xE994 : 0xE995)

OsdIniciarSalida() => SetTimer(OsdPasoSalida, 25)

OsdPasoSalida() {
    if !gPildora
        return
    gPildora.alpha -= 30
    if (gPildora.alpha <= 0) {
        SetTimer(OsdPasoSalida, 0)
        gPildora.g.Hide()
        gPildora.visible := false
        return
    }
    WinSetTransparent(gPildora.alpha, gPildora.g.Hwnd)
}

NombreBonito(exe) {
    static conocidos := Map("obs64.exe", "OBS", "msedge.exe", "Edge", "code.exe", "VS Code", "chrome.exe", "Chrome", "spotify.exe", "Spotify", "discord.exe", "Discord", "vlc.exe", "VLC", "firefox.exe", "Firefox")
    e := StrLower(Trim(exe))
    if conocidos.Has(e)
        return conocidos[e]
    n := RegExReplace(Trim(exe), "i)\.exe$")
    return StrUpper(SubStr(n, 1, 1)) SubStr(n, 2)
}
