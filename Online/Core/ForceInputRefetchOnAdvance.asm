################################################################################
# Address: 0x80019614
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

branchl r12, 0x8001d2bc # Replaced code line

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

# Check if we got the signal to advance a frame
lwz r5, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_IS_FRAME_ADVANCE(r5)
cmpwi r3, 0
beq EXIT

# logf LOG_LEVEL_WARN, "Processing advance request on frame: %d", "lwz r5, ODB_FRAME(5)"

# Here we got the signal to advance a frame, let's call RenewInputs_Prefunction again.
# This should force the engine to loop twice the next time it runs.
branchl r12, RenewInputs_Prefunction

EXIT: