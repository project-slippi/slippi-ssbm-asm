.ifndef HEADER_IN_GAME_DELAY

################################################################################
# Injection locations
################################################################################
.set INJ_InitInGameDelay, 0x802f666c # HUD_Create

################################################################################
# Constants
################################################################################
.set PADS_REPORT_SIZE, 0xC * 4 # 4 controller inputs to backup
.set OFFLINE_MIN_DELAY_FRAMES, 0
.set OFFLINE_MAX_DELAY_FRAMES, 15

################################################################################
# In Game Delay Buffer
################################################################################
.set IGDB_DELAY_FRAMES, 0 # u8
.set IGDB_PAD_BUFFER_INDEX, IGDB_DELAY_FRAMES + 1 # u8
.set IGDB_PAD_BUFFER, IGDB_PAD_BUFFER_INDEX + 1 # PADS_REPORT_SIZE * OFFLINE_MAX_DELAY_FRAMES
.set IGDB_SIZE, IGDB_PAD_BUFFER + PADS_REPORT_SIZE * OFFLINE_MAX_DELAY_FRAMES

.endif
.set HEADER_IN_GAME_DELAY, 1
