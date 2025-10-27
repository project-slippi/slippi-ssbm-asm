################################################################################
# Address: 0x801a4cb4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# This file allocates a scene buffer. This buffer will persist throughout a scene
# and should be guaranteed to exist. It is typically used to execute EXI commands
# without allocating a new buffer. An argument could be made that we should just
# allocate new buffers when they're needed but that would be kind of slow if
# we need to do it often, say for example for logging. Though we shouldn't have
# logs that are frequently hit in prod anyways so maybe we should consider getting
# rid of this.

CODE_START:
# On Dolphin a buffer has been allocated from the heap created in Bootloader/main.asm.
# We want to free that buffer the first time we execute this logic so that the
# buffer always exists prior and after.
# If the heap creation order is ever changed, this will need to be updated.

li r3, 0 # Heap index 0 that was created in Bootloader/main.asm
lwz r4, OFST_R13_SB_ADDR(r13)
branchl r12, 0x80343fec # OSFreeToHeap

# Realloc scene buffer
li r3, 0
li r4, 128
branchl r12, 0x80343ef0 # OSAllocFromHeap
# Store to r13 offset since this is what the other codes reference. But in the
# future if we want to transition off r13 offsets we could store the buffer
# in data in this file and use computeBranchTargetAddress to fetch it.
stw r3, OFST_R13_SB_ADDR(r13)

# Original
li r0, 0
