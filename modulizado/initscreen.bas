SUB InitScreen()

    DIM k AS STRING

    BRIGHT tonoPared
    BORDER 0
    PAPER 0
    INK colorInk
    CLS

    PRINT AT 19, 5; INK 7; " Space bar to start "
    PRINT AT 5, 6; BRIGHT 0; PAPER 7; INK 2; " C O N T R O L E S "
    PRINT AT 8, 10; " W  S  A  D "
    PRINT AT 10, 4; " 0 -> Change render color "
    PRINT AT 12, 4; " 1 -> Change to 2D/3D "

    DO
        k = INKEY$
    LOOP UNTIL k = CHR$(32)

    BEEP 0.2, -9
    CLS

    PRINT AT 12, 8; INK 7; " Cargando... "

END SUB


