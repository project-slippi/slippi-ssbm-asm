################################################################################
# Address: FN_GetCommonMinorID
################################################################################

################################################################################
# Description:
# Gets the common minor ID for the current minor scene. This will evaluated
# to the same ID for all in-game scenes, for example
################################################################################
# Outputs:
# r3 - Common ID for the current minor scene
################################################################################

.include "Common/Common.s"

.set REG_MINOR_ID, 31
.set REG_MAJOR_ID, 30
.set REG_MAJOR_TABLE_START, 29

backup

lis r5, 0x8048 # load address to offset from for scene controller
lbz REG_MAJOR_ID, -0x62D0(r5) # Load major from 0x80479D30
lbz REG_MINOR_ID, -0x62CD(r5) # Load minor from 0x80479D33

load REG_MAJOR_TABLE_START, 0x803daca4

/*
Major Scene Table:
    -Starts at 803daca4
    -Stride is 0x14
    -Structure is:
        -0x0 = Preload Bool. (0x0 = No Preload, 0x1 = Preload)
        -0x1 = Major Scene ID
        -0x2 = Unk
        -0x3 = Unk
        -0x4 = Pointer to MajorLoad Function (is run upon entering the major)
        -0x8 = Pointer to MajorUnload Function (is run upon leaving the major)
        -0xC = Pointer to MajorOnBoot Function (is run on boot to init global stuff)
        -0x10 = Pointer to Minor Scenes Tables
*/

# Amazingly major scene table is mostly ordered except for major scene ID 0x1. So we kind of have
# to loop awkwardly to find the scene we want
LOOP_MAJOR_INIT:
li r4, 0 # index
LOOP_MAJOR_START:
mulli r5, r4, 0x14
add r5, REG_MAJOR_TABLE_START, r5 # Get address for current table entry
lbz r6, 0x1(r5) # Major ID
cmpw r6, REG_MAJOR_ID
bne LOOP_MAJOR_CONTINUE
# Here we have found the proper major ID, load the address of the minor table
lwz r3, 0x10(r5) # Load pointer to minor scene table
b LOOP_MAJOR_EXIT
LOOP_MAJOR_CONTINUE:
addi r4, r4, 1
cmpwi r4, 0x2C # Last scene is 0x2C = Single-button mode
ble LOOP_MAJOR_START
LOOP_MAJOR_EXIT:

# Seems like minor may not be sorted either so just loop through that too
LOOP_MINOR_INIT:
li r4, 0 # index
LOOP_MINOR_START:
mulli r5, r4, 0x18
add r5, r3, r5 # Get address for current table entry
lbz r6, 0x0(r5) # Get minor ID of the current entry
cmpw r6, REG_MINOR_ID
bne LOOP_MINOR_CONTINUE
# Here we have found the proper MINOR ID, load the address of the minor table
lbz r3, 0xC(r5) # Load common minor ID
b LOOP_MINOR_EXIT
LOOP_MINOR_CONTINUE:
addi r4, r4, 1
cmpwi r6, 0xFF # Last scene is 0x2C = Single-button mode
bne LOOP_MINOR_START
LOOP_MINOR_EXIT:

restore
blr