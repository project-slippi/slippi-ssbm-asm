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

backup
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

mr r3, REG_TX_ADDR
li r4, NEAC_SIZE
branchl r12, HSD_Free

restore

branchl r12, 0x8023ce38