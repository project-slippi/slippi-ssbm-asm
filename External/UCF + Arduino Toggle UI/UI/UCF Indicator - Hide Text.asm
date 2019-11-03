################################################################################
# Address: 8025e0e8
################################################################################
.include "Common/Common.s"

.set entity,31
.set player,31

subi r3,r13,UCFTextPointers #get pointers
mulli r4,r31,0x4 #get offset
lwzx r3,r3,r4 #get players pointer

li r4,0x1 #make invisible
stb r4,0x4D(r3) #store visibility bit

original:
li	r3, 186
