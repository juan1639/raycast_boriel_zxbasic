REM ============================================================
REM
REM                      MAP.BAS
REM
REM ============================================================
REM FUNCION: IsWall
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
REM SUB: InitMap
REM ============================================================
SUB InitMap()

    REM FILA 0 -----------------------
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

    REM FILA 1 ----------------------
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

    REM FILA 2 ----------------------
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

    REM FILA 3 ----------------------
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

    REM FILA 4 ----------------------
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

    REM FILA 5 ----------------------
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

    REM FILA 6 ----------------------
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

    REM FILA 7 ----------------------
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



