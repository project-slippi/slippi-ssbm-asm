################################################################################
# Address: 0x802652f0 # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEXT_PROPERTIES, 31
.set REG_TEXT_STRUCT, 30
.set REG_PORT_SELECTIONS_ADDR, 29
.set REG_IS_HOVERING, 28
.set REG_VARIOUS_1, 26
.set REG_VARIOUS_2, 25
.set REG_VARIOUS_3, 24
.set REG_LR, 23

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal
b LOAD_START

################################################################################
# Properties
################################################################################
TEXT_PROPERTIES:
blrl
.set TPO_TEXT_STRUCT_PTR, 0
.long 0x0 # This is where the ptr for the text struct will be stored

# Base Properties
.set TPO_BASE_Z, TPO_TEXT_STRUCT_PTR + 4
.float 0
.set TPO_BASE_CANVAS_SCALING, TPO_BASE_Z + 4
.float 0.1

# Button properties
.set TPO_BUTTON_X, TPO_BASE_CANVAS_SCALING + 4
.float -100
.set TPO_BUTTON_SHEIK_Y, TPO_BUTTON_X + 4
.float 180
.set TPO_BUTTON_ZELDA_Y, TPO_BUTTON_SHEIK_Y + 4
.float 210
.set TPO_OUTLINE_SIZE, TPO_BUTTON_ZELDA_Y + 4
.float 0.6
.set TPO_LETTER_SIZE, TPO_OUTLINE_SIZE + 4
.float 0.4
.set TPO_LETTER_Y_OFFSET, TPO_LETTER_SIZE + 4
.float -3

# Colors
.set TPO_COLOR_GREEN, TPO_LETTER_Y_OFFSET + 4
.long 0x33FF2FFF
.set TPO_COLOR_WHITE, TPO_COLOR_GREEN + 4
.long 0xFFFFFFFF
.set TPO_COLOR_GRAY, TPO_COLOR_WHITE + 4
.long 0x8E9196FF

# Button Bounds
.set TPO_BOUNDS_BUTTON_S_TOP, TPO_COLOR_GRAY + 4
.float -18.45
.set TPO_BOUNDS_BUTTON_Z_TOP, TPO_BOUNDS_BUTTON_S_TOP + 4
.float -21.36
.set TPO_BOUNDS_BUTTON_HEIGHT, TPO_BOUNDS_BUTTON_Z_TOP + 4
.float 1.78
.set TPO_BOUNDS_BUTTON_LEFT, TPO_BOUNDS_BUTTON_HEIGHT + 4
.float -16.28
.set TPO_BOUNDS_BUTTON_RIGHT, TPO_BOUNDS_BUTTON_LEFT + 4
.float -13.73

# String Properties
.set TPO_STRING_BUTTON_OUTLINE, TPO_BOUNDS_BUTTON_RIGHT + 4
.short 0x8169 # (
.byte 0x20 # space
.short 0x816A # )
.byte 0x00
.set TPO_STRING_SHEIK, TPO_STRING_BUTTON_OUTLINE + 6
.string "S"
.set TPO_STRING_ZELDA, TPO_STRING_SHEIK + 2
.string "Z"
.align 2

################################################################################
# Start Init Function
################################################################################
LOAD_START:
backup

################################################################################
# Queue up per-frame Sheik/Zelda selector handler function
################################################################################
# Create GObj (input values stolen from CSS_BigFunc... GObj)
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create

# Schedule Function
bl FN_SZThink
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

################################################################################
# Set up CSS text
################################################################################
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3
stw REG_TEXT_STRUCT, TPO_TEXT_STRUCT_PTR(REG_TEXT_PROPERTIES)

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align center
stb r4, 0x4A(REG_TEXT_STRUCT)
# display over player panel?
stb r4, 0x4C(REG_TEXT_STRUCT)
stb r4, 0x48(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, TPO_BASE_Z(REG_TEXT_PROPERTIES) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Initialize lines
li r3, TPO_STRING_SHEIK
lfs f1, TPO_BUTTON_SHEIK_Y(REG_TEXT_PROPERTIES)
bl INIT_BUTTON

li r3, TPO_STRING_ZELDA
lfs f1, TPO_BUTTON_ZELDA_Y(REG_TEXT_PROPERTIES)
bl INIT_BUTTON

restore
b EXIT

################################################################################
# Function for initializing line subtext.
# Expects f1 to be set to y position of line. Expect r3 to be offset to letter
################################################################################
INIT_BUTTON:
.set REG_LETTER_STRING_OFFSET, REG_VARIOUS_1

mflr REG_LR # Single depth helper function. Non-standard

mr REG_LETTER_STRING_OFFSET, r3
fmr f3, f1 # Y Pos

# Init button outline
lfs f1, TPO_BUTTON_X(REG_TEXT_PROPERTIES)
fmr f2, f3
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_STRING_BUTTON_OUTLINE # change to empty string
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_OUTLINE_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_OUTLINE_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Init button letter
lfs f1, TPO_LETTER_Y_OFFSET(REG_TEXT_PROPERTIES)
fadds f2, f3, f1
lfs f1, TPO_BUTTON_X(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
add r4, REG_TEXT_PROPERTIES, REG_LETTER_STRING_OFFSET # change to empty string
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_LETTER_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_LETTER_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

mtlr REG_LR
blr

################################################################################
# Function for updating online status graphics every frame
################################################################################
FN_SZThink:
blrl

.set SUBTEXT_ITEM_COUNT_PER_BUTTON, 2

backup

# Get text properties address
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

lwz REG_TEXT_STRUCT, TPO_TEXT_STRUCT_PTR(REG_TEXT_PROPERTIES)

################################################################################
# Hide the text if zelda is not selected and do nothing
################################################################################
loadbz r3, 0x8043208f # This value resets when char is unselected
cmpwi r3, 0x12 # Check if Zelda selected
beq FN_SZThink_SHEIK_OR_ZELDA_SELECTED
cmpwi r3, 0x13 # Check if Sheik selected
beq FN_SZThink_SHEIK_OR_ZELDA_SELECTED

# Hide the structure
li r3, 0x1
stb r3, 0x4D(REG_TEXT_STRUCT)

b FN_SZThink_EXIT

FN_SZThink_SHEIK_OR_ZELDA_SELECTED:
################################################################################
# Initialize
################################################################################
# Show the structure
li r3, 0x0
stb r3, 0x4D(REG_TEXT_STRUCT)

# Get location from which we can find selected character
lwz r4, -0x49F0(r13) # base address where css selections are stored
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 0x24
add REG_PORT_SELECTIONS_ADDR, r4, r3

# Initialize hover state as false
li REG_IS_HOVERING, 0

################################################################################
# Handle changing selection
################################################################################
# Ensure we are not in name entry screen
lbz r3, -0x49AA(r13)
cmpwi r3, 0
bne FN_SZThink_CHANGE_HANDLING_END

# Ensure we are not locked in
loadwz r3, CSSDT_BUF_ADDR # Load where buf is stored
lwz r3, CSSDT_MSRB_ADDR(r3)
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(r3)
cmpwi r3, 0
bne FN_SZThink_CHANGE_HANDLING_END # No changes when locked-in

# Check if the Z button was pressed this frame
load r4, 0x804c20bc
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 68
add r3, r4, r3
lwz r3, 0x8(r3) # get inputs
rlwinm. r3, r3, 0, 27, 27 # check if z was pressed
bne FN_SZThink_TOGGLE_CHARACTER

# Determine if cursor is in bounds of unselected button
loadwz r4, 0x804A0BC0 # This gets ptr to cursor position on CSS
lfs f1, 0x10(r4) # Get y cursor pos

# Get cursor y top boundary
lfs f2, TPO_BOUNDS_BUTTON_Z_TOP(REG_TEXT_PROPERTIES)
lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
cmpwi r3, 0x13 # Check if Sheik is selected
beq FN_SZThink_TOP_BOUND_SET
lfs f2, TPO_BOUNDS_BUTTON_S_TOP(REG_TEXT_PROPERTIES)
FN_SZThink_TOP_BOUND_SET:

# Check if cursor is outside top boundary
fcmpo cr0, f1, f2
bgt FN_SZThink_CHANGE_HANDLING_END

# Check if cursor is outside bottom boundary
lfs f3, TPO_BOUNDS_BUTTON_HEIGHT(REG_TEXT_PROPERTIES)
fsubs f2, f2, f3
fcmpo cr0, f1, f2
blt FN_SZThink_CHANGE_HANDLING_END

# Now we do left and right bounds
lfs f1, 0xC(r4) # Get x cursor pos

# Check if cursor is left of left bounds
lfs f2, TPO_BOUNDS_BUTTON_LEFT(REG_TEXT_PROPERTIES)
fcmpo cr0, f1, f2
blt FN_SZThink_CHANGE_HANDLING_END

# Check right boundary
lfs f2, TPO_BOUNDS_BUTTON_RIGHT(REG_TEXT_PROPERTIES)
fcmpo cr0, f1, f2
bgt FN_SZThink_CHANGE_HANDLING_END

# If we get here, the cursor is within the bounds of the unselected button
li REG_IS_HOVERING, 1

# Check if a button was pressed this frame
load r4, 0x804c20bc
lbz r3, -0x49B0(r13) # player index
mulli r3, r3, 68
add r3, r4, r3
lwz r3, 0x8(r3) # get inputs
rlwinm. r3, r3, 0, 23, 23 # check if a was pressed
beq FN_SZThink_CHANGE_HANDLING_END

FN_SZThink_TOGGLE_CHARACTER:
# Toggle the selected character
lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
cmpwi r3, 0x13 # Check if Sheik is selected
beq FN_SZThink_SWITCH_TO_ZELDA

# Switch to sheik
li r3, 0x13
stb r3, 0x70(REG_PORT_SELECTIONS_ADDR)

b FN_SZThink_SWITCH_COMPLETE

FN_SZThink_SWITCH_TO_ZELDA:
# Switch to zelda
li r3, 0x12
stb r3, 0x70(REG_PORT_SELECTIONS_ADDR)

FN_SZThink_SWITCH_COMPLETE:
# Required to play correct sound and show correct nameplate
load r4, 0x803f0cc8
stb r3, 0x1(r4)

# Play sound r3 is ext ID
branchl r12, 0x80168c5c # SFX_getCharacterNameAnnouncer

li r3, 0
branchl r12, 0x8025db34 # CSS_CursorHighlightUpdateCSPInfo

FN_SZThink_CHANGE_HANDLING_END:

################################################################################
# Prepare to set styles
################################################################################
.set REG_SUBTEXT_IDX_SELECTED, REG_VARIOUS_1
.set REG_SUBTEXT_IDX_UNSELECTED, REG_VARIOUS_2
.set REG_UNSELECTED_COLOR, REG_VARIOUS_3

li REG_SUBTEXT_IDX_SELECTED, 0
addi REG_SUBTEXT_IDX_UNSELECTED, REG_SUBTEXT_IDX_SELECTED, SUBTEXT_ITEM_COUNT_PER_BUTTON
lbz r3, 0x70(REG_PORT_SELECTIONS_ADDR)
cmpwi r3, 0x13 # Check if Sheik is selected
beq FN_SZThink_SUBTEXT_IDX_INITIALIZED

# Set subtext idx to Zelda button
li REG_SUBTEXT_IDX_UNSELECTED, 0
addi REG_SUBTEXT_IDX_SELECTED, REG_SUBTEXT_IDX_UNSELECTED, SUBTEXT_ITEM_COUNT_PER_BUTTON

FN_SZThink_SUBTEXT_IDX_INITIALIZED:

################################################################################
# Set selected styles
################################################################################
mr r3, REG_TEXT_STRUCT
addi r4, REG_SUBTEXT_IDX_SELECTED, 0
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_GREEN
branchl r12, Text_ChangeTextColor

mr r3, REG_TEXT_STRUCT
addi r4, REG_SUBTEXT_IDX_SELECTED, 1
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE
branchl r12, Text_ChangeTextColor

################################################################################
# Set unselected styles
################################################################################
addi REG_UNSELECTED_COLOR, REG_TEXT_PROPERTIES, TPO_COLOR_GRAY
cmpwi REG_IS_HOVERING, 0
beq FN_SZThink_UNSELECTED_COLOR_SET
addi REG_UNSELECTED_COLOR, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE
FN_SZThink_UNSELECTED_COLOR_SET:

mr r3, REG_TEXT_STRUCT
addi r4, REG_SUBTEXT_IDX_UNSELECTED, 0
mr r5, REG_UNSELECTED_COLOR
branchl r12, Text_ChangeTextColor

mr r3, REG_TEXT_STRUCT
addi r4, REG_SUBTEXT_IDX_UNSELECTED, 1
mr r5, REG_UNSELECTED_COLOR
branchl r12, Text_ChangeTextColor

FN_SZThink_EXIT:
restore
blr

EXIT:
li r3, 0
addi r4, r24, 0
