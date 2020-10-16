################################################################################
# Address: 0x800163fc
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set  REG_Buffer,31
.set  REG_FileString,30

# Original
  mr	REG_FileString, r3      #save pointer to file string

# Init
  backup
  lwz REG_Buffer,OFST_R13_SB_ADDR(r13)
# Ensure buffer exists
  cmpwi REG_Buffer,0
  bne  GetFileLength_REQUEST_DATA
  restore
  b GetFileLength_NO_REPLACEMENT

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
# restore stack frame
  mr  r3,REG_Buffer
  restore
# Check if Slippi has a replacement file
  lwz r3,0x0(r3)
  cmpwi r3,0
  ble GetFileLength_NO_REPLACEMENT

GetFileLength_HAS_REPLACEMENT:
# Exit injection and return slippi's file's length
  branch  r12,0x80016488

GetFileLength_NO_REPLACEMENT:
# Resume the original function
  mr  r3, REG_FileString
