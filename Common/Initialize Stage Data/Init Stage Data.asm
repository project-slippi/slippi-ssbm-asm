#To be inserted at 801c154c
.include "../../Common/Common.s"

#Initialize data
  li  r4,516
  branchl r12,0x8000c160

Exit:
  cmplwi	r26, 0
