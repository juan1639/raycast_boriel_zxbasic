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
REM SUB: Render ( 3D )
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

REM ============================================================
REM                   RENDERIZADO ( 2D )
REM ============================================================
SUB Render2D()

    REM --------------------------------------------------------
    REM CONFIGURACION DEL MAPA 2D
    REM --------------------------------------------------------
    DIM mapScale AS INTEGER
    DIM mapOffsetX AS INTEGER
    DIM mapOffsetY AS INTEGER

    DIM tileX AS INTEGER
    DIM tileY AS INTEGER

    DIM px AS INTEGER
    DIM py AS INTEGER

    DIM dirEndX AS INTEGER
    DIM dirEndY AS INTEGER

    DIM fovLeftX AS INTEGER
    DIM fovLeftY AS INTEGER

    DIM fovRightX AS INTEGER
    DIM fovRightY AS INTEGER

    DIM fovAngleLeft AS FLOAT
    DIM fovAngleRight AS FLOAT

    DIM wallColor AS UBYTE

    REM --------------------------------------------------------
    REM ESCALA
    REM
    REM Cada tile del mapa ocupa 16x16 pixeles.
    REM --------------------------------------------------------
    mapScale = TILE
    mapOffsetX = 8
    mapOffsetY = 8

    REM --------------------------------------------------------
    REM LIMPIAR PANTALLA
    REM --------------------------------------------------------
    CLS
    INK colorInk
    BRIGHT 0

    REM ========================================================
    REM DIBUJAR MAPA
    REM ========================================================
    FOR tileY = 0 TO MAP_H - 1

        FOR tileX = 0 TO MAP_W - 1

            REM ------------------------------------------------
            REM POSICION DEL TILE
            REM ------------------------------------------------
            px = mapOffsetX + tileX * mapScale
            py = mapOffsetY + tileY * mapScale

            REM ------------------------------------------------
            REM ¿ES PARED?
            REM ------------------------------------------------
            IF world(tileY * MAP_W + tileX) <> 0 THEN
                wallColor = 7
            ELSE
                wallColor = 0
            END IF

            REM ------------------------------------------------
            REM DIBUJAR TILE
            REM ------------------------------------------------
            IF wallColor <> 0 THEN

                INK wallColor

                REM Esquina superior izquierda
                PLOT px, py

                REM Linea superior
                DRAW mapScale - 1, 0

                REM Linea derecha
                DRAW 0, mapScale - 1

                REM Linea inferior
                DRAW -(mapScale - 1), 0

                REM Linea izquierda
                DRAW 0, -(mapScale - 1)

            ELSE
                REM ------------------------------------------------
                REM CELDA VACIA
                REM ------------------------------------------------
                INK 1
                PLOT px, py
                DRAW mapScale - 1, 0
                DRAW 0, mapScale - 1
                DRAW -(mapScale - 1), 0
                DRAW 0, -(mapScale - 1)

            END IF

        NEXT tileX

    NEXT tileY

    REM ========================================================
    REM POSICION DEL JUGADOR
    REM ========================================================
    REM
    REM playerX / playerY estan expresados en coordenadas
    REM del mundo.
    REM
    REM Los convertimos a coordenadas de pantalla.
    REM
    REM px = mapOffsetX + playerX / TILE
    REM py = mapOffsetY + playerY / TILE

    px = mapOffsetX + playerX
    py = mapOffsetY + playerY

    REM --------------------------------------------------------
    REM DIBUJAR JUGADOR
    REM --------------------------------------------------------
    INK 2
    PLOT px - 2, py - 2
    DRAW 4, 0
    DRAW 0, 4
    DRAW -4, 0
    DRAW 0, -4

    REM ========================================================
    REM DIRECCION DEL JUGADOR
    REM ========================================================
    dirEndX = px + playerCos / 4
    dirEndY = py + playerSin / 4

    INK 7
    PLOT px, py
    DRAW dirEndX - px, dirEndY - py

    REM ========================================================
    REM CAMPO DE VISION
    REM ========================================================
    fovAngleLeft = playerAngle - FOV / 2
    fovAngleRight = playerAngle + FOV / 2

    REM --------------------------------------------------------
    REM RAYO IZQUIERDO DEL FOV
    REM --------------------------------------------------------
    fovLeftX = px + INT(COS(fovAngleLeft) * 30)
    fovLeftY = py + INT(SIN(fovAngleLeft) * 30)

    REM --------------------------------------------------------
    REM RAYO DERECHO DEL FOV
    REM --------------------------------------------------------
    fovRightX = px + INT(COS(fovAngleRight) * 30)
    fovRightY = py + INT(SIN(fovAngleRight) * 30)

    REM --------------------------------------------------------
    REM DIBUJAR FOV IZQUIERDO
    REM --------------------------------------------------------
    INK 6
    PLOT px, py
    DRAW fovLeftX - px, fovLeftY - py

    REM --------------------------------------------------------
    REM DIBUJAR FOV DERECHO
    REM --------------------------------------------------------
    PLOT px, py
    DRAW fovRightX - px, fovRightY - py

END SUB





