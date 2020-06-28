################################################################################
# Address: 0x80261e5c
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

branch r12, 0x80261f38 # Skip nametag box show handler

EXIT:
lfs f1, 0x0088(sp)
