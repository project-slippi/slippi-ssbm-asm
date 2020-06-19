################################################################################
# Address: 0x801a4fa4
################################################################################

################################################################################
# Routine: SendMenuFrame
# ------------------------------------------------------------------------------
# Description: Gets menu information and sends it to the Slippi device
################################################################################

.include "Common/Common.s"
.include "Recording/Recording.s"

.set PAYLOAD_LEN, 0x3D
.set EXI_BUF_LEN, PAYLOAD_LEN + 1

.set STACK_FREE_SPACE, EXI_BUF_LEN + 0x20 # Add 0x20 to deal with byte alignment

.set STACK_OFST_EXI_BUF, BKP_FREE_SPACE_OFFSET

backup STACK_FREE_SPACE

# check if NOT VS Mode
getMinorMajor r8
cmpwi r8, 0x0202
beq Injection_Exit
cmpwi r8, 0x0208
beq Injection_Exit

addi r3, sp, STACK_OFST_EXI_BUF # This is the start address for the free space
byteAlign32 r3 # Align to next 32 byte boundary

li r4, CMD_MENU_FRAME # Command byte
stb r4, 0x0(r3)

# Two bytes for major / minor scene
sth r8, 0x1(r3)

# send player 1 cursor x position
load r4 0x81118DEC
lwz r4, 0(r4)
stw r4, 0x3(r3)

# send player 1 cursor y position
load r4 0x81118DF0
lwz r4, 0(r4)
stw r4, 0x7(r3)

# send player 2 cursor x position
load r4 0x8111826C
lwz r4, 0(r4)
stw r4, 0xB(r3)

# send player 2 cursor y position
load r4 0x81118270
lwz r4, 0(r4)
stw r4, 0xF(r3)

# send player 3 cursor x position
load r4 0x811176EC
lwz r4, 0(r4)
stw r4, 0x13(r3)

# send player 3 cursor y position
load r4 0x811176F0
lwz r4, 0(r4)
stw r4, 0x17(r3)

# send player 4 cursor x position
load r4 0x8111674C
lwz r4, 0(r4)
stw r4, 0x1B(r3)

# send player 4 cursor y position
load r4 0x81116750
lwz r4, 0(r4)
stw r4, 0x1F(r3)

# Ready to fight banner visible (one byte)
# banner "swoops in" frame by frame
#   value of 10 is fully invisible (not ready to play)
#   value of 0 is fully visible (ready to play)
load r4 0x804d6cf2
lbz r4, 0(r4)
stb r4, 0x23(r3)

# Stage selected (one byte)
load r4 0x804D6CAD
lbz r4, 0(r4)
stb r4, 0x24(r3)

# controller port statuses at CSS (each one byte)
# 0 == Human
# 1 == CPU
# 3 == Off
# Player 1
load r4 0x803F0E08
lbz r4, 0(r4)
stb r4, 0x25(r3)
# Player 2
load r4 0x803F0E2C
lbz r4, 0(r4)
stb r4, 0x26(r3)
# Player 3
load r4 0x803F0E50
lbz r4, 0(r4)
stb r4, 0x27(r3)
# Player 4
load r4 0x803F0E74
lbz r4, 0(r4)
stb r4, 0x28(r3)

# Character selected (each one byte)
# Player 1
load r4 0x803F0E0A
lbz r4, 0(r4)
stb r4, 0x29(r3)
# Player 2
load r4 0x803F0E2E
lbz r4, 0(r4)
stb r4, 0x2A(r3)
# Player 3
load r4 0x803F0E52
lbz r4, 0(r4)
stb r4, 0x2B(r3)
# Player 4
load r4 0x803F0E76
lbz r4, 0(r4)
stb r4, 0x2C(r3)

# Coin down
# 0 == No coin
# 1 == Coin in hand
# 2 == Coin down
# 3 == Not plugged in

# Reading this value involves needing to follow a dynamic pointer
# This can segfault when not in the right scene
# So just return 0's when not in there and don't follow the pointers

# Load 0's into player coins
load r4 0x00000000
stw r4, 0x2D(r3)

cmpwi r8, 0x0002
bne Not_CSS

# Player 1
load r4 0x804a0bc0
lwz r4, 0(r4)
addi r4, r4, 5
lbz r4, 0(r4)
stb r4, 0x2D(r3)
# Player 2
load r4 0x804a0bc4
lwz r4, 0(r4)
addi r4, r4, 5
lbz r4, 0(r4)
stb r4, 0x2E(r3)
# Player 3
load r4 0x804a0bc8
lwz r4, 0(r4)
addi r4, r4, 5
lbz r4, 0(r4)
stb r4, 0x2F(r3)
# Player 4
load r4 0x804a0bcc
lwz r4, 0(r4)
addi r4, r4, 5
lbz r4, 0(r4)
stb r4, 0x30(r3)

Not_CSS:

# Reading this value involves needing to follow a dynamic pointer
# This can segfault when not in the right scene
# So just return 0's when not in there and don't follow the pointers

# Load 0's into cursors
load r4 0x00000000
stw r4, 0x31(r3)
load r4 0x00000000
stw r4, 0x35(r3)

cmpwi r8, 0x0102
bne Not_SSS

# Stage Select Cursor X
# 4-byte float
load r4 0x80bda810
lwz r4, 0(r4)
addi r4, r4, 0x28
lwz r4, 0(r4)
addi r4, r4, 0x38
lwz r4, 0(r4)
stw r4, 0x31(r3)

# Stage Select Cursor y
# 4-byte float
load r4 0x80bda810
lwz r4, 0(r4)
addi r4, r4, 0x28
lwz r4, 0(r4)
addi r4, r4, 0x3C
lwz r4, 0(r4)
stw r4, 0x35(r3)

Not_SSS:

# Frame count
load r4 0x80479D60
lwz r4, 0(r4)
stw r4, 0x39(r3)

#------------- Transfer Buffer ------------
# r3 is the buffer arg, but it's already set
li r4, EXI_BUF_LEN
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

Injection_Exit:

restore STACK_FREE_SPACE
lwz r3, 0(r25) # replaced code line
