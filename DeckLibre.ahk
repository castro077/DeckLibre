#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; =====================================================================
;  DeckLibre - convierte cualquier teclado (el de la laptop, uno USB,
;  un numpad...) en una botonera
;  (tipo Stream Deck) usando AutoHotInterception.
;
;  - Clic derecho en el icono de la bandeja > Configurar...
;  - Ctrl + Alt + F12 (desde cualquier teclado) cambia el modo
;  - La configuracion se guarda sola en DeckLibre.ini
; =====================================================================

#Include "Lib\AutoHotInterception.ahk"

global APP := "DeckLibre"
global CFG := A_ScriptDir "\DeckLibre.ini"

global AHI := AutoHotInterception()

global gBotoneraId := 0          ; ID de Interception del teclado botonera
global gPrincipalHandle := ""        ; Handle del teclado principal, con el que escribes (para el modo automatico)
global gAuto := 1              ; 1 = cambia de modo solo al conectar/desconectar el principal
global gOSD := 1               ; 1 = muestra el indicador en pantalla
global gModo := "botonera"     ; "botonera" o "normal"
global gKeys := Map()          ; scancode -> {acciones, mantener, doble, nombre}
global gSubs := []             ; teclas suscritas en este momento
global gSubsId := 0
global gPressed := Map()
global gPrincipalPresente := -1
global gCapturando := false
global gDetect := 0
global gCaptura := 0

; GUI
global gCfgGui := 0
global ui := {}
global gSel := 0
global gCargandoNombre := false
global gPildora := 0
global gEnCurso := Map()
global gRec := 0, gPdh := 0, gCpuPrev := 0, gHist := Map()
global gHoja := 0, gTeclaActual := 0
global gSonidos := Map(), gReproduciendo := []
global CARPETA_SONIDOS := A_ScriptDir "\Sonidos"
global CARPETA_RESPALDOS := A_ScriptDir "\Respaldos"
global gUltimoRespaldo := 0, gRespGui := 0
global gBateria := 1, gBatAviso := 0
global gGestos := Map(), gLista := "acciones"
global UMBRAL_MANTENER := 420, UMBRAL_DOBLE := 250
global gPerfiles := Map(), gPerfilActivo := "", gEditPerfil := "", gEfectivo := Map()
global gClips := [], gIgnorarClip := 0, gClipGui := 0, gClipDestino := 0
global gTimer := 0, gTecHover := 0, gPresion := Map(), gWidgets := Map()
global ARCHIVO_NOTAS := A_ScriptDir "\notas.txt"
global gHoverMap := Map(), gHover := 0, gApagados := Map()
global C_BG := "18181B", C_PANEL := "232327", C_KEY := "2E2E33", C_KEYTXT := "A1A1AA"
global C_TXT := "F4F4F5", C_MUTED := "8B8B93", C_ACC := "3B82F6", C_LINE := "2E2E33"

#Include "%A_LineFile%\..\modulos\datos.ahk"

; =====================================================================
;  ARRANQUE
; =====================================================================
OnError(AlErrorGeneral)
MigrarNombreViejo()
CargarConfig()
ResolverBotonera()
ConfigurarTray()
try DirCreate(CARPETA_SONIDOS)
Registrar("DeckLibre iniciado" (A_IsAdmin ? " (como administrador)" : ""), "INFO")
HacerRespaldo(true)
SetTimer(RevisarBateria, 60000)
SetTimer(() => RevisarBateria(), -8000)   ; primera revision al arrancar

if !gBotoneraId {
    MsgBox("Bienvenido a DeckLibre.`n`nPrimero hay que elegir qué teclado será tu botonera (el de la laptop, uno USB, un numpad…).`nCierra este mensaje y presiona cualquier tecla de ESE teclado.", APP, "Iconi")
    DetectarTeclado("botonera", PrimerArranqueListo)
} else {
    AplicarSuscripciones()
    OSD("DeckLibre listo", , , Chr(0xE765))
}
RevisarPrincipal()
OnMessage(0x219, AlCambiarDispositivos)   ; WM_DEVICECHANGE: conectaste o desconectaste algo
SetTimer(RevisarPrincipal, 30000)          ; respaldo por si Windows no avisa
IniciarPerfiles()
IniciarPortapapeles()
SetTimer(RestaurarWidgets, -1200)          ; vuelven los widgets que dejaste abiertos

PrimerArranqueListo() {
    OSD("Teclado botonera detectado", , "4ADE80", Chr(0xE765))
    AbrirConfig()
}

; Cambiar de modo desde cualquier teclado
^!F12:: AlternarModo()

; =====================================================================
;  MODULOS (carpeta modulos)
; =====================================================================
#Include "%A_LineFile%\..\modulos\config.ahk"
#Include "%A_LineFile%\..\modulos\teclados.ahk"
#Include "%A_LineFile%\..\modulos\acciones.ahk"
#Include "%A_LineFile%\..\modulos\perfiles.ahk"
#Include "%A_LineFile%\..\modulos\ventanas.ahk"
#Include "%A_LineFile%\..\modulos\espacios.ahk"
#Include "%A_LineFile%\..\modulos\apps.ahk"
#Include "%A_LineFile%\..\modulos\audio.ahk"
#Include "%A_LineFile%\..\modulos\sonidos.ahk"
#Include "%A_LineFile%\..\modulos\portapapeles.ahk"
#Include "%A_LineFile%\..\modulos\edicion.ahk"
#Include "%A_LineFile%\..\modulos\temporizador.ahk"
#Include "%A_LineFile%\..\modulos\widgets.ahk"
#Include "%A_LineFile%\..\modulos\indicador.ahk"
#Include "%A_LineFile%\..\modulos\graficos.ahk"
#Include "%A_LineFile%\..\modulos\recursos.ahk"
#Include "%A_LineFile%\..\modulos\hoja.ahk"
#Include "%A_LineFile%\..\modulos\sistema.ahk"
#Include "%A_LineFile%\..\modulos\registro.ahk"
#Include "%A_LineFile%\..\modulos\estilo.ahk"
#Include "%A_LineFile%\..\modulos\interfaz.ahk"
