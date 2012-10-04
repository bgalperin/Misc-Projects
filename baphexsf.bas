;------------------------------------
; Hex robot - Servo zero point finder
; 
; This version is written for the Atom Pro
; *** without an SSC-32 *** and uses HSERVO
; 
; It will store the values in the EEPROM of the BAP.
; Will emulate the SSC-32 in that we store the values out at memory
; locations 32-63.  However I will also store out a checksum at
; memory location 31, which I will compare against on the read to
; make sure the information looks valid.  
; Since we want a range of at least +- 8 degrees 
; so +-1900 HServo should be good (on Arc32 +- 9.5) degrees, which then implies
; that our increments would be +- 15 HSERVO units
;
; This program uses the keyboard on the PC to make the adjustments
; instructions are output on the terminal at 9600 baud on Bap28 or 38400 Bap40
;									
;MECHBRAT		con 1
ARC_PHOENIX		con 1

#ifdef TMB1		; this is defined for BAP40 and ARC-32
enablehserial
#ifdef ARC_PHOENIX
enablehservo2	; only if we are on phoenix... wish way to know arc32 vs bap40
#else
enablehservo
#endif
#else
enablehservo
#endif

;System variables
#ifdef MECHBRAT
NUMSERVOS		con	7
righthip		con p10 
rightknee		con p8 
rightankle		con p7 
lefthip			con p6 
leftknee		con p5 
leftankle		con p4 

Turret			con p11

ServoTable		bytetable RightHip,rightknee, rightankle,lefthip, leftknee, leftankle, Turret
_TT1			bytetable 	"Right Hip", 0, 
_TT2			bytetable 	"Right Knee ", 0
_TT3			bytetable 	"Right Ankle", 0
_TT4			bytetable 	"Left Hip", 0  
_TT5			bytetable 	"Left Knee", 0 
_TT6			bytetable 	"Left Ankle", 0
_TT7			bytetable 	"Turret", 0
#endif

#ifdef ARC_PHOENIX
NUMSERVOS		con	18
; Warning: Need to set for phoenix with Arc32...
;[SSC PIN NUMBERS]
cRRCoxaPin 		con P31	;Rear Right leg Hip Horizontal
cRRFemurPin 	con P30	;Rear Right leg Hip Vertical
cRRTibiaPin 	con P29	;Rear Right leg Knee

cRMCoxaPin 		con P28	;Middle Right leg Hip Horizontal
cRMFemurPin 	con P27	;Middle Right leg Hip Vertical
cRMTibiaPin 	con P26	;Middle Right leg Knee

cRFCoxaPin 		con P25	;Front Right leg Hip Horizontal
cRFFemurPin 	con P24	;Front Right leg Hip Vertical
cRFTibiaPin 	con P23	;Front Right leg Knee

cLRCoxaPin 		con P15	;Rear Left leg Hip Horizontal
cLRFemurPin 	con P14	;Rear Left leg Hip Vertical
cLRTibiaPin 	con P13	;Rear Left leg Knee

cLMCoxaPin 		con P12	;Middle Left leg Hip Horizontal
cLMFemurPin 	con P11	;Middle Left leg Hip Vertical
cLMTibiaPin 	con P10	;Middle Left leg Knee

cLFCoxaPin 		con P9	;Front Left leg Hip Horizontal
cLFFemurPin 	con P8	;Front Left leg Hip Vertical
cLFTibiaPin 	con P4	;Front Left leg Knee


ServoTable		bytetable 	cRRCoxaPin,cRRFemurPin,cRRTibiaPin,|
							cRMCoxaPin,cRMFemurPin,cRMTibiaPin,|
							cRFCoxaPin,cRFFemurPin,cRFTibiaPin,|
							cLRCoxaPin,cLRFemurPin,cLRTibiaPin,|
							cLMCoxaPin,cLMFemurPin,cLMTibiaPin, |
							cLFCoxaPin,cLFFemurPin,cLFTibiaPin
_TT1			bytetable 	"RR Hip Hor", 0 
_TT2			bytetable	"RR Hip Vert",0 
_TT3			bytetable	"RR Knee", 0 
_TT4			bytetable	"MR Hip Hor", 0
_TT5			bytetable	"MR Hip Vert",0
_TT6			bytetable	"MR Knee", 0
_TT7			bytetable	"FR Hip Hor", 0 
_TT8			bytetable	"FR Hip Vert",0
_TT9			bytetable	"FR Knee", 0
_TT10			bytetable	"RL Hip Hor", 0
_TT11			bytetable	"RL Hip Vert",0
_TT12			bytetable	"RL Knee", 0
_TT13			bytetable	"ML Hip Hor", 0
_TT14			bytetable	"ML Hip Vert",0
_TT15			bytetable	"ML Knee", 0
_TT16			bytetable	"FL Hip Hor", 0
_TT17			bytetable	"FL Hip Vert",0
_TT18			bytetable	"FL Knee", 0

#endif
 				
; We will keep a set of offsets  
SERVOSAVECNT	con	32				
aServoOffsets	var	sword(SERVOSAVECNT)		; Our new values - must take stored away values into account...

i				var byte		; temp counter
bTemp			var	byte(30);	; buffer to read stuff into
bChar			var	byte
pText			var	pointer
fChanged		var	bit
cChanges		var	byte
fSSCReboot		var	byte
bPlusMinusOffset var byte		; How much to offset when the + or - is hit

iServoTable	var byte			; Which servo table entry is current
bCurServo		var	byte		; Get the actual servo number to keep from having to double table lookup

; needs to be end of data make sure that 
; Warning: not for the faint of heart, but this table is trying to emulate being able to create
; a pointer table that looks something like:
; TT_TABLE	longtable @_TT1, @_TT2, 
; compiler should be able to do this, but currently does not allow you to put a pointer in...
goto AfterTable
#ifdef MECHBRAT
BEGINASMSUB
ASM{
TT_TABLE:
   .long (_TT1 + 0x20000)
   .long (_TT2 + 0x20000)
   .long (_TT3 + 0x20000)
   .long (_TT4 + 0x20000)
   .long (_TT5 + 0x20000)
   .long (_TT6 + 0x20000)
   .long (_TT7 + 0x20000)
}
ENDASMSUB
#endif

#ifdef ARC_PHOENIX
BEGINASMSUB
ASM{
TT_TABLE:
   .long (_TT1 + 0x20000)
   .long (_TT2 + 0x20000)
   .long (_TT3 + 0x20000)
   .long (_TT4 + 0x20000)
   .long (_TT5 + 0x20000)
   .long (_TT6 + 0x20000)
   .long (_TT7 + 0x20000)
   .long (_TT8 + 0x20000)
   .long (_TT9 + 0x20000)
   .long (_TT10 + 0x20000)
   .long (_TT11 + 0x20000)
   .long (_TT12 + 0x20000)
   .long (_TT13 + 0x20000)
   .long (_TT14 + 0x20000)
   .long (_TT15 + 0x20000)
   .long (_TT16 + 0x20000)
   .long (_TT17 + 0x20000)
   .long (_TT18 + 0x20000)
}
ENDASMSUB
#endif
AfterTable:

	sound 9,[50\3800, 50\4200, 40\4100]

;==============================================================================
; Complete initialization
;==============================================================================
	enable	; make sure interrupts are enabled
#ifdef TMB1
	SetHSerial H38400,H8DATABITS,HNOPARITY,H1STOPBITS
#endif	
AfterSSC_Reboot:
	iServoTable = 0
	bCurServo = ServoTable(iServoTable)
	aServoOffsets = rep 0\SERVOSAVECNT		; Use the rep so if size changes we should properly init

	; try to retrieve the offsets from EEPROM:
	
	pause 500	; give some time to setup
	
	gosub ReadServoOffsets

	pause 500
	
	gosub MoveAllServos

#ifdef TMB1
	hserout |
#else	
	serout s_out, i9600, |
#endif	
				["Use keyboard to adjust the servos", 13, |
				" +-  - to increment/decrement the current servo", 13, |
				" 0   - Will zero out that offset", 13, |
				" 1-9 - Set the increment default 50 Num * 10", 13, |
				" @   - Clear all offsets from SSC", 13, |
				" *   - to choose next servo or a-z to choose specific...", 13, |
				" <entr> - to save away the updated values", 13]

	iServoTable = 0
	bCurServo = ServoTable(iServoTable)
	gosub ShowWhichServo
	fChanged = 0
	fSSCReboot = 0;
	bPlusMinusOffset = 50
	cChanges = 0	; so we don't keep going and going on the keyapd...
;==============================================================================
; Main Loop
;==============================================================================
	
main:

	; warning serin only works when you are in it and the character(s) arrive.  So try
	; to be in the majority of the time.  For this case where we are simply doing
	; servo find center it will probably not be that much of an issue.
#ifdef TMB1
	hserin [bChar]	; we will wait for a character to be input
#else
	serin s_in, i9600, [bChar]	; we will wait for a character to be input
#endif	
	if bChar = "-" then
		if (aServoOffsets(bCurServo) > -2000) then
			; Make sure we did not move it out of range...
			if aServoOffsets(bCurServo) < (-2000 + bPlusMinusOffset) then
				aServoOffsets(bCurServo) = -2000
			else
				aServoOffsets(bCurServo) = aServoOffsets(bCurServo) - bPlusMinusOffset
			endif

			gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 128]	; move each servo to center point
			cChanges = cChanges + 1
			if cChanges > 5 then
#ifdef TMB1
				hserout [13, "  : ", sdec aServoOffsets(bCurServo), 13]
#else			
				serout s_out, i9600, [13, "  : ", sdec aServoOffsets(bCurServo), 13]
#endif				
				cChanges = 0
			endif

			fChanged = 1
   		else
    		sound 9,[150\3500]
 		endif 
  
	elseif bChar = "+" 
		if (aServoOffsets(bCurServo) < 2000) then
			; Make sure we did not move it out of range...
			if aServoOffsets(bCurServo) > (2000 - bPlusMinusOffset) then
				aServoOffsets(bCurServo) = 2000
			else
				aServoOffsets(bCurServo) = aServoOffsets(bCurServo) + bPlusMinusOffset
			endif
			
			gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 128]	; move each servo to center point
			fChanged = 1
			cChanges = cChanges + 1
			if cChanges > 5 then
#ifdef TMB1
				hserout [13, "  : ", sdec aServoOffsets(bCurServo), 13]
#else			
				serout s_out, i9600, [13, "  : ", sdec aServoOffsets(bCurServo), 13]
#endif				
				cChanges = 0
			endif
   		else
    		sound 9,[150\3500]
 		endif 
 		
 	elseif bChar = "0"
		aServoOffsets(bCurServo) = 0		; clear it back to logical zero
		gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 128]	; move each servo to center point
		fChanged = 1

	elseif (bChar >= "1") and (bChar <= "9")
		bPlusMinusOffset = (bChar - "0") * 10	; set the increment
		
 	elseif (bChar = "*") or (bChar >= "a" and bchar <= ("a"+NUMSERVOS-1)) or (bChar >= "A" and bchar <= ("A"+NUMSERVOS-1))
    	; first print out new Value...
    	if fChanged then
#ifdef TMB1
			hserout [13,"  : ", sdec aServoOffsets(bCurServo), 13]
#else    	
			serout s_out, i9600, [13,"  : ", sdec aServoOffsets(bCurServo), 13]
#endif			
	 		fChanged = 0
			cChanges = 0
		endif	 		
	 	if (bChar = "*") then
	  		iServoTable = iServoTable + 1
	  		if(iServoTable = NUMSERVOS) then
				iServoTable = 0
			endif
		elseif (bChar >= "a" and bchar <= ("a"+NUMSERVOS-1)) 
			iServoTable = bChar - "a"		
		else
			iServoTable = bChar - "A"		
		endif
		bCurServo = ServoTable(iServoTable)
  		gosub ShowWhichServo
  		
	elseif bchar = "@" 				; Clear all of the values from the SSC
		aServoOffsets = rep 0\SERVOSAVECNT
  		sound 9,[75\3200, 50\3300]
		gosub WriteServoOffsets[], fSSCReboot ; ok lets write out the updated values...
	
		
	elseif bChar and bchar <= 13 		; handle cr or lf or...
   		sound 9,[75\3200, 50\3300]
		gosub WriteServoOffsets[], fSSCReboot		; ok lets write out the updated values...
  	
	endif

	if 	fSSCReboot then 
#ifdef TMB1
		hserout["+++ Reset after values updated +++", 13]
#else	
		serout s_out, i9600, ["+++ Reset after values updated +++", 13]
#endif		
		goto AfterSSC_Reboot
	endif
	goto main

;==============================================================================
; subroutine: MoveAServo
; Calls Hservo to move all of the servos to their current zero location
;==============================================================================
iservo 	var byte
wNewPos	var	word
wTime	var	word
MoveAServo[iServo, wNewPos, wTime]

	hservo [iServo\wNewPos\wTime]
	hservowait[iServo]
	return
	
;==============================================================================
; subroutine: MoveServos
; Calls Hservo to move all of the servos to their current zero location
;==============================================================================
 				

MoveAllServos:
	for iServoTable = 0 to NUMSERVOS-1
		bCurServo = ServoTable(iServoTable)
		gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 0]	; move each servo to center point
	next

return

;==============================================================================
; Subroutine: ShowWhichServo
; Helps to let the user know which servo they are adjusting
; then it puts it to the current position...
;==============================================================================
ShowWhichServo:
	gosub MoveAServo[bCurServo, -1500, 128]	; move each servo to center point
	pause 128
	gosub MoveAServo[bCurServo, 1500, 128]	; move each servo to center point
	pause 128
	; move to current position which is 1500 + our offset...
	gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 128]	; move each servo to center point
	pause 128


	xor.l	er0, er0	; zero out the whole thing
	mov.b	@ISERVOTABLE, r0l
	shal.l	er0
	shal.l	er0				; multiply by 4 bytes per...
	mov.l	#TT_TABLE:24, er1
	add.l	er0, er1			; should have the address now
	mov.l	@er1, er0
	mov.l	er0, @PTEXT
#ifdef TMB1
	hserout["A"+iServoTable, ") ",str @pText\20\0, "(", dec bCurServo,  ") Center= ", sdec aServoOffsets(bCurServo), 13]
#else	
	serout s_out, i9600, ["A"+iServoTable, ") ",str @pText\20\0, "(", dec bCurServo,  ") Center= ", sdec aServoOffsets(bCurServo), 13]
#endif	
	return

;==============================================================================
; Subroutine: ReadServoOffsets
; Will read in the zero points that wer last saved for the different servos
; that are part of this robot.  
;
;==============================================================================
pT			var		pointer		; try using a pointer variable
cSOffsets	var		byte		; number of
bCSIn		var		byte
bCSCalc		var		byte		; calculated checksum
b			var		byte		; 

ReadServoOffsets:
	readdm 31, [ bCSIn]
	readdm 32, [str aServoOffsets\32]	; We are storing words now.
	readdm 64, [str aServoOffsets(16)\32]
	bCSCalc = 0
	for i = 0 to SERVOSAVECNT-1
		bCSCalc = bCSCalc + AServoOffsets(i).lowbyte + AServoOffsets(i).highbyte
	next
		
	if bCSCalc <> bCSIn then 
		aServoOffsets = rep 0\SERVOSAVECNT
#ifdef TMB1
		hserout ["--- Invalid Servo Offsets ---", 13,|
				"Cnt: ", dec cSOffsets, " CS in: ", hex bCSIn, " CS calc: ", hex bCSCalc, 13]
#else
		serout s_out, i9600, ["--- Invalid Servo Offsets ---", 13,|
				"Cnt: ", dec cSOffsets, " CS in: ", hex bCSIn, "CS calc: ", hex bCSCalc, 13]
#endif					
	endif

	for i = 0 to NUMSERVOS-1
		bCurServo = ServoTable(i)
		; Need to get to text name for servo
		xor.l	er0, er0	; zero out the whole thing
		mov.b	@I, r0l
		shal.l	er0
		shal.l	er0				; multiply by 4 bytes per...
		mov.l	#TT_TABLE:24, er1
		add.l	er0, er1			; should have the address now
		mov.l	@er1, er0
		mov.l	er0, @PTEXT
#ifdef TMB1
		hserout ["A"+I, ") ",str @pText\20\0, " = ", sdec AServoOffsets(bCurServo), 13]
#else			
		serout s_out, i9600, ["A"+I, ") ",str @pText\20\0, " = ", sdec AServoOffsets(bCurServo), 13]
#endif			
	next
	return
	
;==============================================================================
; Subroutine: WriteServoOffsets
; Will write out the current servo offsets to the EEPROM on the BAP29  
;
;==============================================================================
WriteServoOffsets:
	; OK First calculate the checksum
	; We will do something simple like add all of the bytes to each other.
	; bugbug:: If like bap28 can not write more than 32 bytes at a time so
	; will need to break up into smaller pieces for larger writes like
	; offset for 18 servos.
	bCSCalc = 0
#ifdef TMB1
	hserout ["+++ Write Servo OffsetsOffsets +++", 13]
#else	
	serout s_out, i9600, ["+++ Write Servo OffsetsOffsets +++", 13]
#endif				

	for i = 0 to SERVOSAVECNT-1
		bCSCalc = bCSCalc + AServoOffsets(i).lowbyte + AServoOffsets(i).highbyte
	next
	
	; Now write out checksum, followed by offset data
	writedm 31, [ bCSCalc]
	pause 10
	;writedm can only handle 32 bytes a time so will split to two writes
	writedm 32, [str aServoOffsets\32]		; bugbug should check to make sure that count
	pause 10
	writedm 64, [str aServoOffsets(16)\32]
	pause 10
	
	return 1 ; always jump to the start after this...

