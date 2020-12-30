################################################################################
# Address: 0x801b1040 # ScenePrep_MainMenu
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# general registers
.set REG_FG_USER_DISPLAY, 21
.set REG_DLG_BUFFER_SIZE, REG_FG_USER_DISPLAY+1
.set REG_DLG_BUFFER_ADDRESS, REG_DLG_BUFFER_SIZE+1

.set REG_DLG_GOBJ, REG_DLG_BUFFER_ADDRESS+1
.set REG_DLG_JOBJ, REG_DLG_GOBJ+1

# Registers used on Dialog think function, start at REG_DLG_JOBJ
.set REG_DLG_USER_DATA_ADDR, REG_DLG_JOBJ+1
.set REG_DLG_SELECTED_OPTION, REG_DLG_USER_DATA_ADDR+1 # 0: NO, 1: YES
.set REG_DLG_MENU_GOBJ_ADDR, REG_DLG_SELECTED_OPTION+1
.set REG_DLG_TEXT_STRUCT_ADDR, REG_DLG_MENU_GOBJ_ADDR+1
.set REG_TEXT_PROPERTIES, REG_DLG_TEXT_STRUCT_ADDR+1

.set REG_JOBJ_DESC_ADDR, REG_DLG_USER_DATA_ADDR
.set REG_JOBJ_DESC_ANIM_JOINT_ADDR, REG_JOBJ_DESC_ADDR+1
.set REG_JOBJ_DESC_MAT_JOINT_ADDR, REG_JOBJ_DESC_ANIM_JOINT_ADDR+1
.set REG_JOBJ_DESC_SHAPE_JOINT_ADDR, REG_JOBJ_DESC_MAT_JOINT_ADDR+1

# float registers
.set REG_F_0, 22
.set REG_F_1, 23

# Dialog Constants
.set DLG_JOBJ_OFFSET, 0x28 # offset from GOBJ to HSD Object (Jobj we assigned)
.set DLG_USER_DATA_OFFSET, 0x2C # offset from GOBJ to entity data
.set DLG_OPTION_YES, 0x1
.set DLG_OPTION_NO, 0x0

# PAD Constants for dialog when using Inputs_GetPlayerHeldInputs on the dialog
.set PAD_LEFT, 0x40 # on r4 is 00040000
.set PAD_RIGHT, 0x80 # on r4 is 00080000
.set PAD_A, 0x01 # on r4 is 00000100
.set PAD_B, 0x02 # on r4 is 00000200

# Dialog Static Memory JOBJ Descriptors Locations/Pointers
.set JOBJ_DESC_DLG, 0x803efa0c # archive memory address of dialog jobj
.set JOBJ_DESC_DLG_ANIM_JOINT, 0x803efa24 # archive memory address of dialog anim joint
.set JOBJ_DESC_DLG_MAT_JOINT, 0x803efa40 # archive memory address of dialog mat joint
.set JOBJ_DESC_DLG_SHAPE_JOINT, 0x803efa60 # archive memory address of dialog shape joint
.set JOBJ_CHILD_OFFSET, 0x34 # Pointer to store Child JOBJ on the SP

# Offset from submenu gobj where we are storing dialog user data buffer when
# open
.set MENU_DLG_USER_DATA_OFFSET, 0x8

# Dialog Buffer Data Table
.set DLG_DT_SELECTED_OPTION, 0 # u8
.set DLG_DT_SUBMENU_GOBJ_ADDR, DLG_DT_SELECTED_OPTION+1 # u32
.set DLG_DT_TEXT_STRUCT_ADDR, DLG_DT_SUBMENU_GOBJ_ADDR+4 # u32
.set DLG_DT_SIZE, DLG_DT_TEXT_STRUCT_ADDR + 4

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
.set REG_SM_GOBJ, 19

FN_OnlineSubmenuThink:
blrl

backup

################################################################################
# Check if confirm dialog is open or not, and prevent input if it is
################################################################################
mr REG_SM_GOBJ, r3

lwz r3, MENU_DLG_USER_DATA_OFFSET(REG_SM_GOBJ)
cmpwi r3, 0
bne FN_OnlineSubmenuThink_INPUT_HANDLERS_END

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

FN_OnlineSubmenuThink_HANDLE_LOGOUT: # crash at 80370c28

# Play Warning sfx
li r3, 0xbc
li r4, 127
li r5, 64
branchl r12, 0x800237a8 # SFX_PlaySoundAtFullVolume

bl FN_CREATE_DIALOG
b FN_OnlineSubmenuThink_INPUT_HANDLERS_END

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

FN_CREATE_DIALOG:

backup

# load jobjects in memory
lwz r3, archiveDataBuffer(r13)
load r4, JOBJ_DESC_DLG
branchl r12, HSD_ArchiveGetPublicAddress # 0x80380358
mr REG_JOBJ_DESC_ADDR, r3

lwz r3, archiveDataBuffer(r13)
load r4, JOBJ_DESC_DLG_ANIM_JOINT
branchl r12, HSD_ArchiveGetPublicAddress # 0x80380358
mr REG_JOBJ_DESC_ANIM_JOINT_ADDR, r3

lwz r3, archiveDataBuffer(r13)
load r4, JOBJ_DESC_DLG_MAT_JOINT
branchl r12, HSD_ArchiveGetPublicAddress # 0x80380358
mr REG_JOBJ_DESC_MAT_JOINT_ADDR, r3

lwz r3, archiveDataBuffer(r13)
load r4, JOBJ_DESC_DLG_SHAPE_JOINT
branchl r12, HSD_ArchiveGetPublicAddress # 0x80380358
mr REG_JOBJ_DESC_SHAPE_JOINT_ADDR, r3


# INIT PROPERTIES
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

lfs REG_F_0, TPO_FLOAT_0(REG_TEXT_PROPERTIES)
lfs REG_F_1, TPO_FLOAT_1(REG_TEXT_PROPERTIES)

# Create User Data:
# We will be adding a very small buffer to be able to track the selected option
# Get Memory Buffer for Chat Window Data Table
li REG_DLG_BUFFER_SIZE, REG_DLG_BUFFER_SIZE # buffer size

mr r3, REG_DLG_BUFFER_SIZE # Buffer Size
branchl r12, HSD_MemAlloc
mr REG_DLG_BUFFER_ADDRESS, r3 # save result address into REG_DLG_BUFFER_ADDRESS

# Zero out CSS data table
mr r4, REG_DLG_BUFFER_SIZE # buffer size
branchl r12, Zero_AreaLength

# 0: means no is selected, 1: yes is selected
li r3, DLG_OPTION_NO # Initial Selected Option
stb r3, DLG_DT_SELECTED_OPTION(REG_DLG_BUFFER_ADDRESS)

# save submenu gobj
mr r3, REG_SM_GOBJ
stw r3, DLG_DT_SUBMENU_GOBJ_ADDR(REG_DLG_BUFFER_ADDRESS)

# Save Pointer to User data To keep track of it
stw REG_DLG_BUFFER_ADDRESS, MENU_DLG_USER_DATA_OFFSET(REG_SM_GOBJ)


# Create GObj
li r3, 6 # GObj Type (6 is menu type?)
li r4, 7 # On-Pause Function (dont run on pause)
li r5, 0x80 # some type of priority
branchl r12, GObj_Create
mr REG_DLG_GOBJ, r3 # 0x803901f0 store result

# Create JOBJ
mr r3, REG_JOBJ_DESC_ADDR
branchl r12, JObj_LoadJoint # 0x80370E44 # (this func only uses r3)
mr REG_DLG_JOBJ, r3 # store result

# Add JOBJ to GObj
mr r3,REG_DLG_GOBJ
li	r4, 3
mr r5,REG_DLG_JOBJ
branchl r12, GObj_AddToObj # 0x80390A70


# Hide Interrogation Mark
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 10 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Set invisible flag on JObj
lwz r3, JOBJ_CHILD_OFFSET(sp) # get return obj
li r4, 0x10
branchl r12, JObj_SetFlagsAll # 0x80371D9c

# Hide Progress Bar
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 11 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Set invisible flag on JObj
lwz r3, JOBJ_CHILD_OFFSET(sp) # get return obj
li r4, 0x10
branchl r12, JObj_SetFlagsAll # 0x80371D9c
# Hide Progress Bar!


# Add Animations to JObj
mr r3, REG_DLG_JOBJ
mr r4, REG_JOBJ_DESC_ANIM_JOINT_ADDR
mr r5, REG_JOBJ_DESC_MAT_JOINT_ADDR
mr r6, REG_JOBJ_DESC_SHAPE_JOINT_ADDR
branchl r12, JObj_AddAnimAll #, 0x8036FB5C # (jobj,an_joint,mat_joint,sh_joint)

mr r3, REG_DLG_JOBJ
fmr f1, REG_F_0
branchl r12, JObj_ReqAnimAll# (jobj, frames)

# Configure "Yes" Button
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 6 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Move to the Left
lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
load r4, 0xC0600000
stw r4, 0x38(r3)
# Configure "Yes" Button!


# Configure "No" Button
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 7 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Move to the Right
lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
load r4, 0x405c0000
stw r4, 0x38(r3)
# Configure "No" Button!

# AddGXLink
mr r3, REG_DLG_GOBJ
load r4, 0x80391070 # GX Callback func to use
li r5, 6 # Assigns the gx_link index
li r6, 0x80 # sets the priority
branchl r12, GObj_SetupGXLink # 0x8039069c

# Add User Data to GOBJ ( Our buffer )
mr r3, REG_DLG_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, REG_DLG_BUFFER_ADDRESS # memory pointer of allocated buffer above
branchl r12, GObj_Initialize # 0x80390b68;

#Create Proc
mr r3, REG_DLG_GOBJ
bl FN_LogoutDialogThink
mflr r4 # Function
li r5, 15 # Priority
branchl	r12, GObj_AddProc

restore
blr


################################################################################
# Routine: FN_LogoutDialogThink
# ------------------------------------------------------------------------------
# Description: Handles Confirm Dialog when pressing logout
################################################################################
FN_LogoutDialogThink: #801978fc
blrl
backup

# INIT PROPERTIES
bl TEXT_PROPERTIES
mflr REG_TEXT_PROPERTIES

lfs REG_F_0, TPO_FLOAT_0(REG_TEXT_PROPERTIES) # load 0.0
lfs REG_F_1, TPO_FLOAT_1(REG_TEXT_PROPERTIES) # load 1.0

mr REG_DLG_GOBJ, r3
lwz REG_DLG_JOBJ, DLG_JOBJ_OFFSET(REG_DLG_GOBJ) # Get Jobj
lwz REG_DLG_USER_DATA_ADDR, DLG_USER_DATA_OFFSET(REG_DLG_GOBJ) # get address of data buffer

lbz REG_DLG_SELECTED_OPTION, DLG_DT_SELECTED_OPTION(REG_DLG_USER_DATA_ADDR) # Get selected option from bufffer
lwz REG_DLG_MENU_GOBJ_ADDR, DLG_DT_SUBMENU_GOBJ_ADDR(REG_DLG_USER_DATA_ADDR) # get address of submenu's gboj
lwz REG_DLG_TEXT_STRUCT_ADDR, DLG_DT_TEXT_STRUCT_ADDR(REG_DLG_USER_DATA_ADDR) # get address of text struct

# Always Animate the dialog
mr r3, REG_DLG_JOBJ
branchl r12, JObj_AnimAll

# Only Initialize Text if needed
cmpwi REG_DLG_TEXT_STRUCT_ADDR, 0
bne FN_LogoutDialogThink_ConfigureUI

FN_LogoutDialogThink_InitText:

# Create Text Object
li r3, 0
li r4, 1 # gx_link?
lfs f0, TPO_DLG_LABEL_UNK0(REG_TEXT_PROPERTIES)
lfs f1, TPO_DLG_LABEL_X_POS(REG_TEXT_PROPERTIES)
lfs f2, TPO_DLG_LABEL_Y_POS(REG_TEXT_PROPERTIES)
lfs f3, TPO_DLG_LABEL_SCALE_FACTOR(REG_TEXT_PROPERTIES) # Scale Factor
lfs f4, TPO_DLG_LABEL_WIDTH(REG_TEXT_PROPERTIES) # Width after scaled
lfs f5, TPO_DLG_LABEL_UNK1(REG_TEXT_PROPERTIES) # Unk, 300
branchl r12, Text_AllocateTextObject #0x803a5acc
mr REG_DLG_TEXT_STRUCT_ADDR, r3

# Save Text Struct Address
mr REG_DLG_TEXT_STRUCT_ADDR, r3
stw REG_DLG_TEXT_STRUCT_ADDR, DLG_DT_TEXT_STRUCT_ADDR(REG_DLG_USER_DATA_ADDR)

# Initialize Struct Stuff
li r0, 1
li r4, 0x13F # Premade Text id "Are you Sure?"
mr r3, REG_DLG_TEXT_STRUCT_ADDR
lfs f0, TPO_DLG_LABEL_CANVAS_SCALE(REG_TEXT_PROPERTIES) # Unk, 0.05
stfs f0, 0x24(r3) # Scale X
stfs f0, 0x28(r3) # Scale Y
stb r0, 0x4A(REG_DLG_TEXT_STRUCT_ADDR) # Set text to align center
branchl r12, Text_CopyPremadeTextDataToStruct

# exit to next frame when dialog is first initialized
b FN_LogoutDialogThink_Exit

FN_LogoutDialogThink_ConfigureUI:

# Configure "No" Button
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 7 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Set Animation Frame (frame 0 is turned off, frame 1+ is on)
fmr f1, REG_F_0 # Turn off
cmpwi REG_DLG_SELECTED_OPTION, DLG_OPTION_NO
bne FN_LogoutDialogThink_ConfigureUI_Animate_No
fmr f1, REG_F_1 # Turn on

FN_LogoutDialogThink_ConfigureUI_Animate_No:
lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
branchl r12, JObj_ReqAnimAll# (jobj, frames)

lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
branchl r12, JObj_AnimAll
# Configure "No" Button!

# Configure "Yes" Button
mr r3,REG_DLG_JOBJ # jobj
addi r4, sp, JOBJ_CHILD_OFFSET # pointer where to store return value
li r5, 6 # index
li r6, -1
branchl r12, JObj_GetJObjChild

# Set Animation Frame (frame 0 is turned off, frame 1+ is on)
fmr f1, REG_F_0 # Turn off
cmpwi REG_DLG_SELECTED_OPTION, DLG_OPTION_YES
bne FN_LogoutDialogThink_ConfigureUI_Animate_Yes
fmr f1, REG_F_1 # Turn on

FN_LogoutDialogThink_ConfigureUI_Animate_Yes: # 801979b4
lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
branchl r12, JObj_ReqAnimAll# (jobj, frames)

lwz r3, JOBJ_CHILD_OFFSET(sp) # jobj child
branchl r12, JObj_AnimAll
# Configure "Yes" Button!

FN_LogoutDialogThink_CheckInputs:
# Check input and switch option if left or right
li r3, 0
branchl r12, 0x801A36A0 # Inputs_GetPlayerInstantInputs

# Exit function if no input # 0x8019796c
cmpwi r3, PAD_LEFT
beq FN_LogoutDialogThink_SwitchOption
cmpwi r3, PAD_RIGHT
beq FN_LogoutDialogThink_SwitchOption
cmpwi r3, PAD_A
beq FN_LogoutDialogThink_DoLogout
cmpwi r3, PAD_B
beq FN_LogoutDialogThink_CloseDialog
b FN_LogoutDialogThink_Exit


FN_LogoutDialogThink_SwitchOption:
li	r3, 2
branchl r12, SFX_Menu_CommonSound

xori r3, REG_DLG_SELECTED_OPTION, 0x1 # alternate selected option
stb r3, DLG_DT_SELECTED_OPTION(REG_DLG_USER_DATA_ADDR) # Store to proper user data offset

b FN_LogoutDialogThink_Exit

FN_LogoutDialogThink_DoLogout:
# only logout if selected option is YES
cmpwi REG_DLG_SELECTED_OPTION, DLG_OPTION_YES
bne FN_LogoutDialogThink_CloseDialog


li r4, CONST_SlippiCmdLogOut
# Use the scene buffer cause it's not being used for anything
lwz r3, OFST_R13_SB_ADDR(r13)
stb r4, 0(r3) # Store command byte
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

b FN_LogoutDialogThink_CloseDialog

FN_LogoutDialogThink_CloseDialog:
li	r3, 0
branchl r12, SFX_Menu_CommonSound

# remove all anims
mr r3, REG_DLG_JOBJ
branchl r12, 0x8036F6B4 # HSD_JObjRemoveAnimAll

# remove proc
mr r3, REG_DLG_GOBJ
branchl r12, GObj_RemoveProc

# destroy gobj
mr r3, REG_DLG_GOBJ
branchl r12, GObj_Destroy

# Delete Text
mr r3, REG_DLG_TEXT_STRUCT_ADDR
branchl r12, Text_RemoveText

# Clear Pointer to this gobj's User data to restore input on submenu
load r3, 00000000
stw r3, MENU_DLG_USER_DATA_OFFSET(REG_DLG_MENU_GOBJ_ADDR)

b FN_LogoutDialogThink_Exit

FN_LogoutDialogThink_Exit:

restore
blr

################################################################################
# Properties
################################################################################
TEXT_PROPERTIES:
blrl
# Label properties
.set TPO_DLG_LABEL_X_POS, 0
.float -5.5
.set TPO_DLG_LABEL_Y_POS, TPO_DLG_LABEL_X_POS+4
.float -2.8
.set TPO_DLG_LABEL_UNK0, TPO_DLG_LABEL_Y_POS+4
.float 9
.set TPO_DLG_LABEL_SCALE_FACTOR,  TPO_DLG_LABEL_UNK0+4
.float 23
.set TPO_DLG_LABEL_WIDTH, TPO_DLG_LABEL_SCALE_FACTOR+4
.float 250
.set TPO_DLG_LABEL_UNK1, TPO_DLG_LABEL_WIDTH+4
.float 20
.set TPO_DLG_LABEL_CANVAS_SCALE, TPO_DLG_LABEL_UNK1+4
.float 0.05

.set TPO_FLOAT_0, TPO_DLG_LABEL_CANVAS_SCALE+4
.float 0.0
.set TPO_FLOAT_1, TPO_FLOAT_0+4
.float 1.0

.align 2

EXIT:
lis r3, 0x804A
