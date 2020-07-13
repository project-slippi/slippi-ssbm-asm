################################################################################
# Address: 0x8025b8a4   # injecting where the NOW LOADING screen is created
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online SSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_SSS
bne EXIT # If not online CSS, continue as normal

branch r12, 0x8025b8cc # Skip LRA code

EXIT:
li	r3, 0
