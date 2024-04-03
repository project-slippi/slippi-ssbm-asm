################################################################################
# Address: 0x80262768 # CSS_PTokenThinkFunc, After Player index is loaded in 1P mode
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

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

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

cmpwi REG_TEAM_IDX, 3
beq SKIP_COLOR_MAP

subi REG_TEAM_IDX, REG_TEAM_IDX, 1
SKIP_COLOR_MAP:

stb	REG_TEAM_IDX, 0x6(r29)

# b EXIT

EXIT:
restore
addi	r3, r28, 0 # original line