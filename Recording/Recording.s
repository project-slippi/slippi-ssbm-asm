.set MAX_ITEMS, 15

# Payload lengths, if any additional data is added, these must be incremented
.set MESSAGE_DESCRIPTIONS_PAYLOAD_LENGTH, 19 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 418 # byte count
.set GAME_INITIAL_RNG_PAYLOAD_LENGTH, 8 #byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 63 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 52 # byte count
.set GAME_ITEM_INFO_PAYLOAD_LENGTH, 35 # byte count
.set GAME_END_PAYLOAD_LENGTH, 2 # byte count

# Calculate out the maximum buffer length that will be needed. This buffer
# is also used for transferring message descriptions and game info but that
# length should be less than the frame buf length
.set SUPPORTED_PORTS, 4
.set MAX_CHARACTERS, SUPPORTED_PORTS * 2 // ICs
.set TOTAL_INITIAL_RNG_LEN, GAME_INITIAL_RNG_PAYLOAD_LENGTH + 1
.set TOTAL_CHAR_FRAME_LEN, MAX_CHARACTERS * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + MAX_CHARACTERS * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1)
.set TOTAL_ITEM_LEN, MAX_ITEMS * (GAME_ITEM_INFO_PAYLOAD_LENGTH + 1)
.set TOTAL_GAME_END_LEN, GAME_END_PAYLOAD_LENGTH + 1
.set FULL_FRAME_DATA_BUF_LENGTH, TOTAL_INITIAL_RNG_LEN + TOTAL_CHAR_FRAME_LEN + TOTAL_ITEM_LEN + TOTAL_GAME_END_LEN

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
