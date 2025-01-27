################################################################################
# Address: 80211bf8
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendDreamlandInfo
# ------------------------------------------------------------------------------
# Sends whispy wind direction when it changes.
################################################################################

.set REG_Buffer,11
.set REG_BufferOffset,12

b Start
STATIC_PREVIOUS_VALUE:
  blrl
  .long 0x00000000

Start:
  # check if VS Mode
  branchl r12,FN_ShouldRecord
  cmpwi r3,0x0
  beq Skip

  bl STATIC_PREVIOUS_VALUE
  mflr r3

  # on first frame, initialize previous value to no wind. this prevents a situation where if
  # the previous game on DL ended with wind blowing, we wont get an event indicating no wind
  # at the start of the next game
  lwz r4, frameIndex(r13)
  cmpwi r4, CONST_FirstFrameIdx
  bne ContinueCheck
  li r4, 0
  stw r4, 0(r3)

ContinueCheck:
  lwz r4, 0(r3)
  lwz r5,0xdc(r31)
  cmpw r4, r5
  beq Skip
  stw r5, 0(r3)

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset

# send stage info event code
  li r3, CMD_DL_INFO
  stb r3,0x0(REG_Buffer)

# send frame index
  lwz r3,frameIndex(r13)
  stw r3,0x1(REG_Buffer)

# send wind direction (0 = none, 1 = left, 2 = right)
  stb r5,0x5(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,DL_INFO_PAYLOAD_LENGTH+1
  stw REG_BufferOffset,bufferOffset(r13)

Skip:
  lmw r26, 0xe8(r1) #execute replaced code line

