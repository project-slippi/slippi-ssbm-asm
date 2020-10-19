################################################################################
# Address: 0x800882b0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_ODB_ADDRESS, 31
.set REG_SOUND_ID, 30 # from caller
.set REG_SFXDB_ADDRESS, 29
.set REG_WRITE_INDEX, 28

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
addi REG_SFXDB_ADDRESS, REG_ODB_ADDRESS, ODB_SFXDB_START

rlwinm REG_SOUND_ID, REG_SOUND_ID, 0, 0xFFFF # extract half word ID

lbz REG_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
loadGlobalFrame r3
lwz r4, ODB_LATEST_FRAME(REG_ODB_ADDRESS)
cmpw r3, r4
bgt RESTORE_AND_EXIT # If new frame, skip check if we should play sound

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

b RESTORE_AND_EXIT

SOUND_ALREADY_PLAYED:
# Skip destroy functions
restore
branch r12, 0x800882d0

RESTORE_AND_EXIT:
restore

EXIT:
addi r3, r31, 0
