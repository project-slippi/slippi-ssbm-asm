################################################################################
# Address: 0x80389814
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

branchl r12, 0x8038987c # replaced code line

logf LOG_LEVEL_WARN, "[Stop Sound] Arg(r3): 0x%X. SoundId?: %d", "lwz r5, 0(23)", "mr r6, 24"