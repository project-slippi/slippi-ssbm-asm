################################################################################
# Address: INJ_InitDebugInputs
################################################################################

.include "Common/Common.s"
.include "Online/Online.s" # Required for logf buffer, should fix that
.include "./DebugInputs.s"

b CODE_START

DATA_BLRL:
blrl
.long 0 # Buffer

CODE_START:

# logf LOG_LEVEL_WARN, "Init..."

li r3, DIB_SIZE
branchl r12, HSD_MemAlloc

bl DATA_BLRL
mflr r4
stw r3, 0(r4) # Write address to static address

li r4, DIB_SIZE
branchl r12, Zero_AreaLength

EXIT:
lfs f1, -0x5738(rtoc)