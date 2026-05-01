################################################################################
# Address: 0x80179378
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

CODE_START:
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_RESULTS
bne EXIT # If not online results, continue as normal

# Go through all the ports and copy inputs from the single player port
li r28, 0 # r28 safe to use, we overwrite it on exit anyway
COPY_INPUTS_LOOP_START:
load r6, 0x804c20bc # controller inputs / status location
loadbz r4, 0x8045abf6 # single player port index (source)
mulli r3, r28, 0x44 # offset for this port's controller struct
mulli r4, r4, 0x44 # offset for source controller struct
add r3, r6, r3 # Destination controller struct
add r4, r6, r4 # Source controller struct
li r5, 0x44 # Size of controller struct
branchl r12, memcpy # Copy controller struct from source to destination
COPY_INPUTS_LOOP_CONTINUE:
addi r28, r28, 1
cmpwi r28, 4
blt COPY_INPUTS_LOOP_START

EXIT:
addi r28, r31, 0 # replaced code line
