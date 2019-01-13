#To be inserted at 8016d004
################################################################################
#                      Inject at address 8016d004
# Function is SceneThink_VSMode and we're incrementing the frame index
# before anything "game-engine related" happens
################################################################################
.include "../Common/Common.s"

# Original Codeline
  stw	r28, 0x0028 (sp)

# Check if its the first frame (initialize timer)
  lis r3,0x8048
  lwz r3,-0x62A8(r3) # load scene controller frame count
  cmpwi r3,0x0
  bne IncrementFrameIndex

InitIndex:
  li  r3,-123
  stw r3,frameIndex(r13)
  b Exit

IncrementFrameIndex:
  lwz r3,frameIndex(r13)
  addi r3,r3,1
  stw r3,frameIndex(r13)

Exit:
