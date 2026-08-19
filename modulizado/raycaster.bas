REM ============================================================
REM
REM                   RAYCASTER.BAS
REM
REM ============================================================
REM SUB: InitRayTable
REM ============================================================
SUB InitRayTable()

    DIM relativeAngle AS FLOAT

    REM --------------------------------------------------------
    REM Calcular las direcciones relativas de los rayos.
    REM
    REM Esto solamente se ejecuta una vez al iniciar el programa.
    REM --------------------------------------------------------
    FOR i = 0 TO NUM_RAYS - 1

        relativeAngle = -FOV / 2 + _
                        FOV * i / (NUM_RAYS - 1)

        rayDirX(i) = INT(COS(relativeAngle) * FP)
        rayDirY(i) = INT(SIN(relativeAngle) * FP)

    NEXT i

END SUB

REM ============================================================
REM SUB: CastRay
REM ============================================================
REM
REM DDA - DIGITAL DIFFERENTIAL ANALYZER
REM
REM ============================================================
SUB CastRay()

    REM --------------------------------------------------------
    REM TILE INICIAL
    REM --------------------------------------------------------
    mapX = INT(playerX / TILE)
    mapY = INT(playerY / TILE)

    REM --------------------------------------------------------
    REM DIRECCION RELATIVA DEL RAYO
    REM --------------------------------------------------------
    dirX = rayDirX(ray)
    dirY = rayDirY(ray)

    REM --------------------------------------------------------
    REM ROTAR DIRECCION
    REM
    REM X' = X*cos - Y*sin
    REM Y' = X*sin + Y*cos
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
    REM DISTANCIA ENTRE FRONTERAS
    REM --------------------------------------------------------
    deltaDistX = (TILE * FP) / ABS(dirX)
    deltaDistY = (TILE * FP) / ABS(dirY)

    REM --------------------------------------------------------
    REM DIRECCION X
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
    REM DIRECCION Y
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
    REM BUSQUEDA DDA
    REM --------------------------------------------------------
    hit = 0
    side = 0

    WHILE hit = 0

        REM ----------------------------------------------------
        REM ¿SIGUIENTE FRONTERA X O Y?
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
        REM ¿PARED?
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
        perpWallDist = sideDistX - deltaDistX
    ELSE
        perpWallDist = sideDistY - deltaDistY
    END IF

    IF perpWallDist < 1 THEN
        perpWallDist = 1
    END IF

END SUB

REM ============================================================
REM SUB: Render
REM ============================================================
SUB Render()

    REM --------------------------------------------------------
    REM LIMPIAR PANTALLA
    REM --------------------------------------------------------
    CLS

    REM --------------------------------------------------------
    REM ACTUALIZAR TRIGONOMETRIA
    REM --------------------------------------------------------
    UpdatePlayerTrig()

    REM --------------------------------------------------------
    REM LANZAR RAYOS
    REM --------------------------------------------------------
    FOR ray = 0 TO NUM_RAYS - 1


        REM ----------------------------------------------------
        REM CALCULAR IMPACTO
        REM ----------------------------------------------------
        CastRay()

        REM ----------------------------------------------------
        REM ALTURA DE LA PARED
        REM ----------------------------------------------------
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
        REM COLOR / BRIGHT
        REM ----------------------------------------------------
        INK colorInk
        BRIGHT tonoPared

        REM ----------------------------------------------------
        REM COLUMNA
        REM ----------------------------------------------------
        PLOT screenX, wallTop
        DRAW 0, wallBottom - wallTop

        REM ----------------------------------------------------
        REM 3 PIXELES RESTANTES
        REM ----------------------------------------------------
        PLOT screenX + 1, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 2, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 3, wallTop
        DRAW 0, wallBottom - wallTop

    NEXT ray

END SUB



