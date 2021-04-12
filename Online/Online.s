################################################################################
# TODO List
################################################################################
# - Handle situation where a game ends while still predicting inputs, probably
#   wouldn't want to trigger a game end until all inputs have been received

.macro loadGlobalFrame reg
lis \reg, 0x8048
lwz \reg, -0x62A0(\reg)
.endm

################################################################################
# Offsets from r13
################################################################################
.set OFST_R13_ODB_ADDR,-0x49e4 # Online data buffer
.set OFST_R13_SB_ADDR,-0x503C # Scene buffer, persists throughout scenes
.set OFST_R13_ONLINE_MODE,-0x5060 # Byte, Selected online mode
.set OFST_R13_APP_STATE,-0x505F # Byte, App state / online status
.set OFST_R13_FORCE_MENU_CLEAR,-0x505E # Byte, Force menu clear
.set OFST_R13_NAME_ENTRY_MODE,-0x505D # Byte, 0 = normal, 1 = connect code
.set OFST_R13_SWITCH_TO_ONLINE_SUBMENU,-0x49ec # Function used to switch
.set OFST_R13_CALLBACK,-0x5018 # Callback address
.set OFST_R13_ISPAUSE,-0x5038 # byte, client paused bool (originally used for tournament mode @ 8019b8e4)
.set OFST_R13_ISWINNER,-0x5037 # byte, used to know if the player won the previous match
.set OFST_R13_CHOSESTAGE,-0x5036 # bool, used to know if the player has selected a stage
.set OFST_R13_USE_PREMADE_TEXT,-0x5014 # bool, used to make Text_CopyPremadeTextDataToStruct load text data from dolphin
.set OFST_R13_ISWIDESCREEN,-0x5020 # bool, used to make Text_CopyPremadeTextDataToStruct load text data from dolphin

# r13 offsets used in tournament mode (not sure if completely safe though)
# -0x5040 (r13)
# -0x5068 (r13)
# -0x7510 (r13)


.set CSSDT_BUF_ADDR, 0x80005614

################################################################################
# Debug Flags
################################################################################
.set DEBUG_INPUTS, 0

################################################################################
# Constants
################################################################################
.set CONTROLLER_COUNT, 4
.set PAD_REPORT_SIZE, 0xC
.set MIN_DELAY_FRAMES, 1
.set MAX_DELAY_FRAMES, 15
.set ROLLBACK_MAX_FRAME_COUNT, 7
.set PLAYER_MAX_INPUT_SIZE, PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT

.set UNFREEZE_INPUTS_FRAME, 84

.set STATIC_PLAYER_BLOCK_P1, 0x80453080
.set STATIC_PLAYER_BLOCK_LEN, 0xE90

.set MATCH_STRUCT_LEN, 0x138

.set ONLINE_MODE_RANKED, 0
.set ONLINE_MODE_UNRANKED, 1
.set ONLINE_MODE_DIRECT, 2
.set ONLINE_MODE_TEAMS, 3

.set OPTION_RANKED_IDX, 0
.set OPTION_UNRANKED_IDX, 1
.set OPTION_DIRECT_IDX, 2
.set OPTION_TEAMS_IDX, 3
.set OPTION_LOGIN_IDX, 4
.set OPTION_LOGOUT_IDX, 5
.set OPTION_UPDATE_IDX, 6

.set ONLINE_SUBMENU_OPTION_COUNT, 7

################################################################################
# Online Scenes
################################################################################
.set SCENE_ONLINE_CSS, 0x0008
.set SCENE_ONLINE_SSS, 0x0108
.set SCENE_ONLINE_IN_GAME, 0x0208
.set SCENE_ONLINE_VS, 0x0408

/*
-each is 0xC long
-4 total, one for each controller

0x0 = u8, ---SYXBA
0x1 = u8, -LRZUDRL
0x2 = int8, leftstick X
0x3 = int8, leftstick Y
0x4 = int8, rightstick X
0x5 = int8, rightstick Y
0x6 = int8, lefttrigger value
0x7 = int8, righttrigger value
0x8 = int8, unk
0x9 = int8, unk
0xA = int8, isConnected (0 = connected, -1 = disconnected)
0xB = padding
*/

################################################################################
# ISWINNER Values
################################################################################
.set ISWINNER_NULL, -1    # indicates this is the first match / no previous winner
.set ISWINNER_LOST, 0    # indicates the player lost the previous match
.set ISWINNER_WON, 1    # indicates the player won the previous match

################################################################################
# Stage Behavior Arg Values (r3 for FN_LOCK_IN_AND_SEARCH and FN_TX_LOCK_IN)
# 0+ = specify stage ID.
################################################################################
.set  SB_RAND, -2
.set  SB_NOTSEL, -1

################################################################################
# Savestate Request Buffer
################################################################################
.set SSRB_COMMAND, 0 # u8
.set SSRB_FRAME, SSRB_COMMAND + 1 # u32
.set SSRB_ODB_ADDR, SSRB_FRAME + 4 # u32
.set SSRB_ODB_SIZE, SSRB_ODB_ADDR + 4 # u32
.set SSRB_RXB_ADDR, SSRB_ODB_SIZE + 4 # u32
.set SSRB_RXB_SIZE, SSRB_RXB_ADDR + 4 # u32
.set SSRB_SSCB_ADDR, SSRB_RXB_SIZE + 4 # u32
.set SSRB_SSCB_SIZE, SSRB_SSCB_ADDR + 4 # u32
# .set SSRB_STACK_ADDR, SSRB_RXB_SIZE + 4 # u32
# .set SSRB_STACK_SIZE, SSRB_STACK_ADDR + 4 # u32
.set SSRB_TERMINATOR, SSRB_SSCB_SIZE + 4 # u32
.set SSRB_SIZE, SSRB_TERMINATOR + 4

################################################################################
# Savestate Data Buffer - Includes data stored locally for savestates
################################################################################
.set SSDB_FRAME, 0 # u32
.set SSDB_SIZE, SSDB_FRAME + 4

################################################################################
# Savestate Pre-Load Buffer
################################################################################
.set SSPLB_SOUND_ENTRY_ID, 0 # u32
.set SSPLB_SOUND_ENTRY_LOC, SSPLB_SOUND_ENTRY_ID + 4 # u32
.set SSPLB_SOUND_ENTRY_SIZE, SSPLB_SOUND_ENTRY_LOC + 4

.set SOUND_ENTRY_COUNT, 16

.set SSPLB_SOUND_ENTRIES, 0 # SOUND_ENTRY_COUNT * SSPLB_SOUND_ENTRY_SIZE
.set SSPLB_SIZE, SSPLB_SOUND_ENTRIES + SOUND_ENTRY_COUNT * SSPLB_SOUND_ENTRY_SIZE

################################################################################
# Savestate Control Buffer
################################################################################
.set SSCB_WRITE_INDEX, 0 # u8, next index to write savestate at
.set SSCB_SSDB_COUNT, SSCB_WRITE_INDEX + 1 # u8
.set SSCB_SSDB_START, SSCB_SSDB_COUNT + 1 # SSDB_SIZE * ROLLBACK_MAX_FRAME_COUNT
.set SSCB_SSPLB_START, SSCB_SSDB_START + SSDB_SIZE * ROLLBACK_MAX_FRAME_COUNT # SSPLB_SIZE
.set SSCB_SIZE, SSCB_SSPLB_START + SSPLB_SIZE

################################################################################
# SFX Storage
################################################################################
.set MAX_SOUNDS_PER_FRAME, 0x10

# The entry is the data needed to keep track of for a given sound every frame
.set SFXS_ENTRY_SOUND_ID, 0 # u16, ID of the sound played
.set SFXS_ENTRY_INSTANCE_ID, SFXS_ENTRY_SOUND_ID + 2 # u32
.set SFXS_ENTRY_SIZE, SFXS_ENTRY_INSTANCE_ID + 4

# A log keeps tracks of sounds on a given frame, the index is effectively how
# many sounds have been encountered so far
.set SFXS_LOG_INDEX, 0 # u8, Index where we are in the frame
.set SFXS_LOG_ENTRIES, SFXS_LOG_INDEX + 1 # SFXS_ENTRY_SIZE * MAX_SOUNDS_PER_FRAME
.set SFXS_LOG_SIZE, SFXS_LOG_ENTRIES + SFXS_ENTRY_SIZE * MAX_SOUNDS_PER_FRAME

# Pending log keeps track of all inputs during execution of a frame
# Stable log is copied from the pending log at the end of the frame
# Both are needed because as a frame is processing, we need to check if the last
# time this frame was played, whether our sound was executed. This is the purpose
# of the stable log, the pending log is needed to keep track of the latest frame
# sound execution such that on the next frame, it can be used as the stable log
.set SFXS_FRAME_PENDING_LOG, 0 # SFXS_LOG_SIZE
.set SFXS_FRAME_STABLE_LOG, SFXS_FRAME_PENDING_LOG + SFXS_LOG_SIZE # SFXS_LOG_SIZE
.set SFXS_FRAME_SIZE, SFXS_FRAME_STABLE_LOG + SFXS_LOG_SIZE

# Write index increments every frame we process
.set SFXDB_WRITE_INDEX, 0 # u8
.set SFXDB_FRAMES, SFXDB_WRITE_INDEX + 1 # SFXS_FRAME_SIZE * ROLLBACK_MAX_FRAME_COUNT
.set SFXDB_SIZE, SFXDB_FRAMES + SFXS_FRAME_SIZE * ROLLBACK_MAX_FRAME_COUNT

################################################################################
# Online Data Buffer Offsets
################################################################################
.set ODB_LOCAL_PLAYER_INDEX, 0 # u8
.set ODB_ONLINE_PLAYER_INDEX, ODB_LOCAL_PLAYER_INDEX + 1 # u8
.set ODB_INPUT_SOURCE_INDEX, ODB_ONLINE_PLAYER_INDEX + 1 # u8
.set ODB_FRAME, ODB_INPUT_SOURCE_INDEX + 1 # u32
.set ODB_RNG_OFFSET, ODB_FRAME + 4 # u32
.set ODB_GAME_OVER_COUNTER, ODB_RNG_OFFSET + 4 # u8
.set ODB_IS_GAME_OVER, ODB_GAME_OVER_COUNTER + 1 # bool
.set ODB_IS_DISCONNECTED, ODB_IS_GAME_OVER + 1 # bool
.set ODB_IS_DISCONNECT_STATE_DISPLAYED, ODB_IS_DISCONNECTED + 1 # bool
.set ODB_LAST_LOCAL_INPUTS, ODB_IS_DISCONNECT_STATE_DISPLAYED + 1 # PAD_REPORT_SIZE
.set ODB_DELAY_FRAMES, ODB_LAST_LOCAL_INPUTS + PAD_REPORT_SIZE # u8
.set ODB_DELAY_BUFFER_INDEX, ODB_DELAY_FRAMES + 1 # u8
.set ODB_DELAY_BUFFER, ODB_DELAY_BUFFER_INDEX + 1 # PAD_REPORT_SIZE * MAX_DELAY_FRAMES
.set ODB_TXB_ADDR, ODB_DELAY_BUFFER + PAD_REPORT_SIZE * MAX_DELAY_FRAMES # u32
.set ODB_RXB_ADDR, ODB_TXB_ADDR + 4  # u32
.set ODB_ROLLBACK_IS_ACTIVE, ODB_RXB_ADDR + 4 # bool
.set ODB_ROLLBACK_SHOULD_LOAD_STATE, ODB_ROLLBACK_IS_ACTIVE + 1 # bool
.set ODB_ROLLBACK_END_FRAME, ODB_ROLLBACK_SHOULD_LOAD_STATE + 1 # s32
.set ODB_ROLLBACK_LOCAL_INPUTS_IDX, ODB_ROLLBACK_END_FRAME + 4 # u8
.set ODB_ROLLBACK_LOCAL_INPUTS, ODB_ROLLBACK_LOCAL_INPUTS_IDX + 1 # PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT
.set ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS, ODB_ROLLBACK_LOCAL_INPUTS + PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT # u8
.set ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS + 1*3 # u8
.set ODB_ROLLBACK_PREDICTED_INPUTS, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS + 1*3 # PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT
.set ODB_SAVESTATE_IS_ACTIVE, ODB_ROLLBACK_PREDICTED_INPUTS + PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT * 3 # bool
.set ODB_SAVESTATE_FRAME, ODB_SAVESTATE_IS_ACTIVE + 1 # s32
.set ODB_PLAYER_SAVESTATE_FRAME, ODB_SAVESTATE_FRAME + 4 # u32
.set ODB_PLAYER_SAVESTATE_IS_ACTIVE, ODB_PLAYER_SAVESTATE_FRAME + 4*3 # u32[3]
.set ODB_SAVESTATE_SSRB_ADDR, ODB_PLAYER_SAVESTATE_IS_ACTIVE + 3 # u32
.set ODB_SAVESTATE_SSCB_ADDR, ODB_SAVESTATE_SSRB_ADDR + 4 # u32
.set ODB_SFXDB_START, ODB_SAVESTATE_SSCB_ADDR + 4 # SFXDB_SIZE
.set ODB_LATEST_FRAME, ODB_SFXDB_START + SFXDB_SIZE # u32
.set ODB_FN_HANDLE_GAME_OVER_ADDR, ODB_LATEST_FRAME + 4 # u32
.set ODB_STABLE_ROLLBACK_IS_ACTIVE, ODB_FN_HANDLE_GAME_OVER_ADDR + 4 # bool
.set ODB_STABLE_ROLLBACK_END_FRAME, ODB_STABLE_ROLLBACK_IS_ACTIVE + 1 # s32
.set ODB_STABLE_ROLLBACK_SHOULD_LOAD_STATE, ODB_STABLE_ROLLBACK_END_FRAME + 4 # bool
.set ODB_STABLE_SAVESTATE_FRAME, ODB_STABLE_ROLLBACK_SHOULD_LOAD_STATE + 1 # s32
.set ODB_STABLE_OPNT_FRAME_NUMS, ODB_STABLE_SAVESTATE_FRAME + 4 # s32[3]
.set ODB_SHOULD_FORCE_PAD_RENEW, ODB_STABLE_OPNT_FRAME_NUMS + 4 # bool
.set ODB_HUD_CANVAS, ODB_SHOULD_FORCE_PAD_RENEW + 1 # u32
.set ODB_SIZE, ODB_HUD_CANVAS + 4

.set TXB_CMD, 0 # u8
.set TXB_FRAME, TXB_CMD + 1 # s32
.set TXB_DELAY, TXB_FRAME + 4 # u8 TODO: Delay should be part of some init message or something at start of game
.set TXB_PAD, TXB_DELAY + 1 # PAD_REPORT_SIZE
.set TXB_SIZE, TXB_PAD + PAD_REPORT_SIZE

.set RXB_RESULT, 0 # u8
.set RXB_OPNT_COUNT, RXB_RESULT + 1 # u8
.set RXB_OPNT_FRAME_NUMS, RXB_OPNT_COUNT + 1 # s32[3]
.set RXB_OPNT_INPUTS, RXB_OPNT_FRAME_NUMS + 4*3 # PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT
.set RXB_SIZE, RXB_OPNT_INPUTS + PAD_REPORT_SIZE * ROLLBACK_MAX_FRAME_COUNT * 3

################################################################################
# Matchmaking States
################################################################################
.set MM_STATE_IDLE, 0
.set MM_STATE_INITIALIZING, 1
.set MM_STATE_MATCHMAKING, 2
.set MM_STATE_OPPONENT_CONNECTING, 3
.set MM_STATE_CONNECTION_SUCCESS, 4
.set MM_STATE_ERROR_ENCOUNTERED, 5

################################################################################
# Match State Response Buffer
################################################################################
.set MSRB_CONNECTION_STATE, 0 # u8, matchmaking state defined above
.set MSRB_IS_LOCAL_PLAYER_READY, MSRB_CONNECTION_STATE + 1 # bool
.set MSRB_IS_REMOTE_PLAYER_READY, MSRB_IS_LOCAL_PLAYER_READY + 1 # bool
.set MSRB_LOCAL_PLAYER_INDEX, MSRB_IS_REMOTE_PLAYER_READY + 1 # u8
.set MSRB_REMOTE_PLAYER_INDEX, MSRB_LOCAL_PLAYER_INDEX + 1 # u8
.set MSRB_RNG_OFFSET, MSRB_REMOTE_PLAYER_INDEX + 1 # u32
.set MSRB_DELAY_FRAMES, MSRB_RNG_OFFSET + 4 # u8
.set MSRB_USER_CHATMSG_ID, MSRB_DELAY_FRAMES + 1 # u8
.set MSRB_OPP_CHATMSG_ID, MSRB_USER_CHATMSG_ID + 1 # u8
.set MSRB_CHATMSG_PLAYER_INDEX, MSRB_OPP_CHATMSG_ID + 1 # u8
.set MSRB_VS_LEFT_PLAYERS, MSRB_CHATMSG_PLAYER_INDEX + 1 # u8 player ports 0xP1P2P3PN
.set MSRB_VS_RIGHT_PLAYERS, MSRB_VS_LEFT_PLAYERS + 4 # u8 player ports 0xP1P2P3PN
.set MSRB_LOCAL_NAME, MSRB_VS_RIGHT_PLAYERS + 4 # string (31)
.set MSRB_P1_NAME, MSRB_LOCAL_NAME + 31 # string (31)
.set MSRB_P2_NAME, MSRB_P1_NAME + 31 # string (31)
.set MSRB_P3_NAME, MSRB_P2_NAME + 31 # string (31)
.set MSRB_P4_NAME, MSRB_P3_NAME + 31 # string (31)
.set MSRB_OPP_NAME, MSRB_P4_NAME + 31 # string (63)
.set MSRB_P1_CONNECT_CODE, MSRB_OPP_NAME + 63 # string (10) hashtag is shift-jis
.set MSRB_P2_CONNECT_CODE, MSRB_P1_CONNECT_CODE + 10 # string (10) hashtag is shift-jis
.set MSRB_P3_CONNECT_CODE, MSRB_P2_CONNECT_CODE + 10 # string (10) hashtag is shift-jis
.set MSRB_P4_CONNECT_CODE, MSRB_P3_CONNECT_CODE + 10 # string (10) hashtag is shift-jis
.set MSRB_ERROR_MSG, MSRB_P4_CONNECT_CODE + 10 # string (241)
.set ERROR_MESSAGE_LEN, 241
.set MSRB_GAME_INFO_BLOCK, MSRB_ERROR_MSG + ERROR_MESSAGE_LEN # MATCH_STRUCT_LEN
.set MSRB_SIZE, MSRB_GAME_INFO_BLOCK + MATCH_STRUCT_LEN

################################################################################
# Player Selections Transfer Buffer
################################################################################
.set PSTB_CMD, 0 # u8
.set PSTB_TEAM_ID, PSTB_CMD + 1 # u8
.set PSTB_CHAR_ID, PSTB_TEAM_ID + 1 # u8
.set PSTB_CHAR_COLOR, PSTB_CHAR_ID + 1 # u8
.set PSTB_CHAR_OPT, PSTB_CHAR_COLOR + 1 # u8, 0 = unset, 1 = merge, 2 = clear
.set PSTB_STAGE_ID, PSTB_CHAR_OPT + 1 # u16
.set PSTB_STAGE_OPT, PSTB_STAGE_ID + 2 # u8, 0 = unset, 1 = merge, 2 = clear, 3 = random
.set PSTB_ONLINE_MODE, PSTB_STAGE_OPT + 1 # u8
.set PSTB_SIZE, PSTB_ONLINE_MODE + 1

################################################################################
# Chat Messages Transfer Buffer
################################################################################

.set CMTB_CMD, 0 #u8
.set CMTB_MESSAGE, CMTB_CMD + 1 #u8, 0x01=ggs,0x2=brb,0x4=Last One,0x8=One More, .... See Pad Values on HandleInpuOnCSS.asm for all
.set CMTB_SIZE, CMTB_MESSAGE + 1

################################################################################
# Find Match Transfer Buffer
################################################################################
.set FMTB_CMD, 0 # u8
.set FMTB_ONLINE_MODE, FMTB_CMD + 1 # u8
.set FMTB_OPP_CONNECT_CODE, FMTB_ONLINE_MODE + 1 # string (18) shift-jis
.set FMTB_SIZE, FMTB_OPP_CONNECT_CODE + 18

################################################################################
# CSS Data Table
################################################################################
.set CSSDT_MSRB_ADDR, 0 # u32
.set CSSDT_TEXT_STRUCT_ADDR, CSSDT_MSRB_ADDR + 4 # u32
.set CSSDT_SPINNER1, CSSDT_TEXT_STRUCT_ADDR + 4 # u8 (0 = hide, 1 = spin, 2 = done)
.set CSSDT_SPINNER2, CSSDT_SPINNER1 + 1 # u8 (0 = hide, 1 = spin, 2 = done)
.set CSSDT_SPINNER3, CSSDT_SPINNER2 + 1 # u8 (0 = hide, 1 = spin, 2 = done)
.set CSSDT_FRAME_COUNTER, CSSDT_SPINNER3 + 1 # u16
.set CSSDT_PREV_LOCK_IN_STATE, CSSDT_FRAME_COUNTER + 2 # bool
.set CSSDT_PREV_CONNECTED_STATE, CSSDT_PREV_LOCK_IN_STATE + 1 # u8
.set CSSDT_Z_BUTTON_HOLD_TIMER, CSSDT_PREV_CONNECTED_STATE + 1 # u8 amount of frames Z has been hold for
.set CSSDT_CHAT_WINDOW_OPENED, CSSDT_Z_BUTTON_HOLD_TIMER + 1 # u8
.set CSSDT_CHAT_LAST_INPUT, CSSDT_CHAT_WINDOW_OPENED + 1 # u16
.set CSSDT_CHAT_MSG_COUNT, CSSDT_CHAT_LAST_INPUT + 2 # u8
.set CSSDT_CHAT_LOCAL_MSG_COUNT, CSSDT_CHAT_MSG_COUNT + 1 # u8
.set CSSDT_LAST_CHAT_MSG_INDEX, CSSDT_CHAT_LOCAL_MSG_COUNT + 1 # u8
.set CSSDT_TEAM_IDX, CSSDT_LAST_CHAT_MSG_INDEX + 1 # u8
.set CSSDT_TEAM_COSTUME_IDX, CSSDT_TEAM_IDX + 1 #8
.set CSSDT_SIZE, CSSDT_TEAM_COSTUME_IDX + 1

################################################################################
# CSS Chat Message Data Table
################################################################################
.set CSSCMDT_TIMER, 0 # u8
.set CSSCMDT_TIMER_STATUS, CSSCMDT_TIMER + 1 # u8 0=startup, 1=idle, 2=cleanup
.set CSSCMDT_MSG_ID, CSSCMDT_TIMER_STATUS + 1 # u8
.set CSSCMDT_MSG_INDEX, CSSCMDT_MSG_ID + 1 # u8
.set CSSCMDT_MSG_TEXT_STRUCT_ADDR, CSSCMDT_MSG_INDEX + 1 # u32
.set CSSCMDT_PLAYER_INDEX, CSSCMDT_MSG_TEXT_STRUCT_ADDR + 4 # u8
.set CSSCMDT_CSSDT_ADDR, CSSCMDT_PLAYER_INDEX + 1 # u32 CSS Data Table Address
.set CSSCMDT_SIZE, CSSCMDT_CSSDT_ADDR + 4

################################################################################
# CSS Team Icon Button Data Table
################################################################################
.set CSSTIDT_CSSDT_ADDR, 0 # u32 CSS Data Table Address
.set CSSTIDT_SIZE, CSSTIDT_CSSDT_ADDR + 4

################################################################################
# CSS Chat Window Data Table
################################################################################
.set CSSCWDT_INPUT, 0 # u8
.set CSSCWDT_TIMER, CSSCWDT_INPUT + 1 # u8
.set CSSCWDT_TEXT_STRUCT_ADDR, CSSCWDT_TIMER + 1 # u32
.set CSSCWDT_CSSDT_ADDR, CSSCWDT_TEXT_STRUCT_ADDR + 4 # u32 CSS Data Table Address
.set CSSCWDT_SIZE, CSSCWDT_CSSDT_ADDR + 4

################################################################################
# Online status buffer offsets
################################################################################
.set OSB_APP_STATE, 0 # 0 = not logged in, 1 = logged in, 2 = update required
.set OSB_PLAYER_NAME, OSB_APP_STATE + 1 # string (31)
.set OSB_CONNECT_CODE, OSB_PLAYER_NAME + 31 # string (10) hashtag is shift-jis
.set OSB_SIZE, OSB_CONNECT_CODE + 10

################################################################################
# Define report game buffer offsets and length
################################################################################
.set RGPB_IS_ACTIVE, 0 # bool, is player active
.set RGPB_STOCKS_REMAINING, RGPB_IS_ACTIVE + 1 # byte
.set RGPB_DAMAGE_DONE, RGPB_STOCKS_REMAINING + 1 # float
.set RGPB_SIZE, RGPB_DAMAGE_DONE + 4

.set RGB_COMMAND, 0 # byte
.set RGB_FRAME_LENGTH, RGB_COMMAND + 1 # s32, number of frames in game
.set RGB_P1_RGPB, RGB_FRAME_LENGTH + 4 # RGPB_SIZE
.set RGB_P2_RGPB, RGB_P1_RGPB + RGPB_SIZE # RGPB_SIZE
.set RGB_SIZE, RGB_P2_RGPB + RGPB_SIZE

################################################################################
# Const Values
################################################################################
.set RESP_NORMAL, 1
.set RESP_SKIP, 2
.set RESP_DISCONNECTED, 3
