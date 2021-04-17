################################################################################
# Address: 0x8023ccbc
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq RUN_REPLACED

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill
addi r3, r3, IDO_FN_FetchSuggestion
mtctr r3

# Call FetchSuggestion function
li r3, CONST_ScrollOlder
bctrl

# Exit L handler and skip everything that previously happened on an L press. Exits think function
branch r12, 0x8023ce38

RUN_REPLACED:
lbz	r3, 0x0050(r28)