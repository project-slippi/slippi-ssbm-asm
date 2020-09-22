################################################################################
# Address: 0x80263258 # CSS_LoadButtonInputs runs once per frame
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_INPUTS, 27
.set REG_MSRB_ADDR, 26
.set REG_TXB_ADDR, 25
.set REG_CSSDT_ADDR, 24

# Controller immediate input values for CSS chat messages
.set PAD_LEFT, 0x01
.set PAD_RIGHT, 0x02
.set PAD_DOWN, 0x04
.set PAD_UP, 0x08

.set L_PAD_LEFT, 0x40+PAD_LEFT
.set L_PAD_RIGHT, 0x40+PAD_RIGHT
.set L_PAD_DOWN, 0x40+PAD_DOWN
.set L_PAD_UP, 0x40+PAD_UP

.set R_PAD_LEFT, 0x20+PAD_LEFT
.set R_PAD_RIGHT, 0x20+PAD_RIGHT
.set R_PAD_DOWN, 0x20+PAD_DOWN
.set R_PAD_UP, 0x20+PAD_UP

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
branchl r12, SFX_Menu_CommonSound
b SOUND_PLAY_END

PLAY_ERROR_SOUND_ON_ERROR:
# Play "error" sound
li	r3, 3
branchl r12, SFX_Menu_CommonSound

SOUND_PLAY_END:

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

# Check if we should open chat window
bl FN_CHECK_CHAT_INPUTS

# When idle, pressing start will start finding match
# Check if start was pressed
rlwinm.	r0, REG_INPUTS, 0, 19, 19
beq SKIP_START_MATCH # Exit if start was not pressed

# Initialize ISWINNER (first match)
li  r3, ISWINNER_NULL
stb r3, OFST_R13_ISWINNER (r13)
# Init CHOSESTAGE bool
li  r3,0
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
beq HANDLE_IDLE_DIRECT
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

# Handle disconnect
rlwinm.	r0, REG_INPUTS, 0, 0x10
beq SKIP_DISCONNECT

bl FN_RESET_CONNECTIONS
b SKIP_START_MATCH
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
cmpwi r3, ONLINE_MODE_DIRECT        # Check if this is direct mode
bne CHECK_SHOULD_START_MATCH
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

# Check which mode we are playing.
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_UNRANKED
beq HANDLE_CONNECTED_UNRANKED
cmpwi r3, ONLINE_MODE_DIRECT
beq HANDLE_CONNECTED_DIRECT
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
bl FN_CHECK_CHAT_INPUTS

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

# Start finding opponent
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

# Always store last input in CSS data table
mr r3, REG_INPUTS
stb r3, CSSDT_CHAT_LAST_INPUT(REG_CSSDT_ADDR)

cmpwi REG_INPUTS, PAD_LEFT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_RIGHT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_UP
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, PAD_DOWN
beq HANDLE_CHAT_INPUT_PRESSED

cmpwi REG_INPUTS, L_PAD_LEFT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, L_PAD_RIGHT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, L_PAD_UP
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, L_PAD_DOWN
beq HANDLE_CHAT_INPUT_PRESSED

cmpwi REG_INPUTS, R_PAD_LEFT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, R_PAD_RIGHT
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, R_PAD_UP
beq HANDLE_CHAT_INPUT_PRESSED
cmpwi REG_INPUTS, R_PAD_DOWN
bnel HANDLE_SKIP_CHAT_INPUT

HANDLE_CHAT_INPUT_PRESSED:

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
# Function: Send Chat Commnad 0 = ggs, 1 = brb, 2 = g2g, 3=one more, 4=last one
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

# Play a sound indicating a new message TODO: move to a function
li r3, 0xb7
li r4, 127
li r5, 64
branchl r12, 0x800237a8 # SFX_PlaySoundAtFullVolume

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

# create jbobj (custom chat window background)
lwz r3, -0x49eC(r13) # = 804db6a0 pointer to MnSlChar file
lwz r3, 0x18(r3) # pointer to our custom bg jobj
branchl r12,0x80370e44 #Create Jboj
mr  REG_CHAT_JOBJ,r3

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
branchl r12,0x8039069c # void GObj_AddGXLink(GOBJ *gobj, void *cb, int gx_link, int gx_pri)

# Add User Data to GOBJ ( Our buffer )
mr r3, REG_CHAT_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, r23 # memory pointer of allocated buffer above
branchl r12, GObj_Initialize

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
.set CHAT_WINDOW_IDLE_TIMER_TIME, 0x70 # initial idle timer before window disappears
.set CHAT_WINDOW_IDLE_TIMER_DELAY, 0x20 # initial delay before allowing to send messages
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
lbz REG_CHAT_WINDOW_SECOND_INPUT, CSSDT_CHAT_LAST_INPUT(REG_CHAT_WINDOW_CSSDT_ADDR)

# if text is not initialized, assume we need to initalize everything
# else skip to idle timer check
cmpwi REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, 0x00000000
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
cmpwi REG_CHAT_WINDOW_INPUT, PAD_UP
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_UP_CHAT_TEXT_PROPERTIES
cmpwi REG_CHAT_WINDOW_INPUT, PAD_DOWN
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_DOWN_CHAT_TEXT_PROPERTIES
cmpwi REG_CHAT_WINDOW_INPUT, PAD_RIGHT
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_RIGHT_CHAT_TEXT_PROPERTIES
cmpwi REG_CHAT_WINDOW_INPUT, PAD_LEFT
beq CSS_ONLINE_CHAT_WINDOW_THINK_INIT_LEFT_CHAT_TEXT_PROPERTIES

CSS_ONLINE_CHAT_WINDOW_THINK_INIT_UP_CHAT_TEXT_PROPERTIES:
bl UP_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_DOWN_CHAT_TEXT_PROPERTIES:
bl DOWN_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_RIGHT_CHAT_TEXT_PROPERTIES:
bl RIGHT_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_LEFT_CHAT_TEXT_PROPERTIES:
bl LEFT_CHAT_TEXT_PROPERTIES
mflr REG_CHAT_TEXT_PROPERTIES
b CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END
CSS_ONLINE_CHAT_WINDOW_THINK_INIT_CHAT_TEXT_PROPERTIES_END:

# Create Text Struct
li r3, 0x1 # Text kerning to close
li r4, 0x0 # Align Left
lfs f1, TPO_BASE_Z(REG_TEXT_PROPERTIES) # Z offset
lfs f2, TPO_BASE_CANVAS_SCALING(REG_TEXT_PROPERTIES) # Scale
bl FN_CREATE_TEXT_STRUCT # 801954ec

# Save Text Struct Address
mr REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, r3
stw REG_CHAT_WINDOW_TEXT_STRUCT_ADDR, CSSCWDT_TEXT_STRUCT_ADDR(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

# Create Subtext: Header
mr r3, REG_CHAT_WINDOW_TEXT_STRUCT_ADDR # Text Struct Address
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE # Text Color
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_CHAT_SHORTCUTS # String Format pointer
addi r6, REG_CHAT_TEXT_PROPERTIES, TPO_STRING_CHAT_SHORTCUT_NAME # String pointer
lfs f1, TPO_CHAT_LABEL_SIZE(REG_TEXT_PROPERTIES) # Text Size
lfs f2, TPO_CHAT_LABEL_X(REG_TEXT_PROPERTIES) # X POS
lfs f3, TPO_CHAT_LABEL_Y(REG_TEXT_PROPERTIES) # Y POS
bl FN_CREATE_SUBTEXT_CONCATENATED
mr r4, r3 # sub text index for next function call

# Create Subtext: Labels
mr r10, r4 # save sub text index of header # 0x80195520
mr r11, r4 # initialize looping index
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_START:

# calculate Y offset by moving it down a bit
addi r3, r11, CHAT_WINDOW_HEADER_MARGIN_LINES
lfs f2, TPO_CHAT_LABEL_MARGIN(REG_TEXT_PROPERTIES) # margin between labels
bl FN_MULTIPLY_FLOAT_RF
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
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_UP # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_DOWN_LABEL_ADDR:
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_DOWN # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_RIGHT_LABEL_ADDR:
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_RIGHT # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_SET_LEFT_LABEL_ADDR:
addi r6, REG_TEXT_PROPERTIES, TPO_STRING_LEFT # label String pointer
b CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END
CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_LABEL_ADDR_END:

CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_CALC_MSG_ADDR:
# calculate address of message
mr r3, r11
addi r3, r3, 1
mulli r7, r3, CHAT_TEXT_STRING_LENGTH

mr r3, REG_CHAT_WINDOW_TEXT_STRUCT_ADDR # Text Struct Address
addi r4, REG_TEXT_PROPERTIES, TPO_COLOR_WHITE # Text Color
addi r5, REG_TEXT_PROPERTIES, TPO_STRING_CHAT_LABEL_FORMAT # String Format pointer
addi r6, r6, 0 # label String pointer (this is a noop, actual cal assignment is done above)
add r7, REG_CHAT_TEXT_PROPERTIES, r7 # message String pointer
lfs f1, TPO_CHAT_LABEL_SIZE(REG_TEXT_PROPERTIES) # Text Size
lfs f2, TPO_CHAT_LABEL_X(REG_TEXT_PROPERTIES) # X POS
bl FN_CREATE_SUBTEXT_CONCATENATED
mr r11, r3 # save subtext index

# Loop back if last index has not been reached
addi r3, r10, 4 # Last index we want header + 4 labels
cmpw r11, r3
bne CSS_ONLINE_CHAT_WINDOW_THINK_CREATE_LABELS_LOOP_START

##### END: INITIALIZING CHAT WINDOW TEXT ###########
b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT # just initialize on first loop

CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_INPUT: # 0x8019562C
# prevent spam: Only allow input if a few frames have passed
lbz r3, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)
cmpwi r3, CHAT_WINDOW_IDLE_TIMER_TIME-CHAT_WINDOW_IDLE_TIMER_DELAY
bgt CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER

# load last input from the CSS Data table
# if there's any input, Send Message
cmpwi REG_CHAT_WINDOW_SECOND_INPUT, 0
beq CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER

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

b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT

CSS_ONLINE_CHAT_WINDOW_THINK_CHECK_IDLE_TIMER:
# check timer and decrease until is 0
cmpwi REG_CHAT_WINDOW_TIMER, 0
beq CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC # if timer is 0, then exit and delete think func.

CSS_ONLINE_CHAT_WINDOW_THINK_DECREASE_IDLE_TIMER:
subi REG_CHAT_WINDOW_TIMER, REG_CHAT_WINDOW_TIMER, 1
stb REG_CHAT_WINDOW_TIMER, CSSCWDT_TIMER(REG_CHAT_WINDOW_GOBJ_DATA_ADDR)

b CSS_ONLINE_CHAT_WINDOW_THINK_EXIT

CSS_ONLINE_CHAT_WINDOW_THINK_REMOVE_PROC: # TODO: is this the proper way to delete this proc?

# clear out chat window opened flag on the CSS Data Table
li r3, 0
stb r3, CSSDT_CHAT_WINDOW_OPENED(REG_CHAT_WINDOW_CSSDT_ADDR)

# remove proc
mr r3, REG_CHAT_WINDOW_GOBJ
branchl r12, GObj_RemoveProc

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
.set TPO_CHAT_LABEL_X, TPO_BASE_CANVAS_SCALING + 4
.float -330
.set TPO_CHAT_LABEL_Y, TPO_CHAT_LABEL_X + 4
.float 105
.set TPO_CHAT_LABEL_SIZE, TPO_CHAT_LABEL_Y + 4
.float 0.45
.set TPO_CHAT_LABEL_MARGIN, TPO_CHAT_LABEL_SIZE + 4
.float 25

# Text colors
.set TPO_COLOR_WHITE, TPO_CHAT_LABEL_MARGIN + 4
.long 0xFFFFFFFF # white

# String Properties
.set TPO_EMPTY_STRING, TPO_COLOR_WHITE + 4
.string ""
.set TPO_STRING_CHAT_SHORTCUTS, TPO_EMPTY_STRING + 1
.string "Chat: %s"
.set TPO_STRING_CHAT_LABEL_FORMAT, TPO_STRING_CHAT_SHORTCUTS + 9
.string "%s: %s"
.set TPO_STRING_GAME, TPO_STRING_CHAT_LABEL_FORMAT + 7
.string "Game"
.set TPO_STRING_UP, TPO_STRING_GAME + 5
.string "U"
.set TPO_STRING_LEFT, TPO_STRING_UP + 2
.string "L"
.set TPO_STRING_RIGHT, TPO_STRING_LEFT + 2
.string "R"
.set TPO_STRING_DOWN, TPO_STRING_RIGHT + 2
.string "D"
.set TPO_STRING_PLUS, TPO_STRING_DOWN + 2
.short 0x817B # ＋
.byte 0x00
.align 2

################################################################################
# Chat Message Properties
# Hack: CAP TO SAME LENGTH to ensure pointers are always reached
################################################################################
.set CHAT_TEXT_STRING_LENGTH, 22 +1  # +1 is string ending char
UP_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_CHAT_SHORTCUT_NAME, 0
.string "Common                "
.set TPO_STRING_MSG_UP, TPO_STRING_CHAT_SHORTCUT_NAME + CHAT_TEXT_STRING_LENGTH
.string "ggs                   "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "one more              "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "brb                   "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "good luck             "
.align 2

LEFT_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_CHAT_SHORTCUT_NAME, 0
.string "Compliments           "
.set TPO_STRING_MSG_UP, TPO_STRING_CHAT_SHORTCUT_NAME+CHAT_TEXT_STRING_LENGTH
.string "well played           "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "too good              "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "that was fun          "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "thanks                "
.align 2

RIGHT_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_CHAT_SHORTCUT_NAME, 0
.string "Reactions             "
.set TPO_STRING_MSG_UP, TPO_STRING_CHAT_SHORTCUT_NAME+CHAT_TEXT_STRING_LENGTH
.string "lol                   "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "sorry                 "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "oops                  "
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "wow                   "
.align 2

DOWN_CHAT_TEXT_PROPERTIES:
blrl
.set TPO_STRING_CHAT_SHORTCUT_NAME, 0
.string "Misc                  "
.set TPO_STRING_MSG_UP, TPO_STRING_CHAT_SHORTCUT_NAME+CHAT_TEXT_STRING_LENGTH
.string "back                  "
.set TPO_STRING_MSG_LEFT, TPO_STRING_MSG_UP + CHAT_TEXT_STRING_LENGTH
.string "thinking              "
.set TPO_STRING_MSG_RIGHT, TPO_STRING_MSG_LEFT + CHAT_TEXT_STRING_LENGTH
.string "let's play again later"
.set TPO_STRING_MSG_DOWN, TPO_STRING_MSG_RIGHT + CHAT_TEXT_STRING_LENGTH
.string "bad connection        "
.align 2

################################################################################
# Function: Initializes Text struct
# r3 = kerning, r4 = alignment, f1 = z offset, f2 = scaling
################################################################################
FN_CREATE_TEXT_STRUCT:
# gp registers
.set REG_KERNING, 6
.set REG_ALIGNMENT, REG_KERNING+1
.set REG_TEXT_STRUCT_ADDR, REG_ALIGNMENT+1
# float registers
.set REG_Z_OFFSET, REG_KERNING
.set REG_SCALING, REG_Z_OFFSET+1

# Save arguments
mr REG_KERNING, r3
mr REG_ALIGNMENT, r4

fmr REG_Z_OFFSET, f1
fmr REG_SCALING, f2
backup

# Create Text Struct
li r3, 0 # 0x8019563C
li r4, 0
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT_ADDR, r3

# Set text kerning
stb REG_KERNING, 0x49(REG_TEXT_STRUCT_ADDR)
# Set text alignment
stb REG_ALIGNMENT, 0x4A(REG_TEXT_STRUCT_ADDR)
# set z offset
stfs REG_Z_OFFSET, 0x8(REG_TEXT_STRUCT_ADDR)
# set scale
stfs REG_SCALING, 0x24(REG_TEXT_STRUCT_ADDR)
stfs REG_SCALING, 0x28(REG_TEXT_STRUCT_ADDR)

# Return text struct Pointer in r3
mr r3, REG_TEXT_STRUCT_ADDR
restore
blr

################################################################################
# Function: Creates and initalizes a subtext
# r3 = text struct pointer, r4 = string pointer, r5 = color pointer, f1 = text size, f2 = x, f3 = y pos
################################################################################
FN_CREATE_SUBTEXT:
# gp registers
.set REG_TEXT_STRUCT_ADDR, 28
.set REG_STRING_ADDR, REG_TEXT_STRUCT_ADDR+1
.set REG_COLOR_ADDR, REG_STRING_ADDR+1
.set REG_SUBTEXT_INDEX, REG_COLOR_ADDR+1
# float registers
.set REG_SIZE, REG_TEXT_STRUCT_ADDR
.set REG_X, REG_SIZE+1
.set REG_Y, REG_X+1

# Save arguments
mr REG_TEXT_STRUCT_ADDR, r3
mr REG_STRING_ADDR, r4
mr REG_COLOR_ADDR, r5

fmr REG_SIZE, f1
fmr REG_X, f2
fmr REG_Y, f3
backup

# Initialize subtext
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_STRING_ADDR
fmr f1, REG_X
fmr f2, REG_Y
branchl r12, Text_InitializeSubtext
mr REG_SUBTEXT_INDEX, r3

# Set Text Size
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
fmr f1, REG_SIZE
fmr f2, REG_SIZE
branchl r12, Text_UpdateSubtextSize

# Set Text Color
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
mr r5, REG_COLOR_ADDR
branchl r12, Text_ChangeTextColor


# Return subtext index
mr r3, REG_SUBTEXT_INDEX
restore
blr

################################################################################
# Function: Creates and initalizes a subtext # 801957A0
# r3 = text struct pointer, r4 = color pointer, r5 = string format pointer, r6-r{n}= string pointers, f1 = text size, f2 = x, f3 = y pos
################################################################################
FN_CREATE_SUBTEXT_CONCATENATED:
# gp registers
.set REG_TEXT_STRUCT_ADDR, 21
.set REG_STRING_FORMAT_ADDR, REG_TEXT_STRUCT_ADDR+1
.set REG_STRING_1_ADDR, REG_STRING_FORMAT_ADDR+1
.set REG_STRING_2_ADDR, REG_STRING_1_ADDR+1
.set REG_STRING_3_ADDR, REG_STRING_2_ADDR+1
.set REG_COLOR_ADDR, REG_STRING_3_ADDR+1
.set REG_SUBTEXT_INDEX, REG_COLOR_ADDR+1
# float registers
.set REG_SIZE, REG_TEXT_STRUCT_ADDR
.set REG_X, REG_SIZE+1
.set REG_Y, REG_X+1

# Save arguments
mr REG_TEXT_STRUCT_ADDR, r3
mr REG_COLOR_ADDR, r4
mr REG_STRING_FORMAT_ADDR, r5
mr REG_STRING_1_ADDR, r6
mr REG_STRING_2_ADDR, r7
mr REG_STRING_3_ADDR, r8

fmr REG_SIZE, f1
fmr REG_X, f2
fmr REG_Y, f3
backup

mr r4, REG_STRING_FORMAT_ADDR
mr r5, REG_COLOR_ADDR
bl FN_CREATE_SUBTEXT
mr REG_SUBTEXT_INDEX, r3 # sub text index

# Concatenate user name with message "User: Message"
mr r3, REG_TEXT_STRUCT_ADDR
mr r4, REG_SUBTEXT_INDEX
mr r5, REG_STRING_FORMAT_ADDR
mr r6, REG_STRING_1_ADDR
mr r7, REG_STRING_2_ADDR
mr r8, REG_STRING_3_ADDR
branchl r12, Text_UpdateSubtextContents

# Return subtext index
mr r3, REG_SUBTEXT_INDEX
restore
blr

################################################################################
# Converts int to float returns f3 as converted value (stolen from CreateText.asm)
################################################################################
IntToFloat:
stwu r1,-0x100(r1)	# make space for 12 registers
stfs  f2,0x8(r1)

lis	r0, 0x4330
lfd	f2, -0x6758 (rtoc)
xoris	r3, r3,0x8000
stw	r0,0xF0(sp)
stw	r3,0xF4(sp)
lfd	f1,0xF0(sp)
fsubs	f1,f1,f2		#Convert To Float

lfs  f2,0x8(r1)
addi	r1,r1,0x100	# release the space
blr

################################################################################
# Multiplies r3=int with f2=float
# return result in f1
################################################################################
FN_MULTIPLY_FLOAT_RF:
backup
bl IntToFloat # returns f1
fmuls f1, f1, f2
restore
blr

################################################################################
# Skip starting match
################################################################################
SKIP_START_MATCH:
restore
branch r12, 0x80263334

EXIT:
restore
