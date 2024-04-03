################################################################################
# Address: 0x80376a20 # HSD_PadRenewRawStatus right before PAD call
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

################################################################################
# Short Circuit Conditions
################################################################################

# Check if VS Mode
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Check if rollback is active
################################################################################
lwz r4, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_ROLLBACK_IS_ACTIVE(r4)
cmpwi r3, 0
beq EXIT # If rollback not active, continue as normal to execute pad read

# We do this check because with frame advance especially, we can get in a state where
# we request a second input before savestate has been processed, we still want to fetch
# a controller input in this case
lbz r3, ODB_ROLLBACK_SHOULD_LOAD_STATE(r4)
cmpwi r3, 0
bne EXIT # If state should be loaded, continue as normal to execute pad read

################################################################################
# Skip PADRead
################################################################################

# This goes to the branch to our trigger input function, this function will not
# try to access the pad data when rollback is active
branch r12, 0x80376a28

################################################################################
# Exit
################################################################################

EXIT:
# replaced code line
addi r3, sp, 44
