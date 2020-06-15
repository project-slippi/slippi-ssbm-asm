################################################################################
# Address: 0x801a4fa4
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

.set PAYLOAD_LEN, 0x13
.set EXI_BUF_LEN, PAYLOAD_LEN + 1

.set STACK_FREE_SPACE, EXI_BUF_LEN + 0x20 # Add 0x20 to deal with byte alignment

.set STACK_OFST_EXI_BUF, BKP_FREE_SPACE_OFFSET

backup STACK_FREE_SPACE
mr r3, sp
addi r3, r3, STACK_OFST_EXI_BUF # This is the start address for the free space
byteAlign32 r3 # Align to next 32 byte boundary

li r4, 0xD0 # Command byte
stb r4, 0(r3)

li r4, EXI_BUF_LEN
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

restore STACK_FREE_SPACE
lwz r3, 0(r25) # replaced code line
