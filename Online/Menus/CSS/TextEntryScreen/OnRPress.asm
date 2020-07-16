################################################################################
# Address: 0x8023cce0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_CODE_INDEX, 21 

addi REG_CODE_INDEX, REG_CODE_INDEX, 1
backup

# Stop all pending sounds
branchl r12, SFX_StopSFXInstance

# Play failure sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound

mr r5, REG_CODE_INDEX

restore

logf LOG_LEVEL_NOTICE, "Pressed R. Current Index: %d" 

branchl r12, 0x8023ce38