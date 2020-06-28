################################################################################
# Address: 0x80262004 # CSS_BigFunc... after cursor position is checked
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_MSRB_ADDR, 4

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

loadwz r3, CSSDT_BUF_ADDR # Load where buf is stored
lwz REG_MSRB_ADDR, CSSDT_MSRB_ADDR(r3)

lbz r3, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
cmpwi r3, 0
beq EXIT # Only allow de-select when not locked-in

# When locked-in, don't allow unselect
branch r12, 0x80262154

EXIT:
rlwinm	r0, r19, 2, 22, 29
