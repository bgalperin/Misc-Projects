GOTO AUTO
FILL 255, 10000


DIM A AS BYTE   ' A  : temporary variable          / REMOCON
DIM LASTCMD AS BYTE

DIM A16 AS BYTE   ' A16,A26 : temporary variable
DIM A26 AS BYTE

'BLUESMIRF TESTING
DIM TxOut AS BYTE ' RS-232 output on ETX 
DIM RxIn AS BYTE 'RS-232 input on ERX 
DIM RxCount AS INTEGER

DIM Crouched AS BYTE 
DIM gun_pos AS BYTE
DIM tilt_pos AS INTEGER
DIM tilt_forward AS INTEGER

tilt_forward = 0
tilt_pos = 5
gun_pos = 105
Crouched = 0	'set init value of crouched as standing.

CONST ID = 0     ' 1:0, 2:32, 3:64, 4:96,

'== Action command check (50 - 82)

PTP SETON
PTP ALLON

'== motor diretion setting ======================
DIR G6A, 1, 0, 0, 1, 0, 0
DIR G6B, 1, 1, 1, 1, 1, 1
DIR G6C, 0, 0, 0, 0, 0, 0
DIR G6D, 0, 1, 1, 0, 1, 0

'== motor start position read ===================
TEMPO 230
MUSIC "CDE"
GETMOTORSET G24, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0
'== motor power on  =============================
SPEED 5
MOTOR G24

GOSUB standard_pose
'================================================
MAIN:
'GOSUB robot_voltage
'GOSUB gyro_on

'=======================================================================
'Gyroset tells both LEG servo sets to initialize
'tell gyro 1 to affect ankle and knee servos. zeros are for unaffected servos
GYROSET G6A, 0, 1, 1, 1, 0, 0
GYROSET G6D, 0, 1, 1, 1, 0, 0
'tell both ARM servo sets to initialize
GYROSET G6B, 1, 0, 0, 0, 0, 0 'gyro1=shoulder, the rest are zero for not being used...
GYROSET G6C, 1, 0, 0, 0, 0, 0 'gyro1=shoulder, nada.
'=======================================================================
'Gyrodir tells leg sets direction of movement-
'moves knee servo forward or back depending on direction of push, hence value of 1
'and the ankle slot is set to zero for backward movement. Yes, zero's matter here.
GYRODIR G6A,0,0,1,0,0,0
GYRODIR G6D,0,0,1,0,0,0
'tell arm sets direction of movement
'moves shoulders forward or backward depending on direction of push
GYRODIR G6B,0,0,0,0,0,0
GYRODIR G6C,0,0,0,0,0,0
'=======================================================================
'Gyrosense tells leg sets their sensitivity, 0 - 255.
'use this along with the gain adjustment screw on the gyro to perfect balancing
GYROSENSE G6A, 0,255,255,100, 0, 0
GYROSENSE G6D, 0,255,255,100, 0, 0

'tell arm sets their sensitivity, 0 - 255.
'use this along with the gain adjustment screw on the gyro to perfect arm swings
GYROSENSE G6B, 255,0,0, 0, 0, 0
GYROSENSE G6C, 255,0,0, 0, 0, 0
'=======================================================================
Retry:
'MUSIC "C"
DELAY 200
ERX 9600, LASTCMD, Retry
'MUSIC "BD"
DELAY 200
noRetry:
'ERX 9600, A, MAIN1

'Bluetooth I/O with PC

'TxOut = "T" 
'ETX 9600, TxOut 
'TxOut = "e" 
'ETX 9600, TxOut 
'TxOut = "s" 
'ETX 9600, TxOut 
'TxOut = "t" 
'ETX 9600, TxOut 
'TxOut = " " 
'ETX 9600, TxOut 

'FOR RxCount = 0 TO 4 

'TxOut = 48 + RxCount 'ASCII 0=48, A=65, a=97 
'ETX 9600, TxOut 

'NEXT 


'TxOut = "[" 
'ETX 9600, TxOut 

'FOR RxCount = 0 TO 15 
'ERX 9600, RxIn, NoRetry 
'ETX 9600, RxIn 
'NoRetry: 

'NEXT 

'TxOut = "]" 
'ETX 9600, TxOut
'------------------------

IF LASTCMD = &H66 THEN ' f  -  /\
	GOSUB tilt_fwd 'forward_tumbling
	WAIT
ELSEIF LASTCMD = &H72 THEN ' r  -  >
	GOSUB pan_right 'drop_to_knees
	WAIT
ELSEIF LASTCMD = &H62 THEN ' b  -  \/
	GOSUB tilt_bwd 'back_tumbling
	WAIT
ELSEIF LASTCMD = &H6C THEN ' l  -  <
	GOSUB pan_left 'body_clap
	WAIT
ELSEIF LASTCMD = &H46 THEN ' F  -  o & /\
	GOSUB standard_pose 'backward_standup
	WAIT
ELSEIF LASTCMD = &H52 THEN ' R  -  o & >
	GOSUB standard_pose 'fast_walk
	WAIT
ELSEIF LASTCMD = &H42 THEN ' B  -  o & \/
	GOSUB standard_pose 'forward_standup
	WAIT
ELSEIF LASTCMD = &H4C THEN ' L  -  o & <
	GOSUB standard_pose 'splap
	WAIT
ELSEIF LASTCMD = &H74 THEN ' t  -  Start
	GOSUB crouch 'sit_down_pose16
	WAIT
ELSEIF LASTCMD = &H54 THEN ' T  -  o & Start
	GOSUB standard_pose 'LIMBO
	WAIT
ELSEIF LASTCMD = &H44 THEN ' D  -  L12
	'GOSUB standard_pose 'forward_punch
		gun_pos = 18
		MOVE G6B, 105, , , , ,
		GOSUB gun_movement
	WAIT
ELSEIF LASTCMD = &H32 THEN ' 2  -  L02
	'GOSUB standard_pose 'right_forward
		gun_pos = 26
		MOVE G6B, 145, , , , ,
		GOSUB gun_movement
	WAIT
ELSEIF LASTCMD = &H6d THEN ' m  -  L03
	'GOSUB standard_pose 'right_attack
		gun_pos = 35
		MOVE G6B, 190, , , , ,
		GOSUB gun_movement
	WAIT
ELSEIF LASTCMD = &H33 THEN ' 3  -  L05
	GOSUB standard_pose 'block_right
	WAIT
ELSEIF LASTCMD = &H64 THEN ' d  -  L06
	GOSUB standard_pose 'can_can
	WAIT
ELSEIF LASTCMD = &H34 THEN ' 4  -  L08
	GOSUB standard_pose 'block_left
	WAIT
ELSEIF LASTCMD = &H3C THEN ' <  -  L09
	'GOSUB standard_pose 'left_attack
		gun_pos = 1
		MOVE G6B, 20, , , , ,
		GOSUB gun_movement
	WAIT
ELSEIF LASTCMD = &H31 THEN ' 1  -  L10
	'GOSUB standard_pose 'left_forward
		gun_pos = 10
		MOVE G6B, 65, , , , ,
		GOSUB gun_movement
	WAIT
ELSEIF LASTCMD = &H48 THEN ' H  -  R12
	GOSUB forward_walk
	WAIT
ELSEIF LASTCMD = &H36 THEN ' 6  -  R02
	GOSUB standard_pose 'right_turn
	WAIT
ELSEIF LASTCMD = &H3e THEN ' >  -  R03
	GOSUB right_shift
	WAIT
ELSEIF LASTCMD = &H37 THEN ' 7  -  R05
	GOSUB turn_R
	WAIT
ELSEIF LASTCMD = &H68 THEN ' h  -  R06
	GOSUB backward_walk
	WAIT
ELSEIF LASTCMD = &H38 THEN ' 8  -  R08
	GOSUB turn_L
	WAIT
ELSEIF LASTCMD = &H4d THEN ' M  -  R09
	GOSUB left_shift
	WAIT
ELSEIF LASTCMD = &H35 THEN ' 5  -  R10
	GOSUB standard_pose 'left_turn
	WAIT
ELSEIF LASTCMD = &H3D THEN ' =  -  L09 & R03
	GOSUB standard_pose 'splits
	WAIT
ELSEIF LASTCMD = &H55 THEN ' U  -  tri
	GOSUB standard_pose 'handstanding
	WAIT
ELSEIF LASTCMD = &H75 THEN ' u  -  X
	GOSUB standard_pose 'bow_pose
	WAIT
ELSEIF LASTCMD = &H53 THEN ' S  -  []
	GOSUB shoot_both 'wing_move
	WAIT
ELSEIF LASTCMD = &H4B THEN ' K  -  L1
	GOSUB tilt_left 'left_shoot
	WAIT
ELSEIF LASTCMD = &H6B THEN ' k  -  R1
	GOSUB tilt_right 'right_shoot
	WAIT
ELSEIF LASTCMD = &H2F THEN ' \  -  L2
	GOSUB shoot_left 'left_tumbling
	WAIT
ELSEIF LASTCMD = &H5C THEN ' /  -  R2
	GOSUB shoot_right 'righ_tumbling
	WAIT
ENDIF

IF LASTCMD <> &H53 THEN GOSUB standard_pose
	WAIT

clearbuf:
ERX 9600, LASTCMD, Retry
        WAIT
        GOTO clearbuf
'================================================
robot_voltage:                                          ' [ 10 x Value / 256 = Voltage]
    DIM v AS BYTE
    A = AD(6)
    IF A < 148 THEN                                 ' 5.8v
	    FOR v = 0 TO 2
		    OUT 52, 1
		    DELAY 200
		    OUT 52, 0
		    DELAY 200
	    NEXT v
	ENDIF	
RETURN
'================================================

robot_tilt:
	A = AD(7) 'this is for the IMU on A/D pin 7
	IF A > 250 THEN RETURN
	IF A < 100 THEN GOTO backward_standup
	IF A > 160 THEN GOTO forward_standup
RETURN

'robot_tilt:
'        A = AD(5)
'        IF A > 250 THEN RETURN
'
'        IF A < 30 THEN GOTO tilt_low
'        IF A > 200 THEN GOTO tilt_high
'
'        RETURN
'tilt_low:
'        A = AD(5)
'        'IF A < 30 THEN  GOTO forward_standup
'        IF A < 30 THEN GOTO backward_standup
'        RETURN
'tilt_high:
'        A = AD(5)
'        'IF A > 200 THEN GOTO backward_standup
'        IF A > 200 THEN GOTO forward_standup
'        RETURN
'================================================
sit_down_pose16:
        IF A16 = 0 THEN GOTO standard_pose16
        A16 = 0
        SPEED 10
        MOVE G6A, 100, 151, 23, 140, 101, 100
        MOVE G6D, 100, 151, 23, 140, 101, 100
        MOVE G6B, 100, 30, 80, 100, 100, 100
        MOVE G6C, 100, 30, 80, 100, 100, 100
        WAIT
'== motor power off  ============================
        MOTOROFF G24
        TEMPO 230
        MUSIC "FEDC"
        RETURN
'================================================
standard_pose16:
        TEMPO 230
        MUSIC "CDE"
        GETMOTORSET G24, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0
'== motor power on  =============================
        MOTOR G24
        A16 = 1
'================================================
        SPEED 10
        GOSUB standard_pose
        RETURN
'================================================


'================================================
'GYRO SETTINGS           ****************************************************************************************
'====================
gyro_off:
GYROSET G6A, 0, 0, 0, 0, 0, 0 ' set Gyro to use (0=no Gyro)
GYROSET G6D, 0, 0, 0, 0, 0, 0 ' set Gyro to use (0=no Gyro)
GYROSET G6C, 0, 0, 0, 0, 0, 0 ' set Gyro to use (0=no Gyro)
GYROSET G6B, 0, 0, 0, 0, 0, 0 ' set Gyro to use (0=no Gyro)

GYROSENSE G6A, 0, 0, 0, 0, 0, 0
GYROSENSE G6D, 0, 0, 0, 0, 0, 0
GYROSENSE G6C, 0, 0, 0, 0, 0, 0
GYROSENSE G6B, 0, 0, 0, 0, 0, 0
RETURN

gyro_on:
GYROSET G6A, 2, 1, 1, 0, 2, 0
GYROSET G6D, 2, 1, 1, 0, 2, 0
GYROSET G6C, 1, 2, 0, 0, 0, 0
GYROSET G6B, 1, 2, 0, 0, 0, 0

GYRODIR G6A, 0, 0, 1, 0, 1, 0
GYRODIR G6D, 1, 0, 1, 0, 0, 0
GYRODIR G6C, 0, 0, 0, 0, 0, 0
GYRODIR G6B, 0, 1, 0, 0, 0, 0

GYROSENSE G6A, 200, 200, 200, 0, 200, 0
GYROSENSE G6D, 200, 200, 200, 0, 200, 0
GYROSENSE G6C, 150, 150, 0, 0, 0, 0
GYROSENSE G6B, 150, 150, 0, 0, 0, 0
RETURN

gyro_on_FB:
GYROSET G6A, 0, 1, 1, 0, 0, 0
GYROSET G6D, 0, 1, 1, 0, 0, 0

GYRODIR G6A, 0, 0, 1, 0, 0, 0
GYRODIR G6D, 0, 0, 1, 0, 0, 0

GYROSENSE G6A, 0, 200, 200, 0, 0, 0
GYROSENSE G6D, 0, 200, 200, 0, 0, 0
RETURN

gyro_on_RL:
GYROSET G6A, 2, 0, 0, 0, 2, 0
GYROSET G6D, 2, 0, 0, 0, 2, 0

GYRODIR G6A, 0, 0, 0, 0, 1, 0
GYRODIR G6D, 1, 0, 0, 0, 0, 0

GYROSENSE G6A, 200, 0, 0, 0, 200, 0
GYROSENSE G6D, 200, 0, 0, 0, 200, 0
RETURN '

'================================================
'================================================
turn_L:
MOVE24 86,  80, 145,  93, 114,  95, , , , , , , , , , , , , 114,  80, 145,  93,  86,  93

'lift right leg
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112,  91, 172,  74,  88,  94

'right leg forward
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112, 117, 182,  87,  88,  91

'right leg down
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 113, 105, 162, 104,  88,  92

MOVE24 100,  80, 145,  93, 100,  95, , , , , , , , , , , , , 100,  80, 145,  93, 100,  93

'left leg down to pivot left
'MOVE24 115, 106, 156, 110,  88, 102, , , , , , , , , , , , , 83,  66, 147,  87, 114,  99
'move left leg back to standard
'MOVE24 115, 115, 182,  86,  84, 104, , , , , , , , , , , , , 81,  74, 149,  94, 117,  99
'MOVE G6A,100,  76, 145,  93, 100,  95
'MOVE G6D,100,  76, 145,  93, 100,  93
WAIT
GOSUB standard_pose
RETURN

turn_R:
'turnright
'lean right
'MOVE24 116,  59, 135,  79,  87,  97, , , , , , , , , , , , , 81,  81, 149,  94, 117,  99
MOVE G6A,114,80,145,93,86,93
MOVE G6D, 86, 80, 145, 93, 114, 95
'lift left leg 
'MOVE24 117,  78, 160,  63,  87, 101, , , , , , , , , , , , , 81,  74, 149,  94, 117,  99
MOVE G6A,112,91,172,74,88,94
MOVE G6D, 86, 73, 149, 81, 113, 93
'left leg forward
'MOVE24 115, 115, 182,  86,  84, 104, , , , , , , , , , , , , 81,  74, 149,  94, 117,  99
MOVE G6A,113,105,162,104,88,92
MOVE G6D, 86, 73, 149, 81, 113, 93
'right leg down to pivot right
'MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 113, 105, 162, 104,  88,  92
'right leg forward
'MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112, 117, 182,  87,  88,  91
'lift right leg
'MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112,  91, 172,  74,  88,  94
MOVE G6A,100,  80, 145,  93, 100,  95
MOVE G6D,100,  80, 145,  93, 100,  93
WAIT
GOSUB standard_pose
RETURN


'==================================================
'==================================================
'STANDARD MOVES             *************************************************************************************
'=======================
'================================================
standard_pose:
	IF Crouched = 1 THEN
		IF tilt_pos = 5 THEN
			IF tilt_forward = 0 THEN
		MOVE G6A,100, 150, 188, 124, 100,  95
		MOVE G6D,100, 150, 188, 124, 100,  93
		ENDIF
		ENDIF
		GOSUB tilting
	ELSEIF Crouched = 0 THEN
		MOVE G6A,100,  80, 145,  93, 100,  95
		MOVE G6D,100,  80, 145,  93, 100,  93
	ENDIF
'Crouched = 0

RETURN


'        MOVE G6A, 100, 76, 145, 93, 100, 100
'        MOVE G6D, 100, 76, 145, 93, 100, 100
'        MOVE G6B, 100, 30, 80, 100, 100, 100
'        MOVE G6C, 100, 30, 80, 100, 100, 100
'        WAIT
        
		'GOSUB robot_tilt
        
'        RETURN
'================================================
sit_down_pose:
        SPEED 10
        MOVE G6A, 100, 151, 23, 140, 101, 100
        MOVE G6D, 100, 151, 23, 140, 101, 100
        MOVE G6B, 100, 30, 80, 100, 100, 100
        MOVE G6C, 100, 30, 80, 100, 100, 100
        WAIT
        RETURN
'================================================
'================================================
fast_walk:
DIM A10 AS BYTE
        SPEED 10
        MOVE G6B, 100, 30, 90, 100, 100, 100
        MOVE G6C, 100, 30, 90, 100, 100, 100
        WAIT
        SPEED 7
fast_run01:
        MOVE G6A, 90, 72, 148, 93, 110, 70
        MOVE G6D, 108, 75, 145, 93, 95, 70
        WAIT
        SPEED 15
fast_run02:
        MOVE G6A, 90, 95, 105, 115, 110, 70
        MOVE G6D, 112, 75, 145, 93, 95, 70
        MOVE G6B, 90, 30, 90, 100, 100, 100
        MOVE G6C, 110, 30, 90, 100, 100, 100
        WAIT
        SPEED 15
'----------------------------  4 times
        FOR A10 = 1 TO 4

fast_run20:
        MOVE G6A, 100, 80, 119, 118, 106, 100
        MOVE G6D, 105, 75, 145, 93, 100, 100
        MOVE G6B, 80, 30, 90, 100, 100, 100
        MOVE G6C, 120, 30, 90, 100, 100, 100
fast_run21:
        MOVE G6A, 105, 74, 140, 106, 100, 100
        MOVE G6D, 95, 105, 124, 93, 106, 100
        MOVE G6B, 100, 30, 90, 100, 100, 100
        MOVE G6C, 100, 30, 90, 100, 100, 100
fast_run22:
        MOVE G6D, 100, 80, 119, 118, 106, 100
        MOVE G6A, 105, 75, 145, 93, 100, 100
        MOVE G6C, 80, 30, 90, 100, 100, 100
        MOVE G6B, 120, 30, 90, 100, 100, 100
fast_run23:
        MOVE G6D, 105, 74, 140, 106, 100, 100
        MOVE G6A, 95, 105, 124, 93, 106, 100
        MOVE G6C, 100, 30, 90, 100, 100, 100
        MOVE G6B, 100, 30, 90, 100, 100, 100

        NEXT A10
'------------------------------
        SPEED 8
        MOVE G6A, 85, 80, 130, 95, 106, 100
        MOVE G6D, 108, 73, 145, 93, 100, 100
        MOVE G6B, 80, 30, 90, 100, 100, 100
        MOVE G6C, 120, 30, 90, 100, 100, 100
        WAIT
fast_run03:
        MOVE G6A, 90, 72, 148, 93, 110, 70
        MOVE G6D, 108, 75, 145, 93, 93, 70
        WAIT
        SPEED 5

        RETURN
'================================================
'================================================
left_turn:
        SPEED 6
        MOVE G6D, 85, 71, 152, 91, 112, 60
        MOVE G6A, 112, 76, 145, 93, 92, 60
        MOVE G6C, 100,  40,  80,    ,    ,    ,
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        WAIT

        SPEED 9
        MOVE G6A, 113, 75, 145, 97, 93, 60
        MOVE G6D, 90, 50, 157, 115, 112, 60
        MOVE G6B, 105,  40,  70,    ,    ,    ,
        MOVE G6C,  90,  40,  70,    ,    ,    ,
        WAIT

        MOVE G6A, 108, 78, 145, 98, 93, 60
        MOVE G6D, 95, 43, 169, 110, 110, 60
        MOVE G6B, 105,  40,  70,    ,    ,    ,
        MOVE G6C,  80,  40,  70,    ,    ,    ,
        WAIT
        RETURN
'================================================
'================================================
right_turn:
        SPEED 6
        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        MOVE G6C, 100,  40,  80,    ,    ,    ,
        WAIT

        SPEED 9
        MOVE G6D, 113, 75, 145, 97, 93, 60
        MOVE G6A, 90, 50, 157, 115, 112, 60
        MOVE G6C, 105,  40,  70,    ,    ,    ,
        MOVE G6B,  90,  40,  70,    ,    ,    ,
        WAIT

        MOVE G6D, 108, 78, 145, 98, 93, 60
        MOVE G6A, 95, 43, 169, 110, 110, 60
        MOVE G6C, 105,  40,  70,    ,    ,    ,
        MOVE G6B,  80,  40,  70,    ,    ,    ,
        WAIT
        RETURN
'================================================
'================================================
forward_walk:

        SPEED 4
		MOVE G6A,100,  80, 145,  93, 100,  95
		MOVE G6D,100,  80, 145,  93, 100,  93

'start
MOVE24 100,  80, 145,  93, 100,  95, , , , , , , , , , , , , 100,  80, 145,  93, 100,  93
'lean left
MOVE24 86,  80, 145,  93, 114,  95, , , , , , , , , , , , , 118,  80, 145,  93,  86,  93

'lift right leg
MOVE24 86,  80, 149,  81, 113,  93, , , , , , , , , , , , , 112,  91, 172,  74,  88,  94

'right leg forward
MOVE24 86,  80, 149,  81, 113,  93, , , , , , , , , , , , , 112, 117, 182,  87,  88,  91

'right leg down
MOVE24 86,  80, 149,  81, 113,  93, , , , , , , , , , , , , 113, 105, 162, 104,  88,  92

'shift weight to middle
MOVE24 104,  71, 156,  69,  96,  93, , , , , , , , , , , , , 90,  99, 160,  99, 110,  92

'lean right
MOVE24 116,  59, 135,  79,  87,  97, , , , , , , , , , , , , 81,  81, 149,  94, 117,  99

'lift left leg 
MOVE24 117,  78, 160,  63,  87, 101, , , , , , , , , , , , , 81,  81, 149,  94, 117,  99

'left leg forward
MOVE24 115, 115, 182,  86,  84, 104, , , , , , , , , , , , , 81,  82, 149,  94, 117,  99

'left leg down
MOVE24 115, 106, 149, 110,  88, 102, , , , , , , , , , , , , 83,  66, 140,  87, 114,  99
'156, 147


'shift weight to middle
MOVE24 104, 104, 149, 110,  97,  94, , , , , , , , , , , , , 92,  70, 140,  87, 107,  94
'lean left
'MOVE24 81,  81, 149,  85, 117,  99, , , , , , , , , , , , , 116,  50, 135,  79,  87,  97
MOVE G6A, 84,  86, 136, 109, 118,  94
MOVE G6D,112,  65, 141,  87,  85,  96


'lift right leg 
MOVE24 81,  81, 149,  85, 117,  99, , , , , , , , , , , , , 115,  65, 160,  63,  87, 97

'ight leg forward
MOVE24 81,  82, 149,  85, 117,  99, , , , , , , , , , , , , 115, 110, 182,  86,  84, 97

'right leg down
MOVE24 83,  66, 140,  87, 114,  99, , , , , , , , , , , , ,115, 106, 149, 110,  88, 97

'156, 147


'shift weight to middle
'MOVE24 104, 104, 149, 110,  97,  94, , , , , , , , , , , , , 92,  70, 140,  87, 107,  94
'154, 148
'lean left
'MOVE24 86,  84, 142,  99, 114,  85, , , , , , , , , , , , , 111,  53, 133,  80,  88,  84

'lift right leg
'MOVE24 86,  70, 142,  99, 114,  85, , , , , , , , , , , , , 111,  64, 148,  70,  88,  82
'MOVE24 81,  74, 149,  94, 117,  99, , , , , , , , , , , , , 117,  74, 160,  63,  87, 101
'MOVE24 86,  84, 142,  99, 114,  85, , , , , , , , , , , , , 111,  53, 155,  70,  88,  84
'MOVE G6A, 80,  84, 140,  92, 114,  85
'MOVE G6D,112,  70, 175,  64,  83,  84

'right leg forward
'MOVE24 84,  70, 125,  87, 115,  91, , , , , , , , , , , , , 112, 105, 187,  75,  80,  93

'right leg down
'MOVE24 84,  70, 139,  87, 115,  91, , , , , , , , , , , , , 114,  98, 150, 108,  86,  87



'shift weight to middle
MOVE24 101,  57, 129,  87, 102,  98, , , , , , , , , , , , , 94,  83, 151,  93, 102,  97

'lean right
MOVE24 109,  45, 112,  87,  96, 101, , , , , , , , , , , , , 86,  69, 144,  86, 108, 101

'lift left leg
MOVE24 109,  70, 148,  69,  98, 103, , , , , , , , , , , , , 86,  63, 140,  86, 108, 101

'left leg forward to standard pose
MOVE24 107,  86, 159,  84,  97, 102, , , , , , , , , , , , , 86,  63, 140,  86, 108, 101

MOVE24 100,  80, 145,  93, 100,  95, , , , , , , , , , , , , 100,  80, 145,  93, 100,  93

RETURN
'================================================
'================================================
left_shift:
'lean right
MOVE G6A,122,  74, 138,  93,  83, 100
MOVE G6D, 85,  72, 146,  91, 113,  94

'lift left leg
MOVE G6A,122,  78, 149,  87,  81, 100
MOVE G6D, 85,  72, 146,  91, 113,  94

'left leg extend
MOVE G6A,132,  66, 128,  91,  64, 104
MOVE G6D, 92,  72, 146,  91, 113,  94

'shift weight to middle
MOVE G6A,115,  67, 132,  91,  87, 103
MOVE G6D,108,  70, 142,  91,  91,  94

'shift weight to left leg
MOVE G6A, 98,  69, 151,  75, 103,  92
MOVE G6D,125,  61, 133,  91,  74,  89


        RETURN
'================================================
'================================================
'================================================
'================================================
right_shift:

'lean left
MOVE24 86,  76, 145,  93, 114,  95, , , , , , , , , , , , , 114,  76, 145,  93,  86,  93
'lift right leg
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112,  91, 172,  74,  88,  94
'right leg extend
MOVE G6A, 86,  73, 149,  81, 113,  93
MOVE G6D,129,  65, 140,  87,  68,  86
'shift weight to middle
MOVE G6A,111,  72, 145,  86,  91,  92
MOVE G6D,105,  77, 153,  87,  93,  86
'shift weight to right leg
MOVE G6A,126,  71, 139,  90,  82, 100
MOVE G6D, 95,  95, 174,  87,  99,  87

        RETURN
'================================================
'================================================
'================================================
backward_walk:
SPEED 4
'walking backward
'MOVE24 100,  76, 145,  93, 100,  95, , , , , , , , , , , , , 100,  76, 145,  93, 100,  93
MOVE24 100,  80, 145,  93, 100,  95, , , , , , , , , , , , , 100,  80, 145,  93, 100,  93
'left leg forward to standard pose
MOVE24 107,  86, 159,  84,  97, 102, , , , , , , , , , , , , 86,  63, 144,  86, 108, 101
'lift left leg
MOVE24 109,  70, 148,  69,  98, 103, , , , , , , , , , , , , 86,  63, 144,  86, 108, 101
'lean right
MOVE24 109,  45, 112,  87,  96, 101, , , , , , , , , , , , , 86,  69, 144,  86, 108, 101
'shift weight to middle
MOVE24 101,  57, 129,  87, 102,  98, , , , , , , , , , , , , 94,  83, 151,  93, 102,  97
'right leg down
MOVE24 84,  70, 139,  93, 115,  91, , , , , , , , , , , , , 114,  98, 153, 108,  86,  87
'right leg forward
MOVE24 84,  70, 139,  93, 115,  91, , , , , , , , , , , , , 112, 116, 187,  75,  86,  83
'lift right leg
'MOVE24 86,  70, 142,  99, 114,  85, , , , , , , , , , , , , 111,  64, 148,  70,  88,  82
'MOVE24 81,  74, 149,  94, 117,  99, , , , , , , , , , , , , 117,  74, 160,  63,  87, 101

'lean left
MOVE24 86,  84, 142,  99, 114,  85, , , , , , , , , , , , , 111,  53, 133,  80,  88,  84
'shift weight to middle
MOVE24 104, 104, 154, 110,  97,  94, , , , , , , , , , , , , 92,  70, 148,  87, 107,  94
'left leg down
MOVE24 115, 106, 156, 110,  88, 102, , , , , , , , , , , , , 83,  66, 147,  87, 114,  99
'left leg forward
MOVE24 115, 115, 182,  86,  84, 104, , , , , , , , , , , , , 81,  74, 149,  94, 117,  99
'lift left leg 
MOVE24 117,  78, 160,  63,  87, 101, , , , , , , , , , , , , 81,  74, 149,  94, 117,  99
'lean right
MOVE24 116,  59, 135,  79,  87,  97, , , , , , , , , , , , , 81,  81, 149,  94, 117,  99
'shift weight to middle
MOVE24 104,  71, 156,  69,  96,  93, , , , , , , , , , , , , 90,  99, 160,  99, 110,  92
'right leg down
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 113, 105, 162, 104,  88,  92
'right leg forward
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112, 117, 182,  87,  88,  91
'lift right leg
MOVE24 86,  73, 149,  81, 113,  93, , , , , , , , , , , , , 112,  91, 172,  74,  88,  94
'lean left
MOVE24 86,  80, 145,  93, 114,  95, , , , , , , , , , , , , 114,  80, 145,  93,  86,  93
'start
MOVE24 100,  80, 145,  93, 100,  95, , , , , , , , , , , , , 100,  80, 145,  93, 100,  93

        RETURN
'================================================

'================================================
'================================================
'================================================
sit_pose:

        SPEED 10
        MOVE G6A,100, 151,  23, 140, 101, 100,
        MOVE G6D,100, 151,  23, 140, 101, 100,
        MOVE G6B,100,  30,  80, 100, 100, 100,
        MOVE G6C,100,  30,  80, 100, 100, 100,
        WAIT
        RETURN
'================================================
'================================================
back_standing:

        SPEED 10

        MOVE G6A, 100, 130, 120, 80, 110, 100
        MOVE G6D, 100, 130, 120, 80, 110, 100
        MOVE G6B, 150, 160, 10, 100, 100, 100
        MOVE G6C, 150, 160, 10, 100, 100, 100
        WAIT

        MOVE G6A, 80, 155, 85, 150, 150, 100
        MOVE G6D, 80, 155, 85, 150, 150, 100
        MOVE G6B, 185, 40, 60, 100, 100, 100
        MOVE G6C, 185, 40, 60, 100, 100, 100
        WAIT

        MOVE G6A, 75, 165, 55, 165, 155, 100
        MOVE G6D, 75, 165, 55, 165, 155, 100
        MOVE G6B, 185, 10, 100, 100, 100, 100
        MOVE G6C, 185, 10, 100, 100, 100, 100
        WAIT

        MOVE G6A, 60, 165, 30, 165, 155, 100
        MOVE G6D, 60, 165, 30, 165, 155, 100
        MOVE G6B, 170, 10, 100, 100, 100, 100
        MOVE G6C, 170, 10, 100, 100, 100, 100
        WAIT

        MOVE G6A, 60, 165, 25, 160, 145, 100
        MOVE G6D, 60, 165, 25, 160, 145, 100
        MOVE G6B, 150, 60, 90, 100, 100, 100
        MOVE G6C, 150, 60, 90, 100, 100, 100
        WAIT

        MOVE G6A, 100, 155, 25, 140, 100, 100
        MOVE G6D, 100, 155, 25, 140, 100, 100
        MOVE G6B, 130, 50, 85, 100, 100, 100
        MOVE G6C, 130, 50, 85, 100, 100, 100
        WAIT

        RETURN
'================================================
'================================================
'================================================
forward_standup:

        SPEED 10

        MOVE G6A, 100, 130, 120, 80, 110, 100
        MOVE G6D, 100, 130, 120, 80, 110, 100
        MOVE G6B, 150, 160, 10, 100, 100, 100
        MOVE G6C, 150, 160, 10, 100, 100, 100
        WAIT

        MOVE G6A, 80, 155, 85, 150, 150, 100
        MOVE G6D, 80, 155, 85, 150, 150, 100
        MOVE G6B, 185, 40, 60, 100, 100, 100
        MOVE G6C, 185, 40, 60, 100, 100, 100
        WAIT

        MOVE G6A, 75, 165, 55, 165, 155, 100
        MOVE G6D, 75, 165, 55, 165, 155, 100
        MOVE G6B, 185, 10, 100, 100, 100, 100
        MOVE G6C, 185, 10, 100, 100, 100, 100
        WAIT

        MOVE G6A, 60, 165, 30, 165, 155, 100
        MOVE G6D, 60, 165, 30, 165, 155, 100
        MOVE G6B, 170, 10, 100, 100, 100, 100
        MOVE G6C, 170, 10, 100, 100, 100, 100
        WAIT

        MOVE G6A, 60, 165, 25, 160, 145, 100
        MOVE G6D, 60, 165, 25, 160, 145, 100
        MOVE G6B, 150, 60, 90, 100, 100, 100
        MOVE G6C, 150, 60, 90, 100, 100, 100
        WAIT

        MOVE G6A, 100, 155, 25, 140, 100, 100
        MOVE G6D, 100, 155, 25, 140, 100, 100
        MOVE G6B, 130, 50, 85, 100, 100, 100
        MOVE G6C, 130, 50, 85, 100, 100, 100
        WAIT

        GOSUB standard_pose

        RETURN
'================================================
'================================================
backward_standup:

        SPEED 10

        MOVE G6A, 100, 10, 100, 115, 100, 100
        MOVE G6D, 100, 10, 100, 115, 100, 100
        MOVE G6B, 100, 130, 10, 100, 100, 100
        MOVE G6C, 100, 130, 10, 100, 100, 100
        WAIT

        MOVE G6A, 100, 10, 83, 140, 100, 100
        MOVE G6D, 100, 10, 83, 140, 100, 100
        MOVE G6B, 20, 130, 10, 100, 100, 100
        MOVE G6C, 20, 130, 10, 100, 100, 100
        WAIT

        MOVE G6A, 100, 126, 60, 50, 100, 100
        MOVE G6D, 100, 126, 60, 50, 100, 100
        MOVE G6B, 20, 30, 90, 100, 100, 100
        MOVE G6C, 20, 30, 90, 100, 100, 100
        WAIT

        MOVE G6A, 100, 165, 70, 15, 100, 100
        MOVE G6D, 100, 165, 70, 15, 100, 100
        MOVE G6B, 30, 20, 95, 100, 100, 100
        MOVE G6C, 30, 20, 95, 100, 100, 100
        WAIT

        MOVE G6A, 100, 165, 40, 100, 100, 100
        MOVE G6D, 100, 165, 40, 100, 100, 100
        MOVE G6B, 110, 70, 50, 100, 100, 100
        MOVE G6C, 110, 70, 50, 100, 100, 100
        WAIT

        GOSUB standard_pose
        RETURN
'=================================================
'190 FULL RIGHT
'145 MID RIGHT
'105 CENTER
'65 MID LEFT
'20 FULL LEFT
'MOVE G6B, 105, , , , ,

'declare gun_pos var
pan_left:
		 IF gun_pos > 1 THEN
		 	gun_pos = gun_pos - 1
		 ENDIF
		 GOSUB gun_movement
	RETURN
	
pan_right:
		IF gun_pos < 35 THEN
			gun_pos = gun_pos + 1
		ENDIF
		GOSUB gun_movement
	RETURN
	
gun_movement:	
	IF gun_pos = 1 THEN
		MOVE G6B, 20, , , , , 
	ELSEIF gun_pos = 2 THEN
		MOVE G6B, 25, , , , ,
	ELSEIF gun_pos = 3 THEN
		MOVE G6B, 30, , , , ,
	ELSEIF gun_pos = 4 THEN
		MOVE G6B, 35, , , , ,
	ELSEIF gun_pos = 5 THEN
		MOVE G6B, 40, , , , ,
	ELSEIF gun_pos = 6 THEN
		MOVE G6B, 45, , , , ,
	ELSEIF gun_pos = 7 THEN
		MOVE G6B, 50, , , , ,
	ELSEIF gun_pos = 8 THEN
		MOVE G6B, 55, , , , ,
	ELSEIF gun_pos = 9 THEN
		MOVE G6B, 60, , , , ,
	ELSEIF gun_pos = 10 THEN
		MOVE G6B, 65, , , , ,
	ELSEIF gun_pos = 11 THEN
		MOVE G6B, 70, , , , ,
	ELSEIF gun_pos = 12 THEN
		MOVE G6B, 75, , , , ,
	ELSEIF gun_pos = 13 THEN
		MOVE G6B, 80, , , , ,
	ELSEIF gun_pos = 14 THEN
		MOVE G6B, 85, , , , ,
	ELSEIF gun_pos = 15 THEN
		MOVE G6B, 90, , , , ,
	ELSEIF gun_pos = 16 THEN
		MOVE G6B, 95, , , , ,
	ELSEIF gun_pos = 17 THEN
		MOVE G6B, 100, , , , ,
	ELSEIF gun_pos = 18 THEN
		MOVE G6B, 105, , , , ,
	ELSEIF gun_pos = 19 THEN
		MOVE G6B, 110, , , , ,
	ELSEIF gun_pos = 20 THEN
		MOVE G6B, 115, , , , ,
	ELSEIF gun_pos = 21 THEN
		MOVE G6B, 120, , , , ,
	ELSEIF gun_pos = 22 THEN
		MOVE G6B, 125, , , , ,
	ELSEIF gun_pos = 23 THEN
		MOVE G6B, 130, , , , ,
	ELSEIF gun_pos = 24 THEN
		MOVE G6B, 135, , , , ,
	ELSEIF gun_pos = 25 THEN
		MOVE G6B, 140, , , , ,
	ELSEIF gun_pos = 26 THEN
		MOVE G6B, 145, , , , ,
	ELSEIF gun_pos = 27 THEN
		MOVE G6B, 150, , , , ,
	ELSEIF gun_pos = 28 THEN
		MOVE G6B, 155, , , , ,
	ELSEIF gun_pos = 29 THEN
		MOVE G6B, 160, , , , ,
	ELSEIF gun_pos = 30 THEN
		MOVE G6B, 165, , , , ,
	ELSEIF gun_pos = 31 THEN
		MOVE G6B, 170, , , , ,
	ELSEIF gun_pos = 32 THEN
		MOVE G6B, 175, , , , ,
	ELSEIF gun_pos = 33 THEN
		MOVE G6B, 180, , , , ,
	ELSEIF gun_pos = 34 THEN
		MOVE G6B, 185, , , , ,
	ELSEIF gun_pos = 35 THEN
		MOVE G6B, 190, , , , ,
	ENDIF
	
RETURN
	 

shoot_right:
	SPEED 15
	MOVE G6B, , 150, , , , 
	DELAY 2000
	MOVE G6B, , 100, , , , 
	SPEED 5
RETURN
	
shoot_left:
	SPEED 15
	MOVE G6B, , , 150, , , 
	DELAY 2000
	MOVE G6B, , , 100, , ,
	SPEED 5
RETURN

shoot_both:
	SPEED 15
	MOVE G6B, , 150, 150, , ,
	DELAY 2000
	MOVE G6B, , 100, 100, , ,
	SPEED 5
RETURN	
'RETURN
'start
'standard_pose:

crouch:
	IF Crouched = 1 THEN 
		GOTO crouch_up
	ELSEIF Crouched = 0 THEN
		GOTO crouch_down
	ENDIF
'	MOVE G6A,100, 150, 188, 124, 100,  95
'	MOVE G6D,100, 150, 188, 124, 100,  93
'	WAIT
'	Crouched = 1
	
RETURN

crouch_down:
	Crouched = 1
	MOVE G6A,100,  80, 145,  93, 100,  95
	MOVE G6D,100,  80, 145,  93, 100,  93
	WAIT
	MOVE G6A,100, 118, 188,  97, 100,  95
	MOVE G6D,100, 118, 188,  96, 100,  93
	tilt_pos = 5
	tilt_forward = 0
	WAIT
	
	MOVE G6A,100, 150, 188, 124, 100,  95
	MOVE G6D,100, 150, 188, 124, 100,  93
	
	
RETURN

crouch_up:
	Crouched = 0
		
	MOVE G6A,100, 150, 188, 124, 100,  95
	MOVE G6D,100, 150, 188, 124, 100,  93

	MOVE G6A,100, 150, 188, 132, 100,  95
	MOVE G6D,100, 150, 188, 132, 100,  93


	MOVE G6A,100, 118, 188,  97, 100,  95
	MOVE G6D,100, 118, 188,  96, 100,  93

	
	MOVE G6A,100,  80, 145,  93, 100,  95
	MOVE G6D,100,  80, 145,  93, 100,  93
		
RETURN

'crouch
	MOVE G6A,100, 150, 188, 124, 100,  95
	MOVE G6D,100, 150, 188, 124, 100,  93


tilt_right:
	IF Crouched = 0 THEN 
		RETURN
	ENDIF
	IF tilt_pos > 0 THEN
		tilt_pos = tilt_pos - 1
	ENDIF
	GOSUB tilting
RETURN
		
tilt_left:
	IF Crouched = 0 THEN 
		RETURN
	ENDIF
	IF tilt_pos < 10 THEN
		tilt_pos = tilt_pos + 1
	ENDIF
	GOSUB tilting
RETURN


'				 -27,  -28,     +19
'			+4,     ,     ,    , -22

tilt_fwd:
	IF Crouched = 0 THEN 
		RETURN
	ENDIF
	IF tilt_forward < 7 THEN
		tilt_forward = tilt_forward + 1
	ENDIF
	GOSUB tilting
RETURN

tilt_bwd:
	IF Crouched = 0 THEN 
		RETURN
	ENDIF
	IF tilt_forward > 0 THEN
		tilt_forward = tilt_forward - 1
	ENDIF
	GOSUB tilting
RETURN


tilting:
'down and right
	
	IF tilt_pos = 0 THEN
		MOVE G6A,   , 123, 160,    , 119,  
		MOVE G6D,104,    ,    ,    ,  78,  
	ELSEIF tilt_pos = 1 THEN
		MOVE G6A,   , 128, 165,    , 114,  
		MOVE G6D,103,    ,    ,    ,  82,
	ELSEIF tilt_pos = 2 THEN
		MOVE G6A,   , 133, 170,    , 110,  
		MOVE G6D,102,    ,    ,    ,  86,  
	ELSEIF tilt_pos = 3 THEN
		MOVE G6A,   , 140, 176,    , 106,  
		MOVE G6D,101,    ,    ,    ,  90,
	ELSEIF tilt_pos = 4 THEN
		MOVE G6A,   , 146, 182,    , 103,  
		MOVE G6D,100,    ,    ,    ,  100,  	
	ELSEIF tilt_pos = 5 THEN
		MOVE G6A,   , 150, 188,    , 100,  
		MOVE G6D,100,    ,    ,    , 100,   
	ELSEIF tilt_pos = 10 THEN
'down and left 
		MOVE G6A,104,    ,    ,    ,  78,  
		MOVE G6D,   , 123, 160,    , 119, 
	ELSEIF tilt_pos = 9 THEN
		MOVE G6A,103,    ,    ,    ,  82,  
		MOVE G6D,   , 128, 165,    , 114, 
	ELSEIF tilt_pos = 8 THEN
		MOVE G6A,102,    ,    ,    ,  86,  
		MOVE G6D,   , 133, 170,    , 110, 
	ELSEIF tilt_pos = 7 THEN
		MOVE G6A,101,    ,    ,    ,  90,  
		MOVE G6D,   , 140, 176,    , 106, 
	ELSEIF tilt_pos = 6 THEN
		MOVE G6A,100,    ,    ,    , 100,  
		MOVE G6D,   , 146, 182,    , 103, 
	ENDIF
	
	IF tilt_forward = 0 THEN
		MOVE G6A,   ,    ,    , 124,    ,  
		MOVE G6D,   ,    ,    , 124,    ,
	ELSEIF tilt_forward = 1 THEN
		MOVE G6A,   ,    ,    , 126,    ,  
		MOVE G6D,   ,    ,    , 126,    ,
	ELSEIF tilt_forward = 2 THEN
		MOVE G6A,   ,    ,    , 128,    ,  
		MOVE G6D,   ,    ,    , 128,    ,
	ELSEIF tilt_forward = 3 THEN
		MOVE G6A,   ,    ,    , 130,    ,  
		MOVE G6D,   ,    ,    , 130,    ,
	ELSEIF tilt_forward = 4 THEN		 
		MOVE G6A,   ,    ,    , 132,    ,  
		MOVE G6D,   ,    ,    , 132,    ,
	ELSEIF tilt_forward = 5 THEN
		MOVE G6A,   ,    ,    , 134,    ,  
		MOVE G6D,   ,    ,    , 134,    ,
	ELSEIF tilt_forward = 6 THEN
		MOVE G6A,   ,    ,    , 136,    ,  
		MOVE G6D,   ,    ,    , 136,    ,
	ELSEIF tilt_forward = 7 THEN
		MOVE G6A,   ,    ,    , 138,    ,  
		MOVE G6D,   ,    ,    , 138,    ,			
	ENDIF

RETURN	
	'MOVE G6A,100,    ,    ,    , 100,  
	'MOVE G6D,   , 150, 188,    , 100,    