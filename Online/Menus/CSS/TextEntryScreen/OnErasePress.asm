################################################################################
# Address: 0x8023c81c
################################################################################

.include "Common/Common.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

# Pressing A on the erase button works very similar to pressing B except that the last char erase
# doesn't return to CSS, instead it plays an error sound.

# Fetch INJ data table in order to branch to function stored in there
computeBranchTargetAddress r3, INJ_CheckAutofill

# Update committed char count in ADC
lwz r4, IDO_ACB_ADDR(r3)
lbz r5, ACB_COMMITTED_CHAR_COUNT(r4)
cmpwi r5, 0
beq PLAY_ERROR_SOUND

branch r12, 0x8023cd3c

PLAY_ERROR_SOUND:
li	r3, 3
branchl r12, SFX_Menu_CommonSound
branch r12, 0x8023ce38 # Exits think function