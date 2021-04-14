################################################################################
# Address: 0x8023cf80
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"
.include "Online/Menus/CSS/TextEntryScreen/AutoComplete.s"

.set REG_CHAR_INDEX, 27 # Set by parent function

b CODE_START

 DATA_BLRL:
 blrl 
 .set DEFAULT_COLOR, 0
 .long 0x00000000
 .set AUTOCOMPLETE_COLOR, DEFAULT_COLOR + 4
 .long 0x8E9196FF
 .align 2

CODE_START:

lbz r6, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r6, 0
beq EXIT

# r29 stores the color to load for the text, here we will overwrite it. This runs once per char

# Get address where colors are stored
bl DATA_BLRL
mflr r6

# Fetch INJ data table in order to get ADC to get committed char count
computeBranchTargetAddress r7, INJ_CheckAutofill
lwz r7, IDO_ACB_ADDR(r7)
lbz r7, ACB_COMMITTED_CHAR_COUNT(r7)

# Compare current letter idx to committed char count
cmpw REG_CHAR_INDEX, r7
blt DISPLAY_DARK
addi r29, r6, AUTOCOMPLETE_COLOR
b EXIT
DISPLAY_DARK:
addi r29, r6, DEFAULT_COLOR 

EXIT:
lwz	r0, -0x6728 (r13) # replaced code line