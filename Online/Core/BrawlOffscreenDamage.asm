################################################################################
# Address: 0x8006a880 # PlayerThink_Animation. Function call determines if player is in bubble normally
################################################################################
# This function needs to return 1 or 0 determining whether a player is in the
# damage zone for offscreen damage. 1 means we are offscreen

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_FIGHTERDATA, 31
.set SPO_PLAYER_POS_X, 0x80 # float
.set SPO_PLAYER_POS_Y, SPO_PLAYER_POS_X + 4 # float
.set SPO_PLAYER_POS_Z, SPO_PLAYER_POS_Y + 4 # float

backup

# The Sandbag in vanilla melee doesn't take damage when offscreen
getMinorMajor r3
cmpwi r3, SCENE_HOMERUN_IN_GAME
beq RETURN_FALSE

# First check if the player is dead
lbz r3, 0x221F(REG_FIGHTERDATA)
rlwinm. r3,r3,0,0x40
bne RETURN_FALSE
# Then check for star KO and screen KO
lwz r3, 0x10(REG_FIGHTERDATA)
cmpwi r3,4
beq RETURN_FALSE
cmpwi r3,6
beq RETURN_FALSE

# Compare the players X position to the left camera bound
branchl r12, 0x80224a54 # StageInfo_CameraLimitLeft_Load
lfs f2, 0xB0(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
blt RETURN_TRUE

branchl r12, 0x80224a68 # StageInfo_CameraLimitRight_Load
lfs f2, 0xB0(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
bgt RETURN_TRUE

branchl r12, 0x80224a80 # StageInfo_CameraLimitTop_Load
lfs f2, 0xB4(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
bgt RETURN_TRUE

branchl r12, 0x80224a98 # StageInfo_CameraLimitBottom_Load
lfs f2, 0xB4(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
blt RETURN_TRUE

# Here we are inside the camera bounds, so return false
RETURN_FALSE:
li r3, 0
b RESTORE_AND_EXIT

RETURN_TRUE:
li r3, 1

RESTORE_AND_EXIT:
restore
