################################################################################
# Address: 0x8038d00c # SFX_PlaySFX
################################################################################

.include "Common/Common.s"

addi r23, r3, 0 # Replaced code line before we use r3

getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

# If we are in game vs mode, let's skip the PlaySFX function
branch r12, 0x8038d29c

EXIT:
# We haven't touched r9 or r0 which have already been initialized. If this injection ever does
# touch those registers, we will need to restore more lines of code