################################################################################
# Address: 0x80264110 # Executed after check to see if tag is empty
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Reset name entry mode
li r3, 0
stb r3, OFST_R13_NAME_ENTRY_MODE(r13)

# Skip playing sounds
branch r12, 0x802641a8

EXIT:
rlwinm r0, r0, 3, 0, 28
