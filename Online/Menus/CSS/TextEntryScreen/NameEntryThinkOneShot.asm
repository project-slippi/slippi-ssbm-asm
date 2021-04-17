################################################################################
# Address: 0x8023c588
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

# Used to populate the first prediction on load
lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Fetch location where we will store auto-complete buffer
computeBranchTargetAddress r6, INJ_CheckAutofill

# Check if one shot has already happened
lwz r7, IDO_ACB_ADDR(r6) # Load ACB
lbz r3, ACB_ONE_SHOT_COMPLETE(r7)
cmpwi r3, 0
bne EXIT

# Set one shot complete
li r3, 1
stb r3, ACB_ONE_SHOT_COMPLETE(r7)

# Run function to fetch initial suggestion
addi r3, r6, IDO_FN_FetchSuggestion
mtctr r3
li r3, CONST_ScrollReset
bctrl

EXIT:
lbz r3, -0x4A94(r13) # replaced code line
