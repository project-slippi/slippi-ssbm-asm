################################################################################
# Address: 0x8016e9b4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

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
.float 27
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float -10
.set DOFST_TEXT_SIZE, DOFST_TEXT_Y_POS + 4
.float 0.04



# BG values
.set DOFST_PLAYERBG_OPA, DOFST_TEXT_SIZE + 4
.float 0.33
.set DOFST_PLAYERBG_COLOR, DOFST_PLAYERBG_OPA + 4
.byte 0,0,0,255
.set DOFST_PLAYERBG_YSCALE, DOFST_PLAYERBG_COLOR + 4
.float 0.8
.set DOFST_PLAYERBG_XOFST, DOFST_PLAYERBG_YSCALE + 4
.float 0.775
.set DOFST_PLAYERBG_YOFST, DOFST_PLAYERBG_XOFST + 4
.float -24.5 #(DOFST_PLAYERTEXT_YPOS * 1.13953488372)
# BG X scale per letter
.set DOFST_PLAYERBG_XSCALEMULT, DOFST_PLAYERBG_YOFST + 4
.float 0.014

.set DOFST_PLAYERTEXT_XPOS, DOFST_PLAYERBG_XSCALEMULT + 4
.float -3    #higher values = right
.set DOFST_PLAYERTEXT_YPOS, DOFST_PLAYERTEXT_XPOS + 4
.float 21.5     #higher values = down
.set DOFST_PLAYERTEXT_ZPOS, DOFST_PLAYERTEXT_YPOS + 4
.float 0
.set DOFST_PLAYERTEXT_WIDTH, DOFST_PLAYERTEXT_ZPOS + 4
.float 145
.set DOFST_PLAYERTEXT_HEIGHT, DOFST_PLAYERTEXT_WIDTH + 4
.float 300
.set DOFST_PLAYERTEXT_CANVASSCALE, DOFST_PLAYERTEXT_HEIGHT + 4
.float 0.0521 #0.0521

# strings
.set DOFST_TEXT_DELAYSTRING, DOFST_PLAYERTEXT_CANVASSCALE + 4
.string "Delay: %df"
.align 2

.set DOFST_TEXTHEADER_SIZE, 10
TEXT_HEADER_BLRL:
blrl
#.byte 0x10                  #center
.byte 0x16                  #kerning
.byte 0xC, 255, 255, 255    #color
.byte 0x0E
.hword 138, 138             #bound
.align 2

.set DOFST_TEXTTERMINATOR_SIZE, 3
TEXT_TERMINATOR_BLRL:
blrl
.byte 0xf, 0xd, 00
.align 2

#########################################
COBJ_CB:
blrl
.set  REG_GOBJ,31

backup

mr  REG_GOBJ, r3

/*
# Check if paused
li  r3,1
branchl r12,0x801a45e8
cmpwi r3,2
beq COBJ_CB_Exit
*/
# Check if paused
lbz	r0, -0x4934 (r13)
cmpwi r0,1
beq COBJ_CB_Exit

# Draw camera
mr  r3, REG_GOBJ
branchl r12,0x803910d8

COBJ_CB_Exit:
restore
blr
#########################################

CODE_START:
backup

# CObj stuff
.set  COBJ_GXPRI, 8
.set  TEXT_GXPRI, 80
.set  TEXT_GXLINK, 12

.set  REG_Canvas,31
.set  REG_COBJ,30
.set  REG_GOBJ,29

# Get HUD CObjDesc
load  r3, 0x804d6d5c
lwz r3, 0x0 (r3)
load  r4, 0x803f94d0
branchl r12,0x80380358
# Create CObj
lwz r3,0x4(r3)
lwz r3,0x0(r3)
branchl r12,0x8036a590
mr  REG_COBJ,r3
# Create GObj
li  r3,19
li  r4,20
li  r5,0
branchl r12,0x803901f0
mr  REG_GOBJ,r3
# Add object
mr  r3,REG_GOBJ
lbz r4,-0x3E55(r13)
mr  r5,REG_COBJ
branchl r12,0x80390a70
# Init camera
mr  r3,REG_GOBJ
bl  COBJ_CB
mflr  r4
li  r5, COBJ_GXPRI
branchl r12,0x8039075c
# Store COBJs GXLinks
load  r3, 1 << TEXT_GXLINK
stw r3, 0x24 (REG_GOBJ)

# Create canvas
li  r3,2
mr  r4,REG_GOBJ
li  r5, 9
li  r6, 13
li  r7, 0
li  r8, TEXT_GXLINK
li  r9, TEXT_GXPRI
li  r10, COBJ_GXPRI
branchl r12, 0x803a611c
mr  REG_Canvas, r3


.set REG_ODB_ADDRESS, 30
.set REG_TEXT_STRUCT, 29
.set REG_DATA_ADDR, 28
.set REG_STRING_BUF, 27
.set REG_MSRB_ADDR,26

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

bl DATA_BLRL
mflr REG_DATA_ADDR

# Get player names
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Start prepping text struct
li r3, 2
mr  r4,REG_Canvas
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
lfs f1, DOFST_TEXT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

##########################
## Display Player Names ##
##########################

# Display all player names
.set REG_COUNT, 20
.set REG_TAG_BUFFER, 21
.set REG_TAG_SIZE, 22
.set REG_TAG_ALLOC, 23
.set REG_HUDPOS, 21
.set REG_BG_JOBJ, 22
.set REG_BG_GOBJ, 23
li  REG_COUNT, 0
load REG_HUDPOS, 0x804a0ff0
DISPLAY_NAME_LOOP:
#Check if player exists
mr  r3, REG_COUNT
branchl r12, 0x8003241c
cmpwi r3, 3
beq DISPLAY_NAME_INC_LOOP

# Calculate X Position
#Get HUD Position
mr  r3,REG_COUNT
branchl r12,0x802f3424
# HUD X
lfs f1, 0x0(r3)
stfs f1, 0x70 (sp)


# Start prepping text struct
li r3, 2
mr  r4, REG_Canvas
lfs f1, 0x70 (sp)
lfs f2, DOFST_PLAYERTEXT_XPOS (REG_DATA_ADDR)
fadds f1,f1,f2
lfs f2, DOFST_PLAYERTEXT_YPOS (REG_DATA_ADDR)
lfs f3, DOFST_PLAYERTEXT_ZPOS (REG_DATA_ADDR)
lfs f4, DOFST_PLAYERTEXT_WIDTH (REG_DATA_ADDR)
lfs f5, DOFST_PLAYERTEXT_HEIGHT (REG_DATA_ADDR)
branchl r12, 0x803a5acc
mr REG_TEXT_STRUCT, r3

# Fixed Width
li r4, 0x1
stb r4, 0x48(REG_TEXT_STRUCT)
# Set text to align center
li r4, 0x1
stb r4, 0x4A(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, DOFST_PLAYERTEXT_CANVASSCALE(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

#############################
## Create Player Name Text ##
#############################

# alloc buffer of size (15 * 3) + 1. (3 bytes per character, plus a terminator)
li  r3,(15*3) + 1
branchl r12,HSD_MemAlloc
mr  REG_TAG_BUFFER,r3

# convert to menu text
mr  r3,REG_TAG_BUFFER
addi r4, REG_MSRB_ADDR, MSRB_P1_NAME
mulli r5, REG_COUNT, 31
add r4,r4,r5
branchl r12,0x803a67ec
mr  REG_TAG_SIZE,r3

# alloc mem for menu text
addi  r3,REG_TAG_SIZE, DOFST_TEXTHEADER_SIZE + DOFST_TEXTTERMINATOR_SIZE
branchl r12,0x803a5798
mr  REG_TAG_ALLOC,r3

# copy header
mr  r3,REG_TAG_ALLOC
bl  TEXT_HEADER_BLRL
mflr  r4
li  r5,DOFST_TEXTHEADER_SIZE
branchl r12,memcpy

# copy text
addi  r3, REG_TAG_ALLOC, DOFST_TEXTHEADER_SIZE
mr  r4, REG_TAG_BUFFER
mr  r5,REG_TAG_SIZE
branchl r12,memcpy

# copy terminator
addi  r3, REG_TAG_ALLOC, DOFST_TEXTHEADER_SIZE
add r3,r3,REG_TAG_SIZE
bl  TEXT_TERMINATOR_BLRL
mflr  r4
li  r5,DOFST_TEXTTERMINATOR_SIZE
branchl r12,memcpy

mr  r3,REG_TEXT_STRUCT
li  r4,0
branchl r12,0x803a6368
stw REG_TAG_ALLOC,0x5C(REG_TEXT_STRUCT)
/*
# finalize struct
stw REG_TAG_ALLOC,0x5C(REG_TEXT_STRUCT)
li  r3,0
stw r3, 0x60(REG_TEXT_STRUCT)                  #store 0 to curr (0x60)
li  r3,16
branchl r12,0x803a5798
stw r3,0x68(REG_TEXT_STRUCT)                #store size
li  r4,16
branchl r12, Zero_AreaLength                #zero out
li  r3,16
sth r3,0x6E(REG_TEXT_STRUCT)                #store size
*/

# free buffer
mr  r3, REG_TAG_BUFFER
branchl r12,HSD_MemAlloc

############################
## Create Text Background ##
############################

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
li  r5, TEXT_GXLINK
li  r6,0
branchl r12,0x8039069c

# Get HUD pos
mr  r3,REG_COUNT
branchl r12,0x802f3424
# Set bg position
lfs f1,0x0 (r3)
lfs f2, DOFST_PLAYERBG_XOFST (REG_DATA_ADDR)
fadds f1,f1,f2
stfs  f1,0x38 (REG_BG_JOBJ)
lfs f1, DOFST_PLAYERBG_YOFST (REG_DATA_ADDR)
stfs  f1,0x3C (REG_BG_JOBJ)
# Adjust scale
lfs f1, DOFST_PLAYERBG_YSCALE (REG_DATA_ADDR)
stfs f1, 0x30 (REG_BG_JOBJ)
# Get JOBJ 1
mr  r3,REG_BG_JOBJ
addi  r4,sp,0x80
li  r5,1
li  r6,-1
branchl r12,0x80011e24
# Z transform = 0
lwz r3,0x80(sp)
li  r4,0
stw r4,0x40(r3)
# Remove unneccessary dobjs
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
.set  CHAR_WIDTH_MAX, 20
.set  TAG_WIDTH_MIN, 60
.set  TAG_WIDTH_MAX, 115
.set  REG_WIDTH, 25
.set  REG_CURR, 10
.set  REG_WIDTH_INTERNAL, 12
.set  REG_WIDTH_EXTERNAL, 11
li  REG_WIDTH,0
# Get subtext contents
lwz  r3,0x5C(REG_TEXT_STRUCT)
addi  REG_CURR, r3, DOFST_TEXTHEADER_SIZE   #skip past header
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
cmpwi REG_WIDTH, TAG_WIDTH_MAX
ble 0x8
li  REG_WIDTH, TAG_WIDTH_MAX
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
