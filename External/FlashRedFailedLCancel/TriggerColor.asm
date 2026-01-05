################################################################################
# Address: 0x8008D690 # Triggers the flash on failed l-cancel
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Player slot is at 0xC(r5) r12 and r11 seem like they should be safe to use
# Ensure that this is an online in-game
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_IN_GAME
bne CODE_START # If not online in game, run code as normal

# If we are online in game, let's make sure this port is the local player port
lwz r12, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r12, ODB_LOCAL_PLAYER_INDEX(r12)
lbz r11, 0xC(r5) # Load port of current character
cmpw r12, r11
beq CODE_START

# If not our port, just set r5 and exit
lbz r5, 0x67F(r5)
b EXIT

CODE_START:
lbz r5, 0x67F(r5)
cmpwi r5, 0x7
blt- EXIT
li r12, 0xD4
stb r12, 0x564(r3)

EXIT:
