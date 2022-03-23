################################################################################
# Address: FN_LoadSavestate
################################################################################
# Inputs:
# r3 - Address of the transfer buffer used to communicate with Dolphin
# r4 - Frame index to load
# r5 - Address of the control buffer for savestates
################################################################################
# Description:
# Loads data stored by SaveState into memory. Will bring back the state of the
# game at the time the save happened
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Alarm.s"

.set REG_SSRB_ADDR, 27
.set REG_SSCB_ADDR, 26
.set REG_SSDB_ADDR, 25
.set REG_FRAME_INDEX, 24
.set REG_INTERRUPT_IDX, 23
.set REG_VARIOUS_1, 22
.set REG_VARIOUS_2, 21
.set REG_VARIOUS_3, 20

backup

# Handle inputs
mr REG_SSRB_ADDR, r3
mr REG_FRAME_INDEX, r4
mr REG_SSCB_ADDR, r5

# Determine the SSDB Ptr to read from
lbz r6, SSCB_WRITE_INDEX(REG_SSCB_ADDR)

.set REG_LOOP_COUNT, REG_VARIOUS_1

li REG_LOOP_COUNT, 0

# This loop will find the savestate we want to load. Currently there really
# isn't anything useful in the ASM-side savestates so currently this logic only really exists
# to ensure we saved a state for the frame requested
FIND_FRAME_LOOP_START:
addi REG_LOOP_COUNT, REG_LOOP_COUNT, 1
cmpwi REG_LOOP_COUNT, ROLLBACK_MAX_FRAME_COUNT
ble LIMIT_NOT_REACHED
# If we get here, the frame requested has not been saved. Perhaps the correct thing to do here
# is to end the game similar to DISCONNECTED but for now let's just assert
logf LOG_LEVEL_NOTICE, "Load state requested for frame %d but frame was not found.", "mr r5, REG_FRAME_INDEX"
b 0
LIMIT_NOT_REACHED:
subi r6, r6, 1
cmpwi r6, 0
bge SKIP_IDX_ADJUST
addi r6, r6, ROLLBACK_MAX_FRAME_COUNT
SKIP_IDX_ADJUST:
mulli r3, r6, SSDB_SIZE
addi r3, r3, SSCB_SSDB_START
add REG_SSDB_ADDR, REG_SSCB_ADDR, r3
lwz r3, SSDB_FRAME(REG_SSDB_ADDR) # Load frame of this save state.
cmpw r3, REG_FRAME_INDEX
bne FIND_FRAME_LOOP_START

CONTINUE_SAVESTATE:
branchl r12, OSDisableInterrupts
mr REG_INTERRUPT_IDX, r3

################################################################################
# Back up sounds
################################################################################
/*
lwz r5, -0x3f0c(r13) # Load ptr to first sound
addi r6, REG_SSCB_ADDR, SSCB_SSPLB_START + SSPLB_SOUND_ENTRIES # Start of sound backups
li r7, 0
load r4, 0x804b09e0 # Sound table start location?

b SOUND_BKP_LOOP_CONDITION
SOUND_BKP_LOOP_START:
cmpwi r5, 0
beq SOUND_BKP_NO_SOUND

lwz r3, 0x10(r5)
cmpwi r3, -1
beq SOUND_BKP_NO_SOUND

rlwinm r3, r3, 0, 0x3f
mulli r3, r3, 0xC0
add r3, r4, r3
lwz r3, 0x7a(r3) # Load sound location
stw r3, SSPLB_SOUND_ENTRY_LOC(r6)

lwz r3, 0xC(r5) # Load sound ID
stw r3, SSPLB_SOUND_ENTRY_ID(r6) # Store sound ID

lwz r5, 0x4(r5) # Load next sound entry
b SOUND_BKP_LOOP_CONTINUE

SOUND_BKP_NO_SOUND:
li r3, 0
stw r3, SSPLB_SOUND_ENTRY_ID(r6) # Store sound ID

SOUND_BKP_LOOP_CONTINUE:
addi r6, r6, SSPLB_SOUND_ENTRY_SIZE # Move to next backup entry
addi r7, r7, 1
SOUND_BKP_LOOP_CONDITION:
cmpwi r7, SOUND_ENTRY_COUNT
blt SOUND_BKP_LOOP_START
*/

################################################################################
# EXI Load state
################################################################################
LOAD_STATE_EXI:
li r3, CONST_SlippiCmdLoadSavestate
stb r3, SSRB_COMMAND(REG_SSRB_ADDR)

stw REG_FRAME_INDEX, SSRB_FRAME(REG_SSRB_ADDR)

# Transfer buffer over DMA
mr r3, REG_SSRB_ADDR
li r4, SSRB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

################################################################################
# Restore sounds
################################################################################
/*
.set REG_SOUND_PTR, REG_VARIOUS_1
.set REG_SOUND_ENTRY_0, REG_VARIOUS_2
.set REG_BKP_IDX, REG_VARIOUS_3

lwz REG_SOUND_PTR, -0x3f0c(r13) # Load ptr to first sound
addi REG_SOUND_ENTRY_0, REG_SSCB_ADDR, SSCB_SSPLB_START + SSPLB_SOUND_ENTRIES # Start of sound backups

b SOUND_RESTORE_LOOP_CONDITION
SOUND_RESTORE_LOOP_START:
lwz r3, 0xC(REG_SOUND_PTR) # Load sound ID

li REG_BKP_IDX, 0

SOUND_RESTORE_INNER_LOOP_START:
mulli r4, REG_BKP_IDX, SSPLB_SOUND_ENTRY_SIZE
add r5, REG_SOUND_ENTRY_0, r4
lwz r4, SSPLB_SOUND_ENTRY_ID(r5)
cmpw r3, r4
beq SOUND_RESTORE_UPDATE_POS

# Continue inner loop
addi REG_BKP_IDX, REG_BKP_IDX, 1
cmpwi REG_BKP_IDX, SOUND_ENTRY_COUNT
blt SOUND_RESTORE_INNER_LOOP_START

# If ID was not found in backup, stop this sound
lwz r3, 0xC(REG_SOUND_PTR)
branchl r12, SFX_StopSFXInstance

b SOUND_RESTORE_LOOP_CONTINUE

SOUND_RESTORE_UPDATE_POS:
lwz r3, 0x10(REG_SOUND_PTR)
cmpwi r3, -1
beq SOUND_RESTORE_LOOP_CONTINUE

rlwinm r3, r3, 0, 0x3f
mulli r3, r3, 0xC0
load r4, 0x804b09e0
add r4, r4, r3
lwz r3, SSPLB_SOUND_ENTRY_LOC(r5)
stw r3, 0x7a(r4) # Store sound location

SOUND_RESTORE_LOOP_CONTINUE:
lwz REG_SOUND_PTR, 0x4(REG_SOUND_PTR)
SOUND_RESTORE_LOOP_CONDITION:
cmpwi REG_SOUND_PTR, 0
bne SOUND_RESTORE_LOOP_START
*/

################################################################################
# End
################################################################################
RESTORE_AND_EXIT:
# Restore interrupts
mr r3, REG_INTERRUPT_IDX
branchl r12, OSRestoreInterrupts

EXIT:
restore
blr
