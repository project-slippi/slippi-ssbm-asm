################################################################################
# Address: 0x802fd16c
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PLAYER_SLOT, 27 # from parent

CODE_START:
# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_LOCAL_PLAYER_INDEX(r3)

# Check if this is the local player
cmpw r3, REG_PLAYER_SLOT
bne EXIT

# If this is the local player, branch into section of code that sets tag, we will know
# that this state was forced by checking the value of LoadNameTagSlot when the string is grabbed
branch r12, 0x802fd188

EXIT:
cmplwi r0, 120 # replaced code line