################################################################################
# Address: 8006c324
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

#Reset Status
  li  r3,0
  stb r3,LCancelStatus(r30)

Original:
  lwz	r3, 0x00B0 (r30)
