################################################################################
# Address: 0x8023c730 # Immediately following selecting a text item.
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

####################################
# Tag autocomplete logic           #
####################################

.set REG_TX_ADDR, 22 # REG to use to send DMA. 
.set BufferPointer, 30 # The buffer to where the autocomplete suggestion will be returned. 
.set ACL, 19 # Current name entry's length. TODO: Rename.

CODE_START:
backup

# Alloc space for buffer.
li r3, NEAC_SIZE
branchl r12, HSD_MemAlloc
mr REG_TX_ADDR, r3

# Write command value/type to first byte in DMA buffer. 
li r3, CONST_SlippiCmdNameEntryAutoComplete
stb r3, NEAC_CMD (REG_TX_ADDR)

# Copy current text to the newly created buffer.
addi r3, REG_TX_ADDR, 1
mr r4, BufferPointer
li r5, 25
branchl r12, memcpy

# Set index into name entry auto complete buffer.
addi r7, REG_TX_ADDR, NEAC_CURRENT_TEXT
li r4, 0
li r5, 0

# Load the cursor location
lbz ACL, 0x58 (r28) 

# No bother trying to autocomplete if we're entering the final character.
# TODO: Move prior to any mem alloc. 
cmpwi ACL, 0x7
bge FREE 

mulli ACL, ACL, 0x2

# Write only the text up to the cursor to DMA buffer.
WRITE_OPP_CODE_LOOP_START:
    lhzx r3, BufferPointer, r4
    sthx r3, r7, r5
    addi r4, r4, 3
    addi r5, r5, 2
    cmpw r5, ACL 
blt WRITE_OPP_CODE_LOOP_START

# Clear any remaining autocompleted portions.
li r3, 0
cmpwi r5, 0xE
bge DMA_WRITE

CLEAR_REST_TEXT:
    sthx r3, r7, r5
    addi r5, r5, 2
    cmpwi r5, 0xE
blt CLEAR_REST_TEXT

DMA_WRITE:

# Dma write
mr r3, REG_TX_ADDR
li r4, NEAC_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Debugging
#    logf LOG_LEVEL_NOTICE, "Auto complete: %x" 

# DMA read
li r4, 0x25
mr r3, BufferPointer
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

FREE: 
# Free buffer 
mr r3, REG_TX_ADDR
li r4, NEAC_SIZE
branchl r12, HSD_Free

restore

EXIT: 
branchl r12, 0x8023ce38
