SUB InitScreen()

    DIM k AS STRING

    BRIGHT tonoPared
    BORDER 1
    PAPER 0
    INK colorInk
    CLS

    PRINT AT 19, 6; INK 6; " Space bar to start "
    PRINT AT 6, 5; BRIGHT 0; PAPER 7; INK 2; "                     "
    PRINT AT 7, 5; BRIGHT 0; PAPER 7; INK 2; " R A Y C A S T I N G "
    PRINT AT 8, 5; BRIGHT 0; PAPER 7; INK 2; "                     "

    DO
        k = INKEY$
    LOOP UNTIL k = CHR$(32)

    BEEP 0.2, -9
    CLS

    PRINT AT 12, 9; INK 7; " Cargando... "

END SUB


