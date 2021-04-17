################################################################################
# Address: 0x80376a24 # HSD_PadRenewRawStatus replaces PADRead call
################################################################################

.include "Common/Common.s"
.include "Common/UseInGameDelay/InGameDelay.s"

# Call PADRead (replaced instruction)
branchl r12, PadRead

# Check short circuit conditions
branchl r12, FN_GetCommonMinorID
cmpwi r3, 0x2 # Checks if we are in-game
beq ALLOWED_COMMON_ID
cmpwi r3, 0x3 # Checks if we are in-game sudden death
beq ALLOWED_COMMON_ID
cmpwi r3, 0x4 # Checks if we are in-game training mode
bne EXIT

ALLOWED_COMMON_ID:
getMajorId r3
cmpwi r3, 0x8
beq EXIT # Don't run this while online, it has its own built-in delay

loadwz r3, 0x80479d64 # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Logic Start
################################################################################
.set REG_IGDB_ADDR, 31
.set REG_CUR_REPORT_IGDB_OFST, 30

.set CONST_BACKUP_BYTES, 0xB0 # Maybe add this to Common.s
.set P1_PAD_OFFSET, CONST_BACKUP_BYTES + 0x2C

backup

computeBranchTargetAddress r3, INJ_InitInGameDelay
lwz REG_IGDB_ADDR, 0x8(r3) # Loads the address of the buffer

# Check for zero delay, if delay is zero, don't do anything
lbz r3, IGDB_DELAY_FRAMES(REG_IGDB_ADDR)
cmpwi r3, 0
ble RESTORE_EXIT

################################################################################
# Copy current inputs to temporary location
################################################################################
addi r3, sp, BKP_FREE_SPACE_OFFSET
addi r4, sp, P1_PAD_OFFSET
li r5, PADS_REPORT_SIZE
branchl r12, memcpy

################################################################################
# Overwrite current inputs with inputs from X frames ago
################################################################################
# Get IGDB offset for current index
lbz r3, IGDB_PAD_BUFFER_INDEX(REG_IGDB_ADDR)
mulli r3, r3, PADS_REPORT_SIZE
addi REG_CUR_REPORT_IGDB_OFST, r3, IGDB_PAD_BUFFER

# Overwrite
addi r3, sp, P1_PAD_OFFSET
add r4, REG_IGDB_ADDR, REG_CUR_REPORT_IGDB_OFST
li r5, PADS_REPORT_SIZE
branchl r12, memcpy

################################################################################
# Store current inputs to use X frames later
################################################################################
add r3, REG_IGDB_ADDR, REG_CUR_REPORT_IGDB_OFST
addi r4, sp, BKP_FREE_SPACE_OFFSET
li r5, PADS_REPORT_SIZE
branchl r12, memcpy

################################################################################
# Increment index
################################################################################
lbz r4, IGDB_DELAY_FRAMES(REG_IGDB_ADDR)
lbz r3, IGDB_PAD_BUFFER_INDEX(REG_IGDB_ADDR)
addi r3, r3, 1
cmpw r3, r4
blt SKIP_WRAP
li r3, 0 # Wrap to start of buffer once we've delayed enough
SKIP_WRAP:
stb r3, IGDB_PAD_BUFFER_INDEX(REG_IGDB_ADDR) # Write new index

RESTORE_EXIT:
restore
EXIT: