;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                   Initialize Game                     ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

	DEFSECT "START_MAIN", CODE
	SECT "START_MAIN"

; mis stuff
GLOBAL _InGameStart
EXTERN _GameEndSequence
EXTERN _LevelList
	
GLOBAL _GameSettings
GLOBAL _GameContrast
GLOBAL _InGameStart
GLOBAL GameFlags
GLOBAL _MainLoopRender
	
; sound driver
EXTERN _ADPM_RUN
EXTERN _ADPM_SETUP
EXTERN _ADPM_SFXbank
EXTERN _ADPM_SFXdir
EXTERN _ADPMrunSFX
EXTERN _ADPM_SFXoverlay

; music and sound
EXTERN _SongList
EXTERN _SFXdata

; graphics
EXTERN StripeDta
EXTERN SprDta_Dawn_Sh1
EXTERN SprDta_Dawn_Sh2
EXTERN SprDta_Expl_Sh1
EXTERN SprDta_Expl_Sh2
EXTERN BannerData
EXTERN PauseBannerIdle
EXTERN PauseBannerMenu
EXTERN GFX_NumbersBlack
EXTERN GFX_NumbersWhite
EXTERN PauseSoundSettingsText
EXTERN PauseRumbleSettingOFF
EXTERN PauseRumbleSettingON


_MainLoopRender:
rete

_InGameStart:
; interrupts
	ld a, #0
	ld [br:020h], #11111111b	 ; priority
	ld [br:021h], #11111111b
	ld [br:022h], #11111111b
	ld [br:023h], #00001000b 	; enable
	ld [br:024h], a
	ld [br:025h], a
	ld [br:026h], a
	ld [br:027h], #11111111b 	; flags
	ld [br:028h], #11111111b
	ld [br:029h], #11111111b
	ld [br:02Ah], #11111111b
	
	; timers
	ld [br:80h], a
	ld hl, #0D854h ;#0D4D4h
	ld [2032h], hl
	ld [br:18h], #10001000b
;	ld [br:19h], #00110000b
	ld [br:30h], #10000110b
	ld [br:0FEh], #10101111b
	ld [br:0FEh], #10100111b

	ld [br:01Ch], #10001000b	; timer 3
	ld [br:01Dh], #00000000b
	ld [br:048h], #10000110b
	ld [br:019h], #00100000b	; oscillator
	ld [br:070h], #0			; sound 
	ld [br:071h], #00000011b

	carl InitObjBuffer

	ld a, #80h ; center player pos
	ld [PlayerPos], a
	ld a, #10h
	ld [ObjSpawnWait], a
	
	ld a, #@dpag(_SFXdata) ; bank
	ld [_ADPM_SFXbank], a
	ld hl, #_SFXdata
	ld [_ADPM_SFXdir], hl










	ld a, #00000111b; TEST INSTRUCTION REMOVE LATER
	ld [_GameSettings], a
	ld a, #31
	ld [_GameContrast], a






	ld a, #0FFh
	ld [CurrentSong], a
	ld a, #0
	ld [CurrentLevel], a
  carl InitLevel

	ld a, #00000100b ; dummy on, sprite off, frame even
	ld [GameFlags], a

	; show first banner
	ld a, [CurrentLevel]
	ld [BannerCurrNumber], a
  carl BannerDispStart
	
MainLoopStart_NoBanner:
	ld hl, #GameFlags
	and [hl], #11110011b          ; turn off ObjGen dummy mode and clear ObjEv flag
	or [hl], #00000001b           ; turn on sprite
	ld a, #@HIGH(SprDta_Dawn_Sh1) ; setup dawn's ingame sprites
	ld [SpritePage], a
  carl DrawProgressCounter


;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                   In-Game Loop                        ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
	
MainLoop:
	; get inputs
	ld l, [br:52h]
	ld a, l
	ld b, [LastInput]
	and a, #10000000b 
	and b, #10000000b
	cp a, b
	ld a, l
  jrs z, SleepStillPressed
	ld [LastInput], a

	bit a, #10000000b
  jrs nz, NoSleep
	ld [br:71h], #0 ; turn off audio output
  int [42h]
	ld [br:0FEh], #10100111b ; invert LCD back
NoSleep:

SleepStillPressed:

	ld a, l
	ld b, [LastInput]
	and a, #00000100b 
	and b, #00000100b
	cp a, b
	ld a, l
  jrs z, CstillPressed
	ld [LastInput], a
	bit a, #00000100b
  jrs nz, CstillPressed
  jrl PauseGame
CstillPressed:

	ld hl, #PlayerPos
	ld b, [hl]
	ld [LastPos], b
	
;	ld b, #0
	bit a, #00100000b ; left
  jrs nz, NoLeft
	add [hl], #6

	; clobber
	cp [hl], #0E0h
  jrs c, NoLeft
	ld [hl], #0E0h
NoLeft:

	bit a, #01000000b ; right
  jrs nz, NoRight
	sub [hl], #6

	; clobber
	cp [hl], #020h
  jrs nc, NoRight
	ld [hl], #020h
NoRight:

	ld a, [LastPos]
	cp a, [hl]
  jrs z, DawnSprIdle
  jrs nc, DawnSprLeft
  jrs c, DawnSprRight

DawnSprLeft:
	ld b, #64
  jrs SpriteSet
DawnSprRight:
	ld b, #32
  jrs SpriteSet
DawnSprIdle:
	ld b, #0
SpriteSet:
	ld [SpriteIndex], b


;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                  Player Collision                     ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

; dawn's hitbox is represented by two points relative from the center player pos
; -24 --- Player pos --- +24

; if either of these points are inside the hit region of the wall then dawn is dead
; the hit region depends on the wall type
; but if for some case the wall happens to be in between the hit points, an additional check between the hit points is made
; if there is a wall point inside then dawn is dead

; the check works by taking a point and range comparing it against the wall points
; if both wall points are to the left or to the right relative to the player point, the point is outside range
; if the wall points are different, the player point is inside range
; this is done twice because dawn has two points

; outside range (dead if apr wall)
; Dawn A: <<
; Dawn B: <<

; Dawn A: >>
; Dawn B: >>


; inside range (dead if strip wall)
; Dawn A: ><
; Dawn B: ><


; in boundary (dead regardless of wall type)
; Dawn A ><
; Dawn B >>

; Dawn A <<
; Dawn B ><

; Dawn A << ; inside a very thin strip wall
; Dawn B >>


; note on subtraction carry relationship:
; --- cp a, b ---
; if A >= B, carry is clear
; if A < B,  carry is set

	ld ix, #ObjState7 ; check if the wall is in the hit position
	ld a, #0F0h
	cp a, [ix]
  jrl nz, Collision_Done
	inc ix ; check if wall type is not empty
	ld a, #0
	cp a, [ix]
  jrl z, Collision_Done

	inc ix
	ld a, [PlayerPos]
	cpl a

	ld hl, #0
	sub a, #18
	cp a, [ix] ; left point
  jrs c, Collision_PointAtLeft1
	ld l, #1
Collision_PointAtLeft1:
	inc ix
	cp a, [ix] ; right point
  jrs c, Collision_PointAtLeft2
	ld h, #1
Collision_PointAtLeft2:

	push hl
	ld hl, #0
	dec ix
	add a, #18+18
	cp a, [ix] ; left point
  jrs c, Collision_PointAtLeft3
	ld l, #1
Collision_PointAtLeft3:
	inc ix
	cp a, [ix] ; right point
  jrs c, Collision_PointAtLeft4
	ld h, #1
Collision_PointAtLeft4:

	; compare points
	pop ba
	cp a, b
  jrs nz, Collision_InsideRange1
	or a, a
  jrs z, Collision_OutsideRange1 ; left
	ld a, #2 ; right
  jrs Collision_OutsideRange1
Collision_InsideRange1:
	ld a, #1
Collision_OutsideRange1:
	
	ex ba, hl
	cp a, b
  jrs nz, Collision_InsideRange2
	or a, a
  jrs z, Collision_OutsideRange2 ; left
	ld a, #2 ; right
  jrs Collision_OutsideRange2
Collision_InsideRange2:
	ld a, #1
Collision_OutsideRange2:
	
	ld b, l
	cp a, b
	ld b, [ObjState7+1] ; get wall type
  jrl nz, DawnIsFuckingDead ; if they differ then it's insta kill
	cp a, #1
  jrs z, Collision_InsideWallRange
	; or else outside
	cp b, #2 ; check for type = aperture
  jrl z, DawnIsFuckingDead
  jrs Collision_Done
  
Collision_InsideWallRange:
	cp b, #1 ; check for type = strip
  jrl z, DawnIsFuckingDead
Collision_Done:




  carl _CalcObj
  carl _RenderGameState
  carl _DisplayBuffer
  carl _SoundRun

; LEVEL LOOP CONTROL
	ld hl, #GameFlags
	bit [hl], #00001000b ; check step flag
  jrl z, LvlCon_ContinueMain
	and [hl], #11110111b ; set flag back off

; increment level count
	ld hl, #LevelTime
	inc [hl]
	
	ld sc, #00010000b
	ld ba, [LevelTimeBCDlow]
	add a, #1
	ld [LevelTimeBCDlow], a
	ld a, b
	adc a, #0
	ld [LevelTimeBCDhigh], a
	ld sc, #00000000b
  carl DrawProgressCounter

; check if level count hit disable limit
	ld a, [LevelTime]
	cp a, #120-70
  jrs nz, LvlCon_NoDisable
	ld hl, #GameFlags
	or [hl], #00000100b ; enable dummy mode
LvlCon_NoDisable:

; check if it hit end level limit
	cp a, #136-70
	jrl z, LvlCon_AutoCenter
LvlCon_ContinueMain:

; this works, cool! but i might have a better idea
; - make the CalcObj call to return a flag only when a wall steps
; - increment level time externally and work with it that way



	halt
  jrl MainLoop



DrawProgressCounter:
; refresh progress counter
	; setup area
	ld ix, #GFX_NumbersBlack
	ld [br:0FEh], #10110111b ; select last row
	ld [br:0FEh], #00010100b ; 5th column area
	ld [br:0FEh], #12 ; offset inside column area

	; start refreshing area
	ld [br:0FFh], #0
	; print level number
	ld a, [CurrentLevel]
	inc a
  carl PrintNum
	; print the short dash in the middle
	ld [br:0FFh], #00010000b
	ld [br:0FFh], #00010000b
	ld [br:0FFh], #00000000b

	ld a, [LevelTime]
	sub a, #8
	ld hl, [LevelTimeBCDlow]
  jrs nc, LvlCon_NumDone
	ld hl, #0AAAh
;  jrs LvlCon_NumDone
;LvlCon_KeepNum:
;	swap a
;	add a, #60h
;  jrs nc, LvlCon_BCDnoOver1
;	inc a
;  jrs LvlCon_BCDOverFlw1
;LvlCon_BCDnoOver1:
;	sub a, #60h
;LvlCon_BCDOverFlw1:
;
;	swap a
;	add a, #60h
;  jrs nc, LvlCon_BCDnoOver2
;	inc h
;  jrs LvlCon_BCDOverFlw2
;LvlCon_BCDnoOver2:
;	sub a, #60h
;LvlCon_BCDOverFlw2:
;	ld l, a
LvlCon_NumDone:

	; print high number
	ld a, h
  carl PrintNum

	; print middle number
	ld a, l
	swap a
	and a, #00001111b
  carl PrintNum

	; print low number
	ld a, l
	and a, #00001111b
  carl PrintNum
  ret


;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX              Player Death Animation Loop              ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

DawnIsFuckingDead:
	ld a, [_GameSettings]
	bit a, #00000100b ; check for rumble ON/OFF setting
  jrs z, Dead_NoRumble
	ld [br:061h], #01111100b ; rumble ON, IR OFF, EEPROM I2C do nothing
Dead_NoRumble:
	ld a, #0 ; sound effect
	ld [_ADPM_SFXoverlay], a
	ld a, #70 ; frame counter
	ld [DeadFrameCount], a
	ld a, #0
	ld [ExplosionAnimCount], a
	ld [SpriteIndex], a
	ld a, #@HIGH(SprDta_Expl_Sh1)
	ld [SpritePage], a
	
Dead_WaitLoop:
	; explosion animation
	ld a, [ExplosionAnimCount]
	cp a, #16
  jrs z, Dead_SkipExplosion
	inc a
	ld b, a
	ld [ExplosionAnimCount], a
	
	swap a
	and a, #11100000b
	ld [SpriteIndex], a
	
	cp b, #16
  jrs nz, Dead_SkipExplosion
	ld hl, #GameFlags
	and [hl], #11111110b ; player off
	ld [br:061h], #01101100b ; rumble OFF, IR OFF, EEPROM I2C do nothing
Dead_SkipExplosion:
	
	
	; close out animation
	ld a, [DeadFrameCount]
	cp a, #25
  jrs nc, Dead_SkipCloseAnim
;	slp
	add a, a
	ld l, a
	ld b, #0
	ld ix, #StripBuffer
	add ix, ba
	add ix, #47
	xor a, a
	ld [ix], ba
	
	ld ix, #StripBuffer+48
	ld b, #0
	ld a, l
	sub ix, ba
;	sub ix, #2
	xor a, a
	ld [ix], ba
	
	
	
Dead_SkipCloseAnim:
	
  carl _DisplayBuffer
  carl _SoundRun
	halt
	ld hl, #DeadFrameCount
	dec [hl]
  jrs nz, Dead_WaitLoop
	
	ld a, #80h
	ld [PlayerPos], a
	ld [LastPos], a
	ld hl, #GameFlags
	or [hl], #00000001b ; player on
  carl InitObjBuffer
  carl InitLevel
  jrl MainLoopStart_NoBanner






;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                 Level Complete Loop                   ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
LvlCon_AutoCenter:
	halt
LvlCon_CenterLoop:
	; check direction relative to center (80h)
	; add or sub from last position and check if it crosses or equals center
	; if it doesn't change or equal, write result to position, else write 80h and end this function

	ld a, [PlayerPos]
	cp a, #80h
  jrs z, LvlCon_CenterDone
  jrs c, LvlCon_CenterFromRight
	; else from left
	ld b, #64
	ld [SpriteIndex], b
	sub a, #6
	cp a, #80h
  jrs z, LvlCon_CenterDone
  jrs c, LvlCon_CenterDone
  jrs LvlCon_ContinueLoop
	
LvlCon_CenterFromRight:
	ld b, #32
	ld [SpriteIndex], b
	add a, #6
	cp a, #80h
  jrs z, LvlCon_CenterDone
  jrs nc, LvlCon_CenterDone
LvlCon_ContinueLoop:
	ld [PlayerPos], a








  carl _CalcObj
  carl _RenderGameState
  carl _DisplayBuffer
  carl _SoundRun
	halt
  jrl LvlCon_CenterLoop

LvlCon_CenterDone:
	ld a, #80h
	ld [PlayerPos], a
	ld [LastPos], a
	ld a, #0
	ld [SpriteIndex], a

	ld b, #10	
LvlCon_WaitFrames:
	push b
  carl _CalcObj
  carl _RenderGameState
  carl _DisplayBuffer
  carl _SoundRun
	halt
	pop b
  djr nz, LvlCon_WaitFrames
	
	; increment level
	ld hl, #CurrentLevel
	inc [hl]
	cp [hl], #3 ; level 4
	ld a, #6
	ld [BannerCurrNumber], a
  carl z, BannerDispStart ; display "BOMB DOWN"
	
	ld a, [CurrentLevel]
	cp a, #6 ; level after 6 (don't exist)
  jrs z, GameEndFade

	; or else go to next level
  carl InitLevel
	ld a, [CurrentLevel]
	ld [BannerCurrNumber], a
  carl BannerDispStart
  
  
;LvlCon_WaitObjAlign:
;  carl _CalcObj
;  carl _RenderGameState
;  carl _DisplayBuffer
;  carl _SoundRun
;	halt
;	ld a, [ObjState0]
;	cp a, #87h
;  jrs nz, LvlCon_WaitObjAlign
  
  jrl MainLoopStart_NoBanner







GameEndFade:
	ld a, #7
	ld [BannerCurrNumber], a
  carl BannerDispStart
	; wait 128 frames to empty out the ObjBuffer
	ld a, #80h
	ld [WaitFramesCount], a
	ld a, #10
	ld [ObjState0], a
	ld hl, #GameFlags
	and [hl], #11111110b
	or [hl], #00010000b
	
LvlCon_EndWaitLoop:


; decrement spawn count
	ld hl, #ObjSpawnWait
	dec [hl]
  jrl nz, EndingObjGen_StepFrame
	ld [hl], #16

; set flag for the main loop's level state track function
;	ld hl, #GameFlags
;	or [hl], #00001000b ; step flag on
	ld hl, #EndingFadeCount
	inc [hl]

; begin spawn obj process
	ld ix, #ObjState6
	ld b, #7
EndingObjGen_MoveBuffer:
	ld hl, [ix]
	ld [ix+4], l
	ld [ix+5], h
	add ix, #2
	ld hl, [ix]
	ld [ix+4], l
	ld [ix+5], h
	sub ix, #6

  djr nz, EndingObjGen_MoveBuffer
	ld hl, #ObjState0
	sub [hl], #10h

  jrs EndingObjGen_SpawnBlank

EndingObjGen_StepFrame:
	ld hl, #ObjState0	
	ld b, #8h
EndingObjGen_CalcLoop:
	inc [hl]
	add hl, #4
  djr nz, EndingObjGen_CalcLoop
  jrs EndingObjGen_Done
	
EndingObjGen_SpawnBlank:
	ld hl, #0
	ld [ObjState0+1], l
	ld [ObjState0+2], hl

EndingObjGen_Done:

; now overwrite some entries to disappear with them
	ld b, [EndingFadeCount]
	cp b, #0
  jrs z, EndingFadeLoopDone
	ld hl, #ObjState0
	ld a, #10h ; any value below 80h will not render
EndingFadeLoop:
	ld [hl], a
	add hl, #4
  djr nz, EndingFadeLoop
EndingFadeLoopDone:


  carl _RenderGameState
  carl _DisplayBuffer
  carl _SoundRun
	
	halt
	ld hl, #WaitFramesCount
	dec [hl]
  jrl nz, LvlCon_EndWaitLoop
  jrl _GameEndSequence
;	slp
	

	

	




;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX            Display Level/Event Banner loop            ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
	
	; hide dawn's sprite
	; scroll from the left to right (easier to do so) untill it hits 96 scroll pos
	; decrement the frame counter
	; scroll the banner back into the left untill it hits 0 scroll pos
	; show dawn's sprite again
	; pass execution to in-game loop
	
BannerDispStart:
	xor a, a
	ld [BannerScrollPos], a
	ld a, #80
	ld [BannerFrameCount], a
	
	
Banner_Loop:	
	
	ld hl, #BannerFrameCount
	cp [hl], #0
  jrs z, Banner_scrollout
	
	; scroll banner in
	ld hl, #BannerScrollPos
	cp [hl], #95
  jrs nc, Banner_Wait
	add [hl], #2
  jrs Banner_ContinueLoop
	
Banner_Wait:
	ld hl, #BannerFrameCount
	cp [hl], #0
  jrs z, Banner_scrollout
	dec [hl]
  jrs Banner_ContinueLoop
	
Banner_scrollout:
	ld hl, #BannerScrollPos
	sub [hl], #2
  jrl z, Banner_BannerDone
  jrl c, Banner_BannerDone
	
Banner_ContinueLoop:
	
	
	carl _CalcObj
	carl _RenderGameState
;	carl _DisplayBuffer

; display buffer, but custom made for event banners
	ld iy, #StripeDta
	ld hl, #GameFlags
	xor [hl], #00000010b
	bit [hl], #00000010b
  jrs z, BannerRender_FrameIsEven
	add iy, #200h
BannerRender_FrameIsEven:





	ld [br:0FEh], #10110000b
  carl PageCopy
	add iy, #32

	ld [br:0FEh], #10110001b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110010b
  carl PageCopy
	add iy, #32

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	; copy banner into video memory
	; note: the banner scroll value won't go beyond 96
	ld ix, #BannerData
	ld a, [BannerCurrNumber] ; index to the banner going to be displayed
	ld l, #192
	mlt
	add ix, hl
	
	ld b, [BannerScrollPos]
	ld a, #96
	sub a, b ; invert scroll pos to get the end of the banner's first page
	; to get to the second page it's as easy as just adding 96 to this
	
	ld l, a
	ld h, b
	
	; display first half page
	ld [br:0FEh], #10110011b
  carl Banner_CopyPage
	add iy, #32
	
	ld ix, #BannerData+96
	ld a, [BannerCurrNumber] ; index to the banner going to be displayed
	ld l, #192
	mlt
	add ix, hl
	
	ld b, [BannerScrollPos]
	ld a, #96
	sub a, b ; invert scroll pos to get the end of the banner's second page
	
	ld l, a
	ld h, b
	
	; display second half page
;	ld [br:0FEh], #0
;	ld [br:0FEh], #00010000b
	ld [br:0FEh], #10110100b
  carl Banner_CopyPage
	add iy, #32
;	jrs Banner_FinishCopies



 	ld [br:0FEh], #10110101b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110110b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110111b
  carl PageCopy
	
	
	
	
	
  carl _SoundRun	

;	push ip
;	carl _ADPM_RUN
;	pop ip
;	push ip
;	carl _ADPMrunSFX
;	pop ip
	
	
	halt
  jrl Banner_Loop
	
Banner_BannerDone:
  ret
	
;	ld a, #96
;	sub a, b
;	ld l, a
;	ld h, b
;	add ix, #96
;Banner_CopyPage2:	
;	ld a, [ix+l]
;	inc l
;	ld [br:0FFh], a
;	dec h
;	db 0E7h, 0F9h ; jr nz, .CopyPage2
	

	
	
;	add iy, #64 ; just for test purposes
;	jrs Banner_FinishCopies

	Banner_CopyPage:
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
	ld a, [ix+l]
	inc l
	ld [br:0FFh], a
	dec h
	db 0E7h, 0F9h ; jr nz, .CopyPage
	
	; render remaining area as strip buffer like normal
	ld a, [BannerScrollPos]
	ld l, #9
	mlt
	ld ix, #PageCopy_LoopBase
	add hl, ix
	
	bit a, #1
  jrs z, Banner_ScrollIsEven
	add hl, #3
Banner_ScrollIsEven:
	ld ix, #StripBuffer+1
	ld b, #0
	add ix, ba
;	ld a, #0
;	push a
;	ld ba, #thisAddr
;	push ba
	jp hl
;thisAddr:
;Banner_FinishCopies:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	
;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                    Audio Management                   ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
_SoundRun:	
	ld a, [_GameSettings]
	bit a, #00000001b
  jrs nz, SoundRun_KeepSFX
	ld a, #0FFh ; or else disable SFX
	ld [_ADPM_SFXoverlay], a
SoundRun_KeepSFX:

	push ip
	ld a, [_GameSettings]
	bit a, #00000010b
	carl nz, _ADPM_RUN
	pop ip
	
	push ip
	ld a, [_GameSettings]
	bit a, #00000001b
	carl nz, _ADPMrunSFX
	pop ip
	
	ld a, [_GameSettings]
	and a, #00000011b
	cp a, #00000001b ; if only SFX is enabled, it's required that the sound is terminated when the sound effect ends
  jrs nz, SoundRun_SoundDone
	ld a, [_ADPM_SFXoverlay]
	inc a ; check if 0
  jrs nz, SoundRun_SoundDone
	ld [br:71h], a
SoundRun_SoundDone:
  ret

  
	
;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                      Pause State                      ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

; this menu have 2 states:
;   idle mode (only shows PAUSE)
;   menu mode (shows settings)

; differences being
;           idle        menu
; refresh   no          yes
; buttons   A, C, P     all
; cursor    no          yes


; pause loop structure:

; start
;   |
;   +------+
;   |      |
; idle    menu
;   |      |
;   +------+
;   |
;  common
;   |
;  end

; Pause flags:
; 0 pause mode (1: menu, 0: idle)
; 1 draw SOUND setting text
; 2 draw RUMBLE setting text
; 3 draw CONTRAST setting text
; 4 draw main menu banner
; 5 draw cursor
; 6 
; 7 
PauseGame:
;slp
	xor a, a
	ld [PauseCursorPos], a 
	ld a, #00010000b ; idle mode, update screen
	ld [PauseFlags], a
  jrl Pause_CommonCode


PauseLoop:
	ld a, [PauseFlags]
	bit a, #00000001b
	ld a, [br:52h]
  jrs nz, Pause_Menu


Pause_Idle:
	cp a, [LastInput]
  jrs z, Pause_IdleSkipInputs
	ld [LastInput], a
	ld b, a

	bit b, #00000100b ; C button
  jrs nz, Pause_IdleSkipC
  carl _DisplayBuffer
  carl _SoundRun
	halt
  jrl MainLoop
Pause_IdleSkipC:

	bit b, #00000001b
  jrs nz, Pause_IdleNoA
	ld a, [PauseFlags]
	or a, #00111111b
	ld [PauseFlags], a
Pause_IdleNoA:

Pause_IdleSkipInputs:



  jrl Pause_CommonCode	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Pause_Menu:
	cp a, [LastInput]
  jrl z, Pause_MenuSkipInputs
	ld [LastInput], a
	ld b, a
	
	bit b, #00000100b ; C button
  jrs nz, Pause_MenuSkipC
  carl _DisplayBuffer
  carl _SoundRun
	halt
  jrl MainLoop
Pause_MenuSkipC:
	
	bit b, #00000010b
  jrs nz, Pause_MenuNoB
	ld a, [PauseFlags]
	and a, #11111110b
	or a, #00010000b
	ld [PauseFlags], a
Pause_MenuNoB:

	bit b, #00001000b
  jrs nz, Pause_MenuNoUp
	ld hl, #PauseCursorPos
	dec [hl]
	and [hl], #00000011b
	ld hl, #PauseFlags
	or [hl], #00100000b
Pause_MenuNoUp:

	bit b, #00010000b
  jrs nz, Pause_MenuNoDown
	ld hl, #PauseCursorPos
	inc [hl]
	and [hl], #00000011b
	ld hl, #PauseFlags
	or [hl], #00100000b
Pause_MenuNoDown:

	bit b, #00100000b
  jrs nz, Pause_MenuNoLeft
	ld a, [PauseCursorPos]
	bit a, #00000010b
  jrs nz, Pause_MenuLeftSettings2ndHalf
	bit a, #00000001b
  jrs nz, Pause_MenuLeftRumble
	; or else SOUND
	ld hl, #PauseFlags
	or [hl], #00000010b
	ld hl, #_GameSettings
	ld a, [hl]
	and [hl], #11111100b
	inc a
	and a, #00000011b
  jrs nz, Pause_MenuLeftSoundNoMute
	ld [br:71h], #0
Pause_MenuLeftSoundNoMute:
	or [hl], a
  jrs Pause_MenuNoLeft
	
Pause_MenuLeftRumble:
	ld hl, #PauseFlags
	or [hl], #00000100b
	ld hl, #_GameSettings
	xor [hl], #00000100b
  jrs Pause_MenuNoLeft
	
Pause_MenuLeftSettings2ndHalf:
	bit a, #00000001b
  jrs nz, Pause_MenuNoLeft
	; or else contrast
	ld hl, #PauseFlags
	or [hl], #00001000b
	ld hl, #_GameContrast
	dec [hl]
	and [hl], #00111111b
	ld [br:0FEh], #10000001b
	ld [br:0FEh], [hl]
Pause_MenuNoLeft:



	bit b, #01000000b
  jrs nz, Pause_MenuNoRight
	ld a, [PauseCursorPos]
	bit a, #00000010b
  jrs nz, Pause_MenuRightSettings2ndHalf
	bit a, #00000001b
  jrs nz, Pause_MenuRightRumble
	; or else SOUND
	ld hl, #PauseFlags
	or [hl], #00000010b
	ld hl, #_GameSettings
	ld a, [hl]
	and [hl], #11111100b
	dec a
	and a, #00000011b
  jrs nz, Pause_MenuRightSoundNoMute
	ld [br:71h], #0
Pause_MenuRightSoundNoMute:
	or [hl], a
  jrs Pause_MenuNoRight
	
Pause_MenuRightRumble:
	ld hl, #PauseFlags
	or [hl], #00000100b
	ld hl, #_GameSettings
	xor [hl], #00000100b
  jrs Pause_MenuNoRight
	
Pause_MenuRightSettings2ndHalf:
	bit a, #00000001b
  jrs nz, Pause_MenuNoRight
	; or else contrast
	ld hl, #PauseFlags
	or [hl], #00001000b
	ld hl, #_GameContrast
	inc [hl]
	and [hl], #00111111b
	ld [br:0FEh], #10000001b
	ld [br:0FEh], [hl]
Pause_MenuNoRight:

	bit b, #00000001b
  jrs nz, Pause_MenuNoA
	ld a, [PauseCursorPos]
	cp a, #3
  jrs nz, Pause_MenuNoA
	slp
;  jrl MainMenuLoop
Pause_MenuNoA:



Pause_MenuSkipInputs:

; draw menu cursor
	ld hl, #PauseFlags
	bit [hl], #00100000b
  jrs z, Pause_SkipCursorDraw
	and [hl], #11011111b
	
	; clear cursor area first
	ld ix, #20FFh
	ld iy, #20FEh
	ld hl, #0FF00h
	ld a, #10110010b
	ld [iy], #00010011b

	ld [iy], a ; set page
	ld [iy], hl
	ld [ix], h
	ld [ix], h
	inc a
	ld [iy], a ; set page
	ld [iy], hl
	ld [ix], h
	ld [ix], h
	inc a
	ld [iy], a ; set page
	ld [iy], hl
	ld [ix], h
	ld [ix], h
	inc a
	ld [iy], a ; set page
	ld [iy], hl
	ld [ix], h
	ld [ix], h
;	inc a
	
	; print cursor at position
	ld [iy], l ; set col
	ld a, [PauseCursorPos]
	add a, #10110010b
	ld [iy], a
	
	ld [ix], #10000001b
	ld [ix], #11000011b
	ld [ix], #11100111b
Pause_SkipCursorDraw:






; draw menu settings

	; draw sound setting
	ld hl, #PauseFlags
	bit [hl], #00000010b
  jrs z, Pause_SkipDrawSound
	and [hl], #11111101b
	ld [br:0FEh], #10110010b
	ld [br:0FEh], #00010011b
	ld [br:0FEh], #5
	
	ld hl, #38
	ld a, [_GameSettings]
	and a, #00000011b
	mlt
	ld ix, #PauseSoundSettingsText
	add ix, hl
	ld b, #38
  carl Pause_CopyPage
Pause_SkipDrawSound:



	; draw rumble setting
	ld hl, #PauseFlags
	bit [hl], #00000100b
  jrs z, Pause_SkipDrawRumble
	and [hl], #11111011b
	ld [br:0FEh], #10110011b
	ld [br:0FEh], #00010011b
	ld [br:0FEh], #5
	
	ld a, [_GameSettings]
	bit a, #00000100b
	ld ix, #PauseRumbleSettingON
  jrs nz, Pause_RumbleSettingDispOn
	ld ix, #PauseRumbleSettingOFF	
Pause_RumbleSettingDispOn:
	ld b, #11
  carl Pause_CopyPage
Pause_SkipDrawRumble:



	; draw contrast setting
	ld hl, #PauseFlags
	bit [hl], #00001000b
  jrs z, Pause_SkipDrawContrast
	and [hl], #11110111b
	ld [br:0FEh], #10110100b
	ld [br:0FEh], #00010011b
	ld [br:0FEh], #5
	
	ld ix, #GFX_NumbersWhite
	ld a, [_GameContrast]
	swap a
	and a, #0Fh
  carl PrintNum
	ld a, [_GameContrast]
	and a, #0Fh
  carl PrintNum
Pause_SkipDrawContrast:


Pause_CommonCode:

	; draw/redraw pause banner
	ld a, [PauseFlags]
	bit a, #00010000b
  jrs z, Pause_NoBannerRefresh
	and a, #11101111b
	ld [PauseFlags], a ; clear flag back
	bit a, #00000001b
	ld ix, #PauseBannerIdle
  jrs z, Pause_DrawIdleBanner
	ld ix, #PauseBannerMenu
Pause_DrawIdleBanner:
	ld [br:0FEh], #10110010b
  carl Pause_CopyPageFull
	ld [br:0FEh], #10110011b
  carl Pause_CopyPageFull
	ld [br:0FEh], #10110100b
  carl Pause_CopyPageFull
	ld [br:0FEh], #10110101b
  carl Pause_CopyPageFull
Pause_NoBannerRefresh:

	; custom-made video copy routine
	ld iy, #StripeDta
	ld hl, #GameFlags ; update frame parity
	xor [hl], #00000010b
	bit [hl], #00000010b
  jrs z, Pause_FrameIsEven
	add iy, #200h
Pause_FrameIsEven:
	
	ld [br:0FEh], #10110000b
  carl PageCopy
	add iy, #32
	ld [br:0FEh], #10110001b
  carl PageCopy
	add iy, #32+32+32+32+32
 	ld [br:0FEh], #10110110b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110111b
	ld a, [GameFlags]
	bit a, #00010000b
  jrs z, Pause_NoScoreWindow
  carl PageCopy
  jrs Pause_VideoCopyDone

Pause_NoScoreWindow:
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
  carl PageCopy_CopyPartialProgressBar
Pause_VideoCopyDone:
	
  carl _SoundRun
	halt
  jrl PauseLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Pause_CopyPageFull:
	ld b, #96
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
Pause_CopyPage:
	ld [br:0FFh], [ix]
	inc ix
  djr nz, Pause_CopyPage
  ret



;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                 Level Data Processor                  ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

_CalcObj:
	ld a, [br:52h]
	bit a, #2
  jrl z, DEBUG_SkipObjCalc

; decrement spawn count
	ld hl, #ObjSpawnWait
	dec [hl]
  jrl nz, ObjGen_StepFrame
	ld [hl], #16

; set flag for the main loop's level state track function
	ld hl, #GameFlags
	or [hl], #00001000b ; step flag on
; todo: flip the left steer sprites

; begin spawn obj process
	ld ix, #ObjState6
	ld b, #7
ObjGen_MoveBuffer:
	ld hl, [ix]
	ld [ix+4], l
	ld [ix+5], h
	add ix, #2
	ld hl, [ix]
	ld [ix+4], l
	ld [ix+5], h
	sub ix, #6

  djr nz, ObjGen_MoveBuffer
	ld hl, #ObjState0
	sub [hl], #10h

; check if dummy mode is on
	ld hl, #GameFlags
	bit [hl], #00000100b
  jrs nz, ObjGen_SpawnBlank

; decrement objwait
	ld hl, #ObjWait
	dec [hl]
  jrs nz, ObjGen_SpawnBlank

; grab obj data
	ld ix, [LevelDtaPointer]
	ld a, [ix] ; get wait and type
	ld b, a
	and a, #00111111b
	inc a
	ld [ObjWait], a
	
	ld l, [ix+1]
	ld h, [ix+2]
	and b, #11000000b
	rlc b
	rlc b
	ld a, b
	
	add ix, #3
	ld [LevelDtaPointer], ix

ObjGen_WriteNew:
	ld [ObjState0+1], a
	ld [ObjState0+2], hl


ObjGen_StepFrame:
	ld hl, #ObjState0	
	ld b, #8h
ObjGen_CalcLoop:
	inc [hl]
	add hl, #4
  djr nz, ObjGen_CalcLoop
DEBUG_SkipObjCalc:
  ret
	
ObjGen_SpawnBlank:
	ld hl, #0
	ld a, l
  jrs ObjGen_WriteNew

InitObjBuffer:
	ld hl, #0080h
	ld [ObjState0], hl
	ld hl, #0002h
	ld [ObjState1], hl
	ld [ObjState2], hl
	ld [ObjState3], hl
	ld [ObjState4], hl
	ld [ObjState5], hl
	ld [ObjState6], hl
	ld [ObjState7], hl
  ret

InitLevel:
	ld a, #1
	ld [ObjWait], a
	ld a, [CurrentLevel]
	ld hl, #_LevelList
	add a, a
	ld b, #0
	ld [LevelTime], b
	add hl, ba
	ld hl, [hl]
	ld a, [hl]
	inc hl
	ld [LevelDtaPointer], hl
;	ld hl, #GameFlags
;	and [hl], #11111011b ; disable dummy mode
	
	ld hl, #09992h
	ld [LevelTimeBCDlow], hl
	
	cp a, [CurrentSong]
  jrs z, LevelInitDone
	ld [CurrentSong], a
	ld b, #0
	add ba, ba
	add ba, ba
	ld ix, #_SongList
	add ix, ba
	ld a, [ix+2] ; bank
	ld ix, [ix] ; song list pointer
	
	push ip
  carl _ADPM_SETUP
	pop ip
LevelInitDone:
  ret

;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                   Rendering Stage                     ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

_RenderGameState:
	; stage 1: initialize buffer
	ld ba, #0
	ld [StripBuffer+0], ba
	ld [StripBuffer+2], ba
	ld [StripBuffer+4], ba
	ld [StripBuffer+6], ba
	ld [StripBuffer+8], ba
	ld [StripBuffer+10], ba
	ld [StripBuffer+12], ba
	ld [StripBuffer+14], ba
	ld [StripBuffer+16], ba
	ld [StripBuffer+18], ba
	ld [StripBuffer+20], ba
	ld [StripBuffer+22], ba
	ld [StripBuffer+24], ba
	ld [StripBuffer+26], ba
	ld [StripBuffer+28], ba
	ld [StripBuffer+30], ba
	ld [StripBuffer+32], ba
	ld [StripBuffer+34], ba
	ld [StripBuffer+36], ba
	ld [StripBuffer+38], ba
	ld [StripBuffer+40], ba
	ld [StripBuffer+42], ba
	ld [StripBuffer+44], ba
	ld [StripBuffer+46], ba
	ld [StripBuffer+48], ba
	ld [StripBuffer+50], ba
	ld [StripBuffer+52], ba
	ld [StripBuffer+54], ba
	ld [StripBuffer+56], ba
	ld [StripBuffer+58], ba
	ld [StripBuffer+60], ba
	ld [StripBuffer+62], ba
	ld [StripBuffer+64], ba
	ld [StripBuffer+66], ba
	ld [StripBuffer+68], ba
	ld [StripBuffer+70], ba
	ld [StripBuffer+72], ba
	ld [StripBuffer+74], ba
	ld [StripBuffer+76], ba
	ld [StripBuffer+78], ba
	ld [StripBuffer+80], ba
	ld [StripBuffer+82], ba
	ld [StripBuffer+84], ba
	ld [StripBuffer+86], ba
	ld [StripBuffer+88], ba
	ld [StripBuffer+90], ba
	ld [StripBuffer+92], ba
	ld [StripBuffer+94], ba
	ld [StripBuffer+96], ba
	; you are looking at precisely 248 cycles and 150 bytes
	
	
	; stage 2: calculate walls and fill buffer
	ld a, #8
	ld [temp], a
;	ld a, [ObjRef]
;	sub a, #07h
;	and a, #0Fh
	ld a, #0
	ld [temp2], a
ObjCalc:
	; get to the ObjRef objects, since they're visible
	ld a, [temp2]
	ld ix, #ObjState0
	ld b, #0
	add a, a
	add a, a
	add ix, ba
	
	; get Obj position and transform it into a perspective line
	; dividend: constant 000200h
	; divisor: object's lifetime (80h ~ FFh)
	
	ld hl, #0002h ; divide high+mid
	ld a, [ix]
	neg a
	inc a
	div
	ld [temp4+1], l
	ld l, #0 ; divide mid+low
	div
	ld a, l
	ld [temp4], a
	
	
	
	; generate right reference line
	ld a, #0
	sub a, [PlayerPos]
	ld l, [temp4]
	mlt
	ld b, h
	ld [temp5low], l
	ld l, [temp4+1]
	mlt
	
	ld a, b
	ld b, #0
	add hl, ba
	ld a, [temp5low]
	add a, a
	adc hl, hl
	ld ba, hl
	
	ld hl, #7FFFh
	sub hl, ba
	ld [temp5], hl



	; generate left reference line
	ld a, [PlayerPos]
	ld l, [temp4]
	mlt
	ld b, h
	ld [temp6low], l
	ld l, [temp4+1]
	mlt
	
	ld a, b
	ld b, #0
	add hl, ba
	ld a, [temp6low]
	add a, a
	adc hl, hl
	
	add hl, #8000h
	ld [temp6], hl
	
	
	
	; clip wall size
	ld hl, [temp4]
	cp hl, #32
  jrs c, WallInRange
	ld hl, #31
WallInRange:
	ld [temp3], l
	
	
	; scale aperture parameter if obj type is not 0
	ld a, [ix+1]
	or a, a
  jrs z, RenderStageBegin
	ld ba, [temp5]
	ld hl, [temp6]
	sub hl, ba
	ld iy, hl
	ld b, h
	ld a, [ix+2] ; offset
	mlt
	ld l, b
	ld b, h
	mlt
	ld a, b
	ld b, #0
	add hl, ba
	ld ba, [temp5]
	add hl, ba
	inc hl
	ld [temp7], hl
	
	
;	ld ba, [temp5]
;	ld hl, [temp6]
;	sub hl, ba
	ld hl, iy
	ld a, [ix+3] ; aperture
	ld b, h
	mlt
	ld l, b
	ld b, h
	mlt
	ld a, b
	ld b, #0
	add hl, ba
	ld ba, [temp5]
	add hl, ba
	inc hl
	ld [temp8], hl
	
	
RenderStageBegin:
	; scale point values into 0-97 screen range
	; left ref line
	ld hl, [temp5]
	cp hl, #7FCFh
  jrs nc, Render_RefLinLeftNotBelowRange
	ld l, #0
  jrs Render_RefLinLeftDone
Render_RefLinLeftNotBelowRange:
	cp hl, #8031h
  jrs c, Render_RefLinLeftNotAboveRange
	ld l, #97
  jrs Render_RefLinLeftDone
Render_RefLinLeftNotAboveRange:
	sub hl, #7FCFh
Render_RefLinLeftDone:
	ld [RefLeftScaled], l
	
	
	
	; right ref line
	ld hl, [temp6]
	cp hl, #7FCFh
  jrs nc, Render_RefLinRightNotBelowRange
	ld l, #0
  jrs Render_RefLinRightDone
Render_RefLinRightNotBelowRange:
	cp hl, #8031h
  jrs c, Render_RefLinRightNotAboveRange
	ld l, #97
  jrs Render_RefLinRightDone
Render_RefLinRightNotAboveRange:
	sub hl, #7FCFh
Render_RefLinRightDone:
	ld [RefRightScaled], l
	
	
	
	; render ref lines
	ld a, [ix]
	cp a, #7Fh
  jrs c, Render_SkipRefLines
	ld iy, #StripBuffer
	ld a, [temp3]
	ld [iy+l], a
	
	ld l, [RefLeftScaled]
	ld [iy+l], a
Render_SkipRefLines:

	
	; scale and render walls if Obj type is not 0
	ld a, [ix+1]
	or a, a
  jrl z, ObjCalcDone
	ld hl, [temp7] ; scale wall start
	cp hl, #7FCFh
  jrs nc, Render_AprLeftNotBelowRange
	ld l, #0
  jrs Render_AprLeftDone
Render_AprLeftNotBelowRange:
	cp hl, #8031h
  jrs c, Render_AprLeftNotAboveRange
	ld l, #97
  jrs Render_AprLeftDone
Render_AprLeftNotAboveRange:
	sub hl, #7FCFh
Render_AprLeftDone:
	ld [AprLeftScaled], l
	
	; scale wall end
	ld hl, [temp8]
	cp hl, #7FCFh
  jrs nc, Render_AprRightNotBelowRange
	ld l, #0
  jrs Render_AprRightDone
Render_AprRightNotBelowRange:
	cp hl, #8031h
  jrs c, Render_AprRightNotAboveRange
	ld l, #97
  jrs Render_AprRightDone
Render_AprRightNotAboveRange:
	sub hl,#7FCFh
Render_AprRightDone:
	ld [AprRightScaled], l
	
	; which wall type?
	ld iy, #StripBuffer
	cp a, #1
  jrs z, Render_StripWall
; aperture wall: renders between points A to B and C to D
;	|::::::::|  |::::|
	ld b, [RefLeftScaled]
	ld a, [AprLeftScaled]
	ld h, #0
	ld l, b
	sub a, b
  jrs z, RenderAperture_2ndLoop
	ld b, a
	ld a, [temp3]
	add hl, iy
;RenderAperture_RenderWallLoop1:
	ld [hl], a
	inc hl
db 0F5h, 0FDh
;  djr nz, RenderAperture_RenderWallLoop1
	
RenderAperture_2ndLoop:
	ld b, [AprRightScaled]
	ld a, [RefRightScaled]
	ld h, #0
	ld l, b
	sub a, b
  jrs z, ObjCalcDone
	ld b, a
	ld a, [temp3]
	add hl, iy
;RenderAperture_RenderWallLoop2:
	ld [hl], a
	inc hl
;  djr nz, RenderAperture_RenderWallLoop2
db 0F5h, 0FDh
  jrs ObjCalcDone
	
Render_StripWall:
; strip wall: renders between points B to C	
;	|        |::|    |
	ld ba, [AprLeftScaled]
	ex a, b
	ld l, b
	ld h, #0
	sub a, b
  jrs z, ObjCalcDone ; zero width means either bad wall data or two clipped wall points
	ld b, a
	ld a, [temp3]
	add hl, iy
;RenderStrip_RenderWallLoop:
	ld [hl], a
	inc hl
db 0F5h, 0FDh
;  djr nz, RenderStrip_RenderWallLoop

	
ObjCalcDone:
	ld a, [temp2]
	inc a
	and a, #0Fh
	ld [temp2], a
	ld a, [temp]
	dec a
	ld [temp], a
  jrl nz, ObjCalc
  ret



;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                  Number Font Display                  ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
; inputs:
; ix: base
; a: number
PrintNum:
	ld b, #0
	add a, a
	add a, a
	ld iy, ix
	add iy, ba
	ld b, #4
Num_PrintCopy:
	ld a, [iy]
	inc iy
	ld [br:0FFh], a
  djr nz, Num_PrintCopy
  ret


;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                  Video Display/Copy                   ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
_DisplayBuffer:
	; stage 3: read buffer output and draw to screen
	ld iy, #StripeDta
	ld a, [SpritePage]
	ld hl, #GameFlags
	xor [hl], #00000010b
	bit [hl], #00000010b
  jrs z, Render_FrameIsEven
	add iy, #200h
	add a, #3
Render_FrameIsEven:
	ld [SpritePageTemp], a

	ld hl, #GameFlags
	bit [hl], #00000001b
  jrl z, Draw_FullScreenNoSprite

; or else draw with dawn's sprite masked in the center
	ld [br:0FEh], #10110000b
  carl PageCopy
	add iy, #32

	ld [br:0FEh], #10110001b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110010b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110011b
  carl PageCopy
	add iy, #32

 	ld [br:0FEh], #10110100b
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
  carl CopyPagePartial
	ld h, [SpritePageTemp]
	ld b, [SpriteIndex]
  carl CopyWithSpriteMask
  carl CopyPagePartial
	add iy, #32

 	ld [br:0FEh], #10110101b
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
  carl CopyPagePartial
	inc h
	ld b, [SpriteIndex]
  carl CopyWithSpriteMask
  carl CopyPagePartial
	add iy, #32

 	ld [br:0FEh], #10110110b
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
  carl CopyPagePartial
	inc h
	ld b, [SpriteIndex]
  carl CopyWithSpriteMask
  carl CopyPagePartial
	add iy, #32

 	ld [br:0FEh], #10110111b
	ld a, [GameFlags]
	bit a, #00010000b
  jrs z, RenderCopy_NoScoreWindow
  carl PageCopy
  ret



Draw_FullScreenNoSprite:
	ld [br:0FEh], #10110000b
  cars PageCopy
	add iy, #32

	ld [br:0FEh], #10110001b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110010b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110011b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110100b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110101b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110110b
  cars PageCopy
	add iy, #32

 	ld [br:0FEh], #10110111b
	ld a, [GameFlags]
	bit a, #00010000b
  jrs z, RenderCopy_NoScoreWindow
  cars PageCopy
  ret

RenderCopy_NoScoreWindow:
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b
  carl PageCopy_CopyPartialProgressBar
  ret

PageCopy:
	ld ix, #StripBuffer+1
	ld [br:0FEh], #0
	ld [br:0FEh], #00010000b

	; 6 bytes each interation
	; unrolling this 96x is 576 bytes
	
	; correction: 9 bytes each iteration   -   9*96 = 864 bytes for this full copy
	; each iteration is 3 + 2 + 4 + 3 + 2 = 14 cycles   -   96*14 = 1344 cycles for this full copy
	; *8 = 10752 cycles for all 8 pages (assuming no sprite), which is nearly half the frame cycle count of ~27777 cycles (1MHz / 36Hz)

PageCopy_LoopBase:
	; offset = base + bannerscroll * 9
	; if offset even = jump as-is; else add 3 to offset and jump

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a

	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
PageCopy_CopyPartialProgressBar:
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	
	
	
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

CopyPagePartial:
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	
	
	
	
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	ld [br:0FFh], a
	inc ix
  ret



CopyWithSpriteMask:
; sprite data format: | MASK | GFX  | MASK | GFX  | ...

; the sprite is 3 pages tall, 16 strips wide (48 strips)

; iteration where sprite is drawn: 3 + 2 + 4 + 3 + 2 + 1 + 2 + 2 + 1 + 2 + 2 + 2 + 2 + 3 + 2 = 33 cycles

; iteration where sprite is hidden: 3 + 2 + 4 + 3 + 2 + 2 + 2 + 3 + 2 = 23 cycles

; 
; 80 * normal lines = 1120
; 16 * sprite drawn lines = 528
; 1648 cycles for a page with a sprite segment visible
; screen with sprite = 3 sprite + 5 normal
; (1344 * 5) + (1648 * 3) = 6720 + 4944 = 11664 cycles for a frame with a fully visible sprite


	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h ; avoiding the auto-inserted NB register load
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	add iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix

	sub iy, #0100h
	ld l, [ix]
	ld a, [iy+l]
	cp l, #1Fh
;  jrs z, NoMask
db 0E6h, 007h
	ld l, b
	and a, [hl]
	inc b
	ld l, b
	or a, [hl]
	dec b
;NoMask:
	inc b
	inc b
	ld [br:0FFh], a
	inc ix
  ret




;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                      RAM Space                        ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

	DEFSECT "RAMDATA", DATA
	SECT "RAMDATA"
	; byte 1: duration, 0 = backmost, FF = frontmost, the wall is only visible when this hits 80h
	; byte 2: OBJ type, 0 = reference lines only (empty), 1 = strip wall, 2 = aperture wall
	; byte 3: OBJ wall offset, 0 = on left side reference line, FF = on right side reference line
	; byte 4: OBJ wall length or aperture size, 0 = no wall or no aperture, FF = full wall or full aperture
	
	
ObjState0: ds 4
ObjState1: ds 4
ObjState2: ds 4
ObjState3: ds 4
ObjState4: ds 4
ObjState5: ds 4
ObjState6: ds 4
ObjState7: ds 4

; note that there's only 8 visible walls on screen at once, so the rendering program only accounts for 8 of them
	
; rendering stage vars
temp:		ds 1 ; loop counter 
temp2:		ds 1 ; Obj offset
temp3:		ds 1 ; wall depth
temp4:      ds 2 ; perspective depth
temp5low:   ds 1 ; left ref line
temp5:      ds 2
temp6low:   ds 1 ; right ref line
temp6:      ds 2
temp7:      ds 2 ; wall begin
temp8:      ds 2 ; wall end
RefLeftScaled:  ds 1 ; Point A
RefRightScaled: ds 1 ; Point D
AprLeftScaled:  ds 1 ; Point B
AprRightScaled: ds 1 ; Point C

; player controller
PlayerPos:	ds 1
LastPos:    ds 1
LastInput:  ds 1
;ObjRef: 	ds 1

; level data and state vars
ObjSpawnWait:    ds 1 ; temporary
ObjWait:         ds 1
CalcObjCount:    ds 1
LevelTime:       ds 1 ; counts the 200 Obj untill level end
LevelTimeBCDlow: ds 1
LevelTimeBCDhigh:ds 1
LevelChangeWait: ds 1 ; waits for the Obj buffer to empty untill next level starts
CurrentLevel:    ds 1
CurrentSong:     ds 1
LevelDtaPointer: ds 2

ObjEmptyOutCount: ds 1

; on-death counters
DeadFrameCount:      ds 1 
ExplosionAnimCount:  ds 1

; banner frame counters
BannerFrameCount:    ds 1
BannerScrollPos:     ds 1
BannerCurrNumber:    ds 1

; misc bytes
WaitFramesCount:     ds 1
EndingFadeCount:     ds 1

; pause screen
PauseCursorPos:     ds 1
PauseFlags:         ds 1

; global settings
_GameSettings:    ds 1 ; 0: Music ON, 1: SFX ON, 2: Rumble ON
_GameContrast:    ds 1 ; range from decimal 0 to 64

; rendering state and control
GameFlags:       ds 1 ; 0: frame parity, 1: display sprite, 2: ObjGen dummy mode, 3: ObjGen Count Event, 4: hide score window, 5: skip render
SpritePage:      ds 1
SpritePageTemp:  ds 1
SpriteIndex:     ds 1
StripBuffer:     ds 98 