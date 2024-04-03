################################################################################
# Address: 0x8016cd08 # Pause_CheckButtonsToPause right after checking if
# anyone pressed the unpause button (and no one did).
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

# we can safely set r29 here because it's replaced right after this injection and
# restored on method exit too
lwz r29, OFST_R13_ODB_ADDR(r13) # data buffer address

lbz r3, ODB_IS_DISCONNECTED(r29)
cmpwi r3, 1
bne EXIT # if we are not disconnected, just continue as normal

lbz r4, ODB_LOCAL_PLAYER_INDEX(r29)
lbz r3, 0x01(r30) # index of player who paused
extsb r3, r3 # I don't know wth this does lol just mimicking the orig line
cmpw r3, r4
beq EXIT # if player who paused is local exit

# if we are disconnected, just branch to unpause
branch r3, 0x8016cd28

EXIT:
li r4, -1
