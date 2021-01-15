################################################################################
# Address: FN_LoadPremadeText
################################################################################
# Inputs:
# r3 - premade text id
################################################################################
# Output:
# r3 - Address of the Premade Text Data
################################################################################
# Description:
# Loads the current match state. See MSRB config in online.s for fields
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PREMADE_TEXT_SIZE, 31
.set REG_PREMADE_TEXT_SIZE_ADDR, 30
.set REG_PREMADE_TEXT_ADDR, 29

backup

# Prepare buffer for EXI transfer for string size
li r3, 2
branchl r12, HSD_MemAlloc
mr REG_PREMADE_TEXT_SIZE_ADDR, r3

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdGetPremadeTextLength
stb r3, 0(REG_PREMADE_TEXT_SIZE_ADDR)

# Request premade text size
mr r3, REG_PREMADE_TEXT_SIZE_ADDR # Use the receive buffer to send the command
li r4, 2
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get premade text size
mr r3, REG_PREMADE_TEXT_SIZE_ADDR # Use the receive buffer to send the command
li r4, 2
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer
lwz REG_PREMADE_TEXT_SIZE, 0(REG_PREMADE_TEXT_SIZE_ADDR) # read string size from buffer

# free up previously allocated buffer for reading text size
mr r3, REG_PREMADE_TEXT_SIZE_ADDR
branchl r12, HSD_Free

# Prepare buffer for EXI transfer for actual string
mr r3, REG_PREMADE_TEXT_SIZE
branchl r12, HSD_MemAlloc
mr REG_PREMADE_TEXT_ADDR, r3

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdGetPremadeText
stb r3, 0(REG_PREMADE_TEXT_SIZE_ADDR)

# Request premade text
mr r3, REG_PREMADE_TEXT_ADDR # Use the receive buffer to send the command
li r4, 2
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get premade text
mr r3, REG_PREMADE_TEXT_ADDR # Use the receive buffer to send the command
li r4, 1
mr r4, REG_PREMADE_TEXT_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer
mr r3, REG_PREMADE_TEXT_ADDR # pointer to premade text data struct

restore
blr
