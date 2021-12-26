################################################################################
# Address: 0x8034ded8 # PADControlMotor
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Execute replaced code line
addi r29, r3, 0

# Check if online in-game
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

# This function will output whether to change r29 to redirect rumble control
# messages to a different controller
################################################################################
# Function: RedirectPort
#-------------------------------------------------------------------------------
# Outputs:
# r3 - The port to redirect rumble signal to
################################################################################
.set REG_ODB_ADDRESS, 31
.set REG_RUMBLE_PORT, 29

backup

# fetch data to use throughout function
lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

lbz r3, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS)
cmpw r3, REG_RUMBLE_PORT
beq IS_LOCAL_PLAYER

# If this rumble instruction is not for the local player, just exit the function
restore
branch r12, 0x8034df44

IS_LOCAL_PLAYER:
# Set r3 output to the controller port to redirect to
lbz r3, ODB_INPUT_SOURCE_INDEX(REG_ODB_ADDRESS)

RESTORE:
restore

# Move new port output to r29
mr r29, r3

EXIT:
