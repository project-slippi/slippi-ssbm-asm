################################################################################
# Address: 0x8038d224 # SFX_PlaySFX after instance ID has been written
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Execute replaced code line
stw r0, -0x3F18 (r13)

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

CODE_START:
.set REG_ODB_ADDRESS, 31
.set REG_SFXDB_ADDRESS, 30
.set REG_SME_ENTRY, 29 # from caller
.set REG_WRITE_INDEX, 28

backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address
addi REG_SFXDB_ADDRESS, REG_ODB_ADDRESS, ODB_SFXDB_START

lbz REG_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
loadGlobalFrame r3
lwz r4, ODB_LATEST_FRAME(REG_ODB_ADDRESS)
cmpw r3, r4
bgt ADJUST_WRITE_INDEX_END # If new frame, skip check if we should play sound

ADJUST_WRITE_INDEX_OLD_FRAME:
# First let's determine the write index for the current frame
loadGlobalFrame r3
lwz r4, ODB_LATEST_FRAME(REG_ODB_ADDRESS)

# If we are on the last frame that was run before a ffw, the following
# will equal 1 I believe. The ffw end frame was never actually processed
sub r3, r4, r3
addi r3, r3, 1

lbz REG_WRITE_INDEX, SFXDB_WRITE_INDEX(REG_SFXDB_ADDRESS)
sub. REG_WRITE_INDEX, REG_WRITE_INDEX, r3
bge ADJUST_WRITE_INDEX_END
addi REG_WRITE_INDEX, REG_WRITE_INDEX, ROLLBACK_MAX_FRAME_COUNT
ADJUST_WRITE_INDEX_END:

FETCH_LOG_ADDRESS:
mulli r3, REG_WRITE_INDEX, SFXS_FRAME_SIZE
addi r6, REG_SFXDB_ADDRESS, SFXDB_FRAMES + SFXS_FRAME_PENDING_LOG
add r6, r6, r3 # SFX log address

FETCH_ENTRY_ADDRESS:
lbz r3, SFXS_LOG_INDEX(r6)
subi r3, r3, 1 # remove 1 because it was just incremented in PreventDuplicateSounds
mulli r3, r3, SFXS_ENTRY_SIZE
addi r5, r6, SFXS_LOG_ENTRIES
add r5, r5, r3

STORE_INSTANCE_ID:
lwz r3, 0xC(REG_SME_ENTRY)
stw r3, SFXS_ENTRY_INSTANCE_ID(r5)

restore

EXIT:
