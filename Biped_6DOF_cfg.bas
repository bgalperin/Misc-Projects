;Project Lynxmotion Phoenix
;Description: Phoenix, configuration file.
;		All Hardware connections (excl controls) and body dimensions 
;		are configurated in this file. Can be used with V2.0 and above
;Configuration version: V2.0
;Date: 06-10-2009
;Programmer: Jeroen Janssen (aka Xan)
; 	ARC32 Version: Kurt Eckhardt(kurte)
;
;Hardware setup: ABB2 with ATOM 28 Pro, SSC32 V2, (See further for connections)
;
;NEW IN V2.0
;	- Conversion to Arc32
;
;--------------------------------------------------------------------
USEPS2			con	1		; Do we use the PS2?
;USEXBEE			con 1		; and/or do we use XBEE?
UseReversedKnee	con 1		

;--------------------------------------------------------------------
;[BB2 PIN NUMBERS]
cEyesPin		con P25
;--------------------------------------------------------------------
;[ARC32 PIN NUMBERS]
; Using group 1 and 3 for servos
; Some pins are changed!

#IFDEF UseReversedKnee
	cLHipYawPin		con P0	;Right Leg Hip Rotate
	cLHipRollPin	con P1	;Right Leg Hip Sway
	cLFemurPin 		con P7	;Right Leg Femur
	cLTibiaPin 		con P3	;Right Leg Knee
	cLAnklePitchPin		con P2	;Right Leg Ankle
	cLAnkleRollPin 	con P5	;Right Leg Ankle Sway
	
	cRHipYawPin		con P16	;Left Leg Hip Rotate
	cRHipRollPin	con P17	;Left Leg Hip Sway
	cRFemurPin 		con P23	;Left Leg Femur
	cRTibiaPin 		con P20	;Left Leg Knee
	cRAnklePitchPin		con P18	;Left Leg Ankle
	cRAnkleRollPin 	con P19	;Left Leg Ankle Sway
#ELSE
	cRHipYawPin		con P0	;Right Leg Hip Rotate
	cRHipRollPin	con P1	;Right Leg Hip Sway
	cRFemurPin 		con P7	;Right Leg Femur
	cRTibiaPin 		con P3	;Right Leg Knee
	cRAnklePitchPin		con P2	;Right Leg Ankle
	cRAnkleRollPin 	con P5	;Right Leg Ankle Sway
	
	cLHipYawPin		con P16	;Left Leg Hip Rotate
	cLHipRollPin	con P17	;Left Leg Hip Sway
	cLFemurPin 		con P23	;Left Leg Femur
	cLTibiaPin 		con P20	;Left Leg Knee
	cLAnklePitchPin		con P18	;Left Leg Ankle
	cLAnkleRollPin 	con P19	;Left Leg Ankle Sway
#ENDIF

cCogShifterpin	con P6
; 
cSound			con P31	; lets try output sound on plug in speaker
cStatusLED		con P44
cBattLED		con P45

;--------------------------------------------------------------------
;[MIN/MAX ANGLES]
cRHipYawMin1		con -900	;Mechanical limits of the Right Leg, decimals = 1
cRHipYawMax1		con 900
cRHipRollMin1		con -900	
cRHipRollMax1		con 900
cRFemurMin1			con -900
cRFemurMax1			con 900
cRTibiaMin1			con -900
cRTibiaMax1			con 900
cRAnklePitchMin1	con -900 
cRAnklePitchMax1	con 900
cRAnkleRollMin1		con -900
cRAnkleRollMax1		con 900

cLHipYawMin1		con -900	;Mechanical limits of the Right Leg, decimals = 1
cLHipYawMax1		con 900
cLHipRollMin1		con -900	
cLHipRollMax1		con 900
cLFemurMin1			con -900
cLFemurMax1			con 900
cLTibiaMin1			con -900
cLTibiaMax1			con 900
cLAnklePitchMin1	con -900
cLAnklePitchMax1	con 900
cLAnkleRollMin1		con -900
cLAnkleRollMax1		con 900

;--------------------------------------------------------------------
;[BODY DIMENSIONS]
cHipVertLength 	con 29
cCoxaLength  	con 29		;Length of the Coxa [mm]
cFemurLength 	con 75		;Length of the Femur [mm]
cTibiaLength 	con 57		;Lenght of the Tibia [mm]

cROffsetX 		con -45		;Distance X from center of the body to the Right Hip
cROffsetZ 		con 0		;Distance Z from center of the body to the Right Hip

cLOffsetX 		con 45		;Distance X from center of the body to the Left Hip
cLOffsetZ 		con 0		;Distance Z from center of the body to the Left Hip
;--------------------------------------------------------------------
;[Joint offsets]
cFemurOffset	con 300 ;450 (350)
cAnklePitchOffset	con 350 ;300 (350)
;--------------------------------------------------------------------
;[START POSITIONS FEET]
cRInitPosX 	con 0		;Start positions of the Right leg
cRInitPosY 	con 75 ;75 / 90
cRInitPosZ 	con 30 ; -10

cLInitPosX 	con 0		;Start positions of the Left leg
cLInitPosY 	con 75 ;75 / 90
cLInitPosZ 	con 30 ;-10
;--------------------------------------------------------------------
;[ICS, Internal Cog Shifter]
cSliderHalfMaxMinDeg 	con 245 ;Thats the 1/2 of max/min range for the slider servo = 24,5 deg
cSCBPX					con 18 	;Division factor for calculating the SCBodyPosX
cMaxOppositeTravel		con 20 	;A limitation for how far the oposite leg can travel while doing sidewalking
								;(when walking sideways to the right the left leg is the oposite)