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

# Ensure that this is an unranked game
lbz r7, OFST_R13_ONLINE_MODE(r13)
cmpwi r7, ONLINE_MODE_UNRANKED
bne EXIT

# TODO: Check if this is the person that paused

# branch r12, 0x802f70fc # Failure
# branch r12, 0x802f7110 # Game!
branch r12, 0x802f7120 # Exit function

EXIT:
lbz	r8, 0x000B(REG_MATCH_INFO) # Replaced codeline