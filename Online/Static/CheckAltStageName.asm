################################################################################
# Address: FN_CheckAltStageName
################################################################################
# Inputs:
# r3 = text ptr
# r4 = ext stage id
################################################################################
# Description:
# Checks to run alternate stage name logic (non-applicable to vanilla melee)
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEXT_STRUCT, 30
.set REG_MSRB_ADDR, 29

CODE_START:
  backup

  mr REG_TEXT_STRUCT, r3
  li r3, 0

  cmpwi r4, 0x3 # Stadium
  bne EXIT

  # check if frozen
  lbz r0, MSRB_ALT_STAGE_MODE(REG_MSRB_ADDR)
  cmpwi r0, 0
  beq EXIT

  mr r3, REG_TEXT_STRUCT
  li r4, 89 # 'Frozen Pokemon Stadium'
  branchl r12, Text_CopyPremadeTextDataToStruct

  li r3, 1

EXIT:
  restore
  blr
