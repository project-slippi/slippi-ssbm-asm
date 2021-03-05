################################################################################
# Address: 8036A4A8
################################################################################
.include "../../Common/Common.s"

# initialize widescreen
li r3, 1
stb r3, isWidescreen(r13)

lfs	f1,0x34(r31)	# default code line

bl  Floats
mflr r3
lfs f2,0x0(r3)
lfs f3,0x4(r3)
fmuls f1,f1,f2
fdivs f1,f1,f3

b END

Floats:
blrl
.float 320
.float 219

END:
