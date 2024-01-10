DEFSECT "EndingCutscene", CODE
SECT "EndingCutscene"

GLOBAL EndingRender
GLOBAL _GameEndSequence
EXTERN __START

_GameEndSequence:
  jrl __START









EndingRender:











  ret
