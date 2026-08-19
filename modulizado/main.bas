' ============================================================
'
'                        main.bas
'
'                 RAYCASTING ZX SPECTRUM
'
' ============================================================
#include "config.bas"
#include "map.bas"
#include "player.bas"
#include "raycaster.bas"
#include "initscreen.bas"

' ============================================================
'   INICIALIZACION
' ============================================================
InitScreen()
InitMap()
InitRayTable()

' ============================================================
'   POSICION INICIAL (jugador)
' ============================================================
playerX = 2 * TILE + TILE / 2
playerY = 4 * TILE + TILE / 2

' ============================================================
'   ORIENTACION INICIAL --> 0 = mirando hacia la derecha
' ============================================================
playerAngle = 0

' ============================================================
'   CALCULAR SIN/COS INICIAL
' ============================================================
UpdatePlayerTrig()

' ============================================================
'   CONF. PANTALLA (bright, border, paper, ink y Clear Screen)
' ============================================================
BRIGHT tonoPared
BORDER 0
PAPER 0
INK colorInk
CLS

' ============================================================
'   BUCLE PRINCIPAL
' 
' ============================================================
DO
    MovePlayer()

    IF modo3d > 0 THEN
        Render()
    ELSE
        Render2D()
    END IF

LOOP UNTIL key$ = CHR$(27)

END


