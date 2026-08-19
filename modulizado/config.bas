REM ============================================================
REM
REM                    CONFIG.BAS
REM
REM ============================================================
REM CONFIGURACION DE PANTALLA
REM ============================================================
CONST SCREEN_W AS INTEGER = 256
CONST SCREEN_H AS INTEGER = 192

REM ============================================================
REM CONFIGURACION DEL RAYCASTER
REM ============================================================
CONST NUM_RAYS AS INTEGER = 64
CONST RAY_WIDTH AS INTEGER = 4

REM ============================================================
REM CONFIGURACION DEL MAPA
REM ============================================================
CONST MAP_W AS INTEGER = 10
CONST MAP_H AS INTEGER = 8

CONST TILE AS INTEGER = 16

REM ============================================================
REM FIXED POINT 8.8
REM
REM 256 = 1.0
REM 128 = 0.5
REM 512 = 2.0
REM ============================================================
CONST FP AS INTEGER = 256

REM ============================================================
REM CAMPO DE VISION
REM ============================================================
CONST FOV AS FLOAT = PI / 3

REM ============================================================
REM MOVIMIENTO
REM ============================================================
CONST MOVE_SPEED AS INTEGER = 2

REM ============================================================
REM PROYECCION
REM
REM Aproximadamente:
REM
REM     focal = (SCREEN_W / 2) / TAN(FOV / 2)
REM
REM para FOV = 60 grados:
REM
REM     focal ~= 221
REM
REM ============================================================
CONST FOCAL_LENGTH AS INTEGER = 221

REM ============================================================
REM MAPA
REM ============================================================
DIM world(79) AS UBYTE

REM ============================================================
REM JUGADOR
REM ============================================================
DIM playerX AS LONG
DIM playerY AS LONG

DIM playerAngle AS FLOAT

REM ------------------------------------------------------------
REM SENO Y COSENO EN FIXED POINT
REM
REM 256 = 1.0
REM ------------------------------------------------------------
DIM playerSin AS INTEGER
DIM playerCos AS INTEGER

REM ============================================================
REM TABLA DE DIRECCIONES DE LOS RAYOS
REM ============================================================
DIM rayDirX(63) AS INTEGER
DIM rayDirY(63) AS INTEGER

REM ============================================================
REM VARIABLES GENERALES
REM ============================================================
DIM i AS INTEGER
DIM ray AS INTEGER

DIM key$ AS STRING

REM ============================================================
REM VARIABLES DEL RAYCASTER
REM ============================================================
DIM dirX AS LONG
DIM dirY AS LONG

DIM rotatedX AS LONG
DIM rotatedY AS LONG

DIM mapX AS INTEGER
DIM mapY AS INTEGER

DIM stepX AS INTEGER
DIM stepY AS INTEGER

DIM deltaDistX AS LONG
DIM deltaDistY AS LONG

DIM sideDistX AS LONG
DIM sideDistY AS LONG

DIM perpWallDist AS LONG

DIM hit AS INTEGER
DIM side AS INTEGER

REM ============================================================
REM VARIABLES DE RENDERIZADO
REM ============================================================
DIM wallHeight AS INTEGER

DIM wallTop AS INTEGER
DIM wallBottom AS INTEGER

DIM screenX AS INTEGER

REM ============================================================
REM COLORES
REM ============================================================
REM Color INK por defecto
DIM colorInk AS UBYTE
colorInk = 5

REM Tono de la pared:
REM
REM 0 = BRIGHT OFF
REM 1 = BRIGHT ON
DIM tonoPared AS UBYTE
tonoPared = 0

REM ============================================================
REM VARIABLES DE MOVIMIENTO
REM ============================================================
DIM moveX AS LONG
DIM moveY AS LONG

DIM newX AS LONG
DIM newY AS LONG


