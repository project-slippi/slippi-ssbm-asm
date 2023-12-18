################################################################################
# Address: 8016e9e4
################################################################################

.include "Common/Common.s"
.include "Playback/Playback.s"

.set REG_DirectoryBuffer, 30
.set REG_CurReadPos, 29
.set REG_ItemCount, 28
.set REG_TempBuffer, 27
.set REG_Offset, 26

# Execute replaced code line
addi r30, r3, 0

backup

lwz REG_DirectoryBuffer, playbackDataBuffer(r13)

####################################################################################################
# Step 1: First we need to count how many items there are so we can allocate a buffer
####################################################################################################
lwz REG_CurReadPos, PDB_RESTORE_BUF_ADDR(REG_DirectoryBuffer)
li REG_ItemCount, 0
COUNT_LOOP_START:
lwz r3, 0(REG_CurReadPos) # Target address (memcpy destination)
cmpwi r3, 0 # If null ptr, loop over
beq COUNT_LOOP_EXIT

# Increment item count
addi REG_ItemCount, REG_ItemCount, 1

lwz r3, 4(REG_CurReadPos) # size
add REG_CurReadPos, REG_CurReadPos, r3
addi REG_CurReadPos, REG_CurReadPos, 8
b COUNT_LOOP_START
COUNT_LOOP_EXIT:

####################################################################################################
# Step 2: Allocate a buffer to store cursor positions where items start
####################################################################################################
mulli r3, REG_ItemCount, 4 # Allocate space for item count u32s
branchl r12, HSD_MemAlloc
mr REG_TempBuffer, r3

####################################################################################################
# Step 3: Next we need to iterate again to store all of the cursor positions
####################################################################################################
lwz REG_CurReadPos, PDB_RESTORE_BUF_ADDR(REG_DirectoryBuffer)
li REG_Offset, 0
STORE_CURSORS_LOOP_START:
lwz r3, 0(REG_CurReadPos) # Target address (memcpy destination)
cmpwi r3, 0 # If null ptr, loop over
beq STORE_CURSORS_LOOP_EXIT

# Store current read position to buffer
stwx REG_CurReadPos, REG_TempBuffer, REG_Offset
addi REG_Offset, REG_Offset, 4

lwz r3, 4(REG_CurReadPos) # size
add REG_CurReadPos, REG_CurReadPos, r3
addi REG_CurReadPos, REG_CurReadPos, 8
b STORE_CURSORS_LOOP_START
STORE_CURSORS_LOOP_EXIT:

####################################################################################################
# Step 4: Finally we loop backwards to clean up in reverse order. This is necessary in the case
# where the gecko code list includes the same injection twice, without iterating backwards we
# would cause Dolphin to crash in that case
####################################################################################################
subi r3, REG_ItemCount, 1
mulli REG_Offset, r3, 4
CLEANUP_LOOP_START:
cmpwi REG_Offset, 0 # If offset is less than zero, exit loop
blt CLEANUP_LOOP_EXIT

# Get current position
lwzx REG_CurReadPos, REG_TempBuffer, REG_Offset

lwz r3, 0(REG_CurReadPos) # target
addi r4, REG_CurReadPos, 8 # source
lwz r5, 4(REG_CurReadPos) # size
branchl r12, memcpy

lwz r3, 0(REG_CurReadPos)
lwz r4, 4(REG_CurReadPos) # size
branchl r12, TRK_flush_cache

subi REG_Offset, REG_Offset, 4
b CLEANUP_LOOP_START
CLEANUP_LOOP_EXIT:

restore
