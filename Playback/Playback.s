################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us). These must not interfere with the Functions
# in Common/Common.s

# None

.macro loadGlobalFrame reg
lis \reg, 0x8048
lwz \reg, -0x62A0(\reg)
.endm

################################################################################
# Const Definitions
################################################################################
.set CONST_FrameFetchResult_Wait, 0
.set CONST_FrameFetchResult_Continue, 1
.set CONST_FrameFetchResult_Terminate, 2
.set CONST_FrameFetchResult_FastForward, 3

################################################################################
# Command Bytes
################################################################################
.set CMD_GET_GAME_INFO, 0x75
.set CMD_GET_FRAME, 0x76
.set CMD_IS_REPLAY_READY, 0x88
.set CMD_IS_STOCK_STEAL,0x89
.set CMD_GET_GECKO_CODES,0x8A

################################################################################
# SFX Storage
################################################################################
.set MAX_SOUNDS_PER_FRAME, 0x10
.set SOUND_STORAGE_FRAME_COUNT, 7

.set SFXS_ENTRY_SOUND_ID, 0 # u16, ID of the sound played
.set SFXS_ENTRY_INSTANCE_ID, SFXS_ENTRY_SOUND_ID + 2 # u32
.set SFXS_ENTRY_SIZE, SFXS_ENTRY_INSTANCE_ID + 4

.set SFXS_LOG_INDEX, 0 # u8, Index where we are in the frame
.set SFXS_LOG_ENTRIES, SFXS_LOG_INDEX + 1 # SFXS_ENTRY_SIZE * MAX_SOUNDS_PER_FRAME
.set SFXS_LOG_SIZE, SFXS_LOG_ENTRIES + SFXS_ENTRY_SIZE * MAX_SOUNDS_PER_FRAME

.set SFXS_FRAME_PENDING_LOG, 0 # SFXS_LOG_SIZE
.set SFXS_FRAME_STABLE_LOG, SFXS_FRAME_PENDING_LOG + SFXS_LOG_SIZE # SFXS_LOG_SIZE
.set SFXS_FRAME_SIZE, SFXS_FRAME_STABLE_LOG + SFXS_LOG_SIZE

.set SFXDB_WRITE_INDEX, 0 # u8
.set SFXDB_FRAMES, SFXDB_WRITE_INDEX + 1 # SFXS_FRAME_SIZE * SOUND_STORAGE_FRAME_COUNT
.set SFXDB_SIZE, SFXDB_FRAMES + SFXS_FRAME_SIZE * SOUND_STORAGE_FRAME_COUNT

################################################################################
# Playback Directory Buffer
################################################################################
.set PDB_EXI_BUF_ADDR, 0x0 # u32
.set PDB_SECONDARY_EXI_BUF_ADDR, PDB_EXI_BUF_ADDR + 4 # u32
.set PDB_DYNAMIC_GECKO_ADDR, PDB_SECONDARY_EXI_BUF_ADDR + 4 # u32
.set PDB_RESTORE_BUF_SIZE, PDB_DYNAMIC_GECKO_ADDR + 4 # u32
.set PDB_RESTORE_BUF_ADDR, PDB_RESTORE_BUF_SIZE + 4 # u32
.set PDB_RESTORE_BUF_WRITE_POS, PDB_RESTORE_BUF_ADDR + 4 # u32
.set PDB_RESTORE_C2_BRANCH, PDB_RESTORE_BUF_WRITE_POS + 4 # u32
.set PDB_SFXDB_START, PDB_RESTORE_C2_BRANCH + 4 # SFXDB_SIZE
.set PDB_LATEST_FRAME, PDB_SFXDB_START + SFXDB_SIZE # u32, must follow SFXDB as it is preserved
.set PDB_SHOULD_RESYNC, PDB_LATEST_FRAME + 4 # bool

.set PDB_SIZE, PDB_SHOULD_RESYNC + 1

################################################################################
# Buffer Offsets
################################################################################
# buffer status
.set BufferStatus_Start,0x0
.set BufferStatus_Length,0x1
# buffer status offsets
  .set BufferStatus_Status,0x0

# rb status
.set RBStatus_Start, BufferStatus_Start + BufferStatus_Length
.set RBStatus_Length,0x1
# rb status offsets
  .set RBStatus_Status,0x0

# initial RNG
.set InitialRNG_Start, RBStatus_Start + RBStatus_Length
.set InitialRNG_Length,0x5
# initial RNG offsets
  .set InitialRNG_Status,0x0
  .set InitialRNG_Seed,0x1

# gameframe
.set GameFrame_Start, InitialRNG_Start + InitialRNG_Length
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

.set GameFrame_Length, PlayerDataLength * 8

.set Buffer_Length, GameFrame_Start + GameFrame_Length

################################################################################
# Game Info Buffer Offsets
################################################################################
  .set SuccessBool,0x0
    .set SuccessBool_Length,0x1
  .set InfoRNGSeed,0x1
    .set InfoRNGSeed_Length,0x4
  .set MatchStruct,0x5
    .set MatchStruct_Length,0x138
  .set UCFToggles,0x13D
    .set UCFToggles_Length,0x20
  .set NametagData,0x15D
    .set NametagData_Length,0x40
  .set PALBool,0x19D
    .set PALBool_Length,0x1
  .set PSPreloadBool,0x19E
    .set PSPreloadBool_Length,0x1
  .set PSPreloadBool,0x19E
    .set PSPreloadBool_Length,0x1
  .set FrozenPSBool,0x19F
    .set FrozenPSBool_Length,0x1
  .set ShouldResyncBool,0x1A0
    .set ShouldResyncBool_Length,0x1
  .set GeckoListSize,0x1A1
    .set GeckoListSize_Length,0x4

  .set GameInfoLength, SuccessBool_Length + InfoRNGSeed_Length + MatchStruct_Length + UCFToggles_Length + NametagData_Length + PALBool_Length + PSPreloadBool_Length + FrozenPSBool_Length + ShouldResyncBool_Length + GeckoListSize_Length

  .if GameInfoLength > Buffer_Length
    .set EXIBufferLength, GameInfoLength
  .else
    .set EXIBufferLength, Buffer_Length
  .endif
