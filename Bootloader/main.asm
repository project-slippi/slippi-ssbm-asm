################################################################################
# Address: 803753b0
################################################################################

################################################################################
# Function: Bootloader
# ------------------------------------------------------------------------------
# Description: Requests codeset length and receives codeset file. Permanently
# allocates memory for the codeset in the heap.
# ------------------------------------------------------------------------------
# In: r3 = pointer to buffer
#     r4 = buffer length
#     r5 = read (0x0) or write (0x1)
################################################################################
.include "Common/Common.s"

.set  REG_HeapLo,31
.set  REG_FileSize,28
.set  REG_File,27
.set  REG_HeapID,26
.set  REG_Buffer,25

# Original codeline
  stw	r31, -0x3FE8 (r13)

backup

#Create a temp heap for getting the codeset size
  addi r4,REG_HeapLo,32 + 32              #heap hi, 32 bytes padding?
  mr  r3,REG_HeapLo                  #heap lo = start
  branchl r12,0x803440e8
  mr  REG_HeapID,r3

# Alloc temp buffer
  mr  r3,REG_HeapID
  li  r4,32
  branchl r12,0x80343ef0
  mr  REG_Buffer,r3

# request gct size from slippi
  li r3, CONST_SlippiCmdGctLength        # store gct length request ID
  stb r3,0x0(REG_Buffer)
# Transfer buffer over DMA
  mr  r3,REG_Buffer    #Buffer Pointer
  li  r4,1                 #Buffer Length = command
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
# Receive response
  mr  r3,REG_Buffer
  li  r4,4                #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer
# Read file size off buffer
  lwz REG_FileSize,0x0(REG_Buffer)

# Destroy the temp heap
  mr  r3,REG_HeapID
  branchl r12,0x80344154

#Align
  addi  REG_FileSize,REG_FileSize,31
  rlwinm	REG_FileSize, REG_FileSize, 0, 0, 26
#Create heap of this size
  add r4,REG_HeapLo,REG_FileSize     #heap hi = start + filesize
  mr  r3,REG_HeapLo                  #heap lo = start
  mr  REG_HeapLo,r4                  #new start = heap hi
  branchl r12,0x803440e8
  mr  REG_HeapID,r3
#Alloc from this heap
  mr  r3,REG_HeapID
  mr  r4,REG_FileSize
  branchl r12,0x80343ef0
  mr  REG_Buffer,r3

#Load file here
  li r3, CONST_SlippiCmdGctLoad        # store gct length request ID
  stb r3,0x0(REG_Buffer)
  stw REG_Buffer,0x1(REG_Buffer)         # store buffer address to buffer
# Transfer buffer over DMA
  mr  r3,REG_Buffer    #Buffer Pointer
  li  r4,5             #Buffer Length = command + address
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
# Receive response
  mr  r3,REG_Buffer
  mr  r4,REG_FileSize                #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer

  stw	REG_HeapLo, -0x3FE8 (r13)   # store new heap low

Exit:
  restore
