	DEFSECT "Levels", CODE
	SECT "Levels"



;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                      Level Data                       ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

GLOBAL _LevelList


_LevelList:
dw Level1Data
dw Level2Data
dw Level3Data
dw Level4Data
dw Level5Data
dw Level6Data

; level format:
; header: 1 byte for music list index
; data: variable, constitutes of 3-byte events
; there is no end command, the level is always a fixed size

; TTWWWWWW LLLLLLLL RRRRRRRR

Level1Data:
db 00h ; song 1: Towards The Core


;db 003h, 000h, 000h
db 040h, 000h, 0A0h
db 040h, 060h, 0A0h
db 042h, 060h, 0A0h
db 040h, 07Eh, 082h

db 042h, 050h, 090h
db 042h, 050h, 090h
db 048h, 050h, 090h

db 042h, 008h, 018h
db 042h, 008h, 028h
db 048h, 008h, 038h

db 042h, 0D8h, 0F8h
db 042h, 0C8h, 0F8h
db 048h, 0B8h, 0F8h

db 086h, 020h, 0E0h

db 03Fh, 000h, 000h
db 03Fh, 000h, 000h
db 03Fh, 000h, 000h
db 03Fh, 000h, 000h

Level2Data:
db 00h ; song 1: Towards The Core
db 040h, 000h, 090h
db 03Fh, 000h, 000h
Level3Data:
db 00h ; song 1: Towards The Core
db 040h, 010h, 090h
db 03Fh, 000h, 000h
Level4Data:
db 00h ; song 1: Towards The Core
db 040h, 020h, 090h
db 03Fh, 000h, 000h
Level5Data:
db 00h ; song 1: Towards The Core
db 040h, 030h, 090h
db 03Fh, 000h, 000h
Level6Data:
db 00h ; song 1: Towards The Core
db 040h, 040h, 090h
db 03Fh, 000h, 000h




