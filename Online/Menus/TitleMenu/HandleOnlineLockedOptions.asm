################################################################################
# Address: 0x802299f0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

cmpwi r3, 0x8
bne- EXIT

/*
CHECK_LOG_IN:
loadGlobalFrame r3
cmpwi r3, 240
blt INITIAL_STATE

SECOND_STATE:
cmpwi r4, 0x3
beq RETURN_LOCKED
cmpwi r4, 0x4
beq EXIT
cmpwi r4, 0x5
beq RETURN_LOCKED
b EXIT
*/

lbz r3, OFST_R13_APP_STATE(r13)
cmpwi r3, 0
beq NOT_LOGGED_IN_STATE
cmpwi r3, 1
beq LOGGED_IN_STATE
cmpwi r3, 2
beq UPDATE_STATE

NOT_LOGGED_IN_STATE:
cmpwi r4, 0x0
beq RETURN_LOCKED
cmpwi r4, 0x1
beq RETURN_LOCKED
cmpwi r4, 0x2
beq RETURN_LOCKED
cmpwi r4, 0x4
beq RETURN_LOCKED
cmpwi r4, 0x5
beq RETURN_LOCKED
b EXIT

LOGGED_IN_STATE:
cmpwi r4, 0x0
beq RETURN_LOCKED
cmpwi r4, 0x3
beq RETURN_LOCKED
cmpwi r4, 0x5
beq RETURN_LOCKED
b EXIT

UPDATE_STATE:
cmpwi r4, 0x0
beq RETURN_LOCKED
cmpwi r4, 0x1
beq RETURN_LOCKED
cmpwi r4, 0x2
beq RETURN_LOCKED
cmpwi r4, 0x3
beq RETURN_LOCKED
cmpwi r4, 0x4
beq RETURN_LOCKED
b EXIT

RETURN_LOCKED:
li r3, 0
branch r12, 0x802299f4

EXIT:
li r3, 1
