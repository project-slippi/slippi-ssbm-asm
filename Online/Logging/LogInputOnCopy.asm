################################################################################
# Address: 0x803775b0 # Here we are starting the copy
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.if DEBUG_INPUTS==1
# Check if VS Mode
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

# Only print players 1 and 2
cmpwi r24, 2
bge EXIT

loadGlobalFrame r5
mr r6, r24
lwz r7, 0(r25)
lwz r8, 4(r25)
lwz r9, 8(r25)

logf LOG_LEVEL_NOTICE, "[%d] P%d Using Input: %08X %08X %08X"

lbz	r3, 0x0041(r26)
extsb. r0, r3
beq EXIT

logf LOG_LEVEL_INFO, "Input detected with non-zero status: %d", "extsb r5, 3"

EXIT:
# Re-loads overwritten data, must run right before extsb. r0, r3
lbz	r3, 0x0041(r26)
.endif
extsb. r0, r3 # replaced codeline
