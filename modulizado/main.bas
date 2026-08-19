REM ============================================================
REM
REM                     MAIN2.BAS
REM
REM                 RAYCASTING ZX SPECTRUM
REM
REM ============================================================
#include "config.bas"
#include "map.bas"
#include "player.bas"
#include "raycaster.bas"

REM ============================================================
REM INICIALIZACION
REM ============================================================
InitMap()
InitRayTable()

REM ============================================================
REM POSICION INICIAL
REM ============================================================
playerX = 2 * TILE + TILE / 2
playerY = 4 * TILE + TILE / 2

REM ============================================================
REM ORIENTACION INICIAL
REM
REM 0 = mirando hacia la derecha
REM ============================================================
playerAngle = 0

REM ============================================================
REM CALCULAR SIN/COS INICIAL
REM ============================================================
UpdatePlayerTrig()

REM ============================================================
REM CONFIGURAR PANTALLA
REM ============================================================
BRIGHT tonoPared
BORDER 0
PAPER 0
INK colorInk
CLS

REM ============================================================
REM BUCLE PRINCIPAL
REM ============================================================
DO
    MovePlayer()
    Render()

LOOP UNTIL key$ = CHR$(27)

END


