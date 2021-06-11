################################################################################
# Address: 0x80375c14 # End of VIPreRetraceCB
################################################################################

.include "Common/Common.s"
.include "./DebugInputs.s"

b CODE_START

DATA_BLRL:
blrl
# The following is an array of the key colors with the 2nd and 4th byte masked out
# The 2nd and 4th byte seem to be either 7F or 80, easier to compare by just excluding them
# TODO: I commented the console versions of the colors but for some reason when I use those,
# TODO: the latency can get really jumpy so I have no idea what's up
.long 0x10001000
.long 0x1E001E00
.long 0x2B002B00 # 0x2C002C00
.long 0x39003900
.long 0x47004700
.long 0x55005500
.long 0x62006200 # 0x63006300
.long 0x70007000
.long 0x7E007E00
.long 0x8C008C00
.long 0x99009900 # 0x9A009A00
.long 0xA700A700
.long 0xB500B500
.long 0xC300C300
.long 0xD000D000 # 0xD100D100
.long 0xDE00DE00

################################################################################
# Function: GetIndexFromColor
################################################################################
# Inputs:
# r3 - YUV Color
################################################################################
# Output:
# r3 - 0-15 or -1 if color does not match
################################################################################
.set REG_DATA, 31
.set REG_IDX, 30
.set REG_COLOR, 29

FN_GetIndexFromColor:
backup

load r4, 0xFF00FF00
and REG_COLOR, r3, r4

bl DATA_BLRL
mflr REG_DATA

li REG_IDX, 0
FN_GetIndexFromColor_LOOP_START:
mulli r3, REG_IDX, 4
lwzx r3, REG_DATA, r3
cmpw REG_COLOR, r3
bne FN_GetIndexFromColor_LOOP_CONTINUE
mr r3, REG_IDX
b FN_GetIndexFromColor_RETURN
FN_GetIndexFromColor_LOOP_CONTINUE:
addi REG_IDX, REG_IDX, 1
cmpwi REG_IDX, 16
blt FN_GetIndexFromColor_LOOP_START

li r3, -1

FN_GetIndexFromColor_RETURN:
restore
blr

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

# Fetch/convert key from frame
loadwz r3, 0x804a8b10 # Load ptr to frame that will be scanned out
lwz REG_COLOR, 4(r3) # Load top left pixel
mr r3, REG_COLOR
bl FN_GetIndexFromColor
cmpwi r3, 0
bge CALC_DIFF

# Color is invalid, increment count and exit
lwz r3, DIB_COLOR_FAIL_COUNT(REG_DIB)
addi r3, r3, 1
stw r3, DIB_COLOR_FAIL_COUNT(REG_DIB)
stw REG_COLOR, DIB_FAILED_COLOR(REG_DIB)
b RESTORE_AND_EXIT

CALC_DIFF:
mr REG_KEY, r3

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

RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lwz	r0, 0x0024(sp) # Replaced codeline