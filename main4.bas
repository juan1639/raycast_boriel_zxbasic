REM ============================================================
REM
REM                 RAYCASTING V3
REM
REM       BORIEL BASIC + Z80 ASM
REM
REM ============================================================
REM
REM MEJORAS:
REM
REM   * 64 rayos
REM   * Fixed Point 8.8
REM   * DDA
REM   * Sin TAN()
REM   * Sin SQR()
REM   * SIN/COS una vez por frame
REM   * Render de columnas directamente en VRAM
REM   * Una sola llamada ASM por rayo
REM   * Columnas de 4 pixels alineadas con bytes
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

REM Fixed Point 8.8
CONST FP AS INTEGER = 256

REM Campo de vision
CONST FOV AS FLOAT = PI / 3

REM Movimiento
CONST MOVE_SPEED AS INTEGER = 2

REM Proyeccion
CONST FOCAL_LENGTH AS INTEGER = 221


REM ============================================================
REM MAPA
REM ============================================================

DIM world(79) AS UBYTE => { _
    1,1,1,1,1,1,1,1,1,1, _
    1,0,0,0,0,0,0,0,0,1, _
    1,0,0,1,1,0,0,0,0,1, _
    1,0,0,0,0,0,0,0,0,1, _
    1,0,0,0,1,0,0,1,0,1, _
    1,0,0,0,1,0,0,0,0,1, _
    1,0,0,0,0,0,0,0,0,1, _
    1,1,1,1,1,1,1,1,1,1 _
}


REM ============================================================
REM VARIABLES DEL JUGADOR
REM ============================================================

DIM playerX AS LONG
DIM playerY AS LONG

DIM playerAngle AS FLOAT

DIM playerSin AS INTEGER
DIM playerCos AS INTEGER


REM ============================================================
REM TABLA DE DIRECCIONES
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
REM VARIABLES RAYCASTER
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
REM VARIABLES RENDER
REM ============================================================

DIM wallHeight AS INTEGER

DIM wallTop AS INTEGER
DIM wallBottom AS INTEGER

DIM screenX AS UBYTE


REM ============================================================
REM COLOR
REM ============================================================

DIM colorInk AS UBYTE = 5

DIM tonoPared AS UBYTE = 0


REM ============================================================
REM MOVIMIENTO
REM ============================================================

DIM moveX AS LONG
DIM moveY AS LONG

DIM newX AS LONG
DIM newY AS LONG


REM ============================================================
REM
REM FAST COLUMN 4
REM
REM Dibuja directamente una columna de 4 pixels de ancho.
REM
REM x      = coordenada X
REM y      = coordenada Y inicial
REM height = altura de la columna
REM
REM IMPORTANTE:
REM
REM screenX siempre es:
REM
REM     ray * 4
REM
REM Por tanto X solamente puede ser:
REM
REM     0,4,8,12,16...
REM
REM Eso significa que los 4 pixels siempre están dentro
REM del mismo byte de VRAM.
REM
REM
REM Los pixels:
REM
REM     X mod 8 = 0 -> 11110000
REM     X mod 8 = 4 -> 00001111
REM
REM ============================================================

SUB FastColumn4(x AS UBYTE, y AS UBYTE, height AS UBYTE)

ASM

    ; ----------------------------------------------------------
    ; Saltamos las tablas
    ; ----------------------------------------------------------

    JP FC4_START


    ; ----------------------------------------------------------
    ; INICIO DE RUTINA
    ; ----------------------------------------------------------

FC4_START:

    ; ----------------------------------------------------------
    ; Seleccionar mascara
    ;
    ; X mod 8 solamente puede ser 0 o 4
    ;
    ; 0 -> 11110000
    ; 4 -> 00001111
    ; ----------------------------------------------------------

    LD A,(IX+5)

    AND 4

    JR Z,FC4_MASK_LEFT


    ; X = 4 mod 8

    LD E,15

    JR FC4_MASK_READY


FC4_MASK_LEFT:

    LD E,240


FC4_MASK_READY:


    ; ----------------------------------------------------------
    ; CALCULAR DIRECCION VRAM
    ;
    ; Entrada:
    ;
    ; X = IX+5
    ; Y = IX+7
    ;
    ; Formato:
    ;
    ; 010 TT SSS LLL CCCCC
    ;
    ; ----------------------------------------------------------

    LD A,(IX+7)

    LD B,A


    ; ----------------------------------------------------------
    ; H:
    ;
    ; bits 0-2 de Y -> SSS
    ; bits 6-7 de Y -> TT
    ;
    ; H = 010TTSSS
    ; ----------------------------------------------------------

    AND 7

    OR 64

    LD H,A


    ; ----------------------------------------------------------
    ; Añadir TT
    ;
    ; Y7,Y6 -> bits 4,3 de H
    ; ----------------------------------------------------------

    LD A,B

    RRCA
    RRCA
    RRCA

    AND 24

    OR H

    LD H,A


    ; ----------------------------------------------------------
    ; L:
    ;
    ; Y5,Y4,Y3 -> bits 7,6,5
    ; X7..X3   -> bits 4..0
    ; ----------------------------------------------------------

    LD A,B

    RLA
    RLA

    AND 224

    LD L,A


    ; ----------------------------------------------------------
    ; X / 8
    ; ----------------------------------------------------------

    LD A,(IX+5)

    RRCA
    RRCA
    RRCA

    AND 31

    OR L

    LD L,A


    ; ----------------------------------------------------------
    ; CONTADOR DE LINEAS
    ; ----------------------------------------------------------

    LD C,(IX+9)


    ; ----------------------------------------------------------
    ; LOOP PRINCIPAL
    ; ----------------------------------------------------------

FC4_LOOP:


    ; ----------------------------------------------------------
    ; Pintar los 4 pixels
    ;
    ; OR en lugar de LD directo para no destruir
    ; los pixels vecinos del mismo byte.
    ; ----------------------------------------------------------

    LD A,(HL)

    OR E

    LD (HL),A


    ; ----------------------------------------------------------
    ; Siguiente scanline
    ;
    ; Dentro de un bloque de 8 lineas:
    ;
    ;       INC H
    ;
    ; Cuando H pasa de xx47 -> xx48
    ; o de xx4F -> xx50:
    ;
    ; hay que corregir L.
    ; ----------------------------------------------------------

    INC H

    LD A,H

    AND 7

    JR NZ,FC4_NEXT


    ; ----------------------------------------------------------
    ; Hemos pasado del scanline 7 al siguiente bloque.
    ;
    ; Avanzamos 32 bytes en L.
    ; ----------------------------------------------------------

    LD A,L

    ADD A,32

    LD L,A


    ; ----------------------------------------------------------
    ; Si hay carry hemos cambiado de tercio.
    ;
    ; INC H ya hizo el cambio de tercio.
    ; ----------------------------------------------------------

    JR C,FC4_NEXT


    ; ----------------------------------------------------------
    ; Si no hubo carry:
    ;
    ; INC H habia añadido tambien el bit de tercio,
    ; pero realmente seguimos en el mismo tercio.
    ;
    ; Lo corregimos restando 8.
    ; ----------------------------------------------------------

    LD A,H

    SUB 8

    LD H,A


FC4_NEXT:

    DEC C

    JR NZ,FC4_LOOP

END ASM

END SUB


REM ============================================================
REM IsWall
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
REM INIT RAY TABLE
REM ============================================================

SUB InitRayTable()

    DIM relativeAngle AS FLOAT

    FOR i = 0 TO NUM_RAYS - 1

        relativeAngle = _
            -FOV / 2 + _
            FOV * i / (NUM_RAYS - 1)

        rayDirX(i) = _
            INT(COS(relativeAngle) * FP)

        rayDirY(i) = _
            INT(SIN(relativeAngle) * FP)

    NEXT i

END SUB


REM ============================================================
REM UPDATE TRIGONOMETRIA
REM ============================================================

SUB UpdatePlayerTrig()

    playerSin = _
        INT(SIN(playerAngle) * FP)

    playerCos = _
        INT(COS(playerAngle) * FP)

END SUB


REM ============================================================
REM MOVIMIENTO
REM ============================================================

SUB MovePlayer()

    key$ = INKEY$


    REM --------------------------------------------------------
    REM GIRAR IZQUIERDA
    REM --------------------------------------------------------

    IF key$ = "a" OR key$ = "A" THEN

        playerAngle = _
            playerAngle - 0.08

    END IF


    REM --------------------------------------------------------
    REM GIRAR DERECHA
    REM --------------------------------------------------------

    IF key$ = "d" OR key$ = "D" THEN

        playerAngle = _
            playerAngle + 0.08

    END IF


    REM --------------------------------------------------------
    REM CAMBIAR COLOR
    REM --------------------------------------------------------

    IF key$ = "0" OR key$ = "1" THEN

        colorInk = colorInk + 1

        IF colorInk > 7 THEN
            colorInk = 1
        END IF

        INK colorInk

    END IF


    REM --------------------------------------------------------
    REM NORMALIZAR ANGULO
    REM --------------------------------------------------------

    IF playerAngle < 0 THEN

        playerAngle = _
            playerAngle + 2 * PI

    END IF


    IF playerAngle >= 2 * PI THEN

        playerAngle = _
            playerAngle - 2 * PI

    END IF


    REM --------------------------------------------------------
    REM TRIGONOMETRIA
    REM --------------------------------------------------------

    UpdatePlayerTrig()


    moveX = 0
    moveY = 0


    REM --------------------------------------------------------
    REM AVANZAR
    REM --------------------------------------------------------

    IF key$ = "w" OR key$ = "W" THEN

        moveX = _
            (playerCos * MOVE_SPEED) / FP

        moveY = _
            (playerSin * MOVE_SPEED) / FP

    END IF


    REM --------------------------------------------------------
    REM RETROCEDER
    REM --------------------------------------------------------

    IF key$ = "s" OR key$ = "S" THEN

        moveX = _
            -(playerCos * MOVE_SPEED) / FP

        moveY = _
            -(playerSin * MOVE_SPEED) / FP

    END IF


    REM --------------------------------------------------------
    REM NUEVA POSICION
    REM --------------------------------------------------------

    newX = playerX + moveX
    newY = playerY + moveY


    REM --------------------------------------------------------
    REM COLISION X
    REM --------------------------------------------------------

    IF IsWall( _
        INT(newX / TILE), _
        INT(playerY / TILE)) = 0 THEN

        playerX = newX

    END IF


    REM --------------------------------------------------------
    REM COLISION Y
    REM --------------------------------------------------------

    IF IsWall( _
        INT(playerX / TILE), _
        INT(newY / TILE)) = 0 THEN

        playerY = newY

    END IF

END SUB


REM ============================================================
REM CAST RAY
REM ============================================================

SUB CastRay()


    REM --------------------------------------------------------
    REM TILE INICIAL
    REM --------------------------------------------------------

    mapX = _
        INT(playerX / TILE)

    mapY = _
        INT(playerY / TILE)


    REM --------------------------------------------------------
    REM DIRECCION DEL RAYO
    REM --------------------------------------------------------

    dirX = rayDirX(ray)
    dirY = rayDirY(ray)


    REM --------------------------------------------------------
    REM ROTACION
    REM --------------------------------------------------------

    rotatedX = _
        (dirX * playerCos - _
         dirY * playerSin) / FP


    rotatedY = _
        (dirX * playerSin + _
         dirY * playerCos) / FP


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
    REM DELTAS
    REM --------------------------------------------------------

    deltaDistX = _
        (TILE * FP) / ABS(dirX)

    deltaDistY = _
        (TILE * FP) / ABS(dirY)


    REM --------------------------------------------------------
    REM STEP X
    REM --------------------------------------------------------

    IF dirX < 0 THEN

        stepX = -1

        sideDistX = _
            (playerX - mapX * TILE) * _
            deltaDistX / TILE

    ELSE

        stepX = 1

        sideDistX = _
            ((mapX + 1) * TILE - playerX) * _
            deltaDistX / TILE

    END IF


    REM --------------------------------------------------------
    REM STEP Y
    REM --------------------------------------------------------

    IF dirY < 0 THEN

        stepY = -1

        sideDistY = _
            (playerY - mapY * TILE) * _
            deltaDistY / TILE

    ELSE

        stepY = 1

        sideDistY = _
            ((mapY + 1) * TILE - playerY) * _
            deltaDistY / TILE

    END IF


    REM --------------------------------------------------------
    REM DDA
    REM --------------------------------------------------------

    hit = 0
    side = 0


    WHILE hit = 0


        IF sideDistX < sideDistY THEN

            sideDistX = _
                sideDistX + deltaDistX

            mapX = _
                mapX + stepX

            side = 0

            tonoPared = 1

        ELSE

            sideDistY = _
                sideDistY + deltaDistY

            mapY = _
                mapY + stepY

            side = 1

            tonoPared = 0

        END IF


        REM ----------------------------------------------------
        REM COLISION
        REM ----------------------------------------------------

        IF IsWall(mapX, mapY) <> 0 THEN

            hit = 1

        END IF


        REM ----------------------------------------------------
        REM SEGURIDAD
        REM ----------------------------------------------------

        IF mapX < 0 OR mapX >= MAP_W OR _
           mapY < 0 OR mapY >= MAP_H THEN

            hit = 1

        END IF


    WEND


    REM --------------------------------------------------------
    REM DISTANCIA PERPENDICULAR
    REM --------------------------------------------------------

    IF side = 0 THEN

        perpWallDist = _
            sideDistX - deltaDistX

    ELSE

        perpWallDist = _
            sideDistY - deltaDistY

    END IF


    IF perpWallDist < 1 THEN

        perpWallDist = 1

    END IF

END SUB


REM ============================================================
REM RENDER
REM ============================================================

SUB Render()


    CLS


    UpdatePlayerTrig()


    REM --------------------------------------------------------
    REM 64 RAYOS
    REM --------------------------------------------------------

    FOR ray = 0 TO NUM_RAYS - 1


        REM ----------------------------------------------------
        REM DDA
        REM ----------------------------------------------------

        CastRay()


        REM ----------------------------------------------------
        REM ALTURA
        REM ----------------------------------------------------

        wallHeight = _
            (TILE * FOCAL_LENGTH) / _
            perpWallDist


        REM ----------------------------------------------------
        REM LIMITAR
        REM ----------------------------------------------------

        IF wallHeight > SCREEN_H THEN

            wallHeight = SCREEN_H

        END IF


        IF wallHeight < 1 THEN

            wallHeight = 1

        END IF


        REM ----------------------------------------------------
        REM CENTRAR
        REM ----------------------------------------------------

        wallTop = _
            (SCREEN_H - wallHeight) / 2

        wallBottom = _
            wallTop + wallHeight


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
        REM RENDER Z80
        REM
        REM Una unica llamada para las 4 columnas.
        REM ----------------------------------------------------

        FastColumn4( _
            screenX, _
            wallTop, _
            wallBottom - wallTop + 1 _
        )


    NEXT ray

END SUB


REM ============================================================
REM INICIALIZACION
REM ============================================================

InitRayTable()


REM ------------------------------------------------------------
REM POSICION INICIAL
REM ------------------------------------------------------------

playerX = _
    2 * TILE + TILE / 2

playerY = _
    4 * TILE + TILE / 2


REM ------------------------------------------------------------
REM ORIENTACION
REM ------------------------------------------------------------

playerAngle = 0


REM ------------------------------------------------------------
REM TRIGONOMETRIA
REM ------------------------------------------------------------

UpdatePlayerTrig()


REM ------------------------------------------------------------
REM PANTALLA
REM ------------------------------------------------------------

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

