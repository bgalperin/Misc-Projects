GOTO AUTO
FILL 255, 10000


DIM A AS BYTE   ' A  : temporary variable          / REMOCON
DIM LASTCMD AS BYTE

DIM A16 AS BYTE   ' A16,A26 : temporary variable
DIM A26 AS BYTE

DIM gyroflag1 AS BYTE 'Gyro on/off variable
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
GOSUB gyro_on 'archival Gyro sub routine, superceeded by the below. (Not archival anymore)

Retry:
'MUSIC "C"
GOSUB robot_tilt
DELAY 200
ERX 9600, LASTCMD, Retry
'MUSIC "BD"
DELAY 200
noRetry:
'ERX 9600, A, MAIN1

IF LASTCMD = &H66 THEN ' f  = D-Up
	GOSUB forward_tumbling
	WAIT
ELSEIF LASTCMD = &H72 THEN ' r = D-Right
	GOSUB drop_to_knees 'body_throw2
	WAIT
ELSEIF LASTCMD = &H62 THEN ' b = D-Down
	GOSUB back_tumbling
	WAIT
ELSEIF LASTCMD = &H6C THEN ' l = D-Left
	GOSUB body_clap 'splap 'ben01 
	WAIT
ELSEIF LASTCMD = &H46 THEN ' F = O + D-Up
	GOSUB backward_standup
	WAIT
ELSEIF LASTCMD = &H52 THEN ' R = O + D-Right
	GOSUB grabby
	WAIT
ELSEIF LASTCMD = &H42 THEN ' B = O + D-Down
	GOSUB forward_standup
	WAIT
ELSEIF LASTCMD = &H4C THEN ' L = O + D-Left
	GOSUB lunge
	WAIT
ELSEIF LASTCMD = &H65 THEN ' e
	'GOSUB 
	WAIT
ELSEIF LASTCMD = &H74 THEN ' t = Start
	GOSUB sit_down_pose16
	WAIT
ELSEIF LASTCMD = &H45 THEN ' E
	'GOSUB 
	WAIT
ELSEIF LASTCMD = &H54 THEN ' T = O + Start
	GOSUB LIMBO
	WAIT
ELSEIF LASTCMD = &H3C THEN ' < = LeftStick Left
	GOSUB left_attack
	WAIT
ELSEIF LASTCMD = &H31 THEN ' 1 = LeftStick Up-Left
	GOSUB left_forward
	WAIT
ELSEIF LASTCMD = &H44 THEN ' D = LeftStick Up
	GOSUB forward_punch 'Walk3
	WAIT
ELSEIF LASTCMD = &H32 THEN ' 2 = LeftStick Up-Right
	GOSUB right_forward
	WAIT
ELSEIF LASTCMD = &H6d THEN ' m = LeftStick Right
	GOSUB right_attack
	WAIT
ELSEIF LASTCMD = &H33 THEN ' 3 = LeftStick Down-Right
	GOSUB block_right
	WAIT
ELSEIF LASTCMD = &H64 THEN ' d = LeftStick Down
	GOSUB can_can
	WAIT
ELSEIF LASTCMD = &H34 THEN ' 4 = LeftStick Down-Left
	GOSUB block_left
	WAIT
ELSEIF LASTCMD = &H4d THEN ' M = RightStick Down-Left
	GOSUB left_shift
	WAIT
ELSEIF LASTCMD = &H35 THEN ' 5 = RightStick Up-Left
	GOSUB left_turn
	WAIT
ELSEIF LASTCMD = &H48 THEN ' H = RightStick Up
	GOSUB forward_walk
	WAIT
ELSEIF LASTCMD = &H36 THEN ' 6 = RightStick Up-Right
	GOSUB right_turn
	WAIT
ELSEIF LASTCMD = &H3e THEN ' > = RightStick Down-Right
	GOSUB right_shift
	WAIT
ELSEIF LASTCMD = &H37 THEN ' 7 = RightStick Up-Right
	GOSUB turn_R
	WAIT
ELSEIF LASTCMD = &H68 THEN ' h = RightStick Down
	GOSUB backward_walk
	WAIT
ELSEIF LASTCMD = &H38 THEN ' 8 = RightStick Up-Left
	GOSUB turn_L
	WAIT
ELSEIF LASTCMD = &H3D THEN ' =
	GOSUB splits
	WAIT
ELSEIF LASTCMD = &H55 THEN ' U = Triangle
	GOSUB handstanding
	WAIT
ELSEIF LASTCMD = &H75 THEN ' u  = X
	GOSUB bow_pose
	WAIT
ELSEIF LASTCMD = &H53 THEN ' S = Square
	GOSUB wing_move
	WAIT
ELSEIF LASTCMD = &H4B THEN ' K = L1
	GOSUB left_shoot
	WAIT
ELSEIF LASTCMD = &H6B THEN ' k = R1
	GOSUB right_shoot
	WAIT
ELSEIF LASTCMD = &H2F THEN ' \ = L2
	GOSUB left_tumbling
	WAIT
ELSEIF LASTCMD = &H5C THEN ' / = R2
	GOSUB righ_tumbling
	WAIT
ENDIF

IF LASTCMD <> &H53 THEN GOSUB standard_pose
	WAIT

clearbuf:
ERX 9600, LASTCMD, Retry
        WAIT
        GOTO clearbuf
RETURN

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

'robot_tilt: 
'A = AD(7) 
'IF A < 70 THEN GOTO tilt_back 
'IF A > 85 THEN GOTO tilt_front 
'RETURN 
'tilt_back: 
'A = AD(7)  
'IF A < 70 THEN GOTO backward_standup 
'RETURN 
'tilt_front: 
'A = AD(7) 
'IF A > 85 THEN GOTO forward_standup 
'RETURN 
 
 robot_tilt:
 	A = AD(7)
 	IF A > 250 THEN RETURN
 	
 	IF A < 50 THEN GOTO tilt_low
 	IF A > 80 THEN GOTO tilt_high
 	
 	RETURN
 tilt_low:
 	A = AD(7)
 	IF A < 50 THEN GOTO forward_standup
 	'IF A < 60 THEN GOTO backward_standup
 	RETURN
 tilt_high:
 	A = AD(7)
 	IF A > 80 THEN GOTO backward_standup
 	'IF A > 100 THEN GOTO forward_standup
 	RETURN
  
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

gyro_off:
gyroflag1 = 0
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
gyroflag1 = 1
'=======================================================================
' hard cable goes to 0-3; removable cable goes to 4-7
'gyro 1 = 0/4; gryo 2 = 1/5; gyro 3 = 2/6; gyro 4 = 3/7

'F/R gyro has removable PWM cable plug facing fwd
'L/R gyro has removable PWM cable plug facing LEFT OR RIGHT

'Gyroset tells both LEG servo sets to initialize
'tell gyro 1 to affect ankle and knee servos. zeros are for unaffected servos
GYROSET G6A, 2, 1, 1, 1, 2, 0 ' Lt side - l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused
GYROSET G6D, 2, 1, 1, 1, 2, 0 ' Rt side -  l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused
'tell both ARM servo sets to initialize
GYROSET G6B, 1, 0, 0, 0, 0, 0 ' Lt side - F/r shoulder, u/d shoulder, u/d elbow, unused, unused
GYROSET G6C, 1, 0, 0, 0, 0, 0 ' Rt side - F/r shoulder, u/d shoulder, u/d elbow, unused, unused
'=======================================================================
'Gyrodir tells leg sets direction of movement-
'moves knee servo forward or back depending on direction of push, hence value of 1
'and the ankle slot is set to zero for backward movement. Yes, zero's matter here.
GYRODIR G6A,0,0,1,0,1,0 ' Lt side - l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused
GYRODIR G6D,1,0,1,0,0,0 ' rt side - l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused
'tell arm sets direction of movement
'moves shoulders forward or backward depending on direction of push
GYRODIR G6B,0,0,0,0,0,0
GYRODIR G6C,0,0,0,0,0,0
'=======================================================================
'Gyrosense tells leg sets their sensitivity, 0 - 255.
'use this along with the gain adjustment screw on the gyro to perfect balancing
GYROSENSE G6A, 250,200,200,000,200,000 ' Lt side - l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused
GYROSENSE G6D, 250,200,200,000,200,000 ' Rt side -  l/r ankle, f/r ankle, knee, f/r hip, l/r hip, unused

'tell arm sets their sensitivity, 0 - 255.
'use this along with the gain adjustment screw on the gyro to perfect arm swings
GYROSENSE G6B, 255,0,0, 0, 0, 0 ' Lt side - F/r shoulder, u/d shoulder, u/d elbow, unused, unused
GYROSENSE G6C, 255,0,0, 0, 0, 0 ' Rt side - F/r shoulder, u/d shoulder, u/d elbow, unused, unused
'=======================================================================
RETURN

'================================================
'================================================
'SOCCER SPECIFIC MOVES     *************************************************************************************
'======================
'================================================
'================================================
splits:
SPEED 15
HIGHSPEED SETON
MOVE G24,  56,  97, 140,  68, 188,  , 114, 105, 100,  ,  ,  , 125, 103,  98,  ,  ,  ,  52,  81, 140,  68, 188,
WAIT
HIGHSPEED SETOFF
DELAY 2000
SPEED 10
MOVE G24,  54,  89, 182, 153, 168,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  52,  86, 188, 152, 167,
WAIT
MOVE G24, 102, 130,  40,  38, 100,  , 184, 121,  95,  ,  ,  ,  , 121,  94,  ,  ,  , 102, 124,  43,  40, 100,
WAIT
GOSUB backward_standup
WAIT
RETURN

fall_L:
MOVE G24, 116, 135,  76,  99,  91,  , 123,  19,  89,  ,  ,  , 107,  92,  76,  ,  ,  , 116,  72, 155,  84, 122,
WAIT
MOVE G24, 116, 135,  76,  99,  91,  , 186,  12,  78,  ,  ,  , 110, 183, 141,  ,  ,  , 116,  72, 155,  56, 122,
WAIT
MOVE G24, 116, 135,  76,  99,  91,  , 186, 117,  ,  ,  ,  ,  96, 183, 141,  ,  ,  , 116,  72, 155,  56, 122,
WAIT
MOVE G24, 114,  63, 149, 102, 103,  , 186, 110, 109,  ,  ,  , 115, 117,  96,  ,  ,  , 115,  90, 179,  75, 119,
WAIT
GOSUB backward_standup
WAIT
RETURN

fall_R:




RETURN
right_shoot:
        SPEED 4
MOVE G6A, 112, 56, 180, 79, 104, 100
MOVE G6D, 70, 56, 180, 79, 102, 100
MOVE G6B, 110, 45, 70, 100, 100, 100
MOVE G6C, 90, 45, 70, 100, 100, 100
WAIT
right_shoot1:
                SPEED 6
        MOVE G6A, 115, 60, 180, 79, 95, 100
        MOVE G6D, 90, 90, 127, 65, 116, 100
        MOVE G6B, 80, 45, 70, 100, 100, 100
        MOVE G6C, 120, 45, 70, 100, 100, 100
        WAIT
                SPEED 15
                HIGHSPEED SETON
right_shoot2:
        MOVE G6A, 115, 52, 180, 79, 95, 100
        MOVE G6D, 90, 90, 127, 147, 116, 100
        MOVE G6B, 140, 45, 70, 100, 100, 100
        MOVE G6C, 60, 45, 70, 100, 100, 100
        WAIT
                DELAY 500
                HIGHSPEED SETOFF
right_shoot3:
                SPEED 5
        MOVE G6A, 115, 76, 145, 93, 102, 100
        MOVE G6D, 70, 76, 145, 93, 104, 100
        MOVE G6B, 110, 45, 70, 100, 100, 100
        MOVE G6C, 90, 45, 70, 100, 100, 100
        WAIT
RETURN
'================================================
left_shoot:
        SPEED 4
MOVE G6A, 70, 56, 180, 79, 102, 100
MOVE G6D, 112, 56, 180, 79, 104, 100
MOVE G6B, 90, 45, 70, 100, 100, 100
MOVE G6C, 110, 45, 70, 100, 100, 100
WAIT
left_shoot1:
                SPEED 6
        MOVE G6A, 90, 90, 127, 65, 116, 100
        MOVE G6D, 115, 60, 180, 79, 95, 100
        MOVE G6B, 140, 45, 70, 100, 100, 100
        MOVE G6C, 60, 45, 70, 100, 100, 100
        WAIT
                SPEED 15
                HIGHSPEED SETON
left_shoot2:
        MOVE G6A, 90, 90, 127, 147, 116, 100
        MOVE G6D, 115, 52, 180, 79, 95, 100
        MOVE G6B, 60, 45, 70, 100, 100, 100
        MOVE G6C, 140, 45, 70, 100, 100, 100
        WAIT
                DELAY 500
                HIGHSPEED SETOFF
left_shoot3:
                SPEED 5
        MOVE G6A, 70, 76, 145, 93, 104, 100
        MOVE G6D, 115, 76, 145, 93, 102, 100
        MOVE G6B, 90, 45, 70, 100, 100, 100
        MOVE G6C, 110, 45, 70, 100, 100, 100
        WAIT
RETURN

pass_left:



RETURN
pass_right:
SPEED 15
MOVE G6A, 112, 120, 68, 135, 89
MOVE G6D, 77, 21, 150, 153, 128
MOVE G6B, 83, 37, 81
MOVE G6C, 124, 40, 91
WAIT
DELAY 150
'SPEED 12
'MOVE G6A, 112, 120,  68, 137,  88
'MOVE G6D,  91,  12, 153, 159, 110
'MOVE G6B,  64,  37,  81
'MOVE G6C, 142,  40,  91
'WAIT
'DELAY 150
SPEED 8
MOVE G6A, 112, 77, 128, 117, 88
MOVE G6D, 91, 107, 52, 160, 115
MOVE G6B, 100, 37, 81
MOVE G6C, 100, 40, 91
WAIT
SPEED 6
MOVE G6A, 112, 77, 128, 117, 88
MOVE G6D, 87, 70, 126, 119, 114
MOVE G6B, 100, 37, 81
MOVE G6C, 100, 40, 91
WAIT


GOSUB standard_pose
RETURN

'================================================
'================================================
turn_L:
SPEED 13
'shift balance RIGHT
MOVE G6A, 108, 95, 93, 130, 92
MOVE G6D, 89, 99, 95, 130, 111
MOVE G6B, 163, 83, 12
MOVE G6C, 163, 83, 12
WAIT
'lift LEFT leg
MOVE G6A, 112, 90, 126, 96, 94
MOVE G6D, 95, 88, 73, 159, 116
MOVE G6B, 123, 83, 12
MOVE G6C, 123, 83, 12
WAIT
SPEED 10
MOVE G6A, 109, 140, 73, 96, 91
MOVE G6D, 90, 88, 73, 159, 113
MOVE G6B, 111, 83, 12
MOVE G6C, 111, 83, 12
WAIT
GOSUB standard_pose
RETURN

turn_R:
SPEED 13
'shift balance LEFT
MOVE G6A, 89, 99, 95, 130, 111
MOVE G6D, 108, 95, 93, 130, 92
MOVE G6B, 163, 83, 12
MOVE G6C, 163, 83, 12
WAIT
'lift RIGHT leg
MOVE G6A, 95, 88, 73, 159, 116
MOVE G6D, 112, 90, 126, 96, 94
MOVE G6B, 123, 83, 12
MOVE G6C, 123, 83, 12
WAIT
SPEED 10
MOVE G6A, 90, 88, 73, 159, 113
MOVE G6D, 109, 140, 73, 96, 91
MOVE G6B, 111, 83, 12
MOVE G6C, 111, 83, 12
WAIT
GOSUB standard_pose
RETURN


LIMBO:
'1
	MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 100,  99, 106,  ,  ,  , 100,  76, 145,  93, 100,  
	
	DELAY 1000
	GOSUB limbo2
	'GOSUB limbo2
RETURN

limbo2:
'2
MOVE G24,  87, 161,  25, 127, 115,  , 100,  52,  97,  ,  ,  , 100,  99, 106,  ,  ,  ,  86, 161,  29, 126, 111,  

DELAY 1500
'3 
MOVE G24, 116, 161,  25, 127, 115,  , 100,  52,  97,  ,  ,  , 100,  99, 106,  ,  ,  ,  87, 161,  29, 126, 110,  

DELAY 2000
'4  
MOVE G24, 116, 149,  25, 124, 115,  , 100,  52,  97,  ,  ,  , 100,  99, 106,  ,  ,  , 110, 161,  29, 126, 110,  

DELAY 1500
'5  
MOVE G24, 106, 138, 123, 157, 130,  , 100,  52,  97,  ,  ,  , 100,  99, 106,  ,  ,  , 114, 161,  29, 126, 110,  

DELAY 1000
'6 
MOVE G24,  ,  10, 157, 162, 123,  , 100,  32,  97,  ,  ,  , 100,  99, 106,  ,  ,  , 115, 161,  29, 120, 111,  

DELAY 1000
'7 
MOVE G24,  72,  10, 138, 147, 125,  , 100,  32,  97,  ,  ,  , 100,  99, 106,  ,  ,  , 115, 161,  29, 109,  87,  

DELAY 1000
'8
MOVE G24,  81,  10, 138, 162, 113,  , 102,  95, 101,  ,  ,  , 168,  18,  38,  ,  ,  , 102,  ,  29, 121, 107,  

DELAY 1500 
'9 '
'MOVE G24,  91,  12, 131, 162, 122,  , 102,  95, 101,  ,  ,  , 168,  18,  38,  ,  ,  ,  92, 161,  67,  79,  95,  
'MOVE G24,  91,  12, 153, 163, 122,  , 186,  13,  98,  ,  ,  , 168,  18,  38,  ,  ,  ,  92, 161,  77,  77,  95,  
'MOVE G24,  82,  17, 138, 162, 113,  , 190,  32, 105,  ,  ,  , 168,  18,  38,  ,  ,  , 102, 161,  67,  89, 107,  
MOVE G24,  82,  17, 138, 162, 113,  , 190,  32, 105,  ,  ,  , 168,  18,  38,  ,  ,  , 102, 148,  90,  89, 107,  

DELAY 2000
'10 
MOVE G24,  94,  88,  74, 162, 132,  , 190,  32, 105,  ,  ,  , 168,  18,  38,  ,  ,  ,  93,  99, 104,  89,  94,  

DELAY 2000 
'11  
MOVE G24,  91, 104,  45, 162, 122,  , 102, 120, 101,  ,  ,  , 168,  18,  23,  ,  ,  ,  93, 115, 106,  47,  95,  

DELAY 2000
'12 
MOVE G24, 108, 124,  26, 162, 122,  , 102, 120, 101,  ,  ,  , 168,  18,  23,  ,  ,  ,  93, 115, 106,  47,  95,  

DELAY 2000
'13
MOVE G24, 108, 124,  26, 162, 122,  , 102, 120, 101,  ,  ,  , 168,  18,  23,  ,  ,  ,  97, 161,  49,  51,  89,  

DELAY 2000
'14
MOVE G24, 116, 124,  26, 162, 122,  , 102, 120, 101,  ,  ,  , 168,  18,  23,  ,  ,  , 105, 161,  29, 138,  87,  

DELAY 2000
'15
MOVE G24, 100, 142,  26, 146,  ,  , 102, 120, 101,  ,  ,  , 168,  18,  23,  ,  ,  ,  97, 153,  29, 135,  99,  


RETURN

'==================================================
'==================================================
'STANDARD MOVES             *************************************************************************************
'=======================
bow_pose:
        MOVE G6A, 100, 58, 135, 160, 100, 100
        MOVE G6D, 100, 58, 135, 160, 100, 100
        MOVE G6B, 100,  30,  80,  ,  ,  ,
        MOVE G6C, 100,  30,  80,  ,  ,  ,
        WAIT
        DELAY 1000
        RETURN
'================================================
standard_pose:
        MOVE G6A, 100, 76, 145, 93, 100, 100
        MOVE G6D, 100, 76, 145, 93, 100, 100
        MOVE G6B, 100, 30, 80, 100, 100, 100
        MOVE G6C, 100, 30, 80, 100, 100, 100
        WAIT
        
		'GOSUB robot_tilt
        
        RETURN
'================================================
'================================================
hans_up:
        SPEED 5
        MOVE G6A, 100, 76, 145, 93, 100
        MOVE G6D, 100, 76, 145, 93, 100
        MOVE G6B, 100, 168, 150
        MOVE G6C, 100, 168, 150
        WAIT
        RETURN
'================================================
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
sit_hans_up:
        SPEED 10
        MOVE G6A, 100, 151,  23, 140, 101, 100,
        MOVE G6D, 100, 151, 23, 140, 101, 100
        MOVE G6B, 100, 168, 150
        MOVE G6C, 100, 168, 150
        WAIT
        RETURN
'================================================
'================================================
foot_up:
        SPEED 5
        MOVE G6A,  85,  71, 152,  91, 112,  60,
        MOVE G6D, 112,  76, 145,  93,  92,  60,
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        MOVE G6C, 100,  40,  80,    ,    ,    ,
        WAIT
        MOVE G6A,  90,  98, 105, 115, 115,  60,
        MOVE G6D, 116,  74, 145,  98,  93,  60,
        MOVE G6B, 100,  95, 100, 100, 100, 100,
        MOVE G6C, 100, 105, 100, 100, 100, 100,
        WAIT
        MOVE G6A, 100, 151,  23, 140, 115, 100,
        WAIT
        DELAY 1000
        MOVE G6A,  85,  71, 152,  91, 112,  60,
        MOVE G6D, 112,  76, 145,  93,  92,  60,
        WAIT
        RETURN
'================================================
'================================================
body_move:
        SPEED 6
        GOSUB body_move1
        GOSUB body_move2
        GOSUB body_move3
        MOVE G6A, 93, 76, 145, 94, 109, 100
        MOVE G6D, 93, 76, 145, 94, 109, 100
        MOVE G6B, 100,  105, 100, , , ,
        MOVE G6C, 100,  105, 100, , , ,
        WAIT
        MOVE G6A, 104, 112, 92, 116, 107
        MOVE G6D, 79, 81, 145, 95, 108
        MOVE G6B, 100, 105, 100
        MOVE G6C, 100, 105, 100
        WAIT
        MOVE G6A, 93, 76, 145, 94, 109, 100
        MOVE G6D, 93, 76, 145, 94, 109, 100
        MOVE G6B, 100,  105, 100, , , ,
        MOVE G6C, 100,  105, 100, , , ,
        WAIT
        MOVE G6D, 104, 112, 92, 116, 107
        MOVE G6A, 79, 81, 145, 95, 108
        MOVE G6B, 100, 105, 100
        MOVE G6C, 100, 105, 100
        WAIT
        MOVE G6A, 93, 76, 145, 94, 109, 100
        MOVE G6D, 93, 76, 145, 94, 109, 100
        MOVE G6B, 100,  105, 100, , , ,
        MOVE G6C, 100,  105, 100, , , ,
        WAIT
        GOSUB body_move3
        GOSUB body_move2
        GOSUB body_move1
RETURN
'================================================
body_move3:
        MOVE G6A, 93, 76, 145, 94, 109, 100
        MOVE G6D, 93, 76, 145, 94, 109, 100
        MOVE G6B,100,  35,  90, , , ,
        MOVE G6C,100,  35,  90, , , ,
        WAIT
        RETURN
'================================================
body_move2:
        MOVE G6D, 110, 92, 124, 97, 93, 70
        MOVE G6A, 76, 72, 160, 82, 128, 70
        MOVE G6B,100,  35,  90, , , ,
        MOVE G6C,100,  35,  90, , , ,
        WAIT
        RETURN
'================================================
body_move1:
        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN
'================================================
'================================================
wing_move:
        DIM i AS BYTE
        SPEED 5

        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT

        MOVE G6A, 90, 98, 105, 115, 115, 60
        MOVE G6D, 116, 74, 145, 98, 93, 60
        MOVE G6B, 100, 150, 150, 100, 100, 100
        MOVE G6C, 100, 150, 150, 100, 100, 100
        WAIT

        MOVE G6A, 90, 121, 36, 105, 115, 60
        MOVE G6D, 116, 60, 146, 138, 93, 60
        MOVE G6B, 100, 150, 150, 100, 100, 100
        MOVE G6C, 100, 150, 150, 100, 100, 100
        WAIT

        MOVE G6A, 90, 98, 105, 64, 115, 60
        MOVE G6D, 116, 50, 160, 160, 93, 60
        MOVE G6B, 145, 110, 110, 100, 100, 100
        MOVE G6C, 145, 110, 110, 100, 100, 100
        WAIT

        FOR i = 10 TO 15
                SPEED i
                MOVE G6B, 145, 80, 80, 100, 100, 100
                MOVE G6C, 145, 80, 80, 100, 100, 100
                WAIT

                MOVE G6B, 145, 120, 120, 100, 100, 100
                MOVE G6C, 145, 120, 120, 100, 100, 100
                WAIT
        NEXT i

        DELAY 1000
        SPEED 6

        MOVE G6A, 90, 98, 105, 64, 115, 60
        MOVE G6D, 116, 50, 160, 160, 93, 60
        MOVE G6B, 100, 160, 180, 100, 100, 100
        MOVE G6C, 100, 160, 180, 100, 100, 100
        WAIT

        MOVE G6A, 90, 121, 36, 105, 115, 60
        MOVE G6D, 116, 60, 146, 138, 93, 60
        MOVE G6B, 100, 150, 150, 100, 100, 100
        MOVE G6C, 100, 150, 150, 100, 100, 100
        WAIT
        SPEED 4

        MOVE G6A, 90, 98, 105, 115, 115, 60
        MOVE G6D, 116, 74, 145, 98, 93, 60
        WAIT

        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN
'================================================
'================================================

'================================================
handstanding:
        GOSUB fall_forward
        GOSUB standard_pose
        GOSUB foot_up2
        GOSUB standard_pose
        GOSUB back_stand_up
RETURN
'================================================
fall_forward:
        SPEED 10
        MOVE G6A, 100, 155, 25, 140, 100, 100
        MOVE G6D, 100, 155, 25, 140, 100, 100
        MOVE G6B, 130, 50, 85, 100, 100, 100
        MOVE G6C, 130, 50, 85, 100, 100, 100
        WAIT
        MOVE G6A, 60, 165, 25, 160, 145, 100
        MOVE G6D, 60, 165, 25, 160, 145, 100
        MOVE G6B, 150, 60, 90, 100, 100, 100
        MOVE G6C, 150, 60, 90, 100, 100, 100
        WAIT
        MOVE G6A, 60, 165, 30, 165, 155, 100
        MOVE G6D, 60, 165, 30, 165, 155, 100
        MOVE G6B, 170, 10, 100, 100, 100, 100
        MOVE G6C, 170, 10, 100, 100, 100, 100
        WAIT
        SPEED 3
        MOVE G6A, 75, 165, 55, 165, 155, 100
        MOVE G6D, 75, 165, 55, 165, 155, 100
        MOVE G6B, 185, 10, 100, 100, 100, 100
        MOVE G6C, 185, 10, 100, 100, 100, 100
        WAIT
        SPEED 10
        MOVE G6A, 80, 155, 85, 150, 150, 100
        MOVE G6D, 80, 155, 85, 150, 150, 100
        MOVE G6B, 185, 40, 60, 100, 100, 100
        MOVE G6C, 185, 40, 60, 100, 100, 100
        WAIT
        MOVE G6A, 100, 130, 120, 80, 110, 100
        MOVE G6D, 100, 130, 120, 80, 110, 100
        MOVE G6B, 125, 160, 10, 100, 100, 100
        MOVE G6C, 125, 160, 10, 100, 100, 100
        WAIT
        RETURN
'================================================
foot_up2:
        SPEED 6
        MOVE G6A, 100, 125,  65,  10, 100,    ,
        MOVE G6D, 100, 125,  65,  10, 100,    ,
        MOVE G6B, 110,  30,  80,    ,    ,    ,
        MOVE G6C, 110,  30,  80,    ,    ,    ,
        SPEED 3
        MOVE G6A, 100, 125,  65,  10, 100,    ,
        MOVE G6D, 100, 125,  65,  10, 100,    ,
        MOVE G6B, 170,  30,  80,    ,    ,    ,
        MOVE G6C, 170,  30,  80,    ,    ,    ,
        WAIT
        DELAY 200
        SPEED 6
        MOVE G6A, 100,  89, 129,  57, 100,    ,
        MOVE G6D, 100,  89, 129,  57, 100,    ,
        MOVE G6B, 180,  30,  80,    ,    ,    ,
        MOVE G6C, 180,  30,  80,    ,    ,    ,
        WAIT
        MOVE G6A, 100,  64, 179,  57, 100,    ,
        MOVE G6D, 100,  64, 179,  57, 100,    ,
        MOVE G6B, 190,  50,  80,    ,    ,    ,
        MOVE G6C, 190,  50,  80,    ,    ,    ,
        WAIT
        DELAY 2000
        MOVE G6A, 100,  64, 179,  57, 100,    ,
        MOVE G6D, 100,  64, 179,  57, 100,    ,
        MOVE G6B, 190,  50,  80,    ,    ,    ,
        MOVE G6C, 190,  50,  80,    ,    ,    ,
        WAIT
        MOVE G6A, 100,  89, 129,  57, 100,    ,
        MOVE G6D, 100,  89, 129,  57, 100,    ,
        MOVE G6B, 180,  30,  80,    ,    ,    ,
        MOVE G6C, 180,  30,  80,    ,    ,    ,
        WAIT
        SPEED 3
        MOVE G6A, 100, 125,  65,  10, 100,    ,
        MOVE G6D, 100, 125,  65,  10, 100,    ,
        MOVE G6B, 170,  30,  80,    ,    ,    ,
        MOVE G6C, 170,  30,  80,    ,    ,    ,
        WAIT
        SPEED 6
        MOVE G6A, 100, 125,  65,  10, 100,    ,
        MOVE G6D, 100, 125,  65,  10, 100,    ,
        MOVE G6B, 110,  30,  80,    ,    ,    ,
        MOVE G6C, 110,  30,  80,    ,    ,    ,
        WAIT
        RETURN
'================================================
back_stand_up:
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

        SPEED 5
MOVE24  85,  71, 152,  91, 112,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 112,  76, 145,  93,  92,  60,

        SPEED 14
'left up
MOVE24  90, 107, 105, 105, 114,  60,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 114,  76, 145,  93,  90,  60,
'---------------------------------------
'left down
MOVE24  90,  56, 143, 122, 114,  60,  80,  40,  80,    ,    ,    , 105,  40,  80,    ,    ,    , 113,  80, 145,  90,  90,  60,
MOVE24  90,  46, 163, 112, 114,  60,  80,  40,  80,    ,    ,    , 105,  40,  80,    ,    ,    , 112,  80, 145,  90,  90,  60,

        SPEED 10
'left center
MOVE24 100,  66, 141, 113, 100, 100,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 100,  83, 156,  80, 100, 100,
MOVE24 113,  78, 142, 105,  90,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    ,  90, 102, 136,  85, 114,  60,

        SPEED 14
'right up
MOVE24 113,  76, 145,  93,  90,  60, 100,  40,  80,    ,    ,    ,  90,  40,  80,    ,    ,    ,  90, 107, 105, 105, 114,  60,

'right down
MOVE24 113,  80, 145,  90,  90,  60, 105,  40,  80,    ,    ,    ,  80,  40,  80,    ,    ,    ,  90,  56, 143, 122, 114,  60,
MOVE24 112,  80, 145,  90,  90,  60, 105,  40,  80,    ,    ,    ,  80,  40,  80,    ,    ,    ,  90,  46, 163, 112, 114,  60,

        SPEED 10
'right center
MOVE24 100,  83, 156,  80, 100, 100, 100,  40,  80,    ,    ,    ,  90,  40,  80,    ,    ,    , 100,  66, 141, 113, 100, 100,
MOVE24  90, 102, 136,  85, 114,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 113,  78, 142, 105,  90,  60,

        SPEED 14
'left up
MOVE24  90, 107, 105, 105, 114,  60,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 113,  76, 145,  93,  90,  60,
'---------------------------------------

        SPEED 5
MOVE24  85,  71, 152,  91, 112,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 112,  76, 145,  93,  92,  60,

        RETURN
'================================================
'================================================
left_shift:

        SPEED 5
        GOSUB left_shift1
        SPEED 9
        GOSUB left_shift2

        GOSUB left_shift3
        GOSUB left_shift4

        SPEED 9
        GOSUB left_shift5
        GOSUB left_shift6

        RETURN
'================================================
left_shift1:
        MOVE G6A,  85,  71, 152,  91, 112,  60,
        MOVE G6D, 112,  76, 145,  93,  92,  60,
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        MOVE G6C, 100,  40,  80,    ,    ,    ,
        WAIT
        RETURN
'---------------------------
left_shift2:
        MOVE G6D, 110,  92, 124,  97,  93,  70,
        MOVE G6A,  76,  72, 160,  82, 128,  70,
        MOVE G6B, 100,  35,  90,    ,    ,    ,
        MOVE G6C, 100,  35,  90,    ,    ,    ,
        WAIT
        RETURN
'---------------------------
left_shift3:
        MOVE G6A,  93,  76, 145,  94, 109, 100,
        MOVE G6D,  93,  76, 145,  94, 109, 100,
        MOVE G6B, 100,  35,  90,    ,    ,    ,
        MOVE G6C, 100,  35,  90,    ,    ,    ,
        WAIT
        RETURN
'---------------------------
left_shift4:
        MOVE G6A, 110,  92, 124,  97,  93,  70,
        MOVE G6D,  76,  72, 160,  82, 128,  70,
        MOVE G6B, 100,  35,  90,    ,    ,    ,
        MOVE G6C, 100,  35,  90,    ,    ,    ,
        WAIT
        RETURN
'---------------------------
left_shift5:
        MOVE G6D,  86,  83, 135,  97, 114,  60,
        MOVE G6A, 113,  78, 145,  93,  93,  60,
        MOVE G6C,  90,  40,  80,    ,    ,    ,
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        WAIT
        RETURN
'---------------------------
left_shift6:
        MOVE G6D,  85,  71, 152,  91, 112,  60,
        MOVE G6A, 112,  76, 145,  93,  92,  60,
        MOVE G6C, 100,  40,  80,    ,    ,    ,
        MOVE G6B, 100,  40,  80,    ,    ,    ,
        WAIT
        RETURN
'================================================
'================================================
sit_down_pose26:
        IF A26 = 0 THEN GOTO standard_pose26

        A26 = 0
        SPEED 10
        MOVE G6A, 100, 151, 23, 140, 101, 100
        MOVE G6D, 100, 151, 23, 140, 101, 100
        MOVE G6B, 100, 30, 80, 100, 100, 100
        MOVE G6C, 100, 30, 80, 100, 100, 100
        WAIT

        RETURN
'================================================
standard_pose26:
        A26 = 1
        MOVE G6A, 100, 76, 145, 93, 100, 100
        MOVE G6D, 100, 76, 145, 93, 100, 100
        MOVE G6B, 100, 30, 80, 100, 100, 100
        MOVE G6C, 100, 30, 80, 100, 100, 100
        WAIT

        RETURN
'================================================
'================================================
right_shift:

        SPEED 5
        GOSUB right_shift1

        SPEED 9
        GOSUB right_shift2

        GOSUB right_shift3

        GOSUB right_shift4

        SPEED 9
        GOSUB right_shift5
        GOSUB right_shift6

        RETURN
'================================================
right_shift1:
        MOVE G6D, 85, 71, 152, 91, 112, 60
        MOVE G6A, 112, 76, 145, 93, 92, 60
        MOVE G6C, 100,  40,  80,  ,  ,  ,
        MOVE G6B, 100,  40,  80,  ,  ,  ,
        WAIT
        RETURN

right_shift2:
        MOVE G6A, 110, 92, 124, 97, 93, 70
        MOVE G6D, 76, 72, 160, 82, 128, 70
        MOVE G6B,100,  35,  90, , , ,
        MOVE G6C,100,  35,  90, , , ,
        WAIT
        RETURN

right_shift3:
        MOVE G6A, 93, 76, 145, 94, 109, 100
        MOVE G6D, 93, 76, 145, 94, 109, 100
        MOVE G6B,100,  35,  90, , , ,
        MOVE G6C,100,  35,  90, , , ,
        WAIT
        RETURN

right_shift4:
        MOVE G6D, 110, 92, 124, 97, 93, 70
        MOVE G6A, 76, 72, 160, 82, 128, 70
        MOVE G6B,100,  35,  90, , , ,
        MOVE G6C,100,  35,  90, , , ,
        WAIT
        RETURN

right_shift5:
        MOVE G6A, 86, 83, 135, 97, 114, 60
        MOVE G6D, 113, 78, 145, 93, 93, 60
        MOVE G6B, 90,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN

right_shift6:
        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN
'================================================
'================================================
backward_walk:

        SPEED 5
        GOSUB backward_walk1

        SPEED 13
        GOSUB backward_walk2

        SPEED 7
        GOSUB backward_walk3
        GOSUB backward_walk4
        GOSUB backward_walk5

        SPEED 13
        GOSUB backward_walk6

        SPEED 7
        GOSUB backward_walk7
        GOSUB backward_walk8
        GOSUB backward_walk9

        SPEED 13
        GOSUB backward_walk2

        SPEED 5
        GOSUB backward_walk1

        RETURN
'================================================
backward_walk1:
        MOVE G6A, 85, 71, 152, 91, 112, 60
        MOVE G6D, 112, 76, 145, 93, 92, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk2:
        MOVE G6A, 90, 107, 105, 105, 114, 60
        MOVE G6D, 113, 78, 145, 93, 90, 60
        MOVE G6B, 90,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk9:
        MOVE G6A, 90, 56, 143, 122, 114, 60
        MOVE G6D, 113, 80, 145, 90, 90, 60
        MOVE G6B, 80,  40,  80, , , ,
        MOVE G6C,105,  40,  80, , , ,
        WAIT
        RETURN

backward_walk8:
        MOVE G6A, 100, 62, 146, 108, 100, 100
        MOVE G6D, 100, 88, 140, 86, 100, 100
        MOVE G6B, 90,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk7:
        MOVE G6A, 113, 76, 142, 105, 90, 60
        MOVE G6D, 90, 96, 136, 85, 114, 60
        MOVE G6B,100,  40,  80, , , ,
        MOVE G6C,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk6:
        MOVE G6D, 90, 107, 105, 105, 114, 60
        MOVE G6A, 113, 78, 145, 93, 90, 60
        MOVE G6C,90,  40,  80, , , ,
        MOVE G6B,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk5:
        MOVE G6D, 90, 56, 143, 122, 114, 60
        MOVE G6A, 113, 80, 145, 90, 90, 60
        MOVE G6C,80,  40,  80, , , ,
        MOVE G6B,105,  40,  80, , , ,
        WAIT
        RETURN

backward_walk4:
        MOVE G6D, 100, 62, 146, 108, 100, 100
        MOVE G6A, 100, 88, 140, 86, 100, 100
        MOVE G6C,90,  40,  80, , ,,
        MOVE G6B,100,  40,  80, , , ,
        WAIT
        RETURN

backward_walk3:
        MOVE G6D, 113, 76, 142, 105, 90, 60
        MOVE G6A, 90, 96, 136, 85, 114, 60
        MOVE G6C,100,  40,  80, , , ,
        MOVE G6B,100,  40,  80, , , ,
        WAIT
        RETURN
'================================================
'================================================
forward_tumbling:

SPEED 8
GOSUB standard_pose
MOVE G6A, 100, 155, 20, 140, 100, 100
MOVE G6D, 100, 155, 20, 140, 100, 100
MOVE G6B, 130, 50, 85, 100, 100, 100
MOVE G6C, 130, 50, 85, 100, 100, 100
WAIT

MOVE G6A, 60, 165, 30, 165, 155, 100
MOVE G6D, 60, 165, 30, 165, 155, 100
MOVE G6B, 170, 10, 100, 100, 100, 100
MOVE G6C, 170, 10, 100, 100, 100, 100
WAIT

MOVE G6A, 75, 165, 55, 165, 155, 100
MOVE G6D, 75, 165, 55, 165, 155, 100
MOVE G6B, 185, 10, 100, 100, 100, 100
MOVE G6C, 185, 10, 100, 100, 100, 100
WAIT

MOVE G6A, 80, 155, 85, 150, 150, 100
MOVE G6D, 80, 155, 85, 150, 150, 100
MOVE G6B, 185, 40, 60, 100, 100, 100
MOVE G6C, 185, 40, 60, 100, 100, 100
WAIT

MOVE G6A, 100, 130, 120, 80, 110, 100
MOVE G6D, 100, 130, 120, 80, 110, 100
MOVE G6B, 130, 160, 10, 100, 100, 100
MOVE G6C, 130, 160, 10, 100, 100, 100
WAIT

MOVE G6A, 100, 160, 110, 140, 100, 100
MOVE G6D, 100, 160, 110, 140, 100, 100
MOVE G6B, 140, 70, 20, 100, 100, 100
MOVE G6C, 140, 70, 20, 100, 100, 100
WAIT

SPEED 15
MOVE G6A, 100, 56, 110, 26, 100, 100
MOVE G6D, 100, 71, 177, 162, 100, 100
MOVE G6B, 170, 40, 50, 100, 100, 100
MOVE G6C, 170, 40, 50, 100, 100, 100
WAIT

MOVE G6A, 100, 62, 110, 15, 100, 100
MOVE G6D, 100, 71, 128, 113, 100, 100
MOVE G6B, 190, 40, 50, 100, 100, 100
MOVE G6C, 190, 40, 50, 100, 100, 100
WAIT

SPEED 15
MOVE G6A, 100, 55, 110, 15, 100, 100
MOVE G6D, 100, 55, 110, 15, 100, 100
MOVE G6B, 190, 40, 50, 100, 100, 100
MOVE G6C, 190, 40, 50, 100, 100, 100
WAIT

SPEED 10

MOVE G6A, 100, 110, 100, 15, 100, 100
MOVE G6D, 100, 110, 100, 15, 100, 100
MOVE G6B, 170, 160, 115, 100, 100, 100
MOVE G6C, 170, 160, 115, 100, 100, 100
WAIT

MOVE G6A, 100, 170, 70, 15, 100, 100
MOVE G6D, 100, 170, 70, 15, 100, 100
MOVE G6B, 190, 170, 120, 100, 100, 100
MOVE G6C, 190, 170, 120, 100, 100, 100
WAIT

MOVE G6A, 100, 170, 30, 110, 100, 100
MOVE G6D, 100, 170, 30, 110, 100, 100
MOVE G6B, 190, 40, 60, 100, 100, 100
MOVE G6C, 190, 40, 60, 100, 100, 100
WAIT

GOSUB sit_pose
GOSUB standard_pose
RETURN
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
left_tumbling:

SPEED 8
MOVE G6A, 100, 135, 60, 123, 100, 100
MOVE G6D, 100, 135, 60, 123, 100, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT


DELAY 100
SPEED 3
MOVE G6A, 114, 135, 60, 123, 105, 100
MOVE G6D, 88, 110, 91, 116, 100, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT
DELAY 100
MOVE G6A, 114, 135, 60, 123, 105, 100
MOVE G6D, 89, 135, 60, 123, 100, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT

MOVE G6A, 120, 135, 60, 123, 110, 100
MOVE G6D, 89, 135, 60, 123, 130, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT

SPEED 4
MOVE G6A, 120, 135, 60, 123, 120, 100
MOVE G6D, 89, 135, 60, 123, 158, 100
MOVE G6B, 100, 165, 185, 100, 100, 100
MOVE G6C, 100, 165, 185, 100, 100, 100
WAIT

SPEED 8
MOVE G6A, 120, 131, 60, 123, 185, 100
MOVE G6D, 120, 131, 60, 123, 183, 100
MOVE G6B, 100, 165, 185, 100, 100, 100
MOVE G6C, 100, 165, 185, 100, 100, 100
WAIT

DELAY 200

SPEED 5
MOVE G6A, 120, 131, 60, 123, 185, 100
MOVE G6D, 120, 131, 60, 123, 183, 100
MOVE G6B, 100, 120, 145, 100, 100, 100
MOVE G6C, 100, 120, 145, 100, 100, 100
WAIT

SPEED 6

MOVE G6A, 86, 112, 73, 127, 101, 100
MOVE G6D, 105, 131, 60, 123, 183, 100
MOVE G6B, 100, 120, 145, 100, 100, 100
MOVE G6C, 100, 120, 145, 100, 100, 100
WAIT

SPEED 3
MOVE G6A, 86, 118, 73, 127, 101, 100
MOVE G6D, 112, 131, 62, 123, 133, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

SPEED 3
MOVE G6A, 88, 115, 86, 115, 90, 100
MOVE G6D, 107, 135, 62, 123, 113, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

SPEED 4
MOVE G6A, 100, 135, 60, 123, 100, 100
MOVE G6D, 100, 135, 60, 123, 100, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

RETURN
'================================================
'================================================
forward_punch:
        SPEED 15
        MOVE G6A, 92, 100, 110, 100, 107, 100
        MOVE G6D, 92, 100, 110, 100, 107, 100
        MOVE G6B, 190, 150, 10, 100, 100, 100
        MOVE G6C, 190, 150, 10, 100, 100, 100
        WAIT
        SPEED 15
        HIGHSPEED SETON

        MOVE G6B, 190, 10, 75, 100, 100, 100
        MOVE G6C, 190, 140, 10, 100, 100, 100
        WAIT
        DELAY 500
        MOVE G6B, 190, 140, 10, 100, 100, 100
        MOVE G6C, 190, 10, 75, 100, 100, 100
        WAIT
        DELAY 500

        MOVE G6A, 92, 100, 113, 100, 107, 100
        MOVE G6D, 92, 100, 113, 100, 107, 100
        MOVE G6B, 190, 150, 10, 100, 100, 100
        MOVE G6C, 190, 150, 10, 100, 100, 100
        WAIT

        HIGHSPEED SETOFF
        MOVE G6A, 100, 115, 90, 110, 100, 100
        MOVE G6D, 100, 115, 90, 110, 100, 100
        MOVE G6B, 100, 80, 60, 100, 100, 100
        MOVE G6C, 100, 80, 60, 100, 100, 100
        WAIT
        RETURN
'================================================
'================================================
righ_tumbling:

SPEED 8
MOVE G6A, 100, 135, 60, 123, 100, 100
MOVE G6D, 100, 135, 60, 123, 100, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT
DELAY 100

SPEED 3
MOVE G6A, 83, 110, 91, 116, 100, 100
MOVE G6D, 114, 135, 60, 123, 105, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT
DELAY 100

MOVE G6A, 89, 135, 60, 123, 100, 100
MOVE G6D, 114, 135, 60, 123, 105, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT

MOVE G6A, 89, 135, 60, 123, 130, 100
MOVE G6D, 120, 135, 60, 123, 110, 100
MOVE G6B, 100, 120, 140, 100, 100, 100
MOVE G6C, 100, 120, 140, 100, 100, 100
WAIT

SPEED 4
MOVE G6A, 89, 135, 60, 123, 158, 100
MOVE G6D, 120, 135, 60, 123, 120, 100
MOVE G6B, 100, 165, 185, 100, 100, 100
MOVE G6C, 100, 165, 185, 100, 100, 100
WAIT

SPEED 8
MOVE G6A, 120, 131, 60, 123, 183, 100
MOVE G6D, 120, 131, 60, 123, 185, 100
MOVE G6B, 100, 165, 185, 100, 100, 100
MOVE G6C, 100, 165, 185, 100, 100, 100
WAIT

DELAY 200

SPEED 5
MOVE G6A, 120, 131, 60, 123, 183, 100
MOVE G6D, 120, 131, 60, 123, 185, 100
MOVE G6B, 100, 120, 145, 100, 100, 100
MOVE G6C, 100, 120, 145, 100, 100, 100
WAIT

SPEED 6
MOVE G6A, 105, 131, 60, 123, 183, 100
MOVE G6D, 86, 112, 73, 127, 101, 100
MOVE G6B, 100, 120, 145, 100, 100, 100
MOVE G6C, 100, 120, 145, 100, 100, 100
WAIT

SPEED 3
MOVE G6A, 112, 131, 62, 123, 133, 100
MOVE G6D, 86, 118, 73, 127, 101, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

SPEED 3
MOVE G6A, 107, 135, 62, 123, 113, 100
MOVE G6D, 88, 115, 89, 115, 90, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

SPEED 4
MOVE G6A, 100, 135, 60, 123, 100, 100
MOVE G6D, 100, 135, 60, 123, 100, 100
MOVE G6B, 100, 80, 80, 100, 100, 100
MOVE G6C, 100, 80, 80, 100, 100, 100
WAIT

RETURN
'================================================
'================================================
back_tumbling:

SPEED 8
GOSUB standard_pose
MOVE G6A, 100, 170, 71, 23, 100, 100
MOVE G6D, 100, 170, 71, 23, 100, 100
MOVE G6B, 80, 50, 70, 100, 100, 100
MOVE G6C, 80, 50, 70, 100, 100, 100
WAIT

MOVE G6A, 100, 133, 71, 23, 100, 100
MOVE G6D, 100, 133, 71, 23, 100, 100
MOVE G6B, 10, 96, 15, 100, 100, 100
MOVE G6C, 10, 96, 14, 100, 100, 100
WAIT

MOVE G6A, 100, 133, 49, 23, 100, 100
MOVE G6D, 100, 133, 49, 23, 100, 100
MOVE G6B, 45, 116, 15, 100, 100, 100
MOVE G6C, 45, 116, 14, 100, 100, 100
WAIT

MOVE G6A, 100, 133, 49, 23, 100, 100
MOVE G6D, 100, 70, 180, 160, 100, 100
MOVE G6B, 45, 50, 70, 100, 100, 100
MOVE G6C, 45, 50, 70, 100, 100, 100
WAIT

SPEED 15
MOVE G6A, 100, 133, 180, 160, 100, 100
MOVE G6D, 100, 133, 180, 160, 100, 100
MOVE G6B, 10, 50, 70, 100, 100, 100
MOVE G6C, 10, 50, 70, 100, 100, 100
WAIT

HIGHSPEED SETON
MOVE G6A, 100, 95, 180, 160, 100, 100
MOVE G6D, 100, 95, 180, 160, 100, 100
MOVE G6B, 160, 50, 70, 100, 100, 100
MOVE G6C, 160, 50, 70, 100, 100, 100
WAIT

HIGHSPEED SETOFF

MOVE G6A, 100, 130, 120, 80, 110, 100
MOVE G6D, 100, 130, 120, 80, 110, 100
MOVE G6B, 130, 160, 10, 100, 100, 100
MOVE G6C, 130, 160, 10, 100, 100, 100
WAIT

GOSUB back_standing

RETURN
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
left_attack:
        SPEED 7
        GOSUB left_attack1

        SPEED 12
        HIGHSPEED SETON
        MOVE G6A, 98, 157, 20, 134, 110, 100
        MOVE G6D, 57, 115, 77, 125, 134, 100
        MOVE G6B, 107, 135, 108, 100, 100, 100
        MOVE G6C, 112, 92, 99, 100, 100, 100
        WAIT
        DELAY 1000
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB sit_pose
        RETURN
'================================================
left_attack1:
        MOVE G6A, 85, 71, 152, 91, 107, 60
        MOVE G6D, 108, 76, 145, 93, 100, 60
        MOVE G6B, 100,  40,  80,  ,  ,  ,
        MOVE G6C, 100,  40,  80,  ,  ,  ,
        WAIT
        RETURN
'================================================
'================================================
right_attack:
        SPEED 7
        GOSUB right_attack1

        SPEED 12
        HIGHSPEED SETON
        MOVE G6D, 98, 157, 20, 134, 110, 100
        MOVE G6A, 57, 115, 77, 125, 134, 100
        MOVE G6B, 112, 92, 99, 100, 100, 100
        MOVE G6C, 107, 135, 108, 100, 100, 100
        WAIT
        DELAY 1000
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB sit_pose
        RETURN
'================================================
right_attack1:
        MOVE G6D, 85, 71, 152, 91, 107, 60
        MOVE G6A, 108, 76, 145, 93, 100, 60
        MOVE G6C, 100,  40,  80,  ,  ,  ,
        MOVE G6B, 100,  40,  80,  ,  ,  ,
        WAIT
        RETURN
'================================================
'================================================
left_forward:
        SPEED 7

        MOVE G6A, 85, 71, 152, 91, 107, 60
        MOVE G6D, 108, 76, 145, 93, 100, 60
        MOVE G6B, 130,  40,  80,  ,  ,  ,
        MOVE G6C,  70,  40,  80,  ,  ,  ,
        WAIT

        SPEED 12
        HIGHSPEED SETON

        MOVE G6A, 107, 164, 21, 125, 93
        MOVE G6D, 66, 163, 85, 65, 130
        MOVE G6B, 189, 40, 77
        MOVE G6C, 50, 72, 86
        WAIT

        DELAY 1000
        HIGHSPEED SETOFF

        GOSUB sit_pose
        RETURN

'================================================
'================================================
right_forward:
        SPEED 7
        MOVE G6D, 85, 71, 152, 91, 107, 60
        MOVE G6A, 108, 76, 145, 93, 100, 60
        MOVE G6C, 130,  40,  80,  ,  ,  ,
        MOVE G6B,  70,  40,  80,  ,  ,  ,
        WAIT

        SPEED 10
        HIGHSPEED SETON
        MOVE G6D, 107, 164, 21, 125, 93
        MOVE G6A, 66, 163, 85, 65, 130
        MOVE G6C, 189, 40, 77
        MOVE G6B, 50, 72, 86
        WAIT

        DELAY 1000
        HIGHSPEED SETOFF

        GOSUB sit_pose
        RETURN
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



	
left_block:
MOVE G6A, 55,  80, 140,  95, 165, 100
MOVE G6D,110, 170,  20, 125,  90, 100
MOVE G6B,185, 105,  95, 100, 100, 100
MOVE G6C,100,  70,  85, 100, 100, 100
WAIT 
RETURN

lean_rt:
MOVE24  85,  71, 152,  91, 112,  , 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 112,  76, 145,  93,  92,  ,
WAIT
RETURN

block_left:
SPEED 5
GOSUB lean_rt
HIGHSPEED SETON
SPEED 15
GOSUB left_block
SPEED 8
HIGHSPEED SETOFF
DELAY 500
GOSUB sit_down_pose
GOSUB standard_pose
RETURN

right_block:
MOVE G6D, 55,  80, 140,  95, 165, 100
MOVE G6A,110, 170,  20, 125,  90, 100
MOVE G6C,185, 105,  95, 100, 100, 100
MOVE G6B,100,  70,  85, 100, 100, 100
WAIT 
RETURN

lean_lt:
MOVE24  112,  76, 145,  93,  92,  , 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 85,  71, 152,  91, 112, , 

WAIT
RETURN

block_right:
SPEED 5
GOSUB lean_lt
HIGHSPEED SETON
SPEED 15
GOSUB right_block
SPEED 8
HIGHSPEED SETOFF
DELAY 500
GOSUB sit_down_pose
GOSUB standard_pose
RETURN

forward_lunge:
PTP SETOFF
PTP ALLOFF
MOVE24 100,  20, 150, 115, 100, 100, 95, 185, 125, 100, 100, 100,95, 185, 125, 100, 100, 100 ,100,  20, 150, 115, 100, 100
PTP SETON
PTP ALLON

RETURN

lean_forward:
MOVE G6A,101, 100, 118, 110,  99, 100
MOVE G6D,103, 101, 118, 111,  98, 100
MOVE G6B,100,  55,  80, 100, 100, 100
MOVE G6C,100,  55,  80, 100, 100, 100
WAIT
RETURN

lunge:
SPEED 5
GOSUB lean_forward
HIGHSPEED SETON
SPEED 15
GOSUB forward_lunge
HIGHSPEED SETOFF
DELAY 1000
SPEED 5
GOSUB standard_pose
RETURN

knee_drop:
MOVE G6A,100,  50,  35, 125, 100, 100
MOVE G6D,100,  50,  35, 125,  99, 100
MOVE G6B,100,  55,  80, 100, 100, 100
MOVE G6C,100,  55,  80, 100, 100, 100
WAIT
RETURN

drop_to_knees:
GOSUB lean_forward
HIGHSPEED SETON
SPEED 15
GOSUB Knee_drop
HIGHSPEED SETOFF
DELAY 500
SPEED 5
GOSUB standard_pose
RETURN




fwalk_knee_bend:

	SPEED 5
MOVE24  85,  71, 152,  91, 112,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 112,  76, 145,  93,  92,  60,
	
	SPEED 14 
'left up
MOVE24  90, 107, 105, 105, 114,  60,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 114,  76, 145,  93,  90,  60,
'---------------------------------------
'left down
MOVE24  90,  56, 143, 122, 114,  60,  80,  40,  80,    ,    ,    , 105,  40,  80,    ,    ,    , 113,  80, 145,  90,  90,  60,
MOVE24  90,  46, 163, 112, 114,  60,  70,  40,  80,    ,    ,    , 115,  40,  80,    ,    ,    , 112,  80, 145,  90,  90,  60,
	
	SPEED 10
'left center
'MOVE24 100,  66, 141, 113, 100, 100,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 100,  83, 156,  80, 100, 100,
'knee bend
	'SPEED 5
MOVE24 100, 100,  85, 127, 100,    ,  90,  70,  35,    ,    ,    , 120,  70,  35,    ,    ,    , 100, 126, 100,  84, 100,  
'left center
MOVE24 100,  66, 141, 113, 100, 100,  90,  40,  80,    ,    ,    , 110,  35,  60,    ,    ,    , 100,  83, 156,  80, 100, 100,
	SPEED 10
MOVE24 113,  78, 142, 105,  90,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    ,  90, 102, 136,  85, 114,  60,

	SPEED 14
'right up
MOVE24 113,  76, 145,  93,  90,  60, 100,  40,  80,    ,    ,    ,  90,  40,  80,    ,    ,    ,  90, 107, 105, 105, 114,  60,
		
'right down
MOVE24 113,  80, 145,  90,  90,  60, 105,  40,  80,    ,    ,    ,  80,  40,  80,    ,    ,    ,  90,  56, 143, 122, 114,  60,
MOVE24 112,  80, 145,  90,  90,  60, 115,  40,  80,    ,    ,    ,  70,  40,  80,    ,    ,    ,  90,  46, 163, 112, 114,  60,
	
	SPEED 10
'right center
'MOVE24 100,  83, 156,  80, 100, 100, 100,  40,  80,    ,    ,    ,  90,  40,  80,    ,    ,    , 100,  66, 141, 113, 100, 100,
'knee bend
	'SPEED 5
MOVE24 100, 126, 100,  84, 100,    , 120,  70,  35,    ,    ,    ,  90,  70,  35,    ,    ,    , 100, 100,  85, 127, 100, 100,
'right center
MOVE24 100,  83, 156,  80, 100, 100, 115,  35,  60,    ,    ,    ,  90,  40,  80,    ,    ,    , 100,  66, 141, 113, 100, 100,
	SPEED 10
MOVE24  90, 102, 136,  85, 114,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 113,  78, 142, 105,  90,  60,
		
	SPEED 14
'left up
MOVE24  90, 107, 105, 105, 114,  60,  90,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 113,  76, 145,  93,  90,  60,
'---------------------------------------

	SPEED 5
MOVE24  85,  71, 152,  91, 112,  60, 100,  40,  80,    ,    ,    , 100,  40,  80,    ,    ,    , 112,  76, 145,  93,  92,  60,
	
	RETURN
	


'---------------------- can can




Lean_back:
'DIM a40 AS BYTE
'SPEED 10
MOVE G6A, 100, 151,  23,  89, 101
MOVE G6D, 100, 151,  23,  91, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT
RETURN

extend_left_leg:
'SPEED 15
MOVE G6A, 100,  82,  22, 161, 101
MOVE G6D, 100, 151,  23,  91, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT
'		FOR a40 = 0 TO 1
MOVE G6A, 100,  57, 132, 161, 101
MOVE G6D, 100, 151,  23,  91, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT

MOVE G6A, 100,  57,  42, 161, 101
MOVE G6D, 100, 151,  23,  91, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT
'		NEXT a40

RETURN
extend_right_leg:
'SPEED 15
MOVE G6A, 100, 151,  23,  91, 101
MOVE G6D, 100,  82,  22, 161, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT

		'FOR a40 = 0 TO 1
MOVE G6A, 100, 151,  23,  91, 101
MOVE G6D, 100,  57, 132, 161, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT


MOVE G6A, 100, 151,  23,  91, 101
MOVE G6D, 100,  57,  42, 161, 101
MOVE G6B,  45,  30,  80
MOVE G6C,  45,  30,  80
WAIT
		'NEXT a40
RETURN


Standup_from_lean_back:

'SPEED 8

MOVE G6A, 100, 167,  22, 126, 101
MOVE G6D, 100, 165,  21, 128, 101
MOVE G6B, 105,  30,  80
MOVE G6C, 105,  30,  80
WAIT

RETURN

can_can:
DIM a40 AS BYTE
DIM a41 AS BYTE
			SPEED 12
	GOSUB sit_down_pose
	'	FOR a41 = 0 TO 1
			GOSUB lean_back
			SPEED 15
	'		FOR a40 = 0 TO 1
				GOSUB extend_left_leg
	'		NEXT a40
			GOSUB lean_back
			GOSUB extend_right_leg
	'	NEXT a41
	SPEED 12
GOSUB lean_back
GOSUB Standup_from_lean_back
GOSUB standard_pose
RETURN





'---------------------- body_clap
		
	
body_clap:
DIM bc AS BYTE
DIM bc1 AS BYTE

SPEED 6
GOSUB body_clap1
GOSUB body_clap2
GOSUB body_clap3
'FOR bc1 = 1 TO 3
	MOVE G6A,  93,  76, 145,  94, 109, 100
	MOVE G6D,  93,  76, 145,  94, 109, 100
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	MOVE G6A, 104, 112,  92, 116, 107
	MOVE G6D,  79,  81, 145,  95, 108
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	SPEED 15
	FOR bc = 0 TO 0
		MOVE G6B,160,  15,  35, 100, 100, 100
		MOVE G6C,160,  15,  35, 100, 100, 100
		WAIT
		MOVE G6B,160,  25,  40, 100, 100, 100
		MOVE G6C,160,  25,  40, 100, 100, 100
		WAIT
		MOVE G6B,160,  15,  35, 100, 100, 100
		MOVE G6C,160,  15,  35, 100, 100, 100
		WAIT
	NEXT bc
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	DELAY 100
	MOVE G6B,160,  15,  35, 100, 100, 100
	MOVE G6C,160,  15,  35, 100, 100, 100
	WAIT
	SPEED 6

	MOVE G6A,  93,  76, 145,  94, 109, 100
	MOVE G6D,  93,  76, 145,  94, 109, 100
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	SPEED 9
	
	MOVE G6B,160,  15,  35, 100, 100, 100
	MOVE G6C,160,  15,  35, 100, 100, 100
	WAIT
	
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	
	MOVE G6B,160,  15,  35, 100, 100, 100
	MOVE G6C,160,  15,  35, 100, 100, 100
	WAIT
	SPEED 6
	MOVE G6D, 104, 112,  92, 116, 107
	MOVE G6A,  79,  81, 145,  95, 108
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	SPEED 15
	FOR bc = 0 TO 0
		MOVE G6B,160,  15,  35, 100, 100, 100
		MOVE G6C,160,  15,  35, 100, 100, 100
		WAIT
		MOVE G6B,160,  25,  40, 100, 100, 100
		MOVE G6C,160,  25,  40, 100, 100, 100
		WAIT
		MOVE G6B,160,  15,  35, 100, 100, 100
		MOVE G6C,160,  15,  35, 100, 100, 100
		WAIT
	NEXT bc
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
	DELAY 100
	MOVE G6B,160,  15,  35, 100, 100, 100
	MOVE G6C,160,  15,  35, 100, 100, 100
	WAIT
	SPEED 10
	
	MOVE G6A,  93,  76, 145,  94, 109, 100
	MOVE G6D,  93,  76, 145,  94, 109, 100
	MOVE G6B,160,  50,  50, 100, 100, 100
	MOVE G6C,160,  50,  50, 100, 100, 100
	WAIT
'NEXT bc1
	
	GOSUB body_clap3
	GOSUB body_clap2
	GOSUB body_clap1
RETURN
'================================================
body_clap3:
	MOVE G6A, 93,  76, 145,  94, 109, 100
	MOVE G6D, 93,  76, 145,  94, 109, 100
	MOVE G6B,100,  35,  90, , , ,
	MOVE G6C,100,  35,  90, , , ,
	WAIT
	RETURN
'================================================
body_clap2:
	MOVE G6D,110,  92, 124,  97,  93,  70
	MOVE G6A, 76,  72, 160,  82, 128,  70
	MOVE G6B,100,  35,  90, , , ,
	MOVE G6C,100,  35,  90, , , ,
	WAIT
	RETURN
'================================================
body_clap1:
	MOVE G6A, 85,  71, 152,  91, 112, 60
	MOVE G6D,112,  76, 145,  93,  92, 60
	MOVE G6B,100,  40,  80, , , ,
	MOVE G6C,100,  40,  80, , , ,	
	WAIT
	RETURN
	
	
'--------------- Fast Walk 3 ----------------------


DIM MODE AS BYTE


standard:
	MOVE G6A,100,  76, 145,  93, 100, 100
	MOVE G6D,100,  76, 145,  93, 100, 100
	MOVE G6B,100,  30,  80, 100, 100, 100
	MOVE G6C,100,  30,  80, 100, 100, 100
	WAIT
	mode = 0
	RETURN


Walk3:'Fast wide step 

SPEED 10

MOVE G6B,100,  30,  90, 100, 100, 100
MOVE G6C,100,  30,  90, 100, 100, 100
WAIT


SPEED 7
'piece_slope_rise2:
	MOVE G6A, 90,  72, 148,  93, 110,  70
	MOVE G6D,108,  75, 145,  93,  95,  70
	WAIT
SPEED 10
''GOSUB left_foot_hold10_2'5_3
	MOVE G6A, 90,  95, 105,  115, 110, 70
	MOVE G6D,112,  75, 145,  95,  95, 70
	MOVE G6B, 90,  30,  90, 100, 100, 100
	MOVE G6C,110,  30,  90, 100, 100, 100
	WAIT

SPEED 12
HIGHSPEED SETON
FOR i=0 TO 5


'left_foot_hold10:
	MOVE G6A,100,  83, 119, 118, 106, 100
	MOVE G6D,105,  80, 145,  93,  97, 100
	MOVE G6B, 80,  30,  90, 100, 100, 100
	MOVE G6C,120,  30,  90, 100, 100, 100
	WAIT
	
	
	55:
	'left_foot_center1:
	MOVE G6A,105,  62, 145, 115,  97,  100
	MOVE G6D, 95, 110, 124,  88, 106,  100
	MOVE G6B,100,  30,  90, 100, 100, 100
	MOVE G6C,100,  30,  90, 100, 100, 100
	WAIT

	66:
	'right_foot_hold10:
	MOVE G6A,105,  80, 145,  93,  97, 100
	MOVE G6D,100,  83, 119, 118, 106, 100
	MOVE G6B,120,  30,  90, 100, 100, 100
	MOVE G6C, 80,  30,  90, 100, 100, 100
	WAIT
	
	77:
	'right_foot_center1:
	MOVE G6A, 95, 110, 124,  88, 106,  100
	MOVE G6D,105,  62, 145, 115,  97,  100
	MOVE G6B,100,  30,  90, 100, 100, 100
	MOVE G6C,100,  30,  90, 100, 100, 100
	WAIT

	88:

NEXT i
HIGHSPEED SETOFF
SPEED 8

'piece_slope_rise2:
	MOVE G6A, 90,  72, 148,  93, 110,  70
	MOVE G6D,108,  75, 145,  93,  93,  70
	WAIT
SPEED 6
MOVE G6A,100,  80, 145,  88, 100, 100
MOVE G6D,100,  80, 145,  88, 100, 100
WAIT

SPEED 10
GOSUB standard
RETURN

'=============== splap

splap:
	SPEED 10
	MOVE G24, 100, 148,  25, 139, 100,  ,  14, 184, 160,  ,  ,  ,  11, 183, 160,  ,  ,  , 100, 155,  28, 132, 100,  
	'DELAY 500
	SPEED 15
	MOVE G24, 100, 148,  25,  , 100,  ,  57, 184, 160,  ,  ,  ,  53, 183, 160,  ,  ,  , 100, 155,  28,  , 100,  
	DELAY 400
	MOVE G24, 100, 122, 136,  90, 100,  ,  57, 184, 160,  ,  ,  ,  53, 183, 160,  ,  ,  , 100, 121, 141,  85, 100,  
	MOVE G24, 100,  72, 136,  90, 100,  , 173, 184, 160,  ,  ,  , 172, 183, 160,  ,  ,  , 100,  72, 141,  85, 100, 
	SPEED 5
RETURN

splap_takedown:
	HIGHSPEED SETON
	SPEED 15
	MOVE G24, 100, 148,  25, 139, 100,  ,  14, 184, 160,  ,  ,  ,  11, 183, 160,  ,  ,  , 100, 155,  28, 132, 100,  
	DELAY 1000
	MOVE G24, 100, 148,  25,  , 100,  ,  57, 184, 160,  ,  ,  ,  53, 183, 160,  ,  ,  , 100, 155,  28,  , 100,  
	DELAY 400
	MOVE G24, 100, 122, 136,  90, 100,  ,  57, 184, 160,  ,  ,  ,  53, 183, 160,  ,  ,  , 100, 121, 141,  85, 100,  
	MOVE G24, 100,  72, 136,  90, 100,  , 173, 184, 160,  ,  ,  , 172, 183, 160,  ,  ,  , 100,  72, 141,  85, 100, 
	HIGHSPEED SETOFF 
	SPEED 5
RETURN

body_throw1:
'recent:
	SPEED 10
	MOVE G24,  51, 147,  25, 142, 154,  , 157,  53,  89,  ,  ,  , 150,  51,  92,  ,  ,  ,  53, 147,  29, 143, 146,  
	DELAY 500
	MOVE G24,  51, 147,  25, 142, 154,  , 163,  38,  45,  ,  ,  , 160,  30,  58,  ,  ,  ,  53, 147,  29, 143, 146, 
	DELAY 1000 
	MOVE G24,  68, 143,  25, 123, 126,  , 190,  38,  45,  ,  ,  , 188,  30,  58,  ,  ,  ,  62, 146,  30, 119, 143,  
	DELAY 400
	MOVE G24,  90, 129,  40,  88, 112,  ,  ,  38,  45,  ,  ,  ,  ,  30,  58,  ,  ,  ,  88, 139,  44,  79, 123,  
	DELAY 2000 
RETURN

body_throw2:
'recent:
	SPEED 10
	MOVE G24,  81, 156,  31, 133, 116,  , 102,  42,  89,  ,  ,  , 101,  40,  99,  ,  ,  ,  79, 157,  34, 134, 121,  
	DELAY 500 
	MOVE G24,  81, 156,  31, 133, 116,  , 167,  35,  67,  ,  ,  , 159,  37,  75,  ,  ,  ,  79, 157,  34, 134, 121,  
	DELAY 500 
	MOVE G24,  81, 146,  25, 133, 119,  , 184,  23,  58,  ,  ,  , 187,  26,  57,  ,  ,  , 101, 157,  29, 121,  94,  
	DELAY 500
	MOVE G24,  81, 146,  25, 103, 119,  , 190,  23,  58,  ,  ,  , 188,  26,  57,  ,  ,  , 101, 157,  29,  97,  94,  
	DELAY 2000 
RETURN

grabby:
	SPEED 15
	MOVE G8B, 80, 154, 100, 100, 100,  30,  80, 169 
	DELAY 2000 
    MOVE G8B, 80, 101, 100, 100, 100,  30,  80,  98
RETURN


patrick:
	MOVE G24, 100,  76, 145,  93, 100,  , 190, 100, 106,  ,  ,  , 100,  30,  80,  ,  ,  , 100,  76, 145,  93, 100, 
	WAIT 
	MOVE G24, 100,  76, 145,  93, 100,  , 190,  18,  11,  ,  ,  , 100,  30,  80,  ,  ,  , 100,  76, 145,  93, 100,  
	WAIT
	DELAY 2000
	MOVE G24, 100,  76, 145,  93, 100,  , 100,  20,  94,  ,  ,  , 100,  30,  80,  ,  ,  , 100,  76, 145,  93, 100,  
RETURN

evan:

	'FOR i = 1 TO 3
		'start wave
		MOVE G24, 100,  75, 143,  93, 100,  , 100,  30,  80,  ,  ,  , 190,  82,  27,  100,  ,  , 100,  75, 143,  94, 100, 
		MOVE G24, 100,  75, 143,  93, 100,  , 100,  30,  80,  ,  ,  , 100, 182, 118,  180,  ,  , 100,  75, 143,  94, 100,    
	'NEXT i
		WAIT
		DELAY 2000 'wait 2 seconds
		'GETMOTORSET G24,1,1,1,1,1,1,0,1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,1,1,0 'not sure what this does
		MOTOROFF G24 'turn all motors off
		DELAY 2000 'wait 2 seconds
		MOTOR G24 'turn all motors on, defaults limbs back to original position before motors turned off, I think
		DELAY 2000 'wait 2 seconds
		'complete wave 		 
		MOVE G24, 100,  75, 143,  93, 100,  , 100,  30,  80,  ,  ,  ,  97,  39,  66,  100,  ,  , 100,  75, 143,  94, 100,
		'TEMPO 250
		'MUSIC "GFEDCBA"
RETURN

melissa:

SPEED 25
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 130,  30,  80,  ,  ,  , 100,  76, 145,  93, 100,  

MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 138,  21,  45,  ,  ,  , 100,  76, 145,  93, 100,  'down 
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 155,  21,  46,  ,  ,  , 100,  76, 145,  93, 100,  'up
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 138,  21,  45,  ,  ,  , 100,  76, 145,  93, 100,  'down
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 155,  21,  46,  ,  ,  , 100,  76, 145,  93, 100,  'up
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 138,  21,  45,  ,  ,  , 100,  76, 145,  93, 100,  'down
MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 155,  21,  46,  ,  ,  , 100,  76, 145,  93, 100,  'up

MOVE G24, 100,  76, 145,  93, 100,  , 100,  30,  80,  ,  ,  , 130,  30,  80,  ,  ,  , 100,  76, 145,  93, 100,  

RETURN

ben01:

'Turn on/off gyros
'gyroflag1 boolean 

'	IF gyroflag1 = 1 THEN    'if gyro on, then turn off
'		GOSUB gyro_off
'		MUSIC "AE"
'	ELSE
'		GOSUB gyro_on			'if gyro off, then turn on
'		MUSIC "EA"	
'	ENDIF
'Lean Left to shoot around corner
MOVE G6A,109, 164,  27, 116, 108, 100
MOVE G6D, 83, 141,  57, 112,  94, 100
WAIT
MOVE G6A,122, 164,  22, 126, 111, 100
MOVE G6B,187,  13,  97, 100, 100, 100
MOVE G6C,101,  31,  81, 100, 100, 100
MOVE G6D, 70, 121,  78, 113,  93, 100
WAIT
DELAY 2000




RETURN