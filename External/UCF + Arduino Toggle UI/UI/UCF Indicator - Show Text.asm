################################################################################
# Address: 8025e070
################################################################################
.include "Common/Common.s"

subi r3,r13,UCFTextPointers #get pointers
mulli r4,r31,0x4 #get offset
lwzx r3,r3,r4 #get players pointer

li r4,0x0 #make visible
stb r4,0x4D(r3) #store visibility bit

original:
li	r3, 185
