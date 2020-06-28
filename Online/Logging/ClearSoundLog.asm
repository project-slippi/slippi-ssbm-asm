################################################################################
# Address: 0x8038acfc
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

/*
b CODE_START

STRING:
blrl
.set BUF_LEN, 30 # Enough to contain string and additional format info
.string "Sound cleared: %x"
.align 2

CODE_START:
.set TX_BUF, 29
.set REG_R3_BKP, 28

backup

mr REG_R3_BKP, r3

li r3, BUF_LEN
branchl r12, HSD_MemAlloc
mr TX_BUF, r3

addi r3, TX_BUF, 1
bl STRING
mflr r4
addi r5, REG_R3_BKP, 0x384
branchl r12, 0x80323cf4 # sprintf

li r3, 0xD0
stb r3, 0(TX_BUF)

mr r3, TX_BUF # Use the receive buffer to send the command
li r4, BUF_LEN
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, TX_BUF
branchl r12, HSD_Free

mr r3, REG_R3_BKP

restore
*/

EXIT:
stw	r26, 0x0384(r3)
