################################################################################
# Address: 8016e2dc
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Playback/Playback.s"

# Some skins can cause stage initialization to run extra RNG calls, this can then throw off
# the seed when Nana's CPU logic counter is initialized around 800a123c. This code resyncs the
# seed prior to initializing the players to ensure that the logic counter is initialized identically

getMinorMajor r3
cmpwi r3, SCENE_PLAYBACK_IN_GAME
beq HANDLE_PLAYBACK
cmpwi r3, SCENE_ONLINE_IN_GAME
beq HANDLE_ONLINE
b EXIT

# We have to handle the playback scene in this code because if this code is added as a dynamic
# code, it will affect initialization during replay load as well, but the seed is stored in a
# different place during playback so we can't run the same logic
HANDLE_PLAYBACK:
lwz r3, primaryDataBuffer(r13) # load directory buffer location
lwz r3, PDB_EXI_BUF_ADDR(r3)
lwz r3, InfoRNGSeed(r3)
lis r4, 0x804D
stw r3, 0x5F90(r4) #store random seed
b EXIT

HANDLE_ONLINE:
lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lwz r3, ODB_RNG_OFFSET(r3)
lis r4, 0x804D
stw r3, 0x5F90(r4) # overwrite seed

EXIT:
lbz r0, 0x0007(r31) # replaced code