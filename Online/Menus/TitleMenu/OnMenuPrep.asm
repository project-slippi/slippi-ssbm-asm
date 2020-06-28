################################################################################
# Address: 0x801b1040 # ScenePrep_MainMenu
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_FG_USER_DISPLAY, 30

backup

################################################################################
# Section 1: Overwrite handler function pointer for going back to menu from
# major 0x8
################################################################################
bl FN_OnReturnFromOnline
mflr r3
load r4, 0x803dd908
stw r3, 0(r4)

################################################################################
# Section 2: Prepare the online submenu
################################################################################
load r3, 0x803eb750 # Start of online submenu entry (0x14 long)

# Write the ptr to think function
bl FN_OnlineSubmenuThink
mflr r4
stw r4, 0x10(r3)

# Write other submenu data
bl Data_OnlineSubmenuOptions
mflr r4
li r5, 0x10
branchl r12, memcpy

load r3, 0x803eb750 # Start of online submenu entry (0x14 long)
bl Data_OnlineSubmenuDescriptions
mflr r4
stw r4, 0x8(r3) # Overwrite description text locations

load r3, 0x803eb66c # Start or 1P mode submenu entry
li r4, 0x644
sth r4, 0x4(r3) # Set 3rd option description text (online submenu)

################################################################################
# Section 3: Store function for switching to online submenu
################################################################################
bl FN_SwitchToOnlineMenu_blrl
mflr r3
stw r3, OFST_R13_SWITCH_TO_ONLINE_SUBMENU(r13)

################################################################################
# Section 4: Prepare user display buffers and data for finding first unlocked
# when returning from online menu or any other menu. Also prepares it for the
# actual user display
################################################################################
# Get static function table
branchl r12, FG_UserDisplay
mflr REG_FG_USER_DISPLAY # This will be restored by parent function

# Init app state buffers
addi r12, REG_FG_USER_DISPLAY, 0x14 # FN_InitBuffers
mtctr r12
bctrl

# Fetch app state, used to determine which options are hidden
addi r12, REG_FG_USER_DISPLAY, 0xC # FN_FetchSlippiAppState
mtctr r12
bctrl

restore
b EXIT

################################################################################
# Routine: OnReturnFromOnline
# ------------------------------------------------------------------------------
# Description: Writes the proper menu and selection when returning from online
# mode
################################################################################
.set REG_FG_USER_DISPLAY, 30 # This will be reset by parent function

FN_OnReturnFromOnline:
blrl

# Get static function table
branchl r12, FG_UserDisplay
mflr REG_FG_USER_DISPLAY # This will be restored by parent function

# Set the submenu to go to
li r0, 8 # Go to submenu 0x8 (Online Play)
stb r0, 0(r31)

# Get the selected index we want
li r3, 0x8
lbz r4, OFST_R13_ONLINE_MODE(r13) # The online mode is the option we want
branchl r12, 0x80229938 # MainMenu_CheckIfOptionIsUnlocked
cmpwi r3, 0
lbz r3, OFST_R13_ONLINE_MODE(r13) # The online mode is the option we want
bne FN_OnReturnFromOnline_SET_SELECTED_INDEX

# If option we want is locked, fetch first unlocked option
addi r12, REG_FG_USER_DISPLAY, 0x10 # FN_GetFirstUnlocked
mtctr r12
bctrl

FN_OnReturnFromOnline_SET_SELECTED_INDEX:
stb r3, 0x1(r31)

# Go to end of function
branch r12, 0x801b136c

################################################################################
# Routine: SwitchToOnlineMenu
# ------------------------------------------------------------------------------
# Description: Triggers a switch to the online submenu
################################################################################
FN_SwitchToOnlineMenu_blrl:
blrl
FN_SwitchToOnlineMenu:
backup

# Most of the code in this function is stolen from game logic so it's a bit
# weird... r27 is returned as r3 so it can mimic a direct function call
load r31, 0x804a04f0
load r30, 0x803eae68

li	r0, 5
sth	r0, -0x4AD8 (r13)

# Fetch first unlocked option
branchl r12, FG_UserDisplay
mflr r3
addi r12, r3, 0x10 # FN_GetFirstUnlocked
mtctr r12
bctrl
mr r0, r3 # Option to select

# Continue
li	r4, 8 # Go to online menu
lbz	r5, 0 (r31)
li	r3, 1
stb	r5, 0x0001 (r31)
stb	r4, 0 (r31)
sth	r0, 2 (r31)
branchl r12, 0x8022B3A0
branchl r12, 0x80390CD4
lwz	r3, -0x3E84 (r13)
branchl r12, 0x80390228
lwz	r27, 0x08F8 (r30) # Load think function
cmplwi	r27, 0
beq- SKIP_TO_END_OF_PARENT
li	r3, 0
li	r4, 1
li	r5, 128
branchl r12, GObj_Create
addi	r4, r27, 0
li	r5, 0
branchl r12, GObj_AddProc
lwz	r4, -0x3E64 (r13)
lbz	r0, 0x000D (r3)
rlwimi	r0, r4, 4, 26, 27
stb	r0, 0x000D (r3)

# Force menu to change (normally changing to the same menu would not clear old menu)
li r3, 1
stb r3, OFST_R13_FORCE_MENU_CLEAR(r13)

# Return this such that we can mimic a direct execution
mr r3, r27

restore
blr

################################################################################
# Routine: OnlineSubmenuThink
# ------------------------------------------------------------------------------
# Description: Think function for online submenu
################################################################################
.set REG_FG_USER_DISPLAY, 27

FN_OnlineSubmenuThink:
blrl

backup

################################################################################
# Most of the below is ported code from function 8022cc28 (Menus_RegularMatch)
################################################################################
lis r3, 0x804A
addi r29, r3, 0x4F0
li r3, 4
branchl r12, 0x80229624 # MainMenu_GetAllControllerInstantButtons
stw r3, 0xC(r29)
li	r30, 0
stw	r30, 0x0008 (r29)
rlwinm.	r0, r3, 0, 27, 27
beq- FN_OnlineSubmenuThink_A_PRESS_HANDLER_END

################################################################################
# A Press Handler
################################################################################
FN_OnlineSubmenuThink_A_PRESS_HANDLER:
# The following is copied and I think its primary goal is to update which
# controller is considered to be the "active player"
li	r0, 5
sth	r0, -0x4AD8 (r13)
li	r31, 1
addi	r28, r30, 0
stb	r31, 0x0011 (r29)
FN_OnlineSubmenuThink_A_PRESS_CHECK_PORT_INPUTS:
rlwinm	r3, r28, 0, 24, 31
branchl r12, 0x801A36A0 # Inputs_GetPlayerInstantInputs
and	r0, r3, r31
and	r4, r4, r30
xor	r3, r4, r30
xor	r0, r0, r30
or.	r0, r3, r0
beq- FN_OnlineSubmenuThink_A_PRESS_CHECK_NEXT_PORT
rlwinm	r3, r28, 0, 24, 31
b	FN_OnlineSubmenuThink_A_PRESS_UPDATE_PLAYER_PORT
FN_OnlineSubmenuThink_A_PRESS_CHECK_NEXT_PORT:
addi	r28, r28, 1
cmpwi	r28, 4
blt+ FN_OnlineSubmenuThink_A_PRESS_CHECK_PORT_INPUTS
li	r3, 0
FN_OnlineSubmenuThink_A_PRESS_UPDATE_PLAYER_PORT:
branchl r12, 0x801677E8 # CSS_StoreSinglePlayerPortNumber

lhz r0, 0x0002 (r29) # Load selected option index
cmpwi r0, 0 # Check if Ranked
beq FN_OnlineSubmenuThink_HANDLE_RANKED
cmpwi r0, 1 # Check if Unranked
beq FN_OnlineSubmenuThink_HANDLE_UNRANKED
cmpwi r0, 2 # Check if Direct
beq FN_OnlineSubmenuThink_HANDLE_DIRECT
cmpwi r0, 3 # Check if Log-in
beq FN_OnlineSubmenuThink_HANDLE_LOGIN
cmpwi r0, 4 # Check if Log-out
beq FN_OnlineSubmenuThink_HANDLE_LOGOUT
cmpwi r0, 5 # Check if update
beq FN_OnlineSubmenuThink_HANDLE_UPDATE
b FN_OnlineSubmenuThink_INPUT_HANDLERS_END

################################################################################
# Option Selected Handlers
################################################################################
FN_OnlineSubmenuThink_HANDLE_RANKED:
li	r3, 3
branchl r12, SFX_Menu_CommonSound
b FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_HANDLE_UNRANKED:
li r3, ONLINE_MODE_UNRANKED
b FN_OnlineSubmenuThink_GO_TO_CSS

FN_OnlineSubmenuThink_HANDLE_DIRECT:
li r3, ONLINE_MODE_DIRECT
b FN_OnlineSubmenuThink_GO_TO_CSS

FN_OnlineSubmenuThink_HANDLE_LOGIN:
li	r3, 1
branchl r12, SFX_Menu_CommonSound

li r4, CONST_SlippiCmdOpenLogIn
b FN_OnlineSubmenuThink_TRIGGER_EXI_MSG

FN_OnlineSubmenuThink_HANDLE_LOGOUT:
li r4, CONST_SlippiCmdLogOut
b FN_OnlineSubmenuThink_TRIGGER_EXI_MSG

FN_OnlineSubmenuThink_HANDLE_UPDATE:
li	r3, 1
branchl r12, SFX_Menu_CommonSound

li r4, CONST_SlippiCmdUpdateApp
b FN_OnlineSubmenuThink_TRIGGER_EXI_MSG

FN_OnlineSubmenuThink_GO_TO_CSS:
# Set the selected mode
stb r3, OFST_R13_ONLINE_MODE(r13)

# Play success sound
li	r3, 1
branchl r12, SFX_Menu_CommonSound

# Go to online mode CSS
li r3, 0x8
branchl r12, Event_StoreSceneNumber
b FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_TRIGGER_EXI_MSG:
# Use the scene buffer cause it's not being used for anything
lwz r3, OFST_R13_SB_ADDR(r13)
stb r4, 0(r3) # Store command byte
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

b FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_A_PRESS_HANDLER_END:

rlwinm.	r0, r3, 0, 26, 26
beq- FN_OnlineSubmenuThink_B_PRESS_HANDLER_END

################################################################################
# B Press Handler
################################################################################
FN_OnlineSubmenuThink_B_PRESS_HANLER:
li	r3, 0
branchl r12, SFX_Menu_CommonSound
stb	r30, 0x0011 (r29)
li	r3, 5
li	r0, 1
sth	r3, -0x4AD8 (r13)
li	r3, 3
lbz	r4, 0 (r29)
stb	r4, 0x0001 (r29)
stb	r0, 0 (r29)
li r0, 2
sth	r0, 0x0002 (r29)
branchl r12, 0x8022B3A0
branchl r12, 0x80390CD4
lwz	r3, -0x3E84 (r13)
branchl r12, 0x80390228
lis	r3, 0x803F
subi	r3, r3, 18768
lwz	r28, 0x0024 (r3)
cmplwi	r28, 0
beq-	 FN_OnlineSubmenuThink_INPUT_HANDLERS_END
li	r3, 0
li	r4, 1
li	r5, 128
branchl r12, 0x803901F0
addi	r4, r28, 0
li	r5, 0
branchl r12, 0x8038FD54
lwz	r4, -0x3E64 (r13)
lbz	r0, 0x000D (r3)
rlwimi	r0, r4, 4, 26, 27
stb	r0, 0x000D (r3)
b	FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_B_PRESS_HANDLER_END:

rlwinm.	r0, r3, 0, 31, 31
beq- FN_OnlineSubmenuThink_STICK_UP_HANDLER_END
################################################################################
# Stick Up Handler
################################################################################
FN_OnlineSubmenuThink_STICK_UP_HANDLER:
li r3, 2
branchl r12, SFX_Menu_CommonSound
li r31, 5 # Bottom index
addi r28, r29, 2
FN_OnlineSubmenuThink_STICK_UP_INDEX_ADJUST_START:
lhz r3, 0(r28) # Load current index
cmplwi r3, 0
beq- FN_OnlineSubmenuThink_WRAP_TO_BOTTOM
subi r0, r3, 1
sth r0, 0(r28)
b FN_OnlineSubmenuThink_STICK_UP_INDEX_ADJUST_COMPLETE
FN_OnlineSubmenuThink_WRAP_TO_BOTTOM:
sth r31, 0(r28)
FN_OnlineSubmenuThink_STICK_UP_INDEX_ADJUST_COMPLETE:
li r3, 0x8
lhz r4, 0(r28)
branchl r12, 0x80229938 # MainMenu_CheckIfOptionIsUnlocked
cmpwi r3, 0
beq FN_OnlineSubmenuThink_STICK_UP_INDEX_ADJUST_START
b	FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_STICK_UP_HANDLER_END:

rlwinm.	r0, r3, 0, 30, 30
beq- FN_OnlineSubmenuThink_STICK_DOWN_HANDLER_END
################################################################################
# Stick Down Handler
################################################################################
FN_OnlineSubmenuThink_STICK_DOWN_HANDLER:
li r3, 2
branchl r12, SFX_Menu_CommonSound
# Play MELEE sfx
addi r28, r29, 2
FN_OnlineSubmenuThink_STICK_DOWN_INDEX_ADJUST_START:
lhz r3, 0(r28) # Load current index
cmplwi r3, 5 # Check if at bottom
beq- FN_OnlineSubmenuThink_WRAP_TO_TOP
addi r0, r3, 1
sth r0, 0(r28)
b FN_OnlineSubmenuThink_STICK_DOWN_INDEX_ADJUST_COMPLETE
FN_OnlineSubmenuThink_WRAP_TO_TOP:
sth r30, 0(r28)
FN_OnlineSubmenuThink_STICK_DOWN_INDEX_ADJUST_COMPLETE:
li r3, 0x8
lhz r4, 0(r28)
branchl r12, 0x80229938 # MainMenu_CheckIfOptionIsUnlocked
cmpwi r3, 0
beq FN_OnlineSubmenuThink_STICK_DOWN_INDEX_ADJUST_START
b	FN_OnlineSubmenuThink_INPUT_HANDLERS_END

FN_OnlineSubmenuThink_STICK_DOWN_HANDLER_END:
FN_OnlineSubmenuThink_INPUT_HANDLERS_END:

################################################################################
# Update user text
################################################################################
branchl r12, FG_UserDisplay
mflr REG_FG_USER_DISPLAY
addi r3, REG_FG_USER_DISPLAY, 0x4 # FN_UserTextUpdate
mtctr r3
bctrl

################################################################################
# Handle menu change to hide User text if in different sub-menu
################################################################################
addi r3, REG_FG_USER_DISPLAY, 0x8 # FN_HandleMenuChange
mtctr r3
bctrl

FN_OnlineSubmenuThink_EXIT:
restore

################################################################################
# Data: OnlineSubmenuOptions
# ------------------------------------------------------------------------------
# Description: These are the new submenu table values for menu
# 0x8 (Originally Smash Dojo). The ptr to the think function comes at the
# end and will be written separately
################################################################################
Data_OnlineSubmenuOptions:
blrl

.long 0x803eb57c # Ptr to preview animation frame values (stolen from reg match)
.float 140 # Frame index pointing at the option text images
.long 0x803eb684 # Ptr to description text. Will be overwritten
.long 0x06000000 # First byte is the number of options

Data_OnlineSubmenuDescriptions:
blrl
.short 0x0645
.short 0x0646
.short 0x0647
.short 0x0648
.short 0x0649
.short 0x064A

EXIT:
lis r3, 0x804A
