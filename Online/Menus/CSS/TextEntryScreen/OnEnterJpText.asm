################################################################################
# Address: 0x8023c33c # Immediately following selecting a text item.
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz r4, IDO_ACB_ADDR(r3)
lbz r5, ACB_COMMITTED_CHAR_COUNT(r4)
cmpwi r5, 8
bge SKIP_COMMITTED_INCR
addi r5, r5, 1
stb r5, ACB_COMMITTED_CHAR_COUNT(r4)
SKIP_COMMITTED_INCR:

# Call fetch suggestion function
addi r4, r3, IDO_FN_FetchSuggestion
mtctr r4

# Call FetchSuggestion function
li r3, CONST_ScrollReset
bctrl
b END

EXIT:
branchl r12, 0x8023CE4C # NameEntry_UpdateTypedName

END:
