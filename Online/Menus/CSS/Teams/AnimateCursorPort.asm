################################################################################
# Address: 0x80262478 # CSS_BigFunc... Before animating the cursor
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_DATA_BUFFER, 31
.set REG_CSSDT_ADDR, REG_DATA_BUFFER-1
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


# Map to proper player port
lbz r6, -0x49B0(r13) # player index
cmpwi r6, 0
beq SKIP_PORT_CALC
cmpwi r6, 1
beq ADD_PORT_1_OFFSET
cmpwi r6, 2
beq ADD_PORT_2_OFFSET
cmpwi r6, 3
beq ADD_PORT_3_OFFSET


ADD_PORT_1_OFFSET:
li r6, 4
b SKIP_PORT_CALC
ADD_PORT_2_OFFSET:
li r6, 8
b SKIP_PORT_CALC
ADD_PORT_3_OFFSET:
li r6, 12
b SKIP_PORT_CALC

SKIP_PORT_CALC:

# if is green, leave as is, else substract 1
cmpwi REG_TEAM_IDX, 3
beq SKIP_COLOR_MAP

subi REG_TEAM_IDX, REG_TEAM_IDX, 1
SKIP_COLOR_MAP:

add REG_TEAM_IDX, REG_TEAM_IDX, r6

mr r3, REG_TEAM_IDX
#logf LOG_LEVEL_NOTICE, "CURSOR COLOR r3: %d", "mr r5, 3", "mr r6, 6"
branchl r12, FN_IntToFloat

b EXIT

EXIT:
restore
# Restore original values to temp registers
lwz r3, 0x3C(sp)
li r4, 6
li r5, 1024
load r6, 0x8036410c
li r7, 1 # restore original line
