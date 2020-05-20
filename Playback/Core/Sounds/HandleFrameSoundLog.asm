################################################################################
# Address: 0x801a5014 # updateFunction, branch instruction
################################################################################

.include "Common/Common.s"
.include "Playback/Playback.s"

# run equivalent code
beq+ START
branch r12, 0x801a5024 # go to where branch would have taken us

################################################################################
# Handle Sound updates function
################################################################################
.set REG_PDB_ADDRESS, 31
.set REG_SFXDB_ADDRESS, 30
.set REG_INTERRUPT_IDX, 29
.set REG_SOUND_WRITE_INDEX, 28
.set REG_PLAYBACK_STATUS, 27
.set REG_CURRENT_FRAME, 26
.set REG_LATEST_FRAME, 25

START:
backup

branchl r12, OSDisableInterrupts # Not backing up r3 output, don't use r3 in body
mr REG_INTERRUPT_IDX, r3

lwz REG_PDB_ADDRESS, primaryDataBuffer(r13) # data buffer address
addi REG_SFXDB_ADDRESS, REG_PDB_ADDRESS, PDB_SFXDB_START

lbz REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
loadGlobalFrame REG_CURRENT_FRAME
subi REG_CURRENT_FRAME, REG_CURRENT_FRAME, 1 # remove 1 from frame index because global frame has already been incremented
lwz REG_LATEST_FRAME, PDB_LATEST_FRAME(REG_PDB_ADDRESS)
cmpw REG_CURRENT_FRAME, REG_LATEST_FRAME
bgt COPY_PENDING_TO_STABLE # If new frame, don't adjust write index

# Let's determine the write index for the current frame
addi r4, REG_LATEST_FRAME, 1 # Simulate the latest frame being 1 frame ahead (would be the case for recording)

# If we are on the last frame that was run before a ffw, the following
# will equal 1 I believe. The ffw end frame was never actually processed
sub r3, r4, REG_CURRENT_FRAME

lbz REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
sub. REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, r3
bge COPY_PENDING_TO_STABLE
addi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, SOUND_STORAGE_FRAME_COUNT
# TODO: Determine sounds to kill here

COPY_PENDING_TO_STABLE:
mulli r5, REG_SOUND_WRITE_INDEX, SFXS_FRAME_SIZE
add r5, REG_SFXDB_ADDRESS, r5
addi r3, r5, SFXDB_FRAMES + SFXS_FRAME_STABLE_LOG
addi r4, r5, SFXDB_FRAMES + SFXS_FRAME_PENDING_LOG
li r5, SFXS_LOG_SIZE
branchl r12, memcpy

# Zero out pending such that on next use, it has a zero index
mulli r5, REG_SOUND_WRITE_INDEX, SFXS_FRAME_SIZE
add r5, REG_SFXDB_ADDRESS, r5
addi r3, r5, SFXDB_FRAMES + SFXS_FRAME_PENDING_LOG
li r4, SFXS_LOG_SIZE
branchl r12, Zero_AreaLength

# If new frame, we need to increment the write index
cmpw REG_CURRENT_FRAME, REG_LATEST_FRAME
ble SKIP_NEW_FRAME_PROCESSING

# Store new latest frame
stw REG_CURRENT_FRAME, PDB_LATEST_FRAME(REG_PDB_ADDRESS)

# ffw not active, increment the write index for sounds
addi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, 1
cmpwi REG_SOUND_WRITE_INDEX, SOUND_STORAGE_FRAME_COUNT
blt SKIP_WRITE_INDEX_ADJUST
subi REG_SOUND_WRITE_INDEX, REG_SOUND_WRITE_INDEX, SOUND_STORAGE_FRAME_COUNT

SKIP_WRITE_INDEX_ADJUST:
stb REG_SOUND_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)

SKIP_NEW_FRAME_PROCESSING:

# Restore interrupts
mr r3, REG_INTERRUPT_IDX
branchl r12, OSRestoreInterrupts

restore
