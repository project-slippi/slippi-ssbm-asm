################################################################################
# Address: 0x8023cce0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_CODE_INDEX, 21 
.set REG_TX_ADDR, 27

addi REG_CODE_INDEX, REG_CODE_INDEX, 1
backup

# Stop all pending sounds
branchl r12, SFX_StopSFXInstance

# Play failure sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound

mr r5, REG_CODE_INDEX
logf LOG_LEVEL_NOTICE, "Pressed R. Current Index: %d" 

li r3, CONST_SlippiCmdSendNameEntryIndex
stb r3, NEDC_CMD(REG_TX_ADDR)
stb REG_CODE_INDEX, NEDC_NAME_ENTRY_INDEX(REG_TX_ADDR)

mr r3, REG_TX_ADDR 
li r4, NEDC_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

restore

branchl r12, 0x8023ce38