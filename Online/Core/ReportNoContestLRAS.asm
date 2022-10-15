################################################################################
# Address: 0x8016e9e8
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# This code ensures that the game has been reported before leaving the game scene. In direct mode
# on an LRAS, the game wasn't being reported in StartEngineLoop.asm

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

lwz r12, OFST_R13_ODB_ADDR(r13) # data buffer address

# Check if game is already ended. For everything but direct LRAS this flag should be true already
lbz r3, ODB_IS_GAME_OVER(r12)
cmpwi r3, 0
bne EXIT

# Mark game as being over
li r3, 1
stb r3, ODB_IS_GAME_OVER(r12)

# Call game end handler function
lwz r3, ODB_FN_HANDLE_GAME_OVER_ADDR(r12)
mtctr r3
bctrl

EXIT:
lbz r0, 0x000E(r31)