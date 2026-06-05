'---------------------------------------------------------------------------
'---                                                                     ---
'---     Motor Grafico pseudo 3D (Ray Cast) en Boriel ZX Basic           ---
'---                                                                     ---
'---                 Programado por: Juan Eguia, 2026                    ---
'---                                                                     ---
'===========================================================================
'---                       C O N S T A N T E S                           ---
'---------------------------------------------------------------------------
Const TILE_X AS Ubyte = 16
Const TILE_Y AS Ubyte = 16
Const NRO_COLUMNAS AS Ubyte = 16
Const NRO_FILAS AS Ubyte = 12
Const RES_X AS Integer = (NRO_COLUMNAS * TILE_X) - 1
Const RES_Y AS Integer = NRO_FILAS * TILE_Y

Const PI_VALUE = 3.141593
Const NUM_RAYOS AS Integer = RES_X
Const FOV AS Ubyte = 60

'===========================================================================
'---                      Variables  O B J E T O S
'---------------------------------------------------------------------------
'---------------------------   J U G A D O R   -----------------------------
'---------------------------------------------------------------------------
DIM jugadorX As Integer
DIM jugadorY As Integer
DIM jugadorAncho As Ubyte
DIM jugadorAlto As Ubyte
DIM jugadorAvanza As Byte
DIM jugadorGira As Byte
DIM jugadorAnguloRotacion As Integer
DIM jugadorVelGiro As Byte
DIM jugadorVelMovimiento As Byte

'---------------------------------------------------------------------------
'------------------------------   R A Y O  ---------------------------------
'---------------------------------------------------------------------------
DIM rayoX(NUM_RAYOS) As Integer
DIM rayoY(NUM_RAYOS) As Integer
DIM rayoAnguloRotacion(NUM_RAYOS) As Integer
DIM rayoIncrementoAngulo(NUM_RAYOS) As Integer
DIM rayoAngulo(NUM_RAYOS) As Integer
DIM rayoWallHitX(NUM_RAYOS) As Byte
DIM rayoWallHitY(NUM_RAYOS) As Byte
DIM rayoWallHitXHorizontal(NUM_RAYOS) As Byte
DIM rayoWallHitYHorizontal(NUM_RAYOS) As Byte
DIM rayoWallHitXVertical(NUM_RAYOS) As Byte
DIM rayoWallHitYVertical(NUM_RAYOS) As Byte
DIM rayoColumna(NUM_RAYOS) As Byte
DIM rayoDistancia(NUM_RAYOS) As Integer
DIM rayoDistanciaPlanoProyeccion(NUM_RAYOS) As Integer
DIM rayohCamara(NUM_RAYOS) As Integer

'---------------------------------------------------------------------------
Dim a, b As Integer
Dim c, d As Ubyte
Dim ciclos As Ubyte
Dim gameOver AS Ubyte = 0

Dim distanciaEntrePuntos As Integer = 0
Dim calculaDistanciaEntrePuntos As Integer = 0
Dim valorTile As Ubyte = 0

Dim tonoPared AS Ubyte = 0
Dim colorPared AS Ubyte = 5

Dim medioFOV As Ubyte = 0
Dim anguloInicial As Integer = 0

Dim modo3d As Ubyte = 0

'--------------------------------------------------------------
Dim tecla As string = ""

Dim keyUp As Ubyte
Dim keyDown As Ubyte
Dim keyLeft As Ubyte
Dim keyRight As Ubyte

'--------------------------------------------------------------
'---            ESCENARIO 1
'--------------------------------------------------------------
DIM escenario(NRO_FILAS - 1, NRO_COLUMNAS - 1) As Ubyte => { _
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}, _
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, _
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, _
    {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,0}, _
    {1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,0}, _
    {1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0}, _
    {1,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0}, _
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, _
    {2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, _
    {3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, _
    {1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0}, _
    {1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0}}

'-------------------------------------------------------------
Declare Function colision_escenario(x As Byte, y As Byte) As Ubyte
Declare Function sub_colisionesHorizontales(a AS Integer) As Ubyte
Declare Function sub_colisionesVerticales(a AS Integer) As Ubyte
Declare Function abajo(a As Integer) As Ubyte
Declare Function izquierda(a As Integer) AS Ubyte

'=============================================================
'--------                                             --------
'--------            INICIALIZACION GENERAL           --------
'--------                                             --------
'-------------------------------------------------------------
BORDER 1
PAPER 0
INK 7
CLS
PRINT AT 12, 7; " Cargando... "

modo3d = 1  '          *** 0 = 2D (Mapa) ...  -1 = 3D  (variable Global) ***
ciclos = 0
gameOver = 0

'-------------------------------------------------------------
'   JUGADOR    VALORES INICIALES
'-------------------------------------------------------------
jugadorX = TILE_X * 4
jugadorY = TILE_Y * 3
jugadorAncho = 1
jugadorAlto = 1

jugadorAnguloRotacion = Cast(Integer, 40 * (PI_VALUE / 180))
jugadorGira = 0
jugadorAvanza = 0
'jugador.velGiro = 0.05236 ' 3 grados
jugadorVelGiro = Cast(Byte, 2 * (PI_VALUE / 180))
jugadorVelMovimiento = 3

'-------------------------------------------------------------
'   R A Y O   VALORES INICIALES
'-------------------------------------------------------------
medioFOV = Cast(Ubyte, FOV / 2)

For a = 0 To NUM_RAYOS

    PRINT AT 2,1; a

    rayoX(a) = jugadorX
    rayoY(a) = jugadorY

    rayoAnguloRotacion(a) = jugadorAnguloRotacion
    rayoIncrementoAngulo(a) = Cast(Integer, (FOV / NUM_RAYOS) * (PI_VALUE / 180))

    anguloInicial = Cast(Integer, rayoAnguloRotacion(a) - medioFOV * (PI_VALUE / 180))
    rayoAngulo(a) = Cast(Integer, anguloInicial + rayoIncrementoAngulo(a) * a)

    rayoWallHitX(a) = 0
    rayoWallHitY(a) = 0
    rayoWallHitXHorizontal(a) = 0
    rayoWallHitYHorizontal(a) = 0
    rayoWallHitXVertical(a) = 0
    rayoWallHitYVertical(a) = 0

    rayoColumna(a) = a
    rayoDistancia(a) = 0
    rayoDistanciaPlanoProyeccion(a) = Cast(Integer, (RES_X / 2) / Tan(FOV / 2))
    rayohCamara(a) = 0

Next a

PRINT AT 1,1; "Bucle principal..."

'============================================================
'--------                                            --------
'--------      B U C L E   P R I N C I P A L         --------
'--------                                            --------
'============================================================
Do
    tecla = ""
    If tecla = CHR$(13) Then gameOver = 1

    dibuja_escenario()
    el_jugador()
    el_rayo()

    ciclos = ciclos + 1
    IF ciclos >= 255 THEN ciclos = 0
    
Loop Until gameOver > 0

'===================================================================
'---                   F I N   P R O G R A M A                   ---
'===================================================================
PAUSE 0
STOP

'===================================================================
'---                                                             ---
'---                    S U B R U T I N A S                      ---
'---                                                             ---
'-------------------------------------------------------------------
Sub dibuja_escenario()

    Dim x As Ubyte
    Dim y As Ubyte

    If modo3d = 0 Then
        'Line (0, 0)-Step(RES_X, RES_Y), gris, BF

        For y = 1 To NRO_FILAS
            For x = 1 To NRO_COLUMNAS
                'If escenario(x, y) = 0 Then Line (x * TILE_X, y * TILE_Y)-Step(TILE_X, TILE_Y), gris, BF

                If (escenario(x, y) > 0) Then
                    Plot x * TILE_X, y * TILE_Y
                    Draw TILE_X, 0
                    Draw 0, TILE_Y
                    Draw -TILE_X, 0
                    Draw 0, -TILE_Y
                End If
            
            Next x
        Next y
    
    Else
        Plot 0, Cast(Byte, RES_Y / 2)
        Draw RES_X, 0
        'Line (0, INT(RES_Y / 2))-Step(RES_X, RES_Y), gris, BF
    End If

End Sub

'===================================================================
Sub el_jugador()

    leer_teclado_jugador()
    actualiza_jugador()
    dibuja_jugador()

End Sub

'===================================================================
Sub leer_teclado_jugador()

    Dim a As Ubyte

    keyUp = 0
    keyDown = 0
    keyLeft = 0
    keyRight = 0

    jugadorAvanza = 0
    jugadorGira = 0

    '------------------------------------------------
    If (In($FBFE) & 1) = 0 Then
        jugadorAvanza = 1
    Else If (In($FDFE) & 1) = 0 Then
        jugadorAvanza = -1
    End If

    '------------------------------------------------
    If (In($DFFE) & 1) = 0 Then
        jugadorGira = 1
    Else If (In($DFFE) & 2) = 0 Then
        jugadorGira = -1
    End If

End Sub

'===================================================================
Sub actualiza_jugador()

    Dim x As Byte
    Dim y As Byte

    Dim nuevaX As Byte
    Dim nuevaY As Byte

    '------------------------------------------
    nuevaX = Cast(Byte, jugadorX + jugadorAvanza * Cos(jugadorAnguloRotacion) * jugadorVelMovimiento)
    nuevaY = Cast(Byte, jugadorY + jugadorAvanza * Sin(jugadorAnguloRotacion) * jugadorVelMovimiento)

    x = Cast(Byte, nuevaX / TILE_X)
    y = Cast(Byte, nuevaY / TILE_Y)

    If (colision_escenario(x, y) = 0) Then
        jugadorX = nuevaX
        jugadorY = nuevaY
    End If

    jugadorAnguloRotacion = Cast(Integer, jugadorAnguloRotacion + jugadorGira * jugadorVelGiro)
    normaliza_angulo_jugador()

End Sub

'===================================================================
Sub dibuja_jugador()

    Dim xDestino As Byte
    Dim yDestino As Byte
    Dim ancho As Ubyte
    Dim alto As Ubyte
    Dim colorJugadorPto As Ubyte

    ancho = jugadorAncho
    alto = jugadorAlto
    colorJugadorPto = 6

    If (modo3d = 0) Then
        'Line (jugador.x - INT(ancho / 2), jugador.y - INT(alto / 2))-Step(ancho, alto), blanco, BF

        INK colorJugadorPto
        Plot jugadorX, jugadorY

        xDestino = Cast(Byte, jugadorX * Cos(jugadorAnguloRotacion) * 0.2)
        yDestino = Cast(Byte, jugadorY * Sin(jugadorAnguloRotacion) * 0.2)

        'LINE (jugador.x, jugador.y)-STEP(xDestino, yDestino), rojo
        Plot jugadorX, jugadorY
        Draw xDestino, yDestino
    End If

End Sub

'================================================================================
Sub el_rayo()

    Dim a As Ubyte

    Dim whx As Byte
    Dim why As Byte
    Dim distanciaHorizontal As Integer
    Dim distanciaVertical As Integer
    Dim distanciaEntrePuntos As Integer
    Dim c As Ubyte
    Dim casilla As Ubyte

    '---------------------------------------------------------------
    For a = 0 To NUM_RAYOS
        ' ----- ACTUALIZAR RAYO antes ------
        sub_actualiza_rayo(a)

        '------------------------------------------------------------------------------------
        '---        CHEQUEAMOS CUAL es el mas CORTO ... HORIZONTAL / VERTICAL??
        '------------------------------------------------------------------------------------
        distanciaHorizontal = 9999 'Inicializamos EXAGERADAMENTE por defecto
        distanciaVertical = 9999

        If (sub_colisionesHorizontales(a) = 1) Then

            whx = rayoWallHitXHorizontal(a)
            why = rayoWallHitYHorizontal(a)
            'distanciaEntrePuntos = Sqr((whx - rayo(a).x) * (whx - rayo(a).x) + (why - rayo(a).y) * (why - rayo(a).y))
            calcula_distancia_entre_puntos(whx, why, rayoX(a), rayoY(a))
            distanciaHorizontal = distanciaEntrePuntos

        End If

        If (sub_colisionesVerticales(a) = 1) Then

            whx = rayoWallHitXVertical(a)
            why = rayoWallHitYVertical(a)
            'distanciaEntrePuntos = Sqr((whx - rayo(a).x) * (whx - rayo(a).x) + (why - rayo(a).y) * (why - rayo(a).y))
            calcula_distancia_entre_puntos(whx, why, rayoX(a), rayoY(a))
            distanciaVertical = distanciaEntrePuntos

        End If

        If (distanciaHorizontal < distanciaVertical) Then

            rayoWallHitX(a) = rayoWallHitXHorizontal(a)
            rayoWallHitY(a) = rayoWallHitYHorizontal(a)
            rayoDistancia(a) = distanciaHorizontal
            tonoPared = 1
            'LINEA DE LA TEXTURA a dibujar ------------
            'casilla = INT(rayo(a).wallHitX / TILE_X) * TILE_X
            'rayo(a).pixelTextura = rayo(a).wallHitX - casilla
            'rayo(a).idTextura = 0 + (nivel - 1) * 100 + rayo(a).valorTH

        Else
            rayoWallHitX(a) = rayoWallHitXVertical(a)
            rayoWallHitY(a) = rayoWallHitYVertical(a)
            rayoDistancia(a) = distanciaVertical
            tonoPared = 0
            'LINEA DE LA TEXTURA a dibujar ------------
            'casilla = INT(rayo(a).wallHitY / TILE_Y) * TILE_Y
            'rayo(a).pixelTextura = rayo(a).wallHitY - casilla
            'rayo(a).idTextura = 0 + (nivel - 1) * 100 + rayo(a).valorTV + 10

        End If

        'corregir_ojoDePez rayo(a)

        'c = rayo(a).columna
        'zBuffer(c) = rayo(a).distancia

        sub_dibuja_rayo(a)

    Next a

End Sub

'================================================================================
Sub corregir_ojoDePez(a As Integer)

    rayoDistancia(a) = rayoDistancia(a) * Cos(rayoAnguloRotacion(a) - rayoAngulo(a))

End Sub

'================================================================================
Function sub_colisionesHorizontales(a As Integer)

    Dim colisionH As Ubyte

    Dim xIntercept As Integer
    Dim yIntercept As Integer

    Dim xStep As Integer
    Dim yStep As Integer

    Dim adyacente As Integer

    Dim siguienteXHorizontal As Integer
    Dim siguienteYHorizontal As Integer

    Dim casillaX As Integer
    Dim casillaY As Integer

    '-----------------------------------------------------------------------
    colisionH = 0

    xIntercept = 0
    yIntercept = 0

    xStep = 0
    yStep = 0

    '-- Buscamos la 1ra INTERSECCION HORIZONTAL ----------------
    yIntercept = INT(rayoY(a) / TILE_Y) * TILE_Y

    ' Si apunta hacia ABAJO, INCREMENTAMOS 1 Tile --------------
    If (abajo(a) = 1) Then yIntercept = yIntercept + TILE_Y

    ' Se le SUMA el cateto ADYACENTE ---------------------------
    adyacente = (yIntercept - rayoY(a)) / Tan(rayoAngulo(a))
    xIntercept = rayoX(a) + adyacente

    ' Calculamos los STEPs -------------------------------------
    yStep = TILE_Y
    xStep = yStep / Tan(rayoAngulo(a)) 'calculamos el otro STEP

    ' Si vamos a la IZQUIERDA o ARRIBA, el paso es negativo ----
    If (abajo(a) = 0) Then yStep = -yStep

    If (((izquierda(a) = 0) AND (xStep > 0)) OR (izquierda(a) = 1) AND (xStep < 0)) Then xStep = -xStep

    '----------------------------------------------------------------------------
    siguienteXHorizontal = xIntercept
    siguienteYHorizontal = yIntercept

    ' Si apunta hacia ARRIBA, FORZAMOS un PIXEL Extra ---------------------------
    If (abajo(a) = 0) Then siguienteYHorizontal = siguienteYHorizontal - 1

    '------------------------------------------------------------------------------------
    '---    BUCLE para BUSCAR el PTO de COLISION (horizontal)
    '------------------------------------------------------------------------------------
    Do
        casillaX = INT(siguienteXHorizontal / TILE_X)
        casillaY = INT(siguienteYHorizontal / TILE_Y)
        'LOCATE 1, 40: PRINT casillaX; casillaY

        If (colision_escenario(casillaX, casillaY) = 1) Then

            colisionH = 1
            rayoWallHitXHorizontal(a) = siguienteXHorizontal
            rayoWallHitYHorizontal(a) = siguienteYHorizontal
            Return 1

        Else
            siguienteXHorizontal = siguienteXHorizontal + xStep
            siguienteYHorizontal = siguienteYHorizontal + yStep
        End If

    Loop Until colisionH = 1

    Return 0

End Function

'================================================================================
Function sub_colisionesVerticales(a As Integer)

    Dim colisionV As Ubyte

    Dim xIntercept As Integer
    Dim yIntercept As Integer

    Dim xStep As Integer
    Dim yStep As Integer

    Dim opuesto As Integer

    Dim siguienteXVertical As Integer
    Dim siguienteYVertical As Integer

    Dim casillaX As Integer
    Dim casillaY As Integer

    '--------------------------------------------------------------------------
    colisionV = 0

    xIntercept = 0
    yIntercept = 0

    xStep = 0
    yStep = 0

    '-- Buscamos la 1ra INTERSECCION VERTICAL -----------------
    xIntercept = INT(rayoX(a) / TILE_X) * TILE_X

    ' Si apunta hacia DCHA, INCREMENTAMOS 1 Tile --------------
    If (izquierda(a) = 0) Then xIntercept = xIntercept + TILE_X
    'xIntercept = xIntercept + TILE_X

    ' Se le SUMA el cateto OPUESTO ---------------------------
    opuesto = (xIntercept - rayoX(a)) * Tan(rayoAngulo(a))
    yIntercept = rayoY(a) + opuesto

    ' Calculamos los STEPs -------------------------------------
    xStep = TILE_X

    ' Si vamos a la IZQUIERDA, INVERTIMOS -----------------------
    If (izquierda(a) = 1) Then xStep = -xStep

    yStep = TILE_X * Tan(rayoAngulo(a)) 'calculamos el otro STEP

    If ((abajo(a) = 0) AND (yStep > 0) OR (abajo(a) = 1) AND (yStep < 0)) Then yStep = -yStep

    '------------------------------------------------------------------------------
    siguienteXVertical = xIntercept
    siguienteYVertical = yIntercept

    ' Si apunta hacia IZQUIERDA, FORZAMOS un PIXEL Extra --------------------
    If (izquierda(a) = 1) Then siguienteXVertical = siguienteXVertical - 1

    '------------------------------------------------------------------------------------
    '--- BUCLE para BUSCAR el PTO de COLISION (vertical)
    '------------------------------------------------------------------------------------
    Do
        casillaX = INT(siguienteXVertical / TILE_X)
        casillaY = INT(siguienteYVertical / TILE_Y)
        'LOCATE 5, 10: PRINT casillaX; casillaY

        If (colision_escenario(casillaX, casillaY) = 1) Then

            colisionV = 1
            rayoWallHitXVertical(a) = siguienteXVertical
            rayoWallHitYVertical(a) = siguienteYVertical
            Return 1

        Else
            siguienteXVertical = siguienteXVertical + xStep
            siguienteYVertical = siguienteYVertical + yStep
        End If

    Loop Until colisionV = 1

    Return 0

End Function

'================================================================================
Sub sub_dibuja_rayo(a As Integer)

    Dim xDestino As Integer
    Dim yDestino As Integer

    xDestino = Cast(Integer, rayoWallHitX(a))
    yDestino = Cast(Integer, rayoWallHitY(a))

    INK 4

    If (modo3d = 0) Then
        Plot rayoX(a), rayoY(a)
        Draw xDestino, yDestino
    Else
        sub_render_pared(a)
    End If

End Sub

'================================================================================
Sub sub_actualiza_rayo(a As Integer)

    rayoAnguloRotacion(a) = jugadorAnguloRotacion
    'rayo(a).angulo = rayo(a).anguloRotacion - medioFOV + rayo(a).incrementoAngulo * a
    rayoAngulo(a) = rayoAngulo(a) + jugadorGira * jugadorVelGiro
    normaliza_angulo_rayo(a)

    rayoX(a) = jugadorX
    rayoY(a) = jugadorY

End Sub

'================================================================================
Sub sub_render_pared(a As Ubyte)

    Dim altoTile As Ubyte
    Dim alturaMuro As Integer

    Dim y0 As Integer
    Dim y1 As Integer
    Dim x As Integer

    altoTile = RES_Y 'RES_Y era lo que aprendi (por defecto)
    alturaMuro = Cast(Integer, (altoTile / rayoDistancia(a)) * rayoDistanciaPlanoProyeccion(a))

    y0 = Cast(Integer, RES_Y / 2 - INT(alturaMuro / 2))
    y1 = y0 + alturaMuro
    x = rayoColumna(a)

    '------------------------------------------
    BRIGHT tonoPared
    INK colorPared

    Plot x, y0
    Draw x, y1
    'Line (x, y0)-(x, y1), tonoPared
    '------------------------------------------
End Sub

'=======================================================================
Sub calcula_distancia_entre_puntos(jugX As Byte, jugY As Byte, sprX As Byte, sprY As Byte)

    calculaDistanciaEntrePuntos = 0
    calculaDistanciaEntrePuntos = Sqr((sprX - jugX) * (sprX - jugX) + (sprY - jugY) * (sprY - jugY))

End Sub

'=======================================================================
Function colision_escenario(x As Byte, y As Byte)

    If (x > NRO_COLUMNAS OR y > NRO_FILAS OR x < 0 OR y < 0) Then Return 1
    If (escenario(x, y) > 0) Then Return 1

    Return 0

End Function

'=======================================================================
Sub valor_tile(x As Byte, y As Byte)

    valorTile = 0

    If (x > NRO_COLUMNAS OR y > NRO_FILAS OR x < 0 OR y < 0) Then
        valorTile = 1
        Return
    End If

    valorTile = escenario(x, y)

End Sub

'=======================================================================
Function abajo(a As Integer)

    If (rayoAngulo(a) < PI_VALUE) Then Return 1

    Return 0

End Function

'=======================================================================
Function izquierda(a As Integer)

    If (rayoAngulo(a) > PI_VALUE / 2 AND rayoAngulo(a) < 3 * (PI_VALUE / 2)) Then Return 1

    Return 0

End Function

'=======================================================================
Sub normaliza_angulo_jugador()

    If (jugadorAnguloRotacion < 0) Then
        jugadorAnguloRotacion = jugadorAnguloRotacion + 2 * PI_VALUE
        Return
    End If

    If (jugadorAnguloRotacion > 2 * PI_VALUE) Then
        jugadorAnguloRotacion = jugadorAnguloRotacion - 2 * PI_VALUE
        Return
    End If

End Sub

'=======================================================================
Sub normaliza_angulo_rayo(a As Integer)

    If (rayoAngulo(a) < 0) Then
        rayoAngulo(a) = rayoAngulo(a) + 2 * PI_VALUE
        Return
    End If

    If (rayoAngulo(a) > 2 * PI_VALUE) Then
        rayoAngulo(a) = rayoAngulo(a) - 2 * PI_VALUE
        Return
    End If

End Sub

'=======================================================================
Sub cambia_modo()

    If (modo3d = 0) Then modo3d = 1 Else modo3d = 0 ' 1 = 2D / 0 = 3D
    Beep 0.5, -10

End Sub

'=======================================================================
Sub mostrar_marcadores()

End Sub

'============================================================================
SUB soniquete(ini AS Byte, fin AS Byte)

    DIM c AS Byte

    FOR c = ini TO fin
        BEEP 0.01, c
    NEXT c 

END SUB

