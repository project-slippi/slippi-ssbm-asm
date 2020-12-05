################################################################################
# Address: 0x801a3f9c # Sets SIS Text Heap Memory Size
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

# Set the same size that is set on the Menu for now
# TODO: Test how many messages this handles for Chat
li r3, 0x4800
b AFTER_EXIT

EXIT:
li r3, 0x2400
AFTER_EXIT:
