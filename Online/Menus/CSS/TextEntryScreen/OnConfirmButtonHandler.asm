################################################################################
# Address: 0x8023cc14
# Executed after check to see if tag is empty or there are remaining autocomplete 
# suggestions.
# 
# OnConfirmButtonAPress may branch to this address, and if it does, r3 will be set to 1. 
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_ACB_ADDR, 31

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

backup

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz REG_ACB_ADDR, IDO_ACB_ADDR(r3)

lbz r3, ACB_COMMITTED_CHAR_COUNT(REG_ACB_ADDR)
cmpwi r3, 8
bge SKIP_CLEAR_SUGGESTION

# There might be a suggestion active, clear out the letter at the current length index to clear
mulli r4, r3, 3
li r5, 0
sthx r5, r30, r4
SKIP_CLEAR_SUGGESTION:

# Play success sound
li	r3, 1
branchl r12, SFX_Menu_CommonSound

# Execute callback function
li  r3, SB_RAND     # first stage in direct is always random
lwz r12, OFST_R13_CALLBACK(r13)
mtctr r12
bctrl

# Skip the regular stuff that would run on success (saving the nametag)
restore
branch r12, 0x8023cc80

EXIT:
li r0, 0
