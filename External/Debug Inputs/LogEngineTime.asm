################################################################################
# Address: 0x801a4dec
################################################################################

.include "Common/Common.s"
.include "Online/Online.s" # Required for logf buffer, should fix that
.include "./DebugInputs.s"

# Check if VS Mode
getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

loadGlobalFrame r3
cmpwi r3, 0
ble EXIT

.set REG_DIB, 31
.set REG_INTERRUPTS, 30
.set REG_DIFF_US, 29

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Calculate time diff
calcDiffTicksToUs REG_DIB, DIB_ENGINE_INDEX
mr REG_DIFF_US, r3

# Log
mr r8, REG_DIFF_US
loadwz r7, 0x804c1fac # Fetch key from controller input
rlwinm r7, r7, 0, 0xF
lbz r6, DIB_ENGINE_INDEX(REG_DIB)
loadGlobalFrame r5
logf LOG_LEVEL_WARN, "ENGINE %u %u 0x%X %u" # Label Frame TimeUs

# Increment index
incrementByte r3, REG_DIB, DIB_ENGINE_INDEX, CIRCULAR_BUFFER_COUNT

# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lwz r0, -0x6C98(r13)