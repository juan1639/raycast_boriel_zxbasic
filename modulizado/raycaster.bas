'============================================================
'                   raycaster.bas
' 
'============================================================
'   SUB: InitRayTable
' 
'============================================================
SUB InitRayTable()

    DIM relativeAngle AS FLOAT

    '--------------------------------------------------------
    'Calcular las direcciones relativas de los rayos.
    'Esto solamente se ejecuta una vez al iniciar el programa.
    '--------------------------------------------------------
    FOR i = 0 TO NUM_RAYS - 1

        relativeAngle = -FOV / 2 + _
                        FOV * i / (NUM_RAYS - 1)

        rayDirX(i) = INT(COS(relativeAngle) * FP)
        rayDirY(i) = INT(SIN(relativeAngle) * FP)

    NEXT i

END SUB

'============================================================
'   SUB: CastRay
' 
'============================================================
'DDA - DIGITAL DIFFERENTIAL ANALYZER
'============================================================
SUB CastRay()

    '--------------------------------------------------------
    'TILE INICIAL
    '--------------------------------------------------------
    mapX = INT(playerX / TILE)
    mapY = INT(playerY / TILE)

    '--------------------------------------------------------
    'DIRECCION RELATIVA DEL RAYO
    '--------------------------------------------------------
    dirX = rayDirX(ray)
    dirY = rayDirY(ray)

    '--------------------------------------------------------
    'ROTAR DIRECCION
    'X = X * cos - Y * sin
    'Y = X * sin + Y * cos
    '--------------------------------------------------------
    rotatedX = _
        (dirX * playerCos - dirY * playerSin) / FP


    rotatedY = _
        (dirX * playerSin + dirY * playerCos) / FP

    dirX = rotatedX
    dirY = rotatedY

    '--------------------------------------------------------
    'EVITAR DIVISION POR CERO
    '--------------------------------------------------------
    IF dirX = 0 THEN
        dirX = 1
    END IF

    IF dirY = 0 THEN
        dirY = 1
    END IF

    '--------------------------------------------------------
    'DISTANCIA ENTRE FRONTERAS
    '--------------------------------------------------------
    deltaDistX = (TILE * FP) / ABS(dirX)
    deltaDistY = (TILE * FP) / ABS(dirY)

    '--------------------------------------------------------
    'DIRECCION X
    '--------------------------------------------------------
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

    '--------------------------------------------------------
    'DIRECCION Y
    '--------------------------------------------------------
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

    '--------------------------------------------------------
    'BUSQUEDA DDA
    '--------------------------------------------------------
    hit = 0
    side = 0

    WHILE hit = 0

        '----------------------------------------------------
        '¿SIGUIENTE FRONTERA X O Y?
        '----------------------------------------------------
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

        '----------------------------------------------------
        '¿PARED?
        '----------------------------------------------------
        IF IsWall(mapX, mapY) <> 0 THEN
            hit = 1
        END IF

        '----------------------------------------------------
        'SEGURIDAD
        '----------------------------------------------------
        IF mapX < 0 OR mapX >= MAP_W OR _
           mapY < 0 OR mapY >= MAP_H THEN

            hit = 1

        END IF

    WEND

    '--------------------------------------------------------
    'DISTANCIA PERPENDICULAR
    '--------------------------------------------------------

    IF side = 0 THEN
        perpWallDist = sideDistX - deltaDistX
    ELSE
        perpWallDist = sideDistY - deltaDistY
    END IF

    IF perpWallDist < 1 THEN
        perpWallDist = 1
    END IF

END SUB

'============================================================
'   SUB: Render ( 3D )
' 
'============================================================
SUB Render()

    '--------------------------------------------------------
    'LIMPIAR PANTALLA
    '--------------------------------------------------------
    CLS
    show_scores()

    '--------------------------------------------------------
    'ACTUALIZAR TRIGONOMETRIA
    '--------------------------------------------------------
    UpdatePlayerTrig()

    '--------------------------------------------------------
    'LANZAR RAYOS
    '--------------------------------------------------------
    FOR ray = 0 TO NUM_RAYS - 1


        '----------------------------------------------------
        'CALCULAR IMPACTO
        '----------------------------------------------------
        CastRay()

        '----------------------------------------------------
        'ALTURA DE LA PARED
        '----------------------------------------------------
        wallHeight = _
            (TILE * FOCAL_LENGTH) / perpWallDist

        '----------------------------------------------------
        'LIMITAR ALTURA
        '----------------------------------------------------
        IF wallHeight > SCREEN_H THEN
            wallHeight = SCREEN_H
        END IF

        IF wallHeight < 1 THEN
            wallHeight = 1
        END IF

        '----------------------------------------------------
        'CENTRAR PARED
        '----------------------------------------------------
        wallTop = (SCREEN_H - wallHeight) / 2

        wallBottom = wallTop + wallHeight

        IF wallTop < 0 THEN
            wallTop = 0
        END IF

        IF wallBottom > SCREEN_H - 1 THEN
            wallBottom = SCREEN_H - 1
        END IF

        '----------------------------------------------------
        'POSICION X
        '----------------------------------------------------
        screenX = ray * RAY_WIDTH

        '----------------------------------------------------
        'COLOR / BRIGHT
        '----------------------------------------------------
        INK colorInk
        BRIGHT tonoPared

        '----------------------------------------------------
        'COLUMNA
        '----------------------------------------------------
        PLOT screenX, wallTop
        DRAW 0, wallBottom - wallTop

        '----------------------------------------------------
        '3 PIXELES RESTANTES
        '----------------------------------------------------
        PLOT screenX + 1, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 2, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 3, wallTop
        DRAW 0, wallBottom - wallTop

    NEXT ray

END SUB

'============================================================
'   SUB: Render ( 2D )
' 
'============================================================
SUB Render2D()

    '--------------------------------------------------------
    'CONFIGURACION DEL MAPA 2D
    '--------------------------------------------------------
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

    '--------------------------------------------------------
    'ESCALA
    'Cada tile del mapa ocupa 16x16 pixeles.
    '--------------------------------------------------------
    mapScale = TILE
    mapOffsetX = 8
    mapOffsetY = 8

    '--------------------------------------------------------
    'LIMPIAR PANTALLA
    '--------------------------------------------------------
    CLS
    show_scores()
    
    INK colorInk
    BRIGHT 0

    '========================================================
    'DIBUJAR MAPA
    '========================================================
    FOR tileY = 0 TO MAP_H - 1

        FOR tileX = 0 TO MAP_W - 1

            '------------------------------------------------
            'POSICION DEL TILE
            '------------------------------------------------
            px = mapOffsetX + tileX * mapScale
            py = mapOffsetY + tileY * mapScale

            '------------------------------------------------
            '¿ES PARED?
            '------------------------------------------------
            IF world(tileY * MAP_W + tileX) <> 0 THEN
                wallColor = 7
            ELSE
                wallColor = 0
            END IF

            '------------------------------------------------
            'DIBUJAR TILE
            '------------------------------------------------
            IF wallColor <> 0 THEN

                INK wallColor

                'Esquina superior izquierda
                PLOT px, py

                'Linea superior
                DRAW mapScale - 1, 0

                'Linea derecha
                DRAW 0, mapScale - 1

                'Linea inferior
                DRAW -(mapScale - 1), 0

                'Linea izquierda
                DRAW 0, -(mapScale - 1)

            ELSE
                '------------------------------------------------
                'CELDA VACIA
                '------------------------------------------------
                INK 1
                PLOT px, py
                DRAW mapScale - 1, 0
                DRAW 0, mapScale - 1
                DRAW -(mapScale - 1), 0
                DRAW 0, -(mapScale - 1)

            END IF

        NEXT tileX

    NEXT tileY

    '========================================================
    'POSICION DEL JUGADOR
    '========================================================
    'playerX / playerY estan expresados en coordenadas
    'del mundo.
    'Los convertimos a coordenadas de pantalla.
    'px = mapOffsetX + playerX / TILE
    'py = mapOffsetY + playerY / TILE

    px = mapOffsetX + playerX
    py = mapOffsetY + playerY

    '--------------------------------------------------------
    'DIBUJAR JUGADOR
    '--------------------------------------------------------
    INK 2
    PLOT px - 2, py - 2
    DRAW 4, 0
    DRAW 0, 4
    DRAW -4, 0
    DRAW 0, -4

    '========================================================
    'DIRECCION DEL JUGADOR
    '========================================================
    dirEndX = px + playerCos / 4
    dirEndY = py + playerSin / 4

    INK 7
    PLOT px, py
    DRAW dirEndX - px, dirEndY - py

    '========================================================
    'CAMPO DE VISION
    '========================================================
    fovAngleLeft = playerAngle - FOV / 2
    fovAngleRight = playerAngle + FOV / 2

    '--------------------------------------------------------
    'RAYO IZQUIERDO DEL FOV
    '--------------------------------------------------------
    fovLeftX = px + INT(COS(fovAngleLeft) * 30)
    fovLeftY = py + INT(SIN(fovAngleLeft) * 30)

    '--------------------------------------------------------
    'RAYO DERECHO DEL FOV
    '--------------------------------------------------------
    fovRightX = px + INT(COS(fovAngleRight) * 30)
    fovRightY = py + INT(SIN(fovAngleRight) * 30)

    '--------------------------------------------------------
    'DIBUJAR FOV IZQUIERDO
    '--------------------------------------------------------
    INK 6
    PLOT px, py
    DRAW fovLeftX - px, fovLeftY - py

    '--------------------------------------------------------
    'DIBUJAR FOV DERECHO
    '--------------------------------------------------------
    PLOT px, py
    DRAW fovRightX - px, fovRightY - py

END SUB

'============================================================
'   SUB: Show scores
' 
'============================================================
SUB show_scores()

    POKE 23692, 255 ' para poder imprimir en las 2 ultimas filas

    PRINT AT 22, 1; BRIGHT 0; INK 7; " W S A D -> move controls "
    PRINT AT 23, 1; BRIGHT 0; INK 6; " 0 -> color ... 1 -> 2D/3D "

    POKE 23692, 3 ' Restaurar a default

END SUB






