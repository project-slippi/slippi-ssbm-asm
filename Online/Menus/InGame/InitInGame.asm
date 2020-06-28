################################################################################
# Address: 0x8016e9b4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_ODB_ADDRESS, 31
.set REG_TEXT_STRUCT, 30
.set REG_DATA_ADDR, 29
.set REG_STRING_BUF, 28

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

.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float 605
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float 415
.set DOFST_TEXT_SIZE, DOFST_TEXT_Y_POS + 4
.float 0.5

.set DOFST_TEXT_STRING, DOFST_TEXT_SIZE + 4
.string "Delay: %df"
.align 2

CODE_START:
backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

bl DATA_BLRL
mflr REG_DATA_ADDR

# Start with sprintf to build string
li r3, STRING_BUF_LEN
branchl r12, HSD_MemAlloc
mr REG_STRING_BUF, r3

addi r4, REG_DATA_ADDR, DOFST_TEXT_STRING
lbz r5, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
branchl r12, sprintf

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
mr r4, REG_STRING_BUF
branchl r12, Text_InitializeSubtext

# Set header text size
mr r3, REG_TEXT_STRUCT
li r4, 0
lfs f1, DOFST_TEXT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

restore

EXIT:
lwz	r0, 0x001C (sp)
