#local functions 
GET_CONTROLLER_DATA_STICK:
loadPlayerDataPointer r10, REG_SCRATCH, REG_PLAYER_INDEX, DONE_HANDLING_PLAYER
# main stick
lfs f11, PD_MAIN_STICK_X_OFFSET(r10)
lfs f12, PD_MAIN_STICK_Y_OFFSET(r10)
# c stick
lfs f13, PD_C_STICK_X_OFFSET(r10)
lfs f14, PD_C_STICK_Y_OFFSET(r10)
blr

GET_CONTROLLER_DATA_BTN:
loadPlayerDataPointer r10, REG_SCRATCH, REG_PLAYER_INDEX, DONE_HANDLING_PLAYER
lwz r14, PD_BTN_STATE_OFFSET(r10)
andi r3, r14, BTN_STATE_A_BIT, REG_SCRATCH
andi r4, r14, BTN_STATE_B_BIT, REG_SCRATCH
andi r5, r14, BTN_STATE_X_BIT, REG_SCRATCH
andi r6, r14, BTN_STATE_Y_BIT, REG_SCRATCH
andi r7, r14, BTN_STATE_Z_BIT, REG_SCRATCH
andi r8, r14, BTN_STATE_R_BIT, REG_SCRATCH
andi r9, r14, BTN_STATE_L_BIT, REG_SCRATCH
blr

.macro handleStick fregx, fregy, loc, cvOffset
loadTextStruct r3, \cvOffset
bl \loc
mflr r10
fmr f1, \fregx
fmr f2, \fregy
bl HANDLE_PIECE_STICK
.endm
# f1,f2 is input stick x,y
# r10 is loc address
# f10 is player hud offset
HANDLE_PIECE_STICK:
loadPieceData
# scale the stick movement
fmuls f1, f1, f9
fmuls f2, f2, f9
# scooch by hud nametag offset
fadds f5, f5, f10
fadds f5, f5, f1
fsubs f6, f6, f2
b SET_TEXT_POS_SCALE_AND_BLR

.macro handleBtn regBtnPressed, loc, cvOffset
loadTextStruct r10, \cvOffset
bl \loc
mflr r10
mr r11, \regBtnPressed
bl HANDLE_PIECE_BTN
.endm
# r11 is btn data
# r10 is loc address
# f10 is player hud offset
HANDLE_PIECE_BTN:
loadPieceData
# scooch by hud nametag offset
fadds f5, f5, f10
# branch on whether button is pressed
cmpwi r11, 0
bne- BTN_IS_PRESSED
# button not pressed
fsubs f6, f6, f9
li r3, UNPRESSED_OPACITY
b BTN_SET_VALUES
BTN_IS_PRESSED:
li r3, PRESSED_OPACITY
BTN_SET_VALUES:
stb r3, TEXT_STRUCT_OPACITY_BYTE_OFFSET(REG_TEXT_STRUCT)
b SET_TEXT_POS_SCALE_AND_BLR

SET_TEXT_POS_SCALE_AND_BLR:
setTextPosScale REG_TEXT_STRUCT, f5, f6, f7, f8
blr

# begin callback
COBJ_CB:
blrl

backup
mr REG_GOBJ, r3
# Check if paused
lbz	r0, -0x4934(r13)
cmpwi r0, 1
beq COBJ_CB_Exit
# start per player loop
li REG_PLAYER_INDEX, 0
bl DATA_LOC
mflr REG_DATA_ADDR

UPDATE_PLAYER_CONTROLLER:
getPlayerHudXFloat f10
bl GET_CONTROLLER_DATA_STICK
handleStick f11, f12, MAIN_STICK_LOC, CV_MAIN_STICK_OFFSET
handleStick f13, f14, C_STICK_LOC, CV_C_STICK_OFFSET
bl GET_CONTROLLER_DATA_BTN
handleBtn r3, A_BTN_LOC, CV_A_BTN_OFFSET
handleBtn r4, B_BTN_LOC, CV_B_BTN_OFFSET
handleBtn r5, X_BTN_LOC, CV_X_BTN_OFFSET
handleBtn r6, Y_BTN_LOC, CV_Y_BTN_OFFSET
handleBtn r9, L_BTN_LOC, CV_L_BTN_OFFSET
handleBtn r8, R_BTN_LOC, CV_R_BTN_OFFSET
handleBtn r7, Z_BTN_LOC, CV_Z_BTN_OFFSET

DONE_HANDLING_PLAYER:
addi REG_PLAYER_INDEX, REG_PLAYER_INDEX, 1
cmpwi REG_PLAYER_INDEX, 4
blt+ UPDATE_PLAYER_CONTROLLER

# Draw camera
mr r3, REG_GOBJ
branchl r12, 0x803910d8

COBJ_CB_Exit:
restore
blr
