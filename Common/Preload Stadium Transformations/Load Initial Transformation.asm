#To be inserted at 801d13d8
.include "../Common.s"

.set PSData,31

#Store Flag
  stb	r0, 0x00C4 (r3)

#Load Transformation
  backup
  branchl r12,FN_LoadPSTransformation
  restore
