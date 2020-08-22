################################################################################
# Address: 0x8008a478 # Changes color to green
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"

.set REG_FighterData,31

# Player slot is at 0xC(r5) r7 and r8 seem like they should be safe to use
# as they get overwitten in the GetLCancelStatus code
# Ensure that this is an online in-game
getMinorMajor r7
cmpwi r7, SCENE_ONLINE_IN_GAME
bne CODE_START # If not online in game, run code as normal

# If we are online in game, let's make sure this port is the local player port
lwz r7, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r7, ODB_LOCAL_PLAYER_INDEX(r7)
lbz r8, 0xC(REG_FighterData) # Load port of current character
cmpw r7, r8
bne Exit

CODE_START:
# store green
bl  Floats
mflr  r5
lfs f1,0x0(r5)
stfs f1, 0x488 + 0x34(REG_FighterData)  # green
lfs f1,0x4(r5)
stfs f1, 0x488 + 0x3C(REG_FighterData)  # alpha

# blank out others
li  r3,0
stw r3, 0x488 + 0x38(REG_FighterData)
stw r3, 0x488 + 0x30(REG_FighterData)
stw r3, 0x488 + 0x40(REG_FighterData)
stw r3, 0x488 + 0x44(REG_FighterData)
stw r3, 0x488 + 0x48(REG_FighterData)
stw r3, 0x488 + 0x4C(REG_FighterData)

# enable
li  r3,1
lbz r4, 0x488 + 0x7C(REG_FighterData)
rlwimi r4,r3,7,31-7,31-7
stb r4, 0x488 + 0x7C(REG_FighterData)
b Exit

Floats:
blrl
.float 255
.float 180

Exit:
lwz	r0, 0x002C (sp)
