################################################################################
# Address: 0x8016e904 # StartMelee before the standard Slippi stuff runs
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne INJECTION_EXIT

################################################################################
# Initialize Client Pause
################################################################################

# Check if pause is disabled
load  r12,0x8046db68
lbz r3,0x2 (r12)
rlwinm. r3,r3,0,0x08
beq PAUSE_INIT_END
# Set client pause callback
bl  ClientPause
mflr  r3
stw r3,0x40(r12)
# Init isPause
li  r3,0
stb r3, OFST_R13_ISPAUSE (r13)
# Enable pause
lbz r3,0x2 (r12)
li  r4,0
rlwimi r3,r4,3,0x8
stb r3,0x2 (r12)
PAUSE_INIT_END:
b INJECTION_EXIT




################################################################################
# Routine: ClientPause
# ------------------------------------------------------------------------------
# Description: Handles pausing the game, clientside
################################################################################

#region ClientPause
ClientPause:
blrl

.set  REG_INPUTS,31
.set  REG_PORT,30
.set REG_ODB_ADDRESS,29

backup

lwz REG_ODB_ADDRESS, OFST_R13_ODB_ADDR(r13) # data buffer address

# Check if opponent LRAS'd
lbz REG_PORT, ODB_ONLINE_PLAYER_INDEX(REG_ODB_ADDRESS)
load  r4,0x804c1fac
mulli r3,REG_PORT,68
add r3, r3, r4

ClientPause_CheckRemoteLRAS:

# Check if opponent holding L R A
lwz r3,0x0(r3)
rlwinm. r0,r3,0,0x40
beq ClientPause_PrepLocalInputs
rlwinm. r0,r3,0,0x20
beq ClientPause_PrepLocalInputs
rlwinm. r0,r3,0,0x100
beq ClientPause_PrepLocalInputs
# Is holding LRA, check for start
rlwinm. r0,r3,0,0x1000
bne ClientPause_Paused_Disconnect

ClientPause_PrepLocalInputs:

# Get local clients inputs
lbz REG_PORT, ODB_LOCAL_PLAYER_INDEX(REG_ODB_ADDRESS)
load  r4,0x804c1fac
mulli r3,REG_PORT,68
add REG_INPUTS,r3,r4

ClientPause_CheckLocalLRAS:

# Check if holding L R A
lwz r3,0x0(REG_INPUTS)
rlwinm. r0,r3,0,0x40
beq ClientPause_HandlePauseAndUnpause
rlwinm. r0,r3,0,0x20
beq ClientPause_HandlePauseAndUnpause
rlwinm. r0,r3,0,0x100
beq ClientPause_HandlePauseAndUnpause
# Is holding LRA, check for start
rlwinm. r0,r3,0,0x1000
bne ClientPause_Paused_Disconnect

ClientPause_HandlePauseAndUnpause:

# Check pause state
lbz r3, OFST_R13_ISPAUSE (r13)
cmpwi r3,0
beq ClientPause_Unpaused

ClientPause_Paused_CheckUnpause:
# Check if just pressed Start
lwz r3,0x8(REG_INPUTS)
rlwinm. r0,r3,0,0x1000
bne ClientPause_Paused_Unpause

# nothing, exit
b ClientPause_Exit

################################################################################
# Disconnect the client
################################################################################

ClientPause_Paused_Disconnect:
# Play SFX
li  r3,2
branchl r12,0x80024030
# Set the address normally used to indicate who paused
load r3, 0x8046b6a0 # Some static match state struct
stb REG_PORT, 0x1(r3) # Write pauser index
# End game
mr r3, REG_PORT
li r4, 0x7
branchl r12,NoContestOrRetry_
# Change scene
li  r3,3
load  r4,0x8046b6a0
stb r3,0x0(r4)
# Unpause clientside
#li  r3,0
#stb r3, OFST_R13_ISPAUSE (r13)
b ClientPause_Exit

################################################################################
# Unpause the client
################################################################################

ClientPause_Paused_Unpause:
# Unpause clientside
li  r3,0
stb r3, OFST_R13_ISPAUSE (r13)
# Show HUD
branchl r12,0x802f33cc
# Show Timer
# Hide Pause UI
mr  r3,REG_PORT
branchl r12,0x801a10fc
b ClientPause_Exit

################################################################################
# Check to pause the client
################################################################################

ClientPause_Unpaused:
# Check if just pressed Start
lwz r3,0x8(REG_INPUTS)
rlwinm. r0,r3,0,0x1000
beq ClientPause_Exit

# Pause clientside
li  r3,1
stb r3, OFST_R13_ISPAUSE (r13)
# Hide HUD
branchl r12,0x802f3394
# Hide Timer
# Show Pause UI
mr  r3,REG_PORT
li  r4,0x5      #shows LRA start and stick
branchl r12,0x801a0fec
# Play SFX
li  r3,5
branchl r12,0x80024030
b ClientPause_Exit

ClientPause_Exit:
li  r3,-1   # always return -1 so the game doesnt actually pause
restore
blr
#endregion





INJECTION_EXIT:
lbz	r0, 0x0001 (r31)
