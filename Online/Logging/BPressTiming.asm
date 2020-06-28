################################################################################
# Address: 0x80376a24
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

branchl r12, 0x8034DA00 # Call PADRead

/*
b CODE_START

STRING:
blrl
.set STRING_LEN, 16
.string "In-game B Press"
.align 2

LAST_BUTTON_READ:
blrl
.byte 0x00
.align 2

CODE_START:
.set P1_PAD_OFFSET, 0x2C
.set TX_BUF, 29

# Get last buttons
bl LAST_BUTTON_READ
mflr r4
lbz r3, 0(r4)
rlwinm. r3, r3, 0, 0x02 # Check if b was pressed last frame

# Store this frame button press into last frame
lbz r3, P1_PAD_OFFSET(sp)
stb r3, 0(r4)

bne EXIT # If b was pressed last frame, don't log
rlwinm. r3, r3, 0, 0x02 # Check if b button is pressed this frame
beq EXIT # If b is not pressed this frame, don't log

LOG_B_PRESS:
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

EXIT:
*/
