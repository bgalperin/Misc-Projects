#ifdef USEXBEE	; Are we using XBEE control

;Project Lynxmotion Phoenix
;Description: Phoenix, control file.
;		The control input subroutine for the phoenix software is placed in this file.
;		Can be used with V2.0 and above
;Configuration version: V1.0
;Date: 08-01-2009
;Programmer: Jeroen Janssen (aka Xan)
;Special Thanks to: Kurt (aka Kurte) Assembly
;
;Hardware setup: DIY XBee
;
;NEW IN V1.0
;	- First Release
;
;
;DIY CONTROLS:
;	- Left Stick	(WalkMode) Body Height / Rotate
;					(Translate Mode) Body Height / Rotate body Y	
;					(Rotate Mode) Body Height / Rotate body Y
;					(Single leg Mode) Move Tars Y	
;
;	- Right Stick	(WalkMode) Walk/Strafe
;			 		(Translate Mode) Translate body X/Z
;					(Rotate Mode) Rotate body X/Z
;					(Single leg Mode) Move Tars X/Z
;
; 	- Left Slider	Speed
;	- Right Slider	Leg Lift Height
;
;	- A				Walk Mode
;	- B				Translate Mode
;	- C				Rotate Mode
;	- D				Single Leg Mode
;	- E				Balance Mode on/off
;
;	- 0				Turn on/off the bot
;
;	- 1-8			(Walk mode) Switch gaits
;	- 1-6			(Single leg mode) Switch legs
;
;====================================================================
;[DEBUG]
;DEBUG_XBEE con 1
;DEBUG_VERBOSE con 1
;DEBUG_ENTERLEAVE con 1
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; From XBEE_TASERIAL_DEFINES
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;==============================================================================
; [XBee definitions]
;==============================================================================
;
; We are rolling our own communication protocol between multiple XBees, one in
; the receiver (this one) and one in each robot.  We may also setup a PC based
; program that we can use to monitor things...
; Packet format:
; 		Packet Header: <Packet Type><Checksum><SerialNumber><cbExtra>
;
; Packet Types:
;[Packets sent from Remote to Robot]
XBEE_TRANS_READY		con	0x01	; Transmitter is ready for requests.
	; Optional Word to use in ATDL command
XBEE_TRANS_NOTREADY		con 0x02	; Transmitter is exiting transmitting on the sent DL
	; No Extra bytes.
XBEE_TRANS_DATA			con	0x03	; Data Packet from Transmitter to Robot*
	; Packet data described below.  Will only be sent when the robot sends
	; the remote a XBEE_RECV_REQ_DATA packet and we must return sequence number
XBEE_TRANS_NEW			con	0x04	; New Data Available
	; No extra data.  Will only be sent when we are in NEW only mode
XBEE_ENTER_SSC_MODE		con	0x05	; The controller is letting robot know to enter SSC echo mode
	; while in this mode the robot will try to be a pass through to the robot. This code assumes
	; cSSC_IN/cSSC_OUT.  The robot should probalby send a XBEE_SSC_MODE_EXITED when it decides
	; to leave this mode...	
	; When packet is received, fPacketEnterSSCMode will be set to TRUE.  Handlers should probalby
	; get robot to a good state and then call XBeeHandleSSCMode, which will return when some exit
	; condition is reached.  Start of with $$<CR> command as to signal exit
XBEE_REQ_SN_NI			con 0x06	; Request the serial number and NI string

;[Packets sent from Robot to remote]
XBEE_RECV_REQ_DATA		con	0x80	; Request Data Packet*
	; No extra bytes, but we do pass a serial number that we expect back 
	; from Remote in the XBEE_TRANS_DATA_PACKET
XBEE_RECV_REQ_NEW		con	0x81	; Request Only New data
	; No Extra bytes, but if <serialNumber> = 0, then we are not
	; expecting the XBEE_TRANS_NEW packet and will query whenever we
	; want to know current values.
	; <serialNumber> <> 0 goes into New only mode and we will typically 
	; wait until Remote says it has new data before asking for data.
	; In new mode, the remote may choose to choose a threshold of how big a change
	; needs to be before sending the XBEE_TRANS_NEW value.
XBEE_RECV_NEW_THRESH	con 0x82	; Set new Data thresholds
	; currently not implemented
XBEE_RECV_DISP_VAL		con	0x83	; Display a value on line 2
	; If <cbExtra> is  0 then we will display the number contained in <SerialNumber> 
	; If not zero, then it is a count of bytes in a string to display.
XBEE_PLAY_SOUND			con	0x84	; Will make sounds on the remote...
	;	<cbExtra> - 2 bytes per sound: Duration <0-255>, Sound: <Freq/25> to make fit in byte...
XBEE_SSC_MODE_EXITED	con	0x85	; a message sent back to the controller when
	; it has left SSC-mode.
XBEE_SEND_SN_NI_DATA	con 0x86	; Response for REQ_SN_NI - will return
	; 4 bytes - SNH
	; 4 bytes - SNL
	; up to 20 bytes(probably 14) for NI

;[XBEE_TRANS_DATA] - has XBEEPACKETSIZE extra bytes
;	0 - Buttons High
;	1 - Buttons Low
; 	2 - Right Joystick L/R
;	3 - Right Joystick U/D
;	4 - Left Joystick L/R
;	5 - Left Joystick U/D
; 	6 - Right Slider
;	7 - Left Slider

PKT_BTNLOW		con 0				; Low Buttons 0-7
PKT_BTNHI		con	1				; High buttons 8-F
PKT_RJOYLR		con	2				; Right Joystick Up/Down
PKT_RJOYUD		con	3				; Right joystick left/Right
PKT_LJOYLR		con	4				; Left joystick Left/Right
PKT_LJOYUD		con	5				; Left joystick Up/Down
PKT_RSLIDER		con	6				; right slider
PKT_LSLIDER		con	7				; Left slider
PKT_RPOT		con 8				; Right potmeter
PKT_LPOT		con 9				; Left potmeter

#ifdef USEPS2
bWhichControl	var 	byte		; Which input device are we currently using?
WC_UNKNOWN		con		0			; Not sure yet
WC_PS2			con 	1			; Using PS2 to control robot
WC_XBEE			con		2			; we are currently using the XBee to control the robot
#endif


;==============================================================================
; [Public Variables] that may be used outside of the helper file 
; Will also describe helper functions that are provided that use
; or return these values.
;==============================================================================

;------------------------------------------------------------------------------
; [InitXbee] - Intializes the XBee - This function assumes that
; 	gosub InitXBee
; 	cXBEE_OUT - is the output pin for the Xbee
; 	cXBEE_IN  - Is the input pin
;	cXBEE_RTS - is the flow control pin.  If using sparkfun regulated explorer
;			be careful that this is P6 or P7 as for lower voltage.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; [ReceiveXbeePacket] - Main workhorse, it does all of the work to ask for new
;				data if appropriate or returns last packet if in new mode.  it
;				will also handle several other packets.  If in new only packet mode
;				and we have not received a packet in awhile, we may deside to force
;				asking for a packet.  If so fPacketForced will be true.  If forced
;				and not valid then maybe something is wrong on the other side so probably
;				go into a safe mode.  If Forced we may want to check to see if our new
;				data matches our old data. If not we may want to retell the Remote that we
;				want new packet only mode.
;	
;				Note: we wont ask for data from the remote until we have received a Transmit ready
;				packet.  This is what fTransReadyRecvd variable is for.
;	gosub ReceiveXbeePacket
;
; On return if fPacketValid is true then the array bPacket Contains valid data.  Other
; flags are described below
;------------------------------------------------------------------------------
XBEEPACKETSIZE		con 10			; define the size of my standard pacekt.
bPacket				var	byte(XBEEPACKETSIZE)		; This is the packet of data we will send to the robot.

fPacketValid		var	bit			; Is the data valid
fPacketForced		var	bit			; did we force a packet
fPacketTimeout		var	bit			; Did a timeout happen
fSendOnlyNewMode	var	bit			; Are we in the mode that we will only receive data when it is new?
fPacketEnterSSCMode	var	bit			; Did we receive packet to enter SSC mode?
fTransReadyRecvd	var	bit			; Are we waiting for transmit ready?

CPACKETTIMEOUTMAX	con	100			; Need to define per program as our loops may take long or short...
cPacketTimeouts		var	word		; See how many timeouts we get...


;==============================================================================
; XBEE standard strings to save memory - by Sharin
;==============================================================================
_XBEE_PPP_STR	bytetable	"+++"		; 3 bytes long
_XBEE_ATCN_STR	bytetable	"ATCN",13	; 5 byte

;------------------------------------------------------------------------------
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; Variables from XBEE_TASERIAL_SUPPORT
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

;--------------------------------------------------------------------
;[DIY XBee Controller Variables]
_bPacketNum			var	byte		; A packet number...
_bPacketHeader		var	byte(4)		; Have a 4 byte header to read in first
_bTemp				var	byte(10)	; for reading in different strings...
_b
_bChkSumIn			var	byte
_lCurrentTimeT		var	long		; 
_lTimerLastPacket	var	long		; the timer value when we received the last packet
_lTimerLastRequest	var	long		; what was the timer when we last requested data?
_lTimeDiffMS		var long		; calculated time difference

_fNewPacketAvail	var	bit			; Is there a new packet available?
_fPacketValidPrev	var	bit			; The previous valid...
_fReqDataPacketSent	var	bit			; has a request been sent since we last received one?
_fReqDataForced		var	bit			; Was our request forced by a timeout?
_tas_i				var	byte
_tas_b				var	byte		; 
_cbRead				var	byte		; how many bytes did we read?


CXBEE_BAUD				con H62500				; Non-standard baud rate for xbee but...

; Also define some timeouts.  Allow users to override
CXBEEPACKETTIMEOUTMS con 500					; how long to wait for packet after we send request
CXBEEFORCEREQMS		con	1000					; if nothing in 1 second force a request...
CXBEETIMEOUTRECVMS	con	2000					; 2 seconds if we receive nothing

;==============================================================================
; If XBEE is on HSERIAL, then define some more stuff...
;==============================================================================
ENABLEHSERIAL2
bHSerinHasData			var	byte		; 

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



;--------------------------------------------------------------------
;[CONSTANTS]
WalkMode		con 0
TranslateMode	con 1
RotateMode		con 2
SingleLegMode	con 3
GPPlayerMode	con 4

;--------------------------------------------------------------------

;[DIY XBee Controller Variables]
abButtonsPrev 			var Byte(2)		; The state of the buttons in previous packet
iNumButton			var	byte		; which button is pressed. Only used in a few places.
fGPSequenceRun		var	bit			; Was a sequence started?

fPacketChanged		var bit			; Something change in the packet
bPacketPrev			var	byte(XBEEPACKETSIZE)

;i					var	byte
b					var	byte		; 
pT					var	pointer		; temporary pointer

CtrlMoveInp			var sword		; Input for smooth control movement (ex joystick, pot value), using sword for beeing on the safe side
CtrlMoveOut			var sword		; 
CtrlDivider			var nib			;

RotateFunction		var nib			; For setting different options/functions in RotateMode
LockFunction		var bit			; If True the actual function are freezed
FunctionIsChanged	var bit 		; Update the DIY remote with new text when this variable are True
LeftJoyUDmode		var bit


; Feedback messages - First byte is the count
_WALKMODE			bytetable	7,  "Walking"
_TANSLATEMODE		bytetable	14, "Body Translate"
_ROTATEMODE			bytetable	11, "Body Rotate"
_SINGLELEG			bytetable	10, "Single Leg"
_BALANCEON			bytetable	10, "Balance On"
_BALANCEOFF			bytetable	11, "Balance Off"
_GPSEQMODE			bytetable	12, "Run Sequence"
_GPSEQSTART			bytetable	14, "Start Sequence"
_GPSEQCOMPLETE		bytetable	 9, "Completed"
_GPSEQDISABLED		bytetable	12, "Seq Disabled"
_GPSEQNOTDEF		bytetable	15, "Seq Not defined"
_LJOYUDwalk			bytetable	11, "LJOYUD walk"
_LJOYUDtrans		bytetable	12, "LJOYUD trans"
_SetRotOffset		bytetable	12, "SetRotOffset"
_LockON				bytetable	 7, "Lock ON"
_LockOFF			bytetable	 8, "Lock OFF"

; Feedback - Gait names *** Warning: make sure counts match as I hop through the strings"
_GATENAMES			bytetable	8, 	"Ripple 6",|
								9, 	"Ripple 12",|
								12,	"Quadripple 9",|
								8, 	"Tripod 4",|
								8, 	"Tripod 6",|
								8, 	"Tripod 8",|
								7, 	"Wave 12",|
								7, 	"Wave 18"
; Other strings...
_EER_SSC1			bytetable	"EER -" ; 5 characters
_EER_SSC2			bytetable	";2",13 ; 3

; Define a sound to send back...
_GPSNDERR			bytetable 100, 5000/25,80, 4000/25] ' play it a little different...

;
; Each of the packets will be defined throughout this file...
;
bXBeeControlMode			var byte
;--------------------------------------------------------------------
InitController:
#ifdef DEBUG_ENTERLEAVE
	hserout ["Enter: Init Controller", 13]
#endif	

#ifdef USEPS2
	; We allow both the PS2 and XBee to control us so if both are defined call
	; the renamed PS2 controller Init code...
	bWhichControl = WC_UNKNOWN		; start off not knowning which controller we will use

	gosub InitPS2Controller
#endif	

	gosub InitXBee
   
 	bXBeeControlMode = WalkMode
	fGPSequenceRun = 0		; make sure it is init...
#ifdef DEBUG_ENTERLEAVE
	hserout ["Exit: Init Controller", 13]
#endif	
 
return

;==============================================================================
; [ControlInput] - If Xbee and PS2 are defined this function will try to decide
;			which one should be in control.  If neither is in contorl it will
;			call both and in the PS2 case it will use it, if the user hits the
;			start button on the PS2... 
;			
;==============================================================================

#ifdef USEPS2
ControlInput:
	; if we are not currently dfined as XBEE in control then call of to PS2 code
	if bWhichControl <> WC_XBEE	 then
		gosub ControlPS2Input
		
		if HexOn then
			bWhichControl = WC_PS2
		else
			bWhichControl = WC_UNKNOWN
		endif
	endif
	
	; if not PS2 control, we will call XBEE function
	if bWhichControl <> WC_PS2 then 
		gosub ControlXBeeInput

		; If we made contact with XBee will use that...
		if fTransReadyRecvd then
			bWhichControl = WC_XBEE
		else
			bWhichControl = WC_UNKNOWN
		endif
	endif		

	return
#endif


;==============================================================================
; [ControlXBeeInput] - if both controllers
; [ControlInput] - This function will try to receive a packet of information
; 		from the remote control over XBee.
;
; the data in a standard packet is arranged in the following byte order:
;	0 - Buttons High
;	1 - Buttons Low
; 	2 - Right Joystick L/R
;	3 - Right Joystick U/D
;	4 - Left Joystick L/R
;	5 - Left Joystick U/D
; 	6 - Right Slider
;	7 - Left Slider
;==============================================================================
#ifdef USEPS2
ControlXBeeInput:
#else	
ControlInput:
#endif
#ifdef DEBUG_ENTERLEAVE
	hserout ["Enter: Control Input", 13]
#endif	
	; Not sure the best place to test this, but if we ran a sequence and now
	; it says it is not running, let the user know this.
	if fGPSequenceRun and (GPStart = 0) then
		fGPSequenceRun = 0		; clear out the data...
		gosub XBeeOutputString[@_GPSEQCOMPLETE]
		GOSUB XBeeResetPacketTimeout ; sets _lTimerLastPacket
		
	endif

	; First lets try getting a packet from the XBEE
	gosub ReceiveXBeePacket
	; See if we have a valid packet to process
	if fPacketValid  then
		fPacketChanged = 0	; don't need to worry about slop 
		for i = 0 to XBEEPACKETSIZE-1
			if (bPacket(i) <> bPacketPrev(i)) then
				fPacketChanged = 1
				bPacketPrev(i) = bPacket(i)
			endif
		next
		
		if fPacketChanged  then
			if fPacketForced then
				gosub SendXbeeNewDataOnlyPacket[1]
			endif
#ifdef DEBUG_XBEE
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout [bin8 bPacket(PKT_BTNHI)\8, bin8 bPacket(PKT_BTNLOW)\8, " "]
				for i = 2 to 7
					hserout [dec bPacket(i)," "]
				next
				hserout[13] 
			endif
#endif

		endif

		; OK lets try "0" button for Start. 
		IF bPacket(PKT_BTNLOW).bit0 and (abButtonsPrev(0).bit0 = 0) THEN	;Start Button (0 on keypad) test
			IF(HexOn) THEN
				'Turn off
				Sound cSound,[100\5000,80\4500,60\4000]
				BodyPosX = 0
				BodyPosY = 10 'biped test|1
				BodyPosZ = 0
				BodyRotX1 = 0
				BodyRotY1 = 0
				BodyRotZ1 = 0
				TravelLengthX = 0
				TravelLengthZ = 0
				TravelRotationY = 0
				
				SSCTime = 600
				GOSUB ServoDriverStart
				GOSUB ServoDriverCommit
				HexOn = 0
				low cStatusLED
#ifdef DEBUG_MAIN				
				hserout ["Cycles: ", dec cCycleTime, " Sum:", dec lsumCycleTime, 13]
#endif				
			ELSE
				'Turn on
				Sound cSound,[60\4000,80\4500,100\5000]
				SSCTime = 200
				HexOn = 1	
				high cStatusLED
#ifdef DEBUG_MAIN				
			  	lsumCycleTime = 0 ;;; bugbug
	  			cCycleTime = 0
#endif
			ENDIF
		ENDIF	
		
		IF HexOn THEN
			IF bPacket(PKT_BTNHI).bit2 and (abButtonsPrev(1).bit2 = 0) THEN		;A Button Walk Mode
				sound cSound, [50\4000]
				bXBeeControlMode = WalkMode
				gosub XBeeOutputString[@_WALKMODE]
			ENDIF

			IF bPacket(PKT_BTNHI).bit3 and (abButtonsPrev(1).bit3 = 0) THEN		;B Button Translate Mode
				sound cSound, [50\4000]
				bXBeeControlMode = TranslateMode
				gosub XBeeOutputString[@_TANSLATEMODE]
			ENDIF
      
			IF bPacket(PKT_BTNHI).bit4 and (abButtonsPrev(1).bit4 = 0) THEN		;C Button Rotate Mode
				sound cSound, [50\4000]
				bXBeeControlMode = RotateMode
				gosub XBeeOutputString[@_ROTATEMODE]
			ENDIF
      
			IF bPacket(PKT_BTNHI).bit5 and (abButtonsPrev(1).bit5 = 0) THEN		;D Button Single Leg Mode
				sound cSound, [50\4000]
				IF SelectedLeg=255 THEN ; none
					SelectedLeg=cRF
				ELSEIF bXBeeControlMode=SingleLegMode ;Double press to turn all legs down
					SelectedLeg=255 ; none
				ENDIF
				bXBeeControlMode=SingleLegMode        
				gosub XBeeOutputString[@_SINGLELEG]
			ENDIF

			IF bPacket(PKT_BTNHI).bit6 and (abButtonsPrev(1).bit6 = 0) THEN		; E Button Balance Mode on/of
				IF BalanceMode = 0 THEN
					BalanceMode = 1
					sound cSound,[100\4000, 50\8000]
					gosub XBeeOutputString[@_BALANCEON]
				ELSE
					BalanceMode = 0
					sound cSound,[250\3000]
					gosub XBeeOutputString[@_BALANCEOFF]
				ENDIF  
			ENDIF   

			IF bPacket(PKT_BTNHI).bit7 and (abButtonsPrev(1).bit7 = 0) THEN		; F Button GP Player Mode Mode on/off
      			if GPEnable THEN ;F Button GP Player Mode Mode on/off -- SSC supports this mode
					gosub XBeeOutputString[@_GPSEQMODE]
					sound cSound, [50\4000]
					
					BodyPosX = 0
					BodyPosZ = 0
					BodyRotX1 = 0
					BodyRotY1 = 0
					BodyRotZ1 = 0
					TravelLengthX = 0
					TravelLengthZ = 0
					TravelRotationY = 0
					
					SelectedLeg=255 ; none
					SLHold=0
			
					bXBeeControlMode = GPPlayerMode
				else
					gosub XBeeOutputString[@_GPSEQDISABLED]
					sound cSound, [50\4000]
				endif
			ENDIF

			; Hack there are several places that use the 1-N buttons to select a number as an index
			; so lets convert our bitmap of which key may be pressed to a number...
			; BUGBUG:: There is probably a cleaner way to convert...
			iNumButton = 0		; assume no button
			if ((bPacket(PKT_BTNLOW) & 0xFE) or (bPacket(PKT_BTNHI) & 0x03)) and ((abButtonsPrev(0) & 0xFE) = 0) and ((abButtonsPrev(1) & 0x03) = 0) then
				b = bPacket(PKT_BTNLOW) & 0xfe
				if b then
					while not b.bit0
						b = b >> 1
						iNumButton = iNumButton + 1
					wend
				else
					b = bPacket(PKT_BTNHI)
					iNumButton = 8		; start off at bit 8
					while not b.bit0
						b = b >> 1
						iNumButton = iNumButton + 1
					wend
				endif
			endif
			; BUGBUG:: we are using all keys now, may want to reserve some...		
			;Switch gait
			; We will do slightly different here than the RC version as we have a bit per button
			IF bXBeeControlMode=WalkMode and iNumButton  and (iNumButton <= 8) THEN	;1-8 Button Gait select	  
				IF ABS(TravelLengthX)<cTravelDeadZone & ABS(TravelLengthZ)<cTravelDeadZone & ABS(TravelRotationY*2)<cTravelDeadZone THEN
				
					;Switch Gait type
					GaitType = 0 'iNumButton-1 'currently only one gait method
					Sound cSound,[50\4000]
					GOSUB GaitSelect
					; For the heck do in assembly!
					pT = @_GATENAMES	; Point to the first of the paint names
					mov.l	@PT:16, er0					; pointer to our strings
					mov.b	@GAITTYPE, r1l				; r1l has the gait type
					beq		_CI_GS_ENDLOOP:8			; passed zero in so done
_CI_GS_LOOP:					
					mov.b	@er0+, r2l					; get the count of bytes in this string and increment to next spot
					extu.w	r2
					extu.l	er2							; convert to 32 bits
					add.l	er2, er0					; and increment to the next string
					dec.b	r1l							; decrement our count
					bne		_CI_GS_LOOP:8				; done
_CI_GS_ENDLOOP:
					mov.l	er0, @PT					; save away our generated pointer					
					; And tell the remote the name for the selected gate
#ifdef DEBUG_XBEE
					if (wDebugLevel and DBG_LVL_CONTROL) then
						hserout ["GT - Addrs: ", hex @_GATENAMES, 13]
						hserout ["GT: ", dec GaitType, " ", hex pT, "=", hex @pt, 13]
					endif
#endif					
					
					gosub XBeeOutputString[pT]
					
				ENDIF
			ENDIF

			;Switch single leg
			SingelLegModeOn = FALSE
			IF bXBeeControlMode=SingleLegMode THEN	
				SingelLegModeOn = TRUE  
				IF iNumButton>=1 & iNumButton<=2 THEN
					Sound cSound,[50\4000]
					SelectedLeg = iNumButton-1
					SLHold=0
				ENDIF
			
				IF iNumButton = 9  THEN ;Switch Directcontrol
			  		sound cSound, [50\4000]
			  		SLHold = SLHold^1 	;Toggle SLHold
				ENDIF
			ELSEIF bXBeeControlMode=Walkmode
				SelectedLeg=255	; none
				SLHold=0
			'ELSE
				'SelectedLeg=255	; none
			ENDIF

			;Body Height
			BodyPosY = (bPacket(PKT_LPOT) / 2)
			
			;Leg lift height - Right slider has value 0-255 translate to 30-93
			LegLiftHeight = 15 + bPacket(PKT_RSLIDER)/5
			
			;**********************************************************************************
			;Walk mode	
			;**********************************************************************************			
			IF (bXBeeControlMode=WalkMode) THEN 		
				
				IF ABS(bPacket(PKT_RJOYLR)-128) < TLDivFactor THEN ;Due to the Walking inhibit function (IF NOT Walking), for avoiding to large deadzone on the stick:	
				  	TravelLengthX = -(bPacket(PKT_RJOYLR) - 128)
				ELSE
					TravelLengthX = -(bPacket(PKT_RJOYLR) - 128)/4
					IF TravelLengthX > 0 THEN
						TravelLengthX = TravelLengthX + TLDivFactor - (TLDivFactor/4)
					ELSE
						TravelLengthX = TravelLengthX - TLDivFactor + (TLDivFactor/4)
					ENDIF
				ENDIF
				
				TravelLengthZ = -(bPacket(PKT_RJOYUD) - 128)
				IF ABS(bPacket(PKT_LJOYLR)-128) < TLDivFactor THEN
				  	TravelRotationY = -(bPacket(PKT_LJOYLR) - 128)
				ELSE
				  	TravelRotationY = -(bPacket(PKT_LJOYLR) - 128)/6
				  	IF TravelRotationY >0 THEN
				    	TravelRotationY = TravelRotationY + TLDivFactor -(TLDivFactor/6)
				  	ELSE
				    	TravelRotationY = TravelRotationY - TLDivFactor +(TLDivFactor/6)
				  	ENDIF
				ENDIF
				
				;Calculate walking time delay
				'InputTimeDelay = 128 - (ABS((bPacket(PKT_RJOYLR)-128)) MIN ABS(((bPacket(PKT_RJOYUD)-128)))) MIN ABS(((bPacket(PKT_LJOYLR)-128))) + (128 -(bPacket(PKT_LSLIDER))/2)
				InputTimeDelay = 255-bPacket(PKT_LSLIDER) 'test

			ENDIF
			
			;**********************************************************************************
			;Body translate	
			;**********************************************************************************	
			IF (bXBeeControlMode=TranslateMode) THEN	
				BodyPosX = (bPacket(PKT_RJOYLR)-128)/2
				BodyPosZ = (bPacket(PKT_RJOYUD)-128)/2
				BodyRotY1 = (bPacket(PKT_LJOYLR)-128)*2
			ENDIF		
			
			;**********************************************************************************
			;Body rotate	
			;**********************************************************************************	
			IF (bXBeeControlMode=RotateMode) THEN	
				IF iNumButton  and (iNumButton <=3) THEN
				  RotateFunction = iNumButton -1
				  FunctionIsChanged = TRUE
				  Sound P9,[20\4000]
				ENDIF
				IF (iNumButton = 9) THEN ; Toogle LockFunction
				  LockFunction = !LockFunction
				  IF LockFunction THEN
				    gosub XBeeOutputString[@_LockON]
				    Sound P9,[20\1500]
				  ELSE
				    gosub XBeeOutputString[@_LockOFF]
				    Sound P9,[20\2500]
				  ENDIF 
				ENDIF
				GOSUB BranchRotateFunction
				
				GOSUB SmoothControl [((bPacket(PKT_RJOYUD)-128)*2), BodyRotX1, 2], BodyRotX1
				GOSUB SmoothControl [((bPacket(PKT_LJOYLR)-128)*2), BodyRotY1, 2], BodyRotY1
				GOSUB SmoothControl [(-(bPacket(PKT_RJOYLR)-128)*2), BodyRotZ1, 2], BodyRotZ1
				;Calculate walking time delay
				InputTimeDelay = 128 - (ABS((bPacket(PKT_LJOYUD)-128)))  + (128 -(bPacket(PKT_LSLIDER))/2)

			ENDIF
			
			;**********************************************************************************
			;Single Leg Mode
			;**********************************************************************************
			IF (bXBeeControlMode = SingleLegMode) THEN
				SLLegX = (bPacket(PKT_RJOYLR)-128)
				SLLegZ = -(bPacket(PKT_RJOYUD)-128)
				SLLegY = -(bPacket(PKT_LJOYUD)-128) ;XP more logic single leg control ;)
				
				
			ENDIF			
			;***********************************************************************************
			IF (bXBeeControlMode = GPPlayerMode & iNumButton>=1 & iNumButton<=9 ) THEN	;1-9 Button Play GP Seq
				IF (GPStart = 0) THEN
					GPSEQ = iNumButton-1
				ENDIF

				readdm ARC32_SSC_OFFSET + GPSEQ*2, [str wGPSeqPtr\2]

				IF (wGPSeqPtr = 0)  or (wGPSeqPtr = 0xffff)	THEN
					gosub XBeeOutputString[@_GPSEQNOTDEF]  ; that sequence was not defined...
					gosub XBeePlaySounds[@_GPSNDERR, 4];	// BUGBUG: maybe should pass number of notes instead?
				ELSE
					; let user know that sequence was started
					gosub XBeeOutputString[@_GPSEQSTART]  ; Tell user sequence started.
					fGPSequenceRun = 1 ; remember that ran one...
					GPStart = 1
				ENDIF
			ENDIF
			
			

		ENDIF
	  
		abButtonsPrev(0) = bPacket(PKT_BTNLOW)
		abButtonsPrev(1) = bPacket(PKT_BTNHI)
	else
		; Not a valid packet - we should go to a turned off state as to not walk into things!
		IF(HexOn and (fPacketForced or fPacketEnterSSCMode)) THEN
			'Turn off
			Sound cSound,[100\5000,80\4500,100\5000,60\4000] ' play it a little different...
			BodyPosX = 0
			BodyPosY = 0
			BodyPosZ = 0
			BodyRotX1 = 0
			BodyRotY1 = 0
			BodyRotZ1 = 0
			TravelLengthX = 0
			TravelLengthZ = 0
			TravelRotationY = 0
			
			SSCTime = 600
			GOSUB ServoDriverStart
			GOSUB ServoDriverCommit
			HexOn = 0
		endif
	endif

#ifdef DEBUG_ENTERLEAVE
	hserout ["Exit: Control Input", 13]
#endif	

return
;-----------------------------------------------------------------------------------
;Branch RotateFunction,
;
BranchRotateFunction:
  BRANCH RotateFunction,[LjoyUDWalk, LjoyUDTranslate, SetRotOffset]
  
  LjoyUDWalk:
    TravelLengthZ = -(bPacket(PKT_LJOYUD) - 128)
  	IF FunctionIsChanged THEN 'Update DIY, send text string:
  	  gosub XBeeOutputString[@_LJOYUDwalk]
  	  FunctionIsChanged = FALSE
  	ENDIF
  return
  
  LjoyUDTranslate:
    GOSUB SmoothControl [((bPacket(PKT_LJOYUD)-128)/2), BodyPosZ, 2], BodyPosZ
  	IF FunctionIsChanged THEN 'Update DIY, send text string:
  	  gosub XBeeOutputString[@_LJOYUDtrans]
  	  FunctionIsChanged = FALSE
  	ENDIF
  return
  
  SetRotOffset:				
	IF LockFunction = 0 THEN	
	  BodyRotOffsetZ = (bPacket(PKT_LJOYUD) - 128)
	  BodyRotOffsetY = (bPacket(PKT_RPOT) - 128)
	ENDIF
  	IF FunctionIsChanged THEN 'Update DIY, send text string:
  	  gosub XBeeOutputString[@_SetRotOffset]
  	  FunctionIsChanged = FALSE
  	ENDIF
return
;--------------------------------------------------------------------
; SmoothControl
; This function makes the body rotation and translation much smoother while walking
; 
SmoothControl [CtrlMoveInp, CtrlMoveOut, CtrlDivider] 
  IF Walking THEN
    IF (CtrlMoveOut < (CtrlMoveInp - 4)) THEN
      CtrlMoveOut = CtrlMoveOut + ABS((CtrlMoveOut - CtrlMoveInp)/CtrlDivider)
    ELSEIF (CtrlMoveOut > (CtrlMoveInp + 4))
      CtrlMoveOut = CtrlMoveOut - ABS((CtrlMoveOut - CtrlMoveInp)/CtrlDivider)
    ELSE
      CtrlMoveOut = CtrlMoveInp
    ENDIF
  ELSE
    CtrlMoveOut = CtrlMoveInp
  ENDIF
  
return CtrlMoveOut
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; From XBEE_TASERIAL_SUPPORT
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;==============================================================================
; XBEE - Support
;==============================================================================

;==============================================================================
; [WaitHSerout2Complete] - This simple helper function waits until the HSersial
; 							output buffer is empty before continuing...
; BUGBUG: Rolling our own as the hserstat reset the processor
;==============================================================================
WaitHSerout2Complete:
	nop						; transisition to assembly language.
_WTC_LOOP:	
	mov.b	@_HSEROUT2START,r0l
	mov.b	@_HSEROUT2END,r0h
	cmp.b	r0l,r0h
	bne		_WTC_LOOP:8

	;hserstat 5, WaitTransmitComplete				; wait for all output to go out...	
	return



;==============================================================================
; [InitXbee] - Initialize the XBEE for use with DIY support
;==============================================================================
InitXBee:
#ifdef DEBUG_ENTERLEAVE
	hserout ["Enter: Init XBee", 13]
#endif	
	sethserial2 cXBEE_BAUD, H8DATABITS,HNOPARITY,H1STOPBITS

	pause 20							; have to have a guard time to get into Command sequence
#ifdef cXBEE_RTS			; RTS line optional for us with HSERIAL 
	hserout2 [str _XBEE_PPP_STR\3]
	gosub WaitHSerout2Complete
	pause 20							; have to wait a bit again
	hserout2 [	"ATD6 1",13,|			; turn on flow control
				str _XBEE_ATCN_STR\5]				; exit command mode
	low cXBEE_RTS						; make sure RTS is output and input starts off enabled...

#endif ; cXBEE_RTS
	pause 10	; need to wait to exit command mode...

	cPacketTimeouts = 0
	fTransReadyRecvd = 0
	_fPacketValidPrev = 0
	fPacketEnterSSCMode = 0   
	_fReqDataPacketSent = 0
	_fReqDataForced = 0			;
    gosub ClearInputBuffer		; make sure we toss everything out of our buffer and init the RTS pin

#ifdef DEBUG_ENTERLEAVE
	hserout ["Exit: Init Controller", 13]
#endif	
 
return

;==============================================================================
; [XBeeOutputVal[bXbeeVal]] - Output a value back to the device.  Works for XBee
; 		by sending Byte value back to the DIY remote to display.
; Parmameters:
;		bXbeeVal - Value to send back
;==============================================================================
bXbeeVal	var	byte
XBeeOutputVal[bXbeeVal]:
	gosub SendXBeePacket[XBEE_RECV_DISP_VAL, bXbeeVal, 0, 0]		
return

;==============================================================================
; [XBeeOutputString] - Output a string back to the device.  Works for XBee
; 		by outputing the string back to the DIY remote to display.
; Parmameters:
;		pString - Pointer to string.  First byte contains the length
;==============================================================================
pString	var	pointer
XBeeOutputString[pString]:
	; BUGBUG:: Will not work for zero count, but what the heck.
	; First we need to get the count a compute the checksum - for the heck of it will use assembly...
	mov.l	@PSTRING:16, er0		; get the pointer value into ero
	mov.b	@er0+, r1l				; Get the count into R1l - start of the checksum
	mov.l	er0, @PSTRING:16		; Update pointer value to be after the count byte.
	mov.b	r1l, @_TAS_B:16			; save away count to pass to the serial output...

	gosub SendXBeePacket[XBEE_RECV_DISP_VAL, 0,  _tas_b, pString]		; Send Data to remote (CmdType, ChkSum, Packet Number, CB extra data)


#ifdef DEBUG_XBEE
	if (wDebugLevel and DBG_LVL_CONTROL) then
		hserout ["XOS: ", dec _tas_b, ":", str @pString\_tas_b, 13]
	endif
#endif

return

;==============================================================================
; [XBeePlaySounds] - Sends the buffer of souncs back to the remote to play
; Parmameters:
;		pSnds - Pointer to the sounds
;		cbSnds - Size of the buffer
;==============================================================================
; Too bad I don't have real macros to save space...
pSnds 	var pointer
cbSnds	var	byte
XBeePlaySounds[pSnds, cbSnds]:
	gosub SendXBeePacket[XBEE_PLAY_SOUND, 0,  cbSnds, pSnds]		; Send Data to remote (CmdType, ChkSum, Packet Number, CB extra data)
	return
	
;==============================================================================
; [XbeeRTSAllowInput] - This function enables or disables the RTS line for the XBEE
; This is only used for the XBEE on HSERIAL mode as the TASerial has the RTS stuff
; built in and we don't want to throw away characters...
;==============================================================================
fRTSEnable	var	byte
XbeeRTSAllowInput[fRTSEnable]
#ifdef cXBEE_RTS
	if fRTSEnable then
		low cXBEE_RTS
	else
		high cXBEE_RTS
	endif
#endif
return
;==============================================================================
; [SetXbeeDL] - Set the XBee DL to the specified word that is passed
; BUGBUG: sample function, need to clean up.
;==============================================================================
wNewDL	var	word
SetXBeeDL[wNewDL]:
#ifdef DEBUG_VERBOSE
	;bugbug;;; debug
	hserout ["Set XBEE DL: ", hex wNewDL, 13]
#endif

	pause 20							; have to have a guard time to get into Command sequence
	hserout2 [str _XBEE_PPP_STR\3]
	gosub WaitHSerout2Complete
	pause 20							; have to wait a bit again

	hserout2 ["ATDL ",hex wNewDL, 13, |	; Set the New DL
			 str _XBEE_ATCN_STR\5]					; Exit command mode
  	pause 10
	return

;==============================================================================
; [GetXbeeDL] - Retrieve the XBee DL and return it as a Word
;==============================================================================
GetXBeeDL:
	gosub GetXBeeHexVal["D","L",0x3], wNewDL
	return wNewDL


;==============================================================================
; [GetXbeeHexVal] - Retrieves one of the XBee values that return some hex value
;	this includes: DL, MY, SH, SL...
;	_c1 and _c2 are the two bytes of the command for my "M", "Y"
;==============================================================================
_c1			var	byte	; First char of command name "M"
_c2 		var byte	; 2nd char of Command        "Y"
_SSAction 	var byte 	; Two bits low says .bit0 = Enter command mode .bit1 exit command mode
						; so we can chain up a few of these if we want...
_lVal		var	long						
GetXBeeHexVal[_c1, _c2, _SSAction]:

#ifdef DEBUG_VERBOSE
	;bugbug;;; debug
	hserout ["Get XBEE HEX VaL: (", _c1, _c2, ")",13]
#endif
	_lVal = -1	; error condition

	if _SSAction.bit0 then
		gosub ClearInputBuffer
		pause 20							; have to have a guard time to get into Command sequence
		hserout2 [str _XBEE_PPP_STR\3]
		gosub WaitHSerout2Complete
		pause 20							; have to wait a bit again

		; need to process the OK for the +++
		hserin2 20000, _GXHV_TO,	[str _bTemp\10\13]	; first OK for +++
	endif
	
	; Now output our command	
	hserout2 ["AT", _c1, _c2,13]

	; Get our value now
	hserin2 20000, _GXHV_TO, [hex _lVal]		; get the value
	
	if _SSAction.bit1 then
		hserout2 [str _XBEE_ATCN_STR\5]							; Exit command mode
		hserin2 20000, _GXHV_TO,	[str _bTemp\10\13]	; and retrieve the OK
	endif
_GXHV_TO:	

	return _lVal


;==============================================================================
; [GetXbeeStringVal] - Retrieves one of the XBee values that return some string
;	this includes: NI
;	_c1 and _c2 are the two bytes of the command for my "M", "Y"
;==============================================================================
_pbSVal		var	pointer
		Sound cSound,[100\4400]
_pbT		var	pointer
_cT			var	byte
_cbSVal		var	byte
_GXSV_cbRet var byte
_GXSV_i		var	byte
GetXBeeStringVal[_c1, _c2, _SSAction, _pbSVal, _cbSVal]:

#ifdef DEBUG_VERBOSE
	;bugbug;;; debug
	hserout ["GXBEE SVaL: (", _c1, _c2, ")",13]
#endif
	_GXSV_cbRet = 0
	
	if _SSAction.bit0 then
		gosub ClearInputBuffer
		pause 20							; have to have a guard time to get into Command sequence
		hserout2 [str _XBEE_PPP_STR\3]
		gosub WaitHSerout2Complete
		pause 20							; have to wait a bit again

		; need to process the OK for the +++
		hserin2 20000, _GXSV_TO,	[str _bTemp\10\13]	; first OK for 
	endif
	
	; Now output our command	
	hserout2 ["AT", _c1, _c2,13]

	; Get our value now
	; BUGBUG: Make sure the pointer passed in is to a byte level...
	_pbsVal.highword = 0x2		
	hserin2 20000, _GXSV_TO, [str @_pbSVal\_cbSVal\13]		; get the value
	
	; Need to see if we read all of the value or not, ie did we get a CR
	_pbT = _pbSVal
	_cT = _cbSVal - 1

	for _GXSV_cbRet = 0 to _cT			
		if @_pbT = 13 then _GXSV_CR		; Our count should be OK at this point-
		_pbT = _pbT + 1
	next

	; if we got to here then we read the whole thing.
	_GXSV_cbRet = _cbSVal;
	
_GXSV_SCAN_READ_UNTIL_CR:
	hserin2 20000, _GXSV_TO, [str _bTemp\10\13]	; retrieve rest of string
	for _GXSV_i = 0 to 9
		if (_bTemp(_GXSV_i) = 13) then _GXSV_CR
	next
	; Need to read some more until we hit CR
	goto _GXSV_SCAN_READ_UNTIL_CR
	
_GXSV_CR:	
	if _SSAction.bit1 then
		hserout2 [str _XBEE_ATCN_STR\5]							; Exit command mode
		hserin2 20000, _GXSV_TO,	[str _bTemp\10\13]	; and retrieve the OK
	endif
_GXSV_TO:	

	return _GXSV_cbRet
	
;==============================================================================
; [SetXBeeMy] - Set the XBee My Value to the passed in value.
; BUGBUG:: Could combine with other functions...
;
;==============================================================================
SetXBeeMy[wNewDL]:

#ifdef DEBUG
	hserout ["Set XBee My: ", hex wNewDL, 13]
#endif		
	pause 20							; have to have a guard time to get into Command sequence
	hserout2 [str _XBEE_PPP_STR\3]
	gosub WaitHSerout2Complete
	pause 20							; have to wait a bit again
	hserout2  ["ATMY ",hex wNewDL, 13, |	; Set the destination address
			str _XBEE_ATCN_STR\5]					; exit command mode
	return


;==============================================================================
; [SendXBeePacket] - Simple helper function to send the 4 byte packet header
;	 plus the extra data if any
; 	 gosub SendXBeePacket[bPacketType, bSeq, cbExtra, pExtra]
;==============================================================================
#ifdef DEBUG_XBEE
_pbDump var pointer
#endif

_pbIN		var	pointer		; pointer to data to retrieve
_bPHType 	var _bPacketHeader(0)
_bPHChkSum	var	_bPacketHeader(1)
_bPHSeq		var	_bPacketHeader(2)
_bPHCBExtra var _bPacketHeader(3)
SendXbeePacket[_bPHType,_bPHSeq,_bPHCBExtra, _pbIN]:
	_bPHChkSum = _bPHSeq + _bPHCBExtra	;
	
	; need to finish checksum - could do in basic but need to verify pointer...
	mov.b	@_BPHCHKSUM:16, r1l	; get the checkum already calculated for header
	mov.b	@_BPHCBEXTRA:16, r1h	; get the count of bytes 
	beq		_SXBP_NOEXTR:8				; no extra bytes
	mov.l	@_PBIN, er0					; get the pointer to extra data
_SXBP_CHKSUM_LOOP:
	mov.b	@er0+, r2l				; get the next character
	add.b	r2l,  r1l				; add on to r0l for checksum
	dec.b	r1h						; decrement	our counter
	bne		_SXBP_CHKSUM_LOOP:8		; not done yet.  
_SXBP_NOEXTR:
	mov.b	r1l, @_BPHCHKSUM:16		; save away checksum for basic to use


	if _bPHCBExtra then
		hserout2 [str _bPacketHeader\4, str @_pbIN\_bPHCBExtra]		; Real simple message 
	else
		hserout2 [str _bPacketHeader\4]		; Real simple message 
	endif

#ifdef DEBUG_XBEE
	if (wDebugLevel and DBG_LVL_CONTROL) then

	; We moved dump before the serout as hserout2 will cause lots of interrupts which will screw up our serial output...
	; Moved after as we want the other side to get it as quick as possible...
		hserout ["SDP:", hex _bPacketHeader(0)\2, hex _bPacketHeader(1)\2, hex _bPacketHeader(2)\2, hex _bPacketHeader(3)\2, ":"]
#ifdef DEBUG_VERBOSE		; Only ouput whole thing if verbose...
		_pbDump = _pbIN
		_pbDump.highword = 0x2	; BUGBUG: force for pointer to bytes
		if _bPHCBExtra then
			for _tas_i = 0 to _bPHCBExtra -1
				hserout [hex @_pbDump\2]
				_pbDump = _pbDump + 1
			next
		endif
#endif	
		hserout [13]
	endif		
#endif

	
	return
	
;==============================================================================
; [ClearInputBuffer] - This simple helper function will clear out the input
;						buffer from the XBEE
;==============================================================================
ClearInputBuffer:
#ifdef DEBUG_ENTERLEAVE
	hserout ["Enter: Clear Input Buffer", 13]
#endif	

; 	warning this function does not handle RTS for HSERIAL
; 	assumes that it has been setup properly before it got here.
_CIB_LOOP:	
	hserin2 1000, _CIB_TO, [_tas_b]
	goto _CIB_LOOP
	
_CIB_TO:
#ifdef DEBUG_ENTERLEAVE
	hserout ["Exit: Clear Input Buffer", 13]
#endif	
	return


;--------------------------------------------------------------------
;[XBeeResetPacketTimeout] - This function resets the save timer value that is used to 
;				 decide if our XBEE has timed out It could/should be simplay
;				 a call to GetCurrentTime, but try to save a little time of
;				 not nesting the calls...
;==============================================================================
	
XBeeResetPacketTimeout:
	_lTimerLastPacket = lTimerCnt + TCB1
	
	; handle wrap
	if lTimerCnt <> (_lTimerLastPacket & 0xffffff00) then
		_lTimerLastPacket = lTimerCnt + TCB1
	endif

	return



;==============================================================================
; [ReceiveXBeePacket] - This function will try to receive a packet of information
; 		from the remote control over XBee.
;
; the data in a standard packet is arranged in the following byte order:
;	0 - Buttons High
;	1 - Buttons Low
; 	2 - Right Joystick L/R
;	3 - Right Joystick U/D
;	4 - Left Joystick L/R
;	5 - Left Joystick U/D
; 	6 - Right Slider
;	7 - Left Slider
;==============================================================================

; Thse are variables needed here and not by tranmitter who deoes not include these functions
; BUGBUG:: Defining three variables next to each other does not necessarily imply they will
; be defined consecutively.  So try a different route.
; are sent in a packet...
_alNIPD		var long(7)		; 2 for SL+H + 20 bytes for NI data...
_lSNH		var _alNIPD(0)	; Serial Number High
_lSNL		var _alNIPD(1)	; Serial number low.
_bNI		var	_alNIPD(2)	; String to read NI into...
_pbNI		var	pointer		; need something to point as a byte pointer


ReceiveXBeePacket:
#ifdef DEBUG_ENTERLEAVE
	hserout ["E: ReceiveXbeePacket", 13]
#endif	
	_fPacketValidPrev = fPacketValid		; Save away the previous state as this is the state if no new data...
	fPacketValid = 0
	fPacketTimeOut = 0
	_fNewPacketAvail = 0;
	fPacketForced = 0;
	fPacketEnterSSCMode = 0   
	;	We will first see if we have a packet header waiting for us.
#ifdef CXBEE_RTS
	low cXBEE_RTS		; Ok enable input from the XBEE - wont turn off by default
	; bugbug should maybe check to see if it was high first and if
	; so maybe bypass the next check...
#endif	
;	hserstat HSERSTAT_INPUT_EMPTY, _TP_Timeout			; if no input available quickly jump out.
	; Well Hserstat is failing, try rolling our own.
	mov.b	@_HSERIN2START, r0l
	mov.b	@_HSERIN2END, r0h
	sub.b	r0h, r0l
	mov.b	r0l, @BHSERINHASDATA
	if	(not bHSerinHasData) then _RXP_CHECKFORHEADER_TO
	hserin2 10000, _RXP_HEADER_TO, [str _bPacketHeader\4]
	goto _RXP_CHECK_PACKET
_RXP_HEADER_TO:
#ifdef DEBUG_XBEE
	if (wDebugLevel and DBG_LVL_CONTROL) then
		hserout ["TO: - Packet header", 13]
	endif
#endif	
	
_RXP_CHECK_PACKET:

#ifdef DEBUG_VERBOSE	
	;bugbug;;; debug
	if (wDebugLevel and DBG_LVL_CONTROL) then
		hserout ["PH:", hex _bPacketHeader(0)\2, hex _bPacketHeader(1)\2, hex _bPacketHeader(2)\2, hex _bPacketHeader(3)\2, 13]
	endif
#endif
	
	;-----------------------------------------------------------------------------
	; [XBEE_TRANS_DATA]
	;-----------------------------------------------------------------------------
	; process first as higher number of these come in...
	if (_bPacketHeader(0) = XBEE_TRANS_DATA) and (_bPacketHeader(3) = XBEEPACKETSIZE) then
		hserin2 25000, _RXP_TIMEOUT, [str bPacket\XBEEPACKETSIZE]
		_fReqDataPacketSent = 0	; if we received a packet reset so we will request data again...
		; validate the header information...
		; Ok Lets try to validate the checksum.
		_bChkSumIn = _bPacketHeader(2) + _bPacketHeader(3)
		for _tas_i = 0 to XBEEPACKETSIZE-1
			_bChkSumIn = _bChkSumIn + bPacket(_tas_i)
		next
#ifdef DEBUG_VERBOSE
		hserout ["P: ", hex bPacket(PKT_BTNLOW)\2, hex bPacket(PKT_BTNHI)\2, hex bPacket(PKT_RJOYLR)\2, hex bPacket(PKT_RJOYUD)\2, |
								     hex bPacket(PKT_LJOYLR)\2, hex bPacket(PKT_LJOYUD)\2, hex bPacket(PKT_RSLIDER)\2, hex bPacket(PKT_LSLIDER)\2, |
								     " CS: ", hex _bChkSumIn, " PN: ", hex _bPacketNum, 13]
#endif		
		if (_bChkSumIn = _bPacketHeader(1)) then
#ifdef DEBUG_XBEE
	;bugbug;;; debug
	if (wDebugLevel and DBG_LVL_CONTROL) then
		hserout ["RV:", hex _bPacketHeader(0)\2, hex _bPacketHeader(1)\2, hex _bPacketHeader(2)\2, hex _bPacketHeader(3)\2, 13]
	endif
#endif

			fPacketValid = 1	; data is valid
			cPacketTimeouts = 0	; reset when we have a valid packet
			fPacketForced = _fReqDataForced	; Was the last request forced???
			_fReqDataForced = 0				; clear that state now
			GOSUB XBeeResetPacketTimeout ; sets _lTimerLastPacket
;			toggle p4
			return	;  		; get out quick!
		else
#ifdef DEBUG_XBEE
			;bugbug;;; debug
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout ["E ChkSum: ", hex _bPacketHeader(0)\2, hex _bPacketHeader(1)\2, hex _bPacketHeader(2)\2, hex _bPacketHeader(3)\2,  ":", hex _bChkSumIn, 13]
			endif
#endif
			; the checksum and data not right lets clear our input buffer out...	
;			toggle p6			; BUGBUG - Debug
			gosub ClearInputBuffer
		endif
	; OK we got 4 bytes is it a proper header and if so what?
	; Currently we are supporting a few different messages including XBEE_TRANS_READY, XBEE_TRANS_READY and XBEE_TRANS_NEW message
	;-----------------------------------------------------------------------------
	; [XBEE_TRANS_READY]
	;-----------------------------------------------------------------------------
	elseif (_bPacketHeader(0) = XBEE_TRANS_READY)
		; Two cases.  everything zero which is the old simple all zero, newer one has the MY of the transmitter, so we will want to update
		; our DL to point to it...
		if  (_bPacketHeader(1) = 0)  and (_bPacketHeader(2) = 0) and (_bPacketHeader(3) = 0) then
			fTransReadyRecvd = 1		; OK we have received a packet saying transmitter is ready.	
#ifdef DEBUG_XBEE
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout ["Ready:  ", 13]
			endif
#endif
		elseif (_bPacketHeader(3) = 2)
			; we need to read in a new DL for the transmitter...
			hserin2 10000, _RXP_CHECKFORHEADER_TO, [str wNewDL\2]
#ifdef DEBUG_XBEE
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout ["Ready:  ", hex wNewDL, 13]
			endif
#endif
			if _bPacketHeader(1) = ((_bPacketHeader(2) + _bPacketHeader(3) + wNewDL.Lowbyte + wNewDl.Highbyte) & 0xff) then ; did on fly make sure byte
				fTransReadyRecvd = 1		; OK we have received a packet saying transmitter is ready.	
				gosub SetXBeeDL[wNewDL]			
				gosub ClearInputBuffer		; get rid of all of the OKs...
			endif
		endif
		Sound cSound,[100\4400]

		; And tell the remote to go into New data only mode.
		gosub SendXbeeNewDataOnlyPacket[1]
		GOSUB XBeeResetPacketTimeout ; sets _lTimerLastPacket
		_fReqDataPacketSent = 0							; make sure we don't think we have any outstanding requests
	;-----------------------------------------------------------------------------
	; [XBEE_TRANS_NOTREADY]
	;-----------------------------------------------------------------------------
	elseif (_bPacketHeader(0) = XBEE_TRANS_NOTREADY) and (_bPacketHeader(1) = 0)  and (_bPacketHeader(2) = 0) and (_bPacketHeader(3) = 0)
		; we are being told that the transmitter may not be valid anymore...
		Sound cSound,[60\3200]
		fTransReadyRecvd = 0			; Ok not valid anymore...
#ifdef DEBUG_XBEE
		if (wDebugLevel and DBG_LVL_CONTROL) then
			hserout ["Not Ready:", 13]
		endif
#endif
		
	;-----------------------------------------------------------------------------
	; [XBEE_TRANS_NEW]
	;-----------------------------------------------------------------------------
	elseif (_bPacketHeader(0) = XBEE_TRANS_NEW) and (_bPacketHeader(1) = 0)  and (_bPacketHeader(2) = 0) and (_bPacketHeader(3) = 0)
		; The remote has told us it has new data available for us, so we should now ask for it!
#ifdef DEBUG_XBEE
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout ["New data Packet received ", 13]
			endif
#endif
		_fNewPacketAvail = 1;
	;-----------------------------------------------------------------------------
	; [XBEE_REQ_SN_NI]
	;-----------------------------------------------------------------------------
	elseif (_bPacketHeader(0) = XBEE_REQ_SN_NI)
		; The caller must pass through the DL to talk back to, or how else would we???
		; our DL to point to it...
		if (_bPacketHeader(3) = 2) then
			; we need to read in a new DL for the transmitter...
			hserin2 10000, _RXP_CHECKFORHEADER_TO, [str wNewDL\2]
#ifdef DEBUG_XBEE
			if (wDebugLevel and DBG_LVL_CONTROL) then
				hserout ["XBEE_REQ_SN_NI:  ", hex wNewDL, 13]
			endif
#endif
			if _bPacketHeader(1) = ((_bPacketHeader(2) + _bPacketHeader(3) + wNewDL.Lowbyte + wNewDl.Highbyte) & 0xff) then ; did on fly make sure byte
				gosub SetXBeeDL[wNewDL]		; We may want to verify that we are not active in some other conversation...
				gosub ClearInputBuffer		; get rid of all of the OKs...
				
				; now lets get the data to send back
				gosub GetXBeeStringVal["N","I",0x1,  @_bNI, 20], _cbRead ; 
				gosub GetXBeeHexVal["S","L",0x0], _lSNL		; get the serial low, don't enter or leave
				gosub GetXBeeHexVal["S","H",0x2], _lSNH		; get the serial high, 

#ifdef DEBUG_XBEE
				if (wDebugLevel and DBG_LVL_CONTROL) then
					hserout ["X._NI:  ", hex _lSNH, " ", hex _lSNL, "(", str _bNI\21\13,")", dec _cbRead, 13]
				endif
#endif
				gosub ClearInputBuffer		; get rid of all of the OKs...
				_pbNI	= @_bni				; get address
				_pbni.highword = 0x2		; make it a byte pointer
				_pbni = _pbni + _cbRead
				; lets blank fill the name...
				while (_cbRead < 14)
					@_pbNI = " "
					_cbRead = _cbRead + 1
					_pbNI = _pbNI + 1
				wend

				; last but not least try to send the data as a packet.
				gosub SendXBeePacket[XBEE_SEND_SN_NI_DATA, 0,  22, @_lSNH]		; Send Data to remote (CmdType, ChkSum, Packet Number, CB extra data)

			endif
		endif
	;-----------------------------------------------------------------------------
	; [UNKNOWN PACKET]
	;-----------------------------------------------------------------------------
	else
#ifdef DEBUG_XBEE
		if (wDebugLevel and DBG_LVL_CONTROL) then
			hserout ["Unk Packet", 13]
		endif
#endif
		gosub ClearInputBuffer
	endif

;-----------------------------------------------------------------------------
; [See if we need to request data from the other side]
;-----------------------------------------------------------------------------
_RXP_CHECKFORHEADER_TO:

	; Only send when we know the transmitter is ready.  Also if we are in the New data only mode don't ask for data unless we have been told there
	; is new data. We relax this a little and be sure to ask for data every so often as to make sure the remote is still working...
	; 
	if fTransReadyRecvd then
		GOSUB GetCurrentTime[], _lCurrentTimeT

		; Time in MS since last packet
		_lTimeDiffMS = ((_lCurrentTimeT-_lTimerLastPacket) * WTIMERTICSPERMSMUL) / WTIMERTICSPERMSDIV

		; See if we exceeded a global timeout.  If so let caller know so they can stop themself if necessary...
		if _ltimeDiffMS > CXBEETIMEOUTRECVMS then
			fPacketValid = 0
			fPacketForced = 1
			return
		endif

		; see if we have an outstanding request out and if it timed out...
		if _fReqDataPacketSent then
			if (((_lCurrentTimeT-_lTimerLastRequest) * WTIMERTICSPERMSMUL) / WTIMERTICSPERMSDIV) > CXBEEPACKETTIMEOUTMS then
				; packet request timed out, force a new attempt.
				_fNewPacketAvail = 1		; make sure it requests a new one	
			endif
		endif
		
		; Next see if it has been too long since we received a packet.  Ask to make sure they are there...
		if (_fNewPacketAvail = 0) and (_lTimeDiffMS > CXBEEFORCEREQMS) then
			_fNewPacketAvail = 1
			_fReqDataForced = 1		; remember that this request was forced!
		endif

		if ((fSendOnlyNewMode = 0) or (fSendOnlyNewMode and _fNewPacketAvail)) then
			; Now send out a prompt request to the transmitter:
			_bPacketNum = _bPacketNum + 1;		; rolling counter 

			gosub SendXBeePacket [XBEE_RECV_REQ_DATA, _bPacketNum,  0, 0]		; Request data Prompt (CmdType, ChkSum, Packet Number, CB extra data)
			_fReqDataPacketSent = 1	; 											; yes we have already sent one.
			GOSUB GetCurrentTime[], _lTimerLastRequest							; use current time to take care of delays...
		endif
		fPacketValid = _fPacketValidPrev	; Say the data is in the same state as the previous call...
	endif
#ifdef DEBUG_ENTERLEAVE
	hserout ["Exit: ReceiveXbeePacket", 13]
#endif	

	return

_RXP_TIMEOUT:
	;toggle p5
	; This should be a rare event	
	fPacketTimeout = 1
	cPacketTimeouts = cPacketTimeouts + 1
	if cPacketTimeouts = CPACKETTIMEOUTMAX then
		Sound cSound,[60\3200]
		fTransReadyRecvd = 0;				; Something wrong?  wait for transmitter to say they are ready
		gosub ClearInputBuffer
	endif
	bPacket = rep 0\9		; timeout clear it out
#ifdef DEBUG_XBEE
	if (wDebugLevel and DBG_LVL_CONTROL) then
		hserout ["Exit: Recv - Timeout - Packet data", 13]
	endif
#endif	
	return

;==============================================================================
; [SendXBeeNewDataOnlyPacket[fNewOnly]] - This function will tell the remote that we only
; 		want packets when something changes.
;==============================================================================
fNewOnly	var	byte
SendXbeeNewDataOnlyPacket[fNewOnly]:
		; And tell the remote to go into New data only mode.
	if fNewonly then
		gosub SendXBeePacket[XBEE_RECV_REQ_NEW, 0xff,  0, 0]		; Request only new data
		fSendOnlyNewMode = 1;						; Say we are in that mode...	
	else
		gosub SendXBeePacket [XBEE_RECV_REQ_NEW, 0,  0, 0]			; We will query for data
		fSendOnlyNewMode = 0;						; Say we are in that mode...	
	endif	
	return

#endif