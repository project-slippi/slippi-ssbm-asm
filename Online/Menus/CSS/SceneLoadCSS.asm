################################################################################
# Address: 0x8026699c # SceneLoad_CSS
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/Teams/Teams.s"

# We moved initialization of memory to here from LoadCSSText.asm because it runs every time name
# entry is closed, which would cause Dolphin to run out of memory

b CODE_START

################################################################################
# User text config
################################################################################
DATA_BLRL:
blrl
.float -112 # X Pos of User Display, 0x0
.float 20 # Y Pos of User Display, 0x4
.float 0 # Z Offset, 0x8
.float 0.1 # Scaling, 0xC
.set DO_USER_TEXT_INPUT, 0

# File-related strings
.string "slpCSS.dat"
.set DO_STRING_SLPCSS_FILENAME, DO_USER_TEXT_INPUT + 0x10
.string "slpCSS"
.set DO_STRING_SLPCSS_SYMBOLNAME, DO_STRING_SLPCSS_FILENAME + 11
.align 2

CODE_START:
stw r0, -0x49C8(r13) # replaced code line

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal


.set REG_CSSDT_ADDR, 31
.set REG_LOCAL_DATA_ADDR, 30

backup

bl DATA_BLRL
mflr REG_LOCAL_DATA_ADDR

################################################################################
# Prepare user text display
################################################################################
# Get static function table
branchl r12, FG_UserDisplay
mflr r3

# Init app state buffers
addi r12, r3, 0x14 # FN_InitBuffers
mtctr r12
bctrl

################################################################################
# Allocate memory locations
################################################################################
# Initialize CSS data table
li r3, CSSDT_SIZE
branchl r12, HSD_MemAlloc
mr REG_CSSDT_ADDR, r3

# Zero out CSS data table
li r4, CSSDT_SIZE
branchl r12, Zero_AreaLength

# Store CSSDT to static mem location
load r3, CSSDT_BUF_ADDR
stw REG_CSSDT_ADDR, 0(r3)

# Prepare the MSRB buffer
li r3, MSRB_SIZE
branchl r12, HSD_MemAlloc
stw r3, CSSDT_MSRB_ADDR(REG_CSSDT_ADDR)

################################################################################
# Initialize values
################################################################################
# Initialize start team color to red (only on teams mode)
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_TEAMS
bne SKIP_TEAM_SETUP

# Fetch INJ data table in order to get previous team idx
# Needed to restore the proper team color after a game finishes
computeBranchTargetAddress r3, INJ_InitTeamToggleButton
lbz r3, IDO_TEAM_IDX(r3)
stb r3, CSSDT_TEAM_IDX(REG_CSSDT_ADDR)

SKIP_TEAM_SETUP:
################################################################################
# Load Chat File
################################################################################
# Load File
addi r3, REG_LOCAL_DATA_ADDR, DO_STRING_SLPCSS_FILENAME
branchl r12,0x80016be0

# Retrieve symbol from file data
addi r4, REG_LOCAL_DATA_ADDR, DO_STRING_SLPCSS_SYMBOLNAME
branchl r12,0x80380358

# Save this pointer
stw r3, CSSDT_SLPCSS_ADDR(REG_CSSDT_ADDR)

restore

EXIT:

