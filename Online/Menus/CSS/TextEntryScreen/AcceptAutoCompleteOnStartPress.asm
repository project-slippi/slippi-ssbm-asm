################################################################################
# Address: 0x8023cc98 # 
################################################################################

.include "Common/Common.s"

backup
li r3, 7 
stb r3, 0x58 (r28) # store position
li r0, 57
sth r0, 0 (r27)

li r3, 57 # Select the confirm button
load r4, 0x804a04f2
sth r3, 0(r4) # Store selection of confirm button
restore

branchl r12, 0x8023CE4C 
branchl r12, 0x8023ce38