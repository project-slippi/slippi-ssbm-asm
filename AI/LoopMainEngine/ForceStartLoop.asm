################################################################################
# Address: 0x801a4da8 # updateFunction
################################################################################

.include "Common/Common.s"

getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

li r26, 0
li r27, 1 # doesn't matter?
branch r12, 0x801a4de4 # go to start of loop

EXIT: