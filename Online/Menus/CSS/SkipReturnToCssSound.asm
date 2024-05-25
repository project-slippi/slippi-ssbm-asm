################################################################################
# Address: 0x80264118 # Executed after check to see if tag is empty
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_ACB_ADDR, 31
.set REG_LOCK_IN_STATE, 30

# This logic only runs in 1P mode CSS, so no need to worry about VS mode compatibility

backupall # r3 needs to be restored for replaced codeline

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
bne RESET_NAME_ENTRY

# The following logic handles the transition coming back from SSS. If we are locked-in, that means
# that the stage was selected, "Choose your character" would then be an incorrect prompt, in that
# situation, we skip playing the sound. If coming back from SSS though, sound will play
li r3, 0
branchl r12, FN_LoadMatchState
lbz REG_LOCK_IN_STATE, MSRB_IS_LOCAL_PLAYER_READY(r3)
branchl r12, HSD_Free
cmpwi REG_LOCK_IN_STATE, 0
bne SKIP_SOUND # If locked in, skip sound

b EXIT

RESET_NAME_ENTRY:
# Reset name entry mode
li r3, 0
stb r3, OFST_R13_NAME_ENTRY_MODE(r13)

# Fetch location where auto-complete buffer is stored and free both buffers
computeBranchTargetAddress r3, INJ_CheckAutofill
lwz REG_ACB_ADDR, IDO_ACB_ADDR(r3) # Load ACB_ADDR
lwz r3, ACB_ACXB_ADDR(REG_ACB_ADDR) # Load ACXB_ADDR
branchl r12, HSD_Free
mr r3, REG_ACB_ADDR
branchl r12, HSD_Free

SKIP_SOUND:
restoreall
# Skip playing sounds
branch r12, 0x802641a8

EXIT:
restoreall
lwz r3, 0x0020(r3) # replaced code line
