################################################################################
# Address: 0x8023cce0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

backup

# Play failure sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound

restore

logf LOG_LEVEL_NOTICE, "Pressed R"

branchl r12, 0x8023ce38