DEFSECT "VectorTable", CODE AT 2100h
SECT "VectorTable"

ascii "MN" ; weird marker 1
GLOBAL __START

	ld nb, #@DPAG(__START)
  jrl __START
  
	ld nb, #@DPAG(_IRQ_VideoCopy)
  jrl _IRQ_VideoCopy
  
	ld nb, #@DPAG(_IRQ_VideoRender)
  jrl _IRQ_VideoRender
  
	ld nb, #@DPAG(_IRQ_Tim2Low)
  jrl _IRQ_Tim2Low
  
	ld nb, #@DPAG(_IRQ_Tim2High)
  jrl _IRQ_Tim2High
  
	ld nb, #@DPAG(_IRQ_Tim1Low)
  jrl _IRQ_Tim1Low
  
	ld nb, #@DPAG(_IRQ_Tim1High)
  jrl _IRQ_Tim1High
  
	ld nb, #@DPAG(_IRQ_SoundTimReload)
  jrl _IRQ_SoundTimReload
  
	ld nb, #@DPAG(_IRQ_SoundTimComMatch)
  jrl _IRQ_SoundTimComMatch
  
	ld nb, #@DPAG(_IRQ_RTCTim32Hz)
  jrl _IRQ_RTCTim32Hz
  
	ld nb, #@DPAG(_IRQ_RTCTim8Hz)
  jrl _IRQ_RTCTim8Hz
  
	ld nb, #@DPAG(_IRQ_RTCTim2Hz)
  jrl _IRQ_RTCTim2Hz
  
	ld nb, #@DPAG(_IRQ_RTCTim1Hz)
  jrl _IRQ_RTCTim1Hz
  
	ld nb, #@DPAG(_IRQ_InfraredRX)
  jrl _IRQ_InfraredRX
  
	ld nb, #@DPAG(_IRQ_ShakeDetect)
  jrl _IRQ_ShakeDetect
  
	ld nb, #@DPAG(_IRQ_ButtonPower)
  jrl _IRQ_ButtonPower
  
	ld nb, #@DPAG(_IRQ_DpadRight)
  jrl _IRQ_DpadRight
  
	ld nb, #@DPAG(_IRQ_DpadLeft)
  jrl _IRQ_DpadLeft
  
	ld nb, #@DPAG(_IRQ_DpadDown)
  jrl _IRQ_DpadDown
  
	ld nb, #@DPAG(_IRQ_DpadUp)
  jrl _IRQ_DpadUp
  
	ld nb, #@DPAG(_IRQ_ButtonC)
  jrl _IRQ_ButtonC
  
	ld nb, #@DPAG(_IRQ_ButtonB)
  jrl _IRQ_ButtonB
  
	ld nb, #@DPAG(_IRQ_ButtonA)
  jrl _IRQ_ButtonA
  
	ld nb, #@DPAG(_IRQ_Unknown1)
  jrl _IRQ_Unknown1
  
	ld nb, #@DPAG(_IRQ_Unknown2)
  jrl _IRQ_Unknown2
  
	ld nb, #@DPAG(_IRQ_Unknown3)
  jrl _IRQ_Unknown3
  
	ld nb, #@DPAG(_IRQ_External)
  jrl _IRQ_External

; magic marker to validate cartridge
ascii "NINTENDO"

; game code, must be 4 bytes, i have no clue what the codes are but this is 4 bytes long
ascii "DAWN"
;      1234

; game title, must be exactly 12 chars
ascii "MAINFRAME   " 
;      123456789111
;               012

ascii "2P" ; weird marker 2

; reserved 18 zero bytes (huh?)
db 00, 00, 00, 00
db 00, 00, 00, 00
db 00, 00, 00, 00
db 00, 00, 00, 00
db 00, 00










DEFSECT "InterruptDestinations", CODE
SECT "InterruptDestinations"

_IRQ_VideoCopy:
	ld [br:27h], #11111111b
	ld [br:20h], #11000000b
  rete
	
_IRQ_VideoRender:
_IRQ_Tim2Low:
_IRQ_Tim2High:
  rete

_IRQ_Tim1High:
_IRQ_Tim1Low:
	ld [br:27h], #11111111b ; clear interrupt flag
	ld [br:20h], #11111111b ; reset interrupt priority
;	ld a, [GameFlags]
  jrl _MainLoopRender
;  rete
_IRQ_SoundTimReload:
_IRQ_SoundTimComMatch:
_IRQ_RTCTim32Hz:
_IRQ_RTCTim8Hz:
_IRQ_RTCTim2Hz:
_IRQ_RTCTim1Hz:
_IRQ_InfraredRX:
_IRQ_ShakeDetect:
_IRQ_ButtonPower:
_IRQ_DpadRight:
_IRQ_DpadLeft:
_IRQ_DpadDown:
_IRQ_DpadUp:
_IRQ_ButtonC:
_IRQ_ButtonB:
_IRQ_ButtonA:
_IRQ_Unknown1:
_IRQ_Unknown2:
_IRQ_Unknown3:
_IRQ_External:
  rete

EXTERN GameFlags
EXTERN _MainLoopRender
EXTERN EndingRender
