'============================================================
'                     player.bas
' 
'============================================================
'   SUB: UpdatePlayerTrig
'============================================================
'Calcula SIN y COS una sola vez.
'Los resultados se almacenan en Fixed Point.
'256 = 1.0
'============================================================
SUB UpdatePlayerTrig()

    playerSin = INT(SIN(playerAngle) * FP)
    playerCos = INT(COS(playerAngle) * FP)

END SUB

'============================================================
'   SUB: MovePlayer
' 
'============================================================
SUB MovePlayer()

    '--------------------------------------------------------
    'LEER TECLADO
    '--------------------------------------------------------
    key$ = INKEY$

    '--------------------------------------------------------
    'CAMBIAR COLOR DEL RENDERIZADO (tecla 0)
    '--------------------------------------------------------
    IF key$ = "0" THEN

        colorInk = colorInk + 1
        IF colorInk > 7 THEN colorInk = 1

        INK colorInk

    END IF

    '--------------------------------------------------------
    'CAMBIAR MODO 3D/2D (tecla 1)
    '--------------------------------------------------------
    IF key$ = "1" THEN

        IF modo3d = 0 THEN
            modo3d = 1
        ELSE
            modo3d = 0
        END IF

    END IF

    '--------------------------------------------------------
    'GIRAR IZQUIERDA
    '--------------------------------------------------------
    IF key$ = "a" OR key$ = "A" THEN
        playerAngle = playerAngle - 0.08
    END IF

    '--------------------------------------------------------
    'GIRAR DERECHA
    '--------------------------------------------------------
    IF key$ = "d" OR key$ = "D" THEN
        playerAngle = playerAngle + 0.08
    END IF

    '--------------------------------------------------------
    'NORMALIZAR ANGULO
    '--------------------------------------------------------
    IF playerAngle < 0 THEN
        playerAngle = playerAngle + 2 * PI
    END IF

    IF playerAngle >= 2 * PI THEN
        playerAngle = playerAngle - 2 * PI
    END IF

    '--------------------------------------------------------
    'ACTUALIZAR TRIGONOMETRIA
    '--------------------------------------------------------
    UpdatePlayerTrig()

    moveX = 0
    moveY = 0

    '--------------------------------------------------------
    'AVANZAR
    '--------------------------------------------------------
    IF key$ = "w" OR key$ = "W" THEN

        moveX = (playerCos * MOVE_SPEED) / FP
        moveY = (playerSin * MOVE_SPEED) / FP

    END IF

    '--------------------------------------------------------
    'RETROCEDER
    '--------------------------------------------------------
    IF key$ = "s" OR key$ = "S" THEN

        moveX = -(playerCos * MOVE_SPEED) / FP
        moveY = -(playerSin * MOVE_SPEED) / FP

    END IF

    '--------------------------------------------------------
    'NUEVA POSICION
    '--------------------------------------------------------
    newX = playerX + moveX
    newY = playerY + moveY

    '--------------------------------------------------------
    'COLISION HORIZONTAL
    '--------------------------------------------------------
    IF IsWall(INT(newX / TILE), INT(playerY / TILE)) = 0 THEN
        playerX = newX
    END IF

    '--------------------------------------------------------
    'COLISION VERTICAL
    '--------------------------------------------------------
    IF IsWall(INT(playerX / TILE), INT(newY / TILE)) = 0 THEN
        playerY = newY
    END IF

END SUB



