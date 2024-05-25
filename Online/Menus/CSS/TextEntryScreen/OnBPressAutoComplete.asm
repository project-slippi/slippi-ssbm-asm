################################################################################
# Address: 0x8023cd74
################################################################################

# This normally replaces the entire b press handler, none of it is necessary when a suggestion
# is fetched

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq RUN_REPLACED

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz r4, IDO_ACB_ADDR(r3)
lbz r5, ACB_COMMITTED_CHAR_COUNT(r4)
cmpwi r5, 0
ble CONTINUE_B_HANDLER # If this is the last B press, don't fetch a suggestion
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

EXIT:
# Skip the rest of the original handler
branch r12, 0x8023ce38

CONTINUE_B_HANDLER:
branch r12, 0x8023cd68 # Branch directly to the handler which exits the CSS

RUN_REPLACED:
lbz r5, 0x0058(r28)
