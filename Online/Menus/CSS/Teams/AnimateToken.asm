################################################################################
# Address: 0x8026295c # CSS_BigFunc... Before animating the tokens color
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Do not override 29, we need its value
.set REG_CSSDT_ADDR, 28
.set REG_TEAM_IDX, REG_CSSDT_ADDR-1

backup
loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
bne EXIT # exit if not on TEAMS mode

# Ensure we are not locked in
lwz r3, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne EXIT # No changes when locked-in

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

cmpwi REG_TEAM_IDX, 3
beq SKIP_COLOR_MAP

subi REG_TEAM_IDX, REG_TEAM_IDX, 1
SKIP_COLOR_MAP:

stb REG_TEAM_IDX, 0x6 (r29) # this is the original line

b EXIT

EXIT:
restore
lbz r0, 0x6 (r29) # this is the original line
