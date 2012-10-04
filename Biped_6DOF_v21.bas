;******************* 6 DOF test version ********************
KJE	con 1	; first put in new stuff in ifdefs...
'debugIK con 1
'debugGait con 1
#ifdef TCA
ENABLEHSERVO
#else
ENABLEHSERVO2
ENABLEHSERIAL
#endif

; Moved from XBee code as I may want to use these defines for serial monitor/output...
HSERSTAT_CLEAR_INPUT	con 0 			;Clear input buffer
HSERSTAT_CLEAR_OUTPUT	con	1 			;Clear output buffer
HSERSTAT_CLEAR_BOTH		con	2 			;Clear both buffers
HSERSTAT_INPUT_DATA		con	3 			;If input data is available go to label
HSERSTAT_INPUT_EMPTY	con	4 			;If input data is not available go to label
HSERSTAT_OUTPUT_DATA	con	5 			;If output data is being sent go to label
HSERSTAT_OUTPUT_EMPTY	con	6 			;If output data is not being sent go to label
i					var	byte
;DEBUG_ROT con 1
;DEBUG_HSERVO	con 1
;DEBUG_SEQ		con 1
;Project Lynxmotion Phoenix
;Description: Phoenix software
;Software version: V2.1
;Date: 29-10-2009
;Programmer: Jeroen Janssen (aka Xan)
;
;Hardware setup: ABB2 with ATOM 28 Pro, SSC32 V2
;
;NEW IN V2.0
;	- Moved to fixed point calculations
;	- Inverted BodyRotX and BodyRotZ direction
;	- Added deadzone for switching gaits
;	- Added GP Player
;	- SSC version check to enable/disable GP player
;	- Controls changed, Check contol file for more information
;	- Added separate files for control and configuration functions
;	- Solved bug at turn-off sequence
;	- Solved bug about legs beeing lift at small travelvalues in 4 steps tripod gait
;	- Solved bug about body translate results in rotate when balance is on (Kåre)
;	- Sequence for wave gait changed (Kåre)
;	- Improved ATan2 function for IK (Kåre)
;	- Added option to turn on/off eyes (leds)
;	- Moving legs to init position improved
;	- Using Indexed values for legs
;	- Added single leg control
;
; NEW IN V2.1
;	- Added Fast SSC communications
;	- Convert to TimerA from TimerW
;	- 
;
;KNOWN BUGS:
;	- None at the moment ;)
;
;Project file order:
;	1. Phoenix_cfg.bas
;	2. Phoenix_V2x.bas
;	3. Phoenix_Control_xxx.bas
;====================================================================
;[CONSTANTS]
BUTTON_DOWN con 0
BUTTON_UP 	con 1

TRUE		con 1
FALSE		con 0

c1DEC		con 10
c2DEC		con 100
c4DEC		con 10000
c6DEC		con 1000000

cRR			con 0
cRM			con 1
cRF			con 2
cLR			con 3
cLM			con 4
cLF			con 5

cRightLeg	con 0
cLeftLeg	con 1

StepsPerDegree 		con 200

;--------------------------------------------------------------------
;[TABLES]
;ArcCosinus Table
;Table build in to 3 part to get higher accuracy near cos = 1. 
;The biggest error is near cos = 1 and has a biggest value of 3*0.012098rad = 0.521 deg.
;-	Cos 0 to 0.9 is done by steps of 0.0079 rad. (1/127)
;-	Cos 0.9 to 0.99 is done by steps of 0.0008 rad (0.1/127)
;-	Cos 0.99 to 1 is done by step of 0.0002 rad (0.01/64)
;Since the tables are overlapping the full range of 127+127+64 is not necessary. Total bytes: 277
GetACos bytetable	255,254,252,251,250,249,247,246,245,243,242,241,240,238,237,236,234,233,232,231,229,228,227,225, |
					224,223,221,220,219,217,216,215,214,212,211,210,208,207,206,204,203,201,200,199,197,196,195,193, |
					192,190,189,188,186,185,183,182,181,179,178,176,175,173,172,170,169,167,166,164,163,161,160,158, |
					157,155,154,152,150,149,147,146,144,142,141,139,137,135,134,132,130,128,127,125,123,121,119,117, |
					115,113,111,109,107,105,103,101,98,96,94,92,89,87,84,81,79,76,73,73,73,72,72,72,71,71,71,70,70, |
					70,70,69,69,69,68,68,68,67,67,67,66,66,66,65,65,65,64,64,64,63,63,63,62,62,62,61,61,61,60,60,59, |
					59,59,58,58,58,57,57,57,56,56,55,55,55,54,54,53,53,53,52,52,51,51,51,50,50,49,49,48,48,47,47,47, |
					46,46,45,45,44,44,43,43,42,42,41,41,40,40,39,39,38,37,37,36,36,35,34,34,33,33,32,31,31,30,29,28, |
					28,27,26,25,24,23,23,23,23,22,22,22,22,21,21,21,21,20,20,20,19,19,19,19,18,18,18,17,17,17,17,16, |
					16,16,15,15,15,14,14,13,13,13,12,12,11,11,10,10,9,9,8,7,6,6,5,3,0
					
;Sin table 90 deg, persision 0.5 deg (180 values)
GetSin wordtable 0, 87, 174, 261, 348, 436, 523, 610, 697, 784, 871, 958, 1045, 1132, 1218, 1305, 1391, 1478, 1564, |
				 1650, 1736, 1822, 1908, 1993, 2079, 2164, 2249, 2334, 2419, 2503, 2588, 2672, 2756, 2840, 2923, 3007, |
				 3090, 3173, 3255, 3338, 3420, 3502, 3583, 3665, 3746, 3826, 3907, 3987, 4067, 4146, 4226, 4305, 4383, |
				 4461, 4539, 4617, 4694, 4771, 4848, 4924, 4999, 5075, 5150, 5224, 5299, 5372, 5446, 5519, 5591, 5664, |
				 5735, 5807, 5877, 5948, 6018, 6087, 6156, 6225, 6293, 6360, 6427, 6494, 6560, 6626, 6691, 6755, 6819, |
				 6883, 6946, 7009, 7071, 7132, 7193, 7253, 7313, 7372, 7431, 7489, 7547, 7604, 7660, 7716, 7771, 7826, |
				 7880, 7933, 7986, 8038, 8090, 8141, 8191, 8241, 8290, 8338, 8386, 8433, 8480, 8526, 8571, 8616, 8660, |
				 8703, 8746, 8788, 8829, 8870, 8910, 8949, 8987, 9025, 9063, 9099, 9135, 9170, 9205, 9238, 9271, 9304, |
				 9335, 9366, 9396, 9426, 9455, 9483, 9510, 9537, 9563, 9588, 9612, 9636, 9659, 9681, 9702, 9723, 9743, |
				 9762, 9781, 9799, 9816, 9832, 9848, 9862, 9876, 9890, 9902, 9914, 9925, 9935, 9945, 9953, 9961, 9969, |
				 9975, 9981, 9986, 9990, 9993, 9996, 9998, 9999, 10000


;Build tables for Leg configuration like I/O and MIN/MAX values to easy access values using a FOR loop
;Constants are still defined as single values in the cfg file to make it easy to read/configure

;SSC Pin numbers
cHipYawPin 		byteTable cRHipYawPin, cLHipYawPin
cHipRollPin 	byteTable cRHipRollPin, cLHipRollPin
cFemurPin 		byteTable cRFemurPin, cLFemurPin
cTibiaPin 		byteTable cRTibiaPin, cLTibiaPin
cAnklePitchPin 		byteTable cRAnklePitchPin, cLAnklePitchPin
cAnkleRollPin 	byteTable cRAnkleRollPin, cLAnkleRollPin


;Min / Max values
cHipYawMin1 	swordTable cRHipYawMin1, cLHipYawMin1
cHipYawMax1 	swordTable cRHipYawMax1,  cLHipYawMax1
cHipRollMin1 	swordTable cRHipRollMin1, cLHipRollMin1
cHipRollMax1 	swordTable cRHipRollMax1,  cLHipRollMax1
cFemurMin1 		swordTable cRFemurMin1, cLFemurMin1
cFemurMax1 		swordTable cRFemurMax1, cLFemurMax1
cTibiaMin1 		swordTable cRTibiaMin1, cLTibiaMin1
cTibiaMax1 		swordTable cRTibiaMax1, cLTibiaMax1
cAnklePitchMin1 		swordTable cRAnklePitchMin1, cLAnklePitchMin1
cAnklePitchMax1 		swordTable cRAnklePitchMax1, cLAnklePitchMax1
cAnkleRollMin1 	swordTable cRAnkleRollMin1, cLAnkleRollMin1
cAnkleRollMax1 	swordTable cRAnkleRollMax1, cLAnkleRollMax1

;Body Offsets (distance between the center of the body and the center of the coxa)
cOffsetX	swordTable cROffsetX, cLOffsetX
cOffsetZ	swordTable cROffsetZ, cLOffsetZ

;Start positions for the leg
cInitPosX	swordTable cRInitPosX, cLInitPosX
cInitPosY	swordTable cRInitPosY, cLInitPosY
cInitPosZ	swordTable cRInitPosZ, cLInitPosZ

; define the offset in the ARC32 EEPROM where we emulate the SSC-32 from
ARC32_SSC_OFFSET	con	0x400		; we will offset saving all of the SSC-32 by this amount


;--------------------------------------------------------------------
;[REMOTE]				 
cTravelDeadZone	con 2	;The deadzone for the analog input from the remote
;====================================================================
;[ANGLES]
HipYawAngle1		var sword(2)	;Actual Angle of the horizontal hip, decimals = 1
HipRollAngle1		var sword(2)
FemurAngle1			var sword(2)	
TibiaAngle1			var sword(2)	
AnklePitchAngle1		var sword(2)
AnkleRollAngle1		var sword(2)
CogShifterAngle1	var sword

;[HServo]
aswHipYawHServo		var sword(2)	; pre-calculated HSERVO values from Angles above
aswHipRollHServo	var sword(2)
aswFemurHServo		var sword(2)
aswTibiaHServo		var sword(2)
aswAnklePitchHServo	var sword(2)
aswAnkleRollHServo	var sword(2)
aswCogShifterHservo var sword

SERVOSAVECNT	con	32				
aServoOffsets	var	sword(SERVOSAVECNT)		; Our new values - must take stored away values into account...
bCSIn		var		byte					; used in Read/Write servo offsets - checksum read
bCSCalc		var		byte					; Used in Read/Write Servo offsets - calculated checksum


;--------------------------------------------------------------------
;[POSITIONS SINGLE LEG CONTROL]
SLHold	var bit		 	;Single leg control mode

LegPosX	var sword(2)	;Actual X Posion of the Leg
LegPosY	var sword(2)	;Actual Y Posion of the Leg
LegPosZ	var sword(2)	;Actual Z Posion of the Leg
;--------------------------------------------------------------------
;[INPUTS]
butA 	var bit
butB 	var bit
butC 	var bit

prev_butA var bit
prev_butB var bit
prev_butC var bit
;--------------------------------------------------------------------
;[GP PLAYER]
GPStart		var bit			;Start the GP Player
GPSeq		var byte		;Number of the sequence

#ifndef SSC_TURBO_MODE
GPVerData	var byte(3)		;Received data to check the SSC Version
#else
GPVerData	var byte(30)	;Received data to check the SSC Version
VERSTR		bytetable "ver",13
cGPBytes	var	byte
; TASerial definitions
_TASI_cFO	var	byte			; how many bytes have we cached away in our serial buffer

#endif

GPEnable	var bit			;Enables the GP player when the SSC version ends with "GP<cr>"
;--------------------------------------------------------------------
;[OUTPUTS]
LedA var bit	;Red
LedB var bit	;Green
LedC var bit	;Orange
Eyes var bit	;Eyes output
;--------------------------------------------------------------------
;[VARIABLES]
Index 			var byte		;Index universal used
LegIndex		var byte		;Index used for leg Index Number

;GetSinCos / ArcCos
AngleDeg1 		var sword		;Input Angle in degrees, decimals = 1
ABSAngleDeg1 	var word		;Absolute value of the Angle in Degrees, decimals = 1
sin4         	var sword		;Output Sinus of the given Angle, decimals = 4
cos4			var sword		;Output Cosinus of the given Angle, decimals = 4
AngleRad4		var sword		;Output Angle in radials, decimals = 4
NegativeValue	var bit			;If the the value is Negative

;GetAtan2
AtanX			var sword		;Input X
AtanY			var sword		;Input Y
Atan4			var sword		;ArcTan2 output
XYhyp2			var sword		;Output presenting Hypotenuse of X and Y

;GetArcTan2 FLOAT
ArcTanX 		var sword		;Input X
ArcTanY 		var sword		;Input Y
ArcTan4			var slong		;Output ARCTAN2(X/Y)

;Body position
BodyPosX 		var sbyte		;Global Input for the position of the body
BodyPosY 		var sword
BodyPosZ 		var sbyte
SCBodyPosX		var sbyte		;Used for shifting the body while walking

;Body Inverse Kinematics
BodyRotX1				var sword ;Global Input pitch of the body
BodyRotY1				var sword ;Global Input rotation of the body
BodyRotZ1  				var sword ;Global Input roll of the body
IKFeetLocalPosY			var sword	;Local Y length for one leg - Hip Vertical
PosX					var sword ;Input position of the feet X
PosZ					var sword ;Input position of the feet Z
PosY					var sword ;Input position of the feet Y
RotationY				var sbyte ;Input for rotation of a single feet for the gait
sinA4          			var sword ;Sin buffer for BodyRotX calculations
cosA4          			var sword ;Cos buffer for BodyRotX calculations
sinB4          			var sword ;Sin buffer for BodyRotX calculations
cosB4          			var sword ;Cos buffer for BodyRotX calculations
sinG4          			var sword ;Sin buffer for BodyRotZ calculations
cosG4          			var sword ;Cos buffer for BodyRotZ calculations
CPR_X					var sword ;Final X value for centerpoint of rotation
CPR_Y					var sword ;Final Y value for centerpoint of rotation
CPR_Z					var sword ;Final Z value for centerpoint of rotation
BodyRotOffsetY			var sbyte ;Input Y offset value to adjust centerpoint of rotation
BodyRotOffsetZ			var sword ;Input Z offset value to adjust centerpoint of rotation
BodyIKPosX				var sword ;Output Position X of feet with Rotation
BodyIKPosY				var sword ;Output Position Y of feet with Rotation
BodyIKPosZ				var sword ;Output Position Z of feet with Rotation

;Leg Inverse Kinematics
IKFeetPosX	    	var sword	;Input position of the Feet X
IKFeetPosY	    	var sword	;Input position of the Feet Y
IKFeetPosZ			var sword	;Input Position of the Feet Z
IKFeetPosXZ			var sword	;Diagonal direction from Input X and Z
IKSW2				var long	;Length between Shoulder and Wrist, decimals = 2
IKA14		    	var long	;Angle of the line S>W with respect to the ground in radians, decimals = 4
IKA24		    	var long	;Angle of the line S>W with respect to the Femur in radians, decimals = 4
Temp1				var long
Temp2				var long
IKSolution			var bit		;Output true if the solution is possible
IKSolutionWarning 	var bit		;Output true if the solution is NEARLY possible
IKSolutionError		var bit		;Output true if the solution is NOT possible
LegRotPosX			var sword
LegRotPosZ			var sword
;--------------------------------------------------------------------
;[TIMING]
lTimerCnt			var	LONG	; used now also in timing of how long since we received a message
lCurrentTime		var long	
lTimerStart			var long	;Start time of the calculation cycles
lTimerEnd			var long 	;End time of the calculation cycles
CycleTime			var byte	;Total Cycle time
SSCTime  			var word	;Time for servo updates

#if 0	; unless we use timer
PrevSSCTime			var word	;Previous time for the servo updates
#endif
#ifdef DEBUG_ROT
xxxLastBodyRotZ1	var	sword
fDebugRotDisp		var bit
#endif


InputTimeDelay		var byte	;Delay that depends on the input to get the "sneaking" effect
SpeedControl		var word	;Adjustible Delay
;--------------------------------------------------------------------
;[GLOBAL]
HexOn	 	var bit			;Switch to turn on Phoenix
Prev_HexOn	var bit			;Previous loop state 
;--------------------------------------------------------------------
;[Balance]
BalanceMode			var bit
TotalTransX			var sword
TotalTransZ			var sword
TotalTransY			var sword
TotalYbal1			var sword
TotalXBal1			var sword
TotalZBal1			var sword
TotalY				var sword ;Total Y distance between the center of the body and the feet

;[Single Leg Control]
SelectedLeg			var byte
Prev_SelectedLeg	var byte
SLLegX				var sword
SLLegY				var sword
SLLegZ				var sword
AllDown				var bit
SLcogShifted		var bit
SingelLegModeOn		var bit	'A dirty fix for inhibiting walking sub while Single Leg Mode is True

;[gait]
GaitType		var byte	;Gait type
NomGaitSpeed	var byte	;Nominal speed of the gait
GaitCurrentLegNr var nib
ActiveLeg		var bit		;Biped: The active leg is the leg that is in the walking state, the other is in the lifting state
GearSlopON		var bit		;Biped: While walking the active leg must compensate for gear backlash (gear slop) on the Hip Roll and Ankle Roll servos
CompLiftToe		var bit		;Biped: While walking forward only. Compensate for backlash by lifting the toe a bit

LegLiftHeight 	var byte	;Current Travel height
TravelLengthX 	var sword	;Current Travel length X
TravelLengthZ 	var sword	;Current Travel length Z
TravelRotationY var sword	;Current Travel Rotation Y

TLDivFactor		var byte	;Number of steps that a leg is on the floor while walking
NrLiftedPos   	var nib		;Number of positions that a single leg is lifted (1-3)
HalfLiftHeigth	var bit		;If TRUE the outer positions of the ligted legs will be half height	
LiftedMiddlePos var byte 	;Biped: The actual step in gait when the passive lifted leg are in the centered position

GaitInMotion 	var bit		;Temp to check if the gait is in motion
StepsInGait		var byte	;Number of steps in gait
LastLeg 		var bit		;TRUE when the current leg is the last leg of the sequence
GaitStep 	 	var byte	;Actual Gait step

GaitLegNr		var byte(6)	;Init position of the leg

GaitLegNrIn	 	var byte	;Input Number of the leg

GaitPosX 		var sbyte(6) ;Array containing Relative X position corresponding to the Gait
GaitPosY 		var sbyte(6) ;Array containing Relative Y position corresponding to the Gait
GaitPosZ 		var sbyte(6) ;Array containing Relative Z position corresponding to the Gait
GaitRotY 		var sbyte(6) ;Array containing Relative Y rotation corresponding to the Gait

GaitPeak      	var byte   ; Saving the largest (ABS) peak value from GaitPosX,Y,Z and GaitRotY
Walking         var bit      ; True if the robot are walking
LastWalkState	var bit		;Saving

;----------------------------
;LiPo safety
wLiPoVad		var word
bLiPoV1			var byte
LiPoLowVoltage	var bit
LiPoCycleCnt	var nib

;[Debug Level - ]
wDebugLevel		var	word	; this is the current debug level, can set by terminal monitor
; note each of the bits can be used any which way Also obviously 
DBG_LVL_NORMAL	con 	0x01	; - Normal starting debug level
DBG_LVL_VERBOSE	con  	0x02	; - More verbose debug
DBG_LVL_CONTROL	con		0x04	; - Turn on debug outputs for the control (PS2,XBEE...)
DBG_LVL_ENTERLEAVE con 	0x80	; Enter/Leave

;====================================================================
;[TIMER INTERRUPT INIT]
#ifdef TMA
ONASMINTERRUPT TIMERAINT, HANDLE_TIMERA_ASM 
#else
ONASMINTERRUPT TIMERB1INT, HANDLE_TIMERB1_ASM 
#endif

; BUGBUG:: May try to add GP player emulation later...
GPStart = 0
;====================================================================
;[INIT]

pause 10

;Turning off all the leds
LedA = 0
LedB = 0
LedC = 0
Eyes = 0
  

; Get the servo offsets
gosub ReadServoOffsets

;Tars Init Positions
for LegIndex  = 0 to 1
  LegPosX(LegIndex) = cInitPosX(LegIndex)	;Set start positions for each leg
  LegPosY(LegIndex) = cInitPosY(LegIndex)
  LegPosZ(LegIndex) = cInitPosZ(LegIndex)  
next

;Single leg control. Make sure no leg is selected
SelectedLeg = 255 ; No Leg selected
Prev_SelectedLeg = 255

;Body Positions
BodyPosX = 0
BodyPosY = 0
BodyPosZ = 0
SCBodyPosX = 0

;Body Rotations
BodyRotX1 = 0
BodyRotY1 = 0
BodyRotZ1 = 0

;Gait
GaitType = 0
BalanceMode = 0
LegLiftHeight = 50
GaitStep = 1
ActiveLeg = cRightLeg 'Start with the Right leg as the active (walking) leg
GOSUB GaitSelect

;Timer
; Timer A init, used for timing of messages and some times for timing code...
#ifdef TMA
WTIMERTICSPERMSMUL con 64	; BAP28 is 16mhz need a multiplyer and divider to make the conversion with /8192
WTIMERTICSPERMSDIV con 125  ; 
TMA = 0	; clock / 8192					; Low resolution clock - used for timeouts...
ENABLE TIMERAINT
#else
WTIMERTICSPERMSMUL con 256	; Arc32 is 20mhz need a multiplyer and divider to make the conversion with /8192
WTIMERTICSPERMSDIV con 625  ; 
TMB1 = 0	; clock / 8192					; Low resolution clock - used for timeouts...
ENABLE TIMERB1INT
low cStatusLED						; status LED set off/output

; FOR ARC32 will assume you can always do sequences
GPEnable=1


; using HSEROUT for debug messages...
SetHSerial1 H38400,H8DATABITS,HNOPARITY,H1STOPBITS
;gosub TerminalMonitorInit	; init our background terminal code...

#endif

lTimerCnt = 0
enable					;enables all interrupts

;Initialize Controller
gosub InitController

;SSC
SSCTime = 150
HexOn = 0



;====================================================================
;[MAIN]	
main:

  'Start time
  GOSUB GetCurrentTime[], lTimerStart 
  
  ;Read input
  GOSUB ControlInput
  
  ;LiPo safety !!
  ;GOSUB CheckLiPoStatus ;changed b/c not using LiPo
  
  ;GOSUB ReadButtons	;I/O used by the remote
  GOSUB WriteOutputs	;Write Outputs

  ;GP Player
  IF GPEnable THEN
    GOSUB GPPlayer
  ENDIF

  ;Single leg control
  GOSUB SingleLegControl 

  ;Gait
  IF NOT (SingelLegModeOn OR SLHold) THEN ; Quick and dirty fix since I'm using common variables for COG shifting in both single leg and gait mode
    GOSUB GaitSeq
  ENDIF
 
  ;Balance calculations
  TotalTransX = 0 'reset values used for calculation of balance
  TotalTransZ = 0
  TotalTransY = 0
  TotalXBal1 = 0
  TotalYBal1 = 0
  TotalZBal1 = 0
  IF (BalanceMode>0) THEN
    for LegIndex = 0 to 2	; balance calculations for all Right legs
      gosub BalCalcOneLeg [-LegPosX(LegIndex)+GaitPosX(LegIndex), |
      						LegPosZ(LegIndex)+GaitPosZ(LegIndex), |
      						(LegPosY(LegIndex)-cInitPosY(LegIndex))+GaitPosY(LegIndex), |
      						LegIndex]
    next
    
    for LegIndex = 3 to 5	; balance calculations for all Left legs
      gosub BalCalcOneLeg [LegPosX(LegIndex)+GaitPosX(LegIndex), |
    						LegPosZ(LegIndex)+GaitPosZ(LegIndex), |
    						(LegPosY(LegIndex)-cInitPosY(LegIndex))+GaitPosY(LegIndex), |
    						LegIndex]
    next
	gosub BalanceBody
  ENDIF
   
  'Reset IKsolution indicators 
  IKSolution = 0 
  IKSolutionWarning = 0 
  IKSolutionError = 0 


  ;Do IK for all Right legs
  LegIndex = cRightLeg	
	  GOSUB BodyIK [-LegPosX(LegIndex)+BodyPosX+SCBodyPosX+GaitPosX(LegIndex) - TotalTransX, |
	  				 LegPosZ(LegIndex)+BodyPosZ+GaitPosZ(LegIndex) - TotalTransZ, |
	  				 LegPosY(LegIndex)+BodyPosY+GaitPosY(LegIndex) - TotalTransY, |
	  				 GaitRotY(LegIndex), LegIndex] 
	  				 
	  GOSUB RotateLeg [-LegPosX(LegIndex)+BodyPosX+SCBodyPosX+GaitPosX(LegIndex) - TotalTransX, |
	  				 LegPosZ(LegIndex)+BodyPosZ+GaitPosZ(LegIndex) - TotalTransZ, GaitRotY(LegIndex)]
	  				 
	  GOSUB LegIK [LegPosX(LegIndex)-BodyPosX-SCBodyPosX+LegRotPosX+BodyIKPosX-(GaitPosX(LegIndex) - TotalTransX), |
	  				LegPosY(LegIndex)+BodyPosY-BodyIKPosY+GaitPosY(LegIndex) - TotalTransY, |
	  				LegPosZ(LegIndex)+BodyPosZ-LegRotPosZ-BodyIKPosZ+GaitPosZ(LegIndex) - TotalTransZ, LegIndex]    
    
  
  ;Do IK for all Left legs  
  LegIndex = cLeftLeg	
	  GOSUB BodyIK [LegPosX(LegIndex)-BodyPosX-SCBodyPosX+GaitPosX(LegIndex) - TotalTransX, |
	  				LegPosZ(LegIndex)+BodyPosZ+GaitPosZ(LegIndex) - TotalTransZ, |
	  				LegPosY(LegIndex)+BodyPosY+GaitPosY(LegIndex) - TotalTransY, |
	  				GaitRotY(LegIndex), LegIndex] 
	  				
	  GOSUB RotateLeg [LegPosX(LegIndex)+BodyPosX+SCBodyPosX+GaitPosX(LegIndex) - TotalTransX, |
	  				 LegPosZ(LegIndex)+BodyPosZ+GaitPosZ(LegIndex) - TotalTransZ, GaitRotY(LegIndex)]
	  				 	  				
	  GOSUB LegIK [LegPosX(LegIndex)+BodyPosX+SCBodyPosX-LegRotPosX-BodyIKPosX+GaitPosX(LegIndex) - TotalTransX, |
	  				LegPosY(LegIndex)+BodyPosY-BodyIKPosY+GaitPosY(LegIndex) - TotalTransY, |
	  				LegPosZ(LegIndex)+BodyPosZ-LegRotPosZ-BodyIKPosZ+GaitPosZ(LegIndex) - TotalTransZ, LegIndex] 
  
  
  ;Check mechanical limits
  GOSUB CheckAngles

  ;Write IK errors to leds
  LedC = IKSolutionWarning
  LedA = IKSolutionError

  ;Drive Servos
  IF HexOn THEN  
    IF HexOn AND Prev_HexOn=0 THEN
      Sound cSound,[60\4000,80\4500,100\5000]
      Eyes = 1
  	ENDIF
	'low cBattLED'debugging
    ;Set SSC time
  	IF(ABS(TravelLengthX)>cTravelDeadZone | ABS(TravelLengthZ)>cTravelDeadZone | ABS(TravelRotationY)>cTravelDeadZone) THEN
  	  SSCTime = NomGaitSpeed + (InputTimeDelay*2) + SpeedControl
  	  'high cBattLED
	  ;Add aditional delay when Balance mode is on
      IF BalanceMode THEN
 	    SSCTime = SSCTime + 100
      ENDIF
      
	ELSE ;Movement speed excl. Walking
	  SSCTime = 200 + SpeedControl
  	ENDIF
	; note we broke up the servo driver into start/commit that way we can output all of the servo information
	; before we wait and only have the termination information to output after the wait.  That way we hopefully
	; be more accurate with our timings...
	GOSUB ServoDriverStart

;;;
	;Sync BAP with SSC while walking to ensure the prev is completed before sending the next one
	GaitPeak = 0 ;Reset
	; Finding any incident of GaitPos/Rot <>0:
   	FOR LegIndex = 0 to 1
     	IF GaitPeak < ABS(GaitPosX(LegIndex)) THEN
        	GaitPeak = ABS(GaitPosX(LegIndex))
     	ELSEIF GaitPeak < ABS(GaitPosY(LegIndex))
       		GaitPeak = ABS(GaitPosY(LegIndex))
     	ELSEIF GaitPeak < ABS(GaitPosZ(LegIndex))
       		GaitPeak = ABS(GaitPosZ(LegIndex))
     	ELSEIF GaitPeak < ABS(GaitRotY(LegIndex))
       		GaitPeak = ABS(GaitRotY(LegIndex))
     	ENDIF
   	NEXT
   	IF (GaitPeak > 2)  or Walking or SLcogShifted THEN ;if GaitPeak is higher than 2 the robot are still walking
		Walking = (GaitPeak > 2)		; remember why we came in here
#if 0
		;Get endtime and calculate wait time
		GOSUB GetCurrentTime[], lTimerEnd   
		CycleTime = ((lTimerEnd-lTimerStart) * WTIMERTICSPERMSMUL) / WTIMERTICSPERMSDIV 
		;Wait for previous commands to be completed while walking
		pause (PrevSSCTime - CycleTime) MIN 1 ;   Min 1 ensures that there alway is a value in the pause command  
#else
		HSERVOWAIT [cRHipYawPin, cRHipRollPin, cRFemurPin,|
					cRTibiaPin, cRAnklePitchPin, cRAnkleRollPin,|
	  				cLHipYawPin, cLHipRollPin, cLFemurPin,|
					cLTibiaPin, cLAnklePitchPin, cLAnkleRollPin, cCogShifterpin]
#endif
	ENDIF
	GOSUB ServoDriverCommit  	
  ELSE ;ELSE from IF HexOn... drive servos
  
    ;Turn the bot off
    IF (Prev_HexOn OR NOT AllDown) THEN
      SSCTime = 600
	  GOSUB ServoDriverStart
	  GOSUB ServoDriverCommit  		
      Sound cSound,[100\5000,80\4500,60\4000]      
      pause 600
    ELSE   
	  GOSUB FreeServos
	  Eyes = 0
    ENDIF
  ' Only when the robot is not active do I do the Terminal monitor...
;  gosub TerminalMonitor[0]
  ENDIF	
  
  ;Store previous HexOn State
  IF HexOn THEN
    Prev_HexOn = 1
  ELSE
    Prev_HexOn = 0
  ENDIF
  
  LastWalkState = Walking 'save
  
goto main
;dead:
;goto dead
;====================================================================
;====================================================================
;[CheckLiPoStatus]LiPo safety warning!!!
;If voltage drop to 6 volt give audio warning!! (The Polyquest LiPo must not go under 5,6v!)
;5,5v = 284
;6,0v = 310
;8,4v = 432
CheckLiPoStatus:

  wLiPoVad = HSERVOSTATE P33 ; Read VL 
  IF (wLiPoVad<330) THEN ;330 = 6,44 volt 
    IF(HexOn) THEN
	  'Turn off immediately!!
	  hserout["Low Voltage", 13]
	  BodyPosX = 0
	  BodyPosY = 0
	  BodyPosZ = 0
	  BodyRotX1 = 0
	  BodyRotY1 = 0
	  BodyRotZ1 = 0
	  TravelLengthX = 0
	  TravelLengthZ = 0
	  TravelRotationY = 0
				
	  SSCTime = 300
	  GOSUB ServoDriverStart
	  GOSUB ServoDriverCommit
	  HexOn = 0
	  LiPoLowVoltage = 1
	  ;Sound P9,[100\2000,100\3000,100\4000,100\3000,100\2000] ;Major Warning beeper!
	ENDIF
	
  ENDIF
  IF (LiPoLowVoltage) THEN ;Give a warning continously, since the voltage probably will raise a little when servos are turned off
    ;Sound P9,[100\2000,100\3000,100\4000] ;Warning beeper
    HexOn = 0 ;Lets keep it turned off
  ENDIF
  bLiPoV1 = wLiPoVad*c2DEC/512 ;Calculate actual voltage with one decimal (fixed point)
  
;  ;Send the voltage value to the transmitter every 15. cycle:
  IF (LiPoCycleCnt = 15) THEN
  	'GOSUB XBeeOutputVal[bLiPoV1]
  	'hserout ["LiPo:", dec wLiPoVad, " LiPoVoltage=", dec bLiPoV1,13]
  	LiPoCycleCnt = 0
  ENDIF
  LiPoCycleCnt = LiPoCycleCnt + 1
  
return

;[ReadButtons] Reading input buttons from the ABB
ReadButtons:
  input P4
  input P5
  input P6
	
  prev_butA = butA
  prev_butB = butB
  prev_butC = butC
	
  butA = IN4
  butB = IN5
  butC = IN6
return
;--------------------------------------------------------------------
;[WriteOutputs] Updates the state of the leds
WriteOutputs:
;  IF ledA = 1 THEN
;	low p4
;  ENDIF
;  IF ledB = 1 THEN
;	low p5
;  ENDIF
;  IF ledC = 1 THEN
;	low p6
;  ENDIF
  IF Eyes = 0 THEN
    low cEyesPin
  ELSE
    high cEyesPin
  ENDIF
return
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;[GP PLAYER]
; Arc32 roll our own sequence code...
wGPSeqPtr		var word
abGPServoPins	var	byte(32)		; remember which pins are defined for this sequence
bGPCntServos	var	byte			; how many servos are used in this sequence
bGPServoNum		var	byte
bGPCntSteps		var	byte			; how many moves are in this sequence...
bGPStepNum		var	byte			; which step are we on.
awGPStepServoVals var	word(32)	; servo value for each pin in desired pulse width
swHSVal			var	sword			; converted to HServo value.
wGPStepTime		var	word			; How long this step will take

GPPlayer:
  ;Start sequence
	IF (GPStart=1) THEN
		readdm ARC32_SSC_OFFSET + GPSEQ*2, [str wGPSeqPtr\2]

		; make sure there is a sequence...
		IF (wGPSeqPtr <> 0)  and (wGPSeqPtr <> 0xffff)	THEN
			; now lets get the header information, will skip sequence number
#ifdef DEBUG_SEQ
			if (wDebugLevel & DBG_LVL_NORMAL) then
				hserout [13, 13, "Start Sequence: ", dec GPSEQ, " ", hex wGPSeqPtr, 13, 13]
			endif
#endif			
			readdm wGPSeqPtr+1,[bGPCntServos, bGPCntSteps]

#ifdef DEBUG_SEQ			
			if (wDebugLevel & DBG_LVL_NORMAL) then
				hserout [hex wGPSeqPtr, " Cnt Servos: ", dec bGPCntServos, "  Steps:", dec bGPCntSteps, 13]
			endif
#endif			
			; now lets read in the pins
			wGPSeqPtr = wGPSeqPtr + 3 ; point to start of pin information.
			for bGPServoNum = 0 to bGPCntServos - 1
				readdm wGPSeqPtr, [abGPServoPins(bGPServoNum)]	; read in the pin, igore max value after
				wGPSeqPtr = wGPSeqPtr + 3
			next


			; now lets start cycling through the steps... Will do seperate HSERVO call for each pin in each step...
			wGPSeqPtr = wGPSeqPtr + 2 ; ignore step-1 time.

#ifdef DEBUG_SEQ
			if (wDebugLevel & DBG_LVL_NORMAL) then
				hserout ["Start Sequences: ", dec wGPSeqPtr, " ", hex wGPSeqPtr, 13]
			endif
#endif

			for bGPStepNum = 1 to bGPCntSteps ; start off 1 biased as I don't use this value and don't have to cnt -1...
				readdm wGPSeqPtr, [str awGPStepServoVals\2*bGPCntServos, wGPStepTime.highbyte, wGPStepTime.lowByte] ; note did not change time bytes order ???
	
				for bGPServoNum = 0 to bGPCntServos - 1
					; need to convert the value to HServo Value
					swHSVal = (awGPStepServoVals(bGPServoNum)*20 - 30000) +  aServoOffsets(abGPServoPins(bGPServoNum)) ; convert to hservo and take care of offsets
					hservo [abGPServoPins(bGPServoNum) \ swHSVal\ abs(HServoPos(abGPServoPins(bGPServoNum)) - swHSVal) * 20 / wGPStepTime]
#ifdef DEBUG_SEQ
					; need to debug this to see what values am I doing...
					if (wDebugLevel & DBG_LVL_VERBOSE) then
						hserout [" ",dec abGPServoPins(bGPServoNum), ":", sdecswHSVal ]
					endif
#endif							
				next
#ifdef DEBUG_SEQ
				if (wDebugLevel & DBG_LVL_VERBOSE) then
			 		hserout [" T:", dec wGPStepTime, 13]		
			 	endif
#endif			 	
				; now lets wait for the step to complete
				pause wGPStepTime
				wGPSeqPtr = wGPSeqPtr + 2*bGPCntServos + 2	; increment to the next sequence
			next
		endif
		GPStart = 0	; say we are done	
	endif	
			
return

;--------------------------------------------------------------------
;[SINGLE LEG CONTROL]
SingleLegControl

  ;Check if all legs are down
  AllDown = LegPosY(cRightLeg)=cInitPosY(cRightLeg) & LegPosY(cLeftLeg)=cInitPosY(cLeftLeg) 
  IF (NOT SLHold) THEN ;Reset these values:
  	GearSlopON = False
  	SpeedControl = 0
  ENDIF
  IF (SelectedLeg=cRightLeg OR SelectedLeg=cLeftLeg) THEN    
    IF(SelectedLeg<>Prev_SelectedLeg) THEN
    
      IF(AllDown)THEN
        IF NOT SLcogShifted THEN 
        	SpeedControl = 300 ; Extra delay while shifting COG
        	;Shift COG at first before lifting leg:
        	IF SelectedLeg = cLeftLeg THEN
        		ActiveLeg = cRightLeg ; Define the Active leg as the opposite of the selected one
      	  		'Shift COG over to the right leg:
      	  		CogShifterAngle1 = -cSliderHalfMaxMinDeg * 2
      	  		SCBodyPosX = -CogShifterAngle1/cSCBPX 
    		ELSE
    			ActiveLeg = cLeftLeg
      	  		'Shift COG over to the left leg:
      	  		CogShifterAngle1 = cSliderHalfMaxMinDeg * 2
      	  		SCBodyPosX = -CogShifterAngle1/cSCBPX 
    		ENDIF
    		SLcogShifted = TRUE
    	ELSE          
        	LegPosY(SelectedLeg) = cInitPosY(SelectedLeg)-20 ;Lift leg a bit when it got selected  
        	
			;Store current status
  			Prev_SelectedLeg = SelectedLeg	         
        ENDIF   
      ELSE ;Return prev leg back to the init position
	    LegPosX(Prev_SelectedLeg) = cInitPosX(Prev_SelectedLeg)
	    LegPosY(Prev_SelectedLeg) = cInitPosY(Prev_SelectedLeg)
	    LegPosZ(Prev_SelectedLeg) = cInitPosZ(Prev_SelectedLeg)
      ENDIF
      
    ELSEIF (NOT SLHold)
      LegPosY(SelectedLeg) = cInitPosY(SelectedLeg)+SLLegY ;Using a centered joystick (XP)
      LegPosX(SelectedLeg) = cInitPosX(SelectedLeg)+SLLegX
      LegPosZ(SelectedLeg) = cInitPosZ(SelectedLeg)+SLLegZ 
      IF SLLegY <-cTravelDeadZone THEN
        GearSlopON = True 'compensate for gear slop / gear backlash when leg is lifted a little
      ENDIF 
      IF SLLegZ <-cTravelDeadZone THEN
        CompLiftToe = TRUE
      ENDIF
      SLcogShifted = FALSE 'is this enough?? or do I need to reset it other places too?   
    ENDIF

 
  ELSE ;All legs to init position
    IF (NOT AllDown) THEN
      for LegIndex = 0 to 1 
	    LegPosX(LegIndex) = cInitPosX(LegIndex)
	    LegPosY(LegIndex) = cInitPosY(LegIndex)
	    LegPosZ(LegIndex) = cInitPosZ(LegIndex)
      next
    ENDIF
    IF Prev_SelectedLeg<>255 THEN
      Prev_SelectedLeg = 255
      SLcogShifted = FALSE ' here too?
    ENDIF
  ENDIF

return
;--------------------------------------------------------------------
GaitSelect
  ;Gait selector
  IF (GaitType = 0) THEN ;9 step Biped gait, Note: Half Walking cycle!
	'GaitLegNr(cRightLeg) = 1
	'GaitLegNr(cLeftLeg) = 8	
		  	    
	'NrLiftedPos = 1
	HalfLiftHeigth = 1
	LiftedMiddlePos = 5	
	TLDivFactor = 13
	StepsInGait = 9
	NomGaitSpeed = 60
  ENDIF  
    
return
;--------------------------------------------------------------------
;[GAIT Sequence]
GaitSeq
   ;Check IF the Gait is in motion
  GaitInMotion = ((ABS(TravelLengthX)>cTravelDeadZone) | (ABS(TravelLengthZ)>cTravelDeadZone) | (ABS(TravelRotationY)>cTravelDeadZone) )
  
  ;Don't cycle the gait while not walking:
  IF NOT Walking Then 
    GaitStep = 1 'Keep it to the first step until leg start walking again  
    ;Decide what leg to set active before start walking after standing still:
    IF TravelRotationY > cTravelDeadZone THEN ;The robot are commanded to walk and turn left
      ActiveLeg = cRightLeg ; This means that the left leg are going to be lifted first
    ELSEIF TravelRotationY < -cTravelDeadZone
      ActiveLeg = cLeftLeg ; This means that the right leg are going to be lifted first
    ENDIF
    ;Same method as for the TravelRotationY, but making sure that sidewalking has higher priority then TravelRotation by placing the code after:
    IF TravelLengthX > cTravelDeadZone THEN ;The robot are commanded to sidewalk to the left
      ActiveLeg = cRightLeg ; This means that the left leg are going to be lifted first
    ELSEIF TravelLengthX < -cTravelDeadZone
      ActiveLeg = cLeftLeg
    ENDIF
  ENDIF
  
  ;Calculate Gait sequence
  LastLeg = 0
  for LegIndex = 0 to 1 ; for all legs
  
    if LegIndex = 1 then ; last leg
      LastLeg = 1 
    endif 
    
    GOSUB BipedGAIT [LegIndex] 
  next	; next leg
return
;--------------------------------------------------------------------
;[BipedGAIT], Half walk Cycle !
; Note: The first and the last GaitStep are used for shifting COG (SC), both leg (feet) are also on ground and walking while SC
BipedGAIT [GaitCurrentLegNr]
  
  ;Clear values under the cTravelDeadZone
  IF (GaitInMotion=0) THEN
    TravelLengthX=0
    TravelLengthZ=0
    TravelRotationY=0
  ENDIF
  
  ;Prevent that the feet crashes into eachother while doing sidewalking:
  ;The robot are commanded to sidewalk to the right and the opposite leg (now the left leg) are the active leg: 
  IF (TravelLengthX > cMaxOppositeTravel) AND (ActiveLeg = cLeftLeg) THEN
    TravelLengthX = cMaxOppositeTravel
    
  ELSEIF (TravelLengthX < -cMaxOppositeTravel) AND (ActiveLeg = cRightLeg)
    TravelLengthX = -cMaxOppositeTravel
  ENDIF  
  
  IF ActiveLeg = GaitCurrentLegNr THEN 'Is this leg the active walking leg?
  	IF ((GaitStep = 1) or (GaitStep = 2)) THEN 'SC towards the active leg + Walk
    	'Shift COG routine here:
    	IF ActiveLeg = cRightLeg THEN
      	  'Shift COG over to the right leg:
      	  CogShifterAngle1 = -cSliderHalfMaxMinDeg * GaitStep
      	  SCBodyPosX = -CogShifterAngle1/cSCBPX 'just for testing.. 
    	ELSE
      	  'Shift COG over to the left leg:
      	  CogShifterAngle1 = cSliderHalfMaxMinDeg * GaitStep
      	  SCBodyPosX = -CogShifterAngle1/cSCBPX 'just for testing.. 
    	ENDIF
    	'Call walk sub
    	GOSUB WalkInDirection [GaitCurrentLegNr]
    ELSEIF ((GaitStep = StepsInGait) or (GaitStep = (StepsInGait-1))) 'SC towards the passive leg + Walk
    	'Shift COG routine here:
    	IF ActiveLeg = cRightLeg THEN
      	  'Shift COG over to the left leg:
      	  CogShifterAngle1 = -cSliderHalfMaxMinDeg * (StepsInGait - GaitStep + 1) ;GaitStep = (StepsInGait-1) => cSliderHalfMaxMinDeg*2
      	  SCBodyPosX = -CogShifterAngle1/cSCBPX 'just for testing..  
    	ELSE
      	  'Shift COG over to the right leg:
      	  CogShifterAngle1 = cSliderHalfMaxMinDeg * (StepsInGait - GaitStep + 1)
      	  SCBodyPosX = -CogShifterAngle1/cSCBPX 'just for testing.. 
    	ENDIF
    	'Call walk sub
    	GOSUB WalkInDirection [GaitCurrentLegNr]
    ELSE ' Walking only:
    	'Call walk sub
    	GOSUB WalkInDirection [GaitCurrentLegNr]
  	ENDIF

  ELSE 'The current leg is not the active, its moving into the lifting state:
  	CompLiftToe = FALSE ; Reset
    IF ((GaitStep = 1) or (GaitStep = 2) or (GaitStep = StepsInGait) or (GaitStep = (StepsInGait-1))) THEN
      'Call walk sub only
      GOSUB WalkInDirection [GaitCurrentLegNr]
      GearSlopON = False 'don't compensate
    ELSE 'Lifting state, lift leg and move it towards the walking direction:
      ;At this moment the gait is not very universal...
      GearSlopON = True 'compensate for gear slop / gear backlash
      IF (GaitStep = (LiftedMiddlePos-2)) & GaitInMotion THEN
        GaitPosX(GaitCurrentLegNr) = -TravelLengthX/2
      	GaitPosY(GaitCurrentLegNr) = -LegLiftHeight/(HalfLiftHeigth+1)
      	GaitPosZ(GaitCurrentLegNr) = -TravelLengthZ/2
      	GaitRotY(GaitCurrentLegNr) = -TravelRotationY/2
      	
      ELSEIF (GaitStep = (LiftedMiddlePos-1)) & GaitInMotion
        GaitPosX(GaitCurrentLegNr) = -TravelLengthX/4
      	GaitPosY(GaitCurrentLegNr) = -LegLiftHeight
      	GaitPosZ(GaitCurrentLegNr) = -TravelLengthZ/4
      	GaitRotY(GaitCurrentLegNr) = -TravelRotationY/4
      	
      	;Leg middle up position:
  	    ;Gait in motion					   					| Gait NOT in motion, return to home position:
      ELSEIF ((GaitInMotion & (GaitStep = LiftedMiddlePos)) | (NOT GaitInMotion & GaitStep=LiftedMiddlePos & ((ABS(GaitPosX(GaitCurrentLegNr))>2) | (ABS(GaitPosZ(GaitCurrentLegNr))>2) | (ABS(GaitRotY(GaitCurrentLegNr))>2))))
        GaitPosX(GaitCurrentLegNr) = 0
    	GaitPosY(GaitCurrentLegNr) = -LegLiftHeight
    	GaitPosZ(GaitCurrentLegNr) = 0
    	GaitRotY(GaitCurrentLegNr) = 0
    	
      ELSEIF (GaitStep = (LiftedMiddlePos+1)) & GaitInMotion
        GaitPosX(GaitCurrentLegNr) = TravelLengthX/4
      	GaitPosY(GaitCurrentLegNr) = -LegLiftHeight
      	GaitPosZ(GaitCurrentLegNr) = TravelLengthZ/4
      	GaitRotY(GaitCurrentLegNr) = TravelRotationY/4
      	IF TravelLengthZ <-cTravelDeadZone THEN 'Only comp while walking forward
      	  CompLiftToe = TRUE
      	ENDIF
      	;Leg front down position:
      ELSEIF (GaitStep = (LiftedMiddlePos+2))& (GaitPosY(GaitCurrentLegNr)<0)
        GaitPosX(GaitCurrentLegNr) = TravelLengthX/2
      	GaitPosY(GaitCurrentLegNr) = -LegLiftHeight/(HalfLiftHeigth+1)
      	GaitPosZ(GaitCurrentLegNr) = TravelLengthZ/2
      	GaitRotY(GaitCurrentLegNr) = TravelRotationY/2
      	IF TravelLengthZ <-cTravelDeadZone THEN
      	  CompLiftToe = TRUE
      	ENDIF
      ENDIF 
    ENDIF
  ENDIF
  
  IF NOT Walking THEN 'this must be improved and integrated to the gait cycle better
    CogShifterAngle1 = 0
    SCBodyPosX = 0
  ENDIF
  
  ;Advance to the next step
  IF LastLeg THEN	;The last leg in this step
    GaitStep = GaitStep+1
    IF GaitStep>StepsInGait THEN
      GaitStep = 1
      IF ActiveLeg = cRightLeg THEN 'At the end of a half walkcycle toogle active leg
        ActiveLeg = cLeftLeg
      ELSE
        ActiveLeg = cRightLeg
      ENDIF
    ENDIF
  ENDIF
  #ifdef debugGait
  if GaitCurrentLegNr = cLeftLeg then
	hserout ["Step#:",dec GaitStep," WalkingState:", dec Walking," GaitInMotion:", dec GaitInMotion,  " ActiveLeg (0=R):", dec ActiveLeg, " TLX:", sdec TravelLengthX,|
	 " GaitPosX:", sdec GaitPosX(GaitCurrentLegNr)  , 13]
  endif	
	
  #endif
  
return
;--------------------------------------------------------------------
;[WalkInDirection] a part of the gait routine
WalkInDirection [GaitCurrentLegNr]
  GaitPosX(GaitCurrentLegNr) = GaitPosX(GaitCurrentLegNr) - (TravelLengthX/TLDivFactor)     
  GaitPosY(GaitCurrentLegNr) = 0  
  GaitPosZ(GaitCurrentLegNr) = GaitPosZ(GaitCurrentLegNr) - (TravelLengthZ/TLDivFactor)
  GaitRotY(GaitCurrentLegNr) = GaitRotY(GaitCurrentLegNr) - (TravelRotationY/TLDivFactor)
return

;--------------------------------------------------------------------
;[BalCalcOneLeg]
BalLegNr var nib
BalCalcOneLeg [PosX, PosZ, PosY, BalLegNr]
  ;Calculating centerpoint (of rotation) of the body to the feet
  CPR_Z = cOffsetZ(BalLegNr)+PosZ
  CPR_X = cOffsetX(BalLegNr)+PosX
  CPR_Y = 150 + PosY' using the value 150 to lower the centerpoint of rotation 'BodyPosY +
  TotalTransY = TotalTransY + PosY
  TotalTransZ = TotalTransZ + CPR_Z
  TotalTransX = TotalTransX + CPR_X
  
  gosub GetATan2 [CPR_X, CPR_Z]
  TotalYbal1 =  TotalYbal1 + (ATan4*1800) / 31415

    
  gosub GetATan2 [CPR_X, CPR_Y]
  TotalZbal1 = TotalZbal1 + ((ATan4*1800) / 31415) -900 'Rotate balance circle 90 deg
  
  gosub GetATan2 [CPR_Z, CPR_Y]
  TotalXbal1 = TotalXbal1 + ((ATan4*1800) / 31415) - 900 'Rotate balance circle 90 deg
  
return

;--------------------------------------------------------------------
;[BalanceBody]
BalanceBody:
	TotalTransZ = TotalTransZ/6 
	TotalTransX = TotalTransX/6
	TotalTransY = TotalTransY/6

	if TotalYbal1 > 0 then		'Rotate balance circle by +/- 180 deg
		TotalYbal1 = TotalYbal1 - 1800
	else
		TotalYbal1 = TotalYbal1 + 1800	
	endif
	if TotalZbal1 < -1800 then	'Compensate for extreme balance positions that causes owerflow
		TotalZbal1 = TotalZbal1 + 3600
	endif
	
	if TotalXbal1 < -1800 then	'Compensate for extreme balance positions that causes owerflow
		TotalXbal1 = TotalXbal1 + 3600
	endif
	
	;Balance rotation
	TotalYBal1 = -TotalYbal1/6
	TotalXBal1 = -TotalXbal1/6
	TotalZBal1 = TotalZbal1/6

return
;--------------------------------------------------------------------
;[GETSINCOS] Get the sinus and cosinus from the angle +/- multiple circles
;AngleDeg1 	- Input Angle in degrees
;Sin4    	- Output Sinus of AngleDeg
;Cos4  		- Output Cosinus of AngleDeg
GetSinCos[AngleDeg1]
	;Get the absolute value of AngleDeg
	IF AngleDeg1 < 0 THEN
	  ABSAngleDeg1 = AngleDeg1 *-1
	ELSE
	  ABSAngleDeg1 = AngleDeg1
	ENDIF
	
	;Shift rotation to a full circle of 360 deg -> AngleDeg // 360
	IF AngleDeg1 < 0 THEN	;Negative values
		AngleDeg1 = 3600-(ABSAngleDeg1-(3600*(ABSAngleDeg1/3600)))
	ELSE				;Positive values
		AngleDeg1 = ABSAngleDeg1-(3600*(ABSAngleDeg1/3600))
	ENDIF	
	
	IF (AngleDeg1>=0 AND AngleDeg1<=900) THEN	; 0 to 90 deg
		Sin4 = GetSin(AngleDeg1/5) 			; 5 is the presision (0.5) of the table
		Cos4 = GetSin((900-(AngleDeg1))/5) 	
		
	ELSEIF (AngleDeg1>900 AND AngleDeg1<=1800) 	; 90 to 180 deg
		Sin4 = GetSin((900-(AngleDeg1-900))/5) ; 5 is the presision (0.5) of the table	
		Cos4 = -GetSin((AngleDeg1-900)/5)			
		
	ELSEIF (AngleDeg1>1800 AND AngleDeg1<=2700) ; 180 to 270 deg
		Sin4 = -GetSin((AngleDeg1-1800)/5) 	; 5 is the presision (0.5) of the table
		Cos4 = -GetSin((2700-AngleDeg1)/5)
		
	ELSEIF (AngleDeg1>2700 AND AngleDeg1<=3600) ; 270 to 360 deg
		Sin4 = -GetSin((3600-AngleDeg1)/5) ; 5 is the presision (0.5) of the table	
		Cos4 = GetSin((AngleDeg1-2700)/5)			
	ENDIF
	
return
;--------------------------------------------------------------------
;[GETARCCOS] Get the sinus and cosinus from the angle +/- multiple circles
;Cos4    	- Input Cosinus
;AngleRad4 	- Output Angle in AngleRad4
GetArcCos[Cos4]
  ;Check for negative value
  IF (Cos4<0) THEN
    Cos4 = -Cos4
    NegativeValue = 1
  ELSE
    NegativeValue = 0
  ENDIF

  ;Limit Cos4 to his maximal value
  Cos4 = (Cos4 max c4DEC)
  
  IF (Cos4>=0 AND Cos4<9000) THEN
    AngleRad4 = GetACos(Cos4/79) ;79=table resolution (1/127)
    AngleRad4 = AngleRad4*616/c1DEC ;616=acos resolution (pi/2/255) 
    
  ELSEIF (Cos4>=9000 AND Cos4<9900)
    AngleRad4 = GetACos((Cos4-9000)/8+114) ;8=table resolution (0.1/127), 114 start address 2nd bytetable range 
    AngleRad4 = AngleRad4*616/c1DEC ;616=acos resolution (pi/2/255) 
    
  ELSEIF (Cos4>=9900 AND Cos4<=10000)
    AngleRad4 = GetACos((Cos4-9900)/2+227) ;2=table resolution (0.01/64), 227 start address 3rd bytetable range 
    AngleRad4 = AngleRad4*616/c1DEC ;616=acos resolution (pi/2/255) 
  ENDIF  
       
  ;Add negative sign
  IF NegativeValue THEN
    AngleRad4 = 31416 - AngleRad4
  ENDIF

return AngleRad4
;--------------------------------------------------------------------
;[GETATAN2] Simplyfied ArcTan2 function based on fixed point ArcCos
;ArcTanX 		- Input X
;ArcTanY 		- Input Y
;ArcTan4  		- Output ARCTAN2(X/Y)
;XYhyp2			- Output presenting Hypotenuse of X and Y
GetAtan2 [AtanX, AtanY]
  XYhyp2 = SQR ((AtanX*AtanX*c4DEC) + (AtanY*AtanY*c4DEC))
  GOSUB GetArcCos [AtanX*c6DEC / XYHyp2]
 
  Atan4 = AngleRad4 * (AtanY/ABS(AtanY)) ;Add sign 
return Atan4
;--------------------------------------------------------------------
;[BODY INVERSE KINEMATICS] 
;BodyRotX         - Global Input pitch of the body 
;BodyRotY         - Global Input rotation of the body 
;BodyRotZ         - Global Input roll of the body 
;RotationY         - Input Rotation for the gait 
;PosX            - Input position of the feet X 
;PosZ            - Input position of the feet Z 
;SinB          		- Sin buffer for BodyRotX
;CosB           	- Cos buffer for BodyRotX
;SinG          		- Sin buffer for BodyRotZ
;CosG           	- Cos buffer for BodyRotZ
;BodyIKPosX         - Output Position X of feet with Rotation 
;BodyIKPosY         - Output Position Y of feet with Rotation 
;BodyIKPosZ         - Output Position Z of feet with Rotation
BodyIKLeg var nib
BodyIK [PosX, PosZ, PosY, RotationY, BodyIKLeg] 

  ;Calculating totals from center of the body to the feet 
  CPR_X = cOffsetX(BodyIKLeg)+PosX 
  CPR_Y = PosY + BodyRotOffsetY ; Define centerpoint for rotation along the Y-axis
  CPR_Z = cOffsetZ(BodyIKLeg) + PosZ + BodyRotOffsetZ
  
  ;Successive global rotation matrix: 
  ;Math shorts for rotation: Alfa (A) = Xrotate, Beta (B) = Zrotate, Gamma (G) = Yrotate 
  ;Sinus Alfa = sinA, cosinus Alfa = cosA. and so on... 
  
  ;First calculate sinus and cosinus for each rotation: 
   GOSUB GetSinCos [BodyRotX1+TotalXBal1] 
  SinG4 = Sin4
  CosG4 = Cos4
  
  GOSUB GetSinCos [BodyRotZ1+TotalZBal1] 
  SinB4 = Sin4
  CosB4 = Cos4
  
  GOSUB GetSinCos [BodyRotY1+(RotationY*c1DEC)+TotalYBal1] 
  SinA4 = Sin4
  CosA4 = Cos4

  ;Calcualtion of rotation matrix: 
  ;BodyIKPosX = TotalX - (TotalX*CosA*CosB - TotalZ*CosB*SinA + PosY*SinB)  
  ;BodyIKPosZ = TotalZ - (TotalX*CosG*SinA + TotalX*CosA*SinB*SinG + TotalZ*CosA*CosG - TotalZ*SinA*SinB*SinG - PosY*CosB*SinG)   
  ;BodyIKPosY = PosY   - (TotalX*SinA*SinG - TotalX*CosA*CosG*SinB + TotalZ*CosA*SinG + TotalZ*CosG*SinA*SinB + PosY*CosB*CosG) 
  BodyIKPosX = (CPR_X*c2DEC - ( CPR_X*c2DEC*CosA4/c4DEC*CosB4/c4DEC - CPR_Z*c2DEC*CosB4/c4DEC*SinA4/c4DEC + CPR_Y*c2DEC*SinB4/c4DEC ))/c2DEC
  BodyIKPosZ = (CPR_Z*c2DEC - ( CPR_X*c2DEC*CosG4/c4DEC*SinA4/c4DEC + CPR_X*c2DEC*CosA4/c4DEC*SinB4/c4DEC*SinG4/c4DEC + CPR_Z*c2DEC*CosA4/c4DEC*CosG4/c4DEC - CPR_Z*c2DEC*SinA4/c4DEC*SinB4/c4DEC*SinG4/c4DEC - CPR_Y*c2DEC*CosB4/c4DEC*SinG4/c4DEC ))/c2DEC
  BodyIKPosY = (CPR_Y  *c2DEC - ( CPR_X*c2DEC*SinA4/c4DEC*SinG4/c4DEC - CPR_X*c2DEC*CosA4/c4DEC*CosG4/c4DEC*SinB4/c4DEC + CPR_Z*c2DEC*CosA4/c4DEC*SinG4/c4DEC + CPR_Z*c2DEC*CosG4/c4DEC*SinA4/c4DEC*SinB4/c4DEC + CPR_Y*c2DEC*CosB4/c4DEC*CosG4/c4DEC ))/c2DEC
  
return 
;--------------------------------------------------------------------
;[Local Leg Rotation] YAW rotate only, compensate for hip rotation
RotateLeg [PosX, PosZ, RotationY] 

  ;Calculating totals from center of the body to the feet 
  CPR_X = PosX 
  CPR_Z = PosZ
  
  ;Successive global rotation matrix: 
  ;Math shorts for rotation: Alfa (A) = Xrotate, Beta (B) = Zrotate, Gamma (G) = Yrotate 
  ;Sinus Alfa = sinA, cosinus Alfa = cosA. and so on... 
  
  ;First calculate sinus and cosinus for Y rotation: 
   
  GOSUB GetSinCos [-BodyRotY1-(RotationY*c1DEC)] 
  SinA4 = Sin4
  CosA4 = Cos4

  ;Calcualtion of rotation matrix:
  ;Y rotation only (Yaw) 
  ;LegRotPosX = (CPR_X- (CPR_X*CosA - CPR_Z*SinA))
  ;LegRotPosZ = (CPR_Z- (CPR_X*SinA + CPR_Z*CosA))
  
  LegRotPosX = (CPR_X*c2DEC - ( CPR_X*c2DEC*CosA4/c4DEC - CPR_Z*c2DEC*SinA4/c4DEC))/c2DEC
  LegRotPosZ = (CPR_Z*c2DEC - ( CPR_X*c2DEC*SinA4/c4DEC + CPR_Z*c2DEC*CosA4/c4DEC))/c2DEC

return 
;--------------------------------------------------------------------
;[LEG INVERSE KINEMATICS] Calculates the angles of the coxa, Femur and tibia for the given position of the feet
;IKFeetPosX			- Input position of the Feet X
;IKFeetPosY			- Input position of the Feet Y
;IKFeetPosZ			- Input Position of the Feet Z
;IKSolution			- Output true IF the solution is possible
;IKSolutionWarning 	- Output true IF the solution is NEARLY possible
;IKSolutionError	- Output true IF the solution is NOT possible
;FemurAngle1	   	- Output Angle of Femur in degrees
;TibiaAngle1  	 	- Output Angle of Tibia in degrees
;CoxaAngle1			- Output Angle of Coxa in degrees
LegIKLegNr var nib
cGearSlop	con 50 'test value
cToeComp	con 150
LegIK [IKFeetPosX, IKFeetPosY, IKFeetPosZ, LegIKLegNr]

	;Calculate IKCoxaAngle and IKFeetPosXZ
	GOSUB GetATan2 [IKFeetPosX, IKFeetPosY]
	IF GearSlopON AND (LegIKLegNr = ActiveLeg) THEN
	 	HipRollAngle1(LegIKLegNr) = -((ATan4*180) / 3141) +900 + cGearSlop
	ELSE
		HipRollAngle1(LegIKLegNr) = -((ATan4*180) / 3141) +900
	ENDIF
	IKFeetLocalPosY = (XYHyp2/c2DEC)-cHipVertLength
	
	HipYawAngle1(LegIKLegNr) = BodyRotY1+(GaitRotY(LegIKLegNr)*c1DEC) ;
		
	;Length between the Coxa and tars (foot)
	;IKFeetPosXZ = XYhyp2/c2DEC
	
	;Using GetAtan2 for solving IKA1 and IKSW
	;IKA14 - Angle between SW line and the ground in radians
	'GOSUB GetATan2 [IKFeetPosY, IKFeetPosXZ-cCoxaLength], IKA14
	GOSUB GetArcTan2 [IKFeetPosZ, IKFeetLocalPosY], IKA14 'from felix float
	'GOSUB GetATan2 [IKFeetPosZ, IKFeetLocalPosY], IKA14
	;IKSW2 - Length between Femur axis and tars
	'IKSW2 = XYhyp2
	IKSW2 = SQR((((IKFeetPosZ)*(IKFeetPosZ))+(IKFeetLocalPosY*IKFeetLocalPosY))*c4DEC)

	
	;IKA2 - Angle of the line S>W with respect to the Femur in radians
	Temp1 = (((cFemurLength*cFemurLength) - (cTibiaLength*cTibiaLength))*c4DEC + (IKSW2*IKSW2))
	Temp2 = ((2*cFemurlength)*c2DEC * IKSW2)
	GOSUB GetArcCos [Temp1 / (Temp2/c4DEC) ], IKA24	

 
	
	;IKFemurAngle
	FemurAngle1(LegIKLegNr) = -(IKA14 + IKA24) * 180 / 3141 + 900 -cFemurOffset

	;IKTibiaAngle
	Temp1 = (((cFemurLength*cFemurLength) + (cTibiaLength*cTibiaLength))*c4DEC - (IKSW2*IKSW2))
	Temp2 = (2*cFemurlength*cTibiaLength)
	GOSUB GetArcCos [Temp1 / Temp2]

	TibiaAngle1(LegIKLegNr) = -(900-AngleRad4*180/3141)
	
	;AnklePitchAngle
	IF (CompLiftToe AND NOT(LegIKLegNr = ActiveLeg)) THEN
	  AnklePitchAngle1(LegIKLegNr) = FemurAngle1(LegIKLegNr) - TibiaAngle1(LegIKLegNr) -cAnklePitchOffset + cFemurOffset - BodyRotX1 - cToeComp/(1+SingelLegModeOn) ;Do half ToeComp in single leg mode
	  'high cBattLED' visual debugging
	ELSE
	  AnklePitchAngle1(LegIKLegNr) = FemurAngle1(LegIKLegNr) - TibiaAngle1(LegIKLegNr) -cAnklePitchOffset + cFemurOffset - BodyRotX1
	  'low cBattLED
	ENDIF
	;AnkleRollAngle
	IF GearSlopON AND (LegIKLegNr = ActiveLeg) THEN
		IF LegIKLegNr = cRightLeg then
			AnkleRollAngle1(LegIKLegNr) = -HipRollAngle1(LegIKLegNr)+ 2*cGearSlop - BodyRotZ1
		ELSE
			AnkleRollAngle1(LegIKLegNr) = -HipRollAngle1(LegIKLegNr)+ 2*cGearSlop + BodyRotZ1
		ENDIF
	ELSE
		IF LegIKLegNr = cRightLeg then
			AnkleRollAngle1(LegIKLegNr) = -HipRollAngle1(LegIKLegNr) - BodyRotZ1
		ELSE
			AnkleRollAngle1(LegIKLegNr) = -HipRollAngle1(LegIKLegNr) + BodyRotZ1
		ENDIF
	ENDIF
	;Set the Solution quality	
	IF(IKSW2 < (cFemurLength+cTibiaLength-30)*c2DEC) THEN
		IKSolution = 1
	ELSE
		IF(IKSW2 < (cFemurLength+cTibiaLength)*c2DEC) THEN
			IKSolutionWarning = 1
		ELSE
			IKSolutionError = 1	
		ENDIF
	ENDIF
	
#ifdef debugIK
  if LegIKLegNr = 0 then
	hserout ["X:", sdec IKFeetPosX, " Y:", sdec IKFeetPosY, " Z:", sdec IKFeetPosZ,| 
			" == LY:", sdec IKFeetLocalPosY,|
			" == L IK HS:",sdec HipRollAngle1(LegIKLegNr), " F:", sdec FemurAngle1(LegIKLegNr), " T:", sdec TibiaAngle1(LegIKLegNr), |
			" A:", sdec AnklePitchAngle1(LegIKlegNr),|
				" SWE: ", hex IKSolution, hex IKSolutionWarning, hex IKSolutionError, 13]
  endif	
	
#endif

	
return
;--------------------------------------------------------------------
;[ARCTAN2] Gets the Inverse Tangus from X/Y with the where Y can be zero or negative
;ArcTanX 		- Input X
;ArcTanY 		- Input Y
;ArcTan4  		- Output ARCTAN2(X/Y)
GetArcTan2 [ArcTanX, ArcTanY]
	IF(ArcTanX = 0) THEN	; X=0 -> 0 or PI
		IF(ArcTanY >= 0) THEN
			ArcTan4 = 0
		ELSE
			ArcTan4 = 31415
		ENDIF
	ELSE	
		IF(ArcTanY = 0) THEN	; Y=0 -> +/- Pi/2
			IF(ArcTanX > 0) THEN
				ArcTan4 = 15707
			ELSE
				ArcTan4 = -15707
			ENDIF
		ELSE
			IF(ArcTanY > 0) THEN	;ARCTAN(X/Y)
				ArcTan4 = TOINT(FATAN(TOFLOAT(ArcTanX) / TOFLOAT(ArcTanY))*10000.0)
			ELSE	
				IF(ArcTanX > 0) THEN	;ARCTAN(X/Y) + PI	
					ArcTan4 = TOINT(FATAN(TOFLOAT(ArcTanX) / TOFLOAT(ArcTanY))*10000.0) + 31415
				ELSE					;ARCTAN(X/Y) - PI	
					ArcTan4 = TOINT(FATAN(TOFLOAT(ArcTanX) / TOFLOAT(ArcTanY))*10000.0) - 31415
				ENDIF
			ENDIF
		ENDIF
	ENDIF
return ArcTan4
;--------------------------------------------------------------------
;[CHECK ANGLES] Checks the mechanical limits of the servos
CheckAngles:

  for LegIndex = 0 to 1
   ' HipYawAngle1(LegIndex)  = (HipYawAngle1(LegIndex)  min cHipYawMin1(LegIndex)) max cCoxaMax1(LegIndex)
   ' FemurAngle1(LegIndex) = (FemurAngle1(LegIndex) min cFemurMin1(LegIndex)) max cFemurMax1(LegIndex)
   ' TibiaAngle1(LegIndex) = (TibiaAngle1(LegIndex) min cTibiaMin1(LegIndex))  max cTibiaMax1(LegIndex)
  next

return

;--------------------------------------------------------------------
;[Servo Driver Start] Do conversions for new Angles to hservo locations in the start phase

ServoDriverStart:

	
  ;Update Right Legs
  ; BUGBUG : should we convert the offsets to their own table that has been pre multiplied?...
  #IFDEF UseReversedKnee
	LegIndex = cRightLeg'test right
		aswHipYawHServo(LegIndex) = (-HipYawAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipYawPin(LegIndex))	; Convert angle to HServo value
		aswHipRollHServo(LegIndex) = (HipRollAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipRollPin(LegIndex))
		aswFemurHServo(LegIndex) = (-FemurAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cFemurPin(LegIndex))
		aswTibiaHServo(LegIndex) = (-TibiaAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cTibiaPin(LegIndex))
		aswAnklePitchHServo(LegIndex) = (-AnklePitchAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnklePitchPin(LegIndex))
		aswAnkleRollHServo(LegIndex) = (AnkleRollAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnkleRollPin(LegIndex))
   			
  	;Update Left Legs
  	LegIndex = cLeftLeg
		aswHipYawHServo(LegIndex) = (-HipYawAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipYawPin(LegIndex))	; Convert angle to HServo value
    	aswHipRollHServo(LegIndex) = (-HipRollAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipRollPin(LegIndex))
    	aswFemurHServo(LegIndex) = (FemurAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cFemurPin(LegIndex))
    	aswTibiaHServo(LegIndex) = (TibiaAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cTibiaPin(LegIndex))
    	aswAnklePitchHServo(LegIndex) = (AnklePitchAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnklePitchPin(LegIndex))
    	aswAnkleRollHServo(LegIndex) = (-AnkleRollAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnkleRollPin(LegIndex))
  		;And the COG shifter servo:	
 		aswCogShifterHservo =	(-CogShifterAngle1 * StepsPerDegree ) / 10 + aServoOffsets(cCogShifterpin)
  #ELSE
  	LegIndex = cRightLeg
		aswHipYawHServo(LegIndex) = (-HipYawAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipYawPin(LegIndex))	; Convert angle to HServo value
		aswHipRollHServo(LegIndex) = (-HipRollAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipRollPin(LegIndex))
		aswFemurHServo(LegIndex) = (FemurAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cFemurPin(LegIndex))
		aswTibiaHServo(LegIndex) = (TibiaAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cTibiaPin(LegIndex))
		aswAnklePitchHServo(LegIndex) = (AnklePitchAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnklePitchPin(LegIndex))
		aswAnkleRollHServo(LegIndex) = (-AnkleRollAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnkleRollPin(LegIndex))
   			
  	;Update Left Legs
  	LegIndex = cLeftLeg
		aswHipYawHServo(LegIndex) = (HipYawAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipYawPin(LegIndex))	; Convert angle to HServo value
    	aswHipRollHServo(LegIndex) = (HipRollAngle1(LegIndex) * StepsPerDegree ) / 10  + aServoOffsets(cHipRollPin(LegIndex))
    	aswFemurHServo(LegIndex) = (-FemurAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cFemurPin(LegIndex))
    	aswTibiaHServo(LegIndex) = (-TibiaAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cTibiaPin(LegIndex))
    	aswAnklePitchHServo(LegIndex) = (-AnklePitchAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnklePitchPin(LegIndex))
    	aswAnkleRollHServo(LegIndex) = (AnkleRollAngle1(LegIndex) * StepsPerDegree ) / 10 + aServoOffsets(cAnkleRollPin(LegIndex))
  		;And the COG shifter servo:	
 		aswCogShifterHservo =	(CogShifterAngle1 * StepsPerDegree ) / 10 + aServoOffsets(cCogShifterpin)
  #ENDIF
  

return
  
;--------------------------------------------------------------------
;[Servo Driver Commit] Do the actual HSERVO in the commit phase
ServoDriverCommit:
  IF HexOn AND Prev_HexOn=0 THEN
    hservo [cRHipYawPin	\	aswHipYawHServo(cRightleg), |
			cRHipRollPin	\	aswHipRollHServo(cRightleg), |
			cRFemurPin	\	aswFemurHServo(cRightleg), |
			cRTibiaPin	\	aswTibiaHServo(cRightleg), |
			cRAnklePitchPin	\	aswAnklePitchHServo(cRightleg), |
			cRAnkleRollPin	\	aswAnkleRollHServo(cRightleg), |
			cLHipYawPin	\	aswHipYawHServo(cLeftLeg), |
			cLHipRollPin	\	aswHipRollHServo(cLeftLeg), |
			cLFemurPin	\	aswFemurHServo(cLeftLeg), |
			cLTibiaPin	\	aswTibiaHServo(cLeftLeg), |
			cLAnklePitchPin	\	aswAnklePitchHServo(cLeftLeg), |
			cLAnkleRollPin	\	aswAnkleRollHServo(cLeftLeg), |
			cCogShifterpin	\	aswCogShifterHservo	]
  ELSE 
	hservo [cRHipYawPin	\	aswHipYawHServo(cRightleg)		\	abs(HServoPos(cRHipYawPin) - aswHipYawHServo(cRightleg)) * 20 / SSCTime, |
			cRHipRollPin	\	aswHipRollHServo(cRightleg)	\	abs(HServoPos(cRHipRollPin) - aswHipRollHServo(cRightleg)) * 20 / SSCTime, |
			cRFemurPin	\	aswFemurHServo(cRightleg)		\	abs(HServoPos(cRFemurPin) - aswFemurHServo(cRightleg)) * 20 / SSCTime, |
			cRTibiaPin	\	aswTibiaHServo(cRightleg)		\	abs(HServoPos(cRTibiaPin) - aswTibiaHServo(cRightleg)) * 20 / SSCTime, |
			cRAnklePitchPin	\	aswAnklePitchHServo(cRightleg)		\	abs(HServoPos(cRAnklePitchPin) - aswAnklePitchHServo(cRightleg)) * 20 / SSCTime, |
			cRAnkleRollPin	\	aswAnkleRollHServo(cRightleg)\	abs(HServoPos(cRAnkleRollPin) - aswAnkleRollHServo(cRightleg)) * 20 / SSCTime, |
			cLHipYawPin	\	aswHipYawHServo(cLeftLeg)		\	abs(HServoPos(cLHipYawPin) - aswHipYawHServo(cLeftLeg)) * 20 / SSCTime, |
			cLHipRollPin	\	aswHipRollHServo(cLeftLeg)	\	abs(HServoPos(cLHipRollPin) - aswHipRollHServo(cLeftLeg)) * 20 / SSCTime, |
			cLFemurPin	\	aswFemurHServo(cLeftLeg)		\	abs(HServoPos(cLFemurPin) - aswFemurHServo(cLeftLeg)) * 20 / SSCTime, |
			cLTibiaPin	\	aswTibiaHServo(cLeftLeg)		\	abs(HServoPos(cLTibiaPin) - aswTibiaHServo(cLeftLeg)) * 20 / SSCTime, |
			cLAnklePitchPin	\	aswAnklePitchHServo(cLeftLeg)		\	abs(HServoPos(cLAnklePitchPin) - aswAnklePitchHServo(cLeftLeg)) * 20 / SSCTime, |
			cLAnkleRollPin	\	aswAnkleRollHServo(cLeftLeg)\	abs(HServoPos(cLAnkleRollPin) - aswAnkleRollHServo(cLeftLeg)) * 20 / SSCTime, |
			cCogShifterpin	\	aswCogShifterHservo			\	abs(HServoPos(cCogShifterpin) - aswCogShifterHservo) * 20 / SSCTime]
  ENDIF

#if 0	; only need if we use timer...
  PrevSSCTime = SSCTime
#endif  
return
;--------------------------------------------------------------------
;[FREE SERVOS] Frees all the servos
FreeServos
	hservo [cRHipYawPin	\	-30000, |
			cRHipRollPin	\	-30000, |
			cRFemurPin	\	-30000, |
			cRTibiaPin	\	-30000, |
			cRAnklePitchPin	\	-30000, |
			cRAnkleRollPin	\	-30000, |
			cLHipYawPin	\	-30000, |
			cLHipRollPin	\	-30000, |
			cLFemurPin	\	-30000, |
			cLTibiaPin	\	-30000, |
			cLAnklePitchPin	\	-30000, |
			cLAnkleRollPin	\	-30000, |
			cCogShifterpin	\	-30000]
	return

;==============================================================================
; Subroutine: ReadServoOffsets
; Will read in the zero points that wer last saved for the different servos
; that are part of this robot.  
;
;==============================================================================
ReadServoOffsets:
	readdm 31, [ bCSIn]
	readdm 32, [str aServoOffsets\32]	; We are storing words now.
	readdm 64, [str aServoOffsets(16)\32]
	bCSCalc = 0
	for Index = 0 to SERVOSAVECNT-1
		bCSCalc = bCSCalc + AServoOffsets(Index).lowbyte + AServoOffsets(Index).highbyte
	next
		
	if bCSCalc <> bCSIn then 
      	Sound cSound,[60\4000,100\5000, 60\4000]	' make some noise...
		if (wDebugLevel and DBG_LVL_NORMAL) then
			hserout ["--- Invalid Servo Offsets ---", 13,|
			" CS in: ", hex bCSIn, " CS calc: ", hex bCSCalc, 13]
		endif
		aServoOffsets = rep 0\SERVOSAVECNT
	endif

	return

;==============================================================================
;[Handle_Timer_asm] - Handle timer A overlfow in assembly language.  Currently only
;used for timings for debuging the speed of the code
;Now used to time how long since we received a message from the remote.
;this is important when we are in the NEW message mode, as we could be hung
;out with the robot walking and no new commands coming in.
;==============================================================================
#ifdef TMA
   BEGINASMSUB 
HANDLE_TIMERA_ASM 
	push.l 	er1                  ; first save away ER1 as we will mess with it. 
	bclr 	#6,@IRR1:8               ; clear the cooresponding bit in the interrupt pending mask 
	mov.l 	@LTIMERCNT:16,er1      ; Add 256 to our counter 
	add.l	#256,er1 
	mov.l 	er1, @LTIMERCNT:16 
	pop.l 	er1 
	rte 
	ENDASMSUB 
#else
   BEGINASMSUB 
HANDLE_TIMERB1_ASM 
	push.l 	er1                  ; first save away ER1 as we will mess with it. 
	bclr 	#5,@IRR2:8               ; clear the cooresponding bit in the interrupt pending mask 
	mov.l 	@LTIMERCNT:16,er1      ; Add 256 to our counter 
	add.l	#256,er1 
	mov.l 	er1, @LTIMERCNT:16 
	pop.l 	er1 
	rte 
	ENDASMSUB 
#endif
	return		; Put a basic statement before...

;==============================================================================
;[GetCurrentTime] - Gets the Timer value from our overflow counter as well as the TCA counter.  It
;                makes sure of consistancy. That is it is very posible that 
;                after we grabed the timers value it overflows, before we grab the other part
;                so we check to make sure it is correct and if necesary regrab things.
;==============================================================================
GetCurrentTime:
#ifdef TCA
	lCurrentTime = lTimerCnt + TCA
#else	
	lCurrentTime = lTimerCnt + TCB1
#endif	
	; handle wrap
	if lTimerCnt <> (lCurrentTime & 0xffffff00) then
#ifdef TCA	
		lCurrentTime = lTimerCnt + TCA
#else
	lCurrentTime = lTimerCnt + TCB1
#endif
	endif

	return lCurrentTime


