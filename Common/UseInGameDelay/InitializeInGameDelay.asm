################################################################################
# Address: INJ_InitInGameDelay
################################################################################

.include "Common/Common.s"
.include "Common/UseInGameDelay/InGameDelay.s"

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
.long 0x80000000 # Placeholder for allocated memory pointer

CODE_START:
# Replaced code line
branchl r12, 0x802f665c # Call HUD_Create

# Short circuit conditions
getMajorId r3
cmpwi r3, 0x8
beq EXIT # Don't run this while online, it has its own built-in delay

################################################################################
# Logic Start
################################################################################
.set REG_IGDB_ADDR, 31
.set REG_DELAY_RESULT, 30

backup

################################################################################
# Initialize 
################################################################################
# Prep the IGDB
li r3, IGDB_SIZE
branchl r12, HSD_MemAlloc
mr REG_IGDB_ADDR, r3
li r4, IGDB_SIZE
branchl r12, Zero_AreaLength

# Write the IGDB address to static memory
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
stw REG_IGDB_ADDR, 0(r3)

################################################################################
# Fetch delay frames setting
################################################################################
# We will just use the IGDB to do the EXI transfer to avoid making another buf
li r3, CONST_SlippiCmdGetDelay
stb r3, 0(REG_IGDB_ADDR)

# Request delay
mr r3, REG_IGDB_ADDR # Use the receive buffer to send the command
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get delay response
mr r3, REG_IGDB_ADDR # Use the receive buffer to send the command
li r4, 2
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

################################################################################
# Set up number of delay frames
################################################################################
# First fetch the result (note that this value should be 0 if EXI didn't exist)
lbz REG_DELAY_RESULT, 0x1(REG_IGDB_ADDR)

# Zero our the IGDB again to clear out any other EXI values
mr r3, REG_IGDB_ADDR
li r4, IGDB_SIZE
branchl r12, Zero_AreaLength

# Handle delay limits
cmpwi REG_DELAY_RESULT, MIN_DELAY_FRAMES
blt DELAY_FRAMES_MIN_LIMIT
cmpwi REG_DELAY_RESULT, MAX_DELAY_FRAMES
bgt DELAY_FRAMES_MAX_LIMIT
b SET_DELAY_FRAMES
DELAY_FRAMES_MIN_LIMIT:
li REG_DELAY_RESULT, MIN_DELAY_FRAMES
b SET_DELAY_FRAMES
DELAY_FRAMES_MAX_LIMIT:
li REG_DELAY_RESULT, MAX_DELAY_FRAMES

# Write delay result to IGDB
SET_DELAY_FRAMES:
stb REG_DELAY_RESULT, IGDB_DELAY_FRAMES(REG_IGDB_ADDR)

################################################################################
# Terminate logic if delay is zero or less
################################################################################
cmpwi REG_DELAY_RESULT, 0
ble RESTORE_EXIT

################################################################################
# Prepare delay display
################################################################################
# TODO: Implement

RESTORE_EXIT:
restore
EXIT: