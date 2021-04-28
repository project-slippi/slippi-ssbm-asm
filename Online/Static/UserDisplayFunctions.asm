################################################################################
# Address: FG_UserDisplay
################################################################################
# Description:
# A collection of functions used for managing user display
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Local data buffer offsets
.set LDB_OSB_ADDR, 0 # u32
.set LDB_PREV_STATE, LDB_OSB_ADDR + 4 # u8
.set LDB_TEXT_STRUCT_ADDR, LDB_PREV_STATE + 1 # u32
.set LDB_DISPLAY_MODE, LDB_TEXT_STRUCT_ADDR + 4 # u8
.set LDB_X_POS, LDB_DISPLAY_MODE + 1 # float
.set LDB_Y_POS, LDB_X_POS + 4 # float
.set LDB_SIZE, LDB_Y_POS + 4

################################################################################
# The accessible contents from the outside
################################################################################
CONTENTS:
blrl
b FN_InitUserDisplay # Execute init function, 0x0
b FN_UserTextUpdate # Execute text update function, 0x4
b FN_HandleMenuChange # Execute check for menu change, 0x8
b FN_FetchSlippiAppState # Execute EXI fetch, 0xC
b FN_GetFirstUnlocked # Execute get first unlocked option, 0x10
b FN_InitBuffers # Execute init buffers, 0x14

DATA_BLRL:
blrl
.set DATA_LDB_ADDR, 0
.long 0

# Text Properties
.set DATA_TEXT_LABEL_HEIGHT, DATA_LDB_ADDR + 4
.float 20
.set DATA_TEXT_VALUE_HEIGHT, DATA_TEXT_LABEL_HEIGHT + 4
.float 25

.set DATA_TEXT_COLOR_GRAY, DATA_TEXT_VALUE_HEIGHT + 4
.long 0x8E9196FF
.set DATA_TEXT_COLOR_WHITE, DATA_TEXT_COLOR_GRAY + 4
.long 0xFFFFFFFF

.set DATA_TEXT_LABEL_SIZE, DATA_TEXT_COLOR_WHITE + 4
.float 0.4
.set DATA_TEXT_VALUE_SIZE, DATA_TEXT_LABEL_SIZE + 4
.float 0.5

.set DATA_TEXT_STRING_EMPTY, DATA_TEXT_VALUE_SIZE + 4
.string ""
.set DATA_TEXT_STRING_USER, DATA_TEXT_STRING_EMPTY + 1
.string "User"
.set DATA_TEXT_STRING_CONNECT_CODE, DATA_TEXT_STRING_USER + 5
.string "Connect Code"
.align 2

# Registers
.set REG_DATA_ADDR, 31
.set REG_LDB_ADDR, 30
.set REG_OSB_ADDR, 29
.set REG_TEXT_STRUCT, 28
.set REG_DISPLAY_MODE, 27
.set REG_DISPLAY_PROPERTIES, 25

################################################################################
# Address: FN_InitUserDisplay
################################################################################
# Inputs:
# r3 - Pointer to display properties
# r4 - Display mode. 1 = No connect code, 2 = with connect code
# r5 - Should init buffers. 0 = don't init, 1 = init
################################################################################
# Outputs:
# r3 - OSB Address
################################################################################
# Description:
# Initializes user display text. Should be called when loading a scene
################################################################################
FN_InitUserDisplay:
backup

mr REG_DISPLAY_PROPERTIES, r3
mr REG_DISPLAY_MODE, r4

cmpwi r5, 0
beq FN_InitUserDisplay_SKIP_INIT_BUFFERS
bl FN_InitBuffers
FN_InitUserDisplay_SKIP_INIT_BUFFERS:

# Get Data Addr
bl DATA_BLRL
mflr REG_DATA_ADDR
lwz REG_LDB_ADDR, DATA_LDB_ADDR(REG_DATA_ADDR)
lwz REG_OSB_ADDR, LDB_OSB_ADDR(REG_LDB_ADDR)

################################################################################
# Write X/Y Offsets
################################################################################
lfs f1, 0x0(REG_DISPLAY_PROPERTIES)
stfs f1, LDB_X_POS(REG_LDB_ADDR)
lfs f2, 0x4(REG_DISPLAY_PROPERTIES)
stfs f2, LDB_Y_POS(REG_LDB_ADDR)
stb REG_DISPLAY_MODE, LDB_DISPLAY_MODE(REG_LDB_ADDR)

################################################################################
# Init text structure
################################################################################
# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3
stw REG_TEXT_STRUCT, LDB_TEXT_STRUCT_ADDR(REG_LDB_ADDR)

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align left
li r4, 0x0
stb r4, 0x4A(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, 0x8(REG_DISPLAY_PROPERTIES) # Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, 0xC(REG_DISPLAY_PROPERTIES) # Scaling
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

################################################################################
# Init text lines
################################################################################
# Init label 1 (User)
li r3, 1
bl FN_InitLine

lfs f1, DATA_TEXT_LABEL_HEIGHT(REG_DATA_ADDR)
bl FN_IncrementYPos

# Init user value
li r3, 0
bl FN_InitLine

lfs f1, DATA_TEXT_VALUE_HEIGHT(REG_DATA_ADDR)
bl FN_IncrementYPos

# Init label 2 (connect code)
li r3, 1
bl FN_InitLine

lfs f1, DATA_TEXT_LABEL_HEIGHT(REG_DATA_ADDR)
bl FN_IncrementYPos

# Init connect code value
li r3, 0
bl FN_InitLine

################################################################################
# Trigger think function once to set the text values
################################################################################
bl FN_UserTextUpdate

################################################################################
# Initialize prev state
################################################################################
lbz r3, OFST_R13_APP_STATE(r13) # Load current state
stb r3, LDB_PREV_STATE(REG_LDB_ADDR)

# Return OSB address as output
mr r3, REG_OSB_ADDR

restore
blr

################################################################################
# InitLine
################################################################################
# Inputs:
# r3 - bool, isLabel
################################################################################
# Description:
# Initializes a single subtext line
################################################################################
.set REG_DATA_ADDR, 31 # From parent
.set REG_LDB_ADDR, 30 # From parent
.set REG_TEXT_STRUCT, 28 # From parent
.set REG_IS_LABEL, 26
.set REG_DISPLAY_PROPERTIES, 25 # From parent
.set REG_SUBTEXT_IDX, 24

FN_InitLine:
backup

mr REG_IS_LABEL, r3

# Init line text
lfs f1, LDB_X_POS(REG_LDB_ADDR)
lfs f2, LDB_Y_POS(REG_LDB_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DATA_TEXT_STRING_EMPTY
branchl r12, Text_InitializeSubtext
mr REG_SUBTEXT_IDX, r3

# Set text size
lfs f1, DATA_TEXT_VALUE_SIZE(REG_DATA_ADDR)
cmpwi REG_IS_LABEL, 0
beq FN_InitLine_SKIP_SIZE_LABEL
lfs f1, DATA_TEXT_LABEL_SIZE(REG_DATA_ADDR)
FN_InitLine_SKIP_SIZE_LABEL:
fmr f2, f1

mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
branchl r12, Text_UpdateSubtextSize

# Set text color
addi r5, REG_DATA_ADDR, DATA_TEXT_COLOR_WHITE
cmpwi REG_IS_LABEL, 0
beq FN_InitLine_SKIP_COLOR_LABEL
addi r5, REG_DATA_ADDR, DATA_TEXT_COLOR_GRAY
FN_InitLine_SKIP_COLOR_LABEL:

mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
branchl r12, Text_ChangeTextColor

restore
blr

################################################################################
# IncrementYPos
################################################################################
# Inputs:
# f1 - Increment amount
################################################################################
# Description:
# Increments text Y pos
################################################################################
.set REG_LDB_ADDR, 30 # From parent
FN_IncrementYPos:
lfs f2, LDB_Y_POS(REG_LDB_ADDR)
fadds f2, f2, f1
stfs f2, LDB_Y_POS(REG_LDB_ADDR)
blr

################################################################################
# UserTextThink
################################################################################
# Description:
# Per-frame function for updating text contents
################################################################################
.set REG_DATA_ADDR, 31
.set REG_LDB_ADDR, 30
.set REG_OSB_ADDR, 29
.set REG_TEXT_STRUCT, 28
.set REG_INDEX, 27

.set SUBTEXT_COUNT, 4

FN_UserTextUpdate:
backup

# Get Data Addr
bl DATA_BLRL
mflr REG_DATA_ADDR

# Load buffers
lwz REG_LDB_ADDR, DATA_LDB_ADDR(REG_DATA_ADDR)
lwz REG_OSB_ADDR, LDB_OSB_ADDR(REG_LDB_ADDR)
lwz REG_TEXT_STRUCT, LDB_TEXT_STRUCT_ADDR(REG_LDB_ADDR)

################################################################################
# Get online status from Slippi
################################################################################
bl FN_FetchSlippiAppState

################################################################################
# Clear text of all subtext entries
################################################################################
li REG_INDEX, 0
FN_UserTextUpdate_CLEAR_LOOP_START:
mr r3, REG_TEXT_STRUCT
mr r4, REG_INDEX
addi r5, REG_DATA_ADDR, DATA_TEXT_STRING_EMPTY
branchl r12, Text_UpdateSubtextContents
addi REG_INDEX, REG_INDEX, 1
cmpwi REG_INDEX, SUBTEXT_COUNT
blt FN_UserTextUpdate_CLEAR_LOOP_START

################################################################################
# Leave entries cleared if player is not logged in
################################################################################
lbz r3, OSB_APP_STATE(REG_OSB_ADDR)
cmpwi r3, 1
bne FN_UserTextUpdate_RESTORE_AND_EXIT

################################################################################
# Leave entries cleared if not on online menu
################################################################################
# TODO: This could maybe be a callback function instead
loadbz r3, 0x80479d30 # Load major scene
cmpwi r3, 0x1
bne FN_UserTextUpdate_SKIP_SUBMENU_CHECK

loadbz r3, 0x804a04f0 # Get current submenu
cmpwi r3, 0x8 # If not on online submenu, hide text
bne FN_UserTextUpdate_RESTORE_AND_EXIT

FN_UserTextUpdate_SKIP_SUBMENU_CHECK:

################################################################################
# Set User label and player name
################################################################################
mr r3, REG_TEXT_STRUCT
li r4, 0
addi r5, REG_DATA_ADDR, DATA_TEXT_STRING_USER
branchl r12, Text_UpdateSubtextContents

mr r3, REG_TEXT_STRUCT
li r4, 1
addi r5, REG_OSB_ADDR, OSB_PLAYER_NAME
branchl r12, Text_UpdateSubtextContents

################################################################################
# Set Connect code label and text if display mode = 2
################################################################################
lbz r3, LDB_DISPLAY_MODE(REG_LDB_ADDR)
cmpwi r3, 2
bne FN_UserTextUpdate_SKIP_CONNECT_CODE

mr r3, REG_TEXT_STRUCT
li r4, 2
addi r5, REG_DATA_ADDR, DATA_TEXT_STRING_CONNECT_CODE
branchl r12, Text_UpdateSubtextContents

mr r3, REG_TEXT_STRUCT
li r4, 3
addi r5, REG_OSB_ADDR, OSB_CONNECT_CODE
branchl r12, Text_UpdateSubtextContents

FN_UserTextUpdate_SKIP_CONNECT_CODE:

FN_UserTextUpdate_RESTORE_AND_EXIT:
restore
blr

################################################################################
# HandleMenuChange
################################################################################
# Description:
# This will listen to the app state and refresh the menu if necessary
################################################################################
.set REG_DATA_ADDR, 31
.set REG_LDB_ADDR, 30

FN_HandleMenuChange:
backup

bl DATA_BLRL
mflr REG_DATA_ADDR

lwz REG_LDB_ADDR, DATA_LDB_ADDR(REG_DATA_ADDR)

lbz r4, LDB_PREV_STATE(REG_LDB_ADDR) # Load previous state
lbz r3, OFST_R13_APP_STATE(r13) # Load current state
cmpw r4, r3 # Compare states
stb r3, LDB_PREV_STATE(REG_LDB_ADDR) # Store current state to previous
beq FN_HandleMenuChange_SKIP_ADJUSTMENT # If states were equal, do nothing

# Play sound on state change for menu transition
li	r3, 1
branchl r12, SFX_Menu_CommonSound

# Here the state has changed and we need to update the UI
lwz r3, OFST_R13_SWITCH_TO_ONLINE_SUBMENU(r13)
mtctr r3
bctrl

FN_HandleMenuChange_SKIP_ADJUSTMENT:

restore
blr

################################################################################
# FetchSlippiAppState
################################################################################
# Description:
# Gets the app state from EXI and sets global variable
################################################################################
.set REG_DATA_ADDR, 31
.set REG_LDB_ADDR, 30
.set REG_OSB_ADDR, 29

FN_FetchSlippiAppState:
backup

# Get Data Addr
bl DATA_BLRL
mflr REG_DATA_ADDR

# Load buffers
lwz REG_LDB_ADDR, DATA_LDB_ADDR(REG_DATA_ADDR)
lwz REG_OSB_ADDR, LDB_OSB_ADDR(REG_LDB_ADDR)

################################################################################
# Request online status from Slippi
################################################################################
# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdGetOnlineStatus
stb r3, 0(REG_OSB_ADDR)

# Request online status information
mr r3, REG_OSB_ADDR # Use the receive buffer to send the command
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get match state information response
mr r3, REG_OSB_ADDR # Use the receive buffer to send the command
li r4, OSB_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# Update global state (used for hidden options)
lbz r4, OSB_APP_STATE(REG_OSB_ADDR)
stb r4, OFST_R13_APP_STATE(r13)

restore
blr

################################################################################
# GetFirstUnlocked
################################################################################
# Description:
# Gets the first unlocked option for online sub-menu
################################################################################
# Outputs:
# r3 - The first unlocked option in online sub-menu
################################################################################
FN_GetFirstUnlocked:
backup

# Determine index to select, use first non-locked index
load r5, 0x803eae68
lbz	r5, 0x08F4(r5) # Load number of options
li r4, 0
LOOP_FIND_FIRST_UNLOCKED_START:
# Function call doesn't overwrite r4, safe to just keep using it
li r3, 0x8 # Use online menu ID for function calls
branchl r12, 0x80229938 # MainMenu_CheckIfOptionIsUnlocked
cmpwi r3, 1 # Check if option is unlocked
beq LOOP_FIND_FIRST_UNLOCKED_BREAK
addi r4, r4, 1
cmpw r4, r5
blt LOOP_FIND_FIRST_UNLOCKED_START
LOOP_FIND_FIRST_UNLOCKED_BREAK:

mr r3, r4

restore
blr

################################################################################
# InitBuffers
################################################################################
# Description:
# Initialize the LDB and OSB
################################################################################
.set REG_DATA_ADDR, 31
.set REG_LDB_ADDR, 30

FN_InitBuffers:
backup

# Get Data Addr
bl DATA_BLRL
mflr REG_DATA_ADDR

# Init local buffer
li r3, LDB_SIZE
branchl r12, HSD_MemAlloc
mr REG_LDB_ADDR, r3
stw r3, DATA_LDB_ADDR(REG_DATA_ADDR)

# Init EXI buffer
li r3, OSB_SIZE
branchl r12, HSD_MemAlloc
stw r3, LDB_OSB_ADDR(REG_LDB_ADDR)

restore
blr
