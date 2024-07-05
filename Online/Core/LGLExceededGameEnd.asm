################################################################################
# Address: 0x802f70c4 # HUD_DisplayEndingExclaimationGraphic
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_P1_LEDGE_GRABS, 28
.set REG_P2_LEDGE_GRABS, 27
.set REG_LGL_LOSER, 26
.set REG_DISPLAY_MESSAGE_ID, 25
.set REG_DO, 24
.set REG_FILL_COLOR, 23
.set REG_FIRST_STRING, 22

# This function's main goal is to overwrite the message displayed on an LGL timeout. Here are the options:
# 0: Time, 1: Sudden Death, 2: Success, 3: Ready, 4: GO!, 5: Game!, 6: Failure, 7: Complete, 8: Nothing, 9: Crash

b CODE_START

DATA_BLRL:
blrl
.set DO_SCALE, 0
.float 0.7
.set DO_POS_X, DO_SCALE + 4
.float 0
.set DO_POS_Y_WIN, DO_POS_X + 4
.float 70
.set DO_POS_Y_LOSS, DO_POS_Y_WIN + 4
.float 60
.set DO_STROKE_OFFSET, DO_POS_Y_LOSS + 4
.float 1
.set DO_COLOR_OUTLINE, DO_STROKE_OFFSET + 4
.byte 0,0,0,255
.set DO_COLOR_FILL_LOSS, DO_COLOR_OUTLINE + 4
.byte 215,165,255,255
.set DO_COLOR_FILL_WIN, DO_COLOR_FILL_LOSS + 4
.byte 250,250,120,255
.set DO_STRING_YOU, DO_COLOR_FILL_WIN + 4
.string "You"
.set DO_STRING_OPP, DO_STRING_YOU + 4
.string "Opponent"
.set DO_STRING, DO_STRING_OPP + 9
.string "%s Exceeded Ledge Grab Limit of %d"
.align 2


CODE_START:
backup

# Store values of r4-r6 so we can restore on exit. They are args to the function that will be called.
# The other args, r3, r7, and r8 are about to be set so we don't need to worry about those
mr r31, r4
mr r30, r5
mr r29, r6
li REG_DISPLAY_MESSAGE_ID, 0

# Grab data address
bl DATA_BLRL
mflr REG_DO

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

# Don't run this code for teams
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
beq EXIT

# Check to see if this is an LGL victory

# Fetch ledge grab amounts
li r3, 0
branchl r12, 0x80040af0 # PlayerBlock_GetCliffhangerStat
mr REG_P1_LEDGE_GRABS, r3
li r3, 1
branchl r12, 0x80040af0 # PlayerBlock_GetCliffhangerStat
mr REG_P2_LEDGE_GRABS, r3

# First handle condition where both players are over LGL
cmpwi REG_P1_LEDGE_GRABS, LGL_LIMIT
ble CHECK_LGL_LOSS
cmpwi REG_P2_LEDGE_GRABS, LGL_LIMIT
bgt EXIT # If we branch here both players have more than 45 so ignore LGL

CHECK_LGL_LOSS:
cmpwi REG_P1_LEDGE_GRABS, LGL_LIMIT
li REG_LGL_LOSER, 0
bgt SET_MODIFIED_MESSAGE # If P1 has more than 45 ledge grabs, P2 wins
cmpwi REG_P2_LEDGE_GRABS, LGL_LIMIT
li REG_LGL_LOSER, 1
bgt SET_MODIFIED_MESSAGE # If P2 has more than 45 ledge grabs, P1 wins
b EXIT # If neither player has more than 45 ledge grabs, exit

SET_MODIFIED_MESSAGE:
# Check if we won or lost via LGL
lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_LOCAL_PLAYER_INDEX(r3)
cmpw r3, REG_LGL_LOSER # Compare local player index of winner
li REG_DISPLAY_MESSAGE_ID, 2 # Set message to "Success" if we won
addi REG_FILL_COLOR, REG_DO, DO_COLOR_FILL_WIN
addi REG_FIRST_STRING, REG_DO, DO_STRING_OPP
lfs f3, DO_POS_Y_WIN(REG_DO)
bne DISPLAY_LGL_MESSAGE
li REG_DISPLAY_MESSAGE_ID, 6 # Set message to "Failure" if we lost
addi REG_FILL_COLOR, REG_DO, DO_COLOR_FILL_LOSS
addi REG_FIRST_STRING, REG_DO, DO_STRING_YOU
lfs f3, DO_POS_Y_LOSS(REG_DO)

# Make game exit transition longer
load r3, 0x8046b6a0 # Some static match state struct
li r4, 0xFD # Default value for this is 0x6e
stb r4, 0x24D5(r3) # Overwrite the GAME! think max time to make it longer

DISPLAY_LGL_MESSAGE:

lwz r3, OFST_R13_ODB_ADDR(r13) # data buffer address
lwz r3, ODB_HUD_TEXT_STRUCT(r3)
mr r4, REG_FILL_COLOR
li r5, 1
addi r6, REG_DO, DO_COLOR_OUTLINE # Outline Color
addi r7, REG_DO, DO_STRING # String
mr r8, REG_FIRST_STRING
li r9, LGL_LIMIT # LGL Limit
lfs f1, DO_SCALE(REG_DO)
lfs f2, DO_POS_X(REG_DO)
lfs f6, DO_STROKE_OFFSET(REG_DO)
branchl r12, FG_CreateSubtext

EXIT:
# Restore r4-r6
mr r4, r31
mr r5, r30
mr r6, r29
mr r3, REG_DISPLAY_MESSAGE_ID # Use the message ID we set earlier. 0 if no LGL which is replaced codeline
restore
addi r7, r31, 0 # Line 802f70c0 may have been clobbered, set it again