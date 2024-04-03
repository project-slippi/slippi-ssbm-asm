.ifndef HEADER_LEDGE_GRAB

# Source: https://smashboards.com/threads/ledge-grab-port-priority-fix.463581/
# Code converted to work in Slippi by Fizzi

.set INJ_CheckLastGObj, 0x8006c3a8

.set xThisCount, 0x0
.set xPrevCount, 0x2
.set xBools, 0x4
.set xGate,  0x8  # opens/closes access to cliffcatch action changes when called
.set xEnabled, 0xC
.set xGetPlayerGObjID, 0x10

.endif
.set HEADER_LEDGE_GRAB, 1
