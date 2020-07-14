################################################################################
# Address: 0x80264110 # Executed after check to see if tag is empty
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_R0, 31
.set REG_CONN_STATE, 30

mr r3, r0

backup

mr REG_R0, r3 # Store r0

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
bne RESET_NAME_ENTRY

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

SKIP_SOUND:
mr r3, REG_R0
restore
mr r0, r3
# Skip playing sounds
branch r12, 0x802641a8

EXIT:
mr r3, REG_R0
restore
rlwinm r0, r3, 3, 0, 28
