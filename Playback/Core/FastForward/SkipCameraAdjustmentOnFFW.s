################################################################################
# Address: 8002b3ec
################################################################################

# Currently .s to disable file. Attempt to fix camera jitteriness

# Injection is right before game engine loops
.include "Common/Common.s"
.include "Playback/Playback.s"

# check status for fast forward
lwz r11,playbackDataBuffer(r13) # directory address
lwz r11,PDB_EXI_BUF_ADDR(r11) # EXI buf address
lbz r11,(RBStatus_Start)+(RBStatus_Status)(r11)
cmpwi r11, 0
beq EXIT # If we are not rb, continue as normal

branch r12, 0x8002b67c # branch to the end of function, skipping camera stuff

EXIT:
lis r3, 0x8045
addi r31, r3, 11368
