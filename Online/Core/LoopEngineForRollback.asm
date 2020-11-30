################################################################################
# Address: 0x801a5014 # updateFunction, branch instruction
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Common/FastForward/FunctionMacros.s"

# run equivalent code
beq+ START
branch r12, 0x801a5024 # go to where branch would have taken us

################################################################################
# Short Circuit Conditions
################################################################################
START:

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Body
################################################################################
.set REG_ODB_ADDRESS, 31
.set REG_SFXDB_ADDRESS, 30
.set REG_INTERRUPT_IDX, 29
.set REG_SOUND_WRITE_INDEX, 28
.set REG_IS_ROLLBACK_ACTIVE, 27
.set REG_SFXS_FRAME_ADDRESS, 26
.set REG_STABLE_CUR_IDX, 25
.set REG_CURRENT_FRAME, 24
.set REG_LATEST_FRAME, 23

backup

branchl r12, OSDisableInterrupts # Not backing up r3 output, don't use r3 in body
mr REG_INTERRUPT_IDX, r3

################################################################################
# Handle Sound updates
################################################################################
lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
addi REG_SFXDB_ADDRESS, REG_ODB_ADDRESS, ODB_SFXDB_START

lbz REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
loadGlobalFrame REG_CURRENT_FRAME
subi REG_CURRENT_FRAME, REG_CURRENT_FRAME, 1 # remove 1 from frame index because global frame has already been incremented
lwz REG_LATEST_FRAME, ODB_LATEST_FRAME(REG_ODB_ADDRESS)
cmpw REG_CURRENT_FRAME, REG_LATEST_FRAME
bgt SOUND_TERMINATE_END # If new frame, no need to try and kill sounds

# If we are on the last frame that was run before a ffw, the following
# will equal 1. The ffw end frame was never actually processed
sub r3, REG_LATEST_FRAME, REG_CURRENT_FRAME
addi r3, r3, 1

lbz REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
sub. REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, r3
bge ADJUST_WRITE_INDEX_END
addi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, ROLLBACK_MAX_FRAME_COUNT
ADJUST_WRITE_INDEX_END:

################################################################################
# Terminate sounds from actions that got cancelled due to rollback
################################################################################
KILL_ROLLBACK_SOUNDS:
# First let's get SFXS_FRAME address
addi r3, REG_SFXDB_ADDRESS, SFXDB_FRAMES
mulli r4, REG_SOUND_WRITE_INDEX, SFXS_FRAME_SIZE
add REG_SFXS_FRAME_ADDRESS, r3, r4 # SFXS_FRAME address

# Start iterating through stable log. If ever a sound exists in the stable
# log but not in the pending log, we need to destroy that sound. This is n^2 atm
# probably not a huge deal because the sizes are small. It should be possible
# to make it nlogn I just don't know how in ASM
li REG_STABLE_CUR_IDX, 0
b STABLE_LOOP_CONDITION
STABLE_LOOP_START:

addi r6, REG_SFXS_FRAME_ADDRESS, SFXS_FRAME_PENDING_LOG # Pending log address
li r7, 0 # Pending log index
b PENDING_LOOP_CONDITION
PENDING_LOOP_START:

# Get current stable sound ID
mulli r3, REG_STABLE_CUR_IDX, SFXS_ENTRY_SIZE
add r3, r5, r3
lhz r3, SFXS_LOG_ENTRIES + SFXS_ENTRY_SOUND_ID(r3) # Current stable sound ID

# Get current pending sound ID
mulli r4, r7, SFXS_ENTRY_SIZE
add r4, r6, r4
lhz r4, SFXS_LOG_ENTRIES + SFXS_ENTRY_SOUND_ID(r4) # Current pending sound ID

cmpw r3, r4
beq STABLE_LOOP_CONTINUE # Stable sound has been found, move to next sound

PENDING_LOOP_CONTINUE:
addi r7, r7, 1
PENDING_LOOP_CONDITION:
lbz r3, SFXS_LOG_INDEX(r6)
cmpwi r7, r3
blt PENDING_LOOP_START

# If we exit loop normally, let's stop sound
mulli r3, REG_STABLE_CUR_IDX, SFXS_ENTRY_SIZE
add r3, r5, r3
lwz r3, SFXS_LOG_ENTRIES + SFXS_ENTRY_INSTANCE_ID(r3) # Current stable sound ID
branchl r12, 0x800236b8 # SFX_StopSFXInstance

STABLE_LOOP_CONTINUE:
addi REG_STABLE_CUR_IDX, REG_STABLE_CUR_IDX, 1 # increment
STABLE_LOOP_CONDITION:
addi r5, REG_SFXS_FRAME_ADDRESS, SFXS_FRAME_STABLE_LOG # Stable log address
lbz r3, SFXS_LOG_INDEX(r5)
cmpw REG_STABLE_CUR_IDX, r3
blt STABLE_LOOP_START # If cur index is lower than length, do loop
SOUND_TERMINATE_END:

################################################################################
# Transfer pending log into stable log
################################################################################
# Set SFXS_FRAME address again in case previous section was skipped
addi r3, REG_SFXDB_ADDRESS, SFXDB_FRAMES
mulli r4, REG_SOUND_WRITE_INDEX, SFXS_FRAME_SIZE
add REG_SFXS_FRAME_ADDRESS, r3, r4 # SFXS_FRAME address

COPY_PENDING_TO_STABLE:
addi r3, REG_SFXS_FRAME_ADDRESS, SFXS_FRAME_STABLE_LOG
addi r4, REG_SFXS_FRAME_ADDRESS, SFXS_FRAME_PENDING_LOG
li r5, SFXS_LOG_SIZE
branchl r12, memcpy

# Zero out pending such that on next use, it has a zero index
addi r3, REG_SFXS_FRAME_ADDRESS, SFXS_FRAME_PENDING_LOG
li r4, SFXS_LOG_SIZE
branchl r12, Zero_AreaLength

# If new frame, we need to increment the write index
cmpw REG_CURRENT_FRAME, REG_LATEST_FRAME
ble SKIP_NEW_FRAME_PROCESSING

# Store new latest frame
stw REG_CURRENT_FRAME, ODB_LATEST_FRAME(REG_ODB_ADDRESS)

# Rollback not active, increment the write index for sounds
addi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, 1
cmpwi REG_SOUND_WRITE_INDEX, ROLLBACK_MAX_FRAME_COUNT
blt SKIP_WRITE_INDEX_ADJUST
subi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, ROLLBACK_MAX_FRAME_COUNT

SKIP_WRITE_INDEX_ADJUST:
stb REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)

SKIP_NEW_FRAME_PROCESSING:

# Restore interrupts
mr r3, REG_INTERRUPT_IDX
branchl r12, OSRestoreInterrupts

lbz REG_IS_ROLLBACK_ACTIVE, ODB_STABLE_ROLLBACK_IS_ACTIVE(REG_ODB_ADDRESS)
cmpwi REG_IS_ROLLBACK_ACTIVE, 1
bne RESTORE_AND_EXIT # If no rollback active, continue as normal

# Here we have a rollback, we are going to loop back to the start of the
# updateFunction loop
bl FN_ExecCameraTasks

# Loop back to start of updateFunction loop
restore
branch r12, 0x801a4de4 # Continue rollback, branch to the start of game engine loop

# Functions section
FunctionBody_ExecCameraTasks

# Terminate code
RESTORE_AND_EXIT:
restore

EXIT:
