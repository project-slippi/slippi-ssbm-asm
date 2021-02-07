################################################################################
# Address: 0x8023e994 # NameEntry_Initialization
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Set flag so we reset index into direct code list.
li r3, 1
stb r3, OFST_R13_NAME_ENTRY_INDEX_FLAG(r13)

b CODE_START

################################################################################
# Initialize instruction text
################################################################################
.set REG_DATA_ADDR, 31
.set REG_TEXT_STRUCT, 30
.set REG_GOBJ, 29
.set REG_JOBJ, 28
.set REG_USER_DATA, 27
.set REG_PRESSED_BUTTON, 26 # this comes from the 


.set USER_DATA_SIZE, 1
.set BTN_LEFT_TRIGGER, 0x40
.set BTN_RIGHT_TRIGGER, 0x20 
.set BTN_Z, 0x10

CODE_START:
backup

# Get Memory Buffer for Chat Window Data Table
li r3, USER_DATA_SIZE # Buffer Size
branchl r12, HSD_MemAlloc
mr REG_USER_DATA, r3 

# create gobj for think function
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr REG_GOBJ, r3 # save GOBJ pointer

# create jbobj (Recent Connect Code Buttons HUD)
lwz r3, -0x49eC(r13) # 804db6a0 pointer to MnSlChar file
lwz r3, 0x1C(r3) # pointer to our custom jobj
branchl r12, JObj_LoadJoint 
mr  REG_JOBJ,r3

# Add JOBJ To GObj
mr  r3,REG_GOBJ
li r4, 4
mr  r5,REG_JOBJ
branchl r12, GObj_AddToObj

# Add GX Link that draws the background
mr  r3,REG_GOBJ
load r4,0x80391070
li  r5, 4
li  r6, 128
branchl r12, GObj_SetupGXLink 

mr r3, REG_GOBJ
li r4, 4 # user data kind
load r5, HSD_Free # destructor
mr r6, REG_USER_DATA # memory pointer of allocated buffer above
branchl r12, GObj_Initialize

# Set Think Function that runs every frame
mr r3, REG_GOBJ # set r3 to GOBJ pointer
bl NAME_ENTRY_RECENT_CONNECT_CODE_THINK
mflr r4 # Function to Run
li r5, 4 # Priority. 4 runs after CSS_LoadButtonInputs 
branchl r12, GObj_AddProc


restore
b EXIT

################################################################################
# Recent connect code think Function: Looping function to handle input 
################################################################################
NAME_ENTRY_RECENT_CONNECT_CODE_THINK:
blrl
backup

CHECK_BTN_PRESSED: # must check for all ports
li r14, 0
CHECK_BTN_PRESSED_LOOP_START:

mr r3, r14
branchl	r12, Inputs_GetPlayerInstantInputs

cmpwi r4, BTN_LEFT_TRIGGER
beq L_PRESSED
cmpwi r4, BTN_RIGHT_TRIGGER
beq R_PRESSED
cmpwi r4, BTN_Z
beq Z_PRESSED

addi r14, r14, 1
cmpwi r14, 4 # check if loop ended
blt CHECK_BTN_PRESSED_LOOP_START

b NAME_ENTRY_RECENT_CONNECT_CODE_THINK_EXIT

L_PRESSED:

R_PRESSED:

LR_PRESSED:

# Play nav sound
# li r3, 1
# branchl r12, SFX_Menu_CommonSound

b NAME_ENTRY_RECENT_CONNECT_CODE_THINK_EXIT

Z_PRESSED:

# Play success sound
# li r3, 1
# branchl r12, SFX_Menu_CommonSound

NAME_ENTRY_RECENT_CONNECT_CODE_THINK_EXIT:
restore
blr


EXIT:
li r3, 0