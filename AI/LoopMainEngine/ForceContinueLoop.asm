################################################################################
# Address: 0x801a500c # updateFunction
################################################################################

.include "Common/Common.s"

getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

# Load game end ID, if non-zero, game ended
load r3, 0x8046b6a0
lbz r3, 0x8(r3)
cmpwi r3, 0
bne EXIT

# Fake that there is an input ready
load r4, 0x804c1f78
li r3, 1
stb r3, 0x3(r4)

addi r26, r26, 1
branch r12, 0x801a4de4 # back to start of loop

EXIT:
lwz	r0, 0x000C(r25) # replaced code line