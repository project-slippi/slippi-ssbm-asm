################################################################################
# Address: 0x801a4cb4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Alloc buffer
  li  r3,128
  branchl r12,HSD_MemAlloc
  stw r3,OFST_R13_SB_ADDR(r13)

# Original
  li	r0, 0
