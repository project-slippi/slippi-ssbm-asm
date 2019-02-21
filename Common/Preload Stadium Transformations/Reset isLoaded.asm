#To be inserted at 801d4f14
.include "../Common.s"
.include "Transformation.s"

.set PSData,31

#Reset Bool
  li  r3,0
  stb r3,isLoaded(PSData)

Original:
  lwz	r3, -0x4D28 (r13)
