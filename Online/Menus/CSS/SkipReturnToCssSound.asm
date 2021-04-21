################################################################################
# Address: 0x80264118 # Executed after check to see if tag is empty
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_ACB_ADDR, 31
.set REG_CONN_STATE, 30

backupall # r3 needs to be restored for replaced codeline

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
bne RESET_NAME_ENTRY

# The following logic handles the transition coming back from SSS
li r3, 0
branchl r12, FN_LoadMatchState
lbz REG_CONN_STATE, MSRB_CONNECTION_STATE(r3)
branchl r12, HSD_Free
cmpwi REG_CONN_STATE, MM_STATE_CONNECTION_SUCCESS
bne EXIT # If not connected, don't skip

lbz r3, OFST_R13_ISWINNER(r13)
cmpwi r3, ISWINNER_LOST
beq SKIP_SOUND # If not previous loser,

b EXIT

RESET_NAME_ENTRY:
# Reset name entry mode
li r3, 0
stb r3, OFST_R13_NAME_ENTRY_MODE(r13)

# Fetch location where auto-complete buffer is stored and free both buffers
computeBranchTargetAddress r3, INJ_CheckAutofill
lwz REG_ACB_ADDR, IDO_ACB_ADDR(r3) # Load ACB_ADDR
lwz r3, ACB_ACXB_ADDR(REG_ACB_ADDR) # Load ACXB_ADDR
branchl r12, HSD_Free
mr r3, REG_ACB_ADDR
branchl r12, HSD_Free

SKIP_SOUND:
restoreall
# Skip playing sounds
branch r12, 0x802641a8

EXIT:
restoreall
lwz r3, 0x0020(r3) # replaced code line
