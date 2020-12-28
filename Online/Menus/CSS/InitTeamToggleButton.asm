################################################################################
# Address: 0x802652f4 # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

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
# Creates and initializes Button and queues it's THINK function
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
branchl r12,JObj_LoadJoint #Create Jboj
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
branchl r12,GObj_AddToObj # void GObj_AddObject(GOBJ *gobj, u8 unk, void *object)

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
bl FN_TEAM_BUTTON_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

b HIDE_PORTRAIT_PORT


################################################################################
# Hides Port from the portrait bg
################################################################################
HIDE_PORTRAIT_PORT:


# Get Portrait Parent Jobj
lwz r3, -0x49E0(r13) # Points to SingleMenu live root Jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 0x29 # index of jboj child we want
li r6, -1
branchl r12, JObj_GetJObjChild

# Lets debug by hiding what we "find"
#lwz r3, JOBJ_CHILD_OFFSET(sp) # get return obj
#li r4, 0x10
#branchl r12, JObj_SetFlagsAll # 0x80371D9c


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
bl PROPERTIES
mflr REG_PROPERTIES

li REG_IS_HOVERING, 0 # Initialize hover state as false
loadwz r4, 0x804A0BC0 # This gets ptr to cursor position on CSS

#lfs f1, 0xC(r4) # Get x cursor pos
#lfs f2, 0x10(r4) # Get y cursor pos
# logf LOG_LEVEL_WARN, "X: %f Y: %f"

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

# Get location from which we can find selected character
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
lbz	r3, 0x00DC (r4) # char id
mr REG_EXTERNAL_CHAR_ID, r3

# Get Custom Team Index increment and store
lbz r4, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
addi r4, r4, 1
cmpwi r4, 4
blt FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM
li r4, 1 # reset to 1 (RED)

FN_SWITCH_PLAYER_TEAM_SKIP_RESET_TEAM: # 0x80197660

# Store Custom Team selection in data table
stb r4, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
mr REG_TEAM_IDX, r4

# Kind of hacky I know :) things get messed up so I just back everything up :D
backupall
mr r3, REG_TEAM_IDX
bl FN_CHANGE_PORTRAIT_BG
restoreall

mr r3, REG_TEAM_IDX
mr r4, REG_INTERNAL_CHAR_ID
bl FN_GET_TEAM_COSTUME_IDX
mr REG_COSTUME_IDX, r3
# logf LOG_LEVEL_NOTICE, "Costume Id for Team %d Char %d is %d", "mr r5, 26", "mr r6, 27", "mr r7, 3"

# Store costume index selection in game
lwz	r5, -0x49F0 (r13) # P1 Players Selections
stb	r3, 0x73 (r5)
load r5, 0x803F0E09 # P1 Char Menu Data
stb r3, 0x0(r5)
stb r3, CSSDT_TEAM_COSTUME_IDX(REG_CSSDT_ADDR)

# Calculate Costume ID from costume Index
mulli	r4, REG_COSTUME_IDX, 30
add	r4, REG_EXTERNAL_CHAR_ID, r4

li r3, 0 # player index
li	r5, 0
branchl r12, 0x8025D5AC # CSS_UpdateCharCostume?


# Play team switch sound
li	r3, 2
branchl r12, SFX_Menu_CommonSound


FN_SWITCH_PLAYER_TEAM_EXIT:
restore
blr

################################################################################
# Function: Returns Proper Costume Index for a give custom team index and char
################################################################################
# Inputs:
# r3: Team IDX
# r4: Internal Char ID (fighter ext id)
################################################################################
# Returns
# r3: Costume Index
################################################################################
FN_GET_TEAM_COSTUME_IDX:
backup
mr REG_TEAM_IDX, r3
mr REG_EXTERNAL_CHAR_ID, r4

mr r3, REG_EXTERNAL_CHAR_ID
cmpwi REG_TEAM_IDX, 3
beq FN_GET_TEAM_COSTUME_IDX_GREEN
cmpwi REG_TEAM_IDX, 2
beq FN_GET_TEAM_COSTUME_IDX_BLUE
cmpwi REG_TEAM_IDX, 1
beq FN_GET_TEAM_COSTUME_IDX_RED

FN_GET_TEAM_COSTUME_IDX_BLUE:
branchl r12, 0x801692bc # CSS_GetCharBlueCostumeIndex
b FN_GET_TEAM_COSTUME_IDX_EXIT
FN_GET_TEAM_COSTUME_IDX_GREEN:
branchl r12, 0x80169290 # CSS_GetCharGreenCostumeIndex
b FN_GET_TEAM_COSTUME_IDX_EXIT
FN_GET_TEAM_COSTUME_IDX_RED:
branchl r12, 0x80169264 # CSS_GetCharRedCostumeIndex

FN_GET_TEAM_COSTUME_IDX_EXIT:
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
# logf LOG_LEVEL_NOTICE, "FN_CHANGE_PORTRAIT_BG r3: %d", "mr r5, 31"

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

# logf LOG_LEVEL_NOTICE, "FN_CHANGE_PORTRAIT_BG after r3: %d", "mr r5, 31"

# Store team idx on r13 offset that stores port for P1-4
lbz r5, -0x49B0(r13) # player index
subi r3, r13, 26056 # 0x801977c4
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
