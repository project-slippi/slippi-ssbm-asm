################################################################################
# Address: 0x8023c730 # Immediately following selecting a text item.
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

b EXIT
b CODE_START

DATA_BLRL:
blrl
# Base Text Properties
.set DOFST_TEXT_BASE_Z, 0
.float 17
.set DOFST_TEXT_BASE_CANVAS_SCALING, DOFST_TEXT_BASE_Z + 4
.float 0.0665

.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float 0
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float -129
.set DOFST_TEXT_COLOR, DOFST_TEXT_Y_POS + 4
.long 0xFFCB00FF
.set DOFST_TEXT_SIZE, DOFST_TEXT_COLOR + 4
.float 0.85
.align 2

####################################
# Tag autocomplete logic           #
####################################

.set REG_TX_ADDR, 22 # REG to use to send DMA. 
.set BufferPointer, 30 # The buffer to where the autocomplete suggestion will be returned. 
.set REG_TEXT_STRUCT, 23
.set REG_DATA_ADDR, 21

CODE_START:
backup

bl DATA_BLRL
mflr REG_DATA_ADDR

# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

# Alloc space for buffer.
li r3, NEAC_SIZE
branchl r12, HSD_MemAlloc
mr REG_TX_ADDR, r3

li r3, CONST_SlippiCmdNameEntryAutoComplete
stb r3, NEAC_CMD (REG_TX_ADDR)

# Copy current text to buffer.
addi r3, REG_TX_ADDR, 1
mr r4, BufferPointer
li r5, 24
branchl r12, memcpy

# Write current name entry
addi r7, REG_TX_ADDR, NEAC_CURRENT_TEXT
li r4, 0
li r5, 0

WRITE_OPP_CODE_LOOP_START:
    lhzx r3, BufferPointer, r4
    sthx r3, r7, r5
    addi r4, r4, 3
    addi r5, r5, 2
    cmpwi r5, 18
blt WRITE_OPP_CODE_LOOP_START

# Dma write
mr r3, REG_TX_ADDR
li r4, NEAC_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Debugging
#    logf LOG_LEVEL_NOTICE, "Auto complete: %x" 

# DMA read
li r4, 0x24
mr r3, BufferPointer
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# b COMMENT

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

# Update text
lfs f1, DOFST_TEXT_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, BufferPointer, 0
branchl r12, Text_InitializeSubtext

mr r4, r3
mr r3, REG_TEXT_STRUCT
lfs f1, DOFST_TEXT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

# COMMENT:

# branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

# Free buffer 
mr r3, REG_TX_ADDR
li r4, NEAC_SIZE
branchl r12, HSD_Free

restore

EXIT: 
branchl r12, 0x8023ce38
