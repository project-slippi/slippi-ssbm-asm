################################################################################
# Address: 0x802620ac # CSS_BigFunc... after B button press is checked
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

lbz r3, CSSDT_CHAT_WINDOW_OPENED(r3)
cmpwi r3, 0
bne SKIP_UNSELECT # skip input if chat window is opened

lbz r3, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
cmpwi r3, 0
beq EXIT # Only allow de-select when not locked-in

SKIP_UNSELECT:
# When locked-in, don't allow unselect
branch r12, 0x80262154

EXIT:
lbz	r7, 0x0004(r31)
