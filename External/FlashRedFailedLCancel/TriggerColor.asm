################################################################################
# Address: 0x8008D690 # Triggers the flash on failed l-cancel
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Player slot is at 0xC(r5) r7 and r8 seem like they should be safe to use
# as they get overwitten in the GetLCancelStatus code
# Ensure that this is an online in-game
getMinorMajor r7
cmpwi r7, SCENE_ONLINE_IN_GAME
bne CODE_START # If not online in game, run code as normal

# If we are online in game, let's make sure this port is the local player port
lwz r7, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r7, ODB_LOCAL_PLAYER_INDEX(r7)
lbz r8, 0xC(r5) # Load port of current character
cmpw r7, r8
beq CODE_START

# If not our port, just set r5 and exit
lbz r5, 1663(r5)
b EXIT

CODE_START:
lbz r5, 1663(r5)
cmpwi r5, 0x7
blt- EXIT
li r15, 0xD4
stb r15, 1380(r3)

EXIT:
