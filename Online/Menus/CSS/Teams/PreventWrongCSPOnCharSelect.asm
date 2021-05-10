################################################################################
# Address: 0x80260c88 # CSS_BigFunc... Right on character select logic
# after setting the external char id to r4 and saving it somewhere
################################################################################

# TODO: This file should be deleted if a better way to handle Hover Costumes is found.

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_CSSDT_ADDR, 31
.set REG_TEAM_IDX, REG_CSSDT_ADDR-1
.set REG_EXTERNAL_CHAR_ID, REG_TEAM_IDX-1
.set REG_COSTUME_IDX, REG_EXTERNAL_CHAR_ID-1
.set REG_ORIG_R3, REG_COSTUME_IDX-1

backup
mr REG_EXTERNAL_CHAR_ID, r4
mr REG_ORIG_R3, r3
loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
bne EXIT # exit if not on TEAMS mode

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

mr r3, REG_TEAM_IDX
mr r4, REG_EXTERNAL_CHAR_ID
branchl r12, FN_GetTeamCostumeIndex
mr REG_COSTUME_IDX, r3

# Store costume index selection in game
lwz	r5, -0x49F0 (r13) # P1 Players Selections
stb	REG_COSTUME_IDX, 0x73 (r5)
load r5, 0x803F0E09 # P1 Char Menu Data
stb REG_COSTUME_IDX, 0x0(r5)

# Update costume CSP
li r3, 0 # player index
mr r4,REG_EXTERNAL_CHAR_ID
mr r5,REG_COSTUME_IDX
li	r6, 0
branchl r12,FN_CSSUpdateCSP

b EXIT

EXIT:
mr r4, REG_EXTERNAL_CHAR_ID
mr r3, REG_ORIG_R3
restore
stb	r4, 0x0070 (r3) # original line
