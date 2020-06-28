################################################################################
# Address: 0x803775b8 # Here we are starting the copy
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.if DEBUG_INPUTS==1
b START_CODE

BUFFER_AND_STRING:
blrl
.long 0 # address of buffer
.string "[%d] P%d %08X %08X %08X" # sprintf input string
.align 2

START_CODE:
# Check if VS Mode
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

backup

# Prepare ref
bl BUFFER_AND_STRING
mflr r31 # Data address

loadGlobalFrame r3
cmpwi r3, 1
bgt SKIP_ALLOC

# Allocate TX buf
li r3, 64
branchl r12, HSD_MemAlloc
stw r3, 0(r31) # Store address of TX buf

# Init TX buf
li r4, 0xD0
stb r4, 0(r3) # Store command byte for logging
li r4, 0
stb r4, 1(r3) # Indicate we don't need to print time

SKIP_ALLOC:

# Format input string
lwz r3, 0(r31)
addi r3, r3, 2 # skip to string
addi r4, r31, 4 # Input string
loadGlobalFrame r5
mr r6, r24
lwz r7, 0(r25)
lwz r8, 4(r25)
lwz r9, 8(r25)
branchl r12, 0x80323cf4 # sprintf

# Transfer string buffer
lwz r3, 0(r31) # Use the receive buffer to send the command
li r4, 64
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

restore
.endif

EXIT:
lhz	r0, 0 (r25)
