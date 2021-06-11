################################################################################
# Address: 0x8038d0b0 # SFX_PlaySFX after all inputs and r9 have been used?
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

################################################################################
# Short Circuit Conditions
################################################################################
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
.set REG_IS_SOUND_ACTIVE, 29
.set REG_WRITE_INDEX, 28
.set REG_SOUND_ID, 27
.set REG_SOUND_INSTANCE_ID, 26

backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
addi REG_SFXDB_ADDRESS, REG_ODB_ADDRESS, ODB_SFXDB_START
li REG_IS_SOUND_ACTIVE, 0
li REG_SOUND_INSTANCE_ID, 0
rlwinm REG_SOUND_ID, r23, 0, 0xFFFF # Extract half word from sound ID input

#exilogf LOG_LEVEL_WARN, "Play SFX %x, Frame: %d, Rollback: %d", "mr r5, REG_SOUND_ID", "loadGlobalFrame r6", "lbz r7, ODB_STABLE_ROLLBACK_IS_ACTIVE(REG_ODB_ADDRESS)"

lbz REG_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
loadGlobalFrame r3
lwz r4, ODB_LATEST_FRAME(REG_ODB_ADDRESS)
cmpw r3, r4
bgt STORE_SOUND # If new frame, skip check if we should play sound

CHECK_SOUND:
# First let's determine the write index for the current frame
loadGlobalFrame r3
lwz r4, ODB_LATEST_FRAME(REG_ODB_ADDRESS)

# If we are on the last frame that was run before a ffw, the following
# will equal 1 I believe. The ffw end frame was never actually processed
sub r3, r4, r3
addi r3, r3, 1

lbz REG_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
sub. REG_WRITE_INDEX, REG_WRITE_INDEX, r3
bge FETCH_LOG_ADDRESS
addi REG_WRITE_INDEX, REG_WRITE_INDEX, ROLLBACK_MAX_FRAME_COUNT

FETCH_LOG_ADDRESS:
mulli r3, REG_WRITE_INDEX, SFXS_FRAME_SIZE
addi r6, REG_SFXDB_ADDRESS, SFXDB_FRAMES + SFXS_FRAME_STABLE_LOG
add r6, r6, r3

li r8, 0
b FIND_SOUND_LOOP_CONDITION
FIND_SOUND_LOOP_START:
mulli r3, r8, SFXS_ENTRY_SIZE
addi r5, r6, SFXS_LOG_ENTRIES
add r5, r5, r3

# Load sound ID and check if it is equal to this one
lhz r3, SFXS_ENTRY_SOUND_ID(r5)
cmpw REG_SOUND_ID, r3
beq SOUND_ALREADY_PLAYED

FIND_SOUND_LOOP_CONTINUE:
addi r8, r8, 1

FIND_SOUND_LOOP_CONDITION:
lbz r3, SFXS_LOG_INDEX(r6)
cmpw r8, r3
blt FIND_SOUND_LOOP_START

#exilogf LOG_LEVEL_ERROR, "SFX %x NOT found. End frame: %d", "mr r5, REG_SOUND_ID", "lwz r6, ODB_STABLE_ROLLBACK_END_FRAME(REG_ODB_ADDRESS)"
b STORE_SOUND

SOUND_ALREADY_PLAYED:
#exilogf LOG_LEVEL_WARN, "SFX %x found. End frame: %d", "mr r5, REG_SOUND_ID", "lwz r6, ODB_STABLE_ROLLBACK_END_FRAME(REG_ODB_ADDRESS)"
lwz REG_SOUND_INSTANCE_ID, SFXS_ENTRY_INSTANCE_ID(r5)
li REG_IS_SOUND_ACTIVE, 1

STORE_SOUND:
mulli r3, REG_WRITE_INDEX, SFXS_FRAME_SIZE
addi r6, REG_SFXDB_ADDRESS, SFXDB_FRAMES + SFXS_FRAME_PENDING_LOG
add r6, r6, r3 # SFXS_LOG

# Get entry start address
lbz r3, SFXS_LOG_INDEX(r6)
cmpwi r3, MAX_SOUNDS_PER_FRAME
bge SKIP_PLAY_IF_NEEDED # Don't write if index is too high

mulli r3, r3, SFXS_ENTRY_SIZE
addi r5, r6, SFXS_LOG_ENTRIES
add r5, r5, r3 # SFXS_ENTRY

# Write sound to entry
sth REG_SOUND_ID, SFXS_ENTRY_SOUND_ID(r5)

# Instance ID will be 0 here if new sound and set later in AssignSoundInstanceId
stw REG_SOUND_INSTANCE_ID, SFXS_ENTRY_INSTANCE_ID(r5)

# Increment pending log index
lbz r3, SFXS_LOG_INDEX(r6)
addi r3, r3, 1
stb r3, SFXS_LOG_INDEX(r6)

SKIP_PLAY_IF_NEEDED:
# Check if we should skip playing this sound
cmpwi REG_IS_SOUND_ACTIVE, 0
beq RESTORE_AND_EXIT

# Set r3 to sound instance ID? Function normally returns this
mr r3, REG_SOUND_INSTANCE_ID

# Skip playing sound
restore
branch r12, 0x8038d2a0

RESTORE_AND_EXIT:
restore

EXIT:
# Run replaced instruction
cmpwi r26, 0
