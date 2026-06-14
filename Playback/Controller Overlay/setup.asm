# local functions
.macro setupPiece loc, strct, isBackdropBool
bl \loc
mflr r3
li r4, 0
loadTextAddr r5, \strct
li r6, \isBackdropBool
bl SETUP_PIECE
.endm
# r3 piece data loc
# r4 player
# r5 save location
# r6 isBackdropBool
SETUP_PIECE:
backup
mr r16, r3
mr r14, r5
mr r15, r6
# build text object
li r3, 2
mr r4, REG_CANVAS 
branchl REG_SCRATCH, Text_CreateStruct
mr REG_TEXT_STRUCT, r3
li r3, 0x1
stb r3, 0x48(REG_TEXT_STRUCT) # Fixed Width
stb r3, 0x4A(REG_TEXT_STRUCT) # Set text to align center
stb r3, 0x4C(REG_TEXT_STRUCT) # Unk?
stb r3, 0x49(REG_TEXT_STRUCT) # kerning?

cmpwi r15, 0
beq+ DONT_PLACE_IT
# specifically place backdrop piece so it doesn't
# need to be updated in callback
mr r10, r16
loadPieceData
getPlayerHudXFloat f1
fadds f5, f5, f1
setTextPosScale REG_TEXT_STRUCT, f5, f6, f7, f8
li r3, UNPRESSED_OPACITY
stb r3, TEXT_STRUCT_OPACITY_BYTE_OFFSET(REG_TEXT_STRUCT)
DONT_PLACE_IT:
# don't need to set position of the text because we update it every frame
# set text on the struct
crset 6
lfs f1, FLOAT_ZERO(REG_DATA_ADDR)
lfs f2, FLOAT_ZERO(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, r16, TEXT
branchl REG_SCRATCH, Text_InitializeSubtext
# save the text struct
stw REG_TEXT_STRUCT, 0(r14)
restore
blr

# begin setup
SETUP:
backup
getMinorMajor r3
cmpwi r3, SCENE_PLAYBACK_IN_GAME
bne SETUP_DONE
# get data address
bl DATA_LOC
mflr REG_DATA_ADDR
# buil COBJ
load r3, 0x804d6d5c
lwz r3, 0x0(r3)
load r4, 0x803f94d0
branchl r12, HSD_ArchiveGetPublicAddress
lwz r3, 0x4(r3)
lwz r3, 0x0(r3)
branchl r12, 0x8036a590
mr REG_COBJ,r3
# build GOBJ
li r3, 19
li r4, 20
li r5, 0
branchl REG_SCRATCH, GObj_Create
mr REG_GOBJ, r3
# add object
mr r3, REG_GOBJ
lbz r4, -0x3E55(r13)
mr r5, REG_COBJ
branchl REG_SCRATCH, GObj_AddToObj
# Init camera
mr r3, REG_GOBJ
bl COBJ_CB
mflr r4
li r5, COBJ_GXPRI
branchl r12, 0x8039075c
# Store COBJs GXLinks:
load r3, 1 << TEXT_GXLINK
stw r3, 0x24 (REG_GOBJ)
#build canvas.
li r3, 2
mr r4,REG_GOBJ
li r5, 9
li r6, 13
li r7, 0
li r8, TEXT_GXLINK
li r9, TEXT_GXPRI
li r10, COBJ_GXPRI
branchl REG_SCRATCH, 0x803a611c
mr REG_CANVAS, r3

li REG_PLAYER_INDEX, 0
SETUP_PLAYER:
# is player present?
offsetAddr r3, REG_SCRATCH, STATIC_BLOCK_ADDRESS, STATIC_BLOCK_OFFSET, REG_PLAYER_INDEX
lhz r3, STATIC_BLOCK_PLAYER_TYPE_OFFSET(r3)
cmpwi r3, PLAYER_TYPE_NONE
bne PLAYER_IS_PRESENT
# if player type is none set data to 0 to clean pointer
# only needs to clean MAIN_STICK because it is the first
# offset read in callback
loadTextAddr r3, CV_MAIN_STICK_OFFSET
li r4, 0
stw r4, 0(r3)
b SETUP_PLAYER_DONE

PLAYER_IS_PRESENT:
# build pieces
# stick backdrops
setupPiece MAIN_STICK_LOC, CV_MAIN_STICK_OFFSET, 1
setupPiece C_STICK_LOC, CV_C_STICK_OFFSET, 1
# everything else
setupPiece MAIN_STICK_LOC, CV_MAIN_STICK_OFFSET, 0
setupPiece C_STICK_LOC, CV_C_STICK_OFFSET, 0
setupPiece A_BTN_LOC, CV_A_BTN_OFFSET, 0
setupPiece B_BTN_LOC, CV_B_BTN_OFFSET, 0
setupPiece X_BTN_LOC, CV_X_BTN_OFFSET, 0
setupPiece Y_BTN_LOC, CV_Y_BTN_OFFSET, 0
setupPiece L_BTN_LOC, CV_L_BTN_OFFSET, 0
setupPiece R_BTN_LOC, CV_R_BTN_OFFSET, 0
setupPiece Z_BTN_LOC, CV_Z_BTN_OFFSET, 0
## background
# Create gobj
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
getPlayerHudXFloat f1
# Set bg position
lfs f1 ,0x0(r3)
lfs f2, BG_X(REG_DATA_ADDR)
fadds f1,f1,f2
stfs  f1,0x38(REG_BG_JOBJ)
lfs f1, BG_Y(REG_DATA_ADDR)
stfs  f1,0x3C(REG_BG_JOBJ)
# Adjust scale
lfs f1, BG_WIDTH(REG_DATA_ADDR)
stfs f1, 0x2c(REG_BG_JOBJ)
lfs f1, BG_HEIGHT(REG_DATA_ADDR)
stfs f1, 0x30(REG_BG_JOBJ)
# Get JOBJ 1
mr  r3, REG_BG_JOBJ
addi  r4, sp, 0x80
li  r5, 1
li  r6, -1
branchl r12,0x80011e24
# Z transform = 0
lwz r3, 0x80(sp)
li r4, 0
stw r4, 0x40(r3)
# Remove unneccessary dobjs
lwz r3, 0x80(sp)
lwz r3, 0x18(r3)  #first dobj
lwz r4, 0x14(r3)
ori r4, r4, 0x1
stw r4, 0x14(r3)
lwz r3, 0x4(r3)  #next dobj
lwz r4, 0x14(r3)
ori r4, r4, 0x1
stw r4, 0x14(r3)
# Adjust opacity of BG
lwz r3, 0x4(r3)  #next dobj
lwz r3, 0x8(r3)  #mobj
lwz r3, 0xC(r3)  #material
lfs f1, BG_OPACITY (REG_DATA_ADDR)
stfs f1, 0xC(r3)
# Adjust color of BG
lwz r4, BG_COLOR (REG_DATA_ADDR)
stw r4, 0x4(r3)

SETUP_PLAYER_DONE:
addi REG_PLAYER_INDEX, REG_PLAYER_INDEX, 1
cmpwi REG_PLAYER_INDEX, 4
blt+ SETUP_PLAYER

SETUP_DONE:
restore
b EXIT
