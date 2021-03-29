################################################################################
# Address: 0x8023cde4
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

# Called function always calls UpdateTypedName, which is the replaced function so we don't need
# to call it again
