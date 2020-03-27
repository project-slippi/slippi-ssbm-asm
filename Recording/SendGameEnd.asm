################################################################################
# Address: 8016d30c
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendGameEnd
# ------------------------------------------------------------------------------
# Description: Send information about the end of a game to Slippi Device
################################################################################

.set REG_PlayerData,30
.set REG_Buffer,29
.set REG_BufferOffset,28
.set REG_PlayerSlot,27
.set REG_GameEndID,26
.set REG_SceneThinkStruct,25

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

# get buffer
  lwz REG_Buffer,primaryDataBuffer(r13)

# request game information from slippi
  li r3, CMD_GAME_END
  stb r3,0x0(REG_Buffer)

# store byte that will tell us whether the game was won by stock loss or by ragequit (2 = stock loss, 7 = no contest)
  stb REG_GameEndID,0x1(REG_Buffer)

# check if sudden death


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

Injection_Exit:
  restore
  lwz	r0, 0x003C (sp)
