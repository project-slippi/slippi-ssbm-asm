################################################################################
# Address: 0x80231f58 # Address in RulesInitialization function that load
# foreground elements
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PROPERTIES, 31
.set REG_TEXT_STRUCT_ADDR, 30

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_DIRECT
blt EXIT # exit if not on DIRECT or TEAMS mode

b INIT

################################################################################
# Properties
################################################################################
PROPERTIES:
blrl
# Top Bar Bounds
.set TEXT_X, 0
.float -7.2
.set TEXT_Y, TEXT_X + 4
.float -8
.set TEXT_Z, TEXT_Y + 4
.float 18.5
.set TEXT_SCALE, TEXT_Z + 4
.float 0.03
.align 2

################################################################################
# Start Init Function
################################################################################
INIT:
backup

# Get text properties address
bl PROPERTIES
mflr REG_PROPERTIES

li r3, 0x7 #  Text ID
li r4, 1 # Use Slippi ID = false
li r5, 2 # use premade text fn
li r6, 0 # gx_link
li r7, 1 # kern close, center text and fixed width
lfs	f1, TEXT_X (REG_PROPERTIES)
lfs	f2, TEXT_Y (REG_PROPERTIES)
lfs	f3, TEXT_Z (REG_PROPERTIES)
lfs	f4, TEXT_SCALE (REG_PROPERTIES)
branchl r12, FG_CreateSubtext

restore

EXIT:
li r3, 1