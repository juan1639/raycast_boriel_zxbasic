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
Const RES_X AS Ubyte = (NRO_COLUMNAS * TILE_X) - 1
Const RES_Y AS Ubyte = NRO_FILAS * TILE_Y

Const PI_VALUE = 3.141593
Const NUM_RAYOS AS Ubyte = RES_X
Const FOV AS Ubyte = 60

'===========================================================================
'---                      Variables  O B J E T O S
'---------------------------------------------------------------------------
'---------------------------   J U G A D O R   -----------------------------
'---------------------------------------------------------------------------
DIM jugadorX As Byte
DIM jugadorY As Byte
DIM jugadorAncho As Ubyte
DIM jugadorAlto As Ubyte
DIM jugadorAvanza As Byte
DIM jugadorGira As Integer
DIM jugadorAnguloRotacion As Integer
DIM jugadorVelGiro As Byte
DIM jugadorVelMovimiento As Byte

'---------------------------------------------------------------------------
'------------------------------   R A Y O  ---------------------------------
'---------------------------------------------------------------------------
DIM rayoX(NUM_RAYOS) As Byte
DIM rayoY(NUM_RAYOS) As Byte
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
Dim a, b, c As Ubyte
Dim ciclos As Ubyte
Dim gameOver AS Ubyte = 0

Dim distanciaEntrePuntos As Integer = 0
Dim calculaDistanciaEntrePuntos As Integer = 0
Dim valorTile As Ubyte = 0

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

'=============================================================
'--------                                             --------
'--------            INICIALIZACION GENERAL           --------
'--------                                             --------
'-------------------------------------------------------------
CLS
PRINT AT 12, 7; " Cargando... "

modo3d = 0  '          *** 0 = 2D (Mapa) ...  -1 = 3D  (variable Global) ***
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

For a = 1 To NUM_RAYOS

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
    'el_rayo()

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
                End If
            
            Next x
        Next y
    
    Else
        Plot 0, Cast(Byte, RES_Y / 2)
        Draw RES_X, 0
        'Line (0, Int(RES_Y / 2))-Step(RES_X, RES_Y), gris, BF
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
        'Line (jugador.x - Int(ancho / 2), jugador.y - Int(alto / 2))-Step(ancho, alto), blanco, BF

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

    Dim a As Integer

    Dim whx As Single
    Dim why As Single
    Dim distanciaHorizontal As Single
    Dim distanciaVertical As Single
    Dim distanciaEntrePuntos As Single
    Dim c As Single
    Dim casilla As Integer

    Shared rayo() As rayo
    Shared jugador As jugador
    Shared zBuffer() As Single
    Shared nivel As Integer

    '---------------------------------------------------------------
    For a = 1 To NUM_RAYOS
        sub_actualiza_rayo rayo(), a ' --- ACTUALIZAR RAYO antes ---

        '------------------------------------------------------------------------------------
        '---        CHEQUEAMOS CUAL es el mas CORTO ... HORIZONTAL / VERTICAL??
        '------------------------------------------------------------------------------------
        distanciaHorizontal = 9999 'Inicializamos EXAGERADAMENTE por defecto
        distanciaVertical = 9999

        If sub_colisionesHorizontales(rayo(), a) Then
            whx = rayo(a).wallHitXHorizontal
            why = rayo(a).wallHitYHorizontal
            'distanciaEntrePuntos = Sqr((whx - rayo(a).x) * (whx - rayo(a).x) + (why - rayo(a).y) * (why - rayo(a).y))
            distanciaEntrePuntos = calculaDistanciaEntrePuntos(whx, why, rayo(a).x, rayo(a).y)
            distanciaHorizontal = distanciaEntrePuntos
        End If

        If sub_colisionesVerticales(rayo(), a) Then
            whx = rayo(a).wallHitXVertical
            why = rayo(a).wallHitYVertical
            'distanciaEntrePuntos = Sqr((whx - rayo(a).x) * (whx - rayo(a).x) + (why - rayo(a).y) * (why - rayo(a).y))
            distanciaEntrePuntos = calculaDistanciaEntrePuntos(whx, why, rayo(a).x, rayo(a).y)
            distanciaVertical = distanciaEntrePuntos
        End If

        If distanciaHorizontal < distanciaVertical Then
            rayo(a).wallHitX = rayo(a).wallHitXHorizontal
            rayo(a).wallHitY = rayo(a).wallHitYHorizontal
            rayo(a).distancia = distanciaHorizontal
            colorPared = pared_claro
            'LINEA DE LA TEXTURA a dibujar ------------
            casilla = Int(rayo(a).wallHitX / TILE_X) * TILE_X
            rayo(a).pixelTextura = rayo(a).wallHitX - casilla
            rayo(a).idTextura = 0 + (nivel - 1) * 100 + rayo(a).valorTH
        Else
            rayo(a).wallHitX = rayo(a).wallHitXVertical
            rayo(a).wallHitY = rayo(a).wallHitYVertical
            rayo(a).distancia = distanciaVertical
            colorPared = pared_oscuro
            'LINEA DE LA TEXTURA a dibujar ------------
            casilla = Int(rayo(a).wallHitY / TILE_Y) * TILE_Y
            rayo(a).pixelTextura = rayo(a).wallHitY - casilla
            rayo(a).idTextura = 0 + (nivel - 1) * 100 + rayo(a).valorTV + 10
        End If

        corregir_ojoDePez rayo(), a

        c = rayo(a).columna
        zBuffer(c) = rayo(a).distancia

        sub_dibuja_rayo rayo(), a

    Next a

End Sub

'================================================================================
Sub corregir_ojoDePez(rayo() As rayo, a As Integer)

    rayo(a).distancia = rayo(a).distancia * Cos(rayo(a).anguloRotacion - rayo(a).angulo)

End Sub

'================================================================================
Function sub_colisionesHorizontales(rayo() As rayo, a As Integer)

    Dim colisionH As _Bit

    Dim xIntercept As Single
    Dim yIntercept As Single

    Dim xStep As Single
    Dim yStep As Single

    Dim adyacente As Single

    Dim siguienteXHorizontal As Single
    Dim siguienteYHorizontal As Single

    Dim casillaX As Integer
    Dim casillaY As Integer

    '-----------------------------------------------------------------------
    sub_colisionesHorizontales = 0
    colisionH = 0

    xIntercept = 0
    yIntercept = 0

    xStep = 0
    yStep = 0

    '-- Buscamos la 1ra INTERSECCION HORIZONTAL ----------------
    yIntercept = Int(rayo(a).y / TILE_Y) * TILE_Y

    ' Si apunta hacia ABAJO, INCREMENTAMOS 1 Tile --------------
    If abajo(rayo(), a) Then yIntercept = yIntercept + TILE_Y

    ' Se le SUMA el cateto ADYACENTE ---------------------------
    adyacente = (yIntercept - rayo(a).y) / Tan(rayo(a).angulo)
    xIntercept = rayo(a).x + adyacente

    ' Calculamos los STEPs -------------------------------------
    yStep = TILE_Y
    xStep = yStep / Tan(rayo(a).angulo) 'calculamos el otro STEP

    ' Si vamos a la IZQUIERDA o ARRIBA, el paso es negativo ----
    If Not abajo(rayo(), a) Then yStep = -yStep

    If (izquierda(rayo(), a) And xStep > 0) Or (Not izquierda(rayo(), a) And xStep < 0) Then xStep = -xStep

    '----------------------------------------------------------------------------
    siguienteXHorizontal = xIntercept
    siguienteYHorizontal = yIntercept

    ' Si apunta hacia ARRIBA, FORZAMOS un PIXEL Extra ---------------------------
    If Not abajo(rayo(), a) Then siguienteYHorizontal = siguienteYHorizontal - 1

    '------------------------------------------------------------------------------------
    '---    BUCLE para BUSCAR el PTO de COLISION (horizontal)
    '------------------------------------------------------------------------------------
    Do
        casillaX = Int(siguienteXHorizontal / TILE_X)
        casillaY = Int(siguienteYHorizontal / TILE_Y)
        'LOCATE 1, 40: PRINT casillaX; casillaY

        If colision_escenario(casillaX, casillaY) Then
            sub_colisionesHorizontales = -1
            colisionH = -1
            rayo(a).valorTH = valorTile(casillaX, casillaY)
            rayo(a).wallHitXHorizontal = siguienteXHorizontal
            rayo(a).wallHitYHorizontal = siguienteYHorizontal
        Else
            siguienteXHorizontal = siguienteXHorizontal + xStep
            siguienteYHorizontal = siguienteYHorizontal + yStep
        End If

    Loop Until colisionH

End Function

'================================================================================
Function sub_colisionesVerticales(rayo() As rayo, a As Integer)

    Dim colisionV As _Bit

    Dim xIntercept As Single
    Dim yIntercept As Single

    Dim xStep As Single
    Dim yStep As Single

    Dim opuesto As Single

    Dim siguienteXVertical As Single
    Dim siguienteYVertical As Single

    Dim casillaX As Integer
    Dim casillaY As Integer

    '--------------------------------------------------------------------------
    sub_colisionesVerticales = 0
    colisionV = 0

    xIntercept = 0
    yIntercept = 0

    xStep = 0
    yStep = 0

    '-- Buscamos la 1ra INTERSECCION VERTICAL ----------------
    xIntercept = Int(rayo(a).x / TILE_X) * TILE_X

    ' Si apunta hacia DCHA, INCREMENTAMOS 1 Tile --------------
    If Not izquierda(rayo(), a) Then xIntercept = xIntercept + TILE_X
    'xIntercept = xIntercept + TILE_X

    ' Se le SUMA el cateto OPUESTO ---------------------------
    opuesto = (xIntercept - rayo(a).x) * Tan(rayo(a).angulo)
    yIntercept = rayo(a).y + opuesto

    ' Calculamos los STEPs -------------------------------------
    xStep = TILE_X

    ' Si vamos a la IZQUIERDA, INVERTIMOS -----------------------
    If izquierda(rayo(), a) Then xStep = -xStep

    yStep = TILE_X * Tan(rayo(a).angulo) 'calculamos el otro STEP

    If (Not abajo(rayo(), a) And yStep > 0) Or (abajo(rayo(), a) And yStep < 0) Then yStep = -yStep

    '------------------------------------------------------------------------------
    siguienteXVertical = xIntercept
    siguienteYVertical = yIntercept

    ' Si apunta hacia IZQUIERDA, FORZAMOS un PIXEL Extra --------------------
    If izquierda(rayo(), a) Then siguienteXVertical = siguienteXVertical - 1

    '------------------------------------------------------------------------------------
    '--- BUCLE para BUSCAR el PTO de COLISION (vertical)
    '------------------------------------------------------------------------------------
    Do
        casillaX = Int(siguienteXVertical / TILE_X)
        casillaY = Int(siguienteYVertical / TILE_Y)
        'LOCATE 5, 10: PRINT casillaX; casillaY

        If colision_escenario(casillaX, casillaY) Then
            sub_colisionesVerticales = -1
            colisionV = -1
            rayo(a).valorTV = valorTile(casillaX, casillaY)
            rayo(a).wallHitXVertical = siguienteXVertical
            rayo(a).wallHitYVertical = siguienteYVertical
        Else
            siguienteXVertical = siguienteXVertical + xStep
            siguienteYVertical = siguienteYVertical + yStep
        End If

    Loop Until colisionV

End Function

'================================================================================
Sub sub_dibuja_rayo(rayo() As rayo, a As Integer)

    Dim xDestino As Single
    Dim yDestino As Single

    xDestino = rayo(a).wallHitX
    yDestino = rayo(a).wallHitY

    If Not modo3d Then
        Line (rayo(a).x, rayo(a).y)-(xDestino, yDestino), verde
    Else
        sub_render_pared rayo(), a
    End If

End Sub

Sub sub_actualiza_rayo(rayo() As rayo, a As Integer)

    Shared jugador As jugador

    rayo(a).anguloRotacion = jugador.anguloRotacion
    'rayo(a).angulo = rayo(a).anguloRotacion - medioFOV + rayo(a).incrementoAngulo * a
    rayo(a).angulo = rayo(a).angulo + jugador.gira * jugador.velGiro
    normaliza_angulo_rayo rayo(), a

    rayo(a).x = jugador.x
    rayo(a).y = jugador.y

End Sub

'================================================================================
Sub sub_render_pared(rayo() As rayo, a)

    Dim altoTile As Single
    Dim alturaMuro As Single

    Dim y0 As Single
    Dim y1 As Single
    Dim x As Integer

    Dim altura As Single
    Dim altoTextura As Single
    Dim alturaTextura As Single
    Dim idTxt As Integer

    Shared renderTexturas As _Bit
    Shared texturaPared() As Long

    altoTile = RES_Y 'RES_Y era lo que aprendi (por defecto)
    alturaMuro = (altoTile / rayo(a).distancia) * rayo(a).distanciaPlanoProyeccion

    y0 = RES_Y / 2 - Int(alturaMuro / 2)
    y1 = y0 + alturaMuro
    x = rayo(a).columna

    altura = 0
    altoTextura = 64
    alturaTextura = y0 - y1

    If Not renderTexturas Then
        Line (x, y0)-(x, y1), colorPared
    Else
        idTxt = rayo(a).idTextura
        _PutImage (x, y0)-(x, y1), texturaPared(idTxt), , (rayo(a).pixelTextura, 0)-Step(0, altoTextura)
    End If

End Sub

'=======================================================================
Sub calcula_distancia_entre_puntos(jugX, jugY, sprX, sprY)

    calculaDistanciaEntrePuntos = 0
    calculaDistanciaEntrePuntos = Sqr((sprX - jugX) * (sprX - jugX) + (sprY - jugY) * (sprY - jugY))

End Sub

'=======================================================================
Function colision_escenario(x As Byte, y As Byte)

    If (x > NRO_COLUMNAS OR y > NRO_FILAS OR x < 1 OR y < 1) Then Return 1
    If (escenario(x, y) > 0) Then Return 1

    Return 0

End Function

'=======================================================================
Sub valor_tile(x As Byte, y As Byte)

    valorTile = 0

    If (x > NRO_COLUMNAS OR y > NRO_FILAS OR x < 1 OR y < 1) Then
        valorTile = 1
        Return
    End If

    valorTile = escenario(x, y)

End Sub

'=======================================================================
Function abajo(a As Integer)

    If (rayo(a).angulo < PI_VALUE) Then Return 1

    Return 0

End Function

'=======================================================================
Function izquierda(a As Integer)

    If (rayo(a).angulo > PI_VALUE / 2 AND rayo(a).angulo < 3 * (PI_VALUE / 2)) Then Return 1

    Return 0

End Function

'=======================================================================
Sub normaliza_angulo()

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

    If (rayo(a).angulo < 0) Then
        rayo(a).angulo = rayo(a).angulo + 2 * PI_VALUE
        Return
    End If

    If (rayo(a).angulo > 2 * PI_VALUE) Then
        rayo(a).angulo = rayo(a).angulo - 2 * PI_VALUE
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

