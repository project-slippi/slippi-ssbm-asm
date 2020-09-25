.include "Common/Common.s"
################################################################################
# Address: FG_CreateSubtext # 0x800056b4
################################################################################
# Inputs:
# r9 = Function to call and possible values:
# 0: Create Subtext
# 1: Create Concatenated Subtext
# 2: Create Subtext with outlines
# 3: Create Concatenated Subtext with outlines
################################################################################

# gp registers
.set REG_TEXT_STRUCT_ADDR, 21
.set REG_STRING_FORMAT_ADDR, REG_TEXT_STRUCT_ADDR+1
.set REG_STRING_1_ADDR, REG_STRING_FORMAT_ADDR+1
.set REG_STRING_2_ADDR, REG_STRING_1_ADDR+1
.set REG_STRING_3_ADDR, REG_STRING_2_ADDR+1
.set REG_COLOR_ADDR, REG_STRING_3_ADDR+1
.set REG_SUBTEXT_INDEX, REG_COLOR_ADDR+1
.set REG_CONCATENATE, REG_SUBTEXT_INDEX+1
.set REG_OUTLINE_COLOR_ADDR, REG_CONCATENATE+1
# float registers
.set REG_SCALE_X, REG_TEXT_STRUCT_ADDR
.set REG_SCALE_Y, REG_SCALE_X+1
.set REG_X, REG_SCALE_Y+1
.set REG_Y, REG_X+1
.set REG_OUTLINE_SIZE, REG_Y+1
.set REG_OUTLINE_OFFSET, REG_OUTLINE_SIZE+1 # outlines offsets to create size

.set REG_LOOP_INDEX, 15
.set TEXT_LAST_INDEX, 2



################################################################################
# Address: FN_CREATE_SUBTEXT
################################################################################
# Inputs:
# r3 = text struct pointer
# r4 = color pointer
# r5 = string pointer
# r6-r8 = string pointers (to concatenate)
# r9 = 0: do not concatenate, 1: concatenate, 2: outlines no concat 3: outlines + concat,
# r10 = outline color pointer
# f1 = scale size x
# f2 = scale size y
# f3 = x pos
# f4 = y pos
# f5 = inner text y-scale
# f6 = outline offset/size
################################################################################
# Output:
# r3 - Subtext Index
################################################################################
# Description:
# Creates and initalizes a subtext (also supports concatenation + outlines via args)
################################################################################
FN_CREATE_SUBTEXT:
backup

# Save arguments
mr REG_TEXT_STRUCT_ADDR, r3
mr REG_COLOR_ADDR, r4
mr REG_STRING_FORMAT_ADDR, r5
mr REG_STRING_1_ADDR, r6
mr REG_STRING_2_ADDR, r7
mr REG_STRING_3_ADDR, r8
mr REG_CONCATENATE, r9
mr REG_OUTLINE_COLOR_ADDR, r10

fmr REG_SCALE_X, f1
fmr REG_SCALE_Y, f2
fmr REG_X, f3
fmr REG_Y, f4
fmr REG_OUTLINE_SIZE, f5
fmr REG_OUTLINE_OFFSET, f6

# Choose if we are creating outlines or not
cmpwi REG_CONCATENATE, 2
blt INIT_SINGLE_TEXT_START

INIT_OUTLINED_TEXT_START:
li REG_LOOP_INDEX, 0 # subindex start
TEXT_LOOP_START:

# Get X+Y Position
fmr f1, REG_X
fmr f2, REG_Y

# Move X+Y positions if is an outline
cmpwi REG_LOOP_INDEX, 0 # left outline
beq TEXT_LOOP_SHIFT_OUTLINE_LEFT
cmpwi REG_LOOP_INDEX, 1 # right outline
beq TEXT_LOOP_SHIFT_OUTLINE_RIGHT
cmpwi REG_LOOP_INDEX, 2 # top outline
beq TEXT_LOOP_SHIFT_OUTLINE_TOP
#cmpwi REG_LOOP_INDEX, 3 # bottom outline
#beq TEXT_LOOP_SHIFT_OUTLINE_TOP
#beq TEXT_LOOP_SHIFT_OUTLINE_BOTTOM
b TEXT_LOOP_INITIALIZE_SUBTEXT

TEXT_LOOP_SHIFT_OUTLINE_LEFT:
fsubs f1,f1,REG_OUTLINE_OFFSET # shift left
b TEXT_LOOP_INITIALIZE_SUBTEXT
TEXT_LOOP_SHIFT_OUTLINE_RIGHT:
fadds f1,f1,REG_OUTLINE_OFFSET  # shift right
b TEXT_LOOP_INITIALIZE_SUBTEXT
TEXT_LOOP_SHIFT_OUTLINE_TOP:
fsubs f2,f2,REG_OUTLINE_OFFSET # shift up
b TEXT_LOOP_INITIALIZE_SUBTEXT
TEXT_LOOP_SHIFT_OUTLINE_BOTTOM:
fadds f2,f2,REG_OUTLINE_OFFSET  # shift down
b TEXT_LOOP_INITIALIZE_SUBTEXT

TEXT_LOOP_INITIALIZE_SUBTEXT:
# Initialize subtext
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_STRING_FORMAT_ADDR
branchl r12, Text_InitializeSubtext
mr REG_SUBTEXT_INDEX, r3 # SubText Index

# Set Text Size
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
fmr f1, REG_SCALE_X
fmr f2, REG_SCALE_Y

# If reached last index, scale y down
cmpwi REG_LOOP_INDEX, TEXT_LAST_INDEX
bne TEXT_LOOP_INITIALIZE_SUBTEXT_SCALE_SET
fmr f2, REG_OUTLINE_SIZE

TEXT_LOOP_INITIALIZE_SUBTEXT_SCALE_SET:
branchl r12, Text_UpdateSubtextSize

# Set Color to white only if SubText Index is last
mr r5, REG_OUTLINE_COLOR_ADDR
cmpwi REG_LOOP_INDEX, TEXT_LAST_INDEX
bne TEXT_LOOP_SET_COLOR
mr r5, REG_COLOR_ADDR

TEXT_LOOP_SET_COLOR:
# Set Text Color
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX # Subtext Index
branchl r12, Text_ChangeTextColor

# concatenate user name with message "User: Message"
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
mr r5, REG_STRING_FORMAT_ADDR
mr r6, REG_STRING_1_ADDR
mr r7, REG_STRING_2_ADDR
mr r8, REG_STRING_3_ADDR
branchl r12, Text_UpdateSubtextContents

# if reached last index, then end the loop, else increment and go back
cmpwi REG_LOOP_INDEX, TEXT_LAST_INDEX
beq TEXT_LOOP_END

# Increment Index and start again
addi REG_LOOP_INDEX, REG_LOOP_INDEX, 1
b TEXT_LOOP_START

TEXT_LOOP_END:


INIT_OUTLINED_TEXT_END:
b FN_CREATE_SUBTEXT_END
INIT_SINGLE_TEXT_START:
# Initialize subtext
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_STRING_FORMAT_ADDR
fmr f1, REG_X
fmr f2, REG_Y
branchl r12, Text_InitializeSubtext
mr REG_SUBTEXT_INDEX, r3

# Set Text Size
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
fmr f1, REG_SCALE_X
fmr f2, REG_SCALE_Y
branchl r12, Text_UpdateSubtextSize

# Set Text Color
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
mr r5, REG_COLOR_ADDR
branchl r12, Text_ChangeTextColor

# Only set concatenated text if flag is set to 1
cmpwi REG_CONCATENATE, 0
beq FN_CREATE_SUBTEXT_END

FN_CREATE_SUBTEXT_UPDATE_TEXT:
# Concatenate user name with message "User: Message"
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
mr r5, REG_STRING_FORMAT_ADDR
mr r6, REG_STRING_1_ADDR
mr r7, REG_STRING_2_ADDR
mr r8, REG_STRING_3_ADDR
branchl r12, Text_UpdateSubtextContents

INIT_SINGLE_TEXT_END:
FN_CREATE_SUBTEXT_END:

# Return subtext index
mr r3, REG_SUBTEXT_INDEX
restore
blr

