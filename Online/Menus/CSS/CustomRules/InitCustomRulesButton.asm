################################################################################
# Address: 0x802652dc # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PROPERTIES, 31
.set REG_IS_HOVERING, 28
.set REG_RULES_BTN_GOBJ, 14
.set REG_RULES_BTN_JOBJ, 15

.set ENTITY_DATA_OFFSET, 0x2C # offset from GOBJ to entity data


# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_DIRECT
blt EXIT # exit if not on DIRECT or TEAMS mode

b LOAD_START

################################################################################
# Properties
################################################################################
PROPERTIES:
blrl
# Top Bar Bounds
.set TPO_BOUNDS_BAR_BOTTOM, 0
.float 22.0
.set TPO_BOUNDS_BAR_RIGHT, TPO_BOUNDS_BAR_BOTTOM + 4
.float 15.0
.set TPO_BOUNDS_BAR_LEFT, TPO_BOUNDS_BAR_RIGHT + 4
.float -20
.align 2

################################################################################
# Start Init Function
################################################################################
LOAD_START:
backup

################################################################################
# Queue up per-frame Rules selector handler function
################################################################################
# Create GObj (input values stolen from CSS_BigFunc... GObj)
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr REG_RULES_BTN_GOBJ, r3 # save GOBJ pointer

################################################################################
# create jbobj (Rules Container)
################################################################################
# We are going to create the whole VS Menu and remove all unnecesary objects

lwz r3, -0x49C8(r13) # pointer to MenuModel JObj Descriptor
lwz	r3, 0x0030 (r3)
branchl r12,JObj_LoadJoint #Create Jboj
mr REG_RULES_BTN_JOBJ,r3

# Remove all Jobjs by clearing out the second jobj child
lwz r3, 0x10(r3) # get first child
lwz r3, 0x8(r3)  # get next sibling
branchl r12, 0x80371590 # JObjRemoveAll(jobj)

# Fix JObj so we only get
# Button jobj:
# - dobj - will be replaced with next dobj
# - dobj <- This is the one we want
# - dobj - will be cleared out
lwz r3, 0x10(REG_RULES_BTN_JOBJ) # get first child
branchl r12, 0x80371BEC # HSD_JObjGetDObj(HSD_JObj* jobj)
lwz r5, 0x04(r3) # get dobj we want!
li r4, 0
stw r4, 0x04(r5) # clear out it's next dobj
lwz r3, 0x10(REG_RULES_BTN_JOBJ) # get first child
stw r5, 0x18(r3) # replace dobj with the one we want

# Add JOBJ To GObj
mr  r3,REG_RULES_BTN_GOBJ
li r4, 4
mr  r5,REG_RULES_BTN_JOBJ
branchl r12,GObj_AddToObj

# Add GX Link that draws the btn
mr  r3,REG_RULES_BTN_GOBJ
load r4,0x80391070
li  r5, 2
li  r6, 128
branchl r12,GObj_SetupGXLink

# Set Think Function that runs every frame
mr r3, REG_RULES_BTN_GOBJ # set r3 to GOBJ pointer
bl FN_RULES_SELECTOR_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

restore
b EXIT


################################################################################
# Function for updating online status graphics every frame
################################################################################
FN_RULES_SELECTOR_THINK:
blrl
backup

# Check if character has been selected, if not exit
lbz r3, -0x49A9(r13)
cmpwi r3, 0
beq FN_RULES_SELECTOR_THINK_EXIT

mr REG_RULES_BTN_GOBJ, r3
lwz REG_RULES_BTN_JOBJ, ENTITY_DATA_OFFSET(REG_RULES_BTN_GOBJ)


# Get text properties address
bl PROPERTIES
mflr REG_PROPERTIES

################################################################################
# Initialize # 0x80196f14
################################################################################

# Initialize hover state as false
li REG_IS_HOVERING, 0

################################################################################
# Handle Pressing Top "Rules" Bar
################################################################################
# Ensure we are not in name entry screen
lbz r3, -0x49AA(r13)
cmpwi r3, 0
bne FN_RULES_SELECTOR_THINK_EXIT

# Ensure we are not locked in
loadwz r3, CSSDT_BUF_ADDR # Load where buf is stored
lwz r3, CSSDT_MSRB_ADDR(r3)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne FN_RULES_SELECTOR_THINK_EXIT # No changes when locked-in

# Check if cursor is anywhere on the top bar (and left of BACK button)
loadwz r4, 0x804A0BC0 # This gets ptr to cursor position on CSS

# Check if cursor is outside top boundary
lfs f1, 0x10(r4) # Get y cursor pos
lfs f2, TPO_BOUNDS_BAR_BOTTOM(REG_PROPERTIES)
fcmpo cr0, f1, f2
blt FN_RULES_SELECTOR_THINK_EXIT

# Check if cursor is outside right boundary
lfs f1, 0xC(r4) # Get x cursor pos
lfs f2, TPO_BOUNDS_BAR_RIGHT(REG_PROPERTIES)
lfs f3, TPO_BOUNDS_BAR_LEFT(REG_PROPERTIES)
fcmpo cr0, f1, f2
bgt FN_RULES_SELECTOR_THINK_EXIT

fcmpo cr0, f1, f3
blt FN_RULES_SELECTOR_THINK_EXIT

# If we get here, the cursor is within the bounds of the unselected button
li REG_IS_HOVERING, 1

# Check if a button was pressed this frame
load r4, 0x804c20bc
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 68
add r3, r4, r3
lwz r3, 0x8(r3) # get inputs
rlwinm. r3, r3, 0, 23, 23 # check if a was pressed
beq FN_RULES_SELECTOR_THINK_EXIT

bl FN_LOAD_RULES_MENU


FN_RULES_SELECTOR_THINK_EXIT:
restore
blr


################################################################################
# Function: Starts a CSS action: Load Rules Menu
# Input: r3, 0=Do nothing, 1/4= Open Name Entry, 3=Open Rules Menu
################################################################################
.set REG_SUBMENU, 21
FN_LOAD_RULES_MENU:
backup

li REG_SUBMENU, 3

# Set the player index controlling process
lbz r0, -0x49b0(r13)
stb r0, -0x49a7(r13)

# Start process to load process
mr r0, REG_SUBMENU
stb r0, -0x49aa(r13)

restore
blr


EXIT:
lwz	r3, 0x0108 (sp)