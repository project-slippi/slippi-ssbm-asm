################################################################################
# Address: 0x803a63a8 # Address in Text_CopyPremadeTextDataToStruct right after
# encoded string is stored in in r0
################################################################################
# Usage:
# OFST_R13_USE_PREMADE_TEXT must be > 0 to use this patch
################################################################################
# Inputs:
# r6 is the actual slippi text id of the text we want to read
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_STRING_FORMAT_ADDR, 30
.set REG_PREMADE_TEXT_ID, REG_STRING_FORMAT_ADDR-1
.set REG_PREMADE_TEXT_PARAM_1, REG_PREMADE_TEXT_ID-1

backup
mr REG_PREMADE_TEXT_ID, r4
mr REG_PREMADE_TEXT_PARAM_1, r6

# So, what we are going to do here is request a READ from the EXI device which
# will return the encoded string requested with an ID and then store that into
# the text data struct
lbz r3, OFST_R13_USE_PREMADE_TEXT(r13)
cmpwi r3, 0
beq EXIT # get out if this is just the game doing it's thing

# Load Premade text id from dolphin
mr r3, REG_PREMADE_TEXT_ID
mr r4, REG_PREMADE_TEXT_PARAM_1
branchl r12, FN_LoadPremadeText
mr REG_STRING_FORMAT_ADDR, r3
stw REG_STRING_FORMAT_ADDR, 0x5C(r31)

EXIT:
restore
# stw	r0, 0x005C (r31) # original line before this one
li	r3, 0 # original line
stb r3, OFST_R13_USE_PREMADE_TEXT(r13) # clear out r13 offset
