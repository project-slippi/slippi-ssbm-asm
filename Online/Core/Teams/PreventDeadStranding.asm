################################################################################
# Address: 0x8016be28 # Pause_CheckButtonInputsToPause right after checking if
# player is in sleep after death
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# r3 holds boolean for is asleep or not (can or cannot take lives)
# leave r3 as is and exit if the player can pause
cmpwi r3, 0
beq EXIT

# Ensure that this is an online match
getMinorMajor r4
cmpwi r4, SCENE_ONLINE_IN_GAME
bne EXIT

# Ensure this is only on teams
lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
bne EXIT

lwz r4, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r4, ODB_IS_DISCONNECTED(r4)
cmpwi r4, 1
beq EXIT_IS_WOKE

b EXIT

EXIT_IS_WOKE:
li r3, 0
b EXIT

EXIT:
cmpwi r3, 0 # original line
