################################################################################
# Address: 0x80376a88
################################################################################

.include "Common/Common.s"
.include "Online/Online.s" # Required for logf buffer, should fix that
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

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Get and write current tick
branchl r12, 0x8034c408 # OSGetTick
lbz r4, DIB_POLL_INDEX(REG_DIB)
mulli r4, r4, 4 # Get index offset
addi r4, r4, DIB_CIRCULAR_BUFFER
stwx r3, REG_DIB, r4

# Log us, not needed
li r4, 486
divwu r3, r3, r4
mulli r4, r3, 12
loadGlobalFrame r3
logf LOG_LEVEL_WARN, "%d %d", "mr 5, 3", "mr 6, 4"

# Increment index
incrementByte r3, REG_DIB, DIB_POLL_INDEX, CIRCULAR_BUFFER_COUNT

# Indicate ready, prevents other functions from running first
li r3, 1
stb r3, DIB_IS_READY(REG_DIB)

# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lbz r0, 0x0002(r31) # replaced code line