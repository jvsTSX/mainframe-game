DEFSECT "IntroMenu", CODE
SECT "IntroMenu"


EXTERN _InGameStart
GLOBAL __START



__START:

	ld sp, #02000h
	ld br, #20h
	ld sc, #0
	
  jrl _InGameStart
