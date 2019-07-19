################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us). These must not interfere with the Functions
# in Common/Common.s

# None

################################################################################
# Const Definitions
################################################################################
.set CONST_FrameFetchResult_Wait, 0
.set CONST_FrameFetchResult_Continue, 1
.set CONST_FrameFetchResult_Terminate, 2
.set CONST_FrameFetchResult_FastForward, 3

################################################################################
# Buffer Offsets
################################################################################
.set Buffer_Length,(BufferStatus_Length)+(InitialRNG_Length)+(GameFrame_Length)

# buffer status
.set BufferStatus_Start,0x0
.set BufferStatus_Length,0x1
# buffer status offsets
  .set BufferStatus_Status,0x0

# initial RNG
.set InitialRNG_Start, BufferStatus_Start + BufferStatus_Length
.set InitialRNG_Length,0x5
# initial RNG offsets
  .set InitialRNG_Status,0x0
  .set InitialRNG_Seed,0x1

# gameframe
.set GameFrame_Start, InitialRNG_Start + InitialRNG_Length
.set GameFrame_Length,(PlayerDataLength*8)
# per player offsets
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

################################################################################
# Game Info Buffer Offsets
################################################################################
  .set GameInfoLength, SuccessBool.Length + InfoRNGSeed.Length + MatchStruct.Length + UCFToggles.Length + NametagData.Length + PALBool.Length + PSPreloadBool.Length + FrozenPSBool.Length
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
  .set PALBool,0x19D
    .set PALBool.Length,0x1
  .set PSPreloadBool,0x19E
    .set PSPreloadBool.Length,0x1
  .set PSPreloadBool,0x19E
    .set PSPreloadBool.Length,0x1
  .set FrozenPSBool,0x19F
    .set FrozenPSBool.Length,0x1
