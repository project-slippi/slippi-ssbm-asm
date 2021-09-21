################################################################################
# Address: 0x80019608 # RenewInputs_Prefunction
################################################################################

.include "Common/Common.s"

stwu sp, -0x0008(sp) # replaced code line

getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

# If we are in game vs mode, let's ignore polling
branch r12, 0x80019618

EXIT:
li r3, 0