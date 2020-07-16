################################################################################
# Address: 0x80186ec4 # SceneLoad_ClassicModeSplash
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEXT_PROPERTIES, 31
.set REG_TEXT_STRUCT, 30
.set REG_MSRB_ADDR, 29

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_VS
bne EXIT # If not online CSS, continue as normal
b LOAD_START

################################################################################
# Properties
################################################################################
TEXT_PROPERTIES:
blrl
# Base Properties
.set TPO_BASE_Z, 0
.float 0
.set TPO_BASE_CANVAS_SCALING, TPO_BASE_Z + 4
.float 1

# Size properties
.set TPO_PORT_LABEL_SIZE, TPO_BASE_CANVAS_SCALING + 4
.float 0.5
.set TPO_PLAYER_NAME_SIZE, TPO_PORT_LABEL_SIZE + 4
.float 0.6

# Color properties
.set TPO_P1_LABEL_COLOR, TPO_PLAYER_NAME_SIZE + 4
.long 0xF15959FF
.set TPO_P2_LABEL_COLOR, TPO_P1_LABEL_COLOR + 4
.long 0x6565FEFF

# X Positions
.set TPO_P1_X_POS, TPO_P2_LABEL_COLOR + 4
.float 60
.set TPO_P2_X_POS, TPO_P1_X_POS + 4
.float 400
.set TPO_STAGE_X_POS, TPO_P2_X_POS + 4
.float 238

# Y Positions
.set TPO_PLAYER_Y_START, TPO_STAGE_X_POS + 4
.float 60
.set TPO_STAGE_Y_POS, TPO_PLAYER_Y_START + 4
.float 440

# Stage
.set TPO_STAGE_UNK0, TPO_STAGE_Y_POS + 4
.float 30 # Changing does nothing?
.set TPO_STAGE_UNK1, TPO_STAGE_UNK0 + 4
.float 160 # Increasing this moves the position of the text to the right?
.set TPO_STAGE_UNK2, TPO_STAGE_UNK1 + 4
.float 300 # Changing does nothing?

# Position Offsets
.set TPO_PLAYER_NAME_Y_OFST, TPO_STAGE_UNK2 + 4
.float 22

# String Properties
.set TPO_P1_STRING, TPO_PLAYER_NAME_Y_OFST + 4
.string "P1"
.set TPO_P2_STRING, TPO_P1_STRING + 3
.string "P2"
.align 2

################################################################################
# Start Init Function
################################################################################
LOAD_START:
backup

################################################################################
# Load Stage Strings
################################################################################
li r3, 0
load r4, 0x803f11a4
load r5, 0x803f1194
branchl r12, 0x803a62a0 # fileLoad_SdMsgBox.usd (Loading file with stage names)

################################################################################
# Fetch player names
################################################################################
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

################################################################################
# Pepare text struct for player names
################################################################################
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align left
li r4, 0x0
stb r4, 0x4A(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, TPO_BASE_Z(REG_TEXT_PROPERTIES) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Initialize P1 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P1_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_P1_STRING
addi r5, REG_MSRB_ADDR, MSRB_P1_NAME
lfs f1, TPO_P1_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT

# Initialize P2 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P2_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_P2_STRING
addi r5, REG_MSRB_ADDR, MSRB_P2_NAME
lfs f1, TPO_P2_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT

################################################################################
# Pepare text struct for stage
################################################################################
# Initialize Stage Text
li r3, 0
li r4, 0
lfs f1, TPO_STAGE_X_POS(REG_TEXT_PROPERTIES)
lfs f2, TPO_STAGE_Y_POS(REG_TEXT_PROPERTIES)
lfs f3, TPO_STAGE_UNK0(REG_TEXT_PROPERTIES) # Width?
lfs f4, TPO_STAGE_UNK1(REG_TEXT_PROPERTIES) # Unk, 160
lfs f5, TPO_STAGE_UNK2(REG_TEXT_PROPERTIES) # Unk, 300
branchl r12, Text_AllocateTextObject
mr REG_TEXT_STRUCT, r3

# Initialize Struct Stuff
lfs f1, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Set text to align center
li r4, 0x1
stb r4, 0x4A(REG_TEXT_STRUCT)

# Set text kerning to close
stb r4, 0x49(REG_TEXT_STRUCT)

# Set ???
#stb r4, 0x48(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, TPO_BASE_Z(REG_TEXT_PROPERTIES) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Get random stage select ID from ext ID
load r5, 0x803B7808 # Start address of SelectID -> ExtID lookup
lhz r6, MSRB_GAME_INFO_BLOCK + 0xE(REG_MSRB_ADDR) # Stage ExtID

li r3, 0 # Current RSS ID
LOOP_FIND_RANDOM_ID_START:
mulli r4, r3, 2
lhzx r4, r5, r4 # ExtID at this index
cmpw r4, r6
beq LOOP_FIND_RANDOM_ID_END
addi r3, r3, 1
cmpwi r3, 0x1d # End of the lookup
blt LOOP_FIND_RANDOM_ID_START
li r3, 0 # Default if ext ID not found?
LOOP_FIND_RANDOM_ID_END:

# Given random stage select ID, get the premade text ID
load r4, 0x803ed488
add r4, r4, r3
lbz r4, 0x5C(r4)
mr r3, REG_TEXT_STRUCT
branchl r12, Text_CopyPremadeTextDataToStruct

# Kill SFX
#branchl r12,0x80023694

restore
b EXIT

################################################################################
# Function for initializing a player's subtext
################################################################################
# Inputs:
# r3 - Label Color
# r4 - Label String
# r5 - Player Name String
# f1 - X Pos
################################################################################
.set SPO_X_POS, 0x80

.set REG_TEXT_PROPERTIES, 31  # From parent function
.set REG_TEXT_STRUCT, 30  # From parent function
.set REG_LABEL_COLOR, 29
.set REG_PLAYER_NAME_STRING, 28
.set REG_CUR_SUBTEXT_IDX, 27

INIT_PLAYER_TEXT:
backup

stfs f1, SPO_X_POS(sp)
mr REG_LABEL_COLOR, r3
mr REG_PLAYER_NAME_STRING, r5

# Init port label text
lfs f2, TPO_PLAYER_Y_START(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
branchl r12, Text_InitializeSubtext
mr REG_CUR_SUBTEXT_IDX, r3

# Set port label font size
mr r3, REG_TEXT_STRUCT
mr r4, REG_CUR_SUBTEXT_IDX
lfs f1, TPO_PORT_LABEL_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PORT_LABEL_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Set port label color
mr r3, REG_TEXT_STRUCT
mr r4, REG_CUR_SUBTEXT_IDX
mr r5, REG_LABEL_COLOR
branchl r12, Text_ChangeTextColor

# Init player name text
lfs f1, SPO_X_POS(sp)
lfs f2, TPO_PLAYER_Y_START(REG_TEXT_PROPERTIES)
lfs f3, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)
fadds f2, f2, f3
mr r3, REG_TEXT_STRUCT
mr r4, REG_PLAYER_NAME_STRING
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

restore
blr

EXIT:
li r0, -1
