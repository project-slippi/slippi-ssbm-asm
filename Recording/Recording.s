.set MEM_SLOT, 1 # 0 is SlotA, 1 is SlotB

# Payload lengths, if any additional data is added, these must be incremented
.set MESSAGE_DESCIPTIONS_PAYLOAD_LENGTH, 13 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 417 # byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 63 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 0x33 # byte count
.set GAME_END_PAYLOAD_LENGTH, 2 # byte count
.set FULL_FRAME_DATA_BUF_LENGTH, 8 * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + 8 * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1)
.set STAR_REPLAY_PAYLOAD_LENGTH, 0 # byte count
.set SECONDARY_DATA_BUF_LENGTH, 32

# Payload IDs
.set STAR_REPLAY,0x3A

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 2.0.0.0
.set CURRENT_VERSION,0x02000000

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_IsVSMode,0x80005604

################################################################################
# Custom Playerblock Offsets
################################################################################
.set PlayerBlockSize,0x2600
.set DPadDownTimer,0x25FE
.set LCancelStatus,0x25FF

################################################################################
# Custom r13 Offsets
################################################################################
.set frameDataBuffer,-0x49b4
.set secondaryDataBuffer,-0x49a8
.set bufferOffset,-0x49b0
.set frameIndex,-0x49ac
.set isStarred,-0x49a4
