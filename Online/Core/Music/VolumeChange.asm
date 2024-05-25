################################################################################
# Address: 0x800249f0 # DSP_Process, where volume is written
################################################################################

.include "Common/Common.s"

.set REG_CMVQ, 31
.set REG_DATA, 30

# This space will be used to transfer over EXI. EXI buffers must be 32 byte aligned though
# so we don't know exactly where the buffer will start
.set SPO_EXI_SPACE_START, BKP_FREE_SPACE_OFFSET

# PlayMusicQuery args
.set CMVQ_COMMAND, 0
.set CMVQ_VOLUME, CMVQ_COMMAND + 1
.set CMVQ_SIZE, CMVQ_VOLUME + 1

# Grab enough space that no matter where we are, we can byteAlign32 and still fit the CMVQ data
.set SPACE_NEEDED, SPO_EXI_SPACE_START + CMVQ_SIZE + 32

b CODE_START

DATA_BLRL:
blrl
.set DO_PREV_VOLUME, 0
.long 0x00000000

CODE_START:
stw r0, -0x7E18(r13) # replaced code line

backup SPACE_NEEDED

bl DATA_BLRL
mflr REG_DATA

lwz r4, -0x7E18(r13) # load new value
lwz r3, DO_PREV_VOLUME(REG_DATA) # load old value
cmpw r3, r4
beq CLEANUP_AND_EXIT

# Update prev value to current
stw r4, DO_PREV_VOLUME(REG_DATA)

# Here the volume differs from the previous. Let's send the new volume to Dolphin
# mr r5, r4
# logf LOG_LEVEL_WARN, "[Music] Volume changed: %d"

addi REG_CMVQ, sp, SPO_EXI_SPACE_START
byteAlign32 REG_CMVQ

# Write command
li r3, CONST_SlippiChangeMusicVolume
stb r3, CMVQ_COMMAND(REG_CMVQ)

# Write new volume
stb r4, CMVQ_VOLUME(REG_CMVQ)

# Exec EXI transfer
mr r3, REG_CMVQ
li r4, CMVQ_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

CLEANUP_AND_EXIT:
restore SPACE_NEEDED