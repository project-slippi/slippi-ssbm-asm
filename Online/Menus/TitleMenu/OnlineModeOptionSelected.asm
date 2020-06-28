################################################################################
# Address: 0x8022d88c
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# If selection was not 2, then skip this handler
bne EXIT

# Code Block Taken from Regular Match Submenu selection
li	r3, 1
branchl r12, SFX_Menu_CommonSound

lwz r3, OFST_R13_SWITCH_TO_ONLINE_SUBMENU(r13)
mtctr r3
bctrl
mr r27, r3 # This function normally would have overwritten r27

SKIP_TO_END_OF_PARENT:
# Exit the parent function
branch r12, 0x8022dafc

EXIT:
