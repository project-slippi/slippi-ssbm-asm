################################################################################
# Address: 801b3668
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online VS
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_VS
beq FORCE_NOP # If online VS, skip line

# Original code line, will be run when not in online mode
branchl r12, 0x8017bec8

FORCE_NOP:
