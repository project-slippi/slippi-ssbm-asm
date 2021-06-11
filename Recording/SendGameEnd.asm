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
  #exilogf LOG_LEVEL_NOTICE, "Checking game end sent: %d", "mr r5, 3"
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
  #exilogf LOG_LEVEL_NOTICE, "Game end being checked %d", "mr r5, 3"
  cmpwi r3, 0
  beq Injection_Exit # If game is not over yet, don't send game end

StartWrite:
# get buffer
  lwz REG_Buffer, RDB_TXB_ADDRESS(REG_RDB)

# request game information from slippi
  li r3, CMD_GAME_END
  stb r3,0x0(REG_Buffer)

# store byte that will tell us whether the game was won by stock loss or by ragequit (2 = stock loss, 7 = no contest)
  stb REG_GameEndID,0x1(REG_Buffer)

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
  stb r3,0x2(REG_Buffer)

#------------- Transfer Buffer ------------
  mr  r3,REG_Buffer
  li  r4,GAME_END_PAYLOAD_LENGTH+1
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer

# Indicate game end has been sent
  li r3, 1
  stb r3, RDB_GAME_END_SENT(REG_RDB)
  #exilogf LOG_LEVEL_NOTICE, "Wrote game end sent"

Injection_Exit:
  restore
  lwz	r12, 0x2514 (r31)
