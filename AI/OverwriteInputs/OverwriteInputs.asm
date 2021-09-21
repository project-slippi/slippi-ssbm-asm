################################################################################
# Address: 0x80377598 # HSD_PadRenewMasterStatus
################################################################################

.include "Common/Common.s"

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
.long 0x80000000 # Placeholder for allocated memory pointer

CODE_START:
lfs	f29, -0x1430 (rtoc) # replaced code line

.set REG_RAW_PAD_START, 25 # Set by parent
.set REG_STATIC_MEM, 30
.set REG_BUF, 31

.set TXB_CMD, 0 # u8

.set RXPB_SHOULD_OVERWRITE, 0 # u8
.set RXPB_PAD_DATA, RXPB_SHOULD_OVERWRITE + 1 # u64
.set RXPB_SIZE, RXPB_PAD_DATA + 8

.set RXB_SIZE, RXPB_SIZE * 4

backup

bl STATIC_MEMORY_TABLE_BLRL
mflr REG_STATIC_MEM

loadGlobalFrame r3
cmpwi r3, 0
bne SKIP_ALLOC

# Prepare buffer for EXI transfer
li r3, RXB_SIZE
branchl r12, HSD_MemAlloc
stw r3, 0(REG_STATIC_MEM)

SKIP_ALLOC:
lwz REG_BUF, 0(REG_STATIC_MEM)

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdOvewriteInputs
stb r3, 0(REG_BUF)

# Request match state information
mr r3, REG_BUF # Use the receive buffer to send the command
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get overwrite inputs response
mr r3, REG_BUF
li r4, RXB_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# Now we overwrite requested inputs
li r10, 0 # loop index

LOOP_START:
mulli r9, r10, RXPB_SIZE
add r9, REG_BUF, r9 # Location of RXPB

lbz r3, RXPB_SHOULD_OVERWRITE(r9)
cmpwi r3, 0
beq LOOP_CONTINUE

# Here we should overwrite... So let's do that
mulli r8, r10, 0xC
add r8, r25, r8

lwz r3, RXPB_PAD_DATA(r9)
stw r3, 0(r8)
lwz r3, RXPB_PAD_DATA+4(r9)
stw r3, 4(r8)

LOOP_CONTINUE:
addi r10, r10, 1
cmpwi r10, 4
blt LOOP_START

restore