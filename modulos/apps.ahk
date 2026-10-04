; =====================================================================
;  DeckLibre  ·  apps.ahk
;  Lista de apps para la accion "Abrir": apps y carpetas del sistema
;  (Explorador, Descargas, Configuracion...) y todas las apps instaladas.
; =====================================================================

AppsSistema() {
    static lista := [
        ["Explorador de archivos", "explorer.exe"],
        ["Este equipo", "explorer.exe shell:MyComputerFolder"],
        ["Descargas", "shell:Downloads"],
        ["Documentos", "shell:Personal"],
        ["Escritorio (carpeta)", "shell:Desktop"],
        ["Imágenes", "shell:My Pictures"],
        ["Música", "shell:My Music"],
        ["Videos", "shell:My Video"],
        ["Papelera de reciclaje", "shell:RecycleBinFolder"],
        ["Configuración de Windows", "ms-settings:"],
        ["Configuración de sonido", "ms-settings:sound"],
        ["Configuración de pantalla", "ms-settings:display"],
        ["Bluetooth y dispositivos", "ms-settings:bluetooth"],
        ["Red e Internet", "ms-settings:network"],
        ["Aplicaciones instaladas", "ms-settings:appsfeatures"],
        ["Panel de control", "control.exe"],
        ["Administrador de tareas", "taskmgr.exe"],
        ["Administrador de dispositivos", "devmgmt.msc"],
        ["Mezclador de volumen", "sndvol.exe"],
        ["Sonido (panel clásico)", "mmsys.cpl"],
        ["Calculadora", "calc.exe"],
        ["Bloc de notas", "notepad.exe"],
        ["Paint", "mspaint.exe"],
        ["Recorte de pantalla", "ms-screenclip:"],
        ["Símbolo del sistema (CMD)", "cmd.exe"],
        ["PowerShell", "powershell.exe"],
        ["Ejecutar...", "shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}"]
    ]
    return lista
}

; Todas las apps del menu Inicio (tambien las de la Microsoft Store).
; Se lee una sola vez por sesion.
AppsInstaladas() {
    static cache := 0
    if IsObject(cache)
        return cache
    cache := []
    try {
        carpeta := ComObject("Shell.Application").NameSpace("shell:AppsFolder")
        for it in carpeta.Items() {
            nom := it.Name, ruta := it.Path
            if (nom = "" || ruta = "")
                continue
            if RegExMatch(nom, "i)desinstal|uninstall|readme|léame|release notes")
                continue
            cache.Push([nom, ComandoApp(ruta)])
        }
    } catch as e
        Registrar("No se pudo leer la lista de apps: " DescribirError(e), "AVISO")
    return cache
}

; Si la app es un .exe normal se guarda su ruta (asi se puede mover de pantalla
; y traer al frente). Si es de la Store, se abre con su identificador.
ComandoApp(ruta) {
    r := ResolverRutaApp(ruta)
    if (SubStr(r, -4) = ".exe" && FileExist(r))
        return r
    return "explorer.exe shell:AppsFolder\" ruta
}

ResolverRutaApp(p) {
    static guias := Map("{6D809377-6AF0-444B-8957-A3773F02200E}", EnvGet("ProgramW6432") != "" ? EnvGet("ProgramW6432") : A_ProgramFiles
        , "{7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E}", EnvGet("ProgramFiles(x86)")
        , "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}", A_WinDir "\System32"
        , "{F38BF404-1D43-42F2-9305-67DE0B28FC23}", A_WinDir)
    if (RegExMatch(p, "^(\{[0-9A-Fa-f-]+\})\\(.*)$", &m) && guias.Has(StrUpper(m[1])))
        return guias[StrUpper(m[1])] "\" m[2]
    return p
}

; Nombres para la lista de sugerencias: primero las del sistema, luego las instaladas
ListaAppsNombres() {
    nombres := [], vistos := Map()
    vistos.CaseSense := false
    for par in AppsSistema() {
        nombres.Push(par[1])
        vistos[par[1]] := true
    }
    for par in AppsInstaladas() {
        if vistos.Has(par[1])
            continue
        vistos[par[1]] := true
        nombres.Push(par[1])
    }
    return nombres
}

NombreAComando(nombre) {
    for par in AppsSistema()
        if (par[1] = nombre)
            return par[2]
    for par in AppsInstaladas()
        if (par[1] = nombre)
            return par[2]
    return ""
}

ComandoANombre(cmd) {
    for par in AppsSistema()
        if (par[2] = cmd)
            return par[1]
    if InStr(cmd, "shell:AppsFolder\") {
        for par in AppsInstaladas()
            if (par[2] = cmd)
                return par[1]
    }
    return ""
}

; Para mostrar: el nombre bonito si es una app conocida, si no, el texto tal cual
NombreAppDe(cmd) {
    n := ComandoANombre(cmd)
    return (n != "") ? n : cmd
}
