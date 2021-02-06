################################################################################
# Address: 0x8023cc14 
# Executed after check to see if tag is empty or there are remaining autocomplete 
# suggestions.
# 
# OnConfirmButtonAPress may branch to this address, and if it does, r3 will be set to 1. 
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

mr r23, r3  # Copy potentially passed arg.
lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Check to see if there's an autcomplete suggestion that hasn't 
# been accepted.
lbz r3, 0x58 (r28) # Get cursor position/index.
cmpwi r3, 7
bge START
backup
li r5, 0
mulli r3, r3, 3
CLEAR_REST_TEXT:
    sthx r5, r30, r3
    addi r3, r3, 2
    cmpwi r3, 0xE
blt CLEAR_REST_TEXT
restore

START:
# Play success sound
li	r3, 1
branchl r12, SFX_Menu_CommonSound

# Execute callback function
li  r3, SB_RAND     # first stage in direct is always random
lwz r12, OFST_R13_CALLBACK(r13)
mtctr r12
bctrl

# Skip the regular stuff that would run on success (saving the nametag)
mr r3, r23
cmpwi r3, 1 # Determine if user confirmed with A button press.
beq CONFIRM_A
branch r12, 0x8023cc80
b EXIT

CONFIRM_A: 
branch r12, 0x8023cabc 

EXIT:
mr r3, r23  # Restore r3 val.
li r0, 0
