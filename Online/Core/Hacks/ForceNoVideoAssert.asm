################################################################################
# Address: 0x80376304
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

#logf LOG_LEVEL_NOTICE, "XFB Status is not 4. Value: %d", "mr r5, 0"

# Log XFB status value
bl STRING
mflr r3
mr r4, r0
crclr 6
branchl r12, OSReport

branch r12, 0x80376384 # Exit function

STRING:
blrl
.string "XFB Status is not 4. Value: %d\n"
.align 2
