#To be inserted at 801d14c8
.include "../Common.s"
.include "Transformation.s"

.set PSData,31

#Init Bool
  li  r3,0
  stb r3,isLoaded(PSData)

#Original
  li	r29, 1
