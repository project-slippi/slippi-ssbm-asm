################################################################################
# Address: FN_LoadChatMessageProperties
################################################################################
# Inputs:
# r3 - Category direction
# r3: 0x08=up, 0x04=down, 0x01=left, 0x02=left
# r4 - Message chosen (PAD_UP/DOWN/RIGHT/LEFT)
# r4: 0x08=PAD_UP 0x04=PAD_DOWN 0x02=PAD_RIGHT 0x01=PAD_LEFT
################################################################################
# Returns:
# r3: Address to Text Properties
# r4: Address to Message
################################################################################
# Description:
# Loads Chat Message Properties and chat message for a given category
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# backup where we came from
mflr r5

cmpwi r3, 0x08 # PAD_UP
beq INIT_UP_CHAT_TEXT_PROPERTIES
cmpwi r3, 0x04 # PAD_DOWN
beq INIT_DOWN_CHAT_TEXT_PROPERTIES
cmpwi r3, 0x02 # PAD_RIGHT
beq INIT_RIGHT_CHAT_TEXT_PROPERTIES
cmpwi r3, 0x01 # PAD_LEFT
beq INIT_LEFT_CHAT_TEXT_PROPERTIES

INIT_UP_CHAT_TEXT_PROPERTIES:
bl UP_CHAT_TEXT_PROPERTIES
mflr r3
b CHECK_MSG_INPUT
INIT_DOWN_CHAT_TEXT_PROPERTIES:
bl DOWN_CHAT_TEXT_PROPERTIES
mflr r3
b CHECK_MSG_INPUT
INIT_RIGHT_CHAT_TEXT_PROPERTIES:
bl RIGHT_CHAT_TEXT_PROPERTIES
mflr r3
b CHECK_MSG_INPUT
INIT_LEFT_CHAT_TEXT_PROPERTIES:
bl LEFT_CHAT_TEXT_PROPERTIES
mflr r3

CHECK_MSG_INPUT:

lbz r7, 0(r3)  # HEADER length
lbz r8, 1(r3)  # UP length
lbz r9, 2(r3)  # LEFT length
lbz r10, 3(r3)  # RIGHT length

# save target label in r6
mr r6, r4
# calculate address of label
addi r4, r3, 0x4 # Skip over lengths
add r4, r4, r7 # skip over header
cmpwi r6, 0x08 # PAD_UP
beq EXIT
add r4, r4, r8 # skip over up
cmpwi r6, 0x01 # PAD_LEFT
beq EXIT
add r4, r4, r9 # skip over left
cmpwi r6, 0x02 # PAD_RIGHT
beq EXIT
add r4, r4, r10 # skip over right

EXIT:
# go back to where we were
mtctr r5
bctr

UP_CHAT_TEXT_PROPERTIES:
blrl
.byte 7 # length of Header
.byte 4 # length of UP
.byte 9 # length of LEFT
.byte 4 # length of RIGHT
.string "Common"
.string "ggs"
.string "one more"
.string "brb"
.string "good luck"
.align 2

LEFT_CHAT_TEXT_PROPERTIES:
blrl
.byte 12 # length of Header
.byte 12 # length of UP
.byte 13 # length of LEFT
.byte 7 # length of RIGHT
.string "Compliments"
.string "well played"
.string "that was fun"
.string "thanks"
.string "too good"
.align 2

RIGHT_CHAT_TEXT_PROPERTIES:
blrl
.byte 10 # length of Header
.byte 6 # length of UP
.byte 5 # length of LEFT
.byte 4 # length of RIGHT
.string "Reactions"
.string "sorry"
.string "my b"
.string "lol"
.string "wow"
.align 2

DOWN_CHAT_TEXT_PROPERTIES:
blrl
.byte 5 # length of Header
.byte 9 # length of UP
.byte 8 # length of LEFT
.byte 23 # length of RIGHT
.string "Misc"
.string "gotta go"
.string "one sec"
.string "let's play again later"
.string "bad connection"
.align 2
