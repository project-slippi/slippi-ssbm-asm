################################################################################
# Address: 0x801a4cb4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Free old buffer if it exists
  lwz r3,OFST_R13_SB_ADDR(r13)
  cmpwi r3,0
  beq Alloc
  branchl r12, HSD_Free

# Alloc buffer
Alloc:
  li  r3,128
  branchl r12,HSD_MemAlloc
  stw r3,OFST_R13_SB_ADDR(r13)

# Original
  li	r0, 0
