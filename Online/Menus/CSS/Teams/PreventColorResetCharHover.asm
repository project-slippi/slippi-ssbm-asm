################################################################################
# Address: 0x80260c28 # CSS_BigFunc... Before invoking
# CSS_CursorHighlightUpdateCSPInfo when hovering over a char
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

# Ensure we are not locked in
lwz r3, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne EXIT # No changes when locked-in

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

cmpwi REG_TEAM_IDX, 0
beq EXIT

lwz r4, -0x49F0(r13) # base address where css selections are stored
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 0x24
add REG_PORT_SELECTIONS_ADDR, r4, r3

lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
mr REG_INTERNAL_CHAR_ID, r3

# Get Char Id
load r3, 0x803f0a48
mr r4, r3
addi r5, r3, 0x03C2
lbzu	r3, 0x0(r5)
mulli	r3, r3, 28
add	r4, r4, r3
lbz	r3, 0x00DD (r4) # char id
mr REG_EXTERNAL_CHAR_ID, r3

mr r3, REG_TEAM_IDX
mr r4, REG_EXTERNAL_CHAR_ID
branchl r12, FN_GetTeamCostumeIndex
mr REG_COSTUME_IDX, r3

# Store costume index selection in game
lwz	r5, -0x49F0 (r13) # P1 Players Selections
stb	REG_COSTUME_IDX, 0x73 (r5)
load r5, 0x803F0E09 # P1 Char Menu Data
stb REG_COSTUME_IDX, 0x0(r5)

b EXIT

EXIT:
restore
stbu r20, 0x03C2(r24)
