################################################################################
# Address: 0x8023c588
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Normally this would not be necessary but since we are allowing old tags
# to re-populate this screen, we technically need to sync the state on first
# run of this function. I could have used a global variable but I didn't want
# to do that. This just makes sure that the position is in sync with the
# letters currently in memory, if not, it updates the text and position

li r3, 0

LOOP_START:
mulli r4, r3, 3
lbzx r4, r30, r4 # Load current letter
cmpwi r4, 0
beq LOOP_END

addi r3, r3, 1
cmpwi r3, 0x7
blt LOOP_START
LOOP_END:

lbz r4, 0x58(r28) # get current position
cmpw r3, r4
beq EXIT

cmpwi r19, 0x0
bne EXIT

# Here position is different, update text and update position
stb r3, 0x58(r28) # store position
branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

li r3, 57 # Select the confirm button
load r4, 0x804a04f2
sth r3, 0(r4) # Store selection of confirm button

EXIT:
lbz r3, -0x4A94(r13)
