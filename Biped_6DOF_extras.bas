;==============================================================================
; Kurts - Extras - for the phoenix on an Arc32
;==============================================================================

;==============================================================================
; Defines and Variables
;==============================================================================

_TM_szIn		var	byte(80)		; input prompt
_TM_iszIn		var	byte

_TM_bDumpMode	var	byte			; What mode are we in.  Simple stuff for now

_TM_wDumpStart	var	word			; what address to start at
_TM_wDumpCnt	var	word			; how many bytes to dump


abHdr		var	byte(6)
wAddr		var	word
ab			var	byte(100)	; Save room for two 32 byte blocks plus
bChkSum		var byte
bChkSumIn	var byte
bAck		var	byte
cSeqs		var	byte
iSeqDl		var byte
cbTotal		var	word
;i			var word


iSeq		var	byte
cbSeq		var	word
wSeqStart	var	word
cbLeft		var	word
wBuffStart	var	word
bDLReadState	var	byte
cbSSCWrite1stBlock 	var byte	; Use for 32 byte boundary alignment when we are outputting to the SSC-32

swServo		var	sword



;==============================================================================
; [TerminalMonitorInit] Init the terminal monitor
;==============================================================================
TerminalMonitorInit:
	; setup initial values for where to start dumping from and count
	_TM_wDumpStart = 0
	_TM_wDumpCnt = 32		; dump 

	gosub TerminalMonitor[1]:
	return


;==============================================================================
; [TerminalMonitor]Terminal monitor - Since on the Arc32 S_IN/S_OUT are on a hardware
; serial port, there is almost no overhead for me to monitor it for inputs.  as
; such might as well add in some stuff from external programs I have.  For now
; will add Sequence Downloader, EEPROM Dump, and set debug on and off...
;==============================================================================

fShowterminalPrompt var byte
TerminalMonitor[fShowTerminalPrompt]:
	if fShowTerminalPrompt then
_TM_ShowPrompt:
		hserout [13, 13, "Phoenix-Arc32 keyboard monitor",13,|
					 	"  D [<start addr>][<cnt>] - Dump EEPROM memory", 13, |
					 	"  O - Enter Servo Offset mode", 13, |
					 	"  S - Download sequence(s) - VB call only", 13, |
					 	"  T <n>] - Set or show debug Trace level", 13, |
					 	"  V <n> - View Sequence", 13, |
					 	" : "]
		fShowTerminalPrompt = 0					 
	endif
	
	; See if there is any keyboard input available.
	; Question: If I have some input should I wait until I get a CR?  Will for now
	mov.b	@_HSERINSTART, r0l
	mov.b	@_HSERINEND, r0h
	sub.b	r0h, r0l
	#ifdef USEXBEE
	mov.b	r0l, @BHSERINHASDATA
	
	if	(not bHSerinHasData) then _RXP_CHECKFORHEADER_TO
	#endif
;	hserstat HSERSTAT_INPUT_EMPTY, _TM_NoInput
	hserin [str _TM_szIn\80\13] 
	
	if _TM_szIn(0) = 13 then
		goto _TM_ShowPrompt

	elseif (_TM_szIn(0) = "t") or (_TM_szIn(0) = "T")	; The user wants to see or set the debug level
		if _TM_szIn(1) <> 13 then
			_TM_iszIn = 1

			gosub ExtractNum[], wDebugLevel
		endif
		hserout [13, "Current Debug Level: 	", dec wDebugLevel, "(", hex wDebugLevel, ")", 13]
	elseif (_TM_szIn(0) = "d") or (_TM_szIn(0) = "D")	; The user wants to Display EEPROM memory
		gosub _TM_ProcessEEPromDumpCmd		
		
	elseif (_TM_szIn(0) = "o") or (_TM_szIn(0) = "O")	; The user wants to update the servos offsets
		gosub _TM_ProcessServoOffsetsCmd
	elseif (_TM_szIn(0) = "s") or (_TM_szIn(0) = "S")	; The user wants to download a sequence or sequences...
		gosub _TM_ProcessDownloadSeqCmd
	elseif (_TM_szIn(0) = "v") or (_TM_szIn(0) = "V")	; The user wants to view a sequence.
		gosub _TM_ProcessViewSequenceCmd
	endif
		
	hserout [": "]
_TM_NoInput:
	return

;==============================================================================
;==============================================================================
; EEPROM - Dump code...
;==============================================================================
;0 - standard hex byte dump (h)
;1 - unsigned Decimal - words (w)
;2 - signed decimal words (s)
;------------------------------------------------------------------------------
_TM_ProcessEEPromDumpCmd:
	if _TM_szIn(1) = 13 then
		gosub DumpEEProm[_TM_wDumpStart, _TM_wDumpCnt]	
	elseif (_TM_szIn(1) = "h") or (_TM_szIn(1) = "H")
		_TM_bDumpMode = 0
	elseif (_TM_szIn(1) = "w") or (_TM_szIn(1) = "w")
		_TM_bDumpMode = 1
	elseif (_TM_szIn(1) = "s") or (_TM_szIn(1) = "S")
		_TM_bDumpMode = 2
	else
		_TM_iszIn = 1
		gosub ExtractNum[], _TM_wDumpStart
		if  _TM_szIn(_TM_iszIn) = "=" then
			; we are going to try to update the EEPROM!
			_TM_iszIn = _TM_iszIn + 1
			while _TM_szIn(_TM_iszIn) <> 13	; let walk through the items
				gosub ExtractNum[], _TM_wDumpCnt	; reuse this variable.
				; This pass of the code I will only update in bytes or words, but not signed
				if _TM_bDumpMode = 0 then
					Writedm _TM_wDumpStart,[_TM_wdumpCnt.lowbyte]
					_TM_wDumpStart = _TM_wDumpStart + 1
				else
					Writedm _TM_wDumpStart,[_TM_wdumpCnt.highbyte, _TM_wdumpCnt.lowbyte] ; Write 2 bytes
					_TM_wDumpStart = _TM_wDumpStart + 2
				endif
			wend	
		else
			if _TM_szIn(_TM_iszIn) = " " then
				; assume that we have a count specified here
				_TM_iszIn = _TM_iszIn + 1
				gosub ExtractNum[], _TM_wDumpCnt
			endif
			gosub DumpEEProm[_TM_wDumpStart, _TM_wDumpCnt]	
		endif
	endif		

	_TM_wDumpStart = _TM_wDumpStart + _TM_wDumpCnt ; assume we will start after the last write...
	return
	
							
;------------------------------------------------------------------------------
; Extract Number from input line
;------------------------------------------------------------------------------
wNum		var	word
fContinue	var	bit

ExtractNum:
	wNum = 0
	; skip any leading blanks...
	while (_TM_szIn(_TM_iszIn) = " ")
		_TM_iszIn = _TM_iszIn + 1
	wend

	; lets parse the strings to see if we have a start address or not...
	if (_TM_szIn(_TM_iszIn) = "0") and ((_TM_szIn(_TM_iszIn+1) = "x") or (_TM_szIn(_TM_iszIn+1) = "X")) then
		; hex number 
		_TM_iszIn = _TM_iszIn+2
		fContinue = 1
		do 
			if (_TM_szIn(_TM_iszIn) >= "0") and (_TM_szIn(_TM_iszIn) <= "9") then
				wNum = wNum * 16 + _TM_szIn(_TM_iszIn)-"0"
				_TM_iszIn = _TM_iszIn + 1
			elseif (_TM_szIn(_TM_iszIn) >= "a") and (_TM_szIn(_TM_iszIn) <= "f")
				wNum = wNum * 16 + _TM_szIn(_TM_iszIn)-"a"+10
				_TM_iszIn = _TM_iszIn + 1
			elseif (_TM_szIn(_TM_iszIn) >= "A") and (_TM_szIn(_TM_iszIn) <= "F")
				wNum = wNum * 16 + _TM_szIn(_TM_iszIn)-"A"+10
				_TM_iszIn = _TM_iszIn + 1
			else 
				fContinue = 0
			endif
		while(fcontinue)
	else
		; assume decimal number
		fContinue = 1
		do 
			if (_TM_szIn(_TM_iszIn) >= "0") and (_TM_szIn(_TM_iszIn) <= "9") then
				wNum = wNum * 10 + _TM_szIn(_TM_iszIn)-"0"
				_TM_iszIn = _TM_iszIn + 1
			else 
				fContinue = 0
			endif
		while(fcontinue)
	endif

	return wNum

;------------------------------------------------------------------------------
; DumpEEProm:
;------------------------------------------------------------------------------
wDumpStart	var	word
wDumpCnt	var	word
abDumpMem	var	byte(16)
iDump		var	byte
wB			var	word
sB			var sword
DumpEEProm[wDumpStart, wDumpCnt]:
	hserout ["Start Dump: ", hex wDumpStart, " Count: ", dec wDumpCnt, 13]
	while wDumpCnt > 0
		readdm	wDumpStart, [str abDumpMem\wDumpCnt max 16]		; read the bytes to dump max 16 at a time.
		
		hserout [hex4 wDumpStart\4,":"]
		
		; first dump the characters out in hex
		for iDump = 0 to 15
			if _TM_bDumpMode = 0 then
				if iDump < wDumpCnt then
					hserout [hex2 abDumpMem(iDump)\2, " "]
				else
					hserout ["   "]
				endif
			elseif ((iDump & 0x1) = 0)	; sort-of crap - but word size so only output every other byte
				if iDump < wDumpCnt then
					if _TM_bDumpMode = 1 then
						wB.highbyte = abDumpMem(iDump)
						wB.lowbyte = abDumpMem(iDump+1)
						hserout [dec5 wB\5, " "]
					else
						sB.highbyte = abDumpMem(iDump)
						sB.lowbyte = abDumpMem(iDump+1)
						if sB < 0 then
							hserout [sdec5 sB\5, " "]
						else
							hserout [sdec6 sB\6, " "]
						endif
					endif
				else
					hserout ["       "]
				endif
			endif
		next
		
		; then dump them out in ascii
		for iDump = 0 to ((wDumpCnt -1) max 15)
			if (abDumpMem(iDump) > 0x1f) and (abDumpMem(iDump) < 0x7f) then
				hserout [abDumpMem(iDump)]
			else
				hserout ["."]
			endif
		next
		
		hserout [13]	; output the cr to end the line
		; setup for the next line if any
		if wDumpCnt > 16 then
			wDumpCnt = wDumpCnt - 16
			wDumpStart = wDumpStart + 16
		else
			wDumpCnt = 0
		endif	
	wend	
	
	return	


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
; View Sequences command processing
; Warning I am going to reuse the variables I used to run sequences.  WIll need to extract these
; if I wish to have a standalone version of this stuff
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
_TM_ProcessViewSequenceCmd:
	if _TM_szIn(1) = 13 then
		_TM_wDumpStart = 0	; assume the first one.
	else
		_TM_iszIn = 1
		gosub ExtractNum[], _TM_wDumpStart
	endif
	
	; Now lets try to walk through the memory to dump out the data about the selected sequence.
	readdm ARC32_SSC_OFFSET + _TM_wDumpStart*2, [str wGPSeqPtr\2]
	; make sure there is a sequence...
	IF (wGPSeqPtr <> 0)  and (wGPSeqPtr <> 0xffff)	THEN
		; now lets get the header information, will skip sequence number
		readdm wGPSeqPtr+1,[bGPCntServos, bGPCntSteps]

		; now lets read in the pins
		wGPSeqPtr = wGPSeqPtr + 3 ; point to start of pin information.
		hserout ["Sequence: ", dec _TM_wDumpStart, " Cnt Servos: ", dec bGPCntServos, " Steps: ", dec bGPCntSteps, 13, |
				"Servos:        "]

		for bGPServoNum = 0 to bGPCntServos - 1
			readdm wGPSeqPtr, [abGPServoPins(bGPServoNum)]	; read in the pin, igore max value after
			hserout [dec4 abGPServoPins(bGPServoNum)\4, " "]
			wGPSeqPtr = wGPSeqPtr + 3
		next
		hserout [13]	; finish the servo line

		wGPSeqPtr = wGPSeqPtr + 2 ; skip over the N-1 time
		; now walk through the steps
		for bGPStepNum = 0 to bGPCntSteps-1 ;
			readdm wGPSeqPtr, [str ab\2*bGPCntServos, wGPStepTime.highbyte, wGPStepTime.lowByte] ; note did not change time bytes order ???
			hserout ["S: ", dec3 bGPStepNum\3, " ", dec4 wGPStepTime\4, " "]

			for bGPServoNum = 0 to bGPCntServos - 1
				; no longer converting the stored pulses to hservo so don't need any translation
				wB.highbyte = ab(bGPServoNum*2)
				wB.lowbyte = ab(bGPServoNum*2+1)
				hserout [dec4 wB\4, " "]
			next
		 	hserout [13]		
			wGPSeqPtr = wGPSeqPtr + 2*bGPCntServos + 2	; increment to the next sequence
		next
	endif

	return
						


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
;==================================================================================================
; Servo Offsets sub-section
;==================================================================================================
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

NUMSERVOS		con	13
;[SSC PIN NUMBERS]
; Actual pin number will now be in CFG file...
ServoTable		bytetable 	cRHipYawPin, cRHipRollPin, cRFemurPin,|
					cRTibiaPin, cRAnklePitchPin, cRAnkleRollPin,|
	  				cLHipYawPin, cLHipRollPin, cLFemurPin,|
					cLTibiaPin, cLAnklePitchPin, cLAnkleRollPin, cCogShifterpin
_TT1			bytetable 	"R Hip Yaw", 0 
_TT2			bytetable	"R Hip Roll",0 
_TT3			bytetable	"R Femur", 0 
_TT4			bytetable	"R Tibia", 0
_TT5			bytetable	"R Ankle Pitch",0
_TT6			bytetable	"R Ankle Roll", 0
_TT7			bytetable 	"L Hip Yaw", 0 
_TT8			bytetable	"L Hip Roll",0 
_TT9			bytetable	"L Femur", 0 
_TT10			bytetable	"L Tibia", 0
_TT11			bytetable	"L Ankle Pitch",0
_TT12			bytetable	"L Ankle Roll", 0
_TT13			bytetable	"COG Shifter", 0
_TT14			bytetable	"Vacant",0
_TT15			bytetable	"Vacant", 0
_TT16			bytetable	"Vacant", 0
_TT17			bytetable	"Vacant",0
_TT18			bytetable	"Vacant", 0
 				
; We will keep a set of offsets  
MAXOFFSET		con	12000					; what is the maximum offset we will allow - was 2000
;SERVOSAVECNT	con	32				
;aServoOffsets	var	sword(SERVOSAVECNT)		; This is up in phoenix_v32.bas..

bTemp			var	byte(30);	; buffer to read stuff into
bChar			var	byte
pText			var	pointer
fChanged		var	bit
cChanges		var	byte
fSSCReboot		var	byte
bPlusMinusOffset var byte		; How much to offset when the + or - is hit

iServoTable	var byte			; Which servo table entry is current
bCurServo		var	byte		; Get the actual servo number to keep from having to double table lookup
;pT			var		pointer		; try using a pointer variable - Defined in xbee
cSOffsets	var		byte		; number of
;b			var		byte		; Defined in XBEE

; needs to be end of data make sure that 
; Warning: not for the faint of heart, but this table is trying to emulate being able to create
; a pointer table that looks something like:
; TT_TABLE	longtable @_TT1, @_TT2, 
; compiler should be able to do this, but currently does not allow you to put a pointer in...
goto AfterTable
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
AfterTable:

;==============================================================================
; Complete initialization
;==============================================================================
_TM_ProcessServoOffsetsCmd:

AfterSSC_Reboot:
	iServoTable = 0
	bCurServo = ServoTable(iServoTable)
	aServoOffsets = rep 0\SERVOSAVECNT		; Use the rep so if size changes we should properly init

	; try to retrieve the offsets from EEPROM:
	
	pause 500	; give some time to setup
	
	gosub ReadServoOffsets

	; Now lets display the offsets for the different servos
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
		hserout ["A"+I, ") ",str @pText\20\0, " = ", sdec AServoOffsets(bCurServo), 13]
	next


	pause 500
	
	gosub MoveAllServos

	hserout [	"Use keyboard to adjust the servos", 13, |
				" +-  - to increment/decrement the current servo", 13, |
				" 0   - Will zero out that offset", 13, |
				" 1-9 - Set the increment default 50 Num * 10", 13, |
				" @   - Clear all offsets from SSC", 13, |
				" *   - to choose next servo or a-z to choose specific...", 13, |
				" <$> - Return to main program", 13, |
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
	
_TMSO_main:

	; warning serin only works when you are in it and the character(s) arrive.  So try
	; to be in the majority of the time.  For this case where we are simply doing
	; servo find center it will probably not be that much of an issue.
#ifdef TMB1
	hserin [bChar]	; we will wait for a character to be input
#else
	serin s_in, i9600, [bChar]	; we will wait for a character to be input
#endif	
	if bChar = "$" then	; Escape... Return to main loop
		return
	elseif bChar = "-" 
		if (aServoOffsets(bCurServo) > -MAXOFFSET) then
			; Make sure we did not move it out of range...
			if aServoOffsets(bCurServo) < (-MAXOFFSET + bPlusMinusOffset) then
				aServoOffsets(bCurServo) = -MAXOFFSET
			else
				aServoOffsets(bCurServo) = aServoOffsets(bCurServo) - bPlusMinusOffset
			endif

			gosub MoveAServo[bCurServo, aServoOffsets(bCurServo), 128]	; move each servo to center point
			cChanges = cChanges + 1
			if cChanges > 5 then
				hserout [13, "  : ", sdec aServoOffsets(bCurServo), 13]
				cChanges = 0
			endif

			fChanged = 1
   		else
    		sound cSound,[150\3500]
 		endif 
  
	elseif bChar = "+" 
		if (aServoOffsets(bCurServo) < MAXOFFSET) then
			; Make sure we did not move it out of range...
			if aServoOffsets(bCurServo) > (MAXOFFSET - bPlusMinusOffset) then
				aServoOffsets(bCurServo) = MAXOFFSET
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
    		sound cSound,[150\3500]
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
  		sound cSound,[75\3200, 50\3300]
		gosub WriteServoOffsets[], fSSCReboot ; ok lets write out the updated values...
	
		
	elseif bChar and bchar <= 13 		; handle cr or lf or...
   		sound cSound,[75\3200, 50\3300]
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
	goto _TMSO_main

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

; Now up in the main file...
	
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

;##################################################################################################
;------------------------------------------------------------------------------
; Download sequences.
;------------------------------------------------------------------------------ 

;==============================================================================
; [_TM_ProcessDownloadSeqCmd]
;==============================================================================
_TM_ProcessDownloadSeqCmd:
	; The VB app will pass us an ascii string with the number of sequences and cbTotal as ascii.
	; need to extract that from the command line...
	_TM_iszIn = 1
	gosub ExtractNum[], cSeqs		; extract the count of sequences
	gosub ExtractNum[], cbTotal		; likewise the expected total number of bytes

	; do a little validation to make sure the user did not enter this by accident...
	; need at least one sequence
	if (cSeqs = 0) or (cSeqs > 20) or (cbTotal < (cSeqs*12)) or (cbTotal > 16383) then
		; either no steps or too many or not enough bytes for even 1 servo and step per sequence
		; or obviously won't fit in EEPROM, then probably garabage, so bail before we do anything
#ifdef TMB1
		hserout ["*** Download Command Error ***", 13]
#else		
		serout s_out, i38400, ["*** Download Command Error ***", 13]
#endif
		return
	endif			
	; Calculate return number that the other will understand as an ack
	; should add some more validation here
	bchksum = cSeqs + cbTotal.highbyte + cbTotal.lowbyte
	bAck = !bChksum
#ifdef TMB1
	hserout	[bAck]	' send an Ack back to the caller.
#else
	serout s_out, i38400,[bAck]	' send an Ack back to the caller.
#endif	
	gosub ClearSeqPtrs	; clear the sequence pointers

	; now we need to loop through all of the sequences that are supposed to be downloaded
	for iSeqDl = 0 to cSeqs -1
		; We should now get a header for the next sequnce
		; BUGBUG should probably put a timeout in here...
#ifdef TMB1		
		hserin [str abHdr\6]	' read in 5 byte header + 
#else
		serin s_in, i38400, [str abHdr\6]	' read in 5 byte header + 
#endif		
		bChkSum = abHdr(0)+abHdr(1)+abHdr(2)+abHdr(3)+abHdr(4)
	
		; we have hopefully a valid header...
		bAck = !bChksum		' invert what we received to send back		
#ifdef TMB1
		hserout	[bAck]	' send an Ack back to the caller.
#else
		serout s_out, i38400,[bAck]	' send an Ack back to the caller.
#endif	
		iSeq = abHdr(0)

		wSeqStart.highbyte = abHdr(1)	; Where it was in EEPROM file. 
		wSeqStart.lowByte = abHdr(2)	
		cbSeq.highbyte = abHdr(3)		; This sequence size 
		cbSeq.lowByte = abHdr(4)	

		cbLeft = cbSeq
		wBuffStart = 0
		bDLReadState = 0

		while cbLeft >= 32
			; also put in timeout...
#ifdef TMB1
			hserin [str ab(wBuffStart)\32, bChkSumIn]	' Read in next 32 bytes
#else
			toggle P5		; debug this stuff...
			serin s_in, i38400, [str ab(wBuffStart)\32, bChkSumIn]	' Read in next 32 bytes
#endif
			bChkSum = 0

			for i = 0 to 31
				bChkSum = bchkSum + ab(wBuffStart+i)
			next
			if bChksum <> bChksumIn then
				goto _TMDL_Error
			endif

			gosub WriteBlockToSSC[bDLReadState]			; Do our call off
			bDLReadState = 1							; not our first call						

			bAck = !bChksum		' invert what we received to send back		
#ifdef TMB1
			hserout	[bAck]	' send an Ack back to the caller.
#else
			serout s_out, i38400,[bAck]	' send an Ack back to the caller.
#endif	
			cbLeft = cbLeft - 32
		wend
		if cbLeft then
#ifdef TMB1
			hserin [str ab(wBuffStart)\cbLeft, bChkSumIn]	' read in the last remaining bytes of this sequence
#else
			toggle P6		; debug this stuff...
			serin s_in, i38400,  [str ab(wBuffStart)\cbLeft, bChkSumIn]	' read in the last remaining bytes of this sequence
#endif			
			bChkSum = 0
			for i = 0 to cbLeft-1
				bChkSum = bchkSum + ab(wBuffStart+i)
			next
			if bChksum <> bChksumIn then
				goto _TMDL_Error
				toggle p4
			endif
			
			; now lets finish writing out the sequence.
			cbLeft = cbLeft + wBuffStart		; this should be the total number of bytes left to output
			if cbLeft >= 32 then
				gosub WriteBlockToSSC[1]		; Do a full write...
				cbLeft = cbLeft - 32
			endif
			
			
			bAck = !bChksum		' invert what we received to send back		
#ifdef TMB1
			hserout	[bAck]	' send an Ack back to the caller.
#else
			serout s_out, i38400,[bAck]	' send an Ack back to the caller.
#endif	
		
		endif
		; After we finish receiving a sequence we can now process it.  At the end of that echo one last Ack to
		; let the other side know that we completed it...
		gosub WriteBlockToSSC[2]			; Do possibly a partial write and any cleanup that may be necessary.
#ifdef TMB1
		hserout	[bAck]	' Output the final Ack to the user to say we finished writing out this sequence
#else
		serout s_out, i38400, [bAck]	' final ack
#endif		

	next		; loop through all of the 
	return		; go back to the main input section...
	
; Handle a timeout 1 second should be plenty of time for VB app to send us data!!!
_TMPDL_TO:
#ifdef TMB1
	hserout ["*** Sequence Download Failed: Timeout ***", 13]
#else
	serout s_out, i38400, ["*** Sequence Download Failed: Timeout ***", 13]
#endif	
	return
	
_TMDL_Error:
#ifdef TMB1
	hserout ["*** Sequence Download Failed: Checksum Error ***", 13]
#else
	serout s_out, i38400, ["*** Sequence Download Failed: Checksum Error ***", 13]
#endif	

	return	

	
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; 				ARC 32 version
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	
ARC32_SSC_OFFSET	con	0x400		; we will offset saving all of the SSC-32 by this amount
;===============================================================================
; ClearSeqPtrs
;===============================================================================
ClearSeqPtrs:	; clear the sequence pointers
	writedm ARC32_SSC_OFFSET,[rep 0\20]						; Clear 10 pointers.
	return


;===============================================================================
; WriteBlockToSSC - Version 2 - Arc32 version
;		before we start writing out to the SSC, we will receive one block and write
; 		it.  The SSC is more efficient if it writes on 32 byte boundaries, so
;		we will try to align all of our writes.   This implies the first buffer
;		we will only write part of it out, 
;		
;===============================================================================
bState	var		byte	; What state of the output are we in
;						; 0 - First output - need to output pointer, plus part or read up to page boundary
;						; 1 - Main state - output 32 bytes, copy rest down to start...
;						; 2 - output final part...
WriteBlockToSSC[bState]:
	; will need to write a max of 32 bytes at a time preferably starting at 32 bit boundry...
	; We will use the memory address that was passed us...
;	wSeqStart.highbyte = abHdr(1)	; Where it was in EEPROM file. 
;	cbSeq.highbyte = abHdr(3)		; This sequence size 

	; first output the address to the start the of SSC
	if bState = 0 then ; we received first buffer.
		; first write out pointer to the data for this sequence.  We will offset the 
		; address by ARC32_SSC_OFFSET to save room for other stuff 
		wSeqStart = wSeqStart + ARC32_SSC_OFFSET
		; first output the address to the start the of SSC - Note since this is all internal
		; we may as well offset the value and save it in our own number ordering...
		writedm ARC32_SSC_OFFSET+ (iSeq*2), [str wSeqStart\2]	; saves in our number system
		pause 10

		; The SSC-32 likes to do writes starting at 32 byte boundaries.  So calculate how many of
		; our first 32 bytes we will output in this call.  This value will also be used then by the
		; receive function to know how far off in our buffer to offset to do the next read...
		cbSSCWrite1stBlock = 32 - (wSeqStart & 0x1f)	; this is the offset into the 

		; ok let write the first part out
		writedm wSeqStart, [str ab\cbSSCWrite1stBlock]		; write out the first block 

		; now the gunk, to make the code easy I am going to copy the rest of the buffer down that we did not output yet...
		if cbSSCWrite1stBlock <> 32 then
			for i = cbSSCWrite1stBlock to 31 
				ab(i-cbSSCWrite1stBlock) = ab(i)	; copy the parts down from the end to the start
			next
		endif		
	
		wSeqStart = (wSeqStart + 32) & 0xffe0				; setup to the start of the next sequence

		wBuffStart = 32 - cbSSCWrite1stBlock					; This is where in the buffer we should setup to do the next read...

	elseif bState = 1	; then normal 32 byte outputs.

		writedm wSeqStart, [str ab\32]						; Output the block

		; now junk again copy down the part of our last read that was not output
		; On the secondary reads, we started the read at the buffer location of
		; ab(32-cbSSCWrite1stBlock) so we will have 32-cbSSCWrite1stBlock bytes that go into our
		; buffer after what we wrote...
		if cbSSCWrite1stBlock <> 32 then
			for i = 0 to 31-cbSSCWrite1stBlock 
				ab(i) = ab(32+i)	; copy the parts down from the beginning of the next block...
			next
		endif		
		wSeqStart = wSeqStart + 32
		toggle p6
	else	; bstate = 2, do the last buffer...
		if cbLeft then
			pause 10
			writedm wSeqStart, [str ab\cbLeft]						; Output the block
		endif
	endif	
	return

