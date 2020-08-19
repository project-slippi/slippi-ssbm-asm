################################################################################
# Address: 0x8023cc98 # 
################################################################################

.include "Common/Common.s"

backup 
li r3, 7
stb r3, 0x58(r28) # store position
# branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName
restore

li r0, 57