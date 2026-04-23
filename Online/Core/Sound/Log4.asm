################################################################################
# Address: 0x8002806c
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

stw	r3, -0x7DAC (r13) # replaced line

logf LOG_LEVEL_NOTICE, "[Hammer Start 2] Handle 0x%X. Count %d", "lwz r5, -0x7DAC(13)", "lwz r6, -0x527C(13)"