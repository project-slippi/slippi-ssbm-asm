################################################################################
# Address: 0x8034ded8 # PADControlMotor
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Execute replaced code line
addi r29, r3, 0

# So I think what is happening is that all controllers are told to stop rumbling when we are
# exiting the scene... but inputs for the local player are being delayed, hence the message to
# stop rumbling doesn't arrive for that player until we have left the in-game scene, which means
# the redirect logic never runs.
# So in short, if player 0 is the local player, the reset message will come in for player 1 while
# still in the in-game scene, but it will be ignored because it's not the local player.
# Then the reset message will come in for player 0 once the scene has transitioned to the CSS meaning
# this command will be respected but the problem is that isn't the controller we are playing on.

# Check if online in-game
getMinorMajor r3
logf LOG_LEVEL_ERROR, "Rumble for port %d. Value: %d. Scene: %X", "mr 5, 29", "mr 6, 4", "mr 7, 3"
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
logf LOG_LEVEL_ERROR, "Is local player, redirect to %d", "mr 5, 3"

RESTORE:
restore

# Move new port output to r29
mr r29, r3

EXIT:
