################################################################################
# Address: 0x801b1630
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online in-game
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT # If not online in game

# This will cause the next scene to be CSS
load r4, 0x80479d30
li r3, 0x01
stb r3, 0x5(r4)

EXIT:
lwz r0, 0x001C(sp)
