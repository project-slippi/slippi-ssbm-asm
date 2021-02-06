################################################################################
# Address: 0x8023e994
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

backup
lbz r3, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r3, 0
beq EXIT

# Set flag so we reset index into direct code list.
li r3, 1
stb r3, OFST_R13_NAME_ENTRY_INDEX_FLAG(r13)

EXIT:
restore