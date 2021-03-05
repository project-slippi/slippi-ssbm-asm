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

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_ROLLBACK_IS_ACTIVE(r3)
cmpwi r3, 1
bne EXIT # If rollback not active, continue as normal

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
