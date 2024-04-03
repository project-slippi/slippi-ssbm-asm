################################################################################
# Address: 0x8038e910 # fileLoad_HPS, after entry num is fetched
################################################################################

.include "Common/Common.s"

.set REG_PMQ, 31
.set REG_ENTRYNUM, 30
.set REG_INTERRUPT_IDX, 29

# This will contain the DVDFileInfo struct which has length 0x40
.set SPO_STRUCT_START, BKP_FREE_SPACE_OFFSET
.set SPO_FILE_OFFSET, SPO_STRUCT_START + 0x30
.set SPO_FILE_SIZE, SPO_FILE_OFFSET + 4

# This space will be used to transfer over EXI. EXI buffers must be 32 byte aligned though
# so we don't know exactly where the buffer will start
.set SPO_EXI_SPACE_START, SPO_STRUCT_START + 0x40

# PlayMusicQuery args
.set PMQ_COMMAND, 0
.set PMQ_FILE_OFFSET, PMQ_COMMAND + 1
.set PMQ_FILE_SIZE, PMQ_FILE_OFFSET + 4
.set PMQ_SIZE, PMQ_FILE_SIZE + 4 # Confusing but this is the size of the buffer

# Grab enough space that no matter where we are, we can byteAlign32 and still fit the PMQ data
.set SPACE_NEEDED, SPO_EXI_SPACE_START + PMQ_SIZE + 32

backup SPACE_NEEDED

mr REG_ENTRYNUM, r3

branchl r12, OSDisableInterrupts
mr REG_INTERRUPT_IDX, r3

mr r3, REG_ENTRYNUM
addi r4, sp, SPO_STRUCT_START
branchl r12, 0x80337c60 # DVDFastOpen

# TODO: File_GetLength asserts when result = 0, hopefully just ignoring it and doing nothing is fine
cmpwi r3, 0
beq CLEANUP_AND_EXIT

# Log
# lwz r5, SPO_FILE_OFFSET(sp)
# lwz r6, SPO_FILE_SIZE(sp)
# logf LOG_LEVEL_WARN, "[Music] Starting song at 0x%x with size %d"

addi REG_PMQ, sp, SPO_EXI_SPACE_START
byteAlign32 REG_PMQ

# Write command
li r3, CONST_SlippiPlayMusic
stb r3, PMQ_COMMAND(REG_PMQ)

# Write file offset and size
lwz r3, SPO_FILE_OFFSET(sp)
stw r3, PMQ_FILE_OFFSET(REG_PMQ)
lwz r3, SPO_FILE_SIZE(sp)
stw r3, PMQ_FILE_SIZE(REG_PMQ)

# Exec EXI transfer
mr r3, REG_PMQ
li r4, PMQ_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

CLEANUP_AND_EXIT:
addi r3, sp, SPO_STRUCT_START
branchl r12, 0x80337cd4 # DVDClose

mr r3, REG_INTERRUPT_IDX
branchl r12, OSRestoreInterrupts

mr r3, REG_ENTRYNUM

restore SPACE_NEEDED

lwz r0, -0x5668(r13) # replaced code line