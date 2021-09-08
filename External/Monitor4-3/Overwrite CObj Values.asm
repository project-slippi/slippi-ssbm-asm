################################################################################
# Address: 0x8036A4A8
################################################################################
.include "../../Common/Common.s"

lfs	f1, 0x34(r31) # default code line. in game it is loaded to 1.21733

bl Floats
mflr r3
lfs f2, 0x0(r3)
fmuls f1, f1, f2

b END

Floats:
blrl
.float 1.09529 # Multiplier to take 1.21733 -> 1.33333

END:
