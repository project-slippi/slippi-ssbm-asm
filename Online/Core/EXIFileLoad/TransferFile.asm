################################################################################
# Address: 0x800166b8
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set  REG_Buffer,31
.set  REG_FileString,30
.set  REG_FileLength,29
.set  REG_FileAlloc,27 # Set by parent function

# Original
  mr	REG_FileString, r3      #save pointer to file string

# Init
  backup
  lwz REG_Buffer,OFST_R13_SB_ADDR(r13)

# Ensure buffer exists
  cmpwi REG_Buffer,0
  beq  TransferFile_NO_REPLACEMENT

#########################
## Check if file exits ##
#########################
GetFileLength_REQUEST_DATA:
# request game information from slippi
  li r3, CONST_SlippiCmdFileLength        # store file length request ID
  stb r3,0x0(REG_Buffer)
# copy file name to buffer
  addi  r3,REG_Buffer,1
  mr  r4,REG_FileString
  branchl r12,strcpy
# get length of string
  mr  r3,REG_FileString
  branchl r12,strlen
# Transfer buffer over DMA
  addi  r4,r3,2            #Buffer Length = strlen + command byte + \0
  mr  r3,REG_Buffer        #Buffer Pointer
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
GetFileLength_RECEIVE_DATA:
# Transfer buffer over DMA
  mr  r3,REG_Buffer
  li  r4,0x4               #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer
GetFileLength_CHECK_STATUS:
# Check if Slippi has a replacement file
  lwz REG_FileLength,0x0(REG_Buffer)
  cmpwi REG_FileLength,0
  ble TransferFile_NO_REPLACEMENT

###################
## Get file data ##
###################

TransferFile_HAS_REPLACEMENT:
  stw	REG_FileLength, 0(r28) # Parent function normally does this
# request file data
  li r3, CONST_SlippiCmdFileLoad        # store file length request ID
  stb r3,0x0(REG_Buffer)
# copy file name to buffer
  addi  r3,REG_Buffer,1
  mr  r4,REG_FileString
  branchl r12,strcpy
# get length of string
  mr  r3,REG_FileString
  branchl r12,strlen
# Transfer buffer over DMA
  addi  r4,r3,2            #Buffer Length = strlen + command byte + \0
  mr  r3,REG_Buffer        #Buffer Pointer
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
TransferFile_RECEIVE_DATA:
# Transfer buffer over DMA
  mr  r3,REG_FileAlloc
  mr  r4,REG_FileLength    #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer
TransferFile_EXIT:
# Exit injection and return 1 (success)
  restore
  li  r3,1
  branch  r12,0x8001674c

#########################
## No replacement file ##
#########################

TransferFile_NO_REPLACEMENT:
# Resume the original function
  restore
  mr  r3, REG_FileString
