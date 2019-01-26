#To be inserted at 8016d298
################################################################################
#                      Inject at address 8016d298
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the frameDataBuffer.
################################################################################
.include "../Common/Common.s"
.include "Playback.s"

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
lwz BufferPointer,frameDataBuffer(r13)

FetchFrameInfo_REQUEST_DATA:
# request game information from slippi
  li r3, CONST_SlippiCmdGetFrame        # store gameframe request ID
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
  li  r4,GameFrameLength     #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer
# Check if successful
  lbz r3,Status(BufferPointer)
  cmpwi r3, CONST_FrameFetchResult_Wait
  bne FetchFrameInfo_Exit # If we are not told to wait, exit
# Wait a frame before trying again
  branchl r12,0x8034f314     #VIWaitForRetrace
# Here we need to flush the pad queue, this is required to prevent the game
# engine from trying to catch up for lost time which would cause a very
# jittery playback experience. Credit to tauKhan for this
  branchl r12,0x80376d04 #HSD_PadFlushQueue
  
#region debug section
.if debugFlag==1
# OSReport
  lwz r4,frameIndex(r13)
  bl  WaitAFrameText
  mflr r3
  branchl r12,0x803456a8
.endif
#endregion

  b FetchFrameInfo_REQUEST_DATA

#region debug section
.if debugFlag==1
b FetchFrameInfo_Exit
#################################
WaitAFrameText:
blrl
.string "Waiting on frame %d"
.align 2
#################################
.endif
#endregion

FetchFrameInfo_Exit:
  restore
#-----------------------------------------------

Exit:
# Original Codeline
  lbz	r0, 0x0008 (r31)
