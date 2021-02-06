################################################################################
# Address: 0x8023ca50 # Executed after check to see if tag is empty
# This now branches to OnConfirmButtonHandler.
################################################################################

.include "Common/Common.s"
li r3, 1
branchl r12, 0x8023cc14 