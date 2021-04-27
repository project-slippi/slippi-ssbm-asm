################################################################################
# Address: 0x8023e994 # NameEntry_Initialization
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

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
.set REG_ACIDT_ADDR, 25

.set USER_DATA_SIZE, 1
.set BTN_LEFT_TRIGGER, 0x40
.set BTN_RIGHT_TRIGGER, 0x20 
.set BTN_Z, 0x10

CODE_START:
backup

# Fetch location where we will store auto-complete buffer
computeBranchTargetAddress REG_ACIDT_ADDR, INJ_CheckAutofill

# Initialize and store buffer used with auto-complete
# These two buffers will be cleaned up in SkipReturnToCssSound.asm
li r3, ACB_SIZE
branchl r12, HSD_MemAlloc
stw r3, IDO_ACB_ADDR(REG_ACIDT_ADDR) # Store ACB address somewhere accessible
li r4, ACB_SIZE
branchl r12, Zero_AreaLength # Zero data in buffer

# Initialize ACXB
li r3, ACXB_SIZE
branchl r12, HSD_MemAlloc
lwz r4, IDO_ACB_ADDR(REG_ACIDT_ADDR)
stw r3, ACB_ACXB_ADDR(r4)

# create gobj for think function
li r3, 0x4
li r4, 0x5
li r5, 0x80
branchl r12, GObj_Create
mr REG_GOBJ, r3 # save GOBJ pointer

# create jbobj (Recent Connect Code Buttons HUD)
load r3, CSSDT_BUF_ADDR
lwz r3, 0(r3)
lwz r3, CSSDT_SLPCSS_ADDR(r3)
lwz r3,SLPCSS_CONNECTHELP(r3)
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

restore
b EXIT

EXIT:
li r3, 0