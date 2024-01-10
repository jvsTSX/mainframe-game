DEFSECT "Music_Sound", CODE
SECT "Music_Sound"

GLOBAL _SongList

_SongList:
dw SongData
db @dpag(SongData), 0




;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                     Music Data                        ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------
SongData:
; HEADER -----------
dw timeline2
dw phrasesIndex2
dw instrumentsIndex2
dw macrosIndex2
dw groovetable2
db 00h ; song speed



; INSTRUMENTS ------
instrumentsIndex2:
dw ins20
dw ins21
dw ins22

instrumentsData2:
ins20:
db  0FFh, 40h, 11011000b, 01h, 02h, 040h, 0C0h
ins21:
db 02h, 10h, 11011000b, 01h, 02h, 0A0h, 40h
ins22:
db  03h, 80h, 11001000b


; MACROS -----------
macrosIndex2:
dw Gmacro20
dw Gmacro21
dw Gmacro22
dw Gmacro23

macrosData2:
Gmacro20: ; drum
db 11011111b, 20h, 7Fh
db 10011110b, 18h, 7Fh
db 10011110b, 14h, 7Fh
db 10000010b
db 01h

Gmacro21:;  drum + arp
db 11011111b, 20h, 7Fh
db 10011110b, 18h, 7Fh
db 10011110b, 14h, 7Fh
db 10001010b, 00Ch
db 10001010b, 000h
db 00h, 05h

Gmacro22: ; arp
db 10001010b, 000h
db 10001010b, 00Ch
db 00h, 05h

Gmacro23: ; pluck
db 10001010b, 00Ch
db 10001010b, 000h
db 01h


; GROOVE -----------
groovetable2:
db 03h
db 03h
db 03h
db 02h
db 0FFh, 00h



; TIMELINE ---------
timeline2:

db 00h, 00h
db 00h, 00h
db 00h, 00h
db 01h, 00h
db 00h, 00h
db 00h, 00h
db 00h, 00h
db 01h, 00h
db 02h, 00h
db 03h, 00h
db 04h, 00h
db 08h, 00h
db 06h, 00h
db 07h, 00h
db 04h, 00h
db 05h, 00h

db 09h, 00h
db 0Ah, 00h
db 0Bh, 00h
db 0Ah, 00h
db 0Ch, 00h

db 00h, 00h
db 00h, 00h
db 00h, 00h
db 01h, 00h
db 00h, 00h
db 00h, 00h
db 00h, 00h
db 01h, 00h
db 02h, 00h
db 03h, 00h
db 04h, 00h
db 08h, 00h
db 06h, 00h
db 07h, 00h
db 04h, 00h
db 05h, 00h

db 0Dh, 00h
db 0Dh, 00h
db 0Dh, 00h
db 0Eh, 00h
db 0Dh, 00h
db 0Dh, 00h
db 0Dh, 00h
db 0Eh, 00h
db 0Fh, 00h
db 10h, 00h
db 0Fh, 00h
db 11h, 00h

db 02h, 00h
db 03h, 00h
db 04h, 00h
db 05h, 00h
db 06h, 00h
db 03h, 00h
db 04h, 00h
db 05h, 00h

db 12h


; PHRASES ----------
phrasesIndex2:
dw phra20
dw phra21
dw phra22
dw phra23
dw phra24
dw phra25
dw phra26
dw phra27
dw phra28
dw phra29
dw phra2A
dw phra2B
dw phra2C
dw phra2D
dw phra2E
dw phra2F
dw phra210
dw phra211
dw phra212

phrasesData2:
phra20:
db 01h,  0Dh, 00h,    50h, 00h

db 01h,  8Dh

db 00h,  99h,         50h, 00h
db 01h,  97h

db 00h,  94h
db 01h,  8Dh,         50h, 00h

db 01h,  8Dh

db 01h,  97h,         50h, 00h

db 01h,  99h

db 11h


phra21:
db 01h,  0Dh, 00h,    50h, 00h

db 01h,  8Dh

db 00h,  97h,         50h, 00h
db 01h,  8Dh

db 00h,  94h
db 20h,               50h, 00h
db 00h,  97h
db 01h,  94h

db 20h,               50h, 00h
db 00h,  97h
db 01h,  99h

db 11h


phra22:
db 01h,  25h, 00h,    50h, 00h

db 01h,  8Dh

db 01h, 0A0h,         50h, 00h

db 01h, 0A8h

db 03h,  8Dh,         50h, 00h



db 03h, 0A7h,         50h, 00h

db 11h


phra23:
db 03h, 0A8h,         50h, 00h



db 03h, 090h,         50h, 00h



db 03h, 090h,         50h, 00h



db 03h, 090h,         50h, 00h



db 11h


phra24:
db 03h, 0A7h,         50h, 00h



db 01h, 8Fh,          50h, 00h

db 01h, 0A3h

db 21h,               50h, 00h

db 01h,  8Fh

db 03h, 0A8h,         50h, 00h




db 11h


phra25:
db 01h, 0A7h,         50h, 00h

db 01h, 08Bh

db 01h, 0A3h,         50h, 00h

db 01h, 08Bh

db 01h, 09Eh,         50h, 00h

db 01h, 08Bh

db 01h, 09Bh,         50h, 00h

db 01h, 08Bh

db 11h


phra26:
db 01h,  25h, 00h,    50h, 00h

db 01h,  8Dh

db 01h, 0A0h,         50h, 00h

db 01h, 0A8h

db 03h,  8Dh,         50h, 00h



db 03h, 0AAh,         50h, 00h

db 11h


phra27:
db 03h, 0A8h,         50h, 00h



db 03h,  90h,         50h, 00h



db 01h,  99h,         50h, 00h

db 01h,  9Bh

db 01h,  9Ch,         50h, 00h

db 01h,  9Eh

db 11h


phra28:
db 01h, 0A7h,         50h, 00h

db 01h, 08Bh

db 01h, 0A3h,         50h, 00h

db 01h, 08Bh

db 01h, 09Eh,         50h, 00h

db 01h, 08Bh

db 01h, 0A3h,         50h, 00h

db 01h, 08Bh

db 11h


phra29:
db 01h, 0A5h,         50h, 00h

db 01h, 0A3h

db 01h, 0A5h,         50h, 00h

db 01h, 0A8h

db 01h, 0A5h,         50h, 00h

db 01h, 0A3h

db 01h, 0A5h,         50h, 00h

db 01h, 0A8h

db 00h, 0A5h,         50h, 00h
db 00h, 0A3h
db 00h, 0A5h
db 00h, 0A8h
db 00h, 0A5h,         50h, 00h
db 00h, 0A3h
db 00h, 0A5h
db 00h, 0A8h
db 00h, 0A5h,         50h, 00h
db 00h, 0A3h
db 00h, 0A5h
db 00h, 0A8h
db 00h, 0A5h,         50h, 00h
db 00h, 0A3h
db 00h, 0A5h,         50h, 00h
db 00h, 0A8h
db 11h


phra2A:

db 01h,  25h, 01h,    50h, 01h

db 01h,  0Dh, 00h

db 01h,  20h, 01h,    50h, 01h

db 01h, 0A8h

db 03h,  0Dh, 00h,    50h, 00h



db 03h, 027h, 01h,    50h, 01h



db 03h, 0A8h,         50h, 01h



db 03h, 010h, 00h,    50h, 00h



db 03h, 090h,         50h, 00h



db 03h, 090h,         50h, 00h



db 03h, 027h, 01h,    50h, 01h



db 01h, 0Fh,  00h,    50h, 00h

db 01h, 023h, 01h

db 21h,               50h, 01h

db 01h,  0Fh, 00h

db 03h, 028h, 01h,    50h, 01h




db 11h


phra2B:
db 01h, 027h, 01h,    50h, 01h

db 01h, 00Bh, 00h

db 01h, 023h, 01h,    50h, 01h

db 01h, 00Bh, 00h

db 01h, 01Eh, 01h,    50h, 01h

db 01h, 00Bh, 00h

db 01h, 023h, 01h,    50h, 01h

db 01h, 00Bh, 00h

db 11h


phra2C:
db 01h,  2Ah, 01h,    50h, 01h

db 01h,  0Bh, 00h

db 01h,  28h, 01h,    50h, 01h

db 01h,  0Bh, 00h 

db 01h,  27h, 01h,    50h, 01h

db 01h,  0Bh, 00h

db 01h,  23h, 01h,    50h, 01h

db 01h,  0Bh, 00h

db 11h


phra2D:
db 03h,  0Dh, 00h,    50h, 00h



db 01h,  99h,         50h, 00h

db 01h,  92h

db 21h,               50h, 00h

db 01h,  94h

db 03h,  97h,         50h, 00h

db 11h


phra2E:
db 03h,  8Dh,         50h, 00h



db 01h,  99h,         50h, 00h

db 01h,  9Ch

db 21h,               50h, 00h

db 00h,  9Eh
db 00h,  9Ch
db 00h,  99h,         50h, 00h
db 00h,  97h
db 00h,  99h
db 00h,  9Ch

db 11h


phra2F:
db 03h, 0A8h,         50h, 00h



db 01h,  8Bh,         50h, 00h

db 01h, 0A7h

db 21h,               50h, 00h

db 01h,  8Bh

db 03h, 0A3h,         50h, 00h



db 00h,  34h, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  0Bh, 00h

db 21h,               50h, 00h

db 00h,  33h, 02h
db 20h,              0C1h
db 03h,  0Bh, 00h,    50h, 00h



db 00h,  2Fh, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  0Bh, 00h

db 11h


phra210:
db 03h,  28h, 00h,    50h, 00h



db 01h,  8Dh,         50h, 00h

db 01h, 0A7h

db 21h,               50h, 00h

db 01h,   8Dh

db 03h,  0A5h,        50h, 00h



db 00h,  34h, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  0Dh, 00h

db 21h,               50h, 00h

db 00h,  33h, 02h
db 20h,              0C1h
db 03h,  0Dh, 00h,    50h, 00h



db 00h,  31h, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  0Dh, 00h

db 11h


phra211:
db 03h,  2Ah, 00h,    50h, 00h



db 01h,  90h,         50h, 00h

db 01h, 0A8h

db 21h,               50h, 00h

db 01h,  90h

db 03h, 0A7h,         50h, 00h



db 00h,  36h, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  10h, 00h

db 21h,               50h, 00h

db 00h,  34h, 02h
db 20h,              0C1h
db 03h,  10h, 00h,    50h, 00h



db 00h,  33h, 02h,    50h, 00h
db 20h,              0C1h
db 01h,  10h, 00h

db 11h


phra212:

db 10h, 00h









;  XXXXXXXXXXXXXZZZZZZZZZZ============-----------...............
;  XXX                                                       ...
;  XXX                      SFX Data                         ...
;  XXX                                                       ...
;  XXXXXXXXXXXXXXXXXXXXZZZZZZZZZZZZZ================------------

	GLOBAL _SFXdata

_SFXdata:
; index table
dw SFX_explosion





SFX_explosion:
db 10110011b, 80h, 24h
db 10010011b, 20h
db 10010011b, 1Eh
db 10010011b, 18h
db 10010011b, 14h
db 10010011b, 12h
db 10010011b, 10h
db 0