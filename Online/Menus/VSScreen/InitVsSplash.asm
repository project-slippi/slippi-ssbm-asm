################################################################################
# Address: 0x80186ec4 # SceneLoad_ClassicModeSplash
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEXT_PROPERTIES, 31
.set REG_TEXT_STRUCT, 30
.set REG_MSRB_ADDR, 29

# FN_GET_TEAM_PLAYERS
.set REG_TEAM_ID, 28
.set REG_PLAYER_INDEX, 27
.set REG_PLAYERS_COUNT, 26
.set REG_PLAYER_1_NAME_STRING, 25
.set REG_PLAYER_2_NAME_STRING, 24
.set REG_PLAYER_3_NAME_STRING, 23

# INIT_PLAYER_TEXT:
.set REG_LABEL_COLOR, 22
.set REG_CUR_SUBTEXT_IDX, 21

.set REG_POS_X_START, 31
.set REG_POS_Y_START, 30


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
.float 65
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
.float 22
.set TPO_PLAYER_NAME_Y_OFST, TPO_PLAYER_NAME_X_OFST + 4
.float 22

# String Properties
.set TPO_TEAM_1_STRING, TPO_PLAYER_NAME_Y_OFST + 4
.string "Team 1"
.set TPO_TEAM_2_STRING, TPO_TEAM_1_STRING + 7
.string "Team 2"
.set TPO_P1_STRING, TPO_TEAM_2_STRING + 7
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


bl FN_GET_MATCH_MODE
# logf LOG_LEVEL_NOTICE, "FN_GET_MATCH_MODE: %d", "mr r5, 3"
cmpwi r3, 0 # 1vs1
beq INIT_1v1_PLAYER_TEXT
cmpwi r3, 1 # 2vs2
beq INIT_2v2_PLAYER_TEXT
cmpwi r3, 2 # 3vs1
beq INIT_3v1_PLAYER_TEXT
cmpwi r3, 3 # 1vs3
beq INIT_1v3_PLAYER_TEXT

INIT_1v1_PLAYER_TEXT:
# Initialize Team 1 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P1_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_P1_STRING
addi r5, REG_MSRB_ADDR, MSRB_P1_NAME
li r6, 0
lfs f1, TPO_P1_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT

# Initialize Team 2 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P2_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_P2_STRING
addi r5, REG_MSRB_ADDR, MSRB_P2_NAME
li r6, 0
lfs f1, TPO_P2_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT
b INIT_STAGE_TEXT

INIT_2v2_PLAYER_TEXT:
INIT_3v1_PLAYER_TEXT:
lbz r3, MSRB_LOCAL_PLAYER_INDEX(REG_MSRB_ADDR)
# logf LOG_LEVEL_NOTICE, "MSRB_LOCAL_PLAYER_INDEX: %d", "mr r5, 3"
bl FN_GET_PLAYER_TEAM
bl FN_GET_TEAM_PLAYERS

# Initialize Team 1 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P1_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_TEAM_1_STRING
lfs f1, TPO_P1_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT

lbz r3, MSRB_REMOTE_PLAYER_INDEX(REG_MSRB_ADDR)
# logf LOG_LEVEL_NOTICE, "MSRB_REMOTE_PLAYER_INDEX: %d", "mr r5, 3"
bl FN_GET_PLAYER_TEAM
bl FN_GET_TEAM_PLAYERS

# Initialize Team 2 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P2_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_TEAM_2_STRING
lfs f1, TPO_P2_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT
b INIT_STAGE_TEXT

INIT_1v3_PLAYER_TEXT:
# Initialize Team 1 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P1_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_P1_STRING
addi r5, REG_MSRB_ADDR, MSRB_LOCAL_NAME
li r6, 0
lfs f1, TPO_P1_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT

addi r3, REG_MSRB_ADDR, MSRB_REMOTE_PLAYER_INDEX
bl FN_GET_PLAYER_TEAM
bl FN_GET_TEAM_PLAYERS

# Initialize Team 2 Text
addi r3, REG_TEXT_PROPERTIES, TPO_P2_LABEL_COLOR
addi r4, REG_TEXT_PROPERTIES, TPO_TEAM_2_STRING
lfs f1, TPO_P2_X_POS(REG_TEXT_PROPERTIES)
bl INIT_PLAYER_TEXT
b INIT_STAGE_TEXT


INIT_STAGE_TEXT:
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
# r6 - Team Players count
# r7 - Team Player 1 Name String
# r8 - Team Player 2 Name String
# f1 - X Pos
################################################################################
INIT_PLAYER_TEXT:
backup

fmr REG_POS_X_START, f1
mr REG_LABEL_COLOR, r3
mr REG_PLAYER_1_NAME_STRING, r5

mr REG_PLAYERS_COUNT, r6
mr REG_PLAYER_2_NAME_STRING, r7
mr REG_PLAYER_3_NAME_STRING, r8

# load initial y position
lfs REG_POS_Y_START, TPO_PLAYER_Y_START(REG_TEXT_PROPERTIES)
lfs f3, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)

mr r3, REG_PLAYERS_COUNT
branchl r12, FN_IntToFloat
fmuls f3, f3, f1
fsubs REG_POS_Y_START, REG_POS_Y_START, f3

# Init port label text
fmr f1, REG_POS_X_START
fmr f2, REG_POS_Y_START
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
fmr f1, REG_POS_X_START
fmr f2, REG_POS_Y_START
lfs f3, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)
fadds f2, f2, f3
mr r3, REG_TEXT_STRUCT
mr r4, REG_PLAYER_1_NAME_STRING
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# if no more players exit
cmpwi REG_PLAYERS_COUNT, 0
beq INIT_PLAYER_TEXT_EXIT

# Init team player 1 name text
fmr f1, REG_POS_X_START
fmr f2, REG_POS_Y_START
lfs f3, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)
fadds f2, f2, f3
fadds f2, f2, f3
lfs f3, TPO_PLAYER_NAME_X_OFST(REG_TEXT_PROPERTIES)
fadds f1, f1, f3
mr r3, REG_TEXT_STRUCT
mr r4, REG_PLAYER_2_NAME_STRING
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# if no more players exit
cmpwi REG_PLAYERS_COUNT, 1
beq INIT_PLAYER_TEXT_EXIT

# Init team player name text
fmr f1, REG_POS_X_START
fmr f2, REG_POS_Y_START
lfs f3, TPO_PLAYER_NAME_Y_OFST(REG_TEXT_PROPERTIES)
fadds f2, f2, f3
fadds f2, f2, f3
fadds f2, f2, f3
lfs f3, TPO_PLAYER_NAME_X_OFST(REG_TEXT_PROPERTIES)
fadds f1, f1, f3
fadds f1, f1, f3
mr r3, REG_TEXT_STRUCT
mr r4, REG_PLAYER_3_NAME_STRING
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYER_NAME_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

INIT_PLAYER_TEXT_EXIT:
restore
blr

# returns match mode depending on number of players
# return r3: 0=1vs1, 1=2vs2, 2=3vs1, 3=1vs3
FN_GET_MATCH_MODE:
backup
# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

lbz r3, MSRB_GAME_INFO_BLOCK + 0xD(REG_MSRB_ADDR)
# 0 = no teams, 1 = teams

FN_GET_MATCH_MODE_EXIT:
restore
blr

# input r3 = player index
# returns player's team id on r3
FN_GET_PLAYER_TEAM:
backup
mr REG_PLAYER_INDEX, r3
# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3


li r4, MSRB_GAME_INFO_BLOCK + 0x69
mulli r3, REG_PLAYER_INDEX, 0x24
add r4, r4, r3
add r4, r4, REG_MSRB_ADDR
lbz r3, 0x0(r4) # team id

# logf LOG_LEVEL_NOTICE, "FN_GET_PLAYER_TEAM ID: %d", "mr r5, 3"
# lbz r4, MSRB_GAME_INFO_BLOCK + 0x69 + 0x24*i(REG_MSRB_ADDR)

FN_GET_PLAYER_TEAM_EXIT:
restore
blr

# input r3: Team ID
# returns Names on r5,r7,r8 of all players
# returns player count on r6
FN_GET_TEAM_PLAYERS:
backup
mr REG_TEAM_ID, r3

# logf LOG_LEVEL_NOTICE, "FN_GET_TEAM_PLAYERS REG_TEAM_ID: %d", "mr r5, 3"

# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

li REG_PLAYER_1_NAME_STRING, 0
li REG_PLAYER_2_NAME_STRING, 0
li REG_PLAYER_3_NAME_STRING, 0

li REG_PLAYERS_COUNT, 0
li REG_PLAYER_INDEX, 0

FN_GET_TEAM_PLAYERS_LOOP_START:
li r4, MSRB_GAME_INFO_BLOCK + 0x69
mulli r3, REG_PLAYER_INDEX, 0x24
add r4, r4, r3
add r4, r4, REG_MSRB_ADDR
lbz r3, 0x0(r4) # team id

# if teams do not match continue
cmpw r3, REG_TEAM_ID
bne FN_GET_TEAM_PLAYERS_LOOP_CONTINUE

addi REG_PLAYERS_COUNT, REG_PLAYERS_COUNT, 1

# Calculate offset where get player name from
li r3, MSRB_P1_NAME
li r4, 31 # player string size
mullw r4, r4, REG_PLAYER_INDEX
add r3, r4, r3 # MSRB_P1_NAME + (REG_PLAYER_INDEX*31)

# check which player name is not yet assigned
cmpwi REG_PLAYER_1_NAME_STRING, 0
beq FN_GET_TEAM_PLAYERS_SET_PLAYER_1_NAME
cmpwi REG_PLAYER_2_NAME_STRING, 0
beq FN_GET_TEAM_PLAYERS_SET_PLAYER_2_NAME
cmpwi REG_PLAYER_3_NAME_STRING, 0
beq FN_GET_TEAM_PLAYERS_SET_PLAYER_3_NAME

FN_GET_TEAM_PLAYERS_SET_PLAYER_1_NAME:
add REG_PLAYER_1_NAME_STRING, REG_MSRB_ADDR, r3
b FN_GET_TEAM_PLAYERS_LOOP_CONTINUE
FN_GET_TEAM_PLAYERS_SET_PLAYER_2_NAME:
add REG_PLAYER_2_NAME_STRING, REG_MSRB_ADDR, r3
b FN_GET_TEAM_PLAYERS_LOOP_CONTINUE
FN_GET_TEAM_PLAYERS_SET_PLAYER_3_NAME:
add REG_PLAYER_3_NAME_STRING, REG_MSRB_ADDR, r3
b FN_GET_TEAM_PLAYERS_LOOP_CONTINUE

FN_GET_TEAM_PLAYERS_LOOP_CONTINUE:
addi REG_PLAYER_INDEX, REG_PLAYER_INDEX, 1
cmpwi REG_PLAYER_INDEX, 4
blt FN_GET_TEAM_PLAYERS_LOOP_START
FN_GET_TEAM_PLAYERS_LOOP_END:

# returns Names on r5,r7,r8 of all players
# returns player count on r6
mr r5, REG_PLAYER_1_NAME_STRING
mr r7, REG_PLAYER_2_NAME_STRING
mr r8, REG_PLAYER_3_NAME_STRING
mr r6, REG_PLAYERS_COUNT

FN_GET_TEAM_PLAYERS_EXIT:
restore
blr

EXIT:
li r0, -1
