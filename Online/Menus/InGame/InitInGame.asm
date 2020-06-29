################################################################################
# Address: 0x8016e9b4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_ODB_ADDRESS, 31
.set REG_TEXT_STRUCT, 30
.set REG_DATA_ADDR, 29
.set REG_STRING_BUF, 28
.set REG_MSRB_ADDR,27

# Ensure that this is an online in-game
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT # If not online in game

b CODE_START

.set STRING_BUF_LEN, 14

DATA_BLRL:
blrl
.set DOFST_TEXT_BASE_Z, 0
.float 0
.set DOFST_TEXT_BASE_CANVAS_SCALING, DOFST_TEXT_BASE_Z + 4
.float 1

# delay values
.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float 605
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float 415
.set DOFST_TEXT_SIZE, DOFST_TEXT_Y_POS + 4
.float 0.5

# player text values
.set DOFST_PLAYERTEXT_X_POS, DOFST_TEXT_SIZE + 4
.float 605
.set DOFST_PLAYERTEXT_Y_POS, DOFST_PLAYERTEXT_X_POS + 4
.float 437
.set DOFST_PLAYERTEXT_SIZE, DOFST_PLAYERTEXT_Y_POS + 4
.float 0.5

# player text center calculation (HUDX * 11) + 330
.set DOFST_HUDPOS_MULT, DOFST_PLAYERTEXT_SIZE + 4
.float 11
.set DOFST_HUDPOS_OFFSET, DOFST_HUDPOS_MULT + 4
.float 330


# BG values
.set DOFST_PLAYERBG_OPA, DOFST_HUDPOS_OFFSET + 4
.float 0.4
.set DOFST_PLAYERBG_COLOR, DOFST_PLAYERBG_OPA + 4
.byte 0,0,0,255
.set DOFST_PLAYERBG_SCALEBASE, DOFST_PLAYERBG_COLOR + 4
.float 12
.set DOFST_PLAYERBG_SCALEMULT, DOFST_PLAYERBG_SCALEBASE + 4
.float 2.3
.set DOFST_PLAYERBG_YSCALE, DOFST_PLAYERBG_SCALEMULT + 4
.float 10
.set DOFST_PLAYERBG_YOFST, DOFST_PLAYERBG_YSCALE + 4
.float -493.5
# BG scale per letter
.set DOFST_PLAYERBG_XSCALEBASE, DOFST_PLAYERBG_YOFST + 4
.float 0.4
.set DOFST_PLAYERBG_XSCALEMULT, DOFST_PLAYERBG_XSCALEBASE + 4
.float 0.25


# strings
.set DOFST_TEXT_FORMATSTRING, DOFST_PLAYERBG_XSCALEMULT + 4
.string "%s"
.align 2
.set DOFST_TEXT_DELAYSTRING, DOFST_TEXT_FORMATSTRING + 4
.string "Delay: %df"
.align 2

CODE_START:
backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

bl DATA_BLRL
mflr REG_DATA_ADDR

# Aspect Scalar
lfs f3,DOFST_PLAYERBG_XSCALEBASE (REG_DATA_ADDR)
load  r3,0x804ddb84
lfs f2,0x0(r3)
fdivs f1,f2,f3
stfs  f1,0x7C(sp)

# Get player names
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Start prepping text struct
li r3, 2
lwz r4, -0x4924 (r13) # Same canvas as nametags
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align right
li r4, 0x2
stb r4, 0x4A(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, DOFST_TEXT_BASE_Z(REG_DATA_ADDR) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, DOFST_TEXT_BASE_CANVAS_SCALING(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Initialize header
lfs f1, DOFST_TEXT_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_DELAYSTRING
lbz r5, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
branchl r12, Text_InitializeSubtext

# Set header text size
mr r3, REG_TEXT_STRUCT
li r4, 0
# Scale text X based on Aspect Ratio
lfs  f2,0x7C(sp)
lfs f1, DOFST_TEXT_SIZE(REG_DATA_ADDR)
fmuls f1,f1,f2
lfs f2, DOFST_TEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

##########################
## Display Player Names ##
##########################

# Start prepping text struct
li r3, 2
lwz r4, -0x4924 (r13) # Same canvas as nametags
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align center
li r4, 0x1
stb r4, 0x4A(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, DOFST_TEXT_BASE_Z(REG_DATA_ADDR) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, DOFST_TEXT_BASE_CANVAS_SCALING(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Display all player names
.set REG_COUNT, 20
.set REG_HUDPOS, 21
.set REG_BG_JOBJ, 22
.set REG_SUBTEXT, 23
.set REG_BG_GOBJ, 24
li  REG_COUNT, 0
load REG_HUDPOS, 0x804a0ff0
DISPLAY_NAME_LOOP:
#Check if player exists
mr  r3, REG_COUNT
branchl r12, 0x8003241c
cmpwi r3, 3
beq DISPLAY_NAME_INC_LOOP

#Create gobj
li  r3,14
li  r4,15
li  r5,0
branchl r12,0x803901f0
mr  REG_BG_GOBJ,r3
#Create Background
load  r3,0x804a1ed0
lwz r3,0x0(r3)
branchl r12,0x80370e44
mr  REG_BG_JOBJ,r3
# Add as object
mr  r3,REG_BG_GOBJ
lbz	r4, -0x3E57 (r13)
mr  r5,REG_BG_JOBJ
branchl r12,0x80390a70
# Add GX Link
mr  r3,REG_BG_GOBJ
load  r4,0x80391070
li  r5,9
li  r6,0
branchl r12,0x8039069c

#############################
## Create Player Name Text ##
#############################

#Get HUD Position
mulli r3,REG_COUNT,0xC
add r3,r3,REG_HUDPOS
# Set text
lfs f1, 0x0(r3)
lfs f2,DOFST_HUDPOS_MULT(REG_DATA_ADDR)
# Scale Text X Position based on Aspect Ratio
lfs  f3,0x7C(sp)
fmuls f2,f2,f3
fmuls f1,f1,f2
lfs f2,DOFST_HUDPOS_OFFSET(REG_DATA_ADDR)
fadds f1,f1,f2
lfs f2, DOFST_PLAYERTEXT_Y_POS(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_MSRB_ADDR, MSRB_P1_NAME
mulli r5, REG_COUNT, 31
add r4,r4,r5
branchl r12, Text_InitializeSubtext
mr  REG_SUBTEXT,r3
# Scale text X based on Aspect Ratio
lfs  f1,0x7C(sp)
lfs f2, DOFST_PLAYERTEXT_SIZE(REG_DATA_ADDR)
fmuls f1,f1,f2
# Set size
mr r3, REG_TEXT_STRUCT
mr  r4,REG_SUBTEXT
lfs f2, DOFST_PLAYERTEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize


############################
## Create Text Background ##
############################

# Get HUD pos
mr  r3,REG_COUNT
branchl r12,0x802f3424
# Set bg position
lfs f1,0x0 (r3)
lfs f2, DOFST_HUDPOS_MULT (REG_DATA_ADDR)
# Scale BG X Position based on Aspect Ratio
lfs  f3,0x7C(sp)
fmuls f2,f2,f3
fmuls f1,f1,f2
lfs f2, DOFST_HUDPOS_OFFSET (REG_DATA_ADDR)
fadds f1,f1,f2
stfs  f1,0x38 (REG_BG_JOBJ)
lfs f1, DOFST_PLAYERBG_YOFST (REG_DATA_ADDR)
stfs  f1,0x3C (REG_BG_JOBJ)
# Adjust scale
lfs f1, DOFST_PLAYERBG_YSCALE (REG_DATA_ADDR)
stfs f1, 0x30 (REG_BG_JOBJ)
# Remove unneccessary dobjs
mr  r3,REG_BG_JOBJ
addi  r4,sp,0x80
li  r5,1
li  r6,-1
branchl r12,0x80011e24
# Add as child to Percent JOBJ
lwz r3,0x80(sp)
lwz r3,0x18(r3)  #first dobj
lwz r4,0x14(r3)
ori r4,r4,0x1
stw r4,0x14(r3)
lwz r3,0x4(r3)  #next dobj
lwz r4,0x14(r3)
ori r4,r4,0x1
stw r4,0x14(r3)
# Adjust opacity of BG
lwz r3,0x4(r3)  #next dobj
lwz r3,0x8(r3)  #mobj
lwz r3,0xC(r3)  #material
lfs f1, DOFST_PLAYERBG_OPA (REG_DATA_ADDR)
stfs f1, 0xC(r3)
# Adjust color of BG
lwz r4, DOFST_PLAYERBG_COLOR (REG_DATA_ADDR)
stw r4, 0x4(r3)


# Get total width of characters used in tag
.set  CHAR_WIDTH_MAX, 17
.set  TAG_WIDTH_MIN, 50
.set  REG_WIDTH, 25
.set  REG_CURR, 26
.set  REG_WIDTH_INTERNAL, 12
.set  REG_WIDTH_EXTERNAL, 11
li  REG_WIDTH,0
# Get subtext contents
lwz  r3,0x5C(REG_TEXT_STRUCT)
mr  r4,REG_SUBTEXT
branchl r12,0x803a6fec
addi  REG_CURR, r3, 0xE   #skip past header
load REG_WIDTH_INTERNAL, 0x8040cb00
lbz r3,0x4F(REG_TEXT_STRUCT)
mulli r3,r3,4
load  r4,0x804d1124
lwzx  r3, r3, r4
lwz REG_WIDTH_EXTERNAL, 0x4 (r3)
DISPLAY_NAME_COUNT_LOOP:
lbz r3,0x0(REG_CURR)
# Check if null character
cmpwi r3,0x0B
beq DISPLAY_NAME_COUNT_NULL
# Check if internal character
cmpwi r3,0x20
beq DISPLAY_NAME_COUNT_INTERNAL
# Check if external character
cmpwi r3,0x40
beq DISPLAY_NAME_COUNT_EXTERNAL
# Check if end of text
lbz r3,0x0(REG_CURR)
cmpwi r3,0x0F
beq DISPLAY_NAME_COUNT_EXIT
b DISPLAY_NAME_COUNT_NULL

DISPLAY_NAME_COUNT_INTERNAL:
lbz r3,0x1(REG_CURR)
mulli r3,r3,2
lbzx  r3,r3,REG_WIDTH_INTERNAL
li  r4,CHAR_WIDTH_MAX
sub r3,r4,r3
add  REG_WIDTH,REG_WIDTH,r3
addi  REG_CURR,REG_CURR,2
b DISPLAY_NAME_COUNT_LOOP
DISPLAY_NAME_COUNT_EXTERNAL:
lbz r3,0x1(REG_CURR)
mulli r3,r3,2
lbzx  r3,r3,REG_WIDTH_EXTERNAL
li  r4,CHAR_WIDTH_MAX
sub r3,r4,r3
add  REG_WIDTH,REG_WIDTH,r3
addi  REG_CURR,REG_CURR,2
b DISPLAY_NAME_COUNT_LOOP

DISPLAY_NAME_COUNT_NULL:
addi  REG_CURR,REG_CURR,1
b DISPLAY_NAME_COUNT_LOOP
DISPLAY_NAME_COUNT_EXIT:

# Check if tag is min width
cmpwi REG_WIDTH, TAG_WIDTH_MIN
bge 0x8
li  REG_WIDTH, TAG_WIDTH_MIN
# Cast to float
lis	r0, 0x4330
lfd	f2, -0x6758 (rtoc)
xoris	r3, REG_WIDTH,0x8000
stw	r0,0x80(sp)
stw	r3,0x84(sp)
lfd	f1,0x80(sp)
fsubs	f1,f1,f2		#Convert To Float
# Multiply width by X to get background size
lfs f2, DOFST_PLAYERBG_XSCALEMULT (REG_DATA_ADDR)
fmuls f1,f1,f2
stfs f1, 0x2C (REG_BG_JOBJ)

# Scale BG X based on Aspect Ratio
lfs  f1,0x7C(sp)
lfs f2, 0x2C (REG_BG_JOBJ)
fmuls f1,f1,f2
stfs f1, 0x2C (REG_BG_JOBJ)

/*
# Count letters in tag
.set  REG_NUM, 25
.set  REG_CURR, 26
addi r3, REG_MSRB_ADDR, MSRB_P1_NAME
mulli r4, REG_COUNT, 31
add REG_CURR,r3,r4
li  REG_NUM,0
DISPLAY_NAME_COUNT_LOOP:
lbz r3,0x0(REG_CURR)
cmpwi r3,0
beq DISPLAY_NAME_COUNT_EXIT
cmpwi r3,0x81
blt DISPLAY_NAME_COUNT_ASCII
DISPLAY_NAME_COUNT_SHIFT:
addi  REG_CURR,REG_CURR,2
b DISPLAY_NAME_COUNT_INCLOOP
DISPLAY_NAME_COUNT_ASCII:
addi  REG_CURR,REG_CURR,1
b DISPLAY_NAME_COUNT_INCLOOP
DISPLAY_NAME_COUNT_INCLOOP:
addi  REG_NUM,REG_NUM,1
b DISPLAY_NAME_COUNT_LOOP
DISPLAY_NAME_COUNT_EXIT:
# Check if over 4 characters
cmpwi REG_NUM, 4
ble DISPLAY_NAME_SHORT
DISPLAY_NAME_LONG:


# Scale BG based on tag length
subi r3,REG_NUM,4
lis	r0, 0x4330
lfd	f2, -0x6758 (rtoc)
xoris	r3, r3,0x8000
stw	r0,0x80(sp)
stw	r3,0x84(sp)
lfd	f1,0x80(sp)
fsubs	f1,f1,f2		#Convert To Float
# Scale based on length
lfs f2,DOFST_PLAYERBG_SCALEMULT (REG_DATA_ADDR)
fmuls f1,f1,f2
# Plus base length
lfs f2, DOFST_PLAYERBG_SCALEBASE (REG_DATA_ADDR)
fadds f1,f1,f2
stfs f1, 0x2C (REG_BG_JOBJ)
b DISPLAY_NAME_END
DISPLAY_NAME_SHORT:
#Base width
lfs f1, DOFST_PLAYERBG_SCALEBASE (REG_DATA_ADDR)
stfs f1, 0x2C (REG_BG_JOBJ)
b DISPLAY_NAME_END
DISPLAY_NAME_END:
*/

DISPLAY_NAME_INC_LOOP:
addi REG_COUNT, REG_COUNT, 1
cmpwi REG_COUNT, 6
blt DISPLAY_NAME_LOOP


# Free buffer
mr  r3,REG_MSRB_ADDR
branchl r12,HSD_Free

CODE_END:
restore

EXIT:
lwz	r0, 0x001C (sp)
