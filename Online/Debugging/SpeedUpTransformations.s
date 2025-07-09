################################################################################
# Address: 0x801d14c4
# This just makes it a little bit faster to debug transformations.
################################################################################

.include "Common/Common.s"

lwz r3, -0x4d28(r13) # stadiums "yakumono" aka stage parameters,

li r4, 180 # 180 frames
stw r4, 0(r3) # initial trans time?
stw r4, 4(r3) # max trans time?
stw r4, 8(r3) # initial reset timer?
stw r4, 12(r3) # max reset timer?
mr r27, r4

# og
stw	r27, 0x00D8(r31)