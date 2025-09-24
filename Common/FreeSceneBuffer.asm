################################################################################
# Address: 0x801a41d8
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Look at AllocSceneBuffer.asm for context

lwz r3, OFST_R13_SB_ADDR(r13)
branchl r12, HSD_Free

# Original
li r3, 11
