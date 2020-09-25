.include "Common/Common.s"

################################################################################
# Address: FN_IntToFloat
################################################################################
# Inputs:
# r3 - Integer Value
################################################################################
# Output:
# f1 - Integer converted to Float
################################################################################
# Description:
# Converts int to float returns f1 as converted value (stolen from CreateText.asm)
################################################################################

stwu r1,-0x100(r1)	# make space for 12 registers
stfs f2,0x8(r1)

lis	r0, 0x4330
lfd	f2, -0x6758 (rtoc)
xoris r3, r3,0x8000
stw	r0,0xF0(sp)
stw	r3,0xF4(sp)
lfd	f1,0xF0(sp)
fsubs f1,f1,f2		#Convert To Float

lfs  f2,0x8(r1)
addi	r1,r1,0x100	# release the space
blr