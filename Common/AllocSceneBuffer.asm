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

CODE_START:

# Realloc scene buffer as the HSD heap gets recreated between scenes
li r3, 128
branchl r12, HSD_MemAlloc
# Store to r13 offset since this is what the other codes reference. But in the
# future if we want to transition off r13 offsets we could store the buffer
# in data in this file and use computeBranchTargetAddress to fetch it.
stw r3, OFST_R13_SB_ADDR(r13)

# Original
li r0, 0
