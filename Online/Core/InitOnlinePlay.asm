################################################################################
# Address: 0x8016e748 # StartMelee before the standard Slippi stuff runs
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_GAME_INFO_START, 31 # from parent

.set REG_ODB_ADDRESS, 27
.set REG_RXB_ADDRESS, 26
.set REG_SSRB_ADDR, 25
.set REG_MSRB_ADDR, 24
.set REG_PLAYER_IDX, 23

# Run replaced code
branchl r12, 0x802254B8

backup

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne GECKO_EXIT

################################################################################
# Initialize Online Data Buffers
################################################################################

li r3, ODB_SIZE
branchl r12, HSD_MemAlloc
mr REG_ODB_ADDRESS, r3
li r4, ODB_SIZE
branchl r12, Zero_AreaLength

stw REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13)

# We use game prep minor scene data as a convenient place to store game index such that it persists
# between games even when not in ranked
loadwz r3, 0x803dad40 # Load minor scene data array ptr
lwz r12, 0x88(r3) # Load game prep minor scene data

# If not in ranked mode, let's increment the game index before the game start. Ranked mode manages
# this in its scene logic
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_RANKED
beq SKIP_GAME_INDEX_INCR
lhz r3, GPDO_CUR_GAME(r12)
addi r3, r3, 1
sth r3, GPDO_CUR_GAME(r12)
SKIP_GAME_INDEX_INCR:

# Indicate that the first frame is frame 1
li r3, 1
stw r3, ODB_FRAME(REG_ODB_ADDRESS)

# Store location to game complete handler
bl FN_HandleGameCompleted
mflr r3
stw r3, ODB_FN_HANDLE_GAME_OVER_ADDR(REG_ODB_ADDRESS)

# Create buffers for EXI data transfer. These buffers are split up because
# EXI buffers must be 32-byte aligned to work
li r3, TXB_SIZE
branchl r12, HSD_MemAlloc
stw r3, ODB_TXB_ADDR(REG_ODB_ADDRESS)

li r3, RXB_SIZE
branchl r12, HSD_MemAlloc
stw r3, ODB_RXB_ADDR(REG_ODB_ADDRESS)
mr REG_RXB_ADDRESS, r3
li r4, RXB_SIZE
branchl r12, Zero_AreaLength # For frame num, may not be necessary

# Prepare buffer for requesting savestate actions from Dolphin
li r3, SSRB_SIZE
branchl r12, HSD_MemAlloc
mr REG_SSRB_ADDR, r3
stw REG_SSRB_ADDR, ODB_SAVESTATE_SSRB_ADDR(REG_ODB_ADDRESS)

# Prepare buffer for ASM side savestates
li r3, SSCB_SIZE
branchl r12, HSD_MemAlloc
stw r3, ODB_SAVESTATE_SSCB_ADDR(REG_ODB_ADDRESS)
li r4, SSCB_SIZE
branchl r12, Zero_AreaLength

li r4, 0
stb r4, SSCB_WRITE_INDEX(r3)

li r4, ROLLBACK_MAX_FRAME_COUNT
stb r4, SSCB_SSDB_COUNT(r3)

# Write the locations that will be preserved through a savestate
stw REG_ODB_ADDRESS, SSRB_ODB_ADDR(REG_SSRB_ADDR)
li r3, ODB_SIZE
stw r3, SSRB_ODB_SIZE(REG_SSRB_ADDR)
stw REG_RXB_ADDRESS, SSRB_RXB_ADDR(REG_SSRB_ADDR)
li r3, RXB_SIZE
stw r3, SSRB_RXB_SIZE(REG_SSRB_ADDR)
lwz r3, ODB_SAVESTATE_SSCB_ADDR(REG_ODB_ADDRESS)
stw r3, SSRB_SSCB_ADDR(REG_SSRB_ADDR)
li r3, SSCB_SIZE
stw r3, SSRB_SSCB_SIZE(REG_SSRB_ADDR)
li r3, 0 # Write terminator
stw r3, SSRB_TERMINATOR(REG_SSRB_ADDR)

################################################################################
# Prepare match characters, ports, and RNG
################################################################################
# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Prepare player indices
lbz r3, -0x5108(r13) # Grab the 1p port in use
stb r3, ODB_INPUT_SOURCE_INDEX(REG_ODB_ADDRESS)
lbz r3, MSRB_LOCAL_PLAYER_INDEX(REG_MSRB_ADDR)
stb r3, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS)
lbz r3, MSRB_REMOTE_PLAYER_INDEX(REG_MSRB_ADDR)
stb r3, ODB_ONLINE_PLAYER_INDEX(REG_ODB_ADDRESS)

# Copy over RNG Offset
lwz r3, MSRB_RNG_OFFSET(REG_MSRB_ADDR)
stw r3, ODB_RNG_OFFSET(REG_ODB_ADDRESS)

# Write RNG offset to seed such that the start seed matches. Without this I
# noticed some desyncs on FD
lis r4, 0x804D
stw r3, 0x5F90(r4) # overwrite seed

# Copy match struct
mr r3, REG_GAME_INFO_START
addi r4, REG_MSRB_ADDR, MSRB_GAME_INFO_BLOCK
li r5, MATCH_STRUCT_LEN
branchl r12, memcpy

lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_RANKED
bne SKIP_TIEBREAK_OVERWRITE

# For ranked, in the case of a tiebreak, overwrite stock count and timer
loadwz r5, 0x803dad40 # Load minor scene data array ptr
lwz r5, 0x88(r5) # Load game prep minor scene data
lbz r3, GPDO_TIEBREAK_GAME_NUM(r5) # Load is_tiebreak
cmpwi r3, 0
beq SKIP_TIEBREAK_OVERWRITE # If not a tiebreak, do nothing
lbz r3, GPDO_LAST_GAME_END_MODE(r5)
cmpwi r3, 0x7
beq SKIP_TIEBREAK_OVERWRITE # If last game ended with exit, desync recovery values will be used (set by dolphin)

li r3, 180
stw r3, 0x10(REG_GAME_INFO_START)

li r3, 1
stb r3, 0x62(REG_GAME_INFO_START)
stb r3, 0x62 + 0x24(REG_GAME_INFO_START)
stb r3, 0x62 + 0x24 * 2(REG_GAME_INFO_START)
stb r3, 0x62 + 0x24 * 3(REG_GAME_INFO_START)

SKIP_TIEBREAK_OVERWRITE:

# Test code to force the timer to 15 seconds
# li r3, 15
# stw r3, 0x10(REG_GAME_INFO_START)

# For teams, overwrite the colors in the game info block with the proper color for the given team ID
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
bne SKIP_CHAR_COLOR_OVERWRITE

li REG_PLAYER_IDX, 0

CHAR_COLOR_OVERWRITE_LOOP_START:
# Load the team ID + 1 for team index and character ID to pass to function to get costume ID
mulli r5, REG_PLAYER_IDX, 0x24
addi r3, r5, 0x69
lbzx r3, REG_GAME_INFO_START, r3 # Loads team ID
addi r3, r3, 1
addi r4, r5, 0x60
lbzx r4, REG_GAME_INFO_START, r4 # Loads character ID
branchl r12, FN_GetTeamCostumeIndex # Loads costume ID into r3

# Write costume ID 
mulli r4, REG_PLAYER_IDX, 0x24
addi r4, r4, 0x63
stbx r3, REG_GAME_INFO_START, r4

# Increment port
addi REG_PLAYER_IDX, REG_PLAYER_IDX, 1
cmpwi REG_PLAYER_IDX, 4
blt CHAR_COLOR_OVERWRITE_LOOP_START

SKIP_CHAR_COLOR_OVERWRITE:

################################################################################
# Set up number of delay frames
################################################################################
lbz r3, MSRB_DELAY_FRAMES(REG_MSRB_ADDR)
cmpwi r3, MIN_DELAY_FRAMES
blt DELAY_FRAMES_MIN_LIMIT
cmpwi r3, MAX_DELAY_FRAMES
bgt DELAY_FRAMES_MAX_LIMIT
b SET_DELAY_FRAMES

DELAY_FRAMES_MIN_LIMIT:
li r3, MIN_DELAY_FRAMES
b SET_DELAY_FRAMES

DELAY_FRAMES_MAX_LIMIT:
li r3, MAX_DELAY_FRAMES

SET_DELAY_FRAMES:
stb r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)

################################################################################
# Clear A inputs to prevent transformation
################################################################################
# This is kind of jank but it will prevent Slippi from trying to flip the
# character in the recording game info block. It will also prevent a
# sheik -> zelda or zelda -> sheik transformation. This does every port because
# otherwise it might be possible for someone to play online with two controllers
# plugged in to start the opponent as the wrong character
li r5, 0

LOOP_CLEAR_INPUTS_START:
load r3, 0x804c20bc
mulli	r4, r5, 68
add r3, r3, r4
li r4, 0
stw r4, 0x0(r3)

addi r5, r5, 1
cmpwi r5, 4
blt LOOP_CLEAR_INPUTS_START

################################################################################
# Initialize RNG Function for Online Games
################################################################################

# Create GObj
li r3, 4 # GObj Type (4 is the player type, this should ensure it runs before any player animations)
li r4, 7 # On-Pause Function (dont run on pause)
li r5, 0 # some type of priority
branchl r12, GObj_Create

#Create Proc
bl FN_SyncRNG
mflr r4 # Function
li r5, 0 # Priority
branchl	r12, GObj_AddProc

b GECKO_EXIT

################################################################################
# Routine: SyncRNG
# ------------------------------------------------------------------------------
# Description: Syncs RNG when playing online
################################################################################

FN_SyncRNG:
blrl

loadGlobalFrame r3
rlwinm r4, r3, 16, 0xFFFFFFFF # Rotate left 16 bits for better RNG differences?

# Add RNG offset such that games are not always the same. Without this, for
# example, Pokemon would always go to the same transformation
lwz r3, OFST_R13_ODB_ADDR(r13) # ODB address
lwz r3, ODB_RNG_OFFSET(r3)
add r4, r4, r3

lis r3, 0x804D
stw r4, 0x5F90(r3) # overwrite random seed

blr

################################################################################
# Routine: HandleGameCompleted
# ------------------------------------------------------------------------------
# Description: Function called when game is confirmed over (no more rollbacks)
################################################################################
FN_HandleGameCompleted:
blrl

.set REG_IDX, 31
.set REG_RGB_ADDR, 30
.set REG_RGPB_ADDR, 29
.set REG_ODB_ADDRESS, 28
.set REG_GPD_ADDR, 27
.set REG_GAME_END_STRUCT_ADDR, 26

backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

loadwz r5, 0x803dad40 # Load minor scene data array ptr
lwz REG_GPD_ADDR, 0x88(r5) # Load game prep minor scene data

load REG_GAME_END_STRUCT_ADDR, 0x80479da4

################################################################################
# Initialize the MatchEndData early. Normally his happens on scene transition
# around 0x8016ea1c but we need it earlier (now) to determine the result of
# the match
################################################################################
mr r3, REG_GAME_END_STRUCT_ADDR # dest
load r4, 0x8046b8ec # source
li r5, 8824 # size
branchl r12, memcpy

load r4, 0x8046b6a0
mr r3, REG_GAME_END_STRUCT_ADDR
lbz r0, 0x24D0(r4)
stb r0, 0x6(r3)
lbz r0, 0x0008(r4)
stb r0, 0x4(r3)
branchl r12, 0x80166378 # CreateMatchEndData (struct @ 80479da4)

################################################################################
# Report game results
################################################################################
# Prepare buffer for EXI transfer
li r3, RGB_SIZE
branchl r12, HSD_MemAlloc
mr REG_RGB_ADDR, r3

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdReportMatch
stb r3, RGB_COMMAND(REG_RGB_ADDR)

lbz r3, OFST_R13_ONLINE_MODE(r13)
stb r3, RGB_ONLINE_MODE(REG_RGB_ADDR)

branchl r12, 0x801a4ba8 # MenuController_LoadTimer1
stw r3, RGB_FRAME_LENGTH(REG_RGB_ADDR) # Store frame length

lhz r3, GPDO_CUR_GAME(REG_GPD_ADDR)
stw r3, RGB_GAME_INDEX(REG_RGB_ADDR)

lbz r3, GPDO_TIEBREAK_GAME_NUM(REG_GPD_ADDR)
stw r3, RGB_TIEBREAKER_INDEX(REG_RGB_ADDR)

lwz r3, GPDO_FN_COMPUTE_RANKED_WINNER(REG_GPD_ADDR)
mtctr r3
bctrl
stb r3, RGB_WINNER_IDX(REG_RGB_ADDR)

# Change winner idx to -3 if disconnect detected, -2 if desync detected
lbz r3, ODB_IS_DISCONNECT_STATE_DISPLAYED(REG_ODB_ADDRESS)
cmpwi r3, 0
li r4, -3
bne OVERWRITE_WINNER_IDX
lbz r3, ODB_IS_DESYNC_STATE_DISPLAYED(REG_ODB_ADDRESS)
cmpwi r3, 0
li r4, -2
bne OVERWRITE_WINNER_IDX
b SKIP_OVERWRITE_WINNER_IDX
OVERWRITE_WINNER_IDX:
stb r4, RGB_WINNER_IDX(REG_RGB_ADDR)
SKIP_OVERWRITE_WINNER_IDX:

# Output the game end method and lras initiator
load r4, 0x8046b6a0
lbz r3, 0x8(r4)
stb r3, RGB_GAME_END_METHOD(REG_RGB_ADDR)
cmpwi r3, 0x7
bne NO_LRAS
lbz r3, 0x1(r4)
b STORE_LRAS_INITIATOR
NO_LRAS:
li r3, -1
STORE_LRAS_INITIATOR:
stb r3, RGB_LRAS_INITIATOR(REG_RGB_ADDR)

# Write synced timer for desync recovery
lwz r4, ODB_DESYNC_RECOVERY_TIMER(REG_ODB_ADDRESS)
stw r4, RGB_SYNCED_TIMER(REG_RGB_ADDR)

PLAYER_LOOP_INIT:
li REG_IDX, 0
addi REG_RGPB_ADDR, REG_RGB_ADDR, RGB_P1_RGPB

PLAYER_LOOP:
mr r3, REG_IDX
branchl r12, PlayerBlock_LoadStaticBlock

# Store isActive
lwz r4, 0x8(r3)
stb r4, RGPB_SLOT_TYPE(REG_RGPB_ADDR)

# Store stocks remaining
lbz r4, 0x8E(r3)
stb r4, RGPB_STOCKS_REMAINING(REG_RGPB_ADDR)

# Store damage done
lwz r4, 0xC6C+188(r3)
stw r4, RGPB_DAMAGE_DONE(REG_RGPB_ADDR)

# Write synced stocks and percents for desync recovery
mulli r5, REG_IDX, DFRE_SIZE
addi r4, r5, ODB_DESYNC_RECOVERY_FIGHTER_ARR + DFRE_STOCKS_REMAINING
lbzx r4, REG_ODB_ADDRESS, r4
stb r4, RGPB_SYNCED_STOCKS(REG_RGPB_ADDR)
addi r4, r5, ODB_DESYNC_RECOVERY_FIGHTER_ARR + DFRE_PERCENT
lhzx r4, REG_ODB_ADDRESS, r4
sth r4, RGPB_SYNCED_DAMAGE(REG_RGPB_ADDR)

PLAYER_LOOP_INC:
addi REG_IDX, REG_IDX, 1
addi REG_RGPB_ADDR, REG_RGPB_ADDR, RGPB_SIZE

PLAYER_LOOP_CHECK:
cmpwi REG_IDX, 4
blt PLAYER_LOOP

# Copy over game info
addi r3, REG_RGB_ADDR, RGB_GAME_INFO_BLOCK # Destination
load r4, 0x80480530 # Game info block source
li r5, MATCH_STRUCT_LEN
branchl r12, memcpy

# Execute match reporting
mr r3, REG_RGB_ADDR
li r4, RGB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

REPORT_GAME_EXIT:

restore

blr


GECKO_EXIT:

restore
