################################################################################
# Address: 0x8023ca50 # Executed after check to see if tag is empty
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Play success sound
li	r3, 1
branchl r12, SFX_Menu_CommonSound

# Execute callback function
lwz r3, OFST_R13_CALLBACK(r13)
mtctr r3
bctrl

# Skip the regular stuff that would run on success (saving the nametag)
branch r12, 0x8023cabc

EXIT:
li r0, 0
