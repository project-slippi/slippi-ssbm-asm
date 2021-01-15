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

.set REG_PREMADE_TEXT_ID, 31
.set REG_BUFFER, REG_PREMADE_TEXT_ID-1
.set REG_BUFFER_SIZE, REG_BUFFER-1

backup
mr REG_PREMADE_TEXT_ID, r3

li REG_BUFFER_SIZE, 2

GET_TEXT_SIZE:
# Create a small buffer for text size
mr r3, REG_BUFFER_SIZE
branchl r12, HSD_MemAlloc
mr REG_BUFFER, r3

# Initialize Buffer
li r3, CONST_SlippiCmdGetPremadeTextLength
stb r3, 0(REG_BUFFER) # EXI Command
stb REG_PREMADE_TEXT_ID, 1(REG_BUFFER) # Text ID

bl FN_Exi
lbz REG_BUFFER_SIZE, 0(r3) # get premade text size
# This should print 23 bytes = 0x17

# Free previous allocated memory
mr r3, REG_BUFFER
branchl r12, HSD_Free

GET_TEXT_DATA:
# Create buffer for text data
mr r3, REG_BUFFER_SIZE
branchl r12, HSD_MemAlloc
mr REG_BUFFER, r3

# Initialize Buffer
li r3, CONST_SlippiCmdGetPremadeText
stb r3, 0(REG_BUFFER) # EXI Command
stb REG_PREMADE_TEXT_ID, 1(REG_BUFFER) # Text ID

bl FN_Exi
mr r3, REG_BUFFER # set reg buffer as the output

restore
blr


# Function that executes EXI Write and Reads right away
FN_Exi:
backup
mr r3, REG_BUFFER
mr r4, REG_BUFFER_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer


# Write to Dolphin
mr r3, REG_BUFFER
mr r4, REG_BUFFER_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer
restore
blr
