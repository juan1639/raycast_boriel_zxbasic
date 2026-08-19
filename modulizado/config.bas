'============================================================
'                      config.bas
' 
'============================================================
'   CONFIGURACION DE PANTALLA
'============================================================
CONST SCREEN_W AS INTEGER = 256
CONST SCREEN_H AS INTEGER = 192

'============================================================
'   CONFIGURACION DEL RAYCASTER
'============================================================
CONST NUM_RAYS AS INTEGER = 64
CONST RAY_WIDTH AS INTEGER = 4

'============================================================
'   CONFIGURACION DEL MAPA
'============================================================
CONST MAP_W AS INTEGER = 10
CONST MAP_H AS INTEGER = 8

CONST TILE AS INTEGER = 16

'============================================================
'   FIXED POINT 8.8
'   256 = 1.0
'   128 = 0.5
'   512 = 2.0
'============================================================
CONST FP AS INTEGER = 256

'============================================================
'   CAMPO DE VISION
'============================================================
CONST FOV AS FLOAT = PI / 3

'============================================================
'   MOVIMIENTO
'============================================================
CONST MOVE_SPEED AS INTEGER = 2

'============================================================
'   PROYECCION
'   Aproximadamente:
'       focal = (SCREEN_W / 2) / TAN(FOV / 2)
'       para FOV = 60 grados:
'       focal ~= 221
'============================================================
CONST FOCAL_LENGTH AS INTEGER = 221

'============================================================
'   MAPA
'============================================================
DIM world(79) AS UBYTE

'============================================================
'   JUGADOR
'============================================================
DIM playerX AS LONG
DIM playerY AS LONG

DIM playerAngle AS FLOAT

'------------------------------------------------------------
'   SENO Y COSENO EN FIXED POINT
'   256 = 1.0
'------------------------------------------------------------
DIM playerSin AS INTEGER
DIM playerCos AS INTEGER

'============================================================
'   TABLA DE DIRECCIONES DE LOS RAYOS
'============================================================
DIM rayDirX(63) AS INTEGER
DIM rayDirY(63) AS INTEGER

'============================================================
'   VARIABLES GENERALES
'============================================================
DIM i AS INTEGER
DIM ray AS INTEGER

DIM key$ AS STRING

'DEFAULT VISTA EN 3D:
DIM modo3d AS UBYTE = 1

'============================================================
'   VARIABLES DEL RAYCASTER
'============================================================
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

'============================================================
'   VARIABLES DE RENDERIZADO
'============================================================
DIM wallHeight AS INTEGER

DIM wallTop AS INTEGER
DIM wallBottom AS INTEGER

DIM screenX AS INTEGER

'============================================================
'   COLORES (INK y BRIGHT)
' Por defecto:
'   - las paredes se veran AZULES (INK = colorInk = 5)
'   - y con diferente tonalidad (BRIGHT = tonoPared = 0 / 1)
'   - se puede cambiar a tiempo real con la tecla '0'
'============================================================
'Color INK por defecto
DIM colorInk AS UBYTE = 5

'Tono de la pared:
'0 = BRIGHT OFF
'1 = BRIGHT ON
DIM tonoPared AS UBYTE = 0

'============================================================
'   VARIABLES DE MOVIMIENTO (Jugador)
'============================================================
DIM moveX AS LONG
DIM moveY AS LONG

DIM newX AS LONG
DIM newY AS LONG


