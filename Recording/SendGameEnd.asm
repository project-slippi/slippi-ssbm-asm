################################################################################
# Address: 0x8016d884 # SceneThink_VSMode after scene function handler
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"
.include "Online/Online.s"

################################################################################
# Routine: SendGameEnd
# ------------------------------------------------------------------------------
# Description: Send information about the end of a game to Slippi Device
################################################################################

.set REG_Buffer,29
.set REG_GameEndID,26
.set REG_SceneThinkStruct,25
.set REG_RDB,24

.set REG_MatchEndStruct,23
.set REG_MatchEndPlayerStruct,22
.set REG_PlayerSlot,21
.set REG_GAME_END_STRUCT_ADDR, 20

backup

# check if VS Mode
  branchl r12,FN_ShouldRecord
  cmpwi r3,0x0
  beq Injection_Exit

# check if game end ID != 0
  load REG_SceneThinkStruct,0x8046b6a0
  lbz REG_GameEndID,0x8(REG_SceneThinkStruct)
  cmpwi REG_GameEndID,0
  beq Injection_Exit

# check if we have previously sent game end message (don't send more than once)
  lwz REG_RDB, primaryDataBuffer(r13)
  lbz r3, RDB_GAME_END_SENT(REG_RDB)
  #logf LOG_LEVEL_NOTICE, "Checking game end sent: %d", "mr r5, 3"
  cmpwi r3, 0
  bne Injection_Exit # If game end already sent, do nothing more

# Need to do some additional checks for rollback to make sure game is confirmed
# complete
  getMinorMajor r3
  cmpwi r3, SCENE_ONLINE_IN_GAME
  bne StartWrite # If not online in-game, just write end
  cmpwi REG_GameEndID,0x2 # Check if GAME! end
  bne StartWrite
  lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
  lbz r3, ODB_IS_GAME_OVER(r3)
  #logf LOG_LEVEL_NOTICE, "Game end being checked %d", "mr r5, 3"
  cmpwi r3, 0
  beq Injection_Exit # If game is not over yet, don't send game end

StartWrite:
# get buffer
  lwz REG_Buffer, RDB_TXB_ADDRESS(REG_RDB)

# request game information from slippi
  li r3, CMD_GAME_END
  stb r3, GAME_END_TXB_COMMAND(REG_Buffer)

# store byte that will tell us whether the game was won by stock loss or by ragequit (2 = stock loss, 7 = no contest)
  stb REG_GameEndID, GAME_END_TXB_END_METHOD(REG_Buffer)

LRAStartCheck:
# check if LRA start
  cmpwi REG_GameEndID,0x7
  bne NoLRAStart
# find Who LRA Started
  lbz r3,0x1(REG_SceneThinkStruct)
  b StoreLRAStarter
NoLRAStart:
  li  r3,-1
StoreLRAStarter:
  stb r3, GAME_END_TXB_LRAS_INITIATOR(REG_Buffer)

# What this is going to do is add an array of placement u8s for each port
PlayerPlacements:

load REG_GAME_END_STRUCT_ADDR, 0x80479da4

################################################################################
# Initialize the MatchEndData early. Normally his happens on scene transition
# around 0x8016ea1c but we need it earlier (now) to determine the result of
# the match
################################################################################
mr r3, REG_GAME_END_STRUCT_ADDR # dest
load r4, 0x8046b8ec # source
li r5, 8824 # size
branchl r12, memcpy

load r4, 0x8046b6a0
mr r3, REG_GAME_END_STRUCT_ADDR
lbz r0, 0x24D0(r4)
stb r0, 0x6(r3)
lbz r0, 0x0008(r4)
stb r0, 0x4(r3)
branchl r12, 0x80166378 # CreateMatchEndData (struct @ 80479da4)
 
PlayerPlacementsLoopInit:
li REG_PlayerSlot, 0 # Start at slot 1
PlayerPlacementsLoopStart:
  # find player placement for this slot
  mr r3, REG_PlayerSlot
  bl FN_GetPlayerPlacement

  # write placement result to buffer
  addi r4, REG_PlayerSlot, GAME_END_TXB_PLACEMENTS
  stbx r3, r4, REG_Buffer # Write placement to buffer

PlayerPlacementsLoopCheck:
  addi REG_PlayerSlot,REG_PlayerSlot,0x1
  cmpwi REG_PlayerSlot,3
  ble PlayerPlacementsLoopStart
PlayerPlacementsLoopEnd:
PlayerPlacementsEnd:

#------------- Transfer Buffer ------------
  mr  r3,REG_Buffer
  li  r4,GAME_END_TXB_SIZE
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer

# Indicate game end has been sent
  li r3, 1
  stb r3, RDB_GAME_END_SENT(REG_RDB)
  #logf LOG_LEVEL_NOTICE, "Wrote game end sent"
  b Injection_Exit

################################################################################
# Function: FN_GetPlayerPlacement
################################################################################
# Determines the player standing in last match for a given player slot
# Inputs:
# r3: Player slot (starting at 1)
# Outputs:
# r3: Player placement
################################################################################
FN_GetPlayerPlacement:

load r12, 0x80479da4 # MatchEndStruct
mulli r11, r3, 0xA8
add r11, r11, r12 # MatchEndPlayerStruct

#Check if player partook in last game
lbz r3, 0x58(r11)
cmpwi r3, 3
beq FN_GetPlayerPlacementPlayerMissing

lbz r3, 0x5E(r11) # offset to player standing
b FN_GetPlayerPlacementReturn

FN_GetPlayerPlacementPlayerMissing:
li r3, -1

FN_GetPlayerPlacementReturn:
blr


Injection_Exit:
  restore
  lwz	r12, 0x2514 (r31)
