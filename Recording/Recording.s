.set MEM_SLOT, 1 # 0 is SlotA, 1 is SlotB

# Payload lengths, if any additional data is added, these must be incremented
.set MESSAGE_DESCIPTIONS_PAYLOAD_LENGTH, 13 # byte count
.set GAME_INFO_PAYLOAD_LENGTH, 417 # byte count
.set GAME_PRE_FRAME_PAYLOAD_LENGTH, 63 # byte count
.set GAME_POST_FRAME_PAYLOAD_LENGTH, 0x34 # byte count
.set GAME_END_PAYLOAD_LENGTH, 2 # byte count
.set FULL_FRAME_DATA_BUF_LENGTH, 8 * (GAME_PRE_FRAME_PAYLOAD_LENGTH + 1) + 8 * (GAME_POST_FRAME_PAYLOAD_LENGTH + 1)

# build version number. Each byte is one digit
# any change in command data should result in a minor version change
# current version: 1.7.1.0
.set CURRENT_VERSION,0x01070100

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_IsVSMode,0x80005604
