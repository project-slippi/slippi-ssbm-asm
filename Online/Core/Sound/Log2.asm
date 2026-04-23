################################################################################
# Address: 0x80028164
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

logf LOG_LEVEL_NOTICE, "[Hammer End] Handle 0x%X. Count %d", "lwz r5, -0x7DAC(13)", "lwz r6, -0x527C(13)"

lwz	r0, -0x7DB0 (r13) # replaced line

