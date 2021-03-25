################################################################################
# Address: 0x8023cca4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Original line - checks for an L or R press.
rlwinm. r0, r26, 0, 24, 25

# If no L or R was pressed, proceed to checking for a Z press.
beq CHECK_Z

# An L or R was pressed, branch to their handlers.
branchl r12, 0x8023ccac

CHECK_Z:

backup

# Manually backup the contents of r4. Without this, it breaks moving the cursor.
mr r26, r4

# Manually retrieve inputs - Best I can tell, the function 
# "MainMenu_GetAllControllerInstantButtons" doesn't include check for Z.
# TODO: It might be worth having the above function handle this. 
lbz r3, -0x4A94(r13)
rlwinm r3, r3, 0, 24, 31
branchl	r12, Inputs_GetPlayerInstantInputs

# Determine if Z was pressed.
rlwinm.	r0, r4, 0, 27, 27
beq EXIT

mr r4, r26 
restore

# Z Button was pressed. Branch to "OnZPress"
branchl r12, 0x8023ccdc

EXIT:
mr r4, r26
restore
branchl r12, 0x8023cd34 # B Press check
