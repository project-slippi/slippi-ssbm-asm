################################################################################
# Address: 801b3650
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online VS
getMinorMajor r4
cmpwi r4, SCENE_ONLINE_VS
beq FORCE_NOP # If online VS, skip line

# Original code line, will be run when not in online mode
stb r3, 0x16(r25)

FORCE_NOP:
