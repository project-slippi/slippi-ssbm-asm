################################################################################
# Address: 0x800355b4 # PlayerBlock_LoadNameTagSlot#
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PLAYER_SLOT, 31 # from parent

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

# If this is the local player, let's just say that the nametag is at index 0 and leave. The set
# tag logic will handle actually grabbing the tag from the correct play
li r3, 0
branch r12, 0x800355cc

EXIT:
mulli r4, r31, 3728 # replaced code line