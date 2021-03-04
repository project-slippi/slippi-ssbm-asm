################################################################################
# Injection locations
################################################################################
.set INJ_InitInGameDelay, 0x8016e9b0 # SceneLoad_InGame

################################################################################
# Constants
################################################################################
.set PAD_REPORT_SIZE, 0xC * 4 # 4 controller inputs to backup
.set MIN_DELAY_FRAMES, 1
.set MAX_DELAY_FRAMES, 15

################################################################################
# In Game Delay Buffer
################################################################################
.set IGDB_DELAY_FRAMES, 0 # u8
.set IGDB_PAD_BUFFER_INDEX, IGDB_DELAY_FRAMES + 1 # u8
.set IGDB_PAD_BUFFER, IGDB_PAD_BUFFER_INDEX + 1 # PAD_REPORT_SIZE * MAX_DELAY_FRAMES
.set IGDB_SIZE, IGDB_PAD_BUFFER + PAD_REPORT_SIZE * MAX_DELAY_FRAMES