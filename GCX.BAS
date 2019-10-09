'Makes memory allocation Dynamic.
'$DYNAMIC

'Makes all symbols (Variable, Constants and Functions) starting with letters
'B, D, I, K or S default as integer.
DEFINT B, D, I, K, S

'Includes files necessary for program to run.
'$INCLUDE: 'KEYB.INC'
'$INCLUDE: 'PLOT.INC'
'$INCLUDE: 'STRUCT.INC'

'Routines used in game.
DECLARE SUB BMPSAVE (Filename$)
DECLARE SUB HALLFAME (lScore AS LONG)
DECLARE SUB INITGAME ()
DECLARE SUB INITGRAPHICS ()
DECLARE SUB INITENEMYCLASSES ()
DECLARE SUB MOVE (iShip AS INTEGER, dDir AS INTEGER, iCost AS INTEGER)
DECLARE SUB SHOOT (iShip AS INTEGER, iShot AS INTEGER)
DECLARE SUB UPDATESHIP (ShipIndex AS INTEGER)

DECLARE FUNCTION COLLISION% (Shot AS ANY, Ship AS ANY)
DECLARE FUNCTION MAINMENU% ()
DECLARE FUNCTION RUNGAME& ()

'Base path to resource files.
CONST BasePath$ = "Data\"

'Boolean constants for use in game.
CONST bTRUE = -1
CONST bFALSE = 0

'Direction constants for shots.
CONST dDOWN = 1
CONST dUP = -1
CONST dLEFT = -1
CONST dRIGHT = 1

'Maximum limits of objects on screen.
CONST iMAXENEMY = 6
CONST iMAXSTARS = 100
CONST iMINSTARS = 75
CONST iMAXSHOTS = 100

'Possible State of ships.
CONST sNORMAL = 0
CONST sEXPLO1 = 1
CONST sEXPLO2 = 3
CONST sUNEXST = 5

'"Makes numbers more random".
RANDOMIZE TIMER

'Graphical arrays used.
DIM Pal(255)      AS LONG
DIM Effect(64, 9) AS LONG
DIM MaskSp(64, 2) AS LONG
DIM Sprite(64, 2) AS LONG

'Elements count in the game.
DIM iEnemyCount AS INTEGER
DIM iShotCount  AS INTEGER
DIM iStarCount  AS INTEGER

'Data used by game.
DIM Cost(2)             AS EnergyCostsType
DIM EnemyClass(1)       AS EnemyShipClassType
DIM Ship(iMAXENEMY)     AS ShipType
DIM Shot(iMAXSHOTS - 1) AS ShotType
DIM Star(iMAXSTARS - 1) AS StarType

'Lines to check out how much more free memory the program can use
'PRINT "Size of next free block:"; FRE(0)
'PRINT "Largest Array: "; FRE(-1)
'PRINT "Unused Stack Space Available: "; FRE(-2)
'PRINT "Free string storage space: "; FRE("")
'SYSTEM

'Initializes graphical mode and clears screen.
SCREEN 13
CLS

'Installs keyboard library and initializes graphics.
INSTALLKEYB
INITGRAPHICS
INITENEMYCLASSES

'Lines to show game sprites (had to check indexes a lot during development).
'FOR i = 0 TO 9
'    PUT (i * 16, 0), Effect(0, i)
'NEXT i
'FOR i = 0 TO 2
'    PUT (i * 16 + 48, 16), MaskSp(0, i)
'    PUT (i * 16, 16), Sprite(0, i)
'NEXT i
'SYSTEM

'Main menu loop, calls MainMenu function and reads output, if 0 starts the
'game, if 1 enters game options and if 2 exits program.
DIM iOption AS INTEGER
DIM lScore  AS LONG
DO
   iOption = MAINMENU
   SELECT CASE iOption
   CASE 0
       CLRSCR
       lScore = RUNGAME
       HALLFAME lScore
  
   CASE 1
       HALLFAME 0
     
   CASE ELSE
       EXIT DO
   END SELECT
LOOP

'Clean-up before leaving program
UNINSTALLKEYB
SCREEN 0
WIDTH 80, 25

'Thanking message
PRINT "Thank you for playing Galactic Cruise X!"
SYSTEM

REM $STATIC
'This rountine checks for collisions between shots and ships, if collision
'has ocurred it returns bTRUE == -1, if not it returns bFALSE == 0.
FUNCTION COLLISION% (Shot AS ShotType, Ship AS ShipType)

'Initializes return value to bFALSE == 0.
COLLISION% = bFALSE

'As horizontal conditions for shots going in either direction are the same and
'would have to be coded twice, I just did it once before direction checking.
IF (((Ship.Position.X + Ship.Boundaries.Right) >= (Shot.Position.X + Shot.Boundaries.Left)) AND ((Ship.Position.X + Ship.Boundaries.Left) <= (Shot.Position.X + Shot.Boundaries.Right))) THEN
   
    'Do vertical collision checking based on shot's direction, return
    'bTRUE == -1 in case collision is detected
    IF (Shot.Direction = dUP) THEN
        IF ((Ship.Position.Y + Ship.Boundaries.Bottom) >= (Shot.Position.Y + Shot.Boundaries.Top)) THEN COLLISION% = bTRUE
    ELSE
        IF ((Ship.Position.Y + Ship.Boundaries.Top) <= (Shot.Position.Y + Shot.Boundaries.Bottom)) THEN COLLISION% = bTRUE
    END IF

END IF

END FUNCTION

SUB HALLFAME (lScore AS LONG)
    DIM iNum AS INTEGER
    DIM Entry(10) AS EntryType

    OPEN BasePath$ + "HALL.DAT" FOR BINARY AS #1

    IF (LOF(1) <> 0) THEN
        FOR iNum = 0 TO 9
            GET #1, , Entry(iNum)
        NEXT iNum
    ELSE
        Entry(0).PName = "Lucas Kanebley Tavares"
        Entry(0).Score = 40750
        FOR iNum = 1 TO 9
            Entry(iNum).PName = ""
            Entry(iNum).Score = 0
        NEXT iNum
    END IF
        
    IF (lScore > 0) THEN
        IF (lScore > Entry(9).Score) THEN
            DIM PName AS STRING * 30
            CLS : LOCATE 1, 1
            INPUT "ENTER YOUR NAME: ", PName

            FOR iNum = 8 TO 0 STEP -1
                Entry(iNum + 1) = Entry(iNum)
                IF (lScore < Entry(iNum).Score) THEN
                    EXIT FOR
                END IF
            NEXT iNum
            Entry(iNum + 1).PName = PName
            Entry(iNum + 1).Score = lScore
     
            SEEK #1, 1
            FOR iNum = 0 TO 9
                PUT #1, , Entry(iNum)
            NEXT iNum
        END IF
    END IF

    CLS
    COLOR 4
    LOCATE 6, 14: PRINT "HALL OF FAME"

    FOR iNum = 0 TO 9
        COLOR 9
        LOCATE 8 + iNum, 1
        PRINT USING "##.& ######"; iNum + 1; Entry(iNum).PName; Entry(iNum).Score
    NEXT iNum
    SLEEP

    CLOSE #1
END SUB

'This routine sets up enemy ships classes.
SUB INITENEMYCLASSES

'"Imports" locally declared array in main module, this way it doesn't have to
'be passed as an argument.
SHARED EnemyClass() AS EnemyShipClassType

'Defines ship's boundaries.
EnemyClass(0).Boundaries.Top = 0
EnemyClass(0).Boundaries.Left = 2
EnemyClass(0).Boundaries.Bottom = 9
EnemyClass(0).Boundaries.Right = 13

'Defines ship's energy settings.
EnemyClass(0).Cost.MOVE = 10
EnemyClass(0).Cost.Shot = 65
EnemyClass(0).EnergyRestoreSpeed = 50
EnemyClass(0).MaxEnergy = 480

'Defines ship's control variables.
EnemyClass(0).Acceleration = 4
EnemyClass(0).Inteligence = 0

'Defines ship's shot boundaries.
EnemyClass(0).ShotBounds.Top = 7
EnemyClass(0).ShotBounds.Left = 2
EnemyClass(0).ShotBounds.Bottom = 10
EnemyClass(0).ShotBounds.Right = 13

'Defines ship's shot information.
EnemyClass(0).ShotType = 1
EnemyClass(0).ShotSpeed = 3

'Defines ship's boundaries.
EnemyClass(1).Boundaries.Top = 1
EnemyClass(1).Boundaries.Left = 2
EnemyClass(1).Boundaries.Bottom = 11
EnemyClass(1).Boundaries.Right = 13

'Defines ship's energy settings.
EnemyClass(1).Cost.MOVE = 5
EnemyClass(1).Cost.Shot = 60
EnemyClass(1).EnergyRestoreSpeed = 30
EnemyClass(1).MaxEnergy = 280

'Defines ship's control variables.
EnemyClass(1).Acceleration = 3
EnemyClass(1).Inteligence = 1

'Defines ship's shot boundaries.
EnemyClass(1).ShotBounds.Top = 10
EnemyClass(1).ShotBounds.Left = 4
EnemyClass(1).ShotBounds.Bottom = 11
EnemyClass(1).ShotBounds.Right = 11

'Defines ship's shot information.
EnemyClass(1).ShotType = 2
EnemyClass(1).ShotSpeed = 7

END SUB

'This routines initializes all game data.
SUB INITGAME

'"Imports" locally declared arrays in main module, this way they don't have to
'be passed as arguments.
SHARED Cost()       AS EnergyCostsType
SHARED EnemyClass() AS EnemyShipClassType
SHARED Ship()       AS ShipType
SHARED Shot()       AS ShotType
SHARED Star()       AS StarType

'"Imports" locally declared variables in main module, this way they don't
'have to be passed as arguments.
SHARED iEnemyCount AS INTEGER
SHARED iStarCount  AS INTEGER

Cost(0).MOVE = 30
Cost(0).Shot = 50

Cost(1).MOVE = EnemyClass(0).Cost.MOVE
Cost(1).Shot = EnemyClass(0).Cost.Shot

Cost(2).MOVE = EnemyClass(1).Cost.MOVE
Cost(2).Shot = EnemyClass(1).Cost.Shot

'Declares multiple purpose indexing variable for loops.
DIM iNum AS INTEGER

'Defines ship's boundaries.
Ship(0).Boundaries.Top = 0
Ship(0).Boundaries.Left = 1
Ship(0).Boundaries.Bottom = 14
Ship(0).Boundaries.Right = 14

'Defines ship's energy settings.
Ship(0).Energy = 320
Ship(0).MaxEnergy = 320
Ship(0).EnergyRestoreSpeed = 40

'Defines ship's control variables.
Ship(0).Acceleration = 5
Ship(0).Speed = 0
Ship(0).State = sNORMAL

'Initializes ship's position.
Ship(0).Position.X = INT((303 - 0 + 1) * RND + 0)
Ship(0).Position.Y = 200 - 32 - 16 - 1

'Defines own type (not used except for enemy ships).
Ship(0).ShipType = 0

'Defines ship's shot boundaries.
Ship(0).ShotBounds.Top = 5
Ship(0).ShotBounds.Left = 2
Ship(0).ShotBounds.Bottom = 8
Ship(0).ShotBounds.Right = 13

'Defines ship's shot information.
Ship(0).ShotType = 0
Ship(0).ShotSpeed = 2

'Initializes enemy count.
iEnemyCount = INT((iMAXENEMY - 1 + 1) * RND + 1)

'Loops through all enemies setting them up.
FOR iNum = 1 TO iEnemyCount
    
    Ship(iNum).ShipType = INT((1 - 0 + 1) * RND + 0)
   
    Ship(iNum).Boundaries.Top = EnemyClass(Ship(iNum).ShipType).Boundaries.Top
    Ship(iNum).Boundaries.Left = EnemyClass(Ship(iNum).ShipType).Boundaries.Left
    Ship(iNum).Boundaries.Bottom = EnemyClass(Ship(iNum).ShipType).Boundaries.Bottom
    Ship(iNum).Boundaries.Right = EnemyClass(Ship(iNum).ShipType).Boundaries.Right

    Ship(iNum).Energy = EnemyClass(Ship(iNum).ShipType).MaxEnergy
    Ship(iNum).MaxEnergy = EnemyClass(Ship(iNum).ShipType).MaxEnergy
    Ship(iNum).EnergyRestoreSpeed = EnemyClass(Ship(iNum).ShipType).EnergyRestoreSpeed

    Ship(iNum).Position.X = INT((303 - 0 + 1) * RND + 0)
    Ship(iNum).Position.Y = 0
    
    Ship(iNum).Acceleration = EnemyClass(Ship(iNum).ShipType).Acceleration
    Ship(iNum).Speed = 0
    Ship(iNum).State = sNORMAL

    Ship(iNum).ShotBounds.Top = EnemyClass(Ship(iNum).ShipType).ShotBounds.Top
    Ship(iNum).ShotBounds.Left = EnemyClass(Ship(iNum).ShipType).ShotBounds.Left
    Ship(iNum).ShotBounds.Bottom = EnemyClass(Ship(iNum).ShipType).ShotBounds.Bottom
    Ship(iNum).ShotBounds.Right = EnemyClass(Ship(iNum).ShipType).ShotBounds.Right

    Ship(iNum).ShotType = EnemyClass(Ship(iNum).ShipType).ShotType
    Ship(iNum).ShotSpeed = EnemyClass(Ship(iNum).ShipType).ShotSpeed
NEXT iNum

FOR iNum = iEnemyCount TO iMAXENEMY
    Ship(iNum).State = sUNEXST
NEXT iNum

iStarCount = INT(((iMAXSTARS - 1) - iMINSTARS + 1) * RND + iMINSTARS)
FOR iNum = 0 TO iStarCount - 1
    Star(iNum).C = INT((31 - 16 + 1) * RND + 16)
    Star(iNum).S = INT((5 - 1 + 1) * RND + 1)
    Star(iNum).X = INT((319 - 0 + 1) * RND + 0)
    Star(iNum).Y = INT(((199 - 32) - 0 + 1) * RND + 0)
NEXT iNum

FOR iNum = 1 TO (iMAXSHOTS - 1)
   Shot(iNum).Fired = bFALSE
NEXT iNum

END SUB

'This routine loads palettes and sprites, setting up all necessary graphics
'for the game.
SUB INITGRAPHICS

'"Imports" locally declared arrays in main module, this way they don't have to
'be passed as arguments.
SHARED Pal()    AS LONG
SHARED Effect() AS LONG
SHARED MaskSp() AS LONG
SHARED Sprite() AS LONG

'Opens palette file.
OPEN BasePath$ + "GCRUISE.PAL" FOR BINARY AS #1
 
'If file is empty, leave program.
IF (LOF(1) = 0) THEN
    UNINSTALLKEYB
    SCREEN 0
    WIDTH 80, 25
    PRINT "Palette file not found"
    SYSTEM
END IF
 
'Loads palette.
FOR iN = 0 TO 255
    GET #1, , Pal(iN)
NEXT iN
 
'Closes file.
CLOSE #1

'Set palette.
PALETTE USING Pal

'Loads effects.
DEF SEG = VARSEG(Effect(0, 0))
BLOAD BasePath$ + "GCRUISE.EFX", VARPTR(Effect(0, 0))

'Loads masks.
DEF SEG = VARSEG(MaskSp(0, 0))
BLOAD BasePath$ + "GCRUISE.MSK", VARPTR(MaskSp(0, 0))

'Loads sprites.
DEF SEG = VARSEG(Sprite(0, 0))
BLOAD BasePath$ + "GCRUISE.SPR", VARPTR(Sprite(0, 0))

'Resets working segment.
DEF SEG
END SUB

'This is the main menu routine, it returns the index of the selected option.
FUNCTION MAINMENU%

'Declares and initializes iOption variable.
DIM iOption AS INTEGER
iOption = 0

'Declares sKey variable.
DIM sKey AS STRING

'Draws menu background and labels.
GOSUB DrawScreen
DO
    GOSUB DrawLabels

    'Clears keyboard buffer.
    DEF SEG = &H40
    POKE &H1A, PEEK(&H1C)
    DEF SEG

    'Reads keyboard input.
    sKey = ""
    DO
        sKey = INKEY$
    LOOP UNTIL (sKey <> "")

    SELECT CASE sKey
        'If up arrow key pressed, move one option up.
        CASE CHR$(0) + CHR$(72)
        iOption = iOption - 1
        IF (iOption = -1) THEN iOption = 2

        'If down arrow key pressed, move one option down.
        CASE CHR$(0) + CHR$(80)
        iOption = iOption + 1
        IF (iOption = 3) THEN iOption = 0

        'In enter pressed return current option.
        CASE CHR$(13)
        MAINMENU = iOption
        EXIT FUNCTION

        'if escape pressed move option to exit game.
        CASE CHR$(27)
        iOption = 2
    END SELECT
LOOP
EXIT FUNCTION

'Draws menu background.
DrawScreen:
  CLS
  LOCATE 1, 11: COLOR 4
  PRINT "GALACTIC  CRUISE X"
  DEF SEG = &HA000
  BLOAD BasePath$ + "GCRUISE.TTL", 2559
  DEF SEG
RETURN

'Draws menu labels.
DrawLabels:
  LOCATE 18, 14: COLOR 4
  PRINT "MAIN  MENU"
  LOCATE 20, 14: IF (iOption = 0) THEN COLOR 9 ELSE COLOR 1
  PRINT "GAME START"
  LOCATE 21, 13: IF (iOption = 1) THEN COLOR 9 ELSE COLOR 1
  PRINT "HALL OF FAME"
  LOCATE 22, 17: IF (iOption = 2) THEN COLOR 12 ELSE COLOR 1
  PRINT "EXIT"
RETURN

END FUNCTION

'This routine moves ships around, it receives the ship to move, the direction
'in which it should move the ship and which ship type costs should be charged.
SUB MOVE (iShip AS INTEGER, dDir AS INTEGER, iCost AS INTEGER)

'"Imports" locally declared arrays on main module.
SHARED Cost() AS EnergyCostsType
SHARED Ship() AS ShipType

'Updates ship energy and speed.
Ship(iShip).Energy = Ship(iShip).Energy - Cost(iCost).MOVE
Ship(iShip).Speed = Ship(iShip).Speed + (dDir * Ship(iShip).Acceleration)

END SUB

'This is the game sub, here's where everything happens, updating the screen,
'the energy, the ships, the shots and the stars.
FUNCTION RUNGAME&

SHARED Cost()       AS EnergyCostsType
SHARED EnemyClass() AS EnemyShipClassType
SHARED Ship()       AS ShipType
SHARED Shot()       AS ShotType
SHARED Star()       AS StarType

SHARED iEnemyCount AS INTEGER
SHARED iShotCount  AS INTEGER
SHARED iStarCount  AS INTEGER

SHARED Effect() AS LONG
SHARED MaskSp() AS LONG
SHARED Sprite() AS LONG

'Clear screen and paint it gray.
CLS
PAINT (0, 0), 22

'Draw upper silver borders.
LINE (0, 6)-(319, 6), 25
LINE (0, 7)-(319, 7), 21

'Draw bottom silver borders.
LINE (0, 176)-(319, 176), 21
LINE (0, 177)-(319, 177), 25

'Draw outile for energy bar.
LINE (23 - 2, 183 - 2)-(123 + 2, 191 + 2), 23, B
LINE (23 - 1, 183 - 1)-(123 + 1, 191 + 1), 25, B

LINE (23, 191 + 1)-(123 + 1, 191 + 1), 20
LINE (123 + 1, 183)-(123 + 1, 191 + 1), 20

'Draw outline for score marker.
LINE (240 - 2, 183 - 2)-(295 + 2, 191 + 2), 23, B
LINE (240 - 1, 183 - 1)-(295 + 1, 191 + 1), 20, B

LINE (240, 191 + 1)-(295 + 1, 191 + 1), 25
LINE (295 + 1, 183)-(295 + 1, 191 + 1), 25
LINE (240, 183)-(295, 183), 0

'Draw outline for lives.
LINE (140, 179)-(227, 198), 23, B
LINE (141, 180)-(226, 197), 20, B

LINE (158, 180)-(158, 197), 20
LINE (175, 180)-(175, 197), 20
LINE (192, 180)-(192, 197), 20
LINE (209, 180)-(209, 197), 20

LINE (141, 180)-(226, 180), 25
LINE (141, 180)-(141, 197), 25

DIM iCost, iShip, iShot, iStar AS INTEGER

DIM iLives AS INTEGER
DIM lScore AS LONG
DIM iLastS AS INTEGER
iLives = 5
lScore = 0
iLastS = 0

GOSUB DrawLives

DIM sDT         AS SINGLE
DIM sFPS        AS SINGLE
DIM lFrameCount AS LONG
DIM sST         AS SINGLE

sDT = TIMER
lFrameCount = 0
sST = TIMER

COLOR 15
DEF SEG = &H40
DO
    iShotCount = 0
    IF (lScore <> 0) THEN
        lScore = lScore + 100
    END IF
    INITGAME
    DO
        POKE &H1A, PEEK(&H1C)
       
        GOSUB DoStars
        GOSUB DoShips
        GOSUB DoShots
        GOSUB DoRandom

        lFrameCount = lFrameCount + 1
   
        GOSUB VSync

        DUMP
        CLRSCR

        LOCATE 24, 31: PRINT USING "#######"; lScore;
        IF ((lScore \ 10000) > iLastS) THEN
            iLastS = lScore \ 10000
            IF (iLives < 5) THEN
                iLives = iLives + 1
                GOSUB DrawLives
            END IF
        END IF

        IF (TIMER > (sDT + .1)) THEN
                LOCATE 1, 1
                sFPS = (lFrameCount / (TIMER - sST))
                PRINT USING "FPS: ##.##"; INT(sFPS * 100) / 100
                sDT = TIMER
        END IF
        IF (KEYDOWN(kESC)) THEN
            iLives = 0
        END IF
    LOOP UNTIL ((KEYDOWN(kESC)) OR (iEnemyCount = 0) OR (iLives = 0))
LOOP WHILE (iLives > 0)
DEF SEG
RUNGAME& = lScore
EXIT FUNCTION

CreateStar:
    Star(iStar).C = INT((31 - 16 + 1) * RND + 16)
    Star(iStar).S = INT((5 - 1 + 1) * RND + 1)
    Star(iStar).X = INT((319 - 0 + 1) * RND + 0)
    Star(iStar).Y = 0
RETURN

DoShips:
    IF (Ship(0).State = sNORMAL) THEN
        'Start by player's ship.
        'If player presses the left key then accelerate ship left.
        IF ((KEYDOWN(kLEFT)) AND (Ship(0).Energy > Cost(0).MOVE)) THEN
            Ship(0).Speed = Ship(0).Speed + (dLEFT * Ship(0).Acceleration)
            Ship(0).Energy = Ship(0).Energy - Cost(0).MOVE
        END IF

        'If player presses the right key then accelerate ship right.
        IF ((KEYDOWN(kRIGHT)) AND (Ship(0).Energy > Cost(0).MOVE)) THEN
            Ship(0).Speed = Ship(0).Speed + (dRIGHT * Ship(0).Acceleration)
            Ship(0).Energy = Ship(0).Energy - Cost(0).MOVE
        END IF

        'Adjust to new position checking for collision on borders.
        Ship(0).Position.X = Ship(0).Position.X + Ship(0).Speed
        IF (Ship(0).Position.X < 0) THEN
            Ship(0).Position.X = 0
            Ship(0).Speed = 0
        END IF
        IF (Ship(0).Position.X > 304) THEN
            Ship(0).Position.X = 304
            Ship(0).Speed = 0
        END IF

        IF (Ship(0).Speed = 0) THEN
            Ship(0).Energy = Ship(0).Energy + 5 * (Ship(0).EnergyRestoreSpeed / 10)
        ELSE
            Ship(0).Energy = Ship(0).Energy + (Ship(0).EnergyRestoreSpeed / 10)
        END IF
        IF (Ship(0).Energy > Ship(0).MaxEnergy) THEN Ship(0).Energy = Ship(0).MaxEnergy
   
        DIM dE AS INTEGER
        dE = (Ship(0).Energy / Ship(0).MaxEnergy) * 100
    
        LINE (23, 183)-(123, 191), 0, BF
        IF (dE <> 0) THEN LINE (23, 183)-(23 + dE, 191), 9, BF
   
        IF (KEYDOWN(kSPACE)) THEN
            IF ((iShotCount < iMAXSHOTS) AND (Ship(0).Energy > Cost(0).Shot)) THEN SHOOT 0, 0
        END IF
   
        'Draw ship.
        PUTX Ship(0).Position.X, Ship(0).Position.Y, MaskSp(1, 0), Sprite(1, 0)
    'If ship exploded, take life and restart
    ELSEIF (Ship(0).State = sUNEXST) THEN
        iLives = iLives - 1
       
        GOSUB DrawLives
        Ship(0).State = sNORMAL
        Ship(0).Energy = 1024
        Ship(0).MaxEnergy = 1024
        Ship(0).Speed = 0
        Ship(0).Position.X = INT((303 - 0 + 1) * RND + 0)
        Ship(0).Position.Y = 200 - 32 - 16 - 1
       
    'If ship's exploding then draw it exploding.
    ELSEIF (Ship(0).State >= sEXPLO2) THEN
        PUTX Ship(0).Position.X, Ship(0).Position.Y, Effect(1, 9), Effect(1, 4)
        Ship(0).State = Ship(0).State + 1

    'If ship's exploding then draw it exploding.
    ELSEIF (Ship(0).State >= sEXPLO1) THEN
        PUTX Ship(0).Position.X, Ship(0).Position.Y, Effect(1, 8), Effect(1, 3)
        Ship(0).State = Ship(0).State + 1
    END IF
       
    'I'm not very proud of the following, it's rather "unclean", or let's
    'just say it was a quick and dirty fix to the explosion time problem.
    'Whereas I wouldn't know how long an explosing was supposed to last, so
    'I just mended it via a variable that cycles in intervals:
    ' * 0    - sNORMAL: Ship exists and is active.
    ' * 1, 2 - sEXPLO1: Ship is starting to explode.
    ' * 3, 4 - sEXPLO2: Ship is ending it's explosion.
    ' * 5    - sUNEXST: Ship unexistant (exploded or never initialized).
    'Again, I am aware that this is a somewhat dirty fix to the problem, but
    'doing concurrent programming in QB can really be a pain in the ass.
    FOR iShip = 1 TO iEnemyCount
        'Check ship state and draw it accordingly
        IF (Ship(iShip).State = sNORMAL) THEN
            UPDATESHIP iShip
            PUTX Ship(iShip).Position.X, Ship(iShip).Position.Y, MaskSp(1, Ship(iShip).ShipType + 1), Sprite(1, Ship(iShip).ShipType + 1)
        'If ship is unexistant, move another ship to it's place.
        ELSEIF (Ship(iShip).State = sUNEXST) THEN
            iEnemyCount = iEnemyCount - 1
           
            'Defines ship's boundaries.
            Ship(iShip).Boundaries.Top = Ship(iEnemyCount + 1).Boundaries.Top
            Ship(iShip).Boundaries.Left = Ship(iEnemyCount + 1).Boundaries.Left
            Ship(iShip).Boundaries.Bottom = Ship(iEnemyCount + 1).Boundaries.Bottom
            Ship(iShip).Boundaries.Right = Ship(iEnemyCount + 1).Boundaries.Right

            'Defines ship's energy settings.
            Ship(iShip).Energy = Ship(iEnemyCount + 1).Energy
            Ship(iShip).MaxEnergy = Ship(iEnemyCount + 1).MaxEnergy
            Ship(iShip).EnergyRestoreSpeed = Ship(iEnemyCount + 1).EnergyRestoreSpeed

            'Defines ship's control variables.
            Ship(iShip).Acceleration = Ship(iEnemyCount + 1).Acceleration
            Ship(iShip).Speed = Ship(iEnemyCount + 1).Speed
            Ship(iShip).State = Ship(iEnemyCount + 1).State

            'Initializes ship's position.
            Ship(iShip).Position.X = Ship(iEnemyCount + 1).Position.X
            Ship(iShip).Position.Y = Ship(iEnemyCount + 1).Position.Y

            'Defines own type (not used except for enemy ships).
            Ship(iShip).ShipType = Ship(iEnemyCount + 1).ShipType

            'Defines ship's shot boundaries.
            Ship(iShip).ShotBounds.Top = Ship(iEnemyCount + 1).ShotBounds.Top
            Ship(iShip).ShotBounds.Left = Ship(iEnemyCount + 1).ShotBounds.Left
            Ship(iShip).ShotBounds.Bottom = Ship(iEnemyCount + 1).ShotBounds.Bottom
            Ship(iShip).ShotBounds.Right = Ship(iEnemyCount + 1).ShotBounds.Right

            'Defines ship's shot information.
            Ship(iShip).ShotType = Ship(iEnemyCount + 1).ShotType
            Ship(iShip).ShotSpeed = Ship(iEnemyCount + 1).ShotSpeed
           
        'If ship's exploding then draw it exploding.
        ELSEIF (Ship(iShip).State >= sEXPLO2) THEN
            PUTX Ship(iShip).Position.X, Ship(iShip).Position.Y, Effect(1, 9), Effect(1, 4)
            Ship(iShip).State = Ship(iShip).State + 1
        'If ship's exploding then draw it exploding.
        ELSEIF (Ship(iShip).State >= sEXPLO1) THEN
            PUTX Ship(iShip).Position.X, Ship(iShip).Position.Y, Effect(1, 8), Effect(1, 3)
            Ship(iShip).State = Ship(iShip).State + 1
        END IF
    NEXT iShip
RETURN

DoShots:
    FOR iShot = 1 TO (iMAXSHOTS - 1)
        IF (Shot(iShot).Fired) THEN
            IF (Shot(iShot).Direction = dUP) THEN
                Shot(iShot).Position.Y = Shot(iShot).Position.Y - Shot(iShot).Speed
                IF (Shot(iShot).Position.Y < 0) THEN
                    Shot(iShot).Fired = bFALSE
                    iShotCount = iShotCount - 1
                ELSE
                    IF (Shot(iShot).Position.Y < 16) THEN
                        FOR iShip = 1 TO iEnemyCount
                            IF (Ship(iShip).State = sNORMAL) THEN
                               IF (COLLISION(Shot(iShot), Ship(iShip))) THEN
                                   Shot(iShot).Fired = bFALSE
                                   iShotCount = iShotCount - 1
                                   Ship(iShip).State = sEXPLO1
                                   IF (Ship(iShip).ShipType = 0) THEN
                                       lScore = lScore + 150
                                   ELSE
                                       lScore = lScore + 250
                                   END IF
                               END IF
                            END IF
                        NEXT iShip
                    END IF
                    IF (Shot(iShot).Fired) THEN PUTX Shot(iShot).Position.X, Shot(iShot).Position.Y, Effect(1, 5), Effect(1, 0)
                END IF
            ELSE
                Shot(iShot).Position.Y = Shot(iShot).Position.Y + Shot(iShot).Speed
                IF (Shot(iShot).Position.Y > 151) THEN
                    Shot(iShot).Fired = bFALSE
                    iShotCount = iShotCount - 1
                ELSE
                    IF (Shot(iShot).Position.Y > 135) THEN
                        IF (Ship(0).State = sNORMAL) THEN
                            IF (COLLISION(Shot(iShot), Ship(0))) THEN
                                Shot(iShot).Fired = bFALSE
                                iShotCount = iShotCount - 1
                                Ship(0).State = sEXPLO1
                                lScore = lScore - 200
                                IF (lScore < 0) THEN lScore = 0
                            END IF
                        END IF
                    END IF
                END IF
                IF (Shot(iShot).Fired) THEN PUTX Shot(iShot).Position.X, Shot(iShot).Position.Y, Effect(1, 5 + Shot(iShot).ShotType), Effect(1, Shot(iShot).ShotType)
            END IF
        END IF
    NEXT iShot
RETURN

DoStars:
    iStar = 0
    DO
        IF ((Star(iStar).Y + Star(iStar).S) > 167) THEN
            iStarCount = iStarCount - 1
            Star(iStar).C = Star(iStarCount - 1).C
            Star(iStar).S = Star(iStarCount - 1).S
            Star(iStar).X = Star(iStarCount - 1).X
            Star(iStar).Y = Star(iStarCount - 1).Y
        ELSE
            Star(iStar).Y = Star(iStar).Y + Star(iStar).S
            PLOT Star(iStar).X, Star(iStar).Y, Star(iStar).C
            iStar = iStar + 1
        END IF
    LOOP WHILE (iStar < iStarCount)
RETURN

DoRandom:
    DIM iEvnt AS INTEGER
    iEvent = (100 * RND)
    SELECT CASE iEvent
        CASE 0 TO 69
        IF (iStarCount < (iMAXSTARS - 1)) THEN
            iStar = iStarCount
            Star(iStar).C = INT((31 - 16 + 1) * RND + 16)
            Star(iStar).S = INT((5 - 1 + 1) * RND + 1)
            Star(iStar).X = INT((319 - 0 + 1) * RND + 0)
            Star(iStar).Y = 0
            iStarCount = iStarCount + 1
        END IF

        CASE 70 TO 76
        iStarCount = iStarCount - 1

        CASE 77 TO 79
        IF (iStarCount < (iMAXSTARS - 1)) THEN
            iStar = iStarCount
            Star(iStar).C = INT((16 - 0 + 1) * RND + 0)
            Star(iStar).S = INT((5 - 1 + 1) * RND + 1)
            Star(iStar).X = INT((319 - 0 + 1) * RND + 0)
            Star(iStar).Y = 0
            iStarCount = iStarCount + 1
        END IF

        CASE ELSE
        IF (iEnemyCount < iMAXENEMY) THEN
            FOR iShip = 1 TO iMAXENEMY - 1
                IF (Ship(iShip).State = sUNEXST) THEN EXIT FOR
            NEXT iShip
            Ship(iShip).ShipType = INT((1 - 0 + 1) * RND + 0)

            Ship(iShip).Boundaries.Top = EnemyClass(Ship(iShip).ShipType).Boundaries.Top
            Ship(iShip).Boundaries.Left = EnemyClass(Ship(iShip).ShipType).Boundaries.Left
            Ship(iShip).Boundaries.Bottom = EnemyClass(Ship(iShip).ShipType).Boundaries.Bottom
            Ship(iShip).Boundaries.Right = EnemyClass(Ship(iShip).ShipType).Boundaries.Right

            Ship(iShip).Energy = EnemyClass(Ship(iShip).ShipType).MaxEnergy
            Ship(iShip).MaxEnergy = EnemyClass(Ship(iShip).ShipType).MaxEnergy
            Ship(iShip).EnergyRestoreSpeed = EnemyClass(Ship(iShip).ShipType).EnergyRestoreSpeed

            Ship(iShip).Position.X = INT((303 - 0 + 1) * RND + 0)
            Ship(iShip).Position.Y = 0
    
            Ship(iShip).Acceleration = EnemyClass(Ship(iShip).ShipType).Acceleration
            Ship(iShip).Speed = 0
            Ship(iShip).State = sNORMAL

            Ship(iShip).ShotBounds.Top = EnemyClass(Ship(iShip).ShipType).ShotBounds.Top
            Ship(iShip).ShotBounds.Left = EnemyClass(Ship(iShip).ShipType).ShotBounds.Left
            Ship(iShip).ShotBounds.Bottom = EnemyClass(Ship(iShip).ShipType).ShotBounds.Bottom
            Ship(iShip).ShotBounds.Right = EnemyClass(Ship(iShip).ShipType).ShotBounds.Right

            Ship(iShip).ShotType = EnemyClass(Ship(iShip).ShipType).ShotType
            Ship(iShip).ShotSpeed = EnemyClass(Ship(iShip).ShipType).ShotSpeed
        END IF
    END SELECT
RETURN

DrawLives:
    DIM i AS INTEGER

    LINE (142, 181)-(225, 196), 0, BF

    LINE (158, 180)-(158, 197), 20
    LINE (175, 180)-(175, 197), 20
    LINE (192, 180)-(192, 197), 20
    LINE (209, 180)-(209, 197), 20

    FOR i = 0 TO (iLives - 1)
        PUT (142 + (i * 17), 181), Sprite(0, 0), PSET
    NEXT i
RETURN

VSync:
    WAIT &H3DA, &H8
    WAIT &H3DA, &H8, &H8
    WAIT &H3DA, &H8
    WAIT &H3DA, &H8, &H8
RETURN

END FUNCTION

'This routine fires shots, it's used for simplifying code reading on the
'UPDATESHIP and RUNGAME subs.
SUB SHOOT (iShip AS INTEGER, iCost AS INTEGER)

'"Imports" local variable holding shot count from main module.
SHARED iShotCount AS INTEGER

'"Imports" useful arrays from main module.
SHARED Cost() AS EnergyCostsType
SHARED Ship() AS ShipType
SHARED Shot() AS ShotType

'finds first free shot on list.
FOR iShot = 0 TO (iMAXSHOTS - 1)
    IF (NOT Shot(iShot).Fired) THEN EXIT FOR
NEXT iShot
   
'updates ship's energy and generates new shot info.
Ship(iShip).Energy = Ship(iShip).Energy - Cost(iCost).Shot
Shot(iShot).Fired = bTRUE
Shot(iShot).Position.X = Ship(iShip).Position.X
Shot(iShot).Position.Y = Ship(iShip).Position.Y
IF (iShip = 0) THEN
    Shot(iShot).Direction = dUP
ELSE
    Shot(iShot).Direction = dDOWN
END IF
Shot(iShot).Boundaries.Top = Ship(iShip).ShotBounds.Top
Shot(iShot).Boundaries.Left = Ship(iShip).ShotBounds.Left
Shot(iShot).Boundaries.Bottom = Ship(iShip).ShotBounds.Bottom
Shot(iShot).Boundaries.Right = Ship(iShip).ShotBounds.Right
Shot(iShot).ShotType = Ship(iShip).ShotType
Shot(iShot).Speed = Ship(iShip).ShotSpeed

'Increases shot count.
iShotCount = iShotCount + 1

END SUB

'This is basically the enemy ship's AI, it's pretty... roustic, as I wanted to
'implements neural nets on this it's kinda disappointing but I'm really low
'on time latelly to work on projects such as this.
SUB UPDATESHIP (ShipIndex AS INTEGER)

'"Imports" locally declared arrays on main module.
SHARED Cost()       AS EnergyCostsType
SHARED EnemyClass() AS EnemyShipClassType
SHARED Ship()       AS ShipType
SHARED Shot()       AS ShotType

'"Imports" locally declared important variables from main module.
SHARED iEnemyCount AS INTEGER
SHARED iShotCount  AS INTEGER

'Shot temporary variable.
DIM iShot AS INTEGER

'Restoration of ship speed.
IF (Ship(ShipIndex).Speed = 0) THEN
    Ship(ShipIndex).Energy = Ship(ShipIndex).Energy + 5 * (Ship(ShipIndex).EnergyRestoreSpeed / 10)
ELSE
    Ship(ShipIndex).Energy = Ship(ShipIndex).Energy + (Ship(ShipIndex).EnergyRestoreSpeed / 10)
END IF
IF (Ship(ShipIndex).Energy > Ship(ShipIndex).MaxEnergy) THEN Ship(ShipIndex).Energy = Ship(ShipIndex).MaxEnergy

'Initialization of movement indicators.
DIM bHit  AS INTEGER
DIM lMove AS LONG
bHit = FALSE
lMove = 0

'Calculate player shots position and best direction to move
FOR iShot = 0 TO (iMAXSHOTS - 1)
    IF (Shot(iShot).Fired) THEN
        IF (Shot(iShot).Direction = dUP) THEN
            IF (Shot(iShot).Position.Y < 150) THEN
                DIM iTmpY AS INTEGER
                iTmpY = Shot(iShot).Position.Y
                Shot(iShot).Position.Y = 0
               
                'Verify future collisions between ship being updated and
                'shots on screen. Shots have weigths according to their
                'distance to the ship.
                IF (COLLISION(Shot(iShot), Ship(ShipIndex))) THEN
                    'Flag indicating ship has to move.
                    bHit = bTRUE

                    'If ship is on either the left or right border of the
                    'screen in order for it not to get cornered. (in a 20
                    ' pixel range).
                    IF (Ship(ShipIndex).Position.X < 25) THEN
                        lMove = 1
                        Shot(iShot).Position.Y = iTmpY
                        EXIT FOR
                    ELSEIF (Ship(ShipIndex).Position.X > 279) THEN
                        lMove = -1
                        Shot(iShot).Position.Y = iTmpY
                        EXIT FOR
                    'If the ship isn't cornered then simply move to where
                    'shots have less weigth.
                    ELSE
                        lMove = lMove + ((Ship(ShipIndex).Position.X - Shot(iShot).Position.X) * (150 - iTmpY))
                    END IF
                END IF
                'Restore shot position.
                Shot(iShot).Position.Y = iTmpY
            END IF
        END IF
    END IF
NEXT iShot

'Move of the "dumb"(intelligence 0) enemy.
IF (EnemyClass(Ship(ShipIndex).ShipType).Inteligence = 0) THEN
    'Defensive action of the ship.
    IF (Ship(ShipIndex).Energy > Cost(Ship(ShipIndex).ShipType + 1).MOVE) THEN
        IF (bHit) THEN
            MOVE ShipIndex, SGN(lMove), (Ship(ShipIndex).ShipType + 1)
        ELSE
            IF (Ship(ShipIndex).Position.X < 25) THEN
                MOVE ShipIndex, dRIGHT, (Ship(ShipIndex).ShipType + 1)
            ELSEIF (Ship(ShipIndex).Position.X > 279) THEN
                MOVE ShipIndex, dLEFT, (Ship(ShipIndex).ShipType + 1)
            ELSE
                IF (Ship(ShipIndex).Energy >= Cost(Ship(ShipIndex).ShipType + 1).MOVE + Cost(Ship(ShipIndex).ShipType + 1).Shot) THEN
                    IF (Ship(ShipIndex).Position.X < Ship(0).Position.X) THEN
                        MOVE ShipIndex, dRIGHT, (Ship(ShipIndex).ShipType + 1)
                    ELSE
                        MOVE ShipIndex, dLEFT, (Ship(ShipIndex).ShipType + 1)
                    END IF
                END IF
            END IF
        END IF
    END IF
    'Offensive action of the ship.
    IF (ABS(Ship(ShipIndex).Position.X - Ship(0).Position.X) < 40) THEN
        IF ((Ship(ShipIndex).Energy > Cost(Ship(ShipIndex).ShipType + 1).Shot) AND (iShotCount < iMAXSHOTS)) THEN SHOOT ShipIndex, (Ship(ShipIndex).ShipType + 1)
    END IF
'Move of the "smart"(intelligence 1) enemy.
ELSEIF (EnemyClass(Ship(ShipIndex).ShipType).Inteligence = 1) THEN
    'Defensive action of the ship.
    IF (Ship(ShipIndex).Energy > Cost(Ship(ShipIndex).ShipType + 1).MOVE) THEN
        IF (bHit) THEN
            MOVE ShipIndex, SGN(lMove), (Ship(ShipIndex).ShipType + 1)
        ELSE
            IF (Ship(ShipIndex).Position.X < 25) THEN
                MOVE ShipIndex, dRIGHT, (Ship(ShipIndex).ShipType + 1)
            ELSEIF (Ship(ShipIndex).Position.X > 279) THEN
                MOVE ShipIndex, dLEFT, (Ship(ShipIndex).ShipType + 1)
            ELSE
                IF (Ship(ShipIndex).Energy >= 3 * Cost(Ship(ShipIndex).ShipType + 1).MOVE + 2 * Cost(Ship(ShipIndex).ShipType + 1).Shot) THEN
                    IF (Ship(ShipIndex).Position.X < Ship(0).Position.X) THEN
                        MOVE ShipIndex, dRIGHT, (Ship(ShipIndex).ShipType + 1)
                    ELSE
                        MOVE ShipIndex, dLEFT, (Ship(ShipIndex).ShipType + 1)
                    END IF
                END IF
            END IF
        END IF
    END IF
    'Offensive action of the ship.
    IF (ABS(Ship(ShipIndex).Position.X - Ship(0).Position.X) < 20) THEN
        IF ((Ship(ShipIndex).Energy > Cost(Ship(ShipIndex).ShipType + 1).Shot) AND (iShotCount < iMAXSHOTS)) THEN SHOOT ShipIndex, (Ship(ShipIndex).ShipType + 1)
    END IF
END IF

Ship(ShipIndex).Position.X = Ship(ShipIndex).Position.X + Ship(ShipIndex).Speed
IF (Ship(ShipIndex).Position.X < 0) THEN Ship(ShipIndex).Position.X = 0
IF (Ship(ShipIndex).Position.X > 303) THEN Ship(ShipIndex).Position.X = 303
EXIT SUB

END SUB

