################################################################################
# Address: 80043230
################################################################################

.include "Common/Common.s"

loadGlobalFrame r12
cmpwi r12, 180
blt EXIT

# Force crash
li r0, 1

EXIT:
# replaced codeline
cmpwi	r0, 1