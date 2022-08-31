################################################################################
# Address: 801d14c8
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "Common/Preload Stadium Transformations/Transformation.s"

.set PSData,31

#Init Bool
  li  r3,0
  stb r3,isLoaded(PSData)

Original:
  li	r29, 1
