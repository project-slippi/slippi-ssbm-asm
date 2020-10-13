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

.set PAYLOAD_LEN, 0x3F
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
# Each player has a heap-allocated struct, make sure the ptr is not NULL before reading

load r4, CSS_CURSOR_STRUCT_PTR_P1
lwz r4, 0(r4)
cmpwi r4, 0
bne SendP1Cursor

# set cursor values to 0
load r5, 0x00000000
stw r5, 0x3(r3)
stw r5, 0x7(r3)
b P2_Cursor

SendP1Cursor:
# Load cursor x position
lwz r5, 0x0c(r4)
stw r5, 0x3(r3)
# Load cursor y position
lwz r5, 0x10(r4)
stw r5, 0x7(r3)

P2_Cursor:
load r4, CSS_CURSOR_STRUCT_PTR_P2
lwz r4, 0(r4)
cmpwi r4, 0
bne SendP2Cursor

# set cursor values to 0
load r5, 0x00000000
stw r5, 0xB(r3)
stw r5, 0xF(r3)
b P3_Cursor

SendP2Cursor:
# Load cursor x position
lwz r5, 0x0c(r4)
stw r5, 0xB(r3)
# Load cursor y position
lwz r5, 0x10(r4)
stw r5, 0xF(r3)

P3_Cursor:
load r4, CSS_CURSOR_STRUCT_PTR_P3
lwz r4, 0(r4)
cmpwi r4, 0
bne SendP3Cursor

# set p1 cursor values to 0
load r5, 0x00000000
stw r5, 0x13(r3)
stw r5, 0x17(r3)
b P4_Cursor

SendP3Cursor:
# Load cursor x position
lwz r5, 0x0c(r4)
stw r5, 0x13(r3)
# Load cursor y position
lwz r5, 0x10(r4)
stw r5, 0x17(r3)

P4_Cursor:
load r4, CSS_CURSOR_STRUCT_PTR_P4
lwz r4, 0(r4)
cmpwi r4, 0
bne SendP4Cursor

# set p1 cursor values to 0
load r5, 0x00000000
stw r5, 0x1B(r3)
stw r5, 0x1F(r3)
b CURSORS_DONE

SendP4Cursor:
# Load cursor x position
lwz r5, 0x0c(r4)
stw r5, 0x1B(r3)
# Load cursor y position
lwz r5, 0x10(r4)
stw r5, 0x1F(r3)

CURSORS_DONE:

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

# 0x0102 is offline SSS
# 0x0108 is online SSS
cmpwi r8, 0x0102
beq Is_SSS
cmpwi r8, 0x0108
beq Is_SSS
b Not_SSS

Is_SSS:

# Stage Select Cursor X
# 4-byte float
load r4 0x804D7820
lwz r4, 0(r4)
addi r4, r4, 0x10
lwz r4, 0(r4)
addi r4, r4, 0x28
lwz r4, 0(r4)
addi r4, r4, 0x38
lwz r4, 0(r4)
stw r4, 0x31(r3)

# Stage Select Cursor y
# 4-byte float
load r4 0x804D7820
lwz r4, 0(r4)
addi r4, r4, 0x10
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

# Sub-menu
load r4 0x804A04F0
lbz r4, 0(r4)
stb r4, 0x3D(r3)

# Menu selection index
load r4 0x804A04F3
lbz r4, 0(r4)
stb r4, 0x3E(r3)

#------------- Transfer Buffer ------------
# r3 is the buffer arg, but it's already set
li r4, EXI_BUF_LEN
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

Injection_Exit:

restore STACK_FREE_SPACE
lwz r3, 0(r25) # replaced code line
