################################################################################
# Address: 0x800280fc
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

stw	r0, -0x5278 (r13) # replaced line

logf LOG_LEVEL_NOTICE, "[Hammer Start] Handle 0x%X. Count %d", "lwz r5, -0x7DAC(13)", "lwz r6, -0x527C(13)"