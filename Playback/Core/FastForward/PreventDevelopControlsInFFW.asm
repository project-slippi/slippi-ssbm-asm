################################################################################
# Address: 0x8022576c
################################################################################

# This code is primarily to prevent user inputs from "sticking" during FFW's causing
# c-stick inputs to affect the camera position

.include "Common/Common.s"
.include "Playback/Playback.s"

bl CODE_START
.long 0 # Data to store previous value

CODE_START:
mflr r5 # Note that if we ever need to use backup/restore we need to add a blrl to data section
lbz r4, 0(r5) # Get previous value

# This loads the real debug level value
lwz	r0, -0x6C98 (r13) # Replaced code line

# check status for fast forward
lwz r3, playbackDataBuffer(r13) # directory address
lwz r3, PDB_EXI_BUF_ADDR(r3) # EXI buf address
lbz r3, (BufferStatus_Start)+(BufferStatus_Status)(r3)
cmpwi r3, CONST_FrameFetchResult_FastForward
stb r3, 0(r5) # Store the value in the data section to use later
beq OVERWRITE_DEBUG_LEVEL # If we are FFW'ing, overwrite debug level to skip input checks

# Check if we were ffw'ing last frame, the state gets cleared one frame too early so we
# need to skip for one extra frame after the ffw ends
cmpwi r4, CONST_FrameFetchResult_FastForward
bne EXIT

OVERWRITE_DEBUG_LEVEL:
# Here we are fast forwarding so let's load 0 for db level to make the
# following branch exit the function
li r0, 0 # Fake debug level 0

EXIT:
