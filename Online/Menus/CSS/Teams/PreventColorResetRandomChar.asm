################################################################################
# Address: 0x80260b90 # CSS_CursorHighlightUpdateCSPInfo... Before invoking
# CSS_CursorHighlightUpdateCSPInfo
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_CSSDT_ADDR, 31
.set REG_TEAM_IDX, REG_CSSDT_ADDR-1
.set REG_INTERNAL_CHAR_ID, REG_TEAM_IDX-1
.set REG_EXTERNAL_CHAR_ID, REG_INTERNAL_CHAR_ID-1
.set REG_COSTUME_IDX, REG_EXTERNAL_CHAR_ID-1
.set REG_PORT_SELECTIONS_ADDR, REG_COSTUME_IDX-1

backup
loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
bne EXIT # exit if not on TEAMS mode

lwz r4, -0x49F0(r13) # base address where css selections are stored
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 0x24
add REG_PORT_SELECTIONS_ADDR, r4, r3

lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
mr REG_INTERNAL_CHAR_ID, r3

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

mr r3, REG_TEAM_IDX
mr r4, REG_INTERNAL_CHAR_ID
branchl r12, FN_GetTeamCostumeIndex
mr REG_COSTUME_IDX, r3

# Store costume index selection in game
lwz	r5, -0x49F0 (r13) # P1 Players Selections
stb	REG_COSTUME_IDX, 0x73 (REG_PORT_SELECTIONS_ADDR)
load r5, 0x803F0E09 # P1 Char Menu Data
stb REG_COSTUME_IDX, 0x0(r5)
lbz r3, 0x1(r5)
stb r3, 0x2(r5)

# Update costume CSP
li r3, 0 # player index
mr r4,REG_INTERNAL_CHAR_ID
mr r5,REG_COSTUME_IDX
li	r6, 0
branchl r12,FN_CSSUpdateCSP

b EXIT

EXIT:
restore
li r0, 0
