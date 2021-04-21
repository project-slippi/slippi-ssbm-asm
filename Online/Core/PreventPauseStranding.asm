################################################################################
# Address: 0x8016cd08 # Pause_CheckButtonsToPause right after checking if
# anyone pressed the unpause button (and no one did).
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

backup

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT_AND_RESTORE

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_IS_DISCONNECTED(r3)
cmpwi r3, 1
bne EXIT_AND_RESTORE # if we are not disconnected, just continue as normal

# if we are disconnected, just branch to unpause
restore
branch r12, 0x8016cd28

EXIT_AND_RESTORE:
restore
addi r29, r4, 0 # original line
