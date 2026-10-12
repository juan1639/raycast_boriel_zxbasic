REM ============================================================
REM
REM                    RAYCASTING V4
REM
REM        BORIEL BASIC + Z80 ASM
REM
REM ============================================================
REM
REM OBJETIVOS
REM
REM   * 64 rayos
REM   * Fixed Point 8.8
REM   * DDA completo en ensamblador Z80
REM   * BASIC calcula las direcciones de los rayos
REM   * ASM calcula las distancias de los 64 rayos
REM   * Tabla de recíprocos para evitar DIV en ASM
REM   * BASIC mantiene el renderizado
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

CONST FP AS INTEGER = 256

CONST FOV AS FLOAT = PI / 3

CONST MOVE_SPEED AS INTEGER = 2

CONST FOCAL_LENGTH AS INTEGER = 221


REM ============================================================
REM MAPA
REM ============================================================

DIM world(79) AS UBYTE


REM ============================================================
REM VARIABLES DEL JUGADOR
REM ============================================================

DIM playerX AS UINTEGER
DIM playerY AS UINTEGER

DIM playerAngle AS FLOAT

DIM playerSin AS INTEGER
DIM playerCos AS INTEGER


REM ============================================================
REM TABLA DE DIRECCIONES
REM ============================================================

DIM rayDirX(63) AS INTEGER
DIM rayDirY(63) AS INTEGER


REM ============================================================
REM DIRECCIONES ROTADAS
REM
REM Estas son las direcciones que recibirá el ASM.
REM
REM BASIC calcula:
REM
REM     dirX = rayDirX * cos - rayDirY * sin
REM     dirY = rayDirX * sin + rayDirY * cos
REM
REM ============================================================

DIM asmRayX(63) AS INTEGER
DIM asmRayY(63) AS INTEGER


REM ============================================================
REM DISTANCIAS CALCULADAS POR ASM
REM ============================================================

DIM rayDist(63) AS UINTEGER


REM ============================================================
REM PUNTEROS UTILIZADOS POR ASM
REM ============================================================

DIM asmRayXPtr AS UINTEGER
DIM asmRayYPtr AS UINTEGER
DIM asmRayDistPtr AS UINTEGER
DIM asmWorldPtr AS UINTEGER


REM ============================================================
REM VARIABLES GENERALES
REM ============================================================

DIM i AS INTEGER
DIM ray AS INTEGER

DIM key$ AS STRING


REM ============================================================
REM VARIABLES DE RENDER
REM ============================================================

DIM perpWallDist AS UINTEGER

DIM wallHeight AS INTEGER

DIM wallTop AS INTEGER
DIM wallBottom AS INTEGER

DIM screenX AS INTEGER

DIM colorInk AS UBYTE = 5

DIM tonoPared AS UBYTE = 0


REM ============================================================
REM VARIABLES DE MOVIMIENTO
REM ============================================================

DIM moveX AS INTEGER
DIM moveY AS INTEGER

DIM newX AS INTEGER
DIM newY AS INTEGER


REM ============================================================
REM FUNCION IsWall
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
REM INIT MAP
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
REM INIT RAY TABLE
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
REM UPDATE PLAYER TRIG
REM ============================================================

SUB UpdatePlayerTrig()

    playerSin = INT(SIN(playerAngle) * FP)
    playerCos = INT(COS(playerAngle) * FP)

END SUB


REM ============================================================
REM MOVIMIENTO
REM ============================================================

SUB MovePlayer()

    key$ = INKEY$


    REM --------------------------------------------------------
    REM GIRAR
    REM --------------------------------------------------------

    IF key$ = "a" OR key$ = "A" THEN
        playerAngle = playerAngle - 0.08
    END IF

    IF key$ = "d" OR key$ = "D" THEN
        playerAngle = playerAngle + 0.08
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
        playerAngle = playerAngle + 2 * PI
    END IF

    IF playerAngle >= 2 * PI THEN
        playerAngle = playerAngle - 2 * PI
    END IF


    REM --------------------------------------------------------
    REM TRIG
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
    REM COLISION X
    REM --------------------------------------------------------

    IF IsWall(INT(newX / TILE), _
              INT(playerY / TILE)) = 0 THEN

        playerX = newX

    END IF


    REM --------------------------------------------------------
    REM COLISION Y
    REM --------------------------------------------------------

    IF IsWall(INT(playerX / TILE), _
              INT(newY / TILE)) = 0 THEN

        playerY = newY

    END IF

END SUB


REM ============================================================
REM
REM PREPARAR RAYOS
REM
REM BASIC realiza únicamente la rotación.
REM
REM El DDA NO se ejecuta aquí.
REM
REM ============================================================

SUB PrepareRays()

    DIM dirX AS INTEGER
    DIM dirY AS INTEGER

    DIM rotatedX AS LONG
    DIM rotatedY AS LONG


    FOR ray = 0 TO NUM_RAYS - 1


        REM ----------------------------------------------------
        REM DIRECCION RELATIVA
        REM ----------------------------------------------------

        dirX = rayDirX(ray)
        dirY = rayDirY(ray)


        REM ----------------------------------------------------
        REM ROTACION
        REM ----------------------------------------------------

        rotatedX = _
            (dirX * playerCos - _
             dirY * playerSin) / FP

        rotatedY = _
            (dirX * playerSin + _
             dirY * playerCos) / FP


        REM ----------------------------------------------------
        REM GUARDAR PARA ASM
        REM ----------------------------------------------------

        IF rotatedX = 0 THEN
            rotatedX = 1
        END IF

        IF rotatedY = 0 THEN
            rotatedY = 1
        END IF

        asmRayX(ray) = rotatedX
        asmRayY(ray) = rotatedY

    NEXT ray

END SUB


REM ============================================================
REM
REM DDA ASM
REM
REM ============================================================
REM
REM Esta rutina procesa LOS 64 RAYOS.
REM
REM BASIC llama una sola vez.
REM
REM El ASM:
REM
REM   1. obtiene la direccion del rayo
REM   2. calcula deltaDist
REM   3. inicializa sideDist
REM   4. ejecuta DDA
REM   5. consulta world[]
REM   6. obtiene distancia perpendicular
REM   7. guarda rayDist[]
REM
REM ============================================================

SUB CastAllRaysASM()

ASM

    ; =========================================================
    ; PUNTEROS A LOS ARRAYS BASIC
    ; =========================================================

    LD HL,(_asmRayXPtr)
    LD (asm_ptr_x),HL

    LD HL,(_asmRayYPtr)
    LD (asm_ptr_y),HL

    LD HL,(_asmRayDistPtr)
    LD (asm_ptr_dist),HL

    LD HL,(_asmWorldPtr)
    LD (asm_ptr_world),HL


    ; =========================================================
    ; POSICION DEL JUGADOR
    ; =========================================================

    LD HL,(_playerX)
    LD (asm_px),HL

    LD HL,(_playerY)
    LD (asm_py),HL


    ; =========================================================
    ; MAP X = playerX / 16
    ; MAP Y = playerY / 16
    ; =========================================================

    LD HL,(asm_px)

    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L

    LD A,L
    LD (asm_mapx),A


    LD HL,(asm_py)

    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L

    LD A,L
    LD (asm_mapy),A


    ; =========================================================
    ; RAY = 0
    ; =========================================================

    XOR A
    LD (asm_ray),A


asm_ray_loop:

    ; =========================================================
    ; CARGAR DIR X
    ; =========================================================

    LD HL,(asm_ptr_x)

    LD A,(asm_ray)

    ; Cada INTEGER ocupa 2 bytes
    ADD A,A
    LD E,A
    LD D,0

    ADD HL,DE

    LD E,(HL)
    INC HL
    LD D,(HL)

    LD (asm_dirx),DE


    ; =========================================================
    ; CARGAR DIR Y
    ; =========================================================

    LD HL,(asm_ptr_y)

    LD A,(asm_ray)

    ADD A,A
    LD E,A
    LD D,0

    ADD HL,DE

    LD E,(HL)
    INC HL
    LD D,(HL)

    LD (asm_diry),DE


    ; =========================================================
    ; DELTA DIST X
    ;
    ; delta = 4096 / abs(dir)
    ;
    ; Utilizamos tabla reciprocal.
    ; =========================================================

    LD HL,(asm_dirx)

    BIT 7,H
    JR Z,asm_dx_positive

    XOR A
    SUB L
    LD L,A

    XOR A
    SBC A,H
    LD H,A

asm_dx_positive:

    ; HL = abs(dirX)

    LD A,L

    ; Si es > 255 utilizamos 255
    CP 255
    JR C,asm_dx_index_ok
    LD A,255

asm_dx_index_ok:

    OR A
    JR NZ,asm_dx_nonzero

    LD A,1

asm_dx_nonzero:

    DEC A

    ; indice * 2
    ADD A,A

    LD E,A
    LD D,0

    LD HL,asm_recip
    ADD HL,DE

    LD E,(HL)
    INC HL
    LD D,(HL)

    LD (asm_delta_x),DE


    ; =========================================================
    ; DELTA DIST Y
    ; =========================================================

    LD HL,(asm_diry)

    BIT 7,H
    JR Z,asm_dy_positive

    XOR A
    SUB L
    LD L,A

    XOR A
    SBC A,H
    LD H,A

asm_dy_positive:

    LD A,L

    CP 255
    JR C,asm_dy_index_ok
    LD A,255

asm_dy_index_ok:

    OR A
    JR NZ,asm_dy_nonzero

    LD A,1

asm_dy_nonzero:

    DEC A
    ADD A,A

    LD E,A
    LD D,0

    LD HL,asm_recip
    ADD HL,DE

    LD E,(HL)
    INC HL
    LD D,(HL)

    LD (asm_delta_y),DE


    ; =========================================================
    ; STEP X
    ; =========================================================

    LD HL,(asm_dirx)

    BIT 7,H
    JR Z,asm_stepx_positive

    LD A,255
    LD (asm_stepx),A

    JR asm_stepx_done

asm_stepx_positive:

    LD A,1
    LD (asm_stepx),A

asm_stepx_done:


    ; =========================================================
    ; STEP Y
    ; =========================================================

    LD HL,(asm_diry)

    BIT 7,H
    JR Z,asm_stepy_positive

    LD A,255
    LD (asm_stepy),A

    JR asm_stepy_done

asm_stepy_positive:

    LD A,1
    LD (asm_stepy),A

asm_stepy_done:


    ; =========================================================
    ; SIDE DIST X
    ;
    ; fracX = playerX AND 15
    ; =========================================================

    LD HL,(asm_px)

    LD A,L
    AND 15

    LD B,A

    LD A,(asm_stepx)

    CP 255
    JR NZ,asm_x_positive_side


    ; ---------------------------------------------------------
    ; X negativo
    ; ---------------------------------------------------------

    LD A,B

    JR asm_x_side_ready


asm_x_positive_side:

    LD A,16
    SUB B


asm_x_side_ready:

    ; A = fraccion
    ;
    ; sideDist = fraction * delta / 16

    LD B,A

    LD HL,(asm_delta_x)

    CALL asm_mul_by_b

    ; Divide /16
    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L

    LD (asm_side_x),HL


    ; =========================================================
    ; SIDE DIST Y
    ; =========================================================

    LD HL,(asm_py)

    LD A,L
    AND 15

    LD B,A

    LD A,(asm_stepy)

    CP 255
    JR NZ,asm_y_positive_side

    LD A,B

    JR asm_y_side_ready

asm_y_positive_side:

    LD A,16
    SUB B

asm_y_side_ready:

    LD B,A

    LD HL,(asm_delta_y)

    CALL asm_mul_by_b

    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L
    SRL H
    RR L

    LD (asm_side_y),HL


    ; =========================================================
    ; RESET MAP COORDINATES
    ; =========================================================

    LD A,(asm_mapx)
    LD (asm_cur_mapx),A

    LD A,(asm_mapy)
    LD (asm_cur_mapy),A


    ; =========================================================
    ; DDA
    ; =========================================================

asm_dda_loop:

    ; ---------------------------------------------------------
    ; sideDistX < sideDistY ?
    ; ---------------------------------------------------------

    LD HL,(asm_side_x)
    LD DE,(asm_side_y)

    OR A
    SBC HL,DE

    JR NC,asm_dda_y


    ; =========================================================
    ; AVANZAR X
    ; =========================================================

    LD HL,(asm_delta_x)

    LD DE,(asm_side_x)

    ADD HL,DE

    LD (asm_side_x),HL


    LD A,(asm_cur_mapx)
    LD B,A

    LD A,(asm_stepx)

    CP 255
    JR NZ,asm_x_plus

    DEC B
    JR asm_x_changed

asm_x_plus:

    INC B

asm_x_changed:

    LD A,B
    LD (asm_cur_mapx),A


    LD A,0
    LD (asm_side_hit),A

    JR asm_check_wall


    ; =========================================================
    ; AVANZAR Y
    ; =========================================================

asm_dda_y:

    LD HL,(asm_delta_y)

    LD DE,(asm_side_y)

    ADD HL,DE

    LD (asm_side_y),HL


    LD A,(asm_cur_mapy)
    LD B,A

    LD A,(asm_stepy)

    CP 255
    JR NZ,asm_y_plus

    DEC B
    JR asm_y_changed

asm_y_plus:

    INC B

asm_y_changed:

    LD A,B
    LD (asm_cur_mapy),A


    LD A,1
    LD (asm_side_hit),A


    ; =========================================================
    ; COMPROBAR MAPA
    ; =========================================================

asm_check_wall:

    LD A,(asm_cur_mapx)

    CP 10
    JR NC,asm_force_hit

    LD B,A

    LD A,(asm_cur_mapy)

    CP 8
    JR NC,asm_force_hit

    ; A = mapY
    ;
    ; mapY * 10
    ;
    ; A*8 + A*2

    LD C,A

    ADD A,A
    ADD A,A
    ADD A,A

    LD D,A

    LD A,C
    ADD A,A

    ADD A,D

    ADD A,B

    LD E,A
    LD D,0

    LD HL,(asm_ptr_world)
    ADD HL,DE

    LD A,(HL)

    OR A

    JR Z,asm_dda_loop


asm_force_hit:

    ; ========================================================
    ; HEMOS GOLPEADO UNA PARED
    ; ========================================================

    LD A,(asm_side_hit)

    OR A

    JR NZ,asm_hit_y


    ; ---------------------------------------------------------
    ; HIT X
    ; distance = sideX - deltaX
    ; ---------------------------------------------------------

    LD HL,(asm_side_x)
    LD DE,(asm_delta_x)

    OR A
    SBC HL,DE

    JR asm_store_distance


asm_hit_y:

    ; ---------------------------------------------------------
    ; HIT Y
    ; distance = sideY - deltaY
    ; ---------------------------------------------------------

    LD HL,(asm_side_y)
    LD DE,(asm_delta_y)

    OR A
    SBC HL,DE


asm_store_distance:

    ; Evitar distancia 0
    LD A,H
    OR L
    JR NZ,asm_distance_ok

    LD HL,1

asm_distance_ok:

    ; ========================================================
    ; GUARDAR rayDist[ray]
    ; ========================================================

    LD DE,(asm_ptr_dist)

    LD A,(asm_ray)

    ADD A,A

    LD C,A
    LD B,0

    EX DE,HL

    ADD HL,BC

    LD (HL),E
    INC HL
    LD (HL),D


    ; ========================================================
    ; SIGUIENTE RAYO
    ; ========================================================

    LD A,(asm_ray)

    INC A

    LD (asm_ray),A

    CP 64

    JR C,asm_ray_loop

    RET


    ; =========================================================
    ; MULTIPLICACION 16 * 8
    ;
    ; Entrada:
    ;
    ; HL = valor 16 bits
    ; B  = multiplicador 0..16
    ;
    ; Salida:
    ;
    ; HL = HL * B
    ;
    ; =========================================================

asm_mul_by_b:

    LD DE,0

    LD C,B

asm_mul_loop:

    LD A,C

    OR A

    JR Z,asm_mul_done

    ADD HL,HL

    DEC C

    ; Esta rutina se utiliza solamente para pequeños valores.
    ; Guardamos el valor original en la pila.

    JR asm_mul_slow


asm_mul_slow:

    ; Rehacer multiplicacion de forma sencilla.
    ;
    ; Para evitar complejidad, utilizamos multiplicacion
    ; mediante sumas.

    PUSH HL

    LD HL,0

    LD C,B

asm_mul_add:

    LD A,C
    OR A
    JR Z,asm_mul_finish

    POP DE
    ADD HL,DE
    PUSH HL

    DEC C

    JR asm_mul_add

asm_mul_finish:

    POP HL
    RET


asm_mul_done:

    RET


    ; =========================================================
    ; VARIABLES ASM
    ; =========================================================

asm_ptr_x:
    DEFW 0

asm_ptr_y:
    DEFW 0

asm_ptr_dist:
    DEFW 0

asm_ptr_world:
    DEFW 0

asm_px:
    DEFW 0

asm_py:
    DEFW 0

asm_dirx:
    DEFW 0

asm_diry:
    DEFW 0

asm_delta_x:
    DEFW 0

asm_delta_y:
    DEFW 0

asm_side_x:
    DEFW 0

asm_side_y:
    DEFW 0

asm_mapx:
    DEFB 0

asm_mapy:
    DEFB 0

asm_cur_mapx:
    DEFB 0

asm_cur_mapy:
    DEFB 0

asm_stepx:
    DEFB 0

asm_stepy:
    DEFB 0

asm_side_hit:
    DEFB 0

asm_ray:
    DEFB 0


    ; =========================================================
    ; TABLA DE RECIPROCOS
    ;
    ; reciprocal[n] = 4096 / n
    ;
    ; n = 1..256
    ;
    ; Se almacena como WORD.
    ; =========================================================

asm_recip:

    DEFW 4096
    DEFW 2048
    DEFW 1365
    DEFW 1024
    DEFW 819
    DEFW 682
    DEFW 585
    DEFW 512
    DEFW 455
    DEFW 409
    DEFW 372
    DEFW 341
    DEFW 315
    DEFW 292
    DEFW 273
    DEFW 256

    DEFW 240
    DEFW 227
    DEFW 215
    DEFW 204
    DEFW 195
    DEFW 186
    DEFW 178
    DEFW 170
    DEFW 163
    DEFW 157
    DEFW 151
    DEFW 146
    DEFW 141
    DEFW 136
    DEFW 132
    DEFW 128

    DEFW 124
    DEFW 120
    DEFW 116
    DEFW 113
    DEFW 110
    DEFW 107
    DEFW 105
    DEFW 102
    DEFW 99
    DEFW 97
    DEFW 95
    DEFW 93
    DEFW 91
    DEFW 89
    DEFW 87
    DEFW 85

    DEFW 83
    DEFW 81
    DEFW 80
    DEFW 78
    DEFW 77
    DEFW 75
    DEFW 74
    DEFW 73
    DEFW 71
    DEFW 70
    DEFW 69
    DEFW 68
    DEFW 66
    DEFW 65
    DEFW 64
    DEFW 63

    DEFW 62
    DEFW 61
    DEFW 60
    DEFW 59
    DEFW 58
    DEFW 57
    DEFW 56
    DEFW 56
    DEFW 55
    DEFW 54
    DEFW 53
    DEFW 52
    DEFW 52
    DEFW 51
    DEFW 50
    DEFW 49

    DEFW 49
    DEFW 48
    DEFW 48
    DEFW 47
    DEFW 46
    DEFW 46
    DEFW 45
    DEFW 44
    DEFW 44
    DEFW 43
    DEFW 43
    DEFW 42
    DEFW 42
    DEFW 41
    DEFW 41
    DEFW 40

    DEFW 40
    DEFW 39
    DEFW 39
    DEFW 38
    DEFW 38
    DEFW 37
    DEFW 37
    DEFW 36
    DEFW 36
    DEFW 35
    DEFW 35
    DEFW 35
    DEFW 34
    DEFW 34
    DEFW 33
    DEFW 33

    DEFW 33
    DEFW 32
    DEFW 32
    DEFW 32
    DEFW 31
    DEFW 31
    DEFW 31
    DEFW 30
    DEFW 30
    DEFW 30
    DEFW 29
    DEFW 29
    DEFW 29
    DEFW 29
    DEFW 28
    DEFW 28

    DEFW 28
    DEFW 27
    DEFW 27
    DEFW 27
    DEFW 27
    DEFW 26
    DEFW 26
    DEFW 26
    DEFW 26
    DEFW 25
    DEFW 25
    DEFW 25
    DEFW 25
    DEFW 24
    DEFW 24
    DEFW 24

    DEFW 24
    DEFW 24
    DEFW 23
    DEFW 23
    DEFW 23
    DEFW 23
    DEFW 22
    DEFW 22
    DEFW 22
    DEFW 22
    DEFW 21
    DEFW 21
    DEFW 21
    DEFW 21
    DEFW 21
    DEFW 20

    DEFW 20
    DEFW 20
    DEFW 20
    DEFW 20
    DEFW 20
    DEFW 20
    DEFW 19
    DEFW 19
    DEFW 19
    DEFW 19
    DEFW 19
    DEFW 19
    DEFW 18
    DEFW 18
    DEFW 18
    DEFW 18

    DEFW 18
    DEFW 18
    DEFW 18
    DEFW 18
    DEFW 18
    DEFW 18
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 17
    DEFW 16

    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16
    DEFW 16

END ASM

END SUB


REM ============================================================
REM RENDER
REM ============================================================

SUB Render()

    CLS


    REM --------------------------------------------------------
    REM ACTUALIZAR TRIG
    REM --------------------------------------------------------

    UpdatePlayerTrig()


    REM --------------------------------------------------------
    REM CALCULAR DIRECCIONES
    REM --------------------------------------------------------

    PrepareRays()


    REM --------------------------------------------------------
    REM PASAR PUNTEROS A ASM
    REM --------------------------------------------------------

    asmRayXPtr = @asmRayX(0)
    asmRayYPtr = @asmRayY(0)

    asmRayDistPtr = @rayDist(0)

    asmWorldPtr = @world(0)


    REM --------------------------------------------------------
    REM DDA COMPLETO EN ASM
    REM --------------------------------------------------------

    CastAllRaysASM()


    REM --------------------------------------------------------
    REM RENDER
    REM --------------------------------------------------------

    FOR ray = 0 TO NUM_RAYS - 1


        perpWallDist = rayDist(ray)


        REM ----------------------------------------------------
        REM ALTURA
        REM ----------------------------------------------------

        wallHeight = _
            (TILE * FOCAL_LENGTH) / perpWallDist


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
        REM X
        REM ----------------------------------------------------

        screenX = ray * RAY_WIDTH


        REM ----------------------------------------------------
        REM COLOR
        REM
        REM En esta primera versión no estamos guardando todavía
        REM el lado X/Y en un array.
        REM ----------------------------------------------------

        BRIGHT tonoPared


        REM ----------------------------------------------------
        REM COLUMNA
        REM ----------------------------------------------------

        PLOT screenX, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 1, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 2, wallTop
        DRAW 0, wallBottom - wallTop

        PLOT screenX + 3, wallTop
        DRAW 0, wallBottom - wallTop


    NEXT ray

END SUB


REM ============================================================
REM INICIALIZACION
REM ============================================================

InitMap()

InitRayTable()


REM ------------------------------------------------------------
REM POSICION INICIAL
REM ------------------------------------------------------------

playerX = 2 * TILE + TILE / 2
playerY = 4 * TILE + TILE / 2


REM ------------------------------------------------------------
REM ANGULO
REM ------------------------------------------------------------

playerAngle = 0


REM ------------------------------------------------------------
REM TRIG
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

