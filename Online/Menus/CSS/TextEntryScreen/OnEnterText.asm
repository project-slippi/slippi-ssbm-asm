################################################################################
# Address: 0x8023c730 # Immediately following selecting a text item.
################################################################################

.include "Common/Common.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill
addi r3, r3, IDO_FN_FetchSuggestion
mtctr r3

# Call FetchSuggestion function
li r3, CONST_ScrollReset
bctrl

# Exit R handler and skip everything that previously happened on an R press. Exits think function
branch r12, 0x8023ce38
