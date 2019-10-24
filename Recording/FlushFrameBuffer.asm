#To be inserted at 802fef88
.include "../Common/Common.s"
.include "./Recording.s"

################################################################################
# Routine: FlushFrameBuffer
# ------------------------------------------------------------------------------
# Description: Flush the buffer once per frame to actually send the frame data
################################################################################

# struct offsets
.set  OFST_CMD,0x0
.set  OFST_FRAME,OFST_CMD+0x1
.set  BOOKEND_STRUCT_SIZE,OFST_FRAME+0x4

# registers
.set REG_Buffer,30
.set REG_BufferOffset,29
.set REG_WritePos,28

backup

#Check if VS Mode
  branchl r12,FN_IsVSMode
  cmpwi r3,0x0
  beq Injection_Exit

# get buffer
  lwz REG_Buffer,frameDataBuffer(r13)
  lwz REG_BufferOffset,bufferOffset(r13)
  #add REG_WritePos,REG_Buffer,REG_BufferOffset

# add frame bookend to transfer buffer
# send data
# initial RNG command byte
  #li r3,CMD_ITEM
  #stb r3,OFST_CMD(REG_Buffer)
# send frame count
  #lwz r3,frameIndex(r13)
  #stw r3,OFST_FRAME(REG_Buffer)

# check if buffer length is 0
  cmpwi REG_BufferOffset,0
  beq Injection_Exit

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
  lwz	r0, 0x0034 (sp)
