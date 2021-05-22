################################################################################
# Address: 0x802600a8 # CSS_CostumeChange
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

# if on teams mode, skip
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
beq EXIT_COSTUME_CHANGE # exit if not on TEAMS mode

# Ensure we are not locked in
loadwz r3, CSSDT_BUF_ADDR # Load where buf is stored
lwz r3, CSSDT_MSRB_ADDR(r3)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
beq EXIT # No changes when locked-in

EXIT_COSTUME_CHANGE:

# Exit CSS_CostumeChange
branch r12, 0x8026028c

EXIT:
lis r3, 0x803F
