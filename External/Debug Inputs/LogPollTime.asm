################################################################################
# Address: 0x80349a28 # SIInterruptHandler
################################################################################

.include "Common/Common.s"
.include "./DebugInputs.s"

# Check if VS Mode
getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

.set REG_DIB, 31
.set REG_INTERRUPTS, 30
.set REG_DIFF_SINCE_LAST, 29

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

lwz r3, DIB_POLL_COUNT(REG_DIB)
addi r3, r3, 1
stw r3, DIB_POLL_COUNT(REG_DIB)

# Write poll time
branchl r12, 0x8034c408 # OSGetTick
lwz r4, DIB_LAST_POLL_TIME(REG_DIB)
stw r3, DIB_LAST_POLL_TIME(REG_DIB)
calcDiffUs r3, r4 # Calculate difference since last poll
mr REG_DIFF_SINCE_LAST, r3

# Store min/max diff for logging
lwz r3, DIB_POLL_COUNT(REG_DIB)
rlwinm. r3, r3, 0, 0xFF
beq FN_PollingHandler_RESET_MIN_MAX # Reset every 256 polls, 2 seconds?

lwz r3, DIB_POLL_DIFF_MIN_US(REG_DIB)
cmpw REG_DIFF_SINCE_LAST, r3
bge FN_PollingHandler_SKIP_ADJUST_MIN
stw REG_DIFF_SINCE_LAST, DIB_POLL_DIFF_MIN_US(REG_DIB)
FN_PollingHandler_SKIP_ADJUST_MIN:

lwz r3, DIB_POLL_DIFF_MAX_US(REG_DIB)
cmpw REG_DIFF_SINCE_LAST, r3
ble FN_PollingHandler_SKIP_ADJUST_MAX
stw REG_DIFF_SINCE_LAST, DIB_POLL_DIFF_MAX_US(REG_DIB)
FN_PollingHandler_SKIP_ADJUST_MAX:

b FN_PollingHandler_MIN_MAX_END

FN_PollingHandler_RESET_MIN_MAX:
stw REG_DIFF_SINCE_LAST, DIB_POLL_DIFF_MIN_US(REG_DIB)
stw REG_DIFF_SINCE_LAST, DIB_POLL_DIFF_MAX_US(REG_DIB)
FN_PollingHandler_MIN_MAX_END:

RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lwz	r5, 0(r24) # Replaced codeline