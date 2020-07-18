################################################################################
# Address: 0x8023ccbc 
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# TODO: Do more testing to make sure register isn't used elsewhere.
.set REG_CODE_INDEX, 21 # Index into our direct codes list.
.set REG_TX_ADDR, 22 # Index used to transmit direct code index through DMA. 
.set BufferPointer, 30 # The buffer to where the returned direct code where will be stored. 

# Only decrement while index is > 0
cmpwi REG_CODE_INDEX, 0x0
ble EXIT 

# Subtract direct codes index by 1
subi REG_CODE_INDEX, REG_CODE_INDEX, 1

# Stop all pending sounds
branchl r12, SFX_StopSFXInstance

backup

# Play sound
li	r3, 2 
branchl r12, SFX_Menu_CommonSound

# Debugging trigger outputs
# mr r5, REG_CODE_INDEX
# logf LOG_LEVEL_NOTICE, "Pressed L. Current Index: %d" 

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
li  r4, 0x24 # Buffer size: 3 bytes for each of the 8 characters
mr r3, BufferPointer # Load the appropriate point in memory to have data written to
li r5, CONST_ExiRead # Load flag indicating we wish to perform a DMA read.
branchl r12,FN_EXITransferBuffer

# Debugging
# lwz r5, 0x0(BufferPointer)
# logf LOG_LEVEL_NOTICE, "Retrieved tag: %x" 

branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

restore

EXIT:

branchl r12, 0x8023ce38