################################################################################
# Address: 0x8023ca50 # Executed after check to see if tag is empty
# This now branches to OnConfirmButtonHandler.
################################################################################

.include "Common/Common.s"

# The A/Start confirm handlers are identical, this just branches the logic for the A handler to
# the logic for the Start handler to avoid code duplication

branch r12, 0x8023cc14