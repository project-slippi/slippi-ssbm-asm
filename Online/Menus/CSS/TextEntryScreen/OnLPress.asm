################################################################################
# Address: 0x8023ccbc 
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# TODO: Do more testing to make sure register isn't used elsewhere.
.set REG_CODE_INDEX, 21 

# Only decrement while index is > 0
cmpwi REG_CODE_INDEX, 0x0
ble EXIT 

# Subtract direct codes index by 1
subi REG_CODE_INDEX, REG_CODE_INDEX, 1

# Stop all pending sounds
branchl r12, SFX_StopSFXInstance

backup

# Play failure sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound

mr r5, REG_CODE_INDEX
logf LOG_LEVEL_NOTICE, "Pressed L. Current Index: %d" 

restore

EXIT:

branchl r12, 0x8023ce38