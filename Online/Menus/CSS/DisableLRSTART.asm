################################################################################
# Address: 0x80266bc4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

branch r12, 0x80266bf4 # Skip LRA code

EXIT:
li	r3, 0
