################################################################################
# Address: 0x80376a28 # HSD_PadRenewRawStatus right after PAD_Read call
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set CONST_BACKUP_BYTES, 0xB0 # Maybe add this to Common.s
.set P1_PAD_OFFSET, CONST_BACKUP_BYTES + 0x2C

.set REG_SSDB_ADDR, 27
.set REG_FRAME_INDEX, 26

#backup registers and sp
backup

################################################################################
# Short Circuit Conditions
################################################################################

# Check if VS Mode
branchl r12, FN_IsVSMode
cmpwi r3, 0
beq EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

################################################################################
# Initialize
################################################################################

/*
lwz r3, 0x124(sp) # Load LR indicating this function call was done by interrupt
load r4, 0x80375e00
bne INITIALIZE

# Here we came from interrupt, right now we are hacking in a method to trigger
# this function only from updateFunction. We hope this will solve savestates.
# A better solution would be to trigger a different function on VIRetrace
# callback so we wouldn't have to do this stupid hack

li r3, 1
stw r3, SSDB_FRAME_COMPLETE(REG_SSDB_ADDR) # Indicate interupt handled

restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input
*/

INITIALIZE:
# Initialize data buffers on first frame
load r3, 0x80479d60
lwz REG_FRAME_INDEX, 0x0(r3) # 0x80479d60 - Global frame counter
cmpwi REG_FRAME_INDEX, 1 # On first frame of scene, we need to initialize our buffer
bne SKIP_ONLINE_DATA_INIT

li r3, SSDB_SIZE
branchl r12, HSD_MemAlloc
mr REG_SSDB_ADDR, r3
stw REG_SSDB_ADDR, OFST_R13_ODB_ADDR(r13)

/*
# Prepare to loop and find size
.set PLAYER_START, STATIC_PLAYER_BLOCK_P1 - STATIC_PLAYER_BLOCK_LEN
.set PLAYER_END, STATIC_PLAYER_BLOCK_P1 + STATIC_PLAYER_BLOCK_LEN

li r3, 0 # size
load r4, 0x80458fd0
lwz	r4, 0x20(r4) # load character block size
load r5, PLAYER_START # Load P1 Index - 0xE90, will be incremented each loop iteration
load r6, PLAYER_END # P2 Index, this is the termination index. only need 2 characters

GET_CHARACTER_BLOCK_SIZE_LOOP:
addi r5, r5, STATIC_PLAYER_BLOCK_LEN
cmpw r5, r6
bgt GET_CHARACTER_BLOCK_SIZE_END

add r3, r3, r4 # add size of one character block
lwz r7, 0xB4(r5)
cmpwi r7, 0
beq GET_CHARACTER_BLOCK_SIZE_LOOP

add r3, r3, r4 # this is either ICs or sheik, add another block
b GET_CHARACTER_BLOCK_SIZE_LOOP

GET_CHARACTER_BLOCK_SIZE_END:
branchl r12, HSD_MemAlloc
stw r3, SSDB_CHARACTER_DATA_ADDR(REG_SSDB_ADDR)
*/

# Prepare buffer for requesting savestate actions from Dolphin
li r3, SSRB_SIZE
branchl r12, HSD_MemAlloc
stw r3, SSDB_SSRB_ADDR(REG_SSDB_ADDR)
li r4, 0
stw r4, SSRB_ODB_ADDR(r3) # Just write terminator immediately, no need to save anything

SKIP_ONLINE_DATA_INIT:

# fetch data to use throughout function
lwz REG_SSDB_ADDR, OFST_R13_ODB_ADDR(r13) # data buffer address

################################################################################
# Check inputs
################################################################################

lbz r3, P1_PAD_OFFSET + 0x1(sp)
rlwinm r3, r3, 0, 0x1
cmpwi r3, 0
beq SKIP_BACKUP

mr r3, REG_SSDB_ADDR
branchl r12, FN_CaptureSavestate

restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input

SKIP_BACKUP:

lbz r3, P1_PAD_OFFSET + 0x1(sp)
rlwinm r3, r3, 0, 0x2
cmpwi r3, 0
beq SKIP_RESTORE

mr r3, REG_SSDB_ADDR
branchl r12, FN_LoadSavestate

restore
branch r12, 0x80376cec # branch to restore of parent function to skip handling input

SKIP_RESTORE:

################################################################################
# Exit
################################################################################

EXIT:
#restore registers and sp
restore
cmpwi r30, 0 # restore replaced instruction
