################################################################################
# Address: 0x80260310 # Start of CSS_BigFunc...
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

# load MSRB address and get match state info
loadwz r3, CSSDT_BUF_ADDR
lwz r3, CSSDT_MSRB_ADDR(r3)
branchl r12, FN_LoadMatchState

EXIT:
# Handle replaced code line
li r0, 0
