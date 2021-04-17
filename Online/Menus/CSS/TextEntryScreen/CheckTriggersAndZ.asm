################################################################################
# Address: INJ_CheckAutofill
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_ACB_ADDR, 31
.set REG_ACXB_ADDR, 30

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
b FN_FetchSuggestion # IDO_FN_FetchSuggestion
.long 0x0, # IDO_ACB_ADDR, address to buffer

CODE_START:
# Original line - checks for an L or R press.
rlwinm. r0, r26, 0, 24, 25

# If no L or R was pressed, proceed to checking for a Z press.
beq CHECK_Z

# An L or R was pressed, branch to their handlers.
branch r12, 0x8023ccac

CHECK_Z:

backup

# Manually backup the contents of r4. Without this, it breaks moving the cursor.
mr r26, r4

# Load buffers into non-volatile registers
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
lwz REG_ACB_ADDR, (IDO_ACB_ADDR - 0x8)(r3)
lwz REG_ACXB_ADDR, ACB_ACXB_ADDR(REG_ACB_ADDR)

# Manually retrieve inputs - Best I can tell, the function 
# "MainMenu_GetAllControllerInstantButtons" doesn't include check for Z.
# TODO: It might be worth having the above function handle this. 
lbz r3, -0x4A94(r13)
rlwinm r3, r3, 0, 24, 31
branchl	r12, Inputs_GetPlayerInstantInputs

# Determine if Z was pressed.
rlwinm.	r0, r4, 0, 27, 27
beq EXIT

mr r4, r26

################################################################################
# Z Press Handler
################################################################################
# Check if we have have an autocomplete result loaded.
lbz r4, 0x58 (r28) # Get cursor position/index.
mulli r4, r4, 0x3 # Multiply by 3 to get data location. 
lhzx r3, r4, r30 # Load the character at the cursor location.
# If there's no data (0), than we have no autocomplete suggestion.
cmpwi r3, 0x0
bne FILL_SUCCESS 

# No data, play error sound and exit
li	r3, 3
branchl r12, SFX_Menu_CommonSound
b Z_HANDLER_END

FILL_SUCCESS:
# Play success sound
li r3, 1
branchl r12, SFX_Menu_CommonSound

# First load the input length into committed char count
lbz r3, ACRXB_SUGGESTION_LEN(REG_ACXB_ADDR)
stb r3, ACB_COMMITTED_CHAR_COUNT(REG_ACB_ADDR)

# There's text that can be autocompleted. So we load it.
cmpwi r3, 7
ble SKIP_CURSOR_POS_ADJUST
li r3, 7 # limit cursor pos to 7
SKIP_CURSOR_POS_ADJUST:
stb r3, 0x58(r28) # store position

# Move selector over the confirm button
li r3, 57
sth r3, 0x2(r26) # Kind of awkward to use r26 here

branchl r12, 0x8023CE4C # NameEntry_UpdateTypedName

Z_HANDLER_END:
# Return to bottom of NameEntry_Think loop
# Previously it would check inputs again but this would cause an infinite loop on z press
# branchl r12, 0x8023cca4
mr r4, r26
restore
branch r12, 0x8023ccfc

################################################################################
# FN_FetchSuggestion
# Description: Fetches auto-fill suggestion based on index
################################################################################
# Inputs:
# r3 - Scroll direction. See Scroll constants
################################################################################
.set REG_ACB_ADDR, 31
.set REG_ACXB_ADDR, 30
.set REG_SCROLL_DIR, 29

FN_FetchSuggestion:
backup

# Store inputs
mr REG_SCROLL_DIR, r3

# Don't run any logic if in normal name entry
lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq FN_FetchSuggestion_Restore

# Fetch ACB and ACXB
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
lwz REG_ACB_ADDR, (IDO_ACB_ADDR - 0x8)(r3)
lwz REG_ACXB_ADDR, ACB_ACXB_ADDR(REG_ACB_ADDR)

li r3, CONST_SlippiCmdSendNameEntryIndex
stb r3, ACTXB_CMD(REG_ACXB_ADDR)

# Copy current input
addi r3, REG_ACXB_ADDR, ACTXB_INPUT
load r4, 0x804a0740 # Load the start location of input
li r5, 3 * 8 # Copy 8 characters
branchl r12, memcpy

# Fetch length and set
lbz r3, ACB_COMMITTED_CHAR_COUNT(REG_ACB_ADDR) # load position
stb r3, ACTXB_INPUT_LEN(REG_ACXB_ADDR)

# Current scroll index
lwz r3, ACB_INDEX(REG_ACB_ADDR)
stw r3, ACTXB_INDEX(REG_ACXB_ADDR)

# Write out scroll direction
stb REG_SCROLL_DIR, ACTXB_SCROLL_DIR(REG_ACXB_ADDR)

# Fetch and write current mode
lbz r3, OFST_R13_ONLINE_MODE(r13)
stb r3, ACTXB_MODE(REG_ACXB_ADDR)

# Write command to start EXI operation
mr r3, REG_ACXB_ADDR
li r4, ACTXB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Receive response
mr r3, REG_ACXB_ADDR
li r4, ACRXB_SIZE
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# Copy result
load r3, 0x804a0740 # Load the start location of input
addi r4, REG_ACXB_ADDR, ACRXB_SUGGESTION
li r5, 3 * 8 # Copy 8 characters
branchl r12, memcpy

# Set new index. Not sure this is necessary, we could maybe just use the value in the XB directly
lwz r3, ACRXB_NEW_INDEX(REG_ACXB_ADDR)
stw r3, ACB_INDEX(REG_ACB_ADDR)

# Update text display. Not strictly necessary to always do it but it saves an additional call
# in B press auto complete and I don't think it hurts?
branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

FN_FetchSuggestion_Restore:
restore
blr

EXIT:
mr r4, r26
restore
branch r12, 0x8023cd34 # B Press check
