#To be inserted at 801bfa20
.include "../../Common/Common.s"
#.include "../Globals.s"
.include "Header.s"

load r4, 0x803dd8e8 # Location where scene load handlers start
bl FN_OnFirstMenuLoad_blrl
mflr r3
stw r3, 0xa0(r4) # Overwrite the scene load handler transition from scene 0x28

b EXIT

################################################################################
# OnFirstMenuLoad
################################################################################
# Description:
# This will cause the first menu load to go to the online submenu
################################################################################
FN_OnFirstMenuLoad_blrl:
blrl

# Get static function table
branchl r12, FG_UserDisplay
mflr r30 # This will be restored by parent function

# Init app state buffers
addi r12, r30, 0x14 # FN_InitBuffers
mtctr r12
bctrl

# Fetch app state, used to determine which options are hidden
addi r12, r30, 0xC # FN_FetchSlippiAppState
mtctr r12
bctrl

# Set the submenu to go to
li r0, 8 # Go to submenu 0x8 (Online Play)
stb r0, 0(r31)

# Fetch first unlocked option
addi r12, r30, 0x10 # FN_GetFirstUnlocked
mtctr r12
bctrl
mr r0, r3 # Option to select
stb r0, 0x1(r31)

# Restore original handler, this handler was just a one-shot for boot
load r4, 0x803dd8e8 # Location where scene load handlers start
load r3, 0x801b1360 # Original title -> menu transition handler
stw r3, 0xa0(r4)

# Go to end of function
branch r12, 0x801b136c

################################################################################
# Code end
################################################################################
EXIT:
li r3, 0x1 # Load menu first
