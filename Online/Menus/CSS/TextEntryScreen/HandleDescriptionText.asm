################################################################################
# Address: 0x8023b3d0
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r4, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r4, 0
beq RESTORE

# Set flag so we reset index into direct code list.
li r3, 1
stb r3, OFST_R13_NAME_ENTRY_INDEX_FLAG(r13)

# ID of our premade text for singles
li r4, 87

lbz r5, OFST_R13_ONLINE_MODE(r13)
cmpwi r5, ONLINE_MODE_TEAMS
bne EXIT # exit if not on TEAMS mode

# IF of our premade text for doubles
li r4, 88
b EXIT

RESTORE:
mr r4, r31 # original line replaced

EXIT:

