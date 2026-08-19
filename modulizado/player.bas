REM ============================================================
REM
REM                    PLAYER.BAS
REM
REM ============================================================
REM SUB: UpdatePlayerTrig
REM ============================================================
REM
REM Calcula SIN y COS una sola vez.
REM
REM Los resultados se almacenan en Fixed Point.
REM
REM 256 = 1.0
REM
REM ============================================================
SUB UpdatePlayerTrig()

    playerSin = INT(SIN(playerAngle) * FP)
    playerCos = INT(COS(playerAngle) * FP)

END SUB

REM ============================================================
REM SUB: MovePlayer
REM ============================================================
SUB MovePlayer()

    REM --------------------------------------------------------
    REM LEER TECLADO
    REM --------------------------------------------------------
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

    REM --------------------------------------------------------
    REM CAMBIAR COLOR DEL RENDERIZADO (tecla 0)
    REM --------------------------------------------------------
    IF key$ = "0" THEN

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



