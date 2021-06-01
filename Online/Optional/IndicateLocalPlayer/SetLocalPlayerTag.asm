################################################################################
# Address: 0x802fd1ec
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

b CODE_START

TAG_BLRL:
blrl
# Nametag (YOU)
.long 0x8278826e
.long 0x82740000

.set REG_PLAYER_SLOT, 27 # from parent

CODE_START:
# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne RUN_ORIGINAL

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_LOCAL_PLAYER_INDEX(r3)

# Check if this is the local player
cmpw r3, REG_PLAYER_SLOT
bne RUN_ORIGINAL

# Let's set r3 to the YOU nametag above
# TODO: If it ever becomes possible to set nametags, we probably would want to prioritize those
bl TAG_BLRL
mflr r3
b EXIT

RUN_ORIGINAL:
# Run original logic to fetch nametag
mr r3, REG_PLAYER_SLOT
branchl r12, 0x8003556c # PlayerBlock_LoadNameTagSlot#
rlwinm r3, r3, 0, 24, 31
branchl r12, 0x8023754c # Nametag_LoadNametagSlotText

EXIT: