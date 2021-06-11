################################################################################
# Address: 0x80375c14 # End of VIPreRetraceCB
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
.set REG_DIFF_US, 29
.set REG_KEY, 28
.set REG_DEVELOP_TEXT, 27

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Check if DIB is ready (poll has happened)
lbz r3, DIB_ACTIVE_STATE(REG_DIB)
cmpwi r3, 0
beq RESTORE_AND_EXIT

# Fetch/convert key from frame
# https://docs.google.com/spreadsheets/d/1EKnVQmAbt5LCipXq_aGCMJ_utsOlPqM_O0UJ3cnWm4c/edit#gid=0
loadwz r3, 0x804a8b10 # Load ptr to frame that will be scanned out
lwz r3, 0(r3) # Load top left pixel
rlwinm r3, r3, 8, 0xFF # Extract top byte
subi r3, r3, 15
mulli r3, r3, 6
li r4, 5
divwu r3, r3, r4
rlwinm REG_KEY, r3, 28, 0xF # Extract 4 bits to get key

# Calculate time diff
calcDiffFromFetchUs REG_DIB, REG_KEY
mr REG_DIFF_US, r3

# Log
# mr r7, REG_DIFF_US
# loadwz r6, 0x804a8b10 # Load ptr to frame that will be scanned out
# lwz r6, 0(r6) # Load top left pixel
# mr r5, REG_KEY
# loadGlobalFrame r4
# subi r4, r4, 1
# logf "BLANK %u 0x%X %X %u" # Label Frame TimeUs

# Store latest latency
stw REG_DIFF_US, DIB_INPUT_TO_RENDER_US(REG_DIB)

# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

RESTORE_AND_EXIT:
restore

EXIT:
lwz	r0, 0x0024(sp) # Replaced codeline