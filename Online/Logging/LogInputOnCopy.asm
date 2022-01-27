################################################################################
# Address: 0x803775b8 # Here we are starting the copy
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

logf LOG_LEVEL_NOTICE, "[%d] P%d %08X %08X %08X"
.endif

EXIT:
lhz	r0, 0 (r25)
