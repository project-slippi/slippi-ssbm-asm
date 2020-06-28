################################################################################
# Address: FN_LoadMatchState
################################################################################
# Inputs:
# r3 - Address of the MSRB. If 0, will allocate a new buffer
################################################################################
# Output:
# r3 - Address of the MSRB
################################################################################
# Description:
# Loads the current match state. See MSRB config in online.s for fields
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_MSRB_ADDR, 31

backup

# Check if a pre-allocated buffer is being passed in
cmpwi r3, 0
bne ALLOC_END

# Prepare buffer for EXI transfer
li r3, MSRB_SIZE
branchl r12, HSD_MemAlloc

ALLOC_END:
mr REG_MSRB_ADDR, r3

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdGetMatchState
stb r3, 0(REG_MSRB_ADDR)

# Request match state information
mr r3, REG_MSRB_ADDR # Use the receive buffer to send the command
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get match state information response
mr r3, REG_MSRB_ADDR # Use the receive buffer to send the command
li r4, MSRB_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# Set the MSRB Address as the output
mr r3, REG_MSRB_ADDR

restore
blr
