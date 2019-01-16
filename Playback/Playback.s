################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us). These must not interfere with the Functions
# in Common/Common.s
.set FN_FetchGameFrame,0x800055f4

################################################################################
# Const Definitions
################################################################################
.set CONST_FrameFetchResult_Wait, 0
.set CONST_FrameFetchResult_Continue, 1
.set CONST_FrameFetchResult_Terminate, 2

################################################################################
# Buffer Offsets
################################################################################
# gameframe offsets
.set GameFrameLength,(FrameHeaderLength+PlayerDataLength*8)
# header
  .set FrameHeaderLength, Status.Length
  .set Status,0x0
    .set Status.Length,0x1
# per player
  .set PlayerDataLength,0x31
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
  .set Percentage,0x2D

# gameinfo offsets
  .set GameInfoLength, SuccessBool.Length + InfoRNGSeed.Length + MatchStruct.Length + UCFToggles.Length + NametagData.Length
  .set SuccessBool,0x0
    .set SuccessBool.Length,0x1
  .set InfoRNGSeed,0x1
    .set InfoRNGSeed.Length,0x4
  .set MatchStruct,0x5
    .set MatchStruct.Length,0x138
  .set UCFToggles,0x13D
    .set UCFToggles.Length,0x20
  .set NametagData,0x15D
    .set NametagData.Length,0x40
