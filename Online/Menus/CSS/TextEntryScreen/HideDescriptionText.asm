################################################################################
# Address: 0x8023b3ac
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Skip setting description text
branch r12, 0x8023b3e4

EXIT:
lbz r4, -0x4AEC(r13)
