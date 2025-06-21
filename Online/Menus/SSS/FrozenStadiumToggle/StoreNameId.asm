################################################################################
# Address: 0x80259fac
# SSS_CreateStageNameText saves the id its given, to data in the gobj
# so we must check if the id is 31 (Frozen) and set it back to 18 (Stadium)
################################################################################

.include "Common/Common.s"
.include "./SSSToggles.s"

CODE_START:
  cmpwi r30, 31
  beq FROZEN_STADIUM

# original
  sth	r30, 0(r28)
  b EXIT

FROZEN_STADIUM:
  li r0, ID_GRPS
  sth	r0, 0(r28)

EXIT:
