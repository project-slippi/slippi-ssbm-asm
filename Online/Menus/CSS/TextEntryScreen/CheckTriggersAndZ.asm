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
branch r12, 0x8023ccac

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

################################################################################
# Z Press Handler
################################################################################
# Check if we have have an autocomplete result loaded.
lbz r4, 0x58 (r28) # Get cursor position/index.
mulli r4, r4, 0x3 # Multiply by 3 to get data location. 
lhzx r3, r4, r30 # Load the character at the cursor location.
# If there's no data (0), than we have no autocomplete suggestion.
cmpwi r3, 0x0
bne FILL_SUCCESS 

# No data, play error sound and exit
li	r3, 3
branchl r12, SFX_Menu_CommonSound
b Z_HANDLER_END

FILL_SUCCESS:
# Play success sound
li r3, 1
branchl r12, SFX_Menu_CommonSound

# There's text that can be autocompleted. So we load it.
li r3, 7 
stb r3, 0x58 (r28) # store position

branchl r12, 0x8023CE4C # NameEntry_UpdateTypedName

Z_HANDLER_END:
# Return to bottom of NameEntry_Think loop
# Previously it would check inputs again but this would cause an infinite loop on z press
# branchl r12, 0x8023cca4
mr r4, r26
restore
branch r12, 0x8023ccfc

EXIT:
mr r4, r26
restore
branchl r12, 0x8023cd34 # B Press check
