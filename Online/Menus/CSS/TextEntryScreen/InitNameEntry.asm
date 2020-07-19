################################################################################
# Address: 0x8023e994
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

b CODE_START

DATA_BLRL:
blrl
# Base Text Properties
.set DOFST_TEXT_BASE_Z, 0
.float 17
.set DOFST_TEXT_BASE_CANVAS_SCALING, DOFST_TEXT_BASE_Z + 4
.float 0.0665

# Line Text Properties
.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float -144
.set DOFST_TEXT_Y_POS_LINE1, DOFST_TEXT_X_POS + 4
.float 114
.set DOFST_TEXT_Y_POS_LINE2, DOFST_TEXT_Y_POS_LINE1 + 4
.float 125
.set DOFST_TEXT_OPP_STR_X_POS, DOFST_TEXT_Y_POS_LINE2 + 4
.float -71.5
.set DOFST_TEXT_FONT_SIZE, DOFST_TEXT_OPP_STR_X_POS + 4
.float 0.35
.set DOFST_TEXT_X_POS_LTRIG, DOFST_TEXT_FONT_SIZE + 4
.float -165
.set DOFST_TEXT_Y_POS_LTRIG, DOFST_TEXT_X_POS_LTRIG + 4
.float -130
.set DOFST_TEXT_X_POS_RTRIG, DOFST_TEXT_Y_POS_LTRIG + 4
.float 60
.set DOFST_TEXT_TRIG_FONT_SIZE, DOFST_TEXT_X_POS_RTRIG + 4
.float 0.70
.set DOFST_TEXT_X_POS_L_ARROW, DOFST_TEXT_TRIG_FONT_SIZE + 4 
.float -167
.set DOFST_TEXT_X_POS_R_ARROW, DOFST_TEXT_X_POS_L_ARROW + 4
.float 58
.set DOFST_TEXT_Y_POS_LR_ARROW, DOFST_TEXT_X_POS_R_ARROW + 4
.float -118
.set DOFST_TEXT_HIGHLIGHT_COLOR, DOFST_TEXT_Y_POS_LR_ARROW + 4
.long 0xFFCB00FF
.set DOFST_TEXT_NOT_SELECTED_COLOR, DOFST_TEXT_HIGHLIGHT_COLOR + 4
.long 0x8E9196FF 

# Line Text Strings
.set DOFST_TEXT_STRING_LINE1, DOFST_TEXT_NOT_SELECTED_COLOR + 4
.string "Enter your %s above."
.set DOFST_TEXT_STRING_LINE2, DOFST_TEXT_STRING_LINE1 + 21
.string "Your opponent will also need to enter yours"
.set DOFST_TEXT_STRING_LTRIG, DOFST_TEXT_STRING_LINE2 + 44
.string "L"
.set DOFST_TEXT_STRING_ARROW_LEFT, DOFST_TEXT_STRING_LTRIG + 2 
.short 0x8183
.short 0x817c
.byte 0x00
.set DOFST_TEXT_STRING_RTRIG, DOFST_TEXT_STRING_ARROW_LEFT + 5
.string "R"
.set DOFST_TEXT_STRING_ARROW_RIGHT, DOFST_TEXT_STRING_RTRIG + 2
.short 0x817c
.short 0x8184
.byte 0x00
.set DOFST_TEXT_STRING_OPP_CONNECT_CODE, DOFST_TEXT_STRING_ARROW_RIGHT + 5
.string "opponent's connect code"
.align 2

################################################################################
# Initialize instruction text
################################################################################
.set REG_DATA_ADDR, 31
.set REG_TEXT_STRUCT, 30

CODE_START:
backup

bl DATA_BLRL
mflr REG_DATA_ADDR

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
lfs f1, DOFST_TEXT_BASE_Z(REG_DATA_ADDR) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, DOFST_TEXT_BASE_CANVAS_SCALING(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Initialize Line 1
lfs f1, DOFST_TEXT_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LINE1(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_LINE1
addi r5, REG_DATA_ADDR, DOFST_TEXT_STRING_OPP_CONNECT_CODE
branchl r12, Text_InitializeSubtext

# Set Line 1 text size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# Initialize Line 2
lfs f1, DOFST_TEXT_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LINE2(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_LINE2
branchl r12, Text_InitializeSubtext

# Set Line 2 text size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# Initialize highlight text
lfs f1, DOFST_TEXT_OPP_STR_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LINE1(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_OPP_CONNECT_CODE
branchl r12, Text_InitializeSubtext

# Set highlight text size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# Set port label color
mr r3, REG_TEXT_STRUCT
li r4, 2
addi r5, REG_DATA_ADDR, DOFST_TEXT_HIGHLIGHT_COLOR
branchl r12, Text_ChangeTextColor

# Initialize LTrig 
lfs f1, DOFST_TEXT_X_POS_LTRIG(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LTRIG(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_LTRIG
branchl r12, Text_InitializeSubtext

# Set LTrig text size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_TRIG_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_TRIG_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# TODO: Finish implementing me.
# mr r3, REG_TEXT_STRUCT
# li r4, 3
# addi r5, REG_DATA_ADDR, DOFST_TEXT_NOT_SELECTED_COLOR
# branchl r12, Text_ChangeTextColor

# Initialize RTrig 
lfs f1, DOFST_TEXT_X_POS_RTRIG(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LTRIG(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_RTRIG
branchl r12, Text_InitializeSubtext

# Set RTrig text size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_TRIG_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_TRIG_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# Right Arrow init
lfs f1, DOFST_TEXT_X_POS_R_ARROW(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LR_ARROW(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_ARROW_RIGHT
branchl r12, Text_InitializeSubtext

# Right arrow size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# Left Arrow init
lfs f1, DOFST_TEXT_X_POS_L_ARROW(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS_LR_ARROW(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING_ARROW_LEFT
branchl r12, Text_InitializeSubtext

# Left arrow size
mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_FONT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# TODO: Finish implementing me
# mr r3, REG_TEXT_STRUCT
# li r4, 6
# addi r5, REG_DATA_ADDR, DOFST_TEXT_NOT_SELECTED_COLOR
# branchl r12, Text_ChangeTextColor


restore

EXIT:
li r3, 0
