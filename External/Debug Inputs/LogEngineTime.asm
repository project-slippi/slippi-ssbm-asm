################################################################################
# Address: 0x801a4dec
################################################################################

.include "Common/Common.s"
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

# Fetch key from controller input and clear d-pad inputs
load r4, 0x804c1fac
lwz r3, 0(r4)
rlwinm REG_KEY, r3, 0, 0xF
rlwinm r3, r3, 0, 0xFFFFFFF0 # clear d-pad inputs
stw r3, 0(r4)

# Calculate time diff
calcDiffFromFetchUs REG_DIB, REG_KEY
mr REG_DIFF_US, r3

stw REG_DIFF_US, DIB_POLL_TO_ENGINE_US(REG_DIB)

# Adjust develop text BG color
lwz r3, DIB_COLOR_KEY_DTEXT_ADDR(REG_DIB)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+0(sp)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+1(sp)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+2(sp)
lwz r4, BKP_FREE_SPACE_OFFSET(sp)
rlwinm r4, r4, 4, 0xFFFFF000
ori r4, r4, 0xFF
stw r4, BKP_FREE_SPACE_OFFSET(sp)
addi r4, sp, BKP_FREE_SPACE_OFFSET
branchl r12, 0x80302b90 # DevelopText_StoreBGColor

RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

restore

EXIT:
lwz r0, -0x6C98(r13)