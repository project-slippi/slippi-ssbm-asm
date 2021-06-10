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

.set CONST_BACKUP_BYTES, 0xB0 # Maybe add this to Common.s
.set P1_PAD_OFFSET, CONST_BACKUP_BYTES + 0x2C

.set REG_DIB, 31
.set REG_INTERRUPTS, 30

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Store "key" to inputs (sets d-pad inputs)
lwz r3, P1_PAD_OFFSET(sp) # Load P1 inputs
rlwinm r3, r3, 16, 0xFFFFFFF0 # shift inputs to put d-pad lowest, also clear d-pad
lbz r4, DIB_POLL_INDEX(REG_DIB)
or r3, r3, r4 # set d-pad inputs to key
rlwinm r3, r3, 16, 0xFFFFFFFF # shift inputs back into place
stw r3, P1_PAD_OFFSET(sp)

# Get and write current tick
lwz r3, DIB_LAST_POLL_TIME(REG_DIB)
lbz r4, DIB_POLL_INDEX(REG_DIB)
mulli r4, r4, 4 # Get index offset
addi r4, r4, DIB_CIRCULAR_BUFFER
stwx r3, REG_DIB, r4

# Log
# loadwz r7, 0xCC006430 # Includes details to poll more often. http://hitmen.c02.at/files/yagcd/yagcd/chap5.html#sec5.8
# loadwz r7, 0xCC006434
# lwz r7, DIB_CALLBACK_COUNT(REG_DIB)
# lwz r6, P1_PAD_OFFSET(sp)
# rlwinm r6, r6, 16, 0xF
# loadGlobalFrame r5
# logf LOG_LEVEL_WARN, "POLL %u 0x%X %u"

# Increment index
incrementByte r3, REG_DIB, DIB_POLL_INDEX, CIRCULAR_BUFFER_COUNT

# Indicate ready, prevents other functions from running first. Only activate if currently inactive
lbz r3, DIB_ACTIVE_STATE(REG_DIB)
cmpwi r3, 0
bne SKIP_ACTIVATE
li r3, 1
stb r3, DIB_ACTIVE_STATE(REG_DIB)
SKIP_ACTIVATE:

# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

RESTORE_AND_EXIT:
restore

EXIT:
lbz r0, 0x0002(r31) # replaced code line