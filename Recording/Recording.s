# Payload lengths, if any additional data is added, these must be incremented
.set MESSAGE_DESCRIPTIONS_PAYLOAD_LENGTH, 0x13 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 418 # byte count
.set GAME_INITIAL_RNG_PAYLOAD_LENGTH, 0x8 #byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 63 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 0x34 # byte count
.set GAME_ITEM_INFO_PAYLOAD_LENGTH, 31 # byte count
.set GAME_END_PAYLOAD_LENGTH, 2 # byte count
.set FULL_FRAME_DATA_BUF_LENGTH, 8 * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + 8 * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1) + ((GAME_ITEM_INFO_PAYLOAD_LENGTH + 1) * 15)

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 2.2.0
.set CURRENT_VERSION,0x02020000

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_IsVSMode,0x80005604

################################################################################
# Custom Playerblock Offsets
################################################################################
.set PlayerBlockSize,0x2600
.set LCancelStatus,0x25FF
