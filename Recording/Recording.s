.set MAX_ITEMS, 15

################################################################################
# Game End Transfer Buffer
################################################################################
.set GAME_END_TXB_COMMAND, 0 # u8
.set GAME_END_TXB_END_METHOD, GAME_END_TXB_COMMAND + 1 # u8
.set GAME_END_TXB_LRAS_INITIATOR, GAME_END_TXB_END_METHOD + 1 # u8
.set GAME_END_TXB_PLACEMENTS, GAME_END_TXB_LRAS_INITIATOR + 1 # u8[4]
.set GAME_END_TXB_SIZE, GAME_END_TXB_PLACEMENTS + 4

################################################################################
# Command bytes
################################################################################
.set CMD_SPLIT_MESSAGE, 0x10 # Used for splitting up a large command into smaller messages
.set CMD_DESCRIPTIONS, 0x35
.set CMD_GAME_INFO, 0x36
.set CMD_GECKO_LIST, 0x3D
.set CMD_INITIAL_RNG, 0x3A
.set CMD_PRE_FRAME, 0x37
.set CMD_POST_FRAME, 0x38
.set CMD_ITEM, 0x3B
.set CMD_FRAME_BOOKEND, 0x3C
.set CMD_GAME_END, 0x39
.set CMD_FOD_INFO, 0x3F
.set CMD_DL_INFO, 0x40
.set CMD_PS_INFO, 0x41
.set COMMAND_COUNT, 13 # number of possible commands
# .set CMD_MENU_FRAME, 0x3E # not written for recorded game

################################################################################
# Payload lengths
################################################################################
.set MESSAGE_DESCRIPTIONS_PAYLOAD_LENGTH, 3 * (COMMAND_COUNT - 1) + 1 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 760 # byte count
.set GAME_FRAME_START_PAYLOAD_LENGTH, 12 #byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 66 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 84 # byte count
.set GAME_ITEM_INFO_PAYLOAD_LENGTH, 44 # byte count
.set GAME_FRAME_BOOKEND_PAYLOAD_LENGTH, 8 # byte count
.set GAME_END_PAYLOAD_LENGTH, GAME_END_TXB_SIZE - 1 # byte count
.set FOD_INFO_PAYLOAD_LENGTH, 9 # byte count
.set DL_INFO_PAYLOAD_LENGTH, 5 # byte count
.set PS_INFO_PAYLOAD_LENGTH, 8 # byte count
.set SPLIT_MESSAGE_PAYLOAD_LENGTH, 516 # byte count

.set SPLIT_MESSAGE_INTERNAL_DATA_LEN, 512

.set SPLIT_MESSAGE_OFST_COMMAND, 0x0 # u8
.set SPLIT_MESSAGE_OFST_DATA, SPLIT_MESSAGE_OFST_COMMAND + 1 # SPLIT_MESSAGE_INTERNAL_DATA_LEN
.set SPLIT_MESSAGE_OFST_SIZE, SPLIT_MESSAGE_OFST_DATA + SPLIT_MESSAGE_INTERNAL_DATA_LEN # u16, number of bytes actually contained in section
.set SPLIT_MESSAGE_OFST_INTERNAL_CMD, SPLIT_MESSAGE_OFST_SIZE + 2 # u8
.set SPLIT_MESSAGE_OFST_IS_COMPLETE, SPLIT_MESSAGE_OFST_INTERNAL_CMD + 1 # bool
.set SPLIT_MESSAGE_BUF_LEN, SPLIT_MESSAGE_OFST_IS_COMPLETE + 1

# Main recording data buffer
.set RDB_TXB_ADDRESS, 0x0 # u32
.set RDB_GAME_END_SENT, RDB_TXB_ADDRESS + 4 # bool
.set RDB_LEN, RDB_GAME_END_SENT + 1

# Calculate out the maximum buffer length that will be needed. This buffer
# is also used for transferring message descriptions and game info but that
# length should be less than the frame buf length
.set SUPPORTED_PORTS, 4
.set MAX_CHARACTERS, SUPPORTED_PORTS * 2 # ICs
.set TOTAL_FRAME_START_LEN, GAME_FRAME_START_PAYLOAD_LENGTH + 1
.set TOTAL_CHAR_FRAME_LEN, MAX_CHARACTERS * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + MAX_CHARACTERS * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1)
.set TOTAL_ITEM_LEN, MAX_ITEMS * (GAME_ITEM_INFO_PAYLOAD_LENGTH + 1)

# Determine the most amount of possible bytes that could be sent in a single frame by stages
.set TOTAL_FOD_LENGTH, (FOD_INFO_PAYLOAD_LENGTH + 1) * 2 # 2 platforms
.set TOTAL_DL_LENGTH, DL_INFO_PAYLOAD_LENGTH + 1
.set TOTAL_PS_LENGTH, PS_INFO_PAYLOAD_LENGTH + 1

.set TOTAL_MAX_STAGE_LEN, TOTAL_FOD_LENGTH
.if TOTAL_DL_LENGTH > TOTAL_MAX_STAGE_LEN
  .set TOTAL_MAX_STAGE_LEN, TOTAL_DL_LENGTH
.endif
.if TOTAL_PS_LENGTH > TOTAL_MAX_STAGE_LEN
  .set TOTAL_MAX_STAGE_LEN, TOTAL_PS_LENGTH
.endif

.set TOTAL_FRAME_BOOKEND_LEN, GAME_FRAME_BOOKEND_PAYLOAD_LENGTH + 1
.set TOTAL_GAME_END_LEN, GAME_END_PAYLOAD_LENGTH + 1
.set FULL_FRAME_DATA_BUF_LENGTH, TOTAL_FRAME_START_LEN + TOTAL_CHAR_FRAME_LEN + TOTAL_ITEM_LEN + TOTAL_MAX_STAGE_LEN + TOTAL_FRAME_BOOKEND_LEN + TOTAL_GAME_END_LEN

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 3.18.0
.set CURRENT_VERSION,0x03120000

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_ShouldRecord,0x80005604

################################################################################
# Custom Playerblock Offsets
################################################################################
.set PlayerBlockSize,0x2600
.set LCancelStatus,0x25FF
