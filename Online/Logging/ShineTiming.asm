################################################################################
# Address: 0x800e8598
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

/*
b CODE_START

STRING:
blrl
.set STRING_LEN, 12
.string "Shine start"
.align 2

CODE_START:
.set TX_BUF, 29

backup

li r3, STRING_LEN
addi r3, r3, 1
branchl r12, HSD_MemAlloc
mr TX_BUF, r3

addi r3, r3, 1
bl STRING
mflr r4
li r5, STRING_LEN
branchl r12, memcpy

li r3, 0xD0
stb r3, 0(TX_BUF)

mr r3, TX_BUF # Use the receive buffer to send the command
li r4, STRING_LEN
addi r4, r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, TX_BUF
branchl r12, HSD_Free

restore
*/

EXIT:
lwz r7, 0x002C(r31)
