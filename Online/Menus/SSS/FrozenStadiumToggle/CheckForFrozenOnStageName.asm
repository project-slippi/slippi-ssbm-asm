################################################################################
# Address: 0x80259e90
################################################################################

.include "Common/Common.s"
.include "./SSSToggles.s"

.set REG_FROZEN, 31
.set REG_NEW_ICON, 30

b CODE_START

CODE_START:
  backup
  lbz	r3, OFST_HOVERED_ICON(r13)
  mr REG_NEW_ICON, r3

  cmpwi REG_NEW_ICON, ID_GRPS
  bne EXIT

  # get our static toggle data
  computeBranchTargetAddress REG_FROZEN, INJ_FREEZE_STADIUM
  addi REG_FROZEN, REG_FROZEN, 0x8

  lwz r3, 0x0(REG_FROZEN)
  cmpwi r3, 0
  beq EXIT
  
  # we have frozen stadium toggled on
  li REG_NEW_ICON, 31

EXIT:
  mr r3, REG_NEW_ICON
  restore
