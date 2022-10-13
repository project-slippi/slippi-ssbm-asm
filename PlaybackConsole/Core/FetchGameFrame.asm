################################################################################
# Address: 8016d298
################################################################################

################################################################################
#                      Inject at address 8016d298
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the EXI buffer.
################################################################################
.include "Common/Common.s"
.include "PlaybackConsole/Playback.s"

# Register names
.set PlayerData,31
.set PlayerGObj,30
.set PlayerSlot,29
.set PlayerDataStatic,28
.set BufferPointer,27
.set PlayerBackup,26
.set FrameNumber,25

# debug flag
.set debugFlag,0

#First, check if game ended. This isn't really strictly required except that without
#it we try to fetch a frame that doesn't exist at the end of the game.
#That causes problems when mirroring because we haven't gotten a game
#end message yet so the game will have to hang temporarily before GAME can be
#shown
  lbz	r0, 0x0008 (r31)
  cmpwi r0,0x0
  bne Exit # r0 is 2 on successful game end

  ################################################################################
  #                   subroutine: FetchGameFrame
  # description: per frame function that will handle fetching the current frame's
  # data and storing it to the buffer
  ################################################################################

FetchGameFrame:

backup
lwz r3,primaryDataBuffer(r13)
lwz BufferPointer,PDB_EXI_BUF_ADDR(r3)

FetchFrameInfo_REQUEST_DATA:
# request game information from slippi
  li r3, CMD_GET_FRAME        # store gameframe request ID
  stb r3,0x0(BufferPointer)
  lwz r3,frameIndex(r13)           #get frame to request
  stw r3,0x1(BufferPointer)
# Transfer buffer over DMA
  mr  r3,BufferPointer   #Buffer Pointer
  li  r4,0x5            #Buffer Length
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
FetchFrameInfo_RECEIVE_DATA:
# Transfer buffer over DMA
  mr  r3,BufferPointer
  li  r4,Buffer_Length     #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer

FetchFrameInfo_Exit:

  restore
#-----------------------------------------------

Exit:
# Original Codeline
  lbz	r0, 0x0008 (r31)
