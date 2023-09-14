################################################################################
# Address: 0x80376a88
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

.set CONST_BACKUP_BYTES, 0xE0 # Maybe add this to Common.s
.set P1_PAD_OFFSET, CONST_BACKUP_BYTES + 0x2C

.set REG_DIB, 31
.set REG_INTERRUPTS, 30
.set REG_FETCH_TIME, 29

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Store "key" to inputs (sets d-pad inputs)
lwz r3, P1_PAD_OFFSET(sp) # Load P1 inputs
rlwinm r3, r3, 16, 0xFFFFFFF0 # shift inputs to put d-pad lowest, also clear d-pad
lbz r4, DIB_FETCH_INDEX(REG_DIB)
or r3, r3, r4 # set d-pad inputs to key
rlwinm r3, r3, 16, 0xFFFFFFFF # shift inputs back into place
stw r3, P1_PAD_OFFSET(sp)

# Get and write current tick
lwz r3, DIB_LAST_POLL_TIME(REG_DIB)
lbz r4, DIB_FETCH_INDEX(REG_DIB)
mulli r4, r4, 4 # Get index offset
addi r4, r4, DIB_CIRCULAR_BUFFER
stwx r3, REG_DIB, r4

# Increment index
incrementByteInBuf r3, REG_DIB, DIB_FETCH_INDEX, CIRCULAR_BUFFER_COUNT

# Indicate ready, prevents other functions from running first. Only activate if currently inactive
lbz r3, DIB_ACTIVE_STATE(REG_DIB)
cmpwi r3, 0
bne SKIP_ACTIVATE
li r3, 1
stb r3, DIB_ACTIVE_STATE(REG_DIB)
SKIP_ACTIVATE:

# Store details to print. Start with difference since last fetch
branchl r12, 0x8034c408 # OSGetTick
mr REG_FETCH_TIME, r3
lwz r4, DIB_LAST_FETCH_TIME(REG_DIB)
stw REG_FETCH_TIME, DIB_LAST_FETCH_TIME(REG_DIB)
calcDiffUs REG_FETCH_TIME, r4 # Calculate difference since last fetch
stw r3, DIB_FETCH_DIFF_US(REG_DIB)

# Store time since poll
lwz r3, DIB_LAST_POLL_TIME(REG_DIB)
calcDiffUs REG_FETCH_TIME, r3
stw r3, DIB_POLL_TO_FETCH_US(REG_DIB)

RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lbz r0, 0x0002(r31) # replaced code line