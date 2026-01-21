.macro andi regOut, regNum, value, regScratch
li \regScratch, \value
and \regOut, \regNum, \regScratch
.endm

.macro followp reg, regScratch, offset, failTag
lwz \reg, \offset(\reg)
lis \regScratch, 0x8000
and \regScratch, \reg, \regScratch
cmpwi \regScratch, 0
beq \failTag
.endm

.macro offsetAddr reg, regb, baseAddr, offset, regi
load \reg, \baseAddr
li \regb, \offset
mullw \regb, \regb, \regi
add \reg, \reg, \regb
.endm

# r3 player index
.macro getPlayerHudXFloat fregOut
mr r3, REG_PLAYER_INDEX
branchl REG_SCRATCH, 0x802f3424
# r3 is HUD struct addr
lfs \fregOut, 0x0(r3) # hud x float
.endm

.macro loadTextAddr regOut, structOffset
offsetAddr REG_SCRATCH, \regOut, CONTROLLER_VISUAL_ADDR, CONTROLLER_VISUAL_OFFSET, REG_PLAYER_INDEX
load \regOut, \structOffset
add \regOut, \regOut, REG_SCRATCH
.endm

.macro loadTextStruct regSecondScratch, structOffset
loadTextAddr \regSecondScratch, \structOffset
lwz REG_TEXT_STRUCT, 0(\regSecondScratch)
.endm

.macro loadPieceData
mflr r0
bl LOAD_PIECE_DATA
mtlr r0
.endm
# r10 is loc addr
LOAD_PIECE_DATA:
lfs f5, TEXT_X(r10)
lfs f6, TEXT_Y(r10)
lfs f7, FLOAT_ZERO(REG_DATA_ADDR)
lfs f8, TEXT_CANVAS_SCALE(r10)
lfs f9, MOVE_SCALE(r10)
blr

.macro setTextPosScale textStruct, x, y, z, s
stfs \x, TEXT_STRUCT_X_OFFSET(\textStruct)
stfs \y, TEXT_STRUCT_Y_OFFSET(\textStruct)
stfs \z, TEXT_STRUCT_Z_OFFSET(\textStruct)
stfs \s, TEXT_STRUCT_WIDTH_OFFSET(\textStruct)
stfs \s, TEXT_STRUCT_HEIGHT_OFFSET(\textStruct)
.endm

.macro loadPlayerDataPointer reg, regScratch, regplayer, failTag
offsetAddr \reg, \regScratch, STATIC_ENTITY_ADDRESS, STATIC_ENTITY_OFFSET, \regplayer
followp \reg, \regScratch, 0, \failTag
followp \reg, \regScratch, STATIC_ENTITY_DATA_POINTER_OFFSET, \failTag
.endm
