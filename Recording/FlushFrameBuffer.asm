################################################################################
# Address: 803219ec
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"
.include "Online/Online.s"

################################################################################
# Routine: FlushFrameBuffer
# ------------------------------------------------------------------------------
# Description: Flush the buffer once per frame to actually send the frame data
################################################################################

# struct offsets
.set  OFST_CMD,0x0
.set  OFST_FRAME,OFST_CMD+0x1
.set  OFST_LATEST_FINALIZED_FRAME,OFST_FRAME+0x4
.set  BOOKEND_STRUCT_SIZE,OFST_LATEST_FINALIZED_FRAME+0x4

# registers
.set REG_Buffer,30
.set REG_BufferOffset,29
.set REG_WritePos,28

backup

#Check if VS Mode
  branchl r12,FN_ShouldRecord
  cmpwi r3,0x0
  beq Injection_Exit

# get buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_WritePos,REG_Buffer,REG_BufferOffset

# check if buffer length is 0
  cmpwi REG_BufferOffset,0
  beq Injection_Exit

# add frame bookend to transfer buffer
# send data
# initial RNG command byte
  li r3,CMD_FRAME_BOOKEND
  stb r3,OFST_CMD(REG_WritePos)
# send frame count
  lwz r3,frameIndex(r13)
  stw r3,OFST_FRAME(REG_WritePos)

# send the latest finalized frame index. This is only relevant during rollback
# where we continue on with frames when their contents may change later.
# Having this here helps any kind of real-time system listening to the file
# wait until a frame will no longer change before processing it
  getMinorMajor r3
  cmpwi r3, SCENE_ONLINE_IN_GAME
  lwz r3,frameIndex(r13)
  bne WRITE_FINALIZED_FRAME
# Convert latest online frame index to replay frame index format
  lwz r5, OFST_R13_ODB_ADDR(r13) # data buffer address
  lbz r4, ODB_IS_DISCONNECTED(r5)
  cmpwi r4, 0
  bne WRITE_FINALIZED_FRAME # If disconnected, just write the current frame
  lbz r4, ODB_IS_GAME_OVER(r5)
  cmpwi r4, 0
  bne WRITE_FINALIZED_FRAME # If game is over, just write the current frame
  lwz r4, ODB_STABLE_OPNT_FRAME_NUMS(r5)
  addi r4, r4, CONST_FirstFrameIdx
  cmpw r4, r3
  bge WRITE_FINALIZED_FRAME # If latest frame greater than current frame, use current
  mr r3, r4
WRITE_FINALIZED_FRAME:
  stw r3,OFST_LATEST_FINALIZED_FRAME(REG_WritePos)

# increment buffer offset, we dont need to write it to memory because it's
# about to get cleared anyway
  addi REG_BufferOffset,REG_BufferOffset,BOOKEND_STRUCT_SIZE

#------------- Transfer Buffer ------------
  mr  r3,REG_Buffer
  mr  r4,REG_BufferOffset
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer

# reset buffer offset
  li  r3,0
  stw r3,bufferOffset(r13)

Injection_Exit:
  restore
  lwz r0, 0x001C (sp)
