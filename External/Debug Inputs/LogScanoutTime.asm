################################################################################
# Address: 0x80375c14 # End of VIPreRetraceCB
################################################################################

.include "Common/Common.s"
.include "./DebugInputs.s"

b CODE_START

################################################################################
# Function: GetIndexFromColor
################################################################################
# Inputs:
# r3 - YUV Color
################################################################################
# Output:
# r3 - 0-15 or -1 if color does not match
################################################################################
FN_GetIndexFromColor:
rlwinm r4, r3, 24, 0xFF
rlwinm r3, r3, 8, 0xFF

cmpw r3, r4
beq FN_GetIndexFromColor_CALC_INDEX

li r3, -1 # Color invalid if the two bytes don't match
b FN_GetIndexFromColor_RETURN

FN_GetIndexFromColor_CALC_INDEX:
# This does some math on the byte to calculate the index from it. See google sheet for examples:
# https://docs.google.com/spreadsheets/d/1EKnVQmAbt5LCipXq_aGCMJ_utsOlPqM_O0UJ3cnWm4c/edit?usp=sharing
subi r3, r3, 15
mulli r3, r3, 6
li r4, 5
divwu r3, r3, r4
rlwinm r3, r3, 28, 0xF # Extract 4 bits to get key

FN_GetIndexFromColor_RETURN:
blr

################################################################################
# Code start
################################################################################
CODE_START:
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
.set REG_COLOR, 26

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

# Load ptr to frame that will be scanned out
loadwz r3, 0x804a8b10 # Contains ptr to the current XFB

# Invalidate the pixel color memory because the GPU will have overwritten it and if that memory
# is still in our cache, we would load a stale color (only on console)
li r4, 0
dcbi r3, r4
sync
isync

# Load 2 pixels and calculate the index from it
lwz REG_COLOR, 0(r3) # Load top left pixels
mr r3, REG_COLOR
bl FN_GetIndexFromColor
cmpwi r3, 0
blt RESTORE_AND_EXIT # Color is invalid, exit

mr REG_KEY, r3

# Calculate time diff
calcDiffFromFetchUs REG_DIB, REG_KEY
mr REG_DIFF_US, r3

# Store latest latency
stw REG_DIFF_US, DIB_INPUT_TO_RENDER_US(REG_DIB)

RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lwz r0, 0x0024(sp) # Replaced codeline