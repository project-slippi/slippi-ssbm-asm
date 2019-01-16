#To be inserted at 8016d304
################################################################################
#                      Inject at address 8016d304
# Function is SceneThink_VSMode and we're ending the game when slippi detects
# an LRA-Start
################################################################################
.include "../Common/Common.s"
.include "Playback.s"

# gameframe offsets
.set GameFrameLength,(FrameHeaderLength+PlayerDataLength*8)
# header
.set FrameHeaderLength,0x1
.set Status,0x0
# per player
.set PlayerDataLength,0x2D
.set RNGSeed,0x00
.set AnalogX,0x04
.set AnalogY,0x08
.set CStickX,0x0C
.set CStickY,0x10
.set Trigger,0x14
.set Buttons,0x18
.set XPos,0x1C
.set YPos,0x20
.set FacingDirection,0x24
.set ActionStateID,0x28
.set AnalogRawInput,0x2C
#.set Percentage,0x2C

# gameinfo offsets
.set GameInfoLength,0x15D
.set SuccessBool,0x0
.set InfoRNGSeed,0x1
.set MatchStruct,0x5
.set UCFToggles,0x13D

#Check status of frame received
  lwz r3,frameDataBuffer(r13)
  lbz r3,Status(r3)
  cmpwi r3, CONST_FrameFetchResult_Continue
  beq Exit
END_GAME:
  li  r3,-1  #Unk
  li  r4,7   #GameEnd ID (7 = LRA Start)
  branchl r12,0x8016cf4c
  branch r12,0x8016d30c     #Exit SceneThink_VSMode
  #branch r12,0x8016d2dc    #creates GAME! end graphic

Exit:
# Original Codeline
  mr	r3, r31
