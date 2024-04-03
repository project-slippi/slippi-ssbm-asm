################################################################################
# Address: 8016d304
################################################################################

################################################################################
#                      Inject at address 8016d304
# Function is SceneThink_VSMode and we're ending the game when slippi detects
# an LRA-Start
################################################################################
.include "Common/Common.s"
.include "Playback/Playback.s"

# Check status of frame received. If a terminate result is received, that means
# we need to end the game immediately
  lwz r3,playbackDataBuffer(r13)
  lwz r3,PDB_EXI_BUF_ADDR(r3)
  lbz r3,(BufferStatus_Start)+(BufferStatus_Status)(r3)
  cmpwi r3, CONST_FrameFetchResult_Terminate
  bne Exit # If we are not terminating, skip

END_GAME:
  li  r3,-1  #Unk
  li  r4,7   #GameEnd ID (7 = LRA Start)
  branchl r12, NoContestOrRetry_
  branch r12,0x8016d30c     #Exit SceneThink_VSMode
  #branch r12,0x8016d2dc    #creates GAME! end graphic

Exit:
# Original Codeline
  mr	r3, r31
