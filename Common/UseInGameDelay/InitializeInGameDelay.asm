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
backup

################################################################################
# Initialize 
################################################################################


################################################################################
# Fetch delay frames setting
################################################################################


################################################################################
# Set up number of delay frames
################################################################################
# lbz r3, MSRB_DELAY_FRAMES(REG_MSRB_ADDR)
# cmpwi r3, MIN_DELAY_FRAMES
# blt DELAY_FRAMES_MIN_LIMIT
# cmpwi r3, MAX_DELAY_FRAMES
# bgt DELAY_FRAMES_MAX_LIMIT
# b SET_DELAY_FRAMES

# DELAY_FRAMES_MIN_LIMIT:
# li r3, MIN_DELAY_FRAMES
# b SET_DELAY_FRAMES

# DELAY_FRAMES_MAX_LIMIT:
# li r3, MAX_DELAY_FRAMES

# SET_DELAY_FRAMES:
# stb r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)

restore

EXIT: