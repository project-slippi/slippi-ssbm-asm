################################################################################
# Address: 0x800236ec # Music_StopMusic, after function call
################################################################################

.include "Common/Common.s"

.set REG_SMQ, 31

# This space will be used to transfer over EXI. EXI buffers must be 32 byte aligned though
# so we don't know exactly where the buffer will start
.set SPO_EXI_SPACE_START, BKP_FREE_SPACE_OFFSET

# PlayMusicQuery args
.set SMQ_COMMAND, 0
.set SMQ_SIZE, SMQ_COMMAND + 1

# Grab enough space that no matter where we are, we can byteAlign32 and still fit the SMQ data
.set SPACE_NEEDED, SPO_EXI_SPACE_START + SMQ_SIZE + 32

backup SPACE_NEEDED

# logf LOG_LEVEL_WARN, "[Music] Stopping music"

addi REG_SMQ, sp, SPO_EXI_SPACE_START
byteAlign32 REG_SMQ

# Write command
li r3, CONST_SlippiStopMusic
stb r3, SMQ_COMMAND(REG_SMQ)

# Exec EXI transfer
mr r3, REG_SMQ
li r4, SMQ_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

CLEANUP_AND_EXIT:
restore SPACE_NEEDED

li r0, 0 # replaced code line