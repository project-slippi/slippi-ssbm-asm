################################################################################
# Address: 0x80186ec4 # SceneLoad_ClassicModeSplash
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEXT_PROPERTIES, 31
.set REG_TEXT_STRUCT, 30
.set REG_MSRB_ADDR, 29

.set REG_LOCAL_PLAYER_IDX, 28
.set REG_LOCAL_PLAYER_TEAM, 27
.set REG_PLAYER_INDEX, 26
.set REG_LEFT_COUNT, 25
.set REG_RIGHT_COUNT, 24

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
.set TPO_LABEL_AND_NAME_SIZE, TPO_BASE_CANVAS_SCALING + 4
.float 0.5

# Color properties. These colors are from the CSS panels
.set TPO_COLOR_RED, TPO_LABEL_AND_NAME_SIZE + 4
.long 0xE54C4CFF
.set TPO_COLOR_BLUE, TPO_COLOR_RED + 4
.long 0x4B4CE5FF
.set TPO_COLOR_YELLOW, TPO_COLOR_BLUE + 4
.long 0xFFCB00FF
.set TPO_COLOR_GREEN, TPO_COLOR_YELLOW + 4
.long 0x00B200FF
.set TPO_COLOR_WHITE, TPO_COLOR_GREEN + 4
.long 0xFFFFFFFF

# X Positions
.set TPO_LEFT_X_POS, TPO_COLOR_WHITE + 4
.float 60
.set TPO_RIGHT_X_POS, TPO_LEFT_X_POS + 4
.float 380
.set TPO_STAGE_X_POS, TPO_RIGHT_X_POS + 4
.float 238

# Y Positions
.set TPO_PLAYER_Y_START, TPO_STAGE_X_POS + 4
.float 80
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
.set TPO_PLAYER_NAME_X_OFST, TPO_STAGE_UNK2 + 4
.float -22
.set TPO_PLAYER_NAME_Y_OFST, TPO_PLAYER_NAME_X_OFST + 4
.float -22
.set TPO_PORT_NAME_X_OFST, TPO_PLAYER_NAME_Y_OFST + 4
.float 36

# String Properties
.set TPO_RED_TEAM_LABEL_STRING, TPO_PORT_NAME_X_OFST + 4
.string "RT"
.set TPO_BLUE_TEAM_LABEL_STRING, TPO_RED_TEAM_LABEL_STRING + 3
.string "BT"
.set TPO_GREEN_TEAM_LABEL_STRING, TPO_BLUE_TEAM_LABEL_STRING + 3
.string "GT"
.set TPO_PORT_STRING, TPO_GREEN_TEAM_LABEL_STRING + 3
.string "P%d"
.align 2

################################################################################
# Start Init Function
################################################################################
LOAD_START:
backup BKP_DEFAULT_FREE_SPACE_SIZE, 1

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

################################################################################
# Loop through all players and determine whether to print them on the left
# or right side
################################################################################
lbz REG_LOCAL_PLAYER_IDX, MSRB_LOCAL_PLAYER_INDEX(REG_MSRB_ADDR)

# Load the team id for local player
mulli r3, REG_LOCAL_PLAYER_IDX, 0x24
addi r3, r3, MSRB_GAME_INFO_BLOCK + 0x69 # loc of this player index's team id
lbzx REG_LOCAL_PLAYER_TEAM, REG_MSRB_ADDR, r3 # load team id for player

li REG_LEFT_COUNT, 0
li REG_RIGHT_COUNT, 0
li REG_PLAYER_INDEX, 3

LOOP_PLAYER_TEXT_START:
addi r12, REG_MSRB_ADDR, MSRB_GAME_INFO_BLOCK
mulli r3, REG_PLAYER_INDEX, 0x24
add r12, r12, r3 # Set this up so we can just use 0x60 to get char id for cur player for example

lbz r3, 0x61(r12) # load player type
cmpwi r3, 3
bge LOOP_PLAYER_TEXT_CONTINUE

# If local player, go left
cmpw REG_PLAYER_INDEX, REG_LOCAL_PLAYER_IDX
beq LOOP_PLAYER_TEXT_GO_LEFT

# If not teams, go right
lbz r3, MSRB_GAME_INFO_BLOCK + 0x8(REG_MSRB_ADDR)
cmpwi r3, 0
beq LOOP_PLAYER_TEXT_GO_RIGHT

# If teams, check team id against local player team
lbz r3, 0x69(r12) # load team id for this player
cmpw r3, REG_LOCAL_PLAYER_TEAM
beq LOOP_PLAYER_TEXT_GO_LEFT
b  LOOP_PLAYER_TEXT_GO_RIGHT

LOOP_PLAYER_TEXT_GO_LEFT:
mr r3, REG_LEFT_COUNT
lfs f31, TPO_LEFT_X_POS(REG_TEXT_PROPERTIES)
addi REG_LEFT_COUNT, REG_LEFT_COUNT, 1
b LOOP_PLAYER_TEXT_PREP_DISPLAY

LOOP_PLAYER_TEXT_GO_RIGHT:
mr r3, REG_RIGHT_COUNT
lfs f31, TPO_RIGHT_X_POS(REG_TEXT_PROPERTIES)
addi REG_RIGHT_COUNT, REG_RIGHT_COUNT, 1

LOOP_PLAYER_TEXT_PREP_DISPLAY:
branchl r12, FN_IntToFloat
fmr f3, f1 # Store left count

# Calculate x pos
lfs f4, TPO_PLAYER_NAME_X_OFST(REG_TEXT_PROPERTIES)
fmuls f4, f3, f4 # left count * x offset
fadds f1, f31, f4 # Base x pos + offset

# Calculate y pos
lfs f4, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)
fmuls f4, f3, f4 # left count * y offset
lfs f2, TPO_PLAYER_Y_START(REG_TEXT_PROPERTIES)
fadds f2, f2, f4 # Base y pos + offset

mr r3, REG_PLAYER_INDEX
bl FN_INIT_PLAYER_DISPLAY

LOOP_PLAYER_TEXT_CONTINUE:
subi REG_PLAYER_INDEX, REG_PLAYER_INDEX, 1
cmpwi REG_PLAYER_INDEX, 0
bge LOOP_PLAYER_TEXT_START
LOOP_PLAYER_TEXT_EXIT:

################################################################################
# Pepare text struct for stage
################################################################################
# Initialize Stage Text
li r3, 0
li r4, 0
branchl r12, 0x803a6754
mr REG_TEXT_STRUCT, r3

# Initialize Struct Stuff
lfs f1, TPO_STAGE_X_POS(REG_TEXT_PROPERTIES)
stfs f1,0x0(REG_TEXT_STRUCT)
lfs f1, TPO_STAGE_Y_POS(REG_TEXT_PROPERTIES)
stfs f1,0x4(REG_TEXT_STRUCT)
lfs f1, TPO_STAGE_UNK0(REG_TEXT_PROPERTIES) # Width?
stfs f1,0x8(REG_TEXT_STRUCT)
lfs f1, TPO_STAGE_UNK1(REG_TEXT_PROPERTIES) # Unk, 160
stfs f1,0xC(REG_TEXT_STRUCT)
lfs f1, TPO_STAGE_UNK2(REG_TEXT_PROPERTIES) # Unk, 300
stfs f1,0x10(REG_TEXT_STRUCT)
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

# Check to execute alternate stage name logic (non-applicable to vanilla melee))
mr  r3, REG_TEXT_STRUCT
lhz r4, MSRB_GAME_INFO_BLOCK + 0xE(REG_MSRB_ADDR) # Stage ExtID
branchl r12,FN_CheckAltStageName
cmpwi r3,1
beq STAGE_NAME_SKIP

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
STAGE_NAME_SKIP:

# Kill SFX
#branchl r12,0x80023694
STAGE_NAME_EXIT:
restore BKP_DEFAULT_FREE_SPACE_SIZE, 1
b EXIT

################################################################################
# Function for initializing a player's subtext
################################################################################
# Inputs:
# r3 - Player index (will grab team/port and color from MSRB game info)
# f1 - X Pos
# f2 - Y Pos
################################################################################
FN_INIT_PLAYER_DISPLAY:
backup BKP_DEFAULT_FREE_SPACE_SIZE, 2

# Save registers for later use.
# We will assume REG_TEXT_PROPERTIES, REG_TEXT_STRUCT, and REG_MSRB_ADDR is already set
fmr f31, f1
fmr f30, f2
mr REG_PLAYER_INDEX, r3

# First let's figure out the string to use and the color for the label
# Check if this is teams mode
lbz r3, MSRB_GAME_INFO_BLOCK + 0x8(REG_MSRB_ADDR)
cmpwi r3, 0
bne FN_INIT_PLAYER_DISPLAY_TEAMS

# Here this is not a teams game, so let's prepare to write the port label
# Get color of this port
mulli r3, REG_PLAYER_INDEX, 4
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_RED
add r4, r4, r3 # r4 now points to the correct color for this port

# Prepare the P%d string with the correct port number
addi r7, REG_TEXT_PROPERTIES, TPO_PORT_STRING
addi r8, REG_PLAYER_INDEX, 1

b FN_INIT_PLAYER_DISPLAY_CREATE_LABEL_TEXT

FN_INIT_PLAYER_DISPLAY_TEAMS:
# Here this is a teams game, so let's prepare to write the team label
# Load the team id for this player
mulli r3, REG_PLAYER_INDEX, 0x24
addi r3, r3, MSRB_GAME_INFO_BLOCK + 0x69 # loc of this player index's team id
lbzx r12, REG_MSRB_ADDR, r3 # load team id for player

# Get color for this team
mr r11, r12
cmpwi r11, 2 # check for green team
blt FN_INIT_PLAYER_DISPLAY_TEAMS_SKIP_COL_ADJUST
addi r11, r11, 1 # team 3 is green, not yellow, gotta move one index over
FN_INIT_PLAYER_DISPLAY_TEAMS_SKIP_COL_ADJUST:
mulli r3, r11, 4
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_RED
add r4, r4, r3 # r4 now points to the correct color for this team

# Get label string for this team
mulli r3, r12, 3
addi r7, REG_TEXT_PROPERTIES, TPO_RED_TEAM_LABEL_STRING
add r7, r7, r3 # r7 now points to the correct label string

FN_INIT_PLAYER_DISPLAY_CREATE_LABEL_TEXT:
# Init label text
mr r3, REG_TEXT_STRUCT
li r5, 0
lfs f1, TPO_LABEL_AND_NAME_SIZE(REG_TEXT_PROPERTIES)
fmr f2, f31
fmr f3, f30
branchl r12, FG_CreateSubtext

# Now we want to set up the player name text, which is to the right of the label
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE
li r5, 0
addi r7, REG_MSRB_ADDR, MSRB_P1_NAME
mulli r8, REG_PLAYER_INDEX, 31
add r7, r7, r8 # r7 now points to the correct player name string
lfs f1, TPO_LABEL_AND_NAME_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PORT_NAME_X_OFST(REG_TEXT_PROPERTIES)
fadds f2, f31, f2
fmr f3, f30
branchl r12, FG_CreateSubtext

restore BKP_DEFAULT_FREE_SPACE_SIZE, 2
blr

EXIT:
li r0, -1
