################################################################################
# Address: 0x8023e9c8
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Don't clear letters if entering connect code... we should probably clear them
# if the previous nametag entry was for a in-game tag though. Perhaps do that
# elsewhere?
lbz r0, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r0, 0
li r5, 0
beq LOOP_INIT # If not entering connect code, make previous letter 0 to clear all

lbz r5, 0(r31) # Load first letter

LOOP_INIT:
li r3, 0

LOOP_START:
cmpwi r5, 0
bne LOAD_LETTER

# Clear current letter
mulli r4, r3, 3
stbx r5, r31, r4 # Clear current letter

LOAD_LETTER:
mulli r4, r3, 3
lbzx r5, r31, r4 # Load current letter

LOOP_CONTINUE:
addi r3, r3, 1
cmpwi r3, 0x8
blt LOOP_START
LOOP_END:

EXIT:
# Skip code that used to clear letters, it's been replaced by this function
branch r12, 0x8023e9e8
