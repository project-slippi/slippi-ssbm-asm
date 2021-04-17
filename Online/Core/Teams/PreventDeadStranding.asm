################################################################################
# Address: 0x8016be28 # Pause_CheckButtonInputsToPause right after checking if
# player is in sleep after death
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_IS_ASLEEP, 14
.set REG_ODB_ADDRESS, 15

backup

# r3 holds boolean for is asleep or not (can or cannot take lives)
mr REG_IS_ASLEEP, r3

# leave r3 as is and exit if the player can pause
cmpwi REG_IS_ASLEEP, 0
beq EXIT_AND_RESTORE

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT_AND_RESTORE

# Ensure this is only on teams
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
bne EXIT_AND_RESTORE

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_IS_DISCONNECTED(REG_ODB_ADDRESS)
cmpwi r3, 1
beq EXIT_IS_WOKE

b EXIT_AND_RESTORE

EXIT_IS_WOKE:
li r3, 0
b EXIT

EXIT_AND_RESTORE:
mr r3, REG_IS_ASLEEP

EXIT:
restore
cmpwi r3, 0 # original line
