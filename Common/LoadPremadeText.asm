################################################################################
# Address: FN_LoadPremadeText
################################################################################
# Inputs:
# r3 - premade text id
# r4 - premade text param
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
.set REG_PREMADE_TEXT_PARAM_1, REG_PREMADE_TEXT_ID-1
.set REG_BUFFER, REG_PREMADE_TEXT_PARAM_1-1
.set REG_BUFFER_SIZE, REG_BUFFER-1

backup
mr REG_PREMADE_TEXT_ID, r3
mr REG_PREMADE_TEXT_PARAM_1, r4

li REG_BUFFER_SIZE, 4

GET_TEXT_SIZE:
# Create a small buffer for text size
mr r3, REG_BUFFER_SIZE
branchl r12, HSD_MemAlloc
mr REG_BUFFER, r3
mr r4, REG_BUFFER_SIZE
branchl r12, Zero_AreaLength

# Initialize Buffer
li r3, CONST_SlippiCmdGetPremadeTextLength
bl FN_Exi
lwz REG_BUFFER_SIZE, 0x0(REG_BUFFER) # get premade text size
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
bl FN_Exi
mr r3, REG_BUFFER # set reg buffer as the output

restore
blr


# Function that executes EXI Write and Reads right away
FN_Exi:
backup

# initialize buffer
stb r3, 0(REG_BUFFER) # EXI Command
stb REG_PREMADE_TEXT_ID, 1(REG_BUFFER) # Text ID
stb REG_PREMADE_TEXT_PARAM_1, 2(REG_BUFFER) # PARAM 1

# Prepare Buffer to read
mr r3, REG_BUFFER
li r4, 3 # Always sends 3 bytes
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Read From Dolphin
mr r3, REG_BUFFER
mr r4, REG_BUFFER_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer
restore
blr
