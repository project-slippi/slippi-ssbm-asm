################################################################################
# Address: 0x801a4cb8
################################################################################

.include "Common/Common.s"

# Alloc buffer
li  r3, 128
branchl r12, HSD_MemAlloc
stw r3, OFST_R13_LOG_BUF(r13)

# Original
li r0, 0
stw r0, -0x4F78(r13)
