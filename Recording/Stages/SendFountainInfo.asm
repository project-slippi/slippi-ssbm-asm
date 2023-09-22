################################################################################
# Address: 801cc998
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendFountainInfo
# ------------------------------------------------------------------------------
# Sends Fount of Dreams platform heights when they change.
################################################################################

.set REG_Buffer,29
.set REG_BufferOffset,28

backup

# Check if VS Mode
  branchl r12,FN_ShouldRecord
  cmpwi r3,0x0
  beq Injection_Exit

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset

# send stage info event code
  li r3, CMD_FOD_INFO
  stb r3,0x0(REG_Buffer)

# send left/right
  lwz r3,0x38(r27)
  srwi r3, r3, 0x1f
  stb r3,0x1(REG_Buffer)

# send height
  stfs f31, 0x2(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,6
  stw REG_BufferOffset,bufferOffset(r13)

Injection_Exit:
  restore
  stfs f31, 0x3c(r27) #execute replaced code line
