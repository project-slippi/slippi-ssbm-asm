################################################################################
# Address: 801d4f14
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "Common/Preload Stadium Transformations/Transformation.s"

.set PSData,31

#Reset Bool
  li  r3,0
  stb r3,isLoaded(PSData)

Original:
  lwz	r3, -0x4D28 (r13)
