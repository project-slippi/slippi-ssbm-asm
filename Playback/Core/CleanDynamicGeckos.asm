################################################################################
# Address: 8016e9e4
################################################################################

.include "Common/Common.s"

.set REG_DirectoryBuffer, 30
.set REG_CleanupBufReadPos, 29

# Execute replaced code line
addi r30, r3, 0

backup

lwz REG_DirectoryBuffer, primaryDataBuffer(r13)
lwz REG_CleanupBufReadPos, PDB_RESTORE_BUF_ADDR(REG_DirectoryBuffer)

LOOP_START:
lwz r3, 0(REG_CleanupBufReadPos) # Target address (memcpy destination)
cmpwi r3, 0 # If null ptr, we are done restoring
beq LOOP_EXIT

addi r4, REG_CleanupBufReadPos, 8 # source
lwz r5, 4(REG_CleanupBufReadPos) # size
branchl r12, memcpy

lwz r3, 0(REG_CleanupBufReadPos)
lwz r4, 4(REG_CleanupBufReadPos) # size
branchl r12, TRK_flush_cache

b LOOP_START

LOOP_EXIT:

restore
