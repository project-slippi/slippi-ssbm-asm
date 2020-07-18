################################################################################
# Address: 0x8023cce0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# TODO: Do more testing to make sure register isn't used elsewhere.
.set REG_CODE_INDEX, 21 # Index into our direct codes list.
.set REG_RUN_ONCE, 23
.set REG_TX_ADDR, 22 # Index used to transmit direct code index through DMA. 
.set BufferPointer, 30 # The buffer to where the returned direct code where will be stored. 

cmpwi REG_RUN_ONCE, 0x0
bgt START 
li REG_CODE_INDEX, -1
li REG_RUN_ONCE, 0x01

START:
addi REG_CODE_INDEX, REG_CODE_INDEX, 1

# Stop all pending sounds
branchl r12, SFX_StopSFXInstance

START_TRANSFER:
backup

# Debugging trigger outputs
    # mr r5, REG_CODE_INDEX
    # logf LOG_LEVEL_NOTICE, "Pressed R. Current Index: %d" 

# Prep data to be written over DMA.
li r3, CONST_SlippiCmdSendNameEntryIndex
stb r3, NEDC_CMD(REG_TX_ADDR)
stb REG_CODE_INDEX, NEDC_NAME_ENTRY_INDEX(REG_TX_ADDR)

# Transmit our index variable to Dolphin
mr r3, REG_TX_ADDR 
li r4, NEDC_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Read name entry from Dolphin.
li r4, 0x25 # Buffer size: 1x byte for hit max index. 3 bytes for each of the 8 characters
mr r3, BufferPointer # Load the appropriate point in memory to have data written to
li r5, CONST_ExiRead # Load flag indicating we wish to perform a DMA read.
branchl r12,FN_EXITransferBuffer

# Handle an error, if we've reached the end of the list. 
lbz r3, 0x0 (BufferPointer)
cmpwi r3, 0x01
beq OOB_ERROR 

# Debugging
    # lwz r5, 0x0(BufferPointer)
    # logf LOG_LEVEL_NOTICE, "Retrieved tag: %x" 

# Play normal nav sound
li r3, 2
branchl r12, SFX_Menu_CommonSound

branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName
b CLEANUP

# Play error noise and revert to last valid entry
OOB_ERROR:
restore

backup
# Play failure sound
li	r3, 3 
branchl r12, SFX_Menu_CommonSound
restore

# Revert cur index to within bounds and re-retrieve data
subi REG_CODE_INDEX, REG_CODE_INDEX, 1
b START_TRANSFER

CLEANUP:
restore

EXIT:

branchl r12, 0x8023ce38