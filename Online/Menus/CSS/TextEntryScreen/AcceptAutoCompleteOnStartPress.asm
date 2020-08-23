################################################################################
# Address: 0x8023cc98 # 
################################################################################

.include "Common/Common.s"

backup

# Check if we have have an autocomplete result loaded.
lhz r3, 0x18 (r30)
cmpwi r3, 0x0
beq ERROR 

# Play success sound
li r3, 1
branchl r12, SFX_Menu_CommonSound

# There's text that can be autocompleted. So we load it.
li r3, 7 
stb r3, 0x58 (r28) # store position
li r0, 57
sth r0, 0 (r27)

li r3, 57 # Select the confirm button
load r4, 0x804a04f2
sth r3, 0(r4) # Store selection of confirm button
restore

branchl r12, 0x8023CE4C 
EXIT:
branchl r12, 0x8023ce38

ERROR:
# Play error sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound
restore
b EXIT