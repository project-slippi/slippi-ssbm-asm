################################################################################
# Address: 0x80376a24 # HSD_PadRenewRawStatus replaces PADRead call
################################################################################

.include "Common/Common.s"
.include "Common/UseInGameDelay/InGameDelay.s"

# Call PADRead (replaced instruction)
branchl r12, PadRead

# Check short circuit conditions
branchl r12, FN_GetCommonMinorID
cmpwi r3, 0x2 # Checks if we are in-game
bne EXIT # If not in-game, do nothing

getMajorId r3
cmpwi r3, 0x8
beq EXIT # Don't run this while online, it has its own built-in delay

loadwz r3, 0x80479d64 # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Logic Start
################################################################################
.set REG_IGDB_ADDR, 31

backup

computeBranchTargetAddress INJ_InitInGameDelay
lwz REG_IGDB_ADDR, 0x8(r3) # Loads the address of the buffer

# I don't think I need to check for zero delay, if someone wants zero delay, they need to turn
# off the code



RESTORE_EXIT:
restore
EXIT: