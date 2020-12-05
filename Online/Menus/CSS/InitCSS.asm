################################################################################
# Address: 0x80264534 # CSS_LoadFunction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_CSSDT_ADDR, 31
.set REG_MSRB_ADDR, 30
.set REG_TEXT_PROPERTIES, 29
.set REG_TEXT_STRUCT, 28
.set REG_SUBTEXT_IDX, 27
.set REG_VARIOUS_1, 26
.set REG_VARIOUS_2, 25
.set REG_VARIOUS_3, 24
.set REG_VARIOUS_4, 23
.set REG_VARIOUS_5, 22
.set REG_LR, 21

# Registers to be used in Chat Messagees Think Function
.set CHAT_ENTITY_DATA_OFFSET, 0x2C # offset from GOBJ to entity data
.set REG_CHATMSG_GOBJ, 14
.set REG_CHATMSG_GOBJ_DATA_ADDR, REG_CHATMSG_GOBJ+1
.set REG_CHATMSG_TIMER, REG_CHATMSG_GOBJ_DATA_ADDR+1
.set REG_CHATMSG_MSG_ID, REG_CHATMSG_TIMER+1
.set REG_CHATMSG_MSG_INDEX, REG_CHATMSG_MSG_ID+1
.set REG_CHATMSG_MSG_TEXT_STRUCT_ADDR, REG_CHATMSG_MSG_INDEX+1
.set REG_CHATMSG_MSG_STRING_ADDR, REG_CHATMSG_MSG_TEXT_STRUCT_ADDR+1
.set REG_CHATMSG_USER_NAME_ADDR, REG_CHATMSG_MSG_STRING_ADDR+1
.set REG_CHAT_TEXT_PROPERTIES, REG_CHATMSG_USER_NAME_ADDR+1
# float registers
.set REG_CHATMSG_TEXT_X_POS, REG_CHATMSG_GOBJ
.set REG_CHATMSG_TEXT_Y_POS, REG_CHATMSG_TEXT_X_POS+1

 # Chat Messages Pad Mapping
.set PAD_LEFT, 0x1
.set PAD_RIGHT, 0x2
.set PAD_DOWN, 0x4
.set PAD_UP, 0x8

.set MAX_CHAT_MESSAGES, 6 # Max messages being displayed at the same time
.set MAX_CHAT_MESSAGE_LINES, 14
.set CHAT_MESSAGE_DISPLAY_TIMER, 0xAA

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal
b LOAD_START

################################################################################
# Properties
################################################################################
.set CHAT_TEXT_STRING_LENGTH, 22 +1  # +1 is string ending char
TEXT_PROPERTIES:
blrl
# Base Properties
.set TPO_BASE_Z, 0
.float 0
.set TPO_CHATMSG_Z, TPO_BASE_Z + 4
.float 0
.set TPO_BASE_CANVAS_SCALING, TPO_CHATMSG_Z + 4
.float 0.1

# Chat Message Propiertes
.set TPO_CHATMSG_X, TPO_BASE_CANVAS_SCALING + 4
.float -330
.set TPO_CHATMSG_Y, TPO_CHATMSG_X + 4
.float -285
.set TPO_CHATMSG_SIZE, TPO_CHATMSG_Y + 4
.float 0.45
.set TPO_CHATMSG_SIZE_SM, TPO_CHATMSG_SIZE + 4
.float 0.40
.set TPO_CHATMSG_OUTLINE_OFFSET, TPO_CHATMSG_SIZE_SM + 4
.float 1
.set TPO_CHATMSG_SIZE_MARGIN, TPO_CHATMSG_OUTLINE_OFFSET + 4
.float 25

# Header properties
.set TPO_HEADER_X, TPO_CHATMSG_SIZE_MARGIN + 4
.float 70
.set TPO_HEADER_Y, TPO_HEADER_X + 4
.float 23
.set TPO_HEADER_SIZE, TPO_HEADER_Y + 4
.float 0.50

# Line properties
.set TPO_LINES_X, TPO_HEADER_SIZE + 4
.float 90
.set TPO_LINE1_Y, TPO_LINES_X + 4
.float 52
.set TPO_LINE2_Y, TPO_LINE1_Y + 4
.float 75
.set TPO_LINE3_Y, TPO_LINE2_Y + 4
.float 98
.set TPO_ERR_LINE1_Y, TPO_LINE3_Y + 4
.float 52
.set TPO_ERR_LINE2_Y, TPO_ERR_LINE1_Y + 4
.float 70
.set TPO_ERR_LINE3_Y, TPO_ERR_LINE2_Y + 4
.float 88
.set TPO_ERR_LINE4_Y, TPO_ERR_LINE3_Y + 4
.float 106
.set TPO_LINES_SIZE, TPO_ERR_LINE4_Y + 4
.float 0.4

# Press Z properties
.set TPO_PRESS_Z_Y, TPO_LINES_SIZE + 4
.float 132.5
# Press D Properties
.set TPO_PRESS_D_Y, TPO_PRESS_Z_Y + 4
.float 152.5

# User Chat Label Properties
# This is supposed to set the chat message cheat on top of
# the original user display
.set TPO_USER_Y, TPO_PRESS_D_Y + 4
.float 40 # Y Pos of User Display, 0x4
.set TPO_USER_X, TPO_USER_Y + 4
.float -112 # X Pos of User Display, 0x0
.set TPO_USER_SIZE, TPO_USER_X + 4
.float 0.5 # Scaling, 0xC

# Player Label Properties
.set TPO_PLAYING_Y, TPO_USER_SIZE + 4
.float -246
.set TPO_PLAYING_LABEL_X, TPO_PLAYING_Y + 4
.float -130
.set TPO_PLAYING_VALUE_X, TPO_PLAYING_LABEL_X + 4
.float -50

# Spinner properties
.set TPO_SPINNER_SIZE, TPO_PLAYING_VALUE_X + 4
.float 0.45
.set TPO_SPINNER_DONE_COLOR, TPO_SPINNER_SIZE + 4
.long 0x33FF2FFF
.set TPO_SPINNER_WAITING_COLOR, TPO_SPINNER_DONE_COLOR + 4
.long 0x3CBCFFFF

# Text colors
.set TPO_COLOR_GRAY, TPO_SPINNER_WAITING_COLOR + 4
.long 0x8E9196FF
.set TPO_COLOR_RED, TPO_COLOR_GRAY + 4
.long 0xFF0000FF
.set TPO_COLOR_CHAT, TPO_COLOR_RED + 4
.long 0xFFFFFFFF # white
.set TPO_COLOR_CHAT_BG, TPO_COLOR_CHAT + 4
.long 0x00000000 # black


# String Properties
.set TPO_EMPTY_STRING, TPO_COLOR_CHAT_BG + 4
.string ""
.set TPO_STRING_UNRANKED, TPO_EMPTY_STRING + 1
.string "Unranked Mode"
.set TPO_STRING_DIRECT, TPO_STRING_UNRANKED + 14
.string "Direct Mode"
.set TPO_STRING_RANKED, TPO_STRING_DIRECT + 12
.string "Ranked Mode"
.set TPO_STRING_SELECT_YOUR_CHARACTER, TPO_STRING_RANKED + 12
.string "Select your character"
.set TPO_STRING_CHARACTER_SELECTED, TPO_STRING_SELECT_YOUR_CHARACTER + 22
.string "Character selected"
.set TPO_STRING_PRESS_START_TO, TPO_STRING_CHARACTER_SELECTED + 19
.string "Press START to %s"
.set TPO_STRING_LOCK_IN, TPO_STRING_PRESS_START_TO + 18
.string "lock in"
.set TPO_STRING_ENTER_CODE, TPO_STRING_LOCK_IN + 8
.string "enter code"
.set TPO_STRING_SEARCH, TPO_STRING_ENTER_CODE + 11
.string "search"
.set TPO_STRING_SELECT_STAGE, TPO_STRING_SEARCH + 7
.string "select stage"
.set TPO_STRING_LOCKED_IN, TPO_STRING_SELECT_STAGE + 13
.string "Locked in"
.set TPO_STRING_SEARCHING_FOR, TPO_STRING_LOCKED_IN + 10
.string "Searching for %s"
.set TPO_STRING_CONNECTING_TO, TPO_STRING_SEARCHING_FOR + 17
.string "Connecting to %s"
.set TPO_STRING_WAITING_ON, TPO_STRING_CONNECTING_TO + 17
.string "Waiting on %s"
.set TPO_STRING_OPPONENT, TPO_STRING_WAITING_ON + 14
.string "opponent"
.set TPO_STRING_OPP_CODE, TPO_STRING_OPPONENT + 9
.string "--//--//--//--//00"
.set TPO_STRING_ERROR, TPO_STRING_OPP_CODE + 19
.string "Error"
.set TPO_STRING_PLAYING_LABEL, TPO_STRING_ERROR + 6
.string "Playing:"
.set TPO_STRING_USER_D_PAD_TO_CHAT, TPO_STRING_PLAYING_LABEL + 9
.string "Use D-Pad to Chat"
.set TPO_STRING_PRESS_Z_TO, TPO_STRING_USER_D_PAD_TO_CHAT + 18
.string "Press Z to %s"
.set TPO_STRING_HOLD_Z_TO, TPO_STRING_PRESS_Z_TO + 14
.string "Hold Z to %s"
.set TPO_STRING_DISCONNECT, TPO_STRING_HOLD_Z_TO + 13
.string "disconnect"
.set TPO_STRING_CANCEL, TPO_STRING_DISCONNECT + 11
.string "cancel"
.set TPO_STRING_CLEAR_ERROR, TPO_STRING_CANCEL + 7
.string "clear error"
.set TPO_STRING_CHATMSG_FORMAT, TPO_STRING_CLEAR_ERROR + 12
.string "%s: %s"
.set TPO_STRING_SPINNER_1, TPO_STRING_CHATMSG_FORMAT + 7
.short 0x817B # ＋
.byte 0x00
.set TPO_STRING_SPINNER_2, TPO_STRING_SPINNER_1 + 3
.short 0x817E # ×
.byte 0x00
.set TPO_STRING_SPINNER_DONE, TPO_STRING_SPINNER_2 + 3
.short 0x817C # －
.byte 0x00
.align 2

################################################################################
# Chat Message Properties
# Hack: CAP TO SAME LENGTH to ensure pointers are always reached
# TODO: Find a way to reuse this between HandleInputOnCSS.asm and this file.
################################################################################
.set CHAT_TEXT_STRING_LENGTH, 22 +1  # +1 is string ending char
UP_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_MSG_UP, 0
.string "ggs                   "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "one more              "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "brb                   "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "good luck             "
.align 2

LEFT_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_MSG_UP, 0
.string "well played           "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "that was fun          "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "thanks                "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "too good              "
.align 2

RIGHT_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_MSG_UP, 0
.string "oof                   "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "my b                  "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "lol                   "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "wow                   "
.align 2

DOWN_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_MSG_UP, 0
.string "okay                  "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "thinking              "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "let's play again later"
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "bad connection        "
.align 2


################################################################################
# User text config
################################################################################
DATA_USER_TEXT_BLRL:
blrl
.float -112 # X Pos of User Display, 0x0
.float 20 # Y Pos of User Display, 0x4
.float 0 # Z Offset, 0x8
.float 0.1 # Scaling, 0xC

################################################################################
# Start Init Function
################################################################################
LOAD_START:
backup

################################################################################
# Init non-volatile registers
################################################################################
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

################################################################################
# Initialize user text
################################################################################
lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_DIRECT
li r4, 1
bne INIT_USER_TEXT
li r4, 2

INIT_USER_TEXT:
bl DATA_USER_TEXT_BLRL
mflr r3
branchl r12, FG_UserDisplay
blrl # FN_InitUserDisplay

################################################################################
# Queue up per-frame CSS text update function
################################################################################
# Create GObj (input values stolen from CSS_BigFunc... GObj)
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create

# Schedule Function
bl CSS_ONLINE_TEXT_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

################################################################################
# Allocate memory locations
################################################################################
# Initialize CSS data table
li r3, CSSDT_SIZE
branchl r12, HSD_MemAlloc
mr REG_CSSDT_ADDR, r3

# Zero out CSS data table
li r4, CSSDT_SIZE
branchl r12, Zero_AreaLength

# Store CSSDT to static mem location
load r3, CSSDT_BUF_ADDR
stw REG_CSSDT_ADDR, 0(r3)

# Prepare the MSRB buffer
li r3, MSRB_SIZE
branchl r12, HSD_MemAlloc
stw r3, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)

################################################################################
# Set up CSS text
################################################################################
# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3
stw REG_TEXT_STRUCT, CSSDT_TEXT_STRUCT_ADDR(REG_CSSDT_ADDR)

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

# Initialize header
lfs f1, TPO_HEADER_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_HEADER_Y(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
branchl r12, Text_InitializeSubtext

# Set header text size
mr r4, r3 # stidx = 0
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Initialize lines
lfs f2, TPO_LINE1_Y(REG_TEXT_PROPERTIES)
bl INIT_LINE_SUBTEXT

lfs f2, TPO_LINE2_Y(REG_TEXT_PROPERTIES)
bl INIT_LINE_SUBTEXT

lfs f2, TPO_LINE3_Y(REG_TEXT_PROPERTIES)
bl INIT_LINE_SUBTEXT

# Initialize Press Z text
lfs f1, TPO_HEADER_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_PRESS_Z_Y(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
branchl r12, Text_InitializeSubtext

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PRESS_Z # stidx = 1
lfs f1, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PRESS_Z
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_GRAY
branchl r12, Text_ChangeTextColor

# Initialize Use D-PAD to Chat
lfs f1, TPO_HEADER_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_PRESS_D_Y(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
branchl r12, Text_InitializeSubtext

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PRESS_D # stidx = 1
lfs f1, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PRESS_D
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_GRAY
branchl r12, Text_ChangeTextColor

# Initialize Playing Label
lfs f1, TPO_PLAYING_LABEL_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYING_Y(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
branchl r12, Text_InitializeSubtext

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PLAYING_LABEL
lfs f1, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PLAYING_LABEL
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_GRAY
branchl r12, Text_ChangeTextColor

# Initialize Opponent text
lfs f1, TPO_PLAYING_VALUE_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_PLAYING_Y(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
branchl r12, Text_InitializeSubtext

mr r3, REG_TEXT_STRUCT
li r4, STIDX_PLAYING_OPP
lfs f1, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_HEADER_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Initialize error lines
lfs f2, TPO_ERR_LINE1_Y(REG_TEXT_PROPERTIES)
bl INIT_ERROR_LINE_SUBTEXT

lfs f2, TPO_ERR_LINE2_Y(REG_TEXT_PROPERTIES)
bl INIT_ERROR_LINE_SUBTEXT

lfs f2, TPO_ERR_LINE3_Y(REG_TEXT_PROPERTIES)
bl INIT_ERROR_LINE_SUBTEXT

lfs f2, TPO_ERR_LINE4_Y(REG_TEXT_PROPERTIES)
bl INIT_ERROR_LINE_SUBTEXT

restore
b EXIT

################################################################################
# Function for initializing line subtext.
# Expects f2 to be set to y position of line
################################################################################
INIT_LINE_SUBTEXT:
mflr REG_LR # Single depth helper function. Non-standard

fmr f3, f2

# Init line text
lfs f1, TPO_LINES_X(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING # change to empty string
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Init spinner
lfs f1, TPO_HEADER_X(REG_TEXT_PROPERTIES)
fmr f2, f3
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING # change to empty string
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, TPO_SPINNER_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_SPINNER_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

mtlr REG_LR
blr

################################################################################
# Function for initializing error line subtext
# Expects f2 to be set to y position of line
################################################################################
INIT_ERROR_LINE_SUBTEXT:
backup

# Init line text
lfs f1, TPO_HEADER_X(REG_TEXT_PROPERTIES)
mr r3, REG_TEXT_STRUCT
addi r4, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING # change to empty string
branchl r12, Text_InitializeSubtext
mr REG_SUBTEXT_IDX, r3

# Set line font size
mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
lfs f1, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
lfs f2, TPO_LINES_SIZE(REG_TEXT_PROPERTIES)
branchl r12, Text_UpdateSubtextSize

# Set line font color
mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_COLOR_RED
branchl r12, Text_ChangeTextColor

restore
blr

################################################################################
# Function for updating online status graphics every frame
################################################################################
CSS_ONLINE_TEXT_THINK:
blrl
.set STIDX_HEADER, 0
.set STIDX_LINE1, 1
.set STIDX_LINE2, 3
.set STIDX_LINE3, 5
.set STIDX_SPINNER1, 2
.set STIDX_SPINNER2, 4
.set STIDX_SPINNER3, 6
.set STIDX_PRESS_Z, 7
.set STIDX_PRESS_D, 8
.set STIDX_PLAYING_LABEL, 9
.set STIDX_PLAYING_OPP, 10
.set STIDX_ERR_LINE1, 11
.set STIDX_ERR_LINE2, 12
.set STIDX_ERR_LINE3, 13
.set STIDX_ERR_LINE4, 14
.set LINE_IDX_GAP, 2
.set LINE_COUNT, 3

.set SPINNER_ICON_COUNT, 2
.set SPINNER_ICON_LEN, 3
.set SPINNER_TRANSITION_FRAMES, 15
.set FRAME_MAX, SPINNER_ICON_COUNT * SPINNER_TRANSITION_FRAMES

backup

# Get text properties address
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR
lwz REG_MSRB_ADDR, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)
lwz REG_TEXT_STRUCT, CSSDT_TEXT_STRUCT_ADDR(REG_CSSDT_ADDR)

################################################################################
# Overwrite connect code string... will only matter for direct mode
################################################################################
addi r7, REG_TEXT_PROPERTIES, TPO_STRING_OPP_CODE
load r6, 0x804a0740
li r4, 0
li r5, 0

WRITE_OPP_CODE_LOOP_START:
lhzx r3, r6, r4
sthx r3, r7, r5
addi r4, r4, 3
addi r5, r5, 2
cmpwi r5, 18
blt WRITE_OPP_CODE_LOOP_START

################################################################################
# Manage header text
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
bgt UPDATE_HEADER_ERROR

# Decide which text to load based on mode
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_UNRANKED
beq UPDATE_HEADER_UNRANKED
cmpwi r3, ONLINE_MODE_DIRECT
beq UPDATE_HEADER_DIRECT
cmpwi r3, ONLINE_MODE_RANKED
beq UPDATE_HEADER_RANKED
b UPDATE_HEADER_ERROR

UPDATE_HEADER_UNRANKED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_UNRANKED
b UPDATE_HEADER

UPDATE_HEADER_DIRECT:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_DIRECT
b UPDATE_HEADER

UPDATE_HEADER_RANKED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_RANKED
b UPDATE_HEADER

UPDATE_HEADER_ERROR:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_ERROR
b UPDATE_HEADER

UPDATE_HEADER:
li r4, STIDX_HEADER
bl FN_UPDATE_TEXT

################################################################################
# Manage Chat Messages: If there's a new message, then initialize a
# disappearing text
################################################################################
# r25 will store the user name string memory address
# r26 will store chat message id
lbz r3, MSRB_USER_CHATMSG_ID(REG_MSRB_ADDR)
cmpwi r3, 0
beq CHECK_OPP_CHAT_MESSAGE
addi r25, REG_MSRB_ADDR, MSRB_P1_NAME
mr r26, r3
b UPDATE_CHAT_MESSAGES

CHECK_OPP_CHAT_MESSAGE:
lbz r3, MSRB_OPP_CHATMSG_ID(REG_MSRB_ADDR)
cmpwi r3, 0
beq SKIP_CHAT_MESSAGES
addi r25, REG_MSRB_ADDR, MSRB_P2_NAME
mr r26, r3

UPDATE_CHAT_MESSAGES:
# Start at the top after x messages
lbz r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR)
cmpwi r3, MAX_CHAT_MESSAGE_LINES
ble CREATE_CHAT_MESSAGE
# if we reached the limit, reset the last message index to 0
li r3, 0
stb r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # store the new message index
beq SKIP_CHAT_MESSAGES

CREATE_CHAT_MESSAGE:
# Play a sound indicating a new message
li r3, 0xb7
li r4, 127
li r5, 64
branchl r12, 0x800237a8 # SFX_PlaySoundAtFullVolume

# Store Increased Message Count
lbz r3, CSSDT_CHAT_MSG_COUNT(REG_CSSDT_ADDR)
addi r3, r3, 1
stb r3, CSSDT_CHAT_MSG_COUNT(REG_CSSDT_ADDR)

# Get Memory Buffer for Chat Message Data Table
li r3, CSSCMDT_SIZE
branchl r12, HSD_MemAlloc
mr r23, r3 # save result address into r23

# Zero out CSS data table
li r4, CSSDT_SIZE
branchl r12, Zero_AreaLength

# Set Buffer Initial Data
# initialize timer 0x80195b38
li r3, CHAT_MESSAGE_DISPLAY_TIMER # max value of byte which is 255, approx 4 seconds 255/60 = 4.25 secs
stb r3, CSSCMDT_TIMER(r23)

# initialize message id
mr r3, r26
stb r3, CSSCMDT_MSG_ID(r23)

# Set Message index + increase by 1
lbz r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR)
stb r3, CSSCMDT_MSG_INDEX(r23) # set index in the new buffer
addi r3, r3, 1 # increase message index
stb r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # store the new message index

# Set Username Address
stw r25, CSSCMDT_USER_NAME_ADDR(r23)

# Set CSS DataTable Address
mr r3, REG_CSSDT_ADDR # store address to CSSDT_DT
stw r3, CSSCMDT_CSSDT_ADDR(r23)

# create gobj for think function
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr r14, r3 # save pointer to GOBJ

li r4, 4 # user data kind 0x80195b7c
load r5, HSD_Free # destructor
mr r6, r23 # memory pointer of allocated buffer above
branchl r12, GObj_Initialize

mr r3, r14 # set pointer back to GOBJ
bl CSS_ONLINE_CHAT_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

SKIP_CHAT_MESSAGES:

################################################################################
# Manage playing label
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_PLAYING_LABEL_CONNECTED

# Here we are not connected, clear
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
b UPDATE_PLAYING_LABEL

UPDATE_PLAYING_LABEL_CONNECTED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PLAYING_LABEL

UPDATE_PLAYING_LABEL:
li r4, STIDX_PLAYING_LABEL
bl FN_UPDATE_TEXT

################################################################################
# Manage playing opponent name
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_PLAYING_VALUE_CONNECTED

# Here we are not connected, clear
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
b UPDATE_PLAYING_VALUE

UPDATE_PLAYING_VALUE_CONNECTED:
addi r5, REG_MSRB_ADDR, MSRB_OPP_NAME

UPDATE_PLAYING_VALUE:
li r4, STIDX_PLAYING_OPP
bl FN_UPDATE_TEXT

################################################################################
# Manage press D text
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_PRESS_D_CONNECTED

# clear on all other cases
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
b UPDATE_PRESS_D_TEXT

UPDATE_PRESS_D_CONNECTED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_USER_D_PAD_TO_CHAT

UPDATE_PRESS_D_TEXT:
li r4, STIDX_PRESS_D
bl FN_UPDATE_TEXT

################################################################################
# Manage press Z text
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_PRESS_Z_CONNECTED
cmpwi r3, MM_STATE_ERROR_ENCOUNTERED
beq UPDATE_PRESS_Z_ERROR
cmpwi r3, MM_STATE_IDLE
bgt UPDATE_PRESS_Z_CONNECTING

# If we get here, pressing Z does nothing, clear
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
b UPDATE_PRESS_Z_TEXT

UPDATE_PRESS_Z_CONNECTING:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_Z_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_CANCEL
b UPDATE_PRESS_Z_TEXT

UPDATE_PRESS_Z_ERROR:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_Z_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_CLEAR_ERROR
b UPDATE_PRESS_Z_TEXT

UPDATE_PRESS_Z_CONNECTED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_HOLD_Z_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_DISCONNECT

UPDATE_PRESS_Z_TEXT:
li r4, STIDX_PRESS_Z
bl FN_UPDATE_TEXT

################################################################################
# Clear all lines
################################################################################
li REG_SUBTEXT_IDX, STIDX_LINE1
LOOP_LINE_CLEAR_START:
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
bl FN_UPDATE_TEXT
addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, LINE_IDX_GAP
cmpwi REG_SUBTEXT_IDX, STIDX_LINE3
ble LOOP_LINE_CLEAR_START

li r4, CSSDT_SPINNER1
li r3, 0
LOOP_SPINNER_CLEAR_START:
stbx r3, REG_CSSDT_ADDR, r4
addi r4, r4, 1
cmpwi r4, CSSDT_SPINNER3
ble LOOP_SPINNER_CLEAR_START

li REG_SUBTEXT_IDX, STIDX_ERR_LINE1
LOOP_ERR_LINE_CLEAR_START:
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
bl FN_UPDATE_TEXT
addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, 1
cmpwi REG_SUBTEXT_IDX, STIDX_ERR_LINE4
ble LOOP_ERR_LINE_CLEAR_START

################################################################################
# Deal with error state
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_ERROR_ENCOUNTERED
bne START_UPDATE_LINES

.set REG_LINE_IDX, REG_VARIOUS_1
.set REG_LINE_LEN, REG_VARIOUS_2
.set REG_LINE_LAST_SPACE_IDX, REG_VARIOUS_3
.set REG_LINE_START, REG_VARIOUS_4
.set REG_ERR_CUR_BYTE, REG_VARIOUS_5

li REG_SUBTEXT_IDX, STIDX_ERR_LINE1 # Start with line 1
li REG_LINE_IDX, 0
li REG_LINE_LEN, 0
li REG_LINE_LAST_SPACE_IDX, 0
addi REG_LINE_START, REG_MSRB_ADDR, MSRB_ERROR_MSG
LOOP_ERR_STR_SET_START:
lbzx REG_ERR_CUR_BYTE, REG_LINE_START, REG_LINE_IDX
rlwinm. r0, REG_ERR_CUR_BYTE, 0, 0x80
beq CHECK_SINGLE_BYTE_LETTER

# If we get here, we have a 2-byte letter. Just add 2 to index and continue
addi REG_LINE_IDX, REG_LINE_IDX, 2
addi REG_LINE_LEN, REG_LINE_LEN, 1
b CHECK_TO_SET_ERROR_LINE

CHECK_SINGLE_BYTE_LETTER:

# Handle space letter
cmpwi REG_ERR_CUR_BYTE, 0x20
bne SINGLE_BYTE_SPACE_HANDLING_END
mr REG_LINE_LAST_SPACE_IDX, REG_LINE_IDX
SINGLE_BYTE_SPACE_HANDLING_END:

# Increment indices. Line len is not always the same as idx when there are
# 2 byte letter
addi REG_LINE_IDX, REG_LINE_IDX, 1
addi REG_LINE_LEN, REG_LINE_LEN, 1

CHECK_TO_SET_ERROR_LINE:
# Check null first, don't want to create new null and lose the last string
# if the line ends at the exact max length
cmpwi REG_ERR_CUR_BYTE, 0x0
beq SET_ERROR_LINE
cmpwi REG_LINE_LEN, 30
bgt REPLACE_LAST_SPACE
b SET_ERROR_LINE_END

REPLACE_LAST_SPACE:
# First replace last space with terminator
li r4, 0
stbx r4, REG_LINE_START, REG_LINE_LAST_SPACE_IDX

SET_ERROR_LINE:
mr r4, REG_SUBTEXT_IDX
mr r5, REG_LINE_START
bl FN_UPDATE_TEXT

addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, 1
add REG_LINE_START, REG_LINE_START, REG_LINE_LAST_SPACE_IDX
addi REG_LINE_START, REG_LINE_START, 1
li REG_LINE_IDX, 0
li REG_LINE_LEN, 0
SET_ERROR_LINE_END:

LOOP_ERR_STR_SET_CONDITION:
# Check if current byte is the termination byte
# Check if byte index is too high
# Check if subtext idx is too high
cmpwi REG_ERR_CUR_BYTE, 0x0
beq LOOP_ERR_STR_SET_END
addi r3, REG_MSRB_ADDR, MSRB_ERROR_MSG + ERROR_MESSAGE_LEN
add r4, REG_LINE_START, REG_LINE_IDX
cmpw r4, r3
bge LOOP_ERR_STR_SET_END
cmpwi REG_SUBTEXT_IDX, STIDX_ERR_LINE4
bgt LOOP_ERR_STR_SET_END
b LOOP_ERR_STR_SET_START
LOOP_ERR_STR_SET_END:

b UPDATE_LINES_EXIT

START_UPDATE_LINES:
# Init cur line to first line
li REG_SUBTEXT_IDX, STIDX_LINE1

################################################################################
# Set up select character line
################################################################################
lbz r3, -0x49A9(r13)
mr r4, REG_SUBTEXT_IDX
cmpwi r3, 0
bne UPDATE_CHAR_SELECTED

addi r5, REG_TEXT_PROPERTIES, TPO_STRING_SELECT_YOUR_CHARACTER
bl FN_UPDATE_TEXT
li r3, 1
stb r3, CSSDT_SPINNER1(REG_CSSDT_ADDR)
b UPDATE_LINES_EXIT

UPDATE_CHAR_SELECTED:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_CHARACTER_SELECTED
bl FN_UPDATE_TEXT
addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, LINE_IDX_GAP # move to next line
li r3, 2
stb r3, CSSDT_SPINNER1(REG_CSSDT_ADDR)

################################################################################
# Set up lock in line
################################################################################
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
mr r4, REG_SUBTEXT_IDX
cmpwi r3, 0
bne UPDATE_LOCKED_IN

# If direct && loser && not locked in, show press start to select stage
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_DIRECT        # Check if this is direct mode
bne NOT_SELECT_STAGE
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
bne NOT_SELECT_STAGE
lbz r3, OFST_R13_ISWINNER (r13)
cmpwi r3,ISWINNER_LOST              # Check if this is the loser
bne NOT_SELECT_STAGE
lbz r3, OFST_R13_CHOSESTAGE (r13)
cmpwi r3,0                          # Check if loser picked stage already
bne NOT_SELECT_STAGE
# Prep "press start" text to use
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_START_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_SELECT_STAGE
b UPDATE_PRESS_START_TEXT

NOT_SELECT_STAGE:
# Prep "press start" text to use
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_START_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_LOCK_IN

lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_PRESS_START_TEXT # If connected already, always show lock-in text

addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_START_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_SEARCH

lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_DIRECT
bne UPDATE_PRESS_START_TEXT # If not direct, show search text

# Show "enter-code" press start action
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_PRESS_START_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_ENTER_CODE

UPDATE_PRESS_START_TEXT:
bl FN_UPDATE_TEXT
li r3, 1
stb r3, CSSDT_SPINNER2(REG_CSSDT_ADDR)
b UPDATE_LINES_EXIT

UPDATE_LOCKED_IN:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_LOCKED_IN
bl FN_UPDATE_TEXT
addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, LINE_IDX_GAP # move to next line
li r3, 2
stb r3, CSSDT_SPINNER2(REG_CSSDT_ADDR)

################################################################################
# Set up waiting line
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
mr r4, REG_SUBTEXT_IDX
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq UPDATE_WAITING_WITH_OPPONENT

cmpwi r3, MM_STATE_OPPONENT_CONNECTING
beq UPDATE_CONNECTING_TO_OPPONENT

# Prep "searching" text to use
lbz r5, OFST_R13_ONLINE_MODE(r13)
cmpwi r5, ONLINE_MODE_DIRECT
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_SEARCHING_FOR
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_OPPONENT
bne UPDATE_WAITING

addi r5, REG_TEXT_PROPERTIES, TPO_STRING_SEARCHING_FOR
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_OPP_CODE
b UPDATE_WAITING

UPDATE_CONNECTING_TO_OPPONENT:
# Prep "connecting" text to use
lbz r5, OFST_R13_ONLINE_MODE(r13)
cmpwi r5, ONLINE_MODE_DIRECT
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_CONNECTING_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_OPPONENT
bne UPDATE_WAITING

addi r5, REG_TEXT_PROPERTIES, TPO_STRING_CONNECTING_TO
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_OPP_CODE
b UPDATE_WAITING

UPDATE_WAITING_WITH_OPPONENT:
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_WAITING_ON
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_OPPONENT

UPDATE_WAITING:
bl FN_UPDATE_TEXT

li r3, 1
stb r3, CSSDT_SPINNER3(REG_CSSDT_ADDR)

UPDATE_LINES_EXIT:

################################################################################
# Set up spinners
################################################################################
.set REG_SPINNER_OFST, REG_VARIOUS_1
li REG_SPINNER_OFST, CSSDT_SPINNER1
li REG_SUBTEXT_IDX, STIDX_SPINNER1

LOOP_SPINNER_SETUP_START:
lbzx r3, REG_CSSDT_ADDR, REG_SPINNER_OFST
cmpwi r3, 1
bne LOOP_SPINNER_CHECK_COMPLETE

# Calculate the offset for spinner string
lhz r3, CSSDT_FRAME_COUNTER(REG_CSSDT_ADDR)
li r4, SPINNER_TRANSITION_FRAMES
divwu r3, r3, r4
mulli r3, r3, SPINNER_ICON_LEN
addi r3, r3, TPO_STRING_SPINNER_1

add r5, REG_TEXT_PROPERTIES, r3
mr r4, REG_SUBTEXT_IDX
bl FN_UPDATE_TEXT

mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_SPINNER_WAITING_COLOR
branchl r12, Text_ChangeTextColor

b LOOP_SPINNER_CONTINUE

LOOP_SPINNER_CHECK_COMPLETE:
cmpwi r3, 2
bne LOOP_SPINNER_DEFAULT_CASE

mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_SPINNER_DONE
bl FN_UPDATE_TEXT

mr r3, REG_TEXT_STRUCT
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_SPINNER_DONE_COLOR
branchl r12, Text_ChangeTextColor

b LOOP_SPINNER_CONTINUE

LOOP_SPINNER_DEFAULT_CASE:
mr r4, REG_SUBTEXT_IDX
addi r5, REG_TEXT_PROPERTIES, TPO_EMPTY_STRING
bl FN_UPDATE_TEXT

LOOP_SPINNER_CONTINUE:
addi REG_SUBTEXT_IDX, REG_SUBTEXT_IDX, LINE_IDX_GAP
addi REG_SPINNER_OFST, REG_SPINNER_OFST, 1
cmpwi REG_SPINNER_OFST, CSSDT_SPINNER3
ble LOOP_SPINNER_SETUP_START

################################################################################
# Update frame counter
################################################################################
lhz r3, CSSDT_FRAME_COUNTER(REG_CSSDT_ADDR)
addi r3, r3, 1
cmpwi r3, FRAME_MAX
blt SKIP_FRAME_ADJUSTMENT

li r3, 0
SKIP_FRAME_ADJUSTMENT:
sth r3, CSSDT_FRAME_COUNTER(REG_CSSDT_ADDR)

restore
blr

################################################################################
# CHAT MSG THINK Function: Looping function to keep on
# updating the text until timer runs out
################################################################################
CSS_ONLINE_CHAT_THINK:
blrl
mr REG_CHATMSG_GOBJ, r3 # Store GOBJ pointer
backup

# INIT PROPERTIES
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

# get gobj and get values for each of the data buffer
lwz REG_CHATMSG_GOBJ_DATA_ADDR, CHAT_ENTITY_DATA_OFFSET(REG_CHATMSG_GOBJ) # get address of data buffer
lbz REG_CHATMSG_TIMER, CSSCMDT_TIMER(REG_CHATMSG_GOBJ_DATA_ADDR)
lbz REG_CHATMSG_MSG_ID, CSSCMDT_MSG_ID(REG_CHATMSG_GOBJ_DATA_ADDR)
lbz REG_CHATMSG_MSG_INDEX, CSSCMDT_MSG_INDEX(REG_CHATMSG_GOBJ_DATA_ADDR)
lwz REG_CHATMSG_MSG_TEXT_STRUCT_ADDR, CSSCMDT_MSG_TEXT_STRUCT_ADDR(REG_CHATMSG_GOBJ_DATA_ADDR)
lwz REG_CHATMSG_USER_NAME_ADDR, CSSCMDT_USER_NAME_ADDR(REG_CHATMSG_GOBJ_DATA_ADDR)
lwz REG_CSSDT_ADDR, CSSCMDT_CSSDT_ADDR(REG_CHATMSG_GOBJ_DATA_ADDR)

# if text is not initialized, do it and move to next frame
cmpwi REG_CHATMSG_MSG_TEXT_STRUCT_ADDR, 0x00000000
bne CSS_ONLINE_CHAT_CHECK_MAX_MESSAGES # already has values means that is set so skip to timer check

##### BEGIN: INITIALIZING CHAT MSG TEXT ###########

# Change Text Struct Descriptor to use a higher GX
lwz	r3, textStructDescriptorBuffer(r13) # Text Struct Descriptor
li r4, 3 # gx_link we want
stb r4, 0xE(r3)
load r3, 0x80bd5c6c

# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_CHATMSG_MSG_TEXT_STRUCT_ADDR, r3
stw REG_CHATMSG_MSG_TEXT_STRUCT_ADDR, CSSCMDT_MSG_TEXT_STRUCT_ADDR(REG_CHATMSG_GOBJ_DATA_ADDR)

# Restore Text Struct descriptor
lwz	r3, textStructDescriptorBuffer(r13) # Text Struct Descriptor
li r4, 1 # original gx_link to restore
stb r4, 0xE(r3)

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_CHATMSG_MSG_TEXT_STRUCT_ADDR)
# Set text to align left
li r4, 0x0
stb r4, 0x4A(REG_CHATMSG_MSG_TEXT_STRUCT_ADDR)

# Store Base Z Offset
lfs f1, TPO_CHATMSG_Z(REG_TEXT_PROPERTIES) #Z offset
stfs f1, 0x8(REG_CHATMSG_MSG_TEXT_STRUCT_ADDR)

# Scale Canvas Down
lfs f1, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES)
stfs f1, 0x24(REG_CHATMSG_MSG_TEXT_STRUCT_ADDR)
stfs f1, 0x28(REG_CHATMSG_MSG_TEXT_STRUCT_ADDR)

# INIT MSG Properties based on input button (lowest bit)
mr r3, REG_CHATMSG_MSG_ID
li r4, 4
srw r3, r3, r4

cmpwi r3, PAD_UP
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_UP_CHAT_TEXT_PROPERTIES
cmpwi r3, PAD_DOWN
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_DOWN_CHAT_TEXT_PROPERTIES
cmpwi r3, PAD_RIGHT
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_RIGHT_CHAT_TEXT_PROPERTIES
cmpwi r3, PAD_LEFT
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_LEFT_CHAT_TEXT_PROPERTIES


CSS_ONLINE_CHAT_WINDOW_THINK_INIT_UP_CHAT_TEXT_PROPERTIES:
bl UP_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_DOWN_CHAT_TEXT_PROPERTIES:
bl DOWN_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_RIGHT_CHAT_TEXT_PROPERTIES:
bl RIGHT_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_LEFT_CHAT_TEXT_PROPERTIES:
bl LEFT_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END:

# get message input (highest bit)
mr r3, REG_CHATMSG_MSG_ID
li r4, 4
srw r3, r3, r4 # shift right = 0x0N
slw r3, r3, r4 # shift left = 0xN0
sub r3, REG_CHATMSG_MSG_ID, r3

# calculate address of label
cmpwi r3, PAD_UP # up
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_UP_LABEL_ADDR
cmpwi r3, PAD_LEFT # left
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_LEFT_LABEL_ADDR
cmpwi r3, PAD_RIGHT # right
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_RIGHT_LABEL_ADDR
cmpwi r3, PAD_DOWN # down
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_DOWN_LABEL_ADDR

CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_UP_LABEL_ADDR:
addi r4, REG_CHAT_TEXT_PROPERTIES, TPO_STRING_MSG_UP # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_LEFT_LABEL_ADDR:
addi r4, REG_CHAT_TEXT_PROPERTIES, TPO_STRING_MSG_LEFT # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_RIGHT_LABEL_ADDR:
addi r4, REG_CHAT_TEXT_PROPERTIES, TPO_STRING_MSG_RIGHT # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_DOWN_LABEL_ADDR:
addi r4, REG_CHAT_TEXT_PROPERTIES, TPO_STRING_MSG_DOWN # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END

addi r4, REG_CHAT_TEXT_PROPERTIES, TPO_EMPTY_STRING # set empty string by default
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END:


SET_CHATMSG_TEXT_HEADER:
mr REG_CHATMSG_MSG_STRING_ADDR, r4 # store current string pointer

# calculate float locations for message
mr r3,REG_CHATMSG_MSG_INDEX # convert message index to float
branchl r12, FN_IntToFloat # returns f1

# calculate Y offset based on message index
lfs f4, TPO_CHATMSG_SIZE_MARGIN(REG_TEXT_PROPERTIES) # distance between message
fmuls f1, f1, f4 # multiply index by margin
fmr f3, f1 # store our desired Y offset in f3

# load X+Y Starting position of text
lfs f1, TPO_CHATMSG_X(REG_TEXT_PROPERTIES)
lfs f2, TPO_CHATMSG_Y(REG_TEXT_PROPERTIES)

fadds f2, f2, f3 # add the offset
fmr REG_CHATMSG_TEXT_X_POS, f1 # store current position to reuse them
fmr REG_CHATMSG_TEXT_Y_POS, f2 # store current position to reuse them


# Create Outlined subtext
mr r3, REG_CHATMSG_MSG_TEXT_STRUCT_ADDR # text struct pointer
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_CHAT # text color
li r5, 1 # outline text
addi r6, REG_TEXT_PROPERTIES, TPO_COLOR_CHAT_BG # color outline
addi r7, REG_TEXT_PROPERTIES, TPO_STRING_CHATMSG_FORMAT # concatenate user name with message "User: Message"
mr r8, REG_CHATMSG_USER_NAME_ADDR # User name
mr r9, REG_CHATMSG_MSG_STRING_ADDR # Message
lfs f1, TPO_CHATMSG_SIZE(REG_TEXT_PROPERTIES) # chat message scale
lfs f2, TPO_CHATMSG_SIZE(REG_TEXT_PROPERTIES) # chat message scale
fmr f3, REG_CHATMSG_TEXT_X_POS # x pos
fmr f4, REG_CHATMSG_TEXT_Y_POS # y pos
lfs f5, TPO_CHATMSG_SIZE_SM(REG_TEXT_PROPERTIES) # chat message scale
lfs f6, TPO_CHATMSG_OUTLINE_OFFSET(REG_TEXT_PROPERTIES) # chat message scale

branchl r12, FG_CreateSubtext

##### END: INITIALIZING CHAT MSG TEXT ###########

CSS_ONLINE_CHAT_CHECK_MAX_MESSAGES:
lbz r3, CSSDT_CHAT_MSG_COUNT(REG_CSSDT_ADDR) # 4
cmpwi r3, MAX_CHAT_MESSAGES
blt CSS_ONLINE_CHAT_CHECK_TIMER

# if last chat message index is 0 and my index is max - 1 (if messages are rotating on the top again)
lbz r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # chat message index
cmpw r3, REG_CHATMSG_MSG_INDEX
bge CSS_ONLINE_CHAT_CHECK_MAX_MESSAGES_SKIP_TOP_ROTATION

cmpwi REG_CHATMSG_MSG_INDEX, MAX_CHAT_MESSAGE_LINES
ble CSS_ONLINE_CHAT_REMOVE_PROC

CSS_ONLINE_CHAT_CHECK_MAX_MESSAGES_SKIP_TOP_ROTATION:
lbz r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # chat message index
sub r3, r3, REG_CHATMSG_MSG_INDEX
cmpwi r3, MAX_CHAT_MESSAGES
bgt CSS_ONLINE_CHAT_REMOVE_PROC

CSS_ONLINE_CHAT_CHECK_TIMER:

# check timer and decrease until is 0
cmpwi REG_CHATMSG_TIMER, 0
beq CSS_ONLINE_CHAT_REMOVE_PROC # if timer is 0, then exit and delete think func.

subi REG_CHATMSG_TIMER, REG_CHATMSG_TIMER, 1
stb REG_CHATMSG_TIMER, CSSCMDT_TIMER(REG_CHATMSG_GOBJ_DATA_ADDR)

b CSS_ONLINE_CHAT_CHECK_EXIT

CSS_ONLINE_CHAT_REMOVE_PROC: # TODO: is this the proper way to delete this proc?

# remove proc
mr r3, REG_CHATMSG_GOBJ
branchl r12, GObj_RemoveProc

# destroy gobj
mr r3, REG_CHATMSG_GOBJ
branchl r12, GObj_Destroy

# remove text
mr r3, REG_CHATMSG_MSG_TEXT_STRUCT_ADDR
branchl r12, Text_RemoveText

# Decrease chat message count by 1
lbz r3, CSSDT_CHAT_MSG_COUNT(REG_CSSDT_ADDR) # chat message index
subi r3, r3, 1
stb r3, CSSDT_CHAT_MSG_COUNT(REG_CSSDT_ADDR) # store the new message count

# If This is the last message being removed, reset the Last MSG Index to 0
lbz r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # chat message index
mr r4, REG_CHATMSG_MSG_INDEX
addi r4, r4, 1 # compare with last index + 1
cmpw r3, r4
beq CSS_ONLINE_CHAT_RESET_MSG_INDEX
b CSS_ONLINE_CHAT_CHECK_EXIT

CSS_ONLINE_CHAT_RESET_MSG_INDEX:
li r3, 0
stb r3, CSSDT_LAST_CHAT_MSG_INDEX(REG_CSSDT_ADDR) # store the new message index

CSS_ONLINE_CHAT_CHECK_EXIT:
restore
blr


################################################################################
# Update subtext function for use only by think function
# Will set r3 to REG_TEXT_STRUCT. Expects caller to set other args
################################################################################
FN_UPDATE_TEXT:
mflr REG_LR # Single depth helper function. Non-standard

mr r3, REG_TEXT_STRUCT
branchl r12, Text_UpdateSubtextContents

mtlr REG_LR
blr


EXIT:
lwz	r6, -0x49C8(r13)
