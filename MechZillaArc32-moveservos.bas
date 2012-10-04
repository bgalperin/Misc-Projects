'Test file - move servos via terminal 38.4k baud

ENABLEHSERVO2
ENABLEHSERIAL1
sethserial1 H38400

hserout ["Individual Servo Movement Test", 13]

; Define pins

cCameraPin		con P6  ;gun/camera pan 
 	
cLHipYawPin		con P0	;Left Leg Hip Rotate
cLHipRollPin	con P1	;Left Leg Hip Sway
cLFemurPin 		con P7	;Left Leg Femur
cLTibiaPin 		con P3	;Left Leg Knee
cLAnklePitchPin		con P2	;Left Leg Ankle
cLAnkleRollPin 	con P5	;Left Leg Ankle Sway
	
cRHipYawPin		con P16	;Right Leg Hip Rotate
cRHipRollPin	con P17	;Right Leg Hip Sway
cRFemurPin 		con P23	;Right Leg Femur
cRTibiaPin 		con P20	;Right Leg Knee
cRAnklePitchPin		con P18	;Right Leg Ankle
cRAnkleRollPin 	con P19	;Right Leg Ankle Sway

Camera var sword
RHipYaw var sword ;servo value
RHipRoll var sword
RFemur var sword
RTibia var sword
RAnklePitch var sword
RAnkleRoll var sword

LHipYaw var sword
LHipRoll var sword
LFemur var sword
LTibia var sword
LAnklePitch var sword
LAnkleRoll var sword

Term_Input		var	byte		; input prompt
ShowTerminalPrompt var bit
Changes var byte 


Term_Prompt:
	IF ShowTerminalPrompt THEN
	hserout [13, "Servo Mover", 13, | 
		" A-Z - Enter individual servo ", 13, |
		" : "]
	Changes = 0
	ShowTerminalPrompt = 0
	ENDIF
	
	
	hserin [Term_Input]
	
main
		
	if Term_Input = 13 then
		ShowTerminalPrompt = 1	
		gosub GetServoPositions
		goto Term_Prompt
	endif
	
	if Term_Input = ("A" | "a") then
		hserout ["A - Right Hip Yaw: ", 13]
		AInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RHipYaw = RHipYaw + 100
			Changes = Changes + 1
			hservo [cRHipYawPin \ RHipYaw]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RHipYaw, 13]
				Changes = 0
			endif
			goto AInput
		elseif Term_Input = "-"
			RHipYaw = RHipYaw - 100
			Changes = Changes + 1
			hservo [cRHipYawPin \ RHipYaw]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RHipYaw, 13]
				Changes = 0
			endif
			goto AInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("B" | "b") then
		hserout ["B - Right Hip Roll: ", 13]
		BInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RHipRoll = RHipRoll + 100
			Changes = Changes + 1
			hservo [cRHipRollPin \ RHipRoll]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RHipRoll, 13]
				Changes = 0
			endif
			goto BInput
		elseif Term_Input = "-"
			RHipRoll = RHipRoll - 100
			Changes = Changes + 1
			hservo [cRHipRollPin \ RHipRoll]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RHipRoll, 13]
				Changes = 0
			endif
			goto BInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("C" | "c") then
		hserout ["C - Right Femur: ", 13]
		CInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RFemur = RFemur + 100
			Changes = Changes + 1
			hservo [cRFemurPin \ RFemur]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RFemur, 13]
				Changes = 0
			endif
			goto CInput
		elseif Term_Input = "-"
			RFemur = RFemur - 100
			Changes = Changes + 1
			hservo [cRFemurPin \ RFemur]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RFemur, 13]
				Changes = 0
			endif
			goto CInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("D" | "d") then
		hserout ["D - Right Tibia: ", 13]
		DInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RTibia = RTibia + 100
			Changes = Changes + 1
			hservo [cRTibiaPin \ RTibia]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RTibia, 13]
				Changes = 0
			endif
			goto DInput
		elseif Term_Input = "-"
			RTibia = RTibia - 100
			Changes = Changes + 1
			hservo [cRTibiaPin \ RTibia]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RTibia, 13]
				Changes = 0
			endif
			goto DInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("E" | "e") then
		hserout ["R - Right Ankle Pitch: ", 13]
		EInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RAnklePitch = RAnklePitch + 100
			Changes = Changes + 1
			hservo [cRAnklePitchPin \ RAnklePitch]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RAnklePitch, 13]
				Changes = 0
			endif
			goto EInput
		elseif Term_Input = "-"
			RAnklePitch = RAnklePitch - 100
			Changes = Changes + 1
			hservo [cRAnklePitchPin \ RAnklePitch]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RAnklePitch, 13]
				Changes = 0
			endif
			goto EInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("F" | "f") then
		hserout ["F - Right Ankle Roll: ", 13]
		FInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			RAnkleRoll = RAnkleRoll + 100
			Changes = Changes + 1
			hservo [cRAnkleRollPin \ RAnkleRoll]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec RAnkleRoll, 13]
				Changes = 0
			endif
			goto FInput
		elseif Term_Input = "-"
			RAnkleRoll = RAnkleRoll - 100
			Changes = Changes + 1
			hservo [cRAnkleRollPin \ RAnkleRoll]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec RAnkleRoll, 13]
				Changes = 0
			endif
			goto FInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("G" | "g") then
		hserout ["G - Left Hip Yaw: ", 13]
		GInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LHipYaw = LHipYaw + 100
			Changes = Changes + 1
			hservo [cLHipYawPin \ LHipYaw]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LHipYaw, 13]
				Changes = 0
			endif
			goto GInput
		elseif Term_Input = "-"
			LHipYaw = LHipYaw - 100
			Changes = Changes + 1
			hservo [cLHipYawPin \ LHipYaw]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LHipYaw, 13]
				Changes = 0
			endif
			goto GInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("H" | "h") then
		hserout ["H - Left Hip Roll: ", 13]
		HInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LHipRoll = LHipRoll + 100
			Changes = Changes + 1
			hservo [cLHipRollPin \ LHipRoll]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LHipRoll, 13]
				Changes = 0
			endif
			goto HInput
		elseif Term_Input = "-"
			LHipRoll = LHipRoll - 100
			Changes = Changes + 1
			hservo [cLHipRollPin \ LHipRoll]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LHipRoll, 13]
				Changes = 0
			endif
			goto HInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("I" | "i") then
		hserout ["I - Left Femur: ", 13]
		IInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LFemur = LFemur + 100
			Changes = Changes + 1
			hservo [cLFemurPin \ LFemur]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LFemur, 13]
				Changes = 0
			endif
			goto IInput
		elseif Term_Input = "-"
			LFemur = LFemur - 100
			Changes = Changes + 1
			hservo [cLFemurPin \ LFemur]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LFemur, 13]
				Changes = 0
			endif
			goto IInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("J" | "j") then
		hserout ["L - L Tibia: ", 13]
		JInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LTibia = LTibia + 100
			Changes = Changes + 1
			hservo [cLTibiaPin \ LTibia]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LTibia, 13]
				Changes = 0
			endif
			goto JInput
		elseif Term_Input = "-"
			LTibia = LTibia - 100
			Changes = Changes + 1
			hservo [cLTibiaPin \ LTibia]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LTibia, 13]
				Changes = 0
			endif
			goto JInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("K" | "k") then
		hserout ["L - Left Ankle Pitch: ", 13]
		KInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LAnklePitch = LAnklePitch + 100
			Changes = Changes + 1
			hservo [cLAnklePitchPin \ LAnklePitch]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LAnklePitch, 13]
				Changes = 0
			endif
			goto KInput	
		elseif Term_Input = "-"
			LAnklePitch = LAnklePitch - 100
			Changes = Changes + 1
			hservo [cLAnklePitchPin \ LAnklePitch]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LAnklePitch, 13]
				Changes = 0
			endif
			goto KInput
		endif	
		goto main
		
	endif	

	if Term_Input = ("L" | "l") then
		hserout ["L - Left Ankle Roll: ", 13]
		LInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			LAnkleRoll = LAnkleRoll + 100
			Changes = Changes + 1
			hservo [cLAnkleRollPin \ LAnkleRoll]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec LAnkleRoll, 13]
				Changes = 0
			endif
			goto LInput
		elseif Term_Input = "-"
			LAnkleRoll = LAnkleRoll - 100
			Changes = Changes + 1
			hservo [cLAnkleRollPin \ LAnkleRoll]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec LAnkleRoll, 13]
				Changes = 0
			endif
			goto LInput
		endif	
		goto main
		
	endif	
	
	if Term_Input = ("M" | "m") then
		hserout ["M - Camera: ", 13]
		MInput:
		hserin [Term_Input]
	
		if Term_Input = "+" then
			Camera = Camera + 100
			Changes = Changes + 1
			hservo [cCameraPin \ Camera]
			
			if Changes > 5 then
				hserout [13, "  : ", sdec Camera, 13]
				Changes = 0
			endif
			goto MInput
		elseif Term_Input = "-"
			Camera = Camera - 100
			Changes = Changes + 1
			hservo [cCameraPin \ Camera]
		
			if Changes > 5 then
				hserout [13, "  : ", sdec Camera, 13]
				Changes = 0
			endif
			goto MInput
		endif	
		goto main
		
	endif
	
	if Term_Input = ("Z" | "z") then
				hservo [cLHipYawPin\1500] ;
		hservo [cLHipRollPin\1000] ;
		hservo [cLFemurPin\-2000] ;
		hservo [cLTibiaPin\-10000] ;
		hservo [cLAnklePitchPin\3000] ;
		hservo [cLAnkleRollPin\1000] ;

		hservo [cRHipYawPin\1500] ;
		hservo [cRHipRollPin\1000] ;
		hservo [cRFemurPin\-2000] ;
		hservo [cRTibiaPin\8000] ;
		hservo [cRAnklePitchPin\-5000] ;
		hservo [cRAnkleRollPin\1000] ;
		
		hservo [cCameraPin\1000];
		goto Term_Prompt
	endif
	
	if Term_Input = ("1") then
				hservo [cLHipYawPin\1500] ;
		hservo [cLHipRollPin\-1100] ;
		hservo [cLFemurPin\-2000] ;
		hservo [cLTibiaPin\-10000] ;
		hservo [cLAnklePitchPin\3000] ;
		hservo [cLAnkleRollPin\-1000] ;

		hservo [cRHipYawPin\1500] ;
		hservo [cRHipRollPin\-1100] ;
		hservo [cRFemurPin\-2000] ;
		hservo [cRTibiaPin\8000] ;
		hservo [cRAnklePitchPin\-5000] ;
		hservo [cRAnkleRollPin\-1000] ;
		
		hservo [cCameraPin\1000];
		goto Term_Prompt
	endif

	if Term_Input = ("2") then
				hservo [cLHipYawPin\1500] ;
		hservo [cLHipRollPin\-1100] ;
		hservo [cLFemurPin\-2000] ;
		hservo [cLTibiaPin\-10000] ;
		hservo [cLAnklePitchPin\3000] ;
		hservo [cLAnkleRollPin\-2200] ;

		hservo [cRHipYawPin\1500] ;
		hservo [cRHipRollPin\-1100] ;
		hservo [cRFemurPin\-2000] ;
		hservo [cRTibiaPin\15200] ;
		hservo [cRAnklePitchPin\2600] ;
		hservo [cRAnkleRollPin\-1000] ;
		
		hservo [cCameraPin\1000];
		goto Term_Prompt
	endif

	if Term_Input = ("3") then
				hservo [cLHipYawPin\1500] ;
		hservo [cLHipRollPin\-1100] ;
		hservo [cLFemurPin\-2000] ;
		hservo [cLTibiaPin\-10000] ;
		hservo [cLAnklePitchPin\3000] ;
		hservo [cLAnkleRollPin\-2200] ;

		hservo [cRHipYawPin\1500] ;
		hservo [cRHipRollPin\-1100] ;
		hservo [cRFemurPin\-4600] ;
		hservo [cRTibiaPin\9700] ;
		hservo [cRAnklePitchPin\200] ;
		hservo [cRAnkleRollPin\-800] ;
		
		hservo [cCameraPin\1000];
		goto Term_Prompt
	endif
				
GetServoPositions:
	Camera = hservopos(cCameraPin)

	LHipYaw = hservopos(cLHipYawPin)
	LHipRoll = hservopos(cLHipRollPin)
	LFemur = hservopos(cLFemurPin)
	LTibia = hservopos(cLTibiaPin)
	LAnklePitch = hservopos(cLAnklePitchPin)
	LAnkleRoll = hservopos(cLAnkleRollPin)

	RHipYaw = hservopos(cRHipYawPin)
	RHipRoll = hservopos(cRHipRollPin)
	RFemur = hservopos(cRFemurPin)
	RTibia = hservopos(cRTibiaPin)
	RAnklePitch = hservopos(cRAnklePitchPin)
	RAnkleRoll = hservopos(cRAnkleRollPin)

	hserout["Servo Positions: ", 13, |
		"         Camera: ", sdec Camera, 13, | 
		"RHipYaw: ", sdec LHipYaw, "     LHipYaw: ", sdec RHipYaw, 13, |
		"RHipRoll: ", sdec LHipRoll, "     LHipRoll: ", sdec RHipRoll, 13, |
		"RFemur: ", sdec LFemur, "     LFemur: ", sdec RFemur, 13, |
		"RTibia: ", sdec LTibia, "     LTibia: ", sdec RTibia, 13, |
		"RAnklePitch: ", sdec LAnklePitch, "     LAnklePitch: ", sdec RAnklePitch, 13, |
		"RAnkleRoll: ", sdec LAnkleRoll, "     LAnkleRoll: ", sdec RankleRoll,13]
		
return