################################################################################
# Address: 0x80178088
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

b CODE_START

DATA_BLRL:
blrl
# This index will be updated in InitOnlinePlay, so if the injection location changes, the code in InitOnlinePlay
# will also need to be updated
.byte 0 # index of the fighter local player was controlling during the game
.align 2

CODE_START:
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_RESULTS
bne EXIT # If not online results, continue as normal

# Remap inputs from local port to the online port
bl DATA_BLRL
mflr r5
# There's two locations where single player port is stored 8045abf6 and 804d6598. Not sure it matters which is used.
loadbz r4, 0x8045abf6 # single player port index (source)
lbz r3, 0x0(r5) # online port index (destination)
cmpw r3, r4 # If the local ports are the same, no need to remap
beq EXIT

load r6, 0x804c20bc # Controller inputs / status location

mulli r3, r3, 0x44 # Each controller struct is 0x44 bytes
mulli r4, r4, 0x44
add r3, r6, r3 # Destination controller struct
add r4, r6, r4 # Source controller struct
li r5, 0x44 # Size of controller struct
branchl r12, memcpy # Copy controller struct from source to destination

# Go through all the inputs and fake that the controllers are disconnected to force their panels to close
li r3, 0
load r6, 0x804c20bc # Controller inputs / status location
bl DATA_BLRL
mflr r5
lbz r4, 0x0(r5) # online port index (destination)
MARK_DISCONNECTED_LOOP_START:
cmpw r3, r4
beq MARK_DISCONNECTED_LOOP_CONTINUE # Don't mark the port we want to control as disconnected
mulli r7, r3, 0x44 # Each controller struct is 0x44 bytes
add r7, r6, r7 # Get controller struct for this player
li r8, 0xFF # Value to mark port as disconnected
stb r8, 0x41(r7) # Set disconnected flag in controller struct
# Clear inputs as well. This should prevent pause from reactivating the menu of the player
# we are copying from. Because while we are remapping inputs, the original inputs are not
# changed so really it's like the same inputs being pressed on two ports now
li r8, 0 
stw r8, 0x0(r7)
MARK_DISCONNECTED_LOOP_CONTINUE:
addi r3, r3, 1
cmpwi r3, 4
blt MARK_DISCONNECTED_LOOP_START

EXIT:
lfs	f0, -0x564C(rtoc) # replaced code line
