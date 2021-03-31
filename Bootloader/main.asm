################################################################################
# Address: 80375380
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
  branchl r12,0x803444e0

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
  addi r4,r4, 32                     #heap hi, 32 bytes padding?
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

# Save pointer to gecko codes
  load r3,GeckoHeapPtr
  stw REG_Buffer, 0 (r3)

# Process gecko codes
  addi r3, REG_Buffer, 8 # Gecko code list start
  bl Callback_ProcessGeckoCode # Callback function to process codes
  mflr r4
  branchl r12, FN_ProcessGecko

  b Exit

Callback_ProcessGeckoCode:
blrl

.set REG_CodeAddress, 30
.set REG_TargetDataPtr, 29
.set REG_SourceDataPtr, 28
.set REG_ReplaceSize, 27

  # r5 is input to this function, it contains the size of the replaced data
  cmpwi r5, 0 # If size is 0, either we don't support this codetype or theres nothing to replace
  beq Callback_ProcessGeckoCode_End

  backup # TODO: Consider being more efficient about backup and restore?

  mr REG_CodeAddress, r4
  mr REG_ReplaceSize, r5

  lwz r5, 0(REG_CodeAddress)
  rlwinm r5, r5, 0, 0x01FFFFFF
  oris REG_TargetDataPtr, r5, 0x8000 # Injection Address

  # r3 contains the codetype, do a switch statement on it to prepare for memcpys
  cmpwi r3, 0x04
  beq HANDLE_04

  cmpwi r3, 0x06
  beq HANDLE_06

  cmpwi r3, 0xC2
  beq HANDLE_C2

  # TODO: Assert? It should not be possible to get here. Obviously we could skip
  # TODO: one of the above compares but I'd rather do an assert or something
  # TODO: here to make sure that we haven't made a code error

HANDLE_04:
  addi REG_SourceDataPtr, REG_CodeAddress, 4
  b EXEC_COPY

HANDLE_06:
  addi REG_SourceDataPtr, REG_CodeAddress, 8
  b EXEC_COPY

HANDLE_C2:
  # C2 Step 1: Copy the branch instruction that will overwrite data to buffer.
  addi r4, REG_CodeAddress, 0x8
  sub r3, r4, REG_TargetDataPtr
  rlwinm r3, r3, 0, 6, 29
  oris r3, r3, 0x4800
  stw r3, BKP_FREE_SPACE_OFFSET(sp)
  addi REG_SourceDataPtr, sp, BKP_FREE_SPACE_OFFSET

  # C2 Step 2: Replace branch instruction in gecko code to return to correct loc
  lwz r3, 0x4(REG_CodeAddress)
  mulli r3, r3, 0x8
  add r4, r3, REG_CodeAddress            # get branch back site
  addi r3, REG_TargetDataPtr, 0x4        # get branch back destination
  sub r3, r3, r4
  rlwinm r3, r3, 0, 6, 29                # extract bits for offset
  oris r3, r3, 0x4800                    # Create branch instruction from it
  subi r3, r3, 0x4                       # subtract 4 i guess
  stw r3, 0x4(r4)                        # place branch instruction

EXEC_COPY:
  # Replace data
  mr r3, REG_TargetDataPtr # destination
  mr r4, REG_SourceDataPtr # source
  mr r5, REG_ReplaceSize
  branchl r12, memcpy

  mr r3, REG_TargetDataPtr
  mr r4, REG_ReplaceSize
  branchl r12, TRK_flush_cache

  restore

Callback_ProcessGeckoCode_End:
  blr

Exit:
  restore

# overwrite r31 which stores the low bound. A few upcoming instructions rely
# on this to initialize the heap
  lwz r31, -0x3FE8(r13)
