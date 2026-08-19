REM ============================================================
REM
REM                 RAYCASTING V2
REM                 BORIEL ZX BASIC 1.18.7
REM
REM ============================================================
REM
REM OBJETIVOS DE ESTA VERSION
REM
REM   * 64 rayos en lugar de 128
REM   * Integer / Long en el raycaster
REM   * Fixed Point 8.8 para las direcciones
REM   * SIN/COS solo se calculan una vez por frame
REM   * SIN TAN
REM   * SIN SQR
REM   * DDA para atravesar el mapa
REM   * Distancia perpendicular directamente desde DDA
REM
REM ============================================================

REM ============================================================
REM CONFIGURACION
REM ============================================================
CONST SCREEN_W AS INTEGER = 256
CONST SCREEN_H AS INTEGER = 192

CONST NUM_RAYS AS INTEGER = 64
CONST RAY_WIDTH AS INTEGER = 4

CONST MAP_W AS INTEGER = 10
CONST MAP_H AS INTEGER = 8

CONST TILE AS INTEGER = 16

REM ------------------------------------------------------------
REM Fixed Point 8.8
REM
REM 256 = 1.0
REM 128 = 0.5
REM 512 = 2.0
REM ------------------------------------------------------------
CONST FP AS INTEGER = 256

REM ------------------------------------------------------------
REM Campo de vision
REM ------------------------------------------------------------
CONST FOV AS FLOAT = PI / 3

REM ------------------------------------------------------------
REM Movimiento
REM ------------------------------------------------------------
CONST MOVE_SPEED AS INTEGER = 2

REM ------------------------------------------------------------
REM Constante de proyeccion.
REM
REM Aproximadamente:
REM
REM     focal = (SCREEN_W / 2) / TAN(FOV / 2)
REM
REM para FOV = 60 grados:
REM
REM     focal ~= 221
REM
REM
REM Altura:
REM
REM     wallHeight = TILE * focal / distance
REM
REM ------------------------------------------------------------
CONST FOCAL_LENGTH AS INTEGER = 221

REM ============================================================
REM MAPA
REM ============================================================
DIM world(79) AS UBYTE

REM ============================================================
REM VARIABLES DEL JUGADOR
REM ============================================================
DIM playerX AS LONG
DIM playerY AS LONG

DIM playerAngle AS FLOAT

REM ------------------------------------------------------------
REM Seno y coseno del jugador en Fixed Point.
REM
REM 256 = 1.0
REM ------------------------------------------------------------
DIM playerSin AS INTEGER
DIM playerCos AS INTEGER

REM ============================================================
REM TABLA DE DIRECCIONES RELATIVAS
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

REM Color del INK por defecto
DIM colorInk AS UBYTE = 5

REM En realidad, el bright (pared mas oscura o clara)
DIM tonoPared AS UBYTE = 0

REM ============================================================
REM VARIABLES DE MOVIMIENTO
REM ============================================================
DIM moveX AS LONG
DIM moveY AS LONG

DIM newX AS LONG
DIM newY AS LONG

REM ============================================================
REM     FUNCION: IsWall
REM ============================================================
REM
REM Devuelve:
REM
REM     0 = espacio
REM     1 = pared
REM
REM Las posiciones fuera del mapa se consideran paredes.
REM
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
REM     SUB: InitMap
REM ============================================================
REM
REM Inicializa directamente los 80 tiles.
REM
REM Esto evita DATA/READ y nos deja el programa muy sencillo.
REM
REM ============================================================
SUB InitMap()

    REM --------------------------------------------------------
    REM FILA 0
    REM --------------------------------------------------------
    world(0) = 1
    world(1) = 1
    world(2) = 1
    world(3) = 1
    world(4) = 1
    world(5) = 1
    world(6) = 1
    world(7) = 1
    world(8) = 1
    world(9) = 1

    REM --------------------------------------------------------
    REM FILA 1
    REM --------------------------------------------------------
    world(10) = 1
    world(11) = 0
    world(12) = 0
    world(13) = 0
    world(14) = 0
    world(15) = 0
    world(16) = 0
    world(17) = 0
    world(18) = 0
    world(19) = 1

    REM --------------------------------------------------------
    REM FILA 2
    REM --------------------------------------------------------
    world(20) = 1
    world(21) = 0
    world(22) = 0
    world(23) = 1
    world(24) = 1
    world(25) = 0
    world(26) = 0
    world(27) = 0
    world(28) = 0
    world(29) = 1

    REM --------------------------------------------------------
    REM FILA 3
    REM --------------------------------------------------------
    world(30) = 1
    world(31) = 0
    world(32) = 0
    world(33) = 0
    world(34) = 0
    world(35) = 0
    world(36) = 0
    world(37) = 0
    world(38) = 0
    world(39) = 1

    REM --------------------------------------------------------
    REM FILA 4
    REM --------------------------------------------------------
    world(40) = 1
    world(41) = 0
    world(42) = 0
    world(43) = 0
    world(44) = 1
    world(45) = 0
    world(46) = 0
    world(47) = 1
    world(48) = 0
    world(49) = 1

    REM --------------------------------------------------------
    REM FILA 5
    REM --------------------------------------------------------
    world(50) = 1
    world(51) = 0
    world(52) = 0
    world(53) = 0
    world(54) = 1
    world(55) = 0
    world(56) = 0
    world(57) = 0
    world(58) = 0
    world(59) = 1

    REM --------------------------------------------------------
    REM FILA 6
    REM --------------------------------------------------------
    world(60) = 1
    world(61) = 0
    world(62) = 0
    world(63) = 0
    world(64) = 0
    world(65) = 0
    world(66) = 0
    world(67) = 0
    world(68) = 0
    world(69) = 1

    REM --------------------------------------------------------
    REM FILA 7
    REM --------------------------------------------------------
    world(70) = 1
    world(71) = 1
    world(72) = 1
    world(73) = 1
    world(74) = 1
    world(75) = 1
    world(76) = 1
    world(77) = 1
    world(78) = 1
    world(79) = 1

END SUB

REM ============================================================
REM SUB: InitRayTable
REM ============================================================
REM
REM Calculamos una vez las direcciones de los 64 rayos.
REM
REM IMPORTANTE:
REM
REM Los valores se almacenan en Fixed Point.
REM
REM Por ejemplo:
REM
REM     256 = 1.0
REM     128 = 0.5
REM
REM ============================================================
SUB InitRayTable()

    DIM relativeAngle AS FLOAT

    FOR i = 0 TO NUM_RAYS - 1

        relativeAngle = -FOV / 2 + _
                        FOV * i / (NUM_RAYS - 1)

        rayDirX(i) = INT(COS(relativeAngle) * FP)
        rayDirY(i) = INT(SIN(relativeAngle) * FP)

    NEXT i

END SUB

REM ============================================================
REM SUB: UpdatePlayerTrig
REM ============================================================
REM
REM SIN y COS se calculan UNA SOLA VEZ por frame.
REM
REM Los almacenamos en Fixed Point.
REM
REM ============================================================
SUB UpdatePlayerTrig()
    playerSin = INT(SIN(playerAngle) * FP)
    playerCos = INT(COS(playerAngle) * FP)
END SUB

REM ============================================================
REM     SUB: MovePlayer
REM ============================================================
SUB MovePlayer()

    key$ = INKEY$

    REM --------------------------------------------------------
    REM GIRAR IZQUIERDA
    REM --------------------------------------------------------
    IF key$ = "a" OR key$ = "A" THEN
        playerAngle = playerAngle - 0.08
    END IF

    REM --------------------------------------------------------
    REM GIRAR DERECHA
    REM --------------------------------------------------------
    IF key$ = "d" OR key$ = "D" THEN
        playerAngle = playerAngle + 0.08
    END IF

    IF key$ = "0" OR key$ = "1" THEN
        colorInk = colorInk + 1
        IF colorInk > 7 THEN colorInk = 1
        INK colorInk
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

    REM --------------------------------------------------------
    REM ACTUALIZAR TRIGONOMETRIA
    REM --------------------------------------------------------
    UpdatePlayerTrig()

    moveX = 0
    moveY = 0

    REM --------------------------------------------------------
    REM AVANZAR
    REM --------------------------------------------------------
    IF key$ = "w" OR key$ = "W" THEN
        moveX = (playerCos * MOVE_SPEED) / FP
        moveY = (playerSin * MOVE_SPEED) / FP
    END IF

    REM --------------------------------------------------------
    REM RETROCEDER
    REM --------------------------------------------------------

    IF key$ = "s" OR key$ = "S" THEN
        moveX = -(playerCos * MOVE_SPEED) / FP
        moveY = -(playerSin * MOVE_SPEED) / FP
    END IF

    REM --------------------------------------------------------
    REM NUEVA POSICION
    REM --------------------------------------------------------
    newX = playerX + moveX
    newY = playerY + moveY

    REM --------------------------------------------------------
    REM COLISION HORIZONTAL
    REM --------------------------------------------------------
    IF IsWall(INT(newX / TILE), INT(playerY / TILE)) = 0 THEN
        playerX = newX
    END IF

    REM --------------------------------------------------------
    REM COLISION VERTICAL
    REM --------------------------------------------------------
    IF IsWall(INT(playerX / TILE), INT(newY / TILE)) = 0 THEN
        playerY = newY
    END IF

END SUB


REM ============================================================
REM SUB: CastRay
REM ============================================================
REM
REM DDA - DIGITAL DIFFERENTIAL ANALYZER
REM
REM En lugar de buscar intersecciones mediante TAN(), el rayo
REM avanza directamente de celda en celda.
REM
REM ============================================================
SUB CastRay()

    REM --------------------------------------------------------
    REM  TILE INICIAL
    REM --------------------------------------------------------
    mapX = INT(playerX / TILE)
    mapY = INT(playerY / TILE)

    REM --------------------------------------------------------
    REM  DIRECCION RELATIVA DEL RAYO
    REM --------------------------------------------------------
    dirX = rayDirX(ray)
    dirY = rayDirY(ray)

    REM --------------------------------------------------------
    REM ROTAR DIRECCION DEL RAYO
    REM
    REM
    REM X' = X*cos - Y*sin
    REM Y' = X*sin + Y*cos
    REM
    REM
    REM Todos los valores estan en Fixed Point 256.
    REM
    REM Por tanto:
    REM
    REM producto / 256
    REM
    REM --------------------------------------------------------
    rotatedX = _
        (dirX * playerCos - dirY * playerSin) / FP

    rotatedY = _
        (dirX * playerSin + dirY * playerCos) / FP

    dirX = rotatedX
    dirY = rotatedY

    REM --------------------------------------------------------
    REM EVITAR DIVISION POR CERO
    REM --------------------------------------------------------
    IF dirX = 0 THEN
        dirX = 1
    END IF

    IF dirY = 0 THEN
        dirY = 1
    END IF

    REM --------------------------------------------------------
    REM DISTANCIA ENTRE FRONTERAS DEL MAPA
    REM
    REM
    REM deltaDistX = TILE / abs(rayDirX)
    REM
    REM Como rayDirX esta en Fixed Point:
    REM
    REM deltaDistX = TILE * FP / abs(rayDirX)
    REM
    REM --------------------------------------------------------
    deltaDistX = (TILE * FP) / ABS(dirX)
    deltaDistY = (TILE * FP) / ABS(dirY)

    REM --------------------------------------------------------
    REM  DIRECCION X
    REM --------------------------------------------------------
    IF dirX < 0 THEN

        stepX = -1

        REM Distancia desde el jugador hasta la frontera
        REM
        REM     playerX - mapX*TILE
        REM
        REM representa la posicion dentro del tile.
        REM --------------------------------------------------------
        sideDistX = _
            (playerX - mapX * TILE) * deltaDistX / TILE
    
    ELSE
        stepX = 1

        sideDistX = _
            ((mapX + 1) * TILE - playerX) * _
            deltaDistX / TILE

    END IF

    REM --------------------------------------------------------
    REM  DIRECCION Y
    REM --------------------------------------------------------
    IF dirY < 0 THEN

        stepY = -1

        sideDistY = _
            (playerY - mapY * TILE) * deltaDistY / TILE

    ELSE
        stepY = 1

        sideDistY = _
            ((mapY + 1) * TILE - playerY) * _
            deltaDistY / TILE

    END IF

    REM --------------------------------------------------------
    REM BUSQUEDA DDA
    REM --------------------------------------------------------
    hit = 0
    side = 0

    WHILE hit = 0

        REM ----------------------------------------------------
        REM ¿La siguiente frontera es X o Y?
        REM ----------------------------------------------------
        IF sideDistX < sideDistY THEN

            sideDistX = sideDistX + deltaDistX
            mapX = mapX + stepX
            side = 0
            tonoPared = 1

        ELSE
            sideDistY = sideDistY + deltaDistY
            mapY = mapY + stepY
            side = 1
            tonoPared = 0

        END IF

        REM ----------------------------------------------------
        REM ¿Hemos golpeado una pared?
        REM ----------------------------------------------------
        IF IsWall(mapX, mapY) <> 0 THEN
            hit = 1
        END IF

        REM ----------------------------------------------------
        REM Seguridad.
        REM
        REM Si salimos del mapa dejamos de buscar.
        REM ----------------------------------------------------

        IF mapX < 0 OR mapX >= MAP_W OR _
           mapY < 0 OR mapY >= MAP_H THEN
            hit = 1
        END IF

    WEND

    REM --------------------------------------------------------
    REM DISTANCIA PERPENDICULAR
    REM
    REM
    REM Si golpeamos una frontera X:
    REM
    REM     sideDistX - deltaDistX
    REM
    REM Si golpeamos una frontera Y:
    REM
    REM     sideDistY - deltaDistY
    REM
    REM
    REM Esta distancia ya es la distancia perpendicular que
    REM necesitamos para proyectar la pared.
    REM
    REM Por tanto:
    REM
    REM     NO necesitamos SQR()
    REM     NO necesitamos correccion fish-eye
    REM
    REM --------------------------------------------------------
    IF side = 0 THEN
        perpWallDist = sideDistX - deltaDistX
    ELSE
        perpWallDist = sideDistY - deltaDistY
    END IF

    IF perpWallDist < 1 THEN
        perpWallDist = 1
    END IF

END SUB

REM ============================================================
REM     SUB: Render
REM ============================================================
SUB Render()

    REM --------------------------------------------------------
    REM Limpiar pantalla
    REM --------------------------------------------------------
    CLS

    REM --------------------------------------------------------
    REM Trigonometria del jugador
    REM --------------------------------------------------------
    UpdatePlayerTrig()

    REM --------------------------------------------------------
    REM LANZAR LOS RAYOS
    REM --------------------------------------------------------
    FOR ray = 0 TO NUM_RAYS - 1

        REM ----------------------------------------------------
        REM CALCULAR IMPACTO
        REM ----------------------------------------------------
        CastRay()

        REM ----------------------------------------------------
        REM ALTURA DE LA PARED
        REM
        REM
        REM wallHeight =
        REM
        REM     TILE * FOCAL_LENGTH
        REM     -------------------
        REM          distancia
        REM
        REM --------------------------------------------------------
        wallHeight = _
            (TILE * FOCAL_LENGTH) / perpWallDist

        REM ----------------------------------------------------
        REM LIMITAR ALTURA
        REM ----------------------------------------------------
        IF wallHeight > SCREEN_H THEN
            wallHeight = SCREEN_H
        END IF

        IF wallHeight < 1 THEN
            wallHeight = 1
        END IF

        REM ----------------------------------------------------
        REM CENTRAR PARED
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
        REM POSICION X
        REM ----------------------------------------------------
        screenX = ray * RAY_WIDTH

        REM ----------------------------------------------------
        REM DIBUJAR COLUMNA
        REM ----------------------------------------------------
        BRIGHT tonoPared

        PLOT screenX, wallTop
        DRAW 0, wallBottom - wallTop

        REM ----------------------------------------------------
        REM Las siguientes 3 columnas pertenecen al mismo rayo.
        REM
        REM Esto nos permite utilizar solamente 64 rayos.
        REM ----------------------------------------------------
        PLOT screenX + 1, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 2, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 3, wallTop
        DRAW 0, wallBottom - wallTop

    NEXT ray

END SUB

REM ============================================================
REM     INICIALIZACION
REM 
REM ============================================================
InitMap()
InitRayTable()

REM ------------------------------------------------------------
REM POSICION INICIAL
REM ------------------------------------------------------------
playerX = 2 * TILE + TILE / 2
playerY = 4 * TILE + TILE / 2

REM ------------------------------------------------------------
REM ORIENTACION INICIAL
REM
REM 0 = mirando hacia la derecha.
REM ------------------------------------------------------------
playerAngle = 0

REM ------------------------------------------------------------
REM CALCULAR SIN/COS INICIAL
REM ------------------------------------------------------------
UpdatePlayerTrig()

REM ------------------------------------------------------------
REM CONFIGURAR PANTALLA
REM ------------------------------------------------------------
BRIGHT tonoPared
BORDER 0
PAPER 0
INK colorInk
CLS

REM ============================================================
REM     BUCLE PRINCIPAL
REM 
REM ============================================================
DO

    MovePlayer()

    Render()

LOOP UNTIL key$ = CHR$(27)

END

