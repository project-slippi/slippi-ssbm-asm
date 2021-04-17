################################################################################
# Address: 0x8023c928
################################################################################

# On random press, we need to update the cursor and the committed char count, as well as
# do a suggestion lookup

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_RANDOM_NAME_LEN, 29 # set by parent function

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq RUN_REPLACED

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz r4, IDO_ACB_ADDR(r3)
stb REG_RANDOM_NAME_LEN, ACB_COMMITTED_CHAR_COUNT(r4)

# Update cursor position
stb	REG_RANDOM_NAME_LEN, 0x58(r28)

# Call fetch suggestion function
addi r4, r3, IDO_FN_FetchSuggestion
mtctr r4

# Call FetchSuggestion function
li r3, CONST_ScrollReset
bctrl

# Called function always calls UpdateTypedName, which is the replaced function so we don't need
# to call it again
b END

RUN_REPLACED:
branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

END: