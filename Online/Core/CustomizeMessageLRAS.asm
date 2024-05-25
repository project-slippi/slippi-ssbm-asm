################################################################################
# Address: 0x802f7094 # HUD_DisplayEndingExclaimationGraphic
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_MATCH_INFO, 3 # From parent, should make sure this doesn't change
# r4-r6 have all been set to the values to be passed to graphic display function, use r7+

# Ensure that this is an online match
getMinorMajor r7
cmpwi r7, SCENE_ONLINE_IN_GAME
bne EXIT

# It seems like on an LRAS where pause is still on/normal, we don't get into this function
# anyway, so we don't have to worry about direct mode's LRAS

# Ensure the game ended as an LRAS
lbz r7, 0x8(REG_MATCH_INFO)
cmpwi r7, 7
bne EXIT

# Store the index of the person that paused
lbz r10, 0x1(REG_MATCH_INFO)

################################################################################
# It's safe to change r3 now cause we are exiting the function
################################################################################

# If this happens in ranked, it's a disconnect, don't play sound as error sound will have played
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_RANKED
bne CHECK_LRAS

# If ranked, play error sound. For some reason the one in StartEngineLoop doesn't play
li r3, 3
b PLAY_SOUND

CHECK_LRAS:
# Fetch the index of the local player
lwz r11, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_LOCAL_PLAYER_INDEX(r11)
cmpw r3, r10 # Compare local player index to index of pauser
beq SKIP_PLAY_SOUND

# Play SFX
li r3, 5
PLAY_SOUND:
branchl r12, SFX_Menu_CommonSound
SKIP_PLAY_SOUND:

# branch r12, 0x802f70fc # Failure
# branch r12, 0x802f7110 # Game!
branch r12, 0x802f7120 # Exit function, shows nothing and plays no sound

EXIT:
lbz	r8, 0x000B(REG_MATCH_INFO) # Replaced codeline