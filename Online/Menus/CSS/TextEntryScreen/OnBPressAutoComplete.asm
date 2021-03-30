################################################################################
# Address: 0x8023cd74
################################################################################

# This replaces the entire b press handler, none of it is necessary

.include "Common/Common.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz r4, IDO_ACB_ADDR(r3)
lbz r5, ACB_COMMITTED_CHAR_COUNT(r4)
subi r5, r5, 1
stb r5, ACB_COMMITTED_CHAR_COUNT(r4)

# Update cursor position
stb	r5, 0x58(r28)

# Call fetch suggestion function
addi r4, r3, IDO_FN_FetchSuggestion
mtctr r4

# Call FetchSuggestion function
li r3, CONST_ScrollReset
bctrl

# Called function always calls UpdateTypedName, which is the replaced function so we don't need
# to call it again

# Skip the rest of the original handler
branch r12, 0x8023ce38