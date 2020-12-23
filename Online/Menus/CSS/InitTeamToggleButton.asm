################################################################################
# Address: 0x802652f4 # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PROPERTIES, 31
.set REG_CSSDT_ADDR, 30
.set REG_IS_HOVERING, 29
.set REG_PORT_SELECTIONS_ADDR, 28

# float registers
.set REG_F_0, 31
.set REG_F_1, REG_F_0-1

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal
b INIT_BUTTON

################################################################################
# Properties
################################################################################
PROPERTIES:
blrl
# Toggle Button Bounds
.set TPO_BOUNDS_ICON_TOP, 0
.float -2.5
.set TPO_BOUNDS_ICON_BOTTOM, TPO_BOUNDS_ICON_TOP + 4
.float -5
.set TPO_BOUNDS_ICON_LEFT, TPO_BOUNDS_ICON_BOTTOM + 4
.float -23.5
.set TPO_BOUNDS_ICON_RIGHT, TPO_BOUNDS_ICON_LEFT + 4
.float -17.5

.set TPO_FLOAT_0, TPO_BOUNDS_ICON_RIGHT + 4
.float 0.0
.set TPO_FLOAT_1, TPO_FLOAT_0 + 4
.float 1.0


.align 2

################################################################################
# Start Init Function
################################################################################
INIT_BUTTON:
.set REG_CHAT_INPUTS, 14
.set REG_ICON_GOBJ, 20
.set REG_ICON_JOBJ, 21
.set REG_DATA_BUFFER, 23
backup

loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR

# INIT PROPERTIES
bl PROPERTIES
mflr REG_PROPERTIES

lfs REG_F_0, TPO_FLOAT_0(REG_PROPERTIES)
lfs REG_F_1, TPO_FLOAT_1(REG_PROPERTIES)

# Set default team id
li r3, 0
stb r3, CSSDT_TEAM_ID(REG_CSSDT_ADDR)

# Get Memory Buffer for Chat Window Data Table
li r3, CSSTIDT_SIZE # Teams Icon Buffer Size
branchl r12, HSD_MemAlloc
mr REG_DATA_BUFFER, r3

# Zero out CSS data table
li r4, CSSTIDT_SIZE
branchl r12, Zero_AreaLength

# Add CSS DataTable Address to Data Buffer
mr r3, REG_CSSDT_ADDR # store address to CSS Data Table
stw r3, CSSCWDT_CSSDT_ADDR(REG_DATA_BUFFER)

# create gobj for think function
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr REG_ICON_GOBJ, r3 # save GOBJ pointer

# create jbobj (Team Switch Icon)
lwz r3, -0x49C8(r13) # = 0x80f454c8 pointer to MenuModel JObj Descriptor
lwz	r3, 0x0030 (r3)
lwz r3, 0x08(r3) # move to it's first child
# Find 8th child
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
# Now get first child which is P1 Switch icon
lwz r3, 0x08(r3) # move to it's first child
branchl r12,0x80370e44 #Create Jboj
mr  REG_ICON_JOBJ,r3

# Move to the correct position
mr r3, REG_ICON_JOBJ
load r4, 0xC19C0000 # -19.5
stw r4, 0x38(r3) # set X position
load r4, 0xC019999A # -2.4
stw r4, 0x40(r3) # set Y position

# Setup proper animations
# find child mat animation joint first
lwz	r3, -0x49C8 (r13)
lwz	r3, 0x0038 (r3)
lwz r3, 0x08(r3) # move to it's first child
# Find 8th child
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
# Now get first child which is P1 Switch icon
lwz r5, 0x08(r3) # move to it's first child

# find animation joint
lwz	r3, -0x49C8 (r13)
lwz	r3, 0x0034 (r3)
lwz r3, 0x08(r3) # move to it's first child
# Find 8th child
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
# Now get first child which is P1 Switch icon
lwz r4, 0x08(r3) # move to it's first child

# find shape joint
lwz	r3, -0x49C8 (r13)
lwz	r3, 0x003C (r3)
lwz r3, 0x08(r3) # move to it's first child
# Find 8th child
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
lwz r3, 0x0C(r3) # move to it's sibling
# Now get first child which is P1 Switch icon
lwz r6, 0x08(r3) # move to it's first child

mr r3, REG_ICON_JOBJ
branchl r12, JObj_AddAnimAll

# Add JOBJ To GObj
mr  r3,REG_ICON_GOBJ
li r4, 4
mr  r5,REG_ICON_JOBJ
branchl r12,0x80390a70 # void GObj_AddObject(GOBJ *gobj, u8 unk, void *object)

# Add GX Link that draws the background
mr  r3,REG_ICON_GOBJ
load r4,0x80391070 # 80302608, 80391044, 8026407c, 80391070, 803a84bc
li  r5, 2
li  r6, 128
branchl r12,GObj_SetupGXLink # void GObj_AddGXLink(GOBJ *gobj, void *cb, int gx_link, int gx_pri)

# Add User Data to GOBJ ( Our buffer )
mr r3, REG_ICON_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, REG_DATA_BUFFER # memory pointer of allocated buffer above
branchl r12, GObj_Initialize

# Set Think Function that runs every frame
mr r3, REG_ICON_GOBJ # set r3 to GOBJ pointer
bl TEAM_BUTTON_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc


# Animate to frame 1
mr r3, REG_ICON_JOBJ
fmr f1, REG_F_1
#lfs	f1, -0x35FC (rtoc)
branchl r12, JObj_ReqAnimAll # (jobj, frames)

mr r3, REG_ICON_JOBJ
branchl r12, JObj_AnimAll

restore
b EXIT


################################################################################
# Function for updating online status graphics every frame
################################################################################
TEAM_BUTTON_THINK:
.set JOBJ_CHILD_OFFSET, 0x34 # Pointer to store Child JOBJ on the SP
blrl

backup

# Get text properties address
bl PROPERTIES
mflr REG_PROPERTIES

# Initialize hover state as false
li REG_IS_HOVERING, 0

################################################################################
# Handle Pressing Top Button
################################################################################
# Ensure we are not in name entry screen
lbz r3, -0x49AA(r13)
cmpwi r3, 0
bne TEAM_BUTTON_THINK_EXIT

# Ensure we are not locked in
loadwz r3, CSSDT_BUF_ADDR # Load where buf is stored
lwz r3, CSSDT_MSRB_ADDR(r3)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne TEAM_BUTTON_THINK_EXIT # No changes when locked-in

# Check if cursor is anywhere on the top bar (and left of BACK button)
loadwz r4, 0x804A0BC0 # This gets ptr to cursor position on CSS

lfs f1, 0xC(r4) # Get x cursor pos
lfs f2, 0x10(r4) # Get y cursor pos
logf LOG_LEVEL_WARN, "X: %f Y: %f"

# Check if cursor is outside top boundary
lfs f1, 0xC(r4) # Get x cursor pos
lfs f2, 0x10(r4) # Get y cursor pos
lfs f3, TPO_BOUNDS_ICON_TOP(REG_PROPERTIES)
lfs f4, TPO_BOUNDS_ICON_BOTTOM(REG_PROPERTIES)
lfs f5, TPO_BOUNDS_ICON_LEFT(REG_PROPERTIES)
lfs f6, TPO_BOUNDS_ICON_RIGHT(REG_PROPERTIES)

fcmpo cr0, f2, f3
bgt TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f2, f4
blt TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f1, f5
blt TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f1, f6
bgt TEAM_BUTTON_THINK_EXIT


# If we get here, the cursor is within the bounds of the unselected button
li REG_IS_HOVERING, 1

# Check if a button was pressed this frame
load r4, 0x804c20bc
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 68
add r3, r4, r3
lwz r3, 0x8(r3) # get inputs
rlwinm. r3, r3, 0, 23, 23 # check if A was pressed
beq TEAM_BUTTON_THINK_EXIT

bl FN_SWITCH_PLAYER_TEAM


TEAM_BUTTON_THINK_EXIT:
restore
blr


################################################################################
# Function: Changes current player team
################################################################################
# skip my test if pad was not pressed
FN_SWITCH_PLAYER_TEAM:
.set REG_CHAR_ID, 27
.set REG_TEAM_IDX, 26
backup

# Get location from which we can find selected character
lwz r4, -0x49F0(r13) # base address where css selections are stored
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 0x24
add REG_PORT_SELECTIONS_ADDR, r4, r3
# should do some checks or something here maybe?

mr REG_CHAR_ID, r3

# Get Char Id
load r3, 0x803f0a48
mr r4, r3
addi r5, r3, 0x03C2
lbzu	r3, 0x0(r5)
mulli	r3, r3, 28
add	r4, r4, r3
lbz	r3, 0x00DC (r4) # char id
mr REG_CHAR_ID, r3


# Get Costume Index increment and store
lwz	r4, -0x49F0 (r13)
lbz r4, 0x73 (r4)
addi r4, r4, 1
cmpwi r4, 4
blt FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM
li r4, 1 # reset to 1 (RED)

FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM:

mr REG_TEAM_IDX, r4

backupall
mr r3, REG_TEAM_IDX
bl FN_CHANGE_PORTRAIT_BG
restoreall

# store costume index
lwz	r5, -0x49AB (r13)
stb REG_TEAM_IDX, 0(r5)

# Store team/costume selection in game and data table
lwz	r5, -0x49F0 (r13)
stb	REG_TEAM_IDX, 0x73 (r5)

# calculate costume offset for a given team
mulli r4, REG_TEAM_IDX, 30 # offset to costume = Costume Index * 30
add r4, r3, r4 # costume id =  char id + offset to costume
li r3, 0 # player index
li r5, 0 # unk ?
branchl r12, 0x8025d5ac # UpdateCharTexture Updates Costume Texture


# Color the portrait to the desired color
lwz r3, -0x49E0 (r13) # root live jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 0x29 # index of portrait bg
li r6, -1
branchl r12, JObj_GetJObjChild


# Play team switch sound
li	r3, 2
branchl r12, SFX_Menu_CommonSound


FN_SWITCH_PLAYER_TEAM_EXIT:
restore
blr

FN_CHANGE_PORTRAIT_BG:
.set REG_TEAM_ID, 31
backup
mr REG_TEAM_ID, r3


logf LOG_LEVEL_NOTICE, "FN_CHANGE_PORTRAIT_BG r3: %d", "mr r5, 31"

cmpwi REG_TEAM_ID, 3
beq FN_CHANGE_PORTRAIT_BG_GREEN
cmpwi REG_TEAM_ID, 2
beq FN_CHANGE_PORTRAIT_BG_BLUE
cmpwi REG_TEAM_ID, 1
beq FN_CHANGE_PORTRAIT_BG_RED

FN_CHANGE_PORTRAIT_BG_BLUE:
li REG_TEAM_ID, 0
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR
FN_CHANGE_PORTRAIT_BG_GREEN:
li REG_TEAM_ID, 1
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR
FN_CHANGE_PORTRAIT_BG_RED:
li REG_TEAM_ID, 2
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR

FN_CHANGE_PORTRAIT_BG_SKIP_COLOR:

logf LOG_LEVEL_NOTICE, "FN_CHANGE_PORTRAIT_BG after r3: %d", "mr r5, 31"

# Store team id on r13 offset that stores port
#mr r4, r3
subi	r3, r13, 26056
mr r4, REG_TEAM_ID
stb r4, 0x0(r3)
li r3, 0
branchl r12, 0x8025db34 # CSS_CursorHighlightUpdateCSPInfo

FN_CHANGE_PORTRAIT_BG_EXIT:
restore
blr


EXIT:
li r3, 0
addi r4, r24, 0
branchl r12, Text_CreateStruct
