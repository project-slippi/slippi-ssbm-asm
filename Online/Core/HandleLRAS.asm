################################################################################
# Address: 0x8016d310
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_ODB_ADDRESS, 4

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

################################################################################
# Handle game completed
################################################################################
# Load game end ID, check for LRAS. This case will not trigger the game completed
load r3, 0x8046b6a0
lbz r3, 0x8(r3)
cmpwi r3, 7 # Check for LRAS ID
bne EXIT

# Call game end handler function
lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
lwz r3, ODB_FN_HANDLE_GAME_OVER_ADDR(REG_ODB_ADDRESS)
mtctr r3
bctrl

EXIT:
# Replaced code lines
lwz r0, 0x003C(sp)
lwz r31, 0x0034(sp)
