################################################################################
# Address: 0x80184adc # VS Splash think function
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_IDX, 31
.set REG_JOBJ_ADDR, 27 # Set by parent function

# Stack Pointer Offsets
.set SPO_CHILD_JOBJ, 0x80 # float

# Ensure that this is an online VS
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_VS
bne EXIT # If not online VS, execute normal code

backup

li REG_IDX, 9

# Loop through 27 JOBJs and set them to invisible
LOOP_START:
# Get child JObj
mr r3, REG_JOBJ_ADDR
addi r4, sp, SPO_CHILD_JOBJ
mr r5, REG_IDX
li r6, -1
branchl r12, JObj_GetJObjChild

# Remove animations for the JObjs. By doing this they will never show
lwz r3, SPO_CHILD_JOBJ(sp)
branchl r12, JObj_RemoveAnimAll

addi REG_IDX, REG_IDX, 1
cmpwi REG_IDX, 14
blt LOOP_START

# Restore
restore

EXIT:
# Run replaced code lines
addi r29, r30, 56
