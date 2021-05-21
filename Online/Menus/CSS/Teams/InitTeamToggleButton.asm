################################################################################
# Address: INJ_InitTeamToggleButton # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/Teams/Teams.s"

.set REG_PROPERTIES, 31
.set REG_CSSDT_ADDR, 30
.set REG_IS_HOVERING, 29
.set REG_PORT_SELECTIONS_ADDR, 28
.set REG_INTERNAL_CHAR_ID, 27
.set REG_EXTERNAL_CHAR_ID, 26
.set REG_TEAM_IDX, 25
.set REG_COSTUME_IDX, 24

# float registers
.set REG_F_0, 31
.set REG_F_1, REG_F_0-1

.set JOBJ_CHILD_OFFSET, 0x34 # Pointer to store Child JOBJ on the SP
.set ICON_JOBJ_OFFSET, 0x28 # offset from GOBJ to HSD Object (Jobj we assigned)

b CODE_START

################################################################################
# Data
################################################################################
DATA_BLRL:
blrl
# Start with data that is accessible externally
.set EXT_TEAM_IDX, 0
.byte 1 # Will be used by SceneLoadCSS.asm

# The remaining values are properties used internally
# Toggle Button Bounds
.set TPO_BOUNDS_ICON_TOP, EXT_TEAM_IDX + 1
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

.set TPO_ICON_POS_X, TPO_FLOAT_1 + 4
.float -19.5
.set TPO_ICON_POS_Y, TPO_ICON_POS_X + 4
.float -3
.set TPO_ICON_POS_Z, TPO_ICON_POS_Y + 4
.float 0.1

.align 2

CODE_START:
# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
bne EXIT # exit if not on TEAMS mode

################################################################################
# Creates and initializes Button and queues it's THINK function
################################################################################
INIT_BUTTON:
.set REG_ICON_GOBJ, 20
.set REG_ICON_JOBJ, 21
.set REG_DATA_BUFFER, 23
backup

loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR

# INIT PROPERTIES
bl DATA_BLRL
mflr REG_PROPERTIES

lfs REG_F_0, TPO_FLOAT_0(REG_PROPERTIES)
lfs REG_F_1, TPO_FLOAT_1(REG_PROPERTIES)


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
li r4, 0
MV_TO_SIBLING:
lwz r3, 0x0C(r3) # move to it's sibling
addi r4, r4, 1
cmpwi r4, 7
blt MV_TO_SIBLING
# Now get first child which is P1 Switch icon
lwz r3, 0x08(r3) # move to it's first child
branchl r12,JObj_LoadJoint #Create Jboj
mr  REG_ICON_JOBJ,r3
# Move to the correct position
mr r3, REG_ICON_JOBJ
lwz r4, TPO_ICON_POS_X(REG_PROPERTIES)
stw r4, 0x38(r3) # set X position
lwz r4, TPO_ICON_POS_Y(REG_PROPERTIES)
stw r4, 0x3C(r3) # set Y position
lwz r4, TPO_ICON_POS_Z(REG_PROPERTIES)
stw r4, 0x40(r3) # set Z position

# Setup proper animations
# find child mat animation joint first
lwz	r3, -0x49C8 (r13)
lwz	r3, 0x0038 (r3)
lwz r3, 0x00(r3) # move to it's first child

# Find 8th child
li r4, 0
MV_TO_ANIM_SIBLING:
lwz r3, 0x04(r3) # move to it's sibling
addi r4, r4, 1
cmpwi r4, 7
blt MV_TO_ANIM_SIBLING
# Now get first child which is P1 Switch icon
lwz r5, 0x00(r3) # move to it's first child

mr r3, REG_ICON_JOBJ
li r4, 0
li r6, 0
branchl r12, JObj_AddAnimAll

# Animate the icon to RED first
mr r3, REG_ICON_JOBJ
fmr f1, REG_F_0
branchl r12, JObj_ReqAnimAll # (jobj, frames)

mr r3, REG_ICON_JOBJ
branchl r12, JObj_AnimAll

# Add JOBJ To GObj
mr  r3,REG_ICON_GOBJ
li r4, 4
mr  r5,REG_ICON_JOBJ
branchl r12,GObj_AddToObj # void GObj_AddObject(GOBJ *gobj, u8 unk, void *object)

# Add GX Link that draws the background
mr  r3,REG_ICON_GOBJ
load r4,0x80391070
li  r5, 2
li  r6, 128
branchl r12,GObj_SetupGXLink # void GObj_AddGXLink(GOBJ *gobj, void *cb, int gx_link, int gx_pri)

# Add User Data to GOBJ ( Our buffer )
mr r3, REG_ICON_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, REG_DATA_BUFFER # memory pointer of allocated buffer above
branchl r12, GObj_AddUserData

# Set Think Function that runs every frame
mr r3, REG_ICON_GOBJ # set r3 to GOBJ pointer
bl FN_TEAM_BUTTON_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

# Update textures to the right colors
bl FN_UPDATE_CSP_TEXTURES

################################################################################
# Hides Port from the portrait bg and moves franchise icon up
################################################################################
CONFIG_PORTRAIT_PORT:

# Get Franchise icon
lwz r3, -0x49E0(r13) # Points to SingleMenu live root Jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 0x2B # index of jboj child we want (franchise icon)
li r6, -1
branchl r12, JObj_GetJObjChild

lwz r3, JOBJ_CHILD_OFFSET(sp) # Franchise Icon
load r4, 0xC0400000 # -3
stw r4, 0x3C(r3) # set Y position

# Get Portrait Parent Jobj
lwz r3, -0x49E0(r13) # Points to SingleMenu live root Jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 0x29 # index of jboj child we want (portrait)
li r6, -1
branchl r12, JObj_GetJObjChild

# Get first Dobj
lwz r3, JOBJ_CHILD_OFFSET(sp) # portrait jobj
branchl r12, 0x80371BEC # HSD_JObjGetDObj

# Move to Dobj's sibling and then its mobj
lwz r3, 0x04(r3) # offset to next dobj sibling
lwz r3, 0x08(r3) # offset to Dobj's mobj

# r3 here is mobj's address (hopefully)
fmr f1, REG_F_0 # float 0.0
branchl r12, 0x80363C2C # HSD_MObjSetAlpha(mobj, float alpha)

restore
b EXIT
################################################################################
# Function: Handles per frame updates of Custom Team Button
################################################################################
FN_TEAM_BUTTON_THINK:
blrl

backup

mr REG_ICON_GOBJ, r3
lwz REG_ICON_JOBJ, ICON_JOBJ_OFFSET(REG_ICON_GOBJ) # Get Jobj

# Ensure we are not in name entry screen
lbz r3, -0x49AA(r13)
cmpwi r3, 0
bne FN_TEAM_BUTTON_THINK_EXIT

# Ensure we are not locked in
loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR # Load where buf is stored
lwz r3, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne FN_TEAM_BUTTON_THINK_EXIT # No changes when locked-in

# Get text properties address
bl DATA_BLRL
mflr REG_PROPERTIES

li REG_IS_HOVERING, 0 # Initialize hover state as false
loadwz r4, 0x804A0BC0 # This gets ptr to cursor position on CSS

# Check if cursor is outside top boundary
lfs f1, 0xC(r4) # Get x cursor pos
lfs f2, 0x10(r4) # Get y cursor pos
lfs f3, TPO_BOUNDS_ICON_TOP(REG_PROPERTIES)
lfs f4, TPO_BOUNDS_ICON_BOTTOM(REG_PROPERTIES)
lfs f5, TPO_BOUNDS_ICON_LEFT(REG_PROPERTIES)
lfs f6, TPO_BOUNDS_ICON_RIGHT(REG_PROPERTIES)

fcmpo cr0, f2, f3
bgt FN_TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f2, f4
blt FN_TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f1, f5
blt FN_TEAM_BUTTON_THINK_EXIT
fcmpo cr0, f1, f6
bgt FN_TEAM_BUTTON_THINK_EXIT

# If we get here, the cursor is within the bounds of the unselected button
li REG_IS_HOVERING, 1

# Check if a button was pressed this frame
load r4, 0x804c20bc
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 68
add r3, r4, r3
lwz r3, 0x8(r3) # get inputs
rlwinm. r3, r3, 0, 23, 23 # check if A was pressed
beq FN_TEAM_BUTTON_THINK_EXIT

bl FN_SWITCH_PLAYER_TEAM

FN_TEAM_BUTTON_THINK_EXIT:
restore
blr


################################################################################
# Function: Updates Graphics and memory values for new team selection
################################################################################
FN_SWITCH_PLAYER_TEAM:

backup

# get CSS icon data
branchl r12,FN_GetCSSIconData
mr r5,r3
# get port's icon ID
li r3,0       # port index
mulli r3,r3,36
load r4,0x803f0a48
add r4,r3,r4
lbz	r3, 0x03C2(r4)
# get icon ID's external ID
mulli	r3, r3, 28
add	r4, r3, r5
lbz	REG_EXTERNAL_CHAR_ID, 0x00DD (r4) # char id

# Get Custom Team Index increment and store
lbz r4, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
addi r4, r4, 1
cmpwi r4, 4
blt FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM
li r4, 1 # reset to 1 (RED)

FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM:

# Store Custom Team selection in data table
stb r4, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
stb r4, EXT_TEAM_IDX(REG_PROPERTIES)

bl FN_UPDATE_CSP_TEXTURES

# Play team switch sound
li	r3, 2
branchl r12, SFX_Menu_CommonSound

FN_SWITCH_PLAYER_TEAM_EXIT:
restore
blr

################################################################################
# Function: Updates Graphics and memory values for new team selection
################################################################################
FN_UPDATE_CSP_TEXTURES:
backup

# Get location from which we can find selected character
lwz r4, -0x49F0(r13) # base address where css selections are stored
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 0x24
add REG_PORT_SELECTIONS_ADDR, r4, r3

lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
mr REG_INTERNAL_CHAR_ID, r3

lbz REG_TEAM_IDX, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
# logf LOG_LEVEL_NOTICE, "TEAM INDEX %d", "mr r5, 25"

# Animate the team icon based on team index
cmpwi REG_TEAM_IDX, 3
beq FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_G
cmpwi REG_TEAM_IDX, 2
beq FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_B
cmpwi REG_TEAM_IDX, 1
ble FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_R

FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_B:
li r3, 0
b FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_SKIP
FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_G:
li r3, 1
b FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_SKIP
FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_R:
li r3, 2

FN_SWITCH_PLAYER_TEAM_CHANGE_ICON_COLOR_SKIP:
branchl r12, FN_IntToFloat

mr r3, REG_ICON_JOBJ
branchl r12, JObj_ReqAnimAll # (jobj, frames)

mr r3, REG_ICON_JOBJ
branchl r12, JObj_AnimAll

mr r3, REG_TEAM_IDX
bl FN_CHANGE_PORTRAIT_BG

mr r3, REG_TEAM_IDX
mr r4, REG_INTERNAL_CHAR_ID
branchl r12, FN_GetTeamCostumeIndex
mr REG_COSTUME_IDX, r3

# Check if character has been selected, if not, do nothing
lbz r3, -0x49A9(r13)
cmpwi r3, 0
beq FN_SWITCH_PLAYER_TEAM_EXIT

# Store costume index selection in game
stb	REG_COSTUME_IDX, 0x73 (REG_PORT_SELECTIONS_ADDR)
load r5, 0x803F0E09 # P1 Char Menu Data
stb REG_COSTUME_IDX, 0x0(r5)
stb REG_COSTUME_IDX, CSSDT_TEAM_COSTUME_IDX(REG_CSSDT_ADDR)

# Update costume CSP
li r3, 0 # player index
mr r4,REG_EXTERNAL_CHAR_ID
mr r5,REG_COSTUME_IDX
li	r6, 0
branchl r12,FN_CSSUpdateCSP

restore
blr


################################################################################
# Function: Changes the portrait bg of the player based on custom team index
################################################################################
# Inputs:
# r3: Team IDX
################################################################################
FN_CHANGE_PORTRAIT_BG:
backup
mr REG_TEAM_IDX, r3

cmpwi REG_TEAM_IDX, 3
beq FN_CHANGE_PORTRAIT_BG_GREEN
cmpwi REG_TEAM_IDX, 2
beq FN_CHANGE_PORTRAIT_BG_BLUE
cmpwi REG_TEAM_IDX, 1
beq FN_CHANGE_PORTRAIT_BG_RED

FN_CHANGE_PORTRAIT_BG_BLUE:
li r4, 0
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR
FN_CHANGE_PORTRAIT_BG_GREEN:
li r4, 1
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR
FN_CHANGE_PORTRAIT_BG_RED:
li r4, 2
b FN_CHANGE_PORTRAIT_BG_SKIP_COLOR

FN_CHANGE_PORTRAIT_BG_SKIP_COLOR:

# Store team idx on r13 offset that stores port for P1-4
lbz r5, -0x49B0(r13) # player index
subi r3, r13, 26056
add r3, r3, r5 # Add player index offset
stb r4, 0(r3)

# Call game method to trigger the bg change
li r3, 0
branchl r12, 0x8025db34 # CSS_CursorHighlightUpdateCSPInfo

FN_CHANGE_PORTRAIT_BG_EXIT:
restore
blr


EXIT:
li r3, 0
addi r4, r24, 0
branchl r12, Text_CreateStruct
