################################################################################
# Address: 0x8016cd08 # Pause_CheckButtonsToPause right after checking if
# anyone pressed the unpause button (and no one did).
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# offset from match info block which we can borrow for this
.set OFST_UNPAUSED_ON_DISCONNECT, 0x9 # can also use 0xb and 0xc

backup

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT_AND_RESTORE

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_IS_DISCONNECTED(r3)
cmpwi r3, 1
bne EXIT_AND_RESTORE # if we are not disconnected, just continue as normal

# make sure we have not already unpaused on disconnect once already
lbz	r3, OFST_UNPAUSED_ON_DISCONNECT(r30)
cmpwi r3, 1
beq EXIT_AND_RESTORE

# if we are disconnected, just branch to unpause
# and store that we already unpaused on disconnect
li r3, 1
stb	r3, OFST_UNPAUSED_ON_DISCONNECT(r30)
restore
branch r12, 0x8016cd28

EXIT_AND_RESTORE:
restore
addi r29, r4, 0 # original line
