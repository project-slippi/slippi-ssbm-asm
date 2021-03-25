################################################################################
# Address: 0x8023ccdc 
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

backup
# Check if we have have an autocomplete result loaded.
lbz r4, 0x58 (r28) # Get cursor position/index.
mulli r4, r4, 0x3 # Multiply by 3 to get data location. 
lhzx r3, r4, r30 # Load the character at the cursor location.
# If there's no data (0), than we have no autocomplete suggestion.
cmpwi r3, 0x0
beq ERROR 

# Play success sound
li r3, 1
branchl r12, SFX_Menu_CommonSound

# There's text that can be autocompleted. So we load it.
li r3, 7 
stb r3, 0x58 (r28) # store position

restore

branchl r12, 0x8023CE4C 
EXIT:
# Return to bottom of NameEntry_Think loop
# Previously it would check inputs again but this would cause an infinite loop on z press
# branchl r12, 0x8023cca4
branchl r12, 0x8023ccfc

ERROR:
# Play error sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound
restore
b EXIT
