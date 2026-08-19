REM ============================================================
REM
REM                 RAYCASTING - BORIEL ZX BASIC
REM
REM        Primer prototipo tipo Wolfenstein 3D
REM
REM ============================================================


REM ------------------------------------------------------------
REM CONFIGURACION
REM ------------------------------------------------------------

CONST SCREEN_W AS INTEGER = 128
CONST SCREEN_H AS INTEGER = 192

CONST MAP_W AS INTEGER = 10
CONST MAP_H AS INTEGER = 8

CONST TILE AS INTEGER = 16

CONST FOV AS FLOAT = PI / 3
CONST HALF_FOV AS FLOAT = FOV / 2

CONST MOVE_SPEED AS FLOAT = 2
CONST ROT_SPEED AS FLOAT = 0.08

CONST EPSILON AS FLOAT = 0.001


REM ------------------------------------------------------------
REM MAPA
REM
REM 0 = espacio
REM 1 = pared
REM
REM El mapa se almacena como un array lineal:
REM world(y * MAP_W + x)
REM
REM ------------------------------------------------------------

DIM world(79) AS UBYTE


REM ------------------------------------------------------------
REM VARIABLES DEL JUGADOR
REM ------------------------------------------------------------

DIM playerX AS FLOAT
DIM playerY AS FLOAT
DIM playerAngle AS FLOAT


REM ------------------------------------------------------------
REM VARIABLES DEL RAYCASTER
REM ------------------------------------------------------------

DIM ray AS INTEGER
DIM rayAngle AS FLOAT

DIM sinAngle AS FLOAT
DIM cosAngle AS FLOAT

DIM horizontalDistance AS FLOAT
DIM verticalDistance AS FLOAT

DIM distance AS FLOAT
DIM correctedDistance AS FLOAT

DIM wallHeight AS INTEGER

DIM wallTop AS INTEGER
DIM wallBottom AS INTEGER

DIM rayX AS INTEGER


REM ------------------------------------------------------------
REM VARIABLES PARA LAS INTERSECCIONES HORIZONTALES
REM ------------------------------------------------------------

DIM hx AS FLOAT
DIM hy AS FLOAT

DIM horizontalStepX AS FLOAT
DIM horizontalStepY AS FLOAT

DIM horizontalTileX AS INTEGER
DIM horizontalTileY AS INTEGER


REM ------------------------------------------------------------
REM VARIABLES PARA LAS INTERSECCIONES VERTICALES
REM ------------------------------------------------------------

DIM vx AS FLOAT
DIM vy AS FLOAT

DIM verticalStepX AS FLOAT
DIM verticalStepY AS FLOAT

DIM verticalTileX AS INTEGER
DIM verticalTileY AS INTEGER


REM ------------------------------------------------------------
REM VARIABLES AUXILIARES
REM ------------------------------------------------------------

DIM key$ AS STRING

DIM i AS INTEGER

DIM moveX AS FLOAT
DIM moveY AS FLOAT

DIM forwardX AS FLOAT
DIM forwardY AS FLOAT


REM ============================================================
REM FUNCION: ISWALL
REM
REM Comprueba si una posicion del mapa contiene una pared.
REM
REM Devuelve:
REM     1 = pared
REM     0 = espacio
REM ============================================================

FUNCTION IsWall(tileX AS INTEGER, tileY AS INTEGER) AS INTEGER

    IF tileX < 0 OR tileX >= MAP_W THEN
        RETURN 1
    END IF

    IF tileY < 0 OR tileY >= MAP_H THEN
        RETURN 1
    END IF

    RETURN world(tileY * MAP_W + tileX)

END FUNCTION


REM ============================================================
REM SUB: INITMAP
REM
REM Inicializa el mapa mediante DATA / READ.
REM ============================================================

SUB InitMap()

    RESTORE mapData

    FOR i = 0 TO 79
        READ world(i)
    NEXT i

END SUB


REM ============================================================
REM SUB: MOVEPLAYER
REM
REM Movimiento sencillo del jugador.
REM
REM W = avanzar
REM S = retroceder
REM A = girar izquierda
REM D = girar derecha
REM
REM Se comprueba la colision antes de mover cada coordenada.
REM ============================================================

SUB MovePlayer()

    key$ = INKEY$

    REM --------------------------------------------------------
    REM GIRAR
    REM --------------------------------------------------------

    IF key$ = "a" OR key$ = "A" THEN
        playerAngle = playerAngle - ROT_SPEED
    END IF

    IF key$ = "d" OR key$ = "D" THEN
        playerAngle = playerAngle + ROT_SPEED
    END IF


    REM --------------------------------------------------------
    REM CALCULAR VECTOR DE MOVIMIENTO
    REM --------------------------------------------------------

    moveX = 0
    moveY = 0

    forwardX = COS(playerAngle)
    forwardY = SIN(playerAngle)


    IF key$ = "w" OR key$ = "W" THEN
        moveX = forwardX * MOVE_SPEED
        moveY = forwardY * MOVE_SPEED
    END IF

    IF key$ = "s" OR key$ = "S" THEN
        moveX = -forwardX * MOVE_SPEED
        moveY = -forwardY * MOVE_SPEED
    END IF


    REM --------------------------------------------------------
    REM COLISION X
    REM --------------------------------------------------------

    IF IsWall(INT((playerX + moveX) / TILE), INT(playerY / TILE)) = 0 THEN
        playerX = playerX + moveX
    END IF


    REM --------------------------------------------------------
    REM COLISION Y
    REM --------------------------------------------------------

    IF IsWall(INT(playerX / TILE), INT((playerY + moveY) / TILE)) = 0 THEN
        playerY = playerY + moveY
    END IF


    REM --------------------------------------------------------
    REM NORMALIZAR ANGULO
    REM --------------------------------------------------------

    IF playerAngle < 0 THEN
        playerAngle = playerAngle + 2 * PI
    END IF

    IF playerAngle >= 2 * PI THEN
        playerAngle = playerAngle - 2 * PI
    END IF

END SUB


REM ============================================================
REM SUB: CASTHORIZONTAL
REM
REM Busca la primera pared que encuentra el rayo al atravesar
REM las lineas HORIZONTALES de la rejilla.
REM
REM El resultado se guarda en:
REM     horizontalDistance
REM
REM ============================================================

SUB CastHorizontal()

    horizontalDistance = 100000

    REM --------------------------------------------------------
    REM Si el rayo es practicamente horizontal no podemos
    REM calcular las intersecciones de esta forma.
    REM --------------------------------------------------------

    IF ABS(sinAngle) < EPSILON THEN
        RETURN
    END IF


    REM --------------------------------------------------------
    REM Primera interseccion horizontal
REM
REM playerY pertenece a un tile.
REM
REM Si vamos hacia abajo:
REM
REM     siguiente frontera = tile actual + TILE
REM
REM Si vamos hacia arriba:
REM
REM     siguiente frontera = tile actual
REM
REM y desplazamos ligeramente hacia arriba para comprobar
REM el tile que realmente estamos entrando.
REM --------------------------------------------------------

    IF sinAngle > 0 THEN

        hy = INT(playerY / TILE) * TILE + TILE

    ELSE

        hy = INT(playerY / TILE) * TILE - EPSILON

    END IF


    REM --------------------------------------------------------
    REM Calculamos X usando:
REM
REM     tan(angle) = dy / dx
REM
REM por tanto:
REM
REM     dx = dy / tan(angle)
REM --------------------------------------------------------

    hx = playerX + (hy - playerY) / TAN(rayAngle)


    REM --------------------------------------------------------
    REM PASO ENTRE INTERSECCIONES
REM
REM Cada vez que atravesamos otra linea horizontal avanzamos
REM exactamente TILE pixels en Y.
REM --------------------------------------------------------

    IF sinAngle > 0 THEN

        horizontalStepY = TILE

    ELSE

        horizontalStepY = -TILE

    END IF


    horizontalStepX = horizontalStepY / TAN(rayAngle)


    REM --------------------------------------------------------
    REM BUSCAR PARED
REM
REM Se limita la busqueda al interior del mapa.
REM --------------------------------------------------------

    WHILE hx >= 0 AND hx < MAP_W * TILE AND _
          hy >= 0 AND hy < MAP_H * TILE

        horizontalTileX = INT(hx / TILE)

        IF sinAngle > 0 THEN
            horizontalTileY = INT(hy / TILE)
        ELSE
            horizontalTileY = INT(hy / TILE)
        END IF


        IF IsWall(horizontalTileX, horizontalTileY) <> 0 THEN

            horizontalDistance = SQR( _
                (hx - playerX) * (hx - playerX) + _
                (hy - playerY) * (hy - playerY) _
            )

            RETURN

        END IF


        hx = hx + horizontalStepX
        hy = hy + horizontalStepY

    END WHILE

END SUB


REM ============================================================
REM SUB: CASTVERTICAL
REM
REM Busca la primera pared que encuentra el rayo al atravesar
REM las lineas VERTICALES de la rejilla.
REM
REM El resultado se guarda en:
REM     verticalDistance
REM
REM ============================================================

SUB CastVertical()

    verticalDistance = 100000


    REM --------------------------------------------------------
    REM Si el rayo es practicamente vertical no podemos
    REM calcular las intersecciones verticales.
    REM --------------------------------------------------------

    IF ABS(cosAngle) < EPSILON THEN
        RETURN
    END IF


    REM --------------------------------------------------------
    REM Primera interseccion vertical.
REM
REM Si vamos hacia la derecha:
REM     siguiente frontera = tile actual + TILE
REM
REM Si vamos hacia la izquierda:
REM     siguiente frontera = tile actual
REM --------------------------------------------------------

    IF cosAngle > 0 THEN

        vx = INT(playerX / TILE) * TILE + TILE

    ELSE

        vx = INT(playerX / TILE) * TILE - EPSILON

    END IF


    REM --------------------------------------------------------
    REM Calculamos Y:
REM
REM     tan(angle) = dy / dx
REM
REM     dy = dx * tan(angle)
REM --------------------------------------------------------

    vy = playerY + (vx - playerX) * TAN(rayAngle)


    REM --------------------------------------------------------
    REM PASO ENTRE INTERSECCIONES
REM --------------------------------------------------------

    IF cosAngle > 0 THEN

        verticalStepX = TILE

    ELSE

        verticalStepX = -TILE

    END IF


    verticalStepY = verticalStepX * TAN(rayAngle)


    REM --------------------------------------------------------
    REM BUSCAR PARED
REM --------------------------------------------------------

    WHILE vx >= 0 AND vx < MAP_W * TILE AND _
          vy >= 0 AND vy < MAP_H * TILE

        IF cosAngle > 0 THEN
            verticalTileX = INT(vx / TILE)
        ELSE
            verticalTileX = INT(vx / TILE)
        END IF

        verticalTileY = INT(vy / TILE)


        IF IsWall(verticalTileX, verticalTileY) <> 0 THEN

            verticalDistance = SQR( _
                (vx - playerX) * (vx - playerX) + _
                (vy - playerY) * (vy - playerY) _
            )

            RETURN

        END IF


        vx = vx + verticalStepX
        vy = vy + verticalStepY

    END WHILE

END SUB


REM ============================================================
REM SUB: RENDER
REM
REM Lanza un rayo por cada columna de la pantalla.
REM
REM 1. Calcula el angulo
REM 2. Busca impacto horizontal
REM 3. Busca impacto vertical
REM 4. Elige el mas cercano
REM 5. Corrige fish-eye
REM 6. Calcula altura de pared
REM 7. Dibuja columna
REM ============================================================

SUB Render()

    FOR ray = 0 TO SCREEN_W - 1


        REM ----------------------------------------------------
        REM ANGULO DEL RAYO
        REM
        REM Distribuimos los rayos dentro del FOV.
        REM ----------------------------------------------------

        rayAngle = playerAngle - HALF_FOV + _
                   FOV * ray / (SCREEN_W - 1)


        REM ----------------------------------------------------
        REM SENO Y COSENO DEL RAYO
        REM ----------------------------------------------------

        sinAngle = SIN(rayAngle)
        cosAngle = COS(rayAngle)


        REM ----------------------------------------------------
        REM CASTING HORIZONTAL
        REM ----------------------------------------------------

        CastHorizontal()


        REM ----------------------------------------------------
        REM CASTING VERTICAL
        REM ----------------------------------------------------

        CastVertical()


        REM ----------------------------------------------------
        REM ELEGIR EL IMPACTO MAS CERCANO
        REM ----------------------------------------------------

        IF horizontalDistance < verticalDistance THEN

            distance = horizontalDistance

        ELSE

            distance = verticalDistance

        END IF


        REM ----------------------------------------------------
        REM CORRECCION FISH-EYE
        REM
        REM La distancia geometrica al muro no es exactamente
        REM la distancia perpendicular al plano de pantalla.
        REM
        REM Multiplicamos por COS(delta).
        REM ----------------------------------------------------

        correctedDistance = distance * COS(rayAngle - playerAngle)


        IF correctedDistance < 0.1 THEN
            correctedDistance = 0.1
        END IF


        REM ----------------------------------------------------
        REM ALTURA DE LA PARED
        REM
        REM TILE / distancia
        REM
        REM El factor 256 hace que las paredes sean visibles
        REM a una escala razonable.
        REM ----------------------------------------------------

        wallHeight = INT((TILE * 256) / correctedDistance)


        IF wallHeight > SCREEN_H THEN
            wallHeight = SCREEN_H
        END IF


        REM ----------------------------------------------------
        REM CENTRAR LA PARED VERTICALMENTE
        REM ----------------------------------------------------

        wallTop = (SCREEN_H - wallHeight) / 2
        wallBottom = wallTop + wallHeight


        IF wallTop < 0 THEN
            wallTop = 0
        END IF

        IF wallBottom > SCREEN_H - 1 THEN
            wallBottom = SCREEN_H - 1
        END IF


        REM ----------------------------------------------------
        REM DIBUJAR LA COLUMNA
        REM
        REM PLOT coloca el cursor.
        REM DRAW 0,n dibuja una linea vertical.
        REM ----------------------------------------------------

        rayX = ray * 2

        PLOT rayX, wallTop
        DRAW 0, wallBottom - wallTop


    NEXT ray

END SUB


REM ============================================================
REM INICIALIZACION
REM ============================================================

InitMap()


REM ------------------------------------------------------------
REM POSICION INICIAL
REM ------------------------------------------------------------

playerX = 2.5 * TILE
playerY = 4.5 * TILE

REM Mirando hacia la derecha.
playerAngle = 0


REM ------------------------------------------------------------
REM PANTALLA
REM ------------------------------------------------------------

BORDER 0
PAPER 0
INK 7
CLS


REM ============================================================
REM BUCLE PRINCIPAL
REM ============================================================

DO

    CLS

    MovePlayer()

    Render()

LOOP UNTIL key$ = CHR$(27)


END


REM ============================================================
REM DATOS DEL MAPA
REM
REM 10 columnas x 8 filas
REM
REM # = pared
REM . = espacio
REM
REM Cada numero representa:
REM
REM 0 = espacio
REM 1 = pared
REM
REM ============================================================

mapData:

DATA 1,1,1,1,1,1,1,1,1,1
DATA 1,0,0,0,0,0,0,0,0,1
DATA 1,0,0,1,1,0,0,0,0,1
DATA 1,0,0,0,0,0,0,0,0,1
DATA 1,0,0,0,1,0,0,1,0,1
DATA 1,0,0,0,1,0,0,0,0,1
DATA 1,0,0,0,0,0,0,0,0,1
DATA 1,1,1,1,1,1,1,1,1,1
