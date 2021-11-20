################################################################################
# Address: 0x8001960c # RenewInputs_Prefunction
################################################################################

.include "Common/Common.s"

getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

# If we are in game vs mode, let's ignore polling
branch r12, 0x80019618

EXIT:
# Let's do polling if we get here
li r3, 0
branchl r12, 0x803769fc # HSD_PadRenewRawStatus