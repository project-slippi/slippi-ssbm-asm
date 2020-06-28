################################################################################
# Address: 0x80185060 # Stage Animation think function
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_JOBJ_ADDR, 31
.set REG_IDX, 30

# Stack Pointer Offsets
.set SPO_CHILD_JOBJ, 0x80 # float

# Ensure that this is an online VS
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_VS
bne EXIT # If not online VS, execute normal code

backup

lwz REG_JOBJ_ADDR, 0x28(r3)
li REG_IDX, 0

# Loop through 27 JOBJs and set them to invisible
LOOP_START:
# Get child JObj
mr r3, REG_JOBJ_ADDR
addi r4, sp, SPO_CHILD_JOBJ
mr r5, REG_IDX
li r6, -1
branchl r12, JObj_GetJObjChild

# Set invisible flag on JObj
lwz r4, SPO_CHILD_JOBJ(sp)
lwz r3, 0x14(r4) # Get current flags
ori r3, r3, 0x10 # Set invisible flag
stw r3, 0x14(r4)

addi REG_IDX, REG_IDX, 1
cmpwi REG_IDX, 27
blt LOOP_START

# Branch to the end of the parent function
restore
branch r12, 0x801851ac

EXIT:
# Run replaced code lines
lis r3, 0x8047
addi r31, r3, 13736
