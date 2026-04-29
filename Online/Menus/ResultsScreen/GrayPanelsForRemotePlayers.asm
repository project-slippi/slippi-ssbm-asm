################################################################################
# Address: 0x8017900C
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# This injection overwrites a call for HUD_GetPlayerColorIndex which is used to color
# the player panels on the results screen. In order to make it easier to know which
# player you were, we are going to gray out all the remote player's panels by
# telling this function they were CPUs.

# IMPORTANT: r3-r6 are already configured with args for the function, don't change
# them unless intentional

getMinorMajor r7
cmpwi r7, SCENE_ONLINE_RESULTS
bne EXIT # If not online results, continue as normal

fetchOnlineStaticDataPtr r7
lbz r8, OSD_LOCAL_PLAYER_INDEX(r7)
cmpw r8, r3 # Compared local player to current port
beq EXIT

# If this is not the local player, overwrite slot_type to say this is a CPU.
# That will cause the panel to use the color gray
li r6, 1

EXIT:
# int HUD_GetPlayerColorIndex(byte port,byte team,char is_teams,char slot_type)
branchl r12, 0x80160854 # HUD_GetPlayerColorIndex