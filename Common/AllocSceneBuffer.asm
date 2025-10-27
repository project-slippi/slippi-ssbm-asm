################################################################################
# Address: 0x801a4cb4
################################################################################

################################################################################
# This file allocates a scene buffer. This buffer will persist throughout a scene
# and should be guaranteed to exist. It is typically used to execute EXI commands
# without allocating a new buffer. An argument could be made that we should just
# allocate new buffers when they're needed but that would be kind of slow if
# we need to do it often, say for example for logging. Though we shouldn't have
# logs that are frequently hit in prod anyways so maybe we should consider getting
# rid of this.
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

b CODE_START

DATA_BLRL:
blrl
.byte 0 # one shot bool
.align 2

CODE_START:
# On Dolphin, a buffer has been allocated from the heap created in Bootloader/main.asm
# This heap was created before the main heap (HSD), and we need to switch to it for
# consoles. Somewhere along the line, the main heap seems to get corrupted and produces
# some undefined behavior in the form of GFX bugs and erroneous logs from HSD_CheckHeap (0x80015df8)

# In this one shot, we do free the buffer correctly by calling OSFreeToHeap, which fixes
# the errorneous logs but not the GFX issues. The opposite is also true... If we
# call HSD_Free on a previously allocated buffer, it *does* fix the GFX issues but
# not the errorneous logs.
# It should be noted that the buffer we free from the main heap doesnt have to be 
# our scene buffer, this also works when we free the SIS buffer, which is the first
# HSD_MemAlloc call.
bl DATA_BLRL
mflr r4
lbz r3, 0x0(r4)
cmpwi r3, 0
bne SKIP_FREE
# Run one shot
li r3, 1
stb r3, 0x0(r4) # Set one shot to true
lwz r4, OFST_R13_SB_ADDR(r13)
cmpwi r4, 0
beq SKIP_FREE

# NOTE: If the heap creation order is ever changed, this will need to be updated.
# Free original scene buffer correctly
li r3, 0 # Heap 0 that was created in Bootloader/main.asm
branchl r12, 0x80343fec # OSFreeToHeap

# Free an early alloc'd buffer
lwz r3, -0x3D30(r13) # SIS buffer
branchl r12, HSD_Free
# Realloc SIS buffer
lwz r3, -0x3D38(r13) # size
branchl r12, HSD_MemAlloc
stw r3, -0x3D30(r13) # SIS buffer
stw r3, -0x3D34(r13) # Copy
SKIP_FREE:

# Realloc scene buffer as the HSD heap gets recreated between scenes
li r3, 128
branchl r12, HSD_MemAlloc
# Store to r13 offset since this is what the other codes reference. But in the
# future if we want to transition off r13 offsets we could store the buffer
# in data in this file and use computeBranchTargetAddress to fetch it.
stw r3, OFST_R13_SB_ADDR(r13)

# Original
li r0, 0
