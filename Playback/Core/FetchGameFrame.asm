################################################################################
# Address: 8016d298
################################################################################

################################################################################
#                      Inject at address 8016d298
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the EXI buffer.
################################################################################
.include "Common/Common.s"
.include "Playback/Playback.s"

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
# Check if successful
  lbz r3, (BufferStatus_Start)+(BufferStatus_Status) (BufferPointer)
  cmpwi r3, CONST_FrameFetchResult_Wait
  bne FetchFrameInfo_Exit # If we are not told to wait, exit
# Wait a frame before trying again
  branchl r12, VIWaitForRetrace
# Here we need to clear the pad queue, this is required to prevent the game
# engine from trying to catch up for lost time which would cause a very
# jittery playback experience. Credit to tauKhan for this
# Originally we were calling the HSD_PadFlushQueue but tauKhan said this
# could potentially cause UCF desyncs if a wait happened at a bad time
  lis r3, 0x804C
  li r0, 0
  stb r0, 0x1f7B(r3)

  b FetchFrameInfo_REQUEST_DATA

FetchFrameInfo_Exit:

# Logic so that we can bp on a very specific frame
/*
lwz r3, frameIndex(r13)
cmpwi r3, 2778
bne SKIP_BP_LINE
li r3, 0 # Dummy line where we can set a bp
SKIP_BP_LINE:
*/

  restore
#-----------------------------------------------

Exit:
# Original Codeline
  lbz	r0, 0x0008 (r31)
