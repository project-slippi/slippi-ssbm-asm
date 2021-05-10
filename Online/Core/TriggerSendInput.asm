################################################################################
# Address: 0x80376a28 # HSD_PadRenewRawStatus right after PAD_Read call
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set CONST_BACKUP_BYTES, 0xB0 # Maybe add this to Common.s
.set P1_PAD_OFFSET, CONST_BACKUP_BYTES + 0x2C

.set REG_ODB_ADDRESS, 27
.set REG_FRAME_INDEX, 26
.set REG_TXB_ADDRESS, 25
.set REG_RXB_ADDRESS, 24
.set REG_SSRB_ADDR, 23
.set REG_VARIOUS_1, 22
.set REG_VARIOUS_2, 21
.set REG_COUNT, 20

#backup registers and sp
backup

################################################################################
# Short Circuit Conditions
################################################################################

# Check if VS Mode
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Initialize
################################################################################

# fetch data to use throughout function
lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

# Load transfer buffer addresses
lwz REG_TXB_ADDRESS, ODB_TXB_ADDR(REG_ODB_ADDRESS)
lwz REG_RXB_ADDRESS, ODB_RXB_ADDR(REG_ODB_ADDRESS)
lwz REG_SSRB_ADDR, ODB_SAVESTATE_SSRB_ADDR(REG_ODB_ADDRESS)

# Load frame index
lwz REG_FRAME_INDEX, ODB_FRAME(REG_ODB_ADDRESS)

# Check if we have an active rollback, if so, we don't want to fetch
# new data from Slippi, we just want to operate on the existing data
lbz r3, ODB_ROLLBACK_IS_ACTIVE(REG_ODB_ADDRESS)
cmpwi r3, 1
beq ROLLBACK_HANDLER

################################################################################
# Section 1: Clear all inputs during freeze time, this is done such that
# both replays are identical when considering only finalized frames
################################################################################
lbz r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
li r4, UNFREEZE_INPUTS_FRAME
sub r3, r4, r3
cmpwi REG_FRAME_INDEX, r3 # Frame 84 +/- 1 (not sure) is first unfrozen frame
bge SKIP_FROZEN_INPUT_CLEAR

addi r3, sp, P1_PAD_OFFSET
li r4, CONTROLLER_COUNT * PAD_REPORT_SIZE
branchl r12, Zero_AreaLength

SKIP_FROZEN_INPUT_CLEAR:
################################################################################
# Section 2: Deal with stale? controller inputs
################################################################################
# These seem to happen when Dolphin slows down? Or during big rollbacks?
# They are problematic because they usually show up as zero inputs and
# are processed differently locally, branch at 803775b4 is hit though
# the zero inputs are used remotely.
lbz r4, ODB_INPUT_SOURCE_INDEX(REG_ODB_ADDRESS) # index to grab inputs from
mulli r4, r4, PAD_REPORT_SIZE
addi r3, r4, P1_PAD_OFFSET + 0xA # offset from sp where pad report we want is
lbzx r3, sp, r3 # Load local controller connected state
extsb r3, r3
cmpwi r3, -3 # This code probably means no new data? Not fully sure but it causes issues
bne SKIP_STALE_CONTROLLER_FIX

.if DEBUG_INPUTS==1
# TEMP: Print inputs for debugging
li r10, 0
lbz r12, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
mr r11, REG_FRAME_INDEX
add r11, r11, r12
addi r12, r4, P1_PAD_OFFSET
add r12, sp, r12
bl FN_PrintInputs
.endif

# Replace the zero inputs with inputs from last frame. I believe this is what
# the game does internally on a -3 status code, we need to make sure our remote
# client does the same
addi r3, r4, P1_PAD_OFFSET
add r3, sp, r3 # destination
addi r4, REG_ODB_ADDRESS, ODB_LAST_LOCAL_INPUTS # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

SKIP_STALE_CONTROLLER_FIX:

# Back up inputs to use for next frame if we get stale inputs
lbz r4, ODB_INPUT_SOURCE_INDEX(REG_ODB_ADDRESS) # index to grab inputs from
mulli r4, r4, PAD_REPORT_SIZE
addi r4, r4, P1_PAD_OFFSET # offset from sp where pad report we want is

# Move over pad data into last inputs storage
addi r3, REG_ODB_ADDRESS, ODB_LAST_LOCAL_INPUTS # destination
add r4, sp, r4 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

################################################################################
# Section 3: Send this frame's pad data over EXI
################################################################################

# Write command byte to transfer buffer
li r3, CONST_SlippiCmdSendOnlineFrame
stb r3, TXB_CMD(REG_TXB_ADDRESS)

# Load frame index into transfer buffer
stw REG_FRAME_INDEX, TXB_FRAME(REG_TXB_ADDRESS)

# Transfer delay amount
lbz r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
stb r3, TXB_DELAY(REG_TXB_ADDRESS)

# prepare to send local player pad
lbz r4, ODB_INPUT_SOURCE_INDEX(REG_ODB_ADDRESS) # index to grab inputs from
mulli r4, r4, PAD_REPORT_SIZE
addi r4, r4, P1_PAD_OFFSET # offset from sp where pad report we want is

# Move over pad data into transfer buffer
addi r3, REG_TXB_ADDRESS, TXB_PAD # destination
add r4, sp, r4 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

.if DEBUG_INPUTS==1
# TEMP: Print inputs for debugging
li r10, 1
lbz r12, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
mr r11, REG_FRAME_INDEX
add r11, r11, r12
addi r12, REG_TXB_ADDRESS, TXB_PAD
bl FN_PrintInputs
.endif

# Transfer buffer over DMA
mr r3, REG_TXB_ADDRESS
li r4, TXB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

################################################################################
# Section 4: Receive response and determine whether this input will be used
################################################################################

# Get response from Slippi and figure out whether this input should be skipped
# Skipping an input causes the game to stall one frame and allows the opponent's
# client to catch up
# TODO: Is it possible to do something better than skipping an input? Obviously
# TODO: this could throw off the timing of someone that is ahead
# request data from EXI that was prepared when we sent our frame
addi r3, REG_RXB_ADDRESS, RXB_RESULT
li r4, RXB_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

lbz r3, RXB_RESULT(REG_RXB_ADDRESS)
cmpwi r3, RESP_SKIP
beq SKIP_INPUT
cmpwi r3, RESP_DISCONNECTED
beq HANDLE_DISCONNECT
b RESP_RES_CONTINUE

HANDLE_DISCONNECT:
li r3, 1
stb r3, ODB_IS_DISCONNECTED(REG_ODB_ADDRESS)
b RESP_RES_CONTINUE

SKIP_INPUT:
# If we get here that means we are skipping this input. Skipping an input
# will cause the global frame timer to not increment, allowing for the numbers
# to sync up between players
restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input

RESP_RES_CONTINUE:

################################################################################
# Section 5: Overwrite this frame's pad data with data from x frames ago
################################################################################

# get delayed pad data offset from
lbz r4, ODB_DELAY_BUFFER_INDEX(REG_ODB_ADDRESS)
mulli r4, r4, PAD_REPORT_SIZE
addi r4, r4, ODB_DELAY_BUFFER

# get offset from sp of local player's pad data
lbz r3, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS) # local player index
mulli r3, r3, PAD_REPORT_SIZE
addi r3, r3, P1_PAD_OFFSET # offset from sp where pad report we want is

# copy data
add r3, sp, r3 # destination
add r4, REG_ODB_ADDRESS, r4 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

################################################################################
# Section 6: Copy local inputs into buffer for use if a rollback happens
################################################################################

# get write location for inputs
lbz r3, ODB_ROLLBACK_LOCAL_INPUTS_IDX(REG_ODB_ADDRESS)
mulli r3, r3, PAD_REPORT_SIZE
addi r3, r3, ODB_ROLLBACK_LOCAL_INPUTS

# get offset from sp of local player's pad data where we just wrote delayed inputs
lbz r4, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS) # local player index
mulli r4, r4, PAD_REPORT_SIZE
addi r4, r4, P1_PAD_OFFSET # offset from sp where pad report we want is

.if DEBUG_INPUTS==1
# TEMP: Print inputs for debugging
li r10, 3
mr r11, REG_FRAME_INDEX
add r12, sp, r4
bl FN_PrintInputs
.endif

# copy data
add r3, REG_ODB_ADDRESS, r3 # destination
add r4, sp, r4 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

# increment index
lbz r3, ODB_ROLLBACK_LOCAL_INPUTS_IDX(REG_ODB_ADDRESS)
addi r3, r3, 1
cmpwi r3, ROLLBACK_MAX_FRAME_COUNT
blt SKIP_LOCAL_INPUT_BUFFER_INDEX_WRAP

li r3, 0

SKIP_LOCAL_INPUT_BUFFER_INDEX_WRAP:
stb r3, ODB_ROLLBACK_LOCAL_INPUTS_IDX(REG_ODB_ADDRESS)

################################################################################
# Section 7: Add this frame's pad data to delay buffer
################################################################################

# prepare offset of current buffer data location
lbz r3, ODB_DELAY_BUFFER_INDEX(REG_ODB_ADDRESS)
mulli r3, r3, PAD_REPORT_SIZE
addi r3, r3, ODB_DELAY_BUFFER

.if DEBUG_INPUTS==1
# TEMP: Print inputs for debugging
li r10, 2
lbz r12, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
mr r11, REG_FRAME_INDEX
add r11, r11, r12
addi r12, REG_TXB_ADDRESS, TXB_PAD
bl FN_PrintInputs
.endif

# copy data we just transferred to use for this frame into the delay buffer
add r3, REG_ODB_ADDRESS, r3 # destination
addi r4, REG_TXB_ADDRESS, TXB_PAD # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

# increment delay buffer index
lbz r4, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
lbz r3, ODB_DELAY_BUFFER_INDEX(REG_ODB_ADDRESS)
addi r3, r3, 1
cmpw r3, r4
blt SKIP_DELAY_BUFFER_INDEX_WRAP
li r3, 0 # index wraps around to the start

SKIP_DELAY_BUFFER_INDEX_WRAP:
stb r3, ODB_DELAY_BUFFER_INDEX(REG_ODB_ADDRESS)

################################################################################
# Section 8: Check if we have prepared for rollback and inputs have been received
################################################################################

# If ODB_SAVESTATE_IS_ACTIVE is 0, we either don't have a savestate created
# or we're in a rollback, so set the per-player savestate flags to 0 and skip
# to section 9. If we're missing inputs for the current frame, they'll get reset
# correctly there.
lbz r3, ODB_SAVESTATE_IS_ACTIVE(REG_ODB_ADDRESS)
cmpwi r3, 0
bne COMPARE_PREDICTED_INPUTS

li r3, 0
stb r3, ODB_PLAYER_SAVESTATE_IS_ACTIVE(REG_ODB_ADDRESS)
stb r3, ODB_PLAYER_SAVESTATE_IS_ACTIVE+0x1(REG_ODB_ADDRESS)
stb r3, ODB_PLAYER_SAVESTATE_IS_ACTIVE+0x2(REG_ODB_ADDRESS)

b LOAD_OPPONENT_INPUTS

# If we were missing past inputs for one or more players, check and see
# if we've received any new inputs that would allow us to compare those to
# past predictions to potentially trigger a rollback.
COMPARE_PREDICTED_INPUTS:
# loop over each remote player
li REG_COUNT, 0

CHECK_WHETHER_TO_ROLL_BACK_LOOP:
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
lbzx r3, r6, REG_ODB_ADDRESS
cmpwi r3, 1
bne CONTINUE_ROLLBACK_CHECK_LOOP

# Look up the frame number for this remote player and store it in r3
mulli r6, REG_COUNT, 4
addi r6, r6, RXB_OPNT_FRAME_NUMS
lwzx r3, r6, REG_RXB_ADDRESS

# If receivedFrame < savestateFrame, we still dont have the inputs we need to
# rollback, in this case, we can continue loading the same stale inputs to
# continue on into prediction land.
# r3 will be (opponent frame - savestate frame), which determines the number
# of old frames to look through and check actual inputs vs predictions for.
# if r3 >= 0, we have actual inputs to compare.
mulli r6, REG_COUNT, 4
addi r6, r6, ODB_PLAYER_SAVESTATE_FRAME
lwzx r4, r6, REG_ODB_ADDRESS
sub. r3, r3, r4 # Load offset for RXB, subtract opp frame from savestate frame
blt CONTINUE_ROLLBACK_CHECK_LOOP

HAVE_PLAYER_INPUTS:
# If we get here, we have a savestate ready and we have received the inputs
# required to handle the savestate, so let's check the inputs to see if we need
# to roll back

mr REG_VARIOUS_1, r3
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Player %d[%d] r/w indexes when reading next input: %d/%d", "mr r5, 20", "mr r6, 22", "mr r7, 3", "mr r8, 4"
mr r3, REG_VARIOUS_1

# Compute offset of true inputs for this player on this frame
mulli r3, r3, PAD_REPORT_SIZE
addi r3, r3, RXB_OPNT_INPUTS
mulli r6, REG_COUNT, PLAYER_MAX_INPUT_SIZE
add r3, r3, r6

# Get inputs that were predicted for this frame
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r4, r6, REG_ODB_ADDRESS # load this player's read idx # r4 = read idx = 0
mulli r4, r4, PAD_REPORT_SIZE # compute offset within predicted input buffer
addi r4, r4, ODB_ROLLBACK_PREDICTED_INPUTS # Offset of inputs
mulli r5, REG_COUNT, PLAYER_MAX_INPUT_SIZE
add r4, r4, r5

add r6, REG_RXB_ADDRESS, r3
add r7, REG_ODB_ADDRESS, r4

# Check to see if inputs have changed. Start with buttons
# ---SYXBA
lbz r3, 0(r6)
lbz r4, 0(r7)
rlwinm r3, r3, 0, 0x1F
rlwinm r4, r4, 0, 0x1F
cmpw r3, r4
bne TRIGGER_ROLLBACK

# -LRZUDRL
lbz r3, 0x1(r6)
lbz r4, 0x1(r7)
rlwinm r3, r3, 0, 0x7F
rlwinm r4, r4, 0, 0x7F
cmpw r3, r4
bne TRIGGER_ROLLBACK

# TODO: Sounds like new UCF still uses raw values but if it ever switches
# TODO: to processed, consider removing this
# Now do the analog sticks. We can't use the deadzones the way we do for the
# triggers because of UCF checking for x differences
lwz r3, 0x2(r6)
lwz r4, 0x2(r7)
cmpw r3, r4
bne TRIGGER_ROLLBACK

# And finally, the triggers. Use deadzone at 42. 43+ are valid
li r5, 5 # Valid indices are 6-7
TRIGGER_LOOP_START:
addi r5, r5, 1
cmpwi r5, 8
bge INPUTS_MATCH
lbzx r3, r5, r6
lbzx r4, r5, r7
cmpwi r3, 42
bgt CONTINUE_TRIGGER_CHECK
cmpwi r4, 42
ble TRIGGER_LOOP_START # If both triggers are 42 or under, they are in deadzone
CONTINUE_TRIGGER_CHECK:
cmpw r3, r4
bne TRIGGER_ROLLBACK
b TRIGGER_LOOP_START

INPUTS_MATCH:
# Here inputs are the same as what we predicted, increment the read idx and the
# savestate frame and continue, we will no longer need to roll back to that frame
mulli r6, REG_COUNT, 4
addi r6, r6, ODB_PLAYER_SAVESTATE_FRAME
lwzx r3, r6, REG_ODB_ADDRESS # get our player-specific savestate frame
addi r3, r3, 1
stwx r3, r6, REG_ODB_ADDRESS

# increment read index
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS # load this player's read idx
addi r3, r3, 1
cmpwi r3, ROLLBACK_MAX_FRAME_COUNT
blt SKIP_PREDICTED_INPUTS_READ_IDX_ADJUST
subi r3, r3, ROLLBACK_MAX_FRAME_COUNT
SKIP_PREDICTED_INPUTS_READ_IDX_ADJUST:
stbx r3, r6, REG_ODB_ADDRESS

addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Player %d r/w indexes after reading: %d/%d", "mr r5, 20", "mr r6, 3", "mr r7, 4"

# Check if we have caught up to the prediction
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS
cmpw r4, r3
bne CHECK_WHETHER_TO_ROLL_BACK_LOOP # Not caught up, try loop again with next frame for this player

b CONTINUE_ROLLBACK_CHECK_LOOP

TRIGGER_ROLLBACK:
mulli r6, REG_COUNT, 4
addi r6, r6, ODB_PLAYER_SAVESTATE_FRAME
lwzx r3, r6, REG_ODB_ADDRESS # get our player-specific savestate frame
#logf LOG_LEVEL_WARN, "Triggering rollback from player %d input on past frame %d", "mr r5, 20", "mr r6, 3"

# Set the is rollback active flag to indicate to the engine to continue
# processing inputs until we have completed the rollback process
li r3, 1
stb r3, ODB_ROLLBACK_IS_ACTIVE(REG_ODB_ADDRESS)
stb r3, ODB_ROLLBACK_SHOULD_LOAD_STATE(REG_ODB_ADDRESS)

# Store the end frame index to remember when to terminate rollback logic
stw REG_FRAME_INDEX, ODB_ROLLBACK_END_FRAME(REG_ODB_ADDRESS)

# We are going to exit the parent function here. We have initiated a rollback
# which will cause the engine to loop without rendering frames, our rollback
# logic will kick in properly the next time this function is called
restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input

CONTINUE_ROLLBACK_CHECK_LOOP:
addi REG_COUNT, REG_COUNT, 1
cmpwi REG_COUNT, 3
blt CHECK_WHETHER_TO_ROLL_BACK_LOOP

# We've checked past predictions against any new inputs and nothing triggered a rollback;
# now determine how far (if at all) to move the savestate frame forward. It should end up as
# the lowest value among players we're tracking a savestate frame for.

.set REG_SAVESTATE_FRAME_SET, REG_VARIOUS_2
li REG_SAVESTATE_FRAME_SET, 0
li REG_COUNT, 0

lwz r3, ODB_SAVESTATE_FRAME(REG_ODB_ADDRESS) # r3 will hold the min savestate frame we see
mr REG_VARIOUS_1, r3
#logf LOG_LEVEL_WARN, "Attempting to advance savestate frame past %d", "mr r5, 3"
mr r3, REG_VARIOUS_1

COMPUTE_SAVESTATE_FRAME_LOOP:
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
lbzx r4, r6, REG_ODB_ADDRESS
mr REG_VARIOUS_1, r3
#logf LOG_LEVEL_WARN, "Player %d savestate flag: %d", "mr r5, 20", "mr r6, 4"
mr r3, REG_VARIOUS_1

# If this player doesn't have missing inputs, ignore their savestate frame
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
lbzx r4, r6, REG_ODB_ADDRESS
cmpwi r4, 1
bne CONTINUE_SAVESTATE_FRAME_LOOP

mulli r6, REG_COUNT, 4
addi r6, r6, ODB_PLAYER_SAVESTATE_FRAME
lwzx r4, r6, REG_ODB_ADDRESS

# If we are the first player to bump the savestate frame, do it to set an initial value.
cmpwi REG_SAVESTATE_FRAME_SET, 0
beq SKIP_SAVESTATE_FRAME_CHECK

# Otherwise only replace it with our frame if we're the new lowest.
cmpw r4, r3 # r4 = this player's savestate frame, r3 = lowest frame seen so far
bge CONTINUE_SAVESTATE_FRAME_LOOP

SKIP_SAVESTATE_FRAME_CHECK:
mr r3, r4
mr REG_VARIOUS_1, r3
#logf LOG_LEVEL_WARN, "Player %d set savestate frame %d", "mr r5, 20", "mr r6, 4"
mr r3, REG_VARIOUS_1
li REG_SAVESTATE_FRAME_SET, 1

CONTINUE_SAVESTATE_FRAME_LOOP:
addi REG_COUNT, REG_COUNT, 1
cmpwi REG_COUNT, 3
blt COMPUTE_SAVESTATE_FRAME_LOOP

# Set the savestate frame to the minimum value among players with missing inputs
stw r3, ODB_SAVESTATE_FRAME(REG_ODB_ADDRESS)
#logf LOG_LEVEL_WARN, "Set savestate frame to %d, game frame: %d", "mr r5, 3", "loadGlobalFrame r6"

# Check if all players inputs have caught up to the prediction so we can set savestate = 0
li REG_COUNT, 0
CHECK_RESET_SAVESTATE_LOOP:
# Don't bother checking read/write index match for players without an active savestate.
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
lbzx r4, r6, REG_ODB_ADDRESS
cmpwi r4, 1
bne CONTINUE_CHECK_RESET_SAVESTATE_LOOP

addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Player %d r/w indexes during reset: %d/%d", "mr r5, 20", "mr r6, 3", "mr r7, 4"

# Check if this player's inputs have caught up to the prediction
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS

# if we're caught up to the prediction, set this player's savestate flag back to 0
cmpw r4, r3
bne CONTINUE_CHECK_RESET_SAVESTATE_LOOP

li r3, 0
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
stbx r3, r6, REG_ODB_ADDRESS

CONTINUE_CHECK_RESET_SAVESTATE_LOOP:
addi REG_COUNT, REG_COUNT, 1
cmpwi REG_COUNT, 3
blt CHECK_RESET_SAVESTATE_LOOP

# If any players still have a savestate active, skip resetting the global flag
# TODO: make this part of the above loop, it doesn't need its own section
li REG_COUNT, 0
CHECK_GLOBAL_SAVESTATE_LOOP:
# Don't bother checking read/write index match for players without an active savestate.
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
lbzx r4, r6, REG_ODB_ADDRESS
cmpwi r4, 1
beq LOAD_OPPONENT_INPUTS

CONTINUE_CHECK_GLOBAL_SAVESTATE_LOOP:
addi REG_COUNT, REG_COUNT, 1
cmpwi REG_COUNT, 3
blt CHECK_GLOBAL_SAVESTATE_LOOP

# If we made it here, we have caught up to the prediction, clear the savestate flags for everyone
li r3, 0
stb r3, ODB_SAVESTATE_IS_ACTIVE(REG_ODB_ADDRESS)

#logf LOG_LEVEL_WARN, "Reset savestate flags to 0"

################################################################################
# Section 9: Try to read opponent's input for this frame
################################################################################

.set REG_REMOTE_PLAYER_IDX, REG_VARIOUS_2

LOAD_OPPONENT_INPUTS:
# loop over each remote player
li REG_COUNT, 0
li REG_REMOTE_PLAYER_IDX, 0 # port index of the current remote player

LOOP_LOAD_OPPONENT_INPUTS:
# skip over the local player's port for inputs
lbz r3, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS)
cmpw REG_REMOTE_PLAYER_IDX, r3
bne SKIP_INCREMENT_OPP_INDEX
addi REG_REMOTE_PLAYER_IDX, REG_REMOTE_PLAYER_IDX, 1
SKIP_INCREMENT_OPP_INDEX:
# get input index to use for this remote player
mulli r6, REG_COUNT, 4
addi r6, r6, RXB_OPNT_FRAME_NUMS
lwzx r3, r6, REG_RXB_ADDRESS
sub r3, r3, REG_FRAME_INDEX

# Make sure that we have the opponent input we need
cmpwi r3, 0
bge CALC_OPNT_PAD_OFFSET

# We are predicting inputs, back up the inputs for later comparison

# Don't save any states at the start of the game, it's frozen anyway
# and there might still be stuff loading
lbz r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
li r4, UNFREEZE_INPUTS_FRAME
sub r3, r4, r3
cmpw REG_FRAME_INDEX, r3 # Frame 84 +/- 1 (not sure) is first unfrozen frame
blt LOAD_STALE_INPUTS

# Don't save/trigger any rollbacks once game ends, prevents issues with loading
lbz r3, ODB_IS_GAME_OVER(REG_ODB_ADDRESS)
cmpwi r3, 1
beq LOAD_STALE_INPUTS

.set REG_PREDICTED_WRITE_IDX, REG_VARIOUS_1

# get offset from sp of online player's pad data
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx REG_PREDICTED_WRITE_IDX, r6, REG_ODB_ADDRESS
mulli r3, REG_PREDICTED_WRITE_IDX, PAD_REPORT_SIZE
addi r3, r3, ODB_ROLLBACK_PREDICTED_INPUTS # offset from REG_ODB_ADDRESS where to write
mulli r5, REG_COUNT, PLAYER_MAX_INPUT_SIZE # Add offset based on which player this is
add r3, r3, r5

# copy predicted pad data to predicted input buffer for later comparison
# in order to decide whether to roll back
mulli r6, REG_COUNT, PLAYER_MAX_INPUT_SIZE
addi r6, r6, RXB_OPNT_INPUTS
add r3, REG_ODB_ADDRESS, r3 # destination
add r4, REG_RXB_ADDRESS, r6 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

# increment write index
addi r3, REG_PREDICTED_WRITE_IDX, 1
cmpwi r3, ROLLBACK_MAX_FRAME_COUNT
blt SKIP_PREDICTED_INPUTS_WRITE_IDX_ADJUST
subi r3, r3, ROLLBACK_MAX_FRAME_COUNT

SKIP_PREDICTED_INPUTS_WRITE_IDX_ADJUST:
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
stbx r3, r6, REG_ODB_ADDRESS # store updated write index

addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
lbzx r3, r6, REG_ODB_ADDRESS
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_WRITE_IDXS # compute offset of write idx for this player
lbzx r4, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Player %d r/w indexes after write update: %d/%d", "mr r5, 20", "mr r6, 3", "mr r7, 4"

# in the case where we don't have this opponent's inputs but already have a
# savestate location for them, just keep the old savestate location
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE # compute offset of savestate flag for this player
lbzx r3, r6, REG_ODB_ADDRESS
cmpwi r3, 1
beq LOAD_STALE_INPUTS

# Store the current frame in this player's savestate frame counter
mulli r6, REG_COUNT, 4
addi r6, r6, ODB_PLAYER_SAVESTATE_FRAME
stwx REG_FRAME_INDEX, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Setting savestate frame for player %d to %d", "mr r5, 20", "mr r6, 26"

# Indicate we have prepared for a rollback because of this player's missing input
li r3, 1
addi r6, REG_COUNT, ODB_PLAYER_SAVESTATE_IS_ACTIVE
stbx r3, r6, REG_ODB_ADDRESS
#logf LOG_LEVEL_WARN, "Setting savestate flag to 1 for player %d", "mr r5, 20"

# Store read idx for predicted inputs
addi r6, REG_COUNT, ODB_ROLLBACK_PREDICTED_INPUTS_READ_IDXS # compute offset of read idx for this player
stbx REG_PREDICTED_WRITE_IDX, r6, REG_ODB_ADDRESS

# In the case where we don't have this player's inputs but already have a
# savestate because of another player's missing inputs, don't touch the global savestate frame counter
lbz r3, ODB_SAVESTATE_IS_ACTIVE(REG_ODB_ADDRESS)
cmpwi r3, 1
beq LOAD_STALE_INPUTS

# Store the rollback frame in the global savestate frame counter
stw REG_FRAME_INDEX, ODB_SAVESTATE_FRAME(REG_ODB_ADDRESS)
#logf LOG_LEVEL_WARN, "Setting global savestate frame to %d", "mr r5, 26"

# Indicate that we have prepared for a rollback
li r3, 1
stb r3, ODB_SAVESTATE_IS_ACTIVE(REG_ODB_ADDRESS)
#logf LOG_LEVEL_WARN, "Setting global savestate flag to 1"

LOAD_STALE_INPUTS:
li r3, 0 # use input at index zero (the most recent received)

CALC_OPNT_PAD_OFFSET:
# Index should never be >= ROLLBACK_MAX_FRAME_COUNT, in this case,
# Slippi should have told us to wait
mulli r3, r3, PAD_REPORT_SIZE # offset for index of input frame to look at
addi r5, r3, RXB_OPNT_INPUTS # offset from start of RXB
mulli r6, REG_COUNT, PLAYER_MAX_INPUT_SIZE # offset for index of remote player
add r5, r5, r6

# get offset from sp of online player's pad data
mulli r3, REG_REMOTE_PLAYER_IDX, PAD_REPORT_SIZE
addi r3, r3, P1_PAD_OFFSET # offset from sp where opponent pad report is

# copy opponent pad data to stack
add r3, sp, r3 # destination
add r4, REG_RXB_ADDRESS, r5 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

addi REG_COUNT, REG_COUNT, 1
addi REG_REMOTE_PLAYER_IDX, REG_REMOTE_PLAYER_IDX, 1
cmpwi REG_COUNT, 3
blt LOOP_LOAD_OPPONENT_INPUTS

b INCREMENT_AND_EXIT

################################################################################
# Rollback Handler Block
################################################################################

ROLLBACK_HANDLER:
# If the frame we want is past the rollback end, just do nothing. This might
# happen in the case where we get an interrupt during a rollback
lwz r3, ODB_ROLLBACK_END_FRAME(REG_ODB_ADDRESS)
cmpw REG_FRAME_INDEX, r3
ble COPY_LOCAL_INPUTS

# Do nothing...
restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input

COPY_LOCAL_INPUTS:
# get local input from history
lwz r3, ODB_ROLLBACK_END_FRAME(REG_ODB_ADDRESS)
sub r3, r3, REG_FRAME_INDEX
addi r3, r3, 1
lbz r4, ODB_ROLLBACK_LOCAL_INPUTS_IDX(REG_ODB_ADDRESS)
sub. r3, r4, r3
bge SKIP_LOCAL_INPUT_IDX_NEG
addi r3, r3, ROLLBACK_MAX_FRAME_COUNT
SKIP_LOCAL_INPUT_IDX_NEG:
mulli r3, r3, PAD_REPORT_SIZE
addi r4, r3, ODB_ROLLBACK_LOCAL_INPUTS

# get offset from sp of local player's pad data
lbz r3, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS) # local player index
mulli r3, r3, PAD_REPORT_SIZE
addi r3, r3, P1_PAD_OFFSET # offset from sp where pad report we want is

.if DEBUG_INPUTS==1
# TEMP: Print inputs for debugging
li r10, 4
mr r11, REG_FRAME_INDEX
add r12, REG_ODB_ADDRESS, r4
bl FN_PrintInputs
.endif

# copy data
add r3, sp, r3 # destination
add r4, REG_ODB_ADDRESS, r4 # source
li r5, PAD_REPORT_SIZE
branchl r12, memcpy

b LOAD_OPPONENT_INPUTS

################################################################################
# Routine: PrintInputs
# ------------------------------------------------------------------------------
# Inputs:
# r10: Log Num, r11: Frame, r12: Inputs
################################################################################
.if DEBUG_INPUTS==1
FN_PrintInputs:
backupall

mr r31, r11 # Frame
mr r30, r12 # Inputs
mr r28, r10 # Log Num
# r27 is ODB_ADDRESS and should not be used

bl PrintInputs_STRING
mflr r29 # Data

lbz r3, ODB_DELAY_FRAMES(REG_ODB_ADDRESS)
addi r3, r3, 1
cmpw r31, r3
bgt FN_PrintInputs_SKIP_ALLOC

# This will actually alloc a few times... but that's fine
li r3, 64
branchl r12, HSD_MemAlloc
stw r3, 0(r29)

# Store command byte for logging
li r4, 0xD0
stb r4, 0(r3)

# Indicate we don't need to print time
li r4, 0
stb r4, 1(r3)

FN_PrintInputs_SKIP_ALLOC:

# Format input string
lwz r3, 0(r29)
addi r3, r3, 2 # skip to string
addi r4, r29, 4 # Input string
mr r5, r31
mr r6, r28
lwz r7, 0(r30)
lwz r8, 4(r30)
lwz r9, 8(r30)
branchl r12, 0x80323cf4 # sprintf

# Transfer string buffer
lwz r3, 0(r29) # Use the receive buffer to send the command
li r4, 64
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

restoreall
blr

PrintInputs_STRING:
blrl
.long 0 # address of buffer
.string "[%d] (%d) %08X %08X %08X" # sprintf input string
.align 2
.endif

################################################################################
# Exit
################################################################################
INCREMENT_AND_EXIT:
addi REG_FRAME_INDEX, REG_FRAME_INDEX, 1
stw REG_FRAME_INDEX, ODB_FRAME(REG_ODB_ADDRESS)

EXIT:
#restore registers and sp
restore
cmpwi r30, 0 # restore replaced instruction
