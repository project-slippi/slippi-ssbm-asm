.set MAX_ITEMS, 15

# Command Bytes
.set CMD_DESCRIPTIONS, 0x35
.set CMD_GAME_INFO, 0x36
.set CMD_INITIAL_RNG, 0x3A
.set CMD_PRE_FRAME, 0x37
.set CMD_POST_FRAME, 0x38
.set CMD_ITEM, 0x3B
.set CMD_FRAME_BOOKEND, 0x3C
.set CMD_GAME_END, 0x39
.set COMMAND_COUNT, 8 # number of possible commands

# Payload lengths, if any additional data is added, these must be incremented
.set MESSAGE_DESCRIPTIONS_PAYLOAD_LENGTH, 3 * (COMMAND_COUNT - 1) + 1 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 418 # byte count
.set GAME_INITIAL_RNG_PAYLOAD_LENGTH, 8 #byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 63 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 52 # byte count
.set GAME_ITEM_INFO_PAYLOAD_LENGTH, 37 # byte count
.set GAME_FRAME_BOOKEND_PAYLOAD_LENGTH, 4 # byte count
.set GAME_END_PAYLOAD_LENGTH, 2 # byte count

# Calculate out the maximum buffer length that will be needed. This buffer
# is also used for transferring message descriptions and game info but that
# length should be less than the frame buf length
.set SUPPORTED_PORTS, 4
.set MAX_CHARACTERS, SUPPORTED_PORTS * 2 # ICs
.set TOTAL_INITIAL_RNG_LEN, GAME_INITIAL_RNG_PAYLOAD_LENGTH + 1
.set TOTAL_CHAR_FRAME_LEN, MAX_CHARACTERS * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + MAX_CHARACTERS * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1)
.set TOTAL_ITEM_LEN, MAX_ITEMS * (GAME_ITEM_INFO_PAYLOAD_LENGTH + 1)
.set TOTAL_FRAME_BOOKEND_LEN, GAME_FRAME_BOOKEND_PAYLOAD_LENGTH + 1
.set TOTAL_GAME_END_LEN, GAME_END_PAYLOAD_LENGTH + 1
.set FULL_FRAME_DATA_BUF_LENGTH, TOTAL_INITIAL_RNG_LEN + TOTAL_CHAR_FRAME_LEN + TOTAL_ITEM_LEN + TOTAL_FRAME_BOOKEND_LEN + TOTAL_GAME_END_LEN

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 3.0.0
.set CURRENT_VERSION,0x03000000

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
