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
.float 0.1

# delay values
.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float 270
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float 207
.set DOFST_TEXT_SIZE, DOFST_TEXT_Y_POS + 4
.float 0.33

# BG values
.set DOFST_PLAYERBG_OPA, DOFST_TEXT_SIZE + 4
.float 0.33
.set DOFST_PLAYERBG_COLOR, DOFST_PLAYERBG_OPA + 4
.byte 0,0,0,255
.set DOFST_PLAYERBG_YSCALE, DOFST_PLAYERBG_COLOR + 4
.float 0.62
.set DOFST_PLAYERBG_XOFST, DOFST_PLAYERBG_YSCALE + 4
.float 0.775
.set DOFST_PLAYERBG_YOFST, DOFST_PLAYERBG_XOFST + 4
.float -24.06
# BG X scale per letter
.set DOFST_PLAYERBG_XSCALEMULT, DOFST_PLAYERBG_YOFST + 4
.float 0.0146

.set DOFST_PLAYERTEXT_XPOS, DOFST_PLAYERBG_XSCALEMULT + 4
.float 0.8    #higher values = right
.set DOFST_PLAYERTEXT_YPOS, DOFST_PLAYERTEXT_XPOS + 4
.float 20.64     #higher values = down
.set DOFST_PLAYERTEXT_ZPOS, DOFST_PLAYERTEXT_YPOS + 4
.float 0
.set DOFST_PLAYERTEXT_CANVASSCALE, DOFST_PLAYERTEXT_ZPOS + 4
.float 0.06 #0.0521
.set DOFST_PLAYERTEXT_WIDTH, DOFST_PLAYERTEXT_CANVASSCALE + 4
.float 150
.set DOFST_PLAYERTEXT_SIZE, DOFST_PLAYERTEXT_WIDTH + 4
.float 0.54

.set DOFST_FLOAT_ZERO, DOFST_PLAYERTEXT_SIZE + 4
.float 0

# strings
.set DOFST_TEXT_DELAYSTRING, DOFST_FLOAT_ZERO + 4
.string "Delay: %df"
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

# Write HUD canvas to ODB
stw REG_Canvas, ODB_HUD_CANVAS(REG_ODB_ADDRESS)

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


# Start prepping player text struct
li r3, 2
mr r4, REG_Canvas
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

li r4, 0x1
stb r4, 0x48(REG_TEXT_STRUCT) # Fixed Width
stb r4, 0x4A(REG_TEXT_STRUCT) # Set text to align center
stb r4, 0x4C(REG_TEXT_STRUCT) # Unk?
stb r4, 0x49(REG_TEXT_STRUCT) # kerning?

# Scale Canvas Down
lfs f1, DOFST_PLAYERTEXT_CANVASSCALE(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Set struct position
lfs f1, 0x70 (sp)
lfs f2, DOFST_PLAYERTEXT_XPOS (REG_DATA_ADDR)
fadds f1,f1,f2
stfs f1, 0x0(REG_TEXT_STRUCT) # X pos
lfs f1, DOFST_PLAYERTEXT_YPOS (REG_DATA_ADDR)
stfs f1, 0x4(REG_TEXT_STRUCT) # Y pos
lfs f1, DOFST_PLAYERTEXT_ZPOS (REG_DATA_ADDR)
stfs f1, 0x8(REG_TEXT_STRUCT) # Z pos

# Set max width for text
lfs f1, DOFST_PLAYERTEXT_WIDTH(REG_DATA_ADDR)
stfs f1, 0xC(REG_TEXT_STRUCT) # Write width
stfs f1, 0x10(REG_TEXT_STRUCT) # I think this is height but I don't think it does anything

#############################
## Create Player Name Text ##
#############################
# Initialize header
crset 6 # Dunno if this does anything?
lfs f1, DOFST_FLOAT_ZERO(REG_DATA_ADDR)
lfs f2, DOFST_FLOAT_ZERO(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_MSRB_ADDR, MSRB_P1_NAME
mulli r5, REG_COUNT, 31
add r4, r4, r5
branchl r12, Text_InitializeSubtext

# Set header text size
mr r3, REG_TEXT_STRUCT
li r4, 0
# Scale text X based on Aspect Ratio
lfs f1, DOFST_PLAYERTEXT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_PLAYERTEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

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
.set  TAG_WIDTH_MAX, 144
.set  TEXTHEADER_SIZE, 15
.set  REG_WIDTH, 25
.set  REG_CURR, 10
.set  REG_WIDTH_INTERNAL, 12
.set  REG_WIDTH_EXTERNAL, 11

li  REG_WIDTH,0
# Get subtext contents
lwz  r3, 0x5C(REG_TEXT_STRUCT)
li r4, 0
branchl r12, 0x803a6fec # Text_GetSubtext
addi  REG_CURR, r3, TEXTHEADER_SIZE   #skip past header
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
