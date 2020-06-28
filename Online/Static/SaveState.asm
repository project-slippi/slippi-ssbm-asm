################################################################################
# Address: FN_CaptureSavestate
################################################################################
# Inputs:
# r3 - Address of the transfer buffer used to communicate with Dolphin
# r4 - Frame index to attribute this savestate to
# r5 - Address of the control buffer for savestates
################################################################################
# Description:
# Stores everything required for a save state to memory. Can then later be
# loaded via the LoadState function
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Alarm.s"

.set REG_SSRB_ADDR, 27
.set REG_SSCB_ADDR, 26
.set REG_SSDB_ADDR, 25
.set REG_FRAME_INDEX, 24
.set REG_INTERRUPT_IDX, 23

backup

# Handle inputs
mr REG_SSRB_ADDR, r3
mr REG_FRAME_INDEX, r4
mr REG_SSCB_ADDR, r5

# Determine the SSDB Ptr to write to
lbz r3, SSCB_WRITE_INDEX(REG_SSCB_ADDR)
mulli r3, r3, SSDB_SIZE
addi r4, REG_SSCB_ADDR, SSCB_SSDB_START
add REG_SSDB_ADDR, r4, r3

# Increment write index for next time
lbz r3, SSCB_WRITE_INDEX(REG_SSCB_ADDR)
addi r3, r3, 1
cmpwi r3, ROLLBACK_MAX_FRAME_COUNT
blt SKIP_WRITE_INDEX_AJUST
subi r3, r3, ROLLBACK_MAX_FRAME_COUNT
SKIP_WRITE_INDEX_AJUST:
stb r3, SSCB_WRITE_INDEX(REG_SSCB_ADDR)

branchl r12, OSDisableInterrupts
mr REG_INTERRUPT_IDX, r3

################################################################################
# Start backup
################################################################################
stw REG_FRAME_INDEX, SSDB_FRAME(REG_SSDB_ADDR)

################################################################################
# EXI Savestate
################################################################################
li r3, CONST_SlippiCmdCaptureSavestate
stb r3, SSRB_COMMAND(REG_SSRB_ADDR)

stw REG_FRAME_INDEX, SSRB_FRAME(REG_SSRB_ADDR)

# Transfer buffer over DMA
mr r3, REG_SSRB_ADDR
li r4, SSRB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, REG_INTERRUPT_IDX
branchl r12, OSRestoreInterrupts

restore
blr
