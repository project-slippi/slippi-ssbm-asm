################################################################################
# Address: 0x80263258 # CSS_LoadButtonInputs runs once per frame
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_ZERO, 28
.set REG_INPUTS, 27
.set REG_MSRB_ADDR, 26
.set REG_TXB_ADDR, 25
.set REG_CSSDT_ADDR, 24

.set DISCONNECT_HOLD_DELAY, 0x30 # 3 seconds

# Controller immediate input values for CSS chat messages
.set PAD_LEFT, 0x01
.set PAD_RIGHT, 0x02
.set PAD_DOWN, 0x04
.set PAD_UP, 0x08
.set B_BUTTON, 0x200

# Deal with replaced codeline
beq+ START
branch r12, 0x80263334

START:
backup

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

################################################################################
# Init
################################################################################
mr REG_INPUTS, r7
loadwz REG_CSSDT_ADDR, CSSDT_BUF_ADDR
lwz REG_MSRB_ADDR, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR) # Load where buf is stored
li REG_ZERO, 0 # set to zero just in case :)

################################################################################
# Play sound on lock-in state 1 -> 0 transition
################################################################################
lbz r3, CSSDT_PREV_LOCK_IN_STATE(REG_CSSDT_ADDR)
lbz r4, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
stb r4, CSSDT_PREV_LOCK_IN_STATE(REG_CSSDT_ADDR) # Change previous value
cmpwi r3, 1
bne LOCK_IN_RESET_CHECK_END
cmpwi r4, 0
bne LOCK_IN_RESET_CHECK_END

# If we get here, we transitioned from locked-in to not locked-in, play the sound
b PLAY_BACK_SOUND_ON_RESET
LOCK_IN_RESET_CHECK_END:

################################################################################
# Handle connection state sounds
################################################################################
lbz r3, CSSDT_PREV_CONNECTED_STATE(REG_CSSDT_ADDR)
lbz r4, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
stb r4, CSSDT_PREV_CONNECTED_STATE(REG_CSSDT_ADDR) # Change previous value

################################################################################
# Play "error" sound on connection state transition ANY -> ERROR
################################################################################
cmpwi r3, MM_STATE_ERROR_ENCOUNTERED
beq ERR_STATE_CHECK_END
cmpwi r4, MM_STATE_ERROR_ENCOUNTERED
bne ERR_STATE_CHECK_END

b PLAY_ERROR_SOUND_ON_ERROR
ERR_STATE_CHECK_END:

################################################################################
# Play "back" sound on connection state transition CONNECTED -> ANY
################################################################################
# Check to see if connection was cleared
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
bne CONN_RESET_CHECK_END
cmpwi r4, MM_STATE_CONNECTION_SUCCESS
beq CONN_RESET_CHECK_END # If still success, no sound

b PLAY_BACK_SOUND_ON_RESET
CONN_RESET_CHECK_END:
b SOUND_PLAY_END

PLAY_BACK_SOUND_ON_RESET:
# Play "back" sound
li	r3, 0
b PLAY_SOUND

PLAY_ERROR_SOUND_ON_ERROR:
# Play "error" sound
li	r3, 3

PLAY_SOUND:
branchl r12, SFX_Menu_CommonSound

SOUND_PLAY_END:


# uncomment to debug the chat window
bl FN_CHECK_CHAT_INPUTS

################################################################################
# Fork logic based on current connection state
################################################################################
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_IDLE
ble HANDLE_IDLE
cmpwi r3, MM_STATE_OPPONENT_CONNECTING
ble HANDLE_FINDING
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq HANDLE_CONNECTED
cmpwi r3, MM_STATE_ERROR_ENCOUNTERED
beq HANDLE_ERROR

b SKIP_START_MATCH

################################################################################
# Case 1: Handle idle case
################################################################################
HANDLE_IDLE:

# uncomment to debug the chat window
# bl FN_CHECK_CHAT_INPUTS

# Prevent CSS Actions if chat window is opened
lbz r3, CSSDT_CHAT_WINDOW_OPENED(REG_CSSDT_ADDR)
cmpwi r3, 0
bne SKIP_START_MATCH # skip input if chat window is opened

# When idle, pressing start will start finding match
# Check if start was pressed
rlwinm.	r0, REG_INPUTS, 0, 19, 19
beq SKIP_START_MATCH # Exit if start was not pressed

# Sometimes when returning to the CSS, previously held buttons will stay held,
# including start. This prevents the start input from locking people in
# immediately... Doesn't feel like this should be necessary, and if it is,
# this doesn't feel like the right place for this logic
loadGlobalFrame r3
cmpwi r3, 0
beq SKIP_START_MATCH # Don't search on very first frame

# Initialize ISWINNER (first match)
li  r3, ISWINNER_NULL
stb r3, OFST_R13_ISWINNER (r13)
# Init CHOSESTAGE bool
li r3,  0
stb r3, OFST_R13_CHOSESTAGE (r13)

# Check if character has been selected, if not, do nothing
lbz r3, -0x49A9(r13)
cmpwi r3, 0
beq SKIP_START_MATCH

# Check which mode we are playing. direct mode should launch text entry
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_UNRANKED
beq HANDLE_IDLE_UNRANKED
cmpwi r3, ONLINE_MODE_DIRECT
bge HANDLE_IDLE_DIRECT
b 0x0

HANDLE_IDLE_UNRANKED:
li  r3, SB_RAND     # stages in unranked are always random
bl FN_LOCK_IN_AND_SEARCH # lock in and trigger matchmaking
b SKIP_START_MATCH

HANDLE_IDLE_DIRECT:
bl FN_LOAD_CODE_ENTRY # load text code entry
b SKIP_START_MATCH

################################################################################
# Case 2: Handle case where search is underway
################################################################################
HANDLE_FINDING:

# Handle cancel
rlwinm.	r0, REG_INPUTS, 0, 0x10
bnel FN_RESET_CONNECTIONS

b SKIP_START_MATCH

################################################################################
# Case 3: Handle case where we have an opponent
################################################################################
HANDLE_CONNECTED:

# Handle disconnect when input is hold for X seconds
branchl r12, Inputs_GetPlayerHeldInputs
rlwinm. r0, r4, 0, 0x10
beq RESET_HOLD_TIMER # if button is no longer pressed, reset hold timer

# increase time holding Z
lbz r3, CSSDT_Z_BUTTON_HOLD_TIMER(REG_CSSDT_ADDR)
addi r3, r3, 1
stb r3, CSSDT_Z_BUTTON_HOLD_TIMER(REG_CSSDT_ADDR)

# skip disconnect if hold time is less than delay
cmpwi r3, DISCONNECT_HOLD_DELAY
ble SKIP_DISCONNECT

# reset disconnect hold timer when disconnecting
stb REG_ZERO, CSSDT_Z_BUTTON_HOLD_TIMER(REG_CSSDT_ADDR)
bl FN_RESET_CONNECTIONS
b SKIP_START_MATCH
RESET_HOLD_TIMER:
stb REG_ZERO, CSSDT_Z_BUTTON_HOLD_TIMER(REG_CSSDT_ADDR)
SKIP_DISCONNECT:

# Handle case where we are not yet locked-in
lbz r3, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
cmpwi r3, 0
bne CHECK_SHOULD_START_MATCH

# Check if start is pressed to see whether we should lock in
rlwinm.	r0, REG_INPUTS, 0, 19, 19
bne HANDLE_CONNECTED_ADVANCE

# Check if direct mode && loser && already chose stage
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_DIRECT        # Check if this is direct/teams mode
blt CHECK_SHOULD_START_MATCH
lbz r3, OFST_R13_ISWINNER (r13)
cmpwi r3,ISWINNER_LOST              # Check if this is the loser
bne CHECK_SHOULD_START_MATCH
lbz r3, OFST_R13_CHOSESTAGE (r13)
cmpwi r3,1                          # Check if loser picked stage already
bne CHECK_SHOULD_START_MATCH
b HANDLE_CONNECTED_ADVANCE

HANDLE_CONNECTED_ADVANCE:
# Check if character has been selected, if not, do nothing
lbz r3, -0x49A9(r13)
cmpwi r3, 0
beq CHECK_SHOULD_START_MATCH

# Sometimes when returning to the CSS, previously held buttons will stay held,
# including start. This prevents the start input from locking people in
# immediately... Doesn't feel like this should be necessary, and if it is,
# this doesn't feel like the right place for this logic
loadGlobalFrame r3
cmpwi r3, 0
beq CHECK_SHOULD_START_MATCH # Don't lock-in on the very first frame

# Check which mode we are playing.
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_UNRANKED
beq HANDLE_CONNECTED_UNRANKED
cmpwi r3, ONLINE_MODE_DIRECT
bge HANDLE_CONNECTED_DIRECT
b 0x0                           # stall if neither

# Branch to this mode's behavior
HANDLE_CONNECTED_UNRANKED:
li  r3, SB_RAND       # stages always random for unranked
bl FN_TX_LOCK_IN
b CHECK_SHOULD_START_MATCH
HANDLE_CONNECTED_DIRECT:
# Loser picks the stage
lbz r3, OFST_R13_ISWINNER (r13)
cmpwi r3,ISWINNER_LOST
beq HANDLE_CONNECTED_DIRECT_ISLOSER
# Winner is unselected
cmpwi r3,ISWINNER_WON
beq HANDLE_CONNECTED_DIRECT_ISWINNER
b 0x0

HANDLE_CONNECTED_DIRECT_ISWINNER:
li  r3, SB_NOTSEL       # lock in, use opponents stage
bl FN_TX_LOCK_IN
b CHECK_SHOULD_START_MATCH

HANDLE_CONNECTED_DIRECT_ISLOSER:
# Check if loser picked stage already
lbz r3, OFST_R13_CHOSESTAGE (r13)
cmpwi r3,0
beq HANDLE_CONNECTED_DIRECT_LOADSSS
HANDLE_CONNECTED_DIRECT_SENDSTAGE:
# Send selected stage
lwz	r3, -0x77C0 (r13)
addi	r3, r3, 1424 + 0x8   # adding 0x8 to skip past some scene state stuff
lhz r3, 0x1E (r3)
bl FN_TX_LOCK_IN
b CHECK_SHOULD_START_MATCH
HANDLE_CONNECTED_DIRECT_LOADSSS:
# Set teams on/off bit. This is required by the "disable fod during doubles" gecko code
lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_TEAMS
li r3, 0
bne SET_TEAMS_BOOL
li r3, 1
SET_TEAMS_BOOL:
lwz	r4, -0x49F0(r13)
stb r3, 0x18(r4)
# Request scene change
li  r3,1
stb	r3, -0x49AA (r13)
# Set lock in callback function
bl FN_TX_LOCK_IN_BLRL
mflr r3
stw r3, OFST_R13_CALLBACK(r13)
b SKIP_START_MATCH

# Check to see if both players are ready and start match if they are
CHECK_SHOULD_START_MATCH:

# Check if we should open chat window
#bl FN_CHECK_CHAT_INPUTS

lbz r3, MSRB_IS_LOCAL_PLAYER_READY(REG_MSRB_ADDR)
lbz r4, MSRB_IS_REMOTE_PLAYER_READY(REG_MSRB_ADDR)
and. r3, r3, r4
beq SKIP_START_MATCH # If not both players are ready, skip

# Once both players are ready, start the game
restore
branch r12, 0x80263264

################################################################################
# Case 4: Handle case where we have not locked-in
################################################################################
HANDLE_ERROR:

# Handle cancel
rlwinm.	r0, REG_INPUTS, 0, 0x10
bnel FN_RESET_CONNECTIONS

b SKIP_START_MATCH

################################################################################
# Function: Start find match
################################################################################
FN_TX_FIND_MATCH:
backup

# Prepare buffer for EXI transfer
li r3, FMTB_SIZE
branchl r12, HSD_MemAlloc
mr REG_TXB_ADDR, r3

# Write tx data
li r3, CONST_SlippiCmdFindOpponent
stb r3, FMTB_CMD(REG_TXB_ADDR)

# Write online mode
lbz r3, OFST_R13_ONLINE_MODE(r13)
stb r3, FMTB_ONLINE_MODE(REG_TXB_ADDR)

# Write opp connect code, only matters for direct mode
addi r7, REG_TXB_ADDR, FMTB_OPP_CONNECT_CODE
load r6, 0x804a0740
li r4, 0
li r5, 0

WRITE_OPP_CODE_LOOP_START:
lhzx r3, r6, r4
sthx r3, r7, r5
addi r4, r4, 3
addi r5, r5, 2
cmpwi r5, 18
blt WRITE_OPP_CODE_LOOP_START

# Start finding opponent
mr r3, REG_TXB_ADDR
li r4, FMTB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, REG_TXB_ADDR
branchl r12, HSD_Free

restore
blr

################################################################################
# Function: Lock in character selection
# r3 = stage behavior.
#     -2 = random stage
#     -1 = unselected (use opponents stage)
#      0+ = specify stage ID.
################################################################################
FN_TX_LOCK_IN_BLRL:
blrl
FN_TX_LOCK_IN:
.set  REG_SB, 31    # stage behavior
backup

# Backup stage behavior
mr  REG_SB,r3

# Prepare buffer for EXI transfer
li r3, PSTB_SIZE
branchl r12, HSD_MemAlloc
mr REG_TXB_ADDR, r3

# Write tx data
li r3, CONST_SlippiCmdSetMatchSelections
stb r3, PSTB_CMD(REG_TXB_ADDR)

# Fetch selected character information
lwz r4, -0x49f0(r13) # base address where css selections are stored
lbz r3, -0x5108(r13) # player index
mulli r3, r3, 0x24
add r4, r4, r3

lbz r3, 0x70(r4) # load char id
stb r3, PSTB_CHAR_ID(REG_TXB_ADDR)
lbz r3, 0x73(r4) # load char color
stb r3, PSTB_CHAR_COLOR(REG_TXB_ADDR)
li r3, 1 # merge character
stb r3, PSTB_CHAR_OPT(REG_TXB_ADDR)

# Send a blank team ID if this isn't teams mode.
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
beq SEND_TEAM_ID
li r3, 0
stb r3, PSTB_TEAM_ID(REG_TXB_ADDR)
b SKIP_SEND_TEAM_ID

SEND_TEAM_ID:
# Calc/Set Team ID
loadwz r3, CSSDT_BUF_ADDR
lbz r3, CSSDT_TEAM_IDX(r3)
subi r3, r3, 1
stb r3, PSTB_TEAM_ID(REG_TXB_ADDR)

SKIP_SEND_TEAM_ID:
# Handle stage
cmpwi REG_SB, -2
beq FN_TX_LOCK_IN_STAGE_RAND
cmpwi REG_SB, -1
beq FN_TX_LOCK_IN_STAGE_UNSET
cmpwi REG_SB, 0
bge FN_TX_LOCK_IN_STAGE_PICK

FN_TX_LOCK_IN_STAGE_RAND:
li  r3,0
li  r4,3
b FN_TX_LOCK_IN_STAGE_SEND

FN_TX_LOCK_IN_STAGE_UNSET:
li  r3,0
li  r4,0
b FN_TX_LOCK_IN_STAGE_SEND

FN_TX_LOCK_IN_STAGE_PICK:
mr  r3,REG_SB
li  r4,1
b FN_TX_LOCK_IN_STAGE_SEND

FN_TX_LOCK_IN_STAGE_SEND:
sth r3, PSTB_STAGE_ID(REG_TXB_ADDR)
stb r4, PSTB_STAGE_OPT(REG_TXB_ADDR)

# Write the online mode we are in
lbz r3, OFST_R13_ONLINE_MODE(r13)
stb r3, PSTB_ONLINE_MODE(REG_TXB_ADDR)

# Indicate to Dolphin we want to lock-in
mr r3, REG_TXB_ADDR
li r4, PSTB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, REG_TXB_ADDR
branchl r12, HSD_Free

restore
blr

################################################################################
# Function: Simple function to lock in and search
# r3 = stage behavior.
#     -2 = random stage
#     -1 = unselected (use opponents stage)
#      0+ = specify stage ID.
################################################################################
FN_LOCK_IN_AND_SEARCH_BLRL:
blrl
FN_LOCK_IN_AND_SEARCH:
backup

lbz r20, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)
# logf LOG_LEVEL_NOTICE, "TEAM INDEX AFTER %d", "mr r5, 20"

bl FN_TX_LOCK_IN # Lock in character selection
bl FN_TX_FIND_MATCH # Trigger matchmaking

restore
blr

################################################################################
# Function: Load code entry
################################################################################
FN_LOAD_CODE_ENTRY:
backup

# Indicate we want name entry to operate in connect code mode
li r3, 1
stb r3, OFST_R13_NAME_ENTRY_MODE(r13)

# Prepare callback address on successful name entry
bl FN_LOCK_IN_AND_SEARCH_BLRL
mflr r3
stw r3, OFST_R13_CALLBACK(r13)

# Set the player index controlling name entry
lbz r0, -0x49b0(r13)
stb r0, -0x49a7(r13)

# Start process to load name entry
li r0, 4
stb r0, -0x49aa(r13)

restore
blr

################################################################################
# Function: Reset connections and clear lock-in state
################################################################################
FN_RESET_CONNECTIONS:
backup

# Prepare buffer for EXI transfer
li r3, 1
branchl r12, HSD_MemAlloc
mr REG_TXB_ADDR, r3

# Write tx data
li r3, CONST_SlippiCmdCleanupConnections
stb r3, 0(REG_TXB_ADDR)

# Reset connections
mr r3, REG_TXB_ADDR
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

mr r3, REG_TXB_ADDR
branchl r12, HSD_Free

restore
blr


################################################################################
# Function: Check if chat input was pressed and send it to the EXI device
################################################################################
# skip my test if pad was not pressed
FN_CHECK_CHAT_INPUTS:
backup

# uncomment this line to disable B press on chat window
# b SKIP_CHAT_WINDOW_B_PRESS

# if b was pressed, set that as last input
cmpwi REG_INPUTS, B_BUTTON
bne SKIP_CHAT_WINDOW_B_PRESS
sth REG_INPUTS, CSSDT_CHAT_LAST_INPUT(REG_CSSDT_ADDR)

SKIP_CHAT_WINDOW_B_PRESS:
cmpwi REG_INPUTS, PAD_LEFT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_RIGHT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_UP
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_DOWN
bnel HANDLE_SKIP_CHAT_INPUT

HANDLE_CHAT_INPUT_PRESSED:

# Store last input in CSS data table if part of the allowed inputs
sth REG_INPUTS, CSSDT_CHAT_LAST_INPUT(REG_CSSDT_ADDR)

# If chat window is already open, skip
lbz r3, CSSDT_CHAT_WINDOW_OPENED(REG_CSSDT_ADDR)
cmpwi r3, 0
bne HANDLE_SKIP_CHAT_INPUT

mr r3, REG_INPUTS
bl FN_OPEN_CHAT_WINDOW

HANDLE_SKIP_CHAT_INPUT:
restore
blr

################################################################################
# Function: Send Chat Commnad
################################################################################
FN_SEND_CHAT_COMMAND:

mr r14, r3 # Store Controller Input argument
backup

# Prepare buffer for EXI transfer
li r3, CMTB_SIZE # Store same bytes as Buffer Size
branchl r12, HSD_MemAlloc
mr REG_TXB_ADDR, r3 # Save the address where the memory has been allocated to

# Write tx data
li r3, CONST_SlippiCmdSendChatMessage # set command on allocated address
stb r3, CMTB_CMD(REG_TXB_ADDR)

mr r3, r14 # set message id from controller_input argument
stb r3, CMTB_MESSAGE(REG_TXB_ADDR)

# transfer the bufffer
mr r3, REG_TXB_ADDR
li r4, CMTB_SIZE # length of buffer
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# free the allocated memory
mr r3, REG_TXB_ADDR
branchl r12, HSD_Free

# Play a sound indicating a new message was sent
li r3, 0xb7
li r4, 127
li r5, 64
branchl r12, 0x800237a8 # SFX_PlaySoundAtFullVolume

mr r3, REG_INPUTS
restore
blr

################################################################################
# Function: Starts THINK Function to show the chat window
# r3 holds the input argument which decides the offset of the text messages to show
##############################################################################
FN_OPEN_CHAT_WINDOW:

.set REG_CHAT_INPUTS, 14
.set REG_CHAT_GOBJ, 20
.set REG_CHAT_JOBJ, 21
.set TEXT_GXLINK, 12

mr REG_CHAT_INPUTS, r3 # Store Controller Input argument
backup


bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

# Play common sound
li	r3, 2
branchl r12, SFX_Menu_CommonSound

# Save in memory that we have the chat opened and store the pad input
mr r3, REG_CHAT_INPUTS # controller input
stb r3, CSSDT_CHAT_WINDOW_OPENED(REG_CSSDT_ADDR) # Load where buf is stored

# Get Memory Buffer for Chat Window Data Table
li r3, CSSCWDT_SIZE # Buffer Size
branchl r12, HSD_MemAlloc
mr r23, r3 # save result address into r23

# Zero out CSS data table
li r4, CSSCWDT_SIZE
branchl r12, Zero_AreaLength

# Set Buffer Initial Data
mr r3, REG_CHAT_INPUTS # controller input
stb r3, CSSCWDT_INPUT(r23) # 0x80195424

# Set CSS DataTable Address
mr r3, REG_CSSDT_ADDR # store address to CSS Data Table
stw r3, CSSCWDT_CSSDT_ADDR(r23)

# create gobj for think function
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr REG_CHAT_GOBJ, r3 # save GOBJ pointer

# Load JOBJ
lwz r3, CSSDT_SLPCSS_ADDR(REG_CSSDT_ADDR)
lwz r3, SLPCSS_CHATSELECT (r3) # pointer to our custom bg main jobj
lwz r3, 0x0 (r3) # jobj
branchl r12,0x80370e44 #Create jobj
mr  REG_CHAT_JOBJ,r3

# Move to the left if widescreen is enabled
lfs f1, TPO_CHAT_WINDOW_X(REG_TEXT_PROPERTIES) # X POS
lbz r4, OFST_R13_ISWIDESCREEN(r13)
cmpwi r4, 0
beq END_SET_CHAT_WINDOW_POS_X
lfs f1, TPO_CHAT_WINDOW_X_WIDESCREEN(REG_TEXT_PROPERTIES) # X POS Widescreen

END_SET_CHAT_WINDOW_POS_X:
lfs f2, TPO_CHAT_WINDOW_Y(REG_TEXT_PROPERTIES) # Y POS
stfs f1, 0x38(r3) # X POS
stfs f2, 0x3C(r3) # Y POS

# Add JOBJ To GObj
mr  r3,REG_CHAT_GOBJ
li r4, 4
mr  r5,REG_CHAT_JOBJ
branchl r12,0x80390a70 # void GObj_AddObject(GOBJ *gobj, u8 unk, void *object)

# Add GX Link that draws the background
mr  r3,REG_CHAT_GOBJ
load r4,0x80391070 # 80302608, 80391044, 8026407c, 80391070, 803a84bc
li  r5, 1
li  r6, 128
branchl r12,GObj_SetupGXLink # void GObj_AddGXLink(GOBJ *gobj, void *cb, int gx_link, int gx_pri)

# Add User Data to GOBJ ( Our buffer )
mr r3, REG_CHAT_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, r23 # memory pointer of allocated buffer above
branchl r12, GObj_AddUserData

# Set Think Function that runs every frame
mr r3, REG_CHAT_GOBJ # set r3 to GOBJ pointer
bl CSS_ONLINE_CHAT_WINDOW_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs (3)
branchl r12, GObj_AddProc

FN_OPEN_CHAT_WINDOW_END:


restore
blr

################################################################################
# CHAT MSG THINK Function: Looping function to keep on
# updating the text until timer runs out
################################################################################
CSS_ONLINE_CHAT_WINDOW_THINK:
blrl
.set REG_CHAT_WINDOW_GOBJ, 14
.set REG_TEXT_PROPERTIES, 15
.set REG_CHAT_TEXT_PROPERTIES, 20
.set REG_CHAT_WINDOW_GOBJ_DATA_ADDR, 16
.set REG_CHAT_WINDOW_JOBJ_ADDR, 23
.set REG_CHAT_WINDOW_INPUT, 17
.set REG_CHAT_WINDOW_SECOND_INPUT, 22
.set REG_CHAT_WINDOW_TIMER, 18
.set REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, 19
.set REG_CHAT_WINDOW_CSSDT_ADDR, 21

.set CHAT_JOBJ_OFFSET, 0x28 # offset from GOBJ to HSD Object (Jobj we assigned)
.set CHAT_ENTITY_DATA_OFFSET, 0x2C # offset from GOBJ to entity data
.set CHAT_WINDOW_IDLE_TIMER_TIME, 0x90 # initial idle timer before window disappears
.set CHAT_WINDOW_IDLE_TIMER_DELAY, 0x06 # initial delay before allowing to send messages
.set CHAT_WINDOW_MAX_MESSAGES, 0x03 # Max messages allowed before blocking new ones
.set CHAT_WINDOW_HEADER_MARGIN_LINES, 0x2 # lines away from which to start drawing messages away from header

mr REG_CHAT_WINDOW_GOBJ, r3 # Store GOBJ pointer 0x801954A4
backup

# get gobj and get values for each of the data buffer
lwz REG_CHAT_WINDOW_GOBJ_DATA_ADDR, CHAT_ENTITY_DATA_OFFSET(REG_CHAT_WINDOW_GOBJ) # get address of data buffer
lwz REG_CHAT_WINDOW_JOBJ_ADDR, CHAT_JOBJ_OFFSET(REG_CHAT_WINDOW_GOBJ) # get address of data buffer
lbz REG_CHAT_WINDOW_INPUT, CSSCWDT_INPUT(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
lbz REG_CHAT_WINDOW_TIMER, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
lwz REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, CSSCWDT_TEXT_STRUCT_ADDR(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
lwz REG_CHAT_WINDOW_CSSDT_ADDR, CSSCWDT_CSSDT_ADDR(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
lhz REG_CHAT_WINDOW_SECOND_INPUT, CSSDT_CHAT_LAST_INPUT(REG_CHAT_WINDOW_CSSDT_ADDR)

lwz REG_MSRB_ADDR, CSSDT_MSRB_ADDR(REG_CHAT_WINDOW_CSSDT_ADDR)

# clear last input
li r3, 0
sth r3, CSSDT_CHAT_LAST_INPUT(REG_CHAT_WINDOW_CSSDT_ADDR)

# if chat command already sent destroy proc
lbz r3, CSSCWDT_INPUT_SENT(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
cmpwi r3, 0
bne CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC

# if text is not initialized, assume we need to initalize everything
# else skip to idle timer check
cmpwi REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, 0
bne CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_INPUT

##### BEGIN: INITIALIZING CHAT WINDOW TIMER ###########
li r3, CHAT_WINDOW_IDLE_TIMER_TIME # idle timer
mr REG_CHAT_WINDOW_TIMER, r3
stb r3, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
##### END: INITIALIZING CHAT WINDOW TIMER ###########

##### BEGIN: INITIALIZING CHAT WINDOW TEXT ###########

# INIT PROPERTIES
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

# INIT MSG Properties based on input button
mr r3, REG_CHAT_WINDOW_INPUT
branchl r12, FN_LoadChatMessageProperties
mr REG_CHAT_TEXT_PROPERTIES, r3

# Create Text Struct
li r3, 0
li r4, 0
branchl r12, Text_CreateStruct
# Save Text Struct Address
mr REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, r3
stw REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, CSSCWDT_TEXT_STRUCT_ADDR(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

li r3, 0x1 # Text kerning to close
li r4, 0x0 # Align Left
lfs f1, TPO_BASE_Z(REG_TEXT_PROPERTIES) # Z offset
lfs f2, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES) # Scale
stb r3, 0x49(REG_CHAT_WINDOW_TEXT_STRUCT_ADDR) # Set text kerning
stb r4, 0x4A(REG_CHAT_WINDOW_TEXT_STRUCT_ADDR) # Set text alignment
stfs f1, 0x8(REG_CHAT_WINDOW_TEXT_STRUCT_ADDR) # set z offset
stfs f2, 0x24(REG_CHAT_WINDOW_TEXT_STRUCT_ADDR) # set scale
stfs f2, 0x28(REG_CHAT_WINDOW_TEXT_STRUCT_ADDR) # set scale

# Create Subtext: Header
# Move to the left if widescreen is enabled
lfs f2, TPO_CHAT_HEADER_X(REG_TEXT_PROPERTIES) # X POS
lbz r3, OFST_R13_ISWIDESCREEN(r13)
cmpwi r3, 0
beq END_SET_CHAT_HEADER_POS_X
lfs f2, TPO_CHAT_HEADER_X_WIDESCREEN(REG_TEXT_PROPERTIES) # X POS Widescreen
END_SET_CHAT_HEADER_POS_X:

# set a different color if not connected
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_YELLOW # color when connected
lbz r3, MSRB_CONNECTION_STATE(REG_MSRB_ADDR)
cmpwi r3, MM_STATE_CONNECTION_SUCCESS
beq END_SET_CHAT_HEADER_COLOR

addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_FAINT_YELLOW # color when not connected
END_SET_CHAT_HEADER_COLOR:

mr r3, REG_CHAT_WINDOW_TEXT_STRUCT_ADDR # Text Struct Address
# r4 is color
li r5, 0 # no outline
addi r6, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE # Text Color
addi r7, REG_TEXT_PROPERTIES, TPO_STRING_CHAT_SHORTCUTS # String Format pointer
addi r8, REG_CHAT_TEXT_PROPERTIES, 0x4 # String pointer (header starts at 0x4)
lfs f1, TPO_CHAT_LABEL_SIZE(REG_TEXT_PROPERTIES) # Text Size
lfs f3, TPO_CHAT_LABEL_Y(REG_TEXT_PROPERTIES) # Y POS
branchl r12, FG_CreateSubtext
mr r4, r3 # sub text index for next function call

# Create Subtext: Labels
mr r10, r4 # save sub text index of header # 0x80195520
mr r11, r4 # initialize looping index
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_START:

# calculate Y offset by moving it down a bit
addi r3, r11, CHAT_WINDOW_HEADER_MARGIN_LINES
lfs f2, TPO_CHAT_LABEL_MARGIN(REG_TEXT_PROPERTIES) # margin between labels
branchl r12, FN_MultiplyRWithF
lfs f3, TPO_CHAT_LABEL_Y(REG_TEXT_PROPERTIES) # Y POS
fadds f3, f3, f1
#fmr f3, f1 # 0x80195588

# calculate address of label
cmpwi r11, 0x0
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_UP_LABEL_ADDR
cmpwi r11, 0x1
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_LEFT_LABEL_ADDR
cmpwi r11, 0x2
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_RIGHT_LABEL_ADDR
cmpwi r11, 0x3
beq CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_DOWN_LABEL_ADDR

CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_UP_LABEL_ADDR:
li r4, PAD_UP
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_DOWN_LABEL_ADDR:
li r4, PAD_DOWN
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_RIGHT_LABEL_ADDR:
li r4, PAD_RIGHT
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_LEFT_LABEL_ADDR:
li r4, PAD_LEFT
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END:

# calculate address of message
# INIT MSG Properties based on input button
mr r3, REG_CHAT_WINDOW_INPUT
# r4 is selected input
branchl r12, FN_LoadChatMessageProperties
mr r7, r4 # message String pointer

# Move to the left if widescreen is enabled
lfs f2, TPO_CHAT_LABEL_X(REG_TEXT_PROPERTIES) # X POS
lbz r3, OFST_R13_ISWIDESCREEN(r13)
cmpwi r3, 0
beq END_SET_CHAT_LABEL_POS_X
lfs f2, TPO_CHAT_LABEL_X_WIDESCREEN(REG_TEXT_PROPERTIES) # X POS Widescreen

END_SET_CHAT_LABEL_POS_X:
mr r3, REG_CHAT_WINDOW_TEXT_STRUCT_ADDR # Text Struct Address
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE # Text Color
li r5, 0 # No outlines
addi r6, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE # Text Color
# r7 message String pointer
lfs f1, TPO_CHAT_LABEL_SIZE(REG_TEXT_PROPERTIES) # Text Size


branchl r12, FG_CreateSubtext
mr r11, r3 # save subtext index

# Loop back if last index has not been reached
addi r3, r10, 4 # Last index we want header + 4 labels
cmpw r11, r3
bne CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_START

##### END: INITIALIZING CHAT WINDOW TEXT ###########
b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT # just initialize on first loop

CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_INPUT: # 0x8019562C

# If theres is no chat messages skip timer check
lbz r3, CSSDT_CHAT_LOCAL_MSG_COUNT(REG_CHAT_WINDOW_CSSDT_ADDR)
cmpwi r3, 0
beq SKIP_CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER

# prevent spam: Only allow input if a few frames have passed
lbz r3, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
cmpwi r3, CHAT_WINDOW_IDLE_TIMER_TIME-CHAT_WINDOW_IDLE_TIMER_DELAY
bgt CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER
SKIP_CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER:

# logf LOG_LEVEL_WARN, "msg input: %d", "mr r5, REG_CHAT_WINDOW_SECOND_INPUT"

# if B pressed, close chat window
cmpwi REG_CHAT_WINDOW_SECOND_INPUT, B_BUTTON
bne SKIP_CSS_ONLINE_CHAT_WINDOW_THINK_CLOSE_CHAT_WINDOW

# Play return SFX
# li  r3, 0
# branchl r12,SFX_Menu_CommonSound
b CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC

SKIP_CSS_ONLINE_CHAT_WINDOW_THINK_CLOSE_CHAT_WINDOW:

# load last input from the CSS Data table
# if there's any input, Send Message
cmpwi REG_CHAT_WINDOW_SECOND_INPUT, 0
beq CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER

# if current local message count is X, do not allow to send another
lbz r3, CSSDT_CHAT_LOCAL_MSG_COUNT(REG_CHAT_WINDOW_CSSDT_ADDR)
cmpwi r3, CHAT_WINDOW_MAX_MESSAGES
bge CSS_ONLINE_CHAT_WINDOW_THINK_BLOCK_MESSAGE

# if current message count is X+2, do not allow to send another
lbz r3, CSSDT_CHAT_MSG_COUNT(REG_CHAT_WINDOW_CSSDT_ADDR)
cmpwi r3, CHAT_WINDOW_MAX_MESSAGES+2
bge CSS_ONLINE_CHAT_WINDOW_THINK_BLOCK_MESSAGE

# Clear Timer
li r3, 0
stb r3, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

# Send Chat command # 0x80195638
# combine so we get 0x00(first input)(second input) i.e: 0x0024 if first was 2 and second was 4
mr r3, REG_CHAT_WINDOW_INPUT
mr r4, REG_CHAT_WINDOW_SECOND_INPUT

li r5, 4 # shift first input 4 bytes to the left
slw r3, r3, r5
add r3, r3, r4 # add second input to highest byte
bl FN_SEND_CHAT_COMMAND

# flag as input already sent
li r3, 1
stb r3, CSSCWDT_INPUT_SENT(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT

CSS_ONLINE_CHAT_WINDOW_THINK_BLOCK_MESSAGE:
# Play SFX
li  r3,3
branchl r12,SFX_Menu_CommonSound

CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER:
# check timer and decrease until is 0
cmpwi REG_CHAT_WINDOW_TIMER, 0
beq CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC # if timer is 0, then exit and delete think func.

CSS_ONLINE_CHAT_WINDOW_THINK_DECREASE_IDLE_TIMER:
subi REG_CHAT_WINDOW_TIMER, REG_CHAT_WINDOW_TIMER, 1
stb REG_CHAT_WINDOW_TIMER, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT

CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC:

# clear out chat window opened flag on the CSS Data Table
li r3, 0
stb r3, CSSDT_CHAT_WINDOW_OPENED(REG_CHAT_WINDOW_CSSDT_ADDR)

# destroy gobj
mr r3, REG_CHAT_WINDOW_GOBJ
branchl r12, GObj_Destroy

# remove text
mr r3, REG_CHAT_WINDOW_TEXT_STRUCT_ADDR
branchl r12, Text_RemoveText

CSS_ONLINE_CHAT_WINDOW_THINK_EXIT:
restore
blr



################################################################################
# Properties
################################################################################
TEXT_PROPERTIES:
blrl
# Base Properties
.set TPO_BASE_Z, 0
.float 0
.set TPO_BASE_CANVAS_SCALING, TPO_BASE_Z + 4
.float 0.1

# Chat Labels Propiertes
.set TPO_CHAT_HEADER_X, TPO_BASE_CANVAS_SCALING + 4
.float -300
.set TPO_CHAT_HEADER_X_WIDESCREEN, TPO_CHAT_HEADER_X + 4
.float -452
.set TPO_CHAT_LABEL_X, TPO_CHAT_HEADER_X_WIDESCREEN + 4
.float -285
.set TPO_CHAT_LABEL_X_WIDESCREEN, TPO_CHAT_LABEL_X + 4
.float -437
.set TPO_CHAT_LABEL_Y, TPO_CHAT_LABEL_X_WIDESCREEN + 4
.float 79
.set TPO_CHAT_LABEL_SIZE, TPO_CHAT_LABEL_Y + 4
.float 0.45
.set TPO_CHAT_LABEL_MARGIN, TPO_CHAT_LABEL_SIZE + 4
.float 25

# Chat Window Properties
.set TPO_CHAT_WINDOW_X, TPO_CHAT_LABEL_MARGIN + 4
.float -20
.set TPO_CHAT_WINDOW_X_WIDESCREEN, TPO_CHAT_WINDOW_X + 4
.float -35
.set TPO_CHAT_WINDOW_Y, TPO_CHAT_WINDOW_X_WIDESCREEN + 4
.float -16.5

# Text colors
.set TPO_COLOR_WHITE, TPO_CHAT_WINDOW_Y + 4
.long 0xFFFFFFFF # white
.set TPO_COLOR_YELLOW, TPO_COLOR_WHITE + 4
.long 0xffea2fFF
.set TPO_COLOR_FAINT_YELLOW, TPO_COLOR_YELLOW + 4
.long 0xc9c387FF

# String Properties
.set TPO_STRING_CHAT_SHORTCUTS, TPO_COLOR_FAINT_YELLOW + 4
.string "Chat: %s"
.align 2

################################################################################
# Skip starting match
################################################################################
SKIP_START_MATCH:
restore
branch r12, 0x80263334

EXIT:
restore
