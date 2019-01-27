################################################################################
# Macros
################################################################################
.macro branchl reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctrl
.endm

.macro branch reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctr
.endm

.macro load reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
.endm

.macro loadf regf,reg,address
lis \reg, \address @h
ori \reg, \reg, \address @l
stw \reg,-0x4(sp)
lfs \regf,-0x4(sp)
.endm

.macro backup
mflr r0
stw r0, 0x4(r1)
stwu r1,-0xB0(r1)	# make space for 12 registers
stmw r20,0x8(r1)
.endm

 .macro restore
lmw r20,0x8(r1)
lwz r0, 0xB4(r1)
addi r1,r1,0xB0	# release the space
mtlr r0
.endm

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_EXITransferBuffer, 0x800055f0
.set FN_GetIsFollower, 0x800055f8
.set FN_LoadPSTransformation, 0x80005600

# Game functions
.set HSD_Randi, 0x80380580
.set HSD_MemAlloc,0x8037f1e4
.set HSD_Free,0x8037f1b0

################################################################################
# Const Definitions
################################################################################
# For EXI transfers
.set CONST_ExiRead, 0 # arg value to make an EXI read
.set CONST_ExiWrite, 1 # arg value to make an EXI write

# For Slippi communication
.set CONST_SlippiCmdGetFrame, 0x76
.set CONST_SlippiCmdCheckForReplay, 0x88
.set CONST_SlippiCmdCheckForStockSteal,0x89
.set CONST_SlippiCmdGetBufferedFrameCount,0x90

.set UCFBools,0xDD8
.set UCFTextPointers,0x4fa0

################################################################################
# Offsets
################################################################################
.set frameDataBuffer,-0x49b4
.set secondaryDmaBuffer,-0x49b0
.set frameIndex,-0x49ac
